---
name: ai-personas-critique
description: >
  Critically review a proposal, design, or argument using dynamically selected AI criticism
  personas. Unlike cowen-critique and yglesias-critique (which apply a fixed voice), this skill
  selects 3-4 maximally orthogonal personas from a catalog of 17 based on the proposal's domain,
  runs each persona's objection, and synthesizes findings. This surfaces concerns that no single
  fixed-perspective critic would raise. Use this skill when the user wants diverse critical
  perspectives on a proposal, when cowen/yglesias perspectives feel too narrow for the subject
  matter, or when the user says things like "what am I missing", "stress-test this from multiple
  angles", "give me diverse critiques", "who would object to this and why", or "poke holes in
  this proposal". Also trigger when reviewing proposals that span multiple domains (e.g.,
  technical + policy + organizational) where a single critic lens would miss important angles.
  NOTE: This skill is designed to complement cowen-critique and yglesias-critique, not replace
  them. Those skills provide deep, consistent voices. This skill provides breadth and surprise.
when: User wants diverse multi-perspective critique of a proposal or design
requires:
  - name: fact-check
    description: >
      A fact-check report covering checkable claims. Without this, factual claims are not
      independently verified — the critique proceeds on argument and design analysis only.
---

> On bad output, see guides/skill-recovery.md

> ## ⚠️ Standalone invocation only — skip if dispatched by an orchestrator
>
> If you were invoked directly by the user (not via `draft-review` or another orchestrator
> that prepends a [goal preamble](../patterns/orchestrated-review.md#goal-preamble) with
> `User goal:` / `Current task:` / `Success criterion:` lines), do this **before**
> producing the critique:
>
> 1. **Capture the user's goal in 1-2 sentences.** State it back to confirm; ask one
>    clarifying question only if the request is genuinely ambiguous.
> 2. **Record it verbatim at the top of the report** as a `**User goal:**` line, alongside
>    the other report header fields (Proposal, Domains, Personas selected, Personas in
>    parallel). The User-goal anchor must persist in the saved artifact so downstream
>    readers and tools see what frame the critique was produced under.
>
> When an orchestrator has already supplied the goal preamble in your dispatch context,
> skip this section entirely — the User-goal anchor is already pinned upstream.

# AI Personas Critique

You are reviewing a proposal using dynamically selected critical personas. Your job is to
surface objections and concerns that a single fixed-perspective critic would miss, by applying
3-4 maximally orthogonal lenses chosen specifically for this proposal's domain and content.

## Pre-flight: Skip Obvious Stubs

If the draft/proposal is under ~500 words AND contains TODO markers or structurally incomplete signals (empty sections, missing thesis/intro, placeholder text), output the single line `draft incomplete; persona pass skipped` and stop — skip the standalone goal-capture block above and all steps below.
Both conditions must hold — legitimately short proposals without stub markers, and longer proposals with stray TODOs, still get the full multi-persona critique.

## Step 1: Read the Persona Catalog

Read `docs/working/ai-criticism-personas.md` in the project root. This file defines 17
personas, each with a core question, domain tags, and a description of the lens they apply.
It also contains orthogonality guidance for selection.

**If the file is missing**, tell the user and fall back to selecting from this minimal set:
Empiricist (evidence), Ethicist (harms), Systems Thinker (feedback loops), End User Advocate
(usability), Scaling Skeptic (scale), Implementation Engineer (feasibility). Apply the
selection logic below using these six.

## Step 2: Analyze the Proposal's Domain

Before selecting personas, identify the proposal's primary and secondary domains:

1. Read the proposal carefully.
2. Assign 2-3 domain tags from the catalog's domain reference table (e.g., "technology",
   "policy", "organizational").
3. Note the proposal's central claim or design decision — this determines which core questions
   are most relevant.

State your domain analysis briefly before proceeding to selection.

## Step 3: Select 3-4 Personas

Select personas that maximize orthogonality — they should attack the proposal from genuinely
different angles, not pile on the same concern from slightly different perspectives.

**Selection algorithm:**

1. **Domain match:** Identify all personas tagged for the proposal's domains. This is your
   candidate pool.
2. **Orthogonality filter:** From candidates, select 3-4 that span the critique dimensions
   defined in the catalog's orthogonality guidance:
   - Evidence vs. values
   - Present vs. future
   - Internal vs. external
   - Builder vs. critic
3. **Wild card check:** If your selected personas cluster on fewer than 3 of the 4 dimensions,
   replace one with the Contrarian (15) or Domain Outsider (16).
4. **Deduplication with pipeline:** If this critique runs alongside cowen-critique or
   yglesias-critique (e.g., via draft-review), avoid personas that substantially overlap with
   those skills. Specifically: skip the Incentive Analyst (6) if Cowen is running (overlaps
   with "follow the money" and market moves). Skip the Opportunity Cost Accountant (12) if
   Yglesias is running (overlaps with mechanism/lever analysis).

**State your selection** with a one-line justification for each persona chosen and which
orthogonality dimensions they cover.

## Step 4: Using the Fact-Check Report

If a fact-check report is provided, use it as your factual foundation. Do not re-verify
claims the fact-checker has assessed. Build on fact-check findings where they inform a
persona's critique (e.g., the Empiricist should reference fact-check verdicts directly).

If no fact-check report is provided, emit this warning before the critique:

> **No fact-check report provided.** Checkable claims have not been independently verified.
> For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

## Step 5: Run Each Persona's Critique

Treat each persona application as a dispatch. The personas run inline in a single pass, but
without an explicit anchor each one drifts toward generic critique within its lens rather
than staying tied to what the user actually asked the orchestration to evaluate. The goal
preamble and Goal-Alignment Note from the [orchestrated-review pattern](../patterns/orchestrated-review.md#goal-preamble)
are how this skill prevents that drift.

For each selected persona, produce a focused critique section. Each section must:

1. **Open with the canonical goal preamble.** Three lines, placed immediately under the
   persona heading:

   ```
   User goal: <captured in the standalone block above, or lifted verbatim from the orchestrator's dispatch>
   Current task: Apply the [Persona Name] lens — [persona's core question] — to this proposal.
   Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
   ```

   The `User goal` line is identical across every persona section in a single run; do not
   paraphrase it. `Current task` and `Success criterion` vary per persona.

2. **Name the persona** and state their core question.
3. **Apply the lens** described in the catalog to the specific proposal. This is not generic
   commentary — ground every observation in specific details from the proposal.
4. **State the objection** clearly: what concern does this persona raise?
5. **Assess severity:** Is this a fatal flaw, a significant weakness, or a point to consider?
6. **Suggest a test or mitigation:** What would address this persona's concern?
7. **Close with a Goal-Alignment Note** using the canonical form from
   [`patterns/orchestrated-review.md`](../patterns/orchestrated-review.md):

   ```markdown
   ## Goal-Alignment Note
   - Answered: [yes / partial / no — one phrase]
   - Out of scope: [what was set aside and why, or "none"]
   - Escalate: [what the synthesis step should action separately, or "nothing"]
   - Questions I would have asked: [1-3 short questions, only if scope was unclear; otherwise omit this bullet]
   ```

   One short bullet per line. No padding. The "Questions I would have asked" bullet is
   optional — include it only when scope was genuinely ambiguous and the persona had to
   make a non-trivial guess (e.g., which audience the proposal targets, or whether to
   evaluate technical feasibility versus organizational feasibility).

Each persona's critique content (steps 3-6) should be 100-200 words. The preamble (step 1)
and Goal-Alignment Note (step 7) are bounded separately by their structure and don't count
against the cap. The goal is focused, specific objections — not exhaustive analysis. If a
persona's lens doesn't reveal anything interesting about this particular proposal, say so
briefly in the critique body and answer `partial` in the Goal-Alignment Note rather than
forcing a critique.

## Step 6: Synthesize

Before writing the synthesis, **scan each persona's Goal-Alignment Note**:

- Any persona whose `Answered:` value is `no` or `partial` — record the persona name and
  the one-phrase reason. These signal that the lens did not fully engage the proposal and
  the corresponding critique should be weighted accordingly.
- Any non-trivial `Out of scope:` item (anything other than `none`) — fold into the blind
  spots discussion below so the user sees what each persona deliberately set aside.
- Any non-trivial `Escalate:` item (anything other than `nothing`) — surface in the synthesis
  alongside the ranked findings so the user can action it separately.
- Any `Questions I would have asked:` bullets — surface under a brief "Questions to clarify"
  note in the synthesis when present, attributed to the persona that raised them. If multiple
  personas asked semantically the same question, list it once.

If a persona's section omitted the note entirely, treat that as a `partial` answer with reason
"missing goal-alignment note" so the gap stays visible.

Then produce the synthesis:

1. **Identifies convergence:** Did multiple personas independently flag the same issue? These
   are the highest-signal findings.
2. **Identifies tensions:** Did personas disagree? (e.g., the Implementation Engineer says
   "this is feasible" but the Scaling Skeptic says "not at scale"). Surface these tensions
   explicitly — they reveal the real tradeoffs.
3. **Ranks findings:** Order by a combination of severity and convergence. A concern raised by
   3 personas at "significant weakness" outranks a single "fatal flaw" finding.
4. **Names the blind spots:** Which critique dimensions (from the orthogonality guidance) are
   NOT covered by the selected personas? What might a persona covering those dimensions say?
   Fold non-trivial out-of-scope items from the goal-alignment scan into this section.

## Output Format

Structure the output as a Markdown document:

```
# AI Personas Critique

**User goal:** [verbatim from standalone capture or orchestrator dispatch]
**Proposal:** [title or one-line summary]
**Domains:** [assigned domain tags]
**Personas selected:** [names with one-line justifications]
**Personas in parallel:** [list any cowen/yglesias critiques running alongside, or "none"]

---

## Persona Critiques

### [Persona Name]: [Core Question]

User goal: [same line as the header field above — paste verbatim]
Current task: Apply the [Persona Name] lens — [core question] — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

[Critique content — 100-200 words, grounded in proposal specifics]

**Severity:** [Fatal flaw | Significant weakness | Point to consider]
**Test/mitigation:** [What would address this concern]

## Goal-Alignment Note
- Answered: [yes / partial / no — one phrase]
- Out of scope: [what was set aside and why, or "none"]
- Escalate: [what the synthesis step should action separately, or "nothing"]
- Questions I would have asked: [optional — omit unless scope was unclear]

[Repeat the persona section, including its preamble and Goal-Alignment Note, for each persona]

---

## Synthesis

### Convergent Findings
[Issues raised by multiple personas]

### Tensions
[Where personas disagree and what tradeoffs that reveals]

### Ranked Concerns
| # | Concern | Raised by | Severity | Convergence |
|---|---------|-----------|----------|-------------|
| 1 | ... | ... | ... | ... |

### Blind Spots
[Uncovered dimensions and what they might reveal, including non-trivial out-of-scope items
collected from each persona's Goal-Alignment Note]
```

## Output Location

Save as `docs/reviews/ai-personas-critique.md`. Create `docs/reviews/` if needed.

When run via an orchestrator, follow the orchestrator's output path instructions instead.

## Differentiating from Cowen and Yglesias Critiques

This skill complements the fixed-voice critics:

- **Cowen-critique** provides deep economic reasoning with consistent cognitive moves (boring
  explanation, market signals, cross-domain analogies). It always applies the same 9 moves.
- **Yglesias-critique** provides deep policy analysis with consistent cognitive moves
  (mechanism demolition, money tracing, election-cycle survival). It always applies the same
  9 moves.
- **This skill** provides breadth: 3-4 perspectives chosen specifically for the proposal at
  hand. It surfaces concerns from angles (security, ethics, scaling, regulation, end-user
  experience) that neither Cowen nor Yglesias would naturally reach.

The value is in the selection mechanism — the same proposal reviewed twice may get different
personas if the domain framing shifts, and proposals in different domains will always get
different persona combinations.

## Tone

Direct and constructive. Each persona should sound distinct — the Security Analyst thinks
differently from the Ethicist, and the critique should reflect that. But the overall posture
is "here are concerns worth addressing," not "here's why this fails." If a persona's lens
reveals a strength, say so.
