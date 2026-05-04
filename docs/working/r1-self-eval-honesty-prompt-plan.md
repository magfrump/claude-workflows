# Plan: Self-eval honesty — surface failure modes before readiness

## Mapping (since the task uses paraphrased prompts)

- "What would make this not work in production?" → **Failure Mode Gracefulness** (currently §5d)
- "Is this ready?" → **Condition for Value** (currently §5c — asks whether the tool's preconditions/infrastructure are met today)

## Change

In `skills/self-eval.md`:

1. Step 5: swap §5c (Condition for Value) and §5d (Failure Mode Gracefulness) so failure modes are answered first. New order:
   - 5a Counterfactual Gap
   - 5b User-Specific Fit
   - 5c Failure Mode Gracefulness  *(was 5d)*
   - 5d Condition for Value         *(was 5c)*
2. Step 6 report template: swap the corresponding `### Failure Mode Gracefulness` and `### Condition for Value` headers in the same way so the saved report mirrors the new evaluation order.
3. Add a one-line note under the Step 5 intro explaining the reorder forces failure modes to surface first (before readiness conditions can rationalize shipping).

## Out of scope

- Renaming the dimensions
- Editing the rubric (`docs/evaluation-rubric.md`) — only `skills/self-eval.md` is in scope per the file-scope constraint
- Reordering automated dimensions in Step 4 (the prompts in question are both human-judgment dimensions)
