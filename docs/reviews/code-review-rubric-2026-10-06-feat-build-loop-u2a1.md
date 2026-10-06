Commit: d48f4645
# Code Review Rubric

**Scope:** full branch `main...feat/build-loop-u2a1` (iteration 2 at d48f4645, run as a final confirming pass; iteration 1 at 6f624cdf below); 233 changed code lines after iteration 2's fixes | **Reviewed:** 2026-10-06 | **Status: 🟡 fixes applied (91469367), iteration 3 confirming pass pending**

## Iteration 2 of 3 (Commit d48f4645, full branch, k=3, full panel; run as the final confirming pass, not clean)

Delivery mode: self-read. Critics: security, performance, api-consistency, architecture, test-strategy (the full panel). Stage 2.5 was not run: the pass found items to fix, so the routed endorsements stay pending execution verification and go to iteration 3's confirming pass.

Reports (all `Commit: d48f4645`):
- `code-fact-check-report-build-loop-u2a1.md`, merged, k=3 (replicates `-r1/-r2/-r3`: 40, 34, 37 claims). 53 clusters: 44 Verified, 9 Mostly accurate, 0 Incorrect. Agreement 88.7% (47/53). Escalations E1-E4, all to the orchestrator: E1 → C9, E2 → C10, E3 → rows 308/324, E4 informational.
- `security-reviewer-review-2026-10-06-final-build-loop-u2a1.md`: nothing in the diff; 1 Informational outside it (C7). A1/C5 and A2 re-executed: hold.
- `performance-reviewer-review-2026-10-06-final-build-loop-u2a1.md`: 1 Informational (C8).
- `api-consistency-reviewer-review-2026-10-06-final-build-loop-u2a1.md`: 4 Informational (A7, A8, A9).
- `architecture-review-review-2026-10-06-final-build-loop-u2a1.md`: 1 Minor (A7), introduced by A4.
- `test-strategy-review-2026-10-06-final-build-loop-u2a1.md`: G1, G2 Medium; G3 Low; G4-G6 moved to What NOT to Test. Patches in its scratch dir, applied in 91469367.

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| A7 | After A4, entry_why's `$2` plays a different role per word (subject, "for $2", ignored by notdir) while its comment says "named in the reason"; check_answer needed its own notdir arm to keep "it" right, so a new word could print the wrong "it" | Minor; Mostly accurate | architecture F1, api I1, fact-check 25a. Convergence | ✅ Fixed (91469367): comment states each word's use; check_answer ends every refusal "so no entry in $f is read" |
| A8 | entry_why read `$2` bare; called with one argument under `set -u` it printed an empty reason | Informational | api I2 | ✅ Fixed: `${2-}` |
| A9 | check_answer's notdir and error lines differ from main; the badform test's tag said U2a | Informational | api I3, I4 | ✅ Fixed (A7's wording; tag U2a1) |
| A10 | The `unset` line is pinned by no test: replacing it with `:` passes every test while a victim repo gains 7 and 5 commits | Medium (test gap) | test-strategy G1 | ✅ Fixed: test/scripts/fixture-git-env.bats; fails on that mutant |
| A11 | isclosed's `closed/*` prefix guard is pinned by no test: without it `--check-write 2026-01-01-x.md` prints ok (the write gate fails open) | Medium (test gap; executed) | test-strategy G2 | ✅ Fixed: new dev-cycle.bats test; fails on that mutant |
| A12 | main_entry's guard order (error before badform with no default branch) is unstated and unpinned | Low | test-strategy G3, fact-check r1/r2 annotation | ✅ Fixed: comment and one test line |
| A13 | Wording: "the skip message below repeats it" (three messages do); the lib header's :16 and :25 | Mostly accurate | fact-check 21a, 3, 7 | ✅ Fixed: "skip messages"; header reflowed whole |
| C7 | Five other suites write into an inherited GIT_DIR | Informational | security I1 | Defer (override row) |
| C8 | Per-test `git rev-parse` in setup (~0.1 s per run) | Informational | performance I1 | Won't-Fix (override row) |
| C9 | Untested: word-newline folding, check_brief's notdir/error via CLI, main_file's error via --settings | Low | test-strategy G4-G6, escalation E1 | Won't-Fix (override row) |
| C10 | build-loop-read.bats:84's older guarded `&&` chain | Informational | fact-check E2 | Defer (override row) |
| C11 | C4 override row's timings (measured 0.42-0.52 ms, 18-37 µs) | Mostly accurate | fact-check 13 | ✅ Row's figures corrected; the conclusion holds |

Immutable history: commit-message claims 37, 38a, 41b, 42 are `Accepted-immutable` override rows.

Composition check: one cluster, `scripts/lib/dev-cycle-read.sh:280-292` with `:569-575` (architecture F1, api I1/I2, fact-check 25a): composed into A7, one root (the argument's role differs per word) with one fix; A8 is distinct (an unset-variable read).

Tests after 91469367: 98/98 (dev-cycle 75, build-loop-read 19, fixture-git-env 2, hermeticity 2) under a TMPDIR with no dot-prefixed part; shellcheck clean; the fix-drift check over d48f4645..91469367 found nothing.

## Iteration 1 of 3 (Commit 6f624cdf, `--loop-pass`, full branch, k=1)

Delivery mode: self-read (each agent ran `git diff main...HEAD`; the enclosing files are ~213 KB, over the inline budget). Critics: security, performance, api-consistency (core); architecture (auto-selected: the lib's caller contract gains `isclosed`, `entry_why` and the `badform` word). test-strategy not selected: every source change has test changes beside it. No short-circuit: no behavioural red. Stage 2.5 skipped (loop pass); routed endorsements stay pending execution verification.

Reports (all `Commit: 6f624cdf`):
- `code-fact-check-report-build-loop-u2a1.md`: k=1. 24 claims: 20 Verified, 3 Mostly accurate, 1 Unverifiable, 0 Incorrect. Executed: badform with 0 git calls; isclosed equal to all three old spellings on 23 edge cases; the positive control and the split chains each fail their mutants.
- `security-reviewer-review-2026-10-06-build-loop-u2a1.md`: 1 Medium, 1 Low, 2 Informational.
- `performance-reviewer-review-2026-10-06-build-loop-u2a1.md`: 2 Informational (measured).
- `api-consistency-reviewer-review-2026-10-06-build-loop-u2a1.md`: 3 Minor, 1 Informational.
- `architecture-review-review-2026-10-06-build-loop-u2a1.md`: 0 Structural, 0 Coupling, 1 Minor, 3 Informational.

Considered overrides (matched in Step 3.5): rows 228, 292, 306, 314, 317-320 are Defer rows whose triggers this unit meets, and the diff addresses each (fact-check claim 8); row 204 is closed by this iteration's C1 row; row 308 is extended by C3; rows 202, 203, 233, 284, 298, 312 match by location and stay with U2a2/U2b.

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| A1 | `test/scripts/dev-cycle.bats:8-26` setup() did not clear an inherited `GIT_DIR`: executed, the suite wrote 2 commits and branch f1 into a victim repo. The fixture header's "same hermetic git environment" became false. | Medium | security F1 | ✅ Fixed: both setups run `unset $(git rev-parse --local-env-vars)`; checked, the victim keeps 1 commit |
| A2 | `entry_why` echoed the raw path in its badform and default arms; a newline path gave a second line `ok ...` (executed; no current caller reaches it, the floor will) | Low | security F2 | ✅ Fixed: entry_why turns newlines into spaces; new test |
| A3 | main_file's `error` reason lost the file path (`constraints unreadable: the tree ... could not be read`) | Minor | api F1 | ✅ Fixed: the error arm names the path when given |
| A4 | entry_why put the path into reasons whose skip line already names it (check_brief "skip A: A is not ..."; check_answer named `$f` twice and dropped the "so no entry in ... is read" sibling wording); badform's wording differed from the five "not an allowed path form" checks | Minor, Informational | api F2, F3 | ✅ Fixed: `$2` may be empty (subjectless reason); check_brief passes ""; check_answer says "so no entry in it is read" (in `$f` after notdir) |
| A5 | The comment above check_fix (`scripts/dev-cycle.sh:167-171`) omitted dotfiles and @-imports and called dev-cycle.md "the settings file"; the list is written in five places | Mostly accurate, Minor, Informational | fact-check, api F4, architecture I2. Convergence | ✅ Fixed: the comment points to the header paragraph and keeps only the why |
| A6 | Row 319 residue: short lines in the lib header (`:13`, `:25`) | Mostly accurate | fact-check | ✅ Fixed: reflowed |
| C1 | Row 204 closed only in plan text; the floor will list the shared subset again | Minor | architecture F1 | Defer (override row; trigger U2a2's floor) |
| C2 | `isbrief \|\| isclosed` at three call sites; an `anybrief` predicate | Informational | architecture I3 | Defer (override row; trigger U2b) |
| C3 | The floor must run its own rules before main_entry and refuse on any word but blob/absent, with a `.gitattributes` test | Informational | architecture I4, security I3 | Defer (override row; extends row 308; trigger U2a2) |
| C4 | entry_why's subshell (~0.3 ms per refusal); isclosed's per-brief cost | Informational | performance F1, F2 | Won't-Fix (override row) |
| C5 | Unset list narrower than `git rev-parse --local-env-vars` | Informational | security I4 | ✅ Fixed with A1 |
| C6 | "dev-cycle.bats 73 pass" unverifiable: test 25 cannot run under a TMPDIR with a dot-prefixed part | Unverifiable | fact-check | Resolved: 95/95 with test 25 run under a TMPDIR with no dot-prefixed part; the environmental failure predates this branch |

Immutable history: the commit's "the lib's check_fix" (Mostly accurate; check_fix is in dev-cycle.sh) is an `Accepted-immutable` override row.

Composition check: one cluster qualified, `scripts/dev-cycle.sh:167-183` (fact-check, api F4, architecture F1/I2): distinct defects, a stale comment (A5) and where the shared list lives (C1); A5's fix also removes the fifth copy's drift.

Tests after the fixes: 95/95 (dev-cycle 74 with the new entry_why test, build-loop-read 19, hermeticity 2); shellcheck clean. Size after the fixes: 165 changed code lines.
