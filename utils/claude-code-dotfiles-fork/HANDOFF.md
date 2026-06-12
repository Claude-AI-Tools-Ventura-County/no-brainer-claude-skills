# HANDOFF — Claude Code Config Sync System

**Audience:** the next LLM/engineer taking over this sync setup.
**Last updated:** 2026-06-11 · **Owner:** noel@neochro.me (GitHub: `noelsaw1`)
**Status:** live and working. Last synced commit `37be50c` on `main`.

> Everything below uses absolute paths. This doc is self-contained — you do not
> need prior conversation context. Read the **Invariants** section before changing anything.

> **Standalone kit:** this folder also contains [INSTALL.md](INSTALL.md) and
> [templates/](templates/) — generic copies of the allowlist, all three hook
> scripts, and the settings.json hooks snippet. Anyone (or any other repo) can
> replicate this setup from this folder alone; no upstream repo is needed.
> This HANDOFF documents the *live deployment* on this machine; INSTALL.md is
> the machine-agnostic version.

---

## 1. What this system does (TL;DR)

It version-controls the user's global Claude Code config (`~/.claude`) to a **private**
GitHub repo so it syncs across machines, and it propagates a separately-maintained
**skills suite** into `~/.claude` as real files. Sync is automatic via Claude Code
**SessionStart/SessionEnd hooks** (works for both terminal and VS Code sessions).

Two hard rules the whole design exists to guarantee:
1. **Secrets never leave the machine** (esp. `~/.claude/.credentials.json` = the Claude OAuth token).
2. **Only real files are committed — never symlinks** (git stores a symlink as a path string, which is broken on every other machine).

---

## 2. Architecture / data flow

```
┌─────────────────────────────────────────────┐
│ SSOT: giant-brains-claude-skills repo        │  ← EDIT SKILLS ONLY HERE
│ /Users/noelsaw/Documents/GH Repos/           │
│   giant-brains-claude-skills/                │
│ remote: Claude-AI-Tools-Ventura-County/...   │
└───────────────┬─────────────────────────────┘
                │ hooks/sync-skills-from-repo.sh  (copies REAL files, runs at SessionStart)
                ▼
┌─────────────────────────────────────────────┐
│ ~/.claude   (the live Claude Code config)    │
│ git repo, remote = the PRIVATE dotfiles repo │
└───────────────┬─────────────────────────────┘
                │ hooks/session-end-sync.sh  (git add -A + commit + push, runs at SessionEnd)
                ▼
┌─────────────────────────────────────────────┐
│ PRIVATE dotfiles repo on GitHub              │  ← other machines clone/pull from here
│ https://github.com/noelsaw1/claude-code-dotfiles  (PRIVATE)
└─────────────────────────────────────────────┘
```

One-directional for skills: **SSOT repo → `~/.claude` → dotfiles repo.** Edit skills only
in the SSOT repo. The dotfiles repo is a downstream carrier of real files.

---

## 3. The two GitHub repos (do not confuse them)

| Repo | Path / URL | Role | Visibility |
|---|---|---|---|
| **dotfiles (central)** | `~/.claude` → `https://github.com/noelsaw1/claude-code-dotfiles` | Syncs the whole `~/.claude` config (allowlisted) across machines | **PRIVATE** |
| **skills SSOT** | `/Users/noelsaw/Documents/GH Repos/giant-brains-claude-skills` → `Claude-AI-Tools-Ventura-County/giant-brains-claude-skills` | Source of truth for the skill suite; synced via its own remote | (its own) |

> NOTE: This HANDOFF.md lives in the SSOT repo at
> `utils/claude-code-dotfiles-fork/`, alongside the standalone kit (INSTALL.md +
> templates/) and a fork of the upstream documentation (README.md). The kit is
> self-sufficient: the clone of the upstream author's reference repo at
> `/Users/noelsaw/Documents/GH Repos/claude-code-dotfiles` (remote
> `elizabethfuentes12/...`) is no longer needed and can be deleted.

---

## 4. File inventory (all under `~/.claude` unless noted)

| File | Role |
|---|---|
| `.gitignore` | **TRUE allowlist** — ignores everything (`*`), re-includes only synced config. This is the secret-leak firewall. |
| `settings.json` | Claude Code settings. Registers the sync hooks under `hooks.SessionStart` and `hooks.SessionEnd`. No secrets inside. |
| `hooks/session-start-sync.sh` | SessionStart hook: `git pull --rebase --autostash` + runs the skills sync. Always exits 0. |
| `hooks/session-end-sync.sh` | SessionEnd hook: `git add -A` + commit + push. Always exits 0. |
| `hooks/sync-skills-from-repo.sh` | Copies every skill (real files) from the SSOT repo into `~/.claude/skills`. Additive — never deletes non-repo skills. Strips `.DS_Store` on copy and excludes it from the change comparison. |
| `hooks/context-mode-cache-heal.mjs` | Pre-existing unrelated plugin hook (context-mode). Leave it alone. |
| `~/.zshrc` | The old `claude()` auto-sync **function was removed** (hooks replaced it). A comment marks where it was. |

---

## 5. How/when sync triggers

Configured in `~/.claude/settings.json` → `hooks`:

- **`SessionStart`** (every session, terminal **or** VS Code) → `session-start-sync.sh`
  → pull latest config, then refresh skills from SSOT.
- **`SessionEnd`** (every session, terminal **or** VS Code) → `session-end-sync.sh`
  → stage all (allowlisted) changes, commit, push.

**Cadence: once per session** (one pull at start, one push at end). NOT a timer, NOT
a daemon, NOT per-keystroke. A long-running session does not sync mid-session.

Hooks take effect on the **next** session after `settings.json` changes (Claude reads
settings at session start).

---

## 6. Skills model

- **SSOT = the giant-brains repo.** Edit skills there only.
- Skills land in `~/.claude/skills/<leaf-name>` as **real copies** (e.g. repo `utils/read-only` → `~/.claude/skills/read-only`).
- `sync-skills-from-repo.sh` is **additive**: it copies/updates skills found in the SSOT
  repo and **never deletes** skills that aren't in the repo.
- **`debug-mantra` is special:** it is a standalone skill that lives ONLY in `~/.claude/skills`
  and is NOT in the SSOT repo. It rides to the dotfiles repo on its own and the additive
  sync leaves it untouched. This is intentional — the pattern for any "central-repo-only"
  skill is: drop a `SKILL.md` folder into `~/.claude/skills/` and don't add it to the SSOT.

Current skills in SSOT repo: `auto-improve, baseline-spec, blast-radius, bottom-line,
giantbrains, iron-triangle, linear, loose-ends, phase-qa, record-decision, snapshot,
take-a-step-back, utils/read-only`.
Plus standalone in `~/.claude`: `debug-mantra`.

> **The hooks never commit the SSOT repo itself.** SessionStart/SessionEnd
> automate `~/.claude` only. After editing skills in the SSOT repo, commit and
> push *there* manually — it is the one link in the chain with no automation,
> so "edit in SSOT" carries an unstated "...and remember to commit there."

---

## 7. INVARIANTS — do not break these

1. **`.gitignore` must stay a true allowlist** (`*` first, then `!`-includes). If you switch
   it to a blocklist, new secret files Claude Code creates later (tokens, caches) will leak.
2. **Never commit `~/.claude/.credentials.json`** (Claude OAuth token) or any `*.key/*.pem/*.token`,
   `projects/`, `sessions/`, `history.jsonl`. Verify with the commands in §10.
3. **Never commit symlinks.** Skills must be real files. Check: `git ls-files -s | awk '$1==120000'`
   must return nothing (mode 120000 = symlink).
4. **Keep the dotfiles repo PRIVATE.** It exposes local paths and project names even with no secrets.
5. **Hook scripts must always `exit 0`** so a network/auth failure never blocks a session.
6. **Stage with `git add -A`, not an explicit path list** (see bug in §8).

---

## 8. Gotchas & bugs already fixed (don't reintroduce)

- **`git add <list>` aborts on a missing path.** The original design staged
  `git add CLAUDE.md settings.json commands hooks agents rules skills`. Because `CLAUDE.md`,
  `agents`, and `rules` don't exist on this machine, `git add` errored and staged **nothing**,
  so auto-commits silently never happened. **Fix in place:** `session-end-sync.sh` uses
  `git add -A` (safe because the allowlist `.gitignore` constrains what can be staged).
- **Symlinks don't survive git.** Git commits a symlink as a path string, not content →
  broken on clone. That's why skills are copied as real files, not symlinked into `~/.claude`.
- **The zsh `claude()` function bypassed VS Code.** A shell function only wraps terminal
  `claude`; IDE-launched sessions call the binary directly. That's why sync moved to
  Claude Code hooks, which fire regardless of launch method. Don't re-add the zsh function
  (it would double-sync terminal sessions alongside the hooks).
- **`set -e` + `&&` pitfall.** In sync scripts, `[ -L x ] && cmd` under `set -euo pipefail`
  exits the script when the test is false. Use explicit `if` blocks (the scripts already do).
- **`.DS_Store` leaked into the dotfiles repo.** The skills allowlist re-included
  everything under `skills/`, and `cp -R` carried macOS junk over from the SSOT
  working tree (the SSOT's own `.gitignore` didn't help — the files existed on
  *disk*). **Fix in place (2026-06-11):** dotfiles `.gitignore` re-ignores
  `**/.DS_Store` after the allowlist; tracked copies removed (`37be50c`); the sync
  script strips `.DS_Store` on copy AND excludes it from the `diff -rq` change
  check (`-x .DS_Store`) — without the exclude, a junk file in the source would
  trigger a pointless re-copy every single session.
- **Skills are keyed by leaf directory name** (`utils/read-only` → `skills/read-only`).
  Two `SKILL.md` dirs with the same basename anywhere in the SSOT repo would
  silently overwrite each other in `~/.claude/skills`. Keep leaf names unique.

---

## 9. Common maintenance tasks

**Add a new synced config path to the dotfiles repo** (e.g. start syncing `agents/`):
Edit `~/.claude/.gitignore`, add `!/agents/` and `!/agents/**` in the allowlist block. Then
confirm only intended files stage: `cd ~/.claude && git add -A && git status --short`.

**Add a standalone (central-repo-only) skill:** create `~/.claude/skills/<name>/SKILL.md`.
It syncs automatically; the SSOT sync won't touch it.

**Add a skill to the shared suite:** add it in the SSOT repo, commit/push there, then run
`bash ~/.claude/hooks/sync-skills-from-repo.sh` (or just start a new Claude session).

**Test the hooks manually (safe, idempotent):**
```bash
bash ~/.claude/hooks/session-start-sync.sh   # should print nothing, exit 0
bash ~/.claude/hooks/session-end-sync.sh     # commits+pushes if there are changes, exit 0
```

**Change the SSOT repo location:** export `GIANT_BRAINS_REPO=/new/path` (the sync script
honors it) or edit the default in `sync-skills-from-repo.sh`.

---

## 10. Verification commands (run these after any change)

```bash
cd ~/.claude
# JSON still valid:
python3 -c "import json;json.load(open('settings.json'));print('settings.json ok')"
# No secret is tracked (must print the path = ignored):
git check-ignore .credentials.json
# Nothing sensitive staged:
git ls-files | grep -Ei 'credential|token|\.pem|\.key|history\.jsonl' && echo LEAK || echo clean
# No symlinks committed (must be empty):
git ls-files -s | awk '$1==120000{print "SYMLINK:",$4}'
# In sync with GitHub:
git fetch -q origin && [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] && echo "in sync"
```

---

## 11. New-machine setup (consume the config elsewhere)

1. Authenticate to GitHub as `noelsaw1` (repo is private): `gh auth status`.
2. Back up existing config: `mv ~/.claude ~/.claude.bak-$(date +%Y%m%d)`.
3. Clone: `git clone https://github.com/noelsaw1/claude-code-dotfiles.git ~/.claude`.
4. Restore machine-local files from the backup (NOT synced): `.credentials.json`,
   `projects/`, `sessions/`, `plugins/`, `*-cache.json`. If `.credentials.json` is missing,
   just log into Claude Code once.
5. The hooks are already in `settings.json`; skills arrive as real files from the clone.
   The SSOT repo is only needed on machines where you *edit* skills.

---

## 12. Known issues / TODO

- ~~`.DS_Store` files are committed~~ **RESOLVED 2026-06-11** — see §8 for what
  was done (gitignore re-ignore, `git rm --cached`, sync-script strip + diff exclude).
- **SessionEnd may not fire on a hard crash / force-quit of VS Code.** Acceptable — the next
  SessionStart pull reconciles, and nothing is lost locally. Don't add a mid-session timer
  to "fix" this unless the user asks.
- **`debug-mantra` has no upstream repo** — single source of truth for it is `~/.claude` only.
  Fine by design, but note it if you ever script a "reconcile skills against SSOT" cleanup
  (it must be on the allow-list of exceptions).

---

## 13. Current state snapshot (2026-06-11, post .DS_Store cleanup)

- dotfiles repo HEAD: `37be50c` on `main`, in sync with `origin` (PRIVATE).
- Tracked: `.gitignore`, `settings.json`, `commands/` (2), `hooks/` (4), `skills/` (14 skills, 16 files).
- No secrets tracked; no symlinks tracked; no `.DS_Store` tracked (verified).
- Sync mechanism: Claude Code `SessionStart`/`SessionEnd` hooks. Old zsh function removed.
- Standalone kit (INSTALL.md + templates/) published alongside this doc in the
  SSOT repo at `utils/claude-code-dotfiles-fork/`.
