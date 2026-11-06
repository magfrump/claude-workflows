Commit: cb59c2bb

# Performance Review — test/q089-source-guard-narrow (Q-147 source guard)

**Scope:** `git diff db31db8b..cb59c2bb`. The only executable change is `test/cc-host-tool-sources.bats`. The other two files are docs.
**Date:** 2026-11-05
**Based on:** `docs/reviews/code-fact-check-report-q089-source-guard.md` (prose only, fixed in cb59c2bb; it makes no timing claims, so every number below is measured here).

## Data Flow and Hot Paths

The file is a static test with no runtime code path. It runs in `scripts/run-tests.sh --fast`, which `scripts/health-check.sh` uses as its blocking pre-gate at `--jobs` 8 or nproc, whichever is lower. So it is cold: a few runs per gate, on a fixed input.

Each test copies the five `devcontainer-config/cc-*.sh` files (3,416 lines) to a temp dir, then calls `check_entry`. The main cost is `source_lines_ok`, which applies bash regexes line by line across the entry point and what it sources. That is 2,476 lines for the launcher, about 135 ms per scan (median of 3). Cost is linear in those lines, and N is the size of these scripts, not anything user-scaled. The `bash -c` launcher source at line 49 took 5.1 ms (k=1): the temp dir holds no `host-tools.sha256`, so `verify_host_tools` returns 1 and the scan file is not loaded.

### Does `fast` hold? Yes.

All numbers are from this container (16 cores, load average 2-3.5), run serially with bare `bats`, k=5 per batch.

| Measure | Result |
|---|---|
| File wall time, batch 1 / batch 2 | 1.34-1.36 s / 1.29-1.32 s |
| Slowest test (`--timing`, one run) | 370 ms (test 1) |
| Other tests | 47-291 ms |
| Sample of the other fast suites (every 10th of 124, n=13) | 0.19-18.39 s, median 0.49 s, 4 of 13 over 1 s |
| Rank among those 13 plus this file | 10th of 14 |
| Estimated share of the fast gate at `--jobs 8` | about 0.17 s amortised, about 0.1% of 171 s |

- **The stated limit.** `run-tests.sh:26` says "pure function tests, <1s each". Read per test, the file passes with room to spare (370 ms). Read per file, 1.3 s is over, but so are 4 of the 13 sampled suites, by up to 18×, so that is not the reading the suite follows.
- **The "pure function" wording.** This file does use temp-dir I/O, which `--slow` names at `run-tests.sh:27`. So do 52 of the 124 fast suites (`mktemp` or `BATS_TEST_TMPDIR`), so the label is looser than the comment. That comment is outside this diff.
- **The gate.** The file is far from the sampled slowest suite (18.39 s), so it should not set the gate's time, which each run's slowest file bounds.
- **Limits of these numbers.** I did not measure under gate load. The 171 s figure is the "first gate" number in the `health-check.sh` comment, from a loaded host, so the 0.1% is an estimate. Nothing in the file depends on timing, so load can slow it but gives it no timeout to trip.

## Findings

#### Each passing `check_entry` scans the closure twice

**Severity:** Informational
**Location:** `test/cc-host-tool-sources.bats:45-46`
**Move:** Count the hidden multiplications
**Classification:** Micro (constant factor of 2 on a linear scan) / Cold path (test file, a few runs per gate)
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** 1.31 s file wall time, serial, median of 5 runs, this review, 2026-11-05 (0.86 s for the single-scan variant, same batch).

Evidence:

```
test/cc-host-tool-sources.bats:45-46
  why="$(source_lines_ok "$dir" "$entry")" || { echo "not a plain source line: $why"; return 1; }
  source_lines_ok "$dir" "$entry"
```

The first call runs in a command substitution, so its `SOURCED` array is lost and the second call repeats the scan to fill it. The double scan accounts for about 0.45 s of the file's 1.31 s, about 34%. A scratch variant that redirected the one call's output to a file passed all 7 tests. In absolute terms this is under half a second per serial run, and about 0.06 s amortised at `--jobs 8`. The pair also mirrors `devcontainer-config/cc-verify.sh:203-204`, so it reads as the known idiom.

**Recommendation:** Leave it. The file is fast enough, and the variant adds a temp file and drops the match with `cc-verify.sh`. This is recorded so that a later reader knows where a third of the time goes. Revisit only if the launcher grows several-fold.

## Endorsements

- Each test's temp dir is created in `setup` and removed in `teardown`, so the copies last one test. `[read: test/cc-host-tool-sources.bats:20-33]`
- The launcher sourced at line 49 runs `main` only when executed directly, and with no manifest in the temp dir `verify_host_tools` returns before hashing anything. `[read: devcontainer-config/cc-isolated.sh:244-255,748-753,1022-1024]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Each passing `check_entry` scans the closure twice | Informational | `test/cc-host-tool-sources.bats:45-46` | High |

## Overall Assessment

The `fast` tag holds: 1.3 s for 7 tests, slowest test 370 ms, and about 0.1% of the fast gate once parallelism is counted. Cost is linear in the size of three fixed scripts. The one finding is a measured constant factor that needs no change. Nothing here blocks landing, and no further profiling is needed.

## Goal-Alignment Note

- Success criterion (restated verbatim): "a critique at docs/reviews/performance-review-2026-11-05-q089-source-guard.md with a `Commit:` line, ending in a Goal-Alignment Note. Findings carry Severity, Location, verbatim Evidence, Confidence, Legibility-target. Do not commit or edit anything else."
- Answered: yes. The file's wall time is measured and `fast` holds on the per-test reading of the limit.
- Out of scope: the source-guard's coverage and correctness, and the docs in the diff; the `run-tests.sh` comment is outside the diff.
- Escalate: nothing
- Decisions I made: read `<1s each` as per test, because 4 of 13 sampled fast suites exceed it per file. Filed the double scan as Informational with a leave-it recommendation rather than omitting it, since it is 34% of the file's time.
