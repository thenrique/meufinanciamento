"""Validators for payment record operations in finance module."""

from datetime import date, datetime
from typing import List, Optional

from fastapi import HTTPException, status
from loguru import logger
from supabase import Client

from app.finance.models.payment import PaymentRecord, PaymentType


class PaymentValidationError(HTTPException):
    """Custom exception for payment validation errors."""

    def __init__(
        self,
        detail: str,
        status_code: int = status.HTTP_400_BAD_REQUEST,
    ):
        super().__init__(status_code=status_code, detail=detail)
        logger.warning(f"PaymentValidationError: {detail}")


def validate_payment_date(payment_date: date, loan_start_date: date) -> None:
    """
    Validate payment date.

    Rules:
    - Must not be in the future
    - Must be after loan start date

    Args:
        payment_date: The payment date to validate
        loan_start_date: The loan start date for comparison

    Raises:
        PaymentValidationError: If validation fails
    """
    today = date.today()

    if payment_date > today:
        raise PaymentValidationError(
            detail="Data do pagamento não pode ser no futuro",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    if payment_date < loan_start_date:
        raise PaymentValidationError(
            detail=f"Data do pagamento não pode ser anterior à data de início do financiamento ({loan_start_date.strftime('%d/%m/%Y')})",
            status_code=status.HTTP_400_BAD_REQUEST,
        )


def validate_payment_amount(amount: float, outstanding_balance: float) -> None:
    """
    Validate payment amount.

    Rules:
    - Must be greater than 0
    - Must not exceed outstanding balance (no overpayment)

    Args:
        amount: The payment amount to validate
        outstanding_balance: The current outstanding balance

    Raises:
        PaymentValidationError: If validation fails
    """
    if amount <= 0:
        raise PaymentValidationError(
            detail="Valor do pagamento deve ser maior que zero",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    if amount > outstanding_balance:
        raise PaymentValidationError(
            detail=f"Valor do pagamento (R$ {amount:.2f}) não pode ser maior que o saldo devedor (R$ {outstanding_balance:.2f})",
            status_code=status.HTTP_400_BAD_REQUEST,
        )


def validate_unique_payment_date(
    loan_id: str, payment_date: date, existing_payments: List[PaymentRecord]
) -> None:
    """
    Validate that no duplicate payment dates exist for the same loan.

    Rules:
    - Payment date must be unique per loan

    Args:
        loan_id: The loan ID
        payment_date: The payment date to validate
        existing_payments: List of existing payment records for the loan

    Raises:
        PaymentValidationError: If duplicate date found
    """
    for payment in existing_payments:
        if payment.payment_date == payment_date:
            raise PaymentValidationError(
                detail=f"Já existe um pagamento registrado em {payment_date.strftime('%d/%m/%Y')}",
                status_code=status.HTTP_409_CONFLICT,
            )


def validate_payment_type(payment_type: str) -> None:
    """
    Validate payment type.

    Rules:
    - Must be one of the valid PaymentType values

    Args:
        payment_type: The payment type to validate

    Raises:
        PaymentValidationError: If payment type is invalid
    """
    valid_types = [pt.value for pt in PaymentType]

    if payment_type not in valid_types:
        raise PaymentValidationError(
            detail=f"Tipo de pagamento inválido. Valores aceitos: {', '.join(valid_types)}",
            status_code=status.HTTP_400_BAD_REQUEST,
        )


async def validate_user_loan_ownership(
    user_id: str, loan_id: str, supabase: Client
) -> dict:
    """
    Verify that user owns the loan.

    Rules:
    - Loan must exist in database
    - Loan must belong to the current user
    - Loan must be active

    Args:
        user_id: The current user ID
        loan_id: The loan ID to verify ownership
        supabase: Supabase client for database queries

    Returns:
        The loan record if validation passes

    Raises:
        PaymentValidationError: If loan doesn't exist or doesn't belong to user (403 Forbidden)
    """
    try:
        resp = supabase.table("loans").select("*").eq("id", loan_id).eq("user_id", user_id).single().execute()
        loan = resp.data

        if not loan:
            raise PaymentValidationError(
                detail="Financiamento não encontrado ou você não tem permissão para acessá-lo",
                status_code=status.HTTP_403_FORBIDDEN,
            )

        if not loan.get("is_active", True):
            raise PaymentValidationError(
                detail="Este financiamento foi cancelado e não aceita novos pagamentos",
                status_code=status.HTTP_403_FORBIDDEN,
            )

        return loan

    except PaymentValidationError:
        raise
    except Exception as exc:
        logger.error(f"Erro ao validar propriedade do financiamento: user_id={user_id}, loan_id={loan_id}, error={exc}")
        raise PaymentValidationError(
            detail="Erro ao validar acesso ao financiamento",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )
