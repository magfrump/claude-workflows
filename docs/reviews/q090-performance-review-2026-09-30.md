Commit: 088bc97

# Performance Review: feat/run-tests-jobs (Q-090, `--jobs N` for scripts/run-tests.sh)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-run-tests-jobs (scripts/run-tests.sh, test/scripts/run-tests.bats), plus a read-only pass over the real suite for cross-file shared state under file-level parallelism
**Date:** 2026-09-30
**Based on:** docs/reviews/q090-code-fact-check-report.md (k=1, 23 claims: 17 verified, 5 mostly accurate, 1 incorrect), docs/reviews/q086-performance-review-2026-09-28.md finding 2
**Baselines in hand:** 742 s wall for 2,129 tests in 122 files, serial, 16 cores, main 2bf5979, 2026-09-28 (`docs/working/proposal-2026-09-27-smaller-review-units.md:109-113`); the scan timing probe (P1) below, run in this session.

## Data Flow and Hot Paths

The diff adds one parse branch (`scripts/run-tests.sh:124-132`) and one `command -v parallel` check (`:390-396`). Both are cold, O(1) CLI setup. The performance substance is downstream. With N > 1, bats 1.8.2 runs `parallel --keep-order --jobs N bats-exec-file ... ::: <files>` (`bats-exec-suite:420`, fact-check Claim 2), in the order the runner hands the files over: `find | sort -z` (`scripts/run-tests.sh:192-194`), with the empty run-log anchor first. Tests within a file stay serial. The path is hot in the way that matters here. It is the developer loop and the pr-prep gate, so it runs many times a day. The data sizes are 124 `.bats` files (`find test -name '*.bats' | wc -l`). install-host.bats has 92 tests, cc-isolated-functions.bats 173 and health-check.bats 32. The machine has 16 cores (`nproc`). Wall time under `--jobs` is bounded below by the slowest file (fact-check Claim 4, Verified). So what matters is (a) what makes the critical-path file slower when other files run beside it, and (b) when that file starts.

Probe P1 (this review, `LC_ALL=C.UTF-8`, run in the foreground under `timeout 60`, nothing left running). A copy of `procs_in_checkout`'s loop body ran against the live `/proc`, with a root that matches nothing, so every readable process takes the `continue` branch. That is the common case in install-host.bats, whose root is a per-test `$BATS_TEST_TMPDIR/repo`. Script: `scratchpad/scan.sh`. Three runs gave: `same-uid=43 unreadable=0` / `102 ms`, `same-uid=41 unreadable=1` / `95 ms`, `same-uid=42 unreadable=0` / `97 ms`. That is about 2.3-2.4 ms per same-uid process (python3 check: 97/42 = 2.31, 102/43 = 2.37).

## Findings

#### 1. install.sh's `/proc` scan costs time in proportion to the uid's process count, and `--jobs` raises that count inside the file that bounds the speedup

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:1165-1182` (`procs_in_checkout`), called via `agent_gate` (`:560`, `:792`, `:1004`, `:1343`), exercised by `test/install-host.bats`
**Move:** Count the hidden multiplications; find the contention point (the host's process table is shared global state)
**Classification:** Macro (cost grows with the number of concurrent same-uid processes, which N multiplies) / Hot (every `--jobs` gate run; install-host.bats is the file named as the speedup bound, `docs/working/questions.md:183`)
**Confidence:** Medium. The per-process cost is measured (P1). The process count under `--jobs` and the number of gate calls per file run are estimated, not measured.
**Baseline:** about 2.3 ms per same-uid process, about 100 ms per scan at 41-43 processes, measured by probe P1 in this session, 2026-09-30 (serial, idle suite)
**Legibility-target:** for-orchestrator-synthesis

Evidence:

```bash
# devcontainer-config/install.sh:1165-1175 (excerpt; the loop continues to :1181 with in_lineage, the cmdline read and the printf; the function ends :1182; read)
procs_in_checkout() {
  local root d pid cwd cmd kind
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 3
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
    if cwd="$(readlink "$d/cwd" 2>/dev/null)"; then
      case "$cwd" in "$root"|"$root"/*) kind=in ;; *) continue ;; esac
    else
      kind=unknown
```

Each same-uid process costs one command-substitution subshell and one `readlink` exec, even when it is skipped. install-host.bats calls the installer at 111 sites (`rg -c 'bash "\$INSTALL"|run_pty|run_pty_feed'`), and a run can reach up to 4 `agent_gate` sites. In a serial run with about 42 same-uid processes, that is roughly 0.1 s per scan: about 11-22 s over the file at 1-2 scans per invocation (python3: 111 × 0.1 = 11.1, × 2 = 22.2). Under `--jobs 16`, each of the other 15 slots adds at least a `bats-exec-file`, a `bats-exec-test` and the test's own subprocesses to the same uid, and `parallel` adds its perl process. If that roughly triples the process count (an assumption; verify the count), the scan cost on the critical-path file rises to about 33-67 s. That erodes the speedup exactly where the fact-check says the bound is set (Claim 4). The diff does not touch install.sh, but the diff is what creates the concurrent processes. The header's "The slowest file therefore bounds the speedup" (`scripts/run-tests.sh:88`) quietly assumes that the slowest file's duration does not grow with N. For this file, it does.

**Recommendation:** Before settling on a default N, time `bats test/install-host.bats` alone and inside a `--jobs 16` full run, and log `ls -d /proc/[0-9]* | wc -l` for the uid during the run. If the file lengthens materially, stub the `/proc` scan in install-host.bats' default setup the way `pgrep` is stubbed (`test/install-host.bats:41`), and keep T88-T92 on the real scan. That also removes the cross-file exposure in finding 3.

#### 2. Files are dispatched in path order, not longest first, so the critical-path files start late

**Severity:** Low
**Location:** `scripts/run-tests.sh:192-194` (candidate order), `:413` (the exec that hands the files to bats in that order)
**Move:** Check the asymptotic behaviour, not just the constant (list scheduling order)
**Classification:** Macro (scheduling order sets makespan) / Hot (every full `--jobs` run), bounded (Graham's list-scheduling bound: at most (2 − 1/N) × optimal)
**Confidence:** Medium on the mechanism, Low on the magnitude (no per-file durations have been measured)
**Baseline:** 742 s wall, full suite, serial, 16 cores, main 2bf5979, 2026-09-28 (`docs/working/proposal-2026-09-27-smaller-review-units.md:109-111`); the two slowest tests are health-check.bats at 54.6 s and 48.9 s (same source, :113)
**Legibility-target:** for-author

Evidence:

```bash
# scripts/run-tests.sh:191-195
else
  while IFS= read -r -d '' file; do
    candidates+=("$file")
  done < <(find "$TEST_DIR" -name '*.bats' -print0 | sort -z)
fi
```

`parallel` starts jobs in argument order as slots free up. In the sorted list, install-host.bats is file 26 of 124 and health-check.bats is file 43 (`find test -name '*.bats' -print0 | sort -z | nl`). health-check.bats holds at least 103.5 s in just its two nested health-check tests. That is more than twice the 46 s per-slot share of the serial total on 16 slots (python3: 742/16 = 46.4). So it, not install-host.bats, may well be the critical-path file. The "install-host, the slowest suite" premise (`docs/working/questions.md:183`, `proposal...:115`) is unmeasured. Wall time is roughly that file's start time plus its duration. With a mean file time of about 6 s (742/124), a file at position 43 starts after roughly the first 27 files have passed through 16 slots, which is on the order of 10-15 s. That is a modest share of a roughly 120 s run, not a cliff. The cost stays bounded, but it is paid on every run.

**Recommendation:** Measure per-file wall time once (`bats -T` or timestamps from a `--jobs` run). If one or two files dominate, have the runner move a short, named list of known-slow files to the front of `files` when `jobs > 1`. That is longest-first on a known list, not a new sort. Record the measured critical-path file in the header instead of "install-host".

#### 3. Cross-file exposure of install-host's `kind=unknown` refusal: the within-file flag does not cover it, and `--jobs` multiplies process churn

**Severity:** Low
**Location:** `devcontainer-config/install.sh:1171-1180`; `test/install-host.bats:1529-1552` (T88, whose second half asserts `status 0`) and `:1554-1561` (T89, `status 0`); `scripts/run-tests.sh:86-88` (the header's justification)
**Move:** Find the contention point (shared global state: the uid's process table)
**Classification:** Macro (couples one file's pass/fail to every concurrent process of the uid) / Hot (every `--jobs` gate run)
**Confidence:** Low. The mechanism was read. No flake under `--jobs` has been observed, and the full suite was not run, per the brief.
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-orchestrator-synthesis

Evidence:

```bash
# scripts/run-tests.sh:84-88 (excerpt of the "Parallel runs" paragraph, which continues to :97; read)
# Parallel runs: --jobs N (N > 1) hands bats `--jobs N
# --no-parallelize-within-files`, so whole files run side by side and the
# tests within a file stay serial, as the suites were written: a file's tests
# may share state (install-host.bats' install.sh scans the real /proc for
# processes in its checkout).
```

```bash
# test/install-host.bats:1546-1551 (excerpt of T88, :1529-1552; read)
  # Once it has gone, the same run installs.
  wait "$helper" 2>/dev/null || true
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *'BLESS-STUB --bless'* ]]
```

Fact-check Claim 3 (Incorrect) is binding here. The scan's hazard is not state shared within the file. It is `kind=unknown` for any concurrent same-uid process with an unreadable cwd, and `--no-parallelize-within-files` leaves other files' processes running beside it. My read of the rest of the suite narrows the realistic sources. The only test that makes a same-uid process hide its cwd is install-host's own T92 (`prctl(4, 0...)`, `:1594-1598`), which is serial within that file. No other `.bats` or `.bash` under `test/` runs `sudo`, `ssh-agent`, `bwrap` or `unshare`, or calls `prctl` (`rg -l`). What is left is transient unreadability. P1 saw `unreadable=1` in 1 of 3 scans of this session's `/proc`. The real function then reads `cmdline` and skips the process when that is empty (`:1179`), which should cover an exiting process. That is my inference from the code and was not execution-verified. Under `--jobs N`, the number of short-lived same-uid processes during an install-host scan grows roughly N-fold, so any window between a failed `readlink` and a non-empty `cmdline` is hit more often. Where it is hit, T88's and T89's `status 0` assertions fail with a refusal. The header, meanwhile, tells the reader this file is the protected case.

**Recommendation:** As the fact-check says, rewrite `:86-88` to cite a real within-file example (health-check.bats' `setup_file`/`BATS_FILE_TMPDIR` cache, `test/scripts/health-check.bats:25-40`), and to say that install-host's `/proc` scan stays exposed to other files under `--jobs`. Run install-host.bats about 5 times beside a `--jobs` full run before trusting the gate (Q-086 perf finding 2). The stub from finding 1 would close this too.

#### 4. Fixed sleeps and polling windows in the slow suites assume an uncontended CPU, and N has no cap relative to cores

**Severity:** Low
**Location:** `scripts/run-tests.sh:124-132` (N accepted without an upper bound); `test/install-host.bats:170-172` (`FEED_TAMPER`), `:531-555` (T67's 5 ms poll loop and 1.5 s swap window); `test/scripts/run-tests.bats:88-98` (10 s `wait_unlocked`/`wait_for`)
**Move:** Find the contention point (CPU); ask what the size of N is
**Classification:** Macro (oversubscription stretches every timing window at once) / Hot (gate runs)
**Confidence:** Low
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-author

Evidence:

```bash
# test/install-host.bats:170-172
FEED_TAMPER='printf "n\n"
  for _i in $(seq 200); do compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*/installed" >/dev/null && break; sleep 0.1; done
  sleep 2; if eval "$TAMPER"; then : > "$HOME/../tamper.landed"; fi; printf "y\n"'
```

```bash
# scripts/run-tests.sh:125
      if [[ ! "${2:-}" =~ ^[1-9][0-9]*$ ]]; then
```

The pty tests time their tamper and answer with a wall-clock `sleep 2` ("give the review time to finish", `:165-166`). T67 relies on a helper that swaps a file back after `sleep 1.5`. install-host.bats has 21 `sleep N` lines (`rg -c`). CPU-heavy neighbours sharing the machine under `--jobs` include the nested health-check runs (54.6 s and 48.9 s serial) and the hermeticity scans (about 8 s each, proposal :113). With N at or above 16 on 16 cores, those windows stretch. In a serial run, only the agent competes for CPU. I did not trace, per test, which direction a late window fails (false pass or false fail), so this is a flake risk and not a demonstrated defect. N itself is unbounded: `--jobs 500` passes the regex and gives `parallel` 500 slots over 124 files.

**Recommendation:** Say in the header that N above `nproc` buys nothing, since at most 124 files run and each is CPU-bound. Optionally clamp N to `nproc` with a note. Include `--jobs 16` repeat runs of install-host.bats and run-tests.bats in the measurement that finding 1 asks for.

#### 5. The serial `bats --count` pre-pass becomes a larger share of a parallel run's wall time

**Severity:** Informational
**Location:** `scripts/run-tests.sh:402` (the header's cost note is at `:55-56`)
**Move:** Find the work that moved to the wrong place (serial prelude before a parallel phase: Amdahl)
**Classification:** Micro (fixed cost per run) / Hot (every recorded run)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative (the header documents "about 15 s", `scripts/run-tests.sh:56`; I found no measurement record for that number and did not re-measure it)
**Legibility-target:** for-author

Evidence:

```bash
# scripts/run-tests.sh:398-408
if [[ "$recording" == true ]]; then
  bats_args+=("$RUN_LOG_ANCHOR")
  # See "Run logs" in the header. A count bats cannot give is recorded as "?",
  # which --failed refuses.
  expected="$(bats --count "${files[@]}" 2>/dev/null)" || expected="?"
  {
    echo "expected=$expected"
    echo "prev-log=$(newest_log)"
    printf '%s\n' "${files[@]}"
  } > "$LAST_RUN"
fi
```

This is pre-existing and unchanged by the diff. But `--jobs` shrinks the parallel phase and leaves this serial prelude as it is. If the documented 15 s holds, it is about 2% of a 742 s serial run (python3: 15/742 = 0.020), and about 12% of a run that `--jobs 16` brings down to roughly 125 s. The last-run file is only read by a later `--failed`, which cannot start while this run holds the lock (`:209-215`). So the count could overlap with the bats run instead of preceding it.

**Recommendation:** Measure the count's cost once in the `--jobs` measurement. If it holds at about 15 s, consider computing it in a background subshell that inherits fd 9 and writes `$LAST_RUN`, which keeps the lock's "held until every process has exited" property, since `exec bats` replaces the shell. Otherwise leave it as is.

## Endorsements

- Two concurrent files cannot share a `BATS_TEST_TMPDIR` or a `BATS_FILE_TMPDIR`. Both are keyed by the test's line number in the one suite-wide test list: `BATS_TEST_TMPDIR="$tests_tmpdir/$BATS_SUITE_TEST_NUMBER"` and `BATS_FILE_TMPDIR="$bats_files_tmpdir/${BATS_FILE_FIRST_TEST_NUMBER_IN_SUITE?}"`, with the first number taken from `line_number` in the list file. So the per-test isolation the suites rely on (install-host's `HOME`/`TMPDIR` pins, cc-push's `GIT_CONFIG_GLOBAL`) carries over to file-level parallelism. `[read: /usr/libexec/bats-core/bats-exec-test:50,69; /usr/libexec/bats-core/bats-exec-file:265-282,322]`
- `--no-parallelize-within-files` keeps the Q-086 finding-1 path out of play, the `bats_semaphore_acquire_slot` busy-wait with `sleep 1` polling. Tests within a file take the serial loop. `[fact-check: claim 2 — Verified]`
- Concurrent run-log appends produced a complete log in the 2-job fixture run (`expected=4`, 4 result lines, `--failed` re-ran exactly the failure). This is scoped to that fixture and was not shown at 124 files. `[fact-check: claim 7 — Verified]`
- run-tests.bats' nested runners pass the real `HOME` (`in_runner`, `test/scripts/run-tests.bats:66`), so the outer and nested `parallel` processes share `~/.parallel`. The claim is that concurrent writes to parallel's line-length cache cannot corrupt it, because it writes `$len_cache.$$` and then `rename`s it into place. `[read: /usr/bin/parallel:13118-13139]`
- The suite's cross-file shared state, beyond the uid's process table and CPU, is limited to reads of the real checkout. No `.bats`/`.bash` under `test/` writes a fixed path under the real `$HOME`, `/tmp` or the repo, or writes an unredirected git global config, and none binds a port. The fixed `/tmp/...` strings `rg` found are guard payloads or nonexistent-file probes. `[unverified — submitted as claim]` (checked by `rg` over the patterns `$HOME/`, `/tmp/<name>`, `git config --global`, `REPO_ROOT`/`BATS_TEST_DIRNAME` write targets and `port`/`localhost:`. A pattern scan cannot show absence; route to code-fact-check, or confirm with a `--jobs` run under a fresh HOME and `inotifywait` on `$HOME` and the checkout)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `/proc` scan cost scales with the uid's process count, which `--jobs` raises inside the speedup-bounding file | Medium | `devcontainer-config/install.sh:1165-1182` | Medium |
| 2 | Path-order dispatch starts the critical-path files (health-check.bats at #43, install-host.bats at #26) late; which file is slowest is unmeasured | Low | `scripts/run-tests.sh:192-194` | Medium (mechanism) / Low (size) |
| 3 | install-host's `kind=unknown` refusal is exposed to other files' processes; the header claims otherwise | Low | `devcontainer-config/install.sh:1171-1180`, `scripts/run-tests.sh:86-88` | Low |
| 4 | Fixed sleeps and polling windows under CPU oversubscription; N unbounded | Low | `test/install-host.bats:170-172`, `scripts/run-tests.sh:125` | Low |
| 5 | Serial `bats --count` prelude grows as a share of parallel wall time | Informational | `scripts/run-tests.sh:402` | Medium |

## Overall Assessment

The diff's own code is cold and cheap: one regex, one `command -v`, three extra bats flags. Choosing file-level-only parallelism is the right first step (Q-086's recommendation, fact-check Claims 2 and 7). None of the findings blocks this change on performance grounds. The structural risk sits outside the diff. The file expected to bound the speedup, install-host.bats, contains a process-table scan whose cost and whose pass/fail both depend on how many other processes the uid runs, and `--jobs` exists to raise that number. The second risk is that nobody has measured which file is actually the critical path: health-check.bats' two nested runs alone take 103.5 s. The most important next step is the measurement Q-090 already calls for, extended to (a) per-file wall time, (b) install-host.bats' duration alone versus inside a `--jobs 16` run, with the uid's process count logged, and (c) about 5 repeat runs to catch timing or `/proc` flakes. Fix the header's install-host sentence (fact-check Claim 3) in this change. Findings 1, 2 and 4 are fixable in place once the numbers exist: stub the scan, put known-slow files first, and cap or document N.

## Goal-Alignment Note

- Success criterion (restated verbatim): "a markdown report saved at the path named below, structured per the skill."
- Answered: yes. The report is saved at docs/reviews/q090-performance-review-2026-09-30.md with `Commit: 088bc97` at the top, in the skill's structure. Every finding carries Severity, Location, verbatim Evidence, Confidence, Baseline, Classification and Legibility-target.
- The brief's specific asks: the fact-check escalation on install-host's `kind=unknown` exposure is finding 3, which also builds on Q-086 perf finding 2. The cross-file shared-state sweep covered `$HOME`, `/tmp`, repo writes, git config and ports by reading. It found only the process table and the CPU (findings 1, 3 and 4) and filed the rest as an unverified endorsement.
- Out of scope, or not done: no full-suite or `--jobs` run (the brief forbids the full suite because of the run lock), so the magnitudes in findings 1, 2, 4 and 5 are estimates. The only execution was probe P1, a copy of the scan loop against the live `/proc`, run under `timeout` in the scratchpad with no process left running.
- Decisions I made: I rated finding 1 Medium and not High, the matrix default for Macro × Hot, because the process-count multiplier is assumed and the cost is bounded by the uid's process count. I used the speculative disclaimer for finding 5 even though the header documents "about 15 s", because I found no record of that measurement.
