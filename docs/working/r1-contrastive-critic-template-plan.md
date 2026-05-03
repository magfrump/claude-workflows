# Plan: Contrastive Critic Template Stub

## Goal

Add an optional `Contrastive note` template (~5 lines) to `skills/code-review.md`
and `skills/draft-review.md`. The note pairs a caught issue with a likely-missed
issue and asks the orchestrator to propose one concrete prompt-refinement
candidate. No feedback pipeline — capture only.

## Placement decision (per stress-test mitigation)

Embed inside Stage 3 (the required synthesis step), as a sibling of
`Goal-alignment scan` at the `####` heading level. Place it directly after the
goal-alignment scan and before the deliverables so the orchestrator does it as
part of the required synthesis flow. Marking it `(optional)` means the *output*
is optional (skip if no genuine contrast), but the *consideration* is part of
the required step — not a freestanding section a reader can ignore wholesale.

## Template content (~5 lines)

Heading: `#### Contrastive note (optional, capture during synthesis)`

Body:
- Pick one finding the panel caught well + one likely-related issue you suspect
  was missed (sources: goal-alignment notes, escalate items, your own scan of
  the diff/draft).
- State both in 1–2 lines.
- Propose one concrete prompt-refinement candidate (added instruction, sharpened
  heuristic, new check) that would have closed the gap on the next run.
- Skip if no genuine contrast is available — do not invent one.
- Capture only; no feedback pipeline reads this yet.

The two files get near-identical templates, varying only the noun
(`diff` vs `draft`) so the example sources match the orchestrator's domain.

## Steps

1. Edit `skills/code-review.md`: add the subsection after the Goal-alignment
   scan in Stage 3, before the Deliverable 1 break.
2. Edit `skills/draft-review.md`: same insertion point in its Stage 3.
3. Commit + push.

## Out of scope (per file scope constraint)

- No new pattern doc or feedback-pipeline machinery.
- No edits to other skills, patterns, or workflows.
- No retrospective workflow integration — the template only supports
  synthesis-time capture.
