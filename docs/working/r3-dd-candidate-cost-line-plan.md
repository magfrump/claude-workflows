---
Goal: Add a cost-prediction requirement for surviving DD candidates as a single bullet under step 4's Decision section.
Project state: r3 round delivers a one-line cost-prediction requirement to divergent-design.md · standalone · not blocked
Task status: complete (bullet added under step 4 Done-when checklist)
---

## Context

Round task: extend divergent-design step 4 so each surviving candidate declares a predicted implementation cost (tokens *or* hours) alongside the existing falsifiable hypothesis. Treat as a soft prediction, not a strict cap. Implementation is a single bullet under the Decision section of `workflows/divergent-design.md`.

## Plan

1. Add a single bullet to step 4's "Done when..." checklist, immediately after the existing falsifiable-hypothesis bullet. The new bullet:
   - Lives in the same checklist as the hypothesis bullet (Decision section's done-when gate).
   - Allows token estimate or hour estimate.
   - Frames the prediction as soft, not a cap.

Proposed bullet text:

> - [ ] Each surviving candidate declares a predicted implementation cost — a token estimate or an hour estimate; treat as a soft prediction, not a strict cap

That is the entire diff. No prose paragraph changes, no other sections touched.

## Verification

- Read the file post-edit; confirm the new bullet sits adjacent to the hypothesis bullet and the surrounding checklist still parses as a markdown list.
- Confirm no other files were modified.
