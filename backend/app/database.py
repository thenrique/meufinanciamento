from supabase import create_client, Client
from functools import lru_cache
from app.config import get_settings
from loguru import logger


@lru_cache()
def get_supabase() -> Client:
    """Retorna cliente Supabase singleton."""
    settings = get_settings()
    client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    logger.debug("Supabase client inicializado")
    return client


def get_supabase_admin() -> Client:
    """Retorna cliente Supabase com service key (admin)."""
    settings = get_settings()
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_KEY)
