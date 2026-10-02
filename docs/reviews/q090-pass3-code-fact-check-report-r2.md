# Code Fact-Check Report

**Commit:** ff99d86
**Replication:** pass 3, r2
**Repository:** /workspace/.claude/wt-run-tests-jobs (branch feat/run-tests-jobs)
**Scope:** `git diff main...HEAD -- scripts test` (scripts/run-tests.sh: the `--jobs` Flags entry, the "Parallel runs" header paragraph, the `--jobs` parse comment, the comment block above the lowering/GNU check; test/scripts/run-tests.bats: `parallel_shim` and the 11 `--jobs` tests), plus the body of commit 78b3b08. `scripts/` and `test/` are identical at 78b3b08 and HEAD ff99d86 (`git diff --stat 78b3b08 ff99d86 -- scripts test` is empty). Claims were checked against the code that runs them: bats 1.8.2 (`/usr/libexec/bats-core/{bats,bats-exec-suite,bats-exec-file}`, `/usr/lib/bats-core/validator.bash`), GNU parallel 20221122 (`/usr/bin/parallel`, Debian), and `devcontainer-config/install.sh` (`procs_in_checkout`, `agent_gate`). The bodies of earlier commits are settled (override-log rows dated 2026-09-30) and are not verdicted again.
**Checked:** 2026-09-30
**Total claims checked:** 40
**Summary:** 31 verified, 5 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`). No claim matches a logged pattern, and none of the four Incorrect verdicts is a fabricated symbol, option or API. All four describe real mechanisms, so nothing new is logged. I also read the settled override-log rows for `feat/run-tests-jobs` (2026-09-30) and do not re-raise them. Claim 17 is the settled "claim 12" proxy, recorded only as Verified-with-residue.

**Probes.** Every probe ran under `timeout` with `LC_ALL=C.UTF-8`, against throwaway copies of the runner and fixtures or copies of run-tests.bats. None ran against the real suite, and none passed `--jobs` above 999; the only 999 was a parse/lowering probe on one or two files. Raw output is in `/tmp/claude-1000/-workspace/21797f19-046e-4351-9c55-0471f4b3d3b6/scratchpad/run-tests-jobs/fc-p3r2/` (written `fc-p3r2/` below). The brief says to edit only this report, so the logs were not copied into `docs/reviews/execution-logs/`. After the probes, `ps -eo pid,args | grep -F fc-p3r2` found no process left over.

| Probe | Command (summary) | cwd | Exit | UTC |
|---|---|---|---|---|
| P1 | `timeout 500 bats test/scripts/run-tests.bats` (unmutated) | worktree root | 0 (30/30 ok) | 22:04:43Z |
| P2 | `parallel [--plain] --version` under `PARALLEL=--no-such-option`, `~/.parallel/config`=`--no-such-option`, `PARALLEL_CSH=--no-such-option`; `dpkg -S /usr/bin/parallel` | fc-p3r2 | 255 without `--plain`, 0 with | 22:04:44Z |
| P3 | `p3.sh`: runner `--jobs 2`, then `--failed`, with `~/.parallel/config` holding `--dry-run`, `--tag`, `--retries 2`, `--halt now,fail=1` or `-j 1` | fc-p3r2 | per case in log | 22:04:58Z–22:05:06Z |
| P4 | `timeout 200 bats --filter '^--jobs' test/scripts/run-tests.bats` on M0 (unmutated), MA (`unset` moved back after the check, `--plain` kept), MB (`--plain` dropped), MC (`unset` removed), MD (both: the pre-78b3b08 check), ME (GNU check → `false`), MF (bats never given `--jobs`); diffs in `fc-p3r2/mut-*.diff` | fc-p3r2/mut-* | M0 0, MA 0, others 1 | 22:06:25Z–22:06:53Z |
| P5 | `p5.sh`: 20 `--jobs` values; `--fast --jobs 2`; `--jobs 5` on one file with no `parallel` on PATH; `PARALLEL_CSH=--dry-run` and `PARALLEL=--dry-run` under `--jobs 2` | fc-p3r2 | 0 | 22:08:11Z |
| P6 | `p6.sh`: `bats --jobs 2` on one file with no `parallel`, and on two files with a moreutils-like fake first; `LANG=xx_XX.UTF-8 parallel --plain --version`; `parallel --keep-order` grouping/order timing | fc-p3r2 | 0 | 22:08:34Z |
| P7 | T24 copy with an added `cat`/`grep` of `$T/parallel.args` | fc-p3r2/mut-T24probe | 0 | 22:09:16Z |
| P8 | `timeout 120 bats --filter '^T92 ' test/install-host.bats`; bash arithmetic overflow without the 3-digit cap | worktree root; fc-p3r2 | 0 | 22:10:15Z |

---

## Claim 1: "--jobs N  Run up to N test files at once (see "Parallel runs"). N is 1 to 999, digits only, no leading zero; anything else is a usage error (exit 2). 1, the default, runs serially; N above the number of selected files is lowered to it. Combines with every other flag, --failed included."

**Location:** `scripts/run-tests.sh:36-40`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the accepted value set, the exit 2, the default of 1, lowering N to the selected-file count, and combining `--jobs` with `--fast`, FILE and `--failed`. It does not establish combinations with `--slow`/`--all`, which were not probed with `--jobs`, but the parser handles them independently.

```bash
# scripts/run-tests.sh:136-146
    --jobs)
      # At most 3 digits, ...
      if [[ ! "${2:-}" =~ ^[1-9][0-9]{0,2}$ ]]; then
        echo "--jobs takes a number from 1 to 999, got: ${2:-(nothing)}" >&2
        usage
        exit 2
      fi
      jobs="$2"
      shift 2
      ;;
```

`jobs=1` is the default (`scripts/run-tests.sh:127`). Lowering is at `:406`: `(( jobs > ${#files[@]} )) && jobs=${#files[@]}`.

- P5a: `''`, `0`, `00`, `007`, `01`, `1000`, `x`, `-3`, `+5`, `' 5'`, `'5 '`, `$'5\n'`, `٣`, `1e2`, `0x10` and a missing value all exited 2 and printed `got: …`. `1`, `9`, `10` and `999` ran gamma (exit 0).
- P5b: `--fast --jobs 2` ran the fast files (`1..3`).
- P1: T23 (`--failed --jobs 2`) and T26 (999 lowered to 2) pass.

**Evidence:** `scripts/run-tests.sh:127`, `scripts/run-tests.sh:136-146`, `scripts/run-tests.sh:406`, fc-p3r2/P5-parse-combos.log, fc-p3r2/P1-suite.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "--jobs N (N > 1) hands bats `--jobs N --no-parallelize-within-files`, so whole files run side by side and the tests within a file stay serial"

**Location:** `scripts/run-tests.sh:85-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arguments handed to bats when the GNU check passes, and bats running files as parallel jobs with each file serial inside. It does not establish anything about the serial fallback (Claims 6-7).

`scripts/run-tests.sh:410`: `bats_args+=(--jobs "$jobs" --no-parallelize-within-files)`. bats-exec-suite:420 runs `parallel --keep-order --jobs "$num_jobs" bats-exec-file … ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}"`, one job per file. bats-exec-file:294 parallelizes within a file only when `"${BATS_NO_PARALLELIZE_WITHIN_FILE-False}" == False`. The flag sets it at `bats-exec-file:24-26`. P7 logged `--keep-order --jobs 2 bats-exec-file --dummy-flag -j 2 --no-parallelize-within-files …`.

**Evidence:** `scripts/run-tests.sh:407-414`, `/usr/libexec/bats-core/bats-exec-suite:415-420`, `/usr/libexec/bats-core/bats-exec-file:24-26`, `/usr/libexec/bats-core/bats-exec-file:294`, fc-p3r2/P7-T24-parallel.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "the only way the suites have ever run: no suite has been checked for tests that interfere when run at once"

**Location:** `scripts/run-tests.sh:87-88`
**Type:** Behavioral (history)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers how the repo's runners (run-tests.sh, health-check) and CI-style paths have run the suites. It does not establish the absence of ad-hoc manual runs, and one such run is on record.

No script in the repo ever passed `--jobs` to bats before this branch. `git log --all -S'--jobs' -- scripts test` lists only this branch's three commits. The user did run one file with within-file parallelism, though:

```
# docs/human-author/answers-9-30-26.txt:23
$ bats --jobs 2 test/agents-gemini-sync.bats 2>&1 | grep -iE 'cite|locale'
```

That run had no `--no-parallelize-within-files`, so agents-gemini-sync.bats' tests ran two at a time. It was a one-off check of output text (`grep -iE 'cite|locale'`), not a check for interference, so the second half of the sentence holds. A precise version would say "the only way the runner has ever run the suites".

**Evidence:** `docs/human-author/answers-9-30-26.txt:23`, `docs/working/questions.md:109`
**Legibility-target:** for-author

---

## Claim 4: "The slowest file bounds the speedup."

**Location:** `scripts/run-tests.sh:88-89`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the structural bound: each file is one serial parallel job, so wall time is at least the slowest file's time. It does not establish the measured speedup figures.

(paraphrased — no quote available because this follows from Claim 2's quoted mechanism: one `parallel` job per file at bats-exec-suite:420, serial within a file per bats-exec-file:294.) The wall time can never be shorter than the longest single job.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, `/usr/libexec/bats-core/bats-exec-file:294`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: "Files still share the machine: install.sh's agent_gate, which install-host.bats runs, refuses when procs_in_checkout cannot read the working directory of a live process of the user (a non-dumpable one, say), and under --jobs other files' processes are live beside it."

**Location:** `scripts/run-tests.sh:89-93`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's refusal on an unreadable cwd, including a non-dumpable process, and that install-host.bats runs the real `/proc` scan. It does not establish that any other test file actually spawns a process with an unreadable cwd. None was found (`prctl` appears only in install-host.bats:1597-1598), so the exposure is latent.

```bash
# devcontainer-config/install.sh:1170-1180 (excerpt ends :1180; enclosing procs_in_checkout() continues to :1182 — read)
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

`agent_gate` exits 1 when `$unknown` is non-empty (`install.sh:1248` returns 0 only if all lists are empty; `:1267-1271` names the unknown processes). install-host.bats stubs only `pgrep` and `docker` (`test/install-host.bats:35-42`), so the `/proc` scan is real. P8: T92, a non-dumpable same-uid process refused and named, passes here.

**Evidence:** `devcontainer-config/install.sh:1165-1182`, `devcontainer-config/install.sh:1187-1283`, `test/install-host.bats:35-42`, `test/install-host.bats:1595-1611`, fc-p3r2/P8-T92-overflow.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "bats runs files through GNU parallel and aborts without it even for one file"

**Location:** `scripts/run-tests.sh:94-95`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bats' behavior at N > 1 when `parallel` is absent (abort, any file count) and when a non-GNU `parallel` comes first (no abort). It does not affect the runner's own check (Claim 7), which handles both cases.

```bash
# /usr/libexec/bats-core/bats-exec-suite:99-101 (excerpt ends :101; enclosing if continues to :103 — read)
if [[ "$num_jobs" != 1 ]]; then
  if ! type -p parallel >/dev/null && [[ -z "$bats_no_parallelize_across_files" ]]; then
    abort "Cannot execute \"${num_jobs}\" jobs without GNU parallel"
```

bats aborts only when no `parallel` at all is on PATH. P6a (one file, no `parallel`) printed `Error: Cannot execute "2" jobs without GNU parallel` and exited 1. With a non-GNU `parallel` first on PATH, bats does not abort: it runs that program with GNU options. P6b printed `parallel from moreutils` and `# bats warning: Executed 0 instead of expected 2 tests`, exit 1. The practical conclusion holds (N > 1 needs GNU parallel). A precise version: "aborts when no parallel is on PATH, even for one file, and fails with no tests run when the first one is not GNU parallel". The same wording recurs at `:403-404` (Claim 13b). Prior passes verdicted this Verified. P6b is new evidence for the non-GNU branch.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-103`, `/usr/libexec/bats-core/bats-exec-suite:420`, fc-p3r2/P6-bats-parallel.log
**Legibility-target:** for-author

---

## Claim 7: "so when the first `parallel` on PATH is missing or is not GNU parallel (moreutils ships one too), the runner warns and runs serially"

**Location:** `scripts/run-tests.sh:95-96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both fallback branches and the moreutils aside. It does not cover a one-file run, where N is lowered to 1 first and no warning is printed (P5c, consistent with Claim 13a).

```bash
# scripts/run-tests.sh:409-413
  if [[ "$(parallel --plain --version 2>/dev/null)" == "GNU parallel"* ]]; then
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
  else
    echo "WARNING: --jobs $jobs needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially" >&2
```

P1: T29 (a fake non-GNU `parallel` first) and T30 (no `parallel`) pass and show serial results. P2: `dpkg -S` shows `diversion by parallel from: /usr/bin/parallel … to: /usr/bin/parallel.moreutils`, so moreutils' `parallel` exists on Debian.

**Evidence:** `scripts/run-tests.sh:407-414`, `test/scripts/run-tests.bats:465-497`, fc-p3r2/P1-suite.log, fc-p3r2/P2-plain-version.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "It unsets $PARALLEL, so the user's parallel options do not reach bats' run."

**Location:** `scripts/run-tests.sh:96-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers options in `$PARALLEL`. It does not establish that other ways of passing options stay out. Config files are covered by the next sentence (Claim 9a). `$PARALLEL_CSH`, which parallel also reads (`/usr/bin/parallel:3366-3368`) and the runner does not unset, does reach bats' run: P5d with `PARALLEL_CSH=--dry-run` gave `Executed 0 instead of expected 4 tests`, exit 1. env_parallel.csh sets that variable, not users directly.

`scripts/run-tests.sh:408`: `unset PARALLEL`, inside `if [[ "$jobs" -gt 1 ]]`, before the check and before the `exec bats` at `:431`. P5e with `PARALLEL=--dry-run` ran all 4 tests. P4 mutant MC (no `unset`) fails T27.

**Evidence:** `scripts/run-tests.sh:407-414`, `/usr/bin/parallel:3360-3368`, fc-p3r2/P5-parse-combos.log, fc-p3r2/P4-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9a: "parallel's config files (~/.parallel/config, ~/.parallelrc, /etc/parallel/config and the like) still apply"

**Location:** `scripts/run-tests.sh:98-99`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named files plus `$PARALLEL_HOME`, `$XDG_CONFIG_HOME/parallel` and `$XDG_CONFIG_DIRS/*/parallel` config ("and the like"). It does not establish anything about `--profile` files, which bats never passes.

```perl
# /usr/bin/parallel:3318-3323 (excerpt ends :3323; enclosing read_options() continues past :3368 — read)
    if(not $opt::plain) {
	# Add options from $PARALLEL_HOME/config and other profiles
	my @config_profiles = (
	    "/etc/parallel/config",
	    (map { "$_/config" } @Global::config_dirs),
	    $ENV{'HOME'}."/.parallelrc");
```

bats calls `parallel` without `--plain` (bats-exec-suite:420). In P3 every `~/.parallel/config` case changed bats' run.

**Evidence:** `/usr/bin/parallel:3318-3368`, `/usr/bin/parallel:2838-2849`, `/usr/libexec/bats-core/bats-exec-suite:420`, fc-p3r2/P3-fail-closed.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9b: "one that breaks the run fails closed: bats reports fewer tests run than expected and exits 1"

**Location:** `scripts/run-tests.sh:99-100`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the four breaking configs probed (`--dry-run`, `--tag`, `--retries 2`, `--halt now,fail=1`). It does not establish this for every possible config line. A config that changes the run without breaking it (`-j 1`, P3) runs every test at a different parallelism with no warning.

`/usr/lib/bats-core/validator.bash:27-31` prints `# bats warning: Executed %s instead of expected %s tests` and `return 1` when the `ok`/`not ok` count differs from the plan. In P3 the counts were: `--dry-run` Executed 0 of 4; `--tag` Executed 0 of 4 (every line tagged, so none starts `ok `); `--retries 2` Executed 2 of 4; `--halt` Executed 3 of 4. All exited 1.

**Evidence:** `/usr/lib/bats-core/validator.bash:3-37`, `/usr/libexec/bats-core/bats:456-466`, fc-p3r2/P3-fail-closed.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9c: "and --failed refuses that log."

**Location:** `scripts/run-tests.sh:100-101`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--failed` after each probed breaking config. It does not establish harm: when `--failed` accepts, the log it accepts holds a real result for every test.

`--failed` checks the run log, not bats' count:

```bash
# scripts/run-tests.sh:255-258 (excerpt ends :258; enclosing if continues to :261 — read)
  recorded="$(sed -nE 's/^(passed|failed|status-filtered [a-z]+) //p' "$RUN_LOG_DIR/$last_log" |
    awk -F'\t' 'NR == FNR { want[$0] = 1; next } ($1 in want)' <(sed '1,2d' "$LAST_RUN") - |
    sort -u | wc -l)"
  if [[ ! "$expected" =~ ^[0-9]+$ || "$recorded" -ne "$expected" ]]; then
```

A config that stops tests from running is refused. `--dry-run` left no log ("no recorded run"), and `--halt` recorded 3 of 4 and was refused. A config that only garbles or drops parallel's output leaves every test's log line in place, and `--failed` accepts that log. With `--tag`, bats said `Executed 0 instead of expected 4` and exited 1, but the log held all 4 results, and `--failed` re-ran `alpha flaky`. With `--retries 2`, alpha's retry failed (`Failed to create BATS_FILE_TMPDIR`) and bats said `Executed 2 of 4`, but the first attempt's lines made the log complete (after `sort -u`), and `--failed` again re-ran `alpha flaky`. A precise version: "--failed refuses the log when the break kept tests from running; when it only garbled the output, the log is complete and --failed re-runs from it". Commit 78b3b08 repeats the claim (Claim 27c).

**Evidence:** `scripts/run-tests.sh:237-261`, fc-p3r2/P3-fail-closed.log
**Legibility-target:** for-author

---

## Claim 10: "bats keeps each file's output together (parallel groups output by default) and in file order (--keep-order), so a file's results appear once it and every file before it have ended."

**Location:** `scripts/run-tests.sh:102-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers grouping and ordering under parallel's defaults. It does not cover a config file that sets `--ungroup`/`--line-buffer` (Claim 9a: config files apply).

bats-exec-suite:420 passes `--keep-order` and no grouping option. P6d ran `parallel --keep-order --jobs 2` with job A (1 s) listed before job B (instant). B's lines were produced at …114.759 but read after A's at …115.76+. A-1, produced at …114.757, was read only at …115.764, once A ended. That shows both grouping and order.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, fc-p3r2/P6-bats-parallel.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "Every test still writes its own run-log line, so the run log, the test-count check and --failed work as in a serial run."

**Location:** `scripts/run-tests.sh:104-106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a parallel run under parallel's defaults: a complete log (5 of 5), `--failed` re-running across two files in parallel, and a killed run refused. It does not cover runs changed by a config file (Claim 9c).

P1: T23 asserts `expected=5` and 5 result lines after `--jobs 2`, then `--failed --jobs 2` re-runs the two failures through `parallel`. T24 asserts a killed `--jobs 2` run is refused. Both pass.

**Evidence:** `test/scripts/run-tests.bats:380-421`, fc-p3r2/P1-suite.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "bats folds parallel's stderr into its output; the locale pin above keeps perl's setlocale warnings out of it, and upstream parallel prints its citation notice only when its stderr is a terminal, which inside bats it never is (Debian's build never prints it)."

**Location:** `scripts/run-tests.sh:106-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `2>&1`, perl's warning under an uninstalled locale and the pin's effect in T25, the citation notice's tty condition and Debian's commented-out call. It does not establish upstream builds' behavior by execution; that part rests on reading the same function in this build.

```perl
# /usr/bin/parallel:5632-5642 (excerpt ends :5642; enclosing citation_notice() continues past :5660 — read)
sub citation_notice() {
    # if --will-cite or --plain: do nothing
    # if stderr redirected: do nothing
    ...
    if($opt::willcite
       or
       $opt::plain
       or
       not -t $Global::original_stderr
```

`/usr/bin/parallel:2578` is `#    citation_notice();`, so the call is commented out. bats-exec-suite:420 ends `2>&1`, and bats pipes that stream into the validator (`bats:464-466`), so stderr is a pipe. P6c: `LANG=xx_XX.UTF-8 parallel --plain --version` printed `perl: warning: Setting locale failed.` P1: T25 (uninstalled `LANG`, asserts no `perl|setlocale|cite|citation`) passes.

**Evidence:** `/usr/bin/parallel:2578`, `/usr/bin/parallel:5632-5660`, `/usr/libexec/bats-core/bats-exec-suite:420`, `/usr/libexec/bats-core/bats:464-466`, fc-p3r2/P6-bats-parallel.log, fc-p3r2/P1-suite.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13a: "N is first lowered to the file count, so a one-file run needs no parallel."

**Location:** `scripts/run-tests.sh:402-403`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-file case with no `parallel` on PATH. It does not establish anything about zero selected files, which exit earlier (`:384-387`).

`:406` lowers N before the `jobs -gt 1` test at `:407`. P5c ran `--jobs 5 test/gamma.bats` with no `parallel` on PATH (`command -v parallel` → none): `1..1`, `ok 1 gamma clean output`, exit 0, no warning.

**Evidence:** `scripts/run-tests.sh:384-387`, `scripts/run-tests.sh:406-414`, fc-p3r2/P5-parse-combos.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13b: "Otherwise bats aborts without GNU parallel, so that is what is checked"

**Location:** `scripts/run-tests.sh:403-404`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same finding as Claim 6. It does not question the check itself, which is right to test for GNU parallel.

bats aborts only when no `parallel` is on PATH (`bats-exec-suite:100-101`, P6a). With a non-GNU one it runs it and fails with 0 tests executed (P6b). Precise version: "bats cannot run N > 1 without GNU parallel (it aborts without any parallel and fails with another one)".

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-103`, fc-p3r2/P6-bats-parallel.log
**Legibility-target:** for-author

---

## Claim 13c: "the first `parallel` on PATH, the one bats runs, with --plain so the user's parallel config cannot fail the check."

**Location:** `scripts/run-tests.sh:404-405`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers config files and `$PARALLEL`/`$PARALLEL_CSH`, all skipped under `--plain`. It does not establish that config cannot affect bats' later run (it can, Claim 9a).

bats calls bare `parallel` (bats-exec-suite:420), and so does the runner (`:409`). The `if(not $opt::plain)` guard is at `/usr/bin/parallel:3318`. P2: with `~/.parallel/config`=`--no-such-option`, `parallel --version` exits 255 and `parallel --plain --version` prints `GNU parallel 20221122`. P4: MB (no `--plain`) fails T28.

**Evidence:** `scripts/run-tests.sh:409`, `/usr/bin/parallel:3315-3318`, fc-p3r2/P2-plain-version.log, fc-p3r2/P4-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "At most 3 digits, so the value never overflows bash arithmetic and parallel never sizes thousands of job slots."

**Location:** `scripts/run-tests.sh:137-138`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both stated reasons for the cap. It does not establish that the cap is the only guard on parallel's slot count: the lowering at `:406` already bounds it by the file count.

The regex `^[1-9][0-9]{0,2}$` caps N at 999. P8 shows what happens without the cap: `9223372036854775808` evaluates to `-9223372036854775808`, is not lowered, and takes the serial branch silently. `99999999999999999999` wraps to `7766279631452241919`.

**Evidence:** `scripts/run-tests.sh:136-146`, `scripts/run-tests.sh:406`, fc-p3r2/P8-T92-overflow.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "parallel_shim: put a `parallel` first on PATH that logs its arguments to $T/parallel.args and execs the real one. The runner's own --version check is logged too, so a test that wants to see bats used parallel greps for the --no-parallelize-within-files it hands bats."

**Location:** `test/scripts/run-tests.bats:329-332`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shim's logging and both logged calls. It does not establish anything when a non-GNU `parallel` is first on PATH: the shim then wraps it and does not skip, although the skip message names GNU parallel (`:335`).

P7's `parallel.args` held `--plain --version`, then `--keep-order --jobs 2 bats-exec-file --dummy-flag -j 2 --no-parallelize-within-files …`.

**Evidence:** `test/scripts/run-tests.bats:333-342`, fc-p3r2/P7-T24-parallel.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "--jobs: a missing, zero, non-numeric or 4-digit N is a usage error"

**Location:** `test/scripts/run-tests.bats:344`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named cases, which the test asserts (exit 2 plus message). It does not cover leading zeros or signs, which the name does not claim (Claim 1 covers them).

Assertions are at `:345-357`. P1 ok 20.

**Evidence:** `test/scripts/run-tests.bats:344-358`, fc-p3r2/P1-suite.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "--jobs 2 runs files through parallel, not tests within a file"

**Location:** `test/scripts/run-tests.bats:360`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argument proxy (the grep of `--jobs 2 .*--no-parallelize-within-files`). It does not establish observed serial execution within a file. That residue is settled in the override log (2026-09-30, "fact-check claim 12") and is not re-raised.

P4: ME and MF fail this test.

**Evidence:** `test/scripts/run-tests.bats:360-370`, fc-p3r2/P4-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "--jobs 1 runs serially and needs no parallel"

**Location:** `test/scripts/run-tests.bats:372`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `parallel` is never invoked, which the test asserts via `[ ! -f "$T/parallel.args" ]`. It does not remove `parallel` from PATH. "Needs no parallel" without one on PATH is shown by P5c.

With `jobs=1` the block at `:407` is skipped, so neither the version check nor bats' `parallel` call happens. P1 ok 22.

**Evidence:** `test/scripts/run-tests.bats:372-378`, `scripts/run-tests.sh:407`, fc-p3r2/P1-suite.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "--jobs: a parallel run records a complete log that --failed re-runs from" and "A second file that fails until $T/fixed exists, so --failed re-runs two files and stays parallel."

**Location:** `test/scripts/run-tests.bats:380-383`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the complete log (5/5), the two-file `--failed` re-run going through `parallel`, and the final "nothing to re-run". It does not cover logs changed by a config file (Claim 9c).

delta's test is `[ -f "$BATS_TEST_DIRNAME/../fixed" ]` (`:384`), and `$BATS_TEST_DIRNAME/..` is `$T`. After `rm "$T/parallel.args"`, the test greps `--jobs 2 .*--no-parallelize-within-files` (`:398`). P4: ME and MF fail it.

**Evidence:** `test/scripts/run-tests.bats:380-405`, fc-p3r2/P4-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: "--jobs: a parallel run killed partway is refused by --failed"

**Location:** `test/scripts/run-tests.bats:407`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal of a killed `--jobs 2` run, and that the run really goes through `parallel` today (P7). It does not establish that the test would notice if the run fell back to serial.

The test calls `parallel_shim` but never checks `$T/parallel.args` (`:407-421`). P4: ME (GNU check forced false, so every `--jobs` run is serial) still passes this test (`ok 5`). P7 added `grep -q -- '--no-parallelize-within-files' "$T/parallel.args"` after the kill, and it passed, so the run is parallel in practice. Precise version: add that grep, or name the test for the refusal alone.

**Evidence:** `test/scripts/run-tests.bats:407-421`, fc-p3r2/P4-mutants.log, fc-p3r2/P7-T24-parallel.log, fc-p3r2/mut-T24probe.diff
**Legibility-target:** for-author

---

## Claim 21: "--jobs: an uninstalled locale leaves no perl or citation text in the output" and "gamma asserts its own subprocess output is clean; the suite-level output must be clean too."

**Location:** `test/scripts/run-tests.bats:423-430`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parallel path (the grep of `--no-parallelize-within-files`) and the final negated grep, which, as the test's last command, decides its status. It does not establish the citation half on an upstream build (Claim 12).

P4: ME and MF fail it, so it checks the parallel path. P6c shows the perl warning that the pin suppresses. P1 ok 25.

**Evidence:** `test/scripts/run-tests.bats:423-433`, fc-p3r2/P4-mutants.log, fc-p3r2/P6-bats-parallel.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: "--jobs above the file count is lowered to it"

**Location:** `test/scripts/run-tests.bats:435`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 999 on 2 files → `--jobs 2`. It does not cover a one-file lowering, which is Claim 13a.

P4: ME and MF fail it. P1 ok 26.

**Evidence:** `test/scripts/run-tests.bats:435-440`, fc-p3r2/P4-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23a: "--jobs: the user's PARALLEL options neither reach bats' parallel nor fail the check"

**Location:** `test/scripts/run-tests.bats:442`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that, at HEAD, `$PARALLEL` neither changes bats' run nor makes the runner serial, which the test asserts. It does not establish that the test guards `unset` ordering. The "fail the check" half fails only when both `unset` is moved after the check and `--plain` is dropped (MD).

P4: MC (no `unset`) fails via `--dry-run` reaching bats. MD fails. MA (`unset` moved after the check, `--plain` kept) passes, because `--plain` alone keeps `$PARALLEL` out of the check.

**Evidence:** `test/scripts/run-tests.bats:442-452`, fc-p3r2/P4-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23b: "--dry-run would run no test at all; an unknown option would fail the --version check and make the run serial."

**Location:** `test/scripts/run-tests.bats:444-445`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the second clause against the runner's actual check. The `--dry-run` clause is right (P3, P5d).

The runner's check is `parallel --plain --version` (`scripts/run-tests.sh:409`), and `--plain` skips `$PARALLEL` (`/usr/bin/parallel:3318`, `:3360-3368`). P2: `PARALLEL=--no-such-option parallel --plain --version` prints `GNU parallel 20221122` and exits 0. So an unknown option in `$PARALLEL` cannot fail that check even if it reached it. P4's MA mutant, which leaves `$PARALLEL` set during the check, passes this test. The `--no-such-option` in the test only matters if `--plain` is also removed (MD). A reader would take the comment to mean the test guards the `unset`-before-check order, and it does not.

**Evidence:** `test/scripts/run-tests.bats:442-452`, `scripts/run-tests.sh:408-409`, `/usr/bin/parallel:3315-3368`, fc-p3r2/P2-plain-version.log, fc-p3r2/P4-mutants.log, fc-p3r2/mut-MA.diff
**Legibility-target:** for-author

---

## Claim 24: "--jobs: a parallel config file cannot fail the GNU parallel check"

**Location:** `test/scripts/run-tests.bats:454`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the check only, which the test asserts (no "running serially", bats handed the flags). It does not assert the run's status: bats' own `parallel` does read the config (Claim 9a).

P4: MB and MD fail it. P1 ok 28.

**Evidence:** `test/scripts/run-tests.bats:454-463`, fc-p3r2/P4-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: "--jobs with a non-GNU parallel first on PATH warns and runs serially"

**Location:** `test/scripts/run-tests.bats:465`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the warning and a serial run with status 0 (a bats `--jobs` run through the fake would give 0 tests, as P6b shows). It does not cover the real moreutils binary, which is not installed; the fake stands in for it.

P1 ok 29.

**Evidence:** `test/scripts/run-tests.bats:465-475`, fc-p3r2/P1-suite.log, fc-p3r2/P6-bats-parallel.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: "--jobs without GNU parallel on PATH warns and runs serially" and "A PATH holding everything the current one does except parallel (and bats' libexec directory, which in_runner drops too)."

**Location:** `test/scripts/run-tests.bats:477-479`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the warning, the serial results and the run-log line. The PATH copy keeps first-match order (`! -e "$bin/${f##*/}"`) and skips `$BATS_LIBEXEC` and `parallel`. It does not establish that directories inside PATH entries are excluded (`-x` also matches subdirectories, which are harmless here).

The `command -v parallel ||` guard makes the test fail rather than pass vacuously if `parallel` stays reachable. P1 ok 30.

**Evidence:** `test/scripts/run-tests.bats:477-499`, fc-p3r2/P1-suite.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27a: 78b3b08: "Pass 2 fact-check (k=3, all three replicates agreeing):"

**Location:** commit 78b3b08 body, line 3
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the replicate reports `docs/reviews/q090-final-code-fact-check-report-r{1,2,3}.md` (all `Commit: b34a6fe`). It does not reach how the orchestrator merged them.

All three replicates flag the `PARALLEL_HOME` claim Incorrect (r1 Claims 9/26b, r2 7b/27, r3 11/31b), and all three found the check running before `unset PARALLEL` (r1:237, r2:259, r3:613). The install-host "starting and ending" item was Incorrect in r1 (6b) and r2 (5b) but Unverifiable in r3 (Claim 7). r3's note names the same real exposure (unreadable cwd), so the replicates agree in substance but not in verdict. The health-check example was an attention item in r1 (Claim 4). Precise version: "agreeing on the substance; the install-host item was 2 Incorrect, 1 Unverifiable".

**Evidence:** `docs/reviews/q090-final-code-fact-check-report-r1.md:9`, `docs/reviews/q090-final-code-fact-check-report-r2.md:8`, `docs/reviews/q090-final-code-fact-check-report-r3.md:193-197`, `docs/reviews/q090-final-code-fact-check-report-r3.md:767`
**Legibility-target:** for-author

---

## Claim 27b: 78b3b08: "PARALLEL_HOME did not isolate parallel's config: parallel still reads ~/.parallel/config, ~/.parallelrc, $XDG_CONFIG_HOME/parallel/config and /etc/parallel/config. The export is removed"

**Location:** commit 78b3b08 body, lines 4-6
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the config sources and the removal of the `PARALLEL_HOME` export. The list omits `$XDG_CONFIG_DIRS/*/parallel/config`, which is also read.

`@Global::config_dirs` includes every existing directory among `$PARALLEL_HOME`, `$XDG_CONFIG_HOME/parallel`, `$XDG_CONFIG_DIRS/*/parallel` and `~/.parallel` (`/usr/bin/parallel:2840-2849`). All their `config` files are read (`:3320-3323`), plus `/etc/parallel/config` and `~/.parallelrc`. `rg PARALLEL_HOME scripts/run-tests.sh` finds nothing.

**Evidence:** `/usr/bin/parallel:2838-2849`, `/usr/bin/parallel:3318-3323`, `scripts/run-tests.sh:407-414`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27c: 78b3b08: "the header now says config files still apply and a breaking one fails closed (bats' count check, then --failed refuses the log)"

**Location:** commit 78b3b08 body, lines 6-8
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "--failed refuses the log" part, as in Claim 9c. The "bats' count check" part holds (Claim 9b).

In P3, `--tag` and `--retries 2` configs broke the run (bats exit 1, `Executed 0/2 instead of expected 4`), and `--failed` then accepted the log and re-ran `alpha flaky` (paraphrased — no quote available because the evidence is probe output, quoted in Claim 9c).

**Evidence:** `scripts/run-tests.sh:255-261`, fc-p3r2/P3-fail-closed.log
**Legibility-target:** for-author

---

## Claim 27d: 78b3b08: "`unset PARALLEL` ran after the GNU check, so an unparsable $PARALLEL made the runner warn "not GNU parallel" and run serially. It now runs first, and the check uses `parallel --plain --version` so a config file cannot fail it either (+ tests for both)."

**Location:** commit 78b3b08 body, lines 9-12
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old order (084868f), the new order and `--plain`, and that tests exist for both. How well T27 guards the order is Claim 23a/23b's residue.

At 084868f the check was `if [[ "$(parallel --version 2>/dev/null)" == "GNU parallel"* ]]; then unset PARALLEL …` (`git show 084868f:scripts/run-tests.sh`). P2: an unparsable `$PARALLEL` makes `parallel --version` exit 255. HEAD `:408-409` has `unset PARALLEL`, then `parallel --plain --version`. P4: MD (the old code) fails T27 and T28.

**Evidence:** `scripts/run-tests.sh:407-414`, fc-p3r2/P2-plain-version.log, fc-p3r2/P4-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27e: 78b3b08: "install-host.bats' exposure: agent_gate refuses on a live process whose working directory procs_in_checkout cannot read (e.g. non-dumpable); exiting processes are skipped, so "starting and ending" was wrong."

**Location:** commit 78b3b08 body, lines 13-15
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the scan's unknown-cwd branch and the skip for exited processes (`[ -n "$cmd" ] || continue`, `install.sh:1180`). It does not establish that no race between `readlink` and the `cmdline` read can leave a live process listed; a process that exits in between has an empty `cmdline` and is skipped.

See Claim 5's quote (`install.sh:1170-1180`) and P8's T92 run.

**Evidence:** `devcontainer-config/install.sh:1165-1182`, fc-p3r2/P8-T92-overflow.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27f: 78b3b08: "The health-check.bats cache example was weak (written in setup_file, only read after); the header now says within-file serial is simply the only way the suites have run. "N above the core count buys nothing" was unmeasured and is dropped. The stale "not the file count" comment now says N is lowered to the file count first, so a one-file run needs no parallel."

**Location:** commit 78b3b08 body, lines 16-21
**Type:** Behavioral / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the setup_file cache and the three header/comment changes. Whether "only way the suites have run" is itself exact is Claim 3.

`test/scripts/health-check.bats:34-35`: `setup_file() { _run_and_cache`. The tests only read the cache. `git show f733a51:scripts/run-tests.sh` has "N above the core count buys nothing" at `:90` and "Test for GNU parallel itself, not the file count" at `:401`. Neither is at HEAD (`rg` finds no "core count" in `scripts/run-tests.sh`). The new comment is at `:402-403`.

**Evidence:** `test/scripts/health-check.bats:20-40`, `scripts/run-tests.sh:85-109`, `scripts/run-tests.sh:402-405`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27g: 78b3b08: "Tests: the shim's args file now also holds the runner's --version call, so tests grep for --no-parallelize-within-files instead of the file's existence; the --failed re-run covers two files so it stays parallel."

**Location:** commit 78b3b08 body, lines 22-24
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tests that use the shim to show parallel use (T21, T23, T25, T26, T27, T28). T24 uses the shim but greps nothing (Claim 20), and T21 keeps a redundant `[ -f "$T/parallel.args" ]` beside its grep.

P7 shows the version call logged. Claim 19 covers the two-file re-run.

**Evidence:** `test/scripts/run-tests.bats:360-463`, fc-p3r2/P7-T24-parallel.log, fc-p3r2/P4-mutants.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27h: 78b3b08: "Mutants (unset moved back, --plain dropped, bats never given --jobs) each fail their test."

**Location:** commit 78b3b08 body, lines 25-26
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named mutants applied one at a time to HEAD's runner. It does not establish which code the author mutated. "unset moved back" does fail T27 when `--plain` is also removed (MD).

P4:
- MB (`--plain` dropped) fails T28.
- MF (bats never given `--jobs`) fails six tests.
- MA (`unset PARALLEL` moved back inside the success branch, after the check, as at 084868f; diff in `fc-p3r2/mut-MA.diff`) passes all 11 `--jobs` tests.

With `--plain`, the check ignores `$PARALLEL`, and the `unset` still runs before bats. So the mutant is equivalent at HEAD and no test can fail it.

**Evidence:** `scripts/run-tests.sh:407-414`, fc-p3r2/P4-mutants.log, fc-p3r2/mut-MA.diff, fc-p3r2/mut-MB.diff, fc-p3r2/mut-MF.diff
**Legibility-target:** for-author

---

## Claim 27i: 78b3b08 Notes: "no attempt to block parallel's config files (bats passes no --plain …)"

**Location:** commit 78b3b08 body, Notes
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers bats' `parallel` call. The "overriding HOME would change every test's environment" rationale is design reasoning and was not checked.

`/usr/libexec/bats-core/bats-exec-suite:420`: `parallel --keep-order --jobs "$num_jobs" bats-exec-file …`, with no `--plain`.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 9c** (`scripts/run-tests.sh:100-101`): "--failed refuses that log" holds only when the broken config kept tests from running (`--dry-run`, `--halt`). A config that only garbles or drops output (`--tag`, `--retries 2`) leaves a complete log, and `--failed` accepts it. Low harm, because the accepted log is accurate. Reword.
- **Claim 23b** (`test/scripts/run-tests.bats:444-445`): an unknown option in `$PARALLEL` cannot fail `parallel --plain --version`, so the comment's reason for `--no-such-option` does not hold. The test does not guard the `unset` order (MA passes).
- **Claim 27c** (commit 78b3b08): repeats Claim 9c's "then --failed refuses the log".
- **Claim 27h** (commit 78b3b08): the "unset moved back" mutant passes every test at HEAD. It is equivalent given `--plain`.

### Mostly Accurate
- **Claim 3** (`scripts/run-tests.sh:87-88`): "the only way the suites have ever run". The user ran `bats --jobs 2 test/agents-gemini-sync.bats` once (within-file parallel). Precise version: "the only way the runner has run them".
- **Claim 6** (`scripts/run-tests.sh:94-95`) and **Claim 13b** (`:403-404`): bats aborts only when no `parallel` is on PATH. With a non-GNU one it runs it and fails with 0 tests.
- **Claim 20** (`test/scripts/run-tests.bats:407`): the test name says "a parallel run" but it never checks `parallel.args`, so it passes when the run falls back to serial (ME).
- **Claim 27a** (commit 78b3b08): "all three replicates agreeing". The install-host item was 2 Incorrect and 1 Unverifiable.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path named below, structured per the skill.
- Answered: yes. 40 claims covering all five priority groups; 34 were verdicted by execution (8 probes, including 6 mutants plus a T24 probe copy).
- Out of scope: earlier commits' bodies (settled); running install-host.bats beside other files under `--jobs`, or the real suite (barred by the brief); upstream parallel and the real moreutils binary (not installed; no network).
- Escalate: Claim 9c/27c. New evidence (P3 `--tag`/`--retries`) against the header's fail-closed sentence, not covered by any override-log row. Claims 23b/27h: T27 no longer guards the `unset` order now that `--plain` exists. Either the comment and commit claim go, or the ordering is accepted as defense in depth with no test. Minor residue: `$PARALLEL_CSH` still reaches bats' run (P5d).
- Decisions I made: kept the execution logs in the scratchpad (`fc-p3r2/`), not `docs/reviews/execution-logs/`, per the edit-only-this-report brief. Rated Claims 6/13b Mostly accurate rather than Incorrect, because "aborts" is the imprecise verb while the "needs GNU parallel" conclusion and the runner's check are right. Rated Claim 9c Incorrect despite its low harm, because its stated mechanism is refuted for a class of breaking configs.
