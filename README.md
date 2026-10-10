# multi-machine-agent-sync

Backup and shared context for Claude Code and Codex across four machines (macOS, Kali, BlackArch, Windows Server).

Each machine syncs `~/projects` to its own private GitHub repository every 15 minutes. Each repository contains a `CLAUDE.md` that the agents on that machine read at session start and update when they change something. Codex reads the same file as `AGENTS.md`.

## Why

I use Claude Code and Codex on all four machines. Agent sessions don't share state, so I kept running into the same issues: work created in a session had no backup, an agent on one machine redid setup that was already finished on another, and a shared repository synced from several machines produced merge conflicts that stopped the sync everywhere.

## How it works

```
macOS            ~/projects  ->  launchd (900 s)         ->  <you>/mac
Kali             ~/projects  ->  cron / systemd timer    ->  <you>/t480-kali
BlackArch        ~/projects  ->  systemd timer           ->  <you>/blackarch
Windows Server   ~/projects  ->  Task Scheduler (15 min) ->  <you>/windows-server
```

Every run does `commit`, then `pull --rebase`, then `push`. If the rebase fails, the script runs `git rebase --abort`, logs the conflict and exits without pushing.

Each machine owns one repository. Nothing else writes to it except an occasional edit to `CLAUDE.md` from an agent on another machine, which is why the pull step is there. Agents can read the other machines' files with:

```bash
gh api repos/<you>/<repo>/contents/CLAUDE.md -H "Accept: application/vnd.github.raw"
```

On macOS and Linux, `AGENTS.md` is a symlink to `CLAUDE.md`. Git on Windows checks symlinks out as plain text by default, so there the scheduled task copies whichever of the two files is newer over the other.

`CLAUDE.md` contains:

- the instruction to pull and read the file at the start of a session
- a dated log of what was set up or changed on that machine
- the list of projects on the machine
- the rule that new projects go in `~/projects/<name>`, since nothing outside that folder is backed up

Secrets (`.env`, keys, service-account JSON) are excluded via `.gitignore` before the first commit. When I moved existing projects into `~/projects`, I left symlinks at the old paths so existing scripts kept working.

## Files

```
macos/git_auto.sh          sync script
macos/com.git.auto.plist   launchd agent (StartInterval 900, RunAtLoad)
linux/setup.sh             installs sync script + systemd user timer
windows/setup.ps1          installs sync script + scheduled task
templates/CLAUDE.md        starting point for a machine's CLAUDE.md
templates/.gitignore       secret and noise exclusions
```

## Setup

macOS:

```bash
mkdir -p ~/projects
cp macos/git_auto.sh ~/projects/ && chmod +x ~/projects/git_auto.sh
sed "s|__HOME__|$HOME|g" macos/com.git.auto.plist > ~/Library/LaunchAgents/com.git.auto.plist
launchctl load ~/Library/LaunchAgents/com.git.auto.plist
```

Linux:

```bash
gh repo clone <you>/<repo> ~/projects
bash linux/setup.sh
```

Windows (PowerShell):

```powershell
gh repo clone <you>/<repo> $HOME\projects
powershell -ExecutionPolicy Bypass -File windows\setup.ps1
```

All three assume `gh auth login` has been run.

## Notes

On the Kali machine the agent found 28 projects in `~/projects`, each already with its own remote. Committing them into one repository would only have stored gitlinks, so it switched to generating a `MANIFEST.md` (project, remote, last commit) and wrote down the reason in `CLAUDE.md`. This setup is meant to support that kind of per-machine adjustment, as long as the agent records it in the file.

Known limitations:

- Up to 15 minutes of changes can be lost. This is a backup, not live sync.
- Agents update `CLAUDE.md` because it tells them to. Nothing enforces it.
- Projects that have their own remote are only backed up if they get pushed there.
