# Code Review: Skill Output Schema Validation

**Branch:** feat/r1-skill-output-schema-validation
**Reviewed:** 2026-03-23
**Status:** CONDITIONAL PASS

## Summary

This branch adds 12 new BATS test files (plus extends 2 existing ones) to validate structural output schemas for all 14 skills, along with shared helper infrastructure in `helpers.bash`. The test design is sound -- validating structure without asserting content, using graceful skip-when-missing semantics, and including cross-skill leakage checks. A few issues in the helper functions could cause false passes in edge cases, and there are minor consistency gaps across test files.

## Findings

### Must Fix (if any)

| # | Finding | Location |
|---|---|---|
| R1 | `assert_field_per_finding` counts fields across the **entire** report, not scoped to the Findings section. If a metadata field like `**Confidence:**` appears in the header *and* in each finding, the count will exceed `FINDING_COUNT` and the assertion silently passes for the wrong reason, or fails spuriously. The same issue exists in `assert_field_per_claim` (pre-existing). Consider scoping the grep to the Findings section, or at minimum documenting the assumption that fields are unique to findings. | `test/skills/helpers.bash:38-43` |
| R2 | `count_findings` matches `^#{3,4} [0-9]+\.` but test files that call `count_findings` (api-consistency, performance, security) then call `assert_field_per_finding` which counts `^\*\*Field:\*\*` across the whole document. If any finding uses `###` while another uses `####`, the count is correct, but if the report has a `**Severity:**` line outside the findings section (e.g., in a summary table row), the field count will be wrong. This is fragile. | `test/skills/helpers.bash:33-34` |

### Must Address (if any)

| # | Finding | Location | Author note |
|---|---|---|---|
| A1 | `cat "$REPORT" \| tr -d '\r'` -- the `cat` is a useless use of cat (UUOC); `tr -d '\r' < "$REPORT"` is cleaner and avoids a subprocess. This appears in both `load_report` and `load_generic_report`. Minor but shows up in shellcheck. | `test/skills/helpers.bash:11,26` | -- |
| A2 | `api-consistency-reviewer-format.bats` line 69: the fallback `echo "$REPORT_CONTENT" \| grep -qiE 'Recommend'` will match the word "Recommend" anywhere in the report (including prose), making this test nearly always pass. Consider requiring at least one `**Recommendation:**` field *or* a `### Recommendation` heading instead. | `test/skills/api-consistency-reviewer-format.bats:69` | -- |
| A3 | `code-review-format.bats` and `draft-review-format.bats` check for emoji characters in grep patterns (`[🔴🟡✅]`). Emoji matching in grep depends on locale and grep implementation. If the system locale is not UTF-8 or grep is compiled without multibyte support, these tests will fail for environmental reasons rather than report quality. Consider an alternative like `grep -qE 'Must Fix\|DOES NOT PASS'` or testing the status line separately from the emoji. | `test/skills/code-review-format.bats:29,34-47`, `test/skills/draft-review-format.bats:28,34-46` | -- |
| A4 | Several test files hardcode default report paths that likely don't exist (e.g., `docs/reviews/performance-review.md`, `docs/reviews/security-review.md`, `docs/reviews/matrix-analysis.md`). The `load_generic_report` skip logic handles this gracefully, but users who run `bats test/skills/` without setting `REPORT_PATH` will see most tests skipped with no obvious indication of how to generate the reports. Consider adding a comment or README about this. | multiple files | -- |
| A5 | `self-eval-format.bats` line 63: the awk command `awk -F'\|' '{print $3}'` extracts the third pipe-delimited field. If the table has a different column order, or leading/trailing pipes are inconsistent, this silently extracts the wrong column. The test would pass even if scores were in a different column. | `test/skills/self-eval-format.bats:63` | -- |

### Consider (if any)

| # | Suggestion |
|---|---|
| C1 | The "no leakage" tests are a clever idea for catching skill prompt contamination. Consider extracting this into a shared helper (e.g., `assert_no_fact_check_language`, `assert_no_reviewer_language`) since the same patterns are duplicated across 6+ files. |
| C2 | `tech-debt-triage-format.bats` line 64: the `grep -iE` chain for Recommendation values is complex and fragile. The line `grep -iE '(Recommendation\|^Fix now\|^Fix opportunistically\|^Carry intentionally\|^Defer and monitor)'` first matches *any* line containing "Recommendation", then pipes to a second grep. If the heading line says "## Recommendation: Fix now", it matches; but if the recommendation value is on its own line below the heading, it might not. Consider using `assert_field_values` or a more targeted extraction. |
| C3 | `dependency-upgrade-format.bats` and `tech-debt-triage-format.bats` both allow `#{1,2}` for the title header, while other files require exactly `^# `. The inconsistency is intentional (noted in comments for skills without existing reports), but worth verifying these relaxed patterns match the actual skill prompt output format once reports are generated. |
| C4 | The `matrix-analysis-format.bats` test for rating symbols (`++`, `+`, `-`, `?`) on line 59 will match these characters anywhere in the report, not just in the matrix table. A `+` in prose text would satisfy the test. |
| C5 | Consider adding a test that validates the total test file count matches the total skill count, to catch regressions when new skills are added without corresponding format tests. This could live in `cross-skill-eval.md` or as a standalone BATS test. |

## What Works Well

- **Complete coverage**: Every one of the 14 skills has a corresponding format test file. This is disciplined and will catch regressions.
- **Graceful degradation via skip**: The `load_generic_report` / `load_report` skip semantics mean tests degrade to "skipped" rather than "failed" when reports don't exist. This is the right design for tests that depend on generated artifacts.
- **Cross-skill leakage tests**: Testing that a Cowen critique doesn't contain Yglesias sections (and vice versa) is a smart way to catch prompt bleed-through. Same for checking that reviewer reports don't contain fact-check verdict language.
- **Shared helpers reduce duplication**: The `assert_section_exists`, `assert_heading_exists`, `assert_field_per_finding`, and `assert_field_values` helpers keep individual test files focused on what matters for each skill.
- **`tr -d '\r'` normalization**: Handling Windows line endings in `load_report` and `load_generic_report` prevents mysterious failures on mixed-platform teams.
- **Consistent structure across files**: All test files follow the same pattern -- header checks, required sections, structural requirements, and leakage checks. Easy to navigate and extend.
