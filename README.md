# claude-workflows

Reusable workflow definitions for AI coding agents. Works with Claude Code, Antigravity, Cursor, GitHub Copilot, Cline, and other tools that read markdown instruction files.

## Setup

### Claude Code

```bash
git clone <repo-url> ~/claude-workflows
cd ~/claude-workflows
./devcontainer-config/install.sh      # run it again after every pull or commit
```

`install.sh` offers two targets in turn, each with its own review diff and its
own `[y/N]`. The first is the `cc-isolated` devcontainer config: decline it if you
don't use the devcontainer. The second copies `global-instructions/CLAUDE.md`,
`skills`, `workflows`, `guides`, `patterns`, `hooks` and `scripts` into
`~/.claude` (or `$CLAUDE_CONFIG_DIR` if you set it). They are **copies, not
symlinks**: an edit to the checkout, by you or by an agent, does nothing until you
rerun `install.sh`, read the diff and answer y (decision 037). Only **committed**
content is installed: uncommitted changes under those paths are listed as NOT
included, and git-ignored files are never copied. The `~/.claude`
target only installs for a human at a terminal. It is skipped with `--yes`, from a
script with no TTY, and inside a Claude Code session. `install.sh --help` has the
details.

**Migrating from the old symlink install.** Close your Claude Code sessions, then
run `install.sh`. Its `~/.claude` review lists every symlink it will replace
(`REPLACE symlink … with a copy`) and every file or link in those directories that
the repo doesn't have (`MOVE to backup`, `MOVE link … to backup`). Check any line marked `WIRED in settings` before you
answer y: that hook is referenced from your `settings.json` and will stop running.
Everything replaced, including the old links, is moved to
`~/.claude/.claude-workflows-backup/<UTC stamp>/`. Delete that directory when you're
satisfied. Your `settings.json`, memory, projects and logs are never touched.

Hooks are inert until wired into `~/.claude/settings.json` (guarded,
not repo-tracked). `hooks/wiring.json` is the canonical wiring (hooks plus the
`permissions.deny` rules the guard depends on); the devcontainer merges it
automatically, and on a bare host you merge it by hand —
see [`guides/bare-host-hook-wiring.md`](guides/bare-host-hook-wiring.md) for the
procedure, the settings hardening `wiring.json` does not carry, the WSL2
prerequisite, and verification steps.

### Cursor, Copilot, Cline, and other AGENTS.md-compatible tools

These tools read `AGENTS.md` from the project root. Symlink it into each project:

```bash
git clone <repo-url> ~/claude-workflows
# In each project:
ln -s ~/claude-workflows/AGENTS.md /path/to/project/AGENTS.md
ln -s ~/claude-workflows/workflows /path/to/project/workflows
ln -s ~/claude-workflows/skills    /path/to/project/skills
ln -s ~/claude-workflows/patterns  /path/to/project/patterns
ln -s ~/claude-workflows/guides    /path/to/project/guides
ln -s ~/claude-workflows/global-instructions /path/to/project/global-instructions
```

AGENTS.md references files in all of these (for example the Debugging defaults
in `global-instructions/CLAUDE.md`, the skills table, and
`guides/doc-freshness.md`), so link them all. If a project already has its own
directory with one of these names, skip that link and point the tool at the
repo copy instead.

These per-project symlinks are unaffected by the `~/.claude` copy install. They are
project wiring for other tools, not global instruction files.

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
| `~/.claude/settings.json` | Permissions allow/deny lists, hook wiring, sandbox config | Guarded and deliberately not repo-tracked; the hook wiring and deny rules come from `hooks/wiring.json`, and the remaining manual hardening is recorded in `guides/bare-host-hook-wiring.md` |
| ~~`~/private_reviews/claude_config_audit.py`~~ | Trusted-policy security auditor run by `claude-config-audit.sh` | **Now tracked at `scripts/claude_config_audit.py`** (decision 023 amendment A) — the image payload is root-owned `0555`, which keeps a policy-file attacker away from the scanner more firmly than the old location did. The `~/private_reviews/` path is still honored as a fallback for bare-host installs; see `guides/claude-config-security-checkup.md` |
| `~/.claude/{CLAUDE.md,skills,workflows,guides,patterns,hooks,scripts}` | Installed copies of the repo's global files | Written only by `install.sh` after a reviewed y (decision 037). Provenance is in `~/.claude/.claude-workflows-manifest`, and replaced entries are in `~/.claude/.claude-workflows-backup/` |
| `/tmp/cc-web-taint/` | Runtime session-taint markers (0700) | Created on demand; cleared on reboot, which is fine — taint is per-session |
| `~/.claude/logs/usage.jsonl` | Output of the usage-logging hooks | Created on demand |
| `C:\Program Files\ClaudeCode\managed-settings.json` (`{}`) + `managed-settings.d\` | WSL2 only: mount points bwrap needs for the Bash sandbox | Create as Windows admin, or **every** Bash call fails at sandbox setup; see `guides/bare-host-hook-wiring.md` |

## Contents

### Entry points (one per tool ecosystem)
- `global-instructions/CLAUDE.md` — Claude Code global instructions. References workflows, plus guidance on session hygiene. It sits in its own directory rather than the repo root so that a session working in *this* repo does not load it twice — once from `~/.claude` and once as the project's own instructions.
- `AGENTS.md` — Cross-tool entry point (Copilot, Cursor, Cline, etc). References workflows with `@` file syntax.
- `GEMINI.md` — Antigravity / Gemini CLI global instructions. No install recipe ships for it (decision 037).

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
- `workflows/parallel-worktrees.md` — Batch fan-out: split 2+ independent tasks, implement each in an isolated git worktree in parallel, merge back

### Patterns (shared structural patterns across workflows)
- `patterns/orchestrated-review.md` — The decompose → parallel dispatch → synthesize → gate pattern, instantiated by task decomposition, divergent design, and PR prep
- `patterns/requesting-user-input.md` — When and how workflows pause for human decisions

### Guides
`guides/` holds ~20 reference documents (process conventions, debugging examples, skill authoring, security checkup, parallel sessions). See `guides/README.md` for the maintained index — a test (`test/guide-index-sync.bats`) keeps it in sync.

### Hooks (Claude Code hooks; wiring under "Setup" above)
- `hooks/log-usage.sh` / `hooks/log-usage-post.sh` — Log skill/agent invocations and workflow file reads to `~/.claude/logs/usage.jsonl` (shared code in `hooks/lib/`)
- `hooks/dd-routing-reminder.sh` — `UserPromptSubmit` hook nudging explicit comparison/decision prompts toward the divergent-design workflow (non-blocking)
- `hooks/batch-feedback-routing-reminder.sh` — `UserPromptSubmit` hook nudging multi-item prompts (batches of feedback) toward parallel-subagent fan-out per decision-tree row 2 (non-blocking); wired from `hooks/wiring.json` (bare host: `guides/bare-host-hook-wiring.md`)
- `hooks/claude-config-audit.sh` — `PostToolUse` security audit of edited trusted-policy files via the external auditor (see `guides/claude-config-security-checkup.md`)
- `hooks/guard-trusted-writes.py` — `PreToolUse` gate on writes to trusted-policy files: hard-deny on Bash write primitives targeting protected config paths, ask on soft policy paths when the session is web-tainted
- `hooks/web-taint-mark.py` — `PostToolUse` marker that records the session ingested web content, feeding the guard's taint check
- `hooks/live-verify-gate.sh` — `PreToolUse` Bash gate that blocks a `git commit` touching a cc-isolated enforcement file unless the message carries a `Live-verified:` trailer
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
2. Add a reference in the entry point files (`global-instructions/CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) so agents know it exists
3. Commit and push

## Skills

`skills/` holds 26 Claude Code skills (copied into `~/.claude/skills` by `install.sh`, see Setup): review orchestrators (`code-review`, `draft-review`) and their critics (security, performance, API-consistency, architecture, fact-checking), decision helpers (`matrix-analysis`, `what-if-analysis`, `design-space-situating`, `pre-mortem`), persona critiques (`cowen-critique`, `yglesias-critique`, `ai-personas-critique`, business-plan critics), and process skills (`self-eval`, `test-strategy`, `tech-debt-triage`, `dependency-upgrade`, `ui-visual-review`, `divergent-design` router). Each skill's `SKILL.md` frontmatter declares its own triggers. The draft-review/fact-check family was originally seeded from [tomwalczak/claude-cowork-fact-checking-skills](https://github.com/tomwalczak/claude-cowork-fact-checking-skills) and has since diverged.

## Sharing with collaborators

Collaborators clone this repo and run the symlink setup for their tool of choice. The workflow files are identical across all entry points — only the wiring differs.
