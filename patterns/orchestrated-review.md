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

#### Goal preamble

Every dispatched sub-agent prompt should begin with a 3-line **Goal preamble** prepended above the role-specific skill content. This is drift-prevention infrastructure: a sub-agent can produce output that is well-formed within its skill but mis-aligned with what the orchestration was actually trying to achieve. The preamble pins each dispatch to the user's outcome, the sub-agent's specific assignment, and the artifact it owes back, so role detail is interpreted in service of those three anchors. Workflows that follow this pattern should require the preamble in their dispatch instructions and cite this section.

Canonical form — three lines, exactly:

```
User goal: <user's high-level outcome — what the human ultimately wants from this orchestration>
Current task: <this sub-agent's specific assignment — narrower than the user goal>
Success criterion: <what "done" looks like for this sub-agent — usually the artifact + path it must produce>
```

Cap at 3 lines. Constraints, scope notes, and reminders belong in the role-specific content that follows; expanding the preamble dilutes its purpose.

Field semantics:

- **User goal** — the outermost frame. Same across all sub-agents in a single orchestration run.
- **Current task** — narrower than the user goal. Different per sub-agent. One imperative sentence.
- **Success criterion** — the artifact this sub-agent must produce, ideally with the output path. Not the orchestrator's downstream synthesis success — this sub-agent's local "done" bar.

Worked example — same dispatch (security critic in a code-review orchestration), filled well vs filled badly.

**Well-filled (drift-resistant):**

```
User goal: Get a comprehensive code review on the current branch before opening a PR.
Current task: Run security design review on the diff between the current branch and main.
Success criterion: A markdown report saved to docs/reviews/security-review.md, structured per the security-reviewer skill.
```

**Badly filled (drift-prone):**

```
User goal: Review the code.
Current task: Be a security reviewer.
Success criterion: Write a good security review.
```

The bad version fails on each line. *User goal* is so generic it could prefix any orchestration, so the sub-agent learns nothing about which frame to apply. *Current task* restates the skill's identity instead of narrowing its assignment, so the sub-agent defaults to its skill template regardless of context. *Success criterion* names neither an artifact nor a path, so the sub-agent invents an output shape the orchestrator may not be able to consume during synthesis. Getting one line right does not save you if the others are vague — each anchor needs to land independently.

#### Goal-alignment self-report

Every dispatched sub-agent must append a short **Goal-Alignment Note** at the end of its required output. The note exists so the orchestrator can detect coverage gaps, intentional scope cuts, and escalations without re-reading the full critique. Workflows that follow this pattern should require the note in their dispatch instructions and cite this section.

Canonical form — three required bullets, plus one optional bullet (see below). One short line each, no padding:

```markdown
## Goal-Alignment Note
- Answered: [yes / partial / no — one phrase on what was / wasn't addressed]
- Out of scope: [what was set aside and why, or "none"]
- Escalate: [what the orchestrator should action separately, or "nothing"]
- Questions I would have asked: [1-3 short questions, only if scope was unclear; otherwise omit this bullet]
```

The note is read by the orchestrator during synthesis, not by humans, so brevity matters more than prose. Sub-agents that pad these bullets with extra detail are doing the orchestrator's synthesis work and should be corrected.

#### Questions I would have asked (optional)

The fourth bullet exists to replace the silent-guess failure mode: when a sub-agent receives an under-specified prompt, it would otherwise pick a plausible interpretation, run with it, and never surface that a guess was made. Listing 1-3 questions the sub-agent would have asked the orchestrator if it could lets the synthesis step flag genuine scope ambiguity for the user instead of laundering it as confident output.

Rules:
- **Omit the bullet entirely when scope was clear.** A blank or "none" placeholder defeats the purpose — if you didn't have to guess, leave the bullet out.
- **Cap at 3 questions.** Pick the questions whose answers would have changed your output, not every clarification you can imagine. The cap exists to keep the note scannable; sub-agents that emit longer lists are reintroducing the noise the goal-alignment note was designed to avoid.
- **Each question is one short line.** Phrase as a question, not a hedged statement. "Did you want test files included in scope?" beats "Unclear whether test files are in scope."
- **Tie each question to a guess you actually made.** The bullet documents decisions that could have gone the other way given different orchestrator intent — not generic curiosity about the codebase.

When this bullet is present, the orchestrator surfaces the questions during synthesis (typically under a "Questions to clarify" heading), attributes them to the sub-agent that raised them, and presents them alongside findings rather than burying them. Multiple sub-agents asking the same question is a strong signal the orchestrator under-specified the prompt and should de-duplicate before surfacing. See worked examples in [`skills/code-review.md`](../skills/code-review.md) and [`skills/draft-review.md`](../skills/draft-review.md).

#### Default output cap

Every dispatched sub-agent should have an output cap stated in its dispatch instructions. The recommended default convention is:

> `<300 words summary; structured output may extend.`

What this means:

- **Prose** (narrative findings, recommendations, explanations) fits within ~300 words. Sub-agents that exceed this are usually padding or doing the orchestrator's synthesis work.
- **Structured output** (rubrics, decision matrices, tables, code-review reports with required fields) may extend beyond the cap when the structure itself is the deliverable. The cap applies to the prose around the structure, not the structure.
- The **Goal-Alignment Note** above is bounded separately by its three-bullet form and does not count against the cap.

Why a cap: the orchestrator must read every sub-agent's output during synthesis. A bounded prose budget keeps synthesis cost predictable and pushes sub-agents to surface conclusions rather than buried-lede analysis.

Workflows whose domain genuinely needs more prose should override the default explicitly in the dispatch instructions and state why (e.g., "report in under 600 words because architectural narratives need room"). Workflows that don't specify a cap inherit this default.

#### Context curation

Every dispatch prompt is curated by the orchestrator. The point of curation is **drift prevention**, not byte-savings — context budget is rarely the binding constraint, but unfiltered upstream material reliably pulls a sub-agent off its assigned slice (re-litigating decisions already made upstream, critiquing material outside its scope, or anchoring on the previous agent's framing instead of the orchestrator's question). The 200-line fact-check excerpt rule in `skills/code-review.md` is the prototype: paste only the findings rated Incorrect / Stale / Mostly Accurate so the critic stays focused on what's actually contestable. Workflows that follow this pattern should curate every dispatch the same way and cite this section.

Apply the same shape at every dispatch site:

- **Include** — (1) the goal preamble: one or two sentences naming what this sub-agent is meant to produce and how its output will be used; (2) the scope spec: the exact slice the sub-agent should examine (files, directories, diff scope, draft passage), with instructions to gather its own primary evidence (e.g., run its own `git diff`) rather than relying on a paste; (3) only the relevant section of any upstream artifact — the specific findings, claims, or constraints that bear on this sub-agent's task.
- **Exclude** — (1) the prior-conversation transcript between user and orchestrator (the goal preamble replaces it); (2) any upstream report pasted whole when it exceeds the per-skill cap (e.g., the full fact-check report past 200 lines, the full research doc, the full draft when only one section is being critiqued); (3) findings that are settled, off-topic for this sub-agent's domain, or already reflected in the goal preamble.
- **Fallback (summary-with-link)** — when an upstream artifact exceeds the cap and you cannot cleanly pull "only the relevant section," paste a short orchestrator-written summary of what the sub-agent needs to know plus the artifact's path on disk (e.g., `docs/reviews/fact-check-report.md`). Sub-agents share the filesystem with the orchestrator and can read the full file if they need to. The summary, not the path, is what shapes the sub-agent's behavior — write it deliberately.

Per-skill caps (the 200-line threshold, the short-draft reduced panel) are calibrations of this rule, not separate rules. New orchestrators should pick a cap appropriate to their domain and apply the Include / Exclude / Fallback shape above rather than re-deriving the principle.

#### Legibility-target tagging

Every finding a sub-agent emits must declare its intended audience with a **legibility-target** tag. The tag does two jobs: it lets the orchestrator rank and filter findings during synthesis without re-reading them, and it tells the sub-agent how deeply to phrase the finding (full prose vs. terse signal). Workflows that follow this pattern should require the tag in their dispatch instructions and cite this section.

Three values, fixed for now:

- **`for-author`** — the human who wrote or maintains the code. Phrase as direct guidance: location, evidence, attack scenario or failure mode where applicable, and a recommendation. This is the default for any actionable finding.
- **`for-orchestrator-synthesis`** — the orchestrator agent doing synthesis. Phrase terse and structured. Used for coverage observations ("no issues found in area X"), cross-critic convergence hints, and "looks correct" confirmations that help the orchestrator decide what to surface but don't need to be shown to the author verbatim.
- **`for-automated-gate`** — a downstream automated check (CI gate, halt rule, blocking-vs-merging signal). Phrase as a parseable directive: pattern name, location, severity verdict. Reserve for findings whose primary consumer is a machine, not a person.

Canonical form on a finding — a single-line field alongside severity/confidence:

```markdown
**Legibility-target:** for-author
```

How orchestrators consume the tag during synthesis:

- **Filter:** `for-orchestrator-synthesis` findings are absorbed into orchestrator reasoning (coverage maps, convergence detection) and typically not surfaced verbatim to the user.
- **Rank:** within a tier, `for-author` findings are surfaced before `for-orchestrator-synthesis` ones; `for-automated-gate` findings drive status lines and escalation blocks rather than appearing as prose bullets.
- **Calibration check:** if a sub-agent tags every finding `for-author`, the dispatch instruction is failing to communicate the distinction. The orchestrator should treat uniform tagging as a signal to refine its critic prompt, not as ground truth.

The taxonomy is intentionally narrow at three values. Expansion (e.g., a `for-reviewer-followup` or `for-author-future-revision` tag) is reserved for future rounds when usage data shows that the existing three values are conflating distinct audiences. Adding values speculatively defeats the calibration purpose.

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
