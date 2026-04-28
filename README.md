# claude-workflows

Reusable workflow definitions for AI coding agents. Works with Claude Code, Antigravity, Cursor, GitHub Copilot, Cline, and other tools that read markdown instruction files.

## Setup

### Claude Code

```bash
git clone <repo-url> ~/claude-workflows
mkdir -p ~/.claude ~/.claude/hooks
ln -s ~/claude-workflows/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/claude-workflows/workflows ~/.claude/workflows
ln -s ~/claude-workflows/skills    ~/.claude/skills
ln -s ~/claude-workflows/patterns  ~/.claude/patterns
ln -s ~/claude-workflows/guides    ~/.claude/guides
ln -s ~/claude-workflows/hooks/log-usage.sh ~/.claude/hooks/log-usage.sh
```

### Gemini CLI (Linux/macOS)

```bash
git clone <repo-url> ~/claude-workflows
mkdir -p ~/.gemini
ln -s ~/claude-workflows/GEMINI.md  ~/.gemini/GEMINI.md
ln -s ~/claude-workflows/workflows  ~/.gemini/workflows
ln -s ~/claude-workflows/skills     ~/.gemini/skills
ln -s ~/claude-workflows/patterns   ~/.gemini/patterns
ln -s ~/claude-workflows/guides     ~/.gemini/guides
```

### Antigravity (built-in agent panel)

The agent panel reads `~/.gemini/GEMINI.md` and the directories alongside it. Where `~` lives depends on where Antigravity itself is running:

- **Antigravity on Linux/macOS** — use the Gemini CLI setup above.
- **Antigravity on Windows (including WSL users)** — Antigravity is a Windows process even when your repo lives in WSL, so the links must be created on the Windows side at `%USERPROFILE%\.gemini\`. Symlinks to `\\wsl.localhost\<distro>\...` UNC targets need either Windows **Developer Mode** enabled (Settings → Privacy & security → For developers) or an elevated shell. Run from elevated PowerShell:

  ```powershell
  $base = "$env:USERPROFILE\.gemini"
  $src  = '\\wsl.localhost\Ubuntu\home\<you>\claude-workflows'   # adjust distro + user
  New-Item -ItemType Directory -Path $base -Force | Out-Null
  foreach ($n in 'GEMINI.md','workflows','skills','patterns','guides') {
      $link = Join-Path $base $n
      if (Test-Path -LiteralPath $link) {
          $i = Get-Item -LiteralPath $link -Force
          if ($i.PSIsContainer) { [System.IO.Directory]::Delete($link) }
          else { [System.IO.File]::Delete($link) }
      }
      New-Item -ItemType SymbolicLink -Path $link -Target (Join-Path $src $n) | Out-Null
  }
  ```

  Single-quote the target paths — double-quoted strings in PowerShell may strip a leading backslash and break UNC resolution. Antigravity reads through the WSL 9P share, so WSL must be running for the panel to see workflow content.

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
- `workflows/branch-strategy.md` — Branch management and dev integration branch workflow for high-throughput feature development
- `workflows/user-testing-workflow.md` — Planning, running, and interpreting usability tests (HCI-grounded, small-team adapted)

### Patterns (shared structural patterns across workflows)
- `patterns/orchestrated-review.md` — The decompose → parallel dispatch → synthesize → gate pattern, instantiated by task decomposition, divergent design, and PR prep

### Human guides (reference for the developer, not agent instructions)
- `guides/parallel-sessions.md` — How to orchestrate multiple concurrent agent sessions across git worktrees

### Hooks (Claude Code PreToolUse hooks)
- `hooks/log-usage.sh` — Logs skill invocations and workflow file reads to `~/.claude/logs/usage.jsonl` for usage analytics

### Tests
- `test/hooks/log-usage.bats` — Bats test suite for the usage-logging hook

### Templates
- `templates/gitattributes-snippet.txt` — `.gitattributes` rule to collapse `docs/working/` in GitHub PR diffs

## Adding workflows

1. Create a new `.md` file in the appropriate directory:
   - `workflows/` for agent-facing instructions
   - `guides/` for human-facing reference
   - `patterns/` for shared structural patterns that multiple workflows instantiate
   - `templates/` for reusable config snippets
2. Add a reference in the entry point files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) so agents know it exists
3. Commit and push

## Skills

The `.claude/skills/` directory contains Claude Code slash-command skills for draft review and fact-checking, sourced from [tomwalczak/claude-cowork-fact-checking-skills](https://github.com/tomwalczak/claude-cowork-fact-checking-skills).

## Sharing with collaborators

Collaborators clone this repo and run the symlink setup for their tool of choice. The workflow files are identical across all entry points — only the wiring differs.
