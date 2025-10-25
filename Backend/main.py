from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Text, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel
from typing import List, Optional
import hashlib
import json
import time
from datetime import datetime
import uvicorn

# Database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./quantum_wallet.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Models
class Wallet(Base):
    __tablename__ = "wallets"
    
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, index=True)
    pubkey_pqc = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    device_binding_info = Column(Text)

class Transaction(Base):
    __tablename__ = "transactions"
    
    id = Column(String, primary_key=True, index=True)
    wallet_id = Column(String, index=True)
    to_wallet = Column(String)
    amount = Column(Float)
    currency = Column(String, default="MXN")
    nonce = Column(Integer)
    timestamp = Column(Integer)
    payload_hash = Column(String)
    sig_pqc = Column(Text)
    status = Column(String, default="pending")
    block_id = Column(String, nullable=True)

class Block(Base):
    __tablename__ = "blocks"
    
    id = Column(String, primary_key=True, index=True)
    index = Column(Integer, unique=True)
    sealed_at = Column(Integer)
    merkle_root = Column(String)
    anchor_ref = Column(String, nullable=True)

class MerkleProof(Base):
    __tablename__ = "merkle_proofs"
    
    tx_id = Column(String, primary_key=True)
    block_id = Column(String)
    proof_json = Column(Text)

# Create tables
Base.metadata.create_all(bind=engine)

# Pydantic models
class WalletCreate(BaseModel):
    user_id: str
    pubkey_pqc: Optional[str] = None

class WalletResponse(BaseModel):
    wallet_id: str
    pubkey_pqc: Optional[str] = None

class TransactionPrepare(BaseModel):
    wallet_id: str
    to: str
    amount: float
    currency: str = "MXN"

class TransactionPayload(BaseModel):
    from_wallet: str
    to: str
    amount: float
    currency: str
    nonce: int
    timestamp: int

class TransactionSubmit(BaseModel):
    payload: TransactionPayload
    sig_pqc: str
    pubkey_pqc: str

class BlockHeader(BaseModel):
    index: int
    sealed_at: int
    merkle_root: str

class ProofItem(BaseModel):
    dir: str  # "L" or "R"
    hash: str

class QuantumReceipt(BaseModel):
    tx: TransactionPayload
    sig_pqc: str
    pubkey_pqc: str
    block_header: BlockHeader
    merkle_proof: List[ProofItem]

class VerifyRequest(BaseModel):
    receipt: QuantumReceipt

class VerifyResponse(BaseModel):
    valid: bool
    reason: Optional[str] = None

# FastAPI app
app = FastAPI(title="Quantum Wallet API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Utility functions
def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def generate_id() -> str:
    return hashlib.sha256(str(time.time()).encode()).hexdigest()[:16]

def merkle_root_and_proofs(leaves: List[bytes]):
    """Build Merkle tree and return root + proofs for each leaf"""
    if not leaves:
        return sha256_hex(b""), []
    
    level = [sha256_hex(leaf) for leaf in leaves]
    proofs = [[] for _ in leaves]
    idx_map = list(range(len(leaves)))
    
    while len(level) > 1:
        next_level = []
        next_idx_map = []
        
        for i in range(0, len(level), 2):
            left = level[i]
            right = level[i+1] if i+1 < len(level) else left
            
            # Concatenate and hash
            parent = sha256_hex(bytes.fromhex(left) + bytes.fromhex(right))
            next_level.append(parent)
            
            # Record proof for children
            for child_pos, sibling in [(i, {"dir": "R", "hash": right}),
                                     (i+1 if i+1 < len(level) else i, {"dir": "L", "hash": left})]:
                if child_pos < len(idx_map):
                    proofs[idx_map[child_pos]].append(sibling)
            
            # Map children indices to parent index
            for child in [i, i+1]:
                if child < len(idx_map):
                    next_idx_map.append(len(next_level)-1)
        
        level = next_level
        idx_map = next_idx_map
    
    root = level[0] if level else sha256_hex(b"")
    return root, proofs

# API Endpoints
@app.post("/wallets", response_model=WalletResponse)
async def create_wallet(wallet_data: WalletCreate, db: Session = Depends(get_db)):
    wallet_id = generate_id()
    
    db_wallet = Wallet(
        id=wallet_id,
        user_id=wallet_data.user_id,
        pubkey_pqc=wallet_data.pubkey_pqc
    )
    db.add(db_wallet)
    db.commit()
    db.refresh(db_wallet)
    
    return WalletResponse(wallet_id=wallet_id, pubkey_pqc=wallet_data.pubkey_pqc)

@app.post("/tx/prepare")
async def prepare_transaction(tx_data: TransactionPrepare, db: Session = Depends(get_db)):
    # Get wallet and increment nonce
    wallet = db.query(Wallet).filter(Wallet.id == tx_data.wallet_id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")
    
    # Get last transaction to determine nonce
    last_tx = db.query(Transaction).filter(
        Transaction.wallet_id == tx_data.wallet_id
    ).order_by(Transaction.nonce.desc()).first()
    
    nonce = (last_tx.nonce + 1) if last_tx else 1
    timestamp = int(time.time())
    
    # Create payload
    payload = TransactionPayload(
        from_wallet=tx_data.wallet_id,
        to=tx_data.to,
        amount=tx_data.amount,
        currency=tx_data.currency,
        nonce=nonce,
        timestamp=timestamp
    )
    
    # Hash payload
    payload_json = payload.json()
    payload_hash = sha256_hex(payload_json.encode())
    
    return {
        "payload": payload,
        "payload_hash": payload_hash,
        "nonce": nonce
    }

@app.post("/tx/submit")
async def submit_transaction(tx_data: TransactionSubmit, db: Session = Depends(get_db)):
    # Create transaction record
    tx_id = generate_id()
    payload_hash = sha256_hex(tx_data.payload.json().encode())
    
    db_tx = Transaction(
        id=tx_id,
        wallet_id=tx_data.payload.from_wallet,
        to_wallet=tx_data.payload.to,
        amount=tx_data.payload.amount,
        currency=tx_data.payload.currency,
        nonce=tx_data.payload.nonce,
        timestamp=tx_data.payload.timestamp,
        payload_hash=payload_hash,
        sig_pqc=tx_data.sig_pqc,
        status="pending"
    )
    
    db.add(db_tx)
    db.commit()
    
    # Trigger block sealing if needed (simplified: seal every 3 transactions)
    pending_txs = db.query(Transaction).filter(Transaction.status == "pending").all()
    if len(pending_txs) >= 3:
        await seal_block(db)
    
    return {"tx_id": tx_id}

@app.get("/tx/{tx_id}/receipt", response_model=QuantumReceipt)
async def get_receipt(tx_id: str, db: Session = Depends(get_db)):
    tx = db.query(Transaction).filter(Transaction.id == tx_id).first()
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    if tx.status != "confirmed":
        raise HTTPException(status_code=400, detail="Transaction not yet confirmed")
    
    # Get block and merkle proof
    block = db.query(Block).filter(Block.id == tx.block_id).first()
    proof_record = db.query(MerkleProof).filter(MerkleProof.tx_id == tx_id).first()
    
    if not block or not proof_record:
        raise HTTPException(status_code=500, detail="Receipt data incomplete")
    
    # Parse merkle proof
    merkle_proof = [ProofItem(**item) for item in json.loads(proof_record.proof_json)]
    
    # Get wallet public key
    wallet = db.query(Wallet).filter(Wallet.id == tx.wallet_id).first()
    
    receipt = QuantumReceipt(
        tx=TransactionPayload(
            from_wallet=tx.wallet_id,
            to=tx.to_wallet,
            amount=tx.amount,
            currency=tx.currency,
            nonce=tx.nonce,
            timestamp=tx.timestamp
        ),
        sig_pqc=tx.sig_pqc,
        pubkey_pqc=wallet.pubkey_pqc or "",
        block_header=BlockHeader(
            index=block.index,
            sealed_at=block.sealed_at,
            merkle_root=block.merkle_root
        ),
        merkle_proof=merkle_proof
    )
    
    return receipt

@app.post("/verify", response_model=VerifyResponse)
async def verify_receipt(verify_req: VerifyRequest):
    try:
        # Verify signature (simplified - in real implementation, use PQC verification)
        payload_json = verify_req.receipt.tx.json()
        payload_hash = sha256_hex(payload_json.encode())
        
        # For demo purposes, we'll just check if signature exists
        if not verify_req.receipt.sig_pqc:
            return VerifyResponse(valid=False, reason="Missing signature")
        
        # Verify Merkle proof
        tx_hash = payload_hash
        for proof_item in verify_req.receipt.merkle_proof:
            if proof_item.dir == "L":
                combined = bytes.fromhex(proof_item.hash) + bytes.fromhex(tx_hash)
            else:
                combined = bytes.fromhex(tx_hash) + bytes.fromhex(proof_item.hash)
            tx_hash = sha256_hex(combined)
        
        if tx_hash.lower() != verify_req.receipt.block_header.merkle_root.lower():
            return VerifyResponse(valid=False, reason="Merkle proof verification failed")
        
        return VerifyResponse(valid=True)
        
    except Exception as e:
        return VerifyResponse(valid=False, reason=f"Verification error: {str(e)}")

async def seal_block(db: Session):
    """Seal pending transactions into a block"""
    pending_txs = db.query(Transaction).filter(Transaction.status == "pending").all()
    if not pending_txs:
        return
    
    # Create block
    block_id = generate_id()
    block_index = db.query(Block).count() + 1
    sealed_at = int(time.time())
    
    # Prepare transaction hashes for Merkle tree
    tx_hashes = []
    for tx in pending_txs:
        tx_hashes.append(tx.payload_hash.encode())
    
    # Build Merkle tree
    merkle_root, proofs = merkle_root_and_proofs(tx_hashes)
    
    # Create block record
    block = Block(
        id=block_id,
        index=block_index,
        sealed_at=sealed_at,
        merkle_root=merkle_root
    )
    db.add(block)
    
    # Update transactions and create proofs
    for i, tx in enumerate(pending_txs):
        tx.status = "confirmed"
        tx.block_id = block_id
        
        proof_record = MerkleProof(
            tx_id=tx.id,
            block_id=block_id,
            proof_json=json.dumps(proofs[i])
        )
        db.add(proof_record)
    
    db.commit()

@app.get("/")
async def root():
    return {"message": "Quantum Wallet API", "version": "1.0.0"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
