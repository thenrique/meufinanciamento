"""
Example integration of payment validators with FastAPI endpoints.

This module demonstrates how to use the payment validators in your endpoints.
This is a reference implementation - integrate with your actual router.py as needed.
"""

from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from loguru import logger

from app.auth.dependencies import get_current_user
from app.database import get_supabase
from app.finance.models.payment import PaymentCreate, PaymentRecord, PaymentType
from app.finance.validators import (
    PaymentValidationError,
    validate_payment_amount,
    validate_payment_date,
    validate_payment_type,
    validate_unique_payment_date,
    validate_user_loan_ownership,
)

# This router is for demonstration purposes
# Integrate these patterns into your existing finance/router.py

router = APIRouter(tags=["payments"], prefix="/finance")


@router.post("/loans/{loan_id}/payments", status_code=status.HTTP_201_CREATED)
async def create_payment(
    loan_id: str,
    payment: PaymentCreate,
    current_user: str = Depends(get_current_user),
) -> dict:
    """
    Create a new payment record for a loan.

    Validates:
    - User owns the loan (403 Forbidden if not)
    - Payment date is not in future and after loan start date
    - Payment amount is valid and doesn't exceed outstanding balance
    - No duplicate payment dates for the same loan
    - Payment type is valid

    Args:
        loan_id: The loan ID
        payment: Payment record data
        current_user: Current authenticated user ID (via dependency injection)

    Returns:
        Created payment record

    Raises:
        HTTPException: 400, 403, 409, or 500 status codes with Portuguese messages
    """
    supabase = get_supabase()

    try:
        # 1. Validate user owns the loan (returns loan record if valid)
        loan = await validate_user_loan_ownership(current_user, loan_id, supabase)

        # 2. Validate payment type is valid
        validate_payment_type(payment.payment_type)

        # 3. Validate payment date (not future, after loan start)
        loan_start_date = date.fromisoformat(loan["start_date"])
        validate_payment_date(payment.payment_date, loan_start_date)

        # 4. Validate payment amount
        outstanding_balance = float(loan["outstanding_balance"])
        validate_payment_amount(payment.amount_paid, outstanding_balance)

        # 5. Get existing payments to check for duplicates
        payments_resp = supabase.table("payment_records").select("*").eq("loan_id", loan_id).execute()
        existing_payments = [PaymentRecord(**p) for p in (payments_resp.data or [])]

        # 6. Validate unique payment date
        validate_unique_payment_date(loan_id, payment.payment_date, existing_payments)

        # 7. All validations passed - create the payment record
        payment_data = payment.model_dump()
        payment_data["user_id"] = current_user  # Track which user created this
        payment_data["loan_id"] = loan_id

        resp = supabase.table("payment_records").insert(payment_data).execute()
        created_payment = resp.data[0]

        logger.info(
            f"Payment created: user_id={current_user}, loan_id={loan_id}, "
            f"amount={payment.amount_paid}, date={payment.payment_date}"
        )

        return created_payment

    except PaymentValidationError:
        # Re-raise validation errors (already have correct status codes and messages)
        raise
    except Exception as exc:
        logger.error(f"Error creating payment: {exc}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao registrar pagamento",
        )


@router.get("/loans/{loan_id}/payments")
async def list_payments(
    loan_id: str,
    current_user: str = Depends(get_current_user),
) -> list:
    """
    List all payments for a loan.

    Validates:
    - User owns the loan

    Args:
        loan_id: The loan ID
        current_user: Current authenticated user ID

    Returns:
        List of payment records for the loan
    """
    supabase = get_supabase()

    try:
        # Verify user owns the loan
        await validate_user_loan_ownership(current_user, loan_id, supabase)

        # Get all payments for this loan
        resp = supabase.table("payment_records").select("*").eq("loan_id", loan_id).order("payment_date", desc=False).execute()

        return resp.data or []

    except PaymentValidationError:
        raise
    except Exception as exc:
        logger.error(f"Error listing payments: {exc}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao listar pagamentos",
        )


@router.get("/loans/{loan_id}/outstanding-balance")
async def get_outstanding_balance(
    loan_id: str,
    current_user: str = Depends(get_current_user),
) -> dict:
    """
    Get current outstanding balance for a loan after accounting for payments.

    Args:
        loan_id: The loan ID
        current_user: Current authenticated user ID

    Returns:
        Dict with original balance and current outstanding balance
    """
    supabase = get_supabase()

    try:
        # Verify user owns the loan
        loan = await validate_user_loan_ownership(current_user, loan_id, supabase)

        # Get all payments for this loan
        payments_resp = supabase.table("payment_records").select("*").eq("loan_id", loan_id).execute()
        payments = payments_resp.data or []

        # Calculate total paid
        total_paid = sum(p["amount_paid"] for p in payments)
        original_balance = float(loan["outstanding_balance"])
        current_balance = max(0, original_balance - total_paid)

        return {
            "loan_id": loan_id,
            "original_balance": original_balance,
            "total_paid": total_paid,
            "current_outstanding_balance": current_balance,
            "payment_count": len(payments),
        }

    except PaymentValidationError:
        raise
    except Exception as exc:
        logger.error(f"Error getting outstanding balance: {exc}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao calcular saldo devedor",
        )
