# Simple Image Processor for Guitar Registry

A simplified image processing script that uploads images to Cloudinary and saves metadata to the Guitar Registry database.

## Quick Reference

```bash
# Basic upload
uv run python image_processor.py <image_file> <entity_type> <entity_id> [options]

# Examples
uv run python image_processor.py logo.png manufacturer 0197bdb2-23c1-72ad-b5b1-c77f67d4896c --image-type logo --is-primary
uv run python image_processor.py guitar.jpg model 0197bda6-49cb-7642-b812-b7b1c2af7824 --image-type primary --is-primary --caption "1954 Stratocaster"
uv run python image_processor.py serial.jpg individual_guitar 0197bda6-49cb-7642-b812-b7b1c2af7824 --image-type serial_number
```

## Setup

### 1. Install Dependencies

```bash
# Install required packages
pip install -r requirements-image.txt

# Or using uv
uv pip install -r requirements-image.txt
```

### 2. Set up Cloudinary

1. Sign up for a free Cloudinary account at https://cloudinary.com
2. Get your credentials from the Dashboard:
   - Cloud Name
   - API Key
   - API Secret

### 3. Create Configuration File

The script will automatically create a `cloudinary_config.json` template file on first run. Edit it with your credentials:

```json
{
  "cloudinary_cloud_name": "your_cloud_name",
  "cloudinary_api_key": "your_api_key",
  "cloudinary_api_secret": "your_api_secret"
}
```

## Usage

### Basic Image Upload

```bash
# Upload a manufacturer logo
uv run python image_processor.py fender-logo.png manufacturer 01982004-3a25-75cf-832c-552b20e8975f --image-type logo --is-primary --caption "Fender Logo"

# Upload a model image
uv run python image_processor.py stratocaster.jpg model 0197bda6-49cb-7642-b812-b7b1c2af7824 --image-type primary --is-primary --caption "1954 Stratocaster"

# Upload an individual guitar image
uv run python image_processor.py guitar-serial.jpg individual_guitar 0197bda6-49cb-7642-b812-b7b1c2af7824 --image-type serial_number --caption "Serial Number Detail"
```

### Create Duplicates

```bash
# Upload image and create duplicate for manufacturer
uv run python image_processor.py stratocaster.jpg model 0197bda6-49cb-7642-b812-b7b1c2af7824 \
  --image-type primary --is-primary --caption "1954 Stratocaster" \
  --create-duplicate "manufacturer:0197bdb2-23c1-72ad-b5b1-c77f67d4896c" \
  --duplicate-reason "Represents manufacturer as flagship example"
```

### Custom Configuration Files

```bash
# Use custom config files
uv run python image_processor.py image.jpg manufacturer 0197bdb2-23c1-72ad-b5b1-c77f67d4896c \
  --cloudinary-config my-cloudinary.json \
  --db-config my-database.json
```

### Command Line Options

**Required Arguments:**
- `image_path`: Path to the image file
- `entity_type`: Type of entity (manufacturer, model, individual_guitar, product_line, specification, finish, notable_association)
- `entity_id`: UUID of the entity

**Optional Arguments:**
- `--image-type`: Type of image (primary, logo, gallery, headstock, serial_number, body_front, body_back, neck, hardware, detail, certificate, documentation, historical)
- `--is-primary`: Set as primary image for the entity
- `--caption`: Image caption
- `--cloudinary-config`: Path to Cloudinary config file (default: cloudinary_config.json)
- `--db-config`: Path to database config file (default: db_config.json)
- `--create-duplicate`: Create duplicate for another entity (format: entity_type:entity_id)
- `--duplicate-reason`: Reason for creating duplicate

## Examples

### Upload Fender Logo

```bash
# Get Fender manufacturer ID
psql -d guitar_registry -c "SELECT id, name FROM manufacturers WHERE name LIKE '%Fender%';"

# Upload logo
uv run python simple_image_processor.py fender-logo.png manufacturer 0197bdb2-23c1-72ad-b5b1-c77f67d4896c \
  --image-type logo --is-primary --caption "Fender Musical Instruments Corporation Logo"
```

### Upload Stratocaster Image

```bash
# Get Stratocaster model ID
psql -d guitar_registry -c "SELECT id, name, year FROM models WHERE name = 'Stratocaster' AND year = 1954;"

# Upload image
uv run python simple_image_processor.py 1954-stratocaster.jpg model 0197bda6-49cb-7642-b812-b7b1c2af7824 \
  --image-type primary --is-primary --caption "1954 Fender Stratocaster - The Original"
```

### Upload Individual Guitar Image

```bash
# Get individual guitar ID
psql -d guitar_registry -c "SELECT id, serial_number FROM individual_guitars WHERE serial_number = '12345';"

# Upload serial number image
uv run python simple_image_processor.py serial-12345.jpg individual_guitar 0197bda6-49cb-7642-b812-b7b1c2af7824 \
  --image-type serial_number --caption "Serial Number: 12345"
```

### Create Duplicate for Manufacturer

```bash
# Upload model image and create duplicate for manufacturer
uv run python simple_image_processor.py stratocaster.jpg model 0197bda6-49cb-7642-b812-b7b1c2af7824 \
  --image-type primary --is-primary --caption "1954 Stratocaster" \
  --create-duplicate "manufacturer:0197bdb2-23c1-72ad-b5b1-c77f67d4896c" \
  --duplicate-reason "Represents manufacturer as flagship example"
```

## Features

- ✅ **Automatic image variants**: Creates thumbnail, small, medium, large, and xlarge versions
- ✅ **Metadata extraction**: Extracts dimensions, aspect ratio, dominant color, file size
- ✅ **Database integration**: Saves all metadata to PostgreSQL
- ✅ **Duplicate support**: Create duplicates for multiple entities (many-to-many)
- ✅ **Validation**: Ensures only one primary image per entity
- ✅ **Cloudinary integration**: Automatic upload with transformations
- ✅ **Error handling**: Comprehensive error checking and reporting

## Database Schema

The script works with the enhanced image schema that includes:

- `images` table with direct entity associations
- `image_sources` table for attribution
- Support for duplicates with `is_duplicate` and `original_image_id` fields
- Automatic primary image management
- Responsive image variants

## Troubleshooting

### Common Issues

1. **"Cloudinary upload failed"**: Check your Cloudinary credentials
2. **"Image file not found"**: Verify the image path is correct
3. **"Entity not found"**: Check the entity_type and entity_id are valid
4. **"Database connection failed"**: Verify database is running and credentials are correct

### Debug Mode

For more verbose output, you can modify the script to add debug logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

## Next Steps

After uploading images, you can:

1. **Query images**: Use the database functions to retrieve images
2. **Create more duplicates**: Use the `create_duplicate` function
3. **Add image sources**: Add attribution information to `image_sources` table
4. **Build UI**: Use the image URLs to display images in your application 