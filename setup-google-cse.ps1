#Requires -Version 5.1

<#
.SYNOPSIS
    Secure Google Custom Search Engine setup assistant.

.DESCRIPTION
    Configures GOOGLE_CSE_ID in a local .env file. GOOGLE_API_KEY must already
    be supplied securely through a local .env file or an environment variable.
    Credential values are never printed.
#>

function Write-Setup {
    param([string]$Message, [string]$Type = "INFO")

    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        "STEP"    { "Cyan" }
        "INPUT"   { "Magenta" }
        default   { "White" }
    }

    Write-Host $Message -ForegroundColor $color
}

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

Write-Setup "=== GOOGLE CUSTOM SEARCH ENGINE SETUP ASSISTANT ===" "STEP"
Write-Setup ""

$apiKey = Get-ConfiguredGoogleApiKey
if ([string]::IsNullOrWhiteSpace($apiKey) -or $apiKey -match '^your_') {
    Write-Setup "ERROR: GOOGLE_API_KEY is not configured securely." "ERROR"
    Write-Setup "Copy .env.template to .env, add the rotated/restricted key locally, and do not commit .env." "WARNING"
    exit 1
}

Write-Setup "STEP 1: Google API key detected without displaying it." "SUCCESS"
Write-Setup ""

Write-Setup "STEP 2: CREATE CUSTOM SEARCH ENGINE" "STEP"
Write-Setup "1. Open https://cse.google.com/cse/" "INFO"
Write-Setup "2. Create a search engine named 'Geopolitical Image Search'." "INFO"
Write-Setup "3. Enable image search." "INFO"
Write-Setup "4. Copy the Search Engine ID." "INFO"
Write-Setup ""

$cseId = Read-Host "Paste your Custom Search Engine ID"
if ([string]::IsNullOrWhiteSpace($cseId)) {
    Write-Setup "ERROR: No CSE ID provided." "ERROR"
    exit 1
}

if ($cseId -notmatch '^[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+$') {
    Write-Setup "ERROR: Invalid CSE ID format." "ERROR"
    exit 1
}

$envPath = ".env"
if (-not (Test-Path $envPath)) {
    Write-Setup "ERROR: Local .env file not found." "ERROR"
    Write-Setup "Copy .env.template to .env and configure it locally." "WARNING"
    exit 1
}

$envContent = Get-Content $envPath -Raw
if ($envContent -match '(?m)^\s*GOOGLE_CSE_ID\s*=') {
    $updatedContent = $envContent -replace '(?m)^\s*GOOGLE_CSE_ID\s*=.*$', "GOOGLE_CSE_ID=$cseId"
} else {
    $updatedContent = $envContent.TrimEnd() + "`r`nGOOGLE_CSE_ID=$cseId`r`n"
}

Set-Content -Path $envPath -Value $updatedContent
Write-Setup "SUCCESS: Updated GOOGLE_CSE_ID in the local .env file." "SUCCESS"
Write-Setup "The API key was not displayed or written to source control." "SUCCESS"
Write-Setup ""

Write-Setup "STEP 3: TEST INTEGRATION" "STEP"
try {
    Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
} catch {
    # No process to stop.
}

Start-Process -FilePath "node" -ArgumentList "geopolitical-intelligence-server.js" -WindowStyle Hidden
Start-Sleep -Seconds 8

try {
    $testRequest = @{
        method = "tools/call"
        params = @{
            name = "search_related_images"
            keywords = "African politics election"
            sources = @("google_images")
            region = "african"
        }
    } | ConvertTo-Json -Depth 3

    $response = Invoke-RestMethod -Uri "http://localhost:3007/mcp" -Method Post -Body $testRequest -ContentType "application/json" -TimeoutSec 30

    if ($response.content) {
        Write-Setup "SUCCESS: Google Images API integration responded." "SUCCESS"
    }
} catch {
    Write-Setup "ERROR: API test failed: $($_.Exception.Message)" "ERROR"
    Write-Setup "Confirm the replacement key restrictions, CSE ID and image-search settings." "WARNING"
}

Write-Setup ""
Write-Setup "SETUP COMPLETE" "SUCCESS"
Write-Setup "Run: powershell -File test-comprehensive-integration.ps1" "INFO"
