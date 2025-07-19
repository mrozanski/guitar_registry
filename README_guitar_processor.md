# Guitar Processor JSON Input Structure

This document describes the JSON input structure expected by the Guitar Registry processor for different entity types.

## Complete Submission Structure

A complete submission requires these top-level properties:

```json
{
  "manufacturer": { ... },
  "model": { ... },
  "individual_guitar": { ... },
  "source_attribution": { ... }
}
```

## 1. Manufacturer

**Required fields:**
- `name` (string, 1-100 chars)

**Optional fields:**
- `country` (string, max 50 chars)
- `founded_year` (integer, 1800-2030)
- `website` (string, URI format)
- `status` (string, enum: "active", "defunct", "acquired", default: "active")
- `notes` (string)
- `logo_source` (string, file path or URL)

## 2. Model

**Required fields:**
- `manufacturer_name` (string)
- `name` (string, 1-150 chars)
- `year` (integer, 1900-2030)

**Optional fields:**
- `product_line_name` (string)
- `production_type` (string, enum: "mass", "limited", "custom", "prototype", "one-off", default: "mass")
- `production_start_date` (string, date format)
- `production_end_date` (string, date format)
- `estimated_production_quantity` (integer, min 1)
- `msrp_original` (number, min 0)
- `currency` (string, max 3 chars, default: "USD")
- `description` (string)
- `specifications` (object)
- `finishes` (array)

## 3. Individual Guitar

**Required fields (choose one of these three combinations):**

**Option A - Complete Model Reference:**
- `model_reference` (object)
  - `manufacturer_name` (string, required)
  - `model_name` (string, required)
  - `year` (integer, required)

**Option B - Fallback Manufacturer + Model:**
- `manufacturer_name_fallback` (string, max 100 chars, required)
- `model_name_fallback` (string, max 150 chars, required)

**Option C - Fallback Manufacturer + Description:**
- `manufacturer_name_fallback` (string, max 100 chars, required)
- `description` (string, required)

**Optional fields:**
- `year_estimate` (string, max 50 chars)
- `serial_number` (string, max 50 chars)
- `production_date` (string, date format)
- `production_number` (integer)
- `significance_level` (string, enum: "historic", "notable", "rare", "custom", default: "notable")
- `significance_notes` (string)
- `current_estimated_value` (number)
- `last_valuation_date` (string, date format)
- `condition_rating` (string, enum: "mint", "excellent", "very_good", "good", "fair", "poor", "relic")
- `modifications` (string)
- `provenance_notes` (string)
- `specifications` (object)
- `notable_associations` (array)
- `photos` (array)

## 4. Source Attribution

**Required fields:**
- `source_name` (string, 1-100 chars)

**Optional fields:**
- `source_type` (string, enum: "manufacturer_catalog", "auction_record", "museum", "book", "website", "manual_entry", "price_guide", default: "website")
- `url` (string, URI format, max 500 chars)
- `isbn` (string, max 20 chars)
- `publication_date` (string, date format)
- `reliability_score` (integer, 1-10)
- `notes` (string)

## 5. Specifications Object

**All fields optional:**
- `body_wood` (string, max 50 chars)
- `neck_wood` (string, max 50 chars)
- `fingerboard_wood` (string, max 50 chars)
- `scale_length_inches` (number, 20-30)
- `num_frets` (integer, 12-36)
- `nut_width_inches` (number, 1.0-2.5)
- `neck_profile` (string, max 50 chars)
- `bridge_type` (string, max 50 chars)
- `pickup_configuration` (string, max 20 chars)
- `pickup_brand` (string, max 50 chars)
- `pickup_model` (string, max 100 chars)
- `electronics_description` (string)
- `hardware_finish` (string, max 50 chars)
- `body_finish` (string, max 100 chars)
- `weight_lbs` (number, 1-20)
- `case_included` (boolean)
- `case_type` (string, max 50 chars)

## 6. Finish Object

**Required fields:**
- `finish_name` (string, 1-100 chars)

**Optional fields:**
- `finish_type` (string, max 50 chars)
- `color_code` (string, max 20 chars)
- `rarity` (string, enum: "common", "uncommon", "rare", "extremely_rare")

## 7. Notable Association Object

**Required fields:**
- `person_name` (string, 1-100 chars)
- `association_type` (string, enum: "owner", "player", "recorded_with", "performed_with", max 50 chars)

**Optional fields:**
- `period_start` (string, date format)
- `period_end` (string, date format)
- `notable_songs` (string)
- `notable_performances` (string)
- `verification_status` (string, enum: "verified", "likely", "claimed", "unverified", default: "unverified")
- `verification_source` (string)

## 8. Photo Object

**Required fields:**
- `source` (string, file path or URL)

**Optional fields:**
- `type` (string, enum: "body_front", "body_back", "headstock", "serial_number", "detail", "gallery", "logo", "catalog", "primary", "historical", default: "gallery")
- `caption` (string)
- `is_primary` (boolean, default: false)

## Data Types Summary

- **string**: Text values
- **integer**: Whole numbers
- **number**: Decimal numbers
- **boolean**: true/false values
- **object**: Nested JSON objects
- **array**: Lists of values
- **date format**: YYYY-MM-DD strings
- **URI format**: Valid URLs or file paths
- **enum**: Specific allowed string values

## Validation Rules

- String fields have maximum length limits
- Numeric fields have minimum/maximum value constraints
- Date fields must be in YYYY-MM-DD format
- URI fields must be valid URLs or file paths
- Enum fields must match exactly one of the specified values
- Required fields cannot be null or missing
- Optional fields can be null or omitted entirely 