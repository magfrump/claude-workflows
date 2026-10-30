Commit: 28dfcd3b

# Security Review — fix/exit-scan-r6-hookspath (pass 3, final confirming)

**Scope:** `git diff d40e4bae..HEAD` (HEAD 28dfcd3b); security-relevant code: `devcontainer-config/cc-exit-scan.sh` (`_snap_cfg_hooks`, `_snap_cfg_hooks_file`, `_snap_entry_hooks`, the `git_exec_snapshot` hook-in), with `guides/cc-isolated-usage.md` and the new R6 bats test.
**Date:** 2026-10-25
**Based on:** the pass-2 reports (`r6-hookspath-p2-*.md`), read as advisory; no pass-3 code-fact-check report was supplied.

> ⚠️ **No code fact-check report provided** for this commit. Claims about security properties in comments and documentation have not been independently verified by code-fact-check. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator. The probes below were executed by this review.

How the probes ran: they are in `/tmp/claude-1000/-workspace/89c2ddf7-2b6b-41d6-b07b-ae5871fb9429/scratchpad/2026-10-25-exit-scan-r6-hookspath/sec-p3/probe.sh`. Each run used a fresh `mktemp -d` under that directory, `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL=<scratch file>`, `HOME=<scratch>`, and `LC_ALL` unset. The steps were: set up the launch state, take `before="$(git_exec_snapshot "$WS")"`, plant the hook, run `git_exit_scan "$WS" "$before"`, then run a real host `git commit` in the target tree. Each scenario ran against HEAD and against the base `d40e4bae` copy of `cc-exit-scan.sh`/`cc-gitdir.sh` (`SCANSRC=.../sec-p3/base`). Host git is 2.39.5.

## Trust Boundary Map

```
B1: session-written checkout (linked worktrees, embedded repos, .git entries) → git_exec_snapshot .git loop (find -mindepth 2 -name .git) → _snap_entry_hooks(g, wt)
B2: commondir file in a .git entry's git dir      → gitdir_common (cc-gitdir.sh)            → "$c/config" read by _snap_cfg_hooks
B3: config / include files (repo config, config.worktree, include[If].path targets) → git config --file --no-includes --null --list → _snap_rhv value set, cached in _snap_rhc by real path (new)
B4: core.hooksPath values (_snap_rhv)              → _snap_path(value, wt)                   → _snap_hooks → F records (hooksdir / hook) diffed at exit
B5: exit snapshot vs launch snapshot              → git_exit_scan / scan_std_worktrees      → rc 0 (host git allowed by the user) / 1 warning / 2 unsafe
```

Input-source classification:

```
S1: .git entries and their working-tree paths (find over the checkout)   — runtime-mutable (session writes) — UNTRUSTED for path construction / exec-adjacent sinks; trusted for nothing
S2: commondir file contents                                              — runtime-mutable — UNTRUSTED for path construction (fail-closed on unreadable: availability only)
S3: config and include file contents (inside the checkout)               — runtime-mutable — UNTRUSTED for path construction and as git-config parser input
S4: config files outside the checkout reached via an absolute commondir/include or ~/ (host files) — deploy-time from the scan's view (container cannot write) — trusted for availability, still parsed as data only
S5: $HOME (host user's)                                                  — deploy-time — trusted (path base for ~/ values)
S6: the launch snapshot string ($before)                                 — produced by the host at launch — trusted as the comparison baseline
```

What enters from outside: every byte in S1–S3, written by a same-uid session in the checkout. It becomes path strings, which feed `realpath`, `dirname` and `git config --file` as argv, and `find`/`stat` through `_snap_hooks`. Nothing is executed from it, and no shell re-parses it. The trust assumption this change rests on is that, for one config file, the set of hooksPath values is the same whichever path the file was reached by. That assumption holds for the values themselves, which resolve in the working tree. It does not hold for relative include paths: git resolves those against the directory of the path it opened, not the file's real path (Finding 1).

## Findings

#### 1. Real-path keying serves one path's include resolution for another path to the same config (symlinked config + relative include): false clean, hook runs

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:659`, `:673-674`, `:692` (new cache and seen set); the same keying already exists at `:484-485` (`_snap_config`)
**Boundary:** B3 → B4 → B5
**Move:** 4 (cached check vs use), 11 (bypass enumeration)
**Confidence:** High on the mechanism (executed). The route needs unusual launch-time state: a repo config that is a symlink to another repo's config and holds a relative include. A session cannot create that state at exit without changing a recorded `config` F/C record.
**Legibility-target:** whoever owns the "Known routes it does not see" list and `_snap_config`'s `c:` key.

Evidence (verbatim):
```
  real="$(realpath -m -- "$1" 2>/dev/null)" || real="$1"
  if [ -z "${_snap_rhc["$real"]:-}" ]; then
```
```
  [ -z "${_snap_rhseen["$real"]:-}" ] || return 0
  _snap_rhseen["$real"]=1
```
```
        t="$(_snap_path "$val" "$(dirname -- "$f")")"
```

`_snap_cfg_hooks_file` resolves a relative include against `dirname` of the path it was given, which matches git (config.c `handle_path_include` uses the opened path). The cache and the seen set, however, are keyed by the file's real path. When repo e2's `.git/config` is a symlink to e1's `.git/config` and that file has `include.path = inc.cfg`, git in e2 reads `e2/.git/inc.cfg` and git in e1 reads `e1/.git/inc.cfg`. Whichever path the scan meets first fills the cache entry, and the other path gets that set. `_snap_config` has the same keying at `c:$real`, so the include target under the other path is never recorded either.

Executed (`probe.sh symcfg e1 e2` and `symcfg zz aa`):
- Launch state: e1's config holds `include.path inc.cfg`, and `e1/.git/inc.cfg` is missing. e2's config is a symlink to e1's. `e2/.git/inc.cfg` holds `core.hooksPath = .sh`. `git -C e2 config core.hooksPath` printed `.sh`; e1 printed nothing.
- The launch snapshot has 0 records naming `e2/.sh` and 0 naming `e2/.git/inc.cfg`.
- Plant: `e2/.sh/pre-commit`. Result: `scan rc=0`, then a host `git commit` in e2 ran the hook (marker `sym`).
- The same probe on base `d40e4bae` also gives `rc=0` with the hook run. This change did not introduce the gap and did not widen it. The new walk copied the keying, so it does not close the gap either.

The variant a session can use without touching a recorded file needs that launch state already in place. The session then only creates `e2/.git/inc.cfg` and the hooks dir, and nothing records `e2/.git/inc.cfg`. Under Q-172 [2] this is an "unusual launch-time state" route, so the boundary does not require closing it. It is, however, not listed under "Known routes it does not see" (grep of the guide for symlink/config finds no such entry).

**Recommendation:** Either list the route in the guide ("a repo config that is a symlink, with a relative include, present at launch"), or key the cache, the seen set and `_snap_config`'s `c:` key by the pair (real path of `dirname` of the path given, real path of the file). That pair is exactly what git's resolution depends on, it stays finite, so cycles still terminate without a depth cap, and it costs at most one extra read per distinct directory.

#### 2. New fail-closed path: an embedded git dir whose `commondir` git cannot read now fails the whole snapshot (availability only)

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:714`
**Boundary:** B2
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** the guide's "One unlistable directory blocks the scan" class of entries.

Evidence: `  c="$(gitdir_common "$g")" || { _snap_fail 'cannot read the commondir file in %s' "$g"; return 1; }`

Executed (`probe.sh commondirdir`): an embedded repo with `.git/commondir` as a directory. HEAD returns `rc=1 cannot read the commondir file in …/ws/emb/.git`; base `d40e4bae` returns `rc=0`. Host git itself dies in that repo (`fatal: failed to read …/commondir: Is a directory`), so no hook can run there.
- At exit this is fail-closed (exit 2, "treat the checkout as untrusted"), which is the safe direction.
- At launch, a checkout that already holds such a broken repo (a fixture, a half-copied repo) now cannot get a baseline. That is an availability regression only; no security property is lost.

**Recommendation:** Optional. Mention the case under the guide's fail-closed entries, or skip the entry hooks for a git dir whose commondir git would itself reject (git cannot run hooks there). Not a merge blocker.

## Bypass candidates (move #11) for the new walk, inside the brief's R6 boundary

| # | Candidate | How tested | Result (HEAD) | Base d40e4bae |
|---|---|---|---|---|
| 1 | Repo `core.hooksPath = .husky/_`, agent worktree present at launch, plant `<wt>/.husky/_/pre-commit` | executed `probe.sh R6basic` | rc=1, `+ hook …/worktrees/x/.husky/_/pre-commit`; the hook ran only because the probe committed anyway | rc=0, hook ran |
| 2 | Value via include; config first met as an include of an embedded repo's config, then as the worktree's top config (both find orders, `aaa`/`zzz`) | executed `probe.sh incthentop aaa|zzz` | rc=1; both the worktree plant and the embedded-repo plant reported | n/a |
| 3 | Include cycle a.cfg → b.cfg → a.cfg (+ `config`) | executed `probe.sh cycle` | the scan terminated (rc=0, no plant possible: git itself dies, `exceeded maximum include depth`, so `worktree add` and every host git command fail) | n/a |
| 4 | Value only in the linked worktree's `config.worktree` (`extensions.worktreeConfig`) | executed `probe.sh wtcfg` | rc=1, `+ hook …/x/.wc/pre-commit` | n/a |
| 5 | Embedded repo with a relative hooksPath and its linked worktree elsewhere in the checkout | executed `probe.sh embwt` | rc=1 | rc=0, hook ran |
| 6 | Worktree added during the session plus a plant (Q-094 note path) | executed `probe.sh newwt [noplant]` | rc=1 warning, both with and without the plant (same status as base; the new walk adds `+ hooksdir`/`+ hook` lines, no note-only rc=0) | rc=1 |
| 7 | Absolute include path; file setting the value first met at depth 10 of an untaken includeIf chain | executed: bats `exit scan R6…` (ok), with `exit scan (Q-094|R6)` 13/13 ok under `env -u LC_ALL` | caught | — |
| 8 | Same config via a symlinked path with a relative include | executed `probe.sh symcfg` | **rc=0, hook ran** (Finding 1) | rc=0, hook ran |

On `_snap_rhs` reuse across calls (read statically): `_snap_entry_hooks` reads `_snap_rhs`/`_snap_rhn` right after each `_snap_cfg_hooks` call. The loop body calls only `_snap_path` and `_snap_hooks`, and neither writes those variables (all writers are at :662 and :666). `_snap_rhv` is append-only, so cached `start count` ranges stay valid. Values from a nested include are counted inside the including config's range and are not cached under the include's own key. A later top-level visit of that file therefore re-reads it into a fresh range, and the executed candidate 2 is consistent with that. Temp names `t.<#rhc>.<#rhseen>` are unique within a snapshot, because `#rhseen` grows within a walk and `#rhc` grows by one after each top walk.

On "walking more → false clean" (read statically, plus candidates 1-6): the new walk adds only F records, and `_snap_hooks` records entries under the real dir path whichever caller reaches it first, so the record keys do not depend on visit order. It writes none of `_snap_seen`'s `c:`/`g:`/`n:` marks, so it cannot suppress `_snap_config`/`_snap_gitdir`. The only order-dependent state it shares is `_snap_seen["h:…"]`, and that dedupes identical entry records. No candidate turned a launch state the old code reported into a clean result.

### Untested bypass candidates

- **A value set big enough to stall the exit scan** (thousands of distinct hooksPath values × many worktrees, or the O(n²) per-config dedupe at `:687`). Not executed. This is availability; the pre-existing `_snap_config` already pays one `_snap_hooks` per value, and the guide lists the route ("A slow scan").
- **`hook.<name>.command` (config-based hooks) with a relative command run from a linked worktree.** Not executed; host git 2.39.5 predates config-based hooks. It is a separate route, not core.hooksPath.
- **A huge or unbounded include chain in a config only this walk reads** (a container-form `.git`'s git dir, which `_snap_gitdir` does not hash under the size cap). Not executed. Availability only: a changed value still yields a new `hooksdir` record, and an unreadable file fails closed.

## Endorsement Claims

- **Claim:** A relative repo `core.hooksPath`, set directly, via include, or via `config.worktree`, is walked in a linked worktree or embedded repo's linked worktree present at launch, and a plant there gives rc=1 where base gave rc=0.
  **Location:** `devcontainer-config/cc-exit-scan.sh:712-721`, `:910`
  **Evidence:** executed
  **Verified:** probe scenarios R6basic, incthentop (both orders), wtcfg, embwt, each against HEAD and base; bats `exit scan (Q-094|R6)` 13/13 ok.
  **Not verified:** a worktree whose `.git` file uses a relative `gitdir:` (git ≥2.48 `worktree.useRelativePaths`) written by container git.
  **route: code-fact-check**
- **Claim:** The include walk terminates on an include cycle without a depth cap.
  **Location:** `devcontainer-config/cc-exit-scan.sh:673-674`
  **Evidence:** executed
  **Verified:** `probe.sh cycle` finished under `timeout 60` with rc=0.
  **Not verified:** a cycle through symlinked directories with distinct given paths (the key is the real path, so read-static says it terminates; not run).

## Primitive sweep

Primitive: process exec / path construction from S1–S3 (no shell re-parse in the diff)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:659` `realpath -m -- "$1"` | S2/S3 path | `--`, argv | cleared: argv, no exec of content |
| `cc-exit-scan.sh:676` `git --no-pager config --file "$f" --no-includes --null --list` (cwd `/`) | S2/S3 path, file content | `--file` takes the next argv as value; every path is absolute (`$c/…` from gitdir_common's `$d/…` or `/…`, `_snap_path` of an absolute dirname or `$HOME`); `--no-includes` | cleared: parse only, no exec; errors routed via `_snap_fail` as an argument, not the format |
| `cc-exit-scan.sh:690` `dirname -- "$f"` | S3 | `--` | cleared |
| `cc-exit-scan.sh:692` `realpath -m -- "$t"` | S3 include value | `--` | cleared; keying is Finding 1 |
| `cc-exit-scan.sh:714` `gitdir_common "$g"` (stat, read) | S2 | size/type checks in cc-gitdir.sh | Finding 2 (availability) |
| `cc-exit-scan.sh:718` `_snap_hooks "$(_snap_path …)"` → `find -P`, `stat`, `sha256sum` | S3 values, S1 wt | existing `_snap_file` size caps, `%q` records | cleared: pre-existing helper, read-only |
| `cc-exit-scan.sh:676` writes `$out`, `$out.err` | names from counters | inside `mktemp -d` | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Real-path cache/seen key gives one path's relative-include resolution to another path to the same symlinked config: false clean, hook ran (pre-existing in `_snap_config`, unlisted, outside the Q-172 closure boundary) | Medium | B3, B4, B5 | `cc-exit-scan.sh:659,673-674,692` (+`:484-485`) | High (executed) |
| 2 | Unreadable embedded `commondir` now fails the snapshot (fail-closed; launch availability only) | Informational | B2 | `cc-exit-scan.sh:714` | High (executed) |

## Overall Assessment

The rewritten walk closes R6 as the brief scopes it. Every R6 variant this review executed inside the boundary returns rc=1 at HEAD, where base returned rc=0 for the core cases: a direct value, a value through an include in either order, a cycle, `config.worktree`, an embedded repo's worktree, and a worktree added during the session. The per-config cache does not serve a stale or partial set in any of these orders, and `_snap_rhs` reuse is sound. The walk adds only records and fails closed on new error paths, so it does not turn a reported state into a clean one.

The one residual false clean (Finding 1) is a pre-existing route outside Q-172's closure boundary. The route needs a symlinked repo config with a relative include at launch, and the new cache copies the same real-path keying from `_snap_config`. The most useful follow-up is to list that route in the guide, or to key by (real dir of the given path, real file). Neither is required for this R6 change to merge. No findings block merge in the paths executed. The non-executed endorsement hop (container-written relative `gitdir:`) is named above.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/r6-hookspath-p3-security-review-2026-10-25.md in the worktree, structured per the security-reviewer skill, `Commit: 28dfcd3b` first line."
- **Answered:** I checked the cache's staleness and partial-set cases: include-then-top in both orders, cycles, the same file by two paths, and `_snap_rhs` reuse. Only the two-paths case fails (Finding 1, pre-existing). R6 variants inside the boundary: all caught, executed. New fail-closed paths: Finding 2. Walking more producing a false clean: none found.
- **Out of scope:** A14, R3's remote half, A16, core.worktree elsewhere, R4 (listed routes, not made worse).
- **Escalate:** none (no HALT pattern).
- **Questions/Decisions:** whether Finding 1 is listed in the guide or fixed by pair-keying, a follow-up for the route list owner.
