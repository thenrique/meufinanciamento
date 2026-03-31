# TR (Taxa Referencial) Caching System

## Overview

The TR caching system provides efficient retrieval and caching of historical Tax Referencial (TR) rates from Banco Central do Brasil (BCB). It implements an in-memory cache with TTL (24 hours) to minimize API calls while maintaining data freshness.

## Architecture

### Components

1. **`tr_cache.py`** - Core caching logic
   - In-memory cache with TTL (24 hours)
   - Batch retrieval support for date ranges
   - Automatic date interpolation for missing values
   - Error handling and graceful fallbacks

2. **`bcb_service.py`** - Integration with BCB API
   - Wrapper functions for TR data retrieval
   - Support for single dates and date ranges
   - Maintains backward compatibility with existing API calls

## API Reference

### Core Functions

#### `get_tr_historical(start_date: date, end_date: date) -> Dict[date, float]`

Main function for retrieving historical TR data with automatic caching.

**Parameters:**
- `start_date`: Start date (inclusive)
- `end_date`: End date (inclusive)

**Returns:**
- Dictionary mapping dates to TR values (as percentages)
- Empty dict on total failure

**Features:**
- Automatic cache checking (24-hour TTL)
- Falls back to BCB API on cache miss
- Interpolates missing dates using forward fill strategy
- Comprehensive error logging

**Example:**
```python
from datetime import date
import asyncio
from app.finance.services.tr_cache import get_tr_historical

async def main():
    tr_data = await get_tr_historical(date(2025, 1, 1), date(2025, 1, 31))
    # Returns: {date(2025, 1, 1): 0.45, date(2025, 1, 2): 0.45, ..., date(2025, 1, 31): 0.47}

asyncio.run(main())
```

---

#### `get_tr_for_month(year: int, month: int) -> float`

Get TR rate for a specific month (uses last day of month).

**Parameters:**
- `year`: Year (e.g., 2025)
- `month`: Month (1-12)

**Returns:**
- TR value as percentage, or DEFAULT_TR_VALUE (0.0) on error

**Example:**
```python
import asyncio
from app.finance.services.tr_cache import get_tr_for_month

async def main():
    tr_jan = await get_tr_for_month(2025, 1)
    # Returns: 0.45

asyncio.run(main())
```

---

### BCB Service Functions

#### `fetch_tr_from_bcb(target_date: date) -> float`

Fetch TR value for a specific date using the historical cache.

**Parameters:**
- `target_date`: The date to fetch TR for

**Returns:**
- TR value as percentage, or DEFAULTS["TR"] (0.0) if unavailable

**Features:**
- Automatic date range expansion (±40 days) to ensure data availability
- Falls back to closest available date if exact date not found
- Handles missing dates gracefully

**Example:**
```python
import asyncio
from datetime import date
from app.finance.bcb_service import fetch_tr_from_bcb

async def main():
    tr = await fetch_tr_from_bcb(date(2025, 1, 15))
    # Returns: 0.45

asyncio.run(main())
```

---

#### `get_tr_for_period(start_date: date, end_date: date) -> dict`

Get TR rates for a period (useful for historical calculations).

**Parameters:**
- `start_date`: Start date (inclusive)
- `end_date`: End date (inclusive)

**Returns:**
- Dictionary mapping dates to TR values, or empty dict on error

**Example:**
```python
import asyncio
from datetime import date
from app.finance.bcb_service import get_tr_for_period

async def main():
    tr_data = await get_tr_for_period(date(2025, 1, 1), date(2025, 12, 31))
    # Returns: {date(2025, 1, 31): 0.45, date(2025, 2, 28): 0.43, ...}

asyncio.run(main())
```

---

### Utility Functions

#### `clear_cache() -> None`

Clear the in-memory cache. Useful for testing or cache refresh.

**Example:**
```python
from app.finance.services.tr_cache import clear_cache

clear_cache()
```

---

#### `get_cache_stats() -> Dict[str, any]`

Get statistics about the current cache state.

**Returns:**
- Dictionary with cache statistics:
  - `total_entries`: Total number of cached entries
  - `valid_entries`: Number of entries within TTL
  - `expired_entries`: Number of expired entries
  - `ttl_seconds`: TTL value in seconds (86400)

**Example:**
```python
from app.finance.services.tr_cache import get_cache_stats

stats = get_cache_stats()
print(f"Cache has {stats['valid_entries']} valid entries")
```

---

## Caching Strategy

### Cache Lookup Flow

```
Request for TR data (start_date, end_date)
    ↓
Check in-memory cache for all dates in range
    ↓
All dates valid & within TTL? → YES → Return cached data
    ↓ NO
Fetch from BCB API
    ↓
Cache results (with timestamps)
    ↓
Interpolate missing dates (forward fill)
    ↓
Return interpolated data
```

### TTL and Expiration

- **TTL**: 24 hours (86400 seconds)
- Checked per-date basis
- Individual dates expire independently
- Cache miss if ANY date in range is expired or missing

### Date Interpolation

Missing dates are filled using a **forward fill** strategy:
- Uses the last known value for missing dates
- Ensures continuity in TR data
- Only fills dates within the requested range

**Example:**
```python
# Input data: {date(2025, 1, 5): 0.40, date(2025, 1, 15): 0.45}
# Range: 2025-01-01 to 2025-01-31
# Result:
# - 2025-01-01 to 2025-01-04: not filled (no previous value)
# - 2025-01-05: 0.40
# - 2025-01-06 to 2025-01-14: 0.40 (forward fill)
# - 2025-01-15 to 2025-01-31: 0.45
```

## Integration with Loan Calculations

### Using TR Cache in `calculate_loan_with_history()`

```python
from datetime import date
from app.finance.bcb_service import get_tr_for_period
from app.finance.engine import CaixaModel

async def calculate_loan_with_history(loan_id: str, start_date: date, end_date: date):
    """Calculate loan amortization with historical TR rates."""
    
    # Get TR data for the period
    tr_data = await get_tr_for_period(start_date, end_date)
    
    # Now use TR data in calculations
    # Example: tr_data[date(2025, 1, 31)] = 0.45
    
    model = CaixaModel()
    schedule = await model.calculate_schedule(
        balance=100000,
        annual_rate=6.5,
        months=360,
        insurance_monthly=0.0
    )
    
    return schedule
```

## Error Handling

### Graceful Degradation

The system implements multiple fallback strategies:

1. **Cache Hit**: Use cached data (fastest)
2. **API Success**: Cache new data and use it
3. **API Failure**: Return empty dict (caller decides handling)
4. **Date Not Found**: Interpolate with last known value
5. **Total Failure**: Use default TR value (0.0)

### Logging

All operations are logged with appropriate levels:
- **INFO**: Cache hits, successful API calls, successful updates
- **DEBUG**: Individual date processing, cache misses
- **WARNING**: API failures, missing data, fallback to defaults
- **ERROR**: Exceptions and unexpected errors

Example logs:
```
INFO - Cache hit for 2025-01-01 to 2025-01-31
INFO - Successfully fetched 31 TR records from BCB
WARNING - Cache expired for 2025-01-15
ERROR - HTTP error fetching TR from BCB: ...
```

## Performance Considerations

### Cache Efficiency

- **In-memory cache**: O(1) lookup per date
- **Batch retrieval**: Fetches entire range in one API call
- **Minimal API calls**: Default 24-hour TTL reduces BCB load

### Limitations

1. **Single-process cache**: In-memory only, not shared across processes
2. **Memory usage**: Stores one entry per cached date
3. **No persistence**: Cache lost on process restart
4. **Date range**: Limited to BCB's available historical data

### Future Improvements

- Redis integration for distributed caching
- Database persistence for cache recovery
- Compressed data storage (only store month-end values)
- Cache warming strategies for predictable patterns
- Exponential backoff for API failures

## Testing

### Running Tests

```bash
cd backend
python -m pytest tests/test_tr_cache.py -v
```

### Test Coverage

- Cache hit/miss scenarios
- Date interpolation logic
- API error handling
- Invalid date range handling
- Cache expiration
- Integration with BCB service

### Example Test

```python
import pytest
from datetime import date
from app.finance.services.tr_cache import get_tr_historical, clear_cache

@pytest.mark.asyncio
async def test_tr_historical_with_mock_api(monkeypatch):
    """Test TR historical retrieval with mocked API."""
    clear_cache()
    
    mock_data = {date(2025, 1, 31): 0.45}
    
    async def mock_fetch(start_date, end_date):
        return mock_data
    
    monkeypatch.setattr(
        "app.finance.services.tr_cache._fetch_tr_from_bcb_api",
        mock_fetch
    )
    
    result = await get_tr_historical(date(2025, 1, 1), date(2025, 1, 31))
    assert result is not None
```

## BCB Data Source

### API Endpoint

- **URL**: https://api.bcb.gov.br/dados/serie/bcdata.sgs.226/dados?formato=json
- **Series ID**: 226 (TR - Taxa Referencial)
- **Format**: JSON
- **Date Format**: DD/MM/YYYY
- **Value Format**: String with comma as decimal separator (e.g., "0,45")

### Example Response

```json
[
    {
        "data": "31/01/2025",
        "valor": "0,45"
    },
    {
        "data": "28/02/2025",
        "valor": "0,43"
    }
]
```

### Data Availability

- Historical data available from BCB's inception
- Updated monthly (typically on the last business day)
- May have gaps for holidays

## Configuration

### Cache Constants

Located in `tr_cache.py`:

```python
_CACHE_TTL_SECONDS = 86400  # 24 hours
DEFAULT_TR_VALUE = 0.0       # Fallback value
BCB_SERIE_ENDPOINT = "https://api.bcb.gov.br/dados/serie/bcdata.sgs.226/dados?formato=json"
```

### Modifying TTL

To change cache TTL, update `_CACHE_TTL_SECONDS`:

```python
# In tr_cache.py
_CACHE_TTL_SECONDS = 3600  # 1 hour instead of 24 hours
```

## Troubleshooting

### High Cache Miss Rate

**Symptom**: Frequent BCB API calls

**Solutions**:
1. Check TTL setting - increase if appropriate
2. Monitor BCB API availability
3. Review cache statistics with `get_cache_stats()`

### Missing TR Data

**Symptom**: Receiving 0.0 (default value)

**Solutions**:
1. Verify requested dates fall within BCB's data range
2. Check BCB API availability
3. Try expanding date range (±30 days)
4. Review logs for API errors

### Stale Data

**Symptom**: TR values not updating despite API changes

**Solutions**:
1. Call `clear_cache()` to force refresh
2. Wait for 24-hour TTL expiration
3. Check if date is within cache TTL with `get_cache_stats()`

## Version History

- **v1.0** (Initial): In-memory cache with TTL, BCB API integration
- **Future**: Redis support, database persistence, cache warming

## Contributing

When modifying this system:

1. Maintain async/await pattern
2. Add comprehensive type hints
3. Include docstrings with examples
4. Add tests for new functionality
5. Update this documentation

## References

- BCB API Documentation: https://www.bcb.gov.br/
- TR Historical Data: https://api.bcb.gov.br/dados/serie/bcdata.sgs.226/
- Python asyncio: https://docs.python.org/3/library/asyncio.html
