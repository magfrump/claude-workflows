# Draft Verification Rubric

**Draft:** Code Review Orchestrator (`skills/code-review.md` + supporting docs) | **Checked:** 2026-03-23 | **Status: 🟡 CONDITIONAL PASS** — 6 amber item(s) awaiting resolution or justification

---

## 🔴 Must Fix

(None — no factual inaccuracies found.)

---

## 🟡 Must Address

| # | Item | Type | Status | Author note |
|---|---|---|---|---|
| A1 | Convergence detection is under-specified — "same file region plus overlapping concern" needs concrete definition (same file? function? line range?) | Both critics | 🟡 Open | — |
| A2 | Contextual critic escalation ambiguity — do advisory critics participate in cross-critic escalation? If yes, they can effectively block merge, contradicting "advisory" status | Cowen critique | 🟡 Open | — |
| A3 | Static classification presented as dynamic discovery — "List all skills/*.md files" implies runtime discovery but provides hardcoded taxonomy | Both critics + Fact-check | 🟡 Open | — |
| A4 | Agent tool vs. Task tool divergence from draft-review not explained — undermines "same pattern" thesis | Both critics + Fact-check | 🟡 Open | — |
| A5 | No decomposition escape valve for large diffs — all contextual critics trigger on big diffs, maximizing agent count when each has the hardest job | Both critics | 🟡 Open | — |
| A6 | "7-9 domain-specific cognitive moves" should be "9" — all three critics have exactly 9 | Imprecise claim (Fact-check) | 🟡 Open | — |

---

## 🟢 Consider

| # | Idea | Source |
|---|---|---|
| C1 | Default to lean pipeline (fact-check + single most relevant critic), with `--full` opt-in for comprehensive review | Yglesias critique |
| C2 | Fact-check-before-critics sequencing may add latency for uncertain benefit — code fact-checking is self-referential, not external-reality-checking | Cowen critique |
| C3 | "Orchestrator must never analyze" constraint prevents the entity with full context from using it analytically during synthesis | Cowen critique |
| C4 | Pipeline doesn't support incremental re-runs (re-run only the critic whose domain was affected by the fix) | Cowen critique |
| C5 | Deliverable 1 heading drops "Freeform" — both baseline orchestrators use "Freeform Chat Synthesis" | Prior rubric (API Consistency) |
| C6 | Performance red-tier mapping (Critical only) differs from Security (Critical+High) — intentional but worth a comment | Fact-check |
| C7 | The elaborate severity mapping and escalation rules may be over-engineered — the core value may simply be "multiple passes with different instructions" | Both critics |

---

## Verified ✅

| Claim | Verdict |
|---|---|
| All 12 skill file references and classifications (orchestrators, fact-checkers, core critics, contextual critics, prose critics) | ✅ Accurate |
| 3-stage pipeline structure matches draft-review's pattern | ✅ Accurate |
| Cross-reference to orchestrated-review pattern | ✅ Accurate |
| Each core critic declares `code-fact-check` as soft dependency via `requires:` | ✅ Accurate |
| Unified severity mapping covers all critic severity levels | ✅ Accurate |
| Escalation rule is logically consistent with tier definitions | ✅ Accurate |
| Two deliverables: chat synthesis + code review rubric | ✅ Accurate |
| Output locations follow conventions | ✅ Accurate |

---

To pass verification: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
