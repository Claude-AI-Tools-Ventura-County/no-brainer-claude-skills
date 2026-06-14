# RELAY · detect_abuse.py evidence-grade retrofit
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 5

## Setup
- Artifact under review: `scripts/detect_abuse.py`
- Definition of Done: every emitted finding carries a FACT / PATTERN / HYPOTHESIS grade, enforced in-script — no central orchestration.
- Producer: Claude Code (window A)   ·   Reviewer: Claude Code (window B)
- Started: 2026-06-13

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top.
4. Stay tight. Requests and findings are bullets, not essays.
5. The Reviewer edits the artifact directly for fixes it's confident in, and logs every edit (file · what · why). The Producer may keep, change, or revert each — with a one-line reason.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved**. A Blocker still open at the max `ROUND` → set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(<slug>): <role> r<N>` — so the other agent can `git diff` exactly what changed.

## Roles
- **Producer** — builds/edits the artifact, requests review, responds to findings, updates.
- **Reviewer** — reviews against the DoD, fixes directly, reports what it changed, sets a verdict.

---
## Log

### Round 1 · Producer · 2026-06-13 09:14 PT
**Did:**
- Imported `Grade` from `evidence.py`; wrapped all three abuse signals as `Finding(grade=...)`.
- Velocity spike → PATTERN; known-bad fingerprint match → FACT; shared-device cluster → HYPOTHESIS.
**Review this:** Are the grade assignments defensible against June 8 logs? Anything emitting an ungraded dict still?
**Open questions:** Is shared-device really HYPOTHESIS or should clustering confidence bump it to PATTERN?
**Commit:** a91c44e

### Round 1 · Reviewer · 2026-06-13 10:02 PT
**Verdict:** Changes requested
**Edits I made:**
- `detect_abuse.py:148` — wrapped the legacy `chargeback_ratio` emit in `Finding(grade=Grade.PATTERN)` — it was still returning a bare dict, which fails the DoD. — direct fix, low risk.
**Findings for Producer:**
- [Blocker] `fingerprint match → FACT` (line 96): the match is fuzzy (Levenshtein ≤ 2), not exact. A near-match isn't a FACT. Downgrade to PATTERN or tighten to exact-match before claiming FACT.
- [Should] Shared-device HYPOTHESIS is correct as-is — clustering confidence is associative, not causal. Keep it HYPOTHESIS; don't bump.
- [Nit] Grade import is unsorted relative to the rest of the `evidence` imports.
**Commit:** c30f8b1

### Round 2 · Producer · 2026-06-13 10:41 PT
**Responses to findings:**
- [Blocker] fuzzy-match → FACT — **Contested →** the ≤2 threshold only fires on hash-normalized device IDs where 2 chars is a casing/encoding artifact, not a different device; I read this as still FACT-grade. Proposing we keep FACT but add an inline comment documenting the normalization. Flagging for your call.
- [Should] shared-device — Accepted, kept as HYPOTHESIS.
- [Nit] Accepted → sorted the `evidence` imports.
**Did:** Kept your `chargeback_ratio` fix. Added the normalization comment at line 96.
**Re-review this:** Just the line-96 FACT/PATTERN call — does the normalization argument hold, or do you still want PATTERN?
**Commit:** 7e1d220

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
