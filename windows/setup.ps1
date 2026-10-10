# Installs git_auto.ps1 and a scheduled task that runs it every 15 minutes.
$ErrorActionPreference = "Stop"
$projects = "$HOME\projects"

gh auth setup-git
Copy-Item "$PSScriptRoot\git_auto.ps1" "$projects\git_auto.ps1"

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$projects\git_auto.ps1`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
Register-ScheduledTask -TaskName "GitAutoSync" -Action $action -Trigger $trigger -Force | Out-Null
