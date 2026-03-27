# Draft Verification Rubric

**Draft:** RPI Workflow Tier Annotations | **Checked:** 2026-03-27 | **Status: 🟡 CONDITIONAL PASS** — post-rebase update

Note: The pre-rebase review rated this DOES NOT PASS due to undisclosed content removals (test-first gate, test spec table, spike freshness section). These were branching artifacts — the branch was created before those sections were added to main. After rebasing onto current main, all content is preserved. The remaining findings below are substantive.

## 🟡 Must Address

| # | Item | Type | Status | Author note |
|---|---|---|---|---|
| A1 | Step 4 "Annotate" labeled (recommended) but body text says "hard gate" — tier label contradicts enforcement language | Both critics + code review | 🟡 Open | — |

## 🟢 Consider

| # | Idea | Source |
|---|---|---|
| C1 | Per-workflow note when the legend mentions tiers not used in that workflow | Fact-check |
| C2 | Whether per-heading tier labels earn their visual weight vs. a lighter alternative like a summary table | Self-eval |
| C3 | Spike cleanup reclassification from (advanced) to (recommended) is reasonable but should be noted | Code review |

## ✅ Verified

| Claim | Verdict |
|---|---|
| Cross-references to guides/doc-freshness.md, templates/gitattributes-snippet.txt resolve correctly | ✅ Accurate |
| Heading format consistent across all four workflows | ✅ Accurate |
| Tier assignments consistent with RPI's own skip guidance | ✅ Accurate |
