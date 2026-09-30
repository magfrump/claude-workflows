Commit: ff99d86

# API Consistency Review — feat/run-tests-jobs (Q-090, final pass)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-run-tests-jobs, full branch. The public surface is the CLI of `scripts/run-tests.sh`: the `--jobs N` flag, its exit codes, messages and `--help` text, and how it composes with `--failed`/`--fast`/`--slow`/`--all`/FILE. Compared with the runner's existing flags, bats 1.8.2's `--jobs`, and the callers `scripts/health-check.sh` and `workflows/pr-prep.md`.
**Date:** 2026-09-30
**Based on:** the pass-3 fact-check replicates `docs/reviews/q090-pass3-code-fact-check-report-r{1,2,3}.md` (r1 41 claims: 2 Incorrect, 4 Mostly accurate; r2 40 claims: 4 Incorrect, 5 Mostly accurate; r3 35 claims: 1 Incorrect, 3 Mostly accurate). Also the pass-1 review `docs/reviews/q090-api-consistency-review-2026-09-30.md` and the settled override-log rows 166-174 (2026-09-30). Behaviour the replicates agree on is not re-verified here, and settled rows are not re-raised.

**Probes.** A single script, `api-final/probe.sh` in the session scratchpad, ran under `timeout 300` with `LC_ALL=C.UTF-8`. It built a scratch layout: a copy of the runner and its two sourced libs, plus three one-test fast files `a/b/c.bats`. It never touched the real suite, and the largest `--jobs` it passed was 8. Output is in `api-final/probe.log`. Each command ran in the foreground and exited before the next one, so no process was left running.

## Status of pass-1 findings

| Pass-1 # | Finding | Now |
|---|---|---|
| 1 | Help text carried the fact-check's Incorrect install-host claim | Fixed (084868f, 78b3b08). `:89-93` now describes the cross-file `agent_gate` exposure, which all three replicates verify (r1 C5, r2 C5, r3 C4). |
| 2 | Usage errors exit 2 (`--jobs x`) or 1 (`-j 2`, `--jobs=2`) | Settled: Won't-Fix (row 169). Re-probed and unchanged: `[--jobs=2] -> 1`, `[-j 2] -> 1`, `[--jobs -1] -> 2`. |
| 3 | "positive integer" did not match the regex | Fixed. The help says "1 to 999, digits only, no leading zero" (`:36-38`), the regex is `^[1-9][0-9]{0,2}$` (`:139`), and the message says "a number from 1 to 999" (`:140`). The replicates verify this (r1/r2/r3 Claim 1). |
| 4 | Per-file stderr moves to stdout under `--jobs` | Settled: Won't-Fix (row 170). |
| 5 | The fallback accepted any `parallel` | Fixed. `parallel --plain --version` must print `GNU parallel` (`:409`). |
| 6 | No caller passes `--jobs` | Settled: Won't-Fix (row 171). `scripts/health-check.sh` and `workflows/pr-prep.md` are unchanged on this branch. |

## Baseline Conventions

The pass-1 baseline still holds, and nothing outside `scripts/run-tests.sh` and its test file changed in `scripts/` or `workflows/`.

- **Flags:** long flags only (`--fast`, `--slow`, `--all`, `--failed`), `-h` is the one short form, and a value is a separate word with no `=`. bats is the same: `-j | --jobs) shift; flags+=('-j' "$1")`, with no `=` splitting.
- **Repeats:** when a flag is repeated, the last one wins.
- **`--failed`:** it refuses the scope-narrowing flags (exit 2, `:161-165`). Flags that don't narrow scope combine with it.
- **Exit codes:**
  - 0: pass.
  - 1: bats' own failure status (via `exec`), runtime `ERROR:` lines, `--failed` refusals, and `Unknown flag`.
  - 2: the usage errors for `--failed` and `--jobs`.
- **Messages:**
  - A usage error names the flag first, then prints `usage` to stderr.
  - A runtime error starts `ERROR: …` and exits 1.
  - A degraded run that carries on prints `WARNING: <what>; running <how>` to stderr (`:234`). The same form is used elsewhere in `scripts/` (`skill-usage-report.sh:110`, `flag-removal-candidates.sh:171`).
  - Both kinds of message restate what the user supplied: `got: <value>`, `no such test file: <arg>`.
- **Help:** `-h|--help` prints the header comment from line 2 up to the first blank line (`:148`, blank line `:110`). The Usage line, the Flags list and every `<Topic>:` paragraph are user documentation. The probe (P6) confirmed that `--help` prints through the last "Parallel runs" line.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--jobs` | CLI flag | bats `-j, --jobs <jobs>`; runner `--failed`, `--fast` | `/usr/libexec/bats-core/bats` (`-j \| --jobs`); `scripts/run-tests.sh:132-135` | Consistent. It uses bats' own word and value shape and is long-only like its siblings. |
| `N` (metavar) | CLI param | bats `<jobs>`; runner `FILE...` | `scripts/run-tests.sh:16, 41` | Consistent. It is a bare upper-case metavar. |
| `--jobs takes a number from 1 to 999, got: X` | usage-error message | `--failed re-runs every failure … and takes no --fast/--slow/--all or FILE` | `scripts/run-tests.sh:162` | Consistent. It names the flag first, says "takes", echoes the raw value and is followed by `usage`. |
| `WARNING: --jobs N needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially` | warning message | `WARNING: cannot write …; running without recording (…)` | `scripts/run-tests.sh:234` | The shape (prefix, stderr, "; running …" tail) is consistent. The `N` it prints is not the value the user typed: see Finding 2. |
| "Parallel runs:" help paragraph | help section | "Run logs:", "Locale:", "Report gating" | `scripts/run-tests.sh:48, 79, 11-13` | Consistent. The flag line cross-references it as `(see "Parallel runs")`. |
| test ids `--jobs: …`, `--jobs 2 …`, `--jobs with …` | test ids | `locale: …`, `FILE: …`, `--failed …` | `test/scripts/run-tests.bats` | Consistent. Both existing styles are already in use. |

No new env var is introduced. The runner now unsets the user's `$PARALLEL` for its own run (`:408`). That is an interaction with a variable parallel owns, not a new `RUN_TESTS_*` name, so there is nothing to audit against that family.

## Findings

#### 1. `--help` promises that `--failed` refuses a log that a broken parallel config leaves, and it does not always

**Severity:** Minor
**Location:** `scripts/run-tests.sh:98-101`
**Move:** 3 (documentation drift in the consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Evidence (verbatim, `scripts/run-tests.sh:98-101`):
```
# parallel's config files (~/.parallel/config, ~/.parallelrc,
# /etc/parallel/config and the like) still apply; one that breaks the run
# fails closed: bats reports fewer tests run than expected and exits 1, and
# --failed refuses that log.
```

This paragraph is printed by `--help`, so it is the contract a user relies on when deciding whether to trust `--failed` after a bad parallel run. The replicates split on it:

- **r2 (Incorrect, Claim 9c):** with `--tag` and with `--retries 2` in `~/.parallel/config`, bats printed `Executed 0 instead of expected 4` or `Executed 2 of 4` and exited 1. The run log still held all 4 results, so `--failed` accepted it and re-ran `alpha flaky`.
- **r1 (Mostly accurate, Claim 11b):** the same result with `--tag` and `--retries 2`.
- **r3 (Verified, Claim 9):** it probed only configs that stop tests from running (an unknown option, `--dry-run`, `--retries 2` on its fixture). There, `--failed` refuses, but through "the last run left no log of its own", not by reading "that log".

`--failed` checks the run log (`:255-258`), not bats' TAP count. So a config that only garbles parallel's output leaves a complete log, and `--failed` re-runs from it. The replicates agree that no wrong result follows: the accepted log was accurate every time. The harm is only that the documented contract says "refuses" where the code says "accepts when the log is complete". The same sentence also appears in commit 78b3b08's body (r2 Claim 27c). That body is immutable, so it belongs in an Accepted-immutable row, not in this report.

**Recommendation:** Reword the last clause to what the code checks. r2's wording works: "…and exits 1; --failed refuses the log when the break kept tests from running, and re-runs from it when every test still recorded a result". This is a one-line edit to the help text, with no code change.

#### 2. The fallback warning names the lowered N, not the N the user typed

**Severity:** Minor
**Location:** `scripts/run-tests.sh:406-412`
**Move:** 4 (message consistency)
**Confidence:** High
**Legibility-target:** for-author

Evidence (verbatim, `scripts/run-tests.sh:406-412`, excerpt; the `if` block ends at `:414`):
```
(( jobs > ${#files[@]} )) && jobs=${#files[@]}
if [[ "$jobs" -gt 1 ]]; then
  unset PARALLEL
  if [[ "$(parallel --plain --version 2>/dev/null)" == "GNU parallel"* ]]; then
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
  else
    echo "WARNING: --jobs $jobs needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially" >&2
```

Probe P1 ran `--jobs 8` on three files with no `parallel` on PATH. It printed `WARNING: --jobs 3 needs GNU parallel, …; running serially` and exited 0. The user typed `--jobs 8`, and the message quotes a flag value they never passed. Every other message in the runner that restates input quotes it as given: `got: ${2:-(nothing)}` (`:140`), `no such test file: $arg` (`:187`), `not under test/: $arg` (`:198`). The lowering is documented ("N above the number of selected files is lowered to it", `:38-39`), so a reader can work out the 3. Still, a user grepping their own command for `--jobs 3` finds nothing. The only test of this message (`--jobs without GNU parallel on PATH warns and runs serially`, which asserts `WARNING: --jobs 2 needs …`) passes N=2 on two files, where the two values happen to agree, so it cannot tell them apart.

**Recommendation:** Keep the user's value for messages, for example `requested_jobs="$2"` at `:144`, and print that. Alternatively, drop the number: `WARNING: --jobs needs GNU parallel, …`. Either is one line. A test with N above the file count would pin the choice.

#### 3. Three smaller precision gaps in the "Parallel runs" help paragraph

**Severity:** Informational
**Location:** `scripts/run-tests.sh:94-97`, `scripts/run-tests.sh:106-109`
**Move:** 3 (documentation drift)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence (verbatim, `scripts/run-tests.sh:94-97`):
```
# bats runs files through GNU parallel and aborts without it even for one
# file, so when the first `parallel` on PATH is missing or is not GNU
# parallel (moreutils ships one too), the runner warns and runs serially. It
# unsets $PARALLEL, so the user's parallel options do not reach bats' run.
```

Evidence (verbatim, `scripts/run-tests.sh:107-109`):
```
# above keeps perl's setlocale warnings out of it, and upstream parallel
# prints its citation notice only when its stderr is a terminal, which inside
# bats it never is (Debian's build never prints it).
```

Each of these is one replicate's Mostly accurate. None changes what the runner does, and each is a precision point in user-facing text:

- **(a) "aborts without it" (r1 Claim 17, r2 Claim 6).** bats aborts only when no `parallel` exists at all. With a non-GNU one first on PATH, it runs that program and executes no tests (`Executed 0 instead of expected 2 tests`, exit 1). The runner's check covers both cases, so the stated conclusion stands and only the mechanism is imprecise.
- **(b) "the user's parallel options do not reach bats' run" (r1 Claim 9).** `$PARALLEL_CSH` is also read as options and is not unset. It is set only by env_parallel under csh, so this is narrow.
- **(c) "Debian's build never prints it" (r3 Claim 13).** This is true of the `citation_notice()` banner. But parallel's usage text, which it prints when it rejects an option, carries the same citation paragraph. In the fail-closed case that Finding 1's sentence describes, this lands in the runner's output.

**Recommendation:** Optional. If Finding 1's sentence is being edited anyway, fold in (c) and change "aborts without it" to "aborts without a parallel and runs no tests with any but GNU's". (b) can wait.

## What Looks Good

- **Pass-1 fixes landed on the public surface.** The value contract, regex, message and help now agree on 1-999 with no leading zero. The fallback checks for GNU parallel, not just any `parallel`. The install-host sentence describes the real cross-file exposure. All three replicates verify each of these.
- **The flag's shape matches both neighbours:** bats' `--jobs <n>` and the runner's long-only, separate-value flags. `--jobs=2` and `-j 2` are refused by the runner as they were before this branch, which is the settled row 169.
- **Composition behaves as documented.** The probe showed:
  - `--jobs 2 --failed --slow` still hits `--failed`'s scope conflict (exit 2).
  - `--jobs 2 --jobs 3 --fast` uses the last value and runs.
  - `--jobs --fast` is read as a bad value (`got: --fast`, exit 2), not silently as a flag.
  - `--failed --jobs 2` goes through `--failed`'s normal checks.
- **Backward compatibility.** The default `jobs=1` adds nothing to `bats_args` (`:407`), so health-check's `--fast`/`--slow` calls and pr-prep's documented `<files>`/`--failed` calls are byte-for-byte unchanged. No versioning concern.
- **The degraded run follows precedent:** a `WARNING:` on stderr with a "; running serially" tail and exit status from the tests, exactly like the no-recording case (`:234`).
- **The fail-closed direction is right.** A config that stops tests from running makes the run exit 1 and `--failed` refuse (r1, r2 and r3 all executed this). The one gap is the help wording in Finding 1, where a complete log is accepted.
- **Tests pin the surface:** the exact usage message for missing, `0`, `x` and `1000`, the exact warning text, and the `--failed` composition. Pass-3 mutants of the check (`--plain` dropped, `unset` removed, bats never given `--jobs`) each fail at least one test (r1 E1, r2 P4, r3 E2/E3).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--help` says `--failed` refuses a broken-config log; it accepts a complete one (`--tag`, `--retries`) | Minor | `scripts/run-tests.sh:98-101` | High |
| 2 | Fallback warning prints the lowered N (`--jobs 3`) when the user typed `--jobs 8` | Minor | `scripts/run-tests.sh:406-412` | High |
| 3 | Help precision: bats with a non-GNU `parallel`, `$PARALLEL_CSH`, citation text in parallel's usage output | Informational | `scripts/run-tests.sh:94-97, 106-109` | Medium |

## Overall Assessment

`--jobs N` is consistent with the runner's conventions and with bats. It has the same name and value shape as bats' `--jobs`, it is long-only, its usage error is exit 2 like `--failed`'s, its warning follows the established `WARNING: …; running …` form, the default path is unchanged for every caller, and it composes with the other flags as its help says. Pass 1's three for-author findings are fixed, and its three informational findings are settled in the override log. What remains is precision in the user-facing text and message, all fixable in place. The help overstates `--failed`'s refusal after a broken parallel config: the code accepts a complete log, which is harmless but not what the help promises. The fallback warning quotes a value the user did not type. Nothing here breaks a consumer, and no caller passes `--jobs` yet.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "a markdown report saved at the path named below, structured per the skill."
- **Answered:** yes. The report is saved at `docs/reviews/q090-final-api-consistency-review-2026-09-30.md` with `Commit: ff99d86` at the top. It has the header, Baseline, Name-Pattern Audit, Findings (each with Severity, Location, verbatim Evidence, Confidence and Legibility-target), What Looks Good, the Summary Table and the Overall Assessment. It covers every surface the brief names: the flag, exit codes, messages, help text, composition with `--failed`/`--fast`/`--slow`/FILE, bats' `--jobs`, health-check and pr-prep.
- **Legibility-target:** for-author on Findings 1-3. The pass-1 status table is for-orchestrator-synthesis.
- **Out of scope:**
  - The Incorrect test comment at `test/scripts/run-tests.bats:444-445`, which says an unknown option "would fail the --version check", although `--plain` ignores it (r1 Claim 29b, r2 Claim 23b). It is test documentation, not the runner's public surface.
  - The commit-body claims in 78b3b08 (r2 Claim 27c, r3 Claim 33a), which are immutable.
  - Whether install-host.bats flakes under `--jobs`, which needs the real suite.
- **Escalate:** Finding 1. The replicates split three ways on it (r1 Mostly accurate, r2 Incorrect, r3 Verified-with-residue), so the rubric should record one disposition. The executed evidence (r1 E4, r2 P3) supports reading it as a wording fix.
- **Decisions I made:**
  - Rated Finding 1 Minor, not Inconsistent: the code errs toward accepting only complete logs, so no consumer gets a wrong re-run.
  - Rated Finding 2 Minor: the lowering is documented one flag-line above, so the number can be derived.
  - Did not re-raise pass-1 F2/F4/F6 (rows 169-171). F2's exit codes were re-probed only to confirm nothing had changed.
