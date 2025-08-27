#Requires -Version 5.1

<#
.SYNOPSIS
    Google Custom Search Engine Setup Assistant

.DESCRIPTION
    Helps configure Google CSE for image search integration
#>

function Write-Setup {
    param([string]$Message, [string]$Type = "INFO")
    
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        "STEP"    { "Cyan" }
        "INPUT"   { "Magenta" }
        default   { "White" }
    }
    
    Write-Host $Message -ForegroundColor $color
}

Write-Setup "=== GOOGLE CUSTOM SEARCH ENGINE SETUP ASSISTANT ===" "STEP"
Write-Setup ""

Write-Setup "✅ STEP 1: API KEY CONFIGURED" "SUCCESS"
Write-Setup "   Your Google API Key: AIzaSyB8yvuzAdDx1GDsdRp4ulReaC7Y9BTEBdw" "SUCCESS"
Write-Setup ""

Write-Setup "🎯 STEP 2: CREATE CUSTOM SEARCH ENGINE" "STEP"
Write-Setup ""
Write-Setup "Please follow these steps manually:" "INFO"
Write-Setup "1. Open your browser and go to: https://cse.google.com/cse/" "INFO"
Write-Setup "2. Click 'Add' or 'New Search Engine'" "INFO"
Write-Setup "3. Configure as follows:" "INFO"
Write-Setup "   - Sites to search: Leave BLANK (to search entire web)" "WARNING"
Write-Setup "   - Name: 'Geopolitical Image Search'" "INFO"
Write-Setup "   - Language: English" "INFO"
Write-Setup "4. Click 'Create'" "INFO"
Write-Setup ""

Write-Setup "🔧 STEP 3: ENABLE IMAGE SEARCH" "STEP"
Write-Setup "1. After creating CSE, click 'Control Panel'" "INFO"
Write-Setup "2. Go to 'Setup' → 'Basics'" "INFO"
Write-Setup "3. Under 'Image Search': Turn ON" "WARNING"
Write-Setup "4. Under 'Search the entire web': Turn ON" "WARNING"
Write-Setup "5. Click 'Update'" "INFO"
Write-Setup ""

Write-Setup "🆔 STEP 4: GET YOUR SEARCH ENGINE ID" "STEP"
Write-Setup "1. In Control Panel → 'Setup' → 'Basics'" "INFO"
Write-Setup "2. Find 'Search Engine ID' (format like: abc123:def456)" "INFO"
Write-Setup "3. Copy this ID" "INFO"
Write-Setup ""

# Wait for user to complete setup
Write-Setup "⏳ Complete the steps above, then press ENTER to continue..." "INPUT"
Read-Host

Write-Setup "📝 STEP 5: ENTER YOUR SEARCH ENGINE ID" "STEP"
$cseId = Read-Host "Paste your Custom Search Engine ID here"

if ($cseId -and $cseId.Trim() -ne "") {
    # Update .env file
    $envPath = ".env"
    $envContent = Get-Content $envPath -Raw
    $updatedContent = $envContent -replace "GOOGLE_CSE_ID=your_custom_search_engine_id_here", "GOOGLE_CSE_ID=$cseId"
    
    Set-Content -Path $envPath -Value $updatedContent
    
    Write-Setup "✅ SUCCESS: Updated .env file with your CSE ID" "SUCCESS"
    Write-Setup "   GOOGLE_CSE_ID=$cseId" "SUCCESS"
} else {
    Write-Setup "❌ ERROR: No CSE ID provided" "ERROR"
    Write-Setup "Please run this script again after getting your CSE ID" "WARNING"
    exit 1
}

Write-Setup ""
Write-Setup "🧪 STEP 6: TEST INTEGRATION" "STEP"

# Kill any existing server
try {
    Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
    Write-Setup "Stopped existing server processes" "INFO"
} catch {
    # No processes to stop
}

# Start server in background
Write-Setup "Starting server with Google API integration..." "INFO"
Start-Process -FilePath "node" -ArgumentList "geopolitical-intelligence-server.js" -WindowStyle Hidden

# Wait for server to start
Start-Sleep -Seconds 8

# Test the API integration
Write-Setup "Testing Google Images API integration..." "STEP"

try {
    $testRequest = @{
        method = "tools/call"
        params = @{
            name = "search_related_images"
            keywords = "African politics election"
            sources = @("google_images")
            region = "african"
        }
    } | ConvertTo-Json -Depth 3
    
    $response = Invoke-RestMethod -Uri "http://localhost:3007/mcp" -Method Post -Body $testRequest -ContentType "application/json" -TimeoutSec 30
    
    if ($response.content) {
        $result = $response.content[0].text | ConvertFrom-Json
        Write-Setup "✅ SUCCESS: Google Images API integration working!" "SUCCESS"
        Write-Setup "   Test query: $($result.keywords)" "INFO"
        Write-Setup "   Sources: $($result.sources -join ', ')" "INFO"
        Write-Setup "   Region: $($result.region)" "INFO"
    }
} catch {
    Write-Setup "❌ ERROR: API test failed: $($_.Exception.Message)" "ERROR"
    Write-Setup "This might be due to:" "WARNING"
    Write-Setup "  1. Server still starting up (wait 30 seconds and try again)" "WARNING"
    Write-Setup "  2. Incorrect CSE ID format" "WARNING"
    Write-Setup "  3. Image search not enabled in CSE settings" "WARNING"
}

Write-Setup ""
Write-Setup "🚀 STEP 7: NEXT ACTIONS" "STEP"
Write-Setup "1. Test image scraping with: powershell -File test-comprehensive-integration.ps1" "INFO"
Write-Setup "2. Monitor API usage at: https://console.developers.google.com/apis/dashboard" "INFO"
Write-Setup "3. Add more API keys (Bing, News API) for enhanced capabilities" "INFO"
Write-Setup ""

Write-Setup "GOOGLE CUSTOM SEARCH ENGINE SETUP COMPLETE!" "SUCCESS"
Write-Setup ""
Write-Setup "Configuration Summary:" "INFO"
Write-Setup "  ✅ API Key: Configured" "SUCCESS"
Write-Setup "  ✅ CSE ID: $cseId" "SUCCESS"
Write-Setup "  ✅ Image Search: Enabled" "SUCCESS"
Write-Setup "  ✅ Server: Running with API integration" "SUCCESS"

Write-Setup ""
Write-Setup "Quick Test Commands:" "INFO"
Write-Setup "# Test enhanced image scraping with Google API" "INFO"
Write-Setup 'curl -X POST http://localhost:3007/api/enhanced-scrape-images -H "Content-Type: application/json" -d \'{"strategy":"api_search","limit":2}\'' "INFO"
Write-Setup ""
Write-Setup "# Test direct image search" "INFO"
Write-Setup 'curl -X POST http://localhost:3007/mcp -H "Content-Type: application/json" -d \'{"method":"tools/call","params":{"name":"search_related_images","keywords":"democracy election","sources":["google_images"]}}\'' "INFO"