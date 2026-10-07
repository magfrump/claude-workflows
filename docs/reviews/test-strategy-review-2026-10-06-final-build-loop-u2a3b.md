Commit: e48cf0f7

# Test Strategy: feat/build-loop-u2a3b, final confirming pass (iteration 3 of 3)

**Scope:** `git diff main...HEAD -- scripts test docs/working` at e48cf0f7: `scripts/lib/dev-cycle-read.sh` (import_targets, instruction_names, tree_starts, imported_names, the main_imports lower guard, isimported), `scripts/dev-cycle.sh` check_fix, and the two bats suites. I also ran mutants of the branch's code.
**Reviewed:** 2026-10-06
**Role:** test-strategy (contextual, advisory). The Stage-1 fact-check routed two escalations here (see "Fact-check escalations" below).

## Method

- Scratch copy `/tmp/u2a3b-tsf-2n1r` made from `git archive HEAD`. Baseline: 119/119 across the five suites (45 s).
- 28 hand-written mutants were applied one at a time to separate copies. Each copy ran `build-loop-check.bats`, `build-loop-read.bats` and `dev-cycle.bats`. The harness and logs are in `/tmp/u2a3b-tsf-2n1r-h/` (`mutants.py`, `M*.res`).
- The surviving mutants were run again against the patched suite (Appendix A), which also passed 120/120 across all five suites, `fixture-hermeticity.bats` included. `git apply --check` of the patch against the worktree HEAD succeeds.
- Settled override rows were not re-run or re-filed: the grep status-2 guard, the `) ]` and backtick strips, and per-token dedup (equivalent survivors), plus rows 346/347/350/355/363. The per-path lower guards (`imported_names`, `main_imports`) are deferred survivors in rubric row C1, with the reason "a failing tr fails main_imports earlier". **New evidence:** a tr shim that fails only on one marker string kills both guards cheaply (G2, G3). The deferral's reason therefore no longer holds, so I re-file them.

### Mutant results at e48cf0f7 (current suite)

| Mutant | Site | Result |
|---|---|---|
| M02 cached error returns 0 | lib:566 | killed (test 20) |
| M05 start listing `\|\| true` | lib:568 | killed (tests 20, 95) |
| M06 drop newline-name guard | lib:571 | killed (20) |
| M07 start-name lower `\|\| true` | lib:572 | killed (20) |
| M14 isimported tree without `\|\| return 0` | lib:678 | killed (20) |
| M15 drop check_fix's walk-failed branch | dev-cycle.sh:181-182 | killed (95) |
| M16 sed `\|\| true` | lib:518 | killed (20) |
| M18 one comment only | lib:521 | killed (19) |
| M21 drop untracked_md from tree_starts | lib:562 | killed (3, 20, 97, 103) |
| M22 drop the empty-line skip | lib:583 | killed (103) |
| M23 `~/` drop widened to `~` | lib:537 | killed (19) |
| M24 cut at first mark only | lib:543 | killed (19, 96) |
| M25 `<` removed from cut marks | lib:515 | killed (19) |
| M26 instruction_names `\|\| true` | lib:554 | killed (20) |
| **M08** walk read/parser failure `\|\| true` | lib:581 | **survives** (G1) |
| **M09** same, without `IMPORTED=error` | lib:581 | **survives** (G1) |
| **M10** per-path lower `\|\| true` | lib:584 | **survives** (G2) |
| **M11** same, without `IMPORTED=error` | lib:584 | **survives** (G2) |
| **M12** main_imports lower `\|\| true` | lib:657 | **survives** (G3) |
| **M13** isimported lower of $2 `\|\| true` | lib:675 | **survives** (G4) |
| **M01** delete the cache line | lib:566 | **survives** (G5) |
| **M19** tree_starts `&&` → `;` | lib:562 | **survives** (G6) |
| **M03** drop `IMPORTED=error` at walk start | lib:567 | **survives** (G7) |
| M04 initial `IMPORTED=$'\n'` | lib:481 | survives: equivalent (nothing reads IMPORTED before a walk; fact-check enumerated) |
| M20 tree_starts without its own pipefail | lib:562 | survives: equivalent while imported_names (which sets pipefail, inherited by nul_list's process substitution) is the only caller |
| M17 unclosed `<!--`: `break` instead of `x=""` | lib:523 | survives: only over-reads (the original text is still read), so it can only over-refuse |
| M27 drop `"$p" != ..` | lib:540 | survives: pre-existing; `..` is recorded and inrepo_here skips it (over-read) |
| M28 drop the INSTRUCTION_FILE recheck on starts | lib:573 | survives: pre-existing; instruction_names already applies the same name set |

After the Appendix A patch, M01, M08 to M13 and M19 each fail exactly one test (test 20 for M01, the new test 21 for the rest).

## Test Conventions

- bats-core suites under `test/scripts/`. `build-loop-check.bats` uses `bl_setup`, `commit_all`, and the `imps WALK PATH...` / `want PATH WORD` helpers, which print `walk: ok|failed` and `PATH: imported|-`.
- Failure injection uses PATH shims in `$BATS_TEST_TMPDIR/...` (the existing `bin/tr` exits 1; `gbin/grep` fails only on `-z`). Direct library calls run through `run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL=...'`.
- Gate: `test/fixture-hermeticity.bats` scans every suite for network-capable binaries. The patch passes it: the git shim `exec`s the real git, as the fixtures already do.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:581 — the tree walk's `out="$(import_targets "$d" < "$f")" || { IMPORTED=error; return 1; }` failure arm (a sed failure or a read failure on a start or imported file) — not covered. M08 (`|| true`) reads the failed file as importing nothing, and the walk returns ok. M09 (no `IMPORTED=error`) returns 1 once, then the cached call returns 0 with the partial list. Both are fail-opens for `--check-fix`.
- **G2** — scripts/lib/dev-cycle-read.sh:584 — failure arm of `lp="$(lower "$p")" || { IMPORTED=error; return 1; }` (lower of an imported path) — not covered. M10 records an empty line instead of the path and the walk returns ok. M11 makes the cached second call succeed with the partial list. The tr-always-fails test exits earlier, at :572.
- **G3** — scripts/lib/dev-cycle-read.sh:657 — the lower guard this unit adds to main_imports' import loop — not covered. The always-failing tr fails the walk earlier, at the candidate tr (:620/:621). M12 drops the imported path from IMPORTED_MAIN, and the walk returns ok. That walk feeds U2a4's self-merge floor.
- **G4** — scripts/lib/dev-cycle-read.sh:675 — isimported's `lp="$(lower "$2")" || return 0` arm on a walk that succeeds — not covered. Test 20 reaches it only while the walk has also failed, so `|| return 0` cannot be told apart from the walk's own refusal. M13 sets lp="" and answers "not imported" for any path whose lower fails.
- **G5** — scripts/lib/dev-cycle-read.sh:566 — the cache hit for a failed walk ("a cached error returns 1 again", lib :455-456) — partly covered. Test 20 calls imported_names twice, but both calls run under the same failing tr, so deleting the cache line (M01, a recompute) passes. The fact-check (r1, r2) escalated this.
- **G6** — scripts/lib/dev-cycle-read.sh:562 — tree_starts' `&&` between `git ls-files -z` and `untracked_md` (the "failing when any of the three commands fails" contract, :561) — the arm where only the tracked listing fails is not covered. The corrupt-index tests fail both listings, so M19 (`;`, which takes the group's status from untracked_md) passes, and the walk then starts from untracked files only.
- **G7** — scripts/lib/dev-cycle-read.sh:567 — `IMPORTED=error` at walk start, after a successful walk for another ROOT_REAL — not covered. With M03, a walk for root B that fails at the start list keeps root A's list, and B's cached second call returns 0 with it.

## Findings

Each finding's severity uses this skill's priority scale.

### F1 (G1): the walk's read/parser failure arm is untested, and both ways of reverting it fail open

- **Severity:** High. A one-token revert silently lets `--check-fix` pass a doc that an unreadable or unparsed instruction file imports. M09 also persists, through the cache, for every later call in the process. Setup is one PATH shim.
- **Location:** `scripts/lib/dev-cycle-read.sh:581`
- **Evidence:** `out="$(import_targets "$d" < "$f")" || { IMPORTED=error; return 1; }`. Mutants M08 and M09 pass all 119 tests at e48cf0f7.
- **Confidence:** High (executed).
- **Legibility-target:** for-author
- **Closes with:** Appendix A, new test 21, "parser fails" block (sed shim; two imported_names calls plus isimported tree).

### F2 (G2): imported_names' per-path lower guard is untested (new evidence against row C1's deferral)

- **Severity:** Medium
- **Location:** `scripts/lib/dev-cycle-read.sh:584`
- **Evidence:** `lp="$(lower "$p")" || { IMPORTED=error; return 1; }; IMPORTED+="$lp"$'\n'`. M10 and M11 survive. A tr shim that fails only when its input holds `trfail` lets the start names lower and fails this line alone, so "a failing tr fails earlier" no longer blocks a test.
- **Confidence:** High (executed).
- **Legibility-target:** for-author
- **Closes with:** Appendix A, test 21, "An imported path does not lower" loop (tree).

### F3 (G3): main_imports' new lower guard is unreachable by the current suite

- **Severity:** Medium (the main walk feeds U2a4's self-merge floor)
- **Location:** `scripts/lib/dev-cycle-read.sh:657`
- **Evidence:** `i="$(lower "$p")" || { IMPORTED_MAIN=error; return 1; }; IMPORTED_MAIN+="$i"$'\n'`. M12 survives. The fact-check's escalation reads: "no test reaches main_imports' new lower guard (lib :657), because the main walk fails earlier at its start-list tr".
- **Confidence:** High (executed). With the marker shim, `docs/trfail.md` is not in main's tree, so the candidate tr at :620 succeeds and :657 is the first lower to fail.
- **Legibility-target:** for-author
- **Closes with:** Appendix A, test 21, "An imported path does not lower" loop (main).

### F4 (G4): isimported's lower-of-$2 guard is not discriminated

- **Severity:** Medium (the mutant fails open: "-" for a path it could not lower)
- **Location:** `scripts/lib/dev-cycle-read.sh:675`
- **Evidence:** `lp="$(lower "$2")" || return 0`. M13 survives because test 20 reaches the guard only alongside a failed walk.
- **Confidence:** High (executed).
- **Legibility-target:** for-author
- **Closes with:** Appendix A, test 21, first loop (the walk succeeds, the asked `docs/trfail.md` answers imported, `docs/z.md` answers `-`, for both walks).

### F5 (G5): the cached-error assertion does not isolate the cache

- **Severity:** Low. Fail-closed either way; the mutant costs a re-walk. The test comment claims more than the test checks.
- **Location:** `test/scripts/build-loop-check.bats:372-376`; code at `scripts/lib/dev-cycle-read.sh:566`
- **Evidence:** the comment reads `# The tree walk itself, called twice: the second call returns its cached error.`, and both calls run under `env PATH="$BATS_TEST_TMPDIR/bin:$PATH"`. M01 passes.
- **Confidence:** High (executed).
- **Legibility-target:** for-author
- **Closes with:** Appendix A, first hunk: the second call runs with the real tr, so only the cache can make it fail.

### F6 (G6): tree_starts' `&&` is pinned only where both listings fail together

- **Severity:** Low (a tracked-only listing failure is unlikely, since both commands read the index, but the result is a fail-open)
- **Location:** `scripts/lib/dev-cycle-read.sh:562`
- **Evidence:** `tree_starts() { local -; set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names; }`. M19 survives.
- **Confidence:** High (executed).
- **Legibility-target:** for-author
- **Closes with:** Appendix A, test 21, last line (a git shim fails only the bare `ls-files -z`).

### F7 (G7): the start-of-walk error reset is untested across roots

- **Severity:** Low. No caller changes ROOT_REAL within one process except the tests, and dev-cycle.sh runs one root per process. Not patched; see What NOT to Test.
- **Location:** `scripts/lib/dev-cycle-read.sh:567`
- **Evidence:** `IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error`. M03 survives.
- **Confidence:** High (executed survival). Medium on the scenario's reach.
- **Legibility-target:** for-author

## Recommended Tests

#### Fail-closed paths past the start list (new test 21)

**Closes gaps:** G1, G2, G3, G4, G6
**Type:** integration (bats, real git fixture, PATH shims)
**Priority:** high
**File:** `test/scripts/build-loop-check.bats` (Appendix A)
**What it verifies:** every failure arm this unit adds after the start list makes the walk (and later cached calls) refuse rather than read a partial list.
**Key cases:**
- tr fails only on `trfail`, and the walk succeeds: `isimported tree|main docs/trfail.md` answers imported and `docs/z.md` answers `-` (G4).
- AGENTS.md imports `@docs/trfail.md`: both walks fail, and `docs/z.md` answers imported through the cache (G2, G3).
- sed always fails: imported_names fails twice and `isimported tree docs/z.md` answers imported (G1, both mutants).
- bare `git ls-files -z` fails while untracked_md succeeds: the tree walk fails and every path answers imported (G6).

**Setup needed:** three shim directories in `$BATS_TEST_TMPDIR`; nothing new in fixtures.

#### Cached error isolated (edit to test 20)

**Closes gaps:** G5
**Type:** integration
**Priority:** low
**File:** `test/scripts/build-loop-check.bats:372-376` (Appendix A, first hunk)
**What it verifies:** a failed tree walk stays failed for the root even after the cause goes away.
**Key cases:** the first call runs under the failing tr and reports "walk failed". The second call runs under the real tr and still reports "walk failed" (M01 would print "walked").
**Setup needed:** none.

## What NOT to Test

- **G7** (lib:567): its only reach is a second ROOT_REAL in one process with a start-list failure on the second root. dev-cycle.sh never does that, and test 103 (`dev-cycle.bats:1168`) already pins the recompute for a new root. If wanted, a two-line extension of test 103 with a corrupt index in `other` would kill M03.
- **Equivalent survivors:** M04, M20, M17, M27 and M28 (reasons in the mutant table), plus the settled override row (grep status-2 guard, the `) ]` and backtick strips, per-token dedup). None can make a walk under-read.
- **`--check-fix` with a failing tr** exits 1 with no output before check_fix's walk-failed branch. That is the security-reviewer's escalation (r3) and it is a wording issue: it refuses either way, so I leave it to that role and add no test here.

## Coverage Gaps Beyond Current Scope

**1.** main_imports' `IMPORTED_MAIN=error` resets in its own failure arms (lib :634, :639, :641, :646, :651, :653, :662, :663) are U2a3 context. Dropping the reset in the same way as M09 would make a cached second call succeed with a partial list. Test 17 covers "a failed walk stays failed" for some of these arms; I did not mutate the others, because they are U2a3's code.

## Fact-check escalations (Stage 1, addressed to test-strategy)

- r1, r2, "no test isolates the cached-error path": confirmed by M01. Closed by Appendix A's first hunk (G5).
- r1, r2, "no test reaches main_imports' new lower guard (lib :657)": confirmed by M12. Closed by the marker-tr loop in test 21 (G3). The same shim also closes imported_names' :584 guard (G2) and isimported's :675 guard (G4), which rubric row C1 had deferred for the same reason.

## Routed claims

- [unverified — submitted as claim] The patched suite passes 120/120 across the five named suites at e48cf0f7 plus the Appendix A patch, and `fixture-hermeticity.bats` passes.
- [unverified — submitted as claim] With the patch, mutants M01, M08, M09, M10, M11, M12, M13 and M19 each fail exactly one test. Unpatched, they each pass all 119.
- [unverified — submitted as claim] At e48cf0f7 the current suite kills M02, M05, M06, M07, M14, M15, M16, M18 and M21 to M26 (table above), so the iteration-1 and iteration-2 fixes (R1, R2, I2-A1 to I2-A4, I2-C1, I2-C12) remain pinned.

## Summary

The highest-value addition is test 21's sed-shim block. It pins the tree walk's read/parser failure arm (lib:581), and both ways of reverting that arm currently pass the whole suite while making `--check-fix` fail open; M09 also persists through the cache. A tr shim keyed on a marker string closes the three lower-guard gaps (lib:584, :657, :675) at almost no cost. That removes the reason rubric row C1 gave for deferring them, so I re-file them with that evidence. After the patch, the residual survivors are equivalent or over-read-only, plus G7, which no production caller reaches. One open question for the author: should the G7 cross-root reset be pinned anyway, given that the U2a3c checkout-side work may introduce a second root in one process?

## Appendix A: checked patch

Applied and run in `/tmp/u2a3b-tsf-2n1r`: 120/120 across the five suites. `git -C /workspace/.claude/wt-build-loop-u2a3b apply --check` passes against HEAD e48cf0f7.

```diff
diff --git a/test/scripts/build-loop-check.bats b/test/scripts/build-loop-check.bats
index 3c37e50..213fecd 100644
--- a/test/scripts/build-loop-check.bats
+++ b/test/scripts/build-loop-check.bats
@@ -370,10 +370,11 @@ scripts/x.sh: imported" ] || { echo "$output $stderr"; return 1; }
     imps tree docs/z.md; want walk failed; want docs/z.md imported
     rm -r "a"$'\n'"b" b
     # The tree walk itself, called twice: the second call returns its cached error.
-    run --separate-stderr env PATH="$BATS_TEST_TMPDIR/bin:$PATH" LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
+    # The second call runs with a working tr, so only the cache can fail it.
+    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"; p="$PATH"
         if import_targets "" < docs; then echo read; else echo failed; fi
-        if imported_names; then echo walked; else echo "walk failed"; fi
-        if imported_names; then echo walked; else echo "walk failed"; fi' _ "$LIB"
+        PATH="$2:$p"; if imported_names; then echo walked; else echo "walk failed"; fi
+        PATH="$p"; if imported_names; then echo walked; else echo "walk failed"; fi' _ "$LIB" "$BATS_TEST_TMPDIR/bin"
     [ "$output" = "failed
 walk failed
 walk failed" ] || { echo "$output $stderr"; return 1; }
@@ -391,3 +392,35 @@ walk failed" ] || { echo "$output $stderr"; return 1; }
     [ "$output" = "walk failed
 docs/z.md: imported" ] || { echo "$output $stderr"; return 1; }
 }
+
+@test "the walks fail closed past the start list: a parser failure on a file read, a failed lower of an imported or asked path, a failed tracked listing alone (U2a3b)" {
+    mkdir -p docs && printf 'see @docs/a.md\n' > AGENTS.md && printf 'x\n' > docs/a.md && commit_all base
+    tb="$BATS_TEST_TMPDIR/tb" sb="$BATS_TEST_TMPDIR/sb" gb="$BATS_TEST_TMPDIR/gb" && mkdir -p "$tb" "$sb" "$gb"
+    # A tr that fails only when its input holds "trfail", so the start names still lower;
+    # a sed that always fails; a git whose bare "ls-files -z" (the tracked half) fails.
+    t="$(command -v tr)" && printf '#!/bin/sh\nf="$(mktemp)" || exit 1\ncat > "$f"\nif grep -qa trfail "$f"; then rm -f "$f"; exit 1; fi\n%s "$@" < "$f"; r=$?; rm -f "$f"; exit $r\n' "$t" > "$tb/tr"
+    printf '#!/bin/sh\nexit 1\n' > "$sb/sed"
+    g="$(command -v git)" && printf '#!/bin/sh\n[ "$#" -eq 2 ] && [ "$1 $2" = "ls-files -z" ] && exit 128\nexec %s "$@"\n' "$g" > "$gb/git"
+    chmod +x "$tb/tr" "$sb/sed" "$gb/git"
+    # The asked path does not lower: either walk answers imported.
+    for w in tree main; do
+        PATH="$tb:$PATH" imps "$w" docs/trfail.md docs/z.md
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
+        want walk ok; want docs/trfail.md imported; want docs/z.md -
+    done
+    # An imported path does not lower: both walks fail (isimported's second call reads the cache).
+    printf 'see @docs/trfail.md and @docs/a.md\n' > AGENTS.md && commit_all trfail
+    for w in tree main; do
+        PATH="$tb:$PATH" imps "$w" docs/z.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/z.md imported
+    done
+    # The parser fails on a file the tree walk reads; the error stays cached.
+    run --separate-stderr env PATH="$sb:$PATH" LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
+        if imported_names; then echo walked; else echo "walk failed"; fi
+        if imported_names; then echo walked; else echo "walk failed"; fi
+        if isimported tree docs/z.md; then echo "docs/z.md: imported"; fi' _ "$LIB"
+    [ "$output" = "walk failed
+walk failed
+docs/z.md: imported" ] || { echo "$output $stderr"; return 1; }
+    # The tracked listing fails while the untracked listing works.
+    PATH="$gb:$PATH" imps tree docs/a.md docs/z.md; want walk failed; want docs/a.md imported; want docs/z.md imported
+}
```

The patch file is also at `/tmp/u2a3b-tsf-2n1r-h/g.patch`.

## Goal-Alignment Note

Success criterion: "A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: e48cf0f7` line at the top."
This report is saved at `docs/reviews/test-strategy-review-2026-10-06-final-build-loop-u2a3b.md` with `Commit: e48cf0f7` as its first line, structured per the test-strategy skill. It records mutant survival and gives a checked patch for each gap worth closing, as the role brief asked. No other worktree file was written.
