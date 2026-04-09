# Hypothesis Backlog

Tracks hypotheses about potential improvements, evaluated against real-world evidence
before any implementation is attempted. See docs/decisions/008-hypothesis-screening-workflow.md.

## Resolution Log

- **Round 1 (2026-04-08):** Resolved 3 of 7 TRACKING hypotheses using human feedback from docs/human-author/feedback.md. Reduced TRACKING-with-no-evidence from 7 to 4. Generated 3 next-generation hypotheses (H-08, H-09, H-10).

| ID | Hypothesis | Evidence Sources | Created | Status | Last Checked | Evidence Summary |
|----|-----------|-----------------|---------|--------|-------------|-----------------|
| H-01 | RPI workflow is actively used in external projects (>2 per month) | usage.jsonl, git-log | 2026-04-06 | TRACKING | 2026-04-08 | Author expects contextual triggering without explicit invocation; suspects hook logging misses usage. Low confidence in current data. Blocked on logging fix. |
| H-02 | External projects that adopt workflow patterns (docs/decisions, docs/thoughts) produce more structured commits than those that don't | git-log | 2026-04-06 | TRACKING | 2026-04-08 | Author uses docs/thoughts and docs/decisions in all repos, so no control group exists. "Structured commits" needs operationalization. Blocked on logging + clearer metric definition. |
| H-03 | The bug-diagnosis workflow is never used outside the self-improvement loop | usage.jsonl, git-log | 2026-04-06 | **REFUTED** | 2026-04-08 | Author confirms bug-diagnosis is unused externally — but not because it failed. Direct paste-to-Claude is sufficient for bug fixes, making the workflow unnecessary overhead. The hypothesis predicted non-use and was correct, but the causal mechanism (paste sufficiency) was not anticipated. |
| H-04 | Divergent design is used in external projects when facing architectural decisions | usage.jsonl, git-log | 2026-04-06 | **CONFIRMED** | 2026-04-08 | Author reports 99% confidence. Used in meta-formalism-copilot (backend state management, picked 12th of 12 options) and web-chat (inspired epistemic feature). Author describes diverge/evaluate as "the number one best piece of prompting I use." |
| H-05 | Skills (fact-check, draft-review, simplify) are invoked more frequently than workflows in external projects | usage.jsonl | 2026-04-06 | TRACKING | 2026-04-08 | Author confirms skill use (e.g., full day of ui-visual-review on Behemoth Arsenal) but usage.jsonl has no skill data. Suspected logging bug. Blocked on logging fix. |
| H-06 | Workflow complexity (line count) correlates negatively with adoption in external projects | usage.jsonl, grep:workflows/ | 2026-04-06 | **INCONCLUSIVE** | 2026-04-08 | Author states line count is not an interesting metric; adoption correlates with value-over-manual-alternative, not brevity. However, this feedback addresses the metric's usefulness rather than directly testing the correlation. Retired — the framing is wrong, replaced by H-09. |
| H-07 | The codebase-onboarding workflow is used when starting new projects | usage.jsonl, git-log | 2026-04-06 | TRACKING | 2026-04-08 | No direct evidence yet. Blocked on logging fix (same as H-01, H-05). |

## Next-Generation Hypotheses

Informed by Round 1 resolution findings.

| ID | Hypothesis | Evidence Sources | Created | Status | Last Checked | Evidence Summary |
|----|-----------|-----------------|---------|--------|-------------|-----------------|
| H-08 | Workflows that automate multi-step processes the user would otherwise do manually (divergent-design, user-testing, RPI) have higher adoption than workflows that wrap single-step tasks (bug-diagnosis) | human-feedback, usage.jsonl | 2026-04-08 | TRACKING | — | Derived from H-03 refutation + H-04 confirmation + H-06 feedback. Author's stated adoption driver is "value over manual alternative." |
| H-09 | Workflow adoption correlates with reduction in manual effort (steps saved), not with workflow brevity (line count) | human-feedback, usage.jsonl | 2026-04-08 | TRACKING | — | Replaces H-06. Author explicitly stated the value metric is enabling behavior that would otherwise require more work. Needs operationalization of "steps saved." |
| H-10 | The usage.jsonl hook is missing >50% of actual workflow/skill invocations in external projects | usage.jsonl, human-feedback, git-log | 2026-04-08 | TRACKING | — | Author reports using divergent-design and ui-visual-review extensively, but usage.jsonl shows no corresponding entries. Resolving this is a prerequisite for evaluating H-01, H-05, H-07. |

