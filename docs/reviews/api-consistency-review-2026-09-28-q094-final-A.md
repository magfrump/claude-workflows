Commit: 9075003

# API Consistency Review: Q-094 unit A (exit-scan standard worktrees)

**Scope:** `dfe4c0d..9075003` on `q094-exit-scan-worktree-layout`, excluding `docs/reviews/`. Files: `devcontainer-config/cc-exit-scan.sh`, `devcontainer-config/cc-isolated.sh`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`, `docs/working/plan-q094-exit-scan-worktree-layout.md`
**Date:** 2026-09-28
**Based on:** Stage-1 merged code-fact-check summary (`scratchpad/A-fc-summary.md`, k=3 replicates). It found 0 behavioral Incorrect claims, one comment-only Incorrect claim (header :83-84), and several Mostly-accurate doc claims. This review relies on it for behavior and does not re-verify it.
**Delivery mode:** self-read. Nothing was executed beyond `git show`/`git diff`/`grep` on the branch.

## Baseline Conventions

These are the public and semi-public surfaces the unit touches, and what the codebase already does on each:

- **Launcher exit statuses** (`cc-isolated.sh:19-32`, guide "Exit status"). 0 means success, and after a session it passes claude's own status through. 1 is an error, 2 bad usage, 3 a scan finding, 4 a scan that could not finish. The only thing that maps `git_exit_scan` to an exit code is the `case "$scan"` block (`cc-isolated.sh:745-751`: 0 gives `exit "$rc"`, 1 gives 3, anything else gives 4). The help header and the guide both document every code.
- **Stderr messages.** Block warnings start with an upper-case `WARNING:` and a leading blank line (`cc-exit-scan.sh:911, 949, 976`), and every message that carries container-chosen text goes through `scan_vis`. One-line advisories elsewhere use an upper-case `NOTE:` (`cc-isolated.sh:620, 686`; `install.sh:1231, 1242`).
- **Tunable globals.** They are named `GIT_EXIT_SCAN_<THING>`, assigned unconditionally at file scope (so they are not environment-overridable), and overridden only by tests after sourcing (`cc-exit-scan.sh:116, 182-183`; `test/cc-isolated-functions.bats:2174`).
- **Function namespaces.** `scan_*` is the scan's entry-level API (`scan_git_dirs`, `scan_vis`, `scan_diff`, `scan_interrupted`). `_snap_*` names the "helpers [that] run inside git_exec_snapshot and share its locals" (`cc-exit-scan.sh:144-147`).
- **Snapshot record format** (`cc-exit-scan.sh:148-153`). This is an in-memory, tab-separated format with record types `F` and `C`. Its only producer is `git_exec_snapshot`, and its only consumers are `git_exit_scan`/`scan_diff` inside the same process run, so it is never persisted across versions (grep of the branch for `git_exec_snapshot|git_exit_scan` outside tests: only `cc-isolated.sh:672, 745`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `scan_std_worktrees` | function (scan entry-level) | `scan_git_dirs`, `scan_diff`, `scan_vis` | `devcontainer-config/cc-exit-scan.sh:120,745,752` | Consistent: `scan_<noun>` shape. `std` is a new abbreviation, but the doc comment spells it out. |
| `_snap_wrel` | function (snapshot helper) | `_snap_file`, `_snap_opt`, `_snap_hooks` | `cc-exit-scan.sh:222-320` | Consistent: runs inside `git_exec_snapshot`, appends to `_snap` |
| `_snap_hash_str` | function | `_snap_hash`, `_snap_first_line` | `cc-exit-scan.sh:167,205` | Minor: used only outside `git_exec_snapshot` (Finding 2) |
| `_snap_file_is` | function (predicate) | `_snap_inside_ws`, `gitdir_valid`, `looks_like_gitdir` | `cc-exit-scan.sh:298`; `cc-gitdir.sh` | Minor: same namespace issue (Finding 2); the predicate shape matches `_snap_inside_ws` |
| `GIT_EXIT_SCAN_CONTAINER_WS` | global | `GIT_EXIT_SCAN_MAX_FILE_BYTES`, `GIT_EXIT_SCAN_MAX_TOTAL_BYTES`, `GIT_EXIT_SCAN_KEYS_RE` | `cc-exit-scan.sh:116,182-183` | Consistent: prefix, unconditional assignment, tests override after sourcing; a test (bats:2383) ties its value to `devcontainer.json`'s mount target |
| `W` record type | schema enum | `F`, `C` | `cc-exit-scan.sh:149-150` | Consistent: a single upper-case letter, documented in the same table |
| `W` second field (`core.hookspath`, `core.attributesfile`, `url.*.insteadof`, `remote`) | schema field | `F`'s kind (`dotgit`, `hooksdir`, `remote`) | `cc-exit-scan.sh:149` | Informational: mixes config keys with a kind word; read only for presence (Finding 5) |
| `note: exit scan: … (added: <n> …)` | stderr message | `NOTE: …` one-liners, `WARNING: …` blocks | `cc-isolated.sh:620,686`; `install.sh:1231`; `cc-exit-scan.sh:949` | Lower-case differs from `NOTE:`. The user specified this format in a prior loop decision (won't-fix), so it is not re-filed. |

## Findings

#### 1. The guide's list of what "refuses the note" is narrower than what the code refuses

**Severity:** Minor
**Location:** `guides/cc-isolated-usage.md:345-351`; `devcontainer-config/cc-exit-scan.sh:80-84`
**Move:** 3 (consumer contract / documentation drift)
**Confidence:** Medium
**Legibility-target:** the user reading the guide to predict whether a left-behind agent worktree will warn

Evidence (guide):
> "also any other change in the session, a worktree removed during it, and **any checkout whose config holds a relative `core.hooksPath` or `core.attributesFile` (husky's `.husky/_`) or a relative local remote** other than `.`, which git would resolve in the new worktree's tree, unscanned."

Evidence (code, `cc-exit-scan.sh:417`):
```
        case "$t" in ""|.) _snap_wrel "$key" "$f" ./ ;; esac   # a base "" or "." starts a relative path
```

The fact-check replicates confirmed that W records also come from `url.<base>.insteadOf` with base `.` or `""`, and from the config of embedded repos anywhere in the working tree. Both of these refuse the note even though the guide says only "`.`" is exempt and names only "the checkout's config". A relative `core.hooksPath` in your own global config also makes a host-form worktree warn. The header comment says so at :83-84; the guide does not. All of these fail safe (they warn), so nothing is unsafe. But a user whose checkout vendors a husky-using embedded repo will never see the note and cannot tell why from the documented contract.

**Recommendation:** Add one clause to the guide's decline list: "…or an embedded repo's, or your global config's; an `insteadOf` base of `.` or empty counts as relative". Alternatively, say the list is illustrative and point at `scan_std_worktrees`, which the guide already names as holding "the full rule".

#### 2. The `_snap_*` namespace now has helpers that run outside `git_exec_snapshot`

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:776-791` (definitions), `:807-808` (the caller emulates the snapshot local)
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** the next maintainer adding a `_snap_*` helper or calling one

Precedent: "The _snap_* helpers below run inside git_exec_snapshot and share its locals (bash dynamic scoping) … Each returns 1 after printing a reason on stderr when something cannot be read" used in `devcontainer-config/cc-exit-scan.sh:144-147`

Evidence:
```
  local diff line rec q attrs n p hk dk k wtrel wt g h ok std re pre lnk _snap_bytes=0
```
`_snap_hash_str` and `_snap_file_is` are called only from `scan_std_worktrees`, which runs after the snapshot. `_snap_file_is` calls `_snap_size_ok`, and that function increments the dynamically scoped `_snap_bytes`. For that to work, `scan_std_worktrees` must declare `_snap_bytes=0` itself, a coupling the namespace comment does not mention. `_snap_file_is` also returns 1 silently for "does not match" (stderr is discarded), unlike the documented helper contract. `_snap_inside_ws` is an existing silent predicate, so the "prints a reason" half was already loose. This does not break any consumer; it is a namespace rule that is now false as written.

**Recommendation:** Either extend the :144 comment ("… or, for `_snap_hash_str`/`_snap_file_is`, inside `scan_std_worktrees`, which declares its own `_snap_bytes`"), or rename the two helpers outside the `_snap_` prefix (for example `scan_hash_str`, `scan_file_is`).

#### 3. The exit-0 contract of `git_exit_scan` and the launcher now covers "changed, but only standard worktrees"

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:20-23`; `cc-exit-scan.sh:898-903`; `guides/cc-isolated-usage.md:66-68, 75-77`
**Move:** 3/6 (a consumer contract change, the "changed endpoint behavior" case)
**Confidence:** High
**Legibility-target:** a script that reads the launcher's exit status

Evidence:
> "0  success; after a session: the exit scan found nothing (or only standard linked worktrees, with a note on stderr), and claude's own exit status is passed through"

A wrapper that took `3` to mean "the session left something in `.git`" (including worktrees) now sees `claude`'s status. This is the intended behavior change of Q-094 [1], and every surface that documents exit codes was updated together: help header, function doc, the guide's step 7 and the guide's "Exit status" paragraph. There is no versioning mechanism for the launcher beyond the decision log that the help cites ("decision log #58"). No Q-094 row was added there. That is optional, since the questions archive records the decision. Nothing to fix; recorded so the change is deliberate. The launcher-level test (`bats`, "ends the launcher with claude's status and a note") uses a stub that exits 0, so a non-zero claude status passing through on the note path is not tested separately. It is the same `0) exit "$rc"` arm as a clean scan, so the risk is low.

**Recommendation:** None required. Optionally, add a decision-log row pointing at Q-094 [1] beside #58.

#### 4. The note has no leading blank line, unlike every exit-scan WARNING

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:895, 935-937` (compare `:948`, `:975`)
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the user at the terminal after claude's TUI exits

Evidence:
```
  if [ -z "$invalid" ] && note="$(scan_std_worktrees "$ws" "$before" "$after" 2>/dev/null)"; then
    printf '%s\n' "$note" | scan_vis >&2
```
versus the WARNING block, which opens with `echo` then `echo "WARNING: this session changed …"`. Both are written to stderr right after claude exits. The warning is separated from the TUI's last frame and the note is not. This is cosmetic. The lower-case `note:` itself is the user's specified format (prior loop decision, won't-fix) and is not re-filed.

**Recommendation:** Optional: `{ echo; printf '%s\n' "$note"; } | scan_vis >&2` for symmetry, if the user's format decision allows the blank line.

#### 5. The `W` record's fields mix a config key and a kind word, and a config path and a value path

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:151-153, 290-294, 357`
**Move:** 2/7 (schema field consistency)
**Confidence:** High
**Legibility-target:** a maintainer extending the record table or `scan_diff`

Precedent: `F <kind> <path %q> <attrs>` uses a lower-case kind word (`dotgit`, `hooksdir`, `remote`) in `devcontainer-config/cc-exit-scan.sh:149, 222-260`

Evidence:
```
  [ "$p" = . ] || _snap_wrel remote "$p" "$p"
```
versus `_snap_wrel "$key" "$f" "$val"`. A `W` record's second field is either a config key (`core.hookspath`) or the kind word `remote`. Its third field is either the config file or the remote path itself. The table's `<config or path %q>` states the second mixture honestly. `scan_std_worktrees` reads only the presence of `W`, and `scan_diff` ignores it (its awk handles only `F`/`C`), so no consumer depends on these fields today.

**Recommendation:** None required. If `W` ever gets a reader of its fields, normalize it first, for example to `W <config key> <config %q>`, with remotes recorded under the config entry that named them.

## What Looks Good

- **Exit codes unchanged in shape.** No new status code was added. The note path reuses the existing `0) exit "$rc"` arm, and 1/2 keep their meanings, so the mapping to 3 and 4 in `cc-isolated.sh:747-751` is untouched.
- **Docs and code moved together.** The help header, the `git_exit_scan` doc comment (which now also documents the pre-existing "differ but nothing renders gives 2" case), the guide's step 7, the "Exit status" paragraph and a new guide section all describe the same contract. A launcher-level bats test pins the note text and status 0, and another test pins `GIT_EXIT_SCAN_CONTAINER_WS` to `devcontainer.json`'s mount target, so the two cannot drift silently.
- **The new global matches its siblings** in prefix, file-scope assignment and test-only override.
- **The `W` record is added safely.** It is documented in the record table, never rendered (so existing warning output is byte-for-byte unchanged when a worktree is not the only difference), and confined to an in-process format with no persisted consumers.
- **The note is sanitised the same way the warnings are** (`scan_vis`). Its only variable content is names already restricted to `[A-Za-z0-9._-]`.
- **Unrelated behavior is unchanged by the pipefail fix.** The `invalid` check moved from `printf | grep -q` to a `[[ =~ ]]` match with the same pattern semantics.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The guide's decline list omits embedded-repo/global config and `insteadOf` `.`/`""` | Minor | `guides/cc-isolated-usage.md:345-351` | Medium |
| 2 | `_snap_hash_str`/`_snap_file_is` break the `_snap_*` "inside git_exec_snapshot" rule | Minor | `cc-exit-scan.sh:776-791, 807-808` | High |
| 3 | Exit 0 now covers "standard worktrees changed" (intended, documented) | Informational | `cc-isolated.sh:20-23` | High |
| 4 | The note lacks the WARNINGs' leading blank line | Informational | `cc-exit-scan.sh:935-937` | High |
| 5 | `W` record fields mix key/kind and config/path | Informational | `cc-exit-scan.sh:151-153, 357` | High |

## Overall Assessment

The unit is consistent with the launcher's established public surface. It adds no exit code and does not change the meaning of any existing one. It extends only the documented meaning of 0, and every surface that lists exit codes was updated in the same commit range, with tests pinning the note and the status. The new global, function and record-type names follow their nearest neighbours. The two Minor items are both documentation or namespace precision, and each can be fixed in place in a line or two: the guide's decline list understates when the note is refused (which fails safe), and the `_snap_*` namespace comment is no longer true as written. Nothing blocks the merge.

## Goal-Alignment Note

Q-094 [1] aims to stop false-alarm warnings for agent worktrees while never letting a session make host git run something new without a warning. On the consumer-facing surface, the unit serves that aim. The warning path, its text and its exit code are untouched for every non-standard case. The only new user-visible outcome is one sanitised `note:` line with claude's status, and it is documented everywhere exit codes are. The residual gap (Finding 1) runs in the conservative direction: users will sometimes get the old warning where the guide suggests they would get the note, never the reverse.
