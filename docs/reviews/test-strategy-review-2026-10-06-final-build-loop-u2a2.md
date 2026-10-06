Commit: 7697c6e6

# Test Strategy: feat/build-loop-u2a2 final pass (import_targets, isimported tree; C12/C13 test rows)

**Scope:** net `git diff main...HEAD` (main 20347279, HEAD 7697c6e6). Code: scripts/lib/dev-cycle-read.sh (UNI_SPACES, import_targets, instruction_names, untracked_md, imported_names, isimported, inrepo/inrepo_here), scripts/dev-cycle.sh check_fix. Tests: test/scripts/build-loop-check.bats (new, 2 tests), test/scripts/fixture-git-env.bats (C12), test/scripts/dev-cycle.bats (inventory, entry_why one-arg C13).
**Reviewed:** 2026-10-06 (final confirming pass, iteration 3)
**Method:** 36 single-point mutants of the lib and check_fix, plus 6 mutants of the fixture setups. Each ran in a scratch copy (`git archive HEAD` into /tmp/u2a2f-ts-WNbd, with its own `git init`). The worktree was never edited. Lib mutants ran against build-loop-check.bats plus dev-cycle.bats filtered to `import|check-fix|instruction files|sourcing the reader lib`. Survivors that the filter could have missed were re-run against the full dev-cycle.bats and build-loop-read.bats. Baseline at HEAD: 100 ok on the five-suite list in the shared context.

## Test Conventions

- bats, `bats_require_minimum_version 1.5.0`. Tests use `run --separate-stderr` with explicit `|| { echo "$output $stderr"; return 1; }` diagnostics, and test names end with the unit tag (`(U2a2)`).
- build-loop-check.bats loads test/lib/build-loop-fixtures.bash. `bl_setup` makes a throwaway repo under `$BATS_TEST_TMPDIR`, runs `unset $(git rev-parse --local-env-vars)`, and sets a hermetic config and `LC_ALL=C`. `commit_all` commits everything.
- Helpers: `imps WALK PATH...` runs under `timeout 60` and prints `walk: ok|failed`, then `PATH: imported|-` from `isimported WALK` for each path. `want PATH WORD` checks for an exact line.
- dev-cycle.bats drives `--check-fix` end to end. Lib-level tests source the lib under `set -euo pipefail` with `LC_ALL=C`.

## Mutation results at HEAD

**Killed** (the suite pins the rule):
- M01: no UNI_SPACES cut (killed by build-loop-check test 1).
- M02: U+FEFF dropped from the list (t1).
- M06: no punctuation strip (t1, and dev-cycle's "reads an import token whole").
- M07: stripped name only (t1: `docs/st.md.`).
- M08: whole name only.
- M11: old `..*` filter (t1: `..x.md`).
- M13: no `grep -a` (t1).
- M16: the importing file's directory always "".
- M17: no `seen` check (t1, through the 60 s timeout on its cycle).
- M19: no `lower` into IMPORTED.
- M21: an unknown walk name answers 1 (t2).
- M23: no untracked listing.
- M24: no `GIT_LITERAL_PATHSPECS=0`.
- M26, M27: instruction_names without the suffix arm or without `-i`.
- M33, M34: check_fix calls an unknown walk name, or skips the import arm.
- M35: IMPORT_RE without its boundary.
- M36: the tree arm does not call the walk.
- M32: inrepo without need_root (killed by dev-cycle's "the lib's file checks stop" in the full suite).

**C12 is load-bearing.**
- Narrowing the unset in dev-cycle.bats or build-loop-fixtures.bash to `unset GIT_DIR` (F1, F3) fails fixture-git-env.bats. So does removing it (F2).
- The same narrowing passes once the new `cmp` line (fixture-git-env.bats:27) is deleted (F4, F5). The index check catches it; the commit count does not.
- The new inner filter ('check-answer needs a default branch found by name') stages a file (`git add -A`, dev-cycle.bats:1209), as row 331 required.

**C13 is load-bearing.** dev-cycle.bats:1343 `entry_why error` fails under `p="$2"` (`$2: unbound variable`).

**Survived, but equivalent or over-refusing only** (no test recommended):
- M09: no `break`. It only duplicates output lines, and the dev-cycle cache test happened to kill it anyway.
- M10: no `~` filter. `~x` becomes a repo path, which over-refuses.
- M12: no `..` filter. `../x` lands in IMPORTED, but `inrepo_here` blocks at `..`, no caller asks about it, and pathform refuses `..`.
- M18, M28: queueing on `-f` instead of `inrepo_here`, and starting without `inrepo_here`. Both follow symlinks, so they read more and refuse more.
- M29: no start dedupe. The tracked and `--others` listings are disjoint.
- M30: no cache. It gives the same answers, recomputed.

**Survived, and fail-open or masking a claim a test name makes** (gaps G1-G8 below):
- M03, M04: any UNI_SPACES entry other than U+00A0 and U+FEFF.
- M05: `%%` changed to `%`.
- M14: reading stops at the first NUL.
- M15: realpath without `-m`.
- M20: isimported without `lower`.
- M22: the untracked listing without `icase`.
- M25: instruction_names without `skill`.
- M31: isimported without need_root.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:453-455, :472 — the 17 UNI_SPACES entries other than U+00A0 and U+FEFF. Dropping U+3000 (M03) or U+2028 (M04) from the list passes every test. Test 1 exercises 2 of the 19 — not covered
- **G2** — scripts/lib/dev-cycle-read.sh:472 — the cut takes the longest suffix (`%%`), so a token ends at its first Unicode space. With `%` (M05), `@docs/nb.md<NBSP>for<NBSP>you` reads `docs/nb.md<NBSP>for` and docs/nb.md is missed. Test 1's run holds only one NBSP — not covered
- **G3** — build-loop-check.bats:29, :31, :37 — test 1's name claims "a NUL hides no import". Its only target after the NUL (docs/b.md) is also imported by docs/c.md's `@b.md`, so a reader that stops at the first NUL (M14) passes. This confirms Stage 1's Mostly-accurate note — covered vacuously
- **G4** — scripts/lib/dev-cycle-read.sh:476 — `realpath -m`: without `-m` (M15), a token through a missing directory is dropped. Example: `@gone/../docs/m.md`, which Claude Code resolves lexically to docs/m.md — not covered
- **G5** — scripts/lib/dev-cycle-read.sh:509-517 — isimported's "path $2 (any case)". Its own `lower` is untested because check_fix passes `$lp`, which is already lower-cased. U2a3/U2a4 callers will pass paths as written. Without `lower` (M20), `Docs/NB.MD` answers `-` — not covered
- **G6** — scripts/lib/dev-cycle-read.sh:490 — `icase` in untracked_md. Without it (M22), an untracked `docs/AGENTS.MD` is not listed, although INSTRUCTION_FILE's lower-cased test treats it as an instruction file. dev-cycle's "any case" test uses tracked names and an untracked, lower-case CLAUDE.local.md — not covered
- **G7** — scripts/lib/dev-cycle-read.sh:487 — the `skill` arm of instruction_names. No test uses a SKILL.md start file, so dropping the arm (M25) silently loses every SKILL.md's imports — not covered
- **G8** — scripts/lib/dev-cycle-read.sh:516 — isimported's own need_root. The lib header (:15) lists isimported among the checks that exit 1 without ROOT_REAL. Only the unknown-name arm depends on it, because the tree arm reaches imported_names' need_root. Without it (M31), `isimported bogus x` with ROOT_REAL unset answers 0 instead of stopping. It fails closed either way — not covered (low)
- **G9** — scripts/lib/dev-cycle-read.sh:456, :481 — an `@` right after a UNI_SPACES character (Stage-1 E1: Medium, fail-open, not a regression). `grep -aoE` runs through the space's bytes, so one match swallows the next token: `@docs/a.md<NBSP>@docs/b.md` reads only docs/a.md. A test fails at HEAD (executed: `docs/b.md: -`) and belongs with the fix — not covered, code defect

## Recommended Tests

All are checked patches to test/scripts/build-loop-check.bats, in the Appendix. Patch A passes at HEAD. Patch B's test fails at HEAD by design and passes with the candidate fix shown beside it.

#### Tighten test 1: two NBSPs in one run, a target only after the NUL, a missing directory, mixed-case queries

**Closes gaps:** G2, G3, G4, G5
**Type:** integration (fixture repo)
**Priority:** high for G3 (the test name makes a claim its fixture does not prove) and for G5 (U2a3/U2a4 will call isimported with paths as written); medium for G2; low for G4
**File:** test/scripts/build-loop-check.bats, test 1 (lines 27-39)
**What it verifies:** the token ends at its first Unicode space; an import after a NUL is read; a path through a missing directory is resolved as written; isimported lower-cases its argument.
**Key cases:**
- `@docs/nb.md<NBSP>for<NBSP>you,` → docs/nb.md imported (kills M05)
- `@docs/a.md\0 then @docs/z.md`, with z.md imported nowhere else → docs/z.md imported (kills M14)
- `@gone/../docs/m.md`, with gone/ absent → docs/m.md imported (kills M15)
- queries `Docs/NB.MD` and `CLAUDE.md` → imported (kills M20)
**Setup needed:** none.

#### isimported stops without ROOT_REAL for an unknown walk name

**Closes gaps:** G8
**Type:** unit (lib sourced)
**Priority:** low (it fails closed either way; this pins the header's contract)
**File:** test/scripts/build-loop-check.bats, appended to test 2 (lines 41-45)
**What it verifies:** with ROOT_REAL unset, `isimported bogus docs/z.md` exits 1, prints nothing and reports "ROOT_REAL is not set".
**Key cases:** as stated (kills M31).
**Setup needed:** none.

#### Every Unicode space ends a token; SKILL.md and an untracked upper-case .MD start the walk

**Closes gaps:** G1, G6, G7
**Type:** integration (table over the 19 code points)
**Priority:** medium for G1 (each missing entry is a fail-open import, and the list is hand-encoded bytes) and for G7 (INSTRUCTION_FILE names SKILL.md, but no test walks one); low for G6
**File:** test/scripts/build-loop-check.bats (new test 3)
**What it verifies:** a tracked sub/SKILL.md holds `@../docs/uN.md<space N>x` for each of the 19 non-ASCII code points in JavaScript's `\s`, and every docs/uN.md is imported. An untracked docs/AGENTS.MD's `@k.md` imports docs/k.md.
**Key cases:**
- each of U+00A0, U+1680, U+2000-200A, U+2028, U+2029, U+202F, U+205F, U+3000, U+FEFF → docs/uN.md imported (kills M01-M04). The test's byte list was derived from the code points with Python, independently of the lib, and matches the lib's list.
- untracked docs/AGENTS.MD → docs/k.md imported (kills M22)
- every docs/uN.md also needs SKILL.md to start the walk (kills M25)
- docs/other.md → `-`
**Setup needed:** none.

#### An @ right after a Unicode space starts a token (with the E1 fix)

**Closes gaps:** G9
**Type:** integration
**Priority:** high once E1 is fixed (Medium, fail-open). U2a3's main_imports shares import_targets, so the same test guards both walks.
**File:** test/scripts/build-loop-check.bats (new test 4)
**What it verifies:** `@docs/a.md<NBSP>@docs/b.md` imports both files, and `x<U+3000>@docs/c.md` imports docs/c.md.
**Key cases:** at HEAD, docs/b.md answers `-` (executed). The candidate fix runs one `sed` ahead of the grep to turn each UNI_SPACES character into a blank. With it, all three are imported and the five-suite list is 102 ok.
**Setup needed:** none. Whether the fix goes into U2a2 or is carried forward is the author's call. The test should land with whichever commit fixes E1.

## What NOT to Test

- **fixture-git-env.bats' own `unset` (line 13; F6 survives).** Proving it would mean running fixture-git-env.bats under an inherited GIT_DIR, so the suite would have to run itself. The line copies the one the suite already proves for the other two setups.
- **The `[` token-end rule.** import_targets' comment (:462) says `[` ends a token, but IMPORT_RE (:456) does not end there (Stage-1 Low). Pinning either behaviour before the author chooses between code and comment would lock in one side. The fix is a comment edit, and Claude Code's own regex ends at neither `[` nor `(`.
- **`(`, `)` or `]` inside a real intermediate name (Stage-1 E2).** Fail-open, but not a regression and outside this unit's changes. The test belongs with whoever next changes IMPORT_RE.
- **M09, M10, M12, M18, M28, M29, M30.** These are equivalent or only over-refuse (see Mutation results). A test would pin implementation, not behaviour.
- **The dev-cycle.bats inventory additions (:1086, :1089).** They are plain presence checks. They fail when a name is dropped, which is all they claim.

## Coverage Gaps Beyond Current Scope

**1.** The tree walk does not follow imports through a symlinked intermediate file (`inrepo_here` at :505 gates the queue), while Claude Code reads through symlinks. The target's own imports are then not refused. Main behaves the same way. This falls under the `feat/build-loop-u2a` rows on the walks' deliberate difference (row 347) and the symlinked-directory residue (row 350), so it is not re-filed.
**2.** Absolute imports into the repo (`@/abs/repo/docs/x.md`) are dropped at :475. Settled under row 350.
**3.** U2a3's main_imports shares import_targets. Patch A's test 3 and Patch B's test 4 should be mirrored there with `imps main`, so that a later parser change is caught through both walks.

## Summary

The highest-value addition is Patch A's tightening of test 1. Its name claims that a NUL hides no import, but the only target after the NUL is reachable another way. isimported's documented "any case" argument is also unpinned, just before U2a3 and U2a4 start calling it with paths as written. The 19-entry UNI_SPACES table, the longest-suffix cut, SKILL.md as a start file and the untracked `.MD` listing would each fail open silently if one token were deleted. Patch A's new test kills all of those mutants. After the patches, the main residual risk is Stage-1's E1: an `@` straight after a Unicode space is skipped. Patch B's test fails at HEAD, and a sed-based fix makes it pass with the full suite green. Mutation confirms that C12 and C13 are load-bearing. Open question for the author: fix E1 in U2a2 (about 4 lines, plus one `sed` fork per walked file), or carry the fix and its test to U2a3.

## Appendix: checked patches

**Patch A** (test only).
- Applied in scratch on top of 7697c6e6. `git apply --check` passes against a fresh `git archive 7697c6e6`.
- build-loop-check.bats: 3 ok.
- Run against each target mutant, all killed: M01, M02 (t1, t3); M03, M04, M22, M25 (t3); M05, M14, M15, M20, M17 (t1); M21, M31 (t2).

```diff
diff --git a/test/scripts/build-loop-check.bats b/test/scripts/build-loop-check.bats
index 9315730..28287f7 100644
--- a/test/scripts/build-loop-check.bats
+++ b/test/scripts/build-loop-check.bats
@@ -26,12 +26,15 @@ want() { printf '%s\n' "$output" | grep -qxF "$1: $2" || { echo "want: $1: $2";
 
 @test "tree walk shares the token rules: Unicode spaces end a token, punctuation is read kept and stripped, a ..x name is followed, a NUL hides no import, a cycle ends (U2a2)" {
     mkdir -p docs
-    printf 'See @docs/nb.md\xc2\xa0for, @docs/bom.md\xef\xbb\xbfnow, @docs/st.md. @..x.md and @docs/a.md\0 then @docs/b.md\n' > CLAUDE.md
+    # Two NBSPs in one run: the token ends at the first. docs/z.md is imported only after the NUL;
+    # gone/ does not exist, and the path is still resolved as written.
+    printf 'See @docs/nb.md\xc2\xa0for\xc2\xa0you, @docs/bom.md\xef\xbb\xbfnow, @docs/st.md. @..x.md @gone/../docs/m.md and @docs/a.md\0 then @docs/z.md\n' > CLAUDE.md
     printf 'hid @docs/hid.md\n' > ..x.md
     printf 'back @../CLAUDE.md, @c.md and @b.md\n' > docs/c.md
     printf 'see @docs/c.md\n' > AGENTS.md
     commit_all tree
-    ps=(docs/nb.md docs/bom.md docs/st.md docs/st.md. ..x.md docs/hid.md docs/b.md docs/c.md claude.md)
+    # Docs/NB.MD and CLAUDE.md: isimported takes a path in any case.
+    ps=(docs/nb.md docs/bom.md docs/st.md docs/st.md. ..x.md docs/hid.md docs/b.md docs/c.md claude.md docs/z.md docs/m.md Docs/NB.MD CLAUDE.md)
     imps tree "${ps[@]}" docs/other.md docs/nb.md.
     [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
     for p in "${ps[@]}"; do want "$p" imported; done
@@ -42,4 +45,24 @@ want() { printf '%s\n' "$output" | grep -qxF "$1: $2" || { echo "want: $1: $2";
     run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
         if isimported bogus docs/z.md; then echo "bogus: imported"; fi' _ "$LIB"
     [ "$output" = "bogus: imported" ] || { echo "$output $stderr"; return 1; }
+    # Without ROOT_REAL it stops (need_root) for any walk name, before answering.
+    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main
+        if isimported bogus docs/z.md; then echo "bogus: imported"; fi' _ "$LIB"
+    [ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"ROOT_REAL is not set"* ]] || { echo "$status $output $stderr"; return 1; }
+}
+
+@test "tree walk: every Unicode space JavaScript's \\s holds ends a token; SKILL.md and an untracked upper-case .MD start the walk (U2a2)" {
+    mkdir -p docs sub
+    # U+00A0, U+1680, U+2000-200A, U+2028, U+2029, U+202F, U+205F, U+3000, U+FEFF as UTF-8.
+    sp=('\xc2\xa0' '\xe1\x9a\x80' '\xe2\x80\x80' '\xe2\x80\x81' '\xe2\x80\x82' '\xe2\x80\x83' '\xe2\x80\x84'
+        '\xe2\x80\x85' '\xe2\x80\x86' '\xe2\x80\x87' '\xe2\x80\x88' '\xe2\x80\x89' '\xe2\x80\x8a' '\xe2\x80\xa8'
+        '\xe2\x80\xa9' '\xe2\x80\xaf' '\xe2\x81\x9f' '\xe3\x80\x80' '\xef\xbb\xbf')
+    ps=()
+    for i in "${!sp[@]}"; do printf "@../docs/u$i.md${sp[$i]}x\\n"; ps+=("docs/u$i.md"); done > sub/SKILL.md
+    commit_all spaces
+    printf 'See @k.md\n' > docs/AGENTS.MD
+    imps tree "${ps[@]}" docs/k.md docs/other.md
+    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
+    for p in "${ps[@]}" docs/k.md; do want "$p" imported; done
+    want docs/other.md -
 }
```

**Patch B** (a test, then a candidate fix; apply after Patch A).
- The test alone fails at HEAD (`want: docs/b.md: imported` / `docs/b.md: -`), so HEAD itself serves as its mutant.
- With the fix, the five-suite list is 102 ok, 0 not ok: the 100 at HEAD, plus Patch A's test 3, plus this test.
- The fix keeps NULs: test 1's post-NUL docs/z.md still passes. It makes the existing UNI_SPACES cut at :472 redundant but harmless.

```diff
diff --git a/test/scripts/build-loop-check.bats b/test/scripts/build-loop-check.bats
index 28287f7..66db133 100644
--- a/test/scripts/build-loop-check.bats
+++ b/test/scripts/build-loop-check.bats
@@ -66,3 +66,13 @@ want() { printf '%s\n' "$output" | grep -qxF "$1: $2" || { echo "want: $1: $2";
     for p in "${ps[@]}" docs/k.md; do want "$p" imported; done
     want docs/other.md -
 }
+
+@test "tree walk: an @ right after a Unicode space starts a token, as after a blank (U2a2 E1)" {
+    mkdir -p docs
+    printf 'See @docs/a.md\xc2\xa0@docs/b.md and x\xe3\x80\x80@docs/c.md\n' > CLAUDE.md
+    commit_all e1
+    imps tree docs/a.md docs/b.md docs/c.md docs/other.md
+    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
+    for p in docs/a.md docs/b.md docs/c.md; do want "$p" imported; done
+    want docs/other.md -
+}
diff --git a/scripts/lib/dev-cycle-read.sh b/scripts/lib/dev-cycle-read.sh
index 6bc9e73..b12929f 100644
--- a/scripts/lib/dev-cycle-read.sh
+++ b/scripts/lib/dev-cycle-read.sh
@@ -466,7 +466,10 @@ lower() { printf '%s' "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqr
 # Over-reading (a code span) only over-refuses. ~/ and absolute paths, and
 # paths leaving the repo (.. or ../, not a ..x name), are dropped.
 import_targets() {
-  local t v p u
+  local t v p u sp=()
+  # Each UNI_SPACES space becomes a blank before the grep, so a match cannot run
+  # through one into the next @token (the cut below then finds none).
+  for u in "${UNI_SPACES[@]}"; do sp+=(-e "s/$u/ /g"); done
   while IFS= read -r t; do
     t="${t#*@}"
     for u in "${UNI_SPACES[@]}"; do t="${t%%"$u"*}"; done
@@ -478,7 +481,7 @@ import_targets() {
       printf '%s\n' "$p"
       [[ "$v" != "$t" ]] || break
     done
-  done < <(env LC_ALL=C grep -aoE "$IMPORT_RE" || true)
+  done < <(env LC_ALL=C sed "${sp[@]}" | env LC_ALL=C grep -aoE "$IMPORT_RE" || true)
 }
 # Instruction-file names among NUL-separated paths on stdin: one grep, before
 # the tree walk forks lower and a plain check per path (forking for every tracked
```

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7697c6e6` as its first line."
- **Answered:** saved at docs/reviews/test-strategy-review-2026-10-06-final-build-loop-u2a2.md, with line 1 `Commit: 7697c6e6` and sections per skills/test-strategy. Every recommended test is a checked patch, run against its mutant.
- **Out of scope:** main_imports and the U2a3-routed rubric rows (B2-B6, B8, B10-B12, B14). The settled override rows (347, 350, 355, 356 and the u2a1 C-rows) are not re-filed.
- **Escalate:** G9 (Stage-1 E1) is a code defect (Medium, fail-open, not a regression). Patch B carries a test and a candidate fix for the author to decide on.
- **Findings (structured):**
  - G3 — Severity: Low (the test claims more than it proves). Location: test/scripts/build-loop-check.bats:31. Evidence: `printf 'back @../CLAUDE.md, @c.md and @b.md\n' > docs/c.md` makes docs/b.md, the only target after the NUL at :29, reachable without the NUL; M14 survives. Confidence: high (executed). Legibility-target: test author.
  - G5 — Severity: Low-Medium (a contract left unpinned before new callers arrive). Location: scripts/lib/dev-cycle-read.sh:517. Evidence: `lp="$(lower "$2")"`; removing it passes all tests. Confidence: high (executed). Legibility-target: U2a3/U2a4 authors.
  - G1/G2/G6/G7 — Severity: Low-Medium (fail-open guards with no test). Location: scripts/lib/dev-cycle-read.sh:453-455, :472, :487, :490. Evidence: M03, M04, M05, M22 and M25 survive. Confidence: high (executed). Legibility-target: test author.
  - G9 — Severity: Medium (fail-open, not a regression; Stage-1 E1). Location: scripts/lib/dev-cycle-read.sh:481. Evidence: `done < <(env LC_ALL=C grep -aoE "$IMPORT_RE" || true)`; executed, `@docs/a.md<NBSP>@docs/b.md` gives `docs/b.md: -`. Confidence: high. Legibility-target: author.
