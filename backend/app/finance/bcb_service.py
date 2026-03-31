from datetime import datetime, timedelta, timezone, date
from typing import Optional
import httpx
from loguru import logger
from app.database import get_supabase
from app.finance.services.tr_cache import get_tr_historical, get_tr_for_month

BCB_BASE = "https://api.bcb.gov.br/dados/serie/bcdata.sgs.{serie}/dados/ultimos/1?formato=json"

SERIES = {
    "TR": 226,
    "SELIC": 11,
}

DEFAULTS = {
    "TR": 0.0,
    "SELIC": 10.5,
}


async def _fetch_bcb(serie: int) -> Optional[float]:
    """Busca valor mais recente de uma série do Banco Central do Brasil."""
    url = BCB_BASE.format(serie=serie)
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(url)
            response.raise_for_status()
            data = response.json()
            if data:
                return float(data[0]["valor"].replace(",", "."))
    except Exception as exc:
        logger.warning(f"Falha ao buscar série BCB {serie}: {exc}")
    return None


async def _get_cached(key: str) -> Optional[float]:
    """Busca valor em cache do Supabase (validade 24h)."""
    try:
        supabase = get_supabase()
        cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
        resp = (
            supabase.table("rates_cache")
            .select("value")
            .eq("key", key)
            .gte("updated_at", cutoff)
            .order("updated_at", desc=True)
            .limit(1)
            .execute()
        )
        if resp.data:
            return float(resp.data[0]["value"])
    except Exception as exc:
        logger.warning(f"Falha ao ler cache de taxas ({key}): {exc}")
    return None


async def _save_cache(key: str, value: float) -> None:
    """Persiste valor no cache do Supabase."""
    try:
        supabase = get_supabase()
        supabase.table("rates_cache").upsert(
            {"key": key, "value": value, "updated_at": datetime.now(timezone.utc).isoformat()},
            on_conflict="key",
        ).execute()
    except Exception as exc:
        logger.warning(f"Falha ao salvar cache de taxas ({key}): {exc}")


async def get_tr_mensal() -> float:
    """Retorna TR mensal atual (%). Cache 24h, fallback para último valor salvo."""
    cached = await _get_cached("TR")
    if cached is not None:
        return cached

    value = await _fetch_bcb(SERIES["TR"])
    if value is not None:
        await _save_cache("TR", value)
        return value

    logger.warning("Usando valor padrão histórico para TR")
    return DEFAULTS["TR"]


async def get_selic_anual() -> float:
    """Retorna Selic anual atual (%). Cache 24h, fallback para último valor salvo."""
    cached = await _get_cached("SELIC")
    if cached is not None:
        return cached

    value = await _fetch_bcb(SERIES["SELIC"])
    if value is not None:
        await _save_cache("SELIC", value)
        return value

    logger.warning("Usando valor padrão histórico para Selic")
    return DEFAULTS["SELIC"]


async def get_current_rates() -> dict:
    """Retorna TR mensal e Selic anual atuais."""
    tr = await get_tr_mensal()
    selic = await get_selic_anual()
    return {"tr_mensal": tr, "selic_anual": selic}


async def fetch_tr_from_bcb(target_date: date) -> float:
    """
    Fetch TR value for a specific date from BCB.
    
    Uses the historical TR caching system to retrieve TR rates.
    Attempts to get data for the exact date; if not available,
    returns the last known value from the cache.
    
    Args:
        target_date: The date to fetch TR for
    
    Returns:
        TR value as percentage, or DEFAULTS["TR"] if unavailable
    
    Example:
        >>> from datetime import date
        >>> tr = await fetch_tr_from_bcb(date(2025, 1, 31))
    """
    try:
        # Fetch data for a range around the target date to ensure we get a value
        start_date = target_date - timedelta(days=30)
        end_date = target_date + timedelta(days=10)
        
        tr_data = await get_tr_historical(start_date, end_date)
        
        if not tr_data:
            logger.warning(f"No TR data available for {target_date}, using default")
            return DEFAULTS["TR"]
        
        # Try exact date first
        if target_date in tr_data:
            return tr_data[target_date]
        
        # Find the closest available date
        available_dates = sorted(tr_data.keys())
        
        # Find closest date before target
        before = [d for d in available_dates if d <= target_date]
        if before:
            return tr_data[before[-1]]
        
        # Return first available if all are after target
        return tr_data[available_dates[0]]
    
    except Exception as e:
        logger.error(f"Error fetching TR for {target_date}: {e}")
        return DEFAULTS["TR"]


async def get_tr_for_period(start_date: date, end_date: date) -> dict:
    """
    Get TR rates for a period (useful for historical calculations).
    
    Args:
        start_date: Start date (inclusive)
        end_date: End date (inclusive)
    
    Returns:
        Dictionary mapping dates to TR values, or empty dict on error
    
    Example:
        >>> from datetime import date
        >>> tr_data = await get_tr_for_period(date(2025, 1, 1), date(2025, 12, 31))
    """
    try:
        return await get_tr_historical(start_date, end_date)
    except Exception as e:
        logger.error(f"Error getting TR for period {start_date} to {end_date}: {e}")
        return {}
