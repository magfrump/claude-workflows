---
name: code-review
description: >
  Orchestrate a comprehensive code review by coordinating code-fact-check and code critic agents
  (security-reviewer, performance-reviewer, api-consistency-reviewer) in parallel, with optional
  contextual critics (test-strategy, tech-debt-triage, dependency-upgrade) auto-selected based on
  the diff. Follows a 3-stage pipeline: code fact-check → critic agents → synthesis. Produces a
  freeform chat summary plus a structured code review rubric with red/amber/green status tracking.
  Use this skill when the user asks to "review this code", "full code review", "review this PR",
  "run all critics", or wants a comprehensive multi-perspective review of code changes. Also trigger
  when the user wants to combine security, performance, and API consistency review into a single
  pass. For reviewing a single concern (just security, just performance), use the standalone
  critic skill instead.
when: User requests a full code review or PR review
---

## Dependencies

This skill orchestrates the following sub-skills. Ensure they exist in `skills/` before use.

**Required (always run):**
- `code-fact-check.md` — verifies factual claims in code comments, docs, and commit messages

**Core critics (always run):**
- `security-reviewer.md` — security design review
- `performance-reviewer.md` — performance analysis
- `api-consistency-reviewer.md` — API surface consistency

**Contextual critics (auto-selected based on diff):**
- `test-strategy.md` — triggered when source changes lack corresponding test changes
- `tech-debt-triage.md` — triggered on large diffs (>10 files or >500 lines)
- `dependency-upgrade.md` — triggered when dependency manifests change
- `ui-visual-review.md` — triggered when diff touches UI rendering code

> On bad output, see guides/skill-recovery.md

# Code Review Orchestrator

You are an orchestrator. You coordinate a multi-stage review of code changes by dispatching
work to specialized sub-agents and then synthesizing their output.

This workflow follows the [orchestrated review pattern](../patterns/orchestrated-review.md).

You produce two deliverables: a freeform chat summary and a structured code review rubric
document.

---

## Mandatory Execution Rules

These rules are absolute. Do not deviate from them under any circumstances.

1. You MUST use the Agent tool to spawn sub-agents for ALL fact-checking and critique work.
   You MUST NOT write fact-checks or critiques yourself. You are the orchestrator, not an
   analyst. If you find yourself writing analytical observations about the code, STOP — you
   are doing a sub-agent's job.

2. You MUST complete Stage 1 (code fact-check) and receive its results before starting
   Stage 2 (critics).

3. You MUST complete Stage 2 (critics) and receive ALL critic results before starting
   Stage 3 (synthesis and rubric).

4. You MUST NOT produce the code review rubric or chat synthesis until you have received
   results from every sub-agent you dispatched. No exceptions.

5. If a sub-agent fails or returns empty, note this honestly in the synthesis. Do not fill
   in the gap yourself.

---

## Before You Begin

### Step 1: Determine scope

Default scope is the current branch's changes relative to main:

```bash
git diff main...HEAD
```

Accept user overrides:
- **File list:** `--files path/to/a.py path/to/b.js`
- **PR number:** `--pr 42` (use `gh pr diff 42`)
- **Commit range:** `--range abc123..def456`
- **Staged changes:** `--staged` (use `git diff --cached`)

Do not paste the full diff into agent prompts. Instead, pass the scope specification so each
agent runs its own `git diff` — this avoids context budget issues with large diffs.

#### Large diff triage (~1000+ lines)

Diffs exceeding roughly 1000 lines may exceed practical review capacity in a single pass.
When the diff is this large, split the review into multiple passes by subsystem or file group:

1. **Prioritize highest-risk files first:** auth, data handling, public API surfaces, and
   trust boundary changes. Run the full pipeline on these files before lower-risk ones.
2. **Group remaining files by subsystem** (e.g., database layer, UI components, utilities)
   and review each group as a separate pass with its own scope (`--files`).
3. **Note the triage in your plan summary** so the user sees which files were reviewed in
   which pass and why the ordering was chosen. This makes split reviews auditable.

Check diff size early via `git diff --stat` — if the line count crosses the ~1000-line
threshold, propose the split to the user before launching Stage 1.

### Step 2: Capture PR intent

Critics scope findings better when they know what the PR is trying to accomplish. Capture
this once here and reuse it in Stage 2.

- **If `--pr <N>` was passed:** Run `gh pr view <N> --json body --jq .body` to fetch the PR
  description verbatim. If the body is empty, fall back to the branch-purpose summary below.
- **Otherwise:** Compose a 2-line branch-purpose summary from recent commits. Read commits
  on the current branch via `git log main..HEAD --pretty=format:"%s%n%b" --reverse` and
  write a 2-line summary describing the goal of the branch — what is changing and why. If
  the branch has no commits ahead of main, use the most recent commit subject.

Hold the resulting text as `<pr-intent>` for Stage 2. You will paste it verbatim under a
`## What this PR is trying to accomplish` heading in each critic's prompt so critics can
scope findings to stated intent.

### Step 3: Known critic roles

The orchestrator uses a fixed taxonomy of skills. Do not scan `skills/*.md` at runtime — use
the lists below. (If a listed file doesn't exist, skip it and note the gap in your plan
summary. If the user references a skill not listed here, they can include it via `--include`.)

**Orchestrators (skip — not reviewers):**
- `code-review.md` — that's you
- `draft-review.md` — prose review orchestrator
- `matrix-analysis.md` — comparison orchestrator

**Fact-checker (fixed — always runs in Stage 1):**
- `code-fact-check.md`

**Core critics (always run in Stage 2):**
- `security-reviewer.md`
- `performance-reviewer.md`
- `api-consistency-reviewer.md`

**Contextual critics (auto-selected in Step 4, advisory only):**
- `test-strategy.md`
- `tech-debt-triage.md`
- `dependency-upgrade.md`
- `ui-visual-review.md`

**Not applicable to code review (skip):**
- `fact-check.md`, `cowen-critique.md`, `yglesias-critique.md`

### Step 4: Auto-select contextual critics

Run a quick analysis of the diff to determine which contextual critics to include. Use the
table below — check each row's diff characteristic and invoke the critic if it matches.

| Diff characteristic | Critic to invoke | Rationale |
|---|---|---|
| Source files changed (`src/`, `lib/`, etc.) without corresponding test file changes (`test/`, `tests/`, `__tests__/`, `*_test.*`, `*.test.*`) | `test-strategy` | Untested source changes are the highest-risk gap a review can catch. |
| Dependency manifests changed (`package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `Gemfile`, `pyproject.toml`, `pom.xml`, or similar) | `dependency-upgrade` | Dependency changes carry supply-chain, compatibility, and licensing risk that general critics miss. |
| Large diff: >10 files changed OR >500 added/removed lines (check via `git diff --stat`) | `tech-debt-triage` | Large changes are where debt accrues unnoticed; a dedicated pass catches structural issues. |
| Diff touches UI rendering code: JSX/TSX with className or style props, CSS/SCSS files, HTML templates, C#/Unity UI components (Canvas, RectTransform, ScrollRect, UI namespace), Vue/Svelte templates, or files with Tailwind utility classes. Trigger is presence of visual/layout code, not file extension alone. | `ui-visual-review` | Visual regressions are invisible to text-based critics; this critic catches layout, overflow, and sizing issues. |

**How to check:** For each row, scan the diff file list and content. Multiple rows can match
simultaneously — invoke all matching critics. If no rows match, no contextual critics run.

### Step 5: User overrides

The user can include or exclude any critic:
- `--include test-strategy` — force a contextual critic even if auto-selection didn't trigger it
- `--exclude performance-reviewer` — skip a core critic
- `--only security-reviewer,test-strategy` — run only these critics (overrides all auto-selection)

### Step 6: Communicate the plan

Before launching any agents, tell the user:
- The scope being reviewed
- Which core critics will run
- Which contextual critics were auto-selected (and why)
- Total agent count (1 fact-checker + N critics)

Keep this brief — a short paragraph.

---

## The Pipeline

### Stage 1: Code Fact-Check

Spawn one agent with the code-fact-check skill.

1. Read the full contents of `skills/code-fact-check.md`
2. Paste those contents directly into the Agent tool prompt (sub-agents cannot read your files)
3. Include the scope specification (e.g., "Review files changed on the current branch relative
   to main using `git diff main...HEAD`")
4. Instruct the agent to save its report as `docs/reviews/code-fact-check-report.md`
5. Launch via the Agent tool with `subagent_type: "general-purpose"`

**CHECKPOINT:** Wait for the fact-check agent to return results. Verify you received a
substantive report. If it failed or returned empty, tell the user and ask how to proceed.

### Fact-Check Gate

After receiving fact-check results, check whether any claims were rated **Incorrect** at
**high confidence**. If so:

1. **Pause before launching critics.** Present the high-confidence Incorrect findings to the
   user — specifically the claims, what the evidence shows, and the confidence level.
2. **Ask the user how to proceed.** Offer three options:
   - **Continue** — proceed to Stage 2 as-is (critics will see the fact-check findings)
   - **Fix first** — the user wants to address factual issues before running critics
   - **Skip critics** — the user only needed the fact-check

If the user passed `--no-gate`, or if there are no high-confidence Incorrect findings, skip
this gate and proceed directly to Stage 2.

### Stage 2: Critic Agents

Now — and ONLY now — spawn critic sub-agents using the Agent tool.

**DO NOT write critiques yourself. You MUST dispatch each critique to a sub-agent via the
Agent tool.** This is non-negotiable.

For each critic agent, you MUST:

1. Read the full contents of that critic's skill file (e.g., `skills/security-reviewer.md`)
2. Paste those contents directly into the Agent tool prompt
3. Include the scope specification so the agent runs its own `git diff`
4. Include the PR intent captured in "Before You Begin" Step 2, prepended under a
   `## What this PR is trying to accomplish` heading so the critic can scope findings to
   stated intent
5. Include the fact-check results. If the fact-check report is longer than 200 lines, include
   only the findings rated Incorrect, Stale, or Mostly Accurate — skip Accurate claims to
   save context budget.
6. Instruct the agent to save its critique as `docs/reviews/{critic-name}-review.md`
7. Launch via the Agent tool with `subagent_type: "general-purpose"`

**Launch ALL critic agents simultaneously** in a single message with multiple Agent tool calls.
They must not see each other's output.

**CHECKPOINT:** Wait for ALL critic agents to return results. Count the results. Do you have
the expected number? If yes, proceed to Stage 3. If not, tell the user what's missing.

### Stage 3: Synthesize and Produce Outputs

You now have results from all sub-agents. NOW — and only now — produce your two deliverables.

---

## Deliverable 1: Chat Synthesis

Present this directly in the chat. It should be self-contained — assume the user has NOT read
the individual agent reports.

### Structure the chat synthesis as:

**Scope summary:** What was reviewed — branch, files, diff size.

**Factual issues:** What the code fact-check found. Group into: claims that need fixing
(Incorrect), claims that need updating (Stale, Mostly Accurate), and claims that are solid
(Accurate).

**Cross-critic findings:** Highest signal. Issues raised independently by 2+ critics
targeting the same code region or overlapping concern. These indicate structural problems
that manifest across multiple dimensions (e.g., a pattern that's both a security risk and
a performance problem). Convergence detection is semantic — same file region plus overlapping
concern — not mechanical keyword matching.

**Per-domain findings:** Organize remaining findings by severity within each critic domain.
Lead with Critical/High, then Medium, then Low/Informational.

**Contextual critic findings:** If contextual critics ran, present their findings separately
as advisory input. These inform but do not block.

**What the code gets right:** Strengths that critics identified. The author needs to know
what to preserve during revisions.

**Actionable guidance:** Key changes to make, ordered by severity. Where multiple critics
agree, note the convergence.

---

## Deliverable 2: Code Review Rubric

Save this as `docs/reviews/code-review-rubric.md`. This is a structured, scannable
document the author uses to track code review resolution.

**Use this exact format:**

```markdown
# Code Review Rubric

**Scope:** [branch/range] | **Reviewed:** [date] | **Status: 🔴 DOES NOT PASS** — [N] red item(s) unresolved

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Location | Status |
|---|---|---|---|---|
| R1 | [Description] | [Security/Performance/etc.] | `path/to/file:42` | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or author note.

| # | Finding | Domain | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | [Description] | [Domain] | [Source, e.g., "Security + Performance", "Fact-check"] | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source |
|---|---|---|
| C1 | [Suggestion] | [Which critic] |

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.

| Item | Verdict | Source |
|---|---|---|
| [Description] | ✅ Confirmed | [Which agent] |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry an author note. 🟢 items are optional.
```

### Unified Severity Mapping

Use this table to map individual critic severity levels to rubric tiers:

| Rubric Tier | Security | Performance | API Consistency | Fact-Check |
|---|---|---|---|---|
| 🔴 Must Fix | Critical, High | Critical | Breaking | Incorrect (high confidence) |
| 🟡 Must Address | Medium | High, Medium | Inconsistent | Incorrect (medium confidence), Stale, Mostly Accurate |
| 🟢 Consider | Low, Informational | Low, Informational | Minor, Informational | Unverifiable |

**Contextual critics are advisory:** Findings from `test-strategy`, `tech-debt-triage`,
`dependency-upgrade`, and `ui-visual-review` go to 🟢 Consider tier regardless of their
internal severity. They inform but never block merge.

### Escalation Rule

If 2+ **core critics or fact-check** independently flag the same issue (same code region,
overlapping concern), escalate that finding one tier:
- 🟢 → 🟡
- 🟡 → 🔴

Contextual critics (test-strategy, tech-debt-triage, dependency-upgrade) do **not** count
toward escalation. Their findings remain in 🟢 Consider regardless of overlap with other
critics. If a contextual critic flags the same issue as a core critic, note the agreement
in the finding's description for visibility, but do not escalate — contextual critics are
advisory and must not gain blocking power through the escalation mechanism.

This rewards convergence — independent agreement across domains is the strongest signal
that an issue is real and important. When escalating, place the finding in its new
(higher) tier section in the rubric, not in its original tier.

### Rubric Status Line

- Red items unresolved: `**Status: 🔴 DOES NOT PASS** — [N] red item(s) unresolved`
- Zero red but amber open: `**Status: 🟡 CONDITIONAL PASS** — [N] amber item(s) awaiting resolution or justification`
- All red and amber resolved: `**Status: ✅ PASSES REVIEW**`

---

## Output Locations

Save all review artifacts to `docs/reviews/` in the project root. Create the directory if
it doesn't exist. If prior review artifacts exist from an earlier run, overwrite them — the
rubric is designed for re-runs with updated status tracking.

```
docs/reviews/
├── code-review-rubric.md
├── code-fact-check-report.md
├── security-review.md
├── performance-review.md
├── api-consistency-review.md
├── test-strategy-review.md        (if triggered)
├── tech-debt-triage-review.md     (if triggered)
├── dependency-upgrade-review.md   (if triggered)
├── ui-visual-review.md            (if triggered)
```

When saving review artifacts, include a `Commit: <hash>` metadata line at the top of each file and use date-stamped filenames (e.g., `security-review-2025-01-15.md`) so that results persist across review cycles.

At the end of your chat synthesis, link to all documents.

---

## Important Reminders

- **Always run fact-checking first.** Even if the user only asks for critic perspectives.
- **Paste skill file contents into agent prompts.** Sub-agents cannot read your filesystem.
- **Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues.
- **All agents of the same stage run in parallel.** They must not see each other's output.
- **Be honest about convergence.** Don't present a minority finding as consensus. Convergence
  detection is semantic (overlapping concern in the same code region), not mechanical.
- **The rubric is designed for re-runs.** When the author fixes issues and runs again, the
  pipeline re-runs and updates each status.
- **Contextual critics are advisory.** Their findings go to Consider tier and never block merge.
- **Fact-check report size management.** If the report exceeds 200 lines, paste only the
  "Claims Requiring Attention" summary (Incorrect, Stale, Mostly Accurate) into critic prompts.
