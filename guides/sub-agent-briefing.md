# Sub-Agent Briefing Patterns

Reference for writing prompts to dispatched sub-agents. A sub-agent starts with **zero context** — no conversation history, no idea why the work matters, no shared mental model with you. Brief it like a colleague who just walked into the room.

This is a standalone reference. Any orchestrator that dispatches sub-agents — including `code-review`, `draft-review`, `matrix-analysis`, and the `task-decomposition` and `codebase-onboarding` workflows — can cite it. Cross-references from those skills/workflows are intentionally deferred to a future round; the guide is usable on its own.

## The five elements of a well-formed prompt

Every sub-agent prompt should contain:

1. **Goal preamble** — one sentence stating why the work matters and how the output will be used. This lets the sub-agent make judgment calls instead of mechanically following instructions.
2. **Exact paths** — files, directories, or commands to examine. Don't make the sub-agent search for them.
3. **Specific questions** — numbered, falsifiable questions, not open-ended prompts like "how does this work?"
4. **Output cap** — explicit length limit ("under 200 words", "table only, no prose"). Without one, expect a wall of text.
5. **Output destination** — where to write findings (specific file path, or section heading within an existing doc). If the sub-agent should report inline, say so.

## Worked example — well-formed prompt

> **Goal:** We're planning to add a new API endpoint and need to understand how the existing auth pipeline works so the new endpoint follows the same pattern.
>
> **Examine:** `src/auth/` (especially `tokens.go` and `validator.go`) and `src/middleware/auth.go`. Also grep for `RequireAuth` to find call sites.
>
> **Answer:**
> 1. How are tokens validated — what library, what claims are checked?
> 2. Where is the auth middleware applied — every route, or selectively?
> 3. What happens on auth failure — exception, error response, both?
> 4. Are there bypass paths (e.g., for health checks or webhooks)?
>
> **Output:** Write findings to the **Auth** section of `docs/working/research-api-endpoint.md`. Keep each answer to 2–3 sentences. Cite specific file:line locations. Total length under 300 words.
>
> **Do not:** modify any code, propose design changes, or investigate non-auth subsystems.

Why this works:
- Goal preamble lets the sub-agent recognize when something it sees is structurally relevant vs. a red herring.
- Numbered questions are falsifiable — each has a definite answer to look for.
- Word cap forces the sub-agent to summarize, not paste code.
- Output destination keeps the artifact in a known location for synthesis.
- Explicit "do not" prevents scope creep, which is the most common failure mode of capable sub-agents.

## Anti-pattern catalog

Each anti-pattern below shows a broken prompt and the specific failure mode it produces.

### 1. Omitted paths

**Bad:**
> "Find out how authentication works in this codebase and report back."

**Why it fails:** The sub-agent burns its context budget on `find`, `grep`, and reading wrong files first. You pay for exploration the orchestrator could have skipped — the orchestrator already knows where auth lives.

**Fix:** Name the files. If you don't know them, run a quick `grep` yourself before dispatching.

### 2. Open-ended questions

**Bad:**
> "Read `src/auth/` and tell me how it works."

**Why it fails:** "How it works" has no termination condition. The sub-agent either returns a generic high-level summary (useless) or an exhaustive walkthrough (unreadable). You have no way to know whether it answered the question you actually had.

**Fix:** Numbered, specific questions. "Where are tokens validated?" beats "explain the auth system." If you genuinely need a high-level summary, ask for one explicitly: "Produce a 5-bullet overview, then answer questions 1–3."

### 3. Missing output cap

**Bad:**
> "Examine `src/auth/tokens.go` and explain what each function does."

**Why it fails:** The sub-agent has no signal for when to stop. Expect a wall of text re-deriving information you can read yourself. You then have to re-read the sub-agent's output to extract the parts that matter — the sub-agent's effort becomes a tax on yours.

**Fix:** State the cap. "Under 200 words." "One sentence per function." "Table with three columns." Whatever shape you can act on quickly.

### 4. Full-file paste

**Bad:**
> "Here is the full contents of `src/auth/tokens.go`: [pastes 800 lines]. Tell me how token validation works."

**Why it fails:** The sub-agent can read the file itself — pasting it doubles the context burn (your turn + the sub-agent's turn). Worse, large pastes crowd out the actual question, and the sub-agent may anchor on irrelevant sections.

**Fix:** Pass the path, not the contents. The exception is when the sub-agent can't read your filesystem (e.g., reviewing draft text that exists only in conversation) — then paste the minimum needed. For code review, sub-agents run their own `git diff` rather than receive a pasted diff.

### 5. Missing goal preamble

**Bad:**
> "Examine `src/auth/`. Answer: (1) How are tokens validated? (2) Where is the middleware applied? (3) What happens on failure?"

**Why it fails:** The sub-agent gets the questions but not the *why*. When it encounters an edge case the orchestrator didn't anticipate (e.g., "there are two auth middlewares — should I document both?"), it has no basis for judgment and either picks arbitrarily or asks a clarifying question that wastes a turn.

**Fix:** One sentence on the surrounding goal. "We're adding a new endpoint and want the new code to follow existing patterns" tells the sub-agent that completeness about *current* patterns matters more than judging which is best.

## Quick checklist

Before dispatching a sub-agent, verify the prompt has:

- [ ] **Goal preamble** — one sentence on why and how the output gets used
- [ ] **Exact paths** — files, directories, or commands named explicitly
- [ ] **Specific questions** — numbered, with definite answers
- [ ] **Output cap** — word count, sentence count, or structural format
- [ ] **Output destination** — file path or "report inline"
- [ ] **Do-not list** (optional) — scope guardrails for capable sub-agents prone to drift

If any of the first five are missing, expect proportionally worse output.

## When to dispatch sub-agents at all

Briefing well doesn't fix a bad decision to dispatch. Skip the sub-agent if:

- The work is faster done in the main agent than spent writing a tight prompt for it.
- The investigation depends on information you'll discover mid-task — sub-agents can't be steered iteratively the way the main agent can.
- Output quality matters more than parallelism (e.g., final synthesis, architectural decisions).

If you're invoking a sub-agent ad hoc inside a workflow, ask whether the cost of the prompt + the cost of re-reading the output is actually less than doing the work yourself.
