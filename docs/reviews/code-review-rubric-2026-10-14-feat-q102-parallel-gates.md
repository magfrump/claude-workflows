Commit: b2608086

# Code Review Rubric: feat/q102-parallel-gates

**Scope:** `main...HEAD` (full branch, first pass) · **Delivery mode:** inline (shared preamble file with the diff and the merged fact-check rows; ~19 KB) ·
**Fact-check:** k=3, merged most-severe-wins: `docs/reviews/code-fact-check-report-q102.md` (replicates `-r{1,2,3}-q102.md`), 79% verdict agreement

## Iteration 1 (65c931e6): full panel

Fact-check: 19 clusters; 13 Verified, 4 Mostly accurate, 2 Incorrect (medium, doc-only: the gate timing). No high-confidence Incorrect, so no gate pause. Critics: security (1 Medium low-confidence, 1 Low, 1 Informational), performance (1 Medium, 2 Low, 2 Informational), api-consistency (1 Inconsistent, 3 Minor). Architecture, test-strategy, tech-debt, dependency and UI critics not triggered (tests changed; 5 files; no structural change). Health check passed at 65c931e6 (6:20, 1812 tests).

## 🔴 Must Fix

None.

## 🟡 Must Address

| ID | Finding | Location | Source | Status |
|---|---|---|---|---|
| A1 | "about 2.5 min against 7.5 min serial" attributed to the gate; the figures are one full-suite run's (Q-090), and the gate's two runs took 171 s + 154 s | `workflows/pr-prep.md:331`, 65c931e6 body, `health-check.sh` check 5 comment | fact-check Claims 1, 2, 4; perf; api F4 | Fixed in db341cb9 (text cites Q-090 as a full-run figure and the measured gate split); 65c931e6's body in override log |
| A2 | `RUN_TESTS_JOBS` carries run-tests.sh's prefix but only health-check.sh reads it; `RUN_TESTS_JOBS=8 run-tests.sh` silently runs serially | `health-check.sh` check_bats | api F1 (Inconsistent) | Fixed: renamed `HEALTH_CHECK_JOBS` |
| A3 | The fast pre-gate became the longer run: build-loop-check.bats (fast, 119.5 s solo) bounded it; the gate floor was ~261 s | `test/scripts/build-loop-check.bats:2` | perf F1 (Medium), F2; override row 182 trigger | Tried (db341cb9: retag to slow), measured no gain (311 s against 326 s) and a cross-file hazard; reverted in b2608086. Deferred in the override log with a restated trigger |
| A4 | install-host T92 (hidden-cwd guard, Q-064) skipped after 5 s and a skip passes the gate; parallel load makes it likelier | `test/install-host.bats` T92 | security F1 (Medium, low confidence) | Fixed: waits up to 60 s on a marker written after prctl; skips only when the hide does not work |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| C1 | Header "any other value fails" misses empty = default | fact-check Claim 3, api F2 | Fixed |
| C2 | An inherited `BATS_NUMBER_OF_PARALLEL_JOBS` makes `1 = serial` false (executed: 2 s against 4 s) | security F2 (Low) | Fixed: runner unsets it and `BATS_NO_PARALLELIZE_ACROSS_FILES`; new run-tests.bats test fails without the fix |
| C3 | The report-dependent gate-5 test does not strip the variable; fails under an ambient bad value | fact-check Claim 5 (executed), security F3 | Fixed |
| C4 | Default 8 not capped at the core count | perf F3 (Low) | Fixed: min(8, nproc) when unset or empty; an explicit value is not capped |
| C5 | The `--jobs` regex is copied in two scripts | api F3 (Minor) | Fixed: cross-reference comments in both |
| C6 | Row 181's 105 s baseline is stale (now 141 s solo, 1.09× in-run) | perf F4 | Re-baselined in the override log |
| C7 | Row 183 (serial `bats --count`) now runs twice per gate, ~10 s, 3% | perf F5 | Stays deferred |

## Considered overrides

Rows 93, 181, 182, 183 matched (see the shared preamble); 182's trigger fired (A3); 181 re-baselined (C6); 183 unchanged (C7); 93's watch item is A4's context.

## Composition check

One qualifying cluster: `health-check.sh` check 5 comment + `pr-prep.md:331` (fact-check, perf, api): one root, "the full-run figure is quoted as the gate's", already stated by fact-check Claim 1; distinct composition not needed.

## ⏭️ Skipped Core Critics

None.

## Confirming pass (57f37e3a, range 65c931e6..57f37e3a)

k=1 fact-check (23 claims: 17 Verified, 6 Mostly accurate, 0 Incorrect), security (1 Low, 3 Info), performance (2 Low, 2 Info), api-consistency (1 Minor, 2 Info). Gate at db341cb9 failed only on SC1007 in the new test (fixed 57f37e3a).

| ID | Finding | Source | Status |
|---|---|---|---|
| K1 | The retag put cc-isolated's real-/proc install.sh tests in the slow run beside T92's hidden process (reproduced: they refuse while it lives) | security F1 (Low) | Fixed: retag reverted (b2608086) |
| K2 | The retag saved ~15 s, within noise; four heavy files then shared the slow run | perf F1, F2; fact-check escalation | Reverted; override row rewritten |
| K3 | Retag contradicted run-tests.sh's per-test definition of fast | api F1 (Minor) | Moot after the revert |
| K4 | Gate-5 tests assumed ≥8 cores (default --jobs 8 unstubbed) | security F4 | Fixed: helper always stubs nproc (16 by default) |
| K5 | nproc past bash's integer range wrapped | security F3 | Fixed: regex `{0,2}` |
| K6 | T92's skip also fires on a failed prctl or a ptrace-capable reader; no teardown kill | security F2, fact-check C11/C18 | Fixed: comment and override row name all cases; teardown kills from a pid file |
| K7 | Wording: "at most nproc", "bats reads these … or alongside it", archive "both bounded", "~51 s" as measured, OMP_NUM_THREADS | fact-check C3/C8/C14/C16, api F2/F3, perf F4 | Fixed |
| K8 | Per-file start/end times are not recorded, so the restated triggers cannot be read | perf F3 (Info) | Named in row 182's trigger |

Narrow check of b2608086: see `narrow-check-2026-10-14-q102-b2608086.md`.


## Narrow check (b2608086) and gate

Narrow check: 0 regressions; N1 (Low, run-tests.sh comment on BATS_NO_PARALLELIZE_ACROSS_FILES) and 6 wording items fixed in d8f08694.

Gate at b2608086: red, 1 failure (build-loop-merge.bats 1061), passes alone (`--failed`). Gate at d8f08694: red, 2 failures (build-loop-check.bats 968, build-loop-merge.bats 1059), load 18-20. All three are one class: the gate lib's ancestor listing (`scripts/lib/dev-cycle-read.sh`, `find -H "${tops[@]}" -maxdepth 1`) exits non-zero when an entry vanishes between readdir and stat, and the walk fails closed. The vanished paths were `/tmp/bats-run-*/bats.PID.out` (other test files' output under `--jobs`) and `/tmp/tmp.*` (another session's temp file). Not caused by this branch's code; made likelier by the parallel default. The fix is in GATE_CODE: Q entry filed (`lib-ancestor-listing-vanish-race`).

Status: not merged — waiting on that Q entry. No Must Fix open on this branch's own changes.
