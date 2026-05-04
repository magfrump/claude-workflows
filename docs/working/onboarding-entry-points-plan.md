---
name: Onboarding entry-points step plan
description: Plan for inserting an execution-entry-points step into the codebase-onboarding workflow.
type: working
status: complete
---

# Plan — insert "execution entry points" step into codebase-onboarding workflow

**Goal**: Add a step between the architecture map (step 2) and flow tracing (step 3) that enumerates execution entry points (CLI commands, HTTP handlers, scheduled jobs, message consumers). Skip-able for pure libraries with a documented criterion.

## Insertion point

The new step goes **after** the pre-synthesis status banner section and **before** the current "Trace key flows" step. Rationale:
- The banner currently fires after step 2's parallel sub-agent fan-out as a checkpoint. That checkpoint still belongs immediately after subsystem mapping — entry-point enumeration is closer to additional analytic cataloguing than to the silent flow-tracing/synthesis phase the banner gates.
- Keeping the banner between step 2 and step 3 (now entry-points enumeration) preserves the rule "Emit this banner *only* between step 2 and step 3", with only the next-action wording needing an update.

## New step content

- **Purpose**: produce a complete catalogue of how external actors hand control to the system.
- **Categories**: CLI commands, HTTP handlers, scheduled jobs, message consumers (queues, event subscribers, webhooks).
- **Per-entry data**: trigger type, identifier (route/method, command name, schedule, queue/topic), handler location (file:function), owning subsystem (cross-reference to step 2).
- **Skip criterion**: pure libraries with no executable surface (no `main()`, no daemon, no CLI binary, no scheduled task registration, no message consumer setup). Document the skip with a one-line note in the orientation doc. If unsure, do not skip.
- **Done-when**: complete inventory per applicable category (or explicit "none" with reason); each entry has trigger/identifier/handler/owning subsystem; skip path used only for pure libraries; cross-references step 2's subsystem inventory.

## Knock-on edits

- Renumber steps 3→4, 4→5, 5→6, 6→7, 7→8.
- Update step-number references at lines 60, 62 (Known Unknowns step), 95, 102, 112, 117, 119, 125, 195–207 (template placeholders), and the Done-when blocks.
- Add an "Execution Entry Points" section to the orientation document template (after Architecture Map, before Key Flows).
- Update the banner section's worked example and `<next action>` examples to reflect the entry-points step.
