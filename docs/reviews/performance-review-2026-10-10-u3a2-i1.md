# Performance Review — feat/build-loop-u3a2 (iteration 1)

**Scope:** `git diff main...HEAD` at 7d78e6d0 (`scripts/build-loop.sh`, `test/scripts/build-loop-merge.bats`)
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-u3a2-i1.md` (Stage 1), override log rows 639/642/646

## Data Flow and Hot Paths

`--merge BRIEF --expect SHA` is a one-brief-per-process command that the orchestrator runs once per landed self-merge brief. The plan has the loop run `--check` first as an advisory dry run, in its own process (plan line 28). The whole mode is a **cold path**: it runs once per landing, a few times a day. No request handler or per-item loop runs it at scale. What it costs:

- **Inherited from --check:** `gate_start` (one `store_check --main` pass over main's tree; row 639 measured 0.24 s at 68 MB), then one `check_line` (per-brief `store_check "$sha" "$tree"` at :963, merge-tree, then the per-path rules).
- **New in `land` (:1018-1078):** 2 `git var` forks; 1 `commit-tree`; 1 `worktree list`; a scan over `$common` plus each `worktrees/*` dir with 3 `$(cat …)` forks per dir; with W: 7 `rev-parse --git-path` forks, 1 `git status --untracked-files=no`, and a bash-builtin prefix walk over the added paths; then `state_gate` + `default_gate` (+ `state_gate` in W); then `update-ref` or `merge --ff-only` in W.

Measured on /workspace (3,345 tracked files, 8 worktrees, git 2.39.5, ext4; read-only probes under `/tmp/u3a2-perf-*`):

| Step | Cost |
|---|---|
| `state_gate` + `default_gate` + `state_gate` in W | 22 ms avg (5 runs) |
| worktree rebase/bisect scan (8 git dirs × 3 `cat`) | 19 ms avg |
| 7 marker `rev-parse --git-path` | 5 ms avg |
| `git status --porcelain=v1 -z --untracked-files=no` in /workspace | 3–4 ms |
| `git worktree list --porcelain -z` | 1 ms |
| prefix walk, synthetic 5,000 added paths at depth 5 | 111 ms (a real merge such as 2167ad9d changes 27 paths: well under 1 ms) |

`land` adds about 50 ms plus the fast-forward checkout itself. That is small next to the one `store_check --main` pass of 0.24 s. **Row 639's trigger ("U3a2's --merge adding a second full pass") is not met inside a process.** `land` never calls `store_check`, and `--merge` calls `gate_start` once (:1098). Across processes, the plan's flow (the loop's advisory `--check`, then the orchestrator's `--merge`) pays two full passes per landing, about 0.5 s total. That two-pass cost comes from the flow in the plan, not from this diff.

## Findings

#### 1. ff-merge in W runs repo-configured maintenance tasks (repack, prune-packed) in the foreground; gc.auto=0 does not stop them

**Severity:** Low
**Location:** `scripts/build-loop.sh:1071-1072`
**Move:** Find the work that moved to the wrong place / Price the deployment environment
**Classification:** Macro (the task's cost scales with the whole object store, not with the merge) / Cold path (once per landing), escalated from Informational because the cost has no bound and comes from repo-local config that `state_gate` does not refuse
**Confidence:** High (probed)
**Baseline:** no baseline available — flagged as speculative (the cost of a repack on /workspace's store was not measured; the probe below shows only that the repack runs)
**Legibility-target:** for-author

**Evidence:**
```
    # gc.auto=0: merge would start a git gc of the store store_check read.
    git -C "$w" -c gc.auto=0 merge --ff-only -q "$NEW" > "$GATE_TMP/ff" 2>&1 || { MERGE_WHY="the fast-forward in $in failed"; return 1; }
```

Fact-check claim 13 established that the merge still starts `git maintenance run --auto`. I probed the next step in a temp repo (`maintenance.loose-objects.enabled=true`, `maintenance.loose-objects.auto=1` in `.git/config`, 120 loose commits). `git -c gc.auto=0 merge --ff-only` ran `git prune-packed` and `git pack-objects .git/objects/pack/loose` in the foreground, and the store went from 0 packs to 2. `STATE_KEYS_RE` (:328) does not match `maintenance.*`, so any repo-local `maintenance.<task>.enabled` (loose-objects, incremental-repack, commit-graph, pack-refs) runs inside `--merge`, after the branch has moved. The time it takes scales with the store, not the merge, so `--merge`'s wall time has no bound. An incremental-repack also rewrites the store that `store_check` just certified. That second effect is a security matter and is out of scope for this review. /workspace sets none of these keys today (checked), so this costs nothing now.

**Recommendation:** Add `-c maintenance.auto=false` beside `gc.auto=0`. A probe confirmed that it stops `run_auto_maintenance` outright: no `git maintenance` process starts, no pack is written, and one fork is saved on every landing. Then reword the comment at :1071 to match. The other option is to add `maintenance\.` to `STATE_KEYS_RE`, but that refuses the run rather than avoiding the cost.

#### 2. Worktree rebase/bisect scan forks a `cat` for every probe file, almost all of them absent

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1037-1043`
**Move:** Count the hidden multiplications
**Classification:** Micro (a fork per absent file) / Cold path (once per landing)
**Confidence:** High
**Baseline:** 19 ms avg per scan on /workspace (8 git dirs, 24 `$(cat …)` substitutions; probe 2026-10-10, 5 runs)
**Legibility-target:** for-author

**Evidence:**
```
  for d in "$common" "$common"/worktrees/*; do
    [[ -d "$d" ]] || continue
    for q in rebase-merge rebase-apply; do
      [[ "$(cat "$d/$q/head-name" 2>/dev/null)" != "refs/heads/$MAIN" ]] || { MERGE_WHY="a worktree is rebasing the default branch"; return 1; }
    done
    [[ "$(cat "$d/BISECT_START" 2>/dev/null)" != "$MAIN" ]] || { MERGE_WHY="a worktree is bisecting from the default branch"; return 1; }
  done
```

The scan costs 3 forks for each git dir, and the number of git dirs grows with the worktree count, stale `worktrees/` entries included. Each fork costs about 0.6 ms here, and in nearly every run the file is absent. That is about 19 ms now, rising linearly, which is negligible for a once-per-landing command.

**Recommendation:** Optional. Guard each read with `[[ -f … ]]` before the substitution, or use `$(<file)`, so that absent files cost a `stat` and no fork. Only worth doing if the file is being edited anyway.

## Endorsements

- Inside one `--merge` process, main's tree is re-hashed once: `--merge` calls `gate_start` once and `land` calls no `store_check`. Row 639's "second full pass" trigger is therefore not met within a run [read: scripts/build-loop.sh:1018-1078, 1097-1106, 896-903].
- The added-path prefix walk uses only bash builtins (`[[ -e/-d/-L ]]`, `${q%/*}`, associative lookup) and forks nothing per path. Its cost is O(sum of path depths), 111 ms for a synthetic 5,000 paths and under 1 ms for real merges [read: scripts/build-loop.sh:1053-1062].
- `git status` in W passes `--untracked-files=no`, so it does not walk W's untracked tree (about 68 MB, many ignored build dirs). The only untracked/ignored check is the per-added-path `stat`. Measured at 3–4 ms on /workspace [unverified — submitted as claim: with GIT_OPTIONAL_LOCKS=0 and fsmonitor off, this status stays O(tracked files) lstat and does not re-hash file contents when W's index stat data is fresh].
- `CHANGED[$p]` is filled inside the diff-tree read loop that already exists, so the new data costs O(1) per changed path and adds no extra pass [read: scripts/build-loop.sh:945-949].

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | ff-merge runs repo-configured maintenance tasks in the foreground; gc.auto=0 does not stop them | Low | `scripts/build-loop.sh:1071-1072` | High |
| 2 | Rebase/bisect scan forks `cat` per absent file (24 forks, 19 ms) | Informational | `scripts/build-loop.sh:1037-1043` | High |

## Overall Assessment

For a once-per-landing command, this diff's performance is sound. `land` adds about 50 ms of forks and stats, while the single `store_check --main` pass (0.24 s) still dominates. Nothing in the new code scales worse than linearly. The terms that scale with changed paths (the prefix walk) and with worktrees (the scan, `worktree list`) are cheap even at sizes well beyond today's. The only finding to act on is #1: one `-c maintenance.auto=false` flag closes off unbounded foreground maintenance work. Row 639's trigger stays unmet per process. If the orchestrator's flow keeps the loop's advisory `--check` before every `--merge`, each landing pays two full passes (about 0.5 s), which is acceptable at today's size. A revisit of row 639 should count passes per landing, not per process. No profiling is needed to decide anything here.

## Goal-Alignment Note
- Success criterion (restated verbatim): "A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/performance-review-2026-10-10-u3a2-i1.md, structured per the performance-reviewer skill."
- Answered: the per-A-path prefix walk (endorsed, measured), the re-run state gates (22 ms), git status in W (3–4 ms), the second store pass (not added within a process; two per landing across the plan's processes), the costs that scale with worktree count (finding 2), and a new foreground-maintenance cost (finding 1, probed).
- Out of scope: the security side of finding 1 (a repack rewrites the store after `store_check`), and the correctness of the W checks.
- Escalate: finding 1's store rewrite to the security critic, as a possible addition to `STATE_KEYS_RE` (`maintenance.*`) or a companion to the row-646 residual.
