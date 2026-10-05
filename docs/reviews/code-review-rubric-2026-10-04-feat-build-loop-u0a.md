Commit: 497c8cb5
Loop closed at ac96cf12
# Code Review Rubric

**Scope:** full unit range; iterations 1–2 `--loop-pass` (k=1), iteration 3 the final confirming pass (k=3, full panel) at 497c8cb5; its findings fixed in the commits up to ac96cf12 | **Reviewed:** 2026-10-04 – 2026-10-05 | **Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation

Loop outcome: exit condition 1 at the end of iteration 3. Iteration 3's fixes were verified by the tests (mutation-checked), `lite-review.py --mode fix-drift` and `scripts/health-check.sh`, not by another critic panel (that would be iteration 4).

Reports: `code-fact-check-report-build-loop-u0a.md`, `security-reviewer-review-2026-10-04-build-loop-u0a.md`, `performance-reviewer-review-2026-10-04-build-loop-u0a.md`, `api-consistency-reviewer-review-2026-10-04-build-loop-u0a.md`, `architecture-review-review-2026-10-04-build-loop-u0a.md`. Deviations from the skill: one critic agent per role (and one fact-check agent per replicate) reviewed all three stacked units, writing one report per unit; agents read the skill files themselves; in iteration 2 the critics ran in parallel with the fact-check instead of after it; Stage 2.5 was not run. Iteration 2 reports: `*-2026-10-05-build-loop-<unit>.md`; final pass: `*-2026-10-05-final-build-loop-<unit>.md` and `code-fact-check-report-build-loop-<unit>{,-r1,-r2,-r3}.md`.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `build-loop.sh` named as an existing sharer of the lib (`scripts/dev-cycle.sh:83`, lib `:2`) | Docs | Fact-check Incorrect (comment) | Fact-check | for-author | — | ✅ Fixed in e97eefce | "planned scripts/build-loop.sh" |
| A2 | Commit Notes: "the plan's lib list names only the import walk"; plan :187 lists check_fix's predicate | Docs | Fact-check Incorrect (commit message) | Fact-check | for-author | — | ✅ Fixed: message reworded (d7ea20b9) and plan amended (U0c fix) | — |
| A3 | Lib file checks fail open when ROOT_REAL is unset (blocker runs in `$(...)`; set -u does not catch it) (lib `:63-92`) | Security | Low (Medium once build-loop.sh sources the lib) | security-reviewer | for-author | — | ✅ Fixed in e97eefce (need_root; rawfile/plaindir fail closed; new test) | — |
| A4 | Header Exit line omits the missing-lib exit 1 (`scripts/dev-cycle.sh:75-77`, also --help) | Docs | Fact-check Stale | Fact-check | for-author | — | ✅ Fixed in e97eefce | — |
| A5 | need_root accepted a ROOT_REAL that is not the current directory (walk cached an empty set) — raised on U0c, fixed where need_root lives | Security | Low | security-reviewer (iter 2) | for-author | — | ✅ Fixed in 497c8cb5 (ROOT_REAL == pwd -P; test + mutation) | — |
| A6 | Header said every check exits without ROOT_REAL; rawfile/plaindir/blocker return | Docs | Fact-check Mostly accurate (iter 2) | Fact-check | for-author | — | ✅ Fixed in 497c8cb5 | — |
| A7 | need_root comment: "set -u fires there" — it does not since the ${ROOT_REAL:-} guards (3/3 replicates) | Docs | Fact-check Incorrect (comment) | Fact-check k=3 (final) | for-author | — | ✅ Fixed in ac96cf12 | — |
| A8 | Header: "read nothing as plain" holds only while ROOT_REAL is unset | Docs | Fact-check Incorrect (r3) / Mostly accurate (r1) | Fact-check k=3 (final) | for-author | — | ✅ Fixed in ac96cf12 | — |
| A9 | Commit message 497c8cb5 repeated the inverted set -u remark | Docs | Fact-check Incorrect (commit message, r3) | Fact-check k=3 (final) | for-author | — | ✅ Fixed: message reworded before merge | — |
| A10 | need_root accepted a subdirectory as the root (checks resolve docs/x as sub/docs/x) | Security | Informational here; Low in U0b/U0c | security-reviewer (final) | for-author | — | ✅ Fixed in ac96cf12 (.git at cwd; test + mutation) | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | "returns only in the child" omits the DEV_CYCLE_SCRUBBED case | Fact-check | Mostly accurate | for-author | — | Fixed |
| C2 | Moved comments say "the digest" / "section 8" in the lib | Fact-check | Mostly accurate | for-author | — | Fixed |
| C3 | T29 name "runs nothing" vs stubs only git and perl | Fact-check | Mostly accurate | for-author | — | Fixed (renamed) |
| C4 | "moved verbatim": the wrapper was rewritten | Fact-check | Mostly accurate | for-author | — | Fixed (message reworded) |
| C5 | Shared DEV_CYCLE_SCRUBBED marker undocumented in the lib header | architecture-review, api-consistency | Informational | for-author | — | Fixed |
| C6 | Lib globals as interface; U1 should test sourcing from build-loop.sh's side | architecture-review | Informational | for-author | — | Deferred (U1; override-log row) |
| C7 | Header doesn't say a lib change runs both suites; T29/T30 live in dev-cycle.bats | architecture-review | Informational | for-author | — | Deferred (U1; override-log row) |
| C8 | Lib header shape: `#!/usr/bin/env bash`, no Functions index or execution guard | api-consistency | Informational | for-author | — | Shebang fixed; index/guard Won't-Fix (override-log row) |
| C9 | ~1 ms fixed start-up cost: parent now sources the lib before re-exec | performance-reviewer | Informational | for-author | — | Won't-Fix (override-log row) |
| C10 | D6 hash-checks each file before running it; the lib is a second file sourced later (check-to-use gap) | security-reviewer | Informational (orchestrator) | for-author | — | Deferred (U3b, D6 snippet; override-log row) |
| C11 | rawfile/plaindir test half passed with the ${ROOT_REAL:-} guard removed | Fact-check + security (iter 2) | Informational | for-author | — | Fixed in 497c8cb5 (set -u; mutation checked) |
| C12 | need_root forks $(pwd -P) per call (~324 µs) | performance-reviewer (final) | Informational | for-author | — | Won't-Fix (override-log row) |
| C13 | Header does not say what the lib sets (SKIPPED/SKIP_AT) | api-consistency (final) | Informational | for-author | — | Fixed in ac96cf12 |
| C14 | Commit 32b9ae0e's pre-fix wording | Fact-check (iter 2, final) | Mostly accurate | for-author | — | Won't-Fix (override-log row) |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/dev-cycle` / 2026-09-29 | `scripts/dev-cycle.sh` parses `questions.sh open`'s column output (architecture #6) | Minor → Won't-Fix | no machine-readable mode | Inherited: that code stays in dev-cycle.sh, unchanged by the move. |
| `feat/dev-cycle` / 2026-09-29 | Raw control characters reach the terminal (security #4) | Informational → Won't-Fix | same exposure as `git log`; since superseded by the scrub | Inherited: the scrub moved verbatim. |

---
## ✅ Confirmed Good

None recorded as ✅ rows: the critics' routed endorsements were not put through a Stage-2.5 submitted-claims pass, so they stay pending execution verification. Executed evidence instead: the k=3 fact-check verified byte-identical digest and check-mode output against main, verbatim moves, and that every new test fails when its guard is removed.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (Contextual: architecture-review ran (module structure changed); test-strategy not triggered (tests changed with the source); tech-debt-triage, dependency-upgrade, ui-visual-review not triggered.)

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/lib/dev-cycle-read.sh:1-12` | FC (build-loop.sh claim), arch C5, api C5 | distinct defects: wording vs contract gap, each stated whole |
| 2 | `scripts/lib/dev-cycle-read.sh:60-92` | security A3, FC C2 | distinct defects: fail-open guard vs comment location |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
