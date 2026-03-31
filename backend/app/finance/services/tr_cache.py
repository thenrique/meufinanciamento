"""
Caching system for historical TR (Taxa Referencial) rates from BCB.
Supports in-memory cache with TTL (24 hours) and batch retrieval.
"""

from datetime import date, datetime, timedelta, timezone
from typing import Dict, Optional, Tuple
import asyncio
import httpx
from loguru import logger

# Cache configuration
_CACHE: Dict[date, Tuple[float, datetime]] = {}
_CACHE_TTL_SECONDS = 86400  # 24 hours
_LOCK = asyncio.Lock()

# BCB API endpoints for historical TR
BCB_HISTORICAL_ENDPOINT = "https://www.bcb.gov.br/api/dados/TR"
BCB_SERIE_ENDPOINT = "https://api.bcb.gov.br/dados/serie/bcdata.sgs.226/dados?formato=json"

# Fallback values for error handling
DEFAULT_TR_VALUE = 0.0


def _is_cache_valid(cached_date: datetime) -> bool:
    """Check if a cached value is still valid (within TTL)."""
    age = datetime.now(timezone.utc) - cached_date
    return age.total_seconds() < _CACHE_TTL_SECONDS


async def _fetch_tr_from_bcb_api(start_date: date, end_date: date) -> Dict[date, float]:
    """
    Fetch TR historical data from BCB API.
    
    BCB provides TR data via their API endpoint. This function fetches
    data for the given date range and parses it.
    
    Args:
        start_date: Start date for the range
        end_date: End date for the range
    
    Returns:
        Dictionary mapping dates to TR values (as percentages)
    """
    tr_data: Dict[date, float] = {}
    
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.get(BCB_SERIE_ENDPOINT)
            response.raise_for_status()
            data = response.json()
            
            for entry in data:
                try:
                    # Parse date from BCB format (DD/MM/YYYY)
                    date_str = entry.get("data", "")
                    value_str = entry.get("valor", "0").replace(",", ".")
                    
                    parsed_date = datetime.strptime(date_str, "%d/%m/%Y").date()
                    
                    # Only include dates within requested range
                    if start_date <= parsed_date <= end_date:
                        tr_data[parsed_date] = float(value_str)
                        logger.debug(f"Fetched TR for {parsed_date}: {value_str}%")
                        
                except (ValueError, KeyError) as e:
                    logger.debug(f"Skipped entry due to parse error: {e}")
                    continue
            
            if tr_data:
                logger.info(f"Successfully fetched {len(tr_data)} TR records from BCB")
            else:
                logger.warning(f"No TR data found for range {start_date} to {end_date}")
                
    except httpx.HTTPError as e:
        logger.error(f"HTTP error fetching TR from BCB: {e}")
    except Exception as e:
        logger.error(f"Unexpected error fetching TR from BCB: {e}")
    
    return tr_data


def _get_last_day_of_month(d: date) -> date:
    """Get the last day of the month for a given date."""
    if d.month == 12:
        return date(d.year + 1, 1, 1) - timedelta(days=1)
    return date(d.year, d.month + 1, 1) - timedelta(days=1)


def _interpolate_missing_dates(data: Dict[date, float], start_date: date, end_date: date) -> Dict[date, float]:
    """
    Interpolate missing dates in TR data.
    
    For missing dates, use the last known value. If no previous value exists,
    use the next known value. This ensures continuity in the data.
    
    Args:
        data: Dictionary of available TR data
        start_date: Start of the requested range
        end_date: End of the requested range
    
    Returns:
        Dictionary with interpolated values for all dates in range
    """
    if not data:
        return {}
    
    result = dict(data)
    sorted_dates = sorted(data.keys())
    
    # Fill gaps with last known value (forward fill)
    current_date = start_date
    last_value = None
    
    while current_date <= end_date:
        if current_date in result:
            last_value = result[current_date]
        elif last_value is not None:
            result[current_date] = last_value
            logger.debug(f"Interpolated TR for {current_date} with {last_value}%")
        
        current_date += timedelta(days=1)
    
    return result


async def _update_cache(data: Dict[date, float]) -> None:
    """
    Update in-memory cache with new TR data and timestamps.
    
    Args:
        data: Dictionary of date -> TR value mappings
    """
    async with _LOCK:
        now = datetime.now(timezone.utc)
        for d, value in data.items():
            _CACHE[d] = (value, now)
        logger.info(f"Cache updated with {len(data)} TR entries")


def _get_from_cache(start_date: date, end_date: date) -> Optional[Dict[date, float]]:
    """
    Retrieve valid cached TR data for the requested date range.
    
    Returns None if any date in the range is missing or invalid (expired).
    
    Args:
        start_date: Start date for the range
        end_date: End date for the range
    
    Returns:
        Dictionary of cached TR values, or None if cache miss
    """
    current_date = start_date
    result: Dict[date, float] = {}
    
    while current_date <= end_date:
        if current_date in _CACHE:
            value, cached_time = _CACHE[current_date]
            if _is_cache_valid(cached_time):
                result[current_date] = value
            else:
                # Cache expired for this date
                logger.debug(f"Cache expired for {current_date}")
                return None
        else:
            # Date not in cache
            logger.debug(f"Cache miss for {current_date}")
            return None
        
        current_date += timedelta(days=1)
    
    logger.info(f"Cache hit for {start_date} to {end_date}")
    return result if result else None


async def get_tr_historical(start_date: date, end_date: date) -> Dict[date, float]:
    """
    Retrieve historical TR (Taxa Referencial) data for a date range.
    
    This function implements a caching strategy:
    1. Check in-memory cache first (24-hour TTL)
    2. If cache miss, fetch from BCB API
    3. Cache the results
    4. Interpolate missing dates with last known value
    
    Args:
        start_date: Start date (inclusive)
        end_date: End date (inclusive)
    
    Returns:
        Dictionary mapping dates to TR values (as percentages).
        Returns empty dict on total failure.
        Missing dates are interpolated using the last known value.
    
    Example:
        >>> from datetime import date
        >>> tr_data = await get_tr_historical(date(2025, 1, 1), date(2025, 1, 31))
        >>> tr_value = tr_data.get(date(2025, 1, 31), 0.0)
    """
    if start_date > end_date:
        logger.warning(f"Invalid date range: {start_date} > {end_date}")
        return {}
    
    try:
        # Try to get from cache first
        cached_data = _get_from_cache(start_date, end_date)
        if cached_data is not None:
            return cached_data
        
        # Cache miss - fetch from BCB
        logger.info(f"Fetching TR data from BCB for {start_date} to {end_date}")
        tr_data = await _fetch_tr_from_bcb_api(start_date, end_date)
        
        if tr_data:
            # Update cache with fetched data
            await _update_cache(tr_data)
            
            # Interpolate missing dates
            result = _interpolate_missing_dates(tr_data, start_date, end_date)
            return result
        else:
            logger.warning(f"No TR data fetched from BCB, returning empty dict")
            return {}
    
    except Exception as e:
        logger.error(f"Error in get_tr_historical: {e}")
        return {}


async def get_tr_for_month(year: int, month: int) -> float:
    """
    Get TR rate for a specific month (uses last day of month).
    
    Args:
        year: Year (e.g., 2025)
        month: Month (1-12)
    
    Returns:
        TR value as percentage, or DEFAULT_TR_VALUE on error
    """
    try:
        # Use last day of month for TR value
        if month == 12:
            month_end = date(year + 1, 1, 1) - timedelta(days=1)
        else:
            month_end = date(year, month + 1, 1) - timedelta(days=1)
        
        tr_data = await get_tr_historical(date(year, month, 1), month_end)
        
        # Return TR for last day of month, or last available value
        if month_end in tr_data:
            return tr_data[month_end]
        
        # Find last available value in the month
        for d in sorted(tr_data.keys(), reverse=True):
            if d.month == month and d.year == year:
                return tr_data[d]
        
        logger.warning(f"No TR data found for {year}-{month:02d}")
        return DEFAULT_TR_VALUE
    
    except Exception as e:
        logger.error(f"Error getting TR for month {year}-{month}: {e}")
        return DEFAULT_TR_VALUE


def clear_cache() -> None:
    """Clear the in-memory cache. Useful for testing or cache refresh."""
    global _CACHE
    _CACHE.clear()
    logger.info("TR cache cleared")


def get_cache_stats() -> Dict[str, any]:
    """
    Get statistics about the current cache state.
    
    Returns:
        Dictionary with cache statistics
    """
    valid_count = 0
    expired_count = 0
    now = datetime.now(timezone.utc)
    
    for d, (_, cached_time) in _CACHE.items():
        if _is_cache_valid(cached_time):
            valid_count += 1
        else:
            expired_count += 1
    
    return {
        "total_entries": len(_CACHE),
        "valid_entries": valid_count,
        "expired_entries": expired_count,
        "ttl_seconds": _CACHE_TTL_SECONDS,
    }
