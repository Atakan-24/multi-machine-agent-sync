# Sync for $HOME\projects: commit -> pull --rebase -> push. Run by Task Scheduler every 15 min.
Set-Location "$HOME\projects"

& {
    "--- $(Get-Date)"

    # Claude reads CLAUDE.md, Codex reads AGENTS.md. Git on Windows has no symlinks, so copy the newer one.
    $claude = Get-Item CLAUDE.md
    $agents = Get-Item AGENTS.md
    if ($claude.LastWriteTime -gt $agents.LastWriteTime) { Copy-Item CLAUDE.md AGENTS.md }
    elseif ($agents.LastWriteTime -gt $claude.LastWriteTime) { Copy-Item AGENTS.md CLAUDE.md }

    if (git status --porcelain) {
        git add -A
        git commit -m "Auto-Log: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    }

    git pull --rebase origin main
    if ($LASTEXITCODE -ne 0) {
        git rebase --abort
        "CONFLICT on pull - nothing pushed"
        exit 1
    }

    if (git log origin/main..HEAD --oneline) { git push origin main } else { "nothing to push" }
} *>> git_auto.log
