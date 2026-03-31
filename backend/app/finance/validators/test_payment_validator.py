"""
Unit tests for payment validators.

Run with: pytest backend/app/finance/validators/test_payment_validator.py
"""

import pytest
from datetime import date, timedelta

from fastapi import status

from app.finance.models.payment import PaymentRecord, PaymentType
from app.finance.validators import (
    PaymentValidationError,
    validate_payment_amount,
    validate_payment_date,
    validate_payment_type,
    validate_unique_payment_date,
)


class TestPaymentDate:
    """Tests for validate_payment_date function."""

    def test_valid_past_date(self):
        """Should accept payment dates in the past."""
        past_date = date(2024, 1, 15)
        loan_start = date(2020, 1, 1)
        # Should not raise
        validate_payment_date(past_date, loan_start)

    def test_future_date_raises_error(self):
        """Should reject payment dates in the future."""
        future_date = date.today() + timedelta(days=30)
        loan_start = date(2020, 1, 1)

        with pytest.raises(PaymentValidationError) as exc_info:
            validate_payment_date(future_date, loan_start)

        assert exc_info.value.status_code == status.HTTP_400_BAD_REQUEST
        assert "futuro" in exc_info.value.detail

    def test_date_before_loan_start_raises_error(self):
        """Should reject payment dates before loan start."""
        payment_date = date(2019, 12, 31)
        loan_start = date(2020, 1, 1)

        with pytest.raises(PaymentValidationError) as exc_info:
            validate_payment_date(payment_date, loan_start)

        assert exc_info.value.status_code == status.HTTP_400_BAD_REQUEST
        assert "anterior" in exc_info.value.detail
        assert "01/01/2020" in exc_info.value.detail  # Formatted date

    def test_date_equals_loan_start(self):
        """Should accept payment date equal to loan start."""
        loan_start = date(2020, 1, 1)
        # Should not raise
        validate_payment_date(loan_start, loan_start)

    def test_today_date(self):
        """Should accept payment date as today."""
        today = date.today()
        loan_start = date(2020, 1, 1)
        # Should not raise
        validate_payment_date(today, loan_start)


class TestPaymentAmount:
    """Tests for validate_payment_amount function."""

    def test_valid_amount(self):
        """Should accept valid payment amounts."""
        # Should not raise
        validate_payment_amount(1500.00, 50000.00)
        validate_payment_amount(50000.00, 50000.00)  # Exact balance
        validate_payment_amount(0.01, 1000.00)  # Minimum non-zero

    def test_zero_amount_raises_error(self):
        """Should reject zero payment amount."""
        with pytest.raises(PaymentValidationError) as exc_info:
            validate_payment_amount(0, 1000.00)

        assert exc_info.value.status_code == status.HTTP_400_BAD_REQUEST
        assert "maior que zero" in exc_info.value.detail

    def test_negative_amount_raises_error(self):
        """Should reject negative payment amount."""
        with pytest.raises(PaymentValidationError) as exc_info:
            validate_payment_amount(-1500.00, 50000.00)

        assert exc_info.value.status_code == status.HTTP_400_BAD_REQUEST
        assert "maior que zero" in exc_info.value.detail

    def test_overpayment_raises_error(self):
        """Should reject payment amount exceeding balance."""
        with pytest.raises(PaymentValidationError) as exc_info:
            validate_payment_amount(51000.00, 50000.00)

        assert exc_info.value.status_code == status.HTTP_400_BAD_REQUEST
        assert "saldo devedor" in exc_info.value.detail
        assert "51000.00" in exc_info.value.detail
        assert "50000.00" in exc_info.value.detail

    def test_error_message_includes_amounts(self):
        """Error message should include both amounts for clarity."""
        with pytest.raises(PaymentValidationError) as exc_info:
            validate_payment_amount(2000.50, 1500.00)

        assert "2000.50" in exc_info.value.detail
        assert "1500.00" in exc_info.value.detail


class TestPaymentType:
    """Tests for validate_payment_type function."""

    def test_valid_normal_type(self):
        """Should accept 'normal' payment type."""
        # Should not raise
        validate_payment_type("normal")

    def test_valid_extra_monthly_type(self):
        """Should accept 'extra_monthly' payment type."""
        # Should not raise
        validate_payment_type("extra_monthly")

    def test_valid_extra_one_time_type(self):
        """Should accept 'extra_one_time' payment type."""
        # Should not raise
        validate_payment_type("extra_one_time")

    def test_valid_amortization_type(self):
        """Should accept 'amortization' payment type."""
        # Should not raise
        validate_payment_type("amortization")

    def test_invalid_type_raises_error(self):
        """Should reject invalid payment type."""
        with pytest.raises(PaymentValidationError) as exc_info:
            validate_payment_type("invalid_type")

        assert exc_info.value.status_code == status.HTTP_400_BAD_REQUEST
        assert "inválido" in exc_info.value.detail
        assert "normal" in exc_info.value.detail
        assert "extra_monthly" in exc_info.value.detail

    def test_case_sensitive(self):
        """Payment type validation should be case-sensitive."""
        with pytest.raises(PaymentValidationError):
            validate_payment_type("Normal")  # Capital N

        with pytest.raises(PaymentValidationError):
            validate_payment_type("NORMAL")  # All caps

    def test_error_lists_all_valid_types(self):
        """Error message should list all valid types."""
        with pytest.raises(PaymentValidationError) as exc_info:
            validate_payment_type("invalid")

        detail = exc_info.value.detail
        assert "normal" in detail
        assert "extra_monthly" in detail
        assert "extra_one_time" in detail
        assert "amortization" in detail


class TestUniquePaymentDate:
    """Tests for validate_unique_payment_date function."""

    def test_no_existing_payments(self):
        """Should accept payment date with no existing payments."""
        # Should not raise
        validate_unique_payment_date("loan_123", date(2024, 1, 15), [])

    def test_different_dates(self):
        """Should accept different payment dates."""
        existing = [
            PaymentRecord(
                id="p1",
                loan_id="loan_123",
                payment_date=date(2024, 1, 10),
                amount_paid=1500.00,
                payment_type=PaymentType.NORMAL,
            )
        ]

        # Should not raise
        validate_unique_payment_date("loan_123", date(2024, 1, 15), existing)

    def test_duplicate_date_raises_error(self):
        """Should reject duplicate payment date."""
        existing = [
            PaymentRecord(
                id="p1",
                loan_id="loan_123",
                payment_date=date(2024, 1, 15),
                amount_paid=1500.00,
                payment_type=PaymentType.NORMAL,
            )
        ]

        with pytest.raises(PaymentValidationError) as exc_info:
            validate_unique_payment_date("loan_123", date(2024, 1, 15), existing)

        assert exc_info.value.status_code == status.HTTP_409_CONFLICT
        assert "Já existe um pagamento registrado" in exc_info.value.detail
        assert "15/01/2024" in exc_info.value.detail

    def test_multiple_payments_different_loans(self):
        """Should check uniqueness per loan, not globally."""
        existing_other_loan = [
            PaymentRecord(
                id="p1",
                loan_id="other_loan",
                payment_date=date(2024, 1, 15),
                amount_paid=1500.00,
                payment_type=PaymentType.NORMAL,
            )
        ]

        # Should not raise - different loan
        validate_unique_payment_date("loan_123", date(2024, 1, 15), existing_other_loan)

    def test_error_date_format_brazilian(self):
        """Error should show date in Brazilian format (DD/MM/YYYY)."""
        existing = [
            PaymentRecord(
                id="p1",
                loan_id="loan_123",
                payment_date=date(2024, 3, 25),
                amount_paid=1500.00,
                payment_type=PaymentType.NORMAL,
            )
        ]

        with pytest.raises(PaymentValidationError) as exc_info:
            validate_unique_payment_date("loan_123", date(2024, 3, 25), existing)

        assert "25/03/2024" in exc_info.value.detail


class TestPaymentValidationIntegration:
    """Integration tests combining multiple validators."""

    def test_valid_payment_all_rules(self):
        """Should accept payment passing all validation rules."""
        loan_start = date(2020, 1, 1)
        payment_date = date(2024, 1, 15)
        amount = 1500.00
        outstanding = 50000.00
        payment_type = "normal"
        existing = []

        # All validations should pass
        validate_payment_date(payment_date, loan_start)
        validate_payment_amount(amount, outstanding)
        validate_payment_type(payment_type)
        validate_unique_payment_date("loan_123", payment_date, existing)

    def test_invalid_multiple_rules(self):
        """Should reject payment violating multiple rules."""
        # Future date AND invalid type
        with pytest.raises(PaymentValidationError):
            validate_payment_date(date(2099, 1, 1), date(2020, 1, 1))

        # Overpayment AND zero amount would fail on zero first
        with pytest.raises(PaymentValidationError):
            validate_payment_amount(0, 1000)
