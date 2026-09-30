# Code Fact-Check Report

**Commit:** ff99d86
**Replication:** r1 (final confirming pass 3)
**Repository:** /workspace/.claude/wt-run-tests-jobs (branch feat/run-tests-jobs)
**Scope:** `git diff main...HEAD -- scripts test`: scripts/run-tests.sh (the `--jobs` Flags entry, the "Parallel runs" header paragraph, the `--jobs` parse comment, the lowering/GNU-check block, its comment and warning) and test/scripts/run-tests.bats (`parallel_shim` and the 11 `--jobs` tests), plus the commit message of 78b3b08. `scripts/` and `test/` are unchanged between 78b3b08 and HEAD ff99d86, which only adds the pass-2 rubric row. Earlier commit bodies are settled (override-log rows dated 2026-09-30) and are not re-verdicted. Claims were checked against the code that runs them: bats 1.8.2 libexec (`/usr/libexec/bats-core/bats-exec-suite`, `/usr/lib/bats-core/validator.bash`), GNU parallel 20221122+ds-2 (`/usr/bin/parallel`), and `devcontainer-config/install.sh` (`procs_in_checkout`, `agent_gate`).
**Checked:** 2026-09-30
**Total claims checked:** 41
**Summary:** 35 verified, 4 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

The hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read. No claim matches a logged pattern. Claim 37b (a mutant result that does not reproduce) is a verification-result claim, not a fabricated symbol, and the brief limits edits to this report, so nothing is appended to the log.

Settled override-log rows for 2026-09-30 `feat/run-tests-jobs` (rows 166–174) were read and are not re-raised. Claim 23 is the row-172 proxy, recorded Verified-with-residue only.

**Probes.** Every probe ran with `LC_ALL=C.UTF-8` under `timeout`. Each ran against a throwaway copy of the runner (a repo layout built the same way as run-tests.bats' `setup()`) or a copy of run-tests.bats with its runner, never the real suite. The largest `--jobs` passed was 3 (plus rejected values up to 1000). Raw output is in `/tmp/claude-1000/-workspace/21797f19-046e-4351-9c55-0471f4b3d3b6/scratchpad/run-tests-jobs/fc-p3-r1/` (written `fc-p3-r1/` below). The brief allows edits to this report only, so the logs stay in the scratchpad. When the probes finished, `ps -eo pid,args | grep -F fc-p3-r1` found no process left over.

| Probe | Command (summary) | cwd | Exit | UTC |
|---|---|---|---|---|
| E1 | `timeout 400 bats test/scripts/run-tests.bats` on the unmutated copy M0 and on four mutants: Ma (`unset PARALLEL` moved after the probe, into the GNU branch; `--plain` kept), Mb (`--plain` dropped), Mc (`unset PARALLEL` removed), Md (Ma + Mb, i.e. b34a6fe's order without PARALLEL_HOME) | fc-p3-r1/mut-M* | M0 0 (30/30 ok); Ma 0 (30/30 ok); Mb 1 (28 fails); Mc 1 (27 fails); Md 1 (27, 28 fail) | 22:05:10Z–22:05:42Z |
| E1b | Same, mutant Me (`bats_args+=(--jobs …)` replaced by `:`) | fc-p3-r1/mut-Me | 1 (21, 23, 25, 26, 27, 28 fail) | 22:06:49Z |
| E1c | Same, mutant Mf (the lowering line removed) | fc-p3-r1/mut-Mf | 1 (26 fails) | 22:09:20Z |
| E2 | `parallel --version`, `parallel --plain --version` and `parallel --version --plain` with `--no-such-option` in each of `~/.parallel/config`, `~/.parallelrc`, `$XDG_CONFIG_HOME/parallel/config`, `$PARALLEL_HOME/config`. Also `PARALLEL=`/`PARALLEL_CSH=` set to `--no-such-option` (with and without `--plain`) and to `--dry-run` | fc-p3-r1 | 255 without `--plain`; 0 with it, every location | 22:05:19Z, 22:05:29Z |
| E3 | `parallel --plain --version` under `PARALLEL_SHELL=/nonexistent/sh`, `PARALLEL_HOME=/proc/nope`, `HOME=/nonexistent` | fc-p3-r1 | 255, 0, 0 | 22:05:38Z |
| E4 | Runner `--jobs 2`, then `--failed`, with `~/.parallel/config` empty / `--dry-run` / `--no-such-option` / `--tag` / `--retries 2` / `--ungroup` (fixture: a.bats with a test that fails once, b.bats) | fc-p3-r1 | runs 1 every time (a genuine failure plus any breakage); `--failed` 1, 1 for dry-run and unknown option, 0 for none, tag, retries and ungroup | 22:05:55Z–22:06:04Z |
| E5 | `timeout 180 bats -f 'T9[12] ' test/install-host.bats` | worktree root | 0 (T91, T92 ok) | 22:07:29Z |
| E6 | Runner `--jobs` with `0 01 -1 1000 1x ''`; `--fast --jobs 2`; `--slow --jobs 2` (one file); `--all --jobs 3 a c`; `--jobs 2 --fast a c`; `--failed --jobs 2`, with a `parallel` shim that logs its arguments | fc-p3-r1 | 2 for every bad value; runs 1/0 as the fixtures dictate | 22:07:59Z–22:08:13Z |
| E7 | `dpkg-divert --list`, `dpkg -S /usr/bin/parallel`, `dpkg -s moreutils`, `grep -n "citation_notice()" /usr/bin/parallel` | fc-p3-r1 | 0 | 22:08:22Z |
| E8 | `bats --jobs 2 t/x.bats t/y.bats` with a non-GNU `parallel` (a script that exits 1) first on PATH | fc-p3-r1/e8 | 1 (`Executed 0 instead of expected 2 tests`, no abort message) | 22:09:49Z |

---

## Claim 1: "--jobs N  Run up to N test files at once … N is 1 to 999, digits only, no leading zero; anything else is a usage error (exit 2). 1, the default, runs serially; N above the number of selected files is lowered to it. Combines with every other flag, --failed included."

**Location:** `scripts/run-tests.sh:36-40`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the accepted value set, exit 2, the default of 1, lowering to the selected-file count, and `--fast`, `--slow`, `--all`, FILE and `--failed` combined with `--jobs`. It does not establish that a `--failed` run stays parallel, which depends on how many files failed: E6's `--failed --jobs 2` had one file left and ran serially, which is the stated lowering.

```bash
# scripts/run-tests.sh:136-146 (the --jobs case arm, complete)
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

`jobs=1` is the default (`scripts/run-tests.sh:127`), and `(( jobs > ${#files[@]} )) && jobs=${#files[@]}` (`:406`) does the lowering. In E6, `0`, `01`, `-1`, `1000`, `1x` and a missing value each exited 2. `--fast --jobs 2` (2 files) and `--all --jobs 3 a c` (2 files) logged `--keep-order --jobs 2 bats-exec-file … --no-parallelize-within-files`, and `--slow --jobs 2` (1 file) made no `parallel` call. E1 M0 passed test 23, where `--failed --jobs 2` over two files goes through parallel.

**Evidence:** `scripts/run-tests.sh:127`, `scripts/run-tests.sh:136-146`, `scripts/run-tests.sh:406`, fc-p3-r1/E6-values-and-combos.log, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "Parallel runs: --jobs N (N > 1) hands bats `--jobs N --no-parallelize-within-files`, so whole files run side by side and the tests within a file stay serial"

**Location:** `scripts/run-tests.sh:85-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arguments handed to bats and bats' pass-through of `--no-parallelize-within-files` to each `bats-exec-file`. It does not establish that tests within a file were observed to run one at a time. That is the settled row-172 proxy.

`bats_args+=(--jobs "$jobs" --no-parallelize-within-files)` (`scripts/run-tests.sh:410`). bats forwards it (`flags+=("--no-parallelize-within-files")`, `/usr/libexec/bats-core/bats-exec-suite:49`) into the per-file command it gives parallel (`parallel --keep-order --jobs "$num_jobs" bats-exec-file "$(printf "%q " "${flags[@]}")" "{}" …`, `:420`). E6's shim log shows `--keep-order --jobs 2 bats-exec-file --dummy-flag -j 2 --no-parallelize-within-files  {} …`.

**Evidence:** `scripts/run-tests.sh:410`, `/usr/libexec/bats-core/bats-exec-suite:44-49`, `/usr/libexec/bats-core/bats-exec-suite:415-421`, fc-p3-r1/E6-values-and-combos.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "the only way the suites have ever run: no suite has been checked for tests that interfere when run at once."

**Location:** `scripts/run-tests.sh:87-88`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers committed history: no runner, script or test on main ever passed bats `--jobs`/`-j`. It does not establish what anyone ran by hand outside the repo. "No suite has been checked" is an absence claim, supported only by the lack of any such check in the repo.

`git log --oneline -S'--jobs' main -- scripts test .github`, `-S'bats -j'` and `-S'--parallel'` return nothing, and `rg -n "bats .*(-j |--jobs)" scripts test` finds no match outside run-tests (paraphrased — no quote available because the claim covers absence of code, no matching grep or history results).

**Evidence:** `scripts/run-tests.sh:87-88` (history searches listed above)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "The slowest file bounds the speedup."

**Location:** `scripts/run-tests.sh:88-89`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file-granular scheduling unit. It does not establish which file is slowest or the size of the bound (see override row 166).

The only unit parallel receives is a whole file: `::: "${BATS_UNIQUE_TEST_FILENAMES[@]}"` (`/usr/libexec/bats-core/bats-exec-suite:420`), and within-file parallelism is off (Claim 2). A run therefore cannot end before its longest file does.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: "Files still share the machine: install.sh's agent_gate, which install-host.bats runs, refuses when procs_in_checkout cannot read the working directory of a live process of the user (a non-dumpable one, say), and under --jobs other files' processes are live beside it."

**Location:** `scripts/run-tests.sh:89-93`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's refusal on an unreadable cwd, the real (unstubbed) scan in install-host.bats, and the non-dumpable example. It does not establish that any other suite actually starts a process with an unreadable cwd, so a real `--jobs` refusal is not observed. install.sh's own lineage is exempt, so "a live process of the user" means any process of the user outside that lineage.

```bash
# devcontainer-config/install.sh:1171-1181 (loop body; procs_in_checkout continues to :1182 — read)
    if cwd="$(readlink "$d/cwd" 2>/dev/null)"; then
      case "$cwd" in "$root"|"$root"/*) kind=in ;; *) continue ;; esac
    else
      kind=unknown
    fi
    pid="${d#/proc/}"
    in_lineage "$pid" && continue
    cmd="$(tr '\0' ' ' 2>/dev/null < "$d/cmdline")"
    [ -n "$cmd" ] || continue                   # exited, or a kernel thread
    printf '%s %s %s\n' "$kind" "$pid" "${cmd% }"
  done
```

`agent_gate` takes `scanned="$(procs_in_checkout)"` (`:1203`) and returns 0 only when `$unknown` is empty along with the others (`:1248`). Otherwise it prints "whose working directory cannot be read" and exits 1. install-host.bats stubs only `pgrep` and `docker` (`test/install-host.bats:35-42`), not the scan. In E5, T92 (a `prctl(PR_SET_DUMPABLE, 0)` python process started outside the checkout) and T91 passed: both were refused and named.

**Evidence:** `devcontainer-config/install.sh:1165-1182`, `devcontainer-config/install.sh:1187-1248`, `test/install-host.bats:35-42`, `test/install-host.bats:1594-1611`, fc-p3-r1/E5-install-host-T91-T92.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "bats runs files through GNU parallel and aborts without it even for one file"

**Location:** `scripts/run-tests.sh:94-95`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the abort when no `parallel` is on PATH and `--jobs` is not 1. It does not establish that bats checks for *GNU* parallel: with a non-GNU `parallel` present, bats calls it and the run fails without the abort (E8). Unchanged since r3 Claim 8.

```bash
# /usr/libexec/bats-core/bats-exec-suite:99-101 (excerpt; the if block continues to :108 — read)
if [[ "$num_jobs" != 1 ]]; then
  if ! type -p parallel >/dev/null && [[ -z "$bats_no_parallelize_across_files" ]]; then
    abort "Cannot execute \"${num_jobs}\" jobs without GNU parallel"
```

E8: with a fake `parallel` first on PATH, `bats --jobs 2 x.bats y.bats` called it (`non-GNU parallel called: --keep-order --jobs 2 …`) and ended with `# bats warning: Executed 0 instead of expected 2 tests`, exit 1, without the abort message.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-108`, fc-p3-r1/E8-bats-nongnu-parallel.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "(moreutils ships one too)"

**Location:** `scripts/run-tests.sh:96`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Debian packaging: the parallel package diverts a `/usr/bin/parallel` to `parallel.moreutils`, which exists only because moreutils installs one. It does not establish other distributions' packaging. moreutils is not installed here. This upgrades r3 Claim 9b from Unverifiable.

E7: `dpkg-divert --list` prints `diversion of /usr/bin/parallel to /usr/bin/parallel.moreutils by parallel` (and the same for `parallel.1.gz`). `dpkg -s moreutils` reports it is not installed.

**Evidence:** fc-p3-r1/E7-debian-divert-citation.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "so when the first `parallel` on PATH is missing or is not GNU parallel …, the runner warns and runs serially."

**Location:** `scripts/run-tests.sh:95-96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two stated triggers. It does not establish that they are the only ones. `$PARALLEL` and config files no longer trigger it (Claim 19), but GNU parallel with an unusable `PARALLEL_SHELL` still fails the probe (E3: `Shell '/nonexistent/sh' not found.`, exit 255), and the runner then warns "not GNU parallel".

```bash
# scripts/run-tests.sh:406-414 (the lowering and GNU-check block, complete)
(( jobs > ${#files[@]} )) && jobs=${#files[@]}
if [[ "$jobs" -gt 1 ]]; then
  unset PARALLEL
  if [[ "$(parallel --plain --version 2>/dev/null)" == "GNU parallel"* ]]; then
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
  else
    echo "WARNING: --jobs $jobs needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially" >&2
  fi
fi
```

E1 M0: tests 29 (non-GNU first) and 30 (no parallel) pass.

**Evidence:** `scripts/run-tests.sh:406-414`, `test/scripts/run-tests.bats:465-499`, fc-p3-r1/E1-mutants.log, fc-p3-r1/E3-env-probe.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "It unsets $PARALLEL, so the user's parallel options do not reach bats' run."

**Location:** `scripts/run-tests.sh:96-97`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `$PARALLEL`: it is unset before both the probe and bats (`scripts/run-tests.sh:408`), and E1 Mc (no unset) fails test 27. It does not cover `$PARALLEL_CSH`, which parallel also reads as options and the runner leaves set. Config files are covered separately (Claim 10).

parallel reads options from two environment variables:

```perl
# /usr/bin/parallel:3361-3368 (excerpt; read_options continues to :3381 — read)
	# Add options from shell variable $PARALLEL
	if($ENV{'PARALLEL'}) {
	    push @ARGV_env, shell_words($ENV{'PARALLEL'});
	}
	# Add options from env_parallel.csh via $PARALLEL_CSH
	if($ENV{'PARALLEL_CSH'}) {
	    push @ARGV_env, shell_words($ENV{'PARALLEL_CSH'});
	}
```

E2: `PARALLEL_CSH=--dry-run parallel echo ::: x` printed `echo x` (dry run). The precise version: "It unsets $PARALLEL, so options in $PARALLEL do not reach bats' run". `$PARALLEL_CSH` is set only by env_parallel under csh, so this gap is narrow.

**Evidence:** `scripts/run-tests.sh:408`, `/usr/bin/parallel:3318-3368`, fc-p3-r1/E2-plain-probe.log, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-author

---

## Claim 10: "parallel's config files (~/.parallel/config, ~/.parallelrc, /etc/parallel/config and the like) still apply"

**Location:** `scripts/run-tests.sh:98-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the files parallel reads on bats' call. "And the like" also covers `$PARALLEL_HOME/config`, `$XDG_CONFIG_HOME/parallel/config` and `$XDG_CONFIG_DIRS`. `/etc/parallel/config` was not written (root-owned); it is established from source only.

```perl
# /usr/bin/parallel:3318-3323 (excerpt; read_options continues to :3381 — read)
    if(not $opt::plain) {
	# Add options from $PARALLEL_HOME/config and other profiles
	my @config_profiles = (
	    "/etc/parallel/config",
	    (map { "$_/config" } @Global::config_dirs),
	    $ENV{'HOME'}."/.parallelrc");
```

bats' call carries no `--plain` (`/usr/libexec/bats-core/bats-exec-suite:420`). In E4, `--dry-run`, `--no-such-option`, `--tag`, `--retries 2` and `--ungroup` in `~/.parallel/config` each changed bats' run.

**Evidence:** `/usr/bin/parallel:2838-2849`, `/usr/bin/parallel:3318-3323`, `/usr/libexec/bats-core/bats-exec-suite:420`, fc-p3-r1/E4-config-fail-closed.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11a: "one that breaks the run fails closed: bats reports fewer tests run than expected and exits 1"

**Location:** `scripts/run-tests.sh:99-100`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the four breaking configs probed (`--dry-run`, an unknown option, `--tag`, `--retries 2`). It does not establish that no config can break a run while keeping the TAP count right. `--ungroup` keeps the count and only reorders output (Claim 12).

```bash
# /usr/lib/bats-core/validator.bash:29-32 (excerpt; bats_test_count_validator continues to :37 — read)
    if [[ "${actual_number_of_tests}" != "${expected_number_of_tests}" ]]; then
      printf '# bats warning: Executed %s instead of expected %s tests\n' "$actual_number_of_tests" "$expected_number_of_tests"
      return 1
    fi
```

The validator counts only lines that begin `ok ` or `not ok` (`:19-26`). E4 printed `Executed 0 instead of expected 3` for dry-run, the unknown option and `--tag` (which prefixes every line with the file name), and `Executed 1 instead of expected 3` for `--retries 2` (the retried file failed on `Failed to create BATS_FILE_TMPDIR`). Each run exited 1.

**Evidence:** `/usr/lib/bats-core/validator.bash:3-37`, `/usr/libexec/bats-core/bats:455-466`, fc-p3-r1/E4-config-fail-closed.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11b: "and --failed refuses that log."

**Location:** `scripts/run-tests.sh:100-101`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four breaking configs in E4. `--failed` refuses only when the run log itself falls short. A config that stops tests from running (dry-run, unknown option) leaves no log lines. A config that only garbles bats' TAP output (`--tag`) or breaks a retry (`--retries`) leaves a complete log, and `--failed` accepts it. It does not establish any wrong result from the accepted logs: in E4 they were accurate.

In E4, `--tag`'s run exited 1 with the log holding all 3 result lines (`passed … test_a1`, `passed … test_b1`, `failed … test_a2_once`). `--failed` then re-ran `a2 once` and exited 0. `--retries 2` behaved the same. For `--dry-run` and `--no-such-option`, `--failed` exited 1 (`no recorded run`). The completeness check compares log lines with `expected=`, not with bats' TAP count (paraphrased — no quote available because the check spans `scripts/run-tests.sh:238-262` and was quoted and verdicted in r3 Claim 13). The precise version: "…and exits 1; when tests did not run, --failed also refuses that log."

**Evidence:** `scripts/run-tests.sh:238-262`, fc-p3-r1/E4-config-fail-closed.log
**Legibility-target:** for-author

---

## Claim 12: "bats keeps each file's output together (parallel groups output by default) and in file order (--keep-order), so a file's results appear once it and every file before it have ended."

**Location:** `scripts/run-tests.sh:102-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers parallel's default and bats' `--keep-order`. It does not hold under a config file with `--ungroup`: in E4, output then read `ok 1 a1`, `ok 3 b1`, `not ok 2 a2 once`. Claim 10's sentence tells the reader such files apply, but this sentence does not name the exception. Unchanged since r3 Claim 12.

`parallel --keep-order --jobs "$num_jobs" …` (`/usr/libexec/bats-core/bats-exec-suite:420`). Grouping is the default unless `--ungroup`/`--line-buffer` is set (r3 Claim 12, `/usr/bin/parallel:1744-1755`, `:3713`). E4 "none": `ok 1 a1`, `not ok 2 a2 once`, `ok 3 b1` in file order.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, `/usr/bin/parallel:1744-1755`, fc-p3-r1/E4-config-fail-closed.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "Every test still writes its own run-log line, so the run log, the test-count check and --failed work as in a serial run."

**Location:** `scripts/run-tests.sh:104-106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers default-config parallel runs, including a `--failed` run that itself goes through parallel. It does not cover runs under a breaking config (Claim 11b).

E1 M0: test 23 passes. It asserts `expected=5` and 5 `passed|failed` lines after `--jobs 2`, then `1..2` and a logged `--jobs 2 .*--no-parallelize-within-files` for `--failed --jobs 2` (`test/scripts/run-tests.bats:385-399`). E4 "none": 3 log lines for `expected=3`.

**Evidence:** `test/scripts/run-tests.bats:380-405`, fc-p3-r1/E1-mutants.log, fc-p3-r1/E4-config-fail-closed.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "bats folds parallel's stderr into its output; the locale pin above keeps perl's setlocale warnings out of it, and upstream parallel prints its citation notice only when its stderr is a terminal, which inside bats it never is (Debian's build never prints it)."

**Location:** `scripts/run-tests.sh:106-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `2>&1`, the locale test, the notice's terminal test and Debian's commented-out call. It does not cover parallel's usage text: on an option error (for example a bad config file), `die_usage` prints a separate "Academic tradition requires you to cite…" paragraph regardless of the terminal (E4 unknown-option case).

`… ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1` (`/usr/libexec/bats-core/bats-exec-suite:420`). `citation_notice` skips when `not -t $Global::original_stderr` (`/usr/bin/parallel:5641`), and its only call is commented out: `2578:#    citation_notice();` (E7). E1 M0: test 25 passes (`! grep -iE 'perl|setlocale|cite|citation'`).

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, `/usr/bin/parallel:2578`, `/usr/bin/parallel:5632-5645`, fc-p3-r1/E7-debian-divert-citation.log, fc-p3-r1/E4-config-fail-closed.log, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "At most 3 digits, so the value never overflows bash arithmetic and parallel never sizes thousands of job slots."

**Location:** `scripts/run-tests.sh:137-138`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex bound (≤ 999, quoted in Claim 1) and that `1000` is rejected. It does not claim to be the only bound: the lowering at `:406` also caps parallel's slots at the file count.

`^[1-9][0-9]{0,2}$` admits at most 999, which is far below bash's 64-bit arithmetic limit, and E6 rejected `1000` with exit 2 and made no `parallel` call.

**Evidence:** `scripts/run-tests.sh:139`, `scripts/run-tests.sh:406`, fc-p3-r1/E6-values-and-combos.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "N is first lowered to the file count, so a one-file run needs no parallel."

**Location:** `scripts/run-tests.sh:402-403`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order (lowering at `:406` before the check at `:407`) and a one-selected-file run making no `parallel` call. The test-free run-log anchor is still handed to bats as a second file, but without `--jobs` bats runs serially. It does not establish behavior for zero files, which exits earlier (`:384-387`).

Block quoted in Claim 8. E6: `--slow --jobs 2` (one file) printed `1..1`, `ok 1 c1`, exit 0, with no `parallel` call logged. E1c: removing the lowering fails test 26 only.

**Evidence:** `scripts/run-tests.sh:384-387`, `scripts/run-tests.sh:406-414`, fc-p3-r1/E6-values-and-combos.log, fc-p3-r1/E1c-mutant-Mf.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "Otherwise bats aborts without GNU parallel, so that is what is checked"

**Location:** `scripts/run-tests.sh:403-404`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what bats does when N > 1 and GNU parallel is absent. The mechanism is imprecise: bats aborts only when no `parallel` exists at all. With a non-GNU one it does not abort, but runs it and executes no tests. Checking for GNU is the right conclusion either way.

bats' test is `if ! type -p parallel >/dev/null …` (`/usr/libexec/bats-core/bats-exec-suite:100`, quoted in Claim 6). E8: a non-GNU `parallel` gave `Executed 0 instead of expected 2 tests`, exit 1, not the abort. The precise version: "Otherwise bats aborts without a parallel and fails with any but GNU's, so GNU parallel is what is checked".

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-108`, fc-p3-r1/E8-bats-nongnu-parallel.log
**Legibility-target:** for-author

---

## Claim 18: "the first `parallel` on PATH, the one bats runs"

**Location:** `scripts/run-tests.sh:404-405`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the name lookup of both calls. It does not cover a PATH that changes between the runner's probe and bats' call; the runner does not change PATH.

The runner calls bare `parallel` (`scripts/run-tests.sh:409`) and so does bats (`parallel --keep-order …`, `/usr/libexec/bats-core/bats-exec-suite:420`). Both resolve through PATH. The shim tests rely on this and pass (E1 M0).

**Evidence:** `scripts/run-tests.sh:409`, `/usr/libexec/bats-core/bats-exec-suite:420`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "with --plain so the user's parallel config cannot fail the check."

**Location:** `scripts/run-tests.sh:405`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers config files at `~/.parallel/config`, `~/.parallelrc`, `$XDG_CONFIG_HOME/parallel/config` and `$PARALLEL_HOME/config`; `/etc/parallel/config` is covered from source only (same list, Claim 10). `--plain` also skips `$PARALLEL` and `$PARALLEL_CSH`. It does not cover non-config environment that fails the probe (`PARALLEL_SHELL`, Claim 8).

`--plain` gates the whole profile/env block: `if(not $opt::plain) {` (`/usr/bin/parallel:3318`). It is read from a copy of argv first, in any position (`get_options_from_array(\@ARGV_copy,"profile|J=s","plain")`, `:3315`). E2: for each of the four locations, `parallel --version` exited 255 (`Unknown option: no-such-option`), while `--plain --version` and `--version --plain` exited 0 (`GNU parallel 20221122`). E1 Mb (`--plain` dropped) fails test 28.

**Evidence:** `/usr/bin/parallel:3313-3381`, `scripts/run-tests.sh:409`, fc-p3-r1/E2-plain-probe-bash.log, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: warning "--jobs $jobs needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially"

**Location:** `scripts/run-tests.sh:412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two stated causes, and it closes r3 Claim 27's residue: `$PARALLEL` and config files no longer reach the probe (Claims 9 and 19, and test 27's `!= *"running serially"*`). It does not cover a GNU parallel failing on an unusable `PARALLEL_SHELL` (E3), which still prints this text.

Quoted in Claim 8. E1 M0 tests 29 and 30 assert the text.

**Evidence:** `scripts/run-tests.sh:412`, fc-p3-r1/E1-mutants.log, fc-p3-r1/E3-env-probe.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: "parallel_shim: put a `parallel` first on PATH that logs its arguments to $T/parallel.args and execs the real one. The runner's own --version check is logged too, so a test that wants to see bats used parallel greps for the --no-parallelize-within-files it hands bats."

**Location:** `test/scripts/run-tests.bats:329-332`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shim body and what its log holds. It does not establish that the grep proves tests ran. The shim logs before `exec`, so a line is written even when the real parallel then dies (for example in test 28).

```bash
# test/scripts/run-tests.bats:333-342 (parallel_shim, complete)
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

E6's equivalent shim logged `--plain --version`, then `--keep-order --jobs 2 bats-exec-file --dummy-flag -j 2 --no-parallelize-within-files …`. Only bats' call carries the flag.

**Evidence:** `test/scripts/run-tests.bats:329-342`, fc-p3-r1/E6-values-and-combos.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: test "--jobs: a missing, zero, non-numeric or 4-digit N is a usage error"

**Location:** `test/scripts/run-tests.bats:344-358`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four value classes named. The leading-zero and negative cases are not in the test; E6 covers them.

The test asserts `[ "$status" -eq 2 ]` for `--jobs` with no value, `0`, `x` and `1000`. E1 M0 test 20 passes.

**Evidence:** `test/scripts/run-tests.bats:344-358`, fc-p3-r1/E1-mutants.log, fc-p3-r1/E6-values-and-combos.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: test "--jobs 2 runs files through parallel, not tests within a file"

**Location:** `test/scripts/run-tests.bats:360-370`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arguments bats handed parallel, as a proxy for serial-within-file (settled override row 172). It does not observe tests within a file running one at a time.

`grep -q -- '--jobs 2 .*--no-parallelize-within-files' "$T/parallel.args"` (`:369`). E1b Me (bats never given `--jobs`) fails test 21.

**Evidence:** `test/scripts/run-tests.bats:360-370`, fc-p3-r1/E1b-mutant-Me.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: test "--jobs 1 runs serially and needs no parallel"

**Location:** `test/scripts/run-tests.bats:372-378`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `--jobs 1` over two files (so N is not lowered) makes no `parallel` call and passes. "Needs no parallel" is shown as "calls no parallel" while one is on PATH. The test does not remove parallel from PATH.

`runner --jobs 1 test/gamma.bats test/sub/beta.bats` then `[ ! -f "$T/parallel.args" ]` (`:374-377`). With `jobs=1` the `:407` branch, probe included, is skipped. E1 M0 test 22 passes.

**Evidence:** `test/scripts/run-tests.bats:372-378`, `scripts/run-tests.sh:407`, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: test "--jobs: a parallel run records a complete log that --failed re-runs from" and comment "A second file that fails until $T/fixed exists, so --failed re-runs two files and stays parallel."

**Location:** `test/scripts/run-tests.bats:380-405`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the complete log after `--jobs 2` and a `--failed --jobs 2` that goes through parallel. This closes r3 Claim 22's residue.

`fixture delta.bats fast '@test "delta flaky" { [ -f "$BATS_TEST_DIRNAME/../fixed" ]; }'` (`:384`), then after `rm "$T/parallel.args"` and `runner --failed --jobs 2` the test asserts `1..2` and `grep -q -- '--jobs 2 .*--no-parallelize-within-files'` (`:392-399`). E1b Me fails test 23.

**Evidence:** `test/scripts/run-tests.bats:380-405`, fc-p3-r1/E1b-mutant-Me.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: test "--jobs: a parallel run killed partway is refused by --failed"

**Location:** `test/scripts/run-tests.bats:407-421`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the TERM exit (143) and `--failed`'s refusal. This test is unchanged since r3. It does not grep for a parallel call, so on its own it does not show the killed run was parallel.

E1 M0 test 24 passes.

**Evidence:** `test/scripts/run-tests.bats:407-421`, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: test "--jobs: an uninstalled locale leaves no perl or citation text in the output" (with `grep -q -- '--no-parallelize-within-files'` and the comment "gamma asserts its own subprocess output is clean; the suite-level output must be clean too.")

**Location:** `test/scripts/run-tests.bats:423-433`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parallel path under an uninstalled LANG. This closes r3 Claim 25: a serial fallback now fails the test. It does not cover the usage-text citation paragraph (Claim 14 residue).

`grep -q -- '--no-parallelize-within-files' "$T/parallel.args"` (`:428`). E1b Me fails test 25.

**Evidence:** `test/scripts/run-tests.bats:423-433`, fc-p3-r1/E1b-mutant-Me.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28: test "--jobs above the file count is lowered to it"

**Location:** `test/scripts/run-tests.bats:435-440`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 999 lowered to 2 for two files.

`runner --jobs 999 test/gamma.bats test/sub/beta.bats` then `grep -q -- '--jobs 2 .*--no-parallelize-within-files'` (`:437-439`). E1c Mf (no lowering) fails test 26 and nothing else.

**Evidence:** `test/scripts/run-tests.bats:435-440`, fc-p3-r1/E1c-mutant-Mf.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29a: test "--jobs: the user's PARALLEL options neither reach bats' parallel nor fail the check"

**Location:** `test/scripts/run-tests.bats:442`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both behaviors of the current code: bats' parallel runs all 4 tests despite `PARALLEL="--dry-run --no-such-option"`, and no serial warning appears. It does not establish that the "nor fail the check" assertion depends on where `unset PARALLEL` sits. `--plain` alone already keeps `$PARALLEL` out of the check (Claim 29b).

The test asserts `1..4`, `ok … beta steady`, `!= *"running serially"*` and the grep (`:447-451`). E1 Mc (no unset) and Md fail test 27.

**Evidence:** `test/scripts/run-tests.bats:442-452`, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29b: comment "--dry-run would run no test at all; an unknown option would fail the --version check and make the run serial."

**Location:** `test/scripts/run-tests.bats:444-445`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The first half (`--dry-run` would run no test) is right (E4 dry-run: `Executed 0`). This verdict is carried by the second half, about the runner's check as written. It does not claim the test is useless: it still catches a missing unset (Mc).

The runner's check is `parallel --plain --version` (`scripts/run-tests.sh:409`), and `--plain` skips `$PARALLEL` (`/usr/bin/parallel:3318`). E2: `PARALLEL=--no-such-option parallel --plain --version` → `GNU parallel 20221122`. So an unknown option in `$PARALLEL` cannot fail the check even when it is not unset. E1 Ma (unset moved after the probe) passes all 30 tests, test 27 included. A reader would take the comment to mean the test pins the unset-before-check order, and it does not. The precise version: "an unknown option would make bats' parallel die (the check ignores it: --plain)".

**Evidence:** `scripts/run-tests.sh:408-409`, `/usr/bin/parallel:3313-3368`, fc-p3-r1/E2-plain-probe.log, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-author

---

## Claim 30: test "--jobs: a parallel config file cannot fail the GNU parallel check"

**Location:** `test/scripts/run-tests.bats:454-463`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `~/.parallel/config` with an unknown option. The test asserts no exit status, so it does not show the fail-closed outcome of the run that follows.

`echo '--no-such-option' > "$BATS_TEST_TMPDIR/home/.parallel/config"`, `HOME="$BATS_TEST_TMPDIR/home"`, then `!= *"running serially"*` and the grep (`:457-462`). E1 Mb (`--plain` dropped) fails test 28.

**Evidence:** `test/scripts/run-tests.bats:454-463`, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 31: tests "--jobs with a non-GNU parallel first on PATH warns and runs serially" and "--jobs without GNU parallel on PATH warns and runs serially" (with the comment "A PATH holding everything the current one does except parallel (and bats' libexec directory, which in_runner drops too).")

**Location:** `test/scripts/run-tests.bats:465-499`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both fallbacks. These tests are unchanged since r3 Claim 28, which mutation-checked them (M4). This pass re-ran only M0.

The PATH loop links every executable except `parallel` and skips `$BATS_LIBEXEC` (`:483-488`), and `command -v parallel ||` guards the run (`:491`). E1 M0 tests 29 and 30 pass.

**Evidence:** `test/scripts/run-tests.bats:465-499`, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 32: 78b3b08: "PARALLEL_HOME did not isolate parallel's config: parallel still reads ~/.parallel/config, ~/.parallelrc, $XDG_CONFIG_HOME/parallel/config and /etc/parallel/config. The export is removed"

**Location:** commit `78b3b08` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers parallel's config search and the removal. It does not re-verdict 084868f (settled, row 174).

The config list is quoted in Claim 10. `grep -n PARALLEL_HOME scripts/run-tests.sh` returns nothing at HEAD. E2 read an unknown option from each of the four named locations except `/etc` (root-owned; source only).

**Evidence:** `/usr/bin/parallel:2838-2849`, `/usr/bin/parallel:3318-3323`, fc-p3-r1/E2-plain-probe-bash.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 33: 78b3b08: "the header now says config files still apply and a breaking one fails closed (bats' count check, then --failed refuses the log). Corrects 084868f's body."

**Location:** commit `78b3b08` message
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The header does say this (Claims 10–11b), and the bats count check holds. "Then --failed refuses the log" holds only when tests did not run, as in Claim 11b.

E4: after `--tag` and `--retries 2` configs, `--failed` accepted the complete log and re-ran the failure (exit 0). History is immutable, so a correction would go in the next fix commit's body.

**Evidence:** `scripts/run-tests.sh:98-101`, fc-p3-r1/E4-config-fail-closed.log
**Legibility-target:** for-author

---

## Claim 34: 78b3b08: "`unset PARALLEL` ran after the GNU check, so an unparsable $PARALLEL made the runner warn "not GNU parallel" and run serially. It now runs first, and the check uses `parallel --plain --version` so a config file cannot fail it either (+ tests for both)."

**Location:** commit `78b3b08` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old order, the new order, `--plain`, and one test per input (27 for `$PARALLEL`, 28 for a config file). It does not establish that test 27 depends on the new order (Claim 29b).

At b34a6fe the check came first: `406: if [[ "$(parallel --version 2>/dev/null)" == "GNU parallel"* ]]; then` / `407: unset PARALLEL` (`git show b34a6fe:scripts/run-tests.sh`). E2: `PARALLEL=--no-such-option parallel --version` → `Unknown option`. At HEAD the order is unset (`:408`), then the `--plain` check (`:409`).

**Evidence:** `scripts/run-tests.sh:408-409`, fc-p3-r1/E2-plain-probe.log, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 35: 78b3b08: "install-host.bats' exposure: agent_gate refuses on a live process whose working directory procs_in_checkout cannot read (e.g. non-dumpable); exiting processes are skipped, so "starting and ending" was wrong."

**Location:** commit `78b3b08` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal and the skip of processes that exited (empty cmdline). It does not rule out a process that is mid-exec into a setuid binary, which was not probed.

`[ -n "$cmd" ] || continue                   # exited, or a kernel thread` (`devcontainer-config/install.sh:1179`), quoted in context in Claim 5. E5 T92 passes.

**Evidence:** `devcontainer-config/install.sh:1171-1181`, fc-p3-r1/E5-install-host-T91-T92.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 36: 78b3b08: "The health-check.bats cache example was weak (written in setup_file, only read after); the header now says within-file serial is simply the only way the suites have run. "N above the core count buys nothing" was unmeasured and is dropped. The stale "not the file count" comment now says N is lowered to the file count first, so a one-file run needs no parallel."

**Location:** commit `78b3b08` message
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the three header/comment edits are present at HEAD. The cache-example assessment was r3 Claim 3's finding and is not re-verdicted.

`git diff b34a6fe 78b3b08 -- scripts/run-tests.sh` removes `health-check.bats caches…`, `N above the core count buys nothing` and `Test for GNU parallel itself, not the file count`, and adds `the only way the suites have ever run` (`scripts/run-tests.sh:87`) and `N is first lowered to the file count` (`:402`).

**Evidence:** `scripts/run-tests.sh:85-93`, `scripts/run-tests.sh:402-405`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 37a: 78b3b08: "Tests: the shim's args file now also holds the runner's --version call, so tests grep for --no-parallelize-within-files instead of the file's existence; the --failed re-run covers two files so it stays parallel."

**Location:** commit `78b3b08` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grep changes and the two-file `--failed` re-run. Test 21 still also asserts `[ -f "$T/parallel.args" ]` (`:368`), which is now redundant but harmless.

See Claims 21, 25 and 27. E1b Me fails tests 21, 23, 25, 26, 27 and 28.

**Evidence:** `test/scripts/run-tests.bats:368-369`, `test/scripts/run-tests.bats:392-399`, `test/scripts/run-tests.bats:428`, fc-p3-r1/E1b-mutant-Me.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 37b: 78b3b08: "Mutants (unset moved back, --plain dropped, bats never given --jobs) each fail their test."

**Location:** commit `78b3b08` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** "--plain dropped" (Mb fails 28) and "bats never given --jobs" (Me fails 6 tests) reproduce. "Unset moved back" does not: with `--plain` kept, no test fails. The claim holds only for a mutant that moves the unset back *and* drops `--plain` (Md fails 27 and 28), or one that deletes the unset (Mc fails 27).

E1 Ma moves `unset PARALLEL` after the probe, into the GNU branch (`diff`: `408d407 <   unset PARALLEL` / `409a409 >     unset PARALLEL`). It ran 30/30 ok, exit 0. The cause is Claim 29b: `--plain` already keeps `$PARALLEL` out of the check, and the unset still precedes bats. History is immutable. What could change: correct the record in the next commit body, or drop the "unset first" rationale, since `--plain` covers it. No test can pin the order while `--plain` is there.

**Evidence:** `scripts/run-tests.sh:408-409`, fc-p3-r1/E1-mutants.log
**Legibility-target:** for-author

---

## Claim 38: 78b3b08 Notes: "bats passes no --plain"

**Location:** commit `78b3b08` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers bats 1.8.2's only `parallel` call. The HOME-override rationale that follows is design rationale and is not checked.

`parallel --keep-order --jobs "$num_jobs" bats-exec-file "$(printf "%q " "${flags[@]}")" "{}" "$TESTS_LIST_FILE" ::: …` (`/usr/libexec/bats-core/bats-exec-suite:420`) has no `--plain`.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 29b** (`test/scripts/run-tests.bats:444-445`): "an unknown option would fail the --version check". The check is `--plain --version`, which ignores `$PARALLEL`. Mutant Ma (unset after the probe) passes all 30 tests. Reword to say the option would make bats' parallel die.
- **Claim 37b** (commit 78b3b08): "unset moved back" does not fail any test (Ma 30/30 ok). History is immutable; correct it in the next commit body if one follows.

### Mostly Accurate
- **Claim 9** (`scripts/run-tests.sh:96-97`): `$PARALLEL_CSH` also carries options into bats' run. Say "options in $PARALLEL".
- **Claim 11b** (`scripts/run-tests.sh:100-101`): `--failed` refuses only when tests did not run. With `--tag` or `--retries` configs the log is complete and `--failed` re-runs from it (correctly).
- **Claim 17** (`scripts/run-tests.sh:403-404`): bats aborts without *any* parallel. With a non-GNU one it runs it and executes no tests (E8).
- **Claim 33** (commit 78b3b08): same as Claim 11b.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path named below, structured per the skill.
- Answered: yes. All five priority groups were verdicted: 41 claims (11, 29 and 37 split into a/b), 36 of them by execution (10 probes, including 6 mutants of the runner against run-tests.bats).
- Out of scope: running install-host.bats in full or the full suite under `--jobs` (barred by the brief; only T91/T92 ran); `/etc/parallel/config` (root-owned); upstream (non-Debian) parallel.
- Escalate: none is blocking-grade. No verdict shows a wrong result or a false pass: every breaking config probed made the run exit 1. The two Incorrects are a test comment and a commit-body verification claim about the redundant `unset`-before-check order. Two notes for the orchestrator. First, r3's Claim 27 residue (config/`$PARALLEL` triggering a false "not GNU parallel") is closed, but `PARALLEL_SHELL` can still trigger it (E3). Second, r3's Claim 9b (moreutils) is now Verified via Debian's dpkg diversion.
- Decisions I made: kept the execution logs in the session scratchpad (`…/scratchpad/run-tests-jobs/fc-p3-r1/`) and did not touch `docs/reviews/execution-logs/` or the hallucination-pattern log, because the brief allows edits to this report only. Rated Claim 11b Mostly accurate, not Incorrect: the refuted part is a missing qualifier, and the logs `--failed` accepted were complete and accurate. Rated Claim 29b Incorrect because its stated mechanism is refuted for the check as written, so a reader would wrongly think the test pins the unset order.
