#Requires -Version 5.1

<#
.SYNOPSIS
    Setup Windows Task Scheduler for 8 AM Daily Geopolitical Intelligence Automation

.DESCRIPTION
    Creates a scheduled task that runs daily at 8:00 AM to execute the complete
    geopolitical intelligence workflow including MCP server, news collection,
    image scraping, and intelligence analysis.
#>

Write-Host "Setting up 8 AM Daily Automation..." -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

$taskName = "GeopoliticalIntelligence-8AM-Daily"
$scriptPath = "c:\Users\tjd20.LAPTOP-PCMC2SUO\news\Start-8AM-Automation.ps1"
$workingDir = "c:\Users\tjd20.LAPTOP-PCMC2SUO\news"

# Check if script exists
if (!(Test-Path $scriptPath)) {
    Write-Host "ERROR: Automation script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "Script location: $scriptPath" -ForegroundColor Cyan
Write-Host "Working directory: $workingDir" -ForegroundColor Cyan

# Remove existing task if it exists
try {
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing existing task..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Existing task removed" -ForegroundColor Green
    }
} catch {
    # Task doesn't exist, continue
}

try {
    Write-Host "Creating scheduled task components..." -ForegroundColor Yellow
    
    # Create the action (what to run)
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`"" -WorkingDirectory $workingDir
    Write-Host "Action created" -ForegroundColor Green
    
    # Create the trigger (when to run) - daily at 8:00 AM
    $trigger = New-ScheduledTaskTrigger -Daily -At "08:00"
    Write-Host "Trigger created (Daily at 8:00 AM)" -ForegroundColor Green
    
    # Create the principal (run as current user)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    Write-Host "Principal created (User: $env:USERNAME)" -ForegroundColor Green
    
    # Create the settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -MultipleInstances IgnoreNew
    Write-Host "Settings configured" -ForegroundColor Green
    
    # Create comprehensive description
    $description = "Daily 8 AM Geopolitical Intelligence Automation. Comprehensive workflow includes: MCP Geopolitical Intelligence Server (Port 3007), News Collection (fetchAllAfrica.js), Image Scraping (Non-API methods), Intelligence Analysis and Reports, Regional Categorization (African, Caribbean, Afro-Latino), Visual Intelligence Collection, Automated Notifications. Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'). Script: $scriptPath"
    
    # Register the scheduled task
    Write-Host "Registering scheduled task..." -ForegroundColor Yellow
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description $description | Out-Null
    
    Write-Host "Scheduled task created successfully!" -ForegroundColor Green
    
    # Verify the task was created
    $verifyTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($verifyTask) {
        Write-Host "Task verified in Windows Task Scheduler" -ForegroundColor Green
        
        # Get next run time
        $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
        $nextRun = $taskInfo.NextRunTime
        
        Write-Host ""
        Write-Host "Task Summary:" -ForegroundColor Cyan
        Write-Host "   Name: $taskName" -ForegroundColor White
        Write-Host "   Schedule: Daily at 8:00 AM" -ForegroundColor White
        Write-Host "   Next Run: $nextRun" -ForegroundColor White
        Write-Host "   Status: $($verifyTask.State)" -ForegroundColor White
        Write-Host ""
        
        Write-Host "What will run at 8 AM tomorrow:" -ForegroundColor Yellow
        Write-Host "   1. Start MCP Geopolitical Intelligence Server" -ForegroundColor White
        Write-Host "   2. Collect latest news headlines" -ForegroundColor White
        Write-Host "   3. Scrape related images (non-API methods)" -ForegroundColor White
        Write-Host "   4. Generate intelligence analysis" -ForegroundColor White
        Write-Host "   5. Create trending summaries" -ForegroundColor White
        Write-Host "   6. Send completion notifications" -ForegroundColor White
        
        Write-Host ""
        Write-Host "Key Folder Paths:" -ForegroundColor Yellow
        Write-Host "   Main Workspace: c:\Users\tjd20.LAPTOP-PCMC2SUO\news" -ForegroundColor White
        Write-Host "   Images: c:\Users\tjd20.LAPTOP-PCMC2SUO\news\trending-intelligence\images" -ForegroundColor White
        Write-Host "   Logs: c:\Users\tjd20.LAPTOP-PCMC2SUO\news\logs" -ForegroundColor White
        Write-Host "   Scripts: c:\Users\tjd20.LAPTOP-PCMC2SUO\news\*.ps1" -ForegroundColor White
        
        Write-Host ""
        Write-Host "To test the automation now:" -ForegroundColor Cyan
        Write-Host "   Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor White
        
        Write-Host ""
        Write-Host "8 AM AUTOMATION SETUP COMPLETE!" -ForegroundColor Green
        
    } else {
        Write-Host "ERROR: Task verification failed" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "ERROR: Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}