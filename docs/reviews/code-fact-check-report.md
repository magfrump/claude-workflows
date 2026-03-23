# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** `skills/code-review.md`, `patterns/orchestrated-review.md`, `docs/decisions/002-critic-style-code-review.md`
**Checked:** 2026-03-23
**Total claims checked:** 22
**Summary:** 17 verified, 3 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

---

## Claim 1: "code-review.md — that's you"

**Location:** `skills/code-review.md:75`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `skills/code-review.md` exists and its frontmatter `name: code-review` confirms this self-reference is accurate.

**Evidence:** `skills/code-review.md:1-2`

---

## Claim 2: "draft-review.md — prose review orchestrator"

**Location:** `skills/code-review.md:76`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `skills/draft-review.md` exists. Its frontmatter description says "Orchestrate a comprehensive review of a written draft by coordinating fact-checking and critic agents." Its heading is "Draft Review Orchestrator." Classifying it as "prose review orchestrator" is accurate.

**Evidence:** `skills/draft-review.md:1-17`

---

## Claim 3: "matrix-analysis.md — comparison orchestrator"

**Location:** `skills/code-review.md:77`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `skills/matrix-analysis.md` exists. Its heading is "Matrix Analysis Orchestrator" and it describes orchestrating "a structured evaluation of multiple items across multiple criteria." "Comparison orchestrator" is an accurate characterization.

**Evidence:** `skills/matrix-analysis.md:1-18`

---

## Claim 4: "code-fact-check.md — always runs in Stage 1"

**Location:** `skills/code-review.md:80`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High

The file `skills/code-fact-check.md` exists. The pipeline described in code-review.md (lines 131-143) confirms code-fact-check always runs in Stage 1, before any critic agents.

**Evidence:** `skills/code-fact-check.md:1-2`, `skills/code-review.md:131-143`

---

## Claim 5: Core critics "security-reviewer.md", "performance-reviewer.md", "api-consistency-reviewer.md"

**Location:** `skills/code-review.md:83-85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

All three files exist: `skills/security-reviewer.md`, `skills/performance-reviewer.md`, `skills/api-consistency-reviewer.md`. Each is a domain-specific code critic, not an orchestrator.

**Evidence:** Glob results for `skills/*.md`

---

## Claim 6: Contextual critics "test-strategy.md", "tech-debt-triage.md", "dependency-upgrade.md"

**Location:** `skills/code-review.md:88-90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

All three files exist: `skills/test-strategy.md`, `skills/tech-debt-triage.md`, `skills/dependency-upgrade.md`.

**Evidence:** Glob results for `skills/*.md`

---

## Claim 7: Prose critics listed as "fact-check.md, cowen-critique.md, yglesias-critique.md"

**Location:** `skills/code-review.md:93`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

All three files exist. `fact-check.md` performs journalistic fact-checking on prose drafts. `cowen-critique.md` and `yglesias-critique.md` are persona-based prose critics. Classifying them as "Prose critics (skip -- not applicable to code)" is accurate.

**Evidence:** `skills/fact-check.md:1-10`, `skills/cowen-critique.md:1-14`, `skills/yglesias-critique.md:1-14`

---

## Claim 8: "This workflow follows the [orchestrated review pattern](../patterns/orchestrated-review.md)"

**Location:** `skills/code-review.md:21`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `patterns/orchestrated-review.md` exists and the relative path `../patterns/orchestrated-review.md` from `skills/` is correct.

**Evidence:** `patterns/orchestrated-review.md` exists

---

## Claim 9: Security reviewer severity levels "Critical / High / Medium / Low / Informational"

**Location:** `skills/code-review.md:288-292` (unified severity mapping table, Security column)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The security-reviewer skill defines severity as "Critical / High / Medium / Low / Informational" at lines 204 and 216-220 of the skill file. The mapping in code-review.md correctly places Critical+High at red, Medium at amber, and Low+Informational at green.

**Evidence:** `skills/security-reviewer.md:204, 216-220`

---

## Claim 10: Performance reviewer severity levels "Critical / High / Medium / Low / Informational"

**Location:** `skills/code-review.md:288-292` (unified severity mapping table, Performance column)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The performance-reviewer skill uses "Critical / High / Medium / Low / Informational" at lines 200 and 215-219. However, the unified severity mapping in code-review.md maps Performance as: red=Critical, amber=High+Medium, green=Low+Informational. This differs from the Security column which maps red=Critical+High, amber=Medium. This asymmetry is intentional (Performance "Critical" is more narrowly defined in the skill as "unbounded resource consumption, O(n^2) or worse in hot path, DoS-enabling") but the mapping itself is internally consistent and matches the skill's definitions. The claim about the severity level names themselves is accurate.

**Evidence:** `skills/performance-reviewer.md:200, 215-219`

---

## Claim 11: API Consistency severity levels "Breaking / Inconsistent / Minor / Informational"

**Location:** `skills/code-review.md:288-292` (unified severity mapping table, API Consistency column)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The api-consistency-reviewer skill uses "Breaking / Inconsistent / Minor / Informational" at lines 222 and 235-242. The unified severity mapping correctly maps Breaking to red, Inconsistent to amber, and Minor+Informational to green.

**Evidence:** `skills/api-consistency-reviewer.md:222, 235-242`

---

## Claim 12: Code fact-check verdicts "Incorrect (high confidence)" at red, "Incorrect (medium confidence), Stale, Mostly Accurate" at amber, "Unverifiable" at green

**Location:** `skills/code-review.md:288-292` (unified severity mapping table, Fact-Check column)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The code-fact-check skill defines verdicts as "Verified / Mostly accurate / Stale / Incorrect / Unverifiable" (lines 87-97) and confidence levels as "high, medium, low" (lines 99-104). The mapping uses these correctly. The "Verified" verdict maps implicitly to the "Confirmed Good" rubric section.

**Evidence:** `skills/code-fact-check.md:86-104`

---

## Claim 13: "Each has 7-9 domain-specific cognitive moves"

**Location:** `docs/decisions/002-critic-style-code-review.md:26`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

All three core critics have exactly 9 cognitive moves each — security-reviewer (moves 1-9, lines 69-187), performance-reviewer (moves 1-9, lines 69-177), api-consistency-reviewer (moves 1-9, lines 77-205). Saying "7-9" is not wrong (9 is within the range) but the actual count is uniformly 9 across all three. The range implies variation that does not exist.

**Evidence:** `skills/security-reviewer.md` (9 moves), `skills/performance-reviewer.md` (9 moves), `skills/api-consistency-reviewer.md` (9 moves)

---

## Claim 14: "Each declares `code-fact-check` as a soft dependency via `requires:`"

**Location:** `docs/decisions/002-critic-style-code-review.md:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

All three core critics have a `requires:` block with `name: code-fact-check` in their frontmatter. The dependency is described as soft (the critics proceed without it, just with a warning).

**Evidence:** `skills/security-reviewer.md:15-20`, `skills/performance-reviewer.md:15-20`, `skills/api-consistency-reviewer.md:17-23`

---

## Claim 15: "mirroring draft-review's 3-stage pipeline (code-fact-check -> code critics -> synthesis + rubric)"

**Location:** `docs/decisions/002-critic-style-code-review.md:27`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

Both code-review.md and draft-review.md follow a 3-stage pipeline. Draft-review has Stage 1 (fact-check), Stage 2 (critics), Stage 3 (synthesis). Code-review has the same three stages. The main differences are that code-review uses Agent tool (line 32) while draft-review uses Task tool (line 28), and code-review produces a "code review rubric" while draft-review produces a "verification rubric". The structural mirroring claim is accurate.

**Evidence:** `skills/draft-review.md:33-36, 87, 130, 156`, `skills/code-review.md:37-41, 131, 162, 184`

---

## Claim 16: Code review adds "auto-selection of contextual critics based on diff characteristics"

**Location:** `docs/decisions/002-critic-style-code-review.md:28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Code-review.md defines auto-selection logic at lines 95-108 for three contextual critics (test-strategy, dependency-upgrade, tech-debt-triage), each with specific trigger conditions based on diff characteristics.

**Evidence:** `skills/code-review.md:95-108`

---

## Claim 17: Code review adds "a unified severity mapping across all critic types"

**Location:** `docs/decisions/002-critic-style-code-review.md:28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The unified severity mapping table appears at lines 287-292 of code-review.md, mapping Security, Performance, API Consistency, and Fact-Check severity levels to the three rubric tiers.

**Evidence:** `skills/code-review.md:287-292`

---

## Claim 18: Code review adds "cross-critic escalation (findings raised by 2+ critics independently get escalated one tier)"

**Location:** `docs/decisions/002-critic-style-code-review.md:28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The escalation rule is defined at lines 299-307 of code-review.md, specifying that findings flagged by 2+ critics independently escalate one tier (green to amber, amber to red).

**Evidence:** `skills/code-review.md:299-307`

---

## Claim 19: "Code review pipeline (skills/code-review.md): Decomposes into code-fact-check + domain critics..."

**Location:** `patterns/orchestrated-review.md:68`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High

The file `skills/code-review.md` exists and implements exactly this decomposition: code-fact-check in Stage 1, then security-reviewer, performance-reviewer, api-consistency-reviewer as core critics, with optional test-strategy, tech-debt-triage, dependency-upgrade contextual critics.

**Evidence:** `skills/code-review.md:79-90`

---

## Claim 20: "See docs/decisions/002-critic-style-code-review.md"

**Location:** `patterns/orchestrated-review.md:68`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `docs/decisions/002-critic-style-code-review.md` exists and contains the design decision for the critic-style code review system.

**Evidence:** `docs/decisions/002-critic-style-code-review.md` exists

---

## Claim 21: "Codebase onboarding (workflows/codebase-onboarding.md)"

**Location:** `patterns/orchestrated-review.md:66`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `workflows/codebase-onboarding.md` exists.

**Evidence:** Glob result for `workflows/codebase-onboarding.md`

---

## Claim 22: Draft-review uses "Task tool" while code-review uses "Agent tool" for sub-agents

**Location:** `skills/code-review.md:32` ("You MUST use the Agent tool") vs `skills/draft-review.md:28` ("You MUST use the Task tool")
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium

This is not a checkable claim stated explicitly in the reviewed files, but it is an implicit inconsistency between two orchestrators that claim to follow the same pattern. The terminology note in `patterns/orchestrated-review.md:31` says to 'Use "sub-agent" consistently... regardless of whether the underlying implementation uses the Task tool, Agent tool, or manual sequential processing.' The pattern doc acknowledges tool variation, but the two orchestrators that "mirror" each other use different tools (Task vs Agent) without explanation.

**Evidence:** `skills/code-review.md:32`, `skills/draft-review.md:28`, `patterns/orchestrated-review.md:31`

---

## Claim 23: "The CC/YC prose critic pattern (structured cognitive moves producing markdown critique) has proven effective for draft review"

**Location:** `docs/decisions/002-critic-style-code-review.md:5`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Low

The cowen-critique and yglesias-critique skills exist and produce structured markdown critiques. Whether the pattern has "proven effective" is a judgment about past usage outcomes that cannot be verified from the codebase alone.

**Evidence:** `skills/cowen-critique.md`, `skills/yglesias-critique.md` exist

---

## Claims Requiring Attention

### Incorrect

(None)

### Stale

(None)

### Mostly Accurate

- **Claim 13** (`docs/decisions/002-critic-style-code-review.md:26`): Says "7-9 domain-specific cognitive moves" but all three critics have exactly 9. The range implies variation that does not exist.
- **Claim 10** (`skills/code-review.md:288-292`): Performance severity mapping is accurate but uses a different red-tier grouping than security (Critical only vs Critical+High), which is intentional but worth noting for clarity.
- **Claim 22** (`skills/code-review.md:32`): Code-review uses Agent tool, draft-review uses Task tool. The pattern doc accommodates this but the two orchestrators that "mirror" each other differ without explanation in the decision doc.

### Unverifiable

- **Claim 23** (`docs/decisions/002-critic-style-code-review.md:5`): "proven effective" is a judgment about outcomes, not verifiable from the codebase.
