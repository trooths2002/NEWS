# Start MCP Server for News Fetcher
# This script starts the MCP server that provides news fetching capabilities

Write-Host "Starting MCP Server for News Fetcher..." -ForegroundColor Green

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "Node.js version: $nodeVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Error: Node.js is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Change to the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Install dependencies if node_modules doesn't exist
if (!(Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
}

# Check if port 3006 is already in use
$portInUse = Get-NetTCPConnection -LocalPort 3006 -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host "Warning: Port 3006 is already in use" -ForegroundColor Yellow
    Write-Host "Attempting to start server anyway..." -ForegroundColor Yellow
}

# Start the MCP server
Write-Host "Starting MCP server on http://localhost:3006..." -ForegroundColor Green
Write-Host "SSE endpoint: http://localhost:3006/sse" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

try {
    npm run mcp-server
} catch {
    Write-Host "Failed to start MCP server" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}