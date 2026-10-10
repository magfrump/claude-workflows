# Performance Review — feat/build-loop-u3a2 (iteration 2, fix batch)

**Scope:** `git diff 7d78e6d0..f782d9ee -- scripts test` (the iteration-1 fix batch: `scripts/build-loop.sh`, `test/scripts/build-loop-merge.bats`); the rest of the branch is context only
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-u3a2-i2.md` (claims 11, 12, 15a, 15b, 18, 19), `docs/reviews/performance-review-2026-10-10-u3a2-i1.md`

## Data Flow and Hot Paths

The mode is the same as in iteration 1. `--merge BRIEF --expect SHA` lands one brief per process, a few times a day, so the whole thing is a **cold path**. The cost is still dominated by the single `store_check --main` pass in `gate_start`, measured at 0.24 s in iteration 1. Read in full: `check_line` (`scripts/build-loop.sh:932-1003`), `merge_ident` (`:1011-1018`), `land` (`:1038-1100`) and the merge arm (`:1122-1134`). The fix batch changes these costs:

- **CHANGED fill** has moved out of the diff-tree read loop and into `verdict_ok` (`:987-991`). It is now a second builtin pass over `ps` that runs only on an ok verdict. Refused briefs skip it, but they paid for it before the fix.
- **Rebase/bisect scan** (`:1053-1060`): `[[ -f ]]` guards plus `$(<file)` replace three `$(cat …)` forks per git dir. Two more globs pick up dot-named admin dirs. That adds two readdirs of `worktrees/`.
- **One extra `git rev-parse --show-toplevel` fork**, plus two `stat`s for `-ef`, run in the W branch (`:1062`).
- **`-c maintenance.auto=false`** is now on the ff-merge in W (`:1096`), along with `branch.$MAIN.mergeOptions=` and `GIT_REFLOG_ACTION`.
- **Reordering:** the policy refusal moved into the merge arm before `land`. `commit-tree` moved after the W checks (`:1083-1086`), so a refusal in the decide phase now writes no object.

Measured on /workspace (8 git dirs, git 2.39.5, bash 5.2.15). Probes ran under `/tmp/u3a2i2-perf-*`, scripts are in `scratchpad/u3a2-i2-performance/`, and load average was about 1.5. Today's fork costs are roughly 10x iteration 1's (a `$(cat f)` costs about 6 ms versus 0.6 ms), so compare the ratios rather than the absolute numbers:

| Step | Before (7d78e6d0 code) | After (f782d9ee) |
|---|---|---|
| Rebase/bisect scan, 8 git dirs, 10 runs each, two sessions | 186–230 ms | 1.3–2.2 ms |
| `rev-parse --show-toplevel` + `-ef` | — | 9–16 ms (one git exec; same class as the other ~10 git forks in `land`) |
| `$(<f)` vs `$(cat f)`, a file that exists | 5.9–7.0 ms | 0.16–0.19 ms |
| CHANGED fill, 27 paths (a real merge) | (inside the loop) | 0.18 ms |
| CHANGED fill, 5,000 synthetic paths at depth 5 | (inside the loop) | 12.6 ms |

The net change in `land`'s fork count is −24 `cat` forks and +1 git fork. On every measurement the batch is cheaper than the code it replaces.

**Maintenance probe** (`maint.sh`): a temp repo with repo-local `maintenance.auto=true`, `maintenance.loose-objects.enabled=true`, `maintenance.loose-objects.auto=1`, `gc.auto=1` and 120 loose commits.
- With the fix's flags, `git -c gc.auto=0 -c maintenance.auto=false -c branch.main.mergeOptions= merge --ff-only` traced no `maintenance`, `gc`, `prune-packed` or `pack-objects` run, and the pack count stayed at 0. The command-line `-c` overrides the repo-local `maintenance.auto=true`.
- The same ff with `gc.auto=0` alone traced `git maintenance run --auto --quiet`, `git prune-packed` and `git pack-objects … pack/loose`, and wrote one pack.
- The other git calls in the run that I probed under `GIT_TRACE=1` traced no maintenance run, even with that config: `merge-tree --write-tree`, `diff-tree`, `status`, `worktree list` and `commit-tree`. This covers the gap that fact-check claim 19's scope left open ("other git calls in the run"), apart from `update-ref`, `cat-file` and `rev-parse`, which I did not trace.

## Findings

#### 1. The maintenance.auto=false fix has no regression guard (mutant M7 survives)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1093-1097`; `test/scripts/build-loop-merge.bats:99-106`
**Move:** Find the work that moved to the wrong place (guarding the i1 F1 fix)
**Classification:** Macro (the cost of a foreground repack scales with the object store) / Cold path (once per landing)
**Confidence:** High (fact-check claim 19 ran mutant M7; my probe reproduced the unguarded behaviour)
**Baseline:** no baseline available — flagged as speculative (the probe showed the repack runs without the flag, but I did not time a repack of /workspace's store)
**Legibility-target:** for-author

**Evidence:**
```
    GIT_REFLOG_ACTION="$msg" git -C "$w" -c gc.auto=0 -c maintenance.auto=false -c "branch.$MAIN.mergeOptions=" merge --ff-only -q "$NEW" > "$GATE_TMP/ff" 2>&1 \
      || { MERGE_WHY="the fast-forward in $in failed"; return 1; }
```

The flag does what iteration-1 F1 asked for: it stops the foreground `maintenance run --auto` outright, even against repo-local config that turns maintenance on. No test observes it, though. Fact-check claim 19 says mutant M7 (the flag removed) "survives the suite". If a later edit drops the flag, unbounded foreground work after the branch moves would silently come back, along with the store rewrite after `store_check`, which is the security side of F1. /workspace sets no `maintenance.*` key today, so nothing costs anything now.

**Recommendation:** Optional. In the W test, set `maintenance.loose-objects.enabled=true` and `maintenance.loose-objects.auto=1` (and `maintenance.auto=true`) in the fixture repo's config, then assert that the pack count under `.git/objects/pack` is unchanged after `--merge`. In the probe, that assertion fails without the flag and passes with it.

## Endorsements

- The rebase/bisect scan forks nothing for an absent file: `||` short-circuits inside `[[ ]]`, so `$(<…)` is never expanded when `! -f` holds. iteration-1 F2 is resolved: the scan went from about 186 ms to about 1.3 ms here [fact-check: claim 18 — Verified (executed)].
- `-c maintenance.auto=false` stops `run_auto_maintenance` for the ff-merge in W, so iteration-1 F1 is resolved for that call [fact-check: claim 19 — Verified (executed)].
- `verdict_ok` fills CHANGED only on an ok verdict. Refused briefs (and `--check`'s refused briefs) no longer pay the per-path assignment the old diff loop made. The fill is one builtin pass, 0.18 ms for 27 paths [fact-check: claim 11 — Verified (static)].
- Writing the merge commit after the W checks means a refusal in the decide phase leaves no unreachable commit in the store. The only orphan comes from a refusal after the write (the state gate re-run or the move), which is one small commit object per such refusal [fact-check: claim 15a — Verified (static)].
- `rev-parse --show-toplevel` adds one git exec per landing in the W case and nothing in the update-ref case. It runs once and is not inside any loop [read: scripts/build-loop.sh:1061-1064].

## Iteration-1 Must Address spot-check (performance angle)

- **A1 (mergeOptions):** `-c branch.$MAIN.mergeOptions=` is a config override on a merge that already runs, so it costs nothing extra. Claims 19 and 22 cover the behaviour.
- **A2 (identity):** `-c user.useConfigOnly=true` is on the two `git var` forks that already run. There is no new fork.
- **A3 (header):** documentation only, no runtime cost.
- **Regressions:** no new loop, no new per-path fork, and no second `store_check`. Row 639's "second full pass" trigger is still not met inside a process, and `--merge` still calls `gate_start` once (`:1124`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The maintenance.auto=false fix has no regression guard (M7 survives) | Informational | `scripts/build-loop.sh:1093-1097` | High |

## Overall Assessment

The fix batch makes things faster. It removes 24 forks per landing at today's worktree count and adds 1. The CHANGED fill now costs nothing on refused briefs, and the merge commit is no longer written on decide-phase refusals. Iteration-1 F1 (unbounded foreground maintenance) is fixed. The probe confirmed that `-c maintenance.auto=false` beats a repo-local `maintenance.auto=true`, and none of the run's other traced git calls start maintenance. Iteration-1 F2 (the `cat` forks) is fixed too. The only remaining item is informational: a test should pin the maintenance flag so that dropping it cannot regress silently. No profiling is needed. `store_check --main` still dominates the wall time.

## Goal-Alignment Note
- Success criterion (restated verbatim): "A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/performance-review-2026-10-10-u3a2-i2.md, structured per the performance-reviewer skill."
- Answered: the cost of verdict_ok's CHANGED fill (measured, endorsed), the rebase scan without `cat` (measured, about 140x cheaper), the extra `rev-parse --show-toplevel` (one exec, measured), and `maintenance.auto=false` (probed: it prevents the repack F1 found and overrides repo-local config). A1–A3 were checked for performance regressions, and there are none.
- Out of scope: the correctness of the A1–A3 behaviour (covered by fact-check claims 4b, 5, 19 and 22), and the security side of maintenance.
- Escalate: none. Finding 1 (test guard for M7) goes to the test author if the loop wants it.
