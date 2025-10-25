import Foundation

// MARK: - Quantum Receipt Models
struct QuantumReceipt: Codable, Identifiable {
    let id: String
    let tx: TransactionPayload
    let sigPqc: String
    let pubkeyPqc: String
    let blockHeader: BlockHeader
    let merkleProof: [ProofItem]
    
    enum CodingKeys: String, CodingKey {
        case id
        case tx
        case sigPqc = "sig_pqc"
        case pubkeyPqc = "pubkey_pqc"
        case blockHeader = "block_header"
        case merkleProof = "merkle_proof"
    }
    
    // Custom initializer to generate ID if not provided
    init(tx: TransactionPayload, sigPqc: String, pubkeyPqc: String, blockHeader: BlockHeader, merkleProof: [ProofItem], id: String? = nil) {
        self.tx = tx
        self.sigPqc = sigPqc
        self.pubkeyPqc = pubkeyPqc
        self.blockHeader = blockHeader
        self.merkleProof = merkleProof
        self.id = id ?? UUID().uuidString
    }
}

struct TransactionPayload: Codable {
    let fromWallet: String
    let to: String
    let amount: Double
    let currency: String
    let nonce: Int
    let timestamp: Int
    
    enum CodingKeys: String, CodingKey {
        case fromWallet = "from_wallet"
        case to, amount, currency, nonce, timestamp
    }
}

struct BlockHeader: Codable {
    let index: Int
    let sealedAt: Int
    let merkleRoot: String
    
    enum CodingKeys: String, CodingKey {
        case index
        case sealedAt = "sealed_at"
        case merkleRoot = "merkle_root"
    }
}

struct ProofItem: Codable {
    let dir: String // "L" or "R"
    let hash: String
}

// MARK: - API Request/Response Models
struct WalletCreateRequest: Codable {
    let userId: String
    let pubkeyPqc: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case pubkeyPqc = "pubkey_pqc"
    }
}

struct WalletResponse: Codable {
    let walletId: String
    let pubkeyPqc: String?
    
    enum CodingKeys: String, CodingKey {
        case walletId = "wallet_id"
        case pubkeyPqc = "pubkey_pqc"
    }
}

struct TransactionPrepareRequest: Codable {
    let walletId: String
    let to: String
    let amount: Double
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case walletId = "wallet_id"
        case to, amount, currency
    }
}

struct TransactionPrepareResponse: Codable {
    let payload: TransactionPayload
    let payloadHash: String
    let nonce: Int
    
    enum CodingKeys: String, CodingKey {
        case payload
        case payloadHash = "payload_hash"
        case nonce
    }
}

struct TransactionSubmitRequest: Codable {
    let payload: TransactionPayload
    let sigPqc: String
    let pubkeyPqc: String
    
    enum CodingKeys: String, CodingKey {
        case payload
        case sigPqc = "sig_pqc"
        case pubkeyPqc = "pubkey_pqc"
    }
}

struct TransactionSubmitResponse: Codable {
    let txId: String
    
    enum CodingKeys: String, CodingKey {
        case txId = "tx_id"
    }
}

struct VerifyRequest: Codable {
    let receipt: QuantumReceipt
}

struct VerifyResponse: Codable {
    let valid: Bool
    let reason: String?
}
