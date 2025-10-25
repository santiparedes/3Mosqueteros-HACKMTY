import Foundation
import CoreLocation

// MARK: - Nessie API Service
class NessieAPI: ObservableObject {
    static let shared = NessieAPI()
    
    private let baseURL = "http://api.nessieisreal.com"
    private let apiKey = "2efca97355951ec13f6acfd0a8806a14"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Customer Operations
    func getCustomers() async throws -> [NessieCustomer] {
        return try await performRequest(
            endpoint: "/customers",
            method: "GET",
            body: nil as String?,
            responseType: [NessieCustomer].self
        )
    }
    
    func createCustomer(_ customer: NessieCustomerCreate) async throws -> NessieCustomerResponse {
        return try await performRequest(
            endpoint: "/customers",
            method: "POST",
            body: customer,
            responseType: NessieCustomerResponse.self
        )
    }
    
    // MARK: - Account Operations
    func getCustomerAccounts(customerId: String) async throws -> [NessieAccount] {
        return try await performRequest(
            endpoint: "/customers/\(customerId)/accounts",
            method: "GET",
            body: nil as String?,
            responseType: [NessieAccount].self
        )
    }
    
    func createAccount(customerId: String, account: NessieAccountCreate) async throws -> NessieAccountResponse {
        return try await performRequest(
            endpoint: "/customers/\(customerId)/accounts",
            method: "POST",
            body: account,
            responseType: NessieAccountResponse.self
        )
    }
    
    func getAccount(accountId: String) async throws -> NessieAccount {
        return try await performRequest(
            endpoint: "/accounts/\(accountId)",
            method: "GET",
            body: nil as String?,
            responseType: NessieAccount.self
        )
    }
    
    // MARK: - Transaction Operations
    func getAccountTransactions(accountId: String) async throws -> [NessieTransaction] {
        return try await performRequest(
            endpoint: "/accounts/\(accountId)/transactions",
            method: "GET",
            body: nil as String?,
            responseType: [NessieTransaction].self
        )
    }
    
    func createTransaction(accountId: String, transaction: NessieTransactionCreate) async throws -> NessieTransactionResponse {
        return try await performRequest(
            endpoint: "/accounts/\(accountId)/transactions",
            method: "POST",
            body: transaction,
            responseType: NessieTransactionResponse.self
        )
    }
    
    // MARK: - Location Services
    func getATMs(latitude: Double, longitude: Double, radius: Int = 10) async throws -> [NessieATM] {
        return try await performRequest(
            endpoint: "/atms?lat=\(latitude)&lng=\(longitude)&rad=\(radius)",
            method: "GET",
            body: nil as String?,
            responseType: [NessieATM].self
        )
    }
    
    func getBranches(latitude: Double, longitude: Double, radius: Int = 10) async throws -> [NessieBranch] {
        return try await performRequest(
            endpoint: "/branches?lat=\(latitude)&lng=\(longitude)&rad=\(radius)",
            method: "GET",
            body: nil as String?,
            responseType: [NessieBranch].self
        )
    }
    
    // MARK: - Generic Request Handler
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: String,
        body: T?,
        responseType: U.Type
    ) async throws -> U {
        guard let url = URL(string: baseURL + endpoint + "?key=\(apiKey)") else {
            throw NessieAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NessieAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NessieAPIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(responseType, from: data)
    }
}

// MARK: - Nessie API Errors
enum NessieAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network connection error"
        }
    }
}

// MARK: - Nessie Data Models
struct NessieCustomer: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let address: NessieAddress
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case address
    }
}

struct NessieAddress: Codable {
    let streetNumber: String
    let streetName: String
    let city: String
    let state: String
    let zip: String
    
    enum CodingKeys: String, CodingKey {
        case streetNumber = "street_number"
        case streetName = "street_name"
        case city, state, zip
    }
}

struct NessieCustomerCreate: Codable {
    let firstName: String
    let lastName: String
    let address: NessieAddress
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case address
    }
}

struct NessieCustomerResponse: Codable {
    let objectCreated: NessieCustomer
    
    enum CodingKeys: String, CodingKey {
        case objectCreated = "objectCreated"
    }
}

struct NessieAccount: Codable, Identifiable {
    let id: String
    let type: String
    let nickname: String
    let rewards: Int
    let balance: Double
    let accountNumber: String
    let customerId: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type, nickname, rewards, balance
        case accountNumber = "account_number"
        case customerId = "customer_id"
    }
}

struct NessieAccountCreate: Codable {
    let type: String
    let nickname: String
    let rewards: Int
    let balance: Double
}

struct NessieAccountResponse: Codable {
    let objectCreated: NessieAccount
    
    enum CodingKeys: String, CodingKey {
        case objectCreated = "objectCreated"
    }
}

struct NessieTransaction: Codable, Identifiable {
    let id: String
    let type: String
    let transactionDate: String
    let status: String
    let medium: String
    let payeeId: String
    let amount: Double
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case transactionDate = "transaction_date"
        case status, medium
        case payeeId = "payee_id"
        case amount, description
    }
}

struct NessieTransactionCreate: Codable {
    let medium: String
    let payeeId: String
    let amount: Double
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case medium
        case payeeId = "payee_id"
        case amount, description
    }
}

struct NessieTransactionResponse: Codable {
    let objectCreated: NessieTransaction
    
    enum CodingKeys: String, CodingKey {
        case objectCreated = "objectCreated"
    }
}

struct NessieATM: Codable, Identifiable {
    let id: String
    let name: String
    let languageList: [String]
    let accessible: Bool
    let amount: [Int]
    let address: NessieATMAddress
    let geocode: NessieGeocode
    let distance: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case languageList = "language_list"
        case accessible, amount, address, geocode, distance
    }
}

struct NessieATMAddress: Codable {
    let streetNumber: String
    let streetName: String
    let city: String
    let state: String
    let zip: String
    
    enum CodingKeys: String, CodingKey {
        case streetNumber = "street_number"
        case streetName = "street_name"
        case city, state, zip
    }
}

struct NessieBranch: Codable, Identifiable {
    let id: String
    let name: String
    let hours: [String]
    let phoneNumber: String
    let address: NessieATMAddress
    let geocode: NessieGeocode
    let distance: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, hours
        case phoneNumber = "phone_number"
        case address, geocode, distance
    }
}

struct NessieGeocode: Codable {
    let lat: Double
    let lng: Double
}

// MARK: - Quantum-Nessie Bridge Models
struct QuantumNessieWallet: Codable {
    let quantumWalletId: String
    let nessieCustomerId: String
    let nessieAccountId: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case quantumWalletId = "quantum_wallet_id"
        case nessieCustomerId = "nessie_customer_id"
        case nessieAccountId = "nessie_account_id"
        case userId = "user_id"
    }
}

struct QuantumNessiePayment: Codable {
    let fromQuantumWallet: String
    let toQuantumWallet: String
    let amount: Double
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case fromQuantumWallet = "from_quantum_wallet"
        case toQuantumWallet = "to_quantum_wallet"
        case amount, description
    }
}

struct QuantumNessiePaymentResponse: Codable {
    let quantumTxId: String
    let nessieTxId: String
    let amount: Double
    let status: String
    let description: String
    let quantumSignature: String
    let merkleProof: String
    
    enum CodingKeys: String, CodingKey {
        case quantumTxId = "quantum_tx_id"
        case nessieTxId = "nessie_tx_id"
        case amount, status, description
        case quantumSignature = "quantum_signature"
        case merkleProof = "merkle_proof"
    }
}
