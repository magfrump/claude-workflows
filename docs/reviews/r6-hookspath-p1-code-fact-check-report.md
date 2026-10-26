Commit: cf15f4f9

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-2026-10-25-exit-scan-r6-hookspath`, branch `fix/exit-scan-r6-hookspath`)
**Scope:** full-branch diff `git diff d40e4bae..HEAD` (one commit, cf15f4f9): `devcontainer-config/cc-exit-scan.sh`, `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`, and the commit message
**Checked:** 2026-10-25
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 27 (24 numbered; 3, 22 and 23 split into a/b)
**Summary:** 14 verified, 6 mostly accurate, 1 stale, 5 incorrect, 1 unverifiable

Environment: git 2.39.5, bash 5.2, in the container. Every probe used `GIT_CONFIG_NOSYSTEM=1` and `GIT_CONFIG_GLOBAL=<scratch file>` with `HOME` set to a scratch directory. Captured output is under `/tmp/claude-1000/-workspace/89c2ddf7-2b6b-41d6-b07b-ae5871fb9429/scratchpad/2026-10-25-exit-scan-r6-hookspath/fc-p1/logs/` (called `<logs>` below). It is scratch, outside the repo, because this pass may write only this report. Probe scripts are in the parent `fc-p1/` directory (`probe.sh`, `probe2.sh`, `a14/p.sh`, `a15c/p.sh`, `timing/t.sh`). The "old scan" is `git show d40e4bae:devcontainer-config/cc-exit-scan.sh`, placed in a scratch copy of `devcontainer-config/` (`fc-p1/old/`).

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`): read. None of its 8 patterns (corpus statistics, test-count denominators, consumer lists) resembles any claim here.

Legibility-target tags: **maintainer** means a reader of the scan's code comments. **user** means a reader of the guide who decides whether to run host git. **reviewer** means a reader of the research doc or commit message who judges the change.

---

## Claim 1: "A relative core.hooksPath in repo config is walked in each working tree that uses that config, every linked worktree and `.git` entry in the checkout included (_snap_entry_hooks)."

**Location:** `devcontainer-config/cc-exit-scan.sh:61-64`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a relative `core.hooksPath` written directly in a repo's `config`/`config.worktree`, or in a file included from it by a relative `include.path`/`includeIf` value. It does not cover a relative `core.hooksPath` inside a file the repo config includes by an absolute or `~/` path. Such a value is walked only in the main working tree, and the route stays live.
**Legibility-target:** maintainer

The per-entry walk exists and is called for every `.git` entry the working-tree find returns:

```bash
# devcontainer-config/cc-exit-scan.sh:876-878
      [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}" || { rc=1; break; }
      # The repo's own relative hooksPath, as it applies in this working tree.
      [ -z "$g" ] || _snap_entry_hooks "$g" "${f%/*}" || { rc=1; break; }
```

`_snap_tree_hooks` skips every absolute or `~/` value before it dispatches on the key, include keys included:

```bash
# devcontainer-config/cc-exit-scan.sh:671-675
    case "$val" in ""|/*|"~/"*) continue ;; esac   # walked once, by _snap_config
    case "$key" in
      core.hookspath) _snap_hooks "$wt/$val" || return 1 ;;
      include.path|includeif.*.path)
        _snap_tree_hooks "$(_snap_path "$val" "$(dirname -- "$f")")" "$wt" $((depth + 1)) || return 1 ;;
```

(excerpt ends :675; the enclosing `_snap_tree_hooks()` continues to :677 — read.) `_snap_config` does follow an absolute include, but with the base `_snap_worktree_of` gives the top config, which is the main working tree for the checkout's common config (`:477-481`, `:500-504`, `:345-350`).

Executed. Repo config `include.path = <ws>/.git/inc.cfg` (absolute), with `inc.cfg` holding `core.hooksPath = .inc-hooks`. An agent worktree exists at launch, and the session plants `<wt>/.inc-hooks/pre-commit`. The `homeinclude` case uses `include.path = ~/x.cfg` and gives the same result.

```
== absinclude NEW
scan rc=0
HOOK-RAN
== homeinclude NEW
scan rc=0
HOOK-RAN
```

The direct and relative-include cases do work (Claim 9 and the bats case). The sentence is right about its mechanism but needs a qualifier: "directly or through a relative include".

Command: `LC_ALL= bash probe.sh <scan> absinclude|homeinclude`, run from `fc-p1/`. Exit 0. 2026-10-26T00:37:13Z (UTC).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:61-64`, `:345-358`, `:477-504`, `:654-677`, `:876-878`; `<logs>/probes.out`

---

## Claim 2: "_snap_tree_hooks … a relative core.hooksPath … as git resolves it for a command run in <working tree>: <working tree>/<value>. _snap_config walks it in one working tree per repo; a linked worktree … shares that config but runs hooks from its own tree"

**Location:** `devcontainer-config/cc-exit-scan.sh:647-652`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 resolving a relative `core.hooksPath` against the linked worktree's root, also when git runs from a subdirectory. Also covers `_snap_config` walking each config file once, with one base. Does not establish the case where `core.worktree` names another tree (pre-mortem row 1, Claim 12).
**Legibility-target:** maintainer

`_snap_config` deduplicates on the config's real path, and its base comes from `_snap_worktree_of`, which returns `$_snap_ws` for the checkout's git and common dirs:

```bash
# devcontainer-config/cc-exit-scan.sh:481-484
  [ -n "$base" ] || base="$(_snap_worktree_of "$f")"
  real="$(realpath -m -- "$f" 2>/dev/null)" || real="$f"
  [ -z "${_snap_seen["c:$real"]:-}" ] || return 0
  _snap_seen["c:$real"]=1
```

(excerpt starts after the `local` line :478 and ends :484; the enclosing `_snap_config()` continues to :527 — read.)

Executed. In the `hookbase` case, `core.hooksPath=.husky/_` is set, a linked worktree `wt` exists, a hook sits at `wt/.husky/_/pre-commit`, and the commit runs from `wt/sub`. Output: `HOOK-RAN-from-root`. The hook at the worktree root ran. In the `privconfig` case, git ignores a `config` in the worktree's private dir (Claim 6).

Command: `LC_ALL= bash probe.sh <new scan> hookbase`, run from `fc-p1/`. Exit 0. 2026-10-26T00:37:13Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:345-358`, `:477-527`, `:647-677`; `<logs>/probes.out`

---

## Claim 3a: "Records nothing itself: … and the dir and hooks by _snap_hooks."

**Location:** `devcontainer-config/cc-exit-scan.sh:652-653`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that `_snap_tree_hooks` appends no record itself and that `_snap_hooks` records the hooks dir and its entries. Does not establish that the config files it reads are recorded (Claim 3b).
**Legibility-target:** maintainer

`_snap_tree_hooks` (`:654-677`) never touches `_snap+=`. Paraphrased — no quote available because this is an absence: no `_snap+=` occurs between :654 and :677. Records come only from `_snap_hooks`, which calls `_snap_file hooksdir "$d"` and `_snap_file hook "$f"` (`:329-342`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:328-342`, `:654-677`

---

## Claim 3b: "the config was recorded by _snap_config"

**Location:** `devcontainer-config/cc-exit-scan.sh:652-653`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers configs that no `_snap_gitdir` walk reaches. Two cases: (1) the git dir of a container-form `.git` (`gitdir: /workspace/<rel>`) when nothing else reaches `<ws>/<rel>`; (2) a `commondir` that names a dir outside the checkout. For ordinary linked worktrees and embedded repos the config is recorded. No bypass was found: a changed hooksPath in an unrecorded config still adds a `hooksdir` record.
**Legibility-target:** maintainer

The loop calls `_snap_entry_hooks` on the container-form target `g`, but `_snap_dotgit` walks only the target that `_snap_dotgit_target` returns, and that is empty for a container-form file:

```bash
# devcontainer-config/cc-exit-scan.sh:871-878
      _snap_dotgit "$f" || { rc=1; break; }
      g="$(_snap_dotgit_target "$f")" || { rc=1; break; }
      # A container-form .git: walk your config as it will apply after a repair.
      [ -n "$g" ] || g="$(_snap_container_target "$f")" || { rc=1; break; }
      [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}" || { rc=1; break; }
      # The repo's own relative hooksPath, as it applies in this working tree.
      [ -z "$g" ] || _snap_entry_hooks "$g" "${f%/*}" || { rc=1; break; }
```

`_snap_gitdir` walks a `commondir` target only when it lies inside the checkout:

```bash
# devcontainer-config/cc-exit-scan.sh:763
    if [ -n "$line" ] && [ -d "$c" ] && _snap_inside_ws "$c"; then _snap_gitdir "$c" || return 1; fi
```

`_snap_entry_hooks` reads `$c/config` either way (`:683-690`).

Executed (`probe2.sh`). Setup: `<ws>/sgd` is a git dir holding `core.hooksPath = .hk`, and `<ws>/sub/.git` reads `gitdir: /workspace/sgd`. The snapshot holds the hooks walk but no `C` or `config` record for `sgd/config`:

```
F	dotgit	<S>/c.cH3H/proj/sub/.git	file 644 68690
F	hooksdir	<S>/c.cH3H/proj/sub/.hk	missing
```

Includes reached from such an unrecorded config through this walk are unrecorded too. Includes reached from a recorded config are recorded by `_snap_config` (`:500-504`).

Command: `LC_ALL= timeout 60 bash probe2.sh <S> <new scan>`, run from `fc-p1/`. Exit 0. The run time was not captured; it ran between 00:39 and 00:41Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:652-653`, `:683-690`, `:694-724`, `:745-763`, `:814-819`, `:868-879`; `<logs>/probe2.out`

---

## Claim 4: "git's own include depth limit" (`[ "$depth" -le 10 ]`)

**Location:** `devcontainer-config/cc-exit-scan.sh:656`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the boundary: the top config is depth 0, and a chain of 10 includes is followed while an 11th is not, in both git and the scan. Does not establish identical behaviour beyond the limit: git dies ("fatal: exceeded maximum include depth (10)"), while the scan silently stops walking.
**Legibility-target:** maintainer

Executed in a scratch repo. A chain of 10 include files resolves (`x.d1`, `x.d2`, … printed). An 11-file chain gives `fatal: exceeded maximum include depth (10) while including`. The scan returns at depth > 10 (`:656`), so it walks depths 0-10, the same files git reads. Same limit as `_snap_host_config` (`:607`).

Command: the inline depth probe and the `depth` case of `probe.sh`, run from `fc-p1/`. 2026-10-26T00:37Z. The `depth` case's output is in `<logs>/probes.out`; the 10-versus-11 chain was not captured to a file.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:607`, `:656`; `<logs>/probes.out`

---

## Claim 5: "`# walked once, by _snap_config`" (on skipping empty, absolute and `~/` values)

**Location:** `devcontainer-config/cc-exit-scan.sh:671`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip as it applies to `include.path`/`includeif.*.path` values. For a `core.hookspath` value that is absolute or `~/`, the comment is right: `_snap_config` resolves it to the same path whatever the working tree. Does not establish whether other absolute-include contents matter, beyond hooksPath.
**Legibility-target:** maintainer

The skip comes before the key dispatch, so it drops absolute and `~/` include values (quoted in Claim 1, `:671-675`). `_snap_config` follows those includes, but it resolves a relative hooksPath found inside them against the including config's base, the main working tree, never against each linked worktree:

```bash
# devcontainer-config/cc-exit-scan.sh:500-504
      include.path|includeif.*.path)
        [ -n "$val" ] || continue
        t="$(_snap_path "$val" "$(dirname -- "$f")")"
        _snap_file include "$t" || return 1
        if [ -f "$t" ]; then _snap_config "$t" "$base" || return 1; fi ;;
```

(excerpt inside the `case` of `_snap_config()`, which continues to :527 — read.)

So the R6 route stays live when the relative hooksPath sits in an absolutely-included file. Executed: `absinclude` and `homeinclude` both give `scan rc=0` then `HOOK-RAN` on the new scan (Claim 1). Fix direction: the skip should apply to `core.hookspath` only, not to include values.

Command: `LC_ALL= bash probe.sh <new scan> absinclude` and `homeinclude`, run from `fc-p1/`. Exit 0. 2026-10-26T00:37:13Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:500-504`, `:671-675`; `<logs>/probes.out`

---

## Claim 6: "_snap_tree_hooks for the configs git reads for that git dir — its common dir's config (a linked worktree's private dir has none of its own) and its config.worktree."

**Location:** `devcontainer-config/cc-exit-scan.sh:680-682`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the common-dir resolution, and the fact that git 2.39.5 ignores a `config` file in a linked worktree's private dir. Does not establish matching behaviour for `commondir` with a trailing CR (git strips it, the scan does not: Claim 18), or for an empty `commondir`.
**Legibility-target:** maintainer

```bash
# devcontainer-config/cc-exit-scan.sh:683-690
_snap_entry_hooks() {
  local g="$1" wt="$2" c="$1" line
  if [ -f "$g/commondir" ]; then
    line="$(_snap_first_line "$g/commondir")" || return 1
    case "$line" in "") ;; /*) c="$line" ;; *) c="$g/$line" ;; esac
  fi
  _snap_tree_hooks "$c/config" "$wt" && _snap_tree_hooks "$g/config.worktree" "$wt"
}
```

Executed (`privconfig`). With `.git/worktrees/wt/config` holding `core.hooksPath = .priv`, `git -C wt config core.hooksPath` printed empty and the commit did not run the hook (`hook-not-run`). The scan reading `$c/config` and not the private dir's `config` therefore matches git.

The imprecision: git reads `config.worktree` only when `extensions.worktreeConfig` is true. The scan reads it unconditionally. That is a safe over-walk, and the research doc (row 4) says so, but this comment calls them "the configs git reads". A precise version would say "and its config.worktree (read whether or not extensions.worktreeConfig is on)".

Command: `LC_ALL= bash probe.sh <new scan> privconfig`, run from `fc-p1/`. Exit 0. 2026-10-26T00:37:13Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:680-690`; `<logs>/probes.out`

---

## Claim 7: "R6 was never on that list on main (Q-168's A18 notes none of the split routes was)"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:37-38`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers A18's text at 75d08a94, and the guide's known-routes list on this branch, which has no relative-hooksPath-in-linked-worktree item and lost none in this diff. Does not establish the guide's state on other branches.
**Legibility-target:** reviewer

A18 at 75d08a94 (`docs/reviews/code-review-rubric-2026-10-15-q168-exit-scan-remote-names.md:47`) reads "… and none of the split routes is in the guide's known routes." The guide hunks in this diff only add lines in "Known routes it does not see" (`guides/cc-isolated-usage.md:411-485`), so no route left the list. Paraphrased — no quote available because this is about the diff's shape (no `-` lines in that section).

**Evidence:** `guides/cc-isolated-usage.md:411-485`; 75d08a94 `docs/reviews/code-review-rubric-2026-10-15-q168-exit-scan-remote-names.md:47`

---

## Claim 8: "R3's `core.hooksPath` half is already resolved by this change's per-entry walk (probe below)" / "`old rc=0` (hook ran), `new rc=1`"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:46-47`, `:78-79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the separate-git-dir embedded repo (`git init --separate-git-dir <ws>/sgd vendor/e`) with a relative `core.hooksPath` directly in its config. Does not establish R3's remote half, which the doc says is unresolved, or a hooksPath reached through an absolute include (Claim 5).
**Legibility-target:** reviewer

Executed (`r3`):

```
== r3 OLD
scan rc=0
HOOK-RAN
== r3 NEW
scan rc=1
HOOK-RAN
```

The walk reaches it because `vendor/e/.git` is a `gitdir:` file whose target `_snap_dotgit_target` resolves, and `_snap_entry_hooks` then uses `${f%/*}` = `vendor/e` as the base (`:872-878`).

Command: `LC_ALL= bash probe.sh <old|new scan> r3`, run from `fc-p1/`. Exit 0. 2026-10-26T00:37:13Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:694-708`, `:868-879`; `<logs>/probes.out`

---

## Claim 9: "old R6 scan rc=0 / HOOK-RAN / new R6 scan rc=1 / HOOK-RAN" and "The new bats case fails on the unfixed scan at its first `[ "$status" -eq 1 ]` and passes with the fix"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:55-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the R6 layout (`core.hooksPath=.husky/_`, a worktree at `.claude/worktrees/a` present at launch, a plant at `<wt>/.husky/_/pre-commit`), plus the bats case's two variants (direct and relative `include.path`), on git 2.39.5. Does not establish the host check, which has not been run.
**Legibility-target:** reviewer

Executed with the scratch probe:

```
== r6 OLD
scan rc=0
HOOK-RAN
== r6 NEW
scan rc=1
HOOK-RAN
```

Bats on HEAD: `ok 1 exit scan R6: …`, exit 0. Bats with the d40e4bae scan swapped in: `not ok 1 … (in test file old/test/cc-isolated-functions.bats, line 3152) [ "$status" -eq 1 ]' failed`, exit 1. Line 3152 is the case's first status check:

```bash
# test/cc-isolated-functions.bats:3150-3152
  plant_hook "$STD_WT/.husky/_" pre-commit
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
```

(excerpt ends :3152; the enclosing `@test` continues to :3169 — read.)

Commands:
- `LC_ALL= timeout 300 bats -f R6 test/cc-isolated-functions.bats`, cwd the worktree. Exit 0. 2026-10-26T00:36:14Z.
- The same against `fc-p1/old/test/cc-isolated-functions.bats`, cwd `fc-p1/`. Exit 1. 2026-10-26T00:36:23Z.
- `probe.sh … r6`. Exit 0. 00:37:13Z.

**Evidence:** `test/cc-isolated-functions.bats:3143-3169`; `<logs>/bats-head.out`, `<logs>/bats-head.ts`, `<logs>/bats-old.out`, `<logs>/bats-old.ts`, `<logs>/probes.out`

---

## Claim 10: "Mechanism (main, d40e4bae): `_snap_config` reads the checkout's common `config` once, with `base = _snap_worktree_of(config) = $_snap_ws` … The working-tree `.git` loop … re-applies only *your* config per entry"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:57-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers d40e4bae's `_snap_config` base and the loop body. Does not establish other repo-config paths, such as legacy remotes (`:777-784`), that also use `_snap_worktree_of`.
**Legibility-target:** reviewer

```bash
# devcontainer-config/cc-exit-scan.sh:348-349 (unchanged from d40e4bae)
  if [ "$gd" = "$_snap_gd" ] || [ "$gd" = "$_snap_common" ]; then
    printf '%s' "$_snap_ws"
```

(excerpt inside `_snap_worktree_of()` :345-358 — read.) The d40e4bae loop ended at the `_snap_host_config` call. The diff adds only the two `_snap_entry_hooks` lines after it (`:877-878`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:345-358`, `:477-484`, `:868-879`

---

## Claim 11: "Note that main has no CR stripping in any `.git`/`commondir` reader"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:49-50`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the scan's readers (`scan_git_dirs`, `_snap_gitdir`, `_snap_dotgit_target`, `_snap_container_target`, `_snap_entry_hooks`), which strip no CR. Does not cover `cc-gitdir.sh`'s `gitdir_common`, which does strip one.
**Legibility-target:** reviewer

`cc-exit-scan.sh` contains no `\r` handling (grep: zero hits). `cc-gitdir.sh`, which the scan sources and which `gitdir_valid` uses, does strip:

```bash
# devcontainer-config/cc-gitdir.sh:63-66
    # No NUL: the whole file, trailing line breaks trimmed.
    while :; do
      case "$line" in *$'\n'|*$'\r') line="${line%?}" ;; *) break ;; esac
    done
```

(excerpt ends :66; the enclosing `gitdir_common()` continues to :68 — read.) A precise version would say "no CR stripping in any of the scan's `.git`/`commondir` readers (cc-gitdir.sh's `gitdir_common` strips)".

**Evidence:** `devcontainer-config/cc-gitdir.sh:50-68`; `devcontainer-config/cc-exit-scan.sh:137-165`, `:694-724`, `:683-690`

---

## Claim 12: Pre-mortem row 1: "Hooks base differs from the `.git` entry's dir (`core.worktree` set in the config) — Partly: the entry dir is walked; a `core.worktree` elsewhere needs that value at launch … `_snap_config` still walks its own base too."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers `_snap_entry_hooks` using `${f%/*}` regardless of `core.worktree`, and `_snap_worktree_of` honouring `core.worktree` for `_snap_config`'s base. Also covers an in-session `core.worktree` change being a `C` record. Not executed.
**Legibility-target:** reviewer

`_snap_worktree_of` reads `core.worktree` (`:351-352`: `elif [ -f "$1" ] && v="$(… --get core.worktree …)"; then _snap_path "$v" "$gd"`), and `_snap_entry_hooks` takes `wt` from the caller's `${f%/*}` (`:878`). `_snap_config` records every entry as a `C` line (`:494`). Paraphrased — no quote available beyond these fragments because the claim combines three functions.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:345-358`, `:494`, `:878`

---

## Claim 13: Pre-mortem row 2: "Linked worktree added during the session — Covered: W records already refuse the note; the new walk adds the hook records."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:112`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers any relative `core.hooksPath` in a config `_snap_config` reads (directly or through an include it follows, absolute includes included), which emits a `W` record that refuses the note. Does not establish the case of a relative hooksPath in an unrecorded config (Claim 3b) with an added worktree.
**Legibility-target:** reviewer

```bash
# devcontainer-config/cc-exit-scan.sh:495-498
    case "$key" in
      core.hookspath)
        _snap_wrel "$key" "$f" "$val"
        [ -z "$val" ] || _snap_hooks "$(_snap_path "$val" "$base")" || return 1 ;;
```

```bash
# devcontainer-config/cc-exit-scan.sh:1033
  [[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1
```

(first excerpt inside `_snap_config()` :477-527; second is the first check of `scan_std_worktrees()` :1025-1146 — both read.)

**Evidence:** `devcontainer-config/cc-exit-scan.sh:312-317`, `:495-498`, `:1025-1033`

---

## Claim 14: Pre-mortem row 3 (and plan step 1): "hooksPath set through `include.path`/`includeIf` in repo config — Covered: followed (conditions not evaluated: over-walk)."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:113`, `:99-100`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers include targets named by an absolute or `~/` value, which are not followed by the per-entry walk. Relative include values are followed, which the bats case tests. Plan step 1's "Absolute and `~/` values are skipped (walked by `_snap_config`)" is the design that opens this route.
**Legibility-target:** reviewer

Same evidence as Claim 5. `absinclude` and `homeinclude` give `scan rc=0` and `HOOK-RAN` on the new scan. The pre-mortem marks this bypass family "Covered", but it is open for absolute and `~/` include values.

Command: `LC_ALL= bash probe.sh <new scan> absinclude|homeinclude`, run from `fc-p1/`. Exit 0. 2026-10-26T00:37:13Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:671-675`; `<logs>/probes.out`

---

## Claim 15: Pre-mortem row 4: "`config.worktree` (extensions.worktreeConfig) — Covered: walked for each private git dir (over-walk when the extension is off)."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:114`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_entry_hooks` reading `$g/config.worktree` unconditionally. Does not establish a `config.worktree` in an unrecorded git dir (Claim 3b).
**Legibility-target:** reviewer

`_snap_tree_hooks "$g/config.worktree" "$wt"` (`:689`), with no `extensions.worktreeConfig` check anywhere in the function. Quoted in Claim 6.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:683-690`

---

## Claim 16: Pre-mortem row 5: "Unreadable or unparseable config on the new path — Covered: the snapshot fails (launch refused / exit 4), as `_snap_config` does (H2)."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:115`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a config that is a regular file `git config --file` cannot read or parse: `_snap_fail`, return 1, then `rc=1` in the loop. Does not cover a config path that exists but is not a regular file: `[ -f ]` skips it silently, though `_snap_gitdir` still records it with `_snap_opt`.
**Legibility-target:** reviewer

```bash
# devcontainer-config/cc-exit-scan.sh:662-665
  if ! (cd / && git --no-pager config --file "$f" --no-includes --null --list) > "$out" 2> "$out.err"; then
    _snap_fail 'could not read config %s: %s' "$f" "$(cat "$out.err")"
    return 1
  fi
```

The loop maps the failure to `rc=1` (`:878`: `|| { rc=1; break; }`), and `git_exec_snapshot` then returns 1 (`:911`). `git_exit_scan` returns 2 on that (`:1164-1178`). The exit-4 mapping is in the launcher, which was not read for this claim (paraphrased — no quote available because the claim's "exit 4" lives in `cc-isolated.sh`, outside the diff).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:657`, `:662-665`, `:878`, `:910-912`, `:1162-1178`

---

## Claim 17: Pre-mortem row 7: "`commondir` with a trailing CR (git strips it) — Not covered on main: the walk reads the raw first line, as `_snap_gitdir` does; needs it at launch (an in-session change is a `commondir-file` record)."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 stripping a trailing CR from `commondir` and from a `.git` file's `gitdir:` line, the scan's raw read, and the `commondir-file` record. Does not establish every downstream effect of the mismatch.
**Legibility-target:** reviewer

Executed (`crdotgit`). With `printf '../..\r\n' > .git/worktrees/wt/commondir`, `git rev-parse --git-common-dir` printed `<ws>/.git`, so git stripped the CR. `.git` with `gitdir: …\r\n` also resolved. The scan reads the line with `_snap_first_line` (`:227-240`, `IFS= read -r line`, no trim), and `_snap_gitdir` records `_snap_opt commondir-file "$real/commondir"` (`:758`).

Command: `LC_ALL= bash probe.sh <new scan> crdotgit`, run from `fc-p1/`. Exit 0. 2026-10-26T00:37:13Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:227-240`, `:686-687`, `:758-763`; `<logs>/probes.out`

---

## Claim 18: "Cost: one extra `git config` fork per `.git` entry. 100 embedded repos: old 2.83 s / 2.87 s, new 2.77 s / 2.81 s (noise), so the guide's timing is unchanged."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:122-123`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the conclusion that the change is noise-level on 100 plain embedded repos. Does not reproduce the exact figures, which are host-specific. The fork count is one per entry only when no `config.worktree` or relative include exists.
**Legibility-target:** reviewer

Six snapshots each of a 100-embedded-repo tree on a shared, noisy container: old 4.86, 3.68, 4.95, 4.46, 3.01, 2.89 s; new 5.17, 5.76, 4.35, 2.44, 3.06, 3.11 s. The medians (about 4.1 s old, 3.7 s new) differ by less than the run-to-run spread, which is consistent with "noise". Fork count: `_snap_tree_hooks` forks once per existing file it reads, `$c/config` plus `$g/config.worktree` if present plus each relative include (`:657`, `:662`, `:689`). For a linked worktree with `config.worktree`, or a config with includes, that is more than one. A precise version would say "one `git config` fork per config file read per entry (one for a plain embedded repo)".

Command: `LC_ALL= timeout 120 bash t.sh <dir> <old|new scan>` ×3 each, run from `fc-p1/timing/`. Exit 0. 2026-10-26T00:40:29Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:654-690`; `<logs>/timing.out`

---

## Claim 19: "A relative `core.hooksPath` in a repo's config (husky's `.husky/_`) is walked in every working tree that uses that config: the repo's own and each linked worktree or other `.git` entry in the checkout (an agent worktree runs `<worktree>/.husky/_`)."

**Location:** `guides/cc-isolated-usage.md:337-341`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same split as Claim 1. True for a value set directly or through a relative include. False for a relative hooksPath in a file the repo config includes by an absolute or `~/` path: the scan returns rc=0 and the hook runs.
**Legibility-target:** user

See Claims 1 and 5 for the quotes and runs. For a user, the missing qualifier matters: someone whose repo config includes a shared husky snippet by absolute path would read this sentence as coverage. A precise version: "… set in the repo's config or a file it includes by a relative path …", with the absolute/`~/` include case listed under known routes, or fixed.

Command: `LC_ALL= bash probe.sh <new scan> absinclude|homeinclude`, run from `fc-p1/`. Exit 0. 2026-10-26T00:37:13Z.

**Evidence:** `guides/cc-isolated-usage.md:337-341`; `devcontainer-config/cc-exit-scan.sh:671-675`; `<logs>/probes.out`

---

## Claim 20: "The scan closes routes that need only what a session can write in the checkout; a route that needs some unusual state present at launch stays here by design (Q-172 [2])." (with ":411-414 This is the one list of what the scan and `cc-push` do not cover")

**Location:** `guides/cc-isolated-usage.md:415-418`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first clause read as a statement of current behaviour, together with the section's "the one list" framing. The `cc-push` sentence (":417-418") was not checked.
**Legibility-target:** user

The research doc itself sorts A14, A16 and R3's remote half as "in" (ordinary launch state, only an in-session write) but as follow-ups not built (`docs/working/research-…:26-28`, `:44-46`). The guide's list has no entry for them: grep for `pre-receive`, `receive hook`, `separate-git-dir` and `../upstream` in the guide finds nothing (paraphrased — no quote available because this is an absence). So a user reading "closes routes that need only what a session can write", plus "the one list", concludes those routes are closed.

Executed A14 on HEAD (`a14/p.sh`). The repo config has `remote.origin.url = ../up.git` and a linked worktree at `<ws>/wts/a` exists at launch. The session creates a bare repo `<ws>/wts/up.git` with a `pre-receive` hook, then a host push from the worktree:

```
scan rc=0
remote: A14-HOOK-RAN
```

The absolute-include R6 variant (Claim 5) is another open in-boundary route. Either the sentence should be stated as the target ("is meant to close"), or A14/A16/R3-remote (and Claim 5's route) should be listed until their follow-ups land.

Command: `LC_ALL= timeout 120 bash p.sh <S>/a14 <new scan>`, run from `fc-p1/a14/`. Exit 0. 2026-10-26T00:42:39Z.

**Evidence:** `guides/cc-isolated-usage.md:411-418`; `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:26-28`, `:44-46`; `<logs>/a14.out`

---

## Claim 21: "A local path holding `@[`, or starting with `[`, present at launch. Git cuts such a path at the `]` (`./decoy@[x]plant` pushes to `./]plant`); the scan walks the path as written. This holds for a remote URL, an undefined remote name, a legacy remotes file and an `insteadOf` result (Q-168 rubric R4)."

**Location:** `guides/cc-isolated-usage.md:454-457`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's push target for all five forms named: an `@[` URL, a `[`-leading URL, an undefined name, a legacy `remotes/` file and an `insteadOf` result. Also covers the scan having no `@[`/`]` handling. Does not establish the scan's rc on each form end to end; that was established statically.
**Legibility-target:** user

Executed (`<logs>/r4.out`). Bare repos were created at each candidate path, each with a `pre-receive` that echoes its own name:

```
-- remote url ./decoy@[x]plant
RAN in ]plant
-- remote url [x]p1
RAN in ]p1
-- undefined name ./d@[y]p2
RAN in ]p2
-- legacy remotes file URL: ./d@[z]p3
RAN in ]p3
-- insteadOf result
RAN in ]p4
```

`_snap_remote` joins the value to the base unchanged (`:389`: `case "$p" in /*) ;; *) p="$base/$p" ;; esac`), and `grep -c '@\['` on the scan gives 0. The rubric R4 row at 75d08a94 (`…rubric…:20`) matches.

Command: the inline script recorded in `r4.out`, run from `fc-p1/r4c/`. Exit 0. 2026-10-26T00:41:53Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:376-401`; `<logs>/r4.out`

---

## Claim 22a: "Your `includeIf "gitdir:…"` patterns, matched more loosely than git. If your own config defines a remote only inside a `gitdir:` include and also names it (`remote.pushDefault`, `branch.*.remote`), the scan may count that definition where git would not apply the include, and then never walk the name as a path git pushes to"

**Location:** `guides/cc-isolated-usage.md:458-461`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this branch's scan, the Q-096 tip plus this diff. It never queues a remote name from your own config, and counts your-config definitions only from an include target inside the checkout. So the "count, then skip" mechanism described is not what happens here; the name is unwalked whether or not the include matches. Does not establish the held Q-168 branch, where the rubric's R5/A15 were measured.
**Legibility-target:** user

`_snap_host_config` handles only `url.*.insteadof`, `remote.*.url/pushurl`, `core.hookspath`, `core.attributesfile` and includes (`:618-640`). It has no `remote.pushdefault|branch.*.remote` case. Names are queued, and definitions counted, only in `_snap_config` (`:508-515`), which reads repo configs and include targets inside the checkout. Paraphrased — no quote available because this is the absence of a case arm across `:618-640`.

Executed (`a15c/p.sh`). Your config has `remote.pushDefault = foo`, and the session plants a bare repo `<ws>/foo` with `pre-receive`. In mode `no-include`, `foo` is defined nowhere. In mode `loose-include`, `[includeIf "gitdir:<T>/a**"] path = <T>/inc` defines `remote.foo` (git does not apply `a**` to `<T>/ab/.git`; see Claim 22b).

```
no-include: scan rc=0
remote: HOOK-RAN-no-include
loose-include: scan rc=0
remote: HOOK-RAN-loose-include
```

The outcome is the same without any include, so the gap is the existing bullet "a path-valued `pushRemote`/`pushDefault` in your own config" (`:452-453`), not loose matching. The rubric R5 (75d08a94 `…rubric…:21`) says the counting was "Created by the unit's counting" on the Q-168 branch. This bullet describes that unmerged branch's behaviour.

Command: `LC_ALL= timeout 120 bash p.sh <S>/a15c <new scan>`, run from `fc-p1/a15c/`. Exit 0. 2026-10-26T00:43:56Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:508-515`, `:604-641`, `:885-892`; `guides/cc-isolated-usage.md:452-453`; `<logs>/a15c.out`

---

## Claim 22b: "… a pattern written on a symlinked launch path that matches an embedded repo reached through a `gitdir:` file (R5), or a `**` not bounded by `/` on both sides, which git treats as `*` (A15)."

**Location:** `guides/cc-isolated-usage.md:462-464`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers git's `**` semantics (verified: `a**` does not cross `/`) and the scan's `.*` translation (verified statically). Does not establish the R5 symlinked-launch-path half, which was not executed. Does not establish that either loose match changes any outcome on this branch (Claim 22a suggests it does not for names in your own config).
**Legibility-target:** user

Executed (`<logs>/a15.out`). With `includeIf "gitdir:<T>/a**/.git"`, git applied the include for `abx` but not for `ab/c/r`: `ab/c/r: []  abx: [1]`. So git treats `**` as `*`. The scan's translation:

```bash
# devcontainer-config/cc-exit-scan.sh:539-541
      '*')
        if [ "${pat:i+1:1}" = '*' ]; then
          if [ "${pat:i+2:1}" = / ]; then re+='(.*/)?'; i=$((i + 2)); else re+='.*'; i=$((i + 1)); fi
```

(excerpt inside `_snap_glob_re()` :533-552 — read.) The A15 matching fact is right. Whether R5's `lg1` form ever matters here, and whether any route exists on this branch through either loose match, would need an end-to-end probe. That probe would put the include target inside the checkout and the name in repo config, the only path on which `_snap_rnames` is set from your includes (`:631-633` then `:513-515`).

Command: the inline script recorded in `a15.out`, run from `fc-p1/a15b/`. Exit 0. 2026-10-26T00:41:54Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:533-552`, `:557-596`, `:628-634`; `<logs>/a15.out`

---

## Claim 23a: "(and nothing at all when the line ends in a CR, which git strips: Q-168 tech-debt T1)"

**Location:** `guides/cc-isolated-usage.md:483-485`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_snap_container_target` returning nothing for a `gitdir: /workspace/<rel>\r` line (so neither `_snap_host_config` nor the new `_snap_entry_hooks` runs) and git stripping the CR. "Nothing at all" means nothing walked; the `.git` file itself is still recorded by `_snap_dotgit`.
**Legibility-target:** user

```bash
# devcontainer-config/cc-exit-scan.sh:717-721
  line="$(_snap_first_line "$1")" || return 1
  case "$line" in "gitdir: $GIT_EXIT_SCAN_CONTAINER_WS"/?*) ;; *) return 0 ;; esac
  g="$_snap_ws/${line#"gitdir: $GIT_EXIT_SCAN_CONTAINER_WS"/}"
  [ -d "$g" ] || return 0
  (cd "$g" 2>/dev/null && pwd -P) || true
```

(excerpt ends :721, the last line of `_snap_container_target()`, which starts at :713 — read.) With a trailing CR, `$g` ends in `\r`, `[ -d ]` fails, and the result is empty. Git stripping the CR was executed in the `crdotgit` case (Claim 17).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:713-722`, `:868-879`; `<logs>/probes.out`

---

## Claim 23b: "the scan maps it to `<checkout>/<path>` and walks only your own config there, not that git dir"

**Location:** `guides/cc-isolated-usage.md:483-484`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the container-form path after this diff. The sentence sits in a line pair this diff edits, but its first half predates the diff. Does not establish whether `git worktree repair` picks the same git dir.
**Legibility-target:** user

After this change the loop also calls `_snap_entry_hooks "$g" …` on the container-form target (`:877-878`, quoted in Claim 3b). So that git dir's own `config` and `config.worktree` are read, and a relative `core.hooksPath` in them is walked at the `.git` entry's directory. Executed (`probe2.sh`): `sub/.git` → `gitdir: /workspace/sgd`, with `sgd/config` holding `core.hooksPath = .hk`, produces `F hooksdir <ws>/sub/.hk missing`. A current version would say "walks your own config there and that git dir's relative `core.hooksPath`, nothing else from it (its config is not recorded)".

Command: `LC_ALL= timeout 60 bash probe2.sh <S> <new scan>`, run from `fc-p1/`. Exit 0. The run time was not captured; it ran between 00:39 and 00:41Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:868-879`; `<logs>/probe2.out`

---

## Claim 24: Commit message: "The working-tree .git loop now also reads the configs git uses for each entry's git dir (common config, config.worktree, includes) and walks a relative core.hooksPath at <entry dir>/<value>"; "on d40e4bae … rc=0 and ran on the next host commit"

**Location:** commit cf15f4f9 (message body, lines 3-9)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the before/after rc claim (verified, Claim 9) and the walk description. The walk follows relative includes only. "Configs git uses" includes `config.worktree` unconditionally (Claim 6).
**Legibility-target:** reviewer

The rc=0 → rc=1 behaviour and the host-commit hook run are reproduced (Claim 9). "includes" needs the qualifier "relative": absolute and `~/` include values are skipped (`:671`), and the route stays open through them (Claims 1, 5).

Command: as for Claims 1 and 9. Exit 0. 2026-10-26T00:36-00:37Z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:671-675`, `:877-878`; `<logs>/bats-head.out`, `<logs>/bats-old.out`, `<logs>/probes.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3b** (`devcontainer-config/cc-exit-scan.sh:652-653`): "the config was recorded by _snap_config" is false for a container-form target that no other walk reaches, and for a `commondir` outside the checkout. `probe2` shows a `hooksdir` walk from `sgd/config` with no record of that config. No bypass found.
- **Claim 5** (`devcontainer-config/cc-exit-scan.sh:671`): "walked once, by _snap_config" is wrong for include values. Absolute and `~/` includes are skipped, so a relative hooksPath inside them is never walked in linked worktrees. Probe: rc=0, hook ran. Apply the skip to `core.hookspath` only.
- **Claim 14** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:113`, `:99-100`): pre-mortem row 3 marks the include family "Covered", but it is open for absolute and `~/` include values (same probe).
- **Claim 20** (`guides/cc-isolated-usage.md:415-418`): "The scan closes routes that need only what a session can write" plus "the one list" is false today. A14 is executed live (rc=0, hook ran), and A14, A16, R3-remote and Claim 5's route are all in-boundary but unlisted.
- **Claim 22a** (`guides/cc-isolated-usage.md:458-461`): the R5/A15 mechanism ("count that definition … then never walk the name") describes the held Q-168 branch. On this branch your config's names are never queued, so the outcome is the same with no include (executed). The gap is already the `pushDefault` bullet at :452-453.

### Stale
- **Claim 23b** (`guides/cc-isolated-usage.md:483-484`): "walks only your own config there, not that git dir" is now stale. `_snap_entry_hooks` walks that git dir's relative `core.hooksPath`.

### Mostly Accurate
- **Claim 1** (`devcontainer-config/cc-exit-scan.sh:61-64`): add "directly or through a relative include". It does not hold for absolute or `~/` includes.
- **Claim 6** (`devcontainer-config/cc-exit-scan.sh:680-682`): git reads `config.worktree` only with `extensions.worktreeConfig`; the scan reads it always.
- **Claim 11** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:49-50`): `cc-gitdir.sh`'s `gitdir_common` strips CR/LF. Only the scan's own readers do not.
- **Claim 18** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:122-123`): the noise conclusion is reproduced. The fork count is one per config file read, not strictly one per entry.
- **Claim 19** (`guides/cc-isolated-usage.md:337-341`): same qualifier as Claim 1, user-facing.
- **Claim 24** (commit cf15f4f9 message): "includes" should read "relative includes".

### Unverifiable
- **Claim 22b** (`guides/cc-isolated-usage.md:462-464`): git's `**` semantics and the scan's `.*` are verified, but the R5 symlinked-path half and any end-to-end route on this branch would need a probe with the include target inside the checkout and the name in repo config.

---

## Goal-Alignment Note

**Success criterion (verbatim):** "A markdown report saved to docs/reviews/r6-hookspath-p1-code-fact-check-report.md in that worktree, structured per the code-fact-check skill, with `Commit: <HEAD short sha>` first line and `**Replication:** k=1 (loop pass, decision 031)` in the header."

**Answered:**
- Brief item 1 (Claim 9): reproduced on HEAD and against d40e4bae.
- Item 2 (Claims 2, 6): verified, with the `config.worktree` qualifier.
- Item 3 (Claims 3a, 3b): partly false, for container-form and outside-`commondir` targets.
- Item 4 (Claim 8): verified.
- Item 5 (Claims 12-17): rows 1, 2, 4, 5 and 7 verified; row 3 is Incorrect.
- Item 6 (Claims 19-23): the coverage sentence and boundary paragraph are respectively imprecise and Incorrect; R4 verified; R5/A15 split into Incorrect and Unverifiable; T1 qualifier verified but its surrounding sentence is now Stale.
- Item 7 (Claim 1).
- Item 8 (Claim 18).

**Out of scope:** code quality and design choice (Path A vs B); `cc-push` behaviour (the guide's `cc-push` sentence); `cc-isolated.sh`'s exit-4 mapping; the host check (cannot run in the container); the held Q-168 branch's code.

**Escalate:**
1. **Enforcement gap (security-relevant).** A relative `core.hooksPath` in a file the repo config includes by an absolute or `~/` path is still an R6 route on HEAD: rc=0 and the hook runs (Claims 1, 5, 14). The fix is likely one line (skip absolute values only for `core.hookspath`, not for include keys), plus a bats variant. The pre-mortem claims this family is covered.
2. **Guide boundary paragraph** (Claim 20) tells users the scan closes all in-session-only routes, while A14 is live (executed) and A14, A16 and R3-remote are unlisted follow-ups.
3. **R5/A15 bullet** (Claim 22a) describes the unmerged Q-168 branch's mechanism, not this branch's.

**Questions/Decisions:** whether the guide should list the "in, follow-up" routes (A14, A16, R3-remote) until they land, or the boundary sentence should be reworded as intent. That is the author's call; no Q entry was opened by this pass.
