# R4 Plan: SI Implementation Dispatch Preamble

## Problem

The per-task implementation worktree dispatch in `scripts/self-improvement.sh`
(around line 690) sends Claude a `claude -p` prompt that opens with
`Task: $DESC` followed by the file-scope constraint. The orchestrated-review
pattern (`patterns/orchestrated-review.md` + `skills/code-review.md`) defines a
canonical three-line **goal preamble** — `User goal:`, `Current task:`,
`Success criterion:` — that all critic dispatches use to anchor sub-agents in
the user's outcome, the agent's specific assignment, and the artifact owed
back. The implementation dispatch lacks this preamble, so each per-task
implementer agent starts with no orienting frame above its own task line.

## Fix

Replace the bare `Task: $DESC` line in the dispatch heredoc with the canonical
three-line preamble:

```
User goal: Improve the claude-workflows repo through this round of automated self-improvement by implementing the selected tasks as standalone branches that pass validation gates.
Current task: $DESC
Success criterion: branch pushed with descriptive commits
```

- `User goal` is a literal string — no shell interpolation — and is the same
  across all tasks in a round, satisfying the canonical-form requirement.
- `Current task` reuses the existing `$DESC` interpolation.
- `Success criterion` is the per-task instruction taken verbatim from the
  task description.

Everything below the preamble (the `PRIOR_FAILURE_BLOCK`, `FILE SCOPE
CONSTRAINT`, RPI-workflow instructions, and final commit-subject reminder)
stays unchanged.

## Scope

- File touched: `scripts/self-improvement.sh` (single heredoc edit around
  line 690).
- No changes to validation, gates, or the round-report schema.
- No new variables, no new helper functions.
- Smoke tests in `test/scripts/self-improvement-smoke.bats` source the script
  and exercise functions; they do not grep the prompt text, so they remain
  unaffected.

## Verification

- shellcheck `scripts/self-improvement.sh`.
- Run `bats test/scripts/self-improvement-smoke.bats` to confirm the script
  still sources cleanly and round helpers behave as before.
- Manually inspect the diff to confirm only the dispatch prompt block
  changed.

## Notes

- This is an internal-si task. The change improves the framing the SI loop
  hands to its own implementation sub-agents; there is no externally
  observable behavior to evaluate via real-world usage. No hypothesis row is
  added (file scope is `scripts/self-improvement.sh` only), so the
  deferred-question scope filter has nothing to surface.
