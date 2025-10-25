import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = BankingViewModel()
    @StateObject private var quantumBridge = QuantumNessieBridge.shared
    @StateObject private var userManager = UserManager.shared
    @State private var selectedAccountIndex = 0
    @State private var showQuantumWallet = false
    @State private var quantumWalletId: String = ""
    @State private var showUserSelection = false
    
    var body: some View {
        ZStack {
            // Grainy gradient background
            GrainyGradientView.backgroundGradient()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with User Info
                    HeaderView(userManager: userManager, showUserSelection: $showUserSelection)
                    
                    // Currency balances
                    CurrencyBalancesView()
                    
                    // Main balance
                    MainBalanceView(balance: getCurrentBalance())
                    
                    // Account selector
                    AccountSelectorView(accounts: viewModel.accounts, selectedIndex: $selectedAccountIndex)
                    
                    // Action buttons
                    ActionButtonsView(quantumWalletId: $quantumWalletId, userManager: userManager)
                    
                    // Quantum Wallet Section
                    if !quantumWalletId.isEmpty {
                        QuantumWalletSection(quantumWalletId: quantumWalletId)
                    }
                    
                    // Transactions
                    TransactionsView(transactions: viewModel.getRecentTransactions())
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            viewModel.loadMockData()
            Task {
                await quantumBridge.loadMockData()
            }
        }
    }
    
    private func getCurrentBalance() -> Double {
        guard selectedAccountIndex < viewModel.accounts.count else { return 0.0 }
        return viewModel.accounts[selectedAccountIndex].balance
    }
}

struct QuantumWalletSection: View {
    let quantumWalletId: String
    @StateObject private var quantumAPI = QuantumAPI.shared
    @State private var showPaymentForm = false
    @State private var toWalletId = ""
    @State private var amount: Double = 100.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(.nepBlue)
                    .font(.title2)
                
                Text("Quantum Wallet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                Spacer()
                
                Button("Send") {
                    showPaymentForm = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.nepBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.nepBlue.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Wallet ID")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
                
                Text(quantumWalletId)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.nepTextLight)
                    .padding(8)
                    .background(Color.nepCardBackground.opacity(0.1))
                    .cornerRadius(6)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Security Level")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                    
                    Text("CRYSTALS-Dilithium")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.nepAccent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                    
                    Text("Active")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.nepAccent)
                }
            }
        }
        .padding(16)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showPaymentForm) {
            QuantumPaymentSheet(
                fromWalletId: quantumWalletId,
                toWalletId: $toWalletId,
                amount: $amount
            )
        }
    }
}

struct QuantumPaymentSheet: View {
    let fromWalletId: String
    @Binding var toWalletId: String
    @Binding var amount: Double
    @Environment(\.dismiss) private var dismiss
    @StateObject private var quantumAPI = QuantumAPI.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Payment Details") {
                    TextField("To Wallet ID", text: $toWalletId)
                        .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("Amount", value: $amount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let success = successMessage {
                    Section {
                        Text(success)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Quantum Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        Task {
                            await sendPayment()
                        }
                    }
                    .disabled(isLoading || toWalletId.isEmpty)
                }
            }
        }
    }
    
    private func sendPayment() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Prepare transaction
            let prepareResponse = try await quantumAPI.prepareTransaction(
                walletId: fromWalletId,
                to: toWalletId,
                amount: amount,
                currency: "USD"
            )
            
            // Sign with post-quantum signature (CRYSTALS-Dilithium)
            let signer = DilithiumQuantumSigner()
            let payloadData = try JSONEncoder().encode(prepareResponse.payload)
            let (publicKey, privateKey) = signer.generateKeyPair()
            let signature = try signer.sign(payload: payloadData, privateKey: privateKey)
            
            // Submit transaction
            let submitResponse = try await quantumAPI.submitTransaction(
                payload: prepareResponse.payload,
                signature: signature,
                publicKey: publicKey
            )
            
            successMessage = "Payment sent successfully! TX ID: \(submitResponse.txId)"
            
            // Auto-dismiss after success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
            
        } catch {
            errorMessage = "Failed to send payment: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct HeaderView: View {
    @ObservedObject var userManager: UserManager
    @Binding var showUserSelection: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // User info and controls
            HStack {
                // Current user info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                    
                    Text(userManager.getCurrentUserDisplayName())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.nepTextLight)
                }
                
                Spacer()
                
                // User selection and notification icons
                HStack(spacing: 16) {
                    Button(action: {
                        showUserSelection = true
                    }) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.nepBlue)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                            .foregroundColor(.nepTextLight)
                    }
                }
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.nepTextSecondary)
                Text("Q Search")
                    .foregroundColor(.nepTextSecondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.nepCardBackground)
            .cornerRadius(25)
        }
        .sheet(isPresented: $showUserSelection) {
            UserSelectionSheet(userManager: userManager)
        }
    }
}

struct UserSelectionSheet: View {
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUser: DemoUser?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Demo Users for Presentation")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.nepTextLight)
                    .padding(.top)
                
                Text("Select a user to demonstrate quantum banking features")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                UserSelectionView(
                    userManager: userManager,
                    selectedUser: $selectedUser,
                    onUserSelected: { user in
                        userManager.switchToUser(user)
                        dismiss()
                    }
                )
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color.nepDarkBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct UserSelectionView: View {
    @ObservedObject var userManager: UserManager
    @Binding var selectedUser: DemoUser?
    let onUserSelected: (DemoUser) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Demo User")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.nepTextLight)
            
            ForEach(userManager.demoUsers) { user in
                Button(action: {
                    selectedUser = user
                    onUserSelected(user)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.nepTextLight)
                            
                            Text(user.email)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.nepTextSecondary)
                        }
                        
                        Spacer()
                        
                        if selectedUser?.id == user.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.nepBlue)
                        }
                    }
                    .padding()
                    .background(selectedUser?.id == user.id ? Color.nepBlue.opacity(0.1) : Color.nepCardBackground.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct CurrencyBalancesView: View {
    let currencies = [
        ("USD", "🇺🇸", 24092.67),
        ("EUR", "🇪🇺", 7805.91),
        ("AUD", "🇦🇺", 3693.70)
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(currencies, id: \.0) { currency in
                CurrencyCard(
                    flag: currency.1,
                    amount: currency.2,
                    currency: currency.0
                )
            }
        }
    }
}

struct CurrencyCard: View {
    let flag: String
    let amount: Double
    let currency: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(flag)
                .font(.system(size: 24))
            
            Text(formatCurrency(amount, currency: currency))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.nepTextLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.nepBlue.opacity(0.2))
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct MainBalanceView: View {
    let balance: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.nepTextSecondary)
            
            Text(formatCurrency(balance))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.nepTextLight)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct AccountSelectorView: View {
    let accounts: [Account]
    @Binding var selectedIndex: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<4) { index in
                AccountCard(
                    isSelected: index == selectedIndex,
                    isActive: index < accounts.count,
                    account: index < accounts.count ? accounts[index] : nil
                )
                .onTapGesture {
                    if index < accounts.count {
                        selectedIndex = index
                    }
                }
            }
        }
    }
}

struct AccountCard: View {
    let isSelected: Bool
    let isActive: Bool
    let account: Account?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.nepBlue : Color.nepCardBackground)
                .frame(width: 60, height: 40)
            Group{
                if isActive {
                    if isSelected {
                        Image("Star")
                            .resizable(resizingMode: .stretch)
                            .aspectRatio(contentMode: .fill)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .colorInvert()
                            .frame(width: 25, height: 25)
                    } else {
                        Image(systemName: "creditcard")
                            .font(.system(size: 16))
                            .foregroundColor(.nepTextSecondary)
                    }
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                        .foregroundColor(.nepTextSecondary)
                }
            }
            
        }
        .scaleEffect(isSelected ? 1.06 : 1.0)
                .shadow(color: Color.black.opacity(isSelected ? 0.25 : 0.06), radius: isSelected ? 8 : 2, x: 0, y: isSelected ? 6 : 2)
                .animation(.spring(response: 0.36, dampingFraction: 0.78), value: isSelected)
                .frame(width: 60, height: 40)
                .cornerRadius(12)
    }
}

struct ActionButtonsView: View {
    @Binding var quantumWalletId: String
    @ObservedObject var userManager: UserManager
    @StateObject private var quantumAPI = QuantumAPI.shared
    @State private var isLoading = false
    
    let actions = [
        ("ADD", "plus"),
        ("SEND", "arrow.up"),
        ("QUANTUM", "shield.lefthalf.filled")
    ]
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(actions, id: \.0) { action in
                VStack(spacing: 8) {
                    Button(action: {
                        if action.0 == "QUANTUM" {
                            Task {
                                await createQuantumWallet()
                            }
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(action.0 == "QUANTUM" && !quantumWalletId.isEmpty ? Color.nepBlue : Color.nepCardBackground)
                                .frame(width: 60, height: 60)
                            
                            if isLoading && action.0 == "QUANTUM" {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: action.1)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(action.0 == "QUANTUM" && !quantumWalletId.isEmpty ? .gray : .nepTextLight)
                            }
                        }
                    }
                    .disabled(isLoading && action.0 == "QUANTUM")
                    
                    Text(action.0)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.nepTextLight)
                }
            }
        }
    }
    
    private func createQuantumWallet() async {
        guard quantumWalletId.isEmpty else { return }
        
        isLoading = true
        
        do {
            let wallet = try await quantumAPI.createWallet(userId: userManager.getCurrentUserId())
            await MainActor.run {
                quantumWalletId = wallet.walletId
            }
        } catch {
            print("Failed to create quantum wallet: \(error)")
        }
        
        isLoading = false
    }
}

struct TransactionsView: View {
    let transactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Transactions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                Spacer()
                
                Button("View all") {
                    // Navigate to all transactions
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.nepBlue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
