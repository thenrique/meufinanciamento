"""Tests for the loan calculation engine (calculate_loan_with_history)."""
import pytest
from datetime import date, timedelta
from app.finance.engine import calculate_loan_with_history
from app.finance.models import PaymentRecord, PaymentType


@pytest.fixture
def sample_loan():
    """Create a sample loan for testing."""
    return {
        'id': 'test-loan-001',
        'name': 'Casa - Financiamento',
        'outstanding_balance': 50000.0,
        'interest_rate_year': 6.5,
        'term_months': 120,
        'insurance_monthly': 50.0,
        'start_date': date(2024, 1, 1),
    }


@pytest.mark.asyncio
async def test_calculate_loan_no_payments(sample_loan):
    """Test calculation with no payments made (should match estimated)."""
    result = await calculate_loan_with_history(sample_loan, [])
    
    assert result.loan_id == 'test-loan-001'
    assert result.loan_name == 'Casa - Financiamento'
    assert len(result.calculated_history) > 0
    assert len(result.actual_history) > 0
    
    # With no payments, actual should match estimated
    for calc, actual in zip(result.calculated_history, result.actual_history):
        assert abs(calc.payment_planned - actual.payment_actual) < 0.01


@pytest.mark.asyncio
async def test_calculate_loan_on_time_payments(sample_loan):
    """Test with on-time regular payments (no deviation)."""
    payments = [
        PaymentRecord(
            id=f'pay-{i}',
            loan_id='test-loan-001',
            payment_date=date(2024, 1 + (i // 1), 15 if (i % 1) == 0 else 20),
            amount_paid=600.0,  # Approximate planned payment
            payment_type=PaymentType.NORMAL,
        )
        for i in range(6)
    ]
    
    result = await calculate_loan_with_history(sample_loan, payments)
    
    assert result.loan_id == 'test-loan-001'
    assert len(result.actual_history) >= 1
    assert result.summary.total_payment_actual > 0
    assert result.summary.total_payment_planned > 0


@pytest.mark.asyncio
async def test_calculate_loan_early_payments(sample_loan):
    """Test with early/extra payments (adiantado)."""
    payments = [
        PaymentRecord(
            id=f'pay-early-{i}',
            loan_id='test-loan-001',
            payment_date=date(2024, 1 + (i // 1), 10),
            amount_paid=800.0,  # More than planned
            payment_type=PaymentType.NORMAL,
        )
        for i in range(3)
    ]
    
    result = await calculate_loan_with_history(sample_loan, payments)
    
    assert result.summary.total_payment_actual > result.summary.total_payment_planned
    assert result.summary.total_interest_saved > 0


@pytest.mark.asyncio
async def test_calculate_loan_late_payments(sample_loan):
    """Test with late/partial payments (atrasado)."""
    payments = [
        PaymentRecord(
            id=f'pay-late-{i}',
            loan_id='test-loan-001',
            payment_date=date(2024, 2, 15),  # Late payment
            amount_paid=400.0,  # Less than planned
            payment_type=PaymentType.NORMAL,
        ),
        PaymentRecord(
            id='pay-late-1',
            loan_id='test-loan-001',
            payment_date=date(2024, 3, 15),  # Next month
            amount_paid=400.0,
            payment_type=PaymentType.NORMAL,
        ),
    ]
    
    result = await calculate_loan_with_history(sample_loan, payments)
    
    assert len(result.actual_history) >= 2
    # Balance should be higher due to lower payments
    assert result.actual_history[-1].outstanding_balance > (sample_loan['outstanding_balance'] * 0.9)


@pytest.mark.asyncio
async def test_calculate_loan_mixed_payments(sample_loan):
    """Test with mixed payment history (on-time, early, late)."""
    start = date(2024, 1, 15)
    payments = [
        PaymentRecord(
            id='pay-1',
            loan_id='test-loan-001',
            payment_date=start,
            amount_paid=700.0,  # Early
            payment_type=PaymentType.NORMAL,
        ),
        PaymentRecord(
            id='pay-2',
            loan_id='test-loan-001',
            payment_date=start + timedelta(days=35),
            amount_paid=500.0,  # Late and partial
            payment_type=PaymentType.NORMAL,
        ),
        PaymentRecord(
            id='pay-3',
            loan_id='test-loan-001',
            payment_date=start + timedelta(days=60),
            amount_paid=650.0,  # On-time
            payment_type=PaymentType.NORMAL,
        ),
    ]
    
    result = await calculate_loan_with_history(sample_loan, payments)
    
    assert len(result.actual_history) >= 2
    assert result.summary.total_deviation != 0


@pytest.mark.asyncio
async def test_summary_calculations(sample_loan):
    """Test that summary calculations are correct."""
    payments = [
        PaymentRecord(
            id='pay-summary-1',
            loan_id='test-loan-001',
            payment_date=date(2024, 1, 15),
            amount_paid=600.0,
            payment_type=PaymentType.NORMAL,
        ),
    ]
    
    result = await calculate_loan_with_history(sample_loan, payments)
    
    summary = result.summary
    
    # Verify summary has required fields
    assert summary.total_payment_planned >= 0
    assert summary.total_payment_actual >= 0
    assert summary.total_interest_planned >= 0
    assert summary.total_interest_actual >= 0
    assert summary.months_planned > 0
    assert summary.payoff_date_planned is not None


@pytest.mark.asyncio
async def test_edge_case_empty_loan():
    """Test edge case with minimal loan data."""
    minimal_loan = {
        'id': 'minimal',
        'name': 'Minimal Loan',
        'outstanding_balance': 10000.0,
        'interest_rate_year': 5.0,
        'term_months': 60,
        'insurance_monthly': 0.0,
        'start_date': date(2024, 1, 1),
    }
    
    result = await calculate_loan_with_history(minimal_loan, [])
    
    assert result.loan_id == 'minimal'
    assert len(result.calculated_history) > 0
    assert len(result.actual_history) > 0


@pytest.mark.asyncio
async def test_date_string_handling(sample_loan):
    """Test that string dates are handled correctly."""
    loan_with_string_date = {
        **sample_loan,
        'start_date': '2024-01-01',  # String instead of date object
    }
    
    result = await calculate_loan_with_history(loan_with_string_date, [])
    
    assert result.loan_id == 'test-loan-001'
    assert len(result.calculated_history) > 0


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
