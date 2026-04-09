# Plan: Workflow Trigger Transparency

## Scope
Add explicit YAML frontmatter trigger conditions to each workflow file and strengthen CLAUDE.md's workflow list with inline trigger hints, enabling contextual workflow activation without explicit user invocation.

## Approach
Add a `triggers` field in YAML frontmatter to each workflow file listing file_types, keywords, and session_signals. Update CLAUDE.md to surface these triggers inline. Mark bug-diagnosis as implicit (Claude Code's default debugging behavior suffices). The review-fix-loop is embedded in pr-prep and gets no independent triggers.

## Steps

1. Add YAML frontmatter with `triggers` to all 10 workflow files (~10-20 lines each)
2. Update CLAUDE.md workflow list to include trigger conditions inline and note bug-diagnosis as implicit
3. Commit, push, write summary

## Trigger Design Per Workflow

| Workflow | Keywords | File Types | Session Signals |
|----------|----------|------------|-----------------|
| research-plan-implement | feature, implement, add, build, refactor, migrate | any | task touches >1 file, non-trivial change |
| divergent-design | design, architecture, choose, compare, which approach, library selection | any | 3+ viable approaches, tradeoff evaluation needed |
| task-decomposition | large task, multiple systems, parallel research | any | task touches 3+ independent subsystems |
| pr-prep | PR, pull request, review, ship, open PR | any | implementation complete, branch ready for review |
| spike | feasible, spike, prototype, proof of concept, explore, can we, how hard | any | unknown library/API, feasibility question |
| branch-strategy | branch, integration branch, dev branch, merge strategy | any | multiple concurrent feature branches |
| user-testing-workflow | usability, user test, moderator script, SUS, UX evaluation | *.tsx, *.jsx, *.vue, *.svelte, *.html, *.cs (Unity) | UI change ready for user evaluation |
| bug-diagnosis | (implicit) | any | (implicit — Claude Code's default debugging behavior) |
| codebase-onboarding | onboard, new project, orientation, unfamiliar codebase | any | first session in repo, no prior working docs |
| review-fix-loop | (none — embedded in pr-prep) | any | (none — triggered via pr-prep step 3) |

## Hypothesis Evaluation Support
The YAML frontmatter creates a structured, grep-able format. A hook that logs workflow file reads can be checked with:
```bash
grep -r "triggers:" ~/.claude/workflows/*.md
```
The hypothesis predicts at least 1 contextual activation (workflow Read event in hook logs) within 2 weeks.

## Risks
- Trigger keywords too broad could cause false activations
- Trigger keywords too narrow could prevent any activation (failing the hypothesis)
- Frontmatter format must not break existing workflow parsing
