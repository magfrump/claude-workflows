# What-If Analysis: 48-hour auto-close for pending tickets

**Proposal:** Shorten the auto-close window for Pending customer tickets from 7 days to 48 hours (Support Operations, Brightfold Software)
**Date:** 2026-11-20
**Upstream critiques:** none

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output. This skill is most powerful when focused on the gaps that critics miss.

**Prior Art Check:** No repository is available, so `docs/decisions/` and `docs/working/` could not be searched. No `[PRIOR CONSIDERATION]` findings are possible. All findings below are tagged `[NOVEL]`.

---

## Assumptions Examined

- **Assumption:** The number of auto-closed tickets stays at 3,100, because "customers who never replied in 7 days were never going to reply."
  - **Source:** explicit (Expected impact table, and the paragraph below it)
  - **If wrong:** redesign. The proposal's own Customer data section contradicts this. 39% of customer replies to pending tickets arrived between day 3 and day 7. Under a 48-hour rule, every one of those tickets is closed before the reply arrives. The 3,100 figure counts only the never-repliers. Auto-closes must rise by the number of day-3-to-7 repliers. The proposal does not state that number, so the size of the increase is unknown. The model appears to have moved close dates earlier without moving any ticket from "replied" to "closed." Every downstream figure depends on that model (backlog, resolution time, the contractor cut).
  - **Tag:** `[NOVEL]`

- **Assumption:** The new rule hits both targets in the first full month.
  - **Source:** explicit (Expected impact)
  - **If wrong:** redesign. The proposal's own table does not support this claim. Modelled backlog is 960 against a target of 900, which misses. Modelled median resolution is 2.9 days against a target of 3, which passes by 0.1 days. Even taken at face value, the model shows one metric missing and the other within noise. It also leaves out the extra tickets created by early-closed customers who come back (next assumption).
  - **Tag:** `[NOVEL]`

- **Assumption:** A customer whose ticket closes early will "just contact us again" at low cost to both sides.
  - **Source:** explicit (closing message, Risks)
  - **If wrong:** redesign. Two cases are possible, and the proposal doesn't say which applies:
    - **Reply reopens the closed ticket.** The cost is low for the customer. However, the resolution-time metric must then decide whether it counts the first close or the final close, and the backlog figure rises again.
    - **Contact creates a new ticket.** The customer loses context and repeats their logs and steps. An agent re-triages from scratch. The original ticket counts as "resolved" when it wasn't, and the follow-up counts as a new short ticket. Both cases make the dashboard look better than the customer's actual experience.
  - **Tag:** `[NOVEL]`

- **Assumption:** The reduction in backlog means a reduction in workload, which justifies dropping the $14,000/month contractor overflow team.
  - **Source:** implicit (Expected impact, final paragraph)
  - **If wrong:** full retreat on the staffing cut. Pending tickets waiting on the clock take no agent time. Removing them from the count shrinks the *number*, not the *work*. Actual workload probably rises: follow-up tickets, re-triage, placeholder replies (see Consequence Chains), and complaints. The contractor decision is based on a measurement change, not on reduced demand.
  - **Tag:** `[NOVEL]`

- **Assumption:** 48 hours is a meaningful window for customers.
  - **Source:** implicit (the rule uses wall-clock time and makes no mention of business days)
  - **If wrong:** tweak or redesign. A ticket set to pending on Friday afternoon closes on Sunday afternoon, so the customer had zero business hours to respond. The day-3-to-7 cohort is described as people asking their IT department or collecting logs. That is exactly the work that weekends stop. Using business hours would fix part of this. Leaving it as-is closes tickets on customers who never had a working day to reply.
  - **Tag:** `[NOVEL]`

- **Assumption:** Survey response rates (and implicitly scores) are unaffected.
  - **Source:** explicit (Risks)
  - **If wrong:** tweak or redesign. The survey fires on close. It will now fire at customers who are in the middle of collecting logs and whose ticket was just closed on them. Response *rates* may hold, but scores from this group will be poor. If CSAT is reported anywhere, it will fall at the same time as the two metrics improve.
  - **Tag:** `[NOVEL]`

- **Assumption:** "No other workflow changes" is true. Agents and customers keep behaving as they do today.
  - **Source:** explicit (Proposal)
  - **If wrong:** redesign. Both groups will adapt to a shorter clock (Confidence Inversions).
  - **Tag:** `[NOVEL]`

- **Assumption:** The 1st of next month is a neutral start date.
  - **Source:** implicit
  - **If wrong:** tweak. The start date is 1 December. That month has holiday closures, year-end change freezes, and slow customer IT departments, so the day-3-to-7 cohort will be at its largest. The contractor drop is planned for "end of the quarter," so it would be decided on a single atypical month of data.
  - **Tag:** `[NOVEL]`

## Consequence Chains

**Outcome 1: pending tickets close sooner**
```
→ First-order: pending tickets with no reply close at 48h instead of 7d
  → Second-order: customers who would have replied on days 3–7 find their ticket closed
    → Third-order: they open new tickets; context is lost, agents re-triage, and the customer repeats work. Agent workload per issue goes up.
    → Third-order: a share of them don't come back. The issue stays unresolved, appears later as churn or an escalation through account management, and is invisible in support metrics.
  → Second-order: the CSAT survey fires at a frustrated customer mid-task
    → Third-order: CSAT falls while backlog and resolution time improve. Leadership sees conflicting signals with no explanation.
```

**Outcome 2: median resolution time falls to ~2.9 days**
```
→ First-order: the reported median drops, partly because waiting time is cut and partly because follow-up tickets restart the clock
  → Second-order: the metric stops measuring how long customers wait for a fix. One issue split across two tickets is counted as two quick resolutions.
    → Third-order: future decisions (staffing, targets, tooling) are based on a number that no longer tracks the customer outcome it was created to measure.
    → Third-order: resolution time measured from the customer's *first* contact actually rises for the day-3-to-7 cohort, and no one is measuring that.
```

**Outcome 3: contractor overflow team dropped**
```
→ First-order: $14,000/month saved from end of quarter
  → Second-order: in-house agents absorb the follow-up tickets, the placeholder-reply re-pends, and the normal January post-holiday volume spike without overflow capacity
    → Third-order: first-response SLAs slip, real (not clock-driven) backlog grows, and agents use the auto-close more aggressively to cope
    → Third-order: when metrics worsen, overflow capacity can't be restored quickly (Reversibility Map)
```

**Customer adaptation chain**
```
→ First-order: customers learn the clock is 48 hours
  → Second-order: they send placeholder replies ("still collecting logs") to keep the ticket open
    → Third-order: each placeholder moves the ticket out of Pending into an agent queue; an agent must read it and re-pend it. This is a new touch that didn't exist under the 7-day rule, it lands in the open backlog, and it can trigger response SLAs.
```

## Coupling Analysis

- **Resolution-time metric definition ↔ auto-close rule** (invisible: a convention in reporting). The metric's value is set mostly by the auto-close timer, not by agent work. The proposal states this directly as the motivation. Changing the timer changes the metric without changing the work. Any target, bonus, or staffing model tied to this metric is coupled to a configuration setting. `[HIDDEN COUPLING]`
- **Closed-ticket reply handling ↔ metrics and customer experience** (visible in helpdesk config, but not addressed). Whether a reply to a closed ticket reopens it, creates a new ticket, or bounces decides whether the "contact us again" path is cheap or costly. It also decides whether the metric gains are real or partly reversed by reopens. `[HIDDEN COUPLING]`
- **Survey trigger ↔ close event** (visible). The proposal notes the timing shift but not that the *population* being surveyed changes to include customers who were still engaged. Split tickets may also produce two surveys for one issue. `[HIDDEN COUPLING]`
- **Customer reply ↔ status transition ↔ SLA clock** (invisible: behavioral). A placeholder reply moves the ticket back to an agent queue and may start a response SLA. "Agents keep the same SLAs" is true on paper, but the number of SLA-bearing events changes. `[HIDDEN COUPLING]`
- **Customer contracts or enterprise support terms ↔ close behavior** (invisible to Support Ops; held by Sales or Legal). If any customer contract defines support case handling, or if enterprise accounts have named contacts who review case history, early closes may conflict with what was sold. This is unknown and worth checking. `[HIDDEN COUPLING]`
- **Monday leadership dashboard ↔ historical trend** (invisible: temporal). The step change on 1 December breaks comparisons with earlier periods. An improvement from the rule change can't be separated from any real improvement or decline. `[HIDDEN COUPLING]`

## Confidence Inversions

- **"Customers who never replied in 7 days were never going to reply."** This is true, but it is the wrong group. The confident statement is about never-repliers. The rule also affects late repliers. Inverted: the 3,100 count is a lower bound, and the real number of auto-closes is 3,100 plus everyone in the 39% late-reply cohort. Every modelled number goes with it.
- **"No other workflow changes."** Inverted: both groups change their behavior. Agents under backlog pressure learn that setting a ticket to Pending clears it in two days, so Pending becomes a backlog-clearing tool for borderline tickets. Alternatively, careful agents stop using Pending for complex cases to protect customers, and those tickets stay in Open. Customers learn to send placeholders. In each case the model, which assumes today's behavior, is invalid within weeks.
- **"Both headline metrics hit target."** Inverted using the proposal's own numbers: backlog misses (960 vs 900) and resolution passes by 0.1 days before any of the corrections above. After the corrections, both likely miss, and the contractor cut has already happened.

## Adversarial Scenarios

1. **The late-reply cohort is large and comes back** (the most likely scenario, well above 10–20%). Say, as an illustration, that a few thousand pending tickets got replies last quarter. About 39% of those become early closes. Most of these customers return as new tickets with the same issue. The backlog falls less than modelled, agent touches per issue rise, and January opens without overflow capacity.
2. **December timing** (~20–30% likely to matter). Holiday closures stretch customer response times, so the share of replies after 48 hours rises well above 39%. A spike in early closes and poor CSAT is the first month leadership sees, and the contractor decision is made on that month.
3. **A key account escalates** (~10–20%). An enterprise customer whose IT team needed four days to gather logs has a critical ticket auto-closed over a weekend. The escalation goes through the account manager to leadership. The rule is rolled back under pressure, but the contractors have already been released.

## Reversibility Map

- **1 week:** Reverting the auto-close setting is a configuration change, which is trivial. Tickets already closed early stay closed. That is harm already done, not a cliff, and the affected customers may need outreach.
- **1 month:** The rule is still a trivial revert. Leadership has now seen one month of "on target" metrics, so a revert shows as an obvious regression on the Monday dashboard. This is organizational friction, not a technical cliff.
- **6 months:** The rule is still a trivial revert. However, targets, staffing, and possibly budgets have been reset around the new metric baseline.

**The rule change itself has a flat gradient.** It is equally easy to revert at any point.

**Cliff edge: contractor termination at end of quarter.** The proposal presents dropping the overflow team as a consequence of this approval, not as a separately reviewed change. Once that contract ends, restoring capacity requires procurement, a vendor, and onboarding and training time. That is another party's work and takes weeks to months. The termination is the irreversible step. It is decided on the basis of one month (December) of a metric that the rule change itself shifts. `[REVERSIBILITY CLIFF]`

## Cost of Success

Suppose everything works: backlog is around 900, median resolution is under 3 days, contractors are gone, and $42,000 is saved per quarter. In that world:

- **Optionality cost:** The two metrics leadership watches most now mostly measure a timer setting. Any future question ("are customers actually getting helped faster?") needs a new metric to be built. Nothing remains in reserve for the next push to meet targets. `[SUCCESS COST]`
- **Complexity and maintenance cost:** Someone has to monitor reopen and follow-up rates, explain why CSAT fell, and handle escalations from early closes. That is new work that nobody owns. `[SUCCESS COST]`
- **Capacity cost:** No overflow team for volume spikes. The organization is staffed for a reported backlog, not the actual one. `[SUCCESS COST]`
- **Customer cost:** Customers dealing with harder problems, the ones who need logs or reproductions, get a worse experience. They are likely the higher-value, technically complex accounts. `[SUCCESS COST]`

## Findings Summary

1. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The model keeps auto-closes at 3,100, which contradicts the proposal's own data: 39% of replies arrive after 48 hours. All modelled figures are optimistic.
2. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The table shows backlog at 960, missing the 900 target. The "both targets hit" claim is not supported by the proposal's own numbers.
3. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` A backlog reduction is treated as a workload reduction. The contractor cut is based on a change in measurement.
4. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The 48-hour wall-clock rule ignores weekends and holidays. Friday tickets close with no business day in between.
5. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The start date of 1 December is the worst month for the late-reply cohort, and the contractor decision rests on it.
6. `[SECOND-ORDER EFFECT]` `[NOVEL]` Early-closed customers return as new tickets, which lowers reported resolution time while the customer's actual wait rises.
7. `[SECOND-ORDER EFFECT]` `[NOVEL]` Customers send placeholder replies, creating new agent touches and SLA events.
8. `[SECOND-ORDER EFFECT]` `[NOVEL]` Agents may use Pending as a backlog-clearing tool, or avoid it.
9. `[SECOND-ORDER EFFECT]` `[NOVEL]` CSAT scores fall because the survey reaches customers who were still working on their ticket.
10. `[HIDDEN COUPLING]` `[NOVEL]` The resolution-time metric is mostly set by the auto-close timer. Changing the timer changes the metric without changing the work.
11. `[HIDDEN COUPLING]` `[NOVEL]` Reply-to-closed-ticket behavior (reopen vs new ticket) is undefined but decides both customer cost and metric accuracy.
12. `[HIDDEN COUPLING]` `[NOVEL]` Customer contracts or enterprise terms may cover case handling. Support Ops may not know.
13. `[HIDDEN COUPLING]` `[NOVEL]` The step change breaks dashboard trend continuity.
14. `[REVERSIBILITY CLIFF]` `[NOVEL]` Contractor termination at quarter end is hard to undo and is bundled into this approval.
15. `[SUCCESS COST]` `[NOVEL]` The metrics lose meaning, overflow capacity is gone, and complex-issue customers get worse service.

If the team wants concrete failure stories (for example, "it's March, CSAT is down 15 points and we're re-hiring contractors; what happened?"), run `pre-mortem` on this proposal using this analysis as input.

## Recommendations

**Must address before proceeding:**
- **Re-run the model correctly.** Move every pending ticket whose customer replied after 48 hours into the auto-closed group. Estimate how many return as follow-up tickets, using an assumed return rate with a range. Report the corrected backlog, resolution time, and auto-close count. Correct the "both targets hit" statement, since 960 does not meet 900 even in the current model.
- **Separate the contractor decision from this approval.** Make it its own review, held after at least 6–8 weeks of post-change data that includes January, and base it on agent workload (touches per issue, real queue depth, SLA attainment), not on backlog count.
- **Define and verify reply-to-closed behavior.** Configure the helpdesk so that a customer reply to an auto-closed ticket reopens *that* ticket. Make sure the resolution-time metric uses the final close, not the first.

**Worth mitigating:**
- Use **business hours** (for example, 2 business days) instead of 48 wall-clock hours, and consider a reminder at 24 business hours before close.
- **Don't start on 1 December.** Start in mid-January, or pilot on one queue or customer tier first.
- **Track counter-metrics** next to the Monday numbers: reopen rate, rate of new tickets from the same customer within 7 days of an auto-close, CSAT on auto-closed tickets, and resolution time measured from the customer's first contact on an issue.
- **Check with Sales or Legal** for enterprise contract terms on case handling. Consider leaving the 7-day window in place for enterprise or high-severity tickets.
- Watch for changes in how often agents use Pending, in either direction.

**Acknowledged risks:**
- Some never-replier customers will receive a close message and a survey sooner. This is low harm and acceptable.
- The break in trend continuity on the dashboard can be handled with an annotation on the change date. It doesn't need to block the change.
