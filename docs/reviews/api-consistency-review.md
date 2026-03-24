---
Last verified: 2026-03-23
Relevant paths:
  - skills/code-review.md
  - skills/draft-review.md
  - skills/matrix-analysis.md
  - patterns/orchestrated-review.md
---

# API Consistency Review

**Scope:** Branch `feat/r1-skill-output-schema-validation` vs `main` (15 files, 1027 lines added)
**Reviewed:** 2026-03-24
**Fact-check input:** Stage 1 report (5 verified, 1 mostly accurate, 1 incorrect, 1 unverifiable)

## Baseline Conventions

The existing codebase has two pre-existing format test files (`fact-check-format.bats` and `code-fact-check-format.bats`) that establish the test pattern convention:

1. **File naming:** `{skill-name}-format.bats` in `test/skills/`
2. **Structure:** `load helpers` at top, `setup()` calls a loader, then individual `@test` blocks organized by section (header, required sections, structural checks, leakage checks)
3. **Helper usage:** `load_report` for claim-based skills, `load_generic_report` for others; `assert_field_per_claim` / `assert_field_values` / `assert_section_exists` for assertions
4. **Report path:** `REPORT_PATH` env var with hardcoded fallback default
5. **Skip semantics:** Tests skip gracefully when report doesn't exist
6. **Leakage checks:** Negative assertions at end to ensure no cross-skill contamination

## Findings

#### 1. Inconsistent field name: `Impact` vs `Severity` in performance-reviewer tests

**Severity:** Inconsistent
**Location:** `test/skills/performance-reviewer-format.bats:44-49`
**Move:** #2 — Check naming against the grain
**Confidence:** High

The security-reviewer and api-consistency-reviewer tests both check for `**Severity:**` as the per-finding field (matching their respective skill definitions). The performance-reviewer test checks for `**Impact:**` instead. The performance-reviewer skill definition at `skills/performance-reviewer.md:202` specifies `**Severity:**`, making the test inconsistent with both the skill definition and the naming convention established by sibling tests.

This is also flagged by the fact-check (Claim 4, Incorrect).

**Recommendation:** Change `performance-reviewer-format.bats` to check for `**Severity:**` instead of `**Impact:**`, matching the skill definition and the pattern used by security-reviewer and api-consistency-reviewer.

#### 2. Inconsistent header flexibility: `#{1,2}` vs `^# ` across test files

**Severity:** Minor
**Location:** `test/skills/dependency-upgrade-format.bats:18`, `test/skills/tech-debt-triage-format.bats:9`
**Move:** #2 — Check naming against the grain
**Confidence:** Medium

Most test files check for `^# ` (exactly H1) in the title header. Two files (`dependency-upgrade-format.bats` and `tech-debt-triage-format.bats`) use `^#{1,2}` (H1 or H2). This is explained by comments noting these skills lack example reports, so the tests are more permissive. The inconsistency is intentional but creates a different contract for these two skills than for all others.

**Recommendation:** Document the convention that format tests should match the skill definition's output format exactly. When example reports are generated for these skills, tighten the patterns to match the actual output.

#### 3. `assert_field_values` searches REPORT_CONTENT, not FINDINGS_BODY

**Severity:** Inconsistent
**Location:** `test/skills/helpers.bash:90-97`
**Move:** #7 — Look for the asymmetry
**Confidence:** High

`assert_field_per_finding` correctly operates on `FINDINGS_BODY` (scoped to findings section). However, `assert_field_values` operates on `REPORT_CONTENT` (the entire document). This means field value validation applies to all instances of a field anywhere in the report, while field counting is scoped to findings only. If a `**Severity:**` value appears in a summary table or header that uses a different format, `assert_field_values` could flag it as invalid even though it's not in a finding.

**Recommendation:** Either scope `assert_field_values` to `FINDINGS_BODY` when called after `count_findings`, or accept the inconsistency and document it. The practical impact is low since most reports only use these fields in findings sections.

#### 4. Date field naming varies across test files

**Severity:** Minor
**Location:** Multiple files
**Move:** #2 — Check naming against the grain
**Confidence:** High

Different test files check for different date-related field names:
- `**Reviewed:**` (api-consistency, code-review, draft-review)
- `**Date:**` (performance-reviewer, security-reviewer, matrix-analysis)
- `**Checked:**` (draft-review)
- `**Evaluated:**` (self-eval)

Each follows its respective skill definition, so these are not bugs -- they are accurate reflections of different skill output formats. However, the lack of a common date field name across skills is a consistency gap in the skill definitions themselves, not in the tests.

**Recommendation:** No test changes needed. Consider standardizing the date field name across skill definitions in a future cleanup.

## What Looks Good

- **Consistent file structure:** All 12 new test files follow the same pattern established by the 2 existing files (header checks, section checks, structural checks, leakage checks). Easy to navigate and extend.
- **Consistent helper usage:** All test files use the shared helpers rather than reimplementing common patterns.
- **Correct severity scales per skill:** api-consistency uses `Breaking|Inconsistent|Minor|Informational`, security uses `Critical|High|Medium|Low|Informational`, and both match their respective skill definitions.
- **Leakage checks are symmetric:** Cowen checks for absence of Yglesias sections and vice versa. Reviewer tests check for absence of fact-check verdict language. This is a good pattern.
- **`REPORT_PATH` override convention is consistent:** Every test file supports the same env var override pattern.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Impact vs Severity naming mismatch | Inconsistent | `performance-reviewer-format.bats:44-49` | High |
| 2 | Inconsistent header flexibility | Minor | `dependency-upgrade-format.bats:18`, `tech-debt-triage-format.bats:9` | Medium |
| 3 | assert_field_values scope mismatch | Inconsistent | `helpers.bash:90-97` | High |
| 4 | Date field naming varies | Minor | Multiple | High |

## Overall Assessment

The new test files are highly consistent with each other and with the established patterns in the codebase. The most significant consistency issue is the `Impact` vs `Severity` naming mismatch in the performance-reviewer test (Finding 1), which is a straightforward fix. The `assert_field_values` scope inconsistency (Finding 3) is a subtle design gap in the helper layer that could cause false failures in edge cases. Overall, the API surface (the helper functions and test conventions) is well-designed and easy to extend for future skills.
