---
name: draft-review
description: >
  Orchestrate a comprehensive review of a written draft (blog post, essay, op-ed, policy memo,
  investor deck, fundraising memo, founder pitch, go-to-market doc, or any prose argument) by
  coordinating fact-checking and critic agents. Runs a 3-stage pipeline: fact-check → critic
  agents in parallel → synthesis into a freeform chat summary plus a structured verification
  rubric with red/amber/green status tracking. Auto-selects from available critics
  (`cowen-critique`, `yglesias-critique`, `ai-personas-critique`, `business-plan-critique-moat`,
  `business-plan-critique-unit-economics`) based on draft topic. Supports ensemble mode for
  higher confidence through convergence analysis. Use this skill whenever the user wants a
  thorough review of a draft that combines fact-checking with substantive critique. Trigger
  phrases: "review this draft", "give me feedback on this", "fact-check and critique this",
  "review my essay/post/memo/pitch/deck", "what am I missing", "multiple perspectives on this
  piece", "stress-test this argument". For reviewing a single concern (just fact-check, just
  one critic lens), use the standalone skill instead. For code review, use `code-review`.
when: User wants a thorough multi-perspective review of a written draft
---

## Dependencies

This skill orchestrates the following sub-skills. Skills live at `skills/<name>/SKILL.md`.
Ensure they exist before use.

**Required (always run):**
- `fact-check` — verifies factual claims in the draft

**Known critics (consider for every run, auto-select per Step 2):**
- `cowen-critique` — economist-style argument pressure (default for essays, op-eds, policy)
- `yglesias-critique` — pragmatic mechanism-vs-goal critique of any proposed action
- `ai-personas-critique` — ensemble of orthogonal AI personas; surfaces concerns single critics miss
- `business-plan-critique-moat` — moat, distribution, competitive response (business-plan-shaped drafts)
- `business-plan-critique-unit-economics` — CAC, LTV, contribution margin, payback (business-plan-shaped drafts)

**Not applicable (skip):**
- `code-fact-check`, `security-reviewer`, `performance-reviewer`, `api-consistency-reviewer`,
  `architecture-review`, `ui-visual-review` — these review code, not prose
- `code-review`, `matrix-analysis`, `draft-review` itself — other orchestrators

> On bad output, see guides/skill-recovery.md

# Draft Review Orchestrator

You are an orchestrator. You coordinate a multi-stage review of a written draft by dispatching
work to specialized sub-agents and then synthesizing their output.

You produce two deliverables: a freeform chat summary and a structured verification rubric
document.

---

## Mandatory Execution Rules

These rules are absolute. Do not deviate from them under any circumstances.

1. You MUST use the Agent tool to spawn sub-agents for ALL fact-checking and critique work.
   You MUST NOT write fact-checks or critiques yourself. You are the orchestrator, not an
   analyst. If you find yourself writing analytical observations about the draft's claims or
   arguments, STOP — you are doing a sub-agent's job.

2. You MUST complete Stage 1 (fact-check) and receive its results before starting Stage 2
   (critics).

3. You MUST complete Stage 2 (critics) and receive ALL critic results before starting Stage 3
   (synthesis and rubric).

4. You MUST NOT produce the verification rubric or chat synthesis until you have received
   results from every sub-agent you dispatched. No exceptions.

5. If a sub-agent fails or returns empty, note this honestly in the synthesis. Do not fill in
   the gap yourself.

---

## Selection Disposition

When choosing which critic agents to run, default to **including** any critic that does
cognitive work the draft might benefit from, rather than defaulting to exclude. Critics run
cheaply in parallel; the synthesis step naturally folds redundant findings together. The cost
of running an extra critic is small — the cost of missing a high-signal critique is larger.
Reserve exclusion for critics that obviously don't apply (e.g., a UI-visual reviewer on a
written essay).

---

## Before You Begin: Communicate the Plan

Before launching any sub-agents, tell the user what you're about to do. This is important —
the user should understand the pipeline and what agents are available.

### Step 1: Confirm critic taxonomy

The orchestrator uses the fixed taxonomy in the [Dependencies](#dependencies) block above.
Do **not** scan the filesystem at runtime — skills live at `skills/<name>/SKILL.md`, and any
new prose-critic skill should be added to that block explicitly so its triggers are documented.
If a listed critic skill file doesn't exist, skip it and note the gap in your plan summary.
If the user references a critic not listed, treat their request as authoritative (Step 2 below).

### Step 2: Select critic agents

**User instructions always take priority.** If the user specifies which critics to use (e.g.,
"use the Cowen critique" or "just the moat one"), follow their instructions exactly.

Otherwise, auto-select per the table below. Per the Selection Disposition above, default to
including critics rather than excluding them.

| Draft signal | Auto-include |
|---|---|
| Essay, op-ed, blog post, policy piece, primer, or any argument-shaped prose | `cowen-critique` |
| Draft proposes any mechanism, action, intervention, or policy — author wants something to happen | `yglesias-critique` |
| Multi-domain proposal, or user asks "what am I missing", "diverse critiques", "stress-test from multiple angles" | `ai-personas-critique` |
| Business-plan-shaped draft: founder pitch, investor deck narrative, GTM strategy doc, fundraising memo, product strategy brief | `business-plan-critique-moat` AND `business-plan-critique-unit-economics` (run both — they cover complementary failure modes) |

Multiple rows can match — invoke all matching critics. If the bar for a critic is unclear, include it.
The bar for exclusion is "obviously inapplicable" (e.g., business-plan critics on a poem),
not "topic doesn't match exactly."

**Short or narrowly scoped drafts:** For drafts under ~500 words or tightly focused pieces,
consider running only the 1–2 most relevant critics rather than the full panel. Small content
tends to produce redundant findings across multiple critics, and the extra agents consume
context budget without adding signal. When you reduce the panel for this reason, note it
explicitly in Step 4 (e.g., "Using a reduced critic panel — this is a short draft where
additional critics would likely produce redundant findings").

### Step 3: Capture draft intent

Critics scope findings better when they know what the draft is trying to accomplish. Capture
this once here and reuse it in Stage 2.

- **If the user provided a thesis, goal, or framing for the draft** (e.g., "this is meant to
  argue X", "the goal is to convince skeptics of Y", "this is a primer for Z audience"):
  capture their words verbatim as the intent.
- **Otherwise:** Compose a 2-line summary from the draft itself — line 1 from the title or
  headline, line 2 from the opening paragraph or lede. The summary should describe what the
  draft is and what it is trying to do, not what it says in detail.

Hold the resulting text as `<draft-intent>` for Stage 2. You will paste it verbatim under a
`## What this draft is trying to accomplish` heading in each critic's prompt so critics can
scope feedback to stated intent rather than treating the draft generically.

### Step 4: Tell the user

Before launching agents, briefly communicate:
- What critic agents you found and which you're going to use (and why, in a sentence)
- How many agents will run in total (e.g., "I'll run 1 fact-checker and 2 critics")
- If the user requested ensemble mode, confirm the count (e.g., "3 instances of each, so 9
  agents total")

Keep this brief — a short paragraph, not a lengthy explanation.

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
  intervene — e.g., counts of Inaccurate / Mostly Accurate / Unverified
  fact-check findings after Stage 1, or count of critics returned (and any
  that failed) after Stage 2.
- `<next action>` names the next stage and its parallelism — e.g., "launching
  2 critics in parallel" or "synthesizing into verification rubric and chat summary".

**Worked example:**

> Stage 1 (fact-check) complete: 2 Inaccurate, 1 Mostly Accurate, 3 Unverified — launching 2 critics in parallel (cowen-critique, yglesias-critique).
>
> Stage 2 (critics) complete: 2/2 critics returned (8 findings total) — synthesizing into verification rubric and chat summary.

**Scope:** The banner is emitted *only* between stages. Do **not** emit a
banner after Stage 3 — Stage 3's chat synthesis is itself the user-facing
output, and a "Stage 3 complete" banner would duplicate or compete with it.

### Stage 1: Fact-Check

Spawn fact-check sub-agent(s) using the Agent tool.

**Default:** 1 fact-check agent.
**Ensemble mode:** If the user requests it (e.g., "run 3 of each", "ensemble mode"), spawn
that many independent instances in parallel instead.

For each fact-check agent, you MUST:
1. Read the full contents of `skills/fact-check/SKILL.md`
2. Paste those contents directly into the Agent tool prompt (sub-agents cannot read your files)
3. Include the full draft text in the prompt
4. Instruct the agent to save its report as `docs/reviews/fact-check-report.md`
5. Require the agent to append a **Goal-Alignment Note** at the end of its report and chat
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
   make a non-trivial guess about what to fact-check (e.g., whether a quoted passage
   should be checked for accuracy of its source, or only paraphrased).
6. Launch via the Agent tool with `subagent_type: "general-purpose"`

**CHECKPOINT:** Wait for ALL fact-check agent(s) to return results. Count the results. Do you
have the expected number? If yes, proceed. If not, STOP and tell the user something went wrong.

If running ensemble: briefly synthesize the fact-check consensus before proceeding (which claims
do agents agree on, which do they disagree on). This consensus summary is what you'll pass to
the critic agents.

After receiving substantive results, emit the between-stage status banner per the
format spec above (e.g., `Stage 1 (fact-check) complete: <counts> — <next action>`).
Emit it before the Fact-Check Gate so the user sees stage progress even if the gate
pauses for input.

#### Fact-Check Gate (optional)

After receiving fact-check results, check whether any claims were rated **Inaccurate** at
**high confidence** (or, in ensemble mode, rated Inaccurate by consensus). If so:

1. **Pause before launching critics.** Present the fact-check findings to the user — specifically
   the inaccurate claims, what the evidence shows, and the confidence level.
2. **Ask the user how to proceed.** Offer three options:
   - **Continue** — proceed to Stage 2 as-is (the critics will see the current draft and the
     fact-check findings)
   - **Revise first** — the user wants to fix the draft before spending compute on critics
   - **Skip critics** — the user only needed the fact-check and will revise without critic input

This gate mirrors the plan-approval pattern from RPI: expensive downstream work should not run
if the upstream findings might change the input. Running critics on a draft with known factual
errors produces critique of text that will change, which wastes effort and can mislead.

If the user passed `--no-gate` or explicitly said to run without stopping, skip this gate and
proceed directly to Stage 2. If no claims were rated Inaccurate at high confidence, also skip
and proceed directly.

### Stage 2: Critic Agents

Now — and ONLY now — spawn critic sub-agents using the Agent tool.

**DO NOT write critiques yourself. You MUST dispatch each critique to a sub-agent via the Task
tool.** This is non-negotiable.

**Default:** 1 instance of each selected critic agent.
**Ensemble mode:** spawn N instances of each selected critic, where N matches the user's request.

For each critic agent instance, you MUST:
1. Read the full contents of that critic's skill file (e.g., `skills/cowen-critique/SKILL.md`)
2. Paste those contents directly into the Agent tool prompt
3. Include the full draft text
4. Include the draft intent captured in "Before You Begin" Step 3, prepended under a
   `## What this draft is trying to accomplish` heading so the critic can scope feedback to
   stated intent
5. Include the fact-check results (consensus summary if ensemble, or the single agent's findings)
6. Instruct the agent to save its critique as `docs/reviews/<skill-name>.md` — use the
   critic's skill filename without doubling the `-critique` suffix (e.g., `cowen-critique.md`,
   not `cowen-critique-critique.md`). The agent decides what goes in the file based on its own
   skill instructions — do not prescribe the format.
7. Require the agent to append a **Goal-Alignment Note** at the end of its critique and chat
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
   make a non-trivial guess about what to evaluate (e.g., which audience the draft
   targets, or whether to critique style or only argument structure).
8. Launch via the Agent tool with `subagent_type: "general-purpose"`

**Launch ALL critic agents simultaneously** in a single message with multiple Agent tool calls.
They must not see each other's output.

**CHECKPOINT:** Wait for ALL critic agent(s) to return results. Count the results. Do you have
the expected number? If yes, proceed to Stage 3. If not, STOP and tell the user what's missing.

After confirming the expected critic count, emit the between-stage status banner per the
format spec above (e.g., `Stage 2 (critics) complete: <counts> — synthesizing into verification rubric and chat summary`).
Emit it before launching Stage 3 so the user sees the handoff explicitly.

### Stage 3: Synthesize and Produce Outputs

You now have results from all sub-agents. NOW — and only now — produce your two deliverables.

**No banner after this stage.** Stage 3's chat synthesis (Deliverable 1) is itself the
user-facing output. Do not prepend or append a "Stage 3 complete" banner — it would
duplicate the synthesis. Banners are between-stage progress indicators, not synthesis output.

#### Goal-alignment scan (run before producing deliverables)

Before writing the chat synthesis, scan the **Goal-Alignment Note** appended by each
sub-agent (see [`patterns/orchestrated-review.md`](../../patterns/orchestrated-review.md)).
Collect:

- Any sub-agent whose `Answered:` value is `no` or `partial` — record the agent name
  and the one-phrase reason verbatim. In ensemble mode, record per instance (e.g.,
  "cowen-critique #2 — partial: skipped policy section").
- Any non-trivial `Out of scope:` item — anything other than the literal sentinel
  `none`. Record the agent name and the bullet text.
- Any non-trivial `Escalate:` item — anything other than the literal sentinel
  `nothing`. Record the agent name and the bullet text.

If a sub-agent omitted the note entirely, treat that as a `partial` entry with reason
"missing goal-alignment note" so the gap is still surfaced.

The collected items feed the `### Coverage and Escalations` section of the chat
synthesis below. They do not modify the rubric — coverage is a chat-synthesis concern.

#### Contrastive note (optional, capture during synthesis)

Pick one finding the panel caught well, plus one likely-related issue you suspect was missed (sources: goal-alignment notes, escalations, or your own scan of the draft). State both in 1–2 lines, then propose one concrete prompt-refinement candidate — an added instruction, sharpened heuristic, or new check for a critic skill — that would have closed the gap on the next run. Skip if no genuine contrast is available; do not invent one. Capture only — no feedback pipeline consumes this yet.

**Before synthesizing, cross-reference critic findings against the fact-check report.** For each
critic's output, identify the key claims or premises their arguments depend on. Check each one
against the fact-check verdicts:

- If a critic's reasoning **depends on** a claim the fact-checker rated **Inaccurate** or
  **Unverified**, that critique cannot stand as unqualified analysis. In the synthesis, present
  the critique with an explicit caveat: state which underlying claim is disputed or unverified,
  and note that the critique's force depends on a premise that did not survive fact-checking.
- If a critic's reasoning depends on a claim rated **Mostly Accurate** or **Disputed**, note
  the imprecision but do not disqualify the critique — flag it as conditional.
- If a critic's reasoning depends only on claims rated **Accurate**, no caveat is needed.

This extends the R5 disagreement protocol: where that protocol classifies critic-vs-critic
conflicts as factual or perspective-based, this step catches critic-vs-fact-checker conflicts
where a critic's argument is built on a factual premise the evidence does not support.

**In the chat synthesis**, when presenting a caveated critique, use this format:

> ⚠️ **Fact-check dependency:** [Critic name]'s argument that [summary] relies on the claim
> "[claim]", which the fact-checker rated [Inaccurate/Unverified]. This critique should be
> re-evaluated if the underlying claim is corrected or verified.

**In the verification rubric**, critiques with fact-check dependency caveats should be noted
in the 🟡 Amber tier with type "Fact-dependent critique" rather than being promoted to
standalone structural findings. This prevents flawed factual premises from inflating the
severity of structural critiques. These critic-sourced rows have no fact-check
`**Confidence:**` line of their own, so their Confidence cell renders `—` (see
[Confidence column](#confidence-column) in Deliverable 2) — do not borrow the confidence of
the disputed claim the critique depends on.

**Tracking for evaluation:** When any fact-critic cross-reference caveat is triggered, include
a line in the chat synthesis under a `### Fact-Critic Cross-References` heading listing each
instance (critic name, claim, fact-check verdict, and whether the caveat changed the synthesis
compared to what would have been presented without this check). This makes it possible to audit
whether the cross-referencing caught issues that would otherwise have appeared as unqualified
analysis.

---

## Deliverable 1: Freeform Chat Synthesis

Present this directly in the chat. It should be self-contained — assume the user has NOT read
the individual agent reports.

### Analyzing convergence (ensemble mode)

If running multiple instances per agent type, the convergence patterns are the signal:

*Within the same agent type:* Use these thresholds when reporting convergence. State the
numeric ratio (e.g., "3/3 agents") rather than a qualitative phrase like "most agree" — the
threshold table determines the confidence tier, not the synthesizer's impression.

| Agreement | Confidence tier | Interpretation |
|---|---|---|
| N/N | High confidence | All instances independently reached the same finding |
| (N-1)/N | Medium confidence | One dissenter; finding is likely but not unanimous |
| < (N-1)/N | Low / contested | Genuine disagreement; surface as a tension, not a finding |

*Across different agent types:*
- Fact-checker AND critics flag the same issue → very high signal
- Multiple critic types independently raise the same point → strong structural finding
- Critics disagree with each other → interesting tension worth surfacing

Note convergence counts (e.g., "3/3 agents", "2/3 agents") throughout the synthesis.

*Single-agent mode:* You still have cross-type signal. Where the fact-checker and multiple
critics independently flag the same issue, that's high confidence.

### Structure the chat synthesis as:

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

**Factual issues:** What the fact-check found. Group into: claims that need fixing (inaccurate),
claims that need precision (mostly accurate), and claims that are solid (confirmed accurate).

**Structural critique:** Synthesize by convergence signal, not by critic. Lead with findings
that multiple critics raised independently (highest signal) — rendered as the explicit
`### Convergence` callout described below. Then single-critic findings. Surface disagreements
between critics explicitly — these are valuable. Classify each disagreement as **factual**
(resolvable with more evidence) or **perspective-based** (genuine tension reflecting different
analytical frames). For factual disagreements, escalate to the fact-checker for a targeted
check or flag the specific claim for author research. For perspective-based disagreements,
present both positions with their reasoning. Whichever class a conflict falls into, you MUST
also record it in the **Critic Conflict Reconciliations** table below — the prose synthesis
is not a substitute for the row.

**Convergent objections (required):** When two or more critic agents independently surface
the same objection, you MUST produce an explicit `### Convergence` callout listing each
convergent objection. Matching is on the *topic* of the concern, not literal wording: two
critics calling out the same load-bearing issue under different vocabulary (e.g., one says
"the moat is weak", another says "competitors will copy the playbook within six months")
counts as one convergent objection even though the sentences share no content words. The
operative test is whether the author would receive a single coherent revision instruction
if the two findings were merged. Convergent objections are elevated above single-critic
objections in the **Actionable guidance** subsection — order them first, ahead of any
single-critic finding, and call out the convergence count inline (e.g., "raised by 2/3
critics") so the priority signal is visible at the action level, not only in the callout.

In ensemble mode, convergence may be cross-critic-type (different skills surfacing the same
objection) or within-type (multiple instances of the same critic skill consistently
surfacing the objection). Both count; attribute each entry to the specific instances that
raised it (e.g., "cowen-critique #1, cowen-critique #3, yglesias-critique #2"). The
existing `### Analyzing convergence (ensemble mode)` block above describes how to read
convergence as a *signal*; this directive specifies the *rendered output* for that signal
and applies in default mode (1 instance per critic) as well as in ensemble mode.

The `### Convergence` heading MUST appear in every run, even when nothing converged. When
no two critics surfaced the same objection, render the section with the exact literal line
`No convergent objections across N critics.` (substituting `N` with the total count of
critic instances run, including the degenerate single-critic case where convergence is
structurally impossible). The exact sentinel must be present verbatim — not paraphrased
to "no convergence" or "nothing converged" — so a re-reader (or a grep over saved
synthesis output) can confirm the check ran rather than was silently skipped. This mirrors
the audit-handle pattern used by the `### Coverage and Escalations` empty-case line and
the `### Critic Conflict Reconciliations` `"No critic conflicts surfaced."` line.

Use this format:

> ### Convergence
>
> - **<Objection topic in one short phrase>** — <one-sentence framing of the shared concern>.
>   *Raised by:* <critic-A>, <critic-B>[, <critic-C>...]
> - **<Next convergent objection>** — ...

When nothing convergent surfaced:

> ### Convergence
>
> No convergent objections across N critics.

**Worked example:**

> ### Convergence
>
> - **Moat is not structurally durable** — both critics flag that the named competitive
>   advantage relies on first-mover speed rather than a defensible asset; competitors can
>   replicate the playbook within a typical product-build cycle.
>   *Raised by:* business-plan-critique-moat, ai-personas-critique
> - **CAC payback assumption is fragile under realistic churn** — the plan's payback math
>   assumes steady-state retention that neither critic finds defended by the cited
>   comparables.
>   *Raised by:* business-plan-critique-unit-economics, cowen-critique

Convergent objections route through the **existing** 🟡 Amber rubric tier — the same
"Structural issues flagged by multiple critic types independently" rule already defined
under the tier-assignment block below. Do not invent a new rubric tier for convergent
objections; the elevation lives in chat synthesis ordering (lead position in Actionable
guidance) and in being named in this callout, not in a structural change to the rubric
tiers.

**Critic conflict reconciliation (required):** When two critics produce conflicting verdicts
on the same point, you MUST produce an explicit reconciliation row under a
`### Critic Conflict Reconciliations` heading. Never silently average, blend, or omit the
disagreement — averaging hides which lens the synthesis is filtered through, and silent
omission lets the louder or more verbose critic win by default. For each conflict, name
which critic's framing prevailed and explain why in one or two sentences, citing the
basis for the choice (draft intent from Step 3, fact-check evidence, scope, etc.). If the
tension is genuinely irreducible — both views defensible under the draft's stated intent —
record the verdict as `Both stand` and route the conflict to 🟢 Consider in the rubric so
the author decides; do not silently pick one. The row makes the orchestrator's reasoning
auditable.

Use this table format:

| # | Topic | [Critic A] position | [Critic B] position | Prevailing framing | Why |
|---|---|---|---|---|---|
| X1 | [What they conflict about] | [A's verdict, ≤1 line] | [B's verdict, ≤1 line] | [Critic A / Critic B / Both stand] | [Reason in 1–2 sentences, citing draft intent, fact-check, or scope] |

**Worked example:**

> ### Critic Conflict Reconciliations
>
> | # | Topic | cowen-critique position | yglesias-critique position | Prevailing framing | Why |
> |---|---|---|---|---|---|
> | X1 | Tone of policy section | Too academic — needs concrete cases | Strong as-is — generality fits a primer | cowen-critique | Draft intent (Step 3) names "policy practitioners" as the audience; concrete cases serve practitioners better than primer-style generality, so cowen-critique's framing prevails and the finding lands in 🟡 Amber. |
> | X2 | Whether to keep the counterargument section | Cut it — weakens the thesis | Expand it — strengthens credibility | Both stand | Genuine perspective tension between thesis-clarity and steelman-rigor; neither lens is privileged by stated intent. Routed to 🟢 Consider for author judgment. |

If no critics produced conflicting verdicts, render this section with a single line:
"No critic conflicts surfaced." The heading must still appear so reviewers can audit across
runs that no conflicts were silently dropped.

**What the draft gets right:** Strengths that critics identified. The author needs to know
what to preserve.

**Actionable guidance:** Key revisions, ordered by priority and convergence signal.

**Questions to clarify (if any sub-agent emitted them):** Scan each sub-agent's
Goal-Alignment Note for the optional "Questions I would have asked" bullet. If one or more
sub-agents emitted questions, surface them under a `### Questions to clarify` heading near
the end of the chat synthesis, just before "Actionable guidance" or as a sibling subsection.
De-duplicate: if multiple critics asked semantically the same question, list it once and
note the agreement (multiple critics asking the same question is a strong signal that the
draft itself is ambiguous about its own scope or audience). Attribute each question to the
sub-agent that raised it. If no sub-agent emitted the bullet, omit the section entirely —
do not invent placeholder questions.

Worked example:

> ### Questions to clarify
>
> Two critics flagged scope ambiguity:
>
> - **What audience is this draft for — policy practitioners or general readers?**
>   *(cowen-critique, yglesias-critique — both flagged independently.)* Both critics
>   evaluated against a general-reader frame; if the intended audience is policy
>   practitioners, several "needs more background" findings should be downgraded to
>   🟢 Consider.
> - **Is the section "Counterarguments" meant as a steelman or a strawman pass?**
>   *(yglesias-critique.)* The critic treated it as a steelman and judged it weak;
>   if you intended it as a brief acknowledgment, the finding doesn't apply.

---

## Deliverable 2: Verification Rubric Document

Save this as `docs/reviews/verification-rubric.md`. This is a structured, scannable
document the author uses to track revisions.

**Use this exact format:**

```markdown
# Draft Verification Rubric

**Draft:** [title] | **Checked:** [date] | **Status: 🔴 DOES NOT PASS** — [N] red item(s) unresolved

---

## 🔴 Must Fix

Factual errors identified by fact-check. Draft cannot pass verification with any red items
unresolved.

| # | Claim in draft | Issue | Confidence | Status |
|---|---|---|---|---|
| R1 | "[exact quote]" | [What's wrong. 1-2 sentences max.] | High | 🔴 Unresolved |

---

## 🟡 Must Address

Imprecise/unverified claims, plus structural issues flagged by multiple critics (high-signal).
Each must be fixed or acknowledged by author with a note explaining why it stands.

| # | Item | Type | Confidence | Status | Author note |
|---|---|---|---|---|---|
| A1 | [Description] | [Source, e.g., "Both critics", "Imprecise claim"] | Medium | 🟡 Open | — |

---

## 🟢 Consider

Ideas from one critic or tensions between critics. Not required to pass. For the author's
consideration only.

| # | Idea | Source |
|---|---|---|
| C1 | [Suggestion] | [Which critic] |

---

## Verified ✅

Claims confirmed accurate by the fact-check. No action needed.

| Claim | Verdict | Confidence |
|---|---|---|
| "[exact quote]" | ✅ Accurate | High |

---

To pass verification: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry an author note. 🟢 items are optional.
```

### Confidence column

The **Confidence** column in the 🔴 Must Fix, 🟡 Must Address, and ✅ Verified tables records
how sure the fact-check was about the verdict that produced the row. Populate it by copying the
value **verbatim** from the corresponding fact-check verdict's `**Confidence:**` line (one of
`High` / `Medium` / `Low`; see `skills/fact-check/SKILL.md`). In ensemble mode, copy the
consensus confidence the same way you derive the consensus verdict.

- **Never invent a confidence value.** If a row has no corresponding fact-check `**Confidence:**`
  line, render the cell as `—`. This is the normal case for 🟡 Must Address rows sourced from
  structural critic findings (`Both critics`, `Imprecise claim` from a critic, etc.) rather than
  from a fact-check verdict — critics emit no `**Confidence:**` line, so those rows always show `—`.
- A row whose source fact-check verdict exists but omits the `**Confidence:**` line also renders
  `—` — copy what is there, never backfill a guess.

The 🟢 Consider tier has no Confidence column: its rows come from critics, which carry no
fact-check confidence.

### Tier assignment rules

**🔴 RED — Must Fix:**
- Factual claims rated Inaccurate by fact-check (consensus if ensemble)
- Claims where the specific language is clearly wrong, even if the spirit is right
- Only factual errors go here. Structural critiques never go in red.

**🟡 AMBER — Must Address:**
- Factual claims rated Mostly Accurate (imprecise, needs tightening or justification)
- Factual claims rated Unverified (needs a source or justification)
- Structural issues flagged by multiple critic types independently
- In ensemble mode: structural issues flagged consistently within one critic type (all instances)

**🟢 GREEN — Consider:**
- Ideas from only one critic instance or one critic type with low internal consensus
- Tensions between critics
- Suggestions that would strengthen the draft but aren't problems with the current version

**✅ Verified:**
- All claims rated Accurate by fact-check
- Include so the author knows which facts are confirmed solid

**Confidence column (all tiers except 🟢 Consider):** Copy the value verbatim from the
source fact-check verdict's `**Confidence:**` line (High / Medium / Low). A row with no
source value — including structural critic findings in 🟡 Must Address — renders as `—`.
Never invent a confidence value. See [Confidence column](#confidence-column) above.

### Rubric status line rules

- Red items unresolved: `**Status: 🔴 DOES NOT PASS** — [N] red item(s) unresolved`
- Zero red but amber open: `**Status: 🟡 CONDITIONAL PASS** — [N] amber item(s) awaiting resolution or justification`
- All red and amber resolved: `**Status: ✅ PASSES VERIFICATION**`

---

## Output Locations

Save all review artifacts to `docs/reviews/` in the project root. This is the standard artifact
home for writing-review outputs, parallel to `docs/working/` for RPI artifacts and
`docs/decisions/` for design decisions.

```
docs/reviews/
├── verification-rubric.md
├── fact-check-report.md
├── <skill-name>.md              (one per critic used, e.g., cowen-critique.md)
```

If `docs/reviews/` doesn't exist, create it. If prior review artifacts exist there from an
earlier run, overwrite them — the rubric is designed for re-runs with updated status tracking.

At the end of your chat synthesis, link to all documents.

---

## Important Reminders

- **Always run fact-checking first.** Even if the user only asks for critic perspectives.
- **Paste skill file contents into agent prompts.** Sub-agents cannot read your filesystem.
- **All agents of the same stage run in parallel.** They must not see each other's output.
- **Be honest about convergence.** Don't present a minority finding as consensus.
- **The rubric is designed for re-runs.** When the author submits a revised draft, the pipeline
  re-runs and updates each status.
