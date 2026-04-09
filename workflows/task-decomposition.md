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

Sub-agents should NOT:
- Write or modify source code (risk of conflicts with other sub-agents or the main agent)
- Make architectural decisions (that's the main agent + human's job)
- Proceed to planning or implementation

**Done when...**
- [ ] Each independent area has a sub-agent dispatched (or researched sequentially if sub-agents are unavailable)
- [ ] Each sub-agent prompt specifies exact files/directories to examine, questions to answer, and where to write findings
- [ ] All sub-agents have returned their findings

### 4. Synthesize into a unified research doc

Collect sub-agent outputs into a single research doc following the RPI naming convention: `docs/working/research-{topic}.md`. The synthesized doc must include all RPI-required sections (Scope, What exists, Invariants, Prior art, Gotchas) — sub-agent findings should be reorganized into these sections rather than preserved as separate per-area summaries. Resolve any contradictions or gaps. This synthesized research is what feeds into the plan step of the research-plan-implement workflow.

The main (orchestrating) agent is responsible for writing the final research doc, not the sub-agents. Sub-agents produce raw findings; the main agent structures them into the RPI format.

**Done when...**
- [ ] A unified research doc exists at `docs/working/research-{topic}.md`
- [ ] The doc includes all RPI-required sections (Scope, What exists, Invariants, Prior art, Gotchas)
- [ ] Sub-agent findings are reorganized by section, not preserved as separate per-area summaries
- [ ] Contradictions or gaps between sub-agent findings are resolved or flagged

### 5. Plan and implement sequentially

From here, follow the normal research-plan-implement workflow. The decomposition was about parallelizing *understanding*, not *implementation*. The plan should address the full task as a coherent sequence.

**Done when...**
- [ ] The RPI workflow has been entered with the synthesized research doc as input
- [ ] The plan addresses the full task as a coherent sequence (not as separate per-area plans)

## When to skip

- If the task only touches one subsystem, just do normal research-plan-implement — sub-agents add overhead without benefit.
- If the codebase is small enough that you can read the relevant parts in a few minutes, don't bother decomposing.
- If sub-agent dispatch isn't available in your Claude Code version, do the research sequentially in the main agent. The decomposition list from step 1 is still useful as a research checklist even without parallelism.
