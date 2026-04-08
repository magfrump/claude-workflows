# Plan: What-If Analysis Skill

**Scope:** Create `skills/what-if-analysis.md` — a standalone skill for structured pre-mortem and consequence exploration of proposed changes.

## Approach

Standalone skill (not orchestrator) following the same format as cowen-critique and yglesias-critique. 8 cognitive moves focused on consequence tracing rather than quality evaluation.

## The 8 Cognitive Moves

1. **Name the load-bearing assumptions** — Extract the assumptions the proposal depends on, ranked by how much breaks if they're wrong. Different from Cowen's "contingent assumptions" (move #8) because that identifies what's contingent; this asks "which ones bear the most weight?"

2. **Pre-mortem: it's six months later and this failed** — Klein's pre-mortem technique. Imagine the change shipped and failed. Generate 3-5 specific, concrete failure stories. Not "it might not work" but "the migration corrupted 12% of records because the schema assumed all dates were UTC."

3. **Trace second-order effects** — First-order: the direct consequence of the change. Second-order: what changes because of the first-order effect. Third-order: what changes because of the second-order effect. Most proposals only think through first-order.

4. **Find the hidden coupling** — What else depends on the thing being changed? What depends on the things that depend on it? Systems fail at coupling points that nobody mapped.

5. **Invert the confidence** — For each claim where the proposal is most confident, ask "what if this specific thing is wrong?" The highest-confidence assumptions get the least scrutiny and are often the most dangerous.

6. **Run the adversarial scenario** — If someone actively wanted this change to fail, what would they do? What's the easiest attack vector, the most likely sabotage, the simplest way the environment could be hostile?

7. **Check the reversibility gradient** — How hard is it to undo this change at each stage? A change that's easy to revert in week 1 but impossible in month 6 has a hidden risk profile. Map the reversibility over time.

8. **Ask what success costs** — Even if the change works perfectly, what do you lose? Every change has opportunity costs, maintenance burden, complexity debt. The proposal that succeeds on its own terms may still not be worth it.

## Output Structure

- **Assumptions Map** — Load-bearing assumptions ranked by consequence severity
- **Pre-Mortem Scenarios** — 3-5 specific failure stories
- **Consequence Chain** — Second and third-order effects traced out
- **Coupling Analysis** — Hidden dependencies and interaction points
- **Confidence Inversion** — The highest-confidence assumptions stress-tested
- **Adversarial Scenarios** — How this could be made to fail
- **Reversibility Map** — How hard to undo over time
- **Cost of Success** — What's lost even if it works
- **Findings Summary** — Tagged as [UNEXAMINED ASSUMPTION] or [NOVEL FAILURE MODE] for hypothesis evaluation

## Risks

- Overlap with Cowen move #8 (contingent assumptions) — mitigated by focusing on consequence tracing, not just identification
- Could produce generic worry rather than specific scenarios — mitigated by requiring concrete failure stories with specifics
- May be too focused on software changes — designed to work for proposals, plans, designs, and written arguments too

## Test Specification

Run the skill on the same artifact as a Cowen or Yglesias critique and compare: does it surface at least 1 finding not covered by the critique skills?
