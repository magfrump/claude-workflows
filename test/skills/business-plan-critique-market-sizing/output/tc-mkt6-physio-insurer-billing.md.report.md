> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Market-Sizing Critique: Claimwell, Market Case for a £600k Seed Round

This is an unusually honest market story. It uses a bottom-up build, checks price against what clinics already spend, dates its timing trigger, names a failed comp, and declines to claim venture scale. The arithmetic is internally consistent:

- 6,500 × £3,600 = £23.4M
- 55% × 6,500 = 3,575 clinics, which × £3,600 ≈ £12.9M
- 30% × 120 = 36 clinics
- 160 × £3,600 = £576k
- 160 ÷ 3,575 ≈ 4.5%

The findings below are about which inputs carry the weight, not about inflation.

## TAM Definition Assessment

**Verdict:** Plausible
**Confidence:** Medium

The TAM is bottom-up (clinics × price), with no top-down category figure to reconcile against. For a niche this narrow that is the right choice. The £380/month that pilot clinics already pay bureaus or admin staff is good revealed-preference evidence that £300 sits below an existing spend line.

Three inputs need tightening:

- **Counting unit.** "Clinics, counting independents and small chains of up to five sites" leaves unclear whether a five-site chain is one account or five. At £300 per account, the TAM could move by a meaningful fraction depending on the answer. State whether price is per site or per business, and count the same unit.
- **Uniform price across uneven claim volume.** £3,600/year applies to every clinic, from a solo practitioner with a handful of insured patients to a five-site chain. The £380 benchmark comes from pilot clinics, who likely self-selected for heavy insured volume. Low-volume clinics may not value the product at £300.
- **Benchmark scope.** "The same work" may not be like-for-like. If bureaus also chase rejected claims or handle self-pay invoicing, part of the £380 pays for things Claimwell doesn't do.

**Gap:** The headline £23.4M is a ceiling at one price point. A volume-tiered or volume-weighted version would likely be lower but more credible. The plan's honest framing of £23.4M as a total market, not a venture-scale opportunity, already absorbs much of this risk.

## SAM Realism Assessment

**Verdict:** Plausible
**Confidence:** Medium

The two SAM filters are better than typical descriptive filters:

- "Takes insured patients" is a behavioral condition.
- "Uses one of four integrated booking systems" is a hard technical gate.

The weakness is that both are binary. What predicts purchase is the **share of a clinic's visits that are insured**. A clinic where 5% of visits are insured and a clinic where 60% are insured both pass the filter, but only the second has a £300/month problem. Splitting the 3,575 by insured-visit share would turn SAM into a purchase-predicting number. My rough guess is that it shrinks SAM by 1.5–3×, though the plan has no data to confirm this.

Two further issues:

- **Clinics that have already solved the problem.** The trigger was April 2025, 19 months before today. Every serviceable clinic that bills Albion or Crestmoor has by now had to integrate, hire admin, or pay a bureau. So the SAM is no longer "clinics with an unsolved problem." It is "clinics willing to switch from their current workaround." That market is real, since the £380 spend shows the workaround is costly, but it converts more slowly. Segment SAM by current solution (bureau, in-house admin, direct portal use) and estimate how switchable each group is.
- **Unverified survey input.** The 55% comes from trade-association survey data, and every downstream number depends on it. Report the sample, the year, and whether the two conditions were measured jointly or multiplied as if independent. Clinics on modern booking systems may be more likely to take insured patients, so multiplying the rates could distort the result.

Buyer vs user is not a concern here. In small clinics the owner is both buyer and beneficiary.

## SOM Achievability Assessment

**Verdict:** Plausible for the beachhead; the national expansion path is unsupported
**Confidence:** Medium

**Beachhead.** 19 of 120 regional clinics is about 16% share today. Reaching 36 (30%) by the end of year two means about 17 net new clinics over roughly two years, from two founders who can visit in person. That is achievable. The beachhead logic is the strongest part of the capture story.

**National expansion.** Moving from 36 to 160 means about 124 clinics in three years, about 3.5 per month, mostly outside the region where in-person selling works. The plan doesn't name a sales motion for this phase: no hires, channel, booking-vendor partnership, or referral mechanism. The 4.5% end-state share is modest, but the share isn't the constraint. The constraint is how out-of-region clinics get acquired.

**Acquisition pace (inferred, so treat with care).** If roughly 15 of 23 customers (two thirds) signed within three months of April 2025, then about 8 have signed in the roughly 16 months since, or about 0.5 per month. The year-5 target needs about 2.5 net per month on average. If that reading is correct, it is the most important number missing from the plan: post-trigger acquisition is running at roughly a fifth of the required rate. If the company launched after the switch, or the reading is otherwise wrong, show the monthly signup curve to rule it out.

**Regional density check.** Greater Manchester plus Yorkshire hold very roughly 12% of the UK population. On a population basis, that would imply about 400 serviceable clinics rather than 120. Private physio likely skews toward London and the South East, so a lower figure is plausible. Still, 120 is about 3.4% of the national SAM, so either the regional count is restricted to a drivable radius or the national 3,575 runs high. One sentence explaining the 120 would settle it.

**Churn.** It is not mentioned. Year-5 clinic counts should be net figures.

## Market Timing Assessment

**Verdict:** Defensible
**Confidence:** Medium

This is a textbook "why now":

- A specific, dated trigger: April 2025 insurer API mandates.
- A forcing function: email and paper invoicing stopped being accepted.
- Revealed-preference evidence: two thirds of customers signed within three months.

Reversal risk is low, since insurers rarely reinstate paper channels.

The timing issues are about what happens after the trigger:

- **The forced cohort has largely chosen.** A forcing-function trigger creates a short rush, then a long tail of switching from whatever clinics picked in the rush. The plan's year-5 timeline should be built on the switching-market dynamic, not the trigger dynamic.
- **The trigger creates competitors as well as customers.** The same mandate that created demand also gives booking-system vendors a clear reason to build claims modules, and insurers a reason to offer free direct-entry portals for low-volume providers. The plan lists the vendor risk, at about a quarter of SAM if the largest vendor acts, but not the insurer-portal substitute. Responding to either is moat territory (see Out of scope). The market-sizing point is that a 25% SAM contraction is a live scenario, not a tail risk, and the plan should show results with and without it.
- **Concentration in two insurers.** Albion and Crestmoor "together cover most privately insured physiotherapy patients." This makes the trigger strong but concentrated. Any change in their API terms, provider fees, or bundled tooling flows straight through to Claimwell's market.

## Comparable Benchmarks Assessment

**Verdict:** Plausible
**Confidence:** Medium

The comp set is small but well-constructed. It pairs a positive comp (Dentaclaim) with a negative comp (Optiform) and gives a structural reason why physio resembles the first: high insured share and weekly recurring claims. Few plans name their failure case.

Gaps:

- **No denominators.** "About 400 practices in five years" can't be compared with Claimwell's 160 without knowing how many UK dental practices were addressable. Give Dentaclaim's share of its serviceable market, then compare it with Claimwell's 4.5%. Claimwell's absolute target is well below the comp, which looks conservative. If dental's serviceable base was much larger, the share comparison may tell a different story.
- **Stage conditions.** Dentaclaim's 2019 trigger was followed almost immediately by COVID disruption to dental practices. That could have helped (admin outsourcing) or hurt (closures). Either way, its five-year trajectory may not transfer cleanly.
- **Go-to-market match.** How did Dentaclaim expand beyond its first region? That is exactly the step Claimwell's plan leaves unexplained, so the comp could supply the missing mechanism.
- **The negative comp's lesson is under-used.** Optiform's failure was low insured-claim frequency. That is the same variable that should split Claimwell's SAM (see SAM above). Apply Optiform's lesson within physio, not just between physio and optics.
- **One positive comp is thin.** Other insurer-mandate-driven claims tools in the UK or comparable markets would show whether 400 practices is typical or an outlier. A vet-practice insurance-claims tool is one possible example.

## Factual Foundation

No fact-check report was provided. The claims that most need verification, in order of load-bearing weight:

1. **The 55% serviceable rate from trade-association survey data.** All SAM and share figures depend on it. Verify the source, sample, and year, and whether the two conditions were measured jointly.
2. **The April 2025 Albion/Crestmoor API mandate and their combined coverage of "most" insured physio patients.** The whole timing thesis rests on this. Confirm the mandate's scope, any exemptions for low-volume providers, and whether either insurer offers a free direct-submission portal.
3. **Dentaclaim's "about 400 practices in five years" and its addressable base.** This is the only positive comp, and it can't be read without a denominator.

The 6,500-clinic count is also worth sourcing, but it matters less because the plan relies on the 3,575 figure.

## Overall Assessment

**Strongest lens: market timing.** The trigger is specific, dated, hard to reverse, and backed by observed signup behavior. The TAM build is also commendably transparent.

**Weakest lens: SOM, specifically the path from beachhead to national.** The end-state share is modest, but the plan doesn't explain how roughly 124 out-of-region clinics will be acquired. The customer timeline suggests post-trigger signups may be running well below the required pace.

**Most important revision:** Add one table showing monthly net new clinics since April 2025 and the source of each (regional in-person, referral, inbound). Then state the acquisition mechanism for years three to five and the rate it must hit. If the post-trigger rate supports the plan, this table will be the most persuasive evidence in the document. If it doesn't, the revision is either a smaller year-5 target or a named channel, such as a booking-vendor partnership, that changes the rate. Splitting SAM by insured-visit share is the close second.

The plan's candor about scale is a strength. One note on audience, outside the sizing critique itself: a £12.9M serviceable ceiling and £576k year-5 ARR are a fit for angels or revenue-based financing more than for typical seed funds. The plan already seems to know this.

**Out of scope, flagged for sibling skills:**
- Booking-vendor and insurer-portal competitive response belongs to moat critique.
- Profitability at £576k ARR against a £600k raise, and CAC for out-of-region sales, belong to unit-economics critique.
