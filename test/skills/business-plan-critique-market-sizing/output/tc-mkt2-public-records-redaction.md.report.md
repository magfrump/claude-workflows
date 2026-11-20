> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Market-Sizing Critique: Ferrule Series A Market Narrative

## TAM Definition Assessment

**Verdict:** Inflated
**Confidence:** Medium

The plan has no TAM. The $302.1M bottom-up table is labeled "serviceable market," but it works as a TAM. It includes every segment Ferrule could ever sell to, including ones it cannot currently serve (see SAM). Building bottom-up by body type and ACV is the right method, and the arithmetic checks: the segments sum to $302.1M, and federal plus state comes to $139.8M, or 46%. The problems are in the inputs.

**The stated filter doesn't appear to have been applied to two of the five rows.** The plan says it counts bodies "that receive enough requests to justify a dedicated tool." Two counts look like full census totals instead:

- **Counties: 3,031.** As far as I know, this is the total number of county governments in the US Census of Governments. That would mean every county is counted, including rural counties that get a handful of requests a year. If the filter were applied, this row would shrink by some fraction. I can't estimate that fraction from the draft.
- **School districts over 5,000 students: 13,000.** This is roughly the total number of US public school districts, not the number above 5,000 students. My understanding is that districts above that size are a small minority, on the order of 2,000. I haven't verified that figure, and it is the one I'd most want fact-checked. If it holds, this row falls from $78.0M to roughly $12M. That one correction removes about 22% of the headline market.

The municipality count (3,300 over 10,000 residents) looks broadly plausible. I have no basis for judging the 2,900 state-agency count.

**ACV provenance is mixed.** The table says ACVs are values "we see or expect." Only the county and city ACVs ($18K and $9K) can be observed, because those are the only segments with customers. The federal ($120K), state ($30K) and school district ($6K) ACVs are expectations. Those three rows hold $217.8M of the $302.1M, or 72%. The plan should mark which ACVs are observed and which are assumed, and state the current blended ACV across the 64 customers.

**Gap:** Fixing the school-district count alone takes the headline from $302M to about $236M. Applying a real request-volume filter to counties would take it lower. Methodology disclosure is otherwise good. The problem is that the stated method wasn't applied consistently.

## SAM Realism Assessment

**Verdict:** Inflated
**Confidence:** High

The plan's own facts contradict its SAM in three ways. None of these depend on outside data.

**1. Federal is not serviceable within the plan horizon.** The plan says FedRAMP Moderate work begins in 2028, runs from a single commercial cloud region, and has no compliance team yet. Federal cloud purchases generally require an authorization. Moderate authorizations typically take a year or more after kickoff, so the earliest realistic federal-ready date is about 2029–2030. Yet the revenue model assumes "a first federal contract in year two." Unless that contract uses an agency-specific ATO or a non-cloud deployment, which the plan doesn't describe, the $52.8M federal row is aspirational TAM, not SAM.

**2. State agencies are partly gated, and StateRAMP isn't scoped.** A growing number of states require StateRAMP or a state equivalent for cloud vendors. Ferrule hasn't scoped it, so some unknown share of the $87.0M state row is gated, with no timeline to open it. The SOC 2 Type II report, expected Q2 next year, is also a common procurement prerequisite for larger agencies. Until it lands, Ferrule only has Type I.

**3. The behavioral segment is the eleven trigger states, not the nation.** This is the most important point, and the plan supplies the evidence for it:

- every one of the 64 customers contacted Ferrule within a year of its state's deadline change;
- three quarters of the pipeline is in those eleven states;
- the plan explicitly does not count on other states following.

That is a strong behavioral filter. It says the people who buy are agencies under a newly shortened deadline with a published on-time rate. But the SAM is sized nationally with descriptive filters (body type and size). If the plan does not depend on other states changing their law, the SAM should not depend on them either.

A rough sizing, assuming the eleven states hold about 11/50 of the bodies (an assumption, since big states would skew it either way):

| Segment | Plan (national) | Eleven trigger states (~22%) |
|---|---|---|
| Counties | $54.6M | ~$12M |
| Municipalities >10K | $29.7M | ~$6.5M |
| School districts (corrected to ~2,000) | $78.0M → ~$12M | ~$2.6M |
| State agencies (ungated portion) | $87.0M | ~$19M less StateRAMP-gated share |

On these assumptions, the behavioral local-government SAM is about $20M a year, not $162M. The real number is somewhere between the two, and the plan should say where. The quarter of pipeline outside the trigger states is the evidence for how much demand exists without a trigger.

**Buyer vs. user for state and federal.** The revenue model refers to a "state-agency *enterprise agreement*." That implies the buyer is a central body, such as state IT, procurement or the AG's office, not each of 2,900 agencies. If states buy centrally, the state row becomes about 50 buyers with large, lumpy contracts rather than 2,900 × $30K. The total dollars could be similar, but the sales motion, cycle length and number of AEs needed are very different. The same question applies to federal "components" versus departments.

## SOM Achievability Assessment

**Verdict:** Speculative
**Confidence:** High

The headline is $15M ARR in year 5, which is 5% of $302M. That blended figure hides two very different bets.

| Segment | Year-5 ARR | Share of plan's segment | Evidence today |
|---|---|---|---|
| Federal + state | $8.0M (53%) | 5.7% of $139.8M | Zero customers; FedRAMP not started; StateRAMP not scoped |
| Counties + cities | $5.0M (33%) | 5.9% of $84.3M | 64 customers, about 1-in-3 win rate |
| School districts | $2.0M (13%) | 2.6% of $78M (≈17% of corrected ~$12M) | No customers mentioned |

**The weighting is the inverse of the evidence.** The plan calls county and city "the ones we can defend best" and federal and state "the centre of our growth plan." More than half of year-5 revenue comes from segments with no customers, gated by certifications the company won't start until 2028, and backed by two AEs. To make $8M, an illustrative split is about 33 federal components at $120K plus about 133 state agencies at $30K. Federal and state sales cycles commonly run 12–24 months, and the FedRAMP gate realistically opens late in the five-year window. That ramp looks very unlikely.

**County and city capacity check:**
- $5M at $9–18K ACV is about 280–560 customers, versus 64 today.
- The pool in the eleven trigger states is roughly 1,400 counties plus large municipalities, using the same proportionality assumption as above.
- So the plan needs about 20–40% of the behavioral pool.
- At a one-in-three win rate, that means evaluating close to the entire pool in five years.

A 20–40% share of a small beachhead is achievable in principle, and this is the right shape for a wedge. But it is the binding constraint on the defensible part of the plan, and the plan doesn't state it. The plan says it will "double the county and city sales team" without giving current team size or rep productivity, so I can't check whether the hiring plan supports the required evaluation volume.

**Missing baseline.** Current ARR isn't stated. If the 64 customers pay roughly the table ACVs, current ARR is around $1M, which makes $15M about 15× in five years. State current ARR and year-by-year ARR by segment so investors can see the curve's shape. As written, federal and state "ramping from there" after a year-2 first contract implies a smooth ramp, when the real curve is likely to be flat until authorization and then a step up.

**Most constraining bottleneck:** certification timing for federal and state, and pool exhaustion for local.

## Market Timing Assessment

**Verdict:** Defensible
**Confidence:** Medium

This is the strongest section of the plan, and it is a model "why now":

- **Specific trigger, not a trend.** The plan names the decade-long volume increase and correctly sets it aside. The real trigger is that between 2023 and 2025, eleven states shortened deadlines, added per-day penalties, and in six cases began publishing on-time rates. That is a dated, legal, observable change.
- **Revealed preference.** Every customer arrived within a year of its state's change. That is evidence of current spending, not of a market that has to be educated. It is the opposite of the "too early" failure mode.
- **Restraint.** The plan doesn't count on the other 39 states following.

Three refinements:

1. **The trigger doesn't reach federal.** Federal FOIA deadlines are set by federal statute, and nothing in the 2023–2025 state changes affects them. The segment the plan calls its growth centre is the one segment the "why now" doesn't cover. Federal needs its own timing thesis, such as a backlog mandate or an OMB directive, or it should be framed as later upside.
2. **The trigger may produce a buying wave rather than steady demand.** If agencies buy within about a year of their deadline change, demand in each state could peak and then decay. Show whether win rate and inbound volume hold up two or more years after a state's change. If they fade, growth depends on new states adopting, which the plan says it doesn't assume.
3. **Reversibility is low but not zero.** Statutory penalties are sticky. Publication of on-time rates is the strongest mechanism, and it is also the easiest to quietly drop. Six of eleven states doing it is good, but say whether conversion is higher in those six. If it is, that strengthens the behavioral SAM argument above.

On the adoption curve, 64 bodies is innovator or early-adopter stage even within the trigger states. The low-ACV, single-department-head-plus-council-vote motion fits that stage. Federal enterprise pricing does not.

## Comparable Benchmarks Assessment

**Verdict:** Plausible
**Confidence:** Low

**What works:** the plan includes a partial negative comp in Docketwise Public, which flattened at $12M because of long procurement cycles, and states the mechanism. That is more honest than most comp sections.

**What's missing:**

- **Two comps is too few to give a base rate.** They bracket $12–41M, but the plan's year-5 target of $15M already exceeds Docketwise's year-7 outcome. The plan cites Clerkstream's ARR at year 9, not at year 5. Give Clerkstream's year-5 ARR. Without it, "we sit between the two" compares a year-5 projection to outcomes at years 7 and 9.
- **Both comps are local-government only.** Nothing in the comp set shows any company in this space selling into federal or state agencies, yet that is 53% of the plan. Add comps that broke into federal or state through FedRAMP, and show how long that took them.
- **Segment match is imperfect.** Agenda and minutes software has a buyer in essentially every municipality with a council, and it is used weekly. Records redaction is request-driven and concentrated in larger bodies. Clerkstream's addressable base is likely broader than Ferrule's, so "a narrower product than agenda management" argues for a ceiling below Clerkstream, which the plan acknowledges only implicitly.
- **No direct-category comps.** Public-records request-management platforms and redaction tools already exist; GovQA, NextRequest and JustFOIA are examples I believe operate here, though I haven't verified current ownership or figures. The plan names none. Their revenue at comparable stage is the most relevant benchmark available. Whether they are competitors or acquirers belongs to the moat critique, but their trajectories belong here.
- **Negative comps beyond Docketwise.** Has anyone tried to sell redaction automation to agencies and stalled? If so, at which gate: procurement, accuracy, or certification?

**Implied-outlier check:** if the realistic local-government comp median is around $12M at year 7, then $15M at year 5, with more than half from an untested segment, implies top-decile execution plus a successful federal entry. Name the structural advantage, or anchor the projection to the local segment and treat federal as upside.

## Factual Foundation

No fact-check report was provided. These claims most need verification, in order of how much they move the market story:

1. **Segment body counts**, especially school districts over 5,000 students (13,000) and counties (3,031). If these are census totals rather than filtered counts, the serviceable market falls by roughly a quarter or more.
2. **The eleven-state statutory changes, 2023–2025**, including which states and whether six publish on-time rates. The timing thesis and the behavioral SAM both rest on this.
3. **Comparable-company figures.** Clerkstream at $41M ARR in year 9 and Docketwise Public at $12M and acquired in year 7, plus Clerkstream's year-5 ARR, which the plan doesn't give.

The plan's assumption that federal sales can begin before FedRAMP authorization is worth a quick check with a federal procurement advisor. It is a structural question as much as a factual one.

## Overall Assessment

**Strongest lens: market timing.** The trigger is specific, dated and backed by revealed preference across all 64 customers. Few Series A plans can say that.

**Weakest lens: SOM, driven by SAM.** The plan's best evidence says buyers are local and state bodies in trigger states. Its revenue model puts 53% of year-5 ARR into federal and state segments that:

- have zero customers;
- sit behind certifications not yet started or scoped;
- are covered by just two AEs;
- in the case of federal, are not covered by the timing thesis at all.

Meanwhile the defensible segment is sized nationally, when the demand evidence is confined to eleven states.

**The single most important revision:** rebuild the market story around the segment the evidence supports.

1. Size a behavioral SAM: counties, large cities, larger school districts, and ungated state agencies in the eleven trigger states, with the filters applied consistently.
2. Show the county and city capture math in customers and evaluations against that pool.
3. Move federal to a separate, explicitly post-authorization upside case, dated to the FedRAMP timeline.

The year-5 number will likely come down. But the plan will then rest on its strongest asset, a real trigger with demonstrated pull, rather than on a federal ramp that a diligent investor will discount anyway. A smaller, well-evidenced wedge with a credible federal option usually raises more easily than a larger number that falls apart on the compliance section.

*Out of scope:* how incumbent request-management platforms might bundle redaction is a moat question for `business-plan-critique-moat`. Federal and state CAC and sales-cycle length under a two-AE model is a question for `business-plan-critique-unit-economics`.
