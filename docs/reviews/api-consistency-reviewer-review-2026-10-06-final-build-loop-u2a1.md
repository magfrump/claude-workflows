Commit: d48f4645

# API Consistency Review — feat/build-loop-u2a1 (final confirming pass)

**Scope:** `git diff main...HEAD` at d48f4645 (6f624cdf unit, 706e0499 iteration-1 artifacts, d48f4645 iteration-1 fixes): scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/{dev-cycle,build-loop-read}.bats
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2a1-r{1,2,3}.md (Stage 1, k=3 at d48f4645); rubric docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md (iteration 1, A1-A6, C1-C6); docs/reviews/override-log.md rows 306-325

## Baseline Conventions

Unchanged from iteration 1's report (`api-consistency-reviewer-review-2026-10-06-build-loop-u2a1.md`), restated briefly:

- **Check-mode output:** one line per argument, `ok ...` or `skip <arg>: <reason>`. The reason is free English text; consumers act on the leading word, and the bats suites are the only consumers that pin the text. [unverified — submitted as claim: no script or doc outside test/ parses a `skip` reason; route: code-fact-check]
- **Reason subject:** check_brief's reasons drop the subject (its prefix names the brief); check_answer names the file it was reading and closes with `so no entry in $f is read` (lib:578-580); build-loop.sh's `FILE_WHY` reasons name `$f` (build-loop.sh:136, :138, :139) because the `--settings` prefix names a key, not a path.
- **Path-form refusal wording:** `not an allowed path form`, five check functions (dev-cycle.sh:146, :152, :162, :175; lib:343).
- **main_entry words:** lower-case run-together (`blob`, `absent`, `notfile`, `notdir PART`, `error`, now `badform`); callers `case` on them with a refusing default arm.
- **Lib function names / optional parameters:** snake_case multi-word functions, `is<noun>` predicates, `<word>why` / `<word>_why` reason mappers. An optional positional parameter is read with `${2:-}` (pathform, lib:142; skipped, lib:125); a required one is read bare (blocker, lib:115).
- **Test names:** a trailing parenthesised tag naming the unit that added or changed the test, e.g. `(U1d)` (build-loop-read.bats:414, :443, :451).

## Name-Pattern Audit

New public names on the branch are the same four as in iteration 1; d48f4645 adds none (it changes `entry_why`'s parameter contract, covered under Findings 2 and 3).

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `badform` | main_entry result word | `notfile`, `notdir`, `absent`, `error` | `scripts/lib/dev-cycle-read.sh:249-279` | Consistent (iteration 1; unchanged) |
| `isclosed` | lib path predicate | `isbrief`, `inrepo`, `writable` | `scripts/lib/dev-cycle-read.sh:157-162` | Consistent (iteration 1; unchanged) |
| `entry_why` | lib reason mapper | `oddwhy`, `main_entry`, `brief_fields` | `scripts/lib/dev-cycle-read.sh:232`, `:262`, `:309` | Consistent with the snake_case majority (iteration 1; unchanged) |
| `--check-fix` exclusion `constraints.md` | CLI allowlist entry | `dev-cycle.md`, `working/`, `decisions/` | `scripts/dev-cycle.sh:52`, `:181`; `skills/dev-cycle/SKILL.md:74` | Consistent: bare beside bare `dev-cycle.md` in header and skip reason, `docs/`-prefixed beside `docs/dev-cycle.md` in SKILL.md |
| test tag `(U1d, U2a)` | test-name unit tag | `(U1d)`, `(U2a1)` | `test/scripts/build-loop-read.bats:414,443,451`; `test/scripts/dev-cycle.bats:1338` | Names a unit that no longer lands (split into U2a1/U2a2); Finding 4 |

## Findings

#### 1. entry_why's comment says `$2` is "named in the reason", but the notdir arm ignores it, so each caller must know per arm whether the file was named

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:280-287`, `:572-574`; `scripts/build-loop.sh:133`
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
# Why main_entry's word $1 is not a file to read, for a skip line. $2 is the
# path, named in the reason; pass "" when the skip line already names it. A
# newline in either becomes a space, so the reason stays one line.
entry_why() {
  local w="${1//$'\n'/ }" p="${2//$'\n'/ }"
  case "$w" in
    notdir\ *) echo "${w#notdir } is not a directory on the default branch" ;;
```
(lib:280-286)
```
      # "it" is $f, except after notdir, whose reason names a directory above it.
      notdir\ *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in it is read"; return ;;
```
(lib:572-574)
```
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
```
(build-loop.sh:133)

The mapping was introduced so callers would not each word the refusals (row 228). For four of its five arms that holds: the reason names `$2` when given. The notdir arm never names `$2`, which the comment does not say (Stage 1 r3 records this as Mostly accurate). check_answer compensates with a separate arm and an explanatory comment; main_file does not, so `--settings` prints e.g. `constraints unreadable: docs is not a directory on the default branch` without the file. That main_file line is the same text main printed (main's notdir arm, removed at build-loop.sh:-132, had no `$f` either), so this is not a regression. The cost is to the next caller: U2a2's floor will be the fourth, and the comment as written tells it the path is always named. [unverified — submitted as claim: main_file's notdir reason text is byte-identical to main's; route: code-fact-check]

**Recommendation:** Either say so in the comment ("named in the reason, except after notdir, whose reason names the directory instead"), or make the notdir arm append `${p:+, above $p}` so every arm names `$2` when given and check_answer's special arm can go. The comment-only change is enough before U2a2.

#### 2. A one-argument call to entry_why under `set -u` prints `skip X: ` with an empty reason and carries on

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:283-284`
**Move:** 8 (nullability), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
entry_why() {
  local w="${1//$'\n'/ }" p="${2//$'\n'/ }"
```
(lib:283-284). Lib precedent for an optional positional parameter:
```
  [[ "${2:-}" == glob ]] && set="^[*?$NAMECHARS]+\$"  # * ? first: - must stay last
```
(lib:142, pathform; also `"${2:-file}"` in skipped, lib:125).

Executed (scratch dir, `set -euo pipefail`, lib sourced): `echo "skip x: $(entry_why notfile)"` wrote `line 284: 2: unbound variable` to stderr, printed `skip x: ` and exited 0; `out="$(entry_why notfile)"` exited 1. All three current callers pass two arguments and use the inline `$(...)` form, so nothing is wrong today. The in-code comment is precise ("pass \"\""), and blocker (lib:115) reads its required `$2` bare the same way, so this is consistent with the lib's required-parameter style. But the commit message and the unit's description call the path "optional (possibly empty)", and the lib's optional parameters are read with `${2:-}`. A floor author reading "optional" and omitting it gets a refusal whose reason is blank. It still fails closed (the line starts `skip`).

**Recommendation:** Read it as `${2-}` (one character), which makes the description true and matches pathform/skipped; or leave the code and treat the comment's "pass \"\"" as the contract. No test change needed beyond the existing `entry_why "$w" ""` cases.

#### 3. check_answer's notdir and error lines changed text against main (wording drift, consistent direction)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:573-574`; `test/scripts/dev-cycle.bats:1203`, `:1327`
**Move:** 3 (consumer contract), 4 (message consistency)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
-      notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch, so $f is not read"; return ;;
-      error) echo "skip $a: the tree of the default branch could not be read, so $f is not read"; return ;;
+      notdir\ *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
+      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in it is read"; return ;;
```
Both pinned lines in dev-cycle.bats were updated in the same commit. d48f4645's Notes say the old sentences "come back except where a path is now named"; Stage 1 (r1-r3) records that the notdir and error lines were reworded beyond that. The new wording matches check_answer's three sibling arms (`so no entry in $f is read`, lib:578-580), so this is drift toward the function's own convention, not away from it, and only the suites pin the text. Filed so the orchestrator does not read the Notes line as "check_answer text unchanged".

**Recommendation:** None for the code. The commit Notes are immutable history; an `Accepted-immutable` row, if the orchestrator wants one, is the place.

#### 4. Test tag `(U1d, U2a)` names a unit that no longer lands

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:1356`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: test-name tags name the landing unit that added or changed the test, `(U1d)` in test/scripts/build-loop-read.bats:414, :443, :451 and `(U2a1)` in test/scripts/dev-cycle.bats:1338

**Evidence:**
```
@test "entry_why words each main_entry refusal on one line, naming the path only when given (U2a1)" {
...
@test "main_entry answers badform for a path pathform refuses, absent for a plain missing one (U1d, U2a)" {
```
(dev-cycle.bats:1338, :1356)

U2a was split at its review cap into U2a1 and U2a2 (Q-119), and the sibling test added in the same branch says `(U2a1)`. A reader grepping test names for `U2a1` to find what this unit pinned misses the badform test; grepping `U2a` matches both sub-units. Cosmetic.

**Recommendation:** `(U1d, U2a1)`, whenever dev-cycle.bats is next edited.

## Iteration-1 fixes (A1-A6) against the baseline

- **A3** (main_file error names its file): `the tree of the default branch could not be read for $f` restores the path that every other `FILE_WHY` carries; the reworded head ("the tree of the default branch" for main's "the default branch's tree") now matches check_brief's and check_answer's error wording. Correct.
- **A4** (subjectless reasons): check_brief passes `""`, so its notfile and error lines return to the subjectless style of its other reasons, and badform reads `not an allowed path form`, the five checks' spelling, whenever a caller passes `""`. [unverified — submitted as claim: check_brief's notfile, notdir and error skip lines at d48f4645 are byte-identical to main's; route: code-fact-check] check_answer's notfile line is identical to main's. Correct; Findings 1 and 3 are residue, not regressions.
- **A5** (check_fix comment points to the header): removes the drifted fifth copy; the remaining copies (header :50-55, skip reason :181, SKILL.md :72-76) agree on `constraints.md`. Stage 1's "the skip message below repeats it" Mostly-accurate note (three skip messages together do) stands; not re-filed.
- **A1/C5** (both setups `unset $(git rev-parse --local-env-vars)`): the two suites now use one identical line with the same shellcheck directive, and dev-cycle.bats' comment points to bl_setup's. Executed here: git 2.39.5 lists 16 names including `GIT_CONFIG_PARAMETERS` and `GIT_CONFIG_COUNT`, so bl_setup's "(GIT_CONFIG_PARAMETERS too)" holds on this git; build-loop-read.bats:436 sets `GIT_CONFIG_COUNT` per `run`, after setup, so the unset does not hide it.
- **A2, A6:** no interface effect beyond Finding 2 (A2's newline folding uses the bare `$2`).

## What Looks Good

- One spelling of each refusal: after d48f4645, a path-form refusal reads `not an allowed path form` from check_brief and the five check modes alike, and the error reason has one head across the three callers.
- main_entry's contract sentence "Only blob reads the file, and only absent means there is none: every other word is a refusal" (lib:256-257) states the consumer rule once; Stage 1 executed that every caller refuses every other word.
- `badform`, `isclosed`, `entry_why` follow their neighbours' naming (iteration 1 audit; unchanged).
- `constraints.md` is added to all three user-facing copies of the --check-fix list with the same form each copy already used.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | entry_why's comment says `$2` is named; notdir ignores it, so callers special-case it | Informational | `scripts/lib/dev-cycle-read.sh:280-287` | High |
| 2 | One-argument entry_why under `set -u` gives `skip X: ` with an empty reason; "optional" in the description vs bare `$2` | Informational | `scripts/lib/dev-cycle-read.sh:283-284` | High |
| 3 | check_answer's notdir/error lines reworded against main (toward its siblings) | Informational | `scripts/lib/dev-cycle-read.sh:573-574` | High |
| 4 | Test tag `(U1d, U2a)` vs the unit `U2a1` | Informational | `test/scripts/dev-cycle.bats:1356` | Medium |

## Overall Assessment

The branch is consistent with the codebase's interface conventions, and the iteration-1 fixes moved every reason it touched toward the established forms (subjectless in check_brief, path-named in main_file, `so no entry in ... is read` in check_answer, one path-form spelling). No finding is Breaking, Inconsistent or Minor. The four Informational items are all about the contract the next caller (U2a2's floor) will read: say in entry_why's comment that notdir names a directory rather than `$2`, and either read `$2` as `${2-}` or stop calling it optional. Both are one-line changes and can land with U2a2's first edit of the lib.

## Goal-Alignment Note

**Success criterion:** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-final-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: d48f4645` as its first line.
**Answered:** Saved as docs/reviews/api-consistency-reviewer-review-2026-10-06-final-build-loop-u2a1.md in /workspace/.claude/wt-build-loop-u2a1, first line `Commit: d48f4645`, with the skill's sections (Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment) and a check of A1-A6. 4 Informational findings, 0 Breaking/Inconsistent/Minor.
**Out of scope:** Re-filing C1-C4 or rows 306-325 (none re-filed); the commit-message wording Stage 1 already recorded; U2a2's floor itself.
**Escalate:** Nothing.
**Questions / Decisions:** Findings 1 and 2 are natural Defer rows with trigger "U2a2's first edit of scripts/lib/dev-cycle-read.sh" (the floor is entry_why's fourth caller); Finding 4 at the next edit of dev-cycle.bats.
