import Foundation
import AVFoundation
import Speech

class ElevenLabsService: NSObject, ObservableObject {
    static let shared = ElevenLabsService()
    
    @Published var isSpeaking = false
    @Published var isListening = false
    @Published var currentMessage = ""
    @Published var conversationHistory: [ConversationMessage] = []
    
    private let apiKey = "YOUR_ELEVENLABS_API_KEY" // Replace with actual API key
    private let baseURL = "https://api.elevenlabs.io/v1"
    private var audioPlayer: AVAudioPlayer?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
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
    func speak(_ text: String, voiceId: String = "pNInz6obpgDQGcFmaJgB") async {
        await MainActor.run {
            isSpeaking = true
            currentMessage = text
        }
        
        do {
            let audioData = try await generateSpeech(text: text, voiceId: voiceId)
            try await playAudio(audioData)
        } catch {
            print("Speech generation error: \(error)")
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
    
    // MARK: - Conversation Management
    func startOnboardingConversation(ocrResults: OCRResults) async {
        let welcomeMessage = """
        ¡Hola! Soy tu asistente virtual de NEP. He detectado algunos datos de tu identificación:
        
        Nombre: \(ocrResults.fullName)
        Fecha de nacimiento: \(ocrResults.dateOfBirth)
        Número de documento: \(ocrResults.documentNumber)
        
        ¿Podrías confirmarme tu nombre completo por favor?
        """
        
        await speak(welcomeMessage)
        addMessage(welcomeMessage, isUser: false)
    }
    
    func processUserResponse(_ response: String) async -> String {
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
