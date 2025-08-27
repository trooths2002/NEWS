#Requires -Version 5.1
<#
.SYNOPSIS
    Launch News Automation MCP Orchestrator
    
.DESCRIPTION
    This script starts the MCP server that orchestrates the entire 
    news automation build and deployment process.
    
.PARAMETER Action
    Action to perform: start, test, status
    
.EXAMPLE
    .\start-mcp-orchestrator.ps1 -Action start
#>

[CmdletBinding()]
param(
    [ValidateSet("start", "test", "status", "demo")]
    [string]$Action = "start"
)

$WorkspacePath = $PSScriptRoot
$LogFile = Join-Path $WorkspacePath "logs\mcp-orchestrator.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"}elseif($Level -eq "WARN"){"Yellow"}else{"Green"})
    
    # Create logs directory if it doesn't exist
    $logsDir = Split-Path $LogFile -Parent
    if (-not (Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    }
    
    Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
}

function Start-MCPOrchestrator {
    Write-Log "Starting MCP News Automation Orchestrator..."
    
    try {
        # Check if Node.js is available
        $nodeVersion = & node --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Node.js is required but not found!" "ERROR"
            return $false
        }
        Write-Log "Node.js detected: $nodeVersion"
        
        # Check if mcp-server.js exists
        $mcpServerPath = Join-Path $WorkspacePath "mcp-server.js"
        if (-not (Test-Path $mcpServerPath)) {
            Write-Log "MCP server script not found: $mcpServerPath" "ERROR"
            return $false
        }
        
        # Start the MCP server
        Write-Log "Launching MCP Orchestrator on stdio..."
        Write-Host ""
        Write-Host "🚀 MCP News Automation Orchestrator Ready!" -ForegroundColor Green
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host "Available Tools:" -ForegroundColor Yellow
        Write-Host "  • initialize_project    - Set up complete project structure" -ForegroundColor White
        Write-Host "  • install_dependencies  - Install all required packages" -ForegroundColor White
        Write-Host "  • build_automation_system - Create automation scripts" -ForegroundColor White
        Write-Host "  • deploy_production_system - Deploy with scheduling" -ForegroundColor White
        Write-Host "  • start_mcp_servers     - Launch additional MCP servers" -ForegroundColor White
        Write-Host "  • validate_system       - Comprehensive health checks" -ForegroundColor White
        Write-Host "  • generate_documentation - Create complete docs" -ForegroundColor White
        Write-Host ""
        Write-Host "Connect your MCP client to this server to orchestrate builds!" -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Start the server
        Set-Location $WorkspacePath
        & node mcp-server.js
        
        return $true
        
    } catch {
        Write-Log "Failed to start MCP orchestrator: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-MCPOrchestrator {
    Write-Log "Testing MCP Orchestrator availability..."
    
    # Check Node.js
    try {
        $nodeVersion = & node --version 2>$null
        Write-Log "✅ Node.js available: $nodeVersion"
    } catch {
        Write-Log "❌ Node.js not available" "ERROR"
    }
    
    # Check MCP server script
    $mcpServerPath = Join-Path $WorkspacePath "mcp-server.js"
    if (Test-Path $mcpServerPath) {
        Write-Log "✅ MCP server script found"
    } else {
        Write-Log "❌ MCP server script missing" "ERROR"
    }
    
    # Check package.json
    $packagePath = Join-Path $WorkspacePath "package.json"
    if (Test-Path $packagePath) {
        try {
            $package = Get-Content $packagePath | ConvertFrom-Json
            Write-Log "✅ Package.json valid: $($package.name) v$($package.version)"
        } catch {
            Write-Log "❌ Package.json invalid" "ERROR"
        }
    } else {
        Write-Log "❌ Package.json missing" "ERROR"
    }
}

function Show-Status {
    Write-Log "MCP Orchestrator Status Check..."
    
    Write-Host ""
    Write-Host "📊 NEWS AUTOMATION MCP ORCHESTRATOR STATUS" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    
    # Check workspace
    Write-Host "Workspace: $WorkspacePath" -ForegroundColor Cyan
    
    # Check key files
    $keyFiles = @(
        "mcp-server.js",
        "package.json"
    )
    
    foreach ($file in $keyFiles) {
        $filePath = Join-Path $WorkspacePath $file
        if (Test-Path $filePath) {
            Write-Host "✅ $file" -ForegroundColor Green
        } else {
            Write-Host "❌ $file (missing)" -ForegroundColor Red
        }
    }
    
    # Check directories
    $keyDirs = @("src", "config", "logs", "scripts")
    foreach ($dir in $keyDirs) {
        $dirPath = Join-Path $WorkspacePath $dir
        if (Test-Path $dirPath) {
            Write-Host "✅ $dir/" -ForegroundColor Green
        } else {
            Write-Host "⚠️ $dir/ (will be created)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "🔧 AVAILABLE COMMANDS:" -ForegroundColor Yellow
    Write-Host "  .\start-mcp-orchestrator.ps1 -Action start" -ForegroundColor White
    Write-Host "  .\start-mcp-orchestrator.ps1 -Action test" -ForegroundColor White
    Write-Host "  .\start-mcp-orchestrator.ps1 -Action demo" -ForegroundColor White
    Write-Host ""
}

function Show-Demo {
    Write-Host ""
    Write-Host "🎬 MCP ORCHESTRATOR DEMO" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    Write-Host ""
    Write-Host "This MCP server orchestrates complete project builds:" -ForegroundColor White
    Write-Host ""
    Write-Host "1️⃣ INITIALIZE PROJECT" -ForegroundColor Yellow
    Write-Host "   Creates full directory structure, package.json, configuration" -ForegroundColor White
    Write-Host ""
    Write-Host "2️⃣ INSTALL DEPENDENCIES" -ForegroundColor Yellow
    Write-Host "   Installs all npm packages required for automation" -ForegroundColor White
    Write-Host ""
    Write-Host "3️⃣ BUILD AUTOMATION SYSTEM" -ForegroundColor Yellow
    Write-Host "   Generates news automation scripts with error handling" -ForegroundColor White
    Write-Host ""
    Write-Host "4️⃣ DEPLOY TO PRODUCTION" -ForegroundColor Yellow
    Write-Host "   Sets up Windows Task Scheduler and monitoring" -ForegroundColor White
    Write-Host ""
    Write-Host "5️⃣ START MCP SERVERS" -ForegroundColor Yellow
    Write-Host "   Launches Browser MCP and other integration servers" -ForegroundColor White
    Write-Host ""
    Write-Host "6️⃣ VALIDATE SYSTEM" -ForegroundColor Yellow
    Write-Host "   Comprehensive health checks and performance tests" -ForegroundColor White
    Write-Host ""
    Write-Host "🔗 Connect your MCP client to orchestrate the entire build!" -ForegroundColor Cyan
    Write-Host ""
}

# Main execution
try {
    Write-Host ""
    Write-Host "🤖 News Automation MCP Orchestrator" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host ""
    
    switch ($Action) {
        "start" {
            $success = Start-MCPOrchestrator
            if (-not $success) {
                Write-Log "Failed to start MCP orchestrator" "ERROR"
                exit 1
            }
        }
        "test" {
            Test-MCPOrchestrator
        }
        "status" {
            Show-Status
        }
        "demo" {
            Show-Demo
        }
    }
    
} catch {
    Write-Log "Critical error: $($_.Exception.Message)" "ERROR"
    exit 1
}