# Draft Verification Rubric

**Draft:** Test Strategy & Evaluation Infrastructure for Fact-Check Skills (branch `chore/cleanup-20260320`) | **Checked:** 2026-03-23 | **Status: 🔴 DOES NOT PASS** — 2 red item(s) unresolved

---

## 🔴 Must Fix

Factual errors identified by fact-check. Draft cannot pass verification with any red items unresolved.

| # | Claim in draft | Issue | Status |
|---|---|---|---|
| R1 | "US healthcare spending reached $4.3 trillion in 2023, or 17.3% of GDP" (TC-1.1 fixture) | CMS reports actual 2023 spending was $4.9 trillion (17.6% of GDP). Off by ~$600B. The eval criteria specify "Any" as expected verdict, making this test unfalsifiable. Either fix the figure or explicitly mark TC-1.1 as containing an intentionally wrong claim with an expected verdict of Inaccurate. | 🔴 Unresolved |
| R2 | "Oregon's SB 458 requires sellers to share appreciation with tenants who helped maintain the property" (TC-1.2 fixture) | SB 458 is a middle-housing land division bill, not a tenant appreciation-sharing law. The description is completely wrong. Either fix the description or explicitly mark TC-1.2 as containing an intentionally wrong claim with an expected verdict of Inaccurate. | 🔴 Unresolved |

---

## 🟡 Must Address

Imprecise/unverified claims, plus structural issues flagged by multiple critics (high-signal). Each must be fixed or acknowledged by author with a note explaining why it stands.

| # | Item | Type | Status | Author note |
|---|---|---|---|---|
| A1 | TC-1.1 and TC-1.2 have no expected verdict — tests are unfalsifiable | Both critics | 🟡 Open | — |
| A2 | Missing verdict-scale isolation test in `fact-check-format.bats` (reverse of the one in `code-fact-check-format.bats`) | Test-strategy critic | 🟡 Open | — |
| A3 | Florida waitlist "exceeded 40,000 families in 2023" (TC-3.3) — unverified, available data shows ~4,200 (2022) and ~26,000 (2025) | Fact-check + imprecise claim | 🟡 Open | — |
| A4 | Two-tier testing asymmetry not acknowledged: BATS tests are automated but test format; eval criteria test behavior but require human evaluation | Both critics | 🟡 Open | — |
| A5 | No automation for running skills against fixtures — BATS validates format but no harness invokes skills | Both critics | 🟡 Open | — |
| A6 | `assert_field_per_claim` helper counts fields in the attention section, risking false positives | Test-strategy critic | 🟡 Open | — |
| A7 | Each fixture should document whether its claims are intentionally accurate, intentionally inaccurate, or unknown | Both critics | 🟡 Open | — |
| A8 | France "banned homeschooling" — actually restricted with exceptions; TC-2.4 expects "Inaccurate" which is defensible but the verdict boundary is ambiguous | Fact-check (mostly accurate) | 🟡 Open | — |
| A9 | Denmark 2% vs US "about 0.4%" — US figure closer to 0.3% per OECD data | Fact-check (mostly accurate) | 🟡 Open | — |

---

## 🟢 Consider

Ideas from one critic or tensions between critics. Not required to pass. For the author's consideration only.

| # | Idea | Source |
|---|---|---|
| C1 | All fact-check fixtures are US domestic policy in English; all code fixtures are JS (2 Python). Acknowledge scope limitations. | Cowen critique |
| C2 | No test for the orchestrated case (draft-review feeding fact-check to critics) — interaction effects are untested | Cowen critique |
| C3 | Fixture claims with time-sensitive ground truth (e.g., Austin rents) will go stale — consider documenting a "fixture freshness" review cadence | Cowen critique |
| C4 | TC-C5.1 (thread-safety partial truth) may push the skill toward critique rather than fact-checking, contradicting guardrail tests | Test-strategy critic |
| C5 | TC-C4 bundles 4 sub-tests into one file; separate fixtures per sub-case would make evaluation cleaner | Test-strategy critic |
| C6 | No test for multi-file cross-reference in code-fact-check (all fixtures are single-file) | Test-strategy critic |
| C7 | No test for empty input (draft with zero checkable claims) | Test-strategy critic |
| C8 | No negative format tests (intentionally malformed reports to verify BATS tests catch problems) | Test-strategy critic |
| C9 | Add regression tracking (e.g., `eval-results.json` with dates and pass/fail per TC) | Test-strategy critic |
| C10 | Consider the "standardized patient" limitation: performance on scripted one-claim fixtures doesn't predict performance on real multi-claim drafts | Cowen critique |
| C11 | BATS dependency is undocumented — no `package.json`, `Makefile`, or CI config mentions it | Test-strategy critic |
| C12 | No test verifying web search was actually used (TC-6.2 requirement is aspirational, not enforceable) | Cowen critique |
| C13 | The Sources field uses `Sources?` regex (singular/plural) but the skill prompt doesn't specify — standardize | Test-strategy critic |
| C14 | No test for Summary line arithmetic (verdict counts should add up to total claims) | Test-strategy critic |

---

## Verified ✅

Claims confirmed accurate by the fact-check. No action needed.

| Claim | Verdict |
|---|---|
| "The 2020 US Census counted 331.4 million people" (TC-2.1) | ✅ Accurate |
| "Minnesota legalized recreational cannabis in 2023" (TC-1.3) | ✅ Accurate |
| "The median pay for childcare workers was $13.71 per hour in 2022" (TC-3.3) | ✅ Accurate |
| "The childcare sector employs roughly 1 million workers" (TC-3.3) | ✅ Accurate |
| "The Great Wall of China is the only man-made structure visible from space" — correctly identified as myth (TC-6.3) | ✅ Correctly designed as Inaccurate test case |
| "The minimum wage increase in Seattle reduced hours worked" — correctly designed as Disputed test case (TC-2.3) | ✅ Correctly designed |
| "Nearly 70% of parents spend a fifth of their income on childcare" — correctly designed as conflation test (TC-2.2/4.2) | ✅ Correctly designed |

---

To pass verification: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
