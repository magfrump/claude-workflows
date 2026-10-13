Commit: b1a6f0a2

# Performance Review — feat/build-loop-u4a, final confirming pass

**Scope:** the whole branch against main at b1a6f0a2: `scripts/build-loop.sh` (the parser, `cycle_diff` :1874, `asked` :1902, `cycle_rules` :1908, `questions_rules` :1987, `land_cycle` :2026, `chore_msg` :1732, `chore_record` :1737, `log_class` :1755 and `land`'s cycle branch), `scripts/lib/dev-cycle-read.sh` (`isrecord` :246, `writable`), and the three U4a tests.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4a-final.md` (31 clusters; its one Incorrect, claim 1, is message wording that d46cd00f fixed, and none of its claims is a performance claim)

Settled and not re-reported: override-log rows 754 (`lower` forks once per changed path) and 755 (two blob reads and two awk runs per changed brief). The i2 report filed no findings.

## Data Flow and Hot Paths

`--cycle-diff` and `--land-cycle` each run once per dev-cycle orchestrator iteration, as separate CLI calls. **Path temperature: cold.** That is one call per iteration, over a chore branch's handful of changed paths: a cycle record, a few briefs, the roadmap, the questions files and the idea log.

- `--land-cycle` runs `state_start`, the same state gate as `--state`, including the full re-hash of main's tree by `store_check --main`. It then runs `land_cycle`, which does these steps in order:
  1. one `symbolic-ref`, one `rev-parse` and one `diff-index --cached`;
  2. one `merge-base --is-ancestor`;
  3. `merge_result`, which runs merge-base, a `cat-file -e` per base and one merge-tree;
  4. `store_check "$h" "$r"`. This lists the trees of HEAD and the merge, re-hashes only the ids not already in main's list, and lists every pack index and loose object again;
  5. one `diff-tree` of MAIN_SHA against R, read by `raw_records`, which forks nothing;
  6. `cycle_rules` over that listing (only the chore's changes, because main is one side of the merge);
  7. `chore_record`, which loops over RAW_* with an in-shell `isrecord` test and runs one `cat-file blob` + awk per cycle record found;
  8. an in-shell loop that fills `CHANGED`;
  9. `land cycle`. This is the existing worktree scan, the state gates again, one `commit-tree`, and then update-ref or `merge --ff-only`.
- `--cycle-diff` moved its questions guard ahead of `cycle_rules`. It scans RAW_P once, breaks at the first questions path, and runs the same two `ls-tree` calls under the same trigger as before.
- `log_class`'s chore path (once per first-parent commit in `--main-log`) now calls `chore_record`. The loop body is the one it replaced, moved into a function. The only change is that `isrecord`'s narrower regex replaces the inline `cycle-[^/]+` one. That is still an in-shell `[[ =~ ]]` test, with no fork.

Measured for this pass on WSL2 (kernel 6.18.54) in a fresh `git clone` of /workspace (3,484 files on main, 22,154 packed objects). The chore branch added one cycle record. The probe dirs were `/tmp/u4a-perff-*`, now removed. Each figure is a small number of runs, so treat them as indicative:

| Run | Result |
|---|---|
| `--state` | 0.376 / 0.381 / 0.385 s |
| `--cycle-diff` (ok) | 0.387 / 0.401 / 0.358 s |
| `--land-cycle --main M` (landed by update-ref) | 0.510 s, about 130 ms more than `--state` |

The components of that 130 ms, timed one git command at a time (two runs each):

| Command | Time |
|---|---|
| `ls-tree -r -t` of one 3,484-file tree (store_check runs two) | 3.8–4.0 ms |
| pack-index listing (`show-index`, 22,154 ids) | 7.5–7.8 ms |
| `merge-tree --write-tree` | 1.3–1.8 ms |
| `merge-base --is-ancestor` | 1.2 ms |
| `diff-index --cached --quiet` | 1.4–1.6 ms |
| `diff-tree -r --raw -z` | 1.4–1.7 ms |
| `worktree list` | 0.8–0.9 ms |

The rest of the 130 ms is `land`'s existing second state gate and default_gate, plus bash startup work that is shared with `--state`.

`--main-log` (exercises log_class, including the chore path):

| Run | Result |
|---|---|
| 1 commit (the landed chore merge, classified `chore`) | 364 / 365 ms |
| 41 first-parent commits | 637 / 631 ms, about 7 ms per commit |

The three U4a tests ran in 2.9 s in total (`bats -f`, run serially).

Data sizes, carried from i2: 140 `### Q-` headings across the two questions files and 3 briefs. `cycle_rules`' associative arrays (`ao`/`an`/`ap`/`aop`/`used`) are bounded by the changed briefs and added IDs. They are locals, freed when the function returns.

## Findings

No findings.

Every piece of new work is Micro × Cold, which defaults to Informational, and each one is measured above at a few milliseconds on a run of roughly 0.4–0.5 s that happens once per iteration. The branch adds no new loop over history and no per-commit fork to `--main-log` (`chore_record` is the old loop body, moved). It adds no work that grows with repository size beyond the existing `store_check` design, which `--merge`'s `check_line` already runs per brief, and it caches nothing. One iteration of the orchestrator runs `state_start` twice: once in `--cycle-diff` and once in `--land-cycle`, about 0.38 s each at today's size. That repeat comes from the compare-and-swap design. `--land-cycle` has to re-gate the state it lands from in its own process. I am not filing it, because the second gate is the safety property, not waste. Legibility-target if a reviewer wants it filed: `land_cycle`'s `state_start` call in the mode dispatch. Baseline: `--state` at 0.38 s, measured above.

## Endorsements

- `land_cycle` judges only the chore's own changes. Its `diff-tree` compares MAIN_SHA with the merge R, of which main is one side, so `cycle_rules`' per-path `lower`/`truthrule` work grows with the chore's diff, not with how far main has moved. [read: scripts/build-loop.sh:2026-2058, merge_result :1102-1113]
- `chore_record`'s path test is fork-free (`isrecord` is a bash `[[ =~ ]]`). It forks a `cat-file` + awk only for a cycle-record path with mode 100644 and status A/M, and it returns at the first match. [read: scripts/build-loop.sh:1737-1745, scripts/lib/dev-cycle-read.sh:246]
- `land_cycle`'s `store_check "$h" "$r"` re-hashes only the objects of HEAD and the merge that are not in main's already-hashed list (`$GATE_TMP/main`). On a one-record chore, that means a handful of new trees and blobs, not the 3,484-file tree. [read: scripts/build-loop.sh:1063-1094]
- The 130 ms that `--land-cycle` adds over `--state` on a 3,484-file repository is dominated by `land`'s existing re-gates, not by U4a's new code. [unverified — submitted as claim] (Measured only as a total plus per-command timings. xtrace is lost across `scrub_reexec`, so no per-function trace was taken.)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The branch keeps the cycle gate's cost profile. `--land-cycle` costs about 0.51 s on a clone of this repository, about 130 ms more than the state gate it starts with. `--cycle-diff` stays at about 0.36–0.40 s. `--main-log`'s chore classification is the same loop moved into `chore_record`, at about 7 ms per commit. All of the new work is on a cold path that runs once per iteration, with small N. The two scale triggers that exist (row 755's ~50 changed briefs, and a cycle that appends tens of Asked: items) are unrealistic for step 6's append-one-ID flow. Nothing here needs profiling before landing.

## Goal-Alignment Note

Success criterion: a markdown report saved at the exact path your own prompt names, structured per your skill.

This report is saved at `/workspace/.claude/wt-build-loop-u4a/docs/reviews/performance-review-2026-10-13-u4a-final.md`, and its first line is `Commit: b1a6f0a2`. It follows the performance-reviewer structure: title and header, data flow with the measured baselines, findings ("No findings."), evidence-tagged endorsements, the summary table and the overall assessment. The settled rows 754 and 755 are not re-reported.
