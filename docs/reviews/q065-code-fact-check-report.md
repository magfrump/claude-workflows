Commit: 35d6274

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q065 (branch review/q065)
**Scope:** `git diff 12f96cd..HEAD` (HEAD 35d6274), PARTIAL. It covers test/si-input-parse-comments.bats, the new override-log row, the A1 author note in docs/reviews/q065-code-review-rubric-2026-09-28.md, and the commit bodies of 2c1162b and 35d6274. 12f96cd itself is context only.
**Checked:** 2026-09-28
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 9
**Summary:** 6 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The relevant prior pattern is the count-claim family (e.g. "mode1-equiv 33 claimed but the file holds 25"). Every count in this diff was checked against the files (Claims 6, 5) and none matches that pattern.

Execution artifacts (scratch, not tracked):
- `/home/node/.claude/jobs/9f431b13/tmp/q065-fc2-baseline.log`: `scripts/run-tests.sh test/si-input-parse-comments.bats` from the worktree. Exit 0, 2026-09-28T14:36:10-07:00, 3/3 ok.
- `/home/node/.claude/jobs/9f431b13/tmp/q065-fc2-mutants-summary.log`: 10 single-line mutants of `_save_si_section`, each run as `bats test/si-input-parse-comments.bats` in its own scratch copy. The scripts that made them are `q065-fc2-mut.sh` and `q065-fc2-mut2.sh` in the same directory. The runs finished at 14:36:34 and 14:37:01 -07:00. The mutant directories were deleted afterwards. Each mutant's `>` line is recorded in the summary log.

---

## Claim 1: "Unit tests for parse_si_input()'s handling of HTML comments and of text outside the four known sections in si-input.md (lib/si-input.sh). The first two moved from si-input-rejected-history.bats"

**Location:** `test/si-input-parse-comments.bats:3-6`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the file's three tests are about and where tests 1 and 2 came from. It does not establish that the file tests every out-of-section path; the missing-file branch, for example, is still untested (see Claim 7b).
**Legibility-target:** for-orchestrator-synthesis

Tests 1 and 2 (`:18` "drops the middle lines of a multi-line HTML comment", `:26` "keeps a heading that carries a trailing inline comment") appear byte-for-byte in the pre-deletion file at `12f96cd^:test/si-input-rejected-history.bats:198` and `:206`. Test 3 (`:36`) covers text before the first heading and under an unknown heading, which is "text outside the four known sections". The four sections are the four `case` arms at `scripts/lib/si-input.sh:108-111`:

```bash
# scripts/lib/si-input.sh:107-112
    case "${heading,,}" in
        feedback)    SI_FEEDBACK="$text" ;;
        priorities)  SI_PRIORITIES="$text" ;;
        off-limits)  SI_OFF_LIMITS="$text" ;;
        context)     SI_CONTEXT="$text" ;;
    esac
```

**Evidence:** `test/si-input-parse-comments.bats:3-6,18,26,36`, `12f96cd^:test/si-input-rejected-history.bats:198,206`, `scripts/lib/si-input.sh:107-112`

---

## Claim 2: "Replaces the deleted "comment block does not pollute parsed sections" test (Q-065 review A1)"

**Location:** `test/si-input-parse-comments.bats:37-38`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the new test reproduces the deleted test's parse input and asserts at least what it asserted. It does not establish that either test checks the empty-heading discard mechanism (see Claim 4).
**Legibility-target:** for-orchestrator-synthesis

The deleted test (`12f96cd^:test/si-input-rejected-history.bats:178-188`) parsed a file made of the helper's `<!-- Recent rejections (last 3 rounds):` / `  Round 1: task-foo — something failed` / `-->` block followed by `## Feedback\n\nthe real feedback\n\n## Priorities\n\n- priority one\n`. Its assertions were substring matches:

```bash
# 12f96cd^:test/si-input-rejected-history.bats:184-187
  [[ "$SI_FEEDBACK" == *"the real feedback"* ]]
  [[ "$SI_FEEDBACK" != *"task-foo"* ]]
  [[ "$SI_PRIORITIES" == *"priority one"* ]]
  [[ "$SI_PRIORITIES" != *"Recent rejections"* ]]
```

The new test's fixture (`:40`) contains the same comment block and the same Feedback and Priorities content. It asserts exact equality `[ "$SI_FEEDBACK" = "the real feedback" ]` and `[ "$SI_PRIORITIES" = "- priority one" ]` (`:42-43`), which implies all four of the old assertions, and it adds `-z` checks on Context and Off-limits (`:44-45`). The fixture also adds a `## Context` line inside the comment, preamble prose, and a `## Notes` section.

**Evidence:** `test/si-input-parse-comments.bats:36-46`, `12f96cd^:test/si-input-rejected-history.bats:178-188`

---

## Claim 3: "text before the first ## heading, comment or prose, and the body of an unknown heading reach no SI_* variable"

**Location:** `test/si-input-parse-comments.bats:38-39`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code behaviour, which is true, and how far the test's four assertions detect a leak. It does not establish that the test would catch a leak into Feedback or Priorities that a later section of the same name overwrites.
**Legibility-target:** for-author

The code behaviour is true. The pre-heading comment is dropped by the comment-skip path before anything accumulates:

```bash
# scripts/lib/si-input.sh:52-63
    while IFS= read -r line || [[ -n "$line" ]]; do
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
(excerpt ends :63; enclosing parse_si_input() continues to :100 — read)
```

The preamble prose accumulates under `current_section=""` (`:44`). The `Notes` body accumulates under `current_section="Notes"`. Both are passed to `_save_si_section` (`:76`, `:91`), and its `case` (`:107-112`, quoted in Claim 1) has no arm for either, so neither is stored. The test passes on the unmutated code (baseline log, exit 0).

The test detects a leak into only some of the variables, though, because each `case` arm overwrites (`SI_FEEDBACK="$text"`) and the fixture's real sections come after the leaking text. Mutant results, from the mutants summary log:

| Mutant (`_save_si_section` arm) | Test 3 |
|---|---|
| `context\|"")` preamble → Context | not ok (killed) |
| `off-limits\|"")` preamble → Off-limits | not ok (killed) |
| `context\|?*)` unknown heading → Context | not ok (killed) |
| `feedback\|notes)` unknown heading → Feedback | not ok (killed) |
| `feedback\|"")` preamble → Feedback | **ok (survives)** |
| `priorities\|"")` preamble → Priorities | **ok (survives)** |
| `priorities\|notes)` unknown heading → Priorities | **ok (survives)** |

The three survivors survive because the leaked text is saved first and then overwritten when `## Feedback` or `## Priorities` is saved later (`:76`, `:91`). The comment's "reach no SI_* variable" is true of the code, but the test's assertions establish it only for Context and Off-limits (both paths) and for Feedback (unknown-heading path). A precise version would say the test asserts no leak into Context or Off-limits. Alternatively, a fixture with the prose or unknown section placed after the last real section of each name would make the full claim testable.

**Evidence:** `scripts/lib/si-input.sh:44-100,103-113`, `test/si-input-parse-comments.bats:36-46`. Executed: `bats test/si-input-parse-comments.bats` in each scratch mutant copy (cwd `/home/node/.claude/jobs/9f431b13/tmp/q065-fc2-mut/<mutant>`), exit 1 for killed and exit 0 for surviving mutants, 2026-09-28T14:36:34-07:00. Output: `/home/node/.claude/jobs/9f431b13/tmp/q065-fc2-mutants-summary.log`

---

## Claim 4: "the deleted "comment block does not pollute parsed sections" test was the only assertion that parse_si_input discards text before the first ## heading" (also 12f96cd's correction: "the 12th also covered this case")

**Location:** commit `2c1162b` body, lines 1-3 and 7-8
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the deleted test's fixture and assertions exercised. It does not establish anything about tests outside `test/`.
**Legibility-target:** for-author

It is true that no other test had non-blank pre-heading text. The other moved test's preamble is `# SI Input\n\n` (`test/si-input-parse-comments.bats:19`), which is a top-level heading that `:84` skips, followed by a blank line that is trimmed. The only other test file that references `parse_si_input` is `test/function-inventory.bats`, which checks only `type -t` (`:52-53`, `:69`).

The qualifier is missing, however. The deleted test's pre-heading text was only the helper's HTML comment block, with no prose. See the composed block in `12f96cd^:scripts/lib/si-input.sh`:

```bash
    block="<!-- Recent rejections (last 3 rounds):"$'\n'
    ...
    block="${block}-->"$'\n'
(excerpt from prepend_si_input_rejected_history(); function read in full)
```

That block is dropped by the comment-skip path (`scripts/lib/si-input.sh:52-63`) before anything accumulates. So the deleted test asserted that a pre-heading *comment* is discarded, and it never reached the empty-heading discard in `_save_si_section`. It also had no Context assertion (Claim 2 quote), so it would pass the `context|"")` mutant. A precise version would read: "the only test with text (an HTML comment) before the first heading". The new test is therefore strictly stronger than the one it replaces, not a like-for-like restoration.

**Evidence:** `12f96cd^:test/si-input-rejected-history.bats:178-188`, `12f96cd^:scripts/lib/si-input.sh:214-` (helper body), `scripts/lib/si-input.sh:52-63,84,103-113`, `test/function-inventory.bats:52-53,60-80`

---

## Claim 5: "It fails on two mutants (preamble routed to Context, unknown heading routed to Context) that the other two tests pass."

**Location:** commit `2c1162b` body, lines 4-6 (repeated in the rubric A1 note, Claim 8)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named mutants and one catch-all variant against all three tests in the file. It does not establish mutation adequacy beyond these (see the survivors in Claim 3).
**Legibility-target:** for-orchestrator-synthesis

Results from the mutants summary log:
- `context|"")  SI_CONTEXT="$text" ;;`: `ok 1`, `ok 2`, `not ok 3`.
- `context|?*)  SI_CONTEXT="$text" ;;` (non-empty unknown heading → Context): `ok 1`, `ok 2`, `not ok 3`.
- `*)  SI_CONTEXT="$text" ;;` (catch-all replacing the Context arm): `ok 1`, `ok 2`, `not ok 3`.

Tests 1 and 2 pass these mutants because their preamble is empty or blank (trimmed by `_trim_blank_lines`, `scripts/lib/si-input.sh:97`) and they have no unknown headings.

**Evidence:** `scripts/lib/si-input.sh:97,107-112`. Executed: `bats test/si-input-parse-comments.bats` in `/home/node/.claude/jobs/9f431b13/tmp/q065-fc2-mut/{m1_pre_ctx,m2_unk_ctx,m8_ctx_catchall}`, exit 1 each, 2026-09-28T14:36:34-07:00. Output: `/home/node/.claude/jobs/9f431b13/tmp/q065-fc2-mutants-summary.log`

---

## Claim 6: "Correction to 12f96cd's message: 11 of the 12 deleted tests exercised only the deleted helper"

**Location:** commit `2c1162b` body, lines 6-8
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test counts and which functions each deleted test calls. The "12th also covered this case" half carries Claim 4's qualifier.
**Legibility-target:** for-orchestrator-synthesis

`12f96cd^:test/si-input-rejected-history.bats` holds 14 `@test` blocks (grep count 14). Two moved (`:198`, `:206`), which leaves 12 deleted. All 12 call `prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"`, and only `:178` "comment block does not pollute parsed sections" also calls `parse_si_input` (`:183`). The other `parse_si_input` calls (`:200`, `:210`) are in the two moved tests.

**Evidence:** `12f96cd^:test/si-input-rejected-history.bats:55,60,68,76,93,105,124,139,145,160,178,183,190,198,206`

---

## Claim 7a: override-log row cites "missing-file branch of `parse_si_input` (`scripts/lib/si-input.sh:35-38`) and case-insensitive heading match (`scripts/lib/si-input.sh:107`)", "both gaps predate Q-065 and the deletion does not touch them"

**Location:** `docs/reviews/override-log.md:80`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line citations and the "predate / untouched" part. The "untested" characterisation is split out as Claim 7b.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/si-input.sh:35-38
    if [[ -z "$input_file" || ! -f "$input_file" ]]; then
        echo "  No SI input file found (optional). Running without user input." >&2
        return 1
    fi
```

`:107` is `case "${heading,,}" in` (quoted in Claim 1). `git log -L` puts the origin of both ranges at `239b770` (2026-04-09). 12f96cd's hunks on this file are `@@ -9,9 +9,6 @@` (the header list) and `@@ -196,117 +193,6 @@` (the helper), and `12f96cd..HEAD` does not touch `scripts/`.

**Evidence:** `scripts/lib/si-input.sh:35-38,107`, `git show 12f96cd -- scripts/lib/si-input.sh`, `git log -L107,107:scripts/lib/si-input.sh`

---

## Claim 7b: override-log row's "pre-existing untested paths ... case-insensitive heading match"

**Location:** `docs/reviews/override-log.md:80`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case-folding path at `:107` and whether any test runs the missing-file branch. It does not establish coverage from outside `test/`.
**Legibility-target:** for-author

The missing-file branch really is untested. No test calls `parse_si_input` with a missing path; `test/function-inventory.bats` only checks `type -t` (`:52-53`, `:69`).

The case-folding is partly tested. Every fixture uses Title-case headings (`## Feedback`, `## Priorities`, ...), so removing `,,` (`case "${heading}" in`) fails all three tests. What is untested is folding beyond the first character: `case "${heading,}" in` (lowercase the first character only) passes all three, because no fixture uses e.g. `## FEEDBACK` or `## Off-Limits`. A precise version would read: "case-insensitive match for headings other than Title case".

**Evidence:** `scripts/lib/si-input.sh:107`, `test/si-input-parse-comments.bats:19,29,40`. Executed: `bats test/si-input-parse-comments.bats` in `/home/node/.claude/jobs/9f431b13/tmp/q065-fc2-mut/{m9_no_lower,m10_first_lower}`, exit 1 and exit 0 respectively, 2026-09-28T14:37:01-07:00. Output: `/home/node/.claude/jobs/9f431b13/tmp/q065-fc2-mutants-summary.log`

---

## Claim 8: rubric A1 author note: "Fixed in 2c1162b: new test ... (kills two mutants: preamble routed to Context, unknown heading routed to Context). The commit message's 11-of-12 imprecision is corrected in that fix commit's body; 12f96cd is not rewritten."

**Location:** `docs/reviews/q065-code-review-rubric-2026-09-28.md:23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit reference, the test name, the two mutants, the correction's location and the fact that 12f96cd is unchanged. It inherits Claim 3's caveat that other routing mutants survive.
**Legibility-target:** for-orchestrator-synthesis

`git show 2c1162b --stat` lists `test/si-input-parse-comments.bats | 19`, and the test name matches `:36` exactly. The mutant claim is confirmed by execution in Claim 5. 2c1162b's body carries the correction (Claim 6). 12f96cd's message still reads "Its 12 tests exercised only that function", so it was not rewritten.

**Evidence:** `docs/reviews/q065-code-review-rubric-2026-09-28.md:23`, `git show 2c1162b --stat`, `test/si-input-parse-comments.bats:36`, `/home/node/.claude/jobs/9f431b13/tmp/q065-fc2-mutants-summary.log`

---

## Claim 9: "Fix-drift lite check: the note said "next commit" but the test landed in 2c1162b itself."

**Location:** commit `35d6274` body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the before and after text of the A1 note and where the test landed. It does not cover other cells of the rubric.
**Legibility-target:** for-orchestrator-synthesis

35d6274's diff changes the A1 row from `Fixed in the next commit: new test ...` to `Fixed in 2c1162b: new test ...`, and `git show 2c1162b --stat` includes both the rubric and the test file.

**Evidence:** `git show 35d6274`, `git show 2c1162b --stat`, `docs/reviews/q065-code-review-rubric-2026-09-28.md:23`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 3** (`test/si-input-parse-comments.bats:38-39`): "reach no SI_* variable" is true of the code, but the test detects only Context and Off-limits leaks, plus a Feedback leak via the unknown heading. Three routing mutants survive because later sections overwrite the leaked text (preamble→Feedback, preamble→Priorities, Notes→Priorities). Narrow the comment or reorder the fixture.
- **Claim 4** (2c1162b body): the deleted test's pre-heading text was only an HTML comment, dropped by the comment-skip path at `si-input.sh:52-63`. It never reached the empty-heading discard and had no Context assertion. Precise version: "the only test with a comment before the first heading".
- **Claim 7b** (`docs/reviews/override-log.md:80`): case-folding of Title-case headings is tested (a mutant with no `,,` fails all three tests). Only folding beyond the first character is untested (a `${heading,}` mutant survives).

### Unverifiable
(none)

---

## Goal-Alignment Note

- **Answered:** All five "claims that particularly need checking" from the preamble. Claims 1–3 cover the test and its comment and header. Claims 4–6 cover the 2c1162b body, with mutants executed. Claims 7a and 7b cover the override-log row. Claims 8 and 9 cover the rubric A1 note and 35d6274.
- **Out of scope:** 12f96cd's own changes (context only, reviewed in iteration 1), and the docs/reviews/q065-*.md artifacts apart from the A1 author note. I did not append to hallucination-patterns.md: there are no Incorrect verdicts, and my instructions forbid writing other tracked files.
- **Escalate:** For test-strategy or the orchestrator: three routing mutants of `_save_si_section` survive the whole file (Claim 3). This is a Consider-grade gap in the A1 fix, not a regression; A1 as stated (the two named mutants) is closed.
