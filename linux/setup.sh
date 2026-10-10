#!/bin/bash
# Installs git_auto.sh and a systemd user timer that runs it every 15 minutes.
set -e
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
units="$HOME/.config/systemd/user"

gh auth setup-git
cp "$repo_dir/git_auto.sh" "$HOME/projects/git_auto.sh"
chmod +x "$HOME/projects/git_auto.sh"
mkdir -p "$units"

cat > "$units/git-auto.service" <<UNIT
[Service]
Type=oneshot
ExecStart=$HOME/projects/git_auto.sh
StandardOutput=append:$HOME/projects/git_auto.log
StandardError=append:$HOME/projects/git_auto.log
UNIT

cat > "$units/git-auto.timer" <<UNIT
[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
UNIT

systemctl --user daemon-reload
systemctl --user enable --now git-auto.timer
loginctl enable-linger "$USER"   # keep the timer running after logout
