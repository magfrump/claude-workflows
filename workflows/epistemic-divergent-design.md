# Epistemic Divergent Design Workflow

Adapts divergent-design for hypothesis-space expansion: generating competing
explanations or framings for an observed phenomenon, then ranking them by
testability and cost-to-test.

## When to use
- An observation, metric, or outcome needs explanation and the first hypothesis is probably not the only one
- You want to avoid anchoring on a single causal story before gathering evidence
- Pre-implementation screening: expanding the hypothesis space before committing resources

## When to pivot
- **← From RPI**: Research phase surfaces a "why?" question with multiple plausible answers
- **→ Hypothesis backlog**: Output shortlist feeds into `docs/working/hypothesis-backlog.md` for tracking
- **→ Spike**: If a top hypothesis needs feasibility validation before evidence collection

## Output artifact
A **hypothesis shortlist** (not a decision record). Format:

```
## Hypothesis Shortlist: [Question]
Date: YYYY-MM-DD | Workflow: epistemic-divergent-design

| Rank | Hypothesis | Distinguishing evidence | Cost to test | Status |
|------|-----------|------------------------|-------------|--------|
| 1    | ...       | ...                    | low/med/high | UNTESTED |
```

Save to `docs/working/` or inline in the calling workflow's artifacts.

## Process

### 1. Frame the question
State the observation or puzzle as a specific, falsifiable question.
- Bad: "Why isn't this working?"
- Good: "Why did adoption of workflow X drop 40% in rounds 3-4 despite no changes to the workflow itself?"

Include: what was observed, when, and what makes it surprising or worth explaining.

**Done when:**
- [ ] Question is specific enough that two people would agree on what counts as an answer
- [ ] The surprising observation is stated with concrete details (numbers, dates, context)

### 2. Diverge — generate 10+ competing explanations
Generate at least 10 candidate hypotheses. Prioritize breadth over plausibility.
- Include at least 2 hypotheses that challenge the framing of the question itself
- Include at least 1 "null hypothesis" (the observation is noise/coincidence)
- Include at least 1 hypothesis that implies a systemic rather than local cause
- One sentence each, no evaluation yet — number them for reference

**Done when:**
- [ ] At least 10 hypotheses are listed
- [ ] At least 2 challenge the question's framing
- [ ] A null hypothesis is included
- [ ] A systemic-cause hypothesis is included
- [ ] No evaluation or ranking has been applied yet

### 3. Identify distinguishing evidence
For each hypothesis, ask: "What observable evidence would make this hypothesis more likely than the others?" Focus on evidence that *differentiates* — evidence consistent with all hypotheses has no diagnostic value.

Create a distinguishability matrix:

| # | Hypothesis | Predicts (if true) | Predicts (if false) | Evidence available? |
|---|-----------|-------------------|--------------------|--------------------|
| 1 | ...       | ...               | ...                | yes/no/partial     |

Merge or discard hypotheses that are observationally equivalent (no distinguishing evidence exists).

**Done when:**
- [ ] Each surviving hypothesis has at least one distinguishing prediction
- [ ] Observationally equivalent hypotheses are merged or noted
- [ ] Evidence availability is assessed for each prediction

### 4. Rank by cost-to-test
Score each surviving hypothesis on:
- **Cost to test**: time, tooling, data access required (low/medium/high)
- **Information value**: how many other hypotheses does this test help rule in/out?
- **Reversibility**: can you test without committing to a course of action?

Sort by: low-cost + high-information-value first. This is your testing order.

**Done when:**
- [ ] Each hypothesis has cost, information value, and reversibility scores
- [ ] Hypotheses are sorted by cost-effectiveness of testing
- [ ] Top 3-5 hypotheses form the shortlist

### 5. Output hypothesis shortlist
Produce the shortlist artifact (see format above). For each shortlist entry, include:
- The hypothesis in one sentence
- What evidence would confirm or refute it
- Estimated cost to test

Add shortlisted hypotheses to `docs/working/hypothesis-backlog.md` if they warrant ongoing tracking.

**Done when:**
- [ ] Shortlist artifact is written with 3-5 ranked hypotheses
- [ ] Each entry has confirming/refuting evidence and cost-to-test
- [ ] Relevant hypotheses are added to the hypothesis backlog
