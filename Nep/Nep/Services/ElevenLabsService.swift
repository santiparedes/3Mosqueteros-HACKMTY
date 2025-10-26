import Foundation
import AVFoundation
import Speech

extension Notification.Name {
    static let voiceRecognitionResult = Notification.Name("voiceRecognitionResult")
}

class ElevenLabsService: NSObject, ObservableObject {
    static let shared = ElevenLabsService()
    
    // Debug flag to force Apple TTS instead of ElevenLabs
    static var forceAppleTTS = false
    
    @Published var isSpeaking = false
    @Published var isListening = false
    @Published var currentMessage = ""
    @Published var conversationHistory: [ConversationMessage] = []
    @Published var isGeminiProcessing = false
    
    // Audio queue management
    private var audioQueue: [String] = []
    private var isProcessingQueue = false
    private var hasPostedResult = false
    
    private let apiKey = APIConfig.elevenLabsAPIKey
    private let baseURL = APIConfig.elevenLabsBaseURL
    private var audioPlayer: AVAudioPlayer?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Gemini AI integration
    private let geminiService = GeminiAIService.shared
    private var currentOnboardingStep: OnboardingStep = .welcome
    private var currentOCRResults: OCRResults = OCRResults.empty
    
    private override init() {
        super.init()
        Task {
            await setupAudioSession()
        }
    }
    
    private func setupAudioSession() async {
        do {
            print("🔊 ELEVENLABS: Setting up audio session for playback...")
            
            // First deactivate the current session
            try? AVAudioSession.sharedInstance().setActive(false)
            
            // Wait a moment for deactivation to complete
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            
            // Set category for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ ELEVENLABS: Audio session configured for playback")
        } catch {
            print("❌ ELEVENLABS: Failed to setup playback audio session: \(error)")
        }
    }
    
    private func setupAudioSessionForRecording() {
        do {
            print("🔊 ELEVENLABS: Setting up audio session for recording...")
            
            // First deactivate the current session
            try? AVAudioSession.sharedInstance().setActive(false)
            
            // Set category for recording
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ ELEVENLABS: Audio session configured for recording")
        } catch {
            print("❌ ELEVENLABS: Failed to setup recording audio session: \(error)")
        }
    }
    
    // MARK: - Text to Speech
    func speak(_ text: String, voiceId: String = APIConfig.defaultVoiceId) async {
        print("🎤 ELEVENLABS: Starting speech generation...")
        print("🎤 ELEVENLABS: Text to speak: \(text.prefix(50))...")
        
        // Check if we're already processing this exact text
        if audioQueue.contains(text) {
            print("🎤 ELEVENLABS: Text already in queue, skipping duplicate")
            return
        }
        
        // Add to queue instead of speaking immediately
        audioQueue.append(text)
        
        // Process queue if not already processing
        if !isProcessingQueue {
            await processAudioQueue(voiceId: voiceId)
        }
    }
    
    private func processAudioQueue(voiceId: String) async {
        guard !isProcessingQueue else { return }
        
        isProcessingQueue = true
        
        while !audioQueue.isEmpty {
            let text = audioQueue.removeFirst()
            
            // Wait for any current speech to finish
            while isSpeaking {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Speak the text
            await speakImmediately(text, voiceId: voiceId)
        }
        
        isProcessingQueue = false
    }
    
    private func speakImmediately(_ text: String, voiceId: String) async {
        // Re-setup audio session to ensure it's active
        await setupAudioSession()
        
        await MainActor.run {
            isSpeaking = true
            currentMessage = text
        }
        
        guard APIConfig.isElevenLabsConfigured else {
            print("❌ ELEVENLABS: API not configured. Skipping speech.")
            await MainActor.run {
                isSpeaking = false
            }
            return
        }
        
        print("✅ ELEVENLABS: API configured, generating speech...")
        print("🔑 ELEVENLABS: Using API key: \(apiKey.prefix(10))...")
        print("🎯 ELEVENLABS: Using voice ID: \(voiceId)")
        print("📝 ELEVENLABS: Text length: \(text.count) characters")
        do {
            let audioData = try await generateSpeech(text: text, voiceId: voiceId)
            try await playAudio(audioData)
            print("✅ ELEVENLABS: Speech generated and played successfully!")
        } catch {
            print("❌ ELEVENLABS: Speech generation error: \(error)")
            // Just skip speech if ElevenLabs fails
        }
        
        await MainActor.run {
            isSpeaking = false
        }
    }
    
    private func generateSpeech(text: String, voiceId: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/text-to-speech/\(voiceId)") else {
            throw ElevenLabsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let requestBody: [String: Any] = [
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.5
            ] as [String: Any]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📊 ELEVENLABS: Received audio data: \(data.count) bytes")
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("❌ ELEVENLABS: Invalid HTTP response")
            throw ElevenLabsError.invalidResponse
        }
        
        print("✅ ELEVENLABS: Audio data received successfully")
        return data
    }
    
    private func playAudio(_ data: Data) async throws {
        print("🔊 ELEVENLABS: Preparing to play audio...")
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                // Ensure audio session is active
                try AVAudioSession.sharedInstance().setActive(true)
                
                audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer?.delegate = self
                audioPlayer?.volume = 1.0
                audioPlayer?.prepareToPlay()
                
                print("🔊 ELEVENLABS: Audio player prepared, starting playback...")
                let success = audioPlayer?.play() ?? false
                
                if success {
                    print("✅ ELEVENLABS: Audio playback started successfully")
                    continuation.resume()
                } else {
                    print("❌ ELEVENLABS: Failed to start audio playback")
                    continuation.resume(throwing: ElevenLabsError.invalidResponse)
                }
            } catch {
                print("❌ ELEVENLABS: Audio playback error: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Speech to Text
    func startListening() async throws {
        guard !isListening else { 
            print("🎤 SPEECH RECOGNITION: Already listening, ignoring start request")
            return 
        }
        
        // Cancel previous task and clean up
        if let recognitionTask = recognitionTask {
            print("🎤 SPEECH RECOGNITION: Canceling previous task")
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Clean up any existing audio engine state
        if audioEngine.isRunning {
            print("🎤 SPEECH RECOGNITION: Stopping existing audio engine")
            audioEngine.stop()
            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
        }
        
        // Request microphone permission
        guard await requestMicrophonePermission() else {
            throw ElevenLabsError.microphonePermissionDenied
        }
        
        // Request speech recognition permission
        guard await requestSpeechRecognitionPermission() else {
            throw ElevenLabsError.speechRecognitionPermissionDenied
        }
        
        // Setup audio session for recording
        setupAudioSessionForRecording()
        
        await MainActor.run {
            isListening = true
            hasPostedResult = false  // Reset flag for new session
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw ElevenLabsError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Validate the audio format before using it
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("❌ SPEECH RECOGNITION: Invalid audio format - sampleRate: \(recordingFormat.sampleRate), channelCount: \(recordingFormat.channelCount)")
            throw ElevenLabsError.recognitionRequestFailed
        }
        
        print("🎤 SPEECH RECOGNITION: Using audio format - sampleRate: \(recordingFormat.sampleRate), channelCount: \(recordingFormat.channelCount)")
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            print("🎤 SPEECH RECOGNITION: Received result or error")
            
            if let error = error {
                print("❌ SPEECH RECOGNITION: Error: \(error)")
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                Task { @MainActor in
                    self.isListening = false
                }
                return
            }
            
            if let result = result {
                let spokenText = result.bestTranscription.formattedString
                print("🎤 SPEECH RECOGNITION: Text: '\(spokenText)', isFinal: \(result.isFinal)")
                
                Task { @MainActor in
                    self.currentMessage = spokenText
                }
                
                // Post notification when we have a final result
                if result.isFinal {
                    print("🎤 SPEECH RECOGNITION: Final result - posting notification")
                    NotificationCenter.default.post(
                        name: .voiceRecognitionResult,
                        object: nil,
                        userInfo: ["text": spokenText]
                    )
                } else {
                    print("🎤 SPEECH RECOGNITION: Partial result - not posting yet")
                }
            }
            
            if let result = result, result.isFinal {
                print("🎤 SPEECH RECOGNITION: Stopping recognition (final result)")
                
                // Post notification for final result only if it's not empty and we haven't posted yet
                let spokenText = result.bestTranscription.formattedString
                if !spokenText.isEmpty && spokenText.trimmingCharacters(in: .whitespacesAndNewlines) != "" && !self.hasPostedResult {
                    print("🎤 SPEECH RECOGNITION: Final result - posting notification")
                    self.hasPostedResult = true
                    NotificationCenter.default.post(
                        name: .voiceRecognitionResult,
                        object: nil,
                        userInfo: ["text": spokenText]
                    )
                } else {
                    print("🎤 SPEECH RECOGNITION: Final result is empty or already posted, not posting")
                }
                
                // Always stop the engine and cleanup
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                Task { @MainActor in
                    self.isListening = false
                }
                
                return  // Exit early to prevent further processing
            }
        }
    }
    
    func stopListening() {
        print("🎤 SPEECH RECOGNITION: Stopping recognition...")
        
        // Stop audio engine first
        audioEngine.stop()
        
        // Remove tap from input node to stop audio processing
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Cancel and clear recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // If we have any partial text, post it as a notification
        if !currentMessage.isEmpty && currentMessage.trimmingCharacters(in: .whitespacesAndNewlines) != "" && !hasPostedResult {
            print("🎤 SPEECH RECOGNITION: Posting final result: '\(currentMessage)'")
            hasPostedResult = true
            NotificationCenter.default.post(
                name: .voiceRecognitionResult,
                object: nil,
                userInfo: ["text": currentMessage]
            )
        } else {
            print("🎤 SPEECH RECOGNITION: No valid message to post or already posted")
        }
        
        // Set microphone mode as default for next voice input
        setMicrophoneMode()
        
        Task { @MainActor in
            isListening = false
        }
    }
    
    // MARK: - Microphone Mode Management
    func setMicrophoneMode() {
        print("🎤 MICROPHONE: Setting microphone mode as default")
        
        do {
            // Set audio session for microphone/recording mode
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ MICROPHONE: Microphone mode set successfully")
        } catch {
            print("❌ MICROPHONE: Failed to set microphone mode: \(error)")
        }
    }
    
    
    // MARK: - Gemini-Powered Conversation Management
    func startOnboardingConversation(ocrResults: OCRResults) async {
        currentOCRResults = ocrResults
        currentOnboardingStep = .welcome
        
        // Use Gemini to generate personalized welcome message
        let welcomeMessage = await geminiService.generateOnboardingGuidance(
            step: .welcome,
            ocrResults: ocrResults
        )
        
        await speak(welcomeMessage)
        addMessage(welcomeMessage, isUser: false)
    }
    
    func processUserResponse(_ response: String) async -> ConversationResponse {
        await MainActor.run {
            isGeminiProcessing = true
        }
        
        // Create conversation context
        let context = OnboardingContext(
            currentStep: currentOnboardingStep,
            userData: currentOCRResults,
            conversationHistory: conversationHistory
        )
        
        // Use Gemini to process the response
        let geminiResponse = await geminiService.processUserResponse(response, context: context)
        
        await MainActor.run {
            isGeminiProcessing = false
        }
        
        // Speak the response
        await speak(geminiResponse.message)
        
        return geminiResponse
    }
    
    func advanceToNextStep() async {
        switch currentOnboardingStep {
        case .welcome:
            currentOnboardingStep = .documentCapture
        case .documentCapture:
            currentOnboardingStep = .dataVerification
        case .dataVerification:
            currentOnboardingStep = .voiceVerification
        case .voiceVerification:
            currentOnboardingStep = .additionalInfo
        case .additionalInfo:
            currentOnboardingStep = .finalConfirmation
        case .finalConfirmation:
            // Onboarding complete
            break
        }
        
        // Generate guidance for the new step
        let guidance = await geminiService.generateOnboardingGuidance(
            step: currentOnboardingStep,
            ocrResults: currentOCRResults
        )
        
        await speak(guidance)
        addMessage(guidance, isUser: false)
    }
    
    func updateOCRResults(_ newResults: OCRResults) {
        currentOCRResults = newResults
    }
    
    func analyzeINEDocument() async -> INEAnalysis {
        return await geminiService.analyzeINEDocument(currentOCRResults)
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    func processUserResponseLegacy(_ response: String) async -> String {
        addMessage(response, isUser: true)
        
        // Simple response processing (in a real app, you'd use more sophisticated NLP)
        let lowercasedResponse = response.lowercased()
        
        if lowercasedResponse.contains("sí") || lowercasedResponse.contains("si") || lowercasedResponse.contains("correcto") {
            let nextQuestion = "Perfecto. Ahora, ¿cuál es tu ocupación principal?"
            await speak(nextQuestion)
            addMessage(nextQuestion, isUser: false)
            return nextQuestion
        } else if lowercasedResponse.contains("no") || lowercasedResponse.contains("incorrecto") {
            let correctionRequest = "Entiendo. Por favor, dime cuál es tu nombre correcto."
            await speak(correctionRequest)
            addMessage(correctionRequest, isUser: false)
            return correctionRequest
        } else {
            // Assume it's a name correction
            let confirmation = "Gracias. He anotado: \(response). ¿Es correcto?"
            await speak(confirmation)
            addMessage(confirmation, isUser: false)
            return confirmation
        }
    }
    
    private func addMessage(_ text: String, isUser: Bool) {
        let message = ConversationMessage(
            id: UUID(),
            text: text,
            isUser: isUser,
            timestamp: Date()
        )
        conversationHistory.append(message)
    }
    
    // MARK: - Permissions
    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    private func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    // MARK: - Apple Native TTS Fallback
    func speakWithAppleTTS(_ text: String) async {
        print("🍎 APPLE TTS: Using native Apple voice synthesis")
        print("🍎 APPLE TTS: Text to speak: \(text.prefix(50))...")
        
        // Ensure audio session is set up for playback
        do {
            // Try to deactivate current session first (ignore errors)
            try? AVAudioSession.sharedInstance().setActive(false)
            
            // Set category for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            
            // Activate the session
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ APPLE TTS: Audio session configured for playback")
        } catch {
            print("❌ APPLE TTS: Failed to setup audio session: \(error)")
            // Try fallback approach
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                print("✅ APPLE TTS: Fallback audio session configured")
            } catch {
                print("❌ APPLE TTS: Fallback also failed: \(error)")
            }
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Try to use English voice first, fallback to system default
        if let englishVoice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = englishVoice
            print("🍎 APPLE TTS: Using English voice")
        } else if let spanishVoice = AVSpeechSynthesisVoice(language: "es-MX") {
            utterance.voice = spanishVoice
            print("🍎 APPLE TTS: Using Spanish voice")
        } else {
            print("🍎 APPLE TTS: Using system default voice")
        }
        
        utterance.rate = 0.5
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        
        speechSynthesizer.speak(utterance)
        
        print("🍎 APPLE TTS: Speech started")
        
        // Wait for speech to complete
        while speechSynthesizer.isSpeaking {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        print("✅ APPLE TTS: Speech completed")
    }
    
    // MARK: - Testing Methods
    func testAppleTTS(_ text: String) async {
        print("🧪 TESTING: Testing Apple TTS directly")
        await speakWithAppleTTS(text)
    }
    
    func forceAppleTTSMode(_ enabled: Bool) {
        Self.forceAppleTTS = enabled
        print("🧪 TESTING: Apple TTS force mode: \(enabled ? "enabled" : "disabled")")
    }
}

// MARK: - AVAudioPlayerDelegate
extension ElevenLabsService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
    }
}

// MARK: - Data Models
struct ConversationMessage: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
}

enum ElevenLabsError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case microphonePermissionDenied
    case speechRecognitionPermissionDenied
    case recognitionRequestFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .microphonePermissionDenied:
            return "Permiso de micrófono denegado"
        case .speechRecognitionPermissionDenied:
            return "Permiso de reconocimiento de voz denegado"
        case .recognitionRequestFailed:
            return "Error al crear solicitud de reconocimiento"
        }
    }
}
