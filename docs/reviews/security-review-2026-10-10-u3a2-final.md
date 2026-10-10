# Security Review — feat/build-loop-u3a2 (final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test` at HEAD 6cbca87c (scripts/build-loop.sh, test/scripts/build-loop-merge.bats), plus `git log main..HEAD`
**Date:** 2026-10-10
**Based on:** Stage 1 fact-check summary (final pass, k=3 at 6cbca87c; docs/reviews/code-fact-check-report-u3a2-final-r{1,2,3}.md); prior passes docs/reviews/security-review-2026-10-10-u3a2-i{1,2}.md; override-log rows 653-666 and those named in the shared brief
**Probes:** /tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-final-security/ (p1-*, p2, p3, p4, p6; fixture from test/lib/build-loop-fixtures.bash, each in its own /tmp/u3a2i3-sec-* dir, all removed)

## Trust Boundary Map

```
B1: caller argv/env (BRIEF, --expect, GIT_* identity)  → usage parse, merge_ident regex     → land's commit and reflog text
B2: W's own git dir and work tree (config.worktree,     → (cd W && state_gate), -ef top level, → merge --ff-only in W
    HEAD, index, files)                                    status, CHANGED A-path checks
B3: repo-shared git state (common config, refs incl.    → state_gate / default_gate (start   → MAIN_SHA, CAS update-ref
    symbolic refs/heads/*, packed refs)                    and row 494 re-run)
B4: worktree registry and per-worktree state           → git worktree list --porcelain -z;  → "which worktree has main" (W or none);
    ($common/worktrees/*: gitdir, HEAD, rebase-*/,         land's own glob scan of head-name,    "nobody will move main later"
    BISECT_START)                                          update-refs, BISECT_START
B5: check_line verdict (VERDICT, CHANGED)              → values, not printed text            → commit-tree TREE, parents, path checks
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | caller argv and environment | request-time | trusted (header: the caller's environment is trusted) |
| S2 | caller's global git config (merge_ident only) | runtime-mutable | untrusted for exec sinks (none reached: `git var` only); trusted for identity text after the regex |
| S3 | repo common config, refs (incl. symbolic refs under refs/heads) | runtime-mutable (any same-uid loop) | UNTRUSTED toward exec and toward "which ref moves" |
| S4 | W's config.worktree, HEAD, index, work-tree files | runtime-mutable | UNTRUSTED toward exec (state-gated) and toward "W is clean" |
| S5 | $common/worktrees/* admin dirs (gitdir, HEAD, rebase state, BISECT_START) | runtime-mutable | UNTRUSTED toward the land-or-refuse decision; must fail closed when unreadable or unparseable |
| S6 | VERDICT/CHANGED from check_line | code-derived from judged objects | trusted for commit-tree inputs (judged at this run) |
| S7 | git's own behaviour (worktree list, read_oneliner, update-ref deref) | code-constant (git 2.39.5) | trusted, but its *interpretation* by land is the boundary |

What enters from outside: repo state a loop can write before the run (S3-S5). The diff's central assumption is that `git worktree list` plus a glob of `$common/worktrees/*` sees every worktree that has main checked out or will move it, and that land parses rebase/bisect state as git does. Both assumptions break on non-racing inputs (Findings 1-3).

## Findings

#### 1. `git worktree list` silently drops a registered worktree whose `gitdir` backlink is missing, empty or unreadable; land then moves main by CAS under that worktree

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1048-1053` (list and parse), `:1101-1103` (CAS); header `:229-230`
**Boundary:** B4
**Move:** 3 (error path), 5 (invert: what does "no W" not cover?)
**Confidence:** High (executed)
**Legibility-target:** land's worktree discovery; header refusal "the worktrees … cannot be read"

**Evidence:**
```
  git worktree list --porcelain -z > "$GATE_TMP/wts" || { MERGE_WHY="the worktrees could not be listed"; return 1; }
  while IFS= read -r -d '' x; do
    case "$x" in
      "worktree "*) p="${x#worktree }" ;;
      "branch refs/heads/$MAIN") [[ -z "$w" ]] || { ...two worktrees...; return 1; }; w="$p" ;;
```
git 2.39's get_linked_worktree returns NULL when `worktrees/<id>/gitdir` cannot be read or is empty, and `worktree list` exits 0 without that entry. The worktree itself keeps working: its `.git` file points at the admin dir, and the admin dir's HEAD is `ref: refs/heads/main`. Probe p1 (main worktree detached, linked W on main, run from a third detached worktree) gave the same result for each variant, `rm gitdir`, `: > gitdir` and `chmod 000 gitdir`: the list showed no W; W's `symbolic-ref HEAD` still read `refs/heads/main`; the output was `merged … exit 0`; main moved; `git -C W status` then showed `D  work-feat-x.txt`. W's HEAD is at NEW while its index and files are the old ones. A later `commit -a` in W reverts the merge. This widens the fact-check's r2 finding, which used a mode-000 admin dir, to plain file deletion or truncation, with no permission tricks. The same scan's glob (`:1059`) visits that admin dir and reads only its rebase state, never its HEAD. The header's "the worktrees … cannot be read" refusal never fires, because git reports success.

**Recommendation:** Do not take "who has main" from `worktree list` alone. In the existing `for d in "$common" "$common"/worktrees/*…` loop, read each admin dir's `HEAD` as a file and treat `ref: refs/heads/$MAIN` as W, whether or not the list shows it. Refuse when a HEAD is unreadable or not a regular file, when `$common/worktrees` exists but is not searchable/readable, or when an admin dir with main is missing from the list. Add a test that deletes W's `gitdir`.

#### 2. land parses rebase and bisect state differently from git: a CRLF `head-name`, a directory, or an unsearchable `rebase-merge/` reads as "not main", and a later `rebase --abort` undoes the merge

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1059-1067`; header `:231-232` ("or that state cannot be read"); commit 6cbca87c D1
**Boundary:** B4
**Move:** 2 (implicit parse assumption), 11 (bypasses for the scan)
**Confidence:** High (executed)
**Legibility-target:** land's rebase/bisect scan

**Evidence:**
```
    for q in rebase-merge/head-name rebase-apply/head-name rebase-merge/update-refs; do
      [[ ! -e "$d/$q" ]] || { [[ -r "$d/$q" ]] && ! grep -qxF "refs/heads/$MAIN" "$d/$q"; } \
        || { MERGE_WHY="a worktree is rebasing the default branch, or its rebase state cannot be read"; return 1; }
    done
    [[ ! -e "$d/BISECT_START" ]] || { [[ -r "$d/BISECT_START" ]] && [[ "$(<"$d/BISECT_START")" != "$MAIN" ]]; } \
```
git reads `head-name` with read_oneliner, which strips one trailing `\n` and then one `\r`. `grep -x` keeps the `\r`. Probe p3 set up a real paused `rebase -i` of main in worktree r, and the scan refused it. After `printf 'refs/heads/main\r\n' > head-name`, the run printed `merged … ` and main moved to NEW. Then `git rebase --abort` in r reset main to the pre-merge commit, undoing the landed merge. The fact-check's executed variants belong to the same class: head-name, update-refs or BISECT_START as a directory (`-r` is true on a dir and grep fails, so `! grep` passes), and an unsearchable `rebase-merge/` (mode 000, where `-e` on the child is false). By trace, BISECT_START has the same mismatch: git's `bisect reset` rtrims it, while `$(<…)` keeps a `\r` or trailing spaces. Its impact is smaller, since bisect reset checks main out rather than writing it. This scan is the only guard against a rebase that later rewrites main (worktree list shows a rebasing worktree as detached). Every way the scan can fail to parse the state reads as "not rebasing main".

**Recommendation:** Invert to fail closed. If `rebase-merge/` or `rebase-apply/` exists, require it to be a searchable directory. Require each state file present to be a readable regular file, and normalize it as git does (strip one `\n`, then one `\r`; rtrim for BISECT_START) before comparing. Refuse anything else. Add the unreadable-BISECT_START mutant test the fact-check found missing.

#### 3. A symbolic `refs/heads/main` hides W: worktree list reports W on the target branch, and the CAS update-ref dereferences, moving the target under W

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1051` (match on `branch refs/heads/$MAIN`), `:1102` (`git update-ref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA"`); `default_gate` `:369-380`
**Boundary:** B3, B4
**Move:** 5 (what does the match not cover?), 1 (S3 refs runtime-mutable)
**Confidence:** High (executed)
**Legibility-target:** default_gate / land's W match

**Evidence:**
```
      "branch refs/heads/$MAIN") [[ -z "$w" ]] || ...; w="$p" ;;
    git update-ref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" 2>/dev/null \
```
Probe p2 ran `git branch trunk main; git symbolic-ref refs/heads/main refs/heads/trunk` with the main worktree R checked out on main. `worktree list --porcelain` printed R as `branch refs/heads/trunk`, because git resolves HEAD fully. land therefore found no W and took the CAS path. update-ref without `--no-deref` moved trunk, and main followed through the symref. Output: `merged … `. Afterwards main = trunk = NEW, and R's status showed `D  work-feat-x.txt`, the same W damage as Finding 1, plus a second branch moved without being named. Main itself points at the judged NEW, so this is W integrity and an unannounced ref write, not an unjudged main. Neither state_gate nor default_gate looks at whether the default branch is itself a symbolic ref. A same-uid loop can plant one before the run with one porcelain command.

**Recommendation:** Refuse in default_gate (so the row-494 re-run covers it too) when `git symbolic-ref -q "refs/heads/$MAIN"` succeeds. Optionally also pass `--no-deref` to the CAS so it can only write the name it judged.

#### 4. An unregistered worktree (admin dir outside `$common/worktrees/`) is invisible to land and to git

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1048-1068`; header residual `:244-246`
**Boundary:** B4
**Move:** 5
**Confidence:** High (executed)
**Legibility-target:** header residuals

**Evidence:** probe p6 moved W's admin dir to `$common/wt-elsewhere`, pointed W's `.git` and `commondir` at it, and W still read `refs/heads/main` with top level W. Output: `merged …`, then `D  work-feat-x.txt` in W.

Git's own "already checked out" guard misses this layout too, and no enumeration can find a checkout git has no record of. This is a residual, not a fix target. It is listed so the header's residual sentence can name it ("a checkout git does not register"). It needs a deliberately hand-built layout, unlike Finding 1's single file deletion.

**Recommendation:** Name it in the header's Residual sentence; no code change.

#### 5. Identity regex accepts an empty email; the post-ff refusal leaves NEW reachable (fact-check r1, both Mostly accurate)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1019` (`<([^\<\>]*)>`); land comment `:1035-1036` / `:1110`
**Boundary:** B1
**Move:** 2
**Confidence:** High (executed by fact-check r1)
**Legibility-target:** merge_ident; land's comment

**Evidence:** `[[ "$x" =~ ^([^\<\>]+)\ \<([^\<\>]*)\>\ …` — with only `committer.email` set, the merge lands with `author=[u <>]`.

This is an attribution gap, not an integrity one: the trailer and reflog still name the gate. "Unreachable" is false for the "not at the merge" refusal after W switched branch.

**Recommendation:** Use `+` for the email group if an empty email should count as "no identity", and correct the comment. Either change is cosmetic for security.

## Untested bypass candidates

1. **A hand-edited `rebase-merge/git-rebase-todo` with an `update-ref refs/heads/main` line during a paused rebase**, where the `update-refs` state file does not list main. By trace of sequencer's do_update_ref, only refs already in `update-refs` are written, so this looks inert, but it was not executed.
2. **`rebase-merge/head-name` as a dangling symlink.** `-e` is false, so the scan passes it. git's read_oneliner also fails, so neither `--continue` nor `--abort` can write main. Not executed.
3. **`worktrees/<id>/HEAD` unreadable while the work tree is still used.** This is the chmod form of Finding 1, and Finding 1's recommendation covers it. Not executed separately.

Because of Findings 1-3 and these candidates, the worktree-discovery scan and the rebase/bisect scan appear nowhere under Endorsement Claims.

## Endorsement Claims

- **Claim:** With W on main and a locally edited tracked file marked `--assume-unchanged` or `--skip-worktree` that the merge modifies, `--merge` refuses ("the fast-forward … failed"), main is not moved, and the local edit survives.
  **Location:** `scripts/build-loop.sh:1081, 1108-1109`
  **Evidence:** executed
  **Verified:** probe p4, both index flags: exit 2, main equal to M, `f.txt` still `localedit`.
  **Not verified:** the same flag on a path the merge *deletes* (D), where git's ff may treat the file as up to date and remove it.
  **route: code-fact-check**

- **Claim:** A real paused `git rebase -i` of main in another linked worktree (LF-terminated head-name, written by git) is refused before the merge commit is written.
  **Location:** `scripts/build-loop.sh:1062-1064`
  **Evidence:** executed
  **Verified:** probe p3's first run: `refuse …: a worktree is rebasing the default branch, or its rebase state cannot be read`.
  **Not verified:** a paused `rebase` using the apply backend (`rebase-apply/head-name`) created by git rather than planted (the suite plants it).
  **route: code-fact-check**

- **Claim:** In every executed fail-open (p1, p2, p3, p6), main ended at the NEW that `merged` printed: a commit of the judged TREE with parents MAIN_SHA and TIP. The damage was to W (or to main's later history via `rebase --abort`), never to which tree landed.
  **Location:** `scripts/build-loop.sh:1095-1103`
  **Evidence:** executed
  **Verified:** each probe printed `main now N` equal to the NEW in the `merged` line. The judged tree `e4ae3d6d…` was identical across runs.
  **Not verified:** the ff path under a racing object rewrite (Q-103, out of scope).

## Primitive sweep

Primitive: reads of git state that decide land-or-refuse, and the ref writes they guard (all call sites in land)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:1018` `git -c user.useConfigOnly=true var` | S1, S2 | regex | Finding 5 (empty email) |
| `build-loop.sh:1048` `git worktree list --porcelain -z` | S5, S7 | exit status only | **Finding 1** (drops entries, exits 0); Finding 3 (resolved branch name) |
| `build-loop.sh:1058` `rev-parse --git-common-dir` | S3 | exit status | cleared |
| `build-loop.sh:1059` glob `"$common"/worktrees/{*,.[!.]*,..?*}` | S5 | `-d` | **Finding 1/2** (unsearchable worktrees/ yields no entries, silently) |
| `build-loop.sh:1062-1064` `grep -qxF` on head-name, update-refs | S5 | `-e`, `-r` | **Finding 2** (CRLF, dir, unsearchable parent); candidates 1-2 |
| `build-loop.sh:1066` `$(<BISECT_START)` | S5 | `-e`, `-r` | Finding 2 (dir, CR/space; lower impact) |
| `build-loop.sh:1073` `(cd "$w" && state_gate)` | S4 | itself | cleared (i2 F1 closed; first git command in W) |
| `build-loop.sh:1074-1076` `-ef` top level, `symbolic-ref -q HEAD`, HEAD == MAIN_SHA | S4 | exact compare | cleared (fails closed on symref chains in W, missing `.git`, core.worktree) |
| `build-loop.sh:1078` `rev-parse --git-path $q` in W | S4 | `! -e && ! -L` | cleared (fails closed on any type) |
| `build-loop.sh:1081` `git -C "$w" status` | S4 | empty stdout and stderr | cleared for assume-unchanged/skip-worktree via the ff's own refusal (p4) |
| `build-loop.sh:1083-1092` A-path and ancestor checks | S4, S6 | `-e`/`-L`/`-d` | cleared (i1/i2) |
| `build-loop.sh:1096` `gate_git commit-tree` | S6 | gate repo, `--no-gpg-sign`, hex check | cleared |
| `build-loop.sh:1099` state_gate, default_gate re-run | S3, S4 | itself | Finding 3 (default_gate does not check for a symbolic main) |
| `build-loop.sh:1102` `update-ref` CAS | S3 | old value MAIN_SHA | **Finding 3** (dereferences a symbolic main) |
| `build-loop.sh:1108-1110` `merge --ff-only` in W, then main == NEW | S4, S6 | `-c` overrides, post-check | cleared (i1 F1/F3) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Worktree list drops W when its `gitdir` is missing, empty or unreadable; CAS moves main under W | Medium | B4 | `build-loop.sh:1048-1053, 1102` | High |
| 2 | Rebase/bisect scan misparses CRLF, directory and unsearchable state as "not main"; `rebase --abort` later undoes the merge | Medium | B4 | `build-loop.sh:1059-1067` | High |
| 3 | Symbolic `refs/heads/main` hides W, and update-ref moves the target branch under W | Medium | B3, B4 | `build-loop.sh:1051, 1102`; `default_gate` | High |
| 4 | Unregistered worktree layout invisible to land and to git (residual) | Informational | B4 | header `:244-246` | High |
| 5 | Empty identity email accepted; "NEW unreachable" comment overclaims | Informational | B1 | `build-loop.sh:1019, 1035` | High |

## Overall Assessment

No probe made main point at anything but the judged merge commit. The landed tree and parents held in every executed case. The amber inventory for this unit is one class with three mechanisms, each executed and each on a non-racing path: land decides "nobody else has or will move main" from state it reads less faithfully than git does. Finding 1 (a deleted or emptied `gitdir`, no chmod needed) and Finding 3 (a symbolic main) damage the worktree that has main checked out. Finding 2 lets a paused rebase of main undo the landed merge. All three fail open, and the header promises the opposite ("cannot be read" refuses). Each fix is local: read admin HEADs directly and refuse on anything unreadable; normalize and type-check rebase state as git does; refuse a symbolic default branch in default_gate. Each needs one bats case. The sweep has no undispositioned rows. Verdict: no further findings within the code paths read; endorsement claims pending execution verification. This is not a categorical all-clear.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/security-review-2026-10-10-u3a2-final.md, structured per the security-reviewer skill.
- Answered: I assessed the fact-check's fail-opens (unsearchable admin dirs; rebase state as a dir or under an unsearchable dir) and confirmed they are one class. I extended it with three more executed mechanisms: a missing or empty `gitdir`, a CRLF head-name with abort damage shown, and a symbolic main. One residual is listed (an unregistered worktree). I checked for main moving to an unjudged commit and found none. I checked damage to W through index flags and found that it fails closed (p4).
- Out of scope: racing same-uid writers (Q-103; rows 509, 646); settled override rows 653-666 and those listed in the brief; test-strength mutants beyond noting the BISECT_START `-r` gap.
- Escalate: none (no HALT pattern). Findings 1-3 are Medium. The orchestrator decides whether to fix them in this loop or defer them with override rows. Each is a local change plus one test.
