"""Integration test demonstrating the calculate_loan_with_history function."""
import asyncio
from datetime import date, timedelta
from app.finance.engine import calculate_loan_with_history
from app.finance.models import PaymentRecord, PaymentType


async def test_scenario_early_payment():
    """
    Scenario: Loan with early payments
    Result: Should show interest savings and early payoff
    """
    print("\n" + "="*60)
    print("SCENARIO: Early Payments (Adiantado)")
    print("="*60)
    
    loan = {
        'id': 'early-payment-test',
        'name': 'Test Early Payment',
        'outstanding_balance': 50000.0,
        'interest_rate_year': 6.5,
        'term_months': 120,
        'insurance_monthly': 0.0,
        'start_date': date(2024, 1, 1),
    }
    
    # Create early payments (more than planned)
    payments = [
        PaymentRecord(
            id=f'pay-early-{i}',
            loan_id='early-payment-test',
            payment_date=date(2024, 1, 15) + timedelta(days=30*i),
            amount_paid=550.0,  # Early payment ~20% more
            payment_type=PaymentType.NORMAL,
        )
        for i in range(6)
    ]
    
    result = await calculate_loan_with_history(loan, payments)
    
    print(f"\nLoan: {result.loan_name}")
    print(f"Calculated History Months: {result.summary.months_planned}")
    print(f"Actual History Months: {result.summary.months_actual}")
    print(f"\nPayment Summary:")
    print(f"  Total Planned:  R$ {result.summary.total_payment_planned:,.2f}")
    print(f"  Total Actual:   R$ {result.summary.total_payment_actual:,.2f}")
    print(f"  Deviation:      R$ {result.summary.total_deviation:,.2f}")
    print(f"\nInterest Summary:")
    print(f"  Total Planned:  R$ {result.summary.total_interest_planned:,.2f}")
    print(f"  Total Actual:   R$ {result.summary.total_interest_actual:,.2f}")
    print(f"  Saved:          R$ {result.summary.total_interest_saved:,.2f}")
    print(f"\nPayoff Status:")
    print(f"  Planned Date:   {result.summary.payoff_date_planned}")
    print(f"  Actual Date:    {result.summary.payoff_date_actual}")
    print(f"  Days Ahead:     {result.summary.days_ahead}")
    
    print("\nFirst 3 Months (Calculated):")
    for entry in result.calculated_history[:3]:
        print(f"  Month {entry.month}: Payment R$ {entry.payment_planned:,.2f} | "
              f"Interest R$ {entry.interest:,.2f} | Balance R$ {entry.outstanding_balance:,.2f}")
    
    print("\nFirst 3 Months (Actual):")
    for entry in result.actual_history[:3]:
        print(f"  Month {entry.month}: Payment R$ {entry.payment_actual:,.2f} | "
              f"Deviation R$ {entry.deviation:,.2f} | Balance R$ {entry.outstanding_balance:,.2f}")


async def test_scenario_no_payments():
    """
    Scenario: Loan with no payments yet
    Result: Actual should match calculated
    """
    print("\n" + "="*60)
    print("SCENARIO: No Payments Yet (Novo Contrato)")
    print("="*60)
    
    loan = {
        'id': 'no-payment-test',
        'name': 'New Loan - No Payments',
        'outstanding_balance': 100000.0,
        'interest_rate_year': 5.5,
        'term_months': 240,
        'insurance_monthly': 75.0,
        'start_date': date(2024, 1, 1),
    }
    
    result = await calculate_loan_with_history(loan, [])
    
    print(f"\nLoan: {result.loan_name}")
    print(f"Original Amount: R$ {loan['outstanding_balance']:,.2f}")
    print(f"Interest Rate: {loan['interest_rate_year']}%")
    print(f"Term: {loan['term_months']} months")
    
    # Verify actual matches calculated
    mismatch = 0
    for calc, actual in zip(result.calculated_history, result.actual_history):
        if abs(calc.payment_planned - actual.payment_actual) > 0.01:
            mismatch += 1
    
    print(f"\nMonth-to-Month Alignment: {len(result.calculated_history) - mismatch}/{len(result.calculated_history)} match")
    
    print(f"\nPayment Summary:")
    print(f"  Total Planned:  R$ {result.summary.total_payment_planned:,.2f}")
    print(f"  Total Actual:   R$ {result.summary.total_payment_actual:,.2f}")
    print(f"  Interest Cost:  R$ {result.summary.total_interest_planned:,.2f}")
    
    print(f"\nPayoff Date: {result.summary.payoff_date_planned}")
    
    print("\nFirst Payment Details:")
    first = result.calculated_history[0]
    print(f"  Amount:      R$ {first.payment_planned:,.2f}")
    print(f"  Amortization: R$ {first.amortization:,.2f}")
    print(f"  Interest:    R$ {first.interest:,.2f}")
    print(f"  Insurance:   R$ {first.insurance:,.2f}")


async def test_scenario_partial_payments():
    """
    Scenario: Loan with partial/late payments
    Result: Should show increased balance and interest
    """
    print("\n" + "="*60)
    print("SCENARIO: Partial/Late Payments (Atraso)")
    print("="*60)
    
    loan = {
        'id': 'partial-payment-test',
        'name': 'Test Partial Payment',
        'outstanding_balance': 30000.0,
        'interest_rate_year': 7.0,
        'term_months': 60,
        'insurance_monthly': 25.0,
        'start_date': date(2024, 1, 1),
    }
    
    # Create partial/late payments
    payments = [
        PaymentRecord(
            id='pay-partial-1',
            loan_id='partial-payment-test',
            payment_date=date(2024, 1, 20),  # On time
            amount_paid=550.0,
            payment_type=PaymentType.NORMAL,
        ),
        PaymentRecord(
            id='pay-partial-2',
            loan_id='partial-payment-test',
            payment_date=date(2024, 2, 25),  # Late
            amount_paid=400.0,  # Partial
            payment_type=PaymentType.NORMAL,
        ),
        PaymentRecord(
            id='pay-partial-3',
            loan_id='partial-payment-test',
            payment_date=date(2024, 3, 20),
            amount_paid=450.0,  # Still partial
            payment_type=PaymentType.NORMAL,
        ),
    ]
    
    result = await calculate_loan_with_history(loan, payments)
    
    print(f"\nLoan: {result.loan_name}")
    print(f"Original Balance: R$ {loan['outstanding_balance']:,.2f}")
    
    print(f"\nPayment Analysis:")
    print(f"  Planned Total:  R$ {result.summary.total_payment_planned:,.2f}")
    print(f"  Actual Total:   R$ {result.summary.total_payment_actual:,.2f}")
    print(f"  Shortfall:      R$ {abs(min(0, result.summary.total_deviation)):,.2f}")
    
    print(f"\nInterest Impact:")
    print(f"  Additional Int: R$ {abs(min(0, result.summary.total_interest_saved)):,.2f}")
    
    print("\nPayment History (First 3 Months):")
    for entry in result.actual_history[:3]:
        print(f"  Month {entry.month}: "
              f"Paid R$ {entry.payment_actual:,.2f} "
              f"(Planned R$ {entry.payment_planned:,.2f}, "
              f"Dev: {entry.deviation:+.2f}) | "
              f"Balance: R$ {entry.outstanding_balance:,.2f}")


async def main():
    """Run all test scenarios."""
    print("\n" + "="*60)
    print("CALCULATION ENGINE DEMONSTRATION")
    print("calculate_loan_with_history() - Estimated vs Actual")
    print("="*60)
    
    try:
        await test_scenario_no_payments()
        await test_scenario_early_payment()
        await test_scenario_partial_payments()
        
        print("\n" + "="*60)
        print("[OK] All scenarios completed successfully")
        print("="*60 + "\n")
        
    except Exception as e:
        print(f"\n[ERROR] {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    asyncio.run(main())
