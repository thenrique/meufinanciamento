"""Integration tests for subscription endpoints."""

import pytest
from datetime import datetime, timezone, timedelta
from unittest.mock import MagicMock, patch, AsyncMock
from uuid import uuid4
from fastapi import status
from fastapi.testclient import TestClient

from app.main import app
from app.finance.models.subscription import UserSubscription, SubscriptionResponse


@pytest.fixture
def client():
    """Provide FastAPI test client."""
    return TestClient(app)


@pytest.fixture
def valid_token():
    """Provide a valid JWT token for testing."""
    return "valid_token_123"


@pytest.fixture
def user_id():
    """Provide a test user ID."""
    return str(uuid4())


@pytest.fixture
def valid_subscription(user_id):
    """Provide a valid subscription object."""
    return {
        "id": str(uuid4()),
        "user_id": user_id,
        "status": "active",
        "plan": "trial",
        "started_at": datetime.now(timezone.utc).isoformat(),
        "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
        "trial_extended": False,
        "stripe_customer_id": None,
        "cancelled_at": None,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }


@pytest.fixture
def headers(valid_token):
    """Provide authorization headers."""
    return {"Authorization": f"Bearer {valid_token}"}


class TestGetUserSubscription:
    """Tests for GET /api/user/subscription endpoint."""

    @patch("app.auth.dependencies.HTTPBearer")
    @patch("app.finance.subscription_router.get_supabase")
    @patch("app.finance.subscription_router.validate_user_subscription_exists")
    async def test_get_subscription_success(
        self, mock_validate, mock_get_supabase, mock_bearer, client, valid_token, user_id, valid_subscription, headers
    ):
        """Test successful subscription retrieval."""
        mock_bearer.return_value = MagicMock()
        
        mock_sub = UserSubscription(**valid_subscription)
        mock_validate.return_value = mock_sub
        mock_get_supabase.return_value = MagicMock()

        # Mock auth to return user_id
        with patch("app.auth.dependencies.get_current_user", return_value=user_id):
            with patch("app.finance.subscription_router.log_event", new_callable=AsyncMock):
                with patch("app.finance.subscription_router.validate_user_subscription_exists", return_value=mock_sub):
                    response = client.get("/api/user/subscription", headers=headers)

        # Should return 200 OK
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "subscription" in data
        assert "status" in data
        assert data["subscription"]["user_id"] == user_id

    @patch("app.auth.dependencies.HTTPBearer")
    async def test_get_subscription_not_found(self, mock_bearer, client, headers):
        """Test subscription not found returns 404."""
        mock_bearer.return_value = MagicMock()

        with patch("app.auth.dependencies.get_current_user", return_value="non_existent_user"):
            with patch("app.finance.subscription_router.validate_user_subscription_exists") as mock_validate:
                from fastapi import HTTPException
                mock_validate.side_effect = HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Assinatura não encontrada"
                )
                response = client.get("/api/user/subscription", headers=headers)

        assert response.status_code == status.HTTP_404_NOT_FOUND

    @patch("app.auth.dependencies.HTTPBearer")
    async def test_get_subscription_unauthorized(self, mock_bearer, client):
        """Test missing auth returns 403."""
        mock_bearer.return_value = MagicMock()

        with patch("app.auth.dependencies.get_current_user") as mock_auth:
            from fastapi import HTTPException
            mock_auth.side_effect = HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Não autenticado"
            )
            response = client.get("/api/user/subscription")

        assert response.status_code == status.HTTP_401_UNAUTHORIZED or response.status_code == status.HTTP_403_FORBIDDEN


class TestGetSubscriptionStatus:
    """Tests for GET /api/subscription/status endpoint."""

    @patch("app.auth.dependencies.HTTPBearer")
    @patch("app.finance.subscription_router.validate_user_subscription_exists")
    async def test_get_status_success(
        self, mock_validate, mock_bearer, client, valid_token, user_id, valid_subscription, headers
    ):
        """Test successful status retrieval."""
        mock_bearer.return_value = MagicMock()
        
        mock_sub = UserSubscription(**valid_subscription)
        mock_validate.return_value = mock_sub

        with patch("app.auth.dependencies.get_current_user", return_value=user_id):
            with patch("app.finance.subscription_router.log_event", new_callable=AsyncMock):
                with patch("app.finance.subscription_router.validate_user_subscription_exists", return_value=mock_sub):
                    response = client.get("/api/subscription/status", headers=headers)

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "subscription" in data
        assert "days_remaining" in data
        assert "is_active" in data
        assert "is_trial" in data
        assert "is_expired" in data

    @patch("app.auth.dependencies.HTTPBearer")
    async def test_get_status_expired_subscription(
        self, mock_bearer, client, valid_token, user_id, valid_subscription, headers
    ):
        """Test status for expired subscription."""
        mock_bearer.return_value = MagicMock()
        
        expired_sub = valid_subscription.copy()
        expired_sub["expires_at"] = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
        expired_sub["status"] = "expired"
        
        mock_sub = UserSubscription(**expired_sub)

        with patch("app.auth.dependencies.get_current_user", return_value=user_id):
            with patch("app.finance.subscription_router.log_event", new_callable=AsyncMock):
                with patch("app.finance.subscription_router.validate_user_subscription_exists", return_value=mock_sub):
                    response = client.get("/api/subscription/status", headers=headers)

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["is_expired"] is True
        assert data["is_active"] is False


class TestExtendTrial:
    """Tests for POST /api/subscription/extend-trial endpoint."""

    @patch("app.auth.dependencies.HTTPBearer")
    @patch("app.finance.subscription_router.validate_user_subscription_exists")
    @patch("app.finance.subscription_router.validate_trial_can_extend")
    @patch("app.finance.subscription_router.get_supabase")
    async def test_extend_trial_success(
        self, mock_get_supabase, mock_validate_extend, mock_validate_exists, mock_bearer,
        client, valid_token, user_id, valid_subscription, headers
    ):
        """Test successful trial extension."""
        mock_bearer.return_value = MagicMock()
        
        mock_sub = UserSubscription(**valid_subscription)
        mock_validate_exists.return_value = mock_sub
        mock_validate_extend.return_value = None
        
        # Mock Supabase update
        updated_sub = valid_subscription.copy()
        updated_sub["expires_at"] = (datetime.now(timezone.utc) + timedelta(days=14)).isoformat()
        updated_sub["trial_extended"] = True
        
        mock_supabase = MagicMock()
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[updated_sub]
        )
        mock_get_supabase.return_value = mock_supabase

        with patch("app.auth.dependencies.get_current_user", return_value=user_id):
            with patch("app.finance.subscription_router.log_event", new_callable=AsyncMock):
                response = client.post(
                    "/api/subscription/extend-trial",
                    json={"extend": True},
                    headers=headers
                )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "subscription" in data
        assert data["subscription"]["trial_extended"] is True

    @patch("app.auth.dependencies.HTTPBearer")
    @patch("app.finance.subscription_router.validate_user_subscription_exists")
    async def test_extend_trial_already_extended(
        self, mock_validate_exists, mock_bearer, client, valid_token, user_id, valid_subscription, headers
    ):
        """Test extending an already extended trial returns error."""
        mock_bearer.return_value = MagicMock()
        
        already_extended = valid_subscription.copy()
        already_extended["trial_extended"] = True
        mock_sub = UserSubscription(**already_extended)
        mock_validate_exists.return_value = mock_sub

        with patch("app.auth.dependencies.get_current_user", return_value=user_id):
            with patch("app.finance.subscription_router.validate_trial_can_extend") as mock_validate:
                from fastapi import HTTPException
                mock_validate.side_effect = HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Este período de trial já foi estendido"
                )
                response = client.post(
                    "/api/subscription/extend-trial",
                    json={"extend": True},
                    headers=headers
                )

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    @patch("app.auth.dependencies.HTTPBearer")
    @patch("app.finance.subscription_router.validate_user_subscription_exists")
    async def test_extend_trial_not_trial_plan(
        self, mock_validate_exists, mock_bearer, client, valid_token, user_id, valid_subscription, headers
    ):
        """Test extending a non-trial plan returns error."""
        mock_bearer.return_value = MagicMock()
        
        premium_sub = valid_subscription.copy()
        premium_sub["plan"] = "premium"
        mock_sub = UserSubscription(**premium_sub)
        mock_validate_exists.return_value = mock_sub

        with patch("app.auth.dependencies.get_current_user", return_value=user_id):
            with patch("app.finance.subscription_router.validate_trial_can_extend") as mock_validate:
                from fastapi import HTTPException
                mock_validate.side_effect = HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Apenas planos de trial podem ser estendidos"
                )
                response = client.post(
                    "/api/subscription/extend-trial",
                    json={"extend": True},
                    headers=headers
                )

        assert response.status_code == status.HTTP_400_BAD_REQUEST


class TestCancelSubscription:
    """Tests for DELETE /api/subscription endpoint."""

    @patch("app.auth.dependencies.HTTPBearer")
    @patch("app.finance.subscription_router.validate_user_subscription_exists")
    @patch("app.finance.subscription_router.get_supabase")
    async def test_cancel_subscription_success(
        self, mock_get_supabase, mock_validate_exists, mock_bearer,
        client, valid_token, user_id, valid_subscription, headers
    ):
        """Test successful subscription cancellation."""
        mock_bearer.return_value = MagicMock()
        
        mock_sub = UserSubscription(**valid_subscription)
        mock_validate_exists.return_value = mock_sub
        
        # Mock Supabase update
        cancelled_sub = valid_subscription.copy()
        cancelled_sub["status"] = "cancelled"
        cancelled_sub["cancelled_at"] = datetime.now(timezone.utc).isoformat()
        
        mock_supabase = MagicMock()
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[cancelled_sub]
        )
        mock_get_supabase.return_value = mock_supabase

        with patch("app.auth.dependencies.get_current_user", return_value=user_id):
            with patch("app.finance.subscription_router.log_event", new_callable=AsyncMock):
                response = client.delete("/api/subscription", headers=headers)

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "subscription" in data
        assert data["subscription"]["status"] == "cancelled"
        assert data["subscription"]["cancelled_at"] is not None

    @patch("app.auth.dependencies.HTTPBearer")
    @patch("app.finance.subscription_router.validate_user_subscription_exists")
    async def test_cancel_subscription_already_cancelled(
        self, mock_validate_exists, mock_bearer, client, valid_token, user_id, valid_subscription, headers
    ):
        """Test cancelling already cancelled subscription returns error."""
        mock_bearer.return_value = MagicMock()
        
        already_cancelled = valid_subscription.copy()
        already_cancelled["status"] = "cancelled"
        already_cancelled["cancelled_at"] = datetime.now(timezone.utc).isoformat()
        mock_sub = UserSubscription(**already_cancelled)
        mock_validate_exists.return_value = mock_sub

        with patch("app.auth.dependencies.get_current_user", return_value=user_id):
            response = client.delete("/api/subscription", headers=headers)

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        data = response.json()
        assert "Esta assinatura já foi cancelada" in data["detail"]
