# Image Scraping Workflow for Geopolitical Intelligence

## Overview

The Geopolitical Intelligence Server now includes a comprehensive image scraping workflow that automatically collects images from captured headlines and related articles. This visual intelligence capability enhances the existing news analysis with supporting imagery for better context and documentation.

## Features

### 🖼️ Image Collection Sources
- **RSS Enclosures**: Images directly attached to RSS feed items
- **Article Content**: Images embedded within article descriptions and content
- **Web Scraping**: Images extracted from full article pages using advanced selectors
- **Multiple Formats**: Support for JPG, JPEG, PNG, WebP, and GIF formats

### 🗂️ Regional Categorization
Images are automatically organized by regional focus:
- `images/regional/african/` - African political and news imagery
- `images/regional/caribbean/` - Caribbean regional content
- `images/regional/afro-latino/` - Afro-Latino community imagery
- `images/headlines/` - General geopolitical imagery

### 📊 Metadata Management
- **Article Association**: Each image linked to source article with metadata
- **Relevance Scoring**: Images inherit relevance scores from parent articles
- **Category Tagging**: Regional and disciplinary categorization preserved
- **JSON Storage**: Comprehensive metadata stored for easy retrieval

## API Endpoints

### Direct Image Scraping
```http
POST /api/scrape-images
Content-Type: application/json

{
  "limit": 10  // Optional: Number of articles to process (default: 10, max: 20)
}
```

**Response:**
```json
{
  "success": true,
  "totalProcessed": 10,
  "successful": 8,
  "skipped": 2,
  "images": [
    {
      "articleId": "abc123def456",
      "title": "Article Title",
      "link": "https://example.com/article",
      "categories": ["african", "politicalScience"],
      "images": [
        {
          "url": "https://example.com/image.jpg",
          "type": "rss_enclosure",
          "description": "Article image",
          "localPath": "images/regional/african/abc123def456_12345678_rss_enclosure.jpg",
          "fileName": "abc123def456_12345678_rss_enclosure.jpg",
          "fileSize": 245760,
          "downloadedAt": "2025-08-26T10:30:00.000Z"
        }
      ],
      "scrapedAt": "2025-08-26T10:30:00.000Z",
      "relevanceScore": 7.5
    }
  ]
}
```

## MCP Tools

### 1. scrape_article_images
Scrape images from captured headlines with optional filtering.

**Parameters:**
- `limit` (number, 1-20): Number of articles to process
- `region` (string): Filter by region - 'african', 'caribbean', 'afroLatino', or 'all'

**Example Usage:**
```json
{
  "method": "tools/call",
  "params": {
    "name": "scrape_article_images",
    "limit": 5,
    "region": "caribbean"
  }
}
```

### 2. get_image_metadata
Retrieve metadata and statistics about scraped images.

**Parameters:**
- `date` (string, YYYY-MM-DD): Date to retrieve metadata for
- `region` (string): Filter by region

**Example Usage:**
```json
{
  "method": "tools/call",
  "params": {
    "name": "get_image_metadata",
    "date": "2025-08-26",
    "region": "all"
  }
}
```

## Technical Implementation

### Rate Limiting & Ethics
- **1-second delays** between requests to respect source servers
- **User-Agent rotation** to appear as legitimate browser requests
- **Reasonable limits** (2 images per article, 10 articles maximum per run)
- **Error handling** for network timeouts and invalid URLs

### File Organization
```
images/
├── headlines/              # General political imagery
├── thumbnails/             # Thumbnail versions (future enhancement)
├── articles/               # Full article screenshots (future enhancement)
└── regional/
    ├── african/            # African regional imagery
    ├── caribbean/          # Caribbean regional imagery
    └── afro-latino/        # Afro-Latino imagery

trending-intelligence/
└── images/
    └── image-metadata-YYYY-MM-DD.json  # Daily metadata files
```

### Filename Convention
Images are saved with unique, collision-resistant filenames:
```
{articleId}_{urlHash}_{imageType}.{extension}
```

Example: `abc123def456_12345678_rss_enclosure.jpg`

- **articleId**: MD5 hash of article title + URL (12 chars)
- **urlHash**: MD5 hash of image URL (8 chars)  
- **imageType**: Source type (rss_enclosure, content_image, scraped_image)
- **extension**: Original image format

### Metadata Structure
Each daily metadata file contains:
```json
{
  "date": "2025-08-26",
  "totalArticles": 8,
  "totalImages": 15,
  "articles": [
    {
      "articleId": "abc123def456",
      "title": "Article Title",
      "link": "https://example.com/article", 
      "categories": ["african", "politicalScience"],
      "images": [...],
      "scrapedAt": "2025-08-26T10:30:00.000Z",
      "relevanceScore": 7.5
    }
  ],
  "generatedAt": "2025-08-26T10:30:00.000Z"
}
```

## Integration with Existing Workflow

The image scraping workflow seamlessly integrates with the existing geopolitical intelligence pipeline:

1. **News Collection**: Headlines fetched from RSS sources
2. **Analysis & Scoring**: Articles categorized and scored for relevance
3. **Image Extraction**: Top articles processed for image collection
4. **Storage & Metadata**: Images saved with regional categorization
5. **Reporting**: Image statistics included in daily intelligence reports

## Usage Examples

### PowerShell Testing
```powershell
# Test image scraping
$response = Invoke-RestMethod -Uri "http://localhost:3007/api/scrape-images" -Method Post -Body '{"limit": 5}' -ContentType "application/json"

# Check results
Write-Host "Processed: $($response.totalProcessed) articles"
Write-Host "Images collected: $($response.successful)"
```

### MCP Integration
```bash
# Using curl to test MCP tools
curl -X POST http://localhost:3007/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "method": "tools/call",
    "params": {
      "name": "scrape_article_images",
      "limit": 10,
      "region": "african"
    }
  }'
```

## Future Enhancements

### Planned Features
- **Image Analysis**: AI-powered image content analysis and tagging
- **Thumbnail Generation**: Automatic thumbnail creation for faster loading
- **Duplicate Detection**: Advanced deduplication based on image content
- **Archive Management**: Automatic cleanup of old images
- **Visual Search**: Search images by content similarity
- **OCR Integration**: Extract text from images for additional analysis

### Performance Optimizations
- **Parallel Processing**: Concurrent image downloads with queue management
- **Caching**: Image URL validation caching to avoid re-downloads
- **Compression**: Automatic image optimization for storage efficiency
- **CDN Integration**: Optional integration with content delivery networks

## Troubleshooting

### Common Issues

**No images found:**
- RSS feeds may not include image enclosures
- Article pages may use JavaScript-loaded images
- Images may be behind authentication

**Download failures:**
- Network timeouts (automatically handled with retries)
- Invalid image URLs (filtered during extraction)
- Server blocking requests (user-agent rotation helps)

**Storage issues:**
- Check disk space availability
- Verify directory permissions
- Ensure unique filename generation working

### Monitoring

Check the server logs for:
- `🖼️` Image scraping workflow messages
- `📸` Individual article processing status
- `💾` Successful image downloads
- `❌` Error messages with detailed explanations

## Security Considerations

- **No Authentication Bypass**: Only publicly accessible images are collected
- **Respectful Scraping**: Rate limiting prevents server overload
- **Legal Compliance**: Only collects images for analytical purposes
- **Data Privacy**: No personal information collected from images
- **Storage Security**: Local storage only, no cloud uploads

## Performance Metrics

Typical performance for image scraping workflow:
- **Processing Speed**: ~5-10 articles per minute
- **Success Rate**: 60-80% (varies by source image availability)
- **Average Images per Article**: 1-2 images
- **File Sizes**: 50KB - 2MB per image
- **Storage Growth**: ~10-50MB per day of operation

The image scraping workflow significantly enhances the geopolitical intelligence system by providing visual context to captured headlines, supporting more comprehensive analysis and reporting capabilities.