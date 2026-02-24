# claude-workflows

Reusable workflow definitions for Claude Code, applied globally across all projects.

## Setup

```bash
# Clone this repo
git clone <repo-url> ~/claude-workflows

# Symlink into Claude Code's global config directory
mkdir -p ~/.claude
ln -s ~/claude-workflows/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/claude-workflows/workflows ~/.claude/workflows
```

## Contents

### Agent workflows (instructions for Claude Code)
- `CLAUDE.md` — Global instructions loaded for every project. References the workflows below, plus guidance on context packing, session hygiene, and shared thoughts.
- `workflows/research-plan-implement.md` — The default dev loop: research codebase → write plan → human annotates → implement
- `workflows/divergent-design.md` — Structured brainstorming: diverge → diagnose → match → tradeoff → decide
- `workflows/task-decomposition.md` — Breaking large tasks into independent sub-investigations with optional sub-agent dispatch
- `workflows/pr-prep.md` — Checklist for packaging work into reviewable async PRs
- `workflows/spike.md` — Timeboxed exploration of unknowns

### Human guides (reference for the developer, not agent instructions)
- `guides/parallel-sessions.md` — How to orchestrate multiple concurrent Claude Code sessions across git worktrees

### Templates
- `templates/gitattributes-snippet.txt` — `.gitattributes` rule to collapse `docs/working/` in GitHub PR diffs

## Adding workflows

1. Create a new `.md` file in `workflows/`
2. Add a reference in `CLAUDE.md` so the agent knows it exists
3. Commit and push

## Sharing with collaborators

Collaborators can clone this repo and run the same symlink setup. Project-specific CLAUDE.md files supplement (not replace) the global one, so team members can share workflows while having different project configs.
