#Requires -Version 5.1

<#
.SYNOPSIS
    Configure a Google Custom Search Engine ID without exposing credentials.

.DESCRIPTION
    Updates the local .env file with GOOGLE_CSE_ID. The Google API key must be
    supplied through a local .env file or the GOOGLE_API_KEY process/user
    environment variable. The key is never printed.
#>

function Get-ConfiguredGoogleApiKey {
    $value = [Environment]::GetEnvironmentVariable("GOOGLE_API_KEY")
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        return $value
    }

    if (Test-Path ".env") {
        $line = Get-Content ".env" |
            Where-Object { $_ -match '^\s*GOOGLE_API_KEY\s*=' } |
            Select-Object -First 1

        if ($line) {
            return ($line -split '=', 2)[1].Trim()
        }
    }

    return $null
}

Write-Host "=== GOOGLE CSE ID CONFIGURATION ===" -ForegroundColor Cyan
Write-Host ""

$apiKey = Get-ConfiguredGoogleApiKey
if ([string]::IsNullOrWhiteSpace($apiKey) -or $apiKey -match '^your_') {
    Write-Host "ERROR: GOOGLE_API_KEY is not configured securely." -ForegroundColor Red
    Write-Host "Set it in a local .env file copied from .env.template, or in your environment." -ForegroundColor Yellow
    Write-Host "Never commit the resulting .env file." -ForegroundColor Yellow
    exit 1
}

Write-Host "Google API key detected. Its value will not be displayed." -ForegroundColor Green
Write-Host ""
Write-Host "Enter your Custom Search Engine ID." -ForegroundColor Yellow
Write-Host "Expected format: abc123def456:ghijklmnop" -ForegroundColor Gray
Write-Host ""

$cseId = Read-Host "Enter your CSE ID"

if ([string]::IsNullOrWhiteSpace($cseId)) {
    Write-Host "ERROR: No CSE ID provided." -ForegroundColor Red
    exit 1
}

if ($cseId -notmatch '^[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+$') {
    Write-Host "ERROR: Invalid CSE ID format." -ForegroundColor Red
    Write-Host "Expected format: abc123:def456" -ForegroundColor Gray
    exit 1
}

$envPath = ".env"
if (-not (Test-Path $envPath)) {
    Write-Host "ERROR: Local .env file not found." -ForegroundColor Red
    Write-Host "Copy .env.template to .env, add the rotated/restricted key locally, and run again." -ForegroundColor Yellow
    exit 1
}

$envContent = Get-Content $envPath -Raw
if ($envContent -match '(?m)^\s*GOOGLE_CSE_ID\s*=') {
    $updatedContent = $envContent -replace '(?m)^\s*GOOGLE_CSE_ID\s*=.*$', "GOOGLE_CSE_ID=$cseId"
} else {
    $updatedContent = $envContent.TrimEnd() + "`r`nGOOGLE_CSE_ID=$cseId`r`n"
}

Set-Content -Path $envPath -Value $updatedContent
Write-Host "SUCCESS: Updated GOOGLE_CSE_ID in the local .env file." -ForegroundColor Green
Write-Host "The API key was not displayed or written to source control." -ForegroundColor Green
Write-Host ""

Write-Host "Restarting the local Node server..." -ForegroundColor Cyan
try {
    Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
} catch {
    # No process to stop.
}

Start-Sleep -Seconds 2
Start-Process -FilePath "node" -ArgumentList "geopolitical-intelligence-server.js" -WindowStyle Hidden

Write-Host "Configuration complete." -ForegroundColor Green
Write-Host "Test with: powershell -File test-comprehensive-integration.ps1" -ForegroundColor Gray
