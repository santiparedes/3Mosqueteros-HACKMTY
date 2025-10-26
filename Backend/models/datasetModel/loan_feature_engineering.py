"""
Feature Engineering Module for Loan Dataset
Maps LendingClub loan data to model features
"""
import pandas as pd
import numpy as np
import re
from datetime import datetime

class LoanFeatureEngineer:
    """
    Transforms LendingClub loan dataset into features for the banking model
    """
    
    def __init__(self):
        self.features_created = []
    
    def parse_employment_length(self, emp_length):
        """
        Parse employment length string to months
        Examples:
        - "10+ years" -> 120
        - "3 years" -> 36
        - "8 months" -> 8
        - "< 1 year" -> 6
        """
        if pd.isna(emp_length):
            return 12  # Default 1 year
        
        emp_str = str(emp_length)
        
        # Handle "n+ years" pattern
        match = re.search(r'(\d+)\+?\s*years?', emp_str, re.IGNORECASE)
        if match:
            return int(match.group(1)) * 12
        
        # Handle "n months" pattern
        match = re.search(r'(\d+)\s*months?', emp_str, re.IGNORECASE)
        if match:
            return int(match.group(1))
        
        # Handle "< 1 year"
        if '< 1' in emp_str or '<1' in emp_str:
            return 6
        
        return 12  # Default
    
    def transform_dataset(self, df):
        """
        Transform raw loan dataset to model features
        
        Args:
            df: DataFrame with LendingClub columns
            
        Returns:
            DataFrame with model features
        """
        print("Starting feature engineering for {} rows...".format(len(df)))
        
        result_df = pd.DataFrame()
        
        # Step 1: Demographics
        print("  1/8 Processing demographics...")
        result_df['age'] = self._estimate_age(df)
        result_df['zone'] = df.get('addr_state', 'Unknown')
        
        # Step 2: Employment
        print("  2/8 Processing employment data...")
        result_df['payroll_streak'] = df['emp_length'].apply(self.parse_employment_length) if 'emp_length' in df.columns else 12
        result_df['employment_type'] = ((df['emp_title'].notna()) & (result_df['payroll_streak'] > 12)).astype(int) if 'emp_title' in df.columns else 1
        
        # Step 3: Income
        print("  3/8 Processing income data...")
        result_df['income_monthly'] = (df['annual_inc'] / 12).fillna(df['annual_inc'] / 12)
        result_df['payroll_variance'] = self._calculate_payroll_variance(result_df['payroll_streak'])
        
        # Step 4: Debt
        print("  4/8 Processing debt data...")
        result_df['current_debt'] = df.get('out_prncp', 0).fillna(0)
        result_df['dti'] = (df['dti'] / 100).fillna(0)
        result_df['utilization'] = (df['revol_util'] / 100).fillna(0)
        
        # Step 5: Spending
        print("  5/8 Processing spending data...")
        result_df['spending_monthly'] = self._estimate_spending(df, result_df['income_monthly'])
        result_df['spending_var_6m'] = self._calculate_spending_variance(df)
        
        # Step 6: Credit Score
        print("  6/8 Processing credit score data...")
        result_df['score_buro'] = self._estimate_credit_score(df)
        result_df['max_days_late'] = self._calculate_max_days_late(df)
        result_df['on_time_rate'] = self._calculate_on_time_rate(df)
        
        # Step 7: Target Label
        print("  7/8 Creating target label...")
        result_df['label'] = self._create_target_label(df)
        
        # Step 8: Cleanup
        print("  8/8 Cleaning and validating...")
        result_df = self._clean_data(result_df)
        
        print(f"✓ Feature engineering complete. Output shape: {result_df.shape}")
        
        # Print label distribution
        if 'label' in result_df.columns:
            label_counts = result_df['label'].value_counts()
            print(f"\n📊 Label Distribution:")
            print(f"  Good (0): {label_counts.get(0, 0):,} ({label_counts.get(0, 0)/len(result_df)*100:.1f}%)")
            print(f"  Bad (1):  {label_counts.get(1, 0):,} ({label_counts.get(1, 0)/len(result_df)*100:.1f}%)")
        
        return result_df
    
    def _estimate_age(self, df):
        """Estimate age based on employment length"""
        payroll_streak = df['emp_length'].apply(self.parse_employment_length) if 'emp_length' in df.columns else pd.Series([12] * len(df))
        
        # Age = 22 (start working) + years employed + random offset
        age = 22 + (payroll_streak / 12) + np.random.randint(5, 15, size=len(df))
        return age.clip(22, 70)
    
    def _calculate_payroll_variance(self, payroll_streak):
        """Calculate income stability based on employment tenure"""
        # More tenure = less variance (more stable)
        # Avoid division by zero
        variance = 0.5 / (1 + payroll_streak / 12)
        # Replace any infinities with a default value
        variance = np.where(np.isfinite(variance), variance, 0.1)
        return variance
    
    def _estimate_spending(self, df, income_monthly):
        """Estimate monthly spending"""
        # Base spending = installment + 30% of income for other expenses
        installment = df.get('installment', 0).fillna(0)
        other_spending = income_monthly.clip(lower=0) * 0.3
        return (installment + other_spending).clip(lower=0, upper=income_monthly * 2)
    
    def _calculate_spending_variance(self, df):
        """Calculate spending volatility based on payment history"""
        # More delinquencies = more variance
        delinq = df.get('delinq_2yrs', 0).fillna(0)
        return 0.1 + (delinq * 0.05)
    
    def _estimate_credit_score(self, df):
        """Estimate credit score based on interest rate"""
        # Higher interest rate = lower credit score
        int_rate = df.get('int_rate', 0).fillna(0)
        
        # Convert interest rate string to float if needed
        if isinstance(int_rate.iloc[0] if len(int_rate) > 0 else 0, str):
            int_rate = int_rate.str.rstrip('%').astype(float)
        
        # Inverse relationship: high rate -> low score
        # Score range: 300-850, typical range: 600-800
        estimated_score = 750 - (int_rate * 10)
        return estimated_score.clip(300, 850)
    
    def _calculate_max_days_late(self, df):
        """Calculate maximum days late based on delinquencies"""
        delinq = df.get('delinq_2yrs', 0).fillna(0)
        # Each delinquency represents 30-90 days late
        return delinq * np.random.randint(30, 90, size=len(df))
    
    def _calculate_on_time_rate(self, df):
        """Calculate on-time payment rate"""
        delinq = df.get('delinq_2yrs', 0).fillna(0)
        # Penalty of 5% per delinquency
        return (1.0 - (delinq * 0.05)).clip(0, 1)
    
    def _create_target_label(self, df):
        """
        Create binary label (0=good, 1=bad) based on loan status
        
        Good (0): Current, Fully Paid, Issued, In Grace Period
        Bad (1): Charged Off, Default, Late payments
        """
        if 'loan_status' not in df.columns:
            # If no loan_status column, return all zeros
            return pd.Series([0] * len(df))
        
        loan_status = df['loan_status'].str.lower()
        
        # Bad loan statuses
        bad_statuses = ['charged off', 'default', 'late (31-120 days)', 'late (16-30 days)']
        
        # Create binary label
        label = loan_status.apply(
            lambda x: 1 if any(status in str(x).lower() for status in bad_statuses) else 0
        )
        
        return label
    
    def _clean_data(self, df):
        """Clean and validate data"""
        # Replace infinite values with NaN
        df = df.replace([np.inf, -np.inf], np.nan)
        
        # Fill NaN values with median or default
        for col in df.columns:
            if df[col].isnull().any():
                if df[col].dtype in ['float64', 'int64']:
                    median_val = df[col].median()
                    if pd.notna(median_val):
                        df[col] = df[col].fillna(median_val)
                    else:
                        df[col] = df[col].fillna(0)
                else:
                    mode_val = df[col].mode()
                    if len(mode_val) > 0:
                        df[col] = df[col].fillna(mode_val[0])
                    else:
                        df[col] = df[col].fillna(0)
        
        # Replace any remaining infinities
        df = df.replace([np.inf, -np.inf], np.nan)
        df = df.fillna(0)
        
        return df

# Quick test function
def test_feature_engineering():
    """Test feature engineering with synthetic data"""
    print("🧪 Testing Loan Feature Engineering...")
    print("=" * 80)
    
    # Create synthetic loan data
    n_samples = 100
    synthetic_data = {
        'annual_inc': np.random.randint(30000, 150000, n_samples),
        'dti': np.random.uniform(5, 45, n_samples),
        'revol_util': np.random.uniform(0, 100, n_samples),
        'addr_state': np.random.choice(['CA', 'NY', 'TX', 'FL', 'IL'], n_samples),
        'out_prncp': np.random.randint(0, 50000, n_samples),
        'installment': np.random.uniform(100, 1000, n_samples),
        'int_rate': np.random.uniform(5, 30, n_samples),
        'delinq_2yrs': np.random.randint(0, 3, n_samples),
        'emp_length': np.random.choice(['10+ years', '5 years', '3 years', '< 1 year', '2 years'], n_samples),
        'emp_title': np.random.choice(['Engineer', 'Teacher', 'Manager', None], n_samples),
        'loan_status': np.random.choice([
            'Fully Paid', 'Current', 'Charged Off', 'Default', 
            'Late (31-120 days)', 'In Grace Period'
        ], n_samples)
    }
    
    df = pd.DataFrame(synthetic_data)
    
    # Test feature engineering
    engineer = LoanFeatureEngineer()
    transformed = engineer.transform_dataset(df)
    
    print("\n✅ Feature Engineering Test Complete!")
    print(f"\nOutput shape: {transformed.shape}")
    print(f"\nFeatures created: {list(transformed.columns)}")
    
    return transformed

if __name__ == "__main__":
    test_feature_engineering()
