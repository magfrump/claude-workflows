---
Last verified: 2026-03-24
Relevant paths:
  - skills/fact-check.md
  - skills/draft-review.md
  - test/skills/fact-check-format.bats
  - test/skills/fact-check-eval.bats
---

# Self-Evaluation: fact-check

**Target:** `skills/fact-check.md` | **Type:** Skill | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Strong | Produces structured output with mechanically checkable properties (verdict per claim, confidence level, source citations). Test inputs with planted factual errors and known correct verdicts are straightforward to construct. |
| Trigger clarity | Strong | "Fact-check this" is unambiguous. The description lists concrete trigger phrases ("verify the numbers", "check the claims", "source-check"). No confusing overlap — code-fact-check is clearly scoped to code comments, critic skills evaluate arguments not facts. |
| Overlap and redundancy | Strong | No other skill performs systematic claim verification against external evidence for prose drafts. code-fact-check covers code comments. Critic skills (cowen-critique, yglesias-critique) evaluate argument structure, not factual accuracy. Unique niche. |
| Test coverage | Adequate | Format tests (`test/skills/fact-check-format.bats`) and eval tests (`test/skills/fact-check-eval.bats`) exist. A real-world output artifact exists at `docs/reviews/fact-check-report.md` from a draft-review pipeline run. Both test and usage evidence present, though eval tests could be deeper. |
| Pipeline readiness | Strong | Standalone viable with clear output path (`docs/reviews/fact-check-report.md`). Also a functioning pipeline stage: draft-review orchestrates it as Stage 1. Both cowen-critique and yglesias-critique declare it in their `requires` block. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the tool does:** Systematically extracts every checkable claim from a prose draft (numbers, named policies, attributed facts, causal claims, comparisons), searches for evidence via web search, and produces structured verdicts (Accurate / Mostly accurate / Disputed / Inaccurate / Unverified) with calibrated confidence and source citations. Includes an actionable "Claims Requiring Author Attention" checklist.

**What generic prompting achieves:** Asking Claude to "fact-check this draft" without the skill would produce a less systematic pass — checking salient claims but missing less obvious ones, inconsistent verdict taxonomy, vague or missing source citations, no confidence calibration, and no structured output. The skill's additions: (1) explicit claim-type taxonomy for comprehensive extraction, (2) five-level verdict scale with defined semantics, (3) mandatory web search per claim, (4) actionable checklist output, (5) guardrails against skipping claims or drifting into critique.

**What built-in tools cover:** No built-in Claude Code capability performs structured fact-checking of prose. The verification-coordinator is code-focused.

**Questions for the reviewer:**
- How much value comes from structured consistency (every claim gets the same treatment) vs. the specific analytical instructions (claim-type taxonomy, ambiguity-handling)?
- When you've used fact-check output, was the most value in the verdicts, the source citations, or the actionable checklist?
- Under what conditions is the gap largest — short drafts with a few key claims, or long drafts where systematic extraction prevents missed claims?

### User-Specific Fit

**Triggering situations:**
- Writing a blog post, essay, or policy piece and wanting factual claims verified before publication
- Running draft-review, which always invokes fact-check as Stage 1
- Verifying specific numbers or statistics in a draft without running a full review

**Questions for the reviewer:**
- How often do you write prose drafts with checkable factual claims?
- Is this frequency increasing or decreasing?
- Do you reach for fact-check standalone or primarily through draft-review?
- Would you remember to fact-check independently, or does the pipeline handle that trigger?

### Condition for Value

**Stated or inferred conditions:**
1. The user writes prose drafts containing factual claims.
2. For pipeline value: the draft-review orchestrator exists and is functional.
3. Web search must be available at runtime.

**Automated findings:**
- draft-review orchestrator: EXISTS at `skills/draft-review.md`, references fact-check as Stage 1.
- Both critic skills declare fact-check in `requires`: EXISTS.
- Example output artifact: EXISTS at `docs/reviews/fact-check-report.md`.
- Test files: EXIST (`test/skills/fact-check-format.bats`, `test/skills/fact-check-eval.bats`).

**Questions for the reviewer:**
- Are all three conditions met today?
- Is the frequency of draft-writing stable, increasing, or decreasing?
- Does the skill pull you toward more carefully sourced drafts, or is it purely a verification step?

### Failure Mode Gracefulness

**Output structure:** Each claim is presented as a quoted excerpt alongside verdict, confidence, evidence summary, and sources. Side-by-side format makes wrong verdicts detectable.

**Potential silent failures:**
1. **False "Accurate" verdicts** — confirms a claim based on a wrong or non-supporting source.
2. **Missed claims** — fails to extract a checkable claim; reader sees only checked claims.
3. **Stale web results** — marks a claim Accurate based on outdated information.
4. **"Unverified" overuse** — uses Unverified as an escape hatch for claims it should have checked.

**Pipeline mitigations:** draft-review passes results to critics who may incidentally catch missed factual issues. The fact-check gate pauses the pipeline on high-confidence Inaccurate findings.

**Questions for the reviewer:**
- Did you spot any wrong verdicts or missed claims in `docs/reviews/fact-check-report.md`?
- Is "Unverified" being used appropriately or as a catch-all?
- Which failure mode concerns you most for your domain?

---

## Key Questions

1. **Missed-claim detection is the main structural blind spot.** The skill checks claims it finds but has no completeness mechanism. Would a "claims considered but not checked" section add meaningful safety?

2. **Test coverage is present but could deepen.** Format and eval tests exist alongside a real-world output artifact. What specific test scenarios would most increase confidence — edge cases in verdict assignment, or completeness of claim extraction?

3. **Standalone vs. pipeline balance.** The skill works well both ways. In practice, which mode delivers more value — and does the answer affect how the skill should evolve?
