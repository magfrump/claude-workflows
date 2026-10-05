Commit: 09cb3764

# Performance Review — feat/build-loop-u0b, iteration 2 (fix 09cb3764)

**Scope:** `git diff feat/build-loop-u0b~1 feat/build-loop-u0b` (main_by_name guard in check_brief/check_branch; MAIN/MAIN_SHA/MAIN_BY_NAME initialised; header contract; FENCE_AWK directive; tests) plus `git range-diff 7cbbe8d2^! feat/build-loop-u0b~1^!` (comment and T29-list conflict resolutions only).
**Date:** 2026-10-05
**Based on:** iteration-1 rubric `code-review-rubric-2026-10-04-feat-build-loop-u0b.md`; no iteration-2 fact-check report.

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Prior Must Address items (rubric 2026-10-04, U0b)

A1 (check_brief/check_branch answering without a default branch found by name) — not a performance item; resolved in the diff: both functions now open with `if ! main_by_name; then echo "skip ..."; return; fi` (lib `:231`, `:277`), and the globals are initialised to empty at lib `:220`. Iteration-1 perf C6 (`git log -G` walk per brief grows with history) is deferred to U1 per the override log; the fix neither worsens nor touches it.

## Data Flow and Hot Paths

`check_brief`/`check_branch` run once per argument of `--check-brief`/`--check-branch`; each already spawns several git processes (`git show`, `git log`, `git rev-parse`, `check-ref-format`). The fix adds one `main_by_name` call (two `[[ -n ]]` builtin tests, no fork) at the top of each. When the guard fails, the function returns before any git call, so the no-main path is strictly cheaper than before. The range-diff of the rebased move commit changes only comments and the T29 list — no code.

Measured by this reviewer on 2026-10-05, this machine (bash microbenchmark in the review scratch dir): `need_root` 0.023 s per 10,000 calls (~2.3 µs/call); `main_by_name` 0.020 s per 10,000 (~2 µs/call); the `IMPORTED_DONE == ROOT_REAL` string compare 0.010 s per 10,000 (~1 µs); one `$(...)` subshell (the cost `inrepo`/`dirok`/`skipped` already pay for `blocker`) 0.330 s per 1,000 (~330 µs/call).

Path temperature: cold (per CLI argument; a build loop calls these per brief/branch, single-digit to tens of arguments).

## Findings

No findings.

## Endorsements

- `main_by_name` costs ~2 µs per call against per-argument git work measured in milliseconds; it adds no fork, and on the refusal path it skips all of that git work. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The guard is an O(1) builtin check ahead of fork-heavy per-argument work; negligible cost, and it removes work on the refused path. No performance regression. C6 remains the only open perf item for this code and stays with U1's measurement as recorded.

## Goal-Alignment Note

Serves landing U0b after a clean loop: checked only the added per-call work from the fix and the rebase. Correctness of the guard's semantics (e.g., `MAIN_BY_NAME` set by resolve_main) is for the security/API/fact-check critics. From the performance side U0b is clean to land.
