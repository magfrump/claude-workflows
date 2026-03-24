---
name: tech-debt-triage
description: >
  Evaluate a piece of tech debt and produce a structured assessment: what it costs to carry,
  what it costs to fix, when it becomes urgent, and where it ranks relative to other work.
  Use this skill when the user asks "should we fix this", "is this worth refactoring",
  "how bad is this tech debt", "prioritize these cleanup tasks", or when planning work and
  deciding whether to address accumulated debt. Also trigger when code review surfaces
  something that works but is fragile, overly complex, or blocking future work. Can evaluate
  a single item or compare multiple debt items using the matrix-analysis pattern.
---

> On bad output, see guides/skill-recovery.md

# Tech Debt Triage

You are evaluating tech debt to help the user decide whether and when to address it. The goal
is not to advocate for or against fixing — it's to make the costs and tradeoffs explicit so
the decision is informed rather than based on gut feeling or guilt.

## Scoping

Determine what debt you're evaluating:

1. **If the user names specific code**: Read it thoroughly — implementation, callers, tests,
   and history (`git log` for the relevant files).
2. **If the user describes a category** ("our test setup is a mess", "the auth module needs
   rewriting"): Explore the area to understand the scope and nature of the debt.
3. **If asked to survey a codebase for debt**: This is a larger task — use the
   task-decomposition workflow to parallelize exploration, then triage each finding with
   this skill.

For each piece of debt, understand:
- What it is (the specific code, pattern, or structural issue)
- How it got this way (git history, design decisions, accumulated shortcuts)
- What depends on it (who calls this, who extends this, who is affected)

## Analysis Framework

### 1. Cost of carrying — what does this debt cost today?

Evaluate the ongoing costs of leaving the debt in place:

**Development friction**: Does this slow down work on nearby code? How often do developers
touch this area? Is it a bottleneck for common tasks?

**Bug risk**: Does this code have a history of bugs? Does its complexity make future bugs
likely? Are there latent bugs that haven't manifested yet?

**Cognitive load**: How much context does a developer need to safely modify this code? Is
the code misleading (looks simple but has hidden complexity)?

**Compounding**: Is this debt getting worse over time? Are other features building on top of
it, making future fixes harder? Is the cost growing linearly or exponentially?

Rate the carrying cost: **High** (actively slowing work or causing bugs), **Medium** (adds
friction but manageable), **Low** (ugly but inert — doesn't affect day-to-day work).

### 2. Cost of fixing — what would remediation require?

Estimate the fix:

**Scope**: How many files, functions, or systems need to change? Is it localized or does it
ripple across boundaries?

**Risk**: What could break? Are there adequate tests to catch regressions? Would the fix
require a migration, data transformation, or API change?

**Effort**: Rough size — hours, days, or weeks of focused work? Can it be done incrementally
or does it require a single coordinated change?

**Dependencies**: Does the fix block or depend on other work? Can it be done independently
or does it need to be sequenced with other changes?

**Opportunity cost**: What feature work or other improvements would be delayed by doing this
fix?

### 3. Urgency triggers — when does this become critical?

Identify conditions that would escalate this debt from "should fix" to "must fix":

- A planned feature that will be much harder to build on top of this debt
- A scaling threshold that this code won't survive
- A security or compliance requirement that this code violates
- A team change (someone who understands this code leaving, new people needing to modify it)
- A dependency EOL that forces changes in this area anyway

If none of these are imminent, the debt may be worth carrying indefinitely.

### 4. Fix-or-carry decision

Combine the analysis into a clear recommendation:

**Fix now** — carrying cost is high AND fix cost is manageable AND no urgent competing work.
Or: an urgency trigger is imminent.

**Fix opportunistically** — carrying cost is medium, fix is manageable, but there's no
urgency. Schedule it when someone is already working in this area.

**Carry intentionally** — carrying cost is low relative to fix cost. The debt is real but
the investment to fix it isn't justified right now. Document the known debt and the conditions
under which to revisit.

**Defer and monitor** — uncertain whether the debt will become urgent. Set a specific trigger
to re-evaluate (e.g., "revisit before starting the v3 API migration").

## Output

### For a single debt item:

```markdown
## Tech Debt Triage: {description}

**Location:** {file paths or module names}
**Nature:** {what kind of debt — structural, algorithmic, dependency, testing, naming, etc.}

### Carrying Cost: {High / Medium / Low}
{2-4 sentences explaining the ongoing costs}

### Fix Cost
- **Scope:** {localized / cross-cutting / systemic}
- **Effort:** {hours / days / weeks}
- **Risk:** {low / medium / high} — {one sentence on what could go wrong}
- **Incremental?** {yes — can fix in pieces / no — requires coordinated change}

### Urgency Triggers
- {trigger 1 and timeline if known}
- {trigger 2}
- {or: none identified — no imminent escalation}

### Recommendation: {Fix now / Fix opportunistically / Carry intentionally / Defer and monitor}
{2-3 sentences with rationale, referencing the analysis above}
```

### For multiple debt items:

When comparing several pieces of debt (e.g., "which of these should we tackle first"), produce
individual assessments and then a summary ranking:

```markdown
## Triage Summary

| # | Debt Item | Carrying Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|---|
| 1 | ... | High | Days | Imminent | Fix now |
| 2 | ... | Medium | Hours | None | Fix opportunistically |
| 3 | ... | Low | Weeks | None | Carry intentionally |

### Recommended Order
{If fixing multiple items, suggest sequencing based on urgency, dependencies between items,
and opportunities to batch related fixes.}
```

For large-scale debt surveys (5+ items across multiple criteria), consider using the
matrix-analysis skill for structured comparison.

## Output Location

Present the triage in chat. If the user requests a persisted artifact, save to
`docs/working/tech-debt-triage-{topic}.md`.

## Important

- **Read the code, not just the complaint.** The user's description of the debt may not match
  reality. Verify the scope and severity by reading the actual implementation.
- **Check git history.** How old is this code? How often does it change? Has it been partially
  fixed before? History tells you whether the debt is stable or actively accumulating.
- **Don't moralize.** All codebases have tech debt. The question is not "is this bad?" but
  "is fixing it worth the cost right now?" Some debt is worth carrying forever.
- **Consider the fix's second-order effects.** A refactoring that "cleans up" one module but
  forces changes in 20 callers may not be a net improvement. Account for the full blast radius.
- **Be honest about uncertainty.** If you can't estimate the fix cost because the scope is
  unclear, say so. A wrong estimate is worse than an honest "I'd need to investigate further."
