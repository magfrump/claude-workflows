---
name: divergent-design
description: >
  Route a decision among 3+ tradeoff-bearing options into workflows/divergent-design.md;
  supersedes open-ended brainstorming. Test: can you name 3+ viable options that differ on a
  tradeoff axis? If not, brainstorming applies. Triggers: "which approach", "X vs Y", "should we
  use X or Y", "compare options", "pros and cons", "tradeoff", "design decision", "library
  selection", "architecture".
when: A creative task has resolved to a choice among 3+ tradeoff-bearing options, and brainstorming would otherwise auto-win
---

> On bad output, see guides/skill-recovery.md

# Divergent Design (router)

Exists so divergent design competes at the **skill-selection layer**, where open-ended
brainstorming otherwise wins by default on any "creative work." Does not re-implement the
workflow — routes into it.

## When to use

Use the moment a creative task resolves to choosing among competing approaches that carry tradeoffs: building a feature, structuring a module, or selecting a library where more than one option is viable.

Trigger phrasings (the same surface brainstorming would catch): "which approach", "compare options", "compare approaches", "evaluate alternatives", "weigh alternatives", "X vs Y", "should we use X or Y", "pick between", "choose between", "decide between", "what are the options", "multiple approaches", "design choice", "design decision", "tradeoff", "trade-offs", "pros and cons", "library selection", "tool selection", "architecture".

## Trigger test (run this first)

Can you name **3+ viable options that differ on a tradeoff axis**?

- **Yes** → decision, not open-ended ideation. Proceed below.
- **No** (solution space genuinely open-ended, no competing options yet) →
  skill does not apply; open-ended brainstorming does. Stop here.

When the test passes, divergent design supersedes brainstorming even if brainstorming
already auto-fired: the structured candidate/tradeoff/matrix presentation is the point.

## Hand off to the workflow

Read and follow **`workflows/divergent-design.md`** end to end — it holds the full
process (diverge → diagnose → match → decide), the epistemic and double-diamond variants,
the compact-console output discipline, and the composition rules with RPI, spike, and
systematic-debugging. Do not restate it here; this file is intentionally a stub, so
the router and the workflow cannot drift apart.

Per that workflow, write the full diverge/diagnose/match prose to `docs/working/dd-{topic}.md`
(or fold it into the calling RPI research doc when DD runs as a sub-procedure), emit only the
compact per-step console lines, and archive the final decision as `docs/decisions/NNN-title.md`.
