Goal: Require the Project state line of the RPI three-line header to end with a `(cite: ...)` locator so the legibility claim is self-auditable.
Project state: Round-2 edit to `workflows/research-plan-implement.md` step 2; sibling to round-1 fact-check inline-citation requirement; not blocked (cite: 728b3f5).
Task status: complete (edits applied, commit pending).

Research: docs/working/r2-rpi-project-state-cite-line-research.md

## Approach

Surgical two-point edit to step 2 of `workflows/research-plan-implement.md`:

1. Extend the Project state bullet to require a trailing `(cite: <short-hash> | <branch-name> | <docs/path>)` locator, with a sentence explaining what each locator form is for and one sentence tying the pattern back to the fact-check inline-citation requirement so the cross-skill lineage is visible.
2. Add a Done-when checklist item that specifically checks for the cite, so the legibility claim is independently auditable (the self-audit posture — what makes the 7% drift visible — needs its own line on the checklist, not a buried sub-clause).

Leave step 3 (Plan) untouched: its header bullet already says "Same one-sentence project state as the corresponding research doc," so the cite requirement propagates by reference. Adding a separate edit to step 3 would duplicate the spec text and risk drift between the two definitions.

## Steps

1. Edit `workflows/research-plan-implement.md` line 67 (the Project state bullet inside step 2): append the cite locator to the inline format string, then add explanatory sentences covering the three locator forms and the fact-check lineage. ~6 lines of prose added to one bullet.
2. Edit `workflows/research-plan-implement.md` line 116 (the first Done-when item in step 2): split the cite check out into its own checklist item. ~1 line added.
3. Commit: `feat(rpi): require cite locator on Project state header line`.

## Implementation order

Sequential: `1 → 2 → 3`. Both edits touch the same file and the commit covers both — no parallelism.

## Size estimate

- Step 1: ~6 lines added to the Project state bullet.
- Step 2: ~1 line added to the Done-when checklist.
- Total: ~7 lines of prose added to `workflows/research-plan-implement.md` (currently 432 lines → ~439 lines, well under the 500-line guideline).

## Estimated context cost

Research ~8k, Implementation ~6k, Review ~4k. Small workflow edit — totals on the low end of the typical range.

## Actual context cost (post-implementation)

Research ~7k, Implementation ~5k, Review ~3k. In line with the estimate; small workflow edit, no surprises.

## Test specification

| Test case | Expected behavior | Level | Diagnostic expectation |
|-----------|------------------|-------|----------------------|
| Re-read step 2 of the modified file | Project state bullet now requires a trailing `(cite: ...)` locator and explains the three forms | Characterization (doc-level) | If the cite requirement is missing or ambiguous, the re-read surfaces it |
| Re-read step 2's Done-when checklist | A distinct checklist item checks for the cite locator | Characterization (doc-level) | If no item names the cite, the checklist fails its self-audit purpose |
| Read step 3's Project state bullet | Unchanged; inherits the cite requirement by "Same one-sentence project state" reference | Characterization (doc-level) | If step 3 was modified, that's a scope violation per the task brief |
| The two example headers in the new research/plan docs both end with `(cite: 728b3f5)` | Demonstrates the requirement in the same round it's specified | Characterization (doc-level) | Shows the pattern in use, not just defined |

These are doc-level characterization tests — re-reads, not runnable code. No test framework applies; the verification is "read the file and confirm the spec is unambiguous."

## Risks

- **Wording risk**: The cite explanation needs to be tight enough not to bloat step 2, but specific enough that "what form should I use" doesn't become a recurring question. Mitigation: lead with the format string, follow with one explanatory sentence per form, and one sentence on the fact-check lineage. Cap the added prose at ~6 lines.
- **Propagation risk**: If a future edit decouples step 3's Project state definition from step 2's, the cite requirement could silently drift out of plan docs. Mitigation: the current spec text in step 3 ("Same one-sentence project state as the corresponding research doc") is robust to wording changes in step 2 — both will be re-read at step 5 anyway.
- **Locator-choice ambiguity**: Authors may pick the wrong locator form (e.g., a `docs/path` for what's really a commit fact). The natural ranking is: prefer the most specific verifiable artifact. Worth one sentence in the spec, but full guidance would over-engineer. Accept some authorial discretion.
