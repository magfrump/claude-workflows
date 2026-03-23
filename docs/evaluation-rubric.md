# Evaluation Rubric for Skills and Workflows

This rubric is used to evaluate new skills and workflows before adding them to the repo, and to periodically reassess existing ones. It was developed by walking through evaluations of `code-fact-check` and `yglesias-critique` and reflecting on which dimensions produced useful signal.

## How to use this rubric

**For new additions:** Score each dimension before merging. A skill doesn't need to score well on every dimension — but low scores should be conscious tradeoffs, not surprises.

**For existing tools:** Periodically re-evaluate, especially when the conditions that justified a tool have changed (e.g., a pipeline it depended on was built or abandoned, usage patterns shifted).

**Scoring:** Each dimension uses a three-level scale (strong / adequate / weak) with brief justification. The justification matters more than the label — it captures *why* and makes the evaluation useful in future sessions.

**Self-evaluation path:** This rubric is designed for manual evaluation first. Once trust is established in both the rubric and in Claude's ability to apply it, a self-evaluation skill can be built on top of it. The structured dimensions and three-level scale are chosen to make that transition feasible.

---

## Dimensions

### 1. Counterfactual gap

*How much worse is the outcome without this tool?*

This is the most important dimension but also the hardest to assess. Decompose it:

- **vs. no tool at all:** What does someone do without this? If the answer is "roughly the same thing but less structured," the gap is small. If the answer is "they miss an entire category of analysis," the gap is large.
- **vs. a generic prompt:** Could you get 70%+ of the value by asking Claude "do X" without a dedicated skill file? The skill's value is in the specificity and consistency it adds beyond what ad-hoc prompting achieves.
- **vs. built-in tools:** Does a built-in capability (e.g., code-simplifier, verification-coordinator) already cover this ground? If so, the skill needs to clearly exceed what the built-in provides.
- **vs. other skills in this repo:** Does another skill substantially overlap? Partial overlap is fine if the lenses are genuinely different (Cowen vs. Yglesias). Full overlap means one should be pruned.

Note the *conditions* under which the gap exists. A skill may have a large counterfactual gap *if* you write policy drafts regularly, or *if* the code-review orchestrator is built. State the condition explicitly.

### 2. User-specific fit

*How relevant is this to my actual work patterns?*

This is explicitly subjective. A well-designed skill that doesn't match your work is inventory, not a tool. Consider:

- How often does the triggering situation arise in practice?
- Is the frequency increasing or decreasing?
- Does this serve a goal you're actively pursuing (e.g., writing more, improving code review process)?

This dimension is the main reason the rubric supports periodic re-evaluation — fit changes as work changes.

### 3. Condition for value

*What has to be true for this tool to earn its place? Is that condition currently met?*

Many tools are valuable only in context:
- A pipeline stage requires the pipeline to exist.
- A domain-specific critic requires working in that domain.
- A standalone tool requires a natural trigger that someone would actually invoke.

State the condition. Then state whether it's met today. If the condition is "not yet met but planned," note what would need to happen and whether there's a realistic path. A tool waiting for a condition that may never be met is speculative inventory.

### 4. Failure mode gracefulness

*When this tool produces bad output, how easy is it to tell?*

Split into two sub-dimensions:

- **Detectable failures:** The output is wrong in a way that's visible on inspection. Wrong verdicts on checkable claims, obviously thin analysis sections, structural format violations. These are safe — the user notices and discards.
- **Silent failures:** The output looks authoritative but is wrong in ways that require domain expertise to catch. Confident-sounding policy analysis built on fabricated reasoning. Plausible-seeming code review that misreads the implementation. These are dangerous.

A tool with mostly detectable failures is safer than one with mostly silent failures, even if the failure rate is similar. For tools with silent failure risk, ask: does the pipeline architecture mitigate this? (e.g., fact-check catching fabricated numbers before they reach a critic)

### 5. Testability investment

*How much work would it take to build a meaningful test for this tool?*

Not a binary "testable or not" — a spectrum of investment required:

- **Low investment:** You can construct a test input with known correct output and mechanically check results. (e.g., code-fact-check: repo with deliberately wrong comments)
- **Medium investment:** You can construct test inputs and check structural properties of the output, but quality assessment requires human judgment. (e.g., critic skills: did it find the planted flaw? Was the analysis coherent?)
- **High investment:** Meaningful testing requires domain expertise and subjective evaluation with no shortcut. (e.g., "was this cross-domain analogy actually illuminating?")

The goal is not to reject high-investment tools, but to be honest about the current level of evidence for whether they work. Testability can be improved with investment — the question is whether that investment is planned.

### 6. Test coverage

*What actual evidence exists that this tool works?*

Separate from testability (which is about potential), this is about current state:

- Have test cases been written and run?
- Has the tool been used on real work? What happened?
- Are there example outputs that demonstrate quality?

A tool with zero test coverage is in a probationary state regardless of how testable it is in theory.

### 7. Pipeline readiness

*Does this tool have a place in an existing pipeline, and does that pipeline exist?*

Levels:
- **Standalone viable:** Useful when invoked directly, no pipeline needed.
- **Pipeline exists:** The orchestrator or workflow that uses this tool is built and functional.
- **Pipeline planned:** The tool is designed for a pipeline that doesn't exist yet. State what's needed.
- **Orphaned:** The tool was designed for a context that no longer applies.

A pipeline-stage tool with no pipeline is less valuable than a standalone tool, but it may pull toward building the pipeline — which could unlock value across multiple tools. Note this if applicable.

### 8. Overlap and redundancy

*Does this tool duplicate work that another tool (in this repo or built-in) already does?*

Overlap is acceptable when:
- The tools apply genuinely different analytical lenses to the same input (Cowen vs. Yglesias)
- One is a pipeline stage and the other is standalone
- The overlap is in structure/format, not in substance

Overlap is a problem when:
- Two tools would produce substantially similar output on the same input
- A built-in tool covers the same ground with less friction
- The triggering conditions are ambiguous enough that users wouldn't know which to choose

### 9. Trigger clarity

*Can the agent (or user) reliably tell when to use this?*

Consider:
- Is the triggering situation specific enough to avoid false positives (invoked when unhelpful)?
- Is it salient enough to avoid false negatives (never invoked when it would help)?
- When multiple tools could apply, is the selection logic clear?

This interacts with user-specific fit — a clear trigger for a situation that never arises is irrelevant.

---

## Applying the rubric: skills vs. workflows

Skills and workflows have different shapes, and some dimensions apply differently:

| Dimension | Skills | Workflows |
|---|---|---|
| Counterfactual gap | vs. generic prompting | vs. ad-hoc process (just start coding) |
| Failure gracefulness | Bad output in the report | Bad process leading to wasted sessions |
| Testability | Can construct input/output test cases | Harder — test the artifacts, not the process |
| Pipeline readiness | Often pipeline stages | Usually top-level, not composed |
| Trigger clarity | "When should I invoke this?" | "When should I follow this process?" |

The key structural difference: **workflows** define multi-step processes with human checkpoints and produce trails of working documents. **Skills** are single-pass transforms that take an input and produce one structured output. Orchestrator skills (like `draft-review`) are skills that compose other skills into pipelines.

---

## Example evaluations

### code-fact-check

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Adequate | Low standalone; high as pipeline stage — but pipeline doesn't exist yet |
| User-specific fit | Strong | Code review is frequent; comment accuracy matters |
| Condition for value | Not yet met | Needs code-review orchestrator to realize pipeline value |
| Failure gracefulness | Strong | Wrong verdicts are visible and easy to dismiss |
| Testability investment | Low | Can construct repos with deliberately wrong comments |
| Test coverage | Weak | No tests written or example outputs produced |
| Pipeline readiness | Pipeline planned | Three code reviewers list it as `requires`, but no orchestrator yet |
| Overlap | Strong | Low overlap — no other tool does comment-vs-code verification |
| Trigger clarity | Adequate | Clear ask, but rarely a first-class user request |

**Key question:** Does its existence justify building the code-review orchestrator? If yes, it's an investment. If the orchestrator isn't coming, it's inventory.

### yglesias-critique

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | 9 specific cognitive moves that generic prompting wouldn't reliably produce |
| User-specific fit | Strong | User writes policy-adjacent content and expects to increase |
| Condition for value | Met | draft-review pipeline exists; user writes applicable content |
| Failure gracefulness | Adequate | Structured sections make thin analysis visible; risk of confident-sounding speculation partially mitigated by fact-check pipeline |
| Testability investment | Medium | Can test flaw detection with planted policy errors; quality of analysis harder |
| Test coverage | Weak | No tests written or example outputs produced |
| Pipeline readiness | Pipeline exists | draft-review orchestrates it with fact-check upstream |
| Overlap | Adequate | Moderate structural overlap with cowen-critique; substantive moves are distinct |
| Trigger clarity | Adequate | Clear for policy drafts; less clear boundary vs. cowen-critique for general essays |

**Key question:** Is the Cowen/Yglesias distinction clear enough that you'd know which to invoke standalone, or does it only make sense to run both via draft-review?

---

## Open questions for future refinement

- **Weighting:** Are all dimensions equally important, or should some dominate? Current instinct: counterfactual gap and condition-for-value are highest-leverage, but this should be tested across more evaluations.
- **Thresholds:** What score pattern would block a new addition? A single "weak" on counterfactual gap? Multiple "weak" scores? This needs more examples to calibrate.
- **Self-evaluation design:** When building the self-evaluation skill, which dimensions can Claude assess reliably vs. which require human judgment? Testability investment and trigger clarity seem automatable. User-specific fit and counterfactual gap probably don't.
- **Workflow-specific dimensions:** The current rubric was developed from skill evaluations. Evaluating a workflow may reveal dimensions that don't appear here (e.g., checkpoint quality, artifact usefulness, session-boundary design).
