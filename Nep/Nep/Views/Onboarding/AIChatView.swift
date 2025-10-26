import SwiftUI
import AVFoundation

struct AIChatView: View {
    @StateObject private var geminiService = GeminiAIService.shared
    @StateObject private var elevenLabsService = ElevenLabsService.shared
    @State private var messages: [ChatMessage] = []
    @State private var currentMessage = ""
    @State private var isTyping = false
    @State private var isListening = false
    @State private var isInVoiceMode = false
    @State private var currentConfirmationStep = 0
    @State private var showDataCard = false
    @State private var isDataConfirmed = false
    @State private var showWelcomeScreen = false
    @State private var currentOCRResults: OCRResults
    @State private var isCorrectingData = false
    @State private var typingText = ""
    @State private var currentTypingMessage = ""
    @State private var isTextFieldFocused = false
    @State private var typingTask: Task<Void, Never>?
    @State private var textAnimationOffset: CGFloat = 0
    @State private var isAnimatingText = false
    @State private var textLines: [String] = []
    @State private var animationID = UUID()
    
    let ocrResults: OCRResults
    let onDataConfirmed: (OCRResults) -> Void
    let onComplete: () -> Void
    
    init(ocrResults: OCRResults, onDataConfirmed: @escaping (OCRResults) -> Void, onComplete: @escaping () -> Void) {
        self.ocrResults = ocrResults
        self.onDataConfirmed = onDataConfirmed
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
                // Top section with text input and AI response
                VStack(spacing: 20) {
                    // Text input field (when in keyboard mode)
                    if !isInVoiceMode {
                        TextField("Type your response...", text: $currentMessage, axis: .vertical)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.9), .white.opacity(0.7), .white.opacity(0.5)],
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(1...10)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                            .onTapGesture {
                                // Clear the field when user taps it
                                if !currentMessage.isEmpty {
                                    currentMessage = ""
                                }
                            }
                            .onSubmit {
                                sendMessage()
                            }
                    }
                    
                    // AI response area with gradient text
                    if isTyping {
                        if !typingText.isEmpty {
                            // Show typing animation
                            AnimatedTextDisplay(text: typingText)
                                .font(.system(size: 34, weight: .medium))
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
                        } else {
                            // Show thinking state
                            Text("Thinking...")
                                .font(.system(size: 20, weight: .medium))
                                .padding(.vertical, 12)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white.opacity(0.8), .white.opacity(0.6)],
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                        }
                    } else if isListening {
                        // Show listening indicator
                        Text("Listening...")
                            .font(.system(size: 34, weight: .medium))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green.opacity(0.8), .green.opacity(0.6), .green.opacity(0.4)],
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            )
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isListening)
                            .onAppear {
                                print("🎤 UI: Listening indicator appeared - isListening: \(isListening)")
                            }
                            .onChange(of: isListening) { newValue in
                                print("🎤 UI: Listening state changed to: \(newValue)")
                            }
                            .onChange(of: isInVoiceMode) { newValue in
                                print("🎤 UI: Voice mode changed to: \(newValue)")
                            }
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
                }
                .padding(.top, 40) // Fixed top padding for text input and AI response
                
                Spacer()
                
                // Bottom control bar
                bottomControlBar
            }
        }
        .onAppear {
            startConversation()
            setupVoiceResponseHandling()
        }
        .onDisappear {
            typingTask?.cancel()
        }
        .sheet(isPresented: $showDataCard) {
            if !APIConfig.isVoiceModeAvailable {
            dataConfirmationSheet
            } else {
                // Empty view when using voice mode
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $showWelcomeScreen) {
            WelcomeCompletionView(
                userName: currentOCRResults.firstName,
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
                    print("DEBUG: Voice mode button tapped")
                    isInVoiceMode = true
                    // Don't auto-start listening, just switch to mic mode
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(
                            LinearGradient(
                                colors: isInVoiceMode ? [.white, .white.opacity(0.8)] : [.white.opacity(0.6), .white.opacity(0.4)],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                        .background(
                            Circle()
                                .fill(isInVoiceMode ? Color.purple.opacity(0.8) : Color.white.opacity(0.1))
                        )
                }
                
                Button(action: {
                    // Switch to keyboard mode
                    print("DEBUG: Keyboard mode button tapped")
                    isInVoiceMode = false
                    isListening = false
                    stopListening()
                }) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(
                            LinearGradient(
                                colors: !isInVoiceMode ? [.white, .white.opacity(0.8)] : [.white.opacity(0.6), .white.opacity(0.4)],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                        .background(
                            Circle()
                                .fill(!isInVoiceMode ? Color.purple.opacity(0.8) : Color.white.opacity(0.1))
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
                print("DEBUG: Main action button tapped")
                if isInVoiceMode {
                if isListening {
                    print("DEBUG: Currently listening, stopping...")
                    stopListening()
                    } else {
                        print("DEBUG: Starting to listen...")
                        startListening()
                    }
                } else if !currentMessage.isEmpty {
                    print("DEBUG: Has message, sending...")
                    sendMessage()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                    
                    if isInVoiceMode {
                    if isListening {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.red)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    } else if !currentMessage.isEmpty {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "keyboard")
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
            Text("Verifying your information")
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
    
    private var dataConfirmationSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Header
                HStack {
                    Text("Data extracted from your ID")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    
                    Spacer()
                    
                    Button(action: {
                        showDataCard = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Scrollable data section
                ScrollView {
                    VStack(spacing: 20) {
                        // Main data fields - only the 4 requested fields
                        VStack(spacing: 16) {
                            DataRow(title: "Nombre Completo", value: currentOCRResults.fullName)
                            DataRow(title: "CURP", value: currentOCRResults.curp)
                            DataRow(title: "Fecha de Nacimiento", value: currentOCRResults.dateOfBirth)
                            DataRow(title: "Estado", value: currentOCRResults.state)
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                        
                        // Additional data section
                        VStack(spacing: 12) {
                            HStack {
                                Text("Datos adicionales")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                DataRow(title: "Document Number", value: currentOCRResults.documentNumber)
                                DataRow(title: "Sex", value: currentOCRResults.sex)
                                DataRow(title: "Nationality", value: currentOCRResults.nationality)
                                DataRow(title: "Locality", value: currentOCRResults.address)
                                DataRow(title: "Municipality", value: currentOCRResults.municipality)
                                DataRow(title: "Address", value: currentOCRResults.locality)
                                DataRow(title: "Electoral Section", value: currentOCRResults.electoralSection)
                                DataRow(title: "Issue Date", value: currentOCRResults.issueDate)
                                DataRow(title: "Expiration Date", value: currentOCRResults.expirationDate)
                            }
                            .padding(16)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        // User says data is wrong
                        print("DEBUG: 'Has errors' button tapped")
                        currentMessage = "No, there are errors in the data"
                        showDataCard = false
                        isCorrectingData = true
                        
                        // Send message immediately
                        sendMessage()
                    }) {
                        Text("Has errors")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange.opacity(0.8))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // User confirms data is correct
                        print("DEBUG: 'It's correct' button tapped")
                        currentMessage = "Yes, the data is correct"
                        showDataCard = false
                        
                        // Send message immediately
                        sendMessage()
                    }) {
                        Text("It's correct")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.nepBlue.opacity(0.8))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34) // Safe area padding
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.height(200), .medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.disabled)
        .interactiveDismissDisabled()
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
        // Reset confirmation step counter
        currentConfirmationStep = 0
        
        // Add initial AI message with animation and audio
        let welcomeText = "Hello! I'm your Nep assistant. I've extracted the information from your ID and want to verify that everything is correct with you."
        
        // Start typing animation and audio immediately
        isTyping = true
        currentTypingMessage = welcomeText
        typingText = welcomeText  // Set the text directly for AnimatedTextDisplay

        // Start audio immediately when animation starts
        Task {
            await elevenLabsService.speak(welcomeText)
        }
        
        // Show data card only if voice mode is not available
        if !APIConfig.isVoiceModeAvailable {
        showDataCard = true
        }
        
        // If voice mode is available, use voice-based confirmation instead of sheet
        if APIConfig.isVoiceModeAvailable {
            print("🎤 VOICE ONBOARDING: Voice mode available (Gemini + Apple TTS), using voice confirmation")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                processDataConfirmation()
            }
        } else {
            print("📱 FALLBACK: Voice mode not available, using sheet confirmation")
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
        // Don't clear the text field - keep it for user to see/edit
    }
    
    private func addAIMessage(_ text: String) {
        // Cancel any existing typing animation
        typingTask?.cancel()
        
        isTyping = true
        currentTypingMessage = text
        typingText = text  // Set the text directly for AnimatedTextDisplay
        
        // Wait for current audio to finish before starting new audio
        Task {
            // Check if we're currently speaking and wait for it to finish
            while elevenLabsService.isSpeaking {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Now speak the new text immediately
            await elevenLabsService.speak(text)
        }
    }
    
    
    @State private var isProcessingConfirmation = false
    
    private func processDataConfirmation() {
        // Prevent multiple simultaneous calls
        guard !isProcessingConfirmation else {
            print("🎤 VOICE ONBOARDING: Already processing confirmation, ignoring duplicate call")
            return
        }
        
        isProcessingConfirmation = true
        print("🎤 VOICE ONBOARDING: Starting voice-based data confirmation (Step \(currentConfirmationStep))")
        
        // Update ElevenLabs with current OCR results
        elevenLabsService.updateOCRResults(currentOCRResults)
        
        // Generate voice confirmation message using Gemini
        Task {
            let confirmationMessage = await generateDataConfirmationMessage()
            print("🎤 VOICE ONBOARDING: Generated confirmation message: \(confirmationMessage)")
            
            // Add the message to chat (this will handle speaking with proper queuing)
            await MainActor.run {
                addAIMessage(confirmationMessage)
            }
            
            // Wait for the message to finish speaking before starting voice recognition
            while elevenLabsService.isSpeaking {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Don't automatically start listening - wait for user to click the button
            print("🎤 VOICE ONBOARDING: Message finished speaking, waiting for user to start listening")
            
            // Reset processing flag
            await MainActor.run {
                isProcessingConfirmation = false
            }
        }
    }
    
    private func generateDataConfirmationMessage() async -> String {
        print("🤖 GEMINI: Generating data confirmation message for step \(currentConfirmationStep)...")
        
        switch currentConfirmationStep {
        case 0:
            return await generatePersonalInfoConfirmation()
        case 1:
            return await generateAddressConfirmation()
        case 2:
            return await generateDocumentDatesConfirmation()
        default:
            return await generateFinalConfirmation()
        }
    }
    
    private func generatePersonalInfoConfirmation() async -> String {
        // Filter out empty fields and create a clean list
        var personalInfo: [String] = []
        
        if !currentOCRResults.fullName.isEmpty {
            personalInfo.append("Full Name: \(currentOCRResults.fullName)")
        }
        if !currentOCRResults.dateOfBirth.isEmpty {
            personalInfo.append("Date of Birth: \(currentOCRResults.dateOfBirth)")
        }
        if !currentOCRResults.documentNumber.isEmpty {
            personalInfo.append("Document Number: \(currentOCRResults.documentNumber)")
        }
        if !currentOCRResults.curp.isEmpty {
            personalInfo.append("CURP: \(currentOCRResults.curp)")
        }
        if !currentOCRResults.sex.isEmpty {
            personalInfo.append("Sex: \(translateGender(currentOCRResults.sex))")
        }
        
        let personalInfoText = personalInfo.joined(separator: ", ")
        
        let prompt = """
        You are Nep's voice assistant confirming personal information from an ID.
        
        Available Personal Information:
        \(personalInfoText)
        
        Create a conversational message that:
        1. Goes straight to confirming details (no introduction)
        2. Lists each field on its own line in a conversational way
        3. Only mentions: Name, Date of Birth, Sex, and CURP
        4. Uses natural speech patterns
        5. Asks if this information is correct
        6. Keep it conversational, not like a list
        7. IMPORTANT: Format the date of birth as "May 7th, 2004" (month name, day with ordinal, year)
        
        Example: "Let me confirm your details. Your name is [Name], you were born on May 7th, 2004, you're [Sex], and your CURP is [CURP]. Does that all look correct?"
        """
        
        do {
            let response = try await geminiService.sendGeminiRequest(prompt: prompt)
            print("✅ GEMINI: Generated personal info confirmation")
            return response
        } catch {
            print("❌ GEMINI: Error generating personal info confirmation: \(error)")
            let name = currentOCRResults.fullName.isEmpty ? "not available" : currentOCRResults.fullName
            let dob = currentOCRResults.dateOfBirth.isEmpty ? "not available" : formatDateOfBirth(currentOCRResults.dateOfBirth)
            let sex = currentOCRResults.sex.isEmpty ? "not available" : translateGender(currentOCRResults.sex)
            let curp = currentOCRResults.curp.isEmpty ? "not available" : currentOCRResults.curp
            
            return "Let me confirm your details. Your name is \(name), you were born on \(dob), you're \(sex), and your CURP is \(curp). Does that all look correct?"
        }
    }
    
    private func generateAddressConfirmation() async -> String {
        // Filter out empty fields and create a clean list
        var addressInfo: [String] = []
        
        if !currentOCRResults.state.isEmpty {
            addressInfo.append("State: \(currentOCRResults.state)")
        }
        if !currentOCRResults.municipality.isEmpty {
            addressInfo.append("Municipality: \(currentOCRResults.municipality)")
        }
        if !currentOCRResults.locality.isEmpty {
            addressInfo.append("Locality: \(currentOCRResults.locality)")
        }
        if !currentOCRResults.electoralSection.isEmpty {
            addressInfo.append("Electoral Section: \(currentOCRResults.electoralSection)")
        }
        if !currentOCRResults.address.isEmpty {
            addressInfo.append("Address: \(currentOCRResults.address)")
        }
        
        let addressInfoText = addressInfo.joined(separator: ", ")
        
        let prompt = """
        You are Nep's voice assistant confirming address information from an ID.
        
        Available Address Information:
        \(addressInfoText)
        
        Create a conversational message that:
        1. Goes straight to confirming address details (no introduction)
        2. Lists each field in a conversational way
        3. Only mentions the available address fields
        4. Uses natural speech patterns
        5. Asks if this information is correct
        6. Keep it conversational, not like a list
        7. If some fields are missing, mention that we'll need to collect them
        
        Example: "Now let's confirm your address details. You live in [State], in [Municipality], and your locality is [Locality]. Is this correct?"
        """
        
        do {
            let response = try await geminiService.sendGeminiRequest(prompt: prompt)
            print("✅ GEMINI: Generated address confirmation")
            return response
        } catch {
            print("❌ GEMINI: Error generating address confirmation: \(error)")
            return "Great! Now let's confirm your address information. \(addressInfoText). Is this correct?"
        }
    }
    
    private func generateDocumentDatesConfirmation() async -> String {
        // Filter out empty fields and create a clean list
        var dateInfo: [String] = []
        
        if !currentOCRResults.issueDate.isEmpty {
            dateInfo.append("Issue Date: \(currentOCRResults.issueDate)")
        }
        if !currentOCRResults.expirationDate.isEmpty {
            dateInfo.append("Expiration Date: \(currentOCRResults.expirationDate)")
        }
        
        let dateInfoText = dateInfo.joined(separator: ", ")
        
        let prompt = """
        You are Nep's voice assistant confirming document dates from an ID.
        
        Available Document Dates:
        \(dateInfoText)
        
        Create a conversational message that:
        1. Goes straight to confirming document dates (no introduction)
        2. Lists each date in a conversational way
        3. Only mentions the available dates
        4. Uses natural speech patterns
        5. Asks if this information is correct
        6. Keep it conversational, not like a list
        7. If some fields are missing, mention that we'll need to collect them
        
        Example: "Finally, let's confirm your document dates. Your ID was issued on [Issue Date] and expires on [Expiration Date]. Are these dates correct?"
        """
        
        do {
            let response = try await geminiService.sendGeminiRequest(prompt: prompt)
            print("✅ GEMINI: Generated document dates confirmation")
            return response
        } catch {
            print("❌ GEMINI: Error generating document dates confirmation: \(error)")
            return "Perfect! Finally, let's confirm your document dates. \(dateInfoText). Are these dates correct?"
        }
    }
    
    private func generateFinalConfirmation() async -> String {
        return "Excellent! All your information has been confirmed. Your account setup is now complete. Welcome to Nep!"
    }
    
    private func startVoiceConfirmation() async {
        print("🎤 VOICE ONBOARDING: Starting voice confirmation...")
        
        // Set listening state to show "Listening..." text
        await MainActor.run {
            isListening = true
        }
        
        do {
            try await elevenLabsService.startListening()
            print("✅ VOICE ONBOARDING: Started listening for user response")
        } catch {
            print("❌ VOICE ONBOARDING: Error starting voice recognition: \(error)")
            // Reset listening state on error
            await MainActor.run {
                isListening = false
                showDataCard = true
            }
        }
    }
    
    private func setupVoiceResponseHandling() {
        print("🎤 VOICE ONBOARDING: Setting up voice response handling")
        
        // Listen for voice recognition results
        NotificationCenter.default.addObserver(
            forName: .voiceRecognitionResult,
            object: nil,
            queue: .main
        ) { notification in
            if let userResponse = notification.userInfo?["text"] as? String {
                print("🎤 VOICE ONBOARDING: Received voice response: \(userResponse)")
                print("🗣️ USER SAID: '\(userResponse)'")
                
                // Add user's speech to chat for debugging
                addUserMessage(userResponse)
                
                handleVoiceResponse(userResponse)
            }
        }
    }
    
    private func handleVoiceResponse(_ response: String) {
        print("🎤 VOICE ONBOARDING: Processing voice response: \(response)")
        
        let lowercasedResponse = response.lowercased()
        
        if lowercasedResponse.contains("yes") || lowercasedResponse.contains("correct") || lowercasedResponse.contains("right") {
            print("✅ VOICE ONBOARDING: User confirmed step \(currentConfirmationStep)")
            
            // Move to next step
            currentConfirmationStep += 1
            
            if currentConfirmationStep < 3 {
                // Continue to next step
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.processDataConfirmation()
                }
            } else {
                // All steps completed
                handleDataConfirmed()
            }
        } else if lowercasedResponse.contains("no") || lowercasedResponse.contains("wrong") || lowercasedResponse.contains("error") {
            print("❌ VOICE ONBOARDING: User says data has errors")
            handleDataErrors()
        } else {
            print("❓ VOICE ONBOARDING: Unclear response, asking for clarification")
            Task {
                // Use Gemini to generate a clarification response
                let clarificationPrompt = """
                You are Nep's voice assistant. The user said: "\(response)"
                
                This was unclear. Generate a friendly clarification message that:
                1. Acknowledges you didn't understand clearly
                2. Asks them to say "yes" if the data is correct or "no" if there are errors
                3. Uses natural speech patterns
                4. Keep it conversational and encouraging
                5. Keep it short and clear
                
                Example: "I didn't quite catch that. Please say 'yes' if the information is correct, or 'no' if you need to make corrections."
                """
                
                do {
                    let clarificationMessage = try await geminiService.sendGeminiRequest(prompt: clarificationPrompt)
                    print("🤖 GEMINI: Generated clarification: \(clarificationMessage)")
                    
                    // Add Gemini's response to chat
                    await MainActor.run {
                        addAIMessage(clarificationMessage)
                    }
                    
                    // Speak the clarification
                    await elevenLabsService.speak(clarificationMessage)
                } catch {
                    print("❌ GEMINI: Error generating clarification: \(error)")
                    // Fallback message
                    await elevenLabsService.speak("I didn't quite catch that. Please say 'yes' if the information is correct, or 'no' if you need to make corrections.")
                }
            }
        }
    }
    
    private func handleDataConfirmed() {
        print("✅ VOICE ONBOARDING: Data confirmed, proceeding to completion")
        
        Task {
            // Use Gemini to generate confirmation message
            let confirmationPrompt = """
            You are Nep's voice assistant. The user has confirmed that their ID data is correct. Generate a friendly confirmation message that:
            1. Congratulates them on completing the verification
            2. Lets them know their account setup is complete
            3. Welcomes them to Nep
            4. Uses natural speech patterns
            5. Keep it conversational and encouraging
            6. Keep it concise and positive
            
            Example: "Perfect! All your information has been confirmed. Your account setup is now complete. Welcome to Nep!"
            """
            
            do {
                let confirmationMessage = try await geminiService.sendGeminiRequest(prompt: confirmationPrompt)
                print("🤖 GEMINI: Generated confirmation: \(confirmationMessage)")
                
                // Add Gemini's response to chat
                await MainActor.run {
                    addAIMessage(confirmationMessage)
                }
                
                // Speak the confirmation
                await elevenLabsService.speak(confirmationMessage)
                
                // Wait for the audio to finish before showing welcome screen
                while elevenLabsService.isSpeaking {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
                
                await MainActor.run {
                    showWelcomeScreen = true
                }
            } catch {
                print("❌ GEMINI: Error generating confirmation: \(error)")
                // Fallback message
                await elevenLabsService.speak("Perfect! The data is correct. Your profile is now complete!")
                
                // Wait for the audio to finish before showing welcome screen
                while elevenLabsService.isSpeaking {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
                
                await MainActor.run {
                    showWelcomeScreen = true
                }
            }
        }
    }
    
    private func handleDataErrors() {
        print("❌ VOICE ONBOARDING: Data has errors, starting correction process")
        
        Task {
            // Use Gemini to generate error handling message
            let errorPrompt = """
            You are Nep's voice assistant. The user has indicated there are errors in their ID data. Generate a friendly message that:
            1. Acknowledges their concern about the data
            2. Asks them to tell you what information is incorrect
            3. Asks them how it should be corrected
            4. Uses natural speech patterns
            5. Be understanding and helpful
            6. Keep it conversational and encouraging
            
            Example: "I understand there are errors in the data. Please tell me what information is incorrect and how it should be corrected."
            """
            
            do {
                let errorMessage = try await geminiService.sendGeminiRequest(prompt: errorPrompt)
                print("🤖 GEMINI: Generated error message: \(errorMessage)")
                
                // Add Gemini's response to chat
                await MainActor.run {
                    addAIMessage(errorMessage)
                }
                
                // Speak the error message
                await elevenLabsService.speak(errorMessage)
                
                // Start listening for correction details
                try? await elevenLabsService.startListening()
            } catch {
                print("❌ GEMINI: Error generating error message: \(error)")
                // Fallback message
                await elevenLabsService.speak("I understand there are errors in the data. Please tell me what information is incorrect and how it should be.")
                
                // Start listening for correction details
                try? await elevenLabsService.startListening()
            }
        }
    }
    
    private func startListening() {
        print("DEBUG: startListening() called")
        isListening = true
        print("DEBUG: isListening set to true")
        
        // Use real voice recognition through ElevenLabs service
        Task {
            do {
                try await elevenLabsService.startListening()
                print("✅ VOICE: Started real voice recognition")
            } catch {
                print("❌ VOICE: Error starting voice recognition: \(error)")
                await MainActor.run {
            isListening = false
                }
            }
        }
    }
    
    private func stopListening() {
        print("DEBUG: stopListening() called")
        isListening = false
        print("DEBUG: isListening set to false")
        
        // Also stop the ElevenLabs service
        elevenLabsService.stopListening()
    }
    
    private func sendMessage() {
        guard !currentMessage.isEmpty else { 
            print("DEBUG: sendMessage() called but currentMessage is empty")
            return 
        }
        
        print("DEBUG: sendMessage() called with message: '\(currentMessage)'")
        addUserMessage(currentMessage)
        
        // Check for confirmation responses
        let lowercasedMessage = currentMessage.lowercased()
        print("DEBUG: Processing message: '\(lowercasedMessage)'")
        
        if lowercasedMessage.contains("yes") || lowercasedMessage.contains("sí") || lowercasedMessage.contains("si") {
            print("DEBUG: User confirmed data is correct")
            isDataConfirmed = true
            addAIMessage("Perfect! The data is confirmed. Your profile is now complete!")
            
            // Wait for the AI message to finish speaking before showing welcome screen
            Task {
                while elevenLabsService.isSpeaking {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
                
                await MainActor.run {
                    print("DEBUG: Showing welcome screen after confirmation")
                    showWelcomeScreen = true
                }
            }
            return
        } else if lowercasedMessage.contains("no") || lowercasedMessage.contains("errors") || lowercasedMessage.contains("wrong") {
            print("DEBUG: User says data has errors")
            isCorrectingData = true
            addAIMessage("I understand, there are errors in the data. Please tell me what information is incorrect and how it should be.")
            return
        }
        
        // Process user input with Gemini AI
        Task {
            if isCorrectingData {
                print("DEBUG: Processing data correction")
                // Handle data correction
                let correctionResponse = await geminiService.processDataCorrection(currentMessage, currentData: currentOCRResults)
                
                await MainActor.run {
                    if correctionResponse.hasChanges {
                        print("DEBUG: Data correction has changes")
                        currentOCRResults = correctionResponse.correctedData
                        addAIMessage("Perfect, I've updated the data. Is it correct now?")
                        
                        // Show updated data card
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDataCard = true
                                isCorrectingData = false
                            }
                        }
                    } else {
                        print("DEBUG: Data correction no changes")
                        addAIMessage(correctionResponse.message)
                    }
                }
            } else {
                print("DEBUG: Processing regular conversation")
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
                    print("DEBUG: AI response: '\(response.message)'")
                    addAIMessage(response.message)
                    
                    if response.nextAction == .confirm && isDataConfirmed {
                        print("DEBUG: AI confirmed data, calling onDataConfirmed")
                        onDataConfirmed(currentOCRResults)
                    }
                }
            }
        }
    }
    
    private func completeOnboarding() {
        addAIMessage("¡Excelente! Tu información ha sido verificada correctamente. ¡Bienvenido a Nep, \(currentOCRResults.firstName)!")
        
        // Wait for the AI message to finish speaking before showing welcome screen
        Task {
            while elevenLabsService.isSpeaking {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            await MainActor.run {
                showWelcomeScreen = true
            }
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value.isEmpty ? "No disponible" : value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(value.isEmpty ? .secondary : .primary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

// MARK: - Animated Text Display Component
// MARK: - Helper Functions

private func formatDateOfBirth(_ dateString: String) -> String {
    // Parse date string (assuming format like "07/05/2004" or "05/07/2004")
    let components = dateString.components(separatedBy: "/")
    guard components.count == 3 else { return dateString }
    
    let day = components[0]
    let month = components[1]
    let year = components[2]
    
    // Convert month number to month name
    let monthNames = ["", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
                     "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
    
    guard let monthInt = Int(month), monthInt >= 1 && monthInt <= 12 else { return dateString }
    let monthName = monthNames[monthInt]
    
    // Convert day to ordinal (1st, 2nd, 3rd, 4th, etc.)
    guard let dayInt = Int(day) else { return dateString }
    let ordinalDay = getOrdinalDay(dayInt)
    
    return "\(monthName) \(ordinalDay), \(year)"
}

private func getOrdinalDay(_ day: Int) -> String {
    let suffix: String
    switch day {
    case 1, 21, 31:
        suffix = "st"
    case 2, 22:
        suffix = "nd"
    case 3, 23:
        suffix = "rd"
    default:
        suffix = "th"
    }
    return "\(day)\(suffix)"
}

private func translateGender(_ gender: String) -> String {
    switch gender.lowercased() {
    case "masculino", "Masculine":
        return "Masculine"
    case "femenino", "Feminine":
        return "Feminine"
    default:
        return gender
    }
}

struct AnimatedTextDisplay: View {
    let text: String
    @State private var displayedText = ""
    @State private var animationTimer: Timer?
    @State private var hasAnimated = false
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                if !hasAnimated {
                    startTypingAnimation()
                } else {
                    // If already animated, just show the full text
                    displayedText = text
                }
            }
            .onChange(of: text) { _, newValue in
                // Reset animation for new text
                hasAnimated = false
                startTypingAnimation()
            }
            .onDisappear {
                animationTimer?.invalidate()
            }
    }
    
    private func startTypingAnimation() {
        // Stop any existing animation
        animationTimer?.invalidate()
        
        // Reset displayed text
        displayedText = ""
        hasAnimated = false
        
        // Calculate how many lines the full text will have
        let fullTextLines = text.components(separatedBy: .newlines)
        let maxLines = 5
        
        // Start typing animation with moderate speed
        var currentIndex = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if currentIndex < text.count {
                let newText = String(text.prefix(currentIndex + 1))
                
                // If the full text will exceed max lines, start removing from top
                if fullTextLines.count > maxLines {
                    let lines = newText.components(separatedBy: .newlines)
                    if lines.count > maxLines {
                        // Remove the first line and keep the rest
                        let remainingLines = Array(lines.dropFirst())
                        displayedText = remainingLines.joined(separator: "\n")
                    } else {
                        displayedText = newText
                    }
                } else {
                    displayedText = newText
                }
                
                currentIndex += 1
            } else {
                timer.invalidate()
                hasAnimated = true  // Mark as completed
            }
        }
    }
}

#Preview {
    AIChatView(
        ocrResults: OCRResults.empty,
        onDataConfirmed: { _ in },
        onComplete: { }
    )
    .preferredColorScheme(.dark)
}
