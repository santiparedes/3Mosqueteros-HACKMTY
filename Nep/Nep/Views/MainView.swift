import SwiftUI

// MARK: - Main Header View
struct MainHeaderView: View {
    @ObservedObject var userManager: UserManager
    @ObservedObject var viewModel: BankingViewModel
    @Binding var showUserSelection: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
                
                if let user = viewModel.user {
                    Text(user.firstName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.nepTextLight)
                }
            }
            
            Spacer()
            
            // Profile Avatar
            Button(action: {
                showUserSelection = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.nepBlue)
                        .frame(width: 44, height: 44)
                    
                    if let user = viewModel.user {
                        Text(user.firstName.prefix(1))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}


// MARK: - Quick Actions Grid
struct QuickActionsGrid: View {
    @Binding var showSendMoney: Bool
    @Binding var showAddMoney: Bool
    @Binding var showCardDetails: Bool
    @Binding var showQuantumWallet: Bool
    @Binding var showCreditScore: Bool
    @Binding var showEncryptionCheck: Bool
    let onReceiveMoney: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.nepTextLight)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        // NEP Pay
                        Button(action: { showSendMoney = true }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.nepBlue.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.nepBlue)
                                }
                                
                                Text("NepPay")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.nepTextLight)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.nepCardBackground.opacity(0.1))
                            .cornerRadius(16)
                        }
                
                // Receive Money
                Button(action: { 
                    onReceiveMoney()
                }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.nepAccent.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.nepAccent)
                        }
                        
                        Text("Receive Money")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.nepTextLight)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.nepCardBackground.opacity(0.1))
                    .cornerRadius(16)
                }
                
                // Credit Score
                Button(action: { 
                    print("🎯 MainView: Botón Credit Report presionado")
                    showCreditScore = true 
                }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.nepWarning.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.nepWarning)
                        }
                        
                        Text("Credit Report")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.nepTextLight)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.nepCardBackground.opacity(0.1))
                    .cornerRadius(16)
                }
                
                // Encryption Check
                Button(action: { showEncryptionCheck = true }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.nepBlue.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.nepBlue)
                        }
                        
                        Text("Encryption Check")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.nepTextLight)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.nepCardBackground.opacity(0.1))
                    .cornerRadius(16)
                }
            }
        }
    }
}


// MARK: - Recent Transactions Section
struct RecentTransactionsSection: View {
    let transactions: [Transaction]
    @Binding var showTransactions: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                Spacer()
                
                Button("View All") {
                    showTransactions = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.nepBlue)
            }
            
            if transactions.isEmpty {
                EmptyTransactionsView()
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(transactions.prefix(3))) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
    }
}




struct QuantumWalletView: View {
    @Binding var quantumWalletId: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Quantum Wallet")
                    .font(.title)
                    .padding()
                
                Text("This feature will be implemented soon")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Quantum Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.nepBlue)
                    }
                }
            }
        }
    }
}

struct AllTransactionsView: View {
    let transactions: [Transaction]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(transactions) { transaction in
                TransactionRow(transaction: transaction)
            }
            .navigationTitle("All Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.nepBlue)
                    }
                }
            }
        }
    }
}


// MARK: - Simple Quantum Security Section for MainView
struct MainQuantumSecuritySection: View {
    let quantumWalletId: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(.nepBlue)
                    .font(.title2)
                
                Text("Quantum Security")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                Spacer()
                
                Text("Active")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.nepAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.nepAccent.opacity(0.1))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Your transactions are protected with post-quantum cryptography")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
                
                Text("Wallet ID: \(quantumWalletId.prefix(8))...")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.nepTextLight)
                    .padding(8)
                    .background(Color.nepCardBackground.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MainView: View {
    @State private var isLoggedIn = false
    @State private var isOnboardingComplete = false
    @StateObject private var viewModel = BankingViewModel()
    @StateObject private var quantumBridge = QuantumNessieBridge.shared
    @StateObject private var userManager = UserManager.shared
    @State private var selectedAccountIndex = 0
    @State private var quantumWalletId: String = ""
    @State private var showUserSelection = false
    
    // Navigation states
    @State private var showCardDetails = false
    @State private var showSendMoney = false
    @State private var showAddMoney = false
    @State private var showQuantumWallet = false
    @State private var showTransactions = false
    @State private var showCreditScore = false
    @State private var showEncryptionCheck = false
    @State private var selectedCard: Card?
    @State private var isBalanceVisible = true
    
    var body: some View {
        Group {
            if !isLoggedIn {
                WelcomeView(isLoggedIn: $isLoggedIn, isOnboardingComplete: $isOnboardingComplete)
            } else if !isOnboardingComplete {
                ConsentView(isOnboardingComplete: $isOnboardingComplete)
            } else if isLoggedIn {
                ZStack {
                    Color.nepDarkBackground
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header with User Info
                            MainHeaderView(userManager: userManager, viewModel: viewModel, showUserSelection: $showUserSelection)
                            
                            // Total Balance Card
                            TotalBalanceCard(balance: getTotalBalance(), isVisible: $isBalanceVisible)
                            
                            // Quick Actions Grid
                            QuickActionsGrid(
                                showSendMoney: $showSendMoney,
                                showAddMoney: $showAddMoney,
                                showCardDetails: $showCardDetails,
                                showQuantumWallet: $showQuantumWallet,
                                showCreditScore: $showCreditScore,
                                showEncryptionCheck: $showEncryptionCheck,
                                onReceiveMoney: addDebugMoney
                            )
                            
                            // Account Selector
                            AccountSelectorView(accounts: viewModel.accounts, selectedIndex: $selectedAccountIndex)
                            
                            // Cards Section
                            CardsSectionView(
                                cards: viewModel.cards,
                                showCardDetails: $showCardDetails,
                                selectedCard: $selectedCard
                            )
                            
                            // Quantum Security Section
                            if !quantumWalletId.isEmpty {
                                MainQuantumSecuritySection(quantumWalletId: quantumWalletId)
                            }
                            
                            // Recent Transactions
                            RecentTransactionsSection(
                                transactions: viewModel.getRecentTransactions(),
                                showTransactions: $showTransactions
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .onAppear {
                    Task {
                        await quantumBridge.loadMockData()
                    }
                    
                    // Test Supabase connection
                    Task {
                        print("🔍 MainView: Testing Supabase connection on app launch...")
                        let supabaseService = SupabaseService.shared
                        do {
                            let connected = try await supabaseService.testConnection()
                            print("✅ MainView: Supabase connection test result: \(connected)")
                        } catch {
                            print("❌ MainView: Supabase connection failed: \(error.localizedDescription)")
                        }
                    }
                    
                    // Run credit scoring once per user session
                    Task {
                        await runCreditScoring()
                    }
                }
                .fullScreenCover(isPresented: $showCardDetails) {
                    CardDetailsView()
                }
                .fullScreenCover(isPresented: $showSendMoney) {
                    TapToSendView()
                }
                .fullScreenCover(isPresented: $showAddMoney) {
                    AddMoneyView()
                }
                .fullScreenCover(isPresented: $showQuantumWallet) {
                    QuantumWalletView(quantumWalletId: $quantumWalletId)
                }
                .fullScreenCover(isPresented: $showTransactions) {
                    AllTransactionsView(transactions: viewModel.getRecentTransactions())
                }
                .fullScreenCover(isPresented: $showCreditScore) {
                    let _ = print("🔴 MainView: Abriendo CreditReportView...")
                    CreditReportView()
                }
            }
        }
    }
    
    private func getTotalBalance() -> Double {
        return viewModel.accounts.reduce(0) { $0 + $1.balance }
    }
    
    private func addDebugMoney() {
        // Add $1000 to the first account for debugging
        if !viewModel.accounts.isEmpty {
            viewModel.accounts[0].balance += 1000.0
            print("💰 DEBUG: Added $1,000 to account. New balance: $\(viewModel.accounts[0].balance)")
        }
    }
    
    private func runCreditScoring() async {
        print("🔍 MainView: Starting credit scoring for test account...")
        
        // Use the test account ID from the Supabase integration test
        let testAccountId = APIConfig.testAccountId
        print("📊 MainView: Using test account ID: \(testAccountId)")
        
        let creditScoringService = CreditScoringService.shared
        
        // Check if we already have a valid score for this account
        if creditScoringService.hasValidScore(for: testAccountId) {
            print("✅ MainView: Valid credit score already exists for account \(testAccountId)")
            return
        }
        
        do {
            let result = try await creditScoringService.scoreCreditByAccount(accountId: testAccountId)
            print("🎉 MainView: Credit scoring completed successfully!")
            print("   - Risk Tier: \(result.offer.riskTier)")
            print("   - Credit Limit: $\(result.offer.creditLimit)")
            print("   - APR: \(result.offer.apr * 100)%")
            print("   - Model Version: \(result.modelVersion)")
        } catch {
            print("❌ MainView: Credit scoring failed: \(error.localizedDescription)")
            print("   This is expected if the backend is not running or the account doesn't exist in Supabase")
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
    @ObservedObject var viewModel: BankingViewModel
    
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
                    
                    if let user = viewModel.user {
                        Text("\(user.firstName) \(user.lastName)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.nepTextLight)
                        
                        Text(user.email)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.nepTextSecondary)
                    } else {
                        Text("Loading...")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.nepTextLight)
                    }
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
                        title: "Credit Settings",
                        icon: "creditcard"
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
        .preferredColorScheme(.dark)
}
