Commit: 9e7c61c5
Loop closed at 9e7c61c5
# Code Review Rubric

**Branch:** `feat/build-loop-u2c1` (U2c1: the S rules in `--check`: Paths:, own files, the floor, Self-merge never:), on main 5c407a4c.
**Status: 🟢 ITERATION 2 (`--loop-pass`, k=1, range eddfd5f9..cf7dd447) — no Must Fix, no Must Address; Consider items fixed in the commit after cf7dd447 (unreviewed at this stamp). Next: the final confirming pass (k=3, full panel, no `--loop-pass`).** Single-sample review; absence of findings is not an attestation.

## Iteration 3: final confirming pass (Commit 9e7c61c5, no `--loop-pass`, k=3, scope `main...HEAD`, full panel)

Delivery mode: self-read. Fact-check: three replicates (`code-fact-check-report-build-loop-u2c1-final-r1/-r2/-r3.md`: 48/47/54 claims) merged most-severe-wins into `code-fact-check-report-build-loop-u2c1-final.md` (63 clusters: 40 Verified, 9 Mostly accurate, 4 Stale, 6 Incorrect, 4 Unverifiable; agreement 79.4%). Critics (opus, parallel): security, performance, api-consistency, architecture (`*-2026-10-10-u2c1-final.md`). Stage 2.5: `code-fact-check-submitted-claims-build-loop-u2c1.md` (claims 55-59: 4 Verified, 1 Mostly accurate, all executed). Lite fix-drift over 9e7c61c5's fixes: one finding, refuted (it read the i2 security report, which described the code before C1).

### 🔴 Must Fix
None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| D1 | An added review whose NAME part holds upper case (`docs/reviews/Code-Review-2026-10-01-x.md`) counted as the brief's own file: ownfile's `*"-$2.md"` checks no case, while --help, srules' comment and plan:311 said own files land only in lower case; on a case-insensitive clone it can take an existing review's name. | Medium | fact-check r3 (Incorrect 12b, 18b, 27b, 50); security F1; architecture F1 | Fixed: srules accepts an own file only when the whole path is lower case; test row added; contract item 8 updated. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| D2 | Contract item 8 still said ownfile takes a lower-cased path. | fact-check 37 (Stale); architecture F2 | Fixed. |
| D3 | --help :155/:179 omitted the brief re-read refusal; srules' $5 "the checkout refusal"; on a re-read failure the deny text said "so only its own files land". | fact-check 14, 16b, 27a, 28; security F2; architecture F3 | Fixed: help names the re-read refusal; $5 is "the verdict's refusal"; the re-read deny reads "the brief could not be read again from the default branch". |
| D4 | A loop's advisory run skips the floor silently (its checkout always refuses). | api-consistency 1 | Fixed in --help; U3 loop prompt (row). |
| D5 | "Paths: P ..." placeholder; LIST_BAD missing from check_line's globals list; nrules' comment omitted briefs/cycles as files. | api-consistency 2; architecture F4; fact-check 23a | Fixed. |
| D6 | Override rows 610, 612, 613 inaccurate (need_root 4 per floor call; re-read now refuses). | fact-check 3a-c, 5, 6; performance 1 | Corrected in new rows. |
| D7 | Commit messages eddfd5f9, d435100e overtaken. | fact-check 46, 50, 52 | Accepted-immutable (row). |
| D8 | LIST_BAD=entry unread. | api-consistency 3 | Won't-Fix (row). |
| D9 | "exactly one walk per brief" is at most one. | Stage 2.5 claim 59 | No code text claims it; the merge message says "at most one". |

### 🧩 Composition check

- ownfile / srules case (fact-check r3, security F1, architecture F1, api i1 3): one root, stated completely by each (D1); no composed row.
- re-read refusal text (fact-check 14/16b/27a/28, security F2, architecture F3): distinct wording defects of one change (D3), each stated.

No other multi-source co-located clusters qualified.

## Iteration 2 (Commit cf7dd447, `--loop-pass`, k=1, scope `eddfd5f9..cf7dd447`, partial)

Fact-check `code-fact-check-report-build-loop-u2c1-i2.md` (20 claims: 17 Verified, 3 Mostly accurate; a 44-input differential run found the never line's parse unchanged; the B1 mutant is caught). Critics: security, api-consistency, architecture (`*-2026-10-10-u2c1-i2.md`); performance skipped (the range adds no per-path work). Prior findings verified: A1 fixed in part (row), B1, B2, B5-B8, B12 fixed; B3, B4, B9, B10 rows present.

### 🔴 Must Fix
None.
### 🟡 Must Address
None.
### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | A failed brief re-read now let own files land with an ok verdict, the failure visible only on deny lines; it also made check_line a second writer of PATHS. | security F1; architecture F-iv | Fixed: the re-read failure refuses the verdict as a checkout refusal does; path lines still print. |
| C2 | read_settings told the form reason apart by its wording ("is not exactly") and re-parsed `none`. | architecture F-ii; api 1, 2 | Fixed: list_entries sets LIST_BAD (form, entry); none read from the empty LIST. |
| C3 | ownfile's lib comment still said it takes a lower-cased path. | architecture F-i | Fixed: it folds no case; both callers named. |
| C4 | check_line's "set -e applies" and its globals list were imprecise; the Exit: text said 1 for a mid-run stop; --help's "in lower case" read as the floor's rule too. | fact-check 5, 7, 14a; security F2; architecture F-v | Fixed in text. |
| C5 | Row 616's reason argued for moving list_entries into the lib. | architecture F-iii | Reason corrected in a new row. |

## Iteration 1 (Commit eddfd5f9, `--loop-pass`, k=1, scope `main...HEAD`, full panel)

Delivery mode: self-read. Fact-check: one opus replicate, `code-fact-check-report-build-loop-u2c1.md` (21 claims: 18 Verified, 1 Mostly accurate, 1 Stale, 1 Unverifiable, 0 Incorrect). Critics (opus, parallel): security, performance, api-consistency, architecture (test-strategy not selected: tests changed with the source). Reports: `security-review-2026-10-10-u2c1.md`, `performance-review-2026-10-10-u2c1.md`, `api-consistency-review-2026-10-10-u2c1.md`, `architecture-review-2026-10-10-u2c1.md`. No short-circuit (no behavioral red). Stage 2.5 skipped (loop pass; routed endorsements stay pending).

Considered overrides: rows 344, 345, 349, 365, 466, 467, 470, 472, 474, 517, 523, 525, 526, 530, 532, 546, 547, 555, 581, 582, 602 (the plan's U2c split routes the walk-side ones to U2c2 and 472 to U3). 523, 532, 349/474 and 517 are resolved by the diff; 530 and 546 were re-raised by their own U2c triggers (A1, B5).

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| A1 | The list-line grammar written a third time (`read_paths` beside read_settings' never parse and the lib's reader_settings); row 546's U2c trigger fired and its cap reason no longer held; the three differ on the empty spelling (bare `Paths:` vs `none`). | Coupling | architecture 1; api 1 | Fixed in part: `list_entries` parses both build-loop.sh lists, and `Paths: none` is the empty spelling (bare `Paths:` is malformed). reader_settings' copy deferred (row). |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| B1 | Own files matched lower-cased, so `Docs/Working/Plan-STEM.md` landed unlisted, against "an allowlist widens nothing by case" (plan:311). | fact-check 2a; security 2; architecture 2; api 3 | Fixed: ownfile gets the path as spelled; test case added. |
| B2 | plan:238 still said a malformed Paths: means no self-merge. | fact-check 1 (Stale); security 3; api 5 | Fixed. |
| B3 | A directory at an instruction-file name or import target lands (`src/CLAUDE.md/n.txt`). | security 1 (Low) | Deferred to U2c2 (row). |
| B4 | floor forks twice per path and runs need_root twice: 6.4 ms per path, 400 paths 3.1 s vs main 0.3 s (row 345 fired). | performance 1 (Low) | Deferred to U2c2, recorded in the plan (row). |
| B5 | The verdict chain grows (row 530); a failed brief re-read printed no path line. | architecture 3 | Slip fixed (lands only own files, every line printed); chain deferred to U3 (row). |
| B6 | Parent-shell check_line: separation now rests on each helper resetting its globals; set -e applies; a mid-run exit gives exit 1 after earlier lines. | architecture 4; security 5; api 7 | Fixed in text: check_line's comment and the Exit: line. |
| B7 | --help said the floor refuses "other briefs' working docs and reviews"; the trailing-/ difference between the two lists unstated. | api 2, 6 | Fixed in --help. |
| B8 | The never deny text did not name the glob. | api 4 | Fixed: "matched by GLOB in the Self-merge never: line of docs/dev-cycle.md". |
| B9 | Malformed Paths: only as a per-path reason; --status still self-merge. | api 5 | Deferred (row). |
| B10 | Lib prose names the caller's functions; dynamic LC_ALL scope; NAME-STEM review collision; row 470's set not the cost. | architecture 5, 6; security 4; performance 2 | Won't-Fix / Defer (rows). |
| B11 | Commit timings unverifiable; first span mixes walk variance; no same-clone main baseline. | fact-check (Unverifiable); performance 3 | The merge message cites performance's same-fixture main/branch numbers. |
| B12 | `paths_read` noun-first name. | api 8 | Fixed: `read_paths`. |

### 🧩 Composition check

- `scripts/build-loop.sh` srules/ownfile (fact-check 2a, security 2, architecture 2, api 3): distinct sources stating one defect each completely (B1); no composition needed.
- `read_paths` / read_settings (architecture 1, api 1): one root (A1), stated by architecture 1 already.

No other multi-source co-located clusters qualified.
