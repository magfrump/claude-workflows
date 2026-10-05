Commit: e97eefce

# Performance Review — feat/build-loop-u0a, iteration 2 (fix e97eefce)

**Scope:** `git diff feat/build-loop-u0a~1 feat/build-loop-u0a` (need_root guard; rawfile/plaindir fail closed; comments; header Exit line; T29 rename; ROOT_REAL test). Move commit d7ea20b9 differs from reviewed b5209cbc only in its message.
**Date:** 2026-10-05
**Based on:** iteration-1 rubric `code-review-rubric-2026-10-04-feat-build-loop-u0a.md`; no iteration-2 fact-check report.

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Prior Must Address items (rubric 2026-10-04, U0a)

None of A1–A4 is in the performance domain. From the diff: A1 (planned build-loop.sh wording, `scripts/dev-cycle.sh:83`, lib `:2-4`) resolved; A3 (fail-open with ROOT_REAL unset) resolved — `need_root` runs in the caller's shell before the `$(blocker ...)` substitution in `inrepo`, `dirok`, `skipped`, and `rawfile`/`plaindir` now test `-n "${ROOT_REAL:-}"`; A4 (Exit line) resolved. A2 is a commit-message/plan item (resolved per the U0c amendment; outside this diff). Iteration-1 perf item C9 (start-up cost) is a Won't-Fix override; the fix does not change it.

## Data Flow and Hot Paths

`inrepo`, `dirok` and `skipped` are called a few dozen times per digest run (fixed-name inputs, section 8) and once per instruction file and per resolved `@` import inside `imported_names` (cold, once per process). The fix adds `need_root` — a single `[[ -n ]]` builtin test with no fork — at the top of each. `rawfile`/`plaindir` gain one `[[ -n ]]` term each; they run inside `blocker` per path component and per glob item (decision records, cycle records). Every one of these calls already pays a `$(blocker ...)` subshell or a `$(realpath ...)` fork that dwarfs the added test.

Measured by this reviewer on 2026-10-05, this machine (bash microbenchmark in the review scratch dir): `need_root` 0.023 s per 10,000 calls (~2.3 µs/call); `main_by_name` 0.020 s per 10,000 (~2 µs/call); the `IMPORTED_DONE == ROOT_REAL` string compare 0.010 s per 10,000 (~1 µs); one `$(...)` subshell (the cost `inrepo`/`dirok`/`skipped` already pay for `blocker`) 0.330 s per 1,000 (~330 µs/call).

Path temperature: cold (a CLI run once per cycle; per-call counts in the tens to low hundreds).

## Findings

No findings.

## Endorsements

- The added guard is a builtin string test placed before, not inside, the existing `$(blocker ...)` fork, so it adds ~2 µs to a call that already costs ~330 µs in subshell alone (<1%) and introduces no new fork or subshell. [unverified — submitted as claim]
- `rawfile`/`plaindir` short-circuit on the new `-n` term before `realpath`, so the fail-closed branch is cheaper than the normal one rather than more expensive. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The fix adds only O(1) builtin tests on cold-path functions, each ahead of an existing subshell that costs two orders of magnitude more; measured overhead is ~2 µs per call. No performance regression; nothing to profile.

## Goal-Alignment Note

The user goal is to land U0a–U0c after a clean review-fix loop. This review checked only whether the fix commit added per-call work on the reader's paths; it did not re-review the move (already reviewed) or the non-performance correctness of need_root's exit placement (security/fact-check own that). From the performance side U0a is clean to land.
