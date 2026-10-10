# Security Review — feat/build-loop-u3a2 (confirming pass over the final fix batch)

Commit: a5837597
**Scope:** `git diff 6cbca87c..a5837597 -- scripts test` (f331f7bf, a5837597), with the rest of land() and default_gate read as context
**Date:** 2026-10-10
**Based on:** docs/reviews/security-review-2026-10-10-u3a2-final.md (probes for F1-F3), rubric docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a2.md (E1-E11), override-log rows for `feat/build-loop-u3a2`, shared brief u3a2-confirm-shared.md
**Probes:** /tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-confirm-security/ (r0, r0b, r1-r3 re-runs; n1-n4 new; `old/` is `git archive 6cbca87c scripts`, used for before/after on the honest layouts). Each probe ran in its own /tmp/u3a2c-sec-* dir under `timeout 60`, and every dir was removed (checked with `ls -d /tmp/u3a2c-sec-*` after each batch). `bats test/scripts/build-loop-merge.bats` ran with its own TMPDIR: 1..6, all ok.

## Trust Boundary Map

```
B1: caller argv/env (BRIEF, --expect, GIT_* identity)      → usage parse, merge_ident regex        → commit and reflog text
B2: W's own git dir and work tree                           → (cd W && state_gate), -ef top level,  → merge --ff-only in W
                                                              -ef holder git dir, status, A-paths
B3: repo-shared refs (symbolic refs under refs/heads)       → default_gate (startup and re-run)     → MAIN_SHA, CAS update-ref --no-deref
B4: worktree registry and per-worktree state (moved)        → worktree list + land's own scan of    → "who has main" (W, or nobody),
    ($common/HEAD, $common/worktrees/*/{HEAD,gitdir,          admin dirs: searchability loop,          "nobody will move main later"
    rebase-*/, BISECT_START})                                 state_is on HEAD / head-name /
                                                              update-refs / BISECT_START, holder count
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | caller argv and environment | request-time | trusted (header: the caller's environment is trusted) |
| S2 | caller's global git config (merge_ident) | runtime-mutable | trusted for identity text after the regex; no exec sink |
| S3 | repo refs incl. symbolic refs under refs/heads | runtime-mutable (any same-uid loop) | UNTRUSTED toward "which ref moves" and "who has main" |
| S4 | W's config.worktree, HEAD, index, files | runtime-mutable | UNTRUSTED toward exec (state-gated) and "W is clean" |
| S5 | $common and $common/worktrees/* admin-dir files | runtime-mutable | UNTRUSTED toward land-or-refuse; must be read as git reads them and fail closed when unreadable |
| S6 | git 2.39.5's own parsing (worktree list, refs backend, read_oneliner) | code-constant | trusted; land's *re-implementation* of it is the boundary |

What crosses: admin-dir state that a loop can plant before the run (S3, S5). The fix batch moved B4 from "trust worktree list" to "re-read every admin dir and compare counts". That only holds if land parses HEAD the way git does and searches every directory it reads from. Findings 1-3 are three places where it does not, each executed. Finding 4 is the honest-repo cost of the new count.

## Re-runs of the final pass's probes (E1-E6) at a5837597

| Item | Probe | Result at a5837597 |
|---|---|---|
| E1 unsearchable admin dir / worktrees/ | r0 `chmod 000 worktrees/w`; r0b `chmod 000 worktrees` (run from R) | `refuse …: a worktree's git directory or rebase state cannot be read`, main not moved. Run from a linked worktree under the mode-000 worktrees/, git itself cannot start (exit 1, nothing moved) |
| E4 / final F1, gitdir missing, empty, mode 000 | r1 ×3 | each: `refuse …: a worktree has the default branch checked out that git worktree list does not show`, main unchanged |
| E2 / E5 / final F2 | r2: real paused `rebase -i` of main, then plain, CRLF head-name, head-name as dir, mode-000 rebase-merge, update-refs as dir, BISECT_START as dir | plain and CRLF: `a worktree is rebasing the default branch`; dir cases: `a worktree's git state (…) cannot be read`; mode 000: `… git directory or rebase state cannot be read`. main unchanged in all six |
| E6 / final F3 | r3: `git symbolic-ref refs/heads/main refs/heads/trunk` | `refuse state default-branch: refs/heads/main is a symbolic ref`, exit 2, trunk unchanged |

E1-E6 are resolved for the mechanisms the final pass named. Findings 1-3 below are other members of the same class.

## Findings

#### 1. state_is misses a worktree HEAD that git reads as main when "ref:" is followed by a CR or LF; with that worktree's gitdir gone, land moves main by CAS under it

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1052` (state_is), `:1082` (holder count), `:1089` (count comparison)
**Boundary:** B4 (S5)
**Move:** 2 (implicit parse assumption), 11 (bypasses for the new count)
**Confidence:** High (executed)
**Legibility-target:** state_is and its comment "read as git reads it"

**Evidence:**
```
state_is() { LC_ALL=C awk -v w="$2" '{ sub(/^[ \t\r]+/, ""); sub(/[ \t\r]+$/, ""); sub(/^ref:[ \t]*/, "ref: ") } $0 == w { f = 1 } END { exit !f }' "$1"; }
```
Probe n1 (W on main, its `gitdir` removed, run from a detached third worktree):
```
### cr-sep   (HEAD = 'ref:\rrefs/heads/main\n')
W reads: refs/heads/main list-has-main: 0
merged docs/working/briefs/2026-10-01-x.md … 136fc2e9…
main now 136fc2e9… was 6e398ff0…
W status:
D  work-feat-x.txt
### nl-sep   (HEAD = 'ref:\nrefs/heads/main\n')
W reads: refs/heads/main list-has-main: 0
merged …
D  work-feat-x.txt
```
git's files backend reads HEAD by rtrimming it and then skipping git's `isspace` set (space, tab, CR, LF) after `ref:`. state_is skips only `[ \t]` after `ref:`, and it matches line by line, so an LF separator splits the symref across two lines. Either way n stays 0. The list dropped W because its gitdir was gone, so w is empty too. `0 -eq 0` passes and the CAS moves main under W, which is the final pass's F1 damage (W's index at the old commit, so a later `commit -a` reverts the merge). The control variants behaved as git does: `\v` and `\f` separators make git reject the directory ("not a git repository"), and a trailing `\v` or `\f` leaves HEAD on an invalid ref. Only CR and LF diverge. The attack needs two non-racing plants: delete the gitdir and rewrite HEAD.

**Recommendation:** Stop parsing HEAD by hand. Ask git, which also covers Finding 2: `git --git-dir="$d" symbolic-ref -q HEAD` (it recurses by default in 2.39) compared to `refs/heads/$MAIN`. A failed read of an existing HEAD should refuse. If a hand parse stays, slurp the whole file, rtrim `[ \t\r\n]`, then strip `^ref:[ \t\r\n]*`, and compare the whole value, not lines. Add a bats case with `ref:\rrefs/heads/main`.

#### 2. A worktree on a symbolic branch that points at main (`refs/heads/alias → refs/heads/main`) is not counted as a holder; with its gitdir gone, land moves main under it

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1082` (count compares the literal `ref: refs/heads/$MAIN`), `:384` (default_gate refuses only a symbolic `refs/heads/$MAIN`)
**Boundary:** B3, B4 (S3, S5)
**Move:** 5 (what does "main is not symbolic" not cover?), 11
**Confidence:** High (executed)
**Legibility-target:** default_gate's symbolic-ref refusal; holder count

**Evidence:** probe n4 `alias`: `git symbolic-ref refs/heads/alias refs/heads/main`; worktree x with `symbolic-ref HEAD refs/heads/alias`; x's gitdir removed:
```
x HEAD: refs/heads/main list-main: 0
merged docs/working/briefs/2026-10-01-x.md … 707b8317…
main moved: yes
x status:
D  work-feat-x.txt
```
With x's gitdir left in place (`KEEP`), the list reports x as `branch refs/heads/main`, n is 0, and land refuses ("…that git worktree list does not show"). That part fails closed. The fail-open needs the same gitdir deletion as Finding 1. The final F3 fix covers a symbolic main. It does not cover a symbolic *other* branch that resolves to main, which git resolves for x's HEAD. Pre-fix code (6cbca87c) also merged here, so this is not a regression. It is the remaining member of the E4/E6 class.

**Recommendation:** Finding 1's fix (resolve each admin HEAD with git, which follows the chain) closes this too. Otherwise, in default_gate, refuse any `refs/heads/*` symref whose target resolves to main (`git for-each-ref --format='%(refname) %(symref)' refs/heads`). Add one bats case.

#### 3. The searchability loop omits rebase dirs of dot-named admin dirs; a mode-000 `rebase-merge` there hides a paused rebase of main, and `rebase --abort` undoes the merge

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1073` (`"$common"/worktrees/*/rebase-{merge,apply}`, with no `.[!.]*` / `..?*` counterpart), `:1080` (`! -e && ! -L` → continue)
**Boundary:** B4 (S5)
**Move:** 12 (sweep every sibling of the glob), 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** land's searchability loop

**Evidence:**
```
for d in "$common" "$common"/worktrees "$common"/worktrees/* "$common"/worktrees/.[!.]* "$common"/worktrees/..?* "$common"/worktrees/*/rebase-{merge,apply} "$common"/rebase-{merge,apply}; do
```
Probe n2: real paused `rebase -i` of main in worktree r, admin dir renamed to `.r` (r's `.git` updated):
```
== dot-named, searchable:
refuse …: a worktree is rebasing the default branch
== dot-named, rebase-merge mode 000:
merged docs/working/briefs/2026-10-01-x.md … 97768c5a…
main now 97768c5a… was b712c193…
after abort: main b712c193…
```
Inside an unsearchable `rebase-merge`, `-e` and `-L` on `head-name` are both false, so the second loop skips it as absent. That is the final F2 "unsearchable rebase-merge" mechanism, which E2 fixed only for non-dot names. git sanitizes a leading dot (`worktree add …/.hid` gives admin name `-hid`), so this layout is planted, not honest. The script explicitly scans dot names, though, and the suite already plants a `.x` admin dir.

**Recommendation:** Derive the rebase dirs from the same admin-dir list, e.g. check `"$d"/rebase-{merge,apply}` searchability inside the second loop for every `$d`, so no glob list has to repeat the dot patterns. Extend the existing `.x` bats case with `chmod 000 .x/rebase-merge`.

#### 4. Regression: an honest bare repository with linked worktrees can no longer land at all

**Severity:** Low (fails closed: an availability and correctness regression, not a fail-open)
**Location:** `scripts/build-loop.sh:1081-1082` (counts `$common/HEAD` unconditionally), `:1089`
**Boundary:** B4
**Move:** 5 (invert: what honest state does the new count reject?)
**Confidence:** High (executed, before and after)
**Legibility-target:** holder count; refusal text

**Evidence:** probe n3, `git clone --bare` of the fixture with linked worktrees, run from a detached linked worktree:
```
### bare-none NEW      (no worktree on main)
refuse …: a worktree has the default branch checked out that git worktree list does not show
### bare-none OLD
merged … main moved: yes
### bare-linked NEW    (linked worktree m on main)
refuse …: a worktree has the default branch checked out that git worktree list does not show
### bare-linked OLD
merged … main moved: yes
```
A bare repo's `HEAD` names main but checks nothing out. `worktree list` marks that record `bare` with no `branch` line. land counts it anyway: n=1 with w empty, or n=2 with w=m. The refusal text is false for this layout. The brief puts honest-path correctness in scope, so I recommend fixing this in this loop and not deferring it.

**Recommendation:** Don't count `$common/HEAD` when the list's first record carries `bare`. A planted `core.bare=true` on a non-bare repo could then hide the main worktree, so also refuse that case when `$common/index` exists (a bare repo has none). Add a bats case for a bare clone with one worktree on main and one detached.

#### 5. Honest-config regression: `core.preferSymlinkRefs=true` (symlink HEAD) now refuses

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1079-1080` (`-f && ! -L` on HEAD)
**Boundary:** B4
**Move:** 5
**Confidence:** High (executed, before and after)
**Legibility-target:** header refusal list

**Evidence:** n4 `symlinkhead`: `HEAD` was `lrwxrwxrwx`. NEW: `refuse …: a worktree's git state (HEAD) cannot be read`. OLD: `merged …`.

This fails closed, and the setting is long deprecated. The header's "exists but is not a readable plain file" technically names it. If Finding 1 is fixed by asking git (`symbolic-ref`), this goes away. Otherwise, accept it with an override row.

**Recommendation:** None beyond Finding 1's fix, or an override row.

## Untested bypass candidates

1. **`update-ref refs/heads/main` planted in a paused rebase's `git-rebase-todo`, then a later `git rebase --edit-todo`.** In 2.38+, sequencer's todo_list_filter_update_refs may add refs named in the edited todo to `update-refs` with `before` set to the current value, which would then be NEW. If so, the rebase's end would move main off the landed merge. At land time `update-refs` does not name main, so land cannot see it. This depends on a later user action and was not executed.
2. **A decoy work tree sharing W's admin dir:** W's `gitdir` rewritten to point at X/.git, where X's `.git` file names W's admin dir. The list then names X, `-ef` holder holds, and the ff runs in X while the real W's files go stale. This is the same family as the final pass's F4 residual (a layout git cannot see either). Not executed.
3. **An admin dir that has no HEAD (an interrupted `worktree add`).** By trace this refuses (HEAD must be a plain file), so it fails closed. Not executed.

Because of Findings 1-3 and these candidates, the holder count and the rebase scan appear nowhere under Endorsement Claims.

## Endorsement Claims

- **Claim:** The final pass's three executed fail-opens (gitdir missing, empty or mode 000; CRLF, directory and mode-000 rebase/bisect state; symbolic main) now refuse at a5837597 with main unmoved.
  **Location:** `scripts/build-loop.sh:384, 1073-1089, 1125`
  **Evidence:** executed
  **Verified:** r0, r0b, r1×3, r2×6, r3 (table above).
  **Not verified:** the same mechanisms in dot-named admin dirs other than Finding 3's rebase-merge case.
  **route: code-fact-check**

- **Claim:** Honest non-bare layouts land as before: no worktree on main (CAS), a linked W on main, the main worktree on main, a locked W, worktree names with spaces and dots (`my wt.v2`, `o..x y`), a prunable worktree on another branch, `--separate-git-dir`, and a symlinked `.git`. A prunable worktree registered on main refuses "missing", the same as at 6cbca87c.
  **Location:** `scripts/build-loop.sh:1053-1146`
  **Evidence:** executed
  **Verified:** n3 and n4 runs, each NEW output compared with the OLD (6cbca87c) output.
  **Not verified:** a repo whose `$common/worktrees` holds an honest non-directory entry written by another git version.
  **route: code-fact-check**

- **Claim:** The `merge-bats` suite passes at a5837597.
  **Location:** `test/scripts/build-loop-merge.bats`
  **Evidence:** executed
  **Verified:** TAP `1..6`, `ok 1` to `ok 6`.
  **Not verified:** the other build-loop suites (`build-loop-*.bats`), which this diff does not touch.

## Primitive sweep

Primitive: land's reads of admin-dir state that decide land-or-refuse, and the ref writes they guard (every site in the diff scope)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:384` `symbolic-ref -q refs/heads/$MAIN` | S3 | refuse | cleared for main (r3); Finding 2 (other symrefs to main) |
| `build-loop.sh:1033` identity regex `<([^\<\>]+)>` | S1, S2 | regex | cleared (bats case for committer.email only) |
| `build-loop.sh:1057` `worktree list --porcelain -z` | S5, S6 | cross-checked by the count | cleared as a source; the count's inputs are Findings 1-4 |
| `build-loop.sh:1073` searchability loop | S5 | `-d -r -x`, `! -L` | Finding 3 (dot-name rebase dirs omitted); cleared for admin dirs, worktrees/ and $common (r0, r0b) |
| `build-loop.sh:1079-1080` plain-file check on HEAD and state | S5 | `-f -r ! -L` | cleared for dir, mode 000 and symlink; Finding 5 (honest symlink HEAD) |
| `build-loop.sh:1082` `state_is HEAD "ref: refs/heads/$MAIN"` | S5 | awk normalisation | **Finding 1** (CR/LF separator), **Finding 2** (symref chain), **Finding 4** (bare HEAD) |
| `build-loop.sh:1084-1087` `state_is` head-name, update-refs, BISECT_START | S5 | `-f` then awk | cleared for CRLF and blanks (r2, bats); over-matching is the fail-closed direction |
| `build-loop.sh:1089` count vs list | S5, S6 | equality | Findings 1-4 feed it |
| `build-loop.sh:1095-1097` W `-ef` holder git dir | S4, S5 | `-ef` | cleared (a mismatched holder refuses: n=1 with a different hd refused by trace); candidate 2 |
| `build-loop.sh:1125` `update-ref --no-deref` CAS | S3 | old value MAIN_SHA | cleared (main not symbolic, r3); still moves main under a hidden holder (Findings 1-3) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | state_is misses `ref:\r…`/`ref:\n…` HEAD that git reads as main; with gitdir gone, CAS under W | Medium | B4 | `build-loop.sh:1052, 1082, 1089` | High |
| 2 | Worktree on a symbolic alias of main not counted; with gitdir gone, CAS under it | Medium | B3, B4 | `build-loop.sh:384, 1082` | High |
| 3 | Dot-named admin dir's unsearchable rebase-merge reads as absent; `rebase --abort` undoes the merge | Medium | B4 | `build-loop.sh:1073, 1080` | High |
| 4 | Honest bare repo + worktrees always refuses (regression vs 6cbca87c) | Low | B4 | `build-loop.sh:1081-1089` | High |
| 5 | `core.preferSymlinkRefs` symlink HEAD now refuses (regression, deprecated config) | Informational | B4 | `build-loop.sh:1079-1080` | High |

## Overall Assessment

The fix batch closes every mechanism the final pass executed (E1-E6 re-run clean), the suite passes, and honest non-bare layouts land exactly as before. In every executed case main still pointed at the judged NEW. The damage in Findings 1-3 is to a hidden holder's work tree or to main's later history, never to which tree landed. The class is still open in three non-racing ways, though, because land's admin-dir reading still differs from git's in places: HEAD's whitespace set (1), symref chains (2), and one glob list that omits dot names (3). Finding 4 is an honest-path regression the brief puts in scope. The single most important change, which fixes 1, 2 and 5 at once, is to read each admin dir's HEAD through git (`git --git-dir="$d" symbolic-ref -q HEAD`), not by hand. Then check searchability per admin dir inside the second loop (3), and skip a bare repo's own HEAD (4). Each is local and needs one bats case. Verdict: no further findings within the code paths read; endorsement claims pending execution verification. This is not a categorical all-clear.

## Goal-Alignment Note
- Success criterion (verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/security-review-2026-10-10-u3a2-confirm.md, structured per the security-reviewer skill.
- Answered: I re-ran F1-F3 (and E1/E2's variants) at a5837597, and all of them refuse. I searched the rest of the class (non-racing moves under a holder, rebase/bisect, unreadable-as-absent) and found three executed Mediums. I probed the honest-repo regressions the brief named: prunable and locked worktrees, names with dots or spaces, separate git dir, symlinked .git, bare, and symlink HEAD. Bare is a real regression.
- Out of scope: racing same-uid writers (Q-103; rows 509, 646); row 669 (`--no-deref` untested), which I accept as logged.
- Escalate: none (no HALT pattern). Findings 1-3 are Medium fail-opens on planted state, the same class and severity as the final pass's F1-F3, which this loop chose to fix. Finding 4 is an honest-path regression. The orchestrator should decide whether these are Must Fix for this loop. My recommendation is to fix all four: one shared change for 1, 2 and 5, plus small changes for 3 and 4.
