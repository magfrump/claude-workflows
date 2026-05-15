---
value-justification: "Replaces ad-hoc architectural debates with structured multi-candidate evaluation, preventing premature commitment to the first idea."
---

# Divergent Design Workflow

*The diverge → diagnose → match → decide structure follows the [orchestrated review pattern](../patterns/orchestrated-review.md), with candidate approaches as the units of parallel evaluation.*

**Problem-framing only?** If the task is to *frame* a contested or unclear problem (not yet to choose a solution), jump to the [Double Diamond (Purpose-First) variant](#variant-double-diamond-purpose-first) and run sections 1a-3a only — the chosen-framing record is the output, and Diamond 2 is skipped.

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
- **Dimensional anchoring**: Do 5 or more candidates all change the *same dimension* of the system, even when each candidate is distinct (e.g., five different prompt edits, or five different orderings)? If so, the search has anchored on one lever — approach variety is high but dimension variety is zero. Name the dimension using a concrete taxonomy. For multi-agent workflows: *agent text* (prompts, instructions, descriptions), *agent set* (which agents exist; adding, removing, splitting, merging), *dispatch order* (sequencing, branching, parallelism, iteration), *communication topology* (who reads whose output, shared state, message structure), or *something else* (data formats, triggers, success criteria). For other domains, substitute concrete dimensions — "different architecture" doesn't count. Generate 1-2 candidates that move on a different named dimension.

If the health check triggers additional generation, note it briefly (e.g., "Added 3-5 after health check flagged clustering around caching approaches"). This makes generation patterns visible across sessions.

**Done when...**
- [ ] At least 8 candidate approaches are listed
- [ ] At least 2-3 approaches feel wrong, naive, or unconventional
- [ ] A "do nothing" or "minimal change" option is included
- [ ] An "ideal if effort were free" option is included
- [ ] No evaluation or ranking has been applied yet — only generation
- [ ] Generation health check passed: no unaddressed clustering, missing perspectives, vague candidates, or dimensional anchoring

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
| **Failure-driven** | What new failure modes does each candidate enable that we haven't enumerated? Where could this break in ways the requirements didn't anticipate? | Use when the cost of an unanticipated failure category is high — security, billing, compliance, regulatory. Unlike push-to-extreme (extending existing logic) or scale test (load on known dimensions), this move enumerates new failure *categories* each candidate introduces. |

Apply 2-4 of the most relevant moves to each surviving approach. Update the tradeoff matrix if the stress test reveals new information — a changed risk rating, a previously unnoticed downside, or a boring alternative that should have been a candidate from the start.

#### Decision

If one approach clearly dominates (>80% confidence): document the decision and proceed.

If the tradeoff is genuinely unclear: **stop and consult the user.** Present the matrix, state your tentative recommendation with reasoning, and identify what information would resolve the ambiguity.

When 2+ surviving candidates score within ~1 cell of each other on the tradeoff matrix, explicitly name the **axis of disagreement** (e.g., "speed vs robustness", "control vs simplicity") and the project's stated preference along that axis. If no stated preference exists, record "no stated preference, picked by tiebreaker rule X" so the buried judgment call is visible and revisitable by future readers.

#### Variant: Trigger-bound decision rule (evidence arrives after commit)

*Invoke this variant when critical evidence will arrive after the commit window* — i.e., when the decision must be made before the information needed to fully evaluate it can be obtained. The variant replaces the step-4 output: instead of selecting a single chosen approach, you produce a **decision rule** of the form *"if X observed → continue; if Y → revisit; if Z → reverse"* that wires the post-commit evidence flow into the decision itself.

This is opt-in. If the trigger below doesn't apply, use the standard step-4 Decision section above and skip this variant entirely — the falsifiable-hypothesis line and step-5 Revisit triggers already cover normal post-decision monitoring.

##### When to engage

Engage the variant when **any** of these hold:

- The decision must be committed before a key piece of evidence is available (e.g., a vendor contract signs before the first month of production traffic; a market-sizing assumption can't be tested until launch).
- The decision is hard to reverse later, but cheap signals that would distinguish "still good" from "wrong call" will arrive during the implementation or rollout window.
- The leading candidate's falsifiable hypothesis (already required by step 4) has its *counter-evidence window* extending past the commit point — so by the time counter-evidence is in, the decision is already locked in unless a rule was set in advance.

If none apply, the problem is a static decision — proceed with the standard Decision section. Most architectural and library-selection decisions fall here; adding a decision rule to a problem whose evidence is already on the table is ceremony, not clarity.

##### Output: the three-branch decision rule

Replace the chosen-approach paragraph with a three-row rule keyed to specific observable signals:

| Branch | Trigger condition | Action |
|--------|------------------|--------|
| **Continue** | [observable consistent with leading hypothesis] within [window] | proceed with chosen approach as planned |
| **Revisit** | [partial / mixed signal] within [window] | re-run step 4 stress-test pass with the new evidence before the next commit gate; decision may stand or shift |
| **Reverse** | [observable contradicting leading hypothesis] within [window] | abandon chosen approach in favor of **[pre-named fallback from step-3 survivors]** |

Two requirements make this rule load-bearing rather than decorative:

- **Each trigger condition is a specific, thresholded observable** — same falsifiability bar as the step-5 Revisit triggers. "If things go badly" is not a Reverse trigger; "if p99 latency exceeds 800 ms for any week" is.
- **The Reverse branch pre-names a specific step-3 survivor candidate** as fallback, not "we'll figure it out then." Pre-naming is the variant's central value: a reversal decision made under post-evidence pressure tends to default to the cheapest fix or the loudest voice, not the best step-3 survivor. Naming it in advance turns the reversal into a binary check rather than a fresh strategic debate.

##### Worked example — software case (build-vs-buy)

Context: choosing between buying a managed analytics SaaS (candidate #2, leading) and building an in-house Kafka + Spark pipeline (candidate #4, step-3 survivor). The vendor contract must be signed before the first month of production traffic, but the buy option's per-event pricing and the build option's necessity only become measurable once real load is observed.

Decision rule:

| Branch | Trigger | Action |
|--------|---------|--------|
| Continue (buy) | First-month event volume within ±25% of vendor's quoted plan **and** p99 ingest latency < 500 ms | Keep vendor through renewal window |
| Revisit | Event volume 25-100% over plan **or** p99 latency 500-800 ms in any week | Re-run step-4 tradeoff matrix with measured numbers before the renewal date |
| Reverse | Event volume sustainedly > 2× plan **or** p99 latency > 800 ms | Exit vendor and implement candidate #4 (Kafka + Spark in-house) before contract renewal |

The Reverse branch names #4 specifically rather than "build something," so when traffic spikes, the team isn't re-litigating which build approach to take under renewal-deadline pressure.

##### Worked example — business case (market sizing assumption)

Context: investing in a premium-tier feature whose business case rests on the assumption that ≥15% of free users will upgrade once the feature ships. The assumption can't be validated until the feature is live; engineering budget for the next quarter must be committed before any conversion data exists. Step-3 survivors included candidate #6 (premium-as-add-on, sold à la carte) and candidate #2 (re-package as free-tier enhancement).

Decision rule:

| Branch | Trigger | Action |
|--------|---------|--------|
| Continue (premium tier) | Upgrade rate ≥ 10% within first 6 weeks of launch | Continue investment per plan; full feature roadmap proceeds |
| Revisit | Upgrade rate 5-10% in first 6 weeks | Re-run step-4 tradeoff matrix considering candidate #6 (premium-as-add-on) before committing next quarter's engineering budget |
| Reverse | Upgrade rate < 5% sustained over 6 weeks | Sunset premium tier; re-enter the feature as a free-tier enhancement (candidate #2) |

Pre-naming #6 as the Revisit fallback and #2 as the Reverse fallback turns "did the upgrade assumption hold?" into a binary check at the quarterly-planning gate, rather than a fresh strategic debate under deadline pressure.

##### How the variant interacts with step 5

When this variant is used, the step-5 decision record's **Decision and rationale** section contains the three-branch table (in place of the single chosen-approach paragraph), followed by a one-line *"Currently operating under: [Continue | Revisit | Reverse]"* status line. The Continue / Revisit / Reverse trigger conditions also enter the **Revisit triggers** section as thresholded entries, so the existing grep convention surfaces them. The chosen-branch line is part of the Task-status drift-check — update it whenever the team transitions across branches.

**Done when...**
- [ ] Each surviving candidate carries a falsifiable hypothesis (expected observable, window, counter-evidence)
- [ ] Each surviving candidate declares a predicted implementation cost — a token estimate or an hour estimate; treat as a soft prediction, not a strict cap
- [ ] At least 2-4 stress-test moves were applied to each surviving approach
- [ ] Tradeoff matrix is updated with any findings from the stress test
- [ ] Either one approach dominates at >80% confidence, or the user has been consulted
- [ ] If 2+ candidates scored within ~1 cell on the tradeoff matrix, the axis of disagreement and the project's stated preference (or the tiebreaker rule used in its absence) are recorded explicitly
- [ ] The chosen approach is stated explicitly with a one-sentence rationale
- [ ] *If the Trigger-bound decision rule variant was engaged*: the decision rule names a specific, thresholded observable for each of Continue / Revisit / Reverse, and the Reverse branch pre-names a specific step-3 survivor candidate as fallback (only fires when the variant trigger applies; default-path decisions skip this gate)

### 5. Document

Create or update `docs/decisions/NNN-title.md`. The doc must begin with the standard three-line header used by RPI working docs (see `workflows/research-plan-implement.md` step 2):

- **Goal**: One sentence — what this artifact is trying to achieve. For a DD decision record, this is the design decision being made.
- **Project state**: One sentence — branch context, written as `<what this branch delivers> · <position in larger initiative, or "standalone"> · <blocked on, or "not blocked">`. When DD is invoked as a sub-procedure within RPI, this is the calling RPI loop's branch context.
- **Task status**: Lifecycle keyword from `in-progress | blocked | paused | complete`, optionally followed by a free-form phase note in parens (e.g., `in-progress (decision drafted, awaiting review)`). The keyword is required; the parenthetical is optional but recommended whenever a phase note would help a re-reader orient.

The header serves the same drift-surfacing purpose described in RPI step 2: every mid-task re-read should re-verify the three lines against reality, and the Task status line should be updated whenever the doc is read or revised. Treat it as required body content — no optional pre-block, no YAML frontmatter, no linter; the spec text is the enforcement.

After the header, the body must include:

- **Context**: what prompted the decision
- **Options considered** (brief — the full analysis doesn't need to be preserved)
- **Decision and rationale**: state the chosen approach and why. End the section with a one-line `See alternatives considered →` pointer to the Pruned candidates section below, so survivors and discarded options have peer prominence rather than the pruned set reading as a footnote.
- **Pruned candidates and why** (anti-portfolio): a 2-line section, placed directly after Decision so it is reachable in ≤2 visual steps from the top of the record. Line 1 is a `how to read` preamble — "Each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches." Line 2 is a compact list, e.g. `[3]: relies on async queue we don't have. [5]: violates auth invariant. [7]: 10x cost of #2.` Include candidates pruned in step 3 (compatibility matrix) and any survivors discarded by the step 4 stress-test pass.
- **Stress-test mitigations** (if any were applied in step 4): one-line `how to read` preamble per mitigation, naming the stress-test move that produced it and what it changed in the tradeoff matrix — e.g., "How to read: *Boring alternative* mitigation — replaced candidate #2 with a simpler variant after the move surfaced unjustified complexity." One preamble per mitigation so a future grep returns enough context to reapply the move without re-reading the full record.
- **Consequences**: what this makes easier, what this makes harder
- **Revisit triggers**: a 2-line section. Line 1 is a `how to read` preamble — "Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply." Line 2 is a compact list of falsifiable conditions with thresholds where applicable, e.g. `if dep X majors. if user count >10k. if p99 >200ms. if pattern Y needed in 3+ places.` Vague triggers like "if requirements change" are not allowed — each entry must name a specific signal a future reader could check.

**Sub-threshold decisions**: Not every decision surfaced during DD warrants a full record. If the diverge phase quickly converges to a single obvious answer — no real tradeoffs, low reversal cost — add a row to [`docs/decisions/log.md`](../docs/decisions/log.md) instead and move on. The log's "when to use" criteria describe the boundary. Reserve full `NNN-title.md` records for decisions with genuine tradeoffs or lasting consequences. The three-line header requirement applies to full records only; sub-threshold log rows are exempt.

**Done when...**
- [ ] Decision record exists in `docs/decisions/NNN-title.md` (or a row in `log.md` for sub-threshold decisions)
- [ ] For full records, the doc opens with the three-line header (Goal · Project state · Task status) and includes all required body sections in order (Context, Options considered, Decision and rationale, Pruned candidates and why, Stress-test mitigations if any, Consequences, Revisit triggers)
- [ ] The Decision and rationale section closes with a `See alternatives considered →` pointer to the Pruned candidates section, so survivors and pruned options have peer prominence
- [ ] The Pruned candidates section is positioned directly after Decision and rationale (reachable in ≤2 visual steps from the top of the record), opens with the `how to read` preamble, and lists every discarded candidate (from step 3 prune and step 4 stress test) with a one-line reason
- [ ] If any stress-test mitigations were applied in step 4, each is documented with its own one-line `how to read` preamble naming the move that produced it
- [ ] The Revisit triggers section opens with the `how to read` preamble and lists at least 2-3 concrete, threshold-bearing conditions that would prompt revisiting the decision
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

Apply the **generation health check** from step 1 of the main process, adapted for hypotheses: watch for clustering around one causal mechanism, missing null hypotheses, explanations too vague to generate testable predictions, and dimensional anchoring (5+ hypotheses all about the same causal layer — e.g., all about the database, all about the network, all about caching).

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
- **Untested ≠ refuted**: a hypothesis whose causal preconditions were never met (feature never deployed, tool never run, predicted trigger never occurred) is **INCONCLUSIVE** — every cell on its row is `?`, not `✗`. Only mark `✗` when evidence was gathered *and* contradicts the hypothesis. Conflating "never tested" with "refuted" inflates the apparent failure rate and feeds misleading signal back into downstream decisions.

Discard hypotheses contradicted by [observed] evidence. Flag hypotheses that depend heavily on [assumed] evidence — these are the ones where gathering more information has the highest value. Do **not** discard INCONCLUSIVE hypotheses; they survive into step 4 with their evidence gap as the primary investigation target.

#### 4. Rank and identify evidence gaps

Instead of a tradeoff matrix and decision, produce a **ranked hypothesis list**:

| Rank | Hypothesis | Confidence | Key supporting evidence | Critical evidence gap |
|------|-----------|------------|------------------------|----------------------|
| 1 | ... | INCONCLUSIVE / high / medium / low | ... | ... |

**Confidence** reflects how well the hypothesis explains all [observed] evidence without relying on [assumed] claims. It is a first-class state with four values:
- **INCONCLUSIVE** — the hypothesis's causal preconditions were never met, so no evidence has been gathered for or against it. Rank these *above* low-confidence refuted hypotheses when prioritizing next investigation steps, because gathering even one piece of evidence yields high information value. Never collapse INCONCLUSIVE into "low" — they are categorically different (untested vs. tested-and-weak).
- **high / medium / low** — evidence has been gathered and the confidence rating reflects how well the hypothesis explains it.

**Critical evidence gap** identifies the single most valuable piece of information that would confirm or refute this hypothesis. This drives the next investigation step. For INCONCLUSIVE hypotheses, the gap is typically the precondition itself (e.g., "deploy the feature and observe for one week").

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

**How to invoke standalone**: if your goal is only problem framing, run sections 1a-3a and stop; the chosen-framing record is the output. Diamond 2 (solution generation) is then deferred or owned by a separate workflow run.

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

**Failure-form framings**: when framing a fix to an observed failure, candidate framings may be stated in failure-form — *the failure is X happening to Y because Z* — and the chosen framing defines which failures are in-scope vs out-of-scope.

**Product-definition-form framings**: when framing what to build rather than what to fix, candidate framings may be stated in product-definition-form — *the product is X serving Y by Z* — and the chosen framing defines which user/job/mechanism are in-scope vs out-of-scope.

Apply the **generation health check** from step 1 of the main process, adapted for framings: watch for clustering around one stakeholder's vocabulary, missing perspectives (maintainer's view vs. user's view), framings too vague to test (a framing must imply at least one falsifiable success criterion), and dimensional anchoring (5+ framings all on the same axis — e.g., all about scope, all about timing, all about ownership).

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
