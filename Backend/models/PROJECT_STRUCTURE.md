# 📁 PROJECT STRUCTURE - AFTER CLEANUP

**Last Updated**: 2025-10-25  
**Status**: ✅ Cleaned and Organized

---

## 🎯 **PROJECT OVERVIEW**

This project contains an advanced banking credit risk model with:
- **Source Data**: Loan dataset with 2.26M records
- **Main Model**: LightGBM with advanced feature engineering
- **Optimization**: Multiple experiments with class weights and feature selection
- **Results**: Best model (Exp1) with 0.754 AUC and near-zero overfitting

---

## 📂 **DIRECTORY STRUCTURE**

```
Tests/
├── 📄 README.md                          # Main project README
├── 📄 ADVANCED_MODEL_SUMMARY.md          # Model performance summary
├── 📄 FEATURE_MAPPING_TABLE.md           # Important reference
├── 📄 MODEL_OPTIMIZATION_PLAN.md         # Active optimization plan
├── 📄 SETUP_DB.md                        # Database setup guide
├── 📄 PROJECT_STRUCTURE.md               # This file
│
├── 📁 dataset/
│   └── loan_reduced.csv                  # ⭐ SOURCE DATA (287 MB, 2.26M rows)
│
├── 📁 datasetModel/                      # ⭐ MAIN WORKING DIRECTORY
│   ├── 📄 README.md                      # DatasetModel overview
│   ├── 📄 TRAINING_GUIDE.md              # Quick start guide
│   ├── 📄 IMPLEMENTATION_PLAN.md         # Implementation details
│   ├── 📄 MODEL_OPTIMIZATION_PLAN.md     # Optimization strategy
│   ├── 📄 OPTIMIZATION_RESULTS_REPORT.md # Optimization results
│   ├── 📄 FINAL_IMPROVEMENTS_REPORT.md   # Final improvements summary
│   │
│   ├── 🐍 CORE SCRIPTS:
│   │   ├── advanced_banking_model.py     # ⭐ Main model architecture
│   │   ├── loan_feature_engineering.py   # ⭐ Feature engineering
│   │   ├── train_from_loan_dataset.py    # ⭐ Main training script
│   │   └── model_optimizer.py            # ⭐ Optimization experiments
│   │
│   ├── 📁 models/
│   │   ├── advanced_banking_model.txt    # Main trained model
│   │   ├── advanced_scaler.pkl           # Feature scaler
│   │   ├── advanced_model_metadata.json  # Model metadata
│   │   ├── model_Exp1_25features_balanced.txt    # 🏆 BEST MODEL
│   │   ├── scaler_Exp1_25features_balanced.pkl
│   │   ├── model_Exp2_25features_real_ratio.txt
│   │   ├── scaler_Exp2_25features_real_ratio.pkl
│   │   ├── model_Exp3_20features_balanced.txt
│   │   └── scaler_Exp3_20features_balanced.pkl
│   │
│   ├── 📁 reports/
│   │   ├── advanced_model_performance.json       # ⭐ Main results
│   │   ├── advanced_feature_importance.csv       # ⭐ Feature ranking
│   │   ├── calibration_results.json              # Calibration results
│   │   ├── credit_offers.json                    # Credit offers (142 MB)
│   │   └── optimization_results.json             # ⭐ Optimization results
│   │
│   └── 📁 plots/
│       ├── advanced_shap_summary.png             # SHAP explanations
│       └── advanced_feature_importance.png       # Feature importance plot
│
├── 📁 Core Scripts/                      # Supporting scripts
│   ├── etl_customer_data.py             # Nessie API integration
│   ├── labels_improved.py               # Active labeling logic
│   ├── model_gbm.py                     # Baseline model (if needed)
│   ├── db_config.py                     # Database config (if using DB)
│   ├── create_database.py               # DB creation (if using DB)
│   └── populate_data_db.py              # DB population (if using DB)
│
├── 📁 archive/
│   └── old_docs/                        # Historical documentation
│       ├── PHASE3_SUMMARY.md
│       ├── PHASE3_IMPROVED_SUMMARY.md
│       ├── PHASE5_SUMMARY.md
│       ├── MIGRATION_SUMMARY.md
│       └── ...
│
├── 📄 requirements.txt                   # Python dependencies
└── 📜 quick_test.sh                      # Quick test script
```

---

## 🎯 **KEY FILES EXPLANATION**

### **Main Training Workflow:**

1. **Source Data**: `dataset/loan_reduced.csv` (287 MB, 2.26M rows)
2. **Training**: `datasetModel/train_from_loan_dataset.py`
3. **Feature Engineering**: `datasetModel/loan_feature_engineering.py`
4. **Model Architecture**: `datasetModel/advanced_banking_model.py`
5. **Optimization**: `datasetModel/model_optimizer.py`

### **Best Model:**
- **File**: `datasetModel/models/model_Exp1_25features_balanced.txt`
- **AUC**: 0.754 (+0.030 vs baseline)
- **Overfitting**: 0.004 gap (vs 0.212 baseline)
- **Features**: 24 (optimized from 28)

### **Results:**
- **Performance**: `datasetModel/reports/advanced_model_performance.json`
- **Features**: `datasetModel/reports/advanced_feature_importance.csv`
- **Optimization**: `datasetModel/reports/optimization_results.json`

---

## 📊 **DISK SPACE**

| Category | Size | Count |
|----------|------|-------|
| Source data | 287 MB | 1 file |
| Models | ~50 MB | 9 files |
| Reports | ~145 MB | 5 files |
| Code | ~1 MB | ~15 files |
| Documentation | ~500 KB | ~12 files |
| **TOTAL** | **~483 MB** | **~42 files** |

**Saved**: ~840 MB from cleanup (deleted intermediate/generated files)

---

## 🚀 **HOW TO USE**

### **1. Quick Test:**
```bash
cd datasetModel
bash quick_test.sh
```

### **2. Full Training:**
```bash
cd datasetModel
python train_from_loan_dataset.py
```

### **3. Optimization Experiments:**
```bash
cd datasetModel
python model_optimizer.py
```

### **4. Load Results:**
```python
import json
import pandas as pd

# Load results
with open('datasetModel/reports/advanced_model_performance.json', 'r') as f:
    results = json.load(f)

# Load feature importance
importance = pd.read_csv('datasetModel/reports/advanced_feature_importance.csv')
```

---

## ✅ **CLEANUP SUMMARY**

**Deleted:**
- ~53 files (~840 MB)
- Redundant intermediate datasets
- Old test data
- Obsolete scripts
- Duplicate documentation

**Kept:**
- Source data (`loan_reduced.csv`)
- Core model scripts
- Best trained models
- Current results and reports
- Essential documentation

**Archived:**
- Historical phase summaries
- Old documentation

---

## 📝 **NOTES**

1. **Intermediate datasets** (enhanced/improved) can be regenerated by running `train_from_loan_dataset.py`
2. **Models** are trained and saved automatically during execution
3. **Reports** are generated automatically after training
4. **Archive** folder contains historical documentation for reference
5. **Source data** is the single source of truth (`loan_reduced.csv`)

---

**Last Cleanup**: 2025-10-25  
**Cleanup Script**: `cleanup_project.sh`
