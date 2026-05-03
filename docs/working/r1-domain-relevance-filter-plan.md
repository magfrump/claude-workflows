# R1 Plan: Domain-relevance filter guidance

## Goal

Add a `Domain-relevance filter` sub-subsection to the `Context curation` section of `patterns/orchestrated-review.md`. Establishes the rule that an orchestrator should slice the diff to the receiving sub-agent's domain rather than pass the whole diff. Guidance only — no router code, no schema changes.

## Why

The existing Context curation section (lines 147-165) explains Include / Exclude / Fallback in terms of *upstream artifacts* (research docs, fact-check findings, prior critic outputs). It also has an anti-pattern about pasting *findings* outside the receiving domain. But the diff itself — the primary input to most code-review-shaped orchestrations — is treated as if the whole-diff dispatch were always the right move. In practice, multi-domain PRs (DB + API + docs) reliably pull a single-domain critic outside its expertise when the dispatch leaves slicing to the sub-agent. Naming the rule and showing one example makes the slicing decision explicit at dispatch time.

## Content

- **The rule (plain prose):** when the receiving sub-agent's domain covers only part of the diff, slice the diff to that part rather than passing the whole thing.
- **Why it matters:** a whole-diff dispatch invites the sub-agent to silently widen its scope or burn prose budget on disclaimers. Slicing at dispatch time is cheaper than asking it to re-filter.
- **How to slice:** pass an explicit path list in the scope spec; instruct the sub-agent to scope its `git diff` to those paths. When the slice cuts across hunks within a single file, fall back to summary-with-link.
- **Empty slice:** skip the dispatch and record "no in-domain changes" in the coverage map rather than dispatching a sub-agent with nothing to evaluate.
- **One worked example:** PR with SQL migration + TS API handler + markdown changelog. `security-reviewer` gets migration + handler. `api-consistency-reviewer` gets handler only.
- **Cross-reference:** one sentence distinguishing this from the existing anti-pattern about pasted *findings* outside the receiving domain (this filters the primary input; that filters cross-critic outputs).

## Placement

New `##### Domain-relevance filter` sub-subsection inside `#### Context curation`, inserted between the anti-patterns bullet block and the closing per-skill-caps paragraph. Heading depth `#####` is one level deeper than the surrounding sub-subsections; this is acceptable because the rule is a calibration of Context curation specifically, not a peer of `Goal preamble` / `Default output cap` / `Legibility-target tagging`.

## Files touched

- `patterns/orchestrated-review.md` (extend §Context curation)

## Out of scope

- Updating `skills/code-review.md` or any other skill to mandate slicing — calibration only; if usage shows skills need an explicit pointer, that's a future round.
- Router code or any new mechanism for computing slices automatically.
- Cross-references from existing anti-patterns up the file (the new section can reference them, but rewriting prior bullets to point down is churn).
