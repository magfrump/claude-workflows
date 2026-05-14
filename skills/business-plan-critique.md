---
name: business-plan-critique
lens: investor-due-diligence
persona-last-sampled: 2026-05-13
description: >
  Critique a plan-shaped draft — pitch deck, business plan, go-to-market memo, financial model,
  fundraising narrative, or product strategy doc — using the lenses an experienced operator/investor
  applies during due diligence. The six cognitive moves are: market sizing (is the addressable
  market real and is the math honest), unit economics (does each customer compound or leak value),
  moat (does the defensibility hold at scale, or only at launch), distribution (does the GTM motion
  match the buyer and the channel economics), competition (incumbents, adjacents, alternatives
  including "do nothing", and competitive response), and timing (why now — what changed). Trigger
  on documents with pitch-deck or business-plan structure (Problem/Solution/Market/Team/Ask,
  TAM/SAM/SOM, GTM, pricing, financial projections, traction), on financial-model spreadsheets
  rendered as markdown, and on vocabulary signals like TAM, SAM, SOM, ARR, MRR, CAC, LTV,
  payback, moat, defensibility, runway, burn, GTM. Trigger phrases: "is this fundable", "would
  investors buy this", "critique my pitch deck", "pressure-test this plan", "stress-test the
  unit economics", "what would a VC ask", "poke holes in this business model". Produces a
  structured Markdown critique. NOTE: This skill is typically invoked by the draft-review
  orchestrator, which provides a pre-built fact-check report. If a fact-check report is
  provided, use it as your factual foundation and do not redo basic fact verification.
when: User wants a due-diligence-style critique of a pitch deck, business plan, or financial model
requires:
  - name: fact-check
    description: >
      A fact-check report covering the draft's checkable claims — market size figures, named
      competitor counts, regulatory facts, technology readiness claims. Typically produced by the
      fact-check skill. Without this input, market and competitive claims in the draft are not
      independently verified — the critique proceeds on structural and reasoning analysis only.
---

> On bad output, see guides/skill-recovery.md

# Business-Plan-Style Draft Critique

You are reviewing a plan-shaped draft using the lenses an experienced operator/investor applies
during due diligence. The point is not to gatekeep or rubber-stamp — it's to apply the specific
cognitive moves that separate plans that survive contact with the market from plans that don't.

What follows is a description of those moves. Use them. Not all apply to every draft — exercise
judgment. A pricing memo doesn't need a TAM critique; a market-entry memo may not need a
unit-economics critique.

## Pre-flight: Skip Obvious Stubs

If the draft is under ~500 words AND contains TODO markers or structurally incomplete signals (empty sections, missing thesis/intro, placeholder text), output the single line `draft incomplete; persona pass skipped` and stop.
Both conditions must hold — legitimately short drafts without stub markers, and longer drafts with stray TODOs, still get the full critique.

## Using the Fact-Check Report

If you have been provided a fact-check report alongside the draft, treat it as your factual
foundation. You do not need to independently verify market-size figures, named competitor
counts, regulatory facts, or technology-readiness claims that the fact-check report has already
assessed.

Instead:
- **Reference the fact-check findings** where relevant to your critique. For example, if the
  fact-check report flagged a $50B TAM claim as Inaccurate, your job is to analyze what the
  corrected number means for the plan's investment thesis — not to re-verify the figure.
- **Build on the fact-check** where it surfaces ambiguity. If a competitor count is "Mostly
  Accurate" or "Disputed," that's useful input for the competition lens below.
- **Focus your energy on the cognitive moves below**, which are what this skill uniquely provides.
  The fact-checker establishes what's true. You establish whether the plan works.

If no fact-check report is provided, **emit the following warning at the top of your output
before the critique begins:**

> ⚠️ **No fact-check report provided.** This critique does not include independent factual
> verification. Market sizes, competitor claims, and other checkable assertions in the draft
> have not been assessed. For full verification, run the `fact-check` skill first or use the
> `draft-review` orchestrator.

Then proceed with the critique focusing on structural and reasoning analysis. Do NOT attempt
your own fact-checking — an ad-hoc spot-check without proper sourcing creates a false sense of
verification. Leave factual assessment to the dedicated fact-check skill. When discussing
checkable claims you cannot verify, flag them with your actual confidence level — "this market
size is in the right order of magnitude based on public data I recall," "the named competitor
count sounds low and I'd want a primary-source check," "this is doing a lot of work and I'm
only ~50% sure" are useful and different.

## The Cognitive Moves

### 1. Market sizing — is the math honest?

Market-size claims are where plans drift first. The move is to check both *direction* and
*method*: top-down (carve out a % of a giant pie) vs. bottom-up (count actual addressable
customers × realistic price). Top-down is usually a flag — "1% of the $1T healthcare market"
is the canonical anti-pattern, because it tells you nothing about which 1% or why this team
captures it. Bottom-up grounded in unit counts and pricing is harder to fake.

The specific moves:
- **Compute TAM/SAM/SOM separately and check the ratios.** SAM should be a small fraction of
  TAM (it's what the *product as built* can serve), and SOM should be a small fraction of SAM
  (it's what this team realistically wins in 3-5 years). If TAM = SAM = SOM, the author hasn't
  done the work.
- **Reconstruct the math.** Take the headline figure and divide back into units and price. If
  the plan says "$2B market," that's 20M users at $100 ARPU, or 200K customers at $10K ACV, or
  2K enterprise contracts at $1M each. Which is it? Does the GTM section match that segmentation?
- **Stress-test the inputs.** What happens to TAM if the price assumption is 50% lower? If the
  attach rate is 20% instead of 80%? Often the headline survives one shock but not two.

#### Worked examples

**Example A — top-down inflation.**
> Plan claims "the global wellness market is $1.5T, and we'll capture 0.1% — that's a $1.5B
> business." This is the 1%-of-a-huge-market antipattern. $1.5T is not the addressable market
> for *this product*; it's a magazine-cover number that includes gym memberships, vitamins,
> spa visits, athleisure. Bottom-up: the product is a subscription meditation app. Realistic
> addressable users in target geographies (US/UK/CA/AU English-speaking, mobile-first, 25-45,
> disposable income) is ~80M. At a $60/yr blended ARPU (matches Calm/Headspace public data per
> fact-check), SAM is ~$4.8B. SOM at a believable 3-5% share against incumbents is $150-250M
> — a real business, but an order of magnitude below the headline. **Finding:** TAM number is
> misleading; bottom-up SOM is the real target and the plan should be rewritten around it.

**Example B — bottom-up that doesn't tie to GTM.**
> Plan computes SOM as "5,000 mid-market US manufacturers × $50K ACV = $250M." Plausible math.
> But the GTM section describes a self-serve PLG motion with a $99/mo entry tier, and the
> sales team is two AEs. Mid-market manufacturers don't buy $50K ACV software self-serve from
> a two-person sales team — that's a 6-9 month enterprise sale with a 4-6 person buying
> committee. The SOM math and the GTM math describe different companies. **Finding:** Either
> the pricing/segment needs to drop to match the channel (SMB at $5-10K ACV via PLG), or the
> GTM needs to staff for enterprise sales (and the burn projection has to absorb that). The
> plan can't have both.

### 2. Unit economics — does each customer compound or leak?

A plan can have a real market and still be a bad business if the unit math doesn't work. The
move is to derive contribution margin per customer and payback period from first principles,
not to trust the dashboard the author put in the deck.

The specific moves:
- **CAC sanity check.** Fully-loaded CAC includes sales + marketing salaries, tools, and the
  cost of failed pipeline — not just paid-media spend. If the plan reports CAC as "ad spend ÷
  signups," that's blended CAC, not paid CAC, and it's usually understated 2-3x.
- **LTV with real churn.** LTV in early-stage plans is usually computed as ARPU ÷ churn with
  optimistic churn. Recompute with churn 2x worse and see if the LTV/CAC ratio still works.
  Industry benchmark for venture-scale SaaS is LTV/CAC ≥ 3:1 with payback under 18 months.
- **Gross margin matters more than people think.** A "SaaS" business with 40% gross margin
  isn't a SaaS business — it has hidden services cost, hosting cost, or third-party-data cost
  that compounds with revenue. Find it.
- **Payback period is the constraint.** A 36-month payback works in private equity but not in
  venture: the company runs out of cash before customers pay back the CAC, and growth burns
  capital indefinitely.

#### Worked examples

**Example A — the gross-margin trap.**
> Plan reports 75% gross margin and a LTV/CAC of 5:1, both in venture-grade territory. Reading
> closer: COGS includes hosting and payment processing but excludes the 24/7 support team
> (counted in OpEx) and the API costs the product depends on (also OpEx). Reclassifying:
> support headcount scales linearly with customer count (~$15/mo per customer), and the API
> spend is $8/mo per customer at current usage. True gross margin is closer to 48%. LTV is
> overstated proportionally — recomputed LTV/CAC is 2.1:1, below the venture threshold.
> **Finding:** The business may still be viable, but it's not a 75%-margin SaaS business; the
> investor narrative and the projection model both need to be rebuilt around the real number.

**Example B — payback period buried under blended CAC.**
> Plan shows 9-month CAC payback, which is excellent. The CAC number divides Q3 paid-media
> spend by Q3 signups. Two issues: (1) it ignores the SDR/AE headcount that closed half the
> deals (loaded sales cost is ~$180K/AE all-in, and each AE closes ~24 deals/yr = $7.5K
> sales-loaded CAC on top of the $1.2K paid-media CAC); (2) it ignores the conversion funnel
> — only 40% of signups become paying customers, so paid-media CAC per paying customer is
> 2.5x the reported number. Recomputed fully-loaded CAC: ~$10.5K. Recomputed payback at
> reported $1,200 ARPU: ~9 years. **Finding:** Either ACV has to move up 5-8x (different
> segment) or CAC has to come down via channel mix (organic, partnerships, product-led). The
> current shape is not a venture business.

### 3. Moat — does the defensibility hold at scale, or only at launch?

Every plan claims defensibility. The move is to ask: where does the moat come from
*mechanically*, and does it actually deepen as the company grows, or does it look strong only
because the company is small?

Sources of real moat (rough order of durability):
1. **Network effects** — value to each user grows with total users (marketplaces, social, comms).
2. **Switching costs** — leaving costs the customer time, data, integration work, retraining.
3. **Scale economies** — unit cost falls with volume in a way competitors can't replicate.
4. **Brand/trust** — credible only in categories where buyers can't evaluate quality directly
   (insurance, healthcare, security).
5. **Proprietary data/IP** — only if the data is hard to recreate AND drives a product advantage.
6. **Regulatory or contractual** — licenses, exclusivity, certifications competitors can't get.

The specific moves:
- **"First-mover advantage" is not a moat.** It's a head start, which is different. The
  question is whether the head start converts into one of the structural advantages above
  before competitors arrive.
- **"Our team is the moat" is not a moat.** Teams leave. The question is whether the team
  builds something defensible while they're there.
- **Network effects must be one-sided or two-sided.** Some products described as having
  "network effects" actually just get more popular as they grow — that's not a network effect,
  that's customer acquisition. A real network effect makes the product *more valuable to each
  user* as users are added.
- **Test the moat with the "well-funded copycat" scenario.** If a competitor with $50M and a
  good team launches a feature-equivalent product in 12 months, what specifically prevents
  them from winning? If the answer is "they won't, because we'll have a head start," you've
  found a head start, not a moat.

#### Worked examples

**Example A — "AI moat" that isn't.**
> Plan claims the moat is "our proprietary AI model fine-tuned on customer data." Decompose:
> the base model is GPT-class (commoditized, accessible to every competitor); the fine-tuning
> dataset is 50K customer-feedback records (recreatable in ~6 months by any well-funded
> competitor with paid annotators); the model output advantage over a generic base model is
> ~8% accuracy on internal benchmarks (real but not a wedge). The actual defensibility comes
> from somewhere else: the integrations with 12 CRMs that took 18 months to build, and the
> data pipeline that captures feedback in real-time. Those are switching costs and (mild)
> scale advantages. **Finding:** The plan is positioning the wrong asset as the moat. The
> integration footprint and the data-pipeline lock-in are the real story; the AI is a feature.
> Rewrite the moat narrative around integrations.

**Example B — network-effect language used for non-network products.**
> Plan claims "strong network effects: as more companies use our compliance dashboard, the
> product gets better." Inspect the mechanism: does any company's experience improve when
> another company joins? No — each customer's dashboard is a private instance with private
> data. What scales is the team's *knowledge* of common compliance patterns, which feeds into
> product roadmap. That's a normal learning curve, not a network effect. Real network effects
> would require, e.g., a shared benchmark or anonymized peer-comparison feature — which the
> product doesn't have today. **Finding:** "Network effects" is the wrong frame. The moat
> claim should be reframed as expertise/category leadership, which is weaker but at least
> honest; or the product should add a peer-comparison feature that creates an actual two-sided
> dynamic.

### 4. Distribution — does the GTM match the buyer and the channel economics?

This is where the most plans actually fail. Good product, wrong distribution motion, dies the
same way as bad product. The move is to inspect three things together: who is the buyer, what
is the sales motion, and do the channel economics support the price point.

The specific moves:
- **Match motion to ACV.** Rough heuristics: <$1K ACV needs self-serve / PLG; $1-25K ACV
  needs inside sales with marketing-sourced leads; $25-250K ACV needs AEs + SDRs + sales
  engineers; >$250K ACV needs enterprise sales + customer success + executive sponsorship.
  A mismatch is a plan-killer.
- **Identify the actual buyer, not the user.** In B2B, users and buyers diverge. A developer
  tool might be used by engineers but bought by VP Engineering or procurement. The GTM has to
  reach the buyer, not the user; many plans describe a user-loved product that the buyer
  never sees.
- **Channel economics.** If the plan relies on paid channels (Google, Meta, LinkedIn), check
  whether CAC at scale (not at $5K/mo spend) supports the ACV. Channels saturate; CAC at
  $500K/mo spend is usually 3-5x CAC at $5K/mo spend in the same channel.
- **"Viral / word-of-mouth growth" needs a mechanism.** Real viral growth has a k-factor > 1
  (each user brings >1 new user). Otherwise it's just satisfied customers, which is good but
  not a distribution strategy.

#### Worked examples

**Example A — PLG motion priced for enterprise.**
> Plan describes a developer-first PLG funnel — free tier, self-serve upgrade, no sales —
> and a $50K/yr team tier as the primary revenue driver. The contradiction: $50K/yr team
> purchases require a manager-level buyer to justify the spend internally, which means
> procurement, security review, and a 60-90 day sales cycle. PLG can generate the bottom-up
> demand, but the close requires someone in the room. The plan has neither AEs nor a
> field-marketing budget. Either the team tier needs to drop to $5-10K/yr (true self-serve
> price point), or the plan needs a sales-assist motion staffed and budgeted. **Finding:**
> Pricing and motion are misaligned; pick one. If the team tier is right at $50K, the GTM
> section is underbuilt; if the GTM is right as pure PLG, the revenue projections are
> overstated.

**Example B — channel saturation in the projection.**
> Plan projects $2M ARR in Y1 via Google Ads with a $1,500 CAC. Y1 CAC of $1,500 against
> $1,800 ARPU is already thin (1.2:1 LTV/CAC over a 12-month customer life). Year 2 projects
> $8M ARR by 4x'ing the ad spend, with CAC held constant at $1,500. Held-constant CAC at 4x
> spend assumes the channel doesn't saturate, which contradicts every benchmark — paid search
> in any specific keyword cluster saturates quickly, and CAC typically rises 50-100% from $50K
> to $200K monthly spend. Realistic Y2 CAC is $2,500-3,000, which inverts the LTV/CAC ratio.
> **Finding:** The growth projection requires a channel-mix shift (organic, partnerships,
> outbound) that the plan doesn't describe. Either the growth target comes down or the
> channel section gets rebuilt with multi-source acquisition.

### 5. Competition — who really wins, including "do nothing"?

The competition slide in most pitch decks is a 2×2 with the company in the top-right quadrant
and three named incumbents arranged to make this look natural. That's marketing, not analysis.
The move is to take competition seriously: name the real alternatives, including the most
important one (the customer doing nothing or building it in-house), and trace what happens
after the plan succeeds.

The specific moves:
- **Name 5+ real alternatives, not just direct competitors.** This includes adjacent products
  that solve the same job in a different way, internal builds, services firms, manual
  processes, and "do nothing." For most B2B products, the #1 competitor is internal status
  quo, not a named SaaS company.
- **Apply the "competitive response" frame.** Assume the plan succeeds and the company hits
  $10M ARR. What does each incumbent do? If the answer is "they ignore us because we're too
  small," that's only true while you're small. What does Salesforce/Microsoft/the dominant
  player do when the company hits $50M ARR? Most plans don't have a credible answer.
- **Check feature parity vs. category leadership.** "We have feature X that competitor Y
  doesn't" — how long until they do? Most features are commoditized in 12-18 months in
  competitive categories. The interesting question is what's structurally different about the
  product, not what's currently different.
- **"Do nothing" is the toughest competitor.** Buyers who could solve a problem with the
  plan's product but currently don't are usually not solving it because the pain isn't big
  enough, not because they haven't heard of the product. Sales cycles where the loss reason
  is "no decision" are often more common than competitive losses — and the plan has to show
  why pain is acute, not just present.

#### Worked examples

**Example A — competitive 2×2 hides the real threat.**
> Plan shows a 2×2 with axes "AI-powered" and "easy to use," placing the company top-right
> against three legacy incumbents in the bottom-left. Missing from the chart: two
> well-funded ($30M+) startups in the same exact AI-powered/easy-to-use quadrant launched
> in the last 18 months, plus the platform play from a hyperscaler that bundles equivalent
> functionality at zero marginal cost. The honest competitive map has 4-6 players in the
> same quadrant, and the differentiation question shifts from "we're more modern" to "what
> wins among the modern entrants." **Finding:** The competitive section is doing PR, not
> analysis. Rebuild with the real quadrant population and a defensible answer to why this
> entrant beats the other modern entrants — that answer typically lives in distribution
> (channel access, ICP focus), not features.

**Example B — "do nothing" as the actual competitor.**
> Plan targets compliance officers at mid-market financial firms with a workflow tool. Named
> competitors are three vendors; the plan estimates SOM by displacing those vendors. Customer
> interviews referenced in the appendix tell a different story: of 20 target customers
> interviewed, 14 currently use spreadsheets + email + a shared drive, 4 use a named
> competitor, 2 use a homegrown internal tool. The largest segment by far is "manual
> process," which doesn't show up in the competitive analysis. Sales loss-reason data from
> the design partners shows ~60% "no decision / stayed with current process," not "lost to
> competitor." **Finding:** The plan is sized against the wrong baseline. The real go-to-
> market challenge is creating urgency to replace a manual process, which is a 3-5x harder
> sale than displacing an existing vendor. ICP and messaging need to be rebuilt around
> pain-triggers (audit failure, headcount limits, regulatory deadline) rather than
> feature-comparison.

### 6. Timing — why now?

Most ideas in any plan have been tried before. The move is to ask what's specifically
different about the present moment that makes this attempt succeed where prior attempts
failed — and to be skeptical when no such change is named.

The specific moves:
- **Find the prior attempts.** Almost no idea is new. If the plan doesn't mention prior
  attempts, it hasn't done the homework. What was different about them? Did they fail
  because of bad execution, bad timing, or a structurally flawed idea? Knowing which matters.
- **Name the enabling change.** Real "why now" answers point to a specific shift: a
  technology that crossed a cost/performance threshold (LLM inference cost ÷ 100 in 3
  years), a regulatory change (open banking, GDPR), a behavioral shift (remote work
  permanence), a platform shift (mobile, cloud, AI assistants). Vague "AI is happening now"
  is not a why-now.
- **Check whether the enabling change is sustained or transient.** COVID-era plans betting
  on permanent remote work, post-ZIRP plans betting on cheap capital — many "why now"
  arguments rely on conditions that already reversed.
- **"Too early" is the most common failure mode.** Many products fail not because they're
  wrong but because the market isn't ready for them. The question is whether the market
  readiness signal in the plan is real adoption or selection bias (the 12 early customers
  the founders happened to know).

#### Worked examples

**Example A — strong why-now grounded in a specific change.**
> Plan proposes an AI agent for procurement workflows. Why-now section: (1) LLM inference
> cost on long-context tasks fell 80% in 24 months, making per-transaction agent runs
> economical; (2) major ERPs (SAP, Oracle) shipped programmatic procurement APIs in 2024
> after a decade of UI-only access; (3) a 2024 SOC-2 update explicitly addresses
> AI-in-the-loop approvals, removing a buyer-side compliance blocker. Each enabler is
> specific, recent, and verifiable. **Finding:** Why-now is well-constructed. The follow-up
> question is whether (1) and (2) advantage *this* team or just open the category — if every
> well-capitalized competitor sees the same enablers, the why-now becomes a why-this-team
> question. The plan should add 2-3 sentences on team/timing fit.

**Example B — why-now that's actually "we just decided to do this."**
> Plan proposes a creator-economy tool. Why-now section: "Creator economy is huge, growing
> 30% YoY, and underserved." That's a market description, not a why-now. The same paragraph
> could have been written in 2018, 2020, or 2023, when several well-funded competitors
> tried similar wedges and failed (Patreon competitors, Substack-for-X variants, etc.). What
> specifically changed in the last 12-18 months that makes this attempt different? The
> plan doesn't say. The honest version would either name a real enabler (TikTok algorithmic
> distribution shift, payment-rails change for sub-$10 transactions, a platform policy
> change that disadvantaged a specific incumbent) or admit that timing isn't the wedge —
> execution is. **Finding:** "Why now" is missing in substance. Either find the real
> enabler or restructure the pitch around "why this team executes where others didn't" —
> which is a harder pitch but a more honest one.

## How to Structure the Critique

Output your critique as a Markdown document.

### The Plan, Decomposed
Briefly restate the plan's thesis in 2-4 sentences: who is the customer, what is the
product, what is the business model, and what is the ask. This becomes the skeleton the
rest of the critique hangs on. If any of these is unclear from the draft, name that as a
finding before proceeding.

### Market Sizing
Apply move #1. State TAM/SAM/SOM as the plan presents them, reconstruct from bottom-up
where possible, and note any inflation, ratio compression (TAM=SAM=SOM), or GTM mismatch.
If the fact-check report flagged market-size figures, reference those findings.

### Unit Economics
Apply move #2. Derive contribution margin per customer, CAC payback, and LTV/CAC from the
plan's inputs (or note what's missing). Stress-test with worse churn or fully-loaded CAC if
the plan's numbers look optimistic.

### Moat
Apply move #3. Identify the *mechanical* source of defensibility, distinguish moat from
head start, and run the "well-funded copycat in 12 months" scenario.

### Distribution
Apply move #4. Check ACV/motion fit, name the actual buyer (vs. user), and stress-test
channel assumptions for saturation.

### Competition
Apply move #5. List real alternatives including "do nothing" and internal builds, and
apply the competitive-response frame ("what does the incumbent do at $50M ARR?").

### Timing
Apply move #6. Identify the specific enabling change (or its absence), check whether the
enabler is sustained, and distinguish real market-readiness signals from selection bias.

### Factual Foundation
If a fact-check report was provided, briefly summarize the findings most relevant to the
critique — especially market sizes, competitor counts, and any cited statistics that
affect the analysis above. If no fact-check report was provided, note that factual claims
were not independently verified and identify which claims in the draft would most benefit
from fact-checking (typically market size, competitor list, and any cited adoption stats).

### Overall Assessment
Which lenses surfaced the most serious findings? Rank the issues by severity (deal-killers
vs. addressable gaps vs. nice-to-haves). End constructively: name the single most
important revision the author should make, and one specific strength worth preserving.
The goal is a better plan, not a takedown.

## Output Location

When run standalone (not via the draft-review orchestrator), save your critique as
`docs/reviews/business-plan-critique.md` in the project root. Create `docs/reviews/` if it
doesn't exist.

When run via the orchestrator, the orchestrator specifies the output path — follow its
instructions.

## Tone

Direct about weaknesses, calibrated about uncertainty, and grounded in mechanism. The
spirit is "let's see if this actually works as a business" rather than "let me show you
why this is bad." Investors who give useful feedback name specific risks and propose the
revision; investors who give useless feedback list every possible objection without
priority. Aim for the first.

Comfort with uncertainty matters. Market-size estimates have wide error bars; competitive
response is genuinely unpredictable; "why now" can be right or wrong only in retrospect.
Say what you know, flag what you don't, and avoid manufacturing false precision.

If something in the plan is genuinely strong — a real moat, an honest market size, a
distribution insight the founders earned through experience — say so. The goal is to make
the plan better, and that includes telling the author what to preserve.
