# Review → Fix → Revalidate Loop

This document is reference material for the review-fix loop step in [pr-prep](../../.claude/workflows/pr-prep.md). See pr-prep Step 3 for the procedure itself.

## Loop dynamics

The key insight is that each iteration operates on a higher-quality baseline:

```
Loop 1: Fix obvious issues (wrong field names, broken regexes, UUOC)
Loop 2: Fix subtle issues revealed by Loop 1 fixes (scoping bugs, false passes)
Loop 3: Fix consistency issues across the now-correct test suite
```

Reviews get more useful as the code gets cleaner — early reviews are dominated by surface issues that mask deeper ones. This is why a single review pass is often insufficient.

In practice, most feature branches converge within a few loops, though this depends on the size and complexity of the change.

## Anti-patterns

- **Fixing Consider items before Must Fix items.** Tier order exists for a reason — fixing a style issue in code that has a correctness bug is wasted work.
- **Skipping the test run between fix and re-review.** The test run is where you catch issues the review didn't anticipate. Skipping it means the re-review may pass on code that doesn't actually work.
- **Treating review findings as infallible.** Always read the code to confirm. Reviews can misidentify field names, miscount sections, or flag correct code as buggy.
- **Running more than 3-4 loops.** If findings aren't converging, the problem is architectural, not incremental. Step back and use a different workflow (divergent-design, RPI).

## Relationship to other workflows

This loop complements Research → Plan → Implement. RPI produces a reviewed implementation; the review-fix loop hardens it by running automated critics and iterating on their findings. Together they cover the full path from "understand the problem" to "PR ready for human review."

The loop is embedded in pr-prep as a required step. It should not be run as a standalone workflow — use pr-prep, which sequences it alongside commit cleanup, CI verification, PR description writing, and size checks.

## Artifacts

This loop doesn't produce its own working documents. It operates on and updates:

- `docs/reviews/*.md` — review artifacts (overwritten each loop)
- Test files — fixed as findings are addressed
- The feature branch itself — commits accumulate naturally

The commit history serves as the audit trail for what was found and fixed in each loop.
