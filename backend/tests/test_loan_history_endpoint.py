"""Tests for GET /loans/{loan_id}/history endpoint."""

import pytest
from datetime import date, datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient

from app.main import app
from app.auth.dependencies import get_current_user
from app.finance.models.payment import PaymentRecord, PaymentType
from app.finance.models.simulation import LoanWithPaymentHistory


@pytest.fixture
def mock_current_user():
    """Mock current user."""
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
    """Sample loan data."""
    return {
        "id": "loan-history-001",
        "user_id": "test-user-id",
        "name": "Casa - Financiamento",
        "total_amount": 200000.00,
        "outstanding_balance": 150000.00,
        "interest_rate_year": 8.5,
        "term_months": 180,
        "insurance_monthly": 50.0,
        "start_date": "2024-01-01",
        "payment_due_date_day": 10,
        "is_active": True,
        "created_at": "2024-01-01T00:00:00Z",
    }


@pytest.fixture
def test_payments():
    """Sample payment records."""
    return [
        {
            "id": "pay-001",
            "loan_id": "loan-history-001",
            "user_id": "test-user-id",
            "payment_date": "2024-01-15",
            "amount_paid": 1500.00,
            "payment_type": "normal",
            "notes": "Regular payment",
            "created_at": "2024-01-15T10:30:00Z",
        },
        {
            "id": "pay-002",
            "loan_id": "loan-history-001",
            "user_id": "test-user-id",
            "payment_date": "2024-02-15",
            "amount_paid": 1550.00,
            "payment_type": "normal",
            "notes": "Regular payment",
            "created_at": "2024-02-15T10:30:00Z",
        },
    ]


class TestGetLoanHistory:
    """Test suite for GET /loans/{loan_id}/history endpoint."""

    @pytest.mark.asyncio
    async def test_get_loan_history_success(self, test_client, test_loan, test_payments):
        """Test successful retrieval of loan history."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.calculate_loan_with_history", new_callable=AsyncMock) as mock_calc, \
             patch("app.finance.router.log_event", new_callable=AsyncMock):
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Mock loan fetch
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
            
            # Mock payment records fetch
            mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = MagicMock(data=test_payments)
            
            # Mock calculation result
            mock_result = MagicMock(spec=LoanWithPaymentHistory)
            mock_result.loan_id = "loan-history-001"
            mock_result.loan_name = "Casa - Financiamento"
            mock_result.calculated_history = []
            mock_result.actual_history = []
            mock_result.summary = MagicMock()
            mock_calc.return_value = mock_result
            
            response = test_client.get("/loans/loan-history-001/history")
            
            assert response.status_code == 200
            
            # Verify that calculate_loan_with_history was called
            assert mock_calc.called

    @pytest.mark.asyncio
    async def test_get_loan_history_not_found(self, test_client):
        """Test 404 when loan not found."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Mock loan not found
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=None)
            
            response = test_client.get("/loans/nonexistent-loan/history")
            
            assert response.status_code == 404
            assert "Financiamento não encontrado" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_get_loan_history_no_payments(self, test_client, test_loan):
        """Test loan history with no payments made."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.calculate_loan_with_history", new_callable=AsyncMock) as mock_calc, \
             patch("app.finance.router.log_event", new_callable=AsyncMock):
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Mock loan fetch
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
            
            # Mock no payment records
            mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = MagicMock(data=None)
            
            # Mock calculation result
            mock_result = MagicMock(spec=LoanWithPaymentHistory)
            mock_result.loan_id = "loan-history-001"
            mock_result.loan_name = "Casa - Financiamento"
            mock_result.calculated_history = []
            mock_result.actual_history = []
            mock_result.summary = MagicMock()
            mock_calc.return_value = mock_result
            
            response = test_client.get("/loans/loan-history-001/history")
            
            assert response.status_code == 200
            
            # Verify that calculate_loan_with_history was called with empty payments list
            call_args = mock_calc.call_args
            assert call_args[0][1] == []  # Empty payments list

    @pytest.mark.asyncio
    async def test_get_loan_history_with_future_filter(self, test_client, test_loan, test_payments):
        """Test loan history with include_future parameter."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.calculate_loan_with_history", new_callable=AsyncMock) as mock_calc, \
             patch("app.finance.router.log_event", new_callable=AsyncMock):
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Mock loan fetch
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
            
            # Mock payment records fetch
            mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = MagicMock(data=test_payments)
            
            # Mock calculation result with future months
            mock_result = MagicMock(spec=LoanWithPaymentHistory)
            mock_result.loan_id = "loan-history-001"
            mock_result.loan_name = "Casa - Financiamento"
            mock_result.calculated_history = []
            mock_result.actual_history = []
            mock_result.summary = MagicMock()
            mock_calc.return_value = mock_result
            
            response = test_client.get("/loans/loan-history-001/history?include_future=true")
            
            assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_get_loan_history_unauthorized(self, test_client, test_loan):
        """Test 403 when user doesn't own the loan."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase:
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Mock loan not found for this user
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=None)
            
            response = test_client.get("/loans/loan-history-001/history")
            
            assert response.status_code == 404
