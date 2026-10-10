Commit: 6cbca87c

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u3a2, branch feat/build-loop-u3a2)
**Scope:** `git diff main...HEAD -- scripts test` at 6cbca87c (scripts/build-loop.sh, test/scripts/build-loop-merge.bats), plus the branch's commit messages (`git log main..HEAD`). Final confirming pass, replicate r3 (k=3).
**Checked:** 2026-10-10
**Total claims checked:** 32
**Summary:** 25 verified, 5 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Execution logs are kept outside the worktree, because the review rules allow only this report file in it. `$L` = `/tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-i3-fc-3/logs`. Probe and runner scripts are in its parent directory: `run-suites.sh`, `mutants.py`, `run-mut.sh`, `run-probe.sh`, and `probe/test/scripts/probe.bats`. Each run used its own `mktemp -d /tmp/u3a2i3-fc3-XXXX` TMPDIR under `timeout`, ran serially, and removed that directory afterwards. Mutants were applied to scratch copies (`$S/mut/<name>/`) only. Times are 2026-10-10 UTC: probes 21:17:54-21:17:55, mutants 21:18:11-21:19:17, suites 21:19:17-21:21:13.

`docs/reviews/hallucination-patterns.md` was read. No claim resembles a logged pattern, and neither Incorrect verdict is a fabricated symbol.

---

## Claim 1: usage "scripts/build-loop.sh --merge BRIEF --expect SHA" and the --merge usage refusal

**Location:** `scripts/build-loop.sh:9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the usage line, the usage() text and the three wrong-count shapes. It does not establish anything about the --expect value errors, which keep the shared messages (settled, override row 665).

`usage() { echo "$1 (usage: ... | --merge BRIEF --expect SHA)" >&2; exit 1; }` (`scripts/build-loop.sh:277`) and `[[ "$MODE" == check || ( -n "$EXPECT" && ${#ARGS[@]} -eq 1 ) ]] || usage "--merge takes one brief path and --expect SHA"` (`:292`). Test 3 runs `"$B"`, `"--expect $T"` and `"$B $B --expect $T"` and asserts exit 1 with that stderr prefix (`test/scripts/build-loop-merge.bats:87-90`). That test passes in the suite run.

**Evidence:** `scripts/build-loop.sh:9`, `:277-295`; `test/scripts/build-loop-merge.bats:87-90`; `$L/build-loop-merge.log` (`TMPDIR=$(mktemp -d /tmp/u3a2i3-fc3-XXXX) timeout 1500 bats test/scripts/build-loop-merge.bats`, cwd the worktree, exit 0, 21:19:17Z)

---

## Claim 2: "merged BRIEF TIP TREE NEW ... a commit of TREE whose parents are main's commit and TIP, with the message "Merge branch 'BRANCH' (build-loop self-merge)" and the trailer "Build-loop-gate: STEM""

**Location:** `scripts/build-loop.sh:214-219`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merged line's field order, NEW's parents, tree, message and trailer. It does not establish the message for an authority other than self-merge (U3a3).

The merge arm prints `v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"` (`:1143`). land writes `printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "$1" "${VERDICT[stem]}"` and then runs `commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}"` (`:1095-1096`). The stem is `stem="${a##*/}"; stem="${stem%.md}"` (`:985`). Test 1 asserts the line, the parents, the tree and the whole message (`build-loop-merge.bats:47-52`) and passes.

**Evidence:** `scripts/build-loop.sh:985`, `:1095-1097`, `:1143`; `test/scripts/build-loop-merge.bats:43-57`; `$L/build-loop-merge.log`

---

## Claim 3: "its reflog entry reads "build-loop: self-merge of STEM" (git adds ": Fast-forward" when W moves it)"

**Location:** `scripts/build-loop.sh:219-221`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch's reflog entry for both moves. It does not establish W's HEAD reflog text, which the header does not quote.

`msg="build-loop: $1 of ${VERDICT[stem]}"` (`:1044`) is passed both as `git update-ref -m "$msg"` (`:1102`) and as `GIT_REFLOG_ACTION="$msg" git -C "$w" ... merge --ff-only` (`:1108`). The tests assert `build-loop: self-merge of 2026-10-01-x` after the CAS (`build-loop-merge.bats:54`) and `build-loop: self-merge of 2026-10-01-x: Fast-forward` after W's move (`:102`). Both pass.

**Evidence:** `scripts/build-loop.sh:1044`, `:1102`, `:1108`; `test/scripts/build-loop-merge.bats:54`, `:102`; `$L/build-loop-merge.log`

---

## Claim 4: "Author and committer names and emails from GIT_AUTHOR_NAME/EMAIL and GIT_COMMITTER_NAME/EMAIL, or else git config (the caller's global file included, the system file not); EMAIL or a guess from the host refuses instead."

**Location:** `scripts/build-loop.sh:221-224`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the env variables, the caller's GIT_CONFIG_GLOBAL file, the global files git reads when that variable is unset (`~/.gitconfig` and `$XDG_CONFIG_HOME/git/config` or `~/.config/git/config`), the EMAIL refusal and per-field mixing. It does not establish that the system file is skipped by execution (static only: `GIT_CONFIG_NOSYSTEM=1` is exported at `:326` and `env` in merge_ident does not unset it). "git config" also includes the repository's own config, which the header does not single out.

merge_ident runs `env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var "GIT_${w}_IDENT"` (`:1018`). Probe results (`$L/probe.log`):
- With names set and only EMAIL for the email, plain `git var` returns `t <e@example.invalid>`.
- With `user.useConfigOnly=true` it exits 128 with `fatal: no email was given and auto-detection is disabled`.
- With GIT_CONFIG_GLOBAL unset and only an XDG file, it returns `xdg <x@example.invalid>`. A full `--merge` run then committed as `xdg x@example.invalid xdg x@example.invalid`.
- An env name with a config email gives `t <c@example.invalid>`.

Test 3 covers the no-identity, EMAIL-only and GIT_CONFIG_GLOBAL cases (`build-loop-merge.bats:73-81`) and passes.

**Evidence:** `scripts/build-loop.sh:323`, `:326`, `:1015-1021`; `test/scripts/build-loop-merge.bats:71-91`; `$L/probe.log` (run-probe.sh, cwd `/tmp/u3a2i3-fc3-*`, exit 0, 21:17:54Z); `$L/build-loop-merge.log`

---

## Claim 5a: the refusal list ("or refuse BRIEF: WHY ... when: ...") names every refusal land and the merge arm make, and each listed refusal is made

**Location:** `scripts/build-loop.sh:227-246`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one-to-one mapping between the header's list and every `MERGE_WHY=` in land plus the merge arm's policy refusal. It does not establish the readability atom, which is split out as 5b.

Every MERGE_WHY assignment in land (`:1046-1112`) maps to a header item (paraphrased — no quote available because the mapping spans 18 assignments; each is quoted in the land source):
- identity
- worktrees not listed; git directory not found
- checked out in two worktrees
- rebasing (update-refs included); bisecting
- W missing; W fails the state gate
- W not its own top level / not on main at MAIN_SHA
- W mid an operation; tracked change or status failed/warned
- untracked or ignored file at an added path; file or link where a directory is added
- merge commit not written
- state changed after the check
- branch moved or could not be updated
- fast-forward failed; branch not at the merge after it

The merge arm adds `refuse $a: the brief's policy is review; --merge lands only a self-merge brief` (`:1142`). The other direction also holds: every header item has a matching assignment. The path lines follow the refusal: `{ echo "$v"; tail -n +2 "$GATE_TMP/line"; }` (`:1144`). A non-ok check_line verdict prints unchanged: `if [[ -z "${VERDICT[tree]-}" ]]; then cat "$GATE_TMP/line"; exit 2; fi` (`:1141`).

**Evidence:** `scripts/build-loop.sh:227-246`, `:1043-1113`, `:1134-1146`

---

## Claim 5b: "... bisecting from it, or that state cannot be read" (unreadable rebase or bisect state refuses)

**Location:** `scripts/build-loop.sh:231-232`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rebase-merge/head-name, rebase-merge/update-refs and BISECT_START existing as a directory under a worktree's git dir. It does not establish the permission-denied case, which does refuse (test 5, mutant M4a), and it does not establish other read errors (EIO) by execution.
**Severity:** Low (planted state that git itself could not use, not an honest path). **Legibility-target:** for-author.

The guards test only `-r`:

```bash
# scripts/build-loop.sh:1062-1067
for q in rebase-merge/head-name rebase-apply/head-name rebase-merge/update-refs; do
  [[ ! -e "$d/$q" ]] || { [[ -r "$d/$q" ]] && ! grep -qxF "refs/heads/$MAIN" "$d/$q"; } \
    || { MERGE_WHY="a worktree is rebasing the default branch, or its rebase state cannot be read"; return 1; }
done
[[ ! -e "$d/BISECT_START" ]] || { [[ -r "$d/BISECT_START" ]] && [[ "$(<"$d/BISECT_START")" != "$MAIN" ]]; } \
  || { MERGE_WHY="a worktree is bisecting from the default branch, or its bisect state cannot be read"; return 1; }
```

A directory passes `-r`. grep then fails with exit 2, so `! grep` is true, and `$(<dir)` yields an empty string, which is not `main`. Either way the state that cannot be read counts as "not rebasing" or "not bisecting". In the probe, each of the three directory shapes gave `status 0`, `merged ...` and moved main. The two grep cases also printed `grep: ...: Is a directory` on stderr beside the merged line (`$L/probe.log`). What the code does: it refuses permission-unreadable state only. A read failure of a readable path counts as "not the default branch".

**Evidence:** `scripts/build-loop.sh:1059-1068`; `$L/probe.log` (test 1, `== head-name is a directory: status 0`, `== update-refs is a directory: status 0`, `== BISECT_START is a directory: status 0`)

---

## Claim 6: "Writes nothing but ... --merge's commit, the branch it moves and that branch's reflog (and in W: its files, index, HEAD reflog and ORIG_HEAD), and its own temporary directory"

**Location:** `scripts/build-loop.sh:249-254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the write commands in land: commit-tree into the real store, update-ref, and merge --ff-only in W with gc.auto=0, maintenance.auto=false and hooks off through harden. It does not establish every file git may touch inside .git during a fast-forward, for example lock files.

The writers are `gate_git commit-tree` with `GIT_OBJECT_DIRECTORY="$v"`, the real objects directory (`:1096`, `:629`), `git update-ref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA"` (`:1102`) and `git -C "$w" -c gc.auto=0 -c maintenance.auto=false -c "branch.$MAIN.mergeOptions=" merge --ff-only -q "$NEW"` (`:1108`). harden sets `core.hooksPath=/dev/null` for every git call (`:315`). W's `git status` runs with `GIT_OPTIONAL_LOCKS=0` (`:326`), so it does not write the index. The pack-count test shows no repack after the fast-forward (`build-loop-merge.bats:105-108`, mutant M2).

**Evidence:** `scripts/build-loop.sh:249-254`, `:315`, `:326`, `:629`, `:1095-1110`; `$L/mut-M2-maintenance.log`

---

## Claim 7: "Exit: 0 ... for --merge merged; 2 any other --check or --merge verdict line, or the state gate not ok ... 1 ... a failed mktemp (--check, --merge; no line printed)"

**Location:** `scripts/build-loop.sh:256-262`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0 on merged, exit 2 on land, policy and check_line refusals, and exit 1 on usage. It does not establish the mktemp failure by execution (static: `GATE_TMP="$(mktemp -d)"` under `set -e`, `:912`).

The arm ends `[[ "$v" == merged* ]] || exit 2` (`:1145`) and `cat "$GATE_TMP/line"; exit 2` for a non-ok verdict (`:1141`). gate_start exits 2 on its refusals (`:911-915`). The suite asserts 0 (`build-loop-merge.bats:47`), 2 (`:39`, `:56`) and 1 (`:89`).

**Evidence:** `scripts/build-loop.sh:910-917`, `:1134-1146`; `test/scripts/build-loop-merge.bats:39`, `:47`, `:56`, `:89`; `$L/build-loop-merge.log`

---

## Claim 8: "The caller's global config, for merge_ident alone ...; every other call reads none."

**Location:** `scripts/build-loop.sh:321-323`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every use of CALLER_GLOBAL and the process-wide `GIT_CONFIG_GLOBAL=/dev/null` export. It does not establish what the parenthetical "all a loop that writes it could change there" says about threats, which is rationale.

`export ... GIT_CONFIG_GLOBAL=/dev/null ...` (`:326`) runs after CALLER_GLOBAL captures the caller's value (`:323`). `rg CALLER_GLOBAL` finds a single use: `env "${CALLER_GLOBAL[@]}" git ... var` (`:1018`). scrub_reexec runs before both lines (`:275`), so the re-executed child sees the caller's environment.

**Evidence:** `scripts/build-loop.sh:275`, `:321-326`, `:1018`; `scripts/lib/dev-cycle-read.sh:150-155`

---

## Claim 9: gate_start's repository rule: "main's files and refs, the branch tips, the checkout and store_check's object reads are in the real repository; the merge computations ... and --merge's commit-tree run through gate_git (into the real object store). --merge moves the branch in the real repository (update-ref) or in W (merge --ff-only), and merge_ident alone reads the caller's global config."

**Location:** `scripts/build-loop.sh:903-909`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every call the rule names: commit-tree via gate_git into GIT_OBJECT_DIRECTORY, update-ref in the real repository, merge --ff-only in W, and git var as the sole reader of the caller's global config. It does not establish a placement for land's other reads, which the rule leaves out.
**Severity:** Informational. **Legibility-target:** for-author.

Each named placement holds:
- `x="$(gate_git commit-tree ...)"` (`:1096`) runs in the gate repository, with `GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")` pointing at the real objects directory (`:629`).
- `git update-ref` (`:1102`) runs in the real repository.
- `git -C "$w" ... merge --ff-only` (`:1108`) runs in W.

The rule says nothing about land's reads in W: `(cd "$w" && state_gate)` (`:1073`, `:1099`), `git -C "$w" rev-parse` and `symbolic-ref` (`:1074-1075`), the `--git-path` probes (`:1078`) and `git -C "$w" status` (`:1081`). It also does not cover the real-repository `git worktree list` (`:1048`), `git rev-parse --git-common-dir` (`:1058`) and `git var` (`:1018`). Precise version: add "land's worktree reads (state_gate, rev-parse, status) run in W; worktree list and git var in the real repository".

**Evidence:** `scripts/build-loop.sh:612-639`, `:903-909`, `:1018`, `:1048`, `:1058`, `:1073-1081`, `:1096-1108`

---

## Claim 10: "The verdict as values (row 512), for --merge: VERDICT holds tip, tree, policy, branch and stem, and CHANGED each changed path's status letter, only after an ok line (both empty otherwise)."

**Location:** `scripts/build-loop.sh:930-934`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return path of check_line (signature `:935` to `:1007`). It does not establish behavior when check_line is left by an exit (need_root), where nothing reads the values.

check_line starts with `VERDICT=(); CHANGED=()` (`:939`), before any return. Only verdict_ok fills them: `VERDICT=([tip]="$sha" [tree]="$tree" [policy]="$pol" [branch]="$br" [stem]="$stem")` and `CHANGED[${ps[$i]}]="${ss[$i]}"` (`:992-993`), and then echoes the ok line (`:994`). It is called only on the two ok branches (`:996`, `:1005`). Every other `return` (`:942-984`, `:996` with `co`, `:998`) and the K-of-N refusal (`:1005`) leave both empty. Mutant M8 of i2 (CHANGED filled in the loop) is settled (override row 664).

**Evidence:** `scripts/build-loop.sh:935-1007`

---

## Claim 11: "Reads check_line's locals (bash scope is dynamic); called only here."

**Location:** `scripts/build-loop.sh:989`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers verdict_ok's reads of `sha tree pol br stem ps ss a` and its two callers. It does not establish anything beyond check_line's own frame, where the function name stays defined.

All the variables verdict_ok reads are declared `local` in check_line (`:938`). `stem` is assigned there too (`:985`). `local i` (`:991`) shadows check_line's `i`, and check_line does not read `i` after either call. `rg verdict_ok` finds the definition and the two calls at `:996` and `:1005` (paraphrased — no quote available because the claim covers absence of other callers, from grep results).

**Evidence:** `scripts/build-loop.sh:938`, `:985-996`, `:1005`

---

## Claim 12: merge_ident: "as git var resolves them: the environment's GIT_AUTHOR_NAME/EMAIL and GIT_COMMITTER_NAME/EMAIL, then git config with the caller's global file (no system file: GIT_CONFIG_NOSYSTEM stays set), each name and email on its own. user.useConfigOnly: without them git would take EMAIL or guess ...; it refuses instead. Exported ... because commit-tree runs in the gate repository, which has no config. Returns 1 when git knows none."

**Location:** `scripts/build-loop.sh:1009-1014`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers source order, per-field mixing, the EMAIL refusal, the export into the gate repository's commit-tree and the return-1 path. It does not establish the passwd/domain guess by execution (this host's fixture always has a name), and return 1 also covers a git var line the regex rejects, which the comment does not mention.

The probe confirms the EMAIL take and its refusal, and the per-field mix (`t <c@example.invalid>`) (Claim 4, `$L/probe.log`). The gate repository's config holds only `[core]` and `[extensions]` (`:628`). The export is `export "GIT_${w}_NAME=${BASH_REMATCH[1]}" "GIT_${w}_EMAIL=${BASH_REMATCH[2]}"` (`:1020`), and GATE_ENV does not unset these variables (`env -u` only for `git rev-parse --local-env-vars`, `:625`). Test 1 asserts the env identity on NEW and test 3 the global-file identity. Both pass.

**Evidence:** `scripts/build-loop.sh:621-629`, `:1015-1021`; `test/scripts/build-loop-merge.bats:53`, `:79-81`; `$L/probe.log`; `$L/build-loop-merge.log`

---

## Claim 13: land's comment: "decide, then write, then move ... compare-and-swap (update-ref from MAIN_SHA ...) ... W must be its own top level ..., on it at MAIN_SHA, with no tracked change, no merge, cherry-pick, revert, rebase, bisect or sequence in progress, nothing at a path the merge adds ... Then the merge commit NEW ... is written ..., the state gate (here and in W) and default_gate run again (row 494), and the branch moves ... Sets NEW, or MERGE_WHY and returns 1 (a refusal after the write leaves NEW set and unreachable in the store). Residuals (Q-103) ..."

**Location:** `scripts/build-loop.sh:1023-1041`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of land's statements, the CAS, every W condition, the re-gate, the post-ff check and the NEW/MERGE_WHY contract. It does not establish anything about the named residual races.

Decisions come first (`:1046-1094`). Then the write: `printf ... && x="$(gate_git commit-tree ...)" && [[ "$x" =~ ... ]]` and `NEW="$x"` (`:1095-1098`). Then the re-gate: `{ state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; }` (`:1099`). Then the move: `git update-ref ... "$NEW" "$MAIN_SHA"` (`:1102`) or `merge --ff-only` followed by `[[ "$(git rev-parse --verify -q "refs/heads/$MAIN")" == "$NEW" ]]` (`:1108-1110`). NEW stays set on any refusal after `:1098`. Tests 2, 4, 5 and 6 exercise the CAS loss, the re-gate, the W conditions and the ignored-file case (`build-loop-merge.bats:59-69`, `:117-161`), and all pass.

**Evidence:** `scripts/build-loop.sh:1023-1113`; `test/scripts/build-loop-merge.bats:59-161`; `$L/build-loop-merge.log`

---

## Claim 14: "Each worktree's own git dir, read as files: the common one and those under worktrees/ (dot names too). worktree list shows a rebasing worktree as detached, so only its rebase state names the branch." (globs `"$common"/worktrees/* .[!.]* ..?*`)

**Location:** `scripts/build-loop.sh:1055-1059`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the glob set (every entry of worktrees/ but `.` and `..`, with unmatched patterns skipped by `[[ -d "$d" ]] || continue`) and the dot-named directory test. It does not establish that git can register a dot-named worktree admin directory.

`*` matches non-dot names, `.[!.]*` matches dot names whose second character is not `.`, and `..?*` matches names that start with `..` and are longer than two characters. Together they cover every name but `.` and `..` (paraphrased — no quote available because this is bash glob semantics, not code). Test 5 plants `$R/.git/worktrees/.x/rebase-merge/head-name` and asserts the refusal (`build-loop-merge.bats:139-140`), which passes.

**Evidence:** `scripts/build-loop.sh:1055-1060`; `test/scripts/build-loop-merge.bats:139-140`; `$L/build-loop-merge.log`

---

## Claim 15: "A rebase of it, or one that will move it (--update-refs lists it)."

**Location:** `scripts/build-loop.sh:1061`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers head-name in rebase-merge and rebase-apply, and an update-refs file naming main. It does not establish git's own update-refs format beyond the test fixture's three-line record.

`for q in rebase-merge/head-name rebase-apply/head-name rebase-merge/update-refs` with `grep -qxF "refs/heads/$MAIN"` (`:1062-1063`). Test 5 plants `printf 'refs/heads/main\n%s\n%s\n'` in update-refs next to a feat/z head-name (`build-loop-merge.bats:135-136`). Mutant M3, which drops update-refs, fails test 5. A probe of rebase-apply/head-name in the common git dir refuses (`$L/probe.log`).

**Evidence:** `scripts/build-loop.sh:1061-1065`; `test/scripts/build-loop-merge.bats:134-136`; `$L/mut-M3-update-refs.log` (exit 1, not ok 5); `$L/probe.log`

---

## Claim 16: "W's own config.worktree before any git command runs there (git status would run a filter it names); the startup gate read this checkout's."

**Location:** `scripts/build-loop.sh:1070-1071`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order: the gate at `:1073` precedes every other git call land makes with `-C "$w"` or `cd "$w"`, and the startup state_gate reads the invoking checkout's config.worktree. It does not establish the literal "before any git command": the gate itself runs git in W.
**Severity:** Informational. **Legibility-target:** for-author.

`(cd "$w" && state_gate)` (`:1073`) runs state_gate's own git commands in W: `git rev-parse --path-format=absolute --git-path "$f"`, `git config --file "$p" --no-includes ...`, `git for-each-ref` and `git symbolic-ref` (`:341-366`). None of these reads the work tree or index or runs a filter. So the gate precedes every git command that could run a filter W's config.worktree names, not every git command. In test 6 the planted clean filter never runs (`[ ! -e "$BATS_TEST_TMPDIR/ran" ]`, `build-loop-merge.bats:155-158`). Mutant M1, which drops the gate, fails test 6. Precise version: "before any git command reads W's work tree or index".

**Evidence:** `scripts/build-loop.sh:341-366`, `:1070-1073`; `test/scripts/build-loop-merge.bats:154-158`; `$L/mut-M1-early-gate.log` (exit 1, not ok 6)

---

## Claim 17: the -ef test's message "$in is missing, not its own top level, or not on it at $MAIN_SHA"

**Location:** `scripts/build-loop.sh:1074-1076`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three conditions joined by `&&` and their disjunctive message. It does not establish that the "missing" disjunct is reachable outside a race: `[[ -d "$w" ]] || { MERGE_WHY="$in is missing"; ...}` (`:1072`) catches a missing W first.

`[[ "$(git -C "$w" rev-parse --show-toplevel)" -ef "$w" && "$(git -C "$w" symbolic-ref -q HEAD)" == "refs/heads/$MAIN" && "$(git -C "$w" rev-parse --verify -q 'HEAD^{commit}')" == "$MAIN_SHA" ]]` (`:1074-1075`). Test 6 sets core.worktree elsewhere and gets this exact message (`build-loop-merge.bats:152-153`). A missing W gets the bare `is missing` message (`:159-160`).

**Evidence:** `scripts/build-loop.sh:1072-1076`; `test/scripts/build-loop-merge.bats:152-153`, `:159-160`; `$L/build-loop-merge.log`

---

## Claim 18: "The branch's own mergeOptions (--squash would stage the merge in W and leave the branch) cleared; no gc or maintenance task (a repack) started on the store store_check read; the reflog names the gate."

**Location:** `scripts/build-loop.sh:1105-1107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three `-c` overrides and GIT_REFLOG_ACTION on the fast-forward. It does not establish maintenance tasks other than loose-objects by execution.

`GIT_REFLOG_ACTION="$msg" git -C "$w" -c gc.auto=0 -c maintenance.auto=false -c "branch.$MAIN.mergeOptions=" merge --ff-only -q "$NEW"` (`:1108`). Each override has a mutant:
- Mutant M2 drops maintenance.auto=false. The pack count changes and test 4 fails at line 108.
- Mutant M6 drops the mergeOptions override. Test 4 fails.
- The reflog text is asserted at `build-loop-merge.bats:102`.

**Evidence:** `scripts/build-loop.sh:1105-1110`; `$L/mut-M2-maintenance.log`, `$L/mut-M6-mergeoptions.log` (both exit 1, not ok 4); `$L/build-loop-merge.log`

---

## Claim 19: "The verdict line is check_line's first (the path lines follow it); the authority (here only self-merge; U3a3 adds --approved), then land's result, replace it."

**Location:** `scripts/build-loop.sh:1138-1140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arm's replacement of line 1 and the order of the policy test before land. It does not establish U3a3's future behavior.

check_line echoes its verdict before `printf '%s\n' "${rows[@]}"` (`:1005-1006`). The arm prints `{ echo "$v"; tail -n +2 "$GATE_TMP/line"; }` (`:1144`), and `v` comes from the policy test, then `land self-merge` (`:1142-1143`).

**Evidence:** `scripts/build-loop.sh:1005-1006`, `:1134-1146`

---

## Claim 20: 6cbca87c B1 "W's own config.worktree is state-gated as soon as W is known, before any git command runs there (git status ran a clean filter it named; pre-existing since 7d78e6d0)."

**Location:** commit 6cbca87c message
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gate's position and the pre-existence claim. It does not establish the literal "any git command": same imprecision as Claim 16.
**Severity:** Informational (immutable message). **Legibility-target:** for-orchestrator-synthesis.

At 7d78e6d0, `git -C "$w" status` (`7d78e6d0:scripts/build-loop.sh:1051`) ran before the only W state_gate (`:1065`, after the write), so "pre-existing since 7d78e6d0" holds. "As soon as W is known" is loose: the rebase/bisect scan (`:1059-1068`) runs between finding W and the gate. That scan runs no git, though. The gate's own git commands run in W (Claim 16).

**Evidence:** `git show 7d78e6d0:scripts/build-loop.sh` lines 1051, 1065; `scripts/build-loop.sh:1047-1073`

---

## Claim 21a: 6cbca87c D1 "a paused rebase --update-refs that will move main refuses"

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers update-refs listing main in any worktree's rebase-merge. It does not establish git's real `rebase --update-refs` state files beyond the fixture.

See Claim 15 (`scripts/build-loop.sh:1062-1063`, test 5, mutant M3).

**Evidence:** `scripts/build-loop.sh:1062-1064`; `$L/mut-M3-update-refs.log`

---

## Claim 21b: 6cbca87c D1 "and unreadable rebase or bisect state refuses"

**Location:** commit 6cbca87c message
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers state at those paths that cannot be read but passes `-r`. It does not establish the permission-denied case, which refuses.
**Severity:** Low. **Legibility-target:** for-author.

As in Claim 5b, a head-name, update-refs or BISECT_START that is a directory merges. Only `-r`-false state refuses: `{ [[ -r "$d/$q" ]] && ! grep -qxF ...; }` (`scripts/build-loop.sh:1063`). The bisect half's `-r` guard is not tested either (Claim 25, mutant M4b).

**Evidence:** `scripts/build-loop.sh:1062-1067`; `$L/probe.log`; `$L/mut-M4b-readable-bisect.log`

---

## Claim 22: 6cbca87c D2 "header: reflog suffix, identity variables, path lines, NEW after a post-write refusal"

**Location:** commit 6cbca87c message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff f782d9ee..6cbca87c of the header and of land's comment. It does not establish anything beyond those two blocks.
**Severity:** Informational. **Legibility-target:** for-orchestrator-synthesis.

Three of the four items are header changes (`git diff f782d9ee 6cbca87c`, `scripts/build-loop.sh:220-227`):
- `(git adds ": Fast-forward" when W moves it)`
- `GIT_AUTHOR_NAME/EMAIL and GIT_COMMITTER_NAME/EMAIL`
- `with the ok line's path lines following`

The fourth, `leaves NEW set and unreachable in the store`, is in land's comment (`:1039`), not the header. The header says nothing about NEW after a refusal (paraphrased — no quote available because the claim covers absence: `sed -n 1,262p | grep NEW` finds only `:214-215`).

**Evidence:** `scripts/build-loop.sh:214-227`, `:1038-1039`; `git diff f782d9ee 6cbca87c -- scripts/build-loop.sh`

---

## Claim 23: 6cbca87c D3 "land takes the authority it records; verdict_ok's local i."

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `$1` reaching the reflog message and the commit message, and `local i`. It does not establish a test that tells `$1` from a hard-coded "self-merge": mutant M5b, which hard-codes it, survives, as it must while only one authority exists.

`msg="build-loop: $1 of ..."` (`:1044`) and `"(build-loop %s)" ... "$1"` (`:1095`), called as `land self-merge` (`:1143`). Mutant M5a calls `land other` and fails tests 1 and 4. `local i` is at `:991`.

**Evidence:** `scripts/build-loop.sh:991`, `:1044`, `:1095`, `:1143`; `$L/mut-M5a-authority-arm.log` (exit 1), `$L/mut-M5b-authority-literal.log` (exit 0)

---

## Claim 24: 6cbca87c D4 "a pack-count test pins maintenance.auto=false."

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loose-objects maintenance task the test enables. It does not establish that other tasks would also be caught.

`build-loop-merge.bats:105-108` enables `maintenance.auto` and `maintenance.loose-objects.auto 1`, then compares the pack file count. Mutant M2 fails exactly there (`line 108`).

**Evidence:** `test/scripts/build-loop-merge.bats:103-108`; `$L/mut-M2-maintenance.log`

---

## Claim 25: 6cbca87c "Each new guard's mutant fails the suite (early gate, maintenance, update-refs, readable state, authority)."

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mutants of every guard 6cbca87c adds, run against the merge suite on scratch copies, with control M0 at 6 ok. It does not establish the results of other suites under the mutants.
**Severity:** Low. **Legibility-target:** for-author (test-strategy input).

Caught (exit 1):
- M1 early gate
- M2 maintenance
- M3 update-refs
- M4a rebase `-r`
- M5a authority
- M6 mergeOptions, an i1 guard re-checked

Survivor: **M4b**, which drops `[[ -r "$d/BISECT_START" ]] &&` (`:1066`) and still gets 6 ok, exit 0. D1 adds this guard ("unreadable rebase or bisect state refuses"), but test 5 makes only head-name unreadable (`chmod 000 "$a/rebase-merge/head-name"`, `build-loop-merge.bats:137`). Precise version: "each new guard's mutant fails the suite but the bisect-state readability guard's". The five named mutants hold if "readable state" means the rebase half.

**Evidence:** `scripts/build-loop.sh:1066`; `test/scripts/build-loop-merge.bats:137-142`; `$L/mut-M0-control.log` … `$L/mut-M6-mergeoptions.log` (`run-mut.sh`: `TMPDIR=$T timeout 600 bats $S/mut/<name>/test/scripts/build-loop-merge.bats`, cwd `/tmp/u3a2i3-fc3-*`, 21:18:11Z-21:19:17Z); `mutants.py`

---

## Claim 26: "Suites 6/145/20/79/2/2." (6cbca87c; also in f782d9ee and 7d78e6d0)

**Location:** commit 6cbca87c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers pass counts at 6cbca87c. It does not establish which 2-test suites the last two numbers name (fixture-git-env, utility-smoke and fixture-hermeticity each have 2 and all pass), or the counts at the earlier commits, which were not re-run.

At 6cbca87c, serial runs with no `not ok` gave:
- merge: 6 ok, exit 0
- check: 145 ok, exit 0
- read: 20 ok, exit 0
- dev-cycle: 79 ok, exit 0
- fixture-git-env, utility-smoke, fixture-hermeticity: 2 ok each

(paraphrased — no quote available because the counts are tallies of `^ok` lines in the logs).

**Evidence:** `$L/build-loop-merge.log`, `$L/build-loop-check.log`, `$L/build-loop-read.log`, `$L/dev-cycle.log`, `$L/fixture-git-env.log`, `$L/utility-smoke.log`, `$L/fixture-hermeticity.log`; `run-suites.sh` (cwd the worktree, ends 21:21:13Z)

---

## Claim 27: "364 code lines." (6cbca87c)

**Location:** commit 6cbca87c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief's numstat command against main (6666a5ce, equal to the merge base). It does not establish anything about the count with docs included.

`git diff --numstat main -- ':(top)' ':(top,exclude)docs/' | awk ...` printed `364` (190+13 in scripts/build-loop.sh, 161+0 in the bats file; in-session, exit 0).

**Evidence:** `git diff --numstat main -- ':(top)' ':(top,exclude)docs/'`, cwd the worktree

---

## Claim 28: "299 code lines." (7d78e6d0) and "337 code lines." (f782d9ee)

**Location:** commits 7d78e6d0, f782d9ee messages
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same command with each commit as the right side. It does not establish the other claims of those messages, which are settled or verified in i1/i2 (override rows 658, 665).

The same numstat command, with `main <commit>`, printed `299` for 7d78e6d0 and `337` for f782d9ee.

**Evidence:** `git diff --numstat main <commit> -- ':(top)' ':(top,exclude)docs/'`, cwd the worktree

---

## Claim 29: 7d78e6d0 Notes "identity comes from git var with the caller's own global config (every other call reads none) ... A review-policy brief is refused until U3a3's --approved."

**Location:** commit 7d78e6d0 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both statements at HEAD. It does not establish the rest of that message's mutant tally (settled, row 658).

See Claim 8 (`:1018`, sole use). The review refusal is `refuse $a: the brief's policy is review; --merge lands only a self-merge brief` (`:1142`), asserted at `build-loop-merge.bats:85-86`.

**Evidence:** `scripts/build-loop.sh:1018`, `:1142`; `$L/build-loop-merge.log`

---

## Claim 30: f782d9ee "C4 the self-merge refusal moved to the merge arm; C10 merged BRIEF TIP TREE NEW; C12 dot-named admin dirs scanned, W must be its own top level"

**Location:** commit f782d9ee message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these three items at HEAD. It does not re-run i2's mutants for f782d9ee's other guards.

Each item holds at HEAD:
- C4: the policy test is at `:1142`, and land has none.
- C10: Claim 2.
- C12: Claims 14 and 17.

**Evidence:** `scripts/build-loop.sh:1059`, `:1074`, `:1142-1143`

---

## Claim 31: test titles of test/scripts/build-loop-merge.bats against what each test asserts

**Location:** `test/scripts/build-loop-merge.bats:43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all six titles (`:43`, `:59`, `:71`, `:93`, `:117`, `:145`). It does not establish anything about the asserts a title leaves out (test 1's identity and reflog checks, test 6's state-gate check), which are extra coverage, not claims.

What each test asserts:
- Test 1: CAS with HEAD detached, then parents, tree, message and trailer, then a second-run refusal (`:44-56`).
- Test 2: a shimmed concurrent update-ref leaves main at `o`, and a filter planted before commit-tree is refused (`:61-68`).
- Test 3: review, no identity and EMAIL-only refusals, the global-file identity, and the three usage shapes (`:73-90`).
- Test 4: a fast-forward from W itself and from `o`, the unrelated untracked file kept, and an R on feat/y left alone (`:94-114`).
- Test 5: a tracked change, an added path untracked or ignored, seven in-progress markers, and rebase/bisect of main (`:118-142`).
- Test 6: file or link at an added directory, a missing W, and W's work tree elsewhere (`:146-160`).

All six pass.

**Evidence:** `test/scripts/build-loop-merge.bats:43-161`; `$L/build-loop-merge.log`

---

## Claim 32: test comments: helper docs (`:13-41`), "commit-tree runs in the gate repository" (`:66`), "Names set but the email only in EMAIL: git would take it ...; user.useConfigOnly refuses" (`:76`), the mergeOptions/maintenance notes (`:103-104`), "A paused rebase --update-refs of another branch that will move main ...; an unreadable head-name" (`:134`), "W's own config.worktree is gated before git status runs there: its clean filter never runs" (`:154`)

**Location:** `test/scripts/build-loop-merge.bats:13-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed comment against the code it describes and the mutant that removes its guard. It does not establish the "on other hosts guess from the domain" clause by execution (static, from git's documented user.useConfigOnly).

How each comment was checked:
- The shim fires once before the first call whose arguments contain WHEN, then execs the real git (`:30-36`).
- commit-tree runs with cwd `$GATE_TMP/work` and GIT_DIR set to the gate repository (`scripts/build-loop.sh:636`), hence the explicit `--file '$R/.git/config'`.
- The EMAIL behavior was probed (Claim 4).
- The `:103-104` notes are pinned by M6/M2, `:134` by M3/M4a, and `:154` by M1.

**Evidence:** `test/scripts/build-loop-merge.bats:13-41`, `:66`, `:76`, `:103-108`, `:134-138`, `:154-158`; `scripts/build-loop.sh:634-639`; `$L/mut-M1-early-gate.log`, `$L/mut-M2-maintenance.log`, `$L/mut-M3-update-refs.log`, `$L/mut-M4a-readable-rebase.log`, `$L/mut-M6-mergeoptions.log`; `$L/probe.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`scripts/build-loop.sh:231-232`): "or that state cannot be read" refuses only `-r`-false state. A head-name, update-refs or BISECT_START that is a directory (or another read error) counts as "not main", and the run merges (probe: exit 0, main moved, grep's "Is a directory" on stderr). Fix the guards or narrow the text to "cannot be opened for reading (permissions)". Severity Low.
- **Claim 21b** (commit 6cbca87c D1): same mismatch in the commit message. Severity Low.

### Stale
(none)

### Mostly Accurate
- **Claim 9** (`scripts/build-loop.sh:903-909`): the repository rule does not place land's W reads (state_gate, rev-parse, symbolic-ref, status) or its real-repository worktree list, git-common-dir and git var.
- **Claim 16** (`scripts/build-loop.sh:1070-1071`): state_gate itself runs git in W. Say "before any git command reads W's work tree or index".
- **Claim 20** (commit 6cbca87c B1): same as 16, and the rebase/bisect scan sits between finding W and the gate.
- **Claim 22** (commit 6cbca87c D2): "NEW after a post-write refusal" changed land's comment, not the header.
- **Claim 25** (commit 6cbca87c): the BISECT_START `-r` guard's mutant (M4b) survives. Test 5 makes only head-name unreadable.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, structured per the code-fact-check skill, with a `Commit: 6cbca87c` line at the top.
- Answered: yes. All eight claim groups in the brief are verdicted (32 claims). All suites pass at 6cbca87c (6/145/20/79/2/2/2). The five named mutants of 6cbca87c are caught. Two Incorrect verdicts share one root: unreadable-but-`-r` rebase/bisect state passes.
- Out of scope: the earlier commits' suite counts and 7d78e6d0's mutant tally (settled in i1/i2; rows 658, 665), the CHANGED placement mutant (row 664), and code-quality judgments.
- Escalate: Claim 5b/21b goes to the amber inventory. It is a non-racing fail-open on planted state, though git could not use that state either, so the practical impact is low. Claim 25's untested BISECT_START readability guard is a test-strategy input. No hallucination pattern qualified: neither Incorrect verdict claims a non-existent symbol.
