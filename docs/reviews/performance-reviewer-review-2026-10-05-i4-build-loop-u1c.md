Commit: 13380172

# Performance Review — feat/build-loop-u1c, iteration 4 (fix commit 13380172)

**Scope:** `git diff 32bef87b..13380172` (scripts/build-loop.sh, test/scripts/build-loop-read.bats, docs/reviews/override-log.md)
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1c.md (Stage 1, k=1); shared block shared-stage2.md

## Data Flow and Hot Paths

`scripts/build-loop.sh --status BRIEF...` is a CLI run (cold path: one process per invocation, by a human or the build loop). `status_line` runs once per argument; on its first call it computes `SHARED_BRANCHES` via `shared_branches` (one `git grep` over main's briefs/, then `brief_fields` per matching file). N is the number of briefs on main (tens, not thousands). The fix commit changes only constant work inside that single `shared_branches` call and adds one string comparison per `status_line` call:

- `:302-303` `local f list b rc=0` / `local -A n=() BRIEF=()` — one extra local associative array, once per run.
- `:307-308` `git grep --no-color ...) || rc=$?`, then `[[ "$rc" -gt 1 ]] && SHARED_BRANCHES=error; return` — same single grep; the error path returns before the loop.
- `:311` `${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}` — anchored substitution, same cost as the old unanchored one.
- `:320` `[[ -n "$SHARED_BRANCHES" ]] || shared_branches` — `error` and `$'\n'` (the no-shared result from :315) are both non-empty, so the guard memoises every outcome.
- `:335` new `[[ "$st" == open && "$SHARED_BRANCHES" == error ]]` — O(1) per brief.

Measurements (scratch repo under the job scratch dir, hermetic git env as in test/lib/build-loop-fixtures.bash, 20 open briefs on main, `--status` with all 20, `GIT_TRACE=1` counting `built-in: git grep`):

| Case | git grep calls per run | wall time |
|---|---|---|
| normal (all open, distinct branches) | 1 | 584 ms |
| grep fails (`grep.patternType=bogus`, exit 128) | 1 | 428 ms |
| `color.ui=always`, `color.grep=always` | 1 | — (output correct: `ok ... feat/b1 absent - - 0`) |
| no open brief (grep exit 1) | 1 | — |

Micro-benchmark of the extra `local -A BRIEF=()`: 10,000 calls of `local -A n=() BRIEF=()` 45 ms vs `local -A n=()` 31 ms, i.e. ~1.4 µs extra per call; it is called once per run.

## Findings

No findings.

The per-brief cost (~15-21 ms per open brief; here ~29 ms/brief including the one-off grep and process start) is covered by override-log rows 266/267/269/301 and its premise is unchanged: the fix commit adds no per-brief process or git call. In the error case each open brief still pays `check_brief` + `brief_fields` before the skip at `:335`; that is the same settled per-brief cost, and the error run is cheaper than the normal one (no `check_branch`, no shared_branches loop).

## Endorsements

- `SHARED_BRANCHES=error` is computed once per run and never recomputed per brief: :320's `-n` guard skips on `error`, and the error path returns at :308 before any `brief_fields` call; measured 1 `git grep` per run with 20 briefs in the failing-grep case. [unverified — submitted as claim]
- `--no-color` and the `|| rc=$?` capture add no extra process: the grep is still one `$(...)` substitution per run (1 grep measured in all four cases above). [unverified — submitted as claim]
- The local `BRIEF` in `shared_branches` costs ~1.4 µs once per run (micro-benchmark above) and removes the call-order dependency at no measurable cost. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The fix commit is cost-neutral. Every change is constant work inside a function that runs once per CLI invocation (cold path), plus one O(1) string test per brief. The fail-closed `error` value is memoised by the existing guard, so a failing grep runs once, not once per brief. The settled per-brief cost (rows 266/267/269/301) is unchanged in premise. No profiling needed beyond the counts above.

## Goal-Alignment Note

Success criterion: A markdown report saved at the path named in your tail, structured per your skill, with a `Commit: 13380172` first line.

This report is at docs/reviews/performance-reviewer-review-2026-10-05-i4-build-loop-u1c.md, starts `Commit: 13380172`, and follows the performance-reviewer structure (header, Data Flow, Findings, tagged Endorsements, Summary Table, Overall Assessment). Scope held to 32bef87b..13380172; no other repo file was edited and nothing was committed. Probes ran under `timeout` in the job scratch dir; no process is left running.
