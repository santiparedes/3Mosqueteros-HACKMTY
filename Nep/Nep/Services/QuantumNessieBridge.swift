import Foundation
import CoreLocation

// MARK: - Quantum-Nessie Bridge Service
class QuantumNessieBridge: ObservableObject {
    static let shared = QuantumNessieBridge()
    
    private let quantumAPI = QuantumAPI.shared
    private let nessieAPI = NessieAPI.shared
    private let baseURL = "http://localhost:8000"
    private let session = URLSession.shared
    
    @Published var linkedWallets: [QuantumNessieWallet] = []
    @Published var nessieCustomers: [NessieCustomer] = []
    @Published var nessieAccounts: [NessieAccount] = []
    @Published var nearbyATMs: [NessieATM] = []
    @Published var nearbyBranches: [NessieBranch] = []
    
    private init() {}
    
    // MARK: - Customer Management
    func loadNessieCustomers() async {
        do {
            let customers = try await nessieAPI.getCustomers()
            await MainActor.run {
                self.nessieCustomers = customers
            }
        } catch {
            print("Failed to load Nessie customers: \(error)")
        }
    }
    
    func createNessieCustomer(firstName: String, lastName: String, address: NessieAddress) async throws -> NessieCustomer {
        let customerCreate = NessieCustomerCreate(
            firstName: firstName,
            lastName: lastName,
            address: address
        )
        let response = try await nessieAPI.createCustomer(customerCreate)
        await loadNessieCustomers() // Refresh the list
        return response.objectCreated
    }
    
    // MARK: - Account Management
    func loadNessieAccounts(for customerId: String) async {
        do {
            let accounts = try await nessieAPI.getCustomerAccounts(customerId: customerId)
            await MainActor.run {
                self.nessieAccounts = accounts
            }
        } catch {
            print("Failed to load Nessie accounts: \(error)")
        }
    }
    
    func createNessieAccount(customerId: String, type: String, nickname: String, balance: Double) async throws -> NessieAccount {
        let accountCreate = NessieAccountCreate(
            type: type,
            nickname: nickname,
            rewards: 0,
            balance: balance
        )
        let response = try await nessieAPI.createAccount(customerId: customerId, account: accountCreate)
        await loadNessieAccounts(for: customerId) // Refresh the list
        return response.objectCreated
    }
    
    // MARK: - Quantum-Nessie Wallet Linking
    func linkQuantumWalletToNessie(
        quantumWalletId: String,
        nessieCustomerId: String,
        nessieAccountId: String,
        userId: String
    ) async throws -> QuantumNessieWallet {
        let wallet = QuantumNessieWallet(
            quantumWalletId: quantumWalletId,
            nessieCustomerId: nessieCustomerId,
            nessieAccountId: nessieAccountId,
            userId: userId
        )
        
        // Store locally
        await MainActor.run {
            self.linkedWallets.append(wallet)
        }
        
        return wallet
    }
    
    // MARK: - Quantum Payment Processing
    func processQuantumPayment(
        fromQuantumWallet: String,
        toQuantumWallet: String,
        amount: Double,
        description: String = "Quantum Payment via Nessie"
    ) async throws -> QuantumNessiePaymentResponse {
        // Step 1: Prepare quantum transaction
        let prepareResponse = try await quantumAPI.prepareTransaction(
            walletId: fromQuantumWallet,
            to: toQuantumWallet,
            amount: amount,
            currency: "USD"
        )
        
        // Step 2: Sign with quantum signature (using Ed25519 for demo)
        let signer = Ed25519QuantumSigner()
        let payloadData = try JSONEncoder().encode(prepareResponse.payload)
        let (publicKey, privateKey) = signer.generateKeyPair()
        let signature = try signer.sign(payload: payloadData, privateKey: privateKey)
        
        // Step 3: Submit quantum transaction
        let submitResponse = try await quantumAPI.submitTransaction(
            payload: prepareResponse.payload,
            signature: signature,
            publicKey: publicKey
        )
        
        // Step 4: Create corresponding Nessie transaction
        if let linkedWallet = linkedWallets.first(where: { $0.quantumWalletId == fromQuantumWallet }) {
            let nessieTransaction = NessieTransactionCreate(
                medium: "balance",
                payeeId: toQuantumWallet,
                amount: amount,
                description: description
            )
            
            let _ = try await nessieAPI.createTransaction(
                accountId: linkedWallet.nessieAccountId,
                transaction: nessieTransaction
            )
        }
        
        return QuantumNessiePaymentResponse(
            quantumTxId: submitResponse.txId,
            nessieTxId: "ntx_\(Int.random(in: 100000...999999))",
            amount: amount,
            status: "processed",
            description: description,
            quantumSignature: signature,
            merkleProof: "generated"
        )
    }
    
    // MARK: - Location Services
    func findNearbyATMs(location: CLLocation, radius: Int = 10) async {
        do {
            let atms = try await nessieAPI.getATMs(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radius: radius
            )
            await MainActor.run {
                self.nearbyATMs = atms
            }
        } catch {
            print("Failed to find nearby ATMs: \(error)")
        }
    }
    
    func findNearbyBranches(location: CLLocation, radius: Int = 10) async {
        do {
            let branches = try await nessieAPI.getBranches(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radius: radius
            )
            await MainActor.run {
                self.nearbyBranches = branches
            }
        } catch {
            print("Failed to find nearby branches: \(error)")
        }
    }
    
    // MARK: - Balance and Transaction History
    func getQuantumWalletBalance(quantumWalletId: String) async throws -> Double {
        // Find linked Nessie account
        guard let linkedWallet = linkedWallets.first(where: { $0.quantumWalletId == quantumWalletId }) else {
            throw QuantumNessieBridgeError.walletNotLinked
        }
        
        let account = try await nessieAPI.getAccount(accountId: linkedWallet.nessieAccountId)
        return account.balance
    }
    
    func getQuantumWalletTransactions(quantumWalletId: String) async throws -> [NessieTransaction] {
        // Find linked Nessie account
        guard let linkedWallet = linkedWallets.first(where: { $0.quantumWalletId == quantumWalletId }) else {
            throw QuantumNessieBridgeError.walletNotLinked
        }
        
        return try await nessieAPI.getAccountTransactions(accountId: linkedWallet.nessieAccountId)
    }
    
    // MARK: - Real Banking Operations
    func simulateRealBankingOperations() async {
        // This function simulates real banking operations using Nessie data
        // and processes them through the quantum wallet system
        
        do {
            // Load real customers and accounts from Nessie
            await loadNessieCustomers()
            
            // For each customer, create a quantum wallet
            for customer in nessieCustomers {
                let quantumWallet = try await quantumAPI.createWallet(
                    userId: customer.id,
                    pubkeyPqc: "demo_pqc_key_\(customer.id)"
                )
                
                // Load their Nessie accounts
                await loadNessieAccounts(for: customer.id)
                
                // Link quantum wallet to their first Nessie account
                if let firstAccount = nessieAccounts.first {
                    let _ = try await linkQuantumWalletToNessie(
                        quantumWalletId: quantumWallet.walletId,
                        nessieCustomerId: customer.id,
                        nessieAccountId: firstAccount.id,
                        userId: customer.id
                    )
                }
            }
            
            print("✅ Successfully linked \(linkedWallets.count) quantum wallets to Nessie accounts")
            
        } catch {
            print("❌ Failed to simulate real banking operations: \(error)")
        }
    }
}

// MARK: - Bridge Errors
enum QuantumNessieBridgeError: Error, LocalizedError {
    case walletNotLinked
    case invalidAccount
    case transactionFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .walletNotLinked:
            return "Quantum wallet is not linked to a Nessie account"
        case .invalidAccount:
            return "Invalid Nessie account"
        case .transactionFailed:
            return "Transaction processing failed"
        case .networkError:
            return "Network connection error"
        }
    }
}

// MARK: - Mock Data for Testing
extension QuantumNessieBridge {
    func loadMockData() async {
        // Create mock Nessie customers
        let mockCustomers = [
            NessieCustomer(
                id: "customer_001",
                firstName: "Alice",
                lastName: "Johnson",
                address: NessieAddress(
                    streetNumber: "123",
                    streetName: "Main St",
                    city: "Austin",
                    state: "TX",
                    zip: "78701"
                )
            ),
            NessieCustomer(
                id: "customer_002",
                firstName: "Bob",
                lastName: "Smith",
                address: NessieAddress(
                    streetNumber: "456",
                    streetName: "Oak Ave",
                    city: "Austin",
                    state: "TX",
                    zip: "78702"
                )
            )
        ]
        
        await MainActor.run {
            self.nessieCustomers = mockCustomers
        }
        
        // Create mock accounts
        let mockAccounts = [
            NessieAccount(
                id: "account_001",
                type: "Checking",
                nickname: "Alice's Quantum Wallet",
                rewards: 0,
                balance: 2500.0,
                accountNumber: "1234567890",
                customerId: "customer_001"
            ),
            NessieAccount(
                id: "account_002",
                type: "Savings",
                nickname: "Bob's Quantum Wallet",
                rewards: 0,
                balance: 1800.0,
                accountNumber: "0987654321",
                customerId: "customer_002"
            )
        ]
        
        await MainActor.run {
            self.nessieAccounts = mockAccounts
        }
        
        print("✅ Mock data loaded successfully")
    }
}
