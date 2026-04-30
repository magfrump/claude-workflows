---
value-justification: "Replaces ad-hoc architectural debates with structured multi-candidate evaluation, preventing premature commitment to the first idea."
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
- **Contested or unclear problem framing** (double-diamond variant): When stakeholders disagree on the goal, a prior attempt solved the wrong problem, or step 2 keeps surfacing contradictory constraints. See the Double Diamond (Purpose-First) variant below.

## When to pivot

- **← From RPI** (see RPI step 2 for triggers): Carry the research doc's invariants and constraints into DD's diagnosis step (step 2) — they're already half the work.
- **← From Bug Diagnosis**: When debugging surfaces a design-level root cause with 3+ viable fix approaches, invoke DD directly — don't route through RPI first. The diagnosis log's root-cause analysis and failed hypotheses become hard constraints in DD's diagnosis step (step 2): the root cause defines what must be solved, and the failed hypotheses document approaches already ruled out (pre-pruning step 3 candidates). This shortcut applies when the bug is understood but the *fix* is a design decision. If the root cause is still uncertain, stay in debugging or escalate to RPI research.
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

#### Generation health check

After generating your initial candidates, scan for these common generation gaps. This is not evaluation — you are checking whether the *search space* is broad enough, not whether any candidate is good or bad. If a gap is found, generate additional candidates to fill it; never remove existing ones.

- **Candidate clustering**: Do 3 or more candidates describe near-variants of the same underlying approach (e.g., three different caching strategies that all assume caching is the answer)? If so, you've anchored on one region of the solution space. Name the shared assumption and generate 2-3 candidates that violate it. Note which cluster triggered this so the pattern is visible in retrospect.
- **Missing perspectives**: Is there a "do nothing" or "minimal change" option? A naive or brute-force option? An option that a newcomer unfamiliar with the codebase might suggest? These perspectives often survive pruning — their absence usually means anchoring, not that they were considered and rejected.
- **Excessive vagueness**: Can each candidate be tested against a concrete constraint? A candidate like "use a better architecture" or "improve the data flow" can't be meaningfully evaluated in step 3's compatibility matrix. Replace vague candidates with specific ones — what *specific* architecture? What *specific* change to data flow?

If the health check triggers additional generation, note it briefly (e.g., "Added 3-5 after health check flagged clustering around caching approaches"). This makes generation patterns visible across sessions.

**Done when...**
- [ ] At least 8 candidate approaches are listed
- [ ] At least 2-3 approaches feel wrong, naive, or unconventional
- [ ] A "do nothing" or "minimal change" option is included
- [ ] An "ideal if effort were free" option is included
- [ ] No evaluation or ranking has been applied yet — only generation
- [ ] Generation health check passed: no unaddressed clustering, missing perspectives, or vague candidates

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

Each surviving candidate must also carry a **falsifiable hypothesis** in the form: *"If we choose this, we expect [observable outcome] within [window]; counter-evidence would be [X]."* For example: *"If we adopt the queue-based ingest, we expect p99 latency under 200ms within two weeks of rollout; counter-evidence would be sustained p99 above 400ms or queue depth growing across a full traffic cycle."* This makes the candidate's success conditions checkable post-decision and pre-prunes candidates whose claimed benefits can't be stated in falsifiable terms.

#### Stress-test pass

After building the tradeoff matrix, pressure-test the surviving approaches using these cognitive moves adapted from structured critique methods. Not all moves apply to every decision — select 2-4 moves whose "When to use" trigger matches the current decision context.

| Move | What to ask | When to use |
|------|------------|-------------|
| **Boring alternative** | Is there a simpler approach that gets 80% of the benefit? Does this approach's complexity earn its keep, or is the simpler version good enough? | Use when a complex or sophisticated approach is leading and you haven't verified that a simpler version would be insufficient. |
| **Invert the thesis** | Argue sincerely for the opposite choice. What survives? What assumptions does the leading approach rest on that you haven't defended? | Use when one approach appears to dominate — unchallenged front-runners are where hidden assumptions hide. |
| **Revealed preferences** | What do teams/users/systems actually do, vs. what they say they want? If the codebase already has a similar decision point, what did it choose and how did that go? | Use when the decision affects how humans interact with the system (APIs, UX, conventions) and actual usage patterns may differ from stated requirements. |
| **Push to extreme** | Extend this approach's logic further than intended. What breaks? What hidden boundary conditions emerge? | Use when the design will be difficult to change later and must accommodate conditions beyond current parameters. |
| **Organizational survival** | Does this survive team turnover, priority shifts, and the person who championed it leaving? Will the next maintainer understand why this choice was made? | Use when the decision's lifespan will exceed the current team's tenure — framework, data model, or infrastructure choices. |
| **Scale test** | What happens at 10x the current traffic, data, users, or contributors? Does the approach degrade gracefully or hit a cliff? | Use when load, data volume, or user count is expected to grow significantly and the approaches differ in how they handle that growth. |
| **Implementation org chart** | Who builds this? Who maintains it? What skills does the team actually have vs. need to acquire? | Use when the approaches require different skills or team structures to build and maintain, or involve build-vs-buy tradeoffs. |

Apply 2-4 of the most relevant moves to each surviving approach. Update the tradeoff matrix if the stress test reveals new information — a changed risk rating, a previously unnoticed downside, or a boring alternative that should have been a candidate from the start.

#### Decision

If one approach clearly dominates (>80% confidence): document the decision and proceed.

If the tradeoff is genuinely unclear: **stop and consult the user.** Present the matrix, state your tentative recommendation with reasoning, and identify what information would resolve the ambiguity.

**Done when...**
- [ ] Each surviving candidate carries a falsifiable hypothesis (expected observable, window, counter-evidence)
- [ ] At least 2-4 stress-test moves were applied to each surviving approach
- [ ] Tradeoff matrix is updated with any findings from the stress test
- [ ] Either one approach dominates at >80% confidence, or the user has been consulted
- [ ] The chosen approach is stated explicitly with a one-sentence rationale

### 5. Document

Create or update `docs/decisions/NNN-title.md`. The doc must begin with the standard three-line header used by RPI working docs (see `workflows/research-plan-implement.md` step 2):

- **Goal**: One sentence — what this artifact is trying to achieve. For a DD decision record, this is the design decision being made.
- **Project state**: One sentence — branch context, written as `<what this branch delivers> · <position in larger initiative, or "standalone"> · <blocked on, or "not blocked">`. When DD is invoked as a sub-procedure within RPI, this is the calling RPI loop's branch context.
- **Task status**: Lifecycle keyword from `in-progress | blocked | paused | complete`, optionally followed by a free-form phase note in parens (e.g., `in-progress (decision drafted, awaiting review)`). The keyword is required; the parenthetical is optional but recommended whenever a phase note would help a re-reader orient.

The header serves the same drift-surfacing purpose described in RPI step 2: every mid-task re-read should re-verify the three lines against reality, and the Task status line should be updated whenever the doc is read or revised. Treat it as required body content — no optional pre-block, no YAML frontmatter, no linter; the spec text is the enforcement.

After the header, the body must include:

- **Context**: what prompted the decision
- **Options considered** (brief — the full analysis doesn't need to be preserved)
- **Decision and rationale**
- **Consequences**: what this makes easier, what this makes harder

**Sub-threshold decisions**: Not every decision surfaced during DD warrants a full record. If the diverge phase quickly converges to a single obvious answer — no real tradeoffs, low reversal cost — add a row to [`docs/decisions/log.md`](../docs/decisions/log.md) instead and move on. The log's "when to use" criteria describe the boundary. Reserve full `NNN-title.md` records for decisions with genuine tradeoffs or lasting consequences. The three-line header requirement applies to full records only; sub-threshold log rows are exempt.

**Done when...**
- [ ] Decision record exists in `docs/decisions/NNN-title.md` (or a row in `log.md` for sub-threshold decisions)
- [ ] For full records, the doc opens with the three-line header (Goal · Project state · Task status) and includes all required body sections (Context, Options considered, Decision and rationale, Consequences)
- [ ] The Task status line accurately reflects current lifecycle (re-read it; if it lies, fix it)
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

Apply the **generation health check** from step 1 of the main process, adapted for hypotheses: watch for clustering around one causal mechanism, missing null hypotheses, and explanations too vague to generate testable predictions.

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

## Variant: Double Diamond (Purpose-First)

When the *problem itself* is contested or unclear, a single divergent pass risks producing well-evaluated solutions to the wrong problem. The Double Diamond variant adds a problem-space diamond before the standard solution-space diamond:

- **Diamond 1 (Purpose)**: Diverge across candidate framings of the problem, then converge on a single chosen framing.
- **Diamond 2 (Solution)**: Run standard DD steps 1-4 (Diverge → Diagnose → Match and prune → Tradeoff matrix and decision) with the chosen framing as input, then document per step 5.

The output of Diamond 1 is a one-paragraph **chosen framing record** that becomes the input to Diamond 2's diverge step. Without that record, Diamond 2 anchors implicitly on whichever framing came up first in conversation.

### When to enter Diamond 1

Enter the purpose diamond when any of the following hold:

- **(a) Stakeholders disagree on the goal** — different parties describe the problem in incompatible terms (e.g., "this is a performance issue" vs. "this is an API design issue"). Solving any one framing won't satisfy the others, so the framing must be settled before solutions are generated.
- **(b) Prior attempt failed because it solved the wrong problem** — a previous DD or implementation pass produced a working solution that didn't address the underlying need. The failure mode is "we built it, it works, but the original pain remains." Re-running standard DD without re-framing will likely repeat the miss.
- **(c) Diagnose keeps surfacing contradictory constraints** — when running standard DD step 2, the constraint list contains pairs no approach can satisfy simultaneously (e.g., "must support all legacy data" + "must remove all legacy code paths"). Contradictory hard constraints usually signal that two distinct problems are being conflated under one DD.

### When to skip Diamond 1

Skip directly to Diamond 2 (standard DD) when **the problem is concrete and uncontested**: a single owner can state the problem in one unambiguous sentence, no prior attempt has misfired, and step 2's diagnosis converges on a coherent constraint set. Most architectural and library-selection decisions fall here — adding Diamond 1 to a well-scoped problem is ceremony, not clarity.

### Diamond 1 (Purpose) — process

#### 1a. Diverge — generate candidate framings

Generate **6-10 candidate framings** of the problem. Each framing is a one-sentence statement of "what we are actually trying to solve." Requirements:

- Include at least one framing each known stakeholder would recognize as their version of the problem
- Include at least one framing that recasts the problem at a different scale (zoom in to a sub-problem; zoom out to the broader system)
- Include at least one "null" framing — the problem doesn't exist or is already solved elsewhere
- One sentence each, no evaluation yet
- Number them for reference

Apply the **generation health check** from step 1 of the main process, adapted for framings: watch for clustering around one stakeholder's vocabulary, missing perspectives (maintainer's view vs. user's view), and framings too vague to test (a framing must imply at least one falsifiable success criterion).

#### 2a. Diagnose — what would each framing imply?

For each candidate framing, briefly note:

- **Success criterion**: how would we know this problem was solved?
- **Implied solution space**: what kind of approaches does this framing suggest?
- **What it leaves out**: what concerns does this framing fail to address?

This step makes anchoring visible. If two framings have nearly identical success criteria, one is redundant. If a framing's "leaves out" list contains a hard concern from the triggering situation, it cannot be the chosen framing.

#### 3a. Converge — choose one framing

Select the framing that best explains the symptoms that triggered this DD, has a success criterion stakeholders can agree on (or articulate disagreement against), and leaves out the fewest hard concerns. If two framings tie and the choice is unclear, **stop and consult the user** rather than picking silently — the same gate as step 4 of standard DD.

#### Output: chosen framing record

Produce a single one-paragraph record at the end of Diamond 1, in the form:

> **Chosen framing**: [one-sentence statement of the problem]. We selected this over [1-2 alternative framings] because [reason — usually grounded in success criteria or constraint coverage]. Diamond 2 will generate solutions evaluated against this framing; approaches that solve a different framing should be discarded as out-of-scope rather than treated as alternatives.

This paragraph is the *only* artifact passed forward to Diamond 2. It replaces the implicit problem statement that standard DD takes for granted in step 1.

### Diamond 2 (Solution) — proceed with standard DD

With the chosen framing record in hand, run standard process steps 1-4. The framing's success criterion enters step 2 as a hard constraint, and its "leaves out" list defines what's out of scope — candidates that primarily solve a discarded framing are discarded in step 3 rather than evaluated as alternatives. Document the final decision per step 5, and reference the chosen framing record from the decision doc so future readers can see which problem was solved.

### Worked example

See [`docs/working/feature-ideas-round-1.md`](../docs/working/feature-ideas-round-1.md) for a worked Diamond 1: nine candidate framings of "what's missing from the workflow repo," a diagnosis matrix of each framing's success criterion and implied solution space, and the chosen framing record that fed into Diamond 2's candidate generation in [`docs/working/feature-ideas.md`](../docs/working/feature-ideas.md).
