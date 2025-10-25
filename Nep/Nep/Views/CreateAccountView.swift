import SwiftUI

struct CreateAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var bridge = QuantumNessieBridge.shared
    
    let selectedCustomer: NessieCustomer?
    
    @State private var accountType = "Checking"
    @State private var nickname = ""
    @State private var initialBalance: Double = 1000.0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    private let accountTypes = ["Checking", "Savings", "Credit Card"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Customer") {
                    if let customer = selectedCustomer {
                        HStack {
                            Text("Customer:")
                            Spacer()
                            Text("\(customer.firstName) \(customer.lastName)")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No customer selected")
                            .foregroundColor(.red)
                    }
                }
                
                Section("Account Details") {
                    Picker("Account Type", selection: $accountType) {
                        ForEach(accountTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    TextField("Account Nickname", text: $nickname)
                    
                    HStack {
                        Text("Initial Balance")
                        Spacer()
                        TextField("Amount", value: $initialBalance, format: .currency(code: "USD"))
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
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await createAccount()
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
        }
        .onAppear {
            if let customer = selectedCustomer {
                nickname = "\(customer.firstName)'s Quantum Wallet"
            }
        }
    }
    
    private var isFormValid: Bool {
        selectedCustomer != nil &&
        !nickname.isEmpty &&
        initialBalance >= 0
    }
    
    private func createAccount() async {
        guard let customer = selectedCustomer else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let account = try await bridge.createNessieAccount(
                customerId: customer.id,
                type: accountType,
                nickname: nickname,
                balance: initialBalance
            )
            
            successMessage = "Account created successfully! ID: \(account.id)"
            
            // Auto-dismiss after success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
            
        } catch {
            errorMessage = "Failed to create account: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    CreateAccountView(selectedCustomer: NessieCustomer(
        id: "preview_customer",
        firstName: "John",
        lastName: "Doe",
        address: NessieAddress(
            streetNumber: "123",
            streetName: "Main St",
            city: "Austin",
            state: "TX",
            zip: "78701"
        )
    ))
}
