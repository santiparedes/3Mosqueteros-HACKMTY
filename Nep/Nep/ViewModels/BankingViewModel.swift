import Foundation
import Combine

class BankingViewModel: ObservableObject {
    @Published var user: User?
    @Published var accounts: [Account] = []
    @Published var transactions: [Transaction] = []
    @Published var cards: [Card] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentAccountId: String = APIConfig.testAccountId // Track current account
    
    private let nessieAPI = NessieAPI.shared
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDataFromSupabase()
    }
    
    // MARK: - Data Loading
    func loadUserData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Use the current demo user from UserManager
                let userManager = UserManager.shared
                let currentDemoUser = userManager.currentUser!
                
                // Get Nessie customer for this demo user
                let firstCustomer = try await userManager.getNessieCustomerForDemoUser(currentDemoUser)
                
                if let customer = firstCustomer {
                    // Convert NessieCustomer to User
                    let user = User(
                        id: customer.id,
                        firstName: customer.firstName,
                        lastName: customer.lastName,
                        email: currentDemoUser.email,
                        phone: currentDemoUser.phone,
                        address: Address(
                            streetNumber: customer.address.streetNumber,
                            streetName: customer.address.streetName,
                            city: customer.address.city,
                            state: customer.address.state,
                            zip: customer.address.zip
                        ),
                        accounts: nil,
                        cards: nil
                    )
                    
                    await MainActor.run {
                        self.user = user
                    }
                    
                    // Load accounts for the user
                    let userAccounts = try await nessieAPI.getCustomerAccounts(customerId: customer.id)
                    // Convert NessieAccount to Account
                    let accounts = userAccounts.map { nessieAccount in
                        Account(
                            id: nessieAccount.id,
                            nickname: nessieAccount.nickname,
                            rewards: nessieAccount.rewards,
                            balance: nessieAccount.balance,
                            accountNumber: nessieAccount.accountNumber,
                            type: nessieAccount.type,
                            customerId: nessieAccount.customerId
                        )
                    }
                    await MainActor.run {
                        self.accounts = accounts
                    }
                    
                    // Load transactions for the first account
                    if let firstAccount = userAccounts.first {
                        let accountTransactions = try await nessieAPI.getAccountTransactions(accountId: firstAccount.id)
                        // Convert NessieTransaction to Transaction
                        let transactions = accountTransactions.map { nessieTx in
                            Transaction(
                                transaction_id: nessieTx.id,
                                account_id: firstAccount.id,
                                transaction_type: nessieTx.type,
                                transaction_date: nessieTx.transactionDate,
                                status: nessieTx.status,
                                medium: nessieTx.medium,
                                payee_id: nessieTx.payeeId,
                                amount: nessieTx.amount,
                                description: nessieTx.description
                            )
                        }
                        await MainActor.run {
                            self.transactions = transactions
                        }
                    }
                    
                    // Convert Nessie accounts to cards
                    let cards = userAccounts.map { account in
                        Card(
                            id: account.id,
                            nickname: account.nickname,
                            type: account.type,
                            accountId: account.id,
                            customerId: account.customerId,
                            cardNumber: generateCardNumber(from: account.id),
                            expirationDate: "12/26",
                            cvc: "123",
                            isActive: true
                        )
                    }
                    
                    await MainActor.run {
                        self.cards = cards
                    }
                }
                
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadMockData() {
        // Load mock data for development
        user = MockData.sampleUser
        accounts = MockData.sampleAccounts
        transactions = MockData.sampleTransactions
        cards = MockData.sampleCards
    }
    
    func loadDataFromSupabase() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔄 BankingViewModel: Loading data from Supabase...")
                
                // Get the account by current account ID
                print("📊 BankingViewModel: Looking for account ID: \(currentAccountId)")
                
                if let account = try await supabaseService.getAccount(by: currentAccountId) {
                    print("💳 BankingViewModel: Found account - \(account.nickname)")
                    
                    // Get the customer ID from the account
                    let customerId = account.customerId
                    print("👤 BankingViewModel: Found customer ID: \(customerId)")
                    
                    // Get the customer details
                    let customer = try await supabaseService.getUser(id: customerId)
                    print("👤 BankingViewModel: Found customer - \(customer.firstName) \(customer.lastName)")
                    
                    // Load all accounts for this customer
                    let customerAccounts = try await supabaseService.getAccounts(for: customerId)
                    print("💳 BankingViewModel: Found \(customerAccounts.count) accounts")
                    
                    // Debug: Print account details
                    for (index, account) in customerAccounts.enumerated() {
                        print("   Account \(index + 1): \(account.type) - $\(account.balance) (\(account.nickname))")
                    }
                    
                    // Load cards for this customer
                    let cards = try await supabaseService.getCards(for: customerId)
                    print("💳 BankingViewModel: Found \(cards.count) cards")
                    
                    // Load transactions for the target account
                    let transactions = try await supabaseService.getTransactions(for: currentAccountId)
                    print("📊 BankingViewModel: Found \(transactions.count) transactions")
                    
                    await MainActor.run {
                        self.user = customer
                        self.accounts = customerAccounts
                        self.cards = cards
                        self.transactions = transactions
                        self.isLoading = false
                        print("✅ BankingViewModel: Data loaded successfully from Supabase!")
                    }
                } else {
                    print("⚠️ BankingViewModel: Account \(currentAccountId) not found, falling back to mock data")
                    await MainActor.run {
                        self.loadMockData()
                        self.isLoading = false
                    }
                }
                
            } catch {
                print("❌ BankingViewModel: Failed to load from Supabase - \(error)")
                await MainActor.run {
                    self.loadMockData() // Fallback to mock data
                    self.isLoading = false
                    self.errorMessage = "Failed to load data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Transaction Updates
    func refreshAfterTransaction() {
        print("🔄 BankingViewModel: Refreshing data after transaction...")
        loadDataFromSupabase()
    }
    
    // MARK: - Account Switching
    func switchToAccount(accountId: String) {
        print("🔄 BankingViewModel: Switching to account: \(accountId)")
        currentAccountId = accountId
        loadDataFromSupabase()
    }
    
    func switchToSofia() {
        print("🔄 BankingViewModel: Switching to Sofia Mendez account")
        switchToAccount(accountId: APIConfig.sofiaAccountId)
    }
    
    func switchToMaria() {
        print("🔄 BankingViewModel: Switching to Maria account")
        switchToAccount(accountId: APIConfig.testAccountId)
    }
    
    // MARK: - Account Operations
    func getTotalBalance() -> Double {
        // Only include positive balances (checking/savings accounts)
        // Credit card balances are negative and represent debt, not available funds
        let totalBalance = accounts.reduce(0) { total, account in
            if account.type.lowercased().contains("credit") {
                // For credit cards, we don't add the negative balance to total available funds
                print("💰 Total Balance: Excluding credit card balance: $\(account.balance)")
                return total
            } else {
                // For checking/savings accounts, add the positive balance
                print("💰 Total Balance: Including \(account.type) balance: $\(account.balance)")
                return total + account.balance
            }
        }
        print("💰 Total Balance: Final calculated balance: $\(totalBalance)")
        return totalBalance
    }
    
    func getAccountBalance(for accountId: String) -> Double {
        return accounts.first { $0.id == accountId }?.balance ?? 0.0
    }
    
    // MARK: - Transaction Operations
    func addTransaction(_ transaction: Transaction) {
        transactions.insert(transaction, at: 0)
    }
    
    func getRecentTransactions(limit: Int = 5) -> [Transaction] {
        return Array(transactions.prefix(limit))
    }
    
    // MARK: - Card Operations
    func getActiveCard() -> Card? {
        return cards.first { $0.isActive }
    }
    
    func getCreditCard() -> Card? {
        return cards.first { $0.type.lowercased() == "credit" }
    }
    
    // MARK: - Card Generation
    func generateCardsFromAccounts(_ accounts: [Account]) -> [Card] {
        let cards = accounts.map { account in
            let cardNumber = generateCardNumber(from: account.id)
            let cardType = account.type.lowercased().contains("credit") ? "Credit" : "Debit"
            
            print("💳 Generated \(cardType) card for \(account.type) account: \(cardNumber)")
            
            return Card(
                id: account.id,
                nickname: account.nickname,
                type: cardType,
                accountId: account.id,
                customerId: account.customerId,
                cardNumber: cardNumber,
                expirationDate: "12/26",
                cvc: "123",
                isActive: true
            )
        }
        
        print("💳 Total cards generated: \(cards.count)")
        return cards
    }
    
    private func generateCardNumber(from accountId: String) -> String {
        // Generate a realistic card number from account ID
        let hash = accountId.hash
        let lastFour = String(abs(hash) % 10000).padding(toLength: 4, withPad: "0", startingAt: 0)
        return "5555 1234 5678 \(lastFour)"
    }
    
    func createNewCard(for accountId: String) {
        let newCard = Card(
            id: UUID().uuidString,
            nickname: "New Card",
            type: "Debit",
            accountId: accountId,
            customerId: user?.id ?? "",
            cardNumber: generateCardNumber(),
            expirationDate: generateExpirationDate(),
            cvc: generateCVC(),
            isActive: true
        )
        
        cards.append(newCard)
    }
    
    // MARK: - Helper Methods
    private func generateCardNumber() -> String {
        let numbers = (0..<16).map { _ in Int.random(in: 0...9) }
        let grouped = numbers.chunked(into: 4).map { $0.map(String.init).joined() }
        return grouped.joined(separator: " ")
    }
    
    private func generateExpirationDate() -> String {
        let month = String(format: "%02d", Int.random(in: 1...12))
        let year = String(Calendar.current.component(.year, from: Date()) + Int.random(in: 1...5))
        return "\(month)/\(year.suffix(2))"
    }
    
    private func generateCVC() -> String {
        return String(format: "%03d", Int.random(in: 100...999))
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
