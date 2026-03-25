# Divergent Design Workflow

*The diverge → diagnose → match → decide structure follows the [orchestrated review pattern](../patterns/orchestrated-review.md), with candidate approaches as the units of parallel evaluation.*

## When to use
- Architectural decisions (how to structure a feature, which pattern to use)
- Library or tool selection
- Major feature design where multiple approaches exist
- Any decision where premature convergence is a risk
- **As a sub-procedure within RPI**: When the research phase of `research-plan-implement.md` reveals a design decision, DD is invoked inline. The decision output feeds back into RPI's research doc and informs the plan. See RPI step 2 for trigger signals.

## When to pivot

- **← From RPI** (see RPI step 2 for triggers): Carry the research doc's invariants and constraints into DD's diagnosis step (step 2) — they're already half the work.
- **→ RPI**: After DD produces a decision, return to RPI's plan step with the decision doc as input. Reference it from the plan; don't duplicate the rationale.
- **→ Spike**: If DD candidates require feasibility validation, run a timeboxed spike on the uncertain option before finalizing the decision. The spike's findings update DD's tradeoff matrix.

## Process

### 1. Diverge — generate many possibilities

#### Completion signals
- You have 8+ candidates, including at least one naive, one do-nothing, and one unconstrained-ideal option.
- You haven't evaluated any candidate yet — if you're already ranking, you converged too early.

Generate 8-15 candidate approaches. Quantity matters more than quality at this stage. Requirements:
- Include at least 2-3 approaches that feel wrong, naive, or unconventional
- Include at least 1 "do nothing" or "minimal change" option
- Include at least 1 approach that would be ideal if effort/complexity were free
- One sentence each, no evaluation yet
- Number them for reference

### 2. Diagnose — specify the actual problems and constraints

#### Completion signals
- Every constraint is specific and testable — you could check a candidate against it with a yes/no answer.
- You've distinguished hard constraints (must satisfy) from soft ones (prefer to satisfy).
- You've included at least one non-obvious constraint (maintenance burden, team skills, deployment).

List every concrete problem, requirement, and constraint the solution must address. Be specific:
- ✓ "The reviewer in IST timezone needs to understand intent in <5 minutes from the PR description alone"
- ✗ "Code should be readable"

Include non-obvious constraints: timezone gaps, skill gaps in the team, maintenance burden, deployment complexity, interaction with existing code, performance requirements. Also note which constraints are hard (must satisfy) vs soft (prefer to satisfy).

### 3. Match and prune

#### Completion signals
- The matrix has no blank cells — every candidate is evaluated against every constraint.
- All survivors address every hard constraint (no ⚠ or ✗ on hard constraints).
- You're left with 3-5 survivors, not 1 (that's premature convergence) or 8+ (that's insufficient pruning).

Create a rough compatibility matrix:

| # | Approach | Problem 1 | Problem 2 | ... |
|---|---------|-----------|-----------|-----|
| 1 | ...     | ✓         | ~         | ... |

Key:
- ✓ addresses well
- ~ partial or uncertain
- ✗ doesn't address
- ⚠ actively makes worse

For approaches that score well overall but have one fixable weakness, briefly sketch how to fix it (1-2 sentences). Discard anything with ⚠ on a hard constraint or mostly ✗ across the board.

### 4. Tradeoff matrix and decision

#### Completion signals
- You've stress-tested with at least 2 moves and updated the matrix if they revealed new information.
- You can state your confidence level: >80% means proceed; below that means consult the user.
- The leading approach's key downside is explicitly named, not hand-waved.

For the top 3-5 survivors, create a detailed comparison:

| Approach | Effort (hours/days) | Risk | Core problem coverage | Key downside |
|----------|-------------------|------|----------------------|--------------|

#### Stress-test pass

After building the tradeoff matrix, pressure-test the surviving approaches using these cognitive moves adapted from structured critique methods. Not all moves apply to every decision — use the ones that illuminate genuine differences between approaches.

| Move | What to ask | Best for |
|------|------------|----------|
| **Boring alternative** | Is there a simpler approach that gets 80% of the benefit? Does this approach's complexity earn its keep, or is the simpler version good enough? | Always worth checking — especially when a sophisticated approach is winning |
| **Invert the thesis** | Argue sincerely for the opposite choice. What survives? What assumptions does the leading approach rest on that you haven't defended? | When one approach seems obviously best — the obvious answer is where hidden assumptions hide |
| **Revealed preferences** | What do teams/users/systems actually do, vs. what they say they want? If the codebase already has a similar decision point, what did it choose and how did that go? | API design, developer experience, convention choices |
| **Push to extreme** | Extend this approach's logic further than intended. What breaks? What hidden boundary conditions emerge? | Architecture decisions where the design will be lived with for a long time |
| **Organizational survival** | Does this survive team turnover, priority shifts, and the person who championed it leaving? Will the next maintainer understand why this choice was made? | Decisions with long maintenance tails — framework selection, data model choices |
| **Scale test** | What happens at 10x the current traffic, data, users, or contributors? Does the approach degrade gracefully or hit a cliff? | Scalability-sensitive decisions |
| **Implementation org chart** | Who builds this? Who maintains it? What skills does the team actually have vs. need to acquire? | Build-vs-buy, framework selection, anything requiring new expertise |

Apply 2-4 of the most relevant moves to each surviving approach. Update the tradeoff matrix if the stress test reveals new information — a changed risk rating, a previously unnoticed downside, or a boring alternative that should have been a candidate from the start.

#### Decision

If one approach clearly dominates (>80% confidence): document the decision and proceed.

If the tradeoff is genuinely unclear: **stop and consult the user.** Present the matrix, state your tentative recommendation with reasoning, and identify what information would resolve the ambiguity.

### 5. Document

#### Completion signals
- The decision doc captures rationale and consequences — a future reader can understand *why*, not just *what*.
- Rejected alternatives are listed briefly so the decision isn't relitigated.

Create or update `docs/decisions/NNN-title.md` with:
- Context: what prompted the decision
- Options considered (brief — the full analysis doesn't need to be preserved)
- Decision and rationale
- Consequences: what this makes easier, what this makes harder
