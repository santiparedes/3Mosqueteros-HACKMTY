import SwiftUI

struct QuantumView: View {
    @StateObject private var quantumAPI = QuantumAPI.shared
    @StateObject private var userManager = UserManager.shared
    @State private var walletId: String = ""
    @State private var isLoading = false
    @State private var showCreateWallet = false
    @State private var showSendPayment = false
    @State private var quantumReceipts: [QuantumReceipt] = []
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.nepDarkBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    QuantumHeaderView()
                    
                    if walletId.isEmpty {
                        // No wallet state
                        NoWalletView(showCreateWallet: $showCreateWallet)
                    } else {
                        // Wallet exists state
                        WalletExistsView(
                            walletId: walletId,
                            showSendPayment: $showSendPayment,
                            quantumReceipts: $quantumReceipts
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            loadWalletData()
        }
        .sheet(isPresented: $showCreateWallet) {
            CreateQuantumWalletView(walletId: $walletId)
        }
        .sheet(isPresented: $showSendPayment) {
            SendQuantumPaymentView(walletId: walletId, quantumReceipts: $quantumReceipts)
        }
    }
    
    private func loadWalletData() {
        // Load existing wallet data if available
        // This would typically come from UserDefaults or a database
    }
}

// MARK: - Header View
struct QuantumHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quantum Wallet")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                Text("Post-quantum secure transactions")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
            }
            
            Spacer()
            
            // Quantum shield icon
            ZStack {
                Circle()
                    .fill(Color.nepBlue.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.nepBlue)
            }
        }
    }
}

// MARK: - No Wallet View
struct NoWalletView: View {
    @Binding var showCreateWallet: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Quantum illustration
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.nepBlue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(.nepBlue)
                }
                
                VStack(spacing: 8) {
                    Text("No Quantum Wallet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.nepTextLight)
                    
                    Text("Create a quantum-resistant wallet to start making secure transactions")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.nepTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Features list
            VStack(spacing: 12) {
                FeatureRow(icon: "lock.shield", title: "Post-Quantum Security", description: "Protected against future quantum attacks")
                FeatureRow(icon: "checkmark.seal", title: "Cryptographic Proofs", description: "Merkle tree verification")
                FeatureRow(icon: "bolt.fill", title: "Instant Settlement", description: "Real-time transaction processing")
            }
            .padding(.vertical, 20)
            
            // Create wallet button
            Button(action: {
                showCreateWallet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Create Quantum Wallet")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.nepBlue)
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.nepCardBackground.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.nepBlue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.nepAccent.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.nepAccent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.nepTextLight)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.nepTextSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Wallet Exists View
struct WalletExistsView: View {
    let walletId: String
    @Binding var showSendPayment: Bool
    @Binding var quantumReceipts: [QuantumReceipt]
    
    var body: some View {
        VStack(spacing: 24) {
            // Wallet status card
            WalletStatusCard(walletId: walletId)
            
            // Quick actions
            QuantumQuickActionsView(showSendPayment: $showSendPayment)
            
            // Recent receipts
            RecentReceiptsView(quantumReceipts: quantumReceipts)
        }
    }
}

// MARK: - Wallet Status Card
struct WalletStatusCard: View {
    let walletId: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quantum Wallet Active")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.nepTextLight)
                    
                    Text("ID: \(walletId.prefix(8))...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.nepAccent.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.nepAccent)
                }
            }
            
            HStack {
                StatusIndicator(title: "Security", status: "Quantum-Resistant", color: .nepAccent)
                Spacer()
                StatusIndicator(title: "Status", status: "Active", color: .nepBlue)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.nepCardBackground.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.nepAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let title: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.nepTextSecondary)
            
            Text(status)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Quantum Quick Actions
struct QuantumQuickActionsView: View {
    @Binding var showSendPayment: Bool
    
    let actions = [
        ("Send Payment", "arrow.up.circle.fill", Color.nepBlue),
        ("View Receipts", "doc.text.fill", Color.nepAccent),
        ("Verify Proof", "checkmark.shield.fill", Color.nepWarning),
        ("Settings", "gearshape.fill", Color.nepTextSecondary)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.nepTextLight)
            
            HStack(spacing: 16) {
                ForEach(actions, id: \.0) { action in
                    Button(action: {
                        if action.0 == "Send Payment" {
                            showSendPayment = true
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(action.2.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: action.1)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(action.2)
                            }
                            
                            Text(action.0)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.nepTextLight)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Recent Receipts
struct RecentReceiptsView: View {
    let quantumReceipts: [QuantumReceipt]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Receipts")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                Spacer()
                
                Button("View All") {
                    // View all receipts action
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.nepBlue)
            }
            
            if quantumReceipts.isEmpty {
                EmptyReceiptsView()
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(quantumReceipts.prefix(3))) { receipt in
                        ReceiptRowView(receipt: receipt)
                    }
                }
            }
        }
    }
}

// MARK: - Receipt Row View
struct ReceiptRowView: View {
    let receipt: QuantumReceipt
    
    var body: some View {
        HStack(spacing: 16) {
            // Receipt icon
            ZStack {
                Circle()
                    .fill(Color.nepBlue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.nepBlue)
            }
            
            // Receipt details
            VStack(alignment: .leading, spacing: 4) {
                Text("Transaction #\(receipt.id.prefix(8))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.nepTextLight)
                
                Text("Amount: \(receipt.tx.currency) \(String(format: "%.2f", receipt.tx.amount))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
            }
            
            Spacer()
            
            // Status
            VStack(alignment: .trailing, spacing: 4) {
                Text("Verified")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.nepAccent)
                
                Text("Block #\(receipt.blockHeader.index)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Empty Receipts View
struct EmptyReceiptsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.nepTextSecondary)
            
            Text("No receipts yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.nepTextSecondary)
            
            Text("Your quantum transaction receipts will appear here")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.nepTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.nepCardBackground.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.nepTextSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Placeholder Views
struct CreateQuantumWalletView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var walletId: String
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Create Quantum Wallet")
                    .font(.title)
                    .padding()
                
                Text("This feature will be implemented soon")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Create Wallet")
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

struct SendQuantumPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    let walletId: String
    @Binding var quantumReceipts: [QuantumReceipt]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Send Quantum Payment")
                    .font(.title)
                    .padding()
                
                Text("This feature will be implemented soon")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Send Payment")
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

#Preview {
    QuantumView()
}
