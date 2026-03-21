# Decision 004: Complementary Skills and Workflows

## Context

Used divergent design to identify gaps in the current workflow/skill inventory. The existing set covers the development lifecycle (RPI), design decisions (DD), exploration (spike), decomposition (task-decomposition), code review (security, performance, API consistency), content review (fact-check, draft-review, critics), and analysis (matrix-analysis). But several common development activities had no structured support.

## Options Considered

15 candidates generated via divergent design, pruned to 5 survivors after constraint matching and stress-testing:

1. Codebase onboarding workflow — pre-task orientation for unfamiliar repos
2. Test strategy skill — concrete test recommendations based on risk and architecture
3. Tech debt triage skill — structured evaluation of carry-vs-fix tradeoffs
4. Dependency upgrade skill — changelog review, breaking change assessment, migration plan
5. Refactoring variant for RPI — characterization tests first, incremental steps, safety checks

Rejected candidates included: incident/debugging workflow (AI can't reliably run code), post-mortem (needs team context), migration planning (subsumed by RPI + task-decomposition), release checklist (too project-specific), estimation (AI estimates unreliable), documentation audit (overlaps code-fact-check), commit archaeology (too narrow), devil's advocate (overlaps existing critics + DD stress-test).

## Decision

Build all five. The onboarding workflow is a new file in `workflows/`. The three skills (test-strategy, tech-debt-triage, dependency-upgrade) are new files in `skills/`. The refactoring variant is an appendix to the existing RPI workflow rather than a separate workflow, since it specializes RPI rather than replacing it.

## Consequences

- **Makes easier**: Starting work in unfamiliar codebases, deciding what tests to write, prioritizing tech debt, evaluating dependency upgrades, structuring safe refactorings.
- **Makes harder**: Nothing significant. The additions are all opt-in and don't change existing workflow behavior.
- **Risk**: The new skills may produce generic advice if not grounded in actual code reading. Each skill's instructions emphasize reading implementation, not just signatures.
