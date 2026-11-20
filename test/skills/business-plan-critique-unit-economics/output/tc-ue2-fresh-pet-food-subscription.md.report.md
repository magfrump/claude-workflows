⚠️ **No fact-check report provided.** This critique does not include independent factual
verification. Checkable numerical claims in the draft (quoted CAC, churn rates, gross-margin
benchmarks, pricing comps) have not been assessed. For full verification, run the
`fact-check` skill first or use the `draft-review` orchestrator.

# Unit-Economics Critique: Kibble & Co. Series A Narrative

## CAC Assessment

**This is the strongest section of the plan.** CAC is broken out by channel, the definition is mostly fully loaded (creative, agency fees, and the free first box are included), and the paid-social number comes with four quarters of history at tripled spend. Most Series A plans give less than this.

Three things still need attention:

- **The blended $180 is not the marginal CAC. $210 is.** The raise puts most new spend into paid social, so the blended figure will move toward $210 as the referral (600 subs at $105) and influencer (900 at $160) channels shrink as a share of adds. Every return calculation that justifies the raise should use $210, not $180. The plan quotes $210 in Use of Funds but builds the headline ratio on $180.
- **"Fully loaded" excludes people costs.** The $1.5M team line includes growth marketing. Those salaries are acquisition cost, and they are not in the $180. This is a small adjustment per subscriber, but the CAC is understated by that amount.
- **The flat-CAC evidence is real but only partly carries over.** Stable CAC from about $50K to $150K a month in a familiar Northeast/Mid-Atlantic audience is good evidence. It does not show what happens from $150K to $400K, or in Southeast audiences with no brand awareness, no referral density, and three-day shipping until the second co-packer is live. I'd treat $210 as a floor for the new spend and model a sensitivity case at $250–275.

**Internal consistency flag (important):** the growth, churn, and gross-add figures don't reconcile.

- At 9% month-over-month growth, the base went from about 8,800 to 11,400 last quarter. That is roughly 2,600 net adds.
- The plan reports 3,600 gross adds. That implies only about 1,000 churned subscribers over roughly 28,900 subscriber-months, or about **3.5% monthly churn, not 6%**.
- At 6% churn, reaching 11,400 would have required roughly 4,400 gross adds.

So one of three things is true:
1. Churn on the active base is lower than stated.
2. Growth was below 9% last quarter.
3. Roughly 800 subscribers a quarter arrived through an unlisted organic channel. In that case the CAC table is incomplete, and blended CAC is overstated, not understated.

Investors will run this arithmetic. Reconcile it before they do.

## LTV Assessment

**This is the headline finding. The LTV is computed on revenue, not contribution.**

- **As stated:** $62 ÷ 6% = $1,033. That is lifetime *revenue* per subscriber.
- **Contribution-weighted:** $23.56 ÷ 6% = **$393**.

The plan's own gross-margin section supplies the $23.56. Using revenue overstates LTV by 1/0.38, which is about 2.6x.

Corrected ratios:

| | LTV (contribution) | CAC | LTV/CAC |
|---|---|---|---|
| As stated (revenue basis) | $1,033 | $180 | 5.7x |
| Blended, corrected | $393 | $180 | **2.2x** |
| Paid social, corrected | $393 | $210 | **1.9x** |

The 3x threshold the plan cites is conventionally applied to margin-weighted LTV. On that basis Kibble & Co. sits below it overall, and well below it on the channel the raise funds.

The sentence "every dollar we put into paid social comes back almost six times over" should become roughly this: each paid-social dollar returns about $1.87 of gross contribution over about 17 months, before fixed costs.

**Retention inputs:**

- **The churn description contradicts itself.** "6% held for every monthly cohort since launch" (a flat per-cohort curve) cannot coexist with "most churn happens in the first two boxes; box-four survivors churn under 3%" (a steeply front-loaded curve). My best guess is that 6% is blended active-base churn. With 9% monthly growth, that base is dominated by subscribers in their first three months.
- **That is probably upside.** Suppose early boxes churn about 12% and survivors churn about 3%. Expected lifetime would then be about 25 months rather than 16.7, and contribution LTV about $600. Paid-social LTV/CAC would be about 2.8x. That is far more fundable than 1.9x, and the plan currently doesn't claim it.
- **It needs evidence.** The cohorts are at most 14 months old, so the "<3% after box four" figure rests on a thin tail. Present actual cohort survival curves instead of a single rate.
- **Free-box takers.** Confirm whether people who take the free first box and never pay are counted in churn, or simply excluded from the subscriber count. If they're excluded, the free box should be in CAC (it appears to be), and the paid-subscriber curve is the right basis. Say so explicitly.
- **Channel-specific retention.** Paid-social subscribers commonly churn faster than referral subscribers. If the 6% blends a referral-heavy early base, paid-social LTV may be lower than $393. Break churn out by acquisition channel.
- **No expansion assumed.** This is appropriate. There is no seat or usage mechanism here beyond adding a second dog or upsizing portions.

## Contribution Margin Assessment

The 38% gross margin is unusually complete for a draft. It already includes cold-chain shipping and payment processing, two costs that plans often omit. The $23.56 is exactly 38% of $62, so the plan is treating gross margin as contribution margin.

Costs that scale with subscriber count but appear to sit outside the 38%:

- **Customer care.** It's in the team budget as overhead. For a perishable, every-four-weeks product, contacts per subscriber (delivery problems, skips, recipe changes, pausing) are meaningful and grow linearly with the base.
- **Spoilage and replacement boxes.** Thawed dry-ice shipments, carrier delays, and reships are a per-box cost. They'll likely rise in the Southeast before the second co-packer is live, when transit takes three days.
- **Referral "get $20" credits.** These should be inside the $105 referral CAC. Confirm they aren't instead netted against revenue or ignored.
- **Retention discounts and save offers,** if any are used to hold subscribers through the high-churn early boxes.

These are illustrative and unverified, but if these items run 3–5 points of revenue, contribution falls to roughly $20.50–21.70 a month. Paid-social LTV/CAC would then drop from 1.9x to about **1.6–1.7x** on the stated churn. Itemize these costs per subscriber, even as estimates.

## Payback Period Assessment

The plan's 7.6 months is a simple payback: CAC divided by monthly contribution. It ignores the fact that subscribers churn during the payback window.

**Cohort payback at 6% monthly churn** (months until the expected cumulative contribution of a cohort equals CAC):

| | Simple payback | Churn-adjusted payback |
|---|---|---|
| Blended ($180) | 7.6 mo | **~9.9 mo** |
| Paid social ($210) | 8.9 mo | **~12.4 mo** |

Average lifetime is 16.7 months. A 12.4-month churn-adjusted payback on the marginal channel therefore leaves a thin window of profit per subscriber. Consumer subscription businesses typically aim for payback under about 6 months, so this is on the slow side for the category. The front-loaded churn reading in the LTV section would shorten it somewhat, but only once the evidence supports that reading.

**Working-capital intensity:**

- At full spend (about 1,900 paid-social adds a month at $400K), each monthly cohort needs about a year to recover its CAC.
- At any moment, roughly 12 months of cohorts are partly unrecovered. Peak unrecovered acquisition spend is therefore on the order of **$2.5–3M**, before fixed costs and before inventory for a second co-packer.
- Frozen inventory and co-packer minimums add working capital that a pure-software business wouldn't carry.

The $7.0M acquisition line and $1.0M buffer may be sufficient. However, the plan sizes the raise on a 7.6-month payback and a 5.7x ratio, not on this interaction between growth and payback. Rebuild the cash model with churn-adjusted cohort payback at $210 or higher.

## Gross-Margin Trajectory Assessment

**Credit where it's due:** the plan explicitly does not project margin expansion. Most consumer plans draw an unsupported line from 38% up to 50%, and this one avoids that.

The risk here is **compression**, which the plan doesn't address:

- **The co-packer price lock expires "through next year."** The Series A will be deployed past that date. Renegotiation happens with Kibble & Co. more dependent on that co-packer than it is today.
- **The second co-packer's pricing is unstated.** "About delivery times and redundancy, not cost" leaves open the possibility that it costs *more*. New partners at low initial volume rarely match an incumbent's rate.
- **Ingredient prices.** Four flat quarters is an observation, not a forecast. Protein input costs are historically volatile. This is a general claim I haven't verified for this product's ingredient mix.
- **Cold-chain shipping.** Carrier rates and dry-ice costs tend to rise over time, and longer Southeast lanes before the second co-packer opens will cost more per box.
- **Pricing pressure.** Scaling paid social into colder audiences often requires deeper first-box offers or ongoing discounts, which erode effective average order value.

With LTV/CAC already near 1.9x on the marginal channel, a 2–3 point margin decline matters. Each point of gross margin is worth about $10 of contribution LTV. Add a downside case covering co-packer repricing and shipping cost increases.

## Factual Foundation

No fact-check report was provided. The three claims most worth verifying:

1. **The 3x LTV/CAC benchmark for subscription consumer businesses,** and specifically whether comps calculate it on contribution-weighted LTV. If they do, the plan's 5.7x isn't comparable to it.
2. **6% monthly churn against the fresh-pet-food subscription comp set,** and whether comps report blended or cohort churn.
3. **Paid-social CAC stability across a 3x spend increase.** This is the main empirical support for the raise. Check it against ad-platform data, not just the summary table.

## Overall Assessment

**Strongest lens: CAC.** It is channel-decomposed, mostly fully loaded, and backed by real scaling evidence. The gross-margin section is similarly honest.

**Weakest lens: LTV.** Computing it on revenue inflates the headline ratio from about 1.9–2.2x to 5.7x, and the whole raise is argued from that number. The churn figures also contradict each other and don't reconcile with the growth and gross-add data.

The underlying business may well be fundable. If the "under 3% after box four" retention holds, contribution LTV could be about $600, and paid-social LTV/CAC about 2.8x. That is a defensible story, and the plan doesn't currently tell it.

**The single most important revision:** restate LTV on a contribution basis, built from actual cohort survival curves broken out by acquisition channel. Then reconcile churn with the 9% growth and 3,600 gross adds, and re-size the raise using churn-adjusted payback at the marginal $210 CAC. Investors will make the $1,033 → $393 correction in the first meeting. It is far better for the narrative to make it first and then show the retention data that earns the ratio back.
