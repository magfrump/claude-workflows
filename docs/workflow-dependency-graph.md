# Workflow & Skill Dependency Graph

> Quick reference for how the 10 workflows and 18 skills connect.
> Generated 2026-04-08. If this doc helped orient you, note it in your session summary
> so we can track whether the dependency graph gets used during onboarding/design sessions.

## Workflow Pivots

```
codebase-onboarding ──→ research-plan-implement (RPI) ──→ pr-prep
                    └─→ divergent-design (DD)     ↑          │
                                                  │          ↓
task-decomposition ───→ RPI                    review-fix-loop
branch-strategy ──────→ RPI                       │
                                                  └─→ DD / RPI (if architectural)
bug-diagnosis ←──────→ RPI
spike ←──────────────→ RPI
spike ←──────────────→ DD

user-testing-workflow   (standalone; references cowen-critique, yglesias-critique)
```

**Central hub:** RPI. Seven of nine other workflows reference or pivot to it.

## Skill Orchestration

Two orchestrators fan out to specialist critics:

```
code-review (code orchestrator)          draft-review (prose orchestrator)
  ├─ code-fact-check  [required, S1]       ├─ fact-check  [required, S1]
  ├─ security-reviewer       [core, S2]   ├─ cowen-critique        [S2]
  ├─ performance-reviewer    [core, S2]   ├─ yglesias-critique      [S2]
  ├─ api-consistency-reviewer [core, S2]  ├─ ai-personas-critique   [S2]
  ├─ test-strategy       [contextual, S2]  └─ (any skill as critic) [S2]
  ├─ tech-debt-triage    [contextual, S2]
  ├─ dependency-upgrade  [contextual, S2]
  └─ ui-visual-review    [contextual, S2]
```

## Standalone Skills (no orchestrator required)

| Skill | Notes |
|---|---|
| self-eval | Reads all skills + workflows to evaluate a target |
| matrix-analysis | General-purpose multi-criteria comparison |
| what-if-analysis | Optionally fed by cowen/yglesias critique output |
| architecture-review | Can run standalone or under code-review |

## Cross-Cutting Dependencies

- **code-fact-check** is required upstream of: security-reviewer, performance-reviewer, api-consistency-reviewer, ui-visual-review, architecture-review
- **fact-check** is required upstream of: cowen-critique, yglesias-critique, ai-personas-critique
- **tech-debt-triage** can invoke matrix-analysis for multi-item comparison and task-decomposition workflow for parallel exploration
- **pr-prep** invokes /code-review and /self-eval skills directly

## Workflow → Skill Bridge

| Workflow | Skills invoked |
|---|---|
| pr-prep | /code-review, /self-eval |
| user-testing-workflow | references cowen-critique, yglesias-critique |
| (all others) | no direct skill invocations |
