# Plan: sync codebase-onboarding 'When to use' with H-07 reframe

## Goal
Update `workflows/codebase-onboarding.md` "When to use" section so it
explicitly names the **acquired-familiarity** trigger (inherited codebase,
returned-cold project) and contains a one-line explicit non-trigger ("Not
for from-scratch projects you started yourself — there is no prior
architecture to map"). Aligns the workflow's trigger language with the
2026-05-12 H-07 reframe in `docs/working/hypothesis-backlog.md`.

## Why
H-07 was reframed from "used when starting new projects" to "used when the
user inherits an unfamiliar codebase or returns to a >30-day-cold project."
The workflow's existing bullets gesture at these triggers ("just cloned a
repo", "haven't touched in months") but never name the underlying concept
("acquired familiarity") or rule out the misuse case ("from-scratch
projects you started yourself"). This is the structural fix: the trigger
list itself encodes the H-07 reframe, so the workflow is rejected from
inappropriate sessions at the routing stage rather than via a top-of-
workflow gate (the gate approach failed self_eval in round 1 because it
moves the check too late — by the time the workflow has been loaded, the
mis-fire has already happened).

## Edit pattern
Replace the `## When to use` bullet list and explanatory paragraph as
follows:

```
## When to use

Use this workflow to acquire familiarity with a codebase you didn't write
(or no longer remember). Triggers:

- **Inherited codebase**: you just cloned a repo, joined a project, or took
  over code someone else built
- **Returned-cold project**: you're returning to a project you haven't
  touched in months
- **New-team-member orientation**: someone needs a structured walkthrough
  of an existing codebase
- **RPI research is stuck**: you can't scope research because you don't
  even know where to start looking

**Not a trigger:** from-scratch projects you started yourself — there is
no prior architecture to map, so the workflow has nothing to do.

This is a **pre-task** workflow. ...
```

The trailing paragraph ("This is a **pre-task** workflow ...") is unchanged.

## Files touched
- `workflows/codebase-onboarding.md` — replace "When to use" bullets +
  add explicit non-trigger line
- `docs/working/r2-onboarding-when-to-use-sync-plan.md` — this plan

## Verification
- Re-read the new section: the acquired-familiarity concept is named in
  the lead sentence; both "inherited codebase" and "returned-cold project"
  are named as bullet labels; the non-trigger line is present and
  explicitly rules out from-scratch self-started projects.
- Confirm no other workflow files or skills reference the old bullet
  wording — none expected (the "When to use" section is internal-only).
- File-scope: only `workflows/codebase-onboarding.md` and
  `docs/working/r2-onboarding-when-to-use-sync-plan.md` modified.
