Commit: e1d7d912

# Security Review — fix/exit-scan-r6-hookspath (Q-168 R6, pass 2)

**Scope:** `git diff d40e4bae..HEAD` — `devcontainer-config/cc-exit-scan.sh` (new `_snap_tree_hooks`, `_snap_entry_hooks`, call site in `git_exec_snapshot`), `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`. Read in full: `_snap_hooks`, `_snap_path`, `_snap_worktree_of`, `_snap_config`, `_snap_host_config`, `_snap_dotgit_target`, `_snap_container_target`, `_snap_gitdir`, `_snap_dotgit`, `git_exec_snapshot`, `scan_std_worktrees`, `git_exit_scan`, and `cc-gitdir.sh` (`gitdir_common` and the rest).
**Date:** 2026-10-25
**Based on:** `docs/reviews/r6-hookspath-p1-code-fact-check-report.md` (pass 1, at cf15f4f9; its Incorrect items are reported fixed in e1d7d912)
**Probes:** git 2.39.5, `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL=<scratch file>`, `LC_ALL=`, scan sourced from this worktree. Scripts are in `/tmp/claude-1000/-workspace/89c2ddf7-2b6b-41d6-b07b-ae5871fb9429/scratchpad/2026-10-25-exit-scan-r6-hookspath/sec-p2/` (`p2.sh`, `p2c.sh`, `p3.sh`, `p5.sh`, `p6.sh`). Every probe ran in the foreground under `timeout`, and none was still running at the end (`ps` checked).

## Trust Boundary Map

```
B1 (moved): [session-written checkout: repo config + include targets, .git entries, commondir files]
            → [_snap_entry_hooks / _snap_tree_hooks: gitdir_common, git config --file --no-includes, include recursion]
            → [F hooksdir/hook records in the snapshot]
B2 (new):   [relative core.hooksPath value in repo config]
            → [resolution against a working-tree base: "$wt/$val", wt = "${f%/*}" of each .git entry]
            → [the dir host git actually runs hooks from (cwd of the git command = git's work tree)]
B3:         [launch snapshot vs exit snapshot]
            → [git_exit_scan / scan_std_worktrees: rc 0 note, rc 1 finding, rc 2 unreadable]
            → [the user's decision to run host git in the checkout]
```

Input sources:

```
S1: repo config, config.worktree, include/includeIf targets — written by the session at run time;
    before launch it is the baseline state. UNTRUSTED for every sink: path construction,
    which dirs the walk visits, and how deep it recurses
S2: .git entries and commondir files (contents and layout) — session-writable at run time;
    UNTRUSTED as the source of the git dir and common dir used for config lookup
S3: working-tree layout (find -P -name .git) — session-writable at run time; UNTRUSTED
    as the list of trees to walk
S4: $HOME (for "~/" values) — host, fixed for the launch — trusted to build paths
S5: include depth limit 10 — a code constant — trusted
```

Hooks git runs are decided by S1 and S2. The new code turns S1's relative `core.hooksPath` into a path that it walks in each tree S3 lists, under a base taken from S2. This diff adds no exec sink. Its security property is completeness. The scan fails open wherever B2's resolution disagrees with where git runs hooks, or wherever B1's recursion skips a file git reads. Either way a planted hook leaves no record, and B3 reports clean.

## Findings

#### 1. The per-worktree include walk dedupes before its depth check, so an unmatched `includeIf` chain hides a relative hooksPath

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:658-685` (lines 660-664 and 680-682)
**Boundary:** B1
**Move:** 11 (bypass enumeration), 3 (error/limit path)
**Confidence:** High that the mechanism works (executed). Low that it occurs: it needs a crafted launch-time state.
**Legibility-target:** the author of `_snap_tree_hooks` and the next reader of the guide's "Known routes" list.

**Evidence:**
```
  [ "$depth" -le 10 ] || return 0   # git's own include depth limit
  [ -f "$f" ] || return 0
  real="$(realpath -m -- "$f" 2>/dev/null)" || real="$f"
  [ -z "${_snap_seen["t:$real:$wt"]:-}" ] || return 0
  _snap_seen["t:$real:$wt"]=1
```
```
      include.path|includeif.*.path)
        # Any include, absolute or not: its relative hooksPath still resolves in <wt>.
        _snap_tree_hooks "$(_snap_path "$val" "$(dirname -- "$f")")" "$wt" $((depth + 1)) || return 1 ;;
```

The walk marks a file seen for each (file, worktree) pair whatever the depth it reached the file at, and it follows every `includeIf` without evaluating the condition. Take a file X that it first reaches at depth 10 through an `includeIf` whose condition does not match. X's own includes, at depth 11, are dropped. When X is reached again later at depth 1, it is skipped as already seen. Git does not follow the unmatched chain. It includes X at depth 1 and X's child Y at depth 2, and takes Y's `core.hooksPath = .evil` from Y. The scan never walks `<worktree>/.evil`. `_snap_config` does walk Y, because it has no depth cap, but it resolves Y's value only in the main working tree. Probe `p2.sh` used this launch state: `includeIf.gitdir:/nomatch/.path = a1.cfg`, a chain a1…a9 → X → Y, then `include.path = X.cfg`, and a linked worktree at `.claude/worktrees/agent-x`. After a hook was planted at `agent-x/.evil/pre-commit`: `git config core.hooksPath` in the worktree gave `.evil`, the launch snapshot held 0 records naming `agent-x/.evil`, the **exit scan returned rc=0**, and `git commit` in the worktree **ran the planted hook**. The control (`p2c.sh`) dropped only the `includeIf` line and got rc=1. The session cannot set this state up within one session, because every config and include file involved is recorded by `_snap_config`, so the edits would themselves be a finding. The state has to exist at launch, for example left by an earlier flagged session that was not cleaned up. Under Q-172 [2] that makes it a route to list. But it comes from a defect in this walk, not from git's own semantics, and the fix is one line.

**Recommendation:** Drop the depth cap. Git dies on any followed chain deeper than 10, so walking past 10 only over-walks, which is how `_snap_config` already behaves. Alternatively, include the depth in the seen key (or re-walk when a file is reached at a shallower depth). Add the `p2.sh` shape as a bats case.

#### 2. The per-worktree walk ignores `core.worktree`: hooks run from `<core.worktree>/<value>`, and the walk resolves `<.git entry dir>/<value>`

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:885` (base `"${f%/*}"`), `:693-697`, `:679`. The guide's "Known routes" list (`guides/cc-isolated-usage.md:420-505`) does not mention it.
**Boundary:** B2
**Move:** 1 (trust boundary: which base git resolves against), 11
**Confidence:** High that the mechanism works (executed). Low that it occurs: it needs an unusual launch-time state.
**Legibility-target:** the guide's "Known routes" list, which Q-172 [2] says must name this kind of launch-time route.

**Evidence:**
```
      # The repo's own relative hooksPath, as it applies in this working tree.
      [ -z "$g" ] || _snap_entry_hooks "$g" "${f%/*}" || { rc=1; break; }
```
```
        case "$val" in /*|"~/"*) ;; *) _snap_hooks "$wt/$val" || return 1 ;; esac ;;
```

Git resolves a relative `core.hooksPath` against the cwd of the command, and that is git's work tree. When `core.worktree` is set, the work tree is not the directory that holds the `.git` entry. Probe `p3.sh` used ordinary husky `core.hooksPath = .husky/_` in the repo config, plus `extensions.worktreeConfig = true` and `git -C <wt> config --worktree core.worktree <ws>/other` (the unusual part). `rev-parse --show-toplevel` from the worktree gave `<ws>/other`. The launch records walked `agent-x/.husky/_` and `<ws>/.husky/_`, never `<ws>/other/.husky/_`. With a hook planted there, the **exit scan returned rc=0** and `git commit` run in the worktree **ran it**. `_snap_config` follows `core.worktree` only when it sits in the same file as the hooksPath (`_snap_worktree_of`), so here it walks the per-worktree `config.worktree` and not the common config's hooksPath. Setting `core.worktree` during the session is recorded as a C change, which is a finding, so the gap is launch-time only. This diff does not make anything worse: the main working tree already ignores `core.worktree` (`_snap_worktree_of` returns `$_snap_ws` for the git dir and the common dir). But the change claims to close R6 for every working tree that uses the config, and this is a working-tree base that differs from the `.git` entry's directory. The guide neither closes it nor lists it.

**Recommendation:** List it in "Known routes it does not see" ("a `core.worktree` present at launch, in the repo config or a worktree's `config.worktree`: relative `core.hooksPath` is walked under the `.git` entry's directory, not under the work tree git uses"). Or resolve the base from `core.worktree`, last value wins, across the common config, `config.worktree` and their includes, and walk both bases.

#### 3. New fail-closed path: an embedded repo's empty or non-regular `commondir` now refuses launch

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:693-697`; `devcontainer-config/cc-gitdir.sh:55-60`
**Boundary:** B1, B3
**Move:** 3 (error path), 8
**Confidence:** High (executed)
**Legibility-target:** the guide entry "One unlistable directory blocks the scan".

**Evidence:**
```
  c="$(gitdir_common "$g")" || { _snap_fail 'cannot read the commondir file in %s' "$g"; return 1; }
```
```
  [ -f "$c" ] && [ -r "$c" ] || return 1
  s="$(stat -c %s -- "$c" 2>/dev/null)" || return 1
  [ "$s" -gt 0 ] && [ "$s" -le 4096 ] || return 1
```

Probe `p5.sh` used `vendor/fixture/.git/commondir` as an empty file, present at launch. The old scan (d40e4bae) gave a launch snapshot rc=0. The new one gives rc=1 with `cannot read the commondir file in …/vendor/fixture/.git`. Host git in that repo exits 128, so the refusal matches git and nothing reads as clean: the error goes through `rc=1; break` and then `return 1`, which `git_exit_scan` maps to rc 2. A session can use this to make the exit scan fail and the next launch refuse. That is the same availability class the guide already documents for an unlistable directory (one `chmod 000` does it), so it is not a new capability. The guide entry could mention it.

**Recommendation:** Optional: add "or an embedded repo whose `commondir` git cannot read" to the "One unlistable directory blocks the scan" entry. No code change.

### Checked and not filed

- **Over-walk cannot produce a false clean.** `config.worktree` is read whether or not `extensions.worktreeConfig` is set, and every `includeIf` is followed. That only adds records. `_snap_hooks` dedupes on the real path (`h:$real`), but it records entries under `$real/…` whichever walk reaches them first, so walk order changes no record (read-static). A false clean would need the exit walk's `$wt/$val` strings to equal launch strings with the same contents. That is a hook that existed at launch, which is the documented "Anything present at launch" route.
- **Path escape.** `$wt/$val` with `..` can walk directories outside the checkout. This is read-only find/stat/sha256, bounded by the 64 MiB / 1 GiB caps, which fail closed. `_snap_config:500` already does the same for the main tree, so this is not new exposure.
- **A14, R3 remote half, A16** are out of scope as briefed, and this change does not worsen them.

## Untested bypass candidates (move 11)

| Candidate | Why not tested |
|---|---|
| Container-form `.git` (target git dir's config not recorded by `_snap_config`): the session edits that config's hooksPath so `$wt/$val` equals a string walked at launch (e.g. `sub/.git/hooks` of a nested repo) | Traced statically. The only reachable effect is that hooks already present at launch run in a new context ("Anything present at launch"). Not executed. |
| CR-terminated `commondir` / `.git` line (git strips the CR, the scan's first-line reads do not) | Known as Q-168 tech-debt T1 and listed in the guide. `gitdir_common` strips the CR as git does, so the new walk partly sees through it. |
| `%(prefix)/` include paths and `~user/` hooksPath values | Covered by the guide's "`~` forms" entry. `%(prefix)` names a host-install path the container cannot write. |
| Empty `core.hooksPath =` after a relative one (git 2.39 then resolves `/<hook>`) | Static reading of git's `replace_dir`. The target is outside the checkout, and the scan over-walks the earlier value. |
| `GIT_DIR` / `GIT_WORK_TREE` in the user's host environment | Host-controlled, not session-reachable. |

Tested and detected (executed, rc=1, and the hook would have run): the R6 baseline (bats); an include named by an absolute path (bats); an embedded repo's linked worktree elsewhere in the checkout (`p6.sh` V1); `includeIf "onbranch:"` in a linked worktree (V2); a hooks dir planted as a symlink to a directory (V3); a worktree added during the session with the hook planted in it, which the W record refuses for the note (V4).

## Endorsement Claims

- **Claim:** With a relative repo `core.hooksPath` (direct, through an include, or through `includeIf onbranch:`), a hook planted in a linked worktree present at launch, in an embedded repo's linked worktree, behind a symlinked hooks dir, or in a worktree added during the session makes `git_exit_scan` return 1.
  **Location:** `devcontainer-config/cc-exit-scan.sh:658-697, 885`
  **Evidence:** executed
  **Verified:** `p6.sh` V1-V4 and the new bats case's shapes, each followed by a real host `git commit` in the tree.
  **Not verified:** the shapes in Findings 1 and 2 (which fail), and container-form `.git` targets outside `.git/`.
  **route: code-fact-check**
- **Claim:** Each new failure branch (`gitdir_common` failure, a config `git config --file` cannot read, `_snap_hooks` failure) propagates to `git_exec_snapshot` returning 1.
  **Location:** `devcontainer-config/cc-exit-scan.sh:666-669, 679, 682, 695-696, 885`
  **Evidence:** executed for the `gitdir_common` branch (`p5.sh`); read-static for the other branches.
  **Verified:** `p5.sh` rc=1, plus the `|| return 1` / `|| { rc=1; break; }` chain read in full.
  **Not verified:** an unparseable `config.worktree` reached only through this walk was not executed.

## Primitive sweep

Primitive: process exec / path construction from session-controlled config values

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:666` `git config --file "$f" --no-includes` | S1, S2 (`$f` = `$c/config`, `$g/config.worktree`, or an include path) | `cd /`, `--no-includes`, `$f` as its own argv element; `$f` is absolute or `$dir/…`, so it never starts with `-` | cleared |
| `cc-exit-scan.sh:679` `_snap_hooks "$wt/$val"` | S1 value, S3 tree | none on `..` | cleared (read-only, bounded by caps, same as `_snap_config:500`); base choice → Finding 2 |
| `cc-exit-scan.sh:682` `_snap_path "$val" "$(dirname -- "$f")"` | S1 | depth ≤ 10, seen-key | Finding 1 |
| `cc-exit-scan.sh:695` `gitdir_common "$g"` | S2 | size/type checks in cc-gitdir.sh | Finding 3 (fail closed, informational) |
| `cc-exit-scan.sh:662` `realpath -m -- "$f"` | S1/S2 | `--` | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Seen-before-depth dedupe plus unmatched `includeIf` hides a relative hooksPath in linked worktrees | Medium | B1 | `cc-exit-scan.sh:660-664, 680-682` | High (mechanism; launch-time state) |
| 2 | Walk base ignores `core.worktree`; not listed in the guide | Medium | B2 | `cc-exit-scan.sh:885, 679` | High (mechanism; launch-time state) |
| 3 | Empty or non-regular embedded `commondir` now refuses launch (git also dies there) | Informational | B1, B3 | `cc-exit-scan.sh:695` | High |

## Overall Assessment

The change does what R6 asks for the ordinary case: husky `.husky/_` in agent worktrees, embedded repos' worktrees, includes, `onbranch:`, symlinked hooks dirs, and new worktrees are all caught (executed). It adds no exec sink and no path that reads as clean on error. Both Medium findings need launch-time state that a session cannot create unseen, so neither is an open in-session route under the Q-172 [2] boundary. Finding 1, though, is a defect of the new walk itself, with a one-line fix (drop the depth cap, as `_snap_config` already does). Finding 2 is a working-tree base the guide neither closes nor lists, and Q-172 [2] requires such routes to be listed. The most important thing to address is Finding 1, with a regression test, then the guide line for Finding 2. Both are fixable in place, and neither points to an architectural problem.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/r6-hookspath-p2-security-review-2026-10-25.md in that worktree, structured per the security-reviewer skill, `Commit: e1d7d912` first line."
- **Answered:** the R6 variants listed under "Look especially at". Worktree bases other than the `.git` entry's directory → Finding 2. includeIf targets → covered (V2), and the dedupe interaction → Finding 1. config.worktree → over-walk, no false clean. Symlinked hooks dirs → covered (V3). Nested worktrees of embedded repos → covered (V1). Worktrees created during the session → covered (V4). A change to a config read only by this walk → traced, listed as untested, reaches only launch-present hooks. New fail-closed paths → Finding 3, and none reads as clean. Over-walk making a launch-valid state a false clean → not found (reasoning under "Checked and not filed").
- **Out of scope:** A14, the R3 remote half, A16 (as briefed). The pre-existing `core.worktree` gap for the main working tree, noted only in Finding 2's context. Performance.
- **Escalate:** none (no HALT patterns).
- **Questions/Decisions:** Finding 2 needs a choice: list it under Q-172 [2] (cheap) or resolve `core.worktree` in the walk (code plus tests). The reviewer's lean is to list it, since the main tree has the same gap.
