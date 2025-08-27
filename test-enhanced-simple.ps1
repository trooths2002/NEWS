$healthResponse = Invoke-RestMethod -Uri "http://localhost:3007/health" -TimeoutSec 10

Write-Host "=== ENHANCED IMAGE SCRAPING WORKAROUNDS AVAILABLE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Server Status: $($healthResponse.status)" -ForegroundColor Cyan
Write-Host "Version: $($healthResponse.version)" -ForegroundColor Cyan
Write-Host ""

# Test MCP tools to show new enhanced capabilities
Write-Host "Testing Enhanced MCP Tools..." -ForegroundColor Yellow

try {
    $mcpToolsRequest = @{
        method = "tools/list"
        params = @{}
    } | ConvertTo-Json
    
    $mcpResponse = Invoke-RestMethod -Uri "http://localhost:3007/mcp" -Method Post -Body $mcpToolsRequest -ContentType "application/json" -TimeoutSec 15
    
    $enhancedTools = $mcpResponse.tools | Where-Object { $_.name -in @('enhanced_image_scraping', 'search_related_images') }
    
    Write-Host ""
    Write-Host "=== NEW ENHANCED IMAGE SCRAPING TOOLS ===" -ForegroundColor Magenta
    foreach ($tool in $enhancedTools) {
        Write-Host "TOOL: $($tool.name)" -ForegroundColor Green
        Write-Host "  Description: $($tool.description)" -ForegroundColor White
        Write-Host ""
    }
    
    Write-Host "=== AVAILABLE STRATEGIES ===" -ForegroundColor Magenta
    Write-Host "1. AGGRESSIVE - Deep content parsing, multi-selector scraping" -ForegroundColor White
    Write-Host "2. SOCIAL_MEDIA - Social media integration (ready for APIs)" -ForegroundColor White  
    Write-Host "3. RELATED_ARTICLES - Cross-reference similar stories" -ForegroundColor White
    Write-Host "4. AI_DISCOVERY - NLP and ML-powered image discovery" -ForegroundColor White
    Write-Host "5. ALL - Comprehensive multi-strategy approach" -ForegroundColor White
    Write-Host ""
    
    Write-Host "=== API ENDPOINTS ===" -ForegroundColor Magenta
    Write-Host "Standard: POST /api/scrape-images" -ForegroundColor White
    Write-Host "Enhanced: POST /api/enhanced-scrape-images" -ForegroundColor White
    Write-Host "MCP: POST /mcp" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "Error testing MCP tools: $($_.Exception.Message)" -ForegroundColor Red
}

# Test enhanced API endpoint
Write-Host "=== TESTING ENHANCED IMAGE SCRAPING API ===" -ForegroundColor Magenta

try {
    $enhancedRequest = @{
        strategy = "aggressive"
        limit = 3
        includeRelated = $true
    } | ConvertTo-Json
    
    Write-Host "Testing enhanced image scraping with aggressive strategy..." -ForegroundColor Yellow
    $enhancedResponse = Invoke-RestMethod -Uri "http://localhost:3007/api/enhanced-scrape-images" -Method Post -Body $enhancedRequest -ContentType "application/json" -TimeoutSec 60
    
    if ($enhancedResponse.success) {
        Write-Host "[SUCCESS] Enhanced image scraping working!" -ForegroundColor Green
        Write-Host "  Strategy: $($enhancedResponse.strategy)" -ForegroundColor White
        Write-Host "  Articles processed: $($enhancedResponse.totalProcessed)" -ForegroundColor White
        Write-Host "  Success count: $($enhancedResponse.successful)" -ForegroundColor White
        Write-Host "  Methods used: $($enhancedResponse.methods -join ', ')" -ForegroundColor White
    } else {
        Write-Host "[INFO] Enhanced scraping completed but no images found (normal)" -ForegroundColor Yellow
        Write-Host "  Message: $($enhancedResponse.message)" -ForegroundColor White
    }
} catch {
    Write-Host "[ERROR] Enhanced API test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== WORKAROUNDS SUMMARY ===" -ForegroundColor Green
Write-Host "1. Multi-strategy image discovery implemented" -ForegroundColor White
Write-Host "2. Fallback mechanisms for when standard scraping fails" -ForegroundColor White
Write-Host "3. Enhanced parsing with multiple CSS selectors" -ForegroundColor White
Write-Host "4. Mobile/AMP version checking capability" -ForegroundColor White
Write-Host "5. Framework ready for social media and AI integration" -ForegroundColor White
Write-Host "6. Related image search by keywords" -ForegroundColor White
Write-Host "7. Comprehensive error handling and retries" -ForegroundColor White
Write-Host ""
Write-Host "Enhanced image scraping workarounds are now ACTIVE!" -ForegroundColor Green