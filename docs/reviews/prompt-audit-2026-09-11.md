# Prompt audit — /workspace prompt surface

**Date:** 2026-09-11 · **Auditor:** `/claude-api prompt-audit` (guide: `shared/prompt-audit.md`)

## Stated assumptions (Step 0)

1. **Scope.** The request named no file, so scope is the whole working directory's prompt
   surface: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `skills/**`, `workflows/**`, `guides/**`,
   `patterns/**`, `hooks/**`, `test/skills/**`, and the request-building code in `scripts/*.py`
   (77 markdown files, ~1.4 MB). Excluded: `external/`, `archive/`, `runs/`, `docs/`,
   `node_modules/`, `.claude/worktrees/` (copies of tracked files), and the fact-check test
   fixtures (deliberately synthetic prose, not instructions).
2. **Target model.** The request named none and the repository documents no in-progress
   migration. The prompt surface is consumed by Claude Code sessions, which run the current
   flagship generation — **Claude Fable 5.1 / Claude Opus 5** is the target. The
   prior-generation IDs that do appear (`anthropic/claude-sonnet-4.5`,
   `anthropic/claude-opus-4.5`, `claude-haiku-4-5-20251001`) are sub-agent and judge pins in
   `scripts/`, not the audience for these prompts; one of them is itself a finding (F10).
3. **Non-Anthropic markers.** `scripts/cross-model-review.py` and `scripts/dd-cross-model-sweep.py`
   call OpenAI and Google models through OpenRouter by design (cross-model review harnesses).
   Recorded, not flagged; no finding proposes switching them to the Anthropic SDK.

## Summary

**13 findings: 4 high, 7 medium, 2 flag-only.** Counts by group — Group 1a (pressure
language): 2 · Group 1c/1d (padding, re-insertion, fossils): 3 · Group 1f (output-shaping
choreography): 1 · Group 2 (brittle skill files): 3 · Group 3 (contract accuracy): 1 ·
Group 4 (config and architecture): 3.

This surface is in good shape overall. There are no retired-model workarounds, no
`think step by step` / `<scratchpad>` scaffolds, no assistant-turn prefills, no forced
`tool_choice`, no `budget_tokens` / `temperature` fossils, no narration suppressors, and no
anti-formatting rules. Caps-emphasis density is low (13 of 77 files contain any), prohibition
runs are absent, and the numbered `Step N` structure in the orchestrators is genuine
order-dependent choreography, which the keep list protects. Most of what follows is
maintenance, not rot.

The three highest-impact findings:

1. **`CLAUDE.md` is loaded into every session twice.** The global instructions file is a
   symlink to the same 31 KB file the project declares, so the harness renders it once as
   global instructions and once as project instructions. Both copies are verbatim in this
   session's own context. That is roughly 8,000 tokens of pure duplication on every request,
   and duplicated rules make the model spend effort reconciling two identical wordings.
2. **A stale tool name survives in a live dispatch instruction.** `draft-review` still tells
   the orchestrator to dispatch "via the Task tool"; the tool is called `Agent`. The repo's own
   `guides/skill-format-audit.md` raised this as Finding 7 and it was fixed everywhere except
   this line, which a later rewrite reintroduced. A description that does not match the actual
   tool sends the model down a path no other prompt text can correct.
3. **The `<300 words` sub-agent output cap is a numeric clamp applied surface-wide.** It is
   stated as a default convention in `patterns/orchestrated-review.md` and inherited by every
   dispatching workflow. Numeric output ceilings were tuned against models that padded; on the
   target model they starve reasoning on hard problems. The documented operational reason
   ("keeps synthesis cost predictable") is real, but it argues for audience framing, not a
   word count.

---

## Findings

Ordered by confidence, highest first.

### F1 — `CLAUDE.md` rendered twice per session · **High** · `remove`

| | |
|---|---|
| **Location** | the global `CLAUDE.md` instructions path (a symlink to `/opt/claude-workflows/CLAUDE.md`) and `/workspace/CLAUDE.md` |
| **Evidence** | `diff -q` reports the two paths identical (31,019 bytes each). Both appear verbatim in this session's system prompt, once labelled "user's private global instructions for all projects" and once "project instructions, checked into the codebase". |
| **Pattern** | Group 4 (token accounting / context cost); Group 1c padding — "duplicated rules make the model spend effort reconciling wordings" |
| **Why obsolete** | The global-instructions channel and the project-instructions channel were separate surfaces when the file was first placed in both; pointing them at one file means every request pays ~8K tokens twice and the model reconciles two byte-identical rule sets instead of reading one. |
| **Action** | `remove` — drop the global symlink so the project copy is the single source, or keep the global copy and have the project not ship its own. Either way the file must load once. |

### F2 — `draft-review` dispatches via a tool that does not exist · **High** · `rewrite`

| | |
|---|---|
| **Location** | `skills/draft-review/SKILL.md:197` |
| **Evidence** | `**DO NOT write critiques yourself. You MUST dispatch each critique to a sub-agent via the Task tool.** This is non-negotiable.` |
| **Pattern** | Group 3 (contract accuracy — "description must precisely match actual behavior"); Group 2 (volatile specifics) |
| **Why obsolete** | The tool is `Agent`. `guides/skill-format-audit.md:156-167` raised this as Finding 7 and recommended replacing every `Task tool` reference; the sibling `skills/code-review/SKILL.md:788` carries the corrected wording. `git log -S` shows this line was reintroduced by `4582f97` (2026-07-21, "terse-imperative rewrite of all 25 SKILL.md files") — a regression against a closed finding, and now the only surviving occurrence in the skill. |
| **Action** | `rewrite` — `Task tool` → `Agent tool` (folded into F3's hunk, which rewrites the same line). |

### F3 — "Mandatory Execution Rules" pressure-language clusters · **High** · `rewrite`

| | |
|---|---|
| **Location** | `skills/code-review/SKILL.md:59-84` and `:788` · `skills/draft-review/SKILL.md:49-68` and `:197` · `skills/matrix-analysis/SKILL.md:34-51` |
| **Evidence** | `These rules are absolute. Do not deviate from them under any circumstances.` followed by four to six numbered rules carrying `MUST` / `MUST NOT` / `ALL` / `STOP —` / `No exceptions.`, then restated 600+ lines later as `**DO NOT write critiques yourself. You MUST dispatch …** This is non-negotiable.` |
| **Pattern** | Group 1a (pressure language); Group 1c (repetition as reinforcement) |
| **Why obsolete** | Provenance is explicit: `git log -S'These rules are absolute'` dates the block to `ca10c6f` (2026-03-17, "Add fact-checking and draft review skills from claude-cowork") and `a127298` / `ee1c4e8` (2026-03-20/23) — written for a generation that under-followed system instructions. On the target model, blanket emphasis stops carrying information once several instructions each claim to be critical, and an anxious prompt produces a cautious, hedging model. The *substance* is load-bearing and stays: the orchestrator-not-analyst contract, the stage ordering, and the honest-gap rule are all things only the author knows. What goes is the volume and the second statement of rule 1. |
| **Action** | `rewrite` — state the contract plainly with its reason; delete the restatement at `code-review:788` / `draft-review:197` since rule 1 already says it (F2's tool-name fix rides along). |

### F4 — The `<300 words` sub-agent output cap · **High** · `rewrite`

| | |
|---|---|
| **Location** | `patterns/orchestrated-review.md:131-145` (the convention) · inherited at `guides/sub-agent-briefing.md:14, 29, 36, 62-69, 96` · `workflows/task-decomposition.md:113, 121` · `skills/matrix-analysis/SKILL.md:225-228` · `guides/task-decomposition-examples.md:32, 35, 38` |
| **Evidence** | `<300 words summary; structured output may extend.` and `Why a cap: the orchestrator must read every sub-agent's output during synthesis.` · `4. **Output cap** — explicit length limit ("under 200 words", "table only, no prose"). Without one, expect a wall of text.` |
| **Pattern** | Group 1f (output-shaping choreography — numeric output ceilings) |
| **Why obsolete** | `git log -S'300 words summary'` dates the convention to `5b83720` / `5b86a66` (2026-04-29), tuned against models that padded. Group 1f is explicit that a stated operational reason does not convert a numeric clamp into a keeper: on the target model, output caps starve reasoning on hard problems, and "expect a wall of text" describes a failure mode the target model does not have. The goal — sub-agents surfacing conclusions rather than buried-lede analysis — is real and survives as audience framing. The structural alternatives already in the text ("table only, no prose", "one sentence per function", "table with three columns") are format instructions and stay. |
| **Action** | `rewrite` — replace the numeric ceiling with outcome framing at the convention site; the inheriting sites then pick it up by reference. |

### F5 — Routing-reminder hooks re-inject rules already in `CLAUDE.md` · **Medium** · `remove`

| | |
|---|---|
| **Location** | `hooks/dd-routing-reminder.sh` · `hooks/batch-feedback-routing-reminder.sh` (both wired as `UserPromptSubmit` in `hooks/wiring.json`) |
| **Evidence** | The scripts' own headers: "This escalates the CLAUDE.md precedence note … from skimmable prose to a harness-executed interception" and "It exists because the documented routing gets skipped: the observed failure is collapsing a multi-item batch into one sequential pass". |
| **Pattern** | Group 1d (instruction re-insertion on a cadence) |
| **Why obsolete** | This is the documented retention-crutch shape: a rule stated once in `CLAUDE.md`, then re-injected into context on every matching prompt because an earlier model lost it over a long session. Current models retain a once-stated instruction, and each firing costs tokens (the batch hook's own comment budgets ~85 tokens per firing and deliberately fires on non-human submits too). |
| **Action** | `remove` the re-injection and re-test the routing behavior from `CLAUDE.md` alone. **Note for the user:** `docs/reviews/override-log.md` records a 2026-06-23 decision to keep the batch hook's broad firing. That decision is a reason you may decline this hunk; it is not a reason to withhold the proposal. If routing still slips after removal, the minimal re-add is one reminder, not two hooks. |

### F6 — Routing rules stated three and four times over · **Medium** · `rewrite`

| | |
|---|---|
| **Location** | `CLAUDE.md:46-62` ("Batch fan-out") against decision-tree row 2; row 3 against `skills/divergent-design/SKILL.md` and `workflows/divergent-design.md` |
| **Evidence** | Row 2's table cell already carries the split-then-route rule, the worked shape, and "Do NOT collapse a batch into one sequential pass — that's the default failure this row exists to prevent." The `### Batch fan-out` section then restates recognition, the four-step procedure, and the when-not-to-fan-out test; the hook (F5) states it a third time. |
| **Pattern** | Group 1c (repetition as reinforcement); Group 1d (patch accretion) |
| **Why obsolete** | Saying it once in the right place is the target-model behavior; three statements of one routing rule make the model reconcile wordings and inflate the always-loaded file. The *mechanics* that live only in the section — worktree isolation, merge-and-reconcile, the row-2-vs-row-7 discriminator — are context and stay. |
| **Action** | `rewrite` — keep the table row as the rule, cut the section to the mechanics the row does not carry, and drop the hook cross-reference (which F5 removes). |

### F7 — Skill descriptions grown by trigger-phrase enumeration · **Medium** · `rewrite`

| | |
|---|---|
| **Location** | All 25 `skills/*/SKILL.md` frontmatter `description` fields; worst offenders `business-plan-critique-market-sizing` (3,055 chars), `yglesias-critique` (2,141), `what-if-analysis` (2,133), `business-plan-critique-unit-economics` (2,020), `api-consistency-reviewer` (2,001) |
| **Evidence** | e.g. `Trigger phrases: "is the market real", "review my TAM", "is the TAM defensible", "TAM/SAM/SOM critique", "market-sizing review", "is the market big enough", "stress-test the market …` |
| **Pattern** | Group 2 (trigger-case enumeration — "description lists of near-synonymous example queries, growing one phrase per missed trigger") |
| **Why obsolete** | Descriptions ride in every request. The repo's own `guides/skill-format-audit.md:91-111` (Finding 4) flagged descriptions exceeding the 250-character threshold and recommended putting the primary trigger first; every one of the 25 now exceeds it, several by tenfold. Near-synonymous phrase lists generalize worse than named intent categories. This is the one place the audit must be careful: Group 3 protects *calibrated urgency* in routing text, and that urgency stays — what goes is the enumeration length. |
| **Action** | `rewrite` — lead each description with the capability and primary trigger inside 250 characters, replace phrase lists with two or three intent categories, move scope notes and the when-not-to-use text into the body. |

### F8 — `skills/code-review/SKILL.md` is 1,909 lines · **Medium** · `move`

| | |
|---|---|
| **Location** | `skills/code-review/SKILL.md` (1,909 lines / 139 KB); also over the ceiling: `fact-check` 681, `security-reviewer` 580, `code-fact-check` 537, `draft-review` 522, `architecture-review` 517, `ui-visual-review` 515 |
| **Evidence** | `guides/skill-format-audit.md:121-140` (Finding 5) sets a 500-line limit and prescribes extracting reference material into supporting files; `ui-visual-review` did exactly that and still sits at 515. |
| **Pattern** | Group 2 (verbose SKILL.md; "skill size is a tax paid on every trigger") |
| **Why obsolete** | The file is not readable in one sitting, and everything in it loads on every trigger. Reference-grade material — the rubric format, deliverable templates, the override-log capture format, worked examples — is exactly what progressive disclosure is for. |
| **Action** | `move` — extract the deliverable templates, rubric format, and override-log format into `skills/code-review/references/*.md` and link them from the body. Not proposed as a diff hunk here: it is a mechanical split whose shape depends on which sections you want resident, and it should be done as its own change with the skill's eval re-run after. |

### F9 — "The research must be thorough" · **Medium** · `rewrite`

| | |
|---|---|
| **Location** | `workflows/research-plan-implement.md:82` |
| **Evidence** | `The research must be thorough. Read the actual implementations, not just signatures. If the research is wrong, everything downstream will be wrong.` |
| **Pattern** | Group 1a (restatement of a trained default — the guide's own example row is "Be thorough. Do not be lazy.") |
| **Why obsolete** | `git log -S` dates it to `b199c7b` (2026-02-24). Current models are thorough by default; the exhortation adds nothing the next two sentences don't say better. The second sentence is a specific, checkable quality bar and the third is its reason — both stay. |
| **Action** | `rewrite` — drop the first sentence, keep the rest. |

### F10 — Prior-generation judge model pinned in a live harness · **Medium** · `rewrite`

| | |
|---|---|
| **Location** | `scripts/cross-model-review.py:372` |
| **Evidence** | `ap.add_argument("--judge", default="anthropic/claude-sonnet-4.5", help="pinned judge model for stage-2 matching")` |
| **Pattern** | Group 2 (history narratives — "pinned model names silently degrade after the next release"); Group 4 (API fossils) |
| **Why obsolete** | Sonnet 4.5 is two generations behind the current Sonnet. The pin is deliberate (the help text says "pinned", and a stable judge keeps scores comparable across runs), so this is a re-baseline rather than a deletion: move the default forward and note the comparability break in the harness's own docs. The sibling `--models` default at line 69 is example text in a docstring and is fine as illustration. |
| **Action** | `rewrite` — default to `anthropic/claude-sonnet-5`, with a comment recording that judge changes break score comparability with earlier runs. |

### F11 — Three business-plan critics share one scaffold · **Medium** · `move`

| | |
|---|---|
| **Location** | `skills/business-plan-critique-{moat,market-sizing,unit-economics}/SKILL.md` |
| **Evidence** | Identical section skeletons: `## Scope (and what's deferred)` → `## Pre-flight: Skip Obvious Stubs` → `## Using the Fact-Check Report` → `## The Five Lenses` → `## How to Structure the Critique` → per-lens Assessment sections → `## Factual Foundation` → `## Overall Assessment` → `## Output Location` → `## Goal-Alignment Note` → `## Tone`. The pre-flight stub test is near-verbatim across all three (and across `ai-personas-critique`, `cowen-critique`, `yglesias-critique`). |
| **Pattern** | Group 4 (redundant specialist sub-agents) |
| **Why obsolete** | Three agents with the same tools, the same output contract, and near-duplicate prompts, differing in a lens set. Unlike the textbook case, the difference here is substantive (about 2,500 words of genuinely distinct domain content each), so the fix is not one merged agent — it is deduplicating the shared scaffold so the three files carry only their lenses. |
| **Action** | `move` — extract the shared pre-flight, fact-check-usage, output-location, goal-alignment, and tone sections into one `skills/business-plan-critique-common.md` referenced by all three. Proposed as direction rather than a hunk: the extraction is mechanical but touches six critics (the three above plus the persona critics that share the pre-flight), and should be one deliberate change. |

### F12 — "do not hallucinate verdicts" · **Low** · `flag`

`skills/code-fact-check/SKILL.md:271` — `Do not invent claims, do not hallucinate verdicts, and do not emit per-claim sections when …`. The guide lists `do not hallucinate` as a signal but explicitly rates removal here **low confidence, not a documented harm**, and recommends re-testing whether it is still needed rather than editing. Flagged, no edit proposed. Worth a probe next time the skill's eval runs.

### F13 — Non-standard frontmatter `when:` / `requires:` · **Low** · `flag`

Most `skills/*/SKILL.md` files still carry `when:` and/or `requires:` frontmatter keys that
Claude Code does not read — `guides/skill-format-audit.md` Findings 1 and 2, both still open.
This is a format-conformance issue, not a dated-prompting pattern, so it sits outside this
audit's remit. Flagged so it is not lost: `when:` content belongs in `description` (which
interacts with F7), and `requires:` belongs in the body.

---

## What the audit deliberately did not flag

Recording these so a future pass does not "find" them:

- **The numbered `Step N` structure** in the orchestrators, `pr-prep`, and `research-plan-implement`. Order genuinely matters in a staged pipeline; the keep list protects prescriptive text where exactly one sequence is correct.
- **The one-line role statements** (`You are an orchestrator.`, `You are a fact-checker.`, `You are an evaluator, not a cheerleader.`). Each is followed by real task context, which is exactly the case the keep list exempts.
- **The `≤25 words` quoted-span cap** in `skills/fact-check/SKILL.md:458`. This is a format-pinning requirement on a genuinely format-sensitive output, it carries its reason, and it ships with an explicit escape hatch for evidence that will not fit.
- **`MUST` in output-contract rules** — `business-plan-critique-moat:214-219`, `performance-reviewer:50-56, 296-302`, `draft-review:321-356`, `code-review:148`. These specify required fields and sentinel lines in a machine-checkable deliverable, not behavioral pressure; the emphasis is scoped to one requirement each and carries its reason.
- **Overlapping content between `CLAUDE.md` and the workflow files** (e.g. the read-implementations-not-signatures bar). Working redundancy that does not disagree is a refactoring preference, not a dated pattern.
- **`AGENTS.md` / `GEMINI.md`** restating the workflow tree for other tools. Same rule, different audiences — functioning redundancy.
- **No findings at all** for: retired-model workarounds, `think step by step` / `<scratchpad>`, assistant prefill and its JSON-forcing stack, forced `tool_choice`, `budget_tokens` / `temperature` / `top_p`, stop-sequence scaffolds, narration suppressors, anti-formatting rules, prohibition runs, and cache-hostile prompt ordering. Greps for each returned clean across the scope.
- **Token accounting exists** (`hooks/log-usage.sh`, `hooks/log-usage-post.sh`, `hooks/lib/usage-common.sh`), so the "add accounting first" prerequisite does not apply.

---

## Proposed diff

One finding per hunk. `flag` and low-confidence items are absent by design. F8 and F11
are `move` findings whose shape is a deliberate restructure rather than a text edit; they are
described in their entries and not rendered as hunks.

### Hunk 1 — F1: stop loading `CLAUDE.md` twice

Not a text edit. Run one of:

```sh
# Option A (recommended): project copy is the single source.
rm "$HOME/.claude/CLAUDE.md"

# Option B: global copy is the single source; stop shipping the project copy.
git -C /workspace rm CLAUDE.md
```

Then start a fresh session and confirm the file appears once in context. **Before removing
either copy, grep for referrers** — `rg -n 'CLAUDE\.md' --glob '!node_modules'` — since
`guides/cross-project-setup.md` and `README.md` document the install path.

### Hunk 2 — F3 + F2: `skills/draft-review/SKILL.md`

```diff
@@ -49,20 +49,17 @@
-## Mandatory Execution Rules
-
-These rules are absolute. Do not deviate from them under any circumstances.
-
-1. You MUST use the Agent tool to spawn sub-agents for ALL fact-checking and critique work.
-   You MUST NOT write fact-checks or critiques yourself. You are the orchestrator, not an
-   analyst. If you find yourself writing analytical observations about the draft's claims or
-   arguments, STOP — you are doing a sub-agent's job.
-
-2. You MUST complete Stage 1 (fact-check) and receive its results before starting Stage 2
-   (critics).
-
-3. You MUST complete Stage 2 (critics) and receive ALL critic results before starting Stage 3
-   (synthesis and rubric).
-
-4. You MUST NOT produce the verification rubric or chat synthesis until you have received
-   results from every sub-agent you dispatched. No exceptions.
-
-5. If a sub-agent fails or returns empty, note this honestly in the synthesis. Do not fill in
-   the gap yourself.
+## Execution rules
+
+Dispatch every fact-check and critique to a sub-agent via the Agent tool. Writing analytical
+observations about the draft's claims yourself defeats the point of the orchestration: the
+synthesis is only worth reading if the findings came from independent passes.
+
+The stages are sequential because each one consumes the previous one's output. Finish Stage 1
+(fact-check) and read its results before dispatching Stage 2 (critics); collect every critic
+result before Stage 3 (synthesis and rubric). Produce neither deliverable until every
+sub-agent you dispatched has reported.
+
+If a sub-agent fails or returns empty, say so in the synthesis rather than filling the gap
+yourself — a silent gap reads as coverage the review never had.
```

```diff
@@ -197,1 +194,1 @@
-**DO NOT write critiques yourself. You MUST dispatch each critique to a sub-agent via the Task tool.** This is non-negotiable.
+Dispatch each critique to a sub-agent via the Agent tool.
```

### Hunk 3 — F3: `skills/code-review/SKILL.md`

```diff
@@ -59,26 +59,24 @@
-## Mandatory Execution Rules
-
-These rules are absolute. Do not deviate from them under any circumstances.
-
-1. You MUST use the Agent tool to spawn sub-agents for ALL fact-checking and critique work.
-   You MUST NOT write fact-checks or critiques yourself. You are the orchestrator, not an
-   analyst. If you find yourself writing analytical observations about the code, STOP — you
-   are doing a sub-agent's job.
-
-2. You MUST complete Stage 1 (code fact-check) and receive its results before starting
-   Stage 2 (critics).
-
-3. You MUST complete Stage 2 (critics) and receive ALL critic results before starting
-   Stage 2.5 (endorsement-claim verification, when it applies) or Stage 3 (synthesis and
-   rubric). When Stage 2.5 runs, you MUST receive and merge its verdicts before Stage 3.
-
-4. You MUST NOT produce the code review rubric or chat synthesis until you have received
-   results from every sub-agent you dispatched. No exceptions.
-
-5. If a sub-agent fails or returns empty, note this honestly in the synthesis. Do not fill
-   in the gap yourself.
-
-6. You MUST read `docs/reviews/override-log.md` during Step 3.5 of "Before You Begin" and
-   surface every matching row in both deliverables. The "no prior overrides matched this
-   diff" sentinel is not optional — emit it explicitly when the scan returns nothing so
-   the log cannot become write-only. See [Override-Log](#override-log) for capture format.
+## Execution rules
+
+Dispatch every fact-check and critique to a sub-agent via the Agent tool. Writing analytical
+observations about the code yourself defeats the point of the orchestration: the synthesis is
+only worth reading if the findings came from independent passes.
+
+The stages are sequential because each one consumes the previous one's output. Finish Stage 1
+(code fact-check) and read its results before dispatching Stage 2 (critics); collect every
+critic result before Stage 2.5 (endorsement-claim verification, when it applies) and merge its
+verdicts before Stage 3 (synthesis and rubric). Produce neither deliverable until every
+sub-agent you dispatched has reported.
+
+If a sub-agent fails or returns empty, say so in the synthesis rather than filling the gap
+yourself — a silent gap reads as coverage the review never had.
+
+Read `docs/reviews/override-log.md` during Step 3.5 of "Before You Begin" and surface every
+matching row in both deliverables. When the scan returns nothing, emit the "no prior overrides
+matched this diff" sentinel explicitly — without it the log becomes write-only and nobody can
+tell a clean scan from a skipped one. See [Override-Log](#override-log) for capture format.
```

```diff
@@ -788,1 +786,1 @@
-**DO NOT write critiques yourself. You MUST dispatch each critique to a sub-agent via the Agent tool.** This is non-negotiable.
+Dispatch each critique to a sub-agent via the Agent tool.
```

### Hunk 4 — F3: `skills/matrix-analysis/SKILL.md`

```diff
@@ -34,18 +34,15 @@
-## Mandatory Execution Rules
-
-These rules are absolute. Do not deviate from them under any circumstances.
-
-1. You MUST use the Agent tool to spawn sub-agents for ALL evaluation work. You MUST NOT
-   score or evaluate items yourself. You are the orchestrator, not an evaluator. If you find
-   yourself writing assessments of how well an item meets a criterion, STOP — you are doing
-   a sub-agent's job.
-
-2. You MUST complete Stage 1 (setup) before starting Stage 2 (evaluation).
-
-3. You MUST receive results from ALL evaluation sub-agents before starting Stage 3 (synthesis).
-
-4. You MUST NOT produce the matrix document or chat synthesis until you have received
-   results from every sub-agent you dispatched. No exceptions.
-
-5. If a sub-agent fails or returns empty, note this honestly in the synthesis. Do not fill in
-   the gap yourself.
+## Execution rules
+
+Dispatch every evaluation to a sub-agent via the Agent tool. Scoring items yourself defeats
+the point of the matrix: the comparison is only worth reading if each cell came from an
+independent pass.
+
+The stages are sequential because each one consumes the previous one's output. Finish Stage 1
+(setup) before dispatching Stage 2 (evaluation), and collect every evaluation result before
+Stage 3 (synthesis). Produce neither deliverable until every sub-agent you dispatched has
+reported.
+
+If a sub-agent fails or returns empty, say so in the synthesis rather than filling the gap
+yourself — a silent gap reads as coverage the matrix never had.
```

### Hunk 5 — F4: `patterns/orchestrated-review.md` (the convention every other site inherits)

```diff
@@ -131,15 +131,13 @@
-#### Default output cap
-
-Every dispatched sub-agent should have an output cap stated in its dispatch instructions. The recommended default convention is:
-
-> `<300 words summary; structured output may extend.`
-
-What this means:
-
-- **Prose** (narrative findings, recommendations, explanations) fits within ~300 words. Sub-agents that exceed this are usually padding or doing the orchestrator's synthesis work.
-- **Structured output** (rubrics, decision matrices, tables, code-review reports with required fields) may extend beyond the cap when the structure itself is the deliverable. The cap applies to the prose around the structure, not the structure.
-- The **Goal-Alignment Note** above is bounded separately by its bullet-form structure (three required, up to two optional) and does not count against the cap.
-
-Why a cap: the orchestrator must read every sub-agent's output during synthesis. A bounded prose budget keeps synthesis cost predictable and pushes sub-agents to surface conclusions rather than buried-lede analysis.
-
-Workflows whose domain genuinely needs more prose should override the default explicitly in the dispatch instructions and state why (e.g., "report in under 600 words because architectural narratives need room"). Workflows that don't specify a cap inherit this default.
+#### Default output shape
+
+Every dispatched sub-agent should be told what shape its output takes. The default convention:
+
+> `Lead with conclusions; prose only where the structured output can't carry the point.`
+
+What this means:
+
+- **Prose** (narrative findings, recommendations, explanations) states the conclusion first and stops there. The orchestrator reads every sub-agent's output during synthesis, so a buried lede costs the whole pass; re-deriving context the orchestrator already has costs it twice.
+- **Structured output** (rubrics, decision matrices, tables, code-review reports with required fields) is the deliverable wherever the shape is defined — prefer it to prose rather than wrapping it in prose.
+- The **Goal-Alignment Note** above is bounded by its bullet-form structure (three required, up to two optional).
+
+Where a dispatch genuinely needs a hard shape — a three-column table, one sentence per function, a fixed set of fields — state the shape. A structural requirement is a format instruction and belongs in the dispatch; a word count is not, and clamping prose length on a hard question buys scannability by starving the analysis.
```

Dependent edits in the same hunk family — these read the convention, so they move with it:

```diff
--- a/guides/sub-agent-briefing.md
@@ -14,1 +14,1 @@
-4. **Output cap** — explicit length limit ("under 200 words", "table only, no prose"). Without one, expect a wall of text.
+4. **Output shape** — the form the answer takes ("table only, no prose", "one sentence per function", "conclusions first"). Without one, the sub-agent guesses at what you can act on.
@@ -62,9 +62,9 @@
-### 3. Missing output cap
+### 3. Missing output shape
 
 **Bad:**
 > "Examine `src/auth/tokens.go` and explain what each function does."
 
-**Why it fails:** The sub-agent has no signal for when to stop. Expect a wall of text re-deriving information you can read yourself. You then have to re-read the sub-agent's output to extract the parts that matter — the sub-agent's effort becomes a tax on yours.
+**Why it fails:** The sub-agent has no signal for what you can act on, so it re-derives information you can read yourself. You then have to re-read its output to extract the parts that matter — the sub-agent's effort becomes a tax on yours.
 
-**Fix:** State the cap. "Under 200 words." "One sentence per function." "Table with three columns." Whatever shape you can act on quickly.
+**Fix:** State the shape. "One sentence per function." "Table with three columns." "Conclusions first, evidence only where contested." Whatever you can act on quickly.
@@ -96,1 +96,1 @@
-- [ ] **Output cap** — word count, sentence count, or structural format
+- [ ] **Output shape** — structural format, or "conclusions first"
```

```diff
--- a/skills/matrix-analysis/SKILL.md
@@ -225,6 +225,6 @@
-   **Output cap:** Apply the canonical sub-agent convention — `<300 words summary;
-   structured output may extend.` (see `patterns/orchestrated-review.md` §"Default output
-   cap"). The per-item rating blocks, ranking, and key differentiator above are structured
-   output and may extend; the `Rationale` fields are prose and share the 300-word budget across
-   all items. Rationales padded beyond 2-3 sentences each force the orchestrator to re-read
-   filler during synthesis.
+   **Output shape:** Apply the canonical sub-agent convention (see
+   `patterns/orchestrated-review.md` §"Default output shape"). The per-item rating blocks,
+   ranking, and key differentiator are the deliverable. Each `Rationale` is prose: name the
+   evidence that decided the score and stop. Rationales that restate the criterion or hedge
+   across alternatives force the orchestrator to re-read filler during synthesis.
```

```diff
--- a/workflows/task-decomposition.md
@@ -113,1 +113,1 @@
-> Success criterion: Findings in the "Rate limiting" section of `docs/working/research-api-endpoint.md`, under 200 words, with a Goal-Alignment Note appended.
+> Success criterion: Findings in the "Rate limiting" section of `docs/working/research-api-endpoint.md`, conclusions first, with a Goal-Alignment Note appended.
@@ -121,1 +121,1 @@
-Common briefing mistakes: omitting file paths in the Current task (sub-agent wastes time searching), writing a Success criterion that names neither an artifact nor a path (sub-agent invents an output shape synthesis can't consume), and not capping output length. The pattern's [default output cap](../patterns/orchestrated-review.md#default-output-cap) — `<300 words summary; structured output may extend.` — applies unless the dispatch overrides it explicitly.
+Common briefing mistakes: omitting file paths in the Current task (sub-agent wastes time searching), writing a Success criterion that names neither an artifact nor a path (sub-agent invents an output shape synthesis can't consume), and leaving the output shape unstated. The pattern's [default output shape](../patterns/orchestrated-review.md#default-output-shape) applies unless the dispatch names a different one.
```

`guides/task-decomposition-examples.md:32,35,38` carry `"Report in under 300 words."` /
`"under 200 words."` inside worked examples. Replace each with `"Report conclusions first."`
so the examples stop teaching the removed convention — examples are the strongest signal in a
prompt, so leaving them would reinstate the pattern the hunk removes.

### Hunk 6 — F5: remove the routing-reminder re-injection

```diff
--- a/hooks/wiring.json
 (remove the two UserPromptSubmit entries)
-  hooks/dd-routing-reminder.sh
-  hooks/batch-feedback-routing-reminder.sh
```
```sh
git rm hooks/dd-routing-reminder.sh hooks/batch-feedback-routing-reminder.sh
```

A removal is complete only when everything referencing it goes too. Before committing, sweep:

```sh
rg -n 'dd-routing-reminder|batch-feedback-routing-reminder' --glob '!node_modules'
```

Known referrers to update in the same change: `CLAUDE.md` (the hook cross-reference in the
`### Batch fan-out` section, which Hunk 7 rewrites anyway) and `docs/reviews/override-log.md`
(record that the 2026-06-23 broad-firing decision is superseded rather than deleting the row).
Check `test/` for any hook test that asserts the reminder fires.

### Hunk 7 — F6: `CLAUDE.md`, collapse the triple statement

```diff
@@ -46,~17 @@
 ### Batch fan-out (decision-tree row 2)
 
 Full workflow doc: `workflows/parallel-worktrees.md` (dispatch details, merge-and-reconcile mechanics, failure modes). The summary below is the routing trigger; load the workflow when actually fanning out.
 
-When a single message bundles **2+ independent tasks** — the common case being a batch of end-user feedback — the default failure is to grind through them sequentially in the main agent. Don't. Fan out.
-
-**Recognize a batch.** Any of these is enough: a numbered or bulleted list of asks; an enumeration phrasing ("a few things", "couple of bugs", "here's the feedback", "the following issues"); or several distinct imperatives in one message ("fix X, add Y, and change Z"). The bar is deliberately low — when in doubt whether two asks are independent, treat them as independent and fan out; merging back N small worktrees is cheap, re-running a sequential pass is not.
-
 **The procedure:**
 
 1. **Split.** Restate the batch as an explicit numbered task list (this is also the user's confirmation that you parsed their feedback correctly). Group any items that genuinely share files or state into one unit — those go to a single subagent so they don't collide.
 2. **Classify each item.** Route each item back through the decision tree *individually*. One item might be an RPI feature, another a one-line bug fix, another a DD decision. The batch row is a pre-pass; it does not pick the workflow for the items.
 3. **Dispatch.** Send the subagents in parallel — one Agent call per item, all in a single message. Give each subagent one item (or one shared-state group), a focused brief, and — for any item that **writes code** — an isolated git worktree (worktree isolation on the Agent call), so parallel implementations never touch the same working tree. Read-only/triage items don't need a worktree.
 4. **Merge and reconcile.** Collect results, merge the worktrees, and run the combined diff through `pr-prep` / `code-review` as one pass. If two items turn out to touch the same file after all, sequence those two and keep the rest parallel.
 
 **When NOT to fan out:** the items are actually one task wearing three hats (sequential dependencies, or all edits to the same function) — that's row 6 (RPI) or row 7 (task-decomposition), not row 2. Row 7 fans out *research* for one task; row 2 fans out *implementation* across many tasks. If unsure which, ask: "do these share files or an order?" Yes → 6/7. No → 2.
-
-A `UserPromptSubmit` hook (`hooks/batch-feedback-routing-reminder.sh`) escalates this row from skimmable prose to a harness-injected, non-blocking reminder when it detects multi-item phrasing — the same escalation pattern as the divergent-design routing reminder.
```

The two deleted paragraphs restate decision-tree row 2, which already carries the trigger, the
worked example, and the don't-collapse warning; the deleted final paragraph documents the hook
Hunk 6 removes. The procedure and the row-2-vs-row-7 discriminator are mechanics the table row
does not carry and stay.

Apply the same trim to row 3's prose if you take this hunk: the `divergent-design` precedence
rule is stated in the table row, in `skills/divergent-design/SKILL.md`, and in
`workflows/divergent-design.md`. One statement, in the table row, is enough.

### Hunk 8 — F9: `workflows/research-plan-implement.md`

```diff
@@ -82,1 +82,1 @@
-The research must be thorough. Read the actual implementations, not just signatures. If the research is wrong, everything downstream will be wrong.
+Read the actual implementations, not just signatures. If the research is wrong, everything downstream will be wrong.
```

### Hunk 9 — F10: `scripts/cross-model-review.py`

```diff
@@ -372,1 +372,3 @@
-    ap.add_argument("--judge", default="anthropic/claude-sonnet-4.5", help="pinned judge model for stage-2 matching")
+    # Pinned on purpose: changing the judge breaks score comparability with earlier runs.
+    # Re-baseline deliberately and note the cutover in the run log when you move it.
+    ap.add_argument("--judge", default="anthropic/claude-sonnet-5", help="pinned judge model for stage-2 matching")
```

### Hunk 10 — F7: skill descriptions

Not rendered as a single hunk: it is 25 independent rewrites, and each needs the skill's own
trigger eval re-run afterward, since these are routing text and F7's whole risk is
under-triggering. The shape for each, worked on `what-if-analysis`:

```diff
-description: Perform a structured prospective consequence analysis of a proposed change — a plan, design, migration, refactor, policy, or any artifact that proposes doing something different from the status quo. This skill systematically explores "what if this assumption is wrong?" … Use this skill when the user asks things like "what could go wrong with this", "stress-test this plan", "what am I not seeing", "what are the risks", "what are the second-order effects", "what breaks if we're wrong", "what assumptions is this making", or "what if this assumption doesn't hold". Also trigger when …
+description: Prospective consequence analysis of a proposed change — traces second-order effects, maps hidden couplings, and stress-tests the assumptions a plan rests on. Use when the question is what happens if the plan is wrong, what breaks downstream, or what the plan is quietly assuming. Distinct from pre-mortem, which starts from an assumed failure and narrates backward; this one starts from the proposal and works forward.
```

Primary capability and trigger inside the first 250 characters; the phrase list collapses to
the intent categories that generate it; the sibling-disambiguation sentence stays, because
distinguishing `what-if-analysis` from `pre-mortem` is exactly the routing judgment the
description has to support. Scope notes and when-not-to-use text move into the body.

---

## Step 7 — verification notes

Every hunk above is a hypothesis. Before committing:

- **F3, F5, F6 are behavioral.** Run the orchestrator evals in `test/skills/` before and after — `test/skills/cross-skill-eval.md` and the per-skill `eval-criteria.md` files are the existing probes. The specific regression to watch for after F3 and F5: the orchestrator writing critiques itself instead of dispatching. If it regresses, re-add the rule in its minimal form (one sentence), not the original block.
- **F4 touches six files at once.** It is the one change here worth splitting: take the `patterns/orchestrated-review.md` convention first, run a dispatch-heavy workflow, and confirm sub-agent output is still scannable before propagating to the inheriting sites.
- **F7 risks under-triggering**, which is the failure mode routing text exists to prevent. Rewrite one description, run that skill's trigger eval, and only then batch the rest.
- **F1, F2, F9, F10 are safe** — a duplicate file, a wrong tool name, one deleted virtue sentence, and a version pin. No behavioral probe needed beyond the referrer greps named in their hunks.
- **Re-run this audit at the next model release.** Prompts are per-model artifacts; the findings above are relative to Claude Fable 5.1 / Opus 5.

---

## Application status (2026-09-11)

| Finding | Status |
|---|---|
| F2 — `Task tool` → `Agent tool` | **applied** (`skills/draft-review/SKILL.md`) |
| F3 — "Mandatory Execution Rules" pressure blocks | **applied** (draft-review, code-review, matrix-analysis; the restatements at the Stage-2 headers are now one plain sentence) |
| F4 — `<300 words` output cap | **applied** — convention rewritten in `patterns/orchestrated-review.md` as "Default output shape"; inheriting sites updated (`guides/sub-agent-briefing.md` including the worked example at :29 and the "word cap" rationale at :36, the `guides/README.md` index line, `workflows/task-decomposition.md`, `guides/task-decomposition-examples.md`, `skills/matrix-analysis/SKILL.md`) |
| F6 — batch fan-out restated in prose | **partially applied** — the two paragraphs restating decision-tree row 2 are cut from the always-loaded instructions file. The hook cross-reference paragraph stays until F5 is decided. The row-3 (`divergent-design`) trim is not applied: it is routing text carrying the same under-trigger risk as F7 and wants its own pass. |
| F9 — "The research must be thorough" | **applied** |
| F10 — judge pin | **applied** — `anthropic/claude-sonnet-5`, with the comparability-break comment. The OpenRouter slug is unverified against the live model list (no egress from this sandbox); confirm before the next cross-model run. |
| F1 — instructions file loaded twice | **applied** — the file moved to `global-instructions/CLAUDE.md`. Option A was rejected: the global copy exists for *every other* project, and the duplication is specific to this repo, where the payload source doubled as the project instructions. `install.sh` now stages payload entries under their basename, so the image layout and `link-claude-home.sh` are unchanged; `health-check.sh` reads the path from `GLOBAL_MD`. Decision log row 47. Takes effect at the next install + rebuild. |
| F5 — remove the routing-reminder hooks | **declined 2026-09-11.** The 2026-06-23 override-log decision to keep the batch hook's broad firing stands, and the divergent-design reminder stays with it. Recorded here so a future pass does not re-raise it as an open finding: the re-injection cost is known and accepted. |
| F7 — 25 skill descriptions | **open** — 25 rewrites, each gated on its own trigger eval per the audit's verification note. |
| F8 — `code-review` split | **applied** — `references/rubric.md` (515 lines: template, tier definitions, evidence grounding, severity mapping, escalation rule, both evidence channels, status line), `references/chat-synthesis.md` (126), `references/override-log.md` (52). SKILL.md 1,909 → 1,256 lines, with a `## Reference files` index near the top and every crossing anchor rewritten. Still over the 500-line ceiling: the next candidates are Stage 1's dispatch template (~240 lines) and Stage 3's synthesis procedure (~160), both currently pipeline-resident. Four contract suites now read the skill's full surface (SKILL.md + references in document order); the golden-fixture sync test reads `references/rubric.md`. All 97 tests across the seven `test/skills/code-review-*.bats` suites pass (53 in the four this change modified). |
| F11 — business-plan scaffold extraction | **open** — deliberate restructure, its own change. |
| F12, F13 | flag-only, unchanged. |
