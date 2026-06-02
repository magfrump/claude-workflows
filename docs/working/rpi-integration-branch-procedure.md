# RPI: Integration branch refresh procedure

Status: complete
Relevant paths: workflows/branch-strategy.md

## Research

### Task
Add a standardized "Integration branch refresh" procedure to `workflows/branch-strategy.md`:
enumerate all open PRs → merge them into a *fresh* integration branch → resolve conflicts
using the prior integration branch's resolutions as **reference only** (re-verify each hunk) →
fold in PRs not yet on the previous integration branch. Bake in failure-driven mitigations.

### Prior art in the file
- **Branch roles** (line 16–22): `dev` is the disposable integration branch; features branch off
  `main`; PRs squash-merge to `main`.
- **Rules** (line 33): rule 4 already says "`dev` is disposable… delete and recreate from `main` +
  re-merge all active feature branches." The new procedure is the *fuller, PR-driven, reviewable*
  version of that rule.
- **Setting up or resetting dev** (line 146): the lightweight reset. It re-merges *local active
  feature branches* and ends with `git push --force-with-lease origin dev` — an in-place force-push
  of the shared branch. The new procedure differs on three axes: (a) driven by **open PRs**, not
  local branches; (b) **conflict-aware** via prior-resolution reference; (c) lands on a **fresh
  reviewable branch** instead of force-pushing the shared one.

### The "existing approval gate"
Global CLAUDE.md Operating Modes: "Force-push… Any destructive or irreversible operation — Still
require user approval (regardless of mode)." So "never force-push over shared branches outside the
existing approval gate" = the refresh must not silently replace the team's integration branch; the
pointer swap is gated on explicit human approval. The fresh branch is the reviewable artifact until
then.

### Invariants to preserve
- Features branch off `main`; PRs target `main`; `dev` never holds source-of-truth history.
- Section ordering and the `Done when…` + Quick-reference conventions used throughout the file.
- Don't break the existing reset section — cross-reference it and flag its force-push as gated.

## Plan
1. Insert a new `## Integration branch refresh` section after "Setting up or resetting dev",
   positioning it as the heavier, PR-driven sibling and cross-referencing the lighter reset.
2. Section contents:
   - One-paragraph purpose + when-to-use (vs. the lightweight reset).
   - Numbered procedure: enumerate open PRs → fresh branch from main (date-stamped, preserves prior)
     → merge each PR head → resolve conflicts with prior branch as reference-only, re-verifying each
     hunk → fold in PRs absent from the previous integration branch → verify → promote without
     force-pushing the shared branch outside the approval gate.
   - "Why this shape (failure-driven)" subsection naming the three mitigations.
   - `Done when…` checklist.
3. Add a one-line gated-force-push caution to the existing reset section so the two are consistent.
4. Add Quick-reference rows for the new procedure.

## Verification
- Markdown renders; section ordering and conventions match the rest of the file.
- The three mitigations each appear explicitly and are traceable to a procedure step.
- No file outside scope touched.
