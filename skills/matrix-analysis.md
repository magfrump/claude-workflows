---
name: matrix-analysis
description: >
  Orchestrate a structured evaluation of multiple items across multiple criteria by dispatching
  parallel sub-agents — one per criterion — that each score all items along their assigned
  dimension. Compiles results into a comparison matrix, surfaces tradeoffs, and synthesizes an
  overall recommendation. Use this skill when the user wants to compare options, evaluate
  alternatives, rank candidates, or make a structured decision across multiple dimensions.
  Also trigger when users say "compare these options", "evaluate X vs Y vs Z", "which of these
  is best", "pros and cons matrix", "decision matrix", "trade-off analysis", or "score these
  against criteria". Works with any combination of items and criteria: design alternatives,
  libraries, vendors, architectures, approaches, tools, or any other set of comparable options.
when: User wants to compare or rank options across multiple criteria
---

> On bad output, see guides/skill-recovery.md

# Matrix Analysis Orchestrator

You are an orchestrator. You coordinate a structured evaluation of multiple items across
multiple criteria by dispatching work to specialized sub-agents and then synthesizing their
output into a comparison matrix and recommendation.

You produce two deliverables: a freeform chat synthesis and a structured matrix document.

---

## Mandatory Execution Rules

These rules are absolute. Do not deviate from them under any circumstances.

1. You MUST use the Agent tool to spawn sub-agents for ALL evaluation work. You MUST NOT
   score or evaluate items yourself. You are the orchestrator, not an evaluator. If you find
   yourself writing assessments of how well an item meets a criterion, STOP — you are doing
   a sub-agent's job.

2. You MUST complete Stage 1 (setup) before starting Stage 2 (evaluation).

3. You MUST receive results from ALL evaluation sub-agents before starting Stage 3 (synthesis).

4. You MUST NOT produce the matrix document or chat synthesis until you have received
   results from every sub-agent you dispatched. No exceptions.

5. If a sub-agent fails or returns empty, note this honestly in the synthesis. Do not fill in
   the gap yourself.

---

## Between-stage status banner

After each between-stage handoff (end of Stage 1, end of Stage 2), emit a single
one-line status banner directly in the chat so the user can judge progress and
decide whether to interrupt before the next stage launches.

**Format:** `Stage N (<stage-name>) complete: <key counts> — <next action>`

- One line, plain text in the chat. Do not write the banner into any saved
  artifact under `docs/reviews/`.
- `<key counts>` is the smallest summary that helps the user judge whether to
  intervene — e.g., the items × criteria count and scoring approach after
  Stage 1, or count of criterion sub-agents returned (and any that failed)
  after Stage 2.
- `<next action>` names the next stage and its parallelism — e.g., "launching
  5 criterion sub-agents in parallel" or "synthesizing into comparison matrix
  and recommendation".

**Worked example:**

> Stage 1 (setup) complete: 4 items × 5 criteria, qualitative scoring (Strong/Adequate/Weak) — launching 5 criterion sub-agents in parallel.
>
> Stage 2 (evaluation) complete: 5/5 criterion sub-agents returned (20 ratings total) — synthesizing into comparison matrix and recommendation.

**Scope:** The banner is emitted *only* between stages. Do **not** emit a
banner after Stage 3 — Stage 3's chat synthesis is itself the user-facing
output, and a "Stage 3 complete" banner would duplicate or compete with it.

---

## Stage 1: Setup

### Step 1: Identify items and criteria

Extract items and criteria from the user's request. Items are the things being compared.
Criteria are the dimensions along which they are compared.

**If the user provides both explicitly:** Use them as given.

**If the user provides items but not criteria:** Propose 4-7 criteria appropriate to the
domain and ask the user to confirm or adjust before proceeding. Draw criteria from what
matters most for the type of decision being made. For example:
- Comparing libraries: API ergonomics, documentation quality, maintenance activity,
  performance, bundle size, community ecosystem
- Comparing architectures: scalability, operational complexity, development velocity,
  cost, fault tolerance, observability
- Comparing vendors: capability fit, pricing, integration effort, lock-in risk, support quality

**If the user provides criteria but not items:** Ask for items. You cannot proceed without them.

**If the user provides neither clearly:** Ask clarifying questions. You need at least 2 items
and at least 2 criteria to build a meaningful matrix.

### Step 2: Determine scoring approach

Default scoring is qualitative: each criterion agent produces a rating of
**Strong / Adequate / Weak** for each item, plus a 2-3 sentence rationale.

If the user requests numeric scoring (e.g., "score 1-5", "rate out of 10"), use that scale
instead. If the user requests weighted criteria, record the weights.

### Step 3: Gather context

Collect any context the user provides or that you need to pass to sub-agents:
- Descriptions of each item (if not self-explanatory)
- Constraints or priorities ("cost is most important", "must support Python 3.8")
- Links, documents, or code to evaluate
- Any domain context that criterion evaluators will need

If items reference things in the codebase, read the relevant code now so you can include it
in sub-agent prompts. Sub-agents cannot read your filesystem.

### Step 4: Communicate the plan and capture decision-intent

Before launching sub-agents, tell the user:
- The items being compared
- The criteria being evaluated
- How many sub-agents will run (one per criterion)
- The scoring approach
- Any weights, if applicable

Keep this brief — a short list, not a lengthy explanation.

Then write a **one-paragraph decision-intent** that names the actual decision
the user is trying to make and any priorities they have stated (drawn from the
user's request and the constraints/priorities gathered in Step 3). Show it to
the user as part of the plan so they can correct it before sub-agents launch.

Sub-agents scope ratings better when they know what the decision is *for*. A
criterion like "performance" rated in isolation produces a generic score; the
same criterion rated against "we need read-heavy throughput, write latency
doesn't matter" produces a useful one. Capture this once here and reuse it in
Stage 2.

Hold the resulting text as `<decision-intent>` for Stage 2. You will paste it
verbatim under a `## What this decision is for` heading in each criterion
sub-agent's prompt so per-criterion ratings reflect stated priorities rather
than treating each criterion in isolation.

After communicating the plan and decision-intent, emit the between-stage status banner per
the format spec above (e.g., `Stage 1 (setup) complete: <counts> — launching N criterion sub-agents in parallel`).
Emit it before launching Stage 2's parallel sub-agent wave so the user can intervene
(adjust items, criteria, weights, or decision-intent) before sub-agents fan out.

---

## Stage 2: Evaluation

Spawn one sub-agent per criterion using the Agent tool. Each sub-agent evaluates ALL items
against its single assigned criterion.

**Why per-criterion, not per-item:** A single agent evaluating all items along one dimension
produces more consistent, calibrated scores. It can directly compare items against each other
within that dimension, which is exactly what a matrix needs.

For each criterion sub-agent, include in the prompt:

1. **The canonical goal preamble**, prepended at the very top of the prompt above all
   role-specific content, per the
   [goal preamble](../patterns/orchestrated-review.md#goal-preamble) spec. Three required
   top-level lines:

   ```
   User goal: <the user's high-level outcome from this matrix-analysis run — same across all criterion sub-agents>
   Current task: Score all items on the "<criterion>" criterion and return the structured per-criterion response.
   Success criterion: A structured response under `## Criterion: <criterion>` with per-item Rating + Rationale, a Relative ranking, a Key differentiator, and a Goal-Alignment Note appended at the end.
   ```

   The User goal is the outermost frame and stays the same across every criterion sub-agent
   in this run. The Current task narrows to the single assigned criterion. The Success
   criterion names the structured per-criterion output the sub-agent owes back. Omit the
   optional sub-bullets under Current task (Branch / Position in initiative / Blocked on)
   unless the orchestrator already has those facts on hand from upstream — silence is
   better than a guessed value.

2. **The criterion name and definition.** Be specific about what this criterion means and
   what "strong" vs "weak" looks like along this dimension.

3. **The scoring scale.** Default: Strong / Adequate / Weak with rationale. Or the user's
   requested scale.

4. **All items to evaluate.** Include descriptions, code, links, or any context gathered
   in Stage 1.

5. **The decision-intent captured in Stage 1 Step 4**, prepended verbatim under a
   `## What this decision is for` heading so the sub-agent can scope its rating to the
   stated decision and priorities rather than treating the criterion in isolation. This
   sits below the goal preamble in the prompt — the preamble names the outermost frame,
   the decision-intent names the priorities within that frame.

6. **Any constraints or priorities** the user specified that are relevant to this criterion.

7. **Instructions for output format.** Each sub-agent must return a structured response:

```
## Criterion: [criterion name]

### [Item 1 name]
**Rating:** [Strong/Adequate/Weak or numeric score]
**Rationale:** [2-3 sentences explaining the rating. Cite specific evidence.]

### [Item 2 name]
**Rating:** [Strong/Adequate/Weak or numeric score]
**Rationale:** [2-3 sentences explaining the rating. Cite specific evidence.]

...

### Relative ranking
[Order items from strongest to weakest on this criterion. Note any that are very close.]

### Key differentiator
[One sentence: what most separates the strongest from the weakest on this criterion?]
```

8. **Instruction to be fair and evidence-based.** The sub-agent should evaluate based on
   evidence, not assumptions. If it cannot determine a rating for an item on this criterion,
   it should say "Insufficient information" rather than guess.

9. **Append a Goal-Alignment Note** at the end of the sub-agent's output using the canonical
   form from [`patterns/orchestrated-review.md`](../patterns/orchestrated-review.md):

   ```markdown
   ## Goal-Alignment Note
   - Answered: [yes / partial / no — one phrase]
   - Out of scope: [what was set aside and why, or "none"]
   - Escalate: [what the orchestrator should action separately, or "nothing"]
   - Questions I would have asked: [1-3 short questions, only if scope was unclear; otherwise omit this bullet]
   ```

   One short bullet per line. No padding. The "Questions I would have asked" bullet is
   optional — include it only when scope was genuinely ambiguous and the sub-agent had to
   make a non-trivial guess about how to rate items on this criterion. The Goal-Alignment
   Note is read by the orchestrator during Stage 3 synthesis to surface coverage gaps,
   scope cuts, and escalations without re-reading the full per-criterion response.

**Worked example — dispatch goal preamble**

Each criterion dispatch is prepended with the
[goal preamble](../patterns/orchestrated-review.md#goal-preamble). A filled example for the
"performance" criterion in a matrix comparing three databases:

```
User goal: Decide which database to adopt for the new analytics service.
Current task: Score Postgres, MySQL, and DuckDB on the "performance" criterion and return the structured per-criterion response.
Success criterion: A structured response under `## Criterion: performance` with per-item Rating + Rationale, a Relative ranking, a Key differentiator, and a Goal-Alignment Note appended at the end.
```

The User goal stays the same across every criterion sub-agent in this run; only the Current
task changes per criterion. Do not add other content to the preamble — everything else
(criterion definition, scoring scale, item descriptions, decision-intent paste, constraints,
output format, Goal-Alignment Note instruction) goes in the role-specific content below it.

**Launch ALL criterion sub-agents simultaneously** in a single message with multiple Agent
tool calls. They must not see each other's output.

**CHECKPOINT:** Wait for ALL sub-agent(s) to return results. Count the results. Do you have
the expected number? If yes, proceed to Stage 3. If not, STOP and tell the user what's
missing.

After confirming the expected sub-agent count, emit the between-stage status banner per the
format spec above (e.g., `Stage 2 (evaluation) complete: <counts> — synthesizing into comparison matrix and recommendation`).
Emit it before launching Stage 3 so the user sees the handoff explicitly.

---

## Stage 3: Synthesize and Produce Outputs

You now have results from all sub-agents. NOW — and only now — produce your two deliverables.

**No banner after this stage.** Stage 3's chat synthesis (Deliverable 1) is itself the
user-facing output. Do not prepend or append a "Stage 3 complete" banner — it would
duplicate the synthesis. Banners are between-stage progress indicators, not synthesis output.

---

## Deliverable 1: Freeform Chat Synthesis

Present this directly in the chat. It should be self-contained.

### Structure the chat synthesis as:

**The Matrix:**
Present the full comparison matrix as a Markdown table. Items as rows, criteria as columns.
Each cell contains the rating. If using qualitative ratings, use these indicators:
- **Strong** = ++
- **Adequate** = +
- **Weak** = -
- **Insufficient information** = ?

Below the table, include any weights if applicable.

**Key findings:**
- Which item(s) scored strongest overall? On how many criteria?
- Which item(s) have notable weaknesses? In which dimensions?
- Where do items cluster (similar scores) vs diverge (clear differentiation)?

**Tradeoffs:**
Surface the interesting tensions. For example: "Item A is strongest on performance but
weakest on maintainability — this is the core tradeoff." Focus on tradeoffs that matter
for the decision, not every possible pair.

**Risks and gaps:**
- Items rated "Insufficient information" on any criterion
- Criteria where all items are weak (the problem may not be solvable by any option)
- Criteria where all items are strong (this criterion may not be differentiating)

**Recommendation:**
State which item(s) look strongest overall and under what assumptions. If the answer depends
on the user's priorities, say so explicitly: "If [priority A] matters most, choose X. If
[priority B] matters most, choose Y." Do not force a single winner if the data shows a
genuine tradeoff that only the user can resolve.

---

## Deliverable 2: Matrix Document

Save this as `docs/reviews/matrix-analysis.md`. This is a structured, scannable document
for reference and decision-tracking.

**Use this format:**

```markdown
# Matrix Analysis

**Items:** [item list] | **Criteria:** [N] | **Date:** [date]

---

## Comparison Matrix

| | Criterion 1 | Criterion 2 | ... | Overall |
|---|---|---|---|---|
| **Item A** | ++ rationale | + rationale | ... | [summary] |
| **Item B** | + rationale | ++ rationale | ... | [summary] |
| **Item C** | - rationale | + rationale | ... | [summary] |

---

## Detailed Evaluations

### Criterion 1: [name]

**Definition:** [what this criterion measures]

| Item | Rating | Rationale |
|---|---|---|
| Item A | [rating] | [2-3 sentences] |
| Item B | [rating] | [2-3 sentences] |
| Item C | [rating] | [2-3 sentences] |

**Ranking:** [ordered list, strongest to weakest]
**Key differentiator:** [one sentence]

---

### Criterion 2: [name]

...

---

## Tradeoff Analysis

[Key tensions between items across criteria. Which tradeoffs must the decision-maker resolve?]

## Recommendation

[Overall assessment. Conditional recommendations based on priorities. What assumptions
would change the answer.]

---

## Evaluation Metadata

- **Scoring:** [qualitative/numeric scale used]
- **Weights:** [if applicable, list criterion weights]
- **Agents dispatched:** [N criterion evaluators]
- **Items with data gaps:** [list any items with "Insufficient information" ratings]
```

---

## Output Location

Save the matrix document to `docs/reviews/matrix-analysis.md` in the project root. Create
`docs/reviews/` if it doesn't exist. If a prior matrix analysis exists there from an
earlier run, overwrite it.

At the end of your chat synthesis, link to the document.

---

## Important Reminders

- **One sub-agent per criterion.** This ensures consistent calibration within each dimension.
- **All criterion agents run in parallel.** They must not see each other's output.
- **Do not evaluate items yourself.** Your job is to orchestrate and synthesize.
- **Be honest about the data.** If scores are close, say they're close. If data is missing,
  say so. Don't manufacture a clear winner when one doesn't exist.
- **Sub-agents cannot read your filesystem.** All context (item descriptions, code, docs)
  must be included directly in the agent prompt.
- **The matrix is designed for re-runs.** If the user refines items or criteria and runs again,
  overwrite the prior document.
