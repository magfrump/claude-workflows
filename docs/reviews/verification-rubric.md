# Draft Verification Rubric

**Draft:** Foregrounding Tests Decision Record + RPI Workflow Updates | **Checked:** 2026-03-26 | **Status: 🟡 CONDITIONAL PASS** — 3 amber items awaiting resolution or justification

---

## 🔴 Must Fix

Factual errors identified by fact-check. Draft cannot pass verification with any red items unresolved.

| # | Claim in draft | Issue | Status |
|---|---|---|---|
| — | No red items | — | — |

---

## 🟡 Must Address

Imprecise/unverified claims, plus structural issues flagged by multiple critics (high-signal). Each must be fixed or acknowledged by author with a note explaining why it stands.

| # | Item | Type | Status | Author note |
|---|---|---|---|---|
| A1 | "Over a dozen approaches were generated via divergent design" — no DD artifact preserved to verify | Unverified claim (fact-check) | 🟡 Open | — |
| A2 | Both critics: four-column test specification table risks becoming compliance form that gets skipped (same TDD adoption problem); "simple features can be brief" escape hatch becomes universal default | Both critics | 🟡 Open | — |
| A3 | Both critics: workflow assumes humans design tests, LLMs implement — but common LLM pattern is LLM proposes, human reviews; position is undefended | Both critics | 🟡 Open | — |

---

## 🟢 Consider

Ideas from one critic or tensions between critics. Not required to pass. For the author's consideration only.

| # | Idea | Source |
|---|---|---|
| C1 | Diagnostic expectations guidance is the most novel contribution but gets less structural emphasis than the test table — consider inverting the emphasis | Both critics (convergent) |
| C2 | Separate implementation instruction (write tests first, commit separately) from planning artifact (the table) — make former default, latter optional for complex features | Yglesias |
| C3 | The "tests as human-LLM interface" framing does rhetorical work beyond what the concrete changes require — the boring explanation covers ~90% | Cowen |
| C4 | Revealed-preference tension: emphasis on diagnostic output reveals "tests as debugging tools" matters more than "tests as specification" — consider leaning into this | Cowen |
| C5 | Three human review checkpoints before feature code is a lot of gates | Yglesias |
| C6 | "Full taxonomy" reference to test-strategy skill slightly overstates formality | Fact-check |

---

## Verified ✅

Claims confirmed accurate by the fact-check. No action needed.

| Claim | Verdict |
|---|---|
| "RPI workflow mentions 'testing strategy' as a one-line plan section" (pre-change) | ✅ Accurate (verified against git history) |
| "characterization tests first" appears in refactoring variant | ✅ Accurate |
| `linguist-generated` gitattribute behavior correctly described | ✅ Accurate |
| DD 80% confidence threshold reference matches source | ✅ Accurate |
| All internal file references resolve correctly | ✅ Accurate |
| Decision record structure follows established convention | ✅ Accurate |
| Inline taxonomy levels are subset of test-strategy skill's taxonomy | ✅ Accurate |

---

To pass verification: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
