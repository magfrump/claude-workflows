Commit: 9075003

# Security Review: Q-094 unit A (`q094-exit-scan-worktree-layout`)

**Scope:** `dfe4c0d..9075003` excluding `docs/reviews/`: `devcontainer-config/cc-exit-scan.sh`, `cc-isolated.sh` (help text), `guides/cc-isolated-usage.md`, the plan and the tests. Surrounding context read: all of `cc-exit-scan.sh` (lines 1-981) and the session/scan tail of `cc-isolated.sh` (690-760).
**Date:** 2026-09-28
**Based on:** the Stage-1 merged fact-check summary (`scratchpad/A-fc-summary.md`, k=3). Experiments were run on git 2.39.5 against `git archive q094-exit-scan-worktree-layout`, with scripts under `scratchpad/crA-sec7q/x{1..5}/run.sh`.

## Trust Boundary Map

```
B1: [container session: .git/worktrees/<n>/*, <wt>/.git, working trees] → [exit snapshot git_exec_snapshot + scan_std_worktrees] → [note + status 0, or WARNING + 3]
B2: [status 0 / "this is not a finding" note]                           → [user's decision to run host git in <wt>] → [host git: .git-file resolution, common-dir hooks]
B3 (new): [host state outside the checkout: whether the container path /workspace/... resolves, the user's own global config] → [container-form acceptance, scan_std_worktrees:878-887] → [what host git resolves in <wt> later]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | Files under the checkout: `P = <common>/worktrees/<n>` contents, `<wt>/.git`, the files in `<wt>` | request-time (the session writes them) | UNTRUSTED for all sinks: hook execution, file reads (FIFO/size), path construction |
| S2 | Repo config (common `config`, includes) | runtime-mutable by the session, but diffed against the baseline | UNTRUSTED. Any change refuses the note (C/F record), and relative paths in it make W records |
| S3 | The user's global/system config (`_snap_host_config`) | host-only; the user can change it | Its content is trusted, but its **relative** `core.hooksPath`/`core.attributesFile` values resolve into S1 and are UNTRUSTED toward hook execution |
| S4 | Host filesystem outside the checkout: whether `$GIT_EXIT_SCAN_CONTAINER_WS/...` exists | user-mutable at any time after the scan | trusted content, but **time-varying**: a check made at scan time does not bind what host git later resolves |
| S5 | `GIT_EXIT_SCAN_CONTAINER_WS=/workspace` | code constant | trusted |

The diff adds a new pass decision on B1: record-level differences that used to warn now return 0 with a note. The note is only as strong as the set of things the exit snapshot actually walked for the new worktree. For a container-form worktree, that set depends on S4 at scan time, while host git's behavior depends on S4 (and on the user's `git worktree repair`) later. That is where the one finding sits.

## Findings

#### 1. Container-form worktree: the note skips the relative `core.hooksPath` from your own config, and a later `git worktree repair` (or a `/workspace` path) runs the planted hook

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:878-887` (container form accepted), which depends on `:547` (`_snap_dotgit_target`: `[ -d "$g" ] || return 0`) and `:700-701` (host config walked only when the target resolves); also the note text at `:895`, the header at `:83-84`, and `guides/cc-isolated-usage.md:343-347`.
**Boundary:** B3 → B2
**Move:** 11 (bypass enumeration), 4 (TOCTOU: a check at scan time, a use later)
**Confidence:** High (run on git 2.39.5)
**Legibility-target:** the maintainer of the container-form rule in `scan_std_worktrees`, and a guide reader whose global config has a relative `core.hooksPath` (for example `.githooks`)

**Evidence (verbatim):**
```
    for g in "$p" ${ccommon:+"$ccommon/worktrees/$n"}; do
      h="$(_snap_hash_str "gitdir: $g"$'\n')"
      re="^file [0-7]+ $h\$"
      if [[ "$attrs" =~ $re ]] && _snap_file_is "$wt/.git" "$h"; then ok="$g"; break; fi
    done
    [ -n "$ok" ] || return 1
    # The container form names a host path too: if it exists, it must be P.
    if [ "$ok" != "$p" ] && { [ -e "$ok" ] || [ -L "$ok" ]; }; then
      [ "$(cd "$ok" 2>/dev/null && pwd -P)" = "$p" ] || return 1
    fi
```
and in the snapshot, `:700-701`:
```
      g="$(_snap_dotgit_target "$f")" || { rc=1; break; }
      [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}" || { rc=1; break; }
```
Experiment output (`x1/run.sh`, `x2/run.sh`). The global config holds `core.hooksPath = .githooks`, the container path is absent, and `<wt>/.githooks/pre-commit` is planted:
```
note: exit scan: only linked worktrees in git's standard layout changed (added: agent-x). They take config and hooks from the checkout's own .git, so this is not a finding.
scan rc=0
--- host git in the worktree now (container path absent):
fatal: not a git repository: .../x2/cws/.git/worktrees/agent-x
--- user runs git worktree repair on the host:
repair: gitdir incorrect: .git/worktrees/agent-x/gitdir
repair: .git file broken: .../x2/ws/.claude/worktrees/agent-x
gitdir: .../x2/ws/.git/worktrees/agent-x
PLANTED-HOOK-RAN
[ax bd812d1] t
```
Control (`x3/run.sh`): the same plant in a host-form worktree warns (`+ hooksdir .../agent-x/.githooks dir 755`, `+ hook .../pre-commit`). The scan does detect this plant; it only misses it in the container form.

The snapshot walks your own config's relative `core.hooksPath`/`core.attributesFile` (and `includeIf gitdir:` targets inside the checkout) for a worktree only when its `.git` resolves on the host at scan time. A worktree made by container git has the container form (`gitdir: /workspace/.git/worktrees/<n>`). On a host whose checkout is not at `/workspace`, that form does not resolve, so the worktree's tree is never walked. `scan_std_worktrees` then accepts the form and prints "this is not a finding". Plan B14 and the fact-check (Incorrect, `:83-84`) call this safe because host git refuses the worktree ("not a git repository"). That holds only at scan time. The user can make the form resolve later, in either of two ways. They can run `git worktree repair` in the checkout, which is the standard fix for exactly that error: it runs no hook, infers the admin dir from `<n>` and rewrites `<wt>/.git` to the host path. Or they can create a `/workspace` path that points at the checkout. After either, the next host `git commit` in the worktree runs the session-planted hook as the user. Before unit A, the same state warned (`+ dotgit`, `+ commondir-file`), so this pass decision is new. The attack needs a user whose own config has a relative `core.hooksPath` or `core.attributesFile`, the configuration the scan already supports (header `:64-66`). With `attributesFile`, the planted attributes can only select drivers the user has already configured.

**Recommendation:** Evaluate the container form the way it would behave once repaired. When the only match is `ccommon/worktrees/<n>`, run `_snap_host_config "$p" "$wt/.git" "$wt"` in the exit snapshot (key it off the `gitdir:` line naming `$ccommon/worktrees/<n>` with `P` present), so that relative host-config paths produce `+hooksdir`/`+attributes` records and refuse the note. The simpler alternative is to refuse the container form whenever your own config, includes followed, has any relative `core.hooksPath`/`core.attributesFile`. Either way, correct the header (`:83-84`), the guide (`:343-347`) and plan B14, and add a bats case using the `x2` sequence (container form, relative global hooksPath, plant, then `git worktree repair`).

## Bypass candidates for `scan_std_worktrees` (move 11)

| # | Candidate | How dispositioned | Outcome |
|---|---|---|---|
| a | Container-form `.git` plus a relative host `core.hooksPath`, repaired later | executed (`x1`, `x2`, control `x3`) | **Finding 1** |
| b | Per-worktree `P/modules/<sm>` git dir with a hook (in a linked worktree, `modules/` is per-worktree) | executed (`x5` c) | WARNING: `_snap_nested P/modules` records it |
| c | `P/rebase-merge/git-rebase-todo` with an `exec` line | executed (`x5` e) | WARNING (sequencer record) |
| d | Working tree reached through a symlink in the checkout (`ws/lnk -> outside`, `P/gitdir = ws/lnk/wt/.git`) | executed (`x5` d) | WARNING: `find -P` never produces a `dotgit` record under the link, so the `dk` lookup fails |
| e | `url."file://".insteadOf` / `url."file://.".insteadOf`, which make no W record (`_snap_remote` strips the scheme to `""`/`.`) | executed (`x4`): W count 0 for both, 1 for `""` and `.`. On git 2.39.5, `file://<rest>` takes the part before the first `/` as the host and uses an absolute path (`zz:sub/r.git` → `fatal: '/r.git' ...`) | cleared: a `file://` rewrite cannot give a working-tree-relative path. (The rewritten URL is unwalked anyway, a documented limit.) |
| f | Second working tree whose `.git` also says `gitdir: P` | traced (`:873-887`): the extra `+dotgit` stays in `left` without `used` | declines (read-static) |
| g | `P/config.worktree`, `P/hooks`, `P/config`, a symlink in P | traced (`:852-853`) | declines (read-static; fact-check replicates executed E-series) |
| h | FIFO or oversized `P/gitdir`, `<wt>/.git` or `P/commondir` | traced (`:856-858`, `_snap_file_is`) | declines before the read (read-static) |

### Untested bypass candidates

- **Case-insensitive host filesystem (macOS Docker Desktop).** `%q` string comparisons against `find` output, and `[ ! -e "$p/hooks" ]` on names that differ only in case. Not tested because there is no such filesystem here. By reading, a case mismatch makes the `dk` lookup miss (declines).
- **Container git ≥ 2.48 with `worktree.useRelativePaths`.** Relative `gitdir:` lines. Not tested because only git 2.39.5 is available. By reading, the `case "$line"` at `:864-867` rejects them (declines).
- **Content of `P/index` (split-index `link`, untracked cache, gitlink entries).** Not tested. A gitlink's submodule dir under `<wt>` would be found by the embedded `.git` search. No exec path was identified.
- **A process left in the still-running container that changes P between the exit snapshot and `scan_std_worktrees`'s re-reads (or after).** Not tested. It is covered by the documented "After the scan" limit, and a plain clean scan is equally exposed.

Because of Finding 1 and the untested candidates above, `scan_std_worktrees` as a whole does not appear under Endorsement Claims.

## Endorsement Claims

- **Claim:** The `invalid` check in `git_exit_scan` no longer uses `printf | grep -q`, so pipefail cannot make an early match read as "no match".
  **Location:** `devcontainer-config/cc-exit-scan.sh:927-929`
  **Evidence:** read-static
  **Verified:** read the regex `$'(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid'` and the `gitdir-valid` record producer at `:681-682`. The `%q`'d path field holds no raw tab or newline.
  **Not verified:** behavior under the launcher's `set -o pipefail` with an invalid gitdir at exit. The fact-check notes that no pipefail test covers this regex (plan B28).
  **route: code-fact-check**
- **Claim:** `_snap_worktree_of` does not open a non-regular config path with `git config --file` (the FIFO guard).
  **Location:** `devcontainer-config/cc-exit-scan.sh:328`
  **Evidence:** read-static
  **Verified:** `[ -f "$1" ] &&` precedes the `git config` call. `-f` follows symlinks, so a link to a FIFO also fails the test.
  **Not verified:** the caller at `:608`/`:611` (the legacy-remote path passes `$real/config`, which may be absent). That falls to the `.git`-suffix/`gd` branches.
- **Claim:** A difference that includes any record other than `+F dotgit`, `+F commondir-file` or `+F hooksdir`, or any W record in the exit snapshot, makes `scan_std_worktrees` return 1.
  **Location:** `devcontainer-config/cc-exit-scan.sh:814, 828-835, 890`
  **Evidence:** executed (candidates b, c, d above; fact-check E-series)
  **Verified:** three plants beside a standard worktree produced a WARNING, and the pattern checks were read.
  **Not verified:** whether the record set covers every per-worktree file host git executes from (the `P/index` extensions above).
  **route: code-fact-check**

## Primitive sweep

Primitive: read/stat/hash of container-chosen paths (blocking FIFO, oversized file, symlink following), in unit A's new code

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:818` `scan_git_dirs "$ws"` | S1 | the same `_snap_first_line` size cap as the snapshot | cleared: same function as the launch/exit snapshot |
| `:852` `_snap_file_is "$p/commondir"` | S1 | `-f`, `! -L`, `_snap_size_ok`, full hash | cleared |
| `:853` `[ ! -e ] && [ ! -L ]` on hooks/config/config.worktree | S1 | existence tests only | cleared |
| `:854` `find -P "$p" -type l -print -quit` | S1 | `-P` (no follow); a failure declines | cleared |
| `:857-859` `stat`, `_snap_first_line`, `_snap_file_is` on `P/gitdir` | S1 | `-f`/`! -L` first, a 4097-byte cap, a full-content hash | cleared (the only race is the documented "After the scan" process) |
| `:879` `_snap_file_is "$wt/.git"` | S1 | `wtrel` rejects `.`/`..`/`//`, a symlink component fails the `dk` lookup (candidate d), `-f`/`! -L` | cleared |
| `:885-886` `cd "$ok" && pwd -P` | S1/S4 | only when the container-form path exists | cleared for reading. The *absence* branch is Finding 1 |
| `:328` `git config --file "$1"` (in `_snap_worktree_of`) | S1 | `-f` added by this diff | cleared |

Primitive: process exec. Unit A adds none. The only exec reached is the unchanged `git config --file ... --no-includes` from `/`.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Container-form worktree: your own config's relative hooksPath is never walked, the note returns 0, and after `git worktree repair` host git runs the planted hook | Medium | B3 → B2 | `cc-exit-scan.sh:878-887` (with `:547`, `:700-701`, `:895`; guide `:343-347`) | High |

## Overall Assessment

The unit's refusal logic is tight where it applies. Every experiment that planted something beside a standard worktree (per-worktree `modules/`, a sequencer todo list, a symlinked working-tree path) warned. Earlier-loop hazards (pipefail, FIFOs, size) are guarded in the new code, and the `file://` insteadOf spelling that escapes the W rule was traced and does not yield a working-tree-relative path. One pass decision is unsound: the container form, the common case for agent worktrees whenever the host checkout is not at `/workspace`. It is judged by whether host git can use the worktree *at scan time*, and the snapshot never walks your own config's relative hook paths for it. A single `git worktree repair` (git's own fix for the resulting error) turns it into a worktree whose planted hooks run, and unit A has already printed "this is not a finding" for it. This can be fixed in place: walk host config for the container form, or refuse it when that config has a relative hooksPath/attributesFile. It does not point to an architectural problem. Fix Finding 1 before merge, or at least document it and exclude that case. Otherwise: no further findings within the code paths read, and the endorsement claims are pending execution verification.

## Goal-Alignment Note

The goal is that a sandboxed session cannot make host git run something new without a warning. Unit A serves that goal for host-form worktrees and for every repo-config route (W records). It misses one route, Finding 1, where the warning is replaced by a reassuring note and the hook runs after an ordinary user repair step. The fix is small and local to the container-form branch plus one snapshot hook-up, so this is a merge-after-fix, not a redesign. Unit B (removal) was not reviewed here.
