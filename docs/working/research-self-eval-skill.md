# Research: Self-Evaluation Skill

## Scope

Build a skill that reads `docs/evaluation-rubric.md` at runtime and applies automatable dimensions to a target skill or workflow, flagging human-judgment dimensions for manual review.

## What exists

### The rubric (`docs/evaluation-rubric.md`)

9 dimensions with three-level scoring (strong / adequate / weak):

1. **Counterfactual gap** — How much worse without the tool?
2. **User-specific fit** — Relevant to actual work patterns?
3. **Condition for value** — What must be true? Is it true?
4. **Failure mode gracefulness** — Detectable vs. silent failures?
5. **Testability investment** — How hard to build meaningful tests? (Low/Medium/High)
6. **Test coverage** — What evidence exists it works?
7. **Pipeline readiness** — Standalone? Pipeline exists? Planned? Orphaned?
8. **Overlap and redundancy** — Duplicates other tools?
9. **Trigger clarity** — Can agent/user reliably know when to use this?

The rubric itself identifies which are automatable (line 185):
> "Testability investment and trigger clarity seem automatable. User-specific fit and counterfactual gap probably don't."

### Automatable vs. human-judgment dimensions

**Automatable (can assess from reading the skill file + codebase):**
- **Testability investment** — Can be assessed by analyzing the skill's input/output structure, whether outputs have checkable properties
- **Trigger clarity** — Can check: does the frontmatter `description` specify triggers? Are they specific? Do multiple skills have overlapping triggers?
- **Overlap and redundancy** — Can compare skill descriptions and cognitive moves across all skills to detect duplication
- **Test coverage** — Can check for existence of test files, example outputs in `docs/reviews/`, whether the skill has been run
- **Pipeline readiness** — Can check: does the skill have `requires` dependencies? Do orchestrators reference it? Does the orchestrator exist?

**Human-judgment required (flag for manual review):**
- **Counterfactual gap** — Requires understanding what generic prompting achieves vs. the skill
- **User-specific fit** — Explicitly subjective per rubric
- **Condition for value** — Partially automatable (can check if pipelines exist) but the "is this condition met" part requires domain knowledge
- **Failure mode gracefulness** — Requires reasoning about what "silent failure" looks like for each skill

### Prior art: existing orchestrator skills

Two orchestrators exist: `draft-review.md` (320 lines) and `code-review.md` (360 lines). Both follow the orchestrated review pattern with:
- YAML frontmatter (name, description)
- Mandatory execution rules
- Multi-stage pipeline with checkpoints
- Structured output format

**Key difference for self-eval:** This skill does NOT need sub-agents. The analysis is simpler — read the target skill, read other skills for overlap comparison, check for test files, and produce a structured report. A single-agent skill (like `fact-check.md` or `security-reviewer.md`) is the better model.

### Prior art: full-evaluation.md

`docs/reviews/full-evaluation.md` is a 37K manually-produced evaluation of all skills against all 9 dimensions. This is the output format we want to approximate for individual skills, with the key addition of explicitly marking which assessments are automated vs. flagged for human review.

### Skill file structure

All skills use YAML frontmatter with `name` and `description`. Some have `requires` blocks. The body contains instructions for the agent executing the skill.

## Invariants

- Skills are `.md` files in `skills/` with YAML frontmatter
- Workflows are `.md` files in `workflows/`
- Review artifacts go in `docs/reviews/`
- The rubric's three-level scale (strong/adequate/weak) must be preserved
- The rubric distinguishes skills vs. workflows (table at line 133)

## Gotchas

- The rubric says "a tool doesn't need to score well on every dimension" — the skill should not produce a pass/fail verdict, just structured assessment
- Workflows are harder to evaluate (rubric line 137: "test the artifacts, not the process") — the skill should handle both but acknowledge workflow limitations
- The `full-evaluation.md` example evaluates all skills at once; this skill should evaluate one target at a time for more focused analysis
