Commit: 6f624cdf
# Code Review Rubric

**Scope:** full branch `main...feat/build-loop-u2a1` at 6f624cdf (loop pass; no earlier rubric for this slug, so full-branch scope); 128 changed code lines by pr-prep 1a | **Reviewed:** 2026-10-06 | **Status: 🟡 fixes applied, re-review pending**

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
