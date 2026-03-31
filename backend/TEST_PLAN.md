# Payment & Loan History Integration Tests - Test Plan

## Overview
Comprehensive integration test suite for payment CRUD endpoints and loan history calculation in the meufinanciamento backend. Tests validate all HTTP endpoints, error scenarios, authentication, validation, and data integrity.

## Test Scope

### Endpoints Tested

#### 1. CREATE PAYMENT
- **Endpoint:** `POST /loans/{loan_id}/payments`
- **Status Code:** 201 (Created)
- **Authentication:** Required (Bearer token)
- **Purpose:** Create new payment record for a loan

#### 2. LIST PAYMENTS  
- **Endpoint:** `GET /loans/{loan_id}/payments`
- **Status Code:** 200 (OK)
- **Authentication:** Required (Bearer token)
- **Purpose:** Retrieve all payments for a loan with optional date filtering

#### 3. UPDATE PAYMENT
- **Endpoint:** `PUT /loans/{loan_id}/payments/{payment_id}`
- **Status Code:** 200 (OK)
- **Authentication:** Required (Bearer token)
- **Purpose:** Update payment details (amount, type, notes, date)

#### 4. DELETE PAYMENT
- **Endpoint:** `DELETE /loans/{loan_id}/payments/{payment_id}`
- **Status Code:** 204 (No Content)
- **Authentication:** Required (Bearer token)
- **Purpose:** Remove payment record

#### 5. GET LOAN HISTORY
- **Endpoint:** `GET /loans/{loan_id}/history`
- **Status Code:** 200 (OK)
- **Authentication:** Required (Bearer token)
- **Purpose:** Retrieve complete loan history with "Estimado x Realizado" comparison

---

## Test Cases (24 Total)

### CREATE PAYMENT Tests (8 tests)

| Test Case | Input | Expected Result | Status Code |
|-----------|-------|-----------------|-------------|
| test_create_payment_success | Valid payment data | Payment created successfully | 201 |
| test_create_payment_invalid_date | Invalid date format | Validation error | 422 |
| test_create_payment_future_date | Future date | Future date validation error | 400 |
| test_create_payment_duplicate_date | Duplicate payment date | Conflict error | 409 |
| test_create_payment_amount_exceeds_balance | Amount > outstanding balance | Amount validation error | 400 |
| test_create_payment_invalid_type | Invalid payment type | Enum validation error | 422 |
| test_create_payment_unauthorized | Missing auth token | Authentication error | 403 |
| test_create_payment_loan_not_found | Non-existent loan | Loan not found error | 403 |

#### Test Data for CREATE:
```json
{
  "loan_id": "d6f1d42a-001",
  "payment_date": "2024-02-10",
  "amount_paid": 1500.00,
  "payment_type": "normal",
  "notes": "Regular monthly payment"
}
```

#### Validation Rules:
- Payment date: Not in future, after loan start date
- Payment amount: > 0, ≤ outstanding_balance
- Payment type: normal | extra_monthly | extra_one_time | amortization
- Duplicate detection: No two payments on same date per loan
- User authorization: User must own the loan

---

### LIST PAYMENTS Tests (4 tests)

| Test Case | Scenario | Result | Status Code |
|-----------|----------|--------|-------------|
| test_list_payments_success | Retrieve all payments | Returns payment list | 200 |
| test_list_payments_with_date_filter | Date range filter | Returns filtered payments | 200 |
| test_list_payments_unauthorized | No auth token | Authentication error | 403 |
| test_list_payments_loan_not_found | Loan doesn't exist | Loan not found | 403 |

#### Query Parameters:
- `start_date` (optional): Filter payments from this date (YYYY-MM-DD)
- `end_date` (optional): Filter payments until this date (YYYY-MM-DD)

---

### UPDATE PAYMENT Tests (4 tests)

| Test Case | Scenario | Result | Status Code |
|-----------|----------|--------|-------------|
| test_update_payment_success | Valid update data | Payment updated | 200 |
| test_update_payment_not_found | Non-existent payment | Not found error | 404 |
| test_update_payment_unauthorized | No auth token | Authentication error | 403 |
| test_update_payment_invalid_data | Invalid amount | Amount validation error | 400 |

#### Updatable Fields:
- `payment_date` (optional): Must validate against business rules
- `amount_paid` (optional): Must be > 0 and ≤ outstanding_balance
- `payment_type` (optional): Valid enum value
- `notes` (optional): Free text

---

### DELETE PAYMENT Tests (3 tests)

| Test Case | Scenario | Result | Status Code |
|-----------|----------|--------|-------------|
| test_delete_payment_success | Valid deletion | Payment removed | 204 |
| test_delete_payment_not_found | Non-existent payment | Not found error | 404 |
| test_delete_payment_unauthorized | No auth token | Authentication error | 403 |

---

### LOAN HISTORY Tests (5 tests)

| Test Case | Scenario | Result | Status Code |
|-----------|----------|--------|-------------|
| test_get_history_success | Retrieve loan history | Complete history returned | 200 |
| test_get_history_with_calculations | Verify calculation fields | All calculations present | 200 |
| test_get_history_no_payments | No payments made yet | History with 0 actual values | 200 |
| test_get_history_unauthorized | No auth token | Authentication error | 403 |
| test_get_history_loan_not_found | Loan doesn't exist | Loan not found | 404 |

#### Response Structure:
```json
{
  "loan_id": "string",
  "loan_name": "string",
  "calculated_history": [
    {
      "month": 1,
      "date": "2024-02-10",
      "payment_planned": 1500.00,
      "amortization": 950.00,
      "interest": 531.25,
      "insurance": 50.00,
      "outstanding_balance": 74050.00
    }
  ],
  "actual_history": [
    {
      "month": 1,
      "date": "2024-02-10",
      "payment_actual": 1500.00,
      "payments": [...],
      "deviation": 0.00,
      ...
    }
  ],
  "summary": {
    "total_payment_planned": 270000.00,
    "total_payment_actual": 0.00,
    "total_interest_planned": 170000.00,
    "total_interest_actual": 0.00,
    "total_interest_saved": 0.00,
    "total_insurance": 0.00,
    "months_planned": 180,
    "months_actual": 0,
    "months_ahead": 0,
    "payoff_date_planned": "2034-01-01",
    "payoff_date_actual": null,
    "days_ahead": 0,
    "total_deviation": 0.00
  }
}
```

---

## Test Data

### Sample Loan
```json
{
  "id": "d6f1d42a-001",
  "user_id": "test-user-id",
  "name": "Financiamento Imobiliário",
  "total_amount": 100000.00,
  "outstanding_balance": 75000.00,
  "interest_rate_year": 8.5,
  "term_months": 180,
  "insurance_monthly": 50.0,
  "created_at": "2024-01-01",
  "payment_due_date_day": 10,
  "is_active": true
}
```

### Sample Payments
```json
[
  {
    "id": "d6f1d42a-p01",
    "loan_id": "d6f1d42a-001",
    "user_id": "test-user-id",
    "payment_date": "2024-02-10",
    "amount_paid": 1500.00,
    "payment_type": "normal",
    "notes": "Regular monthly payment"
  },
  {
    "id": "d6f1d42a-p02",
    "loan_id": "d6f1d42a-001",
    "user_id": "test-user-id",
    "payment_date": "2024-03-10",
    "amount_paid": 2000.00,
    "payment_type": "extra_monthly",
    "notes": "Extra contribution"
  }
]
```

---

## Error Scenarios Tested

### Authentication Errors (3 tests)
- Missing Authorization header → 403 Forbidden
- No authentication token → 403 Forbidden
- Invalid token → handled by FastAPI security

### Validation Errors (8 tests)
- Invalid date format → 422 Unprocessable Entity
- Future date → 400 Bad Request
- Negative amount → 422 Unprocessable Entity
- Amount exceeds balance → 400 Bad Request
- Invalid payment type → 422 Unprocessable Entity
- Duplicate payment date → 409 Conflict
- Missing required fields → 422 Unprocessable Entity

### Resource Errors (4 tests)
- Non-existent loan → 403 Forbidden (authorization check)
- Non-existent payment → 404 Not Found
- Unauthorized loan access → 403 Forbidden
- Unauthorized payment access → 403 Forbidden

---

## Test Execution

### Prerequisites
1. Python 3.11+
2. FastAPI 0.115+
3. pytest with asyncio support
4. Dependencies: `pip install -r requirements.txt`

### Running Tests

**Run all integration tests:**
```bash
cd backend
pytest tests/test_payment_integration.py -v
```

**Run specific test class:**
```bash
pytest tests/test_payment_integration.py::TestCreatePayment -v
```

**Run single test:**
```bash
pytest tests/test_payment_integration.py::TestCreatePayment::test_create_payment_success -v
```

**Run with coverage:**
```bash
pytest tests/test_payment_integration.py --cov=app.finance --cov-report=html
```

### Test Configuration
- **Framework:** pytest
- **Async Mode:** AUTO (asyncio_mode = auto in pytest.ini)
- **Timeout:** 5 seconds per test (default)
- **Mocking:** unittest.mock (MagicMock, AsyncMock, patch)
- **HTTP Client:** FastAPI TestClient

---

## Coverage Goals

- **Target Coverage:** >90%
- **Coverage Breakdown:**
  - CREATE PAYMENT: 8 test cases
  - LIST PAYMENTS: 4 test cases
  - UPDATE PAYMENT: 4 test cases
  - DELETE PAYMENT: 3 test cases
  - GET HISTORY: 5 test cases

---

## Assumptions & Limitations

1. **Mocking Strategy:** All tests mock the Supabase database and validators to isolate endpoint logic
2. **Authentication:** Tests use a mock current_user fixture returning a fixed test user ID
3. **Timezone:** Tests use local date.today() for date validation
4. **Error Messages:** Error messages are in Portuguese (Brazilian Portuguese)
5. **No Database:** Tests do not connect to real database or Supabase instance

---

## Future Enhancements

1. Integration tests with real Supabase test instance
2. Load testing for concurrent payment creation
3. Edge cases: very small amounts (< 0.01), large amounts (> 1M)
4. Performance testing: response times for history with 1000+ payments
5. Data validation: unique payment date constraint testing
6. Concurrent payment updates handling
7. Transaction rollback scenarios
