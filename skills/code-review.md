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

### Step 3: Surface prior review findings (optional)

If the diff touches files that appear in a prior `docs/reviews/*.md` report from the last 30 days (detect via `git log --since="30 days ago" -- docs/reviews/` and intersect those reports' `Location:` paths with the changed-file list), lift the **Must-Fix** rows whose locations still apply and hold them as `<prior-findings>` for Stage 2. You will paste them verbatim under a `## Prior review findings (advisory — worth checking, not verdict input)` heading in each critic's prompt so recurring issues are flagged explicitly rather than re-discovered. Treat them as hints about where to look — critics MUST NOT confirm them as findings or feed them into verdicts. Skip silently if no matching prior reports exist. (Extends the within-PR cross-iteration contrastive prompt in `workflows/pr-prep.md` step 3d to across-PR memory.)

### Step 4: Known critic roles

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

**Contextual critics (auto-selected in Step 5, advisory only):**
- `test-strategy.md`
- `tech-debt-triage.md`
- `dependency-upgrade.md`
- `ui-visual-review.md`

**Not applicable to code review (skip):**
- `fact-check.md`, `cowen-critique.md`, `yglesias-critique.md`

### Step 5: Auto-select contextual critics

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

### Step 6: User overrides

The user can include or exclude any critic:
- `--include test-strategy` — force a contextual critic even if auto-selection didn't trigger it
- `--exclude performance-reviewer` — skip a core critic
- `--only security-reviewer,test-strategy` — run only these critics (overrides all auto-selection)
- `--all-critics` — disable the Stage 1.5 critic gate (run every core critic regardless
  of diff-shape or fact-check evidence signals). Use when the user wants the full panel.
- `--chain <pair>` — opt into chain dispatch for the named critic pair (see
  [Stage 2 dispatch modes](#stage-2-dispatch-modes)). Supported pairs:
  `security→api-consistency` and `test-strategy→tech-debt-triage`. The
  flag is the orchestrator's one-line signal to switch off the parallel
  default for that pair only; all other critics still run in parallel
  alongside the chain. Omit the flag to keep the parallel default.

### Step 7: Communicate the plan

Before launching any agents, tell the user:
- The scope being reviewed
- Which core critics will run
- Which contextual critics were auto-selected (and why)
- Total agent count (1 fact-checker + N critics)

Keep this brief — a short paragraph.

---

## The Pipeline

### Between-stage status banner

After each between-stage handoff (end of Stage 1, end of Stage 2), emit a single
one-line status banner directly in the chat so the user can judge progress and
decide whether to interrupt before the next stage launches.

**Format:** `Stage N (<stage-name>) complete: <key counts> — <next action>`

- One line, plain text in the chat. Do not write the banner into any saved
  artifact under `docs/reviews/`.
- `<key counts>` is the smallest summary that helps the user judge whether to
  intervene — e.g., counts of Incorrect / Stale fact-check findings after
  Stage 1, or count of critics returned (and any that failed) after Stage 2.
- `<next action>` names the next stage and its dispatch shape — e.g.,
  "launching 4 critics in parallel", "launching 4 critics: 3 in parallel +
  chain security→api-consistency", or "synthesizing into rubric and chat
  summary".
- The Stage 2-complete banner introduces synthesis (Stage 3). Because Stage
  3 consumes Stage 2's output, this banner must include `dispatch mode:
  <mode>` in `<key counts>` so the reader knows which dispatch shape
  produced the findings before reading the synthesis. Use `parallel`,
  `chain (<pair>)`, or `parallel + chain (<pair>)` — see
  [Stage 2 dispatch modes](#stage-2-dispatch-modes).

**Worked example (parallel default):**

> Stage 1 (fact-check) complete: 3 Incorrect findings, 1 Stale — launching 4 critics in parallel (security, performance, api-consistency, test-strategy).
>
> Stage 2 (critics) complete: 4/4 critics returned (12 findings total), dispatch mode: parallel — synthesizing into rubric and chat summary.

**Worked example (chain mode opted in via `--chain security→api-consistency`):**

> Stage 1 (fact-check) complete: 3 Incorrect findings, 1 Stale — launching 4 critics: 2 in parallel (performance, test-strategy) + chain security→api-consistency.
>
> Stage 2 (critics) complete: 4/4 critics returned (12 findings total), dispatch mode: parallel + chain (security→api-consistency) — synthesizing into rubric and chat summary.

**Scope:** The banner is emitted *only* between stages. Do **not** emit a
banner after Stage 3 — Stage 3's chat synthesis is itself the user-facing
output, and a "Stage 3 complete" banner would duplicate or compete with it.

### Stage 1: Code Fact-Check

Spawn one agent with the code-fact-check skill.

1. Read the full contents of `skills/code-fact-check.md`
2. Paste those contents directly into the Agent tool prompt (sub-agents cannot read your files)
3. Include the scope specification (e.g., "Review files changed on the current branch relative
   to main using `git diff main...HEAD`")
4. Instruct the agent to save its report as `docs/reviews/code-fact-check-report.md`
5. Require the agent to tag every claim with a **Legibility-target** field
   (`for-author`, `for-orchestrator-synthesis`, or `for-automated-gate`) per
   the [legibility-target tagging](../patterns/orchestrated-review.md#legibility-target-tagging)
   spec. Default mapping for fact-check claims: Incorrect / Stale / Mostly
   Accurate → `for-author` (the author needs to fix or update); Verified /
   Unverifiable → `for-orchestrator-synthesis` (orchestrator uses these for
   coverage and convergence, doesn't need to surface verbatim).
6. Require the agent to append a **Goal-Alignment Note** at the end of its report and chat
   summary using the canonical form from
   [`patterns/orchestrated-review.md`](../patterns/orchestrated-review.md):

   ```markdown
   ## Goal-Alignment Note
   - Answered: [yes / partial / no — one phrase]
   - Out of scope: [what was set aside and why, or "none"]
   - Escalate: [what the orchestrator should action separately, or "nothing"]
   - Questions I would have asked: [1-3 short questions, only if scope was unclear; otherwise omit this bullet]
   ```

   One short bullet per line. No padding. The "Questions I would have asked" bullet is
   optional — include it only when scope was genuinely ambiguous and the agent had to
   make a non-trivial guess about what to check.
7. Launch via the Agent tool with `subagent_type: "general-purpose"`

**CHECKPOINT:** Wait for the fact-check agent to return results. Verify you received a
substantive report. If it failed or returned empty, tell the user and ask how to proceed.

After receiving substantive results, emit the between-stage status banner per the
format spec above (e.g., `Stage 1 (fact-check) complete: <counts> — <next action>`).
Emit it before the Fact-Check Gate so the user sees stage progress even if the gate
pauses for input.

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

### Stage 1.5: Critic gating

After the Fact-Check Gate (and only if the user did NOT pass `--all-critics`), narrow the
core-critic set down before launching Stage 2. This stage applies two gating signals,
ordered by when their input becomes available:

- **First gate — diff-shape.** Already partially applied: Step 4 used the diff to select
  contextual critics pre-Stage-1. Now extend the same diff-shape logic to the core
  critics via the skip table below — `git diff --stat` and spot-checked diff content are
  the inputs.
- **Second gate — evidence (new).** The fact-check report is now in hand. Use it to
  confirm that each remaining core critic has *some* corroborating evidence in its
  domain. If the only thing keeping a critic alive is "we always run it," and Stage 1
  surfaced nothing in its domain, downgrade it.

The default is **run all core critics** — skipping is conservative. The cost of running
an extra critic is small; the cost of a missed finding is large. If you are uncertain
whether a signal applies, do not skip.

**Boring version:** consult fact-check to optionally *downgrade* critics. Do not re-derive
the critic set from scratch — the set entering Stage 1.5 is whatever survived Step 4
selection + user overrides, and Stage 1.5 only narrows it further. Stage 1.5 never
*promotes* a critic.

This section runs silently — emit no status banner. The Stage 1 banner already fired
before the Fact-Check Gate, and the Stage 2 banner fires after critics return.

#### Evidence consultation (lead signal)

For each remaining core critic, ask: did Stage 1 surface *any* claim — at any verdict,
including Accurate or Unverifiable — that touches this critic's domain? And does the
diff (which fact-check scoped over) actually contain files in that domain?

| Critic | Domain heuristic — corroborating evidence is any of |
|---|---|
| `security-reviewer` | A fact-check claim or diff hunk touching auth, crypto, input handling, file I/O, network calls, serialization, error/exception messages, URL/path construction, or any string literal in an HTML/SQL/shell/regex context. |
| `performance-reviewer` | A fact-check claim or diff hunk touching loops, queries, data-structure choice, hot paths, complexity claims (e.g., "O(n)"), caching, batching, or dependency add/upgrade. |
| `api-consistency-reviewer` | A fact-check claim or diff hunk touching exported function signatures, schema/contract definitions, route handlers, public CLI flags, module exports, or published config keys. |

If a critic's domain heuristic finds **zero corroborating evidence** in both the
fact-check report and the diff, downgrade the critic to skip-with-note. Record the skip
in the rubric's `## ⏭️ Skipped Core Critics` section with the signal cited as
"no fact-check claims or diff content in domain."

If *any* corroborating evidence exists — even a single Accurate fact-check claim, or a
single diff hunk touching the domain — run the critic. The diff-shape skip table below
still applies as a complementary signal, but evidence consultation has priority: a
fact-check finding in the domain forces the critic to run regardless of how copy-only
the diff appears.

#### Skip signals (diff-shape, must be unambiguous)

| Critic | Skip ONLY when | Run anyway when (overriding signals) |
|---|---|---|
| `performance-reviewer` | Diff is copy-only — markdown, docs, comments, or user-facing string-literal changes — with no logic, control-flow, data-structure, query, or dependency changes. | Any code change, query change, loop, dependency add/upgrade, or fact-check finding citing perf concern. |
| `security-reviewer` | Diff is copy-only AND no string-literal change touches an HTML, SQL, shell, regex, auth, error-message, or URL/path context. | Any input handling, auth, crypto, file I/O, network, serialization, error/exception message change, or fact-check finding citing a security concern. |
| `api-consistency-reviewer` | No public API surface touched: no exported function signature changes, no schema/contract changes, no route handlers, no public CLI flags, no module export changes, no published config keys. | Any exported symbol added/renamed/removed, any public schema or contract change, any new public flag, or a fact-check finding citing API drift. |

#### How to apply

1. **Evidence consultation first.** For each remaining core critic, scan the fact-check
   report and the diff for content matching the critic's domain heuristic above. If
   *zero* corroborating evidence exists, the critic is a downgrade candidate.
2. **Then check the diff-shape skip signals.** Run `git diff --stat <scope>` and
   spot-check actual diff content — file extension alone is not sufficient (a `.md`
   file may carry a code block that ships; a `.ts` file may be a one-line copy change).
   The skip table above operationalizes the unambiguous cases.
3. **Override rule:** if any Incorrect / Stale / Mostly Accurate fact-check finding
   falls in a critic's domain, do NOT skip that critic, even if the diff-shape signals
   would otherwise allow it. Evidence consultation outranks diff shape in both directions.
4. **When in doubt, run the critic.** Document the call only when you skip.

#### Logging skipped critics

For every core critic you skip, you MUST record it in the rubric under the
`## ⏭️ Skipped Core Critics` section (see Deliverable 2 below) with the critic name, the
skip reason, and the specific signal observed (e.g., `git diff --stat` output excerpt or
the fact-check finding cited). Also reference skips in the chat synthesis scope summary so
the user sees coverage limits before reading findings.

If `--all-critics` was passed, skip this step entirely; all core critics run.

### Stage 2 dispatch modes

Stage 2 has two dispatch modes. **Default is parallel** — every critic runs
simultaneously and they do not see each other's output. Chain mode is
**opt-in via `--chain <pair>`** and applies only to the named pair; all
other critics still run in parallel alongside the chain.

The orchestrator decision is one line: if the user passed `--chain <pair>`,
run that pair sequentially with the upstream critic's findings injected into
the downstream critic's prompt; otherwise, dispatch every selected critic in
parallel.

**State the chosen mode in the Stage 2-complete (synthesis-introducing)
banner** so the reader knows which dispatch shape produced the findings
(see [Between-stage status banner](#between-stage-status-banner) for format).

#### When to chain

Chain only when an upstream critic's findings genuinely change the
downstream critic's scope — i.e., reading the upstream critique would let
the downstream critic narrow its inspection or sharpen its priorities. If
the downstream critic would do the same scan either way, parallel is
strictly faster and equally informative; do not chain by default.

#### Supported chain pairs

| Pair | Trigger to opt in | What the handoff carries |
|---|---|---|
| `security→api-consistency` | Diff shifts auth or trust boundaries: new/changed auth checks, session handling, scope of a token, permission predicate, or anything security-reviewer is likely to surface as a boundary change. | The security critique's auth/boundary findings (file:line + summary) are injected into api-consistency-reviewer's prompt under a `## Chain context: security findings to scope around` heading. The downstream critic uses these as priority targets — checking that the new auth contract is consistent across exported handlers, schemas, route definitions, and CLI surfaces around those boundaries. |
| `test-strategy→tech-debt-triage` | Diff has untested source changes AND a large/structural surface (the contextual triggers for both critics fire on the same diff). | The test-strategy critique's coverage-gap list (modules + functions lacking tests) is injected into tech-debt-triage's prompt under a `## Chain context: coverage gaps to inspect first` heading. The downstream critic prioritizes those modules — coverage gaps in complex code are evidence of poor factoring, so tech-debt-triage inspects them as candidate refactor targets rather than blanket-scanning the diff. |

#### Mechanics

When chain mode is active for a pair:

1. Identify the upstream critic in the pair. Dispatch it via the Agent tool
   exactly as documented in [Stage 2: Critic Agents](#stage-2-critic-agents)
   below, in parallel with every non-chained critic.
2. Wait for the upstream critic to return.
3. Read the upstream critic's saved report. Extract the findings whose
   domain is the chain trigger (auth/boundary findings for the security
   chain; coverage-gap entries for the test-strategy chain). Limit to
   findings with at least medium severity/confidence — pasting the full
   report defeats the scope-narrowing purpose.
4. Dispatch the downstream critic with the extracted findings prepended
   under the `## Chain context: …` heading named in the table above. Place
   it after the goal preamble and PR-intent block but before the scope
   spec, so the critic reads it before deciding what to inspect.
5. The downstream critic still produces its standard critique structure —
   the chain context narrows scope, it does not replace the critique.
6. All non-chained critics in the same Stage 2 are unaffected: they run in
   parallel and do not wait on the chain.

#### Trade-offs

Chain mode adds one round-trip of latency to Stage 2 (the downstream critic
cannot start until the upstream critic returns). It is worth that cost only
when the trigger applies — without the trigger, the downstream critic gains
no useful narrowing and the chain just slows Stage 2 down.

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
   stated intent. If Step 3 surfaced `<prior-findings>`, paste them verbatim under a
   `## Prior review findings (advisory — worth checking, not verdict input)` heading
   immediately after the intent block; otherwise omit this heading entirely.
5. Include the fact-check results. If the fact-check report is longer than 200 lines, include
   only the findings rated Incorrect, Stale, or Mostly Accurate — skip Accurate claims to
   save context budget.
6. Instruct the agent to save its critique as `docs/reviews/{critic-name}-review.md`
7. Require the agent to tag every finding with a **Legibility-target** field
   (`for-author`, `for-orchestrator-synthesis`, or `for-automated-gate`) per
   the [legibility-target tagging](../patterns/orchestrated-review.md#legibility-target-tagging)
   spec. The tag goes on the finding alongside Severity / Confidence:

   ```markdown
   **Severity:** High
   **Location:** `path/to/file.ext:42`
   **Confidence:** High
   **Legibility-target:** for-author
   ```

   Default mapping for code-review critics:
   - **Actionable code finding** with a specific recommendation →
     `for-author`. This is the default for nearly all critic findings.
   - **Coverage/convergence note** ("no issues found in the auth flow",
     "this overlaps with a performance finding in the same file") →
     `for-orchestrator-synthesis`. Helps the orchestrator decide what to
     surface but doesn't need to be shown to the author verbatim.
   - **HALT-ESCALATE block, status verdict, or other parseable directive
     intended for a downstream gate** → `for-automated-gate`. The
     security-reviewer escalation block is the canonical example.

   If a critic tags every finding `for-author`, that's a calibration
   failure — flag it in synthesis rather than treating uniform tagging as
   ground truth.
8. Require the agent to append a **Goal-Alignment Note** at the end of its critique and chat
   summary using the canonical form from
   [`patterns/orchestrated-review.md`](../patterns/orchestrated-review.md):

   ```markdown
   ## Goal-Alignment Note
   - Answered: [yes / partial / no — one phrase]
   - Out of scope: [what was set aside and why, or "none"]
   - Escalate: [what the orchestrator should action separately, or "nothing"]
   - Questions I would have asked: [1-3 short questions, only if scope was unclear; otherwise omit this bullet]
   ```

   One short bullet per line. No padding. The "Questions I would have asked" bullet is
   optional — include it only when scope was genuinely ambiguous and the critic had to
   make a non-trivial guess about what to evaluate.
9. Launch via the Agent tool with `subagent_type: "general-purpose"`

**Worked example — dispatch goal preamble with optional Project-state fields**

Each critic dispatch is prepended with the [goal preamble](../patterns/orchestrated-review.md#goal-preamble). When the orchestrator has the upstream research/plan/checkpoint/handoff doc's Project state lead block, lift those facts verbatim into the optional sub-bullets under Current task. A filled example for the security critic in this pipeline:

```
User goal: Get a comprehensive code review on the current branch before opening a PR.
Current task: Run security design review on the diff between the current branch and main.
  - Branch: feat/auth-token-storage
  - Position in initiative: Step 2 of 4 in the auth-compliance epic; sibling branch feat/session-cleanup waiting on this review.
  - Blocked on: nothing
Success criterion: A markdown report saved to docs/reviews/security-review.md, structured per the security-reviewer skill.
```

If any of those facts isn't on hand, omit the corresponding sub-bullet rather than guessing — the fields exist to anchor the critic in real project context, not to be filled for completeness. Do not add other content to the preamble; everything else (scope spec, PR intent, fact-check excerpt, output path, tagging requirements) goes in the role-specific content below it.

**Launch ALL critic agents simultaneously** in a single message with multiple Agent tool calls.
They must not see each other's output. **Exception:** when [Stage 2 dispatch
modes](#stage-2-dispatch-modes) chain mode is active for a pair, the
downstream critic is dispatched in a second message after the upstream
critic returns; every other critic still launches in the first parallel
batch.

**CHECKPOINT:** Wait for ALL critic agents to return results (including the
downstream critic of any active chain). Count the results. Do you have the
expected number? If yes, proceed to Stage 3. If not, tell the user what's
missing.

After confirming the expected critic count, emit the between-stage status banner per the
format spec above (e.g., `Stage 2 (critics) complete: <counts>, dispatch mode: <mode> — synthesizing into rubric and chat summary`).
Emit it before launching Stage 3 so the user sees the handoff explicitly.

### Stage 3: Synthesize and Produce Outputs

You now have results from all sub-agents. NOW — and only now — produce your two deliverables.

**No banner after this stage.** Stage 3's chat synthesis (Deliverable 1) is itself the
user-facing output. Do not prepend or append a "Stage 3 complete" banner — it would
duplicate the synthesis. Banners are between-stage progress indicators, not synthesis output.

#### Goal-alignment scan (run before producing deliverables)

Before writing the chat synthesis, scan the **Goal-Alignment Note** appended by each
sub-agent (see [`patterns/orchestrated-review.md`](../patterns/orchestrated-review.md)).
Collect:

- Any sub-agent whose `Answered:` value is `no` or `partial` — record the agent name
  and the one-phrase reason verbatim.
- Any non-trivial `Out of scope:` item — anything other than the literal sentinel
  `none`. Record the agent name and the bullet text.
- Any non-trivial `Escalate:` item — anything other than the literal sentinel
  `nothing`. Record the agent name and the bullet text.

If a sub-agent omitted the note entirely, treat that as a `partial` entry with reason
"missing goal-alignment note" so the gap is still surfaced.

The collected items feed the `### Coverage and Escalations` section of the chat
synthesis below. They do not modify the rubric — coverage is a chat-synthesis concern.

#### Contrastive note (optional, capture during synthesis)

Pick one finding the panel caught well, plus one likely-related issue you suspect was missed (sources: goal-alignment notes, escalations, or your own scan of the diff). State both in 1–2 lines, then propose one concrete prompt-refinement candidate — an added instruction, sharpened heuristic, or new check for a critic skill — that would have closed the gap on the next run. Skip if no genuine contrast is available; do not invent one. Capture only — no feedback pipeline consumes this yet.

---

## Deliverable 1: Chat Synthesis

Present this directly in the chat. It should be self-contained — assume the user has NOT read
the individual agent reports.

### Structure the chat synthesis as:

**Scope summary:** What was reviewed — branch, files, diff size.

### Coverage and Escalations

Surface the items collected in the Goal-alignment scan above so the user sees coverage
limits before reading findings:

- For each sub-agent that answered `no` or `partial`: list the agent name and the
  one-phrase reason.
- For each non-trivial `Out of scope:` bullet: list the agent name and what was set
  aside.
- For each non-trivial `Escalate:` bullet: list the agent name and what the
  orchestrator should action separately.

If the scan surfaced nothing, render this section with a single line: "All sub-agents
fully addressed their scope; no out-of-scope or escalate items." The heading must
still appear so the section is auditable across runs.

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

**Questions to clarify (if any sub-agent emitted them):** Scan each sub-agent's
Goal-Alignment Note for the optional "Questions I would have asked" bullet. If one or more
sub-agents emitted questions, surface them under a `### Questions to clarify` heading near
the end of the chat synthesis, just before "Actionable guidance" or as a sibling subsection.
De-duplicate: if multiple sub-agents asked semantically the same question, list it once and
note the agreement (multiple sub-agents asking the same question is a strong signal that
the prompt was under-specified). Attribute each question to the sub-agent that raised it.
If no sub-agent emitted the bullet, omit the section entirely — do not invent placeholder
questions.

Worked example:

> ### Questions to clarify
>
> Two sub-agents flagged that scope was ambiguous:
>
> - **Should the scripts under `scripts/migrations/` be in scope?** *(security-reviewer,
>   performance-reviewer — both flagged independently.)* Both agents reviewed them; if
>   you intended to exclude one-shot migration scripts, re-run with `--files` narrowed to
>   `src/`.
> - **Is the experimental `src/feature-flags/` directory production code or a sandbox?**
>   *(api-consistency-reviewer.)* The critic treated it as production and flagged a
>   breaking change in `flags.ts:42`; mark this as 🟢 Consider if it's sandbox-only.

**How to use legibility-target tags during synthesis:** Findings tagged
`for-author` are the primary content of the chat synthesis and the rubric's
🔴 / 🟡 / 🟢 tiers. Findings tagged `for-orchestrator-synthesis` feed your
reasoning — coverage maps, convergence detection, "what got reviewed" — but
do not get repeated verbatim in the chat output. Findings tagged
`for-automated-gate` drive the rubric status line and any escalation
blocks; they are referenced once (not duplicated as prose bullets) and link
to the source critique. If a critic tagged everything `for-author`, note
that in your synthesis as a calibration gap rather than treating it as
signal.

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

| # | Finding | Domain | Location | Legibility-target | Status |
|---|---|---|---|---|---|
| R1 | [Description] | [Security/Performance/etc.] | `path/to/file:42` | for-author | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or author note.

| # | Finding | Domain | Source | Legibility-target | Status | Author note |
|---|---|---|---|---|---|---|
| A1 | [Description] | [Domain] | [Source, e.g., "Security + Performance", "Fact-check"] | for-author | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Legibility-target |
|---|---|---|---|
| C1 | [Suggestion] | [Which critic] | for-author |

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.

| Item | Verdict | Source | Legibility-target |
|---|---|---|---|
| [Description] | ✅ Confirmed | [Which agent] | for-orchestrator-synthesis |

---

## ⏭️ Skipped Core Critics

Core critics downgraded by the Stage 1.5 critic gate (diff-shape skip and/or absence of
corroborating fact-check evidence). This section makes coverage limits auditable across runs.

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | Diff is copy-only with no logic changes | `git diff --stat` shows only `docs/*.md` changes |

If no critics were skipped, replace the table with the single line: "All core critics ran;
no skips applied." The heading must still appear so skips remain auditable across runs.

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry an author note. 🟢 items are optional.
```

**Legibility-target column:** Carry forward the tag each critic placed on
the source finding (see [taxonomy](../patterns/orchestrated-review.md#legibility-target-tagging)).
Typical mapping: 🔴 / 🟡 / 🟢 rows are `for-author`; ✅ rows are
`for-orchestrator-synthesis`. `for-automated-gate` findings (e.g., the
security-reviewer HALT-ESCALATE pattern) live in the escalation block
above the rubric, not in these tables — they reference the source
critique once instead of being duplicated as a row.

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
  Exception: opt-in chain mode for a named critic pair (see
  [Stage 2 dispatch modes](#stage-2-dispatch-modes)) deliberately feeds the
  upstream critique into the downstream prompt for that pair only.
- **Be honest about convergence.** Don't present a minority finding as consensus. Convergence
  detection is semantic (overlapping concern in the same code region), not mechanical.
- **The rubric is designed for re-runs.** When the author fixes issues and runs again, the
  pipeline re-runs and updates each status.
- **Contextual critics are advisory.** Their findings go to Consider tier and never block merge.
- **Fact-check report size management.** If the report exceeds 200 lines, paste only the
  "Claims Requiring Attention" summary (Incorrect, Stale, Mostly Accurate) into critic prompts.
