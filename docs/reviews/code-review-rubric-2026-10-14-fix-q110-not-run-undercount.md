Commit: f84a9dfa

# Code Review Rubric

**Scope:** fix/q110-not-run-undercount vs main (70aa3a78, f84a9dfa; 3 files, 25 code lines) | **Reviewed:** 2026-10-14 | **Status: 🟡 fixes landed in 4b775841, pending the confirming pass** — 0 red item(s); 4 amber items fixed or withdrawn

Iteration 1 of 3 (full scope, not a loop pass: code-fact-check k=3 merged, security, performance and api-consistency critics, Stage 2.5 submitted-claims pass). Delivery mode: self-read (each agent read the shared brief at `/home/node/.claude/jobs/00bcf178/tmp/q110/shared-brief.md` and ran its own `git diff`; the diff is ~3.6 KB, well inside the inline budget, so this was a convenience deviation, not a budget degrade).

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|

None.

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or a **qualifying author note** (a discoverable TODO or
a concrete revisit trigger; see "Qualifying author note" in
`skills/code-review/references/rubric.md`).

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Commit 70aa3a78's Notes say "test/scripts/run-tests.bats and others call it too"; only run-tests.bats (`test/scripts/run-tests.bats:67,84,473,505`) starts the real runner besides eval-helpers-gating.bats | Documentation | Mostly Accurate | Fact-check (Claim 1, 3/3 replicates) | for-author | — | Fixed | Corrected in 4b775841's commit body (the branch merges with its history). |
| A2 | Commit 70aa3a78's Notes say "no suite reads the variable from its environment"; `test/scripts/health-check.bats:488`'s stub runner reads one health-check.sh sets | Documentation | Mostly Accurate | Fact-check (Claim 2, r3) | for-author | — | Fixed | Corrected in 4b775841's commit body: no suite relies on inheriting the runner's value. |
| A3 | Header "the suites (and any runner a suite starts) never see it" (`scripts/run-tests.sh:19-22`) overclaims: a caller's `PARALLEL_ENV` code runs before every parallel job and can set the variable (executed, run D) | Documentation | Mostly Accurate | security-reviewer endorsement, qualified by fact-check (submitted Claim 23b) | for-author | — | Fixed | 4b775841 rewords the header (and the test name) to "do not inherit the caller's value". |
| A4 | Performance endorsement "on the old runner, parallel suites that each nested the runner could race on that single file" is refuted: only eval-helpers-gating.bats inherited the path, and `--no-parallelize-within-files` keeps its tests serial; the overwrite was sequential | Performance | Incorrect (high, review-artifact claim only) | performance-reviewer endorsement, refuted by fact-check (submitted Claim 25b) | for-author | — | Withdrawn | The claim lives only in the review artifact; no code or committed doc repeats it. Nothing to change. |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Header "never see it" reads as a ban on the variable; a suite can still pass its own value (`test/skills/eval-helpers-gating.bats:50,63,82`) | api-consistency-reviewer F1 | Informational | for-author | — | Fixed (4b775841) |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. (The rows naming `scripts/run-tests.sh` — locale fallback, run-log pruning, GNU/bash features, `--failed` limits, lock, `--jobs` ordering — concern unrelated runner features.)

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| A nested runner can no longer overwrite the caller's NOT RUN count | ✅ Confirmed | Executed by all three replicates and the submitted-claims pass: main's runner leaves the caller's file at 4 (reproduction) / 99 (stub write), HEAD's at 0 / 4; stub sees `unset` (`code-fact-check-report-q110.md` clusters 17-18; submitted Claim 23a, serial, `--jobs 2` and real GNU parallel) | code-fact-check (executed) | for-orchestrator-synthesis |
| The regression test is not vacuous | ✅ Confirmed | Fails on main's runner at `test/skills/eval-helpers-gating.bats:84` — `[ "$(cat "$T/nr")" = 4 ]`; passes on HEAD's (cluster 14, executed 3/3) | code-fact-check (executed) | for-orchestrator-synthesis |
| Nothing after the unset needs the variable | ✅ Confirmed | `rg -n RUN_TESTS_NOT_RUN_FILE scripts/run-tests.sh test/lib/hermetic-env.bash test/skills/runner-contract.bash` → header, gating comment, :359-368 only (submitted Claim 24) | code-fact-check (static, scope covers the enumeration) | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. No contextual critic matched (tests changed with the source, 3 files, no dependency, UI or structural change).

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/run-tests.sh:19-22` | A3 (fact-check submitted 23b), C1 (api-consistency F1) | distinct defects: each fragment states the overclaim and its fix completely; one rewording resolved both |

---

### Escalations (orchestrator)

- `docs/working/questions.md` Q-110 is still OPEN and cites `scripts/run-tests.sh:356-357`; the write is now at :359-360 (fact-check r1). Owned by the orchestrator; not edited on this branch.
- Early `exit 1` paths before the write leave the caller's file unwritten, so `_not_run_count` reads 0 (fact-check r3). Security traced it: every such exit is non-zero and health-check fails the gate on it, so the zero never hides suites behind a pass. Pre-existing; no action.

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
