# Utils

Miscellaneous skills that live in this repo but are **not part of the Giant Brains suite**. The top-level skills form a curated arc (decide well, then improve verifiably); everything here is standalone tooling -- harness configuration, workflow conveniences, one-off helpers -- with no claim to that narrative.

Each subfolder is a normal skill (a directory containing `SKILL.md`) and installs the same way: symlink or copy it into `~/.claude/skills/`.

## Skills

- **read-only** -- Add a curated set of read-only permission rules (file reads, directory listings, grep/glob search, git inspection, system/environment checks) to a Claude Code `settings.json` allowlist, so safe reads stop triggering permission prompts. Uses exact-match rules where flags can mutate (`git branch -d`, `find -delete`) and excludes trivially write-capable commands (`echo`, `sed`, `tee`, `xargs`).
