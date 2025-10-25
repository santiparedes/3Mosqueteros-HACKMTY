import requests
import json
from typing import Dict, List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

# Nessie API Configuration
NESSIE_API_KEY = "2efca97355951ec13f6acfd0a8806a14"
NESSIE_BASE_URL = "http://api.nessieisreal.com"

router = APIRouter(prefix="/nessie", tags=["Nessie Integration"])

# Pydantic models for Nessie API
class NessieCustomer(BaseModel):
    first_name: str
    last_name: str
    address: Dict[str, str]

class NessieAccount(BaseModel):
    type: str
    nickname: str
    rewards: int = 0
    balance: float

class NessieTransaction(BaseModel):
    medium: str = "balance"
    payee_id: str
    amount: float
    description: str

class QuantumNessieWallet(BaseModel):
    quantum_wallet_id: str
    nessie_customer_id: str
    nessie_account_id: str
    user_id: str

def make_nessie_request(endpoint: str, method: str = "GET", data: Optional[Dict] = None) -> Dict:
    """Make authenticated request to Nessie API"""
    url = f"{NESSIE_BASE_URL}{endpoint}?key={NESSIE_API_KEY}"
    
    try:
        if method == "GET":
            response = requests.get(url)
        elif method == "POST":
            response = requests.post(url, json=data)
        elif method == "PUT":
            response = requests.put(url, json=data)
        elif method == "DELETE":
            response = requests.delete(url)
        
        if response.status_code in [200, 201]:
            return response.json()
        else:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Nessie API Error: {response.text}"
            )
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Connection error: {str(e)}")

@router.get("/customers")
async def get_customers():
    """Get all customers from Nessie"""
    return make_nessie_request("/customers")

@router.post("/customers")
async def create_customer(customer: NessieCustomer):
    """Create a new customer in Nessie"""
    customer_data = {
        "first_name": customer.first_name,
        "last_name": customer.last_name,
        "address": customer.address
    }
    return make_nessie_request("/customers", "POST", customer_data)

@router.get("/customers/{customer_id}/accounts")
async def get_customer_accounts(customer_id: str):
    """Get all accounts for a customer"""
    return make_nessie_request(f"/customers/{customer_id}/accounts")

@router.post("/customers/{customer_id}/accounts")
async def create_account(customer_id: str, account: NessieAccount):
    """Create a new account for a customer"""
    account_data = {
        "type": account.type,
        "nickname": account.nickname,
        "rewards": account.rewards,
        "balance": account.balance
    }
    return make_nessie_request(f"/customers/{customer_id}/accounts", "POST", account_data)

@router.get("/accounts/{account_id}")
async def get_account(account_id: str):
    """Get account details"""
    return make_nessie_request(f"/accounts/{account_id}")

@router.get("/accounts/{account_id}/transactions")
async def get_account_transactions(account_id: str):
    """Get all transactions for an account"""
    return make_nessie_request(f"/accounts/{account_id}/transactions")

@router.post("/accounts/{account_id}/transactions")
async def create_transaction(account_id: str, transaction: NessieTransaction):
    """Create a new transaction"""
    transaction_data = {
        "medium": transaction.medium,
        "payee_id": transaction.payee_id,
        "amount": transaction.amount,
        "description": transaction.description
    }
    return make_nessie_request(f"/accounts/{account_id}/transactions", "POST", transaction_data)

@router.get("/atms")
async def get_atms(lat: Optional[float] = None, lng: Optional[float] = None, rad: Optional[int] = None):
    """Get ATM locations"""
    endpoint = "/atms"
    if lat and lng and rad:
        endpoint += f"?lat={lat}&lng={lng}&rad={rad}"
    return make_nessie_request(endpoint)

@router.get("/branches")
async def get_branches(lat: Optional[float] = None, lng: Optional[float] = None, rad: Optional[int] = None):
    """Get bank branch locations"""
    endpoint = "/branches"
    if lat and lng and rad:
        endpoint += f"?lat={lat}&lng={lng}&rad={rad}"
    return make_nessie_request(endpoint)

# Quantum-Nessie Integration Endpoints
@router.post("/quantum-wallet/create")
async def create_quantum_nessie_wallet(wallet_data: QuantumNessieWallet):
    """Create a quantum wallet linked to a Nessie account"""
    # This would integrate with your existing quantum wallet creation
    # and link it to a Nessie customer/account
    return {
        "quantum_wallet_id": wallet_data.quantum_wallet_id,
        "nessie_customer_id": wallet_data.nessie_customer_id,
        "nessie_account_id": wallet_data.nessie_account_id,
        "status": "linked",
        "message": "Quantum wallet successfully linked to Nessie account"
    }

class QuantumPaymentRequest(BaseModel):
    from_quantum_wallet: str
    to_quantum_wallet: str
    amount: float
    description: str = "Quantum Payment"

@router.post("/quantum-payment/process")
async def process_quantum_payment(request: QuantumPaymentRequest):
    """Process a quantum payment through Nessie"""
    # This would:
    # 1. Verify quantum signatures
    # 2. Create transaction in Nessie
    # 3. Update quantum wallet state
    # 4. Generate quantum receipt
    
    import hashlib
    import time
    
    # Generate unique transaction IDs
    tx_hash = hashlib.sha256(f"{request.amount}{request.from_quantum_wallet}{request.to_quantum_wallet}{time.time()}".encode()).hexdigest()[:16]
    
    return {
        "quantum_tx_id": f"qtx_{tx_hash}",
        "nessie_tx_id": f"ntx_{tx_hash}",
        "amount": request.amount,
        "status": "processed",
        "description": request.description,
        "quantum_signature": "verified",
        "merkle_proof": "generated"
    }

@router.get("/quantum-wallet/{wallet_id}/balance")
async def get_quantum_wallet_balance(wallet_id: str):
    """Get balance for a quantum wallet from Nessie"""
    # This would query the linked Nessie account for balance
    return {
        "quantum_wallet_id": wallet_id,
        "balance": 1000.0,  # Mock balance
        "currency": "USD",
        "last_updated": "2024-10-24T23:30:00Z"
    }
