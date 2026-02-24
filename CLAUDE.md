# Global CLAUDE.md

This file applies to all projects. Project-specific CLAUDE.md files supplement this.

## Cross-project Workflows

When facing non-trivial decisions or repeatable processes, check `~/.claude/workflows/` for applicable process docs before proceeding. Key workflows:

- **divergent-design.md** — Structured brainstorming for architectural, library, or design decisions. Use when the first idea is probably not the best idea.
- **pr-prep.md** — Packaging work for async review across timezones. Use before opening any PR.
- **spike.md** — Quick timeboxed exploration of a library, approach, or proof-of-concept. Use when the question is "can this work?" not "build this."

When a workflow applies, follow it rather than jumping straight to implementation. If unsure whether a workflow applies, default to using divergent-design for decisions and spike for unknowns.

## General Principles

- Commit after each logical unit of work with conventional commit messages (feat:, fix:, refactor:, test:, docs:, spike:)
- When using an unfamiliar library or language feature, add a comment explaining "why" — the human reviewers may not know the library either
- Prefer explicit over clever. Code is read more than written, and the readers may not share your context.
- When you encounter a decision worth documenting, create or update `docs/decisions/NNN-title.md` in the project
