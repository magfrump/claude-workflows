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

### 1. Capture the original goal and identify independent sub-investigations

Before starting research, capture the user's original goal text verbatim — copy the exact request (or the closest single statement of the desired outcome) into the working notes that will become the synthesized research doc. The recompose step (step 6) checks the sum of sub-task findings against this verbatim text, so paraphrasing here weakens the later coverage check.

Then assess whether the task touches multiple independent subsystems. If so, list them:

- What are the distinct areas of the codebase involved?
- Can each area be researched without understanding the others first?
- Are there shared dependencies that need to be researched before the area-specific work?

Example decomposition for "add API endpoint with auth and rate limiting":
- **Shared dependency**: How does the existing routing/middleware pipeline work?
- **Independent area A**: How does auth work in this codebase?
- **Independent area B**: Is there existing rate limiting? What library/approach?
- **Independent area C**: What's the data model for the resource being exposed?

#### Quality signals — when not to decompose

Independence isn't binary. Two areas can look separate on a directory map but be tightly coupled at runtime, and sub-agents researching them in parallel will produce findings that contradict each other once you try to integrate them. Step 4 catches such contradictions downstream via reconciliation, but reconciling assumptions after the fact wastes the parallelism you decomposed for. Catch coupling upstream by checking these signals before dispatching:

- **Shared mutable state across areas.** If the candidate areas read or write the same in-memory store, cache, global config, session object, or database row through different code paths, they aren't independent — a sub-agent looking at one path can't reason about invariants without knowing what the other path does.
- **More than 2 shared interfaces.** A small number of shared interfaces (data shapes, function contracts, error conventions) is normal and step 4 reconciliation handles it. Three or more is a coupling smell: the areas are effectively one subsystem with internal seams, and sub-agents will repeatedly need to make assumptions about each other's behavior.
- **Monorepo cross-package imports between areas.** If area A's code imports from area B's package (or vice versa), the dependency graph contradicts the decomposition. Sub-agents told to research one package in isolation will miss the imported behavior.

If any signal fires, consolidate the affected areas into a single sub-investigation (or research them sequentially in the main agent) before proceeding to step 2. Document the consolidation briefly so the reasoning is visible to reviewers.

#### Capture interface contracts before dispatch

When **two or more sub-agents will be dispatched** in step 3, add an `## Interface contracts` subsection to the working notes *before* dispatching. The contracts make explicit the shared shapes the sub-investigations will collide on, so step 4 (Reconcile) can verify each one against a prediction rather than discovering conflicts organically.

For each interface that spans two or more sub-investigations, write a contract entry naming:

- **(a) Data shape** — the schema, type, struct fields, or message format that crosses the boundary. Be concrete (e.g., `User { id: UUID, email: string, role: enum(admin, member) }`), not vague (e.g., "the user object").
- **(b) Error mode** — how failure surfaces (raised exception type, `null` / `None` return, `Result<T, E>`, `(value, ok)` tuple, HTTP status, etc.). Name the actual mechanism the code uses.
- **(c) Codebase example** — at least one file:line reference showing the existing shape in use, so sub-agents (and the reconciliation step) can compare against ground truth.

Example contract entry:
> **Interface: `AuthMiddleware → Handler` user context**
> (a) Shape: `context.Context` carrying `auth.User{ID uuid.UUID, Email string, Role auth.Role}` under key `auth.userCtxKey`.
> (b) Error mode: middleware writes `401 Unauthorized` and returns without calling the handler; handlers can assume the user is present.
> (c) Example: `src/middleware/auth.go:42` sets the value; `src/handlers/profile.go:18` reads it via `auth.UserFrom(ctx)`.

**Escape line.** If sub-investigations genuinely share no interface, write the line verbatim in place of contract entries: `no shared interfaces — sub-investigations are fully independent`. Use this only when no data, no error type, and no naming convention crosses between the sub-tasks. If you're unsure, write the contracts — the cost is low.

**Done when...**
- [ ] The original goal text is captured verbatim (not paraphrased) for later use by the recompose step
- [ ] The distinct areas of the codebase involved are listed
- [ ] Each area is labeled as either a shared dependency or an independent sub-investigation
- [ ] Independent areas can be researched without understanding the others first
- [ ] Shared dependencies (if any) are identified and will be researched before independent areas
- [ ] Each candidate area pair has been checked against the quality signals (shared mutable state, >2 shared interfaces, cross-package imports) and any consolidation is documented
- [ ] If ≥2 sub-agents will be dispatched, the working notes contain an `## Interface contracts` subsection with one entry per shared interface (each naming data shape, error mode, and ≥1 codebase example), OR the explicit escape line `no shared interfaces — sub-investigations are fully independent`

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

A sub-agent starts with zero context. This workflow follows the [orchestrated review pattern](../patterns/orchestrated-review.md), so every dispatch must carry the same dispatch discipline `code-review`, `draft-review`, and `spike` use when they orchestrate parallel investigation — not just a freeform "brief it like a colleague" prompt:

- **Goal preamble.** Prepend the [3-line goal preamble](../patterns/orchestrated-review.md#goal-preamble) (User goal / Current task / Success criterion) above the role-specific instructions. The **User goal** — the feature or change driving the decomposition — is identical across every sub-agent in the run; **Current task** and **Success criterion** vary per sub-investigation. This is the orchestrated-review conformance the file's intro claims; without it the dispatch is just a freeform prompt.
- **Goal-Alignment Note.** Require each sub-agent to append a [Goal-Alignment Note](../patterns/orchestrated-review.md#goal-alignment-self-report) at the end of its output. The reconciliation step (step 4) and synthesis (step 5) read these notes to surface coverage gaps, intentional scope cuts, escalations, and silent guesses across sub-investigations — drift that task-decomposition would otherwise absorb silently into the synthesized research doc.

The canonical 3-line shape, applied to the auth sub-investigation from the running "API endpoint with auth + rate limiting" example:

```
User goal: Add an authenticated, rate-limited API endpoint to the reports service.
Current task: Examine `src/auth/` and `src/middleware/auth.go` and answer: (1) how are tokens validated, (2) where is the middleware applied, (3) what happens on auth failure.
Success criterion: Findings written to the "Auth" section of `docs/working/research-api-endpoint.md`, with a Goal-Alignment Note appended at the end.
```

The same preamble wraps the other sub-investigations in the running example — only Current task and Success criterion change per area:

**Example — cross-cutting pattern search (Current task / Success criterion):**
> Current task: Find all places rate limiting is applied in this codebase. For each, note: which library, what limits, whether it's per-user or global. The routing middleware is in `src/server/router.go` — start there.
> Success criterion: Findings in the "Rate limiting" section of `docs/working/research-api-endpoint.md`, under 200 words, with a Goal-Alignment Note appended.

**Example — dependency analysis (Current task / Success criterion):**
> Current task: Read `package.json` and `src/pdf/generator.ts`. We're evaluating whether to replace the PDF library. Answer: What API surface do we actually use? How coupled is our code to this specific library? Are there test fixtures that depend on exact output?
> Success criterion: Findings in the "PDF library" section of the research doc, with a Goal-Alignment Note appended.

**End-to-end example — parallel dispatch and recompose:** Continuing the API endpoint decomposition from step 1, after researching the shared routing/middleware dependency, dispatch three sub-agents in parallel by issuing three Agent tool calls in a single response — one for auth, one for rate limiting, one for the resource data model. Each prompt scopes its investigation tightly: the auth sub-agent examines `src/auth/` and reports token validation, where middleware is applied, and failure behavior; the rate-limiting sub-agent searches the codebase for existing rate-limit usage and reports library, configured limits, and whether keys are per-user or global; the data-model sub-agent reads the resource schema and reports field shapes and validation rules. All three return findings concurrently. In the recompose step, the main agent reads each report, checks for conflicts at shared interfaces (e.g., does the auth sub-agent's user-identity field match the rate-limiting sub-agent's rate-limit key?), resolves any conflicts against the actual code, and folds the reconciled findings into the unified research doc's Scope / What exists / Invariants / Gotchas sections — not preserved as three separate per-area appendices.

Common briefing mistakes: omitting file paths in the Current task (sub-agent wastes time searching), writing a Success criterion that names neither an artifact nor a path (sub-agent invents an output shape synthesis can't consume), and not capping output length. The pattern's [default output cap](../patterns/orchestrated-review.md#default-output-cap) — `<300 words summary; structured output may extend.` — applies unless the dispatch overrides it explicitly.

#### Recommended output scaffold

A consistent output shape across sub-agents reduces format-normalization overhead at step 4 (Reconciliation). Suggest sub-agents structure findings as five sections — adapt or omit when an area doesn't fit:

- **Files examined** — paths actually read
- **Findings** — answers to the questions you asked
- **Cross-interface assumptions** — what they assumed about interfaces shared with other sub-investigations
- **Open questions** — things they couldn't answer or weren't asked to investigate
- **Confidence in findings** — high / medium / low, with a brief reason for anything below high

This is a default, not a mandate. A sub-agent doing a focused pattern search may only need Files examined + Findings; a sub-agent reading a complex subsystem benefits from the full scaffold.

Sub-agents should NOT:
- Write or modify source code (risk of conflicts with other sub-agents or the main agent)
- Make architectural decisions (that's the main agent + human's job)
- Proceed to planning or implementation

**Done when...**
- [ ] Each independent area has a sub-agent dispatched (or researched sequentially if sub-agents are unavailable)
- [ ] Each sub-agent prompt prepends the canonical goal preamble (User goal / Current task / Success criterion) and requires a Goal-Alignment Note in the output, with exact files/directories, questions, and the output path named in the Current task / Success criterion
- [ ] All sub-agents have returned their findings, each ending with a Goal-Alignment Note

### 4. Reconcile conflicting assumptions across sub-investigations

Before synthesizing, verify each sub-agent's findings against the **interface contracts** captured in step 1. The contracts are the predictions; the sub-agent findings are the observations. Conflicts get surfaced against the contract (shape, error mode, codebase example) rather than discovered organically by hoping a contradiction jumps out.

For each contract entry recorded in step 1's `## Interface contracts` subsection:
- Walk the relevant sub-agent findings and check what each said about the contract's (a) data shape, (b) error mode, and (c) actual usage versus the cited codebase example.
- If a sub-agent's finding disagrees with the contract, resolve by reading the actual code (the ground truth) — don't pick the contract or the sub-agent's version arbitrarily. Then update the contract entry to match the code, and re-check any other sub-agent finding that depended on the old prediction.
- If two sub-agents disagree with each other on a contract they both touched, the contract was the prediction and the code is the tiebreaker — same rule applies.
- Document each contract's outcome in the research doc under a **Reconciliation** heading: which contracts held as predicted, which were revised, and how each conflict was resolved. If no conflicts were found, note that explicitly (e.g., "All N contracts held as predicted").

If step 1 used the escape line (`no shared interfaces — sub-investigations are fully independent`), this step is a quick sanity check: skim the sub-agent findings to confirm no unexpected shared interface emerged. If one did, capture it as a late-added contract entry and reconcile it now. Record the result under **Reconciliation** (e.g., "Escape line held: no shared interfaces surfaced" or "Late contract added: …").

**Evidence-tag tiebreaker.** When reading the code to resolve a conflict isn't immediately possible and you must weigh the sub-agent findings themselves, prefer evidence by its RPI confidence tag: `[observed]` outranks `[inferred]`, which outranks `[assumed]` (absent staleness signals). This only orders the findings pending a code read — it is not a substitute for verifying against ground truth. The load-bearing case is the tie: if **two sub-agents both claim `[observed]`** for contradictory readings of the same contract, do **not** silently pick one — escalate to the user with both conflicting passages, since two direct observations disagreeing signals the contract or the code itself is ambiguous in a way the orchestrator shouldn't resolve by fiat.

**Done when...**
- [ ] Each contract entry from step 1 has been verified against the sub-agent findings (shape, error mode, codebase example)
- [ ] Contracts that the findings revised have been updated to match the actual code, and dependent findings re-checked
- [ ] Conflicts are resolved by verifying against actual code, not by choosing one sub-agent's version or the original contract
- [ ] A Reconciliation section exists in the research doc listing each contract's outcome (held / revised / late-added), or — if the escape line was used — confirming no shared interfaces emerged

### 5. Synthesize into a unified research doc

Collect sub-agent outputs into a single research doc following the RPI naming convention: `docs/working/research-{topic}.md`. The synthesized doc must include all RPI-required sections (Scope, What exists, Invariants, Prior art, Gotchas) — sub-agent findings should be reorganized into these sections rather than preserved as separate per-area summaries. Resolve any contradictions or gaps. This synthesized research is what feeds into the plan step of the research-plan-implement workflow.

The main (orchestrating) agent is responsible for writing the final research doc, not the sub-agents. Sub-agents produce raw findings; the main agent structures them into the RPI format.

**Done when...**
- [ ] A unified research doc exists at `docs/working/research-{topic}.md`
- [ ] The doc includes all RPI-required sections (Scope, What exists, Invariants, Prior art, Gotchas)
- [ ] Sub-agent findings are reorganized by section, not preserved as separate per-area summaries
- [ ] Contradictions or gaps between sub-agent findings are resolved or flagged

### 6. Recompose: verify the original goal is met by the sum of sub-tasks

When sub-investigations rejoin at synthesis time, re-verify that the combined findings cover the original goal. Decomposition is lossy in two ways: a goal element that doesn't fit any sub-task neatly can be silently dropped during the split, and a finding that addresses a goal element gets reorganized into an RPI section (Invariants, Prior art, etc.) at synthesis time, so its connection to the goal element it answers becomes implicit. Without an explicit recompose check, gaps surface during planning or implementation rather than research, when they're more expensive to fix.

This step complements step 4 (Reconcile). Reconcile catches *conflicting* assumptions across sub-investigations; recompose catches *missing* coverage of the original goal. Run them both.

In the synthesized research doc:

1. Add an **Original goal** section near the top that quotes the user's original goal text verbatim (the same text captured in step 1). Do not paraphrase — the verbatim copy is what makes the coverage check unambiguous.
2. Add a **Coverage check** section that maps each element of the goal to the sub-task finding(s) that address it. Format as a list or table; if the goal has N distinct elements, the coverage check has N rows.
3. Treat any goal element with no sub-task coverage as a gap. Resolve it before planning, either by:
   - Dispatching an additional sub-agent (or main-agent research pass) to fill the gap, or
   - Explicitly acknowledging the element as scoped out of this loop, with a one-line justification (e.g., "deferred to follow-up: requires UX input not available this session").

A gap acknowledged in writing is fine; a gap silently dropped is not. The point of the recompose step is to make the choice visible.

**Done when...**
- [ ] The synthesized research doc has an **Original goal** section quoting the user's original goal text verbatim
- [ ] The synthesized research doc has a **Coverage check** section mapping each element of the goal to the sub-task finding(s) that address it
- [ ] Every goal element either has at least one sub-task finding that addresses it, or is explicitly acknowledged as scoped out with a written justification
- [ ] No goal element is silently absent from the coverage check

### 7. Plan and implement sequentially

From here, follow the normal research-plan-implement workflow. The decomposition was about parallelizing *understanding*, not *implementation*. The plan should address the full task as a coherent sequence.

**Done when...**
- [ ] The RPI workflow has been entered with the synthesized research doc as input
- [ ] The plan addresses the full task as a coherent sequence (not as separate per-area plans)

## When to skip

- If the task only touches one subsystem, just do normal research-plan-implement — sub-agents add overhead without benefit.
- If the codebase is small enough that you can read the relevant parts in a few minutes, don't bother decomposing.
- If sub-agent dispatch isn't available in your Claude Code version, do the research sequentially in the main agent. The decomposition list from step 1 is still useful as a research checklist even without parallelism.
