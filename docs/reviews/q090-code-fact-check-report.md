# Code Fact-Check Report

**Commit:** 088bc97
**Replication:** k=1 (loop pass, decision 031)
**Repository:** /workspace/.claude/wt-run-tests-jobs (branch feat/run-tests-jobs)
**Scope:** `git diff main...HEAD`: scripts/run-tests.sh (header "Parallel runs", `--jobs` flag docs, parsing, the `bats_args` block) and test/scripts/run-tests.bats (7 new tests plus `parallel_shim`), and the commit message of 088bc97. Claims were checked against the code that runs them: bats 1.8.2 (`/usr/libexec/bats-core/{bats,bats-exec-suite,bats-exec-file,bats-exec-test}`), `/usr/lib/bats-core/semaphore.bash` and GNU parallel 20221122+ds-2 (`/usr/bin/parallel`).
**Checked:** 2026-09-30
**Total claims checked:** 23
**Summary:** 17 verified, 5 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 30 lines). No claim matches a logged pattern. The closest class is "specific counts quoted from an artifact set": the brief says 7 new tests, and tests 20-26 in `q090-fc-k1-E4-suite-unmutated.log` are exactly 7.

All executed probes ran with `LC_ALL=C.UTF-8`. Logs are under `docs/reviews/execution-logs/q090-fc-k1-*.log`. Every probe ran in the foreground under `timeout`, and no probe process is left (checked with `pgrep` before reporting). The full suite was not run. Mutants were built in throwaway copies under the session scratchpad (`.../scratchpad/q090fc/mut-*`), never in the worktree.

| Probe | Command (summary) | cwd | Exit | UTC |
|---|---|---|---|---|
| E1 | `bats --jobs 2 [--no-parallelize-within-files] files/one.bats` with a PATH that has no `parallel`, then with one | scratchpad/q090fc | 1, 1, 0 | 2026-09-30T21:09:33Z |
| E2 | `bats --jobs 2 --no-parallelize-within-files g/a.bats g/b.bats`, each line time-stamped, per-test start/end times; contrast run without the flag; E2b with the files swapped | scratchpad/q090fc | 0 (E2b; E2's `exit=` is blank because of a zsh `PIPESTATUS` slip, and its TAP shows all ok) | 21:09:45Z / 21:09:57Z |
| E3 | `script -qec "parallel echo ::: x; test -t 2 && echo STDERR_IS_TTY"` with a fresh HOME; `rg citation_notice /usr/bin/parallel`; `bats --jobs 2 ...` under `script` (pretty formatter) | scratchpad/q090fc | 0, 0 | 21:10:10Z |
| E4 | `timeout 300 bats test/scripts/run-tests.bats` (unmutated, 26 tests) | worktree | 0 | 21:10:22Z |
| E5 | 4 mutants of run-tests.sh, each running `bats -f '<test>' test/scripts/run-tests.bats` | scratchpad/q090fc/mut-* | 1 each | 21:10:46Z |
| E6 | `bash scripts/run-tests.sh --jobs {∅,0,02,-1,x,--failed}` and `--jobs 2 --failed --slow`; bash overflow probe | worktree (exits before the lock) | 2 each | 21:11:14Z |
| E7 | `env -i LANG=C.UTF-8 LC_CTYPE=xx_XX.UTF-8 perl -e 1` and `locale_installed` for the same env | /workspace/.claude/wt-digest | 0 | 21:11:25Z |

---

## Claim 1: "--jobs N  Run up to N test files at once (see "Parallel runs"). N is a positive integer; anything else is a usage error (exit 2). 1, the default, runs serially. Combines with every other flag, --failed included."

**Location:** `scripts/run-tests.sh:36-39`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parse (missing, 0, 02, -1, x and a following flag all exit 2), the default of 1 adding no bats flag, and `--jobs` combined with `--failed` (test 23) and with FILE (tests 24, 26). It does not establish that N is honoured for decimal strings too large for bash: `18446744073709551617` passes the regex and wraps to 1, so it runs serially without a warning (E6). It also does not establish that `02`, a positive integer written with a leading zero, is accepted: it is rejected.

The parse is:

```bash
# scripts/run-tests.sh:124-132
    --jobs)
      if [[ ! "${2:-}" =~ ^[1-9][0-9]*$ ]]; then
        echo "--jobs takes a positive integer, got: ${2:-(nothing)}" >&2
        usage
        exit 2
      fi
      jobs="$2"
      shift 2
      ;;
```

The default is `jobs=1` (`scripts/run-tests.sh:115`), and flags are added only under `if [[ "$jobs" -gt 1 ]]; then` (`:390`). E6 shows exit 2 for each malformed value, and `--jobs 2 --failed --slow` exits 2 through the pre-existing `--failed` conflict (`:147-151`). The bash probe `[[ 18446744073709551617 -gt 1 ]]` prints `notgt` (E6).

**Evidence:** `scripts/run-tests.sh:115`, `scripts/run-tests.sh:124-132`, `scripts/run-tests.sh:147-151`, `scripts/run-tests.sh:390-396`, docs/reviews/execution-logs/q090-fc-k1-E6-jobs-usage.log, docs/reviews/execution-logs/q090-fc-k1-E4-suite-unmutated.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "--jobs N (N > 1) hands bats `--jobs N --no-parallelize-within-files`, so whole files run side by side and the tests within a file stay serial"

**Location:** `scripts/run-tests.sh:84-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the flag hand-off (`scripts/run-tests.sh:392`), bats forwarding the flag to every `bats-exec-file`, and observed concurrency: files overlap, and tests within a file do not. It does not establish that no suite re-enables within-file parallelism: `bats-exec-file` reads `BATS_NO_PARALLELIZE_WITHIN_FILE` after sourcing the file, so a suite could set it to `False`. No non-doc file in the repo sets it (`rg BATS_NO_PARALLELIZE`).

```bash
# /usr/libexec/bats-core/bats-exec-suite:415-420 (excerpt of the dispatch if/else; the else branch :421-429 is the serial loop — read)
if [[ "$num_jobs" -gt 1 ]] && [[ -z "$bats_no_parallelize_across_files" ]]; then
  ...
  parallel --keep-order --jobs "$num_jobs" bats-exec-file "$(printf "%q " "${flags[@]}")" "{}" "$TESTS_LIST_FILE" ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1
```

`--no-parallelize-within-files` is added to `flags` at `bats-exec-suite:47-49`. `bats-exec-file:24-26` sets `BATS_NO_PARALLELIZE_WITHIN_FILE=1`, and `bats-exec-file:294` takes the serial loop unless `"${BATS_NO_PARALLELIZE_WITHIN_FILE-False}" == False`. In E2, b1 ran 0.35 ms after a1 started, so the two files overlapped. a1, a2 and a3 ran strictly one after another. Without the flag, a2 and a3 overlapped (contrast run in the same log). Mutant `mut-nowithin` (flag dropped) fails test 21 (E5).

**Evidence:** `scripts/run-tests.sh:390-396`, `/usr/libexec/bats-core/bats-exec-suite:47-49`, `/usr/libexec/bats-core/bats-exec-suite:415-420`, `/usr/libexec/bats-core/bats-exec-file:24-26`, `/usr/libexec/bats-core/bats-exec-file:286-314`, docs/reviews/execution-logs/q090-fc-k1-E2-grouping-order-within-file.log, docs/reviews/execution-logs/q090-fc-k1-E5-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "a file's tests may share state (install-host.bats' install.sh scans the real /proc for processes in its checkout)"

**Location:** `scripts/run-tests.sh:86-88`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the named example is state shared between the tests of one file that within-file serialisation protects. It does not establish that install-host.bats actually flakes under `--jobs`, which was not run, per the brief's no-full-suite rule. It also does not dispute the general statement that some suites share per-file state: `setup_file`/`BATS_FILE_TMPDIR` appear in `test/cross-model-review-stage1.bats`, `test/lite-review-grammar.bats`, `test/scripts/health-check.bats` and `test/scripts/run-tests.bats` (`rg -l`).

The /proc scan is not state shared between one file's tests. Each install-host test builds its own checkout:

```bash
# test/install-host.bats:24 and :33 (excerpts of setup(), which runs :22-43 — read)
  S="$BATS_TEST_TMPDIR"
  ROOT="$S/repo"
```

The scan reads every process this uid owns:

```bash
# devcontainer-config/install.sh:1165-1172 (excerpt; procs_in_checkout continues to :1182 — read)
procs_in_checkout() {
  local root d pid cwd cmd kind
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 3
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
    if cwd="$(readlink "$d/cwd" 2>/dev/null)"; then
      case "$cwd" in "$root"|"$root"/*) kind=in ;; *) continue ;; esac
```

A concurrent sibling test in the same file has a readable cwd outside this test's `$S/repo`, so it matches neither `in` nor `unknown`. The only exposure is `kind=unknown`: any concurrent process of the same uid whose cwd cannot be read. That exposure is host-global. Under `--jobs`, other files' `bats-exec-file` processes are still concurrent (Claim 2), and they are not in install.sh's lineage (siblings under `parallel`, exempted only via `in_lineage` at `:1177`). So the flag this sentence justifies does not remove the hazard it names. A reader can wrongly conclude that install-host.bats is protected under `--jobs`. q086-performance-review-2026-09-28.md finding 2 says the same: "a sibling's readable cwd will almost never match `kind=in`. The exposure is to `kind=unknown`: any concurrent same-uid process". Fix: cite real within-file shared state (a `setup_file`/`BATS_FILE_TMPDIR` suite), and state that install-host's /proc scan is exposed to concurrent processes from other files, which `--jobs` still runs.

**Evidence:** `test/install-host.bats:22-43`, `devcontainer-config/install.sh:1150-1182`, `/usr/libexec/bats-core/bats-exec-suite:415-420`, `docs/reviews/q086-performance-review-2026-09-28.md:55-83`
**Legibility-target:** for-author

---

## Claim 4: "The slowest file therefore bounds the speedup."

**Location:** `scripts/run-tests.sh:88`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lower bound on wall time: with tests serial within a file, a run takes at least as long as its slowest file. It does not establish other bounds, such as N itself or `parallel` start-up cost, which are unmeasured.

In E2, the 3-test a.bats file (3 × 1 s, serial) finished at t0+3.14 s while b.bats finished at t0+0.1 s. Wall time equals a.bats' serial time (paraphrased — no quote available because the value is a timing read from the captured log, not a source line).

**Evidence:** `/usr/libexec/bats-core/bats-exec-file:297-313`, docs/reviews/execution-logs/q090-fc-k1-E2-grouping-order-within-file.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: "bats runs files through GNU parallel and aborts without it even for one file, so when `parallel` is not on PATH the runner warns and runs serially." (also the code comment "Test for parallel itself, not the file count: bats aborts without it whenever N > 1.")

**Location:** `scripts/run-tests.sh:89-90`, `scripts/run-tests.sh:388-389`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bats' abort for one file with and without `--no-parallelize-within-files`, the runner's `command -v parallel` fallback and its warning, and that the fallback still records. It does not establish that the `parallel` found is GNU parallel. `command -v` accepts any `parallel`, and this host carries moreutils' `/usr/bin/parallel.moreutils` (dpkg diversion); if that were on PATH as `parallel`, bats would run it with GNU options. "Whenever N > 1" holds for the flags the runner passes; bats itself exempts `--no-parallelize-across-files`, which the runner never passes.

```bash
# /usr/libexec/bats-core/bats-exec-suite:99-103 (excerpt; the if block ends :107 — read)
if [[ "$num_jobs" != 1 ]]; then
  if ! type -p parallel >/dev/null && [[ -z "$bats_no_parallelize_across_files" ]]; then
    abort "Cannot execute \"${num_jobs}\" jobs without GNU parallel"
```

The check runs before any file is counted. E1: `Error: Cannot execute "2" jobs without GNU parallel`, exit 1, for a single file, both with and without `--no-parallelize-within-files`. With `parallel` present, the same one-file run goes through the `parallel` branch (`bats-exec-suite:415`, which has no file-count condition). The runner:

```bash
# scripts/run-tests.sh:390-396
if [[ "$jobs" -gt 1 ]]; then
  if command -v parallel > /dev/null; then
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
  else
    echo "WARNING: --jobs $jobs needs GNU parallel, which is not on PATH; running serially" >&2
  fi
fi
```

Test 26 passes (E4), and mutant `mut-fallback` (the `command -v` guard removed) fails it at `[ "$status" -eq 0 ]` (E5).

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-107`, `/usr/libexec/bats-core/bats-exec-suite:415-429`, `scripts/run-tests.sh:388-396`, docs/reviews/execution-logs/q090-fc-k1-E1-abort-without-parallel.log, docs/reviews/execution-logs/q090-fc-k1-E5-mutants.log, docs/reviews/execution-logs/q090-fc-k1-E4-suite-unmutated.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "bats keeps each file's output together and in order (parallel --keep-order), so a file's results appear when the whole file ends."

**Location:** `scripts/run-tests.sh:91-92`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both output modes the runner can reach: TAP when piped (the `cat` formatter), and pretty on a tty (E3). It does not establish output timing when a file itself runs its tests in parallel, which the runner never allows.

The observed behaviour matches, but the parenthetical names the wrong mechanism for half of it. bats calls `parallel --keep-order --jobs "$num_jobs" ...` with no `--ungroup`/`--line-buffer` (`bats-exec-suite:420`). Keeping a job's output together comes from parallel's default `--group`; `--keep-order` supplies only the ordering. `bats-exec-test` writes TAP to fd 3, which is `exec 3<&1` (`bats-exec-test:330`), so TAP goes to the job's stdout, which parallel captures. The conclusion also needs a qualifier. In E2, b.bats (second argument) finished at t0+0.1 s, but its `ok 4 b1` printed at t0+3.15 s, together with a.bats' lines. A file's results therefore appear once that file and every file before it have ended. In E2b, with b.bats first, `ok 1 b1` printed at t0+0.10 s. Precise version: "bats groups each file's output (parallel's default --group) and prints files in argument order (--keep-order), so a file's results appear once it and every earlier file have ended."

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, `/usr/libexec/bats-core/bats-exec-test:159-190`, `/usr/libexec/bats-core/bats-exec-test:330`, docs/reviews/execution-logs/q090-fc-k1-E2-grouping-order-within-file.log, docs/reviews/execution-logs/q090-fc-k1-E3-citation-tty.log
**Legibility-target:** for-author

---

## Claim 7: "Every test still writes its own run-log line, so the run log, the test-count check and --failed work as in a serial run."

**Location:** `scripts/run-tests.sh:92-94`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-test line under `parallel`, completeness of the log (`expected=4`, 4 result lines), `--failed --jobs 2` with the empty anchor handed first and `--filter-status failed` set, and refusal of a killed parallel run. It does not establish the line order inside the log: files interleave. The runner's checks do not depend on order (`sort -u`/`awk` at `:241-243`; bats sorts the log at `bats-exec-suite:259`). It also does not establish Ctrl-C (SIGINT) behaviour under `parallel`, which was not exercised.

```bash
# /usr/libexec/bats-core/bats-exec-test:185-186 (excerpt of bats_exit_trap's tail; the trap continues to the gather-outputs block — read)
  if [[ -z "$should_retry" ]]; then
    printf "%s %s\t%s\n" "$state" "$BATS_TEST_FILENAME" "$BATS_TEST_NAME" >>"$BATS_RUNLOG_FILE"
```

`BATS_RUNLOG_FILE` is exported before dispatch (`bats-exec-suite:199`), so `parallel`'s local jobs inherit it. The log directory comes from the first argument, `TEST_ROOT=${1-}` (`bats-exec-suite:184-186`), which is the anchor (`scripts/run-tests.sh:398-399`). The anchor becomes a `parallel` job with no tests, and `bats-exec-file:342-344` exits 0 for it. Under `--filter-status`, the filtered list is written to `$TESTS_LIST_FILE` before `parallel` starts (`bats-exec-suite:261-269`). Tests 23 and 24 pass (E4). Test 23 covers `expected=4`, 4 `passed|failed` lines, and `--failed --jobs 2` re-running only `alpha flaky` followed by "nothing to re-run". Test 24 covers "recorded … of 4 tests: it did not complete".

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:184-200`, `/usr/libexec/bats-core/bats-exec-suite:204-283`, `/usr/libexec/bats-core/bats-exec-file:338-344`, `/usr/libexec/bats-core/bats-exec-test:185-186`, `scripts/run-tests.sh:241-247`, `scripts/run-tests.sh:398-413`, `test/scripts/run-tests.bats:376-411`, docs/reviews/execution-logs/q090-fc-k1-E4-suite-unmutated.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "bats folds parallel's stderr into its output; the locale pin above keeps perl's setlocale warnings out of it"

**Location:** `scripts/run-tests.sh:94-95`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `2>&1` on the `parallel` line and the pin's effect when the ambient LC_ALL/LANG is uninstalled. It does not establish the case the pin never inspects: LC_ALL unset, LANG installed and a category variable such as LC_CTYPE uninstalled. There `locale_installed` passes, no pin fires, and perl still warns (E7). That limit comes from the pre-existing pin's definition (`:78`, "ambient locale (LC_ALL, else LANG)"), not from this diff. The fold also covers the stderr of every `bats-exec-file`, which a serial run leaves on bats' stderr.

`2>&1` ends the `parallel` line at `bats-exec-suite:420` (quoted in Claim 2). bats pipes `bats-exec-suite` into the validator and the formatter (`bats:464-466`). Mutant `mut-locale-noexport` keeps the pin's message but drops `export LC_ALL="$pinned"`. Test 25 then fails at `! grep -iE 'perl|setlocale|cite|citation' <<< "$output"` with `# perl: warning: Setting locale failed.` in the output (E5). The unmutated test passes (E4).

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, `/usr/libexec/bats-core/bats:456-467`, `scripts/run-tests.sh:153-162`, `test/lib/hermetic-env.bash:70-80`, docs/reviews/execution-logs/q090-fc-k1-E5-mutants.log, docs/reviews/execution-logs/q090-fc-k1-E7-lcctype-residue.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "parallel prints its citation notice only when its stderr is a terminal, which inside bats it never is."

**Location:** `scripts/run-tests.sh:95-97`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tty condition in parallel's `citation_notice` body, the non-tty stderr inside bats in both formatter modes the runner can reach (bats without `-F` uses `tap`→`cat`, or `pretty` when stdin and stdout are ttys and CI is unset; both are piped, as is the `--report-formatter` path), and what the installed build actually does. It does not establish behaviour with an upstream (non-Debian) parallel, whose source was not available.

"Never a terminal inside bats" holds. `parallel ... 2>&1` sends stderr to `bats-exec-suite`'s stdout, and both branches of `bats:458-466` pipe that into `bats_test_count_validator | "$interpolated_formatter"`. The runner passes no formatter flag. The function does test the tty:

```perl
# /usr/bin/parallel:5637-5643 (excerpt of sub citation_notice, which runs :5632-5700+ — read to the else branch)
    if($opt::willcite
       or
       $opt::plain
       or
       not -t $Global::original_stderr
       or
       grep { -e "$_/will-cite" } @Global::config_dirs) {
```

On this host, though, the function is never called:

```perl
# /usr/bin/parallel:2578
#    citation_notice();
```

This is Debian's patch (package `20221122+ds-2`; changelog "Re-add patch to remove citation option"). In E3, `parallel` under `script` (stderr a tty, fresh HOME, no will-cite) printed only `x`. Precise version: "…only when its stderr is a terminal (Debian's build never prints it), and inside bats stderr is always a pipe."

**Evidence:** `/usr/bin/parallel:2578`, `/usr/bin/parallel:5632-5667`, `/usr/libexec/bats-core/bats:142-149`, `/usr/libexec/bats-core/bats:334-336`, `/usr/libexec/bats-core/bats:456-467`, `/usr/libexec/bats-core/bats-exec-suite:420`, docs/reviews/execution-logs/q090-fc-k1-E3-citation-tty.log
**Legibility-target:** for-author

---

## Claim 10: "parallel_shim: put a `parallel` first on PATH that logs its arguments to $T/parallel.args and execs the real one, so a test can see bats used it."

**Location:** `test/scripts/run-tests.bats:329-330`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shim's content and that it stays on the runner's PATH (`in_runner` strips only `$BATS_LIBEXEC`). It does not establish anything about `runner_bg`, which also rebuilds PATH from `$PATH` and so keeps the shim too.

```bash
# test/scripts/run-tests.bats:331-341
parallel_shim() {
  local real
  real="$(command -v parallel)" || skip "GNU parallel is not installed here"
  mkdir -p "$BATS_TEST_TMPDIR/shim"
  printf '%s\n' '#!/usr/bin/env bash' \
    "printf '%s\n' \"\$*\" >> '$T/parallel.args'" \
    "exec '$real' \"\$@\"" > "$BATS_TEST_TMPDIR/shim/parallel"
  chmod +x "$BATS_TEST_TMPDIR/shim/parallel"
  PATH="$BATS_TEST_TMPDIR/shim:$PATH"
}
```

Tests 21 and 25 assert `[ -f "$T/parallel.args" ]` and pass (E4). Mutant `mut-nowithin` fails test 21 at the grep of `parallel.args` (E5), which shows the file records bats' argv.

**Evidence:** `test/scripts/run-tests.bats:58-68`, `test/scripts/run-tests.bats:331-341`, docs/reviews/execution-logs/q090-fc-k1-E4-suite-unmutated.log, docs/reviews/execution-logs/q090-fc-k1-E5-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "--jobs: a missing, zero or non-numeric N is a usage error" (test name)

**Location:** `test/scripts/run-tests.bats:343`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three cases it runs and the check that no test ran. It does not establish negative, leading-zero or overflowing values, which the test does not exercise (E6 covers them).

The test runs `runner --jobs`, `--jobs 0 test/gamma.bats` and `--jobs x test/gamma.bats`, asserting `[ "$status" -eq 2 ]` and the `got:` text each time, then `[[ "$output" != *"gamma clean output"* ]]` (`test/scripts/run-tests.bats:344-353`). It passes (E4, test 20).

**Evidence:** `test/scripts/run-tests.bats:343-353`, docs/reviews/execution-logs/q090-fc-k1-E4-suite-unmutated.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "--jobs 2 runs files through parallel, not tests within a file" (test name)

**Location:** `test/scripts/run-tests.bats:355`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts: `parallel` was invoked, its argv holds `--jobs 2` and `--no-parallelize-within-files`, and all 4 fixture results appear. It does not establish, and the test does not observe, that tests within a file actually ran serially. That rests on bats honouring the forwarded flag, observed separately in E2.

```bash
# test/scripts/run-tests.bats:363-365 (excerpt; the test starts :355 — read)
  [ -f "$T/parallel.args" ]
  grep -q -- '--jobs 2' "$T/parallel.args"
  grep -q -- '--no-parallelize-within-files' "$T/parallel.args"
```

`--jobs 2` matches `parallel`'s own `--jobs "$num_jobs"`. `--no-parallelize-within-files` matches the `%q`-quoted flag string that bats hands `bats-exec-file` (`bats-exec-suite:420`). The test checks the flag hand-off as a proxy for "not within a file". The proxy is sound: the `mut-nowithin` mutant fails it (E5). Precise name: "--jobs 2 runs files through parallel and hands each file --no-parallelize-within-files".

**Evidence:** `test/scripts/run-tests.bats:355-366`, `/usr/libexec/bats-core/bats-exec-suite:420`, docs/reviews/execution-logs/q090-fc-k1-E5-mutants.log, docs/reviews/execution-logs/q090-fc-k1-E2-grouping-order-within-file.log
**Legibility-target:** for-author

---

## Claim 13: "--jobs 1 runs serially and needs no parallel" (test name)

**Location:** `test/scripts/run-tests.bats:368`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `parallel` is never invoked for `--jobs 1` (`[ ! -f "$T/parallel.args" ]`). It does not run with `parallel` absent from PATH, so "needs no parallel" is shown by non-invocation, not by removal. The code path (`scripts/run-tests.sh:390`) adds nothing for N=1, so the two readings coincide.

The test asserts `[ ! -f "$T/parallel.args" ]` after `runner --jobs 1 test/gamma.bats` (`test/scripts/run-tests.bats:370-373`). It passes (E4, test 22).

**Evidence:** `test/scripts/run-tests.bats:368-374`, `scripts/run-tests.sh:390`, docs/reviews/execution-logs/q090-fc-k1-E4-suite-unmutated.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "--jobs: a parallel run records a complete log that --failed re-runs from" (test name)

**Location:** `test/scripts/run-tests.bats:376`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the complete-log assertion (`expected=4`, 4 result lines) and `--failed --jobs 2` re-running exactly the failed test. It does not establish a `--failed` re-run spanning 2 or more files under `parallel`: only alpha.bats had a failure.

The test asserts `[ "$(sed -n 1p "$T/.bats/last-run")" = "expected=4" ]` and `[ "$(grep -cE '^(passed|failed) ' "$LOG_DIR"/*.log)" -eq 4 ]`. It then runs `runner --failed --jobs 2`, expecting `1..1` and `ok 1 alpha flaky` (`test/scripts/run-tests.bats:378-389`). It passes (E4, test 23).

**Evidence:** `test/scripts/run-tests.bats:376-395`, docs/reviews/execution-logs/q090-fc-k1-E4-suite-unmutated.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "--jobs: a parallel run killed partway is refused by --failed" (test name)

**Location:** `test/scripts/run-tests.bats:397`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a TERM to the runner's process group mid-run under `--jobs 2`, followed by the `--failed` refusal. It does not establish the Ctrl-C (SIGINT) path, where bats deletes the log itself.

The test runs `runner_bg ... --jobs 2 test/slow.bats test/gamma.bats`, kills it with TERM, and asserts `rc 143`. It then asserts `--failed` exits 1 with "recorded … of 4 tests: it did not complete" (`test/scripts/run-tests.bats:399-410`). It passes (E4, test 24).

**Evidence:** `test/scripts/run-tests.bats:397-411`, `scripts/run-tests.sh:237-247`, docs/reviews/execution-logs/q090-fc-k1-E4-suite-unmutated.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "--jobs: an uninstalled locale leaves no perl or citation text in the output" (test name, with the comment "gamma asserts its own subprocess output is clean; the suite-level output must be clean too.")

**Location:** `test/scripts/run-tests.bats:413`, `test/scripts/run-tests.bats:419-420`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test asserts both properties and that the perl half discriminates (mutant `mut-locale-noexport` fails it at the grep). It does not establish that the citation half can fail on this host: the installed parallel never calls `citation_notice` (Claim 9), so `cite|citation` in the grep catches nothing here.

`! grep -iE 'perl|setlocale|cite|citation' <<< "$output"` (`test/scripts/run-tests.bats:422`) runs after `in_runner LANG=xx_XX.UTF-8 -- --jobs 2`. E5 shows the grep failing with perl warnings when the export is dropped.

**Evidence:** `test/scripts/run-tests.bats:413-423`, `/usr/bin/parallel:2578`, docs/reviews/execution-logs/q090-fc-k1-E5-mutants.log, docs/reviews/execution-logs/q090-fc-k1-E4-suite-unmutated.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "# A PATH holding everything the current one does except parallel." (fallback test)

**Location:** `test/scripts/run-tests.bats:426`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the loop that builds the PATH. It does not establish anything about the test's assertions, which pass (E4, test 26) and discriminate (E5, `mut-fallback`).

The loop also leaves out bats' libexec directory and non-executables, and keeps only the first entry of each name:

```bash
# test/scripts/run-tests.bats:430-435 (excerpt; the test continues to :446 — read)
  for dir in $PATH; do
    [[ -d "$dir" && "$dir" != "$BATS_LIBEXEC" ]] || continue
    for f in "$dir"/*; do
      [[ -x "$f" && ! -e "$bin/${f##*/}" && "${f##*/}" != parallel ]] && ln -s "$f" "$bin/${f##*/}"
    done
  done
```

Precise version: "…except parallel and bats' libexec directory (as in_runner)". The gap is harmless to the test's purpose.

**Evidence:** `test/scripts/run-tests.bats:425-446`, `test/scripts/run-tests.bats:58-68`
**Legibility-target:** for-author

---

## Claim 18: Commit 088bc97, paragraph 1: "--jobs N (N > 1) hands bats `--jobs N --no-parallelize-within-files` ... When GNU parallel is not on PATH the runner warns and runs serially: bats aborts without it for any N > 1, even on one file, so the check is `command -v parallel`, not the file count. N must be a positive integer (else exit 2). --jobs combines with --failed and the category/FILE flags."

**Location:** commit 088bc97 message, lines 3-9
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same behaviour as Claims 1, 2 and 5, with the same residues: any `parallel` passes `command -v`, overflowing N wraps to serial, and `02` is rejected.

The flag hand-off is at `scripts/run-tests.sh:392`, the check is `command -v parallel > /dev/null` at `:391`, and the exit 2 is at `:127`. bats' abort for one file is shown in E1, and the combinations in tests 23, 24 and 26 (E4).

**Evidence:** `scripts/run-tests.sh:124-132`, `scripts/run-tests.sh:390-396`, docs/reviews/execution-logs/q090-fc-k1-E1-abort-without-parallel.log, docs/reviews/execution-logs/q090-fc-k1-E4-suite-unmutated.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: Commit 088bc97, "Tests (test/scripts/run-tests.bats): usage errors, parallel is really used with the within-file flag (a logging shim), --jobs 1 stays serial, a parallel run's log passes the completeness check and --failed re-runs from it, a killed parallel run is refused by --failed, no perl/citation text under an uninstalled locale, and the serial fallback with parallel removed from PATH."

**Location:** commit 088bc97 message, lines 11-15
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-to-one match between the 7 listed items and tests 20-26, all passing. It does not establish that the citation clause can fail on this host (Claim 16).

The diff adds seven `@test`s at `test/scripts/run-tests.bats:343`, `:355`, `:368`, `:376`, `:397`, `:413` and `:425`, in the listed order. E4 shows `ok 20` through `ok 26`.

**Evidence:** `test/scripts/run-tests.bats:343-446`, docs/reviews/execution-logs/q090-fc-k1-E4-suite-unmutated.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: Commit 088bc97, "The fallback and locale tests were mutation-checked (each fails with its guard removed)."

**Location:** commit 088bc97 message, lines 15-16
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers re-running both mutations. Removing the `command -v parallel` guard fails test 26. Removing the locale guard fails test 25: removing the whole `if` fails it at the "Locale … is not installed" assertion, and dropping only the export fails it at the perl grep. It does not establish that the citation clause of test 25 can fail (Claim 16).

E5 records the diffs and failures: `mut-fallback` fails at ``[ "$status" -eq 0 ]' failed`` (line 440), `mut-locale-whole` fails at line 417, and `mut-locale-noexport` fails at line 422 with `perl: warning:` lines.

**Evidence:** `scripts/run-tests.sh:157-162`, `scripts/run-tests.sh:390-396`, docs/reviews/execution-logs/q090-fc-k1-E5-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: Commit 088bc97 Notes, "chose --no-parallelize-within-files unconditionally (Q-086 C5: install.sh's procs_in_checkout scans the real /proc, and suites were written assuming serial tests)"

**Location:** commit 088bc97 message, Notes lines 1-3
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the flag is unconditional (`scripts/run-tests.sh:392`) and that Q-086 C5 says this: the rubric row reads "`install.sh` `procs_in_checkout` reads the real `/proc` and may make `install-host.bats` flake under concurrency. Start with `--no-parallelize-within-files`." It does not establish that within-file serialisation removes the /proc exposure. It does not (Claim 3): the exposure also comes from other files' concurrent processes.

`docs/reviews/q086-code-review-rubric-2026-09-28.md:44` holds the C5 row quoted above.

**Evidence:** `docs/reviews/q086-code-review-rubric-2026-09-28.md:44`, `docs/working/questions.md:186`, `scripts/run-tests.sh:392`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: Commit 088bc97 Notes, "parallel's citation notice needs a tty on stderr, which bats' `2>&1` into its formatter pipe never gives; checked under `script` as well."

**Location:** commit 088bc97 message, Notes lines 4-6
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tty condition in the function body, the non-tty stderr inside bats, and the `script` check. It does not establish upstream parallel's behaviour.

The mechanism and conclusion hold (Claim 9). The supporting check proves less than it implies. `/usr/bin/parallel:2578` is `#    citation_notice();`, so this Debian build never prints the notice, tty or not. E3 reproduces this: `parallel` under `script`, with stderr confirmed a tty (`STDERR_IS_TTY`), printed no notice. A run under `script` on this host therefore cannot tell the tty condition apart from the Debian patch. Precise version: "…needs a tty on stderr (Debian's build never prints it at all, so the `script` check cannot exercise it)".

**Evidence:** `/usr/bin/parallel:2578`, `/usr/bin/parallel:5632-5643`, docs/reviews/execution-logs/q090-fc-k1-E3-citation-tty.log
**Legibility-target:** for-author

---

## Claim 23: Commit 088bc97 Notes, "Usage errors for --jobs exit 2 like the --failed conflict, not 1 like an unknown flag."

**Location:** commit 088bc97 message, Notes lines 6-7
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three exit sites. It does not establish exit codes for other runner errors.

The three sites: `exit 2` at `scripts/run-tests.sh:127` (`--jobs`), `exit 2` at `:150` (`--failed` conflict), and `exit 1` at `:141` (`Unknown flag`). E6 shows exit 2 for each malformed `--jobs`.

**Evidence:** `scripts/run-tests.sh:124-151`, docs/reviews/execution-logs/q090-fc-k1-E6-jobs-usage.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 3** (`scripts/run-tests.sh:86-88`): install-host.bats' /proc scan is not state shared between one file's tests. Each test uses its own `$BATS_TEST_TMPDIR/repo`. The scan's exposure (`kind=unknown`, any concurrent same-uid process) comes from other files too, which `--jobs` still runs concurrently, so `--no-parallelize-within-files` does not protect it. Cite a `setup_file`/`BATS_FILE_TMPDIR` suite as the within-file example, and state install-host's cross-file exposure separately.

### Stale
- none

### Mostly Accurate
- **Claim 6** (`scripts/run-tests.sh:91-92`): grouping comes from parallel's default `--group`; `--keep-order` only orders. A file's results appear once it and every earlier file have ended, not just when it ends.
- **Claim 9** (`scripts/run-tests.sh:95-97`): true of upstream's function, but the installed Debian build (`/usr/bin/parallel:2578`) never calls `citation_notice`. Say so.
- **Claim 12** (`test/scripts/run-tests.bats:355`): the test checks the flag reaches `parallel`/`bats-exec-file`, not observed within-file serialism. Rename, or accept the proxy.
- **Claim 17** (`test/scripts/run-tests.bats:426`): the PATH also drops bats' libexec dir.
- **Claim 22** (commit 088bc97 Notes): "checked under `script`" cannot discriminate on this host, because the Debian build never prints the notice.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path named below, structured per the skill.
- Answered: yes. All 8 priority groups were verdicted, 20 of 23 by execution: bats abort, grouping and order, within-file serialism, citation under a tty, mutants, usage errors.
- Out of scope: running install-host.bats or the full suite under `--jobs`, which the brief forbids because of the run lock; upstream (non-Debian) parallel behaviour.
- Escalate: Claim 3. The header's install-host example misjustifies `--no-parallelize-within-files`, and install-host's /proc-scan exposure under `--jobs` is still untested, as Q-086 perf finding 2 recommended ("run test/install-host.bats repeatedly … alongside the rest of the suite before trusting the parallel gate").
- Decisions I made: saved execution logs as new files `docs/reviews/execution-logs/q090-fc-k1-*.log`. The skill requires captured-output files, and I read the brief's "edit no other file" as not covering new evidence files. Graded Claim 3 Incorrect rather than Mostly accurate because the stated mechanism (within-file shared state) is refuted, even though other suites do share per-file state.
