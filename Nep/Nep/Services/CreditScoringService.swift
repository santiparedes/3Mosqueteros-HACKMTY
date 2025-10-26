import Foundation
import Combine

// MARK: - Credit Scoring Service
class CreditScoringService: ObservableObject {
    static let shared = CreditScoringService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentCreditScore: CreditScoreResult?
    @Published var lastScoredAccountId: String?
    
    private let baseURL = APIConfig.creditScoringBaseURL
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Credit Scoring Methods
    
    /// Score credit by account ID (automatic endpoint from Supabase data)
    func scoreCreditByAccount(accountId: String) async throws -> CreditScoreResult {
        print("🔵 CreditScoringService: Starting credit scoring for account: \(accountId)")
        
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard let url = URL(string: "\(baseURL)/credit/score-by-account/\(accountId)") else {
            print("❌ CreditScoringService: Invalid URL")
            throw CreditScoringError.invalidURL
        }
        
        print("📡 CreditScoringService: Sending request to \(url.absoluteString)")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            print("📥 CreditScoringService: Response received")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ CreditScoringService: Invalid HTTP response")
                throw CreditScoringError.invalidResponse
            }
            
            print("📊 CreditScoringService: Status code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let errorData = try? JSONDecoder().decode([String: String].self, from: data)
                let errorMessage = errorData?["detail"] ?? "Unknown error"
                print("❌ CreditScoringService: Server error - \(errorMessage)")
                throw CreditScoringError.serverError(errorMessage)
            }
            
            let creditResponse = try JSONDecoder().decode(CreditScoringResponse.self, from: data)
            print("✅ CreditScoringService: Response decoded successfully")
            
            guard let offer = creditResponse.offer else {
                print("❌ CreditScoringService: No offer in response")
                throw CreditScoringError.scoringFailed("No credit offer received")
            }
            
            let result = CreditScoreResult(
                accountId: accountId,
                offer: offer,
                modelVersion: creditResponse.modelVersion,
                scoredAt: Date()
            )
            
            print("🎉 CreditScoringService: Scoring successful!")
            print("   - Risk Tier: \(offer.riskTier)")
            print("   - Credit Limit: $\(offer.creditLimit)")
            print("   - APR: \(offer.apr * 100)%")
            print("   - PD90 Score: \(offer.pd90Score)")
            
            DispatchQueue.main.async {
                self.currentCreditScore = result
                self.lastScoredAccountId = accountId
            }
            
            return result
            
        } catch {
            print("❌ CreditScoringService: Error in scoreCreditByAccount - \(error.localizedDescription)")
            if error is CreditScoringError {
                throw error
            } else {
                throw CreditScoringError.networkError(error.localizedDescription)
            }
        }
    }
    
    /// Extract features from Supabase for an account
    func extractAccountFeatures(accountId: String) async throws -> AccountFeatures {
        print("🔵 CreditScoringService: Extracting features for account: \(accountId)")
        
        guard let url = URL(string: "\(baseURL)/credit/account/\(accountId)/features") else {
            throw CreditScoringError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditScoringError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorData = try? JSONDecoder().decode([String: String].self, from: data)
            let errorMessage = errorData?["detail"] ?? "Unknown error"
            throw CreditScoringError.serverError(errorMessage)
        }
        
        let features = try JSONDecoder().decode(AccountFeatures.self, from: data)
        return features
    }
    
    /// Manual credit scoring with custom data
    func scoreCreditManually(_ request: CreditScoreRequest) async throws -> CreditScoreResult {
        print("🔵 CreditScoringService: Manual credit scoring")
        
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard let url = URL(string: "\(baseURL)/credit/score") else {
            throw CreditScoringError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CreditScoringError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorData = try? JSONDecoder().decode([String: String].self, from: data)
                let errorMessage = errorData?["detail"] ?? "Unknown error"
                throw CreditScoringError.serverError(errorMessage)
            }
            
            let creditResponse = try JSONDecoder().decode(CreditScoringResponse.self, from: data)
            
            guard let offer = creditResponse.offer else {
                throw CreditScoringError.scoringFailed("No credit offer received")
            }
            
            let result = CreditScoreResult(
                accountId: "manual",
                offer: offer,
                modelVersion: creditResponse.modelVersion,
                scoredAt: Date()
            )
            
            DispatchQueue.main.async {
                self.currentCreditScore = result
            }
            
            return result
            
        } catch {
            if error is CreditScoringError {
                throw error
            } else {
                throw CreditScoringError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Health Check
    
    func checkServiceHealth() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/credit/health") else {
            throw CreditScoringError.invalidURL
        }
        
        let (_, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditScoringError.invalidResponse
        }
        
        return httpResponse.statusCode == 200
    }
    
    // MARK: - Helper Methods
    
    func hasValidScore(for accountId: String) -> Bool {
        return currentCreditScore?.accountId == accountId && 
               currentCreditScore?.scoredAt.timeIntervalSinceNow > -3600 // Valid for 1 hour
    }
    
    func clearScore() {
        DispatchQueue.main.async {
            self.currentCreditScore = nil
            self.lastScoredAccountId = nil
        }
    }
}

// MARK: - Credit Scoring Models

struct CreditScoringResponse: Codable {
    let offer: CreditOffer?
    let modelVersion: String
    
    enum CodingKeys: String, CodingKey {
        case offer
        case modelVersion = "model_version"
    }
}

struct CreditScoreResult {
    let accountId: String
    let offer: CreditOffer
    let modelVersion: String
    let scoredAt: Date
}

struct AccountFeatures: Codable {
    let accountId: String
    let customerId: String
    let features: [String: Double]
    let metadata: FeatureMetadata
    
    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case customerId = "customer_id"
        case features
        case metadata
    }
}

struct FeatureMetadata: Codable {
    let dataQualityScore: Double
    let monthsOfHistory: Int
    let qualityStatus: String
    
    enum CodingKeys: String, CodingKey {
        case dataQualityScore = "data_quality_score"
        case monthsOfHistory = "months_of_history"
        case qualityStatus = "quality_status"
    }
}

// MARK: - Credit Scoring Errors
enum CreditScoringError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(String)
    case serverError(String)
    case scoringFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for credit scoring service"
        case .invalidResponse:
            return "Invalid response from credit scoring service"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .scoringFailed(let message):
            return "Credit scoring failed: \(message)"
        }
    }
}
