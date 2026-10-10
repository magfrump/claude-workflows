# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u3a2)
**Scope:** branch diff `main...feat/build-loop-u3a2` (scripts/build-loop.sh, test/scripts/build-loop-merge.bats) plus the commit message of 7d78e6d0; the whole branch (no partial-scope label)
**Commit:** 7d78e6d0
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-10
**Total claims checked:** 21
**Summary:** 14 verified, 5 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Execution logs (outside the worktree, per the probe-safety rule): `/tmp/claude-1000/-workspace/5d98ffd1-f546-48ad-a12b-725f01405637/scratchpad/u3a2-i1-factcheck/` (referred to below as `$L`): `probes.sh` / `probes.log` (git behaviour probes, 2026-10-10T20:33:37Z, cwd a fresh `/tmp/u3a2fc-*` dir, exit 0), and one `<suite>.log` per bats suite (each starts with its UTC timestamp; cwd the worktree; each run with its own `TMPDIR=$(mktemp -d /tmp/u3a2fc-XXXX)`). git 2.39.5. Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no logged pattern matches any claim below.

---

## Claim 1: "merged BRIEF NEW TIP TREE ... a commit of TREE whose parents are main's commit and TIP, with the message "Merge branch 'BRANCH' (build-loop self-merge)" and the trailer "Build-loop-gate: STEM" (the brief's file name without .md)"

**Location:** `scripts/build-loop.sh:211-217`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merged line's field order, the commit's parents, tree, message and trailer, and the stem rule; does not establish behaviour for a brief path whose file name lacks `.md` (stem then keeps the whole name).

The line is built as `v="merged $a $NEW ${VERDICT[tip]} ${VERDICT[tree]}"` (`scripts/build-loop.sh:1103`), matching BRIEF NEW TIP TREE. The commit: `printf "Merge branch '%s' (build-loop self-merge)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "${VERDICT[stem]}"` and `gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}"` (`:1023-1024`); stem is `stem="${a##*/}"; stem="${stem%.md}"` (`:973`). Test 1 asserts `merged $B $n $T $TR`, `$n^1 $n^2 $n^{tree}` = `$M $T $TR` and the exact message (`test/scripts/build-loop-merge.bats:45-55`); it passed (6/6).

**Evidence:** `scripts/build-loop.sh:973`, `scripts/build-loop.sh:1023-1024`, `scripts/build-loop.sh:1103`, `test/scripts/build-loop-merge.bats:45-58`; command `TMPDIR=$(mktemp -d /tmp/u3a2fc-XXXX) timeout 600 bats test/scripts/build-loop-merge.bats`, cwd worktree, exit 0, 2026-10-10T20:31:28Z, `$L/build-loop-merge.log`

---

## Claim 2a: "Author and committer as git would take them (the environment, then git config, the caller's global file included)" / merge_ident "as git var resolves them (the environment, then git config with the caller's global file)"

**Location:** `scripts/build-loop.sh:218-220`, `scripts/build-loop.sh:990-992`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the env-then-config order and the caller's global file being read; does not establish that "as git would take them" holds for the system config, which stays off.

`x="$(env "${CALLER_GLOBAL[@]}" git var "GIT_${w}_IDENT" 2>/dev/null)"` (`:997`) restores only the caller's `GIT_CONFIG_GLOBAL`; `GIT_CONFIG_NOSYSTEM=1` exported at `:315` is not undone, so a `user.name` set only in `/etc/gitconfig` is not read, whereas git itself would take it. Test 3 shows the global file is read: with `GIT_AUTHOR_*` unset and `GIT_CONFIG_GLOBAL` pointing at a `[user] name = g` file, the commit carries `g g@example.invalid g g@example.invalid` (`test/scripts/build-loop-merge.bats:72-75`, passed). Precise version: "the environment, then git config (repository and the caller's global file; not the system file)".

**Evidence:** `scripts/build-loop.sh:312`, `scripts/build-loop.sh:315`, `scripts/build-loop.sh:994-1001`, `test/scripts/build-loop-merge.bats:67-75`; `$L/build-loop-merge.log`

---

## Claim 2b: "none known refuses" / "Returns 1 when git knows none (it never guesses one from the host name)"

**Location:** `scripts/build-loop.sh:220`, `scripts/build-loop.sh:992-993`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what `git var GIT_*_IDENT` does when no env or config identity is given; does not establish behaviour on a host with a gecos name and an FQDN or /etc/mailname (could not be staged in this sandbox).

merge_ident fails only when `git var` fails or the output misses the regex (`:997-998`, quoted at Claim 2a). `git var` falls back, without env or config, to the system user name and "the hostname used for outgoing mail (taken from /etc/mailname and falling back to the fully qualified hostname when that file does not exist)" — git-commit(1), "COMMIT INFORMATION", `man git-commit` lines 478-482 on this host — and refuses only when that guess is bogus. In this sandbox it refuses for exactly that reason: `fatal: unable to auto-detect email address (got 'node@c965a4a7cd4f.(none)')` (host name with no domain), and with `EMAIL` set, `fatal: empty ident name (for <e@x.invalid>) not allowed` (empty gecos) (`$L/probes.log`, P1/P1b). On a host whose name has a domain (or with /etc/mailname) and whose passwd entry has a gecos name, git var returns a guessed `Name <user@host.domain>` and --merge lands with it. So "it never guesses one from the host name" is false, and test 3's "a caller git knows no identity for" step passes only because this sandbox's host name has no dot and its gecos is empty (paraphrased — no quote available because the dependency is on the host's passwd/hostname, not on a line of the test). The unshare probe that would have staged an FQDN was blocked (`unshare: Operation not permitted`), hence Medium.

**Evidence:** `scripts/build-loop.sh:994-1001`, `test/scripts/build-loop-merge.bats:67-70`; `man git-commit` (git 2.39.5) COMMIT INFORMATION; command `timeout 60 bash $L/probes.sh`, cwd `/tmp/u3a2fc-*`, exit 0, 2026-10-10T20:33:37Z, `$L/probes.log`

---

## Claim 3: "or refuse BRIEF: WHY, when the policy --status reads is review, no identity is known, a worktree is rebasing ... or its fast-forward fails or leaves the branch elsewhere. --check's own refusals and skips print as they are."

**Location:** `scripts/build-loop.sh:224-233`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping of every listed condition to a `MERGE_WHY` in `land` and of every `MERGE_WHY` back to the list; does not establish wording of each message.

Every listed condition is produced by `land` (`:1021-1074`; each one's message is asserted in tests 2, 3, 5 and 6). `land` also refuses on conditions the list omits: `MERGE_WHY="the merge commit could not be written"` (`:1025`), `"the worktrees could not be listed"` (`:1028`), `"the default branch is checked out in two worktrees"` (`:1032`), `"the git directory could not be found"` (`:1036`), `"$in is missing, or not on it at $MAIN_SHA"` (`:1046`, "missing" not named), and `"... or git status failed or warned there"` (`:1052`). Of these, only "checked out in two worktrees" is a policy condition rather than a failure; a reader treating the list as exhaustive would not expect it. Check's own lines: `if [[ -z "${VERDICT[tree]-}" ]]; then cat "$GATE_TMP/line"; exit 2; fi` (`:1102`) prints them unchanged.

**Evidence:** `scripts/build-loop.sh:1018-1075`, `scripts/build-loop.sh:1097-1106`

---

## Claim 4: "Writes nothing but --check's merge objects ..., --merge's commit and the branch it moves (and W's files), and its own temporary directory, removed at exit."

**Location:** `scripts/build-loop.sh:239-242`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the object, ref and work-tree writes of `land`; does not establish git's own bookkeeping files beyond those named here.

`git update-ref -m "build-loop: self-merge of ${VERDICT[stem]}" ...` (`:1068`) also writes a reflog entry for the branch (the `-m` exists for it), and `git -C "$w" -c gc.auto=0 merge --ff-only -q "$NEW"` (`:1072`) also writes W's index, ORIG_HEAD and HEAD reflog, and starts `git maintenance run --auto` (Claim 13). The commit is written before the worktree checks (`:1024` precedes `:1027-1063`), so a refused --merge leaves an unreferenced commit object; "--merge's commit" covers it. Precise version: add "(with their reflog entries, and W's index and ORIG_HEAD)".

**Evidence:** `scripts/build-loop.sh:1024`, `scripts/build-loop.sh:1068`, `scripts/build-loop.sh:1072`; `$L/probes.log` P6

---

## Claim 5: "Exit: 0 every line printed (or help), for --check every verdict line ok, for --merge merged; 2 any other --check or --merge verdict line, or the state gate not ok. A --check can also stop part way ... 1 bad usage ... a failed mktemp (--check, --merge; no line printed)"

**Location:** `scripts/build-loop.sh:245-251`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0 on merged, 2 on any refusal or skip, 1 on usage; does not establish exits under a mid-run failure, which the header names for --check only.

`[[ "$v" == merged* ]] || exit 2` (`:1105`) and `cat "$GATE_TMP/line"; exit 2` (`:1102`); usage goes through `usage() { ... >&2; exit 1; }` (`:266`) with `[[ "$MODE" == check || -n "$EXPECT" ]] || usage "--merge takes one brief path and --expect SHA"` (`:283`). Tests 1-3 and 5-6 assert 0/2/1 (all passed). `check_line "$a" > "$GATE_TMP/line"` (`:1100`) runs in the caller's shell under `set -e` exactly as in --check, so --merge can equally stop with 1 (need_root, which prints to stderr: `scripts/lib/dev-cycle-read.sh:166`) or a failed command's own status; the sentence "A --check can also stop part way" names --check only. Precise version: "A --check or --merge can also stop part way".

**Evidence:** `scripts/build-loop.sh:266`, `scripts/build-loop.sh:281-283`, `scripts/build-loop.sh:1097-1106`, `scripts/lib/dev-cycle-read.sh:165-169`; `$L/build-loop-merge.log`

---

## Claim 6: "The caller's global config, for merge_ident alone (the merge commit's names: all a loop that writes it could change there); every other call reads none."

**Location:** `scripts/build-loop.sh:310-312`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every use of CALLER_GLOBAL and of GIT_CONFIG_GLOBAL in build-loop.sh and lib/dev-cycle-read.sh; does not establish which non-identity keys `git var` might read from that file (it prints only the ident, and only the regex-checked name and email are exported).

`rg CALLER_GLOBAL` finds only its definition (`:312`) and `env "${CALLER_GLOBAL[@]}" git var` (`:997`); `GIT_CONFIG_GLOBAL=/dev/null` is exported for every other call (`:315`), and neither script nor lib resets it elsewhere (paraphrased — no quote available because the claim covers absence: `rg 'GIT_CONFIG_GLOBAL'` over both files hits only `:295` (comment), `:312`, `:315`). merge_ident exports only `GIT_${w}_NAME`/`GIT_${w}_EMAIL` from the matched groups (`:999`). When the caller had no `GIT_CONFIG_GLOBAL`, `-u GIT_CONFIG_GLOBAL` lets git var read the default global files, as the caller's git would.

**Evidence:** `scripts/build-loop.sh:310-315`, `scripts/build-loop.sh:994-1001`

---

## Claim 7: "VERDICT holds tip, tree, policy, branch and stem only after an ok line (empty otherwise), and CHANGED each changed path's status letter."

**Location:** `scripts/build-loop.sh:917-919`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return path of check_line (read whole, `:921-988`); does not establish CHANGED's contents after a refusal (it then holds the paths read so far, which no caller reads).

`VERDICT=(); CHANGED=()` runs first (`:925`); the only assignment is `verdict_ok() { VERDICT=([tip]="$sha" [tree]="$tree" [policy]="$pol" [branch]="$br" [stem]="$stem"); echo "ok $a $sha $tree"; }` (`:976`), called only on the zero-path branch when `co` is empty (`if [[ -n "$co" ]]; then echo "$co"; else verdict_ok; fi`, `:977`) and at the end when `co` is empty and `nd` is 0 (`:986`). Every other path (`:928`, `:930-933`, `:937-938`, `:943`, `:947`, `:953`, `:960`, `:963`, `:979`, the checkout refusal at `:977`/`:986`, the deny count at `:986`) echoes a refuse/skip line and leaves VERDICT empty. CHANGED is set per record: `CHANGED[$p]="${ss[-1]}"` (`:948`); keys `@` and `*` behave as plain keys in a bash associative array (probed in-session).

**Evidence:** `scripts/build-loop.sh:920-988`

---

## Claim 8: "No worktree may be rebasing it or bisecting from it."

**Location:** `scripts/build-loop.sh:1005`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a rebase of the default branch (merge or apply backend) and a bisect started while on it, in any worktree; does not establish a bisect started from a detached HEAD at main's commit (BISECT_START then holds a commit id, so it is not "from it") or other operations that can move the branch (e.g. another worktree's `rebase --update-refs`).

```bash
# scripts/build-loop.sh:1037-1043
  for d in "$common" "$common"/worktrees/*; do
    [[ -d "$d" ]] || continue
    for q in rebase-merge rebase-apply; do
      [[ "$(cat "$d/$q/head-name" 2>/dev/null)" != "refs/heads/$MAIN" ]] || { MERGE_WHY="a worktree is rebasing the default branch"; return 1; }
    done
    [[ "$(cat "$d/BISECT_START" 2>/dev/null)" != "$MAIN" ]] || { MERGE_WHY="a worktree is bisecting from the default branch"; return 1; }
  done
```

Probe P2: a stopped `git rebase` of main in linked worktree `w` writes `.git/worktrees/w/rebase-merge/head-name` = `refs/heads/main`, and `git worktree list --porcelain` shows `w` as `detached` meanwhile, so the porcelain scan (`:1030-1034`) does not see it and this loop is what catches it. Probe P3: `git bisect start` on main in `w` writes `BISECT_START` = `main` (short name) in `.git/worktrees/w/`, not in the common dir; from a detached HEAD it writes the commit id. Test 5 asserts both refusals and that `BISECT_START` = `feat/x` is let through (`test/scripts/build-loop-merge.bats:118-122`, passed).

**Evidence:** `scripts/build-loop.sh:1027-1043`, `test/scripts/build-loop-merge.bats:118-122`; `$L/probes.log` (P2, P3); `$L/build-loop-merge.log`

---

## Claim 9: "When no worktree has it checked out: a compare-and-swap (update-ref from MAIN_SHA, so a branch that moved since the check is left as it is)."

**Location:** `scripts/build-loop.sh:1006-1007`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the CAS and its refusal when the branch moved; does not establish the Q-103 residual (a worktree checking the branch out between the scan and the swap), which the comment names as residual.

`git update-ref -m "..." "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" 2>/dev/null || { MERGE_WHY="the default branch moved after the check, or could not be updated; it was left as it is"; return 1; }` (`:1068-1069`). Test 2's shim moves main to `$o` just before the first `update-ref` call; the run refuses and main stays at `$o` (`test/scripts/build-loop-merge.bats:61-65`, passed).

**Evidence:** `scripts/build-loop.sh:1067-1069`, `test/scripts/build-loop-merge.bats:60-65`; `$L/build-loop-merge.log`

---

## Claim 10: "nothing at a path the merge adds (an untracked or ignored file: merge --ff-only overwrites an ignored one)"

**Location:** `scripts/build-loop.sh:1009-1011`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's ff-only overwriting an ignored file and refusing an untracked one, and the A-path check catching both; does not establish paths with status M or T (the clean-W check covers those).

Probe P4: with `n.txt` ignored in W, `git merge --ff-only` exits 0 and `n.txt` becomes `new` (the ignored content is lost); untracked and not ignored, git refuses with "untracked working tree files would be overwritten". The check: `[[ "${CHANGED[$p]}" == A ]] || continue; [[ ! -e "$w/$p" && ! -L "$w/$p" ]] || { MERGE_WHY="$in holds an untracked or ignored $p, a path the merge adds"; return 1; }` (`:1054-1055`) refuses both. Test 5 asserts both cases (`test/scripts/build-loop-merge.bats:109-110`).

**Evidence:** `scripts/build-loop.sh:1053-1063`, `test/scripts/build-loop-merge.bats:109-111`; `$L/probes.log` (P4)

---

## Claim 11: "A directory, nothing, or a file the merge deletes (git replaces it)."

**Location:** `scripts/build-loop.sh:1059`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a tracked file at a prefix that the merge deletes being replaced by the directory on ff-only in a clean W; does not establish a prefix that is a tracked symlink to a directory (then `-e "$w/$p"` at `:1055` follows it and refuses with the "untracked or ignored" message).

`[[ ( -d "$w/$q" && ! -L "$w/$q" ) || ( ! -e "$w/$q" && ! -L "$w/$q" ) || "${CHANGED[$q]-}" == D ]]` (`:1060`). Probe P5: main has file `sub`, the branch replaces it with `sub/f`; diff-tree lists `D sub` and `A sub/f`, and `merge --ff-only` exits 0 with `sub/f` = `g`.

**Evidence:** `scripts/build-loop.sh:1056-1062`; `$L/probes.log` (P5)

---

## Claim 12: "The state gate (here and in W) and default_gate run again just before the branch moves (row 494)."

**Location:** `scripts/build-loop.sh:1013-1014`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the re-run's placement after all of land's checks and before both moves; does not establish anything between this line and the move (the Q-103 race residual).

`{ state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; } > "$GATE_TMP/state" || { MERGE_WHY="the git state changed after the check ($(head -n 1 "$GATE_TMP/state"))"; return 1; }` (`:1065-1066`), immediately followed by the `update-ref` / `merge --ff-only` branch (`:1067-1074`). Test 2's second half plants `filter.x.clean` from a shim on `commit-tree` (after check_line's state gate at startup) and gets that refusal (`test/scripts/build-loop-merge.bats:66-69`, passed).

**Evidence:** `scripts/build-loop.sh:1065-1074`, `test/scripts/build-loop-merge.bats:66-69`; `$L/build-loop-merge.log`

---

## Claim 13: "gc.auto=0: merge would start a git gc of the store store_check read."

**Location:** `scripts/build-loop.sh:1071`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what a fast-forward merge starts in git 2.39; does not establish gc's behaviour at the auto threshold (not staged).

Probe P6: `GIT_TRACE=1 git -c gc.auto=0 merge --ff-only` still runs `git maintenance run --auto --quiet`; the setting does not stop that process. Its default task is gc, whose auto condition gc.auto=0 turns off (paraphrased — no quote available because this rests on git's gc/maintenance documentation, not on repository code; the threshold case was not staged). Precise version: "merge starts git maintenance run --auto, whose gc task gc.auto=0 turns off".

**Evidence:** `scripts/build-loop.sh:1072`; `$L/probes.log` (P6)

---

## Claim 14: "land's result replaces only the verdict line; the path lines follow."

**Location:** `scripts/build-loop.sh:1101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output order on an ok check_line; does not establish anything for the non-ok path, which prints check_line's output unchanged.

`{ echo "$v"; tail -n +2 "$GATE_TMP/line"; }` (`:1104`); check_line prints the verdict first and then `printf '%s\n' "${rows[@]}"` (`:986-987`). Tests assert `lines[1]` = `path $B A work-feat-x.txt` after a refusal and after a merge (`test/scripts/build-loop-merge.bats:39`, `:48-49`).

**Evidence:** `scripts/build-loop.sh:986-987`, `scripts/build-loop.sh:1103-1104`; `$L/build-loop-merge.log`

---

## Claim 15: Test names and labels: "... a second run refuses (T22, G13, U3a2)", "... between the check and the swap, and refuses git state planted after the check (T22, G17, row 494, U3a2)", "a worktree on another branch is left alone (T23, F50, U3a2)", "... or a worktree rebases or bisects main (T23, F29, F50, U3a2)"

**Location:** `test/scripts/build-loop-merge.bats:44`, `test/scripts/build-loop-merge.bats:60`, `test/scripts/build-loop-merge.bats:88`, `test/scripts/build-loop-merge.bats:101`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named test asserting its stated behaviour and the gap labels matching `docs/reviews/test-strategy-build-loop-handoff.md`; does not establish full closure of G13 (its "branch whose only commit is the marker" case is not tested here).

G13 is "repeated or empty merges: a second `--merge` after a successful one ..." and G17 "a wrapper `git` on PATH that moves main on the first `update-ref`" (`docs/reviews/test-strategy-build-loop-handoff.md:30`, `:34`); test 1 runs `--merge` a second time and asserts `refuse $B: its branch feat/x has no commit the default branch lacks` with main unchanged (`:56-57`); test 2 uses `shim update-ref` (`:62`). "A worktree on another branch is left alone": R is put on `feat/y` at `$M` and the test asserts `symbolic-ref HEAD` = `refs/heads/feat/y` and `HEAD` = `$M` after a merge that took the CAS path (`:96-98`). Test 4 also keeps `unrelated.txt` (`:92`). All 6 tests passed.

**Evidence:** `test/scripts/build-loop-merge.bats:44-134`, `docs/reviews/test-strategy-build-loop-handoff.md:30-34`; `$L/build-loop-merge.log`

---

## Claim 16: Commit body: "--merge BRIEF --expect SHA runs gate_start and check_line, then writes the merge commit ... by compare-and-swap when no worktree has it checked out, else by merge --ff-only in that worktree after checking it is on main at the checked commit, clean, mid no operation, and holds nothing (untracked or ignored) where the merge adds a path. No worktree may rebase or bisect main. The state gate and default_gate run again just before the move (row 494). check_line now leaves the verdict as values in VERDICT and CHANGED (row 512)."

**Location:** commit 7d78e6d0 message, paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the summary as a restatement of Claims 1, 7-12; inherits Claim 8's scope (bisect "from" main only) and does not establish the residuals the Notes name.

`merge) gate_start; a="${ARGS[0]}"; check_line "$a" > "$GATE_TMP/line"` (`scripts/build-loop.sh:1097-1100`), then `land` (`:1103`); each part is verdicted in Claims 1 and 7-12.

**Evidence:** `scripts/build-loop.sh:1018-1106`

---

## Claim 17: "Ten mutants of the new guards: nine caught; the tenth (a redundant -d test) was removed."

**Location:** commit 7d78e6d0 message, paragraph 2
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about the mutation run itself; does not establish which guards were mutated or that nine were caught.

No mutant list or log is committed (paraphrased — no quote available because the claim covers absence: `git diff main...HEAD` adds no mutation artifact, and the branch has a single commit, so the removed `-d` test cannot be seen in history). The final code's directory check uses `-d` once, inside the prefix rule (`scripts/build-loop.sh:1060`). Would need the mutation script or its log.

**Evidence:** `scripts/build-loop.sh:1060`; `git log main..HEAD` (one commit)

---

## Claim 18: "Suites 6/145/20/79/2/2."

**Location:** commit 7d78e6d0 message, paragraph 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers pass counts at 7d78e6d0 for build-loop-merge, build-loop-check, build-loop-read, dev-cycle, fixture-git-env and the two 2-test candidates; does not establish which 2-test suite the last "2" names (utility-smoke and fixture-hermeticity both hold 2, both pass).

Serial runs, each with its own `TMPDIR=$(mktemp -d /tmp/u3a2fc-XXXX)`: build-loop-merge 6 ok, build-loop-check 145 ok, build-loop-read 20 ok, dev-cycle 79 ok, fixture-git-env 2 ok, utility-smoke 2 ok, fixture-hermeticity 2 ok; 0 `not ok`, all exit 0 (paraphrased — no quote available because the counts are tallies of `^ok` lines in the captured logs).

**Evidence:** `$L/build-loop-merge.log` (20:31:28Z), `$L/build-loop-read.log` (20:31:33Z), `$L/fixture-git-env.log` (20:31:48Z), `$L/utility-smoke.log` (20:31:49Z), `$L/fixture-hermeticity.log`, `$L/build-loop-check.log` (20:32:07Z), `$L/dev-cycle.log` (20:33:14Z); commands `TMPDIR=... timeout 600|1500 bats test/scripts/<suite>.bats` and `bats test/fixture-hermeticity.bats`, cwd worktree, exit 0

---

## Claim 19: "299 code lines." (pr-prep step 1a's count against main)

**Location:** commit 7d78e6d0 message, paragraph 2
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the step-1a count with BASE=main; does not establish anything about a different base.

`git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` (the command at `workflows/pr-prep.md:91`) printed `299` in the worktree (exit 0, 2026-10-10, output shown in-session; the diff stat agrees: 285 insertions + 14 deletions).

**Evidence:** `workflows/pr-prep.md:86-92`; command run in the worktree at HEAD 7d78e6d0

---

## Claim 20: Commit Notes: "identity comes from git var with the caller's own global config (every other call reads none), so a host run without GIT_AUTHOR_* still finds the user's name; ... A review-policy brief is refused until U3a3's --approved."

**Location:** commit 7d78e6d0 message, Notes
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the global-config identity and the review refusal; does not establish the "never guesses" property (Claim 2b, Incorrect) or the Q-103 residuals.

Test 3 runs without `GIT_AUTHOR_*`/`GIT_COMMITTER_*` and a global file naming `g`, and the merge commit carries `g` (`test/scripts/build-loop-merge.bats:72-74`); `[[ "${VERDICT[policy]}" == self-merge ]] || { MERGE_WHY="the brief's policy is review; --merge lands only a self-merge brief"; return 1; }` (`scripts/build-loop.sh:1021`), asserted at `test/scripts/build-loop-merge.bats:76-79`.

**Evidence:** `scripts/build-loop.sh:1021`, `scripts/build-loop.sh:994-1001`, `test/scripts/build-loop-merge.bats:67-79`; `$L/build-loop-merge.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2b** (`scripts/build-loop.sh:992-993`, also `:220`): `git var` does guess an identity (gecos name + /etc/mailname or the FQDN) and refuses only when that guess is bogus. "(it never guesses one from the host name)" and "none known refuses" are false on a host with a domain name and a gecos name, and test 3's no-identity step depends on this sandbox's hostname and passwd entry. Legibility-target: for-author.

### Stale
- (none)

### Mostly Accurate
- **Claim 2a** (`scripts/build-loop.sh:218-220`, `:990-992`): "as git would take them" leaves out that the system config stays off (`GIT_CONFIG_NOSYSTEM=1`). Legibility-target: for-author.
- **Claim 3** (`scripts/build-loop.sh:224-233`): the refusal list leaves out "checked out in two worktrees", "W missing", and the failure refusals (commit not written, worktrees not listed, git dir not found, git status failed). Legibility-target: for-author.
- **Claim 4** (`scripts/build-loop.sh:239-242`): "Writes nothing but" leaves out the branch reflog entry (`update-ref -m`), W's index, ORIG_HEAD and HEAD reflog. Legibility-target: for-author.
- **Claim 5** (`scripts/build-loop.sh:245-251`): "A --check can also stop part way" applies equally to --merge (same check_line under `set -e`) but names --check only. Legibility-target: for-author.
- **Claim 13** (`scripts/build-loop.sh:1071`): merge starts `git maintenance run --auto` (which still runs), whose gc task gc.auto=0 turns off. It does not start gc directly. Legibility-target: for-author.

### Unverifiable
- **Claim 17** (commit 7d78e6d0): there is no artifact for the ten-mutant run. Verifying it would need the mutation script or log. Legibility-target: for-orchestrator-synthesis.

Legibility-target for the Verified claims (1, 6-12, 14-16, 18-20): for-orchestrator-synthesis.

Hallucination-pattern log: not updated. This pass may write only this report. Claim 2b claims git has a strictness it lacks ("git var never guesses an identity from the host name"). It is a candidate entry for the orchestrator to add to `docs/reviews/hallucination-patterns.md`.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/code-fact-check-report-u3a2-i1.md, structured per the code-fact-check skill, with `**Commit:** 7d78e6d0` and `**Replication:** k=1 (loop pass, decision 031)` in the header.
- Answered: The report covers all 8 claim areas from the brief: the header refusals, exits and field order (Claims 1, 3, 5), the rebase and bisect detection (8), the ignored-file overwrite and the prefix rule (10, 11), CALLER_GLOBAL and merge_ident (2a, 2b, 6), the check_line return paths (7), the row-494 re-run and gc.auto (12, 13), the commit-message counts (17-19), and the test labels (15). Every bats suite and git-behaviour probe ran serially under timeout. No processes are left running.
- Out of scope: code quality, and whether the Q-103 residuals are acceptable. I also did not judge behaviours the comments do not claim, such as an untracked file under a tracked-symlink prefix, or `rebase --update-refs` moving main from another worktree. Those belong to sibling critics.
- Escalate: Claim 2b. The no-identity refusal and its test depend on the host, not on the code. A real host with an FQDN and a gecos name would land a merge under a guessed identity. That contradicts the header's "none known refuses". Fixing it is a design choice for the author: pass `user.useConfigOnly=true` or check the env/config keys directly, or reword the comment.
