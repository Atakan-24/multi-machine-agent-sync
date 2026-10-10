#!/bin/bash
# Auto-sync for ~/projects: commit -> pull --rebase -> push. Run every 15 min by launchd (macOS) or a systemd timer (Linux).
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
cd "$HOME/projects" || exit 1
echo "--- $(date)"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repo"; exit 0; }
BRANCH="$(git branch --show-current)"

if [[ -n $(git status --porcelain) ]]; then
    git add -A
    git commit -m "Auto-Log: $(date '+%Y-%m-%d %H:%M')"
fi

if ! git pull --rebase origin "$BRANCH"; then
    git rebase --abort 2>/dev/null
    echo "CONFLICT on pull - nothing pushed"
    exit 1
fi

if [[ -n $(git log "origin/$BRANCH..HEAD" --oneline) ]]; then
    git push origin "$BRANCH"
else
    echo "nothing to push"
fi
