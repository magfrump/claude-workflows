Commit: de1f4bf9

# Performance Review — fix/confine-tests-dash-and-fallback

**Scope:** `git diff 23ffb16c..de1f4bf9`: `scripts/confine-tests.sh` and `test/scripts/confine-tests.bats` (the guide and docs carry no code)
**Date:** 2026-11-10
**Based on:** docs/reviews/code-fact-check-report-2026-11-10-confine-tests-dash-and-fallback.md (53 claims; none in the performance domain)

## Data Flow and Hot Paths

`scripts/confine-tests.sh` runs once per confined test-suite invocation: it detects a primitive, then execs it with the test command. It is a cold path. Its own cost is milliseconds, against a suite that runs for seconds to minutes. The diff changes three things on that path:

1. **The unshare-with-loopback run form** (`scripts/confine-tests.sh:267-273`) now runs its body under `"$BASH" -c` in place of `sh -c`. The process chain has the same shape as before: the script execs `unshare`, `unshare` execs the shell, the shell forks once for `ip link set lo up` (it did this before too), and then `exec -- "$@"` replaces the shell with the test command. The fact-check verified by execution that the test command runs as the script's pid on every run form (the `same_process` check), so the diff adds no long-lived process and no extra layer between the script and the tests.
2. **The interpreter's startup cost.** Measured on this host (dash 0.5.12 is `/usr/bin/sh`), 500 iterations each: `sh -c 'exec "$@"' sh true` took 744 µs per run, and `bash -c '<the new body shape>' x true` took 1058 µs. The difference is about 0.3 ms, paid once per confined run, only on that run form. `BASH_ENV` is unset by default, so it costs nothing. When a caller sets it, the cost is whatever that caller's file does, and the test runner (itself bash) pays the same cost again inside the namespace. Pre-mortem narrative 3 already records this case, with a revisit trigger.
3. **The fallback warning** (`:203-217`, `warn_unshare_only` at `:126-135`). `command -v bwrap` is a builtin PATH lookup that forks nothing. `warn_unshare_only` adds one `cat` fork for its heredoc, measured at 571 µs (`cat /dev/null`, 500 iterations). It runs once per fallback run or `--no-loopback` run. Before the diff, the `--no-loopback` warning used `echo` builtins, so that route now pays the one fork. It does not repeat inside any loop.

**Test file.** `bats test/scripts/confine-tests.bats` was timed in scratch copies (each revision's script and test file, in the same layout), three alternating runs each. Load average was 0.56 / 1.22 / 1.80 at the start and 0.56 / 1.20 / 1.79 at the end, on 16 CPUs:

| Revision | Tests | Wall time per run (ms) |
|---|---|---|
| 23ffb16c | 17 ok, 0 skip | 1156, 1095, 1083 |
| de1f4bf9 | 21 ok, 0 skip | 1409, 1365, 1434 |

The new revision adds about 0.3 s per file run (+26%). That is in proportion to the 4 added tests (+24%), so the existing tests did not get slower. The fact-check's figure of about 5 minutes for 20 runs of the mutation set is roughly 15 s per run. Each run is a mutant, plus its setup and its load, so that figure is not the file's own cost. At about 1.4 s, the file's `# @category slow` tag is generous. That tag predates this diff and is out of scope.

## Findings

No findings.

The two added costs (about 0.3 ms for bash over dash at startup, and about 0.6 ms for one `cat` fork) are per-invocation constants on a cold path that runs once per suite. Under the skill's calibration (Micro × Cold → Informational) they do not justify a reviewer's or the author's time, so they are recorded above as data and not filed as findings.

## Endorsements

- The unshare-with-loopback run form adds no long-lived process: the script execs `unshare`, the body execs the test command, and the only fork is the `ip link` child the body already had under `sh`. `[fact-check: same_process verified by execution on every run form — Verified]`
- The added test cost scales with the number of added tests (17 → 21 tests, about 1.1 s → 1.4 s per file run), with no slowdown of existing tests. `[unverified — submitted as claim]` (three timed runs per revision, measured by this reviewer; no per-test breakdown)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

From a performance standpoint this diff is neutral. The script is a once-per-suite cold path. The change of interpreter keeps the exec chain intact (fact-check, execution-verified) and costs about 0.3 ms per confined run. The fallback warning costs one `cat` fork per run that reaches it. The test file grows by about 0.3 s, in line with its four new tests. Nothing needs profiling or a fix. The one environment-dependent cost (`BASH_ENV` set by a caller) is already recorded as pre-mortem narrative 3, with a revisit trigger, and belongs to the caller's environment.

Legibility-target: for-orchestrator-synthesis (no findings; the endorsements above are routed to the fact-check intake).

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback/docs/reviews/performance-review-2026-11-10-confine-tests-dash-and-fallback.md, structured per the performance-reviewer skill, with a first line `Commit: de1f4bf9`.
- Answered: yes
- Out of scope: the `# @category slow` tag on a file that runs in about 1.4 s (it predates the diff); the cost of a caller's `BASH_ENV` file (the caller's own environment, already covered by pre-mortem narrative 3)
- Escalate: nothing
