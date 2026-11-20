# Market-Sizing Critique: Stockvet Seed Memo

> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

## TAM Definition Assessment

**Verdict:** Inflated
**Confidence:** High

The $62B TAM is the weakest number in the memo. Most of the rest of the market story is careful, which makes the weakness easy to fix.

**Category-report misfit.** The $62B (Meridian Research Partners) measures spend on animal health *products*. Stockvet sells *software subscriptions* at $4,800/year. It earns nothing from the product dollars that pass through the clinic. The memo's reasoning that "every dollar in the category is a dollar some clinic has to forecast, order, store and track" describes where Stockvet sits in the flow of goods. It does not describe what Stockvet can charge. By the same reasoning a clinic's accounting software could claim the whole $62B. The 8% growth rate has the same problem: it is the growth rate of product spend, not of clinic software spend.

**Geography and segment over-inclusion.** Within the $62B itself, the plan claims the full global figure while serving only the US, starting with the Pacific Northwest. The memo also says "almost every product in the category passes through a clinic's shelves." That claim carries a lot of weight and I have not verified it. Animal health market totals usually include production-animal (livestock and poultry) spend, which often goes through farm distribution channels rather than clinic shelves. They also include companion-animal products sold through retail and online pharmacies. Before relying on this claim, check Meridian's definition.

**Top-down vs bottom-up reconciliation.** The memo already has the inputs for a bottom-up build:

| Build | Clinics | × $4,800 ACV |
|---|---|---|
| All US clinics (incl. corporate) | 32,000 | $153.6M |
| US independents | 18,000 | $86.4M |
| Plan's SAM | 11,000 | $52.8M |

A realistic US TAM at current pricing is about **$150M**. Even with a generous international multiplier, it stays in the hundreds of millions. The gap between the headline and the bottom-up figure is about **400×**, far beyond the ~3× threshold at which one of the two numbers has to be wrong. Here the top-down number is wrong.

**Adjacency creep.** The $62B could become relevant if Stockvet charged a take rate on order flow (for example, a distributor-paid fee or a percentage of automated reorders) instead of a flat subscription. The memo describes no such model. If the founders have that in mind, it should be presented as a future revenue model with its own build, not counted as today's TAM.

**Why it matters.** A sophisticated seed investor will spot the misfit immediately, and it costs credibility that the rest of the memo earns. It also obscures the question that matters most for this company: the honest market is roughly $150M of US subscription revenue, so what is the path to venture scale? (See Overall Assessment.)

## SAM Realism Assessment

**Verdict:** Plausible
**Confidence:** Medium

This section is the memo's strongest piece of sizing work. SAM is built bottom-up, it excludes a buyer the company cannot sell to (corporate groups with centralised procurement), and the resulting dollar figure ($52.8M) is honest about its size. Several filters still need tightening.

**Possible inconsistency in the integration filter.** SAM counts clinics that "already run one of the four practice-management systems we integrate with." The raise, however, funds "two engineers for the California and Texas practice-management integrations." There are two possible readings:
- The 11,000 includes clinics on PMS platforms Stockvet has not yet integrated with. In that case today's SAM is smaller than stated and part of the 11,000 depends on the raise.
- CA and TX clinics run different PMS platforms that are outside the 11,000. In that case the year-4–5 expansion targets clinics that are not in SAM at all.

Either way, the memo should state which PMS platforms are live today and what the SAM is on those platforms alone.

**Missing distributor gate.** Automated reordering works through two distributors' APIs, which handle "most" of an independent clinic's purchasing. Clinics that buy significantly from regional distributors, or directly from manufacturers (vaccines and some parasiticides are often bought direct), get only partial automation. That weakens the value at $4,800. SAM should be filtered by distributor coverage, or the memo should say what share of a typical clinic's SKUs can be auto-reordered.

**Descriptive vs behavioral filters.** PMS platform is descriptive. The >400-SKU filter is a reasonable proxy for pain, but the memo itself says a typical clinic stocks 400–1,200 SKUs, so the filter removes very few clinics. Going from 18,000 to 11,000 (61% retained) appears to be driven mostly by PMS coverage, not by pain. The behavioral evidence (6.5 hours/week, two or more stock-outs per quarter, 2–4% write-offs) comes from *pilot* clinics, which chose to pilot and so are likely to be the most pained. The memo should state what fraction of the general independent population shows that pain. Unlike most plans, though, this one has revealed preference: 41 clinics are paying. A modest contraction for non-buyers (say 2–3×, not the typical 5–20×) seems reasonable.

**Structural erosion risk.** Independents are the buyer, and corporate groups that centralise procurement are not. My understanding is that US vet-clinic consolidation has been a sustained trend, though I have not verified current rates. If so, SAM may be shrinking each year, and customers acquired by a consolidator may churn. The memo should state the trend in independent clinic counts and its effect on the 11,000.

**What works:**
- The wedge is explicit: the 1,200-clinic beachhead gives a year-1 addressable revenue of $5.76M.
- The buyer (owner-operator or practice manager) is correctly identified.
- The ACV is consistent with the segment. Against the pilot pain figures (6.5 hours/week of labour plus several thousand dollars of write-offs), $4,800/year is a coherent price.

## SOM Achievability Assessment

**Verdict:** Plausible
**Confidence:** Medium

The share targets are modest and come with a defined path. The main problem is the *ceiling*, not the capture rate.

**Implied share.**
- Year 5: 700 / 11,000 = **6.4% of SAM**. $3.36M ARR checks out (700 × $4,800).
- Beachhead: 300 / 1,200 = 25% by end of year 3. This sits inside the 20–40% range that is often achievable in a small, well-reached wedge. Founder networks and association endorsements make it credible.
- Current: 41 clinics = 3.4% of the beachhead.

**Sales capacity points in an unexpected direction.** Three reps × 8 closes/month = 24 clinics/month, or about **288/year at full ramp**. The beachhead target needs roughly 260 more clinics over the 24-month runway. Even after a few months of ramp, the stated rep productivity would *overshoot* the 300 target. The memo is therefore internally inconsistent in one of two ways:
- Rep productivity is overstated. Going from founder-led sales of about 3/month to 24/month is a large jump, and 8 field closes per rep per month is aggressive across the sparse Mountain-state geography.
- The binding constraint is beachhead demand, not sales capacity. If so, the reps will run out of willing buyers well before month 24.

The memo should say which one applies. If it is demand, the 25% beachhead share is the critical assumption and needs supporting evidence: conversion rates from the association meetings and pipeline data.

**Expansion logic.** Years 4–5 add 400 clinics in California and Texas, which depends on the integrations discussed above. This step has much less support than the beachhead. The founders have no comparable network there, and no association commitment is mentioned. Show what CA/TX acquisition looks like without warm channels.

**Competitive density.** The memo frames the competition as "spreadsheet + Friday-afternoon walk." The real displacement risks are the PMS vendors' own inventory modules and the distributors' own auto-replenishment tools. Both are well placed to use the same APIs (see Timing). The memo does not address either.

**The real constraint is the ceiling.** Even 30% of SAM is about $16M ARR. A Series A raised on 300 clinics ($1.44M ARR) will be judged on whether there is a path well beyond the current SAM. Some candidates:
- Pricing expansion or additional modules.
- Corporate groups, with a different product and sales motion.
- Take-rate revenue on reorders.
- Adjacent markets such as dental and optometry, which the comp section suggests the founders know.
- International.

Today the plan's capture assumptions are reasonable, but it is optimising for share of a market that may be too small to fund.

## Market Timing Assessment

**Verdict:** Defensible
**Confidence:** Medium

This is a textbook "why now": a specific trigger with a date, a clear before and after, and a mechanism that ties it to product feasibility. In March 2025 the two large national distributors opened ordering APIs, and before that, screen-scraping was prohibited. That is a platform-primitive change, not a ten-year trend. Confidence is Medium only because the claim is unverified and the trigger has some fragility.

**Pressure points:**
- **Reversibility.** The thesis rests on one catalyst controlled by two counterparties. The distributors could restrict access, charge API fees, or favour their own tools. Note that a distributor benefits when reordering stays inside its portal, which may lock the clinic in. What is the API access agreement, and has either distributor signalled a long-term commitment? Having two distributors is some protection, but both acted at the same moment, which suggests a shared cause (regulation? competitive pressure?) that could reverse for both at once.
- **The window is closing.** It is now about 20 months after the APIs opened. Any PMS vendor, distributor, or well-funded entrant has had the same primitive for the same length of time. The trigger explains why the market is newly *possible*. It does not explain why Stockvet in particular will win it. That question belongs to the moat critic, but it affects how durable the timing advantage is.
- **Adoption curve.** At 41 of 11,000 clinics (0.4%), the market is at the innovator stage. Founder-network selling and association endorsements fit that stage. The CA/TX expansion is where the plan crosses into early adopters without warm channels, and the motion will need to change.
- **Too early vs too late.** Not too early: clinics already spend money on the problem in labour (6.5 hours/week) and write-offs, and 41 are paying. Possibly too late is the risk to watch, if incumbents with existing clinic relationships ship a "good enough" auto-reorder module.

## Comparable Benchmarks Assessment

**Verdict:** Plausible
**Confidence:** Medium

The comp set is unusually honest. It includes a failure (Clinicshelf) and a stall (Optistock), and draws an explicit structural lesson about SKU count that is reflected in the SAM filter. That is better than most seed memos manage. Gaps remain.

**Stage and denominator matching for Dentrack.** "2,100 practices six years after launch" is meaningful only relative to its addressable base. To my knowledge, the US has many more independent dental practices than independent vet clinics. If so, Dentrack's *share* may be well below Stockvet's projected 6.4%, even though its absolute count is higher. The memo should state Dentrack's share of its SAM at year 5. That is the comparison that tests the 6.4% figure. Also: when did Dentrack launch, and did dental distributors offer ordering APIs then? If Dentrack had a structurally different integration path, the comp is weaker.

**Selection logic.** All three comps are horizontal "inventory for independent clinical practices" plays in *other* verticals. The negative comps that matter most are missing: earlier attempts at veterinary inventory or reordering software, distributor-built replenishment tools, and PMS inventory modules. If nobody tried before March 2025 because the APIs did not exist, say so explicitly. That strengthens the timing thesis. If someone tried via screen-scraping or manual workflows and failed, explain why.

**Outcome conditioning.** Three comps make a thin base rate. The memo implicitly ranks Stockvet with the winner (Dentrack) using qualitative reasoning about SKU count, perishability, and owner-operators. The reasoning is sensible, but it is the only thing keeping Stockvet out of the Optistock bucket. The founders appear to have spoken to Optistock's founders. One quantitative point would turn that argument into evidence: a SKU-count or savings-per-clinic comparison across dental, vet, and optometry.

**Implied trajectory vs comps.** The plan projects 700 practices at year 5, against Dentrack's 2,100 at year 6. In absolute terms Stockvet is *below* its best comp, which is conservative. The share comparison above is still needed to confirm this.

## Factual Foundation

No fact-check report was provided. The claims that most need verification, in order of how much they carry:

1. **The March 2025 distributor API launch and the distributors' coverage.** The timing thesis and the product's feasibility rest entirely on it. Verify the launch date, the terms of third-party access, and what "most of the product an independent clinic buys" means as a percentage.
2. **US clinic counts (32,000 total, 18,000 independent) and the 11,000 qualifying figure.** SAM is built on these. Verify the source, the direction of the trend in independents, and how the PMS and SKU filters were applied.
3. **Meridian Research Partners' $62B and 8% growth.** Lower priority, because the critique above argues the figure should not be the TAM at all. If it stays in the memo as context, verify the figure and its segment composition (companion vs production animal, clinic vs retail channel).

Dentrack's 2,100-practice figure and launch date also need checking if the comp is kept.

## Overall Assessment

**Strongest lenses:** Market Timing and SAM Realism. The memo names a dated, specific, mechanistic trigger. It builds SAM bottom-up with explicit exclusions, names a wedge, and supports its pricing with pilot pain data and paying customers. Few seed memos do this.

**Weakest lens:** TAM Definition. The $62B figure counts product throughput as software revenue, overstates the bottom-up TAM by about 400×, and conflicts with the disciplined sizing in the rest of the memo.

**Secondary issues to resolve:**
- Whether the 11,000-clinic SAM includes PMS integrations that are not yet built.
- Whether sales capacity (about 288 clinics/year at full ramp) or beachhead demand is the binding constraint, since they do not reconcile.
- The missing in-vertical negative comps: PMS modules and distributor tools.

**The single most important revision:** Replace the $62B TAM with the bottom-up build (about $150M US at current pricing) and add an explicit **path-to-scale** section. Name the one or two expansion vectors that could take the market beyond the current SAM's roughly $16M realistic ceiling, such as order-flow take rates, corporate groups, or adjacent clinical verticals, and size each one bottom-up. This trades a large number that investors will discount for a small number they will trust, paired with a credible plan to make it bigger. The beachhead and timing story is good enough to support that honesty.
