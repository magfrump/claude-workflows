# Pattern: Orchestrated Review

## What this is

A recurring structural pattern found across several workflows in this repo. This is not a workflow you run directly — it's a reference for understanding shared structure and for authoring new workflows that follow the same shape.

## The pattern

Four phases, each with a domain-specific implementation:

### 1. Decompose

Break the input into independent units that can be evaluated separately.

- **In task decomposition**: Identify independent sub-investigations across subsystems
- **In PR prep**: Identify commits to clean up and files to self-review
- **In divergent design**: Generate candidate approaches (the "diverge" step)

**Extension point**: What constitutes a "unit" and how you discover units varies by domain. Some domains decompose by structure (subsystems, files), others by content (approaches, critique angles).

### 2. Parallel dispatch

Process units concurrently using sub-agents, each with a focused prompt and bounded scope.

- **In task decomposition**: Dispatch sub-agents per independent area, each reading specific files and answering specific questions
- **In PR prep**: Review-fix loop dispatches `/code-review`, `/self-eval`, documentation check, and dependency audit in parallel
- **In divergent design**: Evaluate candidates against constraints (the match-and-prune matrix)

**Extension point**: Whether dispatch is literally parallel (sub-agents) or sequential-but-independent depends on the domain and tooling. The key property is that units don't depend on each other's results.

**Terminology note**: Use "sub-agent" consistently for the parallel execution mechanism, regardless of whether the underlying implementation uses the Task tool, Agent tool, or manual sequential processing.

#### Goal-alignment self-report

Every dispatched sub-agent must append a short **Goal-Alignment Note** at the end of its required output. The note exists so the orchestrator can detect coverage gaps, intentional scope cuts, and escalations without re-reading the full critique. Workflows that follow this pattern should require the note in their dispatch instructions and cite this section.

Canonical form — three bullets, one short line each, no padding:

```markdown
## Goal-Alignment Note
- Answered: [yes / partial / no — one phrase on what was / wasn't addressed]
- Out of scope: [what was set aside and why, or "none"]
- Escalate: [what the orchestrator should action separately, or "nothing"]
```

The note is read by the orchestrator during synthesis, not by humans, so brevity matters more than prose. Sub-agents that pad these bullets with extra detail are doing the orchestrator's synthesis work and should be corrected.

### 3. Synthesize

Collect parallel outputs into a single coherent artifact.

- **In task decomposition**: Merge sub-agent findings into a unified research doc (RPI format)
- **In PR prep**: Produce a PR description summarizing intent, approach, and uncertainty
- **In divergent design**: Produce a tradeoff matrix comparing survivors

**Extension point**: The synthesis format is domain-specific. Research produces a structured doc, review produces a summary with recommendations, design produces a decision matrix. The main agent (not sub-agents) owns synthesis — it resolves contradictions and imposes structure.

### 4. Gate

A decision point that determines whether to proceed, revise, or escalate.

- **In task decomposition**: Feeds into RPI's plan gate (human reviews before implementation)
- **In PR prep**: Human reviewer decides whether to merge
- **In divergent design**: 80% confidence threshold — proceed autonomously or consult user
- **In draft review**: Optional mid-pipeline gate — if fact-check finds high-confidence inaccuracies, pause before running critics so the user can revise

**Extension point**: Gate semantics vary significantly. Some gates are human checkpoints, some are confidence thresholds, some are automated checks. The gate type should be chosen based on the cost of proceeding incorrectly.

**Positioning note**: Gates don't have to come at the end. When a pipeline has multiple stages with increasing cost, an early gate between stages can prevent wasted work. The key question is: "If the upstream result changes the input to downstream stages, should we pause?" If yes, insert a conditional gate.

## Using this pattern in new workflows

When creating a workflow that involves breaking work into parts, processing them, and combining results, consider whether it follows this shape. If so:

1. Add a cross-reference: "This workflow follows the [orchestrated review pattern](../patterns/orchestrated-review.md)"
2. Define each phase explicitly — what are the units, how are they dispatched, what's the synthesis format, what's the gate
3. Diverge from the pattern where the domain requires it — approximate fit is expected. Document why if the divergence is non-obvious

## Existing and potential instantiations

- **Codebase onboarding** (`workflows/codebase-onboarding.md`): Decompose into subsystems, dispatch sub-agents per subsystem to explore in parallel, synthesize into orientation document, gate on team validation

- **Code review pipeline** (`skills/code-review.md`): Decomposes into code-fact-check + domain critics (`security-reviewer`, `performance-reviewer`, `api-consistency-reviewer`) with optional contextual critics (`test-strategy`, `tech-debt-triage`, `dependency-upgrade`) auto-selected based on diff characteristics. Dispatches all critics in parallel after fact-check gate, synthesizes into chat summary + code review rubric with unified severity mapping and cross-critic escalation. See `docs/decisions/002-critic-style-code-review.md`.
- **Test planning** (potential): Decompose into test categories (unit, integration, edge cases), generate test cases per category, synthesize into a test plan, gate on coverage
