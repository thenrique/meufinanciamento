"""Subscription system models for user billing and trial management."""
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class UserSubscription(BaseModel):
    """
    Registro de assinatura de um usuário.

    Fields:
        id: Identificador único da assinatura (UUID)
        user_id: ID do usuário que possui a assinatura (UUID)
        status: Status da assinatura (active/expired/cancelled)
        plan: Plano da assinatura (trial/premium)
        started_at: Data e hora de início da assinatura
        expires_at: Data e hora de expiração da assinatura
        trial_extended: Indicador se o período de trial foi estendido
        stripe_customer_id: ID do cliente no Stripe (opcional)
        cancelled_at: Data e hora do cancelamento (opcional)
        created_at: Data e hora de criação do registro em UTC
        updated_at: Data e hora da última atualização em UTC
    """

    id: UUID = Field(..., description="Identificador único da assinatura")
    user_id: UUID = Field(..., description="ID do usuário que possui a assinatura")
    status: str = Field(
        ...,
        description="Status da assinatura (active/expired/cancelled)",
        pattern="^(active|expired|cancelled)$",
    )
    plan: str = Field(
        ..., description="Plano da assinatura (trial/premium)", pattern="^(trial|premium)$"
    )
    started_at: datetime = Field(..., description="Data e hora de início da assinatura")
    expires_at: datetime = Field(..., description="Data e hora de expiração da assinatura")
    trial_extended: bool = Field(
        False, description="Indicador se o período de trial foi estendido"
    )
    mercado_pago_customer_id: Optional[str] = Field(
        None, description="ID do cliente no Stripe"
    )
    cancelled_at: Optional[datetime] = Field(
        None, description="Data e hora do cancelamento"
    )
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="Data e hora de criação em UTC",
    )
    updated_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="Data e hora da última atualização em UTC",
    )

    class Config:
        json_schema_extra = {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "user_id": "660e8400-e29b-41d4-a716-446655440000",
                "status": "active",
                "plan": "premium",
                "started_at": "2024-01-01T10:00:00+00:00",
                "expires_at": "2025-01-01T10:00:00+00:00",
                "trial_extended": False,
                "stripe_customer_id": "cus_1234567890abcdef",
                "cancelled_at": None,
                "created_at": "2024-01-01T10:00:00+00:00",
                "updated_at": "2024-01-01T10:00:00+00:00",
            }
        }


class SubscriptionStatus(BaseModel):
    """
    Informações de status atual de uma assinatura.

    Fields:
        subscription: Dados completos da assinatura
        days_remaining: Quantidade de dias até a expiração
        is_trial: Indicador se é um plano de trial
        is_active: Indicador se a assinatura está ativa
        is_expired: Indicador se a assinatura expirou
    """

    subscription: UserSubscription = Field(..., description="Dados completos da assinatura")
    days_remaining: int = Field(
        ..., ge=0, description="Quantidade de dias até a expiração"
    )
    is_trial: bool = Field(..., description="Indicador se é um plano de trial")
    is_active: bool = Field(..., description="Indicador se a assinatura está ativa")
    is_expired: bool = Field(..., description="Indicador se a assinatura expirou")

    class Config:
        json_schema_extra = {
            "example": {
                "subscription": {
                    "id": "550e8400-e29b-41d4-a716-446655440000",
                    "user_id": "660e8400-e29b-41d4-a716-446655440000",
                    "status": "active",
                    "plan": "premium",
                    "started_at": "2024-01-01T10:00:00+00:00",
                    "expires_at": "2025-01-01T10:00:00+00:00",
                    "trial_extended": False,
                    "stripe_customer_id": "cus_1234567890abcdef",
                    "cancelled_at": None,
                    "created_at": "2024-01-01T10:00:00+00:00",
                    "updated_at": "2024-01-01T10:00:00+00:00",
                },
                "days_remaining": 365,
                "is_trial": False,
                "is_active": True,
                "is_expired": False,
            }
        }


class TrialExtendRequest(BaseModel):
    """
    Requisição para estender o período de trial.

    Fields:
        extend: Indicador para estender o trial (padrão: True)
    """

    extend: bool = Field(
        True,
        description="Indicador para estender o período de trial",
    )

    class Config:
        json_schema_extra = {
            "example": {
                "extend": True,
            }
        }


class SubscriptionResponse(BaseModel):
    """
    Resposta contendo dados completos da assinatura e seu status.

    Fields:
        subscription: Dados completos da assinatura
        status: Informações de status atual da assinatura
    """

    subscription: UserSubscription = Field(..., description="Dados completos da assinatura")
    status: SubscriptionStatus = Field(
        ..., description="Informações de status atual da assinatura"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "subscription": {
                    "id": "550e8400-e29b-41d4-a716-446655440000",
                    "user_id": "660e8400-e29b-41d4-a716-446655440000",
                    "status": "active",
                    "plan": "premium",
                    "started_at": "2024-01-01T10:00:00+00:00",
                    "expires_at": "2025-01-01T10:00:00+00:00",
                    "trial_extended": False,
                    "stripe_customer_id": "cus_1234567890abcdef",
                    "cancelled_at": None,
                    "created_at": "2024-01-01T10:00:00+00:00",
                    "updated_at": "2024-01-01T10:00:00+00:00",
                },
                "status": {
                    "subscription": {
                        "id": "550e8400-e29b-41d4-a716-446655440000",
                        "user_id": "660e8400-e29b-41d4-a716-446655440000",
                        "status": "active",
                        "plan": "premium",
                        "started_at": "2024-01-01T10:00:00+00:00",
                        "expires_at": "2025-01-01T10:00:00+00:00",
                        "trial_extended": False,
                        "stripe_customer_id": "cus_1234567890abcdef",
                        "cancelled_at": None,
                        "created_at": "2024-01-01T10:00:00+00:00",
                        "updated_at": "2024-01-01T10:00:00+00:00",
                    },
                    "days_remaining": 365,
                    "is_trial": False,
                    "is_active": True,
                    "is_expired": False,
                },
            }
        }
