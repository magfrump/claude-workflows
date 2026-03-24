# Code Review Rubric

**Scope:** `feat/r1-skill-output-schema-validation` vs `main` (15 files, 1027+/4- lines) | **Reviewed:** 2026-03-24 | **Status: 🟡 CONDITIONAL PASS** — 3 amber item(s) awaiting resolution or justification

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items unresolved.

| # | Finding | Domain | Location | Status |
|---|---|---|---|---|
| (None) | | | | |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they stand. Each must carry a resolution or author note.

| # | Finding | Domain | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | Performance-reviewer test checks for `**Impact:**` but skill definition specifies `**Severity:**`. Test will fail or skip on conformant reports. | Fact-check + API Consistency | `test/skills/performance-reviewer-format.bats:44-49` | 🟡 Open | -- |
| A2 | `assert_field_values` operates on `REPORT_CONTENT` (whole document) while `assert_field_per_finding` operates on `FINDINGS_BODY` (scoped). This asymmetry means field value validation can pick up values from Summary Table or Overall Assessment sections, causing false positives. | API Consistency + Fact-check | `test/skills/helpers.bash:90-97` | 🟡 Open | -- |
| A3 | `FINDINGS_BODY` captures from first finding to EOF (including Summary Table, Overall Assessment). Comment claims scoping "to avoid false matches from report-level metadata" but the scope is not tight enough to fully deliver on that promise. | Fact-check | `test/skills/helpers.bash:50-53` | 🟡 Open | -- |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement opportunities. Not required to pass review.

| # | Finding | Source |
|---|---|---|
| C1 | `dependency-upgrade-format.bats` and `tech-debt-triage-format.bats` use `#{1,2}` for title headers while all other tests use `^# `. Intentional for skills without existing reports, but should be tightened when reports are generated. | API Consistency |
| C2 | Date field naming varies across skill definitions (`Reviewed`, `Date`, `Checked`, `Evaluated`). Not a test bug but a consistency gap in the skill layer. | API Consistency |
| C3 | `test-strategy-format.bats` checks for `^\*\*[0-9]+\.` (bold numbered items) but the skill definition uses `1. **Bold text**:` patterns. May not match actual output. | Fact-check |
| C4 | Six test files contain similar but not identical leakage check patterns. Consider extracting shared leakage assertion helpers. | Tech-debt-triage |
| C5 | BATS `setup()` re-reads the report file for every `@test`. At current scale (<20 tests, <300 line reports) this is negligible. If suites grow, consider `setup_file()` (BATS 1.5+). | Performance |
| C6 | Unvalidated `REPORT_PATH` environment variable. No realistic attack scenario in local test context. | Security |

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.

| Item | Verdict | Source |
|---|---|---|
| Complete coverage: all 14 skills have corresponding format tests | ✅ Confirmed | Fact-check, API Consistency |
| Graceful skip-when-missing semantics in `load_generic_report` and `load_report` | ✅ Confirmed | Fact-check, Security |
| `CLAIMS_BODY` scoping in `load_report` correctly excludes header metadata | ✅ Confirmed | Fact-check |
| Cross-skill leakage checks are symmetric (Cowen/Yglesias, reviewer/fact-check) | ✅ Confirmed | API Consistency |
| Consistent file structure across all 12 new test files | ✅ Confirmed | API Consistency |
| No security-relevant code (no secrets, no network I/O, no writes) | ✅ Confirmed | Security |
| `tr -d '\r'` normalization prevents cross-platform line ending issues | ✅ Confirmed | Fact-check |
| UUOC fix: `tr -d '\r' < "$REPORT"` instead of `cat "$REPORT" | tr -d '\r'` | ✅ Confirmed | Fact-check (commit 6b46d59) |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
