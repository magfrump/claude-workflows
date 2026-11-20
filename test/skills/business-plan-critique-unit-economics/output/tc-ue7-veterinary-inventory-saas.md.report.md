# Unit-Economics Critique: Tallypad Seed Round One-Pager

> ⚠️ **No fact-check report provided.** This critique does not include independent factual
> verification. Checkable numerical claims in the draft (quoted CAC, churn rates, gross-margin
> benchmarks, pricing comps) have not been assessed. For full verification, run the
> `fact-check` skill first or use the `draft-review` orchestrator.

This is an unusually careful one-pager. It uses fully loaded CAC broken out by channel, treats support as variable, assumes no expansion and a flat margin, and plans on marginal rather than blended CAC. The arithmetic mostly checks out. There are three findings. The LTV formula has an error that overstates LTV by about 36%, though the verdict survives it. The real load-bearing assumption is that marginal CAC stays at $1,900 while paid acquisition volume grows roughly 15x. The value case in the payback section doesn't hold for the smaller half of the stated clinic range.

## CAC Assessment

**What's reported is sound.** Blended CAC checks: 0.60 × $900 + 0.25 × $1,900 + 0.15 × $2,600 = $1,405. The figures are labeled fully loaded, and the $120 onboarding cost sits in CAC rather than being dropped. Planning on $1,900 rather than $1,405 is the right instinct.

**But $1,900 is a floor for the next clinic, not an estimate.** Look at the channel mix at the target rate:

- Today's ~8 clinics/month split into ~4.8 distributor, ~2 paid search and ~1.2 conferences.
- With the distributor channel held flat, 40/month means ~35 clinics/month from paid search and conferences, roughly 11x today's non-distributor volume.
- If the non-distributor channels keep today's mix (62.5% paid, 37.5% conferences), their blended CAC is $2,163, not $1,900. Conferences are the most expensive channel and probably the least scalable, since regional events happen on a fixed calendar.

The larger issue is paid search. Going from ~2 to ~25-35 clinics/month in a niche B2B vertical is exactly where CAC expands. The keyword set for "veterinary inventory software" is small, the buyer pool is finite, and you'll quickly move from high-intent searches into broader, lower-converting terms. The current $1,900 was measured at a volume where you are probably harvesting the best queries. I'd expect sustainable paid CAC at 15x volume to be materially higher. I can't say how much without your search-volume and conversion data, but this one number determines whether the raise works (see Payback).

A small point in the other direction: the raise model charges $1,900 for all 40 clinics, including the ~4.8 distributor clinics that cost $900. Netting that against the $2,163 mix effect gives about $80.5K/month of acquisition spend versus the modeled $76K. That is a minor change on its own. The volume-driven rise in paid CAC is the part that matters.

## LTV Assessment

**The 60-month cap is applied incorrectly.** $273 × 60 assumes every clinic survives all 60 months and then they all leave at once. That is zero churn for five years. Applying the stated 1.1% monthly churn inside the 60-month window:

- Expected paid months = (1 − 0.989⁶⁰) / 0.011 ≈ (1 − 0.515) / 0.011 ≈ **44 months**
- Capped LTV ≈ $273 × 44 ≈ **$12,000**, not $16,380
- For reference, uncapped LTV ≈ $273 × 91 ≈ $24,800, so the cap is conservative in intent. It is just computed wrong.

**The verdict survives it.** LTV/CAC is about 6.3x at $1,900, about 5.6x at $2,163, and about 4.0x even at $3,000. Lifetime value isn't the constraint on this business. Fix the number so a diligence analyst doesn't find it first.

**Inputs are otherwise honest.** Margin-weighted (yes, built on $273), no expansion (conservative), no price increase over five years (also conservative, and a real source of upside).

**Churn needs more support than it has.** 1.1% monthly is about 87.6% annual logo retention. That is good for SMB, but plausible for an integrated vertical tool that touches reordering. Two caveats:

1. **Cohort age.** The oldest cohort is 30 months. With roughly 8 adds a month, most of the 210 clinics are well under 18 months old, so the pooled 1.1% is weighted toward early tenure. Show churn by cohort age. In particular, show whether anything happens after month 12 or around contract and renewal points.
2. **Structural churn drivers the data may not show yet:**
   - *Corporate acquisition of independent clinics.* An acquired clinic typically moves to the acquirer's systems and suppliers. That churn is driven by M&A pace, not product satisfaction, and a young cohort may not have seen much of it yet. Ask how many of your churned clinics left because they were acquired.
   - *A thin ROI for small clinics.* Using your own figures, a $40K-stock clinic writing off 6% loses $2,400/year to expiry. Your subscription is $4,200/year, so expiry savings alone cannot pay for Tallypad at the low end of your range. At the midpoint ($60K, 7.5%) the subscription equals about 93% of total expiry, so near-total elimination is needed to break even. Only the high end ($80K, 9%, $7,200/year) clears it comfortably.

     Either the value comes from elsewhere (less working capital tied up in stock, fewer stockouts, staff time on ordering), or churn will concentrate in smaller clinics. Check whether your churned clinics skew small. If they do, your blended churn will worsen as paid search pulls in a broader, smaller-clinic mix than distributor referrals.

## Contribution Margin Assessment

**This is the strongest section of the plan.** The arithmetic checks: $350 − $14 − $10 − $8 − $45 = $273, which is 78%. Most early plans bury support in overhead. Yours scales it at 1 person per 120 clinics, which implies about $64.8K/year loaded per support person. That is plausible, though possibly light for US fully loaded cost.

Things that could quietly erode it:

- **Support load is front-loaded per clinic.** New clinics generate more tickets than mature ones. Tripling the base mostly with new clinics may push the effective ratio below 1:120 during the growth phase. Check ticket volume by clinic tenure.
- **The distributor fee is a concentration risk, and you've named it.** Each +$10/clinic/month costs about 2.9 margin points. The same distributor supplies 60% of new clinics and the integration you depend on, which gives it pricing leverage.
- **SMS costs.** US carrier registration and per-message surcharges have tended to rise. This is a small line, but it is variable and outside your control.
- **The 2.9% processing figure** likely omits per-transaction fixed fees and chargebacks. This is immaterial at $350/month.

Net: I'd estimate at-scale contribution margin within a few points of 78%, absent a distributor fee change. The conclusion holds.

## Payback Period Assessment

**Payback checks and is strong.** $1,900 / $273 = 7.0 months, on contribution rather than revenue, which is correct. CAC is about 0.45x ACV ($1,900 against $4,200). That is excellent for SMB vertical SaaS, where 12-18 months is common. With a ~44-month expected lifetime (or ~91 uncapped), there is no risk of the "long payback, short life" failure.

**One framing problem.** "Clinics recover the subscription cost within their first quarter" is a claim about customer ROI, not company payback, so it doesn't support the 7-month figure. As shown above, it also doesn't hold across your stated clinic range. Separate the two claims, and restate the customer ROI claim with the benefits that actually carry it.

**The raise model.** I reproduced your trough. Jumping immediately to 40/month at $1,900, with flat $90K fixed costs, gives monthly net cash of −$109K + $10.9K × (months elapsed). That crosses zero in month 11, and the cumulative low is about **−$599K at month 10**. Your number is right. Churn at 1.1% deepens it by roughly $50-60K, which fits "somewhat."

What the model is actually sensitive to:

| Marginal CAC (all 40/mo) | Monthly cash breakeven | Cumulative trough | Buffer vs $1.2M |
|---|---|---|---|
| $1,900 (plan) | ~month 11 | ~−$600K | ~$600K |
| $2,163 (today's non-distributor mix) | ~month 11 | ~−$640K* | ~$560K |
| $2,600 (conference-level) | ~month 14 | ~−$930K | ~$270K |
| $3,000 | ~month 15 | ~−$1.15M | ~$50K |

\*Including the distributor-clinic correction from the CAC section.

- **The breakpoint is a marginal CAC of about $3,000** (closer to $2,950 including churn). That is roughly 58% above your planning figure. For a 15x scale-up in paid search, a 58% CAC increase is not a tail scenario.
- **Fixed costs held flat at $90K for 18 months** while the base grows from 210 to about 930 clinics is the second sensitivity. Each +$10K/month of overhead from month 1 deepens the trough by about $115K and delays breakeven by about a month.
- **A slower ramp is not the main risk.** Staying at 8/month gives a similar trough (about −$556K) that arrives later. The buffer is really a buffer against CAC and overhead, so label it that way.

## Gross-Margin Trajectory Assessment

**Holding margin flat is the right call, and the plan is candid about it.** Most plans draw a curve. You decline to claim levers you haven't demonstrated.

**Compression vectors beyond the distributor fee:**
- Support intensity if the product grows more complex, or the customer mix shifts toward smaller, higher-touch clinics.
- Pricing pressure if distributors or practice-management vendors bundle inventory features. That is a moat question; see Out of scope below.

**Upside levers, real but unproven:**
- Moving billing to ACH (about $9/clinic, roughly 2.5 points).
- Support deflection as the product matures.
- Annual price increases, which the LTV currently excludes.

None of these belong in the base case. Listing them as upside gives investors a sense of asymmetry.

## Factual Foundation

No fact-check report was provided. These three claims would benefit most from verification:

1. **Stock levels of $40-80K and 6-9% annual expiry write-offs.** These underpin the entire value case. As shown above, they already imply weak ROI for smaller clinics.
2. **1.1% monthly logo churn.** This is internal data, but it needs a cohort-age breakdown and a churn-reason breakdown, separating acquired clinics from dissatisfied ones.
3. **The scalability of paid-search CAC**, including the size of the addressable independent-clinic pool reachable by search. This is partly a market-sizing question, but it determines the raise.

## Overall Assessment

**Strongest lens: contribution margin.** It is complete, honest, and treats support as variable. Payback is close behind. **Weakest: CAC at scale.** The plan correctly rejects blended CAC, but then treats the current paid-search figure as constant across a ~15x volume increase. The LTV formula error is the most obvious mistake, but it doesn't change the conclusion.

**The single most important revision:** replace the flat $1,900 with a rising marginal-CAC curve for paid search and conferences. Then show investors the breakpoint: *"the $1.2M survives marginal CAC up to about $3,000."* That turns your strongest asset, a credible and conservative model, into an explicit and testable claim. It also tells you which metric to watch monthly after the raise. Alongside it, fix the LTV to about $12K and restate the customer ROI claim on the benefits that carry it. The underlying business looks genuinely capital-efficient. The fix is to show that efficiency holds as you scale.
