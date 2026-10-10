# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3a2 (feat/build-loop-u3a2)
**Commit:** a5837597
**Replication:** k=1 (confirming pass)
**Scope:** `git diff 6cbca87c..a5837597 -- scripts test` (commits f331f7bf and a5837597): `scripts/build-loop.sh`, `test/scripts/build-loop-merge.bats`, and the two commit messages. The rest of the branch is committed context and was reviewed earlier.
**Checked:** 2026-10-10
**Total claims checked:** 28
**Summary:** 19 verified, 3 mostly accurate, 0 stale, 5 incorrect, 1 unverifiable

Execution logs live under the scratch dir `/tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-confirm-fc/`, written `FC/` below. Every probe ran under `timeout` in `mktemp -d /tmp/u3a2c-fc-XXXX` dirs, which were removed afterwards. git is 2.39.5. Mutants ran on copies of `scripts/` and `test/` in temp dirs. Nothing was written into the worktree except this file.

Hallucination log (`docs/reviews/hallucination-patterns.md`): I compared every claim with the logged patterns. Claims 23-25 are measured-count claims, the class of the logged "specific measured value" entries. 389, 390 and the suite counts reproduce. 416 cannot be reproduced from any commit (Claim 24), but it is a working-state figure, not a fabricated symbol, so it is not logged.

---

## Claim 1: "both main and master present, the default branch a symbolic ref, or origin/HEAD naming another branch than the one taken"

**Location:** `scripts/build-loop.sh:101-103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --check/--merge startup refusal of a symbolic `refs/heads/$MAIN`, which exits 2 with a "refuse state default-branch" line and leaves the target unmoved. It does not establish behaviour for a symbolic origin/HEAD target, which is a separate clause and unchanged.

The code: `if git symbolic-ref -q "refs/heads/$MAIN" >/dev/null; then echo "refuse state default-branch: refs/heads/$MAIN is a symbolic ref"; bad=1; fi` (`scripts/build-loop.sh:384`), inside `default_gate`, which `gate_start` calls first (`default_gate || exit 2`, `:925`). Probe "symbolic main" printed `status 2: refuse state default-branch: refs/heads/main is a symbolic ref`, and trunk stayed at M.

Command: `cd $T && TMPDIR=$T timeout 600 bats --show-output-of-passing-tests FC/probe-land.bats`, cwd a `/tmp/u3a2c-fc-*` dir, 2026-10-10T21:49:10Z, test 9 ok.

**Evidence:** `scripts/build-loop.sh:377-390`, `FC/probe-land.out`

---

## Claim 2: "each email non-empty; EMAIL or a guess from the host refuses instead"

**Location:** `scripts/build-loop.sh:222-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge_ident refusing an empty author or committer email, whether it comes from the environment (`GIT_AUTHOR_EMAIL=`) or from a partial config identity (name plus committer.email only). It does not establish that git itself refuses empty emails. It does not: see below.

The regex now needs one or more characters inside the brackets: `^([^\<\>]+)\ \<([^\<\>]+)\>\ [0123456789]+\ [-+][0123456789]{4}$` (`scripts/build-loop.sh:1033`). Probe "identity" showed that git 2.39.5 accepts an empty email: `user.email empty: var rc=0 out=g <> ...`, `commit rc=0`, and `committer.email only, author: rc=0 out=g <> ...`. The script is therefore stricter than git, as the header says. `--merge` with `GIT_AUTHOR_EMAIL=` printed `refuse ...: git knows no author or committer identity (...)`. Mutant m3 (`+` back to `*`) fails the merge suite.

Command: `bats -f 'honest|real rebase|identity' FC/probe-land.bats`, 2026-10-10T21:49:42Z, exit 1 (an unrelated probe, fixed later in `FC/probe-land3.out`). The identity test is ok.

**Evidence:** `scripts/build-loop.sh:1029-1036`, `FC/probe-land2.out`, `FC/mut-m3_empty_email.log`

---

## Claim 3: The --merge refusal list names every new MERGE_WHY, and each refusal is reached for its shape

**Location:** `scripts/build-loop.sh:229-249`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six MERGE_WHY strings that f331f7bf and a5837597 add or change: the git directory or rebase state; git state ($q); rebasing; bisecting; the list does not show it; W's git directory. Each maps to a header clause, and each was produced by a real or planted shape. It does not establish the parenthetical definition of "cannot be read" (Claim 4), and it does not re-check refusals that predate this commit range.

Strings in the code: `"a worktree's git directory or rebase state cannot be read"` (`:1074`), `"a worktree's git state ($q) cannot be read"` (`:1080`), `"a worktree is rebasing the default branch"` (`:1085`), `"a worktree is bisecting from the default branch"` (`:1087`), `"a worktree has the default branch checked out that git worktree list does not show"` (`:1089`), and `"... not the one whose git directory names the branch ..."` (`:1099`). Each has a header clause: "a worktree's own git directory, HEAD or rebase or bisect state cannot be read", "or in one git worktree list does not show", "a worktree is rebasing it ... or bisecting from it", and "(or not the worktree whose git directory names the branch)".

How each was reached:
- Admin dir mode 000 and `worktrees/` mode 000 gave "git directory or rebase state". HEAD as a directory gave "git state (HEAD)". A gitdir file pointing at another worktree's dir gave the W git-dir message (`FC/probe-land4.out`).
- A real paused `rebase --exec false` of main in a linked worktree gave "rebasing" (`FC/probe-land3.out`).
- A real `git bisect start` in a worktree on main gave "bisecting" (`FC/probe-land.out` test 4).
- A gitdir file that was gone, mode 000 or emptied gave "list does not show" (`FC/probe-land.out` test 8).
- The merge suite covers the rest (6/6, `FC/suite-build-loop-merge.bats.log`).

Honest repos still merge:
- R on main, with linked worktrees mid a real rebase of feat/y, detached, prunable (dir deleted, `prunable` count 1), locked, on another branch, and bisecting from feat/x: `merged`.
- W a linked worktree on main, with R detached plus a detached and a rebasing worktree: merged in W (`FC/probe-land3.out` test 1, `FC/probe-land2.out` test 2).

**Evidence:** `scripts/build-loop.sh:1053-1135`, `FC/probe-land.out`, `FC/probe-land2.out`, `FC/probe-land3.out`, `FC/probe-land4.out`

---

## Claim 4: "the worktrees, the git directory or a worktree's own git directory, HEAD or rebase or bisect state cannot be read (exists but is not a readable plain file in a searchable directory)"

**Location:** `scripts/build-loop.sh:231-234`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which unreadable shapes refuse. It does not establish whether git could act on the shape that is missed. git cannot read inside a mode-000 dir either, so damage needs the permission restored first.

A rebase-merge or rebase-apply dir that exists but cannot be searched does not refuse when its admin dir has a dot name. The searchability loop globs `"$common"/worktrees/*/rebase-{merge,apply}` (`scripts/build-loop.sh:1073`), and `*` does not match dot names. The second loop does include `.[!.]*` and `..?*` (`:1076`), but its tests `[[ "$q" != HEAD && ! -e "$d/$q" && ! -L "$d/$q" ]] && continue` (`:1079`) and `[[ ! -f "$d/$q" ]] || ...` (`:1085`) read a file inside a mode-000 dir as absent.

Probe "dot-named admin dir with a mode-000 rebase-merge": `.git/worktrees/.x/{HEAD,rebase-merge/head-name=refs/heads/main}`, then `chmod 000 .x/rebase-merge`. Result: `status 0: merged ...`. The same shape under a non-dot name refuses (merge suite, `chmod 000 "$a/rebase-merge"`). git itself never creates dot-named ids (`git worktree add .../.hid` made `-hid`, probe test 6), but it does enumerate such entries, so this is planted state, which the threat model covers. The parenthetical is also narrower than the code: an admin dir with no HEAD refuses ("git state (HEAD) cannot be read", probe test 7), and absent is not "exists but is not readable". That error is on the safe side.

Command: `bats --show-output-of-passing-tests FC/probe-land.bats`, 2026-10-10T21:49:10Z, test 5 `not ok` (the assertion expected a refusal).

**Evidence:** `scripts/build-loop.sh:1073-1081`, `FC/probe-land.out`

---

## Claim 5: "or in one git worktree list does not show (its gitdir file gone)"

**Location:** `scripts/build-loop.sh:234-236`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a linked worktree on main whose gitdir file is moved away, mode 000 or empty: git worktree list drops it, and land refuses. It does not cover a checkout whose git dir lies outside `worktrees/` (Claim 7's residual).

`[[ "$n" -eq "$([[ -n "$w" ]] && echo 1 || echo 0)" ]] || { MERGE_WHY="a worktree has the default branch checked out that git worktree list does not show"; ...}` (`:1089`). In the probe, `git worktree list --porcelain | grep -c '^worktree'` printed 1 (w2 dropped) for both the mode-000 and the empty gitdir. `git -C w2 symbolic-ref HEAD` printed `refs/heads/main`. land refused both, and plain `git checkout -q main` in R then succeeded ("git let R check out main while w2 holds it"). git therefore does not see the hold, but the worktree still has main checked out.

**Evidence:** `scripts/build-loop.sh:1082,1089`, `test/scripts/build-loop-merge.bats:158-159`, `FC/probe-land.out`

---

## Claim 6: W "is not its own top level (or not the worktree whose git directory names the branch)"

**Location:** `scripts/build-loop.sh:242-243`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--absolute-git-dir -ef "$hd"` comparison refusing when a listed W's real git dir is not the admin dir whose HEAD names main. It does not establish test coverage: no suite test reaches this clause apart from the others (Claim 22).

`"$(git -C "$w" rev-parse --absolute-git-dir)" -ef "$hd"` (`:1096`). In the probe, worktree a (on main) had its gitdir file pointed at d1. The list then showed d1 twice, once with `branch refs/heads/main`, and `--merge` refused with `... not the one whose git directory names the branch, or not on it at ...`, leaving main unmoved (`FC/probe-land4.out`). Mutant m8, which drops the comparison, passes the merge suite (`FC/mutants.out`).

**Evidence:** `scripts/build-loop.sh:1096-1099`, `FC/probe-land4.out`, `FC/mut-m8_no_gitdir_ef.log`

---

## Claim 7: "Residual: ... a checkout whose git directory lies outside the repository's worktrees/, which neither git nor the gate can see."

**Location:** `scripts/build-loop.sh:250-254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a hand-made checkout whose `.git` file names a git dir outside `worktrees/` with `commondir` pointing at the repo: git uses it, `worktree list` omits it, and --merge proceeds. It does not execute the racing residual (the first clause), which is a timing claim.

In the probe, `git -C outside symbolic-ref HEAD` printed `refs/heads/main`, `git worktree list` showed 1 worktree, and `--merge` printed `status 0: merged ...`.

**Evidence:** `scripts/build-loop.sh:1072-1089`, `FC/probe-land.out` (test 11)

---

## Claim 8: "A symbolic default branch: a worktree on it lists as its target's, and update-ref would move the target (final security F3)."

**Location:** `scripts/build-loop.sh:382-383`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's listing of a worktree on a symbolic main, and plain versus `--no-deref` update-ref on it. It does not establish other git versions.

Probe: with `refs/heads/main -> refs/heads/trunk`, `git worktree add ../w main` wrote `ref: refs/heads/main`, and `worktree list --porcelain` showed `branch refs/heads/trunk`. A plain `update-ref refs/heads/main N M` moved trunk. `update-ref --no-deref` left trunk alone and replaced the symref with a plain ref (`main symref still: no`).

Command: `timeout 60 FC/probe-symref.sh`, 2026-10-10T21:52:47Z, exit 0.

**Evidence:** `scripts/build-loop.sh:382-384,1125`, `FC/probe-symref.out`

---

## Claim 9: "--merge moves the branch ... in W (merge --ff-only, after land's reads there: the state gate, rev-parse, --git-path probes, git status); its worktree list, git-common-dir and the worktrees' state files are read in the real repository, and merge_ident alone (git var) reads the caller's global config."

**Location:** `scripts/build-loop.sh:916-922`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list of git calls land runs in W and where its other reads happen. It does not establish what config each of those calls reads.

The git calls in W are `rev-parse --show-toplevel`, `rev-parse --absolute-git-dir`, `symbolic-ref -q HEAD`, `rev-parse --verify -q 'HEAD^{commit}'`, the `--git-path` loop, `status`, and the final `merge` (`scripts/build-loop.sh:1096-1104,1131`). `symbolic-ref -q HEAD` (`:1097`) is missing from the list. The worktree list (`:1058`) and `--git-common-dir` (`:1072`) run in the real repository. Only merge_ident uses `env "${CALLER_GLOBAL[@]}"` (`:1032`), against `GIT_CONFIG_GLOBAL=/dev/null` exported at `:334`. A precise version adds symbolic-ref to the list.

**Evidence:** `scripts/build-loop.sh:331-334,1032,1058,1072,1096-1104,1131`

---

## Claim 10: "Decide (the header's refusals, in its order: ...)"

**Location:** `scripts/build-loop.sh:1039-1041`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether land checks in the order the header lists. It does not establish which refusal wins when two shapes coexist in a case not listed here.

The order differs in two places:
- "Checked out in two worktrees" is decided in the list loop (`:1062`), before the git-dir reads (`:1072-1081`). The header lists "cannot be read" first.
- The holder count (`:1089`) runs after the rebase and bisect scan (`:1084-1087`). The header puts "one git worktree list does not show" before "rebasing".

The rest matches: the W checks run in header order (`:1094-1116`), then the write (`:1118-1120`), the re-gate (`:1122`) and the move.

**Evidence:** `scripts/build-loop.sh:229-249,1056-1134`

---

## Claim 11: "a refusal after the write leaves NEW set and, but after a racing branch switch in W, unreachable"

**Location:** `scripts/build-loop.sh:1045-1046`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the four refusals after `NEW="$x"`. It does not establish reflog or ORIG_HEAD references in W after a failed `merge --ff-only`.

`NEW="$x"` (`:1121`) is followed by:
- the re-gate refusal (`:1123`), where nothing has moved;
- the update-ref failure (`:1126`), where the CAS did not apply;
- the ff failure (`:1132`);
- "not at the merge after the fast-forward" (`:1133`). Only here can W's HEAD have moved a different branch to NEW, after a racing switch.

**Evidence:** `scripts/build-loop.sh:1118-1134`

---

## Claim 12: "state_is FILE WANT: a line of git's state file FILE is WANT, read as git reads it (blanks and a CR at either end dropped; "ref:" and its target split by any blanks)."

**Location:** `scripts/build-loop.sh:1049-1052`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's reading of rebase-merge/head-name (`git branch -f` checked-out detection and `rebase --abort`), linked-worktree HEAD (symbolic-ref, worktree list, branch -f) and BISECT_START (branch -f), compared with state_is. It does not establish other git versions. No case was found where git reads main and state_is does not, so state_is fails closed.

state_is strips `[ \t\r]` at both ends of every line (`:1052`). git does not:
- **head-name.** `' refs/heads/main \r\n'`, `'refs/heads/main \n'` and `'\trefs/heads/main\n'` are not main to git: `branch -f main` succeeds, and `rebase --abort` leaves main unmoved. Only `\n` and `\r\n` endings are main to git. branch -f strips only trailing LFs, so with `\r\n` it allows the move while abort strips one LF then one CR and resets main (`FC/probe-headname.out`).
- **HEAD.** Trailing blanks and CR are dropped (`'ref:\trefs/heads/main  \n'` reads as main), but leading ones are not: `' ref: refs/heads/main\n'` gives `not a git repository` and an all-zero HEAD in the list (`FC/probe-head.out`).

state_is therefore matches strictly more than git does. The precise statement: git drops trailing LFs (and for abort one CR, for HEAD trailing whitespace) and no leading blanks; state_is drops more, which is safe.

Commands: `timeout 120 FC/probe-headname.sh` (2026-10-10T21:47:28Z, exit 0) and `timeout 120 FC/probe-head.sh` (2026-10-10T21:48:00Z, exit 0).

**Evidence:** `scripts/build-loop.sh:1052`, `FC/probe-headname.out`, `FC/probe-head.out`

---

## Claim 13: "Its HEAD names the branch it has checked out, so a worktree git worktree list drops (its gitdir file gone or unreadable) still counts; its rebase state names a branch a rebase will move (worktree list shows a rebasing worktree as detached)."

**Location:** `scripts/build-loop.sh:1066-1069`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the HEAD-based count for dropped worktrees (gone, mode 000 or empty gitdir) and the detached listing of a real rebasing worktree. It does not cover dot-named admin dirs' rebase state (Claim 14).

`if state_is "$d/HEAD" "ref: refs/heads/$MAIN"; then n=$((n + 1)); hd="$d"; fi` (`:1082`). Claim 5's probes show the dropped worktree is counted. The real rebase of main listed `rb` as `detached` (`FC/probe-land3.out`: `worktree .../rb HEAD ... detached`) and was refused by its head-name.

**Evidence:** `scripts/build-loop.sh:1076-1089`, `FC/probe-land.out`, `FC/probe-land3.out`

---

## Claim 14: "the common one and every entry under worktrees/ (dot names too) ... Anything that exists but is not a readable plain file in a searchable directory refuses"

**Location:** `scripts/build-loop.sh:1065-1071`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers searchability of rebase dirs in dot-named admin dirs. It does not re-check non-dot shapes, which refuse (Claim 3). This is the same root cause as Claim 4, at the comment that states it.

The first loop lists `"$common"/worktrees/*/rebase-{merge,apply}` with no `.[!.]*`/`..?*` counterpart (`:1073`). A mode-000 `worktrees/.x/rebase-merge` holding head-name `refs/heads/main` merged (`status 0`, `FC/probe-land.out` test 5). A dot-named head-name that is a directory or mode 000 does still refuse, through the second loop's plain-file test (`:1080`). The gap is the unsearchable rebase dir only.

**Evidence:** `scripts/build-loop.sh:1073-1087`, `FC/probe-land.out`

---

## Claim 15: "W's own config.worktree before any git command reads its work tree or index (git status would run a filter it names; the gate's own reads run none)"

**Location:** `scripts/build-loop.sh:1091-1093`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ordering: `(cd "$w" && state_gate)` runs before any `git -C "$w"` call. It does not establish that state_gate's own git calls read no work tree, beyond the filter test.

`[[ -d "$w" ]] || ...; (cd "$w" && state_gate) > "$GATE_TMP/state" || ...` (`:1094-1095`) comes before `git -C "$w" rev-parse` (`:1096`). The suite's config.worktree filter test asserts `[ ! -e "$BATS_TEST_TMPDIR/ran" ]` and passes (6/6).

**Evidence:** `scripts/build-loop.sh:1090-1104`, `test/scripts/build-loop-merge.bats:152-155`, `FC/suite-build-loop-merge.bats.log`

---

## Claim 16: "the CAS is --no-deref (E6)"

**Location:** `scripts/build-loop.sh:1125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the flag's presence and git's behaviour with it on a symbolic main. It does not establish test coverage: mutant m2, which drops `--no-deref`, passes the suite because default_gate refuses first. That was already listed as E11.

`git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA"` (`:1125`). For git's behaviour, see Claim 8.

**Evidence:** `scripts/build-loop.sh:1125`, `FC/probe-symref.out`, `FC/mut-m2_no_deref_dropped.log`

---

## Claim 17: "A symbolic default branch refuses before any brief (final security F3)."

**Location:** `test/scripts/build-loop-merge.bats:63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test asserting exit 2, the exact refusal line and trunk unmoved. It does not cover --no-deref (Claim 16).

The test asserts `[ "$status" -eq 2 ] && [ "$output" = "refuse state default-branch: refs/heads/main is a symbolic ref" ] && [ "$(git rev-parse trunk)" = "$M" ]` (`:65`). It passes, and mutant m1 fails it.

**Evidence:** `test/scripts/build-loop-merge.bats:63-65`, `FC/mut-m1_no_symref_gate.log`

---

## Claim 18: "A name with only committer.email set: the author's email would be empty (final fact-check 5)."

**Location:** `test/scripts/build-loop-merge.bats:78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git var's author ident for `[user] name = g` plus `[committer] email = c@...`. It does not cover other partial configurations.

Probe output: `committer.email only, author: rc=0 out=g <> ...`.

**Evidence:** `test/scripts/build-loop-merge.bats:78-80`, `FC/probe-land2.out`

---

## Claim 19: "As git reads it: a CR and blanks around the name (final security F2)."

**Location:** `test/scripts/build-loop-merge.bats:126`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's reading of the test's exact bytes `' refs/heads/main \r\n'`. It does not dispute that the refusal is a safe outcome.

The line is `printf ' refs/heads/main \r\n' > "$a/rebase-merge/head-name"` (`:127`). git does not read that as main: `branch -f main` succeeds and `rebase --abort` leaves main unmoved (`FC/probe-headname.out` row `\ refs/heads/main\ \\r\\n`). The shape git does read as main, `'refs/heads/main\r\n'`, which abort resets, is not the one this test plants. It is covered only through state_is's superset.

**Evidence:** `test/scripts/build-loop-merge.bats:126-127`, `FC/probe-headname.out`

---

## Claim 20: "Its gitdir file gone, git worktree list drops w2, which still has main checked out (final security F1)."

**Location:** `test/scripts/build-loop-merge.bats:158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the moved-gitdir shape. Claim 5 covers the mode-000 and empty variants.

See Claim 5: the list shows 1 worktree, w2's HEAD is `refs/heads/main`, and land refuses.

**Evidence:** `test/scripts/build-loop-merge.bats:157-160`, `FC/probe-land.out`

---

## Claim 21: "six new mutants each fail the suite"

**Location:** commit f331f7bf message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the existence of at least six distinct mutants of f331f7bf's new lines that the merge suite kills. The commit does not name its six, so this does not confirm that the author's six were these.

Nine mutants of the new code were applied to copies, each against the merge suite. Killed: m1 symref gate, m3 empty email, m4 raw grep for state_is, m5 no searchability loop, m6 no plain-file check, m7 no holder count, m9 BISECT_START not plain-checked. Surviving: m2 (`--no-deref` dropped) and m8 (`-ef "$hd"` dropped).

Command: `python3 -I FC/mutants.py ... && TMPDIR=$T timeout 600 bats $C/test/scripts/build-loop-merge.bats`, per mutant, 2026-10-10T21:50:36Z.

**Evidence:** `FC/mutants.py`, `FC/mutants.out`, `FC/mut-*.log`

---

## Claim 22: "Tests for each shape"

**Location:** commit f331f7bf message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which f331f7bf checks have a test that fails without them. It does not judge whether the untested checks need tests.

Every E-item shape named in the message has a test (deleted gitdir, mode-000 dir, state as a directory, CRLF-and-blanks head-name, symbolic main, empty email). The new W git-dir comparison (`:1096`) has none, and its mutant m8 survives (Claim 6). `--no-deref` is untested too, as already recorded (E11).

**Evidence:** `scripts/build-loop.sh:1096`, `FC/mutants.out`

---

## Claim 23: "389 code lines" (f331f7bf) and "390 code lines" (a5837597)

**Location:** commit f331f7bf and a5837597 messages
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures measured with the stated command against current main (6666a5ce, the merge base). It does not establish what main was when the commits were made.

`git diff --numstat main <c> -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` gives f331f7bf 389 and a5837597 390 (and 6cbca87c 364). cwd is the worktree, exit 0.

**Evidence:** command output in this session (no file: the three numbers above are the whole output)

---

## Claim 24: "compressed ... from 416 to 389 code lines"

**Location:** commit f331f7bf message
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether 416 matches any committed state. It does not rule out 416 as the uncommitted pre-compression working tree.

The parent commit 6cbca87c measures 364 by the same command, so 416 is not a committed state. To verify it, one would need the working tree as it stood before compression.

**Evidence:** command output as Claim 23

---

## Claim 25: "Suites 6/145/20/79/2/2" (f331f7bf); "Merge suite 6/6" (a5837597)

**Location:** commit f331f7bf and a5837597 messages
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers runs at a5837597 of build-loop-merge (6), build-loop-check (145), build-loop-read (20), dev-cycle (79), and the 2-test suites fixture-git-env, utility-smoke and fixture-hermeticity (2 each; the message does not say which two). It does not cover runs at f331f7bf, which differs from a5837597 only in a comment and a message string.

All passed with exit 0, run serially with a fresh `TMPDIR` each: 6, 20, 2, 2, 2 ok (started 2026-10-10T21:46:21Z), then 145 and 79 ok with 0 not ok (finished by 21:48:24Z).

**Evidence:** `FC/suite-*.log`, `FC/bigsuites.txt`, `FC/suites.ts`

---

## Claim 26: "Tests ... compressed (no assertion dropped)"

**Location:** commit f331f7bf message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertion tokens (`[ ... ]`, `refused`, `nref`) in test/scripts/build-loop-merge.bats at 6cbca87c and at a5837597. It does not compare setup steps.

Assertion tokens went from 62 to 71, and the test count is 6 at both commits. Every old-only token is a refusal string the code reworded, and each has a new counterpart:
- 4× "rebasing ..., or its rebase state cannot be read" became 4× "rebasing the default branch" plus `$hn` for the chmod-000 head-name;
- bisect became bisect;
- the W message gained the git-dir clause.

**Evidence:** `FC/asserts.py`, `FC/merge-old.bats`, `FC/merge-new.bats`

---

## Claim 27: "compares values as git reads them (CR and blanks dropped)"

**Location:** commit f331f7bf message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same finding as Claim 12, at the commit message. Fail-closed behaviour is not disputed.

git does not drop blanks from head-name or leading blanks from HEAD. See Claim 12.

**Evidence:** `FC/probe-headname.out`, `FC/probe-head.out`

---

## Claim 28: "wording only"

**Location:** commit a5837597 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `git diff f331f7bf a5837597 -- scripts test`. It does not cover docs.

The diff changes the header lines `:242-243`, the MERGE_WHY string at `:1099` and the matching test expectation at `:151`. No logic changes.

**Evidence:** `scripts/build-loop.sh:242-243,1099`, `test/scripts/build-loop-merge.bats:151`

---

## Findings for the gate

- **F1. A dot-named admin dir with an unsearchable rebase dir is read as absent.**
  - Severity: Medium-Low. It is an in-scope planted, non-racing shape, and the same class as E2. git never creates dot ids, and it cannot read the state either until permissions are restored.
  - Confidence: High.
  - Legibility-target: header `:231-234` and land `:1065-1074`.
  - Evidence: `"$common"/worktrees/*/rebase-{merge,apply}` (`:1073`); probe `status 0: merged`.
  - The orchestrator should decide whether this counts as Must Fix under "any refusal the header promises".
- **F2. The "as git reads it" wording overstates git's trimming.**
  - Severity: Low. It fails closed.
  - Confidence: High.
  - Locations: `:1049-1051`, the test comment at `:126`, and the commit message.
- **F3. Comment precision.** Severity: Low.
  - "in its order" (`:1040`) does not match the code's order.
  - The list of land's git calls in W (`:917-918`) omits symbolic-ref.
  - The W git-dir check is untested (m8 survives).
- **E1-E6 status.** E1, E2 (except F1), E4, E5 and E6 are resolved by execution. E3 is resolved except for the F1 sub-case. No regression was found: all six suites pass, and the honest multi-worktree repos still merge.

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`scripts/build-loop.sh:231-234`): An unsearchable rebase-merge/rebase-apply under a dot-named admin dir does not refuse; extend the `:1073` glob to dot names, or narrow the header. An absent HEAD also refuses, beyond "exists but".
- **Claim 12** (`scripts/build-loop.sh:1049-1051`): git drops trailing LFs (one CR for abort; trailing whitespace for HEAD) and no leading blanks; state_is drops more, which is a safe superset.
- **Claim 14** (`scripts/build-loop.sh:1065-1071`): "(dot names too)" does not hold for the rebase-dir searchability check (same root cause as Claim 4).
- **Claim 19** (`test/scripts/build-loop-merge.bats:126`): git does not read `' refs/heads/main \r\n'` as main; the test plants a shape that only state_is's superset refuses.
- **Claim 27** (commit f331f7bf): "CR and blanks dropped" as git reads them; same as Claim 12.

### Stale
(none)

### Mostly Accurate
- **Claim 9** (`scripts/build-loop.sh:916-922`): Add `symbolic-ref` to the list of land's reads in W.
- **Claim 10** (`scripts/build-loop.sh:1039-1041`): The two-worktrees check precedes the git-dir reads, and the holder count follows the rebase/bisect scan, unlike the header's order.
- **Claim 22** (commit f331f7bf): "Tests for each shape". The W git-dir comparison has no test (mutant survives).

### Unverifiable
- **Claim 24** (commit f331f7bf): "from 416". The parent measures 364; 416 needs the uncommitted pre-compression tree.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/code-fact-check-report-u3a2-confirm.md, structured per the code-fact-check skill, with `**Commit:** a5837597` and `**Replication:** k=1 (confirming pass)`."
- **Answered:** All five requested claim areas are covered: the header state-gate and symbolic-ref clauses with the residual; land and state_is against git's own reading; the refusal shapes plus honest multi-worktree merges; the default_gate symref comment, --no-deref and the email regex; and the commit-message claims (mutants, line counts, suites, no assertion dropped).
- **Out of scope:** security severity ranking beyond F1-F3, and other git versions.
- **Escalate:** F1, a possible Must Fix under the E2 class. That decision belongs to the orchestrator.
