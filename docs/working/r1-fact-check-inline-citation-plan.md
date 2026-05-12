# Plan: fact-check inline citation requirement

## Goal
Require every verdict in `skills/fact-check.md` to carry one of three citation formats:
1. URL with anchor (or section/page-level fragment)
2. A quoted ≤25-word span from the source
3. A `[source: title, page/timestamp]` tag for unlinkable sources (paywalled, offline, etc.)

## Why
Sources are already named with year, but readers cannot reliably trace a verdict to the exact
artifact location. An inline citation gives the reader a way to verify or audit each verdict
without re-running the search.

## Edits to `skills/fact-check.md`
1. **New `## Citation Requirement` section** (placed after `Scrutiny Tags`, before
   `How to handle ambiguity`). Specifies the three formats, when each applies, and the
   ≤25-word cap on quoted spans (to stay within fair-use and force precision).
2. **Update verdict template** in the `Output format` section: add a `**Citation:**` line
   below `**Sources:**` showing the three permitted formats. Update the explanation paragraph
   above the template to reference the new line.
3. **New `## Self-check: citation completeness` section** appended after `Important`.
   States the rejection rule: any verdict missing one of the three citation formats must be
   rewritten before the report is finalized. Lists what to do when no valid citation can be
   produced (move the verdict to Unverified / `[assumed]`).

## Out of scope
- No changes to provenance/scrutiny vocabulary.
- No changes to other skills (code-fact-check.md, draft-review.md) — though they may want
  parallel updates in a follow-up round.

## Verification
- Re-read the modified file end-to-end to check the new section flows with surrounding text.
- Confirm the template example shows the Citation line.
- Confirm the self-check section is unambiguous about the rejection criterion.
