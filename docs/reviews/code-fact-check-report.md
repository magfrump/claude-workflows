# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** Branch `feat/r1-skill-output-schema-validation` vs `main`
**Checked:** 2026-03-24
**Total claims checked:** 8
**Summary:** 5 verified, 1 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

---

## Claim 1: "Shared helpers for skill output BATS tests"

**Location:** `test/skills/helpers.bash:1`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The file provides shared helper functions (`load_report`, `load_generic_report`, `count_findings`, `assert_field_per_finding`, `assert_section_exists`, `assert_heading_exists`, `assert_field_per_claim`, `assert_field_values`, `assert_claims_sequential`) used across all 14 skill format test files. Every test file loads this via `load helpers`.

**Evidence:** `test/skills/helpers.bash:1-107`, all `*-format.bats` files

---

## Claim 2: "Counts only within FINDINGS_BODY (set by count_findings) to avoid false matches from report-level metadata sharing the same field name"

**Location:** `test/skills/helpers.bash:56-57`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

`assert_field_per_finding` does search within `FINDINGS_BODY` rather than `REPORT_CONTENT`, which is the claimed scoping behavior. However, `FINDINGS_BODY` is extracted via `sed -nE '/^#{3,4} [0-9]+\./,$p'` which captures from the first finding heading to **end of file**, not to the end of the Findings section. This means the Summary Table and Overall Assessment sections (which appear after findings) are included in `FINDINGS_BODY`. If those trailing sections contain `**Severity:**` or similar field names, they would be counted. The scoping is directionally correct (excludes report header/preamble) but not as tight as the comment implies.

**Evidence:** `test/skills/helpers.bash:50-63`

---

## Claim 3: "Counts only within CLAIMS_BODY (set by load_report) to avoid false matches from report-level metadata sharing the same field name"

**Location:** `test/skills/helpers.bash:78-79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`CLAIMS_BODY` is extracted with a tighter scope: `sed -n '/^## Claim [0-9]/,/^## [^C]/p' | sed '$d'` which captures from the first Claim heading to the first non-Claim `##` heading. The fallback captures from the first Claim to EOF. The `assert_field_per_claim` function then operates on `CLAIMS_BODY` instead of `REPORT_CONTENT`. This correctly scopes field counting to the claims section.

**Evidence:** `test/skills/helpers.bash:22-29, 80-85`

---

## Claim 4: "Impact" field in performance-reviewer tests

**Location:** `test/skills/performance-reviewer-format.bats:44-49`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

The test file checks for `**Impact:**` as a per-finding field and validates its values against `Critical|High|Medium|Low|Informational`. However, the performance-reviewer skill definition (`skills/performance-reviewer.md:202`) specifies the field name as `**Severity:**`, not `**Impact:**`. The test will fail on any report that follows the skill's documented output format, or it will skip if no `Impact` fields are found (via `assert_field_values`'s skip behavior).

**Evidence:** `skills/performance-reviewer.md:202`, `test/skills/performance-reviewer-format.bats:44-49`

---

## Claim 5: "report contains numbered items in at least one section" (test-strategy)

**Location:** `test/skills/test-strategy-format.bats:45-46`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium

The test checks for `^\*\*[0-9]+\.` which matches lines starting with `**N.` (bold numbered items). The test-strategy skill definition uses patterns like `1. **High value**:` (numbered list with bold description), not `**1. Description**` (bold number prefix). Whether the actual LLM output uses the `**N.` format depends on the model's interpretation of the skill prompt. No existing test-strategy report was found to verify against.

**Evidence:** `skills/test-strategy.md:98-102`, `test/skills/test-strategy-format.bats:45-46`

---

## Claim 6: "No example report exists yet" (dependency-upgrade, tech-debt-triage)

**Location:** `test/skills/dependency-upgrade-format.bats:4`, `test/skills/tech-debt-triage-format.bats:4`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High

Both files correctly note that no example reports exist. The `load_generic_report` skip logic will cause all tests in these files to skip with an informative message when no report is present at the default path.

**Evidence:** `test/skills/dependency-upgrade-format.bats:12`, `test/skills/tech-debt-triage-format.bats:11`

---

## Claim 7: "To generate all reports, see test/skills/generate-reports.bash"

**Location:** `test/skills/helpers.bash:8`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `test/skills/generate-reports.bash` exists in the working tree (visible in git status as a modified file).

**Evidence:** `test/skills/helpers.bash:8`, git status output

---

## Claim 8: "Extract only the claims sections (from first claim to the summary/attention section)"

**Location:** `test/skills/helpers.bash:22-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The `sed` command `/^## Claim [0-9]/,/^## [^C]/p` captures from the first `## Claim N` heading to the first `## ` heading that does not start with `C` (i.e., `## Claims Requiring Attention`). The `sed '$d'` removes the terminal non-Claim heading. The fallback handles the case where claims run to EOF. This correctly scopes the extraction.

**Evidence:** `test/skills/helpers.bash:25-29`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`test/skills/performance-reviewer-format.bats:44-49`): Test checks for `**Impact:**` but the skill definition specifies `**Severity:**`. Tests will fail or skip on conformant reports.

### Mostly Accurate
- **Claim 2** (`test/skills/helpers.bash:56-57`): `FINDINGS_BODY` scoping excludes header but includes Summary Table and Overall Assessment sections after findings. Not as tight as documented.

### Unverifiable
- **Claim 5** (`test/skills/test-strategy-format.bats:45-46`): Bold-number pattern `**N.` may not match actual LLM output format. No existing report to verify against.
