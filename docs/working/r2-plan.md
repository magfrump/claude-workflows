# R2 Plan: Synthesis consumes goal-alignment notes

## Goal

Close the loop on R1's goal-alignment-note output by requiring synthesis (Stage 3) to consume it. Surface coverage gaps and escalations in the chat synthesis under a new `### Coverage and Escalations` heading.

## Context (from R1, already shipped)

Both orchestrators (`code-review.md`, `draft-review.md`) require every dispatched sub-agent to append a canonical Goal-Alignment Note:

```markdown
## Goal-Alignment Note
- Answered: [yes / partial / no — one phrase]
- Out of scope: [what was set aside and why, or "none"]
- Escalate: [what the orchestrator should action separately, or "nothing"]
```

Source of truth: `patterns/orchestrated-review.md` §"Goal-alignment self-report".

R1 made sub-agents *produce* the note. R2 makes the orchestrator *consume* it.

## Changes

### `skills/code-review.md`

1. **Stage 3 preamble (after line 268, before "Deliverable 1: Chat Synthesis")**: insert a "Goal-alignment scan" sub-step. Scan all received Goal-Alignment Notes; collect:
   - Sub-agents whose `Answered:` is `no` or `partial` (with the one-phrase reason)
   - Non-trivial `Out of scope:` items (anything beyond literal "none")
   - Non-trivial `Escalate:` items (anything beyond literal "nothing")

   "Non-trivial" filters out the canonical sentinel values "none" / "nothing" — anything else is surfaced.

2. **Chat synthesis structure (Deliverable 1)**: add a `### Coverage and Escalations` heading. Position it after Scope summary and before Factual issues so that coverage limits are visible up front before the user reads findings. If the scan finds nothing to surface, render the heading with a one-line "All sub-agents fully addressed their scope; no out-of-scope or escalate items." so the section is still auditable.

### `skills/draft-review.md`

1. **Stage 3 preamble**: parallel insertion. Existing Stage 3 already has a "cross-reference" sub-step before deliverables. Add the Goal-alignment scan as a separate step alongside the cross-reference (both before Deliverable 1).

2. **Chat synthesis structure**: add `### Coverage and Escalations` heading at the top of the synthesis (before Factual issues). Same content rules as code-review.

## Files touched

- `skills/code-review.md` (modify Stage 3 + Deliverable 1)
- `skills/draft-review.md` (modify Stage 3 + Deliverable 1)

## Out of scope (for this round)

- Updating `patterns/orchestrated-review.md` — R1 is already cited; consumption guidance lives in the orchestrator skills.
- Updating the rubric (Deliverable 2) — the goal-alignment surface is per-spec a chat-synthesis concern.
- Preamble template that prompts sub-agents to think about alignment up front — that's a future round.
