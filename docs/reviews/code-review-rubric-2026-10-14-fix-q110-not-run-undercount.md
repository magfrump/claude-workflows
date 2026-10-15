Commit: 16ce27bf
Loop closed at 16ce27bf

# Code Review Rubric

**Scope:** fix/q110-not-run-undercount vs main (70aa3a78, f84a9dfa, 40f524df, 4b775841, 16ce27bf; code: 3 files, 27 lines) | **Reviewed:** 2026-10-14 | **Status: ✅ PASSES REVIEW** — 0 red, 0 amber open; single-sample review; absence of findings is not an attestation

Iteration 1 of 3 at f84a9dfa (full scope: code-fact-check k=3, security, performance, api-consistency, Stage 2.5) found 0 red and 4 amber; 4b775841 fixed or withdrew them. Iteration 2 of 3 at 16ce27bf was the final confirming pass (full scope, k=3, all core critics, no `--loop-pass`). Delivery mode both passes: self-read (agents read a shared brief and ran their own `git diff`; the ~4 KB diff fit the inline budget, so this was a convenience deviation, not a degrade). Stage 2.5 on the confirming pass was not dispatched: the routed endorsements restate Stage-1 executed verdicts (clusters 3, 10, 21) or a timing claim no row relies on, so the ✅ rows below rest on Stage-1 verdicts only.

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|

None, in either iteration.

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or a **qualifying author note** (a discoverable TODO or
a concrete revisit trigger; see "Qualifying author note" in
`skills/code-review/references/rubric.md`).

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | i1: commit 70aa3a78's Notes say "test/scripts/run-tests.bats and others call it too"; only run-tests.bats (`test/scripts/run-tests.bats:67,84,473,505`) starts the real runner besides eval-helpers-gating.bats | Documentation | Mostly Accurate | Fact-check (i1 Claim 1; i2 Claim 3, 3/3) | for-author | — | Fixed | Corrected in 4b775841's commit body (the branch merges with its history). |
| A2 | i1: commit 70aa3a78's Notes say "no suite reads the variable from its environment"; `test/scripts/health-check.bats:488`'s stub reads one health-check.sh sets | Documentation | Mostly Accurate | Fact-check (i1 Claim 2; i2 Claim 4, 3/3) | for-author | — | Fixed | Corrected in 4b775841's commit body. |
| A3 | i1: header "never see it" (`scripts/run-tests.sh:19-23`) overclaimed: a caller's `PARALLEL_ENV` code runs before each parallel job and can set the variable | Documentation | Mostly Accurate | security-reviewer endorsement, qualified by fact-check (submitted Claim 23b) | for-author | — | Fixed | 4b775841: header and test name now say "do not inherit the caller's value"; i2 fact-check cluster 3 Verified 3/3. |
| A4 | i1: performance endorsement "parallel suites could race on the single file" refuted: the overwrite was sequential (`--no-parallelize-within-files`) | Performance | Incorrect (review-artifact claim only) | performance-reviewer endorsement, refuted by fact-check (submitted Claim 25b) | for-author | — | Withdrawn | Lives only in the i1 review artifact; i2 performance critic did not re-raise it. |
| A5 | i2: commit 70aa3a78's body "so neither bats nor anything a suite starts can see the caller's path" carries the same overclaim as A3 | Documentation | Mostly Accurate | Fact-check (i2 Claim 2; r1+r2 MA, r3 Verified) | for-author | — | Fixed | 4b775841's body states the correction for this guarantee ("What the runner guarantees is that the caller's value is not inherited"); r1 noted it does not quote this sentence, so the merge message should repeat the correction. |
| A6 | i2: this rubric's i1 text cited the write at `:359-360` and the unset range `:359-368`; at HEAD they are `scripts/run-tests.sh:360-361` and `:369` | Documentation | Stale | Fact-check (i2 Claim 1; r1 Stale, r2 MA) | for-author | — | Fixed | This update restamps the rubric and cites HEAD lines. |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | i1: header "never see it" read as a ban on the variable; a suite can pass its own value (`test/skills/eval-helpers-gating.bats:50,63,82`) | api-consistency-reviewer (i1 F1) | Informational | for-author | — | Fixed (4b775841) |
| C2 | i2: under `--jobs`, caller-supplied `PARALLEL_ENV` code can set `RUN_TESTS_NOT_RUN_FILE` inside the suites (`scripts/run-tests.sh:369`, `:429-436`); same user, nothing gained | security-reviewer (i2) | Informational | for-author | — | Won't-Fix |
| C3 | i2: FP-173's `ref:70aa3a78` is the log's only 8-character SHA ref; 165 others use 7 (`docs/thoughts/failure-patterns.md:315`) | api-consistency-reviewer (i2) | Informational | for-author | — | Won't-Fix |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. (The rows naming `scripts/run-tests.sh` — locale fallback, run-log pruning, GNU/bash features, `--failed` limits, lock, `--jobs` ordering — concern unrelated runner features.)

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| A nested runner can no longer overwrite the caller's NOT RUN count | ✅ Confirmed | Executed 3/3 in both iterations: main's runner leaves the caller's file at 4 (reproduction) / 99 (stub write), HEAD's at 0 / 4, stub sees `unset`, serial and `--jobs 2` (`code-fact-check-report-q110-final.md` clusters 10-11; i1 submitted Claim 23a with real GNU parallel) | code-fact-check (executed) | for-orchestrator-synthesis |
| The regression test is not vacuous | ✅ Confirmed | Fails on main's runner at `test/skills/eval-helpers-gating.bats:84` — `[ "$(cat "$T/nr")" = 4 ]`; 7/7 on HEAD's (final cluster 21, executed 3/3) | code-fact-check (executed) | for-orchestrator-synthesis |
| The unset precedes every bats start and nothing after it needs the variable | ✅ Confirmed | `rg -n RUN_TESTS_NOT_RUN_FILE scripts/run-tests.sh` → :19, :321, :360, :361, :369; `bats --count` :442 and `exec bats` :453 come after :369 (final cluster 3, 3/3; i1 submitted Claim 24 covers the sourced helpers) | code-fact-check (static, scope covers the enumeration) | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. No contextual critic matched (tests changed with the source, 3 code files, no dependency, UI or structural change).

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/run-tests.sh:19-23` | A3 (fact-check submitted 23b), C1 (api-consistency i1 F1) | distinct defects: each fragment states the overclaim and its fix completely; one rewording resolved both |
| 2 | `scripts/run-tests.sh:369`, commit 70aa3a78 body | A5 (fact-check i2 Claim 2), C2 (security i2) | distinct defects: C2 is the mechanism A5's sentence overlooks, and both are already stated in full; no shared root beyond A3's, which 4b775841 fixed |

---

### Escalations (orchestrator)

- `docs/working/questions.md` Q-110 is still OPEN and cites `scripts/run-tests.sh:356-357` (off by one even on main, where the write is :357-358); at HEAD the write is `:360-361` and the unset `:369`. Owned by the orchestrator; not edited on this branch.
- Runner exits before the write (lock held, no matched files, bad tag, usage errors) leave the caller's file unwritten, so `_not_run_count` reads 0. Every such exit is non-zero and health-check fails the gate on it, so the zero never hides suites behind a pass. Pre-existing; no action.

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
