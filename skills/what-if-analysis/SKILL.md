---
name: what-if-analysis
description: >
  Perform a structured prospective consequence analysis of a proposed change — a plan, design,
  migration, refactor, policy, or any artifact that proposes doing something different from the
  status quo. This skill systematically explores "what if this assumption is wrong?" and "what
  would need to be true for this to fail?" It traces second-order effects, maps hidden couplings,
  and stress-tests the highest-confidence assumptions. Differentiated from critique skills
  (cowen-critique, yglesias-critique) which evaluate whether an argument is *good* — this skill
  evaluates what happens if the argument is *wrong*, and what the consequences are even if it's
  right. Use this skill when the user asks things like "what could go wrong with this",
  "stress-test this plan", "what am I not seeing", "what are the risks", "what are the
  second-order effects", "what breaks if we're wrong", "what assumptions is this making", or
  "what if this assumption doesn't hold". Also trigger when the user is about to make a
  significant, hard-to-reverse change and wants to understand the consequence space before
  committing, or when invoked as a sub-procedure of `divergent-design` to stress-test top
  candidates before a decision is finalized. Distinct from `pre-mortem`: that skill operates
  retrospectively (assume failure has already happened → write the narrative of why), while
  this skill operates prospectively (the plan is on the table → map the consequence space
  around it). Trigger phrases that name a failure as *already having happened* — "pre-mortem
  this", "imagine 6 months later and this failed", "write the failure story", "tell me why
  this failed" — route to `pre-mortem`, not here. The two skills compose: run what-if first
  to map the territory, then pre-mortem to walk the specific failure paths through it. NOTE:
  This skill can optionally receive upstream reports (fact-check, critique) but does not
  require them. If critique reports are provided, use them to identify which assumptions the
  critics *didn't* examine — that's where this skill adds the most value.
when: User wants to explore consequences, failure modes, and second-order effects of a proposed change — prospectively, from the plan forward
requires:
  - name: cowen-critique
    description: >
      An existing cowen-style critique of the same artifact. Optional. When provided, this skill
      focuses on the assumptions and failure modes that the critique did NOT surface, maximizing
      the unique value of the what-if analysis.
  - name: yglesias-critique
    description: >
      An existing yglesias-style critique of the same artifact. Optional. When provided, this skill
      focuses on the assumptions and failure modes that the critique did NOT surface. Without any
      upstream critiques, the analysis covers the full consequence space independently.
---

> On bad output, see guides/skill-recovery.md

# What-If / Counterfactual Analysis

Perform structured prospective consequence analysis of a proposed change. Point is not to evaluate whether the proposal is *good* — critique skills do that. Explore what happens if things go differently than expected, and what the consequences are even if everything goes as planned.

Critic asks "is this argument sound?" Consequence analyst asks "assuming this argument is sound, what could still go wrong? And assuming it's unsound, what specifically breaks?"

What follows are the cognitive moves. Not all apply to every proposal — exercise judgment. But resist skipping moves that feel uncomfortable or unlikely. The value is in the surprises.

## When to Use This Skill (vs. pre-mortem)

This skill is forward-chained, structural: *"this is the plan — what could go wrong?"* Sibling skill `pre-mortem` is backward-chained, narrative: *"the project failed — what's the story?"*

Mechanical test at trigger time:

| User's framing | Skill |
|----------------|-------|
| "what could go wrong with this", "stress-test this plan", "what are the risks", "trace the second-order effects", "what assumptions is this making", "what's the reversibility gradient", "what's the blast radius" | **what-if-analysis** |
| "pre-mortem the launch", "pre-mortem this", "imagine 6 months later and this failed — what happened?", "write the failure story", "tell me why this failed", "give me the post-mortem before we ship" | **pre-mortem** |

Split is not which skill is "better" — it's which cognitive move the user wants. What-if invokes the structural analyst: the plan is on the table, map the consequence space around it (load-bearing assumptions, second-order effects, hidden couplings, reversibility gradient, cost of success). Pre-mortem invokes the detective: failure has already happened, write the report as narrative. Asking for the wrong one wastes the asymmetry that makes each move work.

The two compose. For high-stakes changes, run this skill first to surface load-bearing assumptions and consequence chains, then run `pre-mortem` to turn the most worrying parts into concrete failure narratives. What-if maps the territory; pre-mortem walks the specific paths through it that end in failure.

## Using Upstream Reports

If provided critique reports (cowen-critique, yglesias-critique, or others) alongside the proposal, treat them as a map of *already-examined territory*. Explore the territory they didn't cover.

Specifically:
- **Read the critiques for assumptions they surfaced.** Those are already examined. Don't re-examine unless your analysis reveals a consequence chain the critique missed.
- **Focus on assumptions the critiques took for granted.** Every critique makes its own meta-assumptions — environment, timeline, actors. Those are your primary target.
- **Tag your novel findings.** When you surface an assumption or failure mode not in any upstream critique, mark it `[NOVEL]`. This lets evaluation judge whether this skill adds unique value.

If no upstream reports are provided, **emit the following note at the top of your output:**

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output — this skill is most powerful when focused on the gaps that critics miss.

Then proceed with the full analysis. Tag all findings as `[NOVEL]` since there's no baseline to compare against.

## Prior Art Check

Before generating new what-if scenarios, search the project's prior decisions and working artifacts for the same scenarios. The team may have already considered some failure modes — surfacing prior consideration lets you focus on novel ground and connect new analyses to the existing reasoning trail.

The move:

1. **Extract scenario keywords** from the proposal — systems, components, failure modes, risk vocabulary (e.g., "migration", "cache invalidation", "rate limiting", `user_preferences`, plus domain terms). Aim for 5–10 keywords spanning what the proposal *changes* and what could *fail* around it.
2. **Grep `docs/decisions/` and `docs/working/`** for each keyword. Use case-insensitive matching, cast a wide net, include synonyms and adjacent concepts. Example:
   `grep -ril -e "migration" -e "backfill" -e "user_preferences" docs/decisions/ docs/working/`.
3. **Read matches** to identify what was previously considered, concluded, and whether circumstances changed. Skim the surrounding section, not just the matched line.
4. **Carry forward what you find** into the cognitive moves below. When a scenario you would surface was already analyzed, tag it `[PRIOR CONSIDERATION]` and cite the file (and section/heading). Do *not* drop the finding — surfacing the link is the value.

Findings already considered are context, not failures. Note them so the reader knows the team has been here before; focus novel work on the gaps. If prior consideration reached a different conclusion than what you'd surface today, that's a finding: circumstances may have changed, and the divergence is worth flagging.

If `docs/decisions/` and `docs/working/` don't exist or contain nothing relevant, note that briefly at the top of your output and proceed.

## The Cognitive Moves

### 1. Name the load-bearing assumptions

Every proposal rests on assumptions — environment, users, technology, timeline, team capabilities. Most proposals don't state these. Extract them.

Don't just list assumptions. *Rank them by load.* A load-bearing assumption is one where, if wrong, the entire proposal collapses or changes fundamentally. A cosmetic assumption needs only minor adjustment if wrong.

The move: read the proposal, write down every "this assumes that..." — explicit and taken-for-granted. For each, ask: "if wrong, does the proposal need a tweak, a redesign, or a full retreat?" Redesign or retreat = load-bearing. Focus the rest of your analysis on those.

### 2. Trace second-order effects

First-order effects are the direct, intended consequences. The proposal already describes these. Go further.

Second-order: What changes *because of* the first-order effect? Add a cache layer (first-order: faster reads) — what changes because reads are faster? UI team builds features assuming fast reads, creating hidden dependency on the cache. Users make more requests because the interface feels snappier, increasing write load.

Third-order: What changes because of the second-order effect? Increased write load spikes write latency, triggers retry logic, causes a thundering herd, causes an outage during peak hours.

The move: take each intended outcome and ask "and then what?" twice. Write out the chain. Many proposals are correct about first-order effects but blind to second and third-order. Chains that lead somewhere bad are findings.

### 3. Find the hidden coupling

The proposal changes thing A. Thing B depends on A, thing C depends on B. The proposal may not know about C. Systems fail at coupling points nobody mapped.

Not just "check the dependencies." Look for *invisible* couplings — ones absent from dependency graphs because they're implicit: shared conventions ("every service assumes timestamps are in UTC"), shared resources (two systems both assuming exclusive access to the same queue), behavioral contracts (consumers depending on *current behavior* of an API, not its documented contract), temporal couplings (things that must happen in order but nothing enforces it).

For systems: draw the coupling map one level deeper than the proposal does. For processes or organizations: identify the informal agreements, handshakes, and conventions the proposal disrupts.

### 4. Invert the confidence

Find the claims where the author is most confident — stated as obvious, unstated because taken as given, described as straightforward.

Invert them. What if the "obvious" thing is wrong? What if the "straightforward" step is the hardest part? What if the thing everyone knows... isn't?

The move: for each high-confidence claim, construct a concrete scenario where it's false, trace the consequences. "Everyone knows our users prefer the web interface" — what if 40% of actual usage quietly shifted to the mobile app and analytics aren't tracking it? What does that do to the proposal?

High-confidence assumptions are most dangerous because they get least scrutiny. If a low-confidence assumption is wrong, the team probably has a contingency. If a high-confidence assumption is wrong, there's no plan B.

### 5. Run the adversarial scenario

Not about malicious actors (though it can include them). Ask: if the environment were actively hostile to this proposal, what would that look like?

- What if the data is worse than expected?
- What if the timeline is half what you think?
- What if the key person leaves mid-project?
- What if a competitor ships something similar next month?
- What if the regulatory environment changes?
- What if load is 10x what you projected?

The move: pick the 2-3 environmental factors that matter most, ask "what's the realistic worst case for each?" Not the apocalyptic worst case — the one that's maybe 10-20% likely. That's the scenario worth planning for.

### 6. Check the reversibility gradient

Some changes are easy to undo on day 1 but impossible on day 180. The proposal may not describe this gradient.

The move: imagine fully reversing this change at each timepoint:
- 1 week after implementation
- 1 month after implementation
- 6 months after implementation

What does reversal require at each stage? What data has been created that depends on the new state? What downstream systems have adapted? What user expectations have shifted? What contracts or commitments have been made?

A change with a steep reversibility gradient — easy to undo today, catastrophic later — needs more upfront scrutiny than one equally reversible at any point. Flag any cliff edges: specific moments where reversal suddenly becomes much harder.

### 7. Ask what success costs

Even if the proposal works perfectly — every assumption holds, every step succeeds, every outcome as intended — what do you lose?

Every change has costs beyond direct resource expenditure:
- **Complexity cost:** The system is now harder to understand, debug, or modify.
- **Opportunity cost:** The team is now committed to this direction and not others.
- **Maintenance cost:** Something new must be kept alive, monitored, documented.
- **Optionality cost:** Future choices are now constrained by this change.

The move: write a paragraph describing the world after the proposal succeeds completely. Then ask: "what's worse about this world compared to today, even though the proposal achieved its goals?" The answer reveals the true cost of success.

## How to Structure the Output

Output as a Markdown document. Begin with a level-1 title and a header block, then the cognitive-move sections below. Sections for moves that produced no interesting findings may be marked "no findings" but must not be omitted — the reader needs to know the move was run.

### Header

Begin the document with:

```
# What-If Analysis: <short proposal label>

**Proposal:** <what is being analyzed — file path, decision name, or one-line summary>
**Date:** <YYYY-MM-DD>
**Upstream critiques:** <list of skills whose reports were used, or "none">
```

### Assumptions Examined

List every load-bearing assumption (move #1). For each, use these fields:
- **Assumption:** the claim itself
- **Source:** explicit (cite location) or implicit
- **If wrong:** tweak / redesign / full retreat
- **Tag:** `[NOVEL]` if not surfaced by any upstream critique, otherwise omit

### Consequence Chains

Trace first → second → third-order effects (move #2) for the proposal's 2-3 most significant intended outcomes. Use an indented chain format:

```
→ First-order: [intended outcome]
  → Second-order: [what changes because of this]
    → Third-order: [what changes because of that]
    → Third-order: [alternative chain]
```

### Coupling Analysis

Map the hidden couplings (move #3) — the dependencies the proposal doesn't acknowledge. For each, note whether it's visible (dependency graph or config) or invisible (convention, behavior, timing).

### Confidence Inversions

For each high-confidence assumption inverted (move #4), describe the concrete scenario where it's wrong and what that does to the proposal.

### Adversarial Scenarios

The 2-3 most important hostile-environment scenarios (move #5), with the realistic worst case for each.

### Reversibility Map

A timeline showing how hard reversal is at 1 week, 1 month, and 6 months (move #6). Flag any cliff edges.

### Cost of Success

What's lost even if everything works (move #7). Complexity, opportunity, maintenance, and optionality costs.

### Findings Summary

A consolidated list of all findings, each tagged:
- `[UNEXAMINED ASSUMPTION]` — a load-bearing assumption the proposal (and any upstream critiques) did not examine
- `[SECOND-ORDER EFFECT]` — a consequence chain the proposal didn't trace
- `[HIDDEN COUPLING]` — a dependency the proposal didn't map
- `[REVERSIBILITY CLIFF]` — a point where reversal suddenly becomes much harder
- `[SUCCESS COST]` — something lost even if the proposal works perfectly
- `[PRIOR CONSIDERATION]` — a finding from the Prior Art Check; cite the source file (e.g., `docs/decisions/007-two-phase-pr-prep.md`) and note whether the prior conclusion still applies or circumstances changed

This tagging enables direct comparison with upstream critique outputs to evaluate whether the what-if analysis surfaced genuinely new findings. The `[PRIOR CONSIDERATION]` tag can combine with others (e.g., `[HIDDEN COUPLING] [PRIOR CONSIDERATION]`) when a prior artifact already named the coupling but the present proposal didn't carry it forward.

If the proposal also needs concrete failure narratives (a story of *why* it failed, not just a map of *what could fail*), run the `pre-mortem` skill on the same artifact — it consumes this analysis as input and produces the narrative complement.

### Recommendations

Close with a Recommendations section translating findings into action. Group them as:
- **Must address before proceeding:** findings whose probability × severity makes shipping without mitigation reckless. State the specific mitigation expected.
- **Worth mitigating:** findings worth a tracking item but not a blocker. Suggest a watch signal or contingency.
- **Acknowledged risks:** findings the team can knowingly carry, with a rationale for why the risk is acceptable.

If no findings rise to "must address" severity, say so explicitly — a flat Recommendations section is more useful than an inflated one.

## Output Location

Save your analysis as `docs/reviews/what-if-analysis.md` in the project root. Create `docs/reviews/` if it doesn't exist.

If run alongside critique skills or `pre-mortem` on the same artifact, all outputs coexist in `docs/reviews/`.

## Tone

Constructive paranoia. The spirit is "let's find out what we haven't thought about" rather than "let me tell you why this will fail." You're not arguing against the proposal — you're mapping the territory around it that the proposal didn't explore.

Be specific, not vague. "This might have issues" is not a finding. "If the `user_preferences` table has more than 50M rows, the ALTER TABLE will lock writes for 4+ minutes during peak hours" is a finding.

Calibrate severity honestly. Not everything is catastrophic. Some failure modes are minor inconveniences. Say which is which. The reader needs to know where to focus.

When a move doesn't produce interesting findings, say so briefly and move on. An honest "the reversibility gradient is flat — this is equally easy to undo at any point" is more useful than manufacturing concern.
