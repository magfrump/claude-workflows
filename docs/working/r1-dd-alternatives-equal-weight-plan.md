- **Goal**: Reorder DD step 5's decision-record template so Pruned candidates achieves peer prominence with Decision (≤2 visual steps from top).
- **Project state**: feat/r1-dd-alternatives-equal-weight delivers a single surgical edit to workflows/divergent-design.md · standalone round · not blocked.
- **Task status**: in-progress (plan drafted, implementing)

## Problem

The current body-section list in DD step 5 (lines 145-151) orders sections as:
1. Context
2. Options considered (brief)
3. Decision and rationale
4. Consequences
5. Revisit triggers
6. **Pruned candidates and why**
7. Stress-test mitigations

A reader scanning a decision record sees Decision early but must scroll past Consequences and Revisit triggers before encountering the pruned-candidate list. This makes pruned candidates feel like a footnote, not a peer of the chosen survivor.

## Change

1. **Reorder**: Move "Pruned candidates and why" immediately after "Decision and rationale". Keep Stress-test mitigations adjacent (it explains how survivors were further filtered, conceptually paired with pruning). The new order:
   1. Context
   2. Options considered (brief)
   3. Decision and rationale
   4. **Pruned candidates and why**
   5. Stress-test mitigations (if any)
   6. Consequences
   7. Revisit triggers

2. **Cross-reference**: Add a one-line instruction to the Decision-and-rationale bullet telling authors to end it with a `See alternatives considered →` pointer to the Pruned-candidates section. This gives a clickable bridge so survivors and pruned options have explicit peer prominence even when scanning.

3. **Update the Done-when checklist** at line 157 to list body sections in the new order.

## Files touched
- workflows/divergent-design.md (in-scope)
- docs/working/r1-dd-alternatives-equal-weight-plan.md (this doc)

## Out of scope
- No edits to actual decision records under docs/decisions/ (none embed in this workflow; constraint forbids).
- No semantic change to the content of any section — only ordering and one cross-reference line.
