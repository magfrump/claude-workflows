- **Goal**: Add a short acceptance checklist to divergent-design.md's step-4 "Decision presentation" sub-step, drawn from three usability properties, holding the rendered CLI decision block to concrete, checkable structure requirements (the brainstorm-display conventions).
- **Project state**: feat/r2-dd-display-formatting-property-acceptance delivers the property-acceptance gate on the r1 Decision-presentation block · round-2 task in the DD-display-formatting line · not blocked.
- **Task status**: complete (checklist added, Done-when row enforces it, scope verified)

## Research

### What exists
- The "Decision presentation" sub-step (`workflows/divergent-design.md` ~lines 139–187) was created by r1 commit `1bf0aa3`. It already renders the tradeoff matrix + stress-tests as a CLI decision block in three regions: Region 1 scorecard grid, Region 2 candidate cards (drill-down target), Region 3 drill-down protocol + recommendation banner.
- It already *embodies* the brainstorm-display conventions without naming them as a gate: box-drawing fences (boxed regions), default-collapsed cards expanded on demand (progressive disclosure), a single `DECISION:` banner (one decision per screen).
- The step-4 "Done when..." checklist (~lines 260–269) has one row covering the Decision presentation block; that is the row the task scopes me to touch.

### Source material
- `docs/human-author/property-tests.json` is referenced by the task but does **not** exist in the repo or on any branch. The task supplies the three property keys inline, and they are standard Norman usability principles, so the file's absence is not blocking — I draw from the named properties directly and note the absent source in the checklist's framing. Creating the JSON is out of file scope.
  - **discoverability-on-creation** — on first render the reader can tell, unprompted, what is recommended, what every glyph means, and how to act (drill down). State + affordances are visible, not hidden behind instructions.
  - **conceptual-model-coherence** — the three regions are views of *one* decision: the same candidate set, axes, and ordering appear consistently; nothing in one region contradicts another.
  - **mapping-naturalness** — the visual encoding maps directly to the data: glyph severity runs one direction (● best → ○ weak → ✗ fails) in every column, row position encodes recommendation priority, and a card carries exactly its row's data — nothing added, nothing dropped.
- Brainstorm-display structural conventions to cite inline (from `superpowers:brainstorming` visual companion + the user's "brainstorm's formatting is structurally nicer" complaint): **boxed regions, progressive disclosure, one decision per screen**. These are the structural vocabulary the acceptance checklist makes checkable.

### Invariants / scope
- Edit ONLY the Decision presentation sub-step and its single Done-when row in step 4. Leave the step-4 handoff seam (separate round-2 task) untouched.
- File scope: only `workflows/divergent-design.md` (+ this working doc).

## Plan
1. Append an "**Acceptance checklist (structure gate)**" block to the end of the Decision presentation sub-step (after Region 3's recommendation banner). It:
   - Cites the brainstorm-display conventions inline (boxed regions / progressive disclosure / one decision per screen) and frames the gate as turning "brainstorm's formatting is structurally nicer" into checkable structure requirements.
   - Lists 3 grouped checks, one per property (discoverability-on-creation, conceptual-model-coherence, mapping-naturalness), each phrased as a concrete pass/fail condition on the rendered block.
2. Update the existing step-4 Done-when row for the Decision presentation block to require the block *satisfies the acceptance checklist*, so the gate is enforced by the same checklist mechanism as the rest of step 4.

## Verification
- Re-read edited region for internal consistency (region names, glyph order, ★ marking referenced in checks all match the rendered examples above).
- Confirm no edits leaked into step-4 handoff seam or other steps (`git diff` scoped to the two regions).
