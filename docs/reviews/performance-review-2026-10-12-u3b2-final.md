Commit: 4afdd68b

# Performance Review: feat/build-loop-u3b2 (`--main-log SINCE`), final confirming pass

**Scope:** full branch `main...4afdd68b` (`scripts/build-loop.sh` header, gate_msg, ANSWERS_AWK, clean_merge, log_class, main_log; tests; plan note; override rows dated 2026-10-12 for this branch)
**Date:** 2026-10-12
**Based on:** Stage-1 merged summary (`code-fact-check-report-2026-10-12-u3b2-final-r{1,2,3}.md`, k=3, no behavioural Incorrect); my prior reports `performance-review-2026-10-12-u3b2-i1.md` and `-i2.md`; rubric `code-review-rubric-2026-10-12-feat-build-loop-u3b2.md` (D1-D13, E1-E8)

## Data Flow and Hot Paths

`--main-log` runs once per orchestrator iteration (warm, not hot). It runs state_start (main's tip re-hash, shared with --state: i1 Finding 2, row D13), lists main's whole first-parent history once (`:1693`), cuts it at SINCE, and calls log_class per commit above SINCE (`:1700-1701`). Per commit, log_class forks about 4-6 processes (cat-file, awk, perl, then by class: diff-tree, awk, cat-file blob). Since 4afdd68b (rubric E4), merge-tree runs only inside the gate and chore subject branches (`:1659`, `:1667`). Other merges cost no merge-tree run. N per iteration is normally under 20.

**Measurements** (this review's probes, cwd under `/tmp/u3b2rv-perff-*`, all removed; `GIT_CONFIG_GLOBAL=/dev/null`, `LC_ALL=C`; wall time from bash `$EPOCHREALTIME`; WSL2; fixture `git clone -q --no-local --single-branch --branch main /workspace`: 1,119 first-parent commits, 422 merges, 0 loose objects after clone):

| Script | SINCE | Runs (wall) | Loose objects after |
|---|---|---|---|
| 4afdd68b (HEAD) | root | 6.72, 7.05, 7.05, 6.99, 6.79 s | 0 |
| 1d829fee (pre-D1) | root | 6.90, 6.98 s | 0 |
| cca66dc2 (i2) | root | 8.42, 8.82 s | 87 |
| 4afdd68b | tip (N=0) | 0.35, 0.33, 0.34 s | 0 |
| 4afdd68b | 10 back (N=10) | 0.43, 0.42, 0.39 s | 0 |

HEAD's stdout was byte-identical to 1d829fee's and to cca66dc2's on the root run (`cmp` exit 0): 1 answers, 1,117 other, exit 2. The two suite tests filtered by `main-log` pass at HEAD (`ok 1`, `ok 2`).

## Findings

#### 1. Row 728's revisit trigger "a --main-log run over 5 s" already fires on an ordinary root-SINCE run, so it cannot isolate the rename case it was written for

**Severity:** Informational
**Location:** `docs/reviews/override-log.md:728`
**Move:** What's the size of N? (the trigger's threshold against the measured per-commit cost)
**Classification:** Micro (a threshold in a ruling, no code cost) / Cold path (once per iteration)
**Confidence:** High
**Baseline:** 6.72-7.05 s for HEAD over a root SINCE on a /workspace main clone (5 runs, this review's probe 2026-10-12), 0 rename-heavy merges in that history
**Legibility-target:** U4 implementer (who reads row 728's trigger) and whoever maintains the override log

Evidence (`docs/reviews/override-log.md:728`): `Revisit trigger: a --main-log run over 5 s, or store_check refusing a second copy after a --main-log run.`

Row 728 records the large-rename merge-tree cost (~5 s for one constructed merge). Its trigger is total run time. But total run time is dominated by the per-commit fork cost (i1 Finding 1, row 727: "~7-10 s for a SINCE at this repo's root"). This review measured about 7 s for a root SINCE with no rename-heavy merge in it. So the trigger fires on the ordinary far-back-SINCE case row 727 already defers, and a run over 5 s says nothing about merge-tree. The stage-1 summary also found the row's "87 objects, 616 KiB" stale: this review reproduced 87 loose objects for cca66dc2 and 0 for HEAD on the same clone (not re-filed; noted as corroboration).

**Recommendation:** When row 728 is next touched for its stale figure, key the trigger to the merge-tree step itself (for example "one gate or chore merge's merge-tree over 1 s"), or to a run over 5 s with SINCE within one cycle. No code change.

## Endorsements

- **E4's reordering removed the i2 regression and all store writes on this repo's history.** HEAD's root-SINCE time is 6.72-7.05 s against 6.90-6.98 s pre-D1 and 8.42-8.82 s at cca66dc2, with 0 loose objects written against cca66dc2's 87, and identical output. `[unverified — submitted as claim]` (this review's measurement, few runs, not an execution verdict of the fact-check)
- **clean_merge runs only after a gate or chore subject matches.** It is called at `:1659` and `:1667`, each inside a branch whose condition is the subject regex and two parents, and nowhere else in log_class. `[read: scripts/build-loop.sh:1644-1648, 1649-1686]`
- **A typical iteration window costs under half a second.** N=10 took 0.39-0.43 s and N=0 0.33-0.35 s on the /workspace clone, so per-iteration cost is mostly state_start. `[unverified — submitted as claim]`
- **log_class reads at most five message lines into the array.** `mapfile -t -n 5 m` bounds the per-commit array; the full message is only streamed to a file for `cmp`. `[read: scripts/build-loop.sh:1656]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Row 728's "--main-log run over 5 s" trigger fires on an ordinary root SINCE (~7 s, no rename merge), so it cannot isolate the merge-tree case | Informational | `docs/reviews/override-log.md:728` | High |

## Overall Assessment

The full branch is performance-sound for its use: a handful of commits per iteration at about 0.4 s, linear at about 6 ms per commit for a far-back SINCE (ruled, row 727). The iteration-2 regression is gone: E4 put merge-tree behind the subject test, and the measured root-SINCE time is back to pre-D1 levels with no objects written into the store on this repo's history. Prior findings (i1 1-2, i2 1-3) are ruled by D13, E4, E5 and rows 727-728, and I found no reason to reopen any. The one new item is a mis-calibrated revisit trigger in row 728, a text fix. No finding blocks landing. Numbers are single-machine, few-run measurements without a variance study.

## Goal-Alignment Note

Success criterion: "A performance review saved to docs/reviews/performance-review-2026-10-12-u3b2-final.md in the worktree, per the performance-reviewer skill." This report is saved at that path, first line `Commit: 4afdd68b`. It follows the skill: baseline and classification × path on the finding, a Legibility-target, verbatim evidence, tagged endorsements (two submitted as claims), summary table and assessment. Probes used the `/tmp/u3b2rv-perff-` prefix; the clone and its temp dir were removed by the probe, and no process I started is still running. A planned bats timing run was not executed (its cleanup command was refused), so the suite was run once untimed.
