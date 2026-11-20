Commit: 41501b18
# Code Review Rubric

**Scope:** fix/skill-verdict-drift, 697e81ae..41501b18 (the branch's own commits e72a534e, 362fa891, d46065b6, 41501b18) | **Reviewed:** 2026-11-20 | **Status: 🟢 PASSES.** 0 red items; 3 amber items, all fixed.

Two review passes, each by a fresh-context reviewer given the code, not the author's conclusions:
- Pass 1 (whole diff): correctness of the changed EREs and bats checks, fixture validity (the ts6 tables were run against the parser under a pytest shim, 48 cases, 0 failures), skill-text consistency, and the hermetic suites (`bats test/skills/eval-helpers*.bats test/skills/frontmatter-fields.bats`: 54/54; `scripts/hermeticity-lint --root .`: clean).
- Pass 2 (d46065b6, the pass-1 fixes): the new per-finding helper under mawk 1.3.4 and GNU grep 3.8 on 24 saved UV reports, 11 architecture reports and 11 synthetic shapes (### and #### headings, CRLF, sub-headings, trailing text on Informational). No blockers, no should-fix items; three nits, one taken (41501b18).

The design record is docs/working/research-2026-11-20-skill-verdict-drift.md. `scripts/health-check.sh` passes at 958d3837.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|---|
| A1 | **The new Critical clause makes tc-uv4's Major expectation ambiguous.** The clause names Step 2 items 1-2, but uv4 (item 3) plants the same outcome: growing content pushes the Save footer off screen. A run after the clause rated that finding Critical. **Fix:** accept Critical or Major for uv4, with the reason in eval-criteria.md. | Tests | Should-fix | Pass 1 S1 | `test/skills/ui-visual-review/expected-verdicts.bash:33-35` | for-author | Narrowing the clause instead was rejected: uv4's outcome is the one the clause calls Critical. | ✅ Fixed (d46065b6) | Run 11 of uv4 passes. |
| A2 | **The uv6 and uv7 fixture headers still said "Expected finding: Minor"**, and the model reads the fixture, so the stale line steered it toward the old tier. **Fix:** say Major. | Tests | Should-fix | Pass 1 S2 | `test/skills/ui-visual-review/fixtures/tc-uv6-disappearing-controls.tsx:5`, `tc-uv7-weak-affordance.tsx:5` | for-author | — | ✅ Fixed (d46065b6) | Run 11 of both passes. |
| A3 | **The Recommendation check compared counts**, so one Informational finding's Recommendation could stand in for a Major finding's missing one (also true of the architecture-review suite it copied). **Fix:** a per-finding helper, `assert_recommendation_per_tiered_finding` in `test/skills/helpers.bash`, used by both format suites, with hermetic cases in `test/skills/helpers-recommendation.bats`. | Tests | Should-fix | Pass 1 S3 | `test/skills/ui-visual-review-format.bats:107-115`, `test/skills/architecture-review-format.bats:100-110` | for-author | — | ✅ Fixed (d46065b6, 41501b18) | On saved reports it flags exactly the three slips found by hand, all from before the template sentence. |

---

## 🟢 Consider

| # | Finding | Status |
|---|---|---|
| C1 | Bold trigger label `**Label**:` was not accepted (pass 1 N1). | ✅ Fixed (d46065b6) |
| C2 | The skip-note title no longer enforces the em dash (pass 1 N2). Nothing machine-reads the title. | Accepted as is |
| C3 | ts6's length message printed leading zeros (pass 1 N4). | ✅ Fixed (d46065b6) |
| C4 | The c2.5 CLAIM_ACCURACY comment described the old fixture (pass 1 N5). | ✅ Fixed (d46065b6) |
| C5 | c2.5's side comment "vendored wheel" could draw another verdict on that one claim (pass 1 N5). The check passes when any claim is Unverifiable. | Accepted as is |
| C6 | The helper also accepts `**Recommendation**:` (pass 2 nit 1). | ✅ Fixed (41501b18) |
| C7 | `count_findings` drops the last line when findings run to end of file (pass 2 nit 2). Older code; templates always have trailing sections. | Accepted as is |
