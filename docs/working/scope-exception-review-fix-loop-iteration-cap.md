# Scope exception: pr-prep.md mirrors the soft-ceiling text

## Allowed scope

This task may only modify `workflows/review-fix-loop.md` (plus `docs/working/`).

## Out-of-scope file with inconsistent text

`workflows/pr-prep.md` Step 3e ("Exit or repeat (3-iteration maximum)") currently
contains text that mirrors the soft-ceiling description being removed from
`workflows/review-fix-loop.md`:

> "The user can override the ceiling and say 'continue' — but the default is to
> stop. See `workflows/review-fix-loop.md` § Convergence ceiling for extended
> discussion."

After this task lands, `review-fix-loop.md` will describe a **hard** cap with a
required `escalate | split | abandon` decision before any iteration 4 work, and the
"user can say continue" override will be removed. The pr-prep.md text will then be
inconsistent with its referent.

## Action

A follow-up edit to `workflows/pr-prep.md` should:

1. Replace "The user can override the ceiling and say 'continue' — but the default
   is to stop" with a hard-cap statement aligned with the updated
   `review-fix-loop.md`.
2. Update the section heading and surrounding language so the cap is described as
   hard, not soft.
3. Add the `Iteration N of 3` header expectation to Step 3d (Re-review) or 3e
   (Exit or repeat), wherever it fits most naturally in the procedure.
4. Add the iteration-4 gate (`escalate | split | abandon`) as an explicit
   completion-criteria item under Step 3.

This edit is deferred to a separate change so the current task respects its file
scope constraint.
