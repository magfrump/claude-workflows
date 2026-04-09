
## Round 1

- **epistemic-dd-section**: Added epistemic reasoning variant to divergent-design.md (hypothesis generation via DD structure) and [observed]/[inferred]/[assumed] confidence-provenance tags to research-plan-implement.md's research phase — no new files, just extensions to existing workflows.
- **hypothesis-mandatory-odds**: (no summary generated)
- **format-linter-health-check**: (no summary generated)

## Round 2

- **calibration-report-script**: Created scripts/hypothesis-calibration.sh: parses hypothesis-log.md markdown table, computes overall hit rate, per-round accuracy, and prospective vs retroactive cohort split; written shellcheck-clean from line 1 to avoid the round-1 gate failure.
- **health-check-coverage-report**: Added check #9 to health-check.sh: compares skills/*.md against test/skills/*/fixtures/ and emits soft warnings for the 14 of 19 skills currently lacking test fixtures, confirming the hypothesis that at least 3 would be identified.
- **convergence-transparency-report**: (no summary generated)

## Round 3

- **hypothesis-dashboard**: Added print_hypothesis_summary to si-functions.sh that parses hypothesis-log.md, counts by status, flags approaching/overdue evaluations, and integrated it as an optional dashboard in print-round-summary.sh (suppressible via SKIP_HYPOTHESIS_DASHBOARD=1).
- **task-summary-generation-fix**: (no summary generated)

## Round 4

- **failure-analysis-automation**: (no summary generated)
- **hypothesis-auto-expiry**: (no summary generated)
- **standalone-hypothesis-eval**: Extracted hypothesis evaluation logic into `evaluate_hypotheses()` in si-functions.sh and created `scripts/evaluate-hypotheses.sh` as a standalone entry point with auto-round-detection, dry-run mode, and invocation logging for hypothesis tracking.

## Round 5

- **dry-run-mode**: (no summary generated)
- **hypothesis-quality-guide**: Added `get_hypothesis_quality_guide()` to `scripts/lib/si-functions.sh` — a prompt-injection function that outputs a hypothesis quality checklist steering toward system-internal behaviors (~70% confirm rate) and away from external-actor behaviors (~15% confirm rate), with concrete good/bad examples and a 4-point self-check.
- **gate-stats-dashboard**: Added `print_gate_stats` function to `scripts/lib/si-functions.sh` that aggregates per-gate pass/fail/skip rates from `round-history.json` and prints a summary table, integrated into `scripts/print-round-summary.sh` with a `SKIP_GATE_STATS` toggle.

## Round 6

- **dead-script-cleanup-single**: (no summary generated)
- **seed-context-enrichment**: (no summary generated)
- **feature-integration-check**: Added check 10 to health-check.sh: scans si-functions.sh for defined functions and warns about any not called from entry-point scripts (3 orphans found on first run: check_convergence_threshold, auto_expire_hypotheses, get_hypothesis_quality_guide).

## Round 7

- **collect-evidence-removal**: (no summary generated)
- **orphan-function-wiring**: (no summary generated)
- **task-summary-backfill**: (no summary generated)

## Round 8

- **plan-drift-checklist-item**: Added manual "Plan-drift check" item to PR-prep step 3a that asks the reviewer to compare the diff against the plan doc and note deviations (missing planned items, unplanned changes, wrong assumptions), with findings recorded in the PR description or as a comment.

## Round 9

- **task-decomp-briefing-patterns**: Expanded task-decomposition.md (91→126 lines) with 3 concrete sub-agent briefing examples, contradiction resolution guidance, common briefing mistakes, and structured "when NOT to decompose" heuristics including file-count and dependency-seriality thresholds.

## Round 10

- **effectiveness-framing**: Replaced line-count/section-count complexity budget checks in health-check.sh (`check_workflow_complexity`) with value-justification frontmatter validation (`check_workflow_value_justification`) across 9 workflow files. All active workflows now declare value via YAML frontmatter. This was the 10th attempt to land this change — prior attempts in R1–R9 were blocked by shellcheck failures and rebase conflicts.

## Round 11

- **debugging-worked-examples**: Added `guides/debugging-examples.md` with 3 worked scenarios grounding the CLAUDE.md debugging defaults: (a) good vs. bad hypothesis formation, (b) the 3-hypothesis escape hatch pivot, (c) root-cause vs. symptom fixes. Referenced from CLAUDE.md debugging section and indexed in `guides/README.md`.
