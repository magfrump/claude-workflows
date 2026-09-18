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

Orchestrates the sub-skills below. Each entry `<name>.md` refers to the skill at `skills/<name>/SKILL.md`; ensure they exist before use.

**Required (always run):**
- `code-fact-check.md` — verifies factual claims in code comments, docs, and commit messages,
  statically or by execution in the review sandbox (every verdict carries
  `**Verification mode:** static | executed` and a per-claim `Scope:` line).
  Runs as **k=3 parallel replicates** merged most-severe-wins; the rationale lives in one
  place — Stage 1's **Why three** — do not restate it elsewhere. Its `## Submitted claims`
  intake additionally verdicts critics' routed endorsement claims in
  [Stage 2.5](#stage-25-endorsement-claim-verification-submitted-claims).

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

## Execution rules

Dispatch every fact-check and critique to a sub-agent via the Agent tool. Writing analytical
observations about the code yourself defeats the point of the orchestration: the synthesis is
only worth reading if the findings came from independent passes.

The stages are sequential because each one consumes the previous one's output. Finish Stage 1
(code fact-check) and read its results before dispatching Stage 2 (critics); collect every
critic result before Stage 2.5 (endorsement-claim verification, when it applies) and merge its
verdicts before Stage 3 (synthesis and rubric). Produce neither deliverable until every
sub-agent you dispatched has reported.

If a sub-agent fails or returns empty, say so in the synthesis rather than filling the gap
yourself — a silent gap reads as coverage the review never had.

Read `docs/reviews/override-log.md` during Step 3.5 of "Before You Begin" and surface every
matching row in both deliverables. When the scan returns nothing, emit the "no prior overrides
matched this diff" sentinel explicitly — without it the log becomes write-only and nobody can
tell a clean scan from a skipped one. See [Override-Log](#override-log) for capture format.

---

## Reference files

Three parts of this skill live beside it and are read when the stage that needs them arrives,
not on every trigger:

- **[references/rubric.md](references/rubric.md)** — the rubric template, tier definitions,
  evidence grounding, the Unified Severity Mapping, the escalation rule and the two evidence
  channels. Needed from the moment you tier a finding (Stage 3, and Stage 2.5 when it runs).
- **[references/chat-synthesis.md](references/chat-synthesis.md)** — the chat deliverable's
  required structure, coverage/escalation blocks and next-action derivation. Needed at Stage 3.
- **[references/override-log.md](references/override-log.md)** — the override-log capture
  format and append procedure. Needed at Step 3.5 (read) and after the run (append).

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

Diff delivery to agents is conditional (decision 032 #3, see [Inline shared-context prefix](#inline-shared-context-prefix-decision-032-3)): assemble the shared block (diff + enclosing-file context) and measure it against the **25k-token budget** defined in that section. Within budget → inline it once as the shared cacheable prefix of every agent prompt. Over budget → degrade per that section's ladder (diff-only inline, then full self-read via the scope specification, each agent running its own `git diff`). The delivery gate is the byte/token budget alone — the ~1000-line triage below governs *splitting the review into passes*, and the >40%-churn rule governs *per-file review framing*; neither gates delivery.

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

Read `docs/reviews/override-log.md` in full **before** rendering any findings. (Create the file if it does not yet exist using the format in [`references/override-log.md` § Capture format](references/override-log.md#capture-format) — the first override row landing in this run is itself capture, not just consumption.) For each row in the log's entry table, decide whether it applies to the current diff by checking, in order:

1. **Location match.** The `Finding` cell records a `path/to/file:line` location. If the file is in the current diff and the line is within ±20 lines of a changed hunk, the entry is a candidate.
2. **Category match.** If no location match, but the finding's category (security/auth, performance, API consistency, lint-style Nit, etc.) overlaps a critic that is about to run AND a file in the same subsystem is touched, the entry is a candidate.
3. **Substantive match.** If the wording of `Finding` describes substantively the same claim a critic is likely to surface on the current diff (e.g., "missing null check at $function" recurring in a refactor of `$function`), it is a candidate even without a location or category hit.

Hold every matched row as `<considered-overrides>` for Stage 3. Each entry MUST be surfaced in both deliverables (see Deliverable 1's `### Considered overrides` section and Deliverable 2's `Considered overrides` column / explicit "none matched" note). The log is not write-only: silent omission of a matched override is a calibration failure and a stage-3 self-check must catch it before publishing.

If the override log is empty or contains no rows that match the current diff, record the negative result explicitly (`No prior overrides matched this diff.`) — the absence statement is part of the contract that prevents the log from being write-only.

This step is **read-only with respect to the log** during the run. New overrides — produced when a human reviews this run's output and downgrades or upgrades a finding — are appended to `docs/reviews/override-log.md` as a follow-up step (see [Capturing new overrides](references/override-log.md#capturing-new-overrides)), not during dispatch.

### Step 4: Known critic roles

The orchestrator uses a fixed taxonomy of skills. Do not scan `skills/*.md` at runtime — use the lists below. Each entry `<name>.md` refers to the skill at `skills/<name>/SKILL.md`. (If a listed skill's `SKILL.md` doesn't exist, skip it and note the gap in your plan summary. If the user references a skill not listed here, they can include it via `--include`.)

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
- `--loop-pass` — mark this run as a **non-final pass of a review-fix loop** (set by
  `pr-prep`'s loop for every pass except the terminal clean check). Enables the
  [first-red short-circuit](#first-red-short-circuit-decision-032-4) and implies `--no-gate`
  (no interactive Fact-Check-Gate pause — the short-circuit decides automatically). Never pass
  it on the terminal pass: that pass must run the full panel so the amber inventory is complete.

### Step 7: Communicate the plan

Before launching any agents, tell the user:
- The scope being reviewed
- Which core critics will run
- Which contextual critics were auto-selected (and why)
- Total agent count (3 fact-check replicates + N critics, plus one Stage-2.5
  submitted-claims fact-check pass if critics route endorsement claims)

Keep this brief — a short paragraph.

---

## The Pipeline

### Inline shared-context prefix (decision 032 #3)

Every Stage-1 replicate and Stage-2 critic prompt is assembled from two parts: a **shared
context block** that is byte-identical across all agents in the run, and a **per-agent tail**
(that agent's skill text + its output path + any chain context). Build the shared block **once**
and place it **first, verbatim**, in every agent prompt; put everything that varies per agent
**after** it. This lets the Anthropic prompt cache serve the shared block to all ~8 agents in a
pass — and again on the next loop pass while it is unchanged — at the cache-read rate instead of
re-billing full input per agent. It is a pure transport optimization: the content each agent sees
is unchanged, so it has **zero effect on recall** (decision 032 H1).

**Inline the shared review material** (this is the realized form of #3 — the 2026-08-06
measurement, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md`, found the benefit is
only captured when the shared material is actually inlined as one cacheable prefix; agents
self-reading via tools share only a ~330-token instruction prefix — ~8k cost-equivalent across
the canon, negligible). The shared block is, in this fixed
order (omit a part only when it does not apply, but keep the order so the cached prefix stays
stable):

1. The goal preamble (what a review pass is). The preamble MUST include the
   **complete-unit reading rule**: before verdicting a claim or filing a finding about
   code inside a function or method, read the entire enclosing unit — signature to final
   line, explicitly including the lines *after* the last line the finding cites — plus
   the flow of any value the analyzed lines produce to its first point of use; and any
   quoted excerpt that ends inside its enclosing unit must carry a truncation marker
   naming the remainder (`excerpt ends :99; enclosing getClient() continues to :108 —
   read`). Measured driver: two independent e8 cells filed analyses truncated one and
   two lines short of the defect in the same function — the excerpt a finding needs is
   not the unit the reviewer must read
   (`docs/working/fn-trace-skill-levers-2026-08-21.md`, lever 3).
2. The partial-scope labelling block, if the scope is partial (Step 1).
3. `## What this PR is trying to accomplish` — the `<pr-intent>` captured in Step 2.
4. `## Prior review findings (advisory …)` — `<prior-findings>` from Step 3, if any.
5. **The unified diff itself** (`git diff <scope>`), inlined — plus the decision-021 Stage-1
   enclosing-file context (the post-scope contents of the files the diff touches), subject to
   the budget below. This is the bulk of the shared prefix; inlining it once and caching it
   across the fan-out is where the saving comes from. It sits second-to-last because a fix
   commit mutates it: parts 1–4 are stable across the whole loop, so ordering them first keeps
   them a cache-warm common prefix across fix→re-review cycles.
6. The Stage-1 merged fact-check summary (Stage 2 only; Incorrect/Stale/Mostly-Accurate rows
   per the >200-line rule in Stage 2 step 5), **plus** the merged report's `## Escalations`
   section in full and a one-line entry for each Verified claim whose `Replicate
   annotations` or `Scope:` does-not-establish clause names a concrete risk (the caveat,
   with `path:line`) — these are the under-calling guard's payload and must reach every
   critic even when the summary is otherwise truncated. Changes every pass, so it is last.

Agents still have repo access and may read further files on demand (e.g. a cross-file consumer not
in the enclosing set); inlining the diff + enclosing files just means they don't re-fetch the
*shared* material, so it can be cached.

**Size guard — the 25k-token budget and the degrade ladder.** Inlining trades context-window
budget for cache reuse, and for a large change the window, not the bill, is the binding
constraint. The gate is a number, measured on the assembled material, not a diff-line proxy —
the dominant term is enclosing-file bytes, which the canon showed are decoupled from diff line
count (7,663–69,575 chars/cell on similar-sized diffs):

- **Budget: 25,000 tokens, estimated as chars/4 (i.e. ~100 KB of assembled part-5 material).**
  Compute after assembling the diff + enclosing-file context (`wc -c` ÷ 4). The number is
  calibrated to the 2026-08-06 canon: the largest measured cell was ~17.4k tokens, so every
  measured cell inlines with ~45% headroom, and the budget stays ~12% of a 200k agent window
  after skill text and working room. Revisit when a post-restructure measurement lands.
- **Within budget** → inline diff + enclosing files as part 5.
- **Over budget** → degrade, don't cliff: drop the enclosing-file context and inline the
  **diff only** (agents self-read enclosing files on demand — they have repo access).
- **Diff alone still over budget** → full fallback to the pre-#3 behavior: pass the scope spec
  and let each agent run its own `git diff` and read what it needs.

State which of the three modes you used in the plan summary (`delivery mode: inline` /
`inline-diff-only` / `self-read`). (This is why Step 1 frames diff-inlining as conditional
rather than forbidden. The per-file >40%-churn rule in Step 1 is a review-framing rule —
greenfield vs diff-level evaluation — and plays no part in this delivery gate.)

**Stability rules that make the cache actually hit:**
- Keep the shared block **first** and **byte-identical** across agents in a pass. The only
  permitted per-agent variation lives in the tail (skill text, output path, chain context).
- Across loop passes, the block's prefix stays cache-warm up to the first part that changed:
  parts 1–4 are stable across the whole fix→re-review loop; the diff/enclosing context (part 5)
  mutates on every fix commit and therefore sits second-to-last; the fact-check summary
  (part 6) changes each pass and sits last. Ordering stable-parts-first is what preserves a
  cacheable common prefix across passes even when the diff changes.
- **Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a
  billing-rate effect, not a token-count reduction). Leave it on because it is free; do not expect
  it to move the token-count ledger.
- This is **production-loop-only**. It must **not** be ported to `scripts/cross-model-review.py`:
  that harness is the cross-model *sweep*, whose confound control requires whole prompts that are
  byte-identical *across models* and stamped by `prompt_sha`. Prompt caching is deliberately absent
  there (decision 032 H4) — see the guard note in that file's module docstring.

### Between-stage status banner

After each between-stage handoff (end of Stage 1, end of Stage 2, and end of Stage 2.5 when that stage runs), emit a single one-line status banner directly in the chat so the user can judge progress and decide whether to interrupt before the next stage launches.

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
- The Stage 2-complete banner introduces the next stage — Stage 2.5 when
  endorsement claims were routed, otherwise synthesis (Stage 3). Because
  later stages consume Stage 2's output, this banner must include `dispatch mode:
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

### Per-stage token accounting

Every sub-agent's completion notification reports its token total. Record it **when the
notification arrives**, not reconstructed from memory afterward:

- **Measured runs** (this review is a cell of an experiment with a `manifest.json` under
  `runs/`): write each stage's token total into the cell's `tokens` map immediately, per
  the measurement-provenance convention in `docs/working/review-canon.md` §3 (E1's manifest
  is the reference shape: one entry per stage plus `total_tokens`). Leaving the map empty
  is a protocol violation to flag in the results doc — a week later, an empty `tokens: {}`
  is indistinguishable from "not measured", and the run's cost can only be re-derived
  indirectly (the E8 lesson: the sweep's cost had to be bounded from subscription-quota
  deltas to ~$150–350, a ±2× window instead of a ledger).
- **All runs**: include a one-line per-stage token summary in the Stage 3 chat synthesis
  (e.g. `tokens: fc 3×80k, merge 90k, critics 4×65k, rubric 85k ≈ 700k total`), so the
  figure exists in a durable transcript even when no manifest does.

### Stage 1: Code Fact-Check (k=3 replicated)

Spawn **three** agents with the code-fact-check skill, in parallel, on **byte-identical
prompts** — same skill text, same scope spec, same instructions, differing only in the
output path each is told to write.

**Model (pinned — do not inherit the session model): `opus`, set explicitly on every
fact-check Agent dispatch (k=3 and k=1 loop-pass alike).** Fact-check verdicts are
load-bearing (the Incorrect channel blocks; verdicts feed Stage-1.5 gating), so the
stage must not silently degrade with whatever model the session happens to run.
Measured basis (`docs/working/fc-model-sweep-results-2026-08-15.md`; 3 models × 2
canon cells × 2 replicates, identical prompts): sonnet — *even with this skill text
as its role prompt* — produced 3 false "Verified" attestations on known-bad claims
in 4 replicates (once after finding the refuting code), so the Stage-2 rule
"sonnet acceptable with role-skill prompts" does **not** extend to Stage 1; opus and
fable both scored 12/12 with 0 attestations, and fable's 2× price bought no marginal
catch. Opus is therefore the pin in both directions: an upgrade from cheaper
sessions, a cost cut from fable sessions.

**Why three.** A fact-check **Incorrect** verdict is one of the two verdict-driven
blocking channels (state doc §1.0: fact-check Incorrect or api-consistency Breaking; the
[Unified Severity Mapping](references/rubric.md#unified-severity-mapping) lists each critic's native 🔴 band) —
and the only one reachable by documentation-class findings. It is also the least stable
judgment in the pipeline: on identical input, the same comment defect was rated
**Incorrect** by one run and **Mostly Accurate** by another, flipping the same finding
between 🔴 and 🟡 (`docs/thoughts/code-review-evaluation-state.md` §1.1, Result 14a).
A single sample of that judgment is a coin flip carrying merge-blocking authority.
Replication converts it into a measured distribution.

**Replication is loop-aware (decision 031, configuration C2 — 031 overrules the earlier
blanket k=3 mandate).** On a `--loop-pass` (an intermediate or confirmation pass inside the
review-fix loop, which requires **2 consecutive clean passes** before merge), run **k=1**: a
single fact-check agent with the same rich shared brief (step 3b below — brief quality, not k,
governs systematic recall), saving its report directly as the canonical
`docs/reviews/code-fact-check-report.md` with `**Replication:** k=1 (loop pass, decision 031)`
in the header; skip the merge machinery and the Verdict-stability section. The across-pass
resampling of the 2-clean rule supplies the redundancy k=3 supplied within a pass (1−(1−p)ᴺ ≥
1−(1−p)³ for N≥3 draws). The **k=3 protocol below applies to standalone single-pass reviews** —
no loop, no second draw, so the replication happens within the pass.

For each of the three replicate agents:

1. Read the full contents of `skills/code-fact-check/SKILL.md`
2. Paste those contents directly into the Agent tool prompt (sub-agents cannot read your files)
3. Deliver the review material per Step 1's conditional diff-delivery rule (see
   [Inline shared-context prefix](#inline-shared-context-prefix-decision-032-3)): within the
   25k-token budget → the shared block (diff + enclosing-file context, inlined) opens the
   prompt; over budget → degrade per that section's ladder (inline the diff only, or fall back
   to the scope specification — e.g., "Review files changed on the current branch relative
   to main using `git diff main...HEAD`" — and let the replicate self-read). If the scope is
   partial (`--range`, `--staged`,
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
   stale (delete it too) — missing provenance is not a pass. Match the line by field
   name with or without bold on replicate reports (`Commit:` or `**Commit:**` both
   satisfy it); only the **merged** report's header is a parsed contract requiring the
   bolded form exactly (Gate 1h).
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
   (file, line-range, claim substance), not on string equality. **Compound/atomic mismatch
   (decision 033):** one replicate may verdict a sentence as a single compound claim while
   another splits it into sub-claims (`7a`/`7b`); the compound clusters with each of its
   parts, and most-severe-wins (step 2) applies across the whole cluster — a sub-claim's
   Incorrect beats the compound's Mostly accurate. **Emit at the finest granularity any
   replicate used:** where any replicate split, the merged report carries one `## Claim`
   per sub-claim, and a replicate that verdicted only the compound records its verdict
   on each sub-claim row annotated `(compound)` — e.g. `r2=Verified (compound)`. This
   keeps a sub-claim's severe verdict from swallowing a sibling sub-claim's clean one,
   and Verdict stability counts sub-claim rows.
2. **Take the most severe verdict any replicate assigned** to the cluster. Severity order,
   most severe first: `Incorrect (high confidence)` > `Incorrect (medium confidence)` >
   `Incorrect (low confidence)` >
   `Stale` > `Mostly Accurate` > `Unverifiable` > `Verified`. Majority vote is explicitly
   the wrong aggregator here: a defect one replicate *proves* Incorrect is Incorrect
   regardless of what the other two concluded, and the observed failure mode is
   under-calling, not over-calling (state doc §1.1). Carry the headline evidence and
   reasoning from the replicate that assigned the winning verdict; when several
   replicates tie on the winning verdict, carry the one with the most specific `Scope:`
   line (the most concrete does-not-establish clause), breaking remaining ties by
   lowest replicate number. But most-severe-wins
   selects the **verdict only**, never which replicate's *annotations* survive:
   **annotations merge by union** (step 3, `Replicate annotations` field). A scope
   caveat, placement note, "does not establish X" disclaimer, or escalation note is
   never dropped because its replicate lost the verdict contest, and never dropped
   because the winning verdict is Verified — a Verified claim with a caveat is a
   different object than a clean Verified. Measured driver: on the e8 benchmark cells,
   the merge dropped a caveat two replicates attached to a Verified setting-consumer
   claim ("does not establish the value is validated as a URL" — the missed Critical
   SSRF) and dropped one replicate's placement note that had already stated a real bug
   verbatim (analytics recorded before the feature-flag gate); both findings died in
   this step (`docs/working/fn-trace-skill-levers-2026-08-21.md`, lever 1).
3. **Record per-replicate verdicts on every merged claim, inside the standard schema.**
   The merged report keeps the code-fact-check report format exactly — `# Code Fact-Check
   Report` title, the five header fields, and per-claim `## Claim N:` sections with the
   seven mandatory bolded fields — so `test/skills/code-fact-check-format.bats` gates it
   unchanged (a merged report with no `## Claim N:` sections makes that suite skip
   silently, which is a gate abdicating, not passing). On top of the standard schema:
   - `**Verdict:**` carries the plain winning verdict from the five-value enum
     (`Incorrect`, `Stale`, …) and `**Confidence:**` the winning replicate's confidence.
     The severity-order tokens in step 2 (`Incorrect (high confidence)` etc.) are ordering
     vocabulary for the merge decision only — never written into a `**Verdict:**` field.
   - Each claim adds a bolded field `**Replicate verdicts:**
     r1=<verdict> · r2=<verdict> · r3=<verdict>` (`—` for a replicate that did not
     surface the claim; a claim surfaced by only one replicate keeps that replicate's
     verdict and its Replicate-verdicts line ends with ` · single-replicate detection`).
   - Each claim adds a bolded field `**Replicate annotations:**` carrying, by union,
     every scope caveat, placement note, disclaimer, and escalation note any replicate
     attached to the claim — quoted verbatim or tightly, attributed by replicate
     (`r1: "…" · r3: "…"`), with `none` when no replicate attached any. Identical or
     paraphrase-equivalent annotations collapse to one entry attributed to all their
     replicates (`r1+r3: "…"`) — dedup is on substance, and one line per *distinct*
     residue is the noise ceiling. The winning
     replicate's `Scope:` line becomes the merged claim's `Scope:`; where other
     replicates' scope residues differ in substance, their does-not-establish clauses
     join the annotations field rather than being overwritten. This field is the merge's
     under-calling guard: the annotation union is *more* mechanical than
     winner-takes-evidence, and it is where minority-detected details survive to reach
     critic prompts and synthesis.
   - The header MUST carry, in addition to the five standard fields, a bolded
     `**Commit:** <reviewed HEAD short SHA>` line (≥7 chars) and a bolded
     `**Replication:** k=3` field (or `**Replication:** k=2 (one replicate failed)` on
     the degraded path). These two are a parsed contract, not decoration: Gate 1h in
     `scripts/self-improvement.sh` reads exactly these field names to detect stale
     reports and degraded replication — a merged report missing either is advisory-flagged
     as commit-unknown / single-sample even when the run was a genuine k=3.
4. **Aggregate escalations into a `## Escalations` section.** Collect every replicate's
   Goal-Alignment `Escalate:` items (anything other than the literal sentinel `nothing`),
   every escalation-shaped note embedded in claim prose ("route to
   security-reviewer", "needs a critic to assess X"), and every Goal-Alignment
   `Out of scope:` bullet that names a critic or hands off a concrete risk ("these
   belong to security-reviewer") into one list before the Verdict
   stability section — each entry with its `path:line`, the replicate(s) that raised it,
   and its addressee. The same escalation raised by multiple replicates merges to one
   entry with multi-replicate attribution (else the dead-letter rule would force
   duplicate rows). An entry naming no critic gets addressee `orchestrator` — the
   dead-letter rule applies to it equally if nothing actions it. This section is a
   **routing contract**, not
   commentary: Stage 2 embeds it in critic prompts (shared-prefix part 6), and any entry
   still unrouted when the run produces its rubric falls under the dead-letter rule
   below.
5. **Report the disagreement rate.** End the merged report with a `## Verdict stability`
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

**Dead-letter rule (escalations must not outlive their addressee silently).** An
`## Escalations` entry names a critic as its addressee. If, when the rubric is produced,
that addressee never read it — Stage 2 skipped entirely (budget, gate, dispatch failure),
the named critic gated off in Stage 1.5, or the pass short-circuited before dispatching
it — the entry is force-surfaced in the rubric as a `## 🟡 Must Address` row: `Source:
fact-check escalation (unrouted)`, `Severity: Unrouted-Escalation`, the entry's text and
`path:line` as the finding, and the reason its addressee never ran in the author note.
Like `Contested` rows, 🟡 is terminal for this mechanism — an unrouted escalation is
never promoted to 🔴 and does not count as escalation-rule corroboration; it grants the
author's attention, not blocking authority on top of a single replicate's say-so. The
same applies to a caveat-bearing Verified claim whose annotation names a risk in a
skipped critic's domain: surface the residue in `### Coverage and Escalations` (chat
synthesis) so it is visible as unreviewed rather than silently cleared. Measured driver:
in the e8 sentry cell, one replicate routed four escalations — one of them a real,
already-diagnosed bug — "to security-reviewer / test-strategy", Stage 2 never ran, and
the escalation channel was a dead letter (`docs/working/fn-trace-skill-levers-2026-08-21.md`,
lever 1).

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

### First-red short-circuit (decision 032 #4)

Applies **only** when `--loop-pass` was passed — i.e., this is a non-final pass of a review-fix
loop, so a fix and another full review pass are guaranteed to follow. Skip this section entirely
on a normal (terminal or standalone) run.

The rule: **once a behavioral 🔴 is confirmed on a `--loop-pass` run, stop the pass and hand
back to the loop for the fix — do not launch the remaining review work.** A branch carrying a
behavioral red is already non-mergeable this pass; the remaining critics' findings would be
re-surfaced next pass over a churned surface, so paying for them now is waste (decision 032 #4;
the token model is E1's finding that a pass is ~1M tokens regardless of how many findings it
carries).

Mechanics:

1. **Behavioral 🔴 is defined by tier policy T (decision 031).** A fact-check high-confidence
   Incorrect on **behavioral/contract** code is a red; a comment/doc-only Incorrect is 🟡 under
   T and does **not** trigger the short-circuit. An api-consistency `Breaking` or an
   architecture `Structural` finding is likewise a behavioral red.
2. **Earliest trigger — the fact-check gate.** If Stage 1 already yields a behavioral 🔴, skip
   the **entire** Stage-1.5/Stage-2 critic panel for this pass. This is the largest saving (the
   whole critic block) — measured at **~73% of the pass** on the one case that fired it, a
   commit hunted from the external benchmark repo's history rather than one of the 8 canon
   cells (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md`). But it is **not** the
   common case: fact-check finds a *behavioral* 🔴 rarely — most fact-check Incorrects are
   comment/doc (→🟡, no fire), and most real behavioral reds surface from the **critic panel**, not
   fact-check. So this trigger is high-value but low-frequency — expected per-pass value ≈ ~73% ×
   P(fact-check-visible behavioral red) ≈ **0.3%** at the measured ~1-in-225 trigger rate, so the
   rare big win carries its own denominator; do not expect it most passes.
3. **Critic-stage trigger (limited).** If no red came from fact-check but a dispatched critic
   returns a behavioral 🔴, do not launch any *second wave* (the downstream leg of a `--chain`
   pair, or a large-diff subsequent file-group pass). Note this saves little in practice: the core
   panel is one parallel wave already in flight, so there is usually nothing left to skip (measured:
   a critic-surfaced red saved 0). Let in-flight critics finish and treat the pass as decided.
4. **Amber is NOT collected on a short-circuited pass.** Ambers gate merge only on the final
   pass (0R+0A, decision 031); gathering them over a surface about to be re-fixed is wasted.
5. **The terminal pass never short-circuits.** `pr-prep` runs the final, otherwise-clean pass
   **without** `--loop-pass`, so the full panel runs to completion and the amber inventory is
   complete for the 0R+0A merge decision. This is what preserves recall (decision 032 H1): a
   behavioral red is never merged — it is caught by construction on the terminal full-panel
   pass — and the short-circuit only defers non-decisive work between fixes.

Emit a one-line note in the chat when short-circuiting (e.g.,
`Loop-pass short-circuit: behavioral 🔴 confirmed at fact-check (<claim>) — skipping critics, returning to loop for fix.`),
and write the rubric with only the confirmed red(s); mark the skipped critics in
`## ⏭️ Skipped Core Critics` with the reason `loop-pass short-circuit (behavioral red confirmed)`.

### Stage 1.5: Critic gating

After the Fact-Check Gate (and only if the user did NOT pass `--all-critics`), narrow the core-critic set down before launching Stage 2. This stage applies two gating signals, ordered by when their input becomes available:

- **First gate — diff-shape.** Already partially applied: Step 5 used the diff to select
  contextual critics pre-Stage-1. Now extend the same diff-shape logic to the core
  critics via the skip table below — `git diff --stat` and spot-checked diff content are
  the inputs.
- **Second gate — evidence (new).** The fact-check report is now in hand. Use it to
  confirm that each remaining core critic has *some* corroborating evidence in its
  domain. If the only thing keeping a critic alive is "we always run it," and Stage 1
  surfaced nothing in its domain, downgrade it.

The default is **run all core critics** — skipping is conservative. The cost of running an extra critic is small; the cost of a missed finding is large. If you are uncertain whether a signal applies, do not skip.

**Boring version:** consult fact-check to optionally *downgrade* critics. Do not re-derive the critic set from scratch — the set entering Stage 1.5 is whatever survived Step 5 selection + user overrides, and Stage 1.5 only narrows it further. Stage 1.5 never *promotes* a critic.

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

For every core critic you skip, you MUST record it in the rubric under the `## ⏭️ Skipped Core Critics` section (see [the rubric template](references/rubric.md)) with the critic name, the skip reason, and the specific signal observed (e.g., `git diff --stat` output excerpt or the fact-check finding cited). Also reference skips in the chat synthesis scope summary so the user sees coverage limits before reading findings.

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

Dispatch each critique to a sub-agent via the Agent tool.

For each critic agent, you MUST:

1. Read the full contents of that critic's skill file (e.g., `skills/security-reviewer/SKILL.md`)
2. Paste those contents directly into the Agent tool prompt
3. Deliver the review material per Step 1's conditional diff-delivery rule (see
   [Inline shared-context prefix](#inline-shared-context-prefix-decision-032-3)): within the
   25k-token budget → the shared block (diff + enclosing-file context, inlined) opens the
   prompt; over budget → degrade per that section's ladder (inline the diff only, or fall
   back to the scope specification so the agent runs its own `git diff`). If
   the scope is partial (`--range`, `--staged`, `--files`, or a partial `--pr`), also include
   the labelling block required by Step 1's partial-scope rule
4. Include the PR intent captured in "Before You Begin" Step 2, prepended under a
   `## What this PR is trying to accomplish` heading so the critic can scope findings to
   stated intent. If Step 3 surfaced `<prior-findings>`, paste them verbatim under a
   `## Prior review findings (advisory — worth checking, not verdict input)` heading
   immediately after the intent block; otherwise omit this heading entirely.
5. Include the fact-check results. If the fact-check report is longer than 200 lines, include
   only the findings rated Incorrect, Stale, or Mostly Accurate — skip Verified claims to
   save context budget.
6. Instruct the agent to save its critique as `docs/reviews/{critic-name}-review-{date}.md`
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
   [Evidence grounding](references/rubric.md#evidence-grounding) for why, and for the check you run on it.

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
Success criterion: A markdown report saved to docs/reviews/security-review-<date>.md, structured per the security-reviewer skill.
```

If any of those facts isn't on hand, omit the corresponding sub-bullet rather than guessing — the fields exist to anchor the critic in real project context, not to be filled for completeness. Do not add other content to the preamble; everything else (scope spec, PR intent, fact-check excerpt, output path, tagging requirements) goes in the role-specific content below it.

**Launch ALL critic agents simultaneously** in a single message with multiple Agent tool calls. They must not see each other's output. **Exception:** when [Stage 2 dispatch modes](#stage-2-dispatch-modes) chain mode is active for a pair, the downstream critic is dispatched in a second message after the upstream critic returns; every other critic still launches in the first parallel batch.

**CHECKPOINT:** Wait for ALL critic agents to return results (including the downstream critic of any active chain). Count the results. Do you have the expected number? If yes, proceed to Stage 3. If not, tell the user what's missing.

After confirming the expected critic count, emit the between-stage status banner per the format spec above (e.g., `Stage 2 (critics) complete: <counts>, dispatch mode: <mode> — synthesizing into rubric and chat summary`). Emit it before launching Stage 2.5 (when it applies) or Stage 3 so the user sees the handoff explicitly — when you already know Stage 2.5 will run, name it as the banner's next action (e.g., `— dispatching submitted-claims fact-check on 4 routed endorsement claims`).

### Stage 2.5: Endorsement-claim verification (submitted claims)

Critics no longer self-certify positives. The security-reviewer emits **Endorsement
Claims** (entries marked `route: code-fact-check` where they could anchor a Confirmed-Good
row), the performance-reviewer emits evidence-gated **Endorsements** (bullets tagged
`[unverified — submitted as claim]`), and any other critic may mark a positive assertion
the same way. A routed entry is a claim awaiting a verdict, not a verdict — this stage gets
it verdicted through the fact-check skill's `## Submitted claims` intake, then feeds the
verdicts into synthesis.

1. **Collect.** Sweep every returned critic report for entries marked
   `route: code-fact-check` or `[unverified — submitted as claim]`. For each, extract the
   claim text, its `Location:`, the submitting critic's name, and (where present) its
   `Verified / Not verified` scope pair. Endorsements the critic scoped without a routing
   tag stay in its report as scoped prose — do not submit them; the routing tag is the
   critic's own signal that the claim would otherwise justify a ✅ row.
2. **Skip conditions.** If no routed claims exist, skip this stage silently — the rubric's
   ✅ rows must then rest on Stage-1 verdicts alone. On a `--loop-pass`, skip it too:
   routed claims stay *pending execution verification* (✅ rows are terminal-pass output,
   and the decision-032 pass economics apply); the terminal pass runs the stage in full.
3. **Dispatch one fact-check agent** — same mechanics as a Stage-1 replicate: paste
   `skills/code-fact-check/SKILL.md`, deliver the review material per Step 1's conditional
   diff-delivery rule, launch with `subagent_type: "general-purpose"` and the **model
   pinned `opus`** exactly as Stage 1 pins it (submitted-claim verdicts feed ✅ rows, so
   this dispatch must not silently degrade either). Supply the collected list under a
   `## Submitted claims` heading — each entry with the submitting critic's name, the claim
   text, and its location — and instruct the agent to verdict them per its "Submitted
   claims" section: same verdicts, same evidence discipline, the same orchestrator-not-analyst rule
   (most routed endorsements are executable guarantees, so expect `executed`-mode
   verdicts). Instruct it to save the report as
   `docs/reviews/code-fact-check-submitted-claims.md` with a `Commit: <current HEAD short
   SHA>` line. k=1 is deliberate here, not a degradation: these claims were authored by a
   named critic rather than sampled from prose, so Stage 1's verdict-stability rationale
   (**Why three**) does not transfer, and no merge machinery applies.
4. **Merge.** Append the returned `## Submitted Claims` section to the canonical merged
   report (`docs/reviews/code-fact-check-report.md`), preserving each verdict's fields
   (including `Verification mode` and `Scope`) and the submitting critic's name, so every
   downstream consumer — the Confirmed-Good cross-check, the Unified Severity Mapping —
   reads one artifact. This is mechanical collation like the Stage-1 merge; you add no
   verdicts of your own — the orchestrator-not-analyst rule in "Execution rules" still stands.
5. **Feed back into synthesis.** A submitted claim verdicted `Verified` — with its
   verification mode and `Scope:` line — is admissible backing for a ✅ row per provenance
   rule 5 of [Confirmed Good is a claim, not an output](references/rubric.md#confirmed-good-is-a-claim-not-an-output).
   A submitted claim verdicted **Incorrect** is a finding, not a footnote: enter it in the
   rubric tiered by the [Unified Severity Mapping](references/rubric.md#unified-severity-mapping)'s fact-check
   column (behavioral-vs-doc scoping included), with the fact-check evidence as the row's
   evidence and `Source: <critic> endorsement, refuted by fact-check`. `Unverifiable`
   verdicts — and routed claims left unverdicted on a skipped stage — surface as *pending
   execution verification* wherever the strength would otherwise be cited, never as
   confirmations.

When the stage ran, emit a between-stage banner (e.g., `Stage 2.5 (endorsement-claim
verification) complete: 4 submitted claims — 2 Verified (executed), 1 Incorrect, 1
Unverifiable — synthesizing into rubric and chat summary`).

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

The collected items feed the `### Coverage and Escalations` section of the chat synthesis (see [references/chat-synthesis.md](references/chat-synthesis.md)). They do not modify the rubric — coverage is a chat-synthesis concern.

#### Confirmed-Good cross-check (required before producing deliverables)

Assemble the candidate `✅ Confirmed Good` rows, then run each one through
[Confirmed Good is a claim, not an output](references/rubric.md#confirmed-good-is-a-claim-not-an-output):
Evidence present and grounded, enumeration behind any universally quantified claim,
provenance per rule 5 (an `executed`-mode verdict, or a static verdict whose `Scope:` line
covers the row's full breadth), and no
observation anywhere in the merged fact-check report **or any current-run per-replicate
report** (matched by `Commit:` line, per the stale-replicate guard) inconsistent with it —
an observation recorded only by a replicate whose verdict lost the severity contest still
counts. To keep this from becoming four full re-reads at Stage 3, build the observation
index once during the Stage-1 merge (file/symbol/directive touched per observation) and
consult that index here. For each static-backed row that survives, apply the
**entailment test**: quote the backing claim's `Scope:` covers clause in the row's
`Evidence` cell and confirm the property it names *entails* the row's assertion —
coverage of the same lines is not entailment of the safety claim (a Verified on message
shape does not entail "the sender/receiver contract works"; a Verified that a guard
cannot throw does not entail the guard is correct). Rows that fail are
dropped (ungrounded), narrowed to what their backing verdict's scope actually covers
(provenance shortfall, rule 5), or moved to 🟡 Must Address as `Contested` (contradicted)
per that section. When a row is narrowed or dropped on scope grounds, the residue named
by the backing claim's does-not-establish clause is a **coverage gap**, not discardable
colour — list it in `### Coverage and Escalations` so the un-verified property stays
visible instead of vanishing with the row. Run this **before** writing either
deliverable — it changes the rubric's contents,
so it cannot be a post-hoc pass over a published table.

#### Soundness-contradiction cross-check (required before producing deliverables)

Immediately after the Confirmed-Good cross-check, sweep every critic report — contextual
critics included — for findings that meet the
[Soundness-Contradiction Channel](references/rubric.md#soundness-contradiction-channel) trigger: a stated
intent quoted verbatim with `path/to/file:line`, the code's actual mechanism quoted or
reconstructed with `path/to/file:line`, and the report's own reasoning that the mechanism
defeats or inverts the stated intent. Each qualifying finding is placed in (or moved to)
`## 🟡 Must Address` per that section. Run this **before** writing either deliverable —
like the Confirmed-Good cross-check, it changes the rubric's contents, so it cannot be a
post-hoc pass over a published table.

#### Executable-defect cross-check (required before producing deliverables)

Immediately after the soundness-contradiction cross-check, sweep every critic report —
contextual critics included — for findings meeting the
[Executable-Defect Channel](references/rubric.md#executable-defect-channel) trigger: a deterministic failure
asserted, a concrete sandbox-executable verification named, and the mechanism quoted
with `path/to/file:line`. Run (or attempt) each named verification and place qualifying
findings per that section. The runs are cheap by construction — single commands and
single tests — so batch them; an unattempted verification on a qualifying finding is a
skipped required check, not a judgment call. Like the other two cross-checks, this
changes the rubric's contents and cannot be a post-hoc pass over a published table.

#### Fragment-Composition cross-check (required before producing deliverables)

Immediately after the executable-defect cross-check (so composition sees final fragment
tiers), harvest every cited location
from every report in the run — `Location:` headers, `Evidence` blocks, and `file:line`
references in finding/claim body text alike (the Stage-1 observation index seeds this;
critic-report citations are added on top). Cluster them: same file, line ranges
overlapping or within ±15 lines — but **do not chain**: when transitive ±15-line links
would grow a cluster beyond one enclosing unit (or ~50 lines), split it and pose the
question per 🔴/🟡-fragment pair instead (measured: naive chaining turns a
heavily-cited file into one whole-file mega-cluster — 69 citations spanning
`database.go:15-166` in the calibration census — where a single forced question is
unanswerable). A cluster **qualifies** when it spans **2+ distinct
sources** (the merged fact-check counts as one source; each critic is one) **and**
contains at least one 🔴 or 🟡 finding. For each qualifying cluster, answer one forced
question and log the answer either way:

> Is there a single root defect these fragments jointly describe that **no single
> fragment states**? If yes, state it in **one sentence** naming the mechanism and the
> fix. If no, record `distinct defects` with a one-clause reason.

Measured driver: on the e8 grafana cell, the mechanism (fact-check), the consequence
(security → rubric red), and the inconsistent sibling derivation (architecture, whose
load-bearing quotes sat in Evidence blocks under unrelated `Location:` headers) were
all detected — and the one-line root ("use `time.Now().UTC()` like the sibling call")
was never stated by any stage
(`docs/working/dd-synthesis-fragment-composition.md`; fn-trace GR1).

**Entailment discipline (the false-composition guard).** Every clause of the composed
sentence must be traceable to a fragment's own quoted evidence. If stating the root
would require reading code beyond what the fragments quote, do **not** compose — log the
cluster as `possible shared root — needs adjudication` and add it as a 🟢 Consider row
instead. When each fragment already states its own mechanism and fix completely, the
answer is `distinct defects` by construction — composition exists to state what only the
conjunction implies, never to staple complete findings together.

**On a "yes":**

- Add **one** composed row in the tier equal to the **maximum of the fragment tiers** —
  inherit-only, never a lift. `Source: Composition cross-check (fragments: <list>)`,
  `Severity: Composed (inherits <max fragment severity>)`.
- The row's evidence is the fragments' quotes **verbatim**, each with `path/to/file:line`,
  so the author can re-verify the composition in seconds without re-deriving it.
- Fragment rows are untouched: they keep their tiers, wording, and evidence, and gain a
  cross-reference to the composed row (e.g., `Composed into X1`). Composition is
  additive, never a merge-and-delete.
- **Composition grants no authority.** A composed row never counts as corroboration
  under the [Escalation Rule](references/rubric.md#escalation-rule), never raises any fragment's tier, and a
  cluster of contextual-critic-only fragments composes at 🟢. This is the boundary with
  the retired convergence-escalation mechanism: that rule used correlated agreement to
  *raise severity* and was retired on measured evidence; this check uses co-location to
  *compose content* at unchanged severity. Severity continues to come only from the
  evidence-gated channels the fragments already passed through.
- Name the composition in the chat synthesis under **Cross-critic findings** (reference
  the composed row; do not restate it) and under **Actionable guidance**.

**Logging.** The rubric gains a `## 🧩 Composition check` section listing every
qualifying cluster — file, line span, fragment IDs, and disposition (`composed → X1` /
`distinct defects: <reason>` / `needs adjudication → C<n>`). If no cluster qualified,
render the single line "No multi-source co-located clusters qualified." The heading must
still appear so the check is auditable across runs and its precision is measurable.

**Cost basis (measured, 2026-08-21):** ~10.7 qualifying clusters per pass on the
3-cell calibration census → ~1,020 output tokens ≈ **0.10%** of a ~1M-token pass, with
no agent round-trip and no new input reading (all reports are already in Stage-3
context; composed evidence is restricted to already-quoted fragments by the entailment
discipline). Hit rate on the census: 1 composed (the GR1 ground-truth miss) / 29
distinct / 2 needs-adjudication, 0 false compositions
(`docs/working/measure-fragment-composition-cost.md`).

**Validation status:** retrospective only (GR1 positive replay + cal.com negative
replay, `docs/working/dd-synthesis-fragment-composition.md`); per the decision-028
precedent, no authority increase until a prospective corpus of ≥10 correct
compositions accumulates. Live falsifiers (from the cost measurement): fewer than ~1
true composition per 20 qualifying clusters over ≥10 live cells, more than 1-in-4
composed rows failing the entailment discipline, or cluster volume ~5× the census
making the section an attention tax — any of these retires or restructures the check.

Like the cross-checks above, run this **before** writing either deliverable — it
changes the rubric's contents.

#### Contrastive note (optional, capture during synthesis)

Pick one finding the panel caught well, plus one likely-related issue you suspect was missed (sources: goal-alignment notes, escalations, or your own scan of the diff). State both in 1–2 lines, then propose one concrete prompt-refinement candidate — an added instruction, sharpened heuristic, or new check for a critic skill — that would have closed the gap on the next run. Skip if no genuine contrast is available; do not invent one. Capture only — no feedback pipeline consumes this yet.

---

## Deliverable 1: Chat Synthesis

Present this directly in the chat, self-contained — assume the user has NOT read the
individual agent reports. Required structure, the coverage-and-escalations block, the
considered-overrides block, the single-sample label and the next-action line are specified in
**[references/chat-synthesis.md](references/chat-synthesis.md)**. Read it before writing the
synthesis; it is the format contract, not background.

---

## Deliverable 2: Code Review Rubric

Save as `docs/reviews/code-review-rubric-<YYYY-MM-DD>-<branch-slug>.md`. The template, the
tier definitions, evidence grounding, the Unified Severity Mapping, the escalation rule, the
soundness-contradiction and executable-defect channels, and the rubric status line are
specified in **[references/rubric.md](references/rubric.md)**. Read it before producing the
rubric and before tiering any finding — the mapping there is the single source of truth for
severity, and Stage 3 cannot be completed correctly without it.

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
├── code-fact-check-submitted-claims.md  (Stage 2.5 — if critics routed endorsement claims)
├── security-review-<date>.md
├── performance-review-<date>.md
├── api-consistency-review-<date>.md
├── architecture-review-<date>.md         (if triggered)
├── test-strategy-review-<date>.md        (if triggered)
├── tech-debt-triage-review-<date>.md     (if triggered)
├── dependency-upgrade-review-<date>.md   (if triggered)
├── ui-visual-review-<date>.md            (if triggered)
├── override-log.md                (append-only across runs — see "Capturing new overrides")
```

When saving review artifacts, include a `Commit: <hash>` metadata line at the top of each file and use date-stamped filenames (e.g., `security-review-2025-01-15.md`) so that results persist across review cycles. **Exception:** `override-log.md` is **append-only** and persists across runs — never overwrite it, never date-stamp it, and never delete entries even when they become stale (mark them with a `~` strikethrough in the `Finding` cell if a reviewer judges them no longer applicable, but keep the row for audit purposes).

At the end of your chat synthesis, link to all documents.

---

## Override-Log

The override log (`docs/reviews/override-log.md`) is the persistent record of human overrides
on this skill's output: an **input** to every run (consumed in Step 3.5) and an **output** of
any run whose chat synthesis produces a human decision contradicting the rubric verdict. The
capture format, the append procedure, and why the log is not write-only are in
**[references/override-log.md](references/override-log.md)**.

---

## Important Reminders

- **Always run fact-checking first; replication is loop-aware (decision 031).** Even if the
  user only asks for critic perspectives. k=1 per pass inside the review-fix loop (paired
  with the 2-consecutive-clean rule); k=3 for standalone single-pass reviews — byte-identical
  prompts, merged most-severe-wins, per-claim replicate verdicts recorded, disagreement rate
  reported. Rationale and mechanics live in Stage 1's **Why three**, its loop-aware
  replication paragraph, and the merge steps — the single canonical statement.
- **Paste skill file contents into agent prompts.** Sub-agents cannot read your filesystem.
- **Co-located fragments get one composition question, at unchanged severity.** The
  Fragment-Composition cross-check clusters all cited locations (headers, Evidence, and
  body citations) across sources; a qualifying cluster's forced question is answered and
  logged either way; a composed row inherits the max fragment tier, never lifts, and
  never corroborates escalation. See
  [Fragment-Composition cross-check](#fragment-composition-cross-check-required-before-producing-deliverables).
- **Diff delivery is conditional (Step 1 / decision 032 #3).** Within the 25k-token shared-block
  budget: inline it once as the shared cacheable prefix of every agent prompt. Over budget:
  degrade — inline the diff only, then as a last resort pass scope, not diffs, so each agent
  runs its own `git diff` to avoid context budget issues.
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
  [Capturing new overrides](references/override-log.md#capturing-new-overrides). Never overwrite, date-stamp, or
  delete entries.
- **`✅ Confirmed Good` is a claim, not an output.** Every row carries grounded
  `Evidence`; universally quantified rows carry the enumeration that establishes them, not
  one instance; every row's backing is an `executed`-mode fact-check verdict or a static
  verdict whose `Scope:` line covers the row's full breadth (provenance rule 5 — a
  critic's read-static endorsement or a narrower Verified stamp never promotes to a
  categorical ✅ row); and every row is cross-checked against the fact-check report before
  publishing. A contradicted row moves to 🟡 Must Address as `Contested` — never dropped
  silently, never promoted past 🟡. See
  [Confirmed Good is a claim, not an output](references/rubric.md#confirmed-good-is-a-claim-not-an-output).
- **Endorsement claims are verified, not self-certified.** Critic entries marked
  `route: code-fact-check` or `[unverified — submitted as claim]` go through the Stage-2.5
  submitted-claims fact-check pass; a routed claim without a verdict surfaces as *pending
  execution verification*, never as a confirmation, and a refuted one enters the rubric as
  a finding. See
  [Stage 2.5](#stage-25-endorsement-claim-verification-submitted-claims).
- **A named defect mechanism never drops below the rubric.** Severity and remit set the
  tier — 🟢 Consider at minimum, mechanism intact — never omission. See
  [Mechanism visibility floor](references/rubric.md#mechanism-visibility-floor-triage-loss-prevention).
- **A clean run is one sample, not an attestation.** When the rubric passes or the next
  action is `merge`, carry the standing label
  "single-sample review; absence of findings is not an attestation" — once on the status
  line and once in the chat synthesis, and nowhere else.
- **The chat synthesis must end with a `Recommended next action:` line.** Exactly one of
  the five bracketed values, chosen mechanically per
  [Next-action derivation](references/chat-synthesis.md#next-action-derivation). Do not hedge, do not list multiple
  options, do not skip the line when the rubric is clean — rule 5 still applies.
