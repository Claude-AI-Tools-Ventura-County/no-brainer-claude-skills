# Utils

Miscellaneous skills that live in this repo but are **not part of the Giant Brains suite**. The top-level skills form a curated arc (decide well, then improve verifiably); everything here is standalone tooling -- harness configuration, workflow conveniences, one-off helpers -- with no claim to that narrative.

Each skill subfolder is a normal skill (a directory containing `SKILL.md`) and installs the same way: symlink or copy it into `~/.claude/skills/`. Subfolders without a `SKILL.md` are docs or kits, not skills -- the skills sync ignores them.

## Skills

- **read-only** -- Add a curated set of read-only permission rules (file reads, directory listings, grep/glob search, git inspection, system/environment checks) to a Claude Code `settings.json` allowlist, so safe reads stop triggering permission prompts. Uses exact-match rules where flags can mutate (`git branch -d`, `find -delete`) and excludes trivially write-capable commands (`echo`, `sed`, `tee`, `xargs`).

## Docs & kits

- **claude-code-dotfiles-fork** -- Standalone kit for syncing `~/.claude` across machines via a private git repo and Claude Code SessionStart/SessionEnd hooks, with optional propagation of a skills repo as real files. Self-contained: [INSTALL.md](claude-code-dotfiles-fork/INSTALL.md) is the machine-agnostic setup guide, [templates/](claude-code-dotfiles-fork/templates/) holds the allowlist `.gitignore`, the three hook scripts, and the settings hooks snippet, [HANDOFF.md](claude-code-dotfiles-fork/HANDOFF.md) documents the maintainer's live deployment, and [README.md](claude-code-dotfiles-fork/README.md) is the upstream project's original documentation (MIT-0 fork of `elizabethfuentes12/claude-code-dotfiles`).
