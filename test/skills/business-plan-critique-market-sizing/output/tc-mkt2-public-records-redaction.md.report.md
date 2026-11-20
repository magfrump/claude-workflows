> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Market-Sizing Critique: Ferrule Series A Market Narrative

## TAM Definition Assessment

**Verdict:** Inflated

**Confidence:** Medium

The method is the plan's best feature. It builds the market bottom-up as body count × ACV, by segment, in a transparent table, and the arithmetic checks out: every row multiplies correctly, the total is $302.1M, and federal plus state is $139.8M, or 46%. Most pitches open with an unexplained analyst-report headline. This one does not, and that earns credibility.

There are two problems.

**1. Several row counts don't appear to apply the plan's own filter.** The plan says it counts bodies "that receive enough requests to justify a dedicated tool." The rows don't look filtered that way:

- **Counties: 3,031.** This is essentially every county in the US, including very small rural counties that may handle only a few requests a year. No request-volume filter appears to have been applied.
- **School districts over 5,000 students: 13,000.** I haven't verified this, but 13,000 is roughly the total number of US school districts, not the subset above 5,000 students. If the filtered count is closer to the low thousands, this row shrinks from $78.0M to something like $10–15M. That alone would bring the total to roughly $235–240M.
- **State agencies: 2,900.** That is about 58 per state. This is plausible as a count of entities, but it is not a count of agencies with enough request volume to justify a tool.

The build is transparent, so these are easy to fix. They still matter: the two rows most likely to be unfiltered (counties and schools) together make up 44% of the headline.

**2. There is no top-down cross-check.** The bottom-up build is never reconciled against an independent figure. The natural top-down check for this product is the **labor cost of request processing**: records-officer FTEs × loaded salary × the share of time spent on review and redaction. That ceiling tells you whether $9K for a city or $120K for a federal component is a small or large fraction of what the work already costs. The federal ACV in particular looks low for a component handling "tens of thousands of requests a year." That suggests the build is not uniformly optimistic, only unchecked.

**Realistic figure.** After filtering counties and school districts by request volume, the full-scope TAM is probably **$200–250M rather than $302M**. That is less than a 2× gap, which is acceptable at this stage. The bigger issue is what happens one level down.

## SAM Realism Assessment

**Verdict:** Inflated

**Confidence:** High

The table is labeled "Serviceable market," but it functions as a TAM. It counts every body of each type, without regard to whether Ferrule can legally or operationally serve it today. The plan's own compliance section shows that it can't serve all of them.

**1. Certification gates remove 46% of the claimed SAM.**

- **Federal ($52.8M).** Federal agencies generally need FedRAMP authorization to buy cloud services. Ferrule plans to *begin* FedRAMP Moderate in 2028, and the process typically takes a year or more after that. The federal row is therefore not serviceable before roughly 2029–2030.
- **State agencies ($87.0M).** StateRAMP (or a state-specific equivalent) is a common procurement requirement, and Ferrule "has not yet scoped" it. The SOC 2 Type II report is also still pending. Some state agencies will buy without StateRAMP. The plan doesn't say which ones, or how many.

The statement that "none of our current customers has required either" is true, but it describes the counties and cities Ferrule sells to now, not the segments the plan calls its growth centre.

**Serviceable today:** counties, municipalities, and school districts, totaling **$162.3M** before the TAM corrections above, or about **$95–100M** after them.

**2. The plan has a behavioral filter but sizes SAM without it.** The most valuable sentence in the document is this one: *"Every one of our 64 customers first contacted us within a year of their state's deadline change."* That is a near-perfect behavioral signal, and it should define the SAM. Sized that way, today's serviceable market is **counties, cities, and (maybe) school districts in the eleven deadline-change states**. Eleven of fifty states is about 22% by count. It may be more if those states skew populous, which is worth checking. That puts behavioral SAM at roughly **$20–35M** for local bodies. The plan explicitly says it does not depend on other states following, so this is the SAM the plan should be stated against.

**3. Product readiness is a second gate.** The raise funds "bulk email ingestion, which is the feature larger agencies ask for first." Larger agencies, the high-ACV state and federal rows, are therefore gated on product as well as certification.

**4. ACV provenance is mixed.** The plan says the ACVs are ones "we see or expect." County and city ACVs presumably come from the 64 customers. Federal and state ACVs must be expected, since there are no such customers. The table should mark which is which. The "first state-agency enterprise agreement" in the plan also doesn't fit a per-agency $30K ACV, because a statewide EA is priced differently. Say which model the state row assumes.

**Net:** the stated $302M SAM contracts about **10×** to a behavioral, certified, product-ready SAM of roughly $20–35M. That smaller market is the one the company actually sells into today.

## SOM Achievability Assessment

**Verdict:** Inflated

**Confidence:** High

**Implied share.** $15M against $302M is the 5% the plan states. That is already at the top of the B2B norm (1% in five years is excellent; above 5% is rare). The segment split is more revealing:

| Segment | Year-5 ARR | Plan's segment value | Implied share | Against realistic SAM |
|---|---|---|---|---|
| Federal + state | $8M | $139.8M | 5.7% | Federal largely unserviceable before year 5; state partly gated |
| Counties + cities | $5M | $84.3M | 5.9% | ~15–25% of eleven-state local SAM |
| School districts | $2M | $78.0M | 2.6% | Larger share if the row shrinks as expected |

**1. The federal timeline contradicts itself.** The plan has a "first federal contract in year two" but starts FedRAMP in 2028. Unless year two is 2028 *and* the first contract avoids FedRAMP (an on-prem deployment, a pilot below the threshold, or a sponsor-agency route), these two statements can't both be true. Even in the best case, federal ARR ramps from roughly year four. The plan needs to name the mechanism or move the date.

**2. The sales capacity for the $8M doesn't fit.** Two account executives cover both federal and state. Reaching $8M means something like 30 federal components at $120K plus about 150 state agencies at $30K, or a few large EAs. Spread over the three or four selling years the plan allows, that is roughly $1M+ of new ARR per AE per year in the segments with the longest procurement cycles and the gated certifications. That is well above typical government-AE productivity. Hitting $8M requires a larger federal and state team than this raise funds, which implies a Series B dependency that isn't stated.

**3. The county and city math is the defensible core, and it should be shown.** At a blended ACV of about $13K, $5M means about 380 local customers, up from 64. At a one-in-three win rate, that is about 950 evaluations net of churn over five years. All of it must come mostly from the eleven trigger states if the plan "does not depend on" the rest. That implies roughly 15–25% of behavioral local SAM. This is within the 20–40% range a well-executed beachhead can reach, but it should be stated explicitly, alongside the current ARR and the size of the doubled sales team.

**4. The beachhead is real.** It is local government in the deadline-change states, with association-driven references and short procurement. The plan's expansion logic jumps from that beachhead to federal, the segment least like it, instead of extending to adjacent segments: state agencies in the same eleven states, school districts, and new states as their deadlines change.

**Most constraining bottleneck:** the certification and sales-capacity path for the $8M. If that segment slips to the right, which is likely, year-five ARR is closer to **$7–9M** on the plan's own local-segment assumptions.

## Market Timing Assessment

**Verdict:** Defensible

**Confidence:** Medium

This is the strongest section of the plan, and it is a model "why now":

- **It names a specific, recent trigger.** Eleven states shortened deadlines and added per-day penalties between 2023 and 2025.
- **It names a mechanism.** Six states publish on-time rates, which turns a quiet backlog into a public number attached to an office.
- **It shows revealed preference.** Every customer arrived within a year of their state's change, and 75% of the pipeline is in those states.
- **It deliberately doesn't depend on the trend spreading.**
- **It rests on multiple triggers.** Eleven separate statutes are less reversible than a single catalyst, and penalty statutes are rarely repealed quickly.

Three issues keep the confidence at Medium.

**1. The trigger doesn't reach the growth centre.** State deadline statutes don't apply to federal agencies. Federal FOIA has its own deadlines and backlog dynamics, and the plan offers no federal "why now." The timing evidence supports the local and state-agency market in the eleven states. Nothing in the plan supports timing for the $52.8M federal row.

**2. Demand may come as a pulse.** If customers arrive "within a year" of a deadline change, demand in each state may spike and then decay. The changes ran from 2023 to 2025, so some of the eleven states may already be past their peak inbound window. Show inbound volume by state against months since the change. If it stays flat, demand is structural. If it decays, new-customer flow from these states shrinks across years three to five, and the plan quietly relies on the remaining states following after all.

**3. Adoption-curve placement fits only the local market.** Local adoption looks early-adopter to early-majority within the trigger states, which suits Ferrule's low-ACV, short-cycle motion. Federal buyers are at a different stage and need a different motion.

## Comparable Benchmarks Assessment

**Verdict:** Plausible

**Confidence:** Low

**What's good:** the comp set includes an outcome that flattened (Docketwise Public) and names the cause, procurement-cycle length. That is unusually honest.

**What's missing:**

1. **The comps don't cover the segment that carries most of the revenue plan.** Both comps sold to local bodies: municipalities and county courts. Federal and state account for 53% of year-five ARR, and no comp sold into those segments. Docketwise's lesson, that long procurement flattens growth, applies *more* strongly to federal and state than to courts. The plan uses it only to flatter its county positioning.

2. **The trajectory outruns both comps.** Ferrule projects $15M at year five. Docketwise peaked at $12M at year seven. Clerkstream reached $41M at year nine, but its year-five figure isn't given, and it is the number that matters. "We sit between the two" is a claim about product and cycle, but the projection sits *above* Docketwise's ceiling and ahead of Docketwise's pace. Give Clerkstream's year-five ARR. If it was below about $10M, the plan claims top-of-comp-set execution and should say why.

3. **The plan names no direct competitors.** The obvious competitive set is existing public-records request-management platforms, many of which include redaction modules, along with eDiscovery and document-redaction vendors moving into government. The plan names none. Many state and federal agencies may already run a request-tracking system, so Ferrule may be displacing or integrating with a tool rather than starting fresh.

4. **The comp set has no failures in this specific category.** Name a public-records or redaction startup that stalled, if one exists, and the reason.

The Low confidence reflects a two-company comp set with no year-five data point and no federal or state coverage.

## Factual Foundation

No fact-check report was provided. These claims most need verification, in order of how much of the plan rests on them:

1. **The eleven-state statutory changes (2023–2025), with penalties, and the six states publishing on-time rates.** The entire timing thesis and the behavioral SAM rest on this. Also check the populations of those states.
2. **The body counts, especially "school districts over 5,000 students: 13,000" and the 3,031 counties.** These look like unfiltered totals, and they account for $132.6M of the $302.1M.
3. **Whether a year-two federal contract is possible without FedRAMP authorization,** and which state agencies in the target states require StateRAMP. This determines whether $139.8M is serviceable within the plan horizon. The comp ARR figures (Clerkstream $41M at nine years, Docketwise $12M at seven) are also worth confirming, along with Clerkstream's year-five ARR.

## Overall Assessment

**Strongest lens: market timing.** The deadline-change trigger, the public on-time rates, and the "every customer arrived within a year" evidence form a specific, recent, revealed-preference "why now" of the kind most pitches lack. The transparent bottom-up TAM build is a close second.

**Weakest lens: SAM realism, which flows into SOM.** The plan calls $302M "serviceable," but by its own compliance section 46% of it can't be served within the plan horizon. It then makes that gated 46% "the centre of our growth plan" and assigns it $8M of the $15M target, staffed by two AEs and dated before the FedRAMP process even begins.

**The single most important revision:** present Ferrule as **two markets with different evidence**.

- **Market 1: the proven core.** This is local government (and, where StateRAMP isn't required, state agencies) in the eleven deadline-change states. It is a behavioral SAM of roughly $20–35M, with a demonstrated trigger, a one-in-three win rate, association references, and short procurement. Build the year-five base case here, with the customer count, evaluation count, and sales headcount spelled out.
- **Market 2: an option on federal and state.** Make it explicitly gated on SOC 2 Type II, StateRAMP scoping, bulk email ingestion, and FedRAMP, with dates that agree with the compliance section. Show it as upside, not as the base case.

This version is more fundable than the current one. Investors can underwrite a credible $7–9M base case, built on a trigger that is already working, with a federal option on top. They will discount a $15M plan whose largest component contradicts its own compliance timeline. The data that makes the strong version possible, the trigger-state concentration, is already in the plan. It just isn't yet being used to size the market.
