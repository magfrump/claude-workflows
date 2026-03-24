# Skill Recovery Guide

When a skill produces poor, empty, or off-target output, follow these tiers in order. Stop as soon as you get usable output.

---

## Tier 1: Retry with narrower scope or simpler input

Most skill failures come from overloaded input — too many files, too long a draft, or ambiguous scope.

**Strategies:**
- **Narrow the scope.** If the skill reviewed an entire branch diff, retry on a single file or function. If it fact-checked a full article, retry on one section.
- **Simplify the input.** Strip supplementary context (fact-check reports, prior reviews) and let the skill work from primary input only.
- **Make the request explicit.** If the original invocation relied on auto-detection (scope, criteria, target), specify these directly instead.
- **Reduce ensemble size.** If running in ensemble mode, retry with a single instance before diagnosing further.

**When to escalate to Tier 2:** Tier 1 fails if a second attempt with narrower scope still produces poor output, or if the problem is clearly structural (e.g., the skill's cognitive moves don't fit the input domain).

---

## Tier 2: Use an alternative skill

Some skills overlap in purpose or can substitute for each other in a degraded mode. Use this table to find alternatives.

### Prose pipeline

| Failing skill | Alternative | Notes |
|---|---|---|
| fact-check | *(none — skip to Tier 3)* | Critics can proceed without a fact-check report; they just won't have verified factual claims. |
| cowen-critique | yglesias-critique | Different lens but same pipeline role. Both accept the same input (draft + optional fact-check report). |
| yglesias-critique | cowen-critique | Same as above, reversed. |
| draft-review | Run fact-check + critics manually | The orchestrator dispatches sub-agents; you can do this yourself with individual skill invocations. |

### Code pipeline

| Failing skill | Alternative | Notes |
|---|---|---|
| code-fact-check | *(none — skip to Tier 3)* | Code critics can proceed without a fact-check report; they analyze code directly. |
| security-reviewer | performance-reviewer or api-consistency-reviewer | Different focus but same pipeline role. Won't catch security issues, but unblocks the review pipeline. |
| performance-reviewer | security-reviewer or api-consistency-reviewer | Same structure, different lens. |
| api-consistency-reviewer | security-reviewer or performance-reviewer | Same structure, different lens. |
| code-review | Run code-fact-check + critics manually | Same pattern as draft-review — the orchestrator is dispensable if sub-agents work. |

### Contextual code critics

| Failing skill | Alternative | Notes |
|---|---|---|
| test-strategy | tech-debt-triage | Overlapping concern — both assess code health from different angles. |
| tech-debt-triage | test-strategy | Reverse of above. |
| dependency-upgrade | *(none — skip to Tier 3)* | Highly specialized; manual changelog review is the fallback. |

### Cross-cutting

| Failing skill | Alternative | Notes |
|---|---|---|
| self-eval | *(none — skip to Tier 3)* | Walk through the rubric dimensions manually using docs/evaluation-rubric.md. |
| matrix-analysis | *(none — skip to Tier 3)* | Build a manual comparison table; the orchestrator adds structure but isn't irreplaceable. |

**When to escalate to Tier 3:** The alternative skill also fails, or no alternative exists for the failing skill.

---

## Tier 3: Skip and note the failure

If Tiers 1 and 2 don't produce usable output, skip the skill and document what happened.

**How to note the failure:**
1. In the output document (review rubric, synthesis, etc.), add a section noting which skill was skipped and why.
2. If an orchestrator dispatched the skill, it already handles this — rule 5 of the mandatory execution rules says to "note this honestly in the synthesis."
3. Log the failure for later investigation. If the project uses `docs/working/hypothesis-log.md`, add an entry: what skill failed, what input triggered it, and what the output looked like.

**The output is still usable.** A review missing one critic is better than no review. A code review without a fact-check pass still catches design issues. Note the gap and move on.
