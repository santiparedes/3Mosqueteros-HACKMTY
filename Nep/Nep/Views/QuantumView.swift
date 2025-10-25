import SwiftUI

struct QuantumView: View {
    @StateObject private var quantumAPI = QuantumAPI.shared
    @StateObject private var signer = Ed25519QuantumSigner()
    
    @State private var walletId: String = ""
    @State private var publicKey: String = ""
    @State private var privateKey: String = ""
    @State private var recipientWallet: String = ""
    @State private var amount: String = ""
    @State private var currentReceipt: QuantumReceipt?
    @State private var verificationResult: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String = ""
    @State private var showReceipt = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Quantum Wallet")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Post-Quantum Cryptography for Secure Transactions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Wallet Setup Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wallet Setup")
                            .font(.headline)
                        
                        if walletId.isEmpty {
                            Button("Create Quantum Wallet") {
                                createWallet()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isLoading)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Wallet ID: \(walletId)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Public Key: \(publicKey.prefix(20))...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Transaction Section
                    if !walletId.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Send Payment")
                                .font(.headline)
                            
                            VStack(spacing: 12) {
                                TextField("Recipient Wallet ID", text: $recipientWallet)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("Amount (MXN)", text: $amount)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                
                                Button("Send Quantum Payment") {
                                    sendPayment()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isLoading || recipientWallet.isEmpty || amount.isEmpty)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Receipt Section
                    if let receipt = currentReceipt {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quantum Receipt")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Transaction ID: \(receipt.tx.fromWallet)")
                                    .font(.caption)
                                
                                Text("Amount: \(receipt.tx.amount) \(receipt.tx.currency)")
                                    .font(.caption)
                                
                                Text("Block: #\(receipt.blockHeader.index)")
                                    .font(.caption)
                                
                                Text("Merkle Root: \(receipt.blockHeader.merkleRoot.prefix(16))...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                            
                            HStack {
                                Button("Verify Receipt") {
                                    verifyReceipt(receipt)
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Show Full Receipt") {
                                    showReceipt = true
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            if !verificationResult.isEmpty {
                                Text(verificationResult)
                                    .foregroundColor(verificationResult.contains("✅") ? .green : .red)
                                    .font(.caption)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Loading Indicator
                    if isLoading {
                        ProgressView("Processing...")
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Quantum Wallet")
            .sheet(isPresented: $showReceipt) {
                if let receipt = currentReceipt {
                    ReceiptDetailView(receipt: receipt)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func createWallet() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Generate key pair
                let keyPair = signer.generateKeyPair()
                publicKey = keyPair.publicKey
                privateKey = keyPair.privateKey
                
                // Create wallet on server
                let response = try await quantumAPI.createWallet(
                    userId: "user_\(UUID().uuidString)",
                    pubkeyPqc: publicKey
                )
                
                await MainActor.run {
                    walletId = response.walletId
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create wallet: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func sendPayment() {
        guard let amountValue = Double(amount) else {
            errorMessage = "Invalid amount"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Prepare transaction
                let prepareResponse = try await quantumAPI.prepareTransaction(
                    walletId: walletId,
                    to: recipientWallet,
                    amount: amountValue
                )
                
                // Sign the payload
                let payloadData = try JSONEncoder().encode(prepareResponse.payload)
                let signature = try signer.sign(payload: payloadData, privateKey: privateKey)
                
                // Submit transaction
                let submitResponse = try await quantumAPI.submitTransaction(
                    payload: prepareResponse.payload,
                    signature: signature,
                    publicKey: publicKey
                )
                
                // Wait a moment for block sealing, then get receipt
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                let receipt = try await quantumAPI.getReceipt(txId: submitResponse.txId)
                
                await MainActor.run {
                    currentReceipt = receipt
                    isLoading = false
                    amount = ""
                    recipientWallet = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to send payment: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func verifyReceipt(_ receipt: QuantumReceipt) {
        Task {
            do {
                let response = try await quantumAPI.verifyReceipt(receipt)
                
                await MainActor.run {
                    if response.valid {
                        verificationResult = "✅ Receipt is valid and verified!"
                    } else {
                        verificationResult = "❌ Receipt verification failed: \(response.reason ?? "Unknown error")"
                    }
                }
            } catch {
                await MainActor.run {
                    verificationResult = "❌ Verification error: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Receipt Detail View
struct ReceiptDetailView: View {
    let receipt: QuantumReceipt
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quantum Receipt Details")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Transaction Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transaction")
                            .font(.headline)
                        
                        Text("From: \(receipt.tx.fromWallet)")
                        Text("To: \(receipt.tx.to)")
                        Text("Amount: \(receipt.tx.amount) \(receipt.tx.currency)")
                        Text("Nonce: \(receipt.tx.nonce)")
                        Text("Timestamp: \(Date(timeIntervalSince1970: TimeInterval(receipt.tx.timestamp)))")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Block Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Block Header")
                            .font(.headline)
                        
                        Text("Index: \(receipt.blockHeader.index)")
                        Text("Sealed At: \(Date(timeIntervalSince1970: TimeInterval(receipt.blockHeader.sealedAt)))")
                        Text("Merkle Root: \(receipt.blockHeader.merkleRoot)")
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Merkle Proof
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Merkle Proof")
                            .font(.headline)
                        
                        ForEach(Array(receipt.merkleProof.enumerated()), id: \.offset) { index, proof in
                            Text("Step \(index + 1): \(proof.dir) - \(proof.hash)")
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Signature
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PQC Signature")
                            .font(.headline)
                        
                        Text(receipt.sigPqc)
                            .font(.caption)
                            .lineLimit(nil)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Receipt")
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
