> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Market-Sizing Critique: Tallyroom Investor Memo

## TAM Definition Assessment

**Verdict:** Plausible
**Confidence:** Medium

The memo does several things right. It discloses its method, presents both a bottom-up and a top-down build, and checks that Halvorsen's category fits the product. Halvorsen's category includes capture, matching and scheduling, and excludes expense management and cards. The arithmetic also holds: 64,000 × $38,000 = $2.432B.

The problem is that **the reconciliation compares two different quantities, so the "within 10%" agreement is not corroboration.**

- **The bottom-up figure is a potential-spend number.** It is what the band would spend if every one of the 64,000 companies bought at $38K.
- **The Halvorsen figure is a current-spend number.** It is what companies in the band *already spend* on AP automation in 2025.

By the memo's own SAM section, a large share of the band still matches invoices by hand and spends roughly nothing on the category. If current spend already equals the theoretical 100%-penetration total, one of three things is true:

1. Current buyers pay far more than $38K on average. That would be good news on pricing headroom, but it means the $38K ACV understates TAM.
2. The 64,000 count or the $38K ACV is wrong.
3. Halvorsen defines "spend" more broadly than the memo assumes.

Each possibility changes the story. The agreement should be replaced with an explanation. A clean version would say: "Halvorsen's current spend of $2.1–2.6B comes from roughly N companies already automated, implying $X per buyer. Our bottom-up potential is $Y."

**Second issue: is the ACV representative of the band?** The $38K ACV is averaged over 38 customers. It is then applied uniformly across 64,000 companies with 100–999 employees.

- US firm counts in that band are heavily skewed toward the low end. Most firms in it have 100–250 employees.
- There is an internal check available. A $38K annual fee is about $3,170 a month. If the $2.10 median cost per invoice is all-in, including Tallyroom's fee, the fee alone fits under $2.10 only above roughly 1,500 invoices a month. That suggests current customers sit in the upper half of the stated 800–6,000 volume range. This is an inference, and it depends on whether $2.10 includes the subscription.
- If pricing scales with volume, a band-weighted ACV could be materially below $38K. I would guess $25–30K, which would pull TAM toward $1.6–1.9B.

**Third, the descriptive claim that every company in the band "runs a dedicated AP function and processes 800–6,000 invoices a month" is asserted for all 64,000.** It is plausible for manufacturers and distributors. It is much less plausible for 120-person professional-services firms, which may process a few hundred supplier invoices a month.

**Headline gap:** the $2.43B figure is a reasonable upper bound. A band-weighted bottom-up figure could plausibly be 20–35% lower. The top-down cross-check, as currently framed, cannot tell us which.

## SAM Realism Assessment

**Verdict:** Plausible
**Confidence:** Medium

The segmentation is better than most plans. The second filter, "still match by hand or on a legacy capture tool," is behavioral, not descriptive, which is exactly the right kind of filter. The arithmetic is 0.60 × ~0.58 ≈ 0.35, giving 22,400 companies and $851M.

One small note: 0.35 ÷ 0.60 = 0.583, which is "a bit under 60%" rather than "a little under two thirds." Two thirds would give about 0.40, or roughly 25,600 companies. That is worth tightening so a diligent reader doesn't trip on it.

Issues that matter more:

- **A product-fit filter is missing: purchase-order discipline.** Tallyroom's core function is matching invoice lines against the PO and the goods receipt. A company that doesn't issue POs for most spend, which is common in services-heavy firms, can't use three-way matching. The memo's own negative comp, Capturely, failed because its product "worked only for companies with standardised purchase orders." The SAM should state what fraction of the 22,400 runs PO-backed purchasing at sufficient coverage. Otherwise the most relevant lesson from the comp set is missing from the segment definition. This is the filter most likely to shrink SAM materially.
- **The behavioral-filter source is selection-biased.** "Surveys of our pipeline" sample companies that are already shopping. Half of them are Corvane customers being forced to move. That population over-represents companies in a manual or legacy state. Halvorsen's buyer panel may also skew toward buyers. The ~58% figure should be described as an upper estimate unless it comes from a random sample of the band.
- **Hand-matchers and legacy-tool users should be split.** The two groups behave differently. A hand-matcher is a greenfield sale. A legacy-tool user is a displacement sale with switching cost and an incumbent that will fight. The revenue plan argues that most customers are "replacing a spreadsheet and a shared inbox." The SAM doesn't show that split, so the claim is unsupported.
- **The Corvane cohort may be excluded by the memo's own filter.** The roughly 9,000 Corvane teams on the bundled AP module are using an ERP-native automation module today. Strictly, they are neither "matching by hand" nor on a "legacy capture tool." Either they fall outside the SAM, which would mean the memo's best opportunity isn't counted in it, or the filter is looser than written. The memo should say which, and show how the 9,000 overlap with the 22,400.
- **ACV-segment match.** The ACV concern from the TAM section carries through. $851M assumes the $38K ACV holds across the filtered set.

**Estimated contraction:** with a PO-discipline filter and a debiased behavioral rate, a realistic SAM could land at 40–70% of the stated $851M, or about $350–600M. That is a wide range, and it reflects the fact that the memo gives no data on PO coverage.

## SOM Achievability Assessment

**Verdict:** Inflated
**Confidence:** Medium

**The implied trajectory, from the memo's own numbers:**

| | Customers (at $38K) | ARR | YoY growth |
|---|---|---|---|
| Today | 38 | ~$1.4M | — |
| Year 1 (1%) | ~224 | $8.5M | ~490% |
| Year 2 (2%) | ~448 | $17.0M | 100% |
| Year 3 (3%) | ~672 | $25.5M | 50% |
| Year 4 (4%) | ~896 | $34.0M | 33% |
| Year 5 (5%) | ~1,120 | $42.6M | 25% |

What the table shows:

- **"1% is conservative" is the wrong frame for year one.** Year one is the most aggressive year in the plan. It requires about 186 net new customers in twelve months, against 38 acquired to date. Product superiority on cost per invoice is a reason customers choose Tallyroom once they evaluate it. It does not determine how many evaluations happen. Year-one share is set by distribution capacity, not product quality.
- **The curve is the wrong shape.** Adding one point of share a year produces a near-sextupling followed by steadily decelerating growth (100% → 25%). Real category capture usually accelerates through the middle of an S-curve before flattening. A huge year one could be justified by the Corvane deadline, but only if the memo says that explicitly. As written, the year-one jump is presented as the conservative baseline rather than as a catalyst-driven spike.
- **There is no sales-capacity plan.** About 186 new customers in year one, and about 224 a year after that, implies roughly 6–9 fully ramped AEs. That assumes about 25–30 mid-market deals per rep per year with ERP integration and implementation work; this is my rough assumption, not a figure from the memo. It also implies an implementation and onboarding team scaled to match. The use of funds lists multi-entity product work, a second integration engineering team, and "marketing." It names no sales or implementation hires, and no channel. Paylode, the best comp, grew through ERP resellers. If Tallyroom plans a reseller channel, the SOM needs to say so. If it plans direct sales, the hiring plan is missing. Either way, the funding ask doesn't visibly support the capture rate.
- **The 30-month runway ends partway through year three.** That is roughly $21M ARR on the plan's curve. The memo should say whether the plan assumes a further raise, because the year-four and year-five shares depend on it.
- **The fragmentation argument is partly undercut by the memo's own SAM.** "No vendor holds more than 12%" supports the claim that no single incumbent blocks entry. But the SAM includes legacy-tool users, who are displacement sales. The Corvane cohort will run competitive bake-offs among every certified partner. A 12% leader is also not small: against Halvorsen's $2.1–2.6B, it implies something on the order of $250–300M in mid-market AP revenue, depending on how share is measured. That is a well-funded competitor in exactly the Corvane bake-offs.
- **The beachhead is implied but not named.** The memo has a natural wedge in Corvane switchers, but the revenue plan is expressed as a percentage of the whole SAM. A stronger build would read: "We win X% of the 9,000 Corvane switchers by year one (pipeline win rate Y%), then expand into the other two ERPs."

**Most constraining bottleneck:** sales capacity and channel in year one. Year five's $42.6M is ambitious but not absurd against the comps (see below). The year-one step from $1.4M to $8.5M has no stated mechanism beyond the Corvane deadline.

## Market Timing Assessment

**Verdict:** Plausible
**Confidence:** Medium

This is the memo's strongest section. It names a specific, dated trigger with revealed-preference force: Corvane retires its bundled AP module at end-2026. Roughly 9,000 teams must spend money on a replacement by a fixed deadline. The Corvane partner certification in August 2025 and the 50% pipeline concentration are concrete evidence that Tallyroom is positioned for it. This is a "why now," not a "why ever."

The pressure points:

- **The window may already be mostly spent.** It is now November 2026, and the deadline is about six weeks away. The memo doesn't say when it was written. If it is current, most of the 9,000 teams have either already chosen a vendor or will choose in the next few weeks. In that case, the catalyst largely concludes before or at the start of "year one." The memo needs to say how many Corvane teams remain undecided, how many Tallyroom has won, and its win rate in Corvane deals. If the memo dates from 2025, it should be re-dated and updated before circulating.
- **A forced switch is a one-time land grab, and it cuts both ways.** Teams that pick a competitor during the window are then locked in, and become displacement sales for years. The SOM should treat the Corvane window as a fixed-size cohort with a closing date, not as a contributor to a steady 1%-a-year share line.
- **The trigger is reversible or dilutable in several ways:**
  - Corvane could extend the deadline. That slows the cohort.
  - Corvane could name a preferred partner, which the memo notes it has not done. If it picks someone else, Tallyroom's channel into that cohort weakens sharply. This is the Invoxa failure mode the memo itself cites, in a different form.
  - Certification may not be scarce. If many AP vendors are Corvane-certified, the trigger creates demand but not a Tallyroom advantage.
- **Placement on the adoption curve.** The SAM filter implies that most of the band is still manual or legacy, so this is early majority, not innovator stage. That fits a $38K mid-market sales motion. Pricing and timing look well matched.
- **Beyond Corvane, the timing case is thin.** Apart from the Corvane cohort, the memo gives no reason the other two ERPs' manual-matching customers will buy now rather than five years ago. A second trigger, such as e-invoicing mandates, payment-fraud pressure, or LLM-based extraction accuracy, would make the thesis less dependent on a single catalyst.

## Comparable Benchmarks Assessment

**Verdict:** Plausible
**Confidence:** Low

Credit where due: this is an unusually honest comp set. It names one success (Paylode, $60M in seven years), one stall-and-sale (Invoxa, $18M, sold at about 2× revenue), and one failure (Capturely, under $6M, shut down). It also draws a lesson from them. That is the opposite of cherry-picking.

What's missing:

- **Stage-matched figures.** The memo projects $42.6M at year five but gives Paylode's revenue only at year seven. What was Paylode at year five? If it was around $30M, Tallyroom's plan requires beating the best comp. If it was around $45M, the plan simply matches it. The memo also gives no founding dates for the comps. A company that grew from 2012 to 2019 faced different ERP and capture-technology conditions.
- **The median outcome and how it compares.** Of the three, the median is Invoxa at $18M, which was ultimately a weak exit. The plan's $42.6M is about 2.4× the median and about 70% of the top outcome, reached two years faster. The memo should name what makes Tallyroom the Paylode case rather than the Invoxa case. Candidates include the Corvane catalyst, the cost-per-invoice advantage, and three-ERP coverage.
- **Segment and go-to-market matching.** Paylode's success ran through ERP resellers. Tallyroom's channel is unstated, so the memo doesn't establish that it is following the same playbook.
- **The lesson is applied only halfway.** "Integrate with three ERPs, not one" addresses Invoxa's failure mode. It doesn't address Capturely's: needing standardized POs. As noted under SAM, that is the comp lesson most relevant to Tallyroom's product.
- **The largest incumbent is missing.** The vendor holding about 12% of the mid-market is the most informative comp. Its revenue, age, channel, and Corvane positioning all bear on the plan, and it isn't named.
- **The base rate is still missing.** Three comps is a small sample. Most mid-market AP startups presumably didn't reach $6M. A sentence acknowledging that, and naming one or two more, would make the comp set stronger.

## Factual Foundation

No fact-check report was provided. These claims carry the most weight and would benefit most from verification:

1. **The Halvorsen Group estimate ($2.1–2.6B US AP-automation spend, 100–999 employee band, 2025) and its definition.** In particular, check whether it measures current spend or potential spend, and whether it includes legacy capture tools. This decides whether the TAM reconciliation means anything.
2. **The Corvane facts and their current status.** Check the retirement date and whether it has been extended, the ~9,000 affected teams, whether a preferred partner has since been named, and how many vendors hold the same certification. The whole timing thesis, and much of year-one SOM, rests on this as of today rather than as of mid-2025.
3. **The comp revenue figures and timelines.** These are Paylode ($60M ARR at year seven, and its year-five figure), Invoxa ($18M, sale at about 2×), and Capturely ($40M raised, under $6M ARR). Also verify the 64,000-firm count and the "no vendor above 12%" claim.

## Overall Assessment

**Strongest signal: market timing.** The Corvane retirement is a real, specific, revealed-preference trigger. The certification and pipeline data show Tallyroom is positioned for it. The comp set is also notably honest.

**Weakest signal: SOM achievability.** The revenue plan is written top-down as "1% a year" instead of being built from the things that actually determine capture:

- the size and closing date of the Corvane cohort,
- Tallyroom's win rate in that cohort,
- the sales or channel capacity the round funds.

Year one requires roughly six times today's customer count with no named sales plan. The TAM reconciliation also needs repair. The two numbers agree because they measure different things, not because they confirm each other.

**The single most important revision:** rebuild the revenue plan bottom-up around the Corvane window. That means stating:

- how many of the ~9,000 Corvane teams remain undecided as of today,
- Tallyroom's current win rate in Corvane deals,
- the sales and implementation capacity the $12M buys,
- the resulting year-one customer count.

Then show expansion into the other two ERPs as a separate, slower line. This turns the strongest part of the memo, the timing trigger, into the engine of the revenue plan rather than a side argument. It also replaces "1% is conservative" with a number an investor can check. While making this revision, add a PO-discipline filter to the SAM and give Paylode's year-five figure. Those two changes would close the remaining gaps that diligence is most likely to probe.
