---
Goal: Add an opt-in Variant block to step 4 of divergent-design.md for decisions where critical evidence arrives after the commit window. Output is a decision rule (if X → continue; if Y → revisit; if Z → reverse) rather than a static decision.
Project state: r1 round delivers a Trigger-bound decision rule variant to divergent-design.md step 4 · standalone · not blocked
Task status: complete (variant block and conditional Done-when gate added to step 4)
---

## Context

Round task: extend `workflows/divergent-design.md` step 4 (Tradeoff matrix and decision) with an **opt-in** variant block addressing the case where critical evidence arrives *after* the commit window. The standard step-4 path assumes the tradeoff matrix can be evaluated now with available information; this variant is for the inverse case.

The variant must:
- Carry an explicit trigger so the default path is untouched for simple decisions.
- Output a three-branch decision rule (Continue / Revisit / Reverse), each branch keyed to a specific observable signal and a pre-named action.
- Include one software worked example (build-vs-buy or vendor lock-in) and one business worked example (market sizing assumption).
- Pre-name the Reverse-branch fallback as a step-3 survivor candidate — that pre-commitment is the variant's central value (avoids deciding under post-evidence pressure).

## Plan

Single-file edit to `workflows/divergent-design.md`. Add a `#### Variant: Trigger-bound decision rule (evidence arrives after commit)` subsection inside step 4, placed after the existing `#### Decision` subsection and before the step-4 `Done when...` checklist. Subsection level matches `#### Stress-test pass` and `#### Decision`, signaling it's a step-4 modifier rather than a full-workflow variant like `## Variant: Epistemic Reasoning` at the end of the file.

The variant block contains:
1. One-paragraph intro with the explicit trigger sentence and what the variant replaces (single chosen approach → three-branch decision rule).
2. **When to use** — 3 bullets, each a concrete condition. Closes with a "skip this variant" line so default-path users opt out cleanly.
3. **Output: the decision rule** — a 3-row Continue/Revisit/Reverse table with column headers (Branch, Trigger condition, Action), plus a one-line constraint that the Reverse branch must pre-name a specific step-3 survivor candidate.
4. **Worked examples** — two short narratives:
   - Software: build-vs-buy for an analytics pipeline (vendor SaaS vs. in-house Kafka+Spark), keyed off event volume and p99 latency.
   - Business: market sizing assumption for a premium tier (upgrade rate threshold), with pre-named fallbacks for the Revisit and Reverse branches.
5. **How it integrates with step 5** — one short paragraph noting the decision record's Decision-and-rationale section becomes the three-branch table plus a "currently operating under: [branch]" line, and that thresholds also enter the Revisit triggers section.

Also add one conditional `Done when...` gate to step 4's checklist: only required when the variant is engaged. Phrasing: "If the variant was engaged (evidence arrives after commit window), the decision rule names specific observable thresholds for each of Continue / Revisit / Reverse, and the Reverse branch pre-names a specific step-3 survivor candidate as fallback."

That gate is conditional so simple-decision cases don't pay the cost — matches the task's "default DD path remains untouched" constraint.

No changes to step 5 prose itself; the integration is described once, inside the variant block, since step 5's existing structure already accommodates the table form (Decision and rationale is free-form text, and Revisit triggers is already a thresholded list).

No other workflow files touched.

## Verification

- Read divergent-design.md post-edit; confirm:
  - The variant subsection appears at `#### Variant: ...` level inside step 4, between `#### Decision` and the `Done when...` block.
  - The explicit trigger sentence ("invoke this variant when critical evidence will arrive after commit window" or equivalent) is present.
  - Both worked examples are present and each names specific thresholds and pre-named fallbacks.
  - The new `Done when...` gate is phrased conditionally (only fires when variant engaged).
  - The existing step-4 flow (tradeoff matrix → stress test → Decision) reads identically — no edits to the default path.
- Confirm markdown parses (tables and bullets well-formed).
- Confirm no other files modified.
