# Plan: Hypothesis-source tag taxonomy

Date: 2026-05-03

## Goal

Add a five-value source tag to every hypothesis generated during bug diagnosis:

- `[from error message]` — derived directly from a stack trace, exception text, or assertion message
- `[from log analysis]` — derived from runtime/application/system logs or telemetry
- `[from code reading]` — derived from reading source code, control flow, or data structures
- `[from intuition]` — based on developer hunch, pattern recognition, or "smell" with no concrete evidence
- `[from prior bug]` — analogous to a previously-seen bug in this or a similar codebase

## Rationale

Provenance enables future analysis of which sources produce confirmed root causes. Once tagged, the diagnosis log becomes a dataset: we can ask "do `[from intuition]` hypotheses get refuted more often than `[from error message]` ones?" and tune debugging guidance accordingly. Without provenance the hypothesis log is opaque.

## Files to change

- `skills/bug-diagnosis.md` — Step 3 (Hypothesize) and Output Format
- `workflows/bug-diagnosis.md` — Step 3 (Hypothesize), example hypotheses (worked example), Done-when checklist, diagnosis log template

## Worked example to include

Take the existing parseDate example and tag it `[from error message]` — the hypothesis was built from a `TypeError: Cannot read property 'getTime' of null` stack trace pointing at parseDate. Add a contrasting `[from intuition]` example so readers see both ends of the provenance spectrum.

## Out of scope

No changes to CLAUDE.md's "Debugging defaults" — tag is a process detail, not a default. No retroactive tagging of historical diagnosis logs.
