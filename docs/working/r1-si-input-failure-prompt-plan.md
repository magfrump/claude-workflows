# Plan: SI Input — Failure Modes Section

## Goal

Add a `## Failure modes from last cycle` section to both the SI input
template and the current working copy, asking the user what failure modes
from the last cycle should drive next cycle's priorities. Include 2–3
example lines (as a guiding HTML comment) to make the shape concrete.

## Files in scope

- `templates/si-input.md` (does not yet exist — create from the structure
  of `docs/working/si-input.md`).
- `docs/working/si-input.md` (add the same section to the user's current
  working copy).

## Placement

Insert the new section between `## Feedback` and `## Priorities`.
Rationale: failure-mode reflection feeds directly into the next cycle's
priorities, so it logically sits just before them.

## Section shape

```
## Failure modes from last cycle
<!-- What failure modes have you seen in the last cycle that should
drive next cycle's priorities?
Examples:
- "DD generated 3 trivial variants — diversity criterion not enforced"
- "Self-eval skipped on small diffs with no skip-cause, masking a regression"
- "Code review surfaced 15 findings but only 2 were actionable — signal/noise too low" -->
```

The question and examples live inside the HTML comment so the parser's
existing comment-skipping behavior leaves them out of any captured
section text. The user fills their actual answer below the comment, the
same pattern the other sections already use.

## Out of scope (parser handling)

The parser in `scripts/lib/si-input.sh` only recognizes the four existing
section names (Feedback, Priorities, Off-limits, Context). A new section
is silently ignored — which is fine for this round: the prompt's value
is in shaping the user's reflection before the next run. Wiring the new
section into the DD prompt is a follow-up that requires touching
`scripts/lib/si-input.sh`, which is outside this round's file scope.

## Verification

- Both files contain a `## Failure modes from last cycle` heading
  between Feedback and Priorities.
- The HTML comment includes the question and 2–3 example lines.
- The existing parser still treats the file as valid markdown (no
  structural changes to recognized sections).
