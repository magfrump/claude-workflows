# Draft Review: Review Artifact Lifecycle

**Branch:** feat/r2-review-artifact-lifecycle
**Reviewed:** 2026-03-23
**Status:** CONDITIONAL PASS

## Summary

This branch adds YAML frontmatter with `Last verified` and `Relevant paths` fields to all 15 review artifacts in `docs/reviews/`, and extends `guides/doc-freshness.md` with a "Review artifact lifecycle" section covering when to re-run, archive, or leave alone a review. The approach is sound and the guide additions are clear, but one path is factually wrong and a few path selections are overly broad or mismatched with what the review actually covers.

## Factual Issues

1. ~~**`fact-check-report.md` references a nonexistent path.**~~ **Resolved in 00c1645.** Path corrected to `test/skills/fact-check/fixtures/` and `test/skills/code-fact-check/fixtures/`.

2. ~~**`performance-review.md` includes paths it does not analyze.**~~ **Resolved in 00c1645.** Removed `CLAUDE.md` and `workflows/user-testing-workflow.md`.

3. ~~**`security-review.md` has the same over-inclusion issue.**~~ **Resolved in 00c1645.** Removed `CLAUDE.md`.

## Structural Critique

**Consistency is good overall.** All 15 review artifacts received frontmatter. The YAML format is identical across files (triple-dash delimiters, `Last verified` and `Relevant paths` keys, list syntax for paths).

**Two different date values exist without explanation.** `performance-review.md` and `security-review.md` use `Last verified: 2026-03-20` while the other 13 files use `2026-03-23`. This is presumably intentional (those reviews were produced on March 20), but the branch commit message doesn't note this distinction. If the intent is that `Last verified` reflects when the review was originally produced, that's correct. If it reflects when freshness tracking was added, they should all be the same date.

**Format duality in the guide could cause confusion.** The existing "Freshness fields" section of `guides/doc-freshness.md` shows the format as bold markdown (`**Last verified:** ...`), but all review artifacts use YAML frontmatter (`---` block). The new "Frontmatter format for reviews" subsection correctly shows the YAML format, but the guide now implicitly documents two incompatible formats without explaining when to use which. A note clarifying that review artifacts use YAML frontmatter while other document types use inline bold fields (or vice versa) would prevent inconsistency as more documents gain tracking.

**`full-evaluation.md` uses very broad paths.** Listing `skills/` and `workflows/` as relevant paths means any change to any file in those directories triggers a staleness signal. For a full evaluation this may be intentional, but it means this review will almost always appear stale. Consider whether that's the desired behavior or whether it should list the specific skills/workflows it evaluated.

## What Works Well

- The guide's lifecycle section (re-run / archive / leave alone) is clear and actionable. The three decision branches cover the realistic cases well.
- Using YAML frontmatter rather than inline bold fields is the right call for review artifacts -- it's parseable by tooling and clearly separated from document content.
- The table change from "Already tracked" to "Yes" with a new rationale correctly reflects that the old `Checked:` date field was not the same as freshness tracking (it recorded when the review was produced, not when it was verified against current code).
- Path granularity is appropriate for most files -- specific skill files rather than whole directories.

## Actionable Guidance

1. **Fix `fact-check-report.md` path.** Change `test/fixtures/` to `test/skills/fact-check/fixtures/` (or `test/skills/` if the report covers both fact-check variants).
2. **Trim `performance-review.md` and `security-review.md` paths** to only the files whose changes would actually invalidate those reviews' findings. Remove `CLAUDE.md` and `workflows/user-testing-workflow.md` from performance-review; remove `CLAUDE.md` from security-review.
3. **Add a note to `guides/doc-freshness.md`** clarifying the relationship between the bold-field format (existing section) and YAML frontmatter format (new section). Suggest one canonical format or explain when each applies.
4. **Consider narrowing `full-evaluation.md` paths** or accepting that this review will always flag as stale and documenting that expectation.
