---
Last verified: 2026-03-24
Relevant paths:
  - skills/cowen-critique.md
  - skills/yglesias-critique.md
  - skills/draft-review.md
  - skills/fact-check.md
  - test/skills/cowen-critique-format.bats
---

# Self-Evaluation: cowen-critique

**Target:** `skills/cowen-critique.md` | **Type:** Skill | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | The structured output format (9 named sections: decomposed argument, inversion, boring explanation, revealed vs. stated, analogy, contingent assumptions, market signal, overall assessment) has checkable structural properties. Planted-flaw detection is testable (did the critique find the planted weakness?). However, the quality of cognitive moves — especially cross-domain analogies and argument decomposition — requires subjective judgment to evaluate. |
| Trigger clarity | Adequate | Triggers are well-defined ("poke holes in this", "what am I missing", "challenge my thinking", "Cowen-style review"). However, there is meaningful overlap with yglesias-critique — both are draft critics invoked for substantive intellectual feedback. The distinction (economist reasoning patterns vs. data-journalist reasoning) is clear in the skill definitions but may not be salient to a user choosing between them. The draft-review orchestrator resolves this by running both. |
| Overlap and redundancy | Adequate | Moderate structural overlap with yglesias-critique — both are prose critics with structured output sections that analyze argument quality. However, the cognitive moves are genuinely distinct: Cowen focuses on boring explanations, revealed preferences, cross-domain analogies, and market signals; Yglesias focuses on evidence strength, policy mechanism analysis, and counterargument construction. The overlap is in format and role, not in analytical substance. |
| Test coverage | Adequate | Format tests exist (`test/skills/cowen-critique-format.bats`). A real-world output artifact exists at `docs/reviews/cowen-critique.md`. Git history shows the skill has been used in draft-review pipeline runs. No eval tests that assess quality of cognitive moves. |
| Pipeline readiness | Strong | Standalone viable with clear output path (`docs/reviews/cowen-critique.md`). Also a functioning pipeline stage: draft-review orchestrates it as a critic in Stage 2. Declares `fact-check` in its `requires` block, and the pipeline provides the fact-check report. The fact-check integration instructions are explicit and well-designed (use as factual foundation, emit warning if absent). |

---

## Flagged for Human Review

### Counterfactual Gap

**What the tool does:** Applies 9 specific cognitive moves modeled on Tyler Cowen's analytical style: (1) try the boring explanation, (2) invert the claim, (3) follow revealed preferences, (4) push to logical extreme, (5) find cross-domain analogy, (6) ask what the market says, (7) decompose into sub-claims, (8) identify contingent assumptions, (9) calibrate uncertainty honestly. Produces a structured critique with named sections mapping to these moves. Integrates upstream fact-check findings when available.

**What generic prompting achieves:** Asking Claude to "critique this draft" without the skill would produce a general-purpose review — likely noting some strengths and weaknesses, perhaps suggesting counterarguments. It would miss: (1) the systematic application of all 9 moves, (2) the specific "boring explanation first" discipline, (3) the revealed-preferences lens, (4) the cross-domain analogy requirement, (5) the explicit uncertainty calibration. Generic prompting might attempt some of these but not consistently or thoroughly.

**What built-in tools cover:** No built-in Claude Code capability performs structured prose critique. The code-simplifier focuses on code, not prose arguments.

**Questions for the reviewer:**
- Which of the 9 cognitive moves have been most valuable in practice? Are there moves that consistently produce weak output?
- Is the gap primarily "the skill ensures all 9 moves are attempted" (consistency value) or "the skill defines moves the user wouldn't think of" (analytical value)?
- How does the skill's output compare to what you'd get from a thoughtful human reviewer with domain expertise?

### User-Specific Fit

**Triggering situations:**
- Writing a blog post, essay, or policy piece and wanting substantive intellectual critique
- Running draft-review, which invokes cowen-critique as a Stage 2 critic
- Wanting to stress-test an argument before sharing it
- Specifically requesting economist-style analysis or Cowen-style review

**Questions for the reviewer:**
- How often do you write drafts that benefit from this style of critique?
- Do you invoke cowen-critique standalone or primarily through draft-review?
- When you have a draft, do you think "I should run the Cowen critique" or is it only triggered by the pipeline?
- Has the critique changed how you write, or is it purely a post-hoc review tool?

### Condition for Value

**Stated or inferred conditions:**
1. The user writes prose drafts that benefit from substantive intellectual critique.
2. For pipeline value: the draft-review orchestrator exists and is functional.
3. For full value: a fact-check report should be available upstream (the skill warns if absent).
4. The user writes content where economist-style reasoning (markets, incentives, revealed preferences) is relevant.

**Automated findings:**
- draft-review orchestrator: EXISTS at `skills/draft-review.md`, invokes cowen-critique in Stage 2.
- fact-check skill: EXISTS at `skills/fact-check.md`, declared in cowen-critique's `requires` block.
- Companion critic (yglesias-critique): EXISTS, providing a complementary analytical lens.
- Example output artifact: EXISTS at `docs/reviews/cowen-critique.md`.
- Format tests: EXIST at `test/skills/cowen-critique-format.bats`.

**Questions for the reviewer:**
- Do you write content where the economist-style moves (boring explanation, revealed preferences, market signals) are specifically relevant, or is the value more general?
- If the draft-review pipeline didn't exist, would you invoke cowen-critique standalone?
- Is the Cowen/Yglesias distinction important to you, or would a single unified critic suffice?

### Failure Mode Gracefulness

**Output structure:** Named sections (The Argument Decomposed, What Survives the Inversion, The Boring Explanation, etc.) make thin analysis visible — an empty or shallow section stands out. The uncertainty calibration move (#9) explicitly asks for honest confidence levels in the critique itself.

**Potential silent failures:**
1. **Superficial cross-domain analogies.** The most distinctive move (#5) is also the riskiest — the skill could produce an analogy that sounds illuminating but is structurally flawed, and the reader may not have the cross-domain expertise to evaluate it.
2. **Confident-sounding analysis on misunderstood arguments.** If the skill misreads the draft's thesis, the entire decomposition and inversion will be wrong but may still read as coherent.
3. **Boring-explanation move applied too aggressively.** Defaulting to "it's just a price change" could dismiss genuinely novel arguments. The move is a useful reflex but needs calibration.
4. **Revealed-preferences analysis based on incomplete evidence.** The skill may assert behavioral patterns it cannot actually verify, producing confident claims about what people "actually do" without evidence.

**Pipeline mitigations:** The fact-check upstream catches factual errors before they reach the critique. The draft-review orchestrator runs yglesias-critique in parallel, providing a second analytical lens that may catch what cowen-critique misses. The structured output makes thin sections visible to the reader.

**Questions for the reviewer:**
- Have any cross-domain analogies been structurally flawed in ways you recognized after the fact?
- Has the boring-explanation move ever dismissed something that was genuinely novel?
- Do you cross-reference cowen-critique and yglesias-critique outputs to catch each other's blind spots?

---

## Key Questions

1. **Cross-domain analogy quality is the key risk.** Move #5 is the most distinctive and highest-value move, but also the hardest to verify. How do you evaluate whether an analogy is genuinely illuminating vs. superficially appealing?

2. **Cowen/Yglesias distinction.** The two critics have moderate structural overlap but distinct cognitive moves. In practice, does the distinction produce meaningfully different critiques, or do they converge on similar findings from different angles?

3. **Standalone vs. pipeline usage.** The skill works both ways, but the fact-check integration suggests pipeline use is the intended primary mode. If standalone is the more common use case, should the skill be more self-contained in handling factual claims?
