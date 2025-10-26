import Foundation
import Combine

// MARK: - Credit Service
class CreditService: ObservableObject {
    static let shared = CreditService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentOffer: CreditOffer?
    @Published var creditHistory: [CreditHistory] = []
    
    private let baseURL = "http://localhost:8002" // Backend URL
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadMockCreditHistory()
    }
    
    // MARK: - Credit Scoring
    
    func scoreCredit(for user: DemoUser) async throws -> CreditOffer {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        // Create credit score request from user data
        let request = createCreditScoreRequest(from: user)
        
        // Make API call
        let response = try await performCreditScoreRequest(request)
        
        DispatchQueue.main.async {
            self.currentOffer = response.offer
        }
        
        return response.offer!
    }
    
    func scoreCreditWithCustomData(_ request: CreditScoreRequest) async throws -> CreditOffer {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        // Make API call
        let response = try await performCreditScoreRequest(request)
        
        DispatchQueue.main.async {
            self.currentOffer = response.offer
        }
        
        return response.offer!
    }
    
    private func performCreditScoreRequest(_ request: CreditScoreRequest) async throws -> CreditScoreResponse {
        guard let url = URL(string: "\(baseURL)/credit/score") else {
            throw CreditServiceError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CreditServiceError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorData = try? JSONDecoder().decode([String: String].self, from: data)
                let errorMessage = errorData?["detail"] ?? "Unknown error"
                throw CreditServiceError.serverError(errorMessage)
            }
            
            let creditResponse = try JSONDecoder().decode(CreditScoreResponse.self, from: data)
            
            guard creditResponse.success, let offer = creditResponse.offer else {
                throw CreditServiceError.scoringFailed(creditResponse.errorMessage ?? "Unknown error")
            }
            
            return creditResponse
            
        } catch {
            if error is CreditServiceError {
                throw error
            } else {
                throw CreditServiceError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createCreditScoreRequest(from user: DemoUser) -> CreditScoreRequest {
        // Extract financial data from user (this would come from user's banking data)
        let monthlyIncome = 4000.0 // Default, should come from user's account data
        let monthlySpending = 2500.0 // Default, should come from transaction data
        let currentDebt = 5000.0 // Default, should come from user's debt data
        
        return CreditScoreRequest(
            age: calculateAge(from: user), // Would need birth date in user model
            incomeMonthly: monthlyIncome,
            payrollStreak: 12, // Default, should come from payroll data
            payrollVariance: 0.1, // Default variance
            spendingMonthly: monthlySpending,
            spendingVar6m: 0.15, // Default spending variance
            currentDebt: currentDebt,
            dti: currentDebt / (monthlyIncome * 12), // Debt-to-income ratio
            utilization: 0.3, // Default credit utilization
            zone: "urban", // Default zone
            savingsRate: nil,
            financialHealthScore: nil
        )
    }
    
    private func calculateAge(from user: DemoUser) -> Int {
        // This is a placeholder - would need birth date in user model
        return 30 // Default age
    }
    
    // MARK: - Mock Data
    
    private func loadMockCreditHistory() {
        creditHistory = [
            CreditHistory(
                applicationId: "APP001",
                appliedDate: "2024-01-15T10:30:00Z",
                status: .approved,
                creditLimit: 10000.0,
                apr: 0.12,
                riskTier: "Prime",
                notes: "Excellent credit history"
            ),
            CreditHistory(
                applicationId: "APP002",
                appliedDate: "2023-08-20T14:15:00Z",
                status: .approved,
                creditLimit: 8000.0,
                apr: 0.15,
                riskTier: "Near Prime",
                notes: "Good credit standing"
            )
        ]
    }
    
    // MARK: - Health Check
    
    func checkServiceHealth() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/credit/health") else {
            throw CreditServiceError.invalidURL
        }
        
        let (_, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditServiceError.invalidResponse
        }
        
        return httpResponse.statusCode == 200
    }
    
    func getModelInfo() async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/credit/model-info") else {
            throw CreditServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CreditServiceError.serverError("Failed to get model info")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json ?? [:]
    }
}

// MARK: - Credit Service Errors
enum CreditServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(String)
    case serverError(String)
    case scoringFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for credit service"
        case .invalidResponse:
            return "Invalid response from credit service"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .scoringFailed(let message):
            return "Credit scoring failed: \(message)"
        }
    }
}

// MARK: - Credit Application Service
extension CreditService {
    
    func submitCreditApplication(_ application: CreditApplication) async throws -> String {
        // This would submit the application to the backend
        // For now, return a mock application ID
        return "APP\(Int.random(in: 1000...9999))"
    }
    
    func getApplicationStatus(_ applicationId: String) async throws -> CreditApplicationStatus {
        // This would check the application status from the backend
        // For now, return a mock status
        return .underReview
    }
    
    func getCreditHistory() async throws -> [CreditHistory] {
        // This would fetch credit history from the backend
        // For now, return mock data
        return creditHistory
    }
}
