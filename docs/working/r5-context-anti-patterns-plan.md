# R5 Plan: Context-curation anti-pattern catalog

## Goal

Extend the `Context curation` sub-section of `patterns/orchestrated-review.md` with a short catalog of recurring concrete mistakes that violate the existing Include / Exclude / Fallback shape. Doc-only, calibrates an existing rule rather than adding a new mechanism.

## Why

Today the section names what to include/exclude in principle (lines 147-157) but doesn't catalog the concrete failures that orchestrator authors keep producing. Naming the failure modes makes the principle easier to apply at the dispatch site — authors recognize their own draft in one of the bullets.

## Anti-patterns to enumerate (5)

1. **Pasted full prior conversation** — the goal preamble exists to replace the user/orchestrator transcript; pasting the transcript anyway re-anchors the sub-agent on already-pruned exploration.
2. **Pasted whole upstream report past cap** — e.g., the full fact-check report when the per-skill rule is "only Incorrect / Stale / Mostly Accurate findings under 200 lines"; the sub-agent then critiques settled findings.
3. **Pasted critic findings irrelevant to this sub-agent's domain** — e.g., performance findings inside a security dispatch; the sub-agent feels obligated to reconcile or anchor on them.
4. **Summarized when the artifact was already small enough to paste verbatim** — paraphrasing a 30-line note into a 50-word summary drops precision (file paths, exact constraint wording) and burns calibration without saving budget.
5. **Omitted the User goal anchor** — dispatch starts at Current task; sub-agent loses the outermost frame and defaults to skill-template output.

## Placement

Inserted as a new `**Anti-patterns**` block immediately after the Include / Exclude / Fallback bullet group (currently ending at line 155) and before the closing per-skill-caps paragraph (currently line 157). Keeps the section flow: principle → shape → known failure modes → calibration note.

## Format

Bulleted list, each entry: bold name → one-sentence "why it fails" → one-sentence fix. Matches the local terse-prose style (no headings, no padding, no separate "Why/Fix" labels — kept inline).

## Files touched

- `patterns/orchestrated-review.md` (extend §Context curation)

## Out of scope

- Changing the Include / Exclude / Fallback bullets themselves.
- Cross-referencing the catalog from individual skill files (e.g., `skills/code-review.md`) — calibration only; if usage shows skills need a direct pointer, a future round.
- Adding new mechanisms (gates, tags, fields).
