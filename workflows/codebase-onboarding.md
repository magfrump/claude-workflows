# Codebase Onboarding Workflow

*This workflow follows the [orchestrated review pattern](../patterns/orchestrated-review.md), with subsystems as the units of parallel exploration.*

## When to use
- You just cloned a repo and need to understand it before doing any work
- You're switching to a project you haven't touched in months
- A new team member needs a structured orientation to a codebase
- The RPI research phase feels impossible because you don't even know where to start looking

This is a **pre-task** workflow. It produces an orientation document that subsequent RPI sessions can reference. Unlike RPI's research phase (which investigates code relevant to a specific task), onboarding maps the terrain broadly so you know where to look when tasks arrive.

## When to pivot

- **→ RPI**: The natural next step. Once onboarding is complete, pivot to RPI for your first task. The onboarding doc's architecture map, key flows, and conventions replace the broad exploration part of RPI research — scope research to your specific task instead.
- **→ DD**: If the architecture map reveals structural conflicts with planned work, invoke DD to resolve the design question before starting RPI.

## Working documents

This workflow produces:
- `docs/working/onboarding-{project}.md` — the orientation document

This file is committed to the repo and treated as a living reference. Unlike RPI working docs (which are disposable per-task artifacts), the onboarding doc has ongoing value and should be updated as understanding deepens. If it grows stale, re-run the workflow rather than patching incrementally.

## Process

### 1. Entry points — find how the system starts

Before reading deep into any module, identify the system's entry points. These anchor everything else.

- **For applications**: `main()`, server startup, request handlers, CLI entry points
- **For libraries**: Public API surface, exported modules, package entry points
- **For infrastructure**: Deployment configs, CI/CD pipelines, Dockerfiles, Makefiles

Read the project's README, CLAUDE.md, AGENTS.md, or equivalent. Note what they explain and — more importantly — what they skip.

Produce a bullet list of entry points with file paths. This is your map's starting nodes.

### 2. Map the architecture — identify subsystems

From the entry points, trace outward to identify the major subsystems. A "subsystem" is a cohesive cluster of code with a recognizable responsibility: the API layer, the data access layer, the auth system, the job queue, the CLI, etc.

For each subsystem, note:
- **Directory/files**: Where it lives
- **Responsibility**: What it does (one sentence)
- **Key abstractions**: The 2-3 most important types, interfaces, or functions
- **Dependencies**: What other subsystems it calls or is called by

Don't read every file. Read entry points and public interfaces to understand boundaries. Read one representative implementation per subsystem to understand internal patterns.

If the codebase is large enough to warrant it (>20 files in multiple directories), use sub-agents to explore subsystems in parallel — one agent per subsystem, each producing the notes above for its area.

### 3. Trace key flows — follow data through the system

Pick 2-3 representative operations (e.g., "user signs up", "report is generated", "webhook is processed") and trace them end-to-end through the codebase. This reveals:

- How subsystems actually connect (not just how the directory structure implies they connect)
- Where the real complexity lives
- Which abstractions are load-bearing vs. ceremonial
- Where data transforms happen

For each flow, produce a numbered sequence of steps: "1. Request hits `routes/auth.ts:handleSignup` → 2. Validates input via `lib/validation.ts:validateUser` → 3. ..." Include file paths and function names.

### 4. Identify conventions — learn the local dialect

Every codebase has conventions that aren't in any style guide. Identify:

- **Naming patterns**: How are files, functions, types, and variables named? Is there a convention for handlers, models, utilities?
- **Error handling**: Exceptions? Result types? Error codes? Where are errors caught vs. propagated?
- **Testing patterns**: Where do tests live? What framework? What's the convention for test names, fixtures, mocking?
- **Configuration**: How is config loaded? Environment variables? Config files? Feature flags?
- **Patterns and idioms**: Dependency injection? Repository pattern? Middleware chains? What design patterns appear repeatedly?

Note any conventions that are inconsistent (the codebase uses two different approaches for the same thing) — these are important for knowing which pattern to follow when adding new code.

### 5. Catalog the unknowns — document what you don't understand

After steps 1-4, explicitly list:

- **Modules you didn't read deeply** and why (too large, seemed peripheral, unclear purpose)
- **Connections you couldn't trace** (subsystem A calls subsystem B somehow, but the mechanism is unclear)
- **Decisions that seem surprising** (why is this done this way? Was it intentional or accidental?)
- **External dependencies you don't understand** (third-party services, internal APIs, shared databases)

This is the most important section for future work. It tells you where your understanding has gaps so you don't unknowingly build on wrong assumptions.

### 6. Produce the orientation document

Compile steps 1-5 into `docs/working/onboarding-{project}.md` with these sections:

```markdown
# Codebase Orientation: {project name}

**Date:** {date}
**Last verified:** {date}
**Relevant paths:** {repo-relative paths this document covers — e.g., src/, lib/, configs/}
**Scope:** {what was covered — "full repo" or "backend only" etc.}

## Entry Points
{bullet list from step 1}

## Architecture Map
{subsystem descriptions from step 2, with a text diagram if helpful}

## Key Flows
{2-3 traced flows from step 3}

## Conventions
{patterns identified in step 4}

## Known Unknowns
{gaps identified in step 5}

## Suggested Starting Points
{for common task types, where to look first — e.g., "to add a new API endpoint, start with routes/ and follow the pattern in routes/users.ts"}
```

### 7. Gate — validate with the team

If possible, have someone familiar with the codebase review the orientation doc. They can correct misunderstandings cheaply here — a wrong mental model carried into implementation is expensive to fix later.

If no reviewer is available, treat the Known Unknowns section as a list of things to verify during your first RPI research phase.

## Relationship to other workflows

- **Feeds into RPI**: The orientation doc is a starting point for RPI research phases. Instead of exploring from scratch, you already know which subsystems are relevant.
- **Feeds into task decomposition**: The architecture map helps identify which subsystems a large task touches, enabling better decomposition.
- **Can trigger divergent design**: If the architecture map reveals that the codebase is structured in a way that conflicts with your planned work, that's a design decision worth running through DD.

## When to re-run

- When you return to a project after a long absence and suspect significant structural changes
- When a major refactoring or migration has landed
- When the orientation doc's Known Unknowns section is mostly resolved and you want a fresh scan for new unknowns
- When the **freshness check** shows changes to tracked paths (see below)

### Freshness check

Before relying on an existing onboarding doc, check whether the codebase has changed since it was last verified:

```bash
git log --oneline --since="<Last verified date>" -- <Relevant paths>
```

If commits appear, read them to decide whether they invalidate the document. If they do, re-run the onboarding workflow. If not, update `Last verified` to today's date. See `guides/doc-freshness.md` for the full heuristic.
