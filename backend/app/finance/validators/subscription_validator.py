"""
Validators for subscription system.

This module provides validation functions for subscription operations,
following PT-BR error messaging convention and FastAPI HTTP exception patterns.

Validators:
    - validate_trial_not_expired: Check if trial period is still valid
    - validate_trial_can_extend: Check if trial extension is allowed (1x only)
    - validate_subscription_active: Check if subscription is in active status
    - validate_days_remaining: Calculate days remaining until subscription expires
    - validate_subscription_not_cancelled: Check if subscription is not cancelled
    - validate_user_subscription_exists: Check if user has a subscription
    - calculate_days_remaining: Calculate days remaining until expiration
    - is_subscription_active: Check if subscription is currently active
    - is_subscription_expired: Check if subscription is expired
"""

from datetime import datetime, timezone, timedelta, date
from fastapi import HTTPException, status
from loguru import logger
from supabase import Client
from sqlalchemy.orm import Session

from app.finance.models.subscription import UserSubscription


class SubscriptionValidationError(HTTPException):
    """Custom exception for subscription validation errors."""

    def __init__(
        self,
        detail: str,
        status_code: int = status.HTTP_400_BAD_REQUEST,
    ):
        super().__init__(status_code=status_code, detail=detail)
        logger.warning(f"SubscriptionValidationError: {detail}")


async def validate_user_subscription_exists(
    user_id: str, supabase: Client
) -> UserSubscription:
    """
    Validate that a user has a subscription.

    Args:
        user_id: The user ID to validate
        supabase: Supabase client instance

    Returns:
        UserSubscription: The user's subscription data

    Raises:
        SubscriptionValidationError: If subscription not found
    """
    try:
        resp = (
            supabase.table("user_subscriptions")
            .select("*")
            .eq("user_id", user_id)
            .single()
            .execute()
        )
        if not resp.data:
            raise SubscriptionValidationError(
                detail="Assinatura não encontrada",
                status_code=status.HTTP_404_NOT_FOUND,
            )
        return UserSubscription(**resp.data)
    except SubscriptionValidationError:
        raise
    except Exception as exc:
        logger.error(f"Erro ao validar assinatura do usuário {user_id}: {exc}")
        raise SubscriptionValidationError(
            detail="Erro ao validar assinatura",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


async def validate_trial_can_extend(
    subscription: UserSubscription,
) -> None:
    """
    Validate that a trial subscription can be extended.

    Rules:
    - Must be a trial plan
    - Must not already be extended
    - Must still be active

    Args:
        subscription: The subscription to validate

    Raises:
        SubscriptionValidationError: If validation fails
    """
    if subscription.plan != "trial":
        raise SubscriptionValidationError(
            detail="Apenas planos de trial podem ser estendidos",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    if subscription.trial_extended:
        raise SubscriptionValidationError(
            detail="Este período de trial já foi estendido",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    if subscription.status == "cancelled":
        raise SubscriptionValidationError(
            detail="Não é possível estender um trial cancelado",
            status_code=status.HTTP_400_BAD_REQUEST,
        )


def calculate_days_remaining(expires_at: datetime) -> int:
    """
    Calculate days remaining until subscription expires.

    Args:
        expires_at: Expiration datetime

    Returns:
        int: Number of days remaining (0 or greater)
    """
    now = datetime.now(timezone.utc)
    delta = expires_at - now
    days = max(0, delta.days + (1 if delta.seconds > 0 else 0))
    return days


def is_subscription_active(
    subscription: UserSubscription,
) -> bool:
    """
    Check if subscription is currently active.

    Args:
        subscription: The subscription to check

    Returns:
        bool: True if active, False otherwise
    """
    if subscription.status != "active":
        return False

    now = datetime.now(timezone.utc)
    return subscription.expires_at > now


def is_subscription_expired(
    subscription: UserSubscription,
) -> bool:
    """
    Check if subscription is expired.

    Args:
        subscription: The subscription to check

    Returns:
        bool: True if expired, False otherwise
    """
    if subscription.status == "cancelled":
        return True

    now = datetime.now(timezone.utc)
    return subscription.expires_at <= now


# ============================================================================
# REQUIRED VALIDATORS - 5 validators per specification
# ============================================================================


def validate_trial_not_expired(subscription: UserSubscription) -> bool:
    """
    Validate if trial period has not expired.

    Rules:
    - Trial expiration date must be today or in the future

    Args:
        subscription: The subscription object to validate

    Returns:
        True if trial is valid (not expired)

    Raises:
        SubscriptionValidationError: If trial has expired
    """
    today = date.today()
    expires_date = subscription.expires_at.date()

    if today > expires_date:
        raise SubscriptionValidationError(
            detail="Seu período de trial expirou",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    return True


def validate_trial_can_extend(subscription: UserSubscription) -> bool:
    """
    Validate if trial can be extended.

    Rules:
    - Trial can only be extended once (trial_extended must be False)

    Args:
        subscription: The subscription object to validate

    Returns:
        True if trial can be extended

    Raises:
        SubscriptionValidationError: If trial has already been extended
    """
    if subscription.trial_extended:
        raise SubscriptionValidationError(
            detail="Você já estendeu seu período de trial",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    return True


def validate_subscription_active(subscription: UserSubscription) -> bool:
    """
    Validate if subscription is in active status.

    Rules:
    - Subscription status must be 'active'

    Args:
        subscription: The subscription object to validate

    Returns:
        True if subscription is active

    Raises:
        SubscriptionValidationError: If subscription is not active
    """
    if subscription.status != "active":
        raise SubscriptionValidationError(
            detail="Sua assinatura não está ativa",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    return True


def validate_days_remaining(subscription: UserSubscription) -> int:
    """
    Calculate and validate days remaining until subscription expires.

    Rules:
    - Returns the difference between expires_at and today in days
    - Returns 0 if the result is negative (expired)

    Args:
        subscription: The subscription object to validate

    Returns:
        Number of days remaining (0 or positive)
    """
    today = date.today()
    expires_date = subscription.expires_at.date()

    days_remaining = (expires_date - today).days

    return max(0, days_remaining)


def validate_subscription_not_cancelled(
    user_id: str,
    db: Session,
) -> bool:
    """
    Validate if subscription is not cancelled.

    Rules:
    - Subscription status must not be 'cancelled'
    - Checks the subscription in the database

    Args:
        user_id: The user ID to check subscription for
        db: Database session

    Returns:
        True if subscription is not cancelled

    Raises:
        SubscriptionValidationError: If subscription is cancelled
    """
    try:
        subscription = (
            db.query(UserSubscription)
            .filter(UserSubscription.user_id == user_id)
            .order_by(UserSubscription.created_at.desc())
            .first()
        )

        if subscription is None:
            raise SubscriptionValidationError(
                detail="Assinatura não encontrada",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        if subscription.status == "cancelled":
            raise SubscriptionValidationError(
                detail="Assinatura cancelada",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        return True

    except SubscriptionValidationError:
        raise
    except Exception as exc:
        logger.error(f"Error validating subscription cancellation status: {exc}")
        raise SubscriptionValidationError(
            detail="Erro ao validar status da assinatura",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

