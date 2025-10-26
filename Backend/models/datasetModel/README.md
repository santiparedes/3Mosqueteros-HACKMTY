# 🏦 Advanced Banking Model - Complete Training Guide

Complete guide for training and optimizing the advanced banking credit risk model.

## 🚀 Quick Start

### Test with Sample Data (5-10 minutes)

```bash
python train_from_loan_dataset.py --sample 50000
```

### Full Training (30-60 minutes)

```bash
python train_from_loan_dataset.py
```

### Run Optimization Experiments

```bash
python model_optimizer.py
```

---

## 📋 What This Model Does

1. **Loads** loan dataset (2.26M rows from LendingClub)
2. **Transforms** raw data to 28 advanced banking features
3. **Trains** LightGBM model with optimized hyperparameters
4. **Generates** credit offers with PD90 scores and risk tiers
5. **Creates** SHAP explanations for transparency

---

## 🎯 Feature Mapping

Your dataset columns → Model features:

| Dataset Variable | Model Feature | Transformation |
|-----------------|---------------|----------------|
| `annual_inc` | `income_monthly` | ÷ 12 |
| `dti` | `dti` | % to decimal |
| `revol_util` | `utilization` | % to decimal |
| `emp_length` | `payroll_streak`, `age` | Years → months |
| `out_prncp` | `current_debt` | Remaining principal |
| `installment` | `spending_monthly` | Payment amount |
| `int_rate` | `score_buro` | Inverse relationship |
| `delinq_2yrs` | `max_days_late` | Estimated days |
| `loan_status` | `label` | Charged Off → 1 |

**Plus 19 advanced features** automatically created!

---

## 📁 Files in This Directory

### Core Scripts

- **`loan_feature_engineering.py`** - Maps LendingClub data to model features
- **`train_from_loan_dataset.py`** - Main training script
- **`advanced_banking_model.py`** - Advanced model architecture
- **`model_optimizer.py`** - Optimization experiments

### Output Files

After training:

**Models:**
- `models/advanced_banking_model.txt` - Trained model
- `models/advanced_scaler.pkl` - Feature scaler
- `models/model_Exp*.txt` - Optimized models

**Reports:**
- `reports/advanced_model_performance.json` - Performance metrics
- `reports/advanced_feature_importance.csv` - Feature rankings
- `reports/optimization_results.json` - Experiment results
- `reports/credit_offers.json` - Generated offers

**Visualizations:**
- `plots/advanced_shap_summary.png` - SHAP summary
- `plots/advanced_feature_importance.png` - Feature importance

---

## 📊 Expected Results

### Model Performance

| Metric | Train | Validation | Test |
|--------|-------|------------|------|
| AUC-ROC | 0.758 | 0.753 | 0.754 |
| Accuracy | 0.703 | 0.701 | 0.701 |
| Precision | 0.659 | 0.653 | 0.655 |
| Recall | 0.659 | 0.653 | 0.655 |

### Risk Tier Distribution

| Tier | PD90 Range | APR | Credit Limit | MSI | Portfolio % |
|------|-----------|-----|--------------|-----|-------------|
| **Prime** | < 0.1 | 12% | 3x income | ✓ 12 months | 37.7% |
| **Near Prime** | 0.1-0.2 | 18% | 2x income | ✓ 6-12 months | 10.2% |
| **Subprime** | 0.2-0.3 | 24% | 1.5x income | ✗ | 14.7% |
| **High Risk** | > 0.3 | 30% | 1x income | ✗ | 37.4% |

---

## 🔧 Training Pipeline

The training process executes these steps:

1. **Load Data** - Reads CSV with optional sampling
2. **Feature Engineering** - Maps raw data to model features
3. **Create Splits** - 70% train / 15% validation / 15% test
4. **Advanced Features** - Creates 28 banking-specific features
5. **Balance Classes** - Applies SMOTE if needed
6. **Train Model** - LightGBM with optimized hyperparameters
7. **Evaluate** - Generates metrics on all datasets
8. **Generate Offers** - Creates credit offers with PD90 scores
9. **SHAP Analysis** - Generates feature importance plots
10. **Save Outputs** - Saves model, reports, and visualizations

---

## 🎯 Key Features

### Model Architecture
- **Algorithm**: LightGBM with early stopping
- **Features**: 24 optimized features (from 28)
- **Class Weighting**: Dynamic based on real distribution (6.8:1)
- **Regularization**: Aggressive (reg_alpha=1.0, reg_lambda=1.0)

### Advanced Capabilities
- ✅ **PD90 Prediction**: Probability of default in 90 days
- ✅ **Dynamic Credit Offers**: APR, limits, MSI based on risk
- ✅ **SHAP Explanations**: Feature importance for transparency
- ✅ **Risk Tiers**: Automatic classification
- ✅ **Calibration**: Probability calibration for accuracy

---

## 🏆 Best Model: Exp1_25features_balanced

**File**: `models/model_Exp1_25features_balanced.txt`

### Configuration:
- **Features**: 24 (4 low-importance removed)
- **Class Weight**: Balanced (6.842)
- **SMOTE**: ❌ Removed (using real distribution)
- **Threshold**: 0.600 (optimized)

### Improvements:
- ✅ **Test AUC**: 0.724 → 0.754 (+4.1%)
- ✅ **Overfitting**: Gap 0.212 → 0.004 (-98.1% 🚀)
- ✅ **Features**: 28 → 24 (-14.3%)
- ✅ **Precision/Recall**: 0.655 (balanced)

---

## 💻 Usage Examples

### Quick Test (Recommended First)

```bash
python train_from_loan_dataset.py --sample 50000
```

### Full Training

```bash
python train_from_loan_dataset.py
```

### Custom Sample Size

```bash
python train_from_loan_dataset.py --sample 100000
```

### Custom Dataset Path

```bash
python train_from_loan_dataset.py --dataset /path/to/your/data.csv
```

### Run Optimization

```bash
python model_optimizer.py
```

This runs three experiments and selects the best model.

### Load Results in Python

```python
import json
import pandas as pd

# Load performance metrics
with open('reports/advanced_model_performance.json', 'r') as f:
    results = json.load(f)

# Load feature importance
importance = pd.read_csv('reports/advanced_feature_importance.csv')

# Load optimization results
with open('reports/optimization_results.json', 'r') as f:
    optimization = json.load(f)
```

---

## 📈 Model Architecture Details

### Hyperparameters (Optimized)

```python
{
    'num_leaves': 10,           # Reduced for regularization
    'learning_rate': 0.03,      # Conservative
    'n_estimators': 2000,
    'max_depth': 4,             # Shallow trees
    'min_child_samples': 30,    # High threshold
    'reg_alpha': 1.0,           # L1 regularization
    'reg_lambda': 1.0,          # L2 regularization
    'scale_pos_weight': 6.842,  # Real distribution ratio
}
```

### Feature Engineering

**28 Advanced Features Created:**
1. Income stability metrics
2. Spending behavior patterns
3. Debt management scores
4. Payment consistency indicators
5. Demographic risk factors
6. Composite risk scores
7. Interaction features

---

## 🔍 Troubleshooting

### Out of Memory?

```bash
# Use smaller sample
python train_from_loan_dataset.py --sample 100000
```

### Want to Test Feature Engineering Only?

```bash
python loan_feature_engineering.py
```

### Different Dataset Format?

Edit `loan_feature_engineering.py` to match your column names.

---

## 📚 Additional Documentation

- **[IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)** - Complete technical plan
- **[../README.md](../README.md)** - Project overview
- **[../FEATURE_MAPPING_TABLE.md](../FEATURE_MAPPING_TABLE.md)** - Complete feature reference

---

## ✅ Expected Training Time

| Sample Size | Runtime | Memory |
|-------------|---------|--------|
| 50K rows | 5-10 min | ~2 GB |
| 100K rows | 10-15 min | ~3 GB |
| 500K rows | 20-30 min | ~6 GB |
| Full (2.26M) | 30-60 min | ~10 GB |

---

## 🎉 Ready to Train!

Start with a quick test:

```bash
python train_from_loan_dataset.py --sample 50000
```

Check results in `reports/` directory!

---

**Status**: ✅ Production Ready  
**Version**: 3.0 (Optimized)  
**Best AUC**: 0.754 (Test)
