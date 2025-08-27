# PowerShell script to create a daily scheduled task for fetching AllAfrica headlines
# Run this script as Administrator

$TaskName = "DailyAllAfricaHeadlines"
$TaskDescription = "Fetch AllAfrica headlines daily"
$BatchFilePath = "C:\Users\tjd20.LAPTOP-PCMC2SUO\news\run-fetch.bat"
$LogPath = "C:\Users\tjd20.LAPTOP-PCMC2SUO\news\task.log"

# Check if task already exists and remove it
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($ExistingTask) {
    Write-Host "Removing existing task: $TaskName"
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create the action (what to run)
$Action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$BatchFilePath`" > `"$LogPath`" 2>&1"

# Create the trigger (when to run) - daily at 8:00 AM
$Trigger = New-ScheduledTaskTrigger -Daily -At 8:00AM

# Create the principal (run as current user)
$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

# Create the settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Register the scheduled task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description $TaskDescription

Write-Host "Successfully created scheduled task: $TaskName"
Write-Host "The task will run daily at 8:00 AM"
Write-Host "Logs will be saved to: $LogPath"
Write-Host ""
Write-Host "To test the task immediately, run:"
Write-Host "Start-ScheduledTask -TaskName '$TaskName'"