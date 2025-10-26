import Foundation

// MARK: - Database Models (matching your Supabase structure)
struct DatabaseCustomer: Codable {
    let customerId: String
    let firstName: String?
    let lastName: String?
    let birthDate: String?
    let streetNumber: String?
    let streetName: String?
    let city: String?
    let state: String?
    let zip: String?
    let profile: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case birthDate = "birth_date"
        case streetNumber = "street_number"
        case streetName = "street_name"
        case city, state, zip, profile
        case createdAt = "created_at"
    }
}

struct DatabaseAccount: Codable {
    let accountId: String
    let customerId: String?
    let accountType: String?
    let balance: Double?
    let creditLimit: Double?
    let nickname: String?
    let rewards: Int?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case customerId = "customer_id"
        case accountType = "account_type"
        case balance, creditLimit = "credit_limit"
        case nickname, rewards
        case createdAt = "created_at"
    }
}

struct DatabaseCard: Codable {
    let cardId: String
    let nickname: String?
    let type: String?
    let accountId: String
    let customerId: String
    let cardNumber: String
    let expirationDate: String
    let cvc: String
    let isActive: Bool?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case nickname, type
        case accountId = "account_id"
        case customerId = "customer_id"
        case cardNumber = "card_number"
        case expirationDate = "expiration_date"
        case cvc, isActive = "is_active"
        case createdAt = "created_at"
    }
}

struct DatabaseTransaction: Codable {
    let transactionId: String
    let accountId: String
    let transactionType: String?
    let transactionDate: String?
    let status: String?
    let medium: String?
    let payeeId: String?
    let amount: Double
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case transactionId = "transaction_id"
        case accountId = "account_id"
        case transactionType = "transaction_type"
        case transactionDate = "transaction_date"
        case status, medium
        case payeeId = "payee_id"
        case amount, description
    }
}

struct DatabaseCreditRiskProfile: Codable {
    let id: Int
    let customerId: String
    let pd90Score: Double?
    let riskTier: String?
    let creditLimit: Double?
    let apr: Double?
    let msiEligible: Bool?
    let msiMonths: Int?
    let explanation: String?
    let actualLabel: Int?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case customerId = "customer_id"
        case pd90Score = "pd90_score"
        case riskTier = "risk_tier"
        case creditLimit = "credit_limit"
        case apr, msiEligible = "msi_eligible"
        case msiMonths = "msi_months"
        case explanation, actualLabel = "actual_label"
        case createdAt = "created_at"
    }
}

// MARK: - Mapping Service
class DatabaseMappingService {
    
    // MARK: - Customer Mapping
    static func mapToUser(from customer: DatabaseCustomer) -> User {
        return User(
            id: customer.customerId,
            firstName: customer.firstName ?? "Unknown",
            lastName: customer.lastName ?? "User",
            email: "\(customer.customerId)@example.com", // You might want to add email to your customers table
            phone: nil,
            address: Address(
                streetNumber: customer.streetNumber ?? "",
                streetName: customer.streetName ?? "",
                city: customer.city ?? "",
                state: customer.state ?? "",
                zip: customer.zip ?? ""
            ),
            accounts: nil,
            cards: nil
        )
    }
    
    static func mapToDatabaseCustomer(from user: User) -> DatabaseCustomer {
        return DatabaseCustomer(
            customerId: user.id,
            firstName: user.firstName,
            lastName: user.lastName,
            birthDate: nil,
            streetNumber: user.address?.streetNumber,
            streetName: user.address?.streetName,
            city: user.address?.city,
            state: user.address?.state,
            zip: user.address?.zip,
            profile: nil,
            createdAt: nil
        )
    }
    
    // MARK: - Account Mapping
    static func mapToAccount(from dbAccount: DatabaseAccount) -> Account {
        return Account(
            id: dbAccount.accountId,
            nickname: dbAccount.nickname ?? "Account",
            rewards: dbAccount.rewards ?? 0,
            balance: dbAccount.balance ?? 0.0,
            accountNumber: nil,
            type: dbAccount.accountType ?? "Checking",
            customerId: dbAccount.customerId ?? ""
        )
    }
    
    static func mapToDatabaseAccount(from account: Account) -> DatabaseAccount {
        return DatabaseAccount(
            accountId: account.id,
            customerId: account.customerId,
            accountType: account.type,
            balance: account.balance,
            creditLimit: nil,
            nickname: account.nickname,
            rewards: account.rewards,
            createdAt: nil
        )
    }
    
    // MARK: - Card Mapping
    static func mapToCard(from dbCard: DatabaseCard) -> Card {
        return Card(
            id: dbCard.cardId,
            nickname: dbCard.nickname ?? "Card",
            type: dbCard.type ?? "Debit",
            accountId: dbCard.accountId,
            customerId: dbCard.customerId,
            cardNumber: dbCard.cardNumber,
            expirationDate: dbCard.expirationDate,
            cvc: dbCard.cvc,
            isActive: dbCard.isActive ?? true
        )
    }
    
    static func mapToDatabaseCard(from card: Card) -> DatabaseCard {
        return DatabaseCard(
            cardId: card.id,
            nickname: card.nickname,
            type: card.type,
            accountId: card.accountId,
            customerId: card.customerId,
            cardNumber: card.cardNumber,
            expirationDate: card.expirationDate,
            cvc: card.cvc,
            isActive: card.isActive,
            createdAt: nil
        )
    }
    
    // MARK: - Transaction Mapping
    static func mapToTransaction(from dbTransaction: DatabaseTransaction) -> Transaction {
        return Transaction(
            transaction_id: dbTransaction.transactionId,
            account_id: dbTransaction.accountId,
            transaction_type: dbTransaction.transactionType ?? "Unknown",
            transaction_date: dbTransaction.transactionDate ?? "",
            status: dbTransaction.status ?? "completed",
            medium: dbTransaction.medium ?? "balance",
            payee_id: dbTransaction.payeeId ?? "unknown",
            amount: dbTransaction.amount,
            description: dbTransaction.description
        )
    }
    
    // MARK: - Credit Offer Mapping
    static func mapToCreditOffer(from profile: DatabaseCreditRiskProfile) -> CreditOffer {
        return CreditOffer(
            customerId: profile.customerId,
            pd90Score: profile.pd90Score ?? 0.15,
            riskTier: profile.riskTier ?? "Near Prime",
            creditLimit: profile.creditLimit ?? 5000.0,
            apr: profile.apr ?? 0.18,
            msiEligible: profile.msiEligible ?? false,
            msiMonths: profile.msiMonths ?? 0,
            explanation: profile.explanation ?? "Credit profile generated",
            confidence: 0.85,
            generatedAt: profile.createdAt ?? Date().iso8601String
        )
    }
}

// MARK: - Date Extension
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
