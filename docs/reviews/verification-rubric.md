# Draft Verification Rubric

**Draft:** Foregrounding Tests Decision Record + RPI Workflow Updates | **Checked:** 2026-03-26 | **Status: 🟡 CONDITIONAL PASS** — 1 amber item awaiting resolution or justification

---

## 🔴 Must Fix

Factual errors identified by fact-check. Draft cannot pass verification with any red items unresolved.

*No inaccurate claims found.*

---

## 🟡 Must Address

Imprecise/unverified claims, plus structural issues flagged by multiple critics (high-signal). Each must be fixed or acknowledged by author with a note explaining why it stands.

| # | Item | Type | Status | Author note |
|---|---|---|---|---|
| A1 | "13 approaches were generated via divergent design" — only 6 listed, no artifact preserves the rest. | Unverified claim | ✅ Resolved — softened to "over a dozen approaches" | — |
| A2 | "Combine approaches 1 + 4 + 5" — the "Concretely" section lists 4 elements, not 3. | Imprecise claim | ✅ Resolved — updated to "1 + 4 + 5, plus diagnostic guidance as a cross-cutting concern" | — |
| A3 | "Tests are the most precise, executable form of requirements" overstates what the mechanism delivers. Both critics independently note the human writes prose, not executable specs. | Both critics | ✅ Resolved — reframed as "among the most precise forms of behavioral specification" with explicit acknowledgment that prose-to-code translation carries ambiguity risk | — |
| A4 | Diagnostic expectations are under-emphasized relative to their importance. Both critics identify this as the most valuable contribution. | Both critics | ✅ Resolved — elevated diagnostic expectations in RPI to "the highest-value part of test specification" with expanded emphasis | — |
| A5 | Test review gate effectiveness depends on human code fluency — an unmitigated assumption. Both critics note this. | Both critics | 🟡 Open | Mitigated: added prose summary step to the test-review gate — LLM produces a bulleted list of what each test verifies alongside the code, so the human can review in plain language. This lowers the code-fluency requirement without removing it entirely. Full mitigation would require a separate "test specification review" in prose, which adds a round-trip the workflow is designed to avoid. |

---

## 🟢 Consider

Ideas from one critic or tensions between critics. Not required to pass. For the author's consideration only.

| # | Idea | Source |
|---|---|---|
| C1 | Simplify the default table to 2 required columns (test case + expected behavior). Make test level and diagnostic expectations recommended but optional. | Yglesias |
| C2 | ~~Add a prose summary step to the test-review gate.~~ Addressed: added to the RPI workflow. | Yglesias |
| C3 | Move taxonomy and diagnostic guidance to an appendix or reference section. Keep the main workflow lean. | Yglesias |
| C4 | ~~"The central use case is code development in other repos" — disputed.~~ Addressed: softened to "the motivating use case" with acknowledgment that implementation is general-purpose. | Fact-check + both critics |
| C5 | The decision does not engage with TDD's decades-long adoption struggles or why mainstream LLM tools have not converged on test-first patterns. | Cowen |
| C6 | Building codes vs. blueprints analogy: most test cases are constraints, not specifications. The gap between constraints and specs is where mismatches hide. | Cowen |
| C7 | RPI is approaching process-manual complexity. Consider splitting into core loop + supplementary guides. | Yglesias |
| C8 | The test review gate has an escape hatch the plan gate does not, revealing tests are still procedurally subordinate to the plan. | Cowen |
| C9 | Predicted adoption: test spec adopted abbreviated; review gate adopted by burned users; taxonomy mostly ignored; diagnostic expectations = sleeper hit. | Yglesias |

---

## Verified ✅

Claims confirmed accurate by the fact-check. No action needed.

| Claim | Verdict |
|---|---|
| "RPI workflow mentions 'testing strategy' as a one-line plan section" | ✅ Accurate |
| "'characterization tests first' in the refactoring variant" | ✅ Accurate |
| "neither gives tests a primary role in the human-LLM collaboration loop" | ✅ Accurate |
| "6 survivors are summarized here" | ✅ Accurate |
| "characterization tests first in the refactoring variant, but neither gives tests a primary role" | ✅ Accurate |

---

To pass verification: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
