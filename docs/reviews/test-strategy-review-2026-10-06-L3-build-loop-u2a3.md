Commit: 0bb98f27

# Test Strategy: feat/build-loop-u2a3 (loop 2 iteration 3, final confirming pass, ts3)

**Scope:** `git diff main...HEAD` (base 62d366a7): `scripts/lib/dev-cycle-read.sh` (`nul_list` :518-519, `main_imports` :538-615, `isimported main` :616-630), `test/scripts/build-loop-check.bats` (17 tests), `test/scripts/dev-cycle.bats` (sourcing check).
**Reviewed:** 2026-10-06
**Method:** I extracted HEAD with `git archive 0bb98f27` into `/tmp/u2a3-ts3-i3-d8OE/copy/` and ran 57 single-point mutants of the lib through `mut.sh` (`m-*` = runs against the original tests, `m-P-*`/`m-F-*` = runs against the patched tests in `p/`), plus two two-line mutants and one probe repo (`g-*`). I did not edit the worktree's tracked files.

## Test Conventions

The suite uses Bats 1.5+, and each test builds its own throwaway repo through `test/lib/build-loop-fixtures.bash` (`bl_setup`, `commit_all`). The main-walk tests call `imps main PATH...` and assert with `want walk ok|failed` and `want PATH imported|-`. Tree shapes that git refuses to check out are built with `git hash-object -w [--literally]`, `git mktree`, `git commit-tree` and `git update-ref refs/heads/main`. Failures are injected with a PATH-shimmed `tr`/`git`, `ulimit -f 0`, or a deleted object file. Cache tests run several `isimported main` calls inside one `bash -c`.

The unit is at the 400-line cap: 387 insertions and 13 deletions across the three code files. A patched line therefore counts against the cap only if it already exists on main. Every line in the appendix patch is a line the branch already added, so the patch nets zero lines (14/14 in the file, 268/2 against main both before and after).

Baselines: build-loop-check.bats passes 17/17 and dev-cycle.bats passes with 0 failures (TMPDIR under the scratch dir).

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:557 — `return 1` when `nul_list` cannot list main's tree whole (`ls-tree -r` fails part-way) — not covered. Test 10's missing-tree case (bats :197-198) is masked because the index still lists `docs/CLAUDE.md`. On an emptied `ent`, that file becomes a `t:` start and :574 fails the walk first. This is fact-check L3 r3's masked tree-listing refusal.
- **G2** — scripts/lib/dev-cycle-read.sh:606 — `lower` applied to each recorded import, so an import token holding upper case matches a query in any case — not covered. Every import token in the suite is already lower case. Test 3's `Docs/Imported.md` query only exercises the `lower "$2"` call at :624.
- **G3** — scripts/lib/dev-cycle-read.sh:569-570 — the `[[ ${#cand[@]} -eq 0 ]] ||` guard: no `.md` on main or in the checkout means an empty start list, and the walk is ok — not covered. Every main-walk fixture has at least one `.md`.
- **G4** — scripts/lib/dev-cycle-read.sh:554 — a cache hit when the key (`$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL`) is unchanged, and the documented reset (`IMPORTED_MAIN_DONE=""` re-walks, header :472-474) — not covered. Test 16 pins only key changes and a failed result that stays failed.
- **G5** — scripts/lib/dev-cycle-read.sh:587-588 — `git cat-file` failing on a symlink's blob (the NUL count, then the text read) — not covered. No fixture deletes a link blob. Each check is redundant with the other and with :590's `-z` (see What NOT to Test).
- **G6** — scripts/lib/dev-cycle-read.sh:559 — `return 1` on a tree record that does not parse — not covered, and real git cannot produce one (What NOT to Test).
- **G7** — scripts/lib/dev-cycle-read.sh:602 — the `*)` record-type arm — not covered and unreachable. The previous pass's G7 still holds (What NOT to Test).

## Findings

### G1 — test 10's tree-listing refusal is masked (fact-check L3 r3)

- **Location:** lib :557; bats :193-204 (test 10), specifically :197.
- **Evidence:** I mutated :557 `|| return 1` to `|| true` (`m-A557-treelist`). It passed 17/17 against the original tests, so it survived. On failure, `nul_list` empties `recs` (:519), so `ent` is empty. The `--cached --others` listing (:566) still returns the index's `docs/CLAUDE.md`, which makes it a `t:` start, and :574 fails the walk. That is the right answer for the wrong reason. The masking has been present since dfeeb85d added `--cached`.

  The patch appends `git rm -qf docs/CLAUDE.md` to :197, after the object deletion. `git rm` reads only the index, so the missing tree object does not stop it. It also restores the file at :204 (`mkdir -p docs && printf 'see @a.md\n' > docs/CLAUDE.md && commit_all again`), because the `tr` case after it needs a tracked start (its comment says so). The rewritten blob and tree have the same hashes, so the deleted tree object is recreated.

  With the patch, `m-F-A557-treelist` is killed by test 10. The mutant answers `walk: ok` and `docs/b.md: -`, so without this check a part-listed tree **fails open**: the walk is empty and passes. `m-F-G566-ls` and `m-F-I570-short` are still killed by test 10.
- **Severity:** Medium. A regression would fail open and leave the suite green. The trigger is a corrupt or partial object store, which is rare on a gate host.
- **Confidence:** High. I ran the mutant before and after the patch.
- **Legibility-target:** The comment `# no index-only start masks the tree-listing refusal`, in the same words as the earlier unmasking edits at :91, :189 and :242. The test 10 title and the :199 comment now say "the checkout's .md list" and `--cached --others`, which closes fact-check r1/r2's wording item.

### G2 — recorded imports are lower-cased, but no token holds upper case

- **Location:** lib :606; bats :219-227 (test 11).
- **Evidence:** I replaced :606 `IMPORTED_MAIN+="$(lower "$p")"` with `IMPORTED_MAIN+="$p"` (`m-Z606-lower`). It passed 17/17 against the original tests. Under that mutant, an import `@Docs/Mixed.md` is recorded as `Docs/Mixed.md`, and `isimported main docs/mixed.md` (lowered at :624) answers `-`, which fails open for the floor's "is this path imported" question.

  The patch puts `and @Docs/Mixed.md` into test 11's `CLAUDE.MD` and asks for `docs/mixed.md imported`. Main lacks `Docs/Mixed.md` and so does the checkout, so the walk is still ok. `m-F-Z606-lower` is killed by test 11.
- **Severity:** Medium. The mutant fails open, and the any-case contract (":616 path $2 (any case)") was pinned only on the query side.
- **Confidence:** High.
- **Legibility-target:** Test 11's title gains "an upper-case token matches any case".

### G3 — an empty start list walks ok

- **Location:** lib :569-570; bats :260-261 (test 14).
- **Evidence:** I dropped the `[[ ${#cand[@]} -eq 0 ]] ||` guard (`m-AC569-tr`). It passed 17/17 against the original tests. Without the guard, `printf '%s\0'` with no arguments emits one NUL, so `low` gets one element while `cand` has zero, and :570 fails the walk. Any repo with no `.md` would then refuse forever.

  The patch puts `imps main docs/a.md; want walk ok; want docs/a.md -` before test 14's first commit, when the fixture repo holds only the empty initial commit. `m-F-AC569-tr` is killed by test 14. I first put this case in test 2, but test 2's lines exist on main, so editing them would have added 4 changed lines over the cap. It went into test 14 instead.
- **Severity:** Low. The mutant fails closed.
- **Confidence:** High.
- **Legibility-target:** Test 14's title gains "a main and checkout with no .md file walk ok", and the line comment explains the ordering.

### G4 — the cache hit and its documented reset are unpinned

- **Location:** lib :554-555, header :472-474; bats :295-303 (test 16).
- **Evidence:** I made the :554 key comparison never match (`m-Z554-nocache`), so every call walks again. It passed 17/17 against the original tests. The header promises that a cached result ignores checkout changes until the caller clears `IMPORTED_MAIN_DONE`, and that one gate decision reads one walk.

  The patch appends this to test 16's script: `resolve_main; w z.sh; printf "x\n" > CLAUDE.local.md; w z.sh; IMPORTED_MAIN_DONE=""; w z.sh`. The expected output becomes `- - z.sh`: the untracked start is not seen until the reset, and then the walk fails closed. `m-F-Z554-nocache` is killed by test 16.

  The correct key mutant, which drops `$MAIN_BY_NAME` from both :554 and :555 (`m-Xkey-orig`), was already killed by test 16 before the patch.
- **Severity:** Low. The mutant only costs walks. The pin mainly fixes the documented contract before U2a3c changes the checkout phase.
- **Confidence:** High.
- **Legibility-target:** Test 16's title gains "a checkout change is not seen until IMPORTED_MAIN_DONE is cleared".

### Wording carried in the patch (fact-check L3 r1, r2, r3)

- **Location:** bats :171 (test 9 comment), :193 (test 10 title), :199 (test 10 comment).
- **Evidence:** In test 9, the :171 case credits the parent-link refusal. The `docs-link` symlink is also in the checkout, though, so :612 fails it as well. `m-V611-parent` is killed by tests 12 and 15, not by test 9. The new comment says both checks fire and names the tests that pin each check on its own. The test 10 fixes are described under G1.
- **Severity:** Low (legibility).
- **Confidence:** High.
- **Legibility-target:** Each comment and title now matches the check it exercises.

## Recommended Tests

#### Unmask test 10's tree-listing refusal
**Closes gaps:** G1 · **Type:** integration (bats) · **Priority:** high · **File:** test/scripts/build-loop-check.bats :197, :204
**What it verifies:** A part-listed main tree fails the walk with no index-only start present.
**Key cases:**
- `docs/` tree object deleted, `docs/CLAUDE.md` removed from the index and checkout → `walk failed`, `docs/b.md imported`. The restored file keeps the `tr` case meaningful.
**Setup needed:** The two appended commands.

#### Upper-case import token
**Closes gaps:** G2 · **Type:** integration · **Priority:** high · **File:** bats :221-224
**What it verifies:** An import token holding upper case is recorded lower-cased.
**Key cases:**
- `@Docs/Mixed.md` in `CLAUDE.MD` → `walk ok`, `docs/mixed.md imported`.

#### Empty start list
**Closes gaps:** G3 · **Type:** integration · **Priority:** low · **File:** bats :261
**What it verifies:** A repo with no `.md` anywhere walks ok and imports nothing.
**Key cases:**
- A repo with only the empty initial commit → `walk ok`, `docs/a.md -`.

#### Cache hit and reset
**Closes gaps:** G4 · **Type:** integration · **Priority:** low · **File:** bats :302-303
**What it verifies:** A cached result ignores a checkout change until `IMPORTED_MAIN_DONE` is cleared.
**Key cases:**
- A walk ok, then an untracked `CLAUDE.local.md` → still `-` (cached).
- Then `IMPORTED_MAIN_DONE=""` → `z.sh` imported (the walk fails).

## What NOT to Test

- **G5, lib :587-588 (cat-file failure on a link blob):** Ignoring the first read (`m-LM587588-both`, which despite its name mutates only :587) survives. Ignoring the second (`m-M588-cat2`) survives. Ignoring both (`m-P-Xboth`) also survives. I ran a probe on a repo whose `CLAUDE.md` is a symlink with its blob deleted, and both HEAD and the both-ignored mutant answer `failed`: the text reads empty, and :590's `-z` fires. The path fails closed through three independent checks, so a test would pin redundancy, not behaviour. (`m-L2587-catfail` was an identity mutant, so I discarded it.)
- **G6, lib :559 parse failure:** `m-B559-parse` (`|| continue`) survives. `ls-tree -r -z` prints only `<6 octal> <lowercase type> <hex id>\t<name>`, so reaching this line needs a fake `git` that forges records. The cost is out of proportion to a check that is unreachable.
- **G7, lib :602 `*)`:** It is unreachable, as in the previous pass (`m-T602-star` survives).
- **Equivalent mutants:**
  - `m-R601-glfall` (`160000) ;;`): replays imports that are already seen.
  - `m-F565-break`: the memo break only skips ancestors that are already checked.
  - `m-W612-dirL`: `blocker "$p" dir` already refuses a link.
  - `m-AB519-empty`: every `nul_list` caller returns 1 at once and never reads the array.
- **lib :596 `|| p=..` and :599 `|| out=..`:** `realpath -ms` reads no filesystem state, and I found no input that makes it fail. Both are fail-closed fallbacks that tests cannot reach.

All other mutants were killed by the original tests (killing tests in parentheses):

- Tree records: :561 doubled name and newline (5), :565 ancestor (17).
- Listing and start list: :566 listing (10), :567 newline (7), :570 short list (10), :574 start main lacks (3/9/11), :519 `rc=0` check (10).
- Reads: :583 blob and its `IMPORTED_MAIN=error` (4/8/14), :587 NUL (9), :588 `error` (9).
- Link text: :590 empty, newline and absolute (12, 7, 7), :595 `..` after a link (15), :597 main link and checkout link (15), :600 leaves the repo (7).
- Gitlinks and paths main lacks: :601 gitlink start (12), :605/:607/:609 (3/13/15), :611 parent link and gitlink (12/15), :612 blocker and `-L` (12).
- Starts: :573 rules at top and nested (6), :563 `.MD` (11).
- Cache and caller: :554/:555/:556 cache (16), :626 `|| return 0` (many).

## Coverage Gaps Beyond Current Scope

**1.** `ident` in main's `.gitattributes` (fact-check L3 r1) is a checkout conversion that A5, F11 and the U2b refusal set do not name. It needs a doc fix and a U2b refusal test, not a U2a3 test. The walk answers ok because it reads blobs, which is its documented contract.
**2.** A non-UTF-8 name on main under a UTF-8 locale fails the walk, which is fail-closed (fact-check r3). The test belongs with the U2a4 floor caller, which should pin `LC_ALL=C`. Every test here already runs under `LC_ALL=C`.
**3.** U2a3b (the parser and sed/grep fail-closed) and U2a3c (the checkout phase) are stacked above this unit. U2a3c will need to re-pin every `walk failed` checkout case, including G4's new `CLAUDE.local.md` case.

## Summary

The highest-value change unmasks test 10's tree-listing refusal (G1, fact-check r3). A single-point `|| true` at lib :557 passes every test today and fails open (`walk: ok`, everything `-`). After the patch, test 10 kills it. G2 pins the lower-casing of recorded imports, whose mutant also fails open. G3 and G4 pin an empty start list and the cache contract, whose mutants fail closed or only cost walks. The patch changes 14 lines, nets zero, keeps the branch at 400 changed code lines, and passes 17/17. The residual surviving mutants are unreachable, equivalent, or fail closed through redundant checks. I found no surviving mutant that fails open.

## Appendix: checked patch (zero net lines; test/scripts/build-loop-check.bats)

```diff
@@ -168,7 +168,7 @@
     printf 'see @docs/lt.md and @docs-link/x.md\n' > CLAUDE.md
     ln -s real docs-link
     commit_all base
-    # An import through a directory link main stores (the parent-link refusal).
+    # An import through a directory link main stores: the parent-link refusal, and the checkout's docs-link fails the plain-directory check too; tests 12 and 15 pin each alone.
     imps main docs/rules.md; want walk failed
     git rm -q docs-link && printf 'see @docs/lt.md\n' > CLAUDE.md && commit_all nolink
     imps main docs/rules.md; want walk ok
@@ -190,18 +190,18 @@
     imps main docs/rules.md; want walk failed; want docs/rules.md imported
 }
 
-@test "main walk returns, not exits, when main's tree or the untracked list cannot be listed (U2a2 iteration 1 A2); reads a list past 64 KiB under ulimit -f 0" {
+@test "main walk returns, not exits, when main's tree or the checkout's .md list cannot be listed (U2a2 iteration 1 A2); reads a list past 64 KiB under ulimit -f 0" {
     mkdir -p docs && printf 'see @a.md\n' > docs/CLAUDE.md && commit_all base
     imps main docs/a.md; want walk ok; want docs/a.md imported
     # The docs/ tree object is missing: ls-tree -r fails part-way.
-    o="$(git rev-parse main:docs)"; rm ".git/objects/${o:0:2}/${o:2}"
+    o="$(git rev-parse main:docs)"; rm ".git/objects/${o:0:2}/${o:2}"; git rm -qf docs/CLAUDE.md  # no index-only start masks the tree-listing refusal
     imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/b.md imported
-    # A corrupt index: git ls-files --others fails.
+    # A corrupt index: git ls-files --cached --others fails.
     git update-ref refs/heads/main "$(git commit-tree "$(printf '' | git mktree)" -m empty)"
     printf 'junk' > .git/index
     imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/b.md imported
     # A tr that fails (docs/CLAUDE.md is a tracked start again): the lower-cased list comes back short.
-    rm .git/index && commit_all again
+    rm .git/index && mkdir -p docs && printf 'see @a.md\n' > docs/CLAUDE.md && commit_all again
     mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/sh\nexit 1\n' > "$BATS_TEST_TMPDIR/bin/tr" && chmod +x "$BATS_TEST_TMPDIR/bin/tr"
     PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; rm "$BATS_TEST_TMPDIR/bin/tr" && printf '#!/bin/sh\ncase " $* " in *" --cached "*) exit 1;; esac\nexec %s "$@"\n' "$(command -v git)" > "$BATS_TEST_TMPDIR/bin/git" && chmod +x "$BATS_TEST_TMPDIR/bin/git"; PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; rm "$BATS_TEST_TMPDIR/bin/git"  # and a git whose ls-files --cached fails
     # An import list past 64 KiB with no room for a temp file is read whole (U2a3b I2-C4).
@@ -216,12 +216,12 @@
     [ "$output" = failed ] || { echo "$status $output $stderr"; return 1; }
 }
 
-@test "main walk: an upper-case .MD instruction file starts it; an untracked one fails the walk until U2a3c (U2a3)" {
+@test "main walk: an upper-case .MD instruction file starts it; an upper-case token matches any case; an untracked one fails the walk until U2a3c (U2a3)" {
     mkdir -p docs
-    printf 'Rules: @docs/up.md\n' > CLAUDE.MD
+    printf 'Rules: @docs/up.md and @Docs/Mixed.md\n' > CLAUDE.MD
     commit_all upper
-    imps main docs/up.md docs/other.md; [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
-    want walk ok; want docs/up.md imported; want docs/other.md -
+    imps main docs/up.md docs/other.md docs/mixed.md; [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
+    want walk ok; want docs/up.md imported; want docs/mixed.md imported; want docs/other.md -
     printf 'Mine: @mine.md\n' > docs/AGENTS.MD
     imps main docs/other.md; want walk failed; want docs/other.md imported
 }
@@ -257,8 +257,8 @@
     want walk ok; want docs/a.md imported; want docs/b.md imported; want docs/other.md -
 }
 
-@test "main walk fails on an unreadable blob when the caller did not set pipefail (U2a3)" {
-    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all claude
+@test "main walk fails on an unreadable blob when the caller did not set pipefail; a main and checkout with no .md file walk ok (U2a3)" {
+    imps main docs/a.md; want walk ok; want docs/a.md -; printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all claude  # first, with no .md on main or in the checkout: an empty start list is no failure
     o="$(git rev-parse main:CLAUDE.md)"; rm ".git/objects/${o:0:2}/${o:2}"
     run --separate-stderr env LC_ALL=C bash -c 'set -eu; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
         if main_imports; then echo "walk: ok"; else echo "walk: failed"; fi
@@ -292,15 +292,15 @@
     ln -s deep/inner ld; imps main deep/secret.md; want walk failed; want deep/secret.md imported
 }
 
-@test "main walk cache: a new main commit or main not found by name walks again; a failed walk stays failed (U2a3 i2 test-strategy G6, G9)" {
+@test "main walk cache: a new main commit or main not found by name walks again; a failed walk stays failed; a checkout change is not seen until IMPORTED_MAIN_DONE is cleared (U2a3 i2 test-strategy G6, G9)" {
     printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all one
     run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
         w() { if isimported main "$1"; then echo "$1"; else echo -; fi; }
         w docs/b.md; printf "Rules: @docs/b.md\n" > CLAUDE.md; git commit -qam two; resolve_main; w docs/b.md; g="$MAIN_SHA"
         a="$(printf "x\n" | git hash-object -w --stdin)"; t="$(printf "100644 blob %s\tA.md\n100644 blob %s\tA.md\n" "$a" "$a" | git mktree)"
         git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup)"; resolve_main; w x.sh; w x.sh
-        git update-ref refs/heads/main "$g"; resolve_main; w x.sh; MAIN_BY_NAME=""; w y.sh' _ "$LIB"
-    [ "$status" -eq 0 ] && [ "$output" = "$(printf '%s\n' - docs/b.md x.sh x.sh - y.sh)" ] || { echo "$output $stderr"; return 1; }
+        git update-ref refs/heads/main "$g"; resolve_main; w x.sh; MAIN_BY_NAME=""; w y.sh; resolve_main; w z.sh; printf "x\n" > CLAUDE.local.md; w z.sh; IMPORTED_MAIN_DONE=""; w z.sh' _ "$LIB"
+    [ "$status" -eq 0 ] && [ "$output" = "$(printf '%s\n' - docs/b.md x.sh x.sh - y.sh - - z.sh)" ] || { echo "$output $stderr"; return 1; }
 }
```

The full patch is at `/tmp/u2a3-ts3-i3-d8OE/patch-final.diff`, and the patched tree is at `/tmp/u2a3-ts3-i3-d8OE/p/`.

- `git diff --no-index --numstat` against HEAD's file: 14 insertions, 14 deletions, 311 lines before and after.
- Against main's file: 268 insertions, 2 deletions, the same as `git diff main...HEAD`.

**Check runs** (`TMPDIR` under the scratch dir):

| Run | Lib | Tests | Result |
|---|---|---|---|
| baseline | HEAD | original | 17/17; dev-cycle.bats 0 failures |
| A557 `\|\| true` | mutant | original | survives |
| Z606 no `lower` | mutant | original | survives |
| AC569 guard dropped | mutant | original | survives |
| Z554 cache never hits | mutant | original | survives |
| Xkey (MAIN_BY_NAME out of key) | mutant | original | killed by 16 |
| patched | HEAD | patched | 17/17 |
| A557 / Z606 / AC569 / Z554 | mutant | patched | killed by 10 / 11 / 14 / 16 |
| full batch (57) | mutants | patched | 46 killed; 11 survivors, all listed in What NOT to Test |
| probe: link blob deleted | HEAD and both-ignored mutant | g-* repo | both `failed` |

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/test-strategy-review-2026-10-06-L3-build-loop-u2a3.md naming each gap with a concrete test case and a checked zero-net-line patch in an appendix (run in your scratch copy; do not edit tracked files)."
- **Answered:** G1-G7 are named. Concrete cases go into a checked patch for four of them:
  - G1, fact-check r3's masked tree-listing refusal, which fails open if it regresses.
  - G2, which also fails open if it regresses.
  - G3 and G4.

  The patch nets zero lines in the file and against main, so the branch stays at 400, and it passes 17/17. G5-G7 and the equivalent mutants are justified in What NOT to Test. The patch also carries the test-wording fixes the fact-check routed (r1/r2 test 10, r3 test 9).
- **Out of scope:** Lib or doc changes (`ident` in A5/F11/U2b, the header and return-1 comment wording, 99cce51b's message), U2a3b's parser, U2a3c's checkout phase, and the caller's `LC_ALL=C`.
- **Escalate:** None blocking. G1 and G2 are unpinned fail-open regressions, and the author should apply the patch before merging. The code at HEAD is correct for both. `ident` goes to the author or the U2b owner (fact-check escalation, not a test gap here).
