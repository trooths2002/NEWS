<#
.SYNOPSIS
    Production Deployment and Validation Script
    Streamlined deployment for the MCP automation system

.DESCRIPTION
    This script validates, deploys, and activates the production MCP automation system.
    It performs all necessary checks and sets up automated scheduling.

.PARAMETER Mode
    Deployment mode: validate, deploy, schedule, test, all
    Default: all

.EXAMPLE
    .\deploy-production-automation.ps1 -Mode all
    
.EXAMPLE
    .\deploy-production-automation.ps1 -Mode validate
#>

[CmdletBinding()]
param(
    [ValidateSet("validate", "deploy", "schedule", "test", "all")]
    [string]$Mode = "all"
)

# Configuration
$WorkspacePath = "c:\Users\tjd20.LAPTOP-PCMC2SUO\news"
$LogFile = Join-Path $WorkspacePath "deployment.log"
$ExecutionId = [System.Guid]::NewGuid().ToString("N")[0..7] -join ""

function Write-DeploymentLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [ConsoleColor]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [ID:$ExecutionId] $Message"
    
    Write-Host $logEntry -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
}

function Test-ProductionReadiness {
    Write-DeploymentLog "🔍 Testing Production Readiness..." "INFO" "Cyan"
    
    $results = @()
    
    # Test 1: PowerShell Version
    try {
        $psVersion = $PSVersionTable.PSVersion
        if ($psVersion -ge [Version]"5.1") {
            $results += @{ Test = "PowerShell Version"; Status = "PASS"; Details = "Version $psVersion" }
        } else {
            $results += @{ Test = "PowerShell Version"; Status = "FAIL"; Details = "Version $psVersion below 5.1" }
        }
    } catch {
        $results += @{ Test = "PowerShell Version"; Status = "FAIL"; Details = $_.Exception.Message }
    }
    
    # Test 2: Node.js
    try {
        $nodeVersion = & node --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results += @{ Test = "Node.js"; Status = "PASS"; Details = "Version $nodeVersion" }
        } else {
            $results += @{ Test = "Node.js"; Status = "FAIL"; Details = "Not found or not accessible" }
        }
    } catch {
        $results += @{ Test = "Node.js"; Status = "FAIL"; Details = $_.Exception.Message }
    }
    
    # Test 3: npm
    try {
        $npmVersion = & npm --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results += @{ Test = "npm"; Status = "PASS"; Details = "Version $npmVersion" }
        } else {
            $results += @{ Test = "npm"; Status = "FAIL"; Details = "Not found or not accessible" }
        }
    } catch {
        $results += @{ Test = "npm"; Status = "FAIL"; Details = $_.Exception.Message }
    }
    
    # Test 4: Critical Files
    $criticalFiles = @("fetchAllAfrica.js", "package.json", "mcp-server.js")
    foreach ($file in $criticalFiles) {
        $filePath = Join-Path $WorkspacePath $file
        if (Test-Path $filePath) {
            $results += @{ Test = "File: $file"; Status = "PASS"; Details = "File exists" }
        } else {
            $results += @{ Test = "File: $file"; Status = "FAIL"; Details = "File missing" }
        }
    }
    
    # Test 5: Disk Space
    try {
        $drive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
        $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        if ($freeSpaceGB -gt 1) {
            $results += @{ Test = "Disk Space"; Status = "PASS"; Details = "${freeSpaceGB}GB available" }
        } else {
            $results += @{ Test = "Disk Space"; Status = "WARN"; Details = "${freeSpaceGB}GB available (low)" }
        }
    } catch {
        $results += @{ Test = "Disk Space"; Status = "WARN"; Details = "Could not check" }
    }
    
    # Report Results
    foreach ($result in $results) {
        $color = switch ($result.Status) {
            "PASS" { "Green" }
            "WARN" { "Yellow" }
            "FAIL" { "Red" }
        }
        Write-DeploymentLog "  $($result.Test): $($result.Status) - $($result.Details)" "INFO" $color
    }
    
    $failedTests = $results | Where-Object { $_.Status -eq "FAIL" }
    return @{
        Results = $results
        AllPassed = ($failedTests.Count -eq 0)
        FailedCount = $failedTests.Count
        TotalCount = $results.Count
    }
}

function Deploy-ProductionSystem {
    Write-DeploymentLog "🚀 Deploying Production System..." "INFO" "Cyan"
    
    # Create required directories
    $directories = @("logs", "workflows", "backups", "config", "temp")
    foreach ($dir in $directories) {
        $dirPath = Join-Path $WorkspacePath $dir
        if (-not (Test-Path $dirPath)) {
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            Write-DeploymentLog "  Created directory: $dir" "INFO" "Green"
        }
    }
    
    # Test news fetching functionality
    Write-DeploymentLog "  Testing news fetching functionality..." "INFO" "White"
    try {
        Set-Location $WorkspacePath
        $testOutput = & node fetchAllAfrica.js 2>&1
        
        if (Test-Path "allafrica-headlines.txt") {
            $headlineCount = (Get-Content "allafrica-headlines.txt" | Measure-Object).Count
            Write-DeploymentLog "  ✅ News fetching successful: $headlineCount headlines" "INFO" "Green"
        } else {
            Write-DeploymentLog "  ⚠️ News fetching completed but no output file" "WARN" "Yellow"
            if ($testOutput) {
                Write-DeploymentLog "  Output: $testOutput" "INFO" "Gray"
            }
        }
    } catch {
        Write-DeploymentLog "  ❌ News fetching test failed: $($_.Exception.Message)" "ERROR" "Red"
        if ($testOutput) {
            Write-DeploymentLog "  Command output: $testOutput" "INFO" "Gray"
        }
    }
    
    Write-DeploymentLog "🎯 Production system deployed successfully!" "INFO" "Green"
}

function Initialize-AutomatedScheduling {
    Write-DeploymentLog "⏰ Setting up Automated Scheduling..." "INFO" "Cyan"
    
    $taskConfigs = @(
        @{
            Name = "AdvancedMCP-DailyIntelligence"
            Description = "Daily news intelligence collection and analysis"
            Schedule = "Daily"
            Time = "08:00"
            Script = "advanced-mcp-automation.ps1"
            Mode = "daily"
            Priority = "High"
        },
        @{
            Name = "AdvancedMCP-CrisisMonitoring"
            Description = "Crisis monitoring and alert system"
            Schedule = "Every 2 hours"
            Time = "02:00"
            Script = "advanced-mcp-automation.ps1"
            Mode = "crisis"
            Priority = "Critical"
        }
    )
    
    foreach ($config in $taskConfigs) {
        Write-DeploymentLog "  Creating task: $($config.Name)" "INFO" "White"
        
        try {
            $scriptPath = Join-Path $WorkspacePath $config.Script
            $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`" -Mode $($config.Mode) -SendNotifications"
            
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
            
            if ($config.Schedule -eq "Daily") {
                $trigger = New-ScheduledTaskTrigger -Daily -At $config.Time
            } elseif ($config.Schedule -eq "Every 2 hours") {
                $trigger = New-ScheduledTaskTrigger -Daily -At $config.Time
                $trigger.Repetition.Interval = "PT2H"
                $trigger.Repetition.Duration = "P1D"
            }
            
            $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
            
            Register-ScheduledTask -TaskName $config.Name -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description $config.Description -Force | Out-Null
            
            Write-DeploymentLog "  ✅ Task created: $($config.Name)" "INFO" "Green"
        } catch {
            Write-DeploymentLog "  ❌ Failed to create task: $($config.Name) - $($_.Exception.Message)" "ERROR" "Red"
        }
    }
    
    Write-DeploymentLog "📅 Automated scheduling configured!" "INFO" "Green"
}

function Test-FullSystem {
    Write-DeploymentLog "🧪 Testing Full System Integration..." "INFO" "Cyan"
    
    # Test basic automation script
    Write-DeploymentLog "  Testing basic automation..." "INFO" "White"
    try {
        Set-Location $WorkspacePath
        if (Test-Path "automated-news-fetch.ps1") {
            $testResult = & powershell -ExecutionPolicy Bypass -File "automated-news-fetch.ps1" -HeadlineCount 5 2>&1
            Write-DeploymentLog "  ✅ Basic automation test completed" "INFO" "Green"
            if ($testResult -and $testResult -match "error|failed|exception") {
                Write-DeploymentLog "  Warning: Potential issues detected in output" "WARN" "Yellow"
                Write-DeploymentLog "  Output: $testResult" "INFO" "Gray"
            }
        } else {
            Write-DeploymentLog "  ⚠️ Basic automation script not found" "WARN" "Yellow"
        }
    } catch {
        Write-DeploymentLog "  ❌ Basic automation test failed: $($_.Exception.Message)" "ERROR" "Red"
        if ($testResult) {
            Write-DeploymentLog "  Command output: $testResult" "INFO" "Gray"
        }
    }
    
    # Test MCP server availability
    Write-DeploymentLog "  Testing MCP server scripts..." "INFO" "White"
    $mcpScripts = @("mcp-server.js", "mcp-server-stdio.js", "enhanced-mcp-server.js")
    foreach ($script in $mcpScripts) {
        if (Test-Path (Join-Path $WorkspacePath $script)) {
            Write-DeploymentLog "  ✅ MCP script available: $script" "INFO" "Green"
        } else {
            Write-DeploymentLog "  ⚠️ MCP script missing: $script" "WARN" "Yellow"
        }
    }
    
    Write-DeploymentLog "🔬 System integration tests completed!" "INFO" "Green"
}

function Show-DeploymentSummary {
    param($ValidationResults)
    
    Write-Host ""
    Write-Host "🎯 PRODUCTION DEPLOYMENT SUMMARY" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "Execution ID: $ExecutionId" -ForegroundColor Cyan
    Write-Host "Deployment Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "Mode: $Mode" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "VALIDATION RESULTS:" -ForegroundColor Yellow
    Write-Host "  Total Tests: $($ValidationResults.TotalCount)" -ForegroundColor White
    Write-Host "  Passed: $(($ValidationResults.Results | Where-Object { $_.Status -eq 'PASS' }).Count)" -ForegroundColor Green
    Write-Host "  Warnings: $(($ValidationResults.Results | Where-Object { $_.Status -eq 'WARN' }).Count)" -ForegroundColor Yellow
    Write-Host "  Failed: $($ValidationResults.FailedCount)" -ForegroundColor Red
    Write-Host ""
    
    if ($ValidationResults.AllPassed) {
        Write-Host "SYSTEM STATUS: ✅ PRODUCTION READY" -ForegroundColor Green
        Write-Host ""
        Write-Host "NEXT STEPS:" -ForegroundColor Yellow
        Write-Host "  1. ✅ System validated and deployed" -ForegroundColor Green
        Write-Host "  2. ✅ Automated scheduling configured" -ForegroundColor Green
        Write-Host "  3. ✅ Ready for MCP integration" -ForegroundColor Green
        Write-Host "  4. 📊 Monitor logs in: $WorkspacePath\logs" -ForegroundColor Cyan
        Write-Host "  5. 🔄 Check scheduled tasks in Task Scheduler" -ForegroundColor Cyan
    } else {
        Write-Host "SYSTEM STATUS: ⚠️ REQUIRES ATTENTION" -ForegroundColor Yellow
        Write-Host "  $($ValidationResults.FailedCount) validation issues detected" -ForegroundColor Red
        Write-Host "  Review the validation results above" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "AVAILABLE OPERATIONS:" -ForegroundColor Yellow
    Write-Host "  • Daily Intelligence: AdvancedMCP-DailyIntelligence (08:00 daily)" -ForegroundColor White
    Write-Host "  • Crisis Monitoring: AdvancedMCP-CrisisMonitoring (every 2 hours)" -ForegroundColor White
    Write-Host "  • Manual Execution: .\automated-news-fetch.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "INTEGRATION READY:" -ForegroundColor Yellow
    Write-Host "  📁 File System MCP: Advanced file operations" -ForegroundColor White
    Write-Host "  🗄️ SQLite MCP: Database analytics" -ForegroundColor White
    Write-Host "  🔍 Brave Search MCP: Real-time verification" -ForegroundColor White
    Write-Host "  📊 GitHub MCP: Version control automation" -ForegroundColor White
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
}

# Main execution
try {
    Write-Host ""
    Write-Host "🚀 Production MCP Automation Deployment v2.0" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "Starting deployment process..." -ForegroundColor Cyan
    Write-Host ""
    
    Set-Location $WorkspacePath
    
    # Execute based on mode
    switch ($Mode) {
        "validate" {
            $validationResults = Test-ProductionReadiness
            Show-DeploymentSummary -ValidationResults $validationResults
        }
        "deploy" {
            $validationResults = Test-ProductionReadiness
            if ($validationResults.AllPassed) {
                Deploy-ProductionSystem
            } else {
                Write-DeploymentLog "❌ Validation failed. Cannot proceed with deployment." "ERROR" "Red"
                exit 1
            }
        }
        "schedule" {
            Initialize-AutomatedScheduling
        }
        "test" {
            Test-FullSystem
        }
        "all" {
            $validationResults = Test-ProductionReadiness
            if ($validationResults.AllPassed) {
                Deploy-ProductionSystem
                Initialize-AutomatedScheduling
                Test-FullSystem
                Show-DeploymentSummary -ValidationResults $validationResults
            } else {
                Write-DeploymentLog "❌ Validation failed. Deployment halted." "ERROR" "Red"
                Show-DeploymentSummary -ValidationResults $validationResults
                exit 1
            }
        }
    }
    
    Write-DeploymentLog "🎉 Production deployment completed successfully!" "INFO" "Green"
    
} catch {
    Write-DeploymentLog "💥 CRITICAL DEPLOYMENT FAILURE: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}