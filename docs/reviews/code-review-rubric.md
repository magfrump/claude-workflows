# Code Review Rubric

**Scope:** feat/r1-workflow-onboarding-tiers vs main | **Reviewed:** 2026-03-27 | **Status: 🟡 CONDITIONAL PASS** — 0 red, 2 amber (post-rebase update: content regression resolved)

Note: Pre-rebase review flagged content regressions (test-first gate removal, test spec table removal). These were branching artifacts resolved by the rebase onto current main. The amber items below are the remaining findings.

## 🟡 Must Address

| # | Finding | Domain | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | Step 4 (Annotate) labeled "(recommended)" but body says "the hard gate" / "required, not optional" — mixed signal for new users | API Consistency | Code review + self-eval | 🟡 Open | — |
| A2 | 5 of 9 workflow files lack tier annotations — creates inconsistent heading format across the collection | API Consistency | Code review | 🟡 Open | — |

## 🟢 Consider

| # | Finding | Source |
|---|---|---|
| C1 | Legend text duplicated across 4 files; future tier definition changes require 4 edits | API consistency reviewer |
| C2 | RPI legend includes "(advanced)" but no RPI step uses this tier | Fact-check |
| C3 | Spike step 5 reclassified from (advanced) to (recommended) — reasonable but not mentioned in commit message | Draft review |

## ✅ Confirmed Good

| Item | Verdict | Source |
|---|---|---|
| Three-tier system is simple, memorable, and scannable | ✅ Confirmed | All reviewers |
| Legend line consistent across all 4 files | ✅ Confirmed | Fact-check, API consistency |
| Annotations are additive, not destructive | ✅ Confirmed | All reviewers |
| Cross-workflow consistency in heading format | ✅ Confirmed | All reviewers |
