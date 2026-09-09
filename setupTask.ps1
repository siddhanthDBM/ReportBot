$ScriptPath = Join-Path $PSScriptRoot 'askDailyUpdate.ps1'
$TaskName   = 'WeeklyReportBot - Daily Update'

$Action  = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File `"$ScriptPath`""

$Trigger = New-ScheduledTaskTrigger -Weekly `
    -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 5:00PM

$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Force

Write-Host "Scheduled task '$TaskName' created: runs Mon-Fri at 5:00 PM."
