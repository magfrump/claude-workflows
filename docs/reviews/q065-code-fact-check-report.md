Commit: 0304a2c

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q065 (branch review/q065)
**Scope:** `git diff main...HEAD` at HEAD 0304a2c (merge base 6405e43), full branch: `docs/reviews/override-log.md`, `scripts/lib/si-input.sh`, `test/si-input-parse-comments.bats` (new), `test/si-input-rejected-history.bats` (deleted), plus every commit message on `main..HEAD`. The `docs/reviews/q065-*.md` review artifacts are out of scope.
**Checked:** 2026-09-28
**Replication:** k=1 (final confirming pass, decision 031)
**Total claims checked:** 20
**Summary:** 19 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The relevant class is "a specific measured value quoted from an artifact set that does not contain it" (e.g. the "All 85 tests" and "mode1-equiv 33" entries). Every count on this branch ("12 tests", "11 of the 12", "three routing mutants", "two mutants", "five routing mutants") was re-measured by execution below. None matches the pattern.

Execution provenance for this run (all in cwd `/workspace/.claude/wt-q065`, exit 0 for each script as a whole):
- `bash /home/node/.claude/jobs/9f431b13/tmp/q065-fc3-callers.sh` at 2026-09-28T14:43:16-07:00 → `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-callers.log`
- `bash /home/node/.claude/jobs/9f431b13/tmp/q065-fc3-run.sh` at 2026-09-28T14:44:08-07:00 → `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run.log` (includes `scripts/run-tests.sh test/si-input-parse-comments.bats test/parse-si-priority-hypotheses.bats test/function-inventory.bats`, exit 0, 23/23 ok)
- `bash /home/node/.claude/jobs/9f431b13/tmp/q065-fc3-run2.sh` at 2026-09-28T14:45:07-07:00 → `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run2.log`

Mutants ran only in scratch copies (`q065-fc3-mut`, `q065-fc3-mut2`), and the scripts deleted them (logs record "scratch removed: yes").

---

## Claim 1: "missing-file branch of `parse_si_input` (`scripts/lib/si-input.sh:35-38`) and heading case-folding beyond the first character (`${heading,,}` at `scripts/lib/si-input.sh:107` …)"

**Location:** `docs/reviews/override-log.md:80`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the two cited line ranges at HEAD are the missing-file branch and the case-folding `case`; does not establish anything about test coverage of those lines (see Claim 2).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/si-input.sh:35-38
    if [[ -z "$input_file" || ! -f "$input_file" ]]; then
        echo "  No SI input file found (optional). Running without user input." >&2
        return 1
    fi
```
(excerpt ends :38; enclosing parse_si_input() continues to :100 — read)

```bash
# scripts/lib/si-input.sh:107
    case "${heading,,}" in
```
(excerpt ends :107; enclosing _save_si_section() continues to :113 — read)

**Evidence:** `scripts/lib/si-input.sh:26-100`, `scripts/lib/si-input.sh:103-113`

---

## Claim 2: "title-case headings are already exercised"

**Location:** `docs/reviews/override-log.md:80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the positive routing of title-case `## Feedback`, `## Priorities` and `## Off-limits` headings in the surviving tests; does not establish a positive test for a title-case `## Context` (every `## Context` in the fixtures sits inside an HTML comment and is asserted empty), nor folding beyond the first character, which the row says is untested.
**Legibility-target:** for-orchestrator-synthesis

The fixtures use first-letter-capitalized headings, and the tests assert those sections are populated:

```bash
# test/si-input-parse-comments.bats:29-33
  printf '## Feedback\nfb line\n## Off-limits <!-- topics to avoid -->\nskills/code-review\n## Priorities\n- p1 <!-- why --> now\n' > "$INPUT_FILE"
  parse_si_input "$INPUT_FILE" 2>/dev/null
  [ "$SI_FEEDBACK" = "fb line" ]
  [ "$SI_OFF_LIMITS" = "skills/code-review" ]
  [ "$SI_PRIORITIES" = "- p1  now" ]
```
(excerpt ends :33; enclosing @test continues to :34 — read)

These reach the lower-case `case` arms only through `${heading,,}` (`scripts/lib/si-input.sh:107-111`). `SI_CONTEXT` is never asserted non-empty in any test (paraphrased — no quote available because the claim covers absence of code: `git grep -n 'SI_CONTEXT\|## Context' -- test` returns only the three `-z "$SI_CONTEXT"` assertions and the two in-comment `## Context` fixture lines).

**Evidence:** `test/si-input-parse-comments.bats:19-23,29-33,40-45`, `scripts/lib/si-input.sh:107-112`

---

## Claim 3: "Scope drift: both gaps predate Q-065 and the deletion does not touch them"

**Location:** `docs/reviews/override-log.md:80`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that neither the missing-file branch nor the `case` statement falls inside a changed hunk of `scripts/lib/si-input.sh`; does not assess whether declining them was the right call.
**Legibility-target:** for-orchestrator-synthesis

The diff has two hunks in the library. One is `@@ -9,9 +9,6 @@`, which removes the three header lines. The other is `@@ -196,117 +193,6 @@`, which removes the function body starting after `parse_si_priority_hypotheses`. Lines 35-38 and 107 sit between them, unchanged. At the merge base they are three lines lower (paraphrased — no quote available because the claim is about hunk placement in the diff, shown in full in the shared diff file at lines 17-27).

**Evidence:** `scripts/lib/si-input.sh:9-12,35-38,107`; `git diff main...HEAD -- scripts/lib/si-input.sh`

---

## Claim 4: "Sourced by scripts/self-improvement.sh — do not execute directly."

**Location:** `scripts/lib/si-input.sh:6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the production source site and the direct-execution guard; does not establish that self-improvement.sh is the only sourcer (two bats files also source it, which is normal for a library).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/self-improvement.sh:230-231
# shellcheck source=lib/si-input.sh
source "$SCRIPT_DIR/lib/si-input.sh"
```

```bash
# scripts/lib/si-input.sh:14-17
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: this file should be sourced, not executed directly" >&2
    exit 1
fi
```

**Evidence:** `scripts/self-improvement.sh:230-231,493,499`, `scripts/lib/si-input.sh:14-17`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-callers.log`

---

## Claim 5: Functions list "parse_si_input — Parse si-input.md and export section variables / parse_si_priority_hypotheses — …emits JSON to stdout"

**Location:** `scripts/lib/si-input.sh:8-11`
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the list names exactly the non-underscore functions defined at HEAD and no deleted one; does not list the underscore-prefixed internals `_save_si_section` and `_trim_blank_lines`, which carry "Internal:" comments.
**Legibility-target:** for-orchestrator-synthesis

The file defines four functions: `parse_si_input() {` (`:26`), `_save_si_section() {` (`:103`), `parse_si_priority_hypotheses() {` (`:135`) and `_trim_blank_lines() {` (`:197`). The header lines for the deleted `prepend_si_input_rejected_history` are gone (`-#   prepend_si_input_rejected_history — New-cycle bootstrap: prepend an`, diff hunk `@@ -9,9 +9,6 @@`).

**Evidence:** `scripts/lib/si-input.sh:8-11,26,103,135,197`

---

## Claim 6: "Unit tests for parse_si_input()'s handling of HTML comments and of text outside the four known sections in si-input.md (lib/si-input.sh). The first two moved from si-input-rejected-history.bats when its subject, prepend_si_input_rejected_history, was deleted (Q-065 [1])."

**Location:** `test/si-input-parse-comments.bats:3-6`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that tests 1-2 match the merge-base copies byte for byte, that test 3 targets text outside the four `case` arms, and that the file tests only `parse_si_input`; does not establish anything about the moved tests' behavior beyond their passing (Claim 7 covers test 2's regression comment).
**Legibility-target:** for-orchestrator-synthesis

`q065-fc3-run.sh` §2 extracted each moved `@test` block from `6405e43:test/si-input-rejected-history.bats` and from HEAD. The log has `IDENTICAL: @test "parse_si_input drops the middle lines` and `IDENTICAL: @test "parse_si_input keeps a heading`. The four known sections are the four arms:

```bash
# scripts/lib/si-input.sh:107-112
    case "${heading,,}" in
        feedback)    SI_FEEDBACK="$text" ;;
        priorities)  SI_PRIORITIES="$text" ;;
        off-limits)  SI_OFF_LIMITS="$text" ;;
        context)     SI_CONTEXT="$text" ;;
    esac
```

**Evidence:** `test/si-input-parse-comments.bats:3-6,18-56`, `6405e43:test/si-input-rejected-history.bats:198-214`, `scripts/lib/si-input.sh:107-112`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run.log`

---

## Claim 7: "Regression (2026-09-18 review F2): the `*-->` skip ran before heading detection, so this heading was dropped and its body joined Feedback."

**Location:** `test/si-input-parse-comments.bats:27-28`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the F2 reference (commit 0f5ae8a) and that inline comments are now stripped before heading detection; does not re-run the pre-fix code (the moved comment is unchanged from main).
**Legibility-target:** for-orchestrator-synthesis

Commit 0f5ae8a (2026-09-18) body: "si-input (F2, regression from ed4e183) - `## Off-limits <!-- note -->` hit the `*-->` skip before heading detection, so its body landed in SI_FEEDBACK." Current code excludes lines containing `<!--` from the tail skip and strips inline comments before the heading regex:

```bash
# scripts/lib/si-input.sh:64-74
        [[ "$line" == *'-->' && "$line" != *'<!--'* ]] && continue
        # Drop complete inline comments, so `## Off-limits <!-- note -->` is
        # still the Off-limits heading rather than a skipped line whose body
        # then lands in the previous section.
        while [[ "$line" == *'<!--'*'-->'* ]]; do
            local _pre="${line%%<!--*}" _rest="${line#*<!--}"
            line="${_pre}${_rest#*-->}"
        done

        # Detect section headings
        if [[ "$line" =~ ^##[[:space:]]+(.*[^[:space:]])[[:space:]]*$ ]]; then
```
(excerpt ends :74; enclosing parse_si_input() continues to :100 — read)

**Evidence:** `scripts/lib/si-input.sh:52-100`, commit `0f5ae8a` message

---

## Claim 8: "Replaces the deleted "comment block does not pollute parsed sections" test (Q-065 review A1): text before the first ## heading, comment or prose, and the body of an unknown heading reach no SI_* variable."

**Location:** `test/si-input-parse-comments.bats:37-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all eight single-arm routing mutants (empty heading or `notes` added to each of the four `case` arms) and a mutant that disables multi-line comment tracking. The test fails on each, and it passes on unmutated code. Does not establish folding beyond the first character or the missing-file branch (declined as C1).
**Legibility-target:** for-orchestrator-synthesis

`q065-fc3-run.sh` §4 applied each mutant to a scratch copy of `scripts/lib/si-input.sh` and ran the HEAD test file against it. The log shows `not ok 3 parse_si_input drops text before the first heading and under unknown headings` for all of `pre-feedback`, `pre-priorities`, `pre-offlimits`, `pre-context`, `notes-feedback`, `notes-priorities`, `notes-offlimits`, `notes-context` and `no-in-comment`, and `control bats exit 0` with `ok 3` on the unmutated copy. The two fixtures:

```bash
# test/si-input-parse-comments.bats:40
  printf '<!-- Recent rejections (last 3 rounds):\n  Round 1: task-foo — something failed\n## Context\n-->\nstray preamble prose\n## Feedback\n\nthe real feedback\n\n## Notes\nunknown section body\n## Priorities\n\n- priority one\n' > "$INPUT_FILE"
# test/si-input-parse-comments.bats:50
  printf 'stray preamble prose\n## Notes\nunknown section body\n' > "$INPUT_FILE"
```
(excerpts from the @test spanning :36-56 — read in full)

**Evidence:** `test/si-input-parse-comments.bats:36-56`, `scripts/lib/si-input.sh:103-113`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run.log`

---

## Claim 9: "With no known section after them, a leak into any variable would not be overwritten by a later real section, so all four SI_* section variables must stay empty."

**Location:** `test/si-input-parse-comments.bats:47-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the overwrite mechanism: `_save_si_section` assigns rather than appends, so a later real section hides an earlier leak, and fixture 2 asserts exactly the four variables `parse_si_input` sets. Does not establish anything about variables outside those four.
**Legibility-target:** for-orchestrator-synthesis

The mechanism is plain assignment (`feedback)    SI_FEEDBACK="$text" ;;`, `scripts/lib/si-input.sh:108`). Execution shows it matters. Against the 2c1162b test file, which has fixture 1 only, `q065-fc3-run2.sh` found that `pre-feedback`, `pre-priorities` and `notes-priorities` exit 0 (the leak is overwritten), while the other five mutants fail. Against HEAD, with fixture 2 added, all eight fail (Claim 8). The four asserted variables are the ones initialized at `:30-33` and trimmed at `:94-97`:

```bash
# scripts/lib/si-input.sh:30-33
    SI_FEEDBACK=""
    SI_PRIORITIES=""
    SI_OFF_LIMITS=""
    SI_CONTEXT=""
```
(excerpt ends :33; enclosing parse_si_input() continues to :100 — read)

**Evidence:** `test/si-input-parse-comments.bats:47-55`, `scripts/lib/si-input.sh:30-33,94-97,103-113`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run2.log`

---

## Claim 10: "prepend_si_input_rejected_history had no caller since it landed in 06903d6."

**Location:** commit `12f96cd` message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every committed revision from 06903d6 to the merge base 6405e43: no code outside the function's own definition and its test file names it. Does not establish that nobody ever ran it by hand from a shell.
**Legibility-target:** for-orchestrator-synthesis

`git log --oneline -S prepend_si_input_rejected_history 06903d6^..6405e43` returns 06903d6 plus three commits (add8f2c, 0b1ebf4, b1780ac). Those three touch only `docs/working/audit-test-constraint-2026-09-26.md` / `docs/working/questions.md` for this string (`git show --stat` in the callers log). At 6405e43, `git grep` finds the name only in `scripts/lib/si-input.sh:12,214`, `test/si-input-rejected-history.bats` and `docs/working` prose. The production loop calls only the two surviving functions (`parse_si_input "$WORKING_DIR/si-input.md" || true`, `scripts/self-improvement.sh:493`; `SI_PRIORITY_HYPOTHESES_JSON=$(parse_si_priority_hypotheses)`, `:499`). A search for dynamic use (`rejected_history`, `Recent rejections`) across `scripts hooks skills test` at main finds nothing outside the function and its tests, apart from an unrelated doc comment in `si-morning-summary.sh:296`.

**Evidence:** `scripts/self-improvement.sh:493,499`, `6405e43:scripts/lib/si-input.sh:214`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-callers.log`

---

## Claim 11: "Its 12 tests exercised only that function"

**Location:** commit `12f96cd` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count (12 deleted tests out of 14) and what each deleted test called. Does not re-verdict the correction, which is Claim 14.
**Legibility-target:** for-author

`q065-fc3-run.sh` §1 counted 14 `@test` blocks at `6405e43:test/si-input-rejected-history.bats`. The 12 non-moved ones all call the helper (`helper=1`). One of them, `@test "comment block does not pollute parsed sections"`, also calls `parse_si_input` (`helper=1 parse=1`). The precise statement is "11 of its 12 tests exercised only that function". The branch already corrects this in the body of 2c1162b ("Correction to 12f96cd's message: 11 of the 12 deleted tests exercised only the deleted helper"), and 12f96cd is intentionally not rewritten. No further action is needed unless the branch history is squashed, in which case the squashed message should carry "11 of 12".

**Evidence:** `6405e43:test/si-input-rejected-history.bats:178-188`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run.log`

---

## Claim 12: "the two parse_si_input comment-handling tests move to test/si-input-parse-comments.bats"

**Location:** commit `12f96cd` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte identity of the two moved `@test` blocks; does not cover the third test, which was added later in 2c1162b.
**Legibility-target:** for-orchestrator-synthesis

The identity check prints `IDENTICAL:` for both blocks (see Claim 6), and both pass (`ok 1`, `ok 2` in the `run-tests.sh` run).

**Evidence:** `test/si-input-parse-comments.bats:18-34`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run.log`

---

## Claim 13: "The rejected-history preamble never appeared in a real run, so no behaviour changes."

**Location:** commit `12f96cd` message (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers "no committed code path could write the preamble" (Claim 10) and "the deletion removes only the definition and header lines, and the surviving functions are unchanged". Does not establish the contents of any user's local `si-input.md`. A stale preamble left there by a manual run would still be discarded by `parse_si_input`'s comment skip.
**Legibility-target:** for-orchestrator-synthesis

The library diff has only removals: `scripts/lib/si-input.sh | 114 ---------` in `git diff --stat main...HEAD`. The removals fall in the header and in the function body after `parse_si_priority_hypotheses` (paraphrased — no quote available because the claim covers absence of changes to the surviving functions, established from the hunk layout in Claim 3). `test/function-inventory.bats` still passes (`ok 21 parse_si_input is a function`, `ok 23 all 9 expected functions are present`).

**Evidence:** `scripts/lib/si-input.sh:26-204`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run.log`

---

## Claim 14: "Correction to 12f96cd's message: 11 of the 12 deleted tests exercised only the deleted helper; the 12th also covered this case." and "It fails on two mutants (preamble routed to Context, unknown heading routed to Context) that the other two tests pass."

**Location:** commit `2c1162b` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 11/12 count and both mutant outcomes against the 2c1162b version of the test file. Does not cover this body's description of what the deleted test asserted; 09626e2 refines that, see Claim 16.
**Legibility-target:** for-orchestrator-synthesis

The count is from §1 of the run log (Claim 11). Against the 2c1162b test file, `pre-context` and `notes-context` give `bats exit 1 ; not-ok: 1` (run2 log). At HEAD, the same two mutants fail only test 3, while tests 1 and 2 pass (`not ok 3` is the only failure listed for each in the run log).

**Evidence:** `2c1162b:test/si-input-parse-comments.bats`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run.log`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run2.log`

---

## Claim 15: "note said "next commit" but the test landed in 2c1162b itself."

**Location:** commit `35d6274` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that 2c1162b introduced test 3; does not re-check the wording of the rubric note itself, which is a review artifact outside scope.
**Legibility-target:** for-orchestrator-synthesis

`git show 2c1162b --stat` lists `test/si-input-parse-comments.bats | 19 ++++++++++++++++---`. Run2 loaded `2c1162b:test/si-input-parse-comments.bats`, and five mutants produced a `not ok`. Tests 1 and 2 do not fail on routing mutants, so the failing test is test 3, which means it already existed at 2c1162b.

**Evidence:** `2c1162b:test/si-input-parse-comments.bats`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run2.log`

---

## Claim 16: "A3: correction to 2c1162b's body. The deleted test was the only one with an HTML comment before the first heading; that comment is dropped by the comment-skip path, so it never asserted the empty-heading discard of plain prose."

**Location:** commit `09626e2` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three merge-base tests that call `parse_si_input` and the path the helper-produced block takes through the parser. Does not establish anything about tests in other files, none of which call `parse_si_input` (`git grep` in the callers log).
**Legibility-target:** for-orchestrator-synthesis

The helper wrote the block starting `block="<!-- Recent rejections (last 3 rounds):"$'\n'` (`6405e43:scripts/lib/si-input.sh:269`) with no `-->` on that line. The parser therefore sets `in_comment=1` and drops every line through `-->`:

```bash
# scripts/lib/si-input.sh:53-63
        if (( in_comment )); then
            [[ "$line" == *'-->'* ]] && in_comment=0
            continue
        fi

        # Skip HTML comments: an opening line (leading whitespace allowed)
        # whose comment does not close on the same line starts a block.
        if [[ "$line" =~ ^[[:space:]]*'<!--' ]]; then
            [[ "${line#*<!--}" != *'-->'* ]] && in_comment=1
            continue
        fi
```
(excerpt ends :63; enclosing parse_si_input() continues to :100 — read)

The other two merge-base parse tests start with `# SI Input\n\n## Feedback` and `## Feedback`, so neither has a comment before the first heading (`6405e43:test/si-input-rejected-history.bats:199,209`).

**Evidence:** `scripts/lib/si-input.sh:52-100`, `6405e43:scripts/lib/si-input.sh:268-280`, `6405e43:test/si-input-rejected-history.bats:178-214`

---

## Claim 17: "A2: … let three routing mutants pass (preamble to Feedback or Priorities, Notes to Priorities) because the later real section overwrote the leaked text. … All five routing mutants tried now fail it."

**Location:** commit `09626e2` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exactly which of the eight single-arm routing mutants survive fixture 1 alone, and that all eight fail at HEAD. The author tried five (these three plus the two Context mutants), and this run tried eight. Does not cover mutants outside `_save_si_section` routing, other than `no-in-comment`.
**Legibility-target:** for-orchestrator-synthesis

The run2 log (2c1162b test file) shows exit 0 for exactly `pre-feedback`, `pre-priorities` and `notes-priorities`, and exit 1 for the other five. The run log (HEAD) shows `not ok 3` for all eight.

**Evidence:** `test/si-input-parse-comments.bats:36-56`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run.log`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-run2.log`

---

## Claim 18: "A4: reword this branch's C1 override-log row: title-case heading folding is tested; only folding beyond the first character is not." / "edited the C1 override-log row in place because it was added on this unmerged branch; rows already on main stay append-only."

**Location:** commit `09626e2` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the only override-log change on the branch is one added `review/q065` row, which main does not have, and that its wording matches Claim 2. Does not audit other rows.
**Legibility-target:** for-orchestrator-synthesis

`git diff main...HEAD -- docs/reviews/override-log.md` is a single `+| 2026-09-28 | \`review/q065\` | C1: …` line with no `-` lines, so no row on main was touched. The row's text includes "title-case headings are already exercised", which Claim 2 verifies.

**Evidence:** `docs/reviews/override-log.md:80`

---

## Claim 19: "parse_si_input sets exactly SI_FEEDBACK, SI_PRIORITIES, SI_OFF_LIMITS and SI_CONTEXT, which the test checks."

**Location:** commit `0304a2c` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the section variables `parse_si_input` and `_save_si_section` assign, and fixture 2's four assertions. Does not count `parse_si_priority_hypotheses` output, which the caller stores in a separate variable.
**Legibility-target:** for-orchestrator-synthesis

The only global assignments in `parse_si_input` and `_save_si_section` are to the four names (`:30-33`, `:94-97`, `:108-111`; quoted in Claims 6 and 9). Fixture 2 asserts all four:

```bash
# test/si-input-parse-comments.bats:52-55
  [ -z "$SI_FEEDBACK" ]
  [ -z "$SI_PRIORITIES" ]
  [ -z "$SI_OFF_LIMITS" ]
  [ -z "$SI_CONTEXT" ]
```
(excerpt ends :55; enclosing @test continues to :56 — read)

**Evidence:** `scripts/lib/si-input.sh:26-113`, `test/si-input-parse-comments.bats:47-56`

---

## Claim 20: (preamble claim 5) no live reference to the deleted function or deleted test file remains

**Location:** `test/si-input-parse-comments.bats:5-6`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the whole tree at HEAD. The only mentions are the provenance comment at `test/si-input-parse-comments.bats:5-6`, `archive/`, historical `docs/reviews/execution-logs/`, this review's own `q065-*` artifacts, the dated `docs/working/audit-test-constraint-2026-09-26.md` ledger, and the Q-065 entry in `docs/working/questions.md` (closed by the answers branch). Does not cover copies installed outside the repo.
**Legibility-target:** for-orchestrator-synthesis

`git grep -n -e prepend_si_input_rejected_history -e si-input-rejected-history HEAD -- .` returns only the locations listed in Scope (full listing in the callers log). No file under `scripts/`, `hooks/` or `skills/` matches, and neither does any `test/` file other than the provenance comment:

```bash
# test/si-input-parse-comments.bats:5-6
# two moved from si-input-rejected-history.bats when its subject,
# prepend_si_input_rejected_history, was deleted (Q-065 [1]).
```

**Evidence:** `test/si-input-parse-comments.bats:5-6`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc3-exec-callers.log`

---

## Submitted Claims

## Claim 21: "The diff removes every temp-file+rename and jq-over-report call site in scripts/lib/si-input.sh and adds no new write, exec or eval."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/si-input.sh:1-204` (post-change), `main:scripts/lib/si-input.sh:199-308` (deleted block)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the in-repo `scripts/lib/si-input.sh` at HEAD versus main: the only `mktemp`, `mv` and report-reading `jq` in the file were in the deleted function, and the diff adds zero lines to the file; does not establish anything about installed copies outside the repo (e.g. `~/.claude/scripts/lib/si-input.sh`, which still carries the old function), nor about other files that write `si-input.md`.
**Legibility-target:** for-orchestrator-synthesis

On main, the temp-file+rename and the report-reading `jq` live only inside the deleted function:

```bash
# main:scripts/lib/si-input.sh:250,256 (inside prepend_si_input_rejected_history, :214-308 — read)
        round_rows=$(jq -r --arg round "$round" '
        ' "$report" 2>/dev/null) || round_rows=""
# main:scripts/lib/si-input.sh:284-285,305
    tmpfile=$(mktemp "${input_file}.XXXXXX")
    printf '%s' "$block" > "$tmpfile"
    mv "$tmpfile" "$input_file"
```

At HEAD, a grep for `mktemp|mv|jq|eval|exec|report|>>` finds only the `parse_si_priority_hypotheses` comment and its stdin-fed `jq`, which reads awk output, not a report file:

```bash
# scripts/lib/si-input.sh:189
    printf '%s\n' "$pairs" | jq -R -s '
```
(excerpt ends :189; enclosing parse_si_priority_hypotheses() runs :135-194 — read; `$pairs` comes from awk over `$priorities_text` at :146-182)

`git diff --numstat main...HEAD -- scripts/lib/si-input.sh` prints `0	114`: no lines added.

**Evidence:** `scripts/lib/si-input.sh:135-194`, `main:scripts/lib/si-input.sh:199-308`, `git diff --numstat main...HEAD -- scripts/lib/si-input.sh`

---

## Claim 22: "The deleted function had no committed caller, so removing it changes no runtime write to si-input.md."

**Submitted by:** security-reviewer
**Location:** `scripts/self-improvement.sh:490-499`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every committed revision in `git log --all` (every commit that changed the symbol's count, 06903d6 onward, shows it only in `scripts/lib/si-input.sh`, the two test files and docs) and the installed `~/.claude/scripts/` tree (definition only, no caller); does not establish that no one invoked it by hand or from an uncommitted script, and does not cover other code paths that write `si-input.md`.
**Legibility-target:** for-orchestrator-synthesis

The self-improvement loop only reads `si-input.md` at this point; nothing between parse and prompt-building calls the helper:

```bash
# scripts/self-improvement.sh:489-499
# --- Pre-run input ---
# Parse user feedback, priorities, and constraints from si-input.md.
# Variables SI_FEEDBACK, SI_PRIORITIES, SI_OFF_LIMITS, SI_CONTEXT are set
# (empty strings if file is missing or sections are blank).
parse_si_input "$WORKING_DIR/si-input.md" || true

# Decision 012 pillar 3: pre-commitment hypotheses attached to priorities.
...
SI_PRIORITY_HYPOTHESES_JSON=$(parse_si_priority_hypotheses)
```

`git grep -n prepend_si_input_rejected_history main` hits only the library definition (`main:scripts/lib/si-input.sh:12,214`), `main:test/si-input-rejected-history.bats` and two docs/working ledgers (paraphrased — no quote available because the claim covers absence of code: no matching grep results outside those files). Iterating `git grep -l` over every commit returned by `git log --all -S prepend_si_input_rejected_history` (outside `docs/` and `archive/`) lists only `scripts/lib/si-input.sh`, `test/si-input-rejected-history.bats` and `test/si-input-parse-comments.bats` (the last a header comment naming the deleted function). `grep -rn prepend_si_input ~/.claude/scripts` hits only the installed library's definition lines 12 and 214.

**Evidence:** `scripts/self-improvement.sh:489-499`, `main:scripts/lib/si-input.sh:214`, `test/si-input-parse-comments.bats:6`

---

## Claim 23a: "Deleting the 12 helper tests makes the fast suite faster"

**Submitted by:** performance-reviewer
**Location:** `main:test/si-input-rejected-history.bats`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers wall time of the deleted file (14 tests) versus its replacement `test/si-input-parse-comments.bats` (3 tests), run serially under bats 1.8.2 in this sandbox: median 8.44 s versus 1.85 s over 5 runs each, about 6.6 s less; does not establish the saving under `bats --jobs` parallelism or on other hosts, or the effect on total fast-suite wall time when run through `scripts/run-tests.sh`.
**Legibility-target:** for-orchestrator-synthesis

Both files carry `# @category fast` (`main:test/si-input-rejected-history.bats:2`, `test/si-input-parse-comments.bats:2`). Measured (from the captured log):

```
old-file runs: 8.439 8.828 8.406 11.771 7.772 s   (median 8.439)
new-file runs: 1.486 1.849 2.278 1.790 2.090 s    (median 1.849)
```

**Evidence:** `main:test/si-input-rejected-history.bats:1-214`, `test/si-input-parse-comments.bats:1-3`, `/home/node/.claude/jobs/9f431b13/tmp/q065-sc-s3-exec.log`

---

## Claim 23b: "since each of them called jq several times"

**Submitted by:** performance-reviewer
**Location:** `main:test/si-input-rejected-history.bats:27-51`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of `jq` invocations per test (via a PATH shim logging `$BATS_TEST_NAME`): 10 of the 12 helper tests called `jq` 2 to 13 times (41 calls in all), and the two "no round reports" tests called it zero times; does not establish how much of the measured saving is due to `jq` rather than per-test bats overhead (the zero-`jq` tests were not timed separately).
**Legibility-target:** for-orchestrator-synthesis

Precise version: "10 of the 12 called `jq` 2-13 times; the two no-reports tests called none." The jq calls come from the test helpers and the function under test:

```bash
# main:test/si-input-rejected-history.bats:32-34
  jq -n --argjson v "$validation_json" \
    --argjson r "$round" \
    '{round: $r, validation: $v}' > "$path"
```
(excerpt ends :34; enclosing write_round_report() continues to :35 — read)

The zero-call tests call only the function, which returns before any `jq` when no reports exist:

```bash
# main:test/si-input-rejected-history.bats:55-58
@test "no round reports: file is left alone (or absent stays absent)" {
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"
  [ ! -f "$INPUT_FILE" ]
}
```

Shim counts per test (from the captured log): spans-many-rounds 13, replaces-prior-block 7, multiple-rejections 5, idempotent 4, reports-but-no-rejections 2, and 3 each for the other five; no entries for the two "no round reports" tests.

**Evidence:** `main:test/si-input-rejected-history.bats:27-51`, `main:test/si-input-rejected-history.bats:55-66`, `main:scripts/lib/si-input.sh:236-238`, `/home/node/.claude/jobs/9f431b13/tmp/q065-sc-s3-exec.log`

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 23b** (`main:test/si-input-rejected-history.bats:27-51`): "each called jq several times" overstates it; 10 of 12 did (2-13 calls), the two no-reports tests called none. The conclusion (Claim 23a) holds.

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 11** (commit `12f96cd` message): "Its 12 tests exercised only that function". The precise figure is 11 of 12, because "comment block does not pollute parsed sections" also exercised `parse_si_input`. It is already corrected in the body of 2c1162b. Carry "11 of 12" into any squashed message.

### Unverifiable
(none)

No new hallucination patterns. Nothing was Incorrect, so `docs/reviews/hallucination-patterns.md` is unchanged.

## Goal-Alignment Note
- **Answered:** All five claim groups from the shared context: the 12f96cd claims (caller, the 12-test count, no behaviour change); the si-input.sh header; the new test file's header and the third test's comments, both verified with 8 routing mutants plus 1 comment-tracking mutant against HEAD and 8 against the 2c1162b file; the C1 override-log row (cited lines, title-case claim, scope-drift premise); and live references to the deleted names. Every branch commit body with a checkable claim (12f96cd, 2c1162b, 35d6274, 09626e2, 0304a2c) was verdicted. The requested test command passed 23/23.
- **Out of scope:** The `docs/reviews/q065-*.md` artifacts and the iteration-1/2 artifact commits (bd80789, 6453949), per the preamble. Code quality, and whether declining C1 was the right call.
- **Escalate:** None. One Mostly Accurate (Claim 11) is already corrected on-branch and is not blocking. Claim 2's residue (a title-case `## Context` is never positively asserted) sits inside the declined C1 scope and is noted, not escalated.
