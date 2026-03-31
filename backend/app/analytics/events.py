from datetime import datetime, timezone
from typing import Optional
from loguru import logger
from supabase import Client


async def log_event(
    supabase: Client,
    user_id: str,
    event_type: str,
    metadata: Optional[dict] = None,
) -> None:
    """
    Registra evento de analytics na tabela analytics_events.

    Dados anonimizados — apenas user_id é preservado, sem PII adicional.
    """
    try:
        supabase.table("analytics_events").insert({
            "user_id": user_id,
            "event_type": event_type,
            "metadata": metadata or {},
            "created_at": datetime.now(timezone.utc).isoformat(),
        }).execute()
    except Exception as exc:
        logger.warning(f"Falha ao registrar evento '{event_type}' para {user_id}: {exc}")
