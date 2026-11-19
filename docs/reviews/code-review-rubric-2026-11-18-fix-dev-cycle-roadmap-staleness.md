Commit: 969e8227
Loop-pass short-circuit: used at b7ebe774

# Code Review Rubric

**Scope:** fix/dev-cycle-roadmap-staleness vs main (full branch, first loop pass) | **Reviewed:** 2026-11-18 | **Status: 🔴 DOES NOT PASS** — pass 3 (critics on the full branch, fact-check of 22f9cd8f..969e8227) found 1 more red and 9 ambers; all fixed in the next commit; a confirming pass follows

Fact-check: `docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness.md` (pass 1) `…-pass2.md` (pass 2, delta b7ebe774..22f9cd8f) and `…-pass3.md` (pass 3, delta 22f9cd8f..969e8227), all k=1 loop passes. Pass 3 critics: `security-review-2026-11-18-roadmap-staleness.md`, `performance-review-2026-11-18-roadmap-staleness.md`, `api-consistency-review-2026-11-18-roadmap-staleness.md`. No prior overrides matched this diff.

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | An entry marked ANSWERED but not archived yet still counts as holding a roadmap item: `questions.sh open` lists live-file entries of any status, so section 5 reports `open Q-NNN` for an answered hold, the stale-hold case the branch exists to catch. | Correctness | Incorrect (fact-check claim 11b, executed) | code-fact-check | `scripts/dev-cycle.sh:466` | for-author | none | Fixed: section 5 drops IDs whose live-file Status is ANSWERED; test "section 5: an entry marked ANSWERED but not archived yet holds nothing…" |
| R2 | Pass 2: the `answered` awk matched `**Status:** ANSWERED` on any line under a heading (body text, a later `## ` section) and any status starting with ANSWERED, so an open entry could read as no hold; its comment said "the Status field". Errs the safe way. | Correctness | Incorrect (pass-2 claim 5b, executed) | code-fact-check | `scripts/dev-cycle.sh:479` | for-author | none | Fixed (57e8950a): reads Status only from the `**Needs:**` line, split on " · ", compared exactly as `questions.sh archive` does; test "section 5 reads an entry's Status only from its Needs line…" |
| R3 | Pass 3: the `answered` awk takes the first `**Needs:**` line; `parse_entries` and `archive` take the last, so an entry OPEN-then-ANSWERED still read as a hold (the R1 direction), and the comment, A4 and commit 57e8950a overstated the parity. | Correctness | Incorrect (pass-3 claims 6b, 4, 9; security informational) | code-fact-check, security-reviewer | `scripts/dev-cycle.sh:483` | for-author | none | Fixed: the last Needs line wins; parity claimed only for well-formed entries (one Needs line with all three fields, which `check` requires); test "the last Needs line of an entry wins" |
| R4 | Pass 3: a repo with no questions file printed "NOT checked" for section 5 although section 3 treats a missing file as normal, so step 6 checked nothing exactly where it is new (api-consistency 1). | Correctness | Inconsistent (High) | api-consistency-reviewer | `scripts/dev-cycle.sh:475` | for-author | none | Fixed: section 3's no-file branch sets open_ok; every item lists as unheld; test "section 5 lists every item as unheld when the repo has no questions file" |

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Every non-blank line up to the next item folds into it, column-0 prose and `###` headings included, so an item can read as held by an ID in a following paragraph (`scripts/dev-cycle.sh:488-489`). | Correctness | Mostly accurate (claim 9b, executed) | code-fact-check | for-author | none | Fixed: only indented lines continue an item; a column-0 non-item line ends it; same test | |
| A2 | A second `## Now` or `## Next` heading is read too and keeps numbering, unlike section 7, which stops at the first (`scripts/dev-cycle.sh:484-487`). | Consistency | Mostly accurate (claim 9a, executed) | code-fact-check | for-author | none | Fixed: only the first of each counts; same test | |
| A4 | Pass 2: "step 1 archives after this digest runs" holds only for a status exactly ANSWERED; the digest dropped a broader set (claims 4b, 5c), and the commit message overstated A3 (claim 10). | Consistency | Mostly accurate (pass-2 claims 4b, 5c, 10) | code-fact-check | for-author | none | Fixed with R2: the digest now drops exactly what `archive` moves | |
| A5 | Pass 2: research doc line 35 still said `open_q` holds a partial list when the second call fails; it holds the first call's full list (claim 3). | Docs | Mostly accurate (pass-2 claim 3) | code-fact-check | for-author | none | Fixed | |
| A3 | The research doc says `open_q` is one line per open entry or watch, and that it is unset or empty when section 3 fails; neither holds (research doc lines 11, 35). | Docs | Mostly accurate (claims 2, 8) | code-fact-check | for-author | none | Fixed: both statements corrected | |
| A6 | Pass 3: a 0x1f byte in the roadmap shifts the record fields, and `for id in $ids` word-splits and globs what lands there (security 1, Low, reproduced). | Robustness | Low | security-reviewer | for-author | none | Fixed: the awk turns 0x1f into a space; IDs split with `read -a` (no globbing) and checked against `^Q-[0-9]+$`; test "a 0x1f byte or glob character…" | |
| A7 | Pass 3: a title printed before the verdict could read as a verdict (security 2, Low). | Robustness | Low | security-reviewer | for-author | none | Fixed: each line prints the verdict, then the title in quotes; same test | |
| A8 | Pass 3: the skill had no handler for section 5's NOT-checked line (api-consistency 2). | Consistency | Inconsistent (High) | api-consistency-reviewer | for-author | none | Fixed: step 6 moves nothing on its account and the `6.` line says so | |
| A9 | Pass 3: the NOT-checked line broke the digest's `**… NOT checked** —` shape; titles rendered `TITLE.:`; Done's definition was not widened; three wordings of one concept; step 0.5 said a stale item waits in a light pass; the `6.` template line mixed ` / ` and `; ` (api-consistency 3-8). | Consistency | Minor/Informational | api-consistency-reviewer | for-author | none | Fixed: all six; the template reshape changes the record fingerprint, so `record-6-roadmap-holds` carries the new one | |
| A10 | Pass 3: research doc and rubric R2 "compared exactly as archive does" needs the well-formed qualifier; a Needs line with no Opened field differs (pass-3 claims 3, 6c). | Docs | Mostly accurate | code-fact-check | for-author | none | Fixed: the comment states the well-formed scope, which `check` enforces | |

## 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | One `printf \| awk` fork per ID (performance 1, informational) | performance-reviewer | Won't-Fix: override-log row 2026-11-18 |
| C2 | A malformed entry shows its slug as the route (api-consistency 9) | api-consistency-reviewer | Won't-Fix: override-log row 2026-11-18 |

## ⏭️ Skipped Core Critics

- Pass 1 only: security-reviewer, performance-reviewer, api-consistency-reviewer, loop-pass short-circuit (behavioral red confirmed at fact-check, claim 11b). All three ran on pass 3 against the full branch.

## 🧩 Composition check

No multi-source co-located clusters qualified.
