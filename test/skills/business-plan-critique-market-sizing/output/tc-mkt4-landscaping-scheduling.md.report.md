> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Market-Sizing Critique: Plotwise Pre-Seed Plan

## TAM Definition Assessment

**Verdict:** Plausible
**Confidence:** Medium

This TAM section is more disciplined than most. The plan deliberately declines to borrow a top-down figure from the broader field-service software category. Its reason is correct: HVAC and plumbing are one-off repair work, while landscaping is recurring route work. That category-report misfit is the most common way TAM gets inflated, and the plan avoids it. There is no adjacency creep, and the methodology is disclosed. The arithmetic checks out: 96,000 × 45% = 43,200, and 43,200 × 40% = 17,280.

The plan never states a TAM in dollars, so here is the implied figure:

- **Implied bottom-up TAM:** 43,200 two-plus-crew firms × $3,600 = **~$156M** a year.
- **With all 96,000 employer firms:** ~$346M, but the plan correctly excludes owner-plus-truck operators.

Two issues:

1. **The 45% figure is a proxy-mapping assumption, not a measurement.** "Industry payroll data" counts employees, not crews. Getting from employee-count bands to "two or more crews" requires an assumed crew size. Crew sizes vary by season and service mix, and many firms add seasonal labor. This mapping is load-bearing because every downstream number scales linearly with it. The plan should state the employee threshold it used (for example, "≥6 employees ≈ 2 crews") and why.
2. **The flat $3,600 ACV understates the top of the market and overstates the bottom.** A 2-crew firm and a 25-crew firm pay the same price. That makes the dollar TAM a count-of-firms figure in disguise. It also means the plan has no lever to grow the ceiling except firm count.

The real headline is not inflation but **size**. A realistic TAM near $150M and a SAM near $60M (see below) is a ceiling the plan should confront openly in a venture raise. That is a market-sizing finding in its own right.

## SAM Realism Assessment

**Verdict:** Plausible
**Confidence:** Medium

Using a behavioral filter ("already paying for scheduling or invoicing software") rather than size alone is exactly right, and grounding it in 400 sales conversations is better than most pre-seed plans manage. Three problems sit inside that filter, however.

1. **The filter measured is broader than the buying signal described.** The plan says buyers are firms using "a generic calendar plus a separate invoicing tool, and complaining about the gap." The 40% figure, though, counts firms paying for "scheduling *or* invoicing software." That wider set includes firms already on a purpose-built landscaping or field-service tool. Those firms have no gap to complain about; they are competitive displacement targets, a much harder sale.
   - I believe several such tools exist (Jobber, LMN, Aspire, Service Autopilot, WorkWave/Real Green), but I have not verified their landscaping penetration.
   - If even a third of the "already paying" group sits on vertical tools, true SAM falls from ~17,300 to ~11,500 firms.
   - **Action:** split the 400-conversation data into "generic stack," "vertical tool," and "paper." The plan already has this data.
2. **The 40% ratio comes from a biased sample.** The conversations are Texas-only, arrive partly through an association partnership, and involve prospects who agreed to a sales call. Firms that take a software sales call are more software-forward than the population. Applying that ratio nationally likely overstates the behavioral share, especially in regions with different adoption patterns.
3. **The national SAM contradicts the plan's own strategy.** The plan expands only into the Sun Belt "where the season is long enough that companies run crews year-round." It cites Snowline's failure from short seasons as the cautionary tale. Yet SAM and year-5 share are measured against all 17,280 firms nationwide. Northern, seasonal firms are by the plan's own reasoning a churn risk, not a serviceable market. **The relevant SAM is a Sun Belt SAM, which the plan never computes.**

The Texas figure is internally consistent: 1,500 is ~8.7% of 17,280, which is broadly in line with Texas's share of US population. The plan should still confirm that the 1,500 uses the same three filters.

The plan also has the data to show behavioral conversion directly: 58 closes from 400 conversations is 14.5%. If most closes came from the ~160 software-paying prospects, that segment converts at ~35%. Stating this would make the SAM argument much stronger.

**Realistic SAM:** with the vertical-tool exclusion and a Sun Belt restriction, it is plausibly a few thousand to ~8,000 firms, or roughly **$15–30M** in revenue at $3,600. Treat that range as an illustration, not an estimate. The plan needs to compute it.

## SOM Achievability Assessment

**Verdict:** Plausible
**Confidence:** Medium

The share arithmetic is internally correct:

| Milestone | Customers | Share | Check |
|---|---|---|---|
| Year 2, Texas | 400 | 400 / 1,500 = 26.7% | Matches "a little over a quarter" |
| Year 5, national | 900 | 900 / 17,280 = 5.2% | ARR = 900 × $3,600 = $3.24M ✓ |

The beachhead logic is the healthy kind: a named state, an association channel, and a 20–40% wedge share. The problem is the sales-capacity model, which does not match either the plan's history or its own targets.

1. **Observed productivity is far below the assumed rate.**
   - Today: 2 reps, 58 closes in 9 months, so **~3.2 closes per rep per month**, from ~22 conversations per rep per month.
   - Plan: **15 per rep per month**, about 4.7× observed.
   - At the current ~35% close rate within the qualified segment, 15 closes would need ~43 qualified conversations per rep per month. That is roughly double each rep's *total* current conversation volume.
2. **The 15/month figure contradicts the year-5 target.**
   - Four reps × 15 × 12 = **720 new customers a year**. Two full years at that rate alone exceeds the year-5 total of 900.
   - Either churn is very high (unstated), the 15/month figure is not the real assumption, or the real constraint is something other than reps, such as Sun Belt market depth or competition.
   - The plan should say which. As written, the capacity model and the share plan describe two different companies.
3. **The year-2 Texas target is aggressive but reachable.**
   - It needs 342 net new customers in 18 months, about 19 a month.
   - With 4 reps, two of them ramping, that requires ~5–6 per rep per month, roughly 1.5–2× today's rate.
   - That is a credible stretch with the association channel, not a fantasy. It is still 27% of a state's qualified firms, taken from roughly 4% today.
4. **The rest of the Sun Belt is the unexamined piece.** Only 500 customers come from outside Texas over three years. Without a Sun Belt SAM, there is no way to tell whether that is 5% or 15% of the reachable market. There is also no stated association partnership outside Texas to replicate the beachhead channel.
5. **The 900 figure ignores churn.** Whether 900 is gross or net matters for share. The churn rate itself belongs to unit economics.

The most constraining bottleneck is the **expansion path**, not rep count. The plan has a credible Texas wedge and an under-specified second market.

## Market Timing Assessment

**Verdict:** Speculative
**Confidence:** High

All three "why now" claims are persistent trends, not triggers:

- **Smartphones in every crew lead's pocket:** effectively true for roughly a decade.
- **SMB cloud adoption and comfort with monthly software:** true since the early 2010s.
- **Generational handover of family businesses:** real, but gradual and continuous, with no inflection point.

None names a change in the last 1–3 years that made this product viable when it was not before. By the framing test (name the specific change in the last 24 months), this is a trend thesis.

The plan's own evidence also points toward "late" rather than "now":

- If 40% of qualifying firms *already pay* for scheduling or invoicing software, the market is in the early majority, not at the innovator stage.
- That is good news for revealed preference: firms are spending on substitutes today, so this is not category creation.
- But it undercuts "ready for modern software in a way it has not been before." The market adopted modern software years ago. What it may lack is the *right* software for recurring-route work.

**Suggested reframe:** drop the "why now" framing, or replace it with a "why this segment is underserved" argument. For example: horizontal field-service tools are built around one-off jobs, and recurring-route landscaping firms are stitching tools together, as the gap-complaint evidence shows. That argument rests on observed behavior and does not need a timing catalyst.

If a genuine recent trigger exists, name it with dates. Candidates the author could investigate include labor-market shifts affecting crew sizes, recent changes to equipment or fuel costs, or a competitor's pricing change or acquisition that pushed customers off a tool.

## Comparable Benchmarks Assessment

**Verdict:** Plausible
**Confidence:** Medium

The comp set has real strengths. It names one success, one failure-by-absorption, and one outright failure, which is better outcome-conditioning than most plans. Snowline is a genuinely useful negative comp because its failure mode (seasonality) maps directly onto a strategic choice the plan makes (Sun Belt only). The year-5 projection is also *conservative* against the anchor comp:

- Poolroute: 3,000 customers in 8 years, about 375 a year.
- Plotwise: 900 in 5 years, about 180 a year.

Four problems:

1. **The direct comps are missing.** The claim that "three companies have tried to build route-based scheduling for a single outdoor trade" is, I believe, too narrow (unverified). Landscaping-specific and field-service tools that serve landscapers appear to exist and compete for the same "already paying" segment. These are the comps that bound Plotwise's share and pricing, and they are also competitors. The plan should name them, along with their approximate customer counts and price points. The competitive-response dimension belongs to the moat critique.
2. **Yardly is not a comparable.** It was a consumer marketplace with a different buyer, motion, and revenue model. Its failure teaches nothing about B2B scheduling software, and it pads the negative-comp list without informing the projection.
3. **Poolroute's market depth is unstated.** 3,000 customers means something very different if pool service has 20,000 qualifying firms versus 5,000. Without Poolroute's denominator, the comp shows a customer count but not a share benchmark. State Poolroute's implied share and compare it to the 5.2% (or recomputed Sun Belt) share.
4. **Poolroute is cited for pace, not for scale.** The comp's best outcome, about 3,000 customers and profitable, at Plotwise's price would be roughly $11M ARR. Even top-comp performance therefore lands Plotwise as a solid, profitable small software company. That may be the right company to build, but the plan should state it plainly to pre-seed investors rather than let them infer it.

## Factual Foundation

No fact-check report was provided. These claims would most benefit from verification, in priority order:

1. **The 96,000 firms and the 45% two-plus-crew share.** Check the source (likely Census County Business Patterns or BLS data for landscaping services) and the employee-to-crew mapping. Every downstream number scales with these.
2. **The "only three single-trade route schedulers" claim, and the Poolroute and Snowline figures.** Verify the comps' customer counts and outcomes. Separately check whether landscaping-specific competitors exist and at what scale. If they do, the comp set and the SAM filter both need revision.
3. **The 1,500 qualifying Texas companies.** Confirm it was derived with the same size and behavioral filters as the national figure.

The 40% behavioral ratio is internal data, so it cannot be externally fact-checked. Its sampling method (who got a sales call, and how) should be disclosed.

## Overall Assessment

**Strongest lens: TAM and SAM methodology.** The plan refuses an ill-fitting top-down category figure, builds bottom-up, and applies a behavioral filter grounded in its own sales data. It also names a negative comp whose lesson it actually applies. This is a more honest market story than most pre-seed plans.

**Weakest lenses: timing and the capacity model.**

- The "why now" is three decade-long trends.
- The 15-closes-per-rep assumption is about 4.7× observed productivity and contradicts the plan's own year-5 target.

**Unstated headline: the ceiling.** A national SAM near $62M, and probably $15–30M after a Sun Belt restriction and a vertical-tool exclusion, is not a problem the plan needs to hide. But it should be addressed directly. Name the path beyond it (crew-based pricing, adjacent recurring outdoor trades, payments or invoicing revenue) or position the company as capital-efficient rather than venture-scale.

**Most important revision:** rebuild SAM as a **Sun Belt SAM** using the buying signal you actually observe, meaning firms on a generic calendar-plus-invoicing stack and excluding firms already on vertical tools. Then restate year-5 share against that denominator. Everything downstream depends on getting this denominator right: share, ceiling, comp benchmarking, and the size of the opportunity you're asking investors to fund.

**Second revision:** replace the 15/month rep assumption with a model built from your observed ~3.2 closes per rep per month and ~35% close rate within the qualified segment.

You already have the data for both, and using it would turn a credible market story into a defensible one.
