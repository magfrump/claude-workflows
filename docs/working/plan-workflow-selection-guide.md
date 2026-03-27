# Plan: Workflow Selection Guide

## Scope
Create `guides/workflow-selection.md` as a prescriptive decision tree and add it to `guides/README.md`.

Research: [research-workflow-selection-guide.md](research-workflow-selection-guide.md)

## Approach
Build a markdown document structured as a series of numbered yes/no questions. Each question leads to either another question or a leaf node naming a specific workflow file. Use indented text or a visual tree format for clarity. Include a quick-reference table at the end.

## Steps

1. **Create `guides/workflow-selection.md`** (~80-120 lines)
   - Title and intro paragraph explaining this is a prescriptive "which one now?" guide
   - Decision tree as numbered questions with yes/no branches
   - Each leaf links to the workflow file path
   - Note on coordination patterns (branch-strategy, review-fix-loop) separately
   - Quick-reference summary table

2. **Update `guides/README.md`** (~3 lines added)
   - Add entry for workflow-selection.md in alphabetical position

## Test specification
No automated tests — this is a documentation-only change.

## Risks
- Decision tree may not cover edge cases; mitigated by noting that RPI is the default fallback
- Workflows may evolve; the guide should be treated as a living document
