# Self-Evaluation: self-eval

**Target:** `skills/self-eval.md` | **Type:** Skill | **Evaluated:** 2026-03-23
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | Produces structured Markdown with a defined table format (5 automated scores, 4 human-review prompts). Structural properties are mechanically checkable (correct dimension count, human-review dimensions not scored, evidence citations present). But evaluating whether scores and justifications are *correct* requires human judgment — is "Adequate" the right score for a given dimension? No shortcut for that. |
| Trigger clarity | Strong | "Evaluate this skill", "self-eval", "run the rubric on X", "how does X score" are specific and unambiguous. No other skill in the repo does rubric-based evaluation. The rubric document itself anticipated this skill (§ "Self-evaluation design"). No confusing overlap with any other tool. |
| Overlap and redundancy | Strong | No other skill evaluates skills/workflows against the rubric. The `full-evaluation.md` was produced by a manual process applying the rubric directly — self-eval codifies and structures that process. No built-in Claude Code capability does structured skill assessment. Matrix-analysis evaluates options against criteria, but self-eval's dimensions, scoring approach, and human-review prompt generation are entirely distinct. |
| Test coverage | Adequate | No automated tests exist in `test/`. However, 3 real-world outputs demonstrate the skill works: `docs/reviews/self-eval-fact-check.md`, `docs/reviews/self-eval-draft-review.md`, `docs/reviews/self-eval-research-plan-implement.md`. Git history confirms the skill was built and used (commits 40266f1, 651130c). These outputs cover both a skill and a workflow evaluation, showing the skill handles both target types. No automated regression tests, though. |
| Pipeline readiness | Adequate | Standalone viable — users invoke it directly and it produces a complete report. Referenced in `self-improvement.sh` as a planned Phase 3 validation step (line 116: "Phase 3: Self-eval for skill changes (TODO)"), but that integration is not built. No orchestrator currently composes it. The skill is useful today but its highest-leverage use — automated quality gating in the self-improvement loop — is planned, not implemented. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the tool does:** Self-eval reads a target skill/workflow file, reads the evaluation rubric, reads all sibling files for overlap analysis, checks git history and test directories for coverage evidence, checks pipeline references — then produces automated scores (Strong/Adequate/Weak) with justifications for 5 dimensions, and structured prompts (not scores) for 4 human-judgment dimensions. Output is saved as a Markdown report to `docs/reviews/`.

**What generic prompting achieves:** Asking Claude "evaluate this skill" without the self-eval skill file would produce: a less structured assessment (no fixed dimension set), likely scoring all dimensions rather than distinguishing automatable from human-judgment ones, missing the systematic evidence-gathering steps (reading all sibling files, checking git log, checking pipeline references), and no consistent output format across evaluations. A skilled user could produce a good evaluation by pasting the rubric and asking Claude to apply it — the main gap is: (1) the systematic evidence-gathering procedure in Step 3, (2) the distinction between automated and human-judgment dimensions, (3) the consistent report format enabling comparison across evaluations, and (4) the structured prompts that make human review efficient rather than open-ended.

**What built-in tools cover:** No built-in Claude Code capability does skill/workflow evaluation. The built-in verification-coordinator handles code test planning, not skill assessment.

**Questions for the reviewer:**
- How much of self-eval's value comes from the consistent report format (enabling comparison across evaluations) vs. the evidence-gathering procedure (ensuring overlap analysis and test coverage checks actually happen)?
- Is the automated/human-judgment split correctly drawn? Could any of the "human-judgment" dimensions (counterfactual gap, user-specific fit, condition for value, failure mode gracefulness) be partially automated with acceptable accuracy?
- Under what conditions is the gap largest — evaluating a new skill before merge (where the structured prompts guide first-time assessment) or re-evaluating an existing skill (where you already have opinions)?

### User-Specific Fit

**Triggering situations:**
- User adds a new skill or workflow and wants pre-merge assessment
- User wants to periodically reassess existing tools as conditions change
- Self-improvement loop wants automated quality gating on skill changes (planned, not built)
- User wants to compare quality across the skill/workflow inventory

**Questions for the reviewer:**
- How often do you add new skills or workflows? Is this frequency increasing or decreasing as the repo matures?
- Do you actually run self-eval before merging new skills, or has it been used more for retrospective assessment?
- Would you remember to invoke self-eval when adding a new skill, or does it need to be enforced by the self-improvement pipeline?
- Is the periodic reassessment use case real? Have you re-run self-eval on a skill whose conditions changed?

### Condition for Value

**Stated or inferred conditions:**
1. The evaluation rubric must exist at `docs/evaluation-rubric.md` — it does.
2. There must be skills/workflows to evaluate — 14 skills and 8 workflows exist.
3. The user must value structured evaluation over ad-hoc judgment.
4. For pipeline value: the self-improvement loop must integrate self-eval as a validation step — this is planned (TODO in `self-improvement.sh` line 116) but not built.

**Automated findings:**
- Evaluation rubric: EXISTS at `docs/evaluation-rubric.md`.
- Sibling skills to evaluate: 13 other skills exist in `skills/`.
- Sibling workflows: 8 workflows exist in `workflows/`.
- Prior self-eval outputs: 3 reports exist in `docs/reviews/` (fact-check, draft-review, RPI).
- Self-improvement.sh integration: PLANNED (TODO comment), NOT IMPLEMENTED.
- No orchestrator currently references or composes self-eval.

**Questions for the reviewer:**
- Is the self-improvement loop integration a realistic next step, or speculative? What would need to happen to build Phase 3?
- Without the pipeline integration, is standalone self-eval valuable enough to justify maintaining the skill file?
- Has using self-eval changed how you think about skill design — i.e., does the evaluation feedback loop actually influence future skill development?

### Failure Mode Gracefulness

**Output structure:** A Markdown report with two sections: (1) a table of 5 automated scores with 1-2 sentence justifications, and (2) structured prompts for 4 human-review dimensions, each containing what the tool found, what automated analysis revealed, and specific questions for the reviewer. The format is consistent across evaluations, enabling comparison.

**Potential silent failures:**
1. **Inflated scores:** The skill instructions say "be honest" and "a low score with clear justification is more useful than an inflated score," but LLMs have a well-documented tendency toward positive assessment. The skill could systematically score Adequate where Weak is warranted, producing authoritative-looking evaluations that don't surface real weaknesses.
2. **Shallow evidence gathering:** Step 3 requires reading all sibling files and checking git history. The skill could skim rather than read, missing substantive overlap or test evidence. The report would look complete (all sections filled) but be built on incomplete analysis.
3. **Wrong automated/human split:** If the skill scores a dimension that should require human judgment (e.g., producing a confident "Strong" for something that's actually ambiguous), the user might accept it without the critical review that a human-judgment prompt would have triggered.
4. **Stale rubric application:** The skill reads the rubric at runtime, but could apply dimension definitions inconsistently across evaluations if the rubric has been updated between runs.

**Pipeline mitigations:** The 3 existing reports can be compared for scoring consistency. The human-review prompts explicitly flag what needs human judgment, reducing the risk of full automation bias. The rubric is read at runtime (Step 2 instruction), not hardcoded.

**Questions for the reviewer:**
- Have you noticed score inflation in the existing self-eval reports? Compare them against the manual evaluations in `full-evaluation.md` — do the automated scores track the manual ones?
- For the 3 existing reports, did the human-review prompts actually prompt useful reflection, or did you skim past them?
- Is the biggest risk inflated scores (false confidence) or missed overlap (incomplete analysis)?

---

## Key Questions

1. **Does self-eval actually change decisions?** The skill produces reports, but the real test is whether those reports have influenced a keep/prune/improve decision on any skill or workflow. If the reports are read and filed but never acted on, the skill produces information without value. Evidence from the 3 existing reports: did any finding lead to a concrete change?

2. **Is the self-improvement loop integration the skill's highest-leverage next step?** `self-improvement.sh` has a TODO for Phase 3 (self-eval for skill changes). If built, this would make self-eval a gating check on autonomously generated skills — a much higher-stakes role than retrospective assessment. But it also raises the bar: the inflated-score failure mode becomes dangerous if self-eval is approving skills without human review.

3. **Is self-eval evaluating itself a useful signal or a hall of mirrors?** This evaluation is inherently limited by the same biases it's trying to detect. The most useful output from this meta-evaluation is the human-review prompts above — particularly the question about score inflation across the existing reports.
