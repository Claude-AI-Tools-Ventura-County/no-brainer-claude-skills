#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# sync-skills-from-repo.sh  (OPTIONAL — only if you maintain skills in a repo)
#
# SSOT (single source of truth): your skills repo.
# Copies every skill as REAL FILES (never symlinks) into ~/.claude/skills so
# Claude Code loads them AND the dotfiles repo can sync them across machines.
#
# Flow:  skills repo  ──copy──▶  ~/.claude/skills  ──git──▶  dotfiles repo
#
# One-directional: EDIT SKILLS IN THE REPO ONLY. This script overwrites the
# ~/.claude copies from the repo. It never deletes ~/.claude skills that have no
# counterpart in the repo (e.g. standalone skills), so those are left untouched.
#
# CAVEAT: skills are keyed by LEAF directory name (repo `utils/read-only` lands
# as `~/.claude/skills/read-only`). Two SKILL.md dirs with the same basename
# anywhere in the repo would overwrite each other — keep leaf names unique.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# Point this at your skills repo, or export SKILLS_SSOT_REPO to override.
REPO="${SKILLS_SSOT_REPO:-$HOME/path/to/your-skills-repo}"
DEST="$HOME/.claude/skills"

if [ ! -d "$REPO" ]; then
  echo "[sync-skills] SSOT repo not found at: $REPO — skipping (this machine has no repo)."
  exit 0
fi

mkdir -p "$DEST"
synced=0

# Every directory containing a SKILL.md anywhere in the repo (excluding .git) is
# a skill. It lands in ~/.claude/skills/<leaf-name>.
while IFS= read -r skill_md; do
  src_dir="$(dirname "$skill_md")"
  name="$(basename "$src_dir")"
  dst_dir="$DEST/$name"

  # An old symlink in the way? Remove it so we write a REAL directory.
  if [ -L "$dst_dir" ]; then
    rm -f "$dst_dir"
  fi

  # Copy only if missing or changed (keeps git churn minimal). .DS_Store is
  # excluded from the comparison and stripped from the copy so macOS junk never
  # reaches the dotfiles repo and never causes a perpetual re-copy.
  if [ ! -d "$dst_dir" ] || ! diff -rq -x .DS_Store "$src_dir" "$dst_dir" >/dev/null 2>&1; then
    rm -rf "$dst_dir"
    cp -R "$src_dir" "$dst_dir"
    find "$dst_dir" -name '.DS_Store' -delete 2>/dev/null || true
    echo "[sync-skills] updated: $name"
    synced=$((synced + 1))
  fi
done < <(find "$REPO" -name SKILL.md -not -path '*/.git/*')

if [ "$synced" -eq 0 ]; then
  echo "[sync-skills] already up to date."
else
  echo "[sync-skills] $synced skill(s) synced from repo → ~/.claude/skills."
fi
