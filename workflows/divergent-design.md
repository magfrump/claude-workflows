---
triggers:
  keywords:
    - design
    - architecture
    - choose
    - compare
    - which approach
    - library selection
    - tradeoff
  session_signals:
    - 3+ viable approaches identified during research
    - tradeoff evaluation needed between competing options
    - premature convergence risk on a design decision
    - "what should we build?" rather than "build this"
---

# Divergent Design Workflow

*The diverge → diagnose → match → decide structure follows the [orchestrated review pattern](../patterns/orchestrated-review.md), with candidate approaches as the units of parallel evaluation.*

## When to use
- Architectural decisions (how to structure a feature, which pattern to use)
- Library or tool selection
- Major feature design where multiple approaches exist
- Any decision where premature convergence is a risk
- **As a sub-procedure within RPI**: When the research phase of `research-plan-implement.md` reveals a design decision, DD is invoked inline. The decision output feeds back into RPI's research doc and informs the plan. See RPI step 2 for trigger signals.
- **Hypothesis generation** (epistemic variant): When the question is "what's true?" rather than "what should we build?" — e.g., explaining a bug, interpreting ambiguous behavior, or evaluating competing theories. See the Epistemic Reasoning variant below.

## When to pivot

- **← From RPI** (see RPI step 2 for triggers): Carry the research doc's invariants and constraints into DD's diagnosis step (step 2) — they're already half the work.
- **→ RPI**: After DD produces a decision, return to RPI's plan step with the decision doc as input. Reference it from the plan; don't duplicate the rationale.
- **→ Spike**: If DD candidates require feasibility validation, run a timeboxed spike on the uncertain option before finalizing the decision. The spike's findings update DD's tradeoff matrix.

## Process

### 1. Diverge — generate many possibilities

Generate 8-15 candidate approaches. Quantity matters more than quality at this stage. Requirements:
- Include at least 2-3 approaches that feel wrong, naive, or unconventional
- Include at least 1 "do nothing" or "minimal change" option
- Include at least 1 approach that would be ideal if effort/complexity were free
- One sentence each, no evaluation yet
- Number them for reference

**Done when...**
- [ ] At least 8 candidate approaches are listed
- [ ] At least 2-3 approaches feel wrong, naive, or unconventional
- [ ] A "do nothing" or "minimal change" option is included
- [ ] An "ideal if effort were free" option is included
- [ ] No evaluation or ranking has been applied yet — only generation

### 2. Diagnose — specify the actual problems and constraints

List every concrete problem, requirement, and constraint the solution must address. Be specific:
- ✓ "The reviewer in IST timezone needs to understand intent in <5 minutes from the PR description alone"
- ✗ "Code should be readable"

Include non-obvious constraints: timezone gaps, skill gaps in the team, maintenance burden, deployment complexity, interaction with existing code, performance requirements. Also note which constraints are hard (must satisfy) vs soft (prefer to satisfy).

**Done when...**
- [ ] Every concrete problem and constraint is stated with enough specificity to test an approach against it
- [ ] Each constraint is labeled as hard (must satisfy) or soft (prefer to satisfy)
- [ ] Non-obvious constraints (team skills, deployment, maintenance) have been explicitly considered
- [ ] No constraint uses vague language like "readable" or "good" without a measurable qualifier

### 3. Match and prune

Create a rough compatibility matrix:

| # | Approach | Problem 1 | Problem 2 | ... |
|---|---------|-----------|-----------|-----|
| 1 | ...     | ✓         | ~         | ... |

Key:
- ✓ addresses well
- ~ partial or uncertain
- ✗ doesn't address
- ⚠ actively makes worse

For approaches that score well overall but have one fixable weakness, briefly sketch how to fix it (1-2 sentences). Discard anything with ⚠ on a hard constraint or mostly ✗ across the board.

**Done when...**
- [ ] A compatibility matrix exists with every approach scored against every constraint
- [ ] All approaches with ⚠ on a hard constraint or mostly ✗ are discarded
- [ ] Fixable weaknesses in surviving approaches have a 1-2 sentence sketch of the fix
- [ ] 3-5 approaches survive for detailed comparison

### 4. Tradeoff matrix and decision

For the top 3-5 survivors, create a detailed comparison:

| Approach | Effort (hours/days) | Risk | Core problem coverage | Key downside |
|----------|-------------------|------|----------------------|--------------|

#### Stress-test pass

After building the tradeoff matrix, pressure-test the surviving approaches using these cognitive moves adapted from structured critique methods. Not all moves apply to every decision — use the ones that illuminate genuine differences between approaches.

| Move | What to ask | Best for |
|------|------------|----------|
| **Boring alternative** | Is there a simpler approach that gets 80% of the benefit? Does this approach's complexity earn its keep, or is the simpler version good enough? | Always worth checking — especially when a sophisticated approach is winning |
| **Invert the thesis** | Argue sincerely for the opposite choice. What survives? What assumptions does the leading approach rest on that you haven't defended? | When one approach seems obviously best — the obvious answer is where hidden assumptions hide |
| **Revealed preferences** | What do teams/users/systems actually do, vs. what they say they want? If the codebase already has a similar decision point, what did it choose and how did that go? | API design, developer experience, convention choices |
| **Push to extreme** | Extend this approach's logic further than intended. What breaks? What hidden boundary conditions emerge? | Architecture decisions where the design will be lived with for a long time |
| **Organizational survival** | Does this survive team turnover, priority shifts, and the person who championed it leaving? Will the next maintainer understand why this choice was made? | Decisions with long maintenance tails — framework selection, data model choices |
| **Scale test** | What happens at 10x the current traffic, data, users, or contributors? Does the approach degrade gracefully or hit a cliff? | Scalability-sensitive decisions |
| **Implementation org chart** | Who builds this? Who maintains it? What skills does the team actually have vs. need to acquire? | Build-vs-buy, framework selection, anything requiring new expertise |

Apply 2-4 of the most relevant moves to each surviving approach. Update the tradeoff matrix if the stress test reveals new information — a changed risk rating, a previously unnoticed downside, or a boring alternative that should have been a candidate from the start.

#### Decision

If one approach clearly dominates (>80% confidence): document the decision and proceed.

If the tradeoff is genuinely unclear: **stop and consult the user.** Present the matrix, state your tentative recommendation with reasoning, and identify what information would resolve the ambiguity.

**Done when...**
- [ ] At least 2-4 stress-test moves were applied to each surviving approach
- [ ] Tradeoff matrix is updated with any findings from the stress test
- [ ] Either one approach dominates at >80% confidence, or the user has been consulted
- [ ] The chosen approach is stated explicitly with a one-sentence rationale

### 5. Document

Create or update `docs/decisions/NNN-title.md` with:
- Context: what prompted the decision
- Options considered (brief — the full analysis doesn't need to be preserved)
- Decision and rationale
- Consequences: what this makes easier, what this makes harder

**Sub-threshold decisions**: Not every decision surfaced during DD warrants a full record. If the diverge phase quickly converges to a single obvious answer — no real tradeoffs, low reversal cost — add a row to [`docs/decisions/log.md`](../docs/decisions/log.md) instead and move on. The log's "when to use" criteria describe the boundary. Reserve full `NNN-title.md` records for decisions with genuine tradeoffs or lasting consequences.

**Done when...**
- [ ] Decision record exists in `docs/decisions/NNN-title.md` (or a row in `log.md` for sub-threshold decisions)
- [ ] Record includes Context, Options considered, Decision and rationale, and Consequences
- [ ] The decision is referenced from the calling workflow's artifacts (e.g., the RPI plan doc)

## Variant: Epistemic Reasoning (Hypothesis Generation)

When the goal is to explain an observation rather than choose an implementation, DD can be used for structured hypothesis generation. Candidates become competing explanations, diagnosis identifies distinguishing evidence, and the output is a ranked hypothesis list rather than a decision record.

Use this variant when:
- A bug, behavior, or outcome has multiple plausible explanations
- You need to distinguish between competing theories about *why* something is happening
- The question is "what's true?" rather than "what should we build?"
- Research has surfaced ambiguity that can't be resolved by reading more code — you need to reason about evidence

### Step modifications

#### 1. Diverge — generate competing explanations

Generate 8-15 candidate explanations for the observed phenomenon. The same quantity-over-quality principle applies:
- Include at least 2-3 explanations that seem unlikely or surprising
- Include at least 1 "null hypothesis" (the observation is noise, expected behavior, or measurement error)
- Include at least 1 explanation that would imply a deeper systemic issue
- One sentence each, no evaluation yet

#### 2. Diagnose — identify distinguishing evidence

Instead of listing constraints, list **observations and evidence** that distinguish between hypotheses:
- What specific, observable predictions does each hypothesis make?
- What evidence would confirm or refute each explanation?
- Which pieces of evidence are already available vs. require new investigation?

Label each piece of evidence with a confidence-provenance tag (see RPI's research phase for the convention):
- **[observed]** — directly verified (you saw it in logs, code, output)
- **[inferred]** — logically derived from observed evidence
- **[assumed]** — believed true but not yet verified

#### 3. Match and prune — evidence matrix

Create an evidence compatibility matrix:

| # | Hypothesis | Evidence 1 | Evidence 2 | ... |
|---|-----------|------------|------------|-----|
| 1 | ...       | ✓ consistent | ✗ contradicted | ... |

Key:
- ✓ consistent with this evidence
- ~ not clearly distinguished by this evidence
- ✗ contradicted by this evidence
- ? — evidence not yet gathered

Discard hypotheses contradicted by [observed] evidence. Flag hypotheses that depend heavily on [assumed] evidence — these are the ones where gathering more information has the highest value.

#### 4. Rank and identify evidence gaps

Instead of a tradeoff matrix and decision, produce a **ranked hypothesis list**:

| Rank | Hypothesis | Confidence | Key supporting evidence | Critical evidence gap |
|------|-----------|------------|------------------------|----------------------|
| 1 | ... | high/medium/low | ... | ... |

**Confidence** reflects how well the hypothesis explains all [observed] evidence without relying on [assumed] claims.

**Critical evidence gap** identifies the single most valuable piece of information that would confirm or refute this hypothesis. This drives the next investigation step.

#### 5. Document — hypothesis record

Instead of a decision record, produce a hypothesis record. This can live in the calling workflow's research doc (if DD was invoked as a sub-procedure) or as a standalone working doc.

The record should include:
- The observation being explained
- The ranked hypothesis list with evidence gaps
- Recommended next investigation steps (ordered by information value — what would most efficiently distinguish between the top hypotheses?)
- Which hypotheses were eliminated and why

**Evaluating epistemic DD usage**: A DD exercise counts as "epistemic mode" when its output is a ranked hypothesis list with evidence gaps rather than a decision record selecting an implementation approach.
