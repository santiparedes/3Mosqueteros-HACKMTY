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
    @Published var showPermissionAlert = false
    @Published var permissionAlertMessage = ""
    
    // Payment data
    @Published var pendingPayment: PendingPayment?
    @Published var paymentSent = false
    @Published var paymentResponse: PaymentResponse?
    
    // Permission monitoring
    private var bluetoothManager: CBCentralManager?
    private var networkMonitor: NWPathMonitor?
    
    override init() {
        super.init()
        setupMultipeerConnectivity()
        setupPermissionMonitoring()
    }
    
    private func setupMultipeerConnectivity() {
        
        // Create session with required encryption for better compatibility
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        // Create advertiser with same peer ID and session
        let discoveryInfo = [
            "device": UIDevice.current.name,
            "app": "QuantumWallet",
            "version": "1.0",
            "peerID": myPeerID.displayName
        ]
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser.delegate = self
        
        // Create browser with same peer ID
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
        
    }
    
    private func setupPermissionMonitoring() {
        // Monitor Bluetooth permissions
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        
        // Monitor network permissions
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                } else {
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor?.start(queue: queue)
        
        // Force Local Network permission request
        requestLocalNetworkPermission()
    }
    
    private func requestLocalNetworkPermission() {
        
        // Create a temporary network monitor to trigger permission request
        let tempMonitor = NWPathMonitor()
        tempMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
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
        
        // Try to create a local network connection to trigger permission
        let connection = NWConnection(host: "127.0.0.1", port: 8080, using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    break
                case .failed(let error):
                    break
                case .cancelled:
                    break
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
    
    
    private func checkPermissions() -> Bool {
        var hasAllPermissions = true
        
        // Check Bluetooth permission
        if let bluetoothManager = bluetoothManager {
            switch bluetoothManager.state {
            case .poweredOn:
                break
            case .poweredOff:
                hasAllPermissions = false
                showPermissionAlert(message: "Bluetooth is turned off. Please enable Bluetooth in Settings to use tap-to-send.")
            case .unauthorized:
                hasAllPermissions = false
                showPermissionAlert(message: "Bluetooth permission is required for tap-to-send. Please grant permission in Settings.")
            case .unsupported:
                hasAllPermissions = false
                showPermissionAlert(message: "Bluetooth is not supported on this device.")
            case .resetting:
                break
            case .unknown:
                break
            @unknown default:
                break
            }
        }
        
        // Check Local Network permission (iOS 14+)
        if #available(iOS 14.0, *) {
            
            // Try to detect Local Network permission status
            checkLocalNetworkPermissionStatus()
        }
        
        return hasAllPermissions
    }
    
    private func checkLocalNetworkPermissionStatus() {
        
        // Create a test connection to check permission
        let testConnection = NWConnection(host: "127.0.0.1", port: 8080, using: .tcp)
        testConnection.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    break
                case .failed(let error):
                    if let nsError = error as NSError?, nsError.code == -72008 {
                        // Local Network permission denied
                    } else {
                        // Other network error
                    }
                case .cancelled:
                    break
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
        
        // Try multiple methods to trigger Local Network permission
        let methods = [
            ("UDP Multicast", "224.0.0.1", 8080, NWParameters.udp),
            ("TCP Local", "127.0.0.1", 8080, NWParameters.tcp),
            ("Bonjour Service", "local.", 8080, NWParameters.tcp)
        ]
        
        for (method, host, port, params) in methods {
            
            let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: UInt16(port)), using: params)
            connection.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        break
                    case .failed(let error):
                        break
                    case .cancelled:
                        break
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
        
    }
    
    // MARK: - Public Methods
    
    func startAdvertising() {
        guard !isAdvertising else { 
            return 
        }
        
        // Force Local Network permission request before advertising
        forceLocalNetworkPermissionRequest()
        
        guard checkPermissions() else {
            return
        }
        
        
        // Ensure advertising starts on main thread
        DispatchQueue.main.async {
            
            self.advertiser.startAdvertisingPeer()
            self.isAdvertising = true
            
            // Add periodic status check
            self.startAdvertisingStatusCheck()
            
            // Start connection watchdog
            self.startConnectionWatchdog()
        }
    }
    
    private func startAdvertisingStatusCheck() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            if self.isAdvertising {
                
                // Connection watchdog - restart if no connections after 30 seconds
                if self.session.connectedPeers.isEmpty {
                }
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func startConnectionWatchdog() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if self.session.connectedPeers.isEmpty && self.isAdvertising {
                self.restartAdvertising()
            }
        }
    }
    
    private func restartAdvertising() {
        
        // Stop current advertising
        if isAdvertising {
            advertiser.stopAdvertisingPeer()
            isAdvertising = false
        }
        
        // Small delay then restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.advertiser.startAdvertisingPeer()
            self.isAdvertising = true
            
            // Start new watchdog
            self.startConnectionWatchdog()
        }
    }
    
    func stopAdvertising() {
        guard isAdvertising else { 
            return 
        }
        advertiser.stopAdvertisingPeer()
        isAdvertising = false
    }
    
    func startBrowsing() {
        
        // Force Local Network permission request before browsing
        forceLocalNetworkPermissionRequest()
        
        guard checkPermissions() else {
            return
        }
        
        
        // Stop any existing browsing first to ensure clean state
        if isBrowsing {
            browser.stopBrowsingForPeers()
            isBrowsing = false
        }
        
        // Ensure browsing starts on main thread
        DispatchQueue.main.async {
            self.startBrowsingWithRetry()
        }
    }
    
    private func startBrowsingWithRetry(attempt: Int = 1) {
        
        // Ensure we're not already browsing
        if isBrowsing {
            browser.stopBrowsingForPeers()
            isBrowsing = false
        }
        
        // Small delay to ensure clean state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.browser.startBrowsingForPeers()
            self.isBrowsing = true
        }
    }
    
    func stopBrowsing() {
        guard isBrowsing else { 
            return 
        }
        browser.stopBrowsingForPeers()
        isBrowsing = false
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
        
        
        // If already connected, send payment immediately
        if !connectedPeers.isEmpty {
            sendPendingPaymentToConnectedPeers()
        } else {
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
        paymentSent = false
        paymentResponse = nil
        
    }
    
    func resetService() {
        
        // Disconnect everything
        disconnect()
        
        // Recreate the session
        recreateMultipeerSession()
        
    }
    
    func forceRestartBrowsing() {
        
        // Always stop browsing first
        if isBrowsing {
            browser.stopBrowsingForPeers()
            isBrowsing = false
        }
        
        // Small delay then restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startBrowsing()
        }
    }
    
    func testAdvertiserDelegate() {
        
        // Test if we can call the delegate method (this won't actually work but shows the method exists)
        if advertiser?.delegate != nil {
        } else {
        }
    }
    
    func sendPendingPaymentToConnectedPeers() {
        
        if let pending = pendingPayment, !connectedPeers.isEmpty {
            for peer in connectedPeers {
                sendPaymentRequest(
                    to: peer,
                    amount: pending.amount,
                    currency: pending.currency,
                    message: pending.message
                )
            }
            pendingPayment = nil
        } else if pendingPayment == nil {
        } else {
        }
    }
}

// MARK: - MCSessionDelegate
extension TapToSendService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                self.isConnected = true
                
                // Stop browsing once connected to avoid conflicts
                if self.isBrowsing {
                    self.browser.stopBrowsingForPeers()
                    self.isBrowsing = false
                }
                
                // Also stop advertising once connected to avoid duplicate connections
                if self.isAdvertising {
                    self.advertiser.stopAdvertisingPeer()
                    self.isAdvertising = false
                }
                
                // If we have a pending payment, send it immediately
                if let pending = self.pendingPayment {
                    self.sendPaymentRequest(
                        to: peerID,
                        amount: pending.amount,
                        currency: pending.currency,
                        message: pending.message
                    )
                    self.pendingPayment = nil
                }
                
            case .connecting:
                break
                
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                self.isConnected = !self.connectedPeers.isEmpty
                
                // If we lost all connections and were browsing, restart browsing
                if !self.isConnected && !self.isBrowsing {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.startBrowsing()
                    }
                }
                
            @unknown default:
                break
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
            do {
                // Try to decode as PaymentRequest
                if let paymentRequest = try? JSONDecoder().decode(PaymentRequest.self, from: data) {
                    self.receivedPaymentRequest = paymentRequest
                    self.showPaymentRequest = true
                    return
                }
                
                // Try to decode as PaymentResponse
                if let paymentResponse = try? JSONDecoder().decode(PaymentResponse.self, from: data) {
                    self.handlePaymentResponse(paymentResponse, from: peerID)
                    return
                }
                
            } catch {
            }
        }
    }
    
    private func handlePaymentResponse(_ response: PaymentResponse, from peer: MCPeerID) {
        DispatchQueue.main.async {
            self.paymentResponse = response
            
            if response.accepted {
                self.paymentSent = true
                // Handle successful payment
                if let transactionId = response.transactionId {
                }
            } else {
                self.paymentSent = false
            }
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
        
        // Check if we're already connected to this peer
        if connectedPeers.contains(peerID) {
            invitationHandler(false, nil)
            return
        }
        
        // Accept the invitation immediately
        
        // Accept with the same session instance
        invitationHandler(true, session)
        
        // Monitor connection progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.session.connectedPeers.contains(peerID) {
            } else {
            }
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        
        // Check for Local Network permission error
        if let nsError = error as NSError?, nsError.domain == "NSNetServicesErrorDomain" && nsError.code == -72008 {
            
            // Try to request permission again
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.forceLocalNetworkPermissionRequest()
                
                // Try advertising again after permission request
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.advertiser.startAdvertisingPeer()
                }
            }
            
            showPermissionAlert(message: "Se requiere permiso de Red Local para tap-to-send. Ve a Configuración > Privacidad y Seguridad > Red Local y habilita el permiso para esta app. Si no aparece la app, reinicia la app y vuelve a intentar.")
        } else {
            // Other errors - try to recreate the session
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.recreateMultipeerSession()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.advertiser.startAdvertisingPeer()
                }
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension TapToSendService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        // Check if we're already connected to this peer
        if connectedPeers.contains(peerID) {
            
            // If we have a pending payment, send it immediately
            if let pending = pendingPayment {
                sendPaymentRequest(
                    to: peerID,
                    amount: pending.amount,
                    currency: pending.currency,
                    message: pending.message
                )
                pendingPayment = nil
            } else {
            }
            return
        }
        
        // Auto-invite found peers with better error handling
        
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        
        // Add a check to see if invitation was sent
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        
        // Check for Local Network permission error
        if let nsError = error as NSError?, nsError.domain == "NSNetServicesErrorDomain" && nsError.code == -72008 {
            showPermissionAlert(message: "Se requiere permiso de Red Local para tap-to-send. Ve a Configuración > Privacidad y Seguridad > Red Local y habilita el permiso para esta app. Si no aparece la app, reinicia la app y vuelve a intentar.")
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension TapToSendService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            break
        case .poweredOff:
            break
        case .unauthorized:
            break
        case .unsupported:
            break
        case .resetting:
            break
        case .unknown:
            break
        @unknown default:
            break
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
