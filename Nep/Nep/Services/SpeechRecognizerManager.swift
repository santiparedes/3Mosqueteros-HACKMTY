import Foundation
import Speech
import AVFoundation

class SpeechRecognizerManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isRecording = false
    private var error216Count = 0
    private let maxError216Retries = 2
    private var lastError216Time: Date?
    private let error216Cooldown: TimeInterval = 5.0
    
    var onTranscriptionUpdate: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onPermissionStatus: ((SFSpeechRecognizerAuthorizationStatus) -> Void)?
    var onTranscriptionComplete: ((String) -> Void)?
    
    private var lastTranscription: String = ""
    
    override init() {
        super.init()
        setupSpeechRecognizer()
        requestPermissions()
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
        speechRecognizer?.delegate = self
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                self?.onPermissionStatus?(authStatus)
                switch authStatus {
                case .authorized:
                    print("✅ Permiso de reconocimiento de voz concedido")
                case .denied:
                    print("❌ Permiso de reconocimiento de voz denegado")
                case .restricted:
                    print("⚠️ Reconocimiento de voz restringido")
                case .notDetermined:
                    print("❓ Permiso de reconocimiento de voz no determinado")
                @unknown default:
                    print("❓ Estado de permiso desconocido")
                }
            }
        }
    }
    
    func startRecognition() throws {
        print("🎙️ Iniciando reconocimiento de voz...")
        
        // Verificar disponibilidad del reconocedor
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw NSError(domain: "SpeechRecognizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "El reconocimiento de voz no está disponible"])
        }
        
        // Verificar cooldown del error 216
        if let lastErrorTime = lastError216Time {
            let timeSinceLastError = Date().timeIntervalSince(lastErrorTime)
            if timeSinceLastError < error216Cooldown {
                throw NSError(domain: "SpeechRecognizer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Por favor, espera unos segundos antes de intentar de nuevo"])
            }
        }
        
        // Limpiar sesión anterior
        cleanupPreviousSession()
        
        // Configurar sesión de audio
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Crear nueva solicitud de reconocimiento
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognizer", code: 3, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear la solicitud de reconocimiento"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Configurar grabación de audio
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Asegurarse de que no haya tap previo
        inputNode.removeTap(onBus: 0)
        
        // Instalar nuevo tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Iniciar motor de audio
        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        print("✅ Motor de audio iniciado correctamente")
        
        // Configurar tarea de reconocimiento
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error en reconocimiento: \(error.localizedDescription)")
                
                if let nsError = error as NSError? {
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                        self.handleError216()
                        return
                    }
                }
                
                // Solo mostrar error si no es por falta de habla
                if !(error.localizedDescription.contains("no speech detected") || 
                     error.localizedDescription.contains("no speech found")) {
                    self.onError?("Error en el reconocimiento: \(error.localizedDescription)")
                }
                return
            }
            
            // Verificar si hay resultado antes de procesarlo
            guard let result = result else {
                print("ℹ️ No se detectó habla")
                return
            }
            
            let transcription = result.bestTranscription.formattedString
            if !transcription.isEmpty {
                print("📝 Texto transcrito: \(transcription)")
                self.lastTranscription = transcription
                self.onTranscriptionUpdate?(transcription)
            }
            
            // Reset error counter on successful transcription
            self.error216Count = 0
            
            if result.isFinal {
                print("✅ Transcripción finalizada")
                if !self.lastTranscription.isEmpty {
                    self.onTranscriptionComplete?(self.lastTranscription)
                }
                self.stopRecognition()
            }
        }
    }
    
    private func handleError216() {
        error216Count += 1
        lastError216Time = Date()
        
        print("⚠️ Error 216 detectado (intento \(error216Count)/\(maxError216Retries))")
        
        if error216Count >= maxError216Retries {
            print("❌ Máximo de intentos alcanzado para error 216")
            onError?("El reconocimiento de voz no está disponible en este momento. Por favor, intenta más tarde.")
            stopRecognition()
            return
        }
        
        // Esperar antes de reintentar
        DispatchQueue.main.asyncAfter(deadline: .now() + error216Cooldown) { [weak self] in
            guard let self = self else { return }
            if self.isRecording {
                print("🔄 Reintentando después del cooldown...")
                self.cleanupPreviousSession()
                try? self.startRecognition()
            }
        }
    }
    
    func stopRecognition() {
        print("⏹️ Deteniendo reconocimiento...")
        
        // Marcar el final de la grabación
        recognitionRequest?.endAudio()
        
        // Detener motor de audio
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Finalizar reconocimiento
        recognitionTask?.cancel()
        
        // Limpiar referencias
        recognitionRequest = nil
        recognitionTask = nil
        
        isRecording = false
        print("✅ Sesión limpiada")
    }
    
    private func cleanupPreviousSession() {
        print("🧹 Limpiando sesión anterior...")
        
        // Marcar el final de la grabación anterior si existe
        recognitionRequest?.endAudio()
        
        // Detener motor de audio
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Finalizar reconocimiento
        recognitionTask?.cancel()
        
        // Limpiar referencias
        recognitionRequest = nil
        recognitionTask = nil
        
        print("✅ Sesión limpiada")
    }
    
    // MARK: - SFSpeechRecognizerDelegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print("🔄 Disponibilidad del reconocedor cambiada: \(available ? "Disponible" : "No disponible")")
        if !available && isRecording {
            onError?("El reconocimiento de voz ya no está disponible")
            stopRecognition()
        }
    }
}
