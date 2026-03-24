---
Last verified: 2026-03-23
Relevant paths:
  - skills/fact-check.md
  - skills/cowen-critique.md
  - skills/yglesias-critique.md
  - skills/draft-review.md
  - skills/code-fact-check.md
  - skills/security-reviewer.md
  - skills/performance-reviewer.md
  - skills/api-consistency-reviewer.md
  - skills/matrix-analysis.md
  - skills/test-strategy.md
  - skills/tech-debt-triage.md
  - skills/dependency-upgrade.md
  - workflows/research-plan-implement.md
  - workflows/divergent-design.md
  - workflows/task-decomposition.md
  - workflows/spike.md
  - workflows/pr-prep.md
  - workflows/user-testing-workflow.md
  - workflows/codebase-onboarding.md
  - workflows/branch-strategy.md
  - docs/evaluation-rubric.md
---

# Full Evaluation of Skills and Workflows

**Date:** 2026-03-23
**Rubric:** [docs/evaluation-rubric.md](../evaluation-rubric.md)
**Evaluator:** Claude (per rubric's self-evaluation path — treat findings as draft requiring human review)

---

## Skills

---

### 1. fact-check

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | Generic prompting produces uncalibrated spot-checks; this skill enforces systematic claim extraction, structured verdicts, confidence calibration, and source citation. The difference between "check this" and "fact-check this with the fact-check skill" is large. |
| User-specific fit | Strong | User writes policy-adjacent content and expects to increase. Every draft benefits from fact-checking. |
| Condition for value | Met | Standalone viable; also a pipeline stage for draft-review which exists. |
| Failure gracefulness | Strong | Wrong verdicts are visible on inspection (the claim and evidence are side-by-side). Silent failures possible for "Accurate" verdicts that are actually wrong, but the structured format makes spot-checking easy. |
| Testability investment | Low | Can construct drafts with deliberately wrong numbers and verify the skill catches them. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Pipeline exists | draft-review orchestrates it. Also standalone viable. |
| Overlap | Strong | No other skill does systematic claim verification for prose drafts. |
| Trigger clarity | Strong | "Fact-check this" is unambiguous. Also triggered reliably by draft-review. |

**Key question:** Test coverage is the main gap. The skill is well-positioned and well-designed; it just needs evidence that it works.

---

### 2. cowen-critique

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | 9 specific cognitive moves that generic prompting wouldn't reliably produce in combination. The moves are genuinely distinctive — "find the cross-domain analogy," "follow revealed preferences" — not generic critique advice. |
| User-specific fit | Strong | User writes policy-adjacent content. Cowen's economic/cultural lens is relevant. |
| Condition for value | Met | draft-review pipeline exists; also standalone viable for any essay or article. |
| Failure gracefulness | Adequate | Structured sections make thin analysis visible. Risk: confident-sounding cross-domain analogies that are structurally wrong. Mitigated by fact-check running upstream. |
| Testability investment | Medium | Can test flaw detection with planted weaknesses. Quality of analogies and inversion exercises harder to assess mechanically. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Pipeline exists | draft-review orchestrates it with fact-check upstream. |
| Overlap | Adequate | Moderate structural overlap with yglesias-critique (both are critic skills with similar output format). Substantive moves are genuinely different — Cowen's are about intellectual stress-testing, Yglesias's about policy feasibility. |
| Trigger clarity | Adequate | Clear for "challenge my thinking" / "poke holes." Less clear vs. yglesias-critique for policy drafts specifically — user may not know which to choose standalone. Draft-review resolves this by running both. |

**Key question:** Same as rubric example — is the Cowen/Yglesias distinction clear enough standalone, or does it only make sense to run both via draft-review?

---

### 3. yglesias-critique

*(Rubric already contains this evaluation. Reproducing with updates.)*

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | 9 specific policy-focused cognitive moves. "Trace the money," "10 million people test," "swap in the implementation org chart" are distinctive and unlikely from generic prompting. |
| User-specific fit | Strong | User writes policy-adjacent content and expects to increase. |
| Condition for value | Met | draft-review pipeline exists; user writes applicable content. |
| Failure gracefulness | Adequate | Structured sections make thin analysis visible. Risk of confident-sounding speculation about political dynamics, partially mitigated by fact-check pipeline. |
| Testability investment | Medium | Can plant policy proposals with obvious scaling problems or cost-disease traps. Quality of "boring lever" and "popular version" suggestions harder. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Pipeline exists | draft-review orchestrates it with fact-check upstream. |
| Overlap | Adequate | See cowen-critique notes. |
| Trigger clarity | Adequate | Clear for policy drafts. Less clear boundary vs. cowen-critique for general essays. |

**Key question:** Unchanged from rubric.

---

### 4. draft-review

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | Without this, the user must manually invoke fact-check, then each critic, then manually synthesize. The orchestrator provides: sequential staging (fact-check before critics), parallel dispatch, convergence analysis, structured rubric with status tracking. A generic prompt can't replicate the pipeline architecture. |
| User-specific fit | Strong | User writes drafts and wants substantive review. This is the one-command entry point. |
| Condition for value | Met | Requires fact-check and at least one critic skill — all exist. |
| Failure gracefulness | Adequate | The orchestrator can fail by: poor synthesis (detectable — agent outputs are preserved), missing an agent failure (mitigated by explicit checkpoint rules), or biased rubric tier assignment. The structured rubric format makes bias visible. |
| Testability investment | Medium | Can test with a draft containing known errors and planted weaknesses. Can verify the pipeline executes correctly (right agents dispatched, right order). Quality of synthesis is harder. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Standalone viable | It *is* the pipeline. |
| Overlap | Strong | No other skill orchestrates multi-stage draft review. |
| Trigger clarity | Strong | "Review this draft" is unambiguous. |

**Key question:** Has anyone actually run the full pipeline end-to-end? The orchestrator is well-specified but complex — the mandatory execution rules, fact-check gate, ensemble mode, and rubric generation create many code paths that could fail in practice.

---

### 5. code-fact-check

*(Rubric already contains this evaluation. Reproducing with updates.)*

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Adequate | Low standalone — most developers read their own code and notice stale comments. High as pipeline stage for code-review orchestrator, which doesn't exist yet. Standalone value exists for large unfamiliar codebases or post-acquisition audits. |
| User-specific fit | Adequate | Code review is frequent; comment accuracy matters. But user may not frequently encounter codebases with extensive stale documentation. |
| Condition for value | Partially met | Standalone viable but highest value is as pipeline stage. Three code-review critics (security, performance, API consistency) list it as `requires`, but no code-review orchestrator exists to compose them. |
| Failure gracefulness | Strong | Wrong verdicts are visible — the claim, the code location, and the evidence are all cited. Easy to verify. |
| Testability investment | Low | Can construct repos with deliberately wrong comments and verify detection. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Pipeline planned | Security, performance, and API-consistency reviewers all depend on it, but no orchestrator composes them. |
| Overlap | Strong | No other tool does comment-vs-code verification. |
| Trigger clarity | Adequate | Clear when asked directly. Rarely a first-class user request — more commonly triggered by a pipeline. |

**Key question:** Does its existence (plus the three code-review critics) justify building a code-review orchestrator? The pipeline is half-built — the stage skills exist but the orchestrator doesn't.

---

### 6. security-reviewer

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | 9 cognitive moves specifically targeting design-level security issues that linters miss: trust boundary tracing, TOCTOU detection, access control inversion, serialization boundary analysis. Generic "review for security" prompting misses at least half of these. |
| User-specific fit | Adequate | Depends on frequency of security-sensitive code changes. Universal need but intermittent trigger. |
| Condition for value | Partially met | Standalone viable for security reviews. Designed as code-review pipeline stage, but that pipeline doesn't exist. |
| Failure gracefulness | Adequate | Findings include severity, confidence, and specific attack scenarios — thin findings are visible. Risk: silent false negatives (missing a real vulnerability) are dangerous but inherent to any security review. |
| Testability investment | Medium | Can construct code with planted vulnerabilities (SQL injection, TOCTOU, missing auth checks) and verify detection. Harder to test for false negatives or quality of attack scenario descriptions. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Pipeline planned | Designed for code-review orchestrator that doesn't exist. Standalone viable. |
| Overlap | Strong | Built-in verification-coordinator does not do security analysis. No overlap with other skills. |
| Trigger clarity | Strong | "Review for security" is clear. Also has good implicit triggers: code touching auth, crypto, input handling. |

**Key question:** High standalone value even without the pipeline. The missing orchestrator is less of a blocker here than for code-fact-check because security review is commonly requested directly.

---

### 7. performance-reviewer

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | 9 cognitive moves for performance: hidden multiplications, "what's the size of N?", work that moved to the wrong place, database interaction patterns, contention points. These are specific enough that generic prompting wouldn't produce them systematically. |
| User-specific fit | Adequate | Similar to security reviewer — universal need, intermittent trigger. Board game digitization work may have performance-sensitive rendering/game-state code. |
| Condition for value | Partially met | Standalone viable. Designed for code-review pipeline that doesn't exist. |
| Failure gracefulness | Adequate | Findings cite specific scaling factors and data sizes. Risk: false positives on cold paths flagged as hot-path issues. The skill explicitly guards against this ("always determine call frequency"). |
| Testability investment | Medium | Can construct code with N+1 queries, O(n²) in loops, unbounded allocations. Quality of "is this actually a hot path?" judgment harder. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Pipeline planned | Same as security-reviewer. |
| Overlap | Strong | Built-in tools don't do structured performance review. |
| Trigger clarity | Strong | "Will this scale?" / "check for bottlenecks" are clear triggers. |

**Key question:** Same as security-reviewer — high standalone value, missing orchestrator is not a blocker.

---

### 8. api-consistency-reviewer

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Adequate | The cognitive moves (establish baseline conventions, check naming against the grain, trace consumer contract, verify error consistency) are valuable but closer to what a thorough generic review would produce. The specific "read 3-5 sibling endpoints first" instruction is the main differentiator. |
| User-specific fit | Adequate | Relevant when building APIs. Less frequent trigger than security or performance for a solo developer. |
| Condition for value | Partially met | Requires a codebase with an established API surface large enough to have conventions. Standalone viable but strongest in pipeline. |
| Failure gracefulness | Adequate | Findings reference specific baseline conventions, making it easy to verify whether the baseline was identified correctly. Risk: choosing the wrong baseline (reading non-representative sibling endpoints). |
| Testability investment | Medium | Can construct a codebase with established conventions and a new endpoint that deviates. Quality of baseline selection harder to test. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Pipeline planned | Same as other code-review skills. |
| Overlap | Adequate | Some overlap with what a good generic code review would catch. The structured approach adds consistency but the gap vs. ad-hoc is smaller than for security/performance. |
| Trigger clarity | Adequate | "Does this match our conventions?" is clear. Less obvious when to invoke standalone vs. as part of a broader review. |

**Key question:** This is the weakest of the three code-review critics in terms of counterfactual gap. Its value primarily comes from consistency when composed with the others in a pipeline. If the pipeline never materializes, this is the first candidate for pruning.

---

### 9. matrix-analysis

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | Per-criterion subagent dispatch with parallel evaluation and synthesis is something generic prompting cannot replicate. The specific design choice (one agent per criterion, not per item) produces better-calibrated comparisons. |
| User-specific fit | Strong | Decision-making and comparison tasks are universal. Used in this repo's own evaluation process (divergent design, rubric application). |
| Condition for value | Met | Standalone viable. No pipeline dependency. |
| Failure gracefulness | Adequate | The matrix format makes weak evaluations visible (sparse rationales, all-identical scores). Risk: subagents producing plausible-sounding but poorly calibrated scores. Mitigated by requiring rationale for every score. |
| Testability investment | Medium | Can construct comparisons with known rankings (e.g., compare sorting algorithms on known criteria). Quality of tradeoff analysis harder. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Standalone viable | Used by divergent-design (which references it conceptually) and tech-debt-triage (which suggests it for large surveys). |
| Overlap | Strong | No built-in tool does structured multi-criterion comparison with subagent dispatch. |
| Trigger clarity | Strong | "Compare these options" / "decision matrix" are clear and common requests. |

**Key question:** This is one of the strongest skills in the repo — clear trigger, high counterfactual gap, standalone viable, broad applicability. Main gap is test coverage.

---

### 10. test-strategy

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Adequate | A good developer asking "what tests should I write" would get reasonable advice from generic prompting. The skill adds: risk profiling, existing coverage survey, explicit "what NOT to test" section, and specific test case descriptions. The gap is in consistency and completeness, not in capability. |
| User-specific fit | Adequate | Relevant for any development work. Frequency depends on how often the user writes new code vs. reviews/evaluates. |
| Condition for value | Met | Standalone viable. Can plug into RPI as the testing strategy section. |
| Failure gracefulness | Adequate | Recommendations cite specific files and test cases, making them verifiable. Risk: recommending tests for low-risk code while missing high-risk gaps. The risk profiling step mitigates this. |
| Testability investment | Medium | Can construct a codebase and verify the skill identifies the right test types and priorities. Whether the specific test cases are good requires human judgment. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Standalone viable | Fits into RPI's testing strategy section. No formal pipeline dependency. |
| Overlap | Adequate | Built-in verification-coordinator does some of this (test planning). The test-strategy skill goes deeper on risk profiling and prioritization. Overlap is real but the skill adds meaningful depth. |
| Trigger clarity | Strong | "What tests should I write?" is clear and common. |

**Key question:** Overlap with built-in verification-coordinator needs monitoring. If the built-in improves, this skill's counterfactual gap shrinks.

---

### 11. tech-debt-triage

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Adequate | The four-part framework (carrying cost, fix cost, urgency triggers, fix-or-carry decision) is structured and useful. Generic prompting would produce a less systematic version. The gap is moderate — a thoughtful developer would consider most of these factors anyway. |
| User-specific fit | Adequate | Relevant when maintaining codebases. The user's workflows repo is still young, so tech debt triage is more relevant for other projects. |
| Condition for value | Met | Standalone viable. References matrix-analysis for large-scale surveys. |
| Failure gracefulness | Adequate | The four-category recommendation (fix now / fix opportunistically / carry intentionally / defer and monitor) is structured enough that weak analysis shows through. Risk: underestimating compounding costs or fix scope. |
| Testability investment | Medium | Can construct codebases with known tech debt and verify the triage produces reasonable categorization. Whether the carrying cost estimate is correct requires human judgment. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Standalone viable | References matrix-analysis as a composition option. |
| Overlap | Strong | No built-in tool does structured tech debt triage. |
| Trigger clarity | Adequate | "Should we fix this?" is clear but may not always be recognized as a tech-debt-triage invocation. The skill is more of a framework that gets invoked when needed than something with a bright-line trigger. |

**Key question:** This is a solid but unexciting skill. Its value is in consistency of evaluation, not in capability that's otherwise unavailable.

---

### 12. dependency-upgrade

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Adequate | The structured approach (search codebase for actual usage, read migration guide, check for codemods, assess urgency) is better than ad-hoc "just upgrade and see what breaks." Generic prompting would cover some of this but miss the systematic "breaking changes that DON'T affect this project" section and the urgency framework. |
| User-specific fit | Adequate | Relevant for any project with dependencies. Frequency depends on project maturity and dependency count. |
| Condition for value | Met | Standalone viable. Triggered by Dependabot/Renovate PRs or security advisories. |
| Failure gracefulness | Adequate | The output includes "breaking changes that affect this project" vs. "that don't" — wrong categorization is visible when the user checks the affected files. Risk: missing a breaking change entirely (silent failure). |
| Testability investment | Medium | Can construct projects with known dependency usage and verify the skill correctly identifies which breaking changes matter. Requires access to real changelogs/migration guides. |
| Test coverage | Weak | No tests written or example outputs produced. |
| Pipeline readiness | Standalone viable | Could be composed with a security-advisory scanner but no such pipeline exists or is planned. |
| Overlap | Strong | No built-in tool does structured dependency upgrade evaluation. |
| Trigger clarity | Strong | "Should we upgrade X?" and Dependabot PR reviews are clear triggers. |

**Key question:** Practical and well-scoped. Main gap is test coverage. Value increases with project complexity and dependency count.

---

## Workflows

Note: The rubric acknowledges workflows have different evaluation characteristics. Key differences: failure means wasted sessions (not bad output), testability is about artifacts not I/O, and trigger clarity is "when should I follow this process?"

---

### 1. research-plan-implement (RPI)

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | vs. ad-hoc: Without RPI, the default is "start coding and figure it out." RPI enforces: understand before proposing, plan before implementing, gate implementation on human review. The hard gate at step 4 is the key differentiator — it prevents the most expensive failure mode (implementing the wrong thing). |
| User-specific fit | Strong | Default workflow for all non-trivial development. Referenced in CLAUDE.md. |
| Condition for value | Met | No dependencies. Works for any development task. |
| Failure gracefulness | Strong | Failures are visible: wrong research → wrong plan → caught at review gate. The artifact trail (research doc, plan doc) makes it easy to identify where understanding went wrong. The worst case (plan approved with wrong assumptions) is mitigated by the refactoring variant's emphasis on characterization tests. |
| Testability investment | Medium | Can test artifact quality on known codebases. Process adherence (did it actually stop at the gate?) harder to test automatically. |
| Test coverage | Weak | No formal tests. Has been used in practice (working docs exist in the repo). |
| Pipeline readiness | Standalone viable | Top-level workflow. Other workflows feed into it (spike → RPI, onboarding → RPI, DD invoked from within RPI). |
| Overlap | Strong | No built-in workflow does research → plan → gate → implement with artifact trail. |
| Trigger clarity | Strong | "Any non-trivial feature or bug fix." Clear default. |

**Key question:** This is the backbone workflow. Its main risk is over-application (using RPI for trivial changes). The "when to skip" section addresses this explicitly.

---

### 2. divergent-design (DD)

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | vs. ad-hoc: Without DD, the default is "pick the first approach that seems reasonable." DD enforces: generate 8-15 candidates (including "wrong" ones), diagnose constraints, match-and-prune, tradeoff matrix with stress-test pass. The diverge phase is the key differentiator — most developers skip it. |
| User-specific fit | Strong | User builds workflows and skills — decisions about structure and approach are frequent. Used for this repo's own design decisions (evidenced by docs/decisions/). |
| Condition for value | Met | No dependencies. Works for any design decision. Invokable from within RPI. |
| Failure gracefulness | Adequate | A bad DD session produces a premature decision — which is the status quo without DD. The stress-test pass (added recently per commit history) mitigates this. The 80% confidence threshold for autonomous decision is a good safeguard. Risk: the diverge phase producing 15 superficially different but substantively identical candidates. |
| Testability investment | High | Evaluating whether a DD session produced a genuinely better decision than ad-hoc requires counterfactual comparison. Can test structural properties (did it generate enough candidates? did it apply stress-test moves?). |
| Test coverage | Weak | No formal tests. Has been used in practice (decision docs exist in the repo). |
| Pipeline readiness | Standalone viable | Also invocable from within RPI. |
| Overlap | Strong | No built-in tool does structured divergent design. Matrix-analysis overlaps on the evaluation phase but not the diverge phase. |
| Trigger clarity | Strong | "When the first idea is probably not the best idea." Clear and well-calibrated. |

**Key question:** The stress-test pass was recently added. Is the DD process becoming too heavy for smaller decisions? The workflow should maintain its value for genuine architectural choices without becoming overhead for minor design decisions.

---

### 3. task-decomposition

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Adequate | vs. ad-hoc: Without this, a developer might research serially or skip some subsystems. The value is in: (1) explicitly identifying independent sub-investigations, (2) parallelizing research via sub-agents, (3) synthesizing into RPI format. The gap is moderate — a careful developer would do most of this mentally. |
| User-specific fit | Adequate | Relevant for large tasks touching multiple subsystems. Frequency depends on project size. |
| Condition for value | Met | Requires sub-agent capability (available in Claude Code). Feeds into RPI. |
| Failure gracefulness | Adequate | Bad decomposition wastes sub-agent work on non-independent areas or misses a key subsystem. The synthesis step is the quality gate — visible if sub-agent findings don't cohere. |
| Testability investment | High | Testing whether a decomposition is correct requires understanding the codebase. Can test structural properties (did it identify shared dependencies? did it synthesize into RPI format?). |
| Test coverage | Weak | No formal tests or documented usage examples. |
| Pipeline readiness | Standalone viable | Feeds into RPI. |
| Overlap | Adequate | RPI's research phase covers some of this. Task decomposition adds explicit parallelism and structure for multi-subsystem tasks. The overlap is in purpose, not in mechanism. |
| Trigger clarity | Adequate | "Task touches multiple subsystems" is clear but the threshold for "multiple" is subjective. The "when to skip" section helps. |

**Key question:** Is this workflow pulling its weight as a separate document, or should it be folded into RPI as a variant (like the refactoring variant)?

---

### 4. spike

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | vs. ad-hoc: Without this, developers either over-invest in a full RPI for a feasibility question, or hack around exploratorily without recording findings. The spike workflow provides: timebox, throwaway branch, structured findings record, and RPI seed for handoff. The RPI seed section is the key differentiator — it bridges spike findings into the implementation workflow. |
| User-specific fit | Strong | Exploring unfamiliar tools and approaches is frequent. Board game digitization work likely involves many "can this work?" questions. |
| Condition for value | Met | No dependencies. Lightweight by design. |
| Failure gracefulness | Strong | A failed spike is a successful answer ("this is harder than expected"). The timebox prevents over-investment. The recording step captures value even from negative results. |
| Testability investment | Medium | Can test structural compliance (did it timebox? did it produce a findings record? did it include an RPI seed?). Quality of findings requires human judgment. |
| Test coverage | Weak | No formal tests. Likely used in practice but no documented examples in this repo. |
| Pipeline readiness | Standalone viable | Feeds into RPI via the RPI seed section. |
| Overlap | Strong | No built-in tool does timeboxed exploration with structured handoff. |
| Trigger clarity | Strong | "Can this work?" vs. "build this" is a clear distinction. |

**Key question:** The spike workflow's main risk is being skipped (developer jumps straight to RPI when a spike would have been more appropriate). The CLAUDE.md listing helps but the trigger could be more prominent.

---

### 5. pr-prep

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Adequate | vs. ad-hoc: Most developers already clean up before PR. The value is in: structured self-review checklist, PR description template, size check, and the suggestion to invoke code-review critics. The gap is in consistency — the process ensures nothing is skipped. |
| User-specific fit | Strong | User opens PRs with a reviewer in a different timezone. PR quality directly affects review turnaround. |
| Condition for value | Met | No dependencies. Applicable to any project using PRs. |
| Failure gracefulness | Strong | A bad PR-prep is visible to the reviewer (messy commits, missing description sections, dead code). Low risk of silent failure. |
| Testability investment | Low | Can test structural compliance (does the PR description have all required sections? were CI checks run?). |
| Test coverage | Weak | No formal tests. Likely used in practice. |
| Pipeline readiness | Standalone viable | Optionally invokes code-review critics as sub-step. |
| Overlap | Adequate | Some overlap with what a good developer does naturally. The structured template and self-review checklist add value beyond habit. |
| Trigger clarity | Strong | "Before opening any pull request." Clear and universal. |

**Key question:** The reference to code-review critics in the self-review step is the most valuable part beyond standard PR hygiene. If the code-review orchestrator is built, this workflow becomes even more useful as the human-facing wrapper around it.

---

### 6. user-testing-workflow

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | vs. ad-hoc: Without this, user testing is either not done or done poorly (leading questions, wrong task construction, no severity framework). This workflow encodes substantial HCI methodology: Nielsen-Landauer model, SUS questionnaire, Travis severity rating, moderator script with anti-patterns. A generic prompt wouldn't produce this level of methodological rigor. |
| User-specific fit | Strong | User actively runs user tests — confirmed recent usage. Board game digitization and tool-building both benefit from usability testing. |
| Condition for value | Met | User actively runs user tests. Has products to test (board game digitization, tools). |
| Failure gracefulness | Strong | The modular structure (phases with checklists) makes it easy to identify which phase went wrong. The stress-test step (3.5) catches inflated severities. Failures produce wasted test sessions, which is costly but recoverable. |
| Testability investment | High | Testing the workflow means running actual user tests and evaluating whether the methodology produced better findings. No shortcut. |
| Test coverage | Weak | No usage examples or findings reports. |
| Pipeline readiness | Standalone viable | Top-level workflow. |
| Overlap | Strong | No built-in tool covers usability testing methodology. |
| Trigger clarity | Adequate | "When you need to design a user test" is clear. Risk of false negative — the user may not think to test when they should. |

**Key question:** User has confirmed recent usage — this earns its place. Future refinement should focus on what worked and didn't work in actual test sessions.

---

### 7. codebase-onboarding

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Strong | vs. ad-hoc: Without this, onboarding to a new codebase is unstructured exploration — reading files semi-randomly, missing key flows, not documenting unknowns. This workflow provides: entry point identification, subsystem mapping, flow tracing, convention cataloging, and explicit unknown-tracking. The "Known Unknowns" section is the key differentiator — most ad-hoc onboarding doesn't track what it missed. |
| User-specific fit | Strong | User works across multiple projects and starts new ones. Board game digitization is a relatively new project. |
| Condition for value | Met | No dependencies. Works for any codebase. Feeds into RPI and task decomposition. |
| Failure gracefulness | Adequate | A bad onboarding doc has wrong subsystem descriptions or missed unknowns. The validation gate (step 7) catches some of this. Risk: false confidence from a well-structured but incorrect mental model. |
| Testability investment | High | Evaluating whether an onboarding doc accurately describes a codebase requires comparing it to ground truth. Can test structural compliance (does it have all required sections?). |
| Test coverage | Weak | No formal tests. Working docs in this repo suggest some usage. |
| Pipeline readiness | Standalone viable | Feeds into RPI and task decomposition. |
| Overlap | Strong | No built-in tool does structured codebase onboarding. |
| Trigger clarity | Strong | "Starting a new project or returning after a long absence" is clear. |

**Key question:** The workflow specifies producing a living document that gets updated. In practice, does the document actually get maintained, or does it go stale after the initial onboarding? If it goes stale, the workflow's ongoing value is limited to first-time orientation.

---

### 8. branch-strategy

| Dimension | Score | Notes |
|---|---|---|
| Counterfactual gap | Adequate | vs. ad-hoc: Without this, a developer uses whatever branching strategy they learned from past teams, which may not fit the specific constraints (high feature velocity, timezone-offset reviewer, integration testing needs). The key insight (dev is disposable, features branch off main, merge not rebase after squash-merge) addresses a real pain point. But this is a reference doc, not a process — it doesn't enforce anything. |
| User-specific fit | Strong | Explicitly designed for the user's work pattern: high feature output, async reviewer in different timezone. |
| Condition for value | Partially met | Requires an active project with the described team structure (one developer, one reviewer, timezone gap). If working solo without a reviewer, most of this is unnecessary overhead. |
| Failure gracefulness | Adequate | Following the strategy incorrectly leads to merge conflicts or messy history — both visible and recoverable (the "reset dev" section is the escape hatch). |
| Testability investment | Low | Can verify the git commands produce the described branch structure. |
| Test coverage | Weak | No formal tests. |
| Pipeline readiness | Standalone viable | Reference doc, not a pipeline stage. |
| Overlap | Adequate | Standard git branching strategies exist; this is specialized for a specific workflow. Not the kind of thing a built-in tool covers. |
| Trigger clarity | Weak | This is a reference doc, not something invoked at a specific moment. It should be read once, understood, and then followed as habit. The trigger is "you're setting up a new project with this team structure" — rare. |

**Key question:** This is closer to a guide than a workflow. It was likely developed for a specific project and may not generalize well. If the user's team structure changes, this document loses most of its value.

---

## Cross-cutting Observations

### Universal weakness: Test coverage

Every skill and workflow scores Weak on test coverage. This is the single most actionable finding. Priorities for first tests:

1. **fact-check** and **code-fact-check** — Low testability investment, high potential for automated testing with constructed inputs.
2. **draft-review** — Most complex orchestration, most likely to have integration failures.
3. **matrix-analysis** — High standalone value, can test with known-ranking comparisons.

### The code-review pipeline gap

Four skills (code-fact-check, security-reviewer, performance-reviewer, api-consistency-reviewer) are designed as pipeline stages for a code-review orchestrator that doesn't exist. This is the biggest structural gap in the repo. Options:

1. **Build the orchestrator** — Mirrors draft-review's architecture. High payoff: unlocks pipeline value for all four skills.
2. **Prune to standalone** — Remove the pipeline assumptions and treat each as standalone. Loses convergence analysis and sequential staging.
3. **Accept the gap** — The skills have standalone value; the pipeline is a future investment.

### Strongest items (invest further)

- **RPI** — Backbone workflow, well-tested in practice, strong across all dimensions.
- **matrix-analysis** — High counterfactual gap, broad applicability, standalone viable.
- **spike** — Strong design, unique handoff mechanism, clear trigger.
- **draft-review** — Well-architected orchestrator that composes other skills effectively.
- **fact-check** — Foundation skill with high testability and clear standalone value.

### Candidates for monitoring / possible pruning

- **api-consistency-reviewer** — Weakest counterfactual gap of the code-review critics. If the pipeline never materializes, this is the first to reconsider.
- **branch-strategy** — More reference doc than workflow. User reports it reduces git overhead, though the process might be similar without it. Value is real but less differentiated.
- **task-decomposition** — May be better as an RPI variant than a standalone workflow.

### Items that need a decision

- **Code-review orchestrator**: Build it (which validates 4 skills) or accept the gap?
- **Cowen vs. Yglesias standalone**: User confirms standalone value — the cognitive moves have cross-pollinated into other workflows (DD stress-test pass). Keep both. Trigger clarity for standalone use remains the main UX question.
- **Cowen/Yglesias standalone value**: User confirms they have standalone value — the persona-critique cognitive moves have influenced other workflows (DD stress-test pass). Keep both.
