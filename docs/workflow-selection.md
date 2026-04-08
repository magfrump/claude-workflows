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
