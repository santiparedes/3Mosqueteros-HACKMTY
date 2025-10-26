import SwiftUI

struct QuantumReceiptDemoView: View {
    @StateObject private var receiptService = QuantumReceiptService.shared
    @State private var generatedReceipt: QuantumReceipt?
    @State private var isGenerating = false
    @State private var showReceipt = false
    @State private var verificationResult: Bool?
    @State private var isVerifying = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    headerSection
                    
                    // Demo Controls
                    demoControlsSection
                    
                    // Quantum Security Info
                    quantumSecurityInfo
                    
                    // Receipt Preview
                    if let receipt = generatedReceipt {
                        receiptPreviewSection(receipt: receipt)
                    }
                    
                    // Verification Results
                    if let result = verificationResult {
                        verificationResultSection(result: result)
                    }
                }
                .padding()
            }
            .navigationTitle("Quantum Receipt Demo")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showReceipt) {
            if let receipt = generatedReceipt {
                QuantumReceiptView(receipt: receipt)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Quantum Shield Icon
            Image(systemName: "shield.checkered")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Quantum-Resistant Receipts")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Your transaction records stay verifiable tomorrow")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(20)
    }
    
    // MARK: - Demo Controls Section
    private var demoControlsSection: some View {
        VStack(spacing: 16) {
            Text("Demo Controls")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Generate Receipt Button
                Button(action: generateDemoReceipt) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text(isGenerating ? "Generating..." : "Generate Demo Receipt")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isGenerating)
                
                // View Receipt Button
                if let receipt = generatedReceipt {
                    Button(action: { showReceipt = true }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("View Full Receipt")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                // Verify Receipt Button
                if let receipt = generatedReceipt {
                    Button(action: { verifyReceipt(receipt) }) {
                        HStack {
                            if isVerifying {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.shield.fill")
                            }
                            Text(isVerifying ? "Verifying..." : "Verify Receipt")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isVerifying)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Quantum Security Info
    private var quantumSecurityInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quantum Security Features")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                securityFeatureCard(
                    icon: "lock.shield",
                    title: "Post-Quantum Signatures",
                    description: "CRYSTALS-Dilithium algorithm",
                    details: "NIST-approved quantum-resistant signatures that remain secure even after quantum computers become available.",
                    color: .blue
                )
                
                securityFeatureCard(
                    icon: "tree",
                    title: "Merkle Tree Proofs",
                    description: "Cryptographic integrity verification",
                    details: "Mathematical proof that your transaction is included in the blockchain without revealing other transactions.",
                    color: .green
                )
                
                securityFeatureCard(
                    icon: "wifi.slash",
                    title: "Offline Verification",
                    description: "Works without internet connection",
                    details: "Verify receipt authenticity completely offline using cryptographic proofs and signatures.",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Receipt Preview Section
    private func receiptPreviewSection(receipt: QuantumReceipt) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generated Receipt")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                receiptDetailRow(title: "Transaction ID", value: receipt.tx.fromWallet)
                receiptDetailRow(title: "Amount", value: "$\(String(format: "%.2f", receipt.tx.amount)) \(receipt.tx.currency)")
                receiptDetailRow(title: "From", value: receipt.tx.fromWallet)
                receiptDetailRow(title: "To", value: receipt.tx.to)
                receiptDetailRow(title: "Block Index", value: "#\(receipt.blockHeader.index)")
                receiptDetailRow(title: "Merkle Root", value: String(receipt.blockHeader.merkleRoot.prefix(16)) + "...")
                receiptDetailRow(title: "Signature", value: String(receipt.sigPqc.prefix(16)) + "...")
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Verification Result Section
    private func verificationResultSection(result: Bool) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(result ? .green : .red)
                
                Text(result ? "Verification Successful" : "Verification Failed")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(result ? .green : .red)
            }
            
            Text(result ? 
                 "This receipt is authentic and quantum-resistant. It will remain verifiable even after quantum computers become available." :
                 "This receipt could not be verified. Please check the signature and Merkle proof.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(result ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Views
    private func securityFeatureCard(icon: String, title: String, description: String, details: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func receiptDetailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .fontFamily(.monospaced)
        }
    }
    
    // MARK: - Actions
    private func generateDemoReceipt() {
        isGenerating = true
        
        Task {
            do {
                let receipt = try await receiptService.generateReceiptForNepPayTransaction(
                    transactionId: "demo_tx_\(Int.random(in: 100000...999999))",
                    fromAccountId: "demo_sender_123",
                    toAccountId: "demo_receiver_456",
                    amount: Double.random(in: 10...500),
                    currency: "USD"
                )
                
                await MainActor.run {
                    self.generatedReceipt = receipt
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                }
                print("Failed to generate demo receipt: \(error)")
            }
        }
    }
    
    private func verifyReceipt(_ receipt: QuantumReceipt) {
        isVerifying = true
        
        Task {
            do {
                let isValid = try await receiptService.verifyReceipt(receipt)
                await MainActor.run {
                    verificationResult = isValid
                    isVerifying = false
                }
            } catch {
                await MainActor.run {
                    verificationResult = false
                    isVerifying = false
                }
            }
        }
    }
}

// MARK: - Preview
struct QuantumReceiptDemoView_Previews: PreviewProvider {
    static var previews: some View {
        QuantumReceiptDemoView()
    }
}
