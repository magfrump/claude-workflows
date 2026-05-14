# Plan: business-plan-critique skill + draft-review wiring

## Goal
Add a sixth critic skill, `business-plan-critique`, that applies investor-style lenses (market sizing, unit economics, moat, distribution, competition, timing) to plan-shaped drafts. Wire it into `draft-review.md` so plan-shaped documents auto-dispatch this critic alongside `cowen-critique`/`yglesias-critique` rather than waiting for explicit user invocation.

## Research notes

**Precedent skills.** `skills/cowen-critique.md` and `skills/yglesias-critique.md` share a stable shape:
- YAML frontmatter: `name`, `lens`, `persona-last-sampled`, `description`, `when`, `requires: fact-check`.
- Body: "Pre-flight: Skip Obvious Stubs" → "Using the Fact-Check Report" → "Cognitive Moves" (numbered) → "How to Structure the Critique" → "Output Location" → "Tone".
- Each cognitive move has a short prose description and a concrete example.
- Standalone output saved to `docs/reviews/[critic-name]-critique.md`; orchestrator-dispatched output uses the path the orchestrator specifies.

I'll mirror this shape exactly so the new skill is a drop-in for the same orchestration path.

**Orchestrator coupling.** `skills/draft-review.md` auto-discovers `skills/*.md` files and is biased toward inclusion ("default to **including** any critic that does cognitive work the draft might benefit from"). Known critics are name-dropped in Step 1 ("Known critics include `cowen-critique.md` and `yglesias-critique.md`"). The cheap, idiomatic wiring is to:

1. Add `business-plan-critique.md` to the Known critics list.
2. Add a Selection Disposition paragraph that calls out plan-shaped triggers — when the draft contains pitch-deck sections (TAM/SAM, GTM, pricing, financials, traction), business-plan-critique must be in the panel. This converts the skill from "available but easily skipped" to "default-included for plan-shaped content," which is what the task asks for.

I won't redesign the orchestrator's general selection model — bias-to-include already does most of the work. The targeted addition is a one-paragraph trigger rule.

## Lenses (six cognitive moves)

1. **Market sizing** — top-down vs. bottom-up; check the math; SOM vs. SAM vs. TAM; "1% of a huge market" antipattern.
2. **Unit economics** — CAC, LTV, payback period, gross margin, contribution margin; whether the business compounds or leaks.
3. **Moat** — defensibility sources (network effects, switching costs, IP, scale, brand, regulatory); whether the moat actually holds at scale or only at launch.
4. **Distribution** — who buys, how they're reached, channel economics, sales motion fit; the most common failure mode in good products.
5. **Competition** — named incumbents, adjacent players, alternatives including "do nothing"; competitive response after the plan succeeds.
6. **Timing** — why now? prior attempts, technological/regulatory enablers, demand readiness; the "10 years too early" problem.

Each lens gets a worked example showing the output shape. The task explicitly asks for 2-3 examples per lens — I'll include 2 per lens to keep the file scannable without bloating it.

## Triggers (when this skill fires)

The skill's `description` and `when` fields should match plan-shaped content:
- Pitch decks (problem/solution/market/team/ask structure)
- Business plans (market analysis, GTM, financial projections)
- Financial models (CAC/LTV math, revenue forecasts, burn/runway)
- Vocabulary signals: TAM, SAM, SOM, ARR, MRR, CAC, LTV, payback, moat, defensibility, runway, burn, GTM
- Trigger phrases: "is this fundable", "pressure-test this plan", "would investors buy this", "critique my pitch deck", "stress-test the unit economics"

## Files to modify

- **CREATE** `skills/business-plan-critique.md` — mirrors cowen/yglesias structure.
- **MODIFY** `skills/draft-review.md`:
  - Add `business-plan-critique.md` to the "Known critics include" line under Dependencies.
  - Add a Selection Disposition paragraph for plan-shaped content.

That's the entire diff. No other files need changes.

## Implementation order

1. Write `skills/business-plan-critique.md` (full skill body, six lenses, examples).
2. Wire into `skills/draft-review.md` (two targeted edits).
3. Commit and push.

## Out of scope

- A separate "business plan" workflow file under `workflows/` — not asked for, and the existing draft-review orchestrator covers the entry path.
- Fact-check integration changes — the new critic depends on `fact-check` the same way the others do; no fact-check modifications needed.
- Sampling persona updates — `persona-last-sampled` will be set to today (2026-05-13) but no broader persona-rotation system change.
