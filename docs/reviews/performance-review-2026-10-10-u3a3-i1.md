Commit: a7a4f784

# Performance Review — feat/build-loop-u3a3 (U3a3, iteration 1)

**Scope:** `git diff main...HEAD` (18f32952 tests, a7a4f784 code): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3a3-i1.md (26 claims, no code defects; Claim 18 covers the fork claim in floor's cost comment)

## Data Flow and Hot Paths

The per-path hot loop is check_line's `for i in "${!ps[@]}"` (scripts/build-loop.sh:1038-1045). It runs once per changed path of a brief, under the brief's budget of 400 paths. Prior measurement: about 6.4 ms a path for floor before U2c2's batch lower. The diff adds three things to that loop or below it:

1. A `[[ =~ $GATE_CODE ]]` test on every path, under every authority (`--check` included).
2. In srules, a `$(floor_why "$FLOOR_WHY")` subshell for each path the floor denies. floor now stores a word and the caller turns it into a sentence.
3. In truthwalk, a `$(walk_why ...)` subshell each time the walk fails. main_imports caches its failure, so once the main walk has failed, every later path that reaches `truthwalk main` in floor forks one walk_why. Before this diff, floor forked the same walk_why inside its FLOOR_WHY string. The fork moved; it did not multiply (fact-check Claim 18).

The approval path (`approval`, scripts/build-loop.sh:1070-1084) runs once per `--merge --approved`: one check_answer (awk over two git blobs) and one `$(cat)`. It is a cold path. AUTH=approved also skips `checkout_gate` (about 0.3 s, per the comment at :1022) and `read_paths` for a self-merge brief, so that path does less work than a self-merge `--merge`.

dev-cycle.sh check_fix makes one `truthwalk tree` call per `--check-fix` argument. It now forks walk_why only when the tree walk fails with IMPORTED_WHY=readers. That path is cold: a handful of arguments, and only on failure.

**Measurements** (probe `/tmp/claude-1000/-workspace/675070f9-0197-40a3-bd3c-520157521989/scratchpad/u3a3-i1/performance/probe.sh`, 3 runs, 401 synthetic lower-cased paths, the lib sourced under `set -euo pipefail`, 16 cores, load 0.5-0.8). The probe shell holds only the lib. build-loop.sh's real shell is larger and forks a little slower, so treat the fork costs as lower bounds.

| Operation | Total for 401 | Per call |
|---|---|---|
| `[[ ! "$p" =~ $GATE_CODE ]] \|\| gc=1` | 3.3-3.5 ms | ~8.5 µs |
| `x="$(floor_why gate)"` | 143-173 ms | 0.36-0.43 ms |
| `x="$(walk_why tree)"` | 157-171 ms | 0.39-0.43 ms |
| walk_why + floor_why pair (failed main walk, per path) | 343-387 ms | 0.86-0.97 ms |

## Findings

#### F1. srules forks a `$(floor_why)` subshell per floor-denied path (a second fork per path after a failed main walk)

**Severity:** Low
**Location:** `scripts/build-loop.sh:831`; `scripts/lib/dev-cycle-read.sh:1892`, `:1962-1978`
**Move:** Count the hidden multiplications; work moved to the wrong place
**Classification:** Micro (one fork per denied path) / Hot path (check_line's per-path loop, up to 400 paths)
**Confidence:** High (measured)
**Baseline:** $(floor_why) subshell 0.36-0.43 ms a call, measured by the probe above on 2026-10-10 (401 calls, 3 runs)
**Legibility-target:** for-author

Evidence:
```bash
# scripts/build-loop.sh:831
  if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY="$(floor_why "$FLOOR_WHY")"; return 0; fi
# scripts/lib/dev-cycle-read.sh:1892
    main) main_imports || { TRUTH_WHERE="$(walk_why "$IMPORTED_MAIN_WHY")"; return 0; } ;;
```
Before this diff, floor set FLOOR_WHY to the sentence directly. Only the walk-failure branch forked, through `$(walk_why "$IMPORTED_MAIN_WHY")`. Two things change now. Every floor denial of any kind (gate, record, working, review, instr, ...) costs one extra subshell. And when the main walk has failed and its failure is cached, each path that reaches `truthwalk main` costs two forks instead of one: walk_why in truthwalk plus floor_why in srules. Worst case is 400 denied paths: about +160 ms of added forks on a self-merge `--check`/`--merge` whose verdict is already a refusal. The pair costs about 0.9 ms a path, against the earlier ~6.4 ms floor baseline. The cost lands only on refusing runs and grows linearly with the path count. It does not grow faster, and the cost of a passing run is unchanged.

**Recommendation:** Optional. To get back to the earlier fork count, have floor_why write its result to a variable instead of echoing it (`printf -v DENY ...`, or set a global such as FLOOR_TEXT), and call it without `$(...)`. In truthwalk, compute TRUTH_WHERE once per cached failure, e.g. keyed on `$IMPORTED_MAIN_WHY` and cleared by import_reset, instead of once per path. Neither change is needed for the 400-path budget.

#### F2. approval reads its one-line answer through `$(cat FILE)`

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1075`
**Move:** Hot-path gate (cold path)
**Classification:** Micro (one fork) / Cold path (once per `--merge --approved`)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative (by analogy to the probe's 0.4 ms subshell, plus one exec of cat)
**Legibility-target:** for-author

Evidence:
```bash
  check_answer "$1" > "$GATE_TMP/answer"; r="$(cat "$GATE_TMP/answer")"
```
The write to a file is required: ANSWER_HEAD has to survive in this shell (fact-check Claim 10). The read-back forks and execs cat once. `r="$(<"$GATE_TMP/answer")"` still forks but skips the exec. A `read`/`mapfile` loop forks nothing. Either way this runs once per invocation, so the saving is under a millisecond. Mention only.

**Recommendation:** None needed. If the line is touched for another reason, `$(<file)` is the cheaper idiom.

## Endorsements

- The GATE_CODE test adds ~8.5 µs a path, ~3.5 ms over 401 paths. bash recompiles the ERE on each `=~`, but that cost does not matter at this N. Measured by the probe above. [read: scripts/build-loop.sh:1041]
- Under AUTH=approved, `sm` stays empty, so checkout_gate (the comment puts it at about 0.3 s a brief), read_paths and srules are skipped. The approved path does strictly less per-path work than self-merge. [fact-check: claim 2 — Verified]
- floor's walk_why fork moved into truthwalk instead of being added next to it. On a cached main walk, floor itself still forks nothing but that one subshell. [fact-check: claim 18 — Verified]
- check_answer runs once per approval. The added awk work (`head = substr($0, 5)` on the first matching heading only, plus one extra print) is constant per questions file. [read: scripts/lib/dev-cycle-read.sh:2028, :2057, :2070-2096]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Per-denied-path `$(floor_why)` fork; two forks/path after a failed main walk (~+160 ms worst case at 400 paths, refusals only) | Low | `scripts/build-loop.sh:831`, `scripts/lib/dev-cycle-read.sh:1892` | High |
| 2 | `$(cat)` read-back of the answer file | Informational | `scripts/build-loop.sh:1075` | High |

## Overall Assessment

The diff does not change the performance posture of the gate. Every addition is constant per path or constant per run. Nothing is quadratic, there is no new unbounded collection, and the approval path is cold and cheaper than the self-merge path it parallels. The only measurable regression is F1. Moving floor's sentence into floor_why put one subshell (~0.4 ms) on every floor-denied path, which comes to about +160 ms in the worst 400-path refusal. This is fixable in place by having floor_why write a variable, plus, optionally, memoizing truthwalk's TRUTH_WHERE for a cached failure. It does not threaten the budget. No further profiling is needed. If F1 is fixed, a no-fork test like the existing tr/pwd shim test (build-loop-check.bats:1390-1398), extended to a floor denial and a failed main walk, would keep the fork count fixed.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/performance-review-2026-10-10-u3a3-i1.md, structured per the performance-reviewer skill, with `Commit: a7a4f784` at the top."
- **Answered:** yes. The report covers the three per-path costs named in the focus (GATE_CODE test, srules' floor_why fork, truthwalk's walk_why fork) and the approval path, with measured per-call costs. Probe and output are in the scratch dir only. Nothing in the worktree was written except this report, and nothing was committed.
- **Out of scope:** an end-to-end timing of check_line over 400 real paths. The probe times the added operations on their own, not a full gate run; the fork costs are lower bounds for build-loop.sh's larger shell.
- **Escalate:** nothing. F1 is optional and Low, and does not block merge.
