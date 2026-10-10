Commit: 6cbca87c

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3a2 (branch feat/build-loop-u3a2)
**Scope:** `git diff main...HEAD -- scripts test` at 6cbca87c (scripts/build-loop.sh, test/scripts/build-loop-merge.bats), plus the commit messages from `git log main..HEAD`. This is the final confirming pass, replicate r1 of k=3.
**Checked:** 2026-10-10
**Total claims checked:** 31
**Summary:** 25 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance. Every executed claim below cites a log under `/tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-i3-fc-1/logs/` (`$LOGS` below). Nothing was written into the worktree except this report.
- **Suites.** `TMPDIR=$(mktemp -d /tmp/u3a2i3-fc1-XXXX) timeout 1200 bats test/scripts/<suite>.bats` ran serially for each suite, with cwd `/workspace/.claude/wt-build-loop-u3a2`, between 2026-10-10T21:17:32Z and 21:19:17Z. Every suite exited 0. Logs: `$LOGS/<suite>.log` and `$LOGS/summary.txt`.
- **Probes.** `bats test/scripts/probe-fc1.bats` ran at 21:18:30Z with cwd `$SCRATCH/tree`, a copy of scripts/ and test/ at HEAD. The probe file holds the merge suite's own helpers plus five probe tests. It exited 0. Log: `$LOGS/probe-fc1.log`.
- **Mutants.** `bats test/scripts/build-loop-merge.bats` ran in `$SCRATCH/mut-<M>`, each holding one mutated copy of build-loop.sh, between 21:19:10Z and 21:20:05Z. Logs: `$LOGS/mut-<M>.log` and `$LOGS/mut-summary.txt`.
- **Ad hoc probes.** Raw git commands ran under `/tmp/u3a2i3-fc1-*`, with git 2.39.5.

Hallucination-pattern log read. No claim below matches a logged pattern. The logged patterns are measured counts quoted from artifacts, and every count in this scope recomputes exactly.

---

## Claim 1: "scripts/build-loop.sh --merge BRIEF --expect SHA" (usage header and usage())

**Location:** `scripts/build-loop.sh:9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the usage synopsis and the arity guard that enforces one brief plus --expect. Does not establish the messages for a malformed --expect value, which are shared with --check (override row 665).

The usage text matches: `usage() { echo "$1 (usage: ... | --merge BRIEF --expect SHA)" >&2; exit 1; }` (`scripts/build-loop.sh:277`). The guard is `[[ "$MODE" == check || ( -n "$EXPECT" && ${#ARGS[@]} -eq 1 ) ]] || usage "--merge takes one brief path and --expect SHA"` (`:292`). Test 3 runs the shapes `"$B"`, `"--expect $T"` and `"$B $B --expect $T"`, and expects exit 1 with that message (`test/scripts/build-loop-merge.bats:87-90`). The test passed (`$LOGS/build-loop-merge.log`, exit 0).

**Evidence:** `scripts/build-loop.sh:277`, `scripts/build-loop.sh:282-294`, `test/scripts/build-loop-merge.bats:87-90`, `$LOGS/build-loop-merge.log`

---

## Claim 2: "merged BRIEF TIP TREE NEW ... a commit of TREE whose parents are main's commit and TIP, with the message "Merge branch 'BRANCH' (build-loop self-merge)" and the trailer "Build-loop-gate: STEM" (the brief's file name without .md)"

**Location:** `scripts/build-loop.sh:212-219`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merged line's field order and the merge commit's tree, parents, message and trailer. Does not establish how a STEM made of unusual characters would render, because pathform-limited brief names were the only ones tried.

The merged line is built as `v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"` (`:1143`). The commit is written with `printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "$1" "${VERDICT[stem]}"` and `gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}"` (`:1095-1096`). The stem is `stem="${a##*/}"; stem="${stem%.md}"` (`:987`). Test 1 asserts each of these values: the full output, `$n^1 $n^2 $n^{tree}` = `$M $T $TR`, and the message body. It passed.

**Evidence:** `scripts/build-loop.sh:987`, `scripts/build-loop.sh:1095-1098`, `scripts/build-loop.sh:1143`, `test/scripts/build-loop-merge.bats:43-57`, `$LOGS/build-loop-merge.log`

---

## Claim 3: "its reflog entry reads "build-loop: self-merge of STEM" (git adds ": Fast-forward" when W moves it)"

**Location:** `scripts/build-loop.sh:219-221`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default branch's reflog subject on both moves and the W HEAD reflog. Does not establish reflog behaviour when core.logAllRefUpdates is off, which this pass did not test.

The code sets `msg="build-loop: $1 of ${VERDICT[stem]}"` (`:1044`). The CAS path passes it with `git update-ref -m "$msg"` (`:1102`). The W path passes it with `GIT_REFLOG_ACTION="$msg" git -C "$w" ... merge --ff-only` (`:1108`). Test 1 asserts the reflog subject `build-loop: self-merge of 2026-10-01-x` after the CAS (`test/scripts/build-loop-merge.bats:54`). Test 4 asserts `...: Fast-forward` after W's move (`:102`). Probe P2 printed W's HEAD reflog as `build-loop: self-merge of 2026-10-01-x: Fast-forward` (`$LOGS/probe-fc1.log`).

**Evidence:** `scripts/build-loop.sh:1044`, `scripts/build-loop.sh:1102`, `scripts/build-loop.sh:1108`, `test/scripts/build-loop-merge.bats:54`, `test/scripts/build-loop-merge.bats:102`, `$LOGS/probe-fc1.log`

---

## Claim 4a: "Author and committer names and emails from GIT_AUTHOR_NAME/EMAIL and GIT_COMMITTER_NAME/EMAIL, or else git config (the caller's global file included, the system file not); EMAIL or a guess from the host refuses instead"

**Location:** `scripts/build-loop.sh:221-224`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of the identity sources, the caller's global file being read, the system file not being read, and an identity whose email would come only from EMAIL being refused. Does not establish the partial-configuration case, which is Claim 4b.

The identity comes from `env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var "GIT_${w}_IDENT"` (`:1018`). GIT_CONFIG_NOSYSTEM=1 remains exported from `:326`. Test 3 checks three cases (`test/scripts/build-loop-merge.bats:73-81`), and all of them passed:
- With no identity, it refuses.
- With names set and only EMAIL, it refuses.
- With `GIT_CONFIG_GLOBAL=$BATS_TEST_TMPDIR/gc`, it records `g g@example.invalid` as both author and committer.

An ad hoc probe confirmed what useConfigOnly changes:
- `GIT_AUTHOR_NAME=n EMAIL=e@x git var GIT_AUTHOR_IDENT` prints `n <e@x>` without the flag.
- `GIT_AUTHOR_NAME=n GIT_COMMITTER_NAME=n EMAIL=e@x git -c user.useConfigOnly=true var GIT_COMMITTER_IDENT` dies with `fatal: no email was given and auto-detection is disabled` and exits 128.

**Evidence:** `scripts/build-loop.sh:323`, `scripts/build-loop.sh:326`, `scripts/build-loop.sh:1015-1022`, `test/scripts/build-loop-merge.bats:71-81`, `$LOGS/build-loop-merge.log`

---

## Claim 4b: "Author and committer names and emails from ... or else git config ...; EMAIL or a guess from the host refuses instead" / "no identity is known" (refusal)

**Location:** `scripts/build-loop.sh:221-224`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 when only one side's email key (committer.email or author.email) is configured. Does not establish whether other git versions behave the same way.

When config sets `committer.email` and `user.name` but no `user.email`, `git -c user.useConfigOnly=true var GIT_AUTHOR_IDENT` exits 0 with `u <> ...`, an empty email. The regex in merge_ident accepts an empty email: `\<([^\<\>]*)\>` (`:1019`). End to end, probe P1 configured `committer.email` and `user.name` in the repo and unset GIT_AUTHOR_*/GIT_COMMITTER_*. It printed `status=0 out=merged ...` and the merge commit recorded `author=[u <>] committer=[u <c@example.invalid>]` (`$LOGS/probe-fc1.log`).

So the landed author's email comes from neither the environment nor git config, and the documented "no identity is known" refusal does not fire. The precise version: an email that git var resolves to empty, which happens when only the other side's email key is configured, lands as `<>`.

**Evidence:** `scripts/build-loop.sh:1018-1020`, `$LOGS/probe-fc1.log` (P1)

---

## Claim 5: "With the branch checked out in no worktree it moves by compare-and-swap from the checked commit; checked out in a worktree W, by merge --ff-only in W."

**Location:** `scripts/build-loop.sh:224-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the selection between the two moves, which depends on a worktree's `branch refs/heads/$MAIN` record. Does not establish behaviour on a case-insensitive ref store (override row 655).

The code reads `w="$p"` on `"branch refs/heads/$MAIN"` (`:1052`). It then runs `if [[ -z "$w" ]]; then git update-ref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" ... else ... merge --ff-only -q "$NEW"` (`:1101-1108`). Test 2's shim moves main before update-ref, and the CAS then refuses (`test/scripts/build-loop-merge.bats:59-64`). Test 4 covers the W fast-forward. Both passed.

**Evidence:** `scripts/build-loop.sh:1048-1054`, `scripts/build-loop.sh:1101-1111`, `test/scripts/build-loop-merge.bats:59-64`, `test/scripts/build-loop-merge.bats:93-115`

---

## Claim 6: The header's refusal list ("refuse BRIEF: WHY ... when: the policy --status reads is review; no identity is known; ... or its fast-forward fails or leaves the branch elsewhere")

**Location:** `scripts/build-loop.sh:227-246`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a two-way match between the header's list and every `MERGE_WHY=` assignment in land plus the merge arm's policy refusal. Does not establish that the header phrasing of the empty-email case is complete (Claim 4b), and does not cover runs that stop part way with no line, which the Exit line covers.

All 18 `MERGE_WHY=` sites in land (`:1046-1110`) and the arm's policy refusal (`:1142`) were enumerated. Each maps to a header clause:

| Code | Header clause |
|---|---|
| identity (`:1046`) | no identity is known |
| worktrees listed (`:1048`) and git dir (`:1058`) | the worktrees or the git directory cannot be read |
| two worktrees (`:1052`) | checked out in two worktrees |
| rebase scan (`:1064`) and bisect scan (`:1067`) | rebasing / paused rebase / bisecting, or unreadable |
| W missing (`:1072`) and W state gate (`:1073`) | W is missing or fails the state gate |
| `-ef`/symbolic-ref/HEAD (`:1076`) | not its own top level or not on the branch at the checked commit |
| in-progress state (`:1079`) | mid a merge, cherry-pick, revert, rebase, bisect or sequence |
| status (`:1082`) | tracked change, or git status fails or warns |
| added path (`:1085`) and directory (`:1091`) | untracked or ignored file / file or link where it adds a directory |
| commit-tree (`:1097`) | the merge commit cannot be written |
| re-gate (`:1100`) | the state gate or default_gate refuses again |
| CAS (`:1103`) | moved since the check, or cannot be updated |
| ff (`:1109`, `:1110`) | fast-forward fails or leaves the branch elsewhere |

The header lists nothing that has no matching site. The arm prints `{ echo "$v"; tail -n +2 "$GATE_TMP/line"; }` (`:1144`), which gives the "path lines following" clause. `cat "$GATE_TMP/line"; exit 2` when VERDICT is empty (`:1141`) gives "--check's own refusals and skips print as they are".

**Evidence:** `scripts/build-loop.sh:1043-1112`, `scripts/build-loop.sh:1134-1146`

---

## Claim 7: "Writes nothing but --check's merge objects ..., --merge's commit, the branch it moves and that branch's reflog (and in W: its files, index, HEAD reflog and ORIG_HEAD), and its own temporary directory"

**Location:** `scripts/build-loop.sh:249-253`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the files under .git, excluding object contents, that change during one successful CAS run and one successful W run in a fixture. Does not establish writes on refusal paths beyond the unreachable commit (Claim 15), or writes that a maintenance or gc run would make if it were enabled.

Probe P2 hashed every file under `.git` before and after each run (`$LOGS/probe-fc1.log`):
- The CAS run changed `logs/refs/heads/main` and `refs/heads/main` and added one loose object.
- The W run changed `ORIG_HEAD`, `index`, `logs/HEAD`, `logs/refs/heads/main` and `refs/heads/main`, plus the working tree.

git status in W writes no index because `GIT_OPTIONAL_LOCKS=0` is exported (`:326`).

**Evidence:** `scripts/build-loop.sh:326`, `scripts/build-loop.sh:1081`, `$LOGS/probe-fc1.log` (P2)

---

## Claim 8: "Exit: 0 every line printed (or help), for --check every verdict line ok, for --merge merged; 2 any other --check or --merge verdict line ... a failed mktemp (--check, --merge; no line printed)"

**Location:** `scripts/build-loop.sh:256-262`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge arm's exit codes for merged, refused, and skipped/--check-refused lines, and mktemp's place in gate_start. Does not establish every "failed command's own status" path, which comes from the pre-existing header text.

The merge arm runs `[[ "$v" == merged* ]] || exit 2` (`:1145`) and `cat ...; exit 2` (`:1141`). gate_start runs `GATE_TMP="$(mktemp -d)"` under `set -e` (`:912`), which exits with mktemp's status before any line prints. The tests assert status 0 on merged and 2 on refusals (`refused`, `nref`), and the second run in test 1 asserts status 2 on a --check refusal (`test/scripts/build-loop-merge.bats:56`). All passed.

**Evidence:** `scripts/build-loop.sh:912`, `scripts/build-loop.sh:1141-1145`, `test/scripts/build-loop-merge.bats:38-41`, `$LOGS/build-loop-merge.log`

---

## Claim 9: "The caller's global config, for merge_ident alone (the merge commit's names: all a loop that writes it could change there); every other call reads none."

**Location:** `scripts/build-loop.sh:321-323`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reference to CALLER_GLOBAL and the GIT_CONFIG_GLOBAL export that follows. Does not establish anything about git calls that run before `:326` (there are none in this file: lines 266-320 run perl's check, the lib's sourcing, scrub_reexec's bash re-exec and argument parsing), or about the caller's own `-c`/GIT_CONFIG_PARAMETERS, which harden trusts.

`grep CALLER_GLOBAL` hits only `:323` (the definition) and `:1018` (merge_ident). Immediately after, `export ... GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` (`:326`) applies to every later git call. scrub_reexec runs `DEV_CYCLE_SCRUBBED=1 bash "$self" "$@"` and no git (`scripts/lib/dev-cycle-read.sh:150-155`).

**Evidence:** `scripts/build-loop.sh:323`, `scripts/build-loop.sh:326`, `scripts/build-loop.sh:1018`, `scripts/lib/dev-cycle-read.sh:150-155`

---

## Claim 10: gate_start's repository rule: "main's files and refs, the branch tips, the checkout and store_check's object reads are in the real repository; the merge computations (merge-base, merge-tree, diff-tree, the blob checks) and --merge's commit-tree run through gate_git (into the real object store). --merge moves the branch in the real repository (update-ref) or in W (merge --ff-only), and merge_ident alone reads the caller's global config."

**Location:** `scripts/build-loop.sh:903-909`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each named read and write and the repository it runs in. Does not establish anything about W's own pre-move reads (state_gate, rev-parse and status run with `cd "$w"` or `git -C "$w"`), which the rule does not enumerate but which are the same repository's worktree.

The merge computations go through gate_git: merge-base and cat-file -e (`:705`, `:708`), merge-tree (`:709`), diff-tree (`:956`), cat-file --batch-check (`:972`), and own_blob's hash-object (`:725`). commit-tree also goes through gate_git (`:1096`), and gate_repo sets `GIT_OBJECT_DIRECTORY="$v"` to the real objects path (`:625-629`). The branch moves with `git update-ref` (`:1102`) or `git -C "$w" ... merge --ff-only` (`:1108`). store_check reads with plain `git cat-file --batch` (`:678`).

**Evidence:** `scripts/build-loop.sh:621-638`, `scripts/build-loop.sh:678`, `scripts/build-loop.sh:705-709`, `scripts/build-loop.sh:725`, `scripts/build-loop.sh:956`, `scripts/build-loop.sh:972`, `scripts/build-loop.sh:1096`, `scripts/build-loop.sh:1102-1108`

---

## Claim 11: "VERDICT holds tip, tree, policy, branch and stem, and CHANGED each changed path's status letter, only after an ok line (both empty otherwise)."

**Location:** `scripts/build-loop.sh:930-933`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return path of check_line, all of which were read from `:935` to `:1007`. Does not establish anything about need_root's exit inside the floor walk, which ends the run rather than returning.

Both arrays are emptied first: `VERDICT=(); CHANGED=()` (`:939`). The only writer is verdict_ok (`:990-995`), which also prints `echo "ok $a $sha $tree"`. Its two call sites are `if [[ -n "$co" ]]; then echo "$co"; else verdict_ok; fi; return` (`:996`) and `elif [[ "$nd" -eq 0 ]]; then verdict_ok` (`:1005`). Every other return (`:942`, `:944-947`, `:951-952`, `:957`, `:961`, `:967`, `:974`, `:977`, `:998`) comes before any call, and `:1005`'s other branches print refusals without calling it.

**Evidence:** `scripts/build-loop.sh:935-1007`

---

## Claim 12: "Reads check_line's locals (bash scope is dynamic); called only here."

**Location:** `scripts/build-loop.sh:989`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers verdict_ok's reads and call sites. Does not establish anything about the fact that bash defines verdict_ok globally once check_line has run (a later caller could call it). No such caller exists.

verdict_ok reads `$sha $tree $pol $br $stem $a` and `ps`/`ss`, all declared in check_line's `local` list (`:938`), and declares only `local i` (`:991`). `grep -n verdict_ok` finds the definition (`:990`) and the calls at `:996` and `:1005`, both inside check_line.

**Evidence:** `scripts/build-loop.sh:938`, `scripts/build-loop.sh:990-996`, `scripts/build-loop.sh:1005`

---

## Claim 13: merge_ident: "as git var resolves them: the environment's GIT_AUTHOR_NAME/EMAIL and GIT_COMMITTER_NAME/EMAIL, then git config with the caller's global file (no system file ...), each name and email on its own. user.useConfigOnly: without them git would take EMAIL or guess ...; it refuses instead. ... Returns 1 when git knows none."

**Location:** `scripts/build-loop.sh:1009-1014`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the source order, the useConfigOnly refusal, the export, and the return value, against probes P1/A-D and test 3. Does not establish anything about other git versions.

The sources, the refusal of EMAIL and the export all hold (Claim 4a). "Returns 1 when git knows none" is imprecise for the case Claim 4b found. When only `committer.email` is configured, `git var GIT_AUTHOR_IDENT` succeeds with an empty email (`u <> 1791667067 -0700`, rc=0, ad hoc probe D). The regex `^([^\<\>]+)\ \<([^\<\>]*)\>\ ...` (`:1019`) accepts that, so merge_ident returns 0 and exports `GIT_AUTHOR_EMAIL=` (P1 recorded `author=[u <>]`). The precise version: it returns 1 when git var fails, and an empty email passes.

**Evidence:** `scripts/build-loop.sh:1015-1022`, `$LOGS/probe-fc1.log` (P1)

---

## Claim 14: land: "decide, then write, then move (D7, F29). No worktree may be rebasing the default branch or bisecting from it. When no worktree has it checked out: a compare-and-swap (update-ref from MAIN_SHA ...). When a worktree W has it: W must be its own top level ..., on it at MAIN_SHA, with no tracked change, no merge, cherry-pick, revert, rebase, bisect or sequence in progress, nothing at a path the merge adds (an untracked or ignored file: merge --ff-only overwrites an ignored one) and no file or link where the merge needs a directory. Then the merge commit NEW ... is written in the gate repository, the state gate (here and in W) and default_gate run again (row 494), and the branch moves ..., after which it must read NEW."

**Location:** `scripts/build-loop.sh:1023-1038`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of decide, write and move against the code, each listed W condition, the re-gate set, and git 2.39.5 overwriting an ignored file. Does not establish anything about W's own checkout settings (override row 657), or the races named as residuals.

The order in the code:
- Decide: identity, worktree list, scan, then W's checks (`:1046-1094`).
- Write: `printf ... && x="$(gate_git commit-tree ...)"` (`:1095-1097`).
- Re-gate: `{ state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; }` (`:1099`).
- Move (`:1101-1110`), with `[[ "$(git rev-parse --verify -q "refs/heads/$MAIN")" == "$NEW" ]]` after the fast-forward (`:1110`).

Probe P3 tested the parenthetical. It put an ignored `work-feat-x.txt` (via info/exclude) holding `mine` in place, then ran `git merge --ff-only`. The merge returned 0, and the file then held `feat/x` (`$LOGS/probe-fc1.log`).

**Evidence:** `scripts/build-loop.sh:1043-1112`, `$LOGS/probe-fc1.log` (P3), `test/scripts/build-loop-merge.bats:117-143`

---

## Claim 15: "Sets NEW, or MERGE_WHY and returns 1 (a refusal after the write leaves NEW set and unreachable in the store)."

**Location:** `scripts/build-loop.sh:1038-1039`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusals after the write: the re-gate, the CAS, a failed ff, and the "not at the merge after the fast-forward" refusal. Does not establish anything about gc timing of the unreachable object.

The claim holds for the re-gate, CAS and failed-ff refusals, because no ref is moved. It does not hold for `MERGE_WHY="the default branch is not at the merge after the fast-forward in $in"` (`:1110`). That refusal fires after `merge --ff-only` succeeded on whatever W's HEAD named.

Probe P5 used a shim to switch W to a new branch `other` at MAIN_SHA just before the ff, which is the residual race the comment names. It printed `status=2 refuse ...: the default branch is not at the merge after the fast-forward ...` and `other=344286a1... main=ddc74c87... M=ddc74c87...`, so NEW is reachable from `other` and from W's HEAD reflog. The precise version: NEW is left unreachable except after that last refusal, where the ff may have moved another branch to it.

**Evidence:** `scripts/build-loop.sh:1098`, `scripts/build-loop.sh:1108-1110`, `$LOGS/probe-fc1.log` (P5)

---

## Claim 16: "Each worktree's own git dir, read as files: the common one and those under worktrees/ (dot names too). worktree list shows a rebasing worktree as detached, so only its rebase state names the branch."

**Location:** `scripts/build-loop.sh:1055-1059`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the glob set (`*`, `.[!.]*`, `..?*` under worktrees/, which together match every name but `.` and `..`) and git 2.39.5's porcelain output during a paused rebase. Does not establish anything about a caller with dotglob set, which would only duplicate entries.

The loop is `for d in "$common" "$common"/worktrees/* "$common"/worktrees/.[!.]* "$common"/worktrees/..?*; do [[ -d "$d" ]] || continue` (`:1059-1060`). Test 5 plants `.x/rebase-merge/head-name` and expects a refusal (`test/scripts/build-loop-merge.bats:139-140`), and it passed. Probe P4 paused `git rebase -x false HEAD~1` in a worktree on main. `git worktree list --porcelain` printed that worktree as `HEAD ddc74c87... detached`, while `rebase-merge/head-name` read `refs/heads/main`.

**Evidence:** `scripts/build-loop.sh:1058-1068`, `test/scripts/build-loop-merge.bats:139-140`, `$LOGS/probe-fc1.log` (P4)

---

## Claim 17: "A rebase of it, or one that will move it (--update-refs lists it)."

**Location:** `scripts/build-loop.sh:1061-1064`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's update-refs file format for a real paused `rebase -i --update-refs` and the `grep -qxF` match on it. Does not establish anything about the rebase-apply backend, which has no --update-refs.

An ad hoc probe ran a real `GIT_SEQUENCE_EDITOR='sed -i 1ibreak' git rebase -i --update-refs HEAD~2` of feat/z, whose range holds main's commit. In `rebase-merge/`, `head-name` read `refs/heads/feat/z` and `update-refs` held `refs/heads/main` on a line of its own, followed by two ids. The code's `grep -qxF "refs/heads/$MAIN" "$d/$q"` with `q=rebase-merge/update-refs` (`:1062-1063`) matches that line. Mutant M3 dropped `rebase-merge/update-refs` from the list, and test 5 then failed (`$LOGS/mut-summary.txt`).

**Evidence:** `scripts/build-loop.sh:1062-1064`, `$LOGS/mut-M3.log`, `$LOGS/mut-summary.txt`

---

## Claim 18: "W's own config.worktree before any git command runs there (git status would run a filter it names); the startup gate read this checkout's."

**Location:** `scripts/build-loop.sh:1070-1071`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the git commands run in W before and inside the gate. Does not establish that any config.worktree key can make those read-only calls run a command; none was found.

No git command runs in W before `(cd "$w" && state_gate)` (`:1073`). The only earlier git calls, `worktree list` (`:1048`) and `rev-parse --git-common-dir` (`:1058`), run in the caller's top level, and the rebase scan reads files. However, the gate is itself four git commands run in W, and each loads W's config, config.worktree included, with includes followed. Those commands are:
- `git rev-parse --path-format=absolute --git-path "$f"` (`:344`, `:353`)
- `git config --file "$p" --no-includes ...` (`:346`)
- `git for-each-ref ... refs/replace/` (`:356`)
- `git symbolic-ref -q refs/remotes/origin/HEAD` (`:358`)

The precise version: config.worktree is gated before any git command other than the gate's own reads, so the gate runs before git status. Test 6 confirms the property that matters: the clean filter never runs (`test/scripts/build-loop-merge.bats:154-158`).

**Evidence:** `scripts/build-loop.sh:341-363`, `scripts/build-loop.sh:1048`, `scripts/build-loop.sh:1058`, `scripts/build-loop.sh:1072-1073`, `test/scripts/build-loop-merge.bats:154-158`

---

## Claim 19: "$in is missing, not its own top level, or not on it at $MAIN_SHA" (the -ef test's message)

**Location:** `scripts/build-loop.sh:1074-1076`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message against its three conditions and the core.worktree case. Does not establish anything about a W whose `show-toplevel` fails for another reason; that case yields an empty string, so `-ef` is false and this message prints.

The test is `[[ "$(git -C "$w" rev-parse --show-toplevel)" -ef "$w" && "$(git -C "$w" symbolic-ref -q HEAD)" == "refs/heads/$MAIN" && "$(git -C "$w" rev-parse --verify -q 'HEAD^{commit}')" == "$MAIN_SHA" ]]` (`:1074-1075`). It covers top level, on the branch, and at MAIN_SHA. "Missing" stays reachable if W vanishes after `:1072`. Test 6 sets `core.worktree` elsewhere and expects this exact message (`test/scripts/build-loop-merge.bats:152-153`), and it passed.

**Evidence:** `scripts/build-loop.sh:1072-1076`, `test/scripts/build-loop-merge.bats:152-153`

---

## Claim 20: "The branch's own mergeOptions (--squash would stage the merge in W and leave the branch) cleared; no gc or maintenance task (a repack) started on the store store_check read; the reflog names the gate."

**Location:** `scripts/build-loop.sh:1105-1108`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three `-c` overrides and GIT_REFLOG_ACTION on the W fast-forward. Does not establish anything about maintenance started by other processes.

The code is `GIT_REFLOG_ACTION="$msg" git -C "$w" -c gc.auto=0 -c maintenance.auto=false -c "branch.$MAIN.mergeOptions=" merge --ff-only -q "$NEW"` (`:1108`). Test 4 runs with `branch.main.mergeOptions --squash` and expects main moved and W clean. It also enables loose-objects maintenance and expects the pack count unchanged (`test/scripts/build-loop-merge.bats:103-111`). Both checks passed. Mutant M2 removed `-c maintenance.auto=false` and test 4 failed at the pack-count line (`$LOGS/mut-M2.log`).

**Evidence:** `scripts/build-loop.sh:1108`, `test/scripts/build-loop-merge.bats:103-111`, `$LOGS/mut-M2.log`

---

## Claim 21: "The verdict line is check_line's first (the path lines follow it); the authority (here only self-merge; U3a3 adds --approved), then land's result, replace it."

**Location:** `scripts/build-loop.sh:1138-1140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line order whenever VERDICT is set. Does not establish anything about the output-by-position design concern (override row 654).

verdict_ok echoes before `printf '%s\n' "${rows[@]}"` (`:1005-1006`), and `:996` prints no rows. The arm prints `{ echo "$v"; tail -n +2 "$GATE_TMP/line"; }` (`:1144`), where `v` is the policy refusal, `merged ...` or `refuse $a: $MERGE_WHY` (`:1142-1143`).

**Evidence:** `scripts/build-loop.sh:996`, `scripts/build-loop.sh:1005-1006`, `scripts/build-loop.sh:1141-1145`

---

## Claim 22: 6cbca87c "Suites 6/145/20/79/2/2." (also f782d9ee and 7d78e6d0)

**Location:** commit 6cbca87c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge, check, read, dev-cycle, fixture-git-env and utility-smoke suites at HEAD (run) and the `@test` counts at all three code commits. Does not establish which suites the author meant beyond the order used in iteration 2's report.

Serial runs at HEAD gave `build-loop-merge exit=0 ok=6`, `build-loop-check exit=0 ok=145`, `build-loop-read exit=0 ok=20`, `dev-cycle exit=0 ok=79`, `fixture-git-env exit=0 ok=2` and `utility-smoke exit=0 ok=2`, with 0 `not ok` (`$LOGS/summary.txt`). `git show <c>:test/scripts/<suite>.bats | grep -c '^@test'` gives 6/145/20/79/2/2 at 7d78e6d0, f782d9ee and 6cbca87c alike.

**Evidence:** `$LOGS/summary.txt`, `$LOGS/build-loop-merge.log`, `$LOGS/build-loop-check.log`, `$LOGS/build-loop-read.log`, `$LOGS/dev-cycle.log`, `$LOGS/fixture-git-env.log`, `$LOGS/utility-smoke.log`

---

## Claim 23: 6cbca87c "364 code lines." (f782d9ee "337", 7d78e6d0 "299")

**Location:** commit 6cbca87c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the given numstat formula at each commit. Does not establish whether the formula is the right measure.

`git diff --numstat main -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` prints 364 at HEAD (190+13 in scripts/build-loop.sh, 161 in the bats file). The same formula with `main <c>` gives 299 at 7d78e6d0 and 337 at f782d9ee. Here main equals the merge base (6666a5ce).

**Evidence:** command output in this session; `scripts/build-loop.sh`, `test/scripts/build-loop-merge.bats`

---

## Claim 24: 6cbca87c "Each new guard's mutant fails the suite (early gate, maintenance, update-refs, readable state, authority)."

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers six mutants of the guards 6cbca87c added, run against build-loop-merge.bats. Does not establish what the author's own mutants were, which were scratch.

Five of the six mutants fail the suite (`$LOGS/mut-summary.txt`):

| Mutant | Change | Result |
|---|---|---|
| M1 | early W state_gate (`:1073`) deleted | test 6 fails |
| M2 | `-c maintenance.auto=false` removed | test 4 fails |
| M3 | update-refs dropped from the scan | test 5 fails |
| M4a | `[[ -r "$d/$q" ]] &&` removed (rebase state) | test 5 fails |
| M5b | `land self-merge` → `land review` | tests 1 and 4 fail |
| M4b | `[[ -r "$d/BISECT_START" ]] &&` removed | survives: `M4b exit=0 notok:` |

M4b removes the other half of D1's "unreadable rebase or bisect state refuses", and no test makes BISECT_START unreadable. A probe with `chmod 000` on a worktree's BISECT_START gave different results:
- The original prints `refuse ...: a worktree is bisecting from the default branch, or its bisect state cannot be read` and exits 2.
- M4b exits 1 with no line and `line 1066: ... BISECT_START: Permission denied` on stderr (`$LOGS/probe-bisect-tree.log`, `$LOGS/probe-bisect-mut-M4b.log`).

M4b therefore still fails closed, but its documented refusal is untested. M5, which called `land` with no argument, failed every test through `$1: unbound variable` and was replaced by M5b. The precise version: every new guard but the bisect readability test has a killing mutant.

**Evidence:** `scripts/build-loop.sh:1062-1067`, `$LOGS/mut-summary.txt`, `$LOGS/mut-M4b.log`, `$LOGS/probe-bisect-tree.log`, `$LOGS/probe-bisect-mut-M4b.log`

---

## Claim 25: 6cbca87c "B1 W's own config.worktree is state-gated as soon as W is known, before any git command runs there (git status ran a clean filter it named; pre-existing since 7d78e6d0)."

**Location:** commit 6cbca87c message
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gate's position at HEAD and the order at 7d78e6d0 and f782d9ee. Does not establish whether the filter ran in practice at 7d78e6d0 (not executed there).

"Pre-existing since 7d78e6d0" holds. At 7d78e6d0, `git -C "$w" status` (`:1051`) ran before the only W state gate, `(cd "$w" && state_gate)` in the re-gate (`:1065`). f782d9ee has the same order (`:1069` before `:1087`).

The rest is imprecise. "As soon as W is known" skips the rebase/bisect scan, which runs between (`:1055-1068`). "Before any git command runs there" has the same imprecision as Claim 18, because the gate's own four git reads run in W.

**Evidence:** `git show 7d78e6d0:scripts/build-loop.sh` lines 1051 and 1065; `scripts/build-loop.sh:1055-1073`

---

## Claim 26: 6cbca87c "D1 a paused rebase --update-refs that will move main refuses, and unreadable rebase or bisect state refuses. ... D4 a pack-count test pins maintenance.auto=false."

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behaviour of D1's guards (the update-refs scan and the `-r` tests) and D4's pin (M2 is killed). Does not establish test coverage of the bisect `-r` guard, which is Claim 24.

The update-refs file is scanned (Claim 17). An unreadable head-name refuses (test 5, `test/scripts/build-loop-merge.bats:137-138`). An unreadable BISECT_START refuses (`$LOGS/probe-bisect-tree.log`). M2 fails test 4 (Claim 20).

**Evidence:** `scripts/build-loop.sh:1062-1067`, `test/scripts/build-loop-merge.bats:134-138`, `$LOGS/probe-bisect-tree.log`, `$LOGS/mut-M2.log`

---

## Claim 27: Suite header and helper comments ("Each test builds a throwaway repo under $BATS_TEST_TMPDIR ...; this repo is untouched"; sm, orch, shim, refused)

**Location:** `test/scripts/build-loop-merge.bats:3-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each helper's documented contract against its body and the fixture lib. Does not establish anything about the hermeticity of the fixture lib itself, which is pre-existing.

- bl_setup sets `R="$BATS_TEST_TMPDIR/repo"` and cds there (`test/lib/build-loop-fixtures.bash`).
- `sm` sets B (via `brief`), T, M and TR as documented (`:19-23`).
- `orch` runs `git worktree add -q --detach "$BATS_TEST_TMPDIR/o" main && cd ...` (`:25`).
- `shim` writes a git that runs ACTION once, guarded by a `fired` file, when `"$*"` holds WHEN, then `exec "$REAL"` (`:29-36`).
- `refused` checks status 2, the first two lines and `git rev-parse main` = M (`:38-41`).

**Evidence:** `test/scripts/build-loop-merge.bats:3-41`, `test/lib/build-loop-fixtures.bash`

---

## Claim 28: Tests 1 and 2 titles ("lands ... by compare-and-swap when no worktree has main checked out: parents, tree, message, trailer; a second run refuses"; "leaves main where another writer moved it between the check and the swap, and refuses git state planted after the check"), and "commit-tree runs in the gate repository"

**Location:** `test/scripts/build-loop-merge.bats:43-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the titles and inline comment against the assertions. Does not establish anything about the test IDs' (T22, G13, G17) meaning in the plan.

Test 1 detaches R (`git checkout -q --detach main`). It asserts parents, tree, message with trailer, identity and the reflog, then asserts that a second run gives `refuse $B: its branch feat/x has no commit the default branch lacks`.

Test 2 has two shims:
- The first moves main to `o` before update-ref and expects the CAS refusal with `M="$o"`.
- The second writes `filter.x.clean` via `config --file '$R/.git/config'`, which needs an absolute path because commit-tree's cwd is `$GATE_TMP/work` with `GIT_DIR` set to the gate repository (`scripts/build-loop.sh:636`). It then expects the re-gate refusal.

Both tests passed.

**Evidence:** `test/scripts/build-loop-merge.bats:43-69`, `scripts/build-loop.sh:634-639`, `$LOGS/build-loop-merge.log`

---

## Claim 29: Test 3 title and "Names set but the email only in EMAIL: git would take it (and on other hosts guess from the domain); user.useConfigOnly refuses."

**Location:** `test/scripts/build-loop-merge.bats:71-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment's two git behaviours (probed) and the title's four parts against the assertions. Does not establish the parenthetical "on other hosts guess from the domain", because the passwd/host guess without EMAIL was not probed.

The ad hoc probe printed `n <e@x>` without useConfigOnly and refused with it (Claim 4a). Each part of the title has a matching assertion:
- No identity is covered at `:74-75`.
- EMAIL-only is covered at `:77-78`.
- The global config identity is covered at `:79-81`.
- The review brief is covered at `:83-86`.
- The three usage shapes are covered at `:87-90`.

The test passed.

**Evidence:** `test/scripts/build-loop-merge.bats:71-91`, `$LOGS/build-loop-merge.log`

---

## Claim 30: Test 4 title ("fast-forwards the worktree that has main checked out, from it or from another, keeping an unrelated untracked file; a worktree on another branch is left alone") and its mergeOptions and maintenance comments

**Location:** `test/scripts/build-loop-merge.bats:93-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title's parts and the two comments against the assertions, with mutant M2 confirming the pack-count pin. Does not establish anything about a mergeOptions mutant, which was not run this pass (iteration 1 recorded it).

The test's steps each match a part of the title or a comment:
1. The first run is from R, which is on main, with `unrelated.txt` present. It asserts HEAD at n, the file content and a clean status.
2. `orch` then runs from another worktree and asserts R moved.
3. The maintenance comment's pack count (`:105-108`) fails under M2.
4. `--squash` expects W clean and on main (`:109-111`).
5. R on `feat/y` expects R left at M on feat/y (`:112-114`).

**Evidence:** `test/scripts/build-loop-merge.bats:93-115`, `$LOGS/mut-M2.log`

---

## Claim 31: Tests 5 and 6 titles and comments ("A paused rebase --update-refs of another branch that will move main ...; an unreadable head-name"; "W's own config.worktree is gated before git status runs there: its clean filter never runs")

**Location:** `test/scripts/build-loop-merge.bats:117-161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each title clause and comment against the assertions, with M1, M3 and M4a killed here. Does not establish anything about the config.worktree case, which test 6's title omits (it is in the body). The title is incomplete, not false.

Test 5 covers each clause in its title:
- tracked change (`:120`)
- untracked and ignored added file (`:122-123`)
- each in-progress marker (`:125-130`)
- worktree rebase of main (`:131-133`)
- update-refs (`:135-136`)
- unreadable head-name (`:137-138`)
- dot-named admin dir (`:139-140`)
- bisect from main (`:141`)
- bisect from another branch (`:142`)

Test 6 covers:
- file and link where a directory is added (`:150-151`)
- core.worktree (`:152-153`)
- the config.worktree filter, with `[ ! -e "$BATS_TEST_TMPDIR/ran" ]` (`:155-158`)
- the missing worktree (`:159-160`)

All passed. M1 fails test 6 because the late re-gate's message differs (`$LOGS/mut-M1.log`).

**Evidence:** `test/scripts/build-loop-merge.bats:117-161`, `$LOGS/mut-M1.log`, `$LOGS/mut-M3.log`, `$LOGS/mut-M4a.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 4b** (`scripts/build-loop.sh:221-224`): when only committer.email (or author.email) is configured, git var gives the other side an empty email. It lands as `<>` with no "no identity" refusal. Say so, or the header's source list is incomplete.
- **Claim 13** (`scripts/build-loop.sh:1009-1014`): this is the same empty-email case. "Returns 1 when git knows none" should read "when git var fails; an empty email passes".
- **Claim 15** (`scripts/build-loop.sh:1038-1039`): after the "not at the merge after the fast-forward" refusal, NEW can be reachable from the branch W's HEAD had moved to (probe P5).
- **Claim 18** (`scripts/build-loop.sh:1070-1071`): the gate's own four git reads run in W first. Say "before any git command but the gate's own reads".
- **Claim 24** (commit 6cbca87c): the bisect-state readability guard's mutant survives the suite. Its fail-closed exit 1 differs from the documented refusal line, and no test covers an unreadable BISECT_START.
- **Claim 25** (commit 6cbca87c, B1): the gate comes after the rebase/bisect scan, not "as soon as W is known", and has the same "any git command" imprecision as Claim 18.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, structured per the code-fact-check skill, with a `Commit: 6cbca87c` line at the top.
- Answered: yes. All eight claim groups from the brief are verdicted in 31 claims. The suites at HEAD reproduce 6/145/20/79/2/2, the code-line formula gives 364, and the five named mutants are killed. The bisect readability guard's mutant survives.
- Out of scope: code-quality judgements, the races named as residuals (Q-103), and any finding settled by the override rows listed in the shared brief. Claims 4b and 13 are not covered by any override row found (`grep -i 'empty email\|committer.email'` returns nothing).
- Escalate: none blocking. Claims 4b/13 (an empty-email identity lands silently) and Claim 24 (no test for unreadable BISECT_START) are amber inputs for the rubric. No hallucination pattern qualified, because there are no Incorrect verdicts.
