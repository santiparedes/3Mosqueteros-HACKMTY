import SwiftUI
import AVFoundation

struct AIChatView: View {
    @StateObject private var geminiService = GeminiAIService.shared
    @StateObject private var elevenLabsService = ElevenLabsService.shared
    @State private var messages: [ChatMessage] = []
    @State private var currentMessage = ""
    @State private var isTyping = false
    @State private var isListening = false
    @State private var showDataCard = false
    @State private var isDataConfirmed = false
    @State private var showPhotoCapture = false
    @State private var showWelcomeScreen = false
    @State private var userPhoto: UIImage?
    @State private var currentOCRResults: OCRResults
    @State private var isCorrectingData = false
    
    let ocrResults: OCRResults
    let onDataConfirmed: (OCRResults) -> Void
    let onPhotoCaptured: (UIImage) -> Void
    let onComplete: () -> Void
    
    init(ocrResults: OCRResults, onDataConfirmed: @escaping (OCRResults) -> Void, onPhotoCaptured: @escaping (UIImage) -> Void, onComplete: @escaping () -> Void) {
        self.ocrResults = ocrResults
        self.onDataConfirmed = onDataConfirmed
        self.onPhotoCaptured = onPhotoCaptured
        self.onComplete = onComplete
        self._currentOCRResults = State(initialValue: ocrResults)
    }
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.4),
                    Color.purple.opacity(0.6),
                    Color.blue.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isTyping)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main content area
                VStack(spacing: 32) {
                    // Text input field (when in keyboard mode) - MOVED TO TOP
                    if !isListening && currentMessage.isEmpty {
                        TextField("Escribe tu respuesta...", text: $currentMessage)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.9), .white.opacity(0.7), .white.opacity(0.5)],
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                            .onSubmit {
                                sendMessage()
                            }
                    }

                    Spacer()
                    
                    // User query/typing display with gradient text
                    if !currentMessage.isEmpty {
                        Text(currentMessage)
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.9), .white.opacity(0.7), .white.opacity(0.5)],
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            )
                    } else if let lastUserMessage = messages.last(where: { $0.isUser }) {
                        Text(lastUserMessage.text)
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.9), .white.opacity(0.7), .white.opacity(0.5)],
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            )
                    }
                    
                    // AI response area with gradient text
                    if isTyping {
                        Text("Pensando...")
                            .font(.system(size: 20, weight: .medium))
                            .padding(.vertical, 12)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.8), .white.opacity(0.6)],
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            )
                    } else if let lastAIMessage = messages.last(where: { !$0.isUser }) {
                        Text(lastAIMessage.text)
                            .font(.system(size: 38, weight: .medium))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.8), .white.opacity(0.6), .white.opacity(0.4)],
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            )
                    }

                    Spacer()
                    Spacer()
                }
                
                Spacer()
                
                // Bottom control bar
                bottomControlBar
            }
        }
        .onAppear {
            startConversation()
        }
        .fullScreenCover(isPresented: $showPhotoCapture) {
            PhotoCaptureView { photo in
                print("DEBUG: Photo captured in AIChatView, showing welcome screen")
                print("DEBUG: showPhotoCapture = \(showPhotoCapture)")
                print("DEBUG: showWelcomeScreen = \(showWelcomeScreen)")
                userPhoto = photo
                showPhotoCapture = false
                showWelcomeScreen = true
                print("DEBUG: After setting - showPhotoCapture = \(showPhotoCapture), showWelcomeScreen = \(showWelcomeScreen)")
            }
        }
        .fullScreenCover(isPresented: $showWelcomeScreen) {
            WelcomeCompletionView(
                userName: currentOCRResults.firstName,
                userPhoto: userPhoto,
                onComplete: {
                    print("DEBUG: WelcomeCompletionView onComplete called")
                    showWelcomeScreen = false
                    print("DEBUG: Calling parent onComplete")
                    onComplete()
                }
            )
        }
    }
    
    private var bottomControlBar: some View {
        HStack {
            // Left side - Mode toggle
            HStack(spacing: 0) {
                Button(action: {
                    // Switch to voice mode
                    isListening = true
                    startListening()
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(
                            LinearGradient(
                                colors: isListening ? [.white, .white.opacity(0.8)] : [.white.opacity(0.6), .white.opacity(0.4)],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                        .background(
                            Circle()
                                .fill(isListening ? Color.purple.opacity(0.8) : Color.white.opacity(0.1))
                        )
                }
                
                Button(action: {
                    // Switch to keyboard mode
                    isListening = false
                    stopListening()
                }) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(
                            LinearGradient(
                                colors: !isListening ? [.white, .white.opacity(0.8)] : [.white.opacity(0.6), .white.opacity(0.4)],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                        .background(
                            Circle()
                                .fill(!isListening ? Color.purple.opacity(0.8) : Color.white.opacity(0.1))
                        )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 44)
            )
            
            Spacer()
            
            // Right side - Main action button (moved to corner)
            Button(action: {
                if isListening {
                    stopListening()
                } else if !currentMessage.isEmpty {
                    sendMessage()
                } else {
                    startListening()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                    
                    if isListening {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.red)
                    } else if !currentMessage.isEmpty {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Main query/title
            Text("Verificando tu información")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Processing indicator
            HStack(spacing: 12) {
                Circle()
                    .fill(isTyping ? Color.green : Color.nepBlue)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isTyping ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isTyping)
                
                Text(isTyping ? "Procesando..." : "Analizando datos")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                    
                    if isTyping {
                        TypingIndicatorView()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    if let lastMessage = messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isTyping) { typing in
                if typing {
                    withAnimation(.easeOut(duration: 0.3)) {
                        // Scroll to bottom when typing starts
                        if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private var dataConfirmationCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Datos extraídos de tu INE")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showDataCard = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            VStack(spacing: 12) {
                DataRow(title: "Nombre", value: currentOCRResults.fullName)
                DataRow(title: "CURP", value: currentOCRResults.curp)
                DataRow(title: "Fecha de Nacimiento", value: currentOCRResults.dateOfBirth)
                DataRow(title: "Estado", value: currentOCRResults.state)
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            
            HStack(spacing: 12) {
                Button(action: {
                    // User says data is wrong
                    addUserMessage("No, hay errores en los datos")
                    showDataCard = false
                    isCorrectingData = true
                    processUserCorrection()
                }) {
                    Text("Hay errores")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    // User confirms data is correct
                    addUserMessage("Sí, los datos están correctos")
                    isDataConfirmed = true
                    showDataCard = false
                    onDataConfirmed(currentOCRResults)
                    processDataConfirmation()
                }) {
                    Text("Está correcto")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.nepBlue.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var inputArea: some View {
        VStack(spacing: 16) {
            // Voice input button - Arc Search style
            Button(action: {
                if isListening {
                    stopListening()
                } else {
                    startListening()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isListening ? .red : .white)
                    
                    Text(isListening ? "Escuchando..." : "Hablar")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .disabled(isTyping)
            
            // Text input - Arc Search style
            HStack(spacing: 16) {
                TextField("Escribe tu respuesta...", text: $currentMessage)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(currentMessage.isEmpty ? .white.opacity(0.3) : .nepBlue)
                }
                .disabled(currentMessage.isEmpty || isTyping)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    private func startConversation() {
        // Add initial AI message
        let welcomeMessage = ChatMessage(
            id: UUID(),
            text: "¡Hola! Soy tu asistente de Nep. He extraído la información de tu INE y quiero verificar que todo esté correcto contigo.",
            isUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
        
        // Show data card after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showDataCard = true
            }
        }
    }
    
    private func addUserMessage(_ text: String) {
        let message = ChatMessage(
            id: UUID(),
            text: text,
            isUser: true,
            timestamp: Date()
        )
        messages.append(message)
        currentMessage = ""
    }
    
    private func addAIMessage(_ text: String) {
        isTyping = true
        
        // Simulate typing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let message = ChatMessage(
                id: UUID(),
                text: text,
                isUser: false,
                timestamp: Date()
            )
            messages.append(message)
            isTyping = false
        }
    }
    
    private func processDataConfirmation() {
        addAIMessage("¡Perfecto! Los datos están correctos. Ahora necesito una foto tuya para completar tu perfil.")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showPhotoCapture = true
        }
    }
    
    private func processUserCorrection() {
        addAIMessage("Entiendo, hay errores en los datos. Por favor, dime qué información está incorrecta y cómo debería ser.")
    }
    
    private func startListening() {
        isListening = true
        // TODO: Implement voice recognition
        // For now, simulate voice input
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isListening = false
            // Simulate voice input
            addUserMessage("Los datos están correctos")
            processDataConfirmation()
        }
    }
    
    private func stopListening() {
        isListening = false
    }
    
    private func sendMessage() {
        guard !currentMessage.isEmpty else { return }
        
        addUserMessage(currentMessage)
        
        // Process user input with Gemini AI
        Task {
            if isCorrectingData {
                // Handle data correction
                let correctionResponse = await geminiService.processDataCorrection(currentMessage, currentData: currentOCRResults)
                
                await MainActor.run {
                    if correctionResponse.hasChanges {
                        currentOCRResults = correctionResponse.correctedData
                        addAIMessage("Perfecto, he actualizado los datos. ¿Está correcto ahora?")
                        
                        // Show updated data card
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDataCard = true
                                isCorrectingData = false
                            }
                        }
                    } else {
                        addAIMessage(correctionResponse.message)
                    }
                }
            } else {
                // Handle regular conversation
                let context = OnboardingContext(
                    currentStep: .dataVerification,
                    userData: currentOCRResults,
                    conversationHistory: messages.map { ConversationMessage(
                        id: $0.id,
                        text: $0.text,
                        isUser: $0.isUser,
                        timestamp: $0.timestamp
                    )}
                )
                
                let response = await geminiService.processUserResponse(currentMessage, context: context)
                
                await MainActor.run {
                    addAIMessage(response.message)
                    
                    if response.nextAction == .confirm && isDataConfirmed {
                        onDataConfirmed(currentOCRResults)
                    }
                }
            }
        }
    }
    
    private func completeOnboarding() {
        addAIMessage("¡Excelente! Tu foto se ha capturado correctamente. ¡Bienvenido a Nep, \(currentOCRResults.firstName)!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showWelcomeScreen = true
        }
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(spacing: 12) {
            if message.isUser {
                // User message - centered and styled like Arc Search
                VStack(alignment: .center, spacing: 8) {
                    Text(message.text)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } else {
                // AI message - full width card style
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        // AI indicator
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.nepBlue, Color.nepBlue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("AI")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text("Asistente Nep")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                    }
                    
                    Text(message.text)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // AI indicator
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.nepBlue, Color.nepBlue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("AI")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Text("Asistente Nep")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationOffset == 0 ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .onAppear {
            animationOffset = 1
        }
    }
}

struct DataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Front Camera Manager for Profile Photos
class FrontCameraManager: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentCameraInput: AVCaptureDeviceInput?
    private var currentCameraPosition: AVCaptureDevice.Position = .front
    private var currentPhotoDelegate: FrontPhotoCaptureDelegate?
    
    @Published var isSessionRunning = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        setupCameraWithPosition(.front)
    }
    
    private func setupCameraWithPosition(_ position: AVCaptureDevice.Position) {
        // Remove existing input
        if let currentInput = currentCameraInput {
            captureSession.removeInput(currentInput)
        }
        
        // Get camera for the specified position
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "No se pudo acceder a la cámara"
            }
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                currentCameraInput = input
                
                // Update position on main thread
                DispatchQueue.main.async {
                    self.currentCameraPosition = position
                }
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            // Configure photo output for better quality
            photoOutput.isHighResolutionCaptureEnabled = true
            
        } catch {
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "Error configurando la cámara: \(error.localizedDescription)"
            }
        }
    }
    
    func startSession() {
        print("DEBUG: FrontCameraManager.startSession called")
        guard !captureSession.isRunning else { 
            print("DEBUG: Front camera session already running, skipping")
            return 
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("DEBUG: Starting front camera session on background thread")
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = true
                print("DEBUG: Front camera session started, isSessionRunning = \(self.isSessionRunning)")
            }
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }
    
    func setupPreview(in view: UIView) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        
        // Mirror the preview for front camera
        if currentCameraPosition == .front {
            previewLayer?.transform = CATransform3DMakeScale(-1, 1, 1)
        } else {
            previewLayer?.transform = CATransform3DIdentity
        }
        
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
    }
    
    func updatePreviewFrame(_ frame: CGRect) {
        previewLayer?.frame = frame
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        print("DEBUG: FrontCameraManager.capturePhoto called")
        print("DEBUG: Capture session is running: \(captureSession.isRunning)")
        print("DEBUG: Photo output is available: \(photoOutput != nil)")
        
        guard captureSession.isRunning else {
            print("DEBUG: ERROR - Capture session is not running!")
            completion(nil)
            return
        }
        
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        
        // Get current position on main thread
        let isFrontCamera = currentCameraPosition == .front
        print("DEBUG: Is front camera: \(isFrontCamera)")
        print("DEBUG: Starting photo capture...")
        
        // Create delegate and store it to prevent deallocation
        currentPhotoDelegate = FrontPhotoCaptureDelegate(completion: { [weak self] image in
            self?.currentPhotoDelegate = nil // Clear the delegate after completion
            completion(image)
        }, isFrontCamera: isFrontCamera)
        
        photoOutput.capturePhoto(with: settings, delegate: currentPhotoDelegate!)
        
        print("DEBUG: Photo capture request sent to output")
    }
    
    func flipCamera() {
        print("DEBUG: FrontCameraManager.flipCamera called")
        // Get current position on main thread
        let currentPosition = currentCameraPosition
        let newPosition: AVCaptureDevice.Position = currentPosition == .front ? .back : .front
        print("DEBUG: Flipping from \(currentPosition == .front ? "front" : "back") to \(newPosition == .front ? "front" : "back")")
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("DEBUG: Stopping current session for flip")
            self.captureSession.stopRunning()
            
            print("DEBUG: Setting up camera with new position: \(newPosition == .front ? "front" : "back")")
            self.setupCameraWithPosition(newPosition)
            
            print("DEBUG: Restarting session after flip")
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                // Update preview transform
                if newPosition == .front {
                    self.previewLayer?.transform = CATransform3DMakeScale(-1, 1, 1)
                } else {
                    self.previewLayer?.transform = CATransform3DIdentity
                }
                print("DEBUG: Camera flip completed")
            }
        }
    }
    
    func reloadCamera() {
        print("DEBUG: FrontCameraManager.reloadCamera called")
        // Get current position on main thread
        let currentPosition = currentCameraPosition
        print("DEBUG: Reloading camera with position: \(currentPosition == .front ? "front" : "back")")
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("DEBUG: Stopping current session for reload")
            self.captureSession.stopRunning()
            
            print("DEBUG: Setting up camera with position: \(currentPosition == .front ? "front" : "back")")
            self.setupCameraWithPosition(currentPosition)
            
            print("DEBUG: Restarting session after reload")
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                // Update preview transform
                if currentPosition == .front {
                    self.previewLayer?.transform = CATransform3DMakeScale(-1, 1, 1)
                } else {
                    self.previewLayer?.transform = CATransform3DIdentity
                }
                print("DEBUG: Camera reload completed")
            }
        }
    }
}

// MARK: - Front Photo Capture Delegate
class FrontPhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    private let isFrontCamera: Bool
    
    init(completion: @escaping (UIImage?) -> Void, isFrontCamera: Bool = true) {
        self.completion = completion
        self.isFrontCamera = isFrontCamera
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("DEBUG: FrontPhotoCaptureDelegate.photoOutput called")
        
        if let error = error {
            print("DEBUG: Error capturing photo: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("DEBUG: Failed to get image data from photo")
            completion(nil)
            return
        }
        
        print("DEBUG: Photo captured successfully, processing...")
        
        // Mirror the image only for front camera (like a selfie)
        if isFrontCamera {
            let mirroredImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
            print("DEBUG: Image mirrored for front camera")
            completion(mirroredImage)
        } else {
            print("DEBUG: Image not mirrored for back camera")
            completion(image)
        }
    }
}

struct PhotoCaptureView: View {
    @StateObject private var cameraManager = FrontCameraManager()
    @State private var capturedImage: UIImage?
    @State private var showFlash = false
    @Environment(\.dismiss) private var dismiss
    
    let onPhotoCaptured: (UIImage) -> Void
    
    var body: some View {
        ZStack {
            // Camera preview
            if cameraManager.isSessionRunning {
                FrontCameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
            // Flash overlay
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.8)
                    .animation(.easeOut(duration: 0.1), value: showFlash)
            }
            
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(22)
                    }
                    
                    Spacer()
                    
                    Text("Tu foto de perfil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    Button(action: { 
                        // Reload camera
                        print("DEBUG: Reload button tapped")
                        cameraManager.reloadCamera()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(22)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Instructions
                VStack(spacing: 12) {
                    Text("Toma una foto clara de tu rostro")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Mira directamente a la cámara y asegúrate de tener buena iluminación")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                
                // Capture button
                Button(action: capturePhoto) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .stroke(Color.nepBlue, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(Color.nepBlue)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.bottom, 20)
                
                // Camera flip button
                Button(action: {
                    print("DEBUG: Camera flip button tapped")
                    cameraManager.flipCamera()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Cambiar cámara")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            print("DEBUG: PhotoCaptureView appeared, starting camera session")
            cameraManager.startSession()
        }
        .onDisappear {
            print("DEBUG: PhotoCaptureView disappeared, stopping camera session")
            cameraManager.stopSession()
        }
    }
    
    private func capturePhoto() {
        print("DEBUG: Profile photo capture button tapped")
        
        // Flash animation
        withAnimation(.easeInOut(duration: 0.1)) {
            showFlash = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.1)) {
                showFlash = false
            }
        }
        
        print("DEBUG: Calling cameraManager.capturePhoto")
        cameraManager.capturePhoto { image in
            print("DEBUG: Photo capture completion called with image: \(image != nil)")
            if let image = image {
                print("DEBUG: Image captured successfully, processing...")
                // Flip the image horizontally so it shows the user's face as they see it
                let flippedImage = flipImageHorizontally(image)
                print("DEBUG: Calling onPhotoCaptured")
                onPhotoCaptured(flippedImage)
            } else {
                print("DEBUG: No image captured")
            }
        }
    }
    
    private func flipImageHorizontally(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let flippedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
        return flippedImage
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct FrontCameraPreviewView: UIViewRepresentable {
    let cameraManager: FrontCameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.contentMode = .scaleAspectFill
        cameraManager.setupPreview(in: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update frame when view size changes
        DispatchQueue.main.async {
            cameraManager.updatePreviewFrame(uiView.bounds)
        }
    }
}

#Preview {
    AIChatView(
        ocrResults: OCRResults.empty,
        onDataConfirmed: { _ in },
        onPhotoCaptured: { _ in },
        onComplete: { }
    )
    .preferredColorScheme(.dark)
}
