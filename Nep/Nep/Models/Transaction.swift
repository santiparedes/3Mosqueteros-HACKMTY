import Foundation

struct Transaction: Codable, Identifiable {
    let transaction_id: String
    let account_id: String
    let transaction_type: String
    let transaction_date: String
    let status: String
    let medium: String
    let payee_id: String
    let amount: Double  // Changed back to Double to match database
    let description: String?
    
    // Computed property for Identifiable protocol
    var id: String { transaction_id }
    
    // Computed property for type (mapped from transaction_type)
    var type: String { transaction_type }
    
    // Computed property for payer (simplified for now)
    var payer: Payer {
        Payer(name: "Account Holder", id: account_id)
    }
    
    // Computed property for payee (simplified for now)
    var payee: Payee {
        Payee(name: "Recipient", id: payee_id)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: transaction_date) {
            formatter.dateFormat = "MMM dd, yyyy"
            return formatter.string(from: date)
        }
        return transaction_date
    }
    
    var isDebit: Bool {
        return type.lowercased().contains("debit") || type.lowercased().contains("withdrawal")
    }
}

struct Payer: Codable {
    let name: String
    let id: String
}

struct Payee: Codable {
    let name: String
    let id: String
}

// Mock data for development
extension Transaction {
    static let mockTransactions: [Transaction] = [
        Transaction(
            transaction_id: "mock-tx-001",
            account_id: "275b3406-0803-4415-8b0e-",
            transaction_type: "Transfer",
            transaction_date: "2024-01-15 10:00:00",
            status: "completed",
            medium: "debit card",
            payee_id: "user2",
            amount: 75.00,
            description: "Transfers"
        ),
        Transaction(
            transaction_id: "mock-tx-002",
            account_id: "275b3406-0803-4415-8b0e-",
            transaction_type: "Purchase",
            transaction_date: "2024-01-15 14:30:00",
            status: "completed",
            medium: "debit card",
            payee_id: "merchant1",
            amount: 34.24,
            description: "Taxi"
        ),
        Transaction(
            transaction_id: "mock-tx-003",
            account_id: "275b3406-0803-4415-8b0e-",
            transaction_type: "Purchase",
            transaction_date: "2024-01-14 16:45:00",
            status: "completed",
            medium: "debit card",
            payee_id: "merchant2",
            amount: 22.41,
            description: "Grocery Shop"
        ),
        Transaction(
            transaction_id: "mock-tx-004",
            account_id: "275b3406-0803-4415-8b0e-",
            transaction_type: "Purchase",
            transaction_date: "2024-01-14 19:20:00",
            status: "completed",
            medium: "debit card",
            payee_id: "merchant3",
            amount: 56.84,
            description: "Food delivery"
        )
    ]
}
