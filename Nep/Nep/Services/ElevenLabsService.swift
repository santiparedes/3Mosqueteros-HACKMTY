import Foundation
import AVFoundation
import Speech

class ElevenLabsService: NSObject, ObservableObject {
    static let shared = ElevenLabsService()
    
    @Published var isSpeaking = false
    @Published var isListening = false
    @Published var currentMessage = ""
    @Published var conversationHistory: [ConversationMessage] = []
    @Published var isGeminiProcessing = false
    
    private let apiKey = APIConfig.elevenLabsAPIKey
    private let baseURL = APIConfig.elevenLabsBaseURL
    private var audioPlayer: AVAudioPlayer?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Gemini AI integration
    private let geminiService = GeminiAIService.shared
    private var currentOnboardingStep: OnboardingStep = .welcome
    private var currentOCRResults: OCRResults = OCRResults.empty
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Text to Speech
    func speak(_ text: String, voiceId: String = APIConfig.defaultVoiceId) async {
        print("🎤 ELEVENLABS: Starting speech generation...")
        print("🎤 ELEVENLABS: Text to speak: \(text.prefix(50))...")
        
        await MainActor.run {
            isSpeaking = true
            currentMessage = text
        }
        
        guard APIConfig.isElevenLabsConfigured else {
            print("❌ ELEVENLABS: API not configured. Using system TTS.")
            await speakWithSystemTTS(text)
            return
        }
        
        print("✅ ELEVENLABS: API configured, generating speech...")
        do {
            let audioData = try await generateSpeech(text: text, voiceId: voiceId)
            try await playAudio(audioData)
            print("✅ ELEVENLABS: Speech generated and played successfully!")
        } catch {
            print("❌ ELEVENLABS: Speech generation error: \(error)")
            // Fallback to system TTS
            await speakWithSystemTTS(text)
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
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ElevenLabsError.invalidResponse
        }
        
        return data
    }
    
    private func playAudio(_ data: Data) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer?.delegate = self
                audioPlayer?.play()
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Speech to Text
    func startListening() async throws {
        guard !isListening else { return }
        
        // Cancel previous task
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Request microphone permission
        guard await requestMicrophonePermission() else {
            throw ElevenLabsError.microphonePermissionDenied
        }
        
        // Request speech recognition permission
        guard await requestSpeechRecognitionPermission() else {
            throw ElevenLabsError.speechRecognitionPermissionDenied
        }
        
        await MainActor.run {
            isListening = true
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
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let spokenText = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.currentMessage = spokenText
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                Task { @MainActor in
                    self.isListening = false
                }
            }
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        
        Task { @MainActor in
            isListening = false
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
    
    // MARK: - System TTS Fallback
    private func speakWithSystemTTS(_ text: String) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        
        // Wait for speech to complete
        while synthesizer.isSpeaking {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
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
