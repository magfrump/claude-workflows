---
Goal: Add a required "cost-of-deferral grows by X per Y" line to every tech-debt-triage item, with example phrasings.
Project state: r3 round delivers a quantitative deferral-growth line to skills/tech-debt-triage.md · standalone · not blocked
Task status: complete (cost-of-deferral line required in framework, single-item template, multi-item table; example phrasings + don't-fabricate guardrail added)
---

## Context

Each tech-debt-triage item should make the *rate* at which carrying cost grows explicit
and quantitative. Today, the framework mentions "Compounding" as a sub-bullet under
Carrying Cost ("Is the cost growing linearly or exponentially?") but does not require a
concrete rate. Without a rate, "fix opportunistically" vs "carry intentionally" comes down
to gut feeling. With a rate, the recommendation has a defensible deadline ("at +1 file/week,
this becomes a 10-file refactor in 10 weeks").

The line goes on every item — including a `+0 — inert` answer when growth is genuinely
flat. Honest zero is a feature, not an analysis failure.

## Plan

Three edits to `skills/tech-debt-triage.md`:

1. **Framework section 1 (Cost of carrying)**: Replace the existing "Compounding" bullet
   with a stronger "Cost of deferral" bullet that *requires* a quantitative rate, lists
   example phrasings, and explicitly permits `+0 (inert)` when honest. Keep the
   High/Medium/Low rating sentence underneath.

2. **Single-item output template**: Add a `**Cost of Deferral:**` line directly under
   `**Nature:**`, with placeholder showing the `+X per Y` format.

3. **Multi-item table**: Insert a "Cost of Deferral" column between "Carrying Cost" and
   "Fix Cost". Update the example rows to show varied rates (`+1 file/week`, `+0 inert`,
   `+1 person/quarter`).

4. **Important section**: Add one bullet warning against fabricating compounding — "+0
   (inert)" is the right answer for stable debt.

## Verification

- Read the file post-edit; confirm the new line appears in the framework, the single-item
  template, and the multi-item table.
- Confirm at least 4 example phrasings are listed (file-spread, knowledge erosion, scope
  creep, zero-growth).
- Confirm no other files modified beyond `skills/tech-debt-triage.md` and this plan doc.
- Existing bats tests in `test/skills/tech-debt-triage-format.bats` (out of scope for edits)
  do not check for the new line, so they will not regress.
