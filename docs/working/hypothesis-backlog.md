# Hypothesis Backlog

Tracks hypotheses about potential improvements, evaluated against real-world evidence
before any implementation is attempted. See docs/decisions/008-hypothesis-screening-workflow.md.

| ID | Hypothesis | Evidence Sources | Created | Status | Last Checked | Evidence Summary |
|----|-----------|-----------------|---------|--------|-------------|-----------------|
| H-01 | RPI workflow is actively used in external projects (>2 per month) | usage.jsonl, git-log | 2026-04-06 | TRACKING | 2026-04-06 | Self-referential scan: 31 RPI git mentions in source repo (90d), but no external project data yet. Pipeline validated; needs external project configs to evaluate. |
| H-02 | External projects that adopt workflow patterns (docs/decisions, docs/thoughts) produce more structured commits than those that don't | git-log | 2026-04-06 | TRACKING | 2026-04-06 | Self-referential scan: source repo has 75% structured commits (210/281) with full workflow adoption. Needs non-adopter comparison data from external projects. |
| H-03 | The bug-diagnosis workflow is never used outside the self-improvement loop | usage.jsonl, git-log | 2026-04-06 | TRACKING | 2026-04-06 | Self-referential scan: 5 bug-diagnosis mentions found, all in the source repo (self-improvement loop). Consistent with hypothesis but not conclusive — need external project scan. |
| H-04 | Divergent design is used in external projects when facing architectural decisions | usage.jsonl, git-log | 2026-04-06 | TRACKING | 2026-04-06 | Self-referential scan: 16 divergent-design mentions, 8 decision docs in source repo. No external project data yet. |
| H-05 | Skills (fact-check, draft-review, simplify) are invoked more frequently than workflows in external projects | usage.jsonl | 2026-04-06 | TRACKING | 2026-04-06 | Self-referential scan: no usage.jsonl data available. Pipeline validated but this hypothesis requires usage log instrumentation. |
| H-06 | Workflow complexity (line count) correlates negatively with adoption in external projects | usage.jsonl, grep:workflows/ | 2026-04-06 | TRACKING | 2026-04-06 | Self-referential scan: mixed signal. RPI (204 lines) most used (31 mentions), user-testing (345 lines) least used (5). But pr-prep (151 lines) also heavily used (26). No clear negative correlation in self-referential data. |
| H-07 | The codebase-onboarding workflow is used when starting new projects | usage.jsonl, git-log | 2026-04-06 | TRACKING | 2026-04-06 | Self-referential scan: 9 onboarding mentions in source repo. Needs external project data to evaluate new-project usage pattern. |

