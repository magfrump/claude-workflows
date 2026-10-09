Commit: f56ba3f5

# Performance Review — feat/build-loop-u2b3b1 (U2b3b1, final confirming pass)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-build-loop-u2b3b1 (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md, tests); delta since iteration 1 is `git diff 8ed86432 f56ba3f5 -- scripts/`
**Date:** 2026-10-09
**Based on:** Stage 1 merged fact-check (k=3, docs/reviews/code-fact-check-report-build-loop-u2b3b1-final-r{1,2,3}.md, as summarized in the critic tail); iteration 1 report docs/reviews/performance-review-2026-10-09-u2b3b1.md (F1 cap and F3 are settled override rows)

## Data Flow and Hot Paths

Unchanged in shape since iteration 1. `reader_settings` (scripts/lib/dev-cycle-read.sh:593-640) runs once per process in build-loop.sh (:307) and dev-cycle.sh (:194): one `main_by_name`, one `main_file` (git cat-file + SETTINGS_AWK), and a linear pass over the parsed keys. Since 1ece139d the no-main branch (:596-599) sets IMPORT_READER_WHY and returns before `main_file`, so the refusing case is cheaper than the reading case. `import_readers` (:1010-1058) runs once per decision (memoized, a refusal included) and builds roots of about (1 + C) × W; both walks (`imported_names` :1177, `main_imports` :1226) call it first and return on its failure, so refused settings fail a walk before any registry listing, tree listing or file read. The new guard in `import_targets` (:1065) is a belt for a direct call outside a walk: two string tests after `import_home`, which already ran. Path temperature: cold (gate/CLI decisions, a few per invocation; the floor walk is not wired into build-loop.sh until U2c).

Measurements (probes in /tmp/claude-1000/-workspace/f2c3719b-892d-4844-84dc-9c1b5883d0c4/scratchpad/u2b3b1-final/perf-final/, p1 and p3, re-runs of iteration 1's probes against the lib at f56ba3f5, 2026-10-09, shared host, wall clock; synthetic `/home/magfrump/aliasN` caller roots with `IMPORT_READER_HOMES=/home/magfrump`):

| Run from | Caller roots | Roots | Names | Work per walk | main s | tree s |
|---|---|---|---|---|---|---|
| /workspace | 0 | 25 | 128 | 347,710 | 1.39 | 1.61 |
| /workspace | 1 | 49 | 128 | 868,530 | 1.52 | 1.71 |
| u2b3b1 worktree | 0 | 25 | 64 | 153,855 | 0.82 | 0.89 |
| u2b3b1 worktree | 1 | 49 | 64 | 395,065 | 0.92 | 0.83 |
| u2b3b1 worktree | 4 | 121 | 64 | 1,567,975 | 1.00 | 0.98 |

Work figures are identical to iteration 1's at the same root counts: the fix commit did not change the parser's charged work. `reader_settings`: 4.0-4.3 ms per call. Refused settings (IMPORT_READER_WHY set, from /workspace): the first main + tree pair fails in 2.4 ms, each later pair in 1.2 ms (memo hit).

## Findings

#### F1. The bound comment's "1.5 s per walk" at 49 roots is low for the tree walk

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:745-746`
**Move:** Build on stale claims (consumes the Stage 1 "Mostly accurate" verdict on lib:746)
**Classification:** Micro (documentation of a measured cost) / Cold path (once-per-decision walk)
**Confidence:** High (measured)
**Baseline:** tree walk 1.71 s at 49 roots over /workspace, probe p3, 2026-10-09 (main walk 1.52 s)
**Evidence:**
```
# Roots are about (1 + C) times the worktrees for C host aliases (G8): with
# one, near 285 worktrees (49 roots here: 1.5 s per walk; U2b3b1 i1 performance F1).
```

The main walk measures 1.52 s at 49 roots, which the comment matches; the tree walk measures 1.71 s here and about 1.7 s in the Stage 1 fact-check, at 25 and 49 roots alike, so the alias adds no measurable tree-walk time and the "1.5 s" understates it by about 0.2 s. The sibling work figure on :740 ("870,000 over 49") matches this probe's 868,530 (the fact-check's 899,730 differs by 3.5%, which reads as a registry or home-list difference, not a parser change). Neither number feeds a threshold; the headroom statement ("near 570 roots", "near 285 worktrees") still holds against the measured curve.

**Recommendation:** Optional, no new lines: "1.5-1.7 s per walk". Not worth a fix iteration on its own.

**Legibility-target:** for-author-fix

No other findings. The fix commit 1ece139d adds no work on any walking path: the no-main refusal returns earlier than before, the new `import_targets` guard is two string tests, and the refusal fails both walks in about 1 ms per pair once memoized. Iteration 1's F1 (no cap on aliases) and F3 (docs/dev-cycle.md parsed twice; reader_settings in every dev-cycle.sh mode) are settled override rows and not re-filed; iteration 1's F2 (stale work figure) is fixed at :740.

## Endorsements

- Refused settings fail both walks before any registry, tree or file read: `imported_names` and `main_imports` call `import_readers` first and return on its failure, and `import_readers` returns 1 under IMPORT_READER_WHY before `nul_list ... git worktree list` [read: scripts/lib/dev-cycle-read.sh:1010-1021, 1177-1181, 1226-1231]; measured 2.4 ms for the first refused main + tree pair and 1.2 ms per later pair (probe p1) [unverified — submitted as claim] route: code-fact-check
- The fix commit leaves the parser's charged work unchanged: work per walk at 25/49/121 roots is byte-identical to iteration 1's probes (347,710 and 868,530 over /workspace; 153,855, 395,065 and 1,567,975 over the worktree) [unverified — submitted as claim] route: code-fact-check
- The no-main branch of reader_settings returns before `main_file`, so the fail-closed case runs no git cat-file or awk [read: scripts/lib/dev-cycle-read.sh:593-599]
- import_readers memoizes a refusal (not an import_home failure) keyed on IMPORT_READER_WHY, so a refusing decision lists the registry at most once [fact-check: Stage 1 "memo of a refusal (not of an import_home failure)" — Verified by execution]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | "1.5 s per walk" at 49 roots understates the tree walk (about 1.7 s) | Informational | `scripts/lib/dev-cycle-read.sh:745-746` | High |

## Overall Assessment

The performance posture is unchanged from iteration 1 and sound for the current registry. The fix commit moved no work onto a walking path: refused settings now fail fast (milliseconds, memoized), and the parser's charged work is identical at every root count probed. With the one host alias main's docs/dev-cycle.md names, the /workspace walks spend about 1.7% of IMPORT_WORK_MAX (868,530 of 50,000,000) and take 1.5-1.7 s, dominated by fixed costs. The headroom question (roots about (1 + C) × W, no alias cap) is a settled override row with revisit triggers. The single finding is an Informational comment figure. No profiling beyond the probes above is needed.

## Goal-Alignment Note

The goal is to land U2b3b1 after a clean review-fix loop. From the performance side nothing blocks landing: no red, no amber, one Informational comment figure (F1) that need not reopen the loop, and fixing it adds no lines to the 397-line unit. Nothing here touches U2b3b2's deferred items (H5, H2, C1, G9, outside starts); the architecture i1 F5 note that U2b3b2's per-root seeds will multiply with the re-spelled root set remains the place to re-measure work when those land.
