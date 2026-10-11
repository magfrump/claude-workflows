Commit: e3781a2c

# Performance Review: feat/build-loop-u3d (U3d, iteration 2)

**Scope:** `git diff main...HEAD -- scripts test` in /workspace/.claude/wt-build-loop-u3d (scripts/build-loop.sh +172/-10, test/scripts/build-loop-dispatch.bats new, 102 lines)
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3d-i1.md; shared brief scratchpad/u3d-i2/shared.md

## Data Flow and Hot Paths

`--start BRIEF` and `--prompt BRIEF` run once per process: the top-level `state_gate`, then `gate_start` (`scripts/build-loop.sh:994-1001`: `default_gate`, `gate_repo`, `store_check --main "$MAIN_SHA"`, `reader_settings; read_settings; never_res; open_shared`), then one `dispatch` (`:1282-1320`). `dispatch` runs `status_fields` (one `check_brief` with its `git log -G` walk, `check_branch`, and `marker_kind` when the branch is ahead), one `git cat-file blob` for docs/constraints.md, one `git worktree list --porcelain -z` (`wt_of`), and then either a lock or unlock+lock (`--prompt` on an existing worktree) or `update-ref` plus `git worktree add --lock` (a checkout of main's tree, or of the branch tip for `--prompt`). `steal` adds one `date` and one `git cat-file commit | awk`. `loop_prompt` is two heredocs and one `sed`.

Call frequency: the plan caps dispatches at 4 per brief and slots at 9. The orchestrator calls this a few times a day. **Path temperature: cold** for every line of the diff. Nothing here is a loop over data except `wt_of` (O(worktrees)) and `open_shared` (O(open briefs), cached per process and already shared with `--check`).

**Measurements** (this review, 2026-10-10). Each was taken in a throwaway `git clone` of /workspace under `mktemp -d /tmp/claude-1000/u3d-rev-perfrev-XXXX`, with main at 12913760 plus a fixture commit (docs/constraints.md and one open brief). Main's tree is 3,392 files and 69.4 MB of blobs; the store is 21,968 packed objects in 5 packs (425 MB). I instrumented a copy of `scripts/` with `$EPOCHREALTIME` around each `gate_start` step and around `dispatch`. Nothing ran in /workspace or the review worktree, and the temp dirs are removed. The machine is shared, and sibling critics' suites were running at the same time, so read these as orders of magnitude.

| Run | Wall (3 runs) | Breakdown |
|---|---|---|
| `--status BRIEF` (no gate_start) | 85 / 81 / 83 ms | |
| `--check BRIEF` (branch absent, skips before check_line's store_check) | 366 / 358 / 397 ms | store_check 253-282 ms |
| `--start BRIEF --dir D` | 737 / 720 / 679 ms | default_gate 3.4-4.4 ms; **store_check 252-264 ms**; reader_settings 4.1-4.7 ms; read_settings 7.5-8.4 ms; never_res+open_shared 24.6-26.3 ms; **dispatch 353-391 ms** |
| Bare `git worktree add -q -b B D main` (same clone) | 335 / 331 / 333 ms | |
| `--prompt BRIEF --dir D` (branch exists, no worktree: add) | 707 ms | store_check 258 ms; dispatch 369 ms |
| `--prompt BRIEF` (unlocked worktree: relock only) | 369 ms | store_check 258 ms; dispatch 37 ms |
| `--prompt BRIEF --steal` (fresh lock: refused) | 1,665 ms (1 run) | default_gate 620 ms, store_check 939 ms: an outlier taken straight after a worktree add, under concurrent load; default_gate is two `show-ref`s and two `symbolic-ref`s, so contention is the likely cause |
| `bats test/scripts/build-loop-dispatch.bats` (fixture repos) | 236 + 301 + 791 + 1,376 ms = 2.7 s, 4/4 ok | |

What the numbers show: `--start` costs about 0.7 s. About 0.3 s is `gate_start`, which is the same startup `--check` pays (store_check is ~37% of the run). About 0.33 s is git's own checkout in `worktree add`. The script's own dispatch logic above the checkout is about 35 ms (369 − 335, and the 37 ms relock-only path agrees). A `GIT_TRACE=1` probe of `git worktree add -q --lock` in a throwaway repo with `gc.auto=1` and `maintenance.auto=true` ran only `git branch`, `symbolic-ref` and `reset --hard --no-recurse-submodules`. It started no `gc --auto` or maintenance child, so the unbounded-maintenance problem U3a2 i1 found in `merge` does not apply to the add.

## Findings

#### 1. --start and --prompt pay --check's full store_check startup; dispatch reads four of main's blobs

**Severity:** Informational
**Location:** `scripts/build-loop.sh:994-1001` (gate_start), called at `:1379`
**Move:** Find the work that moved to the wrong place (startup shared with a mode that needs more)
**Classification:** Macro (scales with main's tree bytes) / Cold path (once per dispatch, at most 4 per brief)
**Confidence:** High (measured)
**Baseline:** store_check --main 252-264 ms of a 679-737 ms `--start`, measured 2026-10-10 on a clone of /workspace (this review, 3 runs)
**Legibility-target:** whoever revisits the "store_check over 1 s" trigger, or writes a dispatch-only gate (U3b, U4)

Evidence:
```
gate_start() {
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
  store_check --main "$MAIN_SHA" \
    || { echo "refuse state objects: the default branch's commit or an object of its tree does not hash to its id, has a second copy in the object store, or could not be read"; exit 2; }
  reader_settings; read_settings; never_res; open_shared
}
```
and
```
  start|prompt)
    gate_start
    dispatch "${ARGS[0]}" > "$GATE_TMP/line" || { cat "$GATE_TMP/line"; exit 2; }
    cat "$GATE_TMP/line"
    ;;
```

The objects of main's that `dispatch`'s decision reads are the brief (`brief_fields`), the other open briefs (`open_shared`), docs/dev-cycle.md (`read_settings`) and docs/constraints.md (`:1293`). `store_check --main` re-hashes every blob of main's 3,392-file tree to cover them. Two more steps are dead weight for dispatch: `reader_settings` (the import walks' reader lists; dispatch runs no walk) and `never_res` (the S rules' regexes). Together those two cost about 4-5 ms. In --start's case the whole-tree re-hash does more than cover the decision: `worktree add` checks out main's tree into the loop's worktree, so the re-hash also certifies the bytes the loop starts from. That is a security reason, and its judgment belongs to the security reviewer. In --prompt's case the checkout is the branch tip, which store_check never reads, so there the full pass covers only the four blobs. The cost grows linearly with main's bytes (row 639's settled shape). It is well under the deferred trigger in docs/working/merge-msg-build-loop-u3a1.md:34 ("store_check over 1 s"): 0.25-0.28 s across 9 of 10 samples, with one 0.94 s outlier under load.

**Recommendation:** No change now. Keeping one `gate_start` for every deciding mode is simpler than a dispatch-only variant, and it saves at most ~0.26 s on a command run a few times a day. If the store_check trigger ever fires, the cheap split is a dispatch-specific `store_check` over the blobs dispatch reads (plus main's tree only for `--start`), not a cache.

#### 2. The checkout in `git worktree add` is half of --start's wall time and scales with main's tree

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1309`
**Move:** Ask "what's the size of N?"
**Classification:** Macro (proportional to main's checked-out bytes) / Cold path
**Confidence:** High (measured)
**Baseline:** bare `git worktree add` 331-335 ms for 3,392 files / 76 MB on disk, measured 2026-10-10 on a clone of /workspace (this review, 3 runs)
**Legibility-target:** the plan's D1 owner, sizing disk for 9 concurrent slots

Evidence:
```
    elif ! git worktree add -q --lock --reason "$reason" "$DIR" "$br" > "$GATE_TMP/add" 2>&1; then
```
The add is one git call that creates the branch's worktree and its lock together, and the measured overhead of `dispatch` beyond it is ~35 ms. Each dispatch writes a full working copy (76 MB today) per brief, up to 9 slots, so up to about 0.7 GB of worktrees on disk when all slots run at once. The design (D1: one worktree per loop) requires this. The diff adds no repeated checkout: `--prompt` reuses an existing worktree and only re-locks it (37 ms measured). `--prompt` adds a worktree only when none holds the branch.

**Recommendation:** None for this unit. If disk or dispatch latency ever matters at larger tree sizes, a sparse or `--no-checkout` add would be a design change to D1, not a fix here.

## Endorsements

- The branch is created and its worktree added and locked in one `worktree add --lock --reason` call, with no separate `git worktree lock` round trip on the add path. On a refusal, the only cleanup is one `update-ref -d` [read: scripts/build-loop.sh:1305-1312].
- `open_shared` runs once per process. `dispatch`'s `status_fields` reaches it again, but it returns at once because gate_start already set OPEN_SHARED (`[[ -z "$OPEN_SHARED" ]] || return 0`) [read: scripts/lib/dev-cycle-read.sh:508-527, scripts/build-loop.sh:642-647].
- `wt_of` reads `git worktree list --porcelain -z` once into `$GATE_TMP/wts` and parses it in the shell with no per-record fork, so it is O(worktrees) [read: scripts/build-loop.sh:1246-1262].
- In a probe, `git worktree add` started no `gc --auto` or `maintenance` child even with `gc.auto=1` and `maintenance.auto=true` set in repo config (GIT_TRACE showed only `branch`, `symbolic-ref` and `reset --hard`). This is for git 2.39 as used here [unverified — submitted as claim].
- The new suite has 4 tests and took 2.7 s in total (the slowest test 1.4 s, about 14 script runs at ~0.1 s each in a fixture repo), which fits its `@category fast` tag [unverified — submitted as claim].

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | --start/--prompt pay --check's whole-tree store_check startup (~0.26 s of ~0.7 s); reader_settings and never_res unused by dispatch (~5 ms) | Informational | `scripts/build-loop.sh:994-1001` | High |
| 2 | `worktree add` checkout is ~0.33 s of --start and one full working copy per slot | Informational | `scripts/build-loop.sh:1309` | High |

## Overall Assessment

For a command run at most 4 times per brief, the dispatch path performs well. `--start` takes about 0.7 s, split roughly evenly between the shared `gate_start` startup (dominated by the settled whole-tree `store_check`, ~0.26 s) and git's own checkout (~0.33 s). The new logic above those costs about 35 ms. Nothing in the diff runs inside a loop over data, and nothing scales worse than linearly. The one cost a dispatch-specific gate could save is about 0.26 s per call. It is not worth the second code path at today's size, and the existing "store_check over 1 s" trigger already covers it. The suite adds 2.7 s. No profiling is needed to decide anything here.

## Goal-Alignment Note

The PR's goal is a safe, refusal-clean dispatch of a build loop. The costs I measured follow from that goal: the shared state gate and the worktree that D1 requires. Neither finding asks for a change that would trade away the gate's coverage for speed. Whether the whole-tree re-hash is the right coverage for `--prompt` (whose checkout is the tip, not main) is a question for the security reviewer, not a performance problem.
