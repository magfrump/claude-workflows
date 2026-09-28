Commit: 12f96cd

# Test Strategy: Q-065 [1], delete `prepend_si_input_rejected_history` (branch review/q065)

**Scope:** `git -C /workspace/.claude/wt-q065 diff main...HEAD` (main 6405e43 → HEAD 12f96cd): `scripts/lib/si-input.sh`, `test/si-input-parse-comments.bats` (new), `test/si-input-rejected-history.bats` (deleted)
**Reviewed:** 2026-09-28
**Trigger:** fact-check Claim 2 escalation. The deleted test "comment block does not pollute parsed sections" was the only test that ran `parse_si_input` on a file with content before the first `##` heading.

## Test Conventions

- bats, one file per unit under `test/`, `# @category fast` header read by `scripts/run-tests.sh`. `setup()` sources `scripts/lib/si-input.sh`, uses a `mktemp -d` fixture dir, and removes it in `teardown()`.
- Fixtures are inline `printf` strings written to `$INPUT_FILE`. Assertions compare exported `SI_*` variables with exact `[ "$X" = "..." ]` (the moved tests), not substring globs (the deleted test).
- Tests that touch `parse_si_input` today: `test/si-input-parse-comments.bats` (2 behavioural tests) and `test/function-inventory.bats:52-53` (existence only). `test/parse-si-priority-hypotheses.bats` covers the other function and never calls `parse_si_input`.

## What the deleted test actually guarded (probe)

I ran `parse_si_input` on a pre-heading fixture against the unchanged library and two mutants, each in a temporary copy that was then deleted. All probes ran under `timeout 10`; no process was left running.

- **m1**: the `in_comment=1` set at `scripts/lib/si-input.sh:61` is removed, so multi-line comments are no longer tracked.
- **m2**: `_save_si_section` maps the empty heading `""` to `SI_FEEDBACK`, so preamble text leaks into Feedback.

```
ok|FB=[the real feedback] PR=[- priority one] CX=[] OL=[]
m1|FB=[the real feedback] PR=[- priority one] CX=[stray preamble prose] OL=[]
m2|FB=[stray preamble prose

the real feedback] PR=[- priority one] CX=[] OL=[]
```

Findings from the probe:
- Comment handling does not depend on `current_section`. A pre-heading comment goes through the same lines (`:53-63`) as an in-section comment, and the moved test "parse_si_input drops the middle lines of a multi-line HTML comment" already kills m1. So the comment half of the lost assertion is **still covered**.
- The other half was only implicit: non-comment text before the first heading is discarded because `_save_si_section` has no `case` arm for `""`. No surviving test asserts it. The deleted test did not really guard it either. Its preamble was entirely a comment, so m2 alone would not have failed it. The deleted test only failed if both mechanisms broke together. What was lost is therefore thin, but the discard behaviour is now asserted nowhere.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/si-input.sh:76,91,103-112 — `_save_si_section` falls through its `case` for the empty heading `""`, so non-blank, non-comment text before the first `##` heading is discarded. The moved tests reach this path only with a blank line (test 1's `# SI Input\n\n`), and `_trim_blank_lines` hides that, so m2 survives the whole suite. Not covered. The last partial assertion went with `main:test/si-input-rejected-history.bats:178-188`.
- **G2** — scripts/lib/si-input.sh:103-112 — the same fall-through for an unrecognised heading (e.g. `## Notes`), whose body must not reach any `SI_*` variable or merge into the previous section. Not covered. No test at main or HEAD used an unknown heading. This is adjacent to the change rather than lost by it; I list it because the fix is one extra line in the same fixture.
- **G3** — scripts/lib/si-input.sh:52-63 — a multi-line comment *before the first heading* that contains a `## <known section>` line. This is the literal shape the deleted helper produced, a `<!-- Recent rejections ... -->` block at the top of the file. It is covered by the same code path as test 1 (m1 is killed there), so this is **partially covered**: the code path is covered, but the position is not. It becomes worth pinning only as a free side-effect of the G1 fixture.

Evidence for the lost assertion (deleted code):

```bash
# main:test/si-input-rejected-history.bats:178-188
@test "comment block does not pollute parsed sections" {
  write_round_report 1 "$(rejected_entry task-foo 'something failed')"
  printf '## Feedback\n\nthe real feedback\n\n## Priorities\n\n- priority one\n' > "$INPUT_FILE"
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"

  parse_si_input "$INPUT_FILE"
  [[ "$SI_FEEDBACK" == *"the real feedback"* ]]
  [[ "$SI_FEEDBACK" != *"task-foo"* ]]
  [[ "$SI_PRIORITIES" == *"priority one"* ]]
  [[ "$SI_PRIORITIES" != *"Recent rejections"* ]]
}
```

Evidence for the uncovered branch (post-change):

```bash
# scripts/lib/si-input.sh:103-113
_save_si_section() {
    local heading="${1:-}"
    local text="${2:-}"

    case "${heading,,}" in
        feedback)    SI_FEEDBACK="$text" ;;
        priorities)  SI_PRIORITIES="$text" ;;
        off-limits)  SI_OFF_LIMITS="$text" ;;
        context)     SI_CONTEXT="$text" ;;
    esac
}
```

### Finding TS1: pre-heading and unknown-section discard is no longer asserted

- **Severity:** Must Address (low blast radius). A regression would put stray preamble or unknown-section prose into the planner prompt through `SI_FEEDBACK`. The prompt would be noisy but not broken, and nobody would notice. The fix costs one test.
- **Location:** `test/si-input-parse-comments.bats:33` (append after the last test); the branch under test is `scripts/lib/si-input.sh:107-112`
- **Evidence:** `scripts/lib/si-input.sh:107-112` quoted above; deleted assertion `main:test/si-input-rejected-history.bats:178-188` quoted above; probe output (m2 survives the current suite, since neither moved fixture has non-blank pre-heading text).
- **Confidence:** High. The branch was read in full (`parse_si_input` :26-100 and `_save_si_section` :103-113), and the mutants were executed.
- **Legibility-target:** for-author

## Recommended Tests

#### parse_si_input discards preamble and unknown sections before and between known headings

**Closes gaps:** G1, G2, G3
**Type:** unit
**Priority:** medium
**File:** `test/si-input-parse-comments.bats` (append as the third `@test`; the file's subject, "parse_si_input's handling of HTML comments", stays accurate if its header comment is widened to "HTML comments and non-section text")
**What it verifies:** only text under the four known `##` headings reaches `SI_*`. Anything before the first heading (comment or prose) or under an unknown heading is dropped.
**Key cases:**
- A pre-heading multi-line `<!-- Recent rejections ... -->` block containing `## Context`, followed by a bare prose line, then `## Feedback` / `## Priorities`. Expect `SI_CONTEXT` to be empty (kills m1) and `SI_FEEDBACK` to equal exactly `the real feedback` (kills m2).
- An `## Notes` section between Feedback and Priorities. Expect its body in no variable, and `SI_FEEDBACK` still exact (G2).

```bash
@test "parse_si_input drops text before the first heading and under unknown headings" {
  printf '<!-- Recent rejections (last 3 rounds):\n  Round 1: task-foo — something failed\n## Context\n-->\nstray preamble prose\n## Feedback\n\nthe real feedback\n\n## Notes\nunknown section body\n## Priorities\n\n- priority one\n' > "$INPUT_FILE"
  parse_si_input "$INPUT_FILE" 2>/dev/null
  [ "$SI_FEEDBACK" = "the real feedback" ]
  [ "$SI_PRIORITIES" = "- priority one" ]
  [ -z "$SI_CONTEXT" ]
  [ -z "$SI_OFF_LIMITS" ]
}
```

**Setup needed:** none beyond the file's existing `setup()`/`teardown()`. I executed the fixture without the `## Notes` lines against HEAD (it passes) and against m1 and m2 (both fail on the assertions above). I did not execute the `## Notes` addition. By reading `:74-80` and `:107-112`, the Notes body is saved under heading `notes`, which matches no arm, and the next heading resets `section_text`, so the test should pass at HEAD. The author should run it once before committing.

## What NOT to Test

- **The 11 deleted tests of `prepend_si_input_rejected_history`.** Their subject no longer exists, so no replacement is warranted.
- **`bats_require_minimum_version 1.5.0` was dropped with the old file.** The new file uses no `run` at all, let alone `run !`/`run -N`, so nothing depends on it. Re-add it only if a future test in the file uses those flags.
- **`test/function-inventory.bats`.** Its expected-function list never included the deleted helper, so it needs no change.

## Coverage Gaps Beyond Current Scope

**1.** `scripts/lib/si-input.sh:35-38`: `parse_si_input`'s missing-file branch (returns 1, resets all four `SI_*` to empty) has no behavioural test. `scripts/self-improvement.sh:493` depends on it through `|| true`. This gap existed before the change and was not lost by it.
**2.** `scripts/lib/si-input.sh:107`: case-insensitive heading matching (`${heading,,}`, e.g. `## FEEDBACK`) is untested. Also pre-existing.

## Summary

The highest-value addition is one unit test in `test/si-input-parse-comments.bats`. It asserts that pre-heading text and unknown-section text never reach `SI_*` (closes G1-G3; the fixture is above and was probed against two mutants). The branch's claim that the moved tests keep the comment-handling coverage holds: the pre-heading *comment* case runs the same code as the moved test 1. What was lost is the implicit assertion that `_save_si_section` discards the empty heading, and the deleted test guarded even that only weakly. Residual risk after the plan: the two pre-existing gaps above. Open question for the author: widen the new file's header comment, or put the test in a new `test/si-input-parse-sections.bats`? The first is cheaper and fits the file's single-subject convention well enough.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the output path named in your role-specific tail, structured per your skill, ending with a Goal-Alignment Note."
- **Answered:** assessed the escalated gap (pre-heading comment case), with an executed mutant probe showing which half is still covered; checked for other lost coverage (none beyond G1, plus adjacent G2); named one concrete test with file, name, fixture and assertions.
- **Out of scope:** did not run the full fast suite or health-check. Did not edit any tracked file or commit. Did not re-verify fact-check Claims 1, 3-8.
- **Escalate:** none new. TS1 is a Must Address for the fix batch: add the test, or record an override-log row if declined.
- **Questions / Decisions:** Decision: I rated TS1 Must Address rather than Consider because it restores an assertion the branch itself removed, even though the blast radius is low.
