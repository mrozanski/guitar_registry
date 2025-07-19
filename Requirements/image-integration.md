# Image Integration Strategy: Hybrid URL/Local File Support

## Overview

This document outlines the strategy for integrating image processing with the guitar registry system, supporting both remote URLs and local file paths (absolute and relative) within the same data processing workflow.

## Core Approach: Two-Phase Processing

### Phase 1: Entity Creation (Existing Process)
1. Process guitar data through existing `GuitarDataProcessor`
2. Create/resolve manufacturer → product_line → model → individual_guitar entities
3. Return entity IDs for use in Phase 2

### Phase 2: Image Processing (New Integration)
1. Extract photo URLs/paths from input JSON
2. Process images using enhanced `GuitarImageProcessor`
3. Create associations using direct schema approach

## Enhanced JSON Schema

Support both URLs and local file paths with unified structure:

```json
{
  "individual_guitar": {
    // existing fields...
    "photos": [
      {
        "source": "https://example.com/guitar-front.jpg",  // URL
        "type": "body_front",
        "caption": "Front view of Jessica", 
        "is_primary": true
      },
      {
        "source": "/path/to/local/serial-number.jpg",  // Local file
        "type": "serial_number",
        "caption": "Serial number close-up"
      },
      {
        "source": "relative/path/headstock.png",  // Relative to working dir
        "type": "headstock"
      }
    ]
  },
  "manufacturer": {
    // existing fields...
    "logo_source": "/logos/gibson-official.png"  // Can be URL or file path
  }
}
```

## Implementation Details

### Enhanced Image Processor

Update `image-processing-module.py:123-133` to handle both sources uniformly:

```python
def _load_image(self, source: str) -> Tuple[bytes, str]:
    """Load image from URL or file path (absolute/relative)"""
    if source.startswith(('http://', 'https://')):
        # Existing URL handling
        response = requests.get(source, timeout=30)
        response.raise_for_status()
        filename = source.split('/')[-1]
        return response.content, filename
    else:
        # File path handling (absolute or relative)
        file_path = Path(source)
        if not file_path.is_absolute():
            # Resolve relative paths from current working directory
            file_path = Path.cwd() / file_path
        
        if not file_path.exists():
            raise FileNotFoundError(f"Image file not found: {file_path}")
        
        with open(file_path, 'rb') as f:
            return f.read(), file_path.name
```

### Source Type Detection & Validation

```python
class ImageSourceValidator:
    """Validates and categorizes image sources"""
    
    @staticmethod
    def categorize_source(source: str) -> str:
        """Determine source type: url, absolute_path, or relative_path"""
        if source.startswith(('http://', 'https://')):
            return 'url'
        elif Path(source).is_absolute():
            return 'absolute_path'
        else:
            return 'relative_path'
    
    @staticmethod
    def validate_source(source: str, base_dir: Optional[Path] = None) -> bool:
        """Validate that source is accessible"""
        source_type = ImageSourceValidator.categorize_source(source)
        
        if source_type == 'url':
            try:
                response = requests.head(source, timeout=10)
                return response.status_code == 200
            except:
                return False
        else:
            file_path = Path(source)
            if not file_path.is_absolute():
                base = base_dir or Path.cwd()
                file_path = base / file_path
            return file_path.exists() and file_path.is_file()
```

### Enhanced Processing Workflow

```python
def process_guitar_with_photos(guitar_data, working_dir=None):
    """Process guitar data with support for URL and local file images"""
    
    with db_transaction():
        # Phase 1: Create entities (unchanged)
        entity_ids = processor.process_guitar_data(guitar_data)
        
        # Phase 2: Process mixed image sources
        for entity_type in ['manufacturer', 'product_line', 'model', 'individual_guitar']:
            if entity_type in entity_ids and entity_ids[entity_type]:
                photos = extract_photos_for_entity(guitar_data, entity_type)
                
                for photo_spec in photos:
                    try:
                        # Validate source accessibility
                        if not ImageSourceValidator.validate_source(
                            photo_spec['source'], Path(working_dir) if working_dir else None
                        ):
                            print(f"⚠ Skipping inaccessible image: {photo_spec['source']}")
                            continue
                        
                        # Process image (handles URLs and files uniformly)
                        processed_image = image_processor.process_image(
                            photo_spec['source'],
                            entity_type,
                            entity_ids[entity_type],
                            photo_spec.get('type', 'gallery'),
                            source_info={
                                'source_type': ImageSourceValidator.categorize_source(photo_spec['source']),
                                'original_path': photo_spec['source']
                            }
                        )
                        
                        # Save to database with enhanced metadata
                        save_image_to_db(processed_image, entity_ids, photo_spec)
                        
                    except Exception as e:
                        print(f"✗ Error processing image {photo_spec['source']}: {e}")
                        # Continue with other images rather than failing entire batch

def extract_photos_for_entity(guitar_data, entity_type):
    """Extract photo specifications for a given entity type"""
    photos = []
    
    if entity_type == 'manufacturer' and 'manufacturer' in guitar_data:
        if 'logo_source' in guitar_data['manufacturer']:
            photos.append({
                'source': guitar_data['manufacturer']['logo_source'],
                'type': 'logo',
                'is_primary': True
            })
    
    elif entity_type == 'individual_guitar' and 'individual_guitar' in guitar_data:
        if 'photos' in guitar_data['individual_guitar']:
            photos.extend(guitar_data['individual_guitar']['photos'])
    
    return photos
```

### CLI Integration

Update `guitar_processor_cli.py` to support working directory context:

```python
def process_file(self, file_path: str):
    """Process guitar data file with support for relative image paths"""
    
    # Establish working directory context from input file location
    working_dir = Path(file_path).parent
    
    guitar_data = self.load_json_file(file_path)
    if not guitar_data:
        return False
    
    try:
        # Pass working directory for relative path resolution
        results = process_guitar_with_photos(guitar_data, working_dir)
        
        if self.verbose:
            print(f"✓ Processed {len(results.get('images', []))} images")
            
        return True
        
    except Exception as e:
        print(f"✗ Processing failed: {e}")
        return False
```

## Key Benefits

1. **Unified Processing**: Single `process_image()` method handles both URLs and files
2. **Path Resolution**: Automatic resolution of relative paths from input file location
3. **Source Tracking**: Full attribution of image origins (URL vs file path)
4. **Validation**: Pre-processing validation to avoid processing inaccessible sources
5. **Graceful Degradation**: Individual image failures don't break entire batch
6. **Working Directory Context**: Relative paths resolved from input file location
7. **Non-breaking**: Existing guitar processing works unchanged
8. **Entity-first**: Guarantees valid UUIDs before image processing
9. **Transactional**: All-or-nothing processing prevents orphaned records
10. **Flexible**: Supports photos on any entity type (manufacturer logos, model catalogs, etc.)

## Database Impact

The existing schema (`database/create.sql:246-331`) already supports this approach with the `images` table using direct entity associations. No schema changes needed.

## Example Usage Scenarios

```bash
# Mixed sources with relative paths resolved from JSON file location
python guitar_processor_cli.py --file /data/slash_collection.json

# Where slash_collection.json contains:
{
  "individual_guitar": {
    "photos": [
      {"source": "https://example.com/remote.jpg", "type": "primary"},
      {"source": "./local-images/serial.jpg", "type": "serial_number"},
      {"source": "/absolute/path/headstock.png", "type": "headstock"}
    ]
  }
}
```

## Processing Order

```
1. Validate JSON schema (including photo specifications)
2. Process entities (manufacturer → product_line → model → individual_guitar)
3. Extract entity IDs from processing results
4. For each entity with photos:
   a. Validate image source accessibility
   b. Process image (fetch/load + transform + upload to Cloudinary)
   c. Store image metadata in database
   d. Create entity-image associations
5. Commit transaction or rollback on any failure
```

This approach provides maximum flexibility while maintaining the existing processor's robustness and the image system's deduplication capabilities.