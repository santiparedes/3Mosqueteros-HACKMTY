#!/usr/bin/env python3
"""
Test script to verify Quantum Wallet + Nessie API integration
"""

import requests
import json
import time

# Configuration
QUANTUM_API_BASE = "http://localhost:8000"
NESSIE_API_BASE = "http://api.nessieisreal.com"
NESSIE_API_KEY = "2efca97355951ec13f6acfd0a8806a14"

def test_quantum_api():
    """Test quantum wallet API endpoints"""
    print("🧪 Testing Quantum Wallet API...")
    
    try:
        # Test API health
        response = requests.get(f"{QUANTUM_API_BASE}/")
        if response.status_code == 200:
            print("✅ Quantum API is running")
            print(f"   Response: {response.json()}")
        else:
            print(f"❌ Quantum API error: {response.status_code}")
            return False
            
        # Test wallet creation
        wallet_data = {
            "user_id": "test_user_123",
            "pubkey_pqc": "demo_public_key_123"
        }
        
        response = requests.post(f"{QUANTUM_API_BASE}/wallets", json=wallet_data)
        if response.status_code == 200:
            wallet = response.json()
            print(f"✅ Wallet created: {wallet['wallet_id']}")
            return wallet['wallet_id']
        else:
            print(f"❌ Wallet creation failed: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"❌ Quantum API test failed: {e}")
        return None

def test_nessie_api():
    """Test Nessie API endpoints"""
    print("\n🏦 Testing Nessie API...")
    
    try:
        # Test customers endpoint
        response = requests.get(f"{NESSIE_API_BASE}/customers?key={NESSIE_API_KEY}")
        if response.status_code == 200:
            customers = response.json()
            print(f"✅ Nessie API connected - Found {len(customers)} customers")
            return True
        else:
            print(f"❌ Nessie API error: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Nessie API test failed: {e}")
        return False

def test_quantum_nessie_bridge():
    """Test the bridge between Quantum and Nessie"""
    print("\n🔗 Testing Quantum-Nessie Bridge...")
    
    try:
        # Test bridge endpoints
        response = requests.get(f"{QUANTUM_API_BASE}/nessie/customers")
        if response.status_code == 200:
            print("✅ Bridge endpoint accessible")
        else:
            print(f"❌ Bridge endpoint error: {response.status_code}")
            return False
            
        # Test quantum payment processing
        payment_data = {
            "from_quantum_wallet": "test_wallet_123",
            "to_quantum_wallet": "test_wallet_456",
            "amount": 100.0,
            "description": "Test quantum payment"
        }
        
        response = requests.post(f"{QUANTUM_API_BASE}/nessie/quantum-payment/process", json=payment_data)
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Quantum payment processed: {result['quantum_tx_id']}")
            return True
        else:
            print(f"❌ Quantum payment failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Bridge test failed: {e}")
        return False

def test_full_flow():
    """Test the complete flow: Create wallet -> Process payment -> Verify"""
    print("\n🚀 Testing Complete Flow...")
    
    try:
        # Step 1: Create quantum wallet
        wallet_data = {
            "user_id": "flow_test_user",
            "pubkey_pqc": "flow_test_pqc_key"
        }
        
        response = requests.post(f"{QUANTUM_API_BASE}/wallets", json=wallet_data)
        if response.status_code != 200:
            print("❌ Failed to create wallet for flow test")
            return False
            
        wallet = response.json()
        wallet_id = wallet['wallet_id']
        print(f"✅ Step 1: Created wallet {wallet_id}")
        
        # Step 2: Prepare transaction
        prepare_data = {
            "wallet_id": wallet_id,
            "to": "recipient_wallet_456",
            "amount": 50.0,
            "currency": "USD"
        }
        
        response = requests.post(f"{QUANTUM_API_BASE}/tx/prepare", json=prepare_data)
        if response.status_code != 200:
            print("❌ Failed to prepare transaction")
            return False
            
        prepare_result = response.json()
        print(f"✅ Step 2: Prepared transaction")
        
        # Step 3: Submit transaction
        submit_data = {
            "payload": prepare_result['payload'],
            "sig_pqc": f"mock_signature_{int(time.time())}",
            "pubkey_pqc": "flow_test_pqc_key"
        }
        
        response = requests.post(f"{QUANTUM_API_BASE}/tx/submit", json=submit_data)
        if response.status_code != 200:
            print("❌ Failed to submit transaction")
            return False
            
        submit_result = response.json()
        print(f"✅ Step 3: Submitted transaction {submit_result['tx_id']}")
        
        # Step 4: Get transaction history
        response = requests.get(f"{QUANTUM_API_BASE}/transactions")
        if response.status_code == 200:
            transactions = response.json()
            print(f"✅ Step 4: Retrieved {len(transactions.get('transactions', []))} transactions")
        
        print("🎉 Complete flow test successful!")
        return True
        
    except Exception as e:
        print(f"❌ Flow test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🛡️ Quantum Wallet + Nessie API Integration Test")
    print("=" * 50)
    
    # Test individual components
    quantum_ok = test_quantum_api()
    nessie_ok = test_nessie_api()
    bridge_ok = test_quantum_nessie_bridge()
    
    # Test complete flow
    flow_ok = test_full_flow()
    
    # Summary
    print("\n📊 Test Summary:")
    print("=" * 20)
    print(f"Quantum API: {'✅ PASS' if quantum_ok else '❌ FAIL'}")
    print(f"Nessie API: {'✅ PASS' if nessie_ok else '❌ FAIL'}")
    print(f"Bridge: {'✅ PASS' if bridge_ok else '❌ FAIL'}")
    print(f"Complete Flow: {'✅ PASS' if flow_ok else '❌ FAIL'}")
    
    if all([quantum_ok, nessie_ok, bridge_ok, flow_ok]):
        print("\n🎉 All tests passed! Integration is working correctly.")
        print("\n📱 You can now test the Swift app with real banking data!")
    else:
        print("\n⚠️ Some tests failed. Check the errors above.")

if __name__ == "__main__":
    main()
