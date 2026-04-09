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

**Done when...**
- [ ] The question is stated in one specific, answerable sentence
- [ ] The question is about feasibility or behavior, not about implementation design
- [ ] Success and failure criteria are implicit in the question (you'll know when it's answered)

### 2. Set a timebox (recommended)

Spikes have a hard time limit. Default: **30 minutes of active work** (which may be 5-15 tool calls for an AI agent). If the question isn't answered by then, the answer is "this is harder than expected" — which is itself a useful answer.

**Done when...**
- [ ] A time limit is stated (default 30 minutes if not specified)
- [ ] The timebox is short enough to prevent the spike from becoming an implementation

### 3. Work in a throwaway space (essential)

```bash
git checkout -b spike/description-date
```

Spike code does NOT need to be clean, tested, or documented. It needs to answer the question. Cut every corner. Hardcode values. Skip error handling. Copy-paste from docs.

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

The "RPI seed" section is the handoff point. When a spike recommends proceeding, the RPI research phase should start by loading the spike record — the seed section provides initial direction so research doesn't repeat work the spike already did. Anything the spike learned about what exists, what connects to what, and what's fragile belongs here, not just in "key findings."

Save this to `docs/spikes/` in the project if the findings are relevant long-term, or just report to the user if ephemeral.

**Done when...**
- [ ] The spike question has a clear answer (yes/no/conditional) stated in 1-3 sentences
- [ ] Key findings include what worked, what didn't, and any surprises
- [ ] A recommendation is stated (proceed to RPI / try alternative / need more investigation)
- [ ] If recommending "proceed," the RPI seed section is populated with scope, invariants, relevant files, gotchas, and gaps

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
