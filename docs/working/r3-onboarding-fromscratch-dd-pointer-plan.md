# R3: From-scratch DD pointer in onboarding skip-output (v3)

**Status:** in-progress

## Context

R2's v2 introduced a redirect *step* and was rejected on self-eval as too heavy. v3 is qualitatively smaller: a single optional sentence inside existing skip-output prose. No new step, no mandatory redirect.

## Change

In `workflows/codebase-onboarding.md`, step 3 ("Inventory the execution surface"), inside the skip-output explanation block (around lines 138–148), add exactly one sentence:

> When the skip fires on a from-scratch project, the orientation doc may instead use DD's Double Diamond variant (sections 1a-3a) to produce a problem-framing record before architecture concerns exist.

## Placement

Immediately after the two skip-note example bullets and before the "Partial-skip rule" paragraph. It reads as a continuation of the skip-output explanation, attached to the from-scratch example. No new heading; no procedural language ("must"/"should") — the sentence uses "may" to remain optional.

## Why this placement

- Adjacent to the from-scratch example that the sentence references.
- Inside the same skip-output explanation block — meets the "inside existing prose" constraint.
- Before the partial-skip rule, which is a distinct concern, keeping the partial-skip prose unbroken.

## Done when

- Sentence appears verbatim in `workflows/codebase-onboarding.md`.
- No other edits to the file.
- Commit + push.
