#!/bin/bash
# Quick test script for loan dataset training

echo "=========================================="
echo "QUICK TEST - Advanced Banking Model"
echo "=========================================="
echo ""
echo "This will train the model on 50,000 sample rows"
echo "Estimated time: 5-10 minutes"
echo ""

# Check if dataset exists
if [ ! -f "dataset/loan_reduced.csv" ]; then
    echo "❌ ERROR: dataset/loan_reduced.csv not found!"
    echo "Please ensure the dataset file exists at: dataset/loan_reduced.csv"
    exit 1
fi

echo "✓ Dataset found"
echo ""

# Check Python dependencies
echo "Checking dependencies..."
python3 -c "import pandas, numpy, lightgbm, sklearn, imblearn, shap" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ Missing dependencies. Installing..."
    pip install pandas numpy lightgbm scikit-learn imbalanced-learn shap matplotlib seaborn joblib
else
    echo "✓ All dependencies installed"
fi

echo ""
echo "Starting training..."
echo ""

# Run training with sample
python3 train_from_loan_dataset.py --sample 50000

echo ""
echo "=========================================="
echo "Test complete!"
echo "=========================================="
