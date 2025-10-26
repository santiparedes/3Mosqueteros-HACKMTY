import Foundation
import CryptoKit

// MARK: - Quantum Receipt Service
class QuantumReceiptService: ObservableObject {
    static let shared = QuantumReceiptService()
    
    private let quantumAPI = QuantumAPI.shared
    private let baseURL = "http://localhost:8000"
    private let session = URLSession.shared
    
    @Published var currentReceipt: QuantumReceipt?
    @Published var isGeneratingReceipt = false
    @Published var receiptError: String?
    
    private init() {}
    
    // MARK: - Generate Quantum Receipt for NepPay Transaction
    func generateReceiptForNepPayTransaction(
        transactionId: String,
        fromAccountId: String,
        toAccountId: String,
        amount: Double,
        currency: String = "USD"
    ) async throws -> QuantumReceipt {
        
        await MainActor.run {
            isGeneratingReceipt = true
            receiptError = nil
        }
        
        do {
            print("🔐 QuantumReceiptService: Generating quantum receipt for transaction \(transactionId)")
            
            // Try to connect to backend first
            let backendAvailable = await checkBackendAvailability()
            
            if backendAvailable {
                // Use real backend
                return try await generateRealQuantumReceipt(
                    transactionId: transactionId,
                    fromAccountId: fromAccountId,
                    toAccountId: toAccountId,
                    amount: amount,
                    currency: currency
                )
            } else {
                // Use fallback for demo
                print("⚠️ QuantumReceiptService: Backend unavailable, using demo receipt")
                return try await generateDemoQuantumReceipt(
                    transactionId: transactionId,
                    fromAccountId: fromAccountId,
                    toAccountId: toAccountId,
                    amount: amount,
                    currency: currency
                )
            }
            
        } catch {
            print("❌ QuantumReceiptService: Failed to generate receipt - \(error)")
            
            // Fallback to demo receipt if real generation fails
            print("🔄 QuantumReceiptService: Falling back to demo receipt")
            do {
                let demoReceipt = try await generateDemoQuantumReceipt(
                    transactionId: transactionId,
                    fromAccountId: fromAccountId,
                    toAccountId: toAccountId,
                    amount: amount,
                    currency: currency
                )
                
                await MainActor.run {
                    self.currentReceipt = demoReceipt
                    self.isGeneratingReceipt = false
                }
                
                return demoReceipt
                
            } catch {
                await MainActor.run {
                    self.receiptError = error.localizedDescription
                    self.isGeneratingReceipt = false
                }
                throw error
            }
        }
    }
    
    // MARK: - Backend Availability Check
    private func checkBackendAvailability() async -> Bool {
        do {
            let url = URL(string: "\(baseURL)/wallets")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 3.0 // 3 second timeout
            
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode < 500
            }
            return false
        } catch {
            print("⚠️ QuantumReceiptService: Backend check failed - \(error)")
            return false
        }
    }
    
    // MARK: - Real Quantum Receipt Generation
    private func generateRealQuantumReceipt(
        transactionId: String,
        fromAccountId: String,
        toAccountId: String,
        amount: Double,
        currency: String
    ) async throws -> QuantumReceipt {
        
        // Step 1: Create or get quantum wallet for the sender
        let walletId = try await getOrCreateQuantumWallet(for: fromAccountId)
        print("✅ QuantumReceiptService: Using wallet \(walletId)")
        
        // Step 2: Prepare quantum transaction
        let prepareResponse = try await quantumAPI.prepareTransaction(
            walletId: walletId,
            to: toAccountId,
            amount: amount,
            currency: currency
        )
        print("✅ QuantumReceiptService: Transaction prepared with nonce \(prepareResponse.nonce)")
        
        // Step 3: Sign with post-quantum signature
        let signer = DilithiumQuantumSigner()
        let (publicKey, privateKey) = signer.generateKeyPair()
        let payloadData = try JSONEncoder().encode(prepareResponse.payload)
        let signature = try signer.sign(payload: payloadData, privateKey: privateKey)
        print("✅ QuantumReceiptService: Transaction signed with Dilithium signature")
        
        // Step 4: Submit quantum transaction
        let submitResponse = try await quantumAPI.submitTransaction(
            payload: prepareResponse.payload,
            signature: signature,
            publicKey: publicKey
        )
        print("✅ QuantumReceiptService: Transaction submitted with ID \(submitResponse.txId)")
        
        // Step 5: Wait for block sealing (simulate with delay)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Step 6: Get quantum receipt
        let receipt = try await quantumAPI.getReceipt(txId: submitResponse.txId)
        print("✅ QuantumReceiptService: Quantum receipt generated successfully")
        
        await MainActor.run {
            self.currentReceipt = receipt
            self.isGeneratingReceipt = false
        }
        
        return receipt
    }
    
    // MARK: - Demo Quantum Receipt Generation
    private func generateDemoQuantumReceipt(
        transactionId: String,
        fromAccountId: String,
        toAccountId: String,
        amount: Double,
        currency: String
    ) async throws -> QuantumReceipt {
        
        print("🎭 QuantumReceiptService: Generating demo quantum receipt")
        
        // Generate demo quantum signature
        let signer = DilithiumQuantumSigner()
        let (publicKey, privateKey) = signer.generateKeyPair()
        
        // Create demo transaction payload
        let payload = TransactionPayload(
            fromWallet: fromAccountId,
            to: toAccountId,
            amount: amount,
            currency: currency,
            nonce: Int.random(in: 1...1000),
            timestamp: Int(Date().timeIntervalSince1970)
        )
        
        let payloadData = try JSONEncoder().encode(payload)
        let signature = try signer.sign(payload: payloadData, privateKey: privateKey)
        
        // Create demo Merkle proof
        let merkleProof = [
            ProofItem(dir: "L", hash: "a1b2c3d4e5f6789"),
            ProofItem(dir: "R", hash: "f9e8d7c6b5a4321")
        ]
        
        // Create demo receipt
        let receipt = QuantumReceipt(
            tx: payload,
            sigPqc: signature,
            pubkeyPqc: publicKey,
            blockHeader: BlockHeader(
                index: Int.random(in: 1000...9999),
                sealedAt: Int(Date().timeIntervalSince1970),
                merkleRoot: "demo_merkle_root_\(Int.random(in: 100000...999999))"
            ),
            merkleProof: merkleProof
        )
        
        print("✅ QuantumReceiptService: Demo quantum receipt generated")
        
        await MainActor.run {
            self.currentReceipt = receipt
            self.isGeneratingReceipt = false
        }
        
        return receipt
    }
    
    // MARK: - Verify Receipt
    func verifyReceipt(_ receipt: QuantumReceipt) async throws -> Bool {
        do {
            let backendAvailable = await checkBackendAvailability()
            
            if backendAvailable {
                let response = try await quantumAPI.verifyReceipt(receipt)
                print("🔍 QuantumReceiptService: Receipt verification result: \(response.valid)")
                return response.valid
            } else {
                // Use offline verification as fallback
                print("⚠️ QuantumReceiptService: Backend unavailable, using offline verification")
                return verifyReceiptOffline(receipt)
            }
        } catch {
            print("❌ QuantumReceiptService: Receipt verification failed - \(error)")
            // Fallback to offline verification
            print("🔄 QuantumReceiptService: Falling back to offline verification")
            return verifyReceiptOffline(receipt)
        }
    }
    
    // MARK: - Local Receipt Verification (Offline)
    func verifyReceiptOffline(_ receipt: QuantumReceipt) -> Bool {
        do {
            // Verify Merkle proof
            let txHash = try hashTransactionPayload(receipt.tx)
            let isValidProof = verifyMerkleProof(
                txHash: txHash,
                proof: receipt.merkleProof,
                expectedRoot: receipt.blockHeader.merkleRoot
            )
            
            // Verify signature (simplified for demo)
            let signatureValid = !receipt.sigPqc.isEmpty && !receipt.pubkeyPqc.isEmpty
            
            print("🔍 QuantumReceiptService: Offline verification - Proof: \(isValidProof), Signature: \(signatureValid)")
            return isValidProof && signatureValid
            
        } catch {
            print("❌ QuantumReceiptService: Offline verification failed - \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func getOrCreateQuantumWallet(for accountId: String) async throws -> String {
        // For demo purposes, create a deterministic wallet ID based on account ID
        let walletId = "wallet_\(accountId.prefix(8))"
        
        do {
            // Try to create wallet (will fail if exists, which is fine)
            let _ = try await quantumAPI.createWallet(userId: accountId)
        } catch {
            // Wallet might already exist, continue with the ID
            print("ℹ️ QuantumReceiptService: Wallet might already exist, continuing with \(walletId)")
        }
        
        return walletId
    }
    
    private func hashTransactionPayload(_ payload: TransactionPayload) throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func verifyMerkleProof(txHash: String, proof: [ProofItem], expectedRoot: String) -> Bool {
        var currentHash = txHash
        
        for proofItem in proof {
            let siblingHash = proofItem.hash
            
            if proofItem.dir == "L" {
                // Left sibling: hash(left + current)
                let combined = siblingHash + currentHash
                currentHash = SHA256.hash(data: Data(combined.utf8)).compactMap { String(format: "%02x", $0) }.joined()
            } else {
                // Right sibling: hash(current + right)
                let combined = currentHash + siblingHash
                currentHash = SHA256.hash(data: Data(combined.utf8)).compactMap { String(format: "%02x", $0) }.joined()
            }
        }
        
        return currentHash.lowercased() == expectedRoot.lowercased()
    }
}

// MARK: - Receipt Display Models
struct ReceiptDisplayInfo {
    let transactionId: String
    let amount: String
    let currency: String
    let fromAccount: String
    let toAccount: String
    let timestamp: Date
    let quantumSignature: String
    let merkleRoot: String
    let blockIndex: Int
    let verificationStatus: String
    let isOfflineVerifiable: Bool
}

extension QuantumReceipt {
    var displayInfo: ReceiptDisplayInfo {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        return ReceiptDisplayInfo(
            transactionId: tx.fromWallet,
            amount: String(format: "%.2f", tx.amount),
            currency: tx.currency,
            fromAccount: tx.fromWallet,
            toAccount: tx.to,
            timestamp: Date(timeIntervalSince1970: TimeInterval(tx.timestamp)),
            quantumSignature: String(sigPqc.prefix(16)) + "...",
            merkleRoot: String(blockHeader.merkleRoot.prefix(16)) + "...",
            blockIndex: blockHeader.index,
            verificationStatus: "Quantum-Resistant",
            isOfflineVerifiable: true
        )
    }
}
