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

# AI Personas Critique

You are reviewing a proposal using dynamically selected critical personas. Your job is to
surface objections and concerns that a single fixed-perspective critic would miss, by applying
3-4 maximally orthogonal lenses chosen specifically for this proposal's domain and content.

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
orthogonality dimensions they cover. Then list 2-3 personas considered but not selected with
a one-line reason each (e.g., redundancy with another pick, weaker domain fit, dimension
already covered) — cap this section at 3-4 lines total to aid auditability across re-critiques
without bloat.

## Step 4: Using the Fact-Check Report

If a fact-check report is provided, use it as your factual foundation. Do not re-verify
claims the fact-checker has assessed. Build on fact-check findings where they inform a
persona's critique (e.g., the Empiricist should reference fact-check verdicts directly).

If no fact-check report is provided, emit this warning before the critique:

> **No fact-check report provided.** Checkable claims have not been independently verified.
> For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

## Step 5: Run Each Persona's Critique

For each selected persona, produce a focused critique section. Each section should:

1. **Name the persona** and state their core question.
2. **Apply the lens** described in the catalog to the specific proposal. This is not generic
   commentary — ground every observation in specific details from the proposal.
3. **State the objection** clearly: what concern does this persona raise?
4. **Assess severity:** Is this a fatal flaw, a significant weakness, or a point to consider?
5. **Suggest a test or mitigation:** What would address this persona's concern?

Each persona's section should be 100-200 words. The goal is focused, specific objections —
not exhaustive analysis. If a persona's lens doesn't reveal anything interesting about this
particular proposal, say so briefly and move on rather than forcing a critique.

## Step 6: Synthesize

After running all persona critiques, produce a synthesis that:

1. **Identifies convergence:** Did multiple personas independently flag the same issue? These
   are the highest-signal findings.
2. **Identifies tensions:** Did personas disagree? (e.g., the Implementation Engineer says
   "this is feasible" but the Scaling Skeptic says "not at scale"). Surface these tensions
   explicitly — they reveal the real tradeoffs.
3. **Ranks findings:** Order by a combination of severity and convergence. A concern raised by
   3 personas at "significant weakness" outranks a single "fatal flaw" finding.
4. **Names the blind spots:** Which critique dimensions (from the orthogonality guidance) are
   NOT covered by the selected personas? What might a persona covering those dimensions say?

## Output Format

Structure the output as a Markdown document:

```
# AI Personas Critique

**Proposal:** [title or one-line summary]
**Domains:** [assigned domain tags]
**Personas selected:** [names with one-line justifications]
**Personas in parallel:** [list any cowen/yglesias critiques running alongside, or "none"]

---

## Persona Critiques

### [Persona Name]: [Core Question]

[Critique content — 100-200 words, grounded in proposal specifics]

**Severity:** [Fatal flaw | Significant weakness | Point to consider]
**Test/mitigation:** [What would address this concern]

[Repeat for each persona]

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
[Uncovered dimensions and what they might reveal]
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
