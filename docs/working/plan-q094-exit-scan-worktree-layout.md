# Plan: Q-094 [1] — the exit scan accepts git's standard linked-worktree layout

**Status:** implemented on branch `q094-exit-scan-worktree-layout` · **Opened:** 2026-09-28
**Enforcement file:** `devcontainer-config/cc-exit-scan.sh` (`hooks/live-verify-gate.sh` set), so this plan carries the bypass-family pre-mortem (decision log row 61 (4), RPI step 3).
**Live check:** a host `cc-isolated` session that leaves an agent worktree behind exits 0 with one `note:` line (`Live-verified: no` until then).

## Problem

`git worktree add <ws>/.claude/worktrees/agent-x -b wt-x` during a session adds exactly three records to the exit snapshot, so `git_exit_scan` returns 1 and the launcher exits 3:

```
+ dotgit          <ws>/.claude/worktrees/agent-x/.git           file 644 <hash>
+ commondir-file  <ws>/.git/worktrees/agent-x/commondir         file 644 <hash>
+ hooksdir        <ws>/.git/worktrees/agent-x/hooks             missing
```

Agent worktrees routinely outlive sessions, so almost every exit warns and the real warning gets skimmed (Q-094).

## Context that matters

- **The container writes container paths.** `devcontainer.json` mounts the checkout at `/workspace`, and git 2.39 (the image's git) writes absolute paths. So a worktree made in the session has `.git` = `gitdir: /workspace/.git/worktrees/<n>\n` and a back-pointer `.git/worktrees/<n>/gitdir` = `/workspace/<rel>/.git\n`. On the host, unless the checkout really lives at `/workspace`, that `.git` file names a path that does not exist. A rule that accepted only the host path would never fire for the case Q-094 is about. Both forms are accepted; see the rule.
- The scan already records the private dir (`.git/worktrees/<n>`) by its fixed layout: `config`, `config.worktree`, `info/attributes`, `hooks/` + entries, `commondir`, legacy remotes/branches, `rebase-merge/`, `rebase-apply/`, `sequencer/`, every symlink, and nested `modules/**` / `worktrees/*`. Anything in that list that is present shows up as a record. So "no other records" already rules out most of the non-standard shapes. The new code adds the checks that the records cannot express: exact bytes, pairing, and what the relative paths in config resolve against.
- The launcher maps `git_exit_scan` 0 → claude's own status, 1 → exit 3, 2 → exit 4. The acceptance lives inside `git_exit_scan` and returns 0, so `cc-isolated.sh` does not change.

## Experiments (git 2.39.5, scratch repos, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`)

Scripts: the session scratchpad `exp/exp.sh`, `exp/exp2.sh` (not committed). Every negative has a positive control in the same repo.

| # | Question | Result |
|---|---|---|
| E1 | Byte forms git writes | `.git` = `gitdir: <abs private dir>\n`; `commondir` = `../..\n` (6 bytes); back-pointer `gitdir` = `<abs wt>/.git\n`. Private dir also holds `HEAD`, `ORIG_HEAD`, `index`, `logs/` |
| E2 | `git rev-parse --git-path X` in the worktree | `hooks`, `info/attributes`, `config`, `info/exclude`, `remotes`, `branches` → **common dir**. `config.worktree`, `info/sparse-checkout`, `modules`, `rebase-merge`, `sequencer`, `index`, `HEAD` → private dir |
| E3 | Executable `pre-commit`, `post-commit`, `post-checkout`, `pre-push`, `reference-transaction` in `.git/worktrees/<n>/hooks/`, then commit + checkout in the worktree | **none ran**. Control: `post-commit` in the common `hooks/` ran |
| E4 | `* filter=x` in `.git/worktrees/<n>/info/attributes`, filter defined in common config, `git add` in the worktree | **filter not run**. Control: the same line in common `info/attributes` ran it |
| E5 | `core.fsmonitor` and `core.hooksPath` in `.git/worktrees/<n>/config` (not `config.worktree`) | **neither used** |
| E6 | `core.hooksPath` in `config.worktree` | ignored without `extensions.worktreeConfig`; used with it (control) |
| E7 | Relative `core.hooksPath = .githooks` in the **common** config, hook at `<wt>/.githooks/post-commit` | **ran**: resolved in the new worktree's working tree |
| E8 | Relative `core.attributesFile = .myattr` in the common config, `<wt>/.myattr` = `* filter=x` | **filter ran**: resolved in the new worktree |
| E9 | `remote.loc.url = ./sub.git` in the common config, bare repo with a `pre-receive` at `<wt>/sub.git`, push from the worktree | **hook ran**: a relative local remote resolves in the new worktree |
| E10 | Private dir removed / its `HEAD` removed / `.git` naming a missing path | `fatal: not a git repository: …` — git stops; no fallback to the parent checkout |
| E11 | `commondir` = absolute path, or `../../` | both accepted by git (same common dir) — so byte-exactness is our rule, not git's |
| E12 | `git worktree remove` | removes the working tree and the private dir (and `worktrees/` when it empties) |

E3–E5 settle the key question: nothing in the private dir that git reads for exec (hooks, attributes, config) comes from the private dir, except `config.worktree` (gated by an extension in the scanned common config, and recorded anyway). E7–E9 found a family the proposal missed: config values resolved **against the working tree git runs in**. The scan resolves them against the top-level checkout only, so a new worktree would silently get unscanned hooks, attributes or remotes.

## The acceptance rule

`git_exit_scan` computes the snapshot difference at record level (lines only in the launch snapshot, lines only in the exit snapshot). It passes with one `note:` line on stderr and status 0 only when **all** of the following hold. Otherwise it warns exactly as today (same text, same exit 3).

1. The exit git dir is valid (no `invalid` finding).
2. The difference has **no config-entry (C) records** and **only** F records of kinds `dotgit`, `commondir-file`, `hooksdir`.
3. The exit snapshot holds **no working-tree-relative path** (a new `W` record, see below): no repo config the scan reads (your own global config is covered by B14 instead) has a relative `core.hooksPath` or `core.attributesFile`, or a remote (url, pushurl, insteadOf base, pushDefault / branch remote naming a path, legacy remotes/branches file) that is a relative local path (E7–E9).
4. Every `commondir-file` record in the difference is at `<common>/worktrees/<n>/commondir`, where `<common>` is the checkout's own common dir (recomputed from `.git` by plain file reads and equal to the snapshot's `commondir` record), and `<n>` matches `^[A-Za-z0-9._-]+$` and is not `.` or `..`. Other names (spaces, newlines, `$'…'` quoting) are not accepted.
5. **Added worktree `<n>`** (its `commondir-file` is new): with `P = <common>/worktrees/<n>`:
   - the difference adds exactly `hooksdir P/hooks missing` and `commondir-file P/commondir file <mode> H("../..\n")` (the snapshot-time content, via its hash);
   - on disk now: `<common>/worktrees` and `P` are real directories (not symlinks); `P/commondir` is a regular file hashing to `H("../..\n")`; `P/hooks`, `P/config`, `P/config.worktree` do not exist; `P` holds no symlink;
   - the back-pointer `P/gitdir` is a regular file whose whole content is `<X>/.git\n`, with `<X>` = `<ws>/<rel>` (host form) or `/workspace/<rel>` (container form), `<rel>` non-empty; the working tree is `<wt> = <ws>/<rel>`;
   - the difference adds `dotgit <wt>/.git file <mode> H(G)` and `<wt>/.git` on disk is a regular file hashing to `H(G)`, where `G` is `gitdir: P\n` or, when `<common>` is inside the checkout, `gitdir: /workspace/<common rel>/worktrees/<n>\n`;
   - container form only: if that `/workspace/…` path exists on the host, it must resolve to `P` itself (host checkout at `/workspace`); otherwise host git in the worktree would read some other directory.
6. **Removed worktree `<n>`**: split into the stacked unit `q094b-exit-scan-worktree-removal` (decision log row 62 size cap; this unit came to 447 lines with it). In this unit any removed record warns. The stacked unit accepts a removal when the difference removes exactly `hooksdir P/hooks missing` and `commondir-file P/commondir file <mode> H("../..\n")`, `P` no longer exists on disk, and one removed `dotgit` record held exactly `gitdir: P\n` (either form). Review iteration 1 (security, Medium) showed that the first design, pairing removed `dotgit` records **by count**, let one clean removal absorb the deletion of another worktree's `.git`. Pairing is now by content.
7. Every record in the difference is consumed by rule 5 (in the stacked unit, by rule 5 or 6).

A decline never errors: any read failure inside the acceptance just means "not standard", and the full warning follows (fail closed). The scan still runs no git command in the checkout, and the note names only `<n>` values restricted by rule 4, through `scan_vis`.

**`W` records.** `_snap_config` and `_snap_remote` add `W <kind> <config or path %q>` whenever they resolve a path against a working tree. `scan_diff` ignores record types other than F and C, and a `W` record only changes when a C or F record does, so the report output is unchanged.

## Pre-mortem: bypass families

"Covered" means a session cannot make that shape pass silently: it either still warns or is proven not to be an exec input.

| # | Family | Status | How |
|---|---|---|---|
| B1 | Hooks in the private dir (`P/hooks/*`) | covered (twice) | E3: never run. Also rule 5 requires the `hooksdir missing` record and no `P/hooks` on disk |
| B2 | `config.worktree` in the private dir | covered | Recorded by the scan (rule 2 residue); on-disk check too. E6: only read with `extensions.worktreeConfig`, which lives in the scanned common config |
| B3 | Private-dir `config` | covered | E5: not read. Recorded anyway (residue) |
| B4 | Private-dir `info/attributes` | covered | E4: not read (common). Recorded anyway (residue) |
| B5 | Per-worktree `rebase-merge/`, `rebase-apply/`, `sequencer/` (todo `exec`) | covered | Recorded (residue) |
| B6 | Per-worktree `modules/**` (submodule git dirs) | covered | `_snap_nested` records them (residue) |
| B7 | Symlinks in the private dir, a symlinked `P` or `worktrees/` | covered | Recorded as `link` (residue); rule 5 also checks on disk |
| B8 | `.git` file naming somewhere else (another repo, a host dir) | covered | Rule 5: hash of the recorded file must equal `gitdir: P\n` or the container form, and the container form must not resolve to anything but `P` on the host |
| B9 | `commondir` variants (`/abs`, `../../`, `../../..`, another repo, CRLF, extra bytes) | covered | Rule 5: hash equals `H("../..\n")` exactly, snapshot-time and on disk |
| B10 | Back-pointer `gitdir` naming a path outside the checkout, or a different working tree than the `.git` found | covered | Rule 5: must be `<ws or /workspace>/<rel>/.git\n` and pair with the new `dotgit` record at that path. (Not an exec input; it steers `git worktree remove`, so pairing it also keeps `remove` pointed at the right dir) |
| B11 | `locked`, `HEAD`, `ORIG_HEAD`, `index`, `logs/`, per-worktree refs, `info/sparse-checkout` | covered: not exec | Not read to decide what to run. The private `index` has the same standing as the main checkout's `index`, which the scan never recorded (parity, no new route) |
| B12 | Relative `core.hooksPath` / `core.attributesFile` in repo config (husky's `.husky/_`), resolved in the new worktree (E7, E8) | covered | Rule 3: any `W` record declines the acceptance. Cost: repos with husky-style relative hooksPath keep warning on every new worktree |
| B13 | Relative local remotes resolved in the new worktree (E9), incl. `insteadOf` bases, `pushDefault`/`branch.*.remote` naming a path, legacy `remotes/*`/`branches/*` | covered | Rule 3 (`W` from `_snap_remote`, which all of these go through) |
| B14 | Your own global config's relative `core.hooksPath`/`attributesFile`, or `includeIf gitdir:` matching the new worktree's git dir | covered | When the worktree's `.git` resolves on the host, `_snap_host_config` already walks it for that git dir and any path inside the checkout becomes a new record (residue). When it does not resolve (container form, host not at `/workspace`), host git in it stops (E10) |
| B15 | Working-tree `.gitattributes` / `.gitmodules` in the new worktree | not covered — parity | The scan never tracks working-tree files for the top level either (they only select drivers the scanned config defines; `.gitmodules` `update=!cmd` is ignored by git). Same as today for any branch the session checks out |
| B16 | An embedded `.git` (dir or file) inside the new worktree's tree | covered | `find -name .git` records it (residue) |
| B17 | `.git` at the worktree root being a directory or a symlink instead of a file | covered | Rule 5: attrs must be `file …` and on disk a regular non-symlink file |
| B18 | Odd names: spaces, newlines, `$'…'`, `..`, names chosen to collide with `%q` output | covered | Rule 4 restricts `<n>` to `[A-Za-z0-9._-]`, not `.`/`..`; paths are compared as the `%q` string recomputed from the parsed name, never unquoted |
| B19 | Worktree registered in a nested repo's common dir (P6-style bare repo in the checkout) | covered (warns) | Rule 4: only the checkout's own common dir |
| B20 | Standard worktree + an unrelated plant anywhere | covered | Rule 7: any residue warns, and the warning lists everything, worktree lines included, exactly as today |
| B21 | Removal hiding a plant: private dir made "not a git dir" (HEAD or commondir deleted) so its records vanish while files stay | covered | Rule 6 requires `P` gone on disk. E10: a private dir without HEAD is refused by git anyway |
| B22 | Removal of a pre-existing non-standard worktree (had hooks/config.worktree) | covered (warns) | Its other records are residue |
| B23 | Remove-and-re-add at the same path (dotgit changed) | covered (warns here) | Here, any removed or changed record warns. In the stacked unit, the added side is verified by rule 5 and the removed `dotgit` is paired by content |
| B24 | TOCTOU: the container (still running after claude exits) changes files between the snapshot and the checks | covered as far as the scan can | Rule 5 checks the snapshot-time hashes and the disk; a later change is the documented "After the scan" route, unchanged |
| B25 | Newer git writing relative paths (`worktree.useRelativePaths`, git ≥ 2.48) | not accepted (warns) | Byte-exact rule. Not a bypass; a future false positive |
| B26 | Worktree whose working tree is outside the checkout | not accepted (warns) | Back-pointer must be inside `<ws>` / `/workspace` |
| B27 | Working tree removed but not pruned (`rm -rf` without `git worktree prune`) | not accepted (warns) | Only the `dotgit` record goes. Here, any removal warns. In the stacked unit, count pairing did NOT cover this: another worktree's clean removal absorbed the lone `-dotgit` (security review iteration 1, confirmed by experiment). It is fixed there by pairing on content |
| B28 | `printf \| grep -q` under the launcher's `pipefail`: an early match SIGPIPEs printf, so the check reads as "no match". For the W refusal that means it fails **open** on a large snapshot (performance review iteration 1) | covered | Pattern matches in bash (`[[ ]]`), no pipeline. The same fix was applied to the pre-existing `invalid` check in `git_exit_scan`. The test (40k padding records) covers the two checks in `scan_std_worktrees`; the `invalid` check has no test of its own |
| B29 | `branch.<b>.remote = .` (local tracking) | covered: benign, exempt | `.` is the repository git runs in. From a linked worktree that means the same common dir and its hooks (verified: a push to `.` from the worktree ran the common `pre-receive`, not the private one). No W record |

Unproven-benign shapes all warn. No family moves from covered to uncovered for the top-level checkout.

## Steps

1. `cc-exit-scan.sh`: `GIT_EXIT_SCAN_CONTAINER_WS`; `W` records in `_snap_config` / `_snap_remote`; `_snap_hash_str`; `scan_std_worktrees`; call it in `git_exit_scan`; header (WHAT IS SNAPSHOTTED, a new STANDARD WORKTREES paragraph).
2. `guides/cc-isolated-usage.md`: exit-status and tripwire sections, the note; the new known route list items (B12 cost, B25–B27 still warn).
3. `test/cc-isolated-functions.bats`: new standard (host form and container form) → 0 + note; removed → 1 (acceptance in the stacked unit); pipefail with large snapshots; non-standard variants (commondir abs / `../../`, hooks/, config.worktree, symlink, `.git` elsewhere, back-pointer outside, odd name, relative hooksPath, relative remote, nested common dir, container form resolving elsewhere, private dir left behind after removal) → 1; standard + plant → 1 with the plant listed; launcher maps to claude's status.
4. Tests, then the review-fix loop.
