Commit: 2028aa89
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3a2 (branch feat/build-loop-u3a2)
**Scope:** `git diff 20de9671..2028aa89 -- scripts test` (ce38eafb: interim fixes G1-G5 to `land()`; 2028aa89: test pinning W's `-ef "$hd"` git-dir check), with the rest of `land()`, `state_is`, the `--merge` header block (~:213-255) and the gate_start comment (~:908-924) read as context
**Checked:** 2026-10-10
**Total claims checked:** 16
**Summary:** 14 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first; no claim below matches a logged pattern.

Execution provenance (all runs cwd = a fresh `mktemp -d /tmp/u3a2c2-fc-XXXX` created inside the script, removed at its end; `ls -d /tmp/u3a2c2-fc-*` afterwards: no matches). Captured outputs live in the session scratchpad `/tmp/claude-1000/-workspace/40e0f8b3-aa3f-469f-bdce-910cba5247e9/scratchpad/u3a2-c2-factcheck/` (this pass was not permitted to write any other repo file):

- **E-git1** `bash probe-git.sh` (git 2.39.5), exit 0, ~2026-10-10T22:20Z, output `probe-git.out`: P1 symbolic-ref through an alias chain; P2 `ref:\n` HEAD; P3 detached rc; P4 garbage HEAD rc; P5 admin dir without commondir rc; P6/P7 `rebase --abort` with CRLF / leading-blank head-name; P8 bare listing.
- **E-git2** `bash probe-git2.sh`, exit 0, ~2026-10-10T22:24Z, output `probe-git2.out`: `rebase --abort` against head-name shapes `state_is` does not match.
- **E-suite** `bash mutants.sh` base copy: `TMPDIR=$(mktemp -d /tmp/u3a2c2-fc-bats-XXXX) bats test/scripts/build-loop-merge.bats` on a copy of `scripts/` and `test/` at 2028aa89, start 2026-10-10T22:21:30Z, rc=0, 7/7 ok (`mutants.out`); mutant `m_ef` (W's `-ef "$hd"` removed) start 22:21:40Z, rc=1, only test 6 fails.
- **E-mut** `bash mutants2.sh` (mutations by `mutate.py`, literal string replacement, each confirmed applied), output `mutants2.out` and `m_*.tap`: `m_bare` (bare-common exclusion removed) 22:22:08Z rc=1, test 7 fails (its test 5 failure is an environment flake, see note at the end); `m_bareidx` (bare-with-index refusal removed) 22:22:16Z rc=1, test 7 fails; `m_dot` (dot-named admin dirs dropped from the loop) 22:22:25Z rc=1, test 5 fails at "a worktree is rebasing the default branch"; `m_oldhead` (HEAD read by the pre-ce38eafb awk instead of symbolic-ref) 22:22:35Z rc=1, test 6 fails at "a worktree has the default branch checked out that git worktree list does not show".

---

## Claim 1: "the worktrees, the git directory or a worktree's own git directory, HEAD or rebase or bisect state cannot be read (exists but is not a readable plain file in a searchable directory)"

**Location:** `scripts/build-loop.sh:231-234`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which HEAD/rebase/bisect conditions refuse with a "cannot be read" reason; does not establish that the parenthetical definition is exhaustive — it is not, since ce38eafb added a refusal for a readable plain-file HEAD that git itself rejects.

The file-shape checks match the parenthetical:

```bash
# scripts/build-loop.sh:1073-1080
for q in "" /rebase-merge /rebase-apply; do
  [[ ! -e "$d$q" && ! -L "$d$q" ]] || [[ -d "$d$q" && ! -L "$d$q" && -r "$d$q" && -x "$d$q" ]] || { MERGE_WHY="a worktree's git directory or rebase state cannot be read"; return 1; }
done
...
  [[ -f "$d/$q" && ! -L "$d/$q" && -r "$d/$q" ]] || { MERGE_WHY="a worktree's git state ($q) cannot be read"; return 1; }
```

But ce38eafb also refuses with the same "(HEAD) cannot be read" reason whenever `git --git-dir=D symbolic-ref -q HEAD` exits 2 or more:

```bash
# scripts/build-loop.sh:1081-1082
x=0; q="$(git --git-dir="$d" symbolic-ref -q HEAD)" || x=$?
[[ "$x" -le 1 ]] || { MERGE_WHY="a worktree's git state (HEAD) cannot be read"; return 1; }
```

E-git1 P4 (HEAD = `garbage`, a readable plain file) gives `rc=128 out=fatal: not a git repository`, and P5 (an admin dir with a valid HEAD but no `commondir`) gives `rc=128` too; both refuse under this reason although the HEAD file is a readable plain file in a searchable directory. The refusal itself is fail-closed; only the header's parenthetical definition is narrower than the code. Precise version: "...cannot be read (exists but is not a readable plain file in a searchable directory, or git cannot read the worktree's HEAD)".

**Evidence:** `scripts/build-loop.sh:231-234`, `scripts/build-loop.sh:1072-1082`, `probe-git.out` (P4, P5)

---

## Claim 2: "the branch is checked out ... in one git worktree list does not show (its gitdir file gone), its HEAD read through any symbolic ref"

**Location:** `scripts/build-loop.sh:234-236`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD files of the shapes `ref: refs/heads/main`, `ref:\nrefs/heads/main`, and `ref: refs/heads/alias` with alias a symref to main, in admin dirs with a valid `commondir`; does not establish behavior for a HEAD reached through per-worktree refs of another admin dir or an admin dir whose `commondir` names a different repository.

The count now comes from git's own resolution:

```bash
# scripts/build-loop.sh:1081-1083
x=0; q="$(git --git-dir="$d" symbolic-ref -q HEAD)" || x=$?
[[ "$x" -le 1 ]] || { MERGE_WHY="a worktree's git state (HEAD) cannot be read"; return 1; }
[[ "$q" != "refs/heads/$MAIN" || ( -n "$bare" && "$d" == "$common" ) ]] || { n=$((n + 1)); hd="$d"; }
```

and is compared with the list's count (`scripts/build-loop.sh:1090`, `[[ "$n" -eq "$([[ -n "$w" ]] && echo 1 || echo 0)" ]] || { MERGE_WHY="a worktree has the default branch checked out that git worktree list does not show"; ...`). E-git1 P1: HEAD → `refs/heads/alias` → `refs/heads/main` prints `rc=0 out=refs/heads/main` (symbolic-ref recurses by default in git 2.39.5). P2: `ref:\nrefs/heads/main` prints `rc=0 out=refs/heads/main`. E-mut `m_oldhead` (the pre-fix awk read) fails test 6 at exactly this refusal; the unmutated suite passes (E-suite).

**Evidence:** `scripts/build-loop.sh:1081-1090`, `test/scripts/build-loop-merge.bats:158-162`, `probe-git.out`, `mutants2.out`, `m_oldhead.tap`

---

## Claim 3: "the repository lists as bare but has an index"

**Location:** `scripts/build-loop.sh:237`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a refusal when the porcelain list carries a `bare` token and `$common/index` exists (file or link); does not establish any other bare-repository inconsistency check (e.g. core.bare set while a work tree exists with no index).

```bash
# scripts/build-loop.sh:1071
[[ -z "$bare" || ( ! -e "$common/index" && ! -L "$common/index" ) ]] || { MERGE_WHY="the repository lists as bare but has an index"; return 1; }
```

Test 7's last step (`: > ../b.git/index`) expects exit 2 and this line; it passes at 2028aa89 and fails under `m_bareidx` (E-mut).

**Evidence:** `scripts/build-loop.sh:1062`, `scripts/build-loop.sh:1071`, `test/scripts/build-loop-merge.bats:173-174`, `mutants2.out`

---

## Claim 4: "Residual: ... a checkout whose git directory lies outside the repository's worktrees/, which neither git nor the gate can see."

**Location:** `scripts/build-loop.sh:251-255`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers an unregistered checkout (no entry under worktrees/) as a residual; does not establish what happens for a registered W whose `.git` file is redirected outside worktrees/ — that case is refused, not residual (Claim 14).

The loop reads only `"$common" "$common"/worktrees "$common"/worktrees/* "$common"/worktrees/.[!.]* "$common"/worktrees/..?*` (`scripts/build-loop.sh:1072`), and the list comes from `git worktree list` (`:1058`), so an admin dir elsewhere is read by neither (paraphrased — no quote available because the claim covers absence of any other read path in land(), confirmed by reading :1053-1136). The new G6 test shows the registered variant is caught by W's `-ef "$hd"` check, consistent with the residual being limited to checkouts git does not list.

**Evidence:** `scripts/build-loop.sh:1058`, `scripts/build-loop.sh:1072`, `scripts/build-loop.sh:1097-1100`

---

## Claim 5: "--merge moves the branch ... in W (merge --ff-only, after land's reads there: the state gate, rev-parse, symbolic-ref, --git-path probes, git status); its worktree list, git-common-dir, each worktree's HEAD (symbolic-ref with that git dir) and state files are read in the real repository"

**Location:** `scripts/build-loop.sh:919-923`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which git commands land() runs with `-C "$w"` versus in the caller's repository or with `--git-dir` on its admin dirs; does not establish which config files `git --git-dir=D` reads (D's own config.worktree, not gated, is read by that invocation).

W reads: `(cd "$w" && state_gate)` (:1096), `git -C "$w" rev-parse --show-toplevel` / `--absolute-git-dir` / `symbolic-ref -q HEAD` / `rev-parse --verify` (:1097-1100), `git -C "$w" rev-parse --path-format=absolute --git-path "$q"` (:1102), `git -C "$w" status` (:1105), then `git -C "$w" ... merge --ff-only` (:1132). Real repository: `git worktree list --porcelain -z` (:1058), `git rev-parse --path-format=absolute --git-common-dir` (:1070), `git --git-dir="$d" symbolic-ref -q HEAD` with `$d` the common dir or an entry of its `worktrees/` (:1081), and `state_is` on files under `$d` (:1085-1087).

**Evidence:** `scripts/build-loop.sh:1058-1105`, `scripts/build-loop.sh:1132`

---

## Claim 6: "Decide (the header's refusals: an ignored file at an added path counts, as merge --ff-only overwrites one)"

**Location:** `scripts/build-loop.sh:1040-1042`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the mapping from the header's --merge refusal list to land(); does not re-verify the ignored-file overwrite behavior of `merge --ff-only` (verified in earlier passes) or the order of the refusals (no longer claimed).

The "in its order" phrase is gone, so no order claim remains. land() implements every header refusal from "no identity is known" through "cannot be updated", including the new bare-with-index one (:1071). Two header refusals are not land()'s: "the policy --status reads is review" is decided in the `merge)` case (`if [[ "${VERDICT[policy]}" != self-merge ]]; then v="refuse $a: the brief's policy is review; ..."`, :1164), and "--check's own refusals and skips" come from check_line (`check_line "$a" > "$GATE_TMP/line"`, :1161). Precise version: "the header's refusals after the policy one".

**Evidence:** `scripts/build-loop.sh:229-252`, `scripts/build-loop.sh:1053-1136`, `scripts/build-loop.sh:1158-1168`

---

## Claim 7: "state_is FILE WANT: a line of FILE is WANT, blanks and a CR at either end dropped (more than git drops, so it matches wherever git would act)."

**Location:** `scripts/build-loop.sh:1050-1051`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers rebase-merge/head-name shapes `refs/heads/main\r\n` (git acts, gate matches) and `main`, `heads/main`, `refs/heads//main`, `refs/heads/main ` and `refs/heads/main\n\n` (git leaves main alone, gate matches or not); does not establish rebase-apply, update-refs or BISECT_START parsing by execution (read only by reasoning) or behavior of other git versions than 2.39.5.

```bash
# scripts/build-loop.sh:1052
state_is() { LC_ALL=C awk -v w="$2" '{ sub(/^[ \t\r]+/, ""); sub(/[ \t\r]+$/, "") } $0 == w { f = 1 } END { exit !f }' "$1"; }
```

E-git1 P6: head-name `refs/heads/main\r\n`, then `rebase --abort` → `main after abort: reset-to-orig HEAD=refs/heads/main` (git acted on main; the gate also matches after stripping the CR). P7: `␠refs/heads/main\n` → `main after abort: other HEAD=detached` (git did not act; the gate matches anyway — "more than git drops"). E-git2: for `main`, `refs/heads/main\n\n`, `refs/heads//main`, `refs/heads/main␠`, `heads/main`, every abort left main `untouched`, so no shape git acts on was found that the gate misses. The old `ref:` normalization was dropped and `state_is` is no longer used on HEAD (grep: its only callers are :1086 and :1088), which is consistent.

**Evidence:** `scripts/build-loop.sh:1050-1052`, `scripts/build-loop.sh:1085-1088`, `probe-git.out` (P6, P7), `probe-git2.out`

---

## Claim 8: "bare) bare=1 ;;  # the repository itself"

**Location:** `scripts/build-loop.sh:1062`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that git's porcelain list emits the `bare` token in the repository's own record; does not establish that `bare` cannot appear in a linked worktree's record (land() sets one flag regardless of record).

E-git1 P8: `worktree /tmp/u3a2c2-fc-JPtP/b.git|bare||worktree .../bo|HEAD ...|detached||` — the token is in the first record, the repository itself, and `--git-common-dir` from `bo` is that same `b.git`, which is the `$d == "$common"` excluded at :1083.

**Evidence:** `scripts/build-loop.sh:1062`, `scripts/build-loop.sh:1083`, `probe-git.out` (P8)

---

## Claim 9: "Every worktree's own git dir (the common one, every entry of worktrees/), read without the list: its HEAD (through any symbolic ref) counts one the list dropped, its rebase state one the list shows as detached."

**Location:** `scripts/build-loop.sh:1066-1068`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the glob set (dot names included) and that HEAD and rebase state are read per admin dir; does not establish the bare case beyond the stated exception (a bare common dir's HEAD on main is deliberately not counted, :1083, which the comment does not mention).

```bash
# scripts/build-loop.sh:1072
for d in "$common" "$common"/worktrees "$common"/worktrees/* "$common"/worktrees/.[!.]* "$common"/worktrees/..?*; do
```

`"$common/worktrees"` itself is only searchability-checked (`[[ -d "$d" && "$d" != "$common/worktrees" ]] || continue`, :1076). E-mut `m_dot` (dot globs removed) fails test 5 at "a worktree is rebasing the default branch" (the `.x` step, `test/scripts/build-loop-merge.bats:133-135`); `m_oldhead` fails test 6 (Claim 2).

**Evidence:** `scripts/build-loop.sh:1066-1090`, `mutants2.out`, `m_dot.tap`

---

## Claim 10: "Anything there git could read and the gate cannot refuses."

**Location:** `scripts/build-loop.sh:1068-1069`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers an unsearchable admin dir or rebase dir (dot names included), a non-plain/unreadable/symlinked HEAD, head-name, update-refs or BISECT_START, and a HEAD git cannot resolve (rc ≥ 2); does not establish exhaustiveness over every state file git consults, and the gate also refuses some shapes git can read (a symlinked HEAD, rubric G7).

Each existing path is checked for shape (:1073-1080), and the symbolic-ref rc ≥ 2 path refuses (:1082). E-git1 P4/P5 give rc 128 for a garbage HEAD and a missing commondir, both refused. The suite's mode-000 `.x/rebase-merge` step (`test/scripts/build-loop-merge.bats:135`, `refused "a worktree's git directory or rebase state cannot be read"`) passes at 2028aa89 (E-suite). No counterexample (a readable-to-git, unreadable-to-gate state passing) was found.

**Evidence:** `scripts/build-loop.sh:1072-1082`, `test/scripts/build-loop-merge.bats:131-135`, `probe-git.out`, `mutants.out`

---

## Claim 11: "The authority (U3a3 adds --approved), then land, replace the verdict line (check_line's first)."

**Location:** `scripts/build-loop.sh:1162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge case's replacement of line 1 of check_line's output; does not establish U3a3's future flag.

```bash
# scripts/build-loop.sh:1163-1166
if [[ -z "${VERDICT[tree]-}" ]]; then cat "$GATE_TMP/line"; exit 2; fi
if [[ "${VERDICT[policy]}" != self-merge ]]; then v="refuse $a: the brief's policy is review; --merge lands only a self-merge brief"
elif land self-merge; then v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"; else v="refuse $a: $MERGE_WHY"; fi
{ echo "$v"; tail -n +2 "$GATE_TMP/line"; }
```

**Evidence:** `scripts/build-loop.sh:1158-1168`

---

## Claim 12: "A CR git's rebase --abort strips (final security F2)."

**Location:** `test/scripts/build-loop-merge.bats:122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `refs/heads/main\r\n` in rebase-merge/head-name with git 2.39.5; does not establish a lone trailing CR without newline.

The test plants `printf 'refs/heads/main\r\n'` (:123). E-git1 P6: with that head-name, `git rebase --abort` reset main to its original commit and left `HEAD=refs/heads/main`, so git strips the CR and acts on main.

**Evidence:** `test/scripts/build-loop-merge.bats:122-123`, `probe-git.out` (P6)

---

## Claim 13: test name "... or a worktree rebases or bisects main" — the `.x` lines pin a dot-named admin dir's rebase and unsearchable rebase-merge (rubric G1)

**Location:** `test/scripts/build-loop-merge.bats:107`, `test/scripts/build-loop-merge.bats:133-135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `.x` admin dir (`.[!.]*` glob); does not exercise the `..?*` glob.

The fixture writes `echo ../.. > "$x/commondir"` (:133) so symbolic-ref resolves (detached, rc 1) and the rebase check, not the HEAD check, fires. Passes at 2028aa89; `m_dot` fails it (E-mut).

**Evidence:** `test/scripts/build-loop-merge.bats:133-135`, `mutants2.out`

---

## Claim 14: "w2's .git names a copy of its admin dir outside worktrees/: on main at M, but not the git dir that counted (rubric G6)."

**Location:** `test/scripts/build-loop-merge.bats:155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the step reaches and is caught only by `-ef "$hd"`; does not test a rogue dir that is also a dot-named entry under worktrees/.

```bash
# test/scripts/build-loop-merge.bats:156-157
cp -r "$R/.git/worktrees/w2" "$BATS_TEST_TMPDIR/rogue" && echo "$R/.git" > "$BATS_TEST_TMPDIR/rogue/commondir" && echo "gitdir: $BATS_TEST_TMPDIR/rogue" > "$BATS_TEST_TMPDIR/w2/.git"
mrg "$B" --expect "$T"; nref "$in is missing, not its own top level, not the one whose git directory names the branch, or not on it at $M"; ...
```

The copy keeps HEAD `ref: refs/heads/main` (on main at M); toplevel, symbolic-ref and rev-parse in W all still pass, so only `"$(git -C "$w" rev-parse --absolute-git-dir)" -ef "$hd"` (`scripts/build-loop.sh:1097`) differs. E-suite: `m_ef` (that conjunct removed) fails test 6 alone; unmutated passes.

**Evidence:** `test/scripts/build-loop-merge.bats:155-157`, `scripts/build-loop.sh:1097-1100`, `mutants.out`

---

## Claim 15: "Its HEAD as git reads it (confirming security 1, 2): "ref:" then a newline; on a symbolic alias of main."

**Location:** `test/scripts/build-loop-merge.bats:160`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two HEAD shapes and the references to security-review-2026-10-10-u3a2-confirm.md findings 1 (`ref:` + CR/LF) and 2 (alias); does not test the `ref:\r` variant of finding 1.

E-git1 P1/P2 show git resolves both shapes to `refs/heads/main`; P2's `git worktree list` output also shows `branch refs/heads/main`, so git does read it as main. `m_oldhead` fails test 6 at the following refusal. Finding 1's title in the security report reads "state_is misses a worktree HEAD that git reads as main when "ref:" is followed by a CR or LF" (`docs/reviews/security-review-2026-10-10-u3a2-confirm.md:46`); rubric G3 names the alias as security 2.

**Evidence:** `test/scripts/build-loop-merge.bats:160-163`, `docs/reviews/security-review-2026-10-10-u3a2-confirm.md:46`, `probe-git.out`, `m_oldhead.tap`

---

## Claim 16: "--merge lands in a bare repository whose worktree is detached or on main, and refuses one listed bare with an index (U3a2 confirming security 4)"

**Location:** `test/scripts/build-loop-merge.bats:167`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a CAS landing from a detached linked worktree (`bo`), a fast-forward in a linked worktree on main (`bw`), and the index refusal; does not cover a bare repository with no linked worktree at all.

The test asserts `merged` from `bo` (:169), `bw`'s HEAD equal to main after the second run (:171), and the refusal line (:173). Passes at 2028aa89; `m_bare` and `m_bareidx` each fail it (E-mut). Rubric G4 maps it to "security 4 (Low, regression)".

**Evidence:** `test/scripts/build-loop-merge.bats:167-174`, `scripts/build-loop.sh:1062`, `scripts/build-loop.sh:1071`, `scripts/build-loop.sh:1083`, `mutants2.out`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 1** (`scripts/build-loop.sh:231-234`): "cannot be read (exists but is not a readable plain file in a searchable directory)" omits the new rc ≥ 2 symbolic-ref refusal (garbage HEAD, missing commondir), which refuses with "(HEAD) cannot be read" on a readable plain file. Text defect, fails closed.
- **Claim 6** (`scripts/build-loop.sh:1040-1042`): "the header's refusals" includes the policy and --check refusals, which the merge case and check_line make, not land(). Text defect.

### Unverifiable
(none)

### Note outside the claims
In E-mut, `m_bare`'s run also failed test 5 at an unrelated step with `deny ... the instruction files outside the checkout (config dirs, ancestors, other worktrees) could not be listed` and stderr `find: '/tmp/u3a2c2-sec-rfjd': No such file or directory` — another agent's temp dir vanished during the gate's walk of ancestor directories. The base run and the other mutants passed that test; it is an environment interaction (a concurrent sibling under /tmp turns the walk into a refusal), not a defect of the mutated line.
