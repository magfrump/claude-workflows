> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Market-Sizing Critique: Claimwell, Market Case for a £600k Seed Round

## TAM Definition Assessment
**Verdict:** Defensible
**Confidence:** Medium

This TAM avoids the usual failures. It is built bottom-up (6,500 clinics × £3,600 = £23.4M, which is arithmetically correct). It does not borrow a research-firm category, does not add future products, and does not include allied-health neighbours such as osteopathy, chiropractic or sports therapy. The plan also checks the price against revealed spend: pilot clinics already paid an average of £380/month for the same work. Most plans never attempt that check.

There is no top-down figure to reconcile against. For a market this narrow that is acceptable, and arguably better, because no honest category report exists for "UK physio claims software."

Three issues are worth tightening:

- **Clinic vs. site counting.** The 6,500 includes "small chains of up to five sites." If a five-site chain counts as one clinic but would buy per site (or the reverse), the clinic count and the price are measured in different units. State which unit the £300 applies to and count in that unit.
- **Flat price across very different clinics.** A sole practitioner who sees few insured patients will not pay £300/month. A busy multi-physio clinic might pay more. The £380 benchmark comes from pilot clinics, which chose to look for a solution and are therefore likely higher-volume than average. It confirms willingness to pay among motivated clinics, not across all 6,500.
- **"Same work" comparison.** Bureaus and part-time admin staff often do more than submit claims. They may chase rejected claims, bill patients for shortfalls, and handle insurer queries. If Claimwell replaces only part of that work, the £380 overstates what clinics would pay for the software alone.

None of these moves the number by an order of magnitude. The TAM is honest. The 6,500 count is the unverified input.

## SAM Realism Assessment
**Verdict:** Plausible
**Confidence:** Medium

The SAM filter is mostly behavioural ("takes insured patients"), which is the right kind. The integration constraint is a real serviceability gate, not a demographic proxy. The arithmetic holds: 6,500 × 55% = 3,575, and 3,575 × £3,600 ≈ £12.9M.

Four questions decide whether 3,575 is the right count:

1. **Joint vs. multiplied probability.** "About 55% of clinics meet both conditions." Did the trade-association survey report the joint figure directly? Or was it built by multiplying the share that takes insured patients by the share on a supported booking system? Multiplying assumes the two are independent. They probably are not: clinics on modern booking systems may skew larger and more insurance-heavy. Say which method was used.
2. **Insured-patient share, not just yes/no.** A clinic where 5% of visits are insured and one where 60% are insured both pass the filter, but only the second will pay £300/month. A threshold such as "insured visits above X% of volume" would likely shrink SAM. That is my main reason this lens is Plausible rather than Defensible.
3. **Already-solved clinics.** The mandate took effect in April 2025, about 19 months ago. Every serviceable clinic that bills insurers has had to choose something: a bureau, admin time, a booking-system add-on, a competitor, or Claimwell. SAM today is therefore not 3,575 clinics with an open problem. It is 3,575 clinics that each already chose a solution, some fraction of whom would switch. That changes the sales motion (see SOM and Timing).
4. **Insurer access as a gate.** SAM assumes Claimwell can submit through Albion's and Crestmoor's provider APIs, and covers the insurers outside "most" of the market. If either insurer must accredit third-party submitters, that accreditation is a serviceability gate like a certification. State whether it is in hand.

The risk section's figure (losing about a quarter of SAM if the largest booking vendor builds its own module) is useful. Treat it as a live sizing scenario. A SAM of about 2,700 clinics (£9.7M) is the downside number to quote alongside 3,575.

## SOM Achievability Assessment
**Verdict:** Plausible
**Confidence:** Medium

**Implied share:** 160 / 3,575 = 4.5%, giving £576,000 ARR at £3,600, as stated. The headline share is not alarming. Benchmarked against Dentaclaim's roughly 400 practices in five years, it looks modest, though that depends on Dentaclaim's denominator (see Comparables).

**The beachhead logic is the plan's best feature.** It names a geography, counts it (about 120 clinics), names the sales capacity (two founders, in person), and targets 30%. Claimwell already has 19 clinics there, about 16% of the beachhead. Reaching 36 means 17 more in two years, which is believable.

The constraint is not the share. It is the **acquisition rate after the April 2025 surge**, together with the **unnamed sales motion for years three to five**:

- **Post-surge rate.** Two-thirds of 23 customers (about 15) signed within three months of the April 2025 switch. If the plan is current, the other ~8 arrived over roughly the following 16 months, about 0.5 clinics per month. Reaching 160 by year five needs about 137 net additions, roughly 27 per year, against an observed post-surge pace of about 6 per year. The plan should show its monthly signups since July 2025. That single number would confirm or undercut the whole projection. (I am inferring dates; if the company launched later than I assume, the rate improves.)
- **Years three to five.** The beachhead reaches 36 clinics through in-person founder selling. The remaining 124 clinics are national, mostly outside visiting range. The plan does not say who sells to them or how: inside sales, booking-vendor partnership, or physio association referrals. That path is the most load-bearing unstated assumption in the plan.
- **Beachhead density looks low.** Greater Manchester plus Yorkshire holds roughly an eighth of the UK population, yet 120 is about 3.4% of the 3,575 SAM. Private physio may genuinely concentrate in the South East, or 120 may be the subset within visiting distance. Either way, explain it. If national density is much higher than the beachhead's, the expansion is easier than it looks. If the 120 is undercounted, the 30% target is softer.
- **Churn.** A booking vendor shipping its own module would cause churn among existing customers, not just shrink the future SAM. The SOM should show a net figure that allows for this.

## Market Timing Assessment
**Verdict:** Plausible
**Confidence:** Medium

This is a real trigger, not a persistent trend. It is a dated, named regulatory-style change: insurers stopped accepting email and paper invoices in April 2025. It is effectively irreversible, since insurers will not return to paper. The plan also offers revealed-preference evidence: two-thirds of customers signed within three months. That is the strongest timing thesis a plan can present.

The problem is that **the trigger was a one-time forcing event, and it is roughly 19 months old.** A forced migration creates a demand spike, and most of it is captured or lost within months. The cohort data in the plan confirms this. That shifts the "why now" in two ways:

- The market has moved from **forced adoption** (clinics must act) to **displacement** (clinics that chose a bureau or admin staff could save money by switching). The £380 revealed spend supports the displacement case. But displacement is a slower, ROI-driven sale with a lower urgency. The plan should restate its timing thesis for that second phase.
- **Too-late risk.** Nineteen months after a mandate is long enough for booking vendors, bureaus and new entrants to respond. The plan names one such risk, booking vendors building their own modules, but not insurer-provided submission portals or other software entrants (see Comparables).

Adoption-curve placement fits the motion: low price, founder-led sales, small clinics. That part is consistent.

Two further triggers would strengthen the thesis if they exist: other insurers following Albion and Crestmoor with their own mandates, or claim-volume growth such as rising private physio uptake. Name them if they exist.

## Comparable Benchmarks Assessment
**Verdict:** Plausible
**Confidence:** Medium

The plan names one positive comp and one negative comp, and explains the mechanism behind the negative one: few optician patients claim on insurance. It then argues on that mechanism (insured share of visits, weekly recurring claims) why physio resembles dental rather than optics. This is better practice than most pitches show.

Gaps:

- **Raw count vs. share.** "About 400 practices in five years" matters only relative to Dentaclaim's serviceable base. State Dentaclaim's share of its SAM and compare it with Claimwell's projected 4.5%. That is the like-for-like test. On raw count, Claimwell's 160 looks conservative. Depending on the dental denominator, the shares may be close.
- **Stage and conditions.** Dentaclaim's five years ran from 2019, which includes COVID-era dental closures. That could have depressed its trajectory, making it a conservative comp, or reshaped it. Say how it should be read.
- **Claim mechanics.** Check whether dental and physio insurance claims share the same structure: per-visit claims vs. plan or capitation arrangements, and how often patients pay directly. The plan's argument relies on claim frequency, so confirm the comp shares it.
- **Outcome after year five.** What happened to Dentaclaim next: plateau, acquisition by a practice-management vendor, or continued growth? That reveals the ceiling and the likely exit. Acquisition by a booking or PMS vendor would also preview the plan's main risk.
- **Missing direct competition.** The plan names no current competitors in UK physio claims. After a mandate this visible, at least bureaus, booking-system add-ons, and possibly insurer portals compete for the same clinics. Name them and show where Claimwell wins.
- **Small set.** Two comps is a thin base. A third data point, such as another allied-health vertical or a non-UK physio claims market, would help.

## Factual Foundation
No fact-check report was provided. The claims that would most benefit from verification, in order of how much they carry:

1. **The 55% joint serviceability figure and its source.** It sets SAM directly. Confirm whether it is a joint survey result or a product of two separate figures.
2. **The Albion/Crestmoor mandate:** its date, its scope, and the claim that the two "cover most privately insured physiotherapy patients," plus whether insurers must accredit API submitters. The timing thesis and SAM both rest on this.
3. **Dentaclaim's ~400 practices in five years, and the size of the dental base it drew from.** The SOM benchmark depends on it.

The 6,500 clinic count and the £380 pilot-spend average are secondary candidates. Overall internal consistency is good: every figure in the plan reconciles arithmetically.

## Overall Assessment
**Strongest:** TAM definition. It is bottom-up, checked against revealed spend, and free of adjacency creep. The comp set (with a negative comp and a stated mechanism) and the beachhead plan are close behind. This is an unusually honest market story.

**Weakest:** the gap between timing and SOM. The trigger is real but in the past. The plan's own cohort data shows most demand arrived in a three-month burst. Yet the five-year projection assumes a steady acquisition rate roughly four times the apparent post-surge pace. It also assumes a national sales motion after year two that the plan never describes.

**The single most important revision:** add a chart of monthly customer signups since launch, split into the April–June 2025 surge and everything after. Then rebuild the year-five SOM from the post-surge rate plus a named sales channel for clinics outside the beachhead. Reframe the "why now" from "clinics are being forced to switch" to "clinics already paying £380/month to bureaus will switch for £300." If the post-surge rate supports the projection, the plan becomes very hard to argue with. If it does not, the honest year-five number is lower, and it is better to say so now than to be found out in diligence.

*Out of scope but worth noting:* whether a £600k raise fits a business projected at £576k ARR in year five is a question of burn, payback and investor fit, not market size. That belongs to `business-plan-critique-unit-economics`. Whether booking-system vendors can be held off as competitors belongs to `business-plan-critique-moat`.
