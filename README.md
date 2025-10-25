# 🛡️ Quantum Wallet - Post-Quantum Cryptography for Secure Transactions

A hackathon project demonstrating post-quantum cryptography in a mobile wallet application with quantum-resistant digital receipts.

## 🎯 Project Overview

The Quantum Wallet implements a secure transaction system using:
- **Post-Quantum Cryptography (PQC)** signatures for transaction authentication
- **Merkle trees** for transaction integrity and inclusion proofs
- **Block-based sealing** for transaction finality
- **Offline verification** capabilities for quantum receipts

## 🏗️ Architecture

### iOS App (`3mosq/`)
- **SwiftUI** interface for wallet management
- **CryptoKit** for cryptographic operations
- **Ed25519** signatures (Plan B for demo, easily swappable to PQC)
- Real-time transaction flow with receipt generation

### Backend API (`Backend/`)
- **FastAPI** server with SQLite database
- **Merkle tree** implementation for transaction batching
- **Block sealing** mechanism (every 3 transactions)
- **RESTful API** for wallet and transaction operations

### Verification Tool (`verifier/`)
- **Pure HTML/JavaScript** offline receipt verifier
- **Client-side Merkle proof** verification
- **No external dependencies** - works completely offline

## 🚀 Quick Start

### 1. Start the Backend Server

```bash
cd Backend
pip install -r requirements.txt
python main.py
```

The API will be available at `http://localhost:8000`

### 2. Run the iOS App

1. Open `3mosq/3mosq.xcodeproj` in Xcode
2. Build and run on iOS Simulator or device
3. Navigate to the Quantum Wallet tab

### 3. Test the Verification Tool

```bash
cd verifier
open index.html
```

Or serve it with any web server:
```bash
python -m http.server 8001
# Then open http://localhost:8001
```

## 🧪 Testing

### Automated Test Suite

```bash
cd Backend
python test_quantum_wallet.py
```

The test suite includes:
- API health checks
- Wallet creation and management
- Transaction preparation and submission
- Receipt generation and verification
- Stress testing with multiple transactions

### Manual Testing Flow

1. **Create Wallet**: Generate quantum key pair and register with backend
2. **Send Payment**: Prepare, sign, and submit transaction
3. **Get Receipt**: Retrieve quantum receipt with Merkle proof
4. **Verify Offline**: Use the web verifier to validate receipt integrity

## 📊 API Endpoints

### Wallet Operations
- `POST /wallets` - Create new quantum wallet
- `GET /wallets/{id}` - Get wallet information

### Transaction Operations
- `POST /tx/prepare` - Prepare transaction payload
- `POST /tx/submit` - Submit signed transaction
- `GET /tx/{id}/receipt` - Get quantum receipt

### Verification
- `POST /verify` - Verify receipt integrity

## 🔐 Cryptographic Components

### Post-Quantum Signatures
- **Current**: Ed25519 (for demo purposes)
- **Future**: CRYSTALS-Dilithium 3 (NIST standardized)
- **Interface**: `QuantumSigner` protocol allows easy algorithm swapping

### Merkle Trees
- **Algorithm**: SHA-256 for all hashing operations
- **Structure**: Binary tree with left/right concatenation
- **Proofs**: Array of `{dir: "L"|"R", hash: hex}` objects

### Block Sealing
- **Trigger**: Every 3 transactions or time-based
- **Process**: Build Merkle tree → Generate proofs → Update status
- **Result**: All transactions marked as "confirmed"

## 📱 iOS App Features

### QuantumView
- **Wallet Creation**: Generate and register quantum key pairs
- **Payment Interface**: Send payments with real-time feedback
- **Receipt Display**: Show quantum receipts with verification
- **Offline Verification**: Local Merkle proof validation

### Key Components
- `QuantumAPI`: Network service for backend communication
- `Ed25519QuantumSigner`: Cryptographic signing implementation
- `MerkleVerifier`: Client-side proof verification
- `QuantumReceipt`: Data models for receipt structure

## 🌐 Web Verifier Features

### Offline Verification
- **Pure JavaScript**: No external dependencies
- **SHA-256**: Web Crypto API for hashing
- **Merkle Proofs**: Step-by-step verification process
- **Receipt Details**: Complete transaction information display

### Security Features
- **Local Processing**: No data sent to external servers
- **Cryptographic Integrity**: Full Merkle tree validation
- **Signature Verification**: PQC signature validation (mock for demo)

## 🔄 Transaction Flow

1. **Prepare**: Client requests transaction preparation with nonce
2. **Sign**: Client signs transaction payload with quantum key
3. **Submit**: Signed transaction sent to backend
4. **Batch**: Backend collects transactions for block sealing
5. **Seal**: Merkle tree built, proofs generated, block created
6. **Receipt**: Client retrieves quantum receipt with proof
7. **Verify**: Receipt can be verified offline or online

## 🎯 Hackathon Demo Script

### 30-Second Demo
1. **Create Wallet** (5s): Show key generation and registration
2. **Send Payment** (10s): Demonstrate transaction flow
3. **Show Receipt** (10s): Display quantum receipt details
4. **Verify Offline** (5s): Use web verifier to prove integrity

### Key Talking Points
- **Post-Quantum Ready**: Architecture supports PQC algorithms
- **Offline Verification**: Receipts work without internet
- **Merkle Proofs**: Cryptographic integrity guarantees
- **Block Sealing**: Transaction finality mechanism

## 🔮 Future Enhancements

### Phase 1: Production PQC
- Integrate CRYSTALS-Dilithium 3 via liboqs
- Device-side signing for enhanced security
- Hardware security module integration

### Phase 2: Advanced Features
- Multi-signature wallets
- Smart contract integration
- Cross-chain compatibility

### Phase 3: Enterprise Features
- Compliance reporting
- Audit trails
- Enterprise key management

## 🛠️ Development Notes

### PQC Implementation Strategy
- **Current**: Ed25519 with `QuantumSigner` protocol
- **Migration**: Replace `Ed25519QuantumSigner` with `DilithiumSigner`
- **Testing**: Same interface, different algorithm

### Database Schema
- **Wallets**: User accounts with PQC public keys
- **Transactions**: Signed transaction records
- **Blocks**: Sealed transaction batches
- **Merkle Proofs**: Inclusion proofs for each transaction

### Error Handling
- **Network**: Graceful degradation with retry logic
- **Cryptographic**: Clear error messages for key/signature issues
- **Verification**: Detailed failure reasons for debugging

## 📄 License

This project is developed for hackathon demonstration purposes.

## 🤝 Contributing

This is a hackathon project. For production use, additional security reviews and testing would be required.

---

**Built with ❤️ for HACKMTY 2024**

*Demonstrating the future of quantum-resistant cryptography in mobile applications*
