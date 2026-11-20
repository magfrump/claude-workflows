⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Market-Sizing Critique: Tallyroom Investor Memo

## TAM Definition Assessment

**Verdict:** Inflated
**Confidence:** Medium

The memo does several things right. It discloses its method, builds both top-down and bottom-up, keeps scope to the US 100–999-employee band, and checks that the Halvorsen category matches the product (capture, matching and payment scheduling, but not expense or cards). The arithmetic is correct: 64,000 × $38,000 = $2.43B.

The problem is that the two estimates agree for the wrong reason. They measure different things.

- **The bottom-up figure is a ceiling.** It assumes every one of the 64,000 companies buys at $38K. That is total potential spend at full penetration.
- **The Halvorsen figure is actual 2025 spending.** It is what companies in the band already pay for AP automation.
- **If both numbers are right, the market is already fully penetrated at your price point.** That contradicts the SAM section, which says most on-ERP companies still match by hand or on legacy tools. It also contradicts the revenue section's claim that most buyers are "replacing a spreadsheet and a shared inbox."
- **One of three things must be true.** Halvorsen measures something broader than you think. Current adopters pay well above $38K. Or the bottom-up figure is overstated. The "within 10%" agreement is a reason to re-examine both numbers, not a confirmation of either.

There are three reasons to think the bottom-up is overstated.

1. **Not every company in the band fits the profile.** The claim that companies in this band run a dedicated AP function and process 800–6,000 invoices a month is asserted for the whole band. A 120-person software or services firm may process a few hundred supplier invoices a month and have no dedicated AP staff. Headcount does not predict invoice volume.
2. **Not every company uses POs and goods receipts.** Tallyroom's core value is matching invoices against purchase orders and goods receipts. Many mid-market companies, especially in services, don't use either for most of their spend. That is exactly the failure mode the memo attributes to Capturely. No filter in the TAM removes these firms.
3. **$38K may not apply to the low-volume end.** The memo's own numbers hint at this. If the $2.10 median cost per invoice includes the Tallyroom fee, then a $38K ACV implies the median customer processes at least about 1,500 invoices a month ($38,000 ÷ $2.10 ÷ 12). Your current 38 customers may sit in the upper half of the 800–6,000 range. Applying their ACV to 800-invoice firms would overstate TAM. The memo should say whether $2.10 includes the subscription and what ACV looks like by volume tier.

**Revision:** Rebuild the bottom-up by invoice-volume tier, with ACV by tier, and filter for PO-based purchasing. Then reconcile against Halvorsen by splitting it into current spend versus remaining unpenetrated spend. You don't yet have a gap figure. The headline $2.43B could be too high or even too low, but the current reconciliation does not support it.

## SAM Realism Assessment

**Verdict:** Plausible
**Confidence:** Medium

This section is better than most plans. It uses a real behavioral filter (current matching method) alongside a technical one (ERP fit), not just headcount bands. The math checks: 64,000 × 35% = 22,400, and 22,400 × $38K = $851M.

Points to pressure:

- **The arithmetic and the wording don't match.** 35% ÷ 60% means the second filter is about 58%. That is "under three fifths," not "a little under two thirds." This is small, but a reader who notices will start checking every other number.
- **The pipeline survey is a biased sample.** Companies already in your pipeline are not a random draw from the market. They have self-selected for interest in replacing their current process. The Halvorsen panel helps, but the memo should say how much weight each source carries and whether they agree.
- **"Match by hand" includes companies that don't match at all.** Companies without PO discipline aren't doing three-way matching, by hand or otherwise. The SAM needs the same PO filter the TAM is missing. Given the Capturely lesson, this is the filter most likely to shrink SAM materially.
- **Multi-entity customers aren't serviceable yet.** Part of the $12M funds multi-entity support. Companies that need it, which are common near the top of the band, should be excluded from current SAM. Report them as SAM unlocked after the build ships.
- **The Corvane cohort may not be in the SAM.** The memo doesn't say whether the 9,000 finance teams on Corvane's bundled AP module are among the 22,400. If a bundled module counts as "a legacy capture tool," they are. If not, the why-now cohort sits outside the serviceable market. Say which.
- **Payments may add a gate.** Scheduling and executing supplier payments may carry security-review or payments-partner requirements, such as SOC 2 or a money-movement partner. The memo is silent on this. If any segment is gated, carve it out.

A PO-discipline filter and a multi-entity carve-out could plausibly cut SAM by another third or more. That is my estimate, not a measured figure. The structure here is sound, and the inputs are what need tightening.

## SOM Achievability Assessment

**Verdict:** Inflated
**Confidence:** High

This is the weakest part of the market story. Framing the plan as share of SAM hides what the share targets mean in customer counts.

**Year one.** 1% of 22,400 is 224 customers at $38K, or $8.5M ARR. Today you have 38 customers, roughly $1.4M ARR. So "a conservative 1%" in year one means adding about 186 customers and growing ARR about 6× in twelve months. That may be achievable with the Corvane tailwind. It is not conservative, and calling it conservative will cost credibility with any investor who does the division.

**Year five.** 5% is 1,120 customers and $42.6M ARR, so adding about 224 net customers a year with no churn. A 5% share in five years sits at the upper edge of what B2B SaaS typically reaches. The fragmentation argument (no vendor above 12%) helps, but that figure is unverified.

**The share curve has the wrong shape.** Adding one point of share a year is a straight line. Your own why-now is a one-time event with a deadline, which should produce a front-loaded spike in Corvane migrations followed by a slower, ordinary acquisition rate. The plan doesn't model the demand that the plan itself describes.

**The beachhead is named but not used.** The obvious beachhead is Corvane customers forced to switch. Half the pipeline already comes from there. The memo could project a share of those 9,000 (say, 5–10% of migrating teams) and then a separate expansion rate into the other two ERPs. Instead it projects a flat share of the whole SAM.

**The funding doesn't include a sales team.** Use of funds names product work, engineering and marketing, but no sales hiring. Closing about 186 mid-market deals in year one, each with an ERP integration and finance-team approval, would likely need on the order of 6–12 ramped account executives. That assumes roughly 15–30 closes per AE per year, which is a rough benchmark, not data from the memo. This could be a gap in the use-of-funds writeup rather than in the plan itself. Either way, it is the most constraining bottleneck as presented. Paylode, your best comp, grew through ERP resellers, and the memo describes no reseller channel either.

**Revision:** Build the revenue plan from customer counts by source: Corvane migrations, other-ERP new logos, and channel. Tie it to a sales and channel capacity plan that the $12M actually funds. Report the implied share as an output, not an input.

## Market Timing Assessment

**Verdict:** Plausible
**Confidence:** Medium

This is the strongest "why now" a mid-market SaaS plan can offer. It is a specific, recent, dated trigger: Corvane retiring its bundled AP module at the end of 2026, with no preferred partner named. It forces a decision among a defined group of about 9,000 teams. You've already acted on it, with partner certification in August 2025, and pipeline evidence (half from Corvane) suggests it's real. It is also revealed-preference demand, since these teams already use and pay for AP tooling. It isn't category creation.

What needs pressure:

- **The deadline may be nearly here.** The memo doesn't give its date. If it's being circulated now, the end-of-2026 deadline is weeks away, and most of those 9,000 teams have likely already chosen, or are extending on the old module. The memo should state how much of the migration window remains and what share of Corvane switchers Tallyroom has won so far. A five-year plan resting on a trigger that has largely expired needs a second leg.
- **The trigger could reverse or soften.** It rests on one catalyst controlled by one vendor. Corvane could extend the deadline, which ERP vendors often do under customer pressure. It could also name a preferred partner, which would concentrate the migration on someone else. Your strategy and your own Invoxa lesson both say ERP dependence cuts both ways. The timing thesis should acknowledge this risk directly.
- **There is no second trigger.** Nothing in the memo makes the other two ERPs' customers newly ready to buy. After the Corvane wave, timing falls back to a general modernization trend.
- **Adoption stage needs one sentence.** Per the SAM, about 58% of on-ERP firms are still manual or on legacy tools. That suggests modern AP tools are in the early majority. That fits a $38K mid-market sales motion. Saying so explicitly would help.

## Comparable Benchmarks Assessment

**Verdict:** Plausible
**Confidence:** Medium

Credit where due: this comp set includes one success, one stall and one failure, and it draws a lesson from them. That is rarer than it should be and makes the section more credible than most.

The gaps:

- **The plan sits near the top of the range.** The median of the three comps is Invoxa at $18M, then stalled. Paylode, the only clear success, reached $60M in seven years. Tallyroom projects $42.6M in five, which is roughly on Paylode's pace and about 2.4× the median. The memo needs to state why Tallyroom tracks the best outcome rather than the middle one.
- **The best comp grew through a different channel.** Paylode grew through ERP resellers. Tallyroom describes no reseller motion. If Paylode's trajectory depended on that channel, it isn't a like-for-like benchmark until you name your equivalent.
- **The Capturely lesson is drawn selectively.** The memo takes the ERP-dependence lesson from Invoxa. It doesn't address the Capturely lesson: a product that worked only for companies with standardized POs. Tallyroom's core value is three-way PO matching, so this is the most relevant failure mode in the set. The memo should state what share of SAM has the PO discipline the product needs, and what Tallyroom does for the rest.
- **Multi-ERP may not prevent the Invoxa outcome.** Integrating with three ERPs spreads the risk. It doesn't remove the risk that one of the other two launches or bundles an AP module. Ironically, Corvane is doing the opposite right now.
- **Stage and era are missing.** Founding dates and the market conditions behind Paylode's seven-year run aren't given. Without them, it's hard to tell whether those comps faced the same buyer and price environment.
- **The incumbents are missing.** The comps are all startups. The vendors holding up to 12% of the mid-market, and the AP spend Halvorsen counts, are the competitive set the plan will actually meet. Naming them would test the fragmentation claim.

## Factual Foundation

No fact-check report was provided. These are the claims that most need verification, in order of load-bearing weight.

1. **Halvorsen Group's $2.1–2.6B figure and its definition.** Is it current spend or addressable spend? Does it cover the same 100–999 band? Does it include legacy capture tools? Is it a real, citable report? The entire TAM reconciliation depends on this.
2. **The Corvane facts.** Check the retirement announcement, the end-2026 date, the count of about 9,000 affected finance teams, and whether Corvane has since extended the deadline or named a preferred partner. The why-now and the beachhead both rest on these.
3. **The market-structure inputs.** Check the 64,000-company count, the 800–6,000 invoices-per-month range, the 60% share held by the three ERPs, and the 12% maximum vendor share. Add the Paylode, Invoxa and Capturely revenue figures behind the comp-set argument.

## Overall Assessment

**Strongest lenses: Market Timing, then Comparable Benchmarks.** The Corvane retirement is a real, specific, dated trigger with pipeline evidence behind it. The comp set includes negative outcomes and draws a lesson from them. The SAM section is also more disciplined than most, because it uses a real behavioral filter.

**Weakest lens: SOM Achievability.** The share-of-SAM framing makes "1% in year one" sound conservative, when it means about 6× ARR growth and roughly 186 new customers. The straight-line share curve ignores the event-driven shape of your own trigger. And the stated use of funds doesn't include the sales capacity those customer counts need.

There is also a quieter issue in the TAM. The "within 10%" reconciliation compares a full-penetration ceiling with current spend. If both are right, the unpenetrated market the plan depends on doesn't exist.

**The single most important revision:** replace the share-of-SAM revenue plan with a customer-count build anchored on the Corvane beachhead. Show how many of the 9,000 migrating teams you've won or expect to win, and by when relative to the deadline. Add the separate acquisition rate into the other two ERPs. Tie it to a sales and channel plan the $12M visibly funds. That turns the strongest part of the memo, the Corvane trigger, into the backbone of the revenue case instead of a separate section.
