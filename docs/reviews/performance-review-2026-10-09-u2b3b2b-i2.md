Commit: 39f64d62

# Performance Review: feat/build-loop-u2b3b2b (U2b3b2b, outside seeds), iteration 2

**Scope:** `git diff 1c820663..39f64d62` (the iteration-1 fix commit), mainly `scripts/lib/dev-cycle-read.sh`: `outside_proj`, `root_starts`, `outside_seeds`, and the seed loops in `imported_names` and `main_imports`
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2b-i2/shared.md`; iteration-1 report `performance-review-2026-10-09-u2b3b2b.md`; iteration-1 rubric. No iteration-2 fact-check report was available, so this review rests on reading the code and on read-only measurements against /workspace.

> **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Measurement setup (read-only)

The setup matches iteration 1:
- Run from `/workspace/.claude/wt-build-loop-u2b3b2b` with `resolve_main; reader_settings; ROOT_REAL=$(pwd -P)` and `LC_ALL=C`, using the real `HOME=/home/node`.
- Timed with `EPOCHREALTIME`. Load average was 0.6–0.75 on 16 CPUs and the cache was warm.
- The probes are `u2b3b2b-perf2-probe{1,2,3}.sh` in the session scratchpad. Their temp dirs carry the prefix `/tmp/u2b3b2b-perf2-` and were removed.
- `import_readers` gave 15 roots and 2 homes. `git worktree list` shows 8 worktrees. C1 lists 6 roots present here with one `find` (`/workspace`).

| Measure | 1c820663 (i1 lib) | 39f64d62 (fix) |
|---|---|---|
| `imported_names` wall | 6289 ms (i1 report: 7356, 7793) | 2821 ms, 2943 ms |
| `main_imports` wall | 6212 ms (i1 report: 6734) | 3335 ms, 3421 ms |
| names (sorted, unique, no `//`) | 1177 tree / 1177 main | 1177 / 1177, byte-identical to 1c820663 |
| seeds | 143 (85 `f`, 58 `p`) | 85 (41 `f`, 44 `p`), 41 under /workspace |
| files read by the tree walk | 230 | 172 (45 repo, 44 `~/.claude`, 42 `/opt`, 41 `/workspace` absolute) |
| summed `import_file` time | 3004 ms | 1519 ms |
| `outside_seeds` | 1924 ms | 528 ms, 525 ms |

Where `outside_seeds`' 528 ms goes now:
- **`root_starts /workspace`: 447 ms.** It returns 396 names, of which 351 remain after the ROOT_REAL drop. This is almost all `find`.
- **The innermost-root loop: 8 ms.**
- **`lower_all`: 4 ms.**
- **C1 `xargs grep`: 5 ms**, with 67 hits.
- **The isstart, @ and rawfile loop: 109 ms.** `rawfile` alone accounts for 64 ms over 67 calls.
- **The config phase: under 80 ms**, including its `xargs grep` and `realpath -mz`.

## Verification of iteration-1 findings

- **F1 (Medium): fixed in large part.** The `@` filter (`:1287-1291`, `:1308-1311`) cut the seeds from 143 to 85 and the files read from 230 to 172. Walks fell from 6.3–7.4 s to 2.8–3.4 s, and both name lists are unchanged. My recommendation's first half asked to also drop an `@`-free seed whose real path lies below no reader root. That half was not taken, and its second half (short-circuit `@`-free reads in `import_outside`) was not taken either. The remaining cost is finding N1.
- **F2 (Low): fixed.** `root_starts` (`:1211`) pipes `find -P` through `instruction_names`. `lower_all` and `isstart` now run over 351 names, not 24,663, and `isstart` stays the authority (`:1311`). Those two stages now cost 4 ms and well under 109 ms, against 394 ms and 683 ms before.
- **F3 (Low): fixed.** The guard at `:1199` skips the process substitution when the output holds no `//` line. Its pattern `*$'\n'//*` matches a `//` name on any line after the first, and `//*` matches one on the first.
- **F4 (Informational): the `E2BIG` part is fixed.** `sha1sum` and both greps now run under `xargs -0r -a <(...)` (`:1288`, `:1308`, `:1317`). The other parts needed no action.
- **Header cost line (`:759-761`): confirmed.** It reads "over this repository's 8 registered worktrees, about 85 seeds and 3 to 3.5 s per walk, against 0.6 s without". I measured 85 seeds, 2.8–3.4 s and 8 worktrees.

## Data Flow and Hot Paths

Nothing changed from iteration 1:
- Both walks are cold CLI gate paths, memoized per decision.
- `floor` pays one main walk per self-merge brief per `--check`. `--check-fix` pays one tree walk per process.
- `outside_seeds` runs once per walk.

The fix commit adds the following, all inside `outside_seeds` once per walk except the last:
- two `xargs`/`sh`/`grep` pipelines;
- one `realpath -mz` over the config seeds;
- a bash loop over each C1 candidate and each C1 root;
- a `rawfile` (one `realpath` fork) per C1 candidate that holds an `@` and is not a link;
- one `lower` fork per prompt seed, inside each walk's seed loop.

## Findings

#### N1. The `@`-free seeds reached through the `~/.claude/skills` link are still read twice each and yield no name: about 0.8 s per walk

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1291` (the config-seed keep rule), `:1169-1176` (`import_outside`, the second read under the real path)
**Move:** Count the hidden multiplications
**Classification:** Macro (cost grows with the number of `@`-free `.md` files under a linked config dir) / Cold path (one walk per gate decision, multiplied by briefs per `--check`)
**Confidence:** High for the measurement; Medium for the claim that dropping them is name-neutral (tested on this repository only)
**Baseline:** 844–875 ms over three runs to read the 35 `@`-free seeds under their link spelling and again at their real path, with `outside_proj` and `lower`, against a tree walk of 2821–2943 ms. Measured 2026-10-09, probe `u2b3b2b-perf2-probe3.sh`.
**Legibility-target:** the `outside_seeds` comment sentence "Only a seed holding an @ byte or reached through a link ... can yield a name, so the rest are dropped"

**Evidence:**
- Keep rule: `for i in "${!cx[@]}"; do [[ -z "${os_at[${cx[i]}]+set}" && "${rl[i]}" == "${cx[i]}" ]] || os_a+=("${kx[i]}${cx[i]}"); done`
- Probe: `@-free seeds: 35` with real paths `31 /opt/claude-workflows/skills`, `3 /opt/claude-workflows/skills/code-review` and `1 /opt/claude-workflows/skills/ui-visual-review`.
- Probe 2: wrapping `outside_seeds` to drop `@`-free seeds whose real path lies below no reader root kept `50 of 85`. Both walks gave `names=1177`, the same as the unfiltered fix (`tree names new==drop`, `main names new==drop`).

Every `@`-free seed that survives here does so only because its path differs from its real path: the user's `~/.claude/skills` is a link into `/opt/claude-workflows/skills`. For each one, the walk pays:
- a read under the link spelling, whose only output is the `//opt/...` projection;
- a second read of the `/opt` file, which also holds no `@` and yields nothing.

The only name either read adds is the lower-cased `//` line. The walk header says such a line "no repo path isimported asks for can match". When the real path lies below no reader root, that is about 30% of the walk's file reads (70 of 172) and roughly 0.8 s of its 2.8–3.4 s. The cost still grows with no bound as the number of `.md` files grows in a linked skills tree or plugin version, as iteration-1 F1 described. One case is different: when the real path lies below a reader root, the projection becomes a repo path, so that seed must be kept. The keep rule's link exception is right for that case and too broad for the `/opt` case.

**Recommendation:** Narrow the keep rule (`:1291`) to `@`-free seeds whose real path (`rl[i]`, already computed) lies below a reader root, with the same prefix loop as the ancestor test. Drop the rest. This keeps the superset (re-verify `names` are unchanged) and needs no new fork. Optionally extend it to imported `@`-free files with iteration-1's `import_outside` short-circuit. Otherwise, record the residual in the override log, since this is a cold path and 3 s is acceptable.

#### N2. `rawfile` forks `realpath` per C1 candidate, and `lower` forks per prompt seed in both walks' seed loops

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1314` (calls `rawfile`, defined at `:160`), `:1432` and `:1513` (`pdir[$p]="$(lower "$p")" || return 1`)
**Move:** Count the hidden multiplications
**Classification:** Micro / Cold path
**Confidence:** High
**Baseline:** `rawfile` costs 64 ms per walk over 67 calls, of which 30 are true. `lower` costs 53 ms per walk over 44 prompt seeds. Measured 2026-10-09, probe `u2b3b2b-perf2-probe1.sh`.
**Legibility-target:** none needed

**Evidence:**
- `if [[ ! -L "${cx[i]}" ]] && rawfile "${ir[i]}" && outside_ok "${cx[i]}"; then sp+=(...)`
- `rawfile() { local r; [[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }`
- `seen[$p]=1; tq+=("$p"); [[ "$f" != p* ]] || pdir[$p]="$(lower "$p")" || return 1`

Both costs are linear in the seed count and add about 0.1 s per walk. They become worth doing only if the seed count grows by an order of magnitude. The fix is the lib's usual pattern: one `realpath -ez` over the candidate list in place of the fork per call, and one `lower_all` over the prompt seeds. On error handling, `return 1` in both seed loops leaves `IMPORTED=error` (`:1418`) or `IMPORTED_MAIN=error` (`:1475`), which was set before the loop. That is correct fail-closed state, not a performance matter.

**Recommendation:** None now. Batch both only if the seed count grows.

#### N3. `root_starts` keeps the full `find -P /workspace` traversal (about 0.45 s per walk), which is now `outside_seeds`' dominant term

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1211`, called at `:1300`
**Move:** What's the size of N?
**Classification:** Macro (linear in the entries under the other roots, including untracked clones) / Cold path
**Confidence:** High
**Baseline:** `root_starts /workspace` took 447 ms, out of 528 ms for `outside_seeds`. Measured 2026-10-09, probe `u2b3b2b-perf2-probe1.sh`. Iteration 1 measured about 410k entries walked, 381k of them under `/workspace/external`.
**Legibility-target:** none needed

**Evidence:**
- `root_starts() { local -; set -o pipefail; find -P "$1" -name .git -prune -o '(' -type f -o -type l ')' -iname '*.md' -print0 | instruction_names; }`

The traversal is inherent to C1's "tracked or not" superset. The fix correctly moved the per-name bash work after `instruction_names`, so the rest of C1 is now about 0.13 s. Each further root outside an already-listed one adds its own traversal, and so does a root below ROOT_REAL, which the comment at `:1297` says is listed by itself. Pushing the name filter into `find` (`-iname` alternatives) saved little in iteration 1's probe, because the cost is directory traversal, not output.

**Recommendation:** None.

## Endorsements

- The C1 innermost-root loop is O(candidates × roots) in pure bash with no fork. It cost 8 ms for 351 candidates × 6 roots. [read: scripts/lib/dev-cycle-read.sh:1306]
- Both `@` filters run as one `xargs`-batched `grep -l` per phase (5 ms for the C1 phase), with no fork per file, and `-l` stops reading a file at its first `@`. [read: scripts/lib/dev-cycle-read.sh:1288, 1308]
- The `outside_proj` guard skips the process substitution for output with no `//` name, and it matches a `//` name on the first line as well as on any later one. [read: scripts/lib/dev-cycle-read.sh:1199-1200]
- Claim for the fact-check: under the fix, both walks yield the same 1177 names as at 1c820663 over this repository, in about half the time. [unverified — submitted as claim] (measured by probe 2, not by an execution verdict from the fact-check)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| N1 | 35 `@`-free link seeds (real path under `/opt`, below no root) still cost two reads each, about 0.8 s per walk, and add no name | Low | `scripts/lib/dev-cycle-read.sh:1291`, `:1169-1176` | High (measurement) / Medium (name-neutral) |
| N2 | `rawfile` and `lower` fork per C1 candidate and per prompt seed (about 0.1 s per walk) | Informational | `scripts/lib/dev-cycle-read.sh:1314`, `:160`, `:1432`, `:1513` | High |
| N3 | `find -P /workspace` (0.45 s) is now `outside_seeds`' dominant, inherent term | Informational | `scripts/lib/dev-cycle-read.sh:1211`, `:1300` | High |

## Overall Assessment

The fix commit does what iteration 1 asked for in the main:
- Walks fell from 6.3–7.4 s to 2.8–3.4 s.
- `outside_seeds` fell from 1.9 s to 0.53 s.
- The name lists are byte-identical (1177 and 1177).
- The `E2BIG` cliff is gone.
- The header's cost line is accurate.

The new pieces add no measurable cost: the `xargs` grep batches take 5 ms, the innermost-root loop 8 ms, and the per-seed `lower` and `rawfile` forks about 0.1 s together.

One residual remains (N1): the link exception in the `@` filter is broader than it needs to be. It keeps 35 `@`-free skills files whose real path lies below no root, which costs about 0.8 s per walk and still grows with the size of a linked skills tree. The fix stays in place, using values already computed at `:1290`. Nothing needs profiling beyond re-running probe 2 after any change.

## Goal-Alignment Note

The goal is to land U2b3b2b after a clean review-fix loop. Nothing here blocks it:
- **N1 (Low)** can take one more line in this unit, or go to the override log as a cold-path residual, alongside the per-walk recompute row.
- **N2 and N3** need no action.

All my probes read only, against the real repo and `HOME`, and ran under `timeout`. They left no processes behind, and their temp dirs (`/tmp/u2b3b2b-perf2-*`) were removed. I wrote no repo file other than this report. Claim 2 of the brief, a grep read error on a readable file accepted as status 2, is a fail-open question for security and the fact-check. I did not probe it.
