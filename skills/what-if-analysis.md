---
name: what-if-analysis
description: >
  Perform a structured pre-mortem and consequence analysis of a proposed change — a plan, design,
  migration, refactor, policy, or any artifact that proposes doing something different from the status
  quo. This skill systematically explores "what if this assumption is wrong?" and "what would need to
  be true for this to fail?" It traces second-order effects, maps hidden couplings, and stress-tests
  the highest-confidence assumptions. Differentiated from critique skills (cowen-critique,
  yglesias-critique) which evaluate whether an argument is *good* — this skill evaluates what happens
  if the argument is *wrong*, and what the consequences are even if it's right. Use this skill when
  the user asks things like "what could go wrong with this", "stress-test this plan", "what am I not
  seeing", "pre-mortem this", "what are the risks", "what are the second-order effects", "what breaks
  if we're wrong", or "what if this assumption doesn't hold". Also trigger when the user is about to
  make a significant, hard-to-reverse change and wants to understand the consequence space before
  committing. NOTE: This skill can optionally receive upstream reports (fact-check, critique) but
  does not require them. If critique reports are provided, use them to identify which assumptions
  the critics *didn't* examine — that's where this skill adds the most value.
when: User wants to explore consequences, failure modes, and second-order effects of a proposed change
requires:
  - name: cowen-critique or yglesias-critique
    description: >
      An existing critique of the same artifact. Optional. When provided, this skill focuses on
      the assumptions and failure modes that the critique did NOT surface, maximizing the unique
      value of the what-if analysis. Without upstream critiques, the analysis covers the full
      consequence space independently.
---

> On bad output, see guides/skill-recovery.md

# What-If / Counterfactual Analysis

You are performing a structured pre-mortem and consequence analysis of a proposed change. The point
is not to evaluate whether the proposal is *good* — the critique skills do that. The point is to
explore what happens if things go differently than the proposal expects, and what the consequences
are even if everything goes exactly as planned.

This is the difference between a critic and a pre-mortem analyst. The critic asks "is this argument
sound?" The pre-mortem analyst asks "assuming this argument is sound, what could still go wrong?
And assuming it's unsound, what specifically breaks?"

What follows are the cognitive moves for this analysis. Not all will apply to every proposal —
exercise judgment. But resist the temptation to skip moves that feel uncomfortable or unlikely.
The value of this analysis is in the surprises.

## Using Upstream Reports

If you have been provided critique reports (from cowen-critique, yglesias-critique, or others)
alongside the proposal, treat them as a map of *already-examined territory*. Your job is to
explore the territory they didn't cover.

Specifically:
- **Read the critiques for assumptions they surfaced.** Those assumptions have already been
  examined. You don't need to re-examine them unless your analysis reveals a consequence chain
  the critique missed.
- **Focus on the assumptions the critiques took for granted.** Every critique makes its own
  assumptions — about the environment, the timeline, the actors involved. Those meta-assumptions
  are your primary target.
- **Tag your novel findings.** When you surface an assumption or failure mode not mentioned in
  any upstream critique, mark it with `[NOVEL]`. This makes it possible to evaluate whether
  this skill is adding unique value beyond what critique skills provide.

If no upstream reports are provided, **emit the following note at the top of your output:**

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output — this skill is most powerful when focused on the gaps that critics miss.

Then proceed with the full analysis. Tag all findings as `[NOVEL]` since there's no baseline
to compare against.

## The Cognitive Moves

### 1. Name the load-bearing assumptions

Every proposal rests on assumptions — about the environment, the users, the technology, the
timeline, the team's capabilities. Most proposals don't state these explicitly. Your first job
is to extract them.

But don't just list assumptions. *Rank them by load.* A load-bearing assumption is one where,
if it's wrong, the entire proposal collapses or changes fundamentally. A cosmetic assumption is
one where, if it's wrong, the proposal needs minor adjustment.

The specific move: read the proposal and write down every "this assumes that..." you can find —
both the explicit ones and the ones the author takes for granted. Then for each one, ask: "if
this is wrong, does the proposal need a tweak, a redesign, or a full retreat?" The ones that
require a redesign or retreat are load-bearing. Focus the rest of your analysis on those.

### 2. Pre-mortem: it's six months later and this failed

This is Gary Klein's pre-mortem technique, applied with specificity. Don't just say "it might
fail." Instead: *assume it has already failed*. It's six months after the change shipped.
Something went wrong. What happened?

Generate 3-5 specific, concrete failure stories. Each one should be a plausible narrative with
specific details — not "the migration might have issues" but "the migration completed
successfully on staging, but in production the 2.3M legacy records from the 2019 acquisition
had null values in the `region` field, which the migration script treated as empty strings,
causing the new geolocation service to route all 2.3M users to the default region."

The power of the pre-mortem is that it shifts your psychology from "how do we make this work?"
(advocate mode) to "what went wrong?" (detective mode). In detective mode, you notice things
that advocacy makes invisible.

Each failure story should trace from a specific root cause through specific consequences to a
specific observable outcome. Vague failure stories ("it was harder than expected") are not useful.

### 3. Trace second-order effects

First-order effects are the direct, intended consequences of the change. The proposal already
describes these. Your job is to go further.

Second-order: What changes *because of* the first-order effect? If you add a cache layer
(first-order: faster reads), what changes because reads are now faster? Maybe the UI team
builds features that assume fast reads, creating a hidden dependency on the cache. Maybe users
start making more requests because the interface feels snappier, increasing write load.

Third-order: What changes because of the second-order effect? The increased write load from
snappier UX causes write latency to spike, which causes the retry logic to trigger, which
causes a thundering herd, which causes an outage during peak hours.

The specific move: take each intended outcome of the proposal and ask "and then what?" twice.
Write out the chain. Many proposals are correct about their first-order effects but blind to
the second and third-order consequences. The chains that lead somewhere bad are findings.

### 4. Find the hidden coupling

The proposal changes thing A. But thing B depends on thing A, and thing C depends on thing B.
The proposal may not know about thing C. Systems fail at coupling points that nobody mapped.

This is not just "check the dependencies." The move is to look for *invisible* couplings —
the ones that don't appear in dependency graphs because they're implicit. Shared conventions
("every service assumes timestamps are in UTC"), shared resources (two systems that both assume
they have exclusive access to the same queue), behavioral contracts (downstream consumers that
depend on the *current behavior* of an API, not its documented contract), and temporal couplings
(things that must happen in a specific order but nothing enforces that order).

For proposals about systems: draw the coupling map one level deeper than the proposal does.
For proposals about processes or organizations: identify the informal agreements, handshakes,
and conventions that the proposal disrupts.

### 5. Invert the confidence

Find the claims in the proposal where the author is most confident — the parts stated as
obvious, the assumptions that aren't even stated because they're taken as given, the steps
described as straightforward.

Now invert them. What if the "obvious" thing is wrong? What if the "straightforward" step is
actually the hardest part? What if the thing everyone knows is true... isn't?

The specific move: for each high-confidence claim, construct a concrete scenario where it's
false, and trace the consequences. "Everyone knows our users prefer the web interface" — what
if 40% of actual usage has quietly shifted to the mobile app and the analytics aren't tracking
it? What does that do to the proposal?

High-confidence assumptions are the most dangerous because they get the least scrutiny. If
a low-confidence assumption is wrong, the team probably has a contingency. If a high-confidence
assumption is wrong, there's no plan B.

### 6. Run the adversarial scenario

This is not about malicious actors (though it can include them). It's about asking: if the
environment were actively hostile to this proposal, what would that look like?

- What if the data is worse than expected?
- What if the timeline is half what you think?
- What if the key person leaves mid-project?
- What if a competitor ships something similar next month?
- What if the regulatory environment changes?
- What if load is 10x what you projected?

The specific move: pick the 2-3 environmental factors that matter most to the proposal and
ask "what's the realistic worst case for each?" Not the apocalyptic worst case — the one that's
maybe 10-20% likely. That's the scenario worth planning for.

### 7. Check the reversibility gradient

Some changes are easy to undo on day 1 but impossible to undo on day 180. The proposal may
not describe this gradient.

The specific move: imagine you need to fully reverse this change at each of these timepoints:
- 1 week after implementation
- 1 month after implementation
- 6 months after implementation

What does reversal require at each stage? What data has been created that depends on the new
state? What downstream systems have adapted? What user expectations have shifted? What
contracts or commitments have been made based on the change?

A change with a steep reversibility gradient — easy to undo today, catastrophic to undo
later — needs more scrutiny upfront than a change that's equally reversible at any point.
Flag any cliff edges in the reversibility gradient: specific moments where reversal suddenly
becomes much harder.

### 8. Ask what success costs

Even if the proposal works perfectly — every assumption holds, every step succeeds, every
outcome is as intended — what do you lose?

Every change has costs beyond its direct resource expenditure:
- **Complexity cost:** The system is now harder to understand, debug, or modify.
- **Opportunity cost:** The team is now committed to this direction and not others.
- **Maintenance cost:** Something new must now be kept alive, monitored, documented.
- **Optionality cost:** Future choices are now constrained by this change.

The specific move: write a paragraph describing the world after the proposal succeeds
completely. Then ask: "what's worse about this world compared to today, even though the
proposal achieved its goals?" The answer reveals the true cost of success.

## How to Structure the Output

Output your analysis as a Markdown document.

### Assumptions Map

List every load-bearing assumption (move #1). For each one, state:
- The assumption itself
- Whether it's explicit in the proposal or implicit
- What happens if it's wrong (tweak / redesign / full retreat)
- Tag: `[NOVEL]` if not surfaced by any upstream critique

### Pre-Mortem Scenarios

Present 3-5 concrete failure stories (move #2). Each should have:
- A specific root cause
- A specific chain of consequences
- A specific observable outcome
- A plausibility assessment (likely / plausible / unlikely-but-catastrophic)

### Consequence Chains

Trace first → second → third-order effects (move #3) for the proposal's 2-3 most significant
intended outcomes. Use an indented chain format:

```
→ First-order: [intended outcome]
  → Second-order: [what changes because of this]
    → Third-order: [what changes because of that]
    → Third-order: [alternative chain]
```

### Coupling Analysis

Map the hidden couplings (move #4) — the dependencies the proposal doesn't acknowledge.
For each coupling, note whether it's visible (in a dependency graph or config) or invisible
(convention, behavior, timing).

### Confidence Inversions

For each high-confidence assumption inverted (move #5), describe the concrete scenario where
it's wrong and what that does to the proposal.

### Adversarial Scenarios

The 2-3 most important hostile-environment scenarios (move #6), with the realistic worst case
for each.

### Reversibility Map

A timeline showing how hard reversal is at 1 week, 1 month, and 6 months (move #7). Flag
any cliff edges.

### Cost of Success

What's lost even if everything works (move #8). Complexity, opportunity, maintenance, and
optionality costs.

### Findings Summary

A consolidated list of all findings, each tagged:
- `[UNEXAMINED ASSUMPTION]` — a load-bearing assumption that the proposal (and any upstream
  critiques) did not examine
- `[NOVEL FAILURE MODE]` — a specific way the proposal could fail that was not identified
  by any upstream analysis
- `[SECOND-ORDER EFFECT]` — a consequence chain that the proposal didn't trace
- `[HIDDEN COUPLING]` — a dependency the proposal didn't map
- `[REVERSIBILITY CLIFF]` — a point where reversal suddenly becomes much harder
- `[SUCCESS COST]` — something lost even if the proposal works perfectly

This tagging enables direct comparison with upstream critique outputs to evaluate whether
the what-if analysis surfaced genuinely new findings.

## Output Location

Save your analysis as `docs/reviews/what-if-analysis.md` in the project root. Create
`docs/reviews/` if it doesn't exist.

If run alongside critique skills on the same artifact, all outputs coexist in `docs/reviews/`.

## Tone

Constructive paranoia. The spirit is "let's find out what we haven't thought about" rather
than "let me tell you why this will fail." You're not arguing against the proposal — you're
mapping the territory around it that the proposal didn't explore.

Be specific, not vague. "This might have issues" is not a finding. "If the `user_preferences`
table has more than 50M rows, the ALTER TABLE will lock writes for 4+ minutes during peak
hours" is a finding.

Calibrate severity honestly. Not everything is catastrophic. Some failure modes are minor
inconveniences. Say which is which. The reader needs to know where to focus their attention.

When a move doesn't produce interesting findings for a particular proposal, say so briefly
and move on. An honest "the reversibility gradient is flat — this is equally easy to undo at
any point" is more useful than manufacturing concern.
