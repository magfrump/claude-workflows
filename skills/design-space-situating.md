---
name: design-space-situating
description: >
  Place a proposed design decision onto eight orthogonal dimensions of design technique
  (locus of authority, orientation in time, search/compose/emerge, modeling target,
  reversibility, formality, social structure, legibility) and produce a one-paragraph
  situating record that names what kind of decision this actually is. Use this skill when
  the user asks "what kind of decision is this", "situate this decision", "where does
  this sit in the design space", or "frame this before we choose". Also trigger as a
  sub-procedure when divergent-design surfaces contradictory constraints that no candidate
  can satisfy — contradictory constraints often signal a misframed problem rather than a
  genuine tradeoff. The output record becomes input to DD's diagnosis step (problem
  statement) or RPI's plan step (decision framing); it is a frame, not a decision.
when: User wants to frame a design decision before choosing, or DD/RPI surfaces a misframing signal
---

> On bad output, see guides/skill-recovery.md

# Design Space Situating

You are placing a design decision onto eight orthogonal dimensions of design technique
and producing a one-paragraph record that names what kind of decision this actually is.

You are not making the decision. You are not generating candidates. You are clarifying
the *frame* the decision sits inside, so that whatever follows (DD, RPI, or direct
implementation) operates on the right kind of problem.

The dimensions come from a cross-disciplinary survey of design techniques (visual,
software, instructional, game, generative, pattern-language, participatory). Most
techniques foreground one position on each dimension; most decisions inherit a default
position without realizing they could choose otherwise. The point of this skill is to
make those defaults explicit.

---

## When to use

- **Explicit request.** "Situate this decision", "what kind of decision is this", "where
  does this fit in the design space", "frame this before we diverge".
- **Misframing signal from DD.** When divergent-design's compatibility matrix (step 3)
  shows constraints that no candidate satisfies, or when constraints actively contradict
  each other (e.g., "needs formal verification" + "must support rapid iteration"), pause
  and run this skill. Contradictory constraints often signal that the decision is
  misframed — placing it on the dimensions can reveal which axis the user has assumed a
  position on without choosing it.
- **Implicit defaults in RPI.** When RPI research surfaces a decision that touches social
  structure, temporal commitment, or legibility in ways the user hasn't named, situate
  before planning so the plan reflects what the decision actually is.

---

## Inputs

You need the decision under consideration stated in 1-3 sentences. If the user has
provided more (a research doc, a DD candidate list, a draft plan), read it for context
but treat the stated decision as the unit being situated.

If the user has not stated a decision clearly, ask for one before proceeding. You cannot
situate "we need to do something about caching" — you can situate "we are deciding
whether to introduce a centralized cache layer in front of the API."

---

## The Eight Dimensions

For each dimension, ask the placement question, then ask the "why this matters for your
decision" prompt. Record a placement (one of the named positions, or "mixed" with what
mixes) and one sentence of rationale tied to the specific decision.

### 1. Locus of Design Authority

**Centralized ↔ Mixed (centralized vocabulary, distributed application) ↔ Distributed**

*Placement question:* Will one person or one team hold the whole vision and execute
top-down, will many implementers make local decisions under shared rules, or is there
a centralized vocabulary that distributed implementers compose with?

*Why this matters for your decision:* If you assume centralized authority but the
artifact will be applied by many implementers in different contexts (different teams,
different repos, different timezones), the design will not survive contact with reality.
If you assume distributed authority but no shared vocabulary exists, you'll get
incoherence and slow convergence. Naming the locus tells you whether the artifact
needs a strong central spec, a vocabulary of named moves, or shared local rules.

### 2. Orientation in Time

**Backward-looking ↔ Forward-looking** *and* **Static snapshot ↔ Ongoing process**

*Placement question:* Does the decision start from a desired end-state and work
backward (backward design, JTBD, target architecture), or from current state and
project forward (analysis, interviews, Wardley mapping)? Is the output a finished
artifact you ship and walk away from, or a system that continues to change after
shipping?

*Why this matters for your decision:* The snapshot/process axis is one of the sharpest
fault lines in the design space — most teams default to "static artifact" without
realizing they could choose otherwise, and that default gets baked into review
processes, ownership, and metrics. Backward-looking decisions maintain teleological
coherence but can ignore present reality; forward-looking decisions stay grounded but
can drift. Naming both axes prevents the "we built it, now what?" failure mode.

### 3. How the Solution Space Is Navigated

**Search ↔ Compose ↔ Emerge**

*Placement question:* Are you navigating a pre-existing space of candidate designs
(A/B testing, contradiction matrix, genetic search), authoring within a vocabulary of
named elements and composition rules (patterns, grammars, principles), or seeding
local rules and initial conditions and trusting global structure to crystallize
(piecemeal growth, generative workflows, emergent design)?

*Why this matters for your decision:* Most decisions get framed as "compose" by
default — pick from a vocabulary, follow the rules. But search requires a pre-existing
solution space; compose requires a vocabulary; emerge requires trust that local rules
will produce desired global coherence. Picking the wrong move wastes effort: searching
when no enumerable space exists, composing when no vocabulary is shared, or emerging
when the team needs predictable global properties. This is also the dimension with the
most untapped design space — generative AI is making "emerge" newly viable in places
that defaulted to "compose."

### 4. Primary Modeling Target

**Receiver ↔ Structure ↔ Context**

*Placement question:* Does the decision primarily shape the experience of a receiver
(user, learner, player, downstream system), the internal organization of an artifact
(modules, dependencies, invariants), or the fit with an external environment (social,
temporal, competitive, regulatory)?

*Why this matters for your decision:* Receiver-only produces experiences that don't
scale; structure-only produces elegant things nobody wants; context-only produces
situationally apt things that don't hold together. Most interdisciplinary friction
between designers, engineers, and strategists traces to this dimension — they're
modeling different targets and assuming the others will handle their concerns.
Naming the target lets you check whether the other two are being silently delegated
or silently ignored.

### 5. Reversibility of Commitment

**Cheap to undo ↔ Expensive to undo** (and: how does this gradient evolve over time?)

*Placement question:* How expensive is it to undo this decision one week after it
ships? One month? Six months? Where does the gradient steepen — are there cliff edges
where reversal suddenly becomes much harder?

*Why this matters for your decision:* Cost of a wrong decision = (probability of being
wrong) × (cost to reverse). Techniques that reduce the second factor are often more
valuable than techniques that reduce the first. A decision that is cheap to undo today
but expensive to undo in six months needs more upfront scrutiny than one that is equally
reversible at any point. This is the most underrated dimension in most frameworks —
naming it lets you ask "do we need to commit now, or can we defer this until we know
more?"

### 6. Formality of Knowledge

**Tacit/craft ↔ Explicit/auditable ↔ Formal/computable**

*Placement question:* Is the resulting artifact tacit (you'll know it when you see it,
transmitted by apprenticeship), explicit (heuristics, checklists, principles you can
communicate and check, but require judgment to apply), or formal (mechanically
verifiable by a type system, constraint solver, or proof)?

*Why this matters for your decision:* Aiming above your team's formality budget
produces brittle, performative artifacts (a "formal" spec nobody can maintain). Aiming
below produces unauditable artifacts that depend on whoever wrote them sticking around.
Field maturity correlates with formality — young fields are mostly tacit, mature ones
develop formal methods — so the right level depends on what's already been stabilized
in your domain. The interesting frontier is where tacit knowledge gets made explicit
or explicit knowledge gets formalized; if your decision sits there, expect resistance.

### 7. Social/Participatory Structure

**Expert-led ↔ User-participatory ↔ Community-generated**

*Placement question:* Will specialists design for a population, will users be
co-designers (porous designer/user boundary), or will the artifact emerge from
accumulated community practice with no designated designers?

*Why this matters for your decision:* This is orthogonal to dimension 1 (centralized
vs. distributed authority is about *how many*; this is about *who they are*).
Most techniques implicitly assume expert-led; if your decision is actually
participatory or community-generated, expert-led framing creates the wrong artifacts
(specs nobody contributes to, governance nobody legitimizes). Conversely, if the
decision genuinely needs expert-led framing but you let it drift toward
"community-generated" by default, you get bikeshedding instead of decisions.

### 8. Legibility — To Whom?

**Self ↔ Peer ↔ Stakeholder ↔ Machine**

*Placement question:* Who needs to read the artifact this decision produces — the
author (thinking tool), a peer specialist (efficient within a community of practice),
a non-specialist stakeholder with power over the project, or a machine (processable,
verifiable, executable)?

*Why this matters for your decision:* Most artifacts optimize for one or two audiences
and silently fail at the others. Machine-legible is rarely stakeholder-legible without
a translation layer. Self-legible often fails handoff. Peer-legible artifacts (named
patterns, jargon-dense diagrams) are efficient inside their community but useless to
outsiders, including future maintainers who didn't share the original context. Naming
the audience tells you what translation layers the decision needs to ship — and which
layers will be expensive afterthoughts if they're not designed in.

---

## Process

1. **Read the decision statement.** If it's not stated in 1-3 sentences, ask the user to
   state it. Do not proceed without a concrete decision unit.

2. **Place on each of the eight dimensions.** Walk the dimensions in order. For each:
   ask the placement question, ask the "why this matters" prompt, record a placement and
   a one-sentence rationale tied to *this specific decision*. Use "mixed" only when the
   decision genuinely sits across positions, and name what mixes.

3. **Look for tensions.** After placing all 8, scan for placements that contradict each
   other or contradict the user's stated framing. Common patterns:
   - **Formality–reversibility tension.** High formality + needs to be cheaply reversible
     is a hard ask; the formality-legibility-reversibility triangle is tightly coupled.
   - **Authority–social-structure mismatch.** "Centralized authority" + "user-participatory"
     usually means one of them is wishful framing.
   - **Snapshot–emerge mismatch.** "Static artifact" + "emerge" navigation is contradictory
     — emergence requires ongoing process.
   - **Target neglect.** A decision that names "structure" as the target but the listed
     constraints are all about receiver experience or contextual fit.

4. **Write the situating paragraph.** 3-6 sentences synthesizing the placements into a
   single description of what kind of decision this is. Lead with the most load-bearing
   dimensions (the ones whose placement most constrains downstream choices). Name any
   tensions surfaced in step 3 explicitly.

---

## Output

Produce a Markdown record with three sections:

```markdown
# Situating Record: <decision name>

## Decision under situating
<the user's 1-3 sentence statement, verbatim if possible>

## Situating paragraph
<3-6 sentences naming what kind of decision this is, leading with the most
load-bearing dimensions, and explicitly noting any tensions>

## Dimensional placements

| Dimension | Placement | Rationale |
|---|---|---|
| 1. Locus of authority | Centralized / Mixed / Distributed | <one sentence tied to this decision> |
| 2. Orientation in time | Backward / Forward; Snapshot / Process | <one sentence> |
| 3. Search / Compose / Emerge | Search / Compose / Emerge / Mixed | <one sentence> |
| 4. Modeling target | Receiver / Structure / Context | <one sentence> |
| 5. Reversibility | Cheap / Expensive; gradient note | <one sentence> |
| 6. Formality | Tacit / Explicit / Formal | <one sentence> |
| 7. Social structure | Expert-led / Participatory / Community | <one sentence> |
| 8. Legibility | Self / Peer / Stakeholder / Machine | <one sentence + any translation gaps> |

## Tensions surfaced
- <each contradiction or implicit default that the placements expose, one per bullet>
- <or "None — placements are coherent" if no tensions found>

## Hand-off
This record is a frame, not a decision. It is intended as input to:
- <DD's diagnosis step (step 2) — the constraints become testable>, or
- <RPI's plan step — the decision's actual scope is now named>, or
- <whatever workflow the user is composing this with>
```

---

## Output location

Save to `docs/working/situating-<decision-slug>.md`. Use a kebab-case slug derived from
the decision (e.g., `situating-introduce-cache-layer.md`). If a prior situating record
for the same decision exists, overwrite it — the situating frame can change as
understanding deepens, and stale frames are worse than missing ones.

If `docs/working/` does not exist, create it.

At the end of your chat reply, link to the document and quote the situating paragraph
inline so the user doesn't need to open the file to see the headline result.

---

## Composition with other workflows

- **From DD (misframing trigger):** When DD step 3 (compatibility matrix) shows that no
  candidate satisfies the constraints, or that constraints contradict each other, pause
  DD and run this skill. The situating record either resolves the contradiction (by
  showing one of the constraints was a default rather than a chosen position) or
  confirms it as a genuine tradeoff. In the first case, return to DD with the corrected
  problem statement; in the second, the situating paragraph becomes part of the
  decision's documented framing.
- **To DD:** A situating record produced before DD becomes the seed of DD's diagnosis
  step (step 2). Hard constraints are now visible, and the dimensional placements
  pre-prune candidates that contradict the named placements (e.g., if the placement is
  "expert-led", DD does not need to generate "wiki" candidates).
- **To RPI:** A situating record produced during RPI research becomes part of the plan's
  framing. The plan does not need to re-derive the constraints; it cites the record.
- **From standalone:** A user may invoke this skill on its own when a decision feels
  unclear. The output is still a frame, not a decision — name what comes next (DD, RPI,
  or direct implementation) at the end of the record.

---

## Tone

Diagnostic, not prescriptive. You are not telling the user what to choose on each
dimension — you are surfacing where they have already implicitly chosen, and where
they have not yet chosen. The most valuable findings are usually the dimensions where
the user assumed a default they did not name.

Be concrete. "This is a centralized decision" is not a placement — "this is centralized
because the artifact is a single shared spec maintained by the platform team, even
though it will be applied by 12 product teams" is a placement. Tie every rationale to
the specific decision, not to the abstract dimension.

When a dimension genuinely doesn't apply or doesn't constrain the decision, say so
briefly and move on. Manufactured placements add noise.
