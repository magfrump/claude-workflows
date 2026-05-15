---
name: business-plan-critique-unit-economics
lens: unit-economics
description: >
  Critically review a business-plan-shaped draft (founder pitch, investor deck narrative,
  go-to-market strategy doc, fundraising memo, product strategy brief, financial model, or
  similar) using a focused set of unit-economics lenses: CAC, LTV, contribution margin, payback
  period, and gross-margin trajectory. This skill exists because many early-stage plans look
  defensible on the moat and market story but quietly fail on the math — the per-customer
  economics either never work or only work at a scale the business can't reach. Use this skill
  whenever a draft proposes a business or product strategy and the author wants pressure on
  whether the unit economics actually compound. Also trigger when the draft quotes CAC, LTV,
  LTV/CAC ratio, churn, retention, gross margin, contribution margin, payback period, NRR/GRR,
  or any per-customer profitability figure the author wants pressure-tested. Trigger phrases:
  "do the unit economics work", "review my CAC/LTV", "critique the financial model",
  "is this fundable on the numbers", "stress-test the margins", "payback period feedback",
  "contribution margin critique", "unit economics review", "is the LTV real",
  "are these margins defensible", "check the per-customer math", "review the CAC assumptions",
  "what's wrong with my unit economics". Produces a structured Markdown critique with a known
  section layout (CAC, LTV, Contribution Margin, Payback Period, Gross-Margin Trajectory,
  Factual Foundation, Overall Assessment). Scope is intentionally narrow: moat/distribution
  and market-sizing critiques are explicitly deferred to sibling skills
  (`business-plan-critique-moat` and the future `business-plan-critique-market-sizing`) so this
  skill stays focused on the per-customer math. NOTE: This skill is typically invoked by the
  draft-review orchestrator, which provides a pre-built fact-check report. If a fact-check
  report is provided, use it as your factual foundation and do not redo basic fact verification.
when: User wants a unit-economics critique of a business plan, pitch, or strategy doc
requires:
  - name: fact-check
    description: >
      A fact-check report covering the draft's checkable claims (quoted CAC figures, churn
      rates, gross-margin benchmarks, pricing claims, comp-set unit economics). Typically
      produced by the fact-check skill. Without this input, numerical claims in the plan are
      not independently verified — the critique proceeds on argument structure and internal
      consistency only.
---

> On bad output, see guides/skill-recovery.md

# Business-Plan Unit-Economics Critique

You are reviewing a business-plan-shaped draft for one specific question: **do the per-customer
economics compound, and at what scale?** Many plans that survive moat and market scrutiny still
fail on the unit math — CAC that rises faster than the plan assumes, LTV propped up by an
optimistic churn rate, contribution margins eaten by costs the plan treats as fixed but aren't,
payback periods that consume more working capital than the company can raise, or gross-margin
trajectories that never reach the steady state the model depends on. This skill applies five
lenses scoped to that question.

## Scope (and what's deferred)

This skill covers **unit economics only**. Two adjacent dimensions are explicitly out of scope
and addressed by sibling skills:

- **Moat-and-distribution critique** (moat type, distribution channel, switching cost, network
  effect, competitive response) — handled by the `business-plan-critique-moat` skill.
- **Market-sizing critique** (TAM/SAM/SOM realism, segment definition, addressable customer
  count) — deferred to a future `business-plan-critique-market-sizing` skill.

If the draft's biggest weakness is in one of those areas, name it briefly under "Out of scope"
in your Goal-Alignment Note and let the orchestrator route it. Do not attempt those critiques
here — keeping this skill narrow is what lets it land sharp findings on the unit-economics
question without blurring into a generic business review.

## Pre-flight: Skip Obvious Stubs

If the draft is under ~500 words AND contains TODO markers or structurally incomplete signals
(empty sections, missing thesis/intro, placeholder text), output the single line
`draft incomplete; unit-economics critique skipped` and stop. Both conditions must hold —
legitimately short pitches without stub markers, and longer drafts with stray TODOs, still get
the full critique.

## Using the Fact-Check Report

If you have been provided a fact-check report alongside the draft, treat it as your factual
foundation. You do not need to independently verify quoted CAC figures, churn benchmarks,
gross-margin comps, pricing claims, or competitor unit economics that the fact-check report has
already assessed.

Instead:

- **Reference the fact-check findings** where they bear on the math. If a quoted industry
  churn benchmark is rated Inaccurate, that directly affects the LTV lens.
- **Build on the fact-check** where it surfaces ambiguity. A "Mostly Accurate" finding on a
  comp's contribution margin can still affect the gross-margin trajectory lens.
- **Focus your energy on the lenses below** — what this skill uniquely provides is the
  structural assessment of whether the per-customer math compounds.

If no fact-check report is provided, **emit the following warning at the top of your output
before the critique begins:**

> ⚠️ **No fact-check report provided.** This critique does not include independent factual
> verification. Checkable numerical claims in the draft (quoted CAC, churn rates, gross-margin
> benchmarks, pricing comps) have not been assessed. For full verification, run the
> `fact-check` skill first or use the `draft-review` orchestrator.

Then proceed with the critique focusing on internal consistency and structural argument. Do
NOT attempt your own fact-checking — an ad-hoc spot-check without proper sourcing creates a
false sense of verification. When discussing numerical claims you cannot verify, flag your
actual confidence: "this 4% monthly churn figure is doing a lot of work and I haven't verified
it against the SaaS comp set" beats either false confidence or vague hedging.

## The Five Lenses

### 1. CAC (Customer Acquisition Cost)

CAC is rarely a single number — it's a function of channel, segment, and scale. The most
common failure mode is reporting a blended CAC that conceals a healthy seed-channel CAC mixed
with an unhealthy paid-channel CAC, then assuming the blended figure will hold as the
seed-channel runs out.

The specific moves:

- **Decompose by channel.** What does CAC look like per channel (organic, paid, sales-led,
  partnership, referral)? Plans that report only blended CAC are hiding the marginal cost of
  the *next* customer, which is what actually matters for scaling.
- **CAC at scale, not CAC today.** Early CAC is almost always the cheapest CAC the business
  will ever see. Auctions get more competitive, low-hanging keywords saturate, easy referral
  loops decay, the founder stops personally closing every deal. Does the plan model CAC
  expansion as channels scale, or does it project today's number flat?
- **Fully-loaded vs. ad-spend-only.** "CAC of $200" can mean ad spend per customer (excluding
  sales salaries, content production, free-trial costs, onboarding effort), or it can include
  those costs. The plan should be explicit; if it isn't, assume the figure is understated.
- **Payback timing relative to CAC.** A $5K CAC is fine for a $50K ACV product and ruinous for
  a $50/month one — but this lens is about whether the CAC *is what the plan says it is*. The
  CAC-to-payback-relationship is lens #4.

If the plan reports a CAC that depends on a channel that won't scale (founder network, a single
viral moment, a one-off enterprise reference), flag that the *sustainable* CAC is materially
higher than the reported one.

### 2. LTV (Lifetime Value)

LTV is the most aggressively engineered number in early-stage plans, because it depends on
three assumptions stacked on top of each other (retention, expansion, gross margin) and small
changes in each produce large changes in LTV. Most reported LTVs are upper bounds, not
expected values.

Pressure-test the inputs:

- **Churn rate basis.** Is the quoted churn monthly, annual, gross, or net? Is it customer
  churn or revenue churn? A 5% monthly customer churn implies a 46% annual gross retention,
  which is a 2-year average lifetime — not the 10-year lifetime the model may be assuming.
- **Cohort age.** Has the cohort been alive long enough to observe its actual churn curve?
  Many "low churn" claims come from cohorts under 12 months old, where the post-honeymoon
  churn step hasn't happened yet. Annualizing a 6-month figure is doing a lot of work.
- **Expansion assumptions.** Net-revenue retention >100% (NRR via upsell, seat expansion, usage
  growth) is real but earned. If the plan's LTV bakes in 120% NRR before there's a track
  record, ask what *structural* mechanism drives expansion — usage that scales with the
  customer's growth, seat addition tied to user adoption, etc. "We'll upsell them" is a hope,
  not a structure.
- **Gross-margin input.** LTV is *gross-margin-weighted* lifetime revenue, not revenue. Plans
  that compute LTV on top-line revenue overstate it by 1/GM. If the plan reports an LTV/CAC
  ratio, confirm the LTV is margin-weighted (lens #3 feeds this).

If LTV is stated as a single number, ask for the implied retention and expansion. If the
implied numbers exceed the comp set's *best* performers, that's the headline finding —
the plan is implicitly claiming top-decile retention without saying so.

### 3. Contribution margin

Contribution margin per customer (revenue minus variable cost per customer, before fixed
overhead) is what the business actually gets to keep from each unit of growth. Many plans
conflate gross margin (revenue minus COGS) with contribution margin (revenue minus *all*
costs that scale with customer count), and the latter is what matters for whether scaling
helps or hurts.

Check what the plan is treating as "fixed" that is actually variable per customer:

- **Customer support / success cost per account.** For complex products, support and CS scale
  roughly with customer count. A "fixed cost" support model collapses once the customer count
  triples. If the plan models support as overhead, ask the per-account cost at scale.
- **Onboarding and implementation.** One-time per customer but real — especially for B2B
  products with multi-week implementations. If the plan capitalizes implementation cost
  without amortizing it into contribution margin, the per-customer profitability is overstated.
- **Variable infrastructure.** Cloud costs, per-seat third-party licenses (analytics, comms,
  payment processing), usage-based API costs. Plans that quote 80% gross margin from a SaaS
  comp set sometimes have 60% real gross margin once usage-based costs are included.
- **Payment processing and revenue-share.** 2.9% to a payment processor, 30% to an app store,
  20% to a channel partner — these are direct revenue deductions that show up in contribution
  margin but rarely in headline pricing.

The most actionable finding here is usually: "contribution margin at scale is X% lower than
the stated gross margin, which changes the unit-economics conclusion to Y." Make that
calculation explicit when the inputs are available.

### 4. Payback period

Payback period (months to recover CAC from gross-margin-weighted revenue) is the working-
capital question: how much cash does the business consume per customer before that customer
becomes net positive, and can the business afford to fund that gap at the planned growth rate?

The structural moves:

- **CAC payback math.** Payback ≈ CAC / (monthly revenue × contribution margin). A 24-month
  payback on a $50K CAC means the business funds $50K per customer for two years before
  recovery. At 10 new customers per month, that's $1M of working-capital tied up in
  unrecovered CAC at any given time — and that's before growth.
- **Growth-rate × payback interaction.** Faster growth means more new customers in unrecovered
  CAC simultaneously. A 12-month payback at 100% YoY growth is dramatically more capital-
  intensive than a 12-month payback at flat growth. Does the plan size the funding ask
  against this interaction, or against a static-state model?
- **Industry benchmarks.** SaaS rule of thumb is 12-month payback for healthy, 18-24 for
  acceptable, >24 for problematic absent unusually low churn. Consumer subscription is
  typically faster (<6 months). Marketplaces vary widely with take rate. The plan's payback
  should be situated against the relevant comp set, not against an absolute target.
- **What payback ignores.** Payback doesn't capture lifetime profitability — a 6-month payback
  with 7-month average lifetime is worse than an 18-month payback with 5-year lifetime. Use
  payback to assess capital efficiency; use LTV/CAC to assess long-term value. Plans that lean
  on one and ignore the other are usually hiding something in the other.

If the payback period is long *and* the lifetime is short, the business may never reach
positive cumulative cash on a per-customer basis even before fixed costs. That's the most
serious unit-economics finding — flag it explicitly.

### 5. Gross-margin trajectory

A plan's unit economics today are almost never the unit economics it's being funded against —
investors fund toward the *steady-state* margin, which requires the plan to show a credible
path. The trajectory question is whether gross margin actually moves toward that steady state
as the business scales, or stalls.

Check the levers:

- **Where does margin expansion come from?** Common drivers: volume discounts from suppliers,
  in-housing previously outsourced functions, automation of manual operations, mix shift to
  higher-margin products, scale economies on infrastructure. Each is real but earned. The plan
  should name specific levers, not just project a 60%→80% margin curve.
- **Margin compression risks.** Symmetric question: what makes margin *worse* at scale?
  Competitive price pressure, customer concentration enabling negotiation, regulatory cost
  loads (compliance, security, audit), support-cost growth on complex customers, usage-based
  cost growth outpacing pricing. The plan should at least acknowledge the compression vectors
  it's betting against.
- **Mix-shift assumptions.** If margin expansion depends on selling more enterprise (or more
  premium-tier, or more add-on modules), that's a *go-to-market* claim wearing a margin
  trajectory mask. Is there evidence the mix is shifting that way, or is the plan assuming the
  mix that delivers the model?
- **Hardware, services, and one-time revenue.** Plans that include implementation services
  revenue at low or negative margin can show a healthy blended margin today that deteriorates
  as services revenue grows with customer count. Separate recurring SaaS margin from services
  margin in the trajectory.

The most useful framing here is usually: "the plan reports X% gross margin today and projects
Y% at steady state. The implicit assumption is [specific lever]. Has that lever been
demonstrated in a comparable company at comparable scale?" If not, the trajectory is a
hypothesis, not a baseline — say so.

## How to Structure the Critique

Output your critique as a Markdown document. Use this exact section layout so downstream
consumers (orchestrators, format tests, human readers comparing critiques) can rely on the
structure:

```markdown
# Unit-Economics Critique: <draft title or topic>

## CAC Assessment
## LTV Assessment
## Contribution Margin Assessment
## Payback Period Assessment
## Gross-Margin Trajectory Assessment
## Factual Foundation
## Overall Assessment
```

If a lens does not apply to the draft (e.g., the plan reports no LTV figure at all), keep the
section heading and state under it what the plan is missing rather than dropping the section.
The skeleton is fixed; the content adapts.

### CAC Assessment
Decompose CAC by channel where the plan permits. Identify any reliance on a non-scaling
channel that materially understates sustainable CAC. State whether the CAC figure appears to
be fully-loaded or ad-spend-only.

### LTV Assessment
Recover the implied retention, expansion, and gross-margin inputs from the stated LTV. Flag
any input that exceeds best-in-class comp performance. Note whether LTV appears to be
margin-weighted; if not, recompute roughly and note the corrected figure.

### Contribution Margin Assessment
Identify costs the plan treats as fixed that are actually variable per customer (support,
onboarding, usage-based infra, processing fees, revenue share). Estimate how much these
deductions reduce the stated gross margin at scale, and what that does to the unit-economics
conclusion.

### Payback Period Assessment
State the implied payback period from CAC, monthly revenue, and contribution margin. Compare
to the relevant industry benchmark. Assess the working-capital intensity at the planned
growth rate — funding ask vs. unrecovered CAC at peak.

### Gross-Margin Trajectory Assessment
Name the specific levers the plan implicitly relies on to reach steady-state margin. Note any
compression vectors the plan ignores. If margin expansion depends on mix shift or a specific
operational lever, assess whether that lever has been demonstrated.

### Factual Foundation
If a fact-check report was provided, briefly summarize the findings that bear on unit
economics — especially Unverified or Inaccurate findings about quoted CAC, churn benchmarks,
or comp-set margins. If no fact-check report was provided, identify the 2-3 numerical claims
in the plan that would most benefit from fact-checking.

### Overall Assessment
Of the five lenses, which surfaces the strongest unit-economics signal and which the weakest?
End with the single most important revision the author should make to the model. End
constructively — the goal is a more defensible plan, not a takedown.

## Output Location

When run standalone (not via the draft-review orchestrator), save your critique as
`docs/reviews/business-plan-critique-unit-economics.md` in the project root. Create
`docs/reviews/` if it doesn't exist.

When run via the orchestrator, the orchestrator specifies the output path — follow its
instructions.

## Goal-Alignment Note

When dispatched by an orchestrator, append a Goal-Alignment Note at the end of your critique
using the canonical form from
[`patterns/orchestrated-review.md`](../../patterns/orchestrated-review.md):

```markdown
## Goal-Alignment Note
- Answered: [yes / partial / no — one phrase]
- Out of scope: [what was set aside and why, or "none"]
- Escalate: [what the orchestrator should action separately, or "nothing"]
- Questions I would have asked: [1-3 short questions, only if scope was unclear; otherwise omit this bullet]
```

Use the **Out of scope** line specifically to flag moat/distribution or market-sizing
weaknesses you noticed but did not critique (those belong to sibling skills). The **Escalate**
line is the right place to surface a finding that crosses into another critic's territory —
for example, a CAC argument that depends on a distribution claim the moat critic should
re-examine, or a churn assumption that depends on a fact-check claim the orchestrator should
re-examine.

## Tone

Direct but constructive. The spirit is "let's see whether the math actually compounds" rather
than "let me show you why the numbers don't work." Founders pitching plans have already heard
generic skepticism on unit economics; what they need is structural diagnosis they can act on.
Be specific about what input is doing the load-bearing work in the model, not just what looks
optimistic.

Comfort with uncertainty matters. Many unit-economics questions don't have a clean answer at
early-stage — "the LTV figure is consistent with the cohort data observed so far, but the
cohort is too young to be confident about steady-state churn" is a more useful critique than
either "LTV is wrong" or "numbers look fine." Calibrate confidence explicitly, and when the
plan's number could be right but the supporting evidence is thin, say that exactly.
