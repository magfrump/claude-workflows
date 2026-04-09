# Research: RPI Research Templates

## Scope
Add optional scenario-specific templates to the RPI research phase that reduce blank-page friction without making the workflow rigid.

## What exists

### RPI research step (workflows/research-plan-implement.md, lines 55-92) [observed]
The research step requires five sections: Scope, What exists, Invariants, Prior art, Gotchas. It also specifies confidence-provenance tags ([observed], [inferred], [assumed]) and design-decision detection signals. The step produces a `docs/working/research-{topic}.md` file.

### Refactoring variant (lines 280-296) [observed]
The RPI workflow already has a "Variant: Refactoring" section that adds scenario-specific guidance to the research phase: characterize current behavior, identify callers/dependents, check test coverage. This is the closest prior art to what we're building — it adds structure for a specific scenario type.

### "Done when" checklists [observed]
Every RPI step has a "Done when..." checklist with checkboxes. These were added in R4 (completion criteria standardization). They improved completion criteria without making the workflow rigid — the same pattern we want for templates.

### Existing research docs [observed]
`docs/working/research-active-away-mode-reliability.md` is an example. It follows the required sections but with scenario-specific content (e.g., "Root causes identified" instead of generic "What exists"). This shows research docs already deviate from a rigid format based on the task type.

### No existing templates directory [observed]
There is no `workflows/templates/` directory. Templates would be a new addition to the workflow infrastructure.

## Invariants
- The five required research sections (Scope, What exists, Invariants, Prior art, Gotchas) must remain the canonical structure [observed — the "Done when" checklist on line 88 checks for these]
- Confidence-provenance tags must remain part of the research process [observed — lines 67-72]
- Templates must not become mandatory — the RPI workflow must still work without them [inferred — the task specifies "optional scaffolds"]
- The Refactoring variant section must not be duplicated or contradicted by the refactor template [observed — lines 280-296]

## Prior art
- The Refactoring variant (lines 280-296) adds scenario-specific research guidance inline in the workflow doc. The templates approach externalizes this into separate files, which scales better (adding a new scenario doesn't bloat the main workflow).
- The "Done when" checklists provide structure without rigidity — they say what to achieve, not how to achieve it. Templates should follow the same philosophy: suggest what to investigate, not dictate the output format.

## Gotchas
- Templates that are too detailed become forms to fill in rather than scaffolds to build from. The task explicitly warns against this.
- The refactor template must complement, not duplicate, the existing Refactoring variant section. It should reference that section and add research-phase prompting questions, not restate the variant's guidance.
- Hypothesis evaluation: the task's hypothesis says "at least 1 research doc will share template section headings." Templates should have distinctive-enough headings that template usage is identifiable, but headings should still be natural (not artificially unique tracking markers).
