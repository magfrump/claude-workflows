# Code Review Rubric

**Scope:** feat/r1-retrospective-appendix vs main | **Reviewed:** 2026-03-27 | **Status: 🟡 CONDITIONAL PASS** — 0 red items, 1 amber item

## 🟡 Must Address

| # | Finding | Domain | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | `guides/post-pr-retrospective.md` will be orphaned after merge — no references point to it. Either delete it, keep the cross-reference, or add a "see also" link | API Consistency | Fact-check + API consistency reviewer | 🟡 Open | — |

## 🟢 Consider

| # | Finding | Source |
|---|---|---|
| C1 | Content loss from guide reversal: the guide had timing checkpoints (after opening, after feedback, after merge) and per-question artifact references not carried into inline version | API consistency reviewer |
| C2 | Summary doc could more accurately describe the change as reversing an extraction, not just renaming a heading | Fact-check |

## ✅ Confirmed Good

| Item | Verdict | Source |
|---|---|---|
| "Retrospective" heading is cleaner and consistent with other short headings | ✅ Confirmed | All reviewers |
| "Surprises" replaces "Time vs. estimate" — broader and more useful prompt | ✅ Confirmed | All reviewers |
| Question wording is tighter and more actionable | ✅ Confirmed | All reviewers |
