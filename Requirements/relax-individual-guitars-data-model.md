Here's a prompt you can pass to a Claude Code instance:

---

**Update the guitar registry database schema and validation system to support a hybrid foreign key + fallback text approach for individual guitars. This will allow adding guitars with incomplete model information while maintaining referential integrity when complete data is available.**

**Key Changes Needed:**

1. **Database Schema Updates (create.sql or create_no_extensions.sql):**
   - Make `model_id` optional in `individual_guitars` table (ALTER COLUMN model_id DROP NOT NULL)
   - Add fallback text fields: `manufacturer_name_fallback VARCHAR(100)`, `model_name_fallback VARCHAR(150)`, `year_estimate VARCHAR(50)`, `description TEXT`
   - Add constraint to ensure some identification exists (either model_id FK OR fallback manufacturer + (model OR description))
   - Update any indexes that might be affected

2. **JSON Schema Updates (uniqueness_management_system.py):**
   - Modify `INDIVIDUAL_GUITAR_SCHEMA` to make `model_reference` optional
   - Add optional fields: `manufacturer_name_fallback`, `model_name_fallback`, `year_estimate`, `description`
   - Update validation to ensure at least one identification method is provided

3. **Validator Logic Updates:**
   - Modify `validate_individual_guitar()` to handle both FK resolution and fallback scenarios
   - Update `find_individual_guitar_matches()` to work with both FK and text-based matching
   - Add logic to prefer FK resolution but gracefully fall back to text fields

4. **Processor Updates:**
   - Update `_insert_individual_guitar()` to handle the hybrid approach
   - Add helper method `_resolve_model_reference()` that tries FK resolution first, falls back to text
   - Update `_update_individual_guitar()` to handle both scenarios

5. **Sample Data Updates:**
   - Update the individual guitar sample JSON files to demonstrate both complete (FK) and incomplete (fallback) scenarios
   - Show examples of guitars with missing model info, unknown years, partial serial numbers

**Goals:**
- Maintain referential integrity when complete data is available
- Allow incomplete data via fallback text fields
- Enable progressive data enhancement (upgrading text to FKs later)
- Ensure efficient queries work for both scenarios
- Make the system more permissive while maintaining uniqueness detection

**Test the changes with the existing sample data to ensure backward compatibility and then create new test cases showing the fallback scenarios working.**