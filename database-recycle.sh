#!/bin/bash

# Database Recreation Script
# Based on database-recycle.md

set -e  # Exit on any error

echo "🔄 Starting database recreation process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if database exists and drop it
echo "📋 Step 1: Dropping existing database (if it exists)..."
if psql -d postgres -c "SELECT 1 FROM pg_database WHERE datname='guitar_registry';" | grep -q 1; then
    print_warning "Database 'guitar_registry' exists. Dropping it..."
    psql -d postgres -c "DROP DATABASE guitar_registry;" || {
        print_error "Failed to drop database. Make sure no connections are active."
        exit 1
    }
    print_status "Database dropped successfully"
else
    print_status "Database 'guitar_registry' does not exist (no need to drop)"
fi

# Create new database
echo "📋 Step 2: Creating new database..."
psql -d postgres -c "CREATE DATABASE guitar_registry OWNER guitar_registry_user;" || {
    print_error "Failed to create database"
    exit 1
}
print_status "Database created successfully"

# Grant privileges
echo "📋 Step 3: Granting privileges..."
psql -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE guitar_registry TO guitar_registry_user;" || {
    print_error "Failed to grant database privileges"
    exit 1
}
psql -U guitar_registry_user -d guitar_registry -c "GRANT ALL PRIVILEGES ON SCHEMA public TO guitar_registry_user;" || {
    print_error "Failed to grant schema privileges"
    exit 1
}
print_status "Privileges granted successfully"

# Create extensions
echo "📋 Step 4: Creating extensions..."
psql -U guitar_registry_user -d guitar_registry -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" || {
    print_error "Failed to create uuid-ossp extension"
    exit 1
}
psql -d guitar_registry -c "CREATE EXTENSION IF NOT EXISTS \"pg_uuidv7\";" || {
    print_error "Failed to create pg_uuidv7 extension (requires superuser privileges)"
    exit 1
}
psql -U guitar_registry_user -d guitar_registry -c "CREATE EXTENSION IF NOT EXISTS \"pg_trgm\";" || {
    print_error "Failed to create pg_trgm extension"
    exit 1
}
print_status "Extensions created successfully"

# Create structure
echo "📋 Step 5: Creating database structure..."
if [ -f "database/create.sql" ]; then
    psql -U guitar_registry_user -d guitar_registry -f database/create.sql || {
        print_error "Failed to create database structure"
        exit 1
    }
    print_status "Database structure created successfully"
else
    print_error "database/create.sql file not found!"
    exit 1
fi

# Verify the setup
echo "📋 Step 6: Verifying database setup..."
TABLE_COUNT=$(psql -U guitar_registry_user -d guitar_registry -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)
print_status "Database contains $TABLE_COUNT tables"

# Show table list
echo "📋 Tables created:"
psql -U guitar_registry_user -d guitar_registry -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;" || {
    print_warning "Could not list tables (this is not critical)"
}

# Verify all tables are empty
echo "📋 Verifying all tables are empty..."
EMPTY_TABLES=$(psql -U guitar_registry_user -d guitar_registry -t -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;" | xargs)

for table in $EMPTY_TABLES; do
    COUNT=$(psql -U guitar_registry_user -d guitar_registry -t -c "SELECT COUNT(*) FROM $table;" | xargs)
    if [ "$COUNT" -eq 0 ]; then
        print_status "$table: $COUNT rows"
    else
        print_warning "$table: $COUNT rows (should be 0)"
    fi
done

echo ""
print_status "🎉 Database recreation completed successfully!"
echo ""
echo "Next steps:"
echo "1. Run your data processing scripts"
echo "2. Or import data using: psql -U guitar_registry_user -d guitar_registry -f your_data_file.sql"
echo "" 