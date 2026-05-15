# Scope Exception: Spike Graveyard Log

This round added a new step 1 ("Check the graveyard") to `workflows/spike.md` and renumbered the existing steps 1-6 → 2-7. The renumbering creates one stale external reference outside this round's allowed file scope.

## Stale reference

- **File**: `guides/doc-freshness.md` line 34
- **Current text**: `Spike records: workflows/spike.md step 4 — includes both fields in the spike record template, with a freshness note under "When to reference a spike"`
- **Should become**: `Spike records: workflows/spike.md step 5 — ...`

The "Record the findings" step (which holds the spike record template with `Last verified` / `Relevant paths` fields) moved from step 4 to step 5 in this round.

## Why not fixed here

The file scope constraint for this round permits only `workflows/spike.md`, `docs/thoughts/spike-graveyard.md`, and files under `docs/working/`. `guides/doc-freshness.md` is out of scope.

## Recommended follow-up

A one-line edit to `guides/doc-freshness.md` line 34 (s/step 4/step 5/) closes this gap. Bundle with any future scope that already touches `guides/`.
