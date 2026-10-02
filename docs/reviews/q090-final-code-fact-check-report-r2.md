# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-run-tests-jobs (branch feat/run-tests-jobs)
**Commit:** b34a6fe
**Scope:** `git diff main...HEAD -- scripts test` (scripts/run-tests.sh, test/scripts/run-tests.bats) plus the commit messages of 088bc97, 084868f, f733a51. Final confirming pass (pass 2).
**Checked:** 2026-09-30
**Total claims checked:** 32
**Summary:** 21 verified, 7 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read: no logged pattern matches any claim here. None of the Incorrect verdicts is a fabricated symbol. Each misreads how GNU parallel loads its config, or how the kernel exposes an exiting process, so nothing new was logged. The brief also bars edits outside this report.

Execution logs (new, this pass): `docs/reviews/execution-logs/q090-fc-r2-E1..E7-*.log`. All ran with cwd `/workspace/.claude/wt-run-tests-jobs` and `LC_ALL=C.UTF-8`, against GNU parallel 20221122 (Debian) and bats 1.8.2. Every probe ran under `timeout`. The E4 churn loops were killed by PID, and no probe process was left running (checked with `ps` at the end).

| Log | What | Command (abridged; full command in log) | Exit | Time (UTC) |
|---|---|---|---|---|
| E1 | the suite | `timeout 300 bats test/scripts/run-tests.bats` | 0 (29/29 ok) | 21:49:10 |
| E2 | user config files vs `--jobs 2` | `e2.sh <scratch> {control,home-dot-parallel,parallelrc,xdg}` | runner 0 / 1 / 1 / 1 | 21:49:29 |
| E3 | `$PARALLEL`/config that break `--version`; uncreatable parallel-home | `e3.sh <scratch> {env-bogus,config-bogus,home-uncreatable}` | runner 0 each | 21:50 |
| E4 | install.sh `procs_in_checkout` under process churn | `e4-scan.sh 200` without and with 4× `e4-churn.sh` | 0 / 0 | 21:51 |
| E5 | `--jobs` value validation and clamp | scaffold runner with `--jobs {01,-1,+2,2x,1000,'',999,3,1}` | 2×6, 0×3 | 21:52:21 |
| E6 | mutants M1 to M5 against named tests | `bats -f <name> test/scripts/run-tests.bats` in mutated copies | see claims | 21:53:23 |
| E7 | `--failed --jobs 2` with failures in 2 files | `e7.sh <scratch>` | 1, 0, 0 | 21:53:57 |

---

## Claim 1: Flags entry: "--jobs N  Run up to N test files at once ... N is 1 to 999, digits only, no leading zero; anything else is a usage error (exit 2). 1, the default, runs serially; N above the number of selected files is lowered to it. Combines with every other flag, --failed included."

**Location:** `scripts/run-tests.sh:36-40`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex bound, exit 2, the default of 1, the clamp and `--failed`/category/FILE combination. It does not establish that the suite still tests `--failed` through a real parallel run: after the clamp, test 23's `--failed --jobs 2` keeps one file and runs serially (see Claim 19).

```bash
# scripts/run-tests.sh:138-144 (excerpt; enclosing case arm ends :145 — read)
      if [[ ! "${2:-}" =~ ^[1-9][0-9]{0,2}$ ]]; then
        echo "--jobs takes a number from 1 to 999, got: ${2:-(nothing)}" >&2
        usage
        exit 2
      fi
      jobs="$2"
```
```bash
# scripts/run-tests.sh:404
(( jobs > ${#files[@]} )) && jobs=${#files[@]}
```
E5 results: `01`, `-1`, `+2`, `2x`, `1000` and `''` each exit 2. `999`, `3` and `1` exit 0. `--jobs 999 --all` over 2 files hands parallel `--jobs 2`. `--jobs 3 --slow FILE FILE` runs the one slow file. `jobs=1` is the initial value (`scripts/run-tests.sh:126`). E7 shows `--failed --jobs 2` with failures in two files going through parallel (`shim: --keep-order --jobs 2 bats-exec-file ...`) and re-running only `a flaky` and `b flaky`.

**Evidence:** `scripts/run-tests.sh:36-40`, `:126`, `:135-145`, `:404`; `docs/reviews/execution-logs/q090-fc-r2-E5-jobs-values.log`; `docs/reviews/execution-logs/q090-fc-r2-E7-failed-parallel.log`

---

## Claim 2: "--jobs N (N > 1) hands bats `--jobs N --no-parallelize-within-files`, so whole files run side by side and the tests within a file stay serial"

**Location:** `scripts/run-tests.sh:85-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the flags reaching bats and bats' within-file branch. It does not re-observe within-file serial timing; pass 1 already accepted that proxy (override row 172).

```bash
# scripts/run-tests.sh:411
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
```
```bash
# /usr/libexec/bats-core/bats-exec-file:294
  if [[ "$num_jobs" != 1 && "${BATS_NO_PARALLELIZE_WITHIN_FILE-False}" == False ]]; then
```
The E7 shim log shows parallel called with `--jobs 2 bats-exec-file --dummy-flag -j 2 --no-parallelize-within-files`, and E1's test 21 passes.

**Evidence:** `scripts/run-tests.sh:405-415`; `libexec/bats-core/bats-exec-file:24-26,294`; `libexec/bats-core/bats-exec-suite:420`; E1, E7 logs

---

## Claim 3: "a file's tests may share state (health-check.bats caches one health-check run in $BATS_FILE_TMPDIR in setup_file for all its tests)"

**Location:** `scripts/run-tests.sh:87-89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the cache's location, where it is written and who shares it. It does not establish that within-file parallelism would break health-check.bats: the cache is written once in `setup_file` and only read afterwards. The example shows shared state, not a race.

```bash
# test/scripts/health-check.bats:25,34-36
_HC_CACHE_DIR="$BATS_FILE_TMPDIR/hc-cache"
setup_file() {
  _run_and_cache
}
```
`setup()` reads `$_HC_CACHE_DIR/output` and `status` (`test/scripts/health-check.bats:42-51`). bats creates one `BATS_FILE_TMPDIR` per file (`bats-exec-file:322-328`).

**Evidence:** `test/scripts/health-check.bats:21-51`; `libexec/bats-core/bats-exec-file:322-328`

---

## Claim 4a: "The slowest file bounds the speedup"

**Location:** `scripts/run-tests.sh:89-90`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lower bound that follows from a whole file being the unit of scheduling. It does not measure how close runs come to that bound.

With `--no-parallelize-within-files`, each file is one `bats-exec-file` job (`bats-exec-suite:420`: `parallel --keep-order --jobs "$num_jobs" bats-exec-file ... ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}"`), so wall time cannot fall below the longest single file.

**Evidence:** `libexec/bats-core/bats-exec-suite:415-420`

---

## Claim 4b: "and N above the core count buys nothing"

**Location:** `scripts/run-tests.sh:90`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing measured. The brief bars full-suite runs; the only data is the author's timings (144 s at 8 and 137 s at 16 on 16 cores), and nothing above 16 was measured.

Paraphrased — no quote available because the claim concerns suite-wide timing, not a code path. Several suites wait on sleeps and ptys rather than CPU, so N above the core count could still overlap waiting. The claim needs one timed run at `--jobs 24` or `--jobs 32` to settle it.

**Evidence:** `scripts/run-tests.sh:90`; shared brief (measurements)

---

## Claim 5a: "install.sh's procs_in_checkout, which install-host.bats runs, refuses when it cannot read the working directory of any process of the user"

**Location:** `scripts/run-tests.sh:90-93`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers who lists and who refuses, plus the exemptions. It does not establish how often install-host tests actually hit an unreadable cwd.

`procs_in_checkout` does not refuse. It prints `unknown <PID> <cmd>` lines, and `agent_gate` refuses on them. Two kinds of process are also exempt: install.sh's own lineage, and any process with an empty command line.

```bash
# devcontainer-config/install.sh:1170-1180 (excerpt; procs_in_checkout ends :1182 — read)
    if cwd="$(readlink "$d/cwd" 2>/dev/null)"; then
      case "$cwd" in "$root"|"$root"/*) kind=in ;; *) continue ;; esac
    else
      kind=unknown
    fi
    pid="${d#/proc/}"
    in_lineage "$pid" && continue
    cmd="$(tr '\0' ' ' 2>/dev/null < "$d/cmdline")"
    [ -n "$cmd" ] || continue                   # exited, or a kernel thread
```
The refusal is `agent_gate`'s `if [ -z "$procs" ] && [ -z "$inrepo" ] && [ -z "$unknown" ] && [ -z "$ctrs" ]; then return 0; fi` followed by `exit 1` (`devcontainer-config/install.sh:1248-1281`). Precise version: "install.sh's no-agent gate, which install-host.bats runs, refuses when it cannot read the working directory of another live process of the user (outside its own lineage)."

**Evidence:** `devcontainer-config/install.sh:1150-1182`, `:1197-1281`

---

## Claim 5b: "so other files' processes starting and ending beside it can make it refuse where a serial run would not"

**Location:** `scripts/run-tests.sh:93-94`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the stated mechanism: processes that are short-lived, merely starting or ending. It does not establish that no other suite can ever spawn a same-uid non-dumpable process. That is the real exposure, and a grep of `test/` finds such spawns (`prctl`, ssh-agent) only in install-host.bats itself.

An exiting process does not produce an `unknown` line. The scan skips any process whose command line is empty (`[ -n "$cmd" ] || continue`, `install.sh:1179`). The kernel clears a process's mm, and with it its cmdline, before its fs, and with it its cwd, in `do_exit`. So a process whose cwd is unreadable because it is ending also has an empty cmdline, and is skipped. (Paraphrased — no quote available because the ordering is in the Linux kernel's `do_exit` (exit_mm before exit_fs), not in this repo.) A newly started same-uid process inherits a dumpable mm, and its cwd is readable.

Executed (E4): install.sh's own `ppid_of`/`in_lineage`/`procs_in_checkout` (lines 1128-1182), extracted verbatim, scanned 200 times with no churn and 200 times beside 4 loops that continuously fork and exec short-lived processes. Both runs produced 0 `unknown` lines (`scans-done: 200` ×2, no `scan<N>:` lines). A same-uid process refuses the gate only while it is alive with an unreadable cwd, which means non-dumpable (install-host.bats T92 builds one with `prctl(PR_SET_DUMPABLE, 0)`). Precise version: "... refuses when a live same-uid process's working directory is unreadable (a non-dumpable process), so such a process in another file running beside it would make it refuse where a serial run would not."

**Evidence:** `devcontainer-config/install.sh:1165-1182`; `test/install-host.bats:1594-1611`; `docs/reviews/execution-logs/q090-fc-r2-E4-proc-scan-churn.log`

---

## Claim 6: "bats runs files through GNU parallel and aborts without it even for one file, so when the first `parallel` on PATH is missing or is not GNU parallel (moreutils ships one too), the runner warns and runs serially"

**Location:** `scripts/run-tests.sh:95-97`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers bats' abort condition, the two conditions stated and the moreutils fact. It does not cover the unstated third trigger: GNU parallel is first on PATH, but `parallel --version` fails under the user's `$PARALLEL` or config. The runner then also falls back, and its warning misnames the cause (Claim 13).

```bash
# libexec/bats-core/bats-exec-suite:99-102 (excerpt; enclosing if ends :106 — read)
if [[ "$num_jobs" != 1 ]]; then
  if ! type -p parallel >/dev/null && [[ -z "$bats_no_parallelize_across_files" ]]; then
    abort "Cannot execute \"${num_jobs}\" jobs without GNU parallel"
    exit 1
```
The check does not depend on how many files there are. Tests 28 and 29 pass (E1), and mutant M3 (check weakened to "any output") fails test 28 (E6). The moreutils fact holds on this host: `dpkg -S /usr/bin/parallel` reports `diversion by parallel to: /usr/bin/parallel.moreutils`.

**Evidence:** `libexec/bats-core/bats-exec-suite:99-106`; `scripts/run-tests.sh:405-415`; E1, E6 logs

---

## Claim 7a: "It unsets $PARALLEL and points $PARALLEL_HOME at .bats/parallel-home (left at the user's default when that cannot be created)"

**Location:** `scripts/run-tests.sh:97-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the environment bats' parallel receives. It does not establish what that environment achieves (Claim 7b).

```bash
# scripts/run-tests.sh:407-410
    unset PARALLEL
    if mkdir -p "$REPO_ROOT/.bats/parallel-home" 2>/dev/null; then
      export PARALLEL_HOME="$REPO_ROOT/.bats/parallel-home"
    fi
```
E3 `home-uncreatable`: with `.bats/parallel-home` created in advance as a regular file and the user's `PARALLEL_HOME=<home>/users-own`, bats' parallel call receives `PARALLEL_HOME=[<home>/users-own]` and the run passes.

**Evidence:** `scripts/run-tests.sh:405-415`; `docs/reviews/execution-logs/q090-fc-r2-E3-parallel-env-edge.log`

---

## Claim 7b: "so the user's parallel options and config cannot change how bats' run behaves"

**Location:** `scripts/run-tests.sh:99-100`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the user's config files and `$PARALLEL` on the Debian 20221122 build. It does not cover `$PARALLEL_CSH` or `--profile` files, which the same code reads but which were not probed.

Setting `$PARALLEL_HOME` adds a config dir. It does not replace the others. GNU parallel keeps every config dir that exists, and it reads `/etc/parallel/config`, `<each dir>/config` and `~/.parallelrc`:

```perl
# /usr/bin/parallel:2841-2847
    @Global::config_dirs =
	(grep { -d $_ }
	 $ENV{'PARALLEL_HOME'},
	 (map { "$_/parallel" }
	  $xdg_config_home,
	  split /:/, $ENV{'XDG_CONFIG_DIRS'}),
	 $ENV{'HOME'} . "/.parallel");
```
```perl
# /usr/bin/parallel:3321-3324 (excerpt; enclosing `if(not $opt::plain)` ends :3370 — read)
	my @config_profiles = (
	    "/etc/parallel/config",
	    (map { "$_/config" } @Global::config_dirs),
	    $ENV{'HOME'}."/.parallelrc");
```
E2, run through the real runner copy with `--jobs 2` over two files: a `--dry-run` line in `~/.parallel/config`, in `~/.parallelrc` or in `$XDG_CONFIG_HOME/parallel/config` makes parallel print the `bats-exec-file ...` command lines instead of running them. No test runs, and the runner exits 1. The control run passes.

The runner also checks for GNU parallel (`parallel --version`, `:406`) before `unset PARALLEL` (`:407`). E3: `PARALLEL=--no-such-option`, or the same option in `~/.parallel/config`, makes `--version` fail, and the runner prints its "not GNU parallel" warning and runs serially. So `$PARALLEL` still changes the run too.

**Evidence:** `scripts/run-tests.sh:405-415`; `/usr/bin/parallel:2828-2860`, `:3314-3375`; `docs/reviews/execution-logs/q090-fc-r2-E2-parallel-config.log`; `docs/reviews/execution-logs/q090-fc-r2-E3-parallel-env-edge.log`

---

## Claim 8: "bats keeps each file's output together (parallel groups output by default) and in file order (--keep-order), so a file's results appear once it and every file before it have ended"

**Location:** `scripts/run-tests.sh:101-103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers parallel's defaults under the runner's environment. It does not hold when a user config file sets `--ungroup` or `--line-buffer`, since those files still reach parallel (Claim 7b).

`bats-exec-suite:420` passes `--keep-order` and no grouping flag. `/usr/bin/parallel:3713` groups unless `$opt::ungroup` is set (`if(not $opt::ungroup) {`). Pass 1 observed the same ordering in `q090-fc-k1-E2-grouping-order-within-file.log`.

**Evidence:** `libexec/bats-core/bats-exec-suite:420`; `/usr/bin/parallel:2654-2665`, `:3707-3715`

---

## Claim 9: "Every test still writes its own run-log line, so the run log, the test-count check and --failed work as in a serial run."

**Location:** `scripts/run-tests.sh:103-105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers parallel runs over fixture suites (the E1 tests at HEAD, and E7 for `--failed` re-run through parallel). It does not cover the real suite, which the brief bars.

E7: the `--jobs 2` run over 3 files records 5 results, the `--failed --jobs 2` re-run goes through parallel and runs the 2 failures, and a later `--failed` reports "nothing to re-run". E1: tests 23 and 24 pass (complete log; killed run refused).

**Evidence:** `scripts/run-tests.sh:417-432`; E1, E7 logs

---

## Claim 10: "bats folds parallel's stderr into its output; the locale pin above keeps perl's setlocale warnings out of it, and upstream parallel prints its citation notice only when its stderr is a terminal, which inside bats it never is (Debian's build never prints it)."

**Location:** `scripts/run-tests.sh:105-108`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `2>&1`, the pinned-locale case (test 25 at HEAD) and the Debian citation call. It does not cover the LC_CTYPE residue pass 1 logged (`q090-fc-k1-E7-lcctype-residue.log`, pre-existing), and test 25 no longer proves the parallel path by itself (Claim 21).

`bats-exec-suite:420` ends `... ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1`. `/usr/bin/parallel:2578` is `#    citation_notice();` (commented out). The upstream function skips when `not -t $Global::original_stderr` (`/usr/bin/parallel:5637-5643`). E1 test 25 passes at HEAD.

**Evidence:** `libexec/bats-core/bats-exec-suite:420`; `/usr/bin/parallel:2570-2582`, `:5632-5643`; E1 log

---

## Claim 11: "At most 3 digits, so the value never overflows bash arithmetic and parallel never sizes thousands of job slots."

**Location:** `scripts/run-tests.sh:136-137`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex bound (≤999) and the clamp. It does not re-measure parallel's per-slot cost, which pass 1 did (`q090-fc-k1-E6-jobs-usage.log`).

The regex is `^[1-9][0-9]{0,2}$` (`:138`), E5 shows `1000` rejected, and `:404` further lowers N to the file count (124 `.bats` files in `test/`).

**Evidence:** `scripts/run-tests.sh:136-145`, `:404`; E5 log

---

## Claim 12: "Test for GNU parallel itself, not the file count: bats aborts without it whenever N > 1. bats runs the first `parallel` on PATH, so that is the one checked."

**Location:** `scripts/run-tests.sh:401-403`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers PATH resolution in bats 1.8.2 and the runner. It does not cover an operator who invokes bats with a different PATH, and the check can fail for reasons other than "not GNU" (Claim 13).

bats prepends its libexec dir to PATH (`libexec/bats-core/bats:101`: `export PATH="$BATS_LIBEXEC:$PATH"`). That dir holds no `parallel` (it lists only bats, bats-exec-*, bats-format-* and bats-preprocess), and `bats-exec-suite:420` calls bare `parallel`. In E3 and E5, one PATH shim first on PATH receives both the runner's `--version` and bats' `--keep-order --jobs 2 ...` calls.

**Evidence:** `libexec/bats-core/bats:101`; `libexec/bats-core/bats-exec-suite:420`; `scripts/run-tests.sh:401-406`; E3, E5 logs

---

## Claim 13: warning text "--jobs $jobs needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially"

**Location:** `scripts/run-tests.sh:413`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the causes that reach the else branch. It does not establish whether falling back serially is the right response to a bad user option.

The branch also fires when GNU parallel is first on PATH but `parallel --version` exits non-zero because `$PARALLEL` or a config file holds an option parallel rejects. E3 `env-bogus` and `config-bogus` print this exact warning with `/usr/bin/parallel` (GNU) first on PATH. Precise version: "... or `parallel --version` did not report GNU parallel". Alternatively, unset `$PARALLEL` before the check.

**Evidence:** `scripts/run-tests.sh:405-415`; E3 log

---

## Claim 14: test-file header "filtering, --failed and --jobs. Runs a copy of the script in a throwaway repo layout ... The real suite never runs."

**Location:** `test/scripts/run-tests.bats:2-6`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the setup copy and the fixture suites. It does not cover the tests' own discriminating power (Claims 19-21).

`setup()` copies `scripts/run-tests.sh` into `T="$BATS_TEST_TMPDIR/my repo"` and writes the alpha, gamma and beta fixtures (`test/scripts/run-tests.bats:16-33`). Every `--jobs` test calls `runner`/`in_runner`/`runner_bg` on `$T/scripts/run-tests.sh`.

**Evidence:** `test/scripts/run-tests.bats:16-33`, `:58-89`

---

## Claim 15: "parallel_shim: put a `parallel` first on PATH that logs its arguments to $T/parallel.args and execs the real one, so a test can see bats used it."

**Location:** `test/scripts/run-tests.bats:329-330`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what the shim records. It does not establish which tests rely only on the file's existence (Claims 19-21).

Since 084868f, the runner's own `parallel --version` check also goes through the shim, so `$T/parallel.args` exists whether or not bats used parallel. E5's shim log opens with `shim: --version`, before bats' `--keep-order --jobs 2 ...` line. Precise version: "... a test can see bats used it by grepping for bats' arguments (`--jobs N`), not by the file existing".

**Evidence:** `test/scripts/run-tests.bats:329-340`; `scripts/run-tests.sh:406`; E5 log

---

## Claim 16: test name "--jobs: a missing, zero, non-numeric or 4-digit N is a usage error"

**Location:** `test/scripts/run-tests.bats:342`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four cases the test asserts (status 2 and the message). It does not cover leading-zero, sign or trailing-junk input, which E5 checked separately (all exit 2).

The test asserts `[ "$status" -eq 2 ]` for `--jobs`, `0`, `x` and `1000` (`:343-354`), and it passes in E1.

**Evidence:** `test/scripts/run-tests.bats:342-355`; E1, E5 logs

---

## Claim 17: test name "--jobs 2 runs files through parallel, not tests within a file"

**Location:** `test/scripts/run-tests.bats:358`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the argument-grep proxy. Settled: override-log row 172 (Acknowledged), with no new evidence this pass.

The test greps `--jobs 2` and `--no-parallelize-within-files` in `parallel.args` (`:367-368`). It does not observe serial execution within a file.

**Evidence:** `test/scripts/run-tests.bats:358-369`; `docs/reviews/override-log.md:172`

---

## Claim 18: test name "--jobs 1 runs serially and needs no parallel"

**Location:** `test/scripts/run-tests.bats:371`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the absence of any `parallel` call when N=1. It does not cover N>1 clamped to 1, a different path to the same outcome that E5's `--jobs 999 --fast` exercised.

The test asserts `[ ! -f "$T/parallel.args" ]` (`:376`), so neither the `--version` check nor bats called parallel, and it passes in E1.

**Evidence:** `test/scripts/run-tests.bats:371-377`; E1 log

---

## Claim 19: test name "--jobs: a parallel run records a complete log that --failed re-runs from"

**Location:** `test/scripts/run-tests.bats:379`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what the test asserts and whether it discriminates a parallel run. It does not bear on whether the code works (Claim 9, E7: it does).

The test never checks that either run was parallel. Mutant M5 (E6), in which the GNU check is kept but bats is never given `--jobs`, so every run is serial, still passes this test. Its `--failed --jobs 2` re-run keeps only `alpha.bats`, so the clamp lowers N to 1 and the re-run is serial even at HEAD. Since 084868f, no test runs `--failed` through bats' parallel. To make the name true: add `grep -q -- '--jobs 2' "$T/parallel.args"` after the first run, and give the re-run failures in two files (E7 shows that case works).

**Evidence:** `test/scripts/run-tests.bats:379-398`; `scripts/run-tests.sh:404`; `docs/reviews/execution-logs/q090-fc-r2-E6-mutants.log` (M5); E7 log

---

## Claim 20: test name "--jobs: a parallel run killed partway is refused by --failed"

**Location:** `test/scripts/run-tests.bats:400`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the test's power to tell a parallel run from a serial one. It does not question the refusal it asserts, which holds.

The test asserts rc 143 and the "did not complete" refusal (`:407-414`), but nothing about parallel. Mutant M5 passes it (E6, `ok 1 --jobs: a parallel run killed partway is refused by --failed`).

**Evidence:** `test/scripts/run-tests.bats:400-414`; E6 log (M5)

---

## Claim 21: test name "--jobs: an uninstalled locale leaves no perl or citation text in the output" and its comment "gamma asserts its own subprocess output is clean; the suite-level output must be clean too."

**Location:** `test/scripts/run-tests.bats:416-424`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether the test exercises bats' parallel stderr, the only source of perl/citation text. It does not dispute that the output is clean at HEAD (E1).

The test's only evidence that parallel ran is `[ -f "$T/parallel.args" ]` (`:420`), and the runner's `--version` call now creates that file (Claim 15). Mutant M5, in which bats never runs parallel, passes the test (E6). In that case no parallel stderr reaches the output, so the test cannot fail on perl text. It discriminated at 088bc97, where only bats called the shim. Mutant M4 fails it only because M4 also removes the `--version` call. Fix: grep `--jobs 2` as test 21 does.

**Evidence:** `test/scripts/run-tests.bats:416-426`; `scripts/run-tests.sh:406`; E6 log (M4, M5)

---

## Claim 22: test name "--jobs above the file count is lowered to it"

**Location:** `test/scripts/run-tests.bats:428`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the 999→2 case. It does not cover a clamp to 1, which E5 covered.

The test greps `--jobs 2 ` (`:432`). Mutant M1 (clamp line deleted) fails at that line (E6).

**Evidence:** `test/scripts/run-tests.bats:428-433`; E6 log (M1)

---

## Claim 23: test name "--jobs: the user's PARALLEL options do not reach bats' parallel" and its comment "--dry-run would run no test at all."

**Location:** `test/scripts/run-tests.bats:435-437`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `$PARALLEL` environment variable with `--dry-run`. It does not cover config files, which do reach bats' parallel (Claim 7b, E2), or `$PARALLEL` values that break the runner's `--version` check (Claim 13, E3).

Mutant M2 (`unset PARALLEL` disabled) fails at `[[ "$output" == *"ok"*"beta steady"* ]]` (E6). That confirms the comment: with `--dry-run`, no test runs.

**Evidence:** `test/scripts/run-tests.bats:435-443`; E6 log (M2); E2 log

---

## Claim 24: test name "--jobs with a non-GNU parallel first on PATH warns and runs serially"

**Location:** `test/scripts/run-tests.bats:445`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a fake whose `--version` output does not start with "GNU parallel". It does not cover a real moreutils binary, which is not installed here.

The fake prints `parallel from moreutils` and exits 1 (`:447`), and the test asserts the warning and `ok 2 beta steady`. Mutant M3 fails it (E6).

**Evidence:** `test/scripts/run-tests.bats:445-455`; E6 log (M3)

---

## Claim 25: "A PATH holding everything the current one does except parallel (and bats' libexec directory, which in_runner drops too)."

**Location:** `test/scripts/run-tests.bats:458-459`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the executables linked. Non-executable PATH entries are skipped (`-x`), which the comment does not mention but which does not matter for command lookup.

```bash
# test/scripts/run-tests.bats:464-468 (excerpt; enclosing test ends :479 — read)
  for dir in $PATH; do
    [[ -d "$dir" && "$dir" != "$BATS_LIBEXEC" ]] || continue
    for f in "$dir"/*; do
      [[ -x "$f" && ! -e "$bin/${f##*/}" && "${f##*/}" != parallel ]] && ln -s "$f" "$bin/${f##*/}"
```
`in_runner` removes `$BATS_LIBEXEC` from PATH (`:61-64`). The `command -v parallel ||` guard (`:471`) makes the test fail, rather than pass vacuously, if parallel stays reachable.

**Evidence:** `test/scripts/run-tests.bats:57-68`, `:457-479`

---

## Claim 26: commit 088bc97 body: "--jobs N (N > 1) hands bats `--jobs N --no-parallelize-within-files` ... the check is `command -v parallel`, not the file count. N must be a positive integer (else exit 2). --jobs combines with --failed and the category/FILE flags. ... The fallback and locale tests were mutation-checked"

**Location:** commit 088bc97
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the claims as of 088bc97 (later changes supersede the `command -v` check and the unbounded N). The Notes' `script` claim is settled (override row 173, Accepted-immutable), so it is not re-verdicted.

At 088bc97, `git show 088bc97:scripts/run-tests.sh` shows `if [[ ! "${2:-}" =~ ^[1-9][0-9]*$ ]]` (`:125`) and `if command -v parallel > /dev/null; then` (`:391`). Pass 1 ran the mutation check (`q090-fc-k1-E5-mutants.log`).

**Evidence:** `git show 088bc97:scripts/run-tests.sh` lines 124-127, 388-396; `docs/reviews/execution-logs/q090-fc-k1-E5-mutants.log`

---

## Claim 27: commit 084868f: "$PARALLEL is unset and $PARALLEL_HOME points at .bats/parallel-home, so the user's parallel options or config cannot alter bats' run (security F2)."

**Location:** commit 084868f
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Same evidence and limits as Claim 7b. Branch history is immutable, so the correction belongs in the header comment and the fix commit.

Config files (`~/.parallel/config`, `~/.parallelrc`, `$XDG_CONFIG_HOME/parallel/config`, `/etc/parallel/config`) still reach parallel. A `--dry-run` line in any of them stops every test (E2). A rejected option in `$PARALLEL` or in config forces the serial fallback (E3). Security F2 is therefore only partly addressed: its fail-closed note still holds (the dry-run case exits 1), but the config route to parallel stays open.

**Evidence:** `/usr/bin/parallel:2841-2847`, `:3321-3364`; E2, E3 logs

---

## Claim 28: commit 084868f, remaining bullets: "--jobs takes 1 to 999 (was any digit string ...), and N above the selected file count is lowered to it"; "The fallback now checks that the first `parallel` on PATH is GNU parallel (`parallel --version`)"; test list; "The clamp and PARALLEL tests were mutation-checked"; "8 override-log rows"; Notes "PARALLEL_HOME under .bats/ (gitignored) ... when .bats/ is unwritable it is left at the user's default ... (16 cores, 124 files)"

**Location:** commit 084868f
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed fact. It does not re-run pass 1's N=20000 orphan reproduction (`q090-fc-k1-E6-jobs-usage.log`). "the fallback test's comment now says it drops bats' libexec too" is covered by Claim 25.

The earlier regex is `^[1-9][0-9]*$` at 088bc97. Mutants M1 (clamp) and M2 (unset) each fail their test (E6). `docs/reviews/override-log.md:166-173` holds 8 rows dated 2026-09-30 for `feat/run-tests-jobs`. `.gitignore:43` is `.bats/`. `nproc` prints 16, and `test/` holds 124 `.bats` files (at 084868f too). E3 covers the unwritable case.

**Evidence:** `scripts/run-tests.sh:136-145`, `:401-415`; `.gitignore:43`; `docs/reviews/override-log.md:166-173`; E3, E6 logs

---

## Claim 29: commit f733a51: "the header said the runner always points $PARALLEL_HOME at .bats/parallel-home; it does only when that directory can be created."

**Location:** commit f733a51
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the conditional export. The "Notes: comment-only" line holds: `git show f733a51 --stat` touches only scripts/run-tests.sh comment lines.

The `mkdir -p ... && export` sits at `scripts/run-tests.sh:408-410`, and E3 `home-uncreatable` leaves the user's value in place.

**Evidence:** `scripts/run-tests.sh:408-410`; E3 log

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`scripts/run-tests.sh:93-94`): starting or ending processes do not make the /proc scan refuse. It skips processes with an empty cmdline, and 400 scans under churn produced 0 `unknown` lines. The real cross-file exposure is a live, non-dumpable same-uid process. Reword the sentence to name that.
- **Claim 7b** (`scripts/run-tests.sh:99-100`): `$PARALLEL_HOME` does not stop parallel reading `~/.parallel/config`, `~/.parallelrc`, `$XDG_CONFIG_HOME/parallel/config` or `/etc/parallel/config` (a `--dry-run` there runs no test). `$PARALLEL` is also read by the `--version` check before `unset`. Either scope the sentence to `$PARALLEL`, or pass `--plain` or point `HOME`/`XDG_*` at the private dir as well, and move `unset PARALLEL` before the check.
- **Claim 27** (commit 084868f): the same "options or config cannot alter bats' run" claim. Correct it in the next commit or the merge notes.

### Stale
- none

### Mostly Accurate
- **Claim 5a** (`scripts/run-tests.sh:90-93`): `procs_in_checkout` lists; `agent_gate` refuses. Lineage and exited processes are exempt.
- **Claim 13** (`scripts/run-tests.sh:413`): the warning also fires when GNU parallel's `--version` fails under the user's `$PARALLEL` or config, and then misnames the cause.
- **Claim 15** (`test/scripts/run-tests.bats:329-330`): the shim also logs the runner's `--version` call, so the file's existence does not show bats used parallel.
- **Claim 17** (`test/scripts/run-tests.bats:358`): settled (override row 172).
- **Claim 19** (`test/scripts/run-tests.bats:379`): passes with bats never parallel (M5). Its `--failed --jobs 2` re-run is clamped to serial, so no test now runs `--failed` through parallel.
- **Claim 20** (`test/scripts/run-tests.bats:400`): passes with bats never parallel (M5).
- **Claim 21** (`test/scripts/run-tests.bats:416-424`): `[ -f parallel.args ]` is satisfied by the `--version` call, so the test passes with bats never parallel (M5). It lost its power to catch this regression in 084868f.

### Unverifiable
- **Claim 4b** (`scripts/run-tests.sh:90`): "N above the core count buys nothing" needs one timed run at N > 16.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path named below, structured per the skill.
- Answered: yes. All 5 priority groups were verdicted, 23 of 32 claims by execution (suite, config and env probes, /proc churn, value checks, 5 mutants, `--failed` through parallel).
- Out of scope: the full suite and install-host.bats under `--jobs` (brief), non-Debian parallel, `$PARALLEL_CSH`/`--profile`.
- Escalate: Claims 7b and 27 are a new-evidence reopening of security F2 / rubric C2, which were marked fixed: config files still reach bats' parallel. Claims 19-21: since 084868f, three `--jobs` tests pass with parallel never used (M5). Claim 5b: the A1 rewrite states a mechanism that does not occur.
- Decisions I made: saved execution logs as new `docs/reviews/execution-logs/q090-fc-r2-*.log` files, following pass 1's precedent, and read "edit no other file" as not covering new evidence files. Did not touch hallucination-patterns.md (no fabrication; brief bars edits). Graded 5b Incorrect at Medium confidence: the mechanism was tested and refuted, although a possibility claim cannot be disproved exhaustively.
