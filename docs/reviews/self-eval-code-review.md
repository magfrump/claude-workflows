---
Last verified: 2026-03-24
Relevant paths:
  - skills/code-review.md
  - skills/code-fact-check.md
  - skills/security-reviewer.md
  - skills/performance-reviewer.md
  - skills/api-consistency-reviewer.md
  - test/skills/code-review-format.bats
  - docs/reviews/code-review-rubric.md
  - patterns/orchestrated-review.md
---

# Self-Evaluation: code-review

**Target:** `skills/code-review.md` | **Type:** Skill (orchestrator) | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | The rubric output is highly structured (tiered tables, status lines, severity mapping) and format tests exist in `test/skills/code-review-format.bats`. However, testing the orchestration logic (correct agent dispatch, fact-check gate, escalation rules, contextual critic auto-selection) requires multi-agent integration testing with substantial setup — quality of the synthesis deliverable requires human judgment. |
| Trigger clarity | Strong | The frontmatter lists concrete trigger phrases ("review this code", "full code review", "review this PR", "run all critics") and explicitly distinguishes itself from standalone critic invocation. The boundary with `draft-review` is clear (code vs. prose). Step 2 enumerates exactly which skills are orchestrated and which are skipped, preventing false dispatch. |
| Overlap and redundancy | Strong | No other skill in the repo does multi-perspective code review orchestration. `draft-review` is the prose-review counterpart; `matrix-analysis` is a comparison orchestrator. The individual critic skills (security, performance, API consistency) overlap in topic area but serve as pipeline components, not competitors. The orchestrator's unique value is in the synthesis, escalation logic, and severity mapping — none of which the standalone critics provide. |
| Test coverage | Adequate | A format validation test suite exists (`test/skills/code-review-format.bats`, 14 assertions on rubric structure). Multiple real-world output artifacts exist in `docs/reviews/` (the rubric, plus several review-fix-loop iterations like `code-review-review-fix-loop.md`, `code-review-r2-convergence.md`, etc.). Git history shows the skill has been used on real branches. However, there are no automated integration tests that verify orchestration behavior (agent dispatch order, gate logic, escalation). |
| Pipeline readiness | Strong | This skill is itself a functioning pipeline orchestrator. It composes `code-fact-check`, `security-reviewer`, `performance-reviewer`, `api-consistency-reviewer`, and three contextual critics. All composed skills exist and reference the code-review orchestrator in their descriptions. The skill is also standalone viable — it produces a self-contained rubric document. The orchestrated-review pattern document it references exists at `patterns/orchestrated-review.md`. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the tool does:** Orchestrates a 3-stage code review pipeline: (1) code fact-check to verify claims in comments/docs against actual behavior, (2) parallel critic agents (security, performance, API consistency, plus auto-selected contextual critics), (3) synthesis into a chat summary and structured rubric with tiered severity (red/amber/green), escalation rules for cross-critic convergence, and a fact-check gate that pauses on high-confidence incorrect findings.

**What generic prompting achieves:** Asking Claude "do a code review" would produce a single-pass review covering multiple concerns but without: the staged pipeline ensuring fact-check precedes analysis, parallel independent critic perspectives that enable convergence detection, the structured severity mapping across domains, the escalation rule rewarding independent agreement, the fact-check gate, contextual critic auto-selection based on diff analysis, or the reusable rubric format with status tracking for re-runs.

**What built-in tools cover:** Claude Code has no built-in multi-agent code review orchestrator. The `/review` command provides basic code review but without the structured pipeline, convergence detection, or rubric output.

**Questions for the reviewer:**
- How much of the skill's value comes from the structured rubric format and severity tracking (consistency) vs. the multi-agent pipeline and convergence detection (unique analytical architecture)?
- Is the gap "the orchestrator catches things a single-pass review would miss" (convergence finding real issues) or "the orchestrator ensures nothing is forgotten" (checklist completeness)?
- Under what conditions is the gap largest — large diffs touching multiple subsystems, or is it equally valuable on small focused changes?

### User-Specific Fit

**Triggering situations:** Code review before merge; PR review; comprehensive multi-perspective review of code changes; combining security + performance + API consistency review in a single pass.

**Questions for the reviewer:**
- How often do you perform code review on branches before merge in your actual workflow?
- Do you typically want multi-perspective review (security + performance + API), or do you more often want a single focused review (just security, just performance)?
- Is the overhead of the full pipeline (fact-check + 3-6 critic agents + synthesis) proportionate to your typical change size, or do most of your changes warrant a lighter touch?
- Would you actually remember to invoke this, or would you more naturally ask for a generic "review this code"?

### Condition for Value

**Stated or inferred conditions:**
1. The sub-agent skills it orchestrates must exist and function correctly (code-fact-check, security-reviewer, performance-reviewer, api-consistency-reviewer, plus contextual critics).
2. The Agent tool must be available for spawning sub-agents.
3. Changes being reviewed must be substantial enough to justify a multi-agent pipeline (vs. a quick single-pass review).

**Automated findings:**
- `code-fact-check.md`: EXISTS
- `security-reviewer.md`: EXISTS
- `performance-reviewer.md`: EXISTS
- `api-consistency-reviewer.md`: EXISTS
- `test-strategy.md`: EXISTS
- `tech-debt-triage.md`: EXISTS
- `dependency-upgrade.md`: EXISTS
- `patterns/orchestrated-review.md`: EXISTS
- All three core critics reference `code-review` orchestrator in their descriptions: CONFIRMED
- Format tests for the rubric output: EXIST

**Questions for the reviewer:**
- Are the conditions met today? (All sub-skills exist; the question is whether the Agent tool reliably spawns them and they produce quality output.)
- Have you encountered situations where the pipeline overhead was disproportionate to the change size? If so, is there a natural threshold below which you'd skip the orchestrator?
- Is the value primarily from the orchestration (parallel dispatch, convergence, synthesis) or could you get comparable results by running the critics manually in sequence?

### Failure Mode Gracefulness

**Output structure:** Two deliverables: (1) a freeform chat synthesis organized by cross-critic findings, per-domain findings, and actionable guidance; (2) a structured rubric with tiered tables (Must Fix / Must Address / Consider / Confirmed Good), each finding tagged with domain, location, and status. The rubric includes a status line (DOES NOT PASS / CONDITIONAL PASS / PASSES REVIEW) and clear pass criteria.

**Potential silent failures:**
- **Missed convergence:** Two critics flag overlapping concerns in different language, and the orchestrator fails to detect the semantic overlap — the finding stays at a lower severity tier instead of being escalated. This is hard to catch because the rubric still looks complete.
- **Severity mis-mapping:** A critic rates something as "Medium" but the orchestrator maps it to the wrong rubric tier, especially for edge cases in the unified severity mapping table. The rubric looks authoritative but the tier assignment is wrong.
- **Fact-check gate false negative:** The fact-check misses an incorrect claim (rates it Accurate), so the gate doesn't trigger and critics build analysis on a false premise. The downstream critique looks plausible but is grounded in wrong assumptions.
- **Sub-agent failure silently absorbed:** A sub-agent returns thin or off-topic output, and the orchestrator synthesizes it without flagging the quality gap. The rubric appears complete but one domain's findings are shallow.

**Pipeline mitigations:** The staged pipeline design partially mitigates some failures — fact-check runs first so critics can build on verified facts. The mandatory execution rules require checking that all agents returned results. The skill instructs the orchestrator to "note honestly" if a sub-agent fails. The structured rubric makes thin sections somewhat visible (a domain with only "Consider" items when others have "Must Fix" may signal a weak critic pass).

**Questions for the reviewer:**
- Based on your experience running this skill, which failure mode is most common — missed convergence, severity mis-mapping, or something else?
- Have you observed cases where the synthesis smoothed over a sub-agent's thin output, making it look more thorough than it was?
- Is the detectable-to-silent failure ratio acceptable, or do you find yourself re-reading individual critic reports to verify the synthesis?

---

## Key Questions

1. **Is convergence detection delivering real value?** The escalation rule (promoting findings when 2+ critics independently flag the same issue) is the skill's most distinctive architectural feature. Has this actually surfaced important issues that individual critics would have under-weighted, or does it mostly confirm what was already obvious from any single critic?

2. **Does the pipeline scale down gracefully?** The skill is designed for comprehensive multi-perspective review, but many code changes are small and focused. Is there a natural lightweight mode (e.g., fact-check + one critic), or does the overhead always require the full pipeline — and if so, does that limit how often it gets used?

3. **How reliable is the orchestration in practice?** The skill has extensive mandatory execution rules and checkpoints, but its correctness depends on the LLM faithfully following a complex multi-step protocol with agent dispatching. How often does the orchestration break down (agents not spawned, stages run out of order, results not properly synthesized)?
