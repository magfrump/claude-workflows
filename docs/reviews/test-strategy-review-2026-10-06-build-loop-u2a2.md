Commit: 7f295cdb

# Test Strategy: feat/build-loop-u2a2 (main_imports, isimported, import_targets; C12/C13 test rows)

**Scope:** `git diff main...HEAD` (main 20347279, HEAD 7f295cdb). Code: scripts/lib/dev-cycle-read.sh (import_targets, instruction_names, untracked_md, imported_names, main_imports, isimported), scripts/dev-cycle.sh check_fix. Tests: test/scripts/build-loop-check.bats (new, 9 tests), test/scripts/fixture-git-env.bats (C12), test/scripts/dev-cycle.bats (inventory, entry_why one-arg).
**Reviewed:** 2026-10-06 (critic pass, iteration 2)
**Method:** 48 single-point mutants of the lib, each run against build-loop-check.bats in a scratch copy (`git archive HEAD` into /tmp/u2a2-ts-TWvx, its own `git init`; the worktree was never edited), plus 2 mutants of the fixture setups run against fixture-git-env.bats in a second copy (/tmp/u2a2-ts2-JPzj). The recommended patch (Appendix A) was applied in the scratch copy, run (full five-suite list: 111 ok, 0 not ok = the 107 at HEAD plus 4 new), and run against every mutant it targets (all killed), plus `git apply --check` against the file at 7f295cdb (applies).

## Test Conventions

- bats 1.8.2, `bats_require_minimum_version 1.5.0`; `run --separate-stderr`, explicit `[ ... ] || { echo "$output $stderr"; return 1; }` diagnostics.
- build-loop-check.bats loads test/lib/build-loop-fixtures.bash (`bl_setup`: throwaway repo under `$BATS_TEST_TMPDIR`, local git env vars unset, hermetic config; `commit_all`). Trees the porcelain cannot make are built with `git mktree` / `git commit-tree` / `git update-ref`.
- Helpers `imps WALK PATH...` (prints `walk: ok|failed`, then `PATH: imported|-`) and `want PATH WORD` (exact line match). Test names end with the unit tag, e.g. `(U2a2)`.
- No per-test timeout anywhere (no `BATS_TEST_TIMEOUT`, no `timeout` in the helpers) — relevant to G6.

## Mutation results at HEAD (build-loop-check.bats)

Killed (the suite pins the guard): duplicate name (M04, t3), newline in a tree name (M05, t3), newline in an untracked name (M07, t5), `.claude/rules/` start (M08, t4), the directory arm (M09, t8), checkout symlink at a target fails (M11b, t8), NUL count in link text (M13, t8), newline/absolute link text (M15/M16, t5), empty `p` skip (M18, t1 t4), always-checkout / always-main queue (M20 t4 / M21 many), `main_imports || return 0` (M22), unknown walk name (M23, t6), UTF-8 space split (M24, t4 t7), old `..*` filter (M25b, t5 t7), trailing punctuation (M26, t1), `grep -a` (M27, t6 t7), both listing rc checks (M30/M31, t9), blob-read failure (M32, t2 t6), NUL link `continue` (M36, t8).

Survived, judged equivalent or unreachable (no test recommended): M02 no cache (recomputing gives the same answers), M03 record-parse guard (ls-tree -z output always parses), M10b `! -L` in the directory arm (`blocker "$f" dir` already prints a symlink: plaindir compares realpath), M34 no `seen` for start files, M35 no empty-candidate guard (loop over zero indices), M28 `~` filter (the `~/x` record matches no repo path a caller asks about; only over-refuses), M25a lone `..` token (falls into the `-e` arm: over-refuses), M38 gitlink arm made fatal (over-refusal; fact-check caveat already records `*) continue`).

Survived and fail-open or masking a documented rule: M06, M29, M10, M11, M12, M14, M19, MT19 (tree walk), M37 — the gaps below. M17 is discussed under Coverage Gaps Beyond Current Scope.

C12 (fixture-git-env.bats) is load-bearing: replacing dev-cycle.bats' `unset $(git rev-parse --local-env-vars)` with `unset GIT_DIR` (F2), or bl_setup's the same way (F2b), fails only at the new `cmp` line (fixture-git-env.bats:27) — the commit-count check alone would have passed. Removing the unset entirely (F1) also fails. C13 (dev-cycle.bats:1342 `entry_why error`) fails under `p="$2"` (unbound under `set -u`). The inventory additions are plain presence checks and fail if any name is dropped.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:542 — `*.[mM][dD]` keeps a main entry with an upper-case extension (CLAUDE.MD) as a start candidate; narrowing to `*.md` (M06) passes every test — not covered
- **G2** — scripts/lib/dev-cycle-read.sh:497 — `icase` in untracked_md lists an untracked docs/AGENTS.MD; dropping it (M29) passes every test — not covered
- **G3** — scripts/lib/dev-cycle-read.sh:562 — `-z "$(blocker "$f" dir)"`: a plain directory reached through a checkout directory symlink must fail the walk (lib:521-522 "or under one"); dropping it (M10) passes — not covered
- **G4** — scripts/lib/dev-cycle-read.sh:563 — the `-L "$f"` arm: a dangling checkout symlink at a target fails the walk; dropping it (M11) passes (test 8's link targets all exist) — not covered
- **G5** — scripts/lib/dev-cycle-read.sh:574 — the `-z "$out"` arm for empty link text; test 5's `''` case passes without it (M14) because at the top level the text resolves to `.`, which then fails in the `-e` arm by accident (`plaindir .` compares `ROOT/.`). A link below the top level (sub/AGENTS.md → `sub`, a plain directory) walks ok under M14 — partially covered (top-level arm only, for the wrong reason)
- **G6** — scripts/lib/dev-cycle-read.sh:583 (main) and :512 (tree) — the `seen` checks that end an import cycle; no fixture has a cycle or self-import, so removing either (M19, MT19) passes and a real cycle would hang the gate with no test timeout to catch it — not covered
- **G7** — scripts/lib/dev-cycle-read.sh:528 — `local -; set -o pipefail` inside main_imports: every test caller sets pipefail itself, so removing it (M12) passes; a caller without pipefail would read a missing blob as "no imports" (walk ok) — not covered
- **G8** — scripts/lib/dev-cycle-read.sh:533 — `main_by_name || return 1`: test 2's "no default branch found by name" case (build-loop-check.bats:52-55) passes without the guard (M37) because the blob deleted at :48-49 is still missing on trunk, so the walk fails on the blob, not the name — covered vacuously
- **G9** — build-loop-check.bats:141-142 — test 6's "a NUL in an instruction file hides no import" asserts only `docs/b.md imported`, which a failed walk also answers; a mutant that fails the walk on any NUL-holding blob (V1) passes at HEAD — covered vacuously

## Recommended Tests

All in Appendix A as one checked patch to test/scripts/build-loop-check.bats.

#### Upper-case .MD start files, tracked and untracked

**Closes gaps:** G1, G2
**Type:** integration (fixture repo)
**Priority:** medium (fail-open: an instruction file's imports would be missed; real on case-insensitive checkouts)
**File:** test/scripts/build-loop-check.bats (new test)
**What it verifies:** main's CLAUDE.MD and an untracked docs/AGENTS.MD both start the walk.
**Key cases:**
- main CLAUDE.MD `@docs/up.md` → walk ok, docs/up.md imported (kills M06)
- untracked docs/AGENTS.MD `@mine.md` → docs/mine.md imported (kills M29)
- docs/other.md → `-`
**Setup needed:** none beyond bl_setup.

#### Dangling link, directory under a link, empty link text below the top level

**Closes gaps:** G3, G4, G5
**Type:** integration
**Priority:** medium (G4, G5 pin documented fail-closed refusals); low-medium (G3: a directory loads nothing, but the doc promises the refusal)
**File:** test/scripts/build-loop-check.bats (new test)
**What it verifies:** each shape fails the walk, with a `walk ok` baseline between shapes so no failure carries over.
**Key cases:**
- baseline: CLAUDE.md `@docs/gone.md and @lnk/sub.md`, neither present → walk ok, docs/x.md `-`
- untracked `docs/gone.md -> missing.md` → walk failed (kills M11)
- untracked `lnk -> real`, real/sub.md a directory → walk failed (kills M10); removed → walk ok
- main `sub/AGENTS.md` a symlink with empty text, sub/ a plain checkout directory → walk failed (kills M14)

#### Import cycles end in both walks

**Closes gaps:** G6
**Type:** integration
**Priority:** high (a missing `seen` check hangs the gate on a self-import, a common shape; today nothing would notice)
**File:** test/scripts/build-loop-check.bats (new test, plus `timeout 60` in `imps`)
**What it verifies:** a self-import, a two-file cycle in main, and a cycle through untracked files all end, for `main` and `tree`, with every member imported.
**Key cases:**
- CLAUDE.md ↔ docs/a.md, CLAUDE.md → itself, docs/a.md ↔ docs/b.md
- untracked CLAUDE.local.md → docs/u.md ↔ docs/w.md, docs/u.md → CLAUDE.local.md
- docs/other.md `-`
**Setup needed:** `imps` gains `timeout 60` so a hang fails the test (kills M19 and MT19 by timeout).

#### Missing blob with a caller that did not set pipefail

**Closes gaps:** G7
**Type:** integration
**Priority:** low-medium (current callers set pipefail; the lib claims to set it for itself)
**File:** test/scripts/build-loop-check.bats (new test)
**What it verifies:** under `set -eu` only, a missing instruction blob still fails the walk and isimported answers imported (kills M12).

#### Make test 2's by-name case and test 6's NUL case non-vacuous

**Closes gaps:** G8, G9
**Type:** integration (edits to existing tests)
**Priority:** high (both are assertions that pass for a reason other than the one their names claim)
**File:** test/scripts/build-loop-check.bats tests 2 and 6
**Key cases:**
- test 2: rewrite the deleted blob (`git hash-object -w`) and assert walk ok / `scripts/other.sh -` before switching to trunk (kills M37; it survived at HEAD)
- test 6: add `want walk ok` before `want docs/b.md imported` (kills V1; it survived at HEAD)

## Findings

**F1 — test 2's no-default-branch case is vacuous**
- Severity: medium
- Location: test/scripts/build-loop-check.bats:52-55
- Evidence: `rm ".git/objects/${o:0:2}/${o:2}"` (:49) is never undone, then `git checkout -q -b trunk && git branch -q -D main` / `want walk failed`. resolve_main falls back to the current branch (lib:428-433: `MAIN="$cur"; MAIN_SHA=...HEAD`), whose tree is the same, so the walk fails on the missing blob. Mutant M37 (delete `main_by_name || return 1`, lib:533) passes all 9 tests.
- Confidence: high (mutant run)
- Legibility-target: maintainer trusting the test name "or main is not found by name"

**F2 — test 6's "a NUL hides no import" passes on a failed walk**
- Severity: medium
- Location: test/scripts/build-loop-check.bats:141-142
- Evidence: `imps main docs/b.md` / `want docs/b.md imported` with no `want walk ok`; isimported answers imported when the walk fails (lib:599). Mutant V1 (fail the walk on any NUL-holding blob, lib:567) passes all 9 tests.
- Confidence: high (mutant run)
- Legibility-target: test reader

**F3 — no import cycle in any fixture; no test timeout**
- Severity: medium (a regression would hang the gate and the suite instead of failing)
- Location: scripts/lib/dev-cycle-read.sh:583, :512; test/scripts/build-loop-check.bats:17-22
- Evidence: `[[ -z "${seen[$p]+set}" ]] || continue` (lib:583) and `if [[ "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo_here "$p"` (lib:512); removing either (M19, MT19) passes all 9 tests.
- Confidence: high
- Legibility-target: future editor of the walk

**F4 — four documented guards and one fail-open filter have no killing test**
- Severity: low-medium
- Location: scripts/lib/dev-cycle-read.sh:542, :497, :562, :563, :574, :528
- Evidence: mutants M06, M29, M10, M11, M14, M12 each pass all 9 tests (see G1-G5, G7). M14's survival shows test 5's `''` case (build-loop-check.bats:128-134) fails at lib:563 via `plaindir .`, not at the `-z "$out"` guard it targets.
- Confidence: high
- Legibility-target: test reader / future editor

## What NOT to Test

- The ls-tree record-parse guard (lib:538), the empty-candidate guard (:549) and `! -L` in the directory arm (:562): unreachable or redundant (mutants M03, M35, M10b equivalent).
- The cache key (:531) and changes of MAIN_SHA inside one shell: no caller changes MAIN_SHA mid-process in this unit; revisit when U2a3's floor lands.
- The `~` filter and the lone `..` token in import_targets: their mutants only over-refuse.
- Gitlink entries at a target (`*) continue`, :577): recorded as a fact-check caveat; a mutant making it fatal only over-refuses.
- fixture-git-env.bats' own new `unset` (C12): pinning it needs running that suite under an inherited GIT_DIR from another suite, a third level of nesting for a setup line; the F1/F2 mutants already show the inner checks work.
- The checkout-symlinked-directory start-file gap (fact-check i2 E1) and other A5 items: settled under the 2026-10-06 `feat/build-loop-u2a` override row; a test would pin the gap, not close it.

## Coverage Gaps Beyond Current Scope

**1.** A main symlink whose text leaves the repo (`AGENTS.md -> ../shared/AGENTS.md`) is skipped (lib:576 `continue`) with the walk ok; mutant M17 (follow it) passes all tests. Claude Code would load the outside file, and its relative imports back into the repo are then missed, so the current answer `-` is the fail-open side. Not pinned in Appendix A on purpose: a test would freeze that behavior. Nearest settled row is A5's "absolute imports"; whether repo-escaping link text belongs under it is for the author.

**2.** check_fix (scripts/dev-cycle.sh:181) now calls `isimported tree` only in its last `elif`, where `imported_names` used to run (and `need_root` exit) on every call. The existing --check-fix import tests (dev-cycle.bats:1016-1072) pass, and check_path still runs need_root; no test pins the order, which matters only if a caller ever runs check_fix with ROOT_REAL unset.

## Summary

The highest-value changes are the two edits that make existing tests non-vacuous (F1/G8: the by-name case actually fails on the missing blob it inherited; F2/G9: the NUL case never asserts the walk succeeded) and the cycle test with a `timeout` in `imps` (F3/G6), since a lost `seen` check would hang the gate on a self-import with nothing to catch it. The remaining new tests pin documented fail-closed refusals (dangling link, directory under a link, empty link text below the top level, no-pipefail caller) and the upper-case `.MD` start files whose filters are fail-open if narrowed. With Appendix A applied, every non-equivalent surviving mutant except M17 is killed and the five-suite run is 111 ok. Residual risk: the repo-escaping symlink (Gap 1), which the walk drops as `-`. The C12 index check and the C13 one-arg test were confirmed load-bearing by mutation.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7f295cdb` as its first line."
- **Answered:** untested guards in main_imports/isimported/import_targets (G1-G8, by mutation); vacuous tests (F1, F2); C12/C13 checked load-bearing; one checked patch (Appendix A) applied, run green, and run against each target mutant.
- **Out of scope:** A5-settled gaps (override rows 2026-10-06 `feat/build-loop-u2a`), the doc wording of fact-check i2 E1, the U2a3 floor.
- **Escalate:** none blocking. Gap 1 (repo-escaping symlink text) may need an author call on whether it falls under A5.

## Appendix A — checked patch (test/scripts/build-loop-check.bats at 7f295cdb)

Verified: `git apply --check` against the 7f295cdb file; applied in scratch, five-suite run 111 ok / 0 not ok; kills M06, M29 (test 10), M10, M11, M14 (test 11), M19, MT19 (test 12, by timeout), M12 (test 13), M37 (test 2), V1 (test 6). M37 and V1 both survive the unpatched suite.

```diff
diff --git a/test/scripts/build-loop-check.bats b/test/scripts/build-loop-check.bats
index f0efcba..120ac44 100644
--- a/test/scripts/build-loop-check.bats
+++ b/test/scripts/build-loop-check.bats
@@ -15,7 +15,8 @@ setup() { bl_setup; LIB="$REPO_ROOT/scripts/lib/dev-cycle-read.sh"; }
 # "walk: ok" or "walk: failed" (main_imports' return; tree always reads ok),
 # then "PATH: imported" or "PATH: -" from isimported WALK for each path.
 imps() {
-    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; shift
+    # timeout: a walk that never ends (an import cycle it does not stop) fails the test.
+    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; shift
         resolve_main || true; ROOT_REAL="$(pwd -P)"; w="$1"; shift
         if [[ "$w" != main ]] || main_imports; then echo "walk: ok"; else echo "walk: failed"; fi
         for p in "$@"; do if isimported "$w" "$p"; then echo "$p: imported"; else echo "$p: -"; fi; done' _ "$LIB" "$@"
@@ -49,6 +50,10 @@ want() { printf '%s\n' "$output" | grep -qxF "$1: $2" || { echo "want: $1: $2";
     rm ".git/objects/${o:0:2}/${o:2}"
     imps main scripts/other.sh
     want walk failed; want scripts/other.sh imported
+    # The blob is back: the walk reads again, so the next failure is the name alone.
+    printf 'Rules: @docs/a.md\n' | git hash-object -w --stdin >/dev/null
+    imps main scripts/other.sh
+    want walk ok; want scripts/other.sh -
     # No default branch found by name: nothing is read, every path is imported.
     git checkout -q -b trunk && git branch -q -D main
     imps main scripts/other.sh
@@ -139,7 +144,7 @@ want() { printf '%s\n' "$output" | grep -qxF "$1: $2" || { echo "want: $1: $2";
     printf 'see @docs/a.md\0 and @docs/b.md\n' > AGENTS.md
     commit_all nul
     imps main docs/b.md
-    want docs/b.md imported
+    want walk ok; want docs/b.md imported
     run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
         if isimported bogus docs/z.md; then echo "bogus: imported"; fi
         o="$(git rev-parse main:AGENTS.md)"; rm ".git/objects/${o:0:2}/${o:2}"
@@ -196,3 +201,63 @@ failed walk: imported" ] || { echo "$output $stderr"; return 1; }
     printf 'junk' > .git/index
     imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/b.md imported
 }
+
+@test "main walk: an upper-case .MD instruction file starts it, tracked or untracked (U2a2 review)" {
+    mkdir -p docs
+    printf 'Rules: @docs/up.md\n' > CLAUDE.MD
+    commit_all upper
+    printf 'Mine: @mine.md\n' > docs/AGENTS.MD
+    imps main docs/up.md docs/mine.md docs/other.md
+    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
+    want walk ok; want docs/up.md imported; want docs/mine.md imported; want docs/other.md -
+}
+
+@test "main walk fails on a dangling checkout link at a target, a directory under a checkout link, and empty link text below the top level (U2a2 review)" {
+    mkdir -p docs sub real/sub.md
+    printf 'see @docs/gone.md and @lnk/sub.md\n' > CLAUDE.md
+    commit_all base
+    imps main docs/x.md; want walk ok; want docs/x.md -
+    # A dangling untracked symlink at a target main lacks.
+    ln -s missing.md docs/gone.md
+    imps main docs/x.md; want walk failed; want docs/x.md imported
+    rm docs/gone.md
+    # A plain directory reached through an untracked directory symlink.
+    ln -s real lnk
+    imps main docs/x.md; want walk failed; want docs/x.md imported
+    rm lnk
+    imps main docs/x.md; want walk ok
+    # Empty symlink text in sub/ would name sub/ itself, a plain directory here.
+    e="$(printf '' | git hash-object -w --stdin)"
+    s="$(printf '120000 blob %s\tAGENTS.md\n' "$e" | git mktree)"
+    git update-ref refs/heads/main "$(git commit-tree "$(printf '040000 tree %s\tsub\n' "$s" | git mktree)" -p main -m empty-link)"
+    imps main docs/x.md; want walk failed; want docs/x.md imported
+    [ -z "$stderr" ] || { echo "$stderr"; return 1; }
+}
+
+@test "both walks end on an import cycle, a self-import and a cycle through an untracked file (U2a2 review)" {
+    mkdir -p docs
+    printf 'see @docs/a.md and @CLAUDE.md\n' > CLAUDE.md
+    printf 'back @../CLAUDE.md, @a.md and @b.md\n' > docs/a.md
+    printf 'again @a.md\n' > docs/b.md
+    commit_all cycle
+    printf 'Mine: @docs/u.md\n' > CLAUDE.local.md
+    printf 'loop @../CLAUDE.local.md and @w.md\n' > docs/u.md
+    printf 'last @u.md\n' > docs/w.md
+    for w in main tree; do
+        imps "$w" docs/a.md docs/b.md docs/u.md docs/w.md docs/other.md
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $status $output $stderr"; return 1; }
+        want walk ok
+        for p in docs/a.md docs/b.md docs/u.md docs/w.md; do want "$p" imported; done
+        want docs/other.md -
+    done
+}
+
+@test "main walk fails on an unreadable blob when the caller did not set pipefail (U2a2 review)" {
+    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all claude
+    o="$(git rev-parse main:CLAUDE.md)"; rm ".git/objects/${o:0:2}/${o:2}"
+    run --separate-stderr env LC_ALL=C bash -c 'set -eu; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
+        if main_imports; then echo "walk: ok"; else echo "walk: failed"; fi
+        if isimported main scripts/x.sh; then echo "scripts/x.sh: imported"; fi' _ "$LIB"
+    [ "$status" -eq 0 ] && [ "$output" = "walk: failed
+scripts/x.sh: imported" ] || { echo "$output $stderr"; return 1; }
+}
```

## Appendix B — mutants used

Scripts: /tmp/u2a2-ts-TWvx-tools/mutants.sh (48 lib mutants, HEAD suite), mutants2.sh (targets, patched suite), run.sh (applies one exact-string replacement to the scratch lib, runs bats with `BATS_TEST_TIMEOUT=60` under `timeout 900`, restores). V1 replacement at lib:567: prepend `[[ "$(git cat-file blob "$MAIN_SHA:$f" | tr -cd '\0' | wc -c)" -eq 0 ]] || { IMPORTED_MAIN=error; return 1; };` to the regular-blob arm.
