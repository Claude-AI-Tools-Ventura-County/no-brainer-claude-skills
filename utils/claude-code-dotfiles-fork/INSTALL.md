# INSTALL — Claude Code Config Sync (standalone kit)

Sync your global Claude Code config (`~/.claude`) across machines via a **private**
git repo, automatically, using Claude Code's own SessionStart/SessionEnd hooks.
Optionally propagate a skills suite maintained in a separate repo.

This folder is self-contained: everything you need is in `templates/`. No other
repo is required. (`README.md` in this folder is the upstream project's original
documentation, kept for background; `HANDOFF.md` documents one live deployment
of this kit as a worked example.)

## What's in `templates/`

| File | Install as | Role |
|---|---|---|
| `dot-gitignore` | `~/.claude/.gitignore` | **True allowlist** — ignores everything, re-includes only synced config. The secret-leak firewall. |
| `session-start-sync.sh` | `~/.claude/hooks/session-start-sync.sh` | Pulls latest config at every session start (terminal and IDE). |
| `session-end-sync.sh` | `~/.claude/hooks/session-end-sync.sh` | Commits and pushes allowlisted changes at every session end. |
| `sync-skills-from-repo.sh` | `~/.claude/hooks/sync-skills-from-repo.sh` | **Optional.** Copies skills from a separate SSOT repo as real files. |
| `settings-hooks-snippet.json` | merge into `~/.claude/settings.json` | Registers the two hooks. |

## Design rules (why it's built this way)

1. **Secrets never leave the machine.** The `.gitignore` is a true allowlist (`*`
   first, then `!`-includes), so any new file Claude Code invents later — tokens,
   caches, credentials — stays untracked by default.
2. **Only real files, never symlinks.** Git stores a symlink as a path string,
   which is broken on every other machine. Skills are *copied*, not linked.
3. **Hooks always `exit 0`.** A network or auth failure must never block a session.
4. **Hooks, not a shell wrapper.** A zsh `claude()` function only fires for
   terminal launches; hooks fire for IDE sessions too.
5. **Stage with `git add -A`,** never an explicit path list — a single missing
   path makes `git add` abort and silently stage nothing. The allowlist makes
   `-A` safe.

## Setup (first machine)

1. Create a **PRIVATE** GitHub repo (it will expose local paths and project
   names even with no secrets):
   ```bash
   gh repo create YOUR-USERNAME/claude-code-dotfiles --private
   ```
2. Initialize `~/.claude` as a git repo:
   ```bash
   cd ~/.claude
   git init -b main
   git remote add origin https://github.com/YOUR-USERNAME/claude-code-dotfiles.git
   ```
3. Install the allowlist and hooks (run from this folder):
   ```bash
   cp templates/dot-gitignore ~/.claude/.gitignore
   mkdir -p ~/.claude/hooks
   cp templates/session-start-sync.sh templates/session-end-sync.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/session-*-sync.sh
   ```
4. Register the hooks: merge the `hooks` block from
   `templates/settings-hooks-snippet.json` into `~/.claude/settings.json`
   (append to existing `SessionStart`/`SessionEnd` arrays if you have any —
   drop the `_comment` key). Hooks take effect on the **next** session.
5. First commit and push:
   ```bash
   cd ~/.claude
   git add -A
   git status --short   # review: only allowlisted config should appear
   git commit -m "Initial Claude Code config sync"
   git push -u origin main
   ```
6. Verify nothing sensitive is tracked:
   ```bash
   cd ~/.claude
   git check-ignore .credentials.json   # must print the path (= ignored)
   git ls-files | grep -Ei 'credential|token|\.pem|\.key|history\.jsonl' && echo LEAK || echo clean
   git ls-files -s | awk '$1==120000{print "SYMLINK:",$4}'   # must print nothing
   ```

## Optional: skills from an SSOT repo

If you maintain skills in a separate repo (so they can be public, reviewed, and
versioned independently of your private config):

1. ```bash
   cp templates/sync-skills-from-repo.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/sync-skills-from-repo.sh
   ```
2. Point it at your repo: edit the `REPO=` default in the script, or export
   `SKILLS_SSOT_REPO=/path/to/your-skills-repo` in your shell profile.
3. Done — `session-start-sync.sh` already calls it when present. Every directory
   containing a `SKILL.md` anywhere in the SSOT repo is copied to
   `~/.claude/skills/<leaf-name>` as real files; keep leaf names unique.
4. **Edit skills only in the SSOT repo** — the copy is one-directional and
   overwrites `~/.claude` copies. Skills that exist only in `~/.claude/skills/`
   (no SSOT counterpart) are never touched, so machine-local or
   dotfiles-only skills coexist fine. **The hooks never commit the SSOT repo
   itself** — commit and push there manually when you edit skills.

## Every other machine

1. Authenticate to GitHub (`gh auth status`), then:
   ```bash
   mv ~/.claude ~/.claude.bak-$(date +%Y%m%d)
   git clone https://github.com/YOUR-USERNAME/claude-code-dotfiles.git ~/.claude
   ```
2. Restore machine-local files from the backup (these are NOT synced):
   `.credentials.json`, `projects/`, `sessions/`, `plugins/`, `*-cache.json`.
   If `.credentials.json` is missing, just log into Claude Code once.
3. Hooks are already registered in the cloned `settings.json`; skills arrive as
   real files. The SSOT repo is only needed on machines where you *edit* skills.

## Cadence and failure behavior

- **Once per session:** one pull at SessionStart, one push at SessionEnd. No
  timers, no daemons. A long-running session does not sync mid-session.
- **Hard crash / force-quit:** SessionEnd may not fire. Nothing is lost locally;
  the next SessionStart pull reconciles.
- **Two machines push concurrently:** the second push fails silently (hooks
  exit 0); the next SessionStart `pull --rebase --autostash` reconciles and the
  following SessionEnd pushes.
