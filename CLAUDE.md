# Global CLAUDE.md

This file applies to all projects. Project-specific CLAUDE.md files supplement this.

## Cross-project Workflows

When facing non-trivial tasks, check `~/.claude/workflows/` for applicable process docs before jumping to implementation. Key workflows:

- **research-plan-implement.md** — The default development loop. Research the codebase → write a plan → get human review → implement in a fresh session. Use for any non-trivial feature or bug fix.
- **divergent-design.md** — Structured brainstorming for architectural, library, or design decisions. Use when the first idea is probably not the best idea.
- **task-decomposition.md** — Breaking large tasks into independent sub-investigations, optionally using sub-agents for parallel research. Use when a task touches multiple subsystems.
- **pr-prep.md** — Packaging work for async review across timezones. Use before opening any PR.
- **spike.md** — Quick timeboxed exploration of a library, approach, or proof-of-concept. Use when the question is "can this work?" not "build this."
- **user-testing-workflow.md** — Planning, running, and interpreting usability tests. Use when you need to design a user test, write moderator scripts, or analyze usability findings.
- **codebase-onboarding.md** — Structured orientation for unfamiliar codebases. Use when starting a new project or returning after a long absence — before any task-specific work.

For human orchestration of multiple concurrent Claude Code sessions, see `guides/parallel-sessions.md` (not agent instructions — a reference for the developer).

When a workflow applies, follow it rather than jumping straight to implementation. Default: research-plan-implement for features, divergent-design for decisions, spike for unknowns, codebase-onboarding for new projects.

## Context Packing

Before starting any non-trivial implementation, explicitly establish context:

1. **State what you know** about the relevant parts of the codebase — which files matter, how they connect, what patterns they follow.
2. **Identify invariants** that must be preserved — existing APIs, data contracts, auth flows, caching layers, conventions.
3. **Note what to avoid** — approaches that won't work, known pitfalls, things that look right but aren't.
4. **Check for prior art** — does the codebase already solve a similar problem? If so, the new implementation should be consistent with it.

If you aren't confident about any of these, say so and read the relevant code before proceeding. Surface-level reading (signatures only) is not acceptable — read implementations.

## Session Hygiene

- **One task per session.** When a task is complete, use `/clear` or start a new session before beginning the next task. Carrying stale context into a new task degrades quality.
- **Fresh session for implementation.** If you've spent a session on research and planning, start a new session for the actual coding. Load the plan artifact; don't rely on conversational context from the planning session.
- **Context budget awareness.** Effectiveness degrades after ~10-20 minutes of autonomous work as context fills up. For longer tasks, break into steps with checkpoints rather than running continuously.

## Review Artifacts

Projects may optionally have a `docs/reviews/` directory for writing-review outputs:

- Fact-check reports from the `fact-check` skill
- Critic critiques from `cowen-critique`, `yglesias-critique`, and any future critic skills
- Verification rubrics from the `draft-review` orchestrator

These are versioned alongside the content they review. A later `draft-review` run can reference earlier fact-check findings, and re-runs overwrite prior artifacts with updated status. This parallels `docs/working/` (RPI artifacts) and `docs/decisions/` (design decisions).

## Shared Thoughts

Projects may optionally have a `docs/thoughts/` directory for working notes that persist across sessions:

- Current understanding of how subsystems work
- Open questions and known unknowns
- Gotchas and non-obvious behaviors discovered during implementation
- Patterns or conventions that aren't documented elsewhere

Unlike decision records (which are final), these are living documents. Update them when you learn something new about the codebase. Read them at the start of a session if they exist — they're context from your past selves.

## Operating Modes

The user sets the current mode by typing `/active` or `/away`.

### /active (default)

I'm at my desk. Pause before commits. Flag uncertainty. Wait for approval on plan steps before implementing.

### /away

I'm not at my desk. Commit and push after each completed step without asking. Open draft PRs without asking. Only stop for: failing tests, merge conflicts, ambiguous requirements where guessing wrong would waste significant work, or anything irreversible. Log all autonomous decisions in commit message bodies with a `Confidence` tag (high/medium/low) and a note about any choices not specified in the plan.

When the user returns to `/active`, summarize: what was committed, what decisions were made, and anything flagged for review.

### Autonomous Commit Format

When committing autonomously (in `/away` mode), include a confidence line in the commit message body:

    Confidence: high|medium|low
    Notes: [any uncertainty or decisions made without human input]

This creates a reviewable log of autonomous decisions.

## General Principles

- Commit after each logical unit of work with conventional commit messages (feat:, fix:, refactor:, test:, docs:, spike:)
- When using an unfamiliar library or language feature, add a comment explaining "why" — the human reviewers may not know the library either
- Prefer explicit over clever. Code is read more than written, and the readers may not share your context.
- When you encounter a decision worth documenting, create or update `docs/decisions/NNN-title.md` in the project
