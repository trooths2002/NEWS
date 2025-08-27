# Setup Automation for MCP News Workflow
# This script creates Windows Task Scheduler entries for automated news fetching

Write-Host "🔧 MCP News Workflow Automation Setup" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$currentPath = Get-Location
$scriptPath = Join-Path $currentPath "automated-news-fetch.ps1"

# Check if automated script exists
if (!(Test-Path $scriptPath)) {
    Write-Host "❌ automated-news-fetch.ps1 not found in current directory" -ForegroundColor Red
    Write-Host "Please ensure you're running this from the correct directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "📍 Working directory: $currentPath" -ForegroundColor Cyan
Write-Host "📄 Script to schedule: $scriptPath" -ForegroundColor Cyan
Write-Host ""

# Menu for automation options
Write-Host "Select automation schedule:" -ForegroundColor Yellow
Write-Host "1. Daily at 8:00 AM"
Write-Host "2. Daily at 12:00 PM (Noon)"
Write-Host "3. Daily at 6:00 PM"
Write-Host "4. Every 6 hours"
Write-Host "5. Every 12 hours"
Write-Host "6. Custom schedule"
Write-Host "7. Remove existing automation"
Write-Host "0. Exit"
Write-Host ""

$choice = Read-Host "Enter your choice (0-7)"

switch ($choice) {
    "1" {
        $schedule = "DAILY"
        $time = "08:00"
        $taskName = "MCP-DailyNews-Morning"
        $description = "Daily news fetch at 8:00 AM using MCP SuperAssistant"
    }
    "2" {
        $schedule = "DAILY"
        $time = "12:00"
        $taskName = "MCP-DailyNews-Noon"
        $description = "Daily news fetch at 12:00 PM using MCP SuperAssistant"
    }
    "3" {
        $schedule = "DAILY"
        $time = "18:00"
        $taskName = "MCP-DailyNews-Evening"
        $description = "Daily news fetch at 6:00 PM using MCP SuperAssistant"
    }
    "4" {
        $schedule = "HOURLY"
        $time = "6"
        $taskName = "MCP-NewsMonitoring-6Hour"
        $description = "News fetch every 6 hours using MCP SuperAssistant"
    }
    "5" {
        $schedule = "HOURLY"
        $time = "12"
        $taskName = "MCP-NewsMonitoring-12Hour"
        $description = "News fetch every 12 hours using MCP SuperAssistant"
    }
    "6" {
        Write-Host "Custom schedule setup:" -ForegroundColor Yellow
        $customTime = Read-Host "Enter time (HH:MM format, e.g., 14:30)"
        $customDays = Read-Host "Enter days (DAILY, WEEKLY, or specific days like MON,WED,FRI)"
        
        $schedule = if ($customDays -eq "DAILY") { "DAILY" } else { "WEEKLY" }
        $time = $customTime
        $taskName = "MCP-NewsCustom-$(Get-Date -Format 'HHmm')"
        $description = "Custom news fetch schedule using MCP SuperAssistant"
    }
    "7" {
        Write-Host "Removing existing MCP automation tasks..." -ForegroundColor Yellow
        
        $existingTasks = schtasks /query /fo csv | ConvertFrom-Csv | Where-Object { $_."TaskName" -like "*MCP*News*" }
        
        if ($existingTasks) {
            foreach ($task in $existingTasks) {
                try {
                    schtasks /delete /tn $task.TaskName /f
                    Write-Host "✅ Removed task: $($task.TaskName)" -ForegroundColor Green
                } catch {
                    Write-Host "❌ Failed to remove: $($task.TaskName)" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "ℹ️  No MCP automation tasks found" -ForegroundColor Cyan
        }
        
        Write-Host "🗑️  Cleanup completed" -ForegroundColor Green
        exit 0
    }
    "0" {
        Write-Host "👋 Exiting setup" -ForegroundColor Gray
        exit 0
    }
    default {
        Write-Host "❌ Invalid choice. Exiting." -ForegroundColor Red
        exit 1
    }
}

# Create the scheduled task
Write-Host ""
Write-Host "Creating scheduled task..." -ForegroundColor Yellow
Write-Host "Task Name: $taskName" -ForegroundColor Cyan
Write-Host "Description: $description" -ForegroundColor Cyan
Write-Host "Schedule: $schedule at $time" -ForegroundColor Cyan

try {
    # Build the command
    $action = "powershell.exe"
    $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`" -HeadlineCount 15 -SendNotification"
    
    if ($schedule -eq "DAILY") {
        $scheduleCmd = "/sc DAILY /st $time"
    } elseif ($schedule -eq "HOURLY" -and $time -eq "6") {
        $scheduleCmd = "/sc HOURLY /mo 6"
    } elseif ($schedule -eq "HOURLY" -and $time -eq "12") {
        $scheduleCmd = "/sc HOURLY /mo 12"
    } else {
        $scheduleCmd = "/sc DAILY /st $time"
    }
    
    # Create the task
    $createCmd = "schtasks /create /tn `"$taskName`" /tr `"$action $arguments`" $scheduleCmd /ru SYSTEM /f"
    
    Invoke-Expression $createCmd
    
    Write-Host "✅ Scheduled task created successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Verify the task was created
    schtasks /query /tn $taskName 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Task verified in Task Scheduler" -ForegroundColor Green
        
        # Show task details
        Write-Host ""
        Write-Host "📋 Task Details:" -ForegroundColor Yellow
        Write-Host "Name: $taskName"
        Write-Host "Script: $scriptPath"
        Write-Host "Schedule: $schedule at $time"
        Write-Host "Arguments: Headlines=15, Notifications=Enabled"
        Write-Host ""
        
        # Test option
        $testRun = Read-Host "Would you like to test run the task now? (y/n)"
        if ($testRun -eq "y" -or $testRun -eq "Y") {
            Write-Host "🧪 Running test..." -ForegroundColor Yellow
            schtasks /run /tn $taskName
            Write-Host "✅ Test initiated. Check output in news-archive folder." -ForegroundColor Green
        }
        
    } else {
        Write-Host "⚠️  Task created but verification failed" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error creating scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Automation setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 News files will be saved to: .\news-archive\" -ForegroundColor Cyan
Write-Host "🔔 Notifications will be shown when fetch completes" -ForegroundColor Cyan
Write-Host "⚙️  To modify/remove: Run this script again and choose option 7" -ForegroundColor Cyan
Write-Host ""
Write-Host "To manually run the news fetch:" -ForegroundColor Yellow
Write-Host "  powershell -File `"$scriptPath`"" -ForegroundColor Gray