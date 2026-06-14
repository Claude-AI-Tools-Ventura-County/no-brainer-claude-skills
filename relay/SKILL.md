---
name: relay
description: Generate and run a relay thread file in `relay-system/<date>/<slug>.md` — a turn-based, file-based review loop between two Claude Code agents (a Producer who builds, a Reviewer who critiques and proposes fixes the author applies) so a human stops copy-pasting output between two windows. Use this whenever the user wants to "set up a relay", run a "producer/reviewer" or "worker/reviewer" loop, have "two agents" review each other's work in a shared file, "hand off" between agents without pasting, or cut copy-paste and stray artifacts across AI sessions. Also use it to START a relay (scaffold the dated file) or to TAKE A TURN in an existing one (read the file, act only on your turn, append your block, flip the pointer). Trigger even if the user only describes two Claude windows shuttling text back and forth.
---

# Relay

Two agents, one file, no copy-paste.

A relay is a turn-based review loop carried entirely inside a single Markdown file that both agents can read and append. One agent **builds** (Producer), the other **reviews and proposes** (Reviewer). They never message each other — they read the file, take their turn, and flip a pointer. The human's only job is to say "your turn" in the other window. The file is the shared bus, the change-log, and the decision record all at once.

This skill does two things: **start** a relay (scaffold the dated file from the template in the Appendix) and **take a turn** in an existing one. The **Producer always starts it** — the same step that creates the dated folder and file also writes turn 1. The Reviewer never creates the file; it only reads and appends.

**Honest caveat — independence is only as good as the second agent.** Two Claude sessions share a model and much of the same repo context, so they share blind spots: a same-model relay catches what a fresh pass with fresh framing catches, not what a truly independent reviewer would. For genuinely independent eyes, run a *different* model in the Reviewer window (e.g. Codex, or a different Claude tier). The file-based protocol is model-agnostic by design — any agent that can read and append the file can take a turn.

## When to use

- The user says "set up a relay", "start a relay", "run a producer/reviewer loop", "two-agent review", "have one agent review the other".
- The user is shuttling output between two Claude windows by hand and wants to stop.
- A piece of work needs an independent review pass and the user has a second Claude Code session available in the same repo.
- The user asks to take the next turn / continue a relay that already exists.

## The loop

```
Producer (build + request)  →  Reviewer (review + propose + verdict)
        ↑                                          │
        └──────  Producer (decide + implement)  ←──┘
```

One round = a Producer turn + a Reviewer turn. The relay ends when the Reviewer's verdict is **Approved**, or escalates to the human at the max round if it is still not Approved.

## File location

`relay-system/<YYYY-MM-DD>/<slug>.md`

- One folder per day; multiple relays per day live side by side, each with its own slug.
- Slug = short, lowercase, hyphenated topic — derive it from the artifact filename when obvious (`detect_abuse.py` → `detect-abuse`), otherwise ask the user for a 2–4 word topic.
- If today's target path already exists, derive a unique sibling (`<slug>-2`, `<slug>-3`, ...) instead of overwriting the earlier relay.
- `relay-system/` is local working scratch, not the artifact. Whether to track or `.gitignore` it is the operator's call: gitignore it to keep history quiet (recommended for public repos), or track it in a private repo if you want the relay thread in history. Either way, both agents always read it on disk in the same worktree — only the **artifact** must stay git-tracked, since ground rule 8's `git diff` handoff runs against the artifact, not this log.

---

## Mode 1 — Start a relay (Producer only)

1. Gather three things (pull from context first; ask only what's missing): the **artifact under review** (a local path — or a PR, in which case **check the branch out locally first**, since the direct-edit and `git diff` mechanics assume the artifact is in the shared working tree), a one-line **Definition of Done**, and a **slug**.
2. Get today's date and create `relay-system/<date>/` if it doesn't exist (this also creates `relay-system/` on first ever use).
3. If `relay-system/<date>/<slug>.md` already exists, pick the next unused `-2`, `-3`, ... suffix instead of overwriting it.
4. Write `relay-system/<date>/<slug>.md` using the template in the **Appendix** below. Fill `<TITLE>`, the Setup fields, and `Started`. Leave `NEXT: Producer`, `STATUS: Open`, `ROUND: 1 / 5`.
5. Take Round 1 immediately (Mode 2) — you're the Producer and you have the request. Folder, file, and turn 1 are all one step.
6. Commit, then tell the user the path and to carry it to window B with: *"take the Reviewer turn on `<path>`."*

If the user asks to take a turn but the file doesn't exist yet, you're in this mode — scaffold first.

## Mode 2 — Take a turn

1. **Read the whole file.** Setup, ground rules, and every prior turn.
2. **Check it's your turn.** The user tells you your role ("act as the Reviewer"). If `NEXT` ≠ your role, reply `Not my turn — NEXT is <role>.` and stop. Do not write anything.
3. **Do your role's work:**
   - **Producer:** build or update the artifact, then write your block. On later rounds, decide every Reviewer proposal *with the operator* — implement, modify, or decline — and log each disposition before adding new work.
   - **Reviewer:** review against the Definition of Done. **Do not edit the artifact** — it isn't yours to change. Write each issue as a graded finding, attaching a concrete suggested fix wherever you can (so the Producer can apply it in one step). Set a verdict.
4. **Append your block** at the bottom, directly above the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; bump `ROUND` when a Producer opens a new cycle; set `STATUS` (`Approved` ends the relay; `Escalated` if the max `ROUND` ends without `Approved`).
6. **Commit your turn:** `relay(<slug>): <role> r<N>`, then fill the hash into your block's `Commit:` line. This is what lets the operator `git diff` exactly which proposals the Producer implemented — the safety net behind every applied change. A **Reviewer turn never changes the artifact**: if the relay log is gitignored (the common case) it writes `Commit: none (comments only)`; if the log is *tracked*, the Reviewer still commits the log (rule 9 — no uncommitted state across a handoff) and records that hash. The Producer's turn carries the actual artifact diff — or `Commit: none (comments only)` if it too touched no tracked files.
7. **Hand off in one line.** Close your reply to the human with who goes next, e.g. *"Round 2 Reviewer done — Changes requested, 1 Blocker. Tell the Producer to take its turn."* The human nudges; they never paste.

### Turn block formats

Append exactly one of these per turn.

**Reviewer:**
```
### Round N · Reviewer · <timestamp>
**Verdict:** Approved | Changes requested | Blocked
**Findings & proposals:** (I propose; I do not edit the artifact)
- [Blocker] <finding @ file:line> — Proposed fix: <concrete suggested edit, or "author's call">
- [Should] <finding> — Proposed fix: <…>
- [Nit] <finding> — Proposed fix: <…>
  (or "none — approved as-is")
**Commit:** <log hash if this log is tracked, else "none (comments only)"> — the Reviewer never edits the artifact
```

**Verdict semantics.** `Changes requested` and `Blocked` keep the relay open for a Producer turn to dispose of the proposals; `Approved` **closes** it. So a Reviewer that wants its proposals actioned *in-thread* must set `Changes requested`, not `Approved` — any `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band after the relay closes.

**Producer (rounds 2+):**
```
### Round N · Producer · <timestamp>
**Decisions on proposals:** (operator-approved)
- [Blocker] <quote/ref> — Implemented → <what I changed @ file:line> | Modified → <what & why> | Declined → <one-line rationale>
- [Should] <quote/ref> — Implemented | Modified | Declined + why
**Did:** <further changes>
**Re-review this:** <what changed / where to look>
**Commit:** <hash or "none (comments only)">
```

(The Round 1 Producer block ships pre-stubbed in the template.)

## Guardrails

- **Never act out of turn**, and never edit a prior turn. The header pointer and the marker are load-bearing — respect them. (The one exception: immediately after committing, you may fill in your *own* just-written turn's `Commit:` line with the hash. Nothing else in a prior block is ever touched.)
- **Only one window acts at a time — the pointer is honor-system, not a lock.** Both windows share one working tree. The human serializes by nudging one window at a time; never start a turn while the other window may still be mid-edit, or the shared file and tree can be clobbered.
- **Clean tree at every handoff.** Before you flip `NEXT`, commit (or stash) all your changes — never hand off with uncommitted edits sitting in the working tree. A dirty tree means the next agent reads your half-finished state as if it were the artifact.
- **Smallest change that satisfies the finding.** A proposal — and the fix that implements it — is the narrowest change that resolves the finding; don't rewrite the artifact wholesale.
- **Only the author writes.** The Reviewer never edits the artifact — it proposes, and the Producer (the original author), with the operator, implements. Every change flows through one consistent hand, and the independent check stays independent: the reviewer never grades its own edits.
- **No proposal left undecided.** On its turn the Producer logs a disposition — Implemented / Modified / Declined (+ reason) — for every proposal before adding new work. A Declined Blocker is contested, not skipped (see below).
- **No ignored Blockers.** The Producer resolves or explicitly contests each one — never skips it.
- **Don't loop forever.** If the same Blocker is contested twice, escalate to the human rather than ping-pong. Honor the max round.
- **Assume nothing is shared.** The two agents have separate memory; if a decision matters, it goes in the file.

## Hands-free handoff (opt-in, all-Claude only)

By default the human serializes the relay with a one-line "your turn" nudge — and that nudge is the **lock**: it guarantees the previous turn is committed before the next begins. You can automate the nudge away **only when both windows are Claude Code sessions**, by replacing it with a *guarded poll* — each window watches the file and takes its turn the moment it's genuinely ready, never on a clock.

**Why not a fixed timer.** A "fire in N minutes" timer swaps a readiness *condition* for a guess: too short and the next turn fires on a half-finished, uncommitted tree (the clobber rule 9 exists to prevent); too long and you waited for nothing. The trigger you want is "it's my turn and the tree is clean," not "N minutes elapsed."

**The guard (non-negotiable).** A polling window takes its turn only when **both** hold:
1. `NEXT` names its role, **and**
2. the working tree is clean — the other window has already committed (`git status --porcelain` shows nothing for the artifact).

If either is false it does nothing and waits for the next tick. The *condition* is now the lock, so "one window at a time" still holds — and the order is unchanged: do the work → commit → flip `NEXT`, so a poller never sees `NEXT` flip before the commit lands.

**Setup.** Opt in at relay start by running a guarded `/loop` in each Claude window:
```
# Reviewer window
/loop 60s take the Reviewer turn on relay-system/<date>/<slug>.md ONLY if NEXT is Reviewer and the tree is clean; otherwise do nothing and wait
# Producer window
/loop 60s take the Producer turn on relay-system/<date>/<slug>.md ONLY if NEXT is Producer and the tree is clean; otherwise do nothing and wait
```
Record the mode in the file so each window knows it's live — set Setup's `Handoff:` to `hands-free poll (all-Claude)`. A short interval (≈60s) keeps the prompt cache warm; the other window's edits aren't harness-tracked, so polling is the correct way to notice them.

**Stop conditions.** A polling window stops when `STATUS` is `Approved` or `Escalated`, or after a bounded number of idle ticks with no change — then it escalates to the human rather than spinning forever. Honor the max `ROUND` exactly as in manual mode.

**Stays manual when** any window is a non-Claude tool (Codex, Gemini, …): they have their own schedulers or none and can't be driven this way, so cross-tool relays keep the human nudge. Hands-free is an accelerator for the all-Claude case — never the default, because the default has to stay tool-agnostic and human-locked.

## Framing

Don't just silently edit files. Open each turn with a short conversational line to the human ("Taking the Reviewer turn — reviewing `evidence.py` against the DoD…") and close with the hand-off nudge. The structured block lives in the file; the human gets a human sentence.

## What success looks like

The human's entire role collapses to two actions: *"start a relay"* and *"your turn."* No text shuttled between windows, no extra notes outside the relay thread, no lost context — just one dated, git-diffable Markdown file holding the full review thread and every decision, ending cleanly on **Approved** or a clear escalation.

---

## Appendix — relay thread template

Write this verbatim to `relay-system/<date>/<slug>.md` when starting a relay, filling the `<…>` fields. Newest turns append at the **bottom**, above the marker; the header and ground rules stay pinned at the top.

```markdown
# RELAY · <TITLE>
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 5

## Setup
- Artifact under review: <PATH or PR URL>
- Definition of Done: <ONE LINE — the bar the Reviewer checks against>
- Producer: <name/agent>   ·   Reviewer: <name/agent>
- Handoff: manual nudge   <!-- or "hands-free poll (all-Claude)" — see skill -->
- Started: <YYYY-MM-DD>

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (the original author), with the operator, decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(<slug>): <role> r<N>`, then fill the hash into your `Commit:` line — so the other agent can `git diff` exactly what changed. If your turn touched no tracked files (comments-only, or this log is gitignored), write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first, so the next agent never inherits half-finished state.

## Roles
- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · <YYYY-MM-DD HH:MM TZ>
**Did:** <what you built/changed — 1–3 bullets>
**Review this:** <specific focus areas / what to scrutinize>
**Open questions:** <or "none">
**Commit:** <hash or "none (comments only)">

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
```
