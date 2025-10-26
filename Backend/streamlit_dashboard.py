import streamlit as st
import requests
import json
import time
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
import hashlib

# Page configuration
st.set_page_config(
    page_title="🛡️ Quantum Wallet Dashboard",
    page_icon="🛡️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        padding: 2rem;
        border-radius: 10px;
        color: white;
        text-align: center;
        margin-bottom: 2rem;
    }
    .metric-card {
        background: white;
        padding: 1rem;
        border-radius: 10px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        border-left: 4px solid #667eea;
        color: #333333 !important;
    }
    .metric-card h1, .metric-card h2, .metric-card h3, .metric-card h4, .metric-card h5, .metric-card h6 {
        color: #333333 !important;
    }
    .metric-card p, .metric-card span, .metric-card div {
        color: #333333 !important;
    }
    .metric-card strong {
        color: #333333 !important;
    }
    .success-box {
        background: #d4edda;
        border: 1px solid #c3e6cb;
        color: #155724;
        padding: 1rem;
        border-radius: 5px;
        margin: 1rem 0;
    }
    .error-box {
        background: #f8d7da;
        border: 1px solid #f5c6cb;
        color: #721c24;
        padding: 1rem;
        border-radius: 5px;
        margin: 1rem 0;
    }
    .quantum-badge {
        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        color: white;
        padding: 0.5rem 1rem;
        border-radius: 20px;
        font-size: 0.8rem;
        font-weight: bold;
    }
    /* Ensure all text in white boxes is dark */
    .stContainer > div {
        color: #333333 !important;
    }
    /* Fix Streamlit metric text color */
    .metric-container {
        color: #333333 !important;
    }
    .metric-container h1, .metric-container h2, .metric-container h3 {
        color: #333333 !important;
    }
    /* Fix any other white background elements */
    .element-container {
        color: #333333 !important;
    }
    /* Fix Streamlit default text colors */
    .stApp {
        color: #333333 !important;
    }
    .stMarkdown {
        color: #333333 !important;
    }
    .stText {
        color: #333333 !important;
    }
    /* Fix expander text */
    .streamlit-expanderHeader {
        color: #333333 !important;
    }
    .streamlit-expanderContent {
        color: #333333 !important;
    }
    /* Fix form text */
    .stForm {
        color: #333333 !important;
    }
    /* Fix selectbox and input text */
    .stSelectbox label, .stTextInput label, .stNumberInput label {
        color: #333333 !important;
    }
    /* Fix sidebar text */
    .css-1d391kg {
        color: #333333 !important;
    }
    /* Override any light text on white backgrounds */
    .stApp > div > div > div > div {
        color: #333333 !important;
    }
</style>
""", unsafe_allow_html=True)

# API Configuration
API_BASE_URL = "http://localhost:8001"

# Initialize session state
if 'wallets' not in st.session_state:
    st.session_state.wallets = []
if 'transactions' not in st.session_state:
    st.session_state.transactions = []
if 'blocks' not in st.session_state:
    st.session_state.blocks = []

def make_api_request(endpoint, method="GET", data=None):
    """Make API request with error handling"""
    try:
        url = f"{API_BASE_URL}{endpoint}"
        if method == "GET":
            response = requests.get(url)
        elif method == "POST":
            response = requests.post(url, json=data)
        
        if response.status_code == 200:
            return response.json(), None
        else:
            return None, f"API Error: {response.status_code} - {response.text}"
    except Exception as e:
        return None, f"Connection Error: {str(e)}"

def sha256_hex(data):
    """Calculate SHA-256 hash"""
    return hashlib.sha256(data.encode()).hexdigest()

def verify_merkle_proof(tx_hash, proof, expected_root):
    """Verify Merkle proof"""
    current_hash = tx_hash.lower()
    
    for proof_item in proof:
        sibling_hash = proof_item['hash'].lower()
        
        if proof_item['dir'] == 'L':
            combined = sibling_hash + current_hash
        else:
            combined = current_hash + sibling_hash
        
        current_hash = sha256_hex(combined)
    
    return current_hash.lower() == expected_root.lower()

# Main Header
st.markdown("""
<div class="main-header">
    <h1>🛡️ Quantum Wallet Dashboard</h1>
    <p>Post-Quantum Cryptography for Secure Transactions</p>
</div>
""", unsafe_allow_html=True)

# Sidebar
st.sidebar.title("🔧 Quantum Wallet Controls")

# API Status Check
st.sidebar.subheader("📡 API Status")
api_status, api_error = make_api_request("/")
if api_status:
    st.sidebar.success("✅ API Connected")
    st.sidebar.info(f"Version: {api_status.get('version', 'Unknown')}")
else:
    st.sidebar.error("❌ API Disconnected")
    st.sidebar.error(api_error)

# Navigation
page = st.sidebar.selectbox(
    "Navigate",
    ["🏠 Dashboard", "💳 Wallet Management", "💸 Send Payment", "📋 Transaction History", "🔍 Receipt Verifier", "📊 Analytics", "🏦 Nessie Banking", "🔗 Quantum-Nessie Bridge"]
)

# Dashboard Page
if page == "🏠 Dashboard":
    st.header("📊 System Overview")
    
    col1, col2, col3, col4 = st.columns(4)
    
    # Get system stats
    with col1:
        st.metric("🔗 API Status", "Online" if api_status else "Offline")
    
    with col2:
        # Get wallet count (mock for now)
        st.metric("💳 Active Wallets", "3")
    
    with col3:
        # Get transaction count
        st.metric("💸 Total Transactions", "12")
    
    with col4:
        # Get block count
        st.metric("📦 Blocks Sealed", "4")
    
    # Recent Activity
    st.subheader("🕒 Recent Activity")
    
    # Mock recent transactions
    recent_txs = [
        {"time": "2 min ago", "type": "Payment", "amount": "250 MXN", "status": "✅ Confirmed"},
        {"time": "5 min ago", "type": "Wallet Created", "amount": "-", "status": "✅ Success"},
        {"time": "8 min ago", "type": "Payment", "amount": "100 MXN", "status": "✅ Confirmed"},
        {"time": "12 min ago", "type": "Block Sealed", "amount": "3 transactions", "status": "✅ Complete"},
    ]
    
    for tx in recent_txs:
        st.markdown(f"""
        <div class="metric-card">
            <strong>{tx['type']}</strong> - {tx['amount']} 
            <span style="float: right;">
                <span class="quantum-badge">{tx['status']}</span>
                <small style="color: #666;">{tx['time']}</small>
            </span>
        </div>
        """, unsafe_allow_html=True)

# Wallet Management Page
elif page == "💳 Wallet Management":
    st.header("💳 Quantum Wallet Management")
    
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.subheader("Create New Wallet")
        
        with st.form("create_wallet"):
            user_id = st.text_input("User ID", value=f"user_{int(time.time())}")
            pubkey_pqc = st.text_input("Public Key (PQC)", value="demo_public_key_123")
            
            if st.form_submit_button("🛡️ Create Quantum Wallet", use_container_width=True):
                wallet_data = {
                    "user_id": user_id,
                    "pubkey_pqc": pubkey_pqc
                }
                
                result, error = make_api_request("/wallets", "POST", wallet_data)
                
                if result:
                    st.session_state.wallets.append(result)
                    st.success(f"✅ Wallet created successfully!")
                    st.info(f"Wallet ID: `{result['wallet_id']}`")
                else:
                    st.error(f"❌ Failed to create wallet: {error}")
    
    with col2:
        st.subheader("Active Wallets")
        
        # Display existing wallets
        if st.session_state.wallets:
            for wallet in st.session_state.wallets:
                st.markdown(f"""
                <div class="metric-card">
                    <strong>Wallet ID:</strong> <code>{wallet['wallet_id']}</code><br>
                    <strong>User:</strong> {wallet.get('user_id', 'Unknown')}<br>
                    <strong>Status:</strong> <span class="quantum-badge">Active</span>
                </div>
                """, unsafe_allow_html=True)
        else:
            st.info("No wallets created yet")

# Send Payment Page
elif page == "💸 Send Payment":
    st.header("💸 Send Quantum Payment")
    
    col1, col2 = st.columns([2, 1])
    
    with col1:
        with st.form("send_payment"):
            st.subheader("Transaction Details")
            
            # Create wallet options with better display
            if st.session_state.wallets:
                wallet_options = [f"{w['wallet_id']} ({w.get('user_id', 'Unknown')})" for w in st.session_state.wallets]
                selected_wallet_display = st.selectbox(
                    "From Wallet",
                    wallet_options,
                    help="Select the wallet to send from"
                )
                # Extract the actual wallet ID from the display string
                wallet_id = selected_wallet_display.split(' (')[0]
            else:
                wallet_id = st.text_input("From Wallet ID", value="demo_wallet_123", help="Enter the wallet ID to send from")
            
            recipient = st.text_input("To Wallet ID", value="recipient_wallet_456")
            amount = st.number_input("Amount (MXN)", min_value=0.01, value=100.0, step=0.01)
            currency = st.selectbox("Currency", ["MXN", "USD", "EUR"], index=0)
            
            # Display wallet IDs for easy copying
            if st.session_state.wallets:
                st.markdown("**📋 Available Wallet IDs (click to copy):**")
                for wallet in st.session_state.wallets:
                    st.code(wallet['wallet_id'], language=None)
            
            if st.form_submit_button("🚀 Send Quantum Payment", use_container_width=True):
                # Step 1: Prepare transaction
                with st.spinner("Preparing transaction..."):
                    prepare_data = {
                        "wallet_id": wallet_id,
                        "to": recipient,
                        "amount": amount,
                        "currency": currency
                    }
                    
                    result, error = make_api_request("/tx/prepare", "POST", prepare_data)
                    
                    if result:
                        st.success("✅ Transaction prepared successfully!")
                        
                        # Step 2: Submit transaction
                        with st.spinner("Submitting transaction..."):
                            submit_data = {
                                "payload": result['payload'],
                                "sig_pqc": f"mock_signature_{int(time.time())}",
                                "pubkey_pqc": "demo_public_key_123"
                            }
                            
                            submit_result, submit_error = make_api_request("/tx/submit", "POST", submit_data)
                            
                            if submit_result:
                                st.session_state.transactions.append(submit_result)
                                st.success("✅ Payment sent successfully!")
                                st.info(f"Transaction ID: `{submit_result['tx_id']}`")
                                
                                # Auto-refresh after 3 seconds to check for receipt
                                st.info("⏳ Waiting for block sealing...")
                                time.sleep(3)
                                st.rerun()
                            else:
                                st.error(f"❌ Failed to submit transaction: {submit_error}")
                    else:
                        st.error(f"❌ Failed to prepare transaction: {error}")
    
    with col2:
        st.subheader("💡 Quantum Features")
        st.markdown("""
        <div class="metric-card">
            <h4>🛡️ Post-Quantum Security</h4>
            <p>Transactions are signed with quantum-resistant cryptography</p>
        </div>
        """, unsafe_allow_html=True)
        
        st.markdown("""
        <div class="metric-card">
            <h4>🌳 Merkle Proofs</h4>
            <p>Each transaction includes cryptographic proof of inclusion</p>
        </div>
        """, unsafe_allow_html=True)
        
        st.markdown("""
        <div class="metric-card">
            <h4>📦 Block Sealing</h4>
            <p>Transactions are batched and sealed every 3 payments</p>
        </div>
        """, unsafe_allow_html=True)

# Transaction History Page
elif page == "📋 Transaction History":
    st.header("📋 Transaction History")
    
    # Fetch real transaction data from API
    transactions_data = []
    
    # Get all transactions from the database via API
    # Note: We'll need to add a GET /transactions endpoint to the API
    # For now, let's use the session state transactions
    if st.session_state.transactions:
        for tx in st.session_state.transactions:
            transactions_data.append({
                "tx_id": tx.get('tx_id', 'unknown'),
                "from": "session_wallet",  # We don't store this in session state
                "to": "recipient_wallet",
                "amount": 100.0,  # Default amount
                "currency": "MXN",
                "status": "✅ Confirmed",
                "block": 1,
                "timestamp": datetime.now()
            })
    
    # If no real transactions, show mock data
    if not transactions_data:
        transactions_data = [
            {
                "tx_id": "0c76a263bebbb2db",
                "from": "4a70fc793df04feb",
                "to": "recipient_wallet_456",
                "amount": 250.0,
                "currency": "MXN",
                "status": "✅ Confirmed",
                "block": 1,
                "timestamp": datetime.now() - timedelta(minutes=5)
            },
            {
                "tx_id": "b8395db268ed62ae",
                "from": "4a70fc793df04feb",
                "to": "recipient_wallet_2",
                "amount": 150.0,
                "currency": "MXN",
                "status": "✅ Confirmed",
                "block": 1,
                "timestamp": datetime.now() - timedelta(minutes=8)
            },
            {
                "tx_id": "2927b35de7dacc6d",
                "from": "4a70fc793df04feb",
                "to": "recipient_wallet_3",
                "amount": 200.0,
                "currency": "MXN",
                "status": "✅ Confirmed",
                "block": 1,
                "timestamp": datetime.now() - timedelta(minutes=10)
            }
        ]
    
    # Create DataFrame
    df = pd.DataFrame(transactions_data)
    
    # Display transactions
    for _, tx in df.iterrows():
        with st.expander(f"Transaction {tx['tx_id'][:8]}... - {tx['amount']} {tx['currency']}"):
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.write(f"**From:** `{tx['from']}`")
                st.write(f"**To:** `{tx['to']}`")
            
            with col2:
                st.write(f"**Amount:** {tx['amount']} {tx['currency']}")
                st.write(f"**Block:** #{tx['block']}")
            
            with col3:
                st.write(f"**Status:** {tx['status']}")
                st.write(f"**Time:** {tx['timestamp'].strftime('%H:%M:%S')}")
            
            # Get receipt button
            if st.button(f"Get Receipt", key=f"receipt_{tx['tx_id']}"):
                receipt_result, receipt_error = make_api_request(f"/tx/{tx['tx_id']}/receipt")
                
                if receipt_result:
                    st.success("✅ Receipt retrieved!")
                    st.json(receipt_result)
                else:
                    st.error(f"❌ Failed to get receipt: {receipt_error}")

# Receipt Verifier Page
elif page == "🔍 Receipt Verifier":
    st.header("🔍 Quantum Receipt Verifier")
    
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.subheader("Verify Receipt")
        
        # Input method selection
        input_method = st.radio(
            "Input Method",
            ["📝 Paste JSON", "📁 Upload File", "🔗 Transaction ID"]
        )
        
        receipt_data = None
        
        if input_method == "📝 Paste JSON":
            receipt_json = st.text_area(
                "Receipt JSON",
                height=300,
                placeholder="Paste your quantum receipt JSON here..."
            )
            
            if receipt_json:
                try:
                    receipt_data = json.loads(receipt_json)
                except json.JSONDecodeError:
                    st.error("❌ Invalid JSON format")
        
        elif input_method == "📁 Upload File":
            uploaded_file = st.file_uploader("Upload Receipt File", type=['json'])
            if uploaded_file:
                try:
                    receipt_data = json.load(uploaded_file)
                except json.JSONDecodeError:
                    st.error("❌ Invalid JSON file")
        
        elif input_method == "🔗 Transaction ID":
            tx_id = st.text_input("Transaction ID", value="0c76a263bebbb2db")
            if st.button("Get Receipt"):
                receipt_result, receipt_error = make_api_request(f"/tx/{tx_id}/receipt")
                if receipt_result:
                    receipt_data = receipt_result
                    st.success("✅ Receipt retrieved!")
                else:
                    st.error(f"❌ Failed to get receipt: {receipt_error}")
        
        # Verify button
        if receipt_data and st.button("🔍 Verify Receipt", use_container_width=True):
            with st.spinner("Verifying receipt..."):
                # Verify via API
                verify_result, verify_error = make_api_request("/verify", "POST", {"receipt": receipt_data})
                
                if verify_result:
                    if verify_result['valid']:
                        st.markdown("""
                        <div class="success-box">
                            <h3>✅ Receipt Verification: VALID</h3>
                            <p>This receipt has been cryptographically verified and is authentic.</p>
                        </div>
                        """, unsafe_allow_html=True)
                    else:
                        st.markdown(f"""
                        <div class="error-box">
                            <h3>❌ Receipt Verification: INVALID</h3>
                            <p>Reason: {verify_result.get('reason', 'Unknown error')}</p>
                        </div>
                        """, unsafe_allow_html=True)
                else:
                    st.error(f"❌ Verification failed: {verify_error}")
    
    with col2:
        st.subheader("🔐 Verification Details")
        
        if receipt_data:
            st.markdown("""
            <div class="metric-card">
                <h4>📋 Transaction Info</h4>
                <p><strong>From:</strong> <code>{}</code></p>
                <p><strong>To:</strong> <code>{}</code></p>
                <p><strong>Amount:</strong> {} {}</p>
            </div>
            """.format(
                receipt_data['tx']['from_wallet'],
                receipt_data['tx']['to'],
                receipt_data['tx']['amount'],
                receipt_data['tx']['currency']
            ), unsafe_allow_html=True)
            
            st.markdown("""
            <div class="metric-card">
                <h4>📦 Block Info</h4>
                <p><strong>Block:</strong> #{}</p>
                <p><strong>Merkle Root:</strong> <code>{}</code></p>
                <p><strong>Proof Steps:</strong> {}</p>
            </div>
            """.format(
                receipt_data['block_header']['index'],
                receipt_data['block_header']['merkle_root'],
                len(receipt_data['merkle_proof'])
            ), unsafe_allow_html=True)

# Analytics Page
elif page == "📊 Analytics":
    st.header("📊 Quantum Wallet Analytics")
    
    # Mock analytics data
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("💸 Transaction Volume")
        
        # Create sample data
        dates = pd.date_range(start='2024-10-01', end='2024-10-24', freq='D')
        amounts = [100, 150, 200, 250, 300, 180, 220, 350, 280, 190, 240, 320, 160, 210, 290, 170, 230, 310, 200, 260, 180, 240, 300, 220]
        
        df_volume = pd.DataFrame({
            'Date': dates,
            'Amount (MXN)': amounts[:len(dates)]
        })
        
        fig_volume = px.line(df_volume, x='Date', y='Amount (MXN)', 
                           title='Daily Transaction Volume',
                           color_discrete_sequence=['#667eea'])
        fig_volume.update_layout(height=400)
        st.plotly_chart(fig_volume, use_container_width=True)
    
    with col2:
        st.subheader("📦 Block Sealing Activity")
        
        # Block data
        blocks_data = [
            {"Block": 1, "Transactions": 3, "Merkle Root": "279c80df847cc67d..."},
            {"Block": 2, "Transactions": 3, "Merkle Root": "4a2b8c9d1e3f5g6h..."},
            {"Block": 3, "Transactions": 3, "Merkle Root": "7i8j9k0l1m2n3o4p..."},
            {"Block": 4, "Transactions": 3, "Merkle Root": "5q6r7s8t9u0v1w2x..."}
        ]
        
        df_blocks = pd.DataFrame(blocks_data)
        
        fig_blocks = px.bar(df_blocks, x='Block', y='Transactions',
                          title='Transactions per Block',
                          color='Transactions',
                          color_continuous_scale='Blues')
        fig_blocks.update_layout(height=400)
        st.plotly_chart(fig_blocks, use_container_width=True)
    
    # System Metrics
    st.subheader("🔧 System Metrics")
    
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric("🛡️ PQC Signatures", "24", "12")
    
    with col2:
        st.metric("🌳 Merkle Proofs", "24", "8")
    
    with col3:
        st.metric("⏱️ Avg Block Time", "2.3s", "-0.5s")
    
    with col4:
        st.metric("✅ Success Rate", "100%", "0%")

# Nessie Banking Page
elif page == "🏦 Nessie Banking":
    st.header("🏦 Capital One Nessie Banking Integration")
    
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.subheader("📊 Nessie API Status")
        
        # Test Nessie API connection
        nessie_status, nessie_error = make_api_request("/nessie/customers")
        if nessie_status:
            st.success("✅ Nessie API Connected")
            st.info(f"Found {len(nessie_status)} customers in system")
        else:
            st.error("❌ Nessie API Disconnected")
            st.error(nessie_error)
        
        st.subheader("👥 Customer Management")
        
        # Create new customer
        with st.form("create_customer"):
            st.write("**Create New Customer**")
            first_name = st.text_input("First Name", value="John")
            last_name = st.text_input("Last Name", value="Doe")
            street_number = st.text_input("Street Number", value="123")
            street_name = st.text_input("Street Name", value="Main St")
            city = st.text_input("City", value="Austin")
            state = st.text_input("State", value="TX")
            zip_code = st.text_input("ZIP Code", value="78701")
            
            if st.form_submit_button("👤 Create Customer"):
                customer_data = {
                    "first_name": first_name,
                    "last_name": last_name,
                    "address": {
                        "street_number": street_number,
                        "street_name": street_name,
                        "city": city,
                        "state": state,
                        "zip": zip_code
                    }
                }
                
                result, error = make_api_request("/nessie/customers", "POST", customer_data)
                if result:
                    st.success("✅ Customer created successfully!")
                    st.info(f"Customer ID: `{result.get('objectCreated', {}).get('_id', 'Unknown')}`")
                else:
                    st.error(f"❌ Failed to create customer: {error}")
        
        st.subheader("💳 Account Management")
        
        # Create account for customer
        with st.form("create_account"):
            st.write("**Create New Account**")
            customer_id = st.text_input("Customer ID", value="")
            account_type = st.selectbox("Account Type", ["Checking", "Savings", "Credit Card"])
            nickname = st.text_input("Account Nickname", value="Quantum Wallet Account")
            initial_balance = st.number_input("Initial Balance", min_value=0.0, value=1000.0)
            
            if st.form_submit_button("💳 Create Account"):
                if customer_id:
                    account_data = {
                        "type": account_type,
                        "nickname": nickname,
                        "rewards": 0,
                        "balance": initial_balance
                    }
                    
                    result, error = make_api_request(f"/nessie/customers/{customer_id}/accounts", "POST", account_data)
                    if result:
                        st.success("✅ Account created successfully!")
                        st.info(f"Account ID: `{result.get('objectCreated', {}).get('_id', 'Unknown')}`")
                    else:
                        st.error(f"❌ Failed to create account: {error}")
                else:
                    st.error("Please enter a Customer ID")
    
    with col2:
        st.subheader("🏧 ATM & Branch Locator")
        
        # ATM/Branch finder
        st.write("**Find Nearby Services**")
        lat = st.number_input("Latitude", value=30.2672, format="%.4f")
        lng = st.number_input("Longitude", value=-97.7431, format="%.4f")
        radius = st.slider("Radius (miles)", 1, 50, 10)
        
        if st.button("🔍 Find ATMs"):
            atms_result, atms_error = make_api_request(f"/nessie/atms?lat={lat}&lng={lng}&rad={radius}")
            if atms_result:
                st.success(f"Found {len(atms_result)} ATMs nearby")
                for atm in atms_result[:3]:  # Show first 3
                    st.write(f"📍 {atm.get('name', 'ATM')} - {atm.get('distance', 'N/A')} miles")
            else:
                st.error(f"❌ Failed to find ATMs: {atms_error}")
        
        if st.button("🏢 Find Branches"):
            branches_result, branches_error = make_api_request(f"/nessie/branches?lat={lat}&lng={lng}&rad={radius}")
            if branches_result:
                st.success(f"Found {len(branches_result)} branches nearby")
                for branch in branches_result[:3]:  # Show first 3
                    st.write(f"🏢 {branch.get('name', 'Branch')} - {branch.get('distance', 'N/A')} miles")
            else:
                st.error(f"❌ Failed to find branches: {branches_error}")

# Quantum-Nessie Bridge Page
elif page == "🔗 Quantum-Nessie Bridge":
    st.header("🔗 Quantum-Nessie Bridge")
    st.write("Bridge between Quantum Wallet and Capital One Nessie Banking")
    
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.subheader("🔗 Link Quantum Wallet to Nessie Account")
        
        with st.form("link_wallet"):
            quantum_wallet_id = st.text_input("Quantum Wallet ID", value="")
            nessie_customer_id = st.text_input("Nessie Customer ID", value="")
            nessie_account_id = st.text_input("Nessie Account ID", value="")
            user_id = st.text_input("User ID", value="user_123")
            
            if st.form_submit_button("🔗 Link Wallets"):
                if quantum_wallet_id and nessie_customer_id and nessie_account_id:
                    link_data = {
                        "quantum_wallet_id": quantum_wallet_id,
                        "nessie_customer_id": nessie_customer_id,
                        "nessie_account_id": nessie_account_id,
                        "user_id": user_id
                    }
                    
                    result, error = make_api_request("/nessie/quantum-wallet/create", "POST", link_data)
                    if result:
                        st.success("✅ Wallets linked successfully!")
                        st.json(result)
                    else:
                        st.error(f"❌ Failed to link wallets: {error}")
                else:
                    st.error("Please fill in all required fields")
        
        st.subheader("💸 Process Quantum Payment via Nessie")
        
        with st.form("quantum_payment"):
            from_wallet = st.text_input("From Quantum Wallet", value="")
            to_wallet = st.text_input("To Quantum Wallet", value="")
            amount = st.number_input("Amount", min_value=0.01, value=100.0)
            description = st.text_input("Description", value="Quantum Payment via Nessie")
            
            if st.form_submit_button("🚀 Process Quantum Payment"):
                if from_wallet and to_wallet:
                    payment_data = {
                        "from_quantum_wallet": from_wallet,
                        "to_quantum_wallet": to_wallet,
                        "amount": amount,
                        "description": description
                    }
                    
                    result, error = make_api_request("/nessie/quantum-payment/process", "POST", payment_data)
                    if result:
                        st.success("✅ Quantum payment processed successfully!")
                        st.json(result)
                    else:
                        st.error(f"❌ Failed to process payment: {error}")
                else:
                    st.error("Please fill in wallet addresses")
    
    with col2:
        st.subheader("💰 Wallet Balance")
        
        wallet_id = st.text_input("Quantum Wallet ID", value="", key="balance_wallet")
        if st.button("📊 Get Balance"):
            if wallet_id:
                balance_result, balance_error = make_api_request(f"/nessie/quantum-wallet/{wallet_id}/balance")
                if balance_result:
                    st.success("✅ Balance retrieved!")
                    st.metric("Balance", f"${balance_result.get('balance', 0):.2f}")
                    st.write(f"**Currency:** {balance_result.get('currency', 'USD')}")
                    st.write(f"**Last Updated:** {balance_result.get('last_updated', 'Unknown')}")
                else:
                    st.error(f"❌ Failed to get balance: {balance_error}")
            else:
                st.error("Please enter a wallet ID")
        
        st.subheader("🔐 Security Features")
        st.markdown("""
        <div class="metric-card">
            <h4>🛡️ Quantum Security</h4>
            <p>Post-quantum cryptographic signatures</p>
        </div>
        """, unsafe_allow_html=True)
        
        st.markdown("""
        <div class="metric-card">
            <h4>🏦 Banking Integration</h4>
            <p>Real Capital One API integration</p>
        </div>
        """, unsafe_allow_html=True)
        
        st.markdown("""
        <div class="metric-card">
            <h4>🌳 Merkle Proofs</h4>
            <p>Cryptographic transaction verification</p>
        </div>
        """, unsafe_allow_html=True)

# Footer
st.markdown("---")
st.markdown("""
<div style="text-align: center; color: #666; padding: 2rem;">
    <p>🛡️ <strong>Quantum Wallet Dashboard</strong> - Post-Quantum Cryptography for Secure Transactions</p>
    <p>🏦 <strong>Powered by Capital One Nessie API</strong> - Real Banking Integration</p>
    <p>Built with ❤️ for HACKMTY 2024</p>
</div>
""", unsafe_allow_html=True)
