# No-Brainer Claude Skills

A small suite of decision-hygiene skills for [Claude Code](https://claude.com/claude-code). Each one fires at a different moment around a decision and forces the response into a short, scannable shape — so a human operator can act fast without missing what matters.

## The skills

| Skill | The operator's question | Fires |
|---|---|---|
| [take-a-step-back](take-a-step-back/skill.md) | "Am I making the best decision possible?" | **before** committing — challenge the plan and the framing |
| [blast-radius](blast-radius/skill.md) | "If I do this, how big is it, what breaks, how hard to undo?" | **during** — size a path you have chosen |
| [bottom-line](bottom-line/skill.md) | "There's too much here — what's the call?" | **after** — compress overload and analysis paralysis into a decision |

Before / during / after. They **chain**: step back to pick the approach, size it with blast-radius, then cut to the bottom line if the analysis balloons. The same situation can touch all three precisely because they answer different questions at different moments.

## What they share

- **Short, structured output.** Every skill leads with the one line that must survive skimming, then adds only the fields that change the decision. Drop anything that doesn't; never pad the template.
- **One reversibility vocabulary** — **Easy / Costly / One-way door** — so a two-way door is treated differently from a commitment that is expensive to unwind.
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
for s in blast-radius bottom-line take-a-step-back; do
  ln -s "$PWD/$s" "$HOME/.claude/skills/$s"
done
```

Claude auto-invokes a skill when the request matches its `description`, or you can call it by name. Note: Claude Code's skill entry file is conventionally `SKILL.md`; these use `skill.md` — rename if your Claude Code version requires uppercase.

## Authoring conventions

Lessons baked into these files. Keep them if you add more skills:

- **Valid frontmatter on line 1.** The file must open with `---` and a YAML `name` + `description`, with no prose preamble and no ` ```yaml ` code fence wrapping it — otherwise the skill silently fails to load and never appears.
- **ASCII punctuation.** Straight quotes and regular hyphens. Curly quotes and non-breaking hyphens (`‑`) look identical but break grep, copy, and matching. Em-dashes are fine.
- **Triggers live in the `description`.** That is the surface Claude matches against — keep it concrete and observable ("about to recommend a migration"), never circular ("fire when the change is major", which the skill can only know *after* running).
- **Examples calibrate behavior.** Include at least one counter-example where the skill correctly does *not* escalate — a small change, a cheap reversible call — or it will skew toward alarm.
- **Brevity is the product.** Each skill's output should be just enough meat that a human operator will actually read it.

## Layout

```
.
├── take-a-step-back/skill.md
├── blast-radius/skill.md
├── bottom-line/skill.md
└── README.md
```
