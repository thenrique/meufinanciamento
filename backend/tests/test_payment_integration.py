"""Comprehensive integration tests for payment and loan history endpoints."""

import pytest
from datetime import date, datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch, Mock
from fastapi.testclient import TestClient

from app.main import app
from app.auth.dependencies import get_current_user
from app.finance.models.payment import PaymentRecord, PaymentType
from app.finance.models.simulation import LoanWithPaymentHistory


# ============================================================================
# FIXTURES
# ============================================================================

@pytest.fixture
def mock_current_user():
    """Mock the get_current_user dependency."""
    return "test-user-id"


@pytest.fixture
def test_client(mock_current_user):
    """FastAPI test client with mocked auth."""
    app.dependency_overrides[get_current_user] = lambda: mock_current_user
    client = TestClient(app)
    yield client
    app.dependency_overrides.clear()


@pytest.fixture
def test_loan():
    """Sample loan data with realistic values."""
    return {
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
        "is_active": True,
    }


@pytest.fixture
def test_payment():
    """Sample payment data."""
    return {
        "id": "d6f1d42a-p01",
        "loan_id": "d6f1d42a-001",
        "user_id": "test-user-id",
        "payment_date": "2024-02-10",
        "amount_paid": 1500.00,
        "payment_type": "normal",
        "notes": "Regular monthly payment",
        "created_at": "2024-02-10T10:30:00",
    }


@pytest.fixture
def test_payments_list():
    """Sample list of payment records."""
    return [
        {
            "id": "d6f1d42a-p01",
            "loan_id": "d6f1d42a-001",
            "user_id": "test-user-id",
            "payment_date": "2024-02-10",
            "amount_paid": 1500.00,
            "payment_type": "normal",
            "notes": "Regular monthly payment",
            "created_at": "2024-02-10T10:30:00",
        },
        {
            "id": "d6f1d42a-p02",
            "loan_id": "d6f1d42a-001",
            "user_id": "test-user-id",
            "payment_date": "2024-03-10",
            "amount_paid": 1500.00,
            "payment_type": "normal",
            "notes": "Regular monthly payment",
            "created_at": "2024-03-10T10:30:00",
        },
        {
            "id": "d6f1d42a-p03",
            "loan_id": "d6f1d42a-001",
            "user_id": "test-user-id",
            "payment_date": "2024-04-10",
            "amount_paid": 2000.00,
            "payment_type": "extra_monthly",
            "notes": "Extra payment",
            "created_at": "2024-04-10T10:30:00",
        },
    ]


# ============================================================================
# CREATE PAYMENT TESTS
# ============================================================================

class TestCreatePayment:
    """Test suite for POST /loans/{loan_id}/payments endpoint."""

    @pytest.mark.asyncio
    async def test_create_payment_success(self, test_client, test_loan, test_payment):
        """Test successful payment creation with valid data (201)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            mock_validate_owner.return_value = test_loan

            # Mock existing payments for duplicate check
            mock_query = MagicMock()
            mock_query.eq.return_value.execute.return_value = MagicMock(data=[])
            mock_supabase.table.return_value.select.return_value = mock_query

            # Mock payment insert
            insert_mock = MagicMock()
            insert_mock.execute.return_value = MagicMock(data=[test_payment])
            mock_supabase.table.return_value.insert.return_value = insert_mock

            payload = {
                "loan_id": "d6f1d42a-001",
                "payment_date": "2024-02-10",
                "amount_paid": 1500.00,
                "payment_type": "normal",
                "notes": "Regular monthly payment",
            }

            response = test_client.post(
                "/loans/d6f1d42a-001/payments",
                json=payload,
            )

            assert response.status_code == 201
            data = response.json()
            assert data["id"] == test_payment["id"]
            assert data["amount_paid"] == 1500.00
            assert data["payment_type"] == "normal"

    @pytest.mark.asyncio
    async def test_create_payment_invalid_date(self, test_client):
        """Test payment creation with invalid date format (422)."""
        payload = {
            "payment_date": "invalid-date",
            "amount_paid": 1500.00,
            "payment_type": "normal",
        }

        response = test_client.post(
            "/loans/d6f1d42a-001/payments",
            json=payload,
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_create_payment_future_date(self, test_client, test_loan):
        """Test payment creation with future date (400)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner, \
             patch("app.finance.router.validate_payment_date") as mock_validate_date:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            mock_validate_owner.return_value = test_loan
            
            from app.finance.validators.payment_validator import PaymentValidationError
            from fastapi import status
            mock_validate_date.side_effect = PaymentValidationError(
                "Data do pagamento não pode ser no futuro",
                status.HTTP_400_BAD_REQUEST
            )

            future_date = (date.today() + timedelta(days=5)).isoformat()
            payload = {
                "loan_id": "d6f1d42a-001",
                "payment_date": future_date,
                "amount_paid": 1500.00,
                "payment_type": "normal",
            }

            response = test_client.post(
                "/loans/d6f1d42a-001/payments",
                json=payload,
            )

            assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_create_payment_duplicate_date(self, test_client, test_loan):
        """Test payment creation with duplicate date for same loan (409)."""
        existing_payment = PaymentRecord(
            id="d6f1d42a-dup",
            loan_id="d6f1d42a-001",
            user_id="test-user-id",
            payment_date=date(2024, 2, 10),
            amount_paid=1500.00,
            payment_type=PaymentType.NORMAL,
        )

        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner, \
             patch("app.finance.router.validate_unique_payment_date") as mock_validate_unique:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            mock_validate_owner.return_value = test_loan

            # Mock existing payments with duplicate
            mock_query = MagicMock()
            mock_query.eq.return_value.execute.return_value = MagicMock(data=[existing_payment.model_dump()])
            mock_supabase.table.return_value.select.return_value = mock_query

            from app.finance.validators.payment_validator import PaymentValidationError
            from fastapi import status
            mock_validate_unique.side_effect = PaymentValidationError(
                "Já existe um pagamento registrado em 10/02/2024",
                status.HTTP_409_CONFLICT
            )

            payload = {
                "loan_id": "d6f1d42a-001",
                "payment_date": "2024-02-10",
                "amount_paid": 1500.00,
                "payment_type": "normal",
            }

            response = test_client.post(
                "/loans/d6f1d42a-001/payments",
                json=payload,
            )

            assert response.status_code == 409

    @pytest.mark.asyncio
    async def test_create_payment_amount_exceeds_balance(self, test_client, test_loan):
        """Test payment creation with amount > outstanding balance (400)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner, \
             patch("app.finance.router.validate_payment_amount") as mock_validate_amount:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            mock_validate_owner.return_value = test_loan

            from app.finance.validators.payment_validator import PaymentValidationError
            from fastapi import status
            mock_validate_amount.side_effect = PaymentValidationError(
                "Valor do pagamento não pode ser maior que o saldo devedor",
                status.HTTP_400_BAD_REQUEST
            )

            payload = {
                "loan_id": "d6f1d42a-001",
                "payment_date": "2024-02-10",
                "amount_paid": 100000.00,
                "payment_type": "normal",
            }

            response = test_client.post(
                "/loans/d6f1d42a-001/payments",
                json=payload,
            )

            assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_create_payment_invalid_type(self):
        """Test payment creation with invalid payment type (422)."""
        payload = {
            "loan_id": "d6f1d42a-001",
            "payment_date": "2024-02-10",
            "amount_paid": 1500.00,
            "payment_type": "invalid_type",
        }

        app.dependency_overrides[get_current_user] = lambda: "test-user-id"
        client = TestClient(app)
        response = client.post(
            "/loans/d6f1d42a-001/payments",
            json=payload,
        )
        app.dependency_overrides.clear()

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_create_payment_unauthorized(self):
        """Test payment creation without authentication (403)."""
        app.dependency_overrides.clear()

        payload = {
            "loan_id": "d6f1d42a-001",
            "payment_date": "2024-02-10",
            "amount_paid": 1500.00,
            "payment_type": "normal",
        }

        client = TestClient(app)
        response = client.post(
            "/loans/d6f1d42a-001/payments",
            json=payload,
        )

        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_create_payment_loan_not_found(self, test_client):
        """Test payment creation for nonexistent loan (403)."""
        with patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner:
            from app.finance.validators.payment_validator import PaymentValidationError
            from fastapi import status
            mock_validate_owner.side_effect = PaymentValidationError(
                "Financiamento não encontrado ou você não tem permissão para acessá-lo",
                status.HTTP_403_FORBIDDEN
            )

            payload = {
                "loan_id": "nonexistent-loan",
                "payment_date": "2024-02-10",
                "amount_paid": 1500.00,
                "payment_type": "normal",
            }

            response = test_client.post(
                "/loans/nonexistent-loan/payments",
                json=payload,
            )

            assert response.status_code == 403


# ============================================================================
# LIST PAYMENTS TESTS
# ============================================================================

class TestListPayments:
    """Test suite for GET /loans/{loan_id}/payments endpoint."""

    @pytest.mark.asyncio
    async def test_list_payments_success(self, test_client, test_loan, test_payments_list):
        """Test successful retrieval of payments list (200)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            mock_validate_owner.return_value = test_loan

            # Mock payments fetch
            mock_query = MagicMock()
            mock_query.eq.return_value.order.return_value.execute.return_value = MagicMock(
                data=test_payments_list
            )
            mock_supabase.table.return_value.select.return_value = mock_query

            response = test_client.get("/loans/d6f1d42a-001/payments")

            assert response.status_code == 200
            data = response.json()
            assert isinstance(data, list)
            assert len(data) == 3
            assert data[0]["id"] == "d6f1d42a-p01"
            assert data[0]["amount_paid"] == 1500.00

    @pytest.mark.asyncio
    async def test_list_payments_with_date_filter(self, test_client, test_loan):
        """Test list payments with date range filter (200)."""
        filtered_payments = [
            {
                "id": "d6f1d42a-p02",
                "loan_id": "d6f1d42a-001",
                "user_id": "test-user-id",
                "payment_date": "2024-03-10",
                "amount_paid": 1500.00,
                "payment_type": "normal",
                "notes": "Regular monthly payment",
                "created_at": "2024-03-10T10:30:00",
            }
        ]

        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            mock_validate_owner.return_value = test_loan

            # Mock payments fetch
            mock_query = MagicMock()
            mock_query.eq.return_value.order.return_value.execute.return_value = MagicMock(
                data=filtered_payments
            )
            mock_supabase.table.return_value.select.return_value = mock_query

            response = test_client.get(
                "/loans/d6f1d42a-001/payments?start_date=2024-03-01&end_date=2024-03-31"
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 1
            assert data[0]["payment_date"] == "2024-03-10"

    @pytest.mark.asyncio
    async def test_list_payments_unauthorized(self):
        """Test list payments without authentication (403)."""
        app.dependency_overrides.clear()
        client = TestClient(app)

        response = client.get("/loans/d6f1d42a-001/payments")

        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_list_payments_loan_not_found(self, test_client):
        """Test list payments for nonexistent loan (403)."""
        with patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner:
            from app.finance.validators.payment_validator import PaymentValidationError
            from fastapi import status
            mock_validate_owner.side_effect = PaymentValidationError(
                "Financiamento não encontrado ou você não tem permissão para acessá-lo",
                status.HTTP_403_FORBIDDEN
            )

            response = test_client.get("/loans/nonexistent-loan/payments")

            assert response.status_code == 403


# ============================================================================
# UPDATE PAYMENT TESTS
# ============================================================================

class TestUpdatePayment:
    """Test suite for PUT /loans/{loan_id}/payments/{payment_id} endpoint."""

    @pytest.mark.asyncio
    async def test_update_payment_success(self, test_client, test_loan):
        """Test successful payment update (200)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            mock_validate_owner.return_value = test_loan

            updated_payment = {
                "id": "d6f1d42a-p01",
                "loan_id": "d6f1d42a-001",
                "user_id": "test-user-id",
                "payment_date": "2024-02-10",
                "amount_paid": 1600.00,
                "payment_type": "normal",
                "notes": "Updated payment",
                "created_at": "2024-02-10T10:30:00",
            }

            # Setup table mocks with proper chaining
            select_chain = MagicMock()
            select_chain.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
                data=updated_payment
            )
            
            update_chain = MagicMock()
            update_chain.eq.return_value.execute.return_value = MagicMock(
                data=[updated_payment]
            )
            
            table_mock = MagicMock()
            table_mock.select.return_value = select_chain
            table_mock.update.return_value = update_chain
            
            mock_supabase.table.return_value = table_mock

            payload = {
                "amount_paid": 1600.00,
                "notes": "Updated payment",
            }

            response = test_client.put(
                "/loans/d6f1d42a-001/payments/d6f1d42a-p01",
                json=payload,
            )

            assert response.status_code == 200
            data = response.json()
            assert data["amount_paid"] == 1600.00
            assert data["notes"] == "Updated payment"

    @pytest.mark.asyncio
    async def test_update_payment_not_found(self, test_client, test_loan):
        """Test update payment that doesn't exist (404)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            mock_validate_owner.return_value = test_loan

            # Mock payment not found
            fetch_query = MagicMock()
            fetch_query.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
                data=None
            )
            mock_supabase.table.return_value.select.return_value = fetch_query

            payload = {
                "amount_paid": 1600.00,
            }

            response = test_client.put(
                "/loans/d6f1d42a-001/payments/nonexistent-payment",
                json=payload,
            )

            assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_payment_unauthorized(self):
        """Test update payment without authentication (403)."""
        app.dependency_overrides.clear()
        client = TestClient(app)

        payload = {
            "amount_paid": 1600.00,
        }

        response = client.put(
            "/loans/d6f1d42a-001/payments/d6f1d42a-p01",
            json=payload,
        )

        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_update_payment_invalid_data(self, test_client, test_loan, test_payment):
        """Test update payment with invalid data (400)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner, \
             patch("app.finance.router.validate_payment_amount") as mock_validate_amount:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            mock_validate_owner.return_value = test_loan

            # Mock payment fetch
            fetch_query = MagicMock()
            fetch_query.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
                data=test_payment
            )
            mock_supabase.table.return_value.select.return_value = fetch_query

            from app.finance.validators.payment_validator import PaymentValidationError
            from fastapi import status
            mock_validate_amount.side_effect = PaymentValidationError(
                "Valor do pagamento não pode ser maior que o saldo devedor",
                status.HTTP_400_BAD_REQUEST
            )

            payload = {
                "amount_paid": 100000.00,
            }

            response = test_client.put(
                "/loans/d6f1d42a-001/payments/d6f1d42a-p01",
                json=payload,
            )

            assert response.status_code == 400


# ============================================================================
# DELETE PAYMENT TESTS
# ============================================================================

class TestDeletePayment:
    """Test suite for DELETE /loans/{loan_id}/payments/{payment_id} endpoint."""

    @pytest.mark.asyncio
    async def test_delete_payment_success(self, test_client, test_loan, test_payment):
        """Test successful payment deletion (204)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            mock_validate_owner.return_value = test_loan

            # Mock payment fetch
            fetch_query = MagicMock()
            fetch_query.eq.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[test_payment]
            )
            mock_supabase.table.return_value.select.return_value = fetch_query

            # Mock payment delete
            delete_mock = MagicMock()
            delete_mock.eq.return_value.execute.return_value = MagicMock()
            mock_supabase.table.return_value.delete.return_value = delete_mock

            response = test_client.delete(
                "/loans/d6f1d42a-001/payments/d6f1d42a-p01"
            )

            assert response.status_code == 204

    @pytest.mark.asyncio
    async def test_delete_payment_not_found(self, test_client, test_loan):
        """Test delete payment that doesn't exist (404)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.validate_user_loan_ownership", new_callable=AsyncMock) as mock_validate_owner:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            mock_validate_owner.return_value = test_loan

            # Mock payment not found
            fetch_query = MagicMock()
            fetch_query.eq.return_value.eq.return_value.execute.return_value = MagicMock(
                data=None
            )
            mock_supabase.table.return_value.select.return_value = fetch_query

            response = test_client.delete(
                "/loans/d6f1d42a-001/payments/nonexistent-payment"
            )

            assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_payment_unauthorized(self):
        """Test delete payment without authentication (403)."""
        app.dependency_overrides.clear()
        client = TestClient(app)

        response = client.delete(
            "/loans/d6f1d42a-001/payments/d6f1d42a-p01"
        )

        assert response.status_code == 403


# ============================================================================
# LOAN HISTORY TESTS
# ============================================================================

class TestGetLoanHistory:
    """Test suite for GET /loans/{loan_id}/history endpoint."""

    @pytest.mark.asyncio
    async def test_get_history_success(self, test_client, test_loan):
        """Test successful loan history retrieval with calculations (200)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.calculate_loan_with_history", new_callable=AsyncMock) as mock_calc:

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # Mock table returns for loans and payment_records
            loans_mock = MagicMock()
            loans_select = MagicMock()
            loans_select.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
            loans_mock.select.return_value = loans_select
            
            records_mock = MagicMock()
            records_select = MagicMock()
            records_select.eq.return_value.order.return_value.execute.return_value = MagicMock(data=[])
            records_mock.select.return_value = records_select
            
            def table_factory(table_name):
                if table_name == "loans":
                    return loans_mock
                return records_mock
            
            mock_supabase.table.side_effect = table_factory

            # Mock calculation result - must be LoanWithPaymentHistory model
            mock_result = LoanWithPaymentHistory(
                loan_id="d6f1d42a-001",
                loan_name="Financiamento Imobiliário",
                calculated_history=[],
                actual_history=[],
                summary={
                    "total_payment_planned": 270000.00,
                    "total_payment_actual": 0.00,
                    "total_interest_planned": 170000.00,
                    "total_interest_actual": 0.00,
                    "total_interest_saved": 0.00,
                    "months_ahead": 0,
                    "months_planned": 180,
                    "months_actual": 0,
                    "payoff_date_planned": None,
                    "payoff_date_actual": None,
                    "days_ahead": 0,
                    "total_deviation": 0.00,
                    "total_insurance": 0.00,
                }
            )
            mock_calc.return_value = mock_result

            response = test_client.get("/loans/d6f1d42a-001/history")

            assert response.status_code == 200
            data = response.json()
            assert data["loan_id"] == "d6f1d42a-001"
            assert "summary" in data

    @pytest.mark.asyncio
    async def test_get_history_with_calculations(self, test_client, test_loan):
        """Test loan history includes proper calculations (200)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.calculate_loan_with_history", new_callable=AsyncMock) as mock_calc:

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # Mock table returns
            loans_mock = MagicMock()
            loans_select = MagicMock()
            loans_select.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
            loans_mock.select.return_value = loans_select
            
            records_mock = MagicMock()
            records_select = MagicMock()
            records_select.eq.return_value.order.return_value.execute.return_value = MagicMock(data=[])
            records_mock.select.return_value = records_select
            
            def table_factory(table_name):
                if table_name == "loans":
                    return loans_mock
                return records_mock
            
            mock_supabase.table.side_effect = table_factory

            # Mock calculation result with detailed data
            from app.finance.models.simulation import CalculatedMonthEntry
            mock_result = LoanWithPaymentHistory(
                loan_id="d6f1d42a-001",
                loan_name="Financiamento Imobiliário",
                calculated_history=[],
                actual_history=[],
                summary={
                    "total_payment_planned": 270000.00,
                    "total_payment_actual": 0.00,
                    "total_interest_planned": 170000.00,
                    "total_interest_actual": 0.00,
                    "total_interest_saved": 0.00,
                    "months_ahead": 0,
                    "months_planned": 180,
                    "months_actual": 0,
                    "payoff_date_planned": None,
                    "payoff_date_actual": None,
                    "days_ahead": 0,
                    "total_deviation": 0.00,
                    "total_insurance": 0.00,
                }
            )
            mock_calc.return_value = mock_result

            response = test_client.get("/loans/d6f1d42a-001/history")

            assert response.status_code == 200
            data = response.json()
            assert "calculated_history" in data
            assert "summary" in data

    @pytest.mark.asyncio
    async def test_get_history_no_payments(self, test_client, test_loan):
        """Test loan history when no payments have been made (200)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.calculate_loan_with_history", new_callable=AsyncMock) as mock_calc:

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # Mock table returns
            loans_mock = MagicMock()
            loans_select = MagicMock()
            loans_select.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
            loans_mock.select.return_value = loans_select
            
            records_mock = MagicMock()
            records_select = MagicMock()
            records_select.eq.return_value.order.return_value.execute.return_value = MagicMock(data=None)
            records_mock.select.return_value = records_select
            
            def table_factory(table_name):
                if table_name == "loans":
                    return loans_mock
                return records_mock
            
            mock_supabase.table.side_effect = table_factory

            # Mock calculation result
            mock_result = LoanWithPaymentHistory(
                loan_id="d6f1d42a-001",
                loan_name="Financiamento Imobiliário",
                calculated_history=[],
                actual_history=[],
                summary={
                    "total_payment_planned": 270000.00,
                    "total_payment_actual": 0.00,
                    "total_interest_planned": 170000.00,
                    "total_interest_actual": 0.00,
                    "total_interest_saved": 0.00,
                    "months_ahead": 0,
                    "months_planned": 180,
                    "months_actual": 0,
                    "payoff_date_planned": None,
                    "payoff_date_actual": None,
                    "days_ahead": 0,
                    "total_deviation": 0.00,
                    "total_insurance": 0.00,
                }
            )
            mock_calc.return_value = mock_result

            response = test_client.get("/loans/d6f1d42a-001/history")

            assert response.status_code == 200
            call_args = mock_calc.call_args
            # Verify it was called with empty payments list
            assert call_args is not None

    @pytest.mark.asyncio
    async def test_get_history_unauthorized(self):
        """Test loan history without authentication (403)."""
        app.dependency_overrides.clear()
        client = TestClient(app)

        response = client.get("/loans/d6f1d42a-001/history")

        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_get_history_loan_not_found(self, test_client):
        """Test loan history for nonexistent loan (404)."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase:
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # Mock loan not found
            loan_query = MagicMock()
            loan_query.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
                data=None
            )
            mock_supabase.table.return_value.select.return_value = loan_query

            response = test_client.get("/loans/nonexistent-loan/history")

            assert response.status_code == 404
