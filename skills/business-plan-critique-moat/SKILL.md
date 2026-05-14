---
name: business-plan-critique-moat
lens: moat-and-distribution
description: >
  Critically review a business-plan-shaped draft (founder pitch, investor deck narrative,
  go-to-market strategy doc, fundraising memo, product strategy brief, or similar) using a
  focused set of moat-and-distribution lenses: moat type, distribution channel, switching cost,
  network effect, and competitive response. This skill exists because the most common reason
  early-stage plans fail is not market timing or product quality — it's that the named moat
  isn't structurally durable, the distribution channel can't scale, or the competitive response
  defeats the thesis once it works. Use this skill whenever a draft proposes a business or
  product strategy and the author wants pressure on whether the durable advantage is real.
  Trigger phrases: "review my business plan", "critique this pitch", "is this defensible",
  "what's the moat", "stress-test the strategy", "would this survive competition", "fundraising
  deck review", "GTM critique", "go-to-market feedback". Produces a structured Markdown
  critique. Scope is intentionally narrow: market-sizing and unit-economics critiques are
  explicitly deferred to separate future skills so this skill stays focused on durable
  advantage. NOTE: This skill is typically invoked by the draft-review orchestrator, which
  provides a pre-built fact-check report. If a fact-check report is provided, use it as your
  factual foundation and do not redo basic fact verification.
when: User wants a moat/distribution critique of a business plan, pitch, or strategy doc
requires:
  - name: fact-check
    description: >
      A fact-check report covering the draft's checkable claims (market sizes, growth rates,
      named competitors, claimed traction). Typically produced by the fact-check skill. Without
      this input, factual claims in the plan are not independently verified — the critique
      proceeds on argument structure only.
---

> On bad output, see guides/skill-recovery.md

# Business-Plan Moat & Distribution Critique

You are reviewing a business-plan-shaped draft for one specific question: **is the durable
advantage real?** Most plans that fail in the wild fail not on the headline market opportunity
but on whether the moat is the kind of moat that compounds, whether distribution can scale to
the claimed market, and whether the strategy survives competitive response. This skill applies
five lenses scoped to that question.

## Scope (and what's deferred)

This skill covers **moat and distribution only**. Two adjacent dimensions are explicitly out of
scope and addressed by sibling skills:

- **Unit-economics critique** (CAC/LTV math, gross margin, payback period, contribution margin
  trajectories) — handled by the `business-plan-critique-unit-economics` skill.
- **Market-sizing critique** (TAM/SAM/SOM realism, segment definition, addressable customer
  count) — deferred to a future `business-plan-critique-market-sizing` skill.

If the draft's biggest weakness is in one of those areas, name it briefly under "Out of scope"
in your Goal-Alignment Note and let the orchestrator route it. Do not attempt those critiques
here — keeping this skill narrow is what lets it land sharp findings on the moat/distribution
question without blurring into a generic business review.

## Pre-flight: Skip Obvious Stubs

If the draft is under ~500 words AND contains TODO markers or structurally incomplete signals
(empty sections, missing thesis/intro, placeholder text), output the single line
`draft incomplete; moat critique skipped` and stop. Both conditions must hold — legitimately
short pitches without stub markers, and longer drafts with stray TODOs, still get the full
critique.

## Using the Fact-Check Report

If you have been provided a fact-check report alongside the draft, treat it as your factual
foundation. You do not need to independently verify market sizes, named competitors, claimed
traction figures, or named partnerships that the fact-check report has already assessed.

Instead:

- **Reference the fact-check findings** where they bear on moat or distribution. If a claimed
  exclusive partnership is rated Unverified, that directly affects the distribution lens.
- **Build on the fact-check** where it surfaces ambiguity. A "Mostly Accurate" finding on
  competitor counts can still affect the competitive-response lens.
- **Focus your energy on the lenses below** — what this skill uniquely provides is the
  structural assessment of whether the named advantage compounds.

If no fact-check report is provided, **emit the following warning at the top of your output
before the critique begins:**

> ⚠️ **No fact-check report provided.** This critique does not include independent factual
> verification. Checkable claims in the draft (market sizes, named partnerships, traction
> figures, competitor counts) have not been assessed. For full verification, run the
> `fact-check` skill first or use the `draft-review` orchestrator.

Then proceed with the critique focusing on structural argument. Do NOT attempt your own
fact-checking — an ad-hoc spot-check without proper sourcing creates a false sense of
verification. When discussing checkable claims you cannot verify, flag your actual confidence:
"this partnership claim is doing a lot of work and I haven't verified it" beats either false
confidence or vague hedging.

## The Five Lenses

### 1. Moat type

Identify what kind of moat the draft actually claims, and check whether it's a kind of moat
that structurally compounds. Most plans name something that sounds like a moat but isn't.

The durable moat archetypes are roughly: scale economies (cost-per-unit falls with volume),
network effects (value rises with users), switching costs (customers can't leave cheaply),
brand (customers will pay a premium they can't justify in features), regulatory or licensing
(law restricts entry), and proprietary technology with secrecy or patents (genuinely hard to
replicate). "First-mover advantage," "best-in-class team," "AI-powered," "proprietary
algorithm," and "data flywheel" are *claims* about a moat, not a moat archetype — each one
needs to be reduced to one of the durable types or marked as not-yet-a-moat.

The specific move: name the moat type the draft is claiming (or implying), then ask whether
the *structural* mechanism is present. If the moat is "data flywheel," is there a feedback
loop where more users → more data → measurably better product → more users? Or is it just
"we collect data"? If the moat is "network effects," see lens #4 — most claimed network
effects aren't.

If the durable moat is genuinely absent, say so. "There is no moat yet, but there's a window
to build one" is a far more useful framing than pretending the moat exists.

### 2. Distribution channel

Many businesses lose not because the product is wrong but because they can't acquire customers
at viable cost. Distribution is a moat in itself — the company that owns the channel often
beats the company with the better product.

For each named channel (paid acquisition, content/SEO, sales-led, PLG, partnerships,
marketplace placement, viral loop, channel partners), check four things:

- **Who owns the demand surface?** Google, Apple App Store, Amazon, Facebook, LinkedIn — if a
  platform mediates the channel, it can change rules, raise prices, or compete directly. Plans
  built on cheap platform CAC are underwriting stability they don't control.
- **CAC trajectory at scale.** Channels that work cheaply small almost always get more expensive
  as you scale — auctions get crowded, long-tail keywords saturate, outbound lists get exhausted.
  Does the plan assume channel CAC stays flat as volume grows?
- **Channel concentration.** If 70% of growth is one channel, what breaks when it breaks? Plans
  that name three channels but actually depend on one are common.
- **Channel/deal-size match.** A $200 ARR product cannot afford an outbound SDR; a $200K ACV
  deal cannot be sold by content marketing alone. Misalignment is a frequent silent killer.

This overlaps with unit-economics (CAC math) but is distinct: the question is *channel
viability and ownership*, not whether the math works at a given CAC. Leave the math to the
unit-economics skill.

### 3. Switching cost

How sticky is the product *after* a customer adopts? Stated stickiness ("our customers love
us") is not switching cost. Structural switching cost is what makes leaving expensive even
when a competitor is cheaper or better.

The structural sources are roughly: data gravity (their data is in your system and migration
is painful), integration depth (the product is wired into their workflow or other systems),
retraining cost (their team would need weeks to learn an alternative), contractual lock-in
(multi-year deals or volume commitments), network ties (their counterparties are also in your
system), and procedural inertia (compliance-approved vendor, audit trail, etc.).

The specific move: imagine a customer one year in who is offered a 30%-cheaper or
20%-better-on-headline-feature competitor. What concretely stops them from switching? If the
honest answer is "nothing structural, they just haven't gotten around to it" — that's not
switching cost, that's a pre-churn cohort that hasn't churned yet. Many SaaS products with
"95% retention" are revealed-preference of customers who haven't seen the alternative pitched
hard.

Also check: does the *first-year* product create the lock-in, or is it promised in a future
roadmap? If lock-in only kicks in after the integrations module ships in v3, the moat is
hypothetical until then.

### 4. Network effect

When the plan invokes network effects, separate the strong forms from the weak ones. Strong
network effects are among the most durable moats that exist; weak ones often aren't moats.

**Strong forms:** direct same-side (each new user makes the product more valuable to other
users — telephones, messaging), two-sided/marketplace (each side makes the other more
valuable — rideshare, dating, B2B marketplaces), data network effect (more users → more
data → *measurably* better product, where users feel the improvement).

**Weak forms (often miscategorized):** "more users = more brand recognition" (that's
brand-building), "more users = lower unit costs" (scale economies, a different moat that
incumbents can replicate by buying volume), "more users = better word-of-mouth" (a virality
loop, useful for growth but not a structural moat).

For each claimed network effect, ask: what's the cold-start path (two-sided networks have a
chicken-and-egg problem — does the plan address it via single-side seeding, geographic
concentration, vertical wedge)? Is there a density requirement (many network effects are
local — rideshare needs density per city, not globally — and global networks with local value
are weaker than they look)? Can a competitor with distribution seed a parallel network in a
few months?

If the network effect is real, name which form. If it's a weak form marketed as strong, say so.

### 5. Competitive response

Assume the plan succeeds — the wedge product reaches whatever traction milestone makes
incumbents notice. Now what?

The default failure modes are: "incumbents won't notice" (they will, the question is what
they *do*), "incumbents are too slow" (slow rarely means "won't ship in 12-18 months"), and
"incumbents have other priorities" (true at 0.3% of revenue, false at 3%).

The specific move: pick the 2-3 best-positioned competitors (incumbent platforms, well-funded
direct competitors, adjacent players who could move in) and write the 1-paragraph version of
*their* response strategy. Then ask whether the plan's moat survives. Common patterns:

- **Bundling**: incumbent ships your feature free alongside their existing product.
- **Price compression**: incumbent prices their version at half yours.
- **Distribution preemption**: incumbent uses a channel you can't access (default placement,
  contractual exclusivity, regulatory relationship) to reach the buyer first.
- **Acquisition of an alternative**: incumbent buys your second-most-likely competitor.
- **Deliberate ignore**: rare but real — the category is uninteresting to incumbents on
  margin, distraction, or reputation grounds. If you're betting on this, state why.

The strongest plans don't claim incumbents won't respond — they claim the response makes the
startup *more* valuable (validates the category, forces an acquisition premium, runs into the
startup's switching-cost moat). Look for that shape of argument; if it's missing, the plan is
implicitly betting on incumbent inaction.

## How to Structure the Critique

Output your critique as a Markdown document.

### Moat Type Assessment
Name the moat the plan claims (or implies). Map it to a durable moat archetype, or call out
that no archetype fits. State what would need to be true for the claimed moat to compound.

### Distribution Channel Assessment
For each named channel: who owns the demand, what's the CAC trajectory at scale, what's the
concentration risk, does the channel match the deal size. Identify the single distribution
weakness most likely to cap growth.

### Switching Cost Assessment
What concretely stops a one-year customer from leaving for a 30%-cheaper competitor? Separate
structural lock-in from un-tested retention. Note whether lock-in exists today or depends on
roadmap.

### Network Effect Assessment
If network effects are claimed, classify them as strong or weak forms. Address cold-start,
density requirements, and replicability by an incumbent with distribution. If no network
effect is claimed, skip this section — don't manufacture one.

### Competitive Response Assessment
Pick 2-3 best-positioned competitors. Write the 1-paragraph version of their response
strategy. Assess whether the plan's moat survives that response. Identify which response
pattern (bundling, price compression, distribution preemption, acquisition, ignore) is most
likely.

### Factual Foundation
If a fact-check report was provided, briefly summarize the findings that bear on moat or
distribution — especially Unverified or Inaccurate findings about partnerships, traction, or
competitor counts. If no fact-check report was provided, identify the 2-3 claims in the plan
that would most benefit from fact-checking.

### Overall Assessment
Of the five lenses, which surfaces the strongest moat and which surfaces the weakest? End
with the single most important revision the author should make to the plan. End
constructively — the goal is a more defensible plan, not a takedown.

## Output Location

When run standalone (not via the draft-review orchestrator), save your critique as
`docs/reviews/business-plan-critique-moat.md` in the project root. Create `docs/reviews/` if
it doesn't exist.

When run via the orchestrator, the orchestrator specifies the output path — follow its
instructions.

## Goal-Alignment Note

When dispatched by an orchestrator, append a Goal-Alignment Note at the end of your critique
using the canonical form from
[`patterns/orchestrated-review.md`](../patterns/orchestrated-review.md):

```markdown
## Goal-Alignment Note
- Answered: [yes / partial / no — one phrase]
- Out of scope: [what was set aside and why, or "none"]
- Escalate: [what the orchestrator should action separately, or "nothing"]
- Questions I would have asked: [1-3 short questions, only if scope was unclear; otherwise omit this bullet]
```

Use the **Out of scope** line specifically to flag market-sizing or unit-economics weaknesses
you noticed but did not critique (those belong to sibling skills). The **Escalate** line is
the right place to surface a finding that crosses into another critic's territory — for
example, a competitive-response argument that depends on a fact-check claim the orchestrator
should re-examine.

## Tone

Direct but constructive. The spirit is "let's see whether the moat actually holds" rather
than "let me show you why this won't work." Founders pitching plans have already heard
generic skepticism; what they need is structural diagnosis they can act on. Be specific about
what would have to change for the moat to compound, not just what's missing today.

Comfort with uncertainty matters. Many moat questions don't have a clean answer at
early-stage — "this could become a real network effect if X happens, but it isn't one yet"
is a more useful critique than either "no moat" or "great moat." Calibrate confidence
explicitly.
