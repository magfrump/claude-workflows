# Research: Simplification Audit of 3 Longest Workflows

## Scope
Reduce user-testing-workflow.md (345 lines), research-plan-implement.md (241 lines), and codebase-onboarding.md (180 lines) by ≥20% each while preserving checkable quality signals (Done when... checklists).

## What exists

### user-testing-workflow.md (345 lines)
- 5 phases (0-4) + 3 appendices
- Phase 1 contains a 65-line moderator script template — the single largest block
- Appendix A (SUS questionnaire) is 38 lines of reference material
- Phase 3 has BOTH a Travis severity flowchart AND a Nielsen severity table — redundant
- Step 3.5 (Stress-Test Findings) is 13 lines that could be 5
- Done-when checklists exist only for Phase 0 (implicitly via the scoping questions)

### research-plan-implement.md (241 lines)
- 6 steps + refactoring variant + abbreviation guidance
- "When to pivot" (8 lines of dense paragraphs) — verbose
- Working documents section (18 lines) includes gitattributes how-to that's operational noise
- Test specification section (19 lines) explains every test level in detail
- Session handoff template (25 lines) + surrounding prose (8 lines)
- Done-when checklists added in R2 — these must be preserved

### codebase-onboarding.md (180 lines)
- 7 steps + relationship/re-run sections
- Step 6 (orientation doc template, 25 lines) repeats the structure already defined by steps 1-5
- "When to re-run" + freshness check (16 lines) partially duplicates guides/doc-freshness.md
- "Relationship to other workflows" (5 lines) overlaps with "When to pivot"
- Done-when checklists added in R2 — must be preserved

## Invariants
- All "Done when..." checklists from R2 must be preserved exactly
- Phase structure and phase names must remain recognizable
- Core actionable content (what to do) must survive; ceremony (why it matters philosophically) is cuttable
- The hypothesis predicts Weak scores won't increase — cuts must target verbosity, not substance

## Prior art
- Exit criteria checklists were added in commit b2e5795 — these are the quality signals to preserve
- The subtraction-checklist.md recommends: trim sections for over-budget workflows, cite evidence

## Gotchas
- The moderator script in user-testing-workflow is the most directly useful reference material — cut examples but keep the structural skeleton
- SUS questionnaire is a standardized instrument — can't change the items, but can compress formatting
- RPI's refactoring variant is a distinct use case — trim but don't remove
