Commit: ff99d86

# Performance Review (final pass): feat/run-tests-jobs (Q-090, `--jobs N` for scripts/run-tests.sh)

**Scope:** `git diff main...HEAD -- scripts test` in /workspace/.claude/wt-run-tests-jobs (scripts/run-tests.sh, test/scripts/run-tests.bats), plus the bats 1.8.2 libexec paths the diff hands work to
**Date:** 2026-09-30
**Based on:** docs/reviews/q090-pass3-code-fact-check-report-r{1,2,3}.md (k=3 at ff99d86); pass-1 docs/reviews/q090-performance-review-2026-09-30.md; settled rows docs/reviews/override-log.md:166-174
**Baselines in hand:** the author's measurements on this 16-core host (serial 451 s; `--jobs 8` 142-145 s over five runs; `--jobs 16` 137 s; install-host.bats alone 105 s; health-check.bats alone 70 s; 1 flake in 12 parallel full runs), plus probes P1-P5 below, run in this pass.

## Data Flow and Hot Paths

The diff's own code is cold, O(1) CLI setup that runs once per run: a 1-3 digit regex, a clamp to the file count, `unset PARALLEL`, and one `parallel --plain --version` exec, only when N > 1 after the clamp (`scripts/run-tests.sh:406-414`). P2 measured that exec at 0.048-0.050 s (3 runs). The work that costs time is downstream: bats runs `parallel --keep-order --jobs N bats-exec-file ... ::: <files>` (`/usr/libexec/bats-core/bats-exec-suite:420`). The unit is a whole file, and tests stay serial within a file (fact-check r1 claims 2 and 4, Verified). The path is hot in developer-loop terms, because it is the gate that pr-prep and the review loop run. The suite has 124 files and 2,184 tests (`bats --count`, P3).

The measurements settle what pass 1 could only estimate:

| Run | Wall | Speedup vs 451 s | Per-slot efficiency |
|---|---|---|---|
| `--jobs 4` (review agents running) | 271 s | 1.66× | — |
| `--jobs 8` (review agents running) | 179 s | 2.52× | — |
| `--jobs 8`, 5 clean runs | 142-145 s | 3.14× (at 143.5 s) | 0.39 |
| `--jobs 16` | 137 s | 3.29× | 0.21 |

(python3: 451/143.5 = 3.14, 451/137 = 3.29, 3.14/8 = 0.39, 3.29/16 = 0.21.) The run is floor-bound. Every file other than install-host.bats adds up to 346 s of serial work (451 − 105), about 49 s per slot across the other 7 slots at `--jobs 8`, which is well under install-host.bats' 105 s. At `--jobs 16` the wall sits 32 s above that file's solo time (137 − 105). P3 measured 5.0 s of that gap as the serial `bats --count` prelude. The rest is the file's start offset (it is file 26 of 124 in path order) plus any slowdown of install-host.bats under load (pass-1 F1, settled as row 166). That split is not measured.

## Findings

#### 1. The pre-existing "killed partway" test pins a run-log count that a signal race can change under load (mechanism for the observed flake)

**Severity:** Low
**Location:** `test/scripts/run-tests.bats:284-299` (the assertion is `:298`); mechanism in `/usr/libexec/bats-core/bats-exec-test:114-118,159,186,314` and `/usr/libexec/bats-core/bats:459-466`
**Move:** Find the contention point (CPU scheduling order among the processes of one signalled group)
**Classification:** Contention / timing (the result depends on which of two processes the scheduler runs first after one group-wide SIGTERM) / Hot (every gate run of run-tests.bats, which under `--jobs` shares the machine with N−1 other files)
**Confidence:** Medium. Both orderings of the race were reproduced deterministically (P4). The natural race was not reproduced in 70 trials (P5). The failing run's output was not captured, so the "2 of 3" message is inferred from the mechanism.
**Baseline:** 1 failure in 12 parallel full runs, at this test's last assertion; 0 in 15 isolated runs and 3 more full `--jobs 8` runs (author's measurements, 2026-09-30, this host)
**Legibility-target:** for-author

Evidence:

```bash
# test/scripts/run-tests.bats:284-299 (the whole test; read)
@test "--failed refuses the log of a run killed partway" {
  sleeper_fixture slow.bats
  runner_bg "$BATS_TEST_TMPDIR/killed.out" test/slow.bats
  local pid=$! rc=0
  wait_for "$T/sleep.pid"
  kill -TERM "$pid"
  wait "$pid" || rc=$?
  [ "$rc" -eq 143 ]
  wait_unlocked
  # The log holds s1 only.
  grep -q '^passed .*slow.bats.*s1' "$LOG_DIR"/*.log

  runner --failed
  [ "$status" -eq 1 ]
  [[ "$output" == *"--failed: the last run ("*") recorded 1 of 3 tests: it did not complete"* ]]
}
```

```bash
# /usr/libexec/bats-core/bats-exec-test:314 (bats_perform_test, :293-323; read)
  trap "bats_teardown_trap as-exit-trap $BATS_killer_pid" EXIT
# :114-118 (bats_exit_trap, :114-201; read)
bats_exit_trap() {
  local status
  local exit_metadata=''
  local killer_pid=${1:-}
  trap - ERR EXIT
# :159 (inside the failed branch, reached because BATS_TEST_COMPLETED is empty)
      printf 'not ok %d %s%s\n' "$BATS_SUITE_TEST_NUMBER" "${BATS_TEST_NAME_PREFIX:-}${BATS_TEST_DESCRIPTION}${BATS_TEST_TIME}" "$exit_metadata" >&3
# :186
    printf "%s %s\t%s\n" "$state" "$BATS_TEST_FILENAME" "$BATS_TEST_NAME" >>"$BATS_RUNLOG_FILE"
```

```bash
# /usr/libexec/bats-core/bats:463-466 (the final pipeline; the if/else is :458-467; read)
else
  exec bats-exec-suite "${flags[@]}" "${filenames[@]}" |
    bats_test_count_validator |
    "$interpolated_formatter" "${formatter_flags[@]}"
```

Mechanism: `timeout` sends SIGTERM to its whole process group. That group holds s2's `bats-exec-test`, which is parked in `wait`, and `bats_test_count_validator`, the subshell that reads that process's fd 3 pipe. P4 found this subshell to be the only reader of the pipe. A non-interactive bash runs its EXIT trap on SIGTERM (P1). So s2's `bats-exec-test` goes through `bats_teardown_trap` → `bats_exit_trap`, which first writes `not ok` to fd 3 (`:159`) and only then appends `failed …\ttest_s2` to the run log (`:186`). The race decides between two outcomes:

- The validator has already exited. Then the `:159` write raises SIGPIPE, which kills the trap before `:186`. The log holds s1 only, and `--failed` says "recorded 1 of 3", which the test expects.
- The validator is still alive. Then the write succeeds and the log gains `failed … s2`. `--failed` still refuses correctly, but it says "recorded 2 of 3", and the `:298` pattern fails.

The earlier `grep` for s1 passes in both outcomes, which matches the author's report that the test failed "at its last assertion". The validator normally dies first: it only has to leave a blocked `read`, while the trap runs several bash functions first. On an idle host that ordering always held. It takes a CPU-saturated host to reorder the two, and a full `--jobs 8` run of this suite is one. That explains why the flake appeared only in parallel full runs. The runner is not at fault: both logs are short of 3 and are refused. Only the test's exact count is fragile. The diff's own killed-run test already avoids this. It matches `recorded "*" of 4` (`test/scripts/run-tests.bats:420`).

**Recommendation:** At `:298`, accept either count, as the `--jobs` sibling does: `*"recorded "[12]" of 3 tests: it did not complete"*`. Alternatively, keep the literal "1 of 3" and state in the comment at `:293` that s2's `failed` line may or may not land. Do not tighten the runner. Its refusal is correct in both outcomes.

Probes (scratch dir `…/scratchpad/run-tests-jobs/perf-final/`, each under `timeout`, every started process killed by PID, none left running, checked by a `/proc` cwd sweep):
- P1: `bash -c 'trap "echo exit-trap-ran >> p1.log" EXIT; sleep 5 & wait'` sent SIGTERM gave `rc=143` and `exit-trap-ran`.
- P4 (`probe2.sh A`, `probe3.sh`): the same three-test fixture run with bats directly, not the runner. TERM to s2's `bats-exec-test` alone, with the reader alive, gave `s2 lines in run log: 1 (failed)` in 3/3 trials. TERM to the validator first, then to s2's `bats-exec-test`, gave `s2 lines in run log: 0` in 3/3 trials.
- P5 (`probe.sh`): a group-wide TERM through `timeout`, as the test sends it, gave `rc=143 lines=1` in 30/30 trials idle and 40/40 trials under 32 busy loops. So the reordering is rare. The author's 1-in-12 parallel full runs is the only observed rate.

#### 2. Row 166's settling evidence is the contaminated `--jobs 8` run; the clean runs fall inside its revisit trigger, by 13-20 s

**Severity:** Informational
**Location:** `docs/reviews/override-log.md:166`
**Move:** Find the contention point (the settled install-host `/proc`-scan item, re-checked against the new clean measurements)
**Classification:** Macro (the critical-path file's duration under load) / Hot (every `--jobs` gate run)
**Confidence:** High on the arithmetic; the per-file split of the 32 s gap is unmeasured
**Baseline:** `--jobs 8` 142-145 s over 5 clean runs; install-host.bats alone 105 s (author's measurements, 2026-09-30, this host)
**Legibility-target:** for-orchestrator-synthesis

Evidence:

```text
# docs/reviews/override-log.md:166 (Rationale cell, excerpt; the row continues with the revisit trigger; read)
Measured instead of changed: install-host.bats alone 105 s, full suite at `--jobs 8` 179 s against 451 s serial, so the slowdown is not what bounds the run today. Revisit if a `--jobs` run's wall time exceeds 1.5× install-host.bats' solo time, or install-host flakes under `--jobs` (then stub the scan by default like `pgrep`).
```

This does not re-raise pass-1 F1. It reports new evidence on its settled row. The row cites 179 s, the run taken while review agents were running. By the row's own trigger that figure would call for a revisit, since 1.5 × 105 = 157.5 s and 179 > 157.5. The clean figures do not: 142-145 s is 1.35-1.38× the solo time and 137 s is 1.30×. That leaves 13-20 s of headroom. So the decision stands, but on the clean numbers, not on the number it cites. The headroom is small enough that one more concurrent workload (an agent, a second checkout's run) crosses the line, as the 179 s run did.

**Recommendation:** When the row is next touched, replace "179 s" with the clean 142-145 s (`--jobs 8`) and 137 s (`--jobs 16`), and note that the trigger should be judged on runs without other heavy work on the host.

#### 3. The header's "about 15 s" for the `bats --count` prelude measures 5.0 s here

**Severity:** Informational
**Location:** `scripts/run-tests.sh:56-57` (pre-existing text, outside the diff's hunks; the prelude is `:420`)
**Move:** Find the work that moved to the wrong place (serial prelude before a parallel phase)
**Classification:** Micro (fixed cost per run) / Hot (every recorded run)
**Confidence:** High
**Baseline:** 5.016 s and 5.022 s for `bats --count` over all 124 files (2,184 tests), probe P3, this pass, 2026-09-30, this host
**Legibility-target:** for-author

Evidence:

```bash
# scripts/run-tests.sh:56-57 (excerpt of the "Run logs" paragraph, :48-70; read)
# Just before the exec it writes .bats/last-run: the selected files, their
# test count (`bats --count`, which adds about 15 s to a full run) and the
```

Pass-1 F5, deferred as row 168, priced this prelude at the documented 15 s, about 12% of a parallel run. Measured at 5.0 s, it is 3.5% of a 143.5 s `--jobs 8` run and 3.6% of the 137 s `--jobs 16` run (python3: 5.0/143.5 = 0.035, 5.0/137 = 0.036). That strengthens row 168's deferral. The text is pre-existing. It matters more now because `--jobs` users will read it as the fixed overhead of a parallel run.

**Recommendation:** Change "about 15 s" to "about 5 s on a 16-core host", or drop the figure. Reopening row 168 is not warranted.

#### 4. `--jobs 16` buys 4.5% over `--jobs 8`, and nothing tells the user where the knee is

**Severity:** Informational
**Location:** `scripts/run-tests.sh:36-40` (the `--jobs` Flags entry) and `:85-89` ("The slowest file bounds the speedup.")
**Move:** Ask "what's the size of N?"
**Classification:** Micro (a choice of constant) / Cold (a per-invocation flag value)
**Confidence:** High for this host; the knee on other core counts is not measured
**Baseline:** 142-145 s at `--jobs 8` (5 runs) and 137 s at `--jobs 16` (1 run), against 105 s for install-host.bats alone (author's measurements, 2026-09-30, this 16-core host)
**Legibility-target:** for-author

Evidence:

```bash
# scripts/run-tests.sh:36-40 (the whole --jobs Flags entry; read)
#   --jobs N  Run up to N test files at once (see "Parallel runs"). N is 1
#             to 999, digits only, no leading zero; anything else is a usage
#             error (exit 2). 1, the default, runs serially; N above the
#             number of selected files is lowered to it. Combines with every
#             other flag, --failed included.
```

Doubling N from 8 to 16 saves about 6.5 s, or 4.5% (python3: (143.5 − 137)/143.5 = 0.045). The cost is twice the concurrent processes. That feeds the settled row-166 scan cost and the timing-window exposure that pass-1 F4 described. The header says the slowest file bounds the speedup, but it does not name that file or its duration, so a user has no way to know that N above about 8 buys almost nothing here.

**Recommendation:** Add one clause to "Parallel runs", for example: "on a 16-core host the full suite takes about 145 s at --jobs 8 against about 105 s for install-host.bats alone, so higher N gains little". Leave the 999 cap as it is.

## Endorsements

- The GNU check, and every other cost the diff adds, is paid only when N > 1 after the clamp to the file count. Serial runs and one-file runs never exec `parallel`, and P2 measured the check itself at 0.05 s. `[read: scripts/run-tests.sh:406-414]`
- Tests within a file stay serial. `--no-parallelize-within-files` keeps bats' per-test semaphore path, whose polling pass 1 flagged, out of the run. `[fact-check: r1 claim 2 — Verified; r2 claim 2 — Verified; r3 claim 2 — Verified]`
- The 1-999 cap and the clamp mean parallel is never given more slots than files. `[fact-check: r1 claims 15 and 16 — Verified; r2 claims 13a and 14 — Verified]`
- A parallel run still writes one run-log line per test, so the count check and `--failed` carry over from serial runs. `[fact-check: r1 claim 13 — Verified; r2 claim 11 — Verified; r3 claim 11 — Verified]`
- The diff's own killed-run test is immune to the finding-1 race, because it accepts any recorded count. `[read: test/scripts/run-tests.bats:407-421]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The pre-existing killed-run test pins "1 of 3"; a SIGTERM/SIGPIPE race makes it "2 of 3" under load (the observed flake) | Low | `test/scripts/run-tests.bats:298` | Medium |
| 2 | Row 166 cites the contaminated 179 s, which trips its own 1.5× trigger; the clean 142-145 s runs fall inside it by 13-20 s | Informational | `docs/reviews/override-log.md:166` | High |
| 3 | Header says `bats --count` adds about 15 s; measured 5.0 s (3.5% of a `--jobs 8` run) | Informational | `scripts/run-tests.sh:56-57` | High |
| 4 | `--jobs 16` gains 4.5% over 8; no guidance on N | Informational | `scripts/run-tests.sh:36-40` | High |

## Overall Assessment

On performance, this change is ready to land. The code it adds is cold and costs about 0.05 s per parallel run. The measured result, 451 s down to about 144 s at `--jobs 8`, is 3.1× and close to the floor that install-host.bats' 105 s sets. The mechanism behind that bound is verified by fact-check (k=3). No finding blocks the merge. The one actionable item is finding 1. It is a one-pattern test fix for a flake that `--jobs` makes visible by loading the machine, not a defect in the runner. The runner refuses the killed run's log whether the race writes s2's line or not. Findings 2-4 are record-keeping. They put the clean numbers into the settled row, fix a stale prelude figure that now overstates the prelude by 3×, and tell users that N above about 8 gains little on this host. The only open measurement is the split of the 32 s between install-host.bats' solo time and the `--jobs 16` wall. It matters only if someone wants to go below about 140 s, and row 166's trigger already covers it.

## Goal-Alignment Note

- Success criterion (restated verbatim): "a markdown report saved at the path named below, structured per the skill."
- Answered: yes. The report is saved at docs/reviews/q090-final-performance-review-2026-09-30.md with `Commit: ff99d86` at the top. Every finding carries Severity, Location, verbatim Evidence, Confidence, Baseline, Classification and Legibility-target.
- Flake mechanism (asked for): finding 1. Both orderings of the race were reproduced deterministically with bats run directly on a scratch fixture. The natural race was not reproduced (70 trials), so the mechanism is well supported, but the observed failure's exact message is inferred.
- Settled items: rows 166-174 were not re-raised. Findings 2 and 3 bring new measured evidence to rows 166 and 168, and both support the existing decisions.
- Probes: `parallel --plain --version` (P2), `bats --count` over the real suite (P3; counting only, no test ran), a bash trap check (P1), race probes on a scratch fixture (P4, P5), and one direct `bats test/scripts/run-tests.bats` (6.0 s, 30/30 ok). I did not run `scripts/run-tests.sh` against the real suite, passed no `--jobs` value above 50, and left no process running (checked with a `/proc` cwd sweep and a process listing).
- Not done: I did not measure install-host.bats inside a `--jobs` run, so the 32 s gap above the floor is split by reasoning, not measurement.
- Decisions I made: I rated finding 1 Low, not Informational, because it fails the gate in about 1 of 12 parallel runs. I rated findings 2-4 Informational because each concerns documentation or a settled row, not code on the hot path.
