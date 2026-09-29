Commit: 5a6d689

# Performance Review — q094-exit-scan-worktree-layout (review-fix loop pass 1)

**Scope:** `git diff main...HEAD` (devcontainer-config/cc-exit-scan.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, plan doc)
**Date:** 2026-09-28
**Based on:** Stage 1 code-fact-check (k=1) as summarized by the orchestrator, plus scratch measurements (scripts in the session scratchpad `perf/`: `measure.sh`, `quad.sh`, `biggitdir.sh`, `wbypass.sh`; bash, hand-made repos, same machine, 2026-09-28)

## Data Flow and Hot Paths

`git_exit_scan` runs once per cc-isolated session, on the user's terminal, after claude exits. It takes an exit snapshot (`git_exec_snapshot`), and, only when that differs from the launch snapshot and `.git` is still valid, now calls `scan_std_worktrees` (`cc-exit-scan.sh:801-909`) before falling back to `scan_diff` and the warning. **Path temperature: cold** (once per session), but it blocks the user's terminal, and a hostile session chooses the input sizes. The guide's documented baseline for the snapshot itself: "about 2–4 s per snapshot on a ~400k-file repository, and about 29 ms more for each embedded repository" (`guides/cc-isolated-usage.md:378-380`). Every added worktree is an embedded repo for the snapshot. In my scratch runs the exit snapshot cost about 42 ms per added worktree ((2,186 − 63) ms / 50).

`scan_std_worktrees` data sizes: `left` holds 3 records per added worktree (dotgit, commondir-file, hooksdir). The realistic case is 1–50 agent worktrees. A hostile session can plant any number, and only the snapshot's own linear cost limits it.

Common path (snapshots equal): the only new work is `_snap_wrel`, which appends a W record for relative hooksPath, attributesFile or local-remote values. `git_exit_scan` returns at line 942 before reaching the new code.

Measured cost of `scan_std_worktrees` (standard worktrees, scratch paths ~95 chars):

| added worktrees | exit snapshot | scan_std_worktrees | result |
|---|---|---|---|
| 2 | 163 ms | 74 ms | note |
| 10 | 532 ms | 345 ms | note |
| 50 | 2,186 ms | 1,749 ms | note |
| 50 + one planted hook | 2,417 ms | 20 ms | declines (correct) |
| 200 | 14,833 ms | 14,174 ms | note |
| 300 | — | 18–20 ms | **declines (wrong: every change is standard)** |
| 600 | 33,277 ms | 18 ms | **declines (wrong)** |

## Findings

#### 1. `printf | grep -q` under `pipefail` makes the note depend on snapshot size, and one fix alone would open a bypass

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:807`, `:812-813` (same pattern pre-existing at `:939`)
**Move:** Ask "what's the size of N?" / Check the asymptotic behavior (a size-dependent cliff)
**Classification:** Macro (behavior changes with snapshot size) / Cold path (once per session exit, on the user's terminal)
**Confidence:** High
**Baseline:** In my scratch measurement on 2026-09-28 (`perf/measure.sh 300`), `scan_std_worktrees` returned 1 for 300 standard worktrees with a 139,834-byte exit snapshot. With the line-812 grep switched to a here-string (`perf/patched/`), it returned 0 on the same snapshots.

The launcher runs under `set -euo pipefail` (`cc-isolated.sh:65`). At line 812, `grep -qxF` finds the `F commondir` record near the top of the sorted snapshot and exits. `printf` is still writing the rest, gets SIGPIPE, and the pipeline returns 141, so `|| return 1` fires. That happens once enough bytes follow the match to fill the pipe plus grep's read buffer. It passed at about 93 KB (200 worktrees) and failed at 140 KB (300 worktrees). Timing decides the exact point, so near it the result can flip between runs. Past that size, the note never prints and the user gets the full warning and exit 3 for plain agent worktrees. With the ~50-character `/workspace/.claude/worktrees/agent-<hex>` paths the cutoff is higher, very roughly 300–450 worktrees. Other snapshot records that sort after `F commondir` (hooks, embedded repos' records) lower it. Today this fails closed.

The important part: line 807 (`printf | grep -q $'^W\t'` inside an `if`) has the same defect in the fail-open direction. When a large block of W records follows the first one, the grep exits early, the pipeline returns 141, the `if` reads false, and the W refusal is skipped. `perf/wbypass.sh 3000` builds a checkout whose launch config holds `core.hooksPath = .husky/_` plus 3,000 relative-path remotes (185,011 bytes of W records) and adds one standard worktree:
- **Shipped code:** declined 3 of 3 tries. That is only because the line-812 grep also hit SIGPIPE, and the `F commondir` record always has more bytes after it than the first W record.
- **Line 812 fixed alone:** returned 0 (note printed, exit 0) 3 of 3 tries, even though a relative hooksPath is present. A new worktree's `.husky/_` hooks would be unscanned.

So the two bugs currently cancel out, but the cover is timing-dependent, and fixing either line alone (the obvious fix for the false warning) turns the W check fail-open. This needs a checkout config with thousands of relative remotes present at launch, which is within the guide's "Anything present at launch" limit. Please route it to the security reviewer. Line 939 has the same pre-existing pattern: a SIGPIPE there drops the `!` invalid line, but the changed `gitdir-valid` record still produces a warning.

**Recommendation:** Replace all three pipelines with forms that have no pipe, in one change, e.g. `LC_ALL=C grep -q $'^W\t' <<< "$after"` and `LC_ALL=C grep -qxF -e "<rec>" <<< "$after"`, or a `[[ $'\n'"$after"$'\n' == *$'\n'"$rec"$'\n'* ]]` test. Add bats cases for (a) ~400 standard worktrees → note, and (b) >128 KiB of W records plus one standard worktree → no note.

#### 2. The dotgit record lookup is O(n²) in the number of added worktrees

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:874-879` (inside the per-record loop at `:832-895`)
**Move:** Count the hidden multiplications / Check the asymptotic behavior
**Classification:** Macro (O(n²), n = added worktrees) / Cold path (once per session exit; hostile-sized input possible)
**Confidence:** High
**Baseline:** Microbenchmark of just this loop (`perf/quad.sh`, 2026-09-28): 56 ms at n=50, 1,978 ms at n=300, 22,672 ms at n=1,000, 164,848 ms at n=3,000.

For each added `commondir-file` record, the loop walks every key of `left` (3n entries) to find the matching `+F dotgit` record, and does not stop at the first hit. At the realistic n ≤ 50 this is negligible. The cost overtakes the snapshot's own linear cost (~42 ms per worktree) at a few thousand worktrees. A hostile session can reach that range, although the snapshot at that size already takes minutes. Today finding 1 hides this above ~200–450 worktrees, because the function declines in ~20 ms before reaching the loop. Once finding 1 is fixed, the quadratic path becomes reachable. The same applies to line 897, but that loop is linear.

**Recommendation:** Before the main loop, index the `+F dotgit` records once, e.g. `dotgit["<path %q>"]="<record>"` built from `left` by cutting the third tab field. Then replace the inner loop with a single `${dotgit[$q]:-}` lookup. This makes the function O(n) with no change to what it accepts.

#### 3. A container-chosen back-pointer up to 64 MiB is read into a bash string before the path-length checks

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:861-879`
**Move:** Trace the memory lifecycle / Identify the serialization tax (parsing hostile input)
**Classification:** Macro (cost linear in file size, up to the 64 MiB cap) / Cold path (hostile-only)
**Confidence:** High
**Baseline:** `perf/biggitdir.sh` (2026-09-28): one worktree whose `P/gitdir` is a single line of 1 / 4 / 60 MiB → `scan_std_worktrees` takes 233 / 879 / 20,035 ms, then declines.

The `-f` check added in 5a6d689 closes the FIFO hang. A regular file up to `GIT_EXIT_SCAN_MAX_FILE_BYTES` is still read whole by `_snap_first_line`, which is not counted toward the 1 GiB total. The same line is then piped through `_snap_hash_str`, the file is hashed again, and the string goes through several glob matches and a `printf %q`. A real back-pointer is at most PATH_MAX + 1 bytes. Anything longer can only decline, and it does so at line 879, where no dotgit record can carry a path that long. The cost is bounded to one such file per scan, because the first decline returns. So this is roughly 20 s of added exit latency (or a Ctrl-C → exit 4), not unbounded.

**Recommendation:** Before reading, decline when `stat -c %s "$p/gitdir"` exceeds a small cap (e.g. 4097 bytes, or `getconf PATH_MAX` + 1). That makes this step constant-cost.

#### 4. The note path costs about one more "embedded repo" per added worktree, and the guide does not say so

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:832-895`; `guides/cc-isolated-usage.md:378-383`
**Move:** Count the hidden multiplications
**Classification:** Micro (process creations per worktree) / Cold path (once per session exit)
**Confidence:** Medium
**Baseline:** `perf/measure.sh 50` (2026-09-28): 1,749 ms for 50 added worktrees (≈35 ms each), against ≈42 ms per worktree for the exit snapshot itself.

Each added worktree costs roughly 20–30 process creations:
- three `$(printf '%q' …)` subshells
- `stat` plus a `sha256sum` subshell in each of three `_snap_file_is` calls
- one `find`
- `_snap_first_line`'s subshell and `stat`
- `_snap_hash_str`'s subshell, pipe and `sha256sum`, once or twice per `g`

For 50 agent worktrees left behind, this adds ~1.7 s to an exit scan that already pays ~2 s for those worktrees. That is acceptable, but it nearly doubles the per-worktree exit cost. The "A slow scan" paragraph quotes 29 ms per embedded repo and does not mention this extra cost.

**Recommendation:** Add one clause to "A slow scan" (e.g. "and about as much again for each worktree added in the session when the scan checks it for the note"). Optional: compute all expected hashes with one `sha256sum` call per worktree (or one per scan over a list of files) instead of per-string pipelines. Only worth doing if the measured cost matters at realistic n.

## Endorsements

- The new code only runs when the snapshots differ and `.git` is still valid. When `$before` equals `$after` and `$invalid` is empty, `git_exit_scan` returns 0 before calling `scan_std_worktrees`. [read: devcontainer-config/cc-exit-scan.sh:942-946]
- Any record difference outside the three worktree kinds rejects the note before any per-worktree process creation. The classification loop runs before the per-record loop. In the measured decline case (50 worktrees plus a planted hook), the added cost was 20 ms. [read: devcontainer-config/cc-exit-scan.sh:822-830]
- `_snap_wrel` creates a process only for a relative value; empty, absolute and `~/` values return from a `case` with no fork. Its cost on the common path is therefore proportional to the number of relative hooksPath, attributesFile and local-remote values. [read: devcontainer-config/cc-exit-scan.sh:287-291]
- `find -P "$p" -type l -print -quit` at line 857 walks at most what the exit snapshot already walked: `_snap_nested` finds `P/HEAD`, and `_snap_gitdir` then runs `find -type l` over all of P. That means a huge planted private dir has already cost a full traversal before this check. This depends on `looks_like_gitdir` accepting P, which I did not open. [unverified — submitted as claim]
- The hashes in `_snap_file_is` count toward a per-call `_snap_bytes` total (a local at line 804), so the 1 GiB hashing cap applies within `scan_std_worktrees` independently of the snapshot's own total. [read: devcontainer-config/cc-exit-scan.sh:181-195,779-785,804]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `printf \| grep -q` under pipefail: note fails past ~100 KB of snapshot; fixing line 812 alone makes the W refusal fail open | Medium | `cc-exit-scan.sh:807,812-813` (and `:939`) | High |
| 2 | O(n²) dotgit lookup over `left` per added worktree | Low | `cc-exit-scan.sh:874-879` | High |
| 3 | Back-pointer up to 64 MiB read whole (~20 s) before it can only decline | Low | `cc-exit-scan.sh:861-879` | High |
| 4 | ~35 ms per added worktree on the note path, not in the guide's cost note | Informational | `cc-exit-scan.sh:832-895`, `guides/cc-isolated-usage.md:378-383` | Medium |

## Overall Assessment

The change costs nothing on the common path (equal snapshots return first), and declining costs about 20 ms. At the realistic scale of 1–50 agent worktrees, the note path costs about 35 ms per worktree, about the same as the snapshot already pays for each. The most important item is finding 1, and it is a correctness issue that shows up with scale rather than a speed issue. Under the launcher's `pipefail`, both new `printf | grep -q` checks depend on snapshot size. The note silently stops appearing at a few hundred worktrees. Worse, the W refusal is protected only because the other grep fails first, so the obvious one-line fix would make it fail open. Fix both lines, and ideally line 939, together, and pin the behavior with a large-snapshot bats case. After that, finding 2's O(n²) lookup becomes reachable, and a one-pass index fixes it. Finding 3 is a small cap. The fixes stay within `scan_std_worktrees`; there is no structural problem. The pipefail behavior and the cutoff sizes were measured here, but the exact cutoff depends on timing and path lengths. A run with real `/workspace/.claude/worktrees/agent-*` layouts would tighten the "300–450 worktrees" estimate.

Out of my lane, for the security reviewer: `_snap_host_config` (`cc-exit-scan.sh:507-512`) follows a relative `core.hooksPath` or `core.attributesFile` from the user's global or system config without calling `_snap_wrel`. Such a value would resolve inside a newly added worktree without leaving a W record. [unverified — submitted as claim]

## Goal-Alignment Note

The PR's goal is to stop a false warning when a session leaves standard linked worktrees behind, without weakening the tripwire. At realistic scale it meets that goal cheaply: nothing is added on the common path, the decline is fast, and the note path costs about 1.7 s for 50 worktrees. Two measured scale effects work against the goal. (1) At a few hundred worktrees the note silently turns back into the false warning it was meant to remove, because of the pipefail and SIGPIPE behavior of `printf | grep -q`. (2) The W-record refusal, a safety condition this PR adds, holds at large snapshot sizes only because of that same bug, so the obvious fix for (1) would weaken the tripwire. Both lines need to be fixed together for the PR to meet both halves of its goal.
