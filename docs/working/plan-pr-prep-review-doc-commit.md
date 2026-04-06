# Plan: PR Prep Review Doc Commit Step

## Scope
Add a step to pr-prep Phase 2 that commits review artifacts from `docs/reviews/` before the history cleanup step.

Research: [research-pr-prep-review-doc-commit.md](research-pr-prep-review-doc-commit.md)

## Approach
Insert a new step between Phase 1 (step 3, review-fix loop) and current step 4 (clean history). This becomes the new step 4, bumping subsequent steps to 5-7. The step stages any uncommitted review artifacts, commits them, and recommends a `.gitattributes` pattern to collapse them in GitHub diffs.

## Steps

1. **Insert new step 4 "Commit review artifacts"** (~30 lines of prose in pr-prep.md)
   - Add prose between the Phase 1/Phase 2 boundary and current step 4
   - Content: stage `docs/reviews/` files, commit with `docs: add review artifacts`
   - Note idempotency: skip if no uncommitted review files exist
   - Recommend `.gitattributes` pattern `docs/reviews/** linguist-generated`
   - Include completion criteria consistent with existing style

2. **Renumber steps 4→5, 5→6, 6→7** (~10 edits across existing headings/references)
   - Update all heading numbers
   - Update any cross-references within the file (e.g., "step 2" references in step 5a)

## Size estimate
~30 new lines for the new step, ~10 lines of heading/reference updates. Single file change.

## Risks
- Renumbering may miss internal cross-references. Will grep for step number references.
