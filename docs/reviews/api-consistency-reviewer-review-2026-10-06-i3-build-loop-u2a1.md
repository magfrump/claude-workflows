Commit: d07cc89c

# API Consistency Review — feat/build-loop-u2a1 (iteration 3 of 3, final confirming pass)

**Scope:** `git diff main...HEAD` at d07cc89c (6f624cdf unit; d48f4645 and 91469367 fixes; 706e0499, d07cc89c review artifacts): scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/{dev-cycle,build-loop-read,fixture-git-env}.bats
**Date:** 2026-10-06
**Based on:** Stage 1 code-fact-check k=3 at d07cc89c (`code-fact-check-report-build-loop-u2a1-r{1,2,3}.md`); rubric `code-review-rubric-2026-10-06-feat-build-loop-u2a1.md` (iterations 1-2: A1-A13, C1-C11); `override-log.md` rows 306-330

## Baseline Conventions

Unchanged from the iteration-1 and iteration-2 reports; restated briefly:

- **Check-mode output:** one line per argument, `ok ...` or `skip <arg>: <reason>`; consumers act on the leading word, and only the bats suites pin reason text. Re-searched at d07cc89c: outside `docs/reviews/` and `test/`, no file holds the new reason text (`could not be read for`, `default branch answered`). [unverified — submitted as claim: no script or doc outside test/ and docs/reviews/ parses or quotes a main_entry refusal reason; route: code-fact-check]
- **Reason subject:** check_brief's reasons are subjectless (its prefix names the brief); check_answer's file-level refusals name the file and close `so no entry in $f is read` (lib:576, :584-586, whose odd/unbalanced/quoted arms already name `$f` twice); build-loop.sh's `FILE_WHY` reasons name `$f`.
- **Path-form refusal:** `not an allowed path form` (five check modes in dev-cycle.sh, check_brief lib:347; dev-cycle.sh:146, :152, :162, :173).
- **main_entry words:** lower-case run-together (`blob`, `absent`, `notfile`, `notdir PART`, `badform`, `error`); every caller `case`s on them with a refusing default arm.
- **Optional positional parameters:** read with a default expansion (`${2:-}` in pathform, `${2:-file}` in skipped); required ones bare.
- **Test-name tags:** a trailing `(<unit>)` naming the landing unit.
- **Suite setup (new on this branch):** both fixture-writing suites under test/scripts/ that this unit touches clear git's repo-local variables with `unset $(git rev-parse --local-env-vars)` before building fixtures (dev-cycle.bats:11-13, build-loop-fixtures.bash:11-15).

## Name-Pattern Audit

91469367 adds no new public lib, script or CLI name. It adds one new suite file and three test names. The unit's names from iterations 1-2 are carried unchanged.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `badform` | main_entry result word | `notfile`, `notdir`, `absent`, `error` | `scripts/lib/dev-cycle-read.sh:249-279` | Consistent (unchanged since iteration 1) |
| `isclosed` | lib path predicate | `isbrief`, `inrepo`, `writable` | `scripts/lib/dev-cycle-read.sh:157-162` | Consistent (unchanged) |
| `entry_why` | lib reason mapper | `oddwhy`, `main_entry`, `brief_fields` | `scripts/lib/dev-cycle-read.sh:231`, `:262`, `:309` | Consistent with the snake_case majority (unchanged) |
| `--check-fix` exclusion `constraints.md` | CLI allowlist entry | `dev-cycle.md`, `working/`, `decisions/` | `scripts/dev-cycle.sh:52`, `:180-181`; `skills/dev-cycle/SKILL.md:74` | Consistent (unchanged) |
| `test/scripts/fixture-git-env.bats` | suite file name | `test/fixture-hermeticity.bats`, `test/scripts/dev-cycle.bats`, `test/scripts/build-loop-read.bats` | `test/*.bats`, `test/scripts/*.bats` | Consistent: kebab-case, `fixture-` prefix shared with the existing cross-suite gate `fixture-hermeticity.bats`; `# @category fast` matches its siblings (whole file ran in 0.66 s here) |
| `@test "... (U2a1)"` (dev-cycle.bats:1338, :1371; fixture-git-env.bats:24, :29) and `(U1d, U2a1)` (dev-cycle.bats:1356) | test-name unit tag | `(U1d)` | `test/scripts/build-loop-read.bats:414,443,451` | Consistent; iteration 2's `(U1d, U2a)` is now `(U1d, U2a1)` (A9) |

## Findings

#### 1. The new suite that enforces the unset convention does not follow it: its own setup writes into an inherited GIT_DIR

**Severity:** Minor
**Location:** `test/scripts/fixture-git-env.bats:9-15` (header `:3-6`)
**Move:** 7 (asymmetry), 1 (baseline)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
# The dev-cycle and build-loop suites must keep their fixtures out of a repo
# named by an inherited GIT_DIR or GIT_INDEX_FILE (a run from a git hook, say):
# each suite's setup unsets every variable `git rev-parse --local-env-vars`
# lists. One test of each suite runs here with both pointed at a victim repo.
...
setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    V="$BATS_TEST_TMPDIR/victim"
    git init -q -b main "$V"
    git -C "$V" -c user.name=v -c user.email=v@example.invalid commit -q --allow-empty -m only
}
```
(fixture-git-env.bats:3-6, :9-15). Sibling setups on the same branch:
```
    # shellcheck disable=SC2046  # word splitting is wanted: one name per line
    unset $(git rev-parse --local-env-vars)
```
(test/lib/build-loop-fixtures.bash:14-15; test/scripts/dev-cycle.bats:12-13)

This branch sets a suite-setup convention for the dev-cycle and build-loop suites, and the new suite's header states it. The new suite's own setup does not follow it: its `git init` and `git commit` are fixture writes that an inherited GIT_DIR redirects. Executed (scratch dir, victim repo with 1 commit, `GIT_DIR` and `GIT_INDEX_FILE` pointed at it, the whole file under `timeout`): git printed `warning: re-init: ignored --initial-branch=main`, both tests failed, and the victim went from 1 to 3 commits (two `only` commits, one per test's setup). This reproduces Stage 1 r3. Override row 327 / rubric C7 defers "five other suites" on the grounds "Outside this unit's files; predates it". Neither ground covers this file, which the branch creates. Consumer impact is limited to whoever runs the suite from a git hook, which is the exposure the file exists to guard. The cost is low but real, and the suite pinning the convention breaks it itself.

**Recommendation:** Add the same two lines (shellcheck directive and `unset $(git rev-parse --local-env-vars)`) as the first statements of `setup()`, before `git init`. The inner `run env GIT_DIR=... bats ...` sets the variables again for the child, so the tests still exercise the siblings' unset. Alternatively, add `fixture-git-env.bats` to row 327's list as a sixth suite with its own trigger. Do not reuse the row's current rationale.

#### 2. entry_why's comment states the empty-`$2` form only for notfile and badform; error and the default arm also drop their "for $2" tail

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:281-285`
**Move:** 8 (nullability), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
# Why main_entry's word $1 is not a file to read, for a skip line. $2 is the
# path asked about, or "" when the skip line already names it: notfile and
# badform make it the subject ("$2 is not ..."; no subject when ""), error and
# any other word end "for $2", and notdir names only the directory above it.
...
    error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;
    *) echo "the default branch answered $w${p:+ for $p}" ;;
```
(lib:281-284, :293-294)

Iteration 2's A7 fix makes the comment state each word's use of `$2`. That fix is correct, and the test at dev-cycle.bats:1338-1354 pins every arm in both forms. The parenthetical "no subject when \"\"" sits on the notfile/badform clause only. A caller passing `""`, as check_brief does, gets no "for " tail from error or the default arm, and the comment does not say so. Stage 1 r3 records the same point as Mostly accurate. It is filed here only because it is the contract U2a2's floor, the fourth caller, will read.

**Recommendation:** Add "(nothing when \"\")" after `end "for $2"`. One comment edit; it can go with U2a2's first lib edit.

## Iteration-2 fixes (91469367) against the baseline

- **A7** (one meaning per argument; one check_answer ending): check_answer has a single refusing arm, `skip $a: $(entry_why "$e" "$f"), so no entry in $f is read` (lib:576). The special notdir arm and its "it" comment are gone. A side effect is that the notfile and error lines now name `$f` twice, the redundancy iteration 1's A4 had removed. This matches check_answer's existing odd/unbalanced/quoted arms (lib:584-586), which already read `... of $f ..., so no entry in $f is read`, so it moves toward the function's convention. Only dev-cycle.bats pins the text (:1198, :1203, :1226-1228, :1327). Not filed.
- **A8** (`${2-}`): no caller passes one argument any more without an empty reason. `${2-}` and the lib's `${2:-}` differ only for a set-but-empty `$2`, which yields "" either way. Stage 1 already records the commit message's "like the lib's other optional arguments" as Mostly accurate. [unverified — submitted as claim: `${2-}` and `${2:-}` produce the same value of p for every argument list entry_why can receive; route: code-fact-check]
- **A9** (test tag): `(U1d, U2a1)` at dev-cycle.bats:1356. Fixed.
- **A12** (guard order stated): the main_entry comment (lib:257-259) now says main_by_name runs before pathform. The test's last line (`MAIN_SHA=""; main_entry .gitattributes` → `error`) pins it. Consistent with the header contract "main_entry and brief_fields answer error" when main is not found by name (lib:242-244).
- **A10/A11** (new tests): naming and tags follow the suite conventions (audit above). Finding 1 covers fixture-git-env.bats's own setup.
- check_brief at d07cc89c passes `""`, so its notdir, notfile and error lines are main's text. [unverified — submitted as claim: check_brief's notdir, notfile and error skip lines at d07cc89c are byte-identical to main's; route: code-fact-check]

## What Looks Good

- One refusal vocabulary. Every main_entry word except `blob`/`absent` reaches each caller through one mapping, and the contract sentence "Only blob reads the file, and only absent means there is none: every other word is a refusal" (lib:256-257) states the consumer rule once.
- `badform` gives the form refusal its own word, as row 306 asked. With no default branch the answer stays `error`, which keeps "main not found" one meaning across main_entry and brief_fields.
- `isclosed` replaces three spellings of the closed/ rule with one predicate named like its neighbour `isbrief`.
- `constraints.md` appears in all three user-facing copies of the `--check-fix` list, in the form each copy already used. The check_fix comment now points to the header rather than keeping a fifth copy.
- The two touched suites clear git's repo-local variables with one identical line and one shared justification.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | fixture-git-env.bats's own setup does not unset the repo-local variables it requires of its siblings; under an inherited GIT_DIR the victim goes 1→3 commits; C7/row 327's rationale does not cover a file this branch creates | Minor | `test/scripts/fixture-git-env.bats:9-15` | High |
| 2 | entry_why's comment omits that error and the default arm drop "for $2" when `$2` is "" | Informational | `scripts/lib/dev-cycle-read.sh:281-285` | High |

## Overall Assessment

The code surface is consistent with the codebase's conventions, and iteration 2's fixes are correct. entry_why's contract now states each argument's role. check_answer has one ending that matches its sibling arms. `${2-}` makes the optional path genuinely optional. The test tag names the landing unit. The fixes introduced no new name or reason form, and no consumer outside the suites reads the changed text. The one new item is in the new test file: fixture-git-env.bats asserts the setup convention this branch establishes but does not follow it in its own setup. That is a two-line fix in place, and nothing in the existing deferral covers it. The comment wording in Finding 2 is Stage 1's point, carried for U2a2. Nothing is Breaking or Inconsistent.

## Goal-Alignment Note

**Success criterion:** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-i3-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: d07cc89c` as its first line.
**Answered:** Saved as docs/reviews/api-consistency-reviewer-review-2026-10-06-i3-build-loop-u2a1.md in /workspace/.claude/wt-build-loop-u2a1, first line `Commit: d07cc89c`. It has the skill's sections and checks iteration 2's fixes (A7-A12) against the baseline. Result: 1 Minor and 1 Informational finding, 0 Breaking or Inconsistent.
**Out of scope:** Re-filing Won't-Fix/Defer rows 306-330 (none re-filed; Finding 1 argues that row 327's rationale does not reach fixture-git-env.bats). Fact-check-only items: plan F10, the stale C1 line cite, fixture-git-env's index-not-checked gap (r2), and commit-message wording. U2a2's floor.
**Escalate:** Finding 1 to the orchestrator. It needs a decision: a two-line fix in this unit, or a sixth suite added to row 327 with its own rationale.
**Questions / Decisions:** None beyond Finding 1's choice.
