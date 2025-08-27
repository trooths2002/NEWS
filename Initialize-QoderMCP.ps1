#Requires -Version 5.1

<#
.SYNOPSIS
    Initialize Qoder MCP integration for News Intelligence Server

.DESCRIPTION
    This script configures Qoder to work with the local MCP news intelligence server.
    It sets up proper configuration, validates connectivity, and provides usage instructions.

.PARAMETER ServerUrl
    The URL of the MCP server (default: http://localhost:3006)

.PARAMETER ConfigPath
    Path to store Qoder configuration (default: .qoder directory)

.EXAMPLE
    .\Initialize-QoderMCP.ps1
    Sets up Qoder MCP integration with default settings

.EXAMPLE
    .\Initialize-QoderMCP.ps1 -ServerUrl "http://localhost:3006" -ConfigPath ".qoder"
    Sets up with custom parameters
#>

[CmdletBinding()]
param(
    [string]$ServerUrl = "http://localhost:3006",
    [string]$ConfigPath = ".qoder"
)

function Write-StatusMessage {
    param([string]$Message, [string]$Status = "INFO")
    
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        default   { "Cyan" }
    }
    
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

function Test-ServerConnectivity {
    param([string]$Url)
    
    try {
        $response = Invoke-RestMethod -Uri "$Url/health" -Method Get -TimeoutSec 5
        return $response.status -eq "healthy"
    }
    catch {
        return $false
    }
}

function Initialize-QoderConfiguration {
    param([string]$ServerUrl, [string]$ConfigDir)
    
    # Create configuration directory
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
        Write-StatusMessage "Created Qoder configuration directory: $ConfigDir" "SUCCESS"
    }
    
    # Generate Qoder MCP configuration
    $qoderConfig = @{
        qoder = @{
            mcp = @{
                enabled = $true
                autoConnect = $true
                servers = @{
                    newsIntelligence = @{
                        name = "News Intelligence Server"
                        url = $ServerUrl
                        type = "http"
                        protocol = "mcp"
                        endpoints = @{
                            health = "/health"
                            mcp = "/mcp"
                            sse = "/sse"
                            api = "/api"
                        }
                        tools = @("fetch_news", "save_headlines", "read_file")
                        autostart = $true
                        timeout = 30
                    }
                }
                settings = @{
                    maxTools = 64
                    autoInvoke = $false
                    logLevel = "info"
                }
            }
        }
    }
    
    # Save configuration
    $configPath = Join-Path $ConfigDir "mcp-config.json"
    $qoderConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
    Write-StatusMessage "Saved Qoder MCP configuration: $configPath" "SUCCESS"
    
    return $configPath
}

function Initialize-QoderPrompts {
    param([string]$ConfigDir)
    
    $promptsDir = Join-Path $ConfigDir "prompts"
    if (-not (Test-Path $promptsDir)) {
        New-Item -ItemType Directory -Path $promptsDir -Force | Out-Null
    }
    
    # Create news intelligence prompts
    $newsPrompts = @"
# News Intelligence Prompts for Qoder

## Quick Actions
- **Fetch News**: Use #fetch_news to get latest African headlines
- **Save Headlines**: Use #save_headlines to archive current news
- **Check Status**: Use the health endpoint to verify server status

## Analysis Prompts
1. "Analyze latest African news trends using the news intelligence tools"
2. "Fetch and summarize today's top headlines from AllAfrica"
3. "Compare current news with historical data in the archives"
4. "Generate an executive briefing from recent news headlines"

## Workflow Examples
```text
# Daily news briefing
Please use the news tools to fetch latest headlines and create an executive summary

# Trend analysis
Analyze recent news patterns and identify key themes in African news

# Crisis monitoring
Check for any urgent or high-priority news items that require attention
```

## Tool References
- fetch_news: Retrieves latest news from AllAfrica.com RSS feed
- save_headlines: Saves current headlines to local file
- read_file: Accesses historical news archives
- health_check: Verifies MCP server status
"@
    
    $promptsPath = Join-Path $promptsDir "news-intelligence.md"
    $newsPrompts | Set-Content -Path $promptsPath -Encoding UTF8
    Write-StatusMessage "Created Qoder prompts: $promptsPath" "SUCCESS"
}

# Main execution
Write-StatusMessage "Initializing Qoder MCP integration for News Intelligence Server" "INFO"

# Validate server connectivity
Write-StatusMessage "Testing server connectivity at $ServerUrl..." "INFO"
if (-not (Test-ServerConnectivity -Url $ServerUrl)) {
    Write-StatusMessage "Cannot connect to MCP server at $ServerUrl" "ERROR"
    Write-StatusMessage "Please ensure the server is running: node minimal-mcp-server.js" "WARNING"
    exit 1
}
Write-StatusMessage "Server connectivity verified" "SUCCESS"

# Initialize configuration
$configPath = Initialize-QoderConfiguration -ServerUrl $ServerUrl -ConfigDir $ConfigPath
Initialize-QoderPrompts -ConfigDir $ConfigPath

# Display usage instructions
Write-Host ""
Write-StatusMessage "Qoder MCP Integration Setup Complete!" "SUCCESS"
Write-Host ""
Write-Host "Configuration Details:" -ForegroundColor Yellow
Write-Host "  Server URL: $ServerUrl" -ForegroundColor White
Write-Host "  Config Path: $configPath" -ForegroundColor White
Write-Host "  Prompts: $ConfigPath/prompts/news-intelligence.md" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Restart Qoder to load the new configuration" -ForegroundColor White
Write-Host "  2. Look for MCP tools in Qoder's tool menu" -ForegroundColor White
Write-Host "  3. Test with: 'Use news tools to fetch latest headlines'" -ForegroundColor White
Write-Host "  4. Reference tools with # syntax: #fetch_news" -ForegroundColor White
Write-Host ""
Write-Host "Server Status:" -ForegroundColor Yellow

try {
    $healthResponse = Invoke-RestMethod -Uri "$ServerUrl/health" -Method Get
    Write-Host "  Status: $($healthResponse.status)" -ForegroundColor Green
    Write-Host "  Uptime: $([math]::Round($healthResponse.uptime, 2)) seconds" -ForegroundColor White
    Write-Host "  Available Tools: $($healthResponse.endpoints.Count)" -ForegroundColor White
}
catch {
    Write-StatusMessage "Could not retrieve detailed server status" "WARNING"
}

Write-Host ""
Write-StatusMessage "Integration ready! Your news intelligence MCP server is now configured for Qoder." "SUCCESS"