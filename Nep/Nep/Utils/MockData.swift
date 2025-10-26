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
            transaction_id: "mock-sample-001",
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
            transaction_id: "mock-sample-002",
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
            transaction_id: "mock-sample-003",
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
            transaction_id: "mock-sample-004",
            account_id: "275b3406-0803-4415-8b0e-",
            transaction_type: "Purchase",
            transaction_date: "2024-01-14 19:20:00",
            status: "completed",
            medium: "debit card",
            payee_id: "merchant3",
            amount: 56.84,
            description: "Food delivery"
        ),
        Transaction(
            transaction_id: "mock-sample-005",
            account_id: "275b3406-0803-4415-8b0e-",
            transaction_type: "Deposit",
            transaction_date: "2024-01-13 09:00:00",
            status: "completed",
            medium: "direct deposit",
            payee_id: "employer1",
            amount: 5000.00,
            description: "Monthly Salary"
        ),
        Transaction(
            transaction_id: "mock-sample-006",
            account_id: "275b3406-0803-4415-8b0e-",
            transaction_type: "Purchase",
            transaction_date: "2024-01-12 20:00:00",
            status: "completed",
            medium: "debit card",
            payee_id: "merchant4",
            amount: 15.99,
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
