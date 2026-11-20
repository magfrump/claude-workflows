> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Market-Sizing Critique: Trussline Series A Memo

## TAM Definition Assessment

**Verdict:** Plausible
**Confidence:** Medium

The memo builds the market bottom-up and shows its work: 45,000 general contractors (GCs) in the $10M–$250M revenue band, then 60% that already use software, then 27,000 contractors at $28K average contract value (ACV), giving $756M. That is more transparent than most Series A memos. There is no headline research-firm number to puncture.

The problems are in labelling and in what the number implies, not in inflation.

- **The memo has no TAM.** It names $756M as "both our addressable and serviceable market." Its own inputs give a band-level TAM of 45,000 × $28K ≈ **$1.26B**. The 18,000 contractors without software are a harder sale, not an unreachable one. Collapsing TAM into SAM hides that $500M of headroom. It also means the plan never says what lies beyond the band:
  - contractors above $250M,
  - specialty and subcontractor firms,
  - owners and developers,
  - Canada.

  Investors will ask what the ceiling is. The memo has chosen not to answer.
- **The ceiling question is real.** At $28K ACV, $100M ARR needs about 3,600 customers, which is 13% of the stated SAM. The memo excludes expansion beyond the band "during the period this plan covers." As written, the market supports a good $38M business but only a stretched venture-scale outcome. That may be fine, but the memo should face it directly rather than let the comp table imply $100M+ is the norm.
- **Inputs carrying the load, all unsourced:**
  - "Census and industry-association data" gives the 45,000 count, but the memo does not say which dataset or how revenue bands were assigned. Census counts are usually by establishment and employee size, not firm revenue.
  - It is unclear whether the 45,000 includes residential homebuilders, design-build firms, or construction managers. The memo should state which.
  - The 60% software-adoption figure has no source at all.
- **No top-down cross-check.** There is no top-down figure to reconcile against. A rough check would be useful: total US construction PM and estimating software spend, and the mid-market share of it. If the bottom-up $756M is far above any credible top-down estimate of mid-market spend, the ACV or the count is wrong.

The derivation is sound. The figure is opaque mainly at the input level, and the memo understates its own TAM while staying silent on the ceiling.

## SAM Realism Assessment

**Verdict:** Plausible
**Confidence:** Medium

The memo uses a behavioral filter ("already pays for some PM or estimating software") rather than only descriptive ones. That is the right instinct. Sizing by firm also counts buyers, not users. Four issues remain.

1. **The filter selects for budget, not for intent to switch.** "Pays for some software" includes contractors who are happy with a modern cloud PM tool and have no reason to move. A sharper behavioral filter is available in the memo's own Why Now section: contractors on Keystone or Brickwell on-premise who face end of support. The memo says these two hold "most of the installed base in our band." That cohort is the real near-term SAM, and the memo never sizes it. If "most" means 60–70% of the 27,000, that is roughly 16,000–19,000 forced decision-makers. The memo should state this number and its source.

2. **Product-category mismatch (most important SAM issue).** Keystone Estimator and Brickwell are described as *estimating* suites. Trussline is described as *project-management* software that "connects the estimate, the schedule and the field." The memo does not say whether Trussline replaces the estimating function being sunset or sits beside it.
   - If it does not replace estimating, the forced migration is a forced estimating decision. Contractors can satisfy it by moving to the incumbent's cloud version, or to another estimating tool, without ever evaluating Trussline.
   - In that case the "workflow to replace" is not Trussline's workflow, and both the SAM filter and the timing thesis weaken considerably.

   This needs one explicit sentence in the memo.

3. **The ACV may not represent the band.** The $28K ACV comes from 71 customers, 58 of them in Colorado and Utah. The band spans a 25× revenue range. A $10M contractor and a $200M contractor almost certainly pay very different amounts. The memo should give:
   - the ACV distribution by contractor size, and
   - the size mix of the 27,000 versus the size mix of current customers.

   If current customers skew toward the upper band, $28K overstates the average for a SAM that, by count, skews toward smaller firms.

4. **National SAM versus the plan-period footprint.** The GTM covers Colorado and Utah, then the Mountain West, then Texas and the Southeast. The memo does not commit to national coverage within five years. On a rough population and construction-activity basis, that footprint is perhaps 35–45% of US activity, which means about 10,000–12,000 of the 27,000 contractors. This is my estimate, not verified. The serviceable market within the plan's actual geography is therefore well under half the stated $756M.

The behavioral logic is better than average, but it uses the wrong behavior. Re-sizing around the migration cohort within the plan's footprint would shrink the headline SAM but make it far more credible.

## SOM Achievability Assessment

**Verdict:** Plausible
**Confidence:** Medium

**Implied share.** $38M ÷ $28K ≈ 1,350 customers, which is 5.0% of the 27,000 SAM in five years. That sits at the upper edge of what B2B vertical SaaS usually reaches; 1% in five years is typically excellent. Against the plan-period footprint estimated above, the implied share is **roughly 11–14%**. The memo calls this "deliberately conservative." The share math does not support that label. A forced-migration event is the kind of disruption that can justify above-normal share, but the memo should say that this is the argument, rather than describe the plan as cautious.

**The beachhead is the strongest evidence in the memo.** Colorado and Utah are perhaps ~3% of US construction (my rough estimate). That would mean about 1,350 contractors in the band there, and about 800 using software. Fifty-eight customers would then be about 7% of the software-using beachhead. This is real, observed share in a wedge. The memo should state it explicitly, with the time it took to achieve. It is a better benchmark for the plan than any of the comps.

**The expansion path is named but not argued.** The beachhead advantages are:
- founder networks from running operations at a regional contractor, and
- referrals from regional association chapters.

Neither transfers automatically to Texas or the Southeast. The plan needs share-by-region assumptions showing what share it expects outside the founders' home market, and why.

**Sales-capacity check.**
- 3.5 closes per rep per month is 42 a year.
- About 1,280 net new customers would need about 30 ramped rep-years.
- 12 reps hired early, growing to 22 by year four, produces more than 30 ramped rep-years. If the close rate holds, capacity is not the binding constraint.

Two caveats:
1. The 1,350 is an ending count. The memo gives no churn assumption, so gross adds must exceed 1,280.
2. The 3.5 rate was measured in the beachhead, with founder relationships and association referrals. If it falls by half outside Colorado and Utah, which is plausible for cold markets, capacity tightens quickly.

The most constraining bottleneck is **demand conversion outside the beachhead**, not rep count. The plan has no data on it.

**Competitive density.** The memo names Keystone and Brickwell as incumbents but does not discuss how they might respond, for example by discounting migration or extending deadlines. The timing lens covers the risk to the trigger. How Trussline defends against that response belongs to the moat critique.

## Market Timing Assessment

**Verdict:** Plausible
**Confidence:** Medium

This is the best "why now" structure in the memo, and better than most. It names a specific, dated trigger: two dominant incumbents announced in 2025 that on-premise support ends by the end of 2026, with roughly doubled cloud pricing. It is a trigger, not a trend, and the revealed-preference test passes because these contractors already pay for software. Four issues still need addressing.

1. **The window may be closing as the round raises.** Today is November 2026, so the stated deadline is about six weeks away. Many affected contractors will already have signed migration or replacement contracts during 2025–26. The 12 reps the Series A funds will need six months to ramp, so they reach full productivity in mid-to-late 2027, after the forced decision point. The memo should say:
   - what share of the affected installed base has already decided,
   - what Trussline won during the window, and
   - why the opportunity persists after the deadline.

   Possible reasons it persists: contractors running unsupported software, deadline extensions, or dissatisfaction after migration.

2. **End-of-support is not end-of-function.** On-premise software usually keeps running after support ends. Contractors can delay, and many will. The trigger creates pressure, not a hard cutoff. The memo should not treat it as a guaranteed decision for "most mid-size contractors."

3. **The trigger is a single catalyst and can be reversed.** Either vendor can:
   - extend the deadline,
   - discount the migration, or
   - offer a lock-in deal to keep its base.

   Incumbents facing defection often do one of these. The thesis currently rests on one catalyst. The memo should identify a reinforcing trigger, such as owner-side pressure for faster change-order billing or labor-market pressure on project-management staff, or else acknowledge single-catalyst risk.

4. **The estimating-versus-PM gap** (see SAM) applies here too. A forced estimating decision is a timing trigger for Trussline only if Trussline is a credible answer to that decision.

The memo also omits that this is a one-time event. After the migration wave, the next forced-choice moment is years away. The memo's five-year SOM likely relies heavily on years 1–2 wins, and the revenue curve should reflect that concentration.

## Comparable Benchmarks Assessment

**Verdict:** Inflated
**Confidence:** High

The comp set is the weakest part of the market story. It is used to make the plan look conservative, but it cannot support that conclusion.

- **The selection method guarantees survivorship bias.** "The three names most often mentioned by the contractors we sell to" selects for the companies that won. Contractors do not mention the construction software startups that failed. All three comps passed $100M ARR, which implies a 100% success rate. The memo names no negative comps. Construction tech has a long tail of failed, stalled, or acquired-for-parts PM and field-management startups, and the memo should name several and say which failure modes Trussline avoids. Common ones are long sales cycles, field-adoption failure, and low ACV ceilings.
- **The comps imply a different market.** At Trussline's $28K ACV:

  | Comp | Year-5 ARR | Implied customers at $28K ACV | Share of Trussline's SAM |
  |---|---|---|---|
  | Buildgrid | $110M | about 3,900 | 14% |
  | Sitework | $140M | about 5,000 | 18.5% |
  | Punchlist Pro | $104M | about 3,700 | 14% |

  Almost certainly, the comps reached $100M+ by:
  - selling at much higher ACV,
  - selling to a broader market (enterprise GCs, subcontractors, owners, residential, international), or
  - both.

  If so, they are not segment-matched, and their absolute ARR says nothing about what is achievable in a $756M mid-market SAM. The memo should state each comp's segment, ACV, and customer count.
- **Comparing absolute ARR across different market sizes is invalid.** "A third of the average year-five ARR" and "half the pace of the category leaders" compare absolute ARR across markets of different size. The correct comparison is **share of a comparable addressable market at year five**. On that basis, the plan's 5% national share (11–14% in its footprint) may well exceed what the comps reached in their own markets.
- **One comp rode an unrepeatable tailwind.** The memo itself notes that Sitework's fastest growth came during the 2020–21 construction surge and the site-access shift to remote collaboration. Keeping it in the average without adjustment imports a tailwind that will not recur.
- **The founding years may not match today's conditions.** Comps founded in 2012–2017 sold into a less crowded construction-tech market. A 2026 entrant faces established cloud incumbents.

The comp set is a list of successes, not a benchmark. As used, it inflates the plan's apparent conservatism.

## Factual Foundation

No fact-check report was provided. These claims would most benefit from verification, in order of how much of the market story they carry:

1. **The Keystone/Brickwell end-of-support claims.** These are:
   - the 2025 announcements,
   - the end-of-2026 deadline,
   - "roughly twice the old maintenance price," and
   - "most of the installed base in our band."

   The entire timing thesis and the sharpest version of the SAM rest on these. The memo should also confirm whether any deadline has been extended.
2. **The 45,000 GC count and the 60% software-adoption rate.** These two inputs define the SAM. The memo needs the specific dataset, how revenue bands were assigned, and which contractor types are included.
3. **The comp figures.** The year-5 ARR figures for Buildgrid, Sitework, and Punchlist Pro, together with each company's segment, ACV, and customer count. The ARR figures matter less than whether these companies sold to the same buyer.

The 1.8% unbilled-change-order figure is a value-proposition claim rather than a market-sizing one. If it reflects a one-time backlog catch-up in the first 90 days rather than a recurring rate, it bears on ACV durability and belongs to the unit-economics review.

## Overall Assessment

**Strongest signal: Market Timing.** It names a specific, dated, revealed-preference trigger. Close behind is the bottom-up build in TAM Definition, which is transparent. Few Series A memos have either.

**Weakest signal: Comparable Benchmarks.** A survivorship-selected set of three companies in what appear to be larger markets is used to call a 5% share plan "conservative." That framing is the most likely thing to cost the memo credibility with a careful investor. The plan's own beachhead data (about 7% of software-using contractors in Colorado and Utah, on my rough estimate) is a far better benchmark, and the memo leaves it unused.

**The single most important revision: rebuild the SAM and SOM around the migration cohort.** Specifically:
1. State how many contractors in the band, within the plan's five-year geographic footprint, run Keystone or Brickwell on-premise.
2. State plainly whether Trussline replaces what is being sunset.
3. Show what share of that cohort has already decided, given the December 2026 deadline.
4. Project capture as a share of the remaining cohort, benchmarked against the beachhead share already achieved.

The result will be a smaller headline number than $756M, but it will be defensible. It turns the memo's best asset, a real and dated trigger, into the center of the market story instead of a separate section. Then address the ceiling question directly: what market lies beyond the band once the migration wave has passed.

*Out of scope:* the defensibility of Trussline against incumbent migration discounts, and whether field-team and association-referral distribution scales beyond the founders' region, belong to `business-plan-critique-moat`. ACV durability, churn, and rep-productivity economics belong to `business-plan-critique-unit-economics`.
