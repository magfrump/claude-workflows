# Hypothesis Backlog

Tracks hypotheses about potential improvements, evaluated against real-world evidence
before any implementation is attempted. See docs/decisions/008-hypothesis-screening-workflow.md.

## Resolution Log

- **Round 1 (2026-04-08):** Resolved 3 of 7 TRACKING hypotheses using human feedback from docs/human-author/feedback.md. Reduced TRACKING-with-no-evidence from 7 to 4. Generated 3 next-generation hypotheses (H-08, H-09, H-10).
- **Round 2 (2026-04-08):** Verified H-10 fix (commit 26e8c41). Post-fix usage.jsonl contains 261 entries across 3 event types and 8 projects. H-10 marked CONFIRMED — logging gap is closed, unblocking H-01/H-05/H-07 evidence collection.
- **Round 10 (2026-04-08):** Retired H-02, H-08, H-09 as INCONCLUSIVE-EXPIRED. Rationale: usage.jsonl was proven structurally unfit in R9, no alternative evidence source exists, and 10 rounds passed without resolution. This clears all remaining TRACKING hypotheses from the backlog that depend on unresolvable evidence sources.

| ID | Hypothesis | Evidence Sources | Created | Status | Last Checked | Evidence Summary |
|----|-----------|-----------------|---------|--------|-------------|-----------------|
| H-01 | RPI workflow is actively used in external projects (>2 per month) | usage.jsonl, git-log | 2026-04-06 | TRACKING | 2026-04-08 | Author expects contextual triggering without explicit invocation; suspects hook logging misses usage. Low confidence in current data. Blocked on logging fix. |
| H-02 | External projects that adopt workflow patterns (docs/decisions, docs/thoughts) produce more structured commits than those that don't | git-log | 2026-04-06 | **INCONCLUSIVE-EXPIRED** | 2026-04-08 | Author uses docs/thoughts and docs/decisions in all repos, so no control group exists. "Structured commits" needs operationalization. Blocked on logging + clearer metric definition. **Retired R10:** usage.jsonl proven structurally unfit (R9), no alternative evidence source, no control group available, 10 rounds without resolution. |
| H-03 | The bug-diagnosis workflow is never used outside the self-improvement loop | usage.jsonl, git-log | 2026-04-06 | **REFUTED** | 2026-04-08 | Author confirms bug-diagnosis is unused externally — but not because it failed. Direct paste-to-Claude is sufficient for bug fixes, making the workflow unnecessary overhead. The hypothesis predicted non-use and was correct, but the causal mechanism (paste sufficiency) was not anticipated. |
| H-04 | Divergent design is used in external projects when facing architectural decisions | usage.jsonl, git-log | 2026-04-06 | **CONFIRMED** | 2026-04-08 | Author reports 99% confidence. Used in meta-formalism-copilot (backend state management, picked 12th of 12 options) and web-chat (inspired epistemic feature). Author describes diverge/evaluate as "the number one best piece of prompting I use." |
| H-05 | Skills (fact-check, draft-review, simplify) are invoked more frequently than workflows in external projects | usage.jsonl | 2026-04-06 | TRACKING | 2026-04-08 | Author confirms skill use (e.g., full day of ui-visual-review on Behemoth Arsenal) but usage.jsonl has no skill data. Suspected logging bug. Blocked on logging fix. |
| H-06 | Workflow complexity (line count) correlates negatively with adoption in external projects | usage.jsonl, grep:workflows/ | 2026-04-06 | **INCONCLUSIVE** | 2026-04-08 | Author states line count is not an interesting metric; adoption correlates with value-over-manual-alternative, not brevity. However, this feedback addresses the metric's usefulness rather than directly testing the correlation. Retired — the framing is wrong, replaced by H-09. |
| H-07 | The codebase-onboarding workflow is used when starting new projects | usage.jsonl, git-log | 2026-04-06 | TRACKING | 2026-04-08 | No direct evidence yet. Blocked on logging fix (same as H-01, H-05). |

## Next-Generation Hypotheses

Informed by Round 1 resolution findings.

| ID | Hypothesis | Evidence Sources | Created | Status | Last Checked | Evidence Summary |
|----|-----------|-----------------|---------|--------|-------------|-----------------|
| H-08 | Workflows that automate multi-step processes the user would otherwise do manually (divergent-design, user-testing, RPI) have higher adoption than workflows that wrap single-step tasks (bug-diagnosis) | human-feedback, usage.jsonl | 2026-04-08 | **INCONCLUSIVE-EXPIRED** | 2026-04-08 | Derived from H-03 refutation + H-04 confirmation + H-06 feedback. Author's stated adoption driver is "value over manual alternative." **Retired R10:** usage.jsonl proven structurally unfit (R9), no alternative evidence source exists, 10 rounds without resolution. |
| H-09 | Workflow adoption correlates with reduction in manual effort (steps saved), not with workflow brevity (line count) | human-feedback, usage.jsonl | 2026-04-08 | **INCONCLUSIVE-EXPIRED** | 2026-04-08 | Replaces H-06. Author explicitly stated the value metric is enabling behavior that would otherwise require more work. Needs operationalization of "steps saved." **Retired R10:** usage.jsonl proven structurally unfit (R9), no alternative evidence source exists, 10 rounds without resolution. |
| H-10 | The usage.jsonl hook is missing >50% of actual workflow/skill invocations in external projects | usage.jsonl, human-feedback, git-log | 2026-04-08 | **CONFIRMED** | 2026-04-08 | Fix in commit 26e8c41 resolved the logging gap. Post-fix verification (2026-04-09) shows 261 entries: 182 workflow events across 8 projects, 66 valid skill events with 19 distinct names, 4 agent dispatches. Skill name extraction works for both flat files and symlinked paths. The 4 "SKILL"-named entries were pre-fix test artifacts from the audit branch itself. Hook is installed in ~/.claude/settings.json for Skill, Read, and Agent tools. H-01, H-05, H-07 evidence collection is now unblocked. |

