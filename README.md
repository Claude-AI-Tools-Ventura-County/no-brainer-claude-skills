# Giant Brains Claude Skills

A small suite of decision-hygiene skills for [Claude Code](https://claude.com/claude-code). Each one fires at a different moment around a decision and forces the response into a short, scannable shape — so a human operator can act fast without missing what matters.

## The skills

| Skill | The operator's question | Its job |
|---|---|---|
| [take-a-step-back](take-a-step-back/SKILL.md) | "Am I making the best decision possible?" | **Frame** — challenge the plan and the problem before committing |
| [iron-triangle](iron-triangle/SKILL.md) | "Which of speed, cost, or quality am I trading away?" | **Price** — make the implicit tradeoff explicit |
| [blast-radius](blast-radius/SKILL.md) | "How big is the path I chose, what breaks, how hard to undo?" | **Size** — measure cost and reversibility of a chosen path |
| [bottom-line](bottom-line/SKILL.md) | "There's too much here — what's the call?" | **Cut** — compress overload and analysis paralysis into a decision |

They **chain** along the life of a decision: **frame** it (should I, and is this the right problem?), **price** the tradeoff (which corner gives?), **size** the chosen path (how big, what breaks?), then **cut** to the bottom line when the analysis balloons. The same situation can touch all four precisely because they answer different questions at different moments.

## What they share

- **Short, structured output.** Every skill leads with the one line that must survive skimming, then adds only the fields that change the decision. Drop anything that doesn't; never pad the template.
- **A shared reversibility read.** Where it applies, the skills speak one vocabulary — **Easy / Costly / One-way door** — so a two-way door is treated differently from a commitment that is expensive to unwind. (Iron-triangle's version asks whether a sacrificed corner stays *contained* or *compounds*.)
- **No manufactured drama.** Accurate signal over constant alarm. If a change is small and reversible, they say so and get out of the way.

## Calibration — what good output looks like

Good output names the *one* thing that changes the call and ends with a move that reduces uncertainty. Example, from `take-a-step-back`:

> **Decision:** You're about to execute the 3-PR plan doc as written — cherry-picking and sequencing the PRs onto the drifted source branch.
>
> **Step-back check:**
> - **Most fragile assumption:** That the plan doc is still the right path now that the branch has drifted — it was written against a tree that no longer exists.
> - **Alternative frame:** This may not be a "merge the existing PRs" problem at all, but a "re-land the *ideas* as fresh work against current main" problem.
> - **Reversibility:** Costly — once the PRs are cherry-picked and merged in sequence, untangling them from main is real work.
>
> **Do next:** Diff each PR's *intent* against current main and decide per PR — cherry-pick as-is, or re-cut as new work. The plan doc is an input, not a destiny.

What makes it good:
- **One sharp counterpoint, not five.** It names the single fragile assumption instead of listing every possible risk.
- **It challenges the frame**, not just the option — the real question is "follow the plan, or re-cut?", not "how do I cherry-pick cleanly?".
- **Concrete, honest reversibility** — a specific cost, on the shared scale.
- **A do-next that reduces uncertainty** rather than describing it.

The inverse matters just as much: a good skill also knows when *not* to escalate. See `blast-radius`'s small-change example, where the right answer is "ship it, low risk" — calibration is as much about staying quiet as raising a flag.

## Installing

These are Claude Code Agent Skills. Put each skill directory where Claude Code looks for skills:

- **Personal (all your projects):** `~/.claude/skills/`
- **Project (shared with a repo):** `<project>/.claude/skills/`

Symlink them so a `git pull` keeps them current (run from the repo root):

```bash
mkdir -p "$HOME/.claude/skills"
for s in blast-radius bottom-line iron-triangle take-a-step-back; do
  ln -s "$PWD/$s" "$HOME/.claude/skills/$s"
done
```

Claude auto-invokes a skill when the request matches its `description`, or you can call it by name. Note: the entry file must be named exactly `SKILL.md` (uppercase) — the loader matches it case-sensitively even on case-insensitive macOS, so a lowercase `skill.md` is silently never discovered.

## Authoring conventions

Lessons baked into these files. Keep them if you add more skills:

- **Valid frontmatter on line 1.** The file must open with `---` and a YAML `name` + `description`, with no prose preamble and no ` ```yaml ` code fence wrapping it — otherwise the skill silently fails to load and never appears.
- **Entry file must be `SKILL.md`, exact case.** The loader matches it case-sensitively even on case-insensitive macOS, so a lowercase `skill.md` is silently skipped — and watch for git hiding a case-only rename when `core.ignorecase` is true.
- **ASCII punctuation.** Straight quotes and regular hyphens. Curly quotes and non-breaking hyphens (`‑`) look identical but break grep, copy, and matching. Em-dashes are fine.
- **Triggers live in the `description`.** That is the surface Claude matches against — keep it concrete and observable ("about to recommend a migration"), never circular ("fire when the change is major", which the skill can only know *after* running).
- **Examples calibrate behavior.** Include at least one counter-example where the skill correctly does *not* escalate — a small change, a cheap reversible call — or it will skew toward alarm.
- **Brevity is the product.** Each skill's output should be just enough meat that a human operator will actually read it.

## Layout

```
.
├── take-a-step-back/SKILL.md
├── iron-triangle/SKILL.md
├── blast-radius/SKILL.md
├── bottom-line/SKILL.md
└── README.md
```

## Sponsored by

This project is supported by two Southern California meetup communities:

- [Claude & AI Tools — Ventura County](https://www.meetup.com/claude-ai-tools-ventura-county/)
- [Love2SoCal — Vibe Coding Meetup](https://www.meetup.com/love2socal/)
