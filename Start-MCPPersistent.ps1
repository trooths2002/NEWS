#Requires -Version 5.1
<#
.SYNOPSIS
    Start MCP Server in persistent mode with auto-restart
    
.DESCRIPTION
    Starts the minimal MCP server and automatically restarts it if it stops
    
.EXAMPLE
    .\Start-MCPPersistent.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$WorkspacePath = $PSScriptRoot

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "Cyan" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Stop-ExistingProcesses {
    Write-Log "Checking for existing processes on port 3006..."
    
    try {
        $connection = Get-NetTCPConnection -LocalPort 3006 -ErrorAction SilentlyContinue
        if ($connection) {
            $processId = $connection.OwningProcess
            Write-Log "Stopping existing process $processId on port 3006" "WARN"
            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }
    catch {
        # No existing process found
    }
}

function Test-NodeAvailable {
    try {
        $version = & node --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Node.js available: $version" "SUCCESS"
            return $true
        }
    }
    catch {
        Write-Log "Node.js not found" "ERROR"
        return $false
    }
    return $false
}

function Start-MCPServer {
    if (-not (Test-Path "minimal-mcp-server.js")) {
        Write-Log "minimal-mcp-server.js not found" "ERROR"
        return $false
    }
    
    try {
        Write-Log "Starting MCP Server..." "SUCCESS"
        $process = Start-Process -FilePath "node" -ArgumentList "minimal-mcp-server.js" -WorkingDirectory $WorkspacePath -NoNewWindow -PassThru
        
        if ($process) {
            Write-Log "MCP Server started (PID: $($process.Id))" "SUCCESS"
            return $process
        }
    }
    catch {
        Write-Log "Failed to start MCP server: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Test-ServerHealth {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:3006/health" -TimeoutSec 3 -ErrorAction Stop
        return $response -and $response.status -eq "healthy"
    }
    catch {
        return $false
    }
}

# Main execution
try {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║           MCP AI Agent Orchestration - Persistent           ║" -ForegroundColor Green
    Write-Host "║                      PowerShell Mode                        ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    # Pre-flight checks
    if (-not (Test-NodeAvailable)) {
        Write-Log "Node.js is required but not found" "ERROR"
        exit 1
    }
    
    Stop-ExistingProcesses
    
    $restartCount = 0
    $maxRestarts = 10
    
    Write-Log "Starting persistent MCP server..." "SUCCESS"
    Write-Log "Available endpoints:" "INFO"
    Write-Log "  • Health: http://localhost:3006/health" "INFO"
    Write-Log "  • SSE: http://localhost:3006/sse" "INFO"
    Write-Log "  • News API: http://localhost:3006/api/headlines" "INFO"
    Write-Host ""
    Write-Log "Press Ctrl+C to stop the server" "WARN"
    Write-Host ""
    
    while ($restartCount -lt $maxRestarts) {
        $process = Start-MCPServer
        
        if (-not $process) {
            Write-Log "Failed to start server. Exiting." "ERROR"
            break
        }
        
        # Wait for the server to initialize
        Start-Sleep -Seconds 3
        
        # Monitor the process
        $healthCheckFailures = 0
        while (-not $process.HasExited) {
            Start-Sleep -Seconds 10
            
            # Perform health check every 30 seconds
            if ((Get-Date).Second % 30 -eq 0) {
                if (Test-ServerHealth) {
                    Write-Log "Health check passed - Server responding" "SUCCESS"
                    $healthCheckFailures = 0
                } else {
                    $healthCheckFailures++
                    Write-Log "Health check failed ($healthCheckFailures/3)" "WARN"
                    
                    if ($healthCheckFailures -ge 3) {
                        Write-Log "Multiple health check failures. Restarting server..." "ERROR"
                        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                        break
                    }
                }
            }
        }
        
        $exitCode = $process.ExitCode
        Write-Log "Server stopped with exit code: $exitCode" "WARN"
        
        if ($exitCode -eq 0) {
            Write-Log "Server stopped gracefully" "INFO"
            break
        }
        
        $restartCount++
        Write-Log "Restart attempt $restartCount of $maxRestarts in 5 seconds..." "WARN"
        Start-Sleep -Seconds 5
    }
    
    if ($restartCount -ge $maxRestarts) {
        Write-Log "Maximum restart attempts reached. Exiting." "ERROR"
    }
    
}
catch {
    Write-Log "Critical error: $($_.Exception.Message)" "ERROR"
}
finally {
    Write-Log "MCP Server management stopped" "INFO"
}