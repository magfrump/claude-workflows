# Global CLAUDE.md

This file applies to all projects. Project-specific CLAUDE.md files supplement this.

## Workflow & Skill Activation

When facing non-trivial tasks, select the right workflow or skill using the decision tree below. Full process docs live in `~/.claude/workflows/` and `~/.claude/skills/`. When a workflow applies, follow it rather than jumping straight to implementation.

For human orchestration of multiple concurrent Claude Code sessions, see `guides/parallel-sessions.md`.

### Workflow decision tree

Evaluate triggers top-to-bottom. Take the **first match**; if none match, default to RPI.

| # | Trigger condition | Activate | Notes |
|---|-------------------|----------|-------|
| 1 | **New/unfamiliar codebase**, or first session in a project with no `docs/thoughts/` | `codebase-onboarding.md` | Output feeds into RPI research — don't redo what onboarding already learned. |
| 2 | **Task involves a design choice** with 3+ viable approaches, or keywords: "which approach", "tradeoff", "library selection", "architecture" | `divergent-design.md` | Often invoked as a sub-procedure within RPI (RPI step 2 signals → DD → decision feeds back into plan). DD↔RPI is the most common composition. |
| 3 | **Non-trivial feature or bug fix** (touches >1 file, root cause unclear, needs codebase understanding) | `research-plan-implement.md` | The default. If RPI research reveals a design fork, invoke DD inline. If research reveals root cause of a bug, skip to Fix & Verify (see debugging defaults below). |
| 4 | **Task touches multiple subsystems** and can be decomposed into independent sub-investigations | `task-decomposition.md` | Layer on top of RPI — each sub-task may itself follow RPI or spike. |
| 5 | **Feasibility question**: "can this work?", unfamiliar library, proof-of-concept | `spike.md` | Spike output includes an RPI seed section; load it when transitioning to implementation. |
| 6 | **Work is ready to open a PR**, or keywords: "open PR", "ready for review", "package this up" | `pr-prep.md` | Includes the review-fix loop (code-review + self-eval → fix → retest → re-review until clean). The review-fix loop is a required sub-procedure, not optional. |
| 7 | **Planning, running, or analyzing a usability test**, or keywords: "user test", "moderator script", "usability" | `user-testing-workflow.md` | |
| 8 | **High-throughput multi-branch development** with async review | `branch-strategy.md` | |

### Debugging defaults (absorbed from bug-diagnosis)

These principles apply to **all** bug-fixing work, whether inside RPI or standalone. The standalone `bug-diagnosis.md` workflow is deprecated — use these defaults directly.

1. **Reproduce first.** Confirm you can trigger the bug reliably before diagnosing. Write the reproduction as a test if possible — it becomes your verification.
2. **Read the error.** Stack traces, error messages, and log output often point directly to the problem. Start here, not with theories.
3. **Hypothesize specifically.** State a falsifiable claim naming a specific location, mechanism, and testable outcome. Bad: "something is wrong with parsing." Good: "parseDate returns null for timezone offsets because the regex omits `+HH:MM`."
4. **Test, don't guess.** Design the smallest experiment that confirms or refutes the hypothesis. If confirmed → fix. If refuted → record what you learned, form a new hypothesis.
5. **Escape hatch at 3 failed hypotheses.** If 3+ hypotheses are refuted, stop iterating. Either you need better isolation (re-read the error, try git bisect) or you don't understand the code well enough (pivot to RPI's research phase — your failed hypotheses document what the bug *isn't*).
6. **Fix root cause, not symptom.** Keep the fix minimal. Don't refactor nearby code. One fix per diagnosis.

For complex bugs that need a formal diagnosis log, the template and full process remain available in `workflows/bug-diagnosis.md`.

### Skill routing

These skills activate based on what files are being modified, not by explicit request. Apply them proactively when triggers match.

| Trigger | Skill | When |
|---------|-------|------|
| Diff touches **TSX, JSX, CSS, SCSS, Tailwind classes, Unity C# UI components**, or any visual rendering code | `ui-visual-review` | After implementation, before PR. Covers cross-resolution, overflow, sizing issues. |
| Diff touches **auth, input handling, crypto, trust boundaries, file I/O, network calls, serialization** | `security-reviewer` | During implementation or review. Design-level flaws, not linter findings. |
| **Opening or preparing a PR** (any codebase) | `code-review` | Orchestrates code-fact-check + security/performance/API-consistency critics in parallel. Integral to PR-prep's review-fix loop. |

**Composition note:** `code-review` may invoke `ui-visual-review` and `security-reviewer` as sub-critics when the diff matches their triggers. When running standalone skills, check if a full `code-review` pass would be more appropriate.

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

Long-lived documents (onboarding docs, spike records, shared thoughts) support **freshness tracking** via `Last verified` and `Relevant paths` fields. Before relying on these documents, check whether tracked paths have changed using `git log --since`. See `guides/doc-freshness.md` for the full heuristic.

## Operating Modes

The session operates in one of two modes: **active** or **away**. Mode is session-scoped and defaults to **active**.

### How to switch modes

The user signals a mode switch by including it in a message. All of these are equivalent:
- `You are in /away mode.` (preamble style — most reliable)
- `/away` or `/active` (standalone — may be intercepted by Claude Code's command parser; if so, include in a sentence instead)
- `away mode` or `active mode` (plain text)

**Platform note:** Claude Code reserves the `/` prefix for built-in commands. If `/away` or `/active` as a standalone message produces an error or no response, the user should use preamble style or plain text instead.

### Acknowledgment protocol

When you detect a mode switch, you MUST respond with:
1. **Explicit confirmation**: "Switching to /away mode." or "Switching to /active mode."
2. **Key behavior change**: One sentence stating the most important difference (e.g., "I will commit and push autonomously after each completed step.")

If you are uncertain which mode is active (e.g., after context compression), **default to /active** and ask the user to confirm.

### /active (default)

The user is at their desk and available for approval.

**Require user approval before:**
- Creating git commits
- Pushing to remote
- Creating or updating pull requests
- Proceeding past plan review gates (RPI step 4)
- Making architectural or design decisions not covered by the plan

**Do autonomously (no approval needed):**
- Reading files, searching code, running non-destructive commands
- Editing files (the user reviews via tool approval)
- Running tests, linters, and build checks
- Writing research docs, plans, and working documents

**Flag uncertainty:** When you encounter ambiguity, state it explicitly and wait for guidance rather than guessing.

### /away

The user is not at their desk. Maximize progress within safe boundaries.

**Do autonomously (no approval needed):**
- Everything in the /active autonomous list, plus:
- Creating git commits (use the autonomous commit format below)
- Pushing to remote after each completed logical step
- Opening draft PRs
- Making judgment calls on ambiguous-but-low-risk implementation details

**Still require user approval (regardless of mode):**
- Force-push, `git reset --hard`, deleting branches, dropping database tables
- Any destructive or irreversible operation
- Decisions where guessing wrong would waste significant work

**Stop and wait for the user when:**
- Tests fail and the fix is not obvious
- Merge conflicts arise
- Requirements are ambiguous AND the wrong guess would waste significant effort
- Anything irreversible not covered above

Log all autonomous decisions in commit message bodies with a `Confidence` tag (high/medium/low) and a note about any choices not specified in the plan.

### Returning to /active

When the user switches back to /active, respond with a summary:
- What was committed (list commits with one-line descriptions)
- What decisions were made autonomously and their confidence level
- Anything flagged for review or requiring follow-up

### Autonomous Commit Format

When committing autonomously (in /away mode), include a confidence line in the commit message body:

    Confidence: high|medium|low
    Notes: [any uncertainty or decisions made without human input]

This creates a reviewable log of autonomous decisions.

## General Principles

- Commit after each logical unit of work with conventional commit messages (feat:, fix:, refactor:, test:, docs:, spike:)
- When using an unfamiliar library or language feature, add a comment explaining "why" — the human reviewers may not know the library either
- Prefer explicit over clever. Code is read more than written, and the readers may not share your context.
- When you encounter a decision worth documenting, create or update `docs/decisions/NNN-title.md` in the project. For smaller decisions that don't warrant a full record (single clear answer, no meaningful tradeoffs), add a row to `docs/decisions/log.md` instead.
