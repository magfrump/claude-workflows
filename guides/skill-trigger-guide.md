# Skill Trigger Guide

Which skill to invoke for a given task. Skills are agent-invocable prompts that produce analysis artifacts — they differ from workflows (which structure multi-phase human+agent collaboration) and from guides (which document conventions).

> **Canonical source:** CLAUDE.md's "Skill routing" table defines the three auto-triggered skills (ui-visual-review, security-reviewer, code-review). This guide is a superset covering all skills including manually invoked ones. If auto-trigger rules diverge, CLAUDE.md wins.

**Key distinction:** Workflows answer "how should I work on this?" Skills answer "what analysis should I run on this artifact?"

## Quick-Reference: Task → Skill(s)

| Task type | Primary skill | Also consider |
|---|---|---|
| Full code review / PR review | `code-review` | — (orchestrates sub-skills automatically) |
| Security audit | `security-reviewer` | `code-review` (includes security as core critic) |
| Performance analysis | `performance-reviewer` | `code-review` (includes performance as core critic) |
| API design review | `api-consistency-reviewer` | `code-review` (includes API as core critic) |
| Writing / draft review | `draft-review` | — (orchestrates sub-skills automatically) |
| Fact-check a draft | `fact-check` | `draft-review` (includes fact-check as Stage 1) |
| Verify code comments match behavior | `code-fact-check` | `code-review` (includes code-fact-check as Stage 1) |
| Tech debt assessment | `tech-debt-triage` | `matrix-analysis` (for comparing multiple debt items) |
| Test planning | `test-strategy` | `code-review` (auto-triggers when tests are missing) |
| Dependency upgrade decision | `dependency-upgrade` | `code-review` (auto-triggers on manifest changes) |
| UI / layout review | `ui-visual-review` | `code-review` (auto-triggers on UI file changes) |
| Compare options / decision matrix | `matrix-analysis` | `tech-debt-triage` (if comparing debt items specifically) |
| Intellectual critique of argument | `cowen-critique` | `draft-review` (dispatches critics automatically) |
| Policy / pragmatism critique | `yglesias-critique` | `draft-review` (dispatches critics automatically) |
| Multi-perspective critique of a proposal | `ai-personas-critique` | `draft-review` (dispatches critics automatically) |
| Business plan / pitch critique | `business-plan-critique-moat`, `business-plan-critique-unit-economics`, `business-plan-critique-market-sizing` | `draft-review` (dispatches moat and unit-economics automatically) |
| Architecture / module-boundary review | `architecture-review` | `code-review` (auto-triggers on structural changes) |
| Stress-test a plan ("what could go wrong?") | `what-if-analysis` | `pre-mortem` (if framed as "it already failed — why?") |
| Failure narratives before shipping | `pre-mortem` | `what-if-analysis` (prospective consequence map) |
| Choose among 3+ design approaches | `divergent-design` | `matrix-analysis`, `design-space-situating` |
| Frame a decision before choosing | `design-space-situating` | `divergent-design` |
| Verify a calculation | `arithmetic-eval` | — |
| Evaluate a skill or workflow | `self-eval` | — |

## Skill Categories

### Orchestrators

These skills dispatch work to sub-agents and synthesize results. **Use one orchestrator per review — they are mutually exclusive.**

- **`code-review`** — Full code review pipeline. Stage 1: `code-fact-check`. Stage 2: three core critics (`security-reviewer`, `performance-reviewer`, `api-consistency-reviewer`) plus auto-selected contextual critics. Stage 3: synthesis. Use for PR reviews or any "review this code" request.

- **`draft-review`** — Full writing review pipeline. Stage 1: `fact-check`. Stage 2: auto-selects from a fixed list of known critics (`cowen-critique`, `yglesias-critique`, `ai-personas-critique`, `business-plan-critique-moat`, `business-plan-critique-unit-economics`) declared in its Dependencies block — it does not scan for new critics, so a new critic must be added to that list. Stage 3: synthesis. Use for "review this draft" or "give me feedback on this writing."

- **`matrix-analysis`** — Structured comparison of N items across M criteria. Dispatches one sub-agent per criterion, compiles into comparison matrix. Use for "compare X vs Y vs Z" or any multi-option evaluation.

### Fact-Checkers

Two complementary fact-checkers for different artifact types:

- **`code-fact-check`** — Verifies claims in code comments, docstrings, and documentation against actual code behavior. Produces verdicts: Verified / Mostly accurate / Stale / Incorrect / Unverifiable.

- **`fact-check`** — Journalistic fact-checking for written drafts. Verifies numbers, named policies, attributed facts, causal claims. Produces verdicts: Accurate / Mostly accurate / Disputed / Inaccurate / Unverified.

**When to use which:** `code-fact-check` for anything in or about code. `fact-check` for prose, articles, essays, policy pieces.

### Core Code Critics

Always included by `code-review`. Can also be invoked standalone for focused analysis.

- **`security-reviewer`** — Traces trust boundaries, finds implicit sanitization assumptions, checks error paths, identifies TOCTOU gaps, inverts access control, follows secrets. Trigger: auth, input handling, crypto, file I/O, network calls, serialization.

- **`performance-reviewer`** — Counts hidden multiplications, traces memory lifecycle, checks database patterns, identifies serialization tax, finds contention points. Trigger: queries, loops, caching, pagination, batch ops, request handlers.

- **`api-consistency-reviewer`** — Checks naming consistency, traces consumer contracts, verifies error patterns, checks pagination. Trigger: any change to endpoints, public interfaces, exported functions, SDK methods, CLI commands, config schemas.

### Draft Critics

Invoked by `draft-review`. Can also be invoked standalone for focused critique.

- **`cowen-critique`** — Tyler Cowen's cognitive methods: try boring explanation first, invert the claim, follow revealed preferences, push to logical extreme, find cross-domain analogies. Best for: argument structure, intellectual rigor, non-obvious weaknesses.

- **`yglesias-critique`** — Matt Yglesias's methods: agree with goal / demolish mechanism, find boring lever, trace money, check election-cycle survival, identify cost disease traps. Best for: policy feasibility, implementation realism, political sustainability.

- **`ai-personas-critique`** — Selects 3-4 maximally orthogonal personas from a catalog based on the proposal's domain, runs each persona's objection, and synthesizes. Best for: breadth and surprise, proposals spanning multiple domains, "what am I missing?"

- **`business-plan-critique-moat`** — Moat type, distribution channel, switching cost, network effect, competitive response. Best for: pitches, investor decks, go-to-market docs.

- **`business-plan-critique-unit-economics`** — CAC, LTV, contribution margin, payback period, gross-margin trajectory. Best for: pitches, financial models, fundraising memos.

- **`business-plan-critique-market-sizing`** — TAM derivation, SAM realism, SOM achievability, market timing. Best for: pitches and market-entry analyses. Not in `draft-review`'s known-critic list — invoke standalone or name it explicitly.

**When to use which:** `cowen-critique` for general argument quality. `yglesias-critique` for policy or economics pieces. `ai-personas-critique` when a single fixed voice feels too narrow. The `business-plan-critique-*` skills for business-plan-shaped drafts. `draft-review` runs the applicable ones.

### Contextual Critics

Auto-triggered by `code-review` under specific conditions. Also useful standalone.

- **`test-strategy`** — Recommends what tests to write, where, and in what priority order based on risk profile. Auto-triggers in `code-review` when source files change without matching test files. Standalone: "what tests should I write for this?"

- **`tech-debt-triage`** — Evaluates cost of carrying vs fixing tech debt, produces fix/carry/defer recommendation. Auto-triggers in `code-review` for large diffs (>10 files or >500 lines). Standalone: "should we fix this?" or "prioritize these cleanup tasks."

- **`dependency-upgrade`** — Evaluates upgrade safety: breaking changes, migration effort, go/no-go recommendation. Auto-triggers in `code-review` when dependency manifests change. Standalone: "should we upgrade X?"

- **`ui-visual-review`** — Checks for layout bugs: unbounded content, scroll traps, wrong flex usage, absolute positioning, responsive issues. Auto-triggers in `code-review` when diff touches JSX/TSX with styling, CSS/SCSS, HTML templates, C#/Unity UI, Vue/Svelte, or Tailwind. Standalone: visual bug reports or "review the UI."

- **`architecture-review`** — SOLID violations, dependency direction, module boundaries, coupling. Auto-triggers in `code-review` when the diff changes module structure, public APIs, data models, or cross-cutting concerns; unlike the other contextual critics its findings can count toward the rubric's red/amber status. Standalone: "review the architecture" or "check module boundaries."

### Decision and Risk Analysis

Standalone skills for evaluating decisions and plans rather than code or drafts. Often invoked as sub-procedures of the `divergent-design` workflow.

- **`divergent-design`** — Thin router into `workflows/divergent-design.md` (diverge → diagnose → match → decide). Use when a task resolves to choosing among 3+ tradeoff-bearing approaches.

- **`design-space-situating`** — Places a decision on eight design-space dimensions and surfaces misframing. Use before choosing, or when no candidate fits the brief.

- **`what-if-analysis`** — Prospective consequence analysis: load-bearing assumptions, second-order effects, hidden couplings, reversibility. Use for "what could go wrong with this?"

- **`pre-mortem`** — Retrospective failure narratives: assume the change shipped and failed, then write 3-5 concrete stories of why. Use for "imagine this has already failed."

**When to use which:** `what-if-analysis` when the plan is on the table and you want the consequence space; `pre-mortem` when the framing is "it already failed — tell the story."

### Utility

- **`arithmetic-eval`** — Evaluates math with python3 (safe AST evaluator for bare arithmetic; allowlisted scientific modules for statistics and data work) instead of mental math. Use for any non-trivial calculation, including inside a fact-check or cost estimate.

### Meta-Skill

- **`self-eval`** — Evaluates a skill or workflow against the project's evaluation rubric. Produces automated assessments plus structured prompts for human judgment. Use when adding or improving a skill.

## Skills vs Workflows

| | Skills | Workflows |
|---|---|---|
| **Purpose** | Analyze an artifact | Structure a multi-phase task |
| **Input** | Code diff, draft, dependency, etc. | A task description |
| **Output** | Structured report with findings | Completed implementation + artifacts |
| **Duration** | Minutes (single pass) | Session to multi-session |
| **Human gates** | None (fully automated) | Plan review, PR review, etc. |
| **Examples** | "Review this PR for security" | "Implement this feature" |

**Rule of thumb:** If you're asking "what's wrong with this?" → skill. If you're asking "how do I build this?" → workflow. The workflow-selection guide ([workflow-selection.md](workflow-selection.md)) handles workflow choice; this guide handles skill choice.

## Overlap Map

Skills that touch similar territory:

```
code-review ──orchestrates──► security-reviewer
                              performance-reviewer
                              api-consistency-reviewer
                              + contextual: test-strategy, tech-debt-triage,
                                           dependency-upgrade, ui-visual-review,
                                           architecture-review

draft-review ──orchestrates──► fact-check
                               cowen-critique
                               yglesias-critique
                               ai-personas-critique
                               business-plan-critique-moat
                               business-plan-critique-unit-economics

what-if-analysis ←── prospective vs retrospective ──► pre-mortem

code-fact-check ←──────────── complementary ──────────► fact-check
(code claims)                                           (draft claims)

security-reviewer ←── both touch ──► performance-reviewer
                    resource limits

security-reviewer ←── both touch ──► api-consistency-reviewer
                    trust boundaries
```

**When overlap causes confusion:**
- "Review this code" → `code-review` (it dispatches the right sub-skills)
- "Just check security" → `security-reviewer` standalone
- "Review this draft" → `draft-review` (it dispatches the right sub-skills)
- "Just fact-check" → `fact-check` or `code-fact-check` depending on artifact type

## Health-Check Validation

To verify that this guide stays in sync with the actual skills directory, run:

```bash
# Every skill in skills/ must appear in this guide
# (skills live at skills/<name>/SKILL.md; flat files like skills/claude-api.md are not loaded as skills)
for skill in skills/*/SKILL.md; do
  name=$(basename "$(dirname "$skill")")
  if ! grep -q "$name" guides/skill-trigger-guide.md; then
    echo "MISSING from guide: $name"
  fi
done

# Every skill referenced in backticks in this guide must exist in skills/
grep -oP '`([a-z][-a-z]*)`' guides/skill-trigger-guide.md | tr -d '`' | sort -u | while read name; do
  if [ -f "skills/${name}/SKILL.md" ]; then
    : # exists
  else
    echo "REFERENCED but not in skills/: $name"
  fi
done
```

Both commands should produce no output when the guide is in sync.
