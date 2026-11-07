Commit: 4dd68cdc

# Performance Review — refactor/d6-block-into-image

**Scope:** `git diff 5b20d4bd..HEAD -- scripts skills` (5 files; only `scripts/d6.sh` and the skill's call line change runtime behaviour)
**Date:** 2026-11-05
**Based on:** `docs/reviews/code-fact-check-report-2026-11-05-d6-block-into-image.md`, taken at 9f80368a, one commit behind this HEAD. No performance claim in it. Used for what `g` does (Claims 1, 28a); the timings below are this review's own.

**Answer to the question asked: no, the cost is not real.** Sourcing the lib twice costs about 3.1 ms per call, about 93 ms per 30-call iteration, on the lib this branch ships. A d6.sh preamble is still 7.5 to 10.5 ms cheaper per call than the old block, because the old block ran 16 child processes (7 git, 9 stat) where d6.sh runs 2 git. The change saves about 0.2 to 0.3 s of process time per iteration. Its larger saving is the 4.4 KB the orchestrator no longer writes out on each call.

## Data Flow and Hot Paths

d6.sh is a preamble in front of `build-loop.sh`, `dev-cycle.sh` and `questions.sh`. It runs once per call, about 30 calls per iteration (figure from the dispatch, not recounted), each already separated by an agent tool round trip. Path temperature: **cold**. It is neither a per-item loop nor a request path, and nothing waits on it at millisecond scale. Data size is fixed: the two names `main` and `master`.

Sourcing the lib is parse-only. Its top level defines functions and assigns literals; the only column-0 `$(` hits (`scripts/lib/dev-cycle-read.sh:159-191`) are one-line function bodies, so no process starts at source time.

### Measurements

Method: `perf1/bench.py`, 150 interleaved rounds, each variant in turn, warm page cache, 16 cores, load average 1.8 to 2.3. Cwd was a `--shared` clone of this branch. Preamble variants have only the final `env ... bash` line replaced by `exit 0`. The old block is byte-for-byte from `5b20d4bd:skills/dev-cycle/SKILL.md`, fed through `bash -s` as the skill did. All variants below exited 0.

| Variant | Median ms | p10 | p90 |
|---|---|---|---|
| empty `bash -c :` | 0.84 | 0.78 | 0.94 |
| old block, preamble only | 16.74 | 16.23 | 18.91 |
| d6.sh preamble, today's image lib (145 KB) | 9.21 | 8.91 | 10.35 |
| d6.sh preamble, this branch's lib (74 KB) | 6.27 | 6.00 | 7.23 |
| hoisted variant (one source), today's image lib | 6.27 | 5.99 | 7.06 |
| hoisted variant (one source), this branch's lib | 4.72 | 4.53 | 5.39 |
| old block + `dev-cycle.sh --check-path README.md`, today's image | 43.59 | 42.54 | 50.38 |
| d6.sh + the same, today's image | 35.62 | 34.83 | 40.63 |
| d6.sh + the same, stand-in for the next image (branch scripts) | 24.85 | 24.09 | 27.00 |

Two rows are the right comparison for two questions. Old against new on one image is 43.59 against 35.62 ms. The 24.85 ms row also includes `dev-cycle.sh` sourcing the smaller lib, which this branch did not cause: the lib was 145,094 bytes at the image's commit c214970a and 74,153 at 5b20d4bd, the base of this branch.

Child processes, counted with a logging PATH shim over `git` and `stat`: old block 7 git and 9 stat (16); d6.sh preamble 2 git and 0 stat (2).

Derived, 30 calls per iteration:

| Quantity | Branch lib | Today's image lib |
|---|---|---|
| One source (preamble minus hoisted) | 1.55 ms | 2.94 ms |
| Two sources per call | 3.10 ms | 5.88 ms |
| Two sources per iteration | 93 ms | 176 ms |
| Preamble saving against the old block, per iteration | 314 ms | 226 ms |
| What hoisting would save, per iteration | 46 ms | 88 ms |

Limits: warm cache only; a cold first read of the lib was not measured, and is at most once per iteration. `build-loop.sh --state` was also timed (48.36 old, 40.45 new) but both refused in the scratch clone, whose HEAD is not the default branch, so it is a refusal-path figure and is left out of the table. It shows the same 8 ms gap.

## Findings

#### The lib is parsed twice per d6.sh call, and this is not worth changing

**Severity:** Informational
**Location:** `scripts/d6.sh:36`, `scripts/d6.sh:49-53`
**Evidence:** `g() { ( source "$D6_OPT/scripts/lib/dev-cycle-read.sh" && git_harden && git "$@" ); }`
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed parse cost per call, no growth with repository data) / Cold path (about 30 calls per iteration, between agent tool round trips)
**Confidence:** High
**Baseline:** 1.55 ms per source on the branch's lib, measured as d6.sh preamble minus hoisted variant, medians of 150 interleaved rounds, 2026-11-05 (`perf1/bench.out`)
**Legibility-target:** for-orchestrator-synthesis

The multiplication is real: 2 sources per call, about 60 per iteration, all parsing the same file to obtain a 10-line function. It prices at 93 ms per iteration on the branch's lib, 12% of a 24.85 ms call, and the preamble that contains it is still 10.47 ms per call cheaper than the block it replaces. Cost follows lib size (2.94 ms at 145 KB, 1.55 ms at 74 KB), so it would only matter if the lib grew far past any size it has had, and even at 145 KB it is 176 ms per iteration.

**Recommendation:** Leave it. Hoisting saves 46 ms per iteration, and it would replace a one-line `g` with a subshell that has to carry the `rc` refusal logic back out through its own exit status, in a file that gates merges. That trade is not worth making in gate code.

## Endorsements

- The move from a pasted heredoc to one call line removes 4,371 bytes of block text per call that the skill told the orchestrator to write out "pasted whole", about 131 KB per 30-call iteration, as model output that also stays in session context. No token or dollar count was measured; the byte count is from the block's extracted size. [read: 5b20d4bd:skills/dev-cycle/SKILL.md:39,185-249]
- The d6.sh preamble is cheaper than the old block on the same image: 9.21 against 16.74 ms median, with 2 child processes against 16. This is a by-product of the checks commit 2b0838bb dropped on threat grounds, and should not be read as an independent reason for that narrowing. [unverified — submitted as claim]
- `exec` at `scripts/d6.sh:55` replaces d6.sh's bash with the target script rather than keeping a waiting parent, as the block's `env ...; exit "$?"` did. [read: scripts/d6.sh:55]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Lib parsed twice per call; about 93 ms per iteration; leave it | Informational | `scripts/d6.sh:36` | High |

## Overall Assessment

This change improves performance and needs no fix. The cost the review was asked to check exists and is small, and it is outweighed within the same preamble by the 14 fewer child processes. Nothing here needs more profiling. The one real saving not priced in milliseconds is the pasted block's output volume, which a token measurement could put a number on if anyone wants it; it does not bear on this merge.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/performance-review-2026-11-05-d6-block-into-image.md, first line `Commit: <HEAD short sha>`, each finding carrying Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with a Goal-Alignment Note (patterns/orchestrated-review.md). Edit nothing else; do not commit.
- Answered: yes; measured, the double source costs about 3.1 ms per call and d6.sh still beats the old block by 7.5 to 10.5 ms per call.
- Out of scope: whether the dropped checks should have been dropped (security and architecture critics); the about-30-calls figure was taken from the dispatch, not recounted.
- Escalate: nothing.
- Decisions I made: measured against both today's image lib (145 KB) and the branch's (74 KB), since /opt has no d6.sh yet and its lib predates a shrink unrelated to this branch; timed the old block on today's image only, as it does not source the lib.
