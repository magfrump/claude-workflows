Commit: 27b5e861

# Performance Review (final pass) — test/confine-tests-bats

**Scope:** `test/scripts/confine-tests.bats` at 27b5e861 (412 lines, 17 tests); `docs/working/research-2026-11-10-confine-tests-bats.md` checked for cost claims only. Review artifacts under `docs/reviews/` and `scripts/confine-tests.sh` (unchanged) are context, not under review.
**Date:** 2026-11-10
**Based on:** code-fact-check reports `final-r1`..`final-r3` (k=3 at 27b5e861; no performance claims among non-Verified items; 17/17 pass in all three); first-pass `performance-review-2026-11-10-confine-tests-bats.md` (at 9d37c1ac).

## Measurement conditions

16 CPUs, bats 1.8.2. Load is given beside each number (`uptime` before each run). Scratch: `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-bats/perffinal/`. Unlike the first pass, the machine was nearly idle for the baseline, so I added a synthetic load run (32 busy loops, stopped by PID afterwards; `ps -p` confirmed gone).

| What | Command | Load (1-min) | Result |
|---|---|---|---|
| Whole file, serial, 3 runs | `bash -c "time timeout 300 bats test/scripts/confine-tests.bats"` | 1.08 | 1.13 s, 1.09 s, 1.12 s; 17/17 each |
| Per test | `timeout 300 bats --timing test/scripts/confine-tests.bats` | 1.09 | 36 ms to 76 ms per test (test 3, the ambient-PATH one: 42 ms) |
| Whole file, `--jobs 8` (parallel within the file) | `bash -c "time timeout 300 bats --jobs 8 ..."` | 1.08 | 0.57 s; 17/17 |
| Serial under load, 2 runs | same as row 1, 32 busy loops running | 10.9 → 12.9 | 8.45 s, 6.33 s; 17/17 each |
| `--jobs 16` under load, 2 runs | `timeout 300 bats --jobs 16 ...`, 32 busy loops | 16.8 → 18.3 | 3.34 s, 3.61 s; 17/17 each |
| `setup()` alone | `bats --timing` on lines 1-181 + `@test "setup only" { :; }` (`bench/bench.bats`) | 0.98 | 19-20 ms per test |
| `confine()` with the new `bash -c` pid wrapper | same harness, 20 x `confine "bwrap unshare ip" STUB_BWRAP=ok -- --probe` | 0.98 | 258 ms, 234 ms per 20 (about 12 ms each) |
| Same 20 probes without the wrapper | same harness, `run --separate-stderr env -i ... "$SCRIPT" --probe` x 20 | 0.98 | 190 ms, 199 ms per 20 (about 10 ms each) |
| `same_process` | same harness, 20 calls | 0.98 | 44 ms, 46 ms per 20 (about 2 ms each) |
| Time bound on a stalling primitive | `PATH="$D/stall:$PATH" timeout 3 scripts/confine-tests.sh --probe`, where `stall/bwrap` is `exec sleep 300` | ~1 | exit 124 after the bound; `ps` shows no `sleep 300` left |
| Order independence | each of the 17 tests run alone with `bats -f '^<name>$'` | 15.8 | 17 run alone, 0 failed |
| Leftovers | `ps -eo pid,args \| grep -E 'record argv\|stub/(bwrap\|unshare\|ip)\|confine-tests.sh\|while :'` after all runs | — | none; `git status` shows no change outside `docs/reviews/` |

The first pass's 4 s figure was taken at load 35-37; the idle figure is about 1.1 s, and 6-8 s at load 11-13 with all 16 CPUs saturated by spinners. The file's cost scales with CPU contention, not with anything inside it.

## Data Flow and Hot Paths

Test code, run once per full suite run (`scripts/health-check.sh`, every build loop). The "hot" quantity is wall time added per suite run: about 1.1 s idle. Per test: `setup()` (lines 40-67, about 20 ms idle) then one to four `confine()` calls, some inside loops of two or three. Each call is now `bash -c` (writes `$$` to `$LOG/script-pid`, execs) → `env -i` (exec) → the script → one to five stand-ins, each a fresh bash with an O(k) scan of `$STUB_LOG/NAME.N` (k at most 5). All collections are bounded by the test text. Nothing scales with input outside the file.

Additions since the first pass:
- **`bash -c` wrapper (line 143):** one extra bash start per `confine()`, about 2 ms idle (12 vs 10 ms per call in the bench). With roughly 40 `confine()` invocations in the file, that is on the order of 0.1 s, about 8% of the idle total. The pid is written synchronously before `exec`, so there is no race: the file exists before the script starts, and `same_process` reads it only after `run` returns.
- **Recorder pid file (line 57):** one `echo` redirect per child run, in the child, under `$STUB_LOG` (`$BATS_TEST_TMPDIR/log`), so per-test and safe under `--jobs`.
- **`same_process` (lines 151-153):** one `cmp` fork, about 2 ms, used in three tests.
- **shellcheck directive (line 3):** no runtime cost.

**Time bound (first-pass PERF-1):** both ambient-PATH calls now run under `timeout 60` (lines 211, 217). GNU `timeout` signals its own process group, and the probe stall test above shows the stalled primitive's child is killed too, leaving nothing behind. A 124 status falls to `*) false ;;` (line 221) and fails the test. The second call runs only after the first returned 3, so the worst case on a host where both stall is 120 s and a failed test, not a hung suite.

The research doc makes no runtime-cost claim that needs checking.

## Findings

#### PERF-F1 · The pid wrapper and `same_process` add about 0.1 s idle; no action

**Severity:** Informational
**Location:** `test/scripts/confine-tests.bats:143-144`
**Evidence:**
> ```
>   run --separate-stderr bash -c 'echo "$$" > "$1"; shift; exec "$@"' _ "$LOG/script-pid" \
>     env -i PATH="$path" HOME="$T" TMPDIR="$T" STUB_LOG="$LOG" "${assigns[@]}" "$SCRIPT" "$@"
> ```
**Move:** Count the hidden multiplications
**Classification:** Micro (one extra exec per call) / Cold path (once per suite run)
**Confidence:** High
**Baseline:** 1.09-1.13 s whole-file wall time at load 1.08 (`bash -c "time timeout 300 bats test/scripts/confine-tests.bats"`, 3 runs, this pass)
**Legibility-target:** for-orchestrator-synthesis

New at this pass. The wrapper costs about 2 ms per `confine()` call idle (bench: 234-258 ms vs 190-199 ms per 20 probes), roughly 0.1 s across the file. `same_process` is about 2 ms per call, three calls. Neither adds a hang, a race or order dependence: the pid file is written before `exec` and read after `run` returns, every path is under `$BATS_TEST_TMPDIR`, all 17 tests pass alone, and serial and `--jobs 16` runs pass under 32 busy loops. This is a convergence note: the additions do not change the first pass's conclusion.

**Recommendation:** None. Keep the wrapper; what it buys (the exec-chain assertion) is worth about 8% of an already small file.

### Status of first-pass findings

- **PERF-1 (Low, no time bound on the ambient-PATH test):** resolved. Lines 211 and 217 use `timeout 60`, and a stalling primitive is bounded and cleaned up (stall probe above).
- **PERF-2 (Informational, keep per-test `setup()`):** still holds. `setup()` is about 20 ms idle per test, about 30% of the 1.1 s file total (17 x 20 ms = 0.34 s), the same share as before. Moving it to `setup_file` would save at most about 0.3 s idle and give up per-test isolation of the call logs. Not worth it.

## Endorsements

- Both ambient-PATH runs are bounded and a stalled primitive's child is killed with them, leaving no process behind. [read: test/scripts/confine-tests.bats:211-221] plus the stall probe in Measurement conditions.
- All per-test state (call logs, pid files, tools, work dir, `HOME`, `TMPDIR`) is under `$BATS_TEST_TMPDIR`. [read: test/scripts/confine-tests.bats:41-46,143-144]
- The file passes under `--jobs 8` and `--jobs 16` with 32 busy loops, and each test passes alone. [unverified — submitted as claim: measured here on one machine, 2-3 runs each; no flake seen, which does not prove there is none]

## Summary Table

| # | Finding | Severity | Location | Confidence | New/repeat |
|---|---------|----------|----------|------------|------------|
| PERF-F1 | Pid wrapper and `same_process` add about 0.1 s idle; no action | Informational | `test/scripts/confine-tests.bats:143-144` | High | New |
| PERF-1 | Ambient-PATH test unbounded | — (resolved) | `test/scripts/confine-tests.bats:211,217` | High | Repeat, closed |

## Overall Assessment

The file costs about 1.1 s idle, 0.6 s with `--jobs 8`, and 3-8 s on a CPU-saturated machine, and its cost is bounded by the test text. The first pass's one actionable finding is fixed and verified: a stalling primitive now ends in 124 within 60 s per call, with no orphan. The changes since then (pid wrapper, recorder pid file, `same_process`, shellcheck directive) add about 0.1 s and no hang, race, leak or order dependence that I could find under load, under `--jobs`, or with tests run alone. Nothing to fix before merge.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-bats/docs/reviews/performance-review-final-2026-11-10-confine-tests-bats.md, structured per the performance-reviewer skill.
- Answered: yes
- Out of scope: `scripts/confine-tests.sh` itself (unchanged by the branch); the suite-wide share of this file's cost (would need `scripts/run-tests.sh`, which the brief forbids).
- Escalate: nothing
