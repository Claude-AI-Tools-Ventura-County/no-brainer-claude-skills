#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Claude Code SessionEnd hook — commit & push config changes to the remote.
# Fires on EVERY session end (terminal AND VS Code / IDE).
# `git add -A` is safe here: the .gitignore is a true allowlist, so only the
# whitelisted config is ever staged and all secrets/runtime data stay ignored.
# (Avoids the trap where naming a non-existent path like CLAUDE.md/agents/rules
#  makes `git add` abort and stage nothing.)
# Always exits 0 so a push failure (offline, etc.) never surfaces as an error.
# ─────────────────────────────────────────────────────────────────────────────
dir="$HOME/.claude"
[ -d "$dir/.git" ] || exit 0

git -C "$dir" add -A 2>/dev/null || true

if ! git -C "$dir" diff --cached --quiet 2>/dev/null; then
  git -C "$dir" commit -q -m "chore: sync config $(date '+%Y-%m-%d %H:%M')" 2>/dev/null || true
  git -C "$dir" push origin HEAD:main --quiet 2>/dev/null || true
fi

exit 0
