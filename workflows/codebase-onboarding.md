# Codebase Onboarding Workflow

## When to use
- You just cloned a repo and need to understand it before doing any work
- You're switching to a project you haven't touched in months
- A new team member needs a structured orientation
- The RPI research phase feels impossible because you don't know where to start

This is a **pre-task** workflow. It produces an orientation document that subsequent RPI sessions can reference — mapping the terrain broadly so you know where to look when tasks arrive.

## When to pivot

- **→ RPI**: The natural next step. The onboarding doc's architecture map replaces broad exploration in RPI research — scope to your specific task.
- **→ DD**: If the architecture map reveals structural conflicts with planned work, resolve via DD before starting RPI.
- **Feeds into task decomposition**: The architecture map helps identify which subsystems a large task touches.

## Working documents

- `docs/working/onboarding-{project}.md` — the orientation document

Committed to the repo and treated as a living reference. Unlike RPI working docs (disposable per-task), the onboarding doc has ongoing value. If it grows stale, re-run the workflow.

## Process

### 1. Entry points — find how the system starts

Before reading deep into any module, identify the system's entry points:

- **Applications**: `main()`, server startup, request handlers, CLI entry points
- **Libraries**: Public API surface, exported modules
- **Infrastructure**: Deployment configs, CI/CD, Dockerfiles, Makefiles

Read the project's README, CLAUDE.md, AGENTS.md. Note what they explain and what they skip.

**Done when...**
- [ ] README/CLAUDE.md/AGENTS.md (or equivalent) has been read and gaps noted
- [ ] A bullet list of entry points exists with file paths for each
- [ ] Entry points cover all system types present (application, library, infrastructure)

### 2. Map the architecture — identify subsystems

From entry points, trace outward to identify major subsystems (cohesive clusters with recognizable responsibility: API layer, data access, auth, job queue, CLI, etc.).

For each subsystem, note: **directory/files**, **responsibility** (one sentence), **key abstractions** (2-3 types/interfaces/functions), **dependencies** (what it calls or is called by).

Read entry points and public interfaces for boundaries. Read one representative implementation per subsystem for internal patterns. For large codebases (>20 files, multiple directories), use sub-agents to explore subsystems in parallel.

**Done when...**
- [ ] Every major subsystem is identified with its directory/files, responsibility, key abstractions, and dependencies
- [ ] At least one representative implementation per subsystem has been read (not just interfaces)
- [ ] Dependencies between subsystems are documented (what calls what)

### 3. Trace key flows — follow data through the system

Pick 2-3 representative operations (e.g., "user signs up", "report generated", "webhook processed") and trace end-to-end. This reveals how subsystems actually connect, where complexity lives, which abstractions are load-bearing, and where data transforms happen.

For each flow, produce a numbered sequence with file paths and function names.

**Done when...**
- [ ] 2-3 representative flows are traced end-to-end with file paths and function names at each step
- [ ] Flows reveal how subsystems actually connect (not just how the directory structure implies)
- [ ] Each flow covers the complete path from entry point to final effect (no gaps marked "somehow")

### 4. Identify conventions — learn the local dialect

Every codebase has conventions not in any style guide. Identify patterns for: **naming**, **error handling**, **testing** (location, framework, conventions), **configuration**, and **design patterns/idioms**.

Note inconsistencies where the codebase uses two approaches for the same thing — important for knowing which pattern to follow.

**Done when...**
- [ ] All five convention categories are addressed (naming, error handling, testing, configuration, patterns/idioms)
- [ ] Inconsistencies between competing conventions are explicitly noted
- [ ] Each convention includes a concrete example from the codebase (file path and pattern)

### 5. Catalog the unknowns — document what you don't understand

After steps 1-4, explicitly list: modules not read deeply (and why), connections not traced, decisions that seem surprising, and external dependencies you don't understand.

This is the most important section for future work — it tells you where your understanding has gaps.

**Done when...**
- [ ] At least one item exists in each category (modules not read, connections not traced, surprising decisions, unclear dependencies)
- [ ] Each unknown includes a reason why it's unknown (not just "didn't look at it")
- [ ] No unknown is actually answerable from work already done in steps 1-4

### 6. Produce the orientation document

Compile steps 1-5 into `docs/working/onboarding-{project}.md` with sections: **Entry Points**, **Architecture Map**, **Key Flows**, **Conventions**, **Known Unknowns**, **Suggested Starting Points** (for common task types, where to look first).

Include `Last verified` date and `Relevant paths` in the frontmatter for freshness tracking.

**Done when...**
- [ ] `docs/working/onboarding-{project}.md` exists with all required sections
- [ ] `Last verified` and `Relevant paths` fields are populated in the frontmatter
- [ ] Document is committed to the repo

### 7. Gate — validate with the team

Have someone familiar with the codebase review the orientation doc. If no reviewer is available, treat Known Unknowns as things to verify during your first RPI research phase.

**Done when...**
- [ ] A codebase-familiar reviewer has approved the orientation doc, OR Known Unknowns are flagged for verification during the first RPI research phase
- [ ] Any reviewer corrections have been incorporated into the document
- [ ] The onboarding doc is ready to serve as input for RPI research phases

## When to re-run

- After a long absence when significant structural changes may have landed
- After a major refactoring or migration
- When the freshness check (`git log --oneline --since="<Last verified>" -- <Relevant paths>`) shows invalidating changes. See `guides/doc-freshness.md` for the full heuristic.
