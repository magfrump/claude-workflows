---
name: self-eval
description: >
  Evaluate a skill or workflow against the project's evaluation rubric (docs/evaluation-rubric.md).
  Automatically scores dimensions that can be assessed from code and structure (testability investment,
  trigger clarity, overlap and redundancy, test coverage, pipeline readiness). Flags dimensions that
  require human judgment (counterfactual gap, user-specific fit, condition for value, failure mode
  gracefulness) with structured prompts to guide manual review. Produces a structured Markdown report.
  Use this skill when the user asks to "evaluate this skill", "assess this workflow", "run the rubric
  on X", "self-eval", or "how does X score on the rubric". Also trigger when adding a new skill or
  workflow and wanting pre-merge assessment, or during periodic reassessment of existing tools.
---

# Self-Evaluation Skill

You evaluate a single skill or workflow against the project's evaluation rubric. You produce
automated assessments where possible and structured prompts for human review where judgment
is required.

You are an evaluator, not a cheerleader. Be honest about weaknesses. A low score with clear
justification is more useful than an inflated score.

---

## Step 1: Determine the Target

The user specifies a target skill or workflow. Accept any of these forms:
- A file path: `skills/fact-check.md`, `workflows/research-plan-implement.md`
- A skill name: `fact-check`, `draft-review`, `security-reviewer`
- A workflow name: `research-plan-implement`, `divergent-design`

If given a name without a path, look in `skills/` first, then `workflows/`. If not found
in either, tell the user and stop.

Read the target file in full. Determine its type:
- **Skill** if it lives in `skills/` and has YAML frontmatter with `name` and `description`
- **Workflow** if it lives in `workflows/`

Note the type — some dimensions apply differently to skills vs. workflows (see the rubric's
"Applying the rubric: skills vs. workflows" table).

---

## Step 2: Read the Rubric

Read `docs/evaluation-rubric.md` in full. This is the authoritative source for dimension
definitions and scoring criteria. Do not rely on a cached or hardcoded version — the rubric
may have been updated since this skill was written.

Extract the 9 dimensions and their scoring guidance. Note the skills-vs-workflows table.

---

## Step 3: Gather Context

Before scoring, gather the evidence you'll need:

### 3a: Read all sibling files

- If the target is a skill: read all other files in `skills/`. For each, note the `name`,
  `description` from frontmatter, and skim the analytical approach / cognitive moves.
- If the target is a workflow: read all other files in `workflows/`.
- Also read skills if evaluating a workflow, and vice versa — overlap can cross categories.

You need this for overlap analysis and trigger clarity comparison.

### 3b: Check for test evidence

Search for evidence that the target has been tested or used:

1. Check `test/` directory for any test files referencing the target name.
2. Check `docs/reviews/` for output artifacts that match the target's expected output
   (e.g., a `fact-check-report.md` for the `fact-check` skill).
3. Check git log for commits mentioning the target name, which may indicate real usage.

```bash
git log --oneline --all --grep="<target-name>" | head -20
```

### 3c: Check pipeline references

Search orchestrator skills for references to the target:

1. Read `skills/draft-review.md` and `skills/code-review.md` (the known orchestrators).
2. Check if any skill's `requires` block references the target.
3. Check if the target's own `requires` block references other skills.

```bash
grep -rl "<target-name>" skills/ workflows/ patterns/
```

---

## Step 4: Automated Assessments

For each of these 5 dimensions, produce a score (Strong / Adequate / Weak) with a
justification based on the evidence gathered. The justification matters more than the
label — it captures *why* and makes the evaluation actionable.

### 4a: Testability Investment

Assess how much work it would take to build meaningful tests.

**Analyze:**
- Does the skill produce structured, checkable output? (Tables, verdicts, scores → lower investment)
- Can you construct a test input with known correct output? (e.g., a draft with planted errors for fact-check)
- Does quality assessment require domain expertise and subjective evaluation? (Higher investment)
- For workflows: can you test the artifacts produced, or only the process? (Workflows are inherently harder)

**Score:**
- **Strong** (Low investment): Structured output with mechanically checkable properties. Test inputs with known correct outputs are easy to construct.
- **Adequate** (Medium investment): Can check structural properties and planted-flaw detection, but quality requires human judgment.
- **Weak** (High investment): Meaningful testing requires domain expertise and subjective evaluation with no shortcut.

### 4b: Trigger Clarity

Assess whether the agent or user can reliably tell when to use this tool.

**Analyze:**
- Does the frontmatter `description` specify concrete trigger phrases or situations?
- Are the triggering situations specific enough to avoid false positives?
- Are they salient enough to avoid false negatives?
- Compare triggers against ALL other skills and workflows. Are there ambiguous overlaps
  where the user wouldn't know which to choose?
- For skills that are pipeline stages: is the orchestrator's selection logic clear?

**Score:**
- **Strong**: Specific, unambiguous triggers. No confusing overlap with other tools. User would know exactly when to reach for this.
- **Adequate**: Triggers are defined but some overlap exists with other tools, or the boundary is fuzzy in edge cases.
- **Weak**: Triggers are vague, overlap heavily with other tools, or the user would rarely think to invoke this unprompted.

### 4c: Overlap and Redundancy

Assess whether this tool duplicates work that another tool already does.

**Analyze:**
- Compare the target's analytical approach with every other skill/workflow.
- Look at cognitive moves, analysis procedures, and output format — not just topic area.
- Is the overlap structural (similar format) or substantive (similar analysis)?
- Could two tools produce substantially similar output on the same input?
- Does the target cover ground that a built-in Claude Code capability already handles?
  (e.g., code-simplifier, verification-coordinator)

**Score:**
- **Strong**: No substantive overlap. The target provides a unique analytical lens or capability.
- **Adequate**: Some overlap exists but the tools apply genuinely different analytical lenses or serve different pipeline roles.
- **Weak**: Substantial overlap with another tool. Similar output on similar input. Users would be confused about which to use.

### 4d: Test Coverage

Assess what actual evidence exists that this tool works.

**Analyze:**
- Are there automated test cases in `test/`?
- Are there example output artifacts in `docs/reviews/` or elsewhere?
- Has the tool been used on real work (evidence from git history)?
- Are there evaluation artifacts (like entries in `full-evaluation.md`)?

**Score:**
- **Strong**: Automated tests exist AND real-world usage is documented with example outputs.
- **Adequate**: Either automated tests exist OR real-world usage with example outputs — but not both.
- **Weak**: No tests written and no example outputs produced. Probationary state per rubric.

### 4e: Pipeline Readiness

Assess whether this tool has a place in an existing pipeline.

**Analyze:**
- Is the tool standalone viable (useful when invoked directly, no pipeline needed)?
- Does an orchestrator exist that composes this tool? Which one?
- Does the tool have a `requires` block indicating pipeline dependencies?
- Do other skills reference this tool in their `requires` blocks?
- If pipeline-dependent: does the pipeline actually exist, or is it planned/orphaned?

**Score:**
- **Strong**: Standalone viable AND/OR part of a functioning pipeline.
- **Adequate**: Standalone viable but designed for a pipeline that's planned (not built), or part of a pipeline but limited standalone value.
- **Weak**: Designed for a pipeline that doesn't exist and has minimal standalone value. Orphaned.

---

## Step 5: Human-Judgment Dimensions

For each of these 4 dimensions, do NOT produce a score. Instead, produce a structured
prompt that helps the human reviewer assess it efficiently. Include what you found from
automated analysis that's relevant, and highlight the specific questions the human needs
to answer.

### 5a: Counterfactual Gap

Present:
- **What the tool does**: One-paragraph summary of the target's analytical approach.
- **What generic prompting achieves**: What would happen if someone asked Claude to do
  this without the skill file? Which specific elements (cognitive moves, pipeline stages,
  structured output) would likely be missing?
- **What built-in tools cover**: Do any built-in Claude Code capabilities overlap?
- **Questions for the reviewer**:
  - How much of the skill's value comes from structure/consistency vs. unique analytical content?
  - Is the gap "the skill adds moves the user wouldn't think of" or "the skill ensures
    consistency the user would otherwise forget"?
  - Under what conditions is the gap largest?

### 5b: User-Specific Fit

Present:
- **Triggering situations**: List the specific situations that would invoke this tool.
- **Questions for the reviewer**:
  - How often does this triggering situation arise in your actual work?
  - Is the frequency increasing or decreasing?
  - Does this serve a goal you're actively pursuing?
  - Would you actually remember to reach for this tool when the situation arises?

### 5c: Condition for Value

Present:
- **Stated or inferred conditions**: What must be true for this tool to be valuable?
  (Pipeline must exist, user must work in a certain domain, certain frequency of use, etc.)
- **Automated findings**: Which conditions can be verified from the codebase? (e.g., "The
  code-review orchestrator that this skill depends on: EXISTS / DOES NOT EXIST")
- **Questions for the reviewer**:
  - Are the conditions met today?
  - If not yet met, is there a realistic path? What would need to happen?
  - Is this tool an investment pulling toward building missing infrastructure, or
    speculative inventory?

### 5d: Failure Mode Gracefulness

Present:
- **Output structure**: Describe the target's output format and what makes failures
  detectable (e.g., side-by-side claim vs. evidence, structured verdicts, confidence levels).
- **Potential silent failures**: Where could the tool produce authoritative-looking but
  wrong output? (e.g., confident analysis built on misread code, plausible-sounding
  cross-domain analogies that are structurally flawed)
- **Pipeline mitigations**: Does the pipeline architecture catch failures? (e.g., fact-check
  upstream of critics)
- **Questions for the reviewer**:
  - Based on your domain expertise, which failure modes are most likely?
  - Have you observed any silent failures in practice?
  - Is the detectable-to-silent failure ratio acceptable for your use case?

---

## Step 6: Produce the Report

Save the evaluation report to `docs/reviews/self-eval-{target-name}.md`.

Use this format:

```markdown
# Self-Evaluation: {target name}

**Target:** `{file path}` | **Type:** {Skill / Workflow} | **Evaluated:** {date}
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | {Strong/Adequate/Weak} | {1-2 sentences} |
| Trigger clarity | {Strong/Adequate/Weak} | {1-2 sentences} |
| Overlap and redundancy | {Strong/Adequate/Weak} | {1-2 sentences} |
| Test coverage | {Strong/Adequate/Weak} | {1-2 sentences} |
| Pipeline readiness | {Strong/Adequate/Weak} | {1-2 sentences} |

---

## Flagged for Human Review

### Counterfactual Gap

{Structured prompt from Step 5a}

### User-Specific Fit

{Structured prompt from Step 5b}

### Condition for Value

{Structured prompt from Step 5c}

### Failure Mode Gracefulness

{Structured prompt from Step 5d}

---

## Key Questions

{2-3 high-level questions that emerged from the evaluation — the most important things
the human reviewer should think about. Modeled after the "Key question" sections in the
rubric's example evaluations.}
```

---

## Step 7: Summarize in Chat

After saving the report, provide a brief chat summary:
- Which automated dimensions scored well and which didn't
- What the most important human-review questions are
- Link to the saved report

Keep the summary to one short paragraph plus the link. The report has the details.

---

## Important Reminders

- **Read the rubric at runtime.** Do not rely on hardcoded dimension definitions.
- **Read sibling files for overlap analysis.** Skim the analytical approach, not just names.
- **Be honest.** A "Weak" score with clear justification is more valuable than an inflated "Adequate."
- **Don't score human-judgment dimensions.** Produce prompts, not verdicts.
- **Handle both skills and workflows.** Note where the rubric applies differently.
- **One target at a time.** For evaluating all skills, run this skill repeatedly or suggest running the batch.
