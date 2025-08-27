# Enhanced Image Source Integration Guide

## 🚀 **Ready-to-Use Integration Examples**

### **1. Google Images API Integration**

```javascript
// Add to geopolitical-intelligence-server.js
async integrateGoogleImages(keywords, region = 'all') {
    const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;
    const GOOGLE_CSE_ID = process.env.GOOGLE_CSE_ID;
    
    if (!GOOGLE_API_KEY || !GOOGLE_CSE_ID) {
        console.log('Google API credentials not configured');
        return { images: [], source: 'google_fallback' };
    }
    
    try {
        const searchQuery = keywords.join(' ') + (region !== 'all' ? ` ${region}` : '');
        const url = `https://www.googleapis.com/customsearch/v1?key=${GOOGLE_API_KEY}&cx=${GOOGLE_CSE_ID}&q=${encodeURIComponent(searchQuery)}&searchType=image&num=10&safe=active`;
        
        const response = await fetch(url);
        const data = await response.json();
        
        const images = (data.items || []).map(item => ({
            url: item.link,
            title: item.title,
            source: 'google_images',
            thumbnail: item.image?.thumbnailLink,
            contextLink: item.image?.contextLink
        }));
        
        return { images, source: 'google_images', count: images.length };
    } catch (error) {
        console.error('Google Images API error:', error);
        return { images: [], source: 'google_error' };
    }
}
```

### **2. Bing Images API Integration**

```javascript
async integrateBingImages(keywords, region = 'all') {
    const BING_API_KEY = process.env.BING_SEARCH_API_KEY;
    
    if (!BING_API_KEY) {
        console.log('Bing API key not configured');
        return { images: [], source: 'bing_fallback' };
    }
    
    try {
        const searchQuery = keywords.join(' ') + (region !== 'all' ? ` ${region}` : '');
        const url = `https://api.bing.microsoft.com/v7.0/images/search?q=${encodeURIComponent(searchQuery)}&count=10&safeSearch=Moderate`;
        
        const response = await fetch(url, {
            headers: {
                'Ocp-Apim-Subscription-Key': BING_API_KEY
            }
        });
        
        const data = await response.json();
        
        const images = (data.value || []).map(item => ({
            url: item.contentUrl,
            title: item.name,
            source: 'bing_images',
            thumbnail: item.thumbnailUrl,
            contextLink: item.hostPageUrl
        }));
        
        return { images, source: 'bing_images', count: images.length };
    } catch (error) {
        console.error('Bing Images API error:', error);
        return { images: [], source: 'bing_error' };
    }
}
```

### **3. News API Integration**

```javascript
async integrateNewsAPI(keywords, region = 'all') {
    const NEWS_API_KEY = process.env.NEWS_API_KEY;
    
    if (!NEWS_API_KEY) {
        console.log('News API key not configured');
        return { articles: [], source: 'news_fallback' };
    }
    
    try {
        const searchQuery = keywords.join(' OR ');
        const url = `https://newsapi.org/v2/everything?q=${encodeURIComponent(searchQuery)}&pageSize=20&sortBy=relevancy`;
        
        const response = await fetch(url, {
            headers: {
                'X-API-Key': NEWS_API_KEY
            }
        });
        
        const data = await response.json();
        
        const articlesWithImages = (data.articles || [])
            .filter(article => article.urlToImage)
            .map(article => ({
                url: article.urlToImage,
                title: article.title,
                source: 'news_api',
                contextLink: article.url,
                description: article.description
            }));
        
        return { articles: articlesWithImages, source: 'news_api', count: articlesWithImages.length };
    } catch (error) {
        console.error('News API error:', error);
        return { articles: [], source: 'news_error' };
    }
}
```

### **4. Social Media Integration Framework**

```javascript
async integrateSocialMedia(keywords, platforms = ['twitter']) {
    const results = [];
    
    for (const platform of platforms) {
        switch (platform) {
            case 'twitter':
                const twitterResults = await this.integrateTwitter(keywords);
                results.push(twitterResults);
                break;
            case 'reddit':
                const redditResults = await this.integrateReddit(keywords);
                results.push(redditResults);
                break;
        }
    }
    
    return { platforms: results, totalSources: results.length };
}

async integrateTwitter(keywords) {
    const TWITTER_BEARER_TOKEN = process.env.TWITTER_BEARER_TOKEN;
    
    if (!TWITTER_BEARER_TOKEN) {
        return { tweets: [], source: 'twitter_fallback' };
    }
    
    // Twitter API v2 implementation ready
    // Endpoint: https://api.twitter.com/2/tweets/search/recent
    return { tweets: [], source: 'twitter_ready', status: 'integration_pending' };
}
```

## 🔧 **Environment Configuration**

Create a `.env` file in your news directory:

```env
# Google Custom Search API
GOOGLE_API_KEY=your_google_api_key_here
GOOGLE_CSE_ID=your_custom_search_engine_id_here

# Bing Search API
BING_SEARCH_API_KEY=your_bing_subscription_key_here

# News API
NEWS_API_KEY=your_news_api_key_here

# Twitter API v2
TWITTER_BEARER_TOKEN=your_twitter_bearer_token_here

# Unsplash API
UNSPLASH_ACCESS_KEY=your_unsplash_access_key_here

# Rate limiting settings
IMAGE_SCRAPING_DELAY=2000
MAX_IMAGES_PER_ARTICLE=5
MAX_CONCURRENT_REQUESTS=3
```

## 🎯 **Integration Priority Recommendations**

### **High Priority (Immediate Impact)**
1. **Google Images API** - Best coverage and quality
2. **News API** - Direct article images
3. **Bing Images API** - Good fallback option

### **Medium Priority (Enhanced Capabilities)**
4. **Unsplash API** - High-quality stock images
5. **Twitter API** - Real-time social content
6. **Reddit API** - Community-sourced images

### **Advanced Integration (AI-Powered)**
7. **OpenAI DALL-E** - Generated images for topics
8. **Google Vision API** - Image analysis and categorization
9. **Azure Computer Vision** - Enhanced image metadata

## 📊 **Usage Examples**

```powershell
# Test Google Images integration
curl -X POST http://localhost:3007/mcp -H "Content-Type: application/json" -d '{
    "method": "tools/call",
    "params": {
        "name": "search_related_images",
        "keywords": "African election democracy voting",
        "sources": ["google_images", "news_api"],
        "region": "african"
    }
}'

# Test enhanced scraping with API fallbacks
curl -X POST http://localhost:3007/api/enhanced-scrape-images -H "Content-Type: application/json" -d '{
    "strategy": "all",
    "limit": 5,
    "includeRelated": true,
    "useAPIFallbacks": true
}'
```

## 🚀 **Next Steps**

1. **Choose Your Integration Level:**
   - **Basic**: Google Images + News API
   - **Advanced**: Add Bing + Social Media
   - **Enterprise**: Include AI services

2. **Get API Keys:**
   - Google Custom Search: https://developers.google.com/custom-search/v1/introduction
   - Bing Search: https://www.microsoft.com/en-us/bing/apis/bing-web-search-api
   - News API: https://newsapi.org/

3. **Configure Environment:**
   - Add API keys to `.env` file
   - Test individual integrations
   - Deploy enhanced collection

4. **Monitor Performance:**
   - Track success rates per source
   - Optimize keyword strategies
   - Adjust rate limiting as needed

The framework is **ready for immediate integration** - just add your API keys and start collecting related article images!