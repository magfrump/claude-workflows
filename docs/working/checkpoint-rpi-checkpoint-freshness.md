# Checkpoint: RPI checkpoint freshness check
Date: 2026-04-28
Branch: feat/r2-rpi-checkpoint-freshness
Research: docs/working/research-rpi-checkpoint-freshness.md
Plan: docs/working/plan-rpi-checkpoint-freshness.md

## Key findings
- The "Continuation of a previous session's work" bullet (line ~297) already tells the reader to verify docs but doesn't say how. Adding the *how* is the whole job.
- Checkpoint template already has `Date:` and `## File map` — both inputs the git log command needs. No schema change required.
- Spike (lines 156-162) and onboarding (lines 237-243) have the canonical pattern: `git log --oneline --since="<date>" -- <paths>` plus a one-sentence interpretation rule.
- RPI working docs are *not* freshness-tracked formally (`guides/doc-freshness.md` line 71). So we reuse the pattern's shape, not its `Last verified` frontmatter.

## Plan
Append a single conditional sentence to the existing "Continuation" bullet:
- Gate on age: "if the checkpoint was written before today"
- Command: `git log --since=<checkpoint Date> -- <files in File map>`
- Interpretation: if commits appear, evaluate whether the plan still applies before continuing.

## Invariants
- Don't add `Last verified` / `Relevant paths` fields to checkpoints (RPI working docs are explicitly excluded from formal freshness tracking).
- Don't change the checkpoint template — fields needed already exist.
- One sentence, not a new subsection.

## File map
- `workflows/research-plan-implement.md` — append freshness-check sentence to the "Continuation of a previous session's work" bullet (step 1)

## Open questions
None.
