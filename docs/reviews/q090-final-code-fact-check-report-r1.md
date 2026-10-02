Commit: b34a6fe

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-run-tests-jobs (branch feat/run-tests-jobs)
**Scope:** `git diff main...HEAD -- scripts test` (scripts/run-tests.sh, test/scripts/run-tests.bats) plus the commit messages of 088bc97, 084868f, f733a51. Final confirming pass (pass 2). HEAD b34a6fe = f733a51 + the pass-1 rubric.
**Checked:** 2026-09-30
**Total claims checked:** 34
**Summary:** 24 verified, 5 mostly accurate, 1 stale, 3 incorrect, 1 unverifiable

Execution logs for this pass are in the session scratchpad (the brief says to edit no file but this report): `/tmp/claude-1000/-workspace/21797f19-046e-4351-9c55-0471f4b3d3b6/scratchpad/run-tests-jobs/fc-final/` (called `$FC` below). All probes ran with `LC_ALL=C.UTF-8` under `timeout`. No process was left running; a final `ps` check found none.

| Log | What ran (cwd `$FC` unless stated) | Exit |
|---|---|---|
| `$FC/E1-parallel-config-sources.log` | `/usr/bin/parallel echo real-{} ::: a` with `--dry-run` in `~/.parallel/config`, `~/.parallelrc`, `$XDG_CONFIG_HOME/parallel/config` or `$PARALLEL_CSH`, while `PARALLEL_HOME` points at another existing directory; plus `PARALLEL=--bogus-opt parallel --version`. 2026-09-30T21:49:18Z | 0 (per case, in the log) |
| `$FC/E2-procscan-churn.log`, `$FC/E2b-procscan-churn-xargs.log` | `timeout 60 bash scan-probe.sh $FC/repo`: install.sh's `procs_in_checkout` (extracted verbatim) run in a loop for 15 s while a background loop forks and ends processes. 21:50:28Z and 21:51:36Z | 0 |
| `$FC/E3-nondumpable.log` | a `prctl(PR_SET_DUMPABLE, 0)` python process: `[ -O /proc/PID ]` and `readlink /proc/PID/cwd`. 21:51:18Z | 0 |
| `$FC/E4-runner-probes.log`, `$FC/E4b-runner-probes-output.log` | `PROBE_ROOT=/workspace/.claude/wt-run-tests-jobs timeout 300 bats probe.bats` (`$FC/probe.bats`: run-tests.bats' own helpers `:8-118` and `parallel_shim`, plus probes P1 to P6 against the branch's runner). 21:52:24Z and 21:52:43Z | 0 |
| `$FC/E5-mutants-and-suite.log` | three mutant copies of the runner (`$FC/m-nojobsarg`, `m-nounset`, `m-noclamp`; diffs are at the top of the log) run with `bats --filter '^--jobs'` on their copy of run-tests.bats, then the unmutated `bats /workspace/.claude/wt-run-tests-jobs/test/scripts/run-tests.bats` (29 of 29 ok). 21:53:04Z | The log's `exit=` lines are empty (a PIPESTATUS capture slip); read the result from the ok/not ok lines |

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`): read. No claim here matches a logged pattern.

---

## Claim 1: "N is 1 to 999, digits only, no leading zero; anything else is a usage error (exit 2)."

**Location:** `scripts/run-tests.sh:36-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the value after `--jobs`: missing, 0, 1000, `x`, `01`, `007`, `-1`, `+2`, `"2 "`, `2x` and `""` all exit 2, and 10 and 999 are accepted. It does not establish the `--jobs=2` and `-j 2` spellings: they take the unknown-flag path (exit 1), which is settled in override-log row 169.

```bash
# scripts/run-tests.sh:138-142 (excerpt of the --jobs case arm, :135-145 — read)
      if [[ ! "${2:-}" =~ ^[1-9][0-9]{0,2}$ ]]; then
        echo "--jobs takes a number from 1 to 999, got: ${2:-(nothing)}" >&2
        usage
        exit 2
      fi
```

Probe P1 (E4) passed: every bad value gave status 2, and `--jobs 999` and `--jobs 10` ran. Test 20 (E5) passed.

**Evidence:** `scripts/run-tests.sh:135-145`, `$FC/E4-runner-probes.log` (P1), `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "1, the default, runs serially; N above the number of selected files is lowered to it. Combines with every other flag, --failed included."

**Location:** `scripts/run-tests.sh:38-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default `jobs=1`, the clamp to `${#files[@]}` (the files left after category, report gating and --failed filtering, not counting the run-log anchor), and `--jobs` combined with `--fast`, `--slow` + FILE, and `--failed`. It does not establish `-h`, which exits before `--jobs` has any effect.

```bash
# scripts/run-tests.sh:126
jobs=1
# scripts/run-tests.sh:404
(( jobs > ${#files[@]} )) && jobs=${#files[@]}
```

`files` is filled at `:398` (`mapfile -t files <<< "$matched"`), and the anchor is appended to `bats_args` afterwards (`:418`), so the anchor is not counted. P2 (E4) passed: `--fast --jobs 2` ran alpha and gamma through parallel, and `--slow --jobs 2 test/sub/beta.bats test/gamma.bats` ran beta alone and never called parallel. Test 23 (`--failed --jobs 2`) and test 26 (the clamp) passed. The noclamp mutant fails test 26 (E5).

**Evidence:** `scripts/run-tests.sh:126`, `:398-418`, `$FC/E4-runner-probes.log` (P2), `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "--jobs N (N > 1) hands bats `--jobs N --no-parallelize-within-files`, so whole files run side by side and the tests within a file stay serial"

**Location:** `scripts/run-tests.sh:85-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the flags that reach bats and how bats 1.8.2 acts on them. It does not establish that the flags are passed when the GNU check fails (they are not; see Claim 8) or when N is lowered to 1.

```bash
# scripts/run-tests.sh:411
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
# /usr/libexec/bats-core/bats-exec-suite:415-420 (excerpt of the file-dispatch if/else, which continues to :427 — read)
if [[ "$num_jobs" -gt 1 ]] && [[ -z "$bats_no_parallelize_across_files" ]]; then
  ...
  parallel --keep-order --jobs "$num_jobs" bats-exec-file "$(printf "%q " "${flags[@]}")" "{}" "$TESTS_LIST_FILE" ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1
# /usr/libexec/bats-core/bats-exec-file:294
  if [[ "$num_jobs" != 1 && "${BATS_NO_PARALLELIZE_WITHIN_FILE-False}" == False ]]; then
```

`--no-parallelize-within-files` sets `BATS_NO_PARALLELIZE_WITHIN_FILE=1` (`bats-exec-file:24-26`), so a file's tests take the serial branch. The dry-run output in E4b shows the `bats-exec-file ... -j 2 --no-parallelize-within-files` lines parallel would run.

**Evidence:** `scripts/run-tests.sh:404-415`, `/usr/libexec/bats-core/bats-exec-suite:415-427`, `/usr/libexec/bats-core/bats-exec-file:20-30`, `:286-300`, `$FC/E4b-runner-probes-output.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "a file's tests may share state (health-check.bats caches one health-check run in $BATS_FILE_TMPDIR in setup_file for all its tests)"

**Location:** `scripts/run-tests.sh:87-89`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the example's facts (a cache in `$BATS_FILE_TMPDIR`, written in `setup_file`, read by every test). It does not establish that this state needs within-file serialism. In bats 1.8.2, `setup_file` finishes before any test starts, and the tests only read the cache, so running health-check.bats' tests in parallel would not race on it.

The facts hold:

```bash
# test/scripts/health-check.bats:25
_HC_CACHE_DIR="$BATS_FILE_TMPDIR/hc-cache"
# test/scripts/health-check.bats:34-36
setup_file() {
  _run_and_cache
}
```

`setup()` (`:42-52`) reads the cache and re-runs the check only if the cache is missing. Order in bats:

```bash
# /usr/libexec/bats-core/bats-exec-file:352 and :357
bats_run_setup_file
bats_run_tests
```

The sentence gives the example as the reason tests "stay serial". Shared read-only state written before any test runs is not a hazard that `--no-parallelize-within-files` removes. The precise version: health-check.bats shares a per-file cache, which is safe either way. The example does not motivate the flag unless a file's tests write shared state while other tests run. This is a rationale issue, not a behaviour bug; the flag itself is correct.

**Evidence:** `test/scripts/health-check.bats:21-52`, `/usr/libexec/bats-core/bats-exec-file:67-100`, `:352-357`
**Legibility-target:** for-author

---

## Claim 5a: "The slowest file bounds the speedup"

**Location:** `scripts/run-tests.sh:89-90`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lower bound: wall time can be no shorter than the longest single file, because files do not split. It does not establish which file is the slowest today.

paraphrased — no quote available because this follows from Claim 3 (each file runs as one serial `bats-exec-file` job), not from one line: a run cannot end before its longest job does.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:415-420`, `/usr/libexec/bats-core/bats-exec-file:294-300`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5b: "N above the core count buys nothing"

**Location:** `scripts/run-tests.sh:90`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing measured. The brief's numbers stop at the core count (16 cores: 144 s at `--jobs 8`, 137 s at `--jobs 16`). Nothing above 16 was measured, and many suites wait on sleeps and subprocesses rather than CPU.

paraphrased — no quote available because the claim is about wall time, and no measurement above the core count exists. Verifying it would need a full-suite timing at `--jobs 24` or `32` on the 16-core host, which the brief does not allow in this pass.

**Evidence:** brief "What this PR is trying to accomplish" (measurements); `nproc` = 16
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6a: "install.sh's procs_in_checkout, which install-host.bats runs, refuses when it cannot read the working directory of any process of the user"

**Location:** `scripts/run-tests.sh:90-93`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers who refuses and when. It does not establish install-host.bats' results under `--jobs`, which were not run.

`procs_in_checkout` does not refuse. It lists the process, and `agent_gate` refuses:

```bash
# devcontainer-config/install.sh:1171-1180 (excerpt of procs_in_checkout, :1165-1182 — read)
    if cwd="$(readlink "$d/cwd" 2>/dev/null)"; then
      case "$cwd" in "$root"|"$root"/*) kind=in ;; *) continue ;; esac
    else
      kind=unknown
    fi
    pid="${d#/proc/}"
    in_lineage "$pid" && continue
    cmd="$(tr '\0' ' ' 2>/dev/null < "$d/cmdline")"
    [ -n "$cmd" ] || continue                   # exited, or a kernel thread
# devcontainer-config/install.sh:1248 (agent_gate, :1188-1283 — read)
  if [ -z "$procs" ] && [ -z "$inrepo" ] && [ -z "$unknown" ] && [ -z "$ctrs" ]; then return 0; fi
```

There are two exemptions. install.sh's own lineage is skipped, and so is a process with no command line (one that exited mid-scan). The precise version: install.sh's agent gate refuses when `procs_in_checkout` finds a live process of the user whose working directory it cannot read.

**Evidence:** `devcontainer-config/install.sh:1150-1182`, `:1188-1283`
**Legibility-target:** for-author

---

## Claim 6b: "so other files' processes starting and ending beside it can make it refuse where a serial run would not"

**Location:** `scripts/run-tests.sh:93-94`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the mechanism the sentence names, processes starting and ending. It does not establish that no other file ever starts a process whose working directory cannot be read (a grep of test/ found only install-host.bats' own T92). It also does not cover exotic exec transitions such as setuid or execute-only binaries.

Processes starting and ending do not produce a refusal. A process that ends mid-scan loses its command line together with its working directory, and it is skipped (`[ -n "$cmd" ] || continue`, `devcontainer-config/install.sh:1179`, quoted in 6a). A newly forked process has a readable working directory. E2 ran the verbatim `procs_in_checkout` for 15 s beside a loop forking `bash -c ':'` 8 at a time: 757 scans, 0 `unknown` lines. E2b repeated it with `xargs -P 16 sh -c "cd /tmp && exec /bin/true"`: 1005 scans, 0 `unknown` lines. What does produce `unknown` is a live process that hides its working directory. E3 shows a `prctl(PR_SET_DUMPABLE, 0)` process owned by this uid (`-O true`) whose `readlink /proc/PID/cwd` fails (rc 1). No other suite starts one (paraphrased — no quote available because the claim covers absence of code: `rg -il 'prctl|DUMPABLE|ssh-agent|unshare|bwrap' test --glob '*.bats'` hits only install-host.bats' T92 at `:1594-1602` plus two arithmetic-eval suites that only mention bwrap in text).

A reader who hits an install-host refusal under `--jobs` would look for process churn, which is not a cause. The precise version: under `--jobs`, install.sh's scan also sees other files' processes, and it refuses if one of them hides its working directory (is non-dumpable), which a serial run would not show. No current suite starts such a process outside install-host.bats itself.

**Evidence:** `devcontainer-config/install.sh:1165-1182`, `test/install-host.bats:1594-1602`, `$FC/E2-procscan-churn.log`, `$FC/E2b-procscan-churn-xargs.log`, `$FC/E3-nondumpable.log`, `$FC/scan-probe.sh`
**Legibility-target:** for-author

---

## Claim 7: "bats runs files through GNU parallel and aborts without it even for one file, so when the first `parallel` on PATH is missing or is not GNU parallel (moreutils ships one too), the runner warns and runs serially."

**Location:** `scripts/run-tests.sh:95-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bats' abort when parallel is absent at N > 1, whatever the file count, and the runner's warning and serial run when parallel is missing (test 29) or a fake non-GNU one comes first (test 28). It does not establish three things. (i) The runner never hands bats N > 1 for one selected file, because of the clamp, and then runs no check at all (P5). (ii) "Not GNU" means "`parallel --version` does not start with `GNU parallel`", so a real GNU parallel whose `--version` fails, for example because of an unparsable `$PARALLEL` or config line, gets the same "not GNU parallel" warning and a serial run (P4, see Claim 9). (iii) The moreutils aside was not checked on this host: moreutils is not installed.

```bash
# /usr/libexec/bats-core/bats-exec-suite:99-102 (excerpt of the num_jobs block, :99-107 — read)
if [[ "$num_jobs" != 1 ]]; then
  if ! type -p parallel >/dev/null && [[ -z "$bats_no_parallelize_across_files" ]]; then
    abort "Cannot execute \"${num_jobs}\" jobs without GNU parallel"
    exit 1
# scripts/run-tests.sh:406
  if [[ "$(parallel --version 2>/dev/null)" == "GNU parallel"* ]]; then
```

P4 (E4b) printed `WARNING: --jobs 2 needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially` with the real GNU parallel first on PATH and `PARALLEL=--bogus-opt`. E1 case E shows `PARALLEL=--bogus-opt parallel --version` prints `Unknown option: bogus-opt`.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-107`, `scripts/run-tests.sh:404-415`, `$FC/E4b-runner-probes-output.log` (P4), `$FC/E4-runner-probes.log` (P5), `$FC/E1-parallel-config-sources.log`, `$FC/E5-mutants-and-suite.log` (tests 28 and 29)
**Legibility-target:** for-author

---

## Claim 8: "It unsets $PARALLEL and points $PARALLEL_HOME at .bats/parallel-home (left at the user's default when that cannot be created)"

**Location:** `scripts/run-tests.sh:97-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the runner does to the two variables before exec'ing bats. It does not establish two things. (i) The runner's own `parallel --version` check runs before the unset, so `$PARALLEL` still reaches it (Claim 7 (ii)). (ii) This does not isolate the user's config (Claim 9).

```bash
# scripts/run-tests.sh:406-411 (excerpt of the jobs block, :404-415 — read)
  if [[ "$(parallel --version 2>/dev/null)" == "GNU parallel"* ]]; then
    unset PARALLEL
    if mkdir -p "$REPO_ROOT/.bats/parallel-home" 2>/dev/null; then
      export PARALLEL_HOME="$REPO_ROOT/.bats/parallel-home"
    fi
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
```

When `mkdir` fails, `PARALLEL_HOME` keeps whatever value the user's environment gave it, which is "the user's default".

**Evidence:** `scripts/run-tests.sh:404-415`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "so the user's parallel options and config cannot change how bats' run behaves."

**Location:** `scripts/run-tests.sh:99-100`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU parallel 20221122 (the installed Debian build) with `PARALLEL_HOME` set, and the runner end to end. It establishes that the user's config files and `$PARALLEL_CSH` still apply. It does not establish any silent failure: bats' test-count validator makes such a run fail ("Executed 0 instead of expected 4 tests", status 1), so the effect fails closed.

GNU parallel reads the `config` file of every existing config directory, not just `$PARALLEL_HOME`'s, plus `~/.parallelrc` and `/etc/parallel/config`:

```perl
# /usr/bin/parallel:2842-2847 (excerpt of the config-dir setup, :2828-2862 — read)
    @Global::config_dirs =
	(grep { -d $_ }
	 $ENV{'PARALLEL_HOME'},
	 (map { "$_/parallel" }
	  $xdg_config_home,
	  split /:/, $ENV{'XDG_CONFIG_DIRS'}),
	 $ENV{'HOME'} . "/.parallel");
# /usr/bin/parallel:3319-3323 and :3366-3368 (excerpts of the option parsing, :3300-3375 — read)
	my @config_profiles = (
	    "/etc/parallel/config",
	    (map { "$_/config" } @Global::config_dirs),
	    $ENV{'HOME'}."/.parallelrc");
	...
	if($ENV{'PARALLEL_CSH'}) {
	    push @ARGV_env, shell_words($ENV{'PARALLEL_CSH'});
	}
```

E1: with `PARALLEL_HOME` pointing at an existing empty directory, `--dry-run` in `~/.parallel/config`, in `~/.parallelrc`, in `$XDG_CONFIG_HOME/parallel/config`, or in `$PARALLEL_CSH` each made `parallel echo real-{} ::: a` print `echo real-a` instead of `real-a`. Through the runner, P3 and P3b (E4b) ran `--jobs 2` with `HOME` holding `~/.parallel/config` or `~/.parallelrc` set to `--dry-run`. `.bats/parallel-home` was created, parallel printed the `bats-exec-file ...` command lines, no test ran, and bats reported `Executed 0 instead of expected 4 tests`. A config line such as `--ungroup` or `--line-buffer` would likewise change the grouping Claim 10 describes. The precise version: the runner unsets `$PARALLEL` (after its own version check) and points parallel's writable home at `.bats/parallel-home`. The user's parallel config files (`~/.parallel/config`, `~/.parallelrc`, `$XDG_CONFIG_HOME/parallel/config`, `/etc/parallel/config`) and `$PARALLEL_CSH` still apply.

**Evidence:** `/usr/bin/parallel:2828-2862`, `:3300-3375`, `$FC/E1-parallel-config-sources.log`, `$FC/E4b-runner-probes-output.log` (P3, P3b), `$FC/probe.bats`
**Legibility-target:** for-author

---

## Claim 10: "bats keeps each file's output together (parallel groups output by default) and in file order (--keep-order), so a file's results appear once it and every file before it have ended."

**Location:** `scripts/run-tests.sh:101-103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers parallel's defaults and bats' `--keep-order`. It does not establish the behaviour when a user config file sets `--ungroup` or `--line-buffer`, which Claim 9 shows is still read.

```bash
# /usr/libexec/bats-core/bats-exec-suite:420
  parallel --keep-order --jobs "$num_jobs" bats-exec-file ... 2>&1 || bats_exec_suite_status=1
```

paraphrased — no quote available because grouping is parallel's default, the absence of `--ungroup` or `--line-buffer`, and so has no single line to quote. Pass 1 observed it by execution: `docs/reviews/execution-logs/q090-fc-k1-E2-grouping-order-within-file.log`. The bats and parallel code involved is unchanged since then.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:415-420`, `/usr/bin/parallel:2405-2440`, `docs/reviews/execution-logs/q090-fc-k1-E2-grouping-order-within-file.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "Every test still writes its own run-log line, so the run log, the test-count check and --failed work as in a serial run."

**Location:** `scripts/run-tests.sh:103-105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a complete `--jobs 2` run whose log passes the `expected=` check, and `--failed --jobs 2` re-running from it (test 23), and a killed `--jobs 2` run being refused (test 24). It does not establish that those tests make sure parallel was actually used (see Claim 19).

Test 23 asserts `expected=4` and 4 result lines:

```bash
# test/scripts/run-tests.bats:382-383 (excerpt of the test at :379-398 — read)
  [ "$(sed -n 1p "$T/.bats/last-run")" = "expected=4" ]
  [ "$(grep -cE '^(passed|failed) ' "$LOG_DIR"/*.log)" -eq 4 ]
```

Tests 23 and 24 passed in the unmutated run (E5).

**Evidence:** `test/scripts/run-tests.bats:379-414`, `scripts/run-tests.sh:236-262`, `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "bats folds parallel's stderr into its output; the locale pin above keeps perl's setlocale warnings out of it, and upstream parallel prints its citation notice only when its stderr is a terminal, which inside bats it never is (Debian's build never prints it)."

**Location:** `scripts/run-tests.sh:105-108`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `2>&1`, stdout always being a pipe into the formatter, the `-t` condition in the function as shipped in this source, Debian's commented-out call, and test 25 passing under an uninstalled `LANG`. It does not establish citation behaviour of other upstream releases. It also does not establish the pre-existing LC_CTYPE residue (pass-1 E7). Test 25's own evidence that parallel ran is weaker than it looks (Claim 15).

```bash
# /usr/libexec/bats-core/bats:465-467 (excerpt; the if/else continues to :467 — read)
  exec bats-exec-suite "${flags[@]}" "${filenames[@]}" |
    bats_test_count_validator |
    "$interpolated_formatter" "${formatter_flags[@]}"
```

```perl
# /usr/bin/parallel:2578
#    citation_notice();
# /usr/bin/parallel:5637-5643 (excerpt of citation_notice, :5632-5670 — read)
    if($opt::willcite
       or
       $opt::plain
       or
       not -t $Global::original_stderr
       or
       grep { -e "$_/will-cite" } @Global::config_dirs) {
```

Test 25 passed (E5).

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, `/usr/libexec/bats-core/bats:459-467`, `/usr/bin/parallel:2578`, `:5632-5670`, `scripts/run-tests.sh:166-175`, `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "At most 3 digits, so the value never overflows bash arithmetic and parallel never sizes thousands of job slots."

**Location:** `scripts/run-tests.sh:136-137`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the regex bound (≤ 999) and the clamp that follows. It does not establish that 999 slots is harmless; the clamp to the file count (124 today) is what keeps N small in practice.

```bash
# scripts/run-tests.sh:138
      if [[ ! "${2:-}" =~ ^[1-9][0-9]{0,2}$ ]]; then
```

999 fits in bash's 64-bit arithmetic, and 999 < 1000, so the value never reaches thousands of slots. The pass-1 security probe P4 showed the problem this bound removes (`--jobs 20000` orphaned parallel and held the lock), cited in `docs/reviews/q090-security-review-2026-09-30.md:19`.

**Evidence:** `scripts/run-tests.sh:135-145`, `:404`, `docs/reviews/q090-security-review-2026-09-30.md:18-20`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14a: "Test for GNU parallel itself, not the file count"

**Location:** `scripts/run-tests.sh:401-402`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the file count affects whether the check runs. It does not establish anything about the check's contents (Claim 14c).

At 088bc97 the check ran for any N > 1 whatever the file count (`if [[ "$jobs" -gt 1 ]]; then if command -v parallel` in `git show 088bc97`), which is what "not the file count" described. Since 084868f, the line right below the comment clamps N to the file count:

```bash
# scripts/run-tests.sh:404-406 (excerpt of the jobs block, :404-415 — read)
(( jobs > ${#files[@]} )) && jobs=${#files[@]}
if [[ "$jobs" -gt 1 ]]; then
  if [[ "$(parallel --version 2>/dev/null)" == "GNU parallel"* ]]; then
```

With one selected file, N becomes 1 and no check runs. P5 (E4) ran `--jobs 5 test/gamma.bats` with a non-GNU `parallel` first on PATH: exit 0, no warning. The behaviour is fine, because bats needs no parallel at N = 1. But the file count now does decide whether the check runs. The precise version: "N is first lowered to the file count; when it is still > 1, test for GNU parallel itself, because bats aborts without it."

**Evidence:** `scripts/run-tests.sh:401-415`, `git show 088bc97 -- scripts/run-tests.sh`, `$FC/E4-runner-probes.log` (P5)
**Legibility-target:** for-author

---

## Claim 14b: "bats aborts without it whenever N > 1"

**Location:** `scripts/run-tests.sh:402`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a missing `parallel` (`type -p` fails). It does not establish bats' behaviour with a non-GNU `parallel` present: bats does not check for GNU and would run it.

Quoted at Claim 7 (`/usr/libexec/bats-core/bats-exec-suite:99-102`). Pass 1 executed this: `docs/reviews/execution-logs/q090-fc-k1-E1-abort-without-parallel.log`.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-107`, `docs/reviews/execution-logs/q090-fc-k1-E1-abort-without-parallel.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14c: "bats runs the first `parallel` on PATH, so that is the one checked."

**Location:** `scripts/run-tests.sh:402-403`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the PATH bats inherits (the runner `exec`s bats with the environment unchanged) and bats' own PATH prepend. It does not establish the case of a `parallel` placed inside bats' libexec directory, which would win for bats but not for the runner. None exists (`ls /usr/libexec/bats-core`).

```bash
# /usr/libexec/bats-core/bats:101
export PATH="$BATS_LIBEXEC:$PATH"
# /usr/libexec/bats-core/bats-exec-suite:420 (bare name, looked up on that PATH)
  parallel --keep-order --jobs "$num_jobs" bats-exec-file ...
# scripts/run-tests.sh:432
exec bats "${bats_args[@]}" "${files[@]}"
```

`/usr/libexec/bats-core` holds `bats`, `bats-exec-*`, `bats-format-*` and `bats-preprocess`, and no `parallel`. Test 28 (a fake first on PATH is detected) and the shim tests, whose shim first on PATH is the one bats calls, passed (E5).

**Evidence:** `/usr/libexec/bats-core/bats:101`, `/usr/libexec/bats-core/bats-exec-suite:420`, `scripts/run-tests.sh:432`, `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "parallel_shim: put a `parallel` first on PATH that logs its arguments to $T/parallel.args and execs the real one, so a test can see bats used it."

**Location:** `test/scripts/run-tests.bats:329-330`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the shim logs and which assertions still show that bats used parallel. It does not re-open the pass-1 settled rows. This finding is new since pass 1: it comes from 084868f's `parallel --version` check.

Since 084868f the runner calls `parallel --version` itself (`scripts/run-tests.sh:406`), through the same shim. So `$T/parallel.args` exists whenever the check runs, even if bats never calls parallel. P4 (E4b) is a serial fallback, yet `parallel.args` held 1 line, the runner's `--version`. The argument contents still show bats' call: tests 21 and 26 grep `--jobs 2` and `--no-parallelize-within-files`. File existence does not, and test 25 relies on existence:

```bash
# test/scripts/run-tests.bats:416-421 (excerpt of the test at :416-426 — read)
@test "--jobs: an uninstalled locale leaves no perl or citation text in the output" {
  parallel_shim
  in_runner LANG=xx_XX.UTF-8 -- --jobs 2
  [ "$status" -eq 1 ]
  [[ "$output" == *"Locale xx_XX.UTF-8 is not installed"* ]]
  [ -f "$T/parallel.args" ]
```

The nojobsarg mutant (E5) keeps the GNU check but never hands bats `--jobs`, so every run is serial. It passes test 25 (and tests 23 and 24). Test 25's "the run went through parallel" precondition, which made its "no perl text from parallel" assertion meaningful and which pass 1's E5 mutation check relied on at 088bc97, no longer holds. The precise version of the comment: "...so a test can see how bats called it (grep the arguments; the runner's own `--version` probe is logged too)". Test 25 would need `grep -q -- '--jobs 2' "$T/parallel.args"` in place of `[ -f ... ]` to keep its precondition.

**Evidence:** `test/scripts/run-tests.bats:329-340`, `:358-369`, `:416-426`, `scripts/run-tests.sh:406`, `$FC/E4b-runner-probes-output.log` (P4), `$FC/E5-mutants-and-suite.log` (mutant nojobsarg)
**Legibility-target:** for-author

---

## Claim 16: "--jobs: a missing, zero, non-numeric or 4-digit N is a usage error"

**Location:** `test/scripts/run-tests.bats:342`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named cases the test asserts (`--jobs` with nothing, `0`, `x`, `1000`: exit 2 with the message) and that no test ran after the last one. It does not establish the leading-zero or sign cases, which the name does not claim (P1 covers them; Claim 1).

```bash
# test/scripts/run-tests.bats:352-355 (excerpt of the test at :342-356 — read)
  runner --jobs 1000 test/gamma.bats
  [ "$status" -eq 2 ]
  [[ "$output" == *"got: 1000"* ]]
  [[ "$output" != *"gamma clean output"* ]]
```

**Evidence:** `test/scripts/run-tests.bats:342-356`, `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "--jobs 2 runs files through parallel, not tests within a file"

**Location:** `test/scripts/run-tests.bats:358`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions: parallel's arguments contain `--jobs 2` and `--no-parallelize-within-files`. It does not establish observed serial execution within a file. This is settled: pass-1 A5, override-log row 172. There is no new evidence, and it is listed only for completeness. The `1..4` plan-line assertion does not tell the cases apart (bats prints it before parallel runs; P6).

```bash
# test/scripts/run-tests.bats:366-368 (excerpt of the test at :358-369 — read)
  [ -f "$T/parallel.args" ]
  grep -q -- '--jobs 2' "$T/parallel.args"
  grep -q -- '--no-parallelize-within-files' "$T/parallel.args"
```

The nojobsarg mutant fails this test (E5).

**Evidence:** `test/scripts/run-tests.bats:358-369`, `docs/reviews/override-log.md:172`, `$FC/E5-mutants-and-suite.log`, `$FC/E4b-runner-probes-output.log` (P6)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "--jobs 1 runs serially and needs no parallel"

**Location:** `test/scripts/run-tests.bats:371`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the shim (so no parallel, not even the runner's `--version` probe) is never called at `--jobs 1`. It does not establish a run with parallel absent from PATH. Also, with one file even `--jobs 5` takes this path (Claim 14a), so the test does not tell the explicit 1 apart from the clamp.

```bash
# test/scripts/run-tests.bats:373-376 (excerpt of the test at :371-377 — read)
  runner --jobs 1 test/gamma.bats
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok 1 gamma clean output"* ]]
  [ ! -f "$T/parallel.args" ]
```

**Evidence:** `test/scripts/run-tests.bats:371-377`, `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "--jobs: a parallel run records a complete log that --failed re-runs from" / "--jobs: a parallel run killed partway is refused by --failed"

**Location:** `test/scripts/run-tests.bats:379`, `test/scripts/run-tests.bats:400`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the log, count and `--failed` assertions under `--jobs 2`, which on this host (GNU parallel present, shim first on PATH) is a parallel run. It does not establish that either test would notice a serial run: neither asserts on `parallel.args`, and the nojobsarg mutant passes both (E5).

paraphrased — no quote available because the assertions are quoted at Claim 11. The finding here is that no assertion exists (the claim covers absence of code: neither test body at `:379-398` or `:400-414` reads `$T/parallel.args`).

**Evidence:** `test/scripts/run-tests.bats:379-414`, `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: "--jobs: an uninstalled locale leaves no perl or citation text in the output" and "gamma asserts its own subprocess output is clean; the suite-level output must be clean too."

**Location:** `test/scripts/run-tests.bats:416-424`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions as written: the pin message, gamma ok, no `perl|setlocale|cite|citation` in the output. It does not establish that the run went through parallel (Claim 15). The citation part cannot fail on Debian's build (settled, pass-1 claim 22 / override row 173).

```bash
# test/scripts/run-tests.bats:422-425 (excerpt of the test at :416-426 — read)
  # gamma asserts its own subprocess output is clean; the suite-level output
  # must be clean too.
  [[ "$output" == *"ok"*"gamma clean output"* ]]
  ! grep -iE 'perl|setlocale|cite|citation' <<< "$output"
```

The gamma fixture asserts `[ "$output" = hi ]` on `run bash -c "echo hi"` (`:29-30`), which matches the comment.

**Evidence:** `test/scripts/run-tests.bats:28-30`, `:416-426`, `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: "--jobs above the file count is lowered to it"

**Location:** `test/scripts/run-tests.bats:428`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--jobs 999` with 2 files reaching parallel as `--jobs 2 `. It does not establish the clamp under `--failed` or gating, where `files` is smaller still.

```bash
# test/scripts/run-tests.bats:430-432 (excerpt of the test at :428-433 — read)
  runner --jobs 999 test/gamma.bats test/sub/beta.bats
  [ "$status" -eq 0 ]
  grep -q -- '--jobs 2 ' "$T/parallel.args"
```

The noclamp mutant fails it (E5).

**Evidence:** `test/scripts/run-tests.bats:428-433`, `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: "--jobs: the user's PARALLEL options do not reach bats' parallel" and "--dry-run would run no test at all."

**Location:** `test/scripts/run-tests.bats:435-437`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `$PARALLEL` only, the narrow reading of "PARALLEL options". It does not establish that the user's parallel config files are ignored: they are not (Claim 9). Its `1..4` assertion cannot fail: bats prints the plan line before parallel runs, and P6 shows `1..4` under a forced `--dry-run`. The `ok ... beta steady` assertion is the one that tells the cases apart.

P6 (E4b): with `--dry-run` forced, parallel printed the `bats-exec-file` lines, and bats reported `Executed 0 instead of expected 4 tests`. That confirms "would run no test at all". The nounset mutant fails this test (E5).

```bash
# test/scripts/run-tests.bats:438-442 (excerpt of the test at :435-443 — read)
  in_runner LC_ALL="$WORKING_LOCALE" PARALLEL=--dry-run -- --jobs 2
  [ "$status" -eq 1 ]
  [[ "$output" == *"1..4"* ]]
  [[ "$output" == *"ok"*"beta steady"* ]]
  [ -d "$T/.bats/parallel-home" ]
```

**Evidence:** `test/scripts/run-tests.bats:435-443`, `$FC/E4b-runner-probes-output.log` (P6), `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: "--jobs with a non-GNU parallel first on PATH warns and runs serially"

**Location:** `test/scripts/run-tests.bats:445`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a fake `parallel` that prints a non-GNU banner and exits 1. It does not establish the real moreutils binary's `--version` behaviour (not installed here).

```bash
# test/scripts/run-tests.bats:452-454 (excerpt of the test at :445-455 — read)
  runner --jobs 2 test/gamma.bats test/sub/beta.bats
  [ "$status" -eq 0 ]
  [[ "$output" == *"is not GNU parallel; running serially"* ]]
```

If the runner did not fall back, bats would call the fake and fail, so `status 0` plus `ok 2 beta steady` shows a serial run.

**Evidence:** `test/scripts/run-tests.bats:445-455`, `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: "A PATH holding everything the current one does except parallel (and bats' libexec directory, which in_runner drops too)."

**Location:** `test/scripts/run-tests.bats:458-459`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the symlink loop and in_runner's libexec drop. It does not establish that non-executable or directory entries are carried over (they are not, which is harmless here).

```bash
# test/scripts/run-tests.bats:464-466 (excerpt of the test at :457-478 — read)
    [[ -d "$dir" && "$dir" != "$BATS_LIBEXEC" ]] || continue
    for f in "$dir"/*; do
      [[ -x "$f" && ! -e "$bin/${f##*/}" && "${f##*/}" != parallel ]] && ln -s "$f" "$bin/${f##*/}"
# test/scripts/run-tests.bats:61
  path="${path//":$BATS_LIBEXEC:"/:}"
```

`! -e` keeps the first match, so PATH precedence is preserved. The test passed (E5).

**Evidence:** `test/scripts/run-tests.bats:58-68`, `:457-478`, `$FC/E5-mutants-and-suite.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: Commit 088bc97: "N must be a positive integer (else exit 2)"; "the check is `command -v parallel`, not the file count"; "The fallback and locale tests were mutation-checked (each fails with its guard removed)."

**Location:** commit 088bc97 (message body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claims against 088bc97's own tree and pass 1's executed mutants. It does not establish that they still hold at HEAD: the bound, the check and the locale test's discrimination changed in 084868f (Claims 1, 14a, 15). The Notes' `script` tty claim is settled (override row 173) and not re-verdicted.

At 088bc97 (`git show 088bc97 -- scripts/run-tests.sh`): `if [[ ! "${2:-}" =~ ^[1-9][0-9]*$ ]]` with exit 2, and `if [[ "$jobs" -gt 1 ]]; then if command -v parallel > /dev/null`. The mutation check is recorded in `docs/reviews/execution-logs/q090-fc-k1-E5-mutants.log`.

**Evidence:** `git show 088bc97 -- scripts/run-tests.sh`, `docs/reviews/execution-logs/q090-fc-k1-E5-mutants.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26a: Commit 084868f: descriptive items (header example now health-check.bats' setup_file cache; install-host exposure stated as cross-file; grouping = default `--group`, order = `--keep-order`; citation sentence names Debian; 1 to 999; N lowered to the file count; `parallel --version` check; the listed tests; fallback comment names libexec; 8 override-log rows; Notes: `.bats/` gitignored, "16 cores, 124 files")

**Location:** commit 084868f (message body)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each described change is present in 084868f's diff and that the host facts hold. It does not endorse the correctness of the install-host sentence those changes wrote (Claim 6b).

Quoted for each: the header text at `scripts/run-tests.sh:87-108`; the regex at `:138`; the clamp at `:404`; the check at `:406`; the tests at `test/scripts/run-tests.bats:342`, `:428`, `:435`, `:445`, `:458-459`. `git show --stat 084868f` lists `docs/reviews/override-log.md | 8 +`, and override-log rows 166-173 are the 8 rows dated 2026-09-30 for `feat/run-tests-jobs`. `git check-ignore -v .bats/parallel-home` gives `.gitignore:43:.bats/`. `nproc` gives 16. `git ls-tree -r --name-only 084868f test | grep -c '\.bats$'` gives 124.

**Evidence:** `git show 084868f`, `docs/reviews/override-log.md:166-173`, `.gitignore:43`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26b: Commit 084868f: "$PARALLEL is unset and $PARALLEL_HOME points at .bats/parallel-home, so the user's parallel options or config cannot alter bats' run (security F2)."

**Location:** commit 084868f (message body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 9. It does not establish a silent failure: such a run fails closed through bats' count validator.

The same mechanism as Claim 9: `~/.parallel/config`, `~/.parallelrc`, `$XDG_CONFIG_HOME/parallel/config`, `/etc/parallel/config` and `$PARALLEL_CSH` still reach bats' parallel (`/usr/bin/parallel:2842-2847`, `:3319-3323`, quoted there). Through the runner, P3 and P3b (E4b) show them doing so. The commit is immutable; the header (Claim 9) is where the fix lands.

**Evidence:** `/usr/bin/parallel:2828-2862`, `:3300-3375`, `$FC/E1-parallel-config-sources.log`, `$FC/E4b-runner-probes-output.log`
**Legibility-target:** for-author

---

## Claim 26c: Commit 084868f: "--jobs takes 1 to 999 (was any digit string, which could overflow bash arithmetic and make parallel fork thousands of slot probes that keep the run lock after a TERM ...)"

**Location:** commit 084868f (message body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "was" description of 088bc97's validator. The overflow and orphan consequences are verified by pass-1 execution (E6, security P3/P4).

088bc97 accepted a positive integer with no leading zero (`^[1-9][0-9]*$`), not "any digit string": `0` and `02` were rejected (`docs/reviews/execution-logs/q090-fc-k1-E6-jobs-usage.log`: `--jobs 0` and `--jobs 02` both exit 2). The precise version: "was any positive integer, however long".

**Evidence:** `git show 088bc97 -- scripts/run-tests.sh`, `docs/reviews/execution-logs/q090-fc-k1-E6-jobs-usage.log`, `docs/reviews/q090-security-review-2026-09-30.md:18-20`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26d: Commit 084868f: "The clamp and PARALLEL tests were mutation-checked."

**Location:** commit 084868f (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers removing the clamp line, which fails test 26, and removing `unset PARALLEL`, which fails test 27. It does not establish the other new tests' sensitivity (see Claims 15 and 19 for tests a serial mutant passes).

The E5 mutants reproduced it. `m-noclamp`: `not ok 7 --jobs above the file count is lowered to it`, everything else ok. `m-nounset`: `not ok 8 --jobs: the user's PARALLEL options do not reach bats' parallel`, everything else ok.

**Evidence:** `$FC/E5-mutants-and-suite.log`, `$FC/m-noclamp/scripts/run-tests.sh:404`, `$FC/m-nounset/scripts/run-tests.sh:407`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: Commit f733a51: "the header said the runner always points $PARALLEL_HOME at .bats/parallel-home; it does only when that directory can be created." / "comment-only."

**Location:** commit f733a51 (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff and the qualifier's accuracy against `:408-410`. It does not endorse the rest of the sentence it edited (Claim 9).

`git show f733a51 --stat` lists only `scripts/run-tests.sh | 5 +++--`, and every changed line is a `#` comment. It adds `(left at the user's default when that cannot be created)`, which matches `if mkdir -p "$REPO_ROOT/.bats/parallel-home" 2>/dev/null; then export PARALLEL_HOME=...` (`scripts/run-tests.sh:408-410`).

**Evidence:** `git show f733a51`, `scripts/run-tests.sh:406-411`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 6b** (`scripts/run-tests.sh:93-94`): processes starting and ending do not trigger install.sh's refusal: exited processes are skipped, and 1762 scans under churn found no `unknown`. The cross-file trigger is a concurrent live process that hides its cwd (non-dumpable). State that instead.
- **Claim 9** (`scripts/run-tests.sh:99-100`): `PARALLEL_HOME` does not isolate config. GNU parallel still reads `~/.parallel/config`, `~/.parallelrc`, `$XDG_CONFIG_HOME/parallel/config`, `/etc/parallel/config` and `$PARALLEL_CSH`, and a `--dry-run` there ran 0 of 4 tests through the runner. This fails closed through bats' count validator. Either narrow the sentence to `$PARALLEL` and where parallel writes, or isolate the config too.
- **Claim 26b** (commit 084868f): the same false isolation claim. The commit is immutable, so fix it in the header and record it in the override log.

### Stale
- **Claim 14a** (`scripts/run-tests.sh:401-402`): "not the file count" predates the clamp. The file count now decides whether the check runs, and for one file it does not. Reword.

### Mostly Accurate
- **Claim 4** (`scripts/run-tests.sh:87-89`): health-check.bats' cache is written in `setup_file` before any test and only read afterwards, so it is not state that within-file parallelism would race on. It is a weak example for the flag.
- **Claim 6a** (`scripts/run-tests.sh:90-93`): the refusal is `agent_gate`'s, on `procs_in_checkout`'s `unknown` lines, and it applies to live processes outside install.sh's lineage.
- **Claim 15** (`test/scripts/run-tests.bats:329-330`): the shim now also logs the runner's own `--version` probe, so `[ -f parallel.args ]` in test 25 no longer shows that bats used parallel (a serial mutant passes it). Grep the arguments instead.
- **Claim 17** (`test/scripts/run-tests.bats:358`): settled (override row 172); no new evidence.
- **Claim 26c** (commit 084868f): 088bc97 took any positive integer, not "any digit string".

### Unverifiable
- **Claim 5b** (`scripts/run-tests.sh:90`): "N above the core count buys nothing" needs a full-suite timing above `--jobs 16`.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path named below, structured per the skill.
- Answered: yes. All 5 priority groups were verdicted, most of them by execution (probes P1-P6, 3 mutants, the unmutated suite, a /proc-scan churn test, parallel config probes).
- Out of scope: running install-host.bats or the full suite under `--jobs` (brief); the real moreutils `parallel` (not installed); other upstream parallel releases.
- Escalate: Claim 9/26b (a new Incorrect, with a behaviour consequence that fails closed); Claim 6b (the Incorrect mechanism in the sentence written to fix pass-1 A1); Claim 15 (new since pass 1: 084868f's `--version` probe weakened test 25's parallel precondition, so pass-1 E5's locale mutant result no longer holds at HEAD). The Claim 9 misattribution (PARALLEL_HOME claimed to isolate parallel's config) may belong in `docs/reviews/hallucination-patterns.md`; I did not add it because the brief allows editing only this report.
- Decisions I made: kept execution logs in the scratchpad (`$FC`), not under `docs/reviews/execution-logs/`, because the brief forbids editing other files. Split the header's install-host sentence into 6a (attribution) and 6b (mechanism) because their verdicts differ. Listed settled rows (Claim 17; the citation part of Claim 20) without raising them again.
