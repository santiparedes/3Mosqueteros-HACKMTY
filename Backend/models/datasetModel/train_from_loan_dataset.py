"""
Main Training Script for Loan Dataset
Trains advanced banking model using loan_reduced.csv
"""
import argparse
import os
import sys
import pandas as pd
import numpy as np
from datetime import datetime

# Import feature engineering and advanced model
from loan_feature_engineering import LoanFeatureEngineer
from advanced_banking_model import BankingRiskModel

def load_dataset(dataset_path, sample_size=None):
    """Load dataset with optional sampling"""
    print("=" * 80)
    print("📂 LOADING LOAN DATASET")
    print("=" * 80)
    
    if not os.path.exists(dataset_path):
        print(f"❌ Error: Dataset not found at {dataset_path}")
        sys.exit(1)
    
    print(f"\nDataset: {dataset_path}")
    
    if sample_size:
        print(f"Sampling: {sample_size:,} rows")
        df = pd.read_csv(dataset_path, nrows=sample_size)
    else:
        print("Loading full dataset...")
        df = pd.read_csv(dataset_path)
    
    print(f"\n✓ Loaded {len(df):,} rows, {len(df.columns)} columns")
    print(f"✓ Memory usage: {df.memory_usage(deep=True).sum() / 1024**2:.1f} MB")
    
    return df

def create_splits(df, train_pct=0.70, valid_pct=0.15):
    """
    Create train/validation/test splits
    """
    print("\n" + "=" * 80)
    print("✂️  CREATING DATA SPLITS")
    print("=" * 80)
    
    # Shuffle data
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)
    
    # Calculate split indices
    n = len(df)
    train_end = int(n * train_pct)
    valid_end = train_end + int(n * valid_pct)
    
    # Create splits
    train_df = df[:train_end].copy()
    valid_df = df[train_end:valid_end].copy()
    test_df = df[valid_end:].copy()
    
    # Add split indicator
    train_df['split'] = 'train'
    valid_df['split'] = 'validation'
    test_df['split'] = 'test'
    
    print(f"\n✓ Train:      {len(train_df):,} rows ({len(train_df)/n*100:.1f}%)")
    print(f"✓ Validation: {len(valid_df):,} rows ({len(valid_df)/n*100:.1f}%)")
    print(f"✓ Test:       {len(test_df):,} rows ({len(test_df)/n*100:.1f}%)")
    
    # Save splits
    train_df.to_csv('dataset_train_improved.csv', index=False)
    valid_df.to_csv('dataset_validation_improved.csv', index=False)
    test_df.to_csv('dataset_test_improved.csv', index=False)
    
    print("\n✓ Splits saved to CSV files")
    
    return train_df, valid_df, test_df

def main():
    """Main training function"""
    parser = argparse.ArgumentParser(description='Train advanced banking model from loan dataset')
    parser.add_argument('--dataset', type=str, default='../dataset/loan_reduced.csv',
                       help='Path to loan dataset CSV file')
    parser.add_argument('--sample', type=int, default=None,
                       help='Sample size (for testing)')
    
    args = parser.parse_args()
    
    print("🚀 ADVANCED BANKING MODEL - TRAINING FROM LOAN DATASET")
    print("=" * 80)
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Step 1: Load dataset
    raw_df = load_dataset(args.dataset, args.sample)
    
    # Step 2: Feature Engineering
    print("\n" + "=" * 80)
    print("⚙️  FEATURE ENGINEERING")
    print("=" * 80)
    
    engineer = LoanFeatureEngineer()
    transformed_df = engineer.transform_dataset(raw_df)
    
    # Step 3: Create Splits
    train_df, valid_df, test_df = create_splits(transformed_df)
    
    # Step 4: Advanced Banking Model
    print("\n" + "=" * 80)
    print("🏦 ADVANCED BANKING MODEL TRAINING")
    print("=" * 80)
    
    # Create model instance
    banking_model = BankingRiskModel()
    
    # Load enhanced data
    train_enhanced, valid_enhanced, test_enhanced, _ = banking_model.load_and_enhance_data()
    
    if train_enhanced is None:
        print("❌ Error: Could not load enhanced datasets")
        sys.exit(1)
    
    # Prepare model data
    X_train, y_train, X_valid, y_valid, X_test, y_test = banking_model.prepare_model_data(
        train_enhanced, valid_enhanced, test_enhanced
    )
    
    # Train model
    banking_model.train_advanced_model(X_train, y_train, X_valid, y_valid)
    
    # Evaluate model
    results = banking_model.evaluate_model(X_train, y_train, X_valid, y_valid, X_test, y_test)
    
    # Generate credit offers
    offers = banking_model.generate_credit_offers(X_test, y_test)
    
    # Generate SHAP explanations
    shap_values, expected_value = banking_model.generate_shap_explanations(X_test, y_test)
    
    # Save model
    banking_model.save_model()
    
    # Final summary
    print("\n" + "=" * 80)
    print("✅ TRAINING COMPLETE!")
    print("=" * 80)
    
    print("\n📊 MODEL PERFORMANCE:")
    for dataset_name in ['Train', 'Validation', 'Test']:
        metrics = results[dataset_name]
        print(f"\n  {dataset_name}:")
        print(f"    AUC-ROC:   {metrics['auc_roc']:.4f}")
        print(f"    Accuracy:  {metrics['accuracy']:.4f}")
        print(f"    Precision: {metrics['precision']:.4f}")
        print(f"    Recall:    {metrics['recall']:.4f}")
    
    print(f"\n💳 CREDIT OFFERS:")
    print(f"  Total offers generated: {len(offers):,}")
    
    # Count by risk tier
    risk_tier_counts = {}
    for offer in offers:
        tier = offer['risk_tier']
        risk_tier_counts[tier] = risk_tier_counts.get(tier, 0) + 1
    
    print(f"\n  Risk Tier Distribution:")
    for tier, count in sorted(risk_tier_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"    {tier:15}: {count:6,} ({count/len(offers)*100:5.1f}%)")
    
    print("\n📁 FILES GENERATED:")
    print("  🤖 models/advanced_banking_model.txt")
    print("  🤖 models/advanced_scaler.pkl")
    print("  📊 reports/advanced_model_performance.json")
    print("  📊 reports/credit_offers.json")
    print("  📊 reports/advanced_feature_importance.csv")
    print("  📈 plots/advanced_shap_summary.png")
    print("  📈 plots/advanced_feature_importance.png")
    
    print(f"\nFinished: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("\n🎉 Training complete! Model ready for production.")

if __name__ == "__main__":
    main()
