# claude-workflows

Reusable workflow definitions for AI coding agents. Works with Claude Code, Antigravity, Cursor, GitHub Copilot, Cline, and other tools that read markdown instruction files.

## Setup

### Claude Code

```bash
git clone <repo-url> ~/claude-workflows
mkdir -p ~/.claude ~/.claude/hooks

# Entry point + content directories (symlinks: repo edits are live immediately)
ln -s ~/claude-workflows/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/claude-workflows/workflows ~/.claude/workflows
ln -s ~/claude-workflows/skills    ~/.claude/skills
ln -s ~/claude-workflows/patterns  ~/.claude/patterns
ln -s ~/claude-workflows/guides    ~/.claude/guides

# Logging and routing hooks (symlinks, same convention)
for h in log-usage.sh log-usage-post.sh dd-routing-reminder.sh \
         batch-feedback-routing-reminder.sh claude-config-audit.sh; do
  ln -s ~/claude-workflows/hooks/$h ~/.claude/hooks/$h
done

# Security + permission hooks (deliberate COPIES, not symlinks — see
# docs/working/wire-security-hooks.md for why; re-copy after repo changes)
cp ~/claude-workflows/hooks/guard-trusted-writes.py \
   ~/claude-workflows/hooks/web-taint-mark.py \
   ~/claude-workflows/hooks/auto-approve-allowed-commands.sh ~/.claude/hooks/
```

Hooks are inert until wired into `~/.claude/settings.json` (guarded,
not repo-tracked). The wiring docs hold the exact JSON to paste:

- `docs/working/wire-security-hooks.md` — guard-trusted-writes (PreToolUse,
  matcher must include `Bash`) + web-taint-mark (PostToolUse), plus the
  2026-07-09 permissions/sandbox hardening applied alongside them
- `docs/working/wire-claude-config-audit.md` — post-edit security audit of
  trusted-policy files
- `docs/working/wire-batch-feedback-reminder.md` — batch fan-out routing
  reminder (dd-routing-reminder follows the same pattern)

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

## Configuration outside this repo

The repo is the versioned half of the setup. These files live outside it and
are referenced by the hooks and instructions above — if you rebuild the
machine, they must be recreated by hand:

| File | Role | Notes |
|---|---|---|
| `~/.claude/settings.json` | Permissions allow/deny lists, hook wiring, sandbox config | Guarded and deliberately not repo-tracked; changes are recorded prose-style in the `docs/working/wire-*.md` docs |
| `~/private_reviews/claude_config_audit.py` | Trusted-policy security auditor run by `claude-config-audit.sh` | Deliberately kept outside the repo so a policy-file attacker can't also edit the scanner; see `guides/claude-config-security-checkup.md` |
| `~/.claude/hooks/guard-trusted-writes.py`, `web-taint-mark.py`, `auto-approve-allowed-commands.sh` | Deployed copies of the repo's security/permission hooks | Copies by design; re-copy deliberately after repo changes |
| `/tmp/cc-web-taint/` | Runtime session-taint markers (0700) | Created on demand; cleared on reboot, which is fine — taint is per-session |
| `~/.claude/logs/usage.jsonl` | Output of the usage-logging hooks | Created on demand |
| `C:\Program Files\ClaudeCode\managed-settings.json` (`{}`) + `managed-settings.d\` | WSL2 only: mount points bwrap needs for the Bash sandbox | Create as Windows admin, or **every** Bash call fails at sandbox setup; see `docs/working/wire-security-hooks.md` |

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
- `workflows/codebase-onboarding.md` — Structured orientation for unfamiliar codebases
- `workflows/review-fix-loop.md` — The review → fix → retest → re-review sub-procedure embedded in pr-prep

### Patterns (shared structural patterns across workflows)
- `patterns/orchestrated-review.md` — The decompose → parallel dispatch → synthesize → gate pattern, instantiated by task decomposition, divergent design, and PR prep
- `patterns/requesting-user-input.md` — When and how workflows pause for human decisions

### Guides
`guides/` holds ~20 reference documents (process conventions, debugging examples, skill authoring, security checkup, parallel sessions). See `guides/README.md` for the maintained index — a test (`test/guide-index-sync.bats`) keeps it in sync.

### Hooks (Claude Code hooks; wiring under "Setup" above)
- `hooks/log-usage.sh` / `hooks/log-usage-post.sh` — Log skill/agent invocations and workflow file reads to `~/.claude/logs/usage.jsonl` (shared code in `hooks/lib/`)
- `hooks/dd-routing-reminder.sh` — `UserPromptSubmit` hook nudging explicit comparison/decision prompts toward the divergent-design workflow (non-blocking)
- `hooks/batch-feedback-routing-reminder.sh` — `UserPromptSubmit` hook nudging multi-item prompts (batches of feedback) toward parallel-subagent fan-out per decision-tree row 2 (non-blocking); wiring instructions in `docs/working/wire-batch-feedback-reminder.md`
- `hooks/claude-config-audit.sh` — `PostToolUse` security audit of edited trusted-policy files via the external auditor (see `guides/claude-config-security-checkup.md`)
- `hooks/guard-trusted-writes.py` — `PreToolUse` gate on writes to trusted-policy files: hard-deny on Bash write primitives targeting protected config paths, ask on soft policy paths when the session is web-tainted
- `hooks/web-taint-mark.py` — `PostToolUse` marker that records the session ingested web content, feeding the guard's taint check
- `hooks/auto-approve-allowed-commands.sh` — `PreToolUse` Bash hook that auto-approves piped/compound commands when every component matches an allowlisted prefix (Claude Code's native prefix matching doesn't handle pipes); depends on `shfmt` + `jq`

### Tests
Bats suites under `test/` cover hooks (`test/hooks/`), skill contracts (`test/skills/`), scripts (`test/scripts/`), and repo invariants (cross-reference integrity, guide-index sync, workflow required sections). Run a suite with `bats <file>`.

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

`skills/` holds 26 Claude Code skills (symlinked to `~/.claude/skills` by the setup above): review orchestrators (`code-review`, `draft-review`) and their critics (security, performance, API-consistency, architecture, fact-checking), decision helpers (`matrix-analysis`, `what-if-analysis`, `design-space-situating`, `pre-mortem`), persona critiques (`cowen-critique`, `yglesias-critique`, `ai-personas-critique`, business-plan critics), and process skills (`self-eval`, `test-strategy`, `tech-debt-triage`, `dependency-upgrade`, `ui-visual-review`, `divergent-design` router). Each skill's `SKILL.md` frontmatter declares its own triggers. The draft-review/fact-check family was originally seeded from [tomwalczak/claude-cowork-fact-checking-skills](https://github.com/tomwalczak/claude-cowork-fact-checking-skills) and has since diverged.

## Sharing with collaborators

Collaborators clone this repo and run the symlink setup for their tool of choice. The workflow files are identical across all entry points — only the wiring differs.
