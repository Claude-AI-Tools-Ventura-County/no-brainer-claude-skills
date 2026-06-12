#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Claude Code SessionStart hook — pull latest config + refresh skills.
# Fires on EVERY session start (terminal AND VS Code / IDE), unlike a zsh
# wrapper function, which only fires for terminal launches.
# Always exits 0 so a network/auth hiccup never blocks the session.
# ─────────────────────────────────────────────────────────────────────────────
dir="$HOME/.claude"

# 1. Pull newest config from the remote (rebase to avoid merge noise; autostash
#    any local churn so the pull never fails on a dirty tree).
if [ -d "$dir/.git" ]; then
  git -C "$dir" pull --rebase --autostash origin main --quiet 2>/dev/null || true
fi

# 2. OPTIONAL: refresh skills from an SSOT repo as REAL files. Delete this
#    block if you don't maintain skills in a separate repo.
if [ -x "$dir/hooks/sync-skills-from-repo.sh" ]; then
  bash "$dir/hooks/sync-skills-from-repo.sh" >/dev/null 2>&1 || true
fi

exit 0
