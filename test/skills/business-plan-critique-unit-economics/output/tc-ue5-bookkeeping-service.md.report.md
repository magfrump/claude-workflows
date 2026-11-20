> ⚠️ **No fact-check report provided.** This critique does not include independent factual
> verification. Checkable numerical claims in the draft (quoted CAC, churn rates, gross-margin
> benchmarks, pricing comps) have not been assessed. For full verification, run the
> `fact-check` skill first or use the `draft-review` orchestrator.

# Unit-Economics Critique: Ledgerly Series A Investment Memo

The memo makes two separate claims, and they deserve very different levels of confidence:

1. **Today's unit economics work.** At 41% gross margin, CAC, retention and payback are healthy and mostly reported honestly.
2. **The valuation case rests on 75% steady-state margin within 24 months.** The memo's own numbers don't support this. Its labour figures, task list and hiring plan each point to something closer to 55–66%.

Most of what follows concerns the gap between those two claims.

## CAC Assessment

**What's solid.** CAC is stated as fully loaded and broken down by channel. That is more disclosure than most Series A memos give. Blended $1,800 matches a 50/50 mix of $1,200 (CPA partners) and $2,400 (paid search), and both channels have been stable for a year.

**Channel-level economics differ a lot:**

| Channel | CAC | Payback at $185 GP | LTV/CAC at $9,250 |
|---|---|---|---|
| CPA partners | $1,200 | ~6.5 months | ~7.7x |
| Paid search | $2,400 | ~13 months | ~3.9x |
| Blended | $1,800 | ~9.7 months | ~5.1x |

**Growth will push blended CAC up.** Getting to 6,000 clients in 24 months requires roughly 5,700 gross adds. That is 3,700 net new clients plus about 2,000 replacements for churn: an average base of ~4,150 clients losing 2% a month for 24 months. That is about 240 new clients a month, versus what the current base suggests is far fewer today.

- **Partner capacity.** The partner channel depends on CPA firms with a stream of too-small clients to refer. That supply is limited by how many partner firms Ledgerly can recruit and keep active, not by spend. The memo does not show that the partner channel can roughly triple its volume.
- **Paid search.** If paid search takes up the slack, it enters a more competitive auction at higher volume. $2,400 is today's marginal cost there, not the marginal cost at 2–3x spend.
- **Funding gap.** At today's blended $1,800, 5,700 gross adds cost about $10.3M. If incremental growth runs mostly through paid search at $2,400 or more, the figure is $12–14M. The memo allocates $7M of the raise to S&M. Gross profit can cover the difference, but the plan should say so.

**Two items to clarify:**
- Do CPA partners get an ongoing revenue share or only a one-time referral fee? An ongoing share belongs in contribution margin, not CAC.
- Does churn differ by channel? Partner-referred clients often retain better. If they do, paid search's real LTV/CAC is below 3.9x.

## LTV Assessment

**The calculation is correct.** LTV is margin-weighted ($185 / 2%), with no expansion assumed. That is appropriate, since flat $450 pricing gives no structural expansion lever. The only simplification is that the figure is undiscounted, which is acceptable at this level of detail.

**The inputs need pressure on three points:**

- **Lifetime is extrapolated.** A 50-month average lifetime is projected from 30 months of cohort data. That is reasonable if the churn curve is flat. Because the base is growing, though, most clients are young, so a blended 2% mostly reflects early-life churn. The memo should show churn by cohort age, especially months 18–30 for the oldest cohorts. 2% monthly churn means about 78% annual retention, which is plausible for SMB services but unverified here.
- **Churn removes the best clients.** Churn from "outgrowing us into a full-time controller" removes clients at the top of the $500K–$5M range. Under flat pricing these are probably the most expensive to serve, so this churn may help margin. The memo should state which way it cuts.
- **Steady-state LTV double-counts the automation bet.** The $16,875 figure applies 75% margin while holding churn at 2%. But clients say the commentary is "the part they value most," and the plan is to cut bookkeeper time per client by two-thirds. If service quality or bookkeeper attention falls, churn is the first place it shows up. Steady-state LTV should be stress-tested at 2.5–3% churn:
  - 2.5% churn gives $13,500.
  - 3% churn gives $11,250.

## Contribution Margin Assessment

The $35 line covers software, bank feeds, hosting and processing. Several per-client costs are missing or unclear:

- **Onboarding and catch-up bookkeeping.** New SMB clients often arrive with messy or months-behind books. Who cleans them up, at what cost, and is it charged? With ~240 gross adds a month, even 10 hours of one-time work per client is a meaningful per-client cost. It should be either amortized into contribution margin or added to CAC.
- **Bookkeeper management and quality control.** $230 equals about $6,440 per bookkeeper per month (28 clients × $230), or about $77K a year. That reads like direct bookkeeper cost only. Team leads, reviewers, training and attrition backfill scale with headcount and probably belong in cost to serve.
- **Inference costs rise with the automation plan.** The next model "uses a larger foundation model and each client's own history." Per-transaction inference cost then grows with transaction volume, which is the same quantity that drives labour savings. The $35 line is held flat in the 75% scenario. It probably should not be.
- **Flat price, variable cost.** A $5M agency and a $500K contractor pay the same $450 but probably differ several-fold in transaction volume, payroll complexity and receipt-chasing. The $230 average hides a range of per-client margins. Some clients are likely unprofitable even today.

**Bottom line.** Realistic contribution margin today is probably a few points below the stated 41%. The bigger issue is the steady-state case, below.

## Payback Period Assessment

**Today: $1,800 / $185 ≈ 9.7 months.** This is healthy for SMB-facing recurring services and well within the 12-month rule of thumb. Given a ~50-month expected lifetime, cumulative cash per client turns positive well before the average client leaves.

**Working capital is manageable.** Acquiring ~5,700 clients over 24 months ties up roughly $10M+ in CAC. Gross profit from an average base of ~4,150 clients at $185 comes to about $18M over the same period, so the business can largely fund its own acquisition before fixed costs. The 10-month payback makes the growth plan capital-feasible without the margin story.

**Risks:**
- Paid-search-heavy growth moves marginal payback toward 13+ months.
- The steady-state 5.3-month figure inherits every weakness of the 75% margin assumption. At a more defensible ~60% margin ($270 GP), payback is about 6.7 months. That is still good, which is worth saying in the memo.

This is the plan's strongest lens.

## Gross-Margin Trajectory Assessment

This is where the investment case and the evidence diverge most.

**The lever.** 75% margin requires labour to fall from $230 to $78 per client, a 66% cut, driven entirely by auto-approval rising from 22% to 80%. The arithmetic ($78 + $35 = $113, so $337 GP) is internally consistent. The assumption underneath it is not.

**Problem 1: categorization would have to be nearly all of bookkeeper time.** Raising auto-approval from 22% to 80% cuts the transactions needing manual review from 78% to 20%. That removes at most ~74% of categorization labour, and only if auto-approved transactions take zero review time. To cut *total* labour by 66%, categorization would need to be about 89% of bookkeeper time. The memo itself lists four other tasks: reconciliation, chasing receipts, payroll and loan entries, and the commentary clients value most. The implied margin depends on how much of the job is really categorization:

| Categorization share of labour | Labour/client | Gross margin |
|---|---|---|
| 30% | ~$179 | ~52% |
| 50% | ~$144 | ~60% |
| 70% | ~$110 | ~68% |
| ~89% (implied by memo) | $78 | 75% |

**Problem 2: the improvement rate would have to jump 15-fold.** The last 12 months moved auto-approval from 18% to 22%, or 4 points. The plan needs 58 points in 18 months. The case rests on a model still being built by two engineers producing a "step change." That may happen, but it is a hypothesis, not a trajectory. A 4-point annual pace says the data-flywheel effect ("every client makes the model better") has been weak so far.

**Problem 3: the memo's own hiring plan contradicts it.** 6,000 clients on 110 bookkeepers is about 55 clients each, not the ~84 that a 3x productivity gain implies. At today's per-bookkeeper cost, 55 clients means about $118 of labour per client, which gives **~66% gross margin**. Delivering 75% would take only ~71 bookkeepers, fewer than today's 82. Either the hiring plan is padded or the margin target is. Investors will see this, so reconcile it before they do.

**Compression vectors the memo doesn't address:**
- **Pricing.** "Prices hold" assumes competitors don't pass their own automation gains through to customers. In a market pitched as "a human bookkeeper at close to software prices," automation savings tend to get competed into lower prices.
- **Wages.** Bookkeeper wage inflation over 24 months.
- **Inference cost.** Rising per-transaction inference cost (noted above).
- **Mix.** Larger, more complex clients take more labour per client.

**The comp set doesn't match.** Pure-software accounting tools at 75–85% sell software that the customer operates. Ledgerly sells an outcome delivered partly by people, including the commentary, which is its stated point of difference. Even at 80% auto-approval, the product stays labour-delivered. The relevant comps are tech-enabled bookkeeping and finance-ops services. That category has a mixed record: at least one well-known venture-backed firm with a similar automation thesis has gone through distress, which deserves a check. Its gross margins have typically sat well below software levels. Arguing for valuation on "steady-state software margin" asks investors to price in an outcome that no comparable company has shown at scale.

## Factual Foundation

No fact-check report was provided. These three claims would benefit most from verification:

1. **75–85% gross margins for "pure-software accounting tools"**, and more importantly what tech-enabled bookkeeping services actually achieve. The valuation rests on which comp set applies.
2. **2% monthly churn** against SMB bookkeeping and accounting-services retention benchmarks, plus Ledgerly's own retention curve by cohort age.
3. **CAC of $1,200 (partner) and $2,400 (paid search)** against SMB financial-services acquisition benchmarks, and whether the partner figure includes any ongoing revenue share.

A fourth item can be checked internally: **a time study of bookkeeper hours by task.** This is the single input that settles whether 75% is reachable.

## Overall Assessment

**Strongest lens: payback and CAC today.** A ~10-month blended payback, fully loaded and channel-separated CAC, and 30 months of cohort data make a fundable services business on today's numbers alone. The memo undersells this by treating 41% as a temporary embarrassment.

**Weakest lens: gross-margin trajectory.** The 75% target requires three things:
- categorization to be ~89% of bookkeeper work, despite four other listed tasks;
- auto-approval to improve ~15x faster than it has;
- a headcount plan that the memo's own hiring numbers contradict, since they imply ~66%.

The comp set used to justify a software valuation doesn't fit the product.

**Most important revision:** rebuild the steady-state margin bottom-up from measured bookkeeper time by task, and make it match the hiring plan. Then present the investment case as a range, roughly 55–66%, with 75% as the upside scenario tied to explicit milestones, such as auto-approval reaching 40% and then 60%, and clients per bookkeeper reaching 40 and then 55.

At 60% margin, Ledgerly still shows ~$13,500 LTV, ~7.5x LTV/CAC and under 7-month payback. A memo that leads with those defensible numbers and treats automation as upside will hold up in diligence far better than one whose valuation depends on a single unproven assumption.
