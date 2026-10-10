#!/bin/bash
# Installs auto-sync for ~/projects (Linux, systemd-User-Timer, alle 15 Min: commit -> pull --rebase -> push).
# Requires: repo cloned to ~/projects, gh auth login done.
set -e
cd "$HOME/projects"
cat > git_auto.sh <<'INNER'
#!/bin/bash
# Auto-Backup: committet & pusht ~/projects. Mit Pull, weil Claude von anderen Rechnern CLAUDE.md ändern kann.
cd "$HOME/projects" || exit 1
echo "--- $(date)"
if [[ -n $(git status --porcelain) ]]; then
    git add -A
    git commit -m "Auto-Log: $(date '+%Y-%m-%d %H:%M')"
fi
# Neuesten Stand holen (andere Claudes ändern z.B. CLAUDE.md); bei Konflikt abbrechen
if ! git pull --rebase origin main; then git rebase --abort 2>/dev/null; echo "KONFLIKT beim Pull - nichts gepusht"; exit 1; fi
[[ -n $(git log origin/main..HEAD --oneline 2>/dev/null) ]] && git push origin main || echo "Nichts zu pushen"
INNER
chmod +x git_auto.sh
command -v gh >/dev/null && gh auth setup-git
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/git-auto.service <<INNER
[Unit]
Description=Git Auto-Backup ~/projects
[Service]
Type=oneshot
ExecStart=$HOME/projects/git_auto.sh
StandardOutput=append:$HOME/projects/git_auto.log
StandardError=append:$HOME/projects/git_auto.log
INNER
cat > ~/.config/systemd/user/git-auto.timer <<'INNER'
[Unit]
Description=Git Auto-Backup alle 15 Min
[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
Persistent=true
[Install]
WantedBy=timers.target
INNER
systemctl --user daemon-reload
systemctl --user enable --now git-auto.timer
loginctl enable-linger "$USER" 2>/dev/null || true
echo "=== FERTIG: Auto-Backup läuft. Log: ~/projects/git_auto.log ==="
