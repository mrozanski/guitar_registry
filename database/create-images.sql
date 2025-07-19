-- Image management tables for Guitar Registry - Enhanced MVP Version (Fixed)
-- Supports many-to-many relationships through duplicate entries with same storage asset
--
-- IMPORTANT: After running this script, you need to grant permissions:
-- GRANT ALL PRIVILEGES ON TABLE images TO guitar_registry_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO guitar_registry_user;

-- Image storage metadata table with direct entity associations
CREATE TABLE images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    
    -- Entity association (direct approach)
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    image_type VARCHAR(50) NOT NULL, -- primary, gallery, headstock, serial, detail, etc
    is_primary BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    caption TEXT,
    
    -- Storage information (shared across duplicates)
    storage_provider VARCHAR(50) NOT NULL DEFAULT 'cloudinary',
    storage_key VARCHAR(500) NOT NULL, -- This should be the same for all duplicates of an image
    original_url TEXT NOT NULL,
    
    -- Image variants (responsive images)
    thumbnail_url TEXT,
    small_url TEXT,      -- 400px wide
    medium_url TEXT,     -- 800px wide
    large_url TEXT,      -- 1600px wide
    xlarge_url TEXT,     -- 2400px wide
    
    -- Metadata
    original_filename VARCHAR(255),
    mime_type VARCHAR(100),
    file_size_bytes INTEGER CHECK (file_size_bytes > 0 AND file_size_bytes <= 10485760), -- Max 10MB
    width INTEGER CHECK (width > 0),
    height INTEGER CHECK (height > 0),
    
    -- Image characteristics
    aspect_ratio DECIMAL(5,3),
    dominant_color VARCHAR(7),
    
    -- Management
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP WITH TIME ZONE,
    access_count INTEGER DEFAULT 0,
    
    -- Validation and moderation
    is_validated BOOLEAN DEFAULT FALSE,
    validation_status VARCHAR(50) DEFAULT 'pending',
    validation_notes TEXT,
    validated_by UUID REFERENCES users(id),
    validated_at TIMESTAMP WITH TIME ZONE,
    
    -- Search and categorization
    tags TEXT[],
    description TEXT,
    
    -- Duplicate management
    is_duplicate BOOLEAN DEFAULT FALSE, -- Marks if this is a duplicate of another image
    original_image_id UUID REFERENCES images(id), -- Points to the "master" image record
    duplicate_reason TEXT, -- Why this duplicate exists (e.g., "represents manufacturer", "catalog display")
    
    -- Constraints
    CONSTRAINT valid_storage_provider CHECK (
        storage_provider IN ('cloudinary', 's3', 'vercel_blob', 'local', 'external')
    ),
    CONSTRAINT valid_mime_type CHECK (
        mime_type IN ('image/jpeg', 'image/png', 'image/webp', 'image/avif')
    ),
    CONSTRAINT valid_validation_status CHECK (
        validation_status IN ('pending', 'approved', 'rejected', 'flagged')
    ),
    CONSTRAINT valid_dominant_color CHECK (
        dominant_color ~ '^#[0-9A-Fa-f]{6}$'
    ),
    CONSTRAINT valid_url_format CHECK (
        original_url ~ '^https?://'
    ),
    CONSTRAINT valid_entity_type CHECK (
        entity_type IN ('manufacturer', 'product_line', 'model', 'individual_guitar', 
                       'specification', 'finish', 'notable_association')
    ),
    CONSTRAINT valid_image_type CHECK (
        image_type IN ('primary', 'logo', 'gallery', 'headstock', 'serial_number', 
                      'body_front', 'body_back', 'neck', 'hardware', 'detail', 
                      'certificate', 'documentation', 'historical')
    ),
    -- Prevent circular references in duplicates
    CONSTRAINT no_circular_duplicates CHECK (
        original_image_id IS NULL OR original_image_id != id
    )
);

-- Image sources for attribution
CREATE TABLE image_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    image_id UUID REFERENCES images(id) ON DELETE CASCADE,
    
    -- Source information
    source_type VARCHAR(50) NOT NULL,
    source_name VARCHAR(255),
    source_url TEXT,
    
    -- Attribution
    copyright_holder VARCHAR(255),
    license_type VARCHAR(50),
    attribution_required BOOLEAN DEFAULT TRUE,
    attribution_text TEXT,
    
    -- Legal and compliance
    usage_rights TEXT,
    expiration_date DATE,
    
    -- Reference to your existing data_sources table
    data_source_id UUID REFERENCES data_sources(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_source_type CHECK (
        source_type IN ('user_upload', 'web_scrape', 'api', 'book_scan', 'catalog')
    ),
    CONSTRAINT valid_license_type CHECK (
        license_type IN ('cc0', 'cc_by', 'cc_by_sa', 'copyright', 'fair_use', 'unknown')
    )
);

-- Indexes for performance
CREATE INDEX idx_images_entity ON images(entity_type, entity_id);
CREATE INDEX idx_images_type ON images(image_type);
CREATE INDEX idx_images_primary ON images(entity_type, entity_id) WHERE is_primary = TRUE;
CREATE INDEX idx_images_validation ON images(validation_status) WHERE validation_status != 'approved';
CREATE INDEX idx_images_uploaded_by ON images(uploaded_by);
CREATE INDEX idx_images_uploaded_at ON images(uploaded_at);
CREATE INDEX idx_images_storage_key ON images(storage_key);

-- Duplicate management indexes
CREATE INDEX idx_images_duplicates ON images(original_image_id) WHERE is_duplicate = TRUE;
CREATE INDEX idx_images_storage_duplicates ON images(storage_key, entity_type, entity_id);

-- Partial index for tags (only if tags exist)
CREATE INDEX idx_images_tags ON images USING gin(tags) WHERE array_length(tags, 1) > 0;

CREATE INDEX idx_image_sources_image ON image_sources(image_id);
CREATE INDEX idx_image_sources_type ON image_sources(source_type);

-- Utility views for common queries

-- Primary images for catalog display
CREATE VIEW catalog_images AS
SELECT 
    entity_type,
    entity_id,
    id as image_id,
    medium_url as display_url,
    thumbnail_url,
    caption
FROM images
WHERE is_primary = TRUE
  AND validation_status = 'approved'
  AND is_duplicate = FALSE; -- Only show original images, not duplicates

-- All images for a given entity with full details
CREATE OR REPLACE FUNCTION get_entity_images(
    p_entity_type VARCHAR,
    p_entity_id UUID
) RETURNS TABLE (
    image_id UUID,
    image_type VARCHAR,
    display_order INTEGER,
    urls JSONB,
    metadata JSONB,
    source JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.image_type,
        i.display_order,
        jsonb_build_object(
            'thumbnail', i.thumbnail_url,
            'small', i.small_url,
            'medium', i.medium_url,
            'large', i.large_url,
            'xlarge', i.xlarge_url,
            'original', i.original_url
        ) as urls,
        jsonb_build_object(
            'filename', i.original_filename,
            'dimensions', jsonb_build_object('width', i.width, 'height', i.height),
            'aspect_ratio', i.aspect_ratio,
            'size_bytes', i.file_size_bytes,
            'caption', i.caption,
            'tags', i.tags
        ) as metadata,
        jsonb_build_object(
            'type', s.source_type,
            'name', s.source_name,
            'attribution', s.attribution_text,
            'license', s.license_type
        ) as source
    FROM images i
    LEFT JOIN image_sources s ON s.image_id = i.id
    WHERE i.entity_type = p_entity_type
      AND i.entity_id = p_entity_id
      AND i.validation_status = 'approved'
    ORDER BY i.is_primary DESC, i.display_order, i.uploaded_at;
END;
$$ LANGUAGE plpgsql;

-- Function to create a duplicate image for another entity
CREATE OR REPLACE FUNCTION create_image_duplicate(
    p_original_image_id UUID,
    p_target_entity_type VARCHAR,
    p_target_entity_id UUID,
    p_image_type VARCHAR DEFAULT 'gallery',
    p_is_primary BOOLEAN DEFAULT FALSE,
    p_caption TEXT DEFAULT NULL,
    p_duplicate_reason TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_new_image_id UUID;
    v_original_image RECORD;
BEGIN
    -- Get the original image data
    SELECT * INTO v_original_image 
    FROM images 
    WHERE id = p_original_image_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Original image not found: %', p_original_image_id;
    END IF;
    
    -- If setting as primary, unset any existing primary for this entity
    IF p_is_primary THEN
        UPDATE images 
        SET is_primary = FALSE 
        WHERE entity_type = p_target_entity_type 
          AND entity_id = p_target_entity_id 
          AND is_primary = TRUE;
    END IF;
    
    -- Get next display order
    SELECT COALESCE(MAX(display_order), 0) + 1 
    INTO v_original_image.display_order
    FROM images 
    WHERE entity_type = p_target_entity_type 
      AND entity_id = p_target_entity_id;
    
    -- Create the duplicate
    INSERT INTO images (
        entity_type, entity_id, image_type, is_primary, display_order, caption,
        storage_provider, storage_key, original_url,
        thumbnail_url, small_url, medium_url, large_url, xlarge_url,
        original_filename, mime_type, file_size_bytes, width, height,
        aspect_ratio, dominant_color, uploaded_by, validation_status,
        tags, description, is_duplicate, original_image_id, duplicate_reason
    ) VALUES (
        p_target_entity_type, p_target_entity_id, p_image_type, p_is_primary, 
        v_original_image.display_order, COALESCE(p_caption, v_original_image.caption),
        v_original_image.storage_provider, v_original_image.storage_key, v_original_image.original_url,
        v_original_image.thumbnail_url, v_original_image.small_url, v_original_image.medium_url,
        v_original_image.large_url, v_original_image.xlarge_url,
        v_original_image.original_filename, v_original_image.mime_type, v_original_image.file_size_bytes,
        v_original_image.width, v_original_image.height,
        v_original_image.aspect_ratio, v_original_image.dominant_color, v_original_image.uploaded_by,
        v_original_image.validation_status,
        v_original_image.tags, v_original_image.description,
        TRUE, p_original_image_id, p_duplicate_reason
    ) RETURNING id INTO v_new_image_id;
    
    RETURN v_new_image_id;
END;
$$ LANGUAGE plpgsql;

-- Function to find all duplicates of an image
CREATE OR REPLACE FUNCTION get_image_duplicates(p_image_id UUID)
RETURNS TABLE (
    duplicate_id UUID,
    entity_type VARCHAR,
    entity_id UUID,
    image_type VARCHAR,
    is_primary BOOLEAN,
    caption TEXT,
    duplicate_reason TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.entity_type,
        i.entity_id,
        i.image_type,
        i.is_primary,
        i.caption,
        i.duplicate_reason
    FROM images i
    WHERE i.original_image_id = p_image_id
    ORDER BY i.entity_type, i.entity_id, i.display_order;
END;
$$ LANGUAGE plpgsql;

-- Function to find images by storage key (all duplicates)
CREATE OR REPLACE FUNCTION get_images_by_storage_key(p_storage_key VARCHAR)
RETURNS TABLE (
    image_id UUID,
    entity_type VARCHAR,
    entity_id UUID,
    image_type VARCHAR,
    is_primary BOOLEAN,
    is_duplicate BOOLEAN,
    original_image_id UUID,
    caption TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.entity_type,
        i.entity_id,
        i.image_type,
        i.is_primary,
        i.is_duplicate,
        i.original_image_id,
        i.caption
    FROM images i
    WHERE i.storage_key = p_storage_key
    ORDER BY i.is_duplicate, i.entity_type, i.entity_id, i.display_order;
END;
$$ LANGUAGE plpgsql;

-- Note: Trigger removed for simplified schema
-- The original trigger was designed for image_associations table
-- but we're using direct columns in images table for MVP
-- If you need access tracking, implement it at the application level

-- Add comments for documentation
COMMENT ON TABLE images IS 'Stores image metadata with direct entity associations, supports duplicates for many-to-many relationships';
COMMENT ON TABLE image_sources IS 'Tracks image sources and attribution requirements';
COMMENT ON VIEW catalog_images IS 'Simplified view for catalog display showing only primary approved images (no duplicates)';
COMMENT ON FUNCTION create_image_duplicate IS 'Creates a duplicate image record for another entity, sharing the same storage asset';
COMMENT ON FUNCTION get_image_duplicates IS 'Returns all duplicate images of a given original image';
COMMENT ON FUNCTION get_images_by_storage_key IS 'Returns all images (original and duplicates) that share the same storage key'; 