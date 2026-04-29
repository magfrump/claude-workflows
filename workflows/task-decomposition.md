---
value-justification: "Replaces sequential investigation of multi-subsystem tasks with parallel sub-investigations, reducing calendar time for complex work."
---

# Task Decomposition Workflow

*This workflow follows the [orchestrated review pattern](../patterns/orchestrated-review.md).*

## When to use
- A feature or task has multiple independent parts that benefit from separate research
- You need to understand several subsystems before planning a change that touches all of them
- A task is large enough that doing it all sequentially risks context degradation

This workflow is about decomposing work into independent sub-investigations and (where possible) dispatching sub-agents for parallel research. Implementation still happens sequentially in the main agent — sub-agents research and analyze, they don't write code to shared files.

## Process

### 1. Identify independent sub-investigations

Before starting research, assess whether the task touches multiple independent subsystems. If so, list them:

- What are the distinct areas of the codebase involved?
- Can each area be researched without understanding the others first?
- Are there shared dependencies that need to be researched before the area-specific work?

Example decomposition for "add API endpoint with auth and rate limiting":
- **Shared dependency**: How does the existing routing/middleware pipeline work?
- **Independent area A**: How does auth work in this codebase?
- **Independent area B**: Is there existing rate limiting? What library/approach?
- **Independent area C**: What's the data model for the resource being exposed?

**Done when...**
- [ ] The distinct areas of the codebase involved are listed
- [ ] Each area is labeled as either a shared dependency or an independent sub-investigation
- [ ] Independent areas can be researched without understanding the others first
- [ ] Shared dependencies (if any) are identified and will be researched before independent areas

### 2. Research shared dependencies first

If sub-investigations have a shared dependency, research that first in the main agent. Produce a research doc for it. This grounds all subsequent sub-investigations in the same understanding.

**Done when...**
- [ ] All shared dependencies have a research doc (or documented section) with findings
- [ ] The research covers enough detail that sub-agents can work without re-investigating shared areas
- [ ] If no shared dependencies exist, this step is explicitly skipped (not silently omitted)

### 3. Dispatch sub-agents for independent research

For each independent area, dispatch a sub-agent with a focused prompt:

- Tell it exactly which files/directories to examine
- Tell it what questions to answer
- Tell it to write findings to a specific section of the research doc, or to a separate research doc per area

Sub-agents are good for:
- Reading and summarizing a module or subsystem
- Checking how a pattern is used across the codebase (e.g., "find all places where auth middleware is applied")
- Running a test suite and reporting what passes/fails
- Analyzing a dependency's API surface

#### Briefing patterns

A sub-agent starts with zero context. Brief it like a colleague who just walked in — state what you're trying to accomplish, what to look at, and what to report back.

**Goal preamble.** Every sub-agent prompt must lead with the 3-line goal preamble (User goal / Current task / Success criterion) defined in [`patterns/orchestrated-review.md`](../patterns/orchestrated-review.md#goal-preamble-standard). This anchors the sub-agent before the file paths and questions that follow. Cap at 3 lines — extra context goes in the briefing body.

**Example — researching a subsystem (with preamble):**
> "User goal: Plan a new API endpoint that needs auth and rate limiting.
> Current task: Research how auth currently works in this codebase.
> Success criterion: Findings written to the 'Auth' section of `docs/working/research-api-endpoint.md`.
>
> Examine `src/auth/` and `src/middleware/auth.go`. Answer: (1) How are tokens validated? (2) Where is the middleware applied? (3) What happens on auth failure?"

**Example — cross-cutting pattern search:**
> "Find all places rate limiting is applied in this codebase. For each, note: which library, what limits, whether it's per-user or global. The routing middleware is in `src/server/router.go` — start there. Report findings in under 200 words."

**Example — dependency analysis:**
> "Read `package.json` and `src/pdf/generator.ts`. We're evaluating whether to replace the PDF library. Answer: What API surface do we actually use? How coupled is our code to this specific library? Are there test fixtures that depend on exact output?"

Common briefing mistakes: omitting file paths (sub-agent wastes time searching), asking open-ended questions ("how does this work?" vs. specific questions), and not capping output length (sub-agent returns a wall of text you have to re-read).

Sub-agents should NOT:
- Write or modify source code (risk of conflicts with other sub-agents or the main agent)
- Make architectural decisions (that's the main agent + human's job)
- Proceed to planning or implementation

**Done when...**
- [ ] Each independent area has a sub-agent dispatched (or researched sequentially if sub-agents are unavailable)
- [ ] Each sub-agent prompt specifies exact files/directories to examine, questions to answer, and where to write findings
- [ ] All sub-agents have returned their findings

### 4. Reconcile conflicting assumptions across sub-investigations

Before synthesizing, check whether sub-agents made conflicting assumptions about shared interfaces — data shapes, API contracts, error handling conventions, or naming that spans multiple sub-investigations. When two sub-agents researched different subsystems that communicate through a shared interface, they may have described that interface differently or assumed incompatible behaviors.

For each shared interface identified in step 1:
- Compare what each relevant sub-agent assumed about its shape, behavior, and error cases
- If assumptions conflict, resolve by reading the actual code (the ground truth) — don't pick one sub-agent's version arbitrarily
- Document any conflicts found and their resolution in the research doc under a **Reconciliation** heading. If no conflicts were found, note that explicitly (e.g., "No cross-investigation conflicts identified")

This step is lightweight when sub-investigations are truly independent. It becomes critical when sub-agents researched different sides of the same interface.

**Done when...**
- [ ] Each shared interface has been checked for conflicting assumptions across sub-agent findings
- [ ] Conflicts (if any) are resolved by verifying against actual code, not by choosing one sub-agent's version
- [ ] A Reconciliation section exists in the research doc (even if it just says "no conflicts found")

### 5. Synthesize into a unified research doc

Collect sub-agent outputs into a single research doc following the RPI naming convention: `docs/working/research-{topic}.md`. The synthesized doc must include all RPI-required sections (Scope, What exists, Invariants, Prior art, Gotchas) — sub-agent findings should be reorganized into these sections rather than preserved as separate per-area summaries. Resolve any contradictions or gaps. This synthesized research is what feeds into the plan step of the research-plan-implement workflow.

The main (orchestrating) agent is responsible for writing the final research doc, not the sub-agents. Sub-agents produce raw findings; the main agent structures them into the RPI format.

**Done when...**
- [ ] A unified research doc exists at `docs/working/research-{topic}.md`
- [ ] The doc includes all RPI-required sections (Scope, What exists, Invariants, Prior art, Gotchas)
- [ ] Sub-agent findings are reorganized by section, not preserved as separate per-area summaries
- [ ] Contradictions or gaps between sub-agent findings are resolved or flagged

### 6. Plan and implement sequentially

From here, follow the normal research-plan-implement workflow. The decomposition was about parallelizing *understanding*, not *implementation*. The plan should address the full task as a coherent sequence.

**Done when...**
- [ ] The RPI workflow has been entered with the synthesized research doc as input
- [ ] The plan addresses the full task as a coherent sequence (not as separate per-area plans)

## When to skip

- If the task only touches one subsystem, just do normal research-plan-implement — sub-agents add overhead without benefit.
- If the codebase is small enough that you can read the relevant parts in a few minutes, don't bother decomposing.
- If sub-agent dispatch isn't available in your Claude Code version, do the research sequentially in the main agent. The decomposition list from step 1 is still useful as a research checklist even without parallelism.
