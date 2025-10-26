import SwiftUI
import MultipeerConnectivity

struct TapToSendView: View {
    @StateObject private var tapToSendService = TapToSendService.shared
    @StateObject private var quantumAPI = QuantumAPI.shared
    @StateObject private var userManager = UserManager.shared
    @StateObject private var deepLinkService = DeepLinkService.shared
    @StateObject private var biometricAuth = BiometricAuthService.shared
    
    @State private var amount: Double = 100.0
    @State private var message: String = ""
    @State private var currency: String = "MXN"
    @State private var showAmountInput = false
    @State private var isProcessingPayment = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var showShareSheet = false
    @State private var showBiometricAuth = false
    @State private var showConfirmation = false
    @State private var isSendingMode = true // true for sending, false for receiving
    @State private var showWaitingForPayment = false
    @State private var showPaymentReceived = false
    @State private var showConnectionConfirmation = false
    @State private var showPaymentSentSuccess = false
    @State private var showPaymentConfirmation = false
    
    // Animation states
    @State private var isPulsing = false
    @State private var isScanning = false
    @State private var connectionPulse = false
    @State private var showParticles = false
    @State private var deviceFound = false
    @State private var connectionEstablished = false
    @State private var paymentSent = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Only show content if not going directly to auth
                if !showBiometricAuth {
                    ScrollView {
                        VStack(spacing: 40) {
                            Spacer(minLength: 20)
                            headerSection
                            Spacer(minLength: 20)
                            actionButtonsSection
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationTitle("NepPay")
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if paymentSent {
                        // Success state - show print receipt in toolbar
                        Button(action: {
                            printReceipt()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "printer.fill")
                                    .font(.system(size: 16))
                                Text("Receipt")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.green)
                        }
                    } else {
                        // Normal state - show back to main
                        Button("Back") {
                            tapToSendService.disconnect()
                            dismiss()
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $tapToSendService.showPaymentRequest) {
            if let request = tapToSendService.receivedPaymentRequest {
                PaymentRequestView(paymentRequest: request)
            }
        }
        .sheet(isPresented: $showPaymentConfirmation) {
            if let response = tapToSendService.paymentResponse {
                PaymentConfirmationView(
                    paymentResponse: response,
                    amount: amount,
                    message: message,
                    onDone: {
                        print("🔄 TapToSendView: PaymentConfirmationView onDone called")
                        showPaymentConfirmation = false
                        print("✅ TapToSendView: Setting showPaymentSentSuccess = true")
                        showPaymentSentSuccess = true
                    }
                )
            } else {
                Text("Payment response not available")
            }
        }
        .alert("Payment Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
        .alert("Payment Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Something went wrong, try again", isPresented: $tapToSendService.showPermissionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please try again or check your device settings.")
        }
        .onDisappear {
            tapToSendService.disconnect()
            biometricAuth.logout()
        }
        .fullScreenCover(isPresented: $showBiometricAuth) {
            BiometricAuthView(
                onSuccess: {
                    // After auth, go to connection screen first (not confirmation)
                    showBiometricAuth = false
                    showConnectionConfirmation = true
                },
                onCancel: {
                    showBiometricAuth = false
                }
            )
        }
        .fullScreenCover(isPresented: $showConfirmation) {
            ConfirmationView(
                amount: amount,
                message: message,
                currency: currency,
                onConfirm: { confirmedAmount, confirmedMessage in
                    // Update the amount and message with edited values
                    amount = confirmedAmount
                    message = confirmedMessage
                    
                    // Send the payment immediately since we're already connected
                    tapToSendService.initiateTapToSend(
                        amount: confirmedAmount,
                        currency: currency,
                        message: confirmedMessage
                    )
                    
                    showConfirmation = false
                    // Don't show search sheet - go straight to success when payment is confirmed
                },
                onCancel: {
                    showConfirmation = false
                }
            )
        }
        .fullScreenCover(isPresented: $showWaitingForPayment) {
            WaitingForPaymentView(
                onCancel: {
                    showWaitingForPayment = false
                },
                onPaymentReceived: { receivedAmount, receivedMessage in
                    amount = receivedAmount
                    message = receivedMessage
                    showWaitingForPayment = false
                    showPaymentReceived = true
                }
            )
        }
        .fullScreenCover(isPresented: $showConnectionConfirmation) {
            ConnectionConfirmationView(
                isSendingMode: isSendingMode,
                onConfirm: {
                    showConnectionConfirmation = false
                    if isSendingMode {
                        // Sender: Go to amount confirmation after connection
                        showConfirmation = true
                    } else {
                        // Receiver: Go to waiting for payment
                        showWaitingForPayment = true
                    }
                },
                onCancel: {
                    showConnectionConfirmation = false
                }
            )
        }
        .fullScreenCover(isPresented: $showPaymentReceived) {
            EnhancedPaymentReceivedView(
                amount: amount,
                message: message,
                onDone: {
                    showPaymentReceived = false
                    dismiss()
                }
            )
        }
        .fullScreenCover(isPresented: $showPaymentSentSuccess) {
            EnhancedPaymentSentSuccessView(
                amount: amount,
                message: message,
                onDone: {
                    print("🔄 TapToSendView: EnhancedPaymentSentSuccessView onDone called")
                    showPaymentSentSuccess = false
                    dismiss()
                }
            )
        }
        .onChange(of: tapToSendService.isConnected) { isConnected in
            if isConnected {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    connectionEstablished = true
                    connectionPulse = true
                }
            } else {
                connectionEstablished = false
                connectionPulse = false
            }
        }
        .onChange(of: tapToSendService.connectedPeers.count) { count in
            if count > 0 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    deviceFound = true
                }
            } else {
                deviceFound = false
            }
        }
        .onChange(of: tapToSendService.paymentSent) { sent in
            print("🔄 TapToSendView: paymentSent changed to \(sent)")
            if sent {
                print("✅ TapToSendView: Payment was sent successfully, showing confirmation sheet")
                print("🔄 TapToSendView: paymentResponse is nil: \(tapToSendService.paymentResponse == nil)")
                // Payment was sent successfully, show confirmation sheet
                showPaymentConfirmation = true
                paymentSent = true
            }
        }
        .onChange(of: showPaymentConfirmation) { isShowing in
            if isShowing {
                print("🔄 TapToSendView: PaymentConfirmationView sheet is being presented")
            }
        }
        .onChange(of: showPaymentSentSuccess) { isShowing in
            if isShowing {
                print("🔄 TapToSendView: EnhancedPaymentSentSuccessView fullScreenCover is being presented")
            }
        }
        .onAppear {
            startHeaderAnimations()
            loadWidgetAmount()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 32) {
            // Modern animated icon with gradient
            ZStack {
                // Outer glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.2),
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true),
                        value: isPulsing
                    )
                
                // Main background circle - solid blue
                Circle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 100)
                    .scaleEffect(connectionEstablished ? 1.15 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: connectionEstablished)
                    .shadow(color: .blue.opacity(0.2), radius: 15, x: 0, y: 5)
                
                // Icon inside
                Image(systemName: getHeaderIcon())
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(connectionEstablished ? 1.2 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: connectionEstablished)
            }
            
            // Enhanced typography with better hierarchy
            VStack(spacing: 16) {
                Text(getHeaderTitle())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    
                Text(getHeaderSubtitle())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 20)
            }
            
            // Send/Receive Mode Selection
            HStack(spacing: 0) {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSendingMode = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text("Send")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(isSendingMode ? .white : .blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSendingMode ? Color.blue : Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSendingMode = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text("Receive")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(!isSendingMode ? .white : .blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(!isSendingMode ? Color.blue : Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 40)
            
        }
        .padding(.top, 20)
    }
    
    
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 20) {
            // Primary Action Button - Enhanced design with gradient
            Button(action: {
                if isSendingMode {
                    // Send mode - go to auth then confirmation
                    showBiometricAuth = true
                } else {
                    // Receive mode - go to connection confirmation first
                    showConnectionConfirmation = true
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: isSendingMode ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text(isSendingMode ? "Send Money" : "Receive Money")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Secondary Action Buttons Row
            HStack(spacing: 16) {
                // Share payment link button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        deepLinkService.sharePaymentRequest(
                            amount: amount,
                            currency: currency,
                            message: message
                        )
                    }
                }) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Share Link")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Go Back button
                Button(action: {
                    tapToSendService.disconnect()
                    dismiss()
                }) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Go Back")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Animation Functions
    
    private func startHeaderAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
    
    private func getHeaderIcon() -> String {
        if connectionEstablished {
            return "checkmark.circle.fill"
        } else if isScanning {
            return "wave.3.right"
        } else {
            return "hand.tap.fill"
        }
    }
    
    private func getHeaderTitle() -> String {
        if connectionEstablished {
            return "Connected! 🎉"
        } else if deviceFound {
            return "Device Found! 📱"
        } else if isScanning {
            return "Searching... 🔍"
        } else {
            return "NepPay"
        }
    }
    
    private func getHeaderSubtitle() -> String {
        if connectionEstablished {
            return "Payment request sent successfully!"
        } else if deviceFound {
            return "Bring devices closer to connect"
        } else if isScanning {
            return "Looking for nearby devices..."
        } else {
            return "Send money instantly with a simple tap"
        }
    }
    
    
    private func loadWidgetAmount() {
        let sharedDefaults = UserDefaults(suiteName: "group.tec.mx.nep")
        if let widgetAmount = sharedDefaults?.integer(forKey: "selectedAmount"), widgetAmount > 0 {
            amount = Double(widgetAmount)
            // Load currency from widget
            if let widgetCurrency = sharedDefaults?.string(forKey: "selectedCurrency") {
                currency = widgetCurrency
            }
            // Clear the widget data after loading
            sharedDefaults?.removeObject(forKey: "selectedAmount")
            sharedDefaults?.removeObject(forKey: "selectedCurrency")
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    
    private func printReceipt() {
        // Create receipt data
        let receiptData = [
            "Date": DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short),
            "Amount": formatCurrency(amount),
            "Message": message.isEmpty ? "No message" : message,
            "Status": "Completed",
            "Transaction ID": UUID().uuidString.prefix(8).uppercased()
        ]
        
        // Show print options
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "Payment Receipt"
        printController.printInfo = printInfo
        
        // Create receipt content
        let receiptContent = createReceiptContent(data: receiptData)
        printController.printFormatter = receiptContent
        
        // Present print dialog
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            printController.present(animated: true) { controller, completed, error in
                if completed {
                    print("Receipt printed successfully")
                } else if let error = error {
                    print("Print error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func createReceiptContent(data: [String: String]) -> UISimpleTextPrintFormatter {
        var receiptText = "NEP PAYMENT RECEIPT\n"
        receiptText += "==================\n\n"
        
        for (key, value) in data {
            receiptText += "\(key): \(value)\n"
        }
        
        receiptText += "\nThank you for using NepPay!"
        
        return UISimpleTextPrintFormatter(text: receiptText)
    }
    
}

struct AnimatedStatusView: View {
    let status: TapToSendStatus
    let amount: Double
    let message: String
    @Binding var isPulsing: Bool
    @Binding var isScanning: Bool
    @Binding var deviceFound: Bool
    @Binding var connectionEstablished: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated Status Icon
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                status.color.opacity(0.4),
                                status.color.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)
                    .opacity(isPulsing ? 0.6 : 0.4)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: isPulsing
                    )
                
                // Main icon
                Image(systemName: getStatusIcon())
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(status.color)
                    .scaleEffect(connectionEstablished ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: connectionEstablished)
                
                // Simple scanning indicator
                if isScanning {
                        Circle()
                            .stroke(status.color.opacity(0.3), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .opacity(0.6)
                        .scaleEffect(isScanning ? 1.2 : 1.0)
                            .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                                value: isScanning
                            )
                }
                
                // Connection particles
                if connectionEstablished {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(Color.nepAccent)
                            .frame(width: 6, height: 6)
                            .offset(
                                x: cos(Double(index) * .pi / 3) * 40,
                                y: sin(Double(index) * .pi / 3) * 40
                            )
                            .opacity(connectionEstablished ? 1.0 : 0.0)
                            .scaleEffect(connectionEstablished ? 1.0 : 0.0)
                            .animation(
                                Animation.spring(response: 0.8, dampingFraction: 0.6)
                                    .delay(Double(index) * 0.1),
                                value: connectionEstablished
                            )
                    }
                }
            }
            
            // Status Text with Animation
            VStack(spacing: 8) {
                Text(getStatusTitle())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .scaleEffect(deviceFound ? 1.05 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: deviceFound)
                
                Text(getStatusDescription())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Amount Display with Animation
            if amount > 0 {
                VStack(spacing: 8) {
                        Text("Amount")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Text("$")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text(String(format: "%.2f", amount))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                                .contentTransition(.numericText())
                        }
                    .scaleEffect(connectionEstablished ? 1.1 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: connectionEstablished)
                }
                .padding(.top, 8)
            }
            
            // Message Display
            if !message.isEmpty {
                VStack(spacing: 4) {
                    Text("Message")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    status.color.opacity(0.3),
                                    status.color.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private func getStatusIcon() -> String {
        switch status {
        case .idle:
            return "iphone"
        case .advertising:
            return "iphone.radiowaves.left.and.right"
        case .browsing:
            return "magnifyingglass"
        case .connected:
            return "checkmark.circle.fill"
        }
    }
    
    private func getStatusTitle() -> String {
        switch status {
        case .idle:
            return "Ready to Send"
        case .advertising:
            return "Waiting for Device"
        case .browsing:
            return "Searching for Devices"
        case .connected:
            return "Connected! 🎉"
        }
    }
    
    private func getStatusDescription() -> String {
        switch status {
        case .idle:
            return "Set an amount and tap 'Start Tap to Send' to begin"
        case .advertising:
            return "Bring another device close and tap them together"
        case .browsing:
            return "Looking for nearby devices to connect with"
        case .connected:
            return "Device connected! Payment will be sent automatically"
        }
    }
}

// MARK: - Particle View for Background Animation
struct ParticleView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(Color.nepBlue.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .animation(
                        Animation.linear(duration: particle.duration)
                            .repeatForever(autoreverses: false),
                        value: particle.position
                    )
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        particles = (0..<20).map { _ in
            Particle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.1...0.3),
                duration: Double.random(in: 3...8)
            )
        }
        
        // Animate particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for i in particles.indices {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                )
            }
        }
    }
}

struct Particle {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    let opacity: Double
    let duration: Double
}

struct TapToSendStatusView: View {
    let status: TapToSendStatus
    let amount: Double
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: status.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(status.color)
            }
            
            // Status Text
            Text(status.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.nepTextLight)
            
            Text(status.description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.nepTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Amount Display
            if amount > 0 {
                VStack(spacing: 4) {
                    Text("Amount")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                    
                    Text(formatCurrency(amount))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.nepTextLight)
                }
                .padding(.top, 8)
            }
            
            // Message Display
            if !message.isEmpty {
                VStack(spacing: 4) {
                    Text("Message")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                    
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

enum TapToSendStatus {
    case idle
    case advertising
    case browsing
    case connected
    
    var icon: String {
        switch self {
        case .idle:
            return "iphone"
        case .advertising:
            return "iphone.radiowaves.left.and.right"
        case .browsing:
            return "magnifyingglass"
        case .connected:
            return "checkmark.circle.fill"
        }
    }
    
    var title: String {
        switch self {
        case .idle:
            return "Ready to Send"
        case .advertising:
            return "Waiting for Device"
        case .browsing:
            return "Searching for Devices"
        case .connected:
            return "Connected"
        }
    }
    
    var description: String {
        switch self {
        case .idle:
            return "Set an amount and tap 'Start Tap to Send' to begin"
        case .advertising:
            return "Bring another device close and tap them together"
        case .browsing:
            return "Looking for nearby devices to connect with"
        case .connected:
            return "Device connected! Payment will be sent automatically"
        }
    }
    
    var color: Color {
        switch self {
        case .idle:
            return .nepTextSecondary
        case .advertising:
            return .nepBlue
        case .browsing:
            return .orange
        case .connected:
            return .green
        }
    }
}

struct PaymentRequestView: View {
    let paymentRequest: PaymentRequest
    @StateObject private var tapToSendService = TapToSendService.shared
    @StateObject private var quantumAPI = QuantumAPI.shared
    @StateObject private var receiptService = QuantumReceiptService.shared
    @State private var isProcessing = false
    @State private var showReceipt = false
    @State private var generatedReceipt: QuantumReceipt?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Payment Request")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.nepTextLight)
                    
                    Text("from \(paymentRequest.from)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                }
                .padding(.top, 20)
                
                // Payment Details
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Amount")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.nepTextSecondary)
                        
                        Text(formatCurrency(paymentRequest.amount))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.nepTextLight)
                    }
                    
                    if !paymentRequest.message.isEmpty {
                        VStack(spacing: 8) {
                            Text("Message")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.nepTextSecondary)
                            
                            Text(paymentRequest.message)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.nepTextLight)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
                .background(Color.nepCardBackground.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        print("🔄 PaymentRequestView: Accept Payment button tapped")
                        print("🔄 PaymentRequestView: isProcessing = \(isProcessing)")
                        print("🔄 PaymentRequestView: paymentRequest = \(paymentRequest)")
                        
                        Task {
                            await acceptPayment()
                        }
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle")
                            }
                            Text("Accept Payment")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessing ? Color.gray : Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        rejectPayment()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Decline")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color.nepDarkBackground)
            .navigationTitle("Payment Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showReceipt) {
            if let receipt = generatedReceipt {
                QuantumReceiptView(receipt: receipt)
            }
        }
    }
    
    private func acceptPayment() async {
        print("🔄 PaymentRequestView: Starting acceptPayment...")
        
        await MainActor.run {
            isProcessing = true
        }
        
        do {
            // Find the peer who sent the request
            let peer = tapToSendService.connectedPeers.first { peer in
                peer.displayName == paymentRequest.from
            }
            
            guard let targetPeer = peer else {
                print("❌ PaymentRequestView: Could not find peer for payment request")
                await MainActor.run {
                    isProcessing = false
                }
                return
            }
            
            print("✅ PaymentRequestView: Found peer: \(targetPeer.displayName)")
            
            // Process the quantum payment
            print("🔄 PaymentRequestView: Processing quantum payment...")
            let transactionId = try await processQuantumPayment(
                amount: paymentRequest.amount,
                currency: paymentRequest.currency
            )
            
            print("✅ PaymentRequestView: Payment processed successfully: \(transactionId)")
            
            // Generate quantum receipt
            print("🔐 PaymentRequestView: Generating quantum receipt...")
            let quantumReceipt = try await receiptService.generateReceiptForNepPayTransaction(
                transactionId: transactionId,
                fromAccountId: getCurrentAccountId(),
                toAccountId: getReceiverAccountId(),
                amount: paymentRequest.amount,
                currency: paymentRequest.currency
            )
            
            print("✅ PaymentRequestView: Quantum receipt generated successfully")
            
            // Send acceptance response
            tapToSendService.sendPaymentResponse(
                to: targetPeer,
                requestId: paymentRequest.id,
                accepted: true,
                transactionId: transactionId
            )
            
            print("✅ PaymentRequestView: Payment response sent")
            
            // Show quantum receipt and dismiss payment request
            await MainActor.run {
                self.generatedReceipt = quantumReceipt
                self.showReceipt = true
                self.isProcessing = false
                // Dismiss the payment request view
                dismiss()
            }
            
        } catch {
            print("❌ PaymentRequestView: Failed to process payment: \(error)")
            
            // Try to generate quantum receipt even if payment failed
            do {
                print("🔄 PaymentRequestView: Attempting to generate quantum receipt despite payment error...")
                let quantumReceipt = try await receiptService.generateReceiptForNepPayTransaction(
                    transactionId: "error_recovery_\(Int.random(in: 100000...999999))",
                    fromAccountId: getCurrentAccountId(),
                    toAccountId: getReceiverAccountId(),
                    amount: paymentRequest.amount,
                    currency: paymentRequest.currency
                )
                
                // Send rejection response
                if let peer = tapToSendService.connectedPeers.first(where: { $0.displayName == paymentRequest.from }) {
                    tapToSendService.sendPaymentResponse(
                        to: peer,
                        requestId: paymentRequest.id,
                        accepted: false
                    )
                }
                
                // Show quantum receipt even for failed payment
                await MainActor.run {
                    self.generatedReceipt = quantumReceipt
                    self.showReceipt = true
                    self.isProcessing = false
                    dismiss()
                }
                
            } catch {
                // Send rejection response
                if let peer = tapToSendService.connectedPeers.first(where: { $0.displayName == paymentRequest.from }) {
                    tapToSendService.sendPaymentResponse(
                        to: peer,
                        requestId: paymentRequest.id,
                        accepted: false
                    )
                }
                
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            }
        }
    }
    
    private func rejectPayment() {
        // Find the peer who sent the request
        let peer = tapToSendService.connectedPeers.first { peer in
            peer.displayName == paymentRequest.from
        }
        
        if let targetPeer = peer {
            tapToSendService.sendPaymentResponse(
                to: targetPeer,
                requestId: paymentRequest.id,
                accepted: false
            )
        }
        
        dismiss()
    }
    
    private func processQuantumPayment(amount: Double, currency: String) async throws -> String {
        // Use the real transaction processor
        let transactionProcessor = TransactionProcessor.shared
        
        do {
            // Get the current user's account ID (Carlos or Maria)
            let currentAccountId = getCurrentAccountId()
            let receiverAccountId = getReceiverAccountId()
            
            print("🔄 PaymentRequestView: Processing payment from \(currentAccountId) to \(receiverAccountId)")
            
            // Process the transaction with real account IDs
            let result = try await transactionProcessor.processTransaction(
                fromAccountId: currentAccountId,
                toAccountId: receiverAccountId,
                amount: amount,
                description: "NepPay Transfer"
            )
            
            print("✅ PaymentRequestView: Transaction processed successfully")
            print("   Transaction ID: \(result.transactionId)")
            print("   New sender balance: $\(result.newSenderBalance)")
            print("   New receiver balance: $\(result.newReceiverBalance)")
            
            return result.transactionId
            
        } catch {
            print("❌ PaymentRequestView: Transaction failed - \(error)")
            throw error
        }
    }
    
    private func getCurrentAccountId() -> String {
        // Use Maria's account as the sender (the one sending money)
        // This should be improved to use a proper shared instance
        return APIConfig.testAccountId // Maria's account (the sender)
    }
    
    private func getReceiverAccountId() -> String {
        // Always send to Sofia's checking account
        return "e8e10efc-53c7-4fb2-9947-"
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = paymentRequest.currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Confirmation View
struct ConfirmationView: View {
    @State private var editableAmount: Double
    @State private var editableMessage: String
    @State private var isEditingAmount = false
    @State private var isEditingMessage = false
    let currency: String
    let onConfirm: (Double, String) -> Void
    let onCancel: () -> Void
    
    init(amount: Double, message: String, currency: String, onConfirm: @escaping (Double, String) -> Void, onCancel: @escaping () -> Void) {
        self._editableAmount = State(initialValue: amount)
        self._editableMessage = State(initialValue: message)
        self.currency = currency
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Amount display
                VStack(spacing: 16) {
                    Text("Confirm Payment")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        Text("Amount")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if isEditingAmount {
                            TextField("0.00", value: $editableAmount, format: .currency(code: currency))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.blue)
                                .onSubmit {
                                    isEditingAmount = false
                                }
                        } else {
                            Text(formatCurrency(editableAmount))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    isEditingAmount = true
                                }
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Text("Message")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if isEditingMessage {
                            TextField("Add a note...", text: $editableMessage)
                                .font(.system(size: 19, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .onSubmit {
                                    isEditingMessage = false
                                }
                        } else {
                            if editableMessage.isEmpty {
                                Text("Tap to add a message")
                                    .font(.system(size: 19, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        isEditingMessage = true
                                    }
                            } else {
                                Text(editableMessage)
                                    .font(.system(size: 19, weight: .medium))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .onTapGesture {
                                        isEditingMessage = true
                                    }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onConfirm(editableAmount, editableMessage)
                    }) {
                        Text("Confirm")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(Color(.systemBackground))
            .navigationTitle("Confirm Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}


// MARK: - Search Progress View
struct SearchProgressView: View {
    let onCancel: () -> Void
    
    @StateObject private var tapToSendService = TapToSendService.shared
    @State private var currentStep = 0
    @State private var isSearching = true
    @State private var searchResult: SearchResult? = nil
    @State private var showConfetti = false
    
    enum SearchResult {
        case success
        case failed
    }
    
    private let searchSteps = [
        "Initializing connection",
        "Scanning for devices",
        "Establishing secure link",
        "Verifying device identity"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                if let result = searchResult {
                    // Success/Failure State
                    Spacer()

                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(result == .success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .scaleEffect(showConfetti ? 1.2 : 1.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showConfetti)
                            
                            Image(systemName: result == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundColor(result == .success ? .green : .red)
                                .scaleEffect(showConfetti ? 1.1 : 1.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showConfetti)
                        }
                        
                        VStack(spacing: 12) {
                            Text(result == .success ? "Money Sent! 🎉" : "Connection Failed")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(result == .success ? 
                                 "Payment sent successfully!" : 
                                 "Unable to connect to device. Please try again.")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                        
                        if result == .success {
                            Button(action: {
                                onCancel()
                            }) {
                                Text("Done")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.green)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Button(action: {
                                // Go back to confirmation screen
                                onCancel()
                            }) {
                                Text("Go Back")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.blue)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } else if isSearching {
                    // Searching State with Progress
                    VStack(spacing: 32) {
                        
                        VStack(spacing: 60) {
                            // Animated instruction text in center with status circles
                            Spacer()
                            // Combined checkmarks and instructions that move together as one unit
                            ZStack {
                                ForEach(0..<searchSteps.count, id: \.self) { index in
                                    stepUnitView(for: index)
                                        .offset(y: CGFloat(index - currentStep) * 50)
                                        .opacity(index == currentStep ? 1.0 : max(0.1, 1.0 - Double(abs(index - currentStep)) * 0.3))
                                        .scaleEffect(index == currentStep ? 1.0 : max(0.6, 1.0 - Double(abs(index - currentStep)) * 0.2))
                                        .animation(.easeInOut(duration: 0.5), value: currentStep)
                                }
                            }
                            .frame(height: 60)
                            
                            Spacer()
                            
                            // Normal loading icon moved down
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        }
                    }
                }
                
                Spacer()
                
                // No cancel button - user must wait for result
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(Color(.systemBackground))
            .navigationTitle("NepPay")
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            startSearchProgress()
            // Browsing is already started from confirmation screen
            // Just monitor the connection status
        }
        .onDisappear {
            tapToSendService.stopBrowsing()
        }
        .onChange(of: tapToSendService.isConnected) { isConnected in
            if isConnected {
                // Connection established, but wait for payment response
                print("🔗 Connection established, waiting for payment response...")
            }
        }
        .onChange(of: tapToSendService.paymentSent) { paymentSent in
            if paymentSent {
                // Payment was sent successfully
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    searchResult = .success
                    isSearching = false
                    showConfetti = true
                }
            }
        }
    }
    
    private func startSearchProgress() {
        // Simulate progress steps
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            if currentStep < searchSteps.count - 1 {
                currentStep += 1
            } else {
                timer.invalidate()
                // Simulate timeout after all steps
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if !tapToSendService.isConnected {
                        searchResult = .failed
                        isSearching = false
                    }
                }
            }
        }
        
        tapToSendService.startBrowsing()
    }
    
    private func getCircleColor(for index: Int) -> Color {
        if index < currentStep {
            return .green // Completed steps
        } else if index == currentStep {
            return .blue // Current step
        } else {
            return .gray.opacity(0.3) // Future steps
        }
    }
    
    private func instructionText(for index: Int) -> some View {
        Text(searchSteps[index])
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.primary)
    }
    
    private func stepUnitView(for index: Int) -> some View {
        HStack(spacing: 20) {
            // Status circle with perfectly centered checkmark - this is one unit
            ZStack {
                Circle()
                    .fill(getCircleColor(for: index))
                    .frame(width: 24, height: 24)
                
                if index < currentStep {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                } else if index == currentStep {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 24, height: 24)
                }
            }
            .frame(width: 24, height: 24)
            
            // Instruction text - this moves with the circle as one unit
            Text(searchSteps[index])
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Waiting For Payment View
struct WaitingForPaymentView: View {
    let onCancel: () -> Void
    let onPaymentReceived: (Double, String) -> Void
    
    @StateObject private var tapToSendService = TapToSendService.shared
    @State private var isPulsing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // Waiting animation
                VStack(spacing: 24) {
                    ZStack {
                        // Multiple pulsing background circles for depth
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isPulsing ? 1.3 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isPulsing
                            )
                        
                        Circle()
                            .fill(Color.blue.opacity(0.05))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isPulsing ? 1.5 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.8)
                                    .repeatForever(autoreverses: true)
                                    .delay(0.3),
                                value: isPulsing
                            )
                        
                        // Main icon with pulsing animation - synchronized with background
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.blue)
                            .scaleEffect(isPulsing ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isPulsing
                            )
                    }
                    
                    VStack(spacing: 12) {
                        Text("Waiting for Payment")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Bring another device close and tap them together to receive money")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Cancel button
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(Color(.systemBackground))
            .navigationTitle("Receive Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            isPulsing = true
            tapToSendService.startAdvertising()
        }
        .onDisappear {
            tapToSendService.stopAdvertising()
        }
        .onChange(of: tapToSendService.receivedPaymentRequest) { request in
            if let paymentRequest = request {
                onPaymentReceived(paymentRequest.amount, paymentRequest.message)
            }
        }
    }
}

// MARK: - Payment Received View
struct PaymentReceivedView: View {
    let amount: Double
    let message: String
    let onDone: () -> Void
    
    @State private var showConfetti = false
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // Success animation
                VStack(spacing: 24) {
                    ZStack {
                        // Confetti background
                        if showConfetti {
                            ForEach(0..<20, id: \.self) { index in
                                Circle()
                                    .fill([Color.blue, Color.green, Color.orange, Color.purple].randomElement() ?? .blue)
                                    .frame(width: 8, height: 8)
                                    .offset(
                                        x: CGFloat.random(in: -100...100),
                                        y: CGFloat.random(in: -100...100)
                                    )
                                    .opacity(showConfetti ? 0 : 1)
                                    .animation(
                                        Animation.easeOut(duration: 2.0)
                                            .delay(Double(index) * 0.1),
                                        value: showConfetti
                                    )
                            }
                        }
                        
                        // Success icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundColor(.green)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Hey, you got money! 🎉")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(formatCurrency(amount))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        
                        if !message.isEmpty {
                            Text("\"\(message)\"")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .italic()
                        }
                    }
                }
                
                Spacer()
                
                // Done button
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.green)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(Color(.systemBackground))
            .navigationTitle("Payment Received")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Connection Confirmation View
struct ConnectionConfirmationView: View {
    let isSendingMode: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @StateObject private var tapToSendService = TapToSendService.shared
    @State private var isPulsing = false
    @State private var connectionEstablished = false
    @State private var showSuccessAnimation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // Connection status animation
                VStack(spacing: 24) {
                    ZStack {
                        // Multiple pulsing background circles for depth
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isPulsing ? 1.3 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isPulsing
                            )
                        
                        Circle()
                            .fill(Color.blue.opacity(0.05))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isPulsing ? 1.5 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.8)
                                    .repeatForever(autoreverses: true)
                                    .delay(0.3),
                                value: isPulsing
                            )
                        
                        // Main icon with pulsing animation
                        Image(systemName: connectionEstablished ? "checkmark.circle.fill" : "iphone.radiowaves.left.and.right")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(connectionEstablished ? .green : .blue)
                            .scaleEffect(connectionEstablished ? 1.1 : (isPulsing ? 1.1 : 1.0))
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isPulsing
                            )
                    }
                    
                    VStack(spacing: 12) {
                        Text(connectionEstablished ? "Device Connected!" : (isSendingMode ? "Looking for Receiver" : "Waiting for Connection"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(connectionEstablished ? 
                             (isSendingMode ? "Ready to send money!" : "A device is ready to send you money") : 
                             (isSendingMode ? "Looking for a device to send money to" : "Bring another device close and tap them together"))
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    if connectionEstablished {
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showSuccessAnimation = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onConfirm()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                Text(isSendingMode ? "Ready to Send" : "Ready to Receive")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.green)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(showSuccessAnimation ? 1.05 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccessAnimation)
                    }
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(Color(.systemBackground))
            .navigationTitle(isSendingMode ? "Send Money" : "Receive Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            isPulsing = true
            // Start BOTH advertising and browsing for maximum connectivity
            tapToSendService.startAdvertising()
            tapToSendService.startBrowsing()
        }
        .onDisappear {
            tapToSendService.stopAdvertising()
            tapToSendService.stopBrowsing()
        }
        .onChange(of: tapToSendService.isConnected) { isConnected in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                connectionEstablished = isConnected
            }
        }
    }
}


// MARK: - Payment Sent Success View
struct PaymentSentSuccessView: View {
    let amount: Double
    let message: String
    let onDone: () -> Void
    
    @StateObject private var receiptService = QuantumReceiptService.shared
    @State private var showConfetti = false
    @State private var isAnimating = false
    @State private var showReceipt = false
    @State private var generatedReceipt: QuantumReceipt?
    @State private var isGeneratingReceipt = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // Success animation
                VStack(spacing: 24) {
                    ZStack {
                        // Confetti background
                        if showConfetti {
                            ForEach(0..<20, id: \.self) { index in
                                Circle()
                                    .fill([Color.blue, Color.green, Color.orange, Color.purple].randomElement() ?? .blue)
                                    .frame(width: 8, height: 8)
                                    .offset(
                                        x: CGFloat.random(in: -100...100),
                                        y: CGFloat.random(in: -100...100)
                                    )
                                    .opacity(showConfetti ? 0 : 1)
                                    .animation(
                                        Animation.easeOut(duration: 2.0)
                                            .delay(Double(index) * 0.1),
                                        value: showConfetti
                                    )
                            }
                        }
                        
                        // Success icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundColor(.green)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Money Sent! 🎉")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(formatCurrency(amount))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        
                        if !message.isEmpty {
                            Text("\"\(message)\"")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .italic()
                        }
                    }
                }
                
                Spacer()
                
                // Done button
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.green)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(Color(.systemBackground))
            .navigationTitle("Payment Sent")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Payment Confirmation View (for sender)
struct PaymentConfirmationView: View {
    let paymentResponse: PaymentResponse
    let amount: Double
    let message: String
    let onDone: () -> Void
    
    @State private var showConfetti = false
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // Success animation
                VStack(spacing: 24) {
                    ZStack {
                        // Confetti background
                        if showConfetti {
                            ForEach(0..<20, id: \.self) { index in
                                Circle()
                                    .fill([Color.blue, Color.green, Color.orange, Color.purple].randomElement() ?? .blue)
                                    .frame(width: 8, height: 8)
                                    .offset(
                                        x: CGFloat.random(in: -100...100),
                                        y: CGFloat.random(in: -100...100)
                                    )
                                    .opacity(showConfetti ? 0 : 1)
                                    .animation(
                                        Animation.easeOut(duration: 2.0)
                                            .delay(Double(index) * 0.1),
                                        value: showConfetti
                                    )
                            }
                        }
                        
                        // Success icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundColor(.green)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Money Sent! 🎉")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(formatCurrency(amount))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        
                        if !message.isEmpty {
                            Text("\"\(message)\"")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .italic()
                        }
                    }
                }
                
                Spacer()
                
                // Done button
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.green)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(Color(.systemBackground))
            .navigationTitle("Payment Sent")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    TapToSendView()
}

