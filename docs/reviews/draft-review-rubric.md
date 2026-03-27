# Draft Verification Rubric

**Draft:** RPI Workflow (Completion Signals) | **Checked:** 2026-03-27 | **Status: 🟡 CONDITIONAL PASS** — 4 amber items

## 🟡 Must Address

| # | Item | Type | Status | Author note |
|---|---|---|---|---|
| A1 | Self-referential completion signals ("you can state the invariants without looking them up again") cannot be reliably self-assessed by LLM agents — consider reformulating as artifact-existence checks | Both critics | 🟡 Open | — |
| A2 | Step 1 (Scope) lacks completion signals, breaking the pattern established by steps 2-6 | Both critics | 🟡 Open | — |
| A3 | Test-first gate content — verify it's preserved after rebase (was flagged as removed in pre-rebase review) | Both critics | 🟡 Resolved (rebase fixed) | — |
| A4 | "Two rounds is typical" presented as empirical finding but is unverified | Fact-check | 🟡 Open | — |

## 🟢 Consider

| # | Idea | Source |
|---|---|---|
| C1 | Clarify which failure mode completion signals primarily address: agents getting stuck vs. agents skipping steps | Cowen critique |
| C2 | Consider descriptive vs. prescriptive framing — prescriptive may be more effective for LLM agents | Yglesias critique |
| C3 | Completion signals that are trivially self-certifiable may be gamed (Definition of Done analogy from Scrum) | Cowen critique |

## ✅ Verified

| Claim | Verdict |
|---|---|
| Lean development principle about cheap-to-discard plans | ✅ Accurate |
| linguist-generated .gitattributes behavior | ✅ Accurate |
| DD's 80% confidence threshold cross-reference | ✅ Accurate |
| Six-step sequential process structure | ✅ Accurate |
