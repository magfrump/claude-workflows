Commit: 6cbca87c

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u3a2, branch feat/build-loop-u3a2)
**Scope:** `git diff main...HEAD -- scripts test` at HEAD 6cbca87c (scripts/build-loop.sh, test/scripts/build-loop-merge.bats), plus the branch's commit messages (`git log main..HEAD`: 7d78e6d0, f782d9ee, 6cbca87c). Final confirming pass, replicate r2 of k=3.
**Checked:** 2026-10-10
**Total claims checked:** 33
**Summary:** 26 verified, 4 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Execution logs are kept outside the worktree (the review rules allow only this report file in it). `$L` = `/tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-i3-fc-2/logs`. Probe scripts sit in its parent (`common.sh`, `probeA.sh`, `probeB.sh`, `probeB2.sh`, `probeC.sh`, `probeD.sh`, `run-suites.sh`, `mutants.py`, `run-mut.sh`). Every probe ran under `timeout` in its own `mktemp -d /tmp/u3a2i3-fc2-XXXX` directory and removed it afterwards. Each probe builds the merge suite's `sm` fixture by sourcing `test/lib/build-loop-fixtures.bash`. Mutants were applied only to copies under `.../u3a2-i3-fc-2/mut/`. Environment: git 2.39.5, GNU bash 5.2.15, uid 1000.

Hallucination log read (`docs/reviews/hallucination-patterns.md`). Its count-claim entries (test tallies, sizes) were the reason the suite and line counts below were re-run, not taken from the messages. No claim here matches a logged fabrication pattern.

**New finding in this pass (not in iterations 1-2 or the override log):** state that git cannot read is not refused. It is treated as absent, and that is a non-racing fail-open (claims 5b, 5c, 14, 25b).
- If `$common/worktrees` or W's own admin directory is unsearchable (`chmod 000`), `git worktree list --porcelain` exits 0 and leaves W out. land then moves main by compare-and-swap underneath W.
- If a worktree's `rebase-merge/` directory is unsearchable, its `head-name` reads as absent, and a rebase of main is let through.

Both were reproduced: the run printed `merged` and exited 0. The i2 security report's listed candidate 3 covered a `chmod 000` *file*, which the code now refuses. It did not cover an unsearchable *directory*.

---

## Claim 1: "scripts/build-loop.sh --merge BRIEF --expect SHA" (usage line and usage())

**Location:** `scripts/build-loop.sh:9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the header usage line, `usage()`'s text and the arity check for --merge (one brief and --expect required). It does not establish the --expect value checks, which are shared with --check and print their own messages (row 665).

Both the header and `usage()` carry the --merge form: `usage() { echo "$1 (usage: build-loop.sh --settings | --status BRIEF... | --check BRIEF... [--expect SHA] | --merge BRIEF --expect SHA)" >&2; exit 1; }` (`scripts/build-loop.sh:277`). The arity guard is `[[ "$MODE" == check || ( -n "$EXPECT" && ${#ARGS[@]} -eq 1 ) ]] || usage "--merge takes one brief path and --expect SHA"` (`scripts/build-loop.sh:289`), and it runs before the --check messages. Test 3's loop (`for args in "$B" "--expect $T" "$B $B --expect $T"`, `test/scripts/build-loop-merge.bats:87-90`) asserts exit 1 and that stderr starts with that message, and it passes.

**Evidence:** `scripts/build-loop.sh:9`, `scripts/build-loop.sh:277-292`, `test/scripts/build-loop-merge.bats:87-90`; `$L/build-loop-merge.log` (cmd `TMPDIR=$(mktemp -d /tmp/u3a2i3-fc2-XXXX) timeout 1500 bats test/scripts/build-loop-merge.bats`, cwd worktree, exit 0, 2026-10-10T21:15:34Z-21:15:41Z)

---

## Claim 2: "merged BRIEF TIP TREE NEW ... parents are main's commit and TIP ... "Merge branch 'BRANCH' (build-loop self-merge)" ... "Build-loop-gate: STEM" ... reflog entry reads "build-loop: self-merge of STEM" (git adds ": Fast-forward" when W moves it)"

**Location:** `scripts/build-loop.sh:213-221`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merged line's field order, the commit's parents, tree, message and trailer, and the reflog text on both moves. It does not establish that W's HEAD reflog uses the same text (it does use GIT_REFLOG_ACTION, but no test reads it).

- **The merged line:** the merge arm prints `v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"` (`scripts/build-loop.sh:1143`).
- **The commit:** it is written as `printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "$1" "${VERDICT[stem]}"` followed by `gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}"` (`scripts/build-loop.sh:1095-1096`). `$1` is `self-merge` from `land self-merge` (`:1143`).
- **The reflog:** the message is `msg="build-loop: $1 of ${VERDICT[stem]}"` (`:1044`). It goes to `update-ref -m "$msg"` (`:1102`) and to `GIT_REFLOG_ACTION="$msg"` for the merge (`:1108`).
- **The tests:** test 1 asserts the parents, tree, message and trailer, and the reflog `"build-loop: self-merge of 2026-10-01-x"`. Test 4 asserts `"build-loop: self-merge of 2026-10-01-x: Fast-forward"` (`test/scripts/build-loop-merge.bats:102`). Both pass.

**Evidence:** `scripts/build-loop.sh:1044`, `scripts/build-loop.sh:1095-1110`, `scripts/build-loop.sh:1143`, `test/scripts/build-loop-merge.bats:43-57`, `test/scripts/build-loop-merge.bats:93-115`; `$L/build-loop-merge.log`

---

## Claim 3: "Author and committer names and emails from GIT_AUTHOR_NAME/EMAIL and GIT_COMMITTER_NAME/EMAIL, or else git config (the caller's global file included, the system file not); EMAIL or a guess from the host refuses instead."

**Location:** `scripts/build-loop.sh:221-224`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the environment variables, the caller's global file (GIT_CONFIG_GLOBAL as the caller set it, or unset), GIT_CONFIG_NOSYSTEM being kept, and the EMAIL and no-identity refusals. It does not establish the passwd/domain guess case on a host that has a domain; that rests on `user.useConfigOnly` semantics, and the no-config case below refuses. It also does not establish that the repository's own `.git/config` user.* is read (it is, because git var runs in the real repository), since the header does not mention it.

merge_ident runs `x="$(env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var "GIT_${w}_IDENT" 2>/dev/null)" || return 1` (`scripts/build-loop.sh:1018`). CALLER_GLOBAL is the caller's GIT_CONFIG_GLOBAL, or `-u GIT_CONFIG_GLOBAL` (`:323`). `GIT_CONFIG_NOSYSTEM=1` stays exported (`:326`). Test 3 passes for three cases: no identity variables refuses, names set with the email only in `EMAIL=e@example.invalid` refuses, and `GIT_CONFIG_GLOBAL=$BATS_TEST_TMPDIR/gc` yields `g g@example.invalid g g@example.invalid` (`test/scripts/build-loop-merge.bats:71-85`).

**Evidence:** `scripts/build-loop.sh:323-326`, `scripts/build-loop.sh:1015-1022`, `test/scripts/build-loop-merge.bats:71-85`; `$L/build-loop-merge.log`

---

## Claim 4: "With the branch checked out in no worktree it moves by compare-and-swap from the checked commit; checked out in a worktree W, by merge --ff-only in W."

**Location:** `scripts/build-loop.sh:224-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both moves whenever `git worktree list` reports the worktree that has the branch checked out. It does not establish the case where git cannot read that worktree's admin directory: W is then left out of the listing and the branch moves by CAS underneath it (claim 5b).

W is the path whose porcelain record holds `"branch refs/heads/$MAIN"` (`scripts/build-loop.sh:1052`). Without a W the move is `git update-ref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA"` (`:1102`); with one it is `git -C "$w" ... merge --ff-only -q "$NEW"` (`:1108`). Tests 1, 2 and 4 exercise both moves and the CAS failure, and all pass.

**Evidence:** `scripts/build-loop.sh:1048-1054`, `scripts/build-loop.sh:1101-1111`; `$L/build-loop-merge.log`

---

## Claim 5a: the refusal list ("or refuse BRIEF: WHY ... when: ...") names every refusal land and the merge arm produce, and nothing else

**Location:** `scripts/build-loop.sh:227-245`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one-to-one mapping between the header's list and every `MERGE_WHY=` assignment in land (`:1043-1112`) plus the merge arm's policy refusal (`:1142`). It does not establish that each refusal fires for every state its words cover; claims 5b and 5c are two such gaps.

Mapping (paraphrased — no quote available because the mapping spans fifteen MERGE_WHY assignments across `:1046-1110`; each is quoted in the cited lines):

| Header item | Code |
|---|---|
| policy is review | merge arm `:1142` |
| no identity | `:1046` |
| worktrees / git dir cannot be read | `:1048`, `:1058` |
| two worktrees | `:1052` |
| rebasing / update-refs / unreadable rebase state | `:1062-1064` |
| bisecting / unreadable bisect state | `:1066-1067` |
| commit not written | `:1095-1097` |
| state gate or default_gate again | `:1099-1100` |
| moved or cannot be updated | `:1102-1103` |
| W missing | `:1072` |
| W fails the state gate | `:1073` |
| not own top level / not on it at MAIN_SHA | `:1074-1076` |
| mid an operation | `:1077-1080` |
| tracked change / status fails or warns | `:1081-1082` |
| untracked or ignored at an added path | `:1083-1085` |
| file or link where a directory is added | `:1086-1091` |
| ff fails / branch elsewhere | `:1108-1110` |

No MERGE_WHY in land is missing from the list, and no listed item lacks code. "--check's own refusals and skips print as they are" matches `if [[ -z "${VERDICT[tree]-}" ]]; then cat "$GATE_TMP/line"; exit 2; fi` (`:1141`). The path lines then follow: `{ echo "$v"; tail -n +2 "$GATE_TMP/line"; }` (`:1144`).

**Evidence:** `scripts/build-loop.sh:227-245`, `scripts/build-loop.sh:1043-1112`, `scripts/build-loop.sh:1136-1146`

---

## Claim 5b: "[refuse when] the worktrees or the git directory cannot be read"

**Location:** `scripts/build-loop.sh:229-230`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Low (hostile same-uid loop; non-racing planted state, so in scope per the brief's threat model)
**Legibility-target:** header refusal list and land's worktree discovery
**Scope:** Covers an unsearchable `$common/worktrees` directory and an unsearchable `$common/worktrees/<W>` admin directory while the branch is checked out in W. It does not establish other unreadable shapes, such as an unreadable `gitdir` file inside a searchable admin directory.

The only refusal is on git's exit status: `git worktree list --porcelain -z > "$GATE_TMP/wts" || { MERGE_WHY="the worktrees could not be listed"; return 1; }` (`scripts/build-loop.sh:1048`). git 2.39 exits 0 and leaves out a worktree whose admin directory it cannot open. That gives `w=""`, and land takes the CAS path (`:1101-1103`). Probe B (`chmod 000 "$R/.git/worktrees"`, W on main) printed:

```
== worktree list with worktrees/ 000:
worktree /tmp/u3a2i3-fc2-W136/repo
HEAD 3f357523e7d67a3623c476138dec34e61e328f07
detached

rc 0
merged docs/working/briefs/2026-10-01-x.md 1f620ac0... e4ae3d6d... 3534de82...
exit 0
```

After the permissions were restored, W's `HEAD` read NEW, but its index and files were still at MAIN_SHA (`git status --short` showed `D  work-feat-x.txt`). A commit made in W next would revert the merge. Probe B2 (`chmod 000` on only `.git/worktrees/w`) gave the same result: `merged`, exit 0. W's checks never ran: the -d test, the state gate, clean, mid-operation and the added-path guards.

**Evidence:** `scripts/build-loop.sh:1048-1054`, `scripts/build-loop.sh:1101-1103`; `$L/probeB.log` (cmd `timeout 300 bash probeB.sh`, cwd the scratch dir, exit 0, 2026-10-10T21:18:10Z), `$L/probeB2.log` (exit 0, 2026-10-10T21:18:26Z)

---

## Claim 5c: "a worktree is rebasing it (or a paused rebase will move it) or bisecting from it, or that state cannot be read"

**Location:** `scripts/build-loop.sh:230-232`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Low (hostile same-uid loop; non-racing)
**Legibility-target:** header refusal list; land's rebase/bisect scan
**Scope:** Covers state that cannot be read because its directory is unsearchable (the `rebase-merge/` directory, or a worktree admin directory as in claim 5b). It does not establish anything against readable state, which refuses correctly (test 5), or against an unreadable *file* (`chmod 000 head-name`), which refuses.

Unreadable state is detected only when its path exists: `[[ ! -e "$d/$q" ]] || { [[ -r "$d/$q" ]] && ! grep -qxF "refs/heads/$MAIN" "$d/$q"; }` (`scripts/build-loop.sh:1063`). The bisect check has the same shape (`:1066`). When the parent directory is unsearchable, `-e` is false, so the state reads as absent. Probe A made `.git/worktrees/o/rebase-merge` (with `head-name` = `refs/heads/main`) mode 000:

```
== readable dir:
refuse docs/working/briefs/2026-10-01-x.md: a worktree is rebasing the default branch, or its rebase state cannot be read
exit 2
== dir mode 000:
merged docs/working/briefs/2026-10-01-x.md 1f620ac0... e4ae3d6d... 3534de82...
exit 0
```

The same mechanism also lets through a `head-name` that is a directory or a FIFO. For those, `-r` is true and grep fails with exit 2, which `!` turns into a pass; a FIFO also blocks grep. (paraphrased — no quote available because this is inferred from the quoted condition at `:1063` and was not executed.)

**Evidence:** `scripts/build-loop.sh:1059-1067`; `$L/probeA.log` (cmd `timeout 300 bash probeA.sh`, exit 0, 2026-10-10T21:18:09Z)

---

## Claim 6: "Writes nothing but --check's merge objects ..., --merge's commit, the branch it moves and that branch's reflog (and in W: its files, index, HEAD reflog and ORIG_HEAD), and its own temporary directory"

**Location:** `scripts/build-loop.sh:249-254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the files that changed under the repository (objects aside) on one CAS landing and one W landing. It does not establish writes under hostile config, which the state gate refuses.

Probe C took a snapshot of every file outside `.git/objects` before and after each landing. The W landing (W = the repo, run from a detached worktree) changed only `.git/ORIG_HEAD` (new), `.git/index`, `.git/logs/HEAD`, `.git/logs/refs/heads/main`, `.git/refs/heads/main` and `work-feat-x.txt`. Two new loose objects appeared. The CAS landing changed only `.git/logs/refs/heads/main` and `.git/refs/heads/main` (paraphrased — no quote available because the evidence is a diff of two file listings, captured in the log).

**Evidence:** `$L/probeC.log` (cmd `timeout 300 bash probeC.sh`, exit 0, 2026-10-10T21:18:28Z)

---

## Claim 7: "Exit: 0 every line printed (or help), for --check every verdict line ok, for --merge merged; 2 any other --check or --merge verdict line ... 1 ... a failed mktemp (--check, --merge; no line printed)"

**Location:** `scripts/build-loop.sh:256-263`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge arm's exits (0 on merged, 2 on any check_line non-ok line, a policy refusal or a land refusal). It does not establish the failed-mktemp exit by execution; that one is static (`GATE_TMP="$(mktemp -d)"` under `set -e`, `:912`).

The merge arm ends `[[ "$v" == merged* ]] || exit 2` (`scripts/build-loop.sh:1145`) after `if [[ -z "${VERDICT[tree]-}" ]]; then cat "$GATE_TMP/line"; exit 2; fi` (`:1141`). land runs as an `elif` condition, so set -e cannot end the run inside it. The suite asserts exit 0 for merged and 2 for refusals (`refused`/`nref`), and it passes.

**Evidence:** `scripts/build-loop.sh:912`, `scripts/build-loop.sh:1136-1146`; `$L/build-loop-merge.log`

---

## Claim 8: "The caller's global config, for merge_ident alone (the merge commit's names: all a loop that writes it could change there); every other call reads none."

**Location:** `scripts/build-loop.sh:321-323`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every git call made after the export at `:326`, and CALLER_GLOBAL's single use. It does not establish what keys in a planted global file could do to `git var` beyond identity (harden's command-line pairs still outrank it, and `user.useConfigOnly` is forced).

`CALLER_GLOBAL` is captured before `export ... GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 ...` (`scripts/build-loop.sh:326`). The only reference is in merge_ident: `env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var` (`:1018`). No git call runs before `:326`. The lib's top level and `scrub_reexec` (`scripts/lib/dev-cycle-read.sh:150-155`) run none (paraphrased — no quote available because this is an absence of git calls before :326, established by grep).

**Evidence:** `scripts/build-loop.sh:313-326`, `scripts/build-loop.sh:1018`, `scripts/lib/dev-cycle-read.sh:150-155`

---

## Claim 9: "The repository rule: main's files and refs, the branch tips, the checkout and store_check's object reads are in the real repository; the merge computations (merge-base, merge-tree, diff-tree, the blob checks) and --merge's commit-tree run through gate_git (into the real object store). --merge moves the branch in the real repository (update-ref) or in W (merge --ff-only), and merge_ident alone reads the caller's global config."

**Location:** `scripts/build-loop.sh:903-909`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each named read and write. It does not establish that the rule is exhaustive: land's discovery reads (worktree list, `--git-common-dir`, and in W rev-parse, status and the state gate) are not named. They run in the real repository or in W.

The computations go through gate_git, which sets `GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v"` (`:629`):
- `gate_git merge-base`, `merge-tree` (`:705-709`)
- `gate_git diff-tree` (`:956`)
- `gate_git cat-file --batch-check` (`:973`)
- own_blob's `gate_git hash-object` (`:725`)
- `gate_git commit-tree` (`:1096`)

The moves are `git update-ref` (`:1102`) and `git -C "$w" ... merge --ff-only` (`:1108`). own_blob reads main's file with plain `git cat-file blob "$MAIN_SHA:$1"` (`:723`), in the real repository as the rule says.

**Evidence:** `scripts/build-loop.sh:621-639`, `scripts/build-loop.sh:703-726`, `scripts/build-loop.sh:956-975`, `scripts/build-loop.sh:1096-1108`

---

## Claim 10: "VERDICT holds tip, tree, policy, branch and stem, and CHANGED each changed path's status letter, only after an ok line (both empty otherwise)."

**Location:** `scripts/build-loop.sh:931-934`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return path of check_line. It does not establish anything about a need_root exit inside check_line, which ends the run.

check_line empties both at entry: `VERDICT=(); CHANGED=()` (`:939`). The only writer is verdict_ok (`:990-995`), which sets `VERDICT=([tip]="$sha" [tree]="$tree" [policy]="$pol" [branch]="$br" [stem]="$stem")` and fills CHANGED from `ps`/`ss`, then echoes the ok line. It is called only where an ok line is printed: `else verdict_ok; fi` (`:997`) and `elif [[ "$nd" -eq 0 ]]; then verdict_ok;` (`:1005`). Every other `return` (`:942-996`) and the co/K-of-N branches print a non-ok line without calling it. check_line runs in the merge arm's shell, with only stdout redirected (`:1137`), so the values persist. "After" is loose: the values are set just before the echo, inside the same function.

**Evidence:** `scripts/build-loop.sh:935-1007`, `scripts/build-loop.sh:1137`

---

## Claim 11: "Reads check_line's locals (bash scope is dynamic); called only here."

**Location:** `scripts/build-loop.sh:989`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers verdict_ok's reads (`a sha tree pol br stem ps ss`, all declared `local` at `:938` or set in check_line) and its two call sites. It does not establish anything about a future caller outside check_line, where the names would resolve to globals.

`local i` (`:991`) keeps the loop index from overwriting check_line's `i`. `grep -n verdict_ok` finds only the definition (`:990`) and the two calls at `:997` and `:1005` (paraphrased — no quote available because this is a grep result).

**Evidence:** `scripts/build-loop.sh:938`, `scripts/build-loop.sh:989-997`, `scripts/build-loop.sh:1005`

---

## Claim 12: merge_ident's comment ("the environment's GIT_AUTHOR_NAME/EMAIL ... then git config with the caller's global file (no system file ...), each name and email on its own. user.useConfigOnly: without them git would take EMAIL or guess ...; it refuses instead. Exported ... because commit-tree runs in the gate repository, which has no config. Returns 1 when git knows none.")

**Location:** `scripts/build-loop.sh:1009-1014`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sources, the refusal and the export. It does not establish what a name holding `<` or `>` does (the regex then also returns 1, a refusal, which the comment does not mention).

`export "GIT_${w}_NAME=${BASH_REMATCH[1]}" "GIT_${w}_EMAIL=${BASH_REMATCH[2]}"` (`:1020`). These variables pass through gate_git, because GATE_ENV unsets only `git rev-parse --local-env-vars` names (`:623-624`), and the identity variables are not among them. The gate repository's config holds only `repositoryformatversion` and `objectformat` (`:627`). Test 3 executes each source and the refusals (claim 3).

**Evidence:** `scripts/build-loop.sh:621-630`, `scripts/build-loop.sh:1009-1022`; `$L/build-loop-merge.log`

---

## Claim 13: land's comment: decide, then write, then move; CAS from MAIN_SHA; W's conditions; "NEW ... written in the gate repository, the state gate (here and in W) and default_gate run again (row 494) ... after which it must read NEW. Sets NEW, or MERGE_WHY and returns 1 (a refusal after the write leaves NEW set and unreachable in the store). Residuals (Q-103) ..."

**Location:** `scripts/build-loop.sh:1023-1041`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order, the CAS, each named W condition, the re-gate, the post-move read, and NEW/MERGE_WHY on each exit when nothing races. It does not establish "unreachable" in the residual race where W switches branch (the other branch would then hold NEW). The rebase/bisect sentence is claim 14.

Order:
1. Every decision (`:1046-1093`, including W's state gate at `:1073`) precedes the message write and commit-tree (`:1095-1097`).
2. `NEW="$x"` (`:1098`).
3. The re-gate `{ state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; }` (`:1099`).
4. The move (`:1101-1110`).

`NEW=""; MERGE_WHY=""` is reset at entry (`:1045`), and a refusal after `:1098` returns with NEW still set. The merge arm prints only `MERGE_WHY` then (`:1143`). Each W condition is quoted in claim 5a's table. Tests 2 (CAS and post-write re-gate), 4, 5 and 6 pass.

**Evidence:** `scripts/build-loop.sh:1023-1112`; `$L/build-loop-merge.log`

---

## Claim 14: "No worktree may be rebasing the default branch or bisecting from it."

**Location:** `scripts/build-loop.sh:1025-1026`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every worktree whose admin directory and rebase/bisect state git and bash can search. It does not hold when that state sits under an unsearchable directory (claims 5b, 5c).

The scan (`:1059-1067`) enforces this for readable state, and test 5 passes. Probe A shows that a rebase of main whose `rebase-merge/` directory is mode 000 lands (`merged`, exit 0). A precise version would say that state which cannot be searched reads as absent. The verdict is Mostly accurate rather than Incorrect because this sentence states the rule, not the handling of unreadable state; claim 5c carries the refuted mechanism.

**Evidence:** `scripts/build-loop.sh:1059-1067`; `$L/probeA.log`

---

## Claim 15: "Each worktree's own git dir, read as files: the common one and those under worktrees/ (dot names too). worktree list shows a rebasing worktree as detached, so only its rebase state names the branch."

**Location:** `scripts/build-loop.sh:1055-1059`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the glob set and the dot-named admin directory. It does not establish coverage when `worktrees/` itself cannot be listed (the globs then expand to nothing and the loop skips them; claim 5b).

`for d in "$common" "$common"/worktrees/* "$common"/worktrees/.[!.]* "$common"/worktrees/..?*; do [[ -d "$d" ]] || continue` (`:1059-1060`) matches every name except `.` and `..`. Test 5's `.git/worktrees/.x/rebase-merge/head-name` case refuses and passes (`test/scripts/build-loop-merge.bats:139-140`). In probe B's listing, the gate's own worktree shows as `detached` because it is detached; a rebasing worktree shows the same way, as git records no branch line during a rebase (paraphrased — no quote available because this is git's behavior, consistent with the porcelain shown in claim 5b).

**Evidence:** `scripts/build-loop.sh:1055-1067`, `test/scripts/build-loop-merge.bats:139-140`; `$L/build-loop-merge.log`

---

## Claim 16: "A rebase of it, or one that will move it (--update-refs lists it)."

**Location:** `scripts/build-loop.sh:1061`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `rebase-merge/update-refs` holding the line `refs/heads/main`. It does not establish the apply backend, which has no update-refs file (and git refuses `--update-refs` with it).

`for q in rebase-merge/head-name rebase-apply/head-name rebase-merge/update-refs` with `grep -qxF "refs/heads/$MAIN"` (`:1062-1063`). Test 5's update-refs case (`:135-136`) refuses. Mutant M3, which drops `rebase-merge/update-refs`, fails test 5 (claim 28).

**Evidence:** `scripts/build-loop.sh:1061-1065`, `test/scripts/build-loop-merge.bats:134-136`; `$L/mut-M3-update-refs-rerun.log`

---

## Claim 17: "W's own config.worktree before any git command runs there (git status would run a filter it names); the startup gate read this checkout's."

**Location:** `scripts/build-loop.sh:1070-1071`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering against land's own git calls in W (rev-parse, status, merge) and the filter consequence. It does not establish that no git command runs in W first, because the state gate itself runs git there.

`(cd "$w" && state_gate)` (`:1073`) runs before `git -C "$w" rev-parse` (`:1074`) and `git -C "$w" status` (`:1081`). No earlier line in land runs git in W. However, state_gate is itself made of git commands run in W: `git rev-parse --path-format=absolute --git-path "$f"`, `git config --file ...`, `git for-each-ref` and `git symbolic-ref` (`:343-358`). These read W's config, including config.worktree, though none runs a filter. A precise version: "before any git command but the state gate's own config and ref reads runs there".

The parenthetical is confirmed by probe D. With the early gate removed (mutant M1) the filter ran (`FILTER RAN`), and the run refused only after the write, with "the git state changed after the check". With the real script it reported `filter did not run` and refused with "fails the state gate".

**Evidence:** `scripts/build-loop.sh:341-363`, `scripts/build-loop.sh:1068-1082`; `$L/probeD.log` (cmd `BL_OVERRIDE=<M1 copy> timeout 120 bash probeD.sh`, then the real script, exit 0 each, 2026-10-10T21:20:43Z)

---

## Claim 18: "$in is missing, not its own top level, or not on it at $MAIN_SHA" (the -ef top-level test's message)

**Location:** `scripts/build-loop.sh:1074-1076`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three conditions the message names. It does not establish which of them fired (one message covers all three).

`[[ "$(git -C "$w" rev-parse --show-toplevel)" -ef "$w" && "$(git -C "$w" symbolic-ref -q HEAD)" == "refs/heads/$MAIN" && "$(git -C "$w" rev-parse --verify -q 'HEAD^{commit}')" == "$MAIN_SHA" ]]`. A failing rev-parse (W unusable) gives an empty string, which fails `-ef`, so "missing" is covered too. Test 6's core.worktree case asserts this message and passes.

**Evidence:** `scripts/build-loop.sh:1074-1076`, `test/scripts/build-loop-merge.bats:152-153`; `$L/build-loop-merge.log`

---

## Claim 19: "The branch's own mergeOptions (--squash would stage the merge in W and leave the branch) cleared; no gc or maintenance task (a repack) started on the store store_check read; the reflog names the gate."

**Location:** `scripts/build-loop.sh:1105-1107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `branch.main.mergeOptions=--squash` and loose-objects maintenance. It does not establish every maintenance strategy (only loose-objects with `auto 1` was exercised).

`GIT_REFLOG_ACTION="$msg" git -C "$w" -c gc.auto=0 -c maintenance.auto=false -c "branch.$MAIN.mergeOptions=" merge --ff-only -q "$NEW"` (`:1108`). Test 4 passes for both the `--squash` case (W clean, main at NEW) and the pack-count case. Mutant M2, which drops `-c maintenance.auto=false`, fails test 4 at the pack-count assertion (`$L/mut-M2-maintenance.log`).

**Evidence:** `scripts/build-loop.sh:1104-1110`, `test/scripts/build-loop-merge.bats:103-111`; `$L/build-loop-merge.log`, `$L/mut-M2-maintenance.log`

---

## Claim 20: "The verdict line is check_line's first (the path lines follow it); the authority (here only self-merge; U3a3 adds --approved), then land's result, replace it."

**Location:** `scripts/build-loop.sh:1138-1140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ok path, where the first line is replaced. It does not establish anything for non-ok lines, which are printed unchanged (`:1141`).

check_line echoes the verdict before `printf '%s\n' "${rows[@]}"` (`:1005-1006`). The arm prints `{ echo "$v"; tail -n +2 "$GATE_TMP/line"; }` (`:1144`).

**Evidence:** `scripts/build-loop.sh:1003-1006`, `scripts/build-loop.sh:1136-1146`

---

## Claim 21: helper comments in the merge suite (mrg/show, sm, orch, shim, refused)

**Location:** `test/scripts/build-loop-merge.bats:13-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each helper's stated behavior. It does not establish anything about the fixture lib beyond `settings`, `brief` and `work`.

- **sm:** sets B (via `brief`), T, M and TR (`:20-22`).
- **orch:** `git worktree add -q --detach "$BATS_TEST_TMPDIR/o" main && cd ...` (`:24-25`).
- **shim:** fires once on the first call whose `$*` holds WHEN (`if [[ \"\$*\" == *'$1'* && ! -e \"\$D/fired\" ]]`, `:32`).
- **refused:** checks status 2, the first two lines and main at M (`:38-40`).

**Evidence:** `test/scripts/build-loop-merge.bats:13-41`, `test/lib/build-loop-fixtures.bash:46-61`

---

## Claim 22: the six test titles against what each test asserts

**Location:** `test/scripts/build-loop-merge.bats:43`, `:59`, `:71`, `:93`, `:117`, `:145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each title's named behavior against its assertions. Some tests assert more than their titles say: test 1 also checks identity and reflog, and test 6 also checks the config.worktree state gate. This verdict does not establish that those extra assertions are named anywhere.

Every behavior a title names has an assertion:
- **Test 1:** CAS, parents, tree, message, trailer, then a second run refuses.
- **Test 2:** main left at the other writer's commit, and planted state refused after the check.
- **Test 3:** review refusal, no identity, global config, usage shapes.
- **Test 4:** from W and from another worktree, untracked file kept, worktree on feat/y left alone.
- **Test 5:** tracked change, each operation, added path (untracked and ignored), rebase, update-refs, dot dir, bisect.
- **Test 6:** file and link at a directory, core.worktree elsewhere, missing W.

(paraphrased — no quote available because this summarises six test bodies spanning `:43-161`.) All six pass.

**Evidence:** `test/scripts/build-loop-merge.bats:43-161`; `$L/build-loop-merge.log`

---

## Claim 23: inline test comments: "commit-tree runs in the gate repository" (:66), the EMAIL comment (:76), mergeOptions/maintenance (:103-104), the update-refs one (:134), "W's own config.worktree is gated before git status runs there: its clean filter never runs" (:154)

**Location:** `test/scripts/build-loop-merge.bats:66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each comment against the test lines it heads and the script. It does not establish the comments' issue references (i1/i2 F-numbers) beyond their presence in docs/reviews.

- **`:66`:** the shim writes `config --file '$R/.git/config'` because the gate's git runs with `GIT_DIR=$GATE_TMP/git` (`scripts/build-loop.sh:629`).
- **`:76`:** the EMAIL case refuses (claim 3).
- **`:103-104`:** mutant M2 shows the pack-count assertion depends on the flag (claim 19).
- **`:134`:** see claim 16.
- **`:154`:** probe D shows that without the early gate the filter runs (`FILTER RAN`), and with it it does not.

**Evidence:** `test/scripts/build-loop-merge.bats:66`, `:76`, `:103-104`, `:134`, `:154-158`; `$L/probeD.log`, `$L/mut-M2-maintenance.log`

---

## Claim 24: "B1 W's own config.worktree is state-gated as soon as W is known, before any git command runs there (git status ran a clean filter it named; pre-existing since 7d78e6d0)."

**Location:** commit 6cbca87c message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering against land's own git calls in W, and the pre-existing history. "Before any git command" carries claim 17's qualifier (the state gate's own reads); it is not split, because the history and consequence parts agree.

In 7d78e6d0, `git -C "$w" status` (its line 1051) ran before the only W state gate, the post-write one (its line 1065), per `git show 7d78e6d0:scripts/build-loop.sh`. Probe D reproduces the filter running under that ordering.

**Evidence:** `git show 7d78e6d0:scripts/build-loop.sh` lines 1051, 1065; `scripts/build-loop.sh:1072-1073`; `$L/probeD.log`

---

## Claim 25a: "D1 a paused rebase --update-refs that will move main refuses"

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an update-refs file listing `refs/heads/main` in a readable state directory. It does not establish behavior for unsearchable state (claim 25b).

See claim 16. Test 5 passes, and mutant M3 fails it.

**Evidence:** `scripts/build-loop.sh:1062-1065`; `$L/build-loop-merge.log`, `$L/mut-M3-update-refs-rerun.log`

---

## Claim 25b: "and unreadable rebase or bisect state refuses"

**Location:** commit 6cbca87c message
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Low (hostile same-uid loop; non-racing)
**Legibility-target:** commit message D1; land's scan
**Scope:** Covers state that cannot be read because its directory is unsearchable. It does not refute the unreadable-*file* case, which refuses (test 5, `chmod 000 head-name`).

As claim 5c shows, `[[ ! -e "$d/$q" ]]` (`scripts/build-loop.sh:1063`) is true under an unsearchable directory, so the state reads as absent. Probe A printed `merged` with exit 0 for a mode-000 `rebase-merge/` whose `head-name` is `refs/heads/main`.

**Evidence:** `scripts/build-loop.sh:1063`, `scripts/build-loop.sh:1066`; `$L/probeA.log`

---

## Claim 26: "D2 header: reflog suffix, identity variables, path lines, NEW after a post-write refusal."

**Location:** commit 6cbca87c message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where each listed fix landed (`git diff f782d9ee 6cbca87c -- scripts/build-loop.sh`). It does not establish anything beyond that diff.

The first three items are in the header:
- `(git adds ": Fast-forward" when W moves it)` (`:220-221`)
- `GIT_AUTHOR_NAME/EMAIL and GIT_COMMITTER_NAME/EMAIL` (`:222`)
- `with the ok line's path lines following` (`:227`)

The fourth is not in the header. It went into land's comment: `(a refusal after the write leaves NEW set and unreachable in the store)` (`:1038-1039`). The header's refusal text does not mention NEW. A precise version: "header: reflog suffix, identity variables, path lines; land's comment: NEW after a post-write refusal".

**Evidence:** `scripts/build-loop.sh:213-245`, `scripts/build-loop.sh:1038-1039`

---

## Claim 27: "D3 land takes the authority it records; verdict_ok's local i. D4 a pack-count test pins maintenance.auto=false."

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argument's use in the message and reflog, the `local i`, and the pack-count test's dependence on the flag. It does not establish anything for a second authority value, which no caller passes yet.

- **D3:** `msg="build-loop: $1 of ..."` (`:1044`), the printf's `"$1"` (`:1095`) and `land self-merge` (`:1143`). `local i` is at `:991`.
- **D4:** mutant M2 fails test 4 at `[ "$(find "$R/.git/objects/pack" -type f | wc -l)" = "$np" ]` (`test/scripts/build-loop-merge.bats:108`).

**Evidence:** `scripts/build-loop.sh:991`, `scripts/build-loop.sh:1044`, `scripts/build-loop.sh:1095`, `scripts/build-loop.sh:1143`; `$L/mut-M2-maintenance.log`

---

## Claim 28: "Each new guard's mutant fails the suite (early gate, maintenance, update-refs, readable state, authority)."

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers eight mutants of `scripts/build-loop.sh`, each run on a scratch copy against the merge suite (copied with test/lib), plus an unmutated control. It does not establish results in other suites.

Results (`run-mut.sh`: `TMPDIR=$(mktemp -d /tmp/u3a2i3-fc2-XXXX) timeout 600 bats <copy>/test/scripts/build-loop-merge.bats`, cwd the scratch dir, 2026-10-10T21:19:19Z onward):

| Mutant | Change | Failing tests |
|---|---|---|
| M0 | control | 0 |
| M1 | early W state gate removed | 1 (test 6) |
| M2 | `-c maintenance.auto=false` removed | 1 (test 4) |
| M3 | `rebase-merge/update-refs` removed | test 5 (the first run's test 2 failure was an unrelated find error on another session's `/tmp/claude-1173-cwd`; the rerun had only test 5 failing) |
| M4a | `[[ -r "$d/$q" ]] &&` removed (rebase readability) | 1 (test 5) |
| **M4b** | **`[[ -r "$d/BISECT_START" ]] &&` removed (bisect readability)** | **0: survives** |
| M5a | `land self-merge` changed to `land approved` | 2 (tests 1, 4) |
| M5b | land ignores its argument (literal self-merge) | 0: expected, since it matches the only caller |

"Readable state" holds for the rebase half only: no test makes BISECT_START unreadable, so that guard's mutant survives. Precise version: "...readable rebase state; the bisect readability guard is untested".

**Evidence:** `$L/mut-M0-control.log` through `$L/mut-M5b-authority-ignored.log`, `$L/mut-M3-update-refs-rerun.log`; `mutants.py`, `run-mut.sh`

---

## Claim 29: "Suites 6/145/20/79/2/2." (commits 7d78e6d0, f782d9ee, 6cbca87c)

**Location:** commit 6cbca87c message (same tally in 7d78e6d0 and f782d9ee)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pass counts at 6cbca87c, and `@test` counts at each of the three commits. It does not establish which 2-test suites the last two numbers name (fixture-git-env, utility-smoke and fixture-hermeticity all hold 2 and all pass), nor pass status at the two earlier commits (their counts are static here; i1 and i2 ran them).

These passed serially at 6cbca87c, each with its own TMPDIR, all exit 0 and 0 `not ok`:

| Suite | Tests |
|---|---|
| build-loop-merge | 6 |
| build-loop-check | 145 |
| build-loop-read | 20 |
| dev-cycle | 79 |
| fixture-git-env | 2 |
| utility-smoke | 2 |
| fixture-hermeticity | 2 |

(paraphrased — no quote available because these are tallies of `^ok` lines in the logs.) `git show <c>:test/scripts/<s>.bats | grep -c '^@test'` gives `6/145/20/79/2/2` at all three commits.

**Evidence:** `$L/build-loop-merge.log`, `$L/build-loop-check.log`, `$L/build-loop-read.log`, `$L/dev-cycle.log`, `$L/fixture-git-env.log`, `$L/utility-smoke.log`, `$L/fixture-hermeticity.log` (cmd `run-suites.sh`, cwd worktree, 2026-10-10T21:15:34Z-21:17:24Z, exit 0)

---

## Claim 30: "364 code lines." (and 7d78e6d0's "299", f782d9ee's "337")

**Location:** commit 6cbca87c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief's numstat formula against main (6666a5ce). It does not establish counts against any other base.

`git diff --numstat main -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` printed `364` at HEAD (190+13 `scripts/build-loop.sh`, 161+0 the bats file). The same formula against `7d78e6d0` printed `299`, and against `f782d9ee` printed `337`. Run in the worktree, exit 0, 2026-10-10, output shown in-session.

**Evidence:** command run in the worktree at 6cbca87c

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`scripts/build-loop.sh:229-230`): if W's admin directory (or `worktrees/`) is unsearchable, `git worktree list` exits 0 without W, and main moves by CAS under W (reproduced: `merged`, W left with a staged reversal). Refuse when an entry under `worktrees/` cannot be searched, or narrow the header.
- **Claim 5c** (`scripts/build-loop.sh:230-232`): rebase/bisect state under an unsearchable directory reads as absent (`-e` false), and a rebase of main lands (reproduced). Same fix, or narrow "cannot be read" to unreadable files.
- **Claim 25b** (commit 6cbca87c D1): the same gap as 5c. It holds for a mode-000 file, not a mode-000 directory.

### Stale
(none)

### Mostly Accurate
- **Claim 14** (`scripts/build-loop.sh:1025-1026`): "No worktree may be rebasing ..." holds for searchable state only.
- **Claim 17** (`scripts/build-loop.sh:1070-1071`): the state gate's own git reads run in W first. Say "before any other git command".
- **Claim 26** (commit 6cbca87c D2): the "NEW after a post-write refusal" fix is in land's comment, not the header.
- **Claim 28** (commit 6cbca87c): the BISECT_START readability guard's mutant survives the suite (no test for it).

### Unverifiable
(none)

### Composition note
Claims 5b, 5c, 14 and 25b share one root: land treats a path that cannot be stat'ed or listed as absent (`git worktree list` exit 0, `[[ ! -e ]]`, glob expansion). They are separate claim locations for one defect, not separate defects.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, structured per the code-fact-check skill, with a `Commit: 6cbca87c` line at the top.
- Answered: yes. All eight claim groups in the brief are verdicted (33 claims), the suites and line counts were re-run, and eight mutants were run on scratch copies. One new non-racing fail-open was found and reproduced: unsearchable worktree or rebase-state directories (5b/5c/25b).
- Out of scope: code quality, and fixes. The i1/i2 reports were used as context only.
- Escalate: the unsearchable-directory fail-open (claims 5b, 5c, 14, 25b) is new for this final pass and belongs to the security critic and the rubric's amber inventory. It needs a hostile same-uid writer, but it is not a race: the state is planted before the run. It is not covered by rows 509/646 (Q-103 races) or by the i2 security listed candidate 3 (an unreadable file). No hallucination pattern qualified: the Incorrect verdicts are fail-open gaps, not fabricated symbols.
