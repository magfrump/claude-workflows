---
Goal: Add a fourth health check to DD step 1 (Diverge) that catches dimensional anchoring — 5+ candidates that all move on the same axis of the decision space.
Project state: r3 round adds dimensional-coverage gap to divergent-design.md generation health check · standalone · not blocked
Task status: complete (fourth check added; both variant references updated to match)
---

## Context

R2 added a generation health check to DD step 1 with three sub-checks: candidate clustering, missing perspectives, and excessive vagueness. R3's task: add a fourth check for *dimensional anchoring* — when 5+ candidates are all distinct but move on the same axis (e.g., all "edit prompt wording", all "add a new step", all "change caching strategy").

The check must:
- Use threshold 5+ (softer signal than the 3+ near-variant clustering, since distinct approaches on one dimension are less obviously redundant than near-variants).
- Name the dimension explicitly using a concrete taxonomy.
- Trigger generation of 1-2 candidates that move on a different dimension.

Concrete taxonomy supplied by the task (multi-agent workflow domain):
- agent text (prompts, instructions, descriptions)
- agent set (which agents exist)
- dispatch order (sequencing, branching, parallelism)
- communication topology (who talks to whom)
- something else (escape hatch)

The "something else" + "for other domains, substitute concrete dimensions" framing keeps the check usable outside multi-agent workflows without losing the "be concrete" force.

## Why this is needed

The existing three checks miss this case:
- Clustering (3+ near-variants) catches *redundancy*, not *axis monoculture*. Five distinct prompt edits aren't near-variants of each other but still leave the structural search space untouched.
- Missing perspectives catches *type-of-approach* gaps (do-nothing, naive, newcomer) but not *dimension-of-change* gaps.
- Vagueness catches under-specified candidates, not over-narrow lever choice.

Dimensional anchoring is a real failure mode in this repo's own DD work (most workflow improvements move agent text; few move dispatch order or topology) — naming the dimension makes the gap actionable rather than vague.

## Plan

1. Add a fourth bullet to the health check sub-list under "Generation health check" (workflows/divergent-design.md:36-44), following the same question → "if so" → action pattern as the existing three bullets.
2. Update the "Done when..." line at line 52 to reference the new check ("…or dimensional anchoring").
3. Update the two variant references to the health check (epistemic variant ~line 178, double-diamond variant ~line 265) so each variant's adapted list also names dimensional anchoring. This prevents drift between the canonical check and its variant adaptations.

### Proposed bullet text (main process)

> - **Dimensional anchoring**: Do 5 or more candidates all change the *same dimension* of the system, even when each candidate is distinct (e.g., five different prompt edits, or five different orderings)? If so, the search has anchored on one lever — approach variety is high but dimension variety is zero. Name the dimension using a concrete taxonomy. For multi-agent workflows: *agent text* (prompts, instructions, descriptions), *agent set* (which agents exist; adding, removing, splitting, merging), *dispatch order* (sequencing, branching, parallelism, iteration), *communication topology* (who reads whose output, shared state, message structure), or *something else* (data formats, triggers, success criteria). For other domains, substitute concrete dimensions — "different architecture" doesn't count. Generate 1-2 candidates that move on a different named dimension.

### Proposed adaptations in variants

- Epistemic variant: "…and dimensional anchoring (5+ hypotheses all about the same causal layer — e.g., all about the database, all about the network, all about caching)."
- Double diamond variant: "…and dimensional anchoring (5+ framings all on the same axis — e.g., all about scope, all about timing, all about ownership)."

## Verification

- Read the file post-edit; confirm the new bullet is the fourth in the health-check sub-list and reads in parallel with the other three.
- Confirm the "Done when" gate at line 52 references the new check.
- Confirm both variant references mention dimensional anchoring with a domain-appropriate adaptation.
- Confirm no other files were modified.
