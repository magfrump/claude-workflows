# Self-Evaluation: fact-check

**Target:** `skills/fact-check.md` | **Type:** Skill | **Evaluated:** 2026-03-23
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Strong | Produces structured output with mechanically checkable properties (verdict per claim, confidence level, source citations). Test inputs with planted factual errors and known correct verdicts are straightforward to construct. |
| Trigger clarity | Strong | "Fact-check this" is unambiguous and specific. The description lists concrete trigger phrases ("verify the numbers", "check the claims", "source-check"). No confusing overlap with other skills — code-fact-check is clearly scoped to code, and critic skills are clearly scoped to argumentation, not factual verification. |
| Overlap and redundancy | Strong | No other skill in the repo performs systematic claim verification against external evidence for prose drafts. code-fact-check covers code comments, not prose. The critic skills (cowen-critique, yglesias-critique) evaluate arguments, not factual accuracy. The skill occupies a unique and well-defined niche. |
| Test coverage | Adequate | No automated tests exist on the current branch, but test fixtures and BATS format tests were written (commit f88d69f on chore/cleanup-20260320 — 13 draft fixtures, 14 format tests). A real-world output artifact exists at `docs/reviews/fact-check-report.md` from a draft-review orchestrator run (18 claims checked). Tests are not yet merged to main. |
| Pipeline readiness | Strong | Standalone viable with clear instructions for direct invocation (saves to `docs/reviews/fact-check-report.md`). Also a functioning pipeline stage: draft-review orchestrates it as Stage 1 before critics. Both critic skills (cowen-critique, yglesias-critique) declare it in their `requires` block. The code-review orchestrator explicitly excludes it (correctly — code-fact-check serves that role). |

---

## Flagged for Human Review

### Counterfactual Gap

**What the tool does:** Systematically extracts every checkable claim from a prose draft (numbers, named policies, attributed facts, causal claims, comparisons, anecdotes), searches for evidence using web search, and produces a structured verdict (Accurate / Mostly accurate / Disputed / Inaccurate / Unverified) with calibrated confidence and source citations. The output is ordered by appearance in the draft, with an actionable summary of claims requiring attention.

**What generic prompting achieves:** Asking Claude to "fact-check this draft" without the skill file would likely produce: a less systematic pass (checking salient claims but missing less obvious ones), inconsistent verdicts (no fixed taxonomy), missing or vague source citations, no confidence calibration, and no structured output format. The skill's main additions over generic prompting are: (1) the explicit claim-type taxonomy ensuring comprehensive extraction, (2) the five-level verdict scale with defined semantics, (3) mandatory web search for every claim rather than relying on training data, (4) the "Claims Requiring Author Attention" actionable checklist, and (5) explicit guardrails against skipping "obvious" claims or adding critique.

**What built-in tools cover:** No built-in Claude Code capability performs structured fact-checking of prose drafts. The built-in verification-coordinator is focused on code verification, not prose claims.

**Questions for the reviewer:**
- How much of the skill's value comes from the structured output format and consistency (ensuring every claim gets the same treatment) vs. the specific analytical instructions (the claim-type taxonomy, the ambiguity-handling rules)?
- When you've used fact-check output, did you find the most value in the verdicts themselves, or in the source citations and evidence summaries?
- Under what conditions is the gap largest — short drafts with a few key claims, or long drafts where systematic extraction prevents claims from being missed?

### User-Specific Fit

**Triggering situations:**
- User writes a blog post, essay, or policy piece and wants factual claims verified before publication
- User runs the draft-review orchestrator, which always invokes fact-check as Stage 1
- User wants to verify specific numbers or statistics in a draft without running a full review

**Questions for the reviewer:**
- How often do you write prose drafts with checkable factual claims (statistics, policy references, attributed facts)?
- Is this frequency increasing or decreasing as your work evolves?
- Do you reach for fact-check standalone, or primarily through draft-review? If primarily through draft-review, does standalone invocation still matter?
- Would you remember to fact-check a draft before sharing it, or does the draft-review pipeline handle that trigger for you?

### Condition for Value

**Stated or inferred conditions:**
1. The user writes prose drafts containing factual claims that benefit from verification.
2. For pipeline value: the draft-review orchestrator must exist and be functional.
3. Web search must be available at runtime (the skill mandates web search for every claim).

**Automated findings:**
- draft-review orchestrator: EXISTS at `skills/draft-review.md`. It references fact-check as a mandatory Stage 1 component.
- Both critic skills (cowen-critique, yglesias-critique) declare fact-check in their `requires` block: EXISTS.
- Example output artifact from a real pipeline run: EXISTS at `docs/reviews/fact-check-report.md`.
- Test fixtures for the skill: EXIST on branch `chore/cleanup-20260320` but NOT MERGED to main or current branch.

**Questions for the reviewer:**
- Are all three conditions met today? (Prose drafts with claims, draft-review pipeline, web search availability)
- Is the frequency of draft-writing stable, increasing, or decreasing?
- Does the skill pull you toward writing more carefully sourced drafts, or is it purely a verification step on existing work?

### Failure Mode Gracefulness

**Output structure:** Each claim is presented as a quoted excerpt from the draft alongside the verdict, confidence level, evidence summary, and source citations. This side-by-side format makes wrong verdicts detectable — the reader can see the claim and the evidence together and judge whether the verdict follows.

**Potential silent failures:**
1. **False "Accurate" verdicts:** The skill confirms a claim based on a source that itself is wrong, or based on a source that doesn't actually support the specific claim made. The structured format makes this checkable but doesn't prevent it.
2. **Missed claims:** The skill fails to extract a checkable claim from the draft. The reader sees only the claims that were checked, not the ones that were missed. No structural safeguard against this.
3. **Stale web search results:** The skill relies on web search, which may return outdated information. A claim could be marked "Accurate" based on old data when newer data contradicts it.
4. **"Unverified" as escape hatch:** The skill could overuse "Unverified" for claims it should have been able to check, producing a safe-looking but uninformative report.

**Pipeline mitigations:** The draft-review orchestrator passes fact-check results to critic agents, who may independently notice factual issues the fact-checker missed (though this is incidental, not systematic). The fact-check gate pauses the pipeline if high-confidence Inaccurate claims are found, preventing wasted critic compute on a draft with known errors.

**Questions for the reviewer:**
- Based on the fact-check report in `docs/reviews/fact-check-report.md`, did you spot any verdicts that seemed wrong or any claims that were missed?
- Is the "Unverified" verdict being used appropriately, or is it serving as a catch-all for insufficient effort?
- For your domain (policy-adjacent writing), which failure mode concerns you most — false Accurate verdicts, missed claims, or something else?

---

## Key Questions

1. **Test coverage is close but not landed.** Test fixtures and format tests exist on `chore/cleanup-20260320` but are not merged. Is merging those tests the highest-leverage next step for this skill, or are there more important gaps to address first?

2. **Missed-claim detection is the main structural blind spot.** The skill checks claims it finds but has no mechanism for ensuring completeness of claim extraction. Is this acceptable given the use case, or would a "claims I considered but didn't check" section add meaningful safety?

3. **Standalone vs. pipeline usage balance.** The skill is well-positioned both standalone and as a pipeline stage. In practice, which mode delivers more value — and does the answer affect how the skill should evolve?
