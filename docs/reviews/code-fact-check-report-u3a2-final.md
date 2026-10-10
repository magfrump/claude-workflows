# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u3a2, branch feat/build-loop-u3a2)
**Scope:** `git diff main...HEAD -- scripts test` at 6cbca87c (scripts/build-loop.sh, test/scripts/build-loop-merge.bats), plus the branch's commit messages (`git log main..HEAD`: 7d78e6d0, f782d9ee, 6cbca87c). Final confirming pass; merged from replicates r1, r2, r3 (`docs/reviews/code-fact-check-report-u3a2-final-r1.md`, `-r2.md`, `-r3.md`).
**Checked:** 2026-10-10
**Total claims checked:** 42
**Summary:** 30 verified, 9 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable
**Commit:** 6cbca87c
**Replication:** k=3

Merge notes. This report is mechanical collation of the three replicate reports under the code-review skill's most-severe-wins rule; it adds no claims or evidence. Claims are emitted at the finest granularity any replicate used; a replicate that verdicted only the enclosing compound claim is recorded as `(compound)`. Carried prose keeps each replicate's log references, with the log-root variables renamed so they do not collide:
- `$L1` = r1's `$LOGS` = `/tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-i3-fc-1/logs`
- `$L2` = r2's `$L` = `/tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-i3-fc-2/logs`
- `$L3` = r3's `$L` = `/tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-i3-fc-3/logs`

Each replicate's execution provenance (commands, cwd, timestamps, git 2.39.5) is in its own report header.

## Claims requiring attention (summary)

### Incorrect
- **Claim 8** (`scripts/build-loop.sh:229-230`): "the worktrees or the git directory cannot be read" — an unsearchable `worktrees/` or W admin directory makes `git worktree list` exit 0 without W, and main moves by CAS under W (r2, reproduced).
- **Claim 9** (`scripts/build-loop.sh:230-232`): "or that state cannot be read" — rebase/bisect state under an unsearchable directory (r2) or at a path that is a directory (r3) reads as absent, and a rebase of main lands.
- **Claim 33** (commit 6cbca87c D1): "unreadable rebase or bisect state refuses" — same gap as Claim 9, in the commit message.

### Stale
(none)

### Mostly accurate
- **Claim 5** (`scripts/build-loop.sh:221-224`): an email git var resolves to empty (only the other side's email key configured) lands as `<>` with no "no identity" refusal.
- **Claim 13** (`scripts/build-loop.sh:903-909`): the repository rule does not place land's W reads or its real-repository worktree list, git-common-dir and git var.
- **Claim 16** (`scripts/build-loop.sh:1009-1014`): "Returns 1 when git knows none" — it returns 1 when git var fails; an empty email passes.
- **Claim 18** (`scripts/build-loop.sh:1025-1026`): "No worktree may be rebasing ..." holds for searchable state only.
- **Claim 19** (`scripts/build-loop.sh:1038-1039`): after the "not at the merge after the fast-forward" refusal, NEW can be reachable from the branch W's HEAD moved.
- **Claim 22** (`scripts/build-loop.sh:1070-1071`): the state gate's own git reads run in W first.
- **Claim 31** (commit 6cbca87c B1): the gate follows the rebase/bisect scan, and has Claim 22's "any git command" imprecision.
- **Claim 34** (commit 6cbca87c D2): "NEW after a post-write refusal" went into land's comment, not the header.
- **Claim 37** (commit 6cbca87c): the BISECT_START readability guard's mutant (M4b) survives the suite.

---

## Claim 1: "scripts/build-loop.sh --merge BRIEF --expect SHA" (usage header and usage())

**Location:** `scripts/build-loop.sh:9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the usage synopsis and the arity guard that enforces one brief plus --expect. Does not establish the messages for a malformed --expect value, which are shared with --check (override row 665).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: same does-not-establish clause as Scope (--expect value messages, row 665) · r2: "[the arity guard] runs before the --check messages"

The usage text matches: `usage() { echo "$1 (usage: ... | --merge BRIEF --expect SHA)" >&2; exit 1; }` (`scripts/build-loop.sh:277`). The guard is `[[ "$MODE" == check || ( -n "$EXPECT" && ${#ARGS[@]} -eq 1 ) ]] || usage "--merge takes one brief path and --expect SHA"` (`:292`). Test 3 runs the shapes `"$B"`, `"--expect $T"` and `"$B $B --expect $T"`, and expects exit 1 with that message (`test/scripts/build-loop-merge.bats:87-90`). The test passed (`$L1/build-loop-merge.log`, exit 0).

**Evidence:** `scripts/build-loop.sh:277`, `scripts/build-loop.sh:282-294`, `test/scripts/build-loop-merge.bats:87-90`, `$L1/build-loop-merge.log`

---

## Claim 2: "merged BRIEF TIP TREE NEW ... a commit of TREE whose parents are main's commit and TIP, with the message "Merge branch 'BRANCH' (build-loop self-merge)" and the trailer "Build-loop-gate: STEM" (the brief's file name without .md)"

**Location:** `scripts/build-loop.sh:212-219`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merged line's field order and the merge commit's tree, parents, message and trailer. Does not establish how a STEM made of unusual characters would render, because pathform-limited brief names were the only ones tried.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: verdicted this together with the reflog sentence (Claim 3) as one compound claim at `:213-221` · r3: "does not establish the message for an authority other than self-merge (U3a3)"

The merged line is built as `v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"` (`:1143`). The commit is written with `printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "$1" "${VERDICT[stem]}"` and `gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}"` (`:1095-1096`). The stem is `stem="${a##*/}"; stem="${stem%.md}"` (`:987`). Test 1 asserts each of these values: the full output, `$n^1 $n^2 $n^{tree}` = `$M $T $TR`, and the message body. It passed.

**Evidence:** `scripts/build-loop.sh:987`, `scripts/build-loop.sh:1095-1098`, `scripts/build-loop.sh:1143`, `test/scripts/build-loop-merge.bats:43-57`, `$L1/build-loop-merge.log`

---

## Claim 3: "its reflog entry reads "build-loop: self-merge of STEM" (git adds ": Fast-forward" when W moves it)"

**Location:** `scripts/build-loop.sh:219-221`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default branch's reflog subject on both moves and the W HEAD reflog. Does not establish reflog behaviour when core.logAllRefUpdates is off, which this pass did not test.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish that W's HEAD reflog uses the same text (it does use GIT_REFLOG_ACTION, but no test reads it)" · r3: "does not establish W's HEAD reflog text, which the header does not quote" · r1: probe P2 printed W's HEAD reflog (see evidence)

The code sets `msg="build-loop: $1 of ${VERDICT[stem]}"` (`:1044`). The CAS path passes it with `git update-ref -m "$msg"` (`:1102`). The W path passes it with `GIT_REFLOG_ACTION="$msg" git -C "$w" ... merge --ff-only` (`:1108`). Test 1 asserts the reflog subject `build-loop: self-merge of 2026-10-01-x` after the CAS (`test/scripts/build-loop-merge.bats:54`). Test 4 asserts `...: Fast-forward` after W's move (`:102`). Probe P2 printed W's HEAD reflog as `build-loop: self-merge of 2026-10-01-x: Fast-forward` (`$L1/probe-fc1.log`).

**Evidence:** `scripts/build-loop.sh:1044`, `scripts/build-loop.sh:1102`, `scripts/build-loop.sh:1108`, `test/scripts/build-loop-merge.bats:54`, `test/scripts/build-loop-merge.bats:102`, `$L1/probe-fc1.log`

---

## Claim 4: "Author and committer names and emails from GIT_AUTHOR_NAME/EMAIL and GIT_COMMITTER_NAME/EMAIL, or else git config (the caller's global file included, the system file not); EMAIL or a guess from the host refuses instead" (source order and refusal)

**Location:** `scripts/build-loop.sh:221-224`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of the identity sources, the caller's global file being read, the system file not being read, and an identity whose email would come only from EMAIL being refused. Does not establish the partial-configuration case, which is Claim 5.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish the passwd/domain guess case on a host that has a domain; that rests on `user.useConfigOnly` semantics" · r2+r3: "git config" also includes the repository's own `.git/config` user.*, which the header does not single out · r3: "does not establish that the system file is skipped by execution (static only: `GIT_CONFIG_NOSYSTEM=1` is exported at `:326` and `env` in merge_ident does not unset it)" · r3: probed GIT_CONFIG_GLOBAL unset with only an XDG file: `xdg <x@example.invalid>`, and a full `--merge` committed as that identity; an env name with a config email gives `t <c@example.invalid>` (`$L3/probe.log`)

The identity comes from `env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var "GIT_${w}_IDENT"` (`:1018`). GIT_CONFIG_NOSYSTEM=1 remains exported from `:326`. Test 3 checks three cases (`test/scripts/build-loop-merge.bats:73-81`), and all of them passed:
- With no identity, it refuses.
- With names set and only EMAIL, it refuses.
- With `GIT_CONFIG_GLOBAL=$BATS_TEST_TMPDIR/gc`, it records `g g@example.invalid` as both author and committer.

An ad hoc probe confirmed what useConfigOnly changes:
- `GIT_AUTHOR_NAME=n EMAIL=e@x git var GIT_AUTHOR_IDENT` prints `n <e@x>` without the flag.
- `GIT_AUTHOR_NAME=n GIT_COMMITTER_NAME=n EMAIL=e@x git -c user.useConfigOnly=true var GIT_COMMITTER_IDENT` dies with `fatal: no email was given and auto-detection is disabled` and exits 128.

**Evidence:** `scripts/build-loop.sh:323`, `scripts/build-loop.sh:326`, `scripts/build-loop.sh:1015-1022`, `test/scripts/build-loop-merge.bats:71-81`, `$L1/build-loop-merge.log`

---

## Claim 5: "Author and committer names and emails from ... or else git config ...; EMAIL or a guess from the host refuses instead" / "no identity is known" (refusal) — partial configuration

**Location:** `scripts/build-loop.sh:221-224`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 when only one side's email key (committer.email or author.email) is configured. Does not establish whether other git versions behave the same way.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: escalated as an amber input for the rubric ("an empty-email identity lands silently"); not covered by any override row (`grep -i 'empty email\|committer.email'` returns nothing) · r2+r3: verdicted the identity sentence only as a whole (r2 Claim 3, r3 Claim 4); neither probed the one-sided email-key case

When config sets `committer.email` and `user.name` but no `user.email`, `git -c user.useConfigOnly=true var GIT_AUTHOR_IDENT` exits 0 with `u <> ...`, an empty email. The regex in merge_ident accepts an empty email: `\<([^\<\>]*)\>` (`:1019`). End to end, probe P1 configured `committer.email` and `user.name` in the repo and unset GIT_AUTHOR_*/GIT_COMMITTER_*. It printed `status=0 out=merged ...` and the merge commit recorded `author=[u <>] committer=[u <c@example.invalid>]` (`$L1/probe-fc1.log`).

So the landed author's email comes from neither the environment nor git config, and the documented "no identity is known" refusal does not fire. The precise version: an email that git var resolves to empty, which happens when only the other side's email key is configured, lands as `<>`.

**Evidence:** `scripts/build-loop.sh:1018-1020`, `$L1/probe-fc1.log` (P1)

---

## Claim 6: "With the branch checked out in no worktree it moves by compare-and-swap from the checked commit; checked out in a worktree W, by merge --ff-only in W."

**Location:** `scripts/build-loop.sh:224-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both moves whenever `git worktree list` reports the worktree that has the branch checked out. It does not establish the case where git cannot read that worktree's admin directory: W is then left out of the listing and the branch moves by CAS underneath it (Claim 8).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r1: "does not establish behaviour on a case-insensitive ref store (override row 655)" · r2: the unreadable-admin-directory gap named in Scope is escalated (see Escalations E2)

W is the path whose porcelain record holds `"branch refs/heads/$MAIN"` (`scripts/build-loop.sh:1052`). Without a W the move is `git update-ref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA"` (`:1102`); with one it is `git -C "$w" ... merge --ff-only -q "$NEW"` (`:1108`). Tests 1, 2 and 4 exercise both moves and the CAS failure, and all pass.

**Evidence:** `scripts/build-loop.sh:1048-1054`, `scripts/build-loop.sh:1101-1111`; `$L2/build-loop-merge.log`

---

## Claim 7: the refusal list ("or refuse BRIEF: WHY ... when: ...") names every refusal land and the merge arm produce, and nothing else

**Location:** `scripts/build-loop.sh:227-245`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one-to-one mapping between the header's list and every `MERGE_WHY=` assignment in land (`:1043-1112`) plus the merge arm's policy refusal (`:1142`). It does not establish that each refusal fires for every state its words cover; Claims 8 and 9 are two such gaps.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: verdicted the whole list as one claim; "does not establish that the header phrasing of the empty-email case is complete (Claim 4b [merged Claim 5]), and does not cover runs that stop part way with no line, which the Exit line covers" · r3: "does not establish the readability atom, which is split out as 5b [merged Claim 9]" · r1+r3: count 18 `MERGE_WHY=` sites; r2 counts fifteen

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

## Claim 8: "[refuse when] the worktrees or the git directory cannot be read"

**Location:** `scripts/build-loop.sh:229-230`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Low (hostile same-uid loop; non-racing planted state, so in scope per the brief's threat model)
**Legibility-target:** header refusal list and land's worktree discovery
**Scope:** Covers an unsearchable `$common/worktrees` directory and an unsearchable `$common/worktrees/<W>` admin directory while the branch is checked out in W. It does not establish other unreadable shapes, such as an unreadable `gitdir` file inside a searchable admin directory.
**Replicate verdicts:** r1=Verified (compound) · r2=Incorrect · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** r1: verdicted the whole refusal list as a two-way mapping (merged Claim 7), maps this clause to `:1048` and `:1058` · r3: verdicted the list as mapping plus "each listed refusal is made" (r3 Claim 5a), carving out only the rebase/bisect readability atom · r2: escalated to the security critic and the rubric's amber inventory; "new for this final pass ... not covered by rows 509/646 (Q-103 races) or by the i2 security listed candidate 3 (an unreadable file)" · r2 composition note: Claims 5b, 5c, 14, 25b [merged 8, 9, 18, 33] "share one root: land treats a path that cannot be stat'ed or listed as absent ... separate claim locations for one defect"

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

**Evidence:** `scripts/build-loop.sh:1048-1054`, `scripts/build-loop.sh:1101-1103`; `$L2/probeB.log` (cmd `timeout 300 bash probeB.sh`, cwd the scratch dir, exit 0, 2026-10-10T21:18:10Z), `$L2/probeB2.log` (exit 0, 2026-10-10T21:18:26Z)

---

## Claim 9: "a worktree is rebasing it (or a paused rebase will move it) or bisecting from it, or that state cannot be read"

**Location:** `scripts/build-loop.sh:230-232`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Low (hostile same-uid loop; non-racing)
**Legibility-target:** header refusal list; land's rebase/bisect scan
**Scope:** Covers state that cannot be read because its directory is unsearchable (the `rebase-merge/` directory, or a worktree admin directory as in Claim 8). It does not establish anything against readable state, which refuses correctly (test 5), or against an unreadable *file* (`chmod 000 head-name`), which refuses.
**Replicate verdicts:** r1=Verified (compound) · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r3 (independent mechanism, executed): a `head-name`, `update-refs` or `BISECT_START` that is a *directory* passes `-r`; grep then exits 2 and `! grep` is true, and `$(<dir)` yields an empty string, so each of the three directory shapes gave `status 0`, `merged ...` and moved main, with `grep: ...: Is a directory` on stderr (`$L3/probe.log`, `== head-name is a directory: status 0`, `== update-refs is a directory: status 0`, `== BISECT_START is a directory: status 0`) · r3 scope: "does not establish the permission-denied case, which does refuse (test 5, mutant M4a), and it does not establish other read errors (EIO) by execution"; r3 severity Low ("planted state that git itself could not use, not an honest path"), Legibility-target for-author; escalated to the amber inventory · r2: the directory/FIFO `head-name` case was inferred, not executed (r3 executed the directory case) · r1: verdicted the whole refusal list as one mapping claim (merged Claim 7) · r2: escalated to the security critic (see E2); composition note as in Claim 8

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

**Evidence:** `scripts/build-loop.sh:1059-1067`; `$L2/probeA.log` (cmd `timeout 300 bash probeA.sh`, exit 0, 2026-10-10T21:18:09Z); `$L3/probe.log` (r3's directory shapes)

---

## Claim 10: "Writes nothing but --check's merge objects ..., --merge's commit, the branch it moves and that branch's reflog (and in W: its files, index, HEAD reflog and ORIG_HEAD), and its own temporary directory"

**Location:** `scripts/build-loop.sh:249-253`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the files under .git, excluding object contents, that change during one successful CAS run and one successful W run in a fixture. Does not establish writes on refusal paths beyond the unreachable commit (Claim 19), or writes that a maintenance or gc run would make if it were enabled.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish writes under hostile config, which the state gate refuses"; r2's probe C saw two new loose objects on the W landing · r3: static only, Confidence Medium; "does not establish every file git may touch inside .git during a fast-forward, for example lock files"; harden sets `core.hooksPath=/dev/null` (`:315`)

Probe P2 hashed every file under `.git` before and after each run (`$L1/probe-fc1.log`):
- The CAS run changed `logs/refs/heads/main` and `refs/heads/main` and added one loose object.
- The W run changed `ORIG_HEAD`, `index`, `logs/HEAD`, `logs/refs/heads/main` and `refs/heads/main`, plus the working tree.

git status in W writes no index because `GIT_OPTIONAL_LOCKS=0` is exported (`:326`).

**Evidence:** `scripts/build-loop.sh:326`, `scripts/build-loop.sh:1081`, `$L1/probe-fc1.log` (P2)

---

## Claim 11: "Exit: 0 every line printed (or help), for --check every verdict line ok, for --merge merged; 2 any other --check or --merge verdict line ... a failed mktemp (--check, --merge; no line printed)"

**Location:** `scripts/build-loop.sh:256-262`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge arm's exit codes for merged, refused, and skipped/--check-refused lines, and mktemp's place in gate_start. Does not establish every "failed command's own status" path, which comes from the pre-existing header text.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: the failed-mktemp exit is established statically only (`GATE_TMP="$(mktemp -d)"` under `set -e`, `:912`), not by execution · r2: "land runs as an `elif` condition, so set -e cannot end the run inside it" · r3: also asserts exit 1 on usage (`build-loop-merge.bats:89`)

The merge arm runs `[[ "$v" == merged* ]] || exit 2` (`:1145`) and `cat ...; exit 2` (`:1141`). gate_start runs `GATE_TMP="$(mktemp -d)"` under `set -e` (`:912`), which exits with mktemp's status before any line prints. The tests assert status 0 on merged and 2 on refusals (`refused`, `nref`), and the second run in test 1 asserts status 2 on a --check refusal (`test/scripts/build-loop-merge.bats:56`). All passed.

**Evidence:** `scripts/build-loop.sh:912`, `scripts/build-loop.sh:1141-1145`, `test/scripts/build-loop-merge.bats:38-41`, `$L1/build-loop-merge.log`

---

## Claim 12: "The caller's global config, for merge_ident alone (the merge commit's names: all a loop that writes it could change there); every other call reads none."

**Location:** `scripts/build-loop.sh:321-323`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reference to CALLER_GLOBAL and the GIT_CONFIG_GLOBAL export that follows. Does not establish anything about git calls that run before `:326` (there are none in this file: lines 266-320 run perl's check, the lib's sourcing, scrub_reexec's bash re-exec and argument parsing), or about the caller's own `-c`/GIT_CONFIG_PARAMETERS, which harden trusts.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish what keys in a planted global file could do to `git var` beyond identity (harden's command-line pairs still outrank it, and `user.useConfigOnly` is forced)" · r3: "does not establish what the parenthetical 'all a loop that writes it could change there' says about threats, which is rationale"

`grep CALLER_GLOBAL` hits only `:323` (the definition) and `:1018` (merge_ident). Immediately after, `export ... GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` (`:326`) applies to every later git call. scrub_reexec runs `DEV_CYCLE_SCRUBBED=1 bash "$self" "$@"` and no git (`scripts/lib/dev-cycle-read.sh:150-155`).

**Evidence:** `scripts/build-loop.sh:323`, `scripts/build-loop.sh:326`, `scripts/build-loop.sh:1018`, `scripts/lib/dev-cycle-read.sh:150-155`

---

## Claim 13: gate_start's repository rule: "main's files and refs, the branch tips, the checkout and store_check's object reads are in the real repository; the merge computations ... and --merge's commit-tree run through gate_git (into the real object store). --merge moves the branch in the real repository (update-ref) or in W (merge --ff-only), and merge_ident alone reads the caller's global config."

**Location:** `scripts/build-loop.sh:903-909`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Severity:** Informational
**Legibility-target:** for-author
**Scope:** Covers every call the rule names: commit-tree via gate_git into GIT_OBJECT_DIRECTORY, update-ref in the real repository, merge --ff-only in W, and git var as the sole reader of the caller's global config. It does not establish a placement for land's other reads, which the rule leaves out.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1: Verified, with "does not establish anything about W's own pre-move reads (state_gate, rev-parse and status run with `cd "$w"` or `git -C "$w"`), which the rule does not enumerate but which are the same repository's worktree" · r2: Verified, with "does not establish that the rule is exhaustive: land's discovery reads (worktree list, `--git-common-dir`, and in W rev-parse, status and the state gate) are not named. They run in the real repository or in W"; own_blob reads main's file with plain `git cat-file blob "$MAIN_SHA:$1"` (`:723`), in the real repository as the rule says

Each named placement holds:
- `x="$(gate_git commit-tree ...)"` (`:1096`) runs in the gate repository, with `GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")` pointing at the real objects directory (`:629`).
- `git update-ref` (`:1102`) runs in the real repository.
- `git -C "$w" ... merge --ff-only` (`:1108`) runs in W.

The rule says nothing about land's reads in W: `(cd "$w" && state_gate)` (`:1073`, `:1099`), `git -C "$w" rev-parse` and `symbolic-ref` (`:1074-1075`), the `--git-path` probes (`:1078`) and `git -C "$w" status` (`:1081`). It also does not cover the real-repository `git worktree list` (`:1048`), `git rev-parse --git-common-dir` (`:1058`) and `git var` (`:1018`). Precise version: add "land's worktree reads (state_gate, rev-parse, status) run in W; worktree list and git var in the real repository".

**Evidence:** `scripts/build-loop.sh:612-639`, `scripts/build-loop.sh:903-909`, `scripts/build-loop.sh:1018`, `scripts/build-loop.sh:1048`, `scripts/build-loop.sh:1058`, `scripts/build-loop.sh:1073-1081`, `scripts/build-loop.sh:1096-1108`

---

## Claim 14: "VERDICT holds tip, tree, policy, branch and stem, and CHANGED each changed path's status letter, only after an ok line (both empty otherwise)."

**Location:** `scripts/build-loop.sh:930-933`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return path of check_line, all of which were read from `:935` to `:1007`. Does not establish anything about need_root's exit inside the floor walk, which ends the run rather than returning.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: same need_root-exit residue as Scope · r2: "'After' is loose: the values are set just before the echo, inside the same function"; check_line runs in the merge arm's shell with only stdout redirected (`:1137`), so the values persist · r3: "Mutant M8 of i2 (CHANGED filled in the loop) is settled (override row 664)"

Both arrays are emptied first: `VERDICT=(); CHANGED=()` (`:939`). The only writer is verdict_ok (`:990-995`), which also prints `echo "ok $a $sha $tree"`. Its two call sites are `if [[ -n "$co" ]]; then echo "$co"; else verdict_ok; fi; return` (`:996`) and `elif [[ "$nd" -eq 0 ]]; then verdict_ok` (`:1005`). Every other return (`:942`, `:944-947`, `:951-952`, `:957`, `:961`, `:967`, `:974`, `:977`, `:998`) comes before any call, and `:1005`'s other branches print refusals without calling it.

**Evidence:** `scripts/build-loop.sh:935-1007`

---

## Claim 15: "Reads check_line's locals (bash scope is dynamic); called only here."

**Location:** `scripts/build-loop.sh:989`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers verdict_ok's reads and call sites. Does not establish anything about the fact that bash defines verdict_ok globally once check_line has run (a later caller could call it). No such caller exists.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish anything about a future caller outside check_line, where the names would resolve to globals" · r2+r3: `local i` (`:991`) keeps the loop index from overwriting check_line's `i`; r3: check_line does not read `i` after either call · r2 cites the first call at `:997` (r1, r3: `:996`)

verdict_ok reads `$sha $tree $pol $br $stem $a` and `ps`/`ss`, all declared in check_line's `local` list (`:938`), and declares only `local i` (`:991`). `grep -n verdict_ok` finds the definition (`:990`) and the calls at `:996` and `:1005`, both inside check_line.

**Evidence:** `scripts/build-loop.sh:938`, `scripts/build-loop.sh:990-996`, `scripts/build-loop.sh:1005`

---

## Claim 16: merge_ident: "as git var resolves them: the environment's GIT_AUTHOR_NAME/EMAIL and GIT_COMMITTER_NAME/EMAIL, then git config with the caller's global file (no system file ...), each name and email on its own. user.useConfigOnly: without them git would take EMAIL or guess ...; it refuses instead. ... Returns 1 when git knows none."

**Location:** `scripts/build-loop.sh:1009-1014`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the source order, the useConfigOnly refusal, the export, and the return value, against probes P1/A-D and test 3. Does not establish anything about other git versions.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: return 1 also covers a git var line the regex rejects (r2: "a name holding `<` or `>`"), which the comment does not mention · r3: "does not establish the passwd/domain guess by execution (this host's fixture always has a name)" · r2+r3: the exported identity variables pass through gate_git because GATE_ENV unsets only `git rev-parse --local-env-vars` names; the gate repository's config holds only core/extensions · r1: escalated with merged Claim 5 as an amber rubric input (see E1)

The sources, the refusal of EMAIL and the export all hold (Claim 4). "Returns 1 when git knows none" is imprecise for the case Claim 5 found. When only `committer.email` is configured, `git var GIT_AUTHOR_IDENT` succeeds with an empty email (`u <> 1791667067 -0700`, rc=0, ad hoc probe D). The regex `^([^\<\>]+)\ \<([^\<\>]*)\>\ ...` (`:1019`) accepts that, so merge_ident returns 0 and exports `GIT_AUTHOR_EMAIL=` (P1 recorded `author=[u <>]`). The precise version: it returns 1 when git var fails, and an empty email passes.

**Evidence:** `scripts/build-loop.sh:1015-1022`, `$L1/probe-fc1.log` (P1)

---

## Claim 17: land: "decide, then write, then move (D7, F29). ... When no worktree has it checked out: a compare-and-swap (update-ref from MAIN_SHA ...). When a worktree W has it: W must be its own top level ..., on it at MAIN_SHA, with no tracked change, no merge, cherry-pick, revert, rebase, bisect or sequence in progress, nothing at a path the merge adds (an untracked or ignored file: merge --ff-only overwrites an ignored one) and no file or link where the merge needs a directory. Then the merge commit NEW ... is written in the gate repository, the state gate (here and in W) and default_gate run again (row 494), and the branch moves ..., after which it must read NEW."

**Location:** `scripts/build-loop.sh:1023-1038`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of decide, write and move against the code, each listed W condition, the re-gate set, and git 2.39.5 overwriting an ignored file. Does not establish anything about W's own checkout settings (override row 657), or the races named as residuals.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2+r3: verdicted land's whole comment (`:1023-1041`) including the NEW sentence (merged Claim 19); r2 split the rebase/bisect sentence out (merged Claim 18) · r3: "does not establish anything about the named residual races" · r2: "does not establish 'unreachable' in the residual race where W switches branch (the other branch would then hold NEW)"

The order in the code:
- Decide: identity, worktree list, scan, then W's checks (`:1046-1094`).
- Write: `printf ... && x="$(gate_git commit-tree ...)"` (`:1095-1097`).
- Re-gate: `{ state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; }` (`:1099`).
- Move (`:1101-1110`), with `[[ "$(git rev-parse --verify -q "refs/heads/$MAIN")" == "$NEW" ]]` after the fast-forward (`:1110`).

Probe P3 tested the parenthetical. It put an ignored `work-feat-x.txt` (via info/exclude) holding `mine` in place, then ran `git merge --ff-only`. The merge returned 0, and the file then held `feat/x` (`$L1/probe-fc1.log`).

**Evidence:** `scripts/build-loop.sh:1043-1112`, `$L1/probe-fc1.log` (P3), `test/scripts/build-loop-merge.bats:117-143`

---

## Claim 18: "No worktree may be rebasing the default branch or bisecting from it."

**Location:** `scripts/build-loop.sh:1025-1026`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every worktree whose admin directory and rebase/bisect state git and bash can search. It does not hold when that state sits under an unsearchable directory (Claims 8, 9).
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1: verdicted this sentence inside land's whole comment (merged Claim 17) · r3: verdicted it inside land's whole comment (r3 Claim 13) · r2: part of the one-root fail-open (composition note, Claims 8/9/18/33) and its escalation (E2)

The scan (`:1059-1067`) enforces this for readable state, and test 5 passes. Probe A shows that a rebase of main whose `rebase-merge/` directory is mode 000 lands (`merged`, exit 0). A precise version would say that state which cannot be searched reads as absent. The verdict is Mostly accurate rather than Incorrect because this sentence states the rule, not the handling of unreadable state; Claim 9 carries the refuted mechanism.

**Evidence:** `scripts/build-loop.sh:1059-1067`; `$L2/probeA.log`

---

## Claim 19: "Sets NEW, or MERGE_WHY and returns 1 (a refusal after the write leaves NEW set and unreachable in the store)."

**Location:** `scripts/build-loop.sh:1038-1039`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusals after the write: the re-gate, the CAS, a failed ff, and the "not at the merge after the fast-forward" refusal. Does not establish anything about gc timing of the unreachable object.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: Verified within land's whole comment, with scope "does not establish 'unreachable' in the residual race where W switches branch (the other branch would then hold NEW)" — the same case r1 probed · r2+r3: `NEW` stays set on any refusal after `:1098`, and the merge arm prints only `MERGE_WHY` then

The claim holds for the re-gate, CAS and failed-ff refusals, because no ref is moved. It does not hold for `MERGE_WHY="the default branch is not at the merge after the fast-forward in $in"` (`:1110`). That refusal fires after `merge --ff-only` succeeded on whatever W's HEAD named.

Probe P5 used a shim to switch W to a new branch `other` at MAIN_SHA just before the ff, which is the residual race the comment names. It printed `status=2 refuse ...: the default branch is not at the merge after the fast-forward ...` and `other=344286a1... main=ddc74c87... M=ddc74c87...`, so NEW is reachable from `other` and from W's HEAD reflog. The precise version: NEW is left unreachable except after that last refusal, where the ff may have moved another branch to it.

**Evidence:** `scripts/build-loop.sh:1098`, `scripts/build-loop.sh:1108-1110`, `$L1/probe-fc1.log` (P5)

---

## Claim 20: "Each worktree's own git dir, read as files: the common one and those under worktrees/ (dot names too). worktree list shows a rebasing worktree as detached, so only its rebase state names the branch."

**Location:** `scripts/build-loop.sh:1055-1059`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the glob set (`*`, `.[!.]*`, `..?*` under worktrees/, which together match every name but `.` and `..`) and git 2.39.5's porcelain output during a paused rebase. Does not establish anything about a caller with dotglob set, which would only duplicate entries.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish coverage when `worktrees/` itself cannot be listed (the globs then expand to nothing and the loop skips them; claim 5b [merged Claim 8])"; r2's "detached" statement was paraphrased, not probed (r1's P4 probed it) · r3: "does not establish that git can register a dot-named worktree admin directory"

The loop is `for d in "$common" "$common"/worktrees/* "$common"/worktrees/.[!.]* "$common"/worktrees/..?*; do [[ -d "$d" ]] || continue` (`:1059-1060`). Test 5 plants `.x/rebase-merge/head-name` and expects a refusal (`test/scripts/build-loop-merge.bats:139-140`), and it passed. Probe P4 paused `git rebase -x false HEAD~1` in a worktree on main. `git worktree list --porcelain` printed that worktree as `HEAD ddc74c87... detached`, while `rebase-merge/head-name` read `refs/heads/main`.

**Evidence:** `scripts/build-loop.sh:1058-1068`, `test/scripts/build-loop-merge.bats:139-140`, `$L1/probe-fc1.log` (P4)

---

## Claim 21: "A rebase of it, or one that will move it (--update-refs lists it)."

**Location:** `scripts/build-loop.sh:1061-1064`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's update-refs file format for a real paused `rebase -i --update-refs` and the `grep -qxF` match on it. Does not establish anything about the rebase-apply backend, which has no --update-refs.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: the apply backend has no update-refs file "and git refuses `--update-refs` with it" · r3: "does not establish git's own update-refs format beyond the test fixture's three-line record" (r1 probed a real rebase); a probe of `rebase-apply/head-name` in the common git dir refuses (`$L3/probe.log`)

An ad hoc probe ran a real `GIT_SEQUENCE_EDITOR='sed -i 1ibreak' git rebase -i --update-refs HEAD~2` of feat/z, whose range holds main's commit. In `rebase-merge/`, `head-name` read `refs/heads/feat/z` and `update-refs` held `refs/heads/main` on a line of its own, followed by two ids. The code's `grep -qxF "refs/heads/$MAIN" "$d/$q"` with `q=rebase-merge/update-refs` (`:1062-1063`) matches that line. Mutant M3 dropped `rebase-merge/update-refs` from the list, and test 5 then failed (`$L1/mut-summary.txt`).

**Evidence:** `scripts/build-loop.sh:1062-1064`, `$L1/mut-M3.log`, `$L1/mut-summary.txt`

---

## Claim 22: "W's own config.worktree before any git command runs there (git status would run a filter it names); the startup gate read this checkout's."

**Location:** `scripts/build-loop.sh:1070-1071`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the git commands run in W before and inside the gate. Does not establish that any config.worktree key can make those read-only calls run a command; none was found.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: precise version "before any git command but the state gate's own config and ref reads runs there"; probe D: with the early gate removed (M1) the filter ran (`FILTER RAN`) and the run refused only after the write; with the real script `filter did not run` (`$L2/probeD.log`) · r3: precise version "before any git command reads W's work tree or index"; "None of these reads the work tree or index or runs a filter"; mutant M1 fails test 6 (`$L3/mut-M1-early-gate.log`); Severity Informational, Legibility-target for-author

No git command runs in W before `(cd "$w" && state_gate)` (`:1073`). The only earlier git calls, `worktree list` (`:1048`) and `rev-parse --git-common-dir` (`:1058`), run in the caller's top level, and the rebase scan reads files. However, the gate is itself four git commands run in W, and each loads W's config, config.worktree included, with includes followed. Those commands are:
- `git rev-parse --path-format=absolute --git-path "$f"` (`:344`, `:353`)
- `git config --file "$p" --no-includes ...` (`:346`)
- `git for-each-ref ... refs/replace/` (`:356`)
- `git symbolic-ref -q refs/remotes/origin/HEAD` (`:358`)

The precise version: config.worktree is gated before any git command other than the gate's own reads, so the gate runs before git status. Test 6 confirms the property that matters: the clean filter never runs (`test/scripts/build-loop-merge.bats:154-158`).

**Evidence:** `scripts/build-loop.sh:341-363`, `scripts/build-loop.sh:1048`, `scripts/build-loop.sh:1058`, `scripts/build-loop.sh:1072-1073`, `test/scripts/build-loop-merge.bats:154-158`

---

## Claim 23: "$in is missing, not its own top level, or not on it at $MAIN_SHA" (the -ef test's message)

**Location:** `scripts/build-loop.sh:1074-1076`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message against its three conditions and the core.worktree case. Does not establish anything about a W whose `show-toplevel` fails for another reason; that case yields an empty string, so `-ef` is false and this message prints.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish which of them fired (one message covers all three)" · r3: "does not establish that the 'missing' disjunct is reachable outside a race: `[[ -d "$w" ]] || { MERGE_WHY="$in is missing"; ...}` (`:1072`) catches a missing W first" (r1: "'Missing' stays reachable if W vanishes after `:1072`")

The test is `[[ "$(git -C "$w" rev-parse --show-toplevel)" -ef "$w" && "$(git -C "$w" symbolic-ref -q HEAD)" == "refs/heads/$MAIN" && "$(git -C "$w" rev-parse --verify -q 'HEAD^{commit}')" == "$MAIN_SHA" ]]` (`:1074-1075`). It covers top level, on the branch, and at MAIN_SHA. "Missing" stays reachable if W vanishes after `:1072`. Test 6 sets `core.worktree` elsewhere and expects this exact message (`test/scripts/build-loop-merge.bats:152-153`), and it passed.

**Evidence:** `scripts/build-loop.sh:1072-1076`, `test/scripts/build-loop-merge.bats:152-153`

---

## Claim 24: "The branch's own mergeOptions (--squash would stage the merge in W and leave the branch) cleared; no gc or maintenance task (a repack) started on the store store_check read; the reflog names the gate."

**Location:** `scripts/build-loop.sh:1105-1108`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three `-c` overrides and GIT_REFLOG_ACTION on the W fast-forward. Does not establish anything about maintenance started by other processes.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: only the loose-objects maintenance task was exercised · r3: mutant M6 (mergeOptions override dropped) fails test 4 (`$L3/mut-M6-mergeoptions.log`); r1 notes no mergeOptions mutant was run in its pass

The code is `GIT_REFLOG_ACTION="$msg" git -C "$w" -c gc.auto=0 -c maintenance.auto=false -c "branch.$MAIN.mergeOptions=" merge --ff-only -q "$NEW"` (`:1108`). Test 4 runs with `branch.main.mergeOptions --squash` and expects main moved and W clean. It also enables loose-objects maintenance and expects the pack count unchanged (`test/scripts/build-loop-merge.bats:103-111`). Both checks passed. Mutant M2 removed `-c maintenance.auto=false` and test 4 failed at the pack-count line (`$L1/mut-M2.log`).

**Evidence:** `scripts/build-loop.sh:1108`, `test/scripts/build-loop-merge.bats:103-111`, `$L1/mut-M2.log`

---

## Claim 25: "The verdict line is check_line's first (the path lines follow it); the authority (here only self-merge; U3a3 adds --approved), then land's result, replace it."

**Location:** `scripts/build-loop.sh:1138-1140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line order whenever VERDICT is set. Does not establish anything about the output-by-position design concern (override row 654).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish anything for non-ok lines, which are printed unchanged (`:1141`)" · r3: "does not establish U3a3's future behavior"

verdict_ok echoes before `printf '%s\n' "${rows[@]}"` (`:1005-1006`), and `:996` prints no rows. The arm prints `{ echo "$v"; tail -n +2 "$GATE_TMP/line"; }` (`:1144`), where `v` is the policy refusal, `merged ...` or `refuse $a: $MERGE_WHY` (`:1142-1143`).

**Evidence:** `scripts/build-loop.sh:996`, `scripts/build-loop.sh:1005-1006`, `scripts/build-loop.sh:1141-1145`

---

## Claim 26: Suite header and helper comments ("Each test builds a throwaway repo under $BATS_TEST_TMPDIR ...; this repo is untouched"; sm, orch, shim, refused)

**Location:** `test/scripts/build-loop-merge.bats:3-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each helper's documented contract against its body and the fixture lib. Does not establish anything about the hermeticity of the fixture lib itself, which is pre-existing.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish anything about the fixture lib beyond `settings`, `brief` and `work`" · r3: verdicted the helper docs together with the inline test comments (merged Claims 27-30)

- bl_setup sets `R="$BATS_TEST_TMPDIR/repo"` and cds there (`test/lib/build-loop-fixtures.bash`).
- `sm` sets B (via `brief`), T, M and TR as documented (`:19-23`).
- `orch` runs `git worktree add -q --detach "$BATS_TEST_TMPDIR/o" main && cd ...` (`:25`).
- `shim` writes a git that runs ACTION once, guarded by a `fired` file, when `"$*"` holds WHEN, then `exec "$REAL"` (`:29-36`).
- `refused` checks status 2, the first two lines and `git rev-parse main` = M (`:38-41`).

**Evidence:** `test/scripts/build-loop-merge.bats:3-41`, `test/lib/build-loop-fixtures.bash`

---

## Claim 27: Tests 1 and 2 titles ("lands ... by compare-and-swap when no worktree has main checked out: parents, tree, message, trailer; a second run refuses"; "leaves main where another writer moved it between the check and the swap, and refuses git state planted after the check"), and "commit-tree runs in the gate repository"

**Location:** `test/scripts/build-loop-merge.bats:43-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the titles and inline comment against the assertions. Does not establish anything about the test IDs' (T22, G13, G17) meaning in the plan.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: split all six titles (r2 Claim 22) from the inline comments (r2 Claim 23) · r2+r3: test 1 asserts more than its title names (identity and reflog); r2: "does not establish that those extra assertions are named anywhere"; r3: "extra coverage, not claims" · r2: "does not establish the comments' issue references (i1/i2 F-numbers) beyond their presence in docs/reviews"

Test 1 detaches R (`git checkout -q --detach main`). It asserts parents, tree, message with trailer, identity and the reflog, then asserts that a second run gives `refuse $B: its branch feat/x has no commit the default branch lacks`.

Test 2 has two shims:
- The first moves main to `o` before update-ref and expects the CAS refusal with `M="$o"`.
- The second writes `filter.x.clean` via `config --file '$R/.git/config'`, which needs an absolute path because commit-tree's cwd is `$GATE_TMP/work` with `GIT_DIR` set to the gate repository (`scripts/build-loop.sh:636`). It then expects the re-gate refusal.

Both tests passed.

**Evidence:** `test/scripts/build-loop-merge.bats:43-69`, `scripts/build-loop.sh:634-639`, `$L1/build-loop-merge.log`

---

## Claim 28: Test 3 title and "Names set but the email only in EMAIL: git would take it (and on other hosts guess from the domain); user.useConfigOnly refuses."

**Location:** `test/scripts/build-loop-merge.bats:71-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment's two git behaviours (probed) and the title's four parts against the assertions. Does not establish the parenthetical "on other hosts guess from the domain", because the passwd/host guess without EMAIL was not probed.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3: same residue as Scope ("does not establish the 'on other hosts guess from the domain' clause by execution (static, from git's documented user.useConfigOnly)")

The ad hoc probe printed `n <e@x>` without useConfigOnly and refused with it (Claim 4). Each part of the title has a matching assertion:
- No identity is covered at `:74-75`.
- EMAIL-only is covered at `:77-78`.
- The global config identity is covered at `:79-81`.
- The review brief is covered at `:83-86`.
- The three usage shapes are covered at `:87-90`.

The test passed.

**Evidence:** `test/scripts/build-loop-merge.bats:71-91`, `$L1/build-loop-merge.log`

---

## Claim 29: Test 4 title ("fast-forwards the worktree that has main checked out, from it or from another, keeping an unrelated untracked file; a worktree on another branch is left alone") and its mergeOptions and maintenance comments

**Location:** `test/scripts/build-loop-merge.bats:93-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title's parts and the two comments against the assertions, with mutant M2 confirming the pack-count pin. Does not establish anything about a mergeOptions mutant, which was not run this pass (iteration 1 recorded it).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3: the `:103-104` notes are pinned by M6 (mergeOptions) and M2 — r3 ran the mergeOptions mutant r1's Scope says was not run

The test's steps each match a part of the title or a comment:
1. The first run is from R, which is on main, with `unrelated.txt` present. It asserts HEAD at n, the file content and a clean status.
2. `orch` then runs from another worktree and asserts R moved.
3. The maintenance comment's pack count (`:105-108`) fails under M2.
4. `--squash` expects W clean and on main (`:109-111`).
5. R on `feat/y` expects R left at M on feat/y (`:112-114`).

**Evidence:** `test/scripts/build-loop-merge.bats:93-115`, `$L1/mut-M2.log`

---

## Claim 30: Tests 5 and 6 titles and comments ("A paused rebase --update-refs of another branch that will move main ...; an unreadable head-name"; "W's own config.worktree is gated before git status runs there: its clean filter never runs")

**Location:** `test/scripts/build-loop-merge.bats:117-161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each title clause and comment against the assertions, with M1, M3 and M4a killed here. Does not establish anything about the config.worktree case, which test 6's title omits (it is in the body). The title is incomplete, not false.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: test 6 asserts the config.worktree state gate, which its title does not name · r2: probe D shows that without the early gate the filter runs (`FILTER RAN`), and with it it does not (`$L2/probeD.log`)

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

All passed. M1 fails test 6 because the late re-gate's message differs (`$L1/mut-M1.log`).

**Evidence:** `test/scripts/build-loop-merge.bats:117-161`, `$L1/mut-M1.log`, `$L1/mut-M3.log`, `$L1/mut-M4a.log`

---

## Claim 31: 6cbca87c "B1 W's own config.worktree is state-gated as soon as W is known, before any git command runs there (git status ran a clean filter it named; pre-existing since 7d78e6d0)."

**Location:** commit 6cbca87c message
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gate's position at HEAD and the order at 7d78e6d0 and f782d9ee. Does not establish whether the filter ran in practice at 7d78e6d0 (not executed there).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r2: Verified; "'Before any git command' carries claim 17's [merged Claim 22] qualifier (the state gate's own reads); it is not split, because the history and consequence parts agree"; probe D reproduces the filter running under 7d78e6d0's ordering (`$L2/probeD.log`) · r3: "That scan runs no git, though"; Severity Informational (immutable message), Legibility-target for-orchestrator-synthesis

"Pre-existing since 7d78e6d0" holds. At 7d78e6d0, `git -C "$w" status` (`:1051`) ran before the only W state gate, `(cd "$w" && state_gate)` in the re-gate (`:1065`). f782d9ee has the same order (`:1069` before `:1087`).

The rest is imprecise. "As soon as W is known" skips the rebase/bisect scan, which runs between (`:1055-1068`). "Before any git command runs there" has the same imprecision as Claim 22, because the gate's own four git reads run in W.

**Evidence:** `git show 7d78e6d0:scripts/build-loop.sh` lines 1051 and 1065; `scripts/build-loop.sh:1055-1073`

---

## Claim 32: 6cbca87c "D1 a paused rebase --update-refs that will move main refuses"

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an update-refs file listing `refs/heads/main` in a readable state directory. It does not establish behavior for unsearchable state (Claim 33).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: verdicted D1 and D4 as one claim (r1 Claim 26) · r3: "does not establish git's real `rebase --update-refs` state files beyond the fixture" (r1's Claim 21 probe ran a real one)

See Claim 21. Test 5 passes, and mutant M3 fails it.

**Evidence:** `scripts/build-loop.sh:1062-1065`; `$L2/build-loop-merge.log`, `$L2/mut-M3-update-refs-rerun.log`

---

## Claim 33: 6cbca87c "D1 ... and unreadable rebase or bisect state refuses"

**Location:** commit 6cbca87c message
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Low (hostile same-uid loop; non-racing)
**Legibility-target:** commit message D1; land's scan
**Scope:** Covers state that cannot be read because its directory is unsearchable. It does not refute the unreadable-*file* case, which refuses (test 5, `chmod 000 head-name`).
**Replicate verdicts:** r1=Verified (compound) · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r3 (independent mechanism): "a head-name, update-refs or BISECT_START that is a directory merges. Only `-r`-false state refuses"; "The bisect half's `-r` guard is not tested either (Claim 25 [merged Claim 37], mutant M4b)"; Severity Low, Legibility-target for-author · r1: Verified within D1+D4; an unreadable head-name refuses (test 5) and an unreadable BISECT_START refuses (`$L1/probe-bisect-tree.log`) — permission-denied files only · r2: composition note as in Claim 8

As Claim 9 shows, `[[ ! -e "$d/$q" ]]` (`scripts/build-loop.sh:1063`) is true under an unsearchable directory, so the state reads as absent. Probe A printed `merged` with exit 0 for a mode-000 `rebase-merge/` whose `head-name` is `refs/heads/main`.

**Evidence:** `scripts/build-loop.sh:1063`, `scripts/build-loop.sh:1066`; `$L2/probeA.log`; `$L3/probe.log` (r3's directory shapes)

---

## Claim 34: 6cbca87c "D2 header: reflog suffix, identity variables, path lines, NEW after a post-write refusal."

**Location:** commit 6cbca87c message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where each listed fix landed (`git diff f782d9ee 6cbca87c -- scripts/build-loop.sh`). It does not establish anything beyond that diff.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r3: Severity Informational, Legibility-target for-orchestrator-synthesis

The first three items are in the header:
- `(git adds ": Fast-forward" when W moves it)` (`:220-221`)
- `GIT_AUTHOR_NAME/EMAIL and GIT_COMMITTER_NAME/EMAIL` (`:222`)
- `with the ok line's path lines following` (`:227`)

The fourth is not in the header. It went into land's comment: `(a refusal after the write leaves NEW set and unreachable in the store)` (`:1038-1039`). The header's refusal text does not mention NEW. A precise version: "header: reflog suffix, identity variables, path lines; land's comment: NEW after a post-write refusal".

**Evidence:** `scripts/build-loop.sh:213-245`, `scripts/build-loop.sh:1038-1039`

---

## Claim 35: 6cbca87c "D3 land takes the authority it records; verdict_ok's local i."

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `$1` reaching the reflog message and the commit message, and `local i`. It does not establish a test that tells `$1` from a hard-coded "self-merge": mutant M5b, which hard-codes it, survives, as it must while only one authority exists.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: verdicted D3 and D4 as one claim; "does not establish anything for a second authority value, which no caller passes yet"; r2's M5b (land ignores its argument) survives, "expected, since it matches the only caller"

`msg="build-loop: $1 of ..."` (`:1044`) and `"(build-loop %s)" ... "$1"` (`:1095`), called as `land self-merge` (`:1143`). Mutant M5a calls `land other` and fails tests 1 and 4. `local i` is at `:991`.

**Evidence:** `scripts/build-loop.sh:991`, `scripts/build-loop.sh:1044`, `scripts/build-loop.sh:1095`, `scripts/build-loop.sh:1143`; `$L3/mut-M5a-authority-arm.log` (exit 1), `$L3/mut-M5b-authority-literal.log` (exit 0)

---

## Claim 36: 6cbca87c "D4 a pack-count test pins maintenance.auto=false."

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loose-objects maintenance task the test enables. It does not establish that other tasks would also be caught.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: verdicted with D1 (r1 Claim 26) · r2: verdicted with D3 (r2 Claim 27)

`build-loop-merge.bats:105-108` enables `maintenance.auto` and `maintenance.loose-objects.auto 1`, then compares the pack file count. Mutant M2 fails exactly there (`line 108`).

**Evidence:** `test/scripts/build-loop-merge.bats:103-108`; `$L3/mut-M2-maintenance.log`

---

## Claim 37: 6cbca87c "Each new guard's mutant fails the suite (early gate, maintenance, update-refs, readable state, authority)."

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers six mutants of the guards 6cbca87c added, run against build-loop-merge.bats. Does not establish what the author's own mutants were, which were scratch.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2+r3: "does not establish results in other suites" (each ran an unmutated control M0, all ok) · r2: M3's first run had an unrelated test 2 failure ("a find error on another session's `/tmp/claude-1173-cwd`"); the rerun failed only test 5 · r2: M5b (land ignores its argument) survives as expected · r3: M6 (mergeOptions, an i1 guard) also caught · r1: escalated as an amber rubric input; r3: escalated as a test-strategy input (see E4) · r1+r2+r3 precise version: every new guard but the BISECT_START readability guard has a killing mutant

Five of the six mutants fail the suite (`$L1/mut-summary.txt`):

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
- M4b exits 1 with no line and `line 1066: ... BISECT_START: Permission denied` on stderr (`$L1/probe-bisect-tree.log`, `$L1/probe-bisect-mut-M4b.log`).

M4b therefore still fails closed, but its documented refusal is untested. M5, which called `land` with no argument, failed every test through `$1: unbound variable` and was replaced by M5b. The precise version: every new guard but the bisect readability test has a killing mutant.

**Evidence:** `scripts/build-loop.sh:1062-1067`, `$L1/mut-summary.txt`, `$L1/mut-M4b.log`, `$L1/probe-bisect-tree.log`, `$L1/probe-bisect-mut-M4b.log`

---

## Claim 38: 6cbca87c "Suites 6/145/20/79/2/2." (also f782d9ee and 7d78e6d0)

**Location:** commit 6cbca87c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge, check, read, dev-cycle, fixture-git-env and utility-smoke suites at HEAD (run) and the `@test` counts at all three code commits. Does not establish which suites the author meant beyond the order used in iteration 2's report.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: fixture-hermeticity also has 2 tests and passes, so which 2-test suites the last two numbers name is not established · r3: Confidence Medium; the earlier commits' counts were not re-run · r2: pass status at the two earlier commits is static (`@test` counts) only

Serial runs at HEAD gave `build-loop-merge exit=0 ok=6`, `build-loop-check exit=0 ok=145`, `build-loop-read exit=0 ok=20`, `dev-cycle exit=0 ok=79`, `fixture-git-env exit=0 ok=2` and `utility-smoke exit=0 ok=2`, with 0 `not ok` (`$L1/summary.txt`). `git show <c>:test/scripts/<suite>.bats | grep -c '^@test'` gives 6/145/20/79/2/2 at 7d78e6d0, f782d9ee and 6cbca87c alike.

**Evidence:** `/tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-i3-fc-1/logs/summary.txt` (`$L1/summary.txt`), `$L1/build-loop-merge.log`, `$L1/build-loop-check.log`, `$L1/build-loop-read.log`, `$L1/dev-cycle.log`, `$L1/fixture-git-env.log`, `$L1/utility-smoke.log`

---

## Claim 39: "364 code lines." (6cbca87c)

**Location:** commit 6cbca87c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief's numstat command against main (6666a5ce, equal to the merge base). It does not establish anything about the count with docs included.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish whether the formula is the right measure" · r1+r2: verdicted 364/337/299 as one claim

`git diff --numstat main -- ':(top)' ':(top,exclude)docs/' | awk ...` printed `364` (190+13 in scripts/build-loop.sh, 161+0 in the bats file; in-session, exit 0).

**Evidence:** `git diff --numstat main -- ':(top)' ':(top,exclude)docs/'`, cwd the worktree; `scripts/build-loop.sh`, `test/scripts/build-loop-merge.bats` (r1's citation for the same count)

---

## Claim 40: "299 code lines." (7d78e6d0) and "337 code lines." (f782d9ee)

**Location:** commit 7d78e6d0 message, commit f782d9ee message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same command with each commit as the right side. It does not establish the other claims of those messages, which are settled or verified in i1/i2 (override rows 658, 665).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish whether the formula is the right measure" · r2: "does not establish counts against any other base"

The same numstat command, with `main <commit>`, printed `299` for 7d78e6d0 and `337` for f782d9ee.

**Evidence:** `git diff --numstat main <commit> -- ':(top)' ':(top,exclude)docs/'`, cwd the worktree; `scripts/build-loop.sh`, `test/scripts/build-loop-merge.bats` (r1's citation for the same count)

---

## Claim 41: 7d78e6d0 Notes "identity comes from git var with the caller's own global config (every other call reads none) ... A review-policy brief is refused until U3a3's --approved."

**Location:** commit 7d78e6d0 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both statements at HEAD. It does not establish the rest of that message's mutant tally (settled, row 658).
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

See Claim 12 (`:1018`, sole use). The review refusal is `refuse $a: the brief's policy is review; --merge lands only a self-merge brief` (`:1142`), asserted at `build-loop-merge.bats:85-86`.

**Evidence:** `scripts/build-loop.sh:1018`, `scripts/build-loop.sh:1142`; `$L3/build-loop-merge.log`

---

## Claim 42: f782d9ee "C4 the self-merge refusal moved to the merge arm; C10 merged BRIEF TIP TREE NEW; C12 dot-named admin dirs scanned, W must be its own top level"

**Location:** commit f782d9ee message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these three items at HEAD. It does not re-run i2's mutants for f782d9ee's other guards.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

Each item holds at HEAD:
- C4: the policy test is at `:1142`, and land has none.
- C10: Claim 2.
- C12: Claims 20 and 23.

**Evidence:** `scripts/build-loop.sh:1059`, `scripts/build-loop.sh:1074`, `scripts/build-loop.sh:1142-1143`

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (`scripts/build-loop.sh:229-230`): if W's admin directory (or `worktrees/`) is unsearchable, `git worktree list` exits 0 without W, and main moves by CAS under W (r2, reproduced: `merged`, W left with a staged reversal). Refuse when an entry under `worktrees/` cannot be searched, or narrow the header.
- **Claim 9** (`scripts/build-loop.sh:230-232`): rebase/bisect state under an unsearchable directory reads as absent (`-e` false) (r2), and state at a path that is a directory passes `-r` and reads as "not main" (r3); in both, a rebase of main lands (reproduced). Fix the guards or narrow "cannot be read".
- **Claim 33** (commit 6cbca87c D1): the same gap as Claim 9. It holds for a mode-000 file only.

### Stale
(none)

### Mostly Accurate
- **Claim 5** (`scripts/build-loop.sh:221-224`): when only committer.email (or author.email) is configured, git var gives the other side an empty email; it lands as `<>` with no "no identity" refusal.
- **Claim 13** (`scripts/build-loop.sh:903-909`): the repository rule does not place land's W reads (state_gate, rev-parse, symbolic-ref, status) or its real-repository worktree list, git-common-dir and git var.
- **Claim 16** (`scripts/build-loop.sh:1009-1014`): "Returns 1 when git knows none" should read "when git var fails; an empty email passes".
- **Claim 18** (`scripts/build-loop.sh:1025-1026`): "No worktree may be rebasing ..." holds for searchable state only.
- **Claim 19** (`scripts/build-loop.sh:1038-1039`): after the "not at the merge after the fast-forward" refusal, NEW can be reachable from the branch W's HEAD had moved to (probe P5).
- **Claim 22** (`scripts/build-loop.sh:1070-1071`): the state gate's own git reads run in W first.
- **Claim 31** (commit 6cbca87c B1): the gate comes after the rebase/bisect scan, not "as soon as W is known", and has Claim 22's "any git command" imprecision.
- **Claim 34** (commit 6cbca87c D2): the "NEW after a post-write refusal" fix is in land's comment, not the header.
- **Claim 37** (commit 6cbca87c): the BISECT_START readability guard's mutant (M4b) survives the suite; no test covers an unreadable BISECT_START.

### Unverifiable
(none)

## Escalations

- **E1** — `scripts/build-loop.sh:1018-1020` (merged Claims 5, 16): an email git var resolves to empty (only the other side's email key configured) lands as `<>` with no refusal. Raised by r1 ("amber inputs for the rubric"). Addressee: orchestrator (rubric amber inventory).
- **E2** — `scripts/build-loop.sh:1048`, `scripts/build-loop.sh:1059-1067` (merged Claims 6, 8, 9, 18, 33): the unsearchable-directory fail-open — an unsearchable `worktrees/` or W admin directory drops W from `git worktree list` (CAS under W), and an unsearchable `rebase-merge/` reads as absent. Raised by r2 ("new for this final pass and belongs to the security critic and the rubric's amber inventory ... not covered by rows 509/646 (Q-103 races) or by the i2 security listed candidate 3 (an unreadable file)"). Addressee: security-reviewer; orchestrator (rubric amber inventory).
- **E3** — `scripts/build-loop.sh:1062-1067` (merged Claims 9, 33): rebase/bisect state at a path that is a directory passes `-r` and reads as "not the default branch", so the run merges. Raised by r3 ("goes to the amber inventory ... a non-racing fail-open on planted state, though git could not use that state either, so the practical impact is low"). Addressee: orchestrator (rubric amber inventory).
- **E4** — `scripts/build-loop.sh:1066`, `test/scripts/build-loop-merge.bats:137` (merged Claim 37; also noted in r3's Claim 21b, merged Claim 33): no test makes BISECT_START unreadable, so the bisect readability guard's mutant M4b survives. Raised by r1 (amber input for the rubric) and r3 ("a test-strategy input"). Addressee: test-strategy; orchestrator (rubric amber inventory).

## Verdict stability

- Total clusters: 42
- Clusters where all reporting replicates agreed: 33 (includes two single-replicate clusters, Claims 41 and 42, and three two-replicate clusters, Claims 6, 34, 35)
- Clusters where verdicts disagreed: 9

| Claim | r1 | r2 | r3 | Merged |
|---|---|---|---|---|
| 5 | Mostly accurate | Verified (compound) | Verified (compound) | Mostly accurate |
| 8 | Verified (compound) | Incorrect | Verified (compound) | Incorrect |
| 9 | Verified (compound) | Incorrect | Incorrect | Incorrect |
| 13 | Verified | Verified | Mostly accurate | Mostly accurate |
| 16 | Mostly accurate | Verified | Verified | Mostly accurate |
| 18 | Verified (compound) | Mostly accurate | Verified (compound) | Mostly accurate |
| 19 | Mostly accurate | Verified (compound) | Verified (compound) | Mostly accurate |
| 31 | Mostly accurate | Verified | Mostly accurate | Mostly accurate |
| 33 | Verified (compound) | Incorrect | Incorrect | Incorrect |

- Agreement rate: 33/42 = 78.6%
