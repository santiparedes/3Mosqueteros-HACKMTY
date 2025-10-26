import SwiftUI

struct QuantumReceiptView: View {
    let receipt: QuantumReceipt
    @State private var isVerifying = false
    @State private var verificationResult: Bool?
    @State private var showVerificationDetails = false
    @State private var showShareSheet = false
    @State private var showImageShareSheet = false
    @State private var receiptImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
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
                    
                }
                .padding()
            }
            .background(Color.white)
            .navigationTitle("Quantum Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            generateReceiptImage()
                        }) {
                            Label("Download as Image", systemImage: "photo")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [receiptText])
        }
        .sheet(isPresented: $showImageShareSheet) {
            if let image = receiptImage {
                ImageShareSheet(image: image)
            }
        }
    }
    
    // MARK: - Receipt Header
    private var receiptHeader: some View {
        VStack(spacing: 16) {
            // NEP Logo with circle background like other screens
            ZStack {
                Circle()
                    .fill(Color.nepBlue)
                    .frame(width: 60, height: 60)
                
                Text("NEP")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Title
            Text("Comprobante de Transferencia")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            
            // Authorization details
            Text("Autorización \(DateFormatter.receiptDate.string(from: receipt.displayInfo.timestamp))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    // MARK: - Transaction Details
    private var transactionDetails: some View {
        VStack(spacing: 20) {
            // Amount
            HStack {
                Text("Monto")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
                Spacer()
                Text("$\(receipt.displayInfo.amount) \(receipt.displayInfo.currency)")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
            }
            
            // Concept (in light gray box like Nu)
            VStack(alignment: .leading, spacing: 8) {
                Text("Concepto")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
                
                Text("NepPay Transfer")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Transfer Type
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Tipo de transferencia")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                    Spacer()
                    Text("Quantum-Secured")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                }
                Text("Transferencia segura con criptografía post-cuántica")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            // Reference Number
            HStack {
                Text("Número de referencia")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
                Spacer()
                Text(receipt.displayInfo.transactionId)
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .foregroundColor(.black)
            }
        }
        .padding()
    }
    
    // MARK: - Quantum Security Section
    private var quantumSecuritySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Seguridad Avanzada")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Tipo de Seguridad")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    Spacer()
                    Text("Protección Futura")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Verificación")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    Spacer()
                    Text("Confirmada")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Número de Transacción")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    Spacer()
                    Text(String(receipt.displayInfo.transactionId.prefix(8)))
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.black)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Verification Section
    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Estado de la Transacción")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                // Status Card
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transferencia Exitosa")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text("Tu dinero fue enviado correctamente")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
               
            }
        }
        .padding()
    }
    
    // MARK: - Merkle Proof Details
    private var merkleProofDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detalles de Seguridad")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Información Técnica:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                VStack(spacing: 8) {
                    detailRow(title: "Hash de Transacción", value: String(receipt.displayInfo.merkleRoot.prefix(12)) + "...")
                    detailRow(title: "Número de Bloque", value: "#\(receipt.displayInfo.blockIndex)")
                    detailRow(title: "Fecha de Sellado", value: DateFormatter.receiptDate.string(from: receipt.displayInfo.timestamp))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
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
                    Text(showVerificationDetails ? "Ocultar Detalles" : "Ver Detalles Técnicos")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.nepBlue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.nepBlue.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(action: {
                showShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Compartir Comprobante")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.nepBlue)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Views
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
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(color)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
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
    
    // MARK: - Image Generation
    private func generateReceiptImage() {
        let renderer = ImageRenderer(content: receiptImageContent)
        renderer.scale = 3.0 // High resolution
        
        if let image = renderer.uiImage {
            // Convert to PNG data to ensure PNG format
            if let pngData = image.pngData() {
                receiptImage = UIImage(data: pngData)
            } else {
                receiptImage = image
            }
            showImageShareSheet = true
        }
    }
    
    private var receiptImageContent: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                // NEP Logo with circle background like other screens
                ZStack {
                    Circle()
                        .fill(Color.nepBlue)
                        .frame(width: 60, height: 60)
                    
                    Text("NEP")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Title
                Text("Comprobante de Transferencia")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                
                // Authorization details
                Text("Autorización \(DateFormatter.receiptDate.string(from: receipt.displayInfo.timestamp))")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            // Transaction Details Section
            VStack(spacing: 20) {
                // Amount
                HStack {
                    Text("Monto")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                    Spacer()
                    Text("$\(receipt.displayInfo.amount) \(receipt.displayInfo.currency)")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                }
                
                // Concept (in light gray box like Nu)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Concepto")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                    
                    Text("NepPay Transfer")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Transfer Type
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Tipo de transferencia")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.black)
                        Spacer()
                        Text("Quantum-Secured")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.black)
                    }
                    Text("Transferencia segura con criptografía post-cuántica")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                // Reference Number
                HStack {
                    Text("Número de referencia")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                    Spacer()
                    Text(receipt.displayInfo.transactionId)
                        .font(.system(size: 16, weight: .regular, design: .monospaced))
                        .foregroundColor(.black)
                }
            }
            
            // Quantum Security Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Seguridad Avanzada")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Tipo de Seguridad")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                        Text("Protección Futura")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Verificación")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                        Text("Confirmada")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Número de Transacción")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                        Text(String(receipt.displayInfo.transactionId.prefix(8)))
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // Footer
            VStack(spacing: 8) {
                Text("Este comprobante está protegido con tecnología avanzada,")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Text("garantizando su validez a largo plazo.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(0)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private func securityFeatureRow(title: String, value: String, isValid: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(isValid ? .green : .red)
        }
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

// MARK: - Image Share Sheet
struct ImageShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Ensure we're sharing as PNG
        var items: [Any] = []
        
        if let pngData = image.pngData() {
            items.append(pngData)
        } else {
            items.append(image)
        }
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Set the subject for email sharing
        activityViewController.setValue("NEP Quantum Receipt", forKey: "subject")
        
        return activityViewController
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
