Commit: a57e5d27

# Performance Review — feat/build-loop-u0c, iteration 2 (fix a57e5d27)

**Scope:** `git diff feat/build-loop-u0c~1 feat/build-loop-u0c` (need_root in imported_names; cache keyed on ROOT_REAL with IMPORTED reset on miss; header inputs sentence; directive wording; T29 globals; new test; plan amendment) plus `git range-diff 27e38dc4^! feat/build-loop-u0c~1^!` (commit message and header-comment wording only).
**Date:** 2026-10-05
**Based on:** iteration-1 rubric `code-review-rubric-2026-10-04-feat-build-loop-u0c.md`; no iteration-2 fact-check report.

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Prior Must Address items (rubric 2026-10-04, U0c)

- A1 (commit message vs plan :187) — not perf; resolved per the range-diff (message now says check_fix's predicate extraction is deferred to U2) and the plan amendment in the diff.
- A2 (walk caches an empty set when ROOT_REAL unset) — not perf; resolved: `need_root` now runs before the cache test (lib `:339`), in the caller's shell, so the walk never runs or caches without a root.
- Iteration-1 perf C10 (cache lasts one process; build-loop.sh should call the lib directly) remains deferred to U1 per the override log; the fix keeps the cache per process and does not make it worse.

## Data Flow and Hot Paths

`imported_names` is called by `check_fix` (`scripts/dev-cycle.sh:174`) once per `--check-fix` argument. The first call does the walk (one `git ls-files` pair + grep, then a `$(lower ...)`, `inrepo` and `$(realpath ...)` fork per instruction file and per `@` import); every later call in the same process should return at the cache test. The fix changes the cache test from `[[ -n "$IMPORTED_DONE" ]]` to `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]]` and resets `IMPORTED=$'\n'` only on a miss (lib `:340`). ROOT_REAL is set once (`scripts/dev-cycle.sh:116`) and never reassigned, so within dev-cycle.sh the key never changes and the hit rate is the same as before.

Measured by this reviewer on 2026-10-05, this machine (bash microbenchmark in the review scratch dir): `need_root` 0.023 s per 10,000 calls (~2.3 µs/call); `main_by_name` 0.020 s per 10,000 (~2 µs/call); the `IMPORTED_DONE == ROOT_REAL` string compare 0.010 s per 10,000 (~1 µs); one `$(...)` subshell (the cost `inrepo`/`dirok`/`skipped` already pay for `blocker`) 0.330 s per 1,000 (~330 µs/call).

Cache hit-rate check (this reviewer, 2026-10-05): `DEV_CYCLE_SCRUBBED=1 bash -x scripts/dev-cycle.sh --check-fix docs/a.md docs/b.md docs/c.md README.md` traced one `git ls-files -z` and one `IMPORTED_DONE=/...` assignment for four arguments — the walk ran once. Wall time for that four-argument run: 0.377 s total.

Path temperature: cold per process (the walk); the cache compare is per argument and costs ~1 µs.

## Findings

No findings.

## Endorsements

- The root-keyed comparison keeps the one-walk-per-process hit rate in dev-cycle.sh: four `--check-fix` arguments traced one `git ls-files` and one `IMPORTED_DONE` assignment. [unverified — submitted as claim]
- `IMPORTED` is reset only on a cache miss, after the hit test, so a hit does no extra work and a root change cannot grow `IMPORTED` across roots (bounded by one root's import set). [unverified — submitted as claim]
- `need_root` in `imported_names` is a ~2 µs builtin test run once per `check_fix` call, before the cache test; it adds no fork. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The fix adds a string compare and a builtin guard per `check_fix` call (~3 µs together) and leaves the walk's once-per-process hit rate unchanged (traced). The reset-on-miss also prevents the memo from mixing roots, so memory stays bounded by one root's import set. No regression; the forward note C10 (per-process cache vs a per-path caller) stays with U1.

## Goal-Alignment Note

Serves landing U0c after a clean loop: checked the fix's per-call cost and its effect on check_fix's cache hit rate, the two performance questions the brief raised. Whether the new test fails when the guard is removed, and the plan amendment's wording, belong to the test/fact-check critics. From the performance side U0c is clean to land.
