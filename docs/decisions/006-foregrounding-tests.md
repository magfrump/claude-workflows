# 006: Foregrounding Tests as a Human-LLM Interface

## Context

Tests in the current workflow system are treated as a verification step — something that happens during or after implementation. The RPI workflow mentions "testing strategy" as a one-line plan section and "characterization tests first" in the refactoring variant, but neither gives tests a primary role in the human-LLM collaboration loop.

The core insight motivating this decision: **tests are the most precise, executable form of requirements.** A human who designs test cases has expressed intent in a way that's unambiguous and machine-checkable. This makes tests a natural interface between human specification and LLM implementation — the human designs the behavioral contract, the LLM writes code to satisfy it.

Additionally, when implementation goes wrong, well-designed tests with rich diagnostic output are the human's primary window into what happened. The quality of test failure output directly determines whether the human can diagnose a problem without re-running or reading all the code.

The central use case is code development in other repos, not testing workflow prompts in this repo.

## Options Considered

**13 approaches were generated via divergent design** (the full list was explored in conversation; 6 survivors are summarized here). The diverge/diagnose/match analysis evaluated them against constraints including: human-designability (tests must be specifiable without deep framework knowledge), cross-language applicability, LLM-implementability, diagnostic quality, and integration with existing workflows. Key candidates that survived pruning:

1. **Test-first plan step** — Restructure RPI's testing section from a one-liner to a structured block where the human specifies test cases, test levels, and diagnostic expectations during planning
2. **Standalone test-design workflow** — A separate workflow doc for test specification. Rejected: too much ceremony, creates a parallel process that competes with RPI
3. **Conversational test negotiation** — Interactive protocol where the LLM proposes tests and the human accepts/rejects. Rejected for universal use: adds a round-trip that's overkill for simple features, though the pattern is valid ad-hoc
4. **Test taxonomy guide** — Reference doc for test levels (unit, integration, characterization, property) to inform human test design choices
5. **Test review checkpoint** — Gate in implementation where human reviews test code before implementation code
6. **Do nothing** — Existing RPI guidance is sufficient. Rejected: the guidance exists but is a throwaway line that gets skipped in practice

## Decision

**Combine approaches 1 + 4 + 5**: restructure RPI's testing section into a first-class planning artifact, add inline taxonomy guidance, and insert a test review gate before implementation review.

Concretely:

1. **Restructure the RPI Plan phase (step 3)** — The "testing strategy" section becomes a structured block where the human specifies:
   - Test cases with expected behavior (what the code should do, in plain language)
   - Test level for each case (unit / integration / characterization / property)
   - Diagnostic expectations (what should be visible when a test fails — expected-vs-actual values, state snapshots, error messages)

2. **Inline test taxonomy** — Brief guidance within the RPI testing section on when to use each test level, so the human can make informed choices without consulting a separate doc

3. **Test review gate** — During implementation, the LLM writes tests first and the human reviews test code before implementation begins. This confirms the tests match the human's intent before the LLM invests in making them pass

4. **Diagnostic guidance** — Patterns for making test failures informative: descriptive assertion messages, expected-vs-actual traces, state context in failure output

## Consequences

### Makes easier
- Human specifies behavior precisely before implementation begins — fewer misunderstandings
- Test failures become diagnostic tools, not just red/green signals
- The human reviews tests (the specification) before implementation (the solution), catching intent mismatches early
- Test design becomes a conscious planning activity with vocabulary for different levels

### Makes harder
- Planning takes slightly longer for the testing section (mitigated: simple features can use minimal test specs)
- The LLM must write tests before implementation, which changes the implementation flow
- Humans unfamiliar with test levels need to learn the taxonomy (mitigated: inline guidance keeps it lightweight)
