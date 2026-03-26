# Plan: Retrospective Appendix R2

## Scope
Tighten integration between pr-prep.md's review-fix loop exit criteria (step 3e) and the Post-PR Reflection appendix; make reflection questions reference concrete artifacts.

## Research
File: `workflows/pr-prep.md` (98 lines). The appendix (lines 90-97) has four reflection questions that use abstract phrasing ("the plan", "workflow steps", "size estimates"). Step 3e (line 49) has no forward reference to the appendix.

## Approach
Three targeted edits to a single file.

## Steps

1. **Step 3e forward reference**: After the exit criteria sentence, add a note directing the reader to the Post-PR Reflection appendix for closing the loop on what the review-fix process revealed.

2. **Concrete artifact references in reflection questions**: Rewrite each question to name the specific artifact it should draw from:
   - Plan accuracy → reference `docs/working/plan-*.md`
   - Skipped steps → reference the review-fix loop findings and self-eval results
   - Time vs. estimate → reference size estimates from the plan doc
   - What to change → reference plan doc, review findings (`docs/reviews/`), self-eval scores

3. **Sharpen surrounding descriptions**: Minor wording tightening in step 3a (clarify what self-eval targets), step 3d (strengthen comparison guidance), and step 6 (add a nudge toward the appendix after size check).

## Risks
- Over-editing could introduce self-eval issues of its own. Keep changes surgical.
