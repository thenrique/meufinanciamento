# Payment Validators - Documentation

## Overview

The payment validators module provides business validation rules for payment record operations in the finance module. These validators ensure data integrity, prevent overpayments, and maintain business logic constraints.

## Module Structure

```
backend/app/finance/validators/
├── __init__.py                    # Package exports
├── payment_validator.py           # Validation functions
└── example_integration.py         # Example endpoint implementations
```

## Validation Functions

### 1. `validate_payment_date(payment_date: date, loan_start_date: date) -> None`

**Purpose**: Ensure payment date is valid relative to loan timeline.

**Rules**:
- Payment date must NOT be in the future
- Payment date must NOT be before loan start date

**Error Handling**:
- Returns 400 Bad Request if date is in future
- Returns 400 Bad Request if date is before loan start
- Uses Portuguese error messages

**Example**:
```python
from datetime import date
from app.finance.validators import validate_payment_date

try:
    validate_payment_date(
        payment_date=date(2024, 1, 15),
        loan_start_date=date(2020, 1, 1)
    )
except PaymentValidationError as e:
    print(f"Validation failed: {e.detail}")
```

**Raised Errors**:
- "Data do pagamento não pode ser no futuro"
- "Data do pagamento não pode ser anterior à data de início do financiamento (01/01/2020)"

---

### 2. `validate_payment_amount(amount: float, outstanding_balance: float) -> None`

**Purpose**: Ensure payment amount is valid and doesn't exceed the outstanding balance.

**Rules**:
- Amount must be greater than 0 (no zero or negative payments)
- Amount must NOT exceed outstanding balance (prevent overpayment)

**Error Handling**:
- Returns 400 Bad Request if amount is invalid
- Provides helpful message showing actual balance

**Example**:
```python
from app.finance.validators import validate_payment_amount

try:
    validate_payment_amount(
        amount=1500.00,
        outstanding_balance=50000.00
    )
except PaymentValidationError as e:
    print(f"Validation failed: {e.detail}")
```

**Raised Errors**:
- "Valor do pagamento deve ser maior que zero"
- "Valor do pagamento (R$ 60000.00) não pode ser maior que o saldo devedor (R$ 50000.00)"

---

### 3. `validate_unique_payment_date(loan_id: str, payment_date: date, existing_payments: List[PaymentRecord]) -> None`

**Purpose**: Prevent duplicate payment dates for the same loan.

**Rules**:
- No two payments can have the same date for a given loan
- Ensures payment date uniqueness at application level (supplementing DB constraint)

**Error Handling**:
- Returns 409 Conflict if duplicate date found
- Provides helpful message with the conflicting date in PT-BR format

**Example**:
```python
from app.finance.validators import validate_unique_payment_date
from app.finance.models.payment import PaymentRecord

existing_payments = [
    PaymentRecord(..., payment_date=date(2024, 1, 15)),
]

try:
    validate_unique_payment_date(
        loan_id="loan_123",
        payment_date=date(2024, 1, 15),
        existing_payments=existing_payments
    )
except PaymentValidationError as e:
    print(f"Validation failed: {e.detail}")
```

**Raised Errors**:
- "Já existe um pagamento registrado em 15/01/2024"

---

### 4. `validate_payment_type(payment_type: str) -> None`

**Purpose**: Ensure payment type is one of the valid enum values.

**Valid Types**:
- `"normal"` - Regular monthly payment
- `"extra_monthly"` - Recurring extra monthly amount
- `"extra_one_time"` - One-time extra payment
- `"amortization"` - Extra amortization (principal reduction)

**Error Handling**:
- Returns 400 Bad Request if type is invalid
- Lists all valid values in error message

**Example**:
```python
from app.finance.validators import validate_payment_type

try:
    validate_payment_type("normal")  # OK
    validate_payment_type("invalid_type")  # Raises error
except PaymentValidationError as e:
    print(f"Validation failed: {e.detail}")
```

**Raised Errors**:
- "Tipo de pagamento inválido. Valores aceitos: normal, extra_monthly, extra_one_time, amortization"

---

### 5. `async validate_user_loan_ownership(user_id: str, loan_id: str, supabase: Client) -> dict`

**Purpose**: Verify that a user owns a loan before allowing payment operations.

**Rules**:
- Loan must exist in database
- Loan must belong to the current user (user_id matches)
- Loan must be active (is_active = true)

**Returns**:
- Complete loan record dict if validation passes

**Error Handling**:
- Returns 403 Forbidden if loan doesn't exist or user doesn't own it
- Returns 403 Forbidden if loan is inactive/cancelled
- Returns 500 Internal Server Error for database errors
- Logs all errors for debugging

**Example**:
```python
from app.finance.validators import validate_user_loan_ownership
from app.database import get_supabase

supabase = get_supabase()

try:
    loan = await validate_user_loan_ownership(
        user_id="user_123",
        loan_id="loan_456",
        supabase=supabase
    )
    print(f"Loan found: {loan['id']}, Balance: R$ {loan['outstanding_balance']}")
except PaymentValidationError as e:
    print(f"Validation failed: {e.detail}")
```

**Raised Errors**:
- "Financiamento não encontrado ou você não tem permissão para acessá-lo" (403)
- "Este financiamento foi cancelado e não aceita novos pagamentos" (403)
- "Erro ao validar acesso ao financiamento" (500)

---

## Custom Exception: `PaymentValidationError`

Custom HTTPException subclass for validation errors.

**Properties**:
- Extends FastAPI's HTTPException
- Automatically logs validation failures with loguru
- Takes detail message and status code

**Example**:
```python
from app.finance.validators import PaymentValidationError
from fastapi import status

raise PaymentValidationError(
    detail="Custom error message in Portuguese",
    status_code=status.HTTP_400_BAD_REQUEST
)
```

---

## Integration with FastAPI Endpoints

### Pattern 1: Create Payment (Full Validation)

```python
from fastapi import APIRouter, Depends, status
from app.finance.validators import (
    validate_user_loan_ownership,
    validate_payment_date,
    validate_payment_amount,
    validate_unique_payment_date,
    validate_payment_type,
)
from app.auth.dependencies import get_current_user
from app.database import get_supabase
from app.finance.models.payment import PaymentCreate

@router.post("/loans/{loan_id}/payments", status_code=status.HTTP_201_CREATED)
async def create_payment(
    loan_id: str,
    payment: PaymentCreate,
    current_user: str = Depends(get_current_user),
):
    supabase = get_supabase()

    # 1. Verify ownership
    loan = await validate_user_loan_ownership(current_user, loan_id, supabase)

    # 2. Validate payment type
    validate_payment_type(payment.payment_type)

    # 3. Validate date
    loan_start_date = date.fromisoformat(loan["start_date"])
    validate_payment_date(payment.payment_date, loan_start_date)

    # 4. Validate amount
    outstanding_balance = float(loan["outstanding_balance"])
    validate_payment_amount(payment.amount_paid, outstanding_balance)

    # 5. Check for duplicates
    payments_resp = supabase.table("payment_records").select("*").eq("loan_id", loan_id).execute()
    existing = [PaymentRecord(**p) for p in (payments_resp.data or [])]
    validate_unique_payment_date(loan_id, payment.payment_date, existing)

    # 6. Create payment
    payment_data = payment.model_dump()
    payment_data["user_id"] = current_user
    payment_data["loan_id"] = loan_id
    
    resp = supabase.table("payment_records").insert(payment_data).execute()
    return resp.data[0]
```

### Pattern 2: Simple Ownership Check

```python
@router.get("/loans/{loan_id}/payments")
async def list_payments(
    loan_id: str,
    current_user: str = Depends(get_current_user),
):
    supabase = get_supabase()
    
    # Just verify ownership, no other validation needed
    await validate_user_loan_ownership(current_user, loan_id, supabase)
    
    resp = supabase.table("payment_records").select("*").eq("loan_id", loan_id).execute()
    return resp.data or []
```

---

## Error Responses

All validators return HTTP exceptions with appropriate status codes and Portuguese messages:

| Validator | Status Code | Error Case |
|-----------|-------------|-----------|
| validate_payment_date | 400 | Future date or before loan start |
| validate_payment_amount | 400 | Invalid amount (zero/negative or overpayment) |
| validate_unique_payment_date | 409 | Duplicate payment date |
| validate_payment_type | 400 | Invalid payment type |
| validate_user_loan_ownership | 403 | User doesn't own loan or loan inactive |
| validate_user_loan_ownership | 500 | Database error |

---

## Logging

All validation failures are logged with loguru:

```python
logger.warning(f"PaymentValidationError: {detail}")
logger.error(f"Error message: {exc}")
```

Check logs to monitor validation failures and debug issues.

---

## Database Constraints (Complementary)

These validators complement database-level constraints:

```sql
-- Unique payment per day per loan
UNIQUE INDEX idx_unique_payment_per_day (loan_id, payment_date)

-- Check constraints
CHECK (amount_paid > 0)
CHECK (loan_id IS NOT NULL)

-- RLS Policy (enforced by Supabase)
CREATE POLICY "Users manage their payments"
  ON payment_records FOR ALL USING (auth.uid() = user_id)
```

Application-level validators run first, providing better user experience with specific error messages.

---

## Testing

Example test cases:

```python
import pytest
from datetime import date
from app.finance.validators import (
    validate_payment_date,
    validate_payment_amount,
    validate_payment_type,
    PaymentValidationError,
)

def test_payment_date_future_raises_error():
    future_date = date(2099, 1, 1)
    with pytest.raises(PaymentValidationError) as exc_info:
        validate_payment_date(future_date, date(2020, 1, 1))
    assert "futuro" in exc_info.value.detail

def test_payment_amount_zero_raises_error():
    with pytest.raises(PaymentValidationError) as exc_info:
        validate_payment_amount(0, 1000)
    assert "maior que zero" in exc_info.value.detail

def test_payment_amount_overpay_raises_error():
    with pytest.raises(PaymentValidationError) as exc_info:
        validate_payment_amount(2000, 1000)
    assert "saldo devedor" in exc_info.value.detail

def test_valid_payment_type():
    # Should not raise
    validate_payment_type("normal")
    validate_payment_type("extra_monthly")
    validate_payment_type("amortization")

def test_invalid_payment_type():
    with pytest.raises(PaymentValidationError) as exc_info:
        validate_payment_type("invalid")
    assert "inválido" in exc_info.value.detail
```

---

## Notes

- All validators use Portuguese messages for user-facing errors
- Async function `validate_user_loan_ownership` must be awaited when called
- PaymentValidationError inherits from FastAPI's HTTPException for automatic FastAPI handling
- Validation order matters: check ownership first, then business rules
- Database-level constraints provide secondary validation layer
- RLS policies at Supabase level provide tertiary security layer
