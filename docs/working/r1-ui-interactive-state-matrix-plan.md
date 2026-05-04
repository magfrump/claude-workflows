# Plan: ui-visual-review interactive state matrix

## Goal
Add a state matrix checklist to `skills/ui-visual-review.md` that verifies
default / hover / focus / active / disabled / error states for each interactive
element actually touched in the diff.

## Research notes
- Existing checklist items 1–5 are mechanical (default mechanical-review mode).
- Items 6–7 are full-audit-only.
- Items 8–9 use the "Activation trigger" pattern — diff-scoped specialty checks
  (3D viewport, accessibility serialization) that run in default mode when their
  trigger condition holds.
- The state matrix is mechanical, diff-scoped, and applies to any framework with
  interactive elements (not full-audit-only). It fits the same pattern as items
  8 and 9.
- Item 6 already covers some affordance concerns (focus indicators, disabled
  states) but is full-audit-only and not diff-scoped or matrix-structured.

## Design decisions
1. **Placement.** Add as a new item under Step 2 alongside items 8 and 9,
   following the "Activation trigger → mechanical pattern check → common
   failure modes" structure. Numbered 10 so existing items keep their numbers
   (avoids breaking inbound references and keeps the diff small).
2. **Mode.** Runs in default mechanical-review mode whenever the activation
   trigger fires. The matrix is concrete pattern matching: either the element
   handles the state or it does not.
3. **Scope.** Strictly diff-scoped. The skill should not audit every
   interactive element in the codebase — only those actually touched by the
   current diff. This keeps signal high and noise low.
4. **State list.** Six states from the task: default, hover, focus, active,
   disabled, error. Note that `error` is element-conditional (only relevant for
   form inputs and similar validatable elements) — call this out so reviewers
   don't flag it as missing on plain buttons.
5. **Element identification.** Define what counts as an interactive element
   (buttons, links, inputs, selects, custom roles, anything with click/keyboard
   handlers) so the trigger is unambiguous.
6. **Cross-reference.** Item 6 already mentions focus indicators and disabled
   states for *full-audit* mode. Add a brief cross-reference note so readers
   know item 10 is the diff-scoped, mechanical version and item 6 is the
   broader audit version.

## Implementation steps
1. Insert new section "### 10. Interactive element state matrix *(when diff
   touches interactive elements)*" after item 9 in `skills/ui-visual-review.md`.
2. Include: activation trigger, the six states with one-line descriptions of
   what to check for each, a per-element checklist format, and common failure
   modes.
3. Add a one-line cross-reference in item 6 pointing to item 10 for the
   diff-scoped mechanical version.
4. Commit with conventional-commit prefix `feat(ui-visual-review):`.
5. Push.

## Files touched
- `skills/ui-visual-review.md` (only file in scope)
- `docs/working/r1-ui-interactive-state-matrix-plan.md` (this plan)

## Out of scope
- Full WCAG audit of state contrast ratios (delegated to a dedicated a11y skill)
- Visual regression tooling for state captures (already covered in Step 6d)
- Renumbering existing checklist items
