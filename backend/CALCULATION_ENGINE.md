# Loan Calculation Engine - Implementation Guide

## Overview

The `calculate_loan_with_history()` function reconciles estimated vs actual amortization for loans, generating detailed month-by-month schedules for both scenarios and a comprehensive comparison summary.

## Function Signature

```python
async def calculate_loan_with_history(
    loan: Dict,
    payment_records: List[PaymentRecord],
) -> LoanWithPaymentHistory:
```

## What It Does

The function performs three main calculations:

1. **Calculated History (Estimado)**: Original contract schedule with SAC amortization and TR
2. **Actual History (Realizado)**: Real payment history reconciled with actual interest and amortization
3. **Comparison Summary**: Detailed metrics comparing the two scenarios

## Input Parameters

### Loan Dictionary
```python
{
    'id': str,                          # Unique loan identifier
    'name': str,                        # Loan name/description
    'outstanding_balance': float,       # Current balance in R$
    'interest_rate_year': float,        # Annual interest rate (%)
    'term_months': int,                 # Total months (120, 240, 360, etc.)
    'insurance_monthly': float,         # Monthly insurance premium
    'start_date': date | str,           # Loan start date
}
```

### Payment Records
```python
[
    PaymentRecord(
        id='pay_xxx',
        loan_id='loan_xxx',
        payment_date=date(2024, 1, 15),
        amount_paid=1500.50,
        payment_type='normal',          # normal, extra_monthly, extra_one_time, amortization
        notes='Optional notes'
    ),
    ...
]
```

## Output Structure

### LoanWithPaymentHistory
```python
{
    'loan_id': str,
    'loan_name': str,
    'calculated_history': [CalculatedMonthEntry, ...],  # Planned schedule
    'actual_history': [ActualMonthEntry, ...],          # Real payments
    'summary': ComparisonSummary                        # Key metrics
}
```

### CalculatedMonthEntry (from contract)
```python
{
    'month': int,                       # Month number (1, 2, 3, ...)
    'date': date,                       # Month date (first day)
    'payment_planned': float,           # Expected payment
    'amortization': float,              # Debt reduction
    'interest': float,                  # Interest charged
    'insurance': float,                 # Insurance premium
    'outstanding_balance': float        # Remaining balance
}
```

### ActualMonthEntry (with real payments)
```python
{
    # All fields from CalculatedMonthEntry, plus:
    'payment_actual': float,            # Actual payment made
    'payments': [PaymentRecord, ...],   # Payment records for this month
    'deviation': float                  # Actual - planned (can be positive or negative)
}
```

### ComparisonSummary
```python
{
    'total_payment_planned': float,     # Sum of all planned payments
    'total_payment_actual': float,      # Sum of all actual payments
    'total_interest_planned': float,    # Total interest in contract
    'total_interest_actual': float,     # Real interest paid
    'total_interest_saved': float,      # Interest reduction (positive = saved)
    'total_insurance': float,           # Total insurance paid
    'months_planned': int,              # Contract months
    'months_actual': int,               # Months with activity
    'months_ahead': int,                # Early payoff (negative = delayed)
    'payoff_date_planned': date,        # Contract payoff date
    'payoff_date_actual': date,         # Actual/projected payoff
    'days_ahead': int,                  # Days ahead of schedule
    'total_deviation': float            # Total overpayment/underpayment
}
```

## Algorithm Details

### Step 1: Calculate Scheduled Payments (Estimado)

Uses SAC (Sistema de Amortização Constante) amortization:

```
For each month:
  effective_rate = (1 + annual_rate/100)^(1/12) * (1 + TR/100) - 1
  amortization = remaining_balance / remaining_months
  interest = remaining_balance * effective_rate
  payment = amortization + interest + insurance
  balance = balance - amortization
```

**Key Features:**
- TR (Taxa Referencial) integrated for each month
- Constant amortization reduces interest over time
- Insurance premium included
- Handles date boundaries correctly

### Step 2: Reconcile Actual Payments (Realizado)

```
For each month from start_date to today:
  Get actual payments for that month
  Calculate interest based on current balance
  Amortization = payment - interest - insurance
  Update balance accordingly
  Track deviation from planned payment
```

**Key Features:**
- Only processes payments up to today
- Groups payments by month
- Calculates real interest accrual
- Tracks payment deviations

### Step 3: Generate Comparison

Calculates:
- Total interest saved/lost
- Days/months ahead of schedule
- Percentage of payment on time
- Deviation patterns

## Example Walkthrough

### Scenario: R$ 50,000 Loan at 6.5% for 10 years

**Loan Setup:**
```python
loan = {
    'id': 'CASA-001',
    'name': 'Casa - Financiamento Caixa',
    'outstanding_balance': 50000.0,
    'interest_rate_year': 6.5,
    'term_months': 120,
    'insurance_monthly': 50.0,
    'start_date': date(2024, 1, 1),
}
```

**Month 1 Calculation (Estimado):**
```
effective_rate = (1 + 0.065/100)^(1/12) * (1 + 0.04/100) - 1
              = 0.005348% (approx)
amortization = 50000 / 120 = 416.67
interest = 50000 * 0.005348 = 267.40
insurance = 50.00
payment = 416.67 + 267.40 + 50.00 = 734.07
balance = 50000 - 416.67 = 49583.33
```

**With Payment (Realizado):**
```
If payment received: 750.00
Amortization = 750.00 - 267.40 - 50.00 = 432.60
Deviation = 750.00 - 734.07 = +15.93 (early)
balance = 50000 - 432.60 = 49567.40
```

## Edge Cases Handled

### 1. Loan Already Paid Off
If `outstanding_balance <= 0`:
- Returns empty histories
- Summary shows zero differences

### 2. No Payment Records
If `payment_records` is empty:
- Actual history matches calculated
- Deviation is zero for all months

### 3. Future Payments
If payment_date > today:
- Payment is excluded
- Only historical data is processed

### 4. Missing TR Data
If TR value not available for a date:
- Uses last known TR value
- Falls back to 0.0 if none available
- Logged as warning

### 5. Very Old Loans (>10 years)
- Full calculation still performed
- No artificial truncation
- May affect calculation time

### 6. String Dates
- Accepts ISO format strings: '2024-01-01'
- Converts automatically to date objects

## Integration with API

### Expected Endpoint
```
GET /loans/{loan_id}/history
```

### Response Example
```json
{
  "loan_id": "CASA-001",
  "loan_name": "Casa - Financiamento Caixa",
  "calculated_history": [
    {
      "month": 1,
      "date": "2024-01-01",
      "payment_planned": 734.07,
      "amortization": 416.67,
      "interest": 267.40,
      "insurance": 50.00,
      "outstanding_balance": 49583.33
    },
    ...
  ],
  "actual_history": [
    {
      "month": 1,
      "date": "2024-01-01",
      "payment_planned": 734.07,
      "payment_actual": 750.00,
      "amortization": 432.60,
      "interest": 267.40,
      "insurance": 50.00,
      "outstanding_balance": 49567.40,
      "payments": [...],
      "deviation": 15.93
    },
    ...
  ],
  "summary": {
    "total_payment_planned": 88088.40,
    "total_payment_actual": 89200.00,
    "total_interest_planned": 38088.40,
    "total_interest_actual": 37500.00,
    "total_interest_saved": 588.40,
    "months_planned": 120,
    "months_actual": 12,
    "months_ahead": 1,
    "payoff_date_planned": "2034-01-01",
    "payoff_date_actual": "2034-12-01",
    "days_ahead": 30,
    "total_deviation": 1111.60
  }
}
```

## Performance Considerations

### Time Complexity
- **Calculated History**: O(months)
- **Actual History**: O(months + payments)
- **Summary**: O(months)
- **Overall**: O(months + payments)

### Space Complexity
- O(months) for storing results

### Caching Strategy
- TR data cached for 24 hours
- Results cached per loan per day
- Consider Redis cache for API responses

## Testing

### Test Cases Included
1. **No Payments**: Actual matches estimated
2. **On-Time**: Minimal deviation
3. **Early Payments**: Interest saved
4. **Late Payments**: Balance increases
5. **Mixed History**: Real-world scenario

### Running Tests
```bash
pytest backend/tests/test_calculation_engine.py -v
```

## Assumptions & Limitations

### Assumptions
1. Interest calculated monthly (not daily)
2. Payments credited on payment_date
3. TR from last day of month (standard practice)
4. No partial month calculations
5. Insurance premium constant throughout

### Limitations
1. SAC model only (not PRICE)
2. No balloon payments
3. No rate changes mid-loan
4. No payment plans for late payments
5. No early payoff prepayment penalties

## Future Enhancements

1. Support for PRICE amortization
2. Variable insurance premiums
3. Interest-only periods
4. Payment rescheduling scenarios
5. Refinancing calculations
6. Multi-currency support

## Debugging

Enable debug logging:
```python
from loguru import logger
logger.enable("app")
```

This will output:
- TR fetches and interpolation
- Month-by-month calculations
- Payment matching logic
- Summary generation
