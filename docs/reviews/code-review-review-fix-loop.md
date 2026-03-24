# Code Review Rubric

**Scope:** `feat/review-fix-loop-workflow` vs `main` (1 file, 115 lines added) | **Reviewed:** 2026-03-24 | **Status: ✅ PASSES REVIEW**

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items unresolved.

| # | Finding | Domain | Location | Status |
|---|---|---|---|---|
| (none) | No must-fix items | -- | -- | -- |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they stand. Each must carry a resolution or author note.

| # | Finding | Domain | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | RPI characterization ("gets you to working") oversimplifies -- RPI includes human review, not just "get to working" | Fact-check | Code fact-check (Claim 7, mostly accurate, medium confidence) | 🟡 Open | -- |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement opportunities. Not required to pass review.

| # | Finding | Source |
|---|---|---|
| C1 | "2-3 loops" convergence claim is unverifiable from repository data; consider qualifying with "in our experience" or similar | Code fact-check |
| C2 | Consider adding a note that review skills invoked in Step 1 follow the orchestrated review pattern | API consistency |
| C3 | "Artifacts" section name differs from RPI's "Working documents" -- defensible but worth noting | API consistency |

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.

| Item | Verdict | Source |
|---|---|---|
| Skills referenced (code-review, self-eval, fact-check) all exist and work as described | ✅ Confirmed | Code fact-check |
| BATS test command and glob pattern are correct | ✅ Confirmed | Code fact-check |
| Review artifacts output to `docs/reviews/` as claimed | ✅ Confirmed | Code fact-check |
| Workflow structure follows established conventions (When to use, Process, numbered steps) | ✅ Confirmed | API consistency |
| Tier table mirrors code-review rubric tiers | ✅ Confirmed | API consistency |
| Conventional commit example follows project conventions | ✅ Confirmed | API consistency |
| No security surface in document | ✅ Confirmed | Security reviewer |
| No performance surface in document | ✅ Confirmed | Performance reviewer |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
