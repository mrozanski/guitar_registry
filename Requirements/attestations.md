# Core Attestation Types to Implement

1. **Expert Reviews** (attached to one or more Models via many-to-many)
2. **Historical Events** (attached to Individual Guitars, extending existing notable_associations)

### Database Schema Extensions

#### 1. Expert Reviews Table (Many-to-Many Support)
```sql
-- Add to your existing schema
CREATE TABLE expert_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    reviewer_name VARCHAR(100) NOT NULL,
    reviewer_credentials TEXT,
    review_title VARCHAR(200) NOT NULL,
    review_summary TEXT NOT NULL,
    content_type VARCHAR(50) DEFAULT 'review' CHECK (content_type IN ('review', 'comparison', 'overview')),
    
    -- Ratings (optional for some content types)
    condition_rating INTEGER CHECK (condition_rating BETWEEN 1 AND 10),
    build_quality_rating INTEGER CHECK (build_quality_rating BETWEEN 1 AND 10),
    value_rating INTEGER CHECK (value_rating BETWEEN 1 AND 10),
    overall_rating INTEGER CHECK (overall_rating BETWEEN 1 AND 10),
    
    -- Attestation simulation fields
    original_content_url VARCHAR(500), -- YouTube/source URL
    content_archived BOOLEAN DEFAULT FALSE,
    content_hash VARCHAR(64), -- Simulated IPFS hash
    attestation_uid VARCHAR(66), -- Simulated EAS UID
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'disputed')),
    
    -- Metadata
    review_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Junction table for many-to-many model relationships
CREATE TABLE review_model_associations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    review_id UUID REFERENCES expert_reviews(id) ON DELETE CASCADE,
    model_id UUID REFERENCES models(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(review_id, model_id)
);

-- Indexes
CREATE INDEX idx_expert_reviews_reviewer ON expert_reviews(reviewer_name);
CREATE INDEX idx_expert_reviews_verification ON expert_reviews(verification_status);
CREATE INDEX idx_expert_reviews_type ON expert_reviews(content_type);
CREATE INDEX idx_review_model_associations_review ON review_model_associations(review_id);
CREATE INDEX idx_review_model_associations_model ON review_model_associations(model_id);
```

#### 2. Historical Events Table (Extension of notable_associations)
```sql
-- Extend existing notable_associations table
ALTER TABLE notable_associations ADD COLUMN event_type VARCHAR(50) DEFAULT 'ownership';
ALTER TABLE notable_associations ADD COLUMN event_title VARCHAR(200);
ALTER TABLE notable_associations ADD COLUMN event_description TEXT;
ALTER TABLE notable_associations ADD COLUMN event_date DATE;
ALTER TABLE notable_associations ADD COLUMN venue_name VARCHAR(200);
ALTER TABLE notable_associations ADD COLUMN recording_title VARCHAR(200);

-- Attestation simulation fields
ALTER TABLE notable_associations ADD COLUMN evidence_url VARCHAR(500);
ALTER TABLE notable_associations ADD COLUMN evidence_hash VARCHAR(64);
ALTER TABLE notable_associations ADD COLUMN attestation_uid VARCHAR(66);
ALTER TABLE notable_associations ADD COLUMN attestor_name VARCHAR(100);
ALTER TABLE notable_associations ADD COLUMN attestor_relationship VARCHAR(50);

-- Update check constraint to include new event types
ALTER TABLE notable_associations DROP CONSTRAINT IF EXISTS check_event_type;
ALTER TABLE notable_associations ADD CONSTRAINT check_event_type 
    CHECK (event_type IN ('ownership', 'performance', 'recording', 'tv_appearance', 'photo_session', 'auction'));
```
