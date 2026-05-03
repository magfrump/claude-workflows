**Goal**: Add a 1-line decision-fragility marker to step 5 of `workflows/divergent-design.md` so DD decision records name the single piece of evidence whose change would flip the decision.

**Project state**: R3 DD post-decision fragility note · standalone enhancement that pairs with R1 dd-anti-portfolio · not blocked.

**Task status**: complete (implemented and verified)

## Context

R1 added an anti-portfolio section to DD decision records (commit 93f427e): a compact list of pruned candidates with one-line discard reasons. R3 inverts it: name the single piece of evidence about the *chosen* approach (or a pruned candidate) whose change would flip the decision. Together they make decisions auditable post-rollout — anti-portfolio shows what was killed, fragility shows what would bring them back.

## Plan

Modify step 5 ("Document") of `workflows/divergent-design.md` only. Two edits:

1. **Add a body-section bullet** between "Pruned candidates and why (anti-portfolio)" and "Stress-test mitigations":

   ```
   - **Decision fragility**: a 1-line marker naming the single piece of evidence whose change would flip the decision — pairs with the anti-portfolio by inversion (anti-portfolio names what was killed; fragility names what would resurrect them). Format: `If [evidence] [changes by X], [pruned candidate or alternative] wins.` Example: `If candidate #2's effort estimate moves from ~1d to >3d, candidate #4 wins.` If the decision is robust to all foreseeable evidence shifts, state `none — robust across [scope]`. Makes decisions auditable post-rollout: when the named evidence changes, re-run the relevant DD steps rather than rationalize.
   ```

2. **Add a Done-when checklist row** in the corresponding list:

   ```
   - [ ] A Decision fragility line names the single piece of evidence whose change would flip the decision, or states `none` if the decision is robust
   ```

Sub-threshold log rows remain exempt (same precedent as the three-line header requirement).

## Out of scope

- Updating existing decision records to add fragility markers (forward-only convention).
- Touching `docs/decisions/log.md` schema.
- Cross-references from RPI / other workflows.

## Verification

- Re-read step 5 to confirm both edits read coherently with surrounding text.
- Confirm the example matches the task brief's example verbatim.
