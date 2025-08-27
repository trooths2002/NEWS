#Requires -Version 5.1

<#
.SYNOPSIS
    Simple CSE ID Configuration Helper

.DESCRIPTION
    Updates .env file with your Custom Search Engine ID
#>

Write-Host "=== GOOGLE CSE ID CONFIGURATION ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Your Google API Key is already configured" -ForegroundColor Green
Write-Host "   AIzaSyB8yvuzAdDx1GDsdRp4ulReaC7Y9BTEBdw" -ForegroundColor Green
Write-Host ""

Write-Host "📝 Please enter your Custom Search Engine ID" -ForegroundColor Yellow
Write-Host "   (Format should be like: abc123def456:ghijklmnop)" -ForegroundColor Gray
Write-Host ""

$cseId = Read-Host "Enter your CSE ID"

if ($cseId -and $cseId.Trim() -ne "") {
    if ($cseId -match "^[a-zA-Z0-9]+:[a-zA-Z0-9]+$") {
        # Update .env file
        $envPath = ".env"
        
        if (Test-Path $envPath) {
            $envContent = Get-Content $envPath -Raw
            $updatedContent = $envContent -replace "GOOGLE_CSE_ID=your_custom_search_engine_id_here", "GOOGLE_CSE_ID=$cseId"
            
            Set-Content -Path $envPath -Value $updatedContent
            
            Write-Host "✅ SUCCESS: Updated .env file!" -ForegroundColor Green
            Write-Host "   GOOGLE_CSE_ID=$cseId" -ForegroundColor Green
            Write-Host ""
            
            Write-Host "🔄 Restarting server with new configuration..." -ForegroundColor Cyan
            
            # Stop existing server
            try {
                Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
                Write-Host "   Stopped existing server" -ForegroundColor Gray
            } catch {
                # No processes to stop
            }
            
            # Start server with new config
            Start-Sleep -Seconds 2
            Write-Host "   Starting server with Google integration..." -ForegroundColor Gray
            Start-Process -FilePath "node" -ArgumentList "geopolitical-intelligence-server.js" -WindowStyle Hidden
            
            Write-Host ""
            Write-Host "✅ CONFIGURATION COMPLETE!" -ForegroundColor Green
            Write-Host ""
            Write-Host "🧪 Test your integration:" -ForegroundColor Yellow
            Write-Host "   powershell -File test-comprehensive-integration.ps1" -ForegroundColor Gray
            Write-Host ""
            Write-Host "🎯 Your Google Images API is now ACTIVE!" -ForegroundColor Green
            
        } else {
            Write-Host "❌ ERROR: .env file not found" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ ERROR: Invalid CSE ID format" -ForegroundColor Red
        Write-Host "   Expected format: abc123:def456" -ForegroundColor Gray
        Write-Host "   Your input: $cseId" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ ERROR: No CSE ID provided" -ForegroundColor Red
    Write-Host "   Please run this script again after getting your CSE ID" -ForegroundColor Gray
}