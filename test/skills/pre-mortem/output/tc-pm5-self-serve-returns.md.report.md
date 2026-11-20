# Pre-Mortem: Oakbarrow self-serve returns launch

> ℹ️ **No upstream what-if analysis provided.** These failure narratives come straight from the proposal. They would be sharper if seeded from a `what-if-analysis` that had already mapped the assumptions and coupling points.

> ℹ️ **Prior Art Check skipped.** No repository was available, so `docs/decisions/` and `docs/working/` were not searched. No narratives carry a `[PRIOR CONSIDERATION]` tag.

**Proposal:** Launch plan: Self-serve returns for Oakbarrow Furniture (Customer Experience product team, launch 1 September, all customers)
**Date:** 2026-11-19
**Upstream what-if analysis:** none

---

## Framing: the arithmetic the plan already contains

The proposal holds the main failure in its own numbers, in two separate sections:

| | Today | After launch (plan's own forecast) |
|---|---|---|
| Requests per day | ~35 | ~105 ("roughly triple") |
| Refunds desk throughput | ~45/day (3 people, 8 min each, alongside reconciliation) | ~45/day (no staffing change is mentioned) |
| Desk time needed | ~4.7 person-hours/day | ~14 person-hours/day |
| Net queue change | −10/day (stable, cleared in 2 working days) | **+60/day** |

The plan forecasts tripled demand as a *success* and leaves the processing step unchanged ("Behind the button, nothing changes"). The Rollout and Metrics sections measure only the front of the flow, the button. Nobody watches the back of the flow, the desk. The narratives below are written six months after a 1 September launch that shipped exactly as written.

---

## Failure Narratives

### 1. The Queue That Never Drained

- **Root cause:** Self-serve demand reached the forecast ~105 requests/working day within the first fortnight. The Refunds desk's capacity stayed at ~45/day, and the plan made no staffing or process change to match.
- **Chain of consequences:**
  1. The order-confirmation email and Help pages announced the button to every customer on 1 September. Pent-up demand arrived at once, including customers who had "given up" on returns from orders weeks or months old.
  2. The Returns queue in the ERP grew by about 60 requests per working day. By 12 September (day 10) it held ~600 requests, about 13 working days of desk capacity. By 30 September it held ~1,300, which is over six weeks of waiting at 45/day.
  3. The instant confirmation email had said a refund "will follow once it is approved", with no timeline. Customers had been used to a phone call and a 2-day turnaround. From day 3 or 4 they began contacting Customer Service to ask where their return was.
  4. Customer Service could not speed anything up. They could see the request in the ERP queue but could not approve it, so each contact ended with "it's in the queue." Repeat contacts followed. Some customers raised card chargebacks, which created a second piece of work for Finance Operations: chargeback disputes on top of the refunds.
  5. In mid-October Finance moved two Customer Service agents onto the desk after short training. Approval error rates rose, including refunds issued for items never collected (see narrative 2).
- **Observable outcome:** ERP Returns queue depth went 0 → ~1,300 in September. Median request-to-refund time went from 2 working days to over 25. Card chargebacks citing "refund not processed" rose sharply in October. The 6-point repeat-purchase lift in the business case reversed: customers who returned in September reordered *less* than the pre-launch baseline, which is the problem the launch was meant to fix (22% of non-reorderers already blamed returns).
- **Plausibility:** Likely (>50%). This needs no assumption beyond the plan's own forecast and its own capacity figure.
- **Severity:** High. The cost is real and recovery is slow: the backlog takes weeks of extra staffing to clear, and the damage to customer trust outlasts it.
- **Mitigation:** Add a "Refunds desk capacity" item to the plan's **Dependencies** section. It should be signed off by the Finance Operations lead and show how ~105 requests/day (~14 person-hours/day at 8 min each) will be handled before launch, whether through added staff, auto-approval rules for low-value or non-damaged returns, or both. Then change **Rollout** from "launch to all customers" to a staged release, for example 25% of accounts on 1 September, with each expansion gated on ERP Returns queue median age staying ≤ 2 working days for 10 consecutive working days.

### 2. The Empty Driveway

- **Root cause:** The customer picks a collection date in the self-serve flow ("chooses a collection date"). Under **What we are launching**, though, the courier collection is booked by the Refunds desk only when it works the request. The date the customer picked is a preference stored on the request. No booking exists until a person opens it.
- **Chain of consequences:**
  1. In week 1 the queue was short, so most chosen dates were booked in time and the gap went unnoticed.
  2. Once the backlog passed the typical lead time customers chose (often 3–5 days out), the desk began reaching requests whose collection date had already passed.
  3. Customers took a day off work, moved a wardrobe or dismantled a bed frame into the hallway, and waited. No courier came. The confirmation email had echoed their chosen date back to them, so they reasonably treated it as an appointment.
  4. Each missed collection produced at least one angry contact. Then the desk had to contact the customer to rebook, which took far longer than 8 minutes and slowed the queue further. This is a feedback loop with narrative 1.
  5. Some customers threw away packaging or left furniture outside. Damage-in-transit disputes followed.
- **Observable outcome:** A rising share of returns where the booked collection date is later than the customer's chosen date. A new Customer Service contact category, "courier didn't arrive" or "missed collection", which did not exist before launch. Social and review-site posts about people taking days off for collections that never came. These are the most emotionally charged complaints in the whole launch, because they cost customers a day.
- **Plausibility:** Likely (>50%), given narrative 1. It is still Plausible even if the desk keeps up, because any weekend or holiday backlog reproduces it.
- **Severity:** High. Each missed collection directly costs a customer a lost day, and it is the most quotable failure in reviews.
- **Mitigation:** In **What we are launching**, change one of two things before launch. Either (a) book the collection through the existing courier booking API at the moment the customer submits, and make refund approval a separate later step, or (b) remove the date picker and have the confirmation email say "we'll contact you within N working days to arrange collection", with N set from desk capacity. Do not ship a UI that presents a date as chosen when nothing has been booked.

### 3. September's Close Didn't Close

- **Root cause:** The desk's 45/day throughput is achieved "alongside their other reconciliation work". When the returns backlog became visible, the three staff were told to prioritise refunds. That reconciliation work, which feeds month-end close, was the slack that got used up.
- **Chain of consequences:**
  1. In the second and third weeks of September, Finance Operations leadership moved the desk to refunds only, raising throughput to ~75–80/day. That was still below inflow.
  2. Bank and payment-provider reconciliations for September fell behind. Refunds issued in bulk late in the month made those reconciliations harder, because high volumes of refunds were posted against September and August sales.
  3. September month-end close slipped by several working days. Unreconciled items carried into October, which then had an even larger refund volume.
  4. The Customer Experience product team's Week 1 and Week 4 reviews did not include Finance Operations. Nobody connected the slipped close to the returns button until the controller raised it.
- **Observable outcome:** September close completed several working days late. Unreconciled-item counts on the Finance Operations reconciliation report rose in September and October. Refund liability and cash forecasting became unreliable for a quarter, and an internal argument about whose budget pays for the extra staff followed.
- **Plausibility:** Plausible (10–50%).
- **Severity:** Medium to High. The cost is real and internal, and recoverable, but it lands on a team that never approved the plan.
- **Mitigation:** Add to **Dependencies** an explicit Finance Operations sign-off. It should name the reconciliation hours protected during launch month, and who authorises any reallocation of desk time away from month-end close. Add the Finance Operations lead to the **Rollout** Week 1 and Week 4 reviews.

### 4. The Dashboard Was Green

- **Root cause:** Every launch metric measures the front of the flow. The plan has no metric for request-to-refund time, queue depth or missed collections. Several of the chosen metrics can hit target *because* the back end is failing.
- **Chain of consequences:**
  1. **Rollout** Week 1 monitored "button usage, completion rate, and errors". All were excellent: usage was high and completion was smooth, because the button worked exactly as built.
  2. "Share of returns started online" reached the 80% target early. That was partly because Customer Service started telling phone callers to use the button.
  3. "Contacts to Customer Service about returns" appeared to fall. Agents logged the new contacts under "refund status" and "delivery/courier" reason codes rather than "returns", so the returns-tagged count dropped while total contacts rose.
  4. If the returns CSAT survey fired at request submission, early scores were high. They reflected the pleasant button, not the six-week wait.
  5. The first review of an *outcome* signal was **Week 4**, "repeat-purchase leading indicators", which lag even further. By then the backlog was ~1,300.
- **Observable outcome:** Leadership saw a successful launch dashboard for most of September while queue depth, chargebacks and missed-collection complaints climbed. The first escalation came from Finance or social media rather than from the product team's own monitoring.
- **Plausibility:** Likely (>50%). This is the plan as written.
- **Severity:** Medium on its own. It acts as an amplifier: it is the reason narratives 1–3 run for weeks instead of days.
- **Mitigation:** Add to **Metrics** three back-end measures: ERP Returns queue depth, median request-to-refund time, and the share of collections booked on or before the customer's chosen date. Add to **Rollout** Week 1 an alert if Returns queue depth exceeds 90 (two days of desk capacity) at the end of any working day. Measure "contacts about returns" across all reason codes linked to a return or refund, not just the "returns" tag. Send the CSAT survey after the refund is issued, not on request.

### 5. The Courier Who Only Delivers

- **Root cause:** Under **Dependencies**, the courier dependency is "Courier booking API: already used for deliveries." Collections reverse the flow. The pickup address is the customer's home, the item may be unboxed, large items need a two-person crew, and the courier may price collections differently or not offer them through the same API product. A delivery integration is not evidence that the collection flow works at furniture scale.
- **Chain of consequences:**
  1. The first desk bookings at launch volume revealed that collection bookings either needed a different service code, were rejected for oversized items, or were capped per day by the courier.
  2. The desk fell back to booking collections by phone or the courier's web portal, which took well over 8 minutes per request and cut throughput further.
  3. The courier's collection slots in some postcodes were booked out a week or more ahead, so customers' chosen dates could not be honoured even when the desk was on time. This reinforced narrative 2.
  4. Collection costs per return came in higher than whatever the business case assumed, at triple the volume.
- **Observable outcome:** Rejected or errored collection bookings in the courier integration logs during the first week. Average handling time per return on the desk rose above 8 minutes. Courier invoices for collections rose sharply relative to delivery spend in September and October.
- **Plausibility:** Plausible (10–50%). The trade pilot may have masked this if trade returns were handled differently, which the plan doesn't say.
- **Severity:** Medium. It is recoverable with a commercial agreement and a workflow change, but it compounds narratives 1 and 2.
- **Mitigation:** Before launch, add to **Dependencies** a confirmed end-to-end test that books *collections*, including a two-person oversized item such as a sofa, through the courier booking API. Also get written confirmation from the courier of daily collection capacity at ~105/day and the collection rate card. Mark "Courier booking API" as not ready until both exist.

---

## Recommendations

### Must address before proceeding

1. **The Queue That Never Drained (1).** Likely / High. The plan forecasts demand at more than twice the stated processing capacity and changes nothing about processing. Approving the launch "to all customers" as written commits to a backlog. Expected mitigation: a signed desk capacity plan for ~105/day (staff, auto-approval rules, or both), plus a staged rollout gated on queue median age ≤ 2 working days.
2. **The Empty Driveway (2).** Likely / High. The UI makes a promise, a collection date, that the system does not keep. Expected mitigation: book the collection at submission, or remove the date picker and set an honest expectation in the confirmation email.
3. **The Dashboard Was Green (4).** Likely / Medium, but this is the detection layer for everything else. It is cheap to fix and should not ship without the fix. Expected mitigation: add queue depth, request-to-refund time and on-time collection rate to **Metrics**, with the queue-depth alert in Week 1.

### Worth mitigating

4. **September's Close Didn't Close (3).** Plausible / Medium–High. Get Finance Operations sign-off and protect reconciliation time. Mitigating narrative 1 mostly removes this risk. Watch signal: unreconciled-item count on the month-end reconciliation report for September.
5. **The Courier Who Only Delivers (5).** Plausible / Medium. Run one real collection-booking test and get a capacity confirmation from the courier before launch. Watch signal: courier integration booking-error rate in week 1, and desk average handling time above 8 minutes.

### Acknowledged risks

- **The tripling forecast itself is uncertain.** It rests on a trade-customer pilot and peer benchmarks, and consumer returns may differ in reason mix and item size. The team can reasonably carry this uncertainty *provided* the staged rollout gate in recommendation 1 exists. The gate makes the forecast self-correcting: if demand is higher or lower than three times today's volume, the expansion pace adjusts.

### Overall view

The proposal's goal is sound, and its prediction that easy returns increase repeat purchases may well be right. The failure is in how the rollout is structured. Nothing in the plan connects the forecast increase in demand (Expected impact) to the fixed capacity that has to absorb it (What we are launching). The launch-to-all rollout and the front-end-only metrics mean the gap would be discovered by customers before anyone on the product team noticed it. Fixing the three must-address items does not require abandoning 1 September. It requires replacing "launch to all customers" with a gated ramp and giving the Refunds desk the capacity the plan's own numbers say it will need.
