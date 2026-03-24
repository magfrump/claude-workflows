# Self-Evaluation: self-eval

**Target:** `skills/self-eval.md` | **Type:** Skill | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | Output is structured Markdown with a fixed table of 5 scored dimensions, 4 human-review prompt sections, and a Key Questions section. Structural properties (dimension count, score values, section presence) are mechanically checkable, and `test/skills/self-eval-format.bats` already validates these. However, evaluating whether scores are *correct* (e.g., is "Adequate" right for a given dimension?) requires human judgment with no shortcut. |
| Trigger clarity | Strong | Triggers are specific and unambiguous: "evaluate this skill", "self-eval", "run the rubric on X", "how does X score on the rubric", pre-merge assessment, periodic reassessment. No other skill in the repo does rubric-based evaluation. The rubric itself anticipated this skill. Zero overlap with any other tool's trigger space. |
| Overlap and redundancy | Strong | No other skill evaluates skills or workflows against the evaluation rubric. Matrix-analysis orchestrates multi-criteria comparison of arbitrary options, but self-eval has a fixed dimension set, a fixed automated/human-judgment split, and produces structured prompts rather than scores for the human-judgment dimensions — a fundamentally different analytical approach. No built-in Claude Code capability does skill assessment. |
| Test coverage | Adequate | Automated structural tests exist in `test/skills/self-eval-format.bats` (13 test cases validating header, table structure, score values, human-review sections, key questions). Four real-world outputs exist in `docs/reviews/` (fact-check, draft-review, research-plan-implement, and this self-eval). Git history shows the skill was built and used across multiple commits. However, no tests verify that scores or justifications are *substantively correct* — only that the output format is valid. |
| Pipeline readiness | Strong | Standalone viable: users invoke it directly and it produces a complete, useful report. Also integrated into the self-improvement pipeline: `self-improvement.sh` Gate 1g runs self-eval on changed skills/workflows and rejects branches with 2+ Weak automated scores. This is a functioning pipeline role, not a planned one — the code is implemented and runs. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the tool does:** Self-eval reads a target skill/workflow, reads the evaluation rubric at `docs/evaluation-rubric.md`, reads all sibling files in `skills/` and `workflows/` for overlap analysis, checks `test/` for test evidence, checks `docs/reviews/` for output artifacts, checks git history for usage evidence, and checks pipeline references in orchestrator skills. It then produces automated scores (Strong/Adequate/Weak) with justifications for 5 dimensions, structured prompts (not scores) for 4 human-judgment dimensions, and 2-3 key questions. The report is saved as structured Markdown.

**What generic prompting achieves:** Asking Claude "evaluate this skill against the rubric" while pasting the rubric would produce a reasonable evaluation — Claude can apply criteria to a target. What would likely be missing: (1) the systematic evidence-gathering procedure (reading all 13 sibling skills for overlap analysis, checking git log, checking test directories, checking pipeline references — a user would need to prompt each of these separately), (2) the automated/human-judgment split (a generic prompt would likely score all 9 dimensions rather than producing structured prompts for the subjective ones), (3) consistent output format across evaluations (enabling comparison), and (4) the specific prompt structure for human-review dimensions that makes reviewer effort efficient rather than open-ended.

**What built-in tools cover:** No built-in Claude Code capability does skill/workflow evaluation or rubric-based assessment.

**Questions for the reviewer:**
- How much of self-eval's value comes from the evidence-gathering procedure (ensuring overlap analysis and coverage checks happen systematically) vs. the report format (enabling comparison across evaluations)?
- Is the automated/human-judgment split the right one? The rubric's "Open questions" section noted that testability investment and trigger clarity seemed automatable, while user-specific fit and counterfactual gap probably don't — has that prediction held up?
- Under what conditions is the gap largest: evaluating a new skill before merge (where the structured prompts guide first-time assessment), or re-evaluating an existing skill (where you have prior reports to compare against)?

### User-Specific Fit

**Triggering situations:**
- Adding a new skill or workflow and wanting pre-merge quality assessment
- Periodically reassessing existing tools as conditions change (rubric suggests this)
- Self-improvement loop running automated quality gating on skill changes (implemented in Gate 1g)
- Comparing quality across the skill/workflow inventory

**Questions for the reviewer:**
- How often do you add new skills or workflows? Is the repo in a growth phase (frequent additions) or a maintenance phase (infrequent changes)?
- Has the self-improvement pipeline's Gate 1g (which runs self-eval automatically) changed how much you rely on manual self-eval invocations?
- Do you actually use the human-review prompts when reading self-eval reports, or do you primarily look at the automated scores table?
- Is periodic reassessment a real use case you've practiced, or an aspirational one? Have you re-run self-eval on a skill whose conditions changed since the last evaluation?

### Condition for Value

**Stated or inferred conditions:**
1. The evaluation rubric must exist at `docs/evaluation-rubric.md` — it does.
2. There must be skills/workflows to evaluate — 14 skills and 8 workflows exist.
3. The user must value structured evaluation over ad-hoc judgment.
4. For standalone value: the user must actually invoke self-eval and act on findings.
5. For pipeline value: the self-improvement loop must integrate self-eval — this IS now implemented (Gate 1g in `self-improvement.sh`).

**Automated findings:**
- Evaluation rubric: EXISTS at `docs/evaluation-rubric.md`.
- Sibling skills to evaluate: 13 other skills exist in `skills/`.
- Sibling workflows: 8 workflows exist in `workflows/`.
- Prior self-eval outputs: 4 reports exist in `docs/reviews/` (fact-check, draft-review, research-plan-implement, self-eval).
- Self-improvement.sh integration: IMPLEMENTED (Gate 1g, lines 205-235). Runs self-eval on any changed skill/workflow and rejects branches with 2+ Weak automated scores.
- Automated format tests: EXIST at `test/skills/self-eval-format.bats` (13 test cases).

**Questions for the reviewer:**
- Now that the pipeline integration is built, has self-eval actually rejected a branch? Is the 2+ Weak threshold well-calibrated, or does it let too much through (or reject too aggressively)?
- Has any self-eval finding (from manual or pipeline invocation) led to a concrete change in a skill or workflow?
- Is the skill earning its maintenance cost? Each rubric update potentially requires verifying that self-eval still applies the rubric correctly.

### Failure Mode Gracefulness

**Output structure:** A Markdown report with two cleanly separated sections: (1) a table of 5 automated scores with justifications, and (2) structured prompts for 4 human-review dimensions, each containing factual findings and specific questions. The format distinguishes what the skill assessed from what it defers to human judgment, making it clear where automation ends. Scores use a constrained 3-level vocabulary (Strong/Adequate/Weak).

**Potential silent failures:**
1. **Score inflation:** LLMs systematically bias toward positive assessment. The skill could score "Adequate" where "Weak" is warranted — particularly for Test Coverage and Pipeline Readiness, where the evidence threshold is judgment-dependent. The report would look authoritative (all sections filled, justifications present) while understating weaknesses. This is the most likely silent failure.
2. **Shallow overlap analysis:** Step 3a requires reading all sibling files and comparing analytical approaches. The skill could note "no overlap" after only reading frontmatter descriptions rather than skimming the actual analytical moves. The report would claim thorough overlap analysis without doing it.
3. **Stale evidence:** The skill checks git history and `docs/reviews/` for test evidence, but could miss recently added or removed artifacts if its search is incomplete. Scoring Test Coverage based on artifacts that no longer exist or missing artifacts that do.
4. **Self-referential blindness:** When evaluating itself (as now), the skill has an inherent conflict of interest. It is unlikely to assign itself a "Weak" score on any dimension, even where warranted, because it is both judge and defendant.

**Pipeline mitigations:** The 4 existing reports enable cross-report consistency checking. The automated format tests in `self-eval-format.bats` catch structural failures (missing sections, invalid scores). The human-review prompts explicitly flag what needs human judgment, creating a natural checkpoint against automation bias. The self-improvement pipeline only uses automated scores for gating (not human-review dimensions), limiting the blast radius of inflated human-judgment assessments.

**Questions for the reviewer:**
- Compare the automated scores across the 4 existing self-eval reports. Do the justifications track your own assessment, or do you notice systematic inflation?
- Has the self-improvement pipeline's Gate 1g ever been the deciding factor in rejecting a branch? If not, is the threshold too lenient?
- For this self-referential evaluation specifically: which scores above do you think are inflated? The self-referential blindness failure mode predicts that at least one score here is too generous.

---

## Key Questions

1. **Is self-eval's primary value now in the pipeline rather than standalone use?** With Gate 1g implemented in `self-improvement.sh`, self-eval has shifted from a tool humans invoke manually to a quality gate the pipeline runs automatically. If pipeline use dominates, the human-review prompts (which the pipeline ignores) may be over-engineered for the actual use case — or they may be the reason manual invocations remain valuable. Which mode delivers more value?

2. **Is score inflation detectable in practice?** The skill's most dangerous failure mode is systematic positive bias in automated scores. With 4 existing reports and a functioning pipeline, there is now enough data to audit. Do the automated scores track your independent judgment? If they don't, the pipeline's 2+ Weak threshold may be meaningless — skills that deserve Weak get scored Adequate and pass the gate.

3. **Does the self-referential evaluation expose the skill's limits or validate it?** This report evaluating self-eval is inherently constrained by the same biases it tries to detect. The most useful test: compare these scores against your independent assessment. Where they diverge, the divergence itself is the finding — it reveals which dimensions self-eval handles poorly when the subject is itself.
