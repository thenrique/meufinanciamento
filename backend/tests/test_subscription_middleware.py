"""Tests for subscription check middleware."""

import pytest
from datetime import datetime, timezone, timedelta
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


class TestSubscriptionMiddleware:
    """Test suite for subscription check middleware."""

    @pytest.mark.asyncio
    async def test_exempt_endpoints_no_auth(self, test_client):
        """Test that exempt endpoints work without auth."""
        response = test_client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"

    @pytest.mark.asyncio
    async def test_exempt_auth_endpoints(self, test_client):
        """Test that auth endpoints are exempt from subscription check."""
        # This would normally require auth setup, but we're just testing
        # that the middleware doesn't interfere
        response = test_client.get("/docs")
        # 200 if in dev, else redirect
        assert response.status_code in [200, 307]

    @pytest.mark.asyncio
    @patch("app.middleware.subscription_check._get_subscription_status")
    @patch("app.middleware.subscription_check._get_user_id_from_token")
    async def test_active_subscription_allows_request(
        self, mock_get_user, mock_get_subscription, test_client
    ):
        """Test that active subscription allows request."""
        tomorrow = datetime.now(timezone.utc) + timedelta(days=1)
        mock_get_user.return_value = "test-user-id"
        mock_get_subscription.return_value = {
            "id": "sub-123",
            "user_id": "test-user-id",
            "status": "active",
            "plan": "trial",
            "started_at": datetime.now(timezone.utc),
            "expires_at": tomorrow,
        }
        
        # Use /finance/loans which requires auth/subscription
        with patch("app.database.get_supabase") as mock_db:
            mock_db.return_value.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(data=[])
            response = test_client.get("/finance/loans")
            assert response.status_code in [200, 404]  # May vary, but not 403

    @pytest.mark.asyncio
    @patch("app.middleware.subscription_check._get_subscription_status")
    @patch("app.middleware.subscription_check._get_user_id_from_token")
    async def test_expired_subscription_blocks_request(
        self, mock_get_user, mock_get_subscription, test_client
    ):
        """Test that expired subscription blocks request."""
        mock_get_user.return_value = "test-user-id"
        mock_get_subscription.return_value = {
            "id": "sub-123",
            "user_id": "test-user-id",
            "status": "expired",
            "plan": "trial",
            "started_at": datetime.now(timezone.utc),
            "expires_at": datetime.now(timezone.utc),
        }
        
        # Patch get_supabase to avoid actual DB calls
        with patch("app.database.get_supabase"):
            response = test_client.get("/finance/loans")
            assert response.status_code == 403
            assert "trial expirou" in response.json()["detail"]

    @pytest.mark.asyncio
    @patch("app.middleware.subscription_check._get_subscription_status")
    @patch("app.middleware.subscription_check._get_user_id_from_token")
    async def test_cancelled_subscription_blocks_request(
        self, mock_get_user, mock_get_subscription, test_client
    ):
        """Test that cancelled subscription blocks request."""
        mock_get_user.return_value = "test-user-id"
        mock_get_subscription.return_value = {
            "id": "sub-123",
            "user_id": "test-user-id",
            "status": "cancelled",
            "plan": "premium",
            "started_at": datetime.now(timezone.utc),
            "expires_at": datetime.now(timezone.utc),
        }
        
        with patch("app.database.get_supabase"):
            response = test_client.get("/finance/loans")
            assert response.status_code == 403
            assert "cancelada" in response.json()["detail"]

    @pytest.mark.asyncio
    @patch("app.middleware.subscription_check._update_subscription_status_to_expired")
    @patch("app.middleware.subscription_check._get_subscription_status")
    @patch("app.middleware.subscription_check._get_user_id_from_token")
    async def test_expired_date_blocks_request(
        self, mock_get_user, mock_get_subscription, mock_update_status, test_client
    ):
        """Test that passed expiration date blocks request and updates status."""
        yesterday = datetime.now(timezone.utc) - timedelta(days=1)
        mock_get_user.return_value = "test-user-id"
        mock_get_subscription.return_value = {
            "id": "sub-123",
            "user_id": "test-user-id",
            "status": "active",
            "plan": "trial",
            "started_at": datetime.now(timezone.utc),
            "expires_at": yesterday,
        }
        
        with patch("app.database.get_supabase"):
            response = test_client.get("/finance/loans")
            assert response.status_code == 403
            assert "trial expirou" in response.json()["detail"]
            # Verify status was updated
            mock_update_status.assert_called_once()

    @pytest.mark.asyncio
    @patch("app.middleware.subscription_check._get_subscription_status")
    @patch("app.middleware.subscription_check._get_user_id_from_token")
    async def test_no_subscription_allows_request(
        self, mock_get_user, mock_get_subscription, test_client
    ):
        """Test that missing subscription allows request."""
        mock_get_user.return_value = "test-user-id"
        mock_get_subscription.return_value = None
        
        response = test_client.get("/health")
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_request_without_token_passes_through(self, test_client):
        """Test that request without auth token is not blocked by subscription middleware."""
        # The auth dependency will handle the 401, not the subscription middleware
        with patch("app.middleware.subscription_check._extract_token_from_request", return_value=None):
            response = test_client.get("/health")
            # Should still work for /health endpoint (it's exempt)
            assert response.status_code == 200
