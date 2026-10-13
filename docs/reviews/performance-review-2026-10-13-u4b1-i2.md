Commit: 0cd86cc0

# Performance Review — feat/build-loop-u4b1, iteration 2

**Scope:** `git diff main...HEAD` (HEAD 0cd86cc0): `skills/dev-cycle/SKILL.md`, `workflows/pr-prep.md`, `test/scripts/build-loop-orchestrator.bats`, `docs/working/plan-build-loop-handoff.md`
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b1-i1.md`, `docs/reviews/code-fact-check-report-2026-10-13-u4b1-i2.md`

## Data Flow and Hot Paths

The diff is skill text an orchestrator session runs once per `/loop` iteration. The hot unit is therefore one iteration, not one request. Per iteration the new frame adds the following. Steps 0.1-0.4: four D6-wrapped script calls (`--state`, `--main-log`, the digest, and later `--settings`). Then one `--check-path` per repo-text path in steps 2-6, `--check-fix` twice per fixed path, and a second `--state` before commits. It also adds one new worktree, plus a health check that runs in the background behind `health-check.lock`. Measurements come from throwaway clones of /workspace at 0cd86cc0 (main's first-parent chain: 1132 commits), run on this host (16 cores, WSL2) by `scratchpad/u4b1-i2/perf-probe1.sh` and `perf-probe2.sh`, outputs beside them.

| Operation | Measured |
|---|---|
| D6 snippet, `build-loop.sh --settings` (walks and hashes all 1132 first-parent commits) | 0.12 s (direct, no snippet: 0.04 s) |
| `--state` through the snippet | 0.44 s |
| `--main-log` bootstrap (40 zeros; refuses) | 0.47 s |
| `--main-log` with SINCE = main~200 | 2.51 s, 201 lines |
| digest (`dev-cycle.sh`) through the snippet | 0.67 s |
| `worktree add` of the iteration's WT | 0.42 s, 79 MB checkout |
| `dev-cycle.sh --check-fix` (3 paths, import walk), 1 extra worktree registered | 5.00 s |
| same, 30 worktrees registered | 8.70 s (+0.13 s per worktree) |
| `--check-path` (glob + 1 path), 1 vs 30 worktrees | 0.14 s / 0.13 s |

## Findings

#### F1. The per-iteration worktree is never removed, so worktrees pile up without bound, adding disk use and slowing every import walk

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:227-228` (step 0.3), `:268-269` (step 1's prune)
**Move:** Trace the memory lifecycle / what's the size of N
**Classification:** Macro (unbounded growth of a registry every reader walks) / Hot path (once per loop iteration, unattended)
**Confidence:** Medium (U4b2 could add a removal; its plan entry at `docs/working/plan-build-loop-handoff.md:343` lists none)
**Legibility-target:** the step that ends an iteration (U4b2's step 9), or a step 1 bullet
**Baseline:** `--check-fix` 5.00 s with 1 extra worktree and 8.70 s with 30 (`perf-probe2.out`, 2026-10-13); 79 MB per full checkout, 2.4 GB for 30.

Evidence: step 0.3 creates the worktree:
> `hg -C MAIN_WT worktree add -b chore/dev-cycle-DATE-HHMM WT MAIN`, with WT at `.claude/wt-dev-cycle-DATE-HHMM` in MAIN_WT

The only cleanup in the diff is step 1's:
> `hg -C MAIN_WT worktree list` and `hg -C MAIN_WT worktree prune`

`prune` only drops entries whose directory is gone, and WT's directory stays. Nothing in SKILL.md, or in U4b2's planned step list, runs `worktree remove` on it. The reader model counts every registered worktree. `scripts/lib/dev-cycle-read.sh:1145`: "IMPORT_ROOTS holds ROOT_REAL, every path git worktree list registers for this repository", and IMPORT_OTHER feeds `root_copies`/`outside_seeds`, which read each one. IMPORT_DOTNEST is built over all root pairs, O(R²). The measured cost is about 0.13 s per registered worktree on each import-walking call, and 79 MB of disk per worktree. A `/loop` at 30-minute intervals adds 48 worktrees a day: about 3.8 GB of disk, plus about 6 s more on every `--check-fix` and every other walk by the end of the first day. That includes the build loops' own gate decisions, since the registry lives in the shared common dir. It grows linearly from there. Branches `chore/dev-cycle-*` pile up in the same way. Step 1 routes them to a `you: terminal` deletion entry, which makes the user do the cleanup.

**Recommendation:** Name the iteration's end in the skill (U4b2's step 9): `hg -C MAIN_WT worktree remove WT` after the land or the stop record, and have step 1 list leftover `wt-dev-cycle-*` worktrees from crashed iterations as findings. Until U4b2 lands, one sentence in step 0.3 saying the WT is removed at the iteration's end keeps U4b2 from missing it.

#### F2. A health-check waiter abandoned after the hour-long lock wait still takes the lock later and runs the full suite, delaying build loops' gates

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:253-259` (step 1, first bullet)
**Move:** Find the contention point / resource lifecycle
**Classification:** Macro (an orphaned lock holder) / Cold-ish (fires only when a wait exceeds an hour)
**Confidence:** Medium
**Legibility-target:** step 1, the lock-wait sentence
**Baseline:** no baseline available — flagged as speculative (the brief puts the health check at over 10 minutes; not re-measured here)

Evidence:
> It takes a lock in the git common directory, so it waits while a loop's gate runs (it says so once); a wait past an hour is recorded and the step's check is skipped (row 750).

`take_lock` waits with no timeout (`scripts/health-check.sh:1116`, `flock -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@"`). The fact-check (i1) confirms that the script does not enforce the hour bound. The skill says to skip the check but not to stop the background run. So the waiter can still acquire the lock later and run the full fast+slow suite for over 10 minutes. It would then hold the common-dir lock that the build loops' gates wait on, and compete for CPU with steps 2-4b's subagents, all for a result the iteration has already discarded. The next iteration's own health check then queues behind it too.

**Recommendation:** Add "and stop that run by its PID" to the skip (D14 already says to stop only this session's processes, and only by PID), or run it under `timeout 3600` for the lock phase so that the bound sits in the command, not in the orchestrator's memory.

## Endorsements

- The D6 snippet's per-call overhead stays small: it walks and SHA-1-checks main's whole first-parent chain each call, yet measured 0.12 s against 0.04 s direct at 1132 commits. About 10-30 calls per iteration then cost a few seconds, and the cost grows linearly with history at about 70 µs per commit `[unverified — submitted as claim]` (measured in `perf-probe1.out`; per-commit rate inferred from one history length).
- `--main-log`'s cost scales with the SINCE window, about 12 ms per commit (2.51 s for 200). The bootstrap path refuses in 0.47 s, so while U4b2 is pending and every iteration bootstraps (fact-check i1, deferred item), the cost stays flat `[unverified — submitted as claim]` (measured once, `perf-probe1.out`).
- The test change adds two `grep`s over SKILL.md inside an existing test, which is negligible `[read: test/scripts/build-loop-orchestrator.bats:366-371]`.
- pr-prep's quiesce line now waits only for this task's subagents, not for other sessions' agents. That removes an unbounded wait on unrelated work `[read: workflows/pr-prep.md:333]`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Iteration worktree never removed: registry and disk grow per iteration, +0.13 s per worktree on every import walk | Medium | `skills/dev-cycle/SKILL.md:227-228` | Medium |
| 2 | Health-check waiter abandoned past the hour still runs later and holds the gate lock | Low | `skills/dev-cycle/SKILL.md:253-259` | Medium |

## Overall Assessment

Per-call costs in the new frame are small: the snippet, `--state`, `--main-log` and the digest are each under a second at today's history. The cost that matters is accumulation across iterations. Each iteration leaves a 79 MB worktree registered, and every import walk (the orchestrator's `--check-fix`, and the loops' gates) gets slower in proportion. Both findings can be fixed in place with a sentence each. F1 belongs in U4b2's step 9 if not here. No profiling is needed beyond the measurements above.

## Goal-Alignment Note

The goal is a clean landing of U4b1. Neither finding blocks the frame's correctness. Until the D6 block lands (Q-140), the skill runs by hand, so neither cost is incurred yet. F1 is the one to carry forward: the U4b2 step list in the plan has no worktree removal, and once the loop runs unattended, the worktree pile-up is what slows the gate. F2 is a one-clause tightening of row 750's answer.
