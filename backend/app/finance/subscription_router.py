"""Subscription endpoints for user billing and trial management."""

from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from loguru import logger

from app.auth.dependencies import get_current_user
from app.database import get_supabase
from app.finance.models.subscription import (
    UserSubscription,
    SubscriptionStatus,
    SubscriptionResponse,
    TrialExtendRequest,
)
from app.finance.validators.subscription_validator import (
    validate_user_subscription_exists,
    validate_trial_can_extend,
    calculate_days_remaining,
    is_subscription_active,
    is_subscription_expired,
)
from app.analytics.events import log_event

router = APIRouter(prefix="/api", tags=["subscription"])


@router.post("/subscriptions/init-trial", response_model=UserSubscription, status_code=status.HTTP_201_CREATED)
async def init_trial_subscription(
    user_id: str = Depends(get_current_user),
) -> UserSubscription:
    """
    Cria uma assinatura trial para um novo usuário após o signup.

    Este endpoint é chamado automaticamente após o signup bem-sucedido.
    Se o usuário já possui uma assinatura, retorna um erro graceful.

    Args:
        user_id: ID do usuário autenticado

    Returns:
        UserSubscription: Dados da assinatura trial criada

    Raises:
        409: Se o usuário já possui uma assinatura
        500: Erro ao criar a assinatura
    """
    supabase = get_supabase()
    try:
        # Verificar se o usuário já possui uma assinatura
        try:
            existing = (
                supabase.table("user_subscriptions")
                .select("*")
                .eq("user_id", user_id)
                .single()
                .execute()
            )
            if existing.data:
                logger.warning(f"Usuário {user_id} já possui assinatura, ignorando criação de trial")
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Usuário já possui uma assinatura ativa",
                )
        except Exception as exc:
            # Se não houver assinatura (erro 406 do Supabase), continuar
            if "no rows" not in str(exc).lower() and "single" not in str(exc).lower():
                raise

        # Criar assinatura trial
        now_utc = datetime.now(timezone.utc)
        expires_at = now_utc + timedelta(days=7)

        subscription_data = {
            "user_id": user_id,
            "status": "active",
            "plan": "trial",
            "started_at": now_utc.isoformat(),
            "expires_at": expires_at.isoformat(),
            "trial_extended": False,
        }

        resp = supabase.table("user_subscriptions").insert(subscription_data).execute()

        if not resp.data:
            logger.error(f"Falha ao criar assinatura trial para usuário {user_id}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao criar assinatura trial",
            )

        created_subscription = UserSubscription(**resp.data[0])

        logger.info(f"Assinatura trial criada para usuário {user_id}, expira em {expires_at}")
        await log_event(
            supabase,
            user_id,
            "trial_subscription_created",
            {
                "expires_at": expires_at.isoformat(),
                "duration_days": 7,
            },
        )

        return created_subscription

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao criar assinatura trial para usuário {user_id}: {exc}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao criar assinatura trial",
        )


@router.get("/user/subscription", response_model=SubscriptionResponse)
async def get_user_subscription(
    user_id: str = Depends(get_current_user),
) -> SubscriptionResponse:
    """
    Retorna a assinatura atual do usuário com seu status.

    Returns:
        SubscriptionResponse: Dados da assinatura e status

    Raises:
        404: Se o usuário não possui assinatura
    """
    supabase = get_supabase()
    try:
        subscription = await validate_user_subscription_exists(user_id, supabase)

        days_remaining = calculate_days_remaining(subscription.expires_at)
        is_active = is_subscription_active(subscription)
        is_expired = is_subscription_expired(subscription)

        status_obj = SubscriptionStatus(
            subscription=subscription,
            days_remaining=days_remaining,
            is_trial=subscription.plan == "trial",
            is_active=is_active,
            is_expired=is_expired,
        )

        logger.info(f"Assinatura recuperada para usuário {user_id}")
        await log_event(supabase, user_id, "subscription_viewed", {})

        return SubscriptionResponse(subscription=subscription, status=status_obj)

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao recuperar assinatura do usuário {user_id}: {exc}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao recuperar assinatura",
        )


@router.get("/subscription/status", response_model=SubscriptionStatus)
async def get_subscription_status(
    user_id: str = Depends(get_current_user),
) -> SubscriptionStatus:
    """
    Retorna o status atual da assinatura do usuário.

    Returns:
        SubscriptionStatus: Status calculado em tempo real

    Raises:
        404: Se o usuário não possui assinatura
    """
    supabase = get_supabase()
    try:
        subscription = await validate_user_subscription_exists(user_id, supabase)

        days_remaining = calculate_days_remaining(subscription.expires_at)
        is_active = is_subscription_active(subscription)
        is_expired = is_subscription_expired(subscription)

        logger.info(f"Status de assinatura calculado para usuário {user_id}")
        await log_event(supabase, user_id, "subscription_status_checked", {})

        return SubscriptionStatus(
            subscription=subscription,
            days_remaining=days_remaining,
            is_trial=subscription.plan == "trial",
            is_active=is_active,
            is_expired=is_expired,
        )

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao calcular status de assinatura para {user_id}: {exc}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao calcular status de assinatura",
        )


@router.post("/subscription/extend-trial", response_model=SubscriptionResponse, status_code=status.HTTP_200_OK)
async def extend_trial(
    payload: TrialExtendRequest,
    user_id: str = Depends(get_current_user),
) -> SubscriptionResponse:
    """
    Estende o período de trial do usuário por 7 dias.

    Body:
        TrialExtendRequest: Validação para estender o trial

    Returns:
        SubscriptionResponse: Dados atualizados da assinatura

    Raises:
        400: Se não for um plano de trial ou já estiver estendido
        404: Se o usuário não possui assinatura
    """
    supabase = get_supabase()
    try:
        subscription = await validate_user_subscription_exists(user_id, supabase)

        await validate_trial_can_extend(subscription)

        new_expires_at = subscription.expires_at + timedelta(days=7)
        now_utc = datetime.now(timezone.utc)

        update_data = {
            "trial_extended": True,
            "expires_at": new_expires_at.isoformat(),
            "updated_at": now_utc.isoformat(),
        }

        resp = (
            supabase.table("user_subscriptions")
            .update(update_data)
            .eq("user_id", user_id)
            .execute()
        )

        if not resp.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao estender o trial",
            )

        updated_subscription = UserSubscription(**resp.data[0])

        days_remaining = calculate_days_remaining(updated_subscription.expires_at)
        is_active = is_subscription_active(updated_subscription)
        is_expired = is_subscription_expired(updated_subscription)

        status_obj = SubscriptionStatus(
            subscription=updated_subscription,
            days_remaining=days_remaining,
            is_trial=updated_subscription.plan == "trial",
            is_active=is_active,
            is_expired=is_expired,
        )

        logger.info(f"Trial estendido para usuário {user_id} até {new_expires_at}")
        await log_event(
            supabase,
            user_id,
            "trial_extended",
            {"new_expires_at": new_expires_at.isoformat()},
        )

        return SubscriptionResponse(subscription=updated_subscription, status=status_obj)

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao estender trial do usuário {user_id}: {exc}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao estender o período de trial",
        )


@router.delete("/subscription", response_model=SubscriptionResponse, status_code=status.HTTP_200_OK)
async def cancel_subscription(
    user_id: str = Depends(get_current_user),
) -> SubscriptionResponse:
    """
    Cancela a assinatura do usuário (soft delete).

    Returns:
        SubscriptionResponse: Dados da assinatura cancelada

    Raises:
        404: Se o usuário não possui assinatura
    """
    supabase = get_supabase()
    try:
        subscription = await validate_user_subscription_exists(user_id, supabase)

        if subscription.status == "cancelled":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Esta assinatura já foi cancelada",
            )

        now_utc = datetime.now(timezone.utc)

        update_data = {
            "status": "cancelled",
            "cancelled_at": now_utc.isoformat(),
            "updated_at": now_utc.isoformat(),
        }

        resp = (
            supabase.table("user_subscriptions")
            .update(update_data)
            .eq("user_id", user_id)
            .execute()
        )

        if not resp.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao cancelar assinatura",
            )

        cancelled_subscription = UserSubscription(**resp.data[0])

        days_remaining = calculate_days_remaining(cancelled_subscription.expires_at)
        is_active = is_subscription_active(cancelled_subscription)
        is_expired = is_subscription_expired(cancelled_subscription)

        status_obj = SubscriptionStatus(
            subscription=cancelled_subscription,
            days_remaining=days_remaining,
            is_trial=cancelled_subscription.plan == "trial",
            is_active=is_active,
            is_expired=is_expired,
        )

        logger.info(f"Assinatura cancelada para usuário {user_id} em {now_utc}")
        await log_event(
            supabase,
            user_id,
            "subscription_cancelled",
            {"cancelled_at": now_utc.isoformat()},
        )

        return SubscriptionResponse(subscription=cancelled_subscription, status=status_obj)

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Erro ao cancelar assinatura do usuário {user_id}: {exc}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao cancelar assinatura",
        )
