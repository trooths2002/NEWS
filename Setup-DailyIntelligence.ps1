#Requires -Version 5.1

<#
.SYNOPSIS
    Set up daily geopolitical intelligence collection at 8:00 AM

.DESCRIPTION
    Creates Windows Task Scheduler entry for comprehensive geopolitical intelligence
    covering African, Caribbean, and Afro-Latino geopolitics with all core disciplines
#>

function Write-Message {
    param([string]$Message, [string]$Type = "INFO")
    
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        default   { "Cyan" }
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
}

# Remove existing task if it exists
$taskName = "GeopoliticalIntelligence-Daily"
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Message "Removed existing scheduled task: $taskName" "WARNING"
}

# Create new scheduled task for daily 8 AM execution
$scriptPath = Join-Path $PWD.Path "Start-GeopoliticalIntelligence.ps1"
$workingDirectory = $PWD.Path

$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -RunOnce" -WorkingDirectory $workingDirectory

$trigger = New-ScheduledTaskTrigger -Daily -At "08:00"

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

$description = @"
Comprehensive Geopolitical Intelligence Collection System

Daily automated execution covering:
- Core Disciplines: Political Science, Geography, History, Economics, Strategic Studies, Cultural/Social, Energy/Resources
- Regional Focus: African, Caribbean, Afro-Latino, Middle East, East Asia, Europe
- Analytical Methods: Risk Assessment, Strategic Foresight, OSINT Analysis, Scenario Planning

Generates:
- Executive intelligence briefings
- 130-character trending summaries
- Copyable content in .txt, .csv, and template formats
- Regional coverage verification

RSS Sources include Caribbean and Afro-Latino geopolitical feeds
"@

$task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $description

Register-ScheduledTask -TaskName $taskName -InputObject $task | Out-Null

Write-Message "Created daily scheduled task: $taskName" "SUCCESS"
Write-Message "Daily execution time: 8:00 AM" "INFO"
Write-Message "Comprehensive geopolitical intelligence coverage active" "SUCCESS"

# Test the task
$scheduledTask = Get-ScheduledTask -TaskName $taskName
if ($scheduledTask.State -eq "Ready") {
    Write-Message "Scheduled task verified and ready" "SUCCESS"
    
    # Show next run time
    $nextRun = (Get-ScheduledTask -TaskName $taskName | Get-ScheduledTaskInfo).NextRunTime
    Write-Message "Next automated run: $nextRun" "INFO"
    
    # Show task details
    Write-Message "Task will execute: $scriptPath" "INFO"
    Write-Message "Working directory: $workingDirectory" "INFO"
} else {
    Write-Message "Warning: Scheduled task may not be properly configured" "WARNING"
}

Write-Message "Daily automation setup complete!" "SUCCESS"
Write-Message "The system will now automatically collect comprehensive geopolitical intelligence daily at 8:00 AM" "SUCCESS"