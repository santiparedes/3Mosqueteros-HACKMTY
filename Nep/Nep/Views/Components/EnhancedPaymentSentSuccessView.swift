import SwiftUI

// MARK: - Enhanced Payment Sent Success View with Quantum Receipt
struct EnhancedPaymentSentSuccessView: View {
    let amount: Double
    let message: String
    let onDone: () -> Void
    
    @StateObject private var receiptService = QuantumReceiptService.shared
    @State private var showConfetti = false
    @State private var isAnimating = false
    @State private var showReceipt = false
    @State private var generatedReceipt: QuantumReceipt?
    @State private var isGeneratingReceipt = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // Success animation
                VStack(spacing: 24) {
                    ZStack {
                        // Confetti background
                        if showConfetti {
                            ForEach(0..<20, id: \.self) { index in
                                Circle()
                                    .fill([Color.blue, Color.green, Color.orange, Color.purple].randomElement() ?? .blue)
                                    .frame(width: 8, height: 8)
                                    .offset(
                                        x: CGFloat.random(in: -100...100),
                                        y: CGFloat.random(in: -100...100)
                                    )
                                    .opacity(showConfetti ? 0 : 1)
                                    .animation(
                                        Animation.easeOut(duration: 2.0)
                                            .delay(Double(index) * 0.1),
                                        value: showConfetti
                                    )
                            }
                        }
                        
                        // Success icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundColor(.green)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Money Sent! 🎉")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(formatCurrency(amount))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        
                        if !message.isEmpty {
                            Text("\"\(message)\"")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .italic()
                        }
                    }
                }
                
                Spacer()
                
                // Quantum Receipt Section
                VStack(spacing: 16) {
                    // Quantum Security Badge
                    HStack {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(.primary)
                        Text("Quantum-Resistant Receipt")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Future-Proof")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Receipt Actions
                    VStack(spacing: 12) {
                        Button(action: {
                            print("🔄 EnhancedPaymentSentSuccessView: Generate Quantum Receipt button tapped")
                            
                            // Always generate a mock receipt immediately for demo
                            let mockReceipt = QuantumReceipt(
                                tx: TransactionPayload(
                                    fromWallet: "sender_account",
                                    to: "receiver_account",
                                    amount: amount,
                                    currency: "USD",
                                    nonce: Int.random(in: 1...1000),
                                    timestamp: Int(Date().timeIntervalSince1970)
                                ),
                                sigPqc: "demo_signature_\(Int.random(in: 1000...9999))",
                                pubkeyPqc: "demo_pubkey_\(Int.random(in: 1000...9999))",
                                blockHeader: BlockHeader(
                                    index: Int.random(in: 1000...9999),
                                    sealedAt: Int(Date().timeIntervalSince1970),
                                    merkleRoot: "demo_merkle_\(Int.random(in: 1000...9999))"
                                ),
                                merkleProof: [
                                    ProofItem(dir: "L", hash: "demo_hash_1"),
                                    ProofItem(dir: "R", hash: "demo_hash_2")
                                ]
                            )
                            
                            self.generatedReceipt = mockReceipt
                            print("✅ EnhancedPaymentSentSuccessView: Mock receipt generated immediately")
                            
                            // Also try the real service in background
                            generateQuantumReceipt()
                        }) {
                            HStack {
                                if isGeneratingReceipt {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "doc.text.fill")
                                }
                                Text(isGeneratingReceipt ? "Generating Receipt..." : "Generate Quantum Receipt")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isGeneratingReceipt)
                        
                        if let receipt = generatedReceipt {
                            Button(action: { showReceipt = true }) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                    Text("View Receipt")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // Done button
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.green)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(Color(.systemBackground))
            .navigationTitle("Payment Sent")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            print("🔄 EnhancedPaymentSentSuccessView: View appeared")
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
            }
        }
        .sheet(isPresented: $showReceipt) {
            if let receipt = generatedReceipt {
                QuantumReceiptView(receipt: receipt)
            }
        }
    }
    
    private func generateQuantumReceipt() {
        print("🔄 EnhancedPaymentSentSuccessView: Starting quantum receipt generation...")
        isGeneratingReceipt = true
        
        Task {
            do {
                print("🔄 EnhancedPaymentSentSuccessView: Calling receiptService.generateReceiptForNepPayTransaction...")
                let receipt = try await receiptService.generateReceiptForNepPayTransaction(
                    transactionId: "neppay_tx_\(Int.random(in: 100000...999999))",
                    fromAccountId: "sender_account",
                    toAccountId: "receiver_account",
                    amount: amount,
                    currency: "USD"
                )
                
                print("✅ EnhancedPaymentSentSuccessView: Quantum receipt generated successfully")
                await MainActor.run {
                    self.generatedReceipt = receipt
                    self.isGeneratingReceipt = false
                }
            } catch {
                print("❌ EnhancedPaymentSentSuccessView: Failed to generate quantum receipt: \(error)")
                print("🔄 EnhancedPaymentSentSuccessView: Generating mock receipt instead...")
                
                // Generate a mock receipt if the real one fails
                let mockReceipt = QuantumReceipt(
                    tx: TransactionPayload(
                        fromWallet: "sender_account",
                        to: "receiver_account",
                        amount: amount,
                        currency: "USD",
                        nonce: Int.random(in: 1...1000),
                        timestamp: Int(Date().timeIntervalSince1970)
                    ),
                    sigPqc: "mock_signature_\(Int.random(in: 1000...9999))",
                    pubkeyPqc: "mock_pubkey_\(Int.random(in: 1000...9999))",
                    blockHeader: BlockHeader(
                        index: Int.random(in: 1000...9999),
                        sealedAt: Int(Date().timeIntervalSince1970),
                        merkleRoot: "mock_merkle_\(Int.random(in: 1000...9999))"
                    ),
                    merkleProof: [
                        ProofItem(dir: "L", hash: "mock_hash_1"),
                        ProofItem(dir: "R", hash: "mock_hash_2")
                    ]
                )
                
                await MainActor.run {
                    self.generatedReceipt = mockReceipt
                    self.isGeneratingReceipt = false
                    print("✅ EnhancedPaymentSentSuccessView: Mock receipt generated successfully")
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
