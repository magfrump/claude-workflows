# What-If Analysis: 48-hour auto-close for pending tickets

**Proposal:** Brightfold Support Ops: shorten the pending-ticket auto-close window from 7 days to 48 hours, effective the 1st of next month
**Date:** 2026-11-20
**Upstream critiques:** none

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output. This skill is most powerful when focused on the gaps that critics miss.

**Prior Art Check:** No repository was available, so `docs/decisions/` and `docs/working/` could not be searched. No `[PRIOR CONSIDERATION]` findings are possible. All findings are tagged `[NOVEL]`.

---

## Assumptions Examined

**A1. The number of auto-closed tickets does not change (3,100 → 3,100).**
- **Source:** Explicit (Expected impact table, and "the rule only changes *when* a pending ticket closes, not *whether* it does").
- **If wrong:** Redesign. The proposal's own Customer data section contradicts this. 39% of customer replies arrived on days 3–7, so every one of those tickets now auto-closes before the reply lands. If R pending tickets got a reply last quarter, auto-closes rise by about 0.39R. For example, if R = 3,000, that is about 1,170 extra closures, a 38% increase. The model appears to count only the tickets that never got a reply. The tickets that are newly closed by this rule seem to be missing from it entirely.
- **Tag:** `[NOVEL]`

**A2. A customer who replies after closure costs about the same as one who replied before closure.**
- **Source:** Implicit ("If you still need help, just contact us again"; "No other workflow changes").
- **If wrong:** Redesign. When a day-3-to-7 customer "contacts us again", the result is either a reopen or, more likely, a new ticket. A new ticket re-enters the front of the queue. It needs a fresh first response, possibly lands on a different agent, and loses its history unless someone links it manually. The 0.39R population stops being cheap pending tickets and becomes new inbound work.
- **Tag:** `[NOVEL]`

**A3. The modelled backlog (960) and median resolution time (2.9 days) reflect real improvement in customer outcomes.**
- **Source:** Implicit (the metrics are presented as the goal, and the contractor cut depends on them).
- **If wrong:** Full retreat on the contractor decision. Resolution time is measured per ticket, from creation to *Closed*. Splitting one customer problem into two tickets, each closed quickly, lowers the median while the customer's actual time to resolution goes up. The backlog drops partly because pending work is relabelled as closed and partly because it re-enters later as new tickets. Neither change means less work.
- **Tag:** `[NOVEL]`

**A4. 48 hours is a fair window for a customer to respond.**
- **Source:** Implicit (48 calendar hours; there is no mention of business days, weekends, or holidays).
- **If wrong:** Tweak or redesign. A ticket set to pending at 3 pm on Friday closes at 3 pm on Sunday, before the customer's IT department has been in the office at all. The proposal itself names "ask their IT department" as a common reason for late replies.
- **Tag:** `[NOVEL]`

**A5. Survey response rates and scores are unaffected.**
- **Source:** Explicit (Risks section, which addresses only timing and response rate, not score).
- **If wrong:** Tweak, but a visible one. The survey will now go to customers whose ticket was closed while they were still collecting logs. These are likely to be the most negative responses in the whole survey population.
- **Tag:** `[NOVEL]`

**A6. One month of hitting target justifies dropping the $14k/month contractor team.**
- **Source:** Explicit ("Both headline metrics hit target in the first full month, which lets us drop the contractor overflow team").
- **If wrong:** Redesign. This is the irreversible part of the plan, and it rests on metrics that A1–A3 suggest are partly artefacts of how closure is counted.
- **Tag:** `[NOVEL]`

**A7. The changeover is clean.**
- **Source:** Implicit ("take effect on the 1st of next month").
- **If wrong:** Tweak. If the new rule applies to tickets already sitting in pending, every ticket pending for 2–7 days closes at once on day one. That produces a burst of closures, closing emails, surveys, and then reopens or new tickets.
- **Tag:** `[NOVEL]`

---

## Consequence Chains

**Intended outcome 1: Open backlog falls from 1,460 to about 960.**
```
→ First-order: Pending tickets leave the backlog 5 days earlier.
  → Second-order: The ~39% of would-be repliers get closed and come back as new tickets
    (or reopens), adding to inbound volume and first-response workload.
    → Third-order: First-response SLA compliance degrades even as "backlog" looks healthy;
      leadership sees green dashboards while queue wait times rise.
    → Third-order: Agents spend time re-reading or re-asking for context ("can you resend
      the logs?"), which lengthens handle time and pushes more tickets back into pending,
      where they risk a second auto-close.
  → Second-order: With the backlog "at target," the contractor team is cut at quarter end.
    → Third-order: The capacity loss lands at the same moment the re-contact volume peaks,
      with no overflow buffer left.
```

**Intended outcome 2: Median time to resolution falls from 5.8 days to 2.9 days.**
```
→ First-order: Auto-closed tickets record a 2-day pending tail instead of 7.
  → Second-order: Tickets split into a closed original and a follow-up, and each counts
    separately with a short resolution time, so the metric stops tracking customer experience.
    → Third-order: Resolution time can no longer be used to detect real slowdowns; a genuine
      process degradation would be masked by the definitional improvement.
  → Second-order: Year-over-year and quarter-over-quarter comparisons break at the
    changeover date, so the "improvement" can't be separated from the rule change itself.
```

**Intended outcome 3: Customers who need more time "just contact us again."**
```
→ First-order: Slower customers (logs, IT approval, intermittent bugs) must re-open contact.
  → Second-order: Customers learn the rule and reply "still working on it" to keep tickets
    open, and each of those replies resets the clock and lands in an agent's queue as a
    customer-replied ticket needing action.
    → Third-order: Agent queues fill with no-content replies; the workload the rule was meant
      to remove reappears in a noisier form.
  → Second-order: Customers with intermittent issues ("wait for the issue to happen again")
    lose the thread; the recurrence arrives as a cold ticket, possibly to a different agent.
    → Third-order: Diagnostic continuity on hard bugs degrades; engineering escalations lose
      the customer-side history.
```

---

## Coupling Analysis

| Coupling | Visibility | Note |
|---|---|---|
| **Behaviour of replies to a closed ticket.** Does the helpdesk reopen the ticket, or create a new follow-up? | Invisible (platform behaviour; never mentioned in the proposal) | This is the most important unknown. If replies reopen the ticket, the original resolution timestamp may be overwritten or double-counted. If replies create a new ticket, history is lost and A2 and A3 apply in full. |
| **Survey trigger fires on *Closed*** | Visible (stated in the proposal) | The proposal notes the timing shift but not that auto-closes will now survey customers who are still mid-task. CSAT is probably reviewed by the same leadership audience. |
| **Engineering escalations and linked bug tickets** | Invisible (convention) | Pending tickets waiting on a customer repro may be linked to engineering issues. Auto-closing them can break "notify customer when fixed" workflows or drop affected-customer counts used to prioritise bugs. |
| **Customer contracts and SLAs** | Possibly invisible | Enterprise agreements may define resolution or response obligations. Unilaterally closing tickets at 48 hours could conflict with contracted terms or account-manager commitments. |
| **Agent macros that request information** | Visible but unadjusted ("same macros") | Macros that ask for logs or IT involvement still imply a relaxed timeline, while the system now enforces 48 hours. Customers receive mixed signals. |
| **Contractor contract notice period** | Visible (finance) | The cut is planned for quarter end. The decision point therefore falls after only about one month of data, and that month is December. |
| **Leadership metric definitions** | Invisible (convention) | Leadership reads "backlog" and "resolution time" as measures of customer outcomes. The proposal changes what the numbers mean without changing their labels. |

---

## Confidence Inversions

**"Customers who never replied in 7 days were never going to reply."**
This is true, but it covers the wrong population. The statement is accurate for the 3,100 tickets. The inversion is that the risk was never those 3,100. It is the day-3-to-7 repliers, and the proposal's own data says they make up 39% of replies. Taking that seriously makes the "auto-closed: 3,100 → 3,100" row incorrect. The backlog and resolution figures were presumably built on the same model, so they need re-checking too.

**"No other workflow changes."**
Inverted: the rule change *is* a workflow change for agents, because re-contacts, context reconstruction, and "still working on it" noise all arrive in their queues. It is also a workflow change for customers, who now need to know they must reply within two days. The claim holds for configuration and fails for behaviour.

**"Response rates should be unaffected."**
Inverted: suppose response rates do rise, because angry customers respond to surveys more often. CSAT then falls on exactly the population this rule creates. A visible CSAT dip in December could easily be blamed on agents rather than on the rule.

---

## Adversarial Scenarios

**1. Holiday launch (realistic, roughly 50% or more likely to matter).**
The rule takes effect on 1 December. Customer IT departments slow down, staff go on leave, and the week of 24 December to 1 January contains several 48-hour windows in which almost nobody replies. Auto-closes spike well beyond the 0.39R baseline, and re-contacts surge in early January. That is right after the contractor team is cut at quarter end. The "first full month hit target" evidence comes from the most atypical month of the year.

**2. Re-contacts create new tickets rather than reopening (plausible, 20–40%, depending on platform configuration).**
Every late reply becomes a new ticket. Inbound volume rises by up to 0.39R per quarter. First-response SLA compliance slips. Backlog may still look near target, because re-contacts close fast with history attached by hand. The headline numbers show success while the operation degrades. This is the worst kind of failure, because nothing on the dashboard warns anyone.

**3. Key enterprise customer escalation (realistic, 10–20%).**
A large account's ticket is auto-closed while their IT team is gathering logs for a production issue. They escalate through their account manager and cite the closure, and the satisfaction survey that followed it, as evidence of poor support. Leadership then asks for a rollback or exemptions. Customer-tier exceptions get bolted onto the rule, which adds the complexity this proposal was supposed to avoid.

---

## Reversibility Map

| Timepoint | What reversal requires | Difficulty |
|---|---|---|
| **1 week** | Change the configuration back. Already-closed tickets stay closed. Affected customers may need an apology or outreach. Survey data from the week is skewed. | Low |
| **1 month** | Configuration change, plus explaining a metric regression to leadership, because the numbers return to 5.8 days and about 1,460. Customers have partly adapted. Reporting shows an awkward bump. | Moderate. The cost is mainly political: reverting looks like "losing" the targets. |
| **6 months** | Configuration change, but the contractor team is gone. Reverting the rule restores the real backlog with no overflow capacity to work it. Targets and planning have been rebased on the new numbers. | High |

**Cliff edges:**
- **Quarter end, when the contractor team is cut.** The rule is a toggle. Losing the team is not. After this point, reverting the rule means admitting a capacity gap. This is the main cliff.
- **The first leadership review that shows the targets met.** Once the numbers are celebrated, reverting carries a political cost. That cost grows every week.
- **Day 1, for in-flight tickets.** If existing pending tickets are swept up by the new rule, that mass closure cannot be undone. Those customers have already received closure emails and surveys.

---

## Cost of Success

Picture the world in which everything works. Backlog averages 960, median resolution is 2.9 days, the contractors are gone, and nobody complains loudly. What is worse than today?

- **Measurement cost (largest):** Brightfold's two headline support metrics now partly measure the auto-close setting rather than customer outcomes. Leadership has lost an instrument. A future real degradation, such as slower agents or a harder product, would be partly hidden by the definitional gain. And because the targets are "met", nobody is looking.
- **Optionality cost:** The 5.8 → 2.9 improvement has been spent. The next push to improve resolution time can no longer use this lever, and capacity planning without contractors assumes the new numbers are real.
- **Customer cost:** Customers with the hardest problems are disproportionately the ones closed early: those needing logs, IT approval, or an intermittent repro. Support becomes worse for exactly the cases where it matters most.
- **Complexity cost:** Low at first. It will rise if business-day clocks, customer-tier exemptions, or survey suppression are added later to patch problems, which is likely.
- **Maintenance cost:** Minimal. It is a configuration value.

---

## Findings Summary

1. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The model's "3,100 auto-closes unchanged" contradicts the proposal's own data. About 39% of replied tickets will now be auto-closed before the reply arrives.
2. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` What happens when a customer replies to a closed ticket (reopen or new ticket) is unspecified. It determines whether the metric gains are real.
3. `[SECOND-ORDER EFFECT]` `[NOVEL]` Splitting tickets lowers per-ticket resolution time while raising the customer's true time to resolution. The headline metric becomes partly definitional.
4. `[SECOND-ORDER EFFECT]` `[NOVEL]` Re-contacts add inbound volume and first-response load, which may degrade SLA compliance while backlog looks healthy.
5. `[SECOND-ORDER EFFECT]` `[NOVEL]` Customers learn to send "still working on it" replies, putting noise back into agent queues.
6. `[HIDDEN COUPLING]` `[NOVEL]` The survey-on-close trigger will poll customers who were closed mid-task, so expect a CSAT drop, not just a timing shift.
7. `[HIDDEN COUPLING]` `[NOVEL]` Engineering escalations and linked bugs may lose customer linkage when pending tickets auto-close.
8. `[HIDDEN COUPLING]` `[NOVEL]` Enterprise contract or SLA terms may conflict with unilateral 48-hour closure.
9. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The 48-hour calendar clock ignores weekends and holidays, and the launch date is 1 December.
10. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Changeover handling for tickets already pending is unspecified, with a risk of a day-one mass closure.
11. `[REVERSIBILITY CLIFF]` `[NOVEL]` The contractor cut at quarter end, based on one atypical month, turns a reversible toggle into an irreversible capacity reduction.
12. `[SUCCESS COST]` `[NOVEL]` Leadership metrics lose their link to customer outcomes, and future degradation is masked.
13. `[SUCCESS COST]` `[NOVEL]` The burden falls disproportionately on the hardest cases: log collection, IT approval, and intermittent bugs.

If the team also needs concrete failure narratives for this change, run `pre-mortem` on the same proposal using this analysis as input. Scenario 2 (silent degradation behind green dashboards) is the strongest candidate.

---

## Recommendations

**Must address before proceeding**
1. **Re-run the model with the day-3-to-7 repliers included.** Count the newly auto-closed tickets (about 0.39R), assume a re-contact rate for them, and model those re-contacts as new inbound work. Re-state backlog and resolution time under that model. If the targets are still met, the case gets stronger. If not, the leadership audience needs to know before approving.
2. **Specify and test the reply-after-close behaviour.** Confirm whether replies reopen the ticket or create a linked follow-up, and how resolution time is recorded in each case. Prefer a configuration in which a late reply reopens the original ticket and resolution time is measured to the *final* close.
3. **Decouple the contractor decision from the first month.** Do not commit to dropping the overflow team on December data. Require at least two non-holiday months that also meet the guardrail metrics (item 6), or extend the contractor contract month to month.
4. **Define the changeover.** Apply the 48-hour rule only to tickets that enter pending on or after the effective date, so there is no day-one mass closure.
5. **Reconsider the launch date or the clock.** Either delay to January or make the window 2 *business* days and pause it over holidays. Launching a calendar-hour clock on 1 December guarantees a distorted first month.

**Worth mitigating**
6. **Add guardrail metrics alongside the headline numbers:** re-contact rate within 7 days of auto-close, reopen rate, first-response SLA compliance, and CSAT for auto-closed tickets versus agent-closed tickets. Watch signal: re-contact rate on auto-closes above about 20%.
7. **Suppress or separate the survey on auto-close.** At minimum, report auto-close CSAT separately so it is not attributed to agents.
8. **Send a reminder at 24 hours** ("we'll close this tomorrow unless you reply; reply 'need more time' to keep it open"), and let agents set a longer pending window when their request needs logs or IT involvement.
9. **Check enterprise contracts** for resolution or closure terms, and exempt linked engineering-escalation tickets from auto-close.

**Acknowledged risks**
10. **Some customers who reply within 48 hours will still find the window brusque.** This is acceptable if the reminder and the extended-pending option exist. The truly unresponsive 3,100 genuinely do not need 7 days.
11. **Quarter-over-quarter metric comparisons will break at the changeover.** This is acceptable as long as the leadership report explicitly annotates the definitional change rather than presenting it as an operational improvement.

A simpler alternative is worth raising at the ops review. If the underlying goal is that leadership metrics should stop counting time spent waiting on customers, the honest fix is to change the *metric*: exclude pending time from resolution time and report pending tickets separately from the backlog. That would achieve the reporting goal without closing anyone's ticket early.
