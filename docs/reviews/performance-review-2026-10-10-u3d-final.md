Commit: 4b863735

# Performance Review: feat/build-loop-u3d (U3d, final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test` in /workspace/.claude/wt-build-loop-u3d. The new part since iteration 2 is ad5ff2d5 (`git diff e3781a2c..ad5ff2d5 -- scripts test`: scripts/build-loop.sh 66 lines changed, test/scripts/build-loop-dispatch.bats 13). 4b863735 touches only docs/.
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3d-final-r{1,2,3}.md (the merged report was not yet written); my iteration-2 report docs/reviews/performance-review-2026-10-10-u3d-i2.md (its findings 1 and 2 are settled by override rows); shared brief scratchpad/u3d-fin/shared.md

## Data Flow and Hot Paths

The path is the same as in iteration 2: `--start`/`--prompt` run once per process, `gate_start` then one `dispatch`. The orchestrator runs this a few times a day, with at most 4 dispatches per brief. **Path temperature: cold** for every changed line. ad5ff2d5 adds these costs per run:

- **The flock** (`scripts/build-loop.sh:1393`): one `git rev-parse --git-common-dir` fork, one `exec 9>>` open and one `flock -n 9` fork. It is taken after `gate_start` and held on fd 9 until the process exits. `-n` means it never waits. A second run refuses at once and does not queue. The lock covers only `dispatch`: about 35 ms of script logic plus git's checkout, which measured about 0.33 s in iteration 2 for `--start`/add, and about 37 ms for a relock-only `--prompt`.
- **readerform** (`scripts/lib/dev-cycle-read.sh:598-602`) replaces absform for `--dir`, the default DIR and an existing worktree's path. It is pure bash: one regex, then a loop over the path's components with no fork. Cost is O(path components).
- **The marker-tip rule** (`:1310`) reads `STATUS[loop]`, which `status_fields` already computed. It adds no git call.
- **B10's `head -n 1`** forks only on the failed-add refusal path.
- **B8/B9** (TIP as an argument, DISPATCH_CAP/STEAL_AGE) are variable reads only.

**Measurements** (this review, 2026-10-10, shared machine with sibling critics running, so read these as orders of magnitude). I ran `TMPDIR=$(mktemp -d /tmp/claude-1000/u3d-rev-perfrevfin-XXXX) bats --timing test/scripts/build-loop-dispatch.bats` twice, serially, under `timeout 300`:

| Test | i2 (e3781a2c) | final run 1 | final run 2 |
|---|---|---|---|
| 1 --start creates… | 236 ms | 256 ms | 257 ms |
| 2 --dir… (adds `--start --steal`) | 301 ms | 325 ms | 326 ms |
| 3 refusals (adds the background flock holder) | 791 ms | 906 ms | 914 ms |
| 4 --prompt… (adds the marker-tip run) | 1,376 ms | 1,538 ms | 2,229 ms |
| Suite wall | 2.7 s | 3.12 s | 3.82 s |

Both runs: 4/4 ok. Afterwards, `ps` showed no surviving `flock … build-loop-dispatch` or `sleep 20` process.

**The background holder** (`test/scripts/build-loop-dispatch.bats:64-67`) is bounded three ways:

1. `timeout 20` caps the holder at 20 s.
2. The readiness poll is at most 50 × 0.1 s = 5 s, and it `break`s as soon as the holder has the lock. In practice that is about one 0.1 s tick, which matches the roughly 0.1 s growth of test 3.
3. `kill "$p"; wait "$p" || true` runs unconditionally, because `dsp` is a bats `run` and cannot abort the test.

GNU `timeout` (not run with `--foreground`) forwards the signal it receives to its child's process group, so `sleep` dies along with `flock`. The worst case is a holder that never gets the lock: the poll spins 5 s, `dsp` then succeeds, and the test fails red. It does not hang. The fd-3 hazard (a background job keeping bats's output pipe open) is bounded by the same 20 s timeout and did not occur.

## Findings

#### 1. The dispatch lock's fd 9 is inherited by every child; harden is what keeps a child from outliving the script with the lock

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1393-1396`
**Move:** Find the contention point (a lock's lifetime is set by whoever holds the descriptor, not by the script's exit)
**Classification:** Micro (one inherited descriptor) / Cold path (once per dispatch)
**Confidence:** High for the mechanism (probed); Low that the honest path reaches it
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** whoever adds a child process to dispatch, or changes harden's config pairs (U3b's --state, U4)

Evidence:
```
    if ! { exec 9>> "$(git rev-parse --path-format=absolute --git-common-dir)/build-loop-dispatch.lock" && flock -n 9; } 2>/dev/null; then
      echo "refuse ${ARGS[0]}: another --start or --prompt is running in this repository (its lock could not be taken)"; exit 2
    fi
    dispatch "${ARGS[0]}" > "$GATE_TMP/line" || { cat "$GATE_TMP/line"; exit 2; }
```
and harden (`:393-399`, whole function):
```
harden() {
  local c="${GIT_CONFIG_COUNT:-0}" kv
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false; do
    export "GIT_CONFIG_KEY_$c=${kv%%=*}" "GIT_CONFIG_VALUE_$c=${kv#*=}"; c=$((c + 1))
  done
  export GIT_CONFIG_COUNT="$c"
}
```
`exec 9>>` opens the descriptor without close-on-exec, so every process `dispatch` starts inherits it: git (`update-ref`, `worktree add`/`lock`/`unlock`, `cat-file`), `date`, `awk`, `sed`, `head`. An flock belongs to the open file description, so any descendant that outlives the script keeps the lock. I probed this in a throwaway repo under `/tmp/claude-1000/u3d-rev-perfrevfin-*`, mimicking `:1393` and then `git worktree add -q --lock`. The repo had a post-checkout hook that backgrounds `sleep 3`.

- **Without harden:** the hook saw the lock fd. After the script exited the lock was "STILL HELD", and it was "freed after 3002 ms".
- **With harden's `core.hooksPath=/dev/null core.fsmonitor=false` pairs:** "lock free right after exit".

So on the honest path nothing can outlive the script holding the lock: harden turns off hooks and fsmonitor, the state gate refuses filter drivers and a partial clone, and i2's GIT_TRACE probe found no `gc --auto` child of `worktree add`. Fact-check r2 reached the same scope ("none of the commands run … daemonizes"), and r3's P4 saw the lock free after a `--start`. The residual cases are a caller that pads GIT_CONFIG_COUNT to re-enable a hook (trusted, per harden's comment) and a future child added to dispatch that backgrounds work. In either case, every later `--start`/`--prompt` refuses with "another --start or --prompt is running" until that descendant exits. That is a stall that fails closed and does not corrupt anything. The message's wrong-cause wording is already noted by the fact-check (Mostly accurate, `:1394`).

**Recommendation:** Optional. Run `dispatch "${ARGS[0]}" > "$GATE_TMP/line" 9>&-`. Bash saves the descriptor it closes for a redirection onto a close-on-exec copy, so the shell keeps the lock while no child inherits it. Alternatively, add a one-line comment at `:1393` saying the lock's release depends on harden's no-hook/no-fsmonitor pairs. No change is needed for this unit.

## Endorsements

- The dispatch lock never waits: `flock -n 9` refuses a second run at once, so a stuck holder cannot queue later runs behind it. The lock is taken after `gate_start`, so it does not cover gate_start's ~0.3 s store_check [read: scripts/build-loop.sh:1389-1398].
- The marker-tip exemption adds no git call. It tests `STATUS[loop]`, which `status_fields` already set, and the TIP for the prompt is passed as `STATUS[sha]`/`$MAIN_SHA` rather than re-read [read: scripts/build-loop.sh:1290-1330].
- `readerform` is fork-free and linear in the path's components (one regex, then a component loop), so swapping it in for absform costs nothing measurable [read: scripts/lib/dev-cycle-read.sh:598-602].
- The suite's background flock holder is bounded by `timeout 20`, a 5 s readiness poll and an unconditional `kill`/`wait`. Two serial suite runs took 3.1 s and 3.8 s, left no stray process, and test 3 grew by about 0.12 s [unverified — submitted as claim].
- With harden's config pairs, a repository post-checkout hook that backgrounds a process does not run during `worktree add`, and the dispatch lock is free as soon as the script exits [unverified — submitted as claim].

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Dispatch lock fd 9 is inherited by all children; only harden keeps a descendant from holding the lock past exit | Informational | `scripts/build-loop.sh:1393-1396` | High (mechanism) / Low (honest-path reach) |

## Overall Assessment

ad5ff2d5 adds no meaningful cost to the dispatch path. The flock costs two forks and an open. It is non-blocking, and it covers only dispatch (about 35 ms of logic plus git's checkout). readerform and the marker-tip rule are fork-free. The suite grew from 2.7 s to 3.1-3.8 s, mostly from the extra `--prompt` run in test 4 and the 0.1 s poll tick in test 3. The new background holder cannot hang the suite: it is bounded at 20 s and in practice gone within the test. The one note is about the lock's lifetime. It ends at exit only because harden turns off hooks and fsmonitor. That holds on the honest path today, and an optional `9>&-` would make it independent of harden. Iteration 2's findings (store_check startup, the checkout's cost) are unchanged and settled by override rows. No profiling is needed.

## Goal-Alignment Note

The goal is a safe, refusal-clean dispatch with one dispatch at a time. The flock serves that goal at negligible cost and fails closed. My single finding does not ask to weaken it. It only asks that the lock's release not rely silently on another function's config pairs. Nothing here trades the gate's coverage for speed.
