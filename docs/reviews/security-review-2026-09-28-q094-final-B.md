Commit: 2eebdf8

# Security Review — Q-094 stacked unit B (`q094b-exit-scan-worktree-removal`)

**Scope:** `git diff 9075003 2eebdf8` (claude-workflows): `devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, plan doc, `test/cc-isolated-functions.bats`. Unit A (dfe4c0d..9075003) was read as context only.
**Date:** 2026-09-28
**Based on:** Stage-1 merged code-fact-check summary (`scratchpad/B-fc-summary.md`, k=3), including its Escalations section.
**Delivery mode:** self-read, with executed probes in a scratch extract (`scratchpad/crB-sec/`, `probe.sh`, `unq.sh`).

## Trust Boundary Map

```
B1: container-written checkout (wt/.git, .git/worktrees/<n>/*) → git_exec_snapshot (host; find -P, %q) → before/after records
B2 (new): removed records (container-chosen paths as %q, host-computed hashes) → scan_std_worktrees removal branch (_snap_unq, content pairing regex) → accept (note, rc 0) / decline (warning, rc 1)
B3 (new): host disk at scan time (P, the old working-tree dir, its ancestors; container still running) → -e/-L/looks_like_gitdir probes (follow symlinks) → acceptance
B4: note text → scan_vis → the user's decision to run host git in the checkout
```

| Label | Source | Mutability | Trust per sink |
|---|---|---|---|
| S1 | dotgit record path (`%q` of a container-chosen path) | container-chosen, format fixed by host `%q` | UNTRUSTED for path construction / filesystem probes; format trusted only after a `%q` round-trip |
| S2 | dotgit/commondir record attrs (`file <mode> <sha256/16>`) | host-computed over container-chosen bytes | trusted as a hash of those bytes; UNTRUSTED as content |
| S3 | on-disk state at scan time (P, old wt, ancestor symlinks) | container-mutable (container keeps running after claude exits) | UNTRUSTED for every acceptance decision |
| S4 | worktree name `<n>` | container-chosen, `[A-Za-z0-9._-]`, not `.`/`..` | trusted for note text (and still scan_vis-ed) |
| S5 | `$common` (scan_git_dirs), `GIT_EXIT_SCAN_CONTAINER_WS` | container-influenced / code constant | `$common` cross-checked against the after snapshot's `commondir` record (:833-834); constant trusted |

Prose: B widens the acceptance from "records only added" to "records only added or removed". A removal only makes records disappear, so the new risk is a record that disappears because the exit snapshot stopped *seeing* something that still exists, rather than because it is gone. P is checked gone on disk (:873, `-e` and `-L`); the old working tree's `.git` is not checked on disk at all — its absence is inferred from the absence of a record, which `find -P` (:694) cannot produce for a path under a symlinked ancestor.

## Findings

#### F1. A removal gets the note while the old working-tree path still resolves to a git dir through a symlink

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:884-890` (removal branch; enclosing function `scan_std_worktrees` :825-943 read in full)
**Boundary:** B3, B4
**Move:** #11 (bypass enumeration), #4 (check vs. use)
**Confidence:** High (executed)
**Legibility-target:** the removal branch's comment and the note text "Removed ones left no git dir behind"

Evidence (verbatim, :884-890):
```
      # The old working tree, if still there, must not look like a git dir: a
      # repository left in its place is not "removed".
      q="${ok%$'\t'*}"; q="${q#?F$'\t'dotgit$'\t'}"
      _snap_unq "$q" wt || return 1
      case "$wt" in */.git) wt="${wt%/.git}" ;; *) return 1 ;; esac
      ! looks_like_gitdir "$wt" || return 1
      used["$ok"]=1; removed+=("$n")
```
The check tests whether `<wt>` *itself* looks like a git dir, never whether `<wt>/.git` still exists. A `<wt>/.git` reachable by a real path inside the checkout would have left a record, so the gap is exactly the paths `find -P` does not walk: a symlinked ancestor or a symlinked `<wt>`. Executed (`probe.sh`, worktrees under `<ws>/cw/worktrees`):
- `symparent`: `git worktree remove`, then replace `cw/worktrees` with a symlink to an outside dir holding `agent-y/.git` (a `git init` repo). At 9075003: WARNING, rc=1. At 2eebdf8: `note: … (removed: agent-y). Removed ones left no git dir behind, so this is not a finding.` rc=0, and `git -C <old wt> rev-parse --absolute-git-dir` → `…/outside/wts/agent-y/.git`.
- `wtsymlink`: `<wt>` itself becomes a symlink to an outside work tree with `.git`: A warns rc=1; B note rc=0.
- `symparent_inside` (symlink target inside the checkout): warns at both (the target's `.git` is recorded under its real path) — so only targets outside the checkout get through.

**Is this new capability from B?** No. `symgeneral` (a brand-new working-tree symlink `tools -> <outside repo>`, no worktree involved) returns rc=0 with *no output* at both 9075003 and 2eebdf8, and host git in `tools` uses the outside repo. The end state B now calls a note is already reachable silently at any path (F2). B's delta is (a) it turns a warning the user would have seen into a note, and (b) the note asserts "left no git dir behind" when host git at that exact path finds one. The target's content is outside the checkout, so under the documented threat model it is host-owned; that is why this is Low rather than the F2 floor.

**Recommendation:** add one line after :889: `[ ! -e "$wt/.git" ] && [ ! -L "$wt/.git" ] || return 1`. Executed in a scratch copy: `symparent` and `wtsymlink` then warn (rc=1), and all 12 `Q-094|_snap_unq` bats tests still pass. It makes the note's claim true at the one path it names, at no cost for a real `git worktree remove` (which deletes `<wt>`).

#### F2. (Pre-existing, not a B merge blocker) A working-tree symlink to a directory outside the checkout hides any repository there; not in "Known routes"

**Severity:** Medium (floor rule: named mechanism; reachability goes in Confidence)
**Location:** `devcontainer-config/cc-exit-scan.sh:694`; `guides/cc-isolated-usage.md:362-430` ("Known routes it does not see")
**Boundary:** B1
**Move:** #1, #11
**Confidence:** Low (exploitation needs a host path, readable by the host user, that the container can write outside the checkout)
**Legibility-target:** the "Known routes" list

Evidence (:694): `    _snap_find "$list" "$_snap_ws" -mindepth 2 -name .git` — `_snap_find` runs `find -P`, which never descends a symlinked directory. `symgeneral` executed at both 9075003 and 2eebdf8: rc=0, no output; `git -C <ws>/tools rev-parse --absolute-git-dir` → the outside repo's `.git`. Under the stated model ("the checkout — the only tree the container can write", `_snap_inside_ws`) the target's content is host-owned, so this is a documentation gap unless some container-writable storage is visible on the host: e.g. under rootless Docker, the per-project named volumes (`cc-<id>-claude-config`, `cc-<id>-bashhistory`, devcontainer.json:77-78) live under the host user's `~/.local/share/docker/volumes/…/_data`, readable by host git. A session could then plant a repo with hooks there and a working-tree symlink to it; host git run inside that symlinked directory runs the hooks with no finding. This answers the fact-check escalation: the symlinked-parent probe is this pre-existing route, not a capability B adds (F1 is B's only contribution).
**Recommendation:** add a "Known routes" bullet: a working-tree symlink to a directory outside the checkout is not followed, so a repository reached through it is not seen; host git run through that path uses it (relevant when any container-writable storage, such as a rootless-Docker volume, is reachable from the host). Track as a separate item; do not hold B for it.

#### F3. The `scan_std_worktrees` docstring still says "nothing is unquoted"

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:823-824`
**Boundary:** B2
**Move:** #2
**Confidence:** High
**Legibility-target:** the function docstring (its security argument)

Evidence: `# at snapshot time and now. Paths are compared as the %q` / `# strings the records hold, recomputed from <n>; nothing is unquoted.` — the removal branch now decodes with `_snap_unq` (:887). The decode is safe (see Endorsement E1; decoded value used only for the read-only `looks_like_gitdir`, and after F1's fix a `-e`/`-L` test), but a reader checking the "no decoding" invariant would be misled. Already flagged by the fact-check (Stale); same for plan B18. **Recommendation:** "the added side compares recomputed %q strings; the removal side decodes one path with _snap_unq, which round-trip checks it."

#### F4. Add/remove asymmetry for paths `%q` writes as `$'…'`

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:788` (`case "$q" in \$\'*|\'*|"") return 1 ;; esac`) vs. added side :914
**Boundary:** B2
**Move:** #11
**Confidence:** High (fact-check executed; my `unq.sh` confirms `$'a\tb'` and C-locale `é` decline)
**Legibility-target:** 2eebdf8 commit message Notes

A tab (either locale) or non-ASCII (C locale) working-tree path is accepted when added but warns when removed. Fails closed — a false positive, no security impact. The commit message's "the added side already declines such paths" is true only for a newline. No code change needed; correct the claim if the message is ever reused in the PR body.

## Untested bypass candidates (move #11, removal acceptance)

Tested (executed): outside-symlinked ancestor → note (F1); `<wt>` symlinked outside → note (F1); inside-symlinked ancestor → warns; bare layout / `commondir` at `<wt>` root → warns (bats test 4); cross-worktree pairing → warns (bats test 6); a baseline second `.git` file naming P, session removes only the worktree → note, and host git there dies `not a git repository` (harmless); remove + re-add under a new name/path → note `added: agent-y2; removed: agent-y` (legitimate); crafted `_snap_unq` inputs → decline or exact decode.

Listed, not tested:
- **Case-insensitive host filesystem** (macOS APFS default, via Docker Desktop): a `<wt>/.GIT` (or any `sub/.GIT`) would satisfy host git's `stat(".git")` but not `find -name .git`. Cannot be exercised on this ext4 host. If real, it is pre-existing and general like F2 (and F1's `-e "$wt/.git"` would catch it at the old path).
- **Bare layout in a subdirectory of the old working tree** — fact-check executed it (note); it is the documented "not named `.git`" route (guide :399-403), not B-specific.
- **Race after the exit snapshot** (container still running while `looks_like_gitdir`/`-e` probe): same as the documented "After the scan" route; not separately probed.

Because candidates remain untested, the removal acceptance as a whole is not listed in Endorsement Claims.

## Endorsement Claims

- **Claim E1:** `_snap_unq` sets its output only to a string whose `printf %q` equals the input, so a decode that differs from the original path declines.
  **Location:** `devcontainer-config/cc-exit-scan.sh:786-796`
  **Evidence:** executed
  **Verified:** read the full function (round-trip check at :794 precedes `printf -v` at :795); ran `unq.sh` under LC_ALL=C and C.UTF-8 on bash 5.2.15: 13 %q outputs (incl. `\$\'a`, `\~`, `a\\`, `\{a\,b\}`, `é`) decode exactly or decline; hand-made `\`, `a\`, `\\\`, `a\ b\` decline; fact-check fuzzed 20,000 strings per locale with 0 wrong decodes.
  **Not verified:** a bash whose `%q` differs between launch-snapshot time and exit-scan time (different bash binary between the two) — would decline, not mis-decode, by the round-trip, but not executed.
  **route: code-fact-check**
- **Claim E2:** a removed `dotgit` record is paired with a removed `commondir-file` only when its hashed content is exactly `gitdir: P\n` or the container form for the same `<n>`, and each record is consumed once.
  **Location:** `devcontainer-config/cc-exit-scan.sh:874-883, 890, 932`
  **Evidence:** executed
  **Verified:** bats "a removed git dir pairs only with the .git that pointed at it" and "a removed standard worktree is a note; a half-removed one warns" pass at 2eebdf8 (12/12 Q-094 tests); `dotgitfile_elsewhere` probe shows an extra baseline `.git` naming P leaves no record difference to pair.
  **Not verified:** two removed `dotgit` records both naming the same P (only by prior-session plant); read-static: the second stays unconsumed and :932 declines.
  **route: code-fact-check**
- **Claim (scoped prose):** B adds no exec, write or network primitive; its new disk touches are `-e`/`-L` on P and `looks_like_gitdir` (read-only `-e/-L/-d/-f` tests) on the decoded path. Read-static; nearest unread hop: `cc-gitdir.sh` callers other than this one (unchanged by B).

## Primitive sweep

Primitive: path construction from container-chosen strings → filesystem probe

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:887` `_snap_unq "$q" wt` | S1 | `%q` round-trip; `$'…'`/`'…'`/empty decline | cleared (E1) |
| `cc-exit-scan.sh:888` `case "$wt" in */.git)` | S1 | suffix required | cleared |
| `cc-exit-scan.sh:889` `looks_like_gitdir "$wt"` | S1, S3 | read-only tests; follows symlinks | F1 (does not cover `$wt/.git`) |
| `cc-exit-scan.sh:873` `[ ! -e "$p" ] && [ ! -L "$p" ]` | S4, S5, S3 | `<n>` regex; `$p` recomputed from `$common` | cleared — no-follow `-L` plus follow `-e` both required absent |

Primitive: regex built from values

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:878` `re="^file [0-7]+ ($h${g:+|$g})\$"` | S2 (host hex hashes) | hex only, anchored | cleared |

Primitive: dynamic variable assignment

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:795` `printf -v "$2"` | code constant `wt` | caller passes a literal name | cleared |

No exec, eval or write primitive in the diff scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 2 | Working-tree symlink to an outside dir hides a repo; not in Known routes (pre-existing, not B) | Medium | B1 | `cc-exit-scan.sh:694`, guide :362-430 | Low |
| 1 | Removal note while old wt path reaches a `.git` via symlink; add `! -e "$wt/.git"` | Low | B3, B4 | `cc-exit-scan.sh:884-890` | High |
| 3 | Docstring "nothing is unquoted" stale | Informational | B2 | `cc-exit-scan.sh:823-824` | High |
| 4 | `$'…'` add/remove asymmetry; commit-message claim | Informational | B2 | `cc-exit-scan.sh:788` | High |

## Overall Assessment

No finding within the code paths read gives a session a way, through B, to make host git run something it could not already reach with no warning at all. The one B-specific issue (F1) is that the removal note can be issued, and can claim "left no git dir behind", while host git at the old working-tree path finds a git dir through a symlink to outside the checkout. The same outside repo is already reachable silently through any new symlink (F2, pre-existing), so B widens nothing an attacker needs, but the one-line `-e`/`-L` check on `$wt/.git` makes the note's claim true and was tested to keep all 12 Q-094 tests green. It is worth taking before merge. `_snap_unq` is decode-safe (executed), and the add and remove branches share `used` without being able to consume each other's records (sign-keyed lookups, bats-verified). F2 is a documentation item for "Known routes", tracked separately. Endorsement claims E1 and E2 are execution-backed and scoped; other statements are no findings within the code paths read, pending execution verification.

## Goal-Alignment Note

The goal is a terminal confirming pass before merging unit B, with the focus on whether a removal note can hide something host git would run. Answer: B introduces no new execution route. The fact-check's symlinked-parent probe is the pre-existing general symlink limit (a new symlink with no worktree change is silent at both A and B). B's only contribution is that the note's wording overclaims at the one path it names (F1, Low, one-line fix). F3 and F4 are documentation. Nothing here should block the merge on security grounds. Taking F1's line and F3's wording in the same pass would close the only open B-specific item.
