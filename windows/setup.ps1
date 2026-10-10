# Richtet Auto-Sync von $HOME\projects ein (Windows, Aufgabenplanung, alle 15 Min: commit -> pull --rebase -> push).
# Voraussetzung: git + gh installiert, "gh auth login" erledigt, Repo nach $HOME\projects geklont.
$ErrorActionPreference = "Stop"
$P = "$HOME\projects"
Set-Location $P
gh auth setup-git
git config core.autocrlf true

@'
# Auto-Sync: committet, pullt (rebase), pusht. Bei Konflikt Abbruch ohne Push.
Set-Location "$HOME\projects"
$log = "$HOME\projects\git_auto.log"
function L($m) { Add-Content $log $m }
L "--- $(Get-Date)"
# CLAUDE.md und AGENTS.md identisch halten (neuere gewinnt)
$c = Get-Item CLAUDE.md -ErrorAction SilentlyContinue; $a = Get-Item AGENTS.md -ErrorAction SilentlyContinue
if ($c -and $a -and ((Get-FileHash $c).Hash -ne (Get-FileHash $a).Hash)) {
    if ($c.LastWriteTime -gt $a.LastWriteTime) { Copy-Item CLAUDE.md AGENTS.md -Force } else { Copy-Item AGENTS.md CLAUDE.md -Force }
}
if (git status --porcelain) {
    git add -A 2>&1 | % { L $_ }
    git commit -m "Auto-Log: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>&1 | % { L $_ }
}
git pull --rebase origin main 2>&1 | % { L $_ }
if ($LASTEXITCODE -ne 0) { git rebase --abort 2>$null; L "KONFLIKT beim Pull - nichts gepusht"; exit 1 }
if (git log origin/main..HEAD --oneline) { git push origin main 2>&1 | % { L $_ } } else { L "Nichts zu pushen" }
'@ | Set-Content "$P\git_auto.ps1" -Encoding UTF8

$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$P\git_auto.ps1`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15)
Register-ScheduledTask -TaskName "GitAutoSync" -Action $action -Trigger $trigger -Description "Git Auto-Sync projects" -Force | Out-Null
Start-ScheduledTask -TaskName "GitAutoSync"
Write-Host "=== FERTIG: Auto-Sync laeuft alle 15 Min. Log: $P\git_auto.log ==="
