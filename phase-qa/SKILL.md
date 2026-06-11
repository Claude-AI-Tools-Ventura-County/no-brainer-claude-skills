---
name: phase-qa
description: >
  Project plan enhancement tool. Reads a phased planning doc and appends a QA checklist
  (DRY, SOLID, and phase-appropriate litmus tests) under each phase. Invoke before work
  begins to bake checks into the plan; invoke mid-project or post-project to also run
  code-diff reviews on completed phases. Always confirms with the user where they are in
  the process before writing anything. Gate enforcement is at the operator's discretion.
  Trigger: user invokes the skill directly, optionally naming phases to skip.
---

# Phase QA (Plan Enhancement)

This skill enhances a phased project plan by embedding a QA checklist under every phase
before work begins — so quality expectations are explicit from the start, not bolted on
at the end.

**Core idea:** each phase in the plan gets a QA Checklist block added to it at one
heading level deeper than the phase heading (e.g., `#### QA Checklist` when phases are
`###`). The checklist is always checkbox format (`- [ ]`), regardless of how the rest of
the plan doc is structured. Items get checked off as the phase's work is reviewed and
approved. Enforcement is the operator's call — the checklist is a structured record, not
a hard blocker.

## Invocation

The user invokes the skill directly, e.g.:

```
/phase-qa
/phase-qa skip phases 2, 4
/phase-qa phases 1-3 only
```

Any phases named as exceptions at invocation time are skipped entirely — no checklist
added, no review run.

## Step 1 — Confirm where the user is in the project

Before reading the plan or writing anything, ask:

> "Where are you in the project right now? (a) haven't started yet, (b) in progress —
> which phase are you on? (c) all phases complete."

**Linear-progress assumption:** unless the user says otherwise, treat the project as
linear — all phases before the current one are complete, the named phase is in progress,
all later phases are upcoming. If the user indicates a non-linear project (e.g., Phase 4
started before Phase 3 finished), ask for the status of each phase explicitly before
proceeding.

Do not skip this step — the same plan doc looks very different depending on where the
user stands.

## Step 2 — Find the plan doc

Locate the phased planning doc: the file the user names, or search for `PLAN.md`,
`ROADMAP.md`, `docs/plan*.md`, or any doc with phase headings. If multiple candidates
exist, ask the user which one. If no phased plan exists, tell the user plainly and
stop — this skill requires a plan doc to write to.

## Step 3 — Confirm classification before writing

After classifying each phase, show the user a summary before modifying anything:

> "Here's what I'll do:
> - Phases 1–2 (completed): run diff review and pre-fill checklists with findings
> - Phase 3 (in progress): add checklist, marked in progress
> - Phases 4–6 (upcoming): add blank checklists
> Proceed?"

Only write to the plan doc after the user confirms. This is the last chance to correct
a mis-classification or adjust phase scope before anything is changed.

## Step 4 — Determine status per phase

Based on the confirmed classification, apply the appropriate behavior per phase:

### Upcoming phases
Add a QA checklist block immediately after the phase heading or deliverables list. The
checklist contains:
- The six standard DRY/SOLID checks (always included)
- Two to four phase-specific litmus tests derived from what the phase is building

All items start unchecked (`- [ ]`). No code review — there is no code yet.

### In-progress phase
Treat the same as an upcoming phase: add the checklist if it isn't there yet. Mark the
header to show it is in progress: `#### QA Checklist *(in progress)*` (or one level
deeper than the phase heading, as above).

### Completed phases
Run a targeted diff review against the same DRY/SOLID and litmus-test items that will
appear in the checklist (this is not a general correctness or bug review — use
`/code-review` for that). Then add the checklist with items pre-filled:
- Items that passed the diff review → checked (`- [x]`) with a one-line note
- Items with findings → unchecked (`- [ ]`) with the finding described inline so the
  operator can act on it or waive it

To find the diff, prefer git markers (a tag like `phase-2-start`, a commit SHA, or a
date the user gives): `git diff <start>..<end> -- .`. If no markers exist, ask the user
for the range or a list of files the phase touched.

**If no diff can be obtained** (no markers and no file list available), add the checklist
with all items unchecked and a note at the top:
```
> Diff unavailable — manual review required before checking off items.
```

## The standard DRY/SOLID checks (always included)

These six items appear in every checklist, every phase:

```
- [ ] DRY: No rule, constant, or business logic duplicated across files changed in this phase
- [ ] S (Single Responsibility): Each new or changed unit has exactly one reason to change
- [ ] O (Open/Closed): New variants don't require editing existing switch/if chains or type lists
- [ ] L (Liskov): No subtype overrides a method to throw NotSupported or narrows the base contract
- [ ] I (Interface Segregation): No implementer forced to stub or no-op methods it doesn't use
- [ ] D (Dependency Inversion): High-level code depends on interfaces, not concrete classes or vendors
```

### Calibration — only flag real smells

- **DRY:** two occurrences are a coincidence; flag at three, or when the duplicated thing
  is a single source-of-truth rule that is dangerous to have in two places (auth check,
  tax rate, permission boundary).
- **SOLID:** flag only when the variation or extension it guards against already exists or
  is explicitly in the plan — not speculative future needs.
- **For completed-phase diff reviews only:** a finding must name a concrete `file:line`
  and explain how it gets more expensive if the phase ships over it. Drop anything that
  can't clear that bar. For upcoming and in-progress phases there is no code to cite —
  checklist items start unchecked with no findings attached.

## Phase-specific litmus tests

After the six standard items, add two to four checks tailored to what this phase is
actually building. Derive them from the phase's deliverables, not from a fixed template.
Examples by phase type:

| Phase type | Example litmus tests |
|---|---|
| Data / DB migration | Schema rollback tested; no data-destructive step runs without a dry-run flag |
| API / endpoints | Contract versioned or backward-compatible; error shapes consistent across routes |
| Auth / permissions | Least-privilege applied; no role check duplicated in caller and callee |
| UI / frontend | No business logic in the view layer; state mutations go through one path |
| Infra / config | Secrets not hardcoded; config values environment-scoped, not environment-named |
| Refactor | No behavior change in the diff; test coverage held or improved |
| Integration | Third-party calls go through an adapter, not direct SDK calls in domain code |

Choose the tests that match the phase. If a phase spans multiple types, combine.

If a phase description is too vague to derive meaningful litmus tests (e.g., only a
title with no deliverables), add this placeholder item and flag it inline:
```
- [ ] Acceptance criteria: Phase has a defined, testable acceptance criterion (define before closing)
```
Do not invent tests that may not apply — a placeholder that prompts the operator to
refine is more useful than a generic checklist that gets rubber-stamped.

## Checklist block format

Always insert the QA block after the phase's deliverables and before the next phase
heading. The heading level must be one level deeper than the phase heading — if phases
are `##`, use `###`; if phases are `###`, use `####`. When in doubt, inspect the plan's
heading structure before inserting.

```markdown
#### QA Checklist
<!-- phase-qa -->
- [ ] DRY: No rule, constant, or business logic duplicated across files changed in this phase
- [ ] S (Single Responsibility): Each new or changed unit has exactly one reason to change
- [ ] O (Open/Closed): New variants don't require editing existing switch/if chains or type lists
- [ ] L (Liskov): No subtype overrides a method to throw NotSupported or narrows the base contract
- [ ] I (Interface Segregation): No implementer forced to stub or no-op methods it doesn't use
- [ ] D (Dependency Inversion): High-level code depends on interfaces, not concrete classes or vendors
- [ ] [Phase-specific litmus test 1]
- [ ] [Phase-specific litmus test 2]
```

For a completed-phase diff review, pre-fill items:
```markdown
- [x] DRY: Clean — reviewed `git diff abc1234..def5678`, no duplicated rules found
- [ ] D (Dependency Inversion): `OrderService` news up `MySQLClient` directly in constructor — inject or waive
```

The `<!-- phase-qa -->` comment is the idempotency marker. If a block with that marker
already exists under a phase, do not add a second one — update it in place instead.

## Output destination

Always write to the same plan doc unless the user specifies otherwise at invocation.
Do not create a separate report file. Do not reformat or reorder any other content in
the doc — the only edits are inserting or updating the `### QA Checklist` blocks.

## Gate enforcement

This skill does not block or unblock phases. Enforcement is entirely at the operator's
discretion. The checklist is a structured record of what was agreed to review — the
operator checks items off as they validate the work, and can choose to ship with open
items by leaving them unchecked (or adding a `~~strikethrough~~ Waived: reason` note).

## When NOT to run

- **No phased plan doc exists.** Without a plan there is nothing to write to — stop and
  tell the user.
- **Docs-only, config-only, or spike phases explicitly excluded by the user.** If the
  user names a phase to skip at invocation, skip it with no checklist added.
- **Mid-phase general review.** If the user wants a line-by-line bug or correctness
  review, that is `/code-review`. For completed phases this skill does run a targeted diff
  review, but only to populate checklist items against the DRY/SOLID and litmus-test
  rubric — it does not surface general bugs or style issues.
