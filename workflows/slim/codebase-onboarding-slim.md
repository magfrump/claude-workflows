# Codebase Onboarding (Slim)

> Quick-start checklist. Full workflow: [codebase-onboarding.md](../codebase-onboarding.md)
> Last synced: 2026-04-08

## When to use

First time in a codebase, returning after a long absence, or RPI research feels impossible because you don't know where to start.

## Checklist

- [ ] **1. Find entry points** — Read README/CLAUDE.md. List `main()`, server startup, CLI entry points, public API surface with file paths. Note what docs skip.

- [ ] **2. Map architecture** — From entry points, identify major subsystems. For each: directory, responsibility (one sentence), key abstractions (2-3 types/functions), dependencies on other subsystems.

- [ ] **3. Trace key flows** — Pick 2-3 representative operations and follow them end-to-end. Produce numbered steps with file paths and function names at each hop.

- [ ] **4. Identify conventions** — Document local patterns for: naming, error handling, testing, configuration, and recurring design idioms. Note any inconsistencies.

- [ ] **5. Catalog unknowns** — List modules you didn't read deeply, connections you couldn't trace, surprising decisions, and unclear external dependencies. Include *why* each is unknown.

- [ ] **6. Write orientation doc** — Compile into `docs/working/onboarding-{project}.md` with sections: Entry Points, Architecture Map, Key Flows, Conventions, Known Unknowns, Suggested Starting Points. Add `Last verified` and `Relevant paths` fields.

- [ ] **7. Validate** — Have someone familiar with the codebase review. If no reviewer, treat Known Unknowns as verification targets for your first RPI research phase.

## What's next

Pivot to [rpi-slim.md](rpi-slim.md) for your first task. The onboarding doc replaces broad exploration in RPI's research phase.
