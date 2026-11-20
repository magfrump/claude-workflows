# What-If Analysis: Ledgerline Solo free tier

**Proposal:** Launch a permanent free tier, "Ledgerline Solo" (1 user, 30 invoices/month, no bank feeds). Target: 40,000 sign-ups in 6 months, 4% conversion to Studio.
**Date:** 2026-11-20
**Upstream critiques:** none

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output. This skill is most powerful when focused on the gaps that critics miss.

**Prior Art Check:** No repository was available, so `docs/decisions/` and `docs/working/` could not be searched. No prior consideration is cited, and all findings are tagged `[NOVEL]`.

---

## Assumptions Examined

**A1. Support load from Solo users is negligible enough to leave out of the plan and the model.**
- **Source:** Implicit. Solo users get the in-app **Contact us** button ("What Solo users get"). The Financial model and Engineering sections contain no support line, and the Team section lists 4 agents with no planned change.
- **If wrong:** Redesign. This is the most load-bearing assumption in the proposal (see Consequence Chain 1).
- **Tag:** `[NOVEL]`

**A2. Conversions arrive by month 6 at 4% of all 40,000 sign-ups.**
- **Source:** Explicit (Financial model). This contradicts the stated mechanism, which is converting "as their businesses grow."
- **If wrong:** Tweak to redesign. The headline MRR number is probably overstated for month 6, though not necessarily for month 24.
- **Tag:** `[NOVEL]`

**A3. Solo adds new demand rather than replacing trials.**
- **Source:** Implicit. The model counts all conversions as new MRR. It does not say whether the 14-day trial continues, or what share of prospects who would have trialled (22% conversion, including some to Agency at $99) now take Solo (4% conversion, modelled only to Studio at $39).
- **If wrong:** Redesign. Net new MRR could be much smaller than gross, or negative.
- **Tag:** `[NOVEL]`

**A4. Cannibalisation is small because Studio customers *average* 70 invoices a month.**
- **Source:** Explicit (Risks). An average tells us nothing about how many Studio accounts sit under 30 invoices and don't use bank feeds. Those accounts are the real downgrade population.
- **If wrong:** Tweak. Downgrade rules or a grandfathering policy are needed.
- **Tag:** `[NOVEL]`

**A5. Abuse means automated sign-ups, and email verification plus CAPTCHA mitigate it.**
- **Source:** Explicit (Risks). The proposal ignores the misuse of the product itself. A free tool that emails invoices to arbitrary recipients from Ledgerline's infrastructure is a ready-made phishing and invoice-fraud vehicle.
- **If wrong:** Redesign. This needs sending limits, content and recipient controls, and domain separation.
- **Tag:** `[NOVEL]`

**A6. Infrastructure capacity is sized in accounts, and Solo accounts load the system like current accounts.**
- **Source:** Explicit (Engineering: "sized for 25x current accounts"). 25 × 2,100 = 52,500. The planned 42,100 total uses about 80% of that capacity, so the headroom is about 20%, not "within capacity" in any comfortable sense.
- **If wrong:** Tweak. Plan load testing and a scaling plan.
- **Tag:** `[NOVEL]`

**A7. Free users are an early version of the target customer (small agencies).**
- **Source:** Implicit. Solo is single-user, which is a freelancer product, while Ledgerline sells to agencies. The 4% assumes freelancers grow into multi-person agencies at a meaningful rate within the horizon.
- **If wrong:** Redesign of the targeting or the conversion path (for example, a Solo → paid single-user plan).
- **Tag:** `[NOVEL]`

**A8. Day 90 is an adequate first checkpoint.**
- **Source:** Explicit (Launch plan step 3).
- **If wrong:** Tweak. Support and abuse failures show up in weeks 1 to 4, long before day 90.
- **Tag:** `[NOVEL]`

---

## Consequence Chains

**Chain 1: Sign-ups hit target, and the support queue absorbs them.**

Current rate: 900 conversations ÷ 2,100 accounts ≈ **0.43 conversations per account per month**, about 225 per agent per month.

```
→ First-order: 40,000 Solo accounts by month 6, each with a Contact us button
  → Second-order: support volume multiplies.
      At 1/10 of the paying rate:  ~1,700 extra/month  (~2.9x today's total)
      At 1/4 of the paying rate:   ~4,300 extra/month  (~5.8x)
      At the same rate:            ~17,100 extra/month (~20x)
    New, often non-accountant users asking "how do I do bookkeeping" questions
    makes the higher end more plausible, not less.
    → Third-order: with 4 agents and one shared queue, the 3-hour median first
      response becomes days. Paying Studio/Agency customers, who generate all
      current revenue, get worse service, and paid churn rises.
    → Third-order (alternative): the team hires to hold SLAs. At ~225
      conversations/agent, the 1/4-rate scenario needs ~19 more agents. At any
      plausible loaded cost, that costs more than the $62,400 projected MRR,
      which flips the financial model's conclusion.
```

**Chain 2: Free invoicing works as intended.**

```
→ First-order: thousands of new accounts send invoice emails to their clients
  → Second-order: Ledgerline's sending domain/IP now carries traffic from
    unvetted users, including fake-invoice and phishing campaigns, which
    pass CAPTCHA easily because humans run them
    → Third-order: sender reputation drops; paying customers' invoices land
      in spam; their clients pay late; paying customers blame Ledgerline.
      Invoicing reliability is the core product, so the damage hits where
      it matters most.
    → Third-order: Ledgerline's brand appears in fraud reports, with support
      and legal load on top.
```

**Chain 3: Free tier replaces the trial as the default entry point.**

```
→ First-order: prospects "just start using it" with no trial clock
  → Second-order: people who would have trialled (22% → paid, some to Agency)
    take Solo instead (4% → Studio), and nothing forces them to decide
    → Third-order: paid acquisition from the core agency segment falls even as
      the headline sign-up count rises. The dashboard shows success while
      revenue growth slows.
    → Third-order: the product roadmap is pulled toward the vocal majority
      (solo freelancers), away from multi-user agency features.
```

---

## Coupling Analysis

| Coupling | Visible / Invisible | Notes |
|---|---|---|
| **Shared support queue** between Solo and paying accounts | Invisible (operational convention) | "Same in-app experience" means Solo tickets land in the same queue as paying ones. No plan-based routing or priority is mentioned. `[NOVEL]` |
| **Shared email sending reputation** for invoice delivery | Invisible (shared resource) | Every customer's deliverability depends on the worst sender on the platform. `[NOVEL]` |
| **Trial funnel ↔ free tier** | Invisible (behavioural) | The proposal does not say whether the 14-day trial survives or how the sign-up flow presents the two options. The trial's 22% conversion is the existing revenue engine. `[NOVEL]` |
| **Capacity planning ↔ account count** | Visible (infra sizing) but mis-measured | Capacity is expressed in accounts, while actual load comes from requests, background jobs, PDF generation and email. A bot wave or a Product Hunt spike stresses those, not the account count. `[NOVEL]` |
| **Financial data custody ↔ account lifecycle** | Invisible (regulatory/contractual) | Bookkeeping records carry user expectations, and often legal ones, of multi-year retention and export. That couples Solo to long-term storage, security and compliance obligations regardless of whether the account is active. `[NOVEL]` |
| **Plan entitlements ↔ existing Studio accounts** | Visible (billing) | Low-volume Studio accounts without bank feeds can self-downgrade unless the entitlement work also defines downgrade rules. `[NOVEL]` |

---

## Confidence Inversions

**"Conversions pay for hosting more than four times over."**
Hosting is the only cost the model counts. Invert the claim's completeness and assume the real marginal costs are support, email, fraud handling, and payment-flow churn. Suppose Solo users contact support at a quarter of the paying rate, and assume any realistic loaded agent cost. Support alone exceeds $62,400/month, and the tier is cash-negative. The 2% downside case ("still covers hosting twice over") then becomes a clearly loss-making case. The confidence comes from leaving out the largest cost line. `[NOVEL]`

**"Studio customers average 70 invoices, so cannibalisation will be small."**
Consider a plausible distribution: a long tail of 200-invoice agencies pulls the mean to 70 while 20–30% of Studio accounts send fewer than 30 a month. If even half of those don't use bank feeds, 5–15% of the Studio base, roughly 100–300 accounts at $39, has a direct reason to downgrade. That costs about $4k–12k/month, against gains that arrive slowly. The data to check this already exists internally. `[NOVEL]`

**"42,000 accounts is within capacity."**
Suppose 40,000 legitimate accounts arrive alongside a bot wave that gets past CAPTCHA, plus Product Hunt concentrating sign-ups into a few days. Account-count headroom of about 20% is thin. Load testing is listed as an engineering task, but its result is asserted in advance ("is within capacity"), so it reads as a formality. `[NOVEL]`

**"Day 90 review."**
If support or deliverability breaks, it breaks within 2–4 weeks of the public launch. A 90-day checkpoint is also too early to judge conversion "as businesses grow." The proposal ends up checking the wrong things at the wrong time. `[NOVEL]`

---

## Adversarial Scenarios

**1. Product Hunt succeeds too well (realistic, maybe 15–20% likely).**
Week 3 brings 8–12k sign-ups in a few days, mostly tire-kickers. Support volume spikes 3–5x within a week. With no triage, paying customers' median first response stretches from 3 hours to 1–2 days during the most visible week of the company's year. Recovery takes weeks, and some Agency-tier customers churn quietly.

**2. Fraudsters discover free invoicing (realistic, 10–20% within six months for any free invoicing tool).**
A few hundred human-created accounts send fake invoices that impersonate real vendors. Mailbox providers throttle or junk Ledgerline's sending domain. Paying customers report that their clients "never got the invoice." Fixing this means emergency work on sending limits, domain separation and account review, which takes engineers off the conversion roadmap.

**3. Conversion is both slow and low (realistic, 20%+).**
By month 6, cohort-adjusted conversion is around 1–1.5%, because most accounts are under 3 months old and many are abandoned. That yields about 400–600 conversions and $16k–23k MRR, some of it from people who would have trialled anyway. Hosting is still covered, but the support and fraud costs from scenarios 1 and 2 are not. The tier is publicly promised as "permanent."

---

## Reversibility Map

| Timepoint | What reversal requires | Difficulty |
|---|---|---|
| **Soft launch (waitlist, ~1,800)** | Email a small known group, offer a discounted Studio plan or a long trial, and export or keep their data. | Easy |
| **⚠️ Cliff edge: public launch, week 3** | "Permanent" free tier publicly announced on Product Hunt and partner newsletters. After this point, withdrawal is a public breach of promise covered in the same channels. | — |
| **1 month** | ~10–15k accounts holding real financial records. Reversal needs a grandfathering policy, data export, notice periods, and reputational management with partners who promoted it. | Hard |
| **6 months** | ~40k accounts, many with half a year of books and tax-relevant records. Users have built workflows and sent clients links. Competitors would use a withdrawal in their marketing. Realistic options shrink to tightening limits rather than removal, and every tightening reads as a takeaway because Solo was explicitly "not second-class." | Very hard |

**Reversibility cliffs:**
- **The word "permanent," combined with a public launch.** `[NOVEL]`
- **Financial data custody.** Once users keep their books in Ledgerline, retention and export obligations persist even if the tier ends. `[NOVEL]`
- **"Same experience as paying customers."** This makes any later restriction, such as removing Contact us, feel like a downgrade. The cheapest time to set Solo's support boundaries is before launch. `[NOVEL]`

---

## Cost of Success

Suppose everything works: 40,000 Solo accounts, 4% conversion, and $62,400 new MRR by month 6.

The company now hosts financial data for about 42,000 accounts, 95% of whom pay nothing, and owns that data's security and retention indefinitely.

- **Complexity cost:** the support org must now run two service tiers, with routing, a self-serve or community channel, and SLAs by plan. Engineering maintains entitlements, downgrade rules, sending limits and fraud review.
- **Maintenance cost:** fraud and deliverability become permanent operational duties. Every new feature needs a decision about whether Solo gets it.
- **Opportunity cost:** 3+ sprints, realistically more once routing and abuse controls are added, out of an 11-engineer team. Growth's three people focus on top-of-funnel volume rather than agency-segment acquisition.
- **Optionality cost:** pricing freedom shrinks. A permanent free anchor plus "not second-class" positioning makes it harder to raise Studio prices or move features up-tier. The product's centre of gravity drifts toward freelancers. `[NOVEL]`

Compared with today, the business is busier, more exposed, and more operationally fragile, even with its revenue goal met. The question is whether $62k MRR is worth that, or whether a time-unlimited but feature-capped trial would capture most of the "just start using it" benefit for less.

---

## Findings Summary

1. `[UNEXAMINED ASSUMPTION]` `[SECOND-ORDER EFFECT]` `[NOVEL]` **Support load is unplanned and unpriced.** At 0.43 conversations/account/month today, even a quarter of that rate from 40k Solo users adds about 4,300 conversations/month (about 5.8x current volume) to a 4-agent team. Either paying customers' SLAs collapse or hiring costs exceed projected MRR. **Severity: high.**
2. `[HIDDEN COUPLING]` `[NOVEL]` **Solo and paying users share one support queue**, so Solo volume directly degrades service for revenue-generating accounts. **Severity: high.**
3. `[HIDDEN COUPLING]` `[UNEXAMINED ASSUMPTION]` `[NOVEL]` **Free invoicing is a fraud and phishing vector**, and paying customers share its sending reputation. CAPTCHA does not address human-operated abuse. **Severity: high.**
4. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` **The financial model counts only hosting.** Support, email, fraud, and cannibalisation are absent, so the "4x" and "2x" coverage claims don't hold. **Severity: high.**
5. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` **4% of cumulative sign-ups by month 6** ignores cohort age and abandoned accounts, and contradicts the "as businesses grow" mechanism. **Severity: medium.**
6. `[SECOND-ORDER EFFECT]` `[NOVEL]` **Trial displacement.** Prospects who would have trialled (22%) take Solo (4%), lowering net MRR and Agency-tier mix. The trial's fate is unspecified. **Severity: medium to high.**
7. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` **The cannibalisation argument uses a mean.** The relevant figure is the count of Studio accounts under 30 invoices without bank feeds. **Severity: medium.**
8. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` **Capacity headroom is about 20%, not "within capacity,"** measured in accounts rather than load. Load testing is asserted, not done. **Severity: medium.**
9. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` **Segment mismatch.** A single-user free tier attracts freelancers, not small agencies. **Severity: medium.**
10. `[REVERSIBILITY CLIFF]` `[NOVEL]` **The public "permanent" launch in week 3** turns a reversible experiment into a public commitment. **Severity: high.**
11. `[REVERSIBILITY CLIFF]` `[NOVEL]` **Financial data custody** creates retention and export obligations that outlive the tier. **Severity: medium.**
12. `[REVERSIBILITY CLIFF]` `[SUCCESS COST]` `[NOVEL]` **"Not second-class" positioning** makes any later restriction, such as of support access or features, a visible takeaway. **Severity: medium.**
13. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` **The day-90 review is mistimed.** It is too late for operational failures and too early for growth-driven conversion. **Severity: medium.**
14. `[SUCCESS COST]` `[NOVEL]` **Ongoing costs even under full success:** two-tier support ops, permanent fraud and deliverability duty, reduced pricing freedom, and roadmap drift toward freelancers. **Severity: medium.**

---

## Recommendations

**Must address before proceeding:**
- **Decide Solo's support model before launch (findings 1, 2, 12).** Route Solo to the help centre plus a deprioritised or async channel, or a community forum, with plan-based queue routing so paying SLAs are protected. Build in the routing logic. Change "same experience" to "same product, self-serve support." If the team insists on full support parity, add a support-cost line to the model with a contact-rate assumption and a hiring plan.
- **Rebuild the financial model with all marginal costs (findings 4, 5, 6).** Include support, email, and fraud costs. Use cohort-based conversion curves on *active* accounts, an explicit assumption about trial displacement, and expected downgrade revenue loss. Present a downside case that includes these costs.
- **Add invoice-sending abuse controls (finding 3).** These include per-account send limits for new Solo accounts, recipient and volume anomaly detection, a separate sending domain or IP pool for free-tier mail, and a takedown process. This work is not in the current 3-sprint estimate.
- **Don't say "permanent" at public launch (finding 10).** Launch as "free plan" with terms that reserve the right to change limits. Treat the waitlist soft launch as a real gate with explicit go/no-go criteria: support contacts per Solo account, abuse reports, and deliverability.

**Worth mitigating:**
- **Pull the Studio invoice distribution (finding 7)** and define downgrade rules, such as requiring a cooling-off period or keeping existing accounts on their plan. Watch signal: Studio → Solo downgrades per week.
- **Actually run the load test (finding 8)** against request and job load, including a Product Hunt spike profile and a bot burst. Have a scaling plan ready before week 3.
- **Decide the trial's fate explicitly (finding 6).** Consider keeping a full-feature trial for multi-user or agency sign-ups alongside Solo, and A/B the entry flow. Watch signal: trial starts and Agency-tier new MRR after launch.
- **Add weekly leading indicators from day 1 (finding 13).** Track support volume by plan, first-response time for paying accounts, abuse flags, and spam-placement rate. Move the conversion review to cohort analysis at months 3, 6 and 12.
- **Consider a Solo → paid single-user plan (finding 9)** so freelancers have a conversion path without needing to become agencies.

**Acknowledged risks:**
- **Hosting cost ($14k/month at target).** This is genuinely small and well understood. It is safe to carry.
- **Data custody obligations (finding 11).** These are inherent to any bookkeeping product with free users. They are acceptable if export and retention policies are written into the Solo terms before launch.
- **Roadmap drift and reduced pricing optionality (finding 14).** These are acceptable if the team decides explicitly that matching competitors' free tiers is strategically necessary. Revisit at month 6 with real segment data.

If the team wants concrete failure narratives for the highest-severity items, especially the support collapse in week 3 and the deliverability incident, run `pre-mortem` on this proposal with this analysis as input.
