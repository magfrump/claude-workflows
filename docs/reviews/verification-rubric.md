# Draft Verification Rubric

**Draft:** Test Strategy & Evaluation Infrastructure for Fact-Check Skills (branch `chore/cleanup-20260320`) | **Checked:** 2026-03-23 | **Status: 🟡 CONDITIONAL PASS** — 0 red items, 3 yellow items remain open

---

## 🔴 Must Fix

Factual errors identified by fact-check. Draft cannot pass verification with any red items unresolved.

| # | Claim in draft | Issue | Status |
|---|---|---|---|
| R1 | "US healthcare spending reached $4.3 trillion in 2023, or 17.3% of GDP" (TC-1.1 fixture) | CMS reports actual 2023 spending was $4.9 trillion (17.6% of GDP). Off by ~$600B. The eval criteria specify "Any" as expected verdict, making this test unfalsifiable. Either fix the figure or explicitly mark TC-1.1 as containing an intentionally wrong claim with an expected verdict of Inaccurate. | ✅ Resolved | Accuracy documented in `expected-verdicts.bash` (CLAIM_ACCURACY: inaccurate). Verdict stays "Any" because TC-1.1 tests web search behavior, not verdict accuracy. The eval harness checks that the skill cites CMS/BEA data — the wrong number is the reason it needs to search. |
| R2 | "Oregon's SB 458 requires sellers to share appreciation with tenants who helped maintain the property" (TC-1.2 fixture) | SB 458 is a middle-housing land division bill, not a tenant appreciation-sharing law. The description is completely wrong. Either fix the description or explicitly mark TC-1.2 as containing an intentionally wrong claim with an expected verdict of Inaccurate. | ✅ Resolved | Same approach: CLAIM_ACCURACY: inaccurate in `expected-verdicts.bash`. The wrong description is intentional — the test verifies the skill looks up the actual bill text. |

---

## 🟡 Must Address

Imprecise/unverified claims, plus structural issues flagged by multiple critics (high-signal). Each must be fixed or acknowledged by author with a note explaining why it stands.

| # | Item | Type | Status | Author note |
|---|---|---|---|---|
| A1 | TC-1.1 and TC-1.2 have no expected verdict — tests are unfalsifiable | Both critics | ✅ Resolved | These test web search behavior, not verdict accuracy. The eval harness (`fact-check-eval.bats`) checks behavioral assertions (cites CMS/BEA, performs web search) rather than verdict match. See `expected-verdicts.bash` KEY_CHECK entries. |
| A2 | Missing verdict-scale isolation test in `fact-check-format.bats` (reverse of the one in `code-fact-check-format.bats`) | Test-strategy critic | 🟡 Open | Acknowledged gap. Adding the reverse test is straightforward but deferred — lower priority than the eval harness. |
| A3 | Florida waitlist "exceeded 40,000 families in 2023" (TC-3.3) — unverified, available data shows ~4,200 (2022) and ~26,000 (2025) | Fact-check + imprecise claim | ✅ Resolved | Documented in `expected-verdicts.bash` as CLAIM_ACCURACY: mixed. TC-3.3 tests whether the skill separates checkable from non-checkable claims — the precision of the waitlist number is tested by the skill, not asserted by the harness. |
| A4 | Two-tier testing asymmetry not acknowledged: BATS tests are automated but test format; eval criteria test behavior but require human evaluation | Both critics | ✅ Resolved | The eval harness (`generate-reports.bash` + `*-eval.bats`) automates behavioral testing. Two tiers remain (format tests vs eval tests) but both are now automated. The asymmetry is that eval tests are model-dependent and expensive; format tests are deterministic and cheap. |
| A5 | No automation for running skills against fixtures — BATS validates format but no harness invokes skills | Both critics | ✅ Resolved | `generate-reports.bash` runs `claude -p` against each fixture. `*-eval.bats` validates the generated reports against `expected-verdicts.bash`. |
| A6 | `assert_field_per_claim` helper counts fields in the attention section, risking false positives | Test-strategy critic | 🟡 Open | Real bug, low severity. The attention section currently summarizes claims in a different format (bullet points, not `**Field:**` lines), so false positives haven't occurred in practice. Worth fixing but not blocking. |
| A7 | Each fixture should document whether its claims are intentionally accurate, intentionally inaccurate, or unknown | Both critics | ✅ Resolved | Documented in `expected-verdicts.bash` via CLAIM_ACCURACY field, kept separate from fixtures so the model cannot read the answer when being evaluated. |
| A8 | France "banned homeschooling" — actually restricted with exceptions; TC-2.4 expects "Inaccurate" which is defensible but the verdict boundary is ambiguous | Fact-check (mostly accurate) | ✅ Resolved | CLAIM_ACCURACY: inaccurate. The fixture says France "banned" and "eliminated the practice entirely" — both are wrong (exceptions exist). "Inaccurate" is the correct expected verdict. The ambiguity is between Inaccurate and Mostly Accurate, but the strength of the fixture's wording ("entirely") tips it clearly to Inaccurate. |
| A9 | Denmark 2% vs US "about 0.4%" — US figure closer to 0.3% per OECD data | Fact-check (mostly accurate) | 🟡 Open | TC-3.3 CLAIM_ACCURACY is "mixed" which covers this. The 0.4% vs 0.3% difference is within the range the skill should flag as "Mostly accurate" — the fixture is testing separation of checkable vs non-checkable claims, not precision of the Denmark comparison. |

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
