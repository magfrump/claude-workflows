# Plan: hypothesis source tag for bug-diagnosis workflow

## Goal
Require every hypothesis recorded during bug-diagnosis to carry a single inline source tag from a fixed taxonomy: `[from error message]` / `[from log analysis]` / `[from code reading]` / `[from intuition]` / `[from prior bug]`. Document what each tag means and how it should inform hypothesis prioritization.

## Why
The source of a hypothesis is a strong signal of its prior probability. A hypothesis derived directly from an error message names the proximal failure; an intuition-based hypothesis is cheap to form but the most likely to be wrong. Tagging the source surfaces this signal so debuggers don't sink time into low-evidence hunches when stronger signals are available, and so the diagnosis log captures *what kind of evidence* was driving each round of testing — useful for the 3-hypothesis escape hatch ("all three were intuition" is a stronger pivot trigger than "all three were code reading").

## Pattern to mirror
The existing step-3 structure in `workflows/bug-diagnosis.md`:
- Bulleted "good vs bad" example
- "Example hypotheses by bug category" with three labelled examples
- "A good hypothesis:" bullet list naming requirements
- "Done when..." checklist at the end of the step

The new content slots in cleanly: add a "Source tag" subsection after the "A good hypothesis:" list and before the recording instruction, update the three category examples to carry tags, add a tag bullet to the Done-when list, and add a Source column to the diagnosis log template's hypothesis table.

## Taxonomy (one-liners for the workflow doc)
- `[from error message]` — derived from the exception text, status code, or error string itself. Strongest signal because the error names the proximal failure.
- `[from log analysis]` — derived from log lines, traces, telemetry, or output surrounding the failure but distinct from the error itself. Strong but more interpretive.
- `[from code reading]` — derived from reading source and reasoning about its control or data flow. Strong when the code path is small and the suspect is on the stack; weaker as the surface grows.
- `[from intuition]` — pattern-matching from prior debugging experience without a concrete signal in hand. Cheapest to form, most likely to be wrong; deprioritize when other sources are available, but valuable when other sources are exhausted.
- `[from prior bug]` — derived from a similar past bug, a known-issues note, or institutional memory. Strong when the prior bug is well-documented and the analogy is tight; weak when the analogy is loose.

## Placement
1. Step 3 (Hypothesize), `workflows/bug-diagnosis.md`:
   - After the "A good hypothesis:" bullet list, before "Record the hypothesis in your diagnosis log."
   - Add a "Source tag" subsection that lists the five tags and the prioritization guidance.
2. Update the three "Example hypotheses by bug category" entries to lead with their source tag (regression → from prior bug or code reading; performance → from log analysis; intermittent → from log analysis).
3. Add `[ ] The hypothesis carries exactly one source tag from the taxonomy` to the step-3 Done-when checklist.
4. Diagnosis log template: add a `Source` column to the hypotheses-tested table.

## Files touched
- `workflows/bug-diagnosis.md` — step 3 subsection insertion, example tag updates, checklist addition, template column addition
- `docs/working/r1-bug-diagnosis-hypothesis-source-plan.md` — this plan

## Verification
- Re-read step 3 in context — the source tag requirement should be unmissable but not bury the existing guidance.
- Confirm all three example hypotheses carry a tag and the tags are plausible for the example.
- Confirm the diagnosis log template renders correctly as a markdown table with the Source column added.
- No other files modified (file-scope constraint).
