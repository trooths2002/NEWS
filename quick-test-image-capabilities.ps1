$healthResponse = Invoke-RestMethod -Uri "http://localhost:3007/health" -TimeoutSec 10

Write-Host "=== Server Status ===" -ForegroundColor Green
Write-Host "Status: $($healthResponse.status)" -ForegroundColor Cyan
Write-Host "Version: $($healthResponse.version)" -ForegroundColor Cyan
Write-Host "Capabilities: $($healthResponse.capabilities -join ', ')" -ForegroundColor Cyan

if ($healthResponse.capabilities -contains 'image_scraping') {
    Write-Host ""
    Write-Host "✅ IMAGE SCRAPING CAPABILITY DETECTED!" -ForegroundColor Green
    Write-Host "✅ Visual intelligence features available" -ForegroundColor Green
    Write-Host ""
    Write-Host "🖼️ Image scraping workflow is now active and ready!" -ForegroundColor Magenta
} else {
    Write-Host ""
    Write-Host "❌ Image scraping capability missing" -ForegroundColor Red
}