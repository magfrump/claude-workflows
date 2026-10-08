Commit: d7cdc1ea
# Code Review Rubric

**Branch:** `feat/build-loop-u2a4` (U2a4, the self-merge floor over one read-as-truth rule and one start predicate), on main 7afdb8d2.
**Status: ⚠️ ITERATION 1 NOT CLEAN — no red; 6 ambers, all fixed; next pass reviews the fixes** (single-sample review; absence of findings is not an attestation)

## Iteration 1 of 3 (Commit d7cdc1ea, `--loop-pass`, k=1)

Scope: full branch `main...HEAD` (no canonical rubric for this slug yet). Delivery mode: self-read (a shared brief file, then each agent ran `git diff main...HEAD`). The first-red short-circuit did not fire because the fact-check found no Incorrect. Panel: security, performance, api-consistency, architecture (auto-selected: the lib's public surface changed). test-strategy was not selected (the source changes carry tests); tech-debt-triage was not selected (6 files, under 500 lines).

Reports (all `Commit: d7cdc1ea`):
- `code-fact-check-report-build-loop-u2a4.md`: k=1, 30 claims. 22 Verified, 6 Mostly accurate, 1 Stale, 0 Incorrect, 1 Unverifiable.
- `security-reviewer-review-2026-10-07-build-loop-u2a4.md`: 2 Medium, 2 Low (all under-reads, executed in fixture repos).
- `performance-reviewer-review-2026-10-07-build-loop-u2a4.md`: 3 Low, 1 Informational. The extra bases stay inside both budgets.
- `api-consistency-reviewer-review-2026-10-07-build-loop-u2a4.md`: 2 Inconsistent, 4 Minor, 1 Informational. Nothing Breaking.
- `architecture-review-review-2026-10-07-build-loop-u2a4.md`: 1 Coupling, 5 Minor, 2 Informational. Nothing Structural.

Stage 2.5 was skipped (loop pass), so the routed security and performance endorsements wait for the final pass to verify them by execution.

Tests after fixes: build-loop-check 78/78, build-loop-read 19/19, dev-cycle 78/78, fixture-git-env 2/2, fixture-hermeticity 2/2, hermeticity-lint 53/53; shellcheck -S warning clean on both scripts. --check-fix output is still identical to main's over the 3,092 whitespace-free tracked paths. Size: 443 code lines against main, up from 381 at step 1a (override log row "The unit measured 381 code lines...").

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | A quoted mention in a command, `@"docs/q.md"`, passes the floor and --check-fix. Claude Code 2.1.293's prompt-mention reader accepts the quote, but the parser keeps it in every name. | Medium | security F1 (executed against the fixture; the binary's reader was found, its caller untraced) | Fixed | `emit` also reads a name without its leading `"`, for every file (a superset). Tested in both walks. |
| A2 | `.claude/skills/<name>/SKILL.md` names resolve only against the file's own directory, not the session's, so a skill's `@docs/k.md` passes. | Medium (Low confidence: untraced whether skills expand `@`) | security F2 | Fixed | `skills` was added to PROMPT_DIR and the prefilter (an untraced superset). Tested. |
| A3 | The floor wiring relies on a cache that a caller resets by assigning a variable by name. Contract item 4 was only a comment. | Coupling | architecture F1 | Fixed | `import_reset`, which contract item 4 now names. Tested: a checkout change goes unseen until the reset, and seen after it. |
| A4 | `truthwalk` left TRUTH_WHY=imported when it returned 1. | Inconsistent | api-consistency 1 | Fixed | It now returns 1 with TRUTH_WHY empty. Tested. |
| A5 | `truthrule`, `isstart` and `ownfile` under-refuse a mixed-case path; only the current callers' lower-casing keeps them right. | Inconsistent | api-consistency 2 | Fixed | `truthrule` refuses an upper-case letter as `case`, and floor words it. Contract item 8 says to lower-case first. The truthrule table test has a mixed-case row. |
| A6 | `isstart` and the `instruction_names` prefilter spell the start rule twice, and no test holds them equal. A widened isstart with a stale grep would make --check-fix under-read silently. | Minor (under-read class) | architecture F6; fact-check check 2 (0 misses over 234,256 generated paths) | Fixed | A table test compares the two over 3 depths × 10 instruction names × 6 dirs × 3 tails × 2 cases. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | prompt_dir's greedy match takes the innermost `.claude/` (a/.claude/commands/b/.claude/commands/x.md misses `a`) | security F3, fact-check Claim 20 / escalation 1 | Fixed: `prompt_bases` adds the top level and the directory holding every enclosing `.claude/`. Tested |
| C2 | A top-level prompt is read against the top level twice (`xs=("" "")`): about 40% more parser work for the same output | performance F1 | Fixed by `prompt_bases` (one entry each) |
| C3 | "The top level" is spelled in both walks; one helper should return the base list | architecture F2 | Fixed: `prompt_bases` |
| C4 | The plan's U2b bullet kept an older, diverging copy of the contract; F11 pointed to the wrong copy | architecture F3; fact-check Claims 9, 11 (Stale) | Fixed: the bullet now points to the header and lists its items; F11 points to the header |
| C5 | The tree walk skips a symlinked prompt start (--check-fix ok); A2 was stale | security F4 | A2 updated; deferred (override row) |
| C6 | The output budget binds before the work budget for prompt starts; the per-line loop is uncharged | performance F2 | Won't-Fix (override row) |
| C7 | floor lower-cases twice; its glob membership test is linear in the walk list | performance F3 | Deferred to U2c (override row) |
| C8 | The tree walk forks once per start; vendored prompt copies widen the start set | performance F4 | Deferred (override row) |
| C9 | `truthwalk LP WALK` takes the opposite argument order from `isimported WALK PATH` | api-consistency 3 | Fixed: `truthwalk WALK PATH` |
| C10 | A file only a prompt imports is worded as "an instruction file names it"; the --check-fix header lists instruction files only | api-consistency 4 | Header fixed ("an instruction or prompt file, or a file one names after an @"); skip wording kept (pinned by dev-cycle.bats) |
| C11 | FLOOR_WHY is a sentence, not a word | api-consistency 5 | Deferred to U2c (override row) |
| C12 | The header's need_root and caller's-shell list omits floor and truthwalk | api-consistency 6 | Fixed |
| C13 | The status-letter form (R100), the deleted-path spelling, and floor before resolve_main are not specified | api-consistency 7 | Status letter documented on floor; the rest Won't-Fix (override row) |
| C14 | floor covers D5 items 1-4; composition is each caller's | architecture F4 | Named in floor's comment; the composed entry is deferred to U2c (override row) |
| C15 | check_fix maps only `cycle`; the lib comment described check_fix's policy | architecture F5 | Lib comment trimmed; mapping Won't-Fix (override row) |
| C16 | One TRUTH_WHY global for two word sets | architecture F7 | Won't-Fix (override row) |
| C17 | Outside-repo starts need a second start source | architecture F8 | Deferred to U2b (override row) |
| C18 | `prompt_dirs` named in a comment; the function is `prompt_dir` | fact-check Claim 24 | Fixed (now `prompt_bases`) |
| C19 | Override rows said "3,092 tracked paths" (3,097 are tracked) and "fails the walk" (only the main walk) | fact-check Claims 2b, 3 | Rows corrected; the commit messages are recorded in an Accepted-immutable row |
| C20 | d861183d's red test 6 also failed for a fixture error | fact-check Claim 29 | Accepted-immutable row |
| C21 | "health check passed" in c934adbc was not re-run by the fact-check | fact-check Claim 30 (Unverifiable) | The step 5a gate runs it again |

### ✅ Confirmed Good

None this pass. The endorsements are pending execution verification (Stage 2.5 runs on the final pass).

### 🧩 Composition check

- `dev-cycle-read.sh` prompt_dir / walks' read lines (security F3, performance F1, architecture F2, fact-check Claim 20): one root, composed → C1-C3. A per-start helper that returns the whole base list removes all three (the fragments' own text names it); no tier lift.
- `dev-cycle-read.sh` truthrule/truthwalk (api-consistency 1, 2, 3; architecture F5, F7): distinct defects. Each fragment names its own mechanism and fix.
- Plan U2b bullet / F11 / header (architecture F3; fact-check Claims 9, 11): distinct statements of the same stale copy, already one fix (C4).

### ⏭️ Skipped Core Critics

None.

### Considered overrides

Matched rows: 204, 228, 308, 322, 324, 348, 370, 372, 376, 418, 419, 424, 435, 439, 459, 461 (this unit's revisit triggers), each disposed of in the six U2a4 rows dated 2026-10-07. No finding re-opened a settled row. api-consistency 5 points to row 376 and stays deferred with it.
