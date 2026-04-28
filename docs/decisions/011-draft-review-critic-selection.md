# 011: Draft-Review Critic Selection — Sequence Description Fix Before Rubric Reframe

**Date:** 2026-04-27
**Status:** Accepted (shipped 2026-04-27)

> **Implementation note:** Items #1 and #2 (description fix and disposition flip)
> shipped together in the same session, skipping the proposed evaluation gate
> between them. The original sequencing was conservative; both changes are small
> and easily revertible, so the gate was deemed unnecessary in retrospect.

## Context

A 2026-04-27 draft-review run on a written essay ("Shape of the Interaction")
skipped `yglesias-critique` during Step 2 selection. On user request it was
added as a retrofit run and produced three high-signal new findings (boring-lever
alternatives, no-defending-constituency frame, popular-version alternative
thesis), reaching 3-critic convergence on three rubric items. The miss was
expensive — the retrofit pattern is unsupported by the orchestrator and
required manual prompting to avoid duplicate work.

Root cause is two-layer:

1. `draft-review.md` Step 2 frames selection as topic-matching ("policy,
   technology, culture, economics") with a default-exclude disposition ("if
   some are clearly irrelevant, skip them").
2. `yglesias-critique.md`'s description anchors on policy keywords ("policy
   feasibility", "institutional capacity", "cost disease", "supply-side
   thinking", "political viability"). Trigger phrases are policy-coded.

Combined, the orchestrator treats "is this a policy piece?" as a yes/no gate
on Yglesias. But Yglesias's distinctive moves (agree-with-goal-demolish-mechanism,
boring lever, follow the money, scale test, org chart, popular version) operate
on **proposed mechanisms in service of stated goals** — they apply to any
proposal, not only government policy.

The accompanying revision notes (`private_reviews/docs/working/critic-selection-revision-notes.md`)
proposed four edits and five adjacent issues. This decision records the result
of pressure-testing those edits via divergent design.

## Options considered

Evaluated via divergent design (14 candidates, 11 survivors after match-and-prune):

1. Kind-of-work rubric + default-include (notes' Edit 1)
2. Inline worked example after Step 3 (notes' Edit 2)
3. Always run every critic (no selection)
4. Justify exclusions, not inclusions
5. Critic self-selection — *discarded* (violates orchestrator-decides rule)
6. Adversarial double-check before launch
7. Explicit classification step
8. User-confirmed selection
9. First-class retrofit-run support
10. Disposition preamble
11. Post-hoc audit step after synthesis
12. Do nothing in `draft-review.md`; fix only critic descriptions
13. Worked-example bank — *discarded* (maintenance overhead vs. inline example)
14. Cost-budget framing

The full diverge / diagnose / matrix / stress-test work lives in the chat
record from this session.

## Decision

Sequence the changes rather than ship them as a bundle:

1. **First:** Fix the `yglesias-critique.md` description (notes' Edit 3). The
   orchestrator was reading a description that anchored on policy keywords;
   this is the root cause. Rewrite the description to lead with "any draft
   that *proposes a mechanism*" and frame government policy as a special case
   of the broader pattern.
2. **Second (after evaluating effect of #1):** Add a disposition flip to
   `draft-review.md` Step 2 — change default-exclude to default-include for
   cognitive critics that run in parallel. Optionally add a top-level
   disposition preamble (candidate 10) to set the frame globally.
3. **Defer:** The full kind-of-work taxonomy (rest of notes' Edit 1) and the
   inline worked example (Edit 2). Wait to see whether the description fix
   plus disposition flip catches the next near-misfire. If a different
   critic gets misfired-on, the new pattern will inform what taxonomy
   actually fits.
4. **Add separately when convenient:** Retrofit-run support (notes' Adjacent E,
   candidate 9). Different bug, real but minor.
5. **Don't add:** Adversarial double-check (#6) and post-hoc audit (#11). They
   add latency or compute for a class of problem that better selection upfront
   should reduce.

## Rationale

Two findings from the stress test changed the picture:

**Edit 1 is doing two things at once.** The disposition flip (default-include)
and the kind-of-work taxonomy are independently shippable. The flip is the
higher-value half — it directly counters the default-exclude behavior that
caused the miss. The taxonomy is more speculative: it might age, might
over-fit to the current critic mix, and risks ossifying around axes that
later critics don't fit. Shipping them separately lets us validate the
cheaper change before committing to the more invasive one.

**Edit 1 alone may be over-correction without Edit 3.** The orchestrator
read the description and applied the rubric correctly given that input.
Even a perfect rubric loses to a misleading description. The description
is the load-bearing input for selection; fixing the rubric without fixing
the description leaves the structural cause intact. Fixing the description
without fixing the rubric likely catches this case (and similar future
cases) on its own.

Sequencing also creates an evaluation opportunity: after the description
fix lands, the next draft-review run is a natural test of whether the
rubric reframe is still needed.

## Consequences

- **Easier:** The minimal change (description fix) is single-file,
  frontmatter-only, low-risk. The disposition flip is ~10 lines in one file.
  Both can be evaluated independently.
- **Harder:** Two-step rollout means the full notes proposal isn't applied
  in one pass. The kind-of-work taxonomy may eventually be needed and
  deferring it costs a future round of editing.
- **Future work:** If the description-only fix proves insufficient (another
  critic gets misfired-on for a different reason), revisit candidates 1, 7,
  and 14 (kind-of-work rubric, explicit classification step, cost-budget
  framing) with concrete data on what kinds of misfires happen.
- **Adjacent issue worth tracking:** Skill descriptions across the board may
  be written for human invocation rather than orchestrator selection (notes'
  Adjacent B). Worth scanning all skill descriptions during a later pass to
  check whether they describe *what the skill does cognitively* or *what
  topics it covers* — the former is more selection-stable.
