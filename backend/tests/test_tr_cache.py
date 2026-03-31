"""Unit tests for TR (Taxa Referencial) cache system."""

import pytest
from datetime import date, datetime, timedelta, timezone
from unittest.mock import AsyncMock, patch, MagicMock
import asyncio

from app.finance.services.tr_cache import (
    get_tr_historical,
    get_tr_for_month,
    clear_cache,
    get_cache_stats,
    _get_from_cache,
    _update_cache,
    _is_cache_valid,
    _interpolate_missing_dates,
)


class TestTRCache:
    """Test suite for TR cache functionality."""

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        """Clear cache before and after each test."""
        clear_cache()
        yield
        clear_cache()

    def test_cache_stats_empty(self):
        """Test cache statistics for empty cache."""
        stats = get_cache_stats()
        assert stats["total_entries"] == 0
        assert stats["valid_entries"] == 0
        assert stats["expired_entries"] == 0
        assert stats["ttl_seconds"] == 86400

    @pytest.mark.asyncio
    async def test_get_from_cache_empty(self):
        """Test getting from empty cache returns None."""
        start_date = date(2025, 1, 1)
        end_date = date(2025, 1, 31)
        result = _get_from_cache(start_date, end_date)
        assert result is None

    def test_is_cache_valid_fresh(self):
        """Test that fresh cache is valid."""
        now = datetime.now(timezone.utc)
        assert _is_cache_valid(now) is True

    def test_is_cache_valid_expired(self):
        """Test that old cache is invalid."""
        old_time = datetime.now(timezone.utc) - timedelta(hours=25)
        assert _is_cache_valid(old_time) is False

    @pytest.mark.asyncio
    async def test_update_and_retrieve_cache(self):
        """Test updating and retrieving from cache."""
        test_data = {
            date(2025, 1, 1): 0.45,
            date(2025, 1, 2): 0.46,
        }
        
        await _update_cache(test_data)
        
        # Verify cache was updated
        stats = get_cache_stats()
        assert stats["total_entries"] == 2
        assert stats["valid_entries"] == 2

    def test_interpolate_missing_dates_empty(self):
        """Test interpolation with empty data returns empty dict."""
        result = _interpolate_missing_dates({}, date(2025, 1, 1), date(2025, 1, 31))
        assert result == {}

    def test_interpolate_missing_dates_single_value(self):
        """Test interpolation with single value fills entire range."""
        data = {date(2025, 1, 15): 0.45}
        result = _interpolate_missing_dates(data, date(2025, 1, 1), date(2025, 1, 31))
        
        # Check a few dates are filled with the value
        assert result[date(2025, 1, 1)] == 0.45
        assert result[date(2025, 1, 10)] == 0.45
        assert result[date(2025, 1, 15)] == 0.45
        assert result[date(2025, 1, 31)] == 0.45

    def test_interpolate_missing_dates_forward_fill(self):
        """Test forward fill interpolation."""
        data = {
            date(2025, 1, 5): 0.40,
            date(2025, 1, 15): 0.45,
        }
        result = _interpolate_missing_dates(data, date(2025, 1, 1), date(2025, 1, 31))
        
        # Before first value, nothing is filled
        assert date(2025, 1, 1) not in result
        
        # After first value, forward fill applies
        assert result[date(2025, 1, 5)] == 0.40
        assert result[date(2025, 1, 10)] == 0.40
        assert result[date(2025, 1, 15)] == 0.45
        assert result[date(2025, 1, 20)] == 0.45

    @pytest.mark.asyncio
    async def test_get_tr_historical_invalid_range(self):
        """Test get_tr_historical with invalid date range."""
        result = await get_tr_historical(date(2025, 1, 31), date(2025, 1, 1))
        assert result == {}

    @pytest.mark.asyncio
    async def test_get_tr_historical_cache_hit(self):
        """Test cache hit on second call."""
        # First populate cache
        test_data = {date(2025, 1, 1): 0.45}
        await _update_cache(test_data)
        
        # Mock the API to ensure it's not called
        with patch("app.finance.services.tr_cache._fetch_tr_from_bcb_api") as mock_fetch:
            result = await get_tr_historical(date(2025, 1, 1), date(2025, 1, 1))
            
            # Should not call API on cache hit
            mock_fetch.assert_not_called()
            assert result is not None

    @pytest.mark.asyncio
    async def test_get_tr_historical_with_mock_api(self):
        """Test get_tr_historical with mocked API response."""
        mock_data = {
            date(2025, 1, 31): 0.45,
            date(2025, 2, 28): 0.43,
        }
        
        with patch("app.finance.services.tr_cache._fetch_tr_from_bcb_api", new_callable=AsyncMock) as mock_fetch:
            mock_fetch.return_value = mock_data
            
            result = await get_tr_historical(date(2025, 1, 1), date(2025, 2, 28))
            
            assert result is not None
            assert len(result) > 0
            mock_fetch.assert_called_once()

    @pytest.mark.asyncio
    async def test_get_tr_for_month_default_fallback(self):
        """Test get_tr_for_month returns default on error."""
        with patch("app.finance.services.tr_cache.get_tr_historical", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = {}
            
            result = await get_tr_for_month(2025, 1)
            assert result == 0.0  # Default value

    @pytest.mark.asyncio
    async def test_get_tr_for_month_with_data(self):
        """Test get_tr_for_month with available data."""
        mock_data = {
            date(2025, 1, 31): 0.45,
        }
        
        with patch("app.finance.services.tr_cache.get_tr_historical", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_data
            
            result = await get_tr_for_month(2025, 1)
            assert result == 0.45

    def test_clear_cache(self):
        """Test clearing the cache."""
        import app.finance.services.tr_cache as tr_cache
        # Manually add some data
        tr_cache._CACHE[date(2025, 1, 1)] = (0.45, datetime.now(timezone.utc))
        
        assert len(tr_cache._CACHE) > 0
        clear_cache()
        assert len(tr_cache._CACHE) == 0


class TestTRCacheErrorHandling:
    """Test error handling in TR cache."""

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        """Clear cache before and after each test."""
        clear_cache()
        yield
        clear_cache()

    @pytest.mark.asyncio
    async def test_get_tr_historical_api_error(self):
        """Test get_tr_historical handles API errors gracefully."""
        with patch("app.finance.services.tr_cache._fetch_tr_from_bcb_api", new_callable=AsyncMock) as mock_fetch:
            mock_fetch.side_effect = Exception("API Error")
            
            result = await get_tr_historical(date(2025, 1, 1), date(2025, 1, 31))
            assert result == {}

    @pytest.mark.asyncio
    async def test_get_tr_historical_empty_response(self):
        """Test get_tr_historical with empty API response."""
        with patch("app.finance.services.tr_cache._fetch_tr_from_bcb_api", new_callable=AsyncMock) as mock_fetch:
            mock_fetch.return_value = {}
            
            result = await get_tr_historical(date(2025, 1, 1), date(2025, 1, 31))
            assert result == {}


class TestTRCacheIntegration:
    """Integration tests for TR cache with bcb_service."""

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        """Clear cache before and after each test."""
        clear_cache()
        yield
        clear_cache()

    @pytest.mark.asyncio
    async def test_fetch_tr_from_bcb_with_exact_date(self):
        """Test fetch_tr_from_bcb finds exact date."""
        from app.finance.bcb_service import fetch_tr_from_bcb
        
        mock_data = {date(2025, 1, 15): 0.45}
        
        with patch("app.finance.services.tr_cache.get_tr_historical", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_data
            
            result = await fetch_tr_from_bcb(date(2025, 1, 15))
            assert result == 0.45

    @pytest.mark.asyncio
    async def test_fetch_tr_from_bcb_closest_date(self):
        """Test fetch_tr_from_bcb falls back to closest date."""
        from app.finance.bcb_service import fetch_tr_from_bcb
        
        mock_data = {
            date(2025, 1, 10): 0.40,
            date(2025, 1, 20): 0.50,
        }
        
        with patch("app.finance.services.tr_cache.get_tr_historical", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_data
            
            # Request date is between 10 and 20, should return 10 (before)
            result = await fetch_tr_from_bcb(date(2025, 1, 15))
            assert result == 0.40

    @pytest.mark.asyncio
    async def test_get_tr_for_period(self):
        """Test get_tr_for_period returns data."""
        from app.finance.bcb_service import get_tr_for_period
        
        mock_data = {
            date(2025, 1, 31): 0.45,
            date(2025, 2, 28): 0.43,
        }
        
        with patch("app.finance.services.tr_cache.get_tr_historical", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_data
            
            result = await get_tr_for_period(date(2025, 1, 1), date(2025, 2, 28))
            assert result == mock_data
