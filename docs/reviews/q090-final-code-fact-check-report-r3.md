# Code Fact-Check Report

**Commit:** b34a6fe
**Replication:** r3 (final confirming pass 2)
**Repository:** /workspace/.claude/wt-run-tests-jobs (branch feat/run-tests-jobs)
**Scope:** `git diff main...HEAD -- scripts test`: scripts/run-tests.sh (the `--jobs` Flags entry, the "Parallel runs" header paragraph, the `--jobs` parsing and its comment, the `bats_args` block and its warning) and test/scripts/run-tests.bats (header, `parallel_shim`, 10 `--jobs` tests), plus the commit messages of 088bc97, 084868f and f733a51. `scripts/` and `test/` are unchanged between f733a51 and HEAD b34a6fe, which only adds the pass-1 rubric (`git diff --stat f733a51 b34a6fe -- scripts test` is empty). Claims were checked against the code that runs them: bats 1.8.2 libexec (`/usr/libexec/bats-core/{bats,bats-exec-suite,bats-exec-file}`), GNU parallel 20221122 (`/usr/bin/parallel`), `devcontainer-config/install.sh` (`procs_in_checkout`, `agent_gate`) and `test/scripts/health-check.bats` (`setup_file`).
**Checked:** 2026-09-30
**Total claims checked:** 36
**Summary:** 23 verified, 5 mostly accurate, 2 stale, 2 incorrect, 4 unverifiable

The hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read. No claim matches a logged pattern. The two Incorrect verdicts (Claims 11 and 31) are about how a real mechanism (`$PARALLEL_HOME`) behaves, not a fabricated symbol, so they are not logged. The brief also limits this pass to editing this report only.

Settled override-log rows for 2026-09-30 `feat/run-tests-jobs` were read and are not re-raised. Claim 21 is the override-log "claim 12" proxy. It is recorded here only as Verified-with-residue.

**Probes.** Every probe ran with `LC_ALL=C.UTF-8` under `timeout`. Each ran against a throwaway copy of the runner (a repo layout built the same way as run-tests.bats' `setup()`) or a copy of run-tests.bats, never the real suite, and never with `--jobs` above 999 (only the parse probe passed 999, which exits or is lowered to 2). Raw output is in `/tmp/claude-1000/-workspace/21797f19-046e-4351-9c55-0471f4b3d3b6/scratchpad/run-tests-jobs/fc-r3/` (written as `fc-r3/` below). Because the brief says to edit no file except this report, the logs stay in the scratchpad and are not copied into `docs/reviews/execution-logs/`. When the probes finished, `ps -eo pid,ppid,etime,args | grep -F run-tests-jobs/fc-r3` found no process left over.

| Probe | Command (summary) | cwd | Exit | UTC |
|---|---|---|---|---|
| E-r3-1 | `env -i PATH=… HOME=<home> LC_ALL=C.UTF-8 bash repo/scripts/run-tests.sh --jobs 2` with HOME holding no config, then `~/.parallel/config`=`--dry-run`, then `~/.parallelrc`=`--dry-run` | fc-r3 | 1, 1, 1 (the last two because `Executed 0 instead of expected 3 tests`) | 2026-09-30T21:49:38Z |
| E-r3-2 | `PARALLEL=--no-such-option parallel --version`, then the runner under `PARALLEL=--no-such-option --jobs 2` | fc-r3 | runner 1 (a2 fails by design; WARNING printed) | 21:49:51Z |
| E-r3-3 | The `procs_in_checkout` loop body (install.sh:1169-1181) run 20× idle, then 40× beside 4 loops that spawn processes | fc-r3 | 0, 0 | 21:50:51Z |
| E-r3-4 | Runner `--jobs` with 13 bad values, no value, `999` on 2 files, `2` on 1 file, `--failed --jobs 2` after a run with one failing file; a `parallel` shim logs each call's arguments | fc-r3 | 2 for every bad value; 1 for the runs (a failing fixture) | 21:51:35Z |
| E-r3-5 | `timeout 400 bats test/scripts/run-tests.bats` on unmutated M0 and mutants M1 (GNU check → `false`), M2 (no `unset PARALLEL`), M3 (no clamp), M4 (check → `command -v parallel`), M5 (the probe runs but the compare never matches) | fc-r3/mut-M* | M0 29/29 ok; failures listed per claim | 21:52:12Z–21:53:11Z |
| E-r3-6 | `--jobs 2`, then `--failed --jobs 2` with failures in 2 files (shim-logged); `bats --jobs 2 a.bats` on a PATH without `parallel` | fc-r3 | 1, 1, 1 (`Cannot execute "2" jobs without GNU parallel`) | 21:52:22Z |
| E-r3-7 | Runner `--jobs 2` with `.bats/parallel-home` blocked by a regular file and `PARALLEL_HOME=<dir with config --dry-run>` | fc-r3 | 1 (`Executed 0 instead of expected 3 tests`) | 21:52:31Z |

---

## Claim 1: "--jobs N  Run up to N test files at once … N is 1 to 999, digits only, no leading zero; anything else is a usage error (exit 2). 1, the default, runs serially; N above the number of selected files is lowered to it. Combines with every other flag, --failed included."

**Location:** `scripts/run-tests.sh:36-40`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the accepted value set, the exit 2, the default of 1, lowering N to the selected-file count, and `--failed` combined with a real parallel run. It does not establish other flag combinations beyond `--failed` and FILE (`--fast`/`--slow` were not probed with `--jobs`). "Selected files" means the files left after category filtering, report gating and the `--failed` narrowing, so `--failed` with one failing file runs serially.

The validator and the lowering step:

```bash
# scripts/run-tests.sh:135-145 (the --jobs case arm, complete)
    --jobs)
      # At most 3 digits, so the value never overflows bash arithmetic and
      # parallel never sizes thousands of job slots.
      if [[ ! "${2:-}" =~ ^[1-9][0-9]{0,2}$ ]]; then
        echo "--jobs takes a number from 1 to 999, got: ${2:-(nothing)}" >&2
        usage
        exit 2
      fi
      jobs="$2"
      shift 2
      ;;
```

```bash
# scripts/run-tests.sh:398 and :404
mapfile -t files <<< "$matched"
(( jobs > ${#files[@]} )) && jobs=${#files[@]}
```

`jobs=1` is the default (`scripts/run-tests.sh:126`). E-r3-4 got exit 2 and the error message for `''`, `0`, `007`, `01`, `1000`, `-3`, `+5`, `' 5'`, `'5 '`, `$'5\n'`, `٣`, `1e2`, `0x10` and a missing value. With `--jobs 999` and 2 files, the shim logged `--keep-order --jobs 2 bats-exec-file … -j 2 --no-parallelize-within-files`. With `--jobs 2 test/a.bats`, `parallel` was never called. E-r3-6 ran `--failed --jobs 2` with failures in two files: the shim logged `--keep-order --jobs 2 bats-exec-file … --no-parallelize-within-files`, and both failed tests re-ran.

**Evidence:** `scripts/run-tests.sh:126`, `scripts/run-tests.sh:135-145`, `scripts/run-tests.sh:398-415`, fc-r3/E-r3-4-jobs-parsing.log, fc-r3/E-r3-6-failed-parallel-and-abort.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "--jobs N (N > 1) hands bats `--jobs N --no-parallelize-within-files`, so whole files run side by side and the tests within a file stay serial"

**Location:** `scripts/run-tests.sh:85-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arguments handed to bats and how bats hands them on to `parallel` and `bats-exec-file`. It does not re-time within-file serialism at this commit: that was observed in pass 1 (q090-fc-k1-E2), and the bats code is unchanged. N is the value after lowering to the file count.

```bash
# scripts/run-tests.sh:411
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
```

```bash
# /usr/libexec/bats-core/bats-exec-suite:420
  parallel --keep-order --jobs "$num_jobs" bats-exec-file "$(printf "%q " "${flags[@]}")" "{}" "$TESTS_LIST_FILE" ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1
```

The shim log in E-r3-4 shows `bats-exec-file --dummy-flag -j 2 --no-parallelize-within-files`. Pass 1's E2 timestamps showed a file's tests running one after another under this flag and overlapping without it.

**Evidence:** `scripts/run-tests.sh:405-411`, `/usr/libexec/bats-core/bats-exec-suite:415-420`, fc-r3/E-r3-4-jobs-parsing.log, docs/reviews/execution-logs/q090-fc-k1-E2-grouping-order-within-file.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "as the suites were written: a file's tests may share state (health-check.bats caches one health-check run in $BATS_FILE_TMPDIR in setup_file for all its tests)"

**Location:** `scripts/run-tests.sh:87-89`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the example's facts: the cache location, that `setup_file` fills it, and that every test reads it. It does not establish that the example is state which running a file's tests in parallel would break. It is not: bats runs `setup_file` to completion before any test, and the tests only read the cache.

The example is accurate:

```bash
# test/scripts/health-check.bats:25-35 (excerpt; the cache block continues to setup() at :42-52 — read)
_HC_CACHE_DIR="$BATS_FILE_TMPDIR/hc-cache"

_run_and_cache() {
  mkdir -p "$_HC_CACHE_DIR"
  run bash "$SCRIPT"
  printf '%s' "$output" > "$_HC_CACHE_DIR/output"
  printf '%s' "$status" > "$_HC_CACHE_DIR/status"
}

setup_file() {
  _run_and_cache
}
```

`setup()` (`:42-52`) only reads `output`/`status`, and it re-runs `_run_and_cache` only when the cache file is missing. In bats-exec-file, `bats_run_setup_file` runs at top level (`/usr/libexec/bats-core/bats-exec-file:352`) before the test loop, which dispatches `bats_run_tests_in_parallel` at `:296`. So this shared state is written once before any test and is read-only afterwards. Running this file's tests in parallel would not corrupt it. The sentence still reads as though the example shows why tests within a file must stay serial. Precise version: say the suites were written assuming serial tests, and cite a file whose tests write shared state if the example is meant to justify the flag. If it is not, present it only as an example of shared per-file state.

**Evidence:** `test/scripts/health-check.bats:21-52`, `/usr/libexec/bats-core/bats-exec-file:67-99`, `/usr/libexec/bats-core/bats-exec-file:296`, `/usr/libexec/bats-core/bats-exec-file:352`
**Legibility-target:** for-author

---

## Claim 4: "The slowest file bounds the speedup"

**Location:** `scripts/run-tests.sh:89-90`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the structural bound: a file is the smallest unit of work under `--no-parallelize-within-files`, so wall time is at least the slowest file's time. It does not establish which file is the slowest or how close runs come to the bound.

The unit is the file (`bats-exec-suite:420`, quoted in Claim 2, runs one `bats-exec-file` per file, and `--no-parallelize-within-files` keeps each file's tests in one process sequence). The override log records install-host.bats alone at 105 s against a full run of 137–179 s under `--jobs` (paraphrased — no quote available because the figures are in a prose override-log cell at `docs/reviews/override-log.md:166`, not in code).

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, `docs/reviews/override-log.md:166`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: "and N above the core count buys nothing"

**Location:** `scripts/run-tests.sh:90`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the measurements supplied in the brief. It does not establish anything about N > 16 on this 16-core host (`nproc` = 16), nor whether I/O-bound or sleep-bound files gain from N above the core count.

The brief gives 144 s at `--jobs 8` and 137 s at `--jobs 16` (paraphrased — no quote available because the figures come from the orchestrator's brief, not the repo). No run above 16 exists. Verifying the claim needs a full-suite run at `--jobs 17` or more, which the brief bars.

**Evidence:** `scripts/run-tests.sh:90`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "install.sh's procs_in_checkout, which install-host.bats runs, refuses when it cannot read the working directory of any process of the user"

**Location:** `scripts/run-tests.sh:90-93`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the scan tags `unknown` and that the gate refuses on it. It does not establish which install-host tests reach the gate with the real /proc scan: pass 1 read that, and it is not re-read here.

`procs_in_checkout` does not refuse. It prints an `unknown` line, and `agent_gate` refuses on it. It also skips three kinds of process: its own lineage, other users' processes, and any process whose command line reads empty:

```bash
# devcontainer-config/install.sh:1169-1181 (excerpt; procs_in_checkout runs :1165-1182 — read)
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
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

`agent_gate` splits the scan's `unknown` lines at `:1225-1227` and refuses when any remain (paraphrased — no quote available because the refusal branch at `:1248-1271` spans several `echo` lines; `rg -n unknown` shows `if [ -n "$unknown" ]` at `:1268`). Precise version: "install.sh's agent gate, which install-host.bats runs, refuses when the /proc scan cannot read the working directory of a live process of the user outside install.sh's own lineage."

**Evidence:** `devcontainer-config/install.sh:1150-1182`, `devcontainer-config/install.sh:1203-1227`, `devcontainer-config/install.sh:1248-1271`
**Legibility-target:** for-author

---

## Claim 7: "so other files' processes starting and ending beside it can make it refuse where a serial run would not"

**Location:** `scripts/run-tests.sh:93-94`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether ordinary process churn produces `unknown` lines. It does not establish that churn never can, and it does not cover concurrent processes whose working directory is unreadable while they run (non-dumpable processes such as setuid helpers or ssh-agent). Those processes do produce `unknown` lines, but no suite file was found starting one.

The code skips a process that exits during the scan: `[ -n "$cmd" ] || continue # exited, or a kernel thread` (`devcontainer-config/install.sh:1179`). In E-r3-3, the scan loop copied from `:1169-1181` found 0 `unknown` lines in 20 idle passes and 0 in 40 passes beside four loops that start and end processes continuously. So the stated trigger, processes "starting and ending", was not reproduced. What does make the scan list a process as `unknown` is a readable command line with an unreadable cwd, which is a property of the process, not of its churn (paraphrased — no quote available because this is kernel `/proc` access behaviour, not repo code). `rg -n "ssh-agent|sudo |PR_SET_DUMPABLE|setpriv" test -g '*.bats'` finds those names only in comments and strings, not in any command a suite runs. Verifying the claim needs install-host.bats run many times beside the full suite under `--jobs`, which the brief bars. Suggested precise version: "other files' processes run beside it, so any of them whose working directory cannot be read makes it refuse where a serial run would not".

**Evidence:** `devcontainer-config/install.sh:1169-1181`, fc-r3/E-r3-3-churn.log, fc-r3/scan.sh
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "bats runs files through GNU parallel and aborts without it even for one file"

**Location:** `scripts/run-tests.sh:95-96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bats 1.8.2 aborting when no `parallel` is on PATH and `--jobs` is not 1, one file included. It does not establish that bats checks for *GNU* parallel: it checks only that some `parallel` is present.

```bash
# /usr/libexec/bats-core/bats-exec-suite:99-102 (excerpt; the if block continues to :108 — read)
if [[ "$num_jobs" != 1 ]]; then
  if ! type -p parallel >/dev/null && [[ -z "$bats_no_parallelize_across_files" ]]; then
    abort "Cannot execute \"${num_jobs}\" jobs without GNU parallel"
    exit 1
```

E-r3-6: `bats --jobs 2 repo2/test/a.bats` on a PATH without `parallel` printed `Error: Cannot execute "2" jobs without GNU parallel` and exited 1.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-108`, fc-r3/E-r3-6-failed-parallel-and-abort.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9a: "so when the first `parallel` on PATH is missing or is not GNU parallel …, the runner warns and runs serially"

**Location:** `scripts/run-tests.sh:96-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two stated triggers. It does not establish that these are the only triggers: the check also fails for GNU parallel when `$PARALLEL` or a parallel config file holds an option `--version` rejects (see Claim 27).

```bash
# scripts/run-tests.sh:405-415 (the if block, complete)
if [[ "$jobs" -gt 1 ]]; then
  if [[ "$(parallel --version 2>/dev/null)" == "GNU parallel"* ]]; then
    unset PARALLEL
    if mkdir -p "$REPO_ROOT/.bats/parallel-home" 2>/dev/null; then
      export PARALLEL_HOME="$REPO_ROOT/.bats/parallel-home"
    fi
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
  else
    echo "WARNING: --jobs $jobs needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially" >&2
  fi
fi
```

E-r3-5: tests 28 (non-GNU first) and 29 (no parallel) pass on M0. The M4 mutant, which only checks that `parallel` is present, fails test 28.

**Evidence:** `scripts/run-tests.sh:405-415`, fc-r3/E-r3-5-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9b: "(moreutils ships one too)"

**Location:** `scripts/run-tests.sh:97`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing on this host. moreutils is not installed (`dpkg -l | grep -i moreutils` is empty), and the sandbox has no network egress. It does not establish the moreutils `parallel`'s `--version` output.

The test's fake stands in for it (`echo "parallel from moreutils"; exit 1`, `test/scripts/run-tests.bats:447`). Verifying the claim needs moreutils installed, or its package file list. Low stakes: this is a parenthetical example.

**Evidence:** `scripts/run-tests.sh:97`, `test/scripts/run-tests.bats:445-455`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "It unsets $PARALLEL and points $PARALLEL_HOME at .bats/parallel-home (left at the user's default when that cannot be created)"

**Location:** `scripts/run-tests.sh:97-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two environment edits and the fallback that leaves the user's `$PARALLEL_HOME` as it was. It does not establish what those edits achieve, which Claim 11 verdicts. It also does not establish when the unset happens: after the GNU probe, not before it (Claim 27).

Quoted in Claim 9a (`scripts/run-tests.sh:407-410`). E-r3-7 put a regular file at `.bats/parallel-home` and set `PARALLEL_HOME` to a directory whose `config` holds `--dry-run`. bats' `parallel` used that directory's config: it printed the `bats-exec-file …` command lines and `# bats warning: Executed 0 instead of expected 3 tests`. So the user's value was kept. Test 27 checks `[ -d "$T/.bats/parallel-home" ]`.

**Evidence:** `scripts/run-tests.sh:405-411`, `test/scripts/run-tests.bats:435-443`, fc-r3/E-r3-7-parallel-home-fallback.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "so the user's parallel options and config cannot change how bats' run behaves"

**Location:** `scripts/run-tests.sh:99-100`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU parallel 20221122's config lookup and its effect on a real `--jobs 2` run of the runner copy. It does not establish how widespread user configs are. This host has `~/.parallel/` with only `tmp/`, and no `~/.parallelrc` or `/etc/parallel`, so the repo's own runs are not affected today.

Setting `$PARALLEL_HOME` adds a config directory to parallel's search list. It replaces none of them:

```perl
# /usr/bin/parallel:2838-2847 (excerpt; the directory setup continues to :2862 — read)
    # config_dirs = $PARALLEL_HOME, $XDG_CONFIG_HOME/parallel,
    #	$(each XDG_CONFIG_DIRS)/parallel, $HOME/.parallel
    # Keep only dirs that exist
    @Global::config_dirs =
	(grep { -d $_ }
	 $ENV{'PARALLEL_HOME'},
	 (map { "$_/parallel" }
	  $xdg_config_home,
	  split /:/, $ENV{'XDG_CONFIG_DIRS'}),
	 $ENV{'HOME'} . "/.parallel");
```

```perl
# /usr/bin/parallel:3318-3323 (excerpt; read_options' profile loop continues to :3360 — read)
    if(not $opt::plain) {
	# Add options from $PARALLEL_HOME/config and other profiles
	my @config_profiles = (
	    "/etc/parallel/config",
	    (map { "$_/config" } @Global::config_dirs),
	    $ENV{'HOME'}."/.parallelrc");
```

Every existing profile is read (`for my $profile (@profiles) { if(-r $profile) { … push @ARGV_profile …`, `:3342-3350`). bats does not pass `--plain` (`bats-exec-suite:420`, quoted in Claim 2). In E-r3-1, `~/.parallel/config` and `~/.parallelrc` each containing `--dry-run` turned `run-tests.sh --jobs 2` into a run that executed no test. The output showed `bats-exec-file …` lines and `# bats warning: Executed 0 instead of expected 3 tests`, with exit 1 and 0 run-log result lines. With an empty HOME the same run passed 3 tests. `$PARALLEL` itself also reaches the run, through the GNU probe before the unset (E-r3-2: a GNU parallel install then falls back to serial). What holds: once the probe passes, `$PARALLEL` no longer reaches bats' `parallel` (test 27; M2 fails it). Fix: narrow the sentence to "$PARALLEL cannot change bats' parallel call". Alternatively, also neutralise the config files, for example by pointing `HOME`/`XDG_CONFIG_HOME` elsewhere for the `parallel` call only (bats offers no hook for this). Whether a user config with `-j1`, `--ungroup` or `--halt` is worth that is the author's call. `--dry-run` fails closed, because the test-count warning makes the run exit 1.

**Evidence:** `/usr/bin/parallel:2832-2862`, `/usr/bin/parallel:3310-3360`, `/usr/libexec/bats-core/bats-exec-suite:420`, `scripts/run-tests.sh:405-411`, fc-r3/E-r3-1-home-config.log, fc-r3/E-r3-2-parallel-env-check.log, fc-r3/E-r3-7-parallel-home-fallback.log
**Legibility-target:** for-author

---

## Claim 12: "bats keeps each file's output together (parallel groups output by default) and in file order (--keep-order), so a file's results appear once it and every file before it have ended."

**Location:** `scripts/run-tests.sh:101-103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers parallel's default grouping and the `--keep-order` flag that bats passes. It does not hold when a user config file adds `--ungroup` or `--line-buffer`: Claim 11 shows such a file still reaches this call.

`--keep-order` appears in `bats-exec-suite:420` (quoted in Claim 2). Grouping is the default unless `-u`/`--line-buffer` is set (`"group[Group output]" => \$opt::group` and the `ungroup`/`linebuffer` options at `/usr/bin/parallel:1744-1755`, and `if(not $opt::ungroup)` at `:3713`). Pass 1's E2 (unchanged bats and parallel) showed each file's lines arriving as one block, in file order, once the earlier files had ended (E2b: `ok 1 b1` at +0.08 s, then `ok 2 a1` through `ok 4 a3` together at +3.1 s).

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, `/usr/bin/parallel:1744-1755`, `/usr/bin/parallel:3713`, docs/reviews/execution-logs/q090-fc-k1-E2-grouping-order-within-file.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "Every test still writes its own run-log line, so the run log, the test-count check and --failed work as in a serial run."

**Location:** `scripts/run-tests.sh:103-105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers complete logs after parallel runs and `--failed` re-running from them, including a `--failed` run that itself goes through parallel. It does not establish log completeness under within-file parallelism, which the runner never uses.

E-r3-5 M0: tests 22 (the log after `--jobs 2` holds 4 result lines, and `expected=4`) and 23 (killed run refused) pass. E-r3-6: after `--jobs 2` with failures in two files, `--failed --jobs 2` passed the completeness check (`scripts/run-tests.sh:250-260`), re-ran `a2` and `b2` through `parallel --keep-order --jobs 2 …`, and printed `1..2`.

**Evidence:** `scripts/run-tests.sh:238-262`, `test/scripts/run-tests.bats:379-414`, fc-r3/E-r3-5-mutants.log, fc-r3/E-r3-6-failed-parallel-and-abort.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "bats folds parallel's stderr into its output; the locale pin above keeps perl's setlocale warnings out of it, and upstream parallel prints its citation notice only when its stderr is a terminal, which inside bats it never is (Debian's build never prints it)."

**Location:** `scripts/run-tests.sh:105-108`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `2>&1`, the tty condition in the function, and the call commented out in the Debian build. It does not establish upstream's call site, whose non-Debian source is not on this host, and it does not establish that test 25 exercises the parallel path (Claim 25).

`… ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1` (`bats-exec-suite:420`). The Debian build has the call commented out: `#    citation_notice();` (`/usr/bin/parallel:2578`). The function itself skips when stderr is not a tty: `not -t $Global::original_stderr` (`/usr/bin/parallel:5639`, inside `sub citation_notice() {` at `:5632`). E-r3-5 M0: test 25 passes, including `! grep -iE 'perl|setlocale|cite|citation'`.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, `/usr/bin/parallel:2570-2582`, `/usr/bin/parallel:5632-5645`, fc-r3/E-r3-5-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "At most 3 digits, so the value never overflows bash arithmetic and parallel never sizes thousands of job slots."

**Location:** `scripts/run-tests.sh:136-137`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex bound (at most 999) and the lowering to the file count that follows it. It does not establish parallel's slot-probe cost at N ≤ 999, which was not measured.

`^[1-9][0-9]{0,2}$` (`:138`, quoted in Claim 1) admits at most 999. `(( jobs > ${#files[@]} ))` (`:404`) then compares at most three digits, and the lowered value (at most the file count, 124 here) is what bats receives. E-r3-4 rejected `1000` and `$'5\n'`: bash `=~` anchors `$` at the end of the string, so a trailing newline is rejected.

**Evidence:** `scripts/run-tests.sh:136-145`, `scripts/run-tests.sh:404`, fc-r3/E-r3-4-jobs-parsing.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "Test for GNU parallel itself, not the file count: bats aborts without it whenever N > 1."

**Location:** `scripts/run-tests.sh:401-402`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how the comment relates to the line directly under it. It does not dispute the bats half ("aborts … whenever N > 1"), which Claim 8 verifies.

The comment dates from 088bc97, where no file count was involved (`# count: bats aborts without it whenever N > 1.` over `if [[ "$jobs" -gt 1 ]]; then`, `git show 088bc97:scripts/run-tests.sh:388-390`). 084868f then added the lowering step right below it:

```bash
# scripts/run-tests.sh:404-405 (excerpt; the if block continues to :415 — read)
(( jobs > ${#files[@]} )) && jobs=${#files[@]}
if [[ "$jobs" -gt 1 ]]; then
```

The file count now decides whether the GNU check runs at all: a one-file `--jobs N` run never reaches it, and it prints no warning even with no `parallel` installed (E-r3-4: `--jobs 2 test/a.bats` made no shim call). Precise version: "N is first lowered to the file count, so a one-file run never needs parallel; for N > 1, test for GNU parallel itself, because bats aborts without it."

**Evidence:** `scripts/run-tests.sh:401-415`, `git show 088bc97:scripts/run-tests.sh` lines 388-391, fc-r3/E-r3-4-jobs-parsing.log
**Legibility-target:** for-author

---

## Claim 17: "bats runs the first `parallel` on PATH, so that is the one checked."

**Location:** `scripts/run-tests.sh:402-403`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers PATH resolution: bats puts its libexec directory, which holds no `parallel`, in front of the runner's PATH, and runs the bare name. It does not establish that the check sees `parallel` in the same environment bats will. The probe runs before `unset PARALLEL` and before `PARALLEL_HOME` is set, so `$PARALLEL` or a config file can fail the check for a GNU parallel (Claim 27).

`export PATH="$BATS_LIBEXEC:$PATH"` (`/usr/libexec/bats-core/bats:101`). The libexec directory holds `bats bats-exec-file bats-exec-suite bats-exec-test bats-format-* bats-preprocess` and no `parallel` (paraphrased — no quote available because this is a directory listing, `ls /usr/libexec/bats-core`). The call is the bare `parallel --keep-order …` (`bats-exec-suite:420`). The runner's probe is the bare `parallel --version` (`scripts/run-tests.sh:406`). The shim tests show the two resolve to the same file: E-r3-4's shim logged both the `--version` probe and bats' call.

**Evidence:** `/usr/libexec/bats-core/bats:101`, `/usr/libexec/bats-core/bats-exec-suite:420`, `scripts/run-tests.sh:406`, fc-r3/E-r3-4-jobs-parsing.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "parallel_shim: put a `parallel` first on PATH that logs its arguments to $T/parallel.args and execs the real one, so a test can see bats used it."

**Location:** `test/scripts/run-tests.bats:329-330`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `$T/parallel.args` holds since 084868f. It does not dispute the shim's mechanics, which log and then exec the real binary.

084868f added the runner's own `parallel --version` probe (`scripts/run-tests.sh:406`), which goes through the same shim. `parallel.args` therefore exists whenever the probe ran, whether or not bats used `parallel`. E-r3-4's shim log begins `--version`, followed by bats' `--keep-order --jobs 2 …` line. A test that asserts only `[ -f "$T/parallel.args" ]` no longer shows bats used `parallel` (Claim 25). Precise version: "…logs each call's arguments (the runner's `--version` probe too) to $T/parallel.args; grep for `--no-parallelize-within-files` to see that bats used it."

**Evidence:** `test/scripts/run-tests.bats:329-340`, `scripts/run-tests.sh:406`, fc-r3/E-r3-4-jobs-parsing.log, fc-r3/E-r3-5-mutants.log
**Legibility-target:** for-author

---

## Claim 19: test "--jobs: a missing, zero, non-numeric or 4-digit N is a usage error"

**Location:** `test/scripts/run-tests.bats:342-356`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test asserts exit 2 and the message for each of the four named classes, and that no test ran for `1000`. It does not cover leading zeros or signs, which E-r3-4 probed instead.

The test asserts `runner --jobs` / `0` / `x` / `1000`, each with `[ "$status" -eq 2 ]` and the `got: …` text (paraphrased — no quote available because the test's 4 × 3 assertion lines at `:343-355` repeat one pattern). E-r3-5 M0: `ok 20`.

**Evidence:** `test/scripts/run-tests.bats:342-356`, fc-r3/E-r3-5-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: test "--jobs 2 runs files through parallel, not tests within a file"

**Location:** `test/scripts/run-tests.bats:358-369`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that bats' `parallel` call carried `--jobs 2` and `--no-parallelize-within-files`. It does not observe serial execution within a file directly: this is the proxy accepted in the override log (row 172), not re-raised.

`grep -q -- '--jobs 2' "$T/parallel.args"` and `grep -q -- '--no-parallelize-within-files' "$T/parallel.args"` (`:367-368`). The `--version` probe line matches neither, so both greps need bats' own call. E-r3-5: M1 and M5 (both of which always run serially) fail it.

**Evidence:** `test/scripts/run-tests.bats:358-369`, fc-r3/E-r3-5-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: test "--jobs 1 runs serially and needs no parallel"

**Location:** `test/scripts/run-tests.bats:371-377`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that with `--jobs 1` no `parallel` call happens at all (neither the probe nor bats'). It does not separate `--jobs 1` from lowering: with one file, `--jobs 2` would also make no call (E-r3-4).

`[ ! -f "$T/parallel.args" ]` (`:376`) with the shim first on PATH. M0 `ok 22`.

**Evidence:** `test/scripts/run-tests.bats:371-377`, fc-r3/E-r3-5-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: test "--jobs: a parallel run records a complete log that --failed re-runs from"

**Location:** `test/scripts/run-tests.bats:379-398`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first run, which goes through parallel (3 files, N = 2), writing a complete log that `--failed` accepts. It does not cover `--failed` itself going through parallel. Since 084868f the `runner --failed --jobs 2` leg re-runs only alpha.bats, so N is lowered to 1 and it runs serially. No test now exercises `--failed` together with a parallel re-run (E-r3-6 shows that path works).

```bash
# test/scripts/run-tests.bats:388-392 (excerpt; the test continues to :398 — read)
  touch "$T/fixed"
  runner --failed --jobs 2
  [ "$status" -eq 0 ]
  [[ "$output" == *"1..1"* ]]
  [[ "$output" == *"ok 1 alpha flaky"* ]]
```

M0 `ok 23`.

**Evidence:** `test/scripts/run-tests.bats:379-398`, `scripts/run-tests.sh:404`, fc-r3/E-r3-5-mutants.log, fc-r3/E-r3-6-failed-parallel-and-abort.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: test "--jobs: a parallel run killed partway is refused by --failed"

**Location:** `test/scripts/run-tests.bats:400-414`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a two-file (hence truly parallel) run killed by TERM (rc 143) followed by the `--failed` refusal. It does not assert that the shim saw bats' call.

`runner_bg … --jobs 2 test/slow.bats test/gamma.bats` then `[ "$rc" -eq 143 ]` and the `recorded … of 4 tests: it did not complete` refusal (paraphrased — no quote available because the assertions are spread across `:403-413` with the background helpers). M0 `ok 24`.

**Evidence:** `test/scripts/run-tests.bats:400-414`, fc-r3/E-r3-5-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: test "--jobs above the file count is lowered to it"

**Location:** `test/scripts/run-tests.bats:428-433`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the value bats hands `parallel` for `--jobs 999` with 2 files. It does not cover lowering after `--failed` narrowing.

`grep -q -- '--jobs 2 ' "$T/parallel.args"` (`:432`). E-r3-5: M3 (no lowering) fails only this test, and M1 and M5 fail it too.

**Evidence:** `test/scripts/run-tests.bats:428-433`, fc-r3/E-r3-5-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: test "--jobs: an uninstalled locale leaves no perl or citation text in the output" (with `[ -f "$T/parallel.args" ]` and the comment "gamma asserts its own subprocess output is clean; the suite-level output must be clean too.")

**Location:** `test/scripts/run-tests.bats:416-426`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts: the pin message, gamma ok, and no perl or citation text. It does not establish that the output went through bats' `parallel`, which the `--jobs:` name and the `parallel.args` check imply.

```bash
# test/scripts/run-tests.bats:417-421 (excerpt; the test continues to :426 — read)
  parallel_shim
  in_runner LANG=xx_XX.UTF-8 -- --jobs 2
  [ "$status" -eq 1 ]
  [[ "$output" == *"Locale xx_XX.UTF-8 is not installed"* ]]
  [ -f "$T/parallel.args" ]
```

The runner's `parallel --version` probe alone creates `parallel.args` (Claim 18). E-r3-5 mutant M5 changes the compare so that the probe still runs but every run falls back to serial. Under M5, tests 21, 26 and 27 fail, and this test **passes**. So it no longer tells a parallel run from a serial fallback. Pass 1 found it discriminating at 088bc97, before the probe existed. Fix: assert `grep -q -- '--no-parallelize-within-files' "$T/parallel.args"` in place of `[ -f … ]`.

**Evidence:** `test/scripts/run-tests.bats:416-426`, `scripts/run-tests.sh:406`, fc-r3/E-r3-5-mutants.log (M5 section), fc-r3/mut-M5.diff
**Legibility-target:** for-author

---

## Claim 26: test "--jobs: the user's PARALLEL options do not reach bats' parallel" and comment "--dry-run would run no test at all."

**Location:** `test/scripts/run-tests.bats:435-443`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `$PARALLEL` environment variable once the GNU probe has passed. It does not cover parallel's config files (Claim 11), nor `$PARALLEL` values that break the probe itself (Claim 27).

`in_runner LC_ALL="$WORKING_LOCALE" PARALLEL=--dry-run -- --jobs 2` with `1..4`, `beta steady` ok, and `[ -d "$T/.bats/parallel-home" ]` (`:438-442`). The directory exists only if the GNU branch was taken. E-r3-5: M2 (no `unset PARALLEL`) fails only this test. E-r3-1 confirms the comment: under `--dry-run` from a config file, bats reports `Executed 0 instead of expected 3 tests`.

**Evidence:** `test/scripts/run-tests.bats:435-443`, fc-r3/E-r3-5-mutants.log, fc-r3/E-r3-1-home-config.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: warning "--jobs $jobs needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially"

**Location:** `scripts/run-tests.sh:413`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the causes that trigger the warning. It does not establish how likely the third cause is in practice.

The probe `"$(parallel --version 2>/dev/null)"` (`:406`) runs before `unset PARALLEL` (`:407`) and reads the user's config files (Claim 11). In E-r3-2, `PARALLEL=--no-such-option parallel --version` printed `Unknown option: no-such-option` and usage. The runner under `PARALLEL=--no-such-option --jobs 2` then printed this warning and ran serially, although `/usr/bin/parallel` is GNU parallel 20221122. The warning names two causes. A third exists: GNU parallel is first on PATH, but `$PARALLEL` or a parallel config file makes `--version` fail. Precise version: add "(or `parallel --version` failed)". An alternative is to run the probe with `PARALLEL` unset and `--plain`, which skips profiles (`if(not $opt::plain)`, `/usr/bin/parallel:3318`), so the probe tests the binary only.

**Evidence:** `scripts/run-tests.sh:405-415`, `/usr/bin/parallel:3318-3323`, fc-r3/E-r3-2-parallel-env-check.log
**Legibility-target:** for-author

---

## Claim 28: tests "--jobs with a non-GNU parallel first on PATH warns and runs serially" and "--jobs without GNU parallel on PATH warns and runs serially" (with the comment "A PATH holding everything the current one does except parallel (and bats' libexec directory, which in_runner drops too).")

**Location:** `test/scripts/run-tests.bats:445-479`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both fallback triggers and the PATH the second test builds. It does not cover the probe-failure cause (Claim 27).

The second test's loop skips `"$dir" != "$BATS_LIBEXEC"` and `"${f##*/}" != parallel` (`:463-467`), matching the comment. `bash -c 'command -v parallel || bash "$1" …'` guards against a `parallel` left on PATH. E-r3-5: M0 passes both. M4 (presence-only check) fails the non-GNU test.

**Evidence:** `test/scripts/run-tests.bats:445-479`, fc-r3/E-r3-5-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29: 084868f body: header bullet ("the within-file example is now health-check.bats' setup_file cache; install-host.bats' /proc scan is stated as a cross-file exposure …; Output grouping is parallel's default --group, ordering is --keep-order; the citation notice sentence now says Debian's build never prints it"), the fallback-test comment bullet, and "N above the selected file count is lowered to it"

**Location:** commit `084868f` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each described edit is present in the diff. It does not rule on the accuracy of the new text, which Claims 3, 6-7, 12, 14 and 28 verdict separately.

`git show 084868f -- scripts/run-tests.sh test/scripts/run-tests.bats` contains each edit: the header lines now at `scripts/run-tests.sh:85-108`, the lowering at `:404`, and the comment at `test/scripts/run-tests.bats:458-459` (paraphrased — no quote available because the claim covers a multi-hunk diff whose resulting text is quoted in the claims named in Scope).

**Evidence:** `scripts/run-tests.sh:85-108`, `scripts/run-tests.sh:404`, `test/scripts/run-tests.bats:458-459`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: 084868f: "--jobs takes 1 to 999 (was any digit string, which could overflow bash arithmetic and make parallel fork thousands of slot probes that keep the run lock after a TERM; security F1, api-consistency F3)"

**Location:** commit `084868f` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the new bound (Claim 1) and that the cited reports record the old hazard. It does not re-execute the N=20000 orphan probe.

The old regex was `^[1-9][0-9]*$` (security review boundary B1: `[regex ^[1-9][0-9]*$ at run-tests.sh:125]`, `docs/reviews/q090-security-review-2026-09-30.md:29`). The security review records P4: "`--jobs 20000` … 3 s later `parallel` is alive (ppid 1, 102% CPU), 662 `sleep 10101` dummies, the run lock is held" (`docs/reviews/q090-security-review-2026-09-30.md:19`).

**Evidence:** `scripts/run-tests.sh:138`, `docs/reviews/q090-security-review-2026-09-30.md:19`, `docs/reviews/q090-security-review-2026-09-30.md:29`, `docs/reviews/q090-security-review-2026-09-30.md:55-98`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 31a: 084868f: "The fallback now checks that the first `parallel` on PATH is GNU parallel (`parallel --version`), not just present (api-consistency F5)."

**Location:** commit `084868f` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the check tests. It does not establish that a failing check means the binary is not GNU parallel.

The check tests that `parallel --version`, run under the user's `$PARALLEL` and config files, prints output beginning "GNU parallel". A GNU parallel whose `$PARALLEL` it rejects fails the check (E-r3-2, Claim 27). Precise version: "…checks `parallel --version` reports GNU parallel".

**Evidence:** `scripts/run-tests.sh:406`, fc-r3/E-r3-2-parallel-env-check.log
**Legibility-target:** for-author

---

## Claim 31b: 084868f: "$PARALLEL is unset and $PARALLEL_HOME points at .bats/parallel-home, so the user's parallel options or config cannot alter bats' run (security F2)."

**Location:** commit `084868f` message
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same mechanism and evidence as Claim 11. It does not establish that security F2's severity (Info, fails closed) changes: `--dry-run` from a config file still makes the run exit 1.

`$HOME/.parallel/config`, `$XDG_CONFIG_HOME/parallel/config`, `/etc/parallel/config` and `~/.parallelrc` are still read (`/usr/bin/parallel:2841-2847`, `:3320-3323`, quoted in Claim 11). E-r3-1 reproduces a user config changing bats' run. Branch history is not rewritten here. If Claim 11 is fixed, a correction belongs in the fix commit's body, following the 088bc97 precedent (override-log row 173).

**Evidence:** `/usr/bin/parallel:2832-2862`, `/usr/bin/parallel:3310-3360`, fc-r3/E-r3-1-home-config.log
**Legibility-target:** for-author

---

## Claim 32: 084868f: "Tests: 4-digit N rejected, N lowered to the file count, PARALLEL=--dry-run ignored, a non-GNU parallel falls back serially …. The clamp and PARALLEL tests were mutation-checked." and Notes "PARALLEL_HOME under .bats/ (gitignored) …; when .bats/ is unwritable it is left at the user's default. The 999 cap is arbitrary but far above any useful N on this host (16 cores, 124 files)."

**Location:** commit `084868f` message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four tests' existence, the two mutation claims, the gitignore, the unwritable fallback and the two host counts. It does not establish the "PARALLEL=--dry-run ignored" test's reach beyond the environment variable (Claim 26).

Tests 20, 26, 27 and 28 exist (`test/scripts/run-tests.bats:342`, `:428`, `:435`, `:445`). E-r3-5: M3 (no lowering) fails test 26, and M2 (no `unset PARALLEL`) fails test 27. `git check-ignore -v .bats/parallel-home` → `.gitignore:43:.bats/`. With `.bats/parallel-home` unusable, `PARALLEL_HOME` was left as the user set it (E-r3-7). `nproc` → `16`, and `rg --files -g '*.bats' test | wc -l` → `124`.

**Evidence:** `test/scripts/run-tests.bats:342-455`, `.gitignore:43`, `scripts/run-tests.sh:408-410`, fc-r3/E-r3-5-mutants.log, fc-r3/E-r3-7-parallel-home-fallback.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 33: f733a51: "the header said the runner always points $PARALLEL_HOME at .bats/parallel-home; it does only when that directory can be created."

**Location:** commit `f733a51` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the conditional export and the header's new parenthetical. It does not cover the header's "so …" conclusion (Claim 11).

`if mkdir -p "$REPO_ROOT/.bats/parallel-home" 2>/dev/null; then export PARALLEL_HOME=…` (`scripts/run-tests.sh:408-410`). The header now reads "(left at the user's default when that cannot be created)" (`:98-99`). E-r3-7 exercised the not-created path.

**Evidence:** `scripts/run-tests.sh:97-100`, `scripts/run-tests.sh:408-410`, fc-r3/E-r3-7-parallel-home-fallback.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 34: 088bc97 body: "so the check is `command -v parallel`, not the file count. N must be a positive integer (else exit 2)."

**Location:** commit `088bc97` message
**Type:** Staleness
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only that HEAD no longer matches these lines. They were accurate at 088bc97 (`git show 088bc97:scripts/run-tests.sh:390-391` has `if command -v parallel > /dev/null; then`), and 084868f superseded them. The Stale verdict is not used because history is immutable. Recorded Unverifiable-as-current, for the orchestrator only.

At HEAD the check is `parallel --version` (`scripts/run-tests.sh:406`), and N is 1–999 (`:138`). 084868f's body documents both changes. No action: this is the same accepted-immutable disposition as override-log row 173.

**Evidence:** `scripts/run-tests.sh:138`, `scripts/run-tests.sh:406`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (`scripts/run-tests.sh:99-100`): the user's parallel config still reaches bats' `parallel`. `$PARALLEL_HOME` adds to the config search list and does not replace it: `~/.parallel/config`, `$XDG_CONFIG_HOME/parallel/config`, `/etc/parallel/config` and `~/.parallelrc` are all still read, and E-r3-1 shows a `--dry-run` in either of the first or last turning a run into zero tests executed. `$PARALLEL` also reaches the GNU probe. Narrow the sentence to `$PARALLEL` after the probe, or neutralise the config files for the `parallel` call.
- **Claim 31b** (commit 084868f): the same claim in the commit body ("options or config cannot alter bats' run"). History is immutable; correct it in the fix commit.

### Stale
- **Claim 16** (`scripts/run-tests.sh:401-402`): "Test for GNU parallel itself, not the file count" predates the lowering at `:404`. The file count now decides whether the check runs.
- **Claim 18** (`test/scripts/run-tests.bats:329-330`): `parallel.args` also logs the runner's `--version` probe, so the file's existence no longer shows bats used `parallel`.

### Mostly Accurate
- **Claim 3** (`scripts/run-tests.sh:87-89`): the health-check.bats cache is real shared state but read-only after `setup_file`, so it is not state that running a file's tests in parallel would break.
- **Claim 6** (`scripts/run-tests.sh:90-93`): `agent_gate` refuses, not `procs_in_checkout`. Lineage and processes with an empty command line are exempt.
- **Claim 25** (`test/scripts/run-tests.bats:416-426`): the locale test passes when the runner always falls back to serial (mutant M5). Its `[ -f parallel.args ]` is satisfied by the probe. Grep for `--no-parallelize-within-files` instead.
- **Claim 27** (`scripts/run-tests.sh:413`): the warning also fires for GNU parallel when `$PARALLEL` or a config file makes `--version` fail (E-r3-2). Name that cause, or probe with `PARALLEL` unset and `--plain`.
- **Claim 31a** (commit 084868f): the check tests `parallel --version` output under the user's options, not the binary alone.

### Unverifiable
- **Claim 5** (`scripts/run-tests.sh:90`): "N above the core count buys nothing". No measurement above 16 jobs, and a full-suite run is barred.
- **Claim 7** (`scripts/run-tests.sh:93-94`): "processes starting and ending … can make it refuse". Churn alone produced 0 `unknown` lines in 40 scans, and exiting processes are skipped at install.sh:1179. The real exposure is concurrent processes with an unreadable cwd. Confirming needs install-host.bats run repeatedly beside the full suite under `--jobs`.
- **Claim 9b** (`scripts/run-tests.sh:97`): "moreutils ships one too". Needs moreutils or its file list; there is no network.
- **Claim 34** (commit 088bc97): superseded by 084868f. Immutable history, no action.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path named below, structured per the skill.
- Answered: yes. All five priority groups were verdicted: 36 claims (Claims 9 and 31 split into a/b), 27 of them by execution (7 probes, including 6 mutants of run-tests.bats).
- Out of scope: running install-host.bats or the full suite under `--jobs` (barred by the brief); upstream (non-Debian) parallel; moreutils.
- Escalate: Claim 11 / 31b, new evidence not covered by any override-log row. Security F2's fix does not keep user parallel config out of bats' run. Also Claim 25: the locale test lost its parallel-path check when 084868f added the `--version` probe. Also note Claim 22's residue: since the lowering step, no test runs `--failed` through `parallel`. E-r3-6 shows the path works, but the rubric's "Confirmed Good: --failed with --jobs" now has no test behind it.
- Decisions I made: kept the execution logs in the session scratchpad (`…/scratchpad/run-tests-jobs/fc-r3/`) and did not add them to `docs/reviews/execution-logs/`, because the brief says to edit no file except this report. Verdicted the 088bc97 body as Unverifiable-as-current rather than Stale to match the override log's accepted-immutable disposition. Split Claim 9 and Claim 31 because their parts earn different verdicts.
