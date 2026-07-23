# 020 — Self-improvement loop dogfoods the repo's own dev process

Status: Accepted
Date: 2026-07-22
Class: Process alignment — the automation that improves the repo should be held
to the same review/verify/learning discipline the repo ships to other projects

## Context

`scripts/self-improvement.sh` runs the improvement loop: divergent-design →
task filtering → parallel-worktree implementation ([[research-plan-implement]])
→ validation gates → merge. Its implementation half faithfully mirrors the
repo's process — idea generation follows `workflows/divergent-design.md`, each
task follows `workflows/research-plan-implement.md`, and the per-task worktrees
are a literal instance of CLAUDE.md's batch fan-out (decision-tree row 2).

Its **validation** half did not. The seven gates (commits, diff_size,
file_scope, critical_files, tests, shellcheck, self_eval) are all mechanical
except `self_eval`, which fires only on changed `skills/**.md` / `workflows/**.md`
files. Meanwhile CLAUDE.md and `workflows/pr-prep.md` are emphatic that the
canonical path is RPI → pr-prep → review-fix loop, that `skills/code-review` is
*"required, not optional"*, and that `/verify` must run before the critic
ensemble. The loop stopped at RPI + mechanical gates and never entered that
half. Three concrete consequences:

- A task rewriting `scripts/lib/*.sh` — the loop's most common self-improvement
  target — got shellcheck and bats but **no** design-level review.
- Decision records were unreachable by construction: `file_scope` allowed only
  `docs/working/`, so recording a decision under `docs/decisions/` tripped a
  scope exception.
- The failure-pattern library (`docs/thoughts/failure-patterns.md`) — which
  `pr-prep` appends to and RPI step 2 greps — was bypassed; cross-round learning
  lived only in per-round JSON reports.

In short: the loop dev-processed its own repo in exactly the way the repo tells
every *other* project not to.

## Decision

Adapt the loop to dogfood the process it ships, in three tiers.

**Tier A — cheap alignment.** `file_scope` (gate 1c) and the implement prompt
allow `docs/decisions/`, `docs/reviews/`, and `docs/thoughts/` alongside
`docs/working/`. The prompt requires the `/away` Autonomous Commit Format
(`Confidence:` + `Notes:`) the loop is the canonical actor for, and reminds the
agent to run RPI step 2's failure-pattern grep before planning.

**Tier B — the core gap.** New gate 1h runs `skills/code-review` headless on
each task branch's diff and rejects on red / Must-Fix findings only (amber/green
advisory), matching the review-fix loop's exit condition. Parsing follows the
`self_eval` precedent — the skill emits a `CODE_REVIEW_RED` sentinel; unparseable
output skips rather than auto-rejecting. Verdict logic (`parse_code_review_red`,
`code_review_gate_verdict`) is extracted to `si-functions.sh` with unit tests
and **fails closed** on a garbage count.

**Tier C — full parity.** The per-task agent runs the pre-ship sequence pr-prep
prescribes before its final commit: `/verify` → bounded (3-iteration) review-fix
loop → retro to `docs/thoughts/retro-rN-<id>.md`. After merge, the loop
sequentially harvests `Failure pattern:` notes from approved **fix** tasks' retros
into `failure-patterns.md` (one claude call, so parallel worktrees never conflict
on the append-only file).

This yields the author/reviewer split pr-prep models: the agent self-reviews
(Tier C), and gate 1h is the independent reviewer pass (Tier B).

## Alternatives considered

- **Parse the code-review rubric document directly** instead of a sentinel line.
  Rejected: `code-review` is an interactive orchestrator (banners, a fact-check
  gate that pauses for input); a sentinel is the same robust contract `self_eval`
  already relies on headless.
- **Gate on amber findings too.** Rejected: over-rejects good work; pr-prep's own
  exit condition is "no Must Fix remain," so red-only is the faithful bar.
- **Let agents append to `failure-patterns.md` directly** (as pr-prep does author-
  side). Rejected: N parallel worktrees appending to one append-only file collide
  at merge. Sequential post-merge harvest serializes the writes.
- **Unparseable code-review output fails closed** (rejects the task). Rejected for
  *this* gate: an LLM formatting hiccup shouldn't reject sound work, and `self_eval`
  set the skip-on-unparseable precedent. (The pure verdict *helper* still fails
  closed on a non-integer count — a garbage number is not the same as no number.)

## Consequences

- Every task — not just `.md` edits — now clears a multi-critic review before
  merge, at the cost of one extra `code-review` run per task branch. Acceptable:
  the user explicitly opted into full process parity.
- The loop now produces the same artifact trail as a human PR (reviews, retros,
  decision records, failure patterns), so a round is auditable the way a PR is.
- Redundant reviews (agent self-review + gate) are intentional, mirroring
  author-then-reviewer; comments in the script flag the redundancy as deliberate.

See also `workflows/pr-prep.md` (the process being mirrored) and
`workflows/review-fix-loop.md` (the 3-iteration cap the agent prompt inherits).
