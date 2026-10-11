Commit: 01a2935f

# Performance Review — feat/build-loop-u3a3 (U3a3, final confirming pass)

**Scope:** `git diff main...HEAD` (full branch: 18f32952, a7a4f784, e25a6e89, 01a2935f): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh (tests and review docs read for context only)
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3a3-final.md (k=3 merge; 0 behavioral Incorrect; the floor cost sentence is Verified in every replicate, r1 Claim 18, r2/r3 Claim 19); the iteration-1 performance review (performance-review-2026-10-10-u3a3-i1.md); the override log's U3a3 rows.

## Data Flow and Hot Paths

The gate's only per-item hot loop is check_line's `for i in "${!ps[@]}"` (scripts/build-loop.sh, check_line, read in full). It runs once per changed path of a brief, up to the 400-path budget, for `--check` and `--merge` alike. The branch adds the following to that loop or below it:

1. `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` on every path, under every authority. 01a2935f/e25a6e89 added a third alternation (`|^skills/dev-cycle/`) to GATE_CODE.
2. srules' `DENY="$(floor_why "$FLOOR_WHY")"`, one subshell for each path the floor denies. This is settled: override row "srules forks $(floor_why) per floor-denied path ...", Low, Defer.
3. truthwalk's `TRUTH_WHERE="$(walk_why ...)"`, run only when a walk fails. The main arm forks once per path that reaches `truthwalk main` after a cached failure, which is the same settled row. The tree arm forks only when `IMPORTED_WHY` is `readers`. On a cache hit for any other failed tree walk, imported_names returns before it sets `IMPORTED_WHY`, so the value stays empty from the walk that cached it and nothing forks. That path is dev-cycle.sh check_fix, one call per `--check-fix` argument: cold.

The approval path (`approval`, then `land "$AUTH" "$APPROVED"`) runs once per `--merge --approved`. It costs one check_answer (ANSWER_AWK over at most two blobs from main's commit), one write to `$GATE_TMP/answer` and one `$(< file)` read back. That is cold. Under AUTH=approved, `sm` is never set, so checkout_gate (about 0.3 s a brief, per check_line's comment), read_paths and srules are all skipped (fact-check r1 Claim 1, Verified, executed). land changed only in its message: one `printf` for the trailer.

Since iteration 1, the code changed in four places: `$(cat FILE)` became `$(< FILE)`, approval gained two `case` arms, the trailer is now keyed on `$1`, and GATE_CODE gained its third alternation. Only the first and last of these touch cost, and they were measured.

**Measurements** (probe `/tmp/claude-1000/-workspace/675070f9-0197-40a3-bd3c-520157521989/scratchpad/u3a3-final/performance/probe.sh`, output `probe.out` beside it; 3 runs, lib sourced under `set -euo pipefail`, LC_ALL=C, 16 cores, load 0.75, 2026-10-10):

| Operation | Total | Per call |
|---|---|---|
| GATE_CODE test, new 3-alternation regex, 401 paths | 3.9-4.7 ms | ~10-12 µs |
| GATE_CODE test, old 2-alternation regex, 401 paths | 3.2-3.3 ms | ~8 µs |
| `r="$(< f)"`, 200 calls | 2.3-2.5 ms | ~12 µs (bash reads it with no fork) |
| `r="$(cat f)"` (iteration-1 form), 200 calls | 124-131 ms | ~0.63 ms |
| `x="$(floor_why gate)"`, 401 calls | 141-146 ms | ~0.35-0.36 ms |

## Findings

No findings.

The settled per-denied-path floor_why/walk_why forks were re-measured to check for regression. They have not regressed: ~0.35 ms a floor_why call now, against 0.36-0.43 ms in iteration 1. The code path is unchanged since a7a4f784 (`git diff a7a4f784..HEAD` does not touch srules or truthwalk). The row stays settled. The third GATE_CODE alternation costs about +2-4 µs a path, about +1.5 ms over 401 paths. That is not worth a finding at this N.

## Endorsements

- C7's fix measured better than proposed. `$(< FILE)` costs about 12 µs, against about 0.63 ms for `$(cat FILE)`, because this bash reads the file in-process without forking. The approval path saves about 0.6 ms a run. [read: scripts/build-loop.sh approval, `check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"`; measured by the probe above]
- Under AUTH=approved, check_line skips checkout_gate, read_paths and srules. The approved landing therefore does no more per-path work than a self-merge `--merge` and skips about 0.3 s of checkout check. [fact-check: claim 1 (r1) — Verified, executed]
- floor's own forks with `$4` given are only truthwalk main's `$(walk_why ...)` after a failed walk. srules' floor_why fork is the caller's and is the settled row. [fact-check: claim 18 (r1) / 19 (r2, r3) — Verified]
- The GATE_CODE test is one in-shell ERE match a path (about 10-12 µs, about 4-5 ms at the 400-path budget). It needs no fork or batch. [read: scripts/build-loop.sh check_line, `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1`; measured by the probe above]
- check_answer's added work is constant per questions file: `head = substr($0, 5)` on the first matching heading only, one extra `print head`, and two parameter expansions in bash to split it. [read: scripts/lib/dev-cycle-read.sh ANSWER_AWK `heading($0) { ... if (inside) head = substr($0, 5); next }`, END block, check_answer `hit="${r%%$'\n'*}"; head="${r#*$'\n'}"`]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings (settled floor_why/walk_why fork row re-measured: not regressed) | — | — | — |

## Overall Assessment

The branch leaves the gate's performance posture unchanged. Each addition is constant per path (one regex test) or constant per run (one check_answer, one in-process file read, one printf). Nothing is quadratic, no collection grows without bound, and no cache changes. The approved path does strictly less work than the self-merge path it parallels. The only per-path regression in the branch is the deferred floor_why/walk_why fork row: Low, paid only by refusing runs, and not regressed in this pass. The one change since iteration 1 that touches cost, `$(< FILE)`, measured as a net improvement. No further profiling is needed before merge.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/performance-review-2026-10-10-u3a3-final.md, structured per the performance-reviewer skill, with `Commit: 01a2935f` at the top."
- **Answered:** yes. The full branch diff was read, and check_line, approval, land's changed lines, srules, floor, floor_why, truthwalk, check_answer and ANSWER_AWK were read. The two cost-bearing changes since iteration 1 and the settled row were measured. The probe ran under `timeout` in the scratch dir only. Nothing in the worktree was written except this report, and nothing was committed.
- **Out of scope:** an end-to-end timing of check_line over 400 real paths. The probe times the operations on their own, and its fork costs are lower bounds for build-loop.sh's larger shell. Test-suite runtime is also out of scope.
- **Escalate:** nothing.
