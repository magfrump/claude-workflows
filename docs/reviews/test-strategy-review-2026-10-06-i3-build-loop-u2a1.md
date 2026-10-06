Commit: d07cc89c
# Test Strategy: feat/build-loop-u2a1 (iteration 3, final confirming pass)

**Scope:** `git diff main...HEAD` at d07cc89c, with the focus on iteration 2's fixes (91469367): scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats, test/scripts/build-loop-read.bats, test/scripts/fixture-git-env.bats, test/lib/build-loop-fixtures.bash
**Reviewed:** 2026-10-06
**Mode:** final confirming pass, full panel. The rubric (iterations 1-2) and override-log rows 306-330 are settled context. No row is re-filed here. G2 below argues why row 327's Defer rationale does not cover the new suite.

## Test Conventions

- The suites use bats-core (>= 1.5.0) and need a `# @category fast` tag. They are contract tests: each builds a throwaway repo under `$BATS_TEST_TMPDIR` and asserts whole output lines (`[ "$output" = ... ] || { echo "$output"; return 1; }`).
- Lib functions are tested in-process with `bash -c 'set -euo pipefail; source "$1"; ...' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh"` (dev-cycle.bats:1337-1379).
- The build-loop suites call `bl_setup` from test/lib/build-loop-fixtures.bash. dev-cycle.bats has its own `setup()`. Since d48f4645, both setups run `unset $(git rev-parse --local-env-vars)`.
- test/scripts/fixture-git-env.bats is new in 91469367. It runs bats inside bats, with `GIT_DIR` and `GIT_INDEX_FILE` pointed at a victim repo.
- The review convention is to check mutants by hand.

## Execution baseline

I extracted d07cc89c with `git archive` into a scratch copy and ran it with TMPDIR=`/tmp/u2a1i3x-*`. The run of dev-cycle.bats, build-loop-read.bats, fixture-git-env.bats and test/fixture-hermeticity.bats passed 98/98. I re-ran two mutants against dev-cycle.bats. M1 drops isclosed's `closed/*` guard: test 75 fails. M2 swaps main_entry's two guards: test 74 fails. [unverified — submitted as claim; route: code-fact-check]

I also checked the iteration-2 fixes against the tests:
- check_answer's merged `*)` arm (lib:576) is pinned word by word with exact lines: notfile at dev-cycle.bats:1198 and :1226-1228, notdir at :1203, and error at :1327. badform cannot be reached here because both paths are fixed and pass pathform.
- The comment changes to main_entry and entry_why have no branch to test.
- `${2-}` (lib:287) is the one fix with no test (G3).

## Untested Paths Touched by the Change

- **G1** — test/scripts/fixture-git-env.bats:17-22 (with header :3-6) — `victim_unchanged` checks only the victim's commit count and ref count, so the `GIT_INDEX_FILE` half of the header's contract is not covered.
  - **Executed:** I ran mutant A, which replaces `unset $(git rev-parse --local-env-vars)` with `unset GIT_DIR` in both setups. Both fixture-git-env tests pass. Run directly, the build-loop-read inner test rewrites the victim's index from 65 to 174 bytes, and `git -C "$V" ls-files` then lists `docs/dev-cycle.md`. The commit count stays 1 and the ref count stays 1. This confirms the stage-1 r2 annotation.
  - **Second part:** the dev-cycle half has a further problem. Its inner test (`^prints all eight sections`, dev-cycle.bats:40) stages nothing, so even an index check would not see mutant A through it. I verified this: with an index check added and that test kept, test 1 still passes under mutant A.
  - **Evidence:** `# named by an inherited GIT_DIR or GIT_INDEX_FILE (a run from a git hook, say):` / `    [ "$(git -C "$V" rev-list --all --count)" = 1 ] && [ "$(git -C "$V" for-each-ref --format=x | wc -l)" = 1 ] \` / `    run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f '^prints all eight sections' "$REPO_ROOT/test/scripts/dev-cycle.bats"`
  - **Legibility-target:** test/scripts/fixture-git-env.bats (its header states a contract that its assertion checks only in part)
- **G2** — test/scripts/fixture-git-env.bats:9-15 — the suite's own `setup()` does not clear the repo-local variables, so the suite is not covered for an inherited `GIT_DIR`, which is the exact environment it guards against.
  - **Executed:** I ran the HEAD suite with `GIT_DIR` and `GIT_INDEX_FILE` pointed at an outer victim. Both tests fail, and the outer victim goes from 1 to 3 commits, because `git init "$V"` and the `--allow-empty` commit go to the inherited repo. This confirms the stage-1 r3 annotation.
  - **Why row 327 does not cover it:** row 327 defers the same pattern in five other suites because they are "outside this unit's files; predates it". Neither condition holds here: this unit adds the file, and the unit's purpose is this guarantee.
  - **Evidence:** `setup() {` / `    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"` / `    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` / `    V="$BATS_TEST_TMPDIR/victim"` / `    git init -q -b main "$V"`
  - **Legibility-target:** test/scripts/fixture-git-env.bats
- **G3** — scripts/lib/dev-cycle-read.sh:286-288 — entry_why called with one argument (the `${2-}` default, iteration-2 fix A8) is not covered.
  - **Executed:** I reverted `p="${2-}"` to bare `p="$2"`, and the full unit test still passes. This matches the stage-1 survivor list. No caller passes one argument today.
  - **Evidence:** `  local w="${1//$'\n'/ }" p="${2-}"` / `  p="${p//$'\n'/ }"`
  - **Legibility-target:** scripts/lib/dev-cycle-read.sh (entry_why's optional-argument contract)

Paths I checked and found covered, so not listed as gaps: check_answer's single refusal arm (above), isclosed's prefix guard (M1), main_entry's guard order (M2), and check_fix's constraints.md refusal (dev-cycle.bats, the --check-fix tests).

## Recommended Tests

#### fixture-git-env checks the victim's index and clears its own environment

**Closes gaps:** G1, G2
**Type:** integration (runs each suite's real setup under a hostile environment)
**Priority:** medium (G1), low (G2). Both changes go in one patch to the same 32-line file.
**File:** test/scripts/fixture-git-env.bats. The checked patch is `g1-g2-fixture-git-env.patch` (Appendix).
**What it verifies:** a run of each suite with an inherited `GIT_DIR` and `GIT_INDEX_FILE` leaves the victim's commits, refs and index byte for byte as they were, and this suite does not write into an inherited repo itself.
**Key cases:**
- **Index check:** `setup()` copies `$V/.git/index` to `$BATS_TEST_TMPDIR/index.before`. `victim_unchanged` adds `cmp -s "$BATS_TEST_TMPDIR/index.before" "$V/.git/index"`. On failure it prints `git -C "$V" ls-files -s`.
- **Inner dev-cycle test:** it changes from `-f '^prints all eight sections'` to `-f 'check-answer needs a default branch found by name'`. That name matches one test, and the test runs `git add -A`, so mutant A shows through it.
- **Own setup:** `setup()` adds `unset $(git rev-parse --local-env-vars)` before `git init`, with the same SC2046 comment the other two setups use.
- **Executed in a scratch copy:**
  - The patched suite passes 2/2 at d07cc89c.
  - Under mutant A (`unset GIT_DIR` only), both tests fail.
  - Under the iteration-2 mutant (the unset replaced by `:`), both still fail.
  - With the outer `GIT_DIR` pointed at a victim, the patched suite passes 2/2 and that victim stays at 1 commit. The unpatched suite fails 0/2 and its victim goes to 3 commits.
  - test/fixture-hermeticity.bats passes 2/2 with the patch.
  - [unverified — submitted as claim; route: code-fact-check]

**Setup needed:** none new. `git init` with no index-touching command does create a 65-byte `.git/index` after the `--allow-empty` commit (observed), so `cp` has a file to copy.

#### entry_why with one argument prints a subjectless reason

**Closes gaps:** G3
**Type:** unit (in-process lib call)
**Priority:** low (one line in an existing test)
**File:** test/scripts/dev-cycle.bats:1337-1354, inside the existing `entry_why words each main_entry refusal ...` test. The checked patch is `g3-entry-why-one-arg.patch` (Appendix).
**What it verifies:** under `set -u`, a call with no `$2` acts like a call with `""`.
**Key cases:**
- Append `entry_why error` to the loop body. The expected output gains a last line, `the tree of the default branch could not be read`.
- Executed: the test passes at d07cc89c. Under the bare-`$2` mutant it fails with `$2: unbound variable`. [unverified — submitted as claim; route: code-fact-check]

**Setup needed:** none.

## What NOT to Test

- **Word-newline folding, check_brief's notdir/error through the CLI, and main_file's error through --settings:** these are settled as override row 329 (Won't-Fix) and are not re-filed. Iteration 2 added no caller that changes the row's premise.
- **A skipped inner test matching `"1..1"*"ok 1 "`:** `ok 1 # skip` would pass `victim_unchanged`, but neither selected inner test calls `skip`. A guard against that would pin a hypothetical.
- **The wording-only changes in 91469367** (the lib header reflow, the "skip messages" comment, the main_entry and entry_why comments): these are prose, and each behaviour they describe is pinned (the M2 test, the entry_why unit test).
- **The fact-check's "error and default arms drop 'for $2'" comment nuance (lib:283-284):** the behaviour is already pinned by the unit test's `""` lines for error and odd. Only the comment's wording is open, which is not a test gap.

## Coverage Gaps Beyond Current Scope

**1.** Five other suites still write into an inherited GIT_DIR (override row 327, Defer). With G2's patch, fixture-git-env.bats is a natural home for one test per suite when each suite is next edited, as the row's trigger already says.

**2.** shared_branches skips a brief that brief_fields refuses (rows 293/308, trigger U2a2's floor). No new test is proposed here.

## Summary

All iteration-2 fixes are correct, and all but one are pinned: check_answer's merged arm, isclosed's guard and main_entry's guard order each fail a test when reverted. The highest-value addition is G1. The new fixture-git-env.bats header promises protection against an inherited `GIT_INDEX_FILE`, but the suite checks only commits and refs. Executed, a mutant that unsets only `GIT_DIR` passes both tests while the victim's index gains a fixture file. Its dev-cycle half also uses an inner test that stages nothing. G2 is the same suite's own setup failing the property it tests (an outer victim goes from 1 to 3 commits), and both fit in one checked patch. G3 is a one-line test for A8's `${2-}`. None of the three is a defect in the shipped scripts. The residual risk after the plan is the row-327 suites outside this unit.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-i3-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: d07cc89c` as its first line.
- **Answered:** yes. This file has `Commit: d07cc89c` on line 1 and is structured per skills/test-strategy (conventions, gap list G1-G3 with Evidence and Legibility-target, recommended tests, what not to test, beyond scope, summary). Iteration 2's fixes (91469367) were checked: none is incorrect, and none introduced a behavioural defect. Two test-strength gaps are in the new suite (G1, G2), and one fix has no test (G3).
- **Out of scope:** writing the tests into the branch, since this is an advisory pass and the patches are in the scratch dir only. Re-filing override rows 306-330.
- **Escalate:** none. G1 (Medium) and G2/G3 (Low) are test gaps, not defects in d07cc89c. Whether to take the 32-line-file patch in this unit or defer it is the orchestrator's call at the iteration cap.
- **Decisions:** the scratch patches are `g1-g2-fixture-git-env.patch` and `g3-entry-why-one-arg.patch` under `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/test/`. The scratch copies and the `/tmp/u2a1i3x-*` TMPDIR are removed, no process is left running, and no tracked file was modified.

## Appendix: the checked patches (copied in by the orchestrator, since the scratch dir is removed with the job)

### g1-g2-fixture-git-env.patch

```diff
diff --git a/test/scripts/fixture-git-env.bats b/test/scripts/fixture-git-env.bats
index 5824372..6c7fb3e 100644
--- a/test/scripts/fixture-git-env.bats
+++ b/test/scripts/fixture-git-env.bats
@@ -8,10 +8,15 @@ bats_require_minimum_version 1.5.0
 
 setup() {
     REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
+    # This suite's own fixture must stay out of an inherited GIT_DIR too.
+    # shellcheck disable=SC2046  # word splitting is wanted: one name per line
+    unset $(git rev-parse --local-env-vars)
     export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
     V="$BATS_TEST_TMPDIR/victim"
     git init -q -b main "$V"
     git -C "$V" -c user.name=v -c user.email=v@example.invalid commit -q --allow-empty -m only
+    # The inner runs name the victim's index too: it must come out byte for byte.
+    cp "$V/.git/index" "$BATS_TEST_TMPDIR/index.before"
 }
 
 victim_unchanged() {
@@ -19,10 +24,11 @@ victim_unchanged() {
     [ "$status" -eq 0 ] && [[ "$output" == *"1..1"*"ok 1 "* ]] || { echo "$output"; return 1; }
     [ "$(git -C "$V" rev-list --all --count)" = 1 ] && [ "$(git -C "$V" for-each-ref --format=x | wc -l)" = 1 ] \
         || { git -C "$V" log --all --oneline | head; git -C "$V" for-each-ref; return 1; }
+    cmp -s "$BATS_TEST_TMPDIR/index.before" "$V/.git/index" || { git -C "$V" ls-files -s | head; return 1; }
 }
 
 @test "dev-cycle.bats fixtures stay out of an inherited GIT_DIR (U2a1)" {
-    run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f '^prints all eight sections' "$REPO_ROOT/test/scripts/dev-cycle.bats"
+    run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f 'check-answer needs a default branch found by name' "$REPO_ROOT/test/scripts/dev-cycle.bats"
     victim_unchanged
 }
 
```

### g3-entry-why-one-arg.patch

```diff
diff --git a/test/scripts/dev-cycle.bats b/test/scripts/dev-cycle.bats
index 251c006..0ca8130 100644
--- a/test/scripts/dev-cycle.bats
+++ b/test/scripts/dev-cycle.bats
@@ -1339,7 +1339,8 @@ caller unchanged" ] || { echo "$output $stderr"; return 1; }
     run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"
         for w in "notdir docs/w" notfile badform error odd; do entry_why "$w" docs/w/q.md; entry_why "$w" ""; done
         entry_why badform "a
-ok b"' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh"
+ok b"
+        entry_why error' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh"
     [ "$output" = "docs/w is not a directory on the default branch
 docs/w is not a directory on the default branch
 docs/w/q.md is not a regular file on the default branch
@@ -1350,7 +1351,8 @@ the tree of the default branch could not be read for docs/w/q.md
 the tree of the default branch could not be read
 the default branch answered odd for docs/w/q.md
 the default branch answered odd
-a ok b is not an allowed path form" ] || { echo "$output $stderr"; return 1; }
+a ok b is not an allowed path form
+the tree of the default branch could not be read" ] || { echo "$output $stderr"; return 1; }
 }
 
 @test "main_entry answers badform for a path pathform refuses, absent for a plain missing one (U1d, U2a1)" {
```
