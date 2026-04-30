---
value-justification: "Replaces unbounded exploration of unknowns with timeboxed feasibility checks that produce a clear go/no-go decision."
---

# Spike Workflow

## When to use
- Evaluating whether a library or tool can do what you need
- Testing a technical approach before committing to it
- Answering "is this feasible?" or "how hard would this be?"
- Exploring an unfamiliar API or language feature

## When to pivot

- **→ RPI**: The most common pivot. When the spike answers "yes, this works," its RPI seed section (see step 4) is the handoff — load it as initial input to RPI research rather than starting from scratch.
- **← From RPI**: When RPI research hits a "is this even feasible?" question that can't be answered by reading code, pause RPI and spike it. Carry the research doc's invariants as constraints for the spike.
- **← From DD**: When a DD candidate needs feasibility validation, spike the uncertain option. The spike's findings feed back into DD's tradeoff matrix.

## Process

### 1. Define the question (essential)

State the specific question the spike answers in one sentence. Examples:
- "Can pdf-parse extract table structure from our sample PDFs?"
- "How does Lean 4's tactic framework handle custom syntax?"
- "What's the latency of OpenRouter's streaming API for our use case?"

If you can't state the question clearly, the spike isn't ready to start.

**Optional: feasibility criteria** — When the spike question is genuinely binary ("can X do Y?", "is Z feasible?"), making success/failure criteria explicit up front leads to more decisive outcomes. Fill in this template:

> - **Success looks like:** _[concrete observable that means "go"]_
> - **Failure looks like:** _[concrete observable that means "no-go"]_
> - **Ambiguous if:** _[what would leave the answer unclear — helps you plan what to test]_

Skip this for exploratory spikes where the goal is to learn rather than decide (e.g., "How does X's API handle Y?" — there's no pass/fail, just discovery). When you do use it, revisit these criteria in step 4's Answer section to force a clear verdict.

**Done when...**
- [ ] The question is stated in one specific, answerable sentence
- [ ] The question is about feasibility or behavior, not about implementation design
- [ ] Success and failure criteria are defined (explicitly via the template above, or implicitly in the question)

### 2. Set a timebox (recommended)

Spikes have a hard time limit. Default: **30 minutes of active work** (which may be 5-15 tool calls for an AI agent). If the question isn't answered by then, the answer is "this is harder than expected" — which is itself a useful answer.

**Done when...**
- [ ] A time limit is stated (default 30 minutes if not specified)
- [ ] The timebox is short enough to prevent the spike from becoming an implementation

### Abandon signals — when to stop before the timebox expires

These signals indicate the spike is no longer productive. When you notice one, stop working and act on it rather than continuing to the timebox limit.

- **No convergence.** The timebox is more than half spent and you're not closer to an answer than when you started — findings are contradictory, each experiment raises new questions rather than narrowing the space, or you're blocked on something outside the spike's scope. **Action:** Record what you tried, mark the spike as "inconclusive — needs different approach," and stop. The "what didn't work" list is the spike's deliverable.

- **Scope drift.** You've started investigating questions beyond the original one — adding "while I'm here" experiments, expanding to adjacent feasibility questions, or building more than the minimum needed to answer the question. **Action:** Stop. Check whether the original question is already answered (often it is, and the drift is a sign you're avoiding committing to the answer). If not, reframe: write down the new question as a separate spike, and finish or abandon the current one on its original scope.

- **Wrong question.** You discover the spike is answering a different question than what actually matters — the assumption behind the question was wrong, the real blocker is elsewhere, or the answer (whatever it is) won't change the decision. **Action:** Stop immediately. Don't salvage partial findings by bending them toward the real question. Record what you learned about *why* the question was wrong, reframe, and start a new spike with the corrected question.

When recording findings (step 4), note which signal triggered an early stop in the **Answer** section (e.g., "Stopped early: scope drift — original question answered at minute 15, additional exploration was beyond scope"). This makes spike records more useful for understanding why a spike ended the way it did.

### 3. Work in a throwaway space (essential)

```bash
git checkout -b spike/description-date
```

Spike code does NOT need to be clean, tested, or documented. It needs to answer the question. Cut every corner. Hardcode values. Skip error handling. Copy-paste from docs.

#### If you dispatch sub-agents

Some spikes probe libraries by fanning out — one sub-agent per candidate library, per API surface, or per documentation source. When you dispatch sub-agents from a spike, apply the [orchestrated review pattern](../patterns/orchestrated-review.md) — the same discipline `code-review` and `draft-review` use when they orchestrate parallel investigation:

- **Goal preamble**: prepend the [3-line preamble](../patterns/orchestrated-review.md#goal-preamble) (User goal / Current task / Success criterion) to each dispatch. The spike question from step 1 is the User goal, identical across all sub-agents in the run.
- **Goal-alignment self-report**: require each sub-agent to append the [Goal-Alignment Note](../patterns/orchestrated-review.md#goal-alignment-self-report) so coverage gaps, scope cuts, and silent guesses surface during synthesis rather than being absorbed into the spike record.

This discipline matters *more* under a tight timebox, not less — drift in a 30-minute spike eats the whole spike.

**Done when...**
- [ ] Work is on a dedicated spike branch, not on a feature or main branch
- [ ] The spike question from step 1 has been answered, OR the timebox from step 2 has expired

### 4. Record the findings (recommended)

Before discarding the spike branch, create a brief record:

```markdown
# Spike: [question]
Date: [date]
Last verified: [date]
Relevant paths: [repo-relative paths this spike investigated]
Branch: spike/[name] (can be deleted)
Time spent: [X minutes]

- **Goal**: [the spike question, restated as a one-sentence goal — what this spike is trying to determine]
- **Project state**: [<what this branch delivers> · <position in larger initiative, or "standalone"> · <blocked on, or "not blocked">]
- **Task status**: [in-progress | blocked | paused | complete] (optional phase note in parens, e.g., `in-progress (running candidate experiments)`)

## Answer
[1-3 sentences]

## Key findings
- [What worked]
- [What didn't]
- [Surprises or gotchas]

## Recommendation
[Proceed to RPI / Try alternative X / Need more investigation because Y]

## RPI seed (include if recommending "proceed")
- **Scope for RPI**: [One-sentence scope statement, ready to use as the RPI loop's scope]
- **Known invariants**: [Constraints or requirements discovered during the spike]
- **Relevant files/APIs**: [What the RPI research phase should read first]
- **Gotchas to carry forward**: [Non-obvious things that would bite someone who didn't do the spike]
- **What the spike did NOT answer**: [Gaps the RPI research phase still needs to fill]
```

The three-line header (Goal · Project state · Task status) immediately after the metadata block is the same drift-surfacing convention RPI working docs use (see `workflows/research-plan-implement.md` step 2). Lifecycle keyword vocabulary is identical: `in-progress | blocked | paused | complete`, with an optional parenthetical phase note. Update the **Task status** line whenever the spike record is read or revised; if any line no longer matches reality, fix it before doing anything else with the record.

The "RPI seed" section is the handoff point. When a spike recommends proceeding, the RPI research phase should start by loading the spike record — the seed section provides initial direction so research doesn't repeat work the spike already did. Anything the spike learned about what exists, what connects to what, and what's fragile belongs here, not just in "key findings."

Save this to `docs/spikes/` in the project if the findings are relevant long-term, or just report to the user if ephemeral.

Here's what a filled-in spike record looks like in practice:

> **Question:** Can pdf-parse extract table structure from our sample invoices?
>
> **Answer:** Partial go. It extracts simple tables reliably, but nested/merged-cell tables need post-processing.
>
> **Key findings:**
> - Simple grid tables (90% of our samples) extracted correctly with default settings
> - Merged cells produced duplicate data in adjacent columns — fixable with a dedup pass
> - Processing time was ~200ms per page, well within our 2s budget
> - The library has no built-in header detection; we'd need a heuristic based on bold/font-size
>
> **RPI seed:** Scope is "add PDF table extraction to the import pipeline." Key constraint: merged-cell dedup must happen before data hits the normalizer. Start with `src/importers/pdf.ts` and `src/normalizers/table.ts`. Recommended approach: use pdf-parse for raw extraction, add a thin dedup layer, feed into existing normalizer.
>
> **Limitations:** The spike only tested 12 sample invoices — all English, all generated (not scanned). It didn't test PDFs with embedded images, scanned documents, or non-Latin character sets. RPI research should check whether those exist in production uploads before committing to this library.

The exact sections don't matter — what matters is that the record captures a clear answer, what you learned, and enough context that someone starting the RPI phase doesn't repeat the spike's work or miss known gaps.

**Done when...**
- [ ] Spike record opens with the three-line header (Goal · Project state · Task status) immediately after the metadata block
- [ ] The Task status line accurately reflects current lifecycle (re-read it; if it lies, fix it)
- [ ] The spike question has a clear answer (yes/no/conditional) stated in 1-3 sentences
- [ ] Key findings include what worked, what didn't, and any surprises
- [ ] A recommendation is stated (proceed to RPI / try alternative / need more investigation)
- [ ] If recommending "proceed," the RPI seed section is populated with scope, invariants, relevant files, gotchas, and gaps

**Promote lasting discoveries.** If the spike produced knowledge with lasting value beyond the current task — library limitations, undocumented API behavior, approaches definitively ruled out — promote those findings to `docs/thoughts/` with `Last verified` and `Relevant paths` freshness fields before deleting the spike branch. This prevents valuable discovery from being lost when the throwaway branch is cleaned up. Even a 3-line note like "pdf-parse silently drops merged cells — discovered in spike 2024-03-15" is worth preserving if it would save a future session from re-discovering the same limitation.

### 5. Decision output (recommended)

If the spike's findings resolve a question with **meaningful tradeoffs** (multiple viable options, non-obvious consequences), create or update a decision record in `docs/decisions/NNN-title.md`. If the answer is **unambiguous** (one clear winner, straightforward rationale), add a row to `docs/decisions/log.md` instead. In either case, note the spike record as the source (e.g., "Based on spike: [question]"). Skip this step if the spike's answer is purely "proceed to RPI" with no architectural choice involved.

### 6. Clean up (advanced)

```bash
git checkout main
git branch -D spike/description-date  # unless findings are worth preserving
```

Spike branches should not be merged. If the spike validates an approach, start a fresh feature branch and implement properly using the research-plan-implement workflow. The spike record (especially the RPI seed section) serves as input to the RPI research phase — not a substitute for it.

**Done when...**
- [ ] Spike branch has been deleted (or explicitly preserved with a reason noted in the spike record)
- [ ] No spike code has been merged into feature or main branches
- [ ] If proceeding to RPI, a fresh feature branch is started from main

## When to reference a spike

Before citing a spike record's findings (e.g., loading an RPI seed), check whether its conclusions are still valid:

```bash
git log --oneline --since="<Last verified date>" -- <Relevant paths>
```

If commits appear, read them to decide whether they invalidate the spike's findings. If they do, re-run the spike or note the discrepancy. If not, update `Last verified` to today's date. See `guides/doc-freshness.md` for the full heuristic.
