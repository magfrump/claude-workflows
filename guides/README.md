# Guides

Reference documents for specific processes and conventions. Unlike workflows (step-by-step procedures) or skills (agent-invocable prompts), guides are consulted when you need to understand how something works or what to do in a particular situation.

- **[doc-freshness.md](doc-freshness.md)** — Lightweight heuristic for detecting stale documents using `git log` against tracked paths. Use when loading a long-lived document (onboarding doc, spike record, shared thought, review artifact) as session context.

- **[parallel-sessions.md](parallel-sessions.md)** — How to run 2–3 concurrent Claude Code sessions in separate git worktrees for maximum throughput. Use when you have independent tasks to parallelize, especially before end-of-day async handoffs. *(Human-facing guide, not agent instructions.)*

- **[post-pr-retrospective.md](post-pr-retrospective.md)** — 2–5 minute reflection after opening a PR, receiving review feedback, or merging. Use at any PR checkpoint to capture plan accuracy, skipped steps, and process improvements.

- **[self-eval-baseline.md](self-eval-baseline.md)** — How to run the self-eval skill on existing skills/workflows to produce baseline quality reports. Use when prioritizing improvement work or measuring progress after changes.

- **[skill-recovery.md](skill-recovery.md)** — Three-tier escalation for recovering from skill failures: retry with narrower scope, substitute an alternative skill, or skip and document. Use when a skill produces poor, empty, or off-target output.

- **[subtraction-checklist.md](subtraction-checklist.md)** — Manual review process for identifying removal candidates using hypothesis logs, complexity warnings, and usage reports. Use after merging an implementation branch in the self-improvement loop.

- **[validation-gates.md](validation-gates.md)** — Reference for all 7 validation gates (commit count, diff size, file scope, critical file protection, BATS tests, shellcheck, self-eval) that run before merging to main. Use when debugging a branch rejection or preparing a task for the self-improvement loop.

- **[workflow-selection.md](workflow-selection.md)** — Prescriptive decision tree for choosing the right workflow. Walk through yes/no questions to get a specific workflow recommendation. Use when you're about to start a task and aren't sure which workflow applies.
