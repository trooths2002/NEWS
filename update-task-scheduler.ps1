# Update Windows Task Scheduler for Enhanced MCP Workflow
# This replaces your existing daily task with the enhanced version

Write-Host "🔧 Updating Windows Task Scheduler for Enhanced MCP Workflow" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green

$currentPath = Get-Location
$enhancedScript = Join-Path $currentPath "enhanced-daily-workflow.ps1"
$oldTaskName = "DailyAllAfricaHeadlines"
$newTaskName = "EnhancedMCPNewsWorkflow"

# Check if enhanced script exists
if (!(Test-Path $enhancedScript)) {
    Write-Host "❌ enhanced-daily-workflow.ps1 not found" -ForegroundColor Red
    exit 1
}

Write-Host "📍 Working directory: $currentPath" -ForegroundColor Cyan
Write-Host "📄 Enhanced script: $enhancedScript" -ForegroundColor Cyan

# Check for existing tasks
$oldTask = Get-ScheduledTask -TaskName $oldTaskName -ErrorAction SilentlyContinue
$newTask = Get-ScheduledTask -TaskName $newTaskName -ErrorAction SilentlyContinue

if ($oldTask) {
    Write-Host "🗑️  Found existing task: $oldTaskName" -ForegroundColor Yellow
    $removeOld = Read-Host "Remove old task and create enhanced version? (y/n)"
    if ($removeOld -eq "y" -or $removeOld -eq "Y") {
        Unregister-ScheduledTask -TaskName $oldTaskName -Confirm:$false
        Write-Host "✅ Removed old task: $oldTaskName" -ForegroundColor Green
    }
}

if ($newTask) {
    Write-Host "⚠️  Enhanced task already exists: $newTaskName" -ForegroundColor Yellow
    $recreate = Read-Host "Recreate enhanced task with latest settings? (y/n)"
    if ($recreate -eq "y" -or $recreate -eq "Y") {
        Unregister-ScheduledTask -TaskName $newTaskName -Confirm:$false
        Write-Host "✅ Removed existing enhanced task" -ForegroundColor Green
    } else {
        Write-Host "👋 Keeping existing task. Exiting." -ForegroundColor Gray
        exit 0
    }
}

# Get schedule preferences
Write-Host ""
Write-Host "📅 Schedule Options:" -ForegroundColor Yellow
Write-Host "1. Daily at 8:00 AM (recommended)"
Write-Host "2. Daily at 12:00 PM (noon)"
Write-Host "3. Daily at 6:00 PM"
Write-Host "4. Custom time"

$scheduleChoice = Read-Host "Choose schedule (1-4)"

switch ($scheduleChoice) {
    "1" { $scheduleTime = "08:00" }
    "2" { $scheduleTime = "12:00" }
    "3" { $scheduleTime = "18:00" }
    "4" { 
        $scheduleTime = Read-Host "Enter time (HH:MM format, e.g., 14:30)"
        if ($scheduleTime -notmatch '^\d{2}:\d{2}$') {
            Write-Host "❌ Invalid time format. Using 08:00" -ForegroundColor Red
            $scheduleTime = "08:00"
        }
    }
    default { 
        Write-Host "Invalid choice. Using 08:00 AM" -ForegroundColor Yellow
        $scheduleTime = "08:00"
    }
}

Write-Host ""
Write-Host "Creating enhanced scheduled task..." -ForegroundColor Yellow
Write-Host "Task Name: $newTaskName" -ForegroundColor Cyan
Write-Host "Schedule: Daily at $scheduleTime" -ForegroundColor Cyan
Write-Host "Script: $enhancedScript" -ForegroundColor Cyan

try {
    # Create the action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$enhancedScript`" -SendNotification"
    
    # Create the trigger (daily at specified time)
    $trigger = New-ScheduledTaskTrigger -Daily -At $scheduleTime
    
    # Create the principal (run as current user)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    
    # Create the settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
    
    # Enhanced task description
    $description = @"
Enhanced MCP News Intelligence Workflow
- Runs comprehensive news collection (fetchAllAfrica.js)
- Downloads article images locally
- Performs real-time MCP analysis
- Generates intelligence reports
- Integrates with MCP SuperAssistant for AI analysis
Created: $(Get-Date)
"@
    
    # Register the scheduled task
    Register-ScheduledTask -TaskName $newTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description $description
    
    Write-Host "✅ Enhanced scheduled task created successfully!" -ForegroundColor Green
    
    # Verify the task
    $verifyTask = Get-ScheduledTask -TaskName $newTaskName -ErrorAction SilentlyContinue
    if ($verifyTask) {
        Write-Host "✅ Task verified in Windows Task Scheduler" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "📋 Task Summary:" -ForegroundColor Yellow
        Write-Host "  Name: $newTaskName"
        Write-Host "  Schedule: Daily at $scheduleTime"
        Write-Host "  Action: Enhanced workflow (collection + MCP analysis)"
        Write-Host "  Features:"
        Write-Host "    • Comprehensive news collection with images"
        Write-Host "    • Real-time MCP analysis integration"
        Write-Host "    • Intelligence report generation"
        Write-Host "    • Desktop notifications"
        Write-Host "    • Automated MCP server management"
        
        Write-Host ""
        Write-Host "📁 Output Locations:" -ForegroundColor Yellow
        Write-Host "  • Headlines: allafrica-headlines.txt"
        Write-Host "  • Images: .\images\"
        Write-Host "  • Intelligence: .\intelligence-reports\"
        Write-Host "  • MCP Data: .\news-archive\"
        Write-Host "  • Logs: enhanced-workflow.log"
        
        # Offer to test run
        Write-Host ""
        $testRun = Read-Host "Test run the enhanced workflow now? (y/n)"
        if ($testRun -eq "y" -or $testRun -eq "Y") {
            Write-Host "🧪 Running test..." -ForegroundColor Yellow
            Write-Host "⏳ This will take a few minutes (collecting news + downloading images + MCP analysis)..." -ForegroundColor Cyan
            
            try {
                Start-ScheduledTask -TaskName $newTaskName
                Write-Host "✅ Test initiated! Check these locations for output:" -ForegroundColor Green
                Write-Host "  • Intelligence report: .\intelligence-reports\"
                Write-Host "  • Downloaded images: .\images\"
                Write-Host "  • Workflow log: enhanced-workflow.log"
                Write-Host ""
                Write-Host "💡 Pro Tip: While it runs, connect your MCP SuperAssistant browser extension to:" -ForegroundColor Cyan
                Write-Host "     http://localhost:3006/sse" -ForegroundColor Gray
            } catch {
                Write-Host "❌ Failed to start test: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
    } else {
        Write-Host "⚠️  Task created but verification failed" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error creating scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Enhanced MCP workflow automation is ready!" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 What happens daily at $scheduleTime" ":" -ForegroundColor Cyan
Write-Host "  1. Comprehensive news collection (your original fetchAllAfrica.js)"
Write-Host "  2. Image downloads to local storage"
Write-Host "  3. MCP server verification/startup"
Write-Host "  4. Real-time headline analysis via MCP"
Write-Host "  5. Intelligence report generation"
Write-Host "  6. Desktop notification with summary"
Write-Host ""
Write-Host "🔗 MCP SuperAssistant Integration:" -ForegroundColor Cyan
Write-Host "  • Connect browser extension to: http://localhost:3006/sse"
Write-Host "  • Use intelligence reports for AI-powered analysis"
Write-Host "  • Leverage both automated data + real-time MCP tools"
Write-Host ""
Write-Host "📊 To monitor: Check enhanced-workflow.log for daily execution details" -ForegroundColor Yellow