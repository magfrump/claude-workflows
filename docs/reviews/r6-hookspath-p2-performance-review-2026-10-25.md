Commit: e1d7d912

# Performance Review — fix/exit-scan-r6-hookspath (R6 pass 2)

**Scope:** `git diff d40e4bae..HEAD` (cf15f4f9, e1d7d912); the performance-relevant code is `devcontainer-config/cc-exit-scan.sh` (`_snap_tree_hooks`, `_snap_entry_hooks`, the call in `git_exec_snapshot`) and the "A slow scan" text in `guides/cc-isolated-usage.md`
**Date:** 2026-10-25
**Based on:** `docs/reviews/r6-hookspath-p1-code-fact-check-report.md` (pass 1, written against cf15f4f9, so it predates e1d7d912's include change). Its Claim 18 (timing, "Mostly accurate") is the only performance verdict in it.

## Data Flow and Hot Paths

`git_exec_snapshot` runs twice per session: once at launch (the baseline) and once at exit. The exit run blocks the user's return to the shell, and its input is whatever the session wrote into the checkout. The path is cold in call frequency, but the session controls the size of its input. That is why this review treats it as a cold path that runs over large, adversarial data.

The new code adds this step for every `.git` entry the working-tree `find` returns (`:877-886`): `_snap_entry_hooks` → `gitdir_common` → `_snap_tree_hooks` on `<common>/config` and `<gitdir>/config.worktree`. These recurse through every `include.path` and `includeIf.*.path`. The dedup key is `t:<realpath>:<worktree>`, and the depth limit is 10.

Every visit to a file costs one `git config` fork, a `realpath` fork and an `$out` file pair. Every include edge costs a `realpath` fork plus two command substitutions (`_snap_path`, `dirname`), even when the target was already seen: the dedup check at `:663` comes after `realpath` at `:662`. Every relative `core.hooksPath` value calls `_snap_hooks "$wt/$val"`, which adds at least one record (a `printf %q` substitution) and runs `find` when the directory exists.

The relevant sizes are N, the number of `.git` entries; M, the number of distinct include files reachable from a common config; E, the number of include edges; and V, the number of relative hooksPath values. The session can make all four large by writing small files. The old `_snap_config` dedups globally (`c:<realpath>`, `:484`), so repository config cost was O(M + E) once. The new walk dedups per worktree, so its cost is O(N × (M + E + V)).

Measurement setup: a scratch harness ran the d40e4bae and HEAD copies of `cc-exit-scan.sh`/`cc-gitdir.sh` on the same freshly built tree. It used `GIT_CONFIG_NOSYSTEM=1`, an empty `GIT_CONFIG_GLOBAL`, git 2.39.5 and bash 5.2.15, on a 16-core WSL2 container with load average 0.4-0.9. Each configuration ran once (k=1), so treat the figures as indicative. Rows marked "shim" ran with a PATH shim that counts `git` invocations, which adds roughly 1 ms per git call. Harness: `/tmp/claude-1000/-workspace/89c2ddf7-2b6b-41d6-b07b-ae5871fb9429/scratchpad/2026-10-25-exit-scan-r6-hookspath/perf-p2/probe.sh` (with shim) and `probe-noshim.sh`.

| Scenario | N | M/E/V | old s | new s | old git calls | new git calls |
|---|---|---|---|---|---|---|
| 100 embedded repos (no shim, 2 runs) | 100 | 0 | 2.15 / 2.08 | 2.44 / 2.50 | — | — |
| 100 embedded repos (shim) | 100 | 0 | 2.45 | 2.73 | 302 | 402 |
| 1 config with M includes, N `.git` files → main git dir (shim) | 50 | M=50 | 1.01 | 12.67 | 102 | 2652 |
| same (shim) | 100 | M=100 | 2.03 | 52.32 | 202 | 10302 |
| same (no shim) | 100 | M=100 | 2.18 | 46.57 | — | — |
| E include lines naming one file (shim) | 100 | E=100 | 1.78 | 23.02 | 103 | 303 |
| V relative `core.hooksPath` values, dirs missing (shim) | 100 | V=100 | 1.31 (312 lines) | 5.99 (10312 lines) | 102 | 202 |
| Include DAG, 10 levels × 2 files, each including both of the next (2^10 paths) | 1 | 20 files | 0.38 | 0.50 | 23 | 44 |

## Findings

#### Per-entry include walk multiplies two session-controlled counts: N `.git` entries × (M include files + E include edges)

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:658-685`, `:693-697`, `:884-885`
**Move:** Count the hidden multiplications; Check the asymptotic behavior
**Classification:** Macro (O(N×(M+E)) where the old repository-config walk was O(N+M+E)) / Cold path that runs over adversarial data and blocks session exit (escalated from Low per the hot-path gate)
**Confidence:** High
**Legibility-target:** maintainer (the fix is in the scan), user (the guide's "A slow scan" bullet)
**Baseline:** 46.57 s per snapshot, against 2.18 s on the old scan, for N=100 `.git` files and M=100 one-line include files (no-shim harness run, 2026-10-25, harness above). That is about 4.4 ms per (entry, include file) pair. Edge-only case: 23.02 s against 1.78 s for N=100, E=100 (shim run), about 2.1 ms per (entry, edge) pair.

Evidence:

```
devcontainer-config/cc-exit-scan.sh:662-666
  real="$(realpath -m -- "$f" 2>/dev/null)" || real="$f"
  [ -z "${_snap_seen["t:$real:$wt"]:-}" ] || return 0
  _snap_seen["t:$real:$wt"]=1
  out="$_snap_tmp/t.${#_snap_seen[@]}"
  if ! (cd / && git --no-pager config --file "$f" --no-includes --null --list) > "$out" 2> "$out.err"; then
```
```
devcontainer-config/cc-exit-scan.sh:680-682
      include.path|includeif.*.path)
        # Any include, absolute or not: its relative hooksPath still resolves in <wt>.
        _snap_tree_hooks "$(_snap_path "$val" "$(dirname -- "$f")")" "$wt" $((depth + 1)) || return 1 ;;
```
```
devcontainer-config/cc-exit-scan.sh:885
      [ -z "$g" ] || _snap_entry_hooks "$g" "${f%/*}" || { rc=1; break; }
```

The dedup key includes `$wt`, so every `.git` entry rereads the whole include closure of its common config. N `.git` files can all name one git dir: `_snap_gitdir` dedups that git dir, so before this change each extra entry cost only its `_snap_dotgit` and `_snap_host_config` work. Measured cost now grows with N × M, about 4.4 ms per pair. There is a second multiplier the M count hides. `realpath`, `_snap_path` and `dirname` run on every edge before the seen check, so one config with E `include.path` lines naming a single file costs N × E fork groups even though only one extra file is ever parsed (measured: 200 extra git calls, but +21 s). A session can make the exit scan take minutes to hours with a few hundred to a few thousand tiny files. Extrapolating linearly from the measured 4.4 ms, N = M = 1000 is about 74 minutes per snapshot (speculative). The old code needed about 1,600 embedded repos at ~29 ms each for a 46 s scan. The new code needs 200 files.

This is an availability cost, not a false clean: Ctrl-C exits 4, which the guide says means unscanned. But the guide's sentence ("about 29 ms more for each embedded repository") no longer bounds the cost. The cost of an entry now depends on the include graph of the config it shares.

**Recommendation:** Cache what the config closure yields, not just which files were visited. Walk each common config's include closure once (key `t:<realpath>` with no `$wt`) and keep its list of relative `core.hooksPath` values. Then, for each entry, loop over that cached list and call `_snap_hooks "$wt/$val"`. That restores O(M+E) parsing plus O(N×V) hooks walks. Also move the seen check ahead of the `realpath` fork where possible (for example, a first-pass key on the unresolved path), so repeated edges stop costing forks. If a cache is out of scope for this PR, add a fail-closed pair cap for (entries × values) like `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS`, and add "and per include in a shared config" to the "A slow scan" bullet.

#### Every relative `core.hooksPath` value is walked in every worktree: N × V records and hooks walks

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:676-679`
**Move:** Ask "what's the size of N?"; Trace the memory lifecycle (`_snap` string growth)
**Classification:** Macro (O(N×V) records) / Cold path over adversarial data
**Confidence:** High
**Legibility-target:** maintainer
**Baseline:** 5.99 s and 10,312 snapshot lines, against 1.31 s and 312 lines on the old scan, for N=100 `.git` files and V=100 relative `core.hooksPath` values naming missing dirs (shim run, 2026-10-25, harness above).

Evidence:

```
devcontainer-config/cc-exit-scan.sh:676-679
      core.hookspath)
        # An absolute or ~/ value names one dir for every tree: _snap_config walks it.
        # shellcheck disable=SC2088  # matching a literal "~/" in the value
        case "$val" in /*|"~/"*) ;; *) _snap_hooks "$wt/$val" || return 1 ;; esac ;;
```

Git uses only the last `core.hooksPath` value. The scan walks every value, as `_snap_config` already did once. Here that over-walk is multiplied by N. Each pair adds at least one `F` record through a `printf %q` command substitution (about 0.5 ms measured). When the directory exists, each pair also runs a `find` and stats and hashes every hook in it. The `h:<realpath>` dedup does not help, because each `$wt/$val` is a different directory. The snapshot text (a bash string built with `+=`, then `sort -u`, then kept as the baseline) grows with N×V. This is cheaper per pair than the first finding, and the cache recommended there bounds it no further, so it stands on its own.

**Recommendation:** Cover it with the same pair cap as the first finding. If walking only the last value is considered precise enough, walk only the last relative value per config closure: git's last-one-wins applies across the whole closure in read order, so this needs care. Otherwise accept and document it.

#### The guide's timing statement holds for plain embedded repos, but the "no measurable change" conclusion did not reproduce on a quieter host

**Severity:** Informational
**Location:** `guides/cc-isolated-usage.md:439-446`; `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:126-129`
**Move:** Find the work that moved to the wrong place (a per-entry step added)
**Classification:** Micro (one extra `git config` plus `realpath`, `gitdir_common` and substitutions per entry) / Cold path
**Confidence:** Medium (k=1 per configuration, two runs for the plain case)
**Legibility-target:** user, reviewer
**Baseline:** 100 plain embedded repos, no shim: old 2.15 s / 2.08 s, new 2.44 s / 2.50 s (2026-10-25, harness above), about +2.9 to +4.2 ms per entry on top of about 21 ms.

Evidence:

```
guides/cc-isolated-usage.md:439-441
- **A slow scan.** The cost is forks per git dir, not I/O: about 2–4 s per
  snapshot on a ~400k-file repository, and about 29 ms more for each embedded
  repository (the tree walk itself is ~0.05 s per 100k files), paid at launch
```

On a load-0.4 host the added cost is measurable: about 14-20% per plain embedded repo. Pass 1 recorded a median that went down (4.1 s to 3.7 s), but on a noisy container. The guide's "about 29 ms" stays roughly right as an order of magnitude (about 25 ms measured here). What it no longer describes is the linked-worktree and include case in the first finding.

**Recommendation:** Change the research doc's "noise" line to "about +3-4 ms per plain entry (about 15%)". Change the guide only together with the first finding.

## Endorsements

- The include recursion cannot blow up exponentially on a DAG: each (file, worktree) pair is marked before recursing, so a diamond-shaped include graph reads each distinct file once per worktree. I measured this: 10 levels × 2 files (2^10 paths) cost 21 extra `git config` calls for one entry. `[read: devcontainer-config/cc-exit-scan.sh:660-666]`
- An include naming a missing file returns at the `-f` test before any fork, so dangling include lines cost only builtins. `[read: devcontainer-config/cc-exit-scan.sh:661]`
- A `commondir` that `gitdir_common` cannot read safely is size-checked (≤4096 bytes) before it is read, so the new per-entry reader adds no unbounded read. `[read: devcontainer-config/cc-gitdir.sh:55-69]`

## Summary Table

| # | Finding | Severity | Location | Confidence | Measured |
|---|---------|----------|----------|------------|----------|
| 1 | Per-entry include walk: N × (M + E) forks | Medium | `cc-exit-scan.sh:658-685, 693-697, 885` | High | Yes (46.6 s vs 2.2 s at N=M=100; 23.0 s vs 1.8 s at N=E=100) |
| 2 | N × V hooksPath records and walks | Low | `cc-exit-scan.sh:676-679` | High | Yes (6.0 s / 10,312 lines vs 1.3 s / 312) |
| 3 | Guide timing holds for plain repos; "noise" claim not reproduced | Informational | `guides/cc-isolated-usage.md:439-446` | Medium | Yes (+3-4 ms per entry) |

## Overall Assessment

For the realistic case (a handful of agent worktrees, and a husky config with zero or one include), the change costs a few milliseconds per `.git` entry and is fine. The structural issue is finding 1. Dedup per (file, worktree) turns the old one-time repository-config walk into a product of two counts the session controls. Two hundred tiny files make the exit scan take about 46 s, and the guide's per-repo figure no longer bounds the cost. The failure mode is the availability one already accepted (Ctrl-C, exit 4, never a false clean), so this does not block merge on correctness. But the amplification is new and undocumented. The fix belongs in this code: cache each closure's relative hooksPath values once, then apply them per worktree, or cap the pairs and fail closed. If neither lands, the guide should name the multiplier. No further profiling is needed to confirm the shape. The extrapolated hour-scale figures are linear projections from the measured per-pair cost.

**Cross-domain note (not a performance finding, unverified, for security-reviewer):** the depth check (`:660`) runs before the seen check (`:663`), and the seen mark is not tied to depth. Suppose a file is first reached at depth 10 through an `includeIf` chain git would not take. Its own includes are cut off at depth 11, and a later shallower route to it (one git does take) is skipped as seen. A relative hooksPath one level further down would then go unwalked in that worktree. `_snap_config` has no such interaction because it has no depth limit.

## Goal-Alignment Note

The PR's goal is to close R6 (a relative repo `core.hooksPath` walked in every linked worktree and `.git` entry) without making the scan materially slower or less available. The coverage goal is met by the design, and the realistic-case cost is small (finding 3). The availability side is only partly aligned. The brief's framing ("a session can plant many `.git` entries or include chains to stall the scan") and override-log row 134's accepted limit describe linear growth at ~29 ms per repo. This change adds a multiplicative route (finding 1) that the documented limit does not describe, so accepting row 134 does not cover it. The low-cost way to align it is to cache each closure's values, or failing that, a cap plus one guide sentence. Neither requires reopening the coverage design.
