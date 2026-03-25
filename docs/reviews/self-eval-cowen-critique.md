---
Last verified: 2026-03-24
Relevant paths:
  - skills/cowen-critique.md
  - skills/draft-review.md
  - skills/yglesias-critique.md
  - skills/fact-check.md
---

# Self-Evaluation: cowen-critique

**Target:** `skills/cowen-critique.md` | **Type:** Skill | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | Can test structural properties (required sections present, no leakage from sibling skills) and planted-flaw detection (does the skill find a deliberately weak argument?). However, the quality of cross-domain analogies, inversion exercises, and revealed-preference analysis requires subjective human judgment with no mechanical shortcut. |
| Trigger clarity | Adequate | Frontmatter lists concrete trigger phrases ("poke holes in this", "challenge my thinking", "what am I missing"). However, the boundary with yglesias-critique is fuzzy for policy-adjacent drafts — a user asking "critique this essay about housing policy" could reasonably invoke either. The draft-review orchestrator resolves this by running both, but standalone invocation requires the user to understand the distinction. |
| Overlap and redundancy | Adequate | Structural overlap with yglesias-critique is moderate — both are critic skills consuming a fact-check report and producing structured Markdown critiques with similar section patterns. Substantive overlap is low: Cowen's 9 cognitive moves (boring explanation, revealed preferences, cross-domain analogy, market signals) are genuinely distinct from Yglesias's moves (goal vs. mechanism, org chart test, cost disease, supply-side). No overlap with code-review pipeline skills or matrix-analysis. |
| Test coverage | Weak | A format validation test exists (`test/skills/cowen-critique-format.bats`) checking required sections and no leakage from sibling skills. One real output artifact exists at `docs/reviews/cowen-critique.md` (a critique of the fact-check test strategy). No behavioral/eval tests exist — no planted-flaw fixtures, no eval criteria document, no evidence of repeated usage beyond the single artifact. The skill is in a probationary state per the rubric. |
| Pipeline readiness | Strong | Standalone viable for any essay or article — the skill works without a pipeline. Also integrated into the draft-review orchestrator, which runs fact-check upstream and passes the report to cowen-critique. The `requires` block correctly declares the fact-check dependency. The pipeline exists and is functional. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the tool does:** Applies 9 specific cognitive moves drawn from Tyler Cowen's analytical style — try the boring explanation, invert the claim, follow revealed preferences, push to logical extremes, find cross-domain analogies, check market signals, decompose sub-claims, spot contingent assumptions, and calibrate uncertainty. These are applied to a draft and structured into a multi-section Markdown critique with prescribed headings (The Argument Decomposed, What Survives the Inversion, The Boring Explanation, etc.).

**What generic prompting achieves:** Asking Claude "critique this draft" or "poke holes in this essay" without the skill file would likely produce a competent general critique covering strengths, weaknesses, and suggestions. Some individual moves (like decomposing sub-claims or noting counterarguments) would appear naturally. However, the specific combination of all 9 moves applied systematically is unlikely. In particular, "follow revealed preferences instead of stated ones," "find a cross-domain structural analogy," and "what is the market telling you?" are distinctive moves that generic prompting would rarely surface together. The structured output format with consistent sections also would not appear without the skill.

**What built-in tools cover:** No built-in Claude Code capability covers draft critique. The closest built-in is general conversation, which lacks the structured analytical framework.

**Questions for the reviewer:**
- How much of the skill's value comes from the 9 specific cognitive moves vs. the structural consistency of always getting the same sections? If you got 5 of the 9 moves from generic prompting, would that be good enough?
- Is the gap "the skill adds moves the user wouldn't think of" (e.g., market signals, revealed preferences) or "the skill ensures consistency the user would otherwise forget" (e.g., always doing the inversion)?
- Under what conditions is the gap largest — long-form essays with implicit arguments, or shorter pieces with explicit claims?

### User-Specific Fit

**Triggering situations:** Writing or reviewing a blog post, essay, article, or similar draft where the user wants substantive intellectual pressure-testing beyond proofreading. Also triggered as part of the draft-review pipeline for any written draft.

**Questions for the reviewer:**
- How often do you write or review drafts that would benefit from this kind of intellectual critique? Weekly? Monthly? Less?
- Is the frequency increasing or decreasing as your writing habits evolve?
- Does the Cowen-style lens (economic reasoning, cross-domain analogies, revealed preferences) match the kind of thinking you want applied to your drafts, or would a different analytical lens be more useful?
- Would you actually remember to invoke `cowen-critique` standalone, or do you always use `draft-review` (which runs it automatically)?

### Condition for Value

**Stated or inferred conditions:**
1. The user writes drafts that benefit from intellectual critique (not just proofreading or fact-checking).
2. The draft-review pipeline exists and is functional (for pipeline value).
3. The Cowen-style analytical lens is relevant to the user's subject matter.
4. The user writes frequently enough that consistency across critiques matters.

**Automated findings:**
- The draft-review orchestrator that composes this skill: **EXISTS** (`skills/draft-review.md`).
- The fact-check skill that provides upstream input: **EXISTS** (`skills/fact-check.md`).
- The sibling yglesias-critique that provides a complementary lens: **EXISTS** (`skills/yglesias-critique.md`).
- Evidence of real-world usage: **ONE ARTIFACT** (`docs/reviews/cowen-critique.md` — a critique of the fact-check test strategy).

**Questions for the reviewer:**
- Are all four conditions met today?
- The single usage artifact suggests the skill has been used at least once on real work. Was that output useful enough to justify keeping the skill?
- Is this skill an investment that pulls toward writing more (because the review pipeline makes drafting feel safer), or is it inventory waiting for a writing habit that may not materialize?

### Failure Mode Gracefulness

**Output structure:** The critique is organized into prescribed sections (The Argument Decomposed, What Survives the Inversion, Factual Foundation, The Boring Explanation, Revealed vs. Stated, The Analogy, Contingent Assumptions, What the Market Says, Overall Assessment). Each section corresponds to a specific cognitive move. The skill warns when no fact-check report is provided, and the Overall Assessment section explicitly rates which sub-claims are strong vs. weak.

**Potential silent failures:**
- **Cross-domain analogies that sound structural but are superficial.** The skill instructs "find an illuminating parallel from a completely different domain." An LLM may produce an analogy that reads well but is structurally flawed — the dynamics in domain B don't actually mirror domain A in the way claimed. This is the hardest failure to detect because the analogy sounds insightful.
- **Revealed-preference analysis built on incorrect behavioral assumptions.** The skill asks "what are people actually doing?" but the LLM may confabulate behavioral evidence or cite outdated patterns. Without the fact-check covering behavioral claims (fact-check focuses on the draft's claims, not the critique's claims), these assertions go unverified.
- **Inversion that is too easy.** The skill inverts the thesis and checks what survives — but a shallow inversion that doesn't genuinely inhabit the opposing view will produce a weak stress test that looks like a strong one.
- **Boring explanation that is itself interesting.** If the "mundane alternative" is actually novel or non-obvious, the section becomes a second argument rather than a baseline test. The output looks correct but the cognitive move has been misapplied.

**Pipeline mitigations:** The fact-check skill runs upstream in the draft-review pipeline, catching fabricated numbers and wrong claims in the draft before the critic sees it. However, fact-check does not verify claims made *by the critic itself* — only claims in the original draft. The critic's own assertions (behavioral evidence for revealed preferences, factual basis for analogies) are unverified.

**Questions for the reviewer:**
- Based on the single output artifact (`docs/reviews/cowen-critique.md`), were any of the cross-domain analogies or revealed-preference observations off-base?
- Which failure mode concerns you most: superficial analogies, confabulated behavioral evidence, shallow inversions, or something else?
- Is the detectable-to-silent failure ratio acceptable given that this is one lens in a multi-critic pipeline (not the sole review)?

---

## Key Questions

1. **Is the Cowen/Yglesias distinction actionable standalone?** Both skills have "Adequate" trigger clarity, and the boundary is fuzzy for policy drafts. If users always invoke `draft-review` (which runs both), the standalone trigger question is moot — but if the distinction isn't clear standalone, the skills are effectively pipeline-only components marketed as standalone tools.

2. **Does one real-world artifact constitute sufficient evidence?** The skill has a format test and one output artifact, but no behavioral tests and no evaluation criteria. The existing artifact (`docs/reviews/cowen-critique.md`) is substantive and demonstrates the cognitive moves working well, but a single data point cannot establish reliability across draft types. What would it take to move from "probationary" to "adequate" test coverage?

3. **Is the critic's own reasoning verified?** The pipeline architecture verifies the *draft's* claims via fact-check, but the *critic's* claims (behavioral evidence, cross-domain analogies, market signals) are unverified. This is the most significant architectural gap — the skill that is supposed to catch reasoning errors in others has no mechanism to catch its own.
