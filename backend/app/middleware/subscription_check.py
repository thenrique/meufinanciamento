"""Middleware to check subscription status before accessing protected endpoints."""
from datetime import datetime, timezone
from typing import Optional
from fastapi import Request
from fastapi.responses import JSONResponse
from loguru import logger
from app.database import get_supabase
from app.auth.dependencies import bearer_scheme


# Endpoints that don't require subscription check
EXEMPT_ENDPOINTS = {
    "/health",
    "/docs",
    "/redoc",
    "/openapi.json",
}

# Prefixes for exempt routes (checked with startswith)
EXEMPT_PREFIXES = {
    "/auth/",
}


def _is_exempt_endpoint(path: str) -> bool:
    """Check if endpoint is exempt from subscription check."""
    if path in EXEMPT_ENDPOINTS:
        return True
    
    for prefix in EXEMPT_PREFIXES:
        if path.startswith(prefix):
            return True
    
    return False


def _extract_token_from_request(request: Request) -> Optional[str]:
    """Extract Bearer token from request headers."""
    auth_header = request.headers.get("authorization")
    if not auth_header:
        return None
    
    parts = auth_header.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        return None
    
    return parts[1]


async def _get_user_id_from_token(token: str) -> Optional[str]:
    """Get user_id from Supabase JWT token."""
    try:
        supabase = get_supabase()
        response = supabase.auth.get_user(token)
        if response and response.user:
            return str(response.user.id)
    except Exception as exc:
        logger.debug(f"Falha ao extrair user_id do token: {exc}")
    
    return None


async def _get_subscription_status(user_id: str) -> Optional[dict]:
    """Get user subscription from database."""
    try:
        supabase = get_supabase()
        response = supabase.table("user_subscriptions").select("*").eq("user_id", user_id).single().execute()
        
        if response and response.data:
            return response.data
    except Exception as exc:
        logger.debug(f"Falha ao buscar assinatura do usuário {user_id}: {exc}")
    
    return None


async def _update_subscription_status_to_expired(user_id: str, subscription_id: str) -> None:
    """Update subscription status to expired if it has passed the expiration date."""
    try:
        supabase = get_supabase()
        supabase.table("user_subscriptions").update(
            {"status": "expired"}
        ).eq("id", subscription_id).execute()
        logger.info(f"Assinatura do usuário {user_id} atualizada para expirada")
    except Exception as exc:
        logger.warning(f"Falha ao atualizar status de assinatura para usuário {user_id}: {exc}")


async def subscription_middleware(request: Request, call_next):
    """
    Middleware to check subscription status before accessing protected endpoints.
    
    Checks:
    1. If endpoint is exempt, allow request
    2. If user is not authenticated, pass to next handler (auth dependency will handle)
    3. If status = 'expired': return 403
    4. If status = 'cancelled': return 403
    5. If status = 'active' and expires_at < today: update to 'expired', return 403
    6. Otherwise: allow request
    """
    # Skip check for exempt endpoints
    if _is_exempt_endpoint(request.url.path):
        return await call_next(request)
    
    # Extract token from request
    token = _extract_token_from_request(request)
    
    # If no token, let the endpoint's auth dependency handle it
    if not token:
        return await call_next(request)
    
    # Get user_id from token
    user_id = await _get_user_id_from_token(token)
    if not user_id:
        return await call_next(request)
    
    # Get subscription status
    subscription = await _get_subscription_status(user_id)
    
    # If no subscription found, allow request (will be created on first access)
    if not subscription:
        return await call_next(request)
    
    status = subscription.get("status")
    
    # Check if subscription is cancelled
    if status == "cancelled":
        logger.warning(
            f"Acesso bloqueado: assinatura cancelada | user_id: {user_id} | path: {request.url.path}"
        )
        return JSONResponse(
            status_code=403,
            content={"detail": "Sua assinatura foi cancelada."},
        )
    
    # Check if subscription is expired
    if status == "expired":
        logger.warning(
            f"Acesso bloqueado: assinatura expirada | user_id: {user_id} | path: {request.url.path}"
        )
        return JSONResponse(
            status_code=403,
            content={"detail": "Seu período de trial expirou. Atualize seu plano para continuar."},
        )
    
    # Check if subscription has passed expiration date
    if status == "active":
        expires_at = subscription.get("expires_at")
        if expires_at:
            try:
                # Parse expiration date
                if isinstance(expires_at, str):
                    expires_at = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
                
                # Compare with today (at start of day in UTC)
                today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
                expires_at_date = expires_at.replace(hour=0, minute=0, second=0, microsecond=0)
                
                if expires_at_date < today:
                    # Update status to expired and block request
                    await _update_subscription_status_to_expired(user_id, subscription.get("id"))
                    logger.warning(
                        f"Acesso bloqueado: assinatura expirada (data passada) | user_id: {user_id} | "
                        f"expires_at: {expires_at} | path: {request.url.path}"
                    )
                    return JSONResponse(
                        status_code=403,
                        content={"detail": "Seu período de trial expirou. Atualize seu plano para continuar."},
                    )
            except Exception as exc:
                logger.warning(f"Falha ao verificar data de expiração: {exc}")
    
    # Allow request
    return await call_next(request)
