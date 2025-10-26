#!/bin/bash

# Quantum Wallet Backend Management Script
# Usage: ./start_quantum_backend.sh

echo "🔐 Starting Quantum Wallet Backend..."

# Navigate to backend directory
cd /Users/santipa/Desktop/TecThings/HACKMTY/3Mosqueteros-HACKMTY/Backend

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python3 first."
    exit 1
fi

# Check if required packages are installed
echo "📦 Checking dependencies..."
python3 -c "import fastapi, sqlalchemy" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "⚠️ Installing required packages..."
    pip3 install -r requirements.txt
fi

# Start the backend server
echo "🚀 Starting quantum wallet backend on http://localhost:8000"
echo "📖 API Documentation available at http://localhost:8000/docs"
echo "🛑 Press Ctrl+C to stop the server"
echo ""

python3 main.py
