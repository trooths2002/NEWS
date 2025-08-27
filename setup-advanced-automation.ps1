# Setup Advanced Multi-MCP Server Automation in Windows Task Scheduler
# Creates multiple scheduled tasks for comprehensive news intelligence automation

Write-Host "🚀 Advanced Multi-MCP Server Automation Setup" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

$currentPath = Get-Location
$advancedScript = Join-Path $currentPath "advanced-mcp-automation.ps1"

# Check if advanced script exists
if (!(Test-Path $advancedScript)) {
    Write-Host "❌ advanced-mcp-automation.ps1 not found" -ForegroundColor Red
    Write-Host "Please ensure you're in the correct directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "📍 Working directory: $currentPath" -ForegroundColor Cyan
Write-Host "📄 Advanced script: $advancedScript" -ForegroundColor Cyan

# Define automation tasks
$automationTasks = @(
    @{
        Name = "AdvancedMCP-DailyIntelligence"
        Description = "Daily news intelligence with multi-MCP server processing"
        Mode = "daily"
        Schedule = "Daily"
        Time = "08:00"
        Priority = "High"
    },
    @{
        Name = "AdvancedMCP-CrisisMonitoring" 
        Description = "Crisis monitoring with real-time alerts"
        Mode = "crisis"
        Schedule = "Every 2 hours"
        Time = "02:00"
        Priority = "Critical"
    },
    @{
        Name = "AdvancedMCP-WeeklyReport"
        Description = "Comprehensive weekly intelligence analysis"
        Mode = "weekly"  
        Schedule = "Weekly"
        Time = "18:00"
        Priority = "Medium"
    }
)

Write-Host ""
Write-Host "📅 Available Automation Tasks:" -ForegroundColor Yellow
for ($i = 0; $i -lt $automationTasks.Count; $i++) {
    $task = $automationTasks[$i]
    Write-Host "  $($i + 1). $($task.Name)"
    Write-Host "     Description: $($task.Description)"
    Write-Host "     Schedule: $($task.Schedule) at $($task.Time)"
    Write-Host "     Priority: $($task.Priority)"
    Write-Host ""
}

Write-Host "Setup Options:" -ForegroundColor Yellow
Write-Host "1. Setup Daily Intelligence (Recommended)"
Write-Host "2. Setup Crisis Monitoring"  
Write-Host "3. Setup Weekly Reports"
Write-Host "4. Setup All Tasks"
Write-Host "5. Remove Existing Tasks"
Write-Host "0. Exit"

$choice = Read-Host "Choose option (0-5)"

function Remove-ExistingTasks {
    Write-Host "🗑️ Removing existing advanced MCP tasks..." -ForegroundColor Yellow
    
    $existingTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*AdvancedMCP*" }
    
    if ($existingTasks) {
        foreach ($task in $existingTasks) {
            try {
                Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
                Write-Host "✅ Removed: $($task.TaskName)" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to remove: $($task.TaskName)" -ForegroundColor Red
            }
        }
        Write-Host "🧹 Cleanup completed" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ No existing advanced MCP tasks found" -ForegroundColor Cyan
    }
}

function New-AutomationTask {
    param($TaskConfig)
    
    Write-Host "Creating task: $($TaskConfig.Name)..." -ForegroundColor Yellow
    
    try {
        # Build arguments
        $arguments = "-ExecutionPolicy Bypass -File `"$advancedScript`" -Mode $($TaskConfig.Mode) -SendNotifications"
        
        # Create action
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
        
        # Create trigger based on schedule type
        switch ($TaskConfig.Schedule) {
            "Daily" {
                $trigger = New-ScheduledTaskTrigger -Daily -At $TaskConfig.Time
            }
            "Weekly" {
                $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At $TaskConfig.Time
            }
            "Every 2 hours" {
                # Create a single trigger that repeats every 2 hours
                $trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
                $trigger.Repetition.Interval = "PT2H"  # Repeat every 2 hours
                $trigger.Repetition.Duration = "P1D"   # For 1 day duration
            }
        }
        
        # Create principal
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
        
        # Create settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
        
        # Enhanced description
        $description = @"
$($TaskConfig.Description)

Advanced Multi-MCP Server Automation:
- Mode: $($TaskConfig.Mode)
- Schedule: $($TaskConfig.Schedule) at $($TaskConfig.Time)
- Priority: $($TaskConfig.Priority)
- Script: $advancedScript

Features:
- File System MCP integration
- SQLite database analytics
- GitHub backup automation
- Brave Search verification
- Crisis monitoring and alerts
- Professional intelligence reports

Created: $(Get-Date)
"@
        
        # Register the task
        Register-ScheduledTask -TaskName $TaskConfig.Name -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description $description | Out-Null
        
        Write-Host "✅ Created: $($TaskConfig.Name)" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "❌ Failed to create $($TaskConfig.Name): $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Process user choice
switch ($choice) {
    "1" {
        Remove-ExistingTasks
        $success = New-AutomationTask $automationTasks[0]
        if ($success) {
            Write-Host "📅 Daily Intelligence automation setup complete!" -ForegroundColor Green
        }
    }
    "2" {
        Remove-ExistingTasks
        $success = New-AutomationTask $automationTasks[1]
        if ($success) {
            Write-Host "🚨 Crisis Monitoring automation setup complete!" -ForegroundColor Green
        }
    }
    "3" {
        Remove-ExistingTasks  
        $success = New-AutomationTask $automationTasks[2]
        if ($success) {
            Write-Host "📊 Weekly Reports automation setup complete!" -ForegroundColor Green
        }
    }
    "4" {
        Remove-ExistingTasks
        Write-Host "🔄 Setting up all automation tasks..." -ForegroundColor Cyan
        
        $successCount = 0
        foreach ($task in $automationTasks) {
            if (New-AutomationTask $task) {
                $successCount++
            }
        }
        
        Write-Host "✅ Setup complete: $successCount/$($automationTasks.Count) tasks created" -ForegroundColor Green
    }
    "5" {
        Remove-ExistingTasks
        Write-Host "👋 Cleanup completed. Exiting." -ForegroundColor Gray
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

# Show setup summary
Write-Host ""
Write-Host "📋 Advanced Automation Setup Summary" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# List created tasks
$createdTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*AdvancedMCP*" }

if ($createdTasks) {
    Write-Host ""
    Write-Host "📅 Active Automation Tasks:" -ForegroundColor Yellow
    foreach ($task in $createdTasks) {
        $nextRun = (Get-ScheduledTaskInfo -TaskName $task.TaskName).NextRunTime
        Write-Host "  ✅ $($task.TaskName)" -ForegroundColor Green
        Write-Host "     Next Run: $nextRun" -ForegroundColor Cyan
        Write-Host "     State: $($task.State)" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "🛠️ Required Setup for Full Functionality:" -ForegroundColor Yellow
    Write-Host "  1. Install additional MCP servers:"
    Write-Host "     npm install @modelcontextprotocol/server-filesystem"
    Write-Host "     npm install @modelcontextprotocol/server-sqlite"
    Write-Host "     npm install @modelcontextprotocol/server-github"
    Write-Host "     npm install @modelcontextprotocol/server-brave-search"
    
    Write-Host ""
    Write-Host "  2. Configure MCP SuperAssistant with enhanced-config.json"
    Write-Host "  3. Set up API keys for GitHub and Brave Search servers"
    Write-Host "  4. Initialize SQLite database with setup-database.sql"
    
    Write-Host ""
    Write-Host "📊 What Your Automation Will Do:" -ForegroundColor Cyan
    Write-Host "  • Daily: Complete news intelligence with multi-server processing"
    Write-Host "  • Crisis: Real-time monitoring with severity alerts"  
    Write-Host "  • Weekly: Comprehensive analysis and reporting"
    Write-Host "  • Database: Structured analytics and trend tracking"
    Write-Host "  • Files: Automated organization and archival"
    Write-Host "  • Backup: Version control with GitHub integration"
    
    Write-Host ""
    Write-Host "📁 Workflow Files Created:" -ForegroundColor Cyan
    Write-Host "  • .\workflows\daily-file-processing.txt"
    Write-Host "  • .\workflows\daily-database-analytics.txt"  
    Write-Host "  • .\workflows\crisis-monitoring.txt"
    Write-Host "  • .\workflows\weekly-intelligence.txt"
    Write-Host "  • .\workflows\test-integration.txt"
    
    Write-Host ""
    $testRun = Read-Host "Test run the daily intelligence automation now? (y/n)"
    if ($testRun -eq "y" -or $testRun -eq "Y") {
        Write-Host "🧪 Starting test run..." -ForegroundColor Yellow
        Write-Host "⏳ This will run the advanced automation script..." -ForegroundColor Cyan
        
        try {
            Start-ScheduledTask -TaskName "AdvancedMCP-DailyIntelligence"
            Write-Host "✅ Test initiated! Check these locations:" -ForegroundColor Green
            Write-Host "  • Logs: multi-mcp-workflow.log"
            Write-Host "  • Workflows: .\workflows\"
            Write-Host "  • Database: news-database.db (if SQLite configured)"
            Write-Host "  • Summary: multi-mcp-summary-[DATE].txt"
        } catch {
            Write-Host "❌ Failed to start test: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} else {
    Write-Host "⚠️ No tasks were created successfully" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Advanced Multi-MCP Server Automation is ready!" -ForegroundColor Green
Write-Host "🌍 You now have enterprise-grade news intelligence automation! 📰🚀" -ForegroundColor Cyan