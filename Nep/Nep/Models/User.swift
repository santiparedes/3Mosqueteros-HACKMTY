import Foundation

struct User: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String?
    let address: Address?
    let accounts: [Account]?
    let cards: [Card]?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

struct Address: Codable {
    let streetNumber: String
    let streetName: String
    let city: String
    let state: String
    let zip: String
}

struct Account: Codable, Identifiable {
    let id: String
    let nickname: String
    let rewards: Int
    let balance: Double
    let accountNumber: String
    let type: String
    let customerId: String
}

struct Card: Codable, Identifiable {
    let id: String
    let nickname: String
    let type: String
    let accountId: String
    let customerId: String
    let cardNumber: String
    let expirationDate: String
    let cvc: String
    let isActive: Bool
}
