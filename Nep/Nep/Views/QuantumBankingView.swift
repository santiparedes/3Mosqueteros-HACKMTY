import SwiftUI
import CoreLocation

struct QuantumBankingView: View {
    @StateObject private var bridge = QuantumNessieBridge.shared
    @StateObject private var quantumAPI = QuantumAPI.shared
    @StateObject private var locationManager = LocationManager()
    
    @State private var selectedCustomer: NessieCustomer?
    @State private var selectedAccount: NessieAccount?
    @State private var quantumWalletId: String = ""
    @State private var showCreateCustomer = false
    @State private var showCreateAccount = false
    @State private var showPaymentForm = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Real Banking Data Section
                    realBankingSection
                    
                    // Quantum Wallet Operations
                    quantumOperationsSection
                    
                    // Location Services
                    locationServicesSection
                    
                    // Transaction History
                    transactionHistorySection
                }
                .padding()
            }
            .navigationTitle("🏦 Quantum Banking")
            .onAppear {
                Task {
                    await loadInitialData()
                }
            }
        }
        .sheet(isPresented: $showCreateCustomer) {
            CreateCustomerView()
        }
        .sheet(isPresented: $showCreateAccount) {
            CreateAccountView(selectedCustomer: selectedCustomer)
        }
        .sheet(isPresented: $showPaymentForm) {
            QuantumPaymentView(selectedAccount: selectedAccount)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Quantum Banking")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Real banking data through quantum security")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("🔄 Refresh") {
                    Task {
                        await loadInitialData()
                    }
                }
                .buttonStyle(.bordered)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            if let success = successMessage {
                Text(success)
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Real Banking Data Section
    private var realBankingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🏦 Real Banking Data")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("+ Customer") {
                    showCreateCustomer = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if bridge.nessieCustomers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.circle")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No customers found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Load Mock Data") {
                        Task {
                            await bridge.loadMockData()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(bridge.nessieCustomers) { customer in
                        CustomerCard(
                            customer: customer,
                            isSelected: selectedCustomer?.id == customer.id
                        ) {
                            selectedCustomer = customer
                            Task {
                                await bridge.loadNessieAccounts(for: customer.id)
                            }
                        }
                    }
                }
            }
            
            // Accounts for selected customer
            if let customer = selectedCustomer, !bridge.nessieAccounts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("💳 Accounts for \(customer.firstName)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button("+ Account") {
                            showCreateAccount = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    LazyVStack(spacing: 8) {
                        ForEach(bridge.nessieAccounts) { account in
                            NessieAccountCard(
                                account: account,
                                isSelected: selectedAccount?.id == account.id
                            ) {
                                selectedAccount = account
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Quantum Operations Section
    private var quantumOperationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🛡️ Quantum Operations")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let account = selectedAccount {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Selected Account")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(account.nickname)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Balance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(account.balance, specifier: "%.2f")")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Button("🔗 Create Quantum Wallet") {
                        Task {
                            await createQuantumWallet(for: account)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    if !quantumWalletId.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quantum Wallet ID:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(quantumWalletId)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                            
                            Button("💸 Send Quantum Payment") {
                                showPaymentForm = true
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            } else {
                Text("Select an account to create a quantum wallet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Location Services Section
    private var locationServicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📍 Location Services")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                Button("🏧 Find ATMs") {
                    if let location = locationManager.location {
                        Task {
                            await bridge.findNearbyATMs(location: location)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("🏢 Find Branches") {
                    if let location = locationManager.location {
                        Task {
                            await bridge.findNearbyBranches(location: location)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            
            if !bridge.nearbyATMs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nearby ATMs")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(bridge.nearbyATMs.prefix(3)) { atm in
                        ATMCard(atm: atm)
                    }
                }
            }
            
            if !bridge.nearbyBranches.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nearby Branches")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(bridge.nearbyBranches.prefix(3)) { branch in
                        BranchCard(branch: branch)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Transaction History Section
    private var transactionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📋 Transaction History")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let account = selectedAccount {
                Button("Load Transactions") {
                    Task {
                        await loadTransactions(for: account)
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            } else {
                Text("Select an account to view transactions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Helper Functions
    private func loadInitialData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            await bridge.loadNessieCustomers()
            if bridge.nessieCustomers.isEmpty {
                await bridge.loadMockData()
            }
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func createQuantumWallet(for account: NessieAccount) async {
        do {
            let wallet = try await quantumAPI.createWallet(
                userId: account.customerId,
                pubkeyPqc: "demo_pqc_key_\(account.id)"
            )
            
            quantumWalletId = wallet.walletId
            
            // Link to Nessie account
            let _ = try await bridge.linkQuantumWalletToNessie(
                quantumWalletId: wallet.walletId,
                nessieCustomerId: account.customerId,
                nessieAccountId: account.id,
                userId: account.customerId
            )
            
            successMessage = "Quantum wallet created and linked successfully!"
            
        } catch {
            errorMessage = "Failed to create quantum wallet: \(error.localizedDescription)"
        }
    }
    
    private func loadTransactions(for account: NessieAccount) async {
        do {
            let transactions = try await bridge.getQuantumWalletTransactions(quantumWalletId: quantumWalletId)
            print("Loaded \(transactions.count) transactions")
        } catch {
            errorMessage = "Failed to load transactions: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Views
struct CustomerCard: View {
    let customer: NessieCustomer
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(customer.firstName) \(customer.lastName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(customer.address.city), \(customer.address.state)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NessieAccountCard: View {
    let account: NessieAccount
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.nickname)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(account.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(account.balance, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ATMCard: View {
    let atm: NessieATM
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(atm.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(atm.address.city), \(atm.address.state)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(atm.distance, specifier: "%.1f") mi")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

struct BranchCard: View {
    let branch: NessieBranch
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(branch.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(branch.address.city), \(branch.address.state)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(branch.distance, specifier: "%.1f") mi")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}

#Preview {
    QuantumBankingView()
}
