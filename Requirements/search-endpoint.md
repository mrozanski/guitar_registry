# Model and instrument search endpoint

## Goal

Enable an API with an endpoint that allows clients to search for model and instruments.

## General requirements

Use case:
User is trying to create a review for a model that is not in the database.
User can search using the model name and other optional parameters, and get a list of models that match.
If a model matches, the user can select the model and continue with the review.
If no model matches, the user can add the model to the database (adding is a separate requirement, not in scope of this one)

Use Python. Create all ncessary files to support the endpoint. This project contains python scripts that can be used from command line but no REST APi structure yet.
The rest api should be implemented in a new folder /api and use the same connection parameters to the database as the existing scripts.

### Pagination

All search endpoints should implement pagination following standard REST practices:

- **Page size**: Maximum of 10 results per request (configurable via environment variable `MAX_PAGE_SIZE`, defaults to 10)
- **Page parameter**: Use `page` query parameter (1-based indexing, defaults to 1)
- **Response format**: Include pagination metadata in all search responses:
  - `total_records`: Total number of matching records
  - `current_page`: Current page number
  - `page_size`: Number of records per page
  - `total_pages`: Total number of pages
- **Example**: `GET /api/search/models?model_name=Les Paul&page=2&page_size=5`

## Model search

### Search parameters

- model_name: string (required)
- manufacturer_name: string (optional)
- year: integer (optional)

### Considerations

- The search should be case-insensitive.
- The search should be fuzzy, so that if the user misspells the model name, it should still find possible matches.
- The search should be able to handle partial matches.
- The search should be able to handle multiple words in the model name.
- The search should be able to handle multiple words in the model_name.
- The user may use the product line name to search for the model. The endpoint should be able to handle this by trying to match the words in models.name and product_lines.name to the words in the search parameters.
- The model_name may include a year, and the endpoint should be able to handle this by identifying possible years in the model_name string and matching them to models.year.

### Response

The endpoint should return a JSON object containing:

- list of models that match the search parameters
- for each model, the following fields:
  - id (from models.id)
  - model_name (from models.name)
  - year (from models.year)
  - product_line_name (from models.product_line_name where models.product_line_id = product_lines.id)
  - manufacturer_name (from manufacturers.name where models.manufacturer_id = manufacturers.id)
  - description (from models.description)
- if no models match, return an empty list

### Example response

```json
{
  "models": [
    {
      "id": "019820ad-be5e-7e78-af44-bec1e789f601",
      "model_name": "Les Paul Standard",
      "manufacturer_name": "Gibson",
      "year": 1959,
      "product_line_name": "Les Paul",
      "description": "The Gibson Les Paul Standard is a legendary solid-body electric guitar known for its iconic design, rich tone, and versatile playability, often considered the quintessential Les Paul."
    }
  ]
}
```

## Individual instruments search

### Search parameters

- serial_number: string (optional, but either serial_number or unknown_serial must be provided)
- unknown_serial: boolean (optional, but either serial_number or unknown_serial must be provided)
- model_name: string (optional, used when unknown_serial is true)
- manufacturer_name: string (optional, used when unknown_serial is true)
- year_estimate: integer (optional, used when unknown_serial is true)

### Considerations

- The search should be case-insensitive.
- The search should be fuzzy, so that if the user misspells the serial number or model name, it should still find possible matches.
- The search should be able to handle partial matches for serial numbers.
- The search should be able to handle multiple words in the model name.
- When searching by serial number, the endpoint should return individual guitars that match the serial number exactly or partially.
- When searching with unknown_serial=true, the endpoint should use model-related parameters (model_name, manufacturer_name, year_estimate) to find individual guitars that are related to matching models.
- The user may use the product line name to search for individual guitars. The endpoint should be able to handle this by trying to match the words in models.name and product_lines.name to the words in the search parameters.
- The model_name may include a year, and the endpoint should be able to handle this by identifying possible years in the model_name string and matching them to models.year.
- Individual guitars may have a model_id (linking to models table) or use manufacturer_name_fallback and model_name_fallback fields when the model is not in the database.

### Search Logic for Unknown Serial Number

When `unknown_serial=true` is provided:

1. **Model Matching**: First, find models that match the provided parameters (model_name, manufacturer_name, year_estimate) using the same fuzzy search logic as the model search endpoint.
2. **Individual Guitar Retrieval**: For each matching model, retrieve all individual guitars that:
   - Have `model_id` matching the found model's id, OR
   - Have `manufacturer_name_fallback` and `model_name_fallback` that match the search parameters
3. **Fallback Handling**: If no models are found but manufacturer_name and model_name parameters are provided, search for individual guitars with matching `manufacturer_name_fallback` and `model_name_fallback` fields.
4. **Deduplication**: Ensure no duplicate individual guitars are returned if they match multiple search criteria.

### Response

The endpoint should return a JSON object containing:

- list of individual guitars that match the search parameters
- for each individual guitar, the following fields:
  - id (from individual_guitars.id)
  - serial_number (from individual_guitars.serial_number)
  - year_estimate (from individual_guitars.year_estimate)
  - description (from individual_guitars.description)
  - significance_level (from individual_guitars.significance_level)
  - significance_notes (from individual_guitars.significance_notes)
  - current_estimated_value (from individual_guitars.current_estimated_value)
  - condition_rating (from individual_guitars.condition_rating)
  - model_name (from models.name where individual_guitars.model_id = models.id, or from individual_guitars.model_name_fallback if model_id is null)
  - manufacturer_name (from manufacturers.name where models.manufacturer_id = manufacturers.id, or from individual_guitars.manufacturer_name_fallback if model_id is null)
  - product_line_name (from product_lines.name where models.product_line_id = product_lines.id, only if model_id is not null)
- if no individual guitars match, return an empty list

### Example responses

#### Example 1: Search by known serial number
```json
{
  "individual_guitars": [
    {
      "id": "019820ad-be5e-7e78-af44-bec1e789f601",
      "serial_number": "9-0824",
      "year_estimate": null,
      "description": null,
      "significance_level": "historic",
      "significance_notes": "Famous 1959 Les Paul",
      "current_estimated_value": "500000.00",
      "condition_rating": null,
      "model_name": "Les Paul Standard",
      "manufacturer_name": "Gibson",
      "product_line_name": "Les Paul"
    }
  ]
}
```

#### Example 2: Search with unknown serial number
```json
{
  "individual_guitars": [
    {
      "id": "019820ad-be5e-7e78-af44-bec1e789f601",
      "serial_number": "9-0824",
      "year_estimate": null,
      "description": null,
      "significance_level": "historic",
      "significance_notes": "Famous 1959 Les Paul",
      "current_estimated_value": "500000.00",
      "condition_rating": null,
      "model_name": "Les Paul Standard",
      "manufacturer_name": "Gibson",
      "product_line_name": "Les Paul"
    },
    {
      "id": "019820ae-6753-7bde-99dd-5e47332a5255",
      "serial_number": "9-1647",
      "year_estimate": null,
      "description": null,
      "significance_level": "historic",
      "significance_notes": "Featured in 'The Beauty of the Burst' book, acquired from someone reluctant to sell",
      "current_estimated_value": "450000.00",
      "condition_rating": "excellent",
      "model_name": "Les Paul Standard",
      "manufacturer_name": "Gibson",
      "product_line_name": "Les Paul"
    },
    {
      "id": "01982952-37dd-7ea1-aba3-1f4ecc8092e7",
      "serial_number": "00247991",
      "year_estimate": null,
      "description": null,
      "significance_level": "notable",
      "significance_notes": "1976 'Centennial' model featuring special red, white and blue bird logo commemorating America's bicentennial year",
      "current_estimated_value": null,
      "condition_rating": null,
      "model_name": "Firebird III",
      "manufacturer_name": "Gibson",
      "product_line_name": "Firebird"
    }
  ]
}
```