# Scope Exception: r3-decisions-made-self-report

## Files that should be updated but are outside scope

The fifth bullet `Decisions I made` is now part of the canonical form in `patterns/orchestrated-review.md`. For sub-agents to actually emit it, the orchestrator skills that template the form inline in their dispatch instructions need the new bullet added to those templates. The canonical form is duplicated, not just cited, in:

1. **`skills/code-review.md`** — two dispatch templates (lines ~207-211 for fact-check dispatch, lines ~287-291 for critic dispatch). Each has the four-bullet form pasted inline. Both need the fifth bullet appended:

   ```markdown
   - Decisions I made: [1-3 short lines naming silent judgment calls between equally plausible interpretations; otherwise omit this bullet]
   ```

   The accompanying paragraph after each template ("The 'Questions I would have asked' bullet is optional...") should also note that "Decisions I made" is optional and gestures at when to use it (silent judgment calls between equally plausible interpretations).

2. **`skills/draft-review.md`** — same pattern, two dispatch templates (lines ~154-158 for fact-check, lines ~221-225 for critic). Same edit shape as code-review.md.

3. **`workflows/codebase-onboarding.md`** — line 76 cites the canonical form by name and explicitly says "(three bullets: Answered / Out of scope / Escalate)". With two optional bullets now defined, this enumeration should be relaxed to "(three required bullets plus optional Questions / Decisions per the pattern doc)" or the parenthetical removed entirely so the cross-reference does the work.

## Synthesis-time consumption (also templated)

The "Goal-alignment scan" sub-step in both orchestrators (`skills/code-review.md` ~309-323 and `skills/draft-review.md` ~244-259) currently collects three things: `Answered: no/partial`, non-trivial `Out of scope`, non-trivial `Escalate`. To consume the fifth bullet's drift-detection signal, that scan should also collect `Decisions I made` entries and the synthesis should look for cross-sub-agent patterns — single decisions are informational, but a trend across critics is the drift signal worth surfacing.

This is a semantically richer change than the dispatch-template edits above (the consumer logic, not just the template) and would benefit from its own round.

## Why not changed

File scope constraint limits changes to `patterns/orchestrated-review.md` and `docs/working/`.

## Suggested follow-up rounds

- **R4 dispatch-template propagation**: add the fifth bullet to the four templated locations in `skills/code-review.md` and `skills/draft-review.md`; relax the enumeration in `workflows/codebase-onboarding.md`. Mechanical edit.
- **R5 drift-detection synthesis**: extend the Goal-alignment scan in both orchestrators to collect `Decisions I made` entries and surface cross-sub-agent patterns under `### Coverage and Escalations` (or a sibling section) as drift signals. Semantic change with design choices around what counts as a "pattern."
