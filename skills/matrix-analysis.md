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
---

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

### Step 4: Communicate the plan

Before launching sub-agents, tell the user:
- The items being compared
- The criteria being evaluated
- How many sub-agents will run (one per criterion)
- The scoring approach
- Any weights, if applicable

Keep this brief — a short list, not a lengthy explanation.

---

## Stage 2: Evaluation

Spawn one sub-agent per criterion using the Agent tool. Each sub-agent evaluates ALL items
against its single assigned criterion.

**Why per-criterion, not per-item:** A single agent evaluating all items along one dimension
produces more consistent, calibrated scores. It can directly compare items against each other
within that dimension, which is exactly what a matrix needs.

For each criterion sub-agent, include in the prompt:

1. **The criterion name and definition.** Be specific about what this criterion means and
   what "strong" vs "weak" looks like along this dimension.

2. **The scoring scale.** Default: Strong / Adequate / Weak with rationale. Or the user's
   requested scale.

3. **All items to evaluate.** Include descriptions, code, links, or any context gathered
   in Stage 1.

4. **Any constraints or priorities** the user specified that are relevant to this criterion.

5. **Instructions for output format.** Each sub-agent must return a structured response:

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

6. **Instruction to be fair and evidence-based.** The sub-agent should evaluate based on
   evidence, not assumptions. If it cannot determine a rating for an item on this criterion,
   it should say "Insufficient information" rather than guess.

**Launch ALL criterion sub-agents simultaneously** in a single message with multiple Agent
tool calls. They must not see each other's output.

**CHECKPOINT:** Wait for ALL sub-agent(s) to return results. Count the results. Do you have
the expected number? If yes, proceed to Stage 3. If not, STOP and tell the user what's
missing.

---

## Stage 3: Synthesize and Produce Outputs

You now have results from all sub-agents. NOW — and only now — produce your two deliverables.

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
