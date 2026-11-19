Commit: 22f9cd8f
Loop-pass short-circuit: used at b7ebe774

# Code Review Rubric

**Scope:** fix/dev-cycle-roadmap-staleness vs main (full branch, first loop pass) | **Reviewed:** 2026-11-18 | **Status: 🔴 DOES NOT PASS** — pass 2 (fact-check of the fix delta b7ebe774..22f9cd8f) found 1 more red; fixed in the next commit; critics pending

Fact-check: `docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness.md` (pass 1) and `…-pass2.md` (pass 2, delta b7ebe774..22f9cd8f), both k=1 loop passes. No prior overrides matched this diff.

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | An entry marked ANSWERED but not archived yet still counts as holding a roadmap item: `questions.sh open` lists live-file entries of any status, so section 5 reports `open Q-NNN` for an answered hold, the stale-hold case the branch exists to catch. | Correctness | Incorrect (fact-check claim 11b, executed) | code-fact-check | `scripts/dev-cycle.sh:466` | for-author | none | Fixed: section 5 drops IDs whose live-file Status is ANSWERED; test "section 5: an entry marked ANSWERED but not archived yet holds nothing…" |
| R2 | Pass 2: the `answered` awk matched `**Status:** ANSWERED` on any line under a heading (body text, a later `## ` section) and any status starting with ANSWERED, so an open entry could read as no hold; its comment said "the Status field". Errs the safe way. | Correctness | Incorrect (pass-2 claim 5b, executed) | code-fact-check | `scripts/dev-cycle.sh:479` | for-author | none | Fixed (57e8950a): reads Status only from the `**Needs:**` line, split on " · ", compared exactly as `questions.sh archive` does; test "section 5 reads an entry's Status only from its Needs line…" |

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Every non-blank line up to the next item folds into it, column-0 prose and `###` headings included, so an item can read as held by an ID in a following paragraph (`scripts/dev-cycle.sh:488-489`). | Correctness | Mostly accurate (claim 9b, executed) | code-fact-check | for-author | none | Fixed: only indented lines continue an item; a column-0 non-item line ends it; same test | |
| A2 | A second `## Now` or `## Next` heading is read too and keeps numbering, unlike section 7, which stops at the first (`scripts/dev-cycle.sh:484-487`). | Consistency | Mostly accurate (claim 9a, executed) | code-fact-check | for-author | none | Fixed: only the first of each counts; same test | |
| A4 | Pass 2: "step 1 archives after this digest runs" holds only for a status exactly ANSWERED; the digest dropped a broader set (claims 4b, 5c), and the commit message overstated A3 (claim 10). | Consistency | Mostly accurate (pass-2 claims 4b, 5c, 10) | code-fact-check | for-author | none | Fixed with R2: the digest now drops exactly what `archive` moves | |
| A5 | Pass 2: research doc line 35 still said `open_q` holds a partial list when the second call fails; it holds the first call's full list (claim 3). | Docs | Mostly accurate (pass-2 claim 3) | code-fact-check | for-author | none | Fixed | |
| A3 | The research doc says `open_q` is one line per open entry or watch, and that it is unset or empty when section 3 fails; neither holds (research doc lines 11, 35). | Docs | Mostly accurate (claims 2, 8) | code-fact-check | for-author | none | Fixed: both statements corrected | |

## 🟢 Consider

None.

## ⏭️ Skipped Core Critics

- security-reviewer, performance-reviewer, api-consistency-reviewer: loop-pass short-circuit (behavioral red confirmed at fact-check, claim 11b). They run on the next pass.

## 🧩 Composition check

No multi-source co-located clusters qualified.
