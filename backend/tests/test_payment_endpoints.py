"""Tests for payment CRUD endpoints."""

import pytest
from datetime import date
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient

from app.main import app
from app.auth.dependencies import get_current_user


@pytest.fixture
def mock_current_user():
    """Mock the get_current_user dependency."""
    async def mock_user():
        return "test-user-id"
    return mock_user


@pytest.fixture
def test_client(mock_current_user):
    """FastAPI test client with mocked auth."""
    app.dependency_overrides[get_current_user] = mock_current_user
    client = TestClient(app)
    yield client
    app.dependency_overrides.clear()


class TestPaymentEndpoints:
    """Test suite for payment CRUD endpoints."""

    @pytest.mark.asyncio
    async def test_create_payment_success(self, test_client):
        """Test successful payment creation."""
        test_loan = {
            "id": "loan-123",
            "user_id": "test-user-id",
            "name": "Test Loan",
            "total_amount": 100000.00,
            "outstanding_balance": 50000.00,
            "interest_rate_year": 10.0,
            "term_months": 60,
            "insurance_monthly": 0.0,
            "created_at": "2024-01-01T00:00:00Z",
            "is_active": True,
        }
        
        test_payment = {
            "id": "payment-123",
            "loan_id": "loan-123",
            "user_id": "test-user-id",
            "payment_date": "2024-06-15",
            "amount_paid": 1500.00,
            "payment_type": "normal",
            "notes": "Regular payment",
            "created_at": "2024-06-15T10:30:00Z",
        }
        
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.log_event", new_callable=AsyncMock):
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Mock loan ownership validation
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
            
            # Mock no existing payments
            mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(data=None)
            
            # Mock payment insert
            mock_supabase.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[test_payment])
            
            payload = {
                "loan_id": "loan-123",
                "payment_date": "2024-06-15",
                "amount_paid": 1500.00,
                "payment_type": "normal",
                "notes": "Regular payment",
            }
            
            response = test_client.post(
                "/loans/loan-123/payments",
                json=payload,
            )
            
            assert response.status_code == 201
            data = response.json()
            assert data["id"] == "payment-123"
            assert data["loan_id"] == "loan-123"
            assert data["amount_paid"] == 1500.00

    @pytest.mark.asyncio
    async def test_create_payment_loan_not_found(self, test_client):
        """Test creating payment for non-existent loan returns 403."""
        with patch("app.finance.router.get_supabase") as mock_get_supabase:
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Mock loan not found
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=None)
            
            payload = {
                "loan_id": "loan-999",
                "payment_date": "2024-06-15",
                "amount_paid": 1500.00,
                "payment_type": "normal",
            }
            
            response = test_client.post(
                "/loans/loan-999/payments",
                json=payload,
            )
            
            assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_list_payments_success(self, test_client):
        """Test successful payment listing."""
        test_loan = {
            "id": "loan-123",
            "user_id": "test-user-id",
            "name": "Test Loan",
            "total_amount": 100000.00,
            "outstanding_balance": 50000.00,
            "interest_rate_year": 10.0,
            "term_months": 60,
            "insurance_monthly": 0.0,
            "created_at": "2024-01-01T00:00:00Z",
            "is_active": True,
        }
        
        test_payment = {
            "id": "payment-123",
            "loan_id": "loan-123",
            "user_id": "test-user-id",
            "payment_date": "2024-06-15",
            "amount_paid": 1500.00,
            "payment_type": "normal",
            "notes": "Regular payment",
            "created_at": "2024-06-15T10:30:00Z",
        }
        
        with patch("app.finance.router.get_supabase") as mock_get_supabase:
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Mock loan ownership validation
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
            
            # Mock payment list
            mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = MagicMock(data=[test_payment])
            
            response = test_client.get(
                "/loans/loan-123/payments",
            )
            
            assert response.status_code == 200
            data = response.json()
            assert len(data) == 1
            assert data[0]["id"] == "payment-123"

    @pytest.mark.asyncio
    async def test_list_payments_with_date_filter(self, test_client):
        """Test payment listing with date filters."""
        test_loan = {
            "id": "loan-123",
            "user_id": "test-user-id",
            "name": "Test Loan",
            "total_amount": 100000.00,
            "outstanding_balance": 50000.00,
            "interest_rate_year": 10.0,
            "term_months": 60,
            "insurance_monthly": 0.0,
            "created_at": "2024-01-01T00:00:00Z",
            "is_active": True,
        }
        
        test_payment = {
            "id": "payment-123",
            "loan_id": "loan-123",
            "user_id": "test-user-id",
            "payment_date": "2024-06-15",
            "amount_paid": 1500.00,
            "payment_type": "normal",
            "notes": "Regular payment",
            "created_at": "2024-06-15T10:30:00Z",
        }
        
        with patch("app.finance.router.get_supabase") as mock_get_supabase:
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Mock loan ownership validation
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
            
            # Mock payment list
            mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = MagicMock(data=[test_payment])
            
            response = test_client.get(
                "/loans/loan-123/payments?start_date=2024-06-01&end_date=2024-06-30",
            )
            
            assert response.status_code == 200
            data = response.json()
            assert len(data) == 1

    @pytest.mark.asyncio
    async def test_update_payment_success(self, test_client):
        """Test successful payment update."""
        test_loan = {
            "id": "loan-123",
            "user_id": "test-user-id",
            "name": "Test Loan",
            "total_amount": 100000.00,
            "outstanding_balance": 50000.00,
            "interest_rate_year": 10.0,
            "term_months": 60,
            "insurance_monthly": 0.0,
            "created_at": "2024-01-01T00:00:00Z",
            "is_active": True,
        }
        
        test_payment = {
            "id": "payment-123",
            "loan_id": "loan-123",
            "user_id": "test-user-id",
            "payment_date": "2024-06-15",
            "amount_paid": 1500.00,
            "payment_type": "normal",
            "notes": "Regular payment",
            "created_at": "2024-06-15T10:30:00Z",
        }
        
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.log_event", new_callable=AsyncMock):
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Create a side effect function to handle different table calls
            def table_side_effect(table_name):
                mock_table = MagicMock()
                if table_name == "loans":
                    # For loans table
                    mock_table.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
                elif table_name == "payments":
                    # For payments table
                    mock_select_chain = MagicMock()
                    # First call: find payment by id and loan_id
                    mock_select_chain.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_payment)
                    # Second call: list all payments for loan
                    mock_select_chain.eq.return_value.execute.return_value = MagicMock(data=[])
                    # Update call
                    mock_table.update.return_value.eq.return_value.execute.return_value = MagicMock(data=[{**test_payment, "amount_paid": 1600.00}])
                    mock_table.select.return_value = mock_select_chain
                return mock_table
            
            mock_supabase.table.side_effect = table_side_effect
            
            payload = {
                "amount_paid": 1600.00,
            }
            
            response = test_client.put(
                "/loans/loan-123/payments/payment-123",
                json=payload,
            )
            
            assert response.status_code == 200
            data = response.json()
            assert data["amount_paid"] == 1600.00

    @pytest.mark.asyncio
    async def test_update_payment_not_found(self, test_client):
        """Test updating non-existent payment returns 404."""
        test_loan = {
            "id": "loan-123",
            "user_id": "test-user-id",
            "name": "Test Loan",
            "total_amount": 100000.00,
            "outstanding_balance": 50000.00,
            "interest_rate_year": 10.0,
            "term_months": 60,
            "insurance_monthly": 0.0,
            "created_at": "2024-01-01T00:00:00Z",
            "is_active": True,
        }
        
        with patch("app.finance.router.get_supabase") as mock_get_supabase:
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            def table_side_effect(table_name):
                mock_table = MagicMock()
                if table_name == "loans":
                    # For loans table
                    mock_table.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
                elif table_name == "payments":
                    # For payments table - payment not found
                    mock_table.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=None)
                return mock_table
            
            mock_supabase.table.side_effect = table_side_effect
            
            payload = {
                "amount_paid": 1600.00,
            }
            
            response = test_client.put(
                "/loans/loan-123/payments/payment-999",
                json=payload,
            )
            
            assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_payment_success(self, test_client):
        """Test successful payment deletion."""
        test_loan = {
            "id": "loan-123",
            "user_id": "test-user-id",
            "name": "Test Loan",
            "total_amount": 100000.00,
            "outstanding_balance": 50000.00,
            "interest_rate_year": 10.0,
            "term_months": 60,
            "insurance_monthly": 0.0,
            "created_at": "2024-01-01T00:00:00Z",
            "is_active": True,
        }
        
        test_payment = {
            "id": "payment-123",
            "loan_id": "loan-123",
            "user_id": "test-user-id",
            "payment_date": "2024-06-15",
            "amount_paid": 1500.00,
            "payment_type": "normal",
            "notes": "Regular payment",
            "created_at": "2024-06-15T10:30:00Z",
        }
        
        with patch("app.finance.router.get_supabase") as mock_get_supabase, \
             patch("app.finance.router.log_event", new_callable=AsyncMock):
            
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Mock loan ownership validation
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
            
            # Mock payment exists
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(data=[test_payment])
            
            response = test_client.delete(
                "/loans/loan-123/payments/payment-123",
            )
            
            assert response.status_code == 204

    @pytest.mark.asyncio
    async def test_delete_payment_not_found(self, test_client):
        """Test deleting non-existent payment returns 404."""
        test_loan = {
            "id": "loan-123",
            "user_id": "test-user-id",
            "name": "Test Loan",
            "total_amount": 100000.00,
            "outstanding_balance": 50000.00,
            "interest_rate_year": 10.0,
            "term_months": 60,
            "insurance_monthly": 0.0,
            "created_at": "2024-01-01T00:00:00Z",
            "is_active": True,
        }
        
        with patch("app.finance.router.get_supabase") as mock_get_supabase:
            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase
            
            # Mock loan found
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=test_loan)
            
            # Mock payment not found
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(data=None)
            
            response = test_client.delete(
                "/loans/loan-123/payments/payment-999",
            )
            
            assert response.status_code == 404
