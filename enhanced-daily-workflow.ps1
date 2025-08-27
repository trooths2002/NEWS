# Enhanced Daily News Intelligence Script
# Combines existing fetchAllAfrica.js with MCP AI analysis
# Perfect integration of automated collection + AI processing

param(
    [switch]$RunFullCollection,
    [switch]$RunMCPAnalysis,
    [switch]$SendNotification,
    [int]$MCPHeadlineCount = 10
)

$Date = Get-Date -Format "yyyy-MM-dd"
$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$LogFile = ".\enhanced-workflow.log"

function Write-Log {
    param($Message, $Color = "White")
    $LogEntry = "$TimeStamp - $Message"
    Write-Host $LogEntry -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $LogEntry
}

Write-Log "🚀 Starting Enhanced News Intelligence Workflow" "Green"
Write-Log "=============================================" "Green"

# Ensure required directories exist
$Directories = @(".\news-archive", ".\images", ".\intelligence-reports")
foreach ($Dir in $Directories) {
    if (!(Test-Path $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force
        Write-Log "📁 Created directory: $Dir" "Yellow"
    }
}

# Set default behavior for switches if not explicitly provided
if (-not $PSBoundParameters.ContainsKey('RunFullCollection')) { $RunFullCollection = $true }
if (-not $PSBoundParameters.ContainsKey('RunMCPAnalysis')) { $RunMCPAnalysis = $true }
if (-not $PSBoundParameters.ContainsKey('SendNotification')) { $SendNotification = $true }

# Phase 1: Run comprehensive collection (your existing script)
if ($RunFullCollection) {
    Write-Log "📡 Phase 1: Running comprehensive news collection..." "Cyan"
    
    try {
        # Check if Node.js is available
        $nodeVersion = node --version 2>$null
        if (-not $nodeVersion) {
            throw "Node.js not found"
        }
        
        Write-Log "📦 Node.js version: $nodeVersion" "Gray"
        Write-Log "🔄 Executing fetchAllAfrica.js..." "Cyan"
        
        # Run your existing comprehensive collection script
        $collectionOutput = node fetchAllAfrica.js 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Comprehensive collection completed successfully" "Green"
            Write-Log "📄 Collection output: $($collectionOutput -join ' ')" "Gray"
            
            # Count images downloaded
            $imageCount = (Get-ChildItem -Path ".\images" -File -ErrorAction SilentlyContinue).Count
            Write-Log "📷 Images downloaded: $imageCount" "Cyan"
            
            # Check output file
            if (Test-Path "allafrica-headlines.txt") {
                $headlineCount = (Get-Content "allafrica-headlines.txt" | Measure-Object -Line).Lines
                Write-Log "📰 Headlines archived: $headlineCount lines" "Cyan"
            }
        } else {
            Write-Log "📄 Collection output: $($collectionOutput -join ' ')" "Red"
            throw "fetchAllAfrica.js failed with exit code $LASTEXITCODE"
        }
        
    } catch {
        Write-Log "❌ Error in comprehensive collection: $($_.Exception.Message)" "Red"
        if (-not $RunMCPAnalysis) {
            Write-Log "🛑 Stopping workflow due to collection failure" "Red"
            exit 1
        }
    }
}

# Phase 2: MCP Real-time Analysis
if ($RunMCPAnalysis) {
    Write-Log "🧠 Phase 2: Running MCP AI analysis..." "Cyan"
    
    # Check if MCP server is running
    $ServerCheck = try {
        $response = Invoke-RestMethod -Uri "http://localhost:3006/health" -Method GET -TimeoutSec 5
        $true
    } catch {
        $false
    }
    
    if (-not $ServerCheck) {
        Write-Log "⚠️  MCP Server not running. Attempting to start..." "Yellow"
        
        # Try to start MCP server
        try {
            Start-Process -FilePath "node" -ArgumentList "mcp-sse-server.js" -WindowStyle Hidden -WorkingDirectory $PWD
            Start-Sleep -Seconds 8
            
            $ServerCheck = try {
                Invoke-RestMethod -Uri "http://localhost:3006/health" -Method GET -TimeoutSec 5
                $true
            } catch {
                $false
            }
            
            if ($ServerCheck) {
                Write-Log "✅ MCP Server started successfully" "Green"
            } else {
                throw "Failed to start MCP server"
            }
        } catch {
            Write-Log "❌ Could not start MCP server: $($_.Exception.Message)" "Red"
            Write-Log "ℹ️  Skipping MCP analysis phase" "Yellow"
            $RunMCPAnalysis = $false
        }
    } else {
        Write-Log "✅ MCP Server is running" "Green"
    }
    
    if ($RunMCPAnalysis) {
        # Fetch real-time headlines via MCP
        try {
            Write-Log "📡 Fetching real-time headlines for analysis..." "Cyan"
            
            $NewsRequest = @{
                jsonrpc = "2.0"
                method = "tools/call"
                params = @{
                    name = "fetch_news"
                    arguments = @{ limit = $MCPHeadlineCount }
                }
                id = 1
            } | ConvertTo-Json -Depth 10
            
            $headers = @{
                'Content-Type' = 'application/json'
                'Accept' = 'application/json, text/event-stream'
            }
            
            $response = Invoke-RestMethod -Uri "http://localhost:3006/sse" -Method POST -Body $NewsRequest -Headers $headers -TimeoutSec 30
            
            if ($response.result -and $response.result.content) {
                $currentHeadlines = $response.result.content[0].text
                Write-Log "✅ Fetched current headlines via MCP" "Green"
                
                # Create intelligence report
                $reportFile = ".\intelligence-reports\daily-intelligence-$Date.txt"
                
                $intelligenceReport = @"
DAILY NEWS INTELLIGENCE REPORT
Generated: $TimeStamp
Data Sources: Comprehensive Archive + Real-Time MCP

=== REAL-TIME HEADLINES (via MCP) ===
$currentHeadlines

=== COMPREHENSIVE DATA AVAILABLE ===
- Complete archive: allafrica-headlines.txt
- Visual content: .\images\ directory ($imageCount images)
- Last collection: $TimeStamp

=== INTELLIGENCE SUMMARY ===
- Real-time headlines fetched: $MCPHeadlineCount
- Comprehensive archive updated: $(if (Test-Path "allafrica-headlines.txt") { "✅" } else { "❌" })
- Visual documentation: $imageCount images available
- Data freshness: Current (as of $TimeStamp)

=== RECOMMENDED AI ANALYSIS PROMPTS ===
Use these with your MCP-connected AI assistant:

1. TREND ANALYSIS:
"Compare today's MCP headlines with my archived data in allafrica-headlines.txt. 
What are the emerging trends? What stories are developing?"

2. VISUAL CONTENT STRATEGY:
"Based on current headlines and my .\images\ folder contents, 
recommend social media content strategies with visual elements."

3. INTELLIGENCE BRIEFING:
"Create executive briefing using current MCP data and historical context 
from my comprehensive archive. Focus on geopolitical developments."

=== NEXT ACTIONS ===
- Connect MCP SuperAssistant to http://localhost:3006/sse
- Use above prompts in ChatGPT/Claude for enhanced analysis
- Review images in .\images\ for visual content opportunities
- Monitor developing stories for follow-up collection

=== WORKFLOW STATUS ===
- Automated Collection: $(if ($RunFullCollection) { "✅ Completed" } else { "⏭️ Skipped" })
- MCP Analysis: ✅ Completed
- Intelligence Report: ✅ Generated
- Ready for AI Assistant Integration: ✅ Yes

Report generated by Enhanced News Intelligence Workflow
"@
                
                $intelligenceReport | Out-File -FilePath $reportFile -Encoding UTF8
                Write-Log "📋 Intelligence report saved: $reportFile" "Green"
                
                # Save MCP headlines separately for quick reference
                $mcpFile = ".\news-archive\mcp-headlines-$Date.txt"
                $currentHeadlines | Out-File -FilePath $mcpFile -Encoding UTF8
                Write-Log "💾 MCP headlines saved: $mcpFile" "Green"
                
            } else {
                throw "Invalid MCP response format"
            }
            
        } catch {
            Write-Log "❌ MCP analysis failed: $($_.Exception.Message)" "Red"
        }
    }
}

# Phase 3: Workflow Summary & Notifications
Write-Log "📊 Generating workflow summary..." "Cyan"

$summary = @"
ENHANCED NEWS WORKFLOW SUMMARY - $Date

✅ COMPLETED PHASES:
$(if ($RunFullCollection) { "  ✅ Comprehensive Collection (fetchAllAfrica.js)" } else { "  ⏭️ Comprehensive Collection (skipped)" })
$(if ($RunMCPAnalysis) { "  ✅ MCP Real-time Analysis" } else { "  ⏭️ MCP Analysis (skipped)" })
  ✅ Intelligence Report Generation

📊 DATA COLLECTED:
  • Archive file: $(if (Test-Path "allafrica-headlines.txt") { "✅ Updated" } else { "❌ Not found" })
  • Images: $imageCount files in .\images\
  • MCP headlines: $MCPHeadlineCount current stories
  • Intelligence report: .\intelligence-reports\daily-intelligence-$Date.txt

🚀 READY FOR AI INTEGRATION:
  • MCP Server: $(if ($ServerCheck) { "✅ Running" } else { "❌ Not running" }) (http://localhost:3006/sse)
  • Tools available: fetch_news, save_headlines
  • Data sources: Both comprehensive & real-time
  • Visual content: Local images available

🎯 NEXT STEPS:
  1. Connect MCP SuperAssistant browser extension
  2. Use intelligence report prompts with AI assistants
  3. Leverage both automated data and real-time MCP tools
  4. Create content using local images + current analysis

Generated at: $TimeStamp
"@

Write-Log $summary "White"
$summary | Out-File -Path ".\workflow-summary-$Date.txt" -Encoding UTF8

# Send notification if requested
if ($SendNotification) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $notification = New-Object System.Windows.Forms.NotifyIcon
        $notification.Icon = [System.Drawing.SystemIcons]::Information
        $notification.BalloonTipTitle = "Enhanced News Workflow Complete"
        $notification.BalloonTipText = "Intelligence report ready. $imageCount images, $MCPHeadlineCount current headlines. MCP $(if ($ServerCheck) { "ready" } else { "offline" })."
        $notification.Visible = $true
        $notification.ShowBalloonTip(8000)
        Start-Sleep -Seconds 3
        $notification.Dispose()
        Write-Log "🔔 Notification sent" "Yellow"
    } catch {
        Write-Log "⚠️  Could not send notification: $($_.Exception.Message)" "Yellow"
    }
}

Write-Log "🎉 Enhanced News Intelligence Workflow completed successfully!" "Green"
Write-Log "⏰ Total execution time: $((Get-Date) - (Get-Date $TimeStamp))" "Gray"