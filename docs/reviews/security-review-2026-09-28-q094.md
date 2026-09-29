# Security Review — branch `q094-exit-scan-worktree-layout`

Commit: 5a6d689
**Scope:** `git diff main...HEAD` — `devcontainer-config/cc-exit-scan.sh` (new `scan_std_worktrees`, `_snap_wrel` W-records, container-form path logic, `git_exit_scan` acceptance branch); read whole, plus `cc-gitdir.sh`, the `cc-isolated.sh` call site, the new bats tests, and the plan/pre-mortem.
**Date:** 2026-09-28
**Based on:** the Stage-1 code-fact-check results supplied in the dispatch (claims about `_snap_worktree_of`, config.worktree, W-record inertness).

The point of this change: `git_exit_scan` returns 0 with one `note:` line (launcher passes claude's own status) when the only difference between the launch and exit snapshots is standard linked worktrees of the checkout's own common dir added/removed in git's exact layout — instead of warning (launcher exit 3) as it did for every left-behind worktree.

## Trust Boundary Map

```
B1: container writes .git/** & working tree (bind mount)  → git_exec_snapshot record diff → scan_std_worktrees accept/decline  (new)
B2: container-written .git file / commondir / gitdir bytes → %q-string + hash equality checks → note text (scan_vis)            (new)
B3: host user runs `git ...` in the checkout AFTER exit    → git repo discovery (2.39)      → hook / config / fsmonitor exec
B4: host user runs `git ...` in a LEFT-BEHIND worktree dir → git repo discovery (2.39)      → hook / config / fsmonitor exec   (new surface)
```

Input-source classification table:

```
S1: .git / commondir / gitdir file bytes in the checkout   — runtime-mutable (container) — UNTRUSTED for path-construction / repo-discovery / exec sinks
S2: private-dir layout under <common>/worktrees/<n>         — runtime-mutable (container) — UNTRUSTED for exec sinks (hooks/config it would host)
S3: working-tree directory at a worktree's <rel> path       — runtime-mutable (container) — UNTRUSTED for repo-discovery/exec (may be replaced with a planted repo)
S4: launch snapshot `before` (string arg)                  — session-local, host-produced — trusted for diffing (produced by the host launcher pre-session)
S5: GIT_EXIT_SCAN_CONTAINER_WS = /workspace constant        — code-constant               — trusted (all sinks)
S6: host global/system git config                          — deploy-time (yours)          — trusted for its own entries; relative paths it names resolving INSIDE the checkout are re-read from S1/S2/S3
```

The scan runs no git command *in the checkout* (config is read `--file … --no-includes` from `/`; the rest is `find -P`, `stat`, `readlink`, `sha256sum`, `cat`). Every container-chosen string is `%q`-quoted or `scan_vis`-reduced before it reaches the terminal. The whole acceptance is designed to fail closed: any unreadable file, unlistable dir, or unmatched record declines to the full warning. The new attack surface Q-094 introduces is B4: a worktree left behind is now *expected* and no longer warned about, so whatever the session leaves at that worktree's directory is a place a host user may later run git.

## Findings

#### Removal count-pairing suppresses an unrelated worktree's `dotgit`-removal warning (defeats pre-mortem B27)

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:896-903` (the removed-`dotgit` count-pairing loop) and `:846-850` (removed-worktree path checks only the private dir `P`, not the working-tree directory)
**Boundary:** B1 → B4
**Move:** #11 (enumerate bypasses), #4 (TOCTOU-adjacent: check/use grain), #5 (invert what the acceptance *prevents*)
**Confidence:** High (the warning→note downgrade is demonstrated; see below)

`scan_std_worktrees` accepts removed worktrees, then in a second loop treats **every remaining unpaired `- dotgit … file …` record as benign as long as `ndot == nrm`** (number of removed `dotgit` files equals number of removed worktree private dirs). The pairing is purely by count — a removed `dotgit` is never tied to the specific worktree whose private dir was removed. So a session that performs **one legitimate worktree removal** (supplying `nrm=1`) may **also silently delete a second, unrelated worktree's back-pointer `.git`** (its `- dotgit` record is absorbed, `ndot=1=nrm`), and `git_exit_scan` returns 0 with a note that names only the cleanly-removed worktree.

The removed-worktree branch (`:846-850`) checks only that the private dir `P = <common>/worktrees/<n>` is gone; it never inspects what now sits at the worktree's working-tree directory. Combined with the pre-existing, documented "a repository in a working-tree directory not named `.git`" limit, the vacated working-tree directory can be replaced with a bare-layout repo (`HEAD`+`objects/`+`config`, no `.git` entry), which the snapshot does not record. When the host user later runs git in that directory, git discovers the planted repo and runs its `core.fsmonitor` / hooks / pager as the user.

This is exactly the shape the pre-mortem's row **B27** claims is safe: *"Working tree removed but not pruned … only the `dotgit` record goes; rule 6 needs the whole triple … Not accepted (warns)."* That protection holds only when `nrm=0`. As soon as the session also removes one worktree cleanly, the lone `dotgit` removal is paired by count and the warning becomes a note.

Verified (scratch repos, git 2.39.5, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`):
- `scratchpad/sec/x1.sh plant`: two launch worktrees A,B; session `rm -rf .git/worktrees/A` (clean removal) + `rm wts/B/.git` + planted bare repo at `wts/B` with `core.fsmonitor`. Result: `git_exit_scan` → **status 0**, note `only linked worktrees … changed (removed: A)` — B is not named. Host `git status` in `wts/B` created the `PWNED-fsmonitor` marker.
- `scratchpad/sec/x1.sh control`: identical but A's private dir kept (`nrm=0`) → **status 1**, full warning (B27's stated behavior). This isolates the count-pairing as the cause.
- `scratchpad/sec/x2.sh`: a bare-layout repo planted at a plain subdir with **no worktrees at all** → status 0 today, exec happens → confirms the underlying *exec* route is the pre-existing bare-repo limit, not new to Q-094.

Net security delta: Q-094 does **not** open a new code-execution primitive — the planted-bare-repo route is already an accepted, documented limit (`guides/cc-isolated-usage.md`, "A repository in a working-tree directory not named `.git`"). What it *does* do is **suppress the one recorded signal the tripwire would otherwise emit** (the `dotgit` removal warning that fired pre-Q-094, per x1 control), and emit a note whose text ("only linked worktrees in git's standard layout changed") actively misdescribes the state — the user is told worktree A was removed and is given no indication that a second worktree's back-pointer vanished. The tripwire's contract is "warn on any difference"; this is a difference in a *recorded* record that is silently accepted.

**Recommendation:** Tie each removed `dotgit` to the specific removed worktree instead of pairing by count: for a removed worktree `<n>`, require the removed `dotgit` to be the one whose back-pointer named that worktree's working tree (the launch snapshot's `P/gitdir` gives `<rel>` → `<wt>/.git`), and refuse any leftover removed `dotgit` that does not correspond to a removed worktree in this diff. At minimum, when a removed `dotgit` cannot be matched to a removed worktree, decline to the full warning (fail closed) rather than accepting on count parity. Consider also having the note name every worktree whose records changed, not only those that passed the clean-removal triple.

#### `_snap_worktree_of` reads a container-chosen config file without a regular-file guard

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:325` (`git --no-pager config --file "$real/config" … --get core.worktree`), reachable from `_snap_gitdir`'s legacy `remotes/`/`branches/` loop (`:602`, `:605`) via `_snap_worktree_of "$real/config"`
**Boundary:** B1
**Move:** #3 (error path), #8 (resource exhaustion / stall)
**Confidence:** High (matches the supplied fact-check; pre-existing code, not introduced by this diff)

Every other config read in the file goes through a size cap or `-f` test first; this one does not. A session that plants a FIFO at `<git dir>/config` together with a `remotes/` entry makes `git config --file <fifo>` block, hanging `git_exec_snapshot`. This is pre-existing (the commit message's claim "The rest of the scan checks `-f` before every read" is inaccurate here, per the fact-check) and it fails *closed* — the launcher/exit either stalls until killed (treated as unscanned) or the operator Ctrl-Cs into exit 4. It does not let a plant pass. Flagged so the commit-message claim is corrected and the read is bounded.

**Recommendation:** Gate the read with `[ -f "$real/config" ] && [ ! -L … ]` (and the size cap) as the other config reads are, or drop the `--get core.worktree` fast-path in favor of the `.git`-suffix heuristic already below it. Correct the commit-message claim.

## Endorsement Claims

- **Claim:** `scan_std_worktrees` returns 1 (declines to the full warning) when the exit snapshot contains any `W` record.
  **Location:** `cc-exit-scan.sh:807`
  **Evidence:** executed
  **Verified:** bats "a relative hooksPath, attributesFile or remote keeps a new worktree a finding" passes; a relative `core.hooksPath` in common config produces a `W` record and the acceptance declines.
  **Not verified:** that `_snap_config`/`_snap_remote` emit a `W` for *every* working-tree-relative exec path git 2.39 resolves (e.g. a `hasconfig:`-gated include); only the enumerated kinds (hooksPath, attributesFile, the remote family) were exercised.
  **route: code-fact-check**

- **Claim:** An added worktree whose `.git` file does not hash to exactly `gitdir: P\n` (or the accepted `/workspace` container form resolving to `P`) is refused.
  **Location:** `cc-exit-scan.sh:874-891`
  **Evidence:** executed
  **Verified:** bats "a private dir git would also accept … warns" and "the container's /workspace form is accepted unless it is another host dir" pass; `.git` pointing elsewhere, or a `/workspace` path resolving to a different host dir, both decline.
  **Not verified:** behavior when the host checkout path is itself *under* `/workspace` but not equal to it (the `case "$common" in "$wsp"/*)` container-common branch) with a symlinked intermediate — read statically, not executed.
  **route: code-fact-check**

- **Claim:** The acceptance runs no git command *in the checkout*; its only git invocations are `git config --file … --no-includes` executed from `/`, plus plain file tools.
  **Location:** `cc-exit-scan.sh:325,376,496` and `scan_std_worktrees` (no git calls; `find -P`, `stat`, `readlink`, `sha256sum`, `cat`)
  **Evidence:** read-static
  **Verified:** grep of the changed functions shows every `git` call carries `--file` and runs under `cd /`; `scan_std_worktrees` invokes no `git`.
  **Not verified:** that `git config --file` on a container-controlled path performs no include/hook side effect under git 2.39 beyond parsing (relied on, consistent with `--no-includes`, not re-executed here).

- **Claim:** Container-chosen names/values in the note and warning cannot inject terminal control bytes.
  **Location:** `cc-exit-scan.sh:739-741` (`scan_vis`), `:904-908` (note names restricted to `[A-Za-z0-9._-]` then `scan_vis`)
  **Evidence:** read-static
  **Verified:** the note interpolates only `<n>` values already matched to `^[A-Za-z0-9._-]+$`, and the whole message is piped through `scan_vis`.
  **Not verified:** the `changes` warning body for a declined case with an exotic path — relies on `%q`/C-record replacement upstream, not re-executed for this diff.

## Primitive sweep

Primitive: repository discovery leading to hook/config/fsmonitor exec (the sink this whole file guards)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| host git in main checkout after exit | S1 `.git`/common config | full record diff + gitdir-valid + root-repo checks | out of Q-094 scope; unchanged |
| host git in a left-behind worktree dir | S3 working-tree dir | removed-worktree branch checks only private dir `P` gone | **Finding 1** (warning→note downgrade; exec via pre-existing bare-repo limit) |
| host git in an *added* worktree dir | S1 `.git` bytes, S2 layout | byte-exact `gitdir:`/commondir hashes, on-disk layout, W-record refusal | cleared — added path is tightly constrained (Endorsement 2) |

Primitive: `git config --file <container path>` (parse / potential FIFO block)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:376` `_snap_config` | S1 | reached only after `_snap_opt`/`-f` records the file | cleared — file existence path-checked before read |
| `cc-exit-scan.sh:496` `_snap_host_config` | S6 | your own config, not container-writable | cleared — S6 deploy-time |
| `cc-exit-scan.sh:325` `_snap_worktree_of` | S1 | **none** (no `-f`/size cap) | **Finding 2** (FIFO stall; fails closed) |

No `eval`, raw SQL, HTML interpolation, deserialization, or network primitives are in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Removal count-pairing suppresses an unrelated worktree's `dotgit`-removal warning (defeats B27) | Medium | B1→B4 | `cc-exit-scan.sh:896-903,846-850` | High |
| 2 | `_snap_worktree_of` reads a container-chosen config without a regular-file guard | Low | B1 | `cc-exit-scan.sh:325` | High |

## Overall Assessment

The change is carefully built and fails closed in the cases the pre-mortem enumerated: added worktrees are pinned to byte-exact `gitdir:`/`commondir` content and on-disk layout, any working-tree-relative exec path leaves a `W` record that refuses the note, and container-form paths are checked to resolve to the same directory. The one real weakness is the **removal side**: `dotgit` removals are paired to removed worktrees *by count, not by identity*, and the removed-worktree branch never inspects what remains at the vacated working-tree directory. This lets a session ride one legitimate worktree removal to silently suppress the warning for a second worktree whose back-pointer it deleted — defeating pre-mortem row B27 and emitting a note that misdescribes the state. It does **not** open a new code-execution primitive (the planted-bare-repo route is a separately-documented accepted limit, confirmed by `x2.sh`), so it is Medium, not High — but it erodes the tripwire's core "warn on any recorded difference" contract, which is the whole point of the scan. The single most important thing to address: match removed `dotgit` records to specific removed worktrees and fail closed on any leftover, rather than accepting on count parity. Endorsement claims routed to code-fact-check remain pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/security-review-2026-09-28-q094.md (in the worktree), structured per the security-reviewer skill.
- Answered: yes — report saved at that path with Commit line, trust map, findings (Med+Low), endorsement claims, primitive sweep, summary, assessment.
- Out of scope: full supply-chain audit (no manifest changes here); non-diff pre-existing scan machinery except where the new acceptance reaches into it.
- Escalate: pre-mortem row B27 is stated as covered but is defeated by concurrent legitimate removal (Finding 1) — plan/pre-mortem should be corrected alongside the code, and the commit-message claim about `-f` checks (Finding 2) is inaccurate.
- Decisions I made: rated Finding 1 Medium not High, since the exec route is a pre-existing documented limit and the delta is warning-suppression + misleading note (alternative: High, treating the suppressed warning as an authz/detection bypass); treated the planted-bare-repo exec route as in-scope context rather than a separate finding, since it is unchanged by this diff (alternative: file it as its own Informational item).
