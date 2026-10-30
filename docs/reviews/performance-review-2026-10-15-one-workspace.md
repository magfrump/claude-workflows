Commit: a54bb3b0

# Performance Review — fix/cc-isolated-one-workspace

**Scope:** `git diff 5e6e9266..HEAD` (cc-isolated.sh main()/usage helpers, install.sh "Next steps", guides/cc-isolated-usage.md, 5 new tests in test/cc-isolated-functions.bats)
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-2026-10-15-one-workspace.md (Stage-1 summary)

## Data Flow and Hot Paths

**Parse path (cold).** `main()` walks argv once. The diff adds one `case` arm (`\#*)`), an integer compare on `ws_given` in the positional arm, and a post-loop block that checks `$#` after `--`. All of that is O(argc), and argc is a handful of words typed by a person, once per launcher invocation. The `printf %q` command substitutions and the `usage` awk pass sit only on the exit-2 error path. Classification: CLI argument parsing. Cold by the skill's hot-path gate. Nothing in the diff runs per file, per repo or per request. The install.sh change swaps one set of `echo` lines for another, runs once per install, and costs nothing.

**Test cost (measured).** I ran `bats --timing` in this worktree at a54bb3b0 on a 16-core host, load average about 1.4 at the start:

| Test | Time |
|---|---|
| a second workspace is a usage error in every mode… (3 launcher runs) | 257 ms |
| a pasted '# note' is refused at its first word… (3 runs) | 287 ms |
| after --: one workspace… (3 runs, one a full stubbed probe) | 480 ms |
| a directory named '#x' is still reachable… (2 full stubbed probes, 3 repos) | 377 ms |
| install.sh's Next steps print no command line carrying a trailing '# note' (sed/grep only) | 44 ms |
| **New tests total** | **1,445 ms** (2.09 s wall for the filtered run) |
| Whole file, 200 tests | 52,557 ms summed per-test, 57.3 s wall |

So the new tests add about 2.7% to the file. Each one stays under the "<1s each" bar that scripts/run-tests.sh sets for `--fast`. The most expensive one, at 480 ms, runs a successful stubbed `--probe-only`. That run is its only positive proof that the word after `--` is now the workspace (before the fix it was dropped and `$PWD` opened instead), so the cost buys a real assertion. The full suite run here had 3 failures (tests 128, 129, 188, at file lines around 1784). All are outside the diff, in launch/exit-scan wording asserts. The fact-check stage reports that the suite's reds are pre-existing. I did not re-run them on the base.

## Findings

No findings.

## Endorsements

- The new parse checks cost O(1) per argument: one glob arm and one integer compare inside the existing single argv loop, plus at most two `$#` tests after it. No new loop and no subshell on the success path. `[read: devcontainer-config/cc-isolated.sh:761-795]`
- The 5 new tests add 1,445 ms to a 52.6 s file (about 2.7%), and each is under 1 s. Measured by `bats --timing` at a54bb3b0 on 2026-10-15. Raw output is at /home/node/.claude/jobs/00bcf178/tmp/one-ws/perf/new5.txt and full.txt. `[read: test/cc-isolated-functions.bats:383-471]`
- The install.sh structural test reads the file with sed/grep. It does not run install.sh, which makes it the cheapest test in the batch (44 ms). `[read: test/cc-isolated-functions.bats:459-471]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The change has no measurable performance effect. The production change is a constant amount of extra work per argument in a cold CLI parse path, plus formatting that runs only on the error path. The test cost fits the suite's fast budget: about 1.4 s across 5 tests, about 2.7% of the file. The one test that runs a full stubbed probe needs it to make its positive assertion. No profiling or benchmarking is needed.

## Goal-Alignment Note

The goal is to land "cc-isolated takes one workspace per run" as a clean, reviewed branch. From a performance angle nothing blocks that. The parse change is cold and O(argc). The new tests are cheap and sit within the fast suite's per-test budget. Correctness issues raised elsewhere, such as `--profile '#'` consuming the next word (fact-check F5), have no performance side. They belong to the security and API reviewers, not here.
