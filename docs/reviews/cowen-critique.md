# Cowen-Style Critique: Code Review Orchestrator

**Draft:** `skills/code-review.md` + supporting documents | **Reviewed:** 2026-03-23

---

## The Argument, Decomposed

The code-review orchestrator bundles at least five distinct claims:

1. **Pipeline transferability:** A 3-stage pipeline (fact-check, parallel critics, synthesis) that works for prose also works for code review, with adaptations.
2. **Auto-selection adds value:** Contextual critics (test-strategy, tech-debt-triage, dependency-upgrade) triggered by diff heuristics are better than always-on or manual selection.
3. **Unified severity mapping:** Different critic domains can be meaningfully reduced to a common red/amber/green scale.
4. **Cross-critic escalation:** Independent convergence (2+ critics flagging the same issue) is a reliable signal of importance and warrants automatic tier promotion.
5. **Orchestrator-as-coordinator:** The orchestrator should dispatch but never analyze — strict separation of concerns between coordination and analysis.

These are independent claims. Some could be true while others fail. The draft presents them as a single coherent system, which makes it harder to see where individual joints might crack.

---

## What Survives the Inversion

**Inversion of claim 1:** "A pipeline designed for prose review is actually a poor fit for code review."

There is something to this. Prose review's fact-check stage verifies claims against external reality (statistics, policies, historical events). Code fact-checking verifies internal consistency — do comments match behavior, do docstrings reflect actual signatures. These are structurally different operations. Prose fact-checking answers "is this true about the world?" while code fact-checking answers "is this true about itself?" The self-referential nature of code fact-checking means it is simultaneously more tractable (the ground truth is right there in the diff) and less valuable (the kinds of errors it catches are things a careful reader would notice anyway). The pipeline shape transfers, but the value distribution across stages may shift significantly.

**Inversion of claim 4:** "Cross-critic convergence is noise, not signal."

If two critics flag the same code region, it might mean the code is genuinely problematic — or it might mean the code is simply unfamiliar/complex in a way that triggers multiple heuristics simultaneously. Complexity is not the same as incorrectness. A novel algorithmic approach might get flagged by both the security reviewer ("unusual pattern, could be exploitable") and the performance reviewer ("non-standard approach, could be slow") simply because neither has seen it before. Automatic escalation rewards conservatism — which may be appropriate for code review, but the draft doesn't acknowledge the tradeoff.

What survives: the pipeline shape is reasonable, and convergence is *some* signal. But the draft treats both as stronger than the inversion suggests they are.

---

## Factual Foundation

The fact-check report found the draft factually solid — 13 of 18 claims accurate, 3 mostly accurate, 0 inaccurate. Two findings worth integrating into the critique:

- **"7-9 domain-specific cognitive moves"** — all three critics have exactly 9. The imprecision is minor but interesting because the range framing ("7-9") implies more variation than exists, which subtly overstates the degree to which each critic was independently designed rather than following a template.

- **Agent tool vs. Task tool divergence** — code-review uses the Agent tool while draft-review uses the Task tool. The fact-check correctly flags this as a genuine divergence between the two orchestrators. The draft's central thesis is that the pipeline pattern transfers; an implementation divergence in how sub-agents are dispatched is worth noting because it means someone maintaining both systems needs to track two different dispatch mechanisms for what is presented as "the same pattern."

- **Dynamic discovery vs. static classification** — "List all skills/*.md files" implies runtime discovery, but the classification (which skills are orchestrators, which are core critics, which are contextual) is hardcoded. This is a tension the draft doesn't acknowledge. If someone adds a new skill file, the orchestrator won't discover it as the instructions suggest — they'd need to edit the orchestrator itself.

---

## The Boring Explanation

Before evaluating the orchestrator's design choices, ask: is there a simpler explanation for why a multi-critic code review pipeline might be useful?

The boring explanation: **people don't read diffs carefully, and having multiple prompts forces multiple passes over the same code.** The value may not be in the specialized cognitive moves, the severity mapping, or the escalation rules. It may simply be that making three separate passes with three different "look for X" instructions catches more than one pass with "look for everything." This is the code review equivalent of reading a draft once for structure and once for grammar — the second pass finds things the first missed not because of domain expertise but because of attention refresh.

If the boring explanation accounts for most of the value, several design choices become over-engineered: the auto-selection heuristics, the unified severity mapping, the escalation rules. A simpler system — "run these three prompts in parallel, concatenate the results" — might capture 80% of the benefit at 20% of the specification complexity. The draft is 352 lines. That is a lot of process for what might be "read the diff three times with different instructions."

---

## Revealed vs. Stated

The draft states that contextual critics are "advisory" and "never block merge" — they always go to the green Consider tier. But the system also includes an escalation rule where 2+ critics agreeing promotes a finding one tier. If a contextual critic and a core critic independently flag the same issue, does the contextual critic's finding participate in escalation? The draft says contextual findings "go to Consider tier regardless of their internal severity," but doesn't explicitly say they're excluded from escalation. If they can participate in escalation, the stated "advisory" status is weaker than presented — a contextual critic could effectively block merge by converging with a core critic to push a finding from amber to red.

The decision document reveals something about preferences too: it says "standalone critics let users scope to one concern at a time" as a benefit, but the orchestrator's design encourages running everything at once. The revealed preference of building the orchestrator suggests that scoped single-concern reviews — despite being called out as valuable — are expected to be the minority use case. The system's center of gravity is the full pipeline.

---

## The Analogy

The closest structural analogy is **a compiler pipeline with lint passes.** A compiler runs lexing, parsing, type-checking, and optimization as separate stages. Each pass sees the same code but applies different rules. Some passes are mandatory (type-checking), others are optional (optimization levels). Cross-pass findings get escalated (a type error in an optimization-eligible path blocks compilation).

This analogy is illuminating because compiler pipelines learned two lessons the code-review orchestrator hasn't yet internalized:

1. **Pass ordering matters more than parallelism.** Compilers run passes in a specific order because later passes depend on earlier pass output (type information enables optimization analysis). The code-review pipeline runs critics in parallel — meaning no critic benefits from another critic's findings. This is a deliberate choice (avoiding cross-contamination), but it means the system cannot do the equivalent of "the security reviewer notices a performance pattern that changes the security assessment." The architecture forbids inter-critic learning within a single run.

2. **Incremental re-runs dominate full passes.** Mature compiler pipelines are incremental — they re-analyze only what changed. The code-review pipeline is full-pass: every re-run dispatches all critics again from scratch. The rubric is "designed for re-runs," but the pipeline itself doesn't support incremental review (e.g., "only re-run security-reviewer because the fix only addressed a security finding"). This will become a friction point if the system is used iteratively.

---

## Contingent Assumptions

Several things the draft treats as natural that are actually choices:

1. **Fact-checking precedes critique.** This sequence is inherited from prose review where it makes clear sense (don't critique arguments built on false claims). For code, the case is weaker. A code fact-check verifies comment-behavior alignment. A security reviewer analyzing control flow doesn't particularly need to know whether a comment is stale first. The sequencing adds latency (fact-check must complete before critics start) for uncertain benefit in the code domain.

2. **Three tiers is the right number.** Red/amber/green is a familiar traffic-light metaphor, but the mapping is doing significant compression. Security maps Critical and High to red. Performance maps only Critical to red. This asymmetry — noted by the fact-check report — means the tiers don't represent equivalent severity across domains. A "red" finding from security could be less severe than a "red" finding from performance, or vice versa, depending on where the boundary was drawn. The unified mapping creates an illusion of commensurability.

3. **The orchestrator should never analyze.** Rule 1 is emphatic: "If you find yourself writing analytical observations about the code, STOP." This is a strong architectural constraint. It prevents the orchestrator from noticing cross-cutting patterns during synthesis that no individual critic would see because each had limited scope. The orchestrator sees all outputs — it's the one entity with full context — but is forbidden from using that context analytically. The constraint makes the system more predictable but potentially less insightful.

4. **Diff-based scoping is sufficient.** The system reviews what changed. But many code review concerns are about what *didn't* change — missing error handling that should have been added, test coverage that should have been updated, migration scripts that should accompany a schema change. The auto-selection heuristics for contextual critics partially address this (test-strategy triggers when tests are *missing*), but the core critics only see the diff, not the delta between what changed and what should have changed.

---

## What the Market Says

If a multi-critic AI code review pipeline with automatic severity mapping and cross-critic escalation were clearly superior to existing approaches, you would expect to see market signals:

- **Code review tools would be converging on this architecture.** They aren't, as far as I can tell. Most AI code review tools (GitHub Copilot review, CodeRabbit, etc.) use a single-pass approach with different focus areas configurable but not independently dispatched. The multi-agent parallel-critic approach is architecturally unusual.

- **The absence of this pattern in commercial tools is informative.** It could mean the market hasn't discovered this approach yet (possible but unlikely given the amount of investment in AI code review). More likely, it means the overhead of coordinating multiple agents, managing their context budgets, and synthesizing their outputs isn't worth the marginal improvement over a single well-prompted pass — at least not at current model capabilities.

- **Context budget is the binding constraint.** The draft explicitly manages context budget (pass scope not diffs, trim fact-check reports over 200 lines). This suggests the system is operating near the limits of what current models can handle. If the main cost of the multi-critic approach is context pressure, and context windows are expanding rapidly, the architecture may be solving a problem that's about to become much less severe — at which point a single-pass approach with a longer prompt might be simpler and equally effective.

That said, this is a personal workflow toolkit, not a commercial product. The "market" here is one developer's productivity. The relevant question is whether the developer finds the multi-pass output more useful than a single-pass review, and that's an empirical question the architecture at least enables testing.

---

## Overall Assessment

The code-review orchestrator is a well-specified, factually solid piece of workflow engineering. It successfully adapts the prose review pipeline to code, and the additions (auto-selection, severity mapping, escalation) are thoughtful.

The main concerns, roughly ordered by importance:

1. **The boring explanation may account for most of the value.** Multiple passes over the same diff with different instructions is likely the core mechanism. The elaborate severity mapping and escalation rules add specification complexity that may not proportionally improve outcomes. I'd want to see evidence — even anecdotal — that the escalation rule actually fires in practice and changes decisions.

2. **The pipeline shape inherits assumptions from prose review that may not transfer cleanly.** Fact-check-before-critics sequencing adds latency for unclear benefit in the code domain. The parallel-critics-with-no-cross-talk design prevents inter-critic learning. These are defensible choices but they're treated as inherited truths rather than design decisions.

3. **The auto-selection claims dynamic discovery but implements static classification.** This is a maintainability concern more than a correctness concern, but it means the system's actual behavior diverges from the mental model its instructions create.

4. **The "advisory" status of contextual critics may be weaker than presented** if they participate in cross-critic escalation. The draft should clarify this edge case.

**Confidence:** Medium-high on the structural observations, medium on the market analysis (personal toolkits have different economics than commercial products), low on predicting whether the escalation rule adds value (that's an empirical question I can't answer from the specification alone).
