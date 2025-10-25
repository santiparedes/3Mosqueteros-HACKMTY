import SwiftUI

struct QuantumPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var bridge = QuantumNessieBridge.shared
    
    let selectedAccount: NessieAccount?
    
    @State private var toWalletId = ""
    @State private var amount: Double = 100.0
    @State private var description = "Quantum Payment"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var paymentResult: QuantumNessiePaymentResponse?
    
    var body: some View {
        NavigationView {
            Form {
                Section("From Account") {
                    if let account = selectedAccount {
                        HStack {
                            Text("Account:")
                            Spacer()
                            Text(account.nickname)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Balance:")
                            Spacer()
                            Text("$\(account.balance, specifier: "%.2f")")
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                    } else {
                        Text("No account selected")
                            .foregroundColor(.red)
                    }
                }
                
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
                    
                    TextField("Description", text: $description)
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
                
                if let result = paymentResult {
                    Section("Payment Result") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Quantum TX ID:")
                                Spacer()
                                Text(result.quantumTxId)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Nessie TX ID:")
                                Spacer()
                                Text(result.nessieTxId)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Amount:")
                                Spacer()
                                Text("$\(result.amount, specifier: "%.2f")")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Status:")
                                Spacer()
                                Text(result.status)
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("Quantum Signature:")
                                Spacer()
                                Text(String(result.quantumSignature.prefix(20)) + "...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
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
                    .disabled(isLoading || !isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        selectedAccount != nil &&
        !toWalletId.isEmpty &&
        amount > 0 &&
        amount <= (selectedAccount?.balance ?? 0)
    }
    
    private func sendPayment() async {
        guard let account = selectedAccount else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        paymentResult = nil
        
        do {
            // First, we need to get the quantum wallet ID for this account
            // For demo purposes, we'll use a mock quantum wallet ID
            let fromQuantumWallet = "quantum_wallet_\(account.id)"
            
            let result = try await bridge.processQuantumPayment(
                fromQuantumWallet: fromQuantumWallet,
                toQuantumWallet: toWalletId,
                amount: amount,
                description: description
            )
            
            paymentResult = result
            successMessage = "Payment processed successfully!"
            
        } catch {
            errorMessage = "Failed to process payment: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    QuantumPaymentView(selectedAccount: NessieAccount(
        id: "preview_account",
        type: "Checking",
        nickname: "Preview Account",
        rewards: 0,
        balance: 2500.0,
        accountNumber: "1234567890",
        customerId: "preview_customer"
    ))
}
