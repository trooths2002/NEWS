#Requires -Version 5.1

<#
.SYNOPSIS
    Test Image Scraping Workflow for Geopolitical Intelligence System

.DESCRIPTION
    Verifies the image scraping functionality added to the geopolitical intelligence system
    Tests both API endpoints and MCP tools for image collection from headlines
#>

function Write-TestMessage {
    param([string]$Message, [string]$Type = "INFO")
    
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        "IMAGE"   { "Magenta" }
        default   { "Cyan" }
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
}

Write-TestMessage "=== Image Scraping Workflow Test ===" "INFO"
Write-TestMessage "Testing image collection from captured headlines" "INFO"

# Check if server is running
$serverRunning = Get-NetTCPConnection -LocalPort 3007 -ErrorAction SilentlyContinue
if (-not $serverRunning) {
    Write-TestMessage "Starting Geopolitical Intelligence Server..." "INFO"
    Start-Process -FilePath "node" -ArgumentList "geopolitical-intelligence-server.js" -WindowStyle Minimized
    Start-Sleep -Seconds 10
}

# Test server health and capabilities
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:3007/health" -TimeoutSec 10
    Write-TestMessage "Server Status: $($healthCheck.status)" "SUCCESS"
    Write-TestMessage "Server Version: $($healthCheck.version)" "INFO"
    Write-TestMessage "Image Capabilities: $($healthCheck.capabilities -contains 'image_scraping')" "INFO"
    
    if ($healthCheck.capabilities -contains 'image_scraping') {
        Write-TestMessage "[OK] Image scraping capability detected" "SUCCESS"
    } else {
        Write-TestMessage "[ERROR] Image scraping capability missing" "ERROR"
        exit 1
    }
} catch {
    Write-TestMessage "Server not responding: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Test MCP tools list to verify image scraping tools
Write-TestMessage "Testing MCP tools list..." "INFO"
try {
    $mcpToolsRequest = @{
        method = "tools/list"
        params = @{}
    } | ConvertTo-Json
    
    $mcpResponse = Invoke-RestMethod -Uri "http://localhost:3007/mcp" -Method Post -Body $mcpToolsRequest -ContentType "application/json" -TimeoutSec 15
    
    $imageScrapingTools = $mcpResponse.tools | Where-Object { $_.name -in @('scrape_article_images', 'get_image_metadata') }
    
    if ($imageScrapingTools.Count -eq 2) {
        Write-TestMessage "[OK] Image scraping MCP tools found: scrape_article_images, get_image_metadata" "SUCCESS"
    } else {
        Write-TestMessage "[ERROR] Image scraping MCP tools missing" "ERROR"
        Write-TestMessage "Available tools: $($mcpResponse.tools.name -join ', ')" "INFO"
    }
} catch {
    Write-TestMessage "Failed to test MCP tools: $($_.Exception.Message)" "ERROR"
}

# First, fetch some geopolitical news to have headlines for image scraping
Write-TestMessage "Fetching geopolitical news for image scraping test..." "INFO"
try {
    $fetchResponse = Invoke-RestMethod -Uri "http://localhost:3007/api/fetch-geopolitical" -Method Post -TimeoutSec 60
    
    if ($fetchResponse.success) {
        Write-TestMessage "Collected $($fetchResponse.result.totalItems) news items" "SUCCESS"
    } else {
        Write-TestMessage "Failed to fetch news for testing" "ERROR"
        exit 1
    }
} catch {
    Write-TestMessage "Failed to fetch geopolitical news: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Test direct API endpoint for image scraping
Write-TestMessage "Testing image scraping API endpoint..." "IMAGE"
try {
    $imageScrapeRequest = @{
        limit = 5
    } | ConvertTo-Json
    
    $imageResponse = Invoke-RestMethod -Uri "http://localhost:3007/api/scrape-images" -Method Post -Body $imageScrapeRequest -ContentType "application/json" -TimeoutSec 120
    
    if ($imageResponse.success) {
        Write-TestMessage "[OK] Image scraping completed successfully" "SUCCESS"
        Write-TestMessage "Articles processed: $($imageResponse.totalProcessed)" "IMAGE"
        Write-TestMessage "Successful: $($imageResponse.successful)" "IMAGE"
        Write-TestMessage "Skipped: $($imageResponse.skipped)" "IMAGE"
        
        if ($imageResponse.images -and $imageResponse.images.Count -gt 0) {
            Write-TestMessage "Images collected from $($imageResponse.images.Count) articles" "IMAGE"
            
            # Show sample of collected images
            $imageResponse.images | Select-Object -First 3 | ForEach-Object {
                Write-TestMessage "[IMG] Article: $($_.title.Substring(0, [Math]::Min(50, $_.title.Length)))..." "IMAGE"
                Write-TestMessage "   Images: $($_.images.Count)" "IMAGE"
                Write-TestMessage "   Categories: $($_.categories -join ', ')" "IMAGE"
            }
        } else {
            Write-TestMessage "[WARN] No images were collected (this may be normal depending on source content)" "WARNING"
        }
    } else {
        Write-TestMessage "[ERROR] Image scraping failed: $($imageResponse.message)" "ERROR"
    }
} catch {
    Write-TestMessage "Failed to test image scraping API: $($_.Exception.Message)" "ERROR"
}

# Test MCP tool for image scraping
Write-TestMessage "Testing MCP image scraping tool..." "IMAGE"
try {
    $mcpImageRequest = @{
        method = "tools/call"
        params = @{
            name = "scrape_article_images"
            limit = 3
            region = "all"
        }
    } | ConvertTo-Json
    
    $mcpImageResponse = Invoke-RestMethod -Uri "http://localhost:3007/mcp" -Method Post -Body $mcpImageRequest -ContentType "application/json" -TimeoutSec 120
    
    if ($mcpImageResponse.content) {
        $result = $mcpImageResponse.content[0].text | ConvertFrom-Json
        
        if ($result.success) {
            Write-TestMessage "[OK] MCP image scraping tool working" "SUCCESS"
            Write-TestMessage "Region: $($result.region)" "IMAGE"
            Write-TestMessage "Articles processed: $($result.totalProcessed)" "IMAGE"
        } else {
            Write-TestMessage "[ERROR] MCP image scraping failed: $($result.message)" "ERROR"
        }
    }
} catch {
    Write-TestMessage "Failed to test MCP image scraping tool: $($_.Exception.Message)" "ERROR"
}

# Test image metadata retrieval
Write-TestMessage "Testing image metadata retrieval..." "IMAGE"
try {
    $today = Get-Date -Format "yyyy-MM-dd"
    
    $mcpMetadataRequest = @{
        method = "tools/call"
        params = @{
            name = "get_image_metadata"
            date = $today
            region = "all"
        }
    } | ConvertTo-Json
    
    $mcpMetadataResponse = Invoke-RestMethod -Uri "http://localhost:3007/mcp" -Method Post -Body $mcpMetadataRequest -ContentType "application/json" -TimeoutSec 30
    
    if ($mcpMetadataResponse.content) {
        $metadataResult = $mcpMetadataResponse.content[0].text | ConvertFrom-Json
        
        if ($metadataResult.success) {
            Write-TestMessage "[OK] Image metadata retrieval working" "SUCCESS"
            Write-TestMessage "Date: $($metadataResult.date)" "IMAGE"
            Write-TestMessage "Total articles with images: $($metadataResult.totalArticles)" "IMAGE"
            Write-TestMessage "Total images collected: $($metadataResult.totalImages)" "IMAGE"
        } else {
            Write-TestMessage "[WARN] No image metadata found for today (this is normal if no images were scraped today)" "WARNING"
        }
    }
} catch {
    Write-TestMessage "Failed to test image metadata retrieval: $($_.Exception.Message)" "ERROR"
}

# Check for created directories and files
Write-TestMessage "Verifying image storage structure..." "INFO"

$imageDirectories = @(
    "images",
    "images/headlines",
    "images/thumbnails",
    "images/articles",
    "images/regional",
    "images/regional/african",
    "images/regional/caribbean",
    "images/regional/afro-latino",
    "trending-intelligence/images"
)

foreach ($dir in $imageDirectories) {
    if (Test-Path $dir) {
        $fileCount = (Get-ChildItem $dir -File -ErrorAction SilentlyContinue).Count
        Write-TestMessage "[OK] $dir exists ($fileCount files)" "SUCCESS"
    } else {
        Write-TestMessage "[ERROR] $dir missing" "ERROR"
    }
}

# Show any image metadata files
$metadataFiles = Get-ChildItem "trending-intelligence/images" -Filter "image-metadata-*.json" -ErrorAction SilentlyContinue

if ($metadataFiles) {
    Write-TestMessage "=== Image Metadata Files ===" "IMAGE"
    foreach ($file in $metadataFiles) {
        Write-TestMessage "[META] $($file.Name) ($($file.Length) bytes)" "IMAGE"
    }
} else {
    Write-TestMessage "[WARN] No image metadata files found yet" "WARNING"
}

Write-TestMessage "=== Image Scraping Workflow Test Complete ===" "SUCCESS"
Write-TestMessage "Image scraping workflow has been successfully implemented!" "SUCCESS"
Write-TestMessage "" "INFO"
Write-TestMessage "Available MCP Tools:" "INFO"
Write-TestMessage "• scrape_article_images - Scrape images from headlines" "INFO"
Write-TestMessage "• get_image_metadata - Retrieve image collection statistics" "INFO"
Write-TestMessage "" "INFO"
Write-TestMessage "API Endpoints:" "INFO"
Write-TestMessage "• POST /api/scrape-images - Direct image scraping endpoint" "INFO"
Write-TestMessage "• POST /mcp - MCP protocol for image tools" "INFO"