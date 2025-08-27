# Setup Optimized MCP SuperAssistant Configuration
# Based on official documentation and best practices

Write-Host "🎯 MCP SuperAssistant Optimization Setup" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Check if MCP server is running
Write-Host "🔍 Checking MCP server status..." -ForegroundColor Cyan

$ServerCheck = try {
    Invoke-RestMethod -Uri "http://localhost:3006/health" -Method GET -TimeoutSec 5 | Out-Null
    $true
} catch {
    $false
}

if ($ServerCheck) {
    Write-Host "✅ MCP Server is running on port 3006" -ForegroundColor Green
    $health = Invoke-RestMethod -Uri "http://localhost:3006/health" -Method GET
    Write-Host "📊 Server Status: $($health.status)" -ForegroundColor Cyan
    Write-Host "🛠️  Available Tools: $($health.tools)" -ForegroundColor Cyan
    Write-Host "📡 Endpoint: $($health.endpoint)" -ForegroundColor Cyan
} else {
    Write-Host "❌ MCP Server not running. Please start it first." -ForegroundColor Red
    Write-Host "💡 Run: node mcp-sse-server.js" -ForegroundColor Yellow
    $startNow = Read-Host "Start MCP server now? (y/n)"
    if ($startNow -eq "y" -or $startNow -eq "Y") {
        Write-Host "🚀 Starting MCP server..." -ForegroundColor Yellow
        Start-Process -FilePath "node" -ArgumentList "mcp-sse-server.js" -WindowStyle Normal
        Write-Host "⏳ Waiting for server to start..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        
        $ServerCheck = try {
            Invoke-RestMethod -Uri "http://localhost:3006/health" -Method GET -TimeoutSec 5
            $true
        } catch {
            $false
        }
        
        if ($ServerCheck) {
            Write-Host "✅ MCP Server started successfully!" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to start MCP server. Please check manually." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "👋 Please start MCP server and run this script again." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "🎯 Setting up optimized MCP configuration..." -ForegroundColor Green

# Create optimized prompts directory
$promptsDir = ".\mcp-prompts"
if (!(Test-Path $promptsDir)) {
    New-Item -ItemType Directory -Path $promptsDir -Force
    Write-Host "📁 Created prompts directory: $promptsDir" -ForegroundColor Yellow
}

# Create MCP Instructions Prompt
$mcpInstructions = @"
MCP SUPERASSISTANT INSTRUCTIONS

You have access to a professional news intelligence system through MCP SuperAssistant tools:

AVAILABLE TOOLS:
- fetch_news: Get latest African news headlines (parameter: limit - number of headlines)
- save_headlines: Save headlines to file (parameter: filename - custom filename)

SYSTEM CONTEXT:
- I run comprehensive daily news collection with fetchAllAfrica.js
- All article images are downloaded locally to ./images/ folder  
- Complete archives available in allafrica-headlines.txt
- Real-time analysis capability via MCP tools
- This is a professional intelligence operation

TOOL EXECUTION SETTINGS:
- Use Auto mode for routine analysis
- Use Manual mode for sensitive/critical operations
- Always mention when referencing local image library
- Combine real-time MCP data with archived comprehensive data

WORKFLOW CAPABILITIES:
- Daily intelligence briefings
- Crisis monitoring and alerts
- Visual content strategy (using local images)  
- Market intelligence reports
- Research analysis with historical context

Please acknowledge this setup and confirm tool availability before proceeding.
"@

$mcpInstructions | Out-File -FilePath "$promptsDir\mcp-instructions.txt" -Encoding UTF8
Write-Host "📝 Created MCP instructions prompt: $promptsDir\mcp-instructions.txt" -ForegroundColor Green

# Create Daily Briefing Prompt
$dailyBriefing = @"
DAILY INTELLIGENCE BRIEFING REQUEST

Context: Professional news system with MCP tools + comprehensive daily collection + local image library

Execute:
1. fetch_news with limit 15 for current analysis
2. Reference my daily comprehensive archive (allafrica-headlines.txt)
3. Compare current developments with recent patterns  
4. Identify stories with visual content (./images/ folder)
5. Create executive-level briefing with:
   - Current developments summary
   - Trend analysis vs historical data
   - Visual content opportunities
   - Recommended actions
6. save_headlines to 'executive-brief-[DATE].txt'

Output: Professional intelligence briefing leveraging both real-time and comprehensive data sources.
"@

$dailyBriefing | Out-File -FilePath "$promptsDir\daily-briefing.txt" -Encoding UTF8
Write-Host "📰 Created daily briefing prompt: $promptsDir\daily-briefing.txt" -ForegroundColor Green

# Create Content Strategy Prompt  
$contentStrategy = @"
VISUAL CONTENT STRATEGY REQUEST

Context: News intelligence system with local image downloads + MCP real-time analysis

Execute:
1. fetch_news with limit 20 for current content opportunities
2. Cross-reference with my comprehensive daily archive
3. Identify top 5 stories with highest engagement potential
4. Note stories with supporting visuals (local ./images/ library)
5. Create content strategy for:
   - Social media posts (Twitter, LinkedIn, Instagram)
   - Blog/article opportunities
   - Presentation materials  
6. save_headlines to 'content-strategy-[DATE].txt'

Leverage: Real-time headlines + comprehensive archives + local visual assets
"@

$contentStrategy | Out-File -FilePath "$promptsDir\content-strategy.txt" -Encoding UTF8
Write-Host "📱 Created content strategy prompt: $promptsDir\content-strategy.txt" -ForegroundColor Green

# Create Crisis Monitoring Prompt
$crisisMonitoring = @"
CRISIS INTELLIGENCE MONITORING

Context: Professional monitoring system with MCP + comprehensive archives + visual documentation

Execute:
1. fetch_news with limit 25 for comprehensive crisis scan
2. Keywords: [political instability, natural disasters, economic crisis, security issues]
3. Compare with historical patterns from daily archives
4. Assess urgency levels (High/Medium/Low)
5. Identify visual documentation available (./images/)
6. Create alert summary with:
   - Immediate action items
   - Developing situations to monitor
   - Historical context from archives
7. save_headlines to 'crisis-alerts-[DATE].txt'

Output: Professional crisis intelligence with actionable recommendations
"@

$crisisMonitoring | Out-File -FilePath "$promptsDir\crisis-monitoring.txt" -Encoding UTF8
Write-Host "🚨 Created crisis monitoring prompt: $promptsDir\crisis-monitoring.txt" -ForegroundColor Green

# Create Google AI Studio System Prompt
$googleSystemPrompt = @"
You are a professional intelligence analyst with access to a comprehensive African news system via MCP SuperAssistant.

SYSTEM CAPABILITIES:
- Real-time news fetching via MCP tools
- Comprehensive daily archives with images
- Professional analysis and reporting
- Crisis monitoring and alerting
- Visual content strategy

TOOLS AVAILABLE:
- fetch_news: Current headlines (parameter: limit)
- save_headlines: Archive analysis (parameter: filename)

CONTEXT:
User operates enterprise-grade news intelligence with automated collection, local image storage, and AI-enhanced analysis. Always leverage both real-time MCP data and comprehensive archives for superior intelligence output.

RESPONSE STYLE: Professional, analytical, actionable intelligence briefings.
"@

$googleSystemPrompt | Out-File -FilePath "$promptsDir\google-ai-studio-system-prompt.txt" -Encoding UTF8
Write-Host "🤖 Created Google AI Studio system prompt: $promptsDir\google-ai-studio-system-prompt.txt" -ForegroundColor Green

# Create setup summary
Write-Host ""
Write-Host "📋 Optimization Setup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

Write-Host ""
Write-Host "📁 Created Files:" -ForegroundColor Yellow
Write-Host "  • mcp-instructions.txt - Start every session with this"
Write-Host "  • daily-briefing.txt - Daily intelligence workflow"  
Write-Host "  • content-strategy.txt - Visual content creation"
Write-Host "  • crisis-monitoring.txt - Crisis/opportunity alerts"
Write-Host "  • google-ai-studio-system-prompt.txt - System prompt for Google AI"

Write-Host ""
Write-Host "🔧 Browser Extension Setup:" -ForegroundColor Cyan
Write-Host "  1. Connect to: http://localhost:3006/sse"
Write-Host "  2. Enable auto-connect"
Write-Host "  3. Configure Auto/Manual toggles as needed"

Write-Host ""
Write-Host "⚙️  AI Chat Platform Setup:" -ForegroundColor Cyan
Write-Host "  ChatGPT:"
Write-Host "    • Turn OFF Search Mode"
Write-Host "    • Turn ON Reasoning Mode"  
Write-Host "    • Use GPT-4 or latest model"
Write-Host "    • Start with mcp-instructions.txt content"
Write-Host ""
Write-Host "  Claude/Perplexity:"
Write-Host "    • Disable web search during MCP sessions"
Write-Host "    • Enable reasoning/analysis modes"
Write-Host "    • Use latest/premium models"
Write-Host ""
Write-Host "  Google AI Studio:"
Write-Host "    • Copy google-ai-studio-system-prompt.txt to system prompt"
Write-Host "    • Configure for tool-focused interactions"

Write-Host ""
Write-Host "🎯 Quick Test:" -ForegroundColor Yellow
Write-Host "  1. Copy mcp-instructions.txt to your AI chat"
Write-Host "  2. Wait for acknowledgment"  
Write-Host "  3. Copy daily-briefing.txt"
Write-Host "  4. Verify tools execute and results appear"

Write-Host ""
Write-Host "📊 Daily Workflow:" -ForegroundColor Cyan
Write-Host "  8:15 AM - Check automated collection"
Write-Host "  8:20 AM - Run daily briefing via MCP"
Write-Host "  8:30 AM - Review intelligence reports"
Write-Host "  As needed - Use other workflow prompts"

Write-Host ""
Write-Host "💡 Pro Tips:" -ForegroundColor Green
Write-Host "  • Always mention specific tools you want"
Write-Host "  • Reference your comprehensive data capabilities"
Write-Host "  • Use Auto mode for routine, Manual for critical analysis"
Write-Host "  • Leverage local image library for content advantages"

Write-Host ""
$openPrompts = Read-Host "Open prompts folder to view files? (y/n)"
if ($openPrompts -eq "y" -or $openPrompts -eq "Y") {
    Start-Process explorer.exe -ArgumentList $promptsDir
}

Write-Host ""
Write-Host "🎉 Your MCP SuperAssistant is now optimized for professional intelligence operations!" -ForegroundColor Green
Write-Host "Ready to run world-class news analysis! 🌍📰🚀" -ForegroundColor Cyan