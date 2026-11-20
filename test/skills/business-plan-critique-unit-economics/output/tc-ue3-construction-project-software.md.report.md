⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable numerical claims in the draft (quoted CAC, churn rates, gross-margin benchmarks, pricing comps) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Unit-Economics Critique: Groundwork Growth Plan and Series A Financial Narrative

**Summary.** The pricing, gross margin and retention mechanics are solid. The plan's headline problem is a classification choice. Implementation and customer success are described as fixed overhead, but the plan's own staffing ratios show both are variable per customer. Re-costing them as variable has three effects:

- **Payback:** rises from about 12 months to about 28.
- **LTV/CAC:** falls from about 10x to about 4x.
- **Year-three operating leverage:** most of it disappears.

The business may still be fundable. It just isn't fundable on the story the plan currently tells.

---

## CAC Assessment

**The good part.** The CAC figure is fully loaded (salaries, commission, events, programs) and decomposed by channel. That is better than most Series A plans. It also models outbound CAC inflation, which is the right instinct. The arithmetic reconciles: 36 × $17,500 + 24 × $11,250 = $900,000, or $15,000 blended.

**Implementation is an acquisition cost.** The plan treats it as overhead, but each new customer costs $560,000 / 60 = **$9,333** of implementation labor. The plan also says customers who aren't live within 60 days usually churn. Implementation is therefore part of what it costs to acquire a retained customer. Investors will add it to CAC.

| | Sales & marketing CAC | + Implementation | Fully loaded acquisition cost |
|---|---|---|---|
| Inbound | $11,250 | $9,333 | $20,583 |
| Blended | $15,000 | $9,333 | **$24,333** |
| Outbound (today) | $17,500 | $9,333 | $26,833 |
| Outbound (year 3, +10%/yr) | $23,293 | $9,333 | $32,626 |

**The mix shifts toward the expensive channel.** The raise grows outbound from four to ten AEs. Inbound includes referrals and has no stated scaling plan. Blended CAC should therefore drift toward the outbound number, and rise faster than either channel does alone. The plan should model blended CAC by year with the mix shift explicit.

**Sales capacity looks short of the 600-customer target.** This is a sanity check, not a firm finding. Four AEs produced 36 outbound customers, about 9 per AE per year. I don't know the AEs' tenure or ramp, so treat that productivity figure loosely. At that rate, ten AEs produce about 90 outbound customers a year.

To grow from 150 to 600 in three years at 10% churn, the business needs roughly these gross adds (assuming even compounding, about 1.59x per year):

| Year | Gross adds needed |
|---|---|
| 1 | ~100 |
| 2 | ~165 |
| 3 | ~260 |

Year three is the gap. Ten AEs plus today's inbound volume gets to roughly 115 a year. Reaching 260 requires one of these:

- AE productivity roughly doubling, which conflicts with the plan's own assumption of rising outbound CAC.
- Inbound scaling several-fold.
- More AEs than the raise funds.

Either the target or the hiring plan needs to move.

## LTV Assessment

**Reconstructing the stated LTV.** $14,760 annual gross profit / 10% churn = $147,600. Credit where due:

- It is margin-weighted.
- It does *not* bake in the 104% NRR. That is conservative.
- The expansion mechanism is structural. Pricing is per active project, and expansion comes from customers adding projects.

The implied expansion is also plausible. With 10% logo churn and 104% NRR, surviving customers must grow about 15.6% a year (0.9 × 1.156 ≈ 1.04).

**Problem 1: margin-weighted at the wrong margin.** LTV should use contribution margin, not gross margin. CS costs $110,000 / 25 accounts = **$4,400 per customer per year** ($367/month). That gives:

| | Gross margin basis (as stated) | Contribution basis |
|---|---|---|
| Monthly profit per customer | $1,230 | $863 |
| LTV at 10% churn | $147,600 | **$103,600** |
| Acquisition cost | $15,000 | $24,333 |
| LTV/CAC | 9.8x | **4.3x** |

4.3x is still healthy. But it is a different headline from "near-10x," and the plan's top-quartile claim rests on the 9.8x.

**Problem 2: a 10-year lifetime from 3 years of data.** Dividing by 10% churn assumes a 10-year average lifetime. The oldest cohort is three years old. "Churn has been flat across cohorts" is encouraging, but it says nothing about years 4 through 10. Construction is also cyclical, and three years doesn't span a downturn. Sensitivity:

| Horizon | LTV (contribution basis) | LTV / $24,333 |
|---|---|---|
| Uncapped (10-yr avg life) | $103,600 | 4.3x |
| 5-year cap | $42,400 | 1.7x |

The expected value lies somewhere between these rows, and the NRR expansion the plan excludes pushes it upward. The honest framing is: "4.3x if observed churn holds; we have 3 years of evidence that it does."

**Problem 3: the customer counts don't reconcile with the churn rate.** The plan says it went from 90 to 150 customers while signing 60 new ones. That implies roughly zero churn last year. At 10% churn, about 9 of the 90 should have left, for an ending count of about 141. Something doesn't tie out. The possibilities:

- More than 60 customers were signed.
- Churn was lower last year than 10%.
- The 10% is measured differently, for example on renewals due rather than on the starting base.

A Series A diligence team will catch this immediately, so fix it before they do.

## Contribution Margin Assessment

This is the most important section. The plan's own numbers contradict its "fixed overhead" claim.

**Customer success is variable by construction.** "Each CSM owns about 25 accounts" is a variable-cost ratio. Six CSMs × 25 = 150 accounts, so the team is at capacity today. At 600 customers that ratio requires 24 CSMs, costing **$2.64M** a year rather than $660K.

**Implementation is variable and also at capacity.** Last year's load was 60 customers × 3 weeks = 180 specialist-weeks. The team has roughly 190–200 working weeks available (4 specialists × 48–50 weeks). It is around 90–95% utilized. Year three needs roughly 260 implementations, or about 17–18 specialists at about **$2.4M** a year.

**Contribution margin per customer:**

| | Per month | % of revenue |
|---|---|---|
| Revenue | $1,500 | 100% |
| Cost of revenue (hosting, data license, processing) | ($270) | 18% |
| **Gross profit** | **$1,230** | **82%** |
| Customer success ($4,400/yr) | ($367) | 24% |
| **Contribution margin** | **$863** | **58%** |
| Implementation (one-time) | $9,333 per customer | treated as acquisition cost above |

Payment processing and the per-customer data license are already in cost of revenue, which is correct.

**What this does to the operating-leverage thesis.** The plan says CS plus implementation falls from 45% of revenue to 11% at 600 customers, and calls this "most of the path" to 25% EBITDA. At the current ratios:

| Year 3 at current ratios | Annual cost |
|---|---|
| CS (24 CSMs) | ~$2.64M |
| Implementation (~17–18 specialists) | ~$2.4M |
| **Total** | **~$5.0M, about 47% of $10.8M run-rate revenue** |

The leverage is essentially zero. The ratio stays flat rather than falling by 34 points. The real levers are productivity improvements, which are worth modeling explicitly:

- **More accounts per CSM.** Monthly job-review calls are high-touch, and pooled or tech-touch CS for smaller accounts is plausible. At 40 accounts per CSM, CS falls to about $1.65M and the combined ratio to about 38%.
- **Shorter implementation.** The two planned ERP integrations could plausibly cut the "connect accounting system" step. If they halve implementation time, that is a real and demonstrable lever. It should be claimed as one.
- **Charging an implementation fee.** Many construction-software vendors do. Even $5,000 would recover over half of the $9,333 per-customer cost.

Each of these is a better story than "fixed overhead," because each is defensible.

**Accounting note.** Many SaaS companies report implementation, and often CS, in cost of revenue. If a diligence team reclassifies CS alone, gross margin goes from 82% to about 58%. If they also reclassify implementation, it falls to roughly 37% on today's numbers. Get ahead of this by presenting both views.

## Payback Period Assessment

**Stated:** $15,000 / $1,230 = 12.2 months.

**Re-costed** on a contribution basis, with implementation in acquisition cost:

| Scenario | Payback |
|---|---|
| Blended, today: $24,333 / $863 | **28 months** |
| Outbound, today: $26,833 / $863 | 31 months |
| Outbound, year 3 (CAC +10%/yr) | ~38 months |

**Benchmarks.** Against the usual SaaS rule of thumb (about 12 months healthy, 18–24 acceptable, over 24 problematic), the re-costed figure is problematic, and it gets worse as outbound becomes the dominant channel.

This is not the worst-case pattern of long payback combined with short lifetime. Observed churn implies most customers survive well past 28 months: about 76% of a cohort remains at month 30. Cumulative per-customer cash does turn positive within the window you have data for. But the "top quartile, 12-month payback" claim does not survive.

**Cash payback may be much better, and the plan doesn't say.** Contracts are annual. If customers prepay annually, the business collects $18,000 at or near signing. That alone covers most of the $24,333 acquisition cost, and cash payback could be under a year even on fully loaded costs. If this is true, it is the plan's strongest capital-efficiency argument and it is missing. State the billing terms. If you bill monthly, consider offering an annual-prepay discount.

**The funding ask doesn't cover the headcount the plan implies.** The $14M allocation has no line for CS or implementation hiring, because the model assumes those teams don't grow.

On the growth path above, the extra cost of CS and implementation beyond the flat $1.22M a year is roughly $6M over three years. That is about 40% of the raise, before any productivity gains. Growth at about 59% a year also means several cohorts of unrecovered acquisition cost are outstanding at once.

The plan should rebuild the cash model with these teams scaling, and then check whether $14M reaches the milestone the Series B will be priced on.

## Gross-Margin Trajectory Assessment

This lens is in good shape. The projection of 81–83% is close to flat, and the levers are specific and credible:

- **Costs track revenue.** Hosting scales with projects, and so does pricing, so margin per project holds as customers expand.
- **The data license gains leverage from expansion.** It is priced per customer while revenue grows per project. NRR-driven expansion therefore improves margin modestly, a lever the plan understates.
- **The volume discount is upside.** It is worth about a point at 400 customers and is left out of the base case. That is appropriately conservative.
- **The track record is real.** Six quarters of stability within a point is actual evidence, not a projection.

**Compression vectors worth acknowledging:**

- **ERP integration costs.** Integrations with the two largest construction ERPs sometimes carry partner-program fees or per-customer connector costs. If so, they land in cost of revenue.
- **The owner-facing reporting module.** If it adds users from outside the customer, such as owners and their reps, hosting and support load may grow faster than per-project revenue.
- **Price pressure.** Per-project pricing at $1,500/month invites negotiation as larger contractors arrive at the top of the $50M–$400M range. Larger accounts mean more projects but also more leverage over price.

The one trajectory risk that matters is the CS and implementation reclassification described above. That is a question of how margin is presented rather than a cost trend, but it is the one diligence will focus on.

## Factual Foundation

No fact-check report was provided. These three numerical claims would benefit most from verification:

1. **"Top quartile of vertical SaaS" on 12-month payback and near-10x LTV/CAC.** The comparison only holds if comp-set figures are computed the same way, and many published benchmarks include CS in the calculation. Check the benchmark's definitions before citing it.
2. **10% annual logo churn as a credible steady state** for mid-market contractor software. This figure carries most of the LTV and I haven't verified it against comparable construction-tech or vertical-SaaS cohorts. It also needs to be reconciled internally with the 90 → 150 customer count.
3. **Outbound CAC inflation of 10% a year.** This is based on one year of observation. Verify it against mid-market vertical-SaaS sales-efficiency data, especially for the period after the founder's network is exhausted.

## Overall Assessment

**Strongest lens: gross-margin trajectory, with retention a close second.** The margin claims are conservative and evidenced. NRR comes from a structural per-project mechanism rather than hoped-for upsell. Three years of flat cohort churn is more evidence than most Series A companies have.

**Weakest lens: contribution margin.** The 25-accounts-per-CSM ratio and a fully utilized implementation team make "fixed overhead" untenable. That one classification inflates every downstream figure: payback, LTV/CAC, the year-three operating leverage and, implicitly, the size of the raise.

**The most important revision:** re-cost CS ($4,400 per customer per year) and implementation ($9,333 per new customer) as variable, and rebuild the model with three things:

- Contribution-basis LTV/CAC (about 4.3x) and payback (about 28 months).
- Billing terms and cash payback stated explicitly.
- Named productivity levers in place of fixed overhead: CSM ratio, faster implementation via the ERP integrations, and an implementation fee.

A plan that says "4x LTV/CAC today, with a credible path to 6x through measurable onboarding and CS efficiency" is more defensible than a 10x claim diligence will dismantle in the first meeting. The underlying business, with sticky customers, structural expansion and stable 82% gross margin, is good enough that it doesn't need the inflated version.

*Out of scope, noted for the sibling critiques:*
- **Market sizing.** Whether 600 customers is reachable within the count of US commercial GCs doing $50M–$400M a year.
- **Moat.** Competitive pricing pressure from larger construction-platform incumbents on per-project pricing.
