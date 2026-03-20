# 002: Critic-Style Code Review

## Context

The CC/YC prose critic pattern (structured cognitive moves producing markdown critique) has proven effective for draft review. PR-prep's self-review step is a manual checklist. The opportunity is to create code-review critic agents — security-reviewer, performance-reviewer, API-consistency-reviewer — that apply domain-specific cognitive moves to code diffs, following the same pattern as cowen-critique and yglesias-critique.

## Options Considered

1. **Direct port of CC/YC pattern**: Standalone critic skills with 7-9 domain-specific moves each
2. **Single unified code-critic with switchable lenses**: One skill, multiple modes
3. **Code-review orchestrator (parallel to draft-review)**: Full pipeline with code-fact-check → critics → synthesis
4. **Extend PR-prep to dispatch sub-agents**: Modify PR-prep step 2
5. **Do nothing**: Document and defer
6. **Template + pluggable move sets**: Shared base skill with loadable move configs
7. **Diff-to-prose wrapper**: Translate diffs to prose, feed to existing critics
8. **Inline PR comment output**: File:line comments instead of standalone reports
9. **Tiered depth**: Quick vs deep review modes
10. **Adversarial red-team reviewer**: Single attacker-mindset agent
11. **Per-commit decomposition**: Review each commit separately, then synthesize
12. **Reuse draft-review orchestrator**: Swap text critics for code critics

## Decision

**Phased approach: standalone critics first (option 1), then orchestrator (option 3).**

Build three independent critic skills following CC/YC conventions — security-reviewer, performance-reviewer, API-consistency-reviewer. Each declares `code-fact-check` as a soft dependency via `requires:`. Each produces markdown output to `docs/reviews/`. Each has 7-9 domain-specific cognitive moves targeting things static analysis and linting cannot catch.

The code-review orchestrator is deferred to a follow-up. It will mirror draft-review's 3-stage pipeline (code-fact-check → code critics → synthesis + rubric). Building critics first validates the cognitive moves in practice before adding orchestration complexity.

## Rationale

- **Proven pattern**: CC/YC critics + draft-review orchestrator evolved incrementally; this follows the same path
- **Immediate value**: Standalone critics are useful without an orchestrator
- **Context budget**: Large diffs + skill instructions + surrounding code strain context windows; standalone critics let users scope to one concern at a time
- **Composability**: Skills designed for orchestrator compatibility from the start (same conventions, dependency declarations) make the future orchestrator straightforward

## Consequences

- **Easier**: Adding more code-critic types later (accessibility, testing-coverage, error-handling). Building the orchestrator when ready. Cross-referencing from PR-prep.
- **Harder**: Users must invoke critics individually until the orchestrator exists. No convergence signal across critic types yet.
