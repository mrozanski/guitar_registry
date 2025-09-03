# Year based models or not? 

This is more a to-do than a requirement, but I'm leaving it here for reference.

Just to confirm, this means the current schema we're using is considering guitar models unique on a year basis, correct? So for example, a Fender player II stratocaster MX 2023 and a
  Fender Player II stratocaster MX 2024 would have two separate records in the DB? I'm asking because I'm not sure yet about that approach if that was the acse, but I can be convinced.

⏺ Yes, that's exactly right. The current schema treats guitar models as unique per year. Looking at the database schema:

⏺ Read(database/create.sql)
  ⎿  Read 5 lines (ctrl+r to expand)

⏺ The UNIQUE(manufacturer_id, name, year) constraint at line 69 confirms this approach.

  Current Year-Based Model Approach

  Yes, your example is correct:
  - Fender Player II Stratocaster MX 2023 → One record
  - Fender Player II Stratocaster MX 2024 → Separate record

  Arguments For Year-Based Models:

  1. Spec Changes: Same model name often has different specs year-to-year
  2. Value Tracking: 2023 vs 2024 can have different market values
  3. Production Differences: Electronics, hardware often change
  4. Collector Relevance: Vintage guitar collectors care deeply about specific years
  5. Data Integrity: Prevents mixing specs from different production runs

  Arguments Against Year-Based Models:

  1. Data Bloat: Modern mass production creates many near-identical records
  2. User Confusion: "Player II Stratocaster" feels like one product line
  3. Maintenance Overhead: More records to manage and update
  4. Query Complexity: Finding "all Stratocasters" requires year ranges

  Alternative Approaches:

  Option A: Production Runs (Middle Ground)
  UNIQUE(manufacturer_id, name, production_start_year, production_end_year)

  Option B: Model Generations (Product-focused)
  UNIQUE(manufacturer_id, name, generation) -- where generation = "2023-2025"

  Option C: Keep Current (Vintage-focused)
  - Best for vintage/collectible guitars where year matters greatly
  - Less ideal for modern mass production

  My Recommendation:

  The year-based approach works well for this registry because:
  1. You're focusing on collectible/notable guitars where year precision matters
  2. The individual_guitars table handles the actual instruments
  3. Market valuation tracking benefits from year-specific models