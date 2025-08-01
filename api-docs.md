# API Documentation

## Running the API

  ```
  uv run python start_api.py
  ```

  Or specify a custom port:
  ```
  PORT=3000 uv run python start_api.py
  ```

## API Endpoints

### Health Check
```bash
  curl "http://localhost:8000/api/health"
```

### Model Search Endpoint
```bash
  # Basic model search
  curl "http://localhost:8000/api/search/models?model_name=Les%20Paul"

  # With manufacturer filter
  curl "http://localhost:8000/api/search/models?model_name=Les%20Paul%20Standard&manufacturer_name=Gibson"

  # With year filter
  curl "http://localhost:8000/api/search/models?model_name=Les%20Paul&year=1959"

  # With pagination
  curl "http://localhost:8000/api/search/models?model_name=Les%20Paul&page=2&page_size=5"
```

### Instrument Search Endpoint
```bash
  # Serial number search (exact matching with normalization)
  curl "http://localhost:8000/api/search/instruments?serial_number=9-0824"
  curl "http://localhost:8000/api/search/instruments?serial_number=90824"
  curl "http://localhost:8000/api/search/instruments?serial_number=00247991"

  # Unknown serial search (model-based)
  curl "http://localhost:8000/api/search/instruments?unknown_serial=true&model_name=Les%20Paul%20Standard&manufacturer_name=Gibson"

  # Unknown serial search with year estimate
  curl "http://localhost:8000/api/search/instruments?unknown_serial=true&model_name=Firebird&year_estimate=1976"

  # With pagination
  curl "http://localhost:8000/api/search/instruments?serial_number=9-0824&page=1&page_size=10"
```

## Search Parameters

### Model Search Parameters (`/api/search/models`)

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `model_name` | string | ✅ Yes | Model name to search for (case-insensitive, fuzzy matching) | `"Les Paul Standard"` |
| `manufacturer_name` | string | ❌ No | Manufacturer name filter (case-insensitive, fuzzy matching) | `"Gibson"` |
| `year` | integer | ❌ No | Year filter (1900-2030 range) | `1959` |
| `page` | integer | ❌ No | Page number (1-based, default: 1) | `2` |
| `page_size` | integer | ❌ No | Results per page (1-10, default: 10) | `5` |

**Notes:**
- `model_name` supports fuzzy matching using PostgreSQL trigrams
- Years can be automatically extracted from model names (e.g., "Les Paul 1959" will set year=1959)
- Manufacturer similarity threshold is 0.25 to handle longer names like "Gibson Guitar Corporation"
- Results are ordered by exact matches first, then by year (descending), then alphabetically

### Instrument Search Parameters (`/api/search/instruments`)

#### Serial Number Search (when `serial_number` is provided)

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `serial_number` | string | ✅ Yes* | Serial number to search for (exact matching with normalization) | `"9-0824"` |
| `page` | integer | ❌ No | Page number (1-based, default: 1) | `1` |
| `page_size` | integer | ❌ No | Results per page (1-10, default: 10) | `10` |

**Serial Number Normalization:**
- **Dash Removal**: `"9-0824"` matches `"90824"`
- **Leading Zeros Removal**: `"00247991"` matches `"247991"`
- **Case Insensitive**: Works regardless of case
- **Exact Matching Only**: No fuzzy or partial matching

#### Unknown Serial Search (when `unknown_serial=true`)

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `unknown_serial` | boolean | ✅ Yes* | Flag indicating unknown serial search | `true` |
| `model_name` | string | ❌ No** | Model name for search (case-insensitive, fuzzy matching) | `"Les Paul Standard"` |
| `manufacturer_name` | string | ❌ No** | Manufacturer name for search (case-insensitive, fuzzy matching) | `"Gibson"` |
| `year_estimate` | integer | ❌ No | Year estimate filter (1900-2030 range) | `1976` |
| `page` | integer | ❌ No | Page number (1-based, default: 1) | `1` |
| `page_size` | integer | ❌ No | Results per page (1-10, default: 10) | `10` |

**Notes:**
- *Either `serial_number` OR `unknown_serial` must be provided
- **At least one of `model_name` or `manufacturer_name` must be provided when `unknown_serial=true`
- Years can be automatically extracted from model names
- Search includes both linked models and fallback fields
- Results are ordered by year relevance, estimated value, and significance level

### Pagination Parameters (All Endpoints)

| Parameter | Type | Default | Description | Example |
|-----------|------|---------|-------------|---------|
| `page` | integer | `1` | Page number (1-based indexing) | `2` |
| `page_size` | integer | `10` | Results per page (max: configurable via `MAX_PAGE_SIZE` env var) | `5` |

**Pagination Response Format:**
```json
{
  "data": [...],
  "pagination": {
    "current_page": 1,
    "page_size": 10,
    "total_pages": 3,
    "total_records": 25
  }
}
```

## Response Formats

### Model Search Response
```json
{
  "models": [
    {
      "id": "019857b5-61dd-7a63-b534-bd885b93cee6",
      "model_name": "Les Paul Standard",
      "year": 1959,
      "manufacturer_name": "Gibson Guitar Corporation",
      "product_line_name": "Les Paul",
      "description": null
    }
  ],
  "total_records": 13,
  "current_page": 1,
  "page_size": 10,
  "total_pages": 2
}
```

### Instrument Search Response
```json
{
  "individual_guitars": [
    {
      "id": "019857b8-ff25-7093-822c-e46d6c4060ec",
      "serial_number": "9-0824",
      "year_estimate": null,
      "description": null,
      "significance_level": "historic",
      "significance_notes": "Famous 1959 Les Paul",
      "current_estimated_value": "500000.00",
      "condition_rating": null,
      "model_name": "Les Paul Standard",
      "manufacturer_name": "Gibson Guitar Corporation",
      "product_line_name": "Les Paul"
    }
  ],
  "total_records": 1,
  "current_page": 1,
  "page_size": 10,
  "total_pages": 1
}
```

## Error Responses

### Bad Request (400)
```json
{
  "error": "Bad Request",
  "message": "model_name parameter is required"
}
```

### Internal Server Error (500)
```json
{
  "error": "Internal Server Error",
  "message": "An error occurred while searching models"
}
```

## API Structure:

- /api directory with proper Flask application structure
- Modular design with separate packages for routes, search logic, and utilities
- Configuration management using existing db_config.json
- Database connection pooling for performance

## Core Features Implemented:

1. Model Search Endpoint (/api/search/models)
- Fuzzy search with PostgreSQL trigrams
- Multi-field search across model names, product lines, and manufacturers
- Automatic year extraction from model names
- Case-insensitive partial matching
- Proper pagination with metadata

2. Individual Guitar Search Endpoint (/api/search/instruments)
- Serial number-based search with exact matching and normalization
- Model-based search for unknown serials
- Hybrid data model support (model_id + fallback fields)
- Advanced search logic as specified in requirements

3. Advanced Search Features:
- Fuzzy matching using PostgreSQL trigrams and Python difflib
- Year extraction from search terms using regex
- Multi-word search term processing
- Similarity scoring and relevance ranking
- Configurable pagination (environment variable support)

## Technical Implementation:

- Flask with CORS support for web integration
- PostgreSQL connection using existing database configuration
- Input validation with comprehensive error handling
- Response formatting matching exact API specification
- Database connection pooling for performance
- Modular architecture for maintainability

## File structure
 ```bash
api/
├── app.py                    # Flask application entry point
├── config.py                 # Database configuration management
├── database.py               # Connection pooling and query utilities
├── requirements.txt          # Flask dependencies
├── README.md                 # Complete API documentation
├── routes/
│   └── search_routes.py      # API endpoint definitions
└── search/
    ├── model_search.py       # Model search implementation
    ├── instrument_search.py  # Individual guitar search
    └── utils.py              # Search utilities and helpers
```
    
## Additional files:
start_api.py                  # Easy startup script
test_api.py                   # Test suite for validation

