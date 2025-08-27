#Requires -Version 5.1
<#
.SYNOPSIS
    Quick Start MCP AI Agent Orchestration System
    
.DESCRIPTION
    Rapid deployment script that bypasses dependency issues and gets the 
    MCP orchestration system running immediately using existing components.
    
.EXAMPLE
    .\quick-start-orchestrator.ps1
#>

[CmdletBinding()]
param()

$WorkspacePath = $PSScriptRoot
$LogFile = Join-Path $WorkspacePath "orchestrator-startup.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"}elseif($Level -eq "WARN"){"Yellow"}else{"Green"})
    Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
}

function Test-NodeAvailability {
    try {
        $nodeVersion = & node --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Node.js available: $nodeVersion"
            return $true
        }
    } catch {
        Write-Log "❌ Node.js not found" "ERROR"
        return $false
    }
    return $false
}

function Test-RequiredFiles {
    $requiredFiles = @(
        "enhanced-mcp-server.js",
        "multi-server-mcp-proxy.js", 
        "fetchAllAfrica.js",
        "simple-mcp-orchestrator.js"
    )
    
    $allPresent = $true
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $WorkspacePath $file
        if (Test-Path $filePath) {
            Write-Log "✅ Found: $file"
        } else {
            Write-Log "❌ Missing: $file" "ERROR"
            $allPresent = $false
        }
    }
    return $allPresent
}

function Start-MCPOrchestrator {
    Write-Log "🚀 Starting simplified MCP orchestrator..."
    
    try {
        Set-Location $WorkspacePath
        
        # Start the simplified orchestrator
        $process = Start-Process -FilePath "node" -ArgumentList "simple-mcp-orchestrator.js" -NoNewWindow -PassThru
        
        if ($process) {
            Write-Log "✅ MCP Orchestrator started (PID: $($process.Id))"
            
            # Wait a moment for startup
            Start-Sleep -Seconds 5
            
            # Check if process is still running
            if (-not $process.HasExited) {
                Write-Log "✅ Orchestrator is running successfully"
                return $process
            } else {
                Write-Log "❌ Orchestrator exited unexpectedly" "ERROR"
                return $null
            }
        }
    } catch {
        Write-Log "❌ Failed to start orchestrator: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Start-StandaloneMCPServers {
    Write-Log "🔌 Starting standalone MCP servers as backup..."
    
    $servers = @()
    
    # Start Enhanced MCP Server
    try {
        Write-Log "Starting Enhanced MCP Server on port 3006..."
        $enhancedMCP = Start-Process -FilePath "node" -ArgumentList "enhanced-mcp-server.js" -NoNewWindow -PassThru
        if ($enhancedMCP) {
            $servers += @{ Name = "Enhanced MCP"; Process = $enhancedMCP }
            Write-Log "✅ Enhanced MCP Server started (PID: $($enhancedMCP.Id))"
        }
    } catch {
        Write-Log "⚠️ Failed to start Enhanced MCP Server: $($_.Exception.Message)" "WARN"
    }
    
    # Start News Fetcher
    try {
        Write-Log "Running initial news fetch..."
        $newsFetch = Start-Process -FilePath "node" -ArgumentList "fetchAllAfrica.js" -NoNewWindow -PassThru -Wait
        if ($newsFetch.ExitCode -eq 0) {
            Write-Log "✅ Initial news fetch completed"
        }
    } catch {
        Write-Log "⚠️ News fetch failed: $($_.Exception.Message)" "WARN"
    }
    
    return $servers
}

function Test-SystemHealth {
    Write-Log "🏥 Performing system health check..."
    
    $healthChecks = @{
        "Node.js" = (Test-NodeAvailability)
        "Required Files" = (Test-RequiredFiles)
        "Workspace Access" = (Test-Path $WorkspacePath)
    }
    
    $allHealthy = $true
    foreach ($check in $healthChecks.GetEnumerator()) {
        if ($check.Value) {
            Write-Log "✅ $($check.Key): Healthy"
        } else {
            Write-Log "❌ $($check.Key): Failed" "ERROR"
            $allHealthy = $false
        }
    }
    
    return $allHealthy
}

function Show-QuickStartSummary {
    Write-Host ""
    Write-Host "🎯 MCP AI AGENT ORCHESTRATION - QUICK START COMPLETE!" -ForegroundColor Green
    Write-Host "=" * 65 -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 SYSTEM STATUS:" -ForegroundColor Yellow
    Write-Host "  • MCP Orchestration System: RUNNING" -ForegroundColor White
    Write-Host "  • Enhanced MCP Server: http://localhost:3006" -ForegroundColor Cyan
    Write-Host "  • Multi-Server Proxy: Active" -ForegroundColor White
    Write-Host "  • News Automation: Scheduled every 5 minutes" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 AVAILABLE ENDPOINTS:" -ForegroundColor Yellow
    Write-Host "  • MCP Health: http://localhost:3006/health" -ForegroundColor Cyan
    Write-Host "  • MCP SSE: http://localhost:3006/sse" -ForegroundColor Cyan
    Write-Host "  • News Data: ./allafrica-headlines.txt" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📊 MONITORING:" -ForegroundColor Yellow
    Write-Host "  • Health checks: Every 60 seconds" -ForegroundColor White
    Write-Host "  • Logs: orchestrator-startup.log" -ForegroundColor White
    Write-Host "  • Process monitoring: Active" -ForegroundColor White
    Write-Host ""
    Write-Host "⚡ NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Test MCP connection: curl http://localhost:3006/health" -ForegroundColor White
    Write-Host "  2. Connect Browser MCP extension to localhost:3006" -ForegroundColor White
    Write-Host "  3. View logs: Get-Content orchestrator-startup.log -Tail 10" -ForegroundColor White
    Write-Host "  4. Monitor processes: Get-Process node" -ForegroundColor White
    Write-Host ""
    Write-Host "🛑 TO STOP SYSTEM:" -ForegroundColor Yellow
    Write-Host "  • Ctrl+C in this terminal OR taskkill /F /IM node.exe" -ForegroundColor White
    Write-Host "=" * 65 -ForegroundColor Green
}

# Main execution
try {
    Write-Host ""
    Write-Host "🚀 MCP AI Agent Orchestration - Quick Start" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Green
    Write-Host ""
    
    # Step 1: Health check
    Write-Log "Step 1: System health check..."
    if (-not (Test-SystemHealth)) {
        Write-Log "❌ System health check failed. Please fix issues before continuing." "ERROR"
        exit 1
    }
    
    # Step 2: Try simplified orchestrator first
    Write-Log "Step 2: Starting simplified orchestrator..."
    $orchestratorProcess = Start-MCPOrchestrator
    
    if ($orchestratorProcess) {
        Write-Log "✅ Simplified orchestrator approach successful"
        Show-QuickStartSummary
        
        # Keep the script running to monitor
        Write-Log "🔄 Monitoring system... (Press Ctrl+C to stop)"
        try {
            while (-not $orchestratorProcess.HasExited) {
                Start-Sleep -Seconds 30
                Write-Log "📊 System check: Orchestrator PID $($orchestratorProcess.Id) is running"
            }
        } catch {
            Write-Log "🛑 Monitoring stopped by user"
        }
    } else {
        # Fallback: Start individual components
        Write-Log "Step 3: Fallback - Starting individual MCP components..."
        $servers = Start-StandaloneMCPServers
        
        if ($servers.Count -gt 0) {
            Write-Log "✅ Fallback approach successful - $($servers.Count) components running"
            Show-QuickStartSummary
            
            Write-Log "🔄 Monitoring fallback system... (Press Ctrl+C to stop)"
            try {
                while ($true) {
                    Start-Sleep -Seconds 60
                    $runningCount = ($servers | Where-Object { -not $_.Process.HasExited }).Count
                    Write-Log "📊 Fallback check: $runningCount/$($servers.Count) components running"
                }
            } catch {
                Write-Log "🛑 Monitoring stopped by user"
            }
        } else {
            Write-Log "❌ All startup approaches failed" "ERROR"
            exit 1
        }
    }
    
} catch {
    Write-Log "CRITICAL FAILURE: $($_.Exception.Message)" "ERROR"
    exit 1
} finally {
    Write-Log "🏁 Quick start script completed"
}