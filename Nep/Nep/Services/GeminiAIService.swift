import Foundation
import UIKit

class GeminiAIService: ObservableObject {
    static let shared = GeminiAIService()
    
    private let apiKey = APIConfig.geminiAPIKey
    private let baseURL = APIConfig.geminiBaseURL
    
    @Published var currentMessage = ""
    @Published var isProcessing = false
    @Published var conversationHistory: [ConversationMessage] = []
    
    private init() {}
    
    // MARK: - INE Document Analysis
    func analyzeINEDocument(_ ocrResults: OCRResults) async -> INEAnalysis {
        print("🤖 GEMINI: Starting INE document analysis...")
        
        guard APIConfig.isGeminiConfigured else {
            print("❌ GEMINI: API not configured. Using fallback analysis.")
            return createFallbackAnalysis(ocrResults)
        }
        
        print("✅ GEMINI: API configured, sending request...")
        let prompt = createINEAnalysisPrompt(ocrResults)
        
        do {
            let response = try await sendGeminiRequest(prompt: prompt)
            print("✅ GEMINI: Analysis completed successfully!")
            return parseINEAnalysis(response)
        } catch {
            print("❌ GEMINI: Error analyzing INE document: \(error)")
            return INEAnalysis(
                isValid: false,
                confidence: 0.0,
                missingFields: [],
                suggestions: ["Error analyzing document. Please try again."],
                extractedData: ocrResults
            )
        }
    }
    
    // MARK: - Onboarding Conversation
    func generateOnboardingGuidance(step: OnboardingStep, ocrResults: OCRResults) async -> String {
        print("🤖 GEMINI: Generating guidance for step: \(step.description)")
        
        let prompt = createOnboardingPrompt(step: step, ocrResults: ocrResults)
        
        do {
            let response = try await sendGeminiRequest(prompt: prompt)
            print("✅ GEMINI: Generated guidance: \(response.prefix(50))...")
            return response
        } catch {
            print("❌ GEMINI: Error generating guidance: \(error)")
            return getFallbackMessage(for: step)
        }
    }
    
    // MARK: - Voice Conversation Management
    func processUserResponse(_ userInput: String, context: OnboardingContext) async -> ConversationResponse {
        let prompt = createConversationPrompt(userInput: userInput, context: context)
        
        do {
            let response = try await sendGeminiRequest(prompt: prompt)
            let conversationResponse = parseConversationResponse(response)
            
            // Add to conversation history
            await MainActor.run {
                conversationHistory.append(ConversationMessage(
                    id: UUID(),
                    text: userInput,
                    isUser: true,
                    timestamp: Date()
                ))
                conversationHistory.append(ConversationMessage(
                    id: UUID(),
                    text: conversationResponse.message,
                    isUser: false,
                    timestamp: Date()
                ))
            }
            
            return conversationResponse
        } catch {
            print("Error processing user response: \(error)")
            return ConversationResponse(
                message: "Lo siento, no pude procesar tu respuesta. ¿Podrías repetir?",
                nextAction: .continue,
                requiresConfirmation: false
            )
        }
    }
    
    // MARK: - Data Correction Processing
    func processDataCorrection(_ userInput: String, currentData: OCRResults) async -> DataCorrectionResponse {
        print("🤖 GEMINI: Processing data correction request...")
        
        let prompt = createDataCorrectionPrompt(userInput: userInput, currentData: currentData)
        
        do {
            let response = try await sendGeminiRequest(prompt: prompt)
            return parseDataCorrectionResponse(response, currentData: currentData)
        } catch {
            print("❌ GEMINI: Error processing data correction: \(error)")
            return DataCorrectionResponse(
                message: "No pude procesar la corrección. ¿Podrías ser más específico sobre qué datos están incorrectos?",
                correctedData: currentData,
                hasChanges: false
            )
        }
    }
    
    // MARK: - Private Methods
    private func sendGeminiRequest(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [GeminiPart(text: prompt)]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 1024
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GeminiError.invalidResponse
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let candidate = geminiResponse.candidates.first,
              let part = candidate.content.parts.first else {
            throw GeminiError.noContent
        }
        
        return part.text
    }
    
    private func createINEAnalysisPrompt(_ ocrResults: OCRResults) -> String {
        return """
        Analiza los siguientes datos extraídos de una credencial INE (Instituto Nacional Electoral) mexicana:
        
        Nombre: \(ocrResults.fullName)
        CURP: \(ocrResults.curp)
        Fecha de Nacimiento: \(ocrResults.dateOfBirth)
        Número de Documento: \(ocrResults.documentNumber)
        Sexo: \(ocrResults.sex)
        Sección Electoral: \(ocrResults.electoralSection)
        Localidad: \(ocrResults.locality)
        Municipio: \(ocrResults.municipality)
        Estado: \(ocrResults.state)
        Fecha de Emisión: \(ocrResults.issueDate)
        Fecha de Vencimiento: \(ocrResults.expirationDate)
        Dirección: \(ocrResults.address)
        
        Por favor, analiza estos datos y responde en formato JSON con la siguiente estructura:
        {
            "isValid": boolean,
            "confidence": number (0-1),
            "missingFields": ["campo1", "campo2"],
            "suggestions": ["sugerencia1", "sugerencia2"],
            "validationErrors": ["error1", "error2"]
        }
        
        Considera:
        1. Si el CURP tiene el formato correcto (18 caracteres alfanuméricos)
        2. Si las fechas tienen formato válido
        3. Si los campos obligatorios están presentes
        4. Si la información es consistente
        5. Si el documento no está vencido
        """
    }
    
    private func createOnboardingPrompt(step: OnboardingStep, ocrResults: OCRResults) -> String {
        let basePrompt = """
        Eres un asistente virtual de NEP, un banco digital mexicano. Tu tarea es guiar al usuario a través del proceso de onboarding de manera amigable y profesional.
        
        Contexto del usuario:
        - Nombre: \(ocrResults.fullName)
        - Documento: INE
        - Paso actual: \(step.description)
        
        Genera un mensaje de voz amigable y claro que:
        1. Sea natural y conversacional
        2. Use un tono profesional pero cálido
        3. Esté en español mexicano
        4. Sea conciso (máximo 2-3 oraciones)
        5. Guíe al usuario en el siguiente paso
        """
        
        switch step {
        case .welcome:
            return basePrompt + "\n\nDa la bienvenida al usuario y explica que vas a ayudarle a completar su registro bancario."
        case .documentCapture:
            return basePrompt + "\n\nExplica que necesita tomar fotos de su INE (frente y reverso) y asegúrate de que esté bien iluminado."
        case .dataVerification:
            return basePrompt + "\n\nExplica que vas a verificar los datos extraídos de su INE y que puede corregir cualquier error."
        case .voiceVerification:
            return basePrompt + "\n\nExplica que vas a hacer algunas preguntas de verificación por voz para confirmar su identidad."
        case .additionalInfo:
            return basePrompt + "\n\nExplica que necesitas información adicional como ocupación y fuente de ingresos."
        case .finalConfirmation:
            return basePrompt + "\n\nExplica que vas a revisar toda la información antes de finalizar el registro."
        }
    }
    
    private func createConversationPrompt(userInput: String, context: OnboardingContext) -> String {
        return """
        Eres un asistente virtual de NEP. El usuario está en el proceso de onboarding bancario.
        
        Contexto:
        - Paso actual: \(context.currentStep.description)
        - Datos del usuario: \(context.userData.fullName)
        - Historial de conversación: \(context.conversationHistory.map { "\($0.isUser ? "user" : "assistant"): \($0.text)" }.joined(separator: "\n"))
        
        Respuesta del usuario: "\(userInput)"
        
        Responde de manera natural y útil. Si el usuario:
        - Confirma información: Agradece y continúa
        - Corrige información: Pide confirmación de la corrección
        - Hace preguntas: Responde de manera clara y amigable
        - Expresa dudas: Tranquiliza y explica el proceso
        
        Responde en formato JSON:
        {
            "message": "tu respuesta aquí",
            "nextAction": "continue|repeat|confirm|error",
            "requiresConfirmation": boolean
        }
        """
    }
    
    private func createDataCorrectionPrompt(userInput: String, currentData: OCRResults) -> String {
        return """
        Eres un asistente virtual de NEP especializado en corrección de datos de documentos INE.
        
        Datos actuales extraídos del INE:
        - Nombre completo: \(currentData.fullName)
        - CURP: \(currentData.curp)
        - Fecha de Nacimiento: \(currentData.dateOfBirth)
        - Número de Documento: \(currentData.documentNumber)
        - Sexo: \(currentData.sex)
        - Sección Electoral: \(currentData.electoralSection)
        - Localidad: \(currentData.locality)
        - Municipio: \(currentData.municipality)
        - Estado: \(currentData.state)
        - Fecha de Emisión: \(currentData.issueDate)
        - Fecha de Vencimiento: \(currentData.expirationDate)
        - Dirección: \(currentData.address)
        
        El usuario dice: "\(userInput)"
        
        Analiza qué datos están incorrectos según el usuario y proporciona los datos corregidos.
        
        Responde en formato JSON:
        {
            "message": "mensaje de confirmación de la corrección",
            "correctedData": {
                "firstName": "nuevo nombre",
                "lastName": "nuevo apellido",
                "middleName": "nuevo segundo nombre",
                "dateOfBirth": "nueva fecha",
                "documentNumber": "nuevo número",
                "curp": "nuevo curp",
                "sex": "nuevo sexo",
                "electoralSection": "nueva sección",
                "locality": "nueva localidad",
                "municipality": "nuevo municipio",
                "state": "nuevo estado",
                "issueDate": "nueva fecha emisión",
                "expirationDate": "nueva fecha vencimiento",
                "address": "nueva dirección"
            },
            "hasChanges": boolean
        }
        
        Si no hay cambios específicos mencionados, mantén los datos originales y hasChanges = false.
        """
    }
    
    private func parseINEAnalysis(_ response: String) -> INEAnalysis {
        // Parse JSON response from Gemini
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return INEAnalysis(
                isValid: false,
                confidence: 0.0,
                missingFields: [],
                suggestions: ["Error parsing analysis"],
                extractedData: OCRResults.empty
            )
        }
        
        return INEAnalysis(
            isValid: json["isValid"] as? Bool ?? false,
            confidence: json["confidence"] as? Double ?? 0.0,
            missingFields: json["missingFields"] as? [String] ?? [],
            suggestions: json["suggestions"] as? [String] ?? [],
            extractedData: OCRResults.empty // Will be filled by caller
        )
    }
    
    private func parseConversationResponse(_ response: String) -> ConversationResponse {
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ConversationResponse(
                message: "Lo siento, no pude procesar tu respuesta.",
                nextAction: .error,
                requiresConfirmation: false
            )
        }
        
        let nextActionString = json["nextAction"] as? String ?? "continue"
        let nextAction = ConversationAction(rawValue: nextActionString) ?? .`continue`
        
        return ConversationResponse(
            message: json["message"] as? String ?? "Continuemos con el proceso.",
            nextAction: nextAction,
            requiresConfirmation: json["requiresConfirmation"] as? Bool ?? false
        )
    }
    
    private func parseDataCorrectionResponse(_ response: String, currentData: OCRResults) -> DataCorrectionResponse {
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return DataCorrectionResponse(
                message: "No pude procesar la corrección. ¿Podrías ser más específico?",
                correctedData: currentData,
                hasChanges: false
            )
        }
        
        let message = json["message"] as? String ?? "He procesado tu corrección."
        let hasChanges = json["hasChanges"] as? Bool ?? false
        
        var correctedData = currentData
        
        if hasChanges, let correctedDataDict = json["correctedData"] as? [String: Any] {
            correctedData = OCRResults(
                firstName: correctedDataDict["firstName"] as? String ?? currentData.firstName,
                lastName: correctedDataDict["lastName"] as? String ?? currentData.lastName,
                middleName: correctedDataDict["middleName"] as? String ?? currentData.middleName,
                dateOfBirth: correctedDataDict["dateOfBirth"] as? String ?? currentData.dateOfBirth,
                documentNumber: correctedDataDict["documentNumber"] as? String ?? currentData.documentNumber,
                nationality: currentData.nationality,
                address: correctedDataDict["address"] as? String ?? currentData.address,
                occupation: currentData.occupation,
                incomeSource: currentData.incomeSource,
                curp: correctedDataDict["curp"] as? String ?? currentData.curp,
                sex: correctedDataDict["sex"] as? String ?? currentData.sex,
                electoralSection: correctedDataDict["electoralSection"] as? String ?? currentData.electoralSection,
                locality: correctedDataDict["locality"] as? String ?? currentData.locality,
                municipality: correctedDataDict["municipality"] as? String ?? currentData.municipality,
                state: correctedDataDict["state"] as? String ?? currentData.state,
                expirationDate: correctedDataDict["expirationDate"] as? String ?? currentData.expirationDate,
                issueDate: correctedDataDict["issueDate"] as? String ?? currentData.issueDate
            )
        }
        
        return DataCorrectionResponse(
            message: message,
            correctedData: correctedData,
            hasChanges: hasChanges
        )
    }
    
    private func getFallbackMessage(for step: OnboardingStep) -> String {
        switch step {
        case .welcome:
            return "¡Bienvenido a Nep! Te ayudo a completar tu registro bancario."
        case .documentCapture:
            return "Por favor, toma una foto clara de tu INE. Asegúrate de que esté bien iluminado."
        case .dataVerification:
            return "Vamos a verificar los datos de tu INE. Revisa que todo esté correcto."
        case .voiceVerification:
            return "Ahora voy a hacerte algunas preguntas para verificar tu identidad."
        case .additionalInfo:
            return "Necesito información adicional sobre tu ocupación y ingresos."
        case .finalConfirmation:
            return "Revisemos toda la información antes de finalizar tu registro."
        }
    }
    
    private func createFallbackAnalysis(_ ocrResults: OCRResults) -> INEAnalysis {
        var missingFields: [String] = []
        var suggestions: [String] = []
        
        // Basic validation without AI
        if ocrResults.firstName.isEmpty { missingFields.append("Nombre") }
        if ocrResults.lastName.isEmpty { missingFields.append("Apellido") }
        if ocrResults.curp.isEmpty { missingFields.append("CURP") }
        if ocrResults.documentNumber.isEmpty { missingFields.append("Número de INE") }
        if ocrResults.dateOfBirth.isEmpty { missingFields.append("Fecha de Nacimiento") }
        
        let isValid = missingFields.isEmpty
        let confidence = isValid ? 0.8 : 0.3
        
        if !isValid {
            suggestions.append("Por favor, verifica que todos los campos estén completos")
            suggestions.append("Asegúrate de que la foto esté bien iluminada y enfocada")
        }
        
        return INEAnalysis(
            isValid: isValid,
            confidence: confidence,
            missingFields: missingFields,
            suggestions: suggestions,
            extractedData: ocrResults
        )
    }
}

// MARK: - Data Models
struct INEAnalysis {
    let isValid: Bool
    let confidence: Double
    let missingFields: [String]
    let suggestions: [String]
    let extractedData: OCRResults
}

struct ConversationResponse {
    let message: String
    let nextAction: ConversationAction
    let requiresConfirmation: Bool
}

struct DataCorrectionResponse {
    let message: String
    let correctedData: OCRResults
    let hasChanges: Bool
}

enum ConversationAction: String {
    case `continue` = "continue"
    case `repeat` = "repeat"
    case confirm = "confirm"
    case error = "error"
}


enum MessageRole: String {
    case user = "user"
    case assistant = "assistant"
}

enum OnboardingStep {
    case welcome
    case documentCapture
    case dataVerification
    case voiceVerification
    case additionalInfo
    case finalConfirmation
    
    var description: String {
        switch self {
        case .welcome: return "Bienvenida"
        case .documentCapture: return "Captura de Documento"
        case .dataVerification: return "Verificación de Datos"
        case .voiceVerification: return "Verificación por Voz"
        case .additionalInfo: return "Información Adicional"
        case .finalConfirmation: return "Confirmación Final"
        }
    }
}

struct OnboardingContext {
    let currentStep: OnboardingStep
    let userData: OCRResults
    let conversationHistory: [ConversationMessage]
}

// MARK: - Gemini API Models
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let topK: Int
    let topP: Double
    let maxOutputTokens: Int
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

// MARK: - Error Handling
enum GeminiError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noContent
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida para Gemini API"
        case .invalidResponse:
            return "Respuesta inválida de Gemini API"
        case .noContent:
            return "No se pudo obtener contenido de Gemini"
        case .apiKeyMissing:
            return "API Key de Gemini no configurada"
        }
    }
}
