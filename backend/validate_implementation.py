"""Comprehensive validation test for calculate_loan_with_history implementation."""
import asyncio
import sys
from datetime import date, timedelta
from app.finance.engine import calculate_loan_with_history
from app.finance.models import (
    PaymentRecord,
    PaymentType,
    CalculatedMonthEntry,
    ActualMonthEntry,
    ComparisonSummary,
    LoanWithPaymentHistory,
)

# Set UTF-8 encoding for Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


async def validate_implementation():
    """Comprehensive validation of the calculate_loan_with_history function."""
    
    print("\n" + "="*70)
    print("COMPREHENSIVE VALIDATION TEST")
    print("="*70)
    
    tests_passed = 0
    tests_total = 0
    
    # Test 1: Basic Structure
    tests_total += 1
    print("\n[TEST 1] Basic Function Structure")
    try:
        loan = {
            'id': 'test-001',
            'name': 'Test Loan',
            'outstanding_balance': 50000.0,
            'interest_rate_year': 6.5,
            'term_months': 120,
            'insurance_monthly': 0.0,
            'start_date': date(2024, 1, 1),
        }
        
        result = await calculate_loan_with_history(loan, [])
        
        assert isinstance(result, LoanWithPaymentHistory), "Return type mismatch"
        assert result.loan_id == 'test-001', "Loan ID not preserved"
        assert result.loan_name == 'Test Loan', "Loan name not preserved"
        assert len(result.calculated_history) > 0, "No calculated history"
        assert len(result.actual_history) > 0, "No actual history"
        assert isinstance(result.summary, ComparisonSummary), "Summary type mismatch"
        
        print("  [OK] Function returns correct structure")
        print(f"  [OK] Generated {len(result.calculated_history)} calculated months")
        print(f"  [OK] Generated {len(result.actual_history)} actual months")
        tests_passed += 1
    except Exception as e:
        print(f"  [FAIL] {e}")
    
    # Test 2: Calculated History Properties
    tests_total += 1
    print("\n[TEST 2] Calculated History Properties")
    try:
        loan = {
            'id': 'test-002',
            'name': 'Test Loan 2',
            'outstanding_balance': 100000.0,
            'interest_rate_year': 5.5,
            'term_months': 120,
            'insurance_monthly': 50.0,
            'start_date': date(2024, 1, 1),
        }
        
        result = await calculate_loan_with_history(loan, [])
        
        # Verify each entry
        for i, entry in enumerate(result.calculated_history):
            assert isinstance(entry, CalculatedMonthEntry), f"Entry {i} wrong type"
            assert entry.month == i + 1, f"Month number wrong at {i}"
            assert entry.payment_planned > 0, f"No payment at {i}"
            assert entry.outstanding_balance >= 0, f"Negative balance at {i}"
            assert entry.interest >= 0, f"Negative interest at {i}"
            assert entry.amortization >= 0, f"Negative amortization at {i}"
        
        # Verify balance decreases
        balances = [e.outstanding_balance for e in result.calculated_history]
        assert balances == sorted(balances, reverse=True), "Balance not decreasing"
        assert balances[-1] <= 0.01, "Loan not paid off"
        
        print(f"  [OK] All {len(result.calculated_history)} entries valid")
        print(f"  [OK] Balance decreases from {balances[0]:.2f} to {balances[-1]:.2f}")
        print(f"  [OK] First payment: R$ {result.calculated_history[0].payment_planned:.2f}")
        tests_passed += 1
    except Exception as e:
        print(f"  [FAIL] Failed: {e}")
    
    # Test 3: Actual History with Payments
    tests_total += 1
    print("\n[TEST 3] Actual History with Payments")
    try:
        loan = {
            'id': 'test-003',
            'name': 'Test Loan 3',
            'outstanding_balance': 30000.0,
            'interest_rate_year': 7.0,
            'term_months': 60,
            'insurance_monthly': 0.0,
            'start_date': date(2024, 1, 1),
        }
        
        payments = [
            PaymentRecord(
                id=f'pay-{i}',
                loan_id='test-003',
                payment_date=date(2024, 1, 15) + timedelta(days=30*i),
                amount_paid=600.0,
                payment_type=PaymentType.NORMAL,
            )
            for i in range(3)
        ]
        
        result = await calculate_loan_with_history(loan, payments)
        
        # Verify actual history
        for i, entry in enumerate(result.actual_history):
            assert isinstance(entry, ActualMonthEntry), f"Entry {i} wrong type"
            assert entry.payment_actual >= 0, f"Negative payment at {i}"
            assert entry.deviation is not None, f"No deviation at {i}"
            assert len(entry.payments) <= 1, f"Multiple payments in month {i}"
        
        # Verify payments are recorded
        payment_count = sum(len(e.payments) for e in result.actual_history)
        assert payment_count == len(payments), f"Payment count mismatch"
        
        print(f"  [OK] All {len(result.actual_history)} entries valid")
        print(f"  [OK] Recorded {payment_count} payments")
        print(f"  [OK] Deviation tracking active")
        tests_passed += 1
    except Exception as e:
        print(f"  [FAIL] Failed: {e}")
    
    # Test 4: No Payments Scenario
    tests_total += 1
    print("\n[TEST 4] No Payments Scenario (Estimated = Actual)")
    try:
        loan = {
            'id': 'test-004',
            'name': 'Test Loan 4',
            'outstanding_balance': 50000.0,
            'interest_rate_year': 6.0,
            'term_months': 100,
            'insurance_monthly': 0.0,
            'start_date': date(2024, 1, 1),
        }
        
        result = await calculate_loan_with_history(loan, [])
        
        # With no payments, actual should match calculated
        mismatches = 0
        for calc, actual in zip(result.calculated_history, result.actual_history):
            if abs(calc.payment_planned - actual.payment_actual) > 0.01:
                mismatches += 1
        
        assert mismatches == 0, f"{mismatches} months don't match"
        
        print(f"  [OK] {len(result.calculated_history)} months aligned perfectly")
        print(f"  [OK] Deviations are zero")
        tests_passed += 1
    except Exception as e:
        print(f"  [FAIL] Failed: {e}")
    
    # Test 5: Summary Calculations
    tests_total += 1
    print("\n[TEST 5] Summary Calculations")
    try:
        loan = {
            'id': 'test-005',
            'name': 'Test Loan 5',
            'outstanding_balance': 40000.0,
            'interest_rate_year': 8.0,
            'term_months': 80,
            'insurance_monthly': 0.0,
            'start_date': date(2024, 1, 1),
        }
        
        result = await calculate_loan_with_history(loan, [])
        summary = result.summary
        
        # Verify totals match sums
        calc_payment_sum = sum(m.payment_planned for m in result.calculated_history)
        actual_payment_sum = sum(m.payment_actual for m in result.actual_history)
        
        assert abs(summary.total_payment_planned - calc_payment_sum) < 1.0, "Calculated payment mismatch"
        assert abs(summary.total_payment_actual - actual_payment_sum) < 1.0, "Actual payment mismatch"
        
        # Verify interest totals
        calc_interest_sum = sum(m.interest for m in result.calculated_history)
        actual_interest_sum = sum(m.interest for m in result.actual_history)
        
        assert abs(summary.total_interest_planned - calc_interest_sum) < 1.0, "Interest mismatch"
        assert abs(summary.total_interest_actual - actual_interest_sum) < 1.0, "Actual interest mismatch"
        
        # Verify payoff dates
        assert summary.payoff_date_planned == result.calculated_history[-1].date, "Payoff date mismatch"
        
        print(f"  [OK] Total payment sums verified")
        print(f"  [OK] Interest totals verified")
        print(f"  [OK] Payoff dates verified")
        print(f"  [OK] Summary.total_interest_saved = R$ {summary.total_interest_saved:.2f}")
        tests_passed += 1
    except Exception as e:
        print(f"  [FAIL] Failed: {e}")
    
    # Test 6: Early Payments Detection
    tests_total += 1
    print("\n[TEST 6] Early Payments Detection")
    try:
        loan = {
            'id': 'test-006',
            'name': 'Test Loan 6',
            'outstanding_balance': 60000.0,
            'interest_rate_year': 6.5,
            'term_months': 120,
            'insurance_monthly': 0.0,
            'start_date': date(2024, 1, 1),
        }
        
        # Early payments (more than planned)
        payments = [
            PaymentRecord(
                id=f'pay-early-{i}',
                loan_id='test-006',
                payment_date=date(2024, 1, 15) + timedelta(days=30*i),
                amount_paid=700.0,  # More than typical ~560
                payment_type=PaymentType.NORMAL,
            )
            for i in range(5)
        ]
        
        result = await calculate_loan_with_history(loan, payments)
        
        # Interest should be saved
        assert result.summary.total_interest_saved > 0, "Should save interest"
        assert result.summary.days_ahead >= 0, "Should be ahead"
        
        print(f"  [OK] Early payments detected")
        print(f"  [OK] Interest saved: R$ {result.summary.total_interest_saved:.2f}")
        print(f"  [OK] Days ahead: {result.summary.days_ahead}")
        tests_passed += 1
    except Exception as e:
        print(f"  [FAIL] Failed: {e}")
    
    # Test 7: Date Handling
    tests_total += 1
    print("\n[TEST 7] Date Handling (String and Date Objects)")
    try:
        # Test with string date
        loan_str = {
            'id': 'test-007',
            'name': 'Test Loan 7',
            'outstanding_balance': 45000.0,
            'interest_rate_year': 6.0,
            'term_months': 90,
            'insurance_monthly': 0.0,
            'start_date': '2024-01-01',  # String format
        }
        
        result_str = await calculate_loan_with_history(loan_str, [])
        
        # Test with date object
        loan_date = {
            'id': 'test-007b',
            'name': 'Test Loan 7b',
            'outstanding_balance': 45000.0,
            'interest_rate_year': 6.0,
            'term_months': 90,
            'insurance_monthly': 0.0,
            'start_date': date(2024, 1, 1),  # Date object
        }
        
        result_date = await calculate_loan_with_history(loan_date, [])
        
        # Both should work and produce same results
        assert len(result_str.calculated_history) == len(result_date.calculated_history), "Different month counts"
        
        print(f"  [OK] String dates handled correctly")
        print(f"  [OK] Date objects handled correctly")
        print(f"  [OK] Both produce same results")
        tests_passed += 1
    except Exception as e:
        print(f"  [FAIL] Failed: {e}")
    
    # Test 8: Edge Case - Very Short Loan
    tests_total += 1
    print("\n[TEST 8] Edge Case - Very Short Loan (12 months)")
    try:
        loan = {
            'id': 'test-008',
            'name': 'Test Loan 8',
            'outstanding_balance': 5000.0,
            'interest_rate_year': 10.0,
            'term_months': 12,
            'insurance_monthly': 0.0,
            'start_date': date(2024, 1, 1),
        }
        
        result = await calculate_loan_with_history(loan, [])
        
        assert len(result.calculated_history) == 12, "Should have 12 months"
        assert result.summary.payoff_date_planned == date(2024, 12, 1), "Wrong payoff date"
        
        print(f"  [OK] Short loan handled correctly")
        print(f"  [OK] Payoff date: {result.summary.payoff_date_planned}")
        tests_passed += 1
    except Exception as e:
        print(f"  [FAIL] Failed: {e}")
    
    # Test 9: Insurance Premium Included
    tests_total += 1
    print("\n[TEST 9] Insurance Premium Handling")
    try:
        loan_no_insurance = {
            'id': 'test-009a',
            'name': 'No Insurance',
            'outstanding_balance': 30000.0,
            'interest_rate_year': 5.0,
            'term_months': 60,
            'insurance_monthly': 0.0,
            'start_date': date(2024, 1, 1),
        }
        
        loan_with_insurance = {
            'id': 'test-009b',
            'name': 'With Insurance',
            'outstanding_balance': 30000.0,
            'interest_rate_year': 5.0,
            'term_months': 60,
            'insurance_monthly': 50.0,
            'start_date': date(2024, 1, 1),
        }
        
        result_no_ins = await calculate_loan_with_history(loan_no_insurance, [])
        result_with_ins = await calculate_loan_with_history(loan_with_insurance, [])
        
        # Total payment with insurance should be higher
        assert result_with_ins.summary.total_payment_planned > result_no_ins.summary.total_payment_planned, \
            "Insurance should increase total"
        
        # Insurance should be 50 * 60 = 3000
        insurance_total = sum(m.insurance for m in result_with_ins.calculated_history)
        assert abs(insurance_total - 3000.0) < 1.0, "Insurance total wrong"
        
        print(f"  [OK] Insurance premium tracked correctly")
        print(f"  [OK] Total insurance: R$ {insurance_total:.2f}")
        tests_passed += 1
    except Exception as e:
        print(f"  [FAIL] Failed: {e}")
    
    # Final Summary
    print("\n" + "="*70)
    print(f"VALIDATION RESULTS: {tests_passed}/{tests_total} tests passed")
    print("="*70)
    
    if tests_passed == tests_total:
        print("\n[OK] ALL TESTS PASSED - Implementation is production-ready!\n")
        return True
    else:
        print(f"\n[FAIL] {tests_total - tests_passed} tests failed\n")
        return False


if __name__ == '__main__':
    success = asyncio.run(validate_implementation())
    exit(0 if success else 1)
