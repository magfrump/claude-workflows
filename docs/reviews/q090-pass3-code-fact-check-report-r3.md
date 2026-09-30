# Code Fact-Check Report

**Commit:** ff99d86
**Replication:** r3 (final confirming pass 3)
**Repository:** /workspace/.claude/wt-run-tests-jobs (branch feat/run-tests-jobs)
**Scope:** `git diff main...HEAD -- scripts test` (scripts/run-tests.sh: the `--jobs` Flags entry, the "Parallel runs" header paragraph, the `--jobs` parsing comment, the comment block and code above `exec bats`; test/scripts/run-tests.bats: header, `parallel_shim`, the 11 `--jobs` tests) plus the commit message of 78b3b08. HEAD ff99d86 only adds the pass-2 rubric row on top of 78b3b08 (`scripts/` and `test/` are identical). Earlier commits' bodies are settled (override-log rows dated 2026-09-30) and are not re-verdicted. Claims were checked against the code that runs them: bats 1.8.2 libexec (`/usr/libexec/bats-core/{bats,bats-exec-suite,bats-exec-file}`, `/usr/lib/bats-core/validator.bash`), GNU parallel 20221122 Debian build (`/usr/bin/parallel`), `devcontainer-config/install.sh` (`procs_in_checkout`, `agent_gate`) and `test/scripts/health-check.bats`.
**Checked:** 2026-09-30
**Total claims checked:** 35
**Summary:** 31 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution logs live under `/tmp/claude-1000/-workspace/21797f19-046e-4351-9c55-0471f4b3d3b6/scratchpad/run-tests-jobs/fc-p3r3/` (written as `SCR/` below; every Evidence line names the full file). All probes ran with `LC_ALL=C.UTF-8`, under `timeout`, on copies of the script in scratch layouts. Nothing ran `scripts/run-tests.sh` against the real suite, except invalid `--jobs` values, which exit 2 while the flags are parsed (E4). No probe process was left running: each probe was a foreground command bounded by `timeout`, and the only background process, T92's sleeper, is killed by the test itself.

- E1 `SCR/E1-suite-and-mutants.log`: the unmutated `bats test/scripts/run-tests.bats`, 30/30 ok (cwd `SCR/orig`, exit 0, 2026-09-30T22:06:05Z). Its mutant section used a bad `-f` argument and is superseded by E2.
- E2 `SCR/E2-mutants.log`: mutants mA (`unset PARALLEL` moved into the success branch after the check, `--plain` kept), mA2 (unset after the check and no `--plain`, i.e. 084868f's shape without PARALLEL_HOME), mB (`--plain` dropped) and mC (bats never given `--jobs`), each run as `timeout 300 bats -f 'jobs' test/scripts/run-tests.bats` (2026-09-30T22:06:17Z–22:06:33Z).
- E3 `SCR/E3-unset-removed-mutant.log`: mD (`unset PARALLEL` disabled, `--plain` kept).
- E4 `SCR/E4-jobs-values.log`: exit codes for invalid `--jobs` values (cwd the worktree).
- E5 `SCR/E5-config-fail-closed.log`: a fixture layout run under a HOME whose `~/.parallel/config` is `--no-such-option` (V1), or whose `~/.parallelrc` is `--dry-run` (V2), then `--failed`.
- E6 `SCR/E6-config-retries.log`: a `--retries 2` config.
- E7 `SCR/E7-noparallel-onefile-order-citation.log`: bats with no `parallel`, a one-file runner run with no `parallel`, output timing, and the citation text.
- E8 `SCR/E8-agent-gate-T92.log`: `bats -f T92 test/install-host.bats`.
- E9 `SCR/E9-config-ungroup-and-fake-parallel.log`: a `--ungroup` config, and bats with a non-GNU `parallel` first on PATH.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read. None of the verdicts below matches a logged fabricated-symbol pattern. The Incorrect (Claim 33a) is closest in kind to the logged "tests pass / suite count" commit-message claims: a claim about test coverage that the named check does not bear out. It is not a fabricated symbol, so it is not appended there (this pass may edit only its own report anyway).

---

## Claim 1: "--jobs N  Run up to N test files at once (see "Parallel runs"). N is 1 to 999, digits only, no leading zero; anything else is a usage error (exit 2). 1, the default, runs serially; N above the number of selected files is lowered to it. Combines with every other flag, --failed included."

**Location:** `scripts/run-tests.sh:36-40`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the accepted range, the rejected forms and their exit code, the default, lowering, and `--failed --jobs 2`. It does not establish `--jobs` combined with each category flag by execution (static only: the category and `--jobs` code paths share no state), and it does not cover a repeated `--jobs`, where the last one wins.

```bash
# scripts/run-tests.sh:136-146
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

`jobs=1` is the default (`scripts/run-tests.sh:127`), and lowering is `(( jobs > ${#files[@]} )) && jobs=${#files[@]}` (`:406`). E4: each of `''`, `0`, `007`, `1000`, `+5`, `' 5'`, `$'5\n'`, `-1`, `5x`, `٥`, `1e3` and a bare `--jobs` exits 2 (command `timeout 10 bash scripts/run-tests.sh --jobs <v>`, cwd the worktree, 2026-09-30T22:07:19Z). The regex accepts 1, 9, 10, 99, 100 and 999. E1: tests 20 (usage errors), 23 (`--failed --jobs 2` stays parallel) and 26 (999 lowered to 2) pass.

**Evidence:** `scripts/run-tests.sh:36-40`, `scripts/run-tests.sh:127`, `scripts/run-tests.sh:136-146`, `scripts/run-tests.sh:406`; `SCR/E4-jobs-values.log`, `SCR/E1-suite-and-mutants.log`

---

## Claim 2: "Parallel runs: --jobs N (N > 1) hands bats `--jobs N --no-parallelize-within-files`, so whole files run side by side and the tests within a file stay serial, the only way the suites have ever run"

**Location:** `scripts/run-tests.sh:85-88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the flags handed to bats (with the lowered N, and only when the GNU check passes, as the header says next), bats running files through `parallel` and each file's tests in its serial loop, and the absence of any earlier `--jobs` or `BATS_NUMBER_OF_PARALLEL_JOBS` use in the repo's runners. It does not establish the "no suite has been checked for interference" half, which is review history rather than code. It also does not cover a user-exported `BATS_NO_PARALLELIZE_ACROSS_FILES`, which the runner does not clear and which would make bats run the files one after another.

```bash
# scripts/run-tests.sh:407-414
if [[ "$jobs" -gt 1 ]]; then
  unset PARALLEL
  if [[ "$(parallel --plain --version 2>/dev/null)" == "GNU parallel"* ]]; then
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
  else
    echo "WARNING: --jobs $jobs needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially" >&2
  fi
fi
```

```bash
# /usr/libexec/bats-core/bats-exec-file:294-296 (excerpt; bats_run_tests continues with the serial loop — read)
  if [[ "$num_jobs" != 1 && "${BATS_NO_PARALLELIZE_WITHIN_FILE-False}" == False ]]; then
    export BATS_SEMAPHORE_NUMBER_OF_SLOTS="$num_jobs"
    bats_run_tests_in_parallel "$BATS_RUN_TMPDIR/parallel_output" || bats_exec_file_status=1
```

`--no-parallelize-within-files` sets `BATS_NO_PARALLELIZE_WITHIN_FILE=1` (`bats-exec-file:24-27`), so the serial branch runs. `git grep -nE "(bats .*(--jobs|-j ))|BATS_NUMBER_OF_PARALLEL_JOBS|BATS_NO_PARALLELIZE" main -- scripts test hooks .github Makefile` returns nothing. E7: with x.bats (two 1 s tests) and y.bats, `bats --jobs 2 --no-parallelize-within-files` finishes in about 2.1 s, which is x.bats' serial time. E2 mC (no `--jobs` to bats) fails tests 21, 23 and 25–28.

**Evidence:** `scripts/run-tests.sh:85-88`, `scripts/run-tests.sh:407-414`, `/usr/libexec/bats-core/bats-exec-file:24-27`, `/usr/libexec/bats-core/bats-exec-file:287-300`, `/usr/libexec/bats-core/bats-exec-suite:415-421`; `SCR/E7-noparallel-onefile-order-citation.log`, `SCR/E2-mutants.log`

---

## Claim 3: "The slowest file bounds the speedup."

**Location:** `scripts/run-tests.sh:88-89`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lower bound on wall time that comes from a file being the smallest unit `parallel` schedules. It does not establish which file is slowest, or that no other bound (CPU or I/O contention) is tighter.

`parallel --keep-order --jobs "$num_jobs" bats-exec-file … ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}"` (`/usr/libexec/bats-core/bats-exec-suite:420`): one job per file. Within a file the tests run in bats-exec-file's serial loop (Claim 2), so no run can finish before its longest file does.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:415-421`

---

## Claim 4: "Files still share the machine: install.sh's agent_gate, which install-host.bats runs, refuses when procs_in_checkout cannot read the working directory of a live process of the user (a non-dumpable one, say), and under --jobs other files' processes are live beside it."

**Location:** `scripts/run-tests.sh:89-93`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `procs_in_checkout` tagging a same-uid process with an unreadable cwd as `unknown`, `agent_gate` refusing on any `unknown` entry, install-host.bats running the real scan (only pgrep and docker are stubbed), and T92 passing here. It does not establish that any file in this suite actually spawns a non-dumpable process, and it does not cover kernels on which a non-dumpable process's `/proc/<pid>` fails `[ -O ]`, where the scan would skip that process rather than refuse on it.

```bash
# devcontainer-config/install.sh:1168-1178 (excerpt; procs_in_checkout continues to :1182 — read)
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

`if [ -z "$procs" ] && [ -z "$inrepo" ] && [ -z "$unknown" ] && [ -z "$ctrs" ]; then return 0; fi` (`install.sh:1248`) is followed by the refusal and `exit 1` (`:1249-1282`). In install-host.bats, `stub_pgrep 'exit 1'` and `stub_docker 'exit 0'` (`test/install-host.bats:41-42`) leave `procs_in_checkout` real. `in_lineage` exempts only install.sh's own ancestors and descendants, so sibling bats files' processes are scanned. E8: `timeout 120 bats -f 'T92' test/install-host.bats` (cwd the worktree, exit 0, 2026-09-30T22:08:32Z) prints `ok 1 T92 a same-uid process that hides its cwd (non-dumpable) is refused and named`.

**Evidence:** `devcontainer-config/install.sh:1150-1182`, `devcontainer-config/install.sh:1187-1282`, `test/install-host.bats:34-43`, `test/install-host.bats:1594-1610`; `SCR/E8-agent-gate-T92.log`

---

## Claim 5: "bats runs files through GNU parallel and aborts without it even for one file"

**Location:** `scripts/run-tests.sh:94-95`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers bats 1.8.2 aborting when no `parallel` is on PATH and `--jobs` is not 1, a one-file run included. It does not establish that bats checks for *GNU* parallel. It checks only that some `parallel` is present: with a non-GNU one first it does not abort but runs it and fails (E9: `Executed 0 instead of expected 3 tests`, exit 1), which the runner's own GNU check covers.

```bash
# /usr/libexec/bats-core/bats-exec-suite:99-102 (excerpt; the if block continues to :106 — read)
if [[ "$num_jobs" != 1 ]]; then
  if ! type -p parallel >/dev/null && [[ -z "$bats_no_parallelize_across_files" ]]; then
    abort "Cannot execute \"${num_jobs}\" jobs without GNU parallel"
    exit 1
```

E7: `bats --jobs 2 lay/test/b.bats` (one file, a PATH with no `parallel`) prints `Error: Cannot execute "2" jobs without GNU parallel` and exits 1.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-106`; `SCR/E7-noparallel-onefile-order-citation.log`, `SCR/E9-config-ungroup-and-fake-parallel.log`

---

## Claim 6: "so when the first `parallel` on PATH is missing or is not GNU parallel (moreutils ships one too), the runner warns and runs serially."

**Location:** `scripts/run-tests.sh:95-96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both fallbacks (a fake non-GNU `parallel`, and no `parallel` at all) ending in the warning, a serial run and exit 0. It does not establish behaviour against the real moreutils binary, which is not installed here (a stub stands in for it).

The else branch is quoted in Claim 2 (`scripts/run-tests.sh:411-413`). E1: tests 29 (`--jobs with a non-GNU parallel first on PATH warns and runs serially`) and 30 (`--jobs without GNU parallel on PATH …`) pass. Test 30 also asserts the run-log line `^passed $T/test/sub/beta.bats`.

**Evidence:** `scripts/run-tests.sh:407-414`, `test/scripts/run-tests.bats:465-499`; `SCR/E1-suite-and-mutants.log`

---

## Claim 7: "It unsets $PARALLEL, so the user's parallel options do not reach bats' run."

**Location:** `scripts/run-tests.sh:96-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers options passed in `$PARALLEL`, whenever bats is handed `--jobs`. It does not cover options in config files (the next sentence says they still apply), or `$PARALLEL_CSH`, which parallel also reads (`/usr/bin/parallel:3365-3368`) and the runner leaves set. Nor does it cover a user-exported `BATS_NUMBER_OF_PARALLEL_JOBS` on a run where N ends up 1, where bats would use `parallel` with `$PARALLEL` still set.

`unset PARALLEL` (`scripts/run-tests.sh:408`) runs before `exec bats`. Parallel reads it here:

```perl
# /usr/bin/parallel:3361-3364 (excerpt; read_options continues to :3380 — read)
	# Add options from shell variable $PARALLEL
	if($ENV{'PARALLEL'}) {
	    push @ARGV_env, shell_words($ENV{'PARALLEL'});
	}
```

E3: mutant mD (`: unset PARALLEL`, `--plain` kept) fails test 27 at `[[ "$output" == *"ok"*"beta steady"* ]]`: `--dry-run` reached bats' parallel and no test ran. The unmutated test passes (E1).

**Evidence:** `scripts/run-tests.sh:408`, `/usr/bin/parallel:3315-3380`; `SCR/E3-unset-removed-mutant.log`, `SCR/E1-suite-and-mutants.log`

---

## Claim 8: "parallel's config files (~/.parallel/config, ~/.parallelrc, /etc/parallel/config and the like) still apply"

**Location:** `scripts/run-tests.sh:98-99`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the profile list parallel reads when `--plain` is absent (bats' call passes none) and two of those files taking effect on a real `--jobs 2` run. It does not enumerate "the like" beyond `$PARALLEL_HOME/config`, `$XDG_CONFIG_HOME/parallel/config`, `$XDG_CONFIG_DIRS/*/parallel/config` and `~/.parallel/config`.

```perl
# /usr/bin/parallel:3318-3323 (excerpt; the not-plain block continues to :3369 — read)
    if(not $opt::plain) {
	# Add options from $PARALLEL_HOME/config and other profiles
	my @config_profiles = (
	    "/etc/parallel/config",
	    (map { "$_/config" } @Global::config_dirs),
	    $ENV{'HOME'}."/.parallelrc");
```

`@Global::config_dirs` is `$PARALLEL_HOME`, `$XDG_CONFIG_HOME/parallel`, each `$XDG_CONFIG_DIRS/parallel` and `$HOME/.parallel`, keeping those that exist (`/usr/bin/parallel:2838-2849`). Bats calls `parallel --keep-order --jobs …` with no `--plain` (`bats-exec-suite:420`). E5: `~/.parallel/config` holding `--no-such-option` (V1), and `~/.parallelrc` holding `--dry-run` (V2), each changed the `--jobs 2` run.

**Evidence:** `/usr/bin/parallel:2838-2849`, `/usr/bin/parallel:3315-3369`, `/usr/libexec/bats-core/bats-exec-suite:420`; `SCR/E5-config-fail-closed.log`

---

## Claim 9: "one that breaks the run fails closed: bats reports fewer tests run than expected and exits 1, and --failed refuses that log."

**Location:** `scripts/run-tests.sh:99-101`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers three breaking configs: an unknown option (parallel exits 255), `--dry-run` (parallel exits 0 but runs nothing) and `--retries 2` (the retried job dies on bats' tmpdir). Each gets bats' count warning and exit 1, and `--failed` refuses the result. It does not cover configs that change the run without breaking it (Claim 10's residue). Wording: when no test ended there is no log of that run, so `--failed` refuses through its "left no log of its own" check, not by reading "that log".

The count check is bats' own, and bats runs under `set -o pipefail` (`bats:456`):

```bash
# /usr/lib/bats-core/validator.bash:29-32 (excerpt; bats_test_count_validator continues to :37 — read)
    if [[ "${actual_number_of_tests}" != "${expected_number_of_tests}" ]]; then
      printf '# bats warning: Executed %s instead of expected %s tests\n' "$actual_number_of_tests" "$expected_number_of_tests"
      return 1
    fi
```

E5 V1 (command `env -i PATH=/usr/bin:/usr/bin:/bin HOME=SCR/h1 TMPDIR=SCR LC_ALL=C.UTF-8 timeout 60 bash SCR/lay/scripts/run-tests.sh --jobs 2`, 2026-09-30T22:07:30Z) prints `# bats warning: Executed 0 instead of expected 3 tests`, `## exit=1`. `--failed` then prints `--failed: the last run left no log of its own …`, exit 1. V2 (`--dry-run`) behaves the same, exit 1. E6 (`--retries 2`) prints `Executed 1 instead of expected 2 tests`, exit 1.

**Evidence:** `/usr/lib/bats-core/validator.bash:3-37`, `/usr/libexec/bats-core/bats:456-466`, `scripts/run-tests.sh:239-261`; `SCR/E5-config-fail-closed.log`, `SCR/E6-config-retries.log`

---

## Claim 10: "bats keeps each file's output together (parallel groups output by default) and in file order (--keep-order), so a file's results appear once it and every file before it have ended."

**Location:** `scripts/run-tests.sh:102-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers parallel's default grouping plus bats' `--keep-order`. It does not hold when a config file overrides grouping: with `--ungroup` in `~/.parallel/config`, the later file's result printed first and x.bats' results streamed as its tests ended (E9). The run still counted and passed. The header sentence on configs (Claim 8) allows for this, but this sentence does not mention it.

`parallel --keep-order --jobs "$num_jobs" bats-exec-file …` (`bats-exec-suite:420`). E7 (default config): `15ms 1..3`, then `2123ms ok 1 x1`, `2123ms ok 2 x2`, `2123ms ok 3 y1`. x1 ended at about 1 s but was held until x.bats ended, and y1, done at once, came after it. E9 (`--ungroup` config): `159ms ok 3 y1`, `1162ms ok 1 x1`, `2176ms ok 2 x2`, exit 0.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`; `SCR/E7-noparallel-onefile-order-citation.log`, `SCR/E9-config-ungroup-and-fake-parallel.log`

---

## Claim 11: "Every test still writes its own run-log line, so the run log, the test-count check and --failed work as in a serial run."

**Location:** `scripts/run-tests.sh:104-106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a complete parallel run (5 lines for 5 tests, `expected=5`), `--failed` re-running from it in parallel, and a killed parallel run being refused. It does not cover the pre-existing `teardown_file` limit named in "Run logs".

E1 test 23 asserts `[ "$(grep -cE '^(passed|failed) ' "$LOG_DIR"/*.log)" -eq 5 ]` and a two-file `--failed --jobs 2` re-run (`test/scripts/run-tests.bats:386-399`). Test 24 asserts the `recorded … of 4 tests: it did not complete` refusal (`:419-420`). Both pass, and E2 mC shows test 23 depends on bats actually getting `--jobs`.

**Evidence:** `test/scripts/run-tests.bats:380-421`; `SCR/E1-suite-and-mutants.log`, `SCR/E2-mutants.log`

---

## Claim 12: "bats folds parallel's stderr into its output; the locale pin above keeps perl's setlocale warnings out of it"

**Location:** `scripts/run-tests.sh:106-107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `2>&1`, and the pinned case (an uninstalled `LANG` or `LC_ALL`) via test 25. It does not cover the pre-existing residue that pass 1 logged (`LANG` installed, `LC_CTYPE` not installed: the pin does not fire and perl warns; `docs/reviews/execution-logs/q090-fc-k1-E7-lcctype-residue.log`).

`… ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1` (`bats-exec-suite:420`). The pin: `export LC_ALL="$pinned"` when `locale_installed "$ambient_locale"` fails (`scripts/run-tests.sh:170-176`). E1 test 25 passes (`! grep -iE 'perl|setlocale|cite|citation' <<< "$output"` under `LANG=xx_XX.UTF-8`, with the shim showing parallel ran).

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, `scripts/run-tests.sh:170-176`, `test/scripts/run-tests.bats:423-433`; `SCR/E1-suite-and-mutants.log`

---

## Claim 13: "and upstream parallel prints its citation notice only when its stderr is a terminal, which inside bats it never is (Debian's build never prints it)."

**Location:** `scripts/run-tests.sh:107-109`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the `citation_notice()` banner: tty-gated in the function, its call commented out in Debian's build, and never shown on a normal run even under a terminal. It does not cover the citation paragraph inside parallel's usage text. That text prints to stdout whenever parallel rejects its options, with no tty check, in this Debian build too, and in the fail-closed config case Claim 9 documents it lands in bats' output.

The banner's gate and Debian's disabled call are as described:

```perl
# /usr/bin/parallel:5632-5645 (excerpt; citation_notice continues to :5700 — read)
sub citation_notice() {
    # if --will-cite or --plain: do nothing
    # if stderr redirected: do nothing
    # if $PARALLEL_HOME/will-cite: do nothing
    # else: print citation notice to stderr
    if($opt::willcite
       or
       $opt::plain
       or
       not -t $Global::original_stderr
```

`#    citation_notice();` (`/usr/bin/parallel:2578`). But `die_usage()` calls `usage()` (`/usr/bin/parallel:5577-5581`), and `usage()` prints unconditionally:

```perl
# /usr/bin/parallel:5614-5619 (excerpt; usage() runs :5583-5630 — read)
	 "Academic tradition requires you to cite works you base your article on.",
	 "If you use programs that use GNU Parallel to process data for an article in a",
	 "scientific publication, please cite:",
	 "",
	 "  Tange, O. (2022, November 22). GNU Parallel 20221122 ('Херсо́н').",
	 "  Zenodo. https://doi.org/10.5281/zenodo.7347980",
```

E5 V1: the `--jobs 2` run's output holds `Unknown option: no-such-option`, the usage text and `Academic tradition requires you to cite works …`, followed by the bats count warning. E7: under `script -qec` (a terminal), a normal `parallel echo ::: hello` prints only `hello`. `parallel --no-such-option … 2>/dev/null | grep -c -i cite` gives `2`. Precise version: "…(Debian's build never prints it, though the usage text parallel prints when it rejects an option, as a breaking config file makes it do, carries the same citation paragraph)".

**Evidence:** `/usr/bin/parallel:2570-2582`, `/usr/bin/parallel:5577-5630`, `/usr/bin/parallel:5632-5660`; `SCR/E5-config-fail-closed.log`, `SCR/E7-noparallel-onefile-order-citation.log`

---

## Claim 14: "At most 3 digits, so the value never overflows bash arithmetic and parallel never sizes thousands of job slots."

**Location:** `scripts/run-tests.sh:137-138`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex capping N at 999 before `(( jobs > ${#files[@]} ))` runs, and 4-digit values being refused. It does not establish what parallel does per job slot. The value parallel sees is further lowered to the file count (Claim 1).

The regex is `^[1-9][0-9]{0,2}$` (`scripts/run-tests.sh:139`, quoted in Claim 1), and its only arithmetic use is `:406`. E4: `1000` and `1e3` exit 2.

**Evidence:** `scripts/run-tests.sh:136-146`, `scripts/run-tests.sh:406`; `SCR/E4-jobs-values.log`

---

## Claim 15: "See "Parallel runs" in the header. N is first lowered to the file count, so a one-file run needs no parallel. Otherwise bats aborts without GNU parallel, so that is what is checked: the first `parallel` on PATH, the one bats runs, with --plain so the user's parallel config cannot fail the check."

**Location:** `scripts/run-tests.sh:402-405`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers lowering before the check, a one-file `--jobs 5` run needing no `parallel`, bats invoking `parallel` by name via PATH, and `--plain` skipping every profile and `$PARALLEL` (`/etc/parallel/config`, all config dirs and `~/.parallelrc`, not just `~/.parallel/config` as parallel's own option text says). It does not establish that bats checks for GNU (Claim 5's residue). Nor does it show that `unset PARALLEL` running first is needed for the check: with `--plain`, moving it after the check changes nothing (E2 mA, Claim 33a).

```bash
# scripts/run-tests.sh:406-409 (excerpt; the if block continues to :414 — read)
(( jobs > ${#files[@]} )) && jobs=${#files[@]}
if [[ "$jobs" -gt 1 ]]; then
  unset PARALLEL
  if [[ "$(parallel --plain --version 2>/dev/null)" == "GNU parallel"* ]]; then
```

`get_options_from_array(\@ARGV_copy,"profile|J=s","plain")` then `if(not $opt::plain) {` around all profile and `$PARALLEL` reading (`/usr/bin/parallel:3315-3318`, the block ends at `:3369`). E7: `runner --jobs 5 test/b.bats` with no `parallel` on PATH prints `ok 1 b1`, exit 0, no warning. E5: under the V1 HOME, `parallel --plain --version` prints `GNU parallel 20221122` while plain `parallel --version` prints `Unknown option: no-such-option`. E2: mB (no `--plain`) fails test 28, and mA2 fails tests 27 and 28.

**Evidence:** `scripts/run-tests.sh:399-414`, `/usr/bin/parallel:3315-3369`, `/usr/libexec/bats-core/bats-exec-suite:420`; `SCR/E7-noparallel-onefile-order-citation.log`, `SCR/E5-config-fail-closed.log`, `SCR/E2-mutants.log`

---

## Claim 16: "parallel_shim: put a `parallel` first on PATH that logs its arguments to $T/parallel.args and execs the real one. The runner's own --version check is logged too, so a test that wants to see bats used parallel greps for the --no-parallelize-within-files it hands bats."

**Location:** `test/scripts/run-tests.bats:329-332`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the shim logging every call (the runner's `--plain --version` and bats' run), and the flag appearing only in bats' call, inside the flags bats forwards to `bats-exec-file`. It does not cover the skip text ("GNU parallel is not installed here"): `command -v parallel` finds any `parallel`, so with only a non-GNU one installed the tests would run and fail rather than skip.

```bash
# test/scripts/run-tests.bats:333-342
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

E5 V2's dry-run output shows bats' call carries `bats-exec-file --dummy-flag -j 2 --no-parallelize-within-files …`. E2 mC (the runner still runs the check, but bats gets no `--jobs`) fails each test that greps for the flag.

**Evidence:** `test/scripts/run-tests.bats:329-342`, `/usr/libexec/bats-core/bats-exec-suite:46-49`; `SCR/E5-config-fail-closed.log`, `SCR/E2-mutants.log`

---

## Claim 17: test "--jobs: a missing, zero, non-numeric or 4-digit N is a usage error"

**Location:** `test/scripts/run-tests.bats:344-358`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four cases named, each with status 2 and its message, and that gamma did not run after `1000`. It does not cover leading-zero, signed or whitespace values (E4 covers those outside the suite).

The test asserts `[ "$status" -eq 2 ]` for `--jobs`, `0`, `x` and `1000`, with the matching `got:` text. E1 `ok 20`.

**Evidence:** `test/scripts/run-tests.bats:344-358`; `SCR/E1-suite-and-mutants.log`

---

## Claim 18: test "--jobs 2 runs files through parallel, not tests within a file"

**Location:** `test/scripts/run-tests.bats:360-370`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test asserting parallel's arguments (`--jobs 2 .*--no-parallelize-within-files`) and the four results. It does not observe serial execution within a file. This is settled: override-log row 172 (2026-09-30), Acknowledged. It is recorded here and not re-raised, and there is no new evidence.

`grep -q -- '--jobs 2 .*--no-parallelize-within-files' "$T/parallel.args"` (`:369`). E1 `ok 21`; E2 mC fails it at `:369`.

**Evidence:** `test/scripts/run-tests.bats:360-370`, `docs/reviews/override-log.md:172`; `SCR/E1-suite-and-mutants.log`, `SCR/E2-mutants.log`

---

## Claim 19: test "--jobs 1 runs serially and needs no parallel"

**Location:** `test/scripts/run-tests.bats:372-378`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `parallel` never being called (not even by the runner's check) on a two-file `--jobs 1` run, so bats ran its serial loop. It does not cover a user-exported `BATS_NUMBER_OF_PARALLEL_JOBS`.

`[ ! -f "$T/parallel.args" ]` (`:377`) with the shim on PATH. The runner skips the check when `jobs` is 1 (`scripts/run-tests.sh:407`). E1 `ok 22`.

**Evidence:** `test/scripts/run-tests.bats:372-378`, `scripts/run-tests.sh:407`; `SCR/E1-suite-and-mutants.log`

---

## Claim 20: test "--jobs: a parallel run records a complete log that --failed re-runs from" and its comment "A second file that fails until $T/fixed exists, so --failed re-runs two files and stays parallel."

**Location:** `test/scripts/run-tests.bats:380-405`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `expected=5`, five log lines, the two-file `--failed --jobs 2` re-run going through parallel (the args file is removed first), and the final "nothing to re-run". It does not cover `--failed` narrowing to one file, which lowers N to 1.

`delta.bats` checks `[ -f "$BATS_TEST_DIRNAME/../fixed" ]`, i.e. `$T/fixed`. `rm "$T/parallel.args"` (`:393`) comes before the re-run's `grep -q -- '--jobs 2 .*--no-parallelize-within-files'` (`:399`). E1 `ok 23`; E2 mC fails it at `:399`.

**Evidence:** `test/scripts/run-tests.bats:380-405`; `SCR/E1-suite-and-mutants.log`, `SCR/E2-mutants.log`

---

## Claim 21: test "--jobs: a parallel run killed partway is refused by --failed"

**Location:** `test/scripts/run-tests.bats:407-421`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the TERM kill (rc 143) and the `--failed` refusal. It does not check that the killed run was parallel: nothing reads `$T/parallel.args`, so a runner that never gave bats `--jobs` passes the test too.

The test calls `parallel_shim` (`:408`) but never greps its log (`:407-421`). E2 mC (bats never given `--jobs`) gives `ok 5 --jobs: a parallel run killed partway is refused by --failed`, as pass 2's M5 did (pass-2 r2 Claim 20 rated this Mostly accurate, r3 Claim 23 Verified; the log has no override row for it). Adding `grep -q -- '--no-parallelize-within-files' "$T/parallel.args"` after the kill would make the name hold.

**Evidence:** `test/scripts/run-tests.bats:407-421`; `SCR/E2-mutants.log`

---

## Claim 22: test "--jobs: an uninstalled locale leaves no perl or citation text in the output" and its comment "gamma asserts its own subprocess output is clean; the suite-level output must be clean too."

**Location:** `test/scripts/run-tests.bats:423-433`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a parallel run (the shim saw `--no-parallelize-within-files`) under `LANG=xx_XX.UTF-8` with no perl, setlocale or citation text. It does not show the assertion could catch a citation notice on this Debian build, which never prints one on a normal run (Claim 13).

`grep -q -- '--no-parallelize-within-files' "$T/parallel.args"` (`:428`), `! grep -iE 'perl|setlocale|cite|citation' <<< "$output"` (`:432`, the last command, so its status is the test's). E1 `ok 25`; E2 mC fails it at `:428`.

**Evidence:** `test/scripts/run-tests.bats:423-433`; `SCR/E1-suite-and-mutants.log`, `SCR/E2-mutants.log`

---

## Claim 23: test "--jobs above the file count is lowered to it"

**Location:** `test/scripts/run-tests.bats:435-440`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--jobs 999` with two files reaching parallel as `--jobs 2`. It does not cover lowering after `--failed` narrows the selection.

`grep -q -- '--jobs 2 .*--no-parallelize-within-files' "$T/parallel.args"` (`:439`). E1 `ok 26`.

**Evidence:** `test/scripts/run-tests.bats:435-440`; `SCR/E1-suite-and-mutants.log`

---

## Claim 24: test "--jobs: the user's PARALLEL options neither reach bats' parallel nor fail the check" and its comment "--dry-run would run no test at all; an unknown option would fail the --version check and make the run serial."

**Location:** `test/scripts/run-tests.bats:442-452`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both halves of the name: removing the unset fails it (mD), and removing both guards of the check fails it (mA2). The comment describes what each option would do if it got through. It does not establish that the test pins the order of `unset` and the check: with `--plain`, either guard alone protects the check, so mA passes (Claim 33a).

E3 mD fails at `:449` (`ok … beta steady`). E2 mA2 fails at `:450` (`!= *"running serially"*`). E2 mA gives `ok 8`.

**Evidence:** `test/scripts/run-tests.bats:442-452`; `SCR/E3-unset-removed-mutant.log`, `SCR/E2-mutants.log`

---

## Claim 25: test "--jobs: a parallel config file cannot fail the GNU parallel check"

**Location:** `test/scripts/run-tests.bats:454-463`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a `~/.parallel/config` holding an unknown option not turning the run serial, with bats handed `--jobs`. It does not assert the run's status (it fails closed, per Claim 9), and it does not cover `/etc/parallel/config` or `~/.parallelrc` by test (static and E5 cover them).

`[[ "$output" != *"running serially"* ]]` and the flag grep (`:461-462`). E1 `ok 28`; E2 mB fails it at `:461`.

**Evidence:** `test/scripts/run-tests.bats:454-463`; `SCR/E1-suite-and-mutants.log`, `SCR/E2-mutants.log`

---

## Claim 26: test "--jobs with a non-GNU parallel first on PATH warns and runs serially"

**Location:** `test/scripts/run-tests.bats:465-475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a stub printing "parallel from moreutils", the warning and a serial pass. It does not use the real moreutils binary.

`[[ "$output" == *"is not GNU parallel; running serially"* ]]`, `[[ "$output" == *"ok 2 beta steady"* ]]` (`:473-474`). E1 `ok 29`.

**Evidence:** `test/scripts/run-tests.bats:465-475`; `SCR/E1-suite-and-mutants.log`

---

## Claim 27: test "--jobs without GNU parallel on PATH warns and runs serially" and its comment "A PATH holding everything the current one does except parallel (and bats' libexec directory, which in_runner drops too)."

**Location:** `test/scripts/run-tests.bats:477-499`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the symlink PATH (executables only, first match per name as PATH order would give, `parallel` and the libexec dir left out), the `command -v parallel ||` guard, the warning, a serial pass and a recorded log line. It does not carry non-executable PATH entries, which do not affect command lookup.

`[[ -x "$f" && ! -e "$bin/${f##*/}" && "${f##*/}" != parallel ]] && ln -s …` (`:487`), and `[[ -d "$dir" && "$dir" != "$BATS_LIBEXEC" ]] || continue` (`:485`). E1 `ok 30`. E7 built the same kind of PATH, where `command -v parallel` returned rc=1.

**Evidence:** `test/scripts/run-tests.bats:477-499`; `SCR/E1-suite-and-mutants.log`, `SCR/E7-noparallel-onefile-order-citation.log`

---

## Claim 28: 78b3b08: "PARALLEL_HOME did not isolate parallel's config: parallel still reads ~/.parallel/config, ~/.parallelrc, $XDG_CONFIG_HOME/parallel/config and /etc/parallel/config. The export is removed and the header now says config files still apply and a breaking one fails closed (bats' count check, then --failed refuses the log)."

**Location:** `78b3b08` commit message, lines 3-9
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers parallel's config-dir list (PARALLEL_HOME is added to it, not substituted), the removed export (`git grep PARALLEL_HOME HEAD -- scripts` finds only the absence) and the header text. The fail-closed half carries Claim 9's wording note.

`@Global::config_dirs = (grep { -d $_ } $ENV{'PARALLEL_HOME'}, (map { "$_/parallel" } $xdg_config_home, split /:/, $ENV{'XDG_CONFIG_DIRS'}), $ENV{'HOME'} . "/.parallel");` (`/usr/bin/parallel:2841-2849`, paraphrased — no quote available because the statement spans nine lines with a comment interleaved; its content is reproduced token for token). The profile list is quoted in Claim 8. E5 shows the fail-closed half.

**Evidence:** `/usr/bin/parallel:2838-2849`, `/usr/bin/parallel:3318-3323`, `scripts/run-tests.sh:98-101`; `SCR/E5-config-fail-closed.log`

---

## Claim 29: 78b3b08: "`unset PARALLEL` ran after the GNU check, so an unparsable $PARALLEL made the runner warn "not GNU parallel" and run serially. It now runs first, and the check uses `parallel --plain --version` so a config file cannot fail it either (+ tests for both)."

**Location:** `78b3b08` commit message, lines 10-13
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the old order, the new order, `--plain` and the two new tests (27 for `$PARALLEL`, 28 for a config file). It does not establish that either test depends on the new order. At HEAD, `--plain` alone keeps `$PARALLEL` from failing the check, so the order no longer matters (Claim 33a).

084868f's block had `if [[ "$(parallel --version 2>/dev/null)" == "GNU parallel"* ]]; then` followed by `    unset PARALLEL` (`git show 084868f:scripts/run-tests.sh`, the `--jobs` block). HEAD's is quoted in Claim 15. E2 mA2 (the old shape) fails tests 27 and 28 with `running serially`.

**Evidence:** `git show 084868f:scripts/run-tests.sh` (the `--jobs` block), `scripts/run-tests.sh:406-414`; `SCR/E2-mutants.log`

---

## Claim 30: 78b3b08: "install-host.bats' exposure: agent_gate refuses on a live process whose working directory procs_in_checkout cannot read (e.g. non-dumpable); exiting processes are skipped, so "starting and ending" was wrong."

**Location:** `78b3b08` commit message, lines 14-16
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the refusal (Claim 4) and the skip of a process whose cmdline is empty (`[ -n "$cmd" ] || continue`). It does not cover a process that exits between the `readlink` and the cmdline read while its cmdline is still readable. That window is a race and is not shown here.

`[ -n "$cmd" ] || continue                   # exited, or a kernel thread` (`devcontainer-config/install.sh:1178`). E8 T92 passes.

**Evidence:** `devcontainer-config/install.sh:1165-1182`; `SCR/E8-agent-gate-T92.log`

---

## Claim 31: 78b3b08: "The health-check.bats cache example was weak (written in setup_file, only read after); the header now says within-file serial is simply the only way the suites have run. "N above the core count buys nothing" was unmeasured and is dropped. The stale "not the file count" comment now says N is lowered to the file count first, so a one-file run needs no parallel."

**Location:** `78b3b08` commit message, lines 17-22
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the cache's write and read sites, the new header wording, the phrase's removal and the rewritten comment. It does not judge whether the cache example was "weak" (opinion).

`setup_file() { _run_and_cache }`. `setup()` reads `$_HC_CACHE_DIR/output` and writes only when it is missing (`test/scripts/health-check.bats:34-50`). `git grep -c "core count" HEAD -- scripts test` finds nothing (rc 1). The header says "the only way the suites have ever run" (`scripts/run-tests.sh:87-88`). The comment is quoted in Claim 15.

**Evidence:** `test/scripts/health-check.bats:21-50`, `scripts/run-tests.sh:85-89`, `scripts/run-tests.sh:402-405`

---

## Claim 32: 78b3b08: "Tests: the shim's args file now also holds the runner's --version call, so tests grep for --no-parallelize-within-files instead of the file's existence; the --failed re-run covers two files so it stays parallel."

**Location:** `78b3b08` commit message, lines 23-25
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tests that assert parallel use (21, 23, 25–28 grep for the flag, and 21 also checks the file exists before grepping). Test 22's `[ ! -f … ]` is an absence check, which is still right for `--jobs 1`. It does not cover test 24, which checks neither (Claim 21).

See Claims 16, 18, 20 and 22–25. E2 mC fails each of those greps.

**Evidence:** `test/scripts/run-tests.bats:360-463`; `SCR/E2-mutants.log`

---

## Claim 33a: 78b3b08: "Mutants (unset moved back, …) each fail their test."

**Location:** `78b3b08` commit message, lines 25-26
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the mutant as the message names it, against the committed code: `unset PARALLEL` moved back behind the GNU check (into the success branch, where 084868f had it) with `--plain` kept. It does not establish which tree the author mutated. A mutant that also dropped `--plain` (mA2) does fail tests 27 and 28.

With `--plain` on the check, `$PARALLEL` cannot fail it, and the success branch still unsets `$PARALLEL` before `exec bats`. The mutant is therefore equivalent, and no test can kill it. E2 mA, diff `408d407 <   unset PARALLEL` / `409a409 >     unset PARALLEL`, command `(cd SCR/mA && timeout 300 bats -f 'jobs' test/scripts/run-tests.bats)`, 2026-09-30T22:06:17Z: all 11 `--jobs` tests `ok`, `## exit=0`. The shipped behaviour is unaffected. What is wrong is the coverage claim in the commit body: "unset first" is not pinned by any test, and cannot be while `--plain` is there. Precise version: "Mutants (unset removed, --plain dropped, bats never given --jobs) each fail their test; moving the unset back after the check is equivalent now that the check uses --plain." Branch history is not rewritten (per the override-log convention), so if kept, record this as Accepted-immutable.

**Evidence:** `scripts/run-tests.sh:406-414`; `SCR/E2-mutants.log` (mA), `SCR/E3-unset-removed-mutant.log` (mD, the "unset removed" mutant that does fail)

---

## Claim 33b: 78b3b08: "Mutants (…, --plain dropped, bats never given --jobs) each fail their test."

**Location:** `78b3b08` commit message, lines 25-26
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers mB (fails test 28) and mC (fails tests 21, 23, 25, 26, 27 and 28). It does not cover test 24, which mC passes (Claim 21).

E2 mB: `not ok 9 --jobs: a parallel config file cannot fail the GNU parallel check`, exit 1. mC: six `not ok`, exit 1.

**Evidence:** `SCR/E2-mutants.log`

---

## Claim 34: 78b3b08 Notes: "no attempt to block parallel's config files (bats passes no --plain, and overriding HOME would change every test's environment)"

**Location:** `78b3b08` commit message, Notes
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers bats' `parallel` call having no `--plain`. The HOME half is design rationale and is not checked.

`parallel --keep-order --jobs "$num_jobs" bats-exec-file "$(printf "%q " "${flags[@]}")" "{}" "$TESTS_LIST_FILE" ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1` (`/usr/libexec/bats-core/bats-exec-suite:420`).

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`

---

## Claims Requiring Attention

### Incorrect
- **Claim 33a** (`78b3b08` message): the "unset moved back" mutant is equivalent at the committed code (`--plain` already protects the check), so all 11 `--jobs` tests pass it (E2 mA). The body should list "unset removed" (mD fails test 27), or say the order is not pinned. The commit is immutable, so record this as Accepted-immutable.

### Stale
- none

### Mostly Accurate
- **Claim 13** (`scripts/run-tests.sh:107-109`): "Debian's build never prints it" holds for the `citation_notice()` banner, but parallel's usage text, printed on any option error (such as a breaking config file, the fail-closed case documented just above), carries the same citation paragraph into bats' output (E5 V1). Add that qualifier.
- **Claim 21** (`test/scripts/run-tests.bats:407-421`): the "parallel run killed partway" test never checks that the run was parallel. A runner that never gives bats `--jobs` passes it (E2 mC). A `grep -q -- '--no-parallelize-within-files' "$T/parallel.args"` would close this.
- **Claim 18** (`test/scripts/run-tests.bats:360-370`): settled (override-log row 172). Listed for completeness, not re-raised.

### Unverifiable
- none

Residues named in Scope that a reader could take as covered (none changes a verdict): a `--ungroup` or `--line-buffer`-style config overrides the grouping and ordering sentence without failing the run (Claim 10, E9). `$PARALLEL_CSH` and a user-exported `BATS_NUMBER_OF_PARALLEL_JOBS` or `BATS_NO_PARALLELIZE_ACROSS_FILES` are not cleared (Claims 2, 7, 19). The pre-existing `LC_CTYPE` locale residue remains (Claim 12).

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path named below, structured per the skill.
- Answered: yes. All five focus areas were verified against bats libexec, /usr/bin/parallel and install.sh, with execution for each executable claim.
- Out of scope: earlier commits' bodies (settled per the override log); non-`--jobs` tests in run-tests.bats; performance and security judgments.
- Escalate: Claim 33a (a commit-body coverage claim, immutable, so an Accepted-immutable row) and the new Claim 13 finding (the citation paragraph in parallel's usage text reaches bats' output when a config file breaks the run); Claim 21 remains open from pass 2 with a split r2/r3 verdict and no override row.
- Decisions I made: read "unset moved back" as moving the unset behind the check with `--plain` kept (the code as committed), not also reverting `--plain`, and ran both (mA survives, mA2 fails). Kept Claim 5 and Claim 9 Verified with their wording residues in Scope rather than Mostly accurate, because a reader's action (trust the runner's GNU check; distrust `--failed` after a broken run) is right either way.
