⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable numerical claims in the draft (quoted CAC, churn rates, gross-margin benchmarks, pricing comps) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Unit-Economics Critique: Clearpath Seed Extension Memo

**Summary up front:** Clearpath's per-customer economics are unusually well-specified and mostly hold up. The CAC is fully loaded, the LTV is margin-weighted, support and onboarding are treated as variable, and no margin expansion is assumed. The problem is in how the raise is sized. The memo treats a 16-month payback as if it made acquisition self-funding after month 3, and it does not. With monthly billing, the plan as written runs out of cash around **month 9**, not month 18, and needs roughly **$4.8M plus buffer** rather than $3.6M. If customers actually pay annually upfront, which the memo does not say, the picture changes sharply in Clearpath's favour. That billing question is the most important open item in the memo.

---

## CAC Assessment

**What holds up.** The CAC is explicitly fully loaded (SDR/AE salaries, commission, programs, sales engineer), and the channel split reconciles: 0.4 × $19K + 0.6 × $27K = $23.8K ≈ $24K. That is better discipline than most seed memos show.

**What's load-bearing and shaky: CAC is modelled flat through a 2.5× volume increase.** The memo's justification has two parts, and neither fully covers the step from 8 to 20 customers/month.

1. **"The mix is stable."** The 40/60 mix has been stable *at 8 customers/month*. Inbound is driven by brand, content, and regulatory news, not by AE headcount, so adding 3 AEs and 2 SDRs mostly adds outbound capacity. If inbound stays at today's ~3 customers/month in absolute terms and the rest comes from outbound, the mix at 20/month is roughly 15/85. Blended CAC would then be ~$25.8K, about 8% higher before any outbound degradation.
2. **"30,000 uncontacted targets."** An untouched list shows the opportunity has not run out, but it says little about cost per win. Outbound teams usually work the best-fit accounts first, and conversion on later list segments is typically lower. (Whether 30,000 is the right addressable count is a market-sizing question; see Overall.)

**Internal inconsistency: ramp vs. start date.** The plan says the company moves to 20/month "starting next month." The risks section says new AEs take three months to ramp. During months 1–3 the company pays new-hire salaries without getting their full output, so effective CAC in that window is above $24K and customer count falls short of plan. The model should show a ramp curve, for example 8 → 12 → 16 → 20.

**Capacity check the memo should show.** The memo doesn't state current AE headcount, so I can't tell where the extra 12 customers/month come from. If they come entirely from 3 new AEs, each AE closes ~4 mid-market deals/month, or roughly $1.15M of new ARR per AE per year. That may be achievable, but it is high enough that the memo should show current per-AE productivity to support it. I haven't verified this against mid-market quota benchmarks.

**Sensitivity:** each 10% rise in CAC adds ~1.6 months to payback and ~$48K/month to acquisition spend at 20 customers/month.

## LTV Assessment

**What holds up.** LTV is correctly margin-weighted ($1,500 contribution, not $2,000 revenue). It excludes expansion despite 103% NRR, which is conservative. The memo also labels the result an upper bound, which is honest. Churn measured across two full renewal cycles is a reasonable cohort age for annual contracts.

**What to tighten:**

- **The $200K figure assumes about an 11-year average lifetime (1/0.09).** It is better to show a horizon-capped figure next to it. Over a 5-year horizon at 9% annual churn, LTV ≈ $18K × (1 − 0.91⁵)/0.09 ≈ **$75K**, giving **LTV/CAC ≈ 3.1×**. That is still healthy, and it is the number a skeptical investor will compute anyway.
- **New cohorts may not churn like old ones.** The 9% comes from the first 120 customers. Many were probably inbound and early adopters, the kind most motivated to replace law-firm newsletters. The plan shifts acquisition toward outbound. Outbound-sourced customers often churn at higher rates. The memo can test this directly with its own data: report churn by acquisition channel.
- **The stated churn driver is cyclical and possibly correlated with a named risk.** If most churn comes from customers being acquired, the churn rate will move with the M&A cycle. Acquirers that are larger companies are also the ones most likely to run a large HRIS vendor with bundled compliance, so this driver overlaps with the bundling risk.
- **Implied expansion needs a mechanism.** 9% logo churn plus 103% NRR implies roughly 12% annual expansion among retained customers, assuming churned accounts are average size. Is pricing tied to employee count or jurisdiction count? If so, expansion is structural: customers grow into new states and cities. The memo should say so, because a structural mechanism is much stronger evidence than "we upsell."

**Calibration:** I consider 9% annual logo churn credible for a system-of-record compliance product with two renewal cycles behind it. However, I haven't verified it against comparable companies, and the LTV figure depends heavily on it.

## Contribution Margin Assessment

**What holds up.** This is the strongest section of the memo. Hosting, per-customer content licenses, payment fees, and support/onboarding are all treated as variable and allocated per customer. That covers almost every item that usually gets hidden in "fixed costs."

**Remaining gaps:**

- **Onboarding is front-loaded, and the customer base is about to become mostly new.** If the 75% is an average across a mature 120-customer base, it understates onboarding cost in a year when the base grows from 120 to 480. At month 18, three-quarters of customers will be under 18 months old. First-year contribution per customer is likely below 75%. The model should split onboarding out as a one-time cost per new customer, which would also lengthen payback.
- **Some fixed costs may behave semi-variably at 4× customers.** The $250K fixed base (engineering flat at nine, legal content team) has to absorb 4× the customers, more HRIS integrations, and jurisdiction-coverage expansion. That is not a contribution-margin issue as such, but the "fixed burn" line could drift upward late in the plan.
- **Content license renewal falls just after the plan horizon.** The contract renews at ~month 24, when Clearpath will have 4× its current customer count. Larger volume may help in negotiation. But if the licensor prices on the value delivered, renewal could go the other way. If license cost moved contribution margin from 75% to 65%, contribution would fall to $1,300/month and payback would stretch to ~18.5 months.

**Net:** I'd estimate a realistic first-year contribution margin for new customers somewhat below 75%, with steady-state margin close to the stated figure. This does not change whether the per-customer economics work. It does make the cash shortfall below somewhat worse.

## Payback Period Assessment

**The per-customer number is correct:** $24,000 / $1,500 = 16 months. It sits at the healthier end of the 18–24 month range the memo cites, though I haven't verified that range. Survival to payback is ~0.91^(16/12) ≈ **88%**, so about 1 in 8 customers churns before paying back. "Almost every" slightly overstates this, but it is not a material problem.

**The raise-sizing logic is the critical error.** The memo states that "because each customer pays back its CAC in 16 months, from the fourth month onward acquisition is funded by contribution from the customers we have already signed." A 16-month payback means each cohort takes 16 months to recover its own CAC. So a customer signed in month 1 has repaid only $1,500 of its $24K by month 2, and none of month 4's $480K acquisition spend can come from recovered CAC. Acquisition only funds itself once monthly contribution from new customers exceeds monthly acquisition spend.

**Rebuilt cash model.** Assumptions: monthly billing, CAC expensed in the month of signing, new customers contribute from their signing month, 20/month from month 1 (optimistic given the ramp), existing base flat.

- Monthly cash flow (in $K) = −70 fixed gap − 480 acquisition + 30 × (month number)

| Month | New customers to date | Monthly net cash flow | Cumulative cash used |
|---|---|---|---|
| 3 | 60 | −$460K | −$1.47M |
| 6 | 120 | −$370K | −$2.67M |
| **9** | **180** | **−$280K** | **−$3.60M ← $0.6M + $3.0M exhausted** |
| 12 | 240 | −$190K | −$4.26M |
| 18 | 360 | −$10K | −$4.77M |

- **Cash runs out at the end of month 9**, at ~300 total customers.
- **Monthly cash-flow breakeven arrives around month 19**, not month 12. I can't reproduce the memo's month-12 figure from its stated inputs.
- **Peak funding requirement is ≈ $4.8M**, before the buffer and before ramp slippage or the onboarding effect above. Against $3.6M available, the gap is roughly **$1.2–1.5M**.
- **Working-capital intuition:** at a steady 20/month with 16-month payback, about **$4.1M** of CAC is unrecovered at any moment. That is more than the entire raise, and the memo should state it plainly.

**What $3.6M actually supports.** Holding everything else constant, $3.6M funds about **12 new customers/month for 18 months** while keeping the $0.3M buffer. That is a 50% increase over today's 8/month, not 150%.

**The billing question that could change all of this.** Contracts are annual, but the memo models cash monthly. If customers pay annually upfront, each new customer brings ~$18K of first-year contribution at signing. That covers ~75% of CAC immediately, and year-2 renewals start arriving in month 13. Under that structure, my rough estimate is that the 20/month plan needs only about $1.5M over 18 months, and the raise would be comfortably sufficient. The memo should state its billing terms and model cash accordingly. If billing is currently monthly, offering an annual-prepay discount may be the cheapest capital available to the business.

## Gross-Margin Trajectory Assessment

**What holds up.** Projecting no margin expansion is the most credible stance available, and it removes the usual "60% → 80% with no named lever" problem. The steady-state margin case rests on current, demonstrated numbers.

**Compression vectors to acknowledge more explicitly:**

- **Content licensing renewal (~month 24).** This is already named as a risk. The memo should add a sensitivity line showing payback and LTV/CAC at 65% and 70% contribution margin.
- **Price pressure from HRIS bundling.** Even if Clearpath's city/county depth holds customers, a free state-level tool in the HRIS sets a lower price anchor and may compress renewal pricing. Whether depth is a durable defence is a moat question. The margin effect belongs here: a 10% renewal price cut at constant costs drops contribution margin to ~72%.
- **Coverage cost growth.** As jurisdictions multiply (the memo's own growth thesis), the legal content team either grows or has to cover more law per head. That cost is fixed today, but it will rise as the regulatory surface expands.
- **Customer mix.** If outbound-sourced customers skew smaller, revenue per customer falls while per-customer license and support costs stay roughly flat. Average ACV by acquisition channel would show whether this is happening.

## Factual Foundation

No fact-check report was provided. These are the claims that would most benefit from verification, in order of how much the analysis depends on them:

1. **9% annual logo churn and 103% NRR**, and how they compare with mid-market HR/compliance SaaS. The LTV figure and the "low churn" framing of payback depend on these, and they should ideally be broken down by acquisition channel.
2. **Billing terms (annual upfront vs. monthly).** This is an internal fact rather than an external claim, but it decides whether the raise is undersized by ~$1.2M or comfortably sufficient.
3. **The 18–24 month "acceptable" payback range for sales-led mid-market SaaS.** It is broadly consistent with commonly cited benchmarks but unverified here. Even if the benchmark holds, it judges per-customer efficiency, not whether this particular raise is large enough.

## Overall Assessment

**Strongest lens: contribution margin and margin trajectory.** Variable costs are honestly allocated and no expansion is assumed. The per-customer economics clearly work: even on a conservative 5-year horizon, LTV/CAC is ~3×, and payback is 16 months on a fully loaded CAC.

**Weakest lens: payback, specifically how payback was turned into a raise size.** The idea that acquisition self-funds after month 3 is not a judgment call. It is an arithmetic error, and it accounts for nearly all of the gap between the memo's 18 months of runway and the ~9 months the stated inputs support. Flat CAC through a 2.5× volume increase, plus the 3-month AE ramp, make the gap somewhat worse.

**The single most important revision:** replace the three-line raise sizing with a monthly cash model showing customer count, acquisition spend, contribution, and cumulative cash, including the AE ramp and the actual billing terms. Then choose one of three positions and state it:
- **(a)** Raise ~$5M+ to fund 20/month.
- **(b)** Keep $3.0M and plan for ~12/month, reaching 20/month once cash allows.
- **(c)** Show that annual upfront billing makes 20/month fundable on $3.0M.

Any of these is defensible. The business underneath this memo looks sound, and a corrected model will make that case more convincingly than the current one.

*Out of scope, for sibling critics:* whether city/county coverage holds up against HRIS bundling (`business-plan-critique-moat`), and whether "30,000 target companies" is the right serviceable count for 200–2,000-employee multi-jurisdiction employers (`business-plan-critique-market-sizing`). The flat-CAC assumption depends partly on the second.
