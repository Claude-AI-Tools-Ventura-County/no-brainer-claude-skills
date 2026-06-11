---
name: phase-gate
description: >
  The phase-exit quality gate. Before a planned phase is marked closed, review the
  CODE that phase produced against a DRY and SOLID checklist; block closure on real
  violations, allow each to be cleared or waived with a one-line recorded reason, and
  stamp the planning doc closed only when the gate passes. Fire when the user signals a
  phase boundary: "close phase 2," "is this phase done," "mark the phase complete,"
  "wrap up this phase," "phase exit checklist," "DRY/SOLID review before closing," or
  finishes the last deliverable a plan lists for the current phase. Skip mid-phase, on
  docs-only or config-only phases, and when there is no phased plan to gate against; for
  a general line-by-line bug review use code-review instead, not this.
---

# Phase Gate

A planned phase does not close until the code it produced clears a DRY (Don't Repeat Yourself) and SOLID checklist. Here, SOLID is applied as six concrete design checks, not as a cue for textbook architecture lectures. Catch the design debt at the boundary, where it is still **Easy** to fix — the same duplication or inverted dependency, once shipped and built upon by the next phase, becomes **Costly** to undo.

The gate has one job: turn "I think the phase is done" into a pass/fail verdict you can defend, with a recorded reason for anything you chose to ship anyway.

## Output format

Lead with the verdict. Then only the findings that block, the waiver line, and the stamp action. A clean phase is a one-line PASS plus the stamp — never pad the checklist with principles that found nothing.

**Verdict:** [✅ PASS — clearing the gate / ⛔ BLOCKED — N open findings] — [one line: the single worst finding, or "no DRY/SOLID violations in the phase diff."]

**Scope reviewed:** [what code the gate looked at — e.g. `git diff phase-1-start..HEAD`, 12 files, or the phase's listed deliverables.]

**Findings:** [only if any — numbered, one line each, grouped under DRY / SOLID. Each names the file:line, the smell, and the fix. Omit the whole section on a clean pass.]

**Waivers:** [only if any accepted — each finding the user chose to ship, with its one-line justification.]

**Do next:** [⛔ → the cheapest path to green: fix list or waive. ✅ → "Stamped phase N closed in `PLAN.md`."]

## The checklist

Six checks. Each is a question about the phase's diff, with the smell that answers it "fail." Apply them to the code the phase *changed*, not the whole repo.

**DRY — is the same knowledge expressed in more than one place?** Not "do two lines look alike" — does one *rule* (a validation, a constant, a business calculation) live in two spots so that changing it means remembering to change both? *Smell:* the phase pasted the same tax/permission/format logic into a second handler.

**S — Single Responsibility: does each unit have one reason to change?** A function or class that parses *and* validates *and* persists has three. *Smell:* a new method that, if the DB schema changes OR the wire format changes OR the business rule changes, all force an edit to the same body.

**O — Open/Closed: can a new variant be added without editing existing code?** *Smell:* the phase added a case to a `switch (type)` that a reader knows will be edited again for every future type — instead of a registered handler or polymorphic call.

**L — Liskov: can every subtype stand in for its base without surprising the caller?** *Smell:* a subclass overrides a method to throw `NotSupported`, or narrows what the base promised, so callers must type-check before using it.

**I — Interface Segregation: are implementers forced to depend on methods they don't use?** *Smell:* the phase added a fat interface and the new implementer stubs half its methods with `throw`/`return null`.

**D — Dependency Inversion: does high-level code depend on abstractions, not concretions?** *Smell:* a service `new`s up a concrete `MySQLClient`/`StripeApi` in its constructor instead of receiving an injected interface — untestable and welded to one vendor. *This is the one that turns Costly fastest:* once three phases depend on the concrete wiring, inverting it is a cross-cutting change.

## Calibration — the gate stays quiet unless the smell is real

DRY and SOLID are heuristics, not laws, and a checker that fires on every repeat is noise that trains people to ignore it (AGENTS.md #8). Hold each finding to this bar before it blocks:

- **Rule of three for DRY.** Two occurrences are not a violation — they are a coincidence. Flag duplication only at the third, or when the duplicated thing is a single source-of-truth rule (a tax rate, an auth check) that is *dangerous* to have in two places even twice. Premature abstraction is its own smell; do not force a shared helper onto two callers that may diverge.
- **No speculative SOLID.** "This might need to be extensible someday" is not Open/Closed — it is a guess about the future you are paying for now. Flag a violation only when the variation it guards against already exists or is in the plan.
- **Severity, not count.** One real Dependency-Inversion violation that the next phase will build on outranks ten cosmetic ones. Lead the verdict with the finding that gets *more expensive* if the phase closes over it, not the longest list.

A finding that can't name a concrete file:line and a concrete way it bites later is not a finding — drop it. Refuse to manufacture violations to look thorough.

## Running the gate

1. **Find the phase's code.** Prefer git: the phase's start point (a tag like `phase-2-start`, the commit where the phase began, or a date the user gives) to `HEAD` — `git diff <start>..HEAD --name-only`. If there's no marker, ask for the start ref or fall back to reviewing the deliverables the plan lists for this phase. Review the *diff*, not the repository.
2. **Find the plan.** Locate the phased planning doc — the file the user names, or a `PLAN.md` / `ROADMAP.md` / `docs/plan*` with phase headings. If there is no phased plan, run the checklist and report the verdict, but say plainly there's nothing to stamp — don't invent a plan file.
3. **Run the six checks** against the diff, applying the calibration bar. Produce the verdict and any findings.
4. **Resolve each finding** — fixed or waived. The phase closes only when the open count hits zero.

## The waiver path — block, but don't stall

A hard gate that can't be overridden gets disabled. Each finding can be **waived** instead of fixed, on one condition: a recorded one-line justification of why shipping it is the right call (deadline, the abstraction is genuinely premature, the duplication is intentional and noted). Record the waiver where the phase lives — a `Waived:` line under the stamped phase — so the exception travels with the work and the next phase sees it.

Escalation: if a waiver is for an architectural violation that is **Costly or a One-way door** to reverse later (a Dependency-Inversion or Open/Closed call the rest of the system will build on), don't bury it in a one-liner — hand off to **record-decision** so the bet, its expected signal, and a revisit trigger are written down. A cosmetic DRY waiver stays inline; an architectural one becomes a decision record.

## Stamping the plan

On PASS (or all findings waived), mark the phase closed in the planning doc — match the structure that's already there:

- A checkbox list → flip `- [ ] Phase 2: …` to `- [x]`.
- A status line → set `Status: Closed — DRY/SOLID gate passed <date>`.
- Neither → append one line under the phase heading: `> Closed <date> — phase-gate passed (N waived).`

Stamp only on a genuine pass. Never mark a phase closed with open, un-waived findings to make the doc look finished — a falsely-green plan is worse than an honestly-open one (AGENTS.md #6). The stamp is the *only* write this skill makes to the plan; don't reformat or reorder the rest of the doc.

## When NOT to fire

- **Mid-phase.** This is a boundary gate, not a running linter. If the phase isn't claiming to be done, stay silent.
- **Docs-only, config-only, or spike phases.** A phase that bumped a dependency, edited copy, or built a throwaway prototype has no DRY/SOLID surface worth gating — say "nothing to gate here, closing" and stamp, rather than forcing the checklist.
- **General code review.** "Find bugs in this" or "review my diff for correctness" is **code-review**'s job — phase-gate only asks the six design questions at a phase boundary, and only blocks on those.
- **No phased plan exists.** Without phases there's no boundary to gate; offer a plain DRY/SOLID read if asked, but don't pretend to close anything.
