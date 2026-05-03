---
name: R3 — code-review cross-PR pointer plan
status: in progress
---

# Plan: cross-PR memory pointer in code-review

## Goal

Add a one-line optional input to `skills/code-review.md`'s "Before You Begin" section so the orchestrator can surface a prior review's Must-Fix findings to Stage-2 critics when the current diff touches files reviewed in the prior 30 days.

This extends the R1 within-PR cross-iteration contrastive prompt (`workflows/pr-prep.md` step 3d) to across-PR memory.

## Context

- **R1 precedent:** `feat(pr-prep): add optional cross-iteration contrastive prompt for review-fix loop` (commit `ddcebb2`) added a one-line optional prompt for iteration N≥2 of a single review-fix loop.
- **R3 extension:** the same idea, scaled to PRs that revisit code reviewed earlier — recurring issues should be flagged explicitly rather than re-discovered.
- **Convention:** `docs/reviews/` already exists in projects that use the orchestrated review pipeline. Reports are date- or round-stamped (e.g. `code-review-r2-convergence.md`, `security-review.md`). The rubric file (`code-review-rubric.md`) carries the canonical Must-Fix table.
- **No new infrastructure:** this is a pure read of an existing convention. No mandatory cache, index, or schema change.

## Design

Insert a new step between current Step 2 (Capture PR intent) and Step 3 (Known critic roles). PR intent and prior-review pointer are both context inputs collected upfront and reused in Stage 2 critic dispatch — placing them adjacent groups them naturally.

Renumber existing Steps 3 → 4, 4 → 5, 5 → 6, 6 → 7. The only existing internal reference (line 319: "Before You Begin Step 2" for PR intent) is unaffected because PR intent stays at Step 2.

### New step content

- **Trigger:** diff touches at least one file path that appears in a prior `docs/reviews/*.md` report from the last 30 days. Detect via `git log --since="30 days ago" -- docs/reviews/` plus a quick scan of those reports for `Location:` paths intersecting the changed-file list.
- **Action:** lift Must-Fix rows whose `Location` cites a still-changed file and pass them to each Stage-2 critic prompt under a heading like `## Prior review findings (advisory — worth checking, not verdict input)`.
- **Framing:** advisory only. Critics may use these as hints for what to look at; they MUST NOT treat them as findings to confirm or as inputs to verdicts.
- **Skip silently** when no matching prior reports exist. Optional input — never gates the pipeline.

### Stage 2 integration

Stage 2's per-critic dispatch list currently has 9 numbered items (read skill, paste, scope, PR intent, fact-check, save path, tagging, goal-alignment, launch). Add a brief sub-bullet under the PR intent step (item 4) noting that if Step 3 surfaced prior findings, they get pasted under the advisory heading. This keeps the addition lightweight — one bullet, mirrors how PR intent is integrated.

## Constraints respected

- File scope: only `skills/code-review.md` (plus this plan doc under `docs/working/`).
- Pure additive: no removals, no behavior change to default path (skipped silently when no prior reports match).
- Advisory framing matches the "worth checking, not verdict input" guardrail in the task.

## Verification

After edit, re-read the modified Before You Begin section end-to-end to confirm:
- New step numbering is consistent (1 → 7).
- Internal Step 2 reference (line ~319 originally) still points to PR intent.
- New step is genuinely optional (skip-silently language present).
- Advisory framing is explicit (so a critic reading the prompt cannot mistake it for a verdict input).
