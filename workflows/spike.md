# Spike Workflow

## When to use
- Evaluating whether a library or tool can do what you need
- Testing a technical approach before committing to it
- Answering "is this feasible?" or "how hard would this be?"
- Exploring an unfamiliar API or language feature

## Process

### 1. Define the question

State the specific question the spike answers in one sentence. Examples:
- "Can pdf-parse extract table structure from our sample PDFs?"
- "How does Lean 4's tactic framework handle custom syntax?"
- "What's the latency of OpenRouter's streaming API for our use case?"

If you can't state the question clearly, the spike isn't ready to start.

### 2. Set a timebox

Spikes have a hard time limit. Default: **30 minutes of active work** (which may be 5-15 tool calls for an AI agent). If the question isn't answered by then, the answer is "this is harder than expected" — which is itself a useful answer.

### 3. Work in a throwaway space

```bash
git checkout -b spike/description-date
```

Spike code does NOT need to be clean, tested, or documented. It needs to answer the question. Cut every corner. Hardcode values. Skip error handling. Copy-paste from docs.

### 4. Record the findings

Before discarding the spike branch, create a brief record:

```markdown
# Spike: [question]
Date: [date]
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

### 5. Clean up

```bash
git checkout main
git branch -D spike/description-date  # unless findings are worth preserving
```

Spike branches should not be merged. If the spike validates an approach, start a fresh feature branch and implement properly using the research-plan-implement workflow. The spike record (especially the RPI seed section) serves as input to the RPI research phase — not a substitute for it.
