Commit: 698348ac

# Performance Review — feat/build-loop-u0b, final confirming pass (full range)

**Scope:** `git diff feat/build-loop-u0a..feat/build-loop-u0b` (0b53fe50, fbe3a219, 698348ac) and their commit messages
**Date:** 2026-10-05
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u0b.md` (merged k=3, Commit 698348ac: no behavioural claim wrong)

## Data Flow and Hot Paths

U0b moves `FENCE_AWK`, `oddwhy`, `check_brief`, `check_branch` and `resolve_main` into the lib and adds `main_by_name` (two `[[ -n ]]` tests) at the top of `check_brief` and `check_branch`, plus `need_root` at the top of `check_brief`. `resolve_main` runs once per process; `check_brief`/`check_branch` once per `--check-brief`/`--check-branch` argument (a handful of briefs per cycle). Each `check_brief` already spawns `$(blocker)`, `git ls-tree | cut`, `git cat-file | awk` and one or two `git log` walks; `check_branch` spawns `check-ref-format` x2, `show-ref`, `rev-parse`, `rev-list --count`, `git log`. Path temperature: cold (per CLI argument).

Measured by this reviewer, 2026-10-05 (same setup as the U0a report): digest median main 421 ms vs U0b 417 ms (7 interleaved runs each, `416 412 414 417 422 423 443`), output md5 identical; `need_root` ~324 µs/call; `main_by_name` was measured at ~2 µs/call in iteration 2.

## Findings

#### check_brief's need_root adds one `$(pwd -P)` subshell per brief

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:236-238` (U0b tip)
**Move:** Count the hidden multiplications
**Classification:** Micro (one fork per call) / Cold path (per `--check-brief` argument)
**Confidence:** High
**Baseline:** need_root ~324 µs/call (1,000-call microbenchmark, this reviewer, 2026-10-05)
**Evidence:** `check_brief() {` … `  need_root`
**Legibility-target:** for-author

Each brief now pays one more subshell (~0.3 ms) ahead of 5-6 git/awk processes that each cost milliseconds, so the added share is a few percent of a per-brief call. It runs before `main_by_name`, so the refusal path (no default branch by name) pays it too, but that path then skips all git work. Same mechanism as U0a finding 1; listed here only because this unit adds the call site.

**Recommendation:** None for landing. The open forward note C6 (`git log -G'^Status: '` grows with history, once per brief; override log 2026-10-05, Defer to U1 `--status`) remains the per-brief cost worth measuring, not this fork.

## Endorsements

- `main_by_name` is two builtin tests with no fork, and on refusal `check_brief`/`check_branch` return before any git process, so the no-main path is cheaper than before. [read: scripts/lib/dev-cycle-read.sh:231 and the two call sites in check_brief/check_branch]
- `resolve_main` is called once per process by dev-cycle.sh (unchanged from main), and the move did not add a second call. [unverified — submitted as claim]
- The digest at U0b produces main's bytes in the same wall time (median 417 vs 421 ms). [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | check_brief's need_root forks once per brief | Informational | `scripts/lib/dev-cycle-read.sh:236-238` | High |

## Overall Assessment

A verbatim move plus O(1) guards ahead of fork-heavy per-argument git work. No regression in digest time or output; the one new fork per brief is noise beside the git processes. C6 stays deferred to U1 as recorded. Nothing to fix before landing.

## Goal-Alignment Note

Serves landing U0b after a clean loop: checked the guards' per-call cost against check_brief/check_branch's existing git work and re-measured the digest against main. Nothing blocks; from the performance side U0b is clean to land.
