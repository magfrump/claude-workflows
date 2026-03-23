# Code Review Rubric

**Scope:** Working tree changes (skills/code-review.md, patterns/orchestrated-review.md, docs/decisions/002-critic-style-code-review.md) | **Reviewed:** 2026-03-23 | **Status: ✅ PASSES REVIEW**

---

## 🔴 Must Fix

(None)

---

## 🟡 Must Address

(None)

---

## 🟢 Consider

| # | Finding | Source |
|---|---|---|
| C1 | Deliverable 1 heading drops "Freeform" — both baseline orchestrators use "Freeform Chat Synthesis" | API Consistency |
| C2 | "Before You Begin" section heading is a hybrid of draft-review and matrix-analysis styles | API Consistency |
| C3 | Decision doc says "7-9 cognitive moves" but all three critics have exactly 9 | Fact-Check |
| C4 | "Agent tool" vs "Task tool" divergence from draft-review.md not noted in decision doc | Fact-Check + API Consistency (convergent) |
| C5 | Performance red-tier mapping (Critical only) differs from Security (Critical+High) — intentional but worth a comment in the skill | Fact-Check |

---

## ✅ Confirmed Good

| Item | Verdict | Source |
|---|---|---|
| All 12 skill file references (paths and classifications) | ✅ Confirmed | Fact-Check |
| Unified severity mapping covers all critic severity levels | ✅ Confirmed | Fact-Check |
| Escalation rule is logically consistent with tier definitions | ✅ Confirmed | Fact-Check |
| Cross-reference to orchestrated-review pattern | ✅ Confirmed | API Consistency |
| Mandatory execution rules follow established format | ✅ Confirmed | API Consistency |
| Output locations section follows conventions | ✅ Confirmed | API Consistency |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
