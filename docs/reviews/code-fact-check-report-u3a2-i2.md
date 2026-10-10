# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3a2 (branch `feat/build-loop-u3a2`)
**Scope:** iteration-1 fix batch, `git diff 7d78e6d0..f782d9ee -- scripts test` (`scripts/build-loop.sh`, `test/scripts/build-loop-merge.bats`) plus commit f782d9ee's message; the rest of `main...HEAD` read as context only
**Commit:** f782d9ee
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-10
**Total claims checked:** 28
**Summary:** 22 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first. No claim below matches a logged pattern.

Execution logs are kept outside the worktree (the review rules allow only this report file in it). `$L` = `/tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-i2-factcheck/logs`. Every probe ran under `timeout` in its own `mktemp -d /tmp/u3a2i2-fc-XXXX` directory, which it removed afterwards. Probe scripts are next to `$L`, in the parent directory (`ident.sh`, `ff.sh`, `glob.sh`, `rebase.sh`, `usage.sh`, `run-suites.sh`, `mutants.py`, `run-mut.sh`).

Iteration-1 Must Address check: **A1** is resolved: claims 19 and 22 show the cleared mergeOptions working, and mutant M1 shows the suite catches its removal. **A2** is resolved: claims 4b and 14b show useConfigOnly refusing a guessed identity, and mutant M2 shows the suite catches its removal. The EMAIL nuance (4a) is a residual wording issue, not a fail-open. **A3** is resolved: claim 5 confirms the refusal list is complete. Claim 3 notes the reflog text is imprecise for the W case. No regressions turned up: all suites pass and the --check usage messages are unchanged.

---

## Claim 1: "After an ok line, a K of N refusal or a checkout refusal (or --merge's own refusal of an ok verdict), one line per path TREE changes against main"

**Location:** `scripts/build-loop.sh:167-169`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge arm's output on a policy or land refusal after an ok verdict. It does not establish anything about a zero-path ok verdict, which has no path lines to follow.

The merge arm swaps only the first line:

```bash
# scripts/build-loop.sh:1130-1132
    if [[ "${VERDICT[policy]}" != self-merge ]]; then v="refuse $a: the brief's policy is review; --merge lands only a self-merge brief"
    elif land; then v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"; else v="refuse $a: $MERGE_WHY"; fi
    { echo "$v"; tail -n +2 "$GATE_TMP/line"; }
```

check_line prints the verdict line first and then `printf '%s\n' "${rows[@]}"` (`scripts/build-loop.sh:1001-1002`).

**Evidence:** `scripts/build-loop.sh:1001-1002`, `scripts/build-loop.sh:1124-1134`

---

## Claim 2: "merged BRIEF TIP TREE NEW"

**Location:** `scripts/build-loop.sh:214`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the field order of the merged line. It does not establish anything about consumers that parse the old order.

`v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"` (`scripts/build-loop.sh:1131`). The tests assert `"merged $B $T $TR $n"` (`test/scripts/build-loop-merge.bats:47`, `:96`). Both tests pass. Command: `TMPDIR=$(mktemp -d /tmp/u3a2i2-fc-XXXX) timeout 1500 bats test/scripts/build-loop-merge.bats`, run in the worktree, exit 0, 2026-10-10T20:5xZ.

**Evidence:** `scripts/build-loop.sh:1131`; `test/scripts/build-loop-merge.bats:47,96`; `$L/build-loop-merge.log`

---

## Claim 3: "its reflog entry reads \"build-loop: self-merge of STEM\"" (with C2 in the commit message: "one reflog message for both moves")

**Location:** `scripts/build-loop.sh:219-220`; commit f782d9ee message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reflog text on both moves. It does not establish anything about other reflogs: in W, the HEAD reflog gets the same suffixed entry.

Both moves pass the same message, `msg="build-loop: self-merge of ${VERDICT[stem]}"` (`scripts/build-loop.sh:1044`). The no-W path uses `git update-ref -m "$msg"` (`:1089`) and writes exactly that text. The W path sets `GIT_REFLOG_ACTION="$msg"` for `merge --ff-only` (`:1096`), and git appends its own action, so the entry reads `build-loop: self-merge of STEM: Fast-forward`. The suite asserts this suffix itself:

```bash
# test/scripts/build-loop-merge.bats:102
    [ "$(git reflog -1 --format=%gs main)" = "build-loop: self-merge of 2026-10-01-x: Fast-forward" ]
```

Probe `ff.sh`, step B, printed `reflog main: build-loop: self-merge of x: Fast-forward` and the same for HEAD. Step E (update-ref) printed `build-loop: self-merge of x`. To be precise: the entry starts with "build-loop: self-merge of STEM", and the W fast-forward adds ": Fast-forward".

**Evidence:** `scripts/build-loop.sh:1044,1089,1096`; `test/scripts/build-loop-merge.bats:54,102`; `$L/ff.log` (`timeout 60 bash ff.sh`, cwd its temp dir, exit 0, 2026-10-10T20:54:29Z)

---

## Claim 4a: "Author and committer from the environment, or else git config (the caller's global file included, the system file not)"

**Location:** `scripts/build-loop.sh:220-222`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GIT_AUTHOR_*/GIT_COMMITTER_* env, local, global and system config, and EMAIL. It does not establish anything about include files or GIT_CONFIG_PARAMETERS.

The parts about config hold. The "environment" part is too broad: of the environment variables plain git reads, `EMAIL` is now refused. Probe `ident.sh` results:
- Case 5 (`GIT_AUTHOR_NAME`/`GIT_AUTHOR_EMAIL` env plus useConfigOnly) gives `n <a@x>`, rc 0.
- Case 8 (the global file) gives `g <g@x>`, and case 13 (`~/.gitconfig` with GIT_CONFIG_GLOBAL unset) passes.
- Case 9 (local config) passes.
- Case 10 (a system file with GIT_CONFIG_NOSYSTEM set) is refused, and case 11 (NOSYSTEM unset) passes.
- Case 3 (names in env, the email only in `EMAIL`, plain git) gives `n <e@x>` rc 0, but case 4 (the same with `-c user.useConfigOnly=true`) fails with `fatal: no email was given and auto-detection is disabled`. Case 12 (a config name with `EMAIL`) is refused too.

The test comment at `test/scripts/build-loop-merge.bats:76` says this outright. Precise version: "from GIT_AUTHOR_*/GIT_COMMITTER_* or else user.name/user.email in git config (EMAIL is not read)". NOSYSTEM comes from `export ... GIT_CONFIG_NOSYSTEM=1` (`scripts/build-loop.sh:323`), and merge_ident's `env "${CALLER_GLOBAL[@]}"` (`:1014`) changes only GIT_CONFIG_GLOBAL (`:320`).

**Evidence:** `scripts/build-loop.sh:320,323,1014`; `$L/ident.log` (`timeout 60 bash ident.sh`, cwd its temp dir, exit 0, 2026-10-10T20:54:07Z)

---

## Claim 4b: "git guessing one from the host refuses instead" (A2: "git var with user.useConfigOnly (it guessed an identity from the domain)")

**Location:** `scripts/build-loop.sh:222-223`; commit f782d9ee message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the email guess and the passwd-name guess under git 2.39.5. It does not establish behaviour on hosts whose passwd or domain would have produced a guess. The disabling is shown by git's own messages, not by a host with a domain.

`git -c user.useConfigOnly=true var GIT_AUTHOR_IDENT` with nothing set fails with `no email was given and auto-detection is disabled` (case 2). With only the email set (name from passwd) it fails with `no name was given and auto-detection is disabled` (case 6). Both messages come from the useConfigOnly branch, before any guess. merge_ident returns 1 on a non-zero `git var` (`scripts/build-loop.sh:1014`), and land maps that to `MERGE_WHY="git knows no author or committer identity ..."` (`:1046`). Mutant M2, which drops `-c user.useConfigOnly=true`, fails test 3 at line 78, the EMAIL case.

**Evidence:** `scripts/build-loop.sh:1012-1017,1046`; `$L/ident.log`; `$L/mut-M2-useConfigOnly.log`

---

## Claim 5: "or refuse BRIEF: WHY, with the path lines following as after a --check refusal, when: [list]" (A3: "header lists every refusal land makes")

**Location:** `scripts/build-loop.sh:226-241`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a two-way map between the header list and every MERGE_WHY assignment in land plus the merge arm's policy refusal. It does not establish that check_line's own refusals are listed, since the header defers to them ("print as they are").

Mapping each MERGE_WHY in land (`scripts/build-loop.sh:1042-1100`, read in full) to the header:
- policy review: the merge arm, `:1130`
- `merge_ident ||`: "no identity is known", `:1046`
- "the worktrees could not be listed" and "the git directory could not be found": "the worktrees or the git directory cannot be read", `:1048`, `:1056`
- "checked out in two worktrees", `:1052`
- rebasing and bisecting, `:1058-1059`
- W "is missing, not its own top level, or not on it", `:1064`
- mid-operation, `:1067`
- tracked change or status failing, `:1070`
- an untracked or ignored file at an added path, `:1074`
- a file or link where a directory is added, `:1079`
- "the merge commit could not be written", `:1085`
- the state gate, including in W, or default_gate, `:1088`
- the update-ref CAS ("moved ... or could not be updated"), `:1091`
- the ff failing, `:1097`
- "not at the merge after the fast-forward" ("leaves the branch elsewhere"), `:1099`

No assignment is missing from the header, and the header lists nothing land does not produce. The path lines follow via `tail -n +2` (see claim 1).

**Evidence:** `scripts/build-loop.sh:226-241,1042-1100,1130-1132`

---

## Claim 6: "--check's own refusals and skips print as they are (a checkout refusal still names --check)"

**Location:** `scripts/build-loop.sh:240-241`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge arm's pass-through when VERDICT is empty, and the checkout refusal's text. It does not establish anything about skip lines beyond pass-through.

`if [[ -z "${VERDICT[tree]-}" ]]; then cat "$GATE_TMP/line"; exit 2; fi` (`scripts/build-loop.sh:1129`). The checkout refusal reads `"refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"` (`:982`).

**Evidence:** `scripts/build-loop.sh:982,1129`

---

## Claim 7: "Writes nothing but ... --merge's commit, the branch it moves and that branch's reflog (and in W: its files, index, HEAD reflog and ORIG_HEAD)"

**Location:** `scripts/build-loop.sh:245-250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what update-ref and `merge --ff-only` wrote in the probe: ORIG_HEAD, the HEAD and branch reflogs, the index and the files. It does not establish that git writes nothing else transient, such as lock files, which are removed.

Probe `ff.sh` step B: after the ff, `ORIG_HEAD` equals the old main commit and HEAD's reflog has the entry. Maintenance is not spawned (step D, see claim 19). The commit is written through `gate_git commit-tree` into the real object directory (`GIT_OBJECT_DIRECTORY="$v"`, `scripts/build-loop.sh:626`).

**Evidence:** `scripts/build-loop.sh:626,1083-1099`; `$L/ff.log`

---

## Claim 8: "A --check or --merge can also stop part way ... with 1 (need_root) or a failed command's own status"

**Location:** `scripts/build-loop.sh:255-258`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the fact that check_line runs in the merge arm's own shell, so an exit inside it ends the run. It does not establish which commands under set -e can exit there.

`check_line "$a" > "$GATE_TMP/line"` is a redirect, not a subshell (`scripts/build-loop.sh:1125`). The comment on check_line (`:920-921`) states that an exit ends the run.

**Evidence:** `scripts/build-loop.sh:920-921,1125`

---

## Claim 9: the three malformed --merge shapes print "--merge takes one brief path and --expect SHA"; --check's messages unchanged

**Location:** `scripts/build-loop.sh:289-291`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers no brief, no `--expect`, and two briefs with `--expect`, for `--merge`; and five `--check` shapes compared old against new. It does not establish anything about build-loop-check.bats pinning the message text. Its test at `:1586-1590` matches only `*"usage:"*`, so no suite would catch a changed --check message.

Probe `usage.sh` runs 7d78e6d0's script against f782d9ee's:
- New `--merge`, `--merge b`, `--merge --expect T` and `--merge b b --expect T` all print `--merge takes one brief path and --expect SHA`.
- Old printed `--merge needs at least one brief path` and `--expect goes with exactly one brief path` for two of these shapes.
- `--check`, `--check --expect T`, `--check b b --expect T`, `--check b --expect` and a doubled `--expect` print identical messages old and new.

**Evidence:** `scripts/build-loop.sh:289-291`; `test/scripts/build-loop-merge.bats:87-90`; `test/scripts/build-loop-check.bats:1586-1590`; `$L/usage.log` (`timeout 60 bash usage.sh`, cwd its temp dir, exit 0, 2026-10-10T20:55:31Z)

---

## Claim 10: "the merge computations ... and --merge's commit-tree run through gate_git (into the real object store). --merge moves the branch in the real repository (update-ref) or in W (merge --ff-only), and merge_ident alone reads the caller's global config."

**Location:** `scripts/build-loop.sh:899-906`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the uses of CALLER_GLOBAL and the git calls in land. It does not establish anything about the caller's own `GIT_CONFIG_PARAMETERS`, which harden's comment already leaves trusted.

`CALLER_GLOBAL` is used only at `scripts/build-loop.sh:1014`. Grep shows just its definition at `:320` and that use (paraphrased — no quote available because the claim covers absence of other references). commit-tree goes through `gate_git` (`:1084`), whose environment sets `GIT_OBJECT_DIRECTORY="$v"`, the real objects path (`:624-626`). The moves are at `:1089` and `:1096`. The W merge runs with the exported `GIT_CONFIG_GLOBAL=/dev/null` (`:323`).

**Evidence:** `scripts/build-loop.sh:320,323,624-626,1014,1084,1089,1096`

---

## Claim 11: "VERDICT holds tip, tree, policy, branch and stem, and CHANGED each changed path's status letter, only after an ok line (both empty otherwise)."

**Location:** `scripts/build-loop.sh:928-930`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every path through check_line, read in full at `:932-1003`. It does not establish test coverage: mutant M8, which refills CHANGED in the diff loop, survives the merge suite.

`VERDICT=(); CHANGED=()` comes right after the locals (`:936`). The only writers are in verdict_ok (`:987-991`), and its only calls print the ok line (`:992`, `:1001`). The diff loop no longer writes CHANGED (`:959`).

**Evidence:** `scripts/build-loop.sh:932-1003`; `$L/mut-M8-changedinloop.log`

---

## Claim 12: "Reads check_line's locals (bash scope is dynamic); called only here."

**Location:** `scripts/build-loop.sh:986`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers call sites of verdict_ok. It does not establish anything about its definition, which is global once check_line has run once.

`grep -n verdict_ok` finds the definition at `:987` and calls at `:992` and `:1001`, both inside check_line. The function reads `sha tree pol br stem ps ss a`, all declared local in check_line at `:935`.

**Evidence:** `scripts/build-loop.sh:935,986-992,1001`

---

## Claim 13: "The merge commit's author and committer, as git var resolves them: the environment, then git config with the caller's global file (no system file: GIT_CONFIG_NOSYSTEM stays set)."

**Location:** `scripts/build-loop.sh:1005-1007`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same env and config cases as claim 4a. It does not establish anything about include files.

This has the same imprecision as claim 4a. With `user.useConfigOnly=true`, "the environment" means GIT_AUTHOR_*/GIT_COMMITTER_* only, and `EMAIL` is refused (`$L/ident.log` cases 3 and 4). The rest is true: the system file is refused with NOSYSTEM (case 10), and env and config mix per field (case 14: env name, config email gives `c <g@x>`).

**Evidence:** `scripts/build-loop.sh:1012-1017`; `$L/ident.log`

---

## Claim 14a: "Exported (for the rest of the run) because commit-tree runs in the gate repository, which has no config. Returns 1 when git knows none."

**Location:** `scripts/build-loop.sh:1009-1010`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the identity reaching commit-tree through GATE_ENV. It does not establish anything about later git calls in the run, which inherit the exported names; that has no effect on reads.

GATE_ENV unsets only `git rev-parse --local-env-vars` (`:621`), which does not include GIT_AUTHOR_*/GIT_COMMITTER_*. The gate config holds only `[core]` and `[extensions]` (`:625`). The suite asserts the commit's `%an %ae %cn %ce` from env (`test/scripts/build-loop-merge.bats:53`) and from the global file (`:81`), and passes.

**Evidence:** `scripts/build-loop.sh:621,625,1012-1017`; `$L/build-loop-merge.log`

---

## Claim 14b: "user.useConfigOnly: without either, git would guess a name from the passwd entry and the host's domain; it refuses instead."

**Location:** `scripts/build-loop.sh:1007-1009`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guess being disabled (cases 2 and 6). It does not establish a successful guess on this host. Here plain git failed on its own, with `got 'node@...(none)'` and an empty gecos (cases 1 and 7).

See claim 4b.

**Evidence:** `$L/ident.log`

---

## Claim 15a: "decide, then write, then move"

**Location:** `scripts/build-loop.sh:1020`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of land's statements, read in full at `:1042-1101`. The re-gate after the write is part of the move step, as the comment's later sentence says.

All refusals that read worktrees, W and identity come at `:1046-1081`. The write follows:

```bash
# scripts/build-loop.sh:1083-1086
  printf "Merge branch '%s' (build-loop self-merge)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "${VERDICT[stem]}" > "$GATE_TMP/msg" \
    && x="$(gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}" < "$GATE_TMP/msg")" \
    && [[ "$x" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || { MERGE_WHY="the merge commit could not be written"; return 1; }
  NEW="$x"
```

After that come the re-gate (`:1087-1088`) and the move (`:1089-1100`). The message write is now inside the `&&` chain, which is C3's "message write checked".

**Evidence:** `scripts/build-loop.sh:1042-1101`

---

## Claim 15b: "W must be its own top level (no core.worktree elsewhere)"

**Location:** `scripts/build-loop.sh:1024`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers core.worktree pointing at another directory, which is refused. It does not establish anything about a core.worktree that names W by another path: `-ef` compares inodes, so that passes, consistent with "elsewhere". It also does not establish anything about a caller-set GIT_WORK_TREE.

`[[ "$(git -C "$w" rev-parse --show-toplevel)" -ef "$w" && ...` (`:1062`). An empty result, when rev-parse fails, is not `-ef` anything. The test sets `core.worktree` to `$BATS_TEST_TMPDIR/elsewhere` and expects the top-level refusal (`test/scripts/build-loop-merge.bats:142-143`), and it passes. Mutant M4, without the `-ef` clause, still refuses, but with "has a tracked change", so test 6 fails on the message.

**Evidence:** `scripts/build-loop.sh:1062-1064`; `test/scripts/build-loop-merge.bats:142-143`; `$L/mut-M4-toplevel.log`

---

## Claim 15c: "Sets NEW, or MERGE_WHY and returns 1 (a refusal after the write leaves NEW unreachable in the store)."

**Location:** `scripts/build-loop.sh:1033-1034`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers non-racing refusals after `:1086`. It does not establish anything about a racing writer that moves main to NEW, which would make NEW reachable (Q-103 residual).

The unreachable part holds. After the write, the refusals at `:1088`, `:1091`, `:1097` and `:1099` leave no ref or reflog pointing at NEW: update-ref and the ff either did not move the branch, or did and passed `:1099`. The "or" is imprecise. On those refusals land sets both: `NEW="$x"` (`:1086`) stays set alongside MERGE_WHY. The merge arm ignores NEW on refusal (`:1131`), so nothing is misled today. Precise version: "Sets NEW (on success and after the write), and MERGE_WHY on a refusal".

**Evidence:** `scripts/build-loop.sh:1083-1100,1131`

---

## Claim 16: "Each worktree's own git dir, read as files: the common one and those under worktrees/ (dot names too). worktree list shows a rebasing worktree as detached, so only its rebase state names the branch."

**Location:** `scripts/build-loop.sh:1050-1052`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's `worktree list --porcelain` during a real conflicted rebase. It does not establish anything about other git versions.

Probe `rebase.sh`: during a conflicted `git rebase` in linked worktree w, the porcelain listing shows `detached` for w, and `.git/worktrees/w/rebase-merge/head-name` reads `refs/heads/main`.

**Evidence:** `scripts/build-loop.sh:1050-1060`; `$L/rebase.log` (`timeout 30 bash rebase.sh`, cwd its temp dir, exit 0, 2026-10-10)

---

## Claim 17: dot globs `.[!.]*` and `..?*` with `*` cover every admin dir name but `.` and `..`

**Location:** `scripts/build-loop.sh:1054`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers default shell options: the file sets no `dotglob`, `nullglob` or `GLOBIGNORE` (grep of `scripts/build-loop.sh` and `scripts/lib/dev-cycle-read.sh` found none). An unmatched pattern stays literal and `[[ -d ]]` drops it. It does not establish anything about duplicate visits under `dotglob`, which would be harmless.

Probe `glob.sh` created `a .b ..c ... .- .x.y -z .? .[`. The three globs visited exactly the `ls -A` set. Mutant M3, which keeps only `*`, fails test 5 at line 130, the `.x` case.

**Evidence:** `scripts/build-loop.sh:1054`; `$L/glob.log` (`timeout 30 bash glob.sh`, exit 0, 2026-10-10T20:54:36Z); `$L/mut-M3-dotglobs.log`

---

## Claim 18: `[[ ! -f "$d/$q" || "$(<"$d/$q")" != ... ]]` reads no missing file (C8: "no cat per file")

**Location:** `scripts/build-loop.sh:1057,1059`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing file, a directory with the name, and a matching file. It does not establish anything about an unreadable file: `$(<f)` then expands empty with a bash error on stderr, where the old `cat ... 2>/dev/null` was silent. The scan passes in that case, as it did before.

In `[[ ]]`, `||` short-circuits, so the `$(<...)` operand is not expanded when `! -f` holds. The probe printed no error for a missing file, passed a directory named like the file, and refused a matching file.

**Evidence:** `scripts/build-loop.sh:1056-1059`; `$L/glob.log`

---

## Claim 19: "The branch's own mergeOptions (--squash would stage the merge in W and leave the branch) cleared; no gc or maintenance task (a repack) started on the store store_check read; the reflog names the gate."

**Location:** `scripts/build-loop.sh:1093-1096`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 with `branch.main.mergeOptions=--squash` in the repo config, and `run_auto_maintenance` under `maintenance.auto=false`. It does not establish anything about maintenance started by other git calls in the run. For the reflog suffix, see claim 3.

Probe `ff.sh`:
- Step A, with `--squash` set and no override, prints `Squash commit -- not updating HEAD`; main stays and `A b` is staged.
- Step B, with `-c branch.main.mergeOptions=`, fast-forwards main to N with a clean status.
- Step C (`gc.auto=0` only) traces `run_command: git maintenance run --auto --quiet`. Step D (adding `maintenance.auto=false`) traces no maintenance run.

Mutant M1 (no mergeOptions override) fails test 4 at line 106 with "the default branch is not at the merge after the fast-forward". Mutant M7 (no `maintenance.auto=false`) survives the suite, since no test observes maintenance.

**Evidence:** `scripts/build-loop.sh:1093-1097`; `$L/ff.log`; `$L/mut-M1-mergeOptions.log`; `$L/mut-M7-maintenance.log`

---

## Claim 20: "The verdict line is check_line's first (the path lines follow it); the authority (here only self-merge; U3a3 adds --approved), then land's result, replace it." (C4: "the self-merge refusal moved to the merge arm")

**Location:** `scripts/build-loop.sh:1126-1128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge arm. "U3a3 adds --approved" is a plan statement and was not verdicted.

The policy check is at `:1130`. land no longer tests the policy: its first statement is `merge_ident` (`:1046`).

**Evidence:** `scripts/build-loop.sh:1042-1046,1126-1132`

---

## Claim 21: "Names set but the email only in EMAIL: git would take it (and on other hosts guess from the domain); user.useConfigOnly refuses."

**Location:** `test/scripts/build-loop-merge.bats:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git taking `EMAIL` (case 3) and useConfigOnly refusing it (case 4). It does not establish the domain guess on another host.

See `$L/ident.log`, cases 3 and 4. Test 3 passes, and mutant M2 fails at this line (`:78`).

**Evidence:** `test/scripts/build-loop-merge.bats:76-78`; `$L/ident.log`; `$L/mut-M2-useConfigOnly.log`

---

## Claim 22: "The branch's own mergeOptions are cleared: --squash would stage the merge in W and leave main (i1 security F1)."

**Location:** `test/scripts/build-loop-merge.bats:103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --squash case. It does not establish anything about other mergeOptions values.

See claim 19, probe step A.

**Evidence:** `test/scripts/build-loop-merge.bats:103-106`; `$L/ff.log`

---

## Claim 23: test name "... a worktree registered on main that is missing or has its work tree elsewhere"

**Location:** `test/scripts/build-loop-merge.bats:135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test body exercising both cases. It does not establish anything about the missing case's stderr, which the test does not assert.

The body at `:142-145` covers core.worktree pointing elsewhere and a removed registered worktree. Both expect the top-level/missing refusal and pass.

**Evidence:** `test/scripts/build-loop-merge.bats:135-146`; `$L/build-loop-merge.log`

---

## Claim 24: commit message fix list "A1 ... A2 ... A3 ... C1 maintenance.auto=false; ... C3 land decides, then writes the commit (message write checked), then re-gates and moves; C4 ...; C6 CHANGED only on an ok verdict; C8 no cat per file; ... C10 merged BRIEF TIP TREE NEW; C12 dot-named admin dirs scanned, W must be its own top level." Notes: the six deferred items

**Location:** commit f782d9ee message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed fix against the diff, and the Notes against override-log rows 653-659. C2 and C9 are verdicted separately (claims 3 and 25).

Claims 2, 5, 11, 15a, 15b, 17, 18, 19 and 20 cover these items. The six deferred items in the Notes match override-log rows 653-659 (`docs/reviews/override-log.md:653-659`; paraphrased — no quote available because the rows run over 260 characters each and are matched by subject, not text).

**Evidence:** `git log -1 f782d9ee`; `docs/reviews/override-log.md:653-659`

---

## Claim 25: "C9 every malformed --merge prints its usage"

**Location:** commit f782d9ee message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arity shapes and the --expect value errors. "Its usage" is read as the --merge usage message, as rubric C9 states it.

All four arity shapes print the --merge message (claim 9). Two --expect value errors keep their shared messages:
- `--merge b --expect` (no value) prints `--expect takes one commit id, given once`.
- `--merge b --expect abc` prints `--expect takes a full 40- or 64-hex commit id`.

Each usage() call appends the full usage line (`scripts/build-loop.sh:274`). Precise version: "every malformed --merge arity prints the --merge usage message".

**Evidence:** `scripts/build-loop.sh:274-291`; `$L/usage.log`

---

## Claim 26: "Tests: mergeOptions --squash, EMAIL-only identity, dot admin dir, core.worktree, reflog text, usage shapes; each new guard's mutant fails the suite."

**Location:** commit f782d9ee message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers nine mutants of `scripts/build-loop.sh`, applied to a scratch copy and run against the merge suite (copied with its fixtures), plus an unmutated control. It does not establish the results of other suites under the mutants.

The control M0 gives 6 ok. Mutants caught (the suite exits 1):
- M1, mergeOptions override removed: test 4
- M2, useConfigOnly removed: test 3
- M3, dot globs removed: test 5
- M4, `-ef` top-level clause removed: test 6
- M5, GIT_REFLOG_ACTION removed: test 4
- M6, old usage order and messages: test 3
- M9, update-ref message changed: test 1

Survivors (6 ok, exit 0):
- **M7**, `-c maintenance.auto=false` removed (C1's new guard)
- **M8**, CHANGED filled in the diff loop again (C6)

The six listed tests' guards are each caught. C1's guard is not. Precise version: "each tested guard's mutant fails the suite (maintenance.auto=false is untested)".

**Evidence:** `$L/mut-M0-control.log` through `$L/mut-M9-updateref-msg.log` (`run-mut.sh`: `TMPDIR=$(mktemp -d /tmp/u3a2i2-fc-XXXX) timeout 600 bats <copy>/test/scripts/build-loop-merge.bats`, cwd the caller's, 2026-10-10 ~20:56-21:05Z); `mutants.py`

---

## Claim 27: "Suites 6/145/20/79/2/2."

**Location:** commit f782d9ee message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers pass counts at f782d9ee for build-loop-merge, build-loop-check, build-loop-read, dev-cycle and fixture-git-env, plus the two 2-test candidates. It does not establish which 2-test suite the last "2" names: utility-smoke and fixture-hermeticity both have 2 tests and both pass.

Serial runs, each with its own TMPDIR, all exit 0 with 0 `not ok`: merge 6, check 145, read 20, dev-cycle 79, fixture-git-env 2, utility-smoke 2, fixture-hermeticity 2 (paraphrased — no quote available because the counts are tallies of `^ok` lines in the logs).

**Evidence:** `$L/build-loop-merge.log`, `$L/build-loop-check.log`, `$L/build-loop-read.log`, `$L/dev-cycle.log` (ends 2026-10-10T20:55:32Z), `$L/fixture-git-env.log`, `$L/utility-smoke.log`, `$L/fixture-hermeticity.log`; `run-suites.sh` (`TMPDIR=... timeout 1500 bats <suite>`, cwd worktree)

---

## Claim 28: "337 code lines."

**Location:** commit f782d9ee message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count against main (6666a5ce, the merge base). It does not establish anything about a different base.

`git diff --numstat main -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` printed `337` (178+13 for `scripts/build-loop.sh`, 146+0 for the bats file). It ran in the worktree, exit 0, 2026-10-10, with the output shown in-session.

**Evidence:** command run in the worktree at f782d9ee

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 3** (`scripts/build-loop.sh:219-220`; commit C2): the W fast-forward's reflog reads "build-loop: self-merge of STEM: Fast-forward". Say the entry starts with the text, or note the suffix.
- **Claim 4a** (`scripts/build-loop.sh:220-222`): "from the environment" includes EMAIL, which useConfigOnly now refuses. Say GIT_AUTHOR_*/GIT_COMMITTER_*.
- **Claim 13** (`scripts/build-loop.sh:1005-1007`): the same EMAIL imprecision in merge_ident's comment.
- **Claim 15c** (`scripts/build-loop.sh:1033`): "Sets NEW, or MERGE_WHY": after the write, a refusal leaves both set.
- **Claim 25** (commit C9): "every malformed --merge" holds only for the arity shapes; the --expect value errors keep their own messages.
- **Claim 26** (commit message): "each new guard's mutant fails the suite": the maintenance.auto=false mutant (C1) and the CHANGED-in-loop mutant (C6) survive.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/code-fact-check-report-u3a2-i2.md, structured per the code-fact-check skill, with `**Commit:** f782d9ee` and `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. All eight claim groups in the brief are verdicted (28 claims), A1, A2 and A3 are confirmed resolved, and there are no regressions: every suite passes and the --check messages are unchanged.
- Out of scope: code-quality judgments, and stderr leakage on a missing W or an unreadable rebase file (not documentation claims). The rest of `main...HEAD` was used as context only.
- Escalate: none blocking. Claim 26's untested maintenance.auto=false guard is a test-strategy input for the security and performance critics. No hallucination pattern qualified, since there are no Incorrect verdicts.
