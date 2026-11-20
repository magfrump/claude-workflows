> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Market-Sizing Critique: Trussline Series A Memo

## TAM Definition Assessment

**Verdict:** Plausible
**Confidence:** Medium

The TAM is built bottom-up (contractor count × ACV), and the method is disclosed. That is better than a borrowed category total, and it avoids the usual adjacency creep. The memo deliberately sets TAM equal to SAM ($756M) and says it will not sell outside the $10M–$250M band during the plan period. That keeps the number honest, but it causes three problems.

- **No reconciliation is possible.** With no top-down figure, nothing cross-checks the bottom-up build. The whole ceiling rests on two unsourced inputs: the 45,000 contractor count ("Census and industry-association data") and the 60% software-adoption rate. Census counts establishments, not firms, and revenue-band data for general contractors is coarse. I have not verified either number, and both are load-bearing.
- **The true TAM is hidden.** The 18,000 contractors with no software are excluded from SAM because their sales cycle is longer. That is a reasonable SAM decision. But they are still TAM. Collapsing the two removes the investor's view of what happens after the migration wave, when Trussline will need to sell to non-software contractors or move up-band.
- **The ACV may be under-priced relative to the value claimed.** The memo says unbilled change orders found in the first 90 days averaged 1.8% of contract value. Suppose "contract value" means project value. A contractor with $50M in annual revenue would then recover something on the order of $900K a year, against a $28K subscription. If that holds, TAM is constrained by pricing, not demand, and the TAM could be materially larger. If "contract value" means something narrower, the memo should say so. Either way, this ambiguity sits directly on the ACV line that multiplies into TAM.

**Gap:** headline TAM is $756M. The realistic ceiling is plausibly in the same range, but the plan's own data suggests it could be higher on price and lower on contractor count. It cannot be bounded without sourcing the 45,000 and 60% figures.

## SAM Realism Assessment

**Verdict:** Plausible
**Confidence:** Medium

The plan's strength is that SAM uses a behavioral filter ("already pays for PM or estimating software"), not just firmographics. Most plans don't do this. Contractors are counted at the buying organization, not per superintendent or user, so buyer-vs-user inflation is avoided. Regulatory and certification gates are not a meaningful issue for this buyer. Four problems remain.

- **The behavioral filter is broader than the trigger.** "Pays for PM *or estimating* software" includes contractors happily on modern cloud PM tools, who are hard to displace. The sharper behavioral segment is contractors on Keystone/Brickwell on-prem with expiring support. That is the segment the "why now" actually activates. The plan says these two vendors hold "most of the installed base," but it never sizes this segment. It should be the core SAM figure.
- **ACV is likely mis-matched to the band's size distribution.** The $28K average comes from 71 customers concentrated in two states. Contractor revenue distributions are heavily right-skewed, so most of the 45,000 likely sit at the low end of a $10M–$250M band. If the 71 customers skew toward larger contractors, $28K overstates ACV across the population. The memo should show ACV by customer revenue tier and weight it to the band's actual distribution. Software adoption probably also rises with size, which partly offsets this, but the plan doesn't show either effect.
- **SAM is national, but the go-to-market is regional.** SAM counts all 27,000 contractors, while the beachhead is Colorado and Utah and the expansion path ends at Texas and the Southeast. The Northeast, Midwest, and West Coast are not in the plan. Those regions belong in SAM over the long run but not in the plan-period serviceable market. This matters most under SOM (below).
- **The excluded 40% is a sound call.** It should be stated as a sequencing decision ("not in plan period"), not as a property of the market.

**Estimated contraction:** restricting to the trigger-activated segment (Keystone/Brickwell on-prem users) in the reachable regions plausibly cuts the plan-period SAM to a fraction of $756M. I can't size this without installed-base data, which is the memo's biggest missing number.

## SOM Achievability Assessment

**Verdict:** Inflated
**Confidence:** Medium

**Implied share.** $38M ÷ $28K ≈ 1,350 customers, which is 5% of the 27,000-contractor SAM. The memo calls this "deliberately conservative," but only by comparing against comp ARR (see Comparable Benchmarks). As a share of SAM, 5% in five years is aggressive for B2B SaaS. Roughly 1% is a strong outcome, and more than 5% usually requires a disruptive event. The plan does have a candidate disruption (the forced migration), so 5% is arguable. "Conservative" is not.

**Share of the reachable market is much higher than 5%.** The rough illustration below uses state population as a proxy for contractor distribution. That is my assumption, not the memo's, and I hold it with low confidence.

| Reachable footprint by year 5 | Approx. share of US | Contractors in SAM | 1,350 customers as % |
|---|---|---|---|
| Colorado + Utah | ~3% | ~760 | (already ~58, ≈ 8%) |
| Mountain West + Texas | ~16–17% | ~4,400 | ~30% |
| + Southeast | ~36–37% | ~9,800 | ~14% |

So the plan implies 14–30% of its reachable segment in five years, not 5%. That needs a structural explanation, and the memo hasn't given one. The beachhead data is genuinely encouraging: roughly 8% penetration in Colorado and Utah, if my proxy is close. But that penetration came with founder relationships and local association referrals that won't travel to Texas or the Southeast.

**Sales capacity is not the bottleneck, but the math is inconsistent.** At 3.5 closes per rep per month (42 per year), 1,279 net new customers needs roughly 30 fully productive rep-years. Twelve reps productive through years 2–3 plus 22 reps through years 4–5 yields about 85 rep-years, or roughly 3,500 closes. That is well over twice what the plan needs. Two readings are possible:

- The plan's arithmetic for "22 reps" isn't shown and may embed unstated discounts.
- More likely, the 3.5 per month figure is a beachhead number, earned with founder networks and association referrals, and the memo is quietly relying on it not holding outside Colorado and Utah.

The load-bearing assumption is out-of-region rep productivity. No churn assumption appears either, so 1,350 is presumably net. The plan should state gross adds and churn separately.

**Competitive density is unaddressed.** The memo names the legacy incumbents being forced to migrate, but no current cloud competitor contesting the same migration wave. In the real US market, established cloud construction-PM platforms already target mid-size contractors. I haven't verified their positioning in this exact band. Capturing 14–30% of a regional segment while other vendors chase the same deadline needs a stated win-rate assumption.

**Most constraining bottleneck:** share of the reachable segment, combined with timing (below). Rep count is not the binding constraint.

## Market Timing Assessment

**Verdict:** Plausible
**Confidence:** Medium

This is the memo's best-argued lens. It names a specific, recent, datable trigger (2025 end-of-support announcements, effective end of 2026), not a decade-long trend. It also identifies a price-curve crossing: the migration offer costs roughly twice the old maintenance price. Five issues need addressing.

- **The window is closing now.** As of today (November 2026), the end-of-support date is about six weeks away. Many affected contractors will already have decided, renewed, or signed a migration contract during 2025–26. Series A reps hired after the raise won't be fully ramped until mid-to-late 2027, after the deadline. The plan's heaviest customer acquisition (years 4–5, with 22 reps) lands years after the trigger. The trigger and the capacity are out of phase.
- **End of support is not end of use.** On-prem software often keeps running unsupported for years, especially at price-sensitive mid-size firms. The forced choice may be softer and more spread out than "fixed deadline" implies. That cuts both ways: it extends the window but reduces urgency. The plan should estimate what fraction of the installed base actually switches, and when.
- **There is a category mismatch: estimating vs. project management.** Keystone and Brickwell are described as *estimating* suites, while Trussline is project-management software that "connects the estimate." A contractor forced off an on-prem estimator needs a new estimator. Does Trussline replace estimating, or sit beside it? If it doesn't replace it, the trigger sends buyers to estimating vendors first, and Trussline benefits only indirectly. This is the most important clarification in the memo.
- **The trigger is reversible.** It rests on two vendors' policy decisions. Vendors facing churn often extend deadlines, discount migrations, or offer bridge licenses. Any of these blunts the trigger. Beyond this one event, the plan has no reinforcing second trigger.
- **Adoption curve.** With 60% already paying for software, this is a late-majority software buyer switching tools, not a category-creation sale. That is good, because it means a real market with revealed spend. But it also means competitive, replacement-style selling, where incumbents and challengers fight for every account.

## Comparable Benchmarks Assessment

**Verdict:** Inflated
**Confidence:** High (on internal inconsistency); Low (on the comp figures themselves)

The comp set is used to call the plan "conservative," and that argument doesn't hold.

- **The comps don't fit inside this SAM.** Sitework's year-5 ARR ($140M) is 18.5% of Trussline's entire $756M SAM. The three comps together ($354M) would be 47% of it. Either the comps sell well outside the mid-size US general-contractor band, or the SAM is badly understated. Their markets might include larger contractors, subcontractors, owners, residential builders, other geographies, or broader construction workflows. In either case, comparing raw ARR across different market sizes is invalid. The right benchmark is each comp's *share of its own addressable segment* at year 5, applied to Trussline's segment.
- **Selection guarantees survivorship.** "The three names most often mentioned by the contractors we sell to" is a selection filter that only returns winners. Contractors don't mention the tools that died. The implied base rate is 100% reaching $100M+ in five years, which is a top-decile outcome, not a benchmark.
- **The tailwind isn't repeatable.** The memo itself notes that Sitework's peak growth came from the 2020–21 construction surge and site-access restrictions. Those conditions don't recur. Buildgrid (2012) also grew in a different capital and adoption environment.
- **There is no segment or go-to-market matching.** The memo doesn't say whether the comps sell to mid-size general contractors through a field sales team. Different buyer, motion, and ACV ceilings make the year-5 figures non-transferable.
- **There are no negative comps.** Construction tech has a long tail of point solutions that stalled or sold early, often because field adoption by superintendents failed or because they couldn't displace an entrenched estimating or accounting system. The memo should name two or three and say which failure mode Trussline avoids.

"Even at half the pace of the category leaders, we reach our target" is a statement about ARR, not about this market's capacity. In share terms, the plan looks aggressive for its reachable footprint, as shown under SOM.

## Factual Foundation

No fact-check report was provided. The claims that would most benefit from verification are:

1. **The 45,000 contractor count and the 60% software-adoption rate.** Together they set the entire $756M ceiling. Both need a named source and a definition (firm vs. establishment, how revenue is measured).
2. **Keystone/Brickwell installed base and the end-of-support terms.** This covers "most of the installed base in our band," the 2025 announcements, the end-2026 date, and the roughly 2× migration pricing. The timing thesis and the missing core SAM figure both depend on it.
3. **Comp ARR figures and the segments behind them.** Buildgrid, Sitework, and Punchlist Pro's year-5 ARR, and crucially *which customer segments* produced that revenue. This determines whether the comps are usable at all.

## Overall Assessment

**Strongest lens: Market Timing.** It is supported by a SAM built on behavioral filters. The plan names a real, specific, datable trigger and a price crossing, and its segmentation uses revealed spend rather than demographics. Most pitches fail exactly here, and this one doesn't.

**Weakest lens: Comparable Benchmarks.** It drives the plan's central rhetorical claim ("deliberately conservative"). But the comps' revenue would consume most of Trussline's own SAM, which shows they aren't measuring the same market. As a result, the plan describes an ambitious share target (14–30% of the regions it can reach in five years) as a cautious one.

These two lenses interact. The trigger that justifies high share is front-loaded into 2025–27, while the sales capacity that delivers the share arrives in years 3–5.

**Most important revision:** rebuild SOM bottom-up around the trigger, by region and by migration cohort:

- Keystone/Brickwell on-prem contractors in each reachable region.
- Expected switch rate and timing after end of support.
- Trussline win rate against named competitors.
- Rep capacity available in each period.

Then replace the ARR comps with share-of-segment comps, including at least two failures. If the result still reaches $38M, the memo will have earned the word "conservative." If it doesn't, the honest story is just as fundable: a strong beachhead, a real but closing migration window, and a clear plan for what drives growth after it.

*Out of scope (sibling skills):* rep productivity and ACV-to-value ratio also bear on unit economics (`business-plan-critique-unit-economics`). The absence of any named cloud competitor and the reliance on association referrals for distribution belong to `business-plan-critique-moat`.
