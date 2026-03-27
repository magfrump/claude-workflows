# Draft Verification Rubric

**Draft:** Bug Diagnosis Workflow | **Checked:** 2026-03-27 | **Status: 🟡 CONDITIONAL PASS** — 0 red, 4 amber items

## 🟡 Must Address

| # | Item | Type | Status | Author note |
|---|---|---|---|---|
| A1 | Draft claims to be "optimized for speed" but mechanism optimizes for structured traceability (documentation log, characterization tests, verification steps) | Both critics | 🟡 Open | — |
| A2 | Pivot guidance is fragmented: "When to pivot" section at top and escape hatch in step 4 say the same thing differently | Both critics | 🟡 Open | — |
| A3 | Workflow doesn't address its actual practitioner (LLM agent) — LLMs have specific debugging failure modes (context degradation, premature fixing) that the structure implicitly counters but doesn't acknowledge | Both critics | 🟡 Open | — |
| A4 | "collapsed in GitHub diffs via linguist-generated" — collapsing is specific to GitHub PR web UI, not all diffs | Fact-check (imprecise claim) | 🟡 Open | — |

## 🟢 Consider

| # | Idea | Source |
|---|---|---|
| C1 | Add hypothesis ordering guidance (test most likely first, or cheapest to rule out) — parallel to medical differential diagnosis | Cowen critique |
| C2 | Elevate "read the error" in step 2 to a sub-heading or call-out — it often resolves bugs by itself | Yglesias critique |
| C3 | The "3 hypotheses" threshold is arbitrary; consider a signal-based trigger (hypotheses getting vaguer) | Cowen critique |
| C4 | Acknowledge multi-causal / interaction bugs in the escape hatch guidance | Yglesias critique |
| C5 | Clarify that retroactive diagnosis-log filling is acceptable | Yglesias critique |
| C6 | The isolation step (step 2) is underweighted relative to its actual importance in practice | Cowen critique |

## ✅ Verified

| Claim | Verdict |
|---|---|
| Git bisect syntax (start, bad, good, run, reset) | ✅ Accurate |
| RPI produces separate research and plan docs | ✅ Accurate |
| RPI has a plan approval gate | ✅ Accurate |
| Git bisect is "the single most powerful isolation technique for regressions" | ✅ Accurate |
