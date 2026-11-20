```markdown
# Situating Record: Specifying roast profiles for Fernhollow's automated drum roaster

**Date:** 2026-11-20

## Decision under situating

Fernhollow Coffee is choosing how to specify roast profiles for its new automated drum roaster. The options are (a) a fixed temperature curve per coffee, (b) a decision table of adjustment rules keyed on bean density and moisture, or (c) a constraint specification the roaster's controller executes directly, with operators locked out of manual adjustment during a batch.

## Situating paragraph

This looks like a choice of specification format, but it is really a **formality decision about knowledge that is currently tacit**. Option (c) aims for formal, machine-computable knowledge. The person who holds that knowledge says she "couldn't write down" why she adjusts a batch, and her assistants learned it by apprenticeship over two to four years. The most load-bearing dimensions are #6 (formality), #5 (reversibility) and #4 (modeling target). Reversibility gets steeply worse at two points: when manual adjustment is switched off, and when Marta reduces to three days a week next spring. After those points, any knowledge the specification failed to capture becomes expensive or impossible to recover. All three criteria measure structure (colour variance, labour ratio, verified compliance). The thing wholesale customers actually pay for is cup quality and consistency, which none of the criteria measure directly, so the receiver has no owner. Option (c) also bundles two separate decisions, formal specification and operator lockout. The lockout removes the mid-batch correction channel ("she knows when it is going wrong") that the current 86.5 average may depend on.

## Dimensional placements

| # | Dimension | Placement | Rationale |
|---|---|---|---|
| 1 | Locus of authority | Today: Centralized (in one person). Target: Mixed. (a)/(c) have Centralized spec with distributed operators; (b) is a shared rule vocabulary applied by operators | The stated goal ("any operator can run any coffee") moves authority from Marta's judgement into a central artifact, but nobody is named to author and maintain that artifact after the six-week elicitation. |
| 2 | Orientation in time | Backward (from the end-state "not dependent on one person"); Process, not Snapshot | The lineup of 38 coffees changes with every harvest, so profiles must be re-derived continually, yet (a) and (c) are framed as one-time per-coffee artifacts written in a single six-week effort. |
| 3 | Search / Compose / Emerge | Today: Emerge (closed-loop sensory adjustment in each batch). (a) Search/fixed pick; (b) Compose; (c) Compose, formal | Marta's practice finds the right roast during the batch from smell, trier colour and the sound of first crack. The controller may not sense several of those signals, so a composed specification may lack inputs that the current method relies on. |
| 4 | Modeling target | Criteria: Structure. Business value: Receiver (cupping score, consistency for wholesale customers) | Colour variance and limit compliance stand in for quality, and nothing in the criteria checks that a compliant batch still cups near 86.5. |
| 5 | Reversibility | Cheap now. Cliffs at (1) manual lockout after week 6 and (2) Marta going part-time next spring. Customer loss is hard to reverse | Each cliff is cheap to cross and expensive to undo, because tacit knowledge that wasn't captured while Marta was full-time cannot be recovered later on demand. |
| 6 | Formality | Actual knowledge: Tacit. (a) Explicit (thin); (b) Explicit; (c) Formal | Option (c) sits on the tacit-to-formal frontier, two steps above where the knowledge currently lives, and plans to cross it in six weeks with an engineer from outside the craft. |
| 7 | Social structure | Expert-led, with a single expert and an apprenticeship pipeline | Marta is the only expert but is not listed as a decider, and the assistants, who are the main future users of whatever is chosen, are absent from the framing. |
| 8 | Legibility | (c): Machine + Stakeholder. (b): Peer + Stakeholder. Today: Self only | Option (c) is designed for the controller and for compliance reporting to management. It is not designed for the operators who will have to notice when a batch is going wrong and explain why. |

## Tensions surfaced

- **Formality vs. the knowledge's actual form.** The plan assumes Marta has "rules" to write down. Her own account is that she has perception and judgement she cannot articulate. Six weeks of elicitation may produce a specification that is formally verifiable but does not encode what made her batches good.
- **Compliance vs. quality (target neglect).** "Controller-verified compliance" proves that a batch stayed within its limits, not that it tasted right. All three criteria are structural, and the receiver-side outcome customers stay for is unmeasured.
- **Lockout bundled with formalization.** Option (c) combines "specify formally" with "remove human correction during a batch." These are separate positions on #1 and #5, and the bundling hides the second choice inside the first.
- **Snapshot spec vs. process reality.** A harvest-driven lineup needs profiles to be re-authored repeatedly. The plan names a one-time authoring effort and no ongoing author, especially after spring.
- **Timeline ordering.** The six weeks of specification writing would mostly happen before the roaster arrives in eight weeks, so the rules would be written without being tested against batches on the actual machine.
- **Sensor gap.** Several of Marta's key inputs (smell, the pitch and pace of first crack) may not exist as controller inputs, which limits what any of (a), (b) or (c) can encode.
- **Dependency framing.** The goal "no longer dependent on one person" is addressed by formalization, but the apprenticeship route (assistants able to run new-harvest batches alone) is a different answer on dimension #7 that the options do not consider.

## Hand-off

This record is a frame, not a decision. It is input to **DD's diagnosis step (step 2)**, so these constraints become testable before candidates are compared:

- **Formality (#6):** state what evidence would show that Marta's judgement *can* be captured, for example by blind-cupping spec-run batches against her batches on the new roaster, before lockout.
- **Reversibility (#5):** decide separately whether to lock out manual adjustment and when. Name the latest safe point given Marta's spring schedule.
- **Modeling target (#4):** add a receiver-side criterion (cupping score floor or consistency as customers experience it) alongside the structural three.
- **Process (#2):** name who re-authors profiles for each new harvest after spring.
- **Social structure (#7):** include Marta and the assistants in framing the constraints. DD should be free to generate hybrid candidates (for example, rules plus operator override with logging) rather than only (a), (b) or (c).
```

The core finding: this is a decision about formalizing tacit knowledge, not a choice of specification format. The plan aims for formal, controller-executed knowledge that the only person who holds it says she can't write down. It also includes a lockout and a part-time transition that make a wrong guess hard to undo, and its criteria never check the cup quality customers pay for.
