# claude-workflows

Reusable workflow definitions for AI coding agents. Works with Claude Code, Antigravity, Cursor, GitHub Copilot, Cline, and other tools that read markdown instruction files.

## Setup

### Claude Code

```bash
git clone <repo-url> ~/claude-workflows
mkdir -p ~/.claude
ln -s ~/claude-workflows/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/claude-workflows/workflows ~/.claude/workflows
```

### Antigravity / Gemini CLI

```bash
git clone <repo-url> ~/claude-workflows
mkdir -p ~/.gemini
ln -s ~/claude-workflows/GEMINI.md ~/.gemini/GEMINI.md
ln -s ~/claude-workflows/workflows ~/.gemini/workflows
```

### Cursor, Copilot, Cline, and other AGENTS.md-compatible tools

These tools read `AGENTS.md` from the project root. Symlink it into each project:

```bash
git clone <repo-url> ~/claude-workflows
# In each project:
ln -s ~/claude-workflows/AGENTS.md /path/to/project/AGENTS.md
ln -s ~/claude-workflows/workflows /path/to/project/workflows
```

Or, for tools that support user-level rules (Cursor user rules, Continue global rules), point them at the repo's workflow files directly.

### Tool-specific alternatives

Some tools have their own config directories that can also be symlinked:

| Tool | Config location | Notes |
|---|---|---|
| Cursor | `.cursor/rules/` | Symlink individual workflow files as `.md` rules |
| Windsurf | `.windsurf/rules/` | Symlink individual workflow files |
| Cline | `.clinerules/` | Symlink individual workflow files |
| Continue | `.continue/rules/` | Symlink individual workflow files |

These are alternatives to the AGENTS.md approach. Use whichever fits your setup — the workflow files are the same either way.

## Contents

### Entry points (one per tool ecosystem)
- `CLAUDE.md` — Claude Code global instructions. References workflows, plus guidance on session hygiene.
- `AGENTS.md` — Cross-tool entry point (Copilot, Cursor, Cline, etc). References workflows with `@` file syntax.
- `GEMINI.md` — Antigravity / Gemini CLI global instructions.

### Agent workflows (tool-agnostic process definitions)
- `workflows/research-plan-implement.md` — The default dev loop: research codebase, write plan, human annotates, implement
- `workflows/divergent-design.md` — Structured brainstorming: diverge, diagnose, match, tradeoff, decide
- `workflows/task-decomposition.md` — Breaking large tasks into independent sub-investigations with optional parallel dispatch
- `workflows/pr-prep.md` — Checklist for packaging work into reviewable async PRs
- `workflows/spike.md` — Timeboxed exploration of unknowns
- `workflows/branch-strategy.md` — Branch management for high-throughput feature development
- `workflows/dev-branch.md` — Integration branch workflow for testing features together

### Human guides (reference for the developer, not agent instructions)
- `guides/parallel-sessions.md` — How to orchestrate multiple concurrent agent sessions across git worktrees

### Templates
- `templates/gitattributes-snippet.txt` — `.gitattributes` rule to collapse `docs/working/` in GitHub PR diffs

## Adding workflows

1. Create a new `.md` file in the appropriate directory:
   - `workflows/` for agent-facing instructions
   - `guides/` for human-facing reference
   - `templates/` for reusable config snippets
2. Add a reference in the entry point files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) so agents know it exists
3. Commit and push

## Skills

The `.claude/skills/` directory contains Claude Code slash-command skills for draft review and fact-checking, sourced from [tomwalczak/claude-cowork-fact-checking-skills](https://github.com/tomwalczak/claude-cowork-fact-checking-skills).

## Sharing with collaborators

Collaborators clone this repo and run the symlink setup for their tool of choice. The workflow files are identical across all entry points — only the wiring differs.
