import Foundation
import Combine

class NessieAPI: ObservableObject {
    static let shared = NessieAPI()
    
    private let baseURL = Config.nessieBaseURL
    private let apiKey = Config.nessieAPIKey
    
    private init() {}
    
    // MARK: - Customer Management
    func getCustomers() async throws -> [User] {
        let url = URL(string: "\(baseURL)/customers?key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([User].self, from: data)
    }
    
    func getCustomer(by id: String) async throws -> User {
        let url = URL(string: "\(baseURL)/customers/\(id)?key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    func createCustomer(_ customer: User) async throws -> User {
        let url = URL(string: "\(baseURL)/customers?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(customer)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    // MARK: - Account Management
    func getAccounts(for customerId: String) async throws -> [Account] {
        let url = URL(string: "\(baseURL)/customers/\(customerId)/accounts?key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Account].self, from: data)
    }
    
    func getAccount(by id: String) async throws -> Account {
        let url = URL(string: "\(baseURL)/accounts/\(id)?key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Account.self, from: data)
    }
    
    func createAccount(for customerId: String, account: Account) async throws -> Account {
        let url = URL(string: "\(baseURL)/customers/\(customerId)/accounts?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(account)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Account.self, from: data)
    }
    
    // MARK: - Transaction Management
    func getTransactions(for accountId: String) async throws -> [Transaction] {
        let url = URL(string: "\(baseURL)/accounts/\(accountId)/transactions?key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Transaction].self, from: data)
    }
    
    func createTransaction(for accountId: String, transaction: Transaction) async throws -> Transaction {
        let url = URL(string: "\(baseURL)/accounts/\(accountId)/transactions?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(transaction)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Transaction.self, from: data)
    }
    
    // MARK: - Card Management
    func getCards(for customerId: String) async throws -> [Card] {
        let url = URL(string: "\(baseURL)/customers/\(customerId)/cards?key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Card].self, from: data)
    }
    
    func createCard(for customerId: String, card: Card) async throws -> Card {
        let url = URL(string: "\(baseURL)/customers/\(customerId)/cards?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(card)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Card.self, from: data)
    }
    
    // MARK: - Utility Methods
    func formatCurrency(_ amount: Double, currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    // MARK: - Error Handling
    enum NessieError: Error, LocalizedError {
        case invalidURL
        case noData
        case decodingError
        case networkError(Error)
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .noData:
                return "No data received"
            case .decodingError:
                return "Failed to decode response"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .apiError(let message):
                return "API error: \(message)"
            }
        }
    }
    
    // MARK: - Request Helper
    private func makeRequest<T: Codable>(url: URL, method: String = "GET", body: Data? = nil, responseType: T.Type) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NessieError.networkError(URLError(.badServerResponse))
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NessieError.apiError("HTTP \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            if error is NessieError {
                throw error
            } else {
                throw NessieError.networkError(error)
            }
        }
    }
}
