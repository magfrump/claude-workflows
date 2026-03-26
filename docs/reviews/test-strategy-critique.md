# Test Strategy Critique: Foreground Tests in RPI

**Reviewed:** 2026-03-26
**Scope:** Branch `feat/foreground-tests` vs `main` -- changes to `workflows/research-plan-implement.md`, `skills/test-strategy.md`, `docs/decisions/006-foregrounding-tests.md`, `docs/decisions/log.md`, and 9 review artifact rewrites.

---

## Test Conventions

This project tests markdown workflow/skill documents using two layers:

1. **BATS format tests** (`test/skills/*-format.bats`): Deterministic structural validation of generated reports. Tests use shared helpers from `test/skills/helpers.bash` (`load_report`, `load_generic_report`, `assert_heading_exists`, `assert_field_per_claim`, `assert_field_values`, etc.). Tests skip gracefully when no report exists.

2. **Eval criteria docs** (`test/skills/*/eval-criteria.md`): Non-deterministic behavioral evaluation rubrics for LLM-generated outputs, graded manually or by LLM.

File conventions: `test/skills/{skill-name}-format.bats` for format tests. Fixtures in `test/skills/{skill-name}/fixtures/`. Reports generated to `docs/reviews/`.

No tests exist for workflow documents (`workflows/*.md`) -- the existing test infrastructure targets skill outputs only. There is no test runner configuration (no Makefile, no CI config, no package.json); BATS is run directly.

---

## Recommended Tests

#### 1. Cross-reference consistency: RPI test specification references test-strategy skill taxonomy

**Type:** integration (structural)
**Priority:** high
**File:** `test/workflows/rpi-cross-references.bats` (new file, following BATS convention)
**What it verifies:** The test levels listed in RPI's inline taxonomy are a subset of those defined in the test-strategy skill, and the cross-reference ("the `test-strategy` skill has a full taxonomy") points to a section that exists.
**Key cases:**
- Each level named in `workflows/research-plan-implement.md` (unit, integration, characterization, property) appears in `skills/test-strategy.md`
- The phrase "test-strategy" in RPI's cross-reference corresponds to an actual skill file
- The test-strategy skill's RPI integration reference (line 153) uses the current section name ("test specification", not the old "testing strategy")

**Setup needed:** No fixtures. Just `grep`/`sed` against the two source files. Could reuse `load_generic_report` pattern from helpers or create a simpler workflow-specific loader.

---

#### 2. RPI structural consistency: step numbering and heading format

**Type:** unit (structural)
**Priority:** medium
**File:** `test/workflows/rpi-structure.bats` (new file)
**What it verifies:** RPI step headings follow the `### N. Name (essential/recommended) -- description` pattern, are sequentially numbered, and sub-sections use `####`.
**Key cases:**
- All `### N.` headings are sequential (1, 2, 3, 4, 5, 6)
- Each step heading includes `(essential)` or `(recommended)`
- No `###` heading exists that doesn't match the step pattern (except within fenced code blocks)
- Sub-sections within steps use `####`, not `###`

**Setup needed:** None. Pattern matching against the workflow file.

---

#### 3. Decision record structural consistency

**Type:** unit (structural)
**Priority:** medium
**File:** `test/decisions/decision-record-format.bats` (new file)
**What it verifies:** All decision records in `docs/decisions/` follow the established structural conventions.
**Key cases:**
- Every `docs/decisions/NNN-*.md` file has `**Date:**` and `**Status:**` fields within the first 5 lines
- Every decision record has `## Context`, `## Decision`, and `## Consequences` sections
- Every decision record with `## Consequences` has `### Makes easier` and `### Makes harder` subsections
- The `NNN` in the filename matches the `# NNN:` in the title heading

**Setup needed:** None. Glob for decision record files, pattern match against each. Note: this test would immediately flag 006 for its missing Date/Status fields (identified by the API consistency review, Finding 4).

---

#### 4. Decision log integrity

**Type:** unit (structural)
**Priority:** low
**File:** `test/decisions/decision-log-format.bats` (new file)
**What it verifies:** The decision log table is well-formed and links to existing files.
**Key cases:**
- Every `[NNN](NNN-*.md)` link in `docs/decisions/log.md` points to an existing file
- Entry numbers are monotonically increasing
- Each row has 5 pipe-separated columns

**Setup needed:** None. Parse the markdown table, check file existence.

---

#### 5. RPI plan section completeness: test specification table template

**Type:** unit (structural)
**Priority:** low
**File:** `test/workflows/rpi-structure.bats` (same file as test 2)
**What it verifies:** The test specification section in RPI step 3 contains the expected table header and level taxonomy.
**Key cases:**
- A markdown table header containing "Test case", "Expected behavior", "Level", "Diagnostic expectation" exists in the Plan section
- The "Choosing a test level" subsection lists at least the four core levels (unit, integration, characterization, property)
- The "Diagnostic expectations" subsection exists

**Setup needed:** None. Pattern matching.

---

## What NOT to Test

**Review artifact content** (`docs/reviews/*.md`): These files are per-branch snapshots generated by LLM skills and overwritten each PR cycle. Their content is non-deterministic and already validated by the existing BATS format tests when the corresponding skill generates them. Testing that these specific files have correct *content* would be testing the skill output, not the code changes on this branch. The format tests already cover structural validation.

**Decision record prose quality**: Whether the decision record's reasoning is sound, options are fairly characterized, or consequences are complete is a judgment call, not a structural property. The existing code-fact-check and critic skills already cover this in their review artifacts.

**The RPI workflow's behavioral effect on LLM output**: The core change (restructured test specification, test-first gate) is a prompt change. Testing whether an LLM actually follows these instructions would require running the workflow end-to-end with an LLM, which is expensive, non-deterministic, and outside the scope of structural testing. This is the domain of the eval criteria layer, not BATS tests.

**The `skills/test-strategy.md` one-line rename**: The change from "testing strategy" to "test specification" is a single string replacement. The cross-reference test (recommended test 1) covers this indirectly by verifying the reference matches the current RPI section name. A dedicated test for this single line would be over-specified.

---

## Coverage Gaps Beyond Current Scope

**1. No structural tests exist for any workflow document.** The entire `workflows/` directory (7 workflow files) has zero test coverage. The BATS infrastructure exists and could be extended, but all existing tests target skill outputs in `docs/reviews/`. The tests recommended above would be the first workflow-level structural tests in the project. This is the most significant gap -- workflows are the highest-traffic documents in the project (they are read every session), but they have no automated consistency checks.

**2. No test verifies cross-document link integrity across the repo.** Workflows reference each other (RPI references spike, divergent-design, codebase-onboarding), skills reference workflows, and decision records reference each other. A broken link (renamed file, changed section heading) would silently break navigation. A repo-wide link checker would catch this class of issue, including the stale reference found in this branch's API consistency review (Finding 1).

**3. The `test/skills/test-strategy-format.bats` test for "numbered items" may not match actual output.** The test checks for `^\*\*[0-9]+\.` (bold-prefixed numbers), but the test-strategy skill definition uses `1. **High value**:` (number then bold). This was flagged as "Unverifiable" in the previous branch's code-fact-check report (Claim 5). No test-strategy report has been generated to validate against, so the format test may be wrong. This predates the current branch but affects the test infrastructure that this branch's changes interact with.

---

## Summary

The changes on this branch are primarily prompt/documentation changes to markdown files, not executable code. The existing test infrastructure (BATS format tests) targets skill *outputs*, not the workflow/decision documents that were modified here. This creates a coverage gap: the most important files in the change set (`workflows/research-plan-implement.md`, `docs/decisions/006-foregrounding-tests.md`) have no automated structural validation.

The highest-value test is the cross-reference consistency check (recommended test 1), which would catch the class of bug already identified on this branch -- stale section name references between documents. This test has a high risk-to-effort ratio: the setup is trivial (grep two files), it catches real bugs (the API consistency review found one), and it prevents regressions as the test specification section evolves.

The structural tests for decision records and RPI headings (recommended tests 2-4) provide moderate value as guardrails against format drift, but are lower priority since the conventions are currently enforced by review rather than automation.
