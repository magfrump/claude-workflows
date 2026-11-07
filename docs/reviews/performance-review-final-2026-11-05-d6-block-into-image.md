Commit: 48498ba6

# Performance Review (final pass) — refactor/d6-block-into-image

**Scope:** `git diff 4dd68cdc..48498ba6 -- scripts` (2 files; only `scripts/d6.sh:37-38,52` changes behaviour, the `scripts/lib/dev-cycle-read.sh` hunks are comments)
**Date:** 2026-11-05
**Based on:** `docs/reviews/performance-review-2026-11-05-d6-block-into-image.md` (the earlier pass) and `docs/reviews/code-fact-check-report-final-2026-11-05-d6-block-into-image.md` (taken at 1c5fd04f). The fact-check makes no performance claim. The timings below are this review's own.

**Answer to the question asked: the conclusion stands, but one of its numbers changes.** The third source adds about 1.9 ms per call, about 58 ms per 30-call iteration, on the lib this branch ships. The conclusion was "not worth changing", and it still holds. The number to replace is the earlier "7.5 to 10.5 ms cheaper per call than the old block". It is now 4.1 to 8.7 ms, and 8.7 ms is the figure that applies, because the 4.1 ms case cannot ship (see below). The saving per iteration falls from 314 ms to 260 ms.

## Data Flow and Hot Paths

Unchanged from the earlier pass: d6.sh is a preamble that runs once per call, about 30 calls per iteration (figure from the earlier dispatch, not recounted), with an agent tool round trip between calls. Path temperature: **cold**. Data size is fixed at two ref names.

What changed: `( harden )` at `scripts/d6.sh:52` runs before the loop, and `g` now goes through `harden`, so the preamble has three subshells that each source the lib. The new subshell costs one fork and one parse and starts no process.

Counted, not inferred:

- A counting copy of the lib logged 3 sources on a preamble that passes.
- A logging PATH shim saw 2 `git show-ref` and 0 `stat`, the same 2 children as before.
- A whole `dev-cycle.sh --check-path` or `build-loop.sh --state` call logs **5** sources. The other two are `scrub_reexec`: the script sources the lib, re-runs itself, and sources it again (`scripts/dev-cycle.sh:101`, `scripts/build-loop.sh:574`, `scripts/lib/dev-cycle-read.sh:139-144`). `scrub_reexec` is already in `dev-cycle.sh` at 5b20d4bd, so it is not this branch's cost.
- `questions.sh` has no lib source of its own, by grep. The one call tried there, `--help`, exited 1 with 3 sources.

### Measurements

Method: `perf3/bench.py`, the earlier harness with these variants added, 150 interleaved rounds, warm page cache, 16 cores. Cwd was a `--shared` clone with `main` at 48498ba6. Preamble variants have the final `exec env ... bash` line replaced by `exit 0`. The branch-lib stand-in is `scripts/` from 48498ba6 (74,362 bytes); today's image lib is 145,094 bytes. The old block is the earlier pass's `old_pre.sh` and `old_full.sh`. All variants exited 0.

Load average was 3.9 to 7.8 against the earlier 1.8 to 2.3, because other sessions were active, so the p90s are wider. The medians of the unchanged variants still reproduce: old block 16.93 against 16.74, two-source 6.31 against 6.27, two-source on the image lib 9.37 against 9.21.

| Variant | Median ms | p10 | p90 |
|---|---|---|---|
| empty `bash -c :` | 0.83 | 0.77 | 1.01 |
| old block, preamble only | 16.93 | 16.31 | 20.57 |
| preamble, 1 source, branch lib | 4.83 | 4.53 | 5.88 |
| preamble, 2 sources (4dd68cdc), branch lib | 6.31 | 5.96 | 8.17 |
| preamble, 3 sources (48498ba6), branch lib | 8.25 | 7.88 | 10.39 |
| preamble, 1 source, today's image lib | 6.38 | 5.99 | 7.98 |
| preamble, 2 sources, today's image lib | 9.37 | 8.90 | 11.16 |
| preamble, 3 sources, today's image lib | 12.84 | 12.28 | 16.35 |
| old block + `dev-cycle.sh --check-path README.md`, today's image | 43.86 | 42.65 | 55.96 |
| d6.sh 3 sources + the same, today's image | 39.57 | 38.24 | 48.89 |
| d6.sh 2 sources + the same, branch scripts | 25.08 | 24.21 | 31.74 |
| d6.sh 3 sources + the same, branch scripts | 27.36 | 26.20 | 33.03 |

Derived, 30 calls per iteration:

| Quantity | Branch lib | Today's image lib |
|---|---|---|
| Added by the third source, per call | 1.94 ms | 3.47 ms |
| Added by the third source, per iteration | 58 ms | 104 ms |
| Preamble saving against the old block, per call | 8.67 ms | 4.09 ms |
| Preamble saving against the old block, per iteration | 260 ms | 123 ms |
| What one source would save, per call | 3.42 ms | 6.45 ms |
| What one source would save, per iteration | 103 ms | 194 ms |

**Read the branch-lib column.** `/opt/claude-workflows/scripts/d6.sh` does not exist, so d6.sh reaches a session only in an image built with it, and that image carries this branch's lib or a later one. The image-lib column is an upper bound for a pairing that does not ship, kept for comparison with the earlier report. The old block does not source the lib, so its 16.93 ms applies to either image.

On a whole call, the third source measures 2.28 ms (25.08 to 27.36), in line with the 1.94 ms from the preamble rows. That is about 8% of the call.

Limits: warm cache only, as before. Cold reads were not measured. The 30-call figure was not recounted.

## Findings

#### The lib is now parsed three times per d6.sh call, and this is still not worth changing

**Severity:** Informational
**Location:** `scripts/d6.sh:37-38`, `scripts/d6.sh:52`, `scripts/d6.sh:55`
**Evidence:** `( harden ) || no "$D6_OPT/scripts/lib/dev-cycle-read.sh did not load, or its git_harden refused this environment"`
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed parse cost per call, no growth with repository data) / Cold path (about 30 calls per iteration, between agent tool round trips)
**Confidence:** High
**Baseline:** 8.25 ms per d6.sh preamble on the branch's lib, against 6.31 ms at 4dd68cdc, medians of 150 interleaved rounds, 2026-11-05 (`perf3/bench.out`)
**Legibility-target:** for-orchestrator-synthesis

The multiplication is now 3 sources per call, about 90 per iteration, and the preamble is 31% slower than it was at 4dd68cdc. It is still about half the cost of the block it replaces. The extra cost is 58 ms per iteration, spread across 30 agent tool round trips. The growth follows lib size, as the earlier pass found, and stays a fixed cost per call.

Hoisting is now worth more than the earlier pass priced it: 103 ms per iteration against 46 ms. That is still small. The third source also buys something: a broken lib gets its own refusal, and exit 1 in the loop can only come from `show-ref`, which the comment at `scripts/d6.sh:50-51` gives as the reason. The one-source variant timed here was built for the measurement and is not a patch. As written it would report `git_harden`'s own `exit 1` as the wrong refusal, because it only maps exit codes 3 and 4. A correct version has to carry those outcomes out through a command substitution, in a file on the merge floor.

**Recommendation:** Leave it. Correct the earlier report's headline figures in any synthesis: 8.7 ms per call and 260 ms per iteration replace 10.5 ms and 314 ms.

## Endorsements

- The check at `scripts/d6.sh:52` adds no child process: the preamble's shim count stays at 2 `git show-ref` and 0 `stat`, against 16 children for the old block by the earlier pass's count. [unverified — submitted as claim]
- The `scripts/lib/dev-cycle-read.sh` hunks in this diff are comment-only, so the lib's parse behaviour is as the earlier pass found it, apart from 209 more bytes against the 74,153 it measured at 5b20d4bd. [read: git diff 4dd68cdc..48498ba6 -- scripts/lib/dev-cycle-read.sh]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Lib parsed three times per call; about 58 ms more per iteration; leave it | Informational | `scripts/d6.sh:52` | High |

## Overall Assessment

The change still improves performance and needs no fix. The third source costs about 2 ms per call and gives back about a sixth of the earlier saving, leaving the preamble 8.67 ms per call cheaper than the old block on any image that can ship d6.sh. The earlier report's larger saving, the 4.4 KB the orchestrator no longer writes out per call, is untouched by this diff. Nothing here needs more profiling.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/performance-review-final-2026-11-05-d6-block-into-image.md, first line `Commit: 48498ba6`, ending with a Goal-Alignment Note (patterns/orchestrated-review.md). Edit nothing else; do not commit.
- Answered: yes; the conclusion stands, and the per-call margin over the old block is now 8.67 ms on the branch lib, down from 10.47 ms.
- Out of scope: the two `scrub_reexec` sources per script call, which predate this branch; whether the refusal wording is right (other critics); the about-30-calls figure was not recounted.
- Escalate: synthesis should use this report's figures in place of the earlier 7.5 to 10.5 ms and 314 ms.
- Decisions I made: treated the branch-lib column as the real one because d6.sh cannot ship with today's lib, though the earlier report gave both columns equal weight; measured hoisting again with a timing-only variant rather than a behaviour-equivalent patch.
