Commit: 65c931e

# Performance Review: feat/q102-parallel-gates (Q-102 [1], parallel gate 5)

**Scope:** `git diff main...HEAD` at 65c931e6 (health-check.sh gate 5, health-check.bats, pr-prep.md, roadmap, Q-102 archive note)
**Date:** 2026-10-14
**Based on:** Stage-1 merged code-fact-check (shared review context, `/home/node/.claude/jobs/00bcf178/tmp/shared.md`); override-log rows 93, 181, 182, 183

## Data Flow and Hot Paths

Gate 5 of `scripts/health-check.sh` (`check_bats`, :405-436) now runs `run-tests.sh --fast --jobs N` and then, only when that is green, `run-tests.sh --slow --jobs N`, with N = `${RUN_TESTS_JOBS:-8}`. The diff's own code is cold: one regex check and two extra arguments. What matters is downstream. Each run hands bats `--jobs N --no-parallelize-within-files`, and GNU parallel then starts whole files in path order as slots free up. Each run's wall time is bounded below by its slowest file plus that file's start delay. The runs are sequential, so the gate pays two critical paths. The path is hot in the way that counts here: it is the gate of every pr-prep and build loop, run many times a day.

Data sizes at 65c931e6: 118 fast-tagged files and 15 slow-tagged files (`rg -l "^# @category fast|slow"`). This host has 16 cores (`nproc`).

Measurements used below:

- **Gate run on this branch, from the run-log mtimes in `.bats/.bats/run-logs/`:** fast run 19:49:27 to 19:52:18 UTC (171 s), slow run 19:52:20 to 19:54:54 UTC (154 s). The host was at load ~5 with review agents running.
- **Solo timings taken in this review with `timeout bats <file>`, at load 4.7 to 9.4:**
  - `test/scripts/build-loop-check.bats`: 119.5 s, 146 tests.
  - `test/cc-isolated-functions.bats`: 84.9 s, 173 tests. Three tests failed on a locale I did not pin; the timing is still representative.
  - `test/install-host.bats`: 141.3 s, 92 ok, with `LC_ALL=C.UTF-8`.
  - `bats --count`: 8.6 s for the fast files and 1.3 s for the slow files.
- **Not timed:** `test/scripts/health-check.bats`. Its nested health-check runs would take the repository-wide `health-check.lock` in the common git dir, which other sessions' gates share.

All arithmetic below was done with python3.

## Findings

#### 1. The "fast" run is now the longer run. A fast-tagged 120 s file sets the gate's first critical path, and the split pays two critical paths in a row

**Severity:** Medium
**Location:** `scripts/health-check.sh:420` and `:428` (two sequential runs); `test/scripts/build-loop-check.bats:2` (`# @category fast`)
**Move:** Hidden multiplication (two serial critical paths); size of N (per-file, not per-test)
**Classification:** Macro (the wall-time floor is set by structure, not by a constant factor) / Hot path (every gate)
**Confidence:** High (the mechanism and both run times are measured) / Medium (the size of the fix is projected)
**Baseline:** fast run 171 s and slow run 154 s at `--jobs 8`, this branch's gate run, 2026-10-14 (run-log mtimes); `build-loop-check.bats` alone 119.5 s, measured in this review
**Legibility-target:** for-author

**Evidence:**

From the fast run's log (`.bats/.bats/run-logs/2026-10-14 19:49:27 UTC.log`), last log line per file:

```
1465 173 test/cc-isolated-functions.bats
1514 146 test/scripts/build-loop-check.bats
```

From `scripts/run-tests.sh:23`:

```
#   --fast    Run only fast tests (pure function tests, <1s each)
```

`build-loop-check.bats` meets the per-test letter of "fast" (119.5 s / 146 ≈ 0.82 s per test). Under `--jobs` the cost that counts is per file, though, and this one file takes 119.5 s alone. It was the last file to finish in the fast run. So the fast run, whose job is to be a cheap early signal before the slow run, took 171 s against the slow run's 154 s. Running fast first no longer saves time when fast fails.

The two runs are sequential, so the gate's BATS floor is the sum of two slowest files: build-loop-check (119.5 s) plus install-host (141.3 s), about 261 s. No ordering or `--jobs` value can push it below that. A single `--all` run's floor is about 141 s. Q-090's single full run at `--jobs 8` took 140 s.

The measured gate took 325 s of BATS against Q-090's 451 s serial full run. That is a 1.39x speedup, not the ~3x the comments cite. This builds on fact-check Claims 1 and 2 (Incorrect). The serial gate time itself was never measured, so 1.39x is a comparison across runs on a loaded host.

**Recommendation:** Retag `build-loop-check.bats` as slow. Also consider `cc-isolated-functions.bats` (84.9 s alone, the next slowest fast file). Two tag lines change and the runner does not. The fast run's floor then falls to the next slowest fast file, which is unmeasured. The slow run takes 17 files in 8 slots with four files of roughly 85 to 141 s, and its floor stays about install-host's 141 s, provided the heavy files start early (see Finding 2). Projected gate BATS: about 180 to 200 s, against 325 s now (speculative until re-measured). Another option is to keep the tags and treat "fast" as "fail-first" rather than "cheap". Either way, record one gate-run timing after the change. The cost is an open-ended 2.4 min per gate.

#### 2. Override-log row 182 (longest-first) fires, and it is worth about 50 s in the fast run and close to nothing in the slow run

**Severity:** Low
**Location:** `scripts/run-tests.sh` candidate listing (path-sorted `files`, :411-416 hands them to bats in that order); fired by `scripts/health-check.sh:408`
**Move:** Find the work that moved to the wrong place (critical file dispatched late)
**Classification:** Micro-to-Macro (a fixed start delay on the critical path) / Hot path (every gate)
**Confidence:** Medium
**Baseline:** fast run 171 s at `--jobs 8`, this branch's gate run, 2026-10-14; `build-loop-check.bats` alone 119.5 s, measured in this review
**Legibility-target:** for-author

**Evidence:**

From `docs/reviews/override-log.md:182`:

```
Files start in path order, not longest first (`scripts/run-tests.sh` candidate listing) (performance F2) | 🟢 Consider | Defer | Worth ~10–15 s per the critic; ordering needs per-file timings kept current. Revisit if `--jobs` becomes the default in health-check.
```

This branch makes `--jobs` the default, so the trigger has fired.

**Fast run.** `build-loop-check.bats` is file 36 of 118 in sorted path order. If its in-run time matched its solo time, it started about 51.5 s into the 171 s run (171 − 119.5). Started first, the fast run would fall to about 120 to 125 s. That saves about 50 s per gate, roughly 3 to 5 times the row's ~10 to 15 s estimate.

**Slow run.** Ordering buys about 0 s here. `install-host.bats` is file 4 of 15 and starts at t=0. Its last test is the run's last log line, 298 of 298, and the run took 154 s against its 141.3 s solo time. `health-check.bats` is file 9 of 15. It needs a slot, but the first files finish early: `archive-working-docs.bats` and `round-log-functions.bats` hold log lines 1 to 3. So it starts within seconds.

**Recommendation:** Do it now, but in its cheapest form. Retagging under Finding 1 removes the fast-run delay with no runner change. If the tags stay, use the Q-090 review's form: when `jobs > 1`, a short named list of known-slow files goes to the front of `files`. Today that list is `build-loop-check.bats`, `install-host.bats`, `health-check.bats` and `cc-isolated-functions.bats`. This is not a timing database. Its upkeep cost is a stale list, which only costs time and never correctness. A general longest-first sort with kept timings stays deferred. The numbers do not justify it: the only file it would move is already identified.

#### 3. Default `--jobs 8` is not capped at the host's core count

**Severity:** Low
**Location:** `scripts/health-check.sh:408`
**Move:** Price the deployment environment
**Classification:** Micro (a per-run contention factor) / Hot path (every gate) on hosts with fewer than 8 cores
**Confidence:** Medium (16 cores) / Low (smaller hosts)
**Baseline:** no baseline available — flagged as speculative (no gate has been timed on a host with fewer than 8 cores)
**Legibility-target:** for-author

**Evidence:**

From `scripts/health-check.sh:408`:

```
    local jobs="${RUN_TESTS_JOBS:-8}"
```

From `scripts/run-tests.sh:89-90`:

```
# The slowest file bounds the speedup (measured on 16 cores: --jobs 16 was
# only about 5% faster than --jobs 8).
```

**On this 16-core host, 8 is right.** The run is floor-bound by one file per run (Finding 1). More slots do not move the floor, and the header's 5% figure agrees. With 8 slots, the other files finish well inside the floor.

**On a 4-core host**, 8 jobs oversubscribe the CPU 2x for no throughput gain. They also stretch the wall-clock windows in install-host's `sleep`-timed pty tests and raise the process count that `install.sh`'s `/proc` scan walks (the Q-090 review's F1 and F4). Both are flake risks rather than slowdowns. `run-tests.sh` caps jobs at the file count only (`:412`).

**Recommendation:** Default to `min(8, nproc)`, for example `${RUN_TESTS_JOBS:-$(( $(nproc) < 8 ? $(nproc) : 8 ))}`, keeping the explicit override. Note that `nproc` reports CPU affinity, not a cgroup CPU quota. If containers here are quota-limited, that is a verify item. The cost is one line, and on this host the value stays at 8.

#### 4. Row 181's baseline is stale, and its trigger is now ambiguous across two runs

**Severity:** Informational
**Location:** `docs/reviews/override-log.md:181`
**Move:** Find the contention point (`install.sh`'s `/proc` scan under `--jobs`)
**Classification:** Macro (the scan grows with the process count) / Hot path, kept at Informational because it is under threshold
**Confidence:** High
**Baseline:** `install-host.bats` alone 141.3 s at load ~5, measured in this review, 2026-10-14; inside the slow `--jobs 8` run about 154 s (the run's end, since its last test is the last log line)
**Legibility-target:** for-author

**Evidence:**

From `docs/reviews/override-log.md:181`:

```
Measured instead of changed: install-host.bats alone 105 s, full suite at `--jobs 8` 179 s against 451 s serial, so the slowdown is not what bounds the run today. Revisit if a `--jobs` run's wall time exceeds 1.5× install-host.bats' solo time, or install-host flakes under `--jobs` (then stub the scan by default like `pgrep`).
```

**Against today's solo time,** install-host's in-run slowdown is 154 / 141.3 ≈ 1.09x. That is far under the 1.5x trigger (212 s), so the trigger has not fired and no flake was seen in this run.

**Two problems with the row as written:**

- Measured against the row's stale 105 s, the same run reads 1.47x, just under the 157.5 s threshold.
- "A `--jobs` run's wall time" now matches two runs per gate. The fast run, at 171 s, exceeds 157.5 s although it does not contain install-host.

Either reading could fire the row falsely.

**Recommendation:** Update row 181's baseline to 141.3 s (2026-10-14, load ~5). Restate the trigger as "install-host.bats' in-run duration (its last log line) exceeds 1.5x its solo time". No code change is needed.

#### 5. Row 183 (serial `bats --count`) now runs twice per gate and stays deferred

**Severity:** Informational
**Location:** `scripts/run-tests.sh:426`, reached by `scripts/health-check.sh:420` and `:428`
**Move:** Hidden multiplication (once per run, now two runs per gate)
**Classification:** Micro / Hot path
**Confidence:** High
**Baseline:** `bats --count` 8.6 s over the 118 fast files and 1.3 s over the 15 slow files, measured in this review, 2026-10-14
**Legibility-target:** for-author

**Evidence:**

From `scripts/run-tests.sh:426`:

```
  expected="$(bats --count "${files[@]}" 2>/dev/null)" || expected="?"
```

About 10 s of the gate's 325 s of BATS (3.0%) is serial counting. That is below the row's own ~15 s estimate and below either ordering lever above. Retagging under Finding 1 moves about 300 tests' worth of counting from one run to the other without changing the total.

**Recommendation:** Keep row 183 deferred. Its revisit trigger ("with the ordering item above") should point at Finding 2's named-list change if that lands. Even then, 10 s does not justify reworking the last-run write order.

## Endorsements

- Validating `RUN_TESTS_JOBS` before the fast run starts (`scripts/health-check.sh:408-412`) means a bad value fails in O(1) rather than after a run's setup work. `[unverified — submitted as claim]`
- Keeping `--no-parallelize-within-files` (run-tests.sh:416), as row 93 asked, holds per-file concurrency at N process trees rather than N × tests, which bounds the `/proc` scan growth row 181 watches. `[unverified — submitted as claim]`
- The `health-check.lock` serializes gates per repository, so two concurrent gates cannot each start 8 jobs on this host (16 files' worth of contention). `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Fast-tagged `build-loop-check.bats` (119.5 s) makes the fast run the longer one (171 s vs 154 s); the split pays two critical paths, floor ~261 s | Medium | `scripts/health-check.sh:420,428`; `test/scripts/build-loop-check.bats:2` | High / Medium |
| 2 | Row 182 fires: ordering is worth ~50 s in the fast run, ~0 s in the slow run; do it now via retag or a named list | Low | `scripts/run-tests.sh:411-416` | Medium |
| 3 | Default 8 not capped at `nproc`; right on 16 cores, oversubscribes small hosts | Low | `scripts/health-check.sh:408` | Medium / Low |
| 4 | Row 181's 105 s baseline is stale (141.3 s now, in-run 1.09x); trigger ambiguous across two runs | Informational | `docs/reviews/override-log.md:181` | High |
| 5 | `bats --count` twice per gate: 9.9 s, 3% — keep row 183 deferred | Informational | `scripts/run-tests.sh:426` | High |

## Overall Assessment

The diff's own code is cold and correct in shape. Nothing in it blocks landing on performance grounds. The default of 8 is right for this host. The structural cost is in what it composes with. The gate runs two sequential parallel runs, and a fast-tagged file sets the first run's floor at about 120 s. So the gate's BATS took 325 s, a 1.39x gain over Q-090's serial full run. That is not the ~3x the comments and pr-prep claim (fact-check Claims 1 and 2).

The cheapest fix with the largest effect is retagging `build-loop-check.bats`, and maybe `cc-isolated-functions.bats`, as slow. Pair it with front-loading a named list of known-slow files. That would take row 182 from Defer to done, at about 50 s per gate, without a timing database.

Rows 181 and 183 stay as they are, but row 181's numbers need refreshing. One timed gate run after any of these changes is needed to confirm the projected ~180 to 200 s. Until then, the docs should cite the measured 171 + 154 s rather than "2.5 min".

## Goal-Alignment Note

The goal was to land Q-102 [1], parallel gates by default, as one reviewed unit. The diff does that, and none of these findings argues against landing it.

Findings 1 and 2 are follow-ups that would deliver more of the speedup the Q-102 motive promised ("~7.5 min serial against ~2.5 min"). They could go in this unit as two tag-line edits, or in a separate small unit, at the orchestrator's choice. Finding 3 is a one-line hardening. Findings 4 and 5 touch only the override log.

The one change this review would make inside the unit regardless is correcting the timing claims (fact-check Claims 1, 2 and 4). The measured gate is 171 + 154 s at `--jobs 8`, not 2.5 min.
