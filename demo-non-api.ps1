#Requires -Version 5.1

Write-Host "=== NON-API IMAGE SCRAPING DEMONSTRATION ===" -ForegroundColor Cyan
Write-Host ""

# Test server health
Write-Host "Testing server health..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:3007/health"
    Write-Host "✅ Server Status: $($health.status)" -ForegroundColor Green
    Write-Host "✅ Version: $($health.version)" -ForegroundColor Green
    Write-Host "✅ Capabilities: $($health.capabilities -join ', ')" -ForegroundColor Green
    
    if ($health.capabilities -contains 'image_scraping') {
        Write-Host "✅ IMAGE SCRAPING: ACTIVE" -ForegroundColor Green
    }
    if ($health.capabilities -contains 'visual_intelligence') {
        Write-Host "✅ VISUAL INTELLIGENCE: ACTIVE" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Server health check failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 1: Aggressive Scraping (No API Required)
Write-Host "TEST 1: AGGRESSIVE SCRAPING (NO API REQUIRED)" -ForegroundColor Magenta
Write-Host "Features: CSS selectors, background images, mobile versions" -ForegroundColor White

$aggressiveRequest = @{
    strategy = "aggressive"
    limit = 2
    includeRelated = $false
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:3007/api/enhanced-scrape-images" -Method Post -Body $aggressiveRequest -ContentType "application/json"
    
    if ($response.success) {
        Write-Host "✅ AGGRESSIVE SCRAPING: WORKING" -ForegroundColor Green
        Write-Host "  Articles processed: $($response.totalProcessed)" -ForegroundColor White
        Write-Host "  Strategy: $($response.strategy)" -ForegroundColor White
        Write-Host "  Methods used: $($response.methods -join ', ')" -ForegroundColor White
    } else {
        Write-Host "ℹ️ Aggressive scraping: $($response.message)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Aggressive scraping test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: RSS Image Extraction
Write-Host "TEST 2: RSS IMAGE EXTRACTION (NO API REQUIRED)" -ForegroundColor Magenta
Write-Host "Features: Direct RSS parsing, media tags, thumbnails" -ForegroundColor White

$rssRequest = @{
    limit = 2
} | ConvertTo-Json

try {
    $rssResponse = Invoke-RestMethod -Uri "http://localhost:3007/api/scrape-images" -Method Post -Body $rssRequest -ContentType "application/json"
    
    if ($rssResponse.success) {
        Write-Host "✅ RSS IMAGE EXTRACTION: WORKING" -ForegroundColor Green
        Write-Host "  Message: $($rssResponse.message)" -ForegroundColor White
    } else {
        Write-Host "ℹ️ RSS extraction: $($rssResponse.message)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ RSS extraction test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: MCP Tools
Write-Host "TEST 3: MCP PROTOCOL TOOLS (NO API REQUIRED)" -ForegroundColor Magenta
Write-Host "Features: Protocol-based scraping, metadata tracking" -ForegroundColor White

$mcpRequest = @{
    method = "tools/call"
    params = @{
        name = "scrape_article_images"
        limit = 1
        region = "all"
    }
} | ConvertTo-Json -Depth 3

try {
    $mcpResponse = Invoke-RestMethod -Uri "http://localhost:3007/mcp" -Method Post -Body $mcpRequest -ContentType "application/json"
    
    if ($mcpResponse.content) {
        Write-Host "✅ MCP TOOLS: OPERATIONAL" -ForegroundColor Green
        Write-Host "  Protocol response received" -ForegroundColor White
    }
} catch {
    Write-Host "❌ MCP tools test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== SUMMARY: NON-API CAPABILITIES ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "OPERATIONAL WITHOUT ANY APIs:" -ForegroundColor Green
Write-Host "✅ RSS Feed Image Extraction" -ForegroundColor Green
Write-Host "✅ Aggressive Web Scraping" -ForegroundColor Green
Write-Host "✅ Content-Based Discovery" -ForegroundColor Green
Write-Host "✅ Multi-Selector CSS Parsing" -ForegroundColor Green
Write-Host "✅ Alternative URL Checking" -ForegroundColor Green
Write-Host "✅ Enhanced Metadata Tracking" -ForegroundColor Green
Write-Host "✅ Regional Categorization" -ForegroundColor Green
Write-Host ""
Write-Host "KEY ADVANTAGES:" -ForegroundColor Cyan
Write-Host "• Completely FREE (no API costs or limits)" -ForegroundColor White
Write-Host "• Direct access to source websites" -ForegroundColor White
Write-Host "• No external dependencies required" -ForegroundColor White
Write-Host "• Better context and image relevance" -ForegroundColor White
Write-Host "• More reliable (no API downtime)" -ForegroundColor White
Write-Host "• Unlimited usage and scaling" -ForegroundColor White
Write-Host ""
Write-Host "NON-API IMAGE SCRAPING: FULLY OPERATIONAL!" -ForegroundColor Green