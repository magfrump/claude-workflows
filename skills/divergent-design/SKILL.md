---
name: divergent-design
description: >
  Route a tradeoff-bearing design decision into the divergent-design workflow
  (diverge → diagnose → match → decide) instead of open-ended brainstorming. Use this
  skill the moment a creative task resolves to choosing among competing approaches that
  carry tradeoffs — building a feature, structuring a module, or selecting a library where
  more than one option is viable. Trigger phrasings (same surface brainstorming would
  catch): "which approach", "compare options", "compare approaches", "evaluate
  alternatives", "weigh alternatives", "X vs Y", "should we use X or Y", "pick between",
  "choose between", "decide between", "what are the options", "multiple approaches",
  "design choice", "design decision", "tradeoff", "trade-offs", "pros and cons",
  "library selection", "tool selection", "architecture". This skill SUPERSEDES
  `superpowers:brainstorming` whenever the task is a decision among 3+ tradeoff-bearing
  options: brainstorming may auto-fire before plan mode, but if you can name 3+ viable
  options that differ on a tradeoff axis, route here for the structured candidate/matrix
  presentation. Mechanical trigger test: can you name 3+ viable options that differ on a
  tradeoff axis? Yes → this skill. (If the solution space is genuinely open-ended with no
  competing options yet, brainstorming still applies.) This is a thin router — it hands off
  to `workflows/divergent-design.md`, which holds the full process; it does not duplicate it.
when: A creative task has resolved to a choice among 3+ tradeoff-bearing options, and brainstorming would otherwise auto-win
---

> On bad output, see guides/skill-recovery.md

# Divergent Design (router)

This skill exists so divergent design competes at the **skill-selection layer**, where
`superpowers:brainstorming` otherwise auto-wins on any "creative work." It does not
re-implement the workflow — it routes you into it.

## Trigger test (run this first)

Can you name **3+ viable options that differ on a tradeoff axis**?

- **Yes** → this is a decision, not open-ended ideation. Proceed below.
- **No** (the solution space is genuinely open-ended, no competing options exist yet) →
  this skill does not apply; `superpowers:brainstorming` does. Stop here.

When the test passes, divergent design supersedes brainstorming even if brainstorming
already auto-fired: the structured candidate/tradeoff/matrix presentation is the point.

## Hand off to the workflow

Read and follow **`workflows/divergent-design.md`** end to end — it holds the full
process (diverge → diagnose → match → decide), the epistemic and double-diamond variants,
the compact-console output discipline, and the composition rules with RPI, spike, and
systematic-debugging. Do not restate it here; this file is intentionally a stub
(per decision 004, anti-redundancy).

Per that workflow, write the full diverge/diagnose/match prose to `docs/working/dd-{topic}.md`
(or fold it into the calling RPI research doc when DD runs as a sub-procedure), emit only the
compact per-step console lines, and archive the final decision as `docs/decisions/NNN-title.md`.
