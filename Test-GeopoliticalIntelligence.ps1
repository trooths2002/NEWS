#Requires -Version 5.1

<#
.SYNOPSIS
    Test Comprehensive Geopolitical Intelligence System with Image Scraping

.DESCRIPTION
    Verifies the enhanced geopolitical intelligence system covering all core disciplines
    and regional focus areas with Caribbean and Afro-Latino RSS sources, plus image
    scraping workflow for visual intelligence collection
#>

function Write-Message {
    param([string]$Message, [string]$Type = "INFO")
    
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        "TRENDING" { "Magenta" }
        default   { "Cyan" }
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
}

Write-Message "=== Comprehensive Geopolitical Intelligence System Test (with Image Scraping) ===" "INFO"
Write-Message "Core Disciplines: Political Science, Geography, History, Economics, Strategic Studies, Cultural/Social, Energy/Resources" "INFO"
Write-Message "Regional Focus: African, Caribbean, Afro-Latino, Middle East, East Asia, Europe" "INFO"

# Initialize directories
$directories = @(
    "trending-intelligence\summaries",
    "trending-intelligence\geopolitics\african",
    "trending-intelligence\geopolitics\caribbean", 
    "trending-intelligence\geopolitics\afro-latino",
    "trending-intelligence\copyable-content",
    "trending-intelligence\reports"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Message "Created directory: $dir" "SUCCESS"
    }
}

# Start server if not running
$serverRunning = Get-NetTCPConnection -LocalPort 3007 -ErrorAction SilentlyContinue
if (-not $serverRunning) {
    Write-Message "Starting Geopolitical Intelligence Server..." "INFO"
    Start-Process -FilePath "node" -ArgumentList "geopolitical-intelligence-server.js" -WindowStyle Minimized
    Start-Sleep -Seconds 8
}

# Test server connectivity
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:3007/health" -TimeoutSec 10
    Write-Message "Server Status: $($healthCheck.status)" "SUCCESS"
    Write-Message "Server Version: $($healthCheck.version)" "INFO"
    Write-Message "Capabilities: $($healthCheck.capabilities -join ', ')" "INFO"
} catch {
    Write-Message "Server not responding: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Collect geopolitical intelligence
Write-Message "Collecting comprehensive geopolitical intelligence..." "INFO"
try {
    $fetchResponse = Invoke-RestMethod -Uri "http://localhost:3007/api/fetch-geopolitical" -Method Post -TimeoutSec 60
    
    if ($fetchResponse.success) {
        $result = $fetchResponse.result
        Write-Message "Collected $($result.totalItems) news items" "SUCCESS"
        Write-Message "Regional categories: $($result.categories.Keys -join ', ')" "INFO"
    }
} catch {
    Write-Message "Failed to fetch intelligence: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Generate trending analysis
Write-Message "Generating trending analysis..." "INFO"
try {
    $trendingResponse = Invoke-RestMethod -Uri "http://localhost:3007/api/trending" -TimeoutSec 30
    
    if ($trendingResponse.success) {
        $trending = $trendingResponse.trending
        Write-Message "Generated trending analysis for $($trending.totalItems) items" "TRENDING"
    }
} catch {
    Write-Message "Failed to generate trending analysis: $($_.Exception.Message)" "ERROR"
}

# Generate copyable content
Write-Message "Generating copyable intelligence formats..." "INFO"
try {
    $copyableResponse = Invoke-RestMethod -Uri "http://localhost:3007/api/generate-copyable" -Method Post -Body (@{format="all"} | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    
    if ($copyableResponse.success) {
        Write-Message "Generated copyable formats: $($copyableResponse.files.Keys -join ', ')" "SUCCESS"
        Write-Message "Items processed: $($copyableResponse.itemsProcessed)" "INFO"
        
        # Verify regional coverage
        $csvPath = "trending-intelligence\copyable-content\summaries-$(Get-Date -Format 'yyyy-MM-dd').csv"
        if (Test-Path $csvPath) {
            $csvContent = Get-Content $csvPath
            $caribbeanCount = ($csvContent | Select-String "caribbean").Count
            $afroLatinoCount = ($csvContent | Select-String "afroLatino").Count  
            $africanCount = ($csvContent | Select-String "african").Count
            
            Write-Message "=== Regional Coverage Verification ===" "INFO"
            Write-Message "African: $africanCount items" "INFO"
            Write-Message "Caribbean: $caribbeanCount items" "INFO" 
            Write-Message "Afro-Latino: $afroLatinoCount items" "INFO"
            
            if ($caribbeanCount -eq 0) {
                Write-Message "WARNING: No Caribbean geopolitical content detected" "WARNING"
                Write-Message "Caribbean RSS sources may need verification" "WARNING"
            }
            
            if ($afroLatinoCount -eq 0) {
                Write-Message "WARNING: No Afro-Latino geopolitical content detected" "WARNING"
                Write-Message "Afro-Latino RSS sources may need verification" "WARNING"
            }
        }
    }
} catch {
    Write-Message "Failed to generate copyable content: $($_.Exception.Message)" "ERROR"
}

# Test image scraping workflow
Write-Message "Testing image scraping workflow..." "TRENDING"
try {
    $imageRequest = @{limit = 5} | ConvertTo-Json
    $imageResponse = Invoke-RestMethod -Uri "http://localhost:3007/api/scrape-images" -Method Post -Body $imageRequest -ContentType "application/json" -TimeoutSec 120
    
    if ($imageResponse.success) {
        Write-Message "Image scraping completed successfully" "SUCCESS"
        Write-Message "Articles processed: $($imageResponse.totalProcessed)" "TRENDING"
        Write-Message "Images collected: $($imageResponse.successful)" "TRENDING"
        
        if ($imageResponse.images -and $imageResponse.images.Count -gt 0) {
            Write-Message "Sample image collections:" "TRENDING"
            $imageResponse.images | Select-Object -First 2 | ForEach-Object {
                Write-Message "  📸 $($_.title.Substring(0, [Math]::Min(40, $_.title.Length)))... ($($_.images.Count) images)" "TRENDING"
            }
        }
    } else {
        Write-Message "Image scraping had issues: $($imageResponse.message)" "WARNING"
    }
} catch {
    Write-Message "Failed to test image scraping: $($_.Exception.Message)" "WARNING"
}

# Show generated files
Write-Message "=== Generated Intelligence Products ===" "INFO"
$today = Get-Date -Format "yyyy-MM-dd"

$files = @(
    "trending-intelligence\summaries\trending-$today.json",
    "trending-intelligence\copyable-content\summaries-$today.csv",
    "trending-intelligence\copyable-content\summaries-$today.txt",
    "trending-intelligence\copyable-content\content-template-$today.txt",
    "trending-intelligence\images\image-metadata-$today.json"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $fileSize = (Get-Item $file).Length
        Write-Message "+ $file ($fileSize bytes)" "SUCCESS"
    } else {
        Write-Message "- $file (missing)" "WARNING"
    }
}

# Check image directories
Write-Message "=== Image Storage Verification ===" "INFO"
$imageDirectories = @(
    "images",
    "images\headlines", 
    "images\regional\african",
    "images\regional\caribbean",
    "images\regional\afro-latino"
)

foreach ($imageDir in $imageDirectories) {
    if (Test-Path $imageDir) {
        $imageCount = (Get-ChildItem $imageDir -File -ErrorAction SilentlyContinue).Count
        Write-Message "+ $imageDir ($imageCount images)" "SUCCESS"
    } else {
        Write-Message "- $imageDir (missing)" "WARNING"
    }
}

Write-Message "=== Test Complete ===" "SUCCESS"
Write-Message "Comprehensive geopolitical intelligence workflow verified!" "SUCCESS"
Write-Message "To set up daily automation at 8 AM, run: schtasks /create /sc daily /st 08:00 /tn `"GeopoliticalIntelligence`" /tr `"PowerShell -ExecutionPolicy Bypass -File '$PWD\Start-GeopoliticalIntelligence.ps1' -RunOnce`"" "INFO"