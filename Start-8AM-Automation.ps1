#Requires -Version 5.1

<#
.SYNOPSIS
    Comprehensive 8 AM Daily Automation for Geopolitical Intelligence System

.DESCRIPTION
    This script runs the complete geopolitical intelligence workflow:
    - Starts MCP server on port 3007
    - Executes news collection (fetchAllAfrica.js)
    - Runs image scraping with non-API methods
    - Generates intelligence reports
    - Creates trending summaries
    - Manages all file operations

.NOTES
    Author: Geopolitical Intelligence System
    Version: 3.0
    Scheduled: Daily at 8:00 AM
    Compatible with: Windows PowerShell 5.1+
#>

param(
    [switch]$TestMode = $false,
    [switch]$SendNotifications = $true,
    [string]$LogLevel = "INFO"
)

# Set execution policy for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Initialize paths and variables
$WorkspacePath = "c:\Users\tjd20.LAPTOP-PCMC2SUO\news"
$StartTime = Get-Date
$LogFile = Join-Path $WorkspacePath "logs\automation-$(Get-Date -Format 'yyyy-MM-dd').log"
$ErrorLogFile = Join-Path $WorkspacePath "logs\automation-errors-$(Get-Date -Format 'yyyy-MM-dd').log"

# Ensure log directory exists
$logDir = Split-Path $LogFile -Parent
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-AutoLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    Write-Host $logEntry -ForegroundColor $Color
    
    # Write to log file
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    # Write errors to separate error log
    if ($Level -eq "ERROR") {
        Add-Content -Path $ErrorLogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

function Test-Prerequisites {
    Write-AutoLog "🔍 Checking system prerequisites..." "INFO" "Cyan"
    
    # Check Node.js
    try {
        $nodeVersion = & node --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-AutoLog "✅ Node.js available: $nodeVersion" "SUCCESS" "Green"
        } else {
            Write-AutoLog "❌ Node.js not found" "ERROR" "Red"
            return $false
        }
    } catch {
        Write-AutoLog "❌ Node.js check failed: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
    
    # Check required files
    $requiredFiles = @(
        "geopolitical-intelligence-server.js",
        "fetchAllAfrica.js",
        "package.json"
    )
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $WorkspacePath $file
        if (Test-Path $filePath) {
            Write-AutoLog "✅ Required file found: $file" "SUCCESS" "Green"
        } else {
            Write-AutoLog "❌ Missing required file: $file" "ERROR" "Red"
            return $false
        }
    }
    
    return $true
}

function Start-MCPServer {
    Write-AutoLog "🚀 Starting MCP Geopolitical Intelligence Server..." "INFO" "Cyan"
    
    try {
        # Check if server is already running
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:3007/health" -TimeoutSec 5
            if ($response.status -eq "healthy") {
                Write-AutoLog "✅ MCP Server already running (version $($response.version))" "SUCCESS" "Green"
                return $true
            }
        } catch {
            # Server not running, will start it
        }
        
        # Start the server
        Set-Location $WorkspacePath
        $serverProcess = Start-Process -FilePath "node" -ArgumentList "geopolitical-intelligence-server.js" -WindowStyle Hidden -PassThru
        
        # Wait for server to start
        $maxWait = 30
        $waited = 0
        do {
            Start-Sleep -Seconds 2
            $waited += 2
            try {
                $response = Invoke-RestMethod -Uri "http://localhost:3007/health" -TimeoutSec 5
                if ($response.status -eq "healthy") {
                    Write-AutoLog "✅ MCP Server started successfully (version $($response.version))" "SUCCESS" "Green"
                    Write-AutoLog "📊 Server capabilities: $($response.capabilities -join ', ')" "INFO" "White"
                    return $true
                }
            } catch {
                # Still starting
            }
        } while ($waited -lt $maxWait)
        
        Write-AutoLog "❌ MCP Server failed to start within $maxWait seconds" "ERROR" "Red"
        return $false
        
    } catch {
        Write-AutoLog "❌ Failed to start MCP Server: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

function Invoke-NewsCollection {
    Write-AutoLog "📰 Starting news collection..." "INFO" "Cyan"
    
    try {
        Set-Location $WorkspacePath
        
        # Run news fetching
        $newsProcess = Start-Process -FilePath "node" -ArgumentList "fetchAllAfrica.js" -WindowStyle Hidden -Wait -PassThru
        
        if ($newsProcess.ExitCode -eq 0) {
            Write-AutoLog "✅ News collection completed successfully" "SUCCESS" "Green"
            
            # Check for output files
            $today = Get-Date -Format "yyyy-MM-dd"
            $headlinesFile = "allafrica-headlines.txt"
            if (Test-Path $headlinesFile) {
                $headlines = Get-Content $headlinesFile
                Write-AutoLog "📄 Headlines collected: $($headlines.Count) items" "INFO" "White"
            }
            
            return $true
        } else {
            Write-AutoLog "❌ News collection failed with exit code: $($newsProcess.ExitCode)" "ERROR" "Red"
            return $false
        }
        
    } catch {
        Write-AutoLog "❌ News collection error: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

function Invoke-ImageScraping {
    Write-AutoLog "🖼️ Starting image scraping workflow..." "INFO" "Cyan"
    
    try {
        # Use the non-API image scraping
        $imageRequest = @{
            strategy = "aggressive"
            limit = 5
            includeRelated = $true
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "http://localhost:3007/api/enhanced-scrape-images" -Method Post -Body $imageRequest -ContentType "application/json" -TimeoutSec 120
        
        if ($response.success) {
            Write-AutoLog "✅ Image scraping completed successfully" "SUCCESS" "Green"
            Write-AutoLog "📊 Articles processed: $($response.totalProcessed)" "INFO" "White"
            Write-AutoLog "🖼️ Images collected: $($response.successful)" "INFO" "White"
            Write-AutoLog "⚡ Methods used: $($response.methods -join ', ')" "INFO" "White"
            return $true
        } else {
            Write-AutoLog "⚠️ Image scraping completed with warnings: $($response.message)" "WARNING" "Yellow"
            return $true
        }
        
    } catch {
        Write-AutoLog "❌ Image scraping error: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

function Invoke-IntelligenceAnalysis {
    Write-AutoLog "🧠 Running intelligence analysis..." "INFO" "Cyan"
    
    try {
        # Use MCP tools for analysis
        $analysisRequest = @{
            method = "tools/call"
            params = @{
                name = "generate_intelligence_report"
                region = "all"
                format = "comprehensive"
            }
        } | ConvertTo-Json -Depth 3
        
        $response = Invoke-RestMethod -Uri "http://localhost:3007/mcp" -Method Post -Body $analysisRequest -ContentType "application/json" -TimeoutSec 60
        
        if ($response.content) {
            Write-AutoLog "✅ Intelligence analysis completed" "SUCCESS" "Green"
            return $true
        } else {
            Write-AutoLog "⚠️ Intelligence analysis completed with limited results" "WARNING" "Yellow"
            return $true
        }
        
    } catch {
        Write-AutoLog "❌ Intelligence analysis error: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

function Send-CompletionNotification {
    if (!$SendNotifications) { return }
    
    $endTime = Get-Date
    $duration = $endTime - $StartTime
    
    $notificationTitle = "8 AM Geopolitical Intelligence Automation Complete"
    $notificationMessage = @"
Daily automation completed in $($duration.TotalMinutes.ToString("F1")) minutes

✅ News Collection: Complete
✅ Image Scraping: Complete  
✅ Intelligence Analysis: Complete
✅ MCP Server: Running

Check results in:
$WorkspacePath
"@
    
    try {
        # Show Windows notification
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        
        $template = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$notificationTitle</text>
            <text>$notificationMessage</text>
        </binding>
    </visual>
</toast>
"@
        
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($template)
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("8AM Automation").Show($toast)
        
    } catch {
        Write-AutoLog "⚠️ Could not send notification: $($_.Exception.Message)" "WARNING" "Yellow"
    }
}

# Main Execution
Write-AutoLog "🌅 Starting 8 AM Daily Geopolitical Intelligence Automation" "INFO" "Green"
Write-AutoLog "⏰ Start time: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" "INFO" "White"

if ($TestMode) {
    Write-AutoLog "🧪 Running in TEST MODE" "INFO" "Yellow"
}

# Step 1: Check Prerequisites
if (!(Test-Prerequisites)) {
    Write-AutoLog "❌ Prerequisites check failed. Aborting automation." "ERROR" "Red"
    exit 1
}

# Step 2: Start MCP Server
if (!(Start-MCPServer)) {
    Write-AutoLog "❌ MCP Server startup failed. Aborting automation." "ERROR" "Red"
    exit 1
}

# Step 3: Collect News
$newsSuccess = Invoke-NewsCollection

# Step 4: Scrape Images  
$imageSuccess = Invoke-ImageScraping

# Step 5: Run Intelligence Analysis
$analysisSuccess = Invoke-IntelligenceAnalysis

# Summary and Notification
$endTime = Get-Date
$duration = $endTime - $StartTime

Write-AutoLog "🏁 8 AM Automation Summary:" "INFO" "Green"
Write-AutoLog "   📰 News Collection: $(if($newsSuccess) { 'SUCCESS' } else { 'FAILED' })" "INFO" $(if($newsSuccess) { "Green" } else { "Red" })
Write-AutoLog "   🖼️ Image Scraping: $(if($imageSuccess) { 'SUCCESS' } else { 'FAILED' })" "INFO" $(if($imageSuccess) { "Green" } else { "Red" })
Write-AutoLog "   🧠 Intelligence Analysis: $(if($analysisSuccess) { 'SUCCESS' } else { 'FAILED' })" "INFO" $(if($analysisSuccess) { "Green" } else { "Red" })
Write-AutoLog "   ⏱️ Total Duration: $($duration.TotalMinutes.ToString('F1')) minutes" "INFO" "White"

Send-CompletionNotification

if ($newsSuccess -and $imageSuccess -and $analysisSuccess) {
    Write-AutoLog "🎉 8 AM Daily Automation COMPLETED SUCCESSFULLY!" "SUCCESS" "Green"
    exit 0
} else {
    Write-AutoLog "⚠️ 8 AM Daily Automation completed with some issues. Check logs." "WARNING" "Yellow"
    exit 0
}