Commit: bd312d15

# Performance Review — fix/confine-tests-dash-and-fallback (final confirming pass)

**Scope:** `git diff 23ffb16c..bd312d15`: `scripts/confine-tests.sh` and `test/scripts/confine-tests.bats` (the guide and docs carry no code)
**Date:** 2026-11-10
**Based on:** docs/reviews/code-fact-check-report-final-r1-, -r2-, -r3-2026-11-10-confine-tests-dash-and-fallback.md (no Incorrect behavioural claim; none in the performance domain; no escalation to performance)

## Data Flow and Hot Paths

`scripts/confine-tests.sh` runs once per confined test-suite invocation: it detects a primitive, then execs it with the test command. It is a **cold path**: its own cost is milliseconds, in front of a suite that runs for seconds (this one test file: about 1.1-1.5 s) to minutes (the whole suite). Nothing in the diff runs in a loop or scales with any input; there is no collection, cache, query or lock. The diff changes three things on that path, measured here in a scratch copy of each revision (load average 0.35-0.80 on 16 CPUs throughout; `/usr/bin/sh` is dash 0.5.12; bash 5.2.15):

1. **The process chain of the unshare-with-loopback run form** (`scripts/confine-tests.sh:285-290`). Script (bash) `exec`s `unshare`; `unshare -rn` execs `"$BASH" -c BODY`; the body forks once for `ip link set lo up` (it forked the same `ip` under `sh` before); `exec -- "$@"` replaces bash with the test command. Every step but the pre-existing `ip` child is an exec, so no shell lingers as a parent of the tests. The shape is the same as at 23ffb16c with `sh` swapped for bash. Tests 16 and 17 call `same_process` (the command ran as the script's pid) and pass at bd312d15 in my runs, under the test file's stand-in `unshare`, which execs its command; nothing here ran under a real `unshare` (the container cannot create a namespace).
2. **bash in place of sh, per confined run.** 1,000 iterations, three rounds: `dash -c 'exec "$@"' sh true` 0.73-0.82 ms; `bash -c 'exec -- "$@"' x true` 1.02-1.07 ms. About **0.3 ms more per run**, only on this run form. Under `env -i` (as the tests run it) `BASH_ENV` is unset and costs nothing; a caller who sets it pays for its own file once more, and the test runner (bash) already pays it inside the namespace. Pre-mortem narrative 3 records that case with a revisit trigger, so I do not re-file it.
3. **The fallback warning** (`warn_unshare_only`, `:132-140`; the call block `:216-230`). `echo`, `printf` and `command -v bwrap` are bash builtins (`command -v` searches PATH and forks nothing); the one new fork is the `cat` for the heredoc at `:133`. Whole-script runs on a fallback (stand-in `unshare` and `ip`, no `bwrap`, command `true`), 1,000 iterations, three rounds: 23ffb16c 4.96-5.05 ms; bd312d15 with the warning disabled (copy with `fell_back=1` changed to `0`) 5.35-7.15 ms; bd312d15 as shipped 5.80-7.75 ms. Round-to-round noise (up to 2 ms) is as large as the effect; the stable rounds put the warning at about **0.5 ms** and the whole change at about **1 ms per fallback run**. The `--no-loopback` route also pays the one `cat` now, where it used seven `echo` builtins before. `--probe` is unchanged in cost: 2.7-3.3 ms at both revisions (300 iterations, two rounds), as expected since neither change runs on a probe.

**Test file.** `timeout 300 bats test/scripts/confine-tests.bats` in scratch copies (each revision's script and test file, layout `scripts/` and `test/scripts/` kept), five alternating runs each; load 0.44 at start, 0.56 at end:

| Revision | Tests | Wall time per run (s) |
|---|---|---|
| 23ffb16c | 17 ok, 0 skip | 1.085, 1.095, 1.139, 1.109, 1.144 |
| bd312d15 | 21 ok, 0 skip | 1.417, 1.545, 3.352, 1.477, 1.378 |

Medians 1.11 s and 1.48 s: about +0.35 s per file run, for four added tests (about 65 ms per test before, about 70 ms after). The 3.35 s run is a single outlier that no other run repeats. Against a whole suite of about 2,000 tests this is noise.

## Findings

No findings.

The added costs (about 0.3 ms for bash over dash, about 0.5 ms for one `cat` fork, once per confined run) are per-invocation constants on a cold path. Under the skill's calibration (Micro × Cold → Informational) they do not justify the author's time, so they are recorded above as measurements, not filed.

Legibility-target: for-orchestrator-synthesis (no findings).

## Endorsements

- The unshare-with-loopback form keeps the test command at the script's pid: script → `unshare` → `"$BASH"` → command are all execs, and the only fork is the `ip link` child the `sh` body already had. `[unverified — submitted as claim]` (tests 16-17's `same_process` pass at bd312d15 in my five runs, under the stand-in `unshare` only; per fact-check Claim 20 that check cannot tell `exec -- "$@"` from a bare `"$@"` under bash, which does not affect the pid result)
- The test file's added time is in proportion to its four added tests, with no slowdown of the existing ones. `[unverified — submitted as claim]` (five timed runs per revision by this reviewer; no per-test breakdown)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

From a performance standpoint the change is neutral. The script runs once per suite; swapping `sh` for `"$BASH"` keeps the exec chain and costs about 0.3 ms per confined run on that one form; the fallback warning costs one `cat` fork per run that reaches it; `--probe` costs the same as before; the test file grows by about 0.35 s for four tests. Nothing needs profiling or a fix. The earlier pass (at de1f4bf9) also filed no performance findings, so no fix in bd312d15 came from this role; its numbers (0.3 ms, 571 µs for `cat`, 1.1 s to 1.4 s) agree with mine, and bd312d15's changes since de1f4bf9 add no cost I could measure.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback/docs/reviews/performance-review-final-2026-11-10-confine-tests-dash-and-fallback.md, structured per the performance-reviewer skill, with a first line `Commit: bd312d15`.
- Answered: yes
- Out of scope: the cost of a caller's own `BASH_ENV` file (the caller's environment; pre-mortem narrative 3 holds it with a revisit trigger); any timing under a real bwrap or unshare (the container cannot create a namespace)
- Escalate: nothing
