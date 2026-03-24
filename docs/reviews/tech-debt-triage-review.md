# Tech Debt Triage: Skill Output Schema Validation Test Suite

**Location:** `test/skills/*.bats`, `test/skills/helpers.bash`
**Nature:** Testing infrastructure, structural validation

## Carrying Cost: Low

The test suite is new and well-structured. The primary carrying costs are:

- **FINDINGS_BODY over-inclusion:** The `count_findings` extraction captures from the first finding to EOF, including Summary Table and Overall Assessment sections. This could produce false matches if those sections contain field-like patterns. The cost of carrying this is low -- it would only manifest when a report's trailing sections use `**Severity:**` or similar patterns, which is unlikely in practice.

- **Impact/Severity mismatch:** The performance-reviewer test uses `Impact` instead of `Severity`. This is an active bug that will cause test failures when the test is run against a conformant report. Low carrying cost because the test currently skips (no report exists), but becomes a blocker when the report is generated.

- **Duplicated leakage check patterns:** Six test files contain similar but not identical "no leakage" assertions. Each checks for absence of cross-skill language using inline grep patterns. This is minor duplication -- each file tests different leakage targets so the patterns are not identical, but the structure is repetitive.

## Fix Cost
- **Scope:** Localized -- all changes are within `test/skills/`
- **Effort:** Hours -- each issue is a small targeted fix
- **Risk:** Low -- test-only changes with no production impact
- **Incremental?** Yes -- each fix is independent

## Urgency Triggers
- The Impact/Severity mismatch will become a blocker when someone generates a performance review report and runs the tests.
- If more skills are added, the duplicated leakage patterns will need updating in multiple places.

## Recommendation: Fix opportunistically

The carrying cost is low. The Impact/Severity fix should be done before the branch merges (it's a bug, not tech debt). The FINDINGS_BODY scoping and leakage pattern deduplication can be addressed when someone is already working in this area. No urgency trigger is imminent.
