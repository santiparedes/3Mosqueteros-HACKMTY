"""
FEATURE ENGINEERING FOR LOAN DATASET
======================================

Maps LendingClub loan dataset variables to banking model features.
"""
import pandas as pd
import numpy as np
import re
from typing import Dict, Tuple


class LoanFeatureEngineer:
    """
    Transforms LendingClub loan data to banking model features
    """

    def __init__(self):
        self.state_risk_mapping = self._create_state_risk_mapping()

    def transform_dataset(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Main transformation pipeline

        Args:
            df: Raw loan dataset

        Returns:
            Transformed dataframe with model features
        """
        print(f"Starting feature engineering for {len(df):,} rows...")

        # Make a copy to avoid modifying original
        transformed = df.copy()

        # 1. Demographics / Zone
        print("  1/8 Processing demographics...")
        transformed['zone'] = self._map_zone(transformed)
        transformed['age'] = self._estimate_age(transformed)

        # 2. Employment / Stability
        print("  2/8 Processing employment data...")
        transformed['payroll_streak'] = self._map_payroll_streak(transformed)
        transformed['employment_type'] = self._map_employment_type(transformed)

        # 3. Income / Payroll
        print("  3/8 Processing income data...")
        transformed['income_monthly'] = transformed['annual_inc'] / 12
        transformed['payroll_variance'] = self._calculate_payroll_variance(transformed)

        # 4. Debt and Loans
        print("  4/8 Processing debt data...")
        transformed['current_debt'] = self._calculate_current_debt(transformed)
        transformed['dti'] = transformed['dti'] / 100  # Convert percentage to decimal
        transformed['utilization'] = transformed['revol_util'] / 100  # Convert percentage to decimal

        # 5. Spending
        print("  5/8 Processing spending data...")
        transformed['spending_monthly'] = self._estimate_spending(transformed)
        transformed['spending_var_6m'] = self._estimate_spending_variance(transformed)

        # 6. Credit Score and Risk
        print("  6/8 Processing credit score data...")
        transformed['score_buro'] = self._estimate_credit_score(transformed)
        transformed['max_days_late'] = self._map_delinquency(transformed)
        transformed['on_time_rate'] = self._calculate_on_time_rate(transformed)

        # 7. Target Label
        print("  7/8 Creating target label...")
        transformed['label'] = self._create_label(transformed)

        # 8. Clean and validate
        print("  8/8 Cleaning and validating...")
        transformed = self._clean_and_validate(transformed)

        print(f"✓ Feature engineering complete. Output shape: {transformed.shape}")

        return transformed

    # =====================================================================
    # ZONE / DEMOGRAPHICS
    # =====================================================================

    def _map_zone(self, df: pd.DataFrame) -> pd.Series:
        """Map state to zone categories"""
        # Use state directly or group into regions
        return df['addr_state'].fillna('UNKNOWN')

    def _estimate_age(self, df: pd.DataFrame) -> pd.Series:
        """
        Estimate age from employment length
        Assumption: Base age 22 + years employed + random variance
        """
        emp_years = df['emp_length'].apply(self._parse_emp_length)

        # Base age 25, add employment years, add random variance
        base_age = 25
        age = base_age + emp_years + np.random.randint(5, 15, size=len(df))

        # Cap between 18 and 75
        age = np.clip(age, 18, 75)

        return age

    # =====================================================================
    # EMPLOYMENT
    # =====================================================================

    def _map_payroll_streak(self, df: pd.DataFrame) -> pd.Series:
        """
        Convert emp_length to months of payroll streak
        """
        return df['emp_length'].apply(self._parse_emp_length)

    def _map_employment_type(self, df: pd.DataFrame) -> pd.Series:
        """
        Map employment title to employment type (formal/informal)
        Simple heuristic: if emp_title exists and emp_length > 1 year → formal
        """
        has_title = df['emp_title'].notna() & (df['emp_title'] != '')
        has_length = df['emp_length'].apply(self._parse_emp_length) >= 12

        return (has_title & has_length).astype(int)  # 1 = formal, 0 = informal

    def _parse_emp_length(self, emp_length: str) -> int:
        """
        Parse employment length to months

        Examples:
            "10+ years" -> 120
            "< 1 year" -> 6
            "3 years" -> 36
        """
        if pd.isna(emp_length) or emp_length == '':
            return 0

        emp_length = str(emp_length).lower()

        # Handle special cases
        if '< 1 year' in emp_length or 'less than 1' in emp_length:
            return 6  # 6 months

        if '10+ years' in emp_length or 'more than 10' in emp_length:
            return 120  # 10 years

        # Extract number
        match = re.search(r'(\d+)', emp_length)
        if match:
            years = int(match.group(1))
            return years * 12

        return 0

    # =====================================================================
    # INCOME / PAYROLL
    # =====================================================================

    def _calculate_payroll_variance(self, df: pd.DataFrame) -> pd.Series:
        """
        Estimate payroll variance based on employment stability
        Lower variance = more stable employment
        """
        emp_months = df['emp_length'].apply(self._parse_emp_length)

        # More employment = less variance
        # Range: 0.05 (very stable) to 0.5 (unstable)
        variance = 0.5 / (1 + emp_months / 12)

        # Add random noise
        variance = variance * (1 + np.random.uniform(-0.2, 0.2, size=len(df)))

        return variance.clip(0.01, 0.8)

    # =====================================================================
    # DEBT
    # =====================================================================

    def _calculate_current_debt(self, df: pd.DataFrame) -> pd.Series:
        """
        Calculate current debt from available fields
        Priority: out_prncp > loan_amnt
        """
        # Use outstanding principal if available, otherwise use loan amount
        current_debt = df['out_prncp'].fillna(df['loan_amnt'])

        # If both are missing, derive from DTI
        mask_missing = current_debt.isna()
        if mask_missing.any():
            # Derive from DTI: debt = dti * income
            income_monthly = df.loc[mask_missing, 'annual_inc'] / 12
            dti_decimal = df.loc[mask_missing, 'dti'] / 100
            current_debt.loc[mask_missing] = income_monthly * dti_decimal

        return current_debt.fillna(0)

    # =====================================================================
    # SPENDING
    # =====================================================================

    def _estimate_spending(self, df: pd.DataFrame) -> pd.Series:
        """
        Estimate monthly spending from installment + debt obligations
        """
        # Base spending = installment payment
        base_spending = df['installment'].fillna(0)

        # Add estimated living expenses (30% of income as baseline)
        income_monthly = df['annual_inc'] / 12
        living_expenses = income_monthly * 0.3

        # Total spending
        spending = base_spending + living_expenses

        # Add random variance ±15%
        spending = spending * (1 + np.random.uniform(-0.15, 0.15, size=len(df)))

        return spending.clip(0, income_monthly * 0.95)  # Max 95% of income

    def _estimate_spending_variance(self, df: pd.DataFrame) -> pd.Series:
        """
        Estimate spending variance based on payment behavior
        More delinquencies = higher variance
        """
        # Base variance
        base_variance = 0.15

        # Increase variance for people with delinquencies
        delinq_factor = 1 + (df['delinq_2yrs'].fillna(0) * 0.1)

        variance = base_variance * delinq_factor

        # Add random noise
        variance = variance * (1 + np.random.uniform(-0.3, 0.3, size=len(df)))

        return variance.clip(0.05, 0.8)

    # =====================================================================
    # CREDIT SCORE
    # =====================================================================

    def _estimate_credit_score(self, df: pd.DataFrame) -> pd.Series:
        """
        Estimate credit score from interest rate and risk factors
        Higher int_rate → Lower score
        """
        # Use interest rate as inverse proxy
        # int_rate range typically 5-30%
        # Score range 300-850

        int_rate = df['int_rate'].fillna(df['int_rate'].median())

        # Inverse relationship: high rate = low score
        # int_rate 5% → 850, int_rate 30% → 300
        score = 850 - ((int_rate - 5) / 25) * 550

        # Adjust for delinquencies
        score = score - (df['delinq_2yrs'].fillna(0) * 50)

        # Adjust for public records
        score = score - (df['pub_rec'].fillna(0) * 30)

        return score.clip(300, 850)

    def _map_delinquency(self, df: pd.DataFrame) -> pd.Series:
        """
        Map delinquencies to max days late
        Estimate: each delinq_2yrs ≈ 30-90 days late
        """
        delinq_count = df['delinq_2yrs'].fillna(0)

        # Each delinquency ≈ 30-90 days late
        max_days = delinq_count * np.random.randint(30, 90, size=len(df))

        return max_days.clip(0, 180)

    def _calculate_on_time_rate(self, df: pd.DataFrame) -> pd.Series:
        """
        Calculate on-time payment rate from total_pymnt and delinquencies
        """
        # Base rate: 100% if no delinquencies
        base_rate = 1.0

        # Reduce for delinquencies
        delinq_penalty = df['delinq_2yrs'].fillna(0) * 0.05  # -5% per delinquency

        # Reduce for collections
        collections_penalty = df['collections_12_mths_ex_med'].fillna(0) * 0.1  # -10% per collection

        on_time_rate = base_rate - delinq_penalty - collections_penalty

        return on_time_rate.clip(0, 1)

    # =====================================================================
    # TARGET LABEL
    # =====================================================================

    def _create_label(self, df: pd.DataFrame) -> pd.Series:
        """
        Create binary label from loan_status

        Good (0):
            - "Current"
            - "Fully Paid"
            - "Issued"
            - "In Grace Period"

        Bad (1):
            - "Charged Off"
            - "Default"
            - "Late (31-120 days)"
            - "Late (16-30 days)"
            - "Does not meet the credit policy. Status:Charged Off"
        """
        loan_status = df['loan_status'].fillna('Unknown').str.lower()

        # Good statuses
        good_statuses = [
            'current',
            'fully paid',
            'issued',
            'in grace period'
        ]

        # Bad statuses
        bad_statuses = [
            'charged off',
            'default',
            'late',  # Catches all late variants
        ]

        # Create label
        label = pd.Series(0, index=df.index)  # Default to good

        for status in bad_statuses:
            label[loan_status.str.contains(status, na=False)] = 1

        return label

    # =====================================================================
    # VALIDATION
    # =====================================================================

    def _clean_and_validate(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Clean and validate transformed data
        """
        # Fill NaN values with sensible defaults
        numeric_columns = df.select_dtypes(include=[np.number]).columns

        for col in numeric_columns:
            if df[col].isna().any():
                if col in ['label']:
                    df[col] = df[col].fillna(0)
                else:
                    df[col] = df[col].fillna(df[col].median())

        # Ensure non-negative values for certain columns
        non_negative_cols = [
            'age', 'income_monthly', 'payroll_streak', 'current_debt',
            'spending_monthly', 'score_buro'
        ]

        for col in non_negative_cols:
            if col in df.columns:
                df[col] = df[col].clip(lower=0)

        # Ensure ratios are between 0 and 1
        ratio_cols = ['dti', 'utilization', 'on_time_rate', 'payroll_variance', 'spending_var_6m']

        for col in ratio_cols:
            if col in df.columns:
                df[col] = df[col].clip(0, 1)

        return df

    def _create_state_risk_mapping(self) -> Dict[str, float]:
        """
        Create state-level risk mapping (simplified)
        Can be enhanced with actual default rate data by state
        """
        # Placeholder - in production, use actual historical data
        return {}

    def get_feature_summary(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Get summary statistics of engineered features
        """
        feature_cols = [
            'zone', 'age', 'payroll_streak', 'employment_type',
            'income_monthly', 'payroll_variance', 'current_debt',
            'dti', 'utilization', 'spending_monthly', 'spending_var_6m',
            'score_buro', 'max_days_late', 'on_time_rate', 'label'
        ]

        available_cols = [col for col in feature_cols if col in df.columns]

        summary = df[available_cols].describe()

        return summary


def test_feature_engineering():
    """
    Test feature engineering with sample data
    """
    print("Testing LoanFeatureEngineer...")

    # Create sample data
    sample_data = {
        'loan_amnt': [5000, 10000, 15000],
        'funded_amnt': [5000, 10000, 15000],
        'int_rate': [10.5, 15.0, 20.0],
        'installment': [162.0, 324.0, 486.0],
        'emp_title': ['Engineer', 'Teacher', 'Manager'],
        'emp_length': ['10+ years', '3 years', '< 1 year'],
        'annual_inc': [60000.0, 45000.0, 80000.0],
        'loan_status': ['Fully Paid', 'Current', 'Charged Off'],
        'zip_code': ['94xxx', '10xxx', '60xxx'],
        'addr_state': ['CA', 'NY', 'IL'],
        'dti': [15.0, 25.0, 35.0],
        'delinq_2yrs': [0.0, 1.0, 2.0],
        'pub_rec': [0.0, 0.0, 1.0],
        'revol_util': [30.0, 50.0, 80.0],
        'out_prncp': [0.0, 5000.0, 12000.0],
        'total_pymnt': [5500.0, 3000.0, 1500.0],
        'recoveries': [0.0, 0.0, 100.0],
        'collections_12_mths_ex_med': [0.0, 0.0, 1.0],
        'income_monthly': [5000.0, 3750.0, 6666.67]
    }

    df = pd.DataFrame(sample_data)

    # Transform
    engineer = LoanFeatureEngineer()
    transformed = engineer.transform_dataset(df)

    # Display results
    print("\nTransformed Features:")
    print(transformed[['age', 'payroll_streak', 'income_monthly', 'current_debt', 'label']])

    print("\nFeature Summary:")
    print(engineer.get_feature_summary(transformed))

    print("\n✓ Test complete!")


if __name__ == "__main__":
    test_feature_engineering()
