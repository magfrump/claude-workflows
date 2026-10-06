Commit: db9cc040

# Code Fact-Check Report

**Commit:** db9cc040
**Replication:** r1 of k=3 (final confirming pass)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a, branch feat/build-loop-u2a)
**Scope:** full branch diff `git diff main...HEAD` (merge base 900c47d0; commits cfbf34d2, b9ffe7a8, 36b79f72, db9cc040 — four commits, not five) and all four commit messages; plan D2/D5/D6, the 2026-10-05 amendment and step 5's U2 split note; known issues A2-A4; the rubric's iteration-2 section and the 14 override rows this branch adds. `docs/reviews/hallucination-patterns.md` was read; no claim below matches a logged pattern.
**Checked:** 2026-10-06
**Total claims checked:** 45
**Summary:** 31 verified, 10 mostly accurate, 1 stale, 2 incorrect, 1 unverifiable

Execution logs: every executed run below wrote its output under
`/tmp/claude-1000/-workspace/f2b09f27-e8e1-48a1-9e62-9ab10d974ed8/scratchpad/review-u2a/fc3r1/` (written `$S/` below). The probe scripts there are
`h.sh` (E1-E9), `h2.sh` (E10-E11), `mut.sh` (guard-deletion mutants), `ifprobe.sh`, `probes2.sh` (+ `uni.py`). Every process ran under `timeout` and had exited before this report was written.

| Run | Command (cwd) | Exit | Time (UTC) | Output |
|---|---|---|---|---|
| X1 | `timeout 900 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats` (worktree) | 0 (97/97 ok) | 2026-10-06T06:56:47Z | `$S/bats.log` |
| X2 | `timeout 120 bash $S/h.sh` (scratch fixture repos `$S/repo-e1`..`e9`) | 0 | 2026-10-06T06:57:43Z | `$S/h.log` |
| X3 | `timeout 300 bash $S/h2.sh` (fixtures `$S/repo-e10*`; E11 in the worktree) | 0 | 2026-10-06T06:58:36Z | `$S/h2.log`, `$S/main.set`, `$S/tree.set` |
| X4 | main_imports / imported_names timing, 3 runs (worktree) | 0 | 2026-10-06T06:58:46Z | `$S/timing.log` |
| X5 | `timeout 200 bash mut.sh <commit> <guard> <tag>` x4 (`$S`; archives in `$S/mut-*`) | 1 each (a test fails) | 2026-10-06T07:00:36Z | `$S/mut.log` |
| X6 | `timeout 30 env LC_ALL=C bash $S/ifprobe.sh` (worktree) | 0 | 2026-10-06T07:02:26Z | `$S/ifprobe.log` |
| X7 | the three suites at cfbf34d2 (`git archive cfbf34d2 scripts test` into `$S/at-cfbf`) | 1 (11 not ok) | 2026-10-06T07:02:51Z | `$S/at-cfbf.log` |
| X8 | `timeout 120 bash $S/probes2.sh` (worktree; fixture `$S/repo-dupread`) | 0 | 2026-10-06T07:04:29Z | `$S/probes2.log` |
| X9 | `git diff --numstat main...<rev> -- ':(top)' ':(top,exclude)docs/' \| awk ...` for b9ffe7a8, 36b79f72, db9cc040 (worktree) | 0 | 2026-10-06T07:01Z | inline: 393, 417, 479 (pr-prep 1a's command) |

---

## Claim 1: "the instruction-file import walks, the self-merge floor, and the default branch"

**Location:** `scripts/lib/dev-cycle-read.sh:6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the lib now defines two walks (`imported_names`, `main_imports`) and `floor`; does not establish anything about the other items in the header's list, which this branch did not change.

The lib defines `imported_names() {` (`:485`), `main_imports() {` (`:509`) and `floor() {` (`:602`), matching the opening list's new items.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1-6`, `:485`, `:509`, `:602`

---

## Claim 2: "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats)."

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the named suites exist and pass at db9cc040 (X1: 97/97); does not establish that any CI enforces the rule.

X1 ran `build-loop-check.bats`, `dev-cycle.bats` and `build-loop-read.bats`; the log ends with `ok 97 ...` and contains no `not ok` line.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-11`, run X1, `$S/bats.log`

---

## Claim 3: "inrepo, dirok, skipped, check_brief, isimported, floor and the import walks exit 1 (need_root) unless ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:15-17`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor, both walks and isimported's `main`/`tree` arms with ROOT_REAL unset; does not establish need_root's other two conditions for these functions.

`floor` calls `need_root` first (`:604`), and both walks call it (`:512`, `imported_names`). isimported, though, reaches need_root only through a walk; its `*) return 2 ;;` arm (`:573`) returns without it. X8 with ROOT_REAL unset: `isimported foo x` printed `rc=2` with shell exit 0, while `isimported main x`, `isimported tree x` and `floor AGENTS.md s M` printed the need_root message and exited 1. Precise version: isimported exits through need_root for `main` and `tree`; an unknown walk name returns 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:567-575`, `:602-604`, run X8, `$S/probes2.log`

---

## Claim 4: "Inputs: check_brief, ... read the default branch's commit, never the working tree (...), and so does floor (its import walk also starts from the checkout's untracked instruction files)"

**Location:** `scripts/lib/dev-cycle-read.sh:30-33`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which inputs floor's walk reads; does not establish anything about the other functions in the sentence.

The parenthetical names one working-tree input, but the walk has two more: `t:` queue items are read from the checkout, `if [[ "$src" == t ]]; then inrepo_here "$f" || continue; out="$(import_targets "$d" < "$f")"` (`:542`). These are untracked start files *and* any import target main does not store (`else queue+=("t:$p")`, `:559`). Untracked `.claude/rules/*.md` files also start the walk (`:534`). Test 5 shows this: `docs/local-notes.md` (untracked, reached from `CLAUDE.local.md`) leads to tracked `docs/t.md` (`test/scripts/build-loop-check.bats:146-150`, passing in X1). Precise version: "floor reads main's commit, plus the checkout's untracked start files and the checkout copy of any import target main lacks."

**Evidence:** `scripts/lib/dev-cycle-read.sh:526-537`, `:542`, `:559`; `test/scripts/build-loop-check.bats:145-150`; run X1

---

## Claim 5: "inrepo for a caller that has run need_root itself (a walk, per path)."

**Location:** `scripts/lib/dev-cycle-read.sh:124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that inrepo_here is inrepo minus need_root and that both walks call it after need_root; does not establish other callers' ordering.

`inrepo() { need_root; inrepo_here "$1"; }` (`:123`) and `inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`:125`). The callers are `imported_names` and `main_imports` (`:542`), and both run `need_root` first.

**Evidence:** `scripts/lib/dev-cycle-read.sh:123-125`, `:512`, `:542`

---

## Claim 6: "isclosed spells the closed/ rule once (row 292)" (commit b9ffe7a8)

**Location:** `scripts/lib/dev-cycle-read.sh:162`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers code lines in scripts/ that test the closed/ path; does not establish anything about prose mentions.

The only code line naming `briefs/closed` in `scripts/lib/dev-cycle-read.sh`, `scripts/build-loop.sh` and `scripts/dev-cycle.sh` is `isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }` (`:162`). `writable`, `check_brief` and `shared_branches` call it (paraphrased — no quote available because the claim is about the absence of other spellings, established by a grep with one hit).

**Evidence:** `scripts/lib/dev-cycle-read.sh:162`, `:163-166`, `:345`; `scripts/build-loop.sh:318`

---

## Claim 7: main_entry's comment: "badform" (a path pathform refuses: a .git* part such as .gitattributes, say) or "error" (no default branch found by name, ls-tree failed, or the tree lists a name twice ...). Only blob reads the file, and only absent means there is none

**Location:** `scripts/lib/dev-cycle-read.sh:251-264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the badform/error/absent split and the ordering main_by_name → pathform; does not establish every input pathform refuses, beyond the seven the test runs.

`if ! main_by_name; then echo error; return; fi` / `if ! pathform "$1"; then echo badform; return; fi` (`:269-270`). The dev-cycle.bats test "main_entry answers badform ..., absent for a plain missing one" passes in X1: `x` gives `absent`, and `a"b.md`, `../x`, `-x`, `docs//x.md`, `.gitattributes` and `.github/x.yml` each give `badform`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:251-283`, `test/scripts/dev-cycle.bats:1335-1345`, run X1

---

## Claim 8: "Why main_entry's word $1 for path $2 is not a file to read, for a skip line." / "A9: entry_why has an explicit error arm; the default names the word."

**Location:** `scripts/lib/dev-cycle-read.sh:284-293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers entry_why's arms and its three callers; does not establish the wording of skip lines beyond those arms.

`error) echo "the tree of the default branch could not be read" ;;` and `*) echo "the default branch answered $1 for $2" ;;` (`:290-291`). `main_file` (`scripts/build-loop.sh:133`), `check_brief` (`:355`) and `check_answer` (`:714`) all call it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:284-293`, `:355`, `:714`; `scripts/build-loop.sh:133`

---

## Claim 9: "it starts at every instruction file stored there (and every .md under .claude/rules/, which Claude Code also loads), plus the checkout's untracked ones"

**Location:** `scripts/lib/dev-cycle-read.sh:445-448`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start selection: main entries of any mode whose name ends in .md, lower-cased and matched against INSTRUCTION_FILE or `.claude/rules/*.md` (nested too, since `*` crosses `/`), plus untracked/ignored .md files; does not establish that a gitlink or an untracked symlinked start is read (neither is: `*) continue` at `:551`; `inrepo_here` at `:542`).

`[[ "$f" != *.[mM][dD] ]] || cand+=("m:$f")` (`:524`), `if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md ]]` (`:534`). In X1, test 5 shows `.claude/rules/style.md`'s import `docs/r.md` refused. In X2/E6, a start under a directory named `a<TAB>b` was read (`docs/q.md` refused). In E9, a gitlink named `CLAUDE.md` started nothing (`other.md: -`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:519-537`, `test/scripts/build-loop-check.bats:133-152`, runs X1, X2 (`$S/h.log`)

---

## Claim 10: "follows an import into the file main stores at that path, whatever its name; a symlink there is followed to the path its text names" (with `:546` "a symlink: its text names the file read, as one more import")

**Location:** `scripts/lib/dev-cycle-read.sh:448-449`, `:546-550`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the symlink-following half for main-stored symlinks. Plain symlinks, chains, loops, `..` texts and doubled-name trees behave as stated. Two text shapes do not: a text ending in newline(s) and an absolute text. Does not establish whether Claude Code reads files holding NUL bytes (E7 below).

The text is read with command substitution: `if ! out="$(git cat-file blob "$MAIN_SHA:$f")" || [[ "$out" == *$'\n'* ]]; then IMPORTED_MAIN=error; return 1; fi` (`:547`). `$(...)` strips trailing newlines, so a text like `n.md\n\n` is neither refused nor followed to the path it names. The walk follows `n.md` instead.

- E1 (X2): a symlink `CLAUDE.md` whose text is `notes.md\n`, plus a blob named `notes.md\n` holding `@secret.md`. A checkout's symlink resolves to `notes.md\n`, which imports `secret.md`. Floor printed `secret.md: -` (passes) and refused `notes.md`, a path that does not exist.
- E10c (X3): the same with the text `n.md\n\n` gives `s.md: -`.

That is fail-open: the imported file is not refused. An interior newline does fail the walk, as intended (E2: `other.md:` walk-failure reason). An absolute text is skipped silently, `[[ "$out" != /* ]] || continue` (`:548`), so it is not "followed to the path its text names". The "Not covered" list (`:451-453`) names absolute *imports* only.

Working as stated: symlink chains and loops (E4: `b.md`, `c.md`, `deep.md`, `l1.md`, `l2.md` all refused, the walk ends); a `../top.md` text resolved from `sub/` (E5: `top.md` and `t2.md` refused); an escaping `../../out.md` dropped; any stored name such as `.github/instr.md` or `docs/a+b.md` (test 5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:445-454`, `:539-561`; runs X2 (`$S/h.log` E1, E2, E4, E5), X3 (`$S/h2.log` E10c), X1 (test 5)

---

## Claim 11: "A target main does not have is read from the checkout when it is a plain file there. Reading the checkout can only add refusals."

**Location:** `scripts/lib/dev-cycle-read.sh:449-451`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `t:` items only append to IMPORTED_MAIN/queue and are gated by inrepo_here; does not establish which checkout the gate runs in (override row, known issue A4).

`if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); else queue+=("t:$p"); fi` (`:559`), and a `t:` item is read only after `inrepo_here "$f" || continue` (`:542`). No path through a `t:` read removes an entry or turns a refusal into a pass. The type of a queued path depends only on `ent`, not on how it was reached, so a checkout read never stops a main read (paraphrased — no quote available because the invariant is inferred from the queue logic across `:532-560`). Test 5 (X1) refuses `docs/local-notes.md` and the tracked `docs/t.md` it imports.

**Evidence:** `scripts/lib/dev-cycle-read.sh:526-561`, run X1

---

## Claim 12: "Not covered (known issues A2/A3): a path through a symlinked directory, other names that one file has on a case-insensitive checkout, and absolute imports."

**Location:** `scripts/lib/dev-cycle-read.sh:451-453`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the three listed gaps and the cited issue IDs; does not establish that the list is complete (Claim 10 adds the newline-tail and absolute symlink texts).

The three gaps are real. A target under a symlinked directory is queued `t:` and dropped by `inrepo_here` (`:542`). `import_targets` skips `/`-leading tokens (`[[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue`, `:470`). But the known-issue row this branch adds for *this* walk is A4: "The gate's walk (`main_imports`, U2a) closes A2 and A3's symlinked-file half ... but not paths through a symlinked directory, other names ..., or absolute imports" (`docs/working/known-issues-dev-cycle.md:18`). A2 and A3 describe the working-tree walk. Precise version: cite A4 (which builds on A2/A3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:451-453`, `:470`, `:542`; `docs/working/known-issues-dev-cycle.md:16-18`

---

## Claim 13: "Its result is cached for the commit and root in IMPORTED_MAIN_DONE."

**Location:** `scripts/lib/dev-cycle-read.sh:453-454`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cache key; does not establish freshness when untracked checkout files change between calls in one process (not part of the key, and not claimed).

`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` and `IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"` (`:513-514`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-514`

---

## Claim 14: "UTF-8 spaces that end an import token, as a blank does: U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F and U+3000."

**Location:** `scripts/lib/dev-cycle-read.sh:456-461`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the 18 byte sequences decode to exactly the named code points and that `import_targets` cuts at the first one; does not establish that Claude Code's own tokenizer stops at the same set.

X8 decoded `UNI_SPACES` with `uni.py`: 18 entries, `['0xa0', '0x1680', '0x2000', ..., '0x200a', '0x2028', '0x2029', '0x202f', '0x205f', '0x3000']`, and printed `matches the comment's list: True`. Cut: `for u in "${UNI_SPACES[@]}"; do t="${t%%"$u"*}"; done` (`:469`). Test 5's `@docs/nb.md\xc2\xa0for` refuses `docs/nb.md` (X1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:456-469`, run X8 (`$S/probes2.log`), run X1

---

## Claim 15: "The import targets in the text on stdin, for a file in directory $1 ("" at the top level): one repo-relative path per line, case kept."

**Location:** `scripts/lib/dev-cycle-read.sh:463-464`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers import_targets' input and output contract; does not establish token-rule parity with Claude Code (override row: backslash and trailing-`_` forms).

`p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)" || continue` / `[[ "$p" != ..* ]] || continue` / `printf '%s\n' "$p"` (`:471-473`). Input: `done < <(env LC_ALL=C grep -oE "$IMPORT_RE" || true)` (`:474`). There is no lower-casing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:463-475`

---

## Claim 16: instruction_names / untracked_md comments ("one grep, before the tree walk forks ...", "--others without --exclude-standard already lists ignored files")

**Location:** `scripts/lib/dev-cycle-read.sh:477-484`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that these two helpers keep the moved logic unchanged; does not establish their speed claim ("took seconds"), which this branch did not change.

`instruction_names() { env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$' || true; }` and `untracked_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; }`. These are the same commands the old inline code at `imported_names` ran (diff `-` lines). `git ls-files --others` without `--exclude-standard` includes ignored files (standard git behaviour).

**Evidence:** `scripts/lib/dev-cycle-read.sh:477-484`, `git diff main...HEAD -- scripts/lib/dev-cycle-read.sh`

---

## Claim 17: "returns 1, with IMPORTED_MAIN set to "error", when the commit's tree cannot be listed whole, lists a name twice (git would read the first copy, whatever its mode) or a blob cannot be read ... The listing stays NUL-separated as git writes it (a name may hold a newline), with its exit status after the last NUL. Queue items are "m:PATH" ... or "t:PATH""

**Location:** `scripts/lib/dev-cycle-read.sh:503-508`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed failure triggers for blob paths as `ls-tree -r` prints them. Does not establish failure for a name doubled as a symlink plus a directory, or as two directories. `-r` does not print trees, so such a name is not "listed twice". The walk fails only if it reads a path under it (E3, E8, E10b fail closed; E10a, with nothing walked there, does not fail). Also does not establish import extraction from a blob holding a NUL byte: E7, where grep says "binary file matches" and the import `docs/n.md` passes. This behaviour is shared with the tree walk.

The status rides after the last NUL: `mapfile -d '' recs < <(git ls-tree -r -z --full-tree "$MAIN_SHA"; printf 'rc=%s' "$?")` / `[[ "${recs[-1]}" == rc=0 ]] || return 1` (`:516-517`). A doubled name fails: `[[ -z "${ent[$f]+set}" ]] || return 1` (`:522`). A failed blob read fails: `|| { IMPORTED_MAIN=error; return 1; }` (`:545`). X1 test 3 (missing blob) and test 4 (doubled `a.md`, doubled start `AGENTS.md` with the symlink first, doubled `z.txt`) refuse with the walk-failure reason. Test 4's newline names, including the forged-record shape, are read, and their imports are refused. X5 mutant `dupH` (`:522` deleted) fails test 4. X8 confirms git reads the first of two `AGENTS.md` entries (`read: x`, the symlink text).

**Evidence:** `scripts/lib/dev-cycle-read.sh:503-561`, `test/scripts/build-loop-check.bats:82-131`; runs X1, X2 (`$S/h.log` E3, E7, E8), X3 (`$S/h2.log` E10a, E10b), X5 (`$S/mut.log`), X8

---

## Claim 18a: "Returns 0 imported, 1 not, 2 when the main walk failed or $1 is neither"

**Location:** `scripts/lib/dev-cycle-read.sh:564`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three return codes; does not establish how a caller that is not floor uses them (Claim 18b).

`main) main_imports || return 2; ...`, `tree) imported_names; ...`, `*) return 2 ;;` (`:571-573`). X6: `isimported main` after `MAIN_BY_NAME=""` gave `rc=2`. X8: `isimported foo x` gave `rc=2`. A run in the worktree printed `rc=2` for `Main` and `rc=1` for a missing path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-575`, runs X6 (`$S/ifprobe.log`), X8

---

## Claim 18b: "(fail closed: a caller that tests it with `if` refuses)"

**Location:** `scripts/lib/dev-cycle-read.sh:565`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how `if isimported ...` treats return 2; does not establish anything about floor, which reads the code explicitly and does refuse on 2 (`:609-610`).

`if` branches on zero versus non-zero, so 2 takes the same branch as 1, "not imported". X6 ran `if isimported foo "$P"; then echo "...refuse"; else echo "...else-branch taken"; fi` and the same for `main` with the walk failed. Both printed `else-branch taken`. A caller written the natural way, `if isimported main "$p"; then refuse; fi`, fails *open* on a failed walk. Fail-closed handling needs the code itself, as floor reads it: `elif rc=0; isimported main "$lp" || rc=$?; [[ "$rc" -ne 1 ]]; then` (`:609`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-575`, `:609-611`; run X6 (`$S/ifprobe.log`)

---

## Claim 19: ownfile's comment: working docs `docs/working/{research,plan,checkpoint,handoff,test-strategy}-STEM.md`, and an added review `docs/reviews/STEM.md` or `NAME-STEM.md` ("a modified or deleted review is never its own")

**Location:** `scripts/lib/dev-cycle-read.sh:576-587`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working-doc and review rules and the empty-stem guard; does not establish that working docs depend on the status letter (they do not, and the comment does not say they do).

`[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`:586`). X1 test 2 shows: added own-name reviews pass; `-xy`, `-notes`, a subdirectory and a `D` status refuse; an empty stem owns nothing. Test 1 shows that `plan-x.md`, `plan-2026-10-01-xy.md` and a nested `scratch/plan-...` refuse, and `Research-`/`test-strategy-` own docs pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:576-587`, `test/scripts/build-loop-check.bats:33-80`, run X1

---

## Claim 20: "The gate's own code: main's copy runs the next merge (plan D6), so a change to it lands only through a merge-gate- review entry"

**Location:** `scripts/lib/dev-cycle-read.sh:588-590`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the GATE_CODE pattern against plan D5 item 3 (the pattern covers all of `scripts/lib/`, a superset of the item's one lib file); does not establish D6's snippet, which is U3b's.

`GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/'`. Plan D5 item 3: "the gate's own code (`scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/questions.sh`, `scripts/lib/dev-cycle-read.sh`). D6 runs main's copy ..." (`plan:71`). X1 test 1 refuses `scripts/lib/new.sh` and `Scripts/Build-Loop.sh` with the gate reason, and passes `scripts/other.sh`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:588-590`, `docs/working/plan-build-loop-handoff.md:71`, run X1

---

## Claim 21: floor's comment ("plan D5 ... Returns 0 with FLOOR_WHY set when the floor refuses, else 1 ... lower-cased ... Floor item 5 ... is the caller's mode rule ...") and `FLOOR_WHY="" # read by floor's caller (U2c's --check)`

**Location:** `scripts/lib/dev-cycle-read.sh:591-600`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's reasons against D5 items 1-4 (plus `docs/dev-cycle.md` and non-own reviews), return codes and lower-casing; does not establish item 5 or the own-brief Status rule, which the comment assigns to the caller.

D5 items 1-4 (`plan:69-72`) map to `:606` (instruction file), `:607` (`"/$lp" == */.*`, which also catches `.envrc` per the 2026-10-05 amendment), `:608` (gate), `:609-611` (imports) and `:612-616` (item 4). The function ends `else return 1; fi` (`:617`). X1 test 1 checks every reason string, including `Agents.MD`, `Docs/Imported.md` and `Docs/Roadmap.md`. Plan step 5 puts "the floor" in U2c (`plan:276`), which matches the FLOOR_WHY reader.

**Evidence:** `scripts/lib/dev-cycle-read.sh:591-618`, `docs/working/plan-build-loop-handoff.md:66-73`, `:276`, run X1

---

## Claim 22: check_fix header and comment: refuses `constraints.md (the user's: plan D2)`

**Location:** `scripts/dev-cycle.sh:49-55`, `:166-171`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the constraints.md refusal, docs/thoughts/ staying fixable and the switch to `isimported tree`; does not establish the rest of the pre-existing list.

`|| "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || ...` and `elif isimported tree "$lp"; then` (`:181-183`). Plan D2: "Creating the doc is your work" (`plan:50`). The X1 dev-cycle.bats `--check-fix` test asserts `skip docs/Constraints.md: in-cycle fixes edit only` and `ok docs/thoughts/t.md`.

**Evidence:** `scripts/dev-cycle.sh:49-55`, `:166-186`; `docs/working/plan-build-loop-handoff.md:50`; `test/scripts/dev-cycle.bats:1013-1029`; run X1

---

## Claim 23: SKILL.md: "--check-fix ... (not ... `docs/dev-cycle.md`, `docs/constraints.md`, a dot-directory ...)"

**Location:** `skills/dev-cycle/SKILL.md:72-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the added `docs/constraints.md` item; does not establish the rest of the paragraph.

The script's check is quoted in Claim 22 (`scripts/dev-cycle.sh:181`).

**Evidence:** `skills/dev-cycle/SKILL.md:72-75`, `scripts/dev-cycle.sh:181`

---

## Claim 24: "Markup that adds letters (a checked task box, a tag) can still hide a copy"

**Location:** `scripts/build-loop.sh:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the letters-only fold; does not establish other markup cases.

`s = tolower($0); gsub(/[^a-z]/, "", s)` then `index(s, "buildlooppolicy") == 1` (`:155-156`). `- [x] Build-loop policy:` folds to `xbuildlooppolicy`, which is missed. An unchecked `- [ ]` adds no letter, hence "checked".

**Evidence:** `scripts/build-loop.sh:143-160`

---

## Claim 25: "A tip on a branch not ahead of main, or whose subject does not start "handoff:", is working."

**Location:** `scripts/build-loop.sh:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `working` default; does not establish check_branch's `ahead` computation.

`loop=working` / `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`:352-354`), and `[[ "$subj" == handoff:* ]] || { echo working; return; }` (`:286`).

**Evidence:** `scripts/build-loop.sh:279-290`, `:345-361`

---

## Claim 26: "An inherited GIT_DIR (a run from a git hook, say) would send every fixture command to that repo instead of the throwaway one."

**Location:** `test/lib/build-loop-fixtures.bash:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers git's environment precedence (GIT_DIR overrides discovery); does not establish that every repo-locating variable is listed.

`unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES` (`:13`). GIT_DIR overriding repository discovery is documented git behaviour (paraphrased — no quote available because the claim is about git's documented environment handling, not repo code).

**Evidence:** `test/lib/build-loop-fixtures.bash:11-13`

---

## Claim 27: build-loop-check.bats titles and comments (e.g. "Untracked local instruction files add imports; a working-tree edit of a tracked one does not", "A start file listed twice (a symlink first, which git reads)", "Start files under directories whose names hold a newline are read ... (a forged symlink line)", "floor follows what Claude Code loads: symlinks, any name main stores, the checkout's files, .claude/rules/, a token ended by a Unicode space")

**Location:** `test/scripts/build-loop-check.bats:3-6`, `:40-41`, `:98-133`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each test's assertions match its title/comment and pass; does not establish that "symlinks" in test 5's title covers every symlink text (Claim 10).

All five tests pass (X1). Test 1 asserts `docs/wt-only.md -` and `docs/private.md` refused. Test 4 asserts the record count is 2 (`:127`) and refuses `docs/d.md`/`docs/p.md`. X8 confirms git reads the first (symlink) copy of a doubled `AGENTS.md`. X5: deleting the doubled-name guard fails test 4.

**Evidence:** `test/scripts/build-loop-check.bats:1-152`, runs X1, X5, X8

---

## Claim 28: edited dev-cycle.bats / build-loop-read.bats comments ("docs/constraints.md is the user's (plan D2); docs/thoughts/ stays a living doc the cycle may fix", "one commit on top of base, with its tree")

**Location:** `test/scripts/dev-cycle.bats:1023`, `test/scripts/build-loop-read.bats:297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two edited comments and the renamed main_entry test; does not establish unedited tests.

The T7 object is `tree <base^{tree}>`, `parent <base>` (`build-loop-read.bats:298`). The dev-cycle.bats assertions match the comment (Claim 22). All tests pass (X1).

**Evidence:** `test/scripts/build-loop-read.bats:297-299`, `test/scripts/dev-cycle.bats:1013-1029`, `:1335-1345`, run X1

---

## Claim 29: known issue A4: "The gate's walk (`main_imports`, U2a) closes A2 and A3's symlinked-file half for the self-merge floor (symlinked start files and targets are followed, `.claude/rules/` starts), but not paths through a symlinked directory, ... and its untracked start files come from the checkout the gate runs in."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "closes ... symlinked-file half" assertion and the listed residue; does not establish case-insensitive behaviour (not probed).

Symlinked starts and targets are followed for ordinary texts (test 5, E4, E5). The symlinked-file half is not fully closed, though: a symlink whose text ends in a newline is followed to the wrong path, and its real target's imports pass (Claim 10, E1/E10c). An absolute symlink text is skipped (`:548`) and is not in the residue list. The residue list is otherwise accurate. Separately, the new row reuses the ID A4. The same file's preamble says "R1 (the `_`/`*` token cut) and A4 (the `--check-fix` slowdown) were fixed on `fix/dev-cycle-import-re`" (`known-issues-dev-cycle.md:8`), so "known issue A4" now names both a fixed issue and an open one in one document. Those are pass-38 rubric IDs, but the table's other IDs (A2, A3, C2-C4) reuse the same scheme.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:546-550`, runs X2, X3

---

## Claim 30: plan F10 row: "Floor item 4 (lib `floor`): `docs/decisions/`, `docs/thoughts/`, `docs/human-author/`, `docs/constraints.md`, the cycle files, other briefs' working docs and reviews; ... `check_fix` ... now refuses `docs/constraints.md` too but still fixes `docs/thoughts/`"

**Location:** `docs/working/plan-build-loop-handoff.md:125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the floor list and the check_fix difference; does not establish T10's full gate test (U2c).

Matches `floor` (`lib:612-616`) and check_fix (Claim 22). Tests 1-2 and the `--check-fix` test pass (X1).

**Evidence:** `docs/working/plan-build-loop-handoff.md:125`, `scripts/lib/dev-cycle-read.sh:612-616`, run X1

---

## Claim 31: plan F11 row: "Floor item 1 walks main's commit (`main_imports`, U2a: one NUL-safe listing, symlinks followed, `.claude/rules/` and the checkout's untracked instruction files as starts). Gaps: known issue A4 ..."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the listed mechanisms; the row is marked **partly** and does not claim completeness, so the newline-tail symlink gap (Claim 10) is residue that the row does not list, not a contradiction.

NUL-safe listing (`lib:516`), symlinks (`:546-550`), starts (`:534`); tests 4-5 pass (X1).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:516-560`, run X1

---

## Claim 32a: "U1 measured four units against a planned one"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unit count from merge commits on main; does not establish the original plan's count beyond step 3's single U1.

`git log --oneline main` has merges of `feat/build-loop-u1a`, `-u1b`, `-u1c` and `-u1d`. Step 3 lists one "U1 code" unit (`plan:270`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:270-273`, `git log --oneline main`

---

## Claim 32b: "U2 carries about twenty override rows"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers rows on main whose revisit trigger names U2 as a word; does not establish which of them the author counted.

`git show main:docs/reviews/override-log.md | grep '^| 2026' | grep -ciE 'trigger:[^|]*\bU2\b'` gives 26. Precise version: "about twenty-five".

**Evidence:** `docs/reviews/override-log.md` (main), `docs/working/plan-build-loop-handoff.md:273`

---

## Claim 32c: U2a bullet: "an import walk that reads main's commit (one `ls-tree -r`, then each instruction blob), started from main's instruction files plus the checkout's untracked ones (they can only add refusals)"

**Location:** `docs/working/plan-build-loop-handoff.md:274`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the walk description in the split note; does not establish the rest of the bullet (which is accurate: floor, ownfile, isimported, badform, isclosed, constraints.md).

This was written at b9ffe7a8, and db9cc040 did not update it (only F10/F11 changed in the plan). The walk now also starts at `.claude/rules/*.md` (`lib:534`), reads every imported blob, not only instruction blobs (`:545`), follows symlinks (`:546-550`) and reads checkout targets (`:542`, `:559`). Precise version: the F11 row's description.

**Evidence:** `docs/working/plan-build-loop-handoff.md:274`, `git show db9cc040 -- docs/working/plan-build-loop-handoff.md`, `scripts/lib/dev-cycle-read.sh:526-560`

---

## Claim 33a: commit db9cc040: R1/A5-A14 bullets, "11 override rows", "grows past the 400-line cap", "Walk parity with the tree walk re-measured on this repo (same set); main_imports ~0.45 s here."

**Location:** commit db9cc040 message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed bullets, the row count, the size and the parity/timing measurements; does not establish the "waiver entry is filed at merge" promise (future act).

- 11 rows added by db9cc040 (`git show db9cc040 --stat`: `override-log.md | 11 +`).
- X9 gives 479 code lines (> 400).
- X3/E11: `IMPORTED_MAIN` and `IMPORTED` both hold 3 paths, and `diff` printed `SAME`.
- X4: main_imports 0.367-0.392 s over 3 runs, within normal run variance of "~0.45 s".
- A5/A6/A7/A8/A10/A14 match `lib:559`, `:469`, `:534`/`:546`, `:571-573`, `:124-125` and `:513`.

**Evidence:** runs X3 (`$S/main.set`, `$S/tree.set`), X4 (`$S/timing.log`), X9; `scripts/lib/dev-cycle-read.sh:509-575`

---

## Claim 33b: commit db9cc040 R1 bullet (and rubric R1 author note): "every name goes into one map, and a name listed twice, of any kind, fails the walk"

**Location:** commit db9cc040 message; `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:40`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers doubled names in the `-r` listing; does not establish any fail-open from doubled tree names (none found: E3, E8 and E10b fail closed on the read).

The map holds only what `ls-tree -r` prints (blobs, symlinks, gitlinks), not trees. A name stored as both a symlink and a directory (E10a: `docs` twice) or as two directories does not fail the walk by itself. E10a's `docs/x.md` and `z.md` passed with no walk failure. The walk fails only when it reads a path under the doubled name (E3: `cat-file` of `docs/x.md` fails). Precise version: "any blob path listed twice, of any mode, fails the walk; a doubled directory name fails it once a walked read lands under it."

**Evidence:** `scripts/lib/dev-cycle-read.sh:516-523`, runs X2 (E3, E8), X3 (E10a, E10b)

---

## Claim 33c: commit db9cc040 Notes: "the early-split trigger fired (3 Incorrect in main_imports)"

**Location:** commit db9cc040 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count and location of the iteration-2 Incorrects; does not establish the split decision.

The iteration-2 report lists 3 Incorrect, all on the main_imports defect. Only Claim 11 is located in main_imports (`lib:506`). Claim 15b is a test title (`build-loop-check.bats:98`) and Claim 16a is commit 36b79f72's message (`docs/reviews/code-fact-check-report-build-loop-u2a.md`, "Claims Requiring Attention"). Precise version: "3 Incorrect on main_imports' defect".

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a.md` (Claims Requiring Attention)

---

## Claim 34: commit 36b79f72: "Every record must now start with a mode, a type and an object id, and any name listed twice (any mode) fails the walk. Tests: both shapes in build-loop-check.bats; deleting either guard fails the test." / "three override rows"

**Location:** commit 36b79f72 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard-deletion claim at 36b79f72 and the row count; the split-record defect it left is Claim 33a's R1 (reopened, fixed at db9cc040).

X5: at 36b79f72, deleting the record-regex guard fails test 4, and deleting the `listed` guard fails test 4. `git show 36b79f72 --stat` adds 3 override rows.

**Evidence:** run X5 (`$S/mut.log`), `git show 36b79f72`

---

## Claim 35: commit b9ffe7a8: "floor PATH STEM STATUS (plan D5 items 1-4) ... main_imports walks main's commit ... Agrees with the working-tree walk on this repo ... 393 changed code lines."

**Location:** commit b9ffe7a8 message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the size count (executed) and the bullets as they describe b9ffe7a8's code (the main_entry-per-target walk, since replaced); parity at b9ffe7a8 itself was not re-run (it holds at HEAD, X3).

X9: `git diff --numstat main...b9ffe7a8 -- ':(top)' ':(top,exclude)docs/' | awk ...` gives 393. At b9ffe7a8 the walk's comment says it "follows an import only into a regular file on that commit (main_entry blob); a target pathform refuses is listed, not followed" (`git show b9ffe7a8:scripts/lib/dev-cycle-read.sh`), which matches the "parity gap ... documented" note.

**Evidence:** run X9, `git show b9ffe7a8:scripts/lib/dev-cycle-read.sh` (main_imports comment)

---

## Claim 36: commit cfbf34d2: "including the walk failing closed (missing blob, a tree listing a name twice, no main by name)" and "these fail until the U2a code commit"

**Location:** commit cfbf34d2 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two statements already settled as Accepted-immutable (override rows for iteration-1 Claims 28-29); does not re-litigate them.

X7 ran the three suites at cfbf34d2: 11 `not ok`, including tests 1-4, the `--check-fix`, inventory, check_answer and main_entry tests. One of them, #81 (`--settings on this repo's own docs/dev-cycle.md`), fails only because the archive has no `docs/`. The build-loop-read rows 317/318 tests pass, as the existing override row says. At cfbf34d2, "a tree listing a name twice" covered a doubled target only (iteration 1's finding).

**Evidence:** run X7 (`$S/at-cfbf.log`), `docs/reviews/override-log.md` (rows for Claims 28, 29)

---

## Claim 37: rubric iteration-2 section (report and critic counts, A-rows, "C2-C11 ... Override rows")

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:32-54`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts, the A-row fix descriptions and the C-range label; R1's "of any kind" is Claim 33b.

These hold:
- The fact-check report shows `**Summary:** 16 verified, 5 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable`.
- Severity counts: security 3 Medium + 1 Informational; performance Low + Informational; api 1 Inconsistent + 4 Minor + 3 Informational; architecture 5 Minor + 2 Informational.
- A5-A14 match the code (Claim 33a).

The miss: `C2-C11` labels 10 IDs, but its own Source column lists 11 sources (api 4, 6, 7; performance F1, F2; architecture 2, 3, 6; security F3 residue, F4; FC 5b), and db9cc040 adds 11 override rows. Precise version: C2-C12.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:36`, `:52`; the four critic reports' `**Severity:**` lines; `git diff main...HEAD -- docs/reviews/override-log.md`

---

## Claim 38a: override rows added on this branch (14), excluding 38b-38c

**Location:** `docs/reviews/override-log.md:321-334`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the checkable factual parts; dispositions and future triggers are decisions, not claims.

Checked parts:
- "45 files here": 45 instruction-named paths on main.
- floor and isimported each lower-case the path (`lib:605`, `:569`).
- "Stated in floor's comment" (`:597-598`).
- The A4/F11/Q-103 cross-references exist.
- "the start-file rule is spelled in both walks" (`:534` and imported_names).

**Evidence:** `docs/reviews/override-log.md:321-334`, `scripts/lib/dev-cycle-read.sh:534`, `:569`, `:597-605`

---

## Claim 38b: override row: "entry_why always names the path, so --check-brief and --check-answer skip lines repeat it"

**Location:** `docs/reviews/override-log.md:324`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which entry_why arms name `$2`; does not establish how readers find the repetition.

Only `notfile`, `badform` and the default arm print `$2`. `notdir` prints `"${1#notdir } is not a directory on the default branch"`, and `error` prints `"the tree of the default branch could not be read"` (`lib:287`, `:290`). Precise version: "names the path for notfile and badform".

**Evidence:** `scripts/lib/dev-cycle-read.sh:284-293`

---

## Claim 38c: override row: "Parity on this repo was measured at each commit"

**Location:** `docs/reviews/override-log.md:330`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether a record of per-commit measurements exists; parity at HEAD was executed and holds (Claim 33a).

No artifact records the measurements at b9ffe7a8 and 36b79f72. The commit messages assert them (paraphrased — no quote available because the claim concerns absent artifacts). Verifying needs a re-run at each commit or the session's logs.

**Evidence:** commits b9ffe7a8, db9cc040 messages; run X3

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:448-449`, `:546-550`): a symlink text ending in newline(s) is cut by `$(...)` and followed to the wrong path. Its real target's imports pass floor (E1: `secret.md: -`), so this fails open. An absolute text is skipped rather than followed.
- **Claim 18b** (`scripts/lib/dev-cycle-read.sh:565`): "a caller that tests it with `if` refuses" is false. `if` treats 2 like 1 (X6: else-branch taken), so only a caller reading the code, as floor does, fails closed.

### Stale
- **Claim 32c** (`docs/working/plan-build-loop-handoff.md:274`): the U2a walk description predates db9cc040 (no `.claude/rules/` starts, symlinks, any-blob or checkout-target reads).

### Mostly Accurate
- **Claim 3** (`lib:15-17`): isimported with an unknown walk name returns 2 without need_root.
- **Claim 4** (`lib:30-33`): floor also reads checkout copies of targets main lacks and untracked `.claude/rules/` starts.
- **Claim 12** (`lib:451-453`): the gate walk's gaps are known issue A4, not A2/A3.
- **Claim 29** (`known-issues-dev-cycle.md:18`): "closes ... symlinked-file half" misses the newline-tail and absolute symlink texts. The ID A4 collides with the preamble's fixed "A4 (the `--check-fix` slowdown)" (`:8`).
- **Claim 32b** (`plan:273`): 26 rows name U2, not "about twenty".
- **Claim 33b** (db9cc040, rubric R1): only blob paths are in the map; a doubled directory name fails only on a read under it.
- **Claim 33c** (db9cc040 Notes): 1 of the 3 Incorrects is in main_imports; the others are a test title and a commit message.
- **Claim 36** (cfbf34d2): already Accepted-immutable.
- **Claim 37** (rubric `:52`): C2-C11 labels 10 IDs for 11 rows.
- **Claim 38b** (override row): entry_why names the path only for notfile/badform/default.

### Unverifiable
- **Claim 38c** (override row): per-commit parity measurements have no artifact; a re-run at b9ffe7a8 and 36b79f72 would settle it.
