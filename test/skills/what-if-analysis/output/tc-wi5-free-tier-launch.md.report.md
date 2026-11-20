# What-If Analysis: Ledgerline Solo free tier

**Proposal:** Launch a permanent free tier, Ledgerline Solo (one user, 30 invoices/month, no bank feeds), targeting 40,000 sign-ups and 4% conversion to Studio in six months
**Date:** 2026-11-20
**Upstream critiques:** none

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output. This skill is most powerful when focused on the gaps that critics miss.

**Prior Art Check:** No repository was available, so `docs/decisions/` and `docs/working/` could not be searched. No `[PRIOR CONSIDERATION]` findings are possible. All findings are tagged `[NOVEL]`.

---

## Assumptions Examined

- **Assumption:** Solo users will not put meaningful load on customer support, so support cost can be left out of the financial model.
  - **Source:** implicit. The financial model counts only hosting. "What Solo users get" explicitly gives Solo the in-app **Contact us** button. "Team today" lists 4 agents handling ~900 conversations/month.
  - **If wrong:** redesign. Either the support model for Solo changes or the unit economics do.
  - **Tag:** `[NOVEL]`

- **Assumption:** Solo sign-ups are mostly *additional* demand, not prospects who would otherwise have started a 14-day trial.
  - **Source:** implicit. The Risks section covers Studio→Solo downgrades but not trial→Solo substitution.
  - **If wrong:** redesign. Each substituted prospect moves from a 22% conversion path to a 4% one.
  - **Tag:** `[NOVEL]`

- **Assumption:** 4% of all Solo accounts will have converted by month 6.
  - **Source:** explicit (Summary, Financial model). It conflicts with the stated mechanism, "converting to paid … as their businesses grow," which implies a lag of months.
  - **If wrong:** redesign of the timeline and the day-90 review criteria. Not necessarily a retreat, because conversion may arrive later.
  - **Tag:** `[NOVEL]`

- **Assumption:** Free accounts sending invoices will not harm the email sending reputation that paying customers' invoices depend on.
  - **Source:** implicit. The Abuse mitigation (email verification, CAPTCHA) addresses automated *sign-ups*, not what a verified human does after signing up.
  - **If wrong:** redesign. Outbound invoice sending for Solo needs separate infrastructure, limits, or review.
  - **Tag:** `[NOVEL]`

- **Assumption:** Infrastructure capacity scales with account count, so "25x current accounts" covers 42,000 accounts.
  - **Source:** explicit (Engineering work, "Load testing").
  - **If wrong:** tweak to redesign, depending on where the bottleneck is. The bullet labelled "load testing" appears to describe a sizing calculation rather than a test that has been run.
  - **Tag:** `[NOVEL]`

- **Assumption:** Studio downgrades will be small because Studio customers *average* 70 invoices/month.
  - **Source:** explicit (Risks, Cannibalisation).
  - **If wrong:** tweak. The cap or the feature split can be adjusted, but only before the public launch, not after.
  - **Tag:** `[NOVEL]`

- **Assumption:** A "permanent" free tier can be revised later if the economics don't work.
  - **Source:** implicit. The word "permanent" is in the Summary, while Launch step 3 schedules a day-90 review as though the decision stays open.
  - **If wrong:** full retreat becomes very costly. See the Reversibility Map.
  - **Tag:** `[NOVEL]`

## Consequence Chains

**Outcome 1: 40,000 Solo sign-ups with full product parity, including Contact us**

```
→ First-order: ~40,000 new accounts, 19x the paying base, all with the Contact us button.
  → Second-order: support volume rises well past current capacity. Today the rate is ~900 / 2,100
    ≈ 0.43 conversations per paying account per month, and 4 agents handle ~225 each.
    Illustrative rates:
      - Solo contacts at one-tenth the paying rate: +~1,700/month, nearly 3x today's volume (~12 agents needed)
      - Solo contacts at one-half the paying rate: +~8,600/month, ~10x (~42 agents)
    Free users new to bookkeeping may plausibly contact *more* often than established agencies
    ("is this a tax-deductible expense?"), not less.
    → Third-order: the 3-hour median first response for *paying* customers degrades because the
      queue is shared. Paying-customer churn rises, and that loss is not in the model.
    → Third-order: support escalations pull engineers (11 total) off the roadmap, including
      the entitlement work that still needs iteration after launch.
```

**Outcome 2: Prospects "just start using it" instead of facing a trial clock**

```
→ First-order: prospects who would have started a 14-day trial start Solo instead.
  → Second-order: their conversion path shifts from 22% within ~14 days to 4% over months.
    Each substituted prospect costs ~0.18 expected paid customers, and every conversion
    that does happen arrives later.
    → Third-order: to break even on substitution alone, Solo needs ~5.5 net-new sign-ups
      for every trial it absorbs (22% / 4%). Trial start volume is not in the proposal,
      so this cannot be checked.
    → Third-order: if trial starts fall after launch, day-90 MRR may be lower than the
      flat-trial baseline even while Solo sign-ups look strong. The headline metric
      (sign-ups) and the business metric (MRR) diverge.
```

**Outcome 3: Solo users send invoices to their clients through Ledgerline**

```
→ First-order: up to 1.2M invoice emails/month of new outbound capacity (40,000 × 30),
  available to anyone with a verified email address.
  → Second-order: fake-invoice and phishing operators find an unmetered, reputable sender.
    CAPTCHA does not stop a human creating accounts by hand, and 30 invoices per account
    is plenty for fraud.
    → Third-order: mailbox providers downgrade the sending domain or IPs. Paying customers'
      invoices land in spam, their clients pay late, and they blame Ledgerline. This hurts
      the core value of the product for the existing base.
    → Third-order: Trust & Safety work (reports, account takedowns, abuse review) appears
      with no owner. Growth is 3 people and support is already saturated.
```

## Coupling Analysis

| Coupling | Visible / invisible | Why it matters |
|---|---|---|
| Solo and paying customers share one support queue | **Invisible** (an organizational convention, not a system dependency) | Free-tier volume directly degrades paid-tier service. The decision to give Solo "the same in-app experience" quietly couples the two tiers' service levels. |
| Solo and paying invoices share email sending reputation | **Invisible** (shared resource, probably one sending domain/IP pool) | Abuse in the free tier damages deliverability for paying customers. |
| Trial funnel and Solo funnel draw on the same prospects | **Invisible** (behavioral) | The "Why now" evidence ("prospects expect to just start using it") describes the same people who now start trials. |
| Capacity planning measured in "accounts" | **Visible** in the proposal, but the coupling it hides is **invisible** | Load depends on usage pattern and on peaks (Product Hunt day), not on account count. Background jobs, report generation, and email queues may scale differently from web requests. |
| Entitlements gating every future feature | **Visible** (the 2-sprint entitlement work) | Every future feature now needs a "is this Solo?" decision and tests across three plans. This is an ongoing coupling between roadmap and pricing. |
| Users' financial records and legal record-keeping | **Invisible** (external obligation on users) | Users keep books in Solo that they may need for tax purposes. This couples any future change to Solo with users' legal obligations. See the Reversibility Map. |

## Confidence Inversions

**"Conversions pay for hosting more than four times over by month 6."**
The arithmetic is right ($62,400 / $14,000 ≈ 4.5x), but the comparison is incomplete. Inverted scenario: Solo users contact support at one-fifth the paying rate (≈0.09/month), adding ~3,400 conversations/month. That requires ~15 more agents at current throughput. Fully loaded support salaries for that headcount plausibly exceed the $48,400/month margin over hosting, and the 2% scenario's $17,200 margin certainly does not cover them. Add any fraud-handling cost and any paid-churn loss, and the "still covers hosting twice over" fallback stops being a fallback. **Severity: high.** This is the claim the decision most rests on.

**"Infrastructure is sized for 25x current accounts, so 42,000 is within capacity."**
2,100 × 25 = 52,500, so the headroom is real on paper. Inverted scenario: the 25x figure came from steady-state web traffic, while the Product Hunt launch concentrates thousands of sign-ups (onboarding, sample data creation, welcome emails) into 24–48 hours. A slow or failing launch day is the worst moment for a first impression and hits paying customers too. **Severity: medium.** This is cheap to check with an actual load test of the sign-up and onboarding path.

**"Cannibalisation is small because Studio averages 70 invoices a month."**
An average of 70 can coexist with a large group under 30. A skewed distribution (a few heavy agencies, many light ones) is typical. Inverted scenario: 20% of Studio accounts send fewer than 30 invoices and don't use bank feeds. They see "the same product and the same in-app experience" for free and downgrade. The proposal can check this today by querying the actual invoice-count distribution and bank-feed usage among Studio accounts. **Severity: medium**, depending on the real distribution.

**"4% conversion as their businesses grow."**
Inverted scenario: most Solo users are freelancers or side businesses who never reach 30 invoices or need bank feeds. Conversion is slow and long-tailed, about 1% at day 90 and rising afterward. The day-90 review then concludes failure after the public launch has already passed the reversibility cliff. **Severity: high for decision-making**, because the review checkpoint measures the wrong thing at the wrong time.

## Adversarial Scenarios

1. **Support saturation (realistic worst case, plausibly 20%+ likely).** Solo contact rates come in at a quarter of paying rates. By month 2, with perhaps 15,000 Solo accounts, the queue is roughly 2.5x today's volume. Paying-customer median first response goes from 3 hours to over a day. Paying accounts begin churning, quietly at first. Hiring and onboarding support agents takes months, so the problem outlasts the launch spike.

2. **Invoice-fraud wave (realistic worst case, ~10–20% likely in the first six months).** A small fraud operation uses a few hundred manually created Solo accounts to send fake invoices. A major mailbox provider starts filtering Ledgerline invoice mail. Paying customers report clients not receiving invoices, and engineering diverts to a sending-infrastructure split under pressure.

3. **Funnel substitution plus conversion lag (realistic worst case, ~15–25% likely).** Trial starts drop by half after launch because prospects choose Solo. Solo conversion at day 90 is 1.5%. MRR growth is *below* the flat-trial baseline, support costs are up, and 25,000 users hold permanent free accounts. Leadership must choose between a painful reversal and an unprofitable status quo.

## Reversibility Map

| Timepoint | What reversal requires | Difficulty |
|---|---|---|
| **Soft launch (~1,800 waitlist users)** | Email a small group, offer a discounted Studio plan or extended trial, and give data export. | Low. This is the cheapest point to learn and to stop. |
| **1 week after public launch (week 3–4)** | Thousands of users who joined from a Product Hunt post saying "free forever" now hold real invoices and expenses. Withdrawal is public, newsworthy, and lands in the same channels that drove sign-ups. | High. |
| **1 month after public launch** | Tens of thousands of users keep their books in Ledgerline. Ending or shrinking Solo needs grandfathering or a long sunset, data export tooling, and handling of users who need these records for tax. Competitors can market directly to the displaced users. | Very high. |
| **6 months after public launch** | Same as above, plus partner newsletters and marketing content built on "free," and possibly a reduced trial program that can't be restored quickly. | Very high, roughly flat from month 1. |

`[REVERSIBILITY CLIFF]` **The cliff is the week-3 public launch**, not any later date. Before it, Solo is a small experiment. After it, a "permanent" free tier holding users' financial records can realistically only be grandfathered, not withdrawn. The day-90 review falls about ten weeks *after* the cliff, so it cannot meaningfully decide whether Solo exists. At most it can decide how Solo is tuned.

Note that some adjustments stay cheap even after the cliff: removing Contact us for Solo, lowering the invoice cap for new sign-ups, or separating email sending. Those are tuning levers, not reversals, and they get harder to apply to existing users over time.

## Cost of Success

Suppose everything works: 40,000 Solo users, 1,600 conversions, $62,400 new MRR, no abuse problems. Ledgerline then has 42,000 accounts, of which ~38,400 pay nothing. The free user base is about 18x the paying base and continues to grow.

- **Complexity:** three plans with entitlement checks threaded through invoicing, bank feeds, and reporting. Every feature now needs a plan decision and tests across all three plans.
- **Maintenance:** a permanent obligation to host, secure, back up, and support financial data for tens of thousands of non-paying users. Security incidents now affect 20x as many people.
- **Opportunity:** support hiring and abuse handling absorb money and attention that would otherwise go to paying-customer features. With 11 engineers, even one engineer on free-tier upkeep is 9% of capacity.
- **Optionality:** pricing is anchored at $0 → $39. Any future price change, plan restructuring, or tighter Solo limits now faces a large, vocal, non-paying constituency. The product roadmap gets pulled toward features that free users request, whose needs differ from those of small agencies.

`[SUCCESS COST]` In the success world, the company has become a free-tier operator with a paid product attached. That is a strategic identity change, not just a growth tactic, and the proposal does not frame it as one.

## Findings Summary

1. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Support cost is missing from the financial model. Even modest Solo contact rates multiply support volume several times over on a 4-agent team.
2. `[HIDDEN COUPLING]` `[NOVEL]` A shared support queue means free-tier volume degrades the 3-hour response time for paying customers, a churn risk the model doesn't count.
3. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Trial→Solo substitution: each prospect diverted from a 22% trial path to a 4% Solo path loses ~0.18 expected customers. Solo needs ~5.5 net-new sign-ups per absorbed trial to break even.
4. `[HIDDEN COUPLING]` `[NOVEL]` Free invoice sending shares email reputation with paying customers. CAPTCHA and email verification do not mitigate human-operated invoice fraud.
5. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` 4% cumulative conversion by month 6 conflicts with "as their businesses grow." The day-90 review will likely read a lagging signal as failure.
6. `[REVERSIBILITY CLIFF]` `[NOVEL]` The week-3 public launch of a "permanent" tier holding users' financial records makes withdrawal impractical. The day-90 review comes after the cliff.
7. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Studio cannibalisation is judged on an average of 70 invoices. The distribution and bank-feed usage are unchecked but queryable today.
8. `[SECOND-ORDER EFFECT]` `[NOVEL]` A Product Hunt sign-up spike concentrates load on onboarding and email paths. "Sized for 25x accounts" is a calculation, not a load test.
9. `[SECOND-ORDER EFFECT]` `[NOVEL]` Trust & Safety work (abuse reports, takedowns) appears with no owning team.
10. `[SUCCESS COST]` `[NOVEL]` Permanent entitlement complexity, data-custody obligations for a large non-paying base, and a $0 price anchor that constrains future pricing.

## Recommendations

**Must address before proceeding**

- **Model support cost and decide Solo's support channel.** Add support cost to the financial model under at least three contact-rate assumptions. Then either route Solo to self-serve (help centre, community forum, or a bot) and reserve Contact us for paying plans, or budget and start hiring agents before the public launch. The "not second-class" goal can be met through the product itself rather than human support.
- **Make the soft launch a gated experiment.** Before week 3, measure Solo contact rate, trial-start change, invoice-sending patterns, and early upgrade intent from the ~1,800 waitlist users. Define go/no-go thresholds in advance. This is the last cheap decision point.
- **Protect paying customers' invoice deliverability.** Send Solo invoices through a separate sending domain or IP pool, rate-limit new accounts, and set up an abuse-report path with a named owner.
- **Drop "permanent" from the launch messaging, or be sure it's meant.** If the day-90 review should be able to change Solo, the public promise has to allow it, for example "free plan" without "forever," plus a stated data-export guarantee.

**Worth mitigating**

- Query the Studio invoice-count distribution and bank-feed usage now, and set the cap based on the result rather than the average. Watch signal: Studio→Solo downgrades per week after launch.
- Track trial starts alongside Solo sign-ups, and report net new paid accounts per week as the headline metric, not Solo sign-ups.
- Run a real load test of sign-up, onboarding, and email paths at Product Hunt–level burst rates.
- Redefine the day-90 review around leading indicators (accounts approaching the invoice cap, upgrade-prompt click-through, by cohort) rather than cumulative conversion.

**Acknowledged risks**

- **Steady-state hosting cost** ($0.35/account) is small and well understood. Carrying it is reasonable.
- **Competitive pressure** from rivals' free tiers is real, and doing nothing also has a cost, since trial starts are already flat. That argues for running the experiment carefully, not for abandoning it.
- **Ongoing entitlement complexity** is an accepted cost of any tiered pricing. Accept it knowingly and assign an owner.
