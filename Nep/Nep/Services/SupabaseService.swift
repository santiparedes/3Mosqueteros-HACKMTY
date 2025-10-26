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
    
    // MARK: - User Operations
    
    func createUser(_ user: User) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: User = try await client
                .from("users")
                .insert(user)
                .select()
                .single()
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to create user: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getUser(id: String) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: User = try await client
                .from("users")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to get user: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateUser(_ user: User) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: User = try await client
                .from("users")
                .update(user)
                .eq("id", value: user.id)
                .select()
                .single()
                .execute()
                .value
            
            return response
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
            let response: [Account] = try await client
                .from("accounts")
                .select()
                .eq("customer_id", value: userId)
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to get accounts: \(error.localizedDescription)"
            throw error
        }
    }
    
    func createAccount(_ account: Account) async throws -> Account {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: Account = try await client
                .from("accounts")
                .insert(account)
                .select()
                .single()
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to create account: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateAccount(_ account: Account) async throws -> Account {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: Account = try await client
                .from("accounts")
                .update(account)
                .eq("id", value: account.id)
                .select()
                .single()
                .execute()
                .value
            
            return response
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
            let response: [Card] = try await client
                .from("cards")
                .select()
                .eq("customer_id", value: userId)
                .execute()
                .value
            
            return response
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
            let response: [Transaction] = try await client
                .from("transactions")
                .select()
                .eq("account_id", value: accountId)
                .order("transaction_date", ascending: false)
                .execute()
                .value
            
            return response
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
    
    // MARK: - Health Check
    
    func testConnection() async throws -> Bool {
        print("🔍 SupabaseService: Testing connection...")
        
        do {
            let _: [String] = try await client
                .from("users")
                .select("id")
                .limit(1)
                .execute()
                .value
            
            print("✅ SupabaseService: Connection successful!")
            return true
        } catch {
            print("❌ SupabaseService: Connection failed - \(error)")
            print("📝 SupabaseService: Error details - \(error.localizedDescription)")
            errorMessage = "Supabase connection failed: \(error.localizedDescription)"
            return false
        }
    }
}
