# CLAUDE.md / AGENTS.md – <machine> (repo <you>/<repo>)

> **MANDATORY FOR EVERY AGENT (Claude and Codex):**
> 1. Read this file at the start of every session and follow it.
> 2. Pull first: `git -C ~/projects pull`
> 3. When you set up, change or decide something: record it under "This machine" right away (with the date and the agent name), then commit and push.
> 4. This file is the memory shared across all machines and agents. If you don't update it, the next agent won't know.

## Code style (most important rule)
- Code must be easy for other programmers to read and review.
- As little code as possible: no bloat, no abstractions or options "for later", no dead lines.
- One thing per line, no nested one-liners. Comment only where the *why* isn't obvious.
- Before finishing, reread your code and delete every line that isn't needed.

## How to work
- Do things yourself instead of handing back commands to run. Report briefly afterwards.
- Logins, passwords and permanent deletion stay with the human.
- Look before you overwrite.

## This machine
- YYYY-MM-DD (agent): ...

## Projects on this machine
| Folder | Purpose |
|---|---|

## All machines
| Repo | Machine | Sync |
|---|---|---|
| <you>/mac | macOS | pull + push every 15 min (launchd) |
| <you>/linux-1 | Linux | pull + push every 15 min (systemd timer) |
| <you>/windows | Windows | pull + push every 15 min (Task Scheduler) |

Read another machine's state: `gh api repos/<you>/<repo>/contents/CLAUDE.md -H "Accept: application/vnd.github.raw"`

## Rules
- New projects always go in `~/projects/<name>/` and get listed above. Only `~/projects` is backed up.
- Secrets go in `.gitignore` before the first commit.
