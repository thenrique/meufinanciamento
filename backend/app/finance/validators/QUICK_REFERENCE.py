#!/usr/bin/env python3
"""
Quick Reference Guide for Payment Validators

Copy this into your IDE or print for reference while integrating validators.
"""

# ════════════════════════════════════════════════════════════════════════════
# QUICK START: Import Validators
# ════════════════════════════════════════════════════════════════════════════

from app.finance.validators import (
    validate_payment_date,
    validate_payment_amount,
    validate_unique_payment_date,
    validate_payment_type,
    validate_user_loan_ownership,
    PaymentValidationError,
)


# ════════════════════════════════════════════════════════════════════════════
# BASIC USAGE PATTERNS
# ════════════════════════════════════════════════════════════════════════════

# 1. Validate payment type
validate_payment_type("normal")  # or: extra_monthly, extra_one_time, amortization
# Raises: PaymentValidationError (400) if invalid

# 2. Validate payment date
from datetime import date
validate_payment_date(
    payment_date=date(2024, 1, 15),
    loan_start_date=date(2020, 1, 1)
)
# Raises: PaymentValidationError (400) if future or before loan start

# 3. Validate payment amount
validate_payment_amount(
    amount=1500.00,
    outstanding_balance=50000.00
)
# Raises: PaymentValidationError (400) if invalid or overpayment

# 4. Check for duplicate dates
from app.finance.models.payment import PaymentRecord
existing_payments = [...]  # List[PaymentRecord]
validate_unique_payment_date(
    loan_id="loan_123",
    payment_date=date(2024, 1, 15),
    existing_payments=existing_payments
)
# Raises: PaymentValidationError (409) if duplicate

# 5. Verify user owns loan (async - must await)
from app.database import get_supabase
supabase = get_supabase()
loan = await validate_user_loan_ownership(
    user_id="user_123",
    loan_id="loan_456",
    supabase=supabase
)
# Returns: loan dict if valid
# Raises: PaymentValidationError (403) if unauthorized or loan inactive


# ════════════════════════════════════════════════════════════════════════════
# ENDPOINT PATTERN: Full Payment Creation
# ════════════════════════════════════════════════════════════════════════════

# @router.post("/loans/{loan_id}/payments", status_code=201)
# async def create_payment(
#     loan_id: str,
#     payment: PaymentCreate,
#     current_user: str = Depends(get_current_user),
# ):
#     supabase = get_supabase()
#
#     try:
#         # 1. Ownership check
#         loan = await validate_user_loan_ownership(current_user, loan_id, supabase)
#
#         # 2. Type validation
#         validate_payment_type(payment.payment_type)
#
#         # 3. Date validation
#         loan_start = date.fromisoformat(loan["start_date"])
#         validate_payment_date(payment.payment_date, loan_start)
#
#         # 4. Amount validation
#         balance = float(loan["outstanding_balance"])
#         validate_payment_amount(payment.amount_paid, balance)
#
#         # 5. Uniqueness check
#         payments_resp = supabase.table("payment_records").select("*").eq("loan_id", loan_id).execute()
#         existing = [PaymentRecord(**p) for p in (payments_resp.data or [])]
#         validate_unique_payment_date(loan_id, payment.payment_date, existing)
#
#         # 6. Create payment
#         data = payment.model_dump()
#         data["user_id"] = current_user
#         data["loan_id"] = loan_id
#         resp = supabase.table("payment_records").insert(data).execute()
#
#         return resp.data[0]
#
#     except PaymentValidationError:
#         raise  # Re-raise with proper HTTP status code


# ════════════════════════════════════════════════════════════════════════════
# HTTP STATUS CODES AND ERROR SCENARIOS
# ════════════════════════════════════════════════════════════════════════════

"""
400 Bad Request:
  - Future payment date
  - Date before loan start
  - Invalid amount (zero, negative, overpayment)
  - Invalid payment type

409 Conflict:
  - Duplicate payment date for same loan

403 Forbidden:
  - Loan not found
  - User doesn't own loan
  - Loan is inactive/cancelled

500 Internal Server Error:
  - Database errors during ownership check
"""


# ════════════════════════════════════════════════════════════════════════════
# ERROR MESSAGE EXAMPLES (PT-BR)
# ════════════════════════════════════════════════════════════════════════════

"""
Payment date errors:
  "Data do pagamento não pode ser no futuro"
  "Data do pagamento não pode ser anterior à data de início do financiamento (01/01/2020)"

Payment amount errors:
  "Valor do pagamento deve ser maior que zero"
  "Valor do pagamento (R$ 60000.00) não pode ser maior que o saldo devedor (R$ 50000.00)"

Payment type errors:
  "Tipo de pagamento inválido. Valores aceitos: normal, extra_monthly, extra_one_time, amortization"

Unique date errors:
  "Já existe um pagamento registrado em 15/01/2024"

Ownership errors:
  "Financiamento não encontrado ou você não tem permissão para acessá-lo"
  "Este financiamento foi cancelado e não aceita novos pagamentos"
  "Erro ao validar acesso ao financiamento"
"""


# ════════════════════════════════════════════════════════════════════════════
# VALID PAYMENT TYPES
# ════════════════════════════════════════════════════════════════════════════

"""
"normal"           - Regular monthly payment
"extra_monthly"    - Recurring extra monthly amount
"extra_one_time"   - One-time extra payment
"amortization"     - Extra amortization (principal reduction)
"""


# ════════════════════════════════════════════════════════════════════════════
# TESTING VALIDATORS
# ════════════════════════════════════════════════════════════════════════════

"""
Run tests:
  cd backend
  pytest app/finance/validators/test_payment_validator.py -v

Test coverage:
  - TestPaymentDate (5 tests)
  - TestPaymentAmount (5 tests)
  - TestPaymentType (6 tests)
  - TestUniquePaymentDate (5 tests)
  - TestPaymentValidationIntegration (2 tests)

Total: 30+ test cases with edge cases
"""


# ════════════════════════════════════════════════════════════════════════════
# DOCUMENTATION
# ════════════════════════════════════════════════════════════════════════════

"""
Files to reference:
  1. backend/app/finance/validators/README.md
     - Complete function reference
     - Error codes and messages
     - Integration patterns
     - Database constraints

  2. backend/app/finance/validators/example_integration.py
     - Ready-to-use endpoint examples
     - Full validation patterns
     - Error handling

  3. VALIDATION_IMPLEMENTATION.md
     - Project overview
     - Edge cases handled
     - Usage examples
"""


# ════════════════════════════════════════════════════════════════════════════
# KEY POINTS
# ════════════════════════════════════════════════════════════════════════════

"""
1. Validation order matters:
   - Always check ownership first (returns loan)
   - Then validate business rules
   - Then check uniqueness

2. validate_user_loan_ownership is async:
   - Must use await
   - Must be in async function
   - Returns loan dict on success

3. All error messages are in Portuguese:
   - PT-BR locale (DD/MM/YYYY format)
   - Helpful context in messages
   - HTTP-appropriate status codes

4. PaymentValidationError extends HTTPException:
   - Automatically serialized by FastAPI
   - Proper status codes (400, 403, 409, 500)
   - Logged automatically

5. Type hints throughout:
   - Compatible with mypy/pyright
   - Proper IDE autocomplete
   - Self-documenting code

6. Database constraints provide secondary validation:
   - UNIQUE (loan_id, payment_date)
   - CHECK (amount_paid > 0)
   - RLS policies for user isolation
"""


# ════════════════════════════════════════════════════════════════════════════
# COMMON PATTERNS
# ════════════════════════════════════════════════════════════════════════════

# Pattern 1: Just check ownership
# loan = await validate_user_loan_ownership(user_id, loan_id, supabase)

# Pattern 2: Validate type and amount quickly
# validate_payment_type(payment_type)
# validate_payment_amount(amount, balance)

# Pattern 3: Check all before creating
# All validators before supabase.insert()

# Pattern 4: Get existing for uniqueness check
# payments_resp = supabase.table("payment_records").select("*").eq("loan_id", loan_id).execute()
# existing = [PaymentRecord(**p) for p in (payments_resp.data or [])]
# validate_unique_payment_date(loan_id, payment_date, existing)
