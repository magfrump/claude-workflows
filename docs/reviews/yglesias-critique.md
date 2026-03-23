# Yglesias-Style Critique: Code Review Orchestrator

## The Goal vs. the Mechanism

The goal is right: multi-perspective code review that catches what single-pass review misses. Security problems, performance regressions, API inconsistencies — these are real failure modes, and catching them before merge is genuinely valuable.

But the mechanism has a structural problem: it optimizes for *thoroughness of analysis* when the bottleneck in most code review is *author response to findings*. A rubric with 15 findings across 5 severity tiers doesn't get acted on faster than a rubric with 5 findings in 2 tiers. In fact, it gets acted on slower, because the author has to triage the triage.

The cross-critic escalation rule (2+ critics flag the same issue → escalate one tier) is the mechanism's best feature — it surfaces signal through convergence. But the rest of the pipeline generates a lot of noise to feed into that convergence detector. Three core critics plus up to three contextual critics plus a fact-checker means 4-7 agents producing findings that the orchestrator must then cross-reference semantically. The convergence detection is described as "semantic — same file region plus overlapping concern — not mechanical keyword matching," which means the orchestrator has to do sophisticated NLP on the outputs of its own sub-agents. That's where the real analytical difficulty lives, and it's handwaved.

## The Boring Lever

The boring lever nobody's pulling: **most code review value comes from a single experienced reviewer reading the diff with full context**. The fancy multi-agent pipeline is solving for breadth of perspective, but the actual failure mode in code review is usually *not reading carefully enough*, not *not having enough frameworks*.

A simpler version: run the fact-checker (which catches concrete, verifiable issues like stale comments, wrong function signatures, dead code references) and then run *one* critic — whichever is most relevant to the change. Security changes get a security reviewer. Performance-sensitive paths get a performance reviewer. The auto-selection logic for contextual critics already demonstrates that the orchestrator knows which concerns are relevant. Use that same logic to pick the *primary* critic, not to pile on additional ones.

The 80/20 version is probably: code-fact-check + the single most relevant critic + a good diff summary. That gives you verifiable facts plus one structured analytical lens plus enough context to act on findings.

## Follow the Money (Follow the Complexity/Effort)

Let's trace what actually happens when this pipeline runs:

1. **Scope determination** — cheap. Git diff, done.
2. **Discover and classify critics** — the orchestrator reads all skill files, classifies them into orchestrators/fact-checkers/core/contextual/prose. This is hardcoded taxonomy work dressed up as discovery. The list of what's an orchestrator, what's core, what's contextual — it's all specified inline. "Discovery" means "read the files and apply the classification I already know." This is fine, but calling it discovery creates a maintenance trap: if someone adds a new skill, the classification logic lives in the orchestrator's prose, not in the skill's metadata.
3. **Auto-select contextual critics** — reasonable. Checking whether test files changed, whether dependency manifests changed, whether the diff is large. Concrete heuristics.
4. **Stage 1: Fact-check** — one agent, reasonable cost.
5. **Fact-check gate** — good design. Prevents wasting downstream compute on a diff with known factual problems.
6. **Stage 2: Critics** — 3-6 agents in parallel. Each agent reads the full skill file, runs its own git diff, reads the fact-check results. This is where the compute cost multiplies. Each agent is doing redundant work (reading the same diff) and producing findings that overlap (security and performance critics both notice the same N+1 query, but frame it differently).
7. **Stage 3: Synthesis** — the orchestrator reads all outputs, detects convergence, maps severities, produces two deliverables. This is the hardest step and gets the least specification. The unified severity mapping table is precise, but the actual cognitive work of "semantic convergence detection" is described in one sentence.

The effort distribution is inverted: the cheapest steps (scope, discovery) get the most specification. The hardest step (synthesis with convergence detection) gets the least.

## Factual Foundation

The fact-check found 18 claims, 13 accurate, 3 mostly accurate, 0 inaccurate, 2 unverified. The draft is factually solid. The "7-9 domain-specific cognitive moves" claim is technically imprecise (all three critics have exactly 9), but this is minor. The Agent tool vs. Task tool divergence between code-review and draft-review is a real consistency issue worth addressing but not a factual error — it's a design choice that creates maintenance surface area.

## The Scale Test

What happens when this pipeline reviews a 50-file, 2000-line diff? Three things break:

1. **Context budget**: The skill says "pass scope, not diffs" so each agent runs its own git diff. Good — but each agent still has to *read* that diff plus its skill instructions plus the fact-check results. A 2000-line diff in a 200K context window doesn't leave much room for analysis. The pipeline doesn't have a "diff is too large, decompose further" escape valve.

2. **Finding volume**: 6 critics each producing 5-10 findings means 30-60 items to cross-reference for convergence. The synthesis step becomes a classification nightmare. The rubric format (tables with columns) doesn't scale past ~20 rows before it becomes unreadable.

3. **Contextual critic trigger cascade**: A 50-file diff will trigger all three contextual critics (tech-debt-triage triggers at 10+ files, test-strategy triggers because *some* source files won't have matching test changes, dependency-upgrade triggers if any manifest file is touched). So you always run the maximum number of agents on big diffs — exactly when each agent has the hardest job and the synthesis is most complex.

The irony: the pipeline is most likely to run at full capacity on the diffs that least benefit from it. Large diffs need decomposition into reviewable chunks, not more parallel reviewers reading the same overwhelming diff.

## The Org Chart

The institution executing this is Claude Code with sub-agents. The track record of LLM sub-agents is: good at structured analysis with clear prompts, bad at nuanced judgment calls, inconsistent at cross-referencing.

The orchestrator is asking sub-agents to do things they're good at (apply a checklist of cognitive moves to a code diff) and then asking the orchestrator to do things that are harder (semantic convergence detection across multiple outputs). This is the right division of labor in principle, but the orchestrator's synthesis instructions are underdetermined. "Convergence detection is semantic — same file region plus overlapping concern — not mechanical keyword matching" is a capability assertion, not an instruction.

The sub-agents save their reports to `docs/reviews/`. The orchestrator reads those reports. But wait — do the sub-agents actually save files, or do they return results through the Agent tool? The pipeline says both: "Instruct the agent to save its report as `docs/reviews/code-fact-check-report.md`" and also "Wait for the fact-check agent to return results." If the orchestrator is reading the results from the Agent tool's return value, the saved files are an artifact for the human, not a pipeline dependency. This is fine but should be explicit.

## Political Survival (Adoption Viability)

Does this create defenders or opponents? The pipeline creates a visible artifact (the rubric) that authors can reference, which is good for adoption. But it also creates friction: running 4-7 agents takes time and produces findings the author must respond to. If the findings are mostly noise, the pipeline gets skipped. If the findings are mostly real, the pipeline gets valued.

The key adoption risk: **the rubric's severity mapping is rigid, and contextual critics are permanently advisory**. If test-strategy consistently catches real bugs that the core critics miss, there's no mechanism to promote it to core status. The classification is hardcoded in the orchestrator's prose. Over time, the static taxonomy will diverge from actual value delivered.

The `--include`, `--exclude`, and `--only` flags are a good escape valve. Users who find the pipeline too noisy can scope it down. But the default should be lean (fewer critics, run more on request) rather than comprehensive (all critics, skip some on request). Default-comprehensive pipelines accumulate cruft; default-lean pipelines get extended when they prove useful.

## The Cost Disease Check

This is the complexity inflation risk: the orchestrator pattern is already being instantiated twice (draft-review, code-review), and each instantiation adds domain-specific features (auto-selection, unified severity mapping, cross-critic escalation). The next instantiation will add its own features. Each feature increases the maintenance surface of the pattern document and the divergence between instantiations.

The Agent tool vs. Task tool split is exhibit A. Draft-review uses Task tool, code-review uses Agent tool. This isn't explained in the pattern document, so the next person instantiating the pattern has to guess which to use. Small divergences like this accumulate into a pattern that's a guideline in name only.

The unified severity mapping table is exhibit B. It maps each critic's severity levels to rubric tiers, but the mapping is asymmetric — Performance's "High" maps to amber while Security's "High" maps to red. This is an intentional design choice (security issues are more urgent), but it means the mapping table must be updated for every new critic type, and the rationale for each mapping lives only in the table itself.

## Overall Assessment

The code-review orchestrator is a well-structured, thoughtfully designed pipeline that solves a real problem (multi-perspective code review) using a proven pattern (the draft-review orchestrator). The fact-check gate, cross-critic escalation, and contextual critic auto-selection are genuinely good ideas.

But the pipeline is over-built for its most common use case and under-specified for its hardest step. Most code reviews would benefit more from one good critic than three mediocre ones running in parallel. The synthesis step — where convergence detection actually happens — needs more specification, not less. And the default-comprehensive posture (3 core critics always, plus contextual critics triggered by heuristics) will push users toward `--only` overrides rather than trusting the defaults.

Three concrete suggestions:

1. **Default to the single most relevant critic**, selected by the same heuristics that currently select contextual critics. Let `--full` or `--all-critics` activate the multi-critic pipeline. This makes the common case fast and the comprehensive case opt-in.

2. **Specify the convergence detection step**. What does "same file region" mean — same file? Same function? Same 10-line range? What does "overlapping concern" mean — same category? Same root cause? This is the step that determines whether the escalation rule fires, and it's described in one sentence.

3. **Add a decomposition escape valve for large diffs**. When the diff exceeds a threshold (say, 1000 lines or 20 files), suggest decomposing into per-directory or per-subsystem reviews rather than running all critics on the full diff. The per-commit decomposition option (option 11 in the decision doc) was considered and not chosen, but some form of decomposition for large inputs would prevent the pipeline from degrading exactly when it's most needed.

The draft is solid infrastructure. The question is whether anyone will use the full pipeline when `--only security-reviewer` is right there.
