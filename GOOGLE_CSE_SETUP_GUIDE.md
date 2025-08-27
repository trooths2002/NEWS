# Google Custom Search Engine Setup Guide

## ✅ Step 1: API Key Ready
Your Google API key is configured: `AIzaSyB8yvuzAdDx1GDsdRp4ulReaC7Y9BTEBdw`

## 🎯 Step 2: Create Custom Search Engine

### A. Go to Google CSE Control Panel
1. Visit: https://cse.google.com/cse/
2. Click "Add" or "New Search Engine"

### B. Configure Your Search Engine

**Basic Settings:**
- **Sites to search**: Leave blank to search the entire web
- **Name**: "Geopolitical Image Search"
- **Language**: English

**Advanced Settings:**
- **Search Engine ID**: Copy this after creation (needed for GOOGLE_CSE_ID)
- **Search Type**: 
  - ✅ **Enable "Image Search"** (CRITICAL)
  - Enable "Safe Search" (Recommended)

### C. Customize for Image Search
1. After creation, click "Control Panel"
2. Go to "Setup" → "Basics"
3. Under "Image Search", select **"ON"**
4. Under "Search the entire web", select **"ON"**

### D. Get Your Search Engine ID
1. In Control Panel → "Setup" → "Basics"
2. Copy the **Search Engine ID** (format: `abc123:def456`)
3. Add it to your `.env` file as `GOOGLE_CSE_ID`

## 🔧 Step 3: Update Configuration

Edit `c:\Users\tjd20.LAPTOP-PCMC2SUO\news\.env`:
```
GOOGLE_API_KEY=AIzaSyB8yvuzAdDx1GDsdRp4ulReaC7Y9BTEBdw
GOOGLE_CSE_ID=YOUR_SEARCH_ENGINE_ID_HERE
```

## 🧪 Step 4: Test Integration

### Quick Test Script:
```powershell
# Test Google Images API integration
curl -X POST http://localhost:3007/mcp -H "Content-Type: application/json" -d '{
    "method": "tools/call",
    "params": {
        "name": "search_related_images",
        "keywords": "African politics election democracy",
        "sources": ["google_images"],
        "region": "african"
    }
}'
```

### Enhanced Test:
```powershell
# Test enhanced image scraping with Google API
curl -X POST http://localhost:3007/api/enhanced-scrape-images -H "Content-Type: application/json" -d '{
    "strategy": "api_search", 
    "limit": 3, 
    "includeRelated": true
}'
```

## 📊 Expected Results

With your API key and CSE ID configured, you should see:

✅ **Success Response:**
```json
{
  "success": true,
  "strategy": "api_search",
  "totalProcessed": 3,
  "successful": 2,
  "images": [
    {
      "url": "https://example.com/image1.jpg",
      "title": "African Election Image",
      "source": "google_images",
      "thumbnail": "https://example.com/thumb1.jpg"
    }
  ]
}
```

❌ **Error if CSE ID missing:**
```
🔑 Google API credentials not configured
```

## 🚀 Next Steps After Setup

1. **Test Google Integration**: Use the test scripts above
2. **Add More APIs**: Get Bing and News API keys for full integration
3. **Production Deployment**: Configure rate limits and monitoring

## 📈 API Quota Information

**Free Tier Limits:**
- **100 search queries per day**
- **10,000 queries per month** (with billing enabled)

**Usage Monitoring:**
- Monitor usage at: https://console.developers.google.com/apis/dashboard
- Track quota: Google Custom Search API → Quotas

## 🔍 Troubleshooting

**Common Issues:**
1. **"Image search not enabled"** → Enable image search in CSE settings
2. **"Invalid API key"** → Verify key in Google Console
3. **"Search engine not found"** → Check CSE ID format

**Verification Commands:**
```powershell
# Check if .env file is loaded
node -e "require('dotenv').config(); console.log('API Key:', process.env.GOOGLE_API_KEY ? 'Loaded' : 'Missing');"

# Test API key directly
curl "https://www.googleapis.com/customsearch/v1?key=AIzaSyB8yvuzAdDx1GDsdRp4ulReaC7Y9BTEBdw&cx=YOUR_CSE_ID&q=test"
```

Complete these steps and your Google Images integration will be fully operational!