# Database re-creation

## Drop database
```
psql -d postgres -c "DROP database guitar_registry;
```

## Create database
```
psql -d postgres -c "CREATE DATABASE guitar_registry OWNER guitar_registry_user;"
```

## Grant privileges
```
psql -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE guitar_registry TO guitar_registry_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO guitar_registry_user;"
```

## Create extensions
```
psql -U guitar_registry_user -d guitar_registry -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
psql -d guitar_registry -c "CREATE EXTENSION IF NOT EXISTS \"pg_uuidv7\";"
```

## Create structure
```
psql -U guitar_registry_user -d guitar_registry -f database/create.sql
```

Recommended: use the comprehensive shell script `database-recycle.sh` to create the database and structure.
It will give you a completely clean, consistent database ready for processing your JSON data.

Here's what the script does:

## **🔄 Database Recreation Script Features:**

### **✅ Complete Automation:**
1. **Drops existing database** (if it exists)
2. **Creates new database** with proper ownership
3. **Grants all privileges** to `guitar_registry_user`
4. **Creates all required extensions** (uuid-ossp, pg_uuidv7, pg_trgm)
5. **Runs the structure creation** from `database/create.sql`
6. **Verifies the setup** and confirms all tables are empty

### **✅ Safety Features:**
- **Error handling** - Exits on any error with clear messages
- **Colored output** - Easy to read status messages
- **Verification steps** - Confirms each step completed successfully
- **Table count verification** - Ensures all tables are created and empty

### **✅ Usage:**
```bash
# Run the script
./database-recycle.sh
```

### **✅ What You'll See:**
- Step-by-step progress with colored status messages
- Confirmation that all tables are created and empty
- Clear next steps for data processing


