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

## Worked example: parametric vs. sculpted 3D modeling

This example walks all eight dimensions for a real 3D-modeling decision, with the
"why this matters for your decision" prompt instantiated on every dimension. Use it
as a template for situating any 3D-modeling fork (printable vs. real-time mesh,
hand-textured vs. PBR, voxel vs. polygon, etc.).

### Decision under situating

> We are deciding how to author the 3D models for a digitized board game's pieces and
> board components: **parametrically** (geometry defined by numerical parameters and
> constructive solid operations — e.g., OpenSCAD, Blender geometry nodes, Fusion 360
> sketches) or by **sculpting** (direct manipulation of mesh vertices via brushes —
> e.g., Blender sculpt mode, ZBrush). The set spans ~40 game tokens (need precise
> dimensional fit on the board), ~12 hero pieces (need expressive silhouette), and
> ~6 board terrain components.

### Walking the eight dimensions

#### 1. Locus of authority

*Placement question:* Will one modeler hold a master parametric file with all
parameters and others change parameters on demand, or will several modelers each
sculpt their own piece following a shared style guide?

*Why this matters for **this** decision:* Parametric pulls toward centralized — the
parametric definition file becomes the single source of truth, and adding a piece
requires editing it. Sculpted pulls toward mixed — distributed sculpting under a
shared silhouette/proportion vocabulary. If we adopt parametric and the piece set
grows past one author's bandwidth, the parametric file becomes the bottleneck. If we
adopt sculpted with no shared style guide, the 40 tokens drift visually and the set
loses cohesion.

*Placement:* Parametric → centralized. Sculpted → mixed (shared vocabulary +
distributed practice).

*Rationale:* Choice on this dimension determines who gets bottlenecked when the set
grows past the initial scope.

#### 2. Orientation in time

*Placement question:* Are we starting from final piece dimensions (board cell size,
hand-feel target, expected print/render scale) and working backward to a definition
that hits those, or starting with reference art and pushing the form forward until
it looks right? Will we keep iterating after launch (variants, rescaling, expansions)
or freeze and ship?

*Why this matters for **this** decision:* If post-launch iteration is on the roadmap
(stretch-goal expansions, rescale for a deluxe edition, stakeholder-driven art
revisions), parametric keeps that iteration cheap forever — change a parameter,
regenerate, re-export. Sculpted iteration cost rises sharply once UVs and textures
are baked. If the asset is one-shot ship-and-forget, the iteration property is
worthless and sculpting's faster initial creation wins. The board-game roadmap
(expansions are common in this domain) tilts toward "process," not "snapshot."

*Placement:* Parametric → backward + process. Sculpted → forward + snapshot.

*Rationale:* The decision pre-commits us to either an iteration-friendly or
iteration-resistant pipeline.

#### 3. Search / Compose / Emerge

*Placement question:* Are we picking from a catalog of piece archetypes (search),
authoring pieces from a vocabulary of named primitives and operations (compose), or
pushing clay around until form crystallizes (emerge)?

*Why this matters for **this** decision:* Parametric is compose by construction —
CSG primitives, named operations, numerical parameters. Sculpting is emerge — the
final silhouette is discovered, not specified. If our concept brief is fixed
("warrior, mage, archer with these reference sheets"), compose works. If creature
design is being discovered as we go, compose will fight us at every iteration. This
is the dimension most likely to surface a hidden assumption: teams often think they
want "compose" because they want predictability, when the brief actually requires
"emerge" and the predictability they want is a defense against an unfixed brief.

*Placement:* Parametric → compose. Sculpted → emerge.

*Rationale:* Mismatch between the brief's actual specificity and the navigation
move wastes the most time of any dimension here.

#### 4. Modeling target

*Placement question:* Does the piece primarily need to satisfy the user's
tactile/visual experience (receiver), the asset's internal manifold/printability/
topology (structure), or fit with the rest of the game-art context — silhouette
consistency with other pieces, legibility on a small board cell (context)?

*Why this matters for **this** decision:* Parametric over-emphasizes structure —
every dimension is exact, every relationship is enforced, but the artist has to
fight the tool to add expressive character. Sculpting over-emphasizes receiver —
the form looks right, but dimensional drift breaks physical fit on the board.
For 40 game tokens that need to nest precisely on a board grid, structure-first
is essential and sculpt-first will leak millimeters. For 12 hero pieces that
players will inspect up close, receiver-first is essential and parametric-first
will produce technically clean but visually flat models.

*Placement:* Parametric → structure. Sculpted → receiver. Context (silhouette
consistency across the set) is silently delegated either way.

*Rationale:* Whichever target we pick, the other two need an explicit owner — the
context dimension specifically (set-level coherence) is the one most often dropped.

#### 5. Reversibility of commitment

*Placement question:* If we ship the asset and a stakeholder asks "make it 15%
taller" or "swap that flange for a curve" — what does the change cost a week later?
A month later? After UV-mapping and texturing?

*Why this matters for **this** decision:* Parametric: change a number, regenerate,
re-export. Cost stays roughly flat over time. Sculpted: cheap during the active
sculpt session; rises after retopology; rises sharply after UV unwrapping and
texture painting because texture maps are bound to specific topology. The cliff
edge is the retopology step — once you cross it, sculpt-level changes require
redoing every downstream step. For a board-game project that anticipates
playtesting feedback ("piece X is too tall, can't see past it"), the reversibility
gap between the two approaches is the single largest cost difference, and it's the
one teams discover too late.

*Placement:* Parametric → cheap, gradient flat. Sculpted → cheap initially,
expensive after the retopology cliff.

*Rationale:* Cost-of-being-wrong on each piece compounds over a 58-piece set;
this dimension is underrated until the first round of playtest revisions hits.

#### 6. Formality of knowledge

*Placement question:* Is the resulting artifact a formal definition (parameters,
constraints, a constructive program a machine can verify and regenerate), an
explicit-but-judged artifact (a sculpt with a written style guide), or tacit craft
("the artist will know")?

*Why this matters for **this** decision:* Writing a parametric piece definition that
survives parameter changes and stays maintainable is a programming skill, not a
modeling skill — it exceeds many small teams' formality budget. Sculpting is mostly
tacit; if no one on the team has experienced anatomy/silhouette training, the result
will look amateur even if the topology is technically clean. The honest formality-
budget question is: "Do we have someone who can keep maintaining the parametric
definitions six months from now, after the initial author has moved on?" If yes,
parametric pays back over the project's life. If no, the parameters calcify, the
"parametric" file becomes write-once read-never, and we get the worst of both worlds.

*Placement:* Parametric → formal/computable. Sculpted → tacit/craft (with explicit
style guide as a partial bridge).

*Rationale:* Aiming above the team's formality budget produces brittle, performative
artifacts; aiming below produces unauditable artifacts that depend on whoever wrote
them sticking around.

#### 7. Social / participatory structure

*Placement question:* Will pieces be designed by specialists (us), with players as
passive consumers, or do we want users to mod and contribute their own pieces?

*Why this matters for **this** decision:* Sculpting integrates naturally with
existing community asset ecosystems (Sketchfab, Blender's asset library, modder
pipelines on platforms like Tabletop Simulator and Unity Asset Store). Parametric
definitions are harder for non-specialists to extend — they require reading parameter
graphs or code. If our roadmap includes user-generated content or community modding,
parametric raises the participation barrier sharply. If modding isn't on the roadmap,
this dimension is dormant and the choice doesn't matter here.

*Placement:* Both fit expert-led for the initial set. Sculpted has a much more
developed community-generated ecosystem if we want to open the door later.

*Rationale:* This dimension is dormant unless modding is a real goal — but if it is,
parametric pre-commits us against it in a hard-to-reverse way.

#### 8. Legibility — to whom?

*Placement question:* Six months from now, who needs to read the asset and be able
to do something with it — us (self), another 3D modeler joining the project (peer),
an art director or producer who can't open Blender (stakeholder), or the game build
itself (machine)?

*Why this matters for **this** decision:* Parametric is machine-legible (the source
*is* code, the build can regenerate from parameters), peer-legible to other
parametric modelers, but stakeholder-illegible without a rendered preview. Sculpted
is peer-legible (form is its own documentation to another sculptor) and
stakeholder-legible via render, but machine-illegible — the build only sees the
baked output mesh, not the intent. Self-legibility flips between the two:
parametric source can be cryptic in six months ("what does this magic number do?")
unless we commit to good parameter naming and inline notes; a sculpt is visually
self-evident even years later. Picking parametric without budgeting for parameter
documentation pre-commits us to future confusion every time we re-open the file.

*Placement:* Parametric → machine-primary, peer-secondary, stakeholder-needs-render.
Sculpted → peer-primary, stakeholder-via-render, machine-bake-only.

*Rationale:* Translation layers (renders for stakeholders, parameter docs for
future-self) become expensive afterthoughts if not designed in from the start.

### Synthesized output

#### Situating paragraph

This is fundamentally a **navigation-mode decision** (compose vs. emerge) wearing
the costume of a tooling decision. Parametric pulls the project toward centralized
authority, formal/machine-legible artifacts, cheap reversibility, and a
structure-first modeling target — a stack that pays back when the brief is fixed,
the team has parametric/programming fluency, and the asset set will keep iterating
post-launch. Sculpted pulls toward distributed practice under a shared style
vocabulary, tacit/peer-legible artifacts, expensive-after-retopology reversibility,
and a receiver-first modeling target — a stack that pays back when the brief is
exploratory and the team's strength is artistic eye rather than programming. The
most load-bearing dimensions are #3 (compose vs. emerge), #5 (reversibility), and
#6 (formality budget) — placements on these constrain the other five. The
piece-set's heterogeneity (precise tokens vs. expressive heroes) suggests the real
output of this situating may be a *split* decision rather than a single-stack one.

#### Dimensional placements

| Dimension | Parametric | Sculpted | Most load-bearing for us? |
|---|---|---|---|
| 1. Locus | Centralized | Mixed | Medium — scales with set size |
| 2. Time | Backward + process | Forward + snapshot | High — roadmap implies process |
| 3. Search/Compose/Emerge | Compose | Emerge | **Highest** — depends on brief fixity |
| 4. Modeling target | Structure | Receiver | High — pieces split structure-vs-receiver |
| 5. Reversibility | Cheap, flat | Cheap → cliff at retopo | **Highest** — playtest revisions guaranteed |
| 6. Formality | Formal/computable | Tacit/craft | **Highest** — team budget is the gate |
| 7. Social structure | Expert-led | Expert-led or community | Low unless modding is real |
| 8. Legibility | Machine + peer | Peer + stakeholder | Medium — translation layers matter |

#### Tensions surfaced

- **Formality vs. team budget.** Picking parametric without a programmer-modeler on
  the team exceeds the formality budget; the parameters become inert and we end up
  with parametric-in-name-only.
- **Snapshot vs. roadmap.** Picking sculpted while planning post-launch expansions
  accepts a steepening reversibility curve that the roadmap will hit hard at the
  first revision request.
- **Modding contradiction.** Pre-committing to parametric while the roadmap mentions
  user mods is dimension #7 contradicting itself; one of those positions is a
  default rather than a choice.
- **Heterogeneous set.** The piece-set spans high-precision tokens (structure-first)
  and expressive hero pieces (receiver-first). A single-stack decision silently
  picks one and underserves the other; a split decision needs an explicit
  inter-stack interface (e.g., shared scale reference, shared base mesh export).

#### Hand-off

This frame produces sharp candidates for divergent-design:

1. **Pure parametric.** All 58 pieces parametric. Pre-pruned by tension #1 if no
   programmer-modeler is available.
2. **Pure sculpt.** All 58 pieces sculpted with shared style guide. Pre-pruned by
   tension #2 if post-launch iteration is on the roadmap.
3. **Split (parametric tokens + sculpted heroes).** Tokens parametric for fit;
   heroes sculpted for character. Requires explicit interface design (the
   "inter-stack interface" surfaced in tension #4).
4. **Hybrid pipeline (sculpt → retopo → parametric blockout).** Sculpt for
   exploration, then re-author parametrically for downstream control. Requires
   highest team capability and is the most expensive option.

The situating placements pre-prune candidates 1 and 2 against specific tensions, so
DD's diagnosis step starts from a much sharper compatibility matrix than it would
without this frame.

### How to apply this to a different 3D decision

The procedure transfers without modification:

1. State the decision in 1-3 sentences with concrete scope (number of assets, target
   medium, downstream pipeline).
2. For each dimension, instantiate the placement question and the "why this matters"
   prompt against your specific decision — do not stop at the abstract version.
3. Give each placement a rationale tied to the *specific* asset set, not to 3D
   modeling in general.
4. Mark which dimensions are "most load-bearing" — usually 2-3 of the 8 do most of
   the constraining work. The rest are background.
5. Look for tensions before writing the situating paragraph; they often reveal that
   the real decision is a split or a hybrid rather than the binary you started with.

The most useful surprise this skill produces, for 3D decisions specifically, is
recognizing that what looked like a tooling fork is usually a navigation-mode fork
(dimension #3) or a formality-budget fork (dimension #6) — and that the piece-set's
heterogeneity often makes a single-stack answer the wrong shape entirely.

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
