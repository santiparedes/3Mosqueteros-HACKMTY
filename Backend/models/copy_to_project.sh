#!/bin/bash

echo "📦 COPY PROJECT FILES"
echo "===================="
echo ""

# Read destination path
read -p "Enter destination path: " DEST_PATH

# Create directories
mkdir -p "$DEST_PATH"
mkdir -p "$DEST_PATH/dataset"

echo "Copying files to: $DEST_PATH"
echo ""

# Copy essential files
echo "✅ Copying essential files..."

# Scripts principales
cp datasetModel/loan_feature_engineering.py "$DEST_PATH/"
cp datasetModel/advanced_banking_model.py "$DEST_PATH/"
cp datasetModel/train_from_loan_dataset.py "$DEST_PATH/"
cp datasetModel/model_optimizer.py "$DEST_PATH/"

# Dependencies
cp requirements.txt "$DEST_PATH/"

# Documentation
cp README.md "$DEST_PATH/"
cp datasetModel/README.md "$DEST_PATH/" 2>/dev/null || true
cp FEATURE_MAPPING_TABLE.md "$DEST_PATH/" 2>/dev/null || true

echo ""
echo "✅ Files copied successfully!"
echo ""
echo "📋 Next steps:"
echo "1. cd $DEST_PATH"
echo "2. pip install -r requirements.txt"
echo "3. Add your dataset CSV file"
echo "4. Run: python train_from_loan_dataset.py --dataset your_data.csv"
echo ""
