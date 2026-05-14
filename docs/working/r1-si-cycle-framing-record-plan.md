# SI Cycle Framing Record — Plan

## Problem

The SI loop generates ideas without an explicit problem-side anchor. Per the
project memory `project_si_rewrite_needed.md`, the loop is biased toward
"ship more tasks" / `feat(si)` introspection rather than asking what the
current run is actually trying to solve.

## Goal

At cycle start (once per SI run), produce a one-paragraph
`docs/working/cycle-framing.md` containing:
1. One sentence stating the specific problem this cycle aims to address.
2. 1-2 alternative framings considered but set aside.

Cap at one paragraph to bound maintenance cost.

## Design

- **"Cycle" = full SI run.** The framing is generated once before the round
  loop begins, not per-round. Single file `docs/working/cycle-framing.md`
  (overwritten each run).
- **Placement.** After `parse_si_input` and `USER_INPUT_CONTEXT` assembly
  (so user feedback informs framing), before `START_ROUND=1` and the round
  loop. New "Step 0a — Cycle framing".
- **Generation.** `claude -p` with a prompt that:
  - References `docs/working/completed-tasks.md` and `round-history.json` for
    state (what has already been shipped).
  - Includes `USER_INPUT_CONTEXT` (priorities/feedback may indicate problem).
  - Constrains output to one paragraph (no headings/bullets), one
    problem-statement sentence + 1-2 alternative framings with brief
    set-aside reasons.
- **Injection.** Read the file into `CYCLE_FRAMING_CONTEXT` and inject into
  the idea-generation prompt alongside `PRIOR_CONTEXT`, `SEED_CONTEXT`,
  `USER_INPUT_CONTEXT`. This makes the framing actually shape generated
  ideas — without injection, the framing is decorative.
- **Failure handling.** If generation fails or file is missing, log warning
  and continue with empty `CYCLE_FRAMING_CONTEXT`. Cycle framing is
  advisory, not blocking.

## Files

- `scripts/self-improvement.sh` — add Step 0a after line 258 (end of
  `USER_INPUT_CONTEXT` assembly), inject `CYCLE_FRAMING_CONTEXT` into idea
  prompt around line 412.

## Verification

- Run `shellcheck` on the modified script.
- The file scope gate in SI's own validation pipeline should accept
  modifications to `scripts/self-improvement.sh` plus
  `docs/working/cycle-framing.md` (created at runtime).
