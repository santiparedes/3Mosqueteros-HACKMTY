import Foundation
import CryptoKit

// MARK: - User Manager
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: DemoUser?
    @Published var demoUsers: [DemoUser] = []
    
    private init() {
        generateDemoUsers()
    }
    
    // MARK: - Demo User Generation
    private func generateDemoUsers() {
        // Create demo users based on existing Nessie customers
        // We'll use Juan Perez and Maria Garcia as our demo users
        let user1 = DemoUser(
            id: "juan_demo_user", // Fixed ID for consistency
            firstName: "Juan",
            lastName: "Perez",
            email: "juan.perez@demo.com",
            phone: "+52-55-1234-5678",
            address: DemoAddress(
                streetNumber: "123",
                streetName: "Main St",
                city: "Mexico City",
                state: "MX",
                zip: "01000"
            )
        )
        
        let user2 = DemoUser(
            id: "maria_demo_user", // Fixed ID for consistency
            firstName: "Maria",
            lastName: "Garcia",
            email: "maria.garcia@demo.com",
            phone: "+52-55-9876-5432",
            address: DemoAddress(
                streetNumber: "456",
                streetName: "Reforma Ave",
                city: "Mexico City",
                state: "MX",
                zip: "06600"
            )
        )
        
        demoUsers = [user1, user2]
        currentUser = user1 // Set Juan as the default current user
    }
    
    // MARK: - User ID Generation
    private func generateUserId() -> String {
        // Generate a unique user ID using timestamp and random data
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "user_\(timestamp)_\(random)"
    }
    
    // MARK: - User Management
    func switchToUser(_ user: DemoUser) {
        currentUser = user
    }
    
    func getCurrentUserId() -> String {
        return currentUser?.id ?? generateUserId()
    }
    
    func getCurrentUserDisplayName() -> String {
        return currentUser?.fullName ?? "Demo User"
    }
    
    // MARK: - Demo Data for Presentation
    func getPresentationUsers() -> (sender: DemoUser, receiver: DemoUser) {
        guard demoUsers.count >= 2 else {
            // Fallback if demo users aren't ready
            let fallbackUser1 = DemoUser(
                id: generateUserId(),
                firstName: "Alice",
                lastName: "Demo",
                email: "alice@demo.com",
                phone: nil,
                address: nil
            )
            let fallbackUser2 = DemoUser(
                id: generateUserId(),
                firstName: "Bob",
                lastName: "Demo",
                email: "bob@demo.com",
                phone: nil,
                address: nil
            )
            return (fallbackUser1, fallbackUser2)
        }
        
        return (demoUsers[0], demoUsers[1])
    }
    
    // MARK: - Nessie Integration
    func getNessieCustomerForDemoUser(_ demoUser: DemoUser) async throws -> NessieCustomer? {
        let nessieAPI = NessieAPI.shared
        
        // First, try to find existing customers
        let customers = try await nessieAPI.getCustomers()
        
        // Look for customers with matching names
        let matchingCustomer = customers.first { customer in
            customer.firstName.lowercased() == demoUser.firstName.lowercased() &&
            customer.lastName.lowercased() == demoUser.lastName.lowercased()
        }
        
        if let customer = matchingCustomer {
            print("✅ Found existing Nessie customer: \(customer.firstName) \(customer.lastName) (ID: \(customer.id))")
            return customer
        }
        
        // If no matching customer found, create one
        print("🆕 Creating new Nessie customer for: \(demoUser.firstName) \(demoUser.lastName)")
        let newCustomer = NessieCustomerCreate(
            firstName: demoUser.firstName,
            lastName: demoUser.lastName,
            address: NessieAddress(
                streetNumber: demoUser.address?.streetNumber ?? "123",
                streetName: demoUser.address?.streetName ?? "Main St",
                city: demoUser.address?.city ?? "New York",
                state: demoUser.address?.state ?? "NY",
                zip: demoUser.address?.zip ?? "10001"
            )
        )
        
        let response = try await nessieAPI.createCustomer(newCustomer)
        print("✅ Created new Nessie customer: \(response.objectCreated.firstName) \(response.objectCreated.lastName) (ID: \(response.objectCreated.id))")
        return response.objectCreated
    }
    
    // MARK: - Available Nessie Customers
    func getAvailableNessieCustomers() async throws -> [NessieCustomer] {
        let nessieAPI = NessieAPI.shared
        return try await nessieAPI.getCustomers()
    }
    
    func getAccountsForDemoUser(_ demoUser: DemoUser) async throws -> [NessieAccount] {
        let nessieAPI = NessieAPI.shared
        let customer = try await getNessieCustomerForDemoUser(demoUser)
        
        guard let customer = customer else {
            return []
        }
        
        return try await nessieAPI.getCustomerAccounts(customerId: customer.id)
    }
    
    // MARK: - Quantum Wallet Management
    func createQuantumWalletForCurrentUser() async throws -> String {
        let userId = getCurrentUserId()
        let wallet = try await QuantumAPI.shared.createWallet(userId: userId)
        return wallet.walletId
    }
    
    func createQuantumWalletForUser(_ user: DemoUser) async throws -> String {
        let wallet = try await QuantumAPI.shared.createWallet(userId: user.id)
        return wallet.walletId
    }
}

// MARK: - Demo User Models
struct DemoUser: Identifiable, Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String?
    let address: DemoAddress?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        return "\(firstName) \(lastName.prefix(1))."
    }
}

struct DemoAddress: Codable {
    let streetNumber: String
    let streetName: String
    let city: String
    let state: String
    let zip: String
    
    var fullAddress: String {
        return "\(streetNumber) \(streetName), \(city), \(state) \(zip)"
    }
}

