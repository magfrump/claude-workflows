Commit: 5fadfc2

# Performance Review — q094-exit-scan-worktree-layout (review-fix loop pass 2)

**Scope:** `git diff 5a6d689..HEAD` (devcontainer-config/cc-exit-scan.sh, cc-isolated.sh header, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, plan doc). Pass 1 (`dfe4c0d..5a6d689`, report `docs/reviews/performance-review-2026-09-28-q094.md`) is context only.
**Date:** 2026-09-28
**Based on:** code reading plus scratch measurements (session scratchpad `perf2/`: `glob.sh`, `mem.sh`, `quad2.sh`, `measure.sh`, `wbypass.sh`, `biggitdir.sh`; bash 5.2.15, same machine as pass 1, 2026-09-28). No fact-check report for this pass.

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

Nothing moved. `git_exit_scan` runs once per cc-isolated session, after claude exits, on the user's terminal. **Path temperature: cold** (once per session), but it blocks the terminal and a hostile session picks the input sizes. The one check that runs on the common path (equal snapshots) is the `invalid` test at `cc-exit-scan.sh:926-927`. It is now an in-bash `=~` instead of `printf | grep -q`. `scan_std_worktrees` runs only when the snapshots differ and `.git` is valid.

What this pass changed, performance-wise:
- **Whole-snapshot checks** (`:812`, `:818`, `:926-927`) are now bash pattern or regex matches over the snapshot string. There is no pipeline, so there is no SIGPIPE.
- **The dotgit lookup** is indexed once (`dot[...]` at `:830`, used at `:873`), replacing a walk over `left` for each worktree.
- **The back-pointer** gets a 4097-byte size cap (`:860`) before `_snap_first_line` reads it.
- **Removal acceptance is gone.** The final pass over `left` (`:891`) is a linear "every record used" check.

### Measurements

**1. Whole-string checks on synthetic snapshots** (`glob.sh`; ~200-byte F records, worst case = no match, so a full scan):

| snapshot | locale | W glob `:812` | commondir glob `:818` (absent / last) | `invalid` regex `:927` | ref: `grep -q <<<` | ref: `[ "$a" != "$b" ]` |
|---|---|---|---|---|---|---|
| 1 MiB | C | 13 ms | 14 / 12 ms | 10 ms | 14 ms | 16 ms |
| 5 MiB | C | 63 ms | 64 / 57 ms | 50 ms | 75 ms | 77 ms |
| 20 MiB | C | 253 ms | 254 / 244 ms | 200 ms | 311 ms | 416 ms |
| 5 MiB | C.UTF-8 | 65 ms | 71 / 70 ms | 75 ms | 70 ms | 115 ms |
| 5 MiB + one non-ASCII path | C.UTF-8 | 89 ms | 71 / 78 ms | 62 ms | 76 ms | 100 ms |
| 20 MiB + one non-ASCII path | C.UTF-8 | 353 ms | 352 / 366 ms | 312 ms | 309 ms | 716 ms |

The cost is linear, about 12–18 ms per MiB. It is no slower than a here-string `grep`, and cheaper than the `before != after` compare the caller already does. The leading `*` does not go quadratic. For the literal-then-`*` shape, bash's matcher tries each start offset and then either fails within the quoted literal or finds a trailing `*`, which matches at once. The literal is quoted, so the `%q` path characters in it cannot act as glob metacharacters.

Peak RSS (`mem.sh`, 20 MiB string): the W glob raised VmHWM from 85 MB to 146 MB (C) and from 146 MB to 187 MB (C.UTF-8 with one non-ASCII byte). The `=~` added nothing. This is a transient copy, linear in snapshot size.

Realistic snapshot sizes are far below these: 140 KB for 300 worktrees in pass 1. At that size these checks cost about 2 ms in total.

**2. `scan_std_worktrees` over N added standard worktrees** (`measure.sh`), compared with pass 1:

| N | exit snapshot | scan_std_worktrees (pass 2) | per worktree | result | pass 1 |
|---|---|---|---|---|---|
| 50 | 1,842 ms | 1,646 ms | 33 ms | note | 1,749 ms, note |
| 100 | 3,806 ms | 2,691 ms | 27 ms | note | — |
| 200 | 7,649 ms | 6,019 ms | 30 ms | note | 14,174 ms, note |
| 300 | 11,842 ms | 9,412 ms | 31 ms | note | 18–20 ms, **wrong decline** |
| 600 | 25,693 ms | 21,540 ms | 36 ms | note | 18 ms, **wrong decline** |
| 50 + one planted hook | 2,151 ms | 13 ms | — | declines (correct) | 20 ms |

**3. Bookkeeping alone** (`quad2.sh`; the `left`/`dot`/`used` fill, the per-record lookups and the final used-check, with no forks and no disk access):

| N | fill | loop | pass 1 lookup loop |
|---|---|---|---|
| 1,000 | 26 ms | 72 ms | 22,672 ms |
| 3,000 | 95 ms | 207 ms | 164,848 ms |
| 30,000 | 949 ms | 2,297 ms | — |

The O(n²) is gone. The loop now grows linearly (×10 N gives ×11 time). What is left per worktree is the ~30 process creations noted in pass 1 finding 4, and the guide now documents that cost ("tens of milliseconds", `guides/cc-isolated-usage.md:384-385`). The in-memory part is about 0.1 ms per worktree, so the forks account for about 99% of the cost.

**4. Safety conditions that pass 1 tied to scale** (re-run on the new code):
- `wbypass.sh 3000`: a relative `core.hooksPath` plus 3,000 relative remotes (185,011 bytes of W records) and one standard worktree. The W refusal holds 3/3 (rc=1). The fail-open pass 1 predicted for a one-line fix does not occur: both lines were fixed together.
- `biggitdir.sh 60`: a 60 MiB single-line `P/gitdir`. The scan declines in 23 ms, down from 20,035 ms in pass 1.

### Pass 1 findings

| Pass 1 # | Finding | Status at 5fadfc2 |
|---|---|---|
| 1 | `printf \| grep -q` under pipefail (note lost past ~100 KB; one-line fix fails open) | **Resolved.** Both checks, plus the pre-existing `:939`, are now pipe-free. Note held at 300 and 600 worktrees, W refusal held at 185 KB of W records. The bats case (40k padding records, both directions) pins this. |
| 2 | O(n²) dotgit lookup | **Resolved.** 207 ms at N=3,000 (was 164,848 ms) |
| 3 | 64 MiB back-pointer read whole | **Resolved.** 23 ms at 60 MiB (was 20,035 ms) |
| 4 | ~35 ms per worktree undocumented | **Resolved.** Guide sentence added. Measured 27–36 ms per worktree. |

## Findings

No findings.

## Endorsements

- The dotgit index is built in the same single pass that classifies the diff lines, and each worktree then does one subscript lookup. No loop over `left` remains inside the per-worktree loop. [read: devcontainer-config/cc-exit-scan.sh:826-834,873]
- The back-pointer cap runs before any read. A regular non-link file is checked at `:859`, then `stat -c %s` at `:860`, and only then `_snap_first_line` at `:861`. When `stat` fails, the check falls back to 99999, so it declines rather than reads. [read: devcontainer-config/cc-exit-scan.sh:859-861]
- Claim for fact-check: the three whole-snapshot checks (`:812`, `:818`, `:927`) scale linearly with snapshot size, at about 12–18 ms per MiB, up to 20 MiB in C and C.UTF-8 (including a non-ASCII path), with no quadratic case. Measured here with `perf2/glob.sh`. [unverified — submitted as claim]
- Claim for fact-check: `scan_std_worktrees` now returns 0 (note) for 300 and 600 standard worktrees and 1 for a 185 KB block of W records, run under the launcher's own `set -euo pipefail` (sourced `cc-isolated.sh`). Measured with `perf2/measure.sh` and `perf2/wbypass.sh`. [unverified — submitted as claim]
- `_snap_worktree_of` now tests `[ -f "$1" ]` before forking `git config --file`, which drops one process creation for each non-file candidate on the snapshot path. [read: devcontainer-config/cc-exit-scan.sh:323-333]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

All four pass 1 items are fixed, and I measured each one against the pass 1 numbers. The whole-snapshot pattern matches are linear, cost about 12–18 ms per MiB (the same as a here-string grep), and do not show the leading-`*` blow-up the brief asked about, up to 20 MiB and in a UTF-8 locale with non-ASCII input. Their only extra cost is a transient copy of the snapshot, about 40–60 MB of peak RSS at 20 MiB. At realistic sizes (hundreds of KB) that is noise. The quadratic lookup is gone: the in-memory bookkeeping is about 0.1 ms per worktree at up to 30,000. The note path now costs about 30 ms per worktree, almost all of it process creation, and scales linearly: 21.5 s at 600 worktrees, against 25.7 s for the exit snapshot itself. The oversized back-pointer is capped at constant cost. I see nothing further to fix for performance. If per-worktree cost ever matters (hundreds of agent worktrees per session), the lever is batching the `printf %q` and `sha256sum` subshells, not the algorithm.

## Goal-Alignment Note

The PR's goal is to stop a false warning when a session leaves standard linked worktrees behind, without weakening the tripwire. In pass 1, both halves of that goal depended on snapshot size: the note vanished at a few hundred worktrees, and the W refusal held only by accident. At 5fadfc2 both halves hold regardless of size. The note printed for 300 and 600 worktrees. The W refusal held against 185 KB of W records. The cost stays proportional: nothing is added to the common path beyond a linear in-bash match, a decline takes about 13 ms, and the note path costs about the same per worktree as the snapshot already pays. Removing removal acceptance from this unit narrows what earns the note, and it costs nothing in performance.
