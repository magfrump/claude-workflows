# Plan: Self-Evaluation Skill

## Scope

Build a skill that reads `docs/evaluation-rubric.md` at runtime and applies automatable rubric dimensions to a target skill/workflow, flagging human-judgment dimensions for manual review.

**Research doc:** [research-self-eval-skill.md](research-self-eval-skill.md)

## Approach

Single-agent skill (not an orchestrator) modeled after `fact-check.md` and `security-reviewer.md`. The skill reads the target file, reads the rubric, reads sibling skills for overlap analysis, checks for test coverage evidence, and produces a structured evaluation report. Automated assessments use the rubric's three-level scale; human-judgment dimensions get a structured prompt for what to consider rather than a score.

## Steps

### Step 1: Create `skills/self-eval.md` (~250 lines)

YAML frontmatter with name, description, and trigger phrases.

Body sections:
1. **Scoping** — Accept target as a skill path or workflow path. Read the target file. Determine if it's a skill or workflow from its location and structure.
2. **Read the rubric** — Read `docs/evaluation-rubric.md` at runtime (not hardcoded). Extract dimension definitions.
3. **Automated dimensions** — For each automatable dimension, specify the analysis procedure:
   - **Testability investment**: Analyze input/output structure. Does the skill produce checkable artifacts? Can you construct a test input with known-correct output?
   - **Trigger clarity**: Parse the frontmatter `description` for trigger phrases. Check specificity. Compare against all other skills' triggers for ambiguity/overlap.
   - **Overlap and redundancy**: Read all sibling skill files. Compare analytical approaches, cognitive moves, and output formats. Identify substantive vs. structural overlap.
   - **Test coverage**: Check for test files in `test/`, example outputs in `docs/reviews/`, and git history for evidence the skill has been run.
   - **Pipeline readiness**: Check if the skill has `requires` dependencies. Search orchestrator skills for references. Determine standalone viability.
4. **Human-judgment dimensions** — For each non-automatable dimension, produce a structured prompt:
   - **Counterfactual gap**: State what the skill does, what generic prompting would achieve, and what questions the human should consider.
   - **User-specific fit**: List the triggering situations and frequency questions from the rubric.
   - **Condition for value**: State what condition the skill depends on and what the automated analysis found about whether infrastructure exists.
   - **Failure mode gracefulness**: Identify output structure and flag where silent failures are possible vs. detectable.
5. **Output format** — Structured markdown report with:
   - Header with target name, date, evaluator note ("automated assessment — human review required for flagged dimensions")
   - Table per automated dimension with score + justification
   - Section per human-judgment dimension with structured prompts
   - Key questions section (like the examples in the rubric)
6. **Output location** — Save to `docs/reviews/self-eval-{target-name}.md`

### Step 2: Validate by running on `fact-check` skill

Invoke the skill targeting `skills/fact-check.md`. Verify:
- All 5 automated dimensions produce scores with justifications
- All 4 human-judgment dimensions produce structured prompts
- Output is saved to `docs/reviews/self-eval-fact-check.md`
- Results are consistent with the manual evaluation in `full-evaluation.md`

### Step 3: Validate by running on `draft-review` orchestrator

Invoke targeting `skills/draft-review.md`. Verify:
- Orchestrator-specific considerations are handled (pipeline readiness should note it IS the pipeline)
- Overlap analysis correctly identifies it as unique
- Trigger clarity picks up the trigger phrases from frontmatter

### Step 4: Validate by running on `research-plan-implement` workflow

Invoke targeting `workflows/research-plan-implement.md`. Verify:
- Workflow vs. skill distinction is handled (per rubric table at line 133)
- Acknowledges that workflow testability is harder ("test the artifacts, not the process")

## Size estimate

- Step 1: ~250 lines in a new file
- Steps 2-4: Validation runs producing ~100-150 line reports each

## Testing strategy

- Run the skill on 3 different target types (standalone skill, orchestrator skill, workflow)
- Compare automated scores against the manual evaluations in `full-evaluation.md` for consistency
- Verify human-judgment sections ask the right questions (not producing scores)

## Risks

- The skill might produce superficial overlap analysis if it doesn't read deep enough into sibling skills. Mitigation: require reading cognitive moves / analytical procedures, not just descriptions.
- Workflow evaluation may be thin since the rubric was developed from skill evaluations. Mitigation: acknowledge this limitation explicitly in output.
- Test coverage checks may miss evidence if it's not in standard locations. Mitigation: also check git log for skill invocations.
