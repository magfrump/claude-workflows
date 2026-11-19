Commit: 70a69b59
Loop-pass short-circuit: used at b7ebe774

# Code Review Rubric

**Scope:** fix/dev-cycle-roadmap-staleness vs main (full branch, first loop pass) | **Reviewed:** 2026-11-18 | **Status: 🔴 DOES NOT PASS** — final confirming pass (k=3 fact-check, full branch, 70a69b59) found 1 red (R5); hard cap reached: decision `escalate`, then `split` on the owner's answer; R5 and A11 split off, the rest merges

Fact-check: `docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness.md` (pass 1) `…-pass2.md` (pass 2, delta b7ebe774..22f9cd8f) and `…-pass3.md` (pass 3, delta 22f9cd8f..969e8227), all k=1 loop passes; final pass replicates `…-final-r1.md`, `…-final-r2.md`, `…-final-r3.md` (k=3, merged most-severe-wins below; the critic panel did not run on the final pass: the cap gate stopped re-review once Stage 1 found a red). Pass 3 critics: `security-review-2026-11-18-roadmap-staleness.md`, `performance-review-2026-11-18-roadmap-staleness.md`, `api-consistency-review-2026-11-18-roadmap-staleness.md`. No prior overrides matched this diff.

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | An entry marked ANSWERED but not archived yet still counts as holding a roadmap item: `questions.sh open` lists live-file entries of any status, so section 5 reports `open Q-NNN` for an answered hold, the stale-hold case the branch exists to catch. | Correctness | Incorrect (fact-check claim 11b, executed) | code-fact-check | `scripts/dev-cycle.sh:466` | for-author | none | Fixed: section 5 drops IDs whose live-file Status is ANSWERED; test "section 5: an entry marked ANSWERED but not archived yet holds nothing…" |
| R2 | Pass 2: the `answered` awk matched `**Status:** ANSWERED` on any line under a heading (body text, a later `## ` section) and any status starting with ANSWERED, so an open entry could read as no hold; its comment said "the Status field". Errs the safe way. | Correctness | Incorrect (pass-2 claim 5b, executed) | code-fact-check | `scripts/dev-cycle.sh:479` | for-author | none | Fixed (57e8950a): reads Status only from the `**Needs:**` line, split on " · ", compared exactly as `questions.sh archive` does; test "section 5 reads an entry's Status only from its Needs line…" |
| R3 | Pass 3: the `answered` awk takes the first `**Needs:**` line; `parse_entries` and `archive` take the last, so an entry OPEN-then-ANSWERED still read as a hold (the R1 direction), and the comment, A4 and commit 57e8950a overstated the parity. | Correctness | Incorrect (pass-3 claims 6b, 4, 9; security informational) | code-fact-check, security-reviewer | `scripts/dev-cycle.sh:483` | for-author | none | Fixed: the last Needs line wins; parity claimed only for well-formed entries (one Needs line with all three fields, which `check` requires); test "the last Needs line of an entry wins" |
| R4 | Pass 3: a repo with no questions file printed "NOT checked" for section 5 although section 3 treats a missing file as normal, so step 6 checked nothing exactly where it is new (api-consistency 1). | Correctness | Inconsistent (High) | api-consistency-reviewer | `scripts/dev-cycle.sh:475` | for-author | none | Fixed: section 3's no-file branch sets open_ok; every item lists as unheld; test "section 5 lists every item as unheld when the repo has no questions file" |
| R5 | Final pass: with `watching.md` present but no `questions.md`, section 3's no-file branch sets open_ok without reading watches, so an item an open watch holds prints "no open entry or watch names it", and step 6 could move it; the `# nothing is open` comment is false there (all three replicates: r1 claim 7, r2 claim 7b, r3 claim 9b; executed). | Correctness | Incorrect (k=3, r2 and r3 Incorrect, r1 Mostly accurate) | code-fact-check | `scripts/dev-cycle.sh:403` | for-author | none | Split: roadmap Now item "Agent: dev-cycle section 5 follow-ups (R5, A11)" (the owner's answer in session, 2026-11-18: "Split R5 off") |

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
| A11 | Final pass, wording and tests: "which `check` requires" one Needs line is false (check accepts two; r1, r2); "first 80 characters" is 80 bytes under mawk and can split a multibyte character (all three); test 97's glob half cannot fail and nothing isolates `read -a` (all three); test 92's Next half is never exercised (r1); plan doc line 14 shows the old line shape and research line 35 says open_ok is set only when both calls succeed (Stale, all three); commit 70a69b59's "389 code lines" double-counts (313 by step 1a's command). | Docs/Tests | Incorrect/Stale/Mostly accurate (k=3) | code-fact-check | for-author | none | Split: roadmap Now item "Agent: dev-cycle section 5 follow-ups (R5, A11)" | The commit message is immutable; the rubric records 313 |

## 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | One `printf \| awk` fork per ID (performance 1, informational) | performance-reviewer | Won't-Fix: override-log row 2026-11-18 |
| C2 | A malformed entry shows its slug as the route (api-consistency 9) | api-consistency-reviewer | Won't-Fix: override-log row 2026-11-18 |

## ⏭️ Skipped Core Critics

- Pass 1 only: security-reviewer, performance-reviewer, api-consistency-reviewer, loop-pass short-circuit (behavioral red confirmed at fact-check, claim 11b). All three ran on pass 3 against the full branch.

## 🧩 Composition check

No multi-source co-located clusters qualified.

## Cap-exceeded decision (iteration 4 gate)

Decision: `escalate` (2026-11-18), to the owner in session. Owner's answer: "Split R5 off". Decision: `split`: R5 and A11 move to roadmap Now item "Agent: dev-cycle section 5 follow-ups (R5, A11)"; this branch merges without them.

### Iterations (3 completed, plus the final confirming pass)
Pass 1 short-circuited on R1; pass 2 found R2; pass 3 (full critic panel) found R3, R4 and A6-A10; the final pass found R5 and A11. Every earlier row is fixed.
### Remaining Must Fix
R5: a repo with `watching.md` but no `questions.md` shows an item an open watch holds as unheld.
### Remaining Must Address
A11: comment wording (one Needs line, 80 bytes), two weak tests, two stale working-doc lines.
### Convergence diagnosis (one sentence)
Each fix of the answered-entry parse opened a new edge case (first vs last Needs line, then the no-file branch), so the reds are shrinking in reach (the last one needs a repo state `questions.sh init` prevents) but not yet zero.
### Recommended action
Authorize one more iteration: R5's fix is to print section 5's NOT-checked line when `watching.md` exists but `questions.md` does not (no new parse), plus A11's wording and test fixes, then a final confirming pass.
