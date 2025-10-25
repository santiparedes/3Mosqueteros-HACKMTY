import SwiftUI
import UIKit

struct CardDetailsView: View {
    @StateObject private var viewModel = BankingViewModel()
    @StateObject private var quantumAPI = QuantumAPI.shared
    @StateObject private var userManager = UserManager.shared
    @State private var card: Card?
    @State private var balance: Double = 24092.67
    @State private var quantumWalletId: String = ""
    @State private var showQuantumSecurity = false
    
    var body: some View {
        ZStack {
            Color.nepDarkBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.nepTextLight)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Card display
                    CardDisplayView(card: card)
                    
                    // Balance
                    BalanceView(balance: balance)
                    
                    // Card info
                    CardInfoView(card: card)
                    
                    // Quantum Security Section
                    QuantumSecuritySection(
                        quantumWalletId: $quantumWalletId,
                        showQuantumSecurity: $showQuantumSecurity,
                        userManager: userManager
                    )
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .onAppear {
            viewModel.loadMockData()
            card = viewModel.getActiveCard()
            balance = viewModel.getTotalBalance()
        }
    }
}

struct QuantumSecuritySection: View {
    @Binding var quantumWalletId: String
    @Binding var showQuantumSecurity: Bool
    @ObservedObject var userManager: UserManager
    @StateObject private var quantumAPI = QuantumAPI.shared
    @State private var isLoading = false
    
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
                
                if quantumWalletId.isEmpty {
                    Button("Enable") {
                        Task {
                            await createQuantumWallet()
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.nepBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.nepBlue.opacity(0.1))
                    .cornerRadius(8)
                    .disabled(isLoading)
                } else {
                    Button("View Details") {
                        showQuantumSecurity = true
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.nepAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.nepAccent.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if quantumWalletId.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Protect your card with quantum-resistant cryptography")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                    
                    HStack(spacing: 12) {
                        SecurityFeature(icon: "lock.shield", title: "Post-Quantum Encryption")
                        SecurityFeature(icon: "checkmark.seal", title: "Merkle Verification")
                        SecurityFeature(icon: "key", title: "CRYSTALS-Dilithium")
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quantum Wallet Active")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.nepAccent)
                    
                    Text("Wallet ID: \(quantumWalletId)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.nepTextLight)
                        .padding(8)
                        .background(Color.nepCardBackground.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showQuantumSecurity) {
            QuantumSecurityDetailsView(quantumWalletId: quantumWalletId)
        }
    }
    
    private func createQuantumWallet() async {
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

struct SecurityFeature: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.nepBlue)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.nepTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuantumSecurityDetailsView: View {
    let quantumWalletId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var quantumAPI = QuantumAPI.shared
    @State private var receipts: [QuantumReceipt] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Wallet Information") {
                    HStack {
                        Text("Wallet ID")
                        Spacer()
                        Text(quantumWalletId)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Security Level")
                        Spacer()
                        Text("CRYSTALS-Dilithium")
                            .foregroundColor(.green)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text("Active")
                            .foregroundColor(.green)
                    }
                }
                
                Section("Recent Transactions") {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if receipts.isEmpty {
                        Text("No transactions yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(receipts) { receipt in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TX: \(receipt.tx.fromWallet)")
                                    .font(.system(.caption, design: .monospaced))
                                
                                Text("Amount: $\(receipt.tx.amount, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Quantum Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadReceipts()
        }
    }
    
    private func loadReceipts() {
        isLoading = true
        // In a real app, you'd fetch receipts from the API
        // For now, we'll use mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            receipts = []
            isLoading = false
        }
    }
}

struct CardDisplayView: View {
    let card: Card?
    
    var body: some View {
        ZStack {
            // Card background with gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.nepBlue, Color.nepLightBlue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 320, height: 200)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack {
                HStack {
                    Spacer()
                    Text("**** 8152")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 50)
                .padding(.top, 20)
                
                Spacer()
                
                // Logo
                Image(systemName: "asterisk")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack {
                    // Contactless icon
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Debit")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 25)
            }
        }
    }
}

struct BalanceView: View {
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

struct CardInfoView: View {
    let card: Card?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Card info")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.nepTextLight)
            
            VStack(spacing: 16) {
                CardInfoRow(
                    title: "Card number",
                    value: card?.cardNumber ?? "5231 7252 1769 8152",
                    showCopyButton: true
                )
                
                CardInfoRow(
                    title: "CVC",
                    value: card?.cvc ?? "678",
                    showCopyButton: false
                )
                
                CardInfoRow(
                    title: "Expiry date",
                    value: card?.expirationDate ?? "08/29",
                    showCopyButton: false
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

struct CardInfoRow: View {
    let title: String
    let value: String
    let showCopyButton: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.nepTextLight)
            }
            
            Spacer()
            
            if showCopyButton {
                Button(action: {
                    // Copy to clipboard
                    UIPasteboard.general.string = value
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16))
                        .foregroundColor(.nepBlue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    CardDetailsView()
}
