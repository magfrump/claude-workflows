# External Skill Repo Audit

**Date:** 2026-04-08
**Branch:** feat/r1-external-skill-repo-audit
**Hypothesis:** The audit will identify at least 2 skills from external repos that address gaps not covered by any of the current 15 skills, and at least 1 of those will be implemented within the next 3 rounds.

## Current Skill Inventory (15 skills)

| Category | Skills |
|---|---|
| Code Review & Quality | code-review (orchestrator), code-fact-check, security-reviewer, performance-reviewer, api-consistency-reviewer |
| Writing Review | draft-review (orchestrator), fact-check, cowen-critique, yglesias-critique |
| Dev Maintenance | dependency-upgrade, tech-debt-triage, test-strategy |
| Evaluation / Meta | matrix-analysis (orchestrator), self-eval |
| UI | ui-visual-review |

**Pattern observations:** All 15 skills are *review/analysis* focused. None create artifacts, drive implementation, or structure debugging. The code-review pipeline is deep (5 skills); writing review has 4. Gaps exist in architecture review, debugging, creation/generation, and testing execution.

---

## Repos Assessed

### 1. anthropics/skills (17 skills)

Anthropic's official skill repo. Mix of creative/design skills (algorithmic-art, canvas-design, frontend-design), document skills (docx, pdf, pptx, xlsx), and development tools (claude-api, mcp-builder, webapp-testing, skill-creator).

**Overlaps with current set:**
- None directly — Anthropic's skills are creation-oriented; ours are review-oriented.

**Notable candidates:**
- **skill-creator** — Meta-skill for creating, improving, and benchmarking skills. Relates to self-eval but focuses on creation rather than evaluation.
- **doc-coauthoring** — Structured 3-phase document workflow (context gathering → refinement → reader testing). No current skill addresses structured content creation.
- **webapp-testing** — Playwright-based skill for testing web apps, capturing screenshots, reading browser logs. test-strategy recommends tests but doesn't execute them.

**Conflicts:** None. Different paradigm (creation vs. review).

### 2. VoltAgent/awesome-agent-skills (1,060+ entries)

Curated awesome-list aggregating skills from many publishers. Not a source repo — it indexes skills from Anthropic, Cloudflare, Netlify, Vercel, HashiCorp, Trail of Bits, Microsoft, and many others.

**Overlaps with current set:**
- Trail of Bits security skills overlap with security-reviewer but are more tool-specific (static analysis, contract auditing).
- Vercel Labs design guidelines overlap loosely with ui-visual-review.

**Notable candidates:**
- **Trail of Bits security suite** — Vulnerability scanning, static analysis, threat modeling. More tooling-oriented than our cognitive-move-based security-reviewer; complementary rather than redundant.
- **Pawel Huryn product management skills** (65+ skills) — Discovery, strategy, metrics. No current skills address product/requirements analysis.

**Conflicts:** None — this is an index, not a methodology.

### 3. K-Dense-AI/claude-scientific-skills (134 skills)

Massive scientific computing skill library. Covers bioinformatics, cheminformatics, ML, statistics, clinical tools, scientific publishing, and research methodology.

**Overlaps with current set:**
- peer-review overlaps with draft-review/fact-check in intent but targets scientific manuscripts specifically.
- scientific-critical-thinking overlaps with fact-check's verification approach.

**Notable candidates:**
- **literature-review** — Systematic literature review workflows. Extends the writing-review pipeline to academic research contexts.
- **hypothesis-generation / hypogenic** — Automated hypothesis generation and iterative testing. No current skill structures hypothesis-driven reasoning.
- **what-if-oracle** — Counterfactual reasoning and scenario analysis. Unique analytical capability not covered by any current skill.
- **scientific-critical-thinking** — Critical analysis of scientific claims with structured evaluation. More domain-specific than fact-check.

**Conflicts:** Scientific domain focus is narrow; would need generalization to fit current patterns.

### 4. sickn33/antigravity-awesome-skills (1,392+ skills)

Largest repo assessed. Community-contributed skill playbooks organized by category. Broad coverage from architecture to marketing to security to game development.

**Overlaps with current set:**
- security-auditor overlaps with security-reviewer.
- api-design-principles overlaps with api-consistency-reviewer.
- create-pr overlaps with the pr-prep workflow (not a skill, but same function).
- test-driven-development overlaps with test-strategy in scope.

**Notable candidates:**
- **architecture-decision-records** — Structured ADR creation and architectural decision documentation. No current skill reviews or creates architectural decisions.
- **debugging-strategies / phase-gated-debugging** — Systematic hypothesis-driven debugging. There's a bug-diagnosis *workflow* but no *skill*. Converting this to a skill would make it invocable from code-review or standalone.
- **brainstorming** — Transform vague ideas into validated designs. No current skill supports ideation/design exploration.
- **explain-like-socrates** — Socratic teaching method. Interesting pedagogical approach, but narrow use case.

**Conflicts:** Many skills are thin wrappers (just a SKILL.md template) — quality varies significantly. Need to evaluate actual content before adapting.

### 5. snwfdhmp/awesome-gpt-prompt-engineering (resource list)

Curated list of prompt engineering resources, techniques, papers, and tools. Not a skills repo — it's a learning resource aggregation.

**Overlaps with current set:**
- Multi Persona Collaboration technique is already embodied in cowen-critique/yglesias-critique.
- Chain of Thought reasoning is implicitly used in several skills.

**Notable candidates:**
- **Tree of Thoughts** technique — Structured exploration of multiple reasoning paths with backtracking. Could inform a "divergent analysis" skill.
- **Decomposed Prompting** — Breaking complex tasks into sub-problems. Already reflected in workflows (task-decomposition) but not as a skill.

**Conflicts:** These are techniques, not skills. Would need significant design work to become skills. Low ROI relative to other candidates.

---

## Gap Analysis

| Gap | Current Coverage | External Candidates |
|---|---|---|
| Architecture review | None | antigravity: architecture-decision-records, architecture |
| Debugging/diagnosis | Workflow only (bug-diagnosis.md) | antigravity: debugging-strategies, phase-gated-debugging |
| Content creation | None (all skills are review) | anthropics: doc-coauthoring |
| Hypothesis/reasoning | None | K-Dense: hypothesis-generation, what-if-oracle |
| Testing execution | test-strategy recommends only | anthropics: webapp-testing |
| Ideation/brainstorming | None | antigravity: brainstorming |

---

## Recommendations: 3-5 Skills Worth Adapting

### 1. Architecture Reviewer (HIGH priority)
**Source:** antigravity-awesome-skills (architecture-decision-records + architecture)
**Gap filled:** No current skill reviews architectural decisions or structural design choices.
**Rationale:** The code-review pipeline catches implementation issues but misses design-level concerns — e.g., "this service shouldn't depend on that module" or "this violates the bounded context." An architecture-reviewer would slot into the code-review orchestrator as a contextual critic, following the same cognitive-move pattern as security-reviewer and performance-reviewer.
**Adaptation needed:** Rewrite from antigravity's creation-oriented template into our review-oriented pattern. Focus on cognitive moves: dependency direction analysis, coupling detection, responsibility allocation review, interface boundary validation.
**Hypothesis tracking:** This is Gap Skill #1.

### 2. Debugging Diagnosis Skill (HIGH priority)
**Source:** antigravity-awesome-skills (debugging-strategies, phase-gated-debugging)
**Gap filled:** bug-diagnosis.md is a workflow (human-orchestrated), not a skill (agent-invocable). Converting the core loop into a skill makes structured debugging available within sessions.
**Rationale:** The hypothesis-test debugging loop (reproduce → isolate → hypothesize → test → fix → verify) is well-defined in the workflow but requires the user to manually invoke it. A skill version could be triggered by the agent when encountering failures during implementation, or invoked directly.
**Adaptation needed:** Extract the cognitive moves from the existing bug-diagnosis workflow. Add structured output (hypothesis log, evidence chain). Don't duplicate the workflow — the skill should be the inner loop that the workflow orchestrates.
**Hypothesis tracking:** This is Gap Skill #2.

### 3. What-If / Counterfactual Analysis (MEDIUM priority)
**Source:** K-Dense-AI (what-if-oracle)
**Gap filled:** No current skill supports "what happens if we change X?" reasoning.
**Rationale:** Useful during tech-debt-triage ("what breaks if we defer this?"), dependency-upgrade ("what breaks if we upgrade?"), and architectural decisions ("what happens at 10x scale?"). Could be an independent skill or integrated as a cognitive move into existing reviewers.
**Adaptation needed:** Generalize from scientific domain to software engineering. Structure around: identify assumptions → enumerate scenarios → trace consequences → assess reversibility.
**Hypothesis tracking:** Potential Gap Skill #3, but may be better as a cognitive move within existing skills than a standalone skill.

### 4. Doc Coauthoring (MEDIUM priority)
**Source:** anthropics/skills (doc-coauthoring)
**Gap filled:** All current skills are review-oriented. This is the strongest creation-oriented candidate that fits the existing quality standards.
**Rationale:** The 3-phase workflow (context gathering → refinement & structure → reader testing) is well-designed and complements draft-review. Together they'd form a create-then-review pipeline. However, this represents a paradigm shift from "review existing work" to "create new work."
**Adaptation needed:** Evaluate whether creation skills belong in this skill set at all, or if they should be a separate collection. If included, adapt the Anthropic version's Claude.ai-specific features to work in Claude Code contexts.
**Hypothesis tracking:** Not a gap skill (it's a paradigm expansion, not a gap fill).

### 5. Hypothesis-Driven Reasoning (LOW priority)
**Source:** K-Dense-AI (hypothesis-generation, hypogenic)
**Gap filled:** No skill structures hypothesis formation and testing as a general analytical tool.
**Rationale:** The scientific skills repo has sophisticated hypothesis generation that could generalize to software contexts — e.g., "why is this test flaky?" or "what's causing this performance regression?" However, this overlaps significantly with the debugging-diagnosis skill (#2) and the existing bug-diagnosis workflow.
**Adaptation needed:** Heavy generalization from scientific to software domain. Risk of overlap with debugging skill.
**Hypothesis tracking:** Deprioritized due to overlap with #2.

---

## Skills Explicitly NOT Recommended

| Skill | Source | Reason |
|---|---|---|
| webapp-testing | anthropics | Execution-focused, not review-focused; better as a workflow tool than a skill |
| Trail of Bits security | VoltAgent | Tool-specific; security-reviewer already covers the cognitive approach |
| brainstorming | antigravity | Too generic; divergent-design workflow already serves this purpose |
| Tree of Thoughts | snwfdhmp | Technique, not a skill; already implicit in how skills structure reasoning |
| scientific-critical-thinking | K-Dense | Too domain-specific; fact-check already covers general verification |

---

## Summary for Hypothesis Evaluation

**Skills identified that address gaps:** 3 clear gap-fills (#1 Architecture Reviewer, #2 Debugging Diagnosis, #3 What-If Analysis)
**Hypothesis met?** Yes — at least 2 skills address gaps not covered by any current skill.
**Implementation prediction:** Architecture Reviewer (#1) is the strongest candidate for near-term implementation, as it follows existing patterns most closely and fills the most obvious gap in the code-review pipeline. Debugging Diagnosis (#2) requires more design work due to the workflow/skill boundary question.

**Tracking:** To evaluate the "implemented within 3 rounds" prediction, check whether any of these skills appear in the `skills/` directory in commits after this audit date (2026-04-08).
