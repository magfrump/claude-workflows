---
name: ai-personas-critique
description: >
  Critique a proposal using 3–4 maximally orthogonal personas selected from a 17-persona AI
  criticism framework. Each persona contributes a focused objection using its signature analytical
  lens. Personas are ordered "closest ally first" — the most sympathetic persona speaks before the
  most skeptical — so objections escalate in intensity. Produces a prioritized synthesis of
  concerns with novelty tagging (flags objections not covered by Cowen or Yglesias critiques).
  Use this skill when the user wants structured multi-perspective pushback on a proposal, plan,
  design, or strategy — especially when they want diverse critical angles beyond economic or
  policy lenses. Also trigger when users say "stress-test this from multiple angles", "what are
  the blind spots", "give me diverse critiques", "who would object to this and why", "red-team
  this proposal", or "what am I not seeing". Works on any proposal type: technical, product,
  policy, organizational, research, or strategic.
when: User wants multi-perspective critique of a proposal from diverse analytical angles
---

> On bad output, see guides/skill-recovery.md

# AI Personas Critique

You are generating a structured multi-perspective critique of a proposal. You select 3–4
maximally orthogonal personas from a 17-persona framework, run each persona's objection in
sequence (closest ally first), then synthesize into prioritized concerns.

You do NOT impersonate these personas. You apply their analytical lenses — their signature
questions, cognitive moves, and habitual blind spots — to generate objections the proposal's
author is unlikely to have considered.

## Persona Definitions

Read the persona definitions from `docs/working/ai-persona-definitions.md` in the project
root. That document defines all 17 personas with their lenses, signature questions, cognitive
moves, and typical blind spots.

If the file is not available, the 17 personas (by name and lens) are:

1. **Empiricist** — evidence quality, inferential validity
2. **Systems Thinker** — feedback loops, emergent behavior, unintended consequences
3. **Historian** — precedent, pattern-matching, institutional memory
4. **End User** — adoption friction, daily experience, real human behavior
5. **Adversary** — attack surface, gaming, perverse incentives
6. **Ethicist** — power dynamics, consent, distributional justice
7. **Operator** — production readiness, failure modes, operational burden
8. **Regulator** — compliance, liability, jurisdictional variance
9. **Economist** — incentive structures, opportunity costs, resource allocation
10. **Scaling Skeptic** — prototype-to-production gaps, coordination costs
11. **Domain Outsider** — naive questions, cross-domain analogies
12. **Incumbent** — existing solutions, switching costs, ecosystem lock-in
13. **Futurist** — technology trajectories, paradigm shifts, obsolescence risk
14. **Minimalist** — essential vs. accidental complexity, core value proposition
15. **Community Voice** — affected populations, stakeholder representation
16. **Maintainer** — long-term sustainability, technical debt, bus factor
17. **Contrarian** — frame inversion, assumption challenging

---

## The Process

### Step 1: Classify the Proposal

Read the proposal and identify:
- **Domain(s):** technical, product, policy, organizational, research, strategic, or hybrid
- **Core claim:** what the proposal asserts will work, and the mechanism by which it works
- **Implicit assumptions:** what the proposal takes for granted without defending

State these briefly (3–5 sentences total) before selecting personas.

### Step 2: Select 3–4 Personas

Choose personas that maximize orthogonality — each should attack from a different analytical
dimension. Selection criteria:

1. **Domain fit:** the persona's lens must be relevant to the proposal's domain. An Operator
   critique of a pure-policy proposal adds little; a Regulator critique of an internal tool
   may be irrelevant.

2. **Orthogonality:** selected personas should span different axes (temporal, scale, stance,
   domain, methodology). Avoid selecting two personas that would make the same objection from
   slightly different angles.

3. **Blind-spot coverage:** prefer personas whose lenses target the proposal's implicit
   assumptions. The best critique comes from the angle the author didn't consider.

4. **Complement, don't duplicate, existing critics:** if the user has already run (or plans
   to run) `cowen-critique` or `yglesias-critique`, avoid selecting personas whose primary
   lens heavily overlaps:
   - Cowen overlaps with: Contrarian (inversion), Economist (market signals), Domain Outsider
     (cross-domain analogy), Historian (contingent assumptions)
   - Yglesias overlaps with: Economist (money tracing), Regulator (political survival),
     Scaling Skeptic (10 million people test), Community Voice (popular version)

   Selecting one partially overlapping persona is fine if it brings a distinct angle. Selecting
   three that all overlap with an existing critic wastes the framework's diversity.

**State which personas you selected and why** (one sentence each). Also state the ordering
(see Step 3).

### Step 3: Order by "Closest Ally First"

Rank the selected personas from most sympathetic to the proposal to most skeptical:

- **Closest ally:** the persona most likely to see merit in the proposal's direction, even if
  they have specific objections. Their critique is constructive refinement.
- **Middle positions:** personas with mixed assessment — they see the problem as real but
  question the mechanism or execution.
- **Furthest critic:** the persona most likely to question whether the proposal should exist
  at all, or whether it's solving the right problem.

This ordering creates an escalating arc: the reader first hears "yes, but fix X" before
hearing "have you considered that the entire framing is wrong?" This makes the critique more
persuasive and actionable — the author isn't immediately defensive.

State the ordering explicitly before running the objections.

### Step 4: Run Each Persona's Objection

For each selected persona, in ally-first order, produce one focused objection:

#### Structure per persona

**[Persona Name] — [Signature Question]**

**Sympathy:** One sentence on what this persona finds promising or correct about the proposal.
Even the furthest critic should acknowledge something.

**Objection:** The core critique, using 2–3 of the persona's cognitive moves (from the
definitions doc). Be specific — reference concrete elements of the proposal, not generic
concerns. The objection should be something the proposal's author probably hasn't considered,
not a restatement of obvious risks.

**Implication:** What follows if this objection is valid? Does it require a design change, a
scope reduction, additional research, or a fundamental rethink?

**Confidence:** How confident is this persona in their objection? (High / Medium / Low). High
means the objection identifies a clear gap; Low means it's a possibility worth investigating
but may not apply.

#### Constraints on objections

- Each objection must be **distinct** from the others. If two personas would raise the same
  point, the second should find a different angle or be replaced.
- Objections must be **specific to this proposal**, not generic advice that applies to any
  proposal. "You should think about scaling" is not an objection. "Your proposal assumes a
  curator reviews each submission, which at 10K submissions/day requires 50 FTEs" is.
- Objections should use the persona's **cognitive moves**, not just invoke the persona's
  general theme. The Historian doesn't just say "check history" — they identify a specific
  precedent and trace which failure modes it shares with this proposal.

### Step 5: Synthesize into Prioritized Concerns

After all persona objections, synthesize into a prioritized list:

#### Priority 1: Likely blockers
Objections rated High confidence that, if valid, would require significant changes to the
proposal. These need resolution before the proposal can proceed.

#### Priority 2: Important uncertainties
Objections rated Medium confidence, or High-confidence objections that require only modest
changes. These should be investigated or addressed but don't block progress.

#### Priority 3: Worth monitoring
Low-confidence objections or concerns that are valid in principle but may not apply to this
specific context. Track these as risks, don't solve them now.

### Step 6: Novelty Check

Compare each objection against what `cowen-critique` and `yglesias-critique` would likely
surface for the same proposal. Tag each concern:

- **Novel:** This objection comes from an analytical angle that neither Cowen nor Yglesias
  methods would produce. The persona's cognitive moves are genuinely orthogonal to the
  economist/policy lenses.
- **Complementary:** This objection touches similar territory as a Cowen/Yglesias move but
  reaches a different specific conclusion or targets a different part of the proposal.
- **Overlapping:** This objection would likely also emerge from a Cowen or Yglesias critique.
  Still valid, but not a unique contribution of this skill.

The novelty check serves two purposes: it helps the user understand which critiques they'd
miss without this skill, and it supports ongoing evaluation of whether the persona framework
adds value beyond the existing critics.

---

## Output Format

Output your critique as a Markdown document with this structure:

```
# AI Personas Critique: [Proposal Title or Summary]

## Proposal Classification
[Domain, core claim, implicit assumptions — from Step 1]

## Selected Personas
[Which 3–4, why, and ally-first ordering — from Steps 2–3]

## Objections

### [Persona 1 — closest ally]
**Sympathy:** ...
**Objection:** ...
**Implication:** ...
**Confidence:** ...

### [Persona 2]
...

### [Persona 3]
...

### [Persona 4 — furthest critic] (if applicable)
...

## Prioritized Concerns

### Priority 1: Likely blockers
...

### Priority 2: Important uncertainties
...

### Priority 3: Worth monitoring
...

## Novelty Assessment
| Concern | Tag | Rationale |
|---------|-----|-----------|
| [Concern from Priority list] | Novel / Complementary / Overlapping | [Why] |

## What the Proposal Gets Right
[Briefly note 1–3 strengths identified across personas. The author needs to know what to preserve.]
```

## Output Location

Save your critique as `docs/reviews/ai-personas-critique.md` in the project root. Create
`docs/reviews/` if it doesn't exist.

If run via an orchestrator (e.g., `draft-review`), follow the orchestrator's output path
instructions instead.

---

## Tone

Direct and substantive. Each persona's objection should feel like it comes from genuine
domain expertise, not from a checklist. Be specific enough that the author can act on the
critique without needing to decode it.

Acknowledge strengths honestly — this is not an exercise in finding fault with everything.
The "closest ally first" ordering should make this natural: the first persona genuinely
appreciates parts of the proposal.

Comfort with uncertainty: tag confidence levels honestly. A Low-confidence objection that
identifies a real possibility is more useful than a fake High-confidence objection that
sounds authoritative but isn't grounded.
