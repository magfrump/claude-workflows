---
name: code-review
description: >
  Orchestrate a comprehensive code review by coordinating code-fact-check and code critic agents
  (security-reviewer, performance-reviewer, api-consistency-reviewer) in parallel, with optional
  contextual critics (architecture-review, test-strategy, tech-debt-triage, dependency-upgrade,
  ui-visual-review) auto-selected based on the diff. Follows a 3-stage pipeline: code fact-check →
  critic agents → synthesis. Produces a freeform chat summary plus a structured code review rubric
  with red/amber/green status tracking. Use this skill when the user asks to "review this code",
  "review this PR", "review my changes", "review this diff", "full code review", "run all critics",
  "code review this branch", or wants a multi-perspective review of code changes. Default to this
  orchestrator whenever a PR is being prepared, opened, or evaluated — it composes security,
  performance, API consistency, and (when triggered) architecture into a single pass. Also use
  when the user asks for two or more of those concerns together. For a deliberately narrow review
  on a single concern (just security, just performance), invoke the standalone critic skill
  directly instead.
when: User requests a full code review or PR review
---

## Dependencies

Orchestrates the sub-skills below. Ensure they exist in `skills/` before use.

**Required (always run):**
- `code-fact-check.md` — verifies factual claims in code comments, docs, and commit messages.
  Runs as **k=3 parallel replicates** merged most-severe-wins; the rationale lives in one
  place — Stage 1's **Why three** — do not restate it elsewhere.

**Core critics (always run):**
- `security-reviewer.md` — security design review
- `performance-reviewer.md` — performance analysis
- `api-consistency-reviewer.md` — API surface consistency

**Structural critic (auto-selected, may produce blocking findings):**
- `architecture-review.md` — triggered when diff changes module structure, public APIs of internal modules, data models, or cross-cutting concerns. Unlike the advisory contextual critics below, this critic declares its own severity-to-rubric mapping (Structural → 🔴, Coupling → 🟡, Minor/Informational → 🟢) and counts toward the convergence-escalation rule.

**Contextual critics (auto-selected based on diff, advisory only — findings go to 🟢 Consider):**
- `test-strategy.md` — triggered when source changes lack corresponding test changes
- `tech-debt-triage.md` — triggered on large diffs (>10 files or >500 lines)
- `dependency-upgrade.md` — triggered when dependency manifests change
- `ui-visual-review.md` — triggered when diff touches UI rendering code

> On bad output, see guides/skill-recovery.md

# Code Review Orchestrator

You are an orchestrator. Coordinate a multi-stage review of code changes by dispatching work to specialized sub-agents, then synthesizing their output.

Follows the [orchestrated review pattern](../../patterns/orchestrated-review.md).

Produce two deliverables: a freeform chat summary and a structured code review rubric document.

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

6. You MUST read `docs/reviews/override-log.md` during Step 3.5 of "Before You Begin" and
   surface every matching row in both deliverables. The "no prior overrides matched this
   diff" sentinel is not optional — emit it explicitly when the scan returns nothing so
   the log cannot become write-only. See [Override-Log](#override-log) for capture format.

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

Do not paste the full diff into agent prompts. Pass the scope specification so each agent runs its own `git diff` — this avoids context budget issues with large diffs.

**Partial-scope reviews must label out-of-scope sibling work.** When the scope is narrower than the full branch changeset (`--range`, `--staged`, `--files`, or a `--pr` covering part of a larger branch), every critic prompt must state: (a) that commits/files on the branch outside the scope are *already committed — context only, not under review*, and (b) that before flagging work as "missing", the critic must check the rest of the branch (`git log main..HEAD`, `git diff main...HEAD -- <path>`) for it. The label marks provenance, not trustworthiness — sibling context stays under normal scrutiny (a control *deleted* in a sibling commit is still a finding); only "this work is missing" claims are gated on checking it. This rule is validated, not speculative: the 2026-07-30 diff-only baseline sweep (`docs/working/experiment-cross-model-review-2026-07-30.md`, Result 5) showed unlabelled single-commit scope made three of four model families flag work as missing that sat in sibling commits (6 of 11 replicates, all at High), and the 2026-07-31 re-run under the label + sibling context (`docs/working/experiment-stage1-fp-kill-2026-07-31.md`, decision 021) reduced that FP class to 0/8 — while cross-family agreement on real issues rose among the Sonnet/Gemini/Sol pairs on the other cell. The default full-branch scope (`git diff main...HEAD`) needs no label — the whole changeset is under review.

#### Large diff triage (~1000+ lines)

Diffs exceeding roughly 1000 lines may exceed practical review capacity in a single pass. When the diff is this large, split the review into multiple passes by subsystem or file group:

1. **Prioritize highest-risk files first:** auth, data handling, public API surfaces, and
   trust boundary changes. Run the full pipeline on these files before lower-risk ones.
2. **Group remaining files by subsystem** (e.g., database layer, UI components, utilities)
   and review each group as a separate pass with its own scope (`--files`).
3. **Note the triage in your plan summary** so the user sees which files were reviewed in
   which pass and why the ordering was chosen. This makes split reviews auditable.

Check diff size early via `git diff --stat` — if the line count crosses the ~1000-line threshold, propose the split to the user before launching Stage 1.

Separately from total diff size, watch the per-file churn ratio. When any single file in the diff has more than 40% of its lines changed (compute as changed lines ÷ post-change file length from `git diff --stat`), treat that file's review as greenfield — evaluate architecture, naming, and module boundaries on the resulting code rather than against the diff. Diff comparison loses signal at high churn ratios because most lines moved or were rewritten. Apply this per file, not per pass: other files in the same diff may still warrant standard diff-level review.

### Step 2: Capture PR intent

Critics scope findings better when they know what the PR is trying to accomplish. Capture once here and reuse in Stage 2.

- **If `--pr <N>` was passed:** Run `gh pr view <N> --json body --jq .body` to fetch the PR
  description verbatim. If the body is empty, fall back to the branch-purpose summary below.
- **Otherwise:** Compose a 2-line branch-purpose summary from recent commits. Read commits
  on the current branch via `git log main..HEAD --pretty=format:"%s%n%b" --reverse` and
  write a 2-line summary describing the goal of the branch — what is changing and why. If
  the branch has no commits ahead of main, use the most recent commit subject.

Hold the resulting text as `<pr-intent>` for Stage 2. Paste it verbatim under a `## What this PR is trying to accomplish` heading in each critic's prompt so critics can scope findings to stated intent.

### Step 3: Surface prior review findings (optional)

If the diff touches files that appear in a prior `docs/reviews/*.md` report from the last 30 days (detect via `git log --since="30 days ago" -- docs/reviews/` and intersect those reports' `Location:` paths with the changed-file list), lift the **Must-Fix** rows whose locations still apply and hold them as `<prior-findings>` for Stage 2. Paste them verbatim under a `## Prior review findings (advisory — worth checking, not verdict input)` heading in each critic's prompt so recurring issues are flagged explicitly rather than re-discovered. Treat them as hints about where to look — critics MUST NOT confirm them as findings or feed them into verdicts. Skip silently if no matching prior reports exist. (Extends the within-PR cross-iteration contrastive prompt in `workflows/pr-prep.md` step 3d to across-PR memory.)

### Step 3.5: Scan the override log for prior decisions matching the current diff

Read `docs/reviews/override-log.md` in full **before** rendering any findings. (Create the file if it does not yet exist using the skeleton in `docs/reviews/override-log.md` — the first override row landing in this run is itself capture, not just consumption.) For each row in the log's entry table, decide whether it applies to the current diff by checking, in order:

1. **Location match.** The `Finding` cell records a `path/to/file:line` location. If the file is in the current diff and the line is within ±20 lines of a changed hunk, the entry is a candidate.
2. **Category match.** If no location match, but the finding's category (security/auth, performance, API consistency, lint-style Nit, etc.) overlaps a critic that is about to run AND a file in the same subsystem is touched, the entry is a candidate.
3. **Substantive match.** If the wording of `Finding` describes substantively the same claim a critic is likely to surface on the current diff (e.g., "missing null check at $function" recurring in a refactor of `$function`), it is a candidate even without a location or category hit.

Hold every matched row as `<considered-overrides>` for Stage 3. Each entry MUST be surfaced in both deliverables (see Deliverable 1's `### Considered overrides` section and Deliverable 2's `Considered overrides` column / explicit "none matched" note). The log is not write-only: silent omission of a matched override is a calibration failure and a stage-3 self-check must catch it before publishing.

If the override log is empty or contains no rows that match the current diff, record the negative result explicitly (`No prior overrides matched this diff.`) — the absence statement is part of the contract that prevents the log from being write-only.

This step is **read-only with respect to the log** during the run. New overrides — produced when a human reviews this run's output and downgrades or upgrades a finding — are appended to `docs/reviews/override-log.md` as a follow-up step (see [Capturing new overrides](#capturing-new-overrides) below), not during dispatch.

### Step 4: Known critic roles

The orchestrator uses a fixed taxonomy of skills. Do not scan `skills/*.md` at runtime — use the lists below. (If a listed file doesn't exist, skip it and note the gap in your plan summary. If the user references a skill not listed here, they can include it via `--include`.)

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

**Structural critic (auto-selected in Step 5, uses its own severity mapping):**
- `architecture-review.md` — unlike the advisory contextual critics, architecture-review
  declares its own severity-to-rubric mapping (Structural → 🔴, Coupling → 🟡, Minor /
  Informational → 🟢). Honor that mapping; do not flatten its findings to advisory.

**Not applicable to code review (skip):**
- `fact-check.md`, `cowen-critique.md`, `yglesias-critique.md`

### Step 5: Auto-select contextual critics

Run a quick analysis of the diff to determine which contextual critics to include. Use the table below — check each row's diff characteristic and invoke the critic if it matches.

| Diff characteristic | Critic to invoke | Rationale |
|---|---|---|
| Source files changed (`src/`, `lib/`, etc.) without corresponding test file changes (`test/`, `tests/`, `__tests__/`, `*_test.*`, `*.test.*`) | `test-strategy` | Untested source changes are the highest-risk gap a review can catch. |
| Dependency manifests changed (`package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `Gemfile`, `pyproject.toml`, `pom.xml`, or similar) | `dependency-upgrade` | Dependency changes carry supply-chain, compatibility, and licensing risk that general critics miss. |
| Large diff: >10 files changed OR >500 added/removed lines (check via `git diff --stat`) | `tech-debt-triage` | Large changes are where debt accrues unnoticed; a dedicated pass catches structural issues. |
| Diff touches UI rendering code: JSX/TSX with className or style props, CSS/SCSS files, HTML templates, C#/Unity UI components (Canvas, RectTransform, ScrollRect, UI namespace), Vue/Svelte templates, or files with Tailwind utility classes. Trigger is presence of visual/layout code, not file extension alone. | `ui-visual-review` | Visual regressions are invisible to text-based critics; this critic catches layout, overflow, and sizing issues. |
| Diff changes module structure (new modules, renames, moves, package/directory layout), public APIs of internal modules, data models (schemas, DTOs, persisted contracts, message formats), or cross-cutting concerns (DI wiring, middleware, auth pipelines, logging/tracing setup, caching layers, error-handling pipelines). Skip when the diff only modifies implementation inside an existing module without touching its public surface. | `architecture-review` | Structural drift compounds silently; this critic catches dependency-direction violations, module-boundary breaches, and coupling problems that the per-concern critics miss. |

**How to check:** For each row, scan the diff file list and content. Multiple rows can match simultaneously — invoke all matching critics. If no rows match, no contextual critics run.

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
- Total agent count (3 fact-check replicates + N critics)

Keep this brief — a short paragraph.

---

## The Pipeline

### Between-stage status banner

After each between-stage handoff (end of Stage 1, end of Stage 2), emit a single one-line status banner directly in the chat so the user can judge progress and decide whether to interrupt before the next stage launches.

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

> Stage 1 (fact-check, k=3) complete: 3 Incorrect findings, 1 Stale, verdict agreement 10/12 clusters — launching 4 critics in parallel (security, performance, api-consistency, test-strategy).
>
> Stage 2 (critics) complete: 4/4 critics returned (12 findings total), dispatch mode: parallel — synthesizing into rubric and chat summary.

**Worked example (chain mode opted in via `--chain security→api-consistency`):**

> Stage 1 (fact-check, k=3) complete: 3 Incorrect findings, 1 Stale, verdict agreement 10/12 clusters — launching 4 critics: 2 in parallel (performance, test-strategy) + chain security→api-consistency.
>
> Stage 2 (critics) complete: 4/4 critics returned (12 findings total), dispatch mode: parallel + chain (security→api-consistency) — synthesizing into rubric and chat summary.

**Scope:** The banner is emitted *only* between stages. Do **not** emit a banner after Stage 3 — Stage 3's chat synthesis is itself the user-facing output, and a "Stage 3 complete" banner would duplicate or compete with it.

### Stage 1: Code Fact-Check (k=3 replicated)

Spawn **three** agents with the code-fact-check skill, in parallel, on **byte-identical
prompts** — same skill text, same scope spec, same instructions, differing only in the
output path each is told to write.

**Why three.** A fact-check **Incorrect** verdict is one of the two verdict-driven
blocking channels (state doc §1.0: fact-check Incorrect or api-consistency Breaking; the
[Unified Severity Mapping](#unified-severity-mapping) lists each critic's native 🔴 band) —
and the only one reachable by documentation-class findings. It is also the least stable
judgment in the pipeline: on identical input, the same comment defect was rated
**Incorrect** by one run and **Mostly Accurate** by another, flipping the same finding
between 🔴 and 🟡 (`docs/thoughts/code-review-evaluation-state.md` §1.1, Result 14a).
A single sample of that judgment is a coin flip carrying merge-blocking authority.
Replication converts it into a measured distribution.

For each of the three replicate agents:

1. Read the full contents of `skills/code-fact-check/SKILL.md`
2. Paste those contents directly into the Agent tool prompt (sub-agents cannot read your files)
3. Include the scope specification (e.g., "Review files changed on the current branch relative
   to main using `git diff main...HEAD`"). If the scope is partial (`--range`, `--staged`,
   `--files`, or a partial `--pr`), also include the labelling block required by Step 1's
   partial-scope rule — the "already committed — context only, not under review" statement and
   the check-siblings-before-flagging-missing directive apply to fact-check replicates too.
3b. Compose **one rich shared brief** and include it verbatim in all three prompts: skim
   the diff and write a "claims that particularly need checking" list — the specific
   comments, docstrings, and commit-message claims in this diff that carry the most
   verdict weight — with an explicit directive to **verify each claim against the code
   that actually exercises it (callers, fetch/consume sites, config that gates it),
   not only the file the claim sits in**. Uniformity constrains *variation between
   replicates*, never brief quality: the MD1-R1 replication
   (`docs/working/experiment-md1-r1-replication-2026-07-30.md`) measured what happens
   when orchestrators read the uniformity clause as license for lean generic prompts —
   0/9 replicates reached the cross-file evidence that three separate single-agent
   (k=1) runs had each found, 3 runs out of 3 (their briefs independently authored;
   two rich, one lean). k=3 of a weak brief is a weaker instrument than k=1 of a
   strong one; most-severe-wins cannot merge what no replicate found.
4. Instruct the agent to save its report as `docs/reviews/code-fact-check-report-r<N>.md`
   (N = 1, 2, 3), with a `Commit: <current HEAD short SHA>` line at the top. This
   per-replicate path is the **only** permitted difference between the three prompts —
   anything else varying would confound the disagreement measurement. (The rich shared
   brief of step 3b is identical across replicates, so it does not violate this clause.)

   **Stale-replicate guard:** before dispatching, delete or overwrite any existing
   `docs/reviews/code-fact-check-report-r*.md` whose `Commit:` line does not match the
   current HEAD — these directories are git-tracked, so a fresh worktree inherits prior
   branches' replicates, and downstream steps that glob `r*.md` would silently read
   another run's observations as this run's (the decision-25 rubric-selection failure
   class). Every later consumer of the replicate reports must match them by `Commit:`,
   never by glob alone. A replicate report with **no** `Commit:` line is treated as
   stale (delete it too) — missing provenance is not a pass.
5. Require the agent to tag every claim with a **Legibility-target** field
   (`for-author`, `for-orchestrator-synthesis`, or `for-automated-gate`) per
   the [legibility-target tagging](../../patterns/orchestrated-review.md#legibility-target-tagging)
   spec. Default mapping for fact-check claims: Incorrect / Stale / Mostly
   Accurate → `for-author` (the author needs to fix or update); Verified /
   Unverifiable → `for-orchestrator-synthesis` (orchestrator uses these for
   coverage and convergence, doesn't need to surface verbatim).
6. Require the agent to append a **Goal-Alignment Note** at the end of its report and chat
   summary using the canonical form from
   [`patterns/orchestrated-review.md`](../../patterns/orchestrated-review.md):

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
7. Launch via the Agent tool with `subagent_type: "general-purpose"` — all three replicates
   in a single message so they run in parallel and cannot see each other's output.

**CHECKPOINT:** Wait for all three replicate agents to return. Verify you received at least
**two** substantive reports — with fewer than two, no disagreement measurement is possible
and the merged verdict degenerates back to a single sample. If only one replicate returned,
tell the user and ask how to proceed; if two returned, proceed but record `k=2 (one
replicate failed)` in the merged report's `**Replication:**` header field and the Stage 1
banner. A report is *substantive* when it parses against the code-fact-check schema and
either contains ≥1 claim section or explicitly records `**Total claims checked:** 0` with
the no-checkable-claims rationale — an empty or truncated file is not substantive.

#### Merging replicate verdicts (most-severe-wins)

Produce the canonical `docs/reviews/code-fact-check-report.md` yourself by merging the
replicate reports. This is mechanical collation, not analysis — you are combining verdicts
the replicates already produced, never adding claims or evidence of your own (Mandatory
Execution Rule 1 still stands).

1. **Cluster claims across replicates.** Two claims are the same claim when they cite the
   same file, overlapping line ranges (±5 lines), and assert substantially the same thing.
   Clustering is semantic — replicates word the same claim differently; match on
   (file, line-range, claim substance), not on string equality.
2. **Take the most severe verdict any replicate assigned** to the cluster. Severity order,
   most severe first: `Incorrect (high confidence)` > `Incorrect (medium confidence)` >
   `Incorrect (low confidence)` >
   `Stale` > `Mostly Accurate` > `Unverifiable` > `Verified`. Majority vote is explicitly
   the wrong aggregator here: a defect one replicate *proves* Incorrect is Incorrect
   regardless of what the other two concluded, and the observed failure mode is
   under-calling, not over-calling (state doc §1.1). Carry the evidence and reasoning from
   the replicate that assigned the winning verdict.
3. **Record per-replicate verdicts on every merged claim, inside the standard schema.**
   The merged report keeps the code-fact-check report format exactly — `# Code Fact-Check
   Report` title, the five header fields, and per-claim `## Claim N:` sections with the
   five mandatory bolded fields — so `test/skills/code-fact-check-format.bats` gates it
   unchanged (a merged report with no `## Claim N:` sections makes that suite skip
   silently, which is a gate abdicating, not passing). On top of the standard schema:
   - `**Verdict:**` carries the plain winning verdict from the five-value enum
     (`Incorrect`, `Stale`, …) and `**Confidence:**` the winning replicate's confidence.
     The severity-order tokens in step 2 (`Incorrect (high confidence)` etc.) are ordering
     vocabulary for the merge decision only — never written into a `**Verdict:**` field.
   - Each claim adds a sixth bolded field `**Replicate verdicts:**
     r1=<verdict> · r2=<verdict> · r3=<verdict>` (`—` for a replicate that did not
     surface the claim; a claim surfaced by only one replicate keeps that replicate's
     verdict and its Replicate-verdicts line ends with ` · single-replicate detection`).
   - The header MUST carry, in addition to the five standard fields, a bolded
     `**Commit:** <reviewed HEAD short SHA>` line (≥7 chars) and a bolded
     `**Replication:** k=3` field (or `**Replication:** k=2 (one replicate failed)` on
     the degraded path). These two are a parsed contract, not decoration: Gate 1h in
     `scripts/self-improvement.sh` reads exactly these field names to detect stale
     reports and degraded replication — a merged report missing either is advisory-flagged
     as commit-unknown / single-sample even when the run was a genuine k=3.
4. **Report the disagreement rate.** End the merged report with a `## Verdict stability`
   section: total clusters, clusters where all reporting replicates agreed, clusters where
   verdicts disagreed (list them with their per-replicate verdicts), and the resulting
   agreement rate. This turns the blocking channel's noise floor from an invisible coin
   flip into a tracked metric (state doc open question #2). If cumulative measurements
   across runs show ≥90% verdict agreement on a ≥20-claim sample, k can drop to 2 — that
   is §1.1's stated falsifier; record the observed rate either way.

Everything downstream — the Fact-Check Gate, Stage 1.5 critic gating, critic prompts, the
Confirmed-Good cross-check, and the severity mapping — consumes the **merged** report. The
per-replicate reports stay on disk for audit and for the Confirmed-Good cross-check's
observation scan.

After producing the merged report, emit the between-stage status banner per the format spec above (e.g., `Stage 1 (fact-check, k=3) complete: <counts, incl. verdict agreement rate> — <next action>`). Emit it before the Fact-Check Gate so the user sees stage progress even if the gate pauses for input.

### Fact-Check Gate

After producing the merged fact-check report, check whether any merged claims carry the verdict **Incorrect** at **high confidence** — i.e., any replicate assigned it, per most-severe-wins. If so:

1. **Pause before launching critics.** Present the high-confidence Incorrect findings to the
   user — specifically the claims, what the evidence shows, and the confidence level.
2. **Ask the user how to proceed.** Offer three options:
   - **Continue** — proceed to Stage 2 as-is (critics will see the fact-check findings)
   - **Fix first** — the user wants to address factual issues before running critics
   - **Skip critics** — the user only needed the fact-check

If the user passed `--no-gate`, or if there are no high-confidence Incorrect findings, skip this gate and proceed directly to Stage 2.

### Stage 1.5: Critic gating

After the Fact-Check Gate (and only if the user did NOT pass `--all-critics`), narrow the core-critic set down before launching Stage 2. This stage applies two gating signals, ordered by when their input becomes available:

- **First gate — diff-shape.** Already partially applied: Step 4 used the diff to select
  contextual critics pre-Stage-1. Now extend the same diff-shape logic to the core
  critics via the skip table below — `git diff --stat` and spot-checked diff content are
  the inputs.
- **Second gate — evidence (new).** The fact-check report is now in hand. Use it to
  confirm that each remaining core critic has *some* corroborating evidence in its
  domain. If the only thing keeping a critic alive is "we always run it," and Stage 1
  surfaced nothing in its domain, downgrade it.

The default is **run all core critics** — skipping is conservative. The cost of running an extra critic is small; the cost of a missed finding is large. If you are uncertain whether a signal applies, do not skip.

**Boring version:** consult fact-check to optionally *downgrade* critics. Do not re-derive the critic set from scratch — the set entering Stage 1.5 is whatever survived Step 4 selection + user overrides, and Stage 1.5 only narrows it further. Stage 1.5 never *promotes* a critic.

This section runs silently — emit no status banner. The Stage 1 banner already fired before the Fact-Check Gate, and the Stage 2 banner fires after critics return.

#### Evidence consultation (lead signal)

For each remaining core critic, ask: did Stage 1 surface *any* claim — at any verdict, including Accurate or Unverifiable — that touches this critic's domain? And does the diff (which fact-check scoped over) actually contain files in that domain?

| Critic | Domain heuristic — corroborating evidence is any of |
|---|---|
| `security-reviewer` | A fact-check claim or diff hunk touching auth, crypto, input handling, file I/O, network calls, serialization, error/exception messages, URL/path construction, or any string literal in an HTML/SQL/shell/regex context. |
| `performance-reviewer` | A fact-check claim or diff hunk touching loops, queries, data-structure choice, hot paths, complexity claims (e.g., "O(n)"), caching, batching, or dependency add/upgrade. |
| `api-consistency-reviewer` | A fact-check claim or diff hunk touching exported function signatures, schema/contract definitions, route handlers, public CLI flags, module exports, or published config keys. |

If a critic's domain heuristic finds **zero corroborating evidence** in both the fact-check report and the diff, downgrade the critic to skip-with-note. Record the skip in the rubric's `## ⏭️ Skipped Core Critics` section with the signal cited as "no fact-check claims or diff content in domain."

If *any* corroborating evidence exists — even a single Accurate fact-check claim, or a single diff hunk touching the domain — run the critic. The diff-shape skip table below still applies as a complementary signal, but evidence consultation has priority: a fact-check finding in the domain forces the critic to run regardless of how copy-only the diff appears.

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

For every core critic you skip, you MUST record it in the rubric under the `## ⏭️ Skipped Core Critics` section (see Deliverable 2 below) with the critic name, the skip reason, and the specific signal observed (e.g., `git diff --stat` output excerpt or the fact-check finding cited). Also reference skips in the chat synthesis scope summary so the user sees coverage limits before reading findings.

If `--all-critics` was passed, skip this step entirely; all core critics run.

### Stage 2 dispatch modes

Stage 2 has two dispatch modes. **Default is parallel** — every critic runs simultaneously and they do not see each other's output. Chain mode is **opt-in via `--chain <pair>`** and applies only to the named pair; all other critics still run in parallel alongside the chain.

The orchestrator decision is one line: if the user passed `--chain <pair>`, run that pair sequentially with the upstream critic's findings injected into the downstream critic's prompt; otherwise, dispatch every selected critic in parallel.

**State the chosen mode in the Stage 2-complete (synthesis-introducing) banner** so the reader knows which dispatch shape produced the findings (see [Between-stage status banner](#between-stage-status-banner) for format).

#### When to chain

Chain only when an upstream critic's findings genuinely change the downstream critic's scope — i.e., reading the upstream critique would let the downstream critic narrow its inspection or sharpen its priorities. If the downstream critic would do the same scan either way, parallel is strictly faster and equally informative; do not chain by default.

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

Chain mode adds one round-trip of latency to Stage 2 (the downstream critic cannot start until the upstream critic returns). It is worth that cost only when the trigger applies — without the trigger, the downstream critic gains no useful narrowing and the chain just slows Stage 2 down.

### Stage 2: Critic Agents

Now — and ONLY now — spawn critic sub-agents using the Agent tool.

**DO NOT write critiques yourself. You MUST dispatch each critique to a sub-agent via the Agent tool.** This is non-negotiable.

For each critic agent, you MUST:

1. Read the full contents of that critic's skill file (e.g., `skills/security-reviewer/SKILL.md`)
2. Paste those contents directly into the Agent tool prompt
3. Include the scope specification so the agent runs its own `git diff`. If the scope is
   partial (`--range`, `--staged`, `--files`, or a partial `--pr`), also include the labelling
   block required by Step 1's partial-scope rule
4. Include the PR intent captured in "Before You Begin" Step 2, prepended under a
   `## What this PR is trying to accomplish` heading so the critic can scope findings to
   stated intent. If Step 3 surfaced `<prior-findings>`, paste them verbatim under a
   `## Prior review findings (advisory — worth checking, not verdict input)` heading
   immediately after the intent block; otherwise omit this heading entirely.
5. Include the fact-check results. If the fact-check report is longer than 200 lines, include
   only the findings rated Incorrect, Stale, or Mostly Accurate — skip Verified claims to
   save context budget.
6. Instruct the agent to save its critique as `docs/reviews/{critic-name}-review.md`
7. Require the agent to tag every finding with a **Legibility-target** field
   (`for-author`, `for-orchestrator-synthesis`, or `for-automated-gate`) per
   the [legibility-target tagging](../../patterns/orchestrated-review.md#legibility-target-tagging)
   spec. The tag goes on the finding alongside Severity / Confidence:

   ```markdown
   **Severity:** High
   **Location:** `path/to/file.ext:42`
   **Evidence:** > const timeout = config.timeout;   ← verbatim from the cited lines
   **Confidence:** High
   **Legibility-target:** for-author
   ```

   The **Evidence** field is required on every finding that cites a location: one or
   more source lines copied *verbatim* from the cited file at the cited lines. See
   [Evidence grounding](#evidence-grounding) for why, and for the check you run on it.

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
   [`patterns/orchestrated-review.md`](../../patterns/orchestrated-review.md):

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
9. Launch via the Agent tool with `subagent_type: "general-purpose"` **and an explicit
   strong `model`** — see [Critic model selection](#critic-model-selection). Do not let
   critics inherit the session default.

### Critic model selection

Set `model` explicitly on every critic dispatch. Measured on this repo's and two other
repos' history (`docs/working/experiment-results-code-review-2026-07-29.md`, Results 7–9):

| Tier | Validated blocking defects recovered | Precision of its own findings |
|---|---|---|
| haiku | 0/6 | 0/2 — both findings were false positives |
| sonnet (generalist prompt) | 0/6 | 3/3 |
| sonnet (**this skill's prompt**) | 2/2 on the isolated case | — |
| opus | 3/6 | ~88% |
| fable | recovered a 🔴 row opus missed 2/2 | — |

Three rules follow:

- **Default to `opus` for critics.** It had the highest and most self-consistent
  blocking-defect recall.
- **Never run a critic on `haiku`.** Its clean verdicts are false attestations — in one
  run it explicitly praised code another critic flagged as defective. A weak reviewer
  reporting "no findings" is worse than no review, because the verdict carries assurance
  weight downstream.
- **`sonnet` is acceptable *only* with these role-skill prompts**, which closed most of
  the tier gap (0/2 → 2/2 on the isolated defect). It is not acceptable for ad-hoc
  generalist review.

**Diversity note.** Model tiers do not form a strict hierarchy: fable recovered a red-tier
finding that opus missed on both replicates, and opus found issues fable missed. When a
diff is high-risk and budget allows, dispatching the *same* critic twice on two different
frontier models and unioning the findings buys real coverage — the union is covering
disjoint blind spots, not just reducing sampling variance.

**Worked example — dispatch goal preamble with optional Project-state fields**

Each critic dispatch is prepended with the [goal preamble](../../patterns/orchestrated-review.md#goal-preamble). When the orchestrator has the upstream research/plan/checkpoint/handoff doc's Project state lead block, lift those facts verbatim into the optional sub-bullets under Current task. A filled example for the security critic in this pipeline:

```
User goal: Get a comprehensive code review on the current branch before opening a PR.
Current task: Run security design review on the diff between the current branch and main.
  - Branch: feat/auth-token-storage
  - Position in initiative: Step 2 of 4 in the auth-compliance epic; sibling branch feat/session-cleanup waiting on this review.
  - Blocked on: nothing
Success criterion: A markdown report saved to docs/reviews/security-review.md, structured per the security-reviewer skill.
```

If any of those facts isn't on hand, omit the corresponding sub-bullet rather than guessing — the fields exist to anchor the critic in real project context, not to be filled for completeness. Do not add other content to the preamble; everything else (scope spec, PR intent, fact-check excerpt, output path, tagging requirements) goes in the role-specific content below it.

**Launch ALL critic agents simultaneously** in a single message with multiple Agent tool calls. They must not see each other's output. **Exception:** when [Stage 2 dispatch modes](#stage-2-dispatch-modes) chain mode is active for a pair, the downstream critic is dispatched in a second message after the upstream critic returns; every other critic still launches in the first parallel batch.

**CHECKPOINT:** Wait for ALL critic agents to return results (including the downstream critic of any active chain). Count the results. Do you have the expected number? If yes, proceed to Stage 3. If not, tell the user what's missing.

After confirming the expected critic count, emit the between-stage status banner per the format spec above (e.g., `Stage 2 (critics) complete: <counts>, dispatch mode: <mode> — synthesizing into rubric and chat summary`). Emit it before launching Stage 3 so the user sees the handoff explicitly.

### Stage 3: Synthesize and Produce Outputs

You now have results from all sub-agents. NOW — and only now — produce your two deliverables.

**No banner after this stage.** Stage 3's chat synthesis (Deliverable 1) is itself the user-facing output. Do not prepend or append a "Stage 3 complete" banner — it would duplicate the synthesis. Banners are between-stage progress indicators, not synthesis output.

#### Goal-alignment scan (run before producing deliverables)

Before writing the chat synthesis, scan the **Goal-Alignment Note** appended by each sub-agent (see [`patterns/orchestrated-review.md`](../../patterns/orchestrated-review.md)). Collect:

- Any sub-agent whose `Answered:` value is `no` or `partial` — record the agent name
  and the one-phrase reason verbatim.
- Any non-trivial `Out of scope:` item — anything other than the literal sentinel
  `none`. Record the agent name and the bullet text.
- Any non-trivial `Escalate:` item — anything other than the literal sentinel
  `nothing`. Record the agent name and the bullet text.

If a sub-agent omitted the note entirely, treat that as a `partial` entry with reason "missing goal-alignment note" so the gap is still surfaced.

The collected items feed the `### Coverage and Escalations` section of the chat synthesis below. They do not modify the rubric — coverage is a chat-synthesis concern.

#### Confirmed-Good cross-check (required before producing deliverables)

Assemble the candidate `✅ Confirmed Good` rows, then run each one through
[Confirmed Good is a claim, not an output](#confirmed-good-is-a-claim-not-an-output):
Evidence present and grounded, enumeration behind any universally quantified claim, and no
observation anywhere in the merged fact-check report **or any current-run per-replicate
report** (matched by `Commit:` line, per the stale-replicate guard) inconsistent with it —
an observation recorded only by a replicate whose verdict lost the severity contest still
counts. To keep this from becoming four full re-reads at Stage 3, build the observation
index once during the Stage-1 merge (file/symbol/directive touched per observation) and
consult that index here. Rows that fail are
dropped (ungrounded) or moved to 🟡 Must Address as `Contested` (contradicted) per that
section. Run this **before** writing either deliverable — it changes the rubric's contents,
so it cannot be a post-hoc pass over a published table.

#### Soundness-contradiction cross-check (required before producing deliverables)

Immediately after the Confirmed-Good cross-check, sweep every critic report — contextual
critics included — for findings that meet the
[Soundness-Contradiction Channel](#soundness-contradiction-channel) trigger: a stated
intent quoted verbatim with `path/to/file:line`, the code's actual mechanism quoted or
reconstructed with `path/to/file:line`, and the report's own reasoning that the mechanism
defeats or inverts the stated intent. Each qualifying finding is placed in (or moved to)
`## 🟡 Must Address` per that section. Run this **before** writing either deliverable —
like the Confirmed-Good cross-check, it changes the rubric's contents, so it cannot be a
post-hoc pass over a published table.

#### Contrastive note (optional, capture during synthesis)

Pick one finding the panel caught well, plus one likely-related issue you suspect was missed (sources: goal-alignment notes, escalations, or your own scan of the diff). State both in 1–2 lines, then propose one concrete prompt-refinement candidate — an added instruction, sharpened heuristic, or new check for a critic skill — that would have closed the gap on the next run. Skip if no genuine contrast is available; do not invent one. Capture only — no feedback pipeline consumes this yet.

---

## Deliverable 1: Chat Synthesis

Present this directly in the chat. It should be self-contained — assume the user has NOT read the individual agent reports.

### Structure the chat synthesis as:

**Scope summary:** What was reviewed — branch, files, diff size.

### Considered overrides

Surface every row collected as `<considered-overrides>` in Step 3.5. For each match, list:

- the override's `PR ref` and `Date`,
- the finding it applied to (with `path/to/file:line`),
- the `Original verdict → Override verdict` shorthand, and
- the `Reason` recorded by the prior reviewer.

Then, for each, state whether the current run's finding (if any) **inherits** the prior call, **departs** from it (and why), or is **not applicable** (different code, same location coincidentally). If a critic surfaced a finding that matches a prior `Won't-Fix` override and you are still flagging it as Must-Fix, explain the delta — new evidence, scope change, or you believe the prior call was wrong. Re-arguing a settled call without acknowledging it is the failure mode this section exists to prevent.

If Step 3.5 found no matching rows, render the section with the single line: "No prior overrides matched this diff." The heading must still appear so absence is auditable across runs.

### Coverage and Escalations

Surface the items collected in the Goal-alignment scan above so the user sees coverage limits before reading findings:

- For each sub-agent that answered `no` or `partial`: list the agent name and the
  one-phrase reason.
- For each non-trivial `Out of scope:` bullet: list the agent name and what was set
  aside.
- For each non-trivial `Escalate:` bullet: list the agent name and what the
  orchestrator should action separately.

If the scan surfaced nothing, render this section with a single line: "All sub-agents fully addressed their scope; no out-of-scope or escalate items." The heading must still appear so the section is auditable across runs.

**Factual issues:** What the code fact-check found. Group into: claims that need fixing (Incorrect), claims that need updating (Stale, Mostly Accurate), and claims that are solid (Verified).

**Cross-critic findings:** Highest signal. Issues raised independently by 2+ critics targeting the same code region or overlapping concern. These indicate structural problems that manifest across multiple dimensions (e.g., a pattern that's both a security risk and a performance problem). Convergence detection is semantic — same file region plus overlapping concern — not mechanical keyword matching.

**Per-domain findings:** Organize remaining findings by severity within each critic domain. Lead with Critical/High, then Medium, then Low/Informational.

**Contextual critic findings:** If contextual critics ran, present their findings separately as advisory input. These inform but do not block.

**What the code gets right:** Strengths that critics identified. The author needs to know what to preserve during revisions.

**Failure-mode escalation:** Count the distinct new failure modes named across critic findings — the per-finding failure-mode phrase that `for-author` findings already carry per the [orchestrated-review pattern](../../patterns/orchestrated-review.md#legibility-target-tagging) (location, evidence, attack scenario or failure mode where applicable, recommendation). Dedupe overlapping concerns in the same code region to a single mode so the count tracks distinct modes, not finding multiplicity. If >=3 new failure modes are flagged, recommend `/pre-mortem` on the diff for narrative analysis; include the recommendation in the Chat Synthesis. The recommendation is advisory — the user decides whether to invoke `/pre-mortem`, not the orchestrator. The >=3 threshold is intentionally conservative to avoid escalation fatigue: at that count, independent failure modes start to suggest coupling and ordering between them that a narrative pre-mortem surfaces but per-critic flags miss. Below the threshold, the per-critic flags already carry the signal and a separate pre-mortem pass would be redundant.

**Actionable guidance:** Key changes to make, ordered by severity. Where multiple critics agree, note the convergence.

**Questions to clarify (if any sub-agent emitted them):** Scan each sub-agent's Goal-Alignment Note for the optional "Questions I would have asked" bullet. If one or more sub-agents emitted questions, surface them under a `### Questions to clarify` heading near the end of the chat synthesis, just before "Actionable guidance" or as a sibling subsection. De-duplicate: if multiple sub-agents asked semantically the same question, list it once and note the agreement (multiple sub-agents asking the same question is a strong signal that the prompt was under-specified). Attribute each question to the sub-agent that raised it. If no sub-agent emitted the bullet, omit the section entirely — do not invent placeholder questions.

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

**Recommended next action (required final line):** End the chat synthesis with this exact line so the user always sees a concrete next step:

> Recommended next action: [merge | fix red items then re-review | split PR | escalate to /pre-mortem | block on architectural review].

**Single-sample label (required when the run is clean):** when the derivation below lands
on `merge`, or the rubric status is `✅ PASSES REVIEW`, the line immediately *above*
`Recommended next action:` must read exactly:

> Single-sample review; absence of findings is not an attestation.

This is the same standing label the rubric status line carries (see
[The single-sample label](#the-single-sample-label)) and it is the whole of the hedging —
one line, no elaboration. Omit it entirely on any other next action: a review that already
tells the author to fix things is not being consumed as assurance.

Choose exactly one bracketed value. The choice is **mechanically derived from the rubric** per [Next-action derivation](#next-action-derivation) below — it is not a free-form judgment call, and the line must not hedge or list multiple options. The line is required even when the rubric is clean (rule 5 still applies). If the derivation ladder ever needs new rules, update the ladder first so the mapping stays the single source of truth.

#### Next-action derivation

Evaluate the rules top-to-bottom; the first matching rule wins. Inputs are the rubric the synthesis just produced (counts of 🔴 / 🟡 rows and which critics ran, including the `## ⏭️ Skipped Core Critics` section) and the diff size from `git diff --stat`.

1. **block on architectural review** — Either: (a) Step 5 auto-selected
   `architecture-review` but it did not produce a report this run (excluded via
   `--exclude architecture-review`, failed, or otherwise skipped), or
   (b) architecture-review ran and produced ≥1 🔴 Structural finding.
   Architectural questions are a wider conversation than a line-fix — rerun with
   architecture-review enabled, or address the structural finding in a separate
   design pass before any other action.
2. **split PR** — Total diff is >500 changed lines (added + removed per
   `git diff --stat`) AND ≥1 🔴 item exists (and rule 1 did not match). Large
   diffs combined with red findings multiply review risk per iteration; split
   before iterating on fixes.
3. **escalate to /pre-mortem** — 🔴 items span 3+ distinct critic domains (e.g.,
   security + performance + api-consistency), OR ≥3 🔴 items total. Systemic
   risk — invoke the `pre-mortem` skill before attempting line-level fixes,
   because the failure mode is likely architectural rather than a sum of
   independent defects.
4. **fix red items then re-review** — ≥1 🔴 item exists (and rules 1–3 did not
   match), OR 0 🔴 but >2 🟡 items are open without author notes resolving them.
   The label covers the general non-merge fix path; amber-heavy reviews land
   here because resolving the load through inline notes alone is impractical.
5. **merge** — 0 🔴 items AND ≤2 🟡 items. Rubric status is either
   ✅ PASSES REVIEW or a low-friction 🟡 CONDITIONAL PASS where amber items can
   be resolved with inline author notes during merge prep.

**Worked examples:**

- 0 🔴, 0 🟡 → rule 5 → `Recommended next action: merge.`
- 0 🔴, 1 🟡 → rule 5 → `Recommended next action: merge.`
- 0 🔴, 4 🟡 → rule 4 (>2 amber, no red) → `Recommended next action: fix red items then re-review.`
- 2 🔴 both in security, 200-line diff → rule 4 → `Recommended next action: fix red items then re-review.`
- 1 🔴 in security, 800-line diff → rule 2 → `Recommended next action: split PR.`
- 1 🔴 security + 1 🔴 performance + 1 🔴 api-consistency, 300-line diff → rule 3 (3 domains) → `Recommended next action: escalate to /pre-mortem.`
- 4 🔴 all in security, 200-line diff → rule 3 (≥3 reds total) → `Recommended next action: escalate to /pre-mortem.`
- 1 🔴 from architecture-review tagged Structural → rule 1 → `Recommended next action: block on architectural review.`
- Diff adds a new module; architecture-review excluded via `--exclude` → rule 1 → `Recommended next action: block on architectural review.`

**How to use legibility-target tags during synthesis:** Findings tagged `for-author` are the primary content of the chat synthesis and the rubric's 🔴 / 🟡 / 🟢 tiers. Findings tagged `for-orchestrator-synthesis` feed your reasoning — coverage maps, convergence detection, "what got reviewed" — but do not get repeated verbatim in the chat output. Findings tagged `for-automated-gate` drive the rubric status line and any escalation blocks; they are referenced once (not duplicated as prose bullets) and link to the source critique. If a critic tagged everything `for-author`, note that in your synthesis as a calibration gap rather than treating it as signal.

---

## Deliverable 2: Code Review Rubric

Save this as `docs/reviews/code-review-rubric-<YYYY-MM-DD>-<branch-slug>.md` (e.g.
`code-review-rubric-2026-07-29-feat-auth-tokens.md`), where `<branch-slug>` is the branch
name with `/` replaced by `-`. This is a structured, scannable document the author uses to
track code review resolution.

**Within one review-fix loop, keep updating the same file** — iterations 2 and 3 update
statuses in place, which is what the 🔴/🟡 `Status` columns are for. A *new* file is
created only when the date or the branch changes, i.e. when it is a genuinely different
review. This preserves in-loop status tracking while stopping each loop from destroying the
prior loop's findings.

Why date-stamped rather than overwritten: the rubric is the only durable record of what a
review actually surfaced. Overwriting it means the pipeline's own output history — the
substrate for calibrating critic precision, and for noticing that a finding was waived
rather than fixed — survives only in `git log -p`. Every other artifact this skill produces
is already date-stamped; the rubric was the inconsistent one.

**Use this exact format.** A worked example of the format below, kept in sync with it, is
`test/skills/code-review/rubric-current-format.md`; it is what
`test/skills/code-review-format-contract.bats` asserts against, so changes to the template
here must be mirrored there in the same commit.

```markdown
# Code Review Rubric

**Scope:** [branch/range] | **Reviewed:** [date] | **Status: 🔴 DOES NOT PASS** — [N] red item(s) unresolved

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | [Description] | [Security/Performance/etc.] | Critical | `path/to/file:42` | for-author | — _or_ `#123 Won't-Fix (override departed from — see chat)` | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or author note.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | [Description] | [Domain] | Medium | [Source, e.g., "Security + Performance", "Fact-check"] | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | [Suggestion] | [Which critic] | Low | for-author | — | 🟢 Open |

The **Status** column is the cheapest calibration instrument in this document. 🟢 is ~70%
of everything the pipeline emits, and it was the only tier with no disposition recorded —
so three quarters of the corpus was unadjudicatable after the fact and precision in the
advisory band could never be estimated. Mark each row `🟢 Open`, `Fixed`, `Won't-Fix`, or
`Deferred` as it is resolved; a `Won't-Fix` here should also become an override-log row.

---

## ↩️ Considered Overrides

Rows lifted from `docs/reviews/override-log.md` that matched the current diff per the
Step 3.5 scan. Each row records how the current run treated the prior call.

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `#123` / 2026-04-12 | Null check in `auth.ts:42` (security) | 🔴 Must-Fix → Won't-Fix | "test-only path; covered by guard upstream" | Inherited — not re-flagged. |

If no rows matched, replace the table with the single line: "No prior overrides
matched this diff." The heading must still appear so absence is auditable across runs.

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.
Every row carries `Evidence` and has passed the Confirmed-Good cross-check — see
[Confirmed Good is a claim, not an output](#confirmed-good-is-a-claim-not-an-output).

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| [Description] | ✅ Confirmed | `path/to/file:42` — "[quoted fragment]" _or_ the enumeration that establishes it (`rg -n "[pattern]" [scope]` → N matches, all [disposition]) | [Which agent] | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

Findings whose **Evidence** block could not be located at the cited location (after
basename resolution) per [Evidence grounding](#evidence-grounding). These are advisory
only: they may not be 🔴 or 🟡 and do not count toward convergence.

| # | Finding | Source | Cited location | Why unverified |
|---|---|---|---|---|
| U1 | [Description] | [Which critic] | `path/to/file:42` | No file matching `file` in repo |

If every finding's evidence checked out, replace the table with the single line: "All
findings' evidence resolved." The heading must still appear so the check is auditable.

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

**Legibility-target column:** Carry forward the tag each critic placed on the source finding (see [taxonomy](../../patterns/orchestrated-review.md#legibility-target-tagging)). Typical mapping: 🔴 / 🟡 / 🟢 rows are `for-author`; ✅ rows are `for-orchestrator-synthesis`. `for-automated-gate` findings (e.g., the security-reviewer HALT-ESCALATE pattern) live in the escalation block above the rubric, not in these tables — they reference the source critique once instead of being duplicated as a row.

### Evidence grounding

Before tiering, verify each finding's **Evidence** block against the file it cites.

1. Read the cited file at the cited line range.
2. Confirm the quoted text appears there (ignore leading/trailing whitespace).
3. **Resolve basenames.** Critics routinely cite `genetics.ts` for
   `packages/sim-core/src/genetics.ts` — in a 287-finding sample only 8 of 54 path
   citations resolved as written, and ~46 were basename shorthand. A checker that does
   not resolve basenames rejects ~85% of *correct* citations. Match on basename when the
   full path does not resolve, and only fail when no file in the repo matches.
4. A finding whose evidence cannot be located goes to a `## ⚠️ Unverified findings`
   section: it may **not** be 🔴 or 🟡, and may not participate in convergence.

**What this is and isn't for.** Anthropic's long-context guidance recommends
quote-before-answer to suppress hallucination, and that is the usual rationale. On this
repo's corpus it is *not* the binding problem: across 330 adjudicated findings there was
**one** borderline location error and zero clear hallucinations. The real payoff is
auditability — only 6 of 43 findings in one corpus carried a mechanically checkable
reference at all, which is why precision could never be measured without re-reading every
finding by hand. Requiring Evidence makes the output machine-checkable going forward.
Treat a firing check as a signal worth investigating, not as a routine occurrence.

### Confirmed Good is a claim, not an output

`✅ Confirmed Good` is the highest-assurance row this rubric emits, and until now it was
the only tier nothing checked. On one measured diff, **two of three model tiers filed the
branch's actual blocking defect under Confirmed Good** — and in one of them the
disconfirming evidence was sitting in that same run's own fact-check report, recorded
verbatim, while the security review certified the claim as "matches reality"
(`docs/thoughts/code-review-evaluation-state.md` §1.3). Treat every ✅ row as a claim that
has to survive the same grounding a 🔴 row does.

**1. Evidence is mandatory.** Each ✅ row's `Evidence` cell is filled and checked with
steps 1–3 of [Evidence grounding](#evidence-grounding) above — cite `path/to/file:line`,
quote the text that appears there, resolve basenames before failing. Same form, same
check; do not invent a second citation format.

**2. An unlocatable ✅ row is deleted, not demoted.** If the evidence cannot be found, the
row does **not** move to `## ⚠️ Unverified Findings` — that section exists for findings
that would otherwise be 🔴 / 🟡, and a confirmation that cannot be grounded is not a
finding at all. It is simply not a confirmation: drop the row. Do not restate it as prose
elsewhere in the synthesis.

**3. Exhaustiveness claims need enumeration, not an instance.** Most false confirmations
here are universally quantified — "no `X` anywhere", "all client fetches are `/api/…`",
"`connect-src 'self'` is sufficient", "sound with no unintended carve-outs". One
confirming instance does not establish a claim of that shape, and citing one is the exact
move that produced the observed miss. Evidence for a universally quantified ✅ row must be
the **enumeration that was actually executed** and its scope (e.g. `rg -n "fetch\(" app`
→ 12 matches, all relative `/api/…`). If no enumeration was run, the row may not be ✅:
either reword it as the specific instance that *was* checked, or drop it.

**4. Cross-check every ✅ row against the fact-check reports (Stage 3, before publishing).**
For each candidate ✅ row, re-read the merged fact-check report **and each current-run
per-replicate report** (`code-fact-check-report-r*.md` filtered to files whose `Commit:`
line matches the current HEAD — the directory is git-tracked, so unfiltered globs read
prior branches' replicates; an observation recorded by only one replicate may be absent
from the merged claim it lost the severity contest to, and it still counts)
for any observation touching the same file, symbol, directive, or claim — **including observations recorded in passing,
under a different claim number, or under a claim the fact-check itself marked Verified.**
The observed failure was exactly this: the contradicting detail (`data:` URLs fetched
client-side) was recorded as supporting colour inside a claim the fact-check verified. Ask
of each observation "if this is true, is the ✅ claim still true?", not "did the fact-check
label this a problem?".

**On a contradiction, the row may not be published as ✅.** The behaviour is fixed so the
item is neither silently dropped nor silently promoted:

- Move it into `## 🟡 Must Address` as a single row worded as the contradiction itself —
  what was certified, and which observation is inconsistent with it.
- `Source:` is `Confirmed-Good cross-check`. `Domain` is the domain of the critic that
  certified it. `Severity` is `Contested` — the confirmation was revoked, no critic
  assigned this a native level, and inventing one would be a fabricated severity.
- The fact-check observation goes in verbatim as the row's evidence, with its
  `path/to/file:line`, so the author can adjudicate without re-deriving it.
- 🟡 is the terminal tier for this mechanism. A contested confirmation is **not** promoted
  to 🔴 by this check, and it does not count as corroboration under the
  [Escalation Rule](#escalation-rule) — this revokes an over-claim, it does not
  manufacture a blocking finding. 🟡 is the right home because it is the tier that means
  "the author must fix this or say on the record why it stands", which is precisely what a
  contested certification needs.
- Name the revocation in the chat synthesis under **Actionable guidance**. A row that
  moves must be visible as having moved; deleting it and moving on is the failure this
  check exists to prevent.

This check is cheap — it is a second read of an artifact already in context — and it is
the one check that would have caught the observed miss.

### Unified Severity Mapping

Use this table to map individual critic severity levels to rubric tiers:

| Rubric Tier | Security | Performance | API Consistency | Architecture | Fact-Check |
|---|---|---|---|---|---|
| 🔴 Must Fix | Critical, High | Critical | Breaking | Structural | Incorrect (high confidence), **behavioral** |
| 🟡 Must Address | Medium | High, Medium | Inconsistent | Coupling | Incorrect (medium confidence), Stale, Mostly Accurate, **Incorrect (high) on a comment/doc only** |
| 🟢 Consider | Low, Informational | Low, Informational | Minor, Informational | Minor, Informational | Unverifiable |

**Fact-check red is scoped by subject (decision 031).** A fact-check `Incorrect (high
confidence)` is 🔴 only when the *code behaves wrong* — the comment/doc accurately
describes broken behavior, or documents a contract/security rationale a future change
would bind to and be misled by (those stay 🔴 here, or are already caught by
api-consistency `Breaking` / the [Soundness-Contradiction Channel](#soundness-contradiction-channel)).
When the code is correct and the claim's only consequence is that a *reader is
misinformed* (e.g. a wrong runtime name in a comment, a stale "same pattern as X"
pointer), map it to 🟡, not 🔴 — under the 0R+0A merge standard a comment fix costs the
same as an ack, so it is still fixed, but a stale *comment* no longer carries a code
defect's merge-blocking authority. **Immutable-history exception:** a fact-check Incorrect
about a claim in an *already-merged commit message* (or any artifact no new commit can
edit) is not a tier at all — route it to `docs/reviews/override-log.md` as an
accepted-immutable acknowledgment and do not raise it as 🔴/🟡; blocking merge on
unfixable history is a category error. Rationale and the measured driver (verdict-draw
variance on these two marginal classes controls loop length, ~1M tokens per marginal-red
pass) are in `docs/decisions/031-review-loop-tier-and-factcheck-policy.md`.

**Record the critic's own severity, don't discard it.** The `Severity` column on the 🔴 /
🟡 / 🟢 tables carries the source critic's native level (Critical / High / Medium / Low /
Informational, or the domain equivalent — Breaking, Structural, Incorrect) *verbatim*,
before this table maps it to a tier. The mapping is lossy and it is lossy in the direction
that matters: tier assignment is the **least** stable part of the output — identical
prompts on an identical diff produced Medium/Low/Low for the same issue — while the
critic-native High band is the **most** stable, with every finding any run rated High
appearing in all runs of that diff
(`docs/working/experiment-results-code-review-2026-07-29.md`, Result 1). Flattening to a
tier throws away the reliable quantity and keeps the unreliable one. Recording both costs
one column and lets a later gate key on whichever proves sound.

**Contextual critics are advisory:** Findings from `test-strategy`, `tech-debt-triage`, `dependency-upgrade`, and `ui-visual-review` go to 🟢 Consider tier regardless of their internal severity. They inform but never block merge. `architecture-review` is the exception: it is auto-selected like a contextual critic but uses its own severity-to-rubric mapping above and can produce blocking (🔴) findings. One further exception is evidence-gated rather than critic-gated: a contextual-critic finding that meets the [Soundness-Contradiction Channel](#soundness-contradiction-channel) trigger is lifted to 🟡 Must Address — the only path by which a contextual-critic finding leaves 🟢, and terminal at 🟡.

### Escalation Rule

If 2+ **core critics, architecture-review, or fact-check** flag the same issue (same code
region, overlapping concern), **record the convergence** on the finding
(`Convergence: security + performance`) and surface it in the synthesis as a
prioritization signal.

**Convergence alone no longer escalates a tier.** Promotion to a higher tier additionally
requires one piece of corroboration that does not come from another critic sampling the
same model:

- a failing test or other executed evidence,
- a fact-check verdict of **Incorrect**, or
- explicit human confirmation during the run.

With corroboration, escalate one tier (🟢 → 🟡, 🟡 → 🔴) and note which corroboration
applied. Without it, the finding keeps its own tier and carries the convergence note.

**Why this changed.** The rule previously read "independent agreement across domains is
the strongest signal that an issue is real." In this repo the critics are **not
independent** — they are the same model on the same diff, differing only by role prompt,
so their errors are correlated by construction. Measurements
(`docs/working/experiment-results-code-review-2026-07-29.md`, Results 2 and 5) found:
cross-role convergence is *rare* (0–1 borderline case across 3 diffs), so the rule almost
never fires; of the four historical convergence-escalations, the one with the **most**
convergence (3 critics) is the one the human waived; and the escalation was applied
inconsistently anyway (≥2 findings labelled convergent were never escalated). The
mechanism was carrying merge-blocking authority on an untested n≈5.

Note what the evidence did *not* show: those escalated findings were factually **valid**.
The failure mode was true-but-unwanted — a real issue promoted to blocking against the
author's judgment. That is why the corroboration required is executable or human, not
another opinion.

Contextual critics (test-strategy, tech-debt-triage, dependency-upgrade) do **not** count toward escalation. Their findings remain in 🟢 Consider regardless of overlap with other critics. If a contextual critic flags the same issue as a core critic, note the agreement in the finding's description for visibility, but do not escalate — contextual critics are advisory and must not gain blocking power through the escalation mechanism. A contextual-critic finding lifted to 🟡 by the [Soundness-Contradiction Channel](#soundness-contradiction-channel) is likewise excluded here: the lift is terminal at 🟡 and does not count as escalation corroboration.

This rewards convergence — independent agreement across domains is the strongest signal that an issue is real and important. When escalating, place the finding in its new (higher) tier section in the rubric, not in its original tier.

### Soundness-Contradiction Channel

A correctly-reasoned **soundness defect** — code whose documented behaviour is accurately
described and wrong as design — can earn neither of the verdict-driven promotions: the
fact-check correctly rates the accurate comment `Verified`, and nothing is `Breaking`. On
a measured diff, a reviewer reached the ground-truth defect, rejected the docstring
defending it, reconstructed the full behavioural inversion — and filed it 🟢, because no
promotion channel existed (`docs/thoughts/code-review-evaluation-state.md` §1.2, Results
15/14a); the historical human panel filed the same finding 🟡 and gated the merge on it.
This channel closes that gap without granting blocking authority to an unvalidated
mechanism (decision 028).

**Trigger — all three parts must be present in the critic report itself:**

1. a **stated intent quoted verbatim** with `path/to/file:line` — a design document, a
   sibling comment or docstring, a spec the code cites, or `<pr-intent>`. *Verbatim*
   admits standard editorial marks — bracketed alterations (`[is]`) and elision (`…`) —
   so long as the quoted words are recognizably the source's; a paraphrase is not a
   quote (measured: the one true lift in the validation corpus carries an `[is]`
   bracket, so a byte-exact reading fails the channel's own purpose);
2. the **code's actual mechanism quoted or reconstructed** with `path/to/file:line`; and
3. the report's own reasoning that the mechanism produces **runtime behaviour contrary
   to the stated intent** — a behavioural defeat or inversion. Contradictions of a
   stated *convention, structure, or hygiene principle* ("this code breaks the module
   header's stated design principle") do **not** qualify, and neither does a claim that
   documentation is *false* (that is fact-check-`Incorrect` territory). In the
   validation replay this distinction alone removed every clear false lift while
   keeping the true one.

**Precision guard.** An intent claim alone, a missing quote on either side, or a critic's
disagreement with a design's *wisdom* never qualifies. Do not lift a finding whose report
does not contain both quotes — the channel's authority comes from evidence a
human can re-verify in seconds, never from any critic's internal severity label.

**On a qualifying finding:**

- Place it in (or move it to) `## 🟡 Must Address` with `Severity: Contested-Soundness`
  and `Source: Soundness cross-check (found by <critic>)`. **Lift only, never demote:** a
  qualifying finding already at 🔴 (or already 🟡 via another channel) keeps its band and
  simply gains the Contested-Soundness annotation — in the validation corpus 8 of 19
  trigger fires were rows already promoted by existing channels, and a literal "move to
  🟡" would have moved 🔴 rows *down*.
- Both quotes go in verbatim as the row's evidence, each with its `path/to/file:line`,
  so the author can adjudicate without re-deriving the contradiction.
- This applies **regardless of which critic filed the finding** — contextual critics
  included. It is the one path by which a contextual-critic finding leaves 🟢 Consider;
  the advisory rule otherwise stands unchanged.
- **🟡 is the terminal tier for this channel.** A Contested-Soundness row is never
  promoted to 🔴 by this mechanism, and it does not count as corroboration under the
  [Escalation Rule](#escalation-rule) — the same bar the Confirmed-Good cross-check
  carries. Executed evidence remains the path to 🔴: a failing test demonstrating the
  inversion already promotes under the existing rule, with no help needed from here.
- Name the lift in the chat synthesis under **Actionable guidance**. A row that moved
  must be visible as having moved.

**Why 🟡 and not 🔴.** This mechanism has one retrospective validation behind it and no
prospective one, and such mechanisms get no blocking authority. 🟡 is also the
ground-truth band: the human panel filed the measured case 🟡, and 🟡 means "the author
must fix this or say on the record why it stands" — exactly what a contested soundness
question needs. **Validation status (2026-07-30,
`docs/working/validation-soundness-channel-2026-07-30.md`):** the decision-028 replay
passed with recalibration — recall 1/1 on the ND2 reconstruction; ~1.3% clear-false-lift
rate before the condition-3 behavioural-only tightening above, 0 after it; md1
`proxy.ts:14` held non-vacuously (the negative control with real probing power — ND3's
`sim.ts:625-628` control was vacuous in that corpus and future falsifiers should not
rely on it). The 🟡 cap stands until a **prospective** corpus of ≥10 correct lifts
accumulates (decision 028's cap-raise precondition).

### Rubric Status Line

- Red items unresolved: `**Status: 🔴 DOES NOT PASS** — [N] red item(s) unresolved`
- Zero red but amber open: `**Status: 🟡 CONDITIONAL PASS** — [N] amber item(s) awaiting resolution or justification`
- All red and amber resolved: `**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation`

#### The single-sample label

A passing verdict is **one draw**, not a proof of absence. Measured 🔴-band self-agreement
between replicate runs of this pipeline on an identical diff is **0.14–0.25**
(`docs/thoughts/code-review-evaluation-state.md` §1.4) — a second run of the same
configuration on the same code frequently disagrees about what is blocking. So a clean
result says "this run found nothing", never "there is nothing".

Carry this label, verbatim and once, wherever a clean or passing verdict is emitted:

> single-sample review; absence of findings is not an attestation

It appears in exactly two places, and never more than once in each: appended to the
`✅ PASSES REVIEW` status line above, and in the chat synthesis when the run is clean
(see [Deliverable 1](#deliverable-1-chat-synthesis)). Do not expand it into a paragraph,
do not repeat it per section, and do not attach it to a 🔴 or 🟡 verdict — those are not
being consumed as assurance, and hedging them dilutes the label where it matters.

---

## Output Locations

Save all review artifacts to `docs/reviews/` in the project root. Create the directory if it doesn't exist. Prior artifacts from an *earlier review* are never overwritten — date-stamping (below) keeps them. Within a single review-fix loop, iterations update the current run's files in place so status tracking works across iterations.

```
docs/reviews/
├── code-review-rubric-<date>-<branch-slug>.md
├── code-fact-check-report.md      (merged, most-severe-wins — the canonical report)
├── code-fact-check-report-r1.md   (replicate — audit + Confirmed-Good observation scan)
├── code-fact-check-report-r2.md   (replicate)
├── code-fact-check-report-r3.md   (replicate)
├── security-review.md
├── performance-review.md
├── api-consistency-review.md
├── architecture-review.md         (if triggered)
├── test-strategy-review.md        (if triggered)
├── tech-debt-triage-review.md     (if triggered)
├── dependency-upgrade-review.md   (if triggered)
├── ui-visual-review.md            (if triggered)
├── override-log.md                (append-only across runs — see "Capturing new overrides")
```

When saving review artifacts, include a `Commit: <hash>` metadata line at the top of each file and use date-stamped filenames (e.g., `security-review-2025-01-15.md`) so that results persist across review cycles. **Exception:** `override-log.md` is **append-only** and persists across runs — never overwrite it, never date-stamp it, and never delete entries even when they become stale (mark them with a `~` strikethrough in the `Finding` cell if a reviewer judges them no longer applicable, but keep the row for audit purposes).

At the end of your chat synthesis, link to all documents.

---

## Override-Log

The override log (`docs/reviews/override-log.md`) is the persistent record of human overrides on this skill's output. It is both an **input** to every future run (consumed in Step 3.5) and an **output** of any run whose chat synthesis produces a human decision that contradicts the rubric verdict.

### Capture format

Each override is one row in the table at the bottom of `docs/reviews/override-log.md`. The columns are:

| Field | Required | Example |
|---|---|---|
| `Date` | yes | `2026-05-12` (ISO date when the override was applied) |
| `PR ref` | yes | `#482` (GitHub PR), `a1b2c3d` (short SHA), or `feat/auth-tokens` (branch) |
| `Finding` | yes | `Missing null check in auth.ts:42 (security-reviewer)` — include `path:line` and the surfacing critic so future runs can match by location, category, and source |
| `Original verdict` | yes | One of `🔴 Must-Fix`, `🟡 Must-Address`, `🟢 Consider`, `Nit` |
| `Override verdict` | yes | One of `Won't-Fix`, `Defer`, `🟡 Must-Address`, `🔴 Must-Fix` (or comparable shorthand using the same vocabulary as Original) |
| `Reason` | yes | One short sentence on the human's rationale (`"test-only path"`, `"deprecated module, removal scheduled in #501"`, `"team style; verbose form preferred here"`). If longer than ~30 words, link to a PR comment or `docs/decisions/NNN-*.md` instead of expanding the cell. |

Rows are kept in reverse-chronological order (most recent at the top of the table) so that the freshest context is easiest to scan.

### Capturing new overrides

When a human review of this run's output produces a verdict change relative to the rubric — typically a Must-Fix → Won't-Fix or a Nit → Must-Fix promotion — append a row to `docs/reviews/override-log.md` immediately. The append happens:

1. **Inside the same skill run** when the orchestrator records the human's verdict
   in chat (e.g., the user says "this one is fine, skip it" or "actually promote that").
2. **From the review-fix loop** in `workflows/pr-prep.md` when the loop terminates
   with unresolved findings that the human explicitly waived.
3. **Manually by the author** if the override is reached outside a structured run
   (e.g., during PR review on GitHub) — the author writes the row themselves.

In all three paths, fill every required field. Missing fields invalidate the row for future Step 3.5 matching: a row without a location cannot match by location, and a row without a reason cannot be evaluated for staleness.

### Why this isn't write-only

The risk with any "log of decisions" is that nothing reads it, so it grows in storage cost but adds no signal. This skill prevents that failure mode by:

- **Mandatory read in Step 3.5.** The orchestrator MUST read the log before
  rendering findings, on every run.
- **Mandatory citation in deliverables.** Both the chat synthesis
  (`### Considered overrides`) and the rubric (`## ↩️ Considered Overrides`)
  must explicitly state which prior overrides applied — or that none did. The
  "none matched" line is not optional; silent omission is treated as a
  calibration failure in self-eval.
- **Explicit delta on departure.** If the current run flags a finding that a
  prior override marked Won't-Fix, the orchestrator must explain why it is
  re-flagging — new evidence, scope change, or disagreement with the prior
  call. Re-arguing a settled override without acknowledging it is the
  specific failure this section exists to prevent.

---

## Important Reminders

- **Always run fact-checking first, and always as k=3 replicates.** Even if the user only
  asks for critic perspectives. Byte-identical prompts, merged most-severe-wins, per-claim
  replicate verdicts recorded, disagreement rate reported — rationale and mechanics live
  in Stage 1's **Why three** and merge steps, the single canonical statement.
- **Paste skill file contents into agent prompts.** Sub-agents cannot read your filesystem.
- **Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues.
- **All agents of the same stage run in parallel.** They must not see each other's output.
  Exception: opt-in chain mode for a named critic pair (see
  [Stage 2 dispatch modes](#stage-2-dispatch-modes)) deliberately feeds the
  upstream critique into the downstream prompt for that pair only.
- **Be honest about convergence.** Don't present a minority finding as consensus. Convergence
  detection is semantic (overlapping concern in the same code region), not mechanical.
- **The rubric is designed for re-runs, and is date-stamped per review.** Within one
  review-fix loop, re-runs update the statuses in the same
  `code-review-rubric-<date>-<branch-slug>.md`. A new date or branch means a new file —
  never overwrite a prior review's rubric, since it is the only durable record of what the
  pipeline surfaced and whether each finding was fixed or waived.
- **Contextual critics are advisory.** Their findings go to Consider tier and never block merge — with one evidence-gated exception: the Soundness-Contradiction Channel lifts a qualifying finding to 🟡, terminal there.
- **Fact-check report size management.** If the report exceeds 200 lines, paste only the
  "Claims Requiring Attention" summary (Incorrect, Stale, Mostly Accurate) into critic prompts.
- **The override log is append-only and must be read on every run.** Step 3.5 reads
  `docs/reviews/override-log.md` before any findings are rendered; both deliverables
  must cite the matching rows (or explicitly state none matched). New overrides
  produced by human review on this run get appended to the log per
  [Capturing new overrides](#capturing-new-overrides). Never overwrite, date-stamp, or
  delete entries.
- **`✅ Confirmed Good` is a claim, not an output.** Every row carries grounded
  `Evidence`; universally quantified rows carry the enumeration that establishes them, not
  one instance; and every row is cross-checked against the fact-check report before
  publishing. A contradicted row moves to 🟡 Must Address as `Contested` — never dropped
  silently, never promoted past 🟡. See
  [Confirmed Good is a claim, not an output](#confirmed-good-is-a-claim-not-an-output).
- **A clean run is one sample, not an attestation.** When the rubric passes or the next
  action is `merge`, carry the standing label
  "single-sample review; absence of findings is not an attestation" — once on the status
  line and once in the chat synthesis, and nowhere else.
- **The chat synthesis must end with a `Recommended next action:` line.** Exactly one of
  the five bracketed values, chosen mechanically per
  [Next-action derivation](#next-action-derivation). Do not hedge, do not list multiple
  options, do not skip the line when the rubric is clean — rule 5 still applies.
