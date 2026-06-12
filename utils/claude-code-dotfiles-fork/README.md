# How to Sync Claude Code Settings Across Multiple Machines

Fork of: https://github.com/elizabethfuentes12/claude-code-dotfiles

Original License: MIT-0

**Claude Code dotfiles** let you version-control your `~/.claude` directory — including `CLAUDE.md`, custom slash commands, settings, hooks, and agents — so your AI coding environment stays in sync across every machine you use. No extra tools required: just Git and a shell function.

> This approach works with any terminal-based AI coding assistant that stores config in a dotfiles directory. The examples below focus on [Claude Code](https://docs.anthropic.com/en/docs/claude-code), Anthropic's CLI for software engineering.

---

## What Is Inside This Repo

| File / Folder | Purpose |
|---------------|---------|
| [claude-code-skills/](https://github.com/elizabethfuentes12/claude-code-dotfiles/tree/main/claude-code-skills) (upstream only) | Reusable Claude Code skills for AWS — architecture diagrams in draw.io, and more |
| `CLAUDE.md` | Global instructions, preferences, and context that Claude reads at session start |
| `settings.json` | Model selection, permissions, and environment config |
| `commands/` | Custom slash commands (`.md` files) available in every session |
| `hooks/` | Shell hooks that run before or after Claude tool calls |
| `agents/` | Custom sub-agents with specialized behaviors |
| `rules/` | Reusable rule sets for specific workflows |

---

## Why Sync Claude Code Config With Git

If you use Claude Code as your AI coding assistant, you likely have:

- A carefully crafted `CLAUDE.md` with instructions, preferences, and context
- Custom slash commands in `commands/` you built over time
- A `settings.json` tuned to your workflow
- Hooks, agents, or rules that shape how Claude behaves

**All of that lives in `~/.claude` and stays on one machine.** Switch to your work laptop and you start from zero. Get a new computer and you lose everything.

This dotfiles repo fixes that: treat `~/.claude` as a Git repository, push it to GitHub, and add a shell wrapper that pulls on open and pushes on close — automatically.

---

## What Files Are Excluded From Sync

These files are machine-specific or sensitive and are excluded via `.gitignore`:

| Excluded | Reason |
|----------|--------|
| `cache/`, `backups/`, `file-history/` | Local ephemeral data, not portable |
| `history.jsonl` | Conversation history — private and machine-specific |
| `projects/`, `shell-snapshots/`, `paste-cache/` | Machine-specific runtime data |
| `plugins/`, `plans/`, `session-env/` | Local runtime state |
| `*.log`, `sessions/`, `transcripts/` | Temporary files |
| `*.key`, `*.pem`, `credentials.json`, `*.token` | **Never version secrets** |

---

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed: `npm install -g @anthropic-ai/claude-code`
- [Git](https://git-scm.com/) installed
- [GitHub CLI](https://cli.github.com/) (`gh`) — optional but recommended
- A GitHub account

---

## How to Set Up Claude Code Dotfiles (First Machine)

Do this once, on your primary machine.

### Step 1 — Create the GitHub repo

```bash
# Option A: using GitHub CLI
gh repo create claude-code-dotfiles --public

# Option B: go to github.com/new and create it manually
```

> **Public or private?** Public repos let the community learn from your config. Private keeps it just for you. Either works — never put secrets in `CLAUDE.md`.

### Step 2 — Initialize Git in `~/.claude`

```bash
cd ~/.claude
git init
git remote add origin git@github.com:YOUR-USERNAME/claude-code-dotfiles.git
```

### Step 3 — Create the `.gitignore`

This is the most important step. Use an explicit allowlist so only the files you choose get versioned.

```bash
cat > ~/.claude/.gitignore << 'EOF'
# Never version these
.api_key
credentials.json
secrets/
*.key
*.pem
auth.json
*.token

# Claude Code runtime / cache (machine-specific, not portable)
cache/
backups/
file-history/
history.jsonl
paste-cache/
plugins/
projects/
shell-snapshots/
plans/
session-env/
transcripts/
sessions/
*.log
clipboard/
project_clones/
.cache/

# Always version these (explicit allowlist)
!CLAUDE.md
!settings.json
!commands/
!skills/
!hooks/
!agents/
!rules/
EOF
```

### Step 4 — First commit and push

```bash
git add CLAUDE.md settings.json commands/
git commit -m "Initial Claude Code config"
git push -u origin main
```

Your config is now on GitHub.

---

## How to Clone Claude Code Config on a New Machine

Do this on every other computer where you want your config.

### Step 1 — Back up any existing config

```bash
mv ~/.claude ~/.claude.bak
```

### Step 2 — Clone the repo as `~/.claude`

```bash
git clone git@github.com:YOUR-USERNAME/claude-code-dotfiles.git ~/.claude
```

Your `CLAUDE.md`, commands, and settings are now in place instantly.

### Step 3 — Add the auto-sync shell function

Open `~/.zshrc` (or `~/.bashrc`) and add:

```bash
# Auto-sync Claude Code config across machines
claude() {
  echo "Syncing Claude config..."
  git -C ~/.claude pull origin main --quiet

  command claude "$@"

  echo "Saving config changes..."
  git -C ~/.claude add CLAUDE.md settings.json commands/ hooks/ agents/ rules/ 2>/dev/null
  if ! git -C ~/.claude diff --cached --quiet; then
    git -C ~/.claude commit -m "chore: sync config $(date '+%Y-%m-%d %H:%M')"
    git -C ~/.claude push origin HEAD:main --quiet
    echo "Config updated on GitHub"
  else
    echo "No changes"
  fi
}
```

Reload your shell:

```bash
source ~/.zshrc
```

### How the auto-sync works

Every time you run `claude`:

1. It **pulls** the latest config from GitHub before the session starts
2. Opens Claude Code normally
3. When you exit, it **commits and pushes** any changes automatically

---

## How to Customize Your Claude Code Config

### CLAUDE.md — Global instructions for every session

This is the most powerful file. Claude reads it at the start of every session. Use it to define:

- Your preferred coding style and conventions
- How you want Claude to communicate (tone, verbosity)
- Rules that apply to every project
- Patterns and preferences you never want to repeat

Example:

```markdown
## Code Style
- Always use snake_case for Python variables
- Prefer explicit over implicit
- Never add comments unless the logic is non-obvious

## Communication
- Be concise. No preamble.
- No emojis unless I ask.
- When in doubt, ask before making irreversible changes.
```

> **Security reminder**: If your repo is public, `CLAUDE.md` is public too. Never put account IDs, API keys, internal URLs, or personal information in it.

### Custom slash commands

Place `.md` files in `~/.claude/commands/`. Each file becomes a `/command-name` you can invoke during any Claude session.

Example — `commands/summarize-pr.md`:

```markdown
You are a senior engineer reviewing a pull request.
Summarize the changes in 3 bullet points, focusing on what changed and why.
Then give one concern and one thing done well.
```

Now `/summarize-pr` is available in every session, on every machine.

---

## Optional — Sync Commands to Kiro (macOS only)

> This section is optional and only applies if you use [Kiro](https://kiro.dev), AWS's AI IDE for macOS.

If you use both Claude Code and Kiro, you can reuse the same slash commands in both tools. Claude Code commands live in `~/.claude/commands/` as `.md` files with a Claude-specific YAML frontmatter. Kiro reads steering files from `~/.kiro/steering/` with a different frontmatter format.

The script below converts your Claude commands to Kiro steering files automatically — stripping Claude's frontmatter and adding Kiro's `inclusion: manual` header.

### Setup

**Step 1 — Save the script**

```bash
mkdir -p ~/.claude/hooks
cat > ~/.claude/hooks/sync-to-kiro.sh << 'EOF'
#!/bin/bash
# Syncs ~/.claude/commands/*.md to ~/.kiro/steering/
# Strips Claude frontmatter (name/description) and adds Kiro's inclusion: manual

CLAUDE_COMMANDS="$HOME/.claude/commands"
KIRO_STEERING="$HOME/.kiro/steering"

mkdir -p "$KIRO_STEERING"

synced=0
deleted=0

# Sync new and modified files
for src in "$CLAUDE_COMMANDS"/*.md; do
    [ -f "$src" ] || continue

    filename=$(basename "$src")
    dst="$KIRO_STEERING/$filename"

    # Extract content after Claude's frontmatter (after the second ---)
    content=$(awk 'BEGIN{count=0} /^---/{count++; next} count>=2{print}' "$src")

    new_content="---
inclusion: manual
---
$content"

    # Only write if content changed
    if [ ! -f "$dst" ] || [ "$new_content" != "$(cat "$dst")" ]; then
        printf '%s\n' "$new_content" > "$dst"
        echo "[sync-to-kiro] Updated: $filename"
        ((synced++))
    fi
done

# Remove steering files that no longer have a matching command
for dst in "$KIRO_STEERING"/*.md; do
    [ -f "$dst" ] || continue
    filename=$(basename "$dst")
    if [ ! -f "$CLAUDE_COMMANDS/$filename" ]; then
        rm "$dst"
        echo "[sync-to-kiro] Removed: $filename"
        ((deleted++))
    fi
done

if [ "$synced" -eq 0 ] && [ "$deleted" -eq 0 ]; then
    echo "[sync-to-kiro] Nothing to sync."
fi
EOF
chmod +x ~/.claude/hooks/sync-to-kiro.sh
```

**Step 2 — Run it manually or hook it to your workflow**

```bash
bash ~/.claude/hooks/sync-to-kiro.sh
```

Or add it to your auto-sync shell function so it runs every time you exit Claude:

```bash
claude() {
  git -C ~/.claude pull origin main --quiet
  command claude "$@"
  bash ~/.claude/hooks/sync-to-kiro.sh
  # ... rest of your sync logic
}
```

### How it works

- Reads every `.md` file in `~/.claude/commands/`
- Strips the Claude YAML frontmatter block (`name`, `description`)
- Writes the file to `~/.kiro/steering/` with `inclusion: manual` as the new header
- Deletes any Kiro steering file whose source command no longer exists
- Skips files that haven't changed (content diff before writing)

> **Note:** The `inclusion: manual` setting means the steering file is only applied when you explicitly reference it in Kiro — it won't be injected into every conversation automatically.

---

## Troubleshooting

**`git push` fails with "non-fast-forward"**

Another machine pushed changes first. Pull and rebase:

```bash
git -C ~/.claude pull --rebase origin main
git -C ~/.claude push origin HEAD:main
```

**Claude doesn't pick up `CLAUDE.md` changes**

Claude reads `CLAUDE.md` at session start. Exit and reopen Claude for changes to take effect.

**I accidentally committed a secret**

Remove it immediately:

```bash
git -C ~/.claude rm --cached path/to/secret
git -C ~/.claude commit -m "remove secret"
git -C ~/.claude push origin HEAD:main
```

Then rotate the secret — pushing to GitHub exposes it even after deletion unless you rewrite history.

---

## Security Best Practices

- Use an explicit allowlist in `.gitignore` rather than a blocklist
- Never put credentials, API keys, or account IDs in `CLAUDE.md` or `settings.json`
- Keep cloud credentials in their respective CLI config files (`~/.aws/credentials`, etc.), not here
- If using a public repo, review every commit before pushing
- Use SSH (`git@github.com:...`) instead of HTTPS for the remote

---

## Frequently Asked Questions

### Does this work on Linux and macOS?

Yes. The shell function works on any system with `bash` or `zsh`. The Kiro sync section is macOS-only because Kiro currently targets macOS.

### Can I use this with a private GitHub repo?

Yes. Set `--private` instead of `--public` when creating the repo with `gh repo create`. Everything else works the same.

### What happens if two machines push at the same time?

The second push will fail with a non-fast-forward error. Run `git -C ~/.claude pull --rebase origin main` and push again. The shell function handles most cases automatically.

### Is it safe to make the repo public?

Yes, as long as you never commit secrets, API keys, credentials, or personal information. The `.gitignore` excludes sensitive files by default. Review every commit before pushing.

### Can I sync Claude Code config without GitHub?

Yes. You can use any Git remote: GitLab, Bitbucket, or a self-hosted server. Replace the `git@github.com:...` URL with your remote.

### How do I add a new file to the sync?

Add it to the allowlist in `.gitignore` (with a `!` prefix) and to the `git add` line in the shell function.

---

## Contributing

Contributions are welcome! See the upstream [CONTRIBUTING](https://github.com/elizabethfuentes12/claude-code-dotfiles/blob/main/CONTRIBUTING.md) for more information.

---

## Security

If you discover a potential security issue in this project, notify AWS/Amazon Security via the [vulnerability reporting page](http://aws.amazon.com/security/vulnerability-reporting/). Please do **not** create a public GitHub issue.

---

## License

This library is licensed under the MIT-0 License. See the upstream [LICENSE](https://github.com/elizabethfuentes12/claude-code-dotfiles/blob/main/LICENSE) file for details.
