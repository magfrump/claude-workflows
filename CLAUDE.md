# Global CLAUDE.md

This file applies to all projects. Project-specific CLAUDE.md files supplement this.

## Workflow & Skill Activation

When facing non-trivial tasks, select the right workflow or skill using the decision tree below. Full process docs live in `~/.claude/workflows/` and `~/.claude/skills/`. When a workflow applies, follow it rather than jumping straight to implementation.

For human orchestration of multiple concurrent Claude Code sessions, see `guides/parallel-sessions.md`.

**How to use these workflows:** Just describe your task to Claude — it will evaluate the triggers below and automatically select the matching workflow. You can also request a specific workflow by name (e.g., "use the spike workflow for this"). If no trigger matches, Claude defaults to research-plan-implement (RPI). You don't need to memorize the table; it's here so you can see what Claude will do and why.

### Workflow decision tree

Evaluate triggers top-to-bottom. Take the **first match**; if none match, default to RPI.

| # | Trigger condition | Activate | Notes |
|---|-------------------|----------|-------|
| 1 | **New/unfamiliar codebase**, or first session in a project with no `docs/thoughts/` | `codebase-onboarding.md` | e.g., "Help me understand this repo" · Output feeds into RPI research — don't redo what onboarding already learned. |
| 2 | **Task involves a design choice** with 3+ viable approaches, or keywords: "which approach", "tradeoff", "library selection", "architecture" | `divergent-design.md` | e.g., "Should we use Postgres or DynamoDB for this?" · Often invoked as a sub-procedure within RPI (RPI step 2 signals → DD → decision feeds back into plan). DD↔RPI is the most common composition. · Within DD: `matrix-analysis` to score candidates, `what-if-analysis` to stress-test top picks, `design-space-situating` if the framing feels off. |
| 3 | **Goal is to explain, theorize, or generate hypotheses** rather than build — keywords: "why does", "what's causing", "competing theories", "explain this behavior", "hypothesize" | `divergent-design.md` (epistemic variant) | e.g., "Why is latency spiking only on Tuesdays?" · Uses DD's Epistemic Reasoning section: candidates are competing explanations, output is a ranked hypothesis list, not a decision record. |
| 4 | **Task involves building a new skill, workflow, plugin, slash command, or other reusable tool**, or keywords: "create a skill", "make a slash command", "build a workflow", "scaffold a plugin", "I need a tool that" | **Tooling discovery pass** (see below), then `skill-creator` if nothing fits | e.g., "I want a skill for fact-checking PDFs" · Past sessions have reinvented tools that already shipped (notably `skill-creator` itself). Skip only when the user has confirmed no existing tool fits. |
| 5 | **Non-trivial feature or bug fix** (touches >1 file, root cause unclear, needs codebase understanding) | `research-plan-implement.md` | e.g., "Fix the login timeout bug" or "Add CSV export to the reports page" · The default. If RPI research reveals a design fork, invoke DD inline. If research reveals root cause of a bug, skip to Fix & Verify (see debugging defaults below). |
| 6 | **Task touches multiple subsystems** and can be decomposed into independent sub-investigations | `task-decomposition.md` | e.g., "Migrate auth, billing, and notifications to the new API version" · Layer on top of RPI — each sub-task may itself follow RPI or spike. |
| 7 | **Feasibility question**: "can this work?", unfamiliar library, proof-of-concept | `spike.md` | e.g., "Can we use WebSockets for real-time sync here?" · Spike output includes an RPI seed section; load it when transitioning to implementation. |
| 8 | **Work is ready to open a PR**, or keywords: "open PR", "ready for review", "package this up" | `pr-prep.md` | e.g., "This is ready, open a PR" · Includes the review-fix loop (code-review + self-eval → fix → retest → re-review until clean). The review-fix loop is a required sub-procedure, not optional. |
| 9 | **Planning, running, or analyzing a usability test**, or keywords: "user test", "moderator script", "usability" | `user-testing-workflow.md` | e.g., "Write a moderator script for testing the onboarding flow" |
| 10 | **High-throughput multi-branch development** with async review | `branch-strategy.md` | e.g., "I have 5 features to ship this week, let's parallelize" |

### Debugging defaults

Invoke `superpowers:systematic-debugging` for the core diagnostic loop. The numbered principles below are the local extension — the 3-failed-hypothesis escape hatch with handoff-doc emission, and the bug-diagnosis-to-RPI handoff path. These principles complement systematic-debugging, which provides the loop itself.

These principles apply to **all** bug-fixing work, whether inside RPI or standalone.

1. **Reproduce first.** Before forming any hypothesis, record a concrete `Reproduction:` line at the start of the diagnosis session. It must be either (a) a runnable command (e.g., `pytest tests/foo.py::test_bar`, `curl -X POST https://api.example.com/...`) or (b) a numbered manual sequence with ≥2 steps (e.g., `1. Navigate to /login  2. Submit form with email=foo, password=bar  3. Observe 500 response`). Bare user-complaint prose ("users say login fails") is not a reproduction and is not acceptable — if that's all you have, get a concrete trigger before hypothesizing. Write the reproduction as a test if possible — it becomes your verification.
2. **Read the error.** Stack traces, error messages, and log output often point directly to the problem. Start here, not with theories.
3. **Hypothesize specifically.** State a falsifiable claim naming a specific location, mechanism, and testable outcome. Bad: "something is wrong with parsing." Good: "parseDate returns null for timezone offsets because the regex omits `+HH:MM`."
4. **Test, don't guess.** Design the smallest experiment that confirms or refutes the hypothesis. If confirmed → fix. If refuted → record what you learned, form a new hypothesis.
5. **Escape hatch at 3 failed hypotheses.** If 3+ hypotheses are refuted, stop iterating. Either you need better isolation (re-read the error, try git bisect) or you don't understand the code well enough (pivot to RPI's research phase). Before pivoting, **emit a structured handoff doc** at `docs/working/handoff-diagnosis-{bug-description}.md` containing a "What this bug isn't" section — one entry per refuted hypothesis with `tested:` (the prediction the experiment ran) and `learned:` (the region of the search space the refutation eliminates). The subsequent RPI research doc must open with this section copied verbatim, so the failed-hypothesis evidence is preserved as input rather than lost.
6. **Fix root cause, not symptom.** Keep the fix minimal. Don't refactor nearby code. One fix per diagnosis.

For worked examples of these defaults (hypothesis formation, the 3-hypothesis escape hatch, root-cause vs. symptom fixes), see `guides/debugging-examples.md`.

### Tooling discovery (before building new skills/workflows)

Triggered by row 4 of the decision tree. Before scaffolding a new skill, workflow, plugin, or slash command, run a discovery pass — past sessions reinvented tools that already shipped (notably `skill-creator` itself):

1. **Local skills**: `ls ~/.claude/skills/` and grep matching `SKILL.md` files for the problem keywords
2. **Plugin-shipped skills**: `find ~/.claude/plugins/cache -name SKILL.md` and grep
3. **Local workflows**: `ls ~/.claude/workflows/`
4. **Marketplace plugins** (not yet installed): `ls ~/.claude/plugins/marketplaces/*/` and grep their indexes

Present matching candidates to the user with three choices — **use existing**, **extend existing**, or **build new**. Lead with anything the user might not know exists; surfacing options is the point, not gatekeeping. Only proceed to `skill-creator` (or equivalent scaffolding) after the user has explicitly chosen "build new."

This gate fires before `skill-creator` regardless of how the task was entered (decision tree, direct skill invocation, or ad-hoc "let's build a skill" requests).

### Plugin-shipped skills

Plugins under `~/.claude/plugins/cache/` ship skills that auto-trigger from their own descriptions, independent of the routing tables below. The ones most relevant to routine work:

- `frontend-design:frontend-design` — *building* distinctive frontend interfaces. Pairs with `ui-visual-review` below (build → review).
- `claude-md-management:claude-md-improver` — auditing and editing CLAUDE.md files (use this when the user asks to update, audit, or improve a CLAUDE.md, including this one).
- `claude-md-management:revise-claude-md` — slash command form of the above for targeted edits.
- `skill-creator:skill-creator` — creating new skills. Reached via the Tooling-discovery gate when no existing tool fits.
- `code-simplifier` — sweeping a recently changed area for reuse, quality, and efficiency. Useful as a follow-up after `code-review` if the diff is large.

These don't need to be re-listed in the routing tables — they trigger on intent. Surface them when the local skills below don't fit and a plugin does. When both apply (e.g., a `frontend-design` build followed by `ui-visual-review`), use them together.

### Skill routing

These skills activate based on what files are being modified, not by explicit request. Apply them proactively when triggers match.

| Trigger | Skill | When |
|---------|-------|------|
| Diff touches **TSX, JSX, CSS, SCSS, Tailwind classes, Unity C# UI components**, or any visual rendering code | `ui-visual-review` | After implementation, before PR. Covers cross-resolution, overflow, sizing issues. |
| Diff touches **auth, input handling, crypto, trust boundaries, file I/O, network calls, serialization** | `security-reviewer` | During implementation or review. Design-level flaws, not linter findings. |
| **Opening or preparing a PR** (any codebase) | `code-review` | Orchestrates code-fact-check + security/performance/API-consistency critics in parallel. Integral to PR-prep's review-fix loop. |

**Composition note:** `code-review` may invoke `ui-visual-review` and `security-reviewer` as sub-critics when the diff matches their triggers. When running standalone skills, check if a full `code-review` pass would be more appropriate.

### Decision-helper skills

These skills activate based on the *type of question* being asked, not on what files are being modified. Use them as sub-procedures within workflows (especially `divergent-design` and RPI) or standalone when the matching question comes up.

| Trigger | Skill | When |
|---------|-------|------|
| **Framing a decision before choosing** — explicit request, or DD/RPI surfaces a misframing signal (constraints contradict, no candidate fits the brief) | `design-space-situating` | Places the decision on eight design-space dimensions and surfaces misframing. Output feeds DD's diagnosis step or RPI's plan. |
| **Comparing or ranking 3+ options across multiple criteria** | `matrix-analysis` | Sub-procedure of DD when the option space is wide and a scoring matrix would clarify the choice. |
| **Exploring consequences, failure modes, or second-order effects** of a proposed change | `what-if-analysis` | Sub-procedure of DD, or standalone when the question is "what could go wrong?" rather than "which option?" |
| **Multi-perspective critique** of a proposal, design, or written argument | `ai-personas-critique` | Standalone, or invoked by `draft-review` alongside `cowen-critique` / `yglesias-critique`. |
| **Dependency upgrade decision** — should we upgrade X, or how do we review a proposed bump | `dependency-upgrade` | Self-contained checklist. Use before opening or while reviewing a dep-bump PR. |
| **Tech debt prioritization** — is this worth fixing, what's the order | `tech-debt-triage` | Self-contained. Use when planning cleanup or scoping a refactor sprint. |
| **Testing plan question** — what tests to write for X, what to verify | `test-strategy` | Self-contained. Often invoked at the end of RPI's planning phase to scope verification. |

### How workflows compose

Workflows are not isolated — they hand off to each other. The most common composition paths:

- **Codebase onboarding → RPI**: Onboarding's architecture map and conventions replace the broad exploration part of RPI research, letting you scope research to the specific task.
- **RPI ↔ Divergent Design**: When RPI research surfaces 3+ viable approaches, invoke DD as a sub-procedure. DD's decision feeds back into the RPI plan. Carry RPI's constraints into DD's diagnosis step.
- **RPI ↔ Spike**: When RPI hits a feasibility question that can't be answered by reading code, pause and spike it. The spike's RPI seed section is the handoff back — load it as input to RPI research.
- **DD → Spike**: DD candidates that involve unfamiliar libraries or techniques can be validated with a spike before committing to a decision.
- **RPI → PR-prep**: Once RPI implementation is complete, PR-prep packages the work for review. PR-prep embeds the review-fix loop (see `workflows/review-fix-loop.md`).
- **`superpowers:systematic-debugging` → RPI**: After 3+ failed hypotheses, pivot to RPI's research phase. Emit `docs/working/handoff-diagnosis-{bug-description}.md` with a "What this bug isn't" section (one entry per refuted hypothesis: `tested:` / `learned:`) and open the RPI research doc with that section copied verbatim.

Each workflow's "When to pivot" section documents these handoffs in detail with specific triggers. When loading a downstream workflow, carry forward the upstream artifacts (research docs, decision records, spike seeds) rather than starting from scratch. When composing workflows, note the composition in commit messages or working docs (e.g., "DD output loaded into RPI plan") to maintain traceability.

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
- **Context budget awareness.** Effectiveness degrades after ~1-2 hours of autonomous work as context fills up. For longer tasks, break into steps with checkpoints rather than running continuously.

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

The session operates in one of two modes: **active** or **away**. Mode is session-scoped and defaults to **away**.

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

If you are uncertain which mode is active (e.g., after context compression), **default to /away** and ask the user to confirm.

### /active

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

### /away (default)

The user is not at their desk, or has not specified. Maximize progress within safe boundaries.

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

- **Commit triggers (mechanical, not vibes-based).** "Logical unit of work" defers indefinitely. Instead, commit whenever any of these is true:
  - (a) You completed a task or sub-task from an explicit plan (RPI plan checklist, decision record, todo list).
  - (b) You finished a Ralph-loop iteration that touched files — commit **before** exiting the iteration so the next iteration sees committed state in `git log` rather than a dirty working tree.
  - (c) Tests went from red to green (or you added a passing test).
  - (d) You finished a coherent file group (implementation + its tests, or a function + its callers updated).
  - (e) You're about to context-switch to a different concern, or are about to run a destructive/risky operation.
  - When in doubt, commit. Small commits are cheap; large unstaged changes are expensive to review and recover. Use conventional prefixes (feat:, fix:, refactor:, test:, docs:, spike:).
- When using an unfamiliar library or language feature, add a comment explaining "why" — the human reviewers may not know the library either
- Prefer explicit over clever. Code is read more than written, and the readers may not share your context.
- When you encounter a decision worth documenting, create or update `docs/decisions/NNN-title.md` in the project. For smaller decisions that don't warrant a full record (single clear answer, no meaningful tradeoffs), add a row to `docs/decisions/log.md` instead.
