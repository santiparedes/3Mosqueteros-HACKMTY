import Foundation
import Supabase

// MARK: - Supabase Service
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        self.client = SupabaseConfig.shared.client
    }
    
    // MARK: - User Operations (using customers table)
    
    func createUser(_ user: User) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dbCustomer = DatabaseMappingService.mapToDatabaseCustomer(from: user)
            let response: DatabaseCustomer = try await client
                .from("customers")
                .insert(dbCustomer)
                .select()
                .single()
                .execute()
                .value
            
            return DatabaseMappingService.mapToUser(from: response)
        } catch {
            errorMessage = "Failed to create user: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getUser(id: String) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: DatabaseCustomer = try await client
                .from("customers")
                .select()
                .eq("customer_id", value: id)
                .single()
                .execute()
                .value
            
            return DatabaseMappingService.mapToUser(from: response)
        } catch {
            errorMessage = "Failed to get user: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateUser(_ user: User) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dbCustomer = DatabaseMappingService.mapToDatabaseCustomer(from: user)
            let response: DatabaseCustomer = try await client
                .from("customers")
                .update(dbCustomer)
                .eq("customer_id", value: user.id)
                .select()
                .single()
                .execute()
                .value
            
            return DatabaseMappingService.mapToUser(from: response)
        } catch {
            errorMessage = "Failed to update user: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Account Operations
    
    func getAccounts(for userId: String) async throws -> [Account] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: [DatabaseAccount] = try await client
                .from("accounts")
                .select()
                .eq("customer_id", value: userId)
                .execute()
                .value
            
            return response.map { DatabaseMappingService.mapToAccount(from: $0) }
        } catch {
            errorMessage = "Failed to get accounts: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getAccount(by accountId: String) async throws -> Account? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: DatabaseAccount? = try await client
                .from("accounts")
                .select()
                .eq("account_id", value: accountId)
                .single()
                .execute()
                .value
            
            return response.map { DatabaseMappingService.mapToAccount(from: $0) }
        } catch {
            errorMessage = "Failed to get account: \(error.localizedDescription)"
            return nil
        }
    }
    
    func createAccount(_ account: Account) async throws -> Account {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dbAccount = DatabaseMappingService.mapToDatabaseAccount(from: account)
            let response: DatabaseAccount = try await client
                .from("accounts")
                .insert(dbAccount)
                .select()
                .single()
                .execute()
                .value
            
            return DatabaseMappingService.mapToAccount(from: response)
        } catch {
            errorMessage = "Failed to create account: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateAccount(_ account: Account) async throws -> Account {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dbAccount = DatabaseMappingService.mapToDatabaseAccount(from: account)
            let response: DatabaseAccount = try await client
                .from("accounts")
                .update(dbAccount)
                .eq("account_id", value: account.id)
                .select()
                .single()
                .execute()
                .value
            
            return DatabaseMappingService.mapToAccount(from: response)
        } catch {
            errorMessage = "Failed to update account: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Card Operations
    
    func getCards(for userId: String) async throws -> [Card] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: [DatabaseCard] = try await client
                .from("cards")
                .select()
                .eq("customer_id", value: userId)
                .execute()
                .value
            
            return response.map { DatabaseMappingService.mapToCard(from: $0) }
        } catch {
            errorMessage = "Failed to get cards: \(error.localizedDescription)"
            throw error
        }
    }
    
    func createCard(_ card: Card) async throws -> Card {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: Card = try await client
                .from("cards")
                .insert(card)
                .select()
                .single()
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to create card: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateCard(_ card: Card) async throws -> Card {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: Card = try await client
                .from("cards")
                .update(card)
                .eq("id", value: card.id)
                .select()
                .single()
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to update card: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Transaction Operations
    
    func getTransactions(for accountId: String) async throws -> [Transaction] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dbTransactions: [DatabaseTransaction] = try await client
                .from("transactions")
                .select()
                .eq("account_id", value: accountId)
                .order("transaction_date", ascending: false)
                .execute()
                .value
            
            // Map DatabaseTransaction to Transaction
            let transactions = dbTransactions.map { DatabaseMappingService.mapToTransaction(from: $0) }
            return transactions
        } catch {
            errorMessage = "Failed to get transactions: \(error.localizedDescription)"
            throw error
        }
    }
    
    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: Transaction = try await client
                .from("transactions")
                .insert(transaction)
                .select()
                .single()
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to create transaction: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Credit Operations
    
    func getCreditOffers(for userId: String) async throws -> [CreditOffer] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: [CreditOffer] = try await client
                .from("credit_offers")
                .select()
                .eq("customer_id", value: userId)
                .order("generated_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to get credit offers: \(error.localizedDescription)"
            throw error
        }
    }
    
    func createCreditOffer(_ offer: CreditOffer) async throws -> CreditOffer {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: CreditOffer = try await client
                .from("credit_offers")
                .insert(offer)
                .select()
                .single()
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to create credit offer: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Customer Operations
    
    func getCustomers() async throws -> [DatabaseCustomer] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: [DatabaseCustomer] = try await client
                .from("customers")
                .select("*")
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to get customers: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Health Check
    
    func testConnection() async throws -> Bool {
        print("🔍 SupabaseService: Testing connection...")
        
        // First, let's test with a very simple query
        do {
            let response = try await client
                .from("customers")
                .select("*")
                .limit(1)
                .execute()
            
            print("📊 SupabaseService: Response status - \(response.response.statusCode)")
            
            let data = response.data
            let jsonString = String(data: data, encoding: .utf8) ?? "No data"
            print("📄 SupabaseService: Response content - \(jsonString)")
            
            // Try to decode as array of customer objects
            do {
                let customers: [DatabaseCustomer] = try JSONDecoder().decode([DatabaseCustomer].self, from: data)
                print("✅ SupabaseService: Connection successful! Found \(customers.count) customers")
                return true
            } catch {
                print("⚠️ SupabaseService: Could not decode customers, but connection works")
                print("📝 Decode error: \(error)")
                return true // Still consider it a successful connection
            }
            
        } catch {
            print("❌ SupabaseService: Connection failed - \(error)")
            print("📝 SupabaseService: Error details - \(error.localizedDescription)")
            errorMessage = "Supabase connection failed: \(error.localizedDescription)"
            return false
        }
    }
    
}
