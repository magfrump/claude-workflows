Commit: cebfed35

# Test Strategy: feat/build-loop-u2a3c (main_imports' checkout phase), review-fix loop iteration 1

**Scope:** `git diff 5e51b58b..HEAD` (cebfed35 only): the tests in `test/scripts/build-loop-check.bats` against `scripts/lib/dev-cycle-read.sh` checkout_md (:524), main_checkout (:529-535) and main_imports' start admission (:589-590), phase-2 swap (:596), checkout read (:600) and import queueing (:628-629).
**Reviewed:** 2026-10-06 (role test-strategy, loop pass)
**Method:** 32 single-point mutants (M1-M19, E1-E6) of a scratch copy of the lib, each run against the full suite (`/tmp/u2a3c-ts-a4ag/w`, driver `/tmp/u2a3c-ts-a4ag/mut2.py`, results for the patched copy in `mut-w2.txt`), plus two behavioural probes (`probe.sh`, `probe2.sh`). Bats ran with `TMPDIR` set to fresh `/tmp/u2a3c-ts-XXXX` dirs. The worktree's tracked files were not edited.

## Test Conventions

- bats >= 1.5.0; each test builds a throwaway repo under `$BATS_TEST_TMPDIR` (`test/lib/build-loop-fixtures.bash`: `bl_setup`, `commit_all`).
- `imps WALK PATH...` prints `walk: ok|failed`, then `PATH: imported|-` from `isimported`. `want PATH WORD` asserts one line. Odd main trees come from `git mktree` / `git commit-tree` / `git update-ref`, so main and the checkout can differ without a checkout. Checkout states come from plain `mkdir`/`printf`/`chmod` (the uid is 1000, not root, so mode-000 and `r--` directories bite).
- Baseline at cebfed35: 18/18 pass (about 6 s).

## Mutation results (baseline suite, cebfed35)

26 of 32 mutants killed. Survivors:

| Mutant | Line | Change | Fail-open? | Disposition |
|---|---|---|---|---|
| M1s | :531 | parent link/gitlink check skipped for starts only | yes | G1 (the fact-check's C1 gap, Claim 22a) |
| E6 | :531 | gitlink parent skipped for starts only (link kept) | yes | G2 |
| M2s | :531 | unsearchable-parent check skipped for starts only | yes (walk ok, start unread) | G3 |
| M8 | :590 | a start main_checkout answers 2 for fails the walk | no (over-refusal) | G4 |
| M9 | :590 | a start main_checkout answers 2 for is queued and read | no (the read fails) | G4 |
| M3 | :532 | `[[ -r "$1" ]]` dropped | no | equivalent: the :600 read fails on the same file (What NOT to Test) |
| M18 | :600 | checkout read failure ignored | no | equivalent: unreachable behind :532's `-r` (What NOT to Test); M3+M18 together (E4) is killed by test 9 |
| M13 | :591 | checkout starts queued in phase 1 rather than tq | no | equivalent: `seen` and `${ent[$f]-checkout}` make the order unobservable (What NOT to Test) |

Killed (for the record): the whole-parent check (M1, tests 12/15/18), gitlink parents for imports (M1g, test 12), unsearchable parents for imports (M2, test 18), inrepo_here weakened to `-f` (M4, test 9), every arm of the dir-or-absent line (M5, M5b-M5e, tests 9/12), the start admission skipped (M6) or its refusal ignored (M7), import refusal/queue/rc-2 mutants (M10-M12), checkout_md's stderr check, `--others`, `--cached` and `icase` (M14-M17, tests 18/3/10/11), and the checkout read sent to main (M19).

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:531, :589-590 — the `^1[26]0000$` link arm of main_checkout's parent loop for a start (cand `t:`) that imports nothing — not covered. Test 18's two C1 fixtures (`ld/CLAUDE.md`, `.claude/rules/foo.md`) both import a path under the same link, and that import's own main_checkout (:628) refuses, so M1s survives.
- **G2** — scripts/lib/dev-cycle-read.sh:531 — the gitlink (160000) half of the same arm for a start — not covered. Test 12's gitlink case (:247-248) reaches it only through an import (`@sub/x.md`).
- **G3** — scripts/lib/dev-cycle-read.sh:531 — the `( ! -d "$c" || -x "$c" )` arm for a start under a readable but unsearchable (`r--`) directory — not covered. Test 18 pins it for an import (`priv/x.md`), and its mode-000 `hid/` start is refused earlier by checkout_md (git warns), so the start arm is never the deciding check.
- **G4** — scripts/lib/dev-cycle-read.sh:590 — `[[ $c -eq 0 ]] || continue`: a start main_checkout answers 2 for (an index-only start deleted from the checkout) is skipped, not walked or failed — not covered.
- **G5** — test/scripts/build-loop-check.bats:92, :191, :199, :244 — `git rm -qf ... # no index-only start masks ...` and test 10's restore at :206 — no longer guard anything (fact-check Claims 26, 30) — stale test code, not a branch.

### Findings

**G1 — the start-only link-parent refusal (C1) is unpinned**
- Severity: high
- Location: scripts/lib/dev-cycle-read.sh:531, :589-590; test/scripts/build-loop-check.bats:321-323
- Evidence: lib `while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ && ( ! -d "$c" || -x "$c" ) ]] || return 1; done` (excerpt of main_checkout, which continues to :535 — read); test `rm .claude/rules && mkdir .claude/rules && cp docs/foo.md .claude/rules/; imps main docs/bar.md; want walk failed; want docs/bar.md imported`, where docs/foo.md reads `see @bar.md`. Mutant M1s survives all 18 tests. With the patched fixture (`printf 'harmless\n' > .claude/rules/foo.md`) the real code gives `walk: failed`, `docs/bar.md: imported`; M1s gives `walk: ok`, `docs/bar.md: -` while main's `.claude/rules -> ../docs` link makes docs/foo.md, which imports docs/bar.md, a rule.
- Confidence: high (executed)
- Legibility-target: implementer

**G2 — the start-only gitlink-parent refusal is unpinned**
- Severity: medium
- Location: scripts/lib/dev-cycle-read.sh:531; test/scripts/build-loop-check.bats:247-248
- Evidence: test 12 `t="$(printf '100644 blob %s\tCLAUDE.md\n160000 commit %s\tsub\n' "$(printf 'see @sub/x.md\n' | ...` reaches the gitlink parent only through an import. Mutant E6 (starts keep the 120000 arm, drop 160000) survives the baseline suite. Patched fixture: main stores `sm` as a gitlink, the checkout holds plain `sm/CLAUDE.md` reading `harmless`; real gives `walk: failed`, E6 gives `walk: ok`.
- Confidence: high (executed). The case is reachable when the checkout's index lacks the gitlink (a branch that replaced the submodule with a plain directory); with the gitlink in the index, `ls-files --others` may not list inside it (A5's settled gap).
- Legibility-target: implementer

**G3 — a start under an `r--` checkout directory is refused only by an unpinned arm**
- Severity: medium
- Location: scripts/lib/dev-cycle-read.sh:524, :531; test/scripts/build-loop-check.bats:324-327
- Evidence: test `# A readable but unsearchable directory holding an import main lacks; then an unreadable one only git's listing meets.` Probe (`probe.sh`/`probe2.sh`, untracked and `git add -f` index-only `priv/AGENTS.md`, `chmod 644 priv`): `git ls-files --cached --others` lists `priv/AGENTS.md` with no warning, so checkout_md passes; real code `walk failed`, M2 `walk ok` / `q -`. Mode 000 and 311 directories make git print `warning: could not open directory 'priv/': Permission denied`, so the `hid/` case in test 18 is decided by checkout_md (M14), not by :531. Mutant M2s survives.
- Confidence: high (executed)
- Legibility-target: implementer

**G4 — skipping an index-only start deleted from the checkout is unpinned**
- Severity: low (both survivors fail closed; a regression would stop every walk on a branch holding such a deletion, a liveness loss rather than a fail-open)
- Location: scripts/lib/dev-cycle-read.sh:533, :590
- Evidence: `[[ $c -ne 1 ]] || return 1; [[ $c -eq 0 ]] || continue`. The pre-U2a3c header said a start main lacks fails the walk "(even one deleted from the checkout)"; cebfed35 skips it, and no test has a `t:` start that main_checkout answers 2 for. M8 (fail) and M9 (queue and read) both survive.
- Confidence: high (executed)
- Legibility-target: implementer

**G5 — four inert `git rm` lines and their comments**
- Severity: low
- Location: test/scripts/build-loop-check.bats:92, :191, :199 (with :206), :244
- Evidence: `git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup-start)"; git rm -qf CLAUDE.md  # no index-only start masks the refusals below` (and the same at :191 `# no index-only start masks the NUL count`, :199 `# no index-only start masks the tree-listing refusal`, :244 `# no index-only start masks the empty-text check`). Under U2a3c an index-only start is walked, not refused. With all four removed and :206 restored to its U2a3 form (`rm .git/index && commit_all again`), the suite stays 18/18 and the refusals they claimed to protect are still killed: NUL count (E1, test 9), empty link text (E2, test 12), duplicate name (E3, tests 5/16), tree listing (E5, test 10).
- Confidence: high (executed)
- Legibility-target: implementer (a reader is told a guard exists that does nothing)

## Recommended Tests

#### Test 18: a rule under main's `.claude/rules` link that imports nothing

**Closes gaps:** G1
**Type:** integration (fixture repo)
**Priority:** high
**File:** test/scripts/build-loop-check.bats, test 18 (:322-323)
**What it verifies:** a start main lacks under a directory main stores as a link fails the walk through its own admission check, not its import's.
**Key cases:**
- main: `.claude/rules -> ../docs`, `docs/foo.md` = `see @bar.md`; checkout: plain `.claude/rules/foo.md` = `harmless` → `walk: failed`, `docs/bar.md: imported`.

**Setup needed:** replace the `cp docs/foo.md .claude/rules/` with `printf 'harmless\n' > .claude/rules/foo.md`; the `ld/` case above it keeps covering the import-through-link shape.

#### Test 18: an untracked start under a directory main stores as a gitlink

**Closes gaps:** G2
**Type:** integration
**Priority:** medium
**File:** test/scripts/build-loop-check.bats, end of test 18
**What it verifies:** the 160000 half of the parent arm for a start.
**Key cases:**
- main gains `sm` as a gitlink (mktree); the checkout holds plain `sm/CLAUDE.md` = `harmless` → `walk: failed`, `docs/q.md: imported`.

**Setup needed:** `git mktree` + `git commit-tree` + `git update-ref`, as test 12.

#### Test 18: an untracked start under an `r--` directory

**Closes gaps:** G3
**Type:** integration
**Priority:** medium
**File:** test/scripts/build-loop-check.bats, test 18, after the `priv` import case
**What it verifies:** a start git lists without a warning, under a readable but unsearchable directory, fails the walk at :531.
**Key cases:**
- `pv/CLAUDE.md` = `harmless`, `chmod 644 pv` → `walk: failed`, `docs/q.md: imported`; `chmod 755 pv` before the asserts so cleanup works when one fails.

**Setup needed:** none beyond chmod; uses a directory no import names, so the import-side check cannot decide it.

#### Test 3: an index-only start deleted from the checkout is skipped

**Closes gaps:** G4
**Type:** integration
**Priority:** low
**File:** test/scripts/build-loop-check.bats, test 3 (after :62)
**What it verifies:** a start only the index holds, absent on disk, loads nothing and does not fail the walk.
**Key cases:**
- after `git add -f CLAUDE.local.md`, `rm CLAUDE.local.md` → `walk: ok`, `docs/private.md: -`.

**Setup needed:** none.

#### Drop the inert `git rm` lines

**Closes gaps:** G5
**Type:** test hygiene
**Priority:** low
**File:** test/scripts/build-loop-check.bats :92, :191, :199, :206, :244
**What it verifies:** nothing new. Removes four lines whose comments claim a guard that no longer exists.

All five are in the Appendix patch.

## What NOT to Test

- **M3 / M18 (readable check vs. read-failure arm):** each is redundant with the other. `-r` at :532 refuses an unreadable plain file, and the :600 redirect fails on the same file if `-r` is skipped, so a test can only tell them apart with a race between the two. Together (E4) they are killed by test 9's `chmod 000 CLAUDE.local.md`. No test.
- **M13 (phase ordering):** the walk's output is a set (IMPORTED_MAIN membership), `seen` stops a repeat, `${ent[$f]-checkout}` picks the read source per path, and any failure fails the whole walk. Reading a checkout start before main's starts cannot change the answer. Fact-check Claims 4/17b (`seen[$p]=1` before main_checkout for imports) are the same: no behavioural effect. No test.
- **checkout_md failing on any git stderr (fact-check 10b, e.g. `GIT_TRACE=1`):** fails closed; pinning it would freeze a refusal nobody relies on.
- **`${ent[$f]-checkout}` vs `:-`:** ent values are never empty (the :574 record regex). Equivalent.

## Coverage Gaps Beyond Current Scope

**1.** The cache-key override row (IMPORTED_MAIN_DONE ignores the checkout) is pinned as current behaviour by test 16; when U2b makes the gate clear it, test 16's `- - z.sh` tail must change with it.
**2.** GIT_INDEX_FILE / core.fsmonitor / sparse checkout hiding a start (override row, Defer) stay untested; the caller owns git config.
**3.** A start under a gitlink that the checkout's index also records as a gitlink: whether `ls-files --others` lists inside it decides reachability (A5, settled). G2's test covers only the index-lacks-it shape.

## Summary

The highest-value addition is G1: the start-only link-parent refusal the fact-check flagged (Claim 22a) is confirmed unpinned (M1s survives), and its gitlink half (G2, E6) and unsearchable-directory half (G3, M2s) are unpinned the same way, because every existing fixture for those arms either imports through the refused directory or is refused earlier by checkout_md. All three are fail-open mutants against code that is correct today. The appendix patch closes G1-G5 in the test file only (+13/-8 lines, net +5, of which +4 code lines; lib untouched), takes the suite to 18/18 and kills every non-equivalent mutant (29 of 32; the three survivors are argued equivalent above). Residual risk: the A5 shapes and the deferred git-config bypasses.

## Goal-Alignment Note

**Success criterion (verbatim):** "a markdown report saved at the output path given in your tail section, structured per your skill, with every finding carrying Location, verbatim Evidence, Severity/verdict, Confidence and Legibility-target."

**Answered:** Five gaps (G1-G5), each a concrete test case, each finding with Severity, Location, verbatim Evidence, Confidence and Legibility-target. The checked patch (Appendix) closes all five; it applies with `git apply --check -p1` to the worktree, the patched suite is 18/18, and M1s, E6, M2s, M8 and M9 are killed. `scripts/hermeticity-lint --root` on the patched copy: clean. No `'` in a skip message, no backtick added to lib code, no comment line starting with "Claude". Only this report was written in the worktree.

**Out of scope:** lib changes (none needed: no fail-open in the code itself), the wording findings (Claims 4/17b, 6, 21) and the U2a3b parser.

**Escalate:**
- (a) implementer: apply the Appendix patch (`/tmp/u2a3c-ts-a4ag/test-strategy-u2a3c.patch`, `git apply -p1` from the worktree root). Lib line count unchanged; the test file grows by 5 lines net.
- (b) implementer: if G4's skip of a deleted index-only start is not the intended contract, flip its assertion; either way the new line pins whichever is chosen.

## Appendix: checked patch

Applied to `/tmp/u2a3c-ts-a4ag/w2` (a copy of the worktree's lib, suite and fixtures at cebfed35). Result: 18/18 ok; mutant table in `/tmp/u2a3c-ts-a4ag/mut-w2.txt` (29/32 killed; M3, M13, M18 survive as equivalents). File: `/tmp/u2a3c-ts-a4ag/test-strategy-u2a3c.patch`.

```diff
--- w/test/scripts/build-loop-check.bats
+++ w2/test/scripts/build-loop-check.bats
@@ -60,6 +60,7 @@
     printf 'Mine: @docs/private.md\n' > CLAUDE.local.md; imps main docs/private.md docs/guide.md; want walk ok; want docs/private.md imported; want docs/guide.md -
     printf 'CLAUDE.local.md\n' > .gitignore; imps main docs/private.md; want walk ok; want docs/private.md imported
     git add -f CLAUDE.local.md; imps main docs/private.md; want walk ok; want docs/private.md imported
+    rm CLAUDE.local.md; imps main docs/private.md; want walk ok; want docs/private.md -  # an index-only start deleted from the checkout loads nothing
 }
 
 @test "main walk fails closed when an instruction blob cannot be read or main is not found by name (U2a2)" {
@@ -89,7 +90,7 @@
     # file listed twice: each fails the walk rather than reading one copy.
     l="$(printf 'x' | git hash-object -w --stdin)" && b="$(printf '@docs/b.md\n' | git hash-object -w --stdin)"
     t="$(printf '120000 blob %s\tAGENTS.md\n100644 blob %s\tAGENTS.md\n' "$l" "$b" | git mktree)"
-    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup-start)"; git rm -qf CLAUDE.md  # no index-only start masks the refusals below
+    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup-start)"
     imps main docs/b.md; want walk failed; want docs/b.md imported
     t="$(printf '100644 blob %s\tAGENTS.md\n100644 blob %s\tz.txt\n100644 blob %s\tz.txt\n' "$a" "$a" "$a" | git mktree)"
     git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup-other)"
@@ -188,7 +189,7 @@
     # Symlink text holding a NUL: $(...) would drop it and follow another name.
     l="$(printf 'docs/rules.md\0zzz' | git hash-object -w --stdin)"
     t="$(printf '120000 blob %s\tAGENTS.md\n100644 blob %s\tdocs-rules.md\n' "$l" "$(git rev-parse main:docs/rules.md)" | git mktree)"
-    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m nul-link)"; git rm -qf CLAUDE.md  # no index-only start masks the NUL count
+    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m nul-link)"
     imps main docs/rules.md; want walk failed; want docs/rules.md imported
 }
 
@@ -196,14 +197,14 @@
     mkdir -p docs && printf 'see @a.md\n' > docs/CLAUDE.md && commit_all base
     imps main docs/a.md; want walk ok; want docs/a.md imported
     # The docs/ tree object is missing: ls-tree -r fails part-way.
-    o="$(git rev-parse main:docs)"; rm ".git/objects/${o:0:2}/${o:2}"; git rm -qf docs/CLAUDE.md  # no index-only start masks the tree-listing refusal
+    o="$(git rev-parse main:docs)"; rm ".git/objects/${o:0:2}/${o:2}"
     imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/b.md imported
     # A corrupt index: git ls-files --cached --others fails.
     git update-ref refs/heads/main "$(git commit-tree "$(printf '' | git mktree)" -m empty)"
     printf 'junk' > .git/index
     imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/b.md imported
     # A tr that fails (docs/CLAUDE.md is a tracked start again): the lower-cased list comes back short.
-    rm .git/index && mkdir -p docs && printf 'see @a.md\n' > docs/CLAUDE.md && commit_all again
+    rm .git/index && commit_all again
     mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/sh\nexit 1\n' > "$BATS_TEST_TMPDIR/bin/tr" && chmod +x "$BATS_TEST_TMPDIR/bin/tr"
     PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; rm "$BATS_TEST_TMPDIR/bin/tr" && printf '#!/bin/sh\ncase " $* " in *" --cached "*) exit 1;; esac\nexec %s "$@"\n' "$(command -v git)" > "$BATS_TEST_TMPDIR/bin/git" && chmod +x "$BATS_TEST_TMPDIR/bin/git"; PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; rm "$BATS_TEST_TMPDIR/bin/git"  # and a git whose ls-files --cached fails
     # An import list past 64 KiB with no room for a temp file is read whole (U2a3b I2-C4).
@@ -241,7 +242,7 @@
     # Empty symlink text in sub/ would name sub/ itself, a plain directory here.
     e="$(printf '' | git hash-object -w --stdin)"
     s="$(printf '120000 blob %s\tAGENTS.md\n' "$e" | git mktree)"
-    git update-ref refs/heads/main "$(git commit-tree "$(printf '040000 tree %s\tsub\n' "$s" | git mktree)" -p main -m empty-link)"; git rm -qf CLAUDE.md  # no index-only start masks the empty-text check
+    git update-ref refs/heads/main "$(git commit-tree "$(printf '040000 tree %s\tsub\n' "$s" | git mktree)" -p main -m empty-link)"
     imps main docs/x.md; want walk failed; want docs/x.md imported
     # An import into a path main stores as a gitlink (sub/ is an empty directory here).
     t="$(printf '100644 blob %s\tCLAUDE.md\n160000 commit %s\tsub\n' "$(printf 'see @sub/x.md\n' | git hash-object -w --stdin)" "$(git rev-parse main)" | git mktree)"
@@ -318,11 +319,15 @@
     imps main deep/secret.md; want walk failed; want deep/secret.md imported
     # The checkout makes ld a plain directory holding an untracked start: still failed, as main alone.
     rm ld && mkdir ld && cp deep/CLAUDE.md ld/; imps main deep/secret.md x.sh; want walk failed; want x.sh imported
-    # main stores .claude/rules as a link; the checkout holds a plain directory with an untracked rule.
+    # main stores .claude/rules as a link; the checkout holds a plain directory with an untracked rule that imports nothing (the start's own check, fact-check 22a).
     rm -r ld && git rm -q CLAUDE.md; mkdir -p .claude && ln -s ../docs .claude/rules && printf 'see @bar.md\n' > docs/foo.md && commit_all rules-link
-    rm .claude/rules && mkdir .claude/rules && cp docs/foo.md .claude/rules/; imps main docs/bar.md; want walk failed; want docs/bar.md imported
-    # A readable but unsearchable directory holding an import main lacks; then an unreadable one only git's listing meets.
+    rm .claude/rules && mkdir .claude/rules && printf 'harmless\n' > .claude/rules/foo.md; imps main docs/bar.md; want walk failed; want docs/bar.md imported
+    # A readable but unsearchable directory holding an import main lacks, then a start; then an unreadable one only git's listing meets.
     rm -r .claude && git rm -q -r --cached .claude && printf 'see @priv/x.md\n' > AGENTS.md && commit_all priv && mkdir priv && printf 'p @q.md\n' > priv/x.md && chmod 644 priv
     imps main docs/q.md; chmod 755 priv; want walk failed; want docs/q.md imported
+    mkdir pv && printf 'harmless\n' > pv/CLAUDE.md && chmod 644 pv; imps main docs/q.md; chmod 755 pv; want walk failed; want docs/q.md imported; rm -r pv
     rm -r priv && mkdir hid && printf 'h @q.md\n' > hid/CLAUDE.md && chmod 000 hid; imps main docs/q.md; chmod 755 hid; want walk failed; want docs/q.md imported
+    # main stores sm as a gitlink; the checkout holds a plain directory with an untracked start that imports nothing.
+    t="$(printf '100644 blob %s\tAGENTS.md\n160000 commit %s\tsm\n' "$(git rev-parse main:AGENTS.md)" "$(git rev-parse main)" | git mktree)"; git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m gitlink)"
+    mkdir sm && printf 'harmless\n' > sm/CLAUDE.md; imps main docs/q.md; want walk failed; want docs/q.md imported
 }
```
