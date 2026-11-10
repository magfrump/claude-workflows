Commit: 9d37c1ac

# Performance Review — test/confine-tests-bats

**Scope:** `git diff a37733cc...HEAD` (`test/scripts/confine-tests.bats` new, 395 lines; `docs/working/research-2026-11-10-confine-tests-bats.md` new)
**Date:** 2026-11-10
**Based on:** `docs/reviews/code-fact-check-report-2026-11-10-confine-tests-bats.md` (Stage 1, k=1; no performance claims among its non-Verified items)

## Measurement conditions

All numbers below were taken on this machine (16 CPUs, bats 1.8.2) while **two full test suites were running**: one in this worktree (`test/scripts/dev-cycle.bats` was executing) and one in `wt-2026-11-10-dev-cycle-skill-held-fixes` under `bats -j 4`. Load average was 34.7 to 37.0 throughout (`uptime` before each run). Treat every number as an upper bound; an idle machine will be faster. Scratch files are under `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-bats/perf1/`.

| What | Command | Result |
|---|---|---|
| Whole file, wall time, 3 runs | `bash -c "time timeout 300 bats test/scripts/confine-tests.bats"` | 4.52 s, 4.45 s, 3.90 s; 17/17 pass each run |
| Per-test, summed | `timeout 300 bats --timing test/scripts/confine-tests.bats` | 142 ms to 369 ms per test; sum about 3.77 s |
| bats' own per-test floor | `bats --timing` on a file of three `{ :; }` tests, no setup | 13 to 14 ms per test |
| This file's `setup()` alone | `bats --timing` on a copy of lines 1-170 plus `@test "setup only" { :; }` | 75 to 84 ms per test, so `setup()` costs about 65 ms |
| One `--probe` under stand-ins | same harness, 10 x `confine "bwrap unshare ip" STUB_BWRAP=ok -- --probe` | 414 ms for 10, so about 33 ms each after setup |
| One unshare run (script, stand-in unshare, `sh`, stand-in `ip`, child) | same harness, 10 x `confine "unshare ip" ... -- -- "$RECORD" a b` | 674 ms for 10, so about 60 ms each |
| One `calls` plus one `call` assertion | same harness, 10 x `calls unshare 2 ip 1 child 1; call ip 1 link set lo up` | about 18 ms per pair |
| Under parallel runs | `timeout 300 bats --jobs 4 --no-parallelize-within-files confine-tests.bats bench.bats empty.bats`, 3 rounds; `timeout 300 bats --jobs 8 confine-tests.bats` (parallel within the file) | all exit 0, no failures |
| Leftovers | `ps -eo pid,args \| rg 'record argv\|stub/(bwrap\|unshare\|ip)\|confine-tests.sh'` after all runs | none |

Where the roughly 4 s goes: about 1.1 s is `setup()` (17 x 65 ms), about 0.25 s is bats' own floor (17 x 14 ms), and the rest, about 2.5 s, is the 28 `run`/`confine` call sites (some inside loops, so more invocations than that) at 33 to 60 ms each, plus the `calls`/`call` assertions.

## Data Flow and Hot Paths

The file is test code, not a request path. It runs once per full suite run: `scripts/health-check.sh` and every build loop run the whole suite of about 2,000 tests. The "hot" quantity is therefore wall time added to each suite run, multiplied by how often loops run. The file adds about 4 s under heavy load. The suite total was not measured here (the brief forbids `scripts/run-tests.sh`), so I can't give this file's share of it.

Per test: `setup()` (lines 39-64) makes about a dozen forks (4 `type -P` plus `ln`, `mkdir`, a `pwd -P` subshell, `cp` x4, `chmod`, `write_stub`'s `cat`). Then the test calls `confine()` (lines 133-142) one to four times. Each call is one `env -i` plus the script, and the script then runs one to five stand-ins. Each stand-in is a fresh `bash` that records its argv with an O(k) scan of existing `$STUB_LOG/NAME.N` files, where k is at most 5 here, and compares argv through `is()`, which forks two command substitutions per comparison. All collections are tiny and bounded by the test text: at most 5 calls per name and a 12-word `TRICKY` array. No loop scales with anything outside the file.

Shared state: every path is under `$BATS_TEST_TMPDIR` (`T`, `LOG`, `TOOLS`, `WORK`), and every stand-in run gets `HOME="$T" TMPDIR="$T"` (line 139). Nothing reads or writes a fixed `/tmp` path or the repo tree, so parallel files and parallel tests cannot collide. The measured `--jobs` runs agree. The only test that reaches outside is test 3 (lines 195-211), which runs the real script on the ambient PATH.

## Findings

#### PERF-1 · Test 3 runs the real primitive with no time bound

**Severity:** Low
**Location:** `test/scripts/confine-tests.bats:199`
**Evidence:**
> ```
>   run --separate-stderr "$SCRIPT" --probe
> ```
**Move:** Resource lifecycle / deployment environment (what happens on a machine other than this one)
**Classification:** Macro (a possible unbounded wait) / Cold path (one call per suite run)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-author

This is the one test with no stand-ins. On a host with a working primitive it runs the real `bwrap --ro-bind / / --unshare-net -- true` or `unshare -rn true` (`scripts/confine-tests.sh:80-87`). In the status-3 branch (line 205) it runs the script again. Here (a container with `unshare` installed but refused) the test took 232 ms. On a host where a real `bwrap` or `unshare` stalls instead of failing (a nested sandbox, a slow user-namespace setup, a seccomp or LSM path that blocks), nothing bounds the wait. bats 1.8.2 has no per-test timeout (`BATS_TEST_TIMEOUT` arrived in a later bats). So such a stall would hang the whole suite run, and every build loop behind it, rather than fail one test. A probe of `true` is unlikely to stall, which is why this is Low. But this test is the only place in the file where the cost depends on a machine the author cannot see.

**Recommendation:** Wrap the two ambient-PATH calls in `timeout` (for example `run --separate-stderr timeout 60 "$SCRIPT" --probe`), and add `124) false ;;` before `*) false ;;` so a timeout fails the test with a readable status. `timeout` passes the script its argv and environment unchanged, so the test still runs the script in its real position.

#### PERF-2 · Per-test `setup()` is about 30% of the file's time; moving it to `setup_file` is not worth it

**Severity:** Informational
**Location:** `test/scripts/confine-tests.bats:39-64`
**Evidence:**
> ```
>   for tool in bash sh cat awk; do
>     ln -s "$(type -P "$tool")" "$TOOLS/$tool"
>   done
> ```
> ```
>   write_stub
>   for tool in bwrap unshare ip; do cp "$T/stub/stub" "$T/stub/$tool/$tool"; done
> ```
**Move:** Work in the wrong place (per test where once per file would do)
**Classification:** Micro (fixed fork count per test) / Cold path (17 tests, once per suite run)
**Confidence:** High
**Baseline:** `setup()` about 65 ms per test (75 to 84 ms with setup, against a 13 to 14 ms bats floor), measured with `bats --timing` at load average 37.0, 2026-11-10, this report's table
**Legibility-target:** for-orchestrator-synthesis

Everything `setup()` builds except `$LOG` and `WORK` is identical for every test and only read after setup: the tool symlinks, the recorder, `-record`, the stand-in script and its three copies, `PROFILE`. Building them once in `setup_file()` under `$BATS_FILE_TMPDIR` would save about 16 x 65 ms, roughly 1 s per suite run under this load and less on an idle machine. The cost: `PROFILE` and `RECORD` would need per-file paths, `WORK` would still need to be per test (the `pwned` checks and `--bind "$WORK"` rely on a fresh directory), and the tests would lose the property that each one owns its whole tree. That property is what makes the `--jobs 8` within-file run safe. For a 17-test file, one second does not buy that complexity. I report this so synthesis does not ask for the change, not to request it.

**Recommendation:** No change. Revisit only if the file grows several-fold, or if a suite-time budget shows it among the slowest files.

## Endorsements

- Every file the tests and stand-ins create is under `$BATS_TEST_TMPDIR`, and each stand-in run gets `HOME`, `TMPDIR` and `STUB_LOG` pointing into it, so parallel files and parallel tests do not share state. [read: test/scripts/confine-tests.bats:40-45, 54-58, 133-142]
- The stand-ins and the recorder are leaf processes that either `exec` the recorder, which writes one file and exits, or exit with a fixed status. None reads stdin or waits on anything, so a stand-in run cannot block. [read: test/scripts/confine-tests.bats:36-37, 54, 91-128]
- Cost scales only with the test text: `calls` (146-154) and the recorder's numbering loop (36) scan at most 5 files per name, and no assertion re-runs the script. [read: test/scripts/confine-tests.bats:36-37, 146-163]
- No test leaves a process behind after a passing run, under serial or `--jobs` execution. [unverified — submitted as claim; `ps` after 3 serial runs, 3 `--jobs 4` runs and one `--jobs 8` run showed none, but that is a sample, not proof]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| PERF-1 | Test 3 runs the real primitive with no time bound; a stall would hang the suite | Low | `test/scripts/confine-tests.bats:199` | Medium |
| PERF-2 | Per-test `setup()` is about 1 s of the file's 4 s; hoisting it is not worth the complexity | Informational | `test/scripts/confine-tests.bats:39-64` | High |

## Overall Assessment

The file is cheap and well contained. It took 3.9 to 4.5 s wall time for 17 tests at load average 35 to 37 with two other suites running. It is fully isolated under `$BATS_TEST_TMPDIR`, passed every parallel configuration tried, and left nothing running. Nothing in it scales with input. The one item worth acting on is PERF-1, a one-line `timeout` around test 3's two ambient-PATH calls, so that an unusual host fails one test instead of hanging the suite. The per-test setup cost (PERF-2) is real and measured, but not worth restructuring for. No further profiling is needed. An idle-machine timing would only make the numbers smaller.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-bats/docs/reviews/performance-review-2026-11-10-confine-tests-bats.md, structured per the performance-reviewer skill.
- Answered: yes
- Out of scope: the research doc (no performance claims beyond a context-token estimate); suite-total share (not measured, because `scripts/run-tests.sh` was off limits)
- Escalate: nothing (the timings were taken under load from two concurrent suite runs, one in this worktree; re-time on an idle machine if exact numbers matter)
