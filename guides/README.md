# Guides

Reference documents for specific processes and conventions. Unlike workflows (step-by-step procedures) or skills (agent-invocable prompts), guides are consulted when you need to understand how something works or what to do in a particular situation.

- **[completion-signals.md](completion-signals.md)** — Quick-reference yes/no checks for each workflow phase. Use to confirm a phase is actually done before moving on.

- **[doc-freshness.md](doc-freshness.md)** — Lightweight heuristic for detecting stale documents using `git log` against tracked paths. Use when loading a long-lived document (onboarding doc, spike record, shared thought, review artifact) as session context.

- **[parallel-sessions.md](parallel-sessions.md)** — How to run 2–3 concurrent Claude Code sessions in separate git worktrees for maximum throughput. Use when you have independent tasks to parallelize, especially before end-of-day async handoffs. *(Human-facing guide, not agent instructions.)*

- **[post-pr-retrospective.md](post-pr-retrospective.md)** — 2–5 minute reflection after opening a PR, receiving review feedback, or merging. Use at any PR checkpoint to capture plan accuracy, skipped steps, and process improvements.

- **[pr-prep-quick-ref.md](pr-prep-quick-ref.md)** — Actionable checklist for the PR prep review-fix loop: generate reviews, triage by tier, fix, re-review, exit when clean. Quick-reference companion to `workflows/pr-prep.md`.

- **[pr-review-doc-inclusion.md](pr-review-doc-inclusion.md)** — How and when to commit review artifacts (`docs/reviews/`) to the PR branch before marking ready. Ensures async reviewers see quality evidence alongside the code.

- **[self-eval-baseline.md](self-eval-baseline.md)** — How to run the self-eval skill on existing skills/workflows to produce baseline quality reports. Use when prioritizing improvement work or measuring progress after changes.

- **[skill-recovery.md](skill-recovery.md)** — Three-tier escalation for recovering from skill failures: retry with narrower scope, substitute an alternative skill, or skip and document. Use when a skill produces poor, empty, or off-target output.

- **[subtraction-checklist.md](subtraction-checklist.md)** — Manual review process for identifying removal candidates using hypothesis logs, complexity warnings, and usage reports. Use after merging an implementation branch in the self-improvement loop.

- **[validation-gates.md](validation-gates.md)** — Reference for all 7 validation gates (commit count, diff size, file scope, critical file protection, BATS tests, shellcheck, self-eval) that run before merging to main. Use when debugging a branch rejection or preparing a task for the self-improvement loop.

- **[skill-trigger-guide.md](skill-trigger-guide.md)** — Maps common task types (code review, security audit, writing review, tech debt assessment, etc.) to the appropriate skill(s). Use when unsure which skill to invoke, or to understand how skills overlap and differ from workflows.

- **[research-scaffolds.md](research-scaffolds.md)** — Optional copy-paste templates for RPI research docs (new feature, bug investigation, refactor). Use when starting a research doc from scratch feels slow.

- **[debugging-examples.md](debugging-examples.md)** — Three worked examples grounding the debugging defaults: hypothesis formation, the 3-hypothesis escape hatch, and root-cause vs. symptom fixes.

- **[workflow-selection.md](workflow-selection.md)** — Prescriptive decision tree for choosing the right workflow given a task type. Use when unsure whether to reach for bug-diagnosis vs research-plan-implement, spike vs divergent-design, or any other workflow.

- **[cross-project-setup.md](cross-project-setup.md)** — How to adopt workflows, skills, and artifact conventions from this repo in other projects. Covers full CLAUDE.md adoption, individual skill copying with dependencies, and directory setup. Includes what to skip (repo-specific scripts and hypothesis tracking).

- **[skill-creation.md](skill-creation.md)** — How to write a new skill from scratch: required frontmatter, prompt structure conventions, CLAUDE.md routing entry, and optional test fixtures. Complements cross-project-setup by covering the path from copying existing skills to creating project-specific ones.

- **[skill-format-audit.md](skill-format-audit.md)** — Audit of the 5 most-used skills against Anthropic's skill-creator guidelines. Identifies 7 format divergences (non-standard frontmatter, description truncation, flat-file structure) with prioritized recommendations. Read-only reference; no skill files modified.
