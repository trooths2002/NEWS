# Ultimate MCP Multi-Server Setup Script
# Automates installation and configuration of all 5 MCP servers

param(
    [string]$Mode = "setup",  # setup, start, stop, status, test
    [string]$GitHubToken = "",
    [string]$BraveApiKey = ""
)

$ProjectPath = "C:\Users\tjd20.LAPTOP-PCMC2SUO\news"
$LogFile = "$ProjectPath\mcp-setup.log"

function Write-LoggedOutput {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $logMessage
}

function Test-Port {
    param([int]$Port)
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $Port -InformationLevel Quiet
        return $connection
    } catch {
        return $false
    }
}

function Stop-ProcessOnPort {
    param([int]$Port)
    try {
        $processes = netstat -ano | Select-String ":$Port " | ForEach-Object {
            $parts = $_.ToString().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
            if ($parts.Length -ge 5) { $parts[-1] }
        }
        
        foreach ($processId in $processes) {
            if ($processId -and $processId -ne "0") {
                Write-LoggedOutput "Stopping process $processId on port $Port" "Yellow"
                taskkill /F /PID $processId 2>$null
            }
        }
        Start-Sleep -Seconds 2
    } catch {
        Write-LoggedOutput "Error stopping processes on port $Port`: $_" "Red"
    }
}

function Install-MCPServers {
    Write-LoggedOutput "🚀 Installing MCP Servers..." "Cyan"
    
    # Change to project directory
    Set-Location $ProjectPath
    
    # Install core dependencies
    Write-LoggedOutput "Installing core dependencies..." "Yellow"
    npm install express cors rss-parser node-fetch cheerio 2>&1 | Tee-Object -Append -FilePath $LogFile
    
    # Install MCP servers
    $servers = @(
        "@modelcontextprotocol/server-filesystem",
        "@modelcontextprotocol/server-sqlite",
        "@modelcontextprotocol/server-github", 
        "@modelcontextprotocol/server-brave-search"
    )
    
    foreach ($server in $servers) {
        Write-LoggedOutput "Installing $server..." "Yellow"
        npm install $server 2>&1 | Tee-Object -Append -FilePath $LogFile
    }
    
    Write-LoggedOutput "✅ MCP Servers installed successfully!" "Green"
}

function Start-MCPProxy {
    Write-LoggedOutput "🌟 Starting Multi-Server MCP Proxy..." "Cyan"
    
    # Stop any existing processes on port 3006
    Stop-ProcessOnPort -Port 3006
    
    # Set environment variables if provided
    if ($GitHubToken) {
        $env:GITHUB_PERSONAL_ACCESS_TOKEN = $GitHubToken
        Write-LoggedOutput "GitHub token configured" "Green"
    }
    
    if ($BraveApiKey) {
        $env:BRAVE_API_KEY = $BraveApiKey
        Write-LoggedOutput "Brave Search API key configured" "Green"
    }
    
    # Change to project directory
    Set-Location $ProjectPath
    
    # Start the multi-server proxy
    Write-LoggedOutput "Starting multi-server proxy on port 3006..." "Yellow"
    Start-Process -FilePath "node" -ArgumentList "multi-server-mcp-proxy.js" -WorkingDirectory $ProjectPath
    
    # Wait for server to start
    Start-Sleep -Seconds 5
    
    # Test connection
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:3006/health" -Method Get -TimeoutSec 10
        Write-LoggedOutput "✅ Multi-Server MCP Proxy started successfully!" "Green"
        Write-LoggedOutput "📡 SSE Endpoint: http://localhost:3006/sse" "Cyan"
        Write-LoggedOutput "🔧 Health Check: http://localhost:3006/health" "Cyan"
        Write-LoggedOutput "🛠️ Available servers: $($response.servers.Keys -join ', ')" "Green"
        Write-LoggedOutput "🔨 Available tools: $($response.tools -join ', ')" "Green"
        return $true
    } catch {
        Write-LoggedOutput "❌ Failed to start MCP Proxy: $_" "Red"
        return $false
    }
}

function Stop-MCPProxy {
    Write-LoggedOutput "🛑 Stopping MCP Proxy..." "Yellow"
    Stop-ProcessOnPort -Port 3006
    Write-LoggedOutput "✅ MCP Proxy stopped" "Green"
}

function Test-MCPSetup {
    Write-LoggedOutput "🧪 Testing MCP Setup..." "Cyan"
    
    # Test health endpoint
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:3006/health" -Method Get
        Write-LoggedOutput "✅ Health check passed" "Green"
        Write-LoggedOutput "   Servers: $($health.servers.Keys -join ', ')" "White"
        Write-LoggedOutput "   Tools: $($health.tools.Count) available" "White"
        
        # Test MCP protocol
        $mcpRequest = @{
            jsonrpc = "2.0"
            method = "tools/list"
            id = 1
        }
        
        $mcpResponse = Invoke-RestMethod -Uri "http://localhost:3006/mcp" -Method Post -Body ($mcpRequest | ConvertTo-Json) -ContentType "application/json"
        Write-LoggedOutput "✅ MCP protocol test passed" "Green"
        Write-LoggedOutput "   Available MCP tools: $($mcpResponse.result.tools.Count)" "White"
        
        return $true
    } catch {
        Write-LoggedOutput "❌ MCP setup test failed: $_" "Red"
        return $false
    }
}

function Show-Status {
    Write-LoggedOutput "📊 MCP Multi-Server Status..." "Cyan"
    
    # Check if port 3006 is in use
    $port3006InUse = Test-Port -Port 3006
    if ($port3006InUse) {
        Write-LoggedOutput "✅ Port 3006: In Use (MCP Proxy likely running)" "Green"
        
        # Try to get health status
        try {
            $health = Invoke-RestMethod -Uri "http://localhost:3006/health" -Method Get -TimeoutSec 5
            Write-LoggedOutput "✅ MCP Proxy: Running" "Green"
            Write-LoggedOutput "   Endpoint: http://localhost:3006/sse" "Cyan"
            Write-LoggedOutput "   Servers: $($health.servers.Keys -join ', ')" "White"
            Write-LoggedOutput "   Tools: $($health.tools.Count) available" "White"
        } catch {
            Write-LoggedOutput "⚠️ Port 3006 in use but health check failed" "Yellow"
        }
    } else {
        Write-LoggedOutput "❌ Port 3006: Not in use (MCP Proxy not running)" "Red"
    }
    
    # Check installed packages
    Write-LoggedOutput "📦 Checking installed MCP packages..." "Yellow"
    Set-Location $ProjectPath
    
    $packages = @(
        "@modelcontextprotocol/server-filesystem",
        "@modelcontextprotocol/server-sqlite",
        "@modelcontextprotocol/server-github",
        "@modelcontextprotocol/server-brave-search"
    )
    
    foreach ($package in $packages) {
        try {
            npm list $package 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-LoggedOutput "✅ ${package}: Installed" "Green"
            } else {
                Write-LoggedOutput "❌ ${package}: Not installed" "Red"
            }
        } catch {
            Write-LoggedOutput "❌ ${package}: Not installed" "Red"
        }
    }
}

function Show-Help {
    Write-LoggedOutput "🆘 MCP Multi-Server Management Help" "Cyan"
    Write-LoggedOutput ""
    Write-LoggedOutput "Usage: .\setup-ultimate-mcp.ps1 -Mode <mode> [options]" "White"
    Write-LoggedOutput ""
    Write-LoggedOutput "Modes:" "Yellow"
    Write-LoggedOutput "  setup    - Install all MCP servers and dependencies" "White"
    Write-LoggedOutput "  start    - Start the multi-server MCP proxy" "White" 
    Write-LoggedOutput "  stop     - Stop the MCP proxy" "White"
    Write-LoggedOutput "  status   - Show current status of all servers" "White"
    Write-LoggedOutput "  test     - Test the MCP setup and connections" "White"
    Write-LoggedOutput "  help     - Show this help message" "White"
    Write-LoggedOutput ""
    Write-LoggedOutput "Options:" "Yellow"
    Write-LoggedOutput "  -GitHubToken <token>   - Set GitHub Personal Access Token" "White"
    Write-LoggedOutput "  -BraveApiKey <key>     - Set Brave Search API Key" "White"
    Write-LoggedOutput ""
    Write-LoggedOutput "Examples:" "Yellow"
    Write-LoggedOutput "  .\setup-ultimate-mcp.ps1 -Mode setup" "White"
    Write-LoggedOutput "  .\setup-ultimate-mcp.ps1 -Mode start" "White"
    Write-LoggedOutput "  .\setup-ultimate-mcp.ps1 -Mode start -GitHubToken 'ghp_xxx' -BraveApiKey 'BSA-xxx'" "White"
    Write-LoggedOutput "  .\setup-ultimate-mcp.ps1 -Mode status" "White"
}

# Main execution
Write-LoggedOutput "🚀 MCP Multi-Server Management Script" "Cyan"
Write-LoggedOutput "Mode: $Mode" "White"

switch ($Mode.ToLower()) {
    "setup" {
        Install-MCPServers
    }
    "start" {
        $success = Start-MCPProxy
        if ($success) {
            Write-LoggedOutput "🎉 Ready to connect MCP SuperAssistant to http://localhost:3006/sse" "Green"
        }
    }
    "stop" {
        Stop-MCPProxy
    }
    "status" {
        Show-Status
    }
    "test" {
        Test-MCPSetup
    }
    "help" {
        Show-Help
    }
    default {
        Write-LoggedOutput "❌ Unknown mode: $Mode" "Red"
        Show-Help
    }
}

Write-LoggedOutput "✅ Script completed. Check $LogFile for detailed logs." "Green"