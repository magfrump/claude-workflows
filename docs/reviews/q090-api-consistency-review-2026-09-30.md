Commit: 088bc97

# API Consistency Review — feat/run-tests-jobs (Q-090, `run-tests.sh --jobs N`)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-run-tests-jobs: the CLI surface of `scripts/run-tests.sh` (the `--jobs N` flag, its exit codes, messages and help text, how it composes with `--failed`/`--fast`/`--slow`/`--all`/FILE), plus the tests in `test/scripts/run-tests.bats` as consumers of that surface
**Date:** 2026-09-30
**Based on:** `docs/reviews/q090-code-fact-check-report.md` (k=1, 23 claims: 17 verified, 5 mostly accurate, 1 incorrect). Documented behaviour it verified is not re-verified here.

Probes run for this review (all under `timeout`, `LC_ALL=C.UTF-8`, foreground, no process left running): `bash scripts/run-tests.sh` with `-j 2`, `--jobs=2`, `--jobs 02`, `--jobs " 2"`, `--jobs 2 --jobs x`, `--jobs 4 --jobs 1 ... <missing file>` and `--help` (all exit before the lock), and `bats --jobs 2 --no-parallelize-within-files` against serial `bats` on two throwaway fixtures under the session scratchpad (`q090api/`). The full suite was not run.

## Baseline Conventions

Surveyed: `scripts/run-tests.sh` (all pre-existing flags and messages), bats 1.8.2's own CLI (`libexec/bats-core/bats:54-61, 150-216`), `scripts/health-check.sh` (the one programmatic caller), `workflows/pr-prep.md:242, 345` (documented invocations), and the other `scripts/*.sh` warning lines.

- **Flag shape.** Long flags only (`--fast`, `--slow`, `--all`, `--failed`). `-h` is the only short form. No `--flag=value` forms; values are separate words. Upstream bats is the same for `--jobs`: `-j | --jobs) shift; flags+=('-j' "$1")` (`bats:195-197`), with no `=` splitting.
- **Repeated flags.** Last one wins (`category=` is overwritten at `:120-122`).
- **Composition.** `--failed` refuses scope-narrowing flags (category, FILE) with exit 2 (`:147-151`) because a narrowed re-run would corrupt the next `--failed`. Flags that do not change scope are expected to combine freely.
- **Exit codes.** 0 pass, 1 test failure (bats' own status via `exec`), 1 for runtime errors (`ERROR: no such test file`, lock held, `--failed` refusals), 1 for `Unknown flag` (`:138-142`), 2 for the `--failed` usage conflict (`:150`). So "usage error" was already split between 1 and 2 before this diff.
- **Messages.** Usage errors name the flag first (`--failed re-runs every failure ... and takes no ...`, `:148`) and are followed by `usage` on stderr. Runtime errors are `ERROR: ...`; degraded-but-continuing runs are `WARNING: <what>; running without <what>` on stderr (`:220`, and `scripts/skill-usage-report.sh:110`).
- **Help.** `-h|--help` prints the header comment from line 2 to the first blank line (`:134`), so the Usage line, the Flags list and every header paragraph ("Run logs", "Locale", "Report gating") are the user-visible documentation.
- **Env seams.** Options callers set without flags are `RUN_TESTS_*` / `HEALTH_CHECK_*` env vars (`RUN_TESTS_NOT_RUN_FILE`, `HEALTH_CHECK_RUN_TESTS`, `HEALTH_CHECK_SKIP_BATS`).
- **Callers.** `scripts/health-check.sh:392, 400` invokes `"$runner" --fast` then `--slow` and treats any non-zero as red; `workflows/pr-prep.md` documents `scripts/run-tests.sh <files>` and `--failed`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--jobs` | CLI flag | bats `-j, --jobs <jobs>`; runner `--failed`, `--fast` | `libexec/bats-core/bats:54, 195`; `scripts/run-tests.sh:120-123` | Consistent — same word and value shape as the tool it wraps; long-only like every runner flag |
| `N` (metavar) | CLI param | bats `<jobs>`; runner `FILE...` | `bats:54`; `scripts/run-tests.sh:16, 40` | Consistent — bare upper-case metavar matches the runner's `FILE` |
| `--jobs takes a positive integer, got: X` | usage-error message | `--failed re-runs every failure ... and takes no --fast/--slow/--all or FILE` | `scripts/run-tests.sh:148` | Consistent — flag-first, "takes", followed by `usage` |
| `WARNING: --jobs N needs GNU parallel, which is not on PATH; running serially` | warning message | `WARNING: cannot write ...; running without recording (...)` | `scripts/run-tests.sh:220` | Consistent — `WARNING:` prefix, stderr, "; running …" tail |
| "Parallel runs:" header paragraph | help section | "Run logs:", "Locale:", "Report gating" | `scripts/run-tests.sh:47, 78, 11-13` | Consistent — `<Topic>:` paragraph, referenced from the flag line as `(see "Parallel runs")` like `--failed`'s `(see "Run logs")` |
| test names `--jobs: …` / `--jobs 2 …` | test ids | `locale: …`, `FILE: …`, `--failed …` | `test/scripts/run-tests.bats:120-313` | Consistent — both existing styles (colon-prefixed topic, bare flag) are already in use |

`jobs` (the shell variable) and `parallel_shim` (a test-local helper) are private and not audited; for the record, the repo's test-helper precedent is `stub_<thing>` (`test/install-host.bats:47, 51`), and a pass-through logger that execs the real binary is fairly called a shim rather than a stub.

## Findings

#### 1. Help text ships the fact-check's Incorrect claim and two imprecisions

**Severity:** Minor
**Location:** `scripts/run-tests.sh:84-97`
**Move:** 3 (documentation drift in the consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Evidence (verbatim, `scripts/run-tests.sh:85-88`):
```
# --no-parallelize-within-files`, so whole files run side by side and the
# tests within a file stay serial, as the suites were written: a file's tests
# may share state (install-host.bats' install.sh scans the real /proc for
# processes in its checkout). The slowest file therefore bounds the speedup.
```

The "Parallel runs" paragraph is printed by `--help`, so it is the flag's user documentation, not just a code comment. The fact-check rated its install-host example Incorrect (Claim 3): each install-host test builds its own `$BATS_TEST_TMPDIR/repo`, and the `/proc` scan's exposure (`kind=unknown`, any concurrent same-uid process) comes from other files' processes too, which `--jobs` still runs concurrently. A reader of `--help` can wrongly conclude install-host.bats is safe under `--jobs`, which is exactly the question Q-090's measurement has to answer. The same paragraph also carries Claim 6 (grouping comes from parallel's default `--group`; a file's results appear once it *and every earlier file* have ended) and Claim 9 (Debian's build never prints the citation notice at all) as Mostly accurate. The Flags entry and Usage line are accurate (Claims 1, 18, 23).

**Recommendation:** Apply the fact-check's precise versions: cite a `setup_file`/`BATS_FILE_TMPDIR` suite as the within-file example and say plainly that install-host's `/proc` scan is still exposed to other files under `--jobs`; fix the ordering sentence and the citation sentence as the fact-check words them.

#### 2. Usage errors for the same intent exit 1 or 2 depending on spelling

**Severity:** Minor
**Location:** `scripts/run-tests.sh:124-142`
**Move:** 4 (error consistency)
**Confidence:** High

Evidence (verbatim, `scripts/run-tests.sh:125-128` and `:138-141`):
```
      if [[ ! "${2:-}" =~ ^[1-9][0-9]*$ ]]; then
        echo "--jobs takes a positive integer, got: ${2:-(nothing)}" >&2
        usage
        exit 2
```
```
    -*)
      echo "Unknown flag: $1" >&2
      usage
      exit 1
```

Probed: `--jobs x` exits 2, while bats-habit spellings of the same request, `-j 2` (bats' own short form, `bats:54`) and `--jobs=2`, both hit `Unknown flag` and exit 1, the same status a red test run returns. The commit Notes choose 2 deliberately ("like the --failed conflict, not 1 like an unknown flag"), and that matches the newer convention (`:150`); the split itself predates this diff. The diff widens it, though: it adds a second exit-2 site next to the exit-1 unknown-flag site, so a wrapper still cannot read "exit 2 = usage error, exit 1 = tests failed". No current caller distinguishes (health-check treats any non-zero as red), so impact is small.

**Recommendation:** Keep `--jobs` at 2. Separately (own change, own test update at `test/scripts/run-tests.bats` wherever `Unknown flag` status is asserted), consider moving `Unknown flag` to exit 2 so every usage error is 2 and 1 means only "tests or runtime failed". Optionally, name `-j`/`--jobs=` in the unknown-flag case, or just accept that the runner is long-only.

#### 3. "positive integer" is narrower and wider than the regex

**Severity:** Minor
**Location:** `scripts/run-tests.sh:36-37`, `scripts/run-tests.sh:125`, `scripts/run-tests.sh:390`
**Move:** 4 (error consistency), 8 (input contract)
**Confidence:** High

Evidence (verbatim, `scripts/run-tests.sh:36-37`):
```
#   --jobs N  Run up to N test files at once (see "Parallel runs"). N is a
#             positive integer; anything else is a usage error (exit 2). 1,
```

The help promises "a positive integer; anything else is a usage error". `^[1-9][0-9]*$` rejects `02` (probed: exit 2, `got: 02`), which is a positive integer. It accepts arbitrarily long digit strings, and the fact-check (Claim 1, E6) showed `18446744073709551617` passes the regex and wraps to 1 in `[[ "$jobs" -gt 1 ]]`, so it runs serially with no warning. That is neither the documented usage error nor the documented N. Real users will not type either, so the impact is on the contract's precision more than on behaviour.

**Recommendation:** Either reword to "a positive integer without leading zeros" and cap the length (e.g. reject more than 4 digits, which also gives a better message than a silent serial run), or normalise with `$((10#$2))` after a length check. One line either way.

#### 4. Under `--jobs`, bats' per-file stderr moves to stdout

**Severity:** Informational
**Location:** `scripts/run-tests.sh:390-396` (via `bats-exec-suite:420`)
**Move:** 3 (subtle contract change), 7 (asymmetry serial vs parallel)
**Confidence:** Medium

Evidence (verbatim, fact-check Claim 8 scope): "The fold also covers the stderr of every `bats-exec-file`, which a serial run leaves on bats' stderr."

The runner's output contract (stdout = banner + TAP, stderr = warnings/errors) holds for TAP: my probe of `bats --jobs 2 --no-parallelize-within-files a.bats b.bats` against serial `bats a.bats b.bats` gave byte-identical TAP (`1..3`, `ok 1 a1`, `not ok 2 a2` with its captured `# errout`, `ok 3 b1`), the same exit status 1, and empty stderr in both. What differs is anything a `bats-exec-file` process writes to its own stderr outside a test (bats warnings, a file that fails to source): serial leaves it on stderr, `--jobs` folds it into stdout via `parallel ... 2>&1`. No caller splits the streams today (health-check lets both through), so nothing breaks.

**Recommendation:** Optionally add half a sentence to "Parallel runs" ("bats' own diagnostics then appear on stdout"); no code change.

#### 5. The fallback check accepts any `parallel`, while the warning and help say "GNU parallel"

**Severity:** Informational
**Location:** `scripts/run-tests.sh:391-394`
**Move:** 3 (consumer contract)
**Confidence:** Low

Evidence (verbatim, `scripts/run-tests.sh:391-394`):
```
  if command -v parallel > /dev/null; then
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
  else
    echo "WARNING: --jobs $jobs needs GNU parallel, which is not on PATH; running serially" >&2
```

The documented contract is "when GNU parallel is missing, warn and run serially". The check tests for any executable named `parallel`; on a Debian host with only moreutils installed, `/usr/bin/parallel` is moreutils' and bats would call it with GNU options (`--keep-order --jobs ...`). The fact-check (Claim 5 scope) raised the same gap. The runner's check does mirror bats' own abort condition exactly (`type -p parallel`, `bats-exec-suite:100`), which is why it was chosen. Not executed: no moreutils `parallel` exists on this host, hence Low confidence on the failure mode.

**Recommendation:** Either `parallel --version 2>/dev/null | grep -q '^GNU parallel'` for the check, or reword the help to "when no `parallel` is on PATH" so the contract says what the code tests. The target image ships GNU parallel, so this can wait.

#### 6. No caller can reach `--jobs` yet

**Severity:** Informational
**Location:** `scripts/health-check.sh:392`, `scripts/health-check.sh:400`
**Move:** 3 (consumer tracing)
**Confidence:** High

Evidence (verbatim, `scripts/health-check.sh:392`):
```
    if ! HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast; then
```

The only programmatic caller runs serially and has no seam to pass `--jobs`; `workflows/pr-prep.md:242, 345` documents `<files>` and `--failed` only. This is consistent with Q-090's own sequencing (add the flag, then measure against the 742 s baseline) and with the unresolved install-host exposure in Finding 1, so it is not drift. It is noted so the follow-up is deliberate.

No existing precedent in `scripts/health-check.sh` flags or `scripts/run-tests.sh` env vars for a parallelism knob (searched: `rg -n 'jobs|JOBS|parallel' scripts/ workflows/pr-prep.md`); the closest shape is the `RUN_TESTS_*` / `HEALTH_CHECK_*` env-seam family (`scripts/run-tests.sh:19`, `scripts/health-check.sh:11-26`). Severity already at the floor (Informational), so the no-precedent downgrade has no effect.

**Recommendation:** When the measurement justifies it, expose it through that family (e.g. `HEALTH_CHECK_BATS_JOBS`, passed as `--jobs`) rather than a new health-check flag (health-check documents "No arguments or options", `:9`), and add one line to pr-prep 5a.

## What Looks Good

- **Name and shape mirror the wrapped tool.** `--jobs N` is bats' own long flag and value form; `--jobs=N` is refused by both the runner and bats, so habits transfer. Long-only matches every other runner flag.
- **Backward compatible.** Default `jobs=1` adds nothing to `bats_args` (fact-check Claims 1, 13), so every existing invocation, including health-check's, is byte-for-byte unchanged. No versioning concern.
- **Composition is principled.** `--failed` still refuses scope-narrowing flags, and `--jobs` (which does not narrow scope) combines with it; `--failed --jobs 2 --slow` still exits 2 via the existing conflict. Repeated `--jobs` is last-wins, like the category flags (probed: `--jobs 4 --jobs 1` accepted; `--jobs 2 --jobs x` rejected).
- **Output and exit contract preserved.** TAP numbering, order and the exit status are identical to a serial run (probe above; `exec bats` keeps bats' status as the runner's). The run log, count check and `--failed` behave as in a serial run (fact-check Claim 7).
- **Degradation matches precedent.** Missing `parallel` is a `WARNING:` on stderr with a "; running …" tail and the run continues, exactly like the no-recording case, rather than a hard failure.
- **Messages and help.** The usage error names the flag and echoes the bad value (`got: (nothing)` for a missing one), then prints `usage`; the Usage line, Flags entry and a cross-referenced topic paragraph were all updated, and `--help` prints the new text through to the end.
- **Tests exercise the public surface** (exit 2 and message for bad N, the `parallel` hand-off, `--jobs 1`, `--failed` composition, kill refusal, locale, fallback), and two were mutation-checked (fact-check Claim 20).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Help text ships fact-check's Incorrect install-host claim plus two imprecisions | Minor | `scripts/run-tests.sh:84-97` | High |
| 2 | Usage errors exit 1 or 2 by spelling (`--jobs x` 2; `-j 2`/`--jobs=2` 1) | Minor | `scripts/run-tests.sh:124-142` | High |
| 3 | "positive integer" contract vs regex: `02` rejected, overflow silently serial | Minor | `scripts/run-tests.sh:36-37, 125, 390` | High |
| 4 | Under `--jobs`, bats' per-file stderr moves to stdout | Informational | `scripts/run-tests.sh:390-396` | Medium |
| 5 | Fallback accepts any `parallel`; text says GNU parallel | Informational | `scripts/run-tests.sh:391-394` | Low |
| 6 | No caller can reach `--jobs` yet (health-check, pr-prep) | Informational | `scripts/health-check.sh:392, 400` | High |

## Overall Assessment

The new flag is consistent with the runner's conventions and with bats: same name and value shape as bats' `--jobs`, long-only like its siblings, usage-error and warning messages in the established style, default behaviour unchanged, and a principled composition rule with `--failed`. Nothing breaks an existing consumer; the only programmatic caller (health-check) never passes the flag. The issues are all fixable in place and are about contract precision, not design: the `--help` text carries the fact-check's one Incorrect claim (which matters because it speaks to exactly the install-host risk Q-090 still has to measure), the value contract says "positive integer" but means "no leading zero, and not too big", and the diff adds a second exit-2 usage error beside the older exit-1 unknown-flag path. Findings 1 and 3 are one-line text/regex edits; 2 is a separate, optional convention change.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "a markdown report saved at the path named below, structured per the skill."
- **Answered:** yes. Saved at `docs/reviews/q090-api-consistency-review-2026-09-30.md` with `Commit: 088bc97` at the top, Baseline, Name-Pattern Audit, Findings (each with Severity, Location, verbatim Evidence, Confidence, Legibility-target), What Looks Good, Summary Table and Overall Assessment. All of the brief's surfaces were covered: flag, exit codes, messages, help text, composition with `--failed`/`--fast`/`--slow`/FILE, bats' `--jobs`, health-check and pr-prep.
- **Legibility-target:** for-author on Findings 1-3 (text/regex edits the author makes); for-orchestrator-synthesis on Findings 4-6 (context for the rubric, no action needed this pass).
- **Out of scope:** whether install-host.bats actually flakes under `--jobs` (needs a full or repeated run, which the brief forbids); moreutils `parallel` behaviour (not installed here).
- **Escalate:** none beyond the fact-check's Claim 3, which Finding 1 carries onto the help surface.
- **Decisions I made:** rated Finding 2 Minor rather than Inconsistent because the exit 1/2 split predates this diff and the commit Notes chose 2 on purpose; treated the absent `-j` short form as consistent (runner is long-only) and folded its exit-code effect into Finding 2. Probe scratch files are in the session scratchpad (`q090api/`), not the worktree.
