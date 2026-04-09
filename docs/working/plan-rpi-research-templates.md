# Plan: RPI Research Templates

## Scope
Add optional scenario-specific templates to the RPI research phase. See `docs/working/research-rpi-research-templates.md`.

## Approach
Create three template files in `workflows/templates/` (new-feature, bug-investigation, refactor) that provide scenario-specific starting structures built on top of the five required RPI research sections. Add a short paragraph to the RPI workflow's research step pointing to these templates as optional scaffolds. Follow the "Done when" checklist pattern: suggest what to investigate, not how to write it up.

## Steps

1. **Create `workflows/templates/research-new-feature.md`** (~60 lines)
   - Standard RPI sections with feature-specific prompting questions under each
   - Feature-specific sections: "Integration points", "User-facing behavior"
   - Clear "starting point, not a form" note at top

2. **Create `workflows/templates/research-bug-investigation.md`** (~60 lines)
   - Standard RPI sections with bug-specific prompting questions
   - Bug-specific sections: "Reproduction", "Hypotheses"
   - Reference to debugging defaults in CLAUDE.md

3. **Create `workflows/templates/research-refactor.md`** (~60 lines)
   - Standard RPI sections with refactor-specific prompting questions
   - Refactor-specific sections: "Current behavior characterization", "Caller/dependent map", "Test coverage"
   - Reference to the Refactoring variant in the RPI workflow (not duplication)

4. **Add template reference to `workflows/research-plan-implement.md`** (~10 lines added)
   - Insert after the research step's main description (around line 65, before confidence-provenance tags)
   - Short paragraph explaining templates are optional scaffolds
   - List the three templates with one-line descriptions

## Size estimate
~200 lines of new content across 3 template files, ~10 lines added to existing workflow file. No file approaches 500 lines.

## Test specification
No automated tests — these are markdown documentation files. Verification is structural:

| Test case | Expected behavior | Level | Diagnostic expectation |
|-----------|------------------|-------|----------------------|
| Templates contain all 5 required RPI sections | Each template has Scope, What exists, Invariants, Prior art, Gotchas | manual review | Missing section is visible by scanning headings |
| Templates have scenario-specific additions | Each template has at least 2 headings not in the base RPI spec | manual review | Count unique headings per template |
| RPI workflow references templates | Research step mentions `workflows/templates/` | manual review | Grep for "templates" in workflow file |
| Templates include "starting point" disclaimer | Each template has a clear note that it's not a form | manual review | Search for disclaimer text |

## Risks
- Templates could be too prescriptive, discouraging adaptation. Mitigation: use questions ("What does the user see?") rather than fill-in-the-blank fields.
- Template headings could be too generic to detect usage for hypothesis evaluation. Mitigation: use distinctive but natural headings (e.g., "Reproduction" for bugs, "Integration points" for features).
