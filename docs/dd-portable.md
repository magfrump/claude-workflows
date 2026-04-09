# Divergent Design — Portable Prompt Template

*Paste this into any LLM chat interface. Replace `[DECISION TOPIC]` with your question.*

---

## Prompt

I need to make a design decision about **[DECISION TOPIC]**.

Walk me through a structured divergent design process with these four phases. Complete each phase fully before moving to the next. Use the done-when checklists to confirm completeness.

### Phase 1: Diverge — Generate Candidates

Generate 8-15 candidate approaches. Quantity over quality — no evaluation yet.

Requirements:
- At least 2-3 approaches that feel wrong, naive, or unconventional
- At least 1 "do nothing" or "minimal change" option
- At least 1 approach that would be ideal if effort/complexity were free
- One sentence each, numbered for reference

**Done when:** 8+ candidates listed, includes naive/unconventional options, includes do-nothing and ideal-if-free options, zero evaluation applied.

### Phase 2: Diagnose — Specify Problems and Constraints

List every concrete problem, requirement, and constraint the solution must address.

Requirements:
- Be specific enough to test an approach against (e.g., "reviewer in IST timezone needs to understand intent in <5 min from the PR description alone" not "code should be readable")
- Label each constraint as **hard** (must satisfy) or **soft** (prefer to satisfy)
- Explicitly consider non-obvious constraints: team skills, timezone gaps, maintenance burden, deployment complexity, performance requirements

**Done when:** All constraints stated with measurable specificity, each labeled hard/soft, non-obvious constraints explicitly considered.

### Phase 3: Match and Prune

Create a compatibility matrix scoring every approach against every constraint:

| # | Approach | Constraint 1 | Constraint 2 | ... |
|---|---------|-------------|-------------|-----|
| 1 | ...     | ✓           | ~           | ... |

Key: ✓ addresses well · ~ partial/uncertain · ✗ doesn't address · ⚠ actively worsens

- Discard anything with ⚠ on a hard constraint or mostly ✗
- For survivors with one fixable weakness, sketch the fix in 1-2 sentences
- Narrow to 3-5 survivors

**Done when:** Matrix complete, weak approaches discarded, fixable weaknesses sketched, 3-5 survivors remain.

### Phase 4: Tradeoff Matrix and Decision

For the 3-5 survivors, create a detailed comparison:

| Approach | Effort | Risk | Core problem coverage | Key downside |
|----------|--------|------|-----------------------|--------------|

State your recommendation with a one-sentence rationale. If the tradeoff is genuinely unclear, say so and identify what information would resolve it.

**Done when:** Tradeoff matrix complete, recommendation stated with rationale (or ambiguity explicitly flagged).

---

## Optional Add-on: Stress-Test Moves

*Add this section to your prompt when the decision has lasting consequences or when one option seems "obviously" best (that's when hidden assumptions hide).*

After building the tradeoff matrix, pressure-test each surviving approach using 2-4 of these moves:

| Move | Question to ask |
|------|----------------|
| **Boring alternative** | Is there a simpler approach that gets 80% of the benefit? Does this complexity earn its keep? |
| **Invert the thesis** | Argue sincerely for the opposite choice. What assumptions does the leading approach rest on? |
| **Revealed preferences** | What do teams/users/systems actually do vs. what they say they want? Is there prior art in the codebase? |
| **Push to extreme** | Extend this approach's logic to 10x scale. What breaks? What hidden boundary conditions emerge? |
| **Organizational survival** | Does this survive team turnover and the champion leaving? Will the next maintainer understand it? |
| **Scale test** | What happens at 10x traffic/data/users? Graceful degradation or cliff? |
| **Implementation org chart** | Who builds this? Who maintains it? What skills does the team have vs. need to acquire? |

Update the tradeoff matrix with any findings from stress testing.

---

## Optional Add-on: Epistemic Variant (Hypothesis Generation)

*Use this variant when the question is "what's true?" rather than "what should we build?" — e.g., explaining a bug, interpreting ambiguous behavior, evaluating competing theories.*

Replace `[DECISION TOPIC]` with `[OBSERVATION TO EXPLAIN]` and modify the phases:

**Phase 1 — Diverge:** Generate 8-15 competing *explanations* instead of approaches. Include 2-3 unlikely/surprising explanations, a "null hypothesis" (it's noise or expected behavior), and one explanation implying a deeper systemic issue.

**Phase 2 — Diagnose:** Instead of constraints, list *distinguishing evidence*. For each hypothesis: what observable predictions does it make? What evidence would confirm or refute it? Tag each piece of evidence:
- **[observed]** — directly verified
- **[inferred]** — logically derived from observations
- **[assumed]** — believed true but not verified

**Phase 3 — Evidence Matrix:** Score hypotheses against evidence:

| # | Hypothesis | Evidence 1 | Evidence 2 | ... |
|---|-----------|------------|------------|-----|
| 1 | ...       | ✓ consistent | ✗ contradicted | ... |

Discard hypotheses contradicted by [observed] evidence. Flag those depending on [assumed] evidence.

**Phase 4 — Rank:** Produce a ranked hypothesis list:

| Rank | Hypothesis | Confidence | Key supporting evidence | Critical evidence gap |
|------|-----------|------------|------------------------|----------------------|
| 1    | ...       | high/med/low | ...                  | ...                  |

The **critical evidence gap** is the single most valuable thing to investigate next.

---

*Template extracted from the Divergent Design workflow. If you use this, consider noting where and how — it helps improve future versions.*
