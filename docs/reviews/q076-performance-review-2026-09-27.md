Commit: 61d801c

# Performance Review — Q-076 (feat/q076-git-exit-scan)

**Scope:** `git diff main...feat/q076-git-exit-scan` (8 files). Performance-relevant: `devcontainer-config/cc-isolated.sh` (exit scan, `git_exec_snapshot` and helpers), `devcontainer-config/cc-push.sh`.
**Date:** 2026-09-27
**Based on:** `docs/reviews/q076-code-fact-check-report-r1.md`, `-r2.md`, `-r3.md`; measurements in `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-perfapi/measurements.log` (scratch clone at 61d801c, git 2.39.5; the snapshot was run read-only against `/workspace` and against synthetic repos).

## Data Flow and Hot Paths

- **Exit scan.** `git_exec_snapshot` runs twice per session. It runs once at launch, before `devcontainer up` (`cc-isolated.sh:1392`), so it adds to launch latency. It runs again after claude exits (`:1465`), and the user waits for it. Neither run is a request hot path. Both block an interactive user, and the exit run's input is chosen by the container. Cost has two parts. (a) One `find -P <ws> -mindepth 2 -name .git` over the whole working tree (`:1182`), which is cheap on a warm cache: 0.05 s for 100k files. (b) A fork-heavy per-git-dir walk (`_snap_gitdir` `:1069`, `_snap_host_config` `:992`, `_snap_file` `:733`). Each git dir costs roughly 15–20 subshells and forks (stat, sha256sum, realpath, `cd && pwd -P`, two `git config` forks).
  - **Measured on this repo:** `/workspace` has about 398k files including `node_modules`, 55 `.git` entries (mostly `external/` benchmark repos) and 3 linked worktrees. The snapshot took **2.2 s and 4.2 s** (two warm runs) and produced 561 records. That is about 4–8 s of scan per session.
  - **Scaling:** time is linear in embedded repos and hook files, not in plain files. 100 embedded repos took 2.5 s, 500 took 14.1 s, 1500 took 43.3 s (about 29 ms per repo). 2000 hook files took 8.9 s (about 4.4 ms per hook).
- **cc-push.** A cold CLI path run by hand once per push. It does a local-path fetch of **every** checkout branch (`cc-push.sh:233-234`), `ls-remote` against the checkout, a fetch of every origin branch (`:251`), a preview and a push. Measured on a 148 MiB repo: first run 3.9 s and a full 148 MiB copy into `~/.local/share/cc-isolated/clones/…`; later runs 0.03–0.15 s, including with 2000 extra branches. Repeated runs are cheap. The cost is in the first run and in what the checkout's branches contain.

## Findings

#### cc-push copies every branch the session created, whatever is pushed, into host disk (unbounded)

**Severity:** Medium
**Location:** `devcontainer-config/cc-push.sh:233-234`
**Move:** 2 (size of N), 4 (memory/storage lifecycle)
**Classification:** Macro (unbounded storage growth driven by container-chosen data) / Cold path (manual CLI), but writes to host disk
**Confidence:** High
**Baseline:** 10.8 s and +278 MiB of host disk (clone 156 MiB → 434 MiB) for a run that printed "Nothing to push: origin/main already has every commit." (scratch measurement 2026-09-27, `measurements.log`)

Evidence:
```bash
  if ! run_vis hgit "$clone" -c protocol.file.allow=always fetch -q --no-tags --no-recurse-submodules \
         --no-write-fetch-head --prune "$co" '+refs/heads/*:refs/cc/heads/*' >&2; then
```
The refspec mirrors all of the checkout's branches before `--branch`/HEAD is even resolved (`:238-244`). A session that leaves a branch holding large incompressible blobs makes every `cc-push`, including a no-op one, pack and copy them into the host-only clone under `$XDG_DATA_HOME`. That happened in the measurement with a 300 MB blob on an unrelated branch. Nothing bounds it: no size check, and no `--filter`. `--prune` deletes the ref when the branch goes away, but the objects stay until `gc` prunes them (default `gc.pruneExpire` is 2 weeks). This is within the threat model (the container writes the checkout), and it turns cc-push into a way for the container to fill the host's data partition. The attempt ends with a clean exit 0 and no mention of the extra data.

**Recommendation:** Resolve the branch first. Resolving HEAD with `ls-remote --symref` does not need the fetch. Then fetch only `+refs/heads/<branch>:refs/cc/heads/<branch>`. Optionally cap the fetched pack size, or report the clone's growth. Route to security-reviewer for the host-disk exhaustion angle.

#### Size cap is bypassed by the unbounded `read` of the checkout's own `.git`/`commondir`

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:655`, `:666` (in `scan_git_dirs`, `:648-677`, read whole; its value flows to `git_exec_snapshot` `:1159`)
**Move:** 9 (asymptotic behaviour / worst-case input)
**Classification:** Macro (linear in a container-chosen, zero-disk-cost size) / Cold path (exit scan), but blocks the user at session end
**Confidence:** High
**Baseline:** 3.71 s for a 1 GiB sparse `.git/commondir` (0 bytes on disk) before the scan fails with "too large to hash"; `read -r` of a 256 MiB sparse file takes 0.91 s (scratch measurement 2026-09-27)

Evidence:
```bash
    { IFS= read -r line < "$g"; } 2>/dev/null || true
...
    { IFS= read -r line < "$g/commondir"; } 2>/dev/null || true
```
`_snap_size_ok` (`:712`) exists because "a session can plant a huge (or sparse, apparently huge) hook to stall the scan for hours". But `scan_git_dirs` reads the first line of `.git` (when it is a file) and of `commondir` before any size check. `read` reads until it sees a newline. A sparse all-zero file has no newline, costs no disk, and scales at about 3.6 s per GiB. A 1 TiB sparse `commondir` therefore stalls the exit scan for roughly an hour. The code reaches `_snap_opt commondir-file` (which is capped) only afterwards. The end result is still fail-closed: exit 4, or exit 4 on Ctrl-C. That keeps severity Low. But this is exactly the stall the cap was added to prevent, and the LIMITS "slow scan" bullet attributes slow scans only to "many files or embedded repos". Fact-check r2 flagged the uncapped read as a scope residue (Claim 8). The same unbounded read in `_snap_dotgit_target` is already protected, because `_snap_dotgit` → `_snap_file` size-checks the entry first (measured: a 256 MiB sparse embedded `.git` failed in 0.03 s).

**Recommendation:** In `scan_git_dirs`, apply `_snap_size_ok` or a small fixed limit (for example 4 KiB via `head -c`) before each `read`. Git itself reads these files whole, but no valid one exceeds a path length.

#### Exit-scan cost is linear in embedded repos and hook files, with no count cap, paid twice per session

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:1182-1191` (embedded-repo loop in `git_exec_snapshot`, `:1153-1204` read whole), per-dir work in `_snap_gitdir` `:1069-1143`, `_snap_hooks` per-file loop
**Move:** 1 (hidden multiplication), 2 (size of N)
**Classification:** Macro (linear, unbounded N) / Cold path, but it blocks launch (before `devcontainer up`) and session end
**Confidence:** High
**Baseline:** /workspace: 2.23 s and 4.24 s per snapshot; synthetic: 1500 embedded repos → 43.3 s, 2000 hooks → 8.9 s (scratch measurement 2026-09-27)

For every `.git` found anywhere in the working tree, the loop runs `_snap_dotgit` (a full `_snap_gitdir`: two config reads, hooks listing, a symlink `find` over the git dir, a nested-dir `find`) plus `_snap_host_config`. `_snap_host_config` forks `git config --list` over your global and system config again for each repo and re-walks their includes. At about 29 ms per repo and 4.4 ms per hook, the cost is fork-bound, not I/O-bound. The tree walk itself took 0.05 s warm over 100k files. For this repo the price is modest (about 4–8 s per session). A submodule-heavy monorepo or a vendored tree with a few hundred `.git` directories pays tens of seconds twice. A hostile session can push the exit run arbitrarily high. That case is documented in LIMITS ("A slow scan"), and Ctrl-C exits 4, so severity stays Low. The launch-side cost is not documented: users will see launch slow down on large checkouts with no message saying why.

**Recommendation:** (1) Read the global and system config once per snapshot (one `--show-origin --list` plus includes) and evaluate only the `includeIf` conditions per repo. The measured share was 5.6 ms of the 29 ms per repo with an empty global config, and more with includes. (2) Batch the per-file `stat`/`sha256sum` forks: one `stat -c` and one `sha256sum` over a NUL list per directory, instead of about 3 forks per file. (3) Print a one-line "scanning N git dirs…" at launch when N is large, so the delay is attributable. A count cap would have to fail closed (exit 4), which is already the documented escape.

#### Working-tree walk makes launch availability depend on every directory in the checkout being listable

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:1182` (via `_snap_find` `:780-786`); launch refusal `:1392-1401`
**Move:** 3 (work moved to the wrong place) / 10 (deployment environment)
**Classification:** Macro (whole-tree walk) / Cold path (launch)
**Confidence:** Medium (the refusal is measured; how often real checkouts contain unlistable directories is assumed)
**Baseline:** a single `chmod 000` directory anywhere in the working tree → snapshot rc=1, "cannot list everything under …: find: '…/pgdata': Permission denied" (scratch measurement 2026-09-27)

The embedded-repo search is a full-tree `find` with no pruning, and `_snap_find` treats any listing error as fatal. At launch, `cc-isolated` refuses to start (exit 1). At exit, it returns 4. Docker-based projects routinely have bind-mounted data directories that your uid cannot list, such as a Postgres `pgdata` owned by uid 999 with mode 700, or root-owned build caches written by containers. On such a checkout the launcher either refuses to start or reports every session as "could not read" (4). That trains users to ignore exit 4. The fail-closed intent is right for git dirs. It is over-broad for arbitrary working-tree directories, whose only role here is as places an embedded `.git` might sit.

**Recommendation:** Keep fail-closed for git dirs, their hooks and config targets. For the working-tree search, either record unlistable working-tree dirs as `F other-unlistable` records, so a change in them is still a finding, or name them in the launch refusal with the fix. At minimum, add a line to the guide's troubleshooting table.

#### cc-push is unusable on partial clones, and the failure reads as corruption

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:233-236`
**Move:** 10 (deployment environment)
**Classification:** Macro / Cold path
**Confidence:** High
**Baseline:** a `blob:none` partial-clone checkout (promisor remote) → exit 1 after 8.6 s, with "remote: fatal: unable to read <oid> … aborting due to possible repository corruption on the remote side" (scratch measurement 2026-09-27)

Large monorepos are commonly partial clones. upload-pack in the checkout cannot supply missing blobs, correctly: it must not lazy-fetch, and fact-check r3 Claim 2 confirms a planted promisor lazy fetch does not fire. So the first `cc-push` of such a checkout always fails, after packing everything it does have. The guide does not mention partial or shallow checkouts.

**Recommendation:** Detect `extensions.partialclone`/`remote.*.promisor` by the same plain text read used for `[include]`, and refuse up front with a clear reason. Document the limitation in "Pushing: cc-push".

#### First cc-push duplicates the whole history, keyed on the checkout's physical path

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:191-195`
**Move:** 4 (storage lifecycle)
**Classification:** Macro (proportional to repo size) / Cold path
**Confidence:** High
**Baseline:** 148 MiB repo → 3.9 s and a 148 MiB clone on first run (scratch measurement 2026-09-27)

The clone id is `sha256(<physical checkout path>)`. Moving or renaming a checkout therefore creates a new full clone, and the old one is orphaned. There is no command to list or clean clones, and the guide does not tell users where disk goes. This duplication is intended: sharing objects via alternates would re-open the exfiltration routes the tool refuses. The cost is still worth stating.

**Recommendation:** Mention the disk cost and location in the guide, and how to delete a clone. Consider a `--list-clones` or a note in the "Created the host-only clone" message.

## Endorsements

- Repeated `cc-push` runs are incremental and cheap: 0.05 s with one new commit, 0.03 s with nothing to push, 0.15 s with 2000 extra checkout branches. This is a measured observation on one 148 MiB repo, not a general claim. [read: `devcontainer-config/cc-push.sh:233-251` plus scratch measurement in measurements.log]
- The per-file 64 MiB and 1 GiB total hashing caps apply to every hashed file, and an oversized embedded `.git` entry fails in 0.03 s rather than being read. [fact-check: r1 Claim 13 — Verified (executed)]
- The whole-tree `find` is not the scan's bottleneck on a warm cache: 0.05 s for 100k files, against about 29 ms per embedded git dir. This is submitted so the fix effort goes to per-dir forks, not to pruning the walk. [unverified — submitted as claim: cold-cache and drvfs (/mnt/c) timings were not measured; the one cold run was 1.23 s for 100k files]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | cc-push fetches all checkout branches; container-chosen blobs fill host disk even on a no-op push | Medium | `devcontainer-config/cc-push.sh:233-234` | High |
| 2 | Uncapped `read` of `.git`/`commondir` bypasses the size cap (sparse file, ~3.6 s/GiB) | Low | `devcontainer-config/cc-isolated.sh:655,666` | High |
| 3 | Scan linear in embedded repos (~29 ms) and hooks (~4.4 ms), paid at launch and exit | Low | `devcontainer-config/cc-isolated.sh:1182-1191` | High |
| 4 | Any unlistable working-tree dir blocks launch (1) or yields 4 | Low | `devcontainer-config/cc-isolated.sh:1182,780-786` | Medium |
| 5 | Partial-clone checkouts always fail, with a corruption-sounding error | Informational | `devcontainer-config/cc-push.sh:233-236` | High |
| 6 | First push duplicates full history; path-keyed clones orphan on move | Informational | `devcontainer-config/cc-push.sh:191-195` | High |

## Overall Assessment

The performance posture is acceptable for the stated purpose. On this repo (about 400k files, 55 embedded repos) the exit scan costs 2–4 s per snapshot, twice per session. Cost is fork-bound and linear in git dirs and hooks, not in working-tree size. None of the issues is structural, and all can be fixed in place. The most important one is #1. `cc-push`'s all-branches fetch runs on the path the guide makes mandatory, and it gives a session an unbounded way to write to host disk, silently. Fetching only the pushed branch fixes the disk growth and also cuts time. #2 is a one-line fix that makes the size cap's own rationale hold. #3 and #4 affect usability on large or docker-heavy checkouts. They should be measured on the user's real largest checkout, preferably from a cold cache and, if the repos live under `/mnt/c`, on drvfs, before deciding whether the host-config hoist and fork batching are worth it.

## Goal-Alignment Note

- **Success criterion (verbatim):** both reports saved at those paths.
- **Answered:** I measured exit-scan cost at launch/exit on this repo with worktrees (2.2–4.2 s per snapshot) and on synthetic scaling cases: many embedded repos, many hooks, a large plain tree like node_modules, and a sparse-file stall. I also covered unreadable directories, the size caps (verified; one bypass found, #2) and cc-push fetch cost on first and repeated runs (cheap), including the all-branches cost (#1) and partial clones (#5). I checked the iteration-3 size-cap and FIFO closures and did not re-report them.
- **Out of scope:** Security implications beyond noting #1's disk-exhaustion angle belong to security-reviewer. I did not measure cold-cache or drvfs timings, git versions other than 2.39.5, or a real submodule-heavy monorepo (the synthetic embedded-repo case stands in for one). I did not re-verify behaviours the fact-check reports cover.
- **Escalate:** #1 (host-disk growth driven by the container through the mandated push path) should be weighed by security-reviewer and fixed before merge if cheap. The fetch-only-the-branch change is small.
