# Proposal: Shorten the auto-close window for pending tickets from 7 days to 48 hours

**Owner:** Support Operations, Brightfold Software · **Status:** For approval at the ops review

## Background

When an agent replies to a customer and asks for more information, the ticket
moves to **Pending customer**. Today a pending ticket closes automatically after
7 days with no reply. About 38% of our open backlog on any given day is pending
tickets that are simply waiting out that clock.

This inflates the two numbers leadership reviews every Monday:

- **Open backlog:** averaged 1,460 tickets last quarter, against a target of 900.
- **Median time to resolution:** 5.8 days, against a target of 3 days. Resolution
  time is measured from ticket creation to the ticket reaching *Closed*, so a
  pending ticket that waits out the 7-day clock adds 7 days to its own
  resolution time.

## Proposal

Change the auto-close rule so pending tickets close after 48 hours with no
customer reply instead of 7 days. The closing message will say: "We haven't
heard back, so we've closed this request. If you still need help, just contact
us again."

No other workflow changes. Agents keep the same queues, macros and SLAs.

## Expected impact

We modelled last quarter's tickets against the new rule:

| Metric | Last quarter | Modelled with 48h rule |
|---|---|---|
| Open backlog (daily average) | 1,460 | 960 |
| Median time to resolution | 5.8 days | 2.9 days |
| Tickets auto-closed | 3,100 | 3,100 |

The number of auto-closed tickets does not change, because the rule only
changes *when* a pending ticket closes, not *whether* it does. Customers who
never replied in 7 days were never going to reply.

Both headline metrics hit target in the first full month, which lets us drop
the contractor overflow team ($14,000 a month) at the end of the quarter.

## Customer data

Of pending tickets that did get a customer reply last quarter, 61% of replies
arrived within 48 hours. The rest arrived between day 3 and day 7, often
because the customer had to collect logs, ask their IT department, or wait for
the issue to happen again.

## Risks

- Some customers may find a 48-hour window short. The closing message tells
  them how to get help again.
- The satisfaction survey fires on close, so survey volume will arrive earlier
  in the ticket lifecycle. Response rates should be unaffected.

## Decision requested

Approve the rule change to take effect on the 1st of next month.
