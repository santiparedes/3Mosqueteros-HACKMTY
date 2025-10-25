import Foundation
import Combine

class BankingViewModel: ObservableObject {
    @Published var user: User?
    @Published var accounts: [Account] = []
    @Published var transactions: [Transaction] = []
    @Published var cards: [Card] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let nessieAPI = NessieAPI.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMockData()
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
                                id: nessieTx.id,
                                type: nessieTx.type,
                                transactionDate: nessieTx.transactionDate,
                                status: nessieTx.status,
                                payer: Payer(name: "Account", id: firstAccount.id),
                                payee: Payee(name: nessieTx.payeeId, id: nessieTx.payeeId),
                                amount: nessieTx.amount,
                                medium: nessieTx.medium,
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
    
    // MARK: - Account Operations
    func getTotalBalance() -> Double {
        return accounts.reduce(0) { $0 + $1.balance }
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
    private func generateCardNumber(from accountId: String) -> String {
        // Generate a card number based on the account ID
        // Take last 4 characters of account ID and pad with zeros
        let lastFour = String(accountId.suffix(4))
        let padded = lastFour.padding(toLength: 4, withPad: "0", startingAt: 0)
        return "5231 7252 1769 \(padded)"
    }
    
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
