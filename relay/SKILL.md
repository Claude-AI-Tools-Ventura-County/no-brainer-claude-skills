---
name: relay
description: Generate and run a RELAY.md — a turn-based, file-based review loop between two Claude Code agents (a Producer who builds, a Reviewer who critiques and fixes directly) so a human stops copy-pasting output between two windows. Use this whenever the user wants to "set up a relay", run a "producer/reviewer" or "worker/reviewer" loop, have "two agents" review each other's work in a shared file, "hand off" between agents without pasting, or cut copy-paste and stray artifacts across AI sessions. Also use it to START a relay (scaffold the dated file) or to TAKE A TURN in an existing one (read the file, act only on your turn, append your block, flip the pointer). Trigger even if the user only describes two Claude windows shuttling text back and forth.
---

# Relay

Two agents, one file, no copy-paste.

A relay is a turn-based review loop carried entirely inside a single Markdown file that both agents can read and append. One agent **builds** (Producer), the other **reviews and fixes** (Reviewer). They never message each other — they read the file, take their turn, and flip a pointer. The human's only job is to say "your turn" in the other window. The file is the shared bus, the change-log, and the decision record all at once.

This skill does two things: **start** a relay (scaffold the dated file from the template in the Appendix) and **take a turn** in an existing one. The **Producer always starts it** — the same step that creates the dated folder and file also writes turn 1. The Reviewer never creates the file; it only reads and appends.

**Honest caveat — independence is only as good as the second agent.** Two Claude sessions share a model and much of the same repo context, so they share blind spots: a same-model relay catches what a fresh pass with fresh framing catches, not what a truly independent reviewer would. For genuinely independent eyes, run a *different* model in the Reviewer window (e.g. Codex, or a different Claude tier). The file-based protocol is model-agnostic by design — any agent that can read and append the file can take a turn.

## When to use

- The user says "set up a relay", "start a relay", "run a producer/reviewer loop", "two-agent review", "have one agent review the other".
- The user is shuttling output between two Claude windows by hand and wants to stop.
- A piece of work needs an independent review pass and the user has a second Claude Code session available in the same repo.
- The user asks to take the next turn / continue a relay that already exists.

## The loop

```
Producer (build + request)  →  Reviewer (review, fix directly, verdict)
        ↑                                          │
        └──────  Producer (respond + update)  ←────┘
```

One round = a Producer turn + a Reviewer turn. The relay ends when the Reviewer's verdict is **Approved**, or escalates to the human if a Blocker is still open at the max round.

## File location

`relay-system/<YYYY-MM-DD>/<slug>.md`

- One folder per day; multiple relays per day live side by side, each with its own slug.
- Slug = short, lowercase, hyphenated topic — derive it from the artifact filename when obvious (`detect_abuse.py` → `detect-abuse`), otherwise ask the user for a 2–4 word topic.
- `relay-system/` is local working scratch, not the artifact. Whether to track or `.gitignore` it is the operator's call: gitignore it to keep history quiet (recommended for public repos), or track it in a private repo if you want the relay thread in history. Either way, both agents always read it on disk in the same worktree — only the **artifact** must stay git-tracked, since ground rule 8's `git diff` handoff runs against the artifact, not this log.

---

## Mode 1 — Start a relay (Producer only)

1. Gather three things (pull from context first; ask only what's missing): the **artifact under review** (a local path — or a PR, in which case **check the branch out locally first**, since the direct-edit and `git diff` mechanics assume the artifact is in the shared working tree), a one-line **Definition of Done**, and a **slug**.
2. Get today's date and create `relay-system/<date>/` if it doesn't exist (this also creates `relay-system/` on first ever use).
3. Write `relay-system/<date>/<slug>.md` using the template in the **Appendix** below. Fill `<TITLE>`, the Setup fields, and `Started`. Leave `NEXT: Producer`, `STATUS: Open`, `ROUND: 1 / 5`.
4. Take Round 1 immediately (Mode 2) — you're the Producer and you have the request. Folder, file, and turn 1 are all one step.
5. Commit, then tell the user the path and to carry it to window B with: *"take the Reviewer turn on `<path>`."*

If the user asks to take a turn but the file doesn't exist yet, you're in this mode — scaffold first.

## Mode 2 — Take a turn

1. **Read the whole file.** Setup, ground rules, and every prior turn.
2. **Check it's your turn.** The user tells you your role ("act as the Reviewer"). If `NEXT` ≠ your role, reply `Not my turn — NEXT is <role>.` and stop. Do not write anything.
3. **Do your role's work:**
   - **Producer:** build or update the artifact, then write your block. On later rounds, respond to every finding before adding new work.
   - **Reviewer:** review against the Definition of Done. Make the direct edits you're confident in and log each one. Leave judgment calls as findings for the Producer. Set a verdict.
4. **Append your block** at the bottom, directly above the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; bump `ROUND` when a Producer opens a new cycle; set `STATUS` (`Approved` ends the relay; `Escalated` if a Blocker is unresolved at the max round).
6. **Commit your turn:** `relay(<slug>): <role> r<N>`, then fill the hash into your block's `Commit:` line. This is what lets the other agent `git diff` exactly what you did — the safety net for the Reviewer's direct edits. If your turn changed no tracked files — a comments-only review, or the log itself is gitignored — there's nothing to commit; write `Commit: none (comments only)` and rely on the file on disk, which the other window reads directly.
7. **Hand off in one line.** Close your reply to the human with who goes next, e.g. *"Round 2 Reviewer done — Changes requested, 1 Blocker. Tell the Producer to take its turn."* The human nudges; they never paste.

### Turn block formats

Append exactly one of these per turn.

**Reviewer:**
```
### Round N · Reviewer · <timestamp>
**Verdict:** Approved | Changes requested | Blocked
**Edits I made:**
- <file:line> — <what> — <why>
  (or "none — comments only this round")
**Findings for Producer:**
- [Blocker] <…>
- [Should] <…>
- [Nit] <…>
**Commit:** <hash>
```

**Producer (rounds 2+):**
```
### Round N · Producer · <timestamp>
**Responses to findings:**
- [Blocker] <quote/ref> — Accepted → <did X> | Contested → <one-line rationale>
- [Should] <quote/ref> — <action or skip + why>
**Did:** <further changes>
**Re-review this:** <what changed / where to look>
**Commit:** <hash>
```

(The Round 1 Producer block ships pre-stubbed in the template.)

## Guardrails

- **Never act out of turn**, and never edit a prior turn. The header pointer and the marker are load-bearing — respect them. (The one exception: immediately after committing, you may fill in your *own* just-written turn's `Commit:` line with the hash. Nothing else in a prior block is ever touched.)
- **Only one window acts at a time — the pointer is honor-system, not a lock.** Both windows share one working tree. The human serializes by nudging one window at a time; never start a turn while the other window may still be mid-edit, or the shared file and tree can be clobbered.
- **Clean tree at every handoff.** Before you flip `NEXT`, commit (or stash) all your changes — never hand off with uncommitted edits sitting in the working tree. A dirty tree means the next agent reads your half-finished state as if it were the artifact.
- **Smallest change that satisfies the finding.** Don't rewrite the artifact wholesale; the Reviewer fixes, it doesn't rebuild.
- **No silent edits.** Every direct change the Reviewer makes gets a log line (file · what · why), so the Producer can see it without spelunking.
- **No ignored Blockers.** The Producer resolves or explicitly contests each one — never skips it.
- **Don't loop forever.** If the same Blocker is contested twice, escalate to the human rather than ping-pong. Honor the max round.
- **Assume nothing is shared.** The two agents have separate memory; if a decision matters, it goes in the file.

## Framing

Don't just silently edit files. Open each turn with a short conversational line to the human ("Taking the Reviewer turn — reviewing `evidence.py` against the DoD…") and close with the hand-off nudge. The structured block lives in the file; the human gets a human sentence.

## What success looks like

The human's entire role collapses to two actions: *"start a relay"* and *"your turn."* No text shuttled between windows, no scratch files, no lost context — just one dated, git-diffable Markdown file holding the full review thread and every decision, ending cleanly on **Approved** or a clear escalation.

---

## Appendix — RELAY.md template

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
- Started: <YYYY-MM-DD>

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. The Reviewer edits the artifact directly for fixes it's confident in, and logs every edit (file · what · why). The Producer may keep, change, or revert each — with a one-line reason.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved**. A Blocker still open at the max `ROUND` → set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(<slug>): <role> r<N>`, then fill the hash into your `Commit:` line — so the other agent can `git diff` exactly what changed. If your turn touched no tracked files (comments-only, or this log is gitignored), write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first, so the next agent never inherits half-finished state.

## Roles
- **Producer** — builds/edits the artifact, requests review, responds to findings, updates.
- **Reviewer** — reviews against the DoD, fixes directly, reports what it changed, sets a verdict.

---
## Log

### Round 1 · Producer · <YYYY-MM-DD HH:MM TZ>
**Did:** <what you built/changed — 1–3 bullets>
**Review this:** <specific focus areas / what to scrutinize>
**Open questions:** <or "none">
**Commit:** <hash or "uncommitted">

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
```
