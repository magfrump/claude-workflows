# Workflow Selection Tree

Pick the **first** rule that matches your situation, top to bottom.

| If... | Then use |
|---|---|
| New or unfamiliar codebase | **codebase-onboarding** |
| Quick "can this work?" question, not "build this" | **spike** |
| Bug with a known area of code | **bug-diagnosis** |
| Architectural, library, or design decision with tradeoffs | **divergent-design** |
| Task touches multiple subsystems independently | **task-decomposition** |
| Planning or running a usability test | **user-testing-workflow** |
| Managing branches for high-throughput parallel dev | **branch-strategy** |
| Non-trivial feature or fix (default) | **research-plan-implement** |

**After implementation, before merging:**

| If... | Then use |
|---|---|
| Code is ready to package for async review | **pr-prep** (includes **review-fix-loop**) |

All workflows live in `~/.claude/workflows/`. When no rule matches, default to **research-plan-implement**.

## Skill Selection

Skills are point tools — invoke them *during* a workflow, not instead of one.

| If you need to... | Then invoke |
|---|---|
| Review code changes for correctness | **code-review** (orchestrates the specialists below) |
| Audit code for security issues | **security-reviewer** |
| Check code for performance problems | **performance-reviewer** |
| Verify API consistency across endpoints | **api-consistency-reviewer** |
| Verify claims in code comments/docs match actual behavior | **code-fact-check** |
| Review a UI change for layout/accessibility issues | **ui-visual-review** |
| Decide what tests to write and where | **test-strategy** |
| Evaluate whether to upgrade a dependency | **dependency-upgrade** |
| Assess whether tech debt is worth fixing now | **tech-debt-triage** |
| Compare multiple options across multiple criteria | **matrix-analysis** |
| Fact-check a written draft for accuracy | **fact-check** |
| Get a comprehensive review of a written draft | **draft-review** (orchestrates fact-check + critics) |
| Pressure-test an argument or proposal | **cowen-critique** or **yglesias-critique** |
| Evaluate a skill/workflow against its rubric | **self-eval** |

All skills live in `~/.claude/skills/`.
