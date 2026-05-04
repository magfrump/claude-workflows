# Plan: Entry Point Inventory step in codebase-onboarding

## Goal
Insert a new step between the architecture map (current step 2) and the data flow tracing (current step 3) that exhaustively enumerates process entry points: CLI commands, HTTP handlers, scheduled jobs, message consumers, cron. Mark skip-able for libraries with no clear entry points and document the skip criterion.

## Why this slot
- Step 1 ("Entry points") is *navigational* — find a couple of starting nodes to begin reading from.
- Step 2 ("Map the architecture") gives you the subsystem layout needed to know *where* different process triggers live.
- Step 3 ("Trace key flows") wants to pick 2–3 representative flows. To pick representatively you need to know the full set of triggers — otherwise the chosen flows skew toward whatever was easiest to find in step 1.
- So the exhaustive inventory belongs after the architecture map and before flow tracing.

## What changes in `workflows/codebase-onboarding.md`
1. Insert a new step ("Inventory process entry points") between current step 2 and current step 3.
2. Renumber: current step 3 → 4, 4 → 5, 5 → 6, 6 → 7, 7 → 8.
3. Update internal cross-references that mention step numbers:
   - The "Pre-synthesis status banner" subsection (which mentions "before step 3 begins flow tracing") — point to step 4 instead, and clarify the banner still fires after the subsystem map (now-step 2).
   - Step 5's "After steps 1-4" → "After steps 1-5".
   - Step 5's done-when "answerable from work already done in steps 1-4" → "1-5".
   - Step 6's "Compile steps 1-5" → "Compile steps 1-6".
   - The orientation-doc template Lifecycle paragraph: "after gate sign-off in step 7" → "step 8".
4. Add a `## Process Entry Points` section to the orientation-doc template (new section between Architecture Map and Key Flows).
5. Update "Done when..." for step 6 to mention the new section.

## Skip criterion
The new step is skip-able when **all** of the following hold:
- The codebase is a pure library or SDK — its only callers are application code outside the repo.
- There are no executable entry points in the repo: no `main()`, no HTTP server, no CLI binary, no scheduled-task definitions, no message-queue consumers, no Lambda/Functions handlers.
- Step 1's "Public API surface" coverage is the system's only externally visible surface; there is nothing else to enumerate.

If even one of these is false (e.g., a library that ships a CLI for local use, or a library with an embedded health-check HTTP server), do not skip — run the step but scope it to whatever entry-point types exist.

When skipping, explicitly note "Process entry point inventory: skipped — pure-library codebase with no executable entry points; public API surface covered in step 1" in the orientation doc's Process Entry Points section so future readers know it was an intentional skip rather than an oversight.

## What the new step does
For each entry-point category present in the codebase, list every concrete instance with file path and a one-line description:
- **CLI commands**: subcommands, their flags, where they dispatch
- **HTTP handlers**: route → handler mapping (or framework-equivalent: REST routes, GraphQL resolvers, gRPC services, RPC methods)
- **Scheduled jobs / cron**: cron expressions or schedule definitions and the function they invoke
- **Message consumers**: queue/topic name → consumer handler
- **Background workers / daemons**: long-running processes that aren't covered above
- **Webhooks / event handlers**: external-event-driven entry points (e.g., Stripe webhooks, GitHub App events, S3 notifications)

Cap the list at exhaustive enumeration — do not trace what each handler does (that is step 4's job). The output is a directory of "every way the system can be triggered" so flow tracing can pick representatively.

## Plan-doc convention
- Step is opt-out (skip-able), not opt-in. Most non-trivial codebases have entry points; making it opt-in would let it be silently forgotten.
- Skip note must be written into the orientation doc, so a future reader can distinguish "skipped on purpose" from "we forgot".

## Implementation order
1. Edit `workflows/codebase-onboarding.md`:
   a. Insert new step body after step 2 (before the pre-synthesis status banner section, which sits between the new step and old step 3 — actually no, the banner currently sits between steps 2 and 3 to checkpoint *after subsystem mapping* and *before flow tracing/synthesis*. The banner still fires after step 2, but the next step is now the inventory rather than flow tracing — update its `<next action>` example to reflect that, and update its preamble that references "step 3 begins flow tracing").
   b. Renumber subsequent steps and update all step-number references.
   c. Add Process Entry Points section to the orientation-doc template.
   d. Update step-6 done-when checklist.
2. Commit with conventional-commit prefix `feat(onboarding):` and a descriptive subject.
3. Push.
