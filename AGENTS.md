# Agent Workflows

This file provides workflow instructions for AI coding agents. It is tool-agnostic and works with any agent that reads AGENTS.md (GitHub Copilot, Cursor, Cline, and others).

## Cross-project Workflows

When facing non-trivial tasks, check `workflows/` for applicable process docs before jumping to implementation:

- **@./workflows/research-plan-implement.md** — The default development loop. Research the codebase, write a plan, get human review, implement. Use for any non-trivial feature or bug fix.
- **@./workflows/divergent-design.md** — Structured brainstorming for architectural, library, or design decisions. Use when the first idea is probably not the best idea.
- **@./workflows/task-decomposition.md** — Breaking large tasks into independent sub-investigations. Use when a task touches multiple subsystems.
- **@./workflows/pr-prep.md** — Packaging work for async review across timezones. Use before opening any PR.
- **@./workflows/spike.md** — Quick timeboxed exploration of a library, approach, or proof-of-concept. Use when the question is "can this work?" not "build this."
- **@./workflows/branch-strategy.md** — Branch management for high-throughput feature development with async review.
- **@./workflows/dev-branch.md** — Integration branch workflow for testing multiple features together before merging to main.

When a workflow applies, follow it rather than jumping straight to implementation. Default: research-plan-implement for features, divergent-design for decisions, spike for unknowns.

## Context Packing

Before starting any non-trivial implementation, explicitly establish context:

1. **State what you know** about the relevant parts of the codebase — which files matter, how they connect, what patterns they follow.
2. **Identify invariants** that must be preserved — existing APIs, data contracts, auth flows, caching layers, conventions.
3. **Note what to avoid** — approaches that won't work, known pitfalls, things that look right but aren't.
4. **Check for prior art** — does the codebase already solve a similar problem? If so, the new implementation should be consistent with it.

If you aren't confident about any of these, say so and read the relevant code before proceeding. Surface-level reading (signatures only) is not acceptable — read implementations.

## Shared Thoughts

Projects may optionally have a `docs/thoughts/` directory for working notes that persist across sessions:

- Current understanding of how subsystems work
- Open questions and known unknowns
- Gotchas and non-obvious behaviors discovered during implementation
- Patterns or conventions that aren't documented elsewhere

These are living documents. Update them when you learn something new about the codebase. Read them at the start of a session if they exist.

## General Principles

- Commit after each logical unit of work with conventional commit messages (feat:, fix:, refactor:, test:, docs:, spike:)
- When using an unfamiliar library or language feature, add a comment explaining "why"
- Prefer explicit over clever. Code is read more than written, and the readers may not share your context.
- When you encounter a decision worth documenting, create or update `docs/decisions/NNN-title.md` in the project
