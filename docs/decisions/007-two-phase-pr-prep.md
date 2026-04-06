# 007: Two-Phase PR Prep Ordering

**Date:** 2026-04-06
**Status:** Accepted

## Context

The existing pr-prep.md workflow has a step ordering that creates waste and missed early exits:

1. **Size check is step 6 (last).** If a PR needs splitting, all prior work — commit cleanup, CI, the full review-fix loop, description writing, and annotation — gets thrown away or needs redoing for the split PRs.
2. **Commit cleanup is step 1, before the review-fix loop.** The review-fix loop changes code, so commits organized before review will need re-organization afterward. Rebasing before code is final creates unnecessary conflict risk.
3. **CI is a standalone step before review.** The review-fix loop already includes re-running tests (step 3c), making the standalone CI step partially redundant for the final state.

These issues were surfaced during a divergent design exercise evaluating candidate orderings.

## Options considered

- **Size-check-first (conservative fix):** Move size check to step 1, keep everything else. Fixes the worst issue but leaves commit cleanup before review.
- **Gate-based pipeline:** Reorder as size check → CI → review-fix loop → commit cleanup → description → annotate. Flat list ordered by "most likely to force a restart." Fixes all issues but lacks conceptual grouping.
- **Two-phase split:** Phase 1 (content): size check → review-fix loop. Phase 2 (packaging): commit cleanup → CI → description → annotate. Separates "is the code right?" from "is the PR presentable?"
- **Review-first:** Size check → review-fix loop → commit cleanup → CI → description → annotate. Pushes CI to the end, creating a late failure point for build/lint issues.
- **Continuous-review:** Run review throughout development, not as a prep step. Blurs the boundary of what "prep" means.

## Decision

**Two-phase split.** The phase labels ("content" vs "packaging") create an intuitive mental model: first make the code right, then make the PR presentable. This fixes all three ordering issues:

- Size check moves to the very first step (fail fast on splitting)
- Commit cleanup moves after the review-fix loop (rebase final code, not in-progress code)
- CI runs on final, reviewed, rebased code (no false confidence from early green)

**Scope note:** This decision covers the ordering of existing steps. The same PR also adds new steps (dependent PR check, draft PR, documentation check, dependency audit, UI screenshots in descriptions) — these are independent enhancements that fit naturally into the two-phase structure but are not part of the ordering decision itself.

## Consequences

- **Easier:** Size check catches split-worthy PRs before any other work. Commit cleanup operates on stable code. CI result reflects what the reviewer will actually see.
- **Harder:** The doc is slightly more complex (two named phases vs a flat list). The review-fix loop no longer has a preceding CI step to catch surface issues before the first review pass — but review-fix loop step 3c covers this, and reviewers are better at ignoring lint noise than we gave them credit for in the original ordering.
