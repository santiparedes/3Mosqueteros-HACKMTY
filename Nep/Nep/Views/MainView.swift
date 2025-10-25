import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    @State private var isLoggedIn = false
    
    var body: some View {
        Group {
            if isLoggedIn {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem {
                            Image(systemName: "house")
                            Text("Home")
                        }
                        .tag(0)
                    
                    CardDetailsView()
                        .tabItem {
                            Image(systemName: "asterisk")
                            Text("Card")
                        }
                        .tag(1)
                    
                    AddView()
                        .tabItem {
                            Image(systemName: "wrench.and.screwdriver")
                            Text("Debug")
                        }
                        .tag(2)
                
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person")
                            Text("Profile")
                        }
                        .tag(3)
                }
                .accentColor(.nepBlue)
            } else {
                WelcomeView()
                    .onAppear {
                        // Simulate login after 3 seconds for demo
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            isLoggedIn = true
                        }
                    }
            }
        }
    }
}

struct AddView: View {
    @StateObject private var quantumBridge = QuantumNessieBridge.shared
    @StateObject private var nessieAPI = NessieAPI.shared
    @StateObject private var userManager = UserManager.shared
    @State private var debugMessages: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.nepDarkBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Debug Actions")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.nepTextLight)
                    
                    Text("Test quantum banking features and API integrations")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    VStack(spacing: 16) {
                        DebugActionButton(
                            title: "Load Mock Data",
                            subtitle: "Load sample customers and accounts",
                            icon: "person.3",
                            action: loadMockData
                        )
                        
                        DebugActionButton(
                            title: "Test Nessie API",
                            subtitle: "Test Capital One API connection",
                            icon: "network",
                            action: testNessieAPI
                        )
                        
                        DebugActionButton(
                            title: "Create Quantum Wallet",
                            subtitle: "Generate a new quantum wallet",
                            icon: "shield.lefthalf.filled",
                            action: createQuantumWallet
                        )
                        
                        DebugActionButton(
                            title: "Test Quantum Payment",
                            subtitle: "Process a quantum payment",
                            icon: "arrow.left.arrow.right",
                            action: testQuantumPayment
                        )
                        
                        DebugActionButton(
                            title: "Find ATMs",
                            subtitle: "Test location services",
                            icon: "location",
                            action: findATMs
                        )
                        
                        DebugActionButton(
                            title: "Show Nessie Customers",
                            subtitle: "List all available customers",
                            icon: "person.3.fill",
                            action: showNessieCustomers
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Debug Messages
                    if !debugMessages.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Debug Log")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.nepTextLight)
                            
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(debugMessages.indices, id: \.self) { index in
                                        Text(debugMessages[index])
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(.nepTextSecondary)
                                            .padding(8)
                                            .background(Color.nepCardBackground.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
                .padding(.top, 50)
            }
        }
    }
    
    private func loadMockData() {
        addDebugMessage("Loading mock data...")
        Task {
            await quantumBridge.loadMockData()
            await MainActor.run {
                addDebugMessage("✅ Mock data loaded successfully")
                addDebugMessage("Customers: \(quantumBridge.nessieCustomers.count)")
                addDebugMessage("Accounts: \(quantumBridge.nessieAccounts.count)")
            }
        }
    }
    
    private func testNessieAPI() {
        addDebugMessage("Testing Nessie API connection...")
        Task {
            do {
                let customers = try await nessieAPI.getCustomers()
                await MainActor.run {
                    addDebugMessage("✅ Nessie API connected successfully")
                    addDebugMessage("Found \(customers.count) customers")
                }
            } catch {
                await MainActor.run {
                    addDebugMessage("❌ Nessie API error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func createQuantumWallet() {
        addDebugMessage("Creating quantum wallet...")
        Task {
            do {
                let wallet = try await QuantumAPI.shared.createWallet(userId: userManager.getCurrentUserId())
                await MainActor.run {
                    addDebugMessage("✅ Quantum wallet created")
                    addDebugMessage("Wallet ID: \(wallet.walletId)")
                }
            } catch {
                await MainActor.run {
                    addDebugMessage("❌ Quantum wallet error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testQuantumPayment() {
        addDebugMessage("Testing quantum payment...")
        Task {
            do {
                // Create two wallets for testing
                // Get the two demo users for presentation
                let (sender, receiver) = userManager.getPresentationUsers()
                let wallet1 = try await QuantumAPI.shared.createWallet(userId: sender.id)
                let wallet2 = try await QuantumAPI.shared.createWallet(userId: receiver.id)
                
                // Process payment
                let result = try await quantumBridge.processQuantumPayment(
                    fromQuantumWallet: wallet1.walletId,
                    toQuantumWallet: wallet2.walletId,
                    amount: 100.0
                )
                
                await MainActor.run {
                    addDebugMessage("✅ Quantum payment successful")
                    addDebugMessage("From: \(sender.fullName) → To: \(receiver.fullName)")
                    addDebugMessage("Quantum TX: \(result.quantumTxId)")
                    addDebugMessage("Nessie TX: \(result.nessieTxId)")
                }
            } catch {
                await MainActor.run {
                    addDebugMessage("❌ Quantum payment error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func findATMs() {
        addDebugMessage("Finding nearby ATMs...")
        Task {
            do {
                let atms = try await nessieAPI.getATMs(latitude: 40.7128, longitude: -74.0060, radius: 5)
                await MainActor.run {
                    addDebugMessage("✅ Found \(atms.count) ATMs nearby")
                    for atm in atms.prefix(3) {
                        addDebugMessage("📍 \(atm.name) - \(atm.address.streetName)")
                    }
                }
            } catch {
                await MainActor.run {
                    addDebugMessage("❌ ATM search error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showNessieCustomers() {
        addDebugMessage("Loading Nessie customers...")
        Task {
            do {
                let customers = try await userManager.getAvailableNessieCustomers()
                await MainActor.run {
                    addDebugMessage("✅ Found \(customers.count) Nessie customers:")
                    for customer in customers {
                        addDebugMessage("👤 \(customer.firstName) \(customer.lastName) - \(customer.address.city), \(customer.address.state)")
                        addDebugMessage("   ID: \(customer.id)")
                    }
                }
            } catch {
                await MainActor.run {
                    addDebugMessage("❌ Failed to load customers: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func addDebugMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        debugMessages.append("[\(timestamp)] \(message)")
        
        // Keep only last 20 messages
        if debugMessages.count > 20 {
            debugMessages.removeFirst()
        }
    }
}

struct DebugActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.nepBlue)
                    .frame(width: 40, height: 40)
                    .background(Color.nepBlue.opacity(0.1))
                    .cornerRadius(20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.nepTextLight)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "play.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.nepBlue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.nepCardBackground.opacity(0.1))
            .cornerRadius(12)
        }
    }
}


struct ProfileView: View {
    var body: some View {
        ZStack {
            Color.nepDarkBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Profile header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.nepBlue)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("John Doe")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.nepTextLight)
                    
                    Text("john.doe@example.com")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                }
                .padding(.top, 50)
                
                // Profile options
                VStack(spacing: 12) {
                    ProfileOptionButton(
                        title: "Personal Information",
                        icon: "person.circle"
                    )
                    
                    ProfileOptionButton(
                        title: "Account Settings",
                        icon: "gear"
                    )
                    
                    ProfileOptionButton(
                        title: "Security Settings",
                        icon: "lock"
                    )
                    
                    ProfileOptionButton(
                        title: "Privacy Settings",
                        icon: "eye.slash"
                    )
                    
                    ProfileOptionButton(
                        title: "Sign Out",
                        icon: "arrow.right.square",
                        isDestructive: true
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}

struct ProfileOptionButton: View {
    let title: String
    let icon: String
    var isDestructive: Bool = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? .nepError : .nepBlue)
                    .frame(width: 40, height: 40)
                    .background((isDestructive ? Color.nepError : Color.nepBlue).opacity(0.1))
                    .cornerRadius(20)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDestructive ? .nepError : .nepTextLight)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.nepTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.nepCardBackground.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    MainView()
}
