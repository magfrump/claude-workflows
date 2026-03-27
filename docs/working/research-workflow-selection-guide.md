# Research: Workflow Selection Guide

## Scope
Create a prescriptive decision-tree guide that answers "which workflow should I use right now?" via yes/no questions, with leaf nodes pointing to specific workflow files.

## What exists
- **CLAUDE.md** has a descriptive list of all 10 workflows with one-liner descriptions and general guidance ("default: research-plan-implement for features, divergent-design for decisions, spike for unknowns, codebase-onboarding for new projects")
- **guides/README.md** indexes all guides with descriptions
- Workflows live in `~/.claude/workflows/` (10 files)
- Each workflow has "When to use" and "When to pivot" sections that define entry/exit criteria

## Key workflows and their distinguishing criteria

| Workflow | Primary signal | Key differentiator |
|----------|---------------|-------------------|
| bug-diagnosis | It's a bug AND you know the code area | Speed: no plan approval gate |
| codebase-onboarding | Unfamiliar codebase | Pre-task orientation, not task-specific |
| research-plan-implement | Non-trivial feature/change | Default; thorough research-then-plan |
| divergent-design | Multiple viable approaches | Generates/evaluates many candidates |
| spike | Feasibility unknown | Timeboxed throwaway exploration |
| task-decomposition | Large task, multiple subsystems | Parallelizes research via sub-agents |
| pr-prep | Ready to open a PR | Cleanup + review-fix loop |
| user-testing | Need usability data | Methodology for running user tests |
| branch-strategy | High-volume dev with async review | VCS coordination pattern |
| review-fix-loop | Sub-procedure of pr-prep | Not standalone |

## Decision tree structure

The natural decision flow:
1. Is this a bug? → bug-diagnosis (if familiar code) or RPI (if unfamiliar)
2. Is the codebase familiar? → codebase-onboarding first
3. Is this about opening a PR? → pr-prep
4. Is feasibility unknown? → spike
5. Are there multiple viable approaches? → divergent-design
6. Does it touch multiple independent subsystems? → task-decomposition
7. Is this about running a user test? → user-testing
8. Default → research-plan-implement

Branch-strategy and review-fix-loop are coordination patterns, not task workflows — they should be noted separately.

## Invariants
- Must reference actual workflow filenames in `~/.claude/workflows/`
- Must be prescriptive (yes/no questions), not descriptive
- Must complement CLAUDE.md, not duplicate it

## Prior art
- CLAUDE.md's workflow list is the closest, but it's descriptive not prescriptive
- No existing decision tree guide in guides/
