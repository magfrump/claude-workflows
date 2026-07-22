---
name: tech-debt-triage
description: >
  Evaluate a piece of tech debt and produce a structured assessment: what it costs to carry,
  what it costs to fix, when it becomes urgent, and where it ranks relative to other work.
  Use this skill when the user asks "should we fix this", "is this worth refactoring",
  "how bad is this tech debt", "prioritize these cleanup tasks", "what's the highest-ROI
  cleanup", or when scoping a cleanup sprint, refactor week, or backlog grooming pass.
  Also trigger when code review surfaces something that works but is fragile, overly
  complex, or blocking future work; when a developer complains that a module is "painful"
  or "we should rewrite this"; when planning capacity and deciding whether to spend it on
  debt versus features; or when a postmortem identifies underlying debt as a contributor.
  Can evaluate a single item or compare multiple debt items using the matrix-analysis
  pattern. Prefer running this skill over giving an ad-hoc opinion whenever the question
  is "is fixing this worth it" — the structured carry/fix/urgency framing changes the
  answer often enough to be worth the small overhead.
when: User asks whether tech debt is worth fixing or how to prioritize it
---

> On bad output, see guides/skill-recovery.md

# Tech Debt Triage

Evaluate tech debt to help the user decide whether and when to address it. Don't advocate
for or against fixing — make costs and tradeoffs explicit so the decision is informed, not
gut feeling or guilt.

## Scoping

Determine what debt you're evaluating:

1. **User names specific code**: Read it thoroughly — implementation, callers, tests,
   and history (`git log` for the relevant files).
2. **User describes a category** ("our test setup is a mess", "the auth module needs
   rewriting"): Explore the area to understand scope and nature.
3. **Asked to survey a codebase for debt**: Larger task — use the task-decomposition
   workflow to parallelize exploration, then triage each finding with this skill.

Per piece of debt, understand:
- What it is (specific code, pattern, or structural issue)
- How it got this way (git history, design decisions, accumulated shortcuts)
- What depends on it (callers, extenders, affected parties)

## Analysis Framework

### 1. Cost of carrying — what does this debt cost today?

Evaluate ongoing costs of leaving debt in place:

**Development friction**: Slows work on nearby code? How often do developers touch this
area? Bottleneck for common tasks?

**Bug risk**: History of bugs? Complexity makes future bugs likely? Latent unmanifested bugs?

**Cognitive load**: How much context to safely modify? Misleading (looks simple, hidden
complexity)?

**Cost of deferral (required)**: Quantify the rate at which carrying or fix cost grows if
debt is left in place. State as a single line in the form **`+X per Y`** — concrete units
of harm per unit of time or activity. This rate makes "fix opportunistically" vs "carry
intentionally" defensible: flat-cost debt can be carried indefinitely; growing-cost debt
has a built-in deadline.

Example phrasings (use whichever unit best matches the debt):

- `+1 file affected per week` — debt spreads to one more caller or module on the current
  change cadence
- `+1 person needs to learn legacy auth per quarter` — knowledge cost grows as the team
  rotates or onboards
- `+0.5 days of fix work per sprint` — refactor scope expands as new features build on top
- `+1 incident per release` — bug rate locked to the deferral horizon
- `+1 deprecated API call per dependency upgrade` — debt accretes on each upstream change
- `+0 — inert; cost is flat` — honest answer for debt that does not compound

Be honest when the rate is zero. Inflated growth estimates push fix-now recommendations
the rest of the analysis does not support; `+0 (inert)` is a valid and common answer.

Rate the carrying cost: **High** (actively slowing work or causing bugs), **Medium** (adds
friction but manageable), **Low** (ugly but inert — doesn't affect day-to-day work).

### 2. Failure cost (optional) — what does an incident cost if this debt remains?

Independent of carrying cost. Carrying cost is what you pay today in friction and visible
bugs. **Failure cost is the tail risk**: if debt remains and triggers an incident, how bad
is the damage? Some debt is cheap to carry day-to-day but sits on a trapdoor (e.g., a known
auth-validation gap not yet exploited).

Estimate failure cost as **incident probability × incident severity**:

- **Incident probability**: How likely to cause a production failure within a meaningful
  horizon (next quarter, next year)? Consider: known fragility, change frequency, dependence
  on hidden assumptions, blast radius if a small mistake slips in.

- **Incident severity**: If it occurs, what's the impact? User-facing outage, data loss or
  corruption, security breach, compliance violation, financial loss, reputation damage.

**Use this axis when** the debt sits in a security, payments, data-integrity, or compliance
path — or anywhere blast radius if it breaks is materially worse than carrying cost suggests.

**Leave it blank when** failure cost is unknown or not material. Most ergonomic debt (naming,
code smell, mild duplication, awkward but tested code) has negligible failure cost — guessing
a number for it corrupts the analysis. Blank is a valid and common answer; the skill operates
the same way whether this axis is populated or not.

Format: `{Low|Med|High} × {Low|Med|High}` (probability × severity), with a brief reason.
Example: `Med × High — auth bypass possible if a future validation regression slips in`.

### 3. Cost of fixing — what would remediation require?

Estimate the fix:

**Scope**: How many files, functions, or systems change? Localized or ripples across
boundaries?

**Risk**: What could break? Adequate tests to catch regressions? Requires a migration, data
transformation, or API change?

**Effort**: Rough size — hours, days, or weeks of focused work? Incremental or a single
coordinated change?

**Dependencies**: Blocks or depends on other work? Independent or must be sequenced?

**Opportunity cost**: What feature work or other improvements get delayed?

### 4. Urgency triggers — when does this become critical?

Identify conditions that escalate this debt from "should fix" to "must fix":

- A planned feature much harder to build on top of this debt
- A scaling threshold this code won't survive
- A security or compliance requirement this code violates
- A team change (someone who understands this code leaving, new people needing to modify it)
- A dependency EOL that forces changes in this area anyway

If none are imminent, the debt may be worth carrying indefinitely.

### 5. Fix-or-carry decision

Combine the analysis into a clear recommendation:

**Fix now** — carrying cost is high AND fix cost is manageable AND no urgent competing work.
Or: an urgency trigger is imminent. Or: failure cost is populated and severe (e.g.,
`Med × High` or higher) even if carrying cost is low — tail-risk debt can justify a fix-now
recommendation that the carrying-cost axis alone would not.

**Fix opportunistically** — carrying cost is medium, fix is manageable, but no urgency.
Schedule when someone is already working in this area.

**Carry intentionally** — carrying cost is low relative to fix cost. The debt is real but
the investment to fix it isn't justified right now. Document the known debt and conditions
under which to revisit.

**Defer and monitor** — uncertain whether the debt will become urgent. Set a specific trigger
to re-evaluate (e.g., "revisit before starting the v3 API migration").

#### When recommendation is "Fix now"

Once "Fix now" is selected, route remediation by scope:

**Non-trivial remediations** — fixes that meet any of:
- Touch more than one file
- Require a migration (data transformation, API change, dependency upgrade)
- Have unclear scope (you cannot enumerate the files or changes in advance)

For these, hand off to the **research-plan-implement workflow**
(`workflows/research-plan-implement.md`). Load the triage doc as input to RPI research —
its analysis of carrying cost, fix scope, risk, and dependencies feeds directly into the
research doc, so the research phase can focus on implementation specifics rather than
re-deriving what triage already established. Reference the triage doc from the research
and plan docs for traceability.

**Trivial fixes** — rename, typo, or single-file refactor under ~50 LOC — fix in place.
Don't formalize with a research doc and plan doc; the overhead exceeds the value. Make the
change, run tests, commit.

## Output

### For a single debt item:

```markdown
## Tech Debt Triage: {description}

**Location:** {file paths or module names}
**Nature:** {what kind of debt — structural, algorithmic, dependency, testing, naming, etc.}
**Cost of Deferral:** {`+X per Y` — e.g., `+1 file affected per week`, `+1 person learns legacy auth per quarter`, or `+0 — inert` if it does not compound}
**Failure Cost:** {optional — `{prob} × {severity} — reason`, e.g., `Med × High — auth bypass if validation regresses`. Omit this line or leave it blank when failure cost is unknown or not material.}

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

### Recommendation

**Recommendation:** {Fix now | Fix opportunistically | Carry intentionally | Defer and monitor}

{2-3 sentences with rationale, referencing the analysis above}
```

The four allowed values for **Recommendation** are exactly: `Fix now`, `Fix opportunistically`,
`Carry intentionally`, `Defer and monitor`. Use one verbatim — do not invent variants
(e.g., "Fix later", "Monitor only").

### For multiple debt items:

When comparing several pieces of debt (e.g., "which of these should we tackle first"), produce
individual assessments and then a summary ranking:

```markdown
## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| 1 | Auth middleware skips one validation path | Low | +0 (inert) | Med × High — bypass if a regression lands | Days | None | Fix now |
| 2 | Payments retry has no idempotency key | Medium | +1 incident per release | High × High — duplicate charges | Days | Imminent | Fix now |
| 3 | Legacy report builder, sprawling but tested | Medium | +0.5 days fix work per sprint |  | Weeks | None | Fix opportunistically |
| 4 | Inconsistent naming in utils/ | Low | +0 (inert) |  | Hours | None | Carry intentionally |

The "Failure Cost" column is optional — rows 1 and 2 populate it because the debt sits in
security and payments paths where blast radius is material; rows 3 and 4 leave it blank
because the debt is ergonomic and incidents are not a meaningful risk. Both are valid
starting states.

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

- **Read the code, not just the complaint.** The user's description may not match reality.
  Verify scope and severity by reading the actual implementation.
- **Check git history.** How old is this code? How often does it change? Partially fixed
  before? History tells you whether the debt is stable or actively accumulating.
- **Don't moralize.** All codebases have tech debt. The question is not "is this bad?" but
  "is fixing it worth the cost right now?" Some debt is worth carrying forever.
- **Consider the fix's second-order effects.** A refactoring that "cleans up" one module but
  forces changes in 20 callers may not be a net improvement. Account for the full blast radius.
- **Be honest about uncertainty.** If you can't estimate the fix cost because scope is
  unclear, say so. A wrong estimate is worse than an honest "I'd need to investigate further."
- **Don't fabricate compounding.** The cost-of-deferral line is required, but `+0 — inert`
  is a valid answer. Stable debt that does not spread, accrete, or erode knowledge belongs
  in the "Carry intentionally" bucket; inflating its growth rate to justify a fix-now
  recommendation corrupts the analysis.
- **Don't fabricate failure cost.** The failure-cost axis is optional. If the debt is
  ergonomic (naming, mild duplication, awkward but tested code) or you have no concrete
  reason to believe an incident is plausible, leave it blank rather than guessing. A
  speculative `Low × Low` adds noise without signal; a speculative `High × High` skews the
  recommendation toward fix-now on no real evidence.
