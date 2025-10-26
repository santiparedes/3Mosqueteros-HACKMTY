# 🏦 Advanced Banking Credit Risk Model

Advanced machine learning model for credit risk assessment with LightGBM, SHAP explanations, and dynamic credit offer generation.

## 🎯 Overview

This project implements a production-ready credit risk model that:
- **Predicts** Probability of Default (PD90) 
- **Generates** dynamic credit offers with APR tiers and credit limits
- **Explains** decisions using SHAP feature importance
- **Optimizes** performance through class balancing and feature selection

## 📊 Current Performance

**Best Model** (Exp1_25features_balanced):
- **AUC-ROC**: 0.754 (+0.030 vs baseline)
- **Overfitting**: 0.004 gap (vs 0.212 baseline) ← **98% improvement**
- **Precision/Recall**: 0.655 (balanced)
- **Features**: 24 (optimized from 28)

## 🚀 Quick Start

### Prerequisites

```bash
# Install dependencies
pip install -r requirements.txt

# Activate virtual environment
source venv/bin/activate  # or venv\Scripts\activate on Windows
```

### Quick Test (5-10 minutes)

```bash
cd datasetModel
./quick_test.sh
```

### Full Training (30-60 minutes)

```bash
cd datasetModel
python train_from_loan_dataset.py
```

## 📁 Project Structure

```
Tests/
├── README.md                    # This file
├── MODEL_OPTIMIZATION_PLAN.md   # Optimization strategy
├── FEATURE_MAPPING_TABLE.md     # Feature reference
├── ADVANCED_MODEL_SUMMARY.md    # Model results
├── PROJECT_STRUCTURE.md         # Directory structure
│
├── dataset/
│   └── loan_reduced.csv         # ⭐ Source data (2.26M rows)
│
└── datasetModel/                # ⭐ Main working directory
    ├── README.md                # Complete training guide
    ├── IMPLEMENTATION_PLAN.md   # Technical details
    ├── advanced_banking_model.py
    ├── loan_feature_engineering.py
    ├── train_from_loan_dataset.py
    ├── model_optimizer.py
    ├── models/                  # Trained models
    ├── reports/                 # Results
    └── plots/                   # Visualizations
```

## 🎯 Key Features

### Model Architecture
- **Algorithm**: LightGBM with early stopping
- **Features**: 24 optimized features (from 28)
- **Class Balancing**: Dynamic class weights (ratio 6.8:1)
- **Regularization**: Aggressive (reg_alpha=1.0, reg_lambda=1.0)

### Advanced Capabilities
- ✅ **PD90 Prediction**: Probability of default in 90 days
- ✅ **Dynamic Credit Offers**: APR, limits, MSI based on risk
- ✅ **SHAP Explanations**: Feature importance for transparency
- ✅ **Risk Tiers**: Prime, Near Prime, Subprime, High Risk
- ✅ **Calibration**: Probability calibration for accurate scores

## 📊 Datasets

### Source Data
- **File**: `dataset/loan_reduced.csv`
- **Rows**: 2.26M records
- **Size**: 287 MB
- **Description**: LendingClub loan data (real-world banking data)

### Feature Engineering
The model automatically creates **28 advanced features** from raw data:
- Income stability metrics
- Spending behavior patterns
- Debt management scores
- Payment consistency indicators
- Demographic risk factors
- Composite risk scores

See [FEATURE_MAPPING_TABLE.md](FEATURE_MAPPING_TABLE.md) for complete mapping.

## 🔧 Usage

### Training the Model

```bash
# Quick test with sample (50k rows)
python train_from_loan_dataset.py --sample 50000

# Full training (all 2.26M rows)
python train_from_loan_dataset.py
```

### Running Optimization Experiments

```bash
python model_optimizer.py
```

This runs three experiments:
1. **Exp1**: 24 features, balanced class weights
2. **Exp2**: 24 features, real ratio (6.8)
3. **Exp3**: 20 features, balanced class weights

### Loading Results

```python
import json
import pandas as pd

# Load model performance
with open('datasetModel/reports/advanced_model_performance.json', 'r') as f:
    results = json.load(f)

# Load feature importance
importance = pd.read_csv('datasetModel/reports/advanced_feature_importance.csv')
```

## 📈 Model Results

### Performance Metrics

| Metric | Train | Validation | Test |
|--------|-------|------------|------|
| AUC-ROC | 0.758 | 0.753 | 0.754 |
| Accuracy | 0.703 | 0.701 | 0.701 |
| Precision | 0.659 | 0.653 | 0.655 |
| Recall | 0.659 | 0.653 | 0.655 |

### Risk Tier Distribution

| Tier | PD90 Range | APR | Limit | % of Portfolio |
|------|-----------|-----|-------|----------------|
| Prime | < 0.1 | 12% | 3x income | 37.7% |
| Near Prime | 0.1-0.2 | 18% | 2x income | 10.2% |
| Subprime | 0.2-0.3 | 24% | 1.5x income | 14.7% |
| High Risk | > 0.3 | 30% | 1x income | 37.4% |

## 🎯 Improvements Over Baseline

- ✅ **Test AUC**: +4.1% (0.724 → 0.754)
- ✅ **Overfitting**: -98% gap reduction (0.212 → 0.004)
- ✅ **Features**: -14.3% (28 → 24, optimized)
- ✅ **Class Balance**: Using real distribution (87.2% / 12.8%)

## 📚 Documentation

- **[datasetModel/README.md](datasetModel/README.md)** - Complete training guide
- **[MODEL_OPTIMIZATION_PLAN.md](MODEL_OPTIMIZATION_PLAN.md)** - Optimization strategy
- **[FEATURE_MAPPING_TABLE.md](FEATURE_MAPPING_TABLE.md)** - Feature reference
- **[ADVANCED_MODEL_SUMMARY.md](ADVANCED_MODEL_SUMMARY.md)** - Model results
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Directory structure

## 🔧 Requirements

- Python 3.8+
- pandas, numpy
- lightgbm, shap
- scikit-learn, imblearn
- matplotlib, seaborn

See `requirements.txt` for complete list.

## 🚀 Getting Started

1. **Clone** this repository
2. **Install** dependencies: `pip install -r requirements.txt`
3. **Navigate** to datasetModel/: `cd datasetModel`
4. **Run** quick test: `./quick_test.sh`
5. **Check** results in `reports/` directory

## 📝 Output Files

After training, you'll find:
- **Models**: `models/model_Exp1_25features_balanced.txt` (best model)
- **Results**: `reports/advanced_model_performance.json`
- **Features**: `reports/advanced_feature_importance.csv`
- **Plots**: `plots/advanced_shap_summary.png`
- **Offers**: `reports/credit_offers.json`

## 🎉 Status

✅ **Production Ready** - Model optimized and validated  
✅ **Overfitting Controlled** - Gap reduced by 98%  
✅ **Documentation Complete** - All guides updated  
✅ **Code Clean** - Redundant files removed

---

**Version**: 3.0 (Optimized)  
**Last Updated**: 2025-10-25  
**Status**: Ready for Deployment 🚀

