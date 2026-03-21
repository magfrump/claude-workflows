# 003: Critic Cognitive Moves as DD Evaluation Lenses

## Context

The matrix analysis (Theme 9) identified that CC and YC's cognitive moves could serve as evaluation lenses for DD's tradeoff matrix. DD step 4's default dimensions (Effort, Risk, Core problem coverage, Key downside) are surface-level and can miss failure modes that structured critique would catch — e.g., whether the "obvious best" approach survives organizational change, works at scale, or is actually more complex than needed.

## Options Considered

1. Direct embedding as fixed matrix columns
2. Critic sub-agent dispatch (parallel evaluation per approach)
3. Move menu during match-and-prune (step 3)
4. Standalone DD-critic skill
5. Annotated constraints (tag constraints with applicable moves)
6. Replace step 4 entirely with structured critique
7. Do nothing
8. Lightweight prompt injection (mention moves, no structure)
9. Move-specific fixed columns
10. Two-pass evaluation (matrix first, then stress-test with moves)
11. Conditional invocation (only when confidence < 70%)
12. Domain-adaptive move selection (mapping table from decision type to moves)

## Decision

**Two-pass evaluation (#10): tradeoff matrix followed by a stress-test pass using adapted cognitive moves.**

Added a "Stress-test pass" subsection to DD step 4 with a table of 7 adapted moves, guidance on which apply when, and instruction to apply 2-4 relevant moves per surviving approach.

## Rationale

- **Addresses the actual gap**: DD's evaluation dimensions were generic; the stress-test pass adds structured, domain-adapted critique lenses
- **Non-destructive**: The existing tradeoff matrix is preserved; the stress-test supplements rather than replaces it
- **Selective by design**: "Not all moves apply" + "use 2-4 relevant ones" prevents forced application of irrelevant criteria
- **No new dependencies**: Everything stays within DD as a self-contained workflow — no sub-agents, no external skills
- **Future-compatible**: A "deep-divergent-design" flow using sub-agent orchestration (option #2) could be built later as a separate workflow that expands on this foundation

### Moves adapted vs. omitted

Adapted: CC #1 (boring explanation), CC #2 (invert), CC #3 (revealed preferences), CC #4 (push to extreme), YC #4 (organizational survival), YC #6 (scale test), YC #7 (org chart).

Omitted: CC #5 (cross-domain analogy — too slow for DD evaluation), CC #6 (market signal — rarely applicable to architecture), YC #3 (follow the money — not relevant to technical decisions), YC #5 (cost disease — too domain-specific), YC #8 (find the popular version — political framing, not technical).

## Consequences

- **Easier**: Catching non-obvious failure modes in design decisions. Building a future deep-DD workflow that dispatches sub-agents with these moves. Consistency between how the repo evaluates prose (CC/YC) and how it evaluates designs (DD).
- **Harder**: DD step 4 is longer to read. Risk of over-applying moves to simple decisions (mitigated by "2-4 relevant" guidance).
