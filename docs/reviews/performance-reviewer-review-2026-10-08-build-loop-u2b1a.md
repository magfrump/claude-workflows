Commit: 9e5d92df

# Performance Review — feat/build-loop-u2b1a (`build-loop.sh --check`)

**Scope:** `git diff main...HEAD` (HEAD 9e5d92df): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh` header
**Date:** 2026-10-08
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b1a-i2.md (via the shared brief's Stage 1 summary)

## Data Flow and Hot Paths

`--check BRIEF...` runs once per orchestrator iteration over the briefs whose branches carry a ready marker (a handful). Per process: `harden` (env only), `state_gate` (6 git calls), `resolve_main`, `read_settings`, `open_shared` (one `git grep` plus `ls-tree`+`cat-file` per open brief on main). Per brief, in a subshell: `status_line` (~13 git calls, unchanged from `--status`), then `check_line`'s own re-read through `check_branch` (6 calls), `merge_result` (`rev-parse --git-common-dir`, `mktemp -d`, `merge-tree`). Path temperature: **cold**. It runs per loop iteration, not per request, over a handful of items, and nothing waits on it with a latency budget. Under the calibration matrix, every finding below is therefore Low or Informational.

**Measurements** (this session, 2026-10-08; a local clone of /workspace main, 3,120 files and 2,325 commits, with 5 open briefs and 5 branches each one commit plus a `handoff: ready` marker ahead of a main that has moved on; git 2.39.5, WSL2; 10-run means, scratch `/tmp/perfu2b1a-SlKH`):

| Run | Wall time | git calls (PATH shim) |
|---|---|---|
| `--check` 5 briefs | 342 ms | 155 |
| `--status` 5 briefs | 269 ms | 109 |
| `--check` 1 brief | 140 ms | 55 |
| `--status` 1 brief | 112 ms | 41 |

Each git spawn costs 1.2 to 2.3 ms here, and the run's wall time is almost entirely spawn count. `--check`'s cost over `--status` is +46 calls for 5 briefs: 6 (state gate) + 5 × 8 (6 `check_branch`, 1 `--git-common-dir`, 1 `merge-tree`). That is about +73 ms per iteration, or about 12 ms per brief plus about 15 ms fixed.

## Findings

#### F1: check_line's re-read runs all of check_branch (6 git calls) where 2 would answer "moved"

**Severity:** Low
**Location:** `scripts/build-loop.sh:463-466` (excerpt from `check_line`, :456-475)
**Move:** Hidden multiplication
**Classification:** Micro (constant per-brief spawn overhead) / Cold path (once per brief per loop iteration)
**Confidence:** High
**Baseline:** 6 git calls ≈ 9.8 ms per brief (shim-timed: check-ref-format ×2, show-ref, rev-parse ^{commit}, rev-list --count, log -1 %cs), 2026-10-08 benchmark above
**Legibility-target:** for-author
**Evidence:**
```
  out="$(check_branch "$br")"
  read -r _ _ _ n _ <<<"$out"
  if [[ "$out" != "ok $br $sha "* || ! "$n" =~ ^$DIGIT+$ ]]; then echo "refuse $a: its branch $br moved or could not be read again"; return; fi
  if [[ "$n" -eq 0 ]]; then echo "refuse $a: its branch $br has no commit the default branch lacks"; return; fi
```

`status_line` already ran `check_branch "$br"` in the same subshell a few ms earlier. The re-read repeats the name validation (two `check-ref-format`) and the date read (`log -1 --format=%cs`), and neither can change for a name already validated. The only new facts it produces are the current tip (show-ref, plus the `^{commit}` peel) and the ahead count. The ahead count is needed only because `status_line`'s output line drops `ahead`. The cost is about 20% of `--check`'s per-brief time (≈ 9.8 of ≈ 50 ms), or ≈ 49 ms per 5-brief iteration. That is harmless at this scale, but it is the largest single item `--check` adds per brief.

**Recommendation:** Optional. Re-read only `show-ref --verify --hash refs/heads/$br` (then the existing peel) and compare it to `$sha`, and take `n` from one `rev-list --count`, or have `status_line` expose `ahead`. That gives the same refusal semantics in 2 to 3 calls. If you keep the full `check_branch` on purpose (one validated reader, no parallel logic), say so in a comment and leave it. The cost does not justify a second reader.

#### F2: state_gate makes four rev-parse calls where one prints all four paths

**Severity:** Informational
**Location:** `scripts/build-loop.sh:185, 194` (in `state_gate`, :182-200)
**Move:** Hidden multiplication
**Classification:** Micro / Cold (once per process)
**Confidence:** High
**Baseline:** one `rev-parse --git-path` = 762 µs; one call with four `--git-path` arguments = 787 µs (200-run means, 2026-10-08 benchmark clone). The four separate calls cost ≈ 3.0 ms, the single call 0.8 ms.
**Legibility-target:** for-author
**Evidence:**
```
    f="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { echo "refuse state $f: its path could not be read"; return 1; }
```
```
    line="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { echo "refuse state $f: its path could not be read"; return 1; }
```

`git rev-parse --path-format=absolute --git-path config --git-path config.worktree --git-path info/attributes --git-path info/grafts --git-common-dir` prints all five lines in one spawn (checked in the clone). That would also give `merge_result` its common dir (F3). The saving is ≈ 2 ms per `--check` process, so only do it if the gate is touched anyway (the planned temp-git-dir rework touches this area).

**Recommendation:** Optional. Read the paths in one call with `mapfile` and fail closed if fewer than the expected number of lines come back.

#### F3: merge_result recomputes the loop-invariant common dir and makes a fresh temp dir per brief

**Severity:** Informational
**Location:** `scripts/build-loop.sh:446-449` (excerpt from `merge_result`, :444-454)
**Move:** Work moved to the wrong place (loop-invariant work inside the per-brief path)
**Classification:** Micro / Cold
**Confidence:** High
**Baseline:** `rev-parse --git-common-dir` 1.5 ms (shim) + `mktemp -d` 0.63 ms (200-run mean) ≈ 2.1 ms per brief, 2026-10-08 benchmark
**Legibility-target:** for-author
**Evidence:**
```
  common="$(git rev-parse --path-format=absolute --git-common-dir)" || return 2
  [[ -n "$GATE_TMP" ]] || return 2
  t="$(mktemp -d "$GATE_TMP/m.XXXXXX")" || return 2
  out="$(cd "$t" && git --git-dir="$common" merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?
```

The common dir cannot change within a run, and merge-tree writes nothing into its cwd, so one empty directory serves every brief. The per-brief subdirectories also stay in place until the EXIT trap. That is bounded by the argument count, so it is not a leak. Each fix saves ≈ 2 ms per brief, and only matters if the brief count grows.

**Recommendation:** Compute `common` and one empty dir once, next to `GATE_TMP="$(mktemp -d)"` (:488). On the author's planned rework (merge-tree in a gate-owned temporary git dir that shares only the object store), build that git dir **once per process**, not per brief. Keep the real `objects/` as `GIT_OBJECT_DIRECTORY` (not as an alternate behind an empty store) so `objects/info/commit-graphs` still speeds merge-base. If you choose an empty store plus alternates to stop the merge objects from landing in the repo, the printed TREE would not resolve in the repo afterwards. That is a contract change for U2b1b/U2b2, not a speed question.

#### F4: merge-tree writes merge objects into the shared store on every run, conflicts included

**Severity:** Informational
**Location:** `scripts/build-loop.sh:449`
**Move:** Memory/resource lifecycle (on-disk growth)
**Classification:** Micro (a handful of objects per changed path) / Cold
**Confidence:** High
**Baseline:** measured 2026-10-08 in the benchmark clone. A 100-file branch off main~150, merged into main, took 14.5 ms, exited 1 (conflict) and wrote 126 loose objects (count-objects 897 → 1023). Re-running an identical merge wrote 0 new objects (897 → 897). An 837-file divergence with no content merges took 3.1 ms.
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
```
  out="$(cd "$t" && git --git-dir="$common" merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?
```

merge-tree itself is cheap (1.1 ms for a one-file branch, 3 to 15 ms for large ones). Its side effect is loose objects. A refused (conflicting) brief re-polled every iteration adds new objects whenever main moves. merge-tree never triggers `gc --auto`, so only the user's ordinary commits collect them (threshold 6,700). The usage header already documents this ("Writes nothing but --check's merge objects"). This is a note for long unattended loops, not a defect.

**Recommendation:** None needed now. If the loop runs unattended for days against a conflicting brief, watch `git count-objects` or let the loop's own commits' auto-gc handle it.

## Endorsements (evidence-gated)

- `open_shared` runs once per `--check` process even though `check_line` runs `status_line` in a subshell. The main-shell call at :487 fills `OPEN_SHARED` before the loop, and the guard at `dev-cycle-read.sh` `open_shared` (`[[ -z "$OPEN_SHARED" ]] || return 0`) then returns early in every subshell. Supporting measurement: 5-brief `--check` made exactly 46 more git calls than `--status` (155 vs 109 = 6 + 5 × 8), so no per-brief re-enumeration (which would add 16+ calls per brief here). `[unverified — submitted as claim]`
- `harden`'s four config-count pairs and the added `GIT_OPTIONAL_LOCKS`/`GIT_ATTR_NOSYSTEM` add no measurable per-call cost: `git rev-parse --verify HEAD` took 1,030 µs with the full hardened env vs 1,048 µs through bare `env` (200-run means). `[unverified — submitted as claim]`
- The merge computation stays in memory (no index, no work tree, no checkout), and its cost scales with the paths both sides changed, not with repo size: 1.1 ms for a one-file branch, 3.1 ms for an 837-file divergence, 14.5 ms for 100 content-merged files. `[unverified — submitted as claim]`
- `marker_kind`'s switch from `git log -1 --format=%B` to `git cat-file commit` keeps the call count the same (rev-list + cat-file, plus the pre-existing NUL-check cat-file only for `handoff:` subjects). `[read: scripts/build-loop.sh:369-396]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | check_line's re-read runs all of check_branch (6 calls, ≈ 9.8 ms/brief) where 2 would answer "moved" | Low | `scripts/build-loop.sh:463-466` | High |
| 2 | state_gate makes four `rev-parse --git-path` spawns where one prints all four (≈ 2 ms/process) | Informational | `scripts/build-loop.sh:185,194` | High |
| 3 | merge_result recomputes the common dir and makes a temp dir per brief (≈ 2 ms/brief); build the planned temp git dir once per process | Informational | `scripts/build-loop.sh:446-449` | High |
| 4 | merge-tree writes loose objects each run, conflicts included (126 for a 100-file merge; 0 on an identical re-run) | Informational | `scripts/build-loop.sh:449` | High |

## Overall Assessment

`--check` costs about 15 ms fixed plus about 12 ms per brief on top of `--status` (342 vs 269 ms for 5 briefs here). That is spawn count, not algorithmic cost: no path in the diff scales with repo size or history depth except the ones `--status` already had. The two places where the diff hoists work are correct: `open_shared` runs once per process, and `harden`'s environment costs nothing per call. The one item worth a thought is F1, the full `check_branch` re-read, which is about a fifth of the per-brief increment. All four findings can be fixed in place, and none blocks the merge. For the author's planned temp-git-dir rework, the performance points are: create it once per process, and point `GIT_OBJECT_DIRECTORY` at the real object store so the commit-graph is still used.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 9e5d92df` line at the top.
- Answered: yes
- Out of scope: the per-path rules (U2b1b); pre-existing `--status` duplicate brief reads (status_line reads the same brief's ls-tree 3× and cat-file 2×, unchanged by this diff); the merge-tree submodule lazy-fetch finding (fact-check's, not re-reported).
- Escalate: nothing
