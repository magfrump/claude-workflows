Commit: ab71bce5

# Performance Review — feat/build-loop-u1d (U1d), final confirming pass

**Scope:** `git diff main...HEAD -- scripts test` at ab71bce5 (83cdb005, 6c83af2a, 07c354c5, merged with main)
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1d.md (merged, k=3, Commit ab71bce5); iteration 1's docs/reviews/performance-reviewer-review-2026-10-06-build-loop-u1d.md (Commit 83cdb005)

All numbers are measured on this host (WSL2, bash 5.2, git 2.39.5, bats 1.8.2). Probes are in `.../scratchpad/review-u1d/f-perf/`: `x-{ba465de2,83cdb005,ab71bce5}/` (`git archive` exports of main, iteration 1's commit and HEAD), `run.sh`, `wall.log`, `tap-<rev>-<round>.tap` (three suites, `bats --timing`, interleaved, 3 rounds), and `t7.log` (T7 alone, 8 interleaved runs per revision). Every run finished under `timeout`, and no probe process is still running. No tracked file was changed other than this report.

## Data Flow and Hot Paths

**Production code has not changed since iteration 1 measured it.** Here is the code-only diff from 83cdb005 to ab71bce5, with comment lines removed:
```
-  -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;  # the header, to the first non-empty line not starting with #
+  -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```
Only a trailing comment moved. The command itself is byte-identical. The merge with main brought in no change to scripts/ or test/: the merge base is ba465de2, which is main's tip. So the guard at `scripts/lib/dev-cycle-read.sh:265` is still the code iteration 1 measured: `if ! main_by_name || ! pathform "$1"; then echo error; return; fi`. pathform is pure bash (`:142-151`) and costs about 33 µs a call, about 1.7% of one main_entry call. The `git ls-tree` fork at `:267` is what dominates. Iteration 1 measured a +1.6% `--status` wall time, within noise, and that result still holds. I did not re-run the per-function bench, because no code it covers has changed. It is a cold path: a CLI run by hand or once per loop poll, over hand-written briefs.

Iterations 1 and 2 added test code only:
- T7 (`test/scripts/build-loop-read.bats:269`) gained a NUL-marker step (`:297-301`). It runs one `git hash-object --literally`, one `update-ref` and one `check` (`:274-278`: one `build-loop.sh --status` run, then an update-ref reset).
- The U1d `--status` test (`:449`) gained a later-"Status: open" commit (`d-later-open`) and a run with the caller's config pair. The `--settings` test (`:414`), T3, the constraints test and T6 each gained a few steps. The help tests in both suites now run `-h` and `--help`.

## Findings

#### F1: Suite cost of U1d at HEAD: +0.84 s per-test time over main (about 2.5%); iterations 1-2 add about 0.2 s of that, mostly T7's NUL step and the --status test's new steps

**Severity:** Informational
**Location:** `test/scripts/build-loop-read.bats:269-315` (T7), `:414`, `:441`, `:449-484`; `test/scripts/dev-cycle.bats:1322`, `:1330`
**Move:** Count the hidden multiplications (each fixture step forks git, and each assertion forks a script run)
**Classification:** Micro / Cold (test time, not production)
**Confidence:** High for the per-test deltas, Medium for the suite-total delta (the noise is about ±1.2 s)
**Baseline:** The per-test time across three suites (build-loop-read, dev-cycle, fixture-hermeticity) sums to a median of 32,904 ms on main, 34,061 ms at 83cdb005 and 33,740 ms at HEAD. These are 3 interleaved rounds each (`tap-*.tap`, 2026-10-06).
**Legibility-target:** for-orchestrator-synthesis (no fix; it answers "measure the suite cost now")

Evidence (verbatim, from the tap files and `t7.log`):
```
tap-ba465de2-{1,2,3}.tap ok=90  sum_ms=32904 / 32942 / 32510
tap-83cdb005-{1,2,3}.tap ok=94  sum_ms=34061 / 33722 / 36167
tap-ab71bce5-{1,2,3}.tap ok=94  sum_ms=34848 / 33740 / 33675
wall.log: ba465de2 34403 34378 33991 · 83cdb005 35565 35278 37663 · ab71bce5 36458 35304 35221 (ms)

T7 alone (t7.log, 8 interleaved runs, ms):
83cdb005  1164 1181 1181 1183 1152 1211 1171 1155
ab71bce5  1235 1240 1223 4113 1219 1254 1237 1216

HEAD, per test (rounds 1/2/3, ms):
#17 --settings deferred cases (U1d)        265 / 252 / 266   (83cdb005: 261 / 261 / 249)
#18 build-loop.sh -h and --help (U1d)       38 /  36 /  37   (83cdb005:  25 /  26 /  25)
#19 --status deferred cases (U1d)          474 / 449 / 475   (83cdb005: 373 / 372 / 363)
#91 dev-cycle -h and --help                 67 /  74 /  95   (83cdb005:  55 /  55 /  53)
#92 main_entry answers error (U1d)          49 /  54 /  58   (83cdb005:  49 /  52 /  51)
```
T7's NUL-marker step costs about +60 ms: the medians are 1176 ms at 83cdb005 and 1236 ms at HEAD, excluding one 4113 ms outlier. That is one extra `--status` run plus two git plumbing calls, and it does not change T7's shape. The U1d `--status` test grew by about 100 ms (median 372 → 474) for its new commit and the caller's-config run. Each help test grew by about 12-20 ms for its second invocation. All of these are linear and fixed: none scales with repo or brief count. Taken together, iterations 1 and 2 add about 0.2 s. That is smaller than the round-to-round spread of the suite totals (83cdb005 varies by 2.4 s), which is why HEAD's total median comes out below 83cdb005's. HEAD's whole cost over main is the 0.84 s difference of medians (2.5%), in line with iteration 1's 0.72 s for the four new tests plus these additions. All 94 tests pass in every HEAD round.

**Recommendation:** None. The cost is proportionate to the cases these tests cover, and splitting the compound tests would cost more in fixture setup.

No other findings. Iteration 1's F1 (pathform runs twice per brief lookup), F2 (U2's per-path `ls-tree` fork) and the redundant pathform check at `:298` are not re-filed. The code is unchanged since iteration 1 and there is no new evidence. The `:298` redundancy has since been dispositioned Won't-Fix (brief_fields' redundant pathform check), and the per-path ls-tree cost is deferred to U2.

## Endorsements

- The guard's cost is unchanged since iteration 1. Code lines in scripts/ differ from 83cdb005 only by a trailing comment on the `-h|--help` line, so iteration 1's measurement (+33 µs per pathform call, +1.6% `--status` wall time, within noise) still applies. `[read: git diff 83cdb005 ab71bce5 -- scripts, comment lines filtered; scripts/lib/dev-cycle-read.sh:142-151, :262-279]`
- main_entry's guard answers error for refused path forms before any read, and the four callers' outputs are unchanged. `[fact-check: claim 9 — Verified]`
- T7's NUL-marker step builds one fixture commit and makes one script run, with no loop. `[read: test/scripts/build-loop-read.bats:274-278, :297-301]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | U1d adds about 0.84 s (2.5%) of suite time over main; iterations 1-2 account for about 0.2 s (T7 NUL step +60 ms, --status test +100 ms, help tests +12-20 ms each) | Informational | `test/scripts/build-loop-read.bats:269`, `:449`; `test/scripts/dev-cycle.bats:1322` | High (per test) / Medium (total) |

## Overall Assessment

Nothing since iteration 1 changes the performance picture. Production code is the same apart from one comment, so the measured guard cost stands: about 33 µs per pathform call and +1.6% `--status` wall time, within noise. The new tests and the T7 NUL fixture add fixed, linear costs of about 0.2 s. U1d's total suite cost is now about 0.84 s over main (2.5% of the per-test time), and all 94 tests pass. There is nothing to fix and no further profiling is needed. From a performance standpoint, U1d is ready to land.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/performance-reviewer-review-2026-10-06-final-build-loop-u1d.md (first line `Commit: ab71bce5`), structured per the performance-reviewer skill.
- Answered: yes. I checked whether anything since iteration 1 changes the guard measurement: no, the code is unchanged apart from one comment. I measured the suite cost now: 3 interleaved rounds over main, 83cdb005 and HEAD, plus 8 isolated T7 runs per revision.
- Out of scope: the test-wording and fixture-chain findings in fact-check Claims 13, 15, 17, 18 and 19 (correctness, not performance), and U2's per-path cost (deferred).
- Escalate: none.
