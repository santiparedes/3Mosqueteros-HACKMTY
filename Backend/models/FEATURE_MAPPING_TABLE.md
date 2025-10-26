# Complete Feature Mapping Reference

## Dataset → Model Feature Mapping

### 📊 Direct Mappings (1:1)

| **Dataset Column** | **Model Feature** | **Transformation** | **Example** |
|-------------------|-------------------|-------------------|-------------|
| `annual_inc` | `income_monthly` | `annual_inc / 12` | 60,000 → 5,000 |
| `dti` | `dti` | `dti / 100` | 25.0 → 0.25 |
| `revol_util` | `utilization` | `revol_util / 100` | 50.0 → 0.50 |
| `addr_state` | `zone` | Direct copy | "CA" → "CA" |
| `out_prncp` | `current_debt` | Use if available | 5,000 → 5,000 |
| `loan_amnt` | `current_debt` | Fallback if out_prncp missing | 10,000 → 10,000 |

---

### 🔧 Derived Features (Calculated)

| **Model Feature** | **Source Columns** | **Calculation Logic** | **Range** |
|------------------|-------------------|----------------------|-----------|
| `age` | `emp_length` | `25 + parse_emp_years(emp_length) + random(5,15)` | 18-75 |
| `payroll_streak` | `emp_length` | Parse to months ("10+ years" → 120) | 0-360 months |
| `employment_type` | `emp_title`, `emp_length` | `1 if (has_title AND length>12m) else 0` | 0 or 1 |
| `payroll_variance` | `emp_length` | `0.5 / (1 + emp_months/12) * random(0.8,1.2)` | 0.01-0.8 |
| `spending_monthly` | `installment`, `income_monthly` | `installment + (income * 0.3) * random(0.85,1.15)` | 0 - 95% income |
| `spending_var_6m` | `delinq_2yrs` | `0.15 * (1 + delinq*0.1) * random(0.7,1.3)` | 0.05-0.8 |
| `score_buro` | `int_rate`, `delinq_2yrs`, `pub_rec` | `850 - ((int_rate-5)/25)*550 - delinq*50 - pub_rec*30` | 300-850 |
| `max_days_late` | `delinq_2yrs` | `delinq_count * random(30, 90)` | 0-180 |
| `on_time_rate` | `delinq_2yrs`, `collections_12_mths_ex_med` | `1.0 - (delinq*0.05) - (collections*0.1)` | 0.0-1.0 |

---

### 🎯 Target Label

| **loan_status Value** | **Label** | **Meaning** |
|----------------------|-----------|-------------|
| "Current" | 0 | Good |
| "Fully Paid" | 0 | Good |
| "Issued" | 0 | Good |
| "In Grace Period" | 0 | Good |
| "Charged Off" | 1 | Bad (Default) |
| "Default" | 1 | Bad (Default) |
| "Late (31-120 days)" | 1 | Bad (Default) |
| "Late (16-30 days)" | 1 | Bad (Default) |

---

### 🚀 Advanced Banking Features (Auto-Created)

After base features are created, the model automatically generates 19 additional features:

#### 1️⃣ Income Stability (3 features)

| Feature | Formula | Purpose |
|---------|---------|---------|
| `income_stability_score` | `1 / (1 + payroll_variance)` | Measure income predictability |
| `income_trend_6m` | `(age - 25) / 40 * payroll_streak / 12` | Detect income growth |
| `income_volatility` | `payroll_variance` | Risk from income fluctuation |

#### 2️⃣ Spending Behavior (3 features)

| Feature | Formula | Purpose |
|---------|---------|---------|
| `spending_stability` | `1 / (1 + spending_var_6m)` | Predictable spending = lower risk |
| `spending_to_income_ratio` | `spending_monthly / income_monthly` | Burn rate analysis |
| `savings_rate` | `(income - spending) / income` | Cushion for payments |

#### 3️⃣ Debt Management (3 features)

| Feature | Formula | Purpose |
|---------|---------|---------|
| `debt_service_ratio` | `current_debt / income_monthly` | Monthly payment burden |
| `credit_utilization_health` | `1 - utilization` | Inverse of credit usage |
| `dti_health_score` | `1 - dti` | Inverse of debt ratio |

#### 4️⃣ Payment Behavior (2 features)

| Feature | Formula | Purpose |
|---------|---------|---------|
| `payment_consistency` | `payroll_streak / 12` | Years of consistent employment |
| `late_payment_risk` | `1 / (1 + payroll_streak/12)` | Inverse of consistency |

#### 5️⃣ Demographic Risk (2 features)

| Feature | Formula | Purpose |
|---------|---------|---------|
| `age_risk_factor` | `abs(age - 35) / 35` | U-curve: young & old = risky |
| `income_adequacy` | `income_monthly / 3000` | Above/below living wage |

#### 6️⃣ Composite Scores (2 features)

| Feature | Formula | Purpose |
|---------|---------|---------|
| `financial_health_score` | Weighted avg of 6 metrics | **Most important feature** |
| `creditworthiness_score` | Weighted avg of 4 credit metrics | Overall credit quality |

**financial_health_score breakdown:**
```python
0.25 * income_stability_score +
0.20 * spending_stability +
0.20 * savings_rate +
0.15 * credit_utilization_health +
0.10 * payment_consistency +
0.10 * (1 - age_risk_factor)
```

#### 7️⃣ Interaction Features (3 features)

| Feature | Formula | Purpose |
|---------|---------|---------|
| `income_debt_interaction` | `income_monthly * dti` | Capture non-linear effects |
| `age_income_interaction` | `age * income_monthly` | Life stage + earning power |
| `stability_utilization_interaction` | `spending_stability * utilization` | Spending vs credit usage |

---

## Complete Feature List (28 Total)

### Base Features (9)
1. `age`
2. `income_monthly`
3. `payroll_streak`
4. `payroll_variance`
5. `spending_monthly`
6. `spending_var_6m`
7. `current_debt`
8. `dti`
9. `utilization`

### Advanced Features (19)
10. `income_stability_score`
11. `income_trend_6m`
12. `income_volatility`
13. `spending_stability`
14. `spending_to_income_ratio`
15. `savings_rate`
16. `debt_service_ratio`
17. `credit_utilization_health`
18. `dti_health_score`
19. `payment_consistency`
20. `late_payment_risk`
21. `age_risk_factor`
22. `income_adequacy`
23. `financial_health_score` ⭐ **Most Important**
24. `creditworthiness_score`
25. `income_debt_interaction`
26. `age_income_interaction`
27. `stability_utilization_interaction`
28. `zone_encoded` (if zone data available)

---

## Feature Importance (Expected)

Based on SHAP analysis from the advanced model:

| Rank | Feature | Importance | Impact |
|------|---------|------------|--------|
| 🥇 1 | `financial_health_score` | 0.433 | **Highest** |
| 🥈 2 | `income_monthly` | 0.229 | High |
| 🥉 3 | `current_debt` | 0.157 | High |
| 4 | `income_trend_6m` | 0.133 | Medium |
| 5 | `spending_var_6m` | 0.120 | Medium |
| 6 | `dti` | 0.098 | Medium |
| 7 | `utilization` | 0.087 | Medium |
| 8 | `age` | 0.065 | Low-Medium |
| 9-28 | Others | 0.001-0.050 | Low |

---

## Data Quality Checks

The feature engineering pipeline handles:

✅ **Missing Values**
- Median imputation for numeric features
- "Unknown" for categorical features

✅ **Invalid Ranges**
- Age: Clipped to [18, 75]
- Ratios: Clipped to [0, 1]
- Non-negative: All monetary values ≥ 0

✅ **Outliers**
- Spending capped at 95% of income
- Credit score bounded [300, 850]
- Days late capped at 180

✅ **Data Types**
- All numeric features converted to float
- Categorical encoded to int
- Labels as binary int (0/1)

---

## Example Transformation

### Input Row (from loan_reduced.csv)
```python
{
    'loan_amnt': 10000,
    'annual_inc': 60000,
    'emp_length': '5 years',
    'int_rate': 15.0,
    'dti': 25.0,
    'revol_util': 50.0,
    'delinq_2yrs': 0,
    'loan_status': 'Fully Paid'
}
```

### Output Features (after transformation)
```python
{
    # Base features
    'age': 37,  # 25 + 5 + random(7)
    'income_monthly': 5000,  # 60000 / 12
    'payroll_streak': 60,  # 5 years * 12
    'payroll_variance': 0.15,  # Low variance (stable job)
    'current_debt': 10000,
    'dti': 0.25,  # 25 / 100
    'utilization': 0.50,  # 50 / 100
    'spending_monthly': 1800,  # Estimated

    # Advanced features
    'financial_health_score': 0.72,  # Good health
    'creditworthiness_score': 0.68,
    'savings_rate': 0.25,

    # Target
    'label': 0  # Good (Fully Paid)
}
```

---

## Validation After Feature Engineering

After running feature engineering, verify:

```python
# Load transformed data
df = pd.read_csv('dataset_train_improved.csv')

# 1. Check feature count
assert len(df.columns) >= 28, "Missing features"

# 2. Check label distribution
print(df['label'].value_counts())
# Should see both 0s and 1s

# 3. Check feature ranges
print(df[['age', 'dti', 'utilization', 'savings_rate']].describe())
# age: [18, 75]
# ratios: [0, 1]

# 4. Check no missing values
print(df.isnull().sum())
# Should all be 0

# 5. Check financial_health_score
print(df['financial_health_score'].describe())
# Should be mostly [0.3, 0.9]
```

---

**This mapping ensures compatibility between your LendingClub dataset and the advanced banking model!**
