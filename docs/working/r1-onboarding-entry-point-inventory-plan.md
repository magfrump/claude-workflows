# Plan: execution-surface inventory step in codebase-onboarding

## Goal
Insert a new step between the current Architecture Map (step 2) and Key Flows
(step 3) in `workflows/codebase-onboarding.md` that enumerates the project's
execution surface — CLI commands, HTTP handlers, scheduled jobs, message
consumers. Make the step skip-able for libraries and from-scratch projects via
a documented skip criterion at the top of the step, with a defined one-line
skip-output format. Update step numbering, cross-references, and the
orientation-document template (the doc's effective table of contents).

## Why here
The Architecture Map answers "what subsystems exist," and Key Flows answers
"what happens when one runs." The current workflow has no structured step
between them that catalogs the runtime triggers themselves. Without an
explicit execution-surface inventory, flow tracing in step 3 silently picks
2–3 entry points without confirming the full set, and Known Unknowns in step
5 has no anchor against which to mark "this flow has no listed trigger" as a
gap. Libraries and pre-runtime projects genuinely have nothing to enumerate,
so the step must be skippable rather than mandatory.

## Edit pattern
1. Insert new step 3, **Inventory the execution surface**, between current
   step 2 (Architecture Map) and current step 3 (Key Flows). Step body:
   - Skip criterion at top: pure library, from-scratch project, or otherwise
     no CLI/HTTP/scheduled/consumer triggers exist.
   - Skip-output format: a single line in the orientation doc's Execution
     Surface section: `Execution Surface: none — <one-sentence reason>.`
   - Partial-skip rule: if some modes exist, do not skip; mark absent modes
     as "none" explicitly.
   - For each entry point: trigger, location (file:fn), owning subsystem
     from step 2, one-line purpose.
   - Minimum categories: CLI commands, HTTP handlers, scheduled jobs,
     message consumers. Note "none" for absent modes. Allow extra modes.
   - Done-when checklist with branched skip / not-skip paths.

2. Renumber the existing steps:
   - 3 → 4 (Trace key flows)
   - 4 → 5 (Identify conventions)
   - 5 → 6 (Catalog the unknowns)
   - 6 → 7 (Produce the orientation document)
   - 7 → 8 (Gate — validate with the team)

3. Update cross-references:
   - Step 2 references to "Known Unknowns (step 5)" → "(step 6)" (two
     occurrences — monorepo paragraph and accessibility paragraph).
   - Pre-synthesis status banner: update example "proceeding to flow tracing
     in step 3" → "proceeding to execution surface inventory in step 3"; the
     "orientation doc produced in step 6" pointer → "step 7"; the
     "between step 2 and step 3" scope rule stays as-is (the banner still
     fires before step 3, just before a different step 3).
   - Old step 5 (Catalog the unknowns) intro: "After steps 1-4" → "After
     steps 1-5"; done-when checklist: "from work already done in steps 1-4"
     → "in steps 1-5".
   - Old step 6 (Produce the orientation document): "Compile steps 1-5" →
     "Compile steps 1-6"; orientation doc template gains an `## Execution
     Surface` section between `## Architecture Map` and `## Key Flows`;
     header notes "(or skip note)" so the template doesn't imply the
     section is always full content; "after gate sign-off in step 7" → "in
     step 8"; done-when checklist gains Execution Surface in the section
     list.
   - Lightweight refresh: "full 7-step re-run" → "full 8-step re-run".

4. The orientation document template under step 7 is the closest thing this
   workflow has to a table of contents. Adding `## Execution Surface` there
   is the TOC update the task requires.

## Skip-output format (final wording)
`Execution Surface: none — <one-sentence reason>.`

Examples:
- `Execution Surface: none — pure library; consumers drive execution via the public API in Entry Points.`
- `Execution Surface: none — from-scratch project, no runtime wiring yet.`

## Files touched
- `workflows/codebase-onboarding.md` — insert step 3, renumber, fix
  cross-refs, update template.
- `docs/working/r1-onboarding-entry-point-inventory-plan.md` — this plan.

## Verification
- Re-read the new step 3 in context: skip criterion is at the top, the
  skip-output format is concrete, and the not-skipped branch produces a
  structured inventory.
- Grep for any remaining stale step numbers (`steps 1-4`, `steps 1-5`,
  `7-step`, `step 5`, `step 6`, `step 7` in cross-reference contexts) and
  confirm each surviving occurrence is correct under the new numbering.
- Confirm the banner section's `between step 2 and step 3` rule still holds
  semantically (banner fires before execution-surface inventory begins).
- Confirm the orientation doc template lists Execution Surface in the
  section list and the done-when checklist of step 7 mentions it.
- No files outside `workflows/codebase-onboarding.md` and `docs/working/`
  are modified (file-scope constraint).
