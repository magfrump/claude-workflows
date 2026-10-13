Commit: 4e14d1cc

# Performance Review — feat/build-loop-u4a, review-fix loop iteration 2

**Scope:** Partial scope: the fix range 722c2e10..4e14d1cc (70d24331, c0cafb66, 4e14d1cc) in `scripts/build-loop.sh` (cycle_diff, cycle_rules, asked_rule, land_cycle, chore_msg, the parser) and `test/scripts/build-loop-orchestrator.bats`. 722c2e10 is context only, not under review.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4a-i2.md` (26 claims; 4b Incorrect is a correctness gap, not a performance claim)

Settled and not re-reported (override-log rows 754 and 755): `lower` forked once per changed path, and two blob reads plus two awk runs per changed brief.

## Data Flow and Hot Paths

`--cycle-diff` and `--land-cycle` each run once per dev-cycle orchestrator iteration. Both call `cycle_rules BASE SIDE` once over the changed paths of a chore branch (a handful of paths: a cycle record, a few briefs, the roadmap, the questions files, the idea log). The path is **cold**: one CLI call per iteration, with small N. The fix range adds three kinds of work there:

1. `truthrule "$lp"` per changed path, after the existing `lower` fork (`scripts/build-loop.sh` cycle_rules loop). truthrule (`scripts/lib/dev-cycle-read.sh:1912-1922`) and its callees `isstart` (`:712`), `writable` (`:247-249`), `isrecord` (`:246`) and `anybrief` (`:242`) are all bash `[[ ]]` tests with no fork.
2. `asked_rule`: one `grep -qxF` fork per item added to a brief's Asked: line, against `$t.new`.
3. One `awk` over `$t.qo`/`$t.qn` (the QKEYS lines of both questions files on both sides) that computes NEW. It runs only when a questions file changed. Otherwise `: > "$t.new"` is used with no fork.

The questions guard moved from cycle_rules into cycle_diff. It scans `RAW_P` once with `break` after the first questions path, and it runs the same two `ls-tree` calls the old guard ran under the same trigger (fact-check claim 11). So it is cost-neutral for `--cycle-diff`. For `--land-cycle` it removes two `ls-tree` forks and a `cmp`.

Measured here (WSL2 kernel 6.18.54, bash, probe dir `/tmp/u4a-perf2-*`; one run each, so these are indicative):
- truthrule: 2,000 calls in 0.156 s, about 78 µs per call (in-shell, no fork).
- `grep -qxF` against a 50-line file: 1,000 forks in 0.852 s, about 0.85 ms per added item.
- The NEW awk: 50 runs in 0.052 s at 100 headings per side (about 1.0 ms per run), and 50 runs in 0.089 s at 2,000 headings per side (about 1.8 ms per run).
- Data sizes in this repo: 17 + 123 = 140 `### Q-` headings across the two questions files, and 3 briefs.

## Findings

No findings.

Each of the three additions is Micro × Cold. Per iteration they cost about 78 µs × (changed paths) + 0.85 ms × (added Asked: items) + about 1 ms (the NEW awk at today's 140 headings). That is a few milliseconds on a run the i1 override row puts at about 350 ms. The NEW awk is linear in the headings (one hash set over BASE, one pass over the listing). At 2,000 headings it measured about 1.8 ms, so it has no cliff at realistic sizes. asked_rule's per-item grep would only be worth batching (by loading `$t.new` into an associative array once) if a cycle appended tens of IDs. Step 6 appends one at a time, so no finding is filed. If a reviewer wants it filed, the Legibility-target is the `asked_rule` loop body, with the baseline of 0.85 ms per item above.

## Endorsements

- truthrule adds no fork per path. It and every callee on its path (`isstart`, `writable`, `isrecord`, `anybrief`) are bash `[[ =~ ]]`/glob tests. [read: scripts/lib/dev-cycle-read.sh:242-249, :712, :1912-1922]
- The NEW computation is one linear awk pass over the QKEYS lines already collected for QDIFF_AWK. It reuses `$t.qo`/`$t.qn` and does not read the blobs again. [read: scripts/build-loop.sh cycle_rules, the QKEYS loop through the NEW awk]
- When no questions file changed, cycle_rules runs asked_rule against an empty `$t.new` made by `:` with no fork, so the common path gains no awk. [read: scripts/build-loop.sh cycle_rules, `: > "$t.new"` and the `${#qi[@]} -eq 0` line]
- Moving the questions guard into cycle_diff keeps the same trigger and the same two `ls-tree` calls for `--cycle-diff`, and drops them from `--land-cycle`, where they were vacuous. [fact-check: claim 11 — Mostly accurate (the behaviour difference is the suppressed co-refusals, not cost)]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The fix range keeps the cycle gate's cost posture. All of its new work sits on a cold, once-per-iteration CLI path with small N (a handful of paths, one to a few added Asked: items, and 140 question headings today). Two of the three additions add no fork or one fork, and the NEW awk is linear and measured at about 1 to 2 ms. Nothing here needs profiling before landing. The only scale trigger is the one row 755 already names (a cycle that changes more than about 50 briefs), plus, by extension, a cycle that appends tens of Asked: items. Neither is realistic for step 6's append-one-ID flow.

## Goal-Alignment Note

Success criterion: a markdown report saved at the exact path your own prompt names, structured per your skill.

This report is saved at `/workspace/.claude/wt-build-loop-u4a/docs/reviews/performance-review-2026-10-13-u4a-i2.md`, and its first line is `Commit: 4e14d1cc`. It follows the performance-reviewer structure: title, header, data flow, findings ("No findings." with the costs measured), evidence-tagged endorsements, summary table and overall assessment. Its scope is the partial range 722c2e10..4e14d1cc. The settled i1 rows (754 and 755) are not re-reported.
