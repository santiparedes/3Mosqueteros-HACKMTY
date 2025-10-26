"""
TRAINING SCRIPT FOR LOAN DATASET
=================================

Trains the advanced banking model using LendingClub loan_reduced.csv dataset.
"""
import pandas as pd
import numpy as np
import lightgbm as lgb
import joblib
import json
import os
from datetime import datetime
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import roc_auc_score, average_precision_score, classification_report
from imblearn.over_sampling import SMOTE
import warnings
warnings.filterwarnings('ignore')

from loan_feature_engineering import LoanFeatureEngineer
from advanced_banking_model import BankingRiskModel


class LoanDatasetTrainer:
    """
    Trains advanced banking model from loan_reduced.csv
    """

    def __init__(self, dataset_path: str, sample_size: int = None):
        """
        Args:
            dataset_path: Path to loan_reduced.csv
            sample_size: Number of rows to sample (None = use all data)
        """
        self.dataset_path = dataset_path
        self.sample_size = sample_size
        self.feature_engineer = LoanFeatureEngineer()
        self.banking_model = BankingRiskModel()

    def load_data(self) -> pd.DataFrame:
        """
        Load loan dataset with optional sampling
        """
        print("=" * 80)
        print("📂 LOADING LOAN DATASET")
        print("=" * 80)

        print(f"\nDataset: {self.dataset_path}")

        if self.sample_size:
            print(f"Sampling: {self.sample_size:,} rows")
            # Load with sampling for faster iteration
            # Get total rows first
            total_rows = sum(1 for _ in open(self.dataset_path)) - 1  # Exclude header

            # Calculate skip probability
            skip = sorted(np.random.choice(range(1, total_rows + 1),
                                          size=total_rows - self.sample_size,
                                          replace=False))

            df = pd.read_csv(self.dataset_path, skiprows=skip)
        else:
            print("Loading full dataset...")
            # Load in chunks to handle large file
            chunk_size = 100000
            chunks = []

            for i, chunk in enumerate(pd.read_csv(self.dataset_path, chunksize=chunk_size)):
                chunks.append(chunk)
                if (i + 1) % 10 == 0:
                    print(f"  Loaded {(i + 1) * chunk_size:,} rows...")

            df = pd.concat(chunks, ignore_index=True)

        print(f"\n✓ Loaded {len(df):,} rows, {len(df.columns)} columns")
        print(f"✓ Memory usage: {df.memory_usage(deep=True).sum() / 1024**2:.1f} MB")

        return df

    def engineer_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Apply feature engineering
        """
        print("\n" + "=" * 80)
        print("⚙️  FEATURE ENGINEERING")
        print("=" * 80)

        transformed = self.feature_engineer.transform_dataset(df)

        # Display summary
        print("\n📊 Feature Summary:")
        summary = self.feature_engineer.get_feature_summary(transformed)
        print(summary[['age', 'income_monthly', 'current_debt', 'dti', 'label']])

        # Check label distribution
        label_dist = transformed['label'].value_counts()
        print(f"\n📊 Label Distribution:")
        print(f"  Good (0): {label_dist.get(0, 0):,} ({label_dist.get(0, 0) / len(transformed) * 100:.1f}%)")
        print(f"  Bad (1):  {label_dist.get(1, 0):,} ({label_dist.get(1, 0) / len(transformed) * 100:.1f}%)")

        return transformed

    def create_train_validation_test_split(self, df: pd.DataFrame) -> tuple:
        """
        Create temporal train/validation/test splits
        """
        print("\n" + "=" * 80)
        print("✂️  CREATING DATA SPLITS")
        print("=" * 80)

        # Create temporal split (70/15/15)
        # Add split column
        n = len(df)
        train_size = int(0.7 * n)
        valid_size = int(0.15 * n)

        df['split'] = 'test'
        df.loc[:train_size, 'split'] = 'train'
        df.loc[train_size:train_size + valid_size, 'split'] = 'validation'

        train_df = df[df['split'] == 'train'].copy()
        valid_df = df[df['split'] == 'validation'].copy()
        test_df = df[df['split'] == 'test'].copy()

        print(f"\n✓ Train:      {len(train_df):,} rows ({len(train_df) / n * 100:.1f}%)")
        print(f"✓ Validation: {len(valid_df):,} rows ({len(valid_df) / n * 100:.1f}%)")
        print(f"✓ Test:       {len(test_df):,} rows ({len(test_df) / n * 100:.1f}%)")

        # Save to CSV for compatibility with advanced_banking_model.py
        print("\n💾 Saving split datasets...")
        train_df.to_csv('dataset_train_improved.csv', index=False)
        valid_df.to_csv('dataset_validation_improved.csv', index=False)
        test_df.to_csv('dataset_test_improved.csv', index=False)

        print("✓ Saved:")
        print("  - dataset_train_improved.csv")
        print("  - dataset_validation_improved.csv")
        print("  - dataset_test_improved.csv")

        return train_df, valid_df, test_df

    def prepare_model_features(self, train_df, valid_df, test_df) -> tuple:
        """
        Prepare features for model training
        """
        print("\n" + "=" * 80)
        print("🔧 PREPARING MODEL FEATURES")
        print("=" * 80)

        # Use the banking model's feature preparation
        # But first ensure we have all required base features
        required_features = [
            'age', 'income_monthly', 'payroll_streak', 'payroll_variance',
            'spending_monthly', 'spending_var_6m', 'current_debt',
            'dti', 'utilization'
        ]

        print("\n✓ Checking required features...")
        for feat in required_features:
            if feat not in train_df.columns:
                print(f"  ⚠️  Missing feature: {feat}")
            else:
                print(f"  ✓ {feat}")

        # Now apply the banking model's advanced feature creation
        print("\n🚀 Creating advanced banking features...")
        train_enhanced = self.banking_model.create_banking_features(train_df)
        valid_enhanced = self.banking_model.create_banking_features(valid_df)
        test_enhanced = self.banking_model.create_banking_features(test_df)

        print(f"\n✓ Enhanced features: {len(train_enhanced.columns)} columns")

        # Prepare final feature sets
        X_train, y_train, X_valid, y_valid, X_test, y_test = \
            self.banking_model.prepare_model_data(train_enhanced, valid_enhanced, test_enhanced)

        print(f"\n✓ Final feature matrix:")
        print(f"  X_train: {X_train.shape}")
        print(f"  X_valid: {X_valid.shape}")
        print(f"  X_test:  {X_test.shape}")

        return X_train, y_train, X_valid, y_valid, X_test, y_test

    def train_model(self, X_train, y_train, X_valid, y_valid):
        """
        Train the advanced banking model
        """
        print("\n" + "=" * 80)
        print("🤖 TRAINING MODEL")
        print("=" * 80)

        self.banking_model.train_advanced_model(X_train, y_train, X_valid, y_valid)

        return self.banking_model.model

    def evaluate_and_save(self, X_train, y_train, X_valid, y_valid, X_test, y_test):
        """
        Evaluate model and save all outputs
        """
        print("\n" + "=" * 80)
        print("📊 EVALUATION & SAVING")
        print("=" * 80)

        # Evaluate
        results = self.banking_model.evaluate_model(
            X_train, y_train, X_valid, y_valid, X_test, y_test
        )

        # Generate credit offers
        offers = self.banking_model.generate_credit_offers(X_test, y_test)

        # Generate SHAP explanations
        shap_values, expected_value = self.banking_model.generate_shap_explanations(X_test, y_test)

        # Save model
        self.banking_model.save_model()

        return results, offers

    def run_full_pipeline(self):
        """
        Run the complete training pipeline
        """
        print("\n" + "🚀" * 40)
        print("ADVANCED BANKING MODEL - LOAN DATASET TRAINING")
        print("🚀" * 40 + "\n")

        # 1. Load data
        df = self.load_data()

        # 2. Feature engineering
        transformed = self.engineer_features(df)

        # 3. Create splits
        train_df, valid_df, test_df = self.create_train_validation_test_split(transformed)

        # 4. Prepare features
        X_train, y_train, X_valid, y_valid, X_test, y_test = \
            self.prepare_model_features(train_df, valid_df, test_df)

        # 5. Train model
        model = self.train_model(X_train, y_train, X_valid, y_valid)

        # 6. Evaluate and save
        results, offers = self.evaluate_and_save(
            X_train, y_train, X_valid, y_valid, X_test, y_test
        )

        # Final summary
        self.print_final_summary(results, offers)

        return results, offers

    def print_final_summary(self, results, offers):
        """
        Print final summary of training results
        """
        print("\n" + "=" * 80)
        print("✅ TRAINING COMPLETE!")
        print("=" * 80)

        print("\n📊 MODEL PERFORMANCE:")
        for dataset_name, metrics in results.items():
            print(f"\n  {dataset_name}:")
            print(f"    AUC-ROC:   {metrics['auc_roc']:.4f}")
            print(f"    PR-AUC:    {metrics['pr_auc']:.4f}")
            print(f"    Accuracy:  {metrics['accuracy']:.4f}")
            print(f"    Precision: {metrics['precision']:.4f}")
            print(f"    Recall:    {metrics['recall']:.4f}")

        print(f"\n💳 CREDIT OFFERS:")
        print(f"  Total offers generated: {len(offers)}")

        # Risk tier distribution
        tiers = {}
        for offer in offers:
            tier = offer['risk_tier']
            tiers[tier] = tiers.get(tier, 0) + 1

        print(f"\n  Risk Tier Distribution:")
        for tier, count in sorted(tiers.items()):
            print(f"    {tier:15s}: {count:6d} ({count / len(offers) * 100:5.1f}%)")

        print("\n📁 OUTPUT FILES:")
        print("  Models:")
        print("    - models/advanced_banking_model.txt")
        print("    - models/advanced_scaler.pkl")
        print("    - models/advanced_model_metadata.json")
        print("\n  Reports:")
        print("    - reports/advanced_model_performance.json")
        print("    - reports/credit_offers.json")
        print("    - reports/advanced_feature_importance.csv")
        print("\n  Plots:")
        print("    - plots/advanced_shap_summary.png")
        print("    - plots/advanced_feature_importance.png")

        print("\n" + "🎉" * 40)
        print("Model ready for deployment!")
        print("🎉" * 40 + "\n")


def main():
    """
    Main entry point
    """
    import argparse

    parser = argparse.ArgumentParser(description='Train banking model from loan dataset')
    parser.add_argument(
        '--dataset',
        type=str,
        default='dataset/loan_reduced.csv',
        help='Path to loan_reduced.csv'
    )
    parser.add_argument(
        '--sample',
        type=int,
        default=None,
        help='Sample size for faster testing (default: use all data)'
    )

    args = parser.parse_args()

    # Create trainer
    trainer = LoanDatasetTrainer(
        dataset_path=args.dataset,
        sample_size=args.sample
    )

    # Run pipeline
    results, offers = trainer.run_full_pipeline()

    return results, offers


if __name__ == "__main__":
    main()
