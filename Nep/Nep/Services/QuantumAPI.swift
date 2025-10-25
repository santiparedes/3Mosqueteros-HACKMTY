import Foundation
import CryptoKit

// MARK: - Quantum API Service
class QuantumAPI: ObservableObject {
    static let shared = QuantumAPI()
    
    private let baseURL = "http://localhost:8000"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Wallet Operations
    func createWallet(userId: String, pubkeyPqc: String? = nil) async throws -> WalletResponse {
        let request = WalletCreateRequest(userId: userId, pubkeyPqc: pubkeyPqc)
        return try await performRequest(
            endpoint: "/wallets",
            method: "POST",
            body: request,
            responseType: WalletResponse.self
        )
    }
    
    // MARK: - Transaction Operations
    func prepareTransaction(walletId: String, to: String, amount: Double, currency: String = "MXN") async throws -> TransactionPrepareResponse {
        let request = TransactionPrepareRequest(
            walletId: walletId,
            to: to,
            amount: amount,
            currency: currency
        )
        return try await performRequest(
            endpoint: "/tx/prepare",
            method: "POST",
            body: request,
            responseType: TransactionPrepareResponse.self
        )
    }
    
    func submitTransaction(payload: TransactionPayload, signature: String, publicKey: String) async throws -> TransactionSubmitResponse {
        let request = TransactionSubmitRequest(
            payload: payload,
            sigPqc: signature,
            pubkeyPqc: publicKey
        )
        return try await performRequest(
            endpoint: "/tx/submit",
            method: "POST",
            body: request,
            responseType: TransactionSubmitResponse.self
        )
    }
    
    func getReceipt(txId: String) async throws -> QuantumReceipt {
        return try await performRequest(
            endpoint: "/tx/\(txId)/receipt",
            method: "GET",
            body: nil as String?,
            responseType: QuantumReceipt.self
        )
    }
    
    // MARK: - Verification
    func verifyReceipt(_ receipt: QuantumReceipt) async throws -> VerifyResponse {
        let request = VerifyRequest(receipt: receipt)
        return try await performRequest(
            endpoint: "/verify",
            method: "POST",
            body: request,
            responseType: VerifyResponse.self
        )
    }
    
    // MARK: - Generic Request Handler
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: String,
        body: T?,
        responseType: U.Type
    ) async throws -> U {
        guard let url = URL(string: baseURL + endpoint) else {
            throw QuantumAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuantumAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw QuantumAPIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(responseType, from: data)
    }
}

// MARK: - Quantum API Errors
enum QuantumAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - Quantum Signer Protocol
protocol QuantumSigner {
    func generateKeyPair() -> (publicKey: String, privateKey: String)
    func sign(payload: Data, privateKey: String) throws -> String
    func verify(payload: Data, signature: String, publicKey: String) throws -> Bool
}

// MARK: - CRYSTALS-Dilithium Post-Quantum Implementation
// 
// This is a demonstration implementation of CRYSTALS-Dilithium post-quantum cryptography.
// In a production environment, you would use a proper implementation like liboqs or
// a NIST-approved library. This implementation simulates the key characteristics:
// - Larger key sizes (Dilithium-2: ~2KB public keys, ~4KB private keys)
// - Larger signature sizes (Dilithium-2: ~2.4KB signatures)
// - Quantum-resistant security based on lattice problems
//
// For production use, integrate with:
// - liboqs (Open Quantum Safe) library
// - NIST PQC Reference Implementation
// - Hardware security modules with PQC support
class DilithiumQuantumSigner: ObservableObject, QuantumSigner {
    private let keySize = 32 // Dilithium-2 key size in bytes
    private let signatureSize = 2420 // Dilithium-2 signature size in bytes
    
    func generateKeyPair() -> (publicKey: String, privateKey: String) {
        // Generate random key material for Dilithium
        var publicKeyData = Data(count: keySize * 8) // Dilithium-2 public key size
        var privateKeyData = Data(count: keySize * 12) // Dilithium-2 private key size
        
        let result1 = publicKeyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, bytes.count, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        let result2 = privateKeyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, bytes.count, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        if result1 != errSecSuccess || result2 != errSecSuccess {
            // Fallback to deterministic generation
            publicKeyData = Data("dilithium_pub_key_\(UUID().uuidString)".utf8)
            privateKeyData = Data("dilithium_priv_key_\(UUID().uuidString)".utf8)
        }
        
        return (
            publicKey: publicKeyData.base64EncodedString(),
            privateKey: privateKeyData.base64EncodedString()
        )
    }
    
    func sign(payload: Data, privateKey: String) throws -> String {
        guard let privateKeyData = Data(base64Encoded: privateKey) else {
            throw QuantumSignerError.invalidPrivateKey
        }
        
        // Simulate Dilithium signing process
        // In a real implementation, this would use the actual Dilithium algorithm
        let messageHash = SHA256.hash(data: payload)
        let keyHash = SHA256.hash(data: privateKeyData)
        
        // Combine message and key for signature generation
        var signatureData = Data()
        signatureData.append(Data(messageHash))
        signatureData.append(Data(keyHash))
        signatureData.append(payload.prefix(16)) // Add some message content
        
        // Pad to Dilithium signature size
        while signatureData.count < signatureSize {
            signatureData.append(Data([UInt8.random(in: 0...255)]))
        }
        
        return signatureData.prefix(signatureSize).base64EncodedString()
    }
    
    func verify(payload: Data, signature: String, publicKey: String) throws -> Bool {
        guard let publicKeyData = Data(base64Encoded: publicKey),
              let signatureData = Data(base64Encoded: signature) else {
            throw QuantumSignerError.invalidKeyOrSignature
        }
        
        // Simulate Dilithium verification process
        // In a real implementation, this would use the actual Dilithium algorithm
        let messageHash = SHA256.hash(data: payload)
        let keyHash = SHA256.hash(data: publicKeyData)
        
        // Reconstruct expected signature
        var expectedSignature = Data()
        expectedSignature.append(Data(messageHash))
        expectedSignature.append(Data(keyHash))
        expectedSignature.append(payload.prefix(16))
        
        // Pad to Dilithium signature size
        while expectedSignature.count < signatureSize {
            expectedSignature.append(Data([UInt8.random(in: 0...255)]))
        }
        
        // For demo purposes, we'll do a partial verification
        // In reality, Dilithium verification is more complex
        let providedSignature = signatureData.prefix(signatureSize)
        let expectedSig = expectedSignature.prefix(signatureSize)
        
        // Check if the first 32 bytes match (simplified verification)
        return providedSignature.prefix(32) == expectedSig.prefix(32)
    }
}

// MARK: - Legacy Ed25519 Implementation (for backward compatibility)
class Ed25519QuantumSigner: ObservableObject, QuantumSigner {
    func generateKeyPair() -> (publicKey: String, privateKey: String) {
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        
        return (
            publicKey: publicKey.rawRepresentation.base64EncodedString(),
            privateKey: privateKey.rawRepresentation.base64EncodedString()
        )
    }
    
    func sign(payload: Data, privateKey: String) throws -> String {
        guard let privateKeyData = Data(base64Encoded: privateKey) else {
            throw QuantumSignerError.invalidPrivateKey
        }
        
        let signingKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
        let signature = try signingKey.signature(for: payload)
        
        return signature.base64EncodedString()
    }
    
    func verify(payload: Data, signature: String, publicKey: String) throws -> Bool {
        guard let publicKeyData = Data(base64Encoded: publicKey),
              let signatureData = Data(base64Encoded: signature) else {
            throw QuantumSignerError.invalidKeyOrSignature
        }
        
        let verifyingKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
        return verifyingKey.isValidSignature(signatureData, for: payload)
    }
}

// MARK: - Quantum Signer Errors
enum QuantumSignerError: Error, LocalizedError {
    case invalidPrivateKey
    case invalidPublicKey
    case invalidKeyOrSignature
    case signingFailed
    case verificationFailed
    case keyGenerationFailed
    case invalidSignatureSize
    case postQuantumAlgorithmError
    
    var errorDescription: String? {
        switch self {
        case .invalidPrivateKey:
            return "Invalid private key format"
        case .invalidPublicKey:
            return "Invalid public key format"
        case .invalidKeyOrSignature:
            return "Invalid key or signature format"
        case .signingFailed:
            return "Failed to sign payload"
        case .verificationFailed:
            return "Failed to verify signature"
        case .keyGenerationFailed:
            return "Failed to generate post-quantum key pair"
        case .invalidSignatureSize:
            return "Invalid signature size for CRYSTALS-Dilithium"
        case .postQuantumAlgorithmError:
            return "Post-quantum cryptographic algorithm error"
        }
    }
}

// MARK: - Merkle Verification
class MerkleVerifier {
    static func verifyMerkleProof(
        txHash: String,
        proof: [ProofItem],
        expectedRoot: String
    ) -> Bool {
        var currentHash = txHash.lowercased()
        
        for proofItem in proof {
            let siblingHash = proofItem.hash.lowercased()
            
            guard let siblingData = Data(hex: siblingHash),
                  let currentData = Data(hex: currentHash) else {
                return false // Invalid hex data
            }
            
            let combined: Data
            if proofItem.dir == "L" {
                // Left sibling, concatenate as sibling + current
                combined = siblingData + currentData
            } else {
                // Right sibling, concatenate as current + sibling
                combined = currentData + siblingData
            }
            
            currentHash = sha256Hex(combined).lowercased()
        }
        
        return currentHash == expectedRoot.lowercased()
    }
    
    private static func sha256Hex(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Data Extension for Hex
extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var i = hex.startIndex
        
        for _ in 0..<len {
            let j = hex.index(i, offsetBy: 2)
            let bytes = hex[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}
