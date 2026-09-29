Commit: 9075003

# Performance Review — Q-094 unit A (`q094-exit-scan-worktree-layout`, dfe4c0d..9075003)

**Scope:** `devcontainer-config/cc-exit-scan.sh` (scan_std_worktrees, _snap_file_is, _snap_hash_str, _snap_wrel, git_exit_scan changes), `devcontainer-config/cc-isolated.sh` (help text only); tests and docs read for context. `docs/reviews/` excluded.
**Date:** 2026-09-28
**Based on:** Stage-1 merged fact-check summary (`scratchpad/A-fc-summary.md`, k=3, 0 behavioral Incorrect, 169/169 tests pass), plus measurements taken in this review.
**Measurement environment:** `git archive` of 9075003 in `scratchpad/crA-perf-19078`, git 2.39.5, bash, WSL2 kernel 6.18, 16 cores, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`. Harness scripts: `scratchpad/crA-bench.sh` (N worktrees), `scratchpad/crA-bench3.sh` (padded snapshots).

## Data Flow and Hot Paths

`git_exit_scan` runs **once per session**, on the host, after `devcontainer exec … claude` returns (`cc-isolated.sh:741-745`). The user's terminal waits for it; Ctrl-C during it becomes exit 4 (`scan_interrupted`). The container is **still running** at that point: the launcher does not stop it before scanning. Path temperature is **cold** (once per session), but it blocks an interactive return, so wall time matters somewhat.

The new code runs only when the launch and exit snapshots differ and `gitdir-valid` is not `invalid`. In order, `scan_std_worktrees`:
1. rejects on any `W` record (one bash glob over `$after`);
2. re-derives the git dirs (`scan_git_dirs`: 2 `cd && pwd -P` subshells plus a first-line read);
3. computes the record-level diff with one `awk` pass that builds hash sets (O(records));
4. classifies each diff line in bash, rejecting the first one that is not a dotgit, commondir-file or hooksdir record (no subprocesses);
5. runs one loop iteration **per added worktree**, where all the subprocess cost sits;
6. runs one `printf | sort | tr` pipeline for the note.

N = worktrees **added during this session**. Worktrees that already existed are in both snapshots and never reach step 5. Realistic N is the number of agent worktrees one session creates: usually 1–20, 200 as a deliberate stress case.

Snapshot sizes: step 3 and the two pattern matches scale with the number of snapshot records. The bats test uses 40,000 padding records, and I measured up to 2.55 MB snapshots (below).

### Measurements (this review, 2026-09-28)

| N added worktrees | exit snapshot (pre-existing) | `scan_std_worktrees` | full `git_exit_scan` | `scan_diff` (the old warn path's render) |
|---|---|---|---|---|
| 1   | 90 ms    | 42 ms    | 140 ms   | — |
| 20  | 1,201 ms | 749 ms   | 1,934 ms | 5 ms |
| 100 | 4,989 ms | 4,111 ms | 9,207 ms | 6 ms |
| 200 | 9,432 ms | 7,862 ms | 18,857 ms | 8 ms |

Cost per added worktree is about 37–41 ms and grows linearly. A first run of the same harness showed 10,036 ms at N=200. WSL fork timing is noisy (±25% run to run).

| padding records (bytes) | locale | `scan_std_worktrees` (1 worktree) | `gitdir-valid` regex | `commondir` glob |
|---|---|---|---|---|
| 1,000 (64 KB)    | C       | 53 ms  | 2 ms  | 1 ms |
| 10,000 (631 KB)  | C       | 120 ms | 8 ms  | 8 ms |
| 40,000 (2.55 MB) | C       | 414 ms | 22 ms | 27 ms |
| 40,000 (2.55 MB) | C.UTF-8 | 457 ms | 68 ms | 36 ms |

Idiom cost on this host: `q="$(printf %q …)"` 624 µs; `printf -v q %q …` 13 µs; `_snap_hash_str`-shaped `$(printf %s x | sha256sum)` 2,725 µs.

## Findings

#### 1. Per-worktree subprocess fan-out makes the note path cost about as much as the snapshot itself

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:839-890` (per-worktree loop of `scan_std_worktrees`), with callees `_snap_hash_str` (:777-781), `_snap_file_is` (:785-791), `_snap_size_ok` (:184-198), `_snap_hash` (:167-174), `_snap_first_line` (:205-215)
**Move:** 1 (count the hidden multiplications)
**Classification:** Micro (constant per-worktree fork/exec overhead) / Cold path (once per session exit, but it blocks the interactive terminal)
**Confidence:** High (measured)
**Legibility-target:** the maintainer of `cc-exit-scan.sh`, deciding whether many-worktree sessions justify batching
**Baseline:** `scan_std_worktrees` took 7,862 ms for N=200 added worktrees and 749 ms for N=20. Measured in this review on 2026-09-28 (git 2.39.5, WSL2, `scratchpad/crA-bench.sh`).

**Evidence (verbatim; the loop body continues to :890):**
```
    [ "$q" = "$(printf '%q' "$p/commondir")" ] || return 1
    ...
    hk="+F"$'\t'"hooksdir"$'\t'"$(printf '%q' "$p/hooks")"$'\t'"missing"
    ...
    _snap_file_is "$p/commondir" "$std" || return 1
    ...
    lnk="$(find -P "$p" -type l -print -quit 2>/dev/null)" && [ -z "$lnk" ] || return 1
    ...
    [ "$(stat -c %s -- "$p/gitdir" 2>/dev/null || echo 99999)" -le 4097 ] || return 1   # PATH_MAX + \n
    line="$(_snap_first_line "$p/gitdir" 2>/dev/null)" || return 1
    _snap_file_is "$p/gitdir" "$(_snap_hash_str "$line"$'\n')" || return 1
    ...
    dk="${dot["+F"$'\t'"dotgit"$'\t'"$(printf '%q' "$wt/.git")"]:-}"
    ...
    for g in "$p" ${ccommon:+"$ccommon/worktrees/$n"}; do
      h="$(_snap_hash_str "gitdir: $g"$'\n')"
      re="^file [0-7]+ $h\$"
      if [[ "$attrs" =~ $re ]] && _snap_file_is "$wt/.git" "$h"; then ok="$g"; break; fi
    done
```

I counted forks through the callees, all of which I opened. For a host-form worktree, one iteration does about 24 forks and 10 execs:
- 3 × `$(printf '%q' …)`;
- 3 × `_snap_file_is`, each one `stat` substitution plus one `$(_snap_hash)` wrapping a `$(sha256sum <)`;
- 2 × `_snap_hash_str`, each a substitution wrapping a `printf | sha256sum` pipeline;
- `find`, `stat`, and `_snap_first_line`, which runs its own `stat` substitution.

A container-form worktree adds about 8 more: a second `_snap_hash_str`, a possible second `_snap_file_is`, and a `cd && pwd -P` subshell.

At the measured idiom costs (0.6 ms per `printf` substitution, 2.7 ms per hash-string, about 2.5 ms per `stat`/`sha256sum` exec), that adds up to the observed 37–41 ms per worktree.

The code has no quadratic term: every loop over `left` is a single pass with O(1) associative lookups. It does change the wall-clock profile of the exit path, though. Before unit A, a worktree-only difference went to `scan_diff`, which took 5–8 ms at N=20–200. The accepted path now costs about 0.8× the exit snapshot, and a session that adds 200 worktrees waits 18.9 s instead of about 9.4 s.

At realistic N (1–20) the added wait is 42–749 ms, which is acceptable, so this is Low rather than Medium. None of it is on a per-request path.

**Recommendation:** Accept as is unless sessions that add dozens of worktrees become common. If they do, two cheap changes cover it:
- Replace `$(printf '%q' …)` with `printf -v` (measured 624 µs → 13 µs per call). This is a pure speed-up with the same bytes.
- Batch the per-file `stat -c %s` and `sha256sum` calls into one invocation each over all 3N candidate files (`P/commondir`, `P/gitdir`, `<wt>/.git`) before the loop.

Together these would bring the loop to roughly a constant number of execs plus bash work. Keep the `-f`/`! -L` guards in front of any batched read (see finding 2).

#### 2. The `-f`-then-read guards are check-then-use while the container is still running; a swap to a FIFO in that window blocks the scan until Ctrl-C

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:860-863` (`P/gitdir`), `:785-791` (`_snap_file_is`, used on `P/commondir` and `<wt>/.git`); launcher sequence `devcontainer-config/cc-isolated.sh:741-750`
**Move:** 7 (find the contention point: a shared writable resource during the scan)
**Classification:** Micro / Cold (one read per file per session exit)
**Confidence:** Medium (the window exists by reading; I did not try to win the race)
**Legibility-target:** the security reviewer and the author of the FIFO read guards (prior-loop fix)
**Baseline:** no baseline available — flagged as speculative

**Evidence (verbatim):**
```
    # Regular file first: a FIFO there would block the read.
    [ -f "$p/gitdir" ] && [ ! -L "$p/gitdir" ] || return 1
    [ "$(stat -c %s -- "$p/gitdir" 2>/dev/null || echo 99999)" -le 4097 ] || return 1   # PATH_MAX + \n
    line="$(_snap_first_line "$p/gitdir" 2>/dev/null)" || return 1
```
and in the launcher:
```
  devcontainer exec "${dc[@]}" claude || rc=$?
  ...
  trap scan_interrupted INT
  local scan=0
  git_exit_scan "$ws" "$git_before" "$lws" || scan=$?
```

`devcontainer exec` returning does not stop the container, so a process the session left behind can still write the bind-mounted checkout while the scan runs. The guards check the file type and then open it by path. A rename of a FIFO over `P/gitdir` or `<wt>/.git` between the check and `read -r`/`sha256sum <` would make the open block indefinitely.

The failure is availability only, and it fails closed: the user's Ctrl-C yields exit 4, "checked nothing", never 0. The snapshot's own reads (`_snap_file`, `_snap_first_line`) have the same pattern, so unit A adds instances of an existing class, not a new one. The fact-check notes "true at tip since c32a734" that the scan checks `-f` before every read.

**Recommendation:** No change needed for unit A. If this class is ever hardened, do it once for the snapshot and this check together, for example by opening with `O_NONBLOCK` through `timeout`, or by reading via `dd iflag=nonblock`. Hardening only the new call sites would leave the snapshot's identical window open.

## Endorsements (evidence-gated)

- On a mixed difference such as "worktree plus planted hook", the check declines in bash before the per-worktree loop: the `W` glob at :820 and the record-kind `case` at :828-834 `return 1` on the first non-worktree diff line, so finding 1's per-worktree cost is paid only when every diff line is a worktree-kind record. `[read: devcontainer-config/cc-exit-scan.sh:820-835]`
- The record diff is a single hash-set `awk` pass. Each loop over `left`/`used` at :828-892 is a single pass with associative-array lookups, and there is no loop over records nested inside the per-worktree loop, so the check is linear in snapshot records plus linear in N. `[read: devcontainer-config/cc-exit-scan.sh:825-892]`
- The hash of `"../..\n"` and the `%q` prefix are computed once, before the loop, not per worktree. `[read: devcontainer-config/cc-exit-scan.sh:837-838]`
- Claim: the per-worktree `find -P "$p" -type l -print -quit` walks a subset of what the exit snapshot has already walked (`_snap_gitdir` → `_snap_find "$list" "$real" -type l` over each git dir, including `P`), and it stops at the first link, so a large or hostile `P` cannot cost the check more than it already cost the snapshot. `[unverified — submitted as claim]`
- Replacing `printf | grep -q` with in-shell matches on large snapshots keeps the note and the `W` refusal correct under `pipefail`, and the cost stays linear in my padded runs: 40,000 records (2.55 MB) took 414 ms for the whole check under C and 457 ms under C.UTF-8. `[fact-check: Stage-1 summary — 169/169 tests pass, including "large snapshots under pipefail neither lose the note nor skip the W refusal" (execution)]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Per-worktree subprocess fan-out (~24 forks, ~10 execs): the note path costs about 0.8× the snapshot, 7.9 s at N=200 | Low | `cc-exit-scan.sh:839-890` | High |
| 2 | Check-then-read guards race a still-running container; a FIFO swap blocks the scan (fails closed via Ctrl-C to exit 4) | Informational | `cc-exit-scan.sh:860-863`, `:785-791`; `cc-isolated.sh:741-750` | Medium |

## Overall Assessment

Unit A is performance-sound for its setting: a once-per-session, cold, interactive exit path. Nothing is quadratic.
- **Snapshot size:** handled in linear time; 2.55 MB snapshots cost under 0.5 s whichever locale is set.
- **Declines:** mixed differences exit before any per-worktree subprocess.
- **Only measurable cost:** a constant of about 40 ms of fork/exec work per worktree added in the session. For typical sessions (1–20 worktrees) that adds 0.04–0.75 s to the exit wait. At 200 it roughly doubles the exit scan to about 19 s.

That is fixable in place: `printf -v`, plus batched `stat`/`sha256sum`. It is worth doing only if many-worktree sessions become common. The blocking-read race is an existing, fail-closed class shared with the snapshot and does not belong to this unit. No profiling beyond the measurements above is needed to merge.

## Goal-Alignment Note

The goal is to stop false-alarm warnings for agent worktrees without letting a sandboxed session make host git run something new unwarned. Nothing in the performance profile works against it:
- Every early return is a decline (`return 1` → the full warning). No time, size or error path turns into a pass.
- The added latency is bounded and linear in the number of worktrees the session itself created.
- The one resource hazard (a blocking read) fails closed to exit 4.

The recommended optimisations in finding 1 must keep that property. In particular, batching must keep the regular-file and no-link checks in front of every read.
