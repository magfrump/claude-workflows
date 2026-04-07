# Evidence Report: Self-Referential Scan

**Date**: 2026-04-06
**Config**: .evidence-config (pointing to repo root)
**Projects scanned**: 1 (wt-hypothesis-backlog-activation / claude-workflows)

## Project Signals

| Signal | Value |
|--------|-------|
| is_git | true |
| has_decisions | true (9 files) |
| has_working | true (22 files) |
| has_thoughts | false |
| CLAUDE.md workflow refs | all 9 workflows referenced |
| structured_commit_ratio | 0.75 (210/281 in 90 days) |

## Git Log Workflow Mentions (90 days)

| Workflow | Line Count | Git Mentions |
|----------|-----------|-------------|
| research-plan-implement | 204 | 31 |
| pr-prep | 151 | 26 |
| divergent-design | 90 | 16 |
| spike | 90 | 12 |
| codebase-onboarding | 145 | 9 |
| bug-diagnosis | 158 | 5 |
| user-testing-workflow | 345 | 5 |
| task-decomposition | 65 | 4 |
| branch-strategy | 153 | 4 |
| review-fix-loop | 40 | 0 |

## Hypothesis Assessments

| ID | Assessment | Notes |
|----|-----------|-------|
| H-01 | NO_EVIDENCE (for external) | 31 RPI mentions but all in source repo |
| H-02 | INSUFFICIENT_DATA | Only 1 project, no comparison possible |
| H-03 | EVIDENCE_FOR | 5 bug-diagnosis mentions, all self-improvement |
| H-04 | NO_EVIDENCE (for external) | 16 DD mentions but all in source repo |
| H-05 | NO_USAGE_DATA | No usage.jsonl found |
| H-06 | INCONCLUSIVE | Mixed: RPI (204L, 31 mentions) vs user-testing (345L, 5 mentions) but pr-prep (151L, 26 mentions) |
| H-07 | NO_EVIDENCE (for external) | 9 onboarding mentions but all in source repo |

## Pipeline Validation

The end-to-end pipeline is validated:
1. `.evidence-config` parsed correctly
2. Directory structure scanning works (decisions, working, thoughts)
3. CLAUDE.md workflow reference detection works
4. Git log workflow mention counting works
5. Structured commit ratio calculation works
6. Hypothesis-to-evidence mapping produces structured output

**Blocker for actionable results**: All 7 hypotheses concern _external_ project usage. The config needs paths to real external projects that may or may not use these workflows.

## Recommendation

Add external project directories to `.evidence-config` and re-run to get actionable evidence. The pipeline itself is ready.
