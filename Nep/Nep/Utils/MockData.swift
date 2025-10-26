import Foundation

struct MockData {
    static let sampleUser = User(
        id: "1",
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        phone: "+1-555-0123",
        address: Address(
            streetNumber: "123",
            streetName: "Main St",
            city: "New York",
            state: "NY",
            zip: "10001"
        ),
        accounts: nil,
        cards: nil
    )
    
    static let sampleAccounts = [
        Account(
            id: "1",
            nickname: "Primary Checking",
            rewards: 0,
            balance: 24092.67,
            accountNumber: "1234567890",
            type: "Checking",
            customerId: "1"
        ),
        Account(
            id: "2",
            nickname: "Savings Account",
            rewards: 0,
            balance: 15000.00,
            accountNumber: "0987654321",
            type: "Savings",
            customerId: "1"
        ),
        Account(
            id: "3",
            nickname: "Investment Account",
            rewards: 0,
            balance: 50000.00,
            accountNumber: "1122334455",
            type: "Investment",
            customerId: "1"
        )
    ]
    
    static let sampleCards = [
        Card(
            id: "1",
            nickname: "Credit Card",
            type: "Credit",
            accountId: "1",
            customerId: "1",
            cardNumber: "5231 7252 1769 8152",
            expirationDate: "08/29",
            cvc: "678",
            isActive: true
        ),
        Card(
            id: "2",
            nickname: "Debit Card",
            type: "Debit",
            accountId: "2",
            customerId: "1",
            cardNumber: "4567 8901 2345 6789",
            expirationDate: "12/26",
            cvc: "123",
            isActive: false
        )
    ]
    
    static let sampleTransactions = [
        Transaction(
            id: "1",
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
            id: "2",
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
            id: "3",
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
            id: "4",
            type: "Purchase",
            transactionDate: "2024-01-14",
            status: "completed",
            payer: Payer(name: "Glovo", id: "merchant3"),
            payee: Payee(name: "Your Account", id: "user2"),
            amount: 56.84,
            medium: "debit card",
            description: "Food delivery"
        ),
        Transaction(
            id: "5",
            type: "Deposit",
            transactionDate: "2024-01-13",
            status: "completed",
            payer: Payer(name: "Salary Deposit", id: "employer1"),
            payee: Payee(name: "Your Account", id: "user2"),
            amount: 5000.00,
            medium: "direct deposit",
            description: "Monthly Salary"
        ),
        Transaction(
            id: "6",
            type: "Purchase",
            transactionDate: "2024-01-12",
            status: "completed",
            payer: Payer(name: "Netflix", id: "merchant4"),
            payee: Payee(name: "Your Account", id: "user2"),
            amount: 15.99,
            medium: "debit card",
            description: "Subscription"
        )
    ]
    
    static let sampleCreditOffer = CreditOffer(
        customerId: "1",
        pd90Score: 0.15,  // 15% probability of default
        riskTier: "Near Prime",
        creditLimit: 8000.0,
        apr: 0.1899,  // 18.99% APR
        msiEligible: true,
        msiMonths: 12,
        explanation: "Based on your financial profile, you qualify for a credit card with competitive rates and MSI benefits.",
        confidence: 0.85,
        generatedAt: "2024-01-15T10:30:00Z"
    )
}
