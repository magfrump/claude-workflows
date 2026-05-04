# R1 — task-decomposition recompose section plan

## Goal

Add a recompose section to `workflows/task-decomposition.md` so that, when
sub-investigations rejoin at synthesis time, the parent (synthesized) doc
re-verifies the original goal is met by the sum of sub-task findings, with
the original goal text quoted verbatim for unambiguous reference.

## Why

Decomposition is lossy. When a goal splits into sub-investigations:
- A goal element that doesn't fit any sub-task neatly may be silently
  dropped during the split.
- A finding that addresses a goal element gets reorganized into an RPI
  section (Invariants, Prior art, etc.) at synthesis time — its connection
  to the goal element it answers becomes implicit.

Without an explicit recompose check, gaps surface during planning or
implementation rather than research, when they're more expensive to fix.

The "Reconcile" step (step 4) catches *conflicting* assumptions across
sub-investigations. The new "Recompose" step catches *missing* coverage.
They are complementary — reconcile is about contradictions, recompose is
about gaps.

## Edits to workflows/task-decomposition.md

1. **Step 1 (Identify independent sub-investigations)** — extend the intro
   sentence and the "Done when..." block so the original goal text is
   captured verbatim before decomposition begins. Without this, the
   recompose step has nothing concrete to verify against.

2. **New step 6: "Recompose — verify the original goal is met by the sum
   of sub-tasks"** — placed between current step 5 (Synthesize) and
   current step 6 (Plan and implement). Specifies:
   - Quote the original goal text verbatim in the synthesized research
     doc under an "Original goal" heading.
   - Map each element of the goal to the sub-task findings that address
     it under a "Coverage check" heading.
   - Treat any goal element with no sub-task coverage as a gap to resolve
     before planning (additional research, or explicit scope-out
     acknowledgment).
   - Note the relationship to step 4 Reconcile: reconcile catches
     conflicts, recompose catches gaps.

3. **Renumber current step 6 → step 7** ("Plan and implement
   sequentially").

## Test specification

This is a docs-only edit. Verification:

| Test case | Expected behavior | Level | Diagnostic expectation |
|-----------|------------------|-------|----------------------|
| Read the workflow top-to-bottom | Step ordering is 1→2→3→4→5→6(Recompose)→7(Plan and implement); intro paragraph still describes the workflow accurately | manual | flag any broken cross-reference (e.g., a "step 6" mention now pointing to the wrong step) |
| Step 1 "Done when..." | Includes a checkbox for capturing the original goal text verbatim | manual | grep for the new bullet |
| New step 6 | Includes Original-goal and Coverage-check guidance, plus a Done-when block with verifiable checkboxes (verbatim quote present, each goal element mapped, gaps explicitly addressed) | manual | inspect the new section |
| Cross-references in adjacent workflows (RPI, branch-strategy) | None reference task-decomposition step numbers in a way that would break | grep | `grep -rn "task-decomposition.*step" workflows/` returns no broken refs |

## Risks

- **Numbering churn**: any external reference to "task-decomposition
  step 6" would now point at the recompose step instead of plan/implement.
  Mitigation: grep for such references before committing.
- **Overlap with RPI's existing goal-tracking**: RPI already requires a
  one-sentence Goal in the research doc header. The recompose step adds
  a *verbatim* copy of the original task statement (which may be longer
  than one sentence) plus an explicit coverage map. These are
  complementary — the RPI Goal is a single-line anchor; the recompose
  Original-goal section is the full statement against which decomposition
  coverage is checked.

## Estimated context cost

Research ~5k, Implementation ~8k, Review ~5k.

## Actual context cost (post-implementation)

Research ~6k, Implementation ~7k, Review ~3k.
