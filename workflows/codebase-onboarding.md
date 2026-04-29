---
value-justification: "Replaces unstructured code exploration when joining a new project with systematic coverage of architecture, conventions, and key flows."
---

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

This file is committed to the repo and treated as a living reference. Unlike RPI working docs (which are disposable per-task artifacts), the onboarding doc has ongoing value and should be updated as understanding deepens. If it grows stale, re-run the workflow (or use a lightweight refresh for incremental changes — see "When to re-run").

## Process

### 1. Entry points — find how the system starts

Before reading deep into any module, identify the system's entry points. These anchor everything else.

- **For applications**: `main()`, server startup, request handlers, CLI entry points
- **For libraries**: Public API surface, exported modules, package entry points
- **For infrastructure**: Deployment configs, CI/CD pipelines, Dockerfiles, Makefiles

Read the project's README, CLAUDE.md, AGENTS.md, or equivalent. Note what they explain and — more importantly — what they skip.

Produce a bullet list of entry points with file paths. This is your map's starting nodes.

**Done when...**
- [ ] README/CLAUDE.md/AGENTS.md (or equivalent) has been read and gaps noted
- [ ] A bullet list of entry points exists with file paths for each
- [ ] Entry points cover all system types present (application, library, infrastructure)

### 2. Map the architecture — identify subsystems

From the entry points, trace outward to identify the major subsystems. A "subsystem" is a cohesive cluster of code with a recognizable responsibility: the API layer, the data access layer, the auth system, the job queue, the CLI, etc.

For each subsystem, note:
- **Directory/files**: Where it lives
- **Responsibility**: What it does (one sentence)
- **Key abstractions**: The 2-3 most important types, interfaces, or functions
- **Dependencies**: What other subsystems it calls or is called by

Don't read every file. Read entry points and public interfaces to understand boundaries. Read one representative implementation per subsystem to understand internal patterns.

**Monorepo scoping.** For monorepos with multiple packages or services, scope your architecture mapping to the package or service relevant to your first task — don't attempt to document every package in a single onboarding pass. Note the monorepo's top-level package dependency graph (e.g., from the root `package.json` workspaces, Cargo workspace members, or Go module layout) so you know which adjacent packages interact with yours. List all packages you did *not* examine in Known Unknowns (step 5) with a note that they were out of scope for the current task.

If the codebase is large enough to warrant it (>20 files in multiple directories), use sub-agents to explore subsystems in parallel — one agent per subsystem, each producing the notes above for its area.

**Sub-agent briefing template.** A sub-agent starts with zero prior context, so its brief must be self-contained. Use the following template per dispatch — one filled brief per subsystem:

- **Subsystem name**: the cluster being investigated (e.g., "auth", "job queue", "API layer").
- **Files to read**: explicit paths or globs — entry points relevant to this subsystem, public interfaces, and 1–2 representative implementation files. Don't ask the sub-agent to discover its own scope; it will waste a turn searching.
- **Questions to answer**: what is the subsystem's one-sentence responsibility? What are its 2–3 key abstractions (types, interfaces, or functions, with file paths)? Which other subsystems does it call or is called by? Are there inconsistencies or surprises worth flagging?
- **Output schema** (the sub-agent fills these fields and nothing else):
  - `Subsystem`: <name>
  - `Directory/files`: <where it lives>
  - `Responsibility`: <one sentence>
  - `Key abstractions`: <2–3 items, each with a file path>
  - `Dependencies`: <inbound and outbound, with subsystem names>
  - `Representative file read`: <path of the implementation file used to confirm internal patterns>
  - `Goal-Alignment Note`: per the [orchestrated review pattern](../patterns/orchestrated-review.md#goal-alignment-self-report) (three bullets: Answered / Out of scope / Escalate)

This output drops directly into the Architecture Map without restructuring. If a sub-agent returns prose instead of the schema, re-dispatch with the schema repeated — don't do the synthesis work yourself.

**Suggested output structure.** When assembling your findings into the Architecture Map section of the orientation document, consider organizing around these three areas. This isn't a mandatory format — adapt it to fit the codebase — but it provides a useful default that downstream RPI research can quickly parse:

- **Subsystem inventory**: A table or list of each subsystem with its name, one-line responsibility, and 2-3 key files (entry points or central modules). This gives future sessions a lookup table for "where does X live?"
- **Data flow**: How subsystems connect — which calls which, what data passes between them, and in what direction. A simple text diagram or arrow notation (e.g., `API layer → Service layer → Database`) is often enough. This answers "if I change subsystem A, what else might be affected?"
- **External dependencies**: Databases, third-party APIs, message queues, shared services, or any system outside the codebase boundary. Note what each is used for and which subsystem owns the integration. This surfaces coupling that isn't visible from code structure alone.

**Done when...**
- [ ] Every major subsystem is identified with its directory/files, responsibility, key abstractions, and dependencies
- [ ] At least one representative implementation per subsystem has been read (not just interfaces)
- [ ] Dependencies between subsystems are documented (what calls what)

### 3. Trace key flows — follow data through the system

Pick 2-3 representative operations (e.g., "user signs up", "report is generated", "webhook is processed") and trace them end-to-end through the codebase. This reveals:

- How subsystems actually connect (not just how the directory structure implies they connect)
- Where the real complexity lives
- Which abstractions are load-bearing vs. ceremonial
- Where data transforms happen

For each flow, produce a numbered sequence of steps: "1. Request hits `routes/auth.ts:handleSignup` → 2. Validates input via `lib/validation.ts:validateUser` → 3. ..." Include file paths and function names.

**Done when...**
- [ ] 2-3 representative flows are traced end-to-end with file paths and function names at each step
- [ ] Flows reveal how subsystems actually connect (not just how the directory structure implies)
- [ ] Each flow covers the complete path from entry point to final effect (no gaps marked "somehow")

### 4. Identify conventions — learn the local dialect

Every codebase has conventions that aren't in any style guide. Identify:

- **Naming patterns**: How are files, functions, types, and variables named? Is there a convention for handlers, models, utilities?
- **Error handling**: Exceptions? Result types? Error codes? Where are errors caught vs. propagated?
- **Testing patterns**: Where do tests live? What framework? What's the convention for test names, fixtures, mocking?
- **Configuration**: How is config loaded? Environment variables? Config files? Feature flags?
- **Patterns and idioms**: Dependency injection? Repository pattern? Middleware chains? What design patterns appear repeatedly?

Note any conventions that are inconsistent (the codebase uses two different approaches for the same thing) — these are important for knowing which pattern to follow when adding new code.

**Done when...**
- [ ] All five convention categories are addressed (naming, error handling, testing, configuration, patterns/idioms)
- [ ] Inconsistencies between competing conventions are explicitly noted
- [ ] Each convention includes a concrete example from the codebase (file path and pattern)

### 5. Catalog the unknowns — document what you don't understand

After steps 1-4, explicitly list:

- **Modules you didn't read deeply** and why (too large, seemed peripheral, unclear purpose). In monorepos, explicitly list every package or service you scoped out of the architecture map — these are known unknowns by design, not oversights.
- **Connections you couldn't trace** (subsystem A calls subsystem B somehow, but the mechanism is unclear)
- **Decisions that seem surprising** (why is this done this way? Was it intentional or accidental?)
- **External dependencies you don't understand** (third-party services, internal APIs, shared databases)

This is the most important section for future work. It tells you where your understanding has gaps so you don't unknowingly build on wrong assumptions.

**Done when...**
- [ ] At least one item exists in each category (modules not read, connections not traced, surprising decisions, unclear dependencies)
- [ ] Each unknown includes a reason why it's unknown (not just "didn't look at it")
- [ ] No unknown is actually answerable from work already done in steps 1-4

### 6. Produce the orientation document

Compile steps 1-5 into `docs/working/onboarding-{project}.md` with these sections:

```markdown
# Codebase Orientation: {project name}

**Date:** {date}
**Last verified:** {date}
**Relevant paths:** {repo-relative paths this document covers — e.g., src/, lib/, configs/}
**Scope:** {what was covered — "full repo", "backend only", "packages/api + packages/shared only", etc.}

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

**Done when...**
- [ ] `docs/working/onboarding-{project}.md` exists with all required sections (Entry Points, Architecture Map, Key Flows, Conventions, Known Unknowns, Suggested Starting Points)
- [ ] `Last verified` and `Relevant paths` fields are populated in the frontmatter
- [ ] Document is committed to the repo

### 7. Gate — validate with the team

If possible, have someone familiar with the codebase review the orientation doc. They can correct misunderstandings cheaply here — a wrong mental model carried into implementation is expensive to fix later.

If no reviewer is available, treat the Known Unknowns section as a list of things to verify during your first RPI research phase.

**Done when...**
- [ ] A codebase-familiar reviewer has approved the orientation doc, OR Known Unknowns are flagged for verification during the first RPI research phase
- [ ] Any reviewer corrections have been incorporated into the document
- [ ] The onboarding doc is ready to serve as input for RPI research phases

## Onboarding sufficiency

Before handing off to RPI, verify the onboarding doc meets these criteria. If any fail, the doc has gaps that will slow down task work.

1. **"Where would I look?" test.** For any likely task category (add a feature, fix a bug, change config, add a test), you can name the directory, file, or subsystem to start in — without re-reading code. If you can't, the Architecture Map or Suggested Starting Points section has gaps.
2. **Unknowns are on-demand only.** Every item in Known Unknowns is something you'd investigate *when a task requires it*, not something that blocks general navigation. If any unknown would block multiple unrelated tasks, resolve it before handing off.
3. **Conventions are actionable.** The Conventions section has enough detail that new code written following it would pass review without style corrections. If a convention is noted but not exemplified, add a file path and example.

These criteria also apply when judging whether a *returning* onboarding session (triggered by staleness) has restored the doc to a usable state.

## Relationship to other workflows

- **Feeds into task decomposition**: The architecture map helps identify which subsystems a large task touches, enabling better decomposition.

See also "When to pivot" above for RPI and DD handoff guidance.

## When to re-run

- When you return to a project after a long absence and suspect significant structural changes
- When a major refactoring or migration has landed
- When the orientation doc's Known Unknowns section is mostly resolved and you want a fresh scan for new unknowns
- When the **freshness check** shows changes to tracked paths (see below)

### Staleness signals

These are concrete triggers that indicate the onboarding doc needs a refresh. Check for them before relying on an existing doc, especially at the start of a new session.

1. **Major dependency upgrade.** A framework or runtime version bump (e.g., React 18→19, Python 3.11→3.12, Rails major version) can change conventions, entry points, and key abstractions. Check `git log --oneline --all -- '*lock*' 'package.json' 'requirements*.txt' '*.gemspec' 'go.mod'` for dependency changes since `Last verified`.
2. **New subsystem added.** A new top-level directory, service, or module that didn't exist when the doc was written means the Architecture Map is incomplete. Check `git log --oneline --diff-filter=A --since="<Last verified date>" -- <Relevant paths>` for newly added files in structural locations.
3. **High churn since last update.** If >30% of files under tracked `Relevant paths` have been modified since `Last verified`, the doc likely has stale descriptions. Check with `git diff --stat <last-verified-commit>..HEAD -- <Relevant paths>` and compare against total file count.
4. **Doc age with active development.** If `Last verified` is >30 days old and the repo has had active commits in that period, refresh even if no single trigger above fires — accumulated small changes can silently invalidate the mental model.

When a signal fires, decide whether a **full re-run** or a **lightweight refresh** is appropriate (see below). Update `Last verified` to today's date after either type of refresh, and note which signal triggered it in the commit message (e.g., `docs: refresh onboarding — new subsystem added`).

### Lightweight refresh

When staleness signals fire but changes are **incremental** — no new subsystems, no major dependency upgrades, no architectural shifts — a targeted refresh is proportionate. A full 7-step re-run is overkill when the existing orientation doc is fundamentally sound and just needs updating in the areas that changed.

**When to use lightweight refresh (all must be true):**
- Staleness signal #3 (high churn) or #4 (doc age) fired, but NOT #1 (major dependency upgrade) or #2 (new subsystem)
- Changes are within existing subsystems, not across subsystem boundaries
- The Architecture Map's subsystem inventory is still complete (no new top-level modules)

**When to use full re-run instead:**
- Signal #1 or #2 fired (new subsystems or major dependency changes)
- Changes span multiple subsystem boundaries in ways that may have altered data flow
- You're unsure whether the changes are incremental — when in doubt, full re-run

**Lightweight refresh process:**

1. **Review recent changes.** Run `git log --oneline --since="<Last verified date>" -- <Relevant paths>` and read the commits to understand what changed and where.
2. **Update Architecture Map.** For each subsystem touched by recent changes, verify that its responsibility, key abstractions, and dependencies are still accurate. Update any that have drifted.
3. **Update Known Unknowns.** Remove unknowns that have been resolved by recent work. Add new unknowns surfaced by the changes you reviewed.
4. **Bump `Last verified`.** Set to today's date. Add a note in the commit message indicating this was a lightweight refresh (e.g., `docs: lightweight refresh onboarding — updated auth subsystem after session handling changes`).

**Done when...**
- [ ] `git log` since `Last verified` has been reviewed
- [ ] Architecture Map reflects current state for all changed subsystems
- [ ] Known Unknowns section is current (stale items removed, new gaps added)
- [ ] `Last verified` date is updated
- [ ] Onboarding sufficiency criteria still pass (the "Where would I look?" test, etc.)

A lightweight refresh should take significantly less time than a full re-run — if you find yourself re-reading most of the codebase, abort and do a full re-run instead.

### Freshness check

Before relying on an existing onboarding doc, check whether the codebase has changed since it was last verified:

```bash
git log --oneline --since="<Last verified date>" -- <Relevant paths>
```

If commits appear, read them to decide whether they invalidate the document. If they do, re-run the onboarding workflow. If not, update `Last verified` to today's date. See `guides/doc-freshness.md` for the full heuristic.
