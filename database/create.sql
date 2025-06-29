-- Guitar Registry - Electric Guitar Provenance and Authentication System
-- Copyright (C) 2025 Mariano Rozanski
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as published
-- by the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- See LICENSE file for full license text.

-- Guitar Database Schema - Without extension creation
-- Extensions must be installed by superuser beforehand

-- Manufacturers table
CREATE TABLE manufacturers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    founded_year INTEGER,
    website VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'defunct', 'acquired')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Product lines/series
CREATE TABLE product_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    manufacturer_id UUID REFERENCES manufacturers(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    introduced_year INTEGER,
    discontinued_year INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Models table
CREATE TABLE models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    manufacturer_id UUID REFERENCES manufacturers(id),
    product_line_id UUID REFERENCES product_lines(id),
    name VARCHAR(150) NOT NULL,
    year INTEGER NOT NULL,
    production_type VARCHAR(20) DEFAULT 'mass' CHECK (production_type IN ('mass', 'limited', 'custom', 'prototype', 'one-off')),
    production_start_date DATE,
    production_end_date DATE,
    estimated_production_quantity INTEGER,
    msrp_original DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(manufacturer_id, name, year)
);

-- Individual guitars table
CREATE TABLE individual_guitars (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    model_id UUID REFERENCES models(id),
    serial_number VARCHAR(50),
    production_date DATE,
    production_number INTEGER,
    significance_level VARCHAR(20) DEFAULT 'notable' CHECK (significance_level IN ('historic', 'notable', 'rare', 'custom')),
    significance_notes TEXT,
    current_estimated_value DECIMAL(12,2),
    last_valuation_date DATE,
    condition_rating VARCHAR(20) CHECK (condition_rating IN ('mint', 'excellent', 'very_good', 'good', 'fair', 'poor', 'relic')),
    modifications TEXT,
    provenance_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(serial_number)
);

-- Specifications table
CREATE TABLE specifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    model_id UUID REFERENCES models(id),
    individual_guitar_id UUID REFERENCES individual_guitars(id),
    body_wood VARCHAR(50),
    neck_wood VARCHAR(50),
    fingerboard_wood VARCHAR(50),
    scale_length_inches DECIMAL(4,2),
    num_frets INTEGER,
    nut_width_inches DECIMAL(3,2),
    neck_profile VARCHAR(50),
    bridge_type VARCHAR(50),
    pickup_configuration VARCHAR(20),
    pickup_brand VARCHAR(50),
    pickup_model VARCHAR(100),
    electronics_description TEXT,
    hardware_finish VARCHAR(50),
    body_finish VARCHAR(100),
    weight_lbs DECIMAL(4,2),
    case_included BOOLEAN DEFAULT FALSE,
    case_type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK ((model_id IS NOT NULL AND individual_guitar_id IS NULL) OR 
           (model_id IS NULL AND individual_guitar_id IS NOT NULL))
);

-- Colors and finishes
CREATE TABLE finishes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    model_id UUID REFERENCES models(id),
    individual_guitar_id UUID REFERENCES individual_guitars(id),
    finish_name VARCHAR(100) NOT NULL,
    finish_type VARCHAR(50),
    color_code VARCHAR(20),
    rarity VARCHAR(20) CHECK (rarity IN ('common', 'uncommon', 'rare', 'extremely_rare')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK ((model_id IS NOT NULL AND individual_guitar_id IS NULL) OR 
           (model_id IS NULL AND individual_guitar_id IS NOT NULL))
);

-- Notable owners/players
CREATE TABLE notable_associations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    individual_guitar_id UUID REFERENCES individual_guitars(id),
    person_name VARCHAR(100) NOT NULL,
    association_type VARCHAR(50),
    period_start DATE,
    period_end DATE,
    notable_songs TEXT,
    notable_performances TEXT,
    verification_status VARCHAR(20) DEFAULT 'unverified' CHECK (verification_status IN ('verified', 'likely', 'claimed', 'unverified')),
    verification_source TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Data sources and citations
CREATE TABLE data_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    source_name VARCHAR(100) NOT NULL,
    source_type VARCHAR(50),
    url VARCHAR(500),
    isbn VARCHAR(20),
    publication_date DATE,
    reliability_score INTEGER CHECK (reliability_score BETWEEN 1 AND 10),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Citations linking data to sources
CREATE TABLE citations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    source_id UUID REFERENCES data_sources(id),
    cited_table VARCHAR(50) NOT NULL,
    cited_record_id UUID NOT NULL,
    page_number INTEGER,
    section VARCHAR(100),
    confidence_level VARCHAR(20) CHECK (confidence_level IN ('high', 'medium', 'low')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Market data for tracking values over time
CREATE TABLE market_valuations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    model_id UUID REFERENCES models(id),
    individual_guitar_id UUID REFERENCES individual_guitars(id),
    valuation_date DATE NOT NULL,
    low_estimate DECIMAL(12,2),
    high_estimate DECIMAL(12,2),
    average_estimate DECIMAL(12,2),
    sale_price DECIMAL(12,2),
    sale_venue VARCHAR(100),
    condition_at_valuation VARCHAR(20),
    source_id UUID REFERENCES data_sources(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK ((model_id IS NOT NULL AND individual_guitar_id IS NULL) OR 
           (model_id IS NULL AND individual_guitar_id IS NOT NULL))
);

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    user_type VARCHAR(20) DEFAULT 'enthusiast' CHECK (user_type IN ('admin', 'curator', 'dealer', 'collector', 'enthusiast')),
    verified_expert BOOLEAN DEFAULT FALSE,
    expertise_areas TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User contributions tracking
CREATE TABLE contributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    user_id UUID REFERENCES users(id),
    contribution_type VARCHAR(50),
    table_name VARCHAR(50),
    record_id UUID,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance and uniqueness validation

-- Core business indexes for lookups and relationships
CREATE INDEX idx_models_manufacturer_year ON models(manufacturer_id, year);
CREATE INDEX idx_individual_guitars_model ON individual_guitars(model_id);
CREATE INDEX idx_specifications_model ON specifications(model_id);
CREATE INDEX idx_specifications_individual ON specifications(individual_guitar_id);
CREATE INDEX idx_citations_cited_record ON citations(cited_table, cited_record_id);
CREATE INDEX idx_market_valuations_date ON market_valuations(valuation_date);
CREATE INDEX idx_notable_associations_guitar ON notable_associations(individual_guitar_id);

-- Uniqueness and duplicate detection indexes
CREATE INDEX idx_manufacturers_name_lower ON manufacturers(LOWER(name));
CREATE INDEX idx_manufacturers_name_country ON manufacturers(LOWER(name), country);
CREATE INDEX idx_manufacturers_status ON manufacturers(status) WHERE status IS NOT NULL;

-- Models: for duplicate detection within manufacturer
CREATE INDEX idx_models_name_lower ON models(manufacturer_id, LOWER(name));
CREATE INDEX idx_models_manufacturer_name_year ON models(manufacturer_id, LOWER(name), year);
CREATE INDEX idx_models_year ON models(year);
CREATE INDEX idx_models_production_type ON models(production_type);

-- Product lines: for hierarchy navigation
CREATE INDEX idx_product_lines_manufacturer ON product_lines(manufacturer_id);
CREATE INDEX idx_product_lines_name_lower ON product_lines(manufacturer_id, LOWER(name));

-- Individual guitars: critical for uniqueness validation
CREATE UNIQUE INDEX idx_individual_guitars_serial_unique ON individual_guitars(serial_number) WHERE serial_number IS NOT NULL;
CREATE INDEX idx_individual_guitars_serial_lower ON individual_guitars(LOWER(serial_number)) WHERE serial_number IS NOT NULL;
CREATE INDEX idx_individual_guitars_production_date ON individual_guitars(production_date) WHERE production_date IS NOT NULL;
CREATE INDEX idx_individual_guitars_significance ON individual_guitars(significance_level);
CREATE INDEX idx_individual_guitars_model_production ON individual_guitars(model_id, production_date) WHERE production_date IS NOT NULL;

-- Trigram indexes for fuzzy text matching (if pg_trgm extension is available)
-- These will be skipped if pg_trgm is not installed
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
        CREATE INDEX idx_manufacturers_name_trgm ON manufacturers USING gin(name gin_trgm_ops);
        CREATE INDEX idx_models_name_trgm ON models USING gin(name gin_trgm_ops);
        CREATE INDEX idx_product_lines_name_trgm ON product_lines USING gin(name gin_trgm_ops);
    END IF;
END
$$;

-- Alternative pattern matching indexes (fallback for when pg_trgm is not available)
CREATE INDEX idx_manufacturers_name_pattern ON manufacturers(name varchar_pattern_ops);
CREATE INDEX idx_models_name_pattern ON models(name varchar_pattern_ops);
CREATE INDEX idx_product_lines_name_pattern ON product_lines(name varchar_pattern_ops);

-- Composite indexes for common query patterns
CREATE INDEX idx_models_full_lookup ON models(manufacturer_id, LOWER(name), year, production_type);
CREATE INDEX idx_individual_guitars_lookup ON individual_guitars(model_id, serial_number, production_date) WHERE serial_number IS NOT NULL;

-- Specifications: for filtering and searching
CREATE INDEX idx_specifications_body_wood ON specifications(body_wood) WHERE body_wood IS NOT NULL;
CREATE INDEX idx_specifications_neck_wood ON specifications(neck_wood) WHERE neck_wood IS NOT NULL;
CREATE INDEX idx_specifications_pickup_config ON specifications(pickup_configuration) WHERE pickup_configuration IS NOT NULL;
CREATE INDEX idx_specifications_year_range ON specifications(scale_length_inches, num_frets) WHERE scale_length_inches IS NOT NULL;

-- Finishes: for color/finish searches
CREATE INDEX idx_finishes_name_lower ON finishes(LOWER(finish_name));
CREATE INDEX idx_finishes_type ON finishes(finish_type) WHERE finish_type IS NOT NULL;
CREATE INDEX idx_finishes_rarity ON finishes(rarity) WHERE rarity IS NOT NULL;
CREATE INDEX idx_finishes_model ON finishes(model_id) WHERE model_id IS NOT NULL;
CREATE INDEX idx_finishes_individual ON finishes(individual_guitar_id) WHERE individual_guitar_id IS NOT NULL;

-- Notable associations: for searching by person/performer
CREATE INDEX idx_notable_associations_person_lower ON notable_associations(LOWER(person_name));
CREATE INDEX idx_notable_associations_type ON notable_associations(association_type);
CREATE INDEX idx_notable_associations_verification ON notable_associations(verification_status);
CREATE INDEX idx_notable_associations_period ON notable_associations(period_start, period_end) WHERE period_start IS NOT NULL;

-- Market valuations: for price analysis and trends
CREATE INDEX idx_market_valuations_model_date ON market_valuations(model_id, valuation_date) WHERE model_id IS NOT NULL;
CREATE INDEX idx_market_valuations_individual_date ON market_valuations(individual_guitar_id, valuation_date) WHERE individual_guitar_id IS NOT NULL;
CREATE INDEX idx_market_valuations_price_range ON market_valuations(average_estimate, valuation_date) WHERE average_estimate IS NOT NULL;
CREATE INDEX idx_market_valuations_venue ON market_valuations(sale_venue) WHERE sale_venue IS NOT NULL;

-- Data sources and citations: for tracking data lineage
CREATE INDEX idx_data_sources_type ON data_sources(source_type);
CREATE INDEX idx_data_sources_reliability ON data_sources(reliability_score) WHERE reliability_score IS NOT NULL;
CREATE INDEX idx_data_sources_date ON data_sources(publication_date) WHERE publication_date IS NOT NULL;
CREATE INDEX idx_citations_source ON citations(source_id);
CREATE INDEX idx_citations_confidence ON citations(confidence_level);

-- User management and contributions
CREATE INDEX idx_users_type ON users(user_type);
CREATE INDEX idx_users_verified ON users(verified_expert) WHERE verified_expert = true;
CREATE INDEX idx_contributions_user ON contributions(user_id);
CREATE INDEX idx_contributions_status ON contributions(status);
CREATE INDEX idx_contributions_type ON contributions(contribution_type);
CREATE INDEX idx_contributions_table_record ON contributions(table_name, record_id);

-- Partial indexes for active/current records
CREATE INDEX idx_manufacturers_active ON manufacturers(id, name) WHERE status = 'active' OR status IS NULL;
CREATE INDEX idx_models_current_production ON models(id, manufacturer_id, name) WHERE production_end_date IS NULL;
CREATE INDEX idx_individual_guitars_high_value ON individual_guitars(id, model_id) WHERE current_estimated_value > 10000;

-- Covering indexes for common read patterns
CREATE INDEX idx_models_with_details ON models(manufacturer_id, year) 
    INCLUDE (name, production_type, estimated_production_quantity, msrp_original);

CREATE INDEX idx_individual_guitars_with_value ON individual_guitars(model_id) 
    INCLUDE (serial_number, significance_level, current_estimated_value, condition_rating);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to tables that need them
CREATE TRIGGER update_manufacturers_updated_at BEFORE UPDATE ON manufacturers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_product_lines_updated_at BEFORE UPDATE ON product_lines FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_models_updated_at BEFORE UPDATE ON models FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_individual_guitars_updated_at BEFORE UPDATE ON individual_guitars FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notable_associations_updated_at BEFORE UPDATE ON notable_associations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();