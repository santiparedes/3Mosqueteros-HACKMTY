import Foundation

struct Transaction: Codable, Identifiable {
    let id: String
    let type: String
    let transactionDate: String
    let status: String
    let payer: Payer
    let payee: Payee
    let amount: Double
    let medium: String
    let description: String?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: transactionDate) {
            formatter.dateFormat = "MMM dd, yyyy"
            return formatter.string(from: date)
        }
        return transactionDate
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
            id: "1",
            type: "Conversion",
            transactionDate: "2024-01-15",
            status: "completed",
            payer: Payer(name: "USD Account", id: "acc1"),
            payee: Payee(name: "EUR Account", id: "acc2"),
            amount: 2000.00,
            medium: "balance",
            description: "Conversion USD → EUR"
        ),
        Transaction(
            id: "2",
            type: "Transfer",
            transactionDate: "2024-01-15",
            status: "completed",
            payer: Payer(name: "John Williams", id: "user1"),
            payee: Payee(name: "Your Account", id: "user2"),
            amount: 75.00,
            medium: "debit card",
            description: "Transfers"
        ),
        Transaction(
            id: "3",
            type: "Purchase",
            transactionDate: "2024-01-15",
            status: "completed",
            payer: Payer(name: "Uber", id: "merchant1"),
            payee: Payee(name: "Your Account", id: "user2"),
            amount: 34.24,
            medium: "debit card",
            description: "Taxi"
        ),
        Transaction(
            id: "4",
            type: "Purchase",
            transactionDate: "2024-01-14",
            status: "completed",
            payer: Payer(name: "ShopRite of Avenue", id: "merchant2"),
            payee: Payee(name: "Your Account", id: "user2"),
            amount: 22.41,
            medium: "debit card",
            description: "Grocery Shop"
        ),
        Transaction(
            id: "5",
            type: "Purchase",
            transactionDate: "2024-01-14",
            status: "completed",
            payer: Payer(name: "Glovo", id: "merchant3"),
            payee: Payee(name: "Your Account", id: "user2"),
            amount: 56.84,
            medium: "debit card",
            description: "Food delivery"
        )
    ]
}
