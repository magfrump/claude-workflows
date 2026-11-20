⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable numerical claims in the draft (quoted CAC, churn rates, gross-margin benchmarks, pricing comps) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Unit-Economics Critique: ChairTime Seed Round Memo

## CAC Assessment

**The memo's own numbers show the $1,500 CAC is a blend of two very different channels, and the plan funds itself on the cheap one while acquiring through the expensive one.**

You can decompose it from the memo:

| Channel | Practices | Spend | CAC |
|---|---|---|---|
| Study club / alumni network | 100 | 100 × $150 = $15,000 | **$150** |
| Paid search + trade shows (+ AE share) | 40 | $210,000 − $15,000 = $195,000 | **$4,875** |
| Blended | 140 | $210,000 | $1,500 |

The memo says the network is exhausted and about 80% of the next 900 practices will come from paid channels. The forward blended CAC on that mix is therefore:

- 0.8 × $4,875 + 0.2 × $150 ≈ **$3,930 per practice**, about 2.6× the modeled figure.
- That assumes the remaining 20% still arrive at referral-credit cost. The memo calls the network "either a customer or has declined," so that 20% probably depends on referrals from existing customers. That may hold, but it is not the channel that produced the historical $150 number.

$3,930 is probably still a floor:

- **Paid CAC at scale will rise, not stay flat.** The $4,875 comes from 40 practices acquired through regional trade shows and early paid search. The plan moves to the national trade-show circuit (more expensive booths, lower density of warm prospects) and higher search volume (less efficient keywords). Both push marginal CAC up.
- **The outbound team has no cost history.** Two new outbound hires calling practices in four states is a new channel with no observed conversion rate. Its CAC is unknown, and the $4,875 paid figure doesn't measure it.
- **"Fully loaded" omits founder selling time.** The network practices came "typically after a colleague demonstrated the product at a study-club meeting," which Dr. Patel attended and championed. Her time is real acquisition labor. It doesn't change the paid-channel math, but the $150 network CAC understates what those customers actually cost.

The memo is commendably transparent about the spend breakdown and the channel mix. The problem is that the model doesn't use the decomposition the memo itself provides.

## LTV Assessment

The LTV calculation is mechanically sound and correctly margin-weighted:

- $240/month × (1 / 0.015) ≈ $240 × 66.7 months ≈ **$16,000**
- No expansion is assumed (single $300 plan, no price increase). That is conservative and appreciated.

The load-bearing input is the 1.5% monthly churn:

- **Annual retention.** 1.5% monthly implies about 83% annual logo retention (0.985¹² ≈ 0.834). That is a strong but not implausible figure for SMB vertical SaaS embedded in a workflow.
- **Extrapolation.** The 67-month lifetime runs more than 3× past the oldest observed cohort (20 months), and most cohorts are younger. The plan is honest that churn is measured "across every cohort since launch." Even so, a 5.6-year expected lifetime is an extrapolation, not an observation. The model also applies no discount rate.
- **Channel mix of the observed churn.** About 71% of the measured base came through a trusted peer demo in the founder's own professional circle. Peer-referred customers typically retain better than paid-search customers, who arrived with less context and less social commitment. The paid cohort is only 40 practices, too small to separate its churn from the blend. The forward plan is 80% paid-acquired, so the relevant churn number is the one the memo can't yet measure.
- **Structural churn specific to dentistry.** Independent practices get sold, merge, or are acquired by DSOs. Those events churn the account regardless of product satisfaction, and they are probably under-represented in a 20-month window.

**Sensitivity for paid-acquired practices:**

| Monthly churn | Lifetime | LTV | LTV/CAC at $4,875 |
|---|---|---|---|
| 1.5% (as stated) | 67 mo | $16,000 | 3.3× |
| 2.5% | 40 mo | $9,600 | 2.0× |
| 3.0% | 33 mo | $8,000 | 1.6× |

Even taking the stated churn at face value, the paid-channel LTV/CAC is **3.3×, not 10.7×**. That is healthy, but it is a different company from the one the memo describes. If paid cohorts churn at 2.5%, which I haven't benchmarked, the ratio falls to about 2×.

## Contribution Margin Assessment

The memo does something most seed plans don't: it puts support and onboarding into gross margin explicitly because "its workload grows with practice count." That is the right treatment.

**The stated 80% margin is hard to reconcile with what's included in it.** Here is the check:

- **Total COGS budget.** Monthly revenue is 140 × $300 = $42,000. At 80% gross margin, total COGS is about $8,400/month, or roughly $100,800/year.
- **Card processing.** At ~3%, that is about $1,260/month.
- **What remains.** About $7,100/month (~$86K/year) must cover hosting, SMS, per-location integration fees, **and** two full support salaries.

Two fully loaded support/onboarding employees typically cost well over $86K/year combined, before any infrastructure or integration fees. Possible explanations:

1. Support is only partly allocated to COGS (e.g., a share of founder or engineer time, or part-time staff).
2. Salaries are well below market and will reset as the team grows.
3. The 80% margin was computed before support was added, or on a different revenue base.

I can't tell which from the memo, and the inference depends on loaded-cost assumptions I haven't verified. It needs resolving, though, because it moves every downstream number. If fully loaded support costs push today's true gross margin to around 60–65%, contribution per practice falls from $240 to roughly $180–195/month.

**At scale.** Going from 140 to ~1,040 practices is a 7.4× increase in accounts. Support won't scale perfectly linearly; a mature team handles more accounts per head. Still, the plan needs a stated accounts-per-support-head ratio and a hiring plan. Two more forward-looking pressures:

- **Paid customers will need more help.** Outbound- and search-acquired practices didn't see the product working in a peer's office first, so they will likely need more onboarding and support than the one-hour session that sufficed for network customers.
- **New integrations bring new costs.** Each of the two new integrations comes with its own per-location fee schedule and its own support burden. Neither is in the model.

Onboarding (one hour, remote) and the referral credit (correctly booked as CAC) look fine.

## Payback Period Assessment

The memo's 6.25-month payback is the blended network-era figure. Recomputed:

| Basis | Simple payback | Churn-adjusted payback* |
|---|---|---|
| Stated ($1,500) | 6.25 mo | ~6.5 mo |
| Forward blended ($3,930) | 16.4 mo | ~20 mo |
| Paid channel ($4,875) | 20.3 mo | **~24 mo** |

\*Churn-adjusted payback means months until expected cumulative margin from a cohort, net of 1.5% monthly churn, equals CAC. For the paid channel: 0.985ⁿ = 1 − (4,875 × 0.015 / 240) → n ≈ 24.

A ~24-month payback on a $300/month SMB product sits at the problematic end of the SaaS range (12 months healthy, 18–24 acceptable, more than 24 a concern). If the gross-margin question above resolves downward, the payback goes past 24 months.

**This breaks the plan's self-funding mechanism.** The memo says cohorts "start funding the next quarter's acquisition quickly" and that the business reaches breakeven in month 19. At a ~24-month churn-adjusted payback, **a paid cohort acquired in month 1 does not return its CAC until roughly month 24.** No paid cohort acquired during the plan window recovers its acquisition cost within that window. Acquisition has to be funded by the raise and by the existing 140-practice base, not by new cohorts.

**The budget doesn't match the target.** Reconciling the two:

- 900 practices at ~$3,930 ≈ **$3.5M** of acquisition, against a $1.35M budget. That gap alone is close to the entire $2.5M raise.
- Read the other way, $1.35M at ~$3,930 buys about **340 practices**, not 900. That ends the plan around 450–480 practices, roughly half the ~1,000 the memo identifies as breakeven.

So the funding ask is sized against a CAC the plan's own channel strategy says it won't get. The month-19 breakeven claim doesn't survive this correction.

## Gross-Margin Trajectory Assessment

The trajectory section is the most credible part of the memo. The plan claims no margin expansion, correctly identifies that SMS and integration fees scale linearly, and names its biggest compression risk (a partner fee increase, about 2 points). Investors will read that restraint well.

Compression vectors the memo doesn't name:

- **Support cost growth.** As discussed above, this is the largest unmodeled pressure if today's 80% doesn't fully load the team.
- **New integration partners.** The $0.75M buys two additional integrations. Each adds a per-location fee with unknown terms, and possibly a partner with more pricing leverage than the current one.
- **SMS carrier costs.** Carrier registration and per-message surcharges for application-to-person texting have risen in recent years and could rise further. They are worth stress-testing as a second compression line next to the integration fee.
- **Flat pricing against rising input costs.** With no price increase in the model, any rise in per-unit costs is pure compression.

There is also an upside lever the plan leaves on the table. A median of 11 recovered hygienist hours per month is a lot of recovered production for a $300 fee. The exact production value per hygienist hour is a number to verify, but it is plausibly several times the subscription. That suggests real pricing headroom. A tested price increase, or a higher tier for multi-hygienist practices, is the most credible margin and LTV lever available, and it is more credible than cost reduction. I'd model it as a scenario, not the base case, until it has been tested on new customers.

## Factual Foundation

No fact-check report was provided. The numerical claims that would most benefit from verification, in order of impact on the unit economics:

1. **The 80% gross-margin composition.** Request a line-item COGS breakdown (hosting, SMS, integration fees per location, processing, support salaries) to resolve the internal-consistency gap above. This is internal data, not a benchmark, and it matters most.
2. **Churn by acquisition channel.** Compare the 40 paid-acquired practices against the 100 network practices, even with wide error bars, and benchmark against SMB dental/healthcare SaaS logo churn. I have not verified 1.5% monthly against a comp set, and the paid-cohort figure is the one the forward model depends on.
3. **Paid-channel CAC benchmarks for dental SaaS.** Check paid-search and national trade-show costs per acquired practice to test whether $4,875 is likely to hold, rise, or fall at higher volume.

(The 8–12% lost-hygienist-hours claim and the 120,000-practice figure bear on market sizing rather than unit economics and are out of scope here.)

## Overall Assessment

**Strongest signal: retention and margin discipline.** Measured churn of 1.5% monthly across cohorts up to 20 months old is genuinely good for SMB. The memo also avoids the usual LTV inflation: no expansion revenue, no price increase, margin-weighted LTV, support counted in COGS, and an honest flat margin outlook. The product appears to retain, and the reported 11 recovered hours a month plausibly explains why.

**Weakest signal: forward CAC, and the payback and funding math built on it.** The $1,500 CAC describes a channel the memo itself says is exhausted. On the paid channels that will drive 80% of growth, the memo's own figures imply:

- CAC of about $4,900
- LTV/CAC of about 3.3×
- A churn-adjusted payback of about 24 months

That is a viable business, but not an unusually capital-efficient one. The current raise funds roughly 340 new practices, not 900.

**The single most important revision:** rebuild the model by channel. Use the observed $4,875 paid CAC (with an explicit assumption about how it moves at national scale), the forward 80/20 channel mix, and churn reported separately for paid and network cohorts. Then resize either the 24-month practice target or the raise so they agree. Resolving the gross-margin composition comes a close second, because it moves every ratio above.

A version of this memo that says "paid CAC is ~$4,900, payback is ~24 months, and here is the plan to bring it down" will be more fundable than the 10.7× version. Investors who do the decomposition above, and the memo makes it easy, will trust the numbers that remain. Pricing headroom is the most natural lever to put in that plan. A price test on new paid-channel customers could shorten payback materially without depending on cheaper acquisition.

*Out of scope:* the shift from founder-network distribution to cold paid and outbound channels in four new states is also a distribution and moat question, specifically whether the "sells itself once a dentist sees it in a peer's office" dynamic transfers without the peer. That belongs to `business-plan-critique-moat`. The 120,000-practice market claim belongs to `business-plan-critique-market-sizing`.
