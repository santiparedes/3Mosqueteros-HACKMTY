import Foundation
import MultipeerConnectivity
import SwiftUI
import CoreBluetooth
import Network

// MARK: - Tap to Send Service
class TapToSendService: NSObject, ObservableObject {
    static let shared = TapToSendService()
    
    // MultipeerConnectivity
    private let serviceType = "quantumtap"
    private lazy var myPeerID: MCPeerID = {
        // Create a unique peer ID by appending last 4 digits of device identifier
        let deviceName = UIDevice.current.name
        let deviceID = UIDevice.current.identifierForVendor?.uuidString.suffix(4) ?? "0000"
        return MCPeerID(displayName: "\(deviceName)-\(deviceID)")
    }()
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    // Published properties
    @Published var isAdvertising = false
    @Published var isBrowsing = false
    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedPaymentRequest: PaymentRequest?
    @Published var showPaymentRequest = false
    @Published var isConnected = false
    @Published var debugMessages: [String] = []
    @Published var showPermissionAlert = false
    @Published var permissionAlertMessage = ""
    
    // Payment data
    @Published var pendingPayment: PendingPayment?
    
    // Permission monitoring
    private var bluetoothManager: CBCentralManager?
    private var networkMonitor: NWPathMonitor?
    
    override init() {
        super.init()
        setupMultipeerConnectivity()
        setupPermissionMonitoring()
        addDebugMessage("TapToSendService initialized")
    }
    
    private func setupMultipeerConnectivity() {
        addDebugMessage("Setting up MultipeerConnectivity with service type: \(serviceType)")
        addDebugMessage("My peer ID: \(myPeerID.displayName)")
        
        // Create session with required encryption for better compatibility
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        addDebugMessage("✅ MCSession created with peer: \(myPeerID.displayName)")
        
        // Create advertiser with same peer ID and session
        let discoveryInfo = [
            "device": UIDevice.current.name,
            "app": "QuantumWallet",
            "version": "1.0",
            "peerID": myPeerID.displayName
        ]
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser.delegate = self
        addDebugMessage("✅ MCNearbyServiceAdvertiser created")
        addDebugMessage("🔍 Advertiser delegate set: \(advertiser.delegate != nil ? "✅ YES" : "❌ NO")")
        addDebugMessage("🔍 Advertiser peer ID: \(advertiser.myPeerID.displayName)")
        addDebugMessage("🔍 Advertiser service type: \(serviceType)")
        
        // Create browser with same peer ID
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
        addDebugMessage("✅ MCNearbyServiceBrowser created")
        
        addDebugMessage("MultipeerConnectivity setup complete - all components use same peer ID")
    }
    
    private func setupPermissionMonitoring() {
        // Monitor Bluetooth permissions
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        
        // Monitor network permissions
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.addDebugMessage("Network status: \(path.status)")
                if path.status == .satisfied {
                    self?.addDebugMessage("Network is available")
                } else {
                    self?.addDebugMessage("Network is not available")
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor?.start(queue: queue)
        
        // Force Local Network permission request
        requestLocalNetworkPermission()
    }
    
    private func requestLocalNetworkPermission() {
        addDebugMessage("🔐 Requesting Local Network permission...")
        
        // Create a temporary network monitor to trigger permission request
        let tempMonitor = NWPathMonitor()
        tempMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.addDebugMessage("🔐 Local Network permission request triggered")
                // Stop the temporary monitor after permission request
                tempMonitor.cancel()
            }
        }
        
        let tempQueue = DispatchQueue(label: "TempNetworkMonitor")
        tempMonitor.start(queue: tempQueue)
        
        // Also try to create a network connection to trigger permission
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.triggerLocalNetworkPermission()
        }
    }
    
    private func triggerLocalNetworkPermission() {
        addDebugMessage("🔐 Attempting to trigger Local Network permission dialog...")
        
        // Try to create a local network connection to trigger permission
        let connection = NWConnection(host: "127.0.0.1", port: 8080, using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.addDebugMessage("🔐 Local Network permission may have been granted")
                case .failed(let error):
                    self?.addDebugMessage("🔐 Local Network permission check: \(error)")
                case .cancelled:
                    self?.addDebugMessage("🔐 Local Network permission check cancelled")
                default:
                    break
                }
            }
        }
        
        connection.start(queue: DispatchQueue.global())
        
        // Cancel the connection after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            connection.cancel()
        }
    }
    
    private func addDebugMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let debugMessage = "[\(timestamp)] \(message)"
        print("🔍 TapToSend Debug: \(debugMessage)")
        
        DispatchQueue.main.async {
            self.debugMessages.append(debugMessage)
            // Keep only last 50 messages
            if self.debugMessages.count > 50 {
                self.debugMessages.removeFirst()
            }
        }
    }
    
    private func checkPermissions() -> Bool {
        var hasAllPermissions = true
        
        // Check Bluetooth permission
        if let bluetoothManager = bluetoothManager {
            switch bluetoothManager.state {
            case .poweredOn:
                addDebugMessage("✅ Bluetooth is powered on")
            case .poweredOff:
                addDebugMessage("❌ Bluetooth is powered off")
                hasAllPermissions = false
                showPermissionAlert(message: "Bluetooth is turned off. Please enable Bluetooth in Settings to use tap-to-send.")
            case .unauthorized:
                addDebugMessage("❌ Bluetooth permission denied")
                hasAllPermissions = false
                showPermissionAlert(message: "Bluetooth permission is required for tap-to-send. Please grant permission in Settings.")
            case .unsupported:
                addDebugMessage("❌ Bluetooth not supported")
                hasAllPermissions = false
                showPermissionAlert(message: "Bluetooth is not supported on this device.")
            case .resetting:
                addDebugMessage("⚠️ Bluetooth is resetting")
            case .unknown:
                addDebugMessage("⚠️ Bluetooth state unknown")
            @unknown default:
                addDebugMessage("⚠️ Unknown Bluetooth state")
            }
        }
        
        // Check Local Network permission (iOS 14+)
        if #available(iOS 14.0, *) {
            addDebugMessage("⚠️ Local Network permission may be required for iOS 14+")
            addDebugMessage("💡 If connection fails, check Settings > Privacy & Security > Local Network")
            
            // Try to detect Local Network permission status
            checkLocalNetworkPermissionStatus()
        }
        
        return hasAllPermissions
    }
    
    private func checkLocalNetworkPermissionStatus() {
        addDebugMessage("🔍 Checking Local Network permission status...")
        
        // Create a test connection to check permission
        let testConnection = NWConnection(host: "127.0.0.1", port: 8080, using: .tcp)
        testConnection.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.addDebugMessage("✅ Local Network permission appears to be granted")
                case .failed(let error):
                    if let nsError = error as NSError?, nsError.code == -72008 {
                        self?.addDebugMessage("❌ Local Network permission is DENIED")
                    } else {
                        self?.addDebugMessage("🔍 Local Network test failed (expected): \(error)")
                    }
                case .cancelled:
                    self?.addDebugMessage("🔍 Local Network test cancelled")
                default:
                    break
                }
            }
        }
        
        testConnection.start(queue: DispatchQueue.global())
        
        // Cancel after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            testConnection.cancel()
        }
    }
    
    private func showPermissionAlert(message: String) {
        DispatchQueue.main.async {
            self.permissionAlertMessage = message
            self.showPermissionAlert = true
        }
    }
    
    private func forceLocalNetworkPermissionRequest() {
        addDebugMessage("🔐 Forcing Local Network permission request...")
        
        // Try multiple methods to trigger Local Network permission
        let methods = [
            ("UDP Multicast", "224.0.0.1", 8080, NWParameters.udp),
            ("TCP Local", "127.0.0.1", 8080, NWParameters.tcp),
            ("Bonjour Service", "local.", 8080, NWParameters.tcp)
        ]
        
        for (method, host, port, params) in methods {
            addDebugMessage("🔐 Trying \(method) to trigger permission...")
            
            let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: UInt16(port)), using: params)
            connection.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.addDebugMessage("🔐 \(method) - Local Network permission granted!")
                    case .failed(let error):
                        self?.addDebugMessage("🔐 \(method) - Permission check failed: \(error)")
                    case .cancelled:
                        self?.addDebugMessage("🔐 \(method) - Permission check cancelled")
                    default:
                        break
                    }
                }
            }
            
            connection.start(queue: DispatchQueue.global())
            
            // Cancel after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                connection.cancel()
            }
        }
    }
    
    private func recreateMultipeerSession() {
        addDebugMessage("🔄 Recreating MultipeerConnectivity session...")
        
        // Stop current operations
        if isBrowsing {
            browser.stopBrowsingForPeers()
            isBrowsing = false
        }
        if isAdvertising {
            advertiser.stopAdvertisingPeer()
            isAdvertising = false
        }
        
        // Disconnect current session
        session.disconnect()
        connectedPeers.removeAll()
        isConnected = false
        
        // Recreate session with same myPeerID (already unique)
        addDebugMessage("🔄 Recreating with peer ID: \(myPeerID.displayName)")
        
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        // Recreate advertiser and browser
        let discoveryInfo = [
            "device": UIDevice.current.name,
            "app": "QuantumWallet",
            "retry": "\(Date().timeIntervalSince1970)",
            "peerID": myPeerID.displayName
        ]
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
        
        addDebugMessage("✅ MultipeerConnectivity session recreated")
    }
    
    // MARK: - Public Methods
    
    func startAdvertising() {
        guard !isAdvertising else { 
            addDebugMessage("⚠️ Already advertising")
            return 
        }
        
        // Force Local Network permission request before advertising
        forceLocalNetworkPermissionRequest()
        
        guard checkPermissions() else {
            addDebugMessage("❌ Cannot start advertising - missing permissions")
            return
        }
        
        addDebugMessage("🚀 Starting advertising for tap-to-send")
        addDebugMessage("🔍 My peer ID: \(myPeerID.displayName)")
        addDebugMessage("🔍 Service type: \(serviceType)")
        addDebugMessage("🔍 Session state: \(session.connectedPeers.count) connected peers")
        
        // Ensure advertising starts on main thread
        DispatchQueue.main.async {
            self.addDebugMessage("🔍 About to start advertising...")
            self.addDebugMessage("🔍 Advertiser delegate before start: \(self.advertiser.delegate != nil ? "✅ SET" : "❌ NOT SET")")
            self.addDebugMessage("🔍 Advertiser peer ID: \(self.advertiser.myPeerID.displayName)")
            self.addDebugMessage("🔍 Advertiser service type: \(self.serviceType)")
            
            self.advertiser.startAdvertisingPeer()
            self.isAdvertising = true
            self.addDebugMessage("✅ Advertising started successfully")
            self.addDebugMessage("🔍 Advertiser delegate after start: \(self.advertiser.delegate != nil ? "✅ STILL SET" : "❌ LOST")")
            
            // Add periodic status check
            self.startAdvertisingStatusCheck()
            
            // Start connection watchdog
            self.startConnectionWatchdog()
        }
    }
    
    private func startAdvertisingStatusCheck() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            if self.isAdvertising {
                self.addDebugMessage("🔍 Advertising status check - still advertising")
                self.addDebugMessage("🔍 Session connected peers: \(self.session.connectedPeers.count)")
                
                // Connection watchdog - restart if no connections after 30 seconds
                if self.session.connectedPeers.isEmpty {
                    self.addDebugMessage("⏳ No connections yet, continuing to advertise...")
                }
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func startConnectionWatchdog() {
        addDebugMessage("🕐 Starting connection watchdog (30s timeout)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if self.session.connectedPeers.isEmpty && self.isAdvertising {
                self.addDebugMessage("⏰ Connection watchdog triggered - restarting advertising")
                self.restartAdvertising()
            }
        }
    }
    
    private func restartAdvertising() {
        addDebugMessage("🔄 Restarting advertising...")
        
        // Stop current advertising
        if isAdvertising {
            advertiser.stopAdvertisingPeer()
            isAdvertising = false
        }
        
        // Small delay then restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.advertiser.startAdvertisingPeer()
            self.isAdvertising = true
            self.addDebugMessage("✅ Advertising restarted")
            
            // Start new watchdog
            self.startConnectionWatchdog()
        }
    }
    
    func stopAdvertising() {
        guard isAdvertising else { 
            addDebugMessage("⚠️ Not currently advertising")
            return 
        }
        addDebugMessage("🛑 Stopping advertising")
        advertiser.stopAdvertisingPeer()
        isAdvertising = false
        addDebugMessage("✅ Advertising stopped")
    }
    
    func startBrowsing() {
        addDebugMessage("🔍 startBrowsing() called - current isBrowsing: \(isBrowsing)")
        
        // Force Local Network permission request before browsing
        forceLocalNetworkPermissionRequest()
        
        guard checkPermissions() else {
            addDebugMessage("❌ Cannot start browsing - missing permissions")
            return
        }
        
        addDebugMessage("🔍 Starting to browse for nearby devices")
        
        // Stop any existing browsing first to ensure clean state
        if isBrowsing {
            addDebugMessage("🔄 Stopping existing browsing session")
            browser.stopBrowsingForPeers()
            isBrowsing = false
        }
        
        // Ensure browsing starts on main thread
        DispatchQueue.main.async {
            self.startBrowsingWithRetry()
        }
    }
    
    private func startBrowsingWithRetry(attempt: Int = 1) {
        addDebugMessage("🔍 Browsing attempt \(attempt)")
        addDebugMessage("🔍 My peer ID (browser): \(myPeerID.displayName)")
        addDebugMessage("🔍 Service type (browser): \(serviceType)")
        
        // Ensure we're not already browsing
        if isBrowsing {
            addDebugMessage("⚠️ Already browsing, stopping first")
            browser.stopBrowsingForPeers()
            isBrowsing = false
        }
        
        // Small delay to ensure clean state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.addDebugMessage("🔍 Actually calling browser.startBrowsingForPeers() now...")
            self.browser.startBrowsingForPeers()
            self.isBrowsing = true
            self.addDebugMessage("✅ Browsing started successfully - isBrowsing = true")
            self.addDebugMessage("🔍 Waiting for nearby devices to appear...")
        }
    }
    
    func stopBrowsing() {
        addDebugMessage("🛑 stopBrowsing() called - current isBrowsing: \(isBrowsing)")
        guard isBrowsing else { 
            addDebugMessage("⚠️ Not currently browsing - no action needed")
            return 
        }
        addDebugMessage("🛑 Stopping browsing")
        browser.stopBrowsingForPeers()
        isBrowsing = false
        addDebugMessage("✅ Browsing stopped")
    }
    
    func sendPaymentRequest(to peer: MCPeerID, amount: Double, currency: String = "USD", message: String = "") {
        let paymentRequest = PaymentRequest(
            id: UUID().uuidString,
            from: myPeerID.displayName,
            to: peer.displayName,
            amount: amount,
            currency: currency,
            message: message,
            timestamp: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(paymentRequest)
            try session.send(data, toPeers: [peer], with: .reliable)
            print("Sent payment request to \(peer.displayName)")
        } catch {
            print("Failed to send payment request: \(error)")
        }
    }
    
    func sendPaymentResponse(to peer: MCPeerID, requestId: String, accepted: Bool, transactionId: String? = nil) {
        let response = PaymentResponse(
            requestId: requestId,
            accepted: accepted,
            transactionId: transactionId,
            timestamp: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(response)
            try session.send(data, toPeers: [peer], with: .reliable)
            print("Sent payment response to \(peer.displayName)")
        } catch {
            print("Failed to send payment response: \(error)")
        }
    }
    
    func initiateTapToSend(amount: Double, currency: String = "USD", message: String = "") {
        // Store pending payment info first
        pendingPayment = PendingPayment(
            amount: amount,
            currency: currency,
            message: message,
            timestamp: Date()
        )
        
        addDebugMessage("💸 Initiated tap-to-send for \(amount) \(currency)")
        addDebugMessage("🔍 Connected peers: \(connectedPeers.count)")
        
        // If already connected, send payment immediately
        if !connectedPeers.isEmpty {
            addDebugMessage("💸 Already connected to peers, sending payment immediately...")
            sendPendingPaymentToConnectedPeers()
        } else {
            addDebugMessage("🔄 No connected peers, starting advertising and browsing...")
            // Start BOTH advertising AND browsing for maximum connectivity
            startAdvertising()
            startBrowsing()
        }
        
        // Set up connection timeout monitoring
        setupConnectionTimeout()
    }
    
    private func setupConnectionTimeout() {
        // If no connection after 10 seconds, show alternative
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if !self.isConnected && self.isAdvertising {
                self.addDebugMessage("⚠️ Connection timeout - offering alternative methods")
                self.showPermissionAlert(message: "La conexión directa está tardando. Puedes usar 'Share Payment Link' para enviar el pago por mensaje.")
            }
        }
    }
    
    func cancelTapToSend() {
        stopAdvertising()
        pendingPayment = nil
        print("Cancelled tap-to-send")
    }
    
    func disconnect() {
        addDebugMessage("🔌 Disconnecting from all peers")
        
        // Stop all operations
        stopAdvertising()
        stopBrowsing()
        
        // Disconnect session
        session.disconnect()
        
        // Reset state
        connectedPeers.removeAll()
        isConnected = false
        pendingPayment = nil
        receivedPaymentRequest = nil
        showPaymentRequest = false
        
        addDebugMessage("✅ Disconnected from all peers")
    }
    
    func resetService() {
        addDebugMessage("🔄 Resetting TapToSend service")
        
        // Disconnect everything
        disconnect()
        
        // Recreate the session
        recreateMultipeerSession()
        
        addDebugMessage("✅ TapToSend service reset complete")
    }
    
    func forceRestartBrowsing() {
        addDebugMessage("🔄 Force restarting browsing...")
        
        // Always stop browsing first
        if isBrowsing {
            browser.stopBrowsingForPeers()
            isBrowsing = false
            addDebugMessage("🛑 Stopped existing browsing for force restart")
        }
        
        // Small delay then restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.addDebugMessage("🔄 Force restarting browsing after delay...")
            self.startBrowsing()
        }
    }
    
    func testAdvertiserDelegate() {
        addDebugMessage("🧪 Testing advertiser delegate...")
        addDebugMessage("🔍 Advertiser exists: \(advertiser != nil ? "✅ YES" : "❌ NO")")
        addDebugMessage("🔍 Advertiser delegate set: \(advertiser?.delegate != nil ? "✅ YES" : "❌ NO")")
        addDebugMessage("🔍 Advertiser is advertising: \(isAdvertising ? "✅ YES" : "❌ NO")")
        addDebugMessage("🔍 Advertiser peer ID: \(advertiser?.myPeerID.displayName ?? "nil")")
        addDebugMessage("🔍 Advertiser service type: \(advertiser?.serviceType ?? "nil")")
        addDebugMessage("🔍 Expected service type: \(serviceType)")
        addDebugMessage("🔍 Service type match: \((advertiser?.serviceType ?? "") == serviceType ? "✅ YES" : "❌ NO")")
        
        // Test if we can call the delegate method (this won't actually work but shows the method exists)
        if advertiser?.delegate != nil {
            addDebugMessage("✅ Advertiser delegate is properly set and should receive invitations")
        } else {
            addDebugMessage("❌ Advertiser delegate is NOT set - invitations will be lost!")
        }
    }
    
    func sendPendingPaymentToConnectedPeers() {
        addDebugMessage("💸 Checking for pending payment to send to connected peers...")
        addDebugMessage("🔍 Connected peers: \(connectedPeers.count)")
        addDebugMessage("🔍 Pending payment exists: \(pendingPayment != nil ? "✅ YES" : "❌ NO")")
        
        if let pending = pendingPayment, !connectedPeers.isEmpty {
            for peer in connectedPeers {
                addDebugMessage("💸 Sending pending payment to \(peer.displayName)")
                sendPaymentRequest(
                    to: peer,
                    amount: pending.amount,
                    currency: pending.currency,
                    message: pending.message
                )
            }
            pendingPayment = nil
            addDebugMessage("✅ Payment sent to all connected peers")
        } else if pendingPayment == nil {
            addDebugMessage("ℹ️ No pending payment to send")
        } else {
            addDebugMessage("⚠️ No connected peers to send payment to")
        }
    }
}

// MARK: - MCSessionDelegate
extension TapToSendService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.addDebugMessage("🔄 Session state changed for \(peerID.displayName): \(self.getStateString(state))")
            
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                self.isConnected = true
                self.addDebugMessage("🔗 Connected to \(peerID.displayName)")
                self.addDebugMessage("🔍 Total connected peers: \(self.connectedPeers.count)")
                
                // Stop browsing once connected to avoid conflicts
                if self.isBrowsing {
                    self.browser.stopBrowsingForPeers()
                    self.isBrowsing = false
                    self.addDebugMessage("🛑 Stopped browsing - device connected")
                }
                
                // Also stop advertising once connected to avoid duplicate connections
                if self.isAdvertising {
                    self.advertiser.stopAdvertisingPeer()
                    self.isAdvertising = false
                    self.addDebugMessage("🛑 Stopped advertising - device connected")
                }
                
                // If we have a pending payment, send it immediately
                if let pending = self.pendingPayment {
                    self.addDebugMessage("💸 Sending pending payment to \(peerID.displayName)")
                    self.sendPaymentRequest(
                        to: peerID,
                        amount: pending.amount,
                        currency: pending.currency,
                        message: pending.message
                    )
                    self.pendingPayment = nil
                }
                
            case .connecting:
                self.addDebugMessage("🔄 Connecting to \(peerID.displayName)")
                self.addDebugMessage("🔍 Session connected peers during connecting: \(session.connectedPeers.count)")
                
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                self.isConnected = !self.connectedPeers.isEmpty
                self.addDebugMessage("❌ Disconnected from \(peerID.displayName)")
                self.addDebugMessage("🔍 Remaining connected peers: \(self.connectedPeers.count)")
                
                // If we lost all connections and were browsing, restart browsing
                if !self.isConnected && !self.isBrowsing {
                    self.addDebugMessage("🔄 Restarting browsing after disconnection")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.startBrowsing()
                    }
                }
                
            @unknown default:
                self.addDebugMessage("⚠️ Unknown connection state with \(peerID.displayName)")
            }
        }
    }
    
    private func getStateString(_ state: MCSessionState) -> String {
        switch state {
        case .notConnected:
            return "Not Connected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        @unknown default:
            return "Unknown"
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.addDebugMessage("📨 Received data from \(peerID.displayName)")
            do {
                // Try to decode as PaymentRequest
                if let paymentRequest = try? JSONDecoder().decode(PaymentRequest.self, from: data) {
                    self.receivedPaymentRequest = paymentRequest
                    self.showPaymentRequest = true
                    self.addDebugMessage("💸 Received payment request from \(peerID.displayName): $\(paymentRequest.amount)")
                    return
                }
                
                // Try to decode as PaymentResponse
                if let paymentResponse = try? JSONDecoder().decode(PaymentResponse.self, from: data) {
                    self.addDebugMessage("📋 Received payment response from \(peerID.displayName)")
                    self.handlePaymentResponse(paymentResponse, from: peerID)
                    return
                }
                
                self.addDebugMessage("⚠️ Unknown data format received from \(peerID.displayName)")
            } catch {
                self.addDebugMessage("❌ Failed to decode received data: \(error)")
            }
        }
    }
    
    private func handlePaymentResponse(_ response: PaymentResponse, from peer: MCPeerID) {
        if response.accepted {
            addDebugMessage("✅ Payment accepted by \(peer.displayName)")
            // Handle successful payment
            if let transactionId = response.transactionId {
                addDebugMessage("📄 Transaction ID: \(transactionId)")
            }
        } else {
            addDebugMessage("❌ Payment rejected by \(peer.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used in this implementation
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used in this implementation
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used in this implementation
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension TapToSendService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        addDebugMessage("🎉 DELEGATE METHOD CALLED! advertiser(_:didReceiveInvitationFromPeer:)")
        addDebugMessage("📨 RECEIVED INVITATION from \(peerID.displayName)")
        addDebugMessage("🔍 Invitation context: \(context?.count ?? 0) bytes")
        addDebugMessage("🔍 My peer ID: \(myPeerID.displayName)")
        addDebugMessage("🔍 Session state: \(session.connectedPeers.count) connected peers")
        addDebugMessage("🔍 Advertiser delegate is active: ✅")
        addDebugMessage("🔍 Advertiser that received invitation: \(advertiser.myPeerID.displayName)")
        addDebugMessage("🔍 Service type match: \(advertiser.serviceType == serviceType ? "✅ YES" : "❌ NO")")
        
        // Check if we're already connected to this peer
        if connectedPeers.contains(peerID) {
            addDebugMessage("⚠️ Already connected to \(peerID.displayName), declining invitation")
            invitationHandler(false, nil)
            return
        }
        
        // Accept the invitation immediately
        addDebugMessage("✅ ACCEPTING invitation from \(peerID.displayName)")
        addDebugMessage("🔍 Using session: \(session)")
        addDebugMessage("🔍 Session peer count before: \(session.connectedPeers.count)")
        
        // Accept with the same session instance
        invitationHandler(true, session)
        
        // Monitor connection progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.addDebugMessage("🔍 1s after invitation - session peers: \(self.session.connectedPeers.count)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.addDebugMessage("🔍 3s after invitation - session peers: \(self.session.connectedPeers.count)")
            if self.session.connectedPeers.contains(peerID) {
                self.addDebugMessage("✅ SUCCESSFULLY CONNECTED to \(peerID.displayName)")
            } else {
                self.addDebugMessage("❌ CONNECTION FAILED to \(peerID.displayName)")
            }
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        addDebugMessage("❌ Failed to start advertising: \(error)")
        
        // Check for Local Network permission error
        if let nsError = error as NSError?, nsError.domain == "NSNetServicesErrorDomain" && nsError.code == -72008 {
            addDebugMessage("🚨 Local Network permission denied!")
            addDebugMessage("🔧 Attempting to request permission again...")
            
            // Try to request permission again
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.forceLocalNetworkPermissionRequest()
                
                // Try advertising again after permission request
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.addDebugMessage("🔄 Retrying advertising after permission request...")
                    self.advertiser.startAdvertisingPeer()
                }
            }
            
            showPermissionAlert(message: "Se requiere permiso de Red Local para tap-to-send. Ve a Configuración > Privacidad y Seguridad > Red Local y habilita el permiso para esta app. Si no aparece la app, reinicia la app y vuelve a intentar.")
        } else {
            // Other errors - try to recreate the session
            addDebugMessage("🔧 Unknown advertising error, recreating session...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.recreateMultipeerSession()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.addDebugMessage("🔄 Retrying advertising with new session...")
                    self.advertiser.startAdvertisingPeer()
                }
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension TapToSendService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        addDebugMessage("📱 Found peer: \(peerID.displayName)")
        addDebugMessage("🔍 Discovery info: \(info?.description ?? "nil")")
        addDebugMessage("🔍 My peer ID: \(myPeerID.displayName)")
        addDebugMessage("🔍 Session connected peers: \(session.connectedPeers.count)")
        addDebugMessage("🔍 Browser service type: \(browser.serviceType)")
        addDebugMessage("🔍 Expected service type: \(serviceType)")
        addDebugMessage("🔍 Service type match: \(browser.serviceType == serviceType ? "✅ YES" : "❌ NO")")
        
        // Check if we're already connected to this peer
        if connectedPeers.contains(peerID) {
            addDebugMessage("⚠️ Already connected to \(peerID.displayName)")
            addDebugMessage("💸 Checking if we have pending payment to send...")
            
            // If we have a pending payment, send it immediately
            if let pending = pendingPayment {
                addDebugMessage("💸 Sending pending payment to already connected \(peerID.displayName)")
                sendPaymentRequest(
                    to: peerID,
                    amount: pending.amount,
                    currency: pending.currency,
                    message: pending.message
                )
                pendingPayment = nil
                addDebugMessage("✅ Payment sent to already connected peer")
            } else {
                addDebugMessage("ℹ️ No pending payment to send")
            }
            return
        }
        
        // Auto-invite found peers with better error handling
        addDebugMessage("🤝 Inviting \(peerID.displayName) to session")
        addDebugMessage("🔍 Invitation timeout: 30 seconds")
        
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        
        // Add a check to see if invitation was sent
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.addDebugMessage("🔍 Post-invitation check - session peers: \(self.session.connectedPeers.count)")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        addDebugMessage("❌ Failed to start browsing: \(error)")
        
        // Check for Local Network permission error
        if let nsError = error as NSError?, nsError.domain == "NSNetServicesErrorDomain" && nsError.code == -72008 {
            addDebugMessage("🚨 Local Network permission denied!")
            showPermissionAlert(message: "Se requiere permiso de Red Local para tap-to-send. Ve a Configuración > Privacidad y Seguridad > Red Local y habilita el permiso para esta app. Si no aparece la app, reinicia la app y vuelve a intentar.")
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension TapToSendService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        addDebugMessage("🔵 Bluetooth state updated: \(central.state.rawValue)")
        switch central.state {
        case .poweredOn:
            addDebugMessage("✅ Bluetooth is powered on")
        case .poweredOff:
            addDebugMessage("❌ Bluetooth is powered off")
        case .unauthorized:
            addDebugMessage("❌ Bluetooth permission denied")
        case .unsupported:
            addDebugMessage("❌ Bluetooth not supported")
        case .resetting:
            addDebugMessage("⚠️ Bluetooth is resetting")
        case .unknown:
            addDebugMessage("⚠️ Bluetooth state unknown")
        @unknown default:
            addDebugMessage("⚠️ Unknown Bluetooth state")
        }
    }
}

// MARK: - Data Models
struct PaymentRequest: Codable, Identifiable, Equatable {
    let id: String
    let from: String
    let to: String
    let amount: Double
    let currency: String
    let message: String
    let timestamp: Date
}

struct PaymentResponse: Codable {
    let requestId: String
    let accepted: Bool
    let transactionId: String?
    let timestamp: Date
}

struct PendingPayment: Codable {
    let amount: Double
    let currency: String
    let message: String
    let timestamp: Date
}
