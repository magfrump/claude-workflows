# Research: PR Prep Review Doc Commit Step

## Scope
Add a step to pr-prep that commits review artifacts from `docs/reviews/` to the PR branch before marking ready.

## What exists
- `workflows/pr-prep.md` is a two-phase workflow: Phase 1 (content) and Phase 2 (packaging).
- Phase 1 step 3 is a review-fix loop that generates artifacts in `docs/reviews/`.
- Phase 2 has steps 4 (clean history), 5 (verify/annotate), 6 (PR description).
- The review-fix loop's completion criteria already require review artifacts to exist in `docs/reviews/`, but no step ensures they're committed.
- `docs/working/**` has a `.gitattributes` pattern (`linguist-generated`) to collapse in GitHub diffs. No equivalent exists for `docs/reviews/`.

## Invariants
- Phase ordering: Phase 1 must complete before Phase 2 starts.
- Step 4 (rebase) expects a clean working tree. Any new commit must come before step 4.
- Review artifacts are generated during step 3; they may be modified across loop iterations.
- The workflow is descriptive guidance, not executable code — changes are prose edits.

## Prior art
- The RPI workflow commits working docs to the repo (research/plan docs in `docs/working/`).
- The `.gitattributes` snippet for `docs/working/**` provides a pattern for collapsing generated docs in PR diffs.

## Gotchas
- Review docs may already be committed if the user committed them during the review-fix loop. The new step should be idempotent — check for uncommitted changes, don't blindly commit.
- Step 4 (rebase) may squash the review doc commit into other commits. The step should note that review docs should remain as a separate commit or be preserved during rebase.
