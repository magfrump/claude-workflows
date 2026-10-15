Commit: f2533b33

# Performance Review — Q-089 unit A1 (host-only tools get their own trust manifest)

**Scope:** `git diff 4ab9a51f f2533b33` (devcontainer-config/cc-isolated.sh, cc-exit-scan.sh, cc-gitdir.sh, install.sh; test/cc-isolated-functions.bats)
**Date:** 2026-10-14
**Based on:** the brief's summary of the prior advisory review `docs/reviews/performance-review-2026-10-14-q089a.md` (13.5 ms/call). That file is not in this worktree, in /workspace/docs/reviews, or in any other worktree under /workspace/.claude, so I could not read it. The 13.5 ms figure is the caller's, and I have not checked it.

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

The commit takes `cc-exit-scan.sh`, `cc-gitdir.sh` and `cc-push.sh` out of `enforcement_files()` and gives them their own manifest, `host-tools.sha256`. New runtime work:

- **Every invocation (source time):** one `verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh`. It costs one `readlink -f` fork, then for each file one `awk` over the 3-line manifest and one `sha256sum | cut` pipeline. Inside a repo checkout it returns early after the `readlink`.
- **launch / probe / register (main):** one more `verify_host_tools … cc-push.sh` for the warning. This sits ahead of the existing `check_manifest` (one batched `sha256sum` over the boundary files and claude-home) and then a container start, which is measured in seconds.
- **Host-tool refusal (exit 1):** adds one `check_manifest` against `$CC_ISOLATED_DIR` and one more `cc-push.sh` verify, then exits.
- **--list:** two more calls (cc-exit-scan+cc-gitdir, cc-push+cc-gitdir), so `cc-gitdir.sh` is hashed twice, plus one `readlink -f`.
- **--bless / --register:** two `mktemp`s, `compute_host_tools_manifest` (one batched `sha256sum` of 3 files), and a `cmp`, plus a `diff | grep` for each changed manifest, then two `mv`s.

**Data sizes (fixed, not user-scaled):** host-tools.sha256 holds 3 lines. The hashed files at f2533b33 are 51,631 B (cc-exit-scan.sh), 4,541 B (cc-gitdir.sh) and 28,263 B (cc-push.sh). N is a constant 3 and does not grow with users, projects or sessions. Every path here is **cold**: a human runs a CLI once per session, and it is followed by a container (re)start or an interactive exit.

**Measurement (my probe, 2026-10-14):** I extracted `verify_host_tools` from f2533b33 and ran it against copies of the real files with a matching manifest. 50 iterations per case, 16-core WSL2 host, load average 0.28, `LC_ALL=C`, inside `mktemp -d` under the job tmp dir, which is now removed:

| Case | Per run |
|---|---|
| 2-file call (source-time check) | 4.28 ms |
| 1-file call (cc-push warning) | 2.85 ms |
| launch total, both calls in `$(…)` as in the code | 7.79 ms |
| --list addition, both calls | 8.98 ms |
| one batched `sha256sum` of all 3 files, for comparison | 0.81 ms |
| batched sha256 of a 41-file skills tree, a stand-in for `check_manifest`'s claude-home walk | ~6 ms |

## Findings

#### Per-file `awk` + `sha256sum` forks where one batched hash would do

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh` `verify_host_tools` (the `for f in "$@"` loop), called at source time and in `main`
**Move:** Hidden multiplication / Count the forks
**Classification:** Micro (fork-per-file constant factor, N=3 fixed) / Cold path (once per CLI invocation, ahead of a container start)
**Confidence:** High
**Baseline:** 7.79 ms per launch for the two calls together, measured by my probe of f2533b33's `verify_host_tools` on 2026-10-14 (see the table above)

Evidence:
```
    want="$(awk -v f="$f" '$2 == f { n++; h = $1 } END { if (n == 1) print h }' "$m")"
    have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"
```
Each file costs about four forks: the awk subshell, sha256sum, cut, and the command substitution. A launch makes two calls, so this runs about 10 times counting the `readlink -f`. The hashing itself is about 0.8 ms; the rest of the 7.8 ms is fork overhead. That is about 0.3% of even a 3 s warm container start. `compute_manifest` already batched its hashing for this reason ("a fork per file made every launch pay for it"), but there it was ~100 files. Here N=3 is fixed by `host_tool_files`, so the multiplication has no way to grow.

**Recommendation:** No change needed. If someone later merges the two calls in main, one `verify_host_tools … cc-exit-scan.sh cc-gitdir.sh cc-push.sh` with the cc-push result split out would save about 3 ms. That is not worth giving up the simple byte-for-byte copy that A2 has to keep in step with cc-push.sh.

**Legibility-target:** a reader of `verify_host_tools`. The per-file loop is the clearer shape, and its cost is bounded by `host_tool_files`'s three-line list. No comment is needed, because the code makes the bound visible.

#### Refusal path now pays a full `check_manifest`

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh` `main`, the `if [ -n "$HOST_TOOLS_ERR" ] …` block
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (one extra batched hash walk) / Cold path (an error exit that a human reads)
**Confidence:** High
**Baseline:** ~6 ms for a batched sha256 of a 41-file skills tree, my probe on 2026-10-14. This stands in for `compute_manifest`'s claude-home walk, which its comment puts at "~100 files", so I expect ~10–15 ms in a real install. No installed config dir was available to measure directly.

Evidence:
```
    if ! CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" check_manifest; then
      boundary_note="The BOUNDARY config changed too (above). ..."
```
The refusal now runs the same boundary hash that a successful launch runs anyway, plus one more 2.85 ms cc-push verify, and then exits 1. The refusal path is therefore no more expensive than the launch path it replaces. It also sits in front of a human-reviewed bless, so latency does not matter. The cost buys the property the comment states: a host-tool refusal never hides a boundary change.

**Recommendation:** None. Keep it; the correctness benefit outweighs the ~10 ms.

**Legibility-target:** a maintainer tempted to "optimise" the refusal by dropping `check_manifest`. The existing comment ("Never let this refusal hide a boundary change") already explains why it is there.

#### `--list` hashes cc-gitdir.sh twice

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh` `list_projects`, the `lerr`/`perr` lines
**Move:** Hidden multiplication
**Classification:** Micro / Cold path (an interactive status command)
**Confidence:** High
**Baseline:** 8.98 ms for the two calls, my probe on 2026-10-14

Evidence:
```
  lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true
  perr="$(verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh)" || true
```
Splitting the check per entry point means the 4.5 KB `cc-gitdir.sh` is checked twice. That costs about 1.5–2 ms of forks, which is invisible next to `--list`'s existing `blessed_hash` work. The split is what lets the output say which entry point refuses.

**Recommendation:** None.

**Legibility-target:** a reader of `--list` output. The two-call shape matches the two entry points it reports on.

#### Bless now computes into temp files and diffs against the previous manifests

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh` `bless_manifest`
**Move:** Serialization tax / Trace the resource lifecycle
**Classification:** Micro / Cold path (a human-initiated bless or register)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

Evidence:
```
  new_m="$(mktemp "$(config_dir)/.manifest.XXXXXX")" || return 1
  new_h="$(mktemp "$(config_dir)/.host-tools.XXXXXX")" || { rm -f "$new_m"; return 1; }
  if ! compute_manifest > "$new_m" || ! compute_host_tools_manifest > "$new_h"; then
```
The added work is two `mktemp`s, the same compute as before plus one 3-file `sha256sum`, then for each manifest one `cmp -s` and, only when it changed, one `diff | grep` over at most ~100+ lines. That is a few milliseconds on an operation the user runs by hand. The temp files are cleaned up on the compute-failure branch and consumed by `mv` on success. An interrupt (SIGINT) between `mktemp` and `mv` leaves `.manifest.*` / `.host-tools.*` debris in the config dir, because there is no `trap`. These are dotfiles, so `enforcement_files`'s globs (`egress/*.txt`, `projects/*.profile`, `claude-home`) never pick them up, but they do pile up, one pair per interrupted bless. I read this from the code and have not tested it.

**Recommendation:** Optionally add a `trap 'rm -f "$new_m" "$new_h"' RETURN INT` or similar. The leak is bounded by how often a human interrupts a bless, so it does not have to block anything.

**Legibility-target:** a maintainer who later widens a glob in `enforcement_files` to `*` and starts hashing stale temp files.

## Endorsements

- The source-time check inside a repo checkout (install.sh beside the script, no manifest of either kind, not the config dir) returns 0 after one `readlink -f`, before it reads or hashes anything, so bats runs that source the script pay almost nothing per source. [read: devcontainer-config/cc-isolated.sh verify_host_tools, first `if` block, at f2533b33]
- `compute_host_tools_manifest` hashes all three files in one `sha256sum` call, keeping `compute_manifest`'s batching approach. [read: devcontainer-config/cc-isolated.sh compute_host_tools_manifest at f2533b33]
- On the launch path, total added host-tool cost is ~8 ms against a container start of seconds, which changes nothing about the brief's "fine on a cold path" conclusion. [unverified — submitted as claim: the 7.79 ms figure comes from my extracted-function probe; nobody timed an end-to-end launch]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Per-file awk + sha256sum forks (7.79 ms per launch) | Informational | `cc-isolated.sh` verify_host_tools | High |
| 2 | Refusal path now runs check_manifest (~10 ms est.) | Informational | `cc-isolated.sh` main, refusal block | High |
| 3 | `--list` hashes cc-gitdir.sh twice (8.98 ms total) | Informational | `cc-isolated.sh` list_projects | High |
| 4 | Bless temp files have no interrupt trap | Informational | `cc-isolated.sh` bless_manifest | Medium |

## Overall Assessment

The later additions don't change the performance picture. The host-tool list is fixed at 3 files and has no way to scale. Every new call is on a cold, human-driven path, and each is followed by a container start, an exit, or an interactive bless. The measured costs are 4.3 ms and 2.9 ms per call, 7.8 ms per launch, 9 ms per `--list`, and roughly 10 ms extra on the refusal exit. Those are well under any threshold a user would notice. They are also the same size as the brief's 13.5 ms/call figure, which I could not check because the earlier report is missing. Nothing needs fixing before merge. Finding 4's interrupt trap is the only change worth considering, and that is for tidiness, not speed. No further profiling is needed.

## Goal-Alignment Note

The goal is to review A1 for whether the triple or double `verify_host_tools` calls and the extra refusal and bless work change the cold-path verdict. They don't: every addition is a bounded constant on a cold path, and the review answers that with measurements, not just reasoning. Two points fall outside performance and belong to other reviewers.

1. At f2533b33, A1's comment says "KEEP IN STEP with the copy in cc-push.sh (a test compares the two byte for byte)", but cc-push.sh at that commit has no `verify_host_tools`. The copy arrives in A2 (840f39b0). This is a code-fact-check item: the claim is stale for this unit's snapshot.
2. The prior perf review the brief cites (`performance-review-2026-10-14-q089a.md`) is not on disk anywhere I looked, so the comparison baseline comes from the brief, not from that report.
