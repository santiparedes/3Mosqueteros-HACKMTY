import Foundation
import CryptoKit

class OnboardingService: ObservableObject {
    static let shared = OnboardingService()
    
    private let baseURL = "http://localhost:8000" // Local backend for development
    private let apiKey = "YOUR_API_KEY" // Replace with actual API key
    
    private init() {}
    
    // MARK: - Data Encryption
    private func encryptData(_ data: Data) throws -> Data {
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined ?? Data()
    }
    
    private func decryptData(_ encryptedData: Data) throws -> Data {
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Save Onboarding Data
    func saveOnboardingData(_ results: OCRResults, userId: String) async throws -> OnboardingResponse {
        let onboardingData = OnboardingData(
            userId: userId,
            firstName: results.firstName,
            lastName: results.lastName,
            middleName: results.middleName,
            dateOfBirth: results.dateOfBirth,
            documentNumber: results.documentNumber,
            nationality: results.nationality,
            address: results.address,
            occupation: results.occupation,
            incomeSource: results.incomeSource,
            timestamp: Date(),
            status: .pending
        )
        
        // Encrypt sensitive data
        let encryptedData = try encryptSensitiveData(onboardingData)
        
        // Send to backend
        let response = try await sendToBackend(encryptedData)
        
        return response
    }
    
    private func encryptSensitiveData(_ data: OnboardingData) throws -> EncryptedOnboardingData {
        let jsonData = try JSONEncoder().encode(data)
        let encryptedData = try encryptData(jsonData)
        
        return EncryptedOnboardingData(
            encryptedData: encryptedData.base64EncodedString(),
            userId: data.userId,
            timestamp: data.timestamp
        )
    }
    
    private func sendToBackend(_ encryptedData: EncryptedOnboardingData) async throws -> OnboardingResponse {
        guard let url = URL(string: "\(baseURL)/ine/onboarding") else {
            throw OnboardingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let requestBody = try JSONEncoder().encode(encryptedData)
        request.httpBody = requestBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OnboardingError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(OnboardingResponse.self, from: data)
        case 400:
            throw OnboardingError.badRequest
        case 401:
            throw OnboardingError.unauthorized
        case 409:
            throw OnboardingError.duplicateData
        case 500:
            throw OnboardingError.serverError
        default:
            throw OnboardingError.unknownError
        }
    }
    
    // MARK: - Verify Document
    func verifyDocument(_ documentNumber: String) async throws -> DocumentVerificationResponse {
        guard let url = URL(string: "\(baseURL)/ine/verify-document/\(documentNumber)") else {
            throw OnboardingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OnboardingError.invalidResponse
        }
        
        return try JSONDecoder().decode(DocumentVerificationResponse.self, from: data)
    }
    
    // MARK: - Get Onboarding Status
    func getOnboardingStatus(userId: String) async throws -> OnboardingStatus {
        guard let url = URL(string: "\(baseURL)/ine/status/\(userId)") else {
            throw OnboardingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OnboardingError.invalidResponse
        }
        
        return try JSONDecoder().decode(OnboardingStatus.self, from: data)
    }
}

// MARK: - Data Models
struct OnboardingData: Codable {
    let userId: String
    let firstName: String
    let lastName: String
    let middleName: String
    let dateOfBirth: String
    let documentNumber: String
    let nationality: String
    let address: String
    let occupation: String
    let incomeSource: String
    let timestamp: Date
    let status: OnboardingStatusType
}

struct EncryptedOnboardingData: Codable {
    let encryptedData: String
    let userId: String
    let timestamp: Date
}

struct OnboardingResponse: Codable {
    let success: Bool
    let message: String
    let onboardingId: String
    let status: OnboardingStatusType
    let nextSteps: [String]
}

struct DocumentVerificationResponse: Codable {
    let isValid: Bool
    let documentType: String
    let verificationLevel: String
    let warnings: [String]
}

struct OnboardingStatus: Codable {
    let status: OnboardingStatusType
    let progress: Int
    let completedSteps: [String]
    let pendingSteps: [String]
    let lastUpdated: Date
}

enum OnboardingStatusType: String, Codable, CaseIterable {
    case pending = "pending"
    case inReview = "in_review"
    case approved = "approved"
    case rejected = "rejected"
    case requiresAdditionalInfo = "requires_additional_info"
    
    var displayName: String {
        switch self {
        case .pending: return "Pendiente"
        case .inReview: return "En Revisión"
        case .approved: return "Aprobado"
        case .rejected: return "Rechazado"
        case .requiresAdditionalInfo: return "Requiere Información Adicional"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .inReview: return "blue"
        case .approved: return "green"
        case .rejected: return "red"
        case .requiresAdditionalInfo: return "yellow"
        }
    }
}

// MARK: - Error Handling
enum OnboardingError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case badRequest
    case unauthorized
    case duplicateData
    case serverError
    case unknownError
    case encryptionFailed
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .badRequest:
            return "Solicitud incorrecta"
        case .unauthorized:
            return "No autorizado"
        case .duplicateData:
            return "Datos duplicados"
        case .serverError:
            return "Error del servidor"
        case .unknownError:
            return "Error desconocido"
        case .encryptionFailed:
            return "Error al encriptar datos"
        case .decryptionFailed:
            return "Error al desencriptar datos"
        }
    }
}

// MARK: - Logging
class OnboardingLogger {
    static let shared = OnboardingLogger()
    
    private init() {}
    
    func logEvent(_ event: OnboardingEvent) {
        let timestamp = DateFormatter.iso8601.string(from: Date())
        let logMessage = "[\(timestamp)] \(event.description)"
        
        print(logMessage)
        
        // In production, send to logging service
        // sendToLoggingService(logMessage)
    }
}

enum OnboardingEvent {
    case consentGiven
    case cameraPermissionGranted
    case documentCaptured
    case ocrCompleted(success: Bool)
    case voiceConversationStarted
    case voiceConversationCompleted
    case dataSubmitted
    case dataApproved
    case dataRejected(reason: String)
    case errorOccurred(error: String)
    
    var description: String {
        switch self {
        case .consentGiven:
            return "User gave consent for camera and data processing"
        case .cameraPermissionGranted:
            return "Camera permission granted"
        case .documentCaptured:
            return "Document captured: Front"
        case .ocrCompleted(let success):
            return "OCR completed: \(success ? "success" : "failed")"
        case .voiceConversationStarted:
            return "Voice conversation started"
        case .voiceConversationCompleted:
            return "Voice conversation completed"
        case .dataSubmitted:
            return "Onboarding data submitted"
        case .dataApproved:
            return "Onboarding data approved"
        case .dataRejected(let reason):
            return "Onboarding data rejected: \(reason)"
        case .errorOccurred(let error):
            return "Error occurred: \(error)"
        }
    }
}

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}

