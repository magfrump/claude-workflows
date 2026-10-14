Commit: 57f37e3

# Performance Review: feat/q102-parallel-gates, confirming pass (fix range 65c931e6..57f37e3a)

**Scope:** `git diff 65c931e6..57f37e3a`, excluding `docs/reviews/` artifacts other than `override-log.md`: health-check.sh gate 5 (`HEALTH_CHECK_JOBS`, nproc default), run-tests.sh unsets, the two retags, install-host T92, health-check.bats/run-tests.bats tests, pr-prep.md, questions-archive note
**Date:** 2026-10-14
**Based on:** shared review context `/home/node/.claude/jobs/00bcf178/tmp/shared2.md`; pass-1 report `docs/reviews/performance-review-2026-10-14-q102.md`; run logs in `.bats/.bats/run-logs/`

> ⚠️ **No code fact-check report provided for this pass.** Performance claims in comments and documentation in the fix range have not been independently verified by a code-fact-check stage. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator. Timing figures below come from run-log mtimes and solo `bats` runs taken in this review.

## Data Flow and Hot Paths

Gate 5 (`scripts/health-check.sh` `check_bats`, :399-445) runs `run-tests.sh --fast --jobs N`, then `--slow --jobs N` only if fast is green. N is now `HEALTH_CHECK_JOBS`, or 8 capped at `nproc` when that is unset or empty. The runner hands bats `--jobs N --no-parallelize-within-files`. GNU parallel then starts whole files in the runner's path-sorted order (`find ... | sort -z`, run-tests.sh:214) as slots free up. Each run's wall time is bounded below by its slowest file plus that file's start delay. The gate pays the two runs one after the other. The code in the diff is cold (one `nproc` fork, one regex). The path is hot: gate 5 gates every pr-prep and build loop.

The only `--fast` caller is gate 5. `rg -- '--fast'` outside reviews and archives finds `scripts/health-check.sh:430` and test fixtures only. No build loop or workflow runs `--fast` on its own.

Tag sets after the fix: 116 fast files and 17 slow files (`rg -l '^# @category (fast|slow)' test`). This host has 16 cores (`nproc`, `nproc --all`), and `/sys/fs/cgroup/cpu.max` is `max 100000`, so there is no quota.

Measured wall times. Run start is the log name and run end is the log mtime, at ±1 s because log names have one-second precision. Arithmetic is in python3.

| Gate run | Tags | Fast run | Slow run | BATS total | Host |
|---|---|---|---|---|---|
| 19:49:27 / 19:52:20 UTC (pass 1, at 65c931e6) | before retag | 171.4 s | 154.7 s | 326.1 s | load ~5 |
| 20:15:59 / 20:17:52 UTC (at db341cb9) | after retag | 109.8 s | 200.9 s | 310.7 s | load 5–7; slow run had 3 failures in health-check.bats (shellcheck, gate 6) |

The slow run's start order is from `.bats/last-run` for the 20:17:52 run. Eight slots, so files 1 to 8 start at t=0:

```
cc-isolated-functions(1) cc-sni-proxy-unittest(2) hooks/log-usage-post(3) hooks/log-usage(4)
install-host(5) link-claude-home-wiring(6) round-log-functions(7) scripts/archive-working-docs(8)
scripts/build-loop-check(9) scripts/flag-removal-candidates(10) scripts/health-check(11) ...
```

Solo times measured in this review at load 18–19:

| File | Solo time |
|---|---|
| `cc-sni-proxy-unittest.bats` | 1.1 s |
| `flag-removal-candidates.bats` | 2.4 s |
| `archive-working-docs.bats` | 3.9 s |
| `log-usage-post.bats` | 6.8 s |
| `test/scripts/dev-cycle.bats` | 144.0 s (79 ok) |
| `test/init-firewall-rules.bats` | 212.3 s (95 ok) |

The last two were taken at load 18–19, and both files ran inside a 109.8 s fast run at load 5–7. Their numbers show only that both files are heavy. They are not usable baselines.

### Answers to the brief's questions

**What bounds each run now?**

- **Fast run.** It is bounded by `test/init-firewall-rules.bats` (file 22 of 116) and `test/scripts/dev-cycle.bats` (file 39). They hold the last two log lines, 1194 and 1195 of 1195. Before the retag, both ended earlier (1397 and 1411 of 1514), and `cc-isolated-functions.bats` and `build-loop-check.bats` ended last (1465 and 1514).
- **Slow run.** Four heavy files run side by side: `health-check.bats` (last line 619 of 619), `install-host.bats` (596), `build-loop-check.bats` (578) and `cc-isolated-functions.bats` (546). `health-check.bats` was also the last or next-to-last finisher before the retag (297 of 298, with install-host at 298). It is a co-bound of the slow run that pass 1 did not time (see Finding 2).

**New fast and slow run times.**

- **Fast:** about 110 s, measured. That is 61.6 s less than before, even on a busier host.
- **Slow:** 200.9 s, measured on the loaded host. That is 46.2 s more.
- **On a load-~5 host:** I estimate slow at about 160 to 200 s. That puts gate BATS at about 270 to 310 s, against 326 s before. This range is speculative. The 3 shellcheck failures in that run do not shorten it: `health-check.bats` runs the whole health check once in `setup_file` (:34-36) and asserts on cached output, so the shellcheck gate ran in full either way.

**Two heavy files that must overlap?** There are four, and they do overlap.

- cc-isolated (file 1) and install-host (file 5) start at t=0.
- build-loop-check (file 9) takes the first freed slot. That is cc-sni-proxy's slot, at about 1 s.
- health-check (file 11) takes the third freed slot, after archive-working-docs (about 4 s) and then flag-removal-candidates or log-usage-post (about 6 to 7 s). Before the retag, it was file 9 and started at about 1 s.

**Does order matter?** Ordering costs health-check.bats about 5 to 6 s of start delay, from solo times. That is speculative under load, and small against the slow run's +46 s. The cost is contention between four CPU-heavy files running at once, not their order.

**Is min(8, nproc) right?** Yes, for this host and as a default. On 16 cores the value stays 8. On a 4-core host it gives 4 slots and stops 2x oversubscription; the four heavy slow files would then start within about the first 10 to 20 s, since only small files sort ahead of build-loop-check and health-check. One caveat about what `nproc` reads (`OMP_NUM_THREADS`, affinity) is filed in the API report.

**Was a retagged file needed in the fast pre-gate for early failure?** No consumer needs it. Gate 5 is the only `--fast` caller, and a green fast run always runs slow. The one cost: when fast is red, a build-loop-check or cc-isolated regression now shows only on the next gate, after fast is fixed, which can mean one extra gate cycle. That is a latency cost, not a coverage loss.

## Findings

#### 1. The retag moved the bottleneck rather than removing it: fast fell 62 s, slow rose 46 s, net about 15 s per gate against pass 1's projected 125–145 s

**Severity:** Low
**Location:** `test/scripts/build-loop-check.bats:2`, `test/cc-isolated-functions.bats:2` (`# @category slow`); gate runs at `scripts/health-check.sh:430` and `:438`
**Move:** Find the contention point (four heavy files now share the slow run); Hidden multiplication (two serial critical paths)
**Classification:** Macro (wall-time floor set by file placement) / Hot path (every gate); Low because the change is net-neutral-to-positive and no correctness is at stake
**Confidence:** Medium (one post-fix gate run on a loaded host, with a failing gate 6)
**Baseline:** gate BATS 326.1 s before the retag (19:49:27 + 19:52:20 UTC logs) against 310.7 s after (20:15:59 + 20:17:52 UTC logs), from run-log names and mtimes
**Legibility-target:** for-author

**Evidence:**

From `docs/reviews/performance-review-2026-10-14-q102.md` (pass 1, F1):

```
Projected gate BATS: about 180 to 200 s, against 325 s now (speculative until re-measured).
```

From `docs/reviews/override-log.md:824` (in this range):

```
build-loop-check.bats and cc-isolated-functions.bats (85 s) moved to slow: the fast set is the early-fail pre-gate.
```

Last log line per file in the post-fix slow run (`.bats/.bats/run-logs/2026-10-14 20:17:52 UTC.log`, 619 lines):

```
546 cc-isolated-functions.bats
578 build-loop-check.bats
596 install-host.bats
619 health-check.bats
```

The projection assumed the slow run's floor stays at install-host's 141 s solo. Two things break that:

- `health-check.bats` was untimed and finishes last (Finding 2).
- The four heavy files now contend with each other. install-host's in-run time rose from about 1.09x its solo time to at most 200.9 / 141.3 = 1.42x.

The fast run did drop as intended, to 109.8 s. So the retag does what its override-log row says: the fast set is now a cheaper early-fail pre-gate. It does not make the gate fast. Host load differed between the two runs, so the net figure has a wide error bar.

**Recommendation:** Keep the retag. Its purpose, a cheap early-fail pre-gate, is met. Change the override-log row's outcome from "Fixed by retag" to the measured result: fast 171 → 110 s, slow 155 → 201 s on a loaded host. Take one gate timing on a quiet host before anyone cites a gate figure. The lever that remains is structural (a single `--all` run, about 140 to 150 s per Q-090) and belongs in a separate unit, not this one.

#### 2. `health-check.bats` co-bounds the slow run but has never been timed; the slow-run model and the restated row-181 trigger both assume install-host alone

**Severity:** Low
**Location:** `test/scripts/health-check.bats:34-36` (`setup_file` runs the whole health check); `docs/reviews/override-log.md:825` (amends row 181, in this range)
**Move:** Ask "what's the size of N?" (an untimed file on the critical path)
**Classification:** Macro / Hot path; Low because it changes the model and the docs, not the code
**Confidence:** Medium
**Baseline:** about 150 s in-run before the retag. It started at about 1 s (file 9 of 15, taking cc-sni-proxy's slot) and ended on line 297 of 298 in a 154.7 s run (19:52:20 UTC log).
**Legibility-target:** for-author

**Evidence:**

From `docs/reviews/override-log.md:825` (in this range):

```
Re-baselined | Trigger restated: revisit if install-host.bats' own in-run duration exceeds 1.5× its solo time (about 212 s), or it flakes under the gate.
```

From `docs/working/questions-archive.md:914`:

```
so that file takes 42–60s depending on load and slow ~80–100s
```

`health-check.bats` (35 tests) has grown from the 42 to 60 s on record to about 150 s in-run. That is as long as install-host, and it finished last in the post-fix run (line 619 of 619). Pass 1 declined to time it because of the shared lock. Its time is therefore unknown solo and is inferred only from log order. A slow-run floor computed from install-host alone undercounts.

**Recommendation:** Time `health-check.bats` once while holding the health-check lock, for example as part of a gate run with per-file timing. Name it beside install-host in the slow-run model (health-check.sh:388-397 comment, override-log rows 181 and :824).

#### 3. The restated override-log triggers need per-file start and end times, which no artifact records

**Severity:** Informational
**Location:** `docs/reviews/override-log.md` (`:824` and `:825`, added in this range); `scripts/run-tests.sh` (run log has no timestamps)
**Move:** Find the contention point (row 181's `/proc`-scan watch) / instrumentation
**Classification:** Micro / Hot path
**Confidence:** High
**Baseline:** install-host in-run at most 200.9 s, or ≤1.42x of 141.3 s solo, from the post-fix slow run (it ended on line 596 of 619 in a 200.9 s run)
**Legibility-target:** for-author

**Evidence:**

From `docs/reviews/override-log.md:824` (in this range):

```
revisit if one file in either run starts more than 30 s after t=0 and finishes last.
```

Run-log line format:

```
passed /workspace/.claude/wt-q102-parallel-gates/test/scripts/health-check.bats	test_gate_14-3a_a_duplicated_question_id_fails_the_gate
```

Neither trigger can be checked from what a gate leaves behind. The run log orders lines but carries no times. The only times are the log name (start) and mtime (end).

- **Row at :824 (fast run).** The trigger is plausibly live already. dev-cycle.bats is file 39 of 116 and finishes last, but its start time cannot be read from the log.
- **Row at :825 (install-host).** The trigger sits at 212 s. The post-fix run bounds install-host only at ≤200.9 s, under four-file contention and load 5–7. That is close enough that a busier host could fire it without anyone being able to tell.

**Recommendation:** Restate both triggers in terms of an observable quantity, or record per-file times. One option is bats' `--timing` flag, which prints per-test durations in the TAP output; it is unverified that it composes with the runner's run-log anchor (see Endorsements). Until then, the triggers should say they need a timed run.

#### 4. Two timing texts in the range describe the pre-retag gate

**Severity:** Informational
**Location:** `scripts/health-check.sh:392-393`; `docs/working/questions-archive.md:2516`
**Move:** Find the work that moved to the wrong place (documentation of a moved bound)
**Classification:** Micro / Cold (comments)
**Confidence:** High
**Baseline:** fast 171.4 s / slow 154.7 s before the retag against 109.8 s / 200.9 s after (run-log names and mtimes)
**Legibility-target:** for-author

**Evidence:**

From `scripts/health-check.sh:392-393`:

```
# less than that (first gate at --jobs 8: 171 s fast + 154 s slow, on a
# loaded host).
```

From `docs/working/questions-archive.md:2516`:

```
build-loop-check.bats and cc-isolated-functions.bats moved from fast to slow, since at 120 s and 85 s they bounded the fast run.
```

Both texts are accurate as history. But the comment sits next to code whose tag set has changed since. A reader will take 171 + 154 as the current gate.

The archive line also overstates. Only build-loop-check bounded the fast run: it ended on line 1514 of 1514. cc-isolated-functions ended on line 1465 and was the next-slowest file, not a bound.

**Recommendation:** Add "(before the retag)" to the comment. Optionally, once a quiet-host timing exists, add the post-retag figures. In the archive line, say "the two slowest fast files" instead of "bounded".

## Endorsements

- min(8, nproc) holds the default at 8 on this 16-core host. This review verified `nproc` = 16 and `cpu.max` = `max`. The stub test `gate 5: the default --jobs 8 is lowered to nproc` covers the cap at 4. `[unverified — submitted as claim]`
- Unsetting `BATS_NUMBER_OF_PARALLEL_JOBS` and `BATS_NO_PARALLELIZE_ACROSS_FILES` in run-tests.sh (:414-416) stops an inherited value from adding within-file parallelism. That would multiply process trees by tests-per-file and enlarge the `/proc` scan that row 181 watches. `[unverified — submitted as claim]`
- T92's marker wait (`test/install-host.bats`, up to 600 × 0.1 s) adds no time on a healthy host, because the marker appears once prctl returns. Its 60 s ceiling only replaces a false skip with a failure under extreme load. `[unverified — submitted as claim]`
- Every heavy slow file starts within the first 8 s of the slow run at `--jobs 8`, so a longest-first sort would save at most about 5 to 6 s there. `[unverified — submitted as claim]`
- bats 1.8.2's `--timing` flag would give per-test durations usable for the triggers at override-log.md:824-825. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Retag moved the bound: fast 171 → 110 s, slow 155 → 201 s; net about 15 s, not the projected 125–145 s | Low | `test/scripts/build-loop-check.bats:2`, `test/cc-isolated-functions.bats:2` | Medium |
| 2 | `health-check.bats` (about 150 s in-run, last finisher) co-bounds slow but is untimed; models assume install-host alone | Low | `test/scripts/health-check.bats:34-36`; `docs/reviews/override-log.md:825` | Medium |
| 3 | Restated triggers need per-file start and end times that no artifact records; install-host now ≤1.42x against the 1.5x trigger | Informational | `docs/reviews/override-log.md:824-825` | High |
| 4 | Comment and archive timing text describe the pre-retag gate; "bounded" overstates cc-isolated | Informational | `scripts/health-check.sh:392-393`; `docs/working/questions-archive.md:2516` | High |

## Overall Assessment

The fixes are correct, and nothing in this range should block landing on performance grounds.

- The `nproc` cap is the right default.
- The bats-variable unset removes a real multiplier.
- T92's wait costs nothing on a healthy host.
- The retag meets its stated purpose: the fast run is now a 110 s early-fail pre-gate, bounded by init-firewall-rules.bats and dev-cycle.bats.

The retag did not deliver pass 1's projected gate time. That projection treated install-host as the slow run's only heavy file. In fact the slow run now carries four heavy files running at once, including the untimed `health-check.bats`, and on a loaded host it grew 46 s. Measured gate BATS went from 326 to 311 s, a difference within the load noise.

Three things matter most:

- Time one gate on a quiet host.
- Time `health-check.bats`.
- Record the measured outcome in the override log rather than "Fixed by retag".

Further speedup needs a structural change, such as one `--all` run or co-scheduling heavy files across runs. That is a separate unit.

## Goal-Alignment Note

The goal was to land Q-102 [1], parallel gates by default, as one reviewed unit. This range does that, and it closes pass 1's F3 (nproc cap) and F4 (row 181 baseline). For F1 and F2, the early-fail structure is improved but the gate is not faster.

None of these findings argues against landing. Findings 1, 2 and 4 are text edits to the override log, the archive note and one comment. Finding 3 is an instrumentation follow-up that can wait for the next unit that touches the runner. No code change is recommended inside this unit.
