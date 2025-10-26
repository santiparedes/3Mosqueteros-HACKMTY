# Credit Scoring Analysis - Realistic Data

## Overview
This document explains the realistic banking data created to test the credit scoring model. Two customers with contrasting credit behaviors were created to demonstrate how different financial patterns affect credit scores.

## Customer Profiles

### 👩‍💼 Sofia Rodriguez - "Good Credit" Customer
**Profile:** 35-year-old tech professional in Mexico City

#### Financial Characteristics:
- **Monthly Income:** $50,000 MXN (consistent, stable)
- **Debt-to-Income Ratio:** 5% (excellent)
- **Credit Utilization:** 5% ($2,500 used of $50,000 limit)
- **Savings Rate:** 20% of income
- **Payment History:** Perfect (always on time, full payments)

#### Credit Score Factors (Why She's "Prime"):
1. **High Income Stability:** Consistent $50k monthly salary
2. **Low DTI:** Only 5% of income goes to debt payments
3. **Low Utilization:** Uses only 5% of available credit
4. **Perfect Payments:** Never late, always pays full balance
5. **Savings Behavior:** Saves 20% of income regularly
6. **Credit Mix:** Has both checking, savings, and credit accounts

#### Expected Credit Score: **Prime (750-850)**
- **PD90 Score:** 0.05 (5% probability of default)
- **APR:** 12% (excellent rate)
- **MSI Eligible:** Yes, 12 months
- **Credit Limit:** $50,000

---

### 👨‍💼 Carlos Mendez - "Bad Credit" Customer
**Profile:** 31-year-old retail worker in Guadalajara

#### Financial Characteristics:
- **Monthly Income:** $7,500 MXN (irregular, unstable)
- **Debt-to-Income Ratio:** 85% (dangerous)
- **Credit Utilization:** 85% ($8,500 used of $10,000 limit)
- **Savings Rate:** 0% (no savings)
- **Payment History:** Poor (late payments, minimum only)

#### Credit Score Factors (Why He's "Subprime"):
1. **Low Income Instability:** Irregular income, reduced hours
2. **High DTI:** 85% of income goes to debt payments
3. **High Utilization:** Uses 85% of available credit
4. **Poor Payments:** Late payments, only minimum payments
5. **No Savings:** Lives paycheck to paycheck
6. **Credit Abuse:** Maxed out credit card

#### Expected Credit Score: **Subprime (300-600)**
- **PD90 Score:** 0.35 (35% probability of default)
- **APR:** 28% (high rate)
- **MSI Eligible:** No
- **Credit Limit:** $10,000

---

## Credit Scoring Model Analysis

### Key Factors in Credit Scoring:

#### 1. **Debt-to-Income Ratio (DTI)**
- **Sofia:** 5% (excellent) - Low risk
- **Carlos:** 85% (dangerous) - High risk
- **Impact:** DTI > 40% significantly increases default risk

#### 2. **Credit Utilization**
- **Sofia:** 5% (excellent) - Shows discipline
- **Carlos:** 85% (dangerous) - Shows financial stress
- **Impact:** Utilization > 30% starts hurting credit score

#### 3. **Payment History**
- **Sofia:** Perfect - Always on time, full payments
- **Carlos:** Poor - Late payments, minimum only
- **Impact:** Payment history is 35% of credit score

#### 4. **Income Stability**
- **Sofia:** Consistent $50k monthly
- **Carlos:** Irregular $6-8k monthly
- **Impact:** Stable income reduces risk

#### 5. **Savings Behavior**
- **Sofia:** 20% savings rate
- **Carlos:** 0% savings rate
- **Impact:** Savings indicate financial responsibility

### Machine Learning Model Features:

The credit scoring model likely uses these features:

```python
# Key features for credit scoring
features = {
    'monthly_income': 50000,  # Sofia vs 7500 Carlos
    'dti_ratio': 0.05,        # Sofia vs 0.85 Carlos
    'credit_utilization': 0.05, # Sofia vs 0.85 Carlos
    'payment_consistency': 1.0,  # Sofia vs 0.3 Carlos
    'savings_rate': 0.20,     # Sofia vs 0.0 Carlos
    'income_stability': 1.0,   # Sofia vs 0.4 Carlos
    'credit_age': 5.0,        # Sofia vs 2.0 Carlos
    'late_payments': 0,       # Sofia vs 3 Carlos
    'credit_mix': 3,          # Sofia vs 2 Carlos
    'new_credit': 0           # Sofia vs 2 Carlos
}
```

## Data Structure

### Tables Populated:
1. **customers** - 2 customers (Sofia + Carlos)
2. **accounts** - 5 accounts total
3. **cards** - 4 cards (2 debit + 2 credit)
4. **transactions** - 28 realistic transactions
5. **credit_risk_profiles** - 2 credit profiles
6. **merchants** - 10 realistic merchants

### Transaction Patterns:

#### Sofia's Transactions (Good Behavior):
- Regular salary deposits
- Responsible spending
- Full credit card payments
- Regular savings transfers
- On-time payments

#### Carlos's Transactions (Bad Behavior):
- Irregular income
- High expenses relative to income
- Credit card abuse
- Late payments
- Minimum payments only

## Testing the Credit Model

This data allows testing:

1. **Credit Score Accuracy:** Model should score Sofia high, Carlos low
2. **Risk Assessment:** PD90 scores should reflect actual risk
3. **Feature Importance:** Which factors most influence scoring
4. **Edge Cases:** How model handles extreme scenarios
5. **Real-world Scenarios:** Realistic financial behaviors

## Next Steps

1. **Run the SQL script** to populate the database
2. **Test the app** to see both customers' data
3. **Verify credit scoring** works with real data
4. **Analyze model predictions** against expected outcomes
5. **Fine-tune model** based on results

This realistic data will provide a solid foundation for testing and improving the credit scoring system.
