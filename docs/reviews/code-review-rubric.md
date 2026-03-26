# Code Review Rubric

**Scope:** feat/foreground-tests vs main | **Reviewed:** 2026-03-26 | **Status: ✅ PASSES REVIEW**

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items unresolved.

| # | Finding | Domain | Location | Status |
|---|---|---|---|---|
| — | No red items | — | — | — |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they stand. Each must carry a resolution or author note.

| # | Finding | Domain | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | `skills/test-strategy.md` frontmatter still says "testing strategy" while RPI section renamed to "test specification" | Consistency | Fact-check + API Consistency (escalated from 🟢) | ✅ Fixed | Changed "testing strategy" → "test specification" in frontmatter |
| A2 | Stale line-number references in security-review.md, cowen-critique.md, yglesias-critique.md (off by 2-4 lines after C2/C3 fixes) | Accuracy | Fact-check + API Consistency (escalated from 🟢) | ✅ Fixed | Review artifacts regenerated with correct line numbers |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement opportunities. Not required to pass review.

| # | Finding | Source |
|---|---|---|
| C1 | Add cross-reference consistency BATS test to catch stale terminology between files | Test Strategy |
| C2 | Prior branch review artifacts were overwritten — unresolved findings (Impact/Severity bug, FINDINGS_BODY scoping) only in git history | Tech Debt |
| C3 | Review artifact freshness metadata stripped — clarify whether reviews need freshness tracking | Tech Debt |
| C4 | RPI at 202 lines, approaching density ceiling — monitor for ~300 lines | Performance + Tech Debt |
| C5 | Decision log gap (entries 2-5 have records but no log entries) — cosmetic | API Consistency |
| C6 | Soft gate terminology: "Test-first gate" heading implies hard enforcement but mechanism is soft | Security |
| C7 | Diagnostic output PII caveat exists but downstream projects may not read it | Security |

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.

| Item | Verdict | Source |
|---|---|---|
| Hard gate at step 4 (plan approval) preserved and unweakened | ✅ Confirmed | Security + Fact-check |
| Checkpoint naming follows established "essential/recommended/optional" pattern | ✅ Confirmed | API Consistency |
| Cross-references to test-strategy skill, divergent-design, doc-freshness all resolve | ✅ Confirmed | Fact-check |
| Inline taxonomy levels are subset of test-strategy skill's full taxonomy | ✅ Confirmed | Fact-check |
| Non-blocking test review checkpoint avoids pipeline stalls | ✅ Confirmed | Performance |
| PII/secrets caveat added for diagnostic output | ✅ Confirmed | Security + Fact-check |
| `linguist-generated` gitattribute behavior accurately described | ✅ Confirmed | Fact-check |
| DD 80% confidence threshold correctly referenced | ✅ Confirmed | Fact-check |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
