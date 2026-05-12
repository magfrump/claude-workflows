# Hypothesis Backlog

Tracks hypotheses about potential improvements, evaluated against real-world evidence
before any implementation is attempted. See docs/decisions/008-hypothesis-screening-workflow.md.

## Resolution Log

- **Round 1 (2026-04-08):** Resolved 3 of 7 TRACKING hypotheses using human feedback from docs/human-author/feedback.md. Reduced TRACKING-with-no-evidence from 7 to 4. Generated 3 next-generation hypotheses (H-08, H-09, H-10).
- **Round 2 (2026-04-08):** Verified H-10 fix (commit 26e8c41). Post-fix usage.jsonl contains 261 entries across 3 event types and 8 projects. H-10 marked CONFIRMED — logging gap is closed, unblocking H-01/H-05/H-07 evidence collection.
- **Round 5 (2026-05-12):** Reframed H-05. Original "skills invoked more than workflows" was structurally untestable because there are 21 skills vs 11 workflows — raw totals depend on category size, not per-item adoption. Replaced with a per-item rate comparison (factor K=1.5 over a W=30d window), with explicit data sources and falsification thresholds. See [r5-h05-reframe-plan.md](r5-h05-reframe-plan.md).

| ID | Hypothesis | Evidence Sources | Created | Status | Last Checked | Evidence Summary |
|----|-----------|-----------------|---------|--------|-------------|-----------------|
| H-01 | RPI workflow is actively used in external projects (>2 per month) | usage.jsonl, git-log | 2026-04-06 | TRACKING | 2026-04-08 | Author expects contextual triggering without explicit invocation; suspects hook logging misses usage. Low confidence in current data. Blocked on logging fix. |
| H-02 | External projects that adopt workflow patterns (docs/decisions, docs/thoughts) produce more structured commits than those that don't | git-log | 2026-04-06 | **INCONCLUSIVE-EXPIRED** | 2026-04-09 | Author uses these patterns in all repos, so no control group exists and the hypothesis is untestable as framed. |
| H-03 | The bug-diagnosis workflow is never used outside the self-improvement loop | usage.jsonl, git-log | 2026-04-06 | **REFUTED** | 2026-04-08 | Author confirms bug-diagnosis is unused externally — but not because it failed. Direct paste-to-Claude is sufficient for bug fixes, making the workflow unnecessary overhead. The hypothesis predicted non-use and was correct, but the causal mechanism (paste sufficiency) was not anticipated. |
| H-04 | Divergent design is used in external projects when facing architectural decisions | usage.jsonl, git-log | 2026-04-06 | **CONFIRMED** | 2026-04-08 | Author reports 99% confidence. Used in meta-formalism-copilot (backend state management, picked 12th of 12 options) and web-chat (inspired epistemic feature). Author describes diverge/evaluate as "the number one best piece of prompting I use." |
| H-05 | In external projects (project ≠ "claude-workflows"), mean per-skill invocation rate exceeds mean per-workflow invocation rate by a factor of ≥1.5 over a 30-day rolling window. Rates computed as (events in window) ÷ (count of items on disk at window end), using event ∈ {skill, workflow} from ~/.claude/logs/usage.jsonl and `ls ~/.claude/{skills,workflows}/` for denominators. | ~/.claude/logs/usage.jsonl; ~/.claude/skills/; ~/.claude/workflows/ | 2026-04-06 | TRACKING | 2026-05-12 | **Reframed 2026-05-12** — original framing ("invoked more frequently") compared raw totals, which is structurally untestable when category sizes differ. Snapshot at reframe: 2221 skill events / 21 skills = 105.8 per skill vs 1304 workflow events / 11 workflows = 118.5 per workflow. Raw totals favor skills; per-item rates favor workflows — verdict flips on the denominator, confirming the methodology problem. Falsification: CONFIRMED if ratio ≥1.5 in ≥80% of 30-day windows since logging fix (2026-04-09); REFUTED if ratio <1.5 in every window; INCONCLUSIVE otherwise. See [r5-h05-reframe-plan.md](r5-h05-reframe-plan.md). |
| H-06 | Workflow complexity (line count) correlates negatively with adoption in external projects | usage.jsonl, grep:workflows/ | 2026-04-06 | **INCONCLUSIVE** | 2026-04-08 | Author states line count is not an interesting metric; adoption correlates with value-over-manual-alternative, not brevity. However, this feedback addresses the metric's usefulness rather than directly testing the correlation. Retired — the framing is wrong, replaced by H-09. |
| H-07 | The codebase-onboarding workflow is used when starting new projects | usage.jsonl, git-log | 2026-04-06 | TRACKING | 2026-04-08 | No direct evidence yet. Blocked on logging fix (same as H-01, H-05). |

## Next-Generation Hypotheses

Informed by Round 1 resolution findings.

| ID | Hypothesis | Evidence Sources | Created | Status | Last Checked | Evidence Summary |
|----|-----------|-----------------|---------|--------|-------------|-----------------|
| H-08 | Workflows that automate multi-step processes the user would otherwise do manually (divergent-design, user-testing, RPI) have higher adoption than workflows that wrap single-step tasks (bug-diagnosis) | human-feedback, usage.jsonl | 2026-04-08 | **INCONCLUSIVE-EXPIRED** | 2026-04-09 | Derived from only two resolved hypotheses and never independently tested before project focus shifted. |
| H-09 | Workflow adoption correlates with reduction in manual effort (steps saved), not with workflow brevity (line count) | human-feedback, usage.jsonl | 2026-04-08 | **INCONCLUSIVE-EXPIRED** | 2026-04-09 | "Steps saved" metric was never operationalized and no evidence was collected before project focus shifted. |
| H-10 | The usage.jsonl hook is missing >50% of actual workflow/skill invocations in external projects | usage.jsonl, human-feedback, git-log | 2026-04-08 | **CONFIRMED** | 2026-04-08 | Fix in commit 26e8c41 resolved the logging gap. Post-fix verification (2026-04-09) shows 261 entries: 182 workflow events across 8 projects, 66 valid skill events with 19 distinct names, 4 agent dispatches. Skill name extraction works for both flat files and symlinked paths. The 4 "SKILL"-named entries were pre-fix test artifacts from the audit branch itself. Hook is installed in ~/.claude/settings.json for Skill, Read, and Agent tools. H-01, H-05, H-07 evidence collection is now unblocked. |

