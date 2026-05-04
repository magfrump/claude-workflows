---
Goal: Add a "Revisit triggers" section to the divergent-design decision-record template, listing concrete conditions (e.g. dep majors, user count >10k, p99 >200ms) that should prompt re-evaluating the decision.
Project state: r1 round delivers a Revisit-triggers requirement to divergent-design.md's step 5 template · standalone · not blocked
Task status: complete (Revisit-triggers section and checklist gates added; body-sections gate enumeration updated)
---

## Context

Round task: extend `workflows/divergent-design.md` step 5 (Document) so the decision record carries an explicit "Revisit triggers" line listing concrete, observable conditions under which the decision should be revisited. This guards against decision rot — a written decision is easy to look at later, but without explicit triggers nobody knows *when* to look at it.

The revisit-trigger entries should be falsifiable and threshold-bearing where possible. Vague triggers like "if requirements change" defeat the purpose. Examples from the brief: "if dep X majors", "if user count >10k", "if p99 >200ms".

## Plan

Single-file edit to `workflows/divergent-design.md` step 5 (lines 133-160). Two changes:

1. Add a new bullet to the body-section enumeration (after the existing **Consequences** bullet, before **Pruned candidates and why**), describing the Revisit triggers section with a `how to read` preamble matching the convention used by Pruned candidates and Stress-test mitigations.

2. Add a "Done when..." checklist entry that gates on the new section being present with at least 2-3 concrete conditions.

Proposed body bullet:

> - **Revisit triggers**: a 2-line section. Line 1 is a `how to read` preamble — "Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply." Line 2 is a compact list of falsifiable conditions with thresholds where applicable, e.g. `if dep X majors. if user count >10k. if p99 >200ms. if [pattern Y] needed in 3+ places.` Vague triggers like "if requirements change" are not allowed — each entry must name a specific signal a future reader could check.

Proposed checklist entry (placed after the Pruned-candidates and stress-test-mitigation gates, before the Task-status gate):

> - [ ] The Revisit triggers section opens with the `how to read` preamble and lists at least 2-3 concrete, threshold-bearing conditions that would prompt revisiting the decision

That is the entire diff. No prose changes elsewhere; no other files touched.

## Verification

- Read the file post-edit; confirm the new body bullet sits between **Consequences** and **Pruned candidates and why**, and the new checklist entry sits adjacent to its peers.
- Confirm the surrounding markdown still parses (bullets and checklists remain well-formed).
- Confirm no other files were modified.
