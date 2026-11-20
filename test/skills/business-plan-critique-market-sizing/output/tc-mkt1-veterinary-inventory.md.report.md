> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Market-Sizing Critique: Stockvet Seed Memo

## TAM Definition Assessment

**Verdict:** Inflated
**Confidence:** High

The $62B TAM is the value of animal-health *products*, but Stockvet sells a $4,800/year *software subscription*. Stockvet doesn't earn a share of the product dollars that flow through a clinic. It earns a fixed fee per clinic. "Every dollar in the category is a dollar some clinic has to forecast" may be true, but it doesn't make that dollar addressable revenue. This is a category-report misfit, and it fails at the unit of measure itself.

**The bottom-up figures, using the memo's own inputs:**

| Build | Clinics | × $4,800 | Revenue ceiling |
|---|---|---|---|
| All US clinics (corporate included) | 32,000 | | ~$154M |
| US independents | 18,000 | | ~$86M |
| Stated SAM | 11,000 | | $52.8M |

- The gap between the $62B headline and the most generous US bottom-up figure (~$154M) is about **400×**. The reconciliation threshold for top-down versus bottom-up is roughly 3×.
- Adding non-US clinics at several times the US count still leaves the software TAM well under $1B.

**Further problems with the $62B figure:**

- **Geography.** The figure is global. The plan sells only in the US, and only in the western states for the next three years.
- **Channel.** "Almost every product passes through a clinic's shelves" is load-bearing and unverified. Animal-health totals usually include livestock and production-animal products and retail/online pet-pharmacy sales. Much of that never touches a companion-animal clinic's inventory. The claim needs a source or should be dropped.
- **Buyer.** The figure includes spend flowing through corporate-group clinics. The memo itself says those are "not our buyer."
- **Growth rate.** The 8% growth applies to product spend. Stockvet's market grows with clinic count and price, not with what each clinic dispenses.

**Why this matters.** The $62B number hides the most important fact in the memo: on current pricing, **100% of the serviceable market is $52.8M ARR.** That is the real market-sizing question for a venture seed round. The memo should face it directly rather than paper over it with a product-spend figure. If the team believes Stockvet's ceiling is above $52.8M, there are two valid paths:

- **Value-based pricing.** Price against write-offs of 2–4% of inventory value, recovered stock-out revenue, and 6.5 hours/week of practice-manager time.
- **Flow-based revenue.** A take rate on orders placed through the platform.

Either path would justify a larger TAM. Neither is in the memo today.

## SAM Realism Assessment

**Verdict:** Plausible
**Confidence:** Medium

This is the strongest-built number in the memo:

- Excluding corporate groups is a correct *buyer* filter, not a user filter.
- The PMS-integration filter is a real technical gate.
- The >400 SKU threshold is a reasonable proxy for pain intensity.
- SAM × ACV gives a coherent $52.8M ceiling, and the ACV is the actual current price, not an aspirational enterprise number.

**Issues to tighten:**

- **The filters are still mostly descriptive.** None of them tests purchase behavior. The obvious behavioral filter is missing: **share of the clinic's purchasing that runs through Pallas or Northgate.** Stockvet's automation only works through those APIs. A clinic buying heavily from regional distributors or directly from manufacturers gets partial value at full price. "Those two distributors handle most of the product" is an aggregate claim. The SAM should count clinics where they handle most of *that clinic's* product.
- **The integration story is internally inconsistent.** The 11,000 count includes "clinics that already run one of the four PMS systems we integrate with." Yet the raise funds "two engineers for the California and Texas practice-management integrations."
  - If CA/TX clinics run PMS systems Stockvet doesn't yet support, they aren't in the 11,000 today. The current SAM is then smaller than stated, perhaps much smaller if those four systems skew regional.
  - If they are already in the count, it isn't clear what the engineers are building.
  - The memo should state how the 11,000 splits by region and PMS.
- **The two filters are blended.** The 18,000 → 11,000 step combines the PMS filter and the SKU filter, so neither can be judged separately. The problem section says a typical clinic stocks 400–1,200 SKUs, which suggests the SKU floor removes few clinics. If so, the PMS gate is doing most of the narrowing. That matters because the PMS gate moves as integrations are added.
- **Controlled substances may be a gate.** Ordering controlled substances in the US runs through DEA-regulated processes. It is not clear whether the distributor APIs cover them. If they don't, part of the "full shelf" value proposition is out of scope for automation. This doesn't shrink clinic count, but it may shrink the value per clinic that the SAM implicitly assumes.
- **SAM direction over time.** The memo treats 18,000 independents as stable. Veterinary-practice consolidation into corporate groups has been a persistent trend (unverified here). If the independent share keeps falling, the SAM erodes over the plan horizon. The memo should state whether it expects the 11,000 to grow or shrink.

**Wedge.** The wedge is well defined: 1,200 beachhead clinics. Year-1 SAM is clearly separated from steady-state SAM.

## SOM Achievability Assessment

**Verdict:** Plausible
**Confidence:** Medium

**The capture math:**

- Year 5: 700 clinics ÷ 11,000 = **6.4% of SAM**, at $3.36M ARR (consistent with $4,800 ACV).
- Year 3: 300 ÷ 1,200 = **25% of the beachhead**.

Taking 25% of a narrow wedge, backed by founder networks and two regional association endorsements, is within the range that beachhead strategies achieve. The beachhead → expansion logic (PNW/Mountain → CA/TX) is named explicitly, which many seed plans skip.

**Sales capacity doesn't reconcile with the target, but in the opposite direction from usual:**

- 3 reps × 8 clinics/month = 24/month, or ~288/year at full ramp.
- Even with a generous six-month ramp, that capacity reaches 300 net new clinics in well under 24 months. Over the full period it would close roughly 40–50% of the 1,200-clinic beachhead.
- So either the rep-productivity figure is not grounded in actual close rates from the first 41 clinics, or the 300-clinic target sits far below what the funded sales capacity implies.
- The memo should show the actual close rate per rep per month so far and size the target from that.

**Timeline mismatch.** The GTM section says 300 clinics "by the end of year three." The raise section says 300 clinics at the end of 24 months of runway. Pick one. If it is three years, the plan needs bridge capital the memo doesn't mention.

**The constraint is the ceiling, not achievability.** Year 5 at 700 clinics and $3.4M ARR is a modest outcome, and it sits close to the Optistock failure case (see Comparable Benchmarks). Even 3–4× the year-5 plan would reach only ~20–25% of a $52.8M SAM.

**Competitive density is not addressed.** No competitors are named. The two plausible ones are:

- PMS vendors bundling an inventory module.
- The distributors themselves offering auto-replenishment, now that they have built the APIs.

A 25% beachhead share depends on neither entering seriously within three years. I'll flag this for the moat critique rather than assess it here.

## Market Timing Assessment

**Verdict:** Defensible
**Confidence:** Medium

This is a genuine trigger, not a trend:

- The two national distributors opened ordering APIs to third parties in March 2025, about 20 months before today.
- Before that, automated reordering required screen-scraping, which both distributors prohibited.
- This is exactly the kind of platform-primitive change a "why now" should name. It also explains why no one had built this before, which pre-empts the "if this is so good, why doesn't it exist?" objection.

**Too-early risk is low.** Clinics already pay for the substitute: 6.5 practice-manager hours per week, write-offs, and stock-outs. 41 paying clinics is direct revealed preference. The market sits in the early-adopter phase, and a $400/month self-serve-plus-field-rep motion fits that phase.

**Remaining risks:**

- **Single-catalyst reversibility.** The thesis rests entirely on two distributors keeping their APIs open on acceptable terms. They could rate-limit, charge per call, restrict which partners get access, or launch a competing first-party product. The memo should say what agreements, if any, govern Stockvet's access, and how the product degrades if one distributor withdraws.
- **The trigger is not exclusive.** The same API opening that enables Stockvet enables every PMS vendor and every competing startup. The timing window may be short. That strengthens the case for speed but weakens any implied "we're alone here."
- **The trigger is unverified.** The claim that "most of the product" flows through those two distributors matters both for timing and for SAM, and it should be sourced.

## Comparable Benchmarks Assessment

**Verdict:** Plausible
**Confidence:** Medium

The comp set is better than most because it includes **negative comps with a stated failure mechanism**:

- Optistock: too few SKUs to justify the price.
- Clinicshelf: never found a segment.

The plan then argues explicitly why veterinary clinics resemble the success case (Dentrack) rather than the failures: high SKU counts, perishables, an owner-operator buyer. That is how a comp set should be used. The year-5 projection of 700 clinics is also *below* Dentrack's 2,100 at year 6, so the plan isn't projecting outlier performance against its own best comp.

**What to add:**

- **Convert comps to share, not counts.** 2,100 dental practices means little without the size of Dentrack's addressable base. The number of independent US dental practices is likely much larger than 11,000 qualifying vet clinics (unverified). If so, Dentrack's *share* may be well below Stockvet's 6.4% year-5 target, and the comp would support the count but not the share.
- **Report outcomes in revenue and exit terms.** What ACV does Dentrack charge? What ARR did 2,100 practices produce? Was it venture-scale, and how was it financed and exited? That answers whether the success case is a venture outcome or a good small business.
- **Read the Optistock comp more closely.** It stalled at 400 practices and sold for its team. At Stockvet pricing, 400 clinics is ~$1.9M ARR. Stockvet's year-5 target of 700 clinics / $3.4M sits much closer to that failure outcome than to the Dentrack outcome. That should prompt the memo to explain what pushes Stockvet past 700.
- **Stage and era matching.** Dentrack's launch year and market conditions aren't given. If it launched before cheap integrations and distributor APIs existed, its trajectory may understate what is possible now, or reflect a less crowded field.
- **Veterinary-specific negative comps are missing.** Has anyone tried inventory software for vet clinics before, through PMS add-ons, distributor tools, or startups? Even pre-API attempts that failed on screen-scraping would strengthen the "why now" if named.

## Factual Foundation

No fact-check report was provided. These claims would benefit most from verification, roughly in order of how much weight they carry:

1. **"Pallas and Northgate handle most of the product an independent clinic buys," and the March 2025 API opening.** This underpins both the timing thesis and the effective SAM. If the combined share is materially lower than "most" for many clinics, both lenses weaken.
2. **Clinic counts: 32,000 US clinics, 18,000 independents, 11,000 qualifying.** The SAM rests entirely on these. The 11,000 needs a disclosed source for PMS market share, ideally broken down by region.
3. **The $62B Meridian Research Partners figure, the 8% growth rate, and the claim that "almost every product" passes through clinics.** I recommend removing the $62B as TAM regardless. If it stays as context, it needs verification and a scope note (global, all species, all channels).
4. **Dentrack's 2,100 practices at year 6**, ideally with its ARR and addressable base.

## Overall Assessment

**Strongest lenses: Market Timing and Comparable Benchmarks.**

- The API opening is a specific, recent, falsifiable trigger.
- The comp set honestly includes failures with mechanisms and argues which side Stockvet falls on.
- The SAM build and beachhead plan are also more disciplined than most seed memos: buyer-level filtering, real current ACV, and a named wedge.

**Weakest lens: TAM Definition, by a wide margin.**

- Treating $62B of product spend as the addressable market for a $4,800/year subscription is off by roughly 400× against the memo's own bottom-up numbers.
- A sophisticated investor will do this arithmetic in under a minute, and it undermines the credibility of the more careful work elsewhere.

**The most important revision:** replace the $62B TAM with an honest bottom-up software TAM (~$86–154M in the US at current pricing). Then state directly how Stockvet gets beyond a $52.8M SAM ceiling. Either:

- **(a)** a value-based pricing case, anchored in the write-off, stock-out and labor figures you already have, or
- **(b)** an expansion path with its own sizing: a take rate on orders, adjacent clinical segments, or eventually corporate groups.

Keep today's TAM and the expansion TAM visibly separate. The underlying business may be good. The memo is strongest when it shows the real ceiling and argues for raising it, rather than hiding it behind a number that doesn't measure what Stockvet sells.

**Smaller fixes worth making in the same pass:**

- Reconcile the 24-month versus three-year timeline.
- Ground the 8-clinics-per-rep-per-month figure in your first 41 sales.
- Clarify whether the CA/TX clinics are already in the 11,000.

**Out of scope, noted for the sibling critiques:**

- Distributor and PMS-vendor competitive response, and API dependency as a moat question: `business-plan-critique-moat`.
- Whether $400/month is well priced against the 6.5 hours/week and the 2–4% write-off savings, plus rep cost versus the payback implied by 8 closes/month: `business-plan-critique-unit-economics`.
