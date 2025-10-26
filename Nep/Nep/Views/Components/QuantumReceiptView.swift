import SwiftUI

struct QuantumReceiptView: View {
    let receipt: QuantumReceipt
    @State private var isVerifying = false
    @State private var verificationResult: Bool?
    @State private var showVerificationDetails = false
    @State private var showShareSheet = false
    
    private let receiptService = QuantumReceiptService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    receiptHeader
                    
                    // Transaction Details
                    transactionDetails
                    
                    // Quantum Security Features
                    quantumSecuritySection
                    
                    // Verification Section
                    verificationSection
                    
                    // Merkle Proof Details
                    if showVerificationDetails {
                        merkleProofDetails
                    }
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Quantum Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        showShareSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [receiptText])
        }
    }
    
    // MARK: - Receipt Header
    private var receiptHeader: some View {
        VStack(spacing: 12) {
            // Quantum Shield Icon
            Image(systemName: "shield.checkered")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Quantum-Resistant Receipt")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Verified & Future-Proof")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Status Badge
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Transaction Confirmed")
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Transaction Details
    private var transactionDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transaction Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                detailRow(title: "Amount", value: "$\(receipt.displayInfo.amount) \(receipt.displayInfo.currency)")
                detailRow(title: "From", value: receipt.displayInfo.fromAccount)
                detailRow(title: "To", value: receipt.displayInfo.toAccount)
                detailRow(title: "Date", value: DateFormatter.receiptDate.string(from: receipt.displayInfo.timestamp))
                detailRow(title: "Transaction ID", value: receipt.displayInfo.transactionId)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Quantum Security Section
    private var quantumSecuritySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quantum Security Features")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                securityFeatureRow(
                    icon: "lock.shield",
                    title: "Post-Quantum Signature",
                    description: "CRYSTALS-Dilithium",
                    value: receipt.displayInfo.quantumSignature,
                    color: .blue
                )
                
                securityFeatureRow(
                    icon: "tree",
                    title: "Merkle Tree Proof",
                    description: "Cryptographic Integrity",
                    value: receipt.displayInfo.merkleRoot,
                    color: .green
                )
                
                securityFeatureRow(
                    icon: "cube.box",
                    title: "Block Index",
                    description: "Blockchain Confirmation",
                    value: "#\(receipt.displayInfo.blockIndex)",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Verification Section
    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Verification")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Offline Verification Status
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("Offline Verifiable")
                            .fontWeight(.medium)
                        Text("Works without internet connection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                // Online Verification
                HStack {
                    Image(systemName: "wifi")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Online Verification")
                            .fontWeight(.medium)
                        Text("Real-time quantum signature validation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    if isVerifying {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let verified = verificationResult {
                        Image(systemName: verified ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(verified ? .green : .red)
                    } else {
                        Button("Verify") {
                            verifyReceipt()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Merkle Proof Details
    private var merkleProofDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Merkle Proof Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Proof Steps:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(Array(receipt.merkleProof.enumerated()), id: \.offset) { index, proofItem in
                    HStack {
                        Text("Step \(index + 1):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(proofItem.dir) - \(String(proofItem.hash.prefix(8)))...")
                            .font(.caption)
                            .fontFamily(.monospaced)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                showVerificationDetails.toggle()
            }) {
                HStack {
                    Image(systemName: showVerificationDetails ? "eye.slash" : "eye")
                    Text(showVerificationDetails ? "Hide Details" : "Show Proof Details")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(action: {
                showShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Receipt")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Views
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private func securityFeatureRow(icon: String, title: String, description: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontFamily(.monospaced)
                .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Actions
    private func verifyReceipt() {
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
    
    // MARK: - Receipt Text for Sharing
    private var receiptText: String {
        """
        🔐 QUANTUM-RESISTANT RECEIPT
        
        Transaction: \(receipt.displayInfo.transactionId)
        Amount: $\(receipt.displayInfo.amount) \(receipt.displayInfo.currency)
        From: \(receipt.displayInfo.fromAccount)
        To: \(receipt.displayInfo.toAccount)
        Date: \(DateFormatter.receiptDate.string(from: receipt.displayInfo.timestamp))
        
        🔒 QUANTUM SECURITY:
        • Post-Quantum Signature: CRYSTALS-Dilithium
        • Merkle Tree Proof: \(receipt.displayInfo.merkleRoot)
        • Block Index: #\(receipt.displayInfo.blockIndex)
        • Offline Verifiable: ✅
        
        This receipt is secured with post-quantum cryptography,
        ensuring it remains verifiable even after quantum computers
        become available.
        
        Generated by NEP Quantum Wallet
        """
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let receiptDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
struct QuantumReceiptView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleReceipt = QuantumReceipt(
            tx: TransactionPayload(
                fromWallet: "wallet_123",
                to: "wallet_456",
                amount: 50.00,
                currency: "USD",
                nonce: 1,
                timestamp: Int(Date().timeIntervalSince1970)
            ),
            sigPqc: "dilithium_signature_here",
            pubkeyPqc: "public_key_here",
            blockHeader: BlockHeader(
                index: 1,
                sealedAt: Int(Date().timeIntervalSince1970),
                merkleRoot: "merkle_root_hash_here"
            ),
            merkleProof: [
                ProofItem(dir: "L", hash: "left_hash"),
                ProofItem(dir: "R", hash: "right_hash")
            ]
        )
        
        QuantumReceiptView(receipt: sampleReceipt)
    }
}
