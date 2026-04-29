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

## Goal preamble standard

Every sub-agent dispatch in an orchestrated workflow MUST begin with a 3-line **goal preamble** prepended to the role-specific skill content. The preamble keeps the sub-agent oriented to the user's overall goal, its own assignment, and what success looks like — without re-reading the orchestrator's chat context (which it does not see).

### Template (paste-ready, exactly 3 lines)

```
User goal: <user's high-level outcome — what the human ultimately wants from this orchestration>
Current task: <this sub-agent's specific assignment — narrower than the user goal>
Success criterion: <what "done" looks like for this sub-agent — usually the artifact + path it must produce>
```

Fill each placeholder per dispatch. Keep each line to one sentence.

**Cap at 3 lines.** Do not expand into a fourth line for context, constraints, or reminders. Constraints and detailed instructions belong in the role-specific skill content that follows. The cap exists to keep the preamble scannable; longer preambles induce fatigue and get skimmed past.

### Where to put it

At the very top of the Agent-tool prompt, before the skill-file paste, scope spec, draft text, fact-check digest, or any other content. Sub-agents read top-down; the preamble must arrive before role detail so it frames everything that follows.

### Before / after worked example

A code-review orchestrator dispatching the security critic.

**Before** (no preamble — sub-agent has to infer goal and success from skill content):

```
[full contents of skills/security-reviewer.md pasted here]

Scope: review files changed on the current branch relative to main (run `git diff main...HEAD`).

Fact-check findings to consider:
- Claim "input is sanitized via escapeHtml" rated Incorrect (high confidence)…

Save your critique as docs/reviews/security-review.md.
```

**After** (preamble prepended; nothing else removed):

```
User goal: Get a comprehensive code review on the current branch before opening a PR.
Current task: Run security design review on the diff and produce a written critique.
Success criterion: A markdown report saved to docs/reviews/security-review.md, structured per the security-reviewer skill.

[full contents of skills/security-reviewer.md pasted here]

Scope: review files changed on the current branch relative to main (run `git diff main...HEAD`).

Fact-check findings to consider:
- Claim "input is sanitized via escapeHtml" rated Incorrect (high confidence)…

Save your critique as docs/reviews/security-review.md.
```

The preamble is additive: existing prompt content is unchanged, only prepended to.

### Field semantics

- **User goal** — the outermost frame. The same across all sub-agents in a single orchestration run (e.g., "code review the current branch", "review this draft", "compare these libraries").
- **Current task** — narrower than the user goal. Different per sub-agent (e.g., "run security review", "score all libraries on documentation quality", "research how auth middleware is applied"). One sentence, imperative.
- **Success criterion** — what artifact this sub-agent must produce, ideally with the output path. Not the orchestrator's downstream synthesis success — the sub-agent's local "done" bar.

## Using this pattern in new workflows

When creating a workflow that involves breaking work into parts, processing them, and combining results, consider whether it follows this shape. If so:

1. Add a cross-reference: "This workflow follows the [orchestrated review pattern](../patterns/orchestrated-review.md)"
2. Define each phase explicitly — what are the units, how are they dispatched, what's the synthesis format, what's the gate
3. Diverge from the pattern where the domain requires it — approximate fit is expected. Document why if the divergence is non-obvious

## Existing and potential instantiations

- **Codebase onboarding** (`workflows/codebase-onboarding.md`): Decompose into subsystems, dispatch sub-agents per subsystem to explore in parallel, synthesize into orientation document, gate on team validation

- **Code review pipeline** (`skills/code-review.md`): Decomposes into code-fact-check + domain critics (`security-reviewer`, `performance-reviewer`, `api-consistency-reviewer`) with optional contextual critics (`test-strategy`, `tech-debt-triage`, `dependency-upgrade`) auto-selected based on diff characteristics. Dispatches all critics in parallel after fact-check gate, synthesizes into chat summary + code review rubric with unified severity mapping and cross-critic escalation. See `docs/decisions/002-critic-style-code-review.md`.
- **Test planning** (potential): Decompose into test categories (unit, integration, edge cases), generate test cases per category, synthesize into a test plan, gate on coverage
