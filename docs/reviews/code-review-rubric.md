# Code Review Rubric

**Scope:** `feat/r1-workflow-pivot-guidance` vs `main` — 4 workflow files + 1 summary doc | **Reviewed:** 2026-03-24 | **Status: 🟡 CONDITIONAL PASS** — 2 amber item(s) awaiting resolution or justification

---

## 🔴 Must Fix

(None)

---

## 🟡 Must Address

| # | Finding | Domain | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | Redundancy between codebase-onboarding's new "When to pivot" section (lines 13-16) and existing "Relationship to other workflows" section (lines 124-128). Both describe onboarding→RPI and onboarding→DD pivots in slightly different language, creating a maintenance burden and potential for drift. Consolidate or differentiate. | Consistency | Manual review | 🟡 Open | — |
| A2 | DD "When to pivot" says "← From RPI: When RPI research surfaces a design fork, invoke DD inline." RPI step 2 already covers this inline invocation in detail. The pivot section adds artifact-carrying guidance ("Carry the research doc's invariants and constraints into DD's diagnosis step") which is valuable, but the trigger description duplicates step 2. Consider phrasing to avoid restating the trigger and focus purely on the artifact handoff. | Consistency | Manual review | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source |
|---|---|---|
| C1 | The pivot paths are asymmetric across workflows: no onboarding→spike, no DD→onboarding. The summary doc says "4 most common pivot paths" which partially addresses this — consider making the intentional scoping more explicit in the summary. | Manual review |
| C2 | Spike "When to pivot" references "its RPI seed section (see step 4)" — while the cross-reference is correct, could also reference the template field name ("## RPI seed") for quicker scanning. Minor. | Manual review |

---

## ✅ Confirmed Good

| Item | Verdict | Source |
|---|---|---|
| Cross-references to step numbers are accurate (RPI step 2 = Research with DD signals, spike step 4 = Record findings with RPI seed) | ✅ Confirmed | Manual verification |
| DD step 2 = "Diagnose" matches the pivot guidance reference to "DD's diagnosis step" | ✅ Confirmed | Manual verification |
| Arrow notation (→ for outbound, ← for inbound) is used consistently across all 4 files | ✅ Confirmed | Manual verification |
| Artifact-carrying guidance (what to bring forward when pivoting) is present in every pivot path | ✅ Confirmed | Manual verification |
| Placement of "When to pivot" is consistent: after "When to use", before first process section | ✅ Confirmed | Manual verification |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
