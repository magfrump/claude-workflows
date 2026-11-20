# Pre-Mortem: Tessellate Pay → Corvid Payments migration

**Proposal:** Move card processing from Tessellate Pay to Corvid Payments (Payments team; for approval by the Finance and Engineering leads)
**Date:** 2026-11-19
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** These failure narratives come straight from the proposal. They would be sharper if seeded from a `what-if-analysis` run, which maps the assumptions and coupling points first.

> ℹ️ **Prior Art Check skipped.** No repository was available, so `docs/decisions/` and `docs/working/` were not searched. No narrative carries a `[PRIOR CONSIDERATION]` tag. The proposal's own "Risks we have considered" section is the only prior reasoning I could check against, and I note where a narrative overlaps it.

**Reading the proposal against itself:** Several of these failures come from comparing dates and rules that sit in different sections:
- *Commercial position:* Tessellate ends 30 June.
- *Ramp:* 50% on 7 July, 100% on 21 July.
- *Rollback:* depends on Tessellate.
- *Refunds:* go back through the original processor, for stays up to eleven months out.
- *Clean-up:* removes the Tessellate adapter in August.

Each section is reasonable on its own. They do not fit together.

---

## Failure Narratives

### 1. The 30 June Cliff

- **Root cause:** Plan §2 (Ramp) leaves 75% of new bookings on Tessellate on 30 June, the date the Commercial position section says the Tessellate agreement ends. No one owned the overlap between the commercial date and the ramp calendar.
- **Chain of consequences:**
  1. The ramp ran on schedule: 5% on 2 June, 25% on 16 June. The 50% step was not due until 7 July.
  2. At 00:00 on 1 July, Tessellate disabled the production API credentials under the terminated agreement. The 75% of checkout traffic still routed there began returning authentication errors from `payments-gateway`.
  3. The Rollback section's only recovery is "set the percentage flag back to 0." That would have sent 100% of traffic to the processor that had just stopped working. The documented recovery made things worse.
  4. The on-call engineer did the opposite and set the flag to 100% Corvid. That was a jump from 25% to 100% with no gate week. It came two weeks earlier than planned, and Corvid had not been notified of a fourfold traffic increase.
  5. From then on the migration had no rollback path. Every later problem, including Narrative 4, had to be fixed forward on Corvid.
- **Observable outcome:**
  - About 600 card payments are taken per day (18,000/month). For the roughly 3–5 hours between the first errors and the flag flip, about 75% of checkout attempts failed with a generic payment error. That is roughly 60–110 lost or delayed bookings, in peak summer booking season.
  - The status page and support queue filled with "card declined" complaints from guests whose cards were fine.
  - Softer variant: Tessellate kept processing out of contract at its undiscounted list rate. Then the outcome is a surprise invoice rather than an outage, but the missing rollback path is the same.
- **Plausibility:** Likely. The conflict is in the dates as written. The only question is whether someone notices before 1 July.
- **Severity:** High
- **Mitigation:** Rewrite the Plan §2 ramp so 100% Corvid is reached by about 16 June, leaving a two-week buffer before 30 June. Alternatively, before approval, get a written month-to-month extension from Tessellate through at least 31 August and add it to the Commercial position section. Then reword the Rollback section to say rollback to Tessellate is unavailable after the agreement end date, and define what replaces it.

### 2. The Orphaned Refunds

- **Root cause:** Plan §3 (Refunds and adjustments) routes each refund back through the processor that took the original payment. Plan §4 (Clean-up) removes the Tessellate adapter in August. Bookings taken on Tessellate before 30 June have stays running until about May of the following year, and refunds cluster in the four weeks before each stay.
- **Chain of consequences:**
  1. Every booking taken on Tessellate up to cut-over had a refund path that depended on Tessellate. That covered almost all bookings before June and most bookings in June.
  2. The refund wave for those bookings started in July and peaked in July–October, matching summer and early-autumn stays. It tailed off through the spring.
  3. After 30 June, refund calls to Tessellate failed, or succeeded only through the Tessellate dashboard if access survived. The August clean-up then deleted the code path entirely.
  4. Support started issuing refunds by hand: bank transfers and goodwill credits, none of them linked to the original card transaction.
  5. Guests who did not get their refund on time filed chargebacks for "credit not processed." Those chargebacks landed on the Tessellate account (see Narrative 3).
- **Observable outcome:**
  - The proposal does not give the size of the Tessellate forward book. Assuming typical holiday-rental lead times, bookings with stays after 30 June number in the tens of thousands. At a 6% refund rate, that is on the order of 2,000–3,000 refunds with no working automated path. The team can compute the real figure from the forward book.
  - The refund-failure error rate in `payments-gateway` jumped from about 0 to near 100% for Tessellate-origin transactions on 1 July.
  - Finance's reconciliation, scoped to "during the ramp" in Risks, ran on a schedule that had already ended.
- **Plausibility:** Likely
- **Severity:** High. Unpaid refunds mean consumer-protection exposure, chargeback fees, and manual work spread over about 11 months.
- **Mitigation:** Before approval, get written confirmation from Tessellate that refund and dispute processing stays available after termination, for the life of the forward book plus the chargeback window. Add that to the Commercial position section. Change the Plan §4 clean-up trigger from "all traffic on Corvid for a month" to "the last Tessellate-origin stay date plus the network chargeback window has passed." Extend Finance's two-file reconciliation commitment in Risks to cover that same period.

### 3. The Reserve Nobody Read

- **Root cause:** The proposal treats the Tessellate termination as a clean end. Travel is a future-delivery business, and termination clauses for future-delivery merchants commonly let the processor hold funds against undelivered services. Here the undelivered services are every Tessellate-paid stay after 30 June.
- **Chain of consequences:**
  1. In July, Tessellate's risk team saw a terminated merchant with a large book of paid-but-undelivered stays and disputes still arriving.
  2. It applied the reserve or holdback terms in the agreement. Settlement payouts on the final weeks of Tessellate volume were withheld, released only as stay dates passed and dispute windows closed.
  3. At the same time, chargebacks on Tessellate transactions kept arriving: the "credit not processed" claims from Narrative 2 plus ordinary travel disputes. Those disputes can arrive long after the transaction, because for future services the deadline runs from the stay date. They were debited from the funds Tessellate was holding.
  4. Dispute evidence had to be submitted through the Tessellate portal. Portal access was tied to the account and was downgraded, so several disputes were lost by default because no one responded in time.
- **Observable outcome:**
  - In the Finance cash forecast, expected Tessellate settlements arrived late or reduced for months. The forward book's value is plausibly in the low tens of millions of dollars (tens of thousands of bookings at about $565 average).
  - A holdback of even a fraction of that was a working-capital hit comparable to several years of the $610,000 annual saving.
  - Dispute win rate on Tessellate transactions fell sharply from July onward.
- **Plausibility:** Plausible. It depends on the agreement's termination clauses, which the proposal does not mention.
- **Severity:** High
- **Mitigation:** Before approval, Legal should review the Tessellate agreement's termination, reserve, and post-termination dispute clauses. Record in the Commercial position section the expected holdback amount, the release schedule, and how long dispute-portal access lasts. Add the expected holdback to the Finance cash forecast as a sign-off condition for the Finance lead.

### 4. The Gate That Couldn't See

- **Root cause:** The Plan §2 ramp gate is a week of authorisation rates within half a point of Tessellate, and no rise in chargebacks. Neither measure can detect a problem at the volumes involved.
  - **Authorisation rate:** At 5% of about 4,150 weekly payments, Corvid handled about 210 transactions. Assuming a roughly 90% authorisation rate, the 95% confidence interval on that measurement is about ±4 points.
  - **Chargebacks:** Travel chargebacks mostly arrive after the stay, months after booking, so a week of data shows nothing.
- **Chain of consequences:**
  1. The 5% and 25% gates "passed" on noise. Each week's authorisation-rate difference was well inside the error bars, and the chargeback count was zero because no Corvid-paid stay had happened yet.
  2. After the forced jump to 100% in Narrative 1, real volume showed what the gates could not. Authorisation rates were about 1.5 points lower for a cluster of issuers, concentrated in two European markets where Corvid's 3-D Secure exemption handling differed from Tessellate's.
  3. With Tessellate gone there was no rollback. The team spent weeks on issuer-by-issuer tickets with Corvid while the gap persisted.
  4. Corvid-origin chargebacks started appearing in September and October as summer stays completed. Only then did the "no rise in chargebacks" criterion produce its first real data, after every gate had already been passed.
- **Observable outcome:**
  - A 1.5-point authorisation-rate drop across about 18,000 monthly payments is about 270 extra declines a month. Some guests retried with another card; some abandoned the booking.
  - That pattern showed up on the gateway's authorisation-rate-by-issuer panel only after full cut-over.
- **Plausibility:** Plausible. A 0.5–2 point authorisation shift for some issuers is common in processor migrations, and Risks names it. The hidden part is that the gate cannot detect it.
- **Severity:** Medium. Real revenue loss, recoverable through tuning, but slower to fix with no rollback.
- **Mitigation:** Rewrite the Plan §2 gate criteria:
  - Set a minimum sample size per step. Detecting a 0.5-point difference needs roughly 14,000 Corvid transactions, so either widen the tolerance or lengthen the step.
  - Measure authorisation rate by issuer country and by 3-D Secure outcome, not only in aggregate.
  - Replace "no rise in chargebacks" with a leading indicator that exists within a week, such as issuer fraud reports or early "unrecognised transaction" disputes.
  - Write down that chargebacks for future-dated stays cannot gate a ramp step.

### 5. The Token Delta

- **Root cause:** Plan §1 runs the network token transfer once, during Integration (April to mid-May). Through May and June, most new bookings still went to Tessellate, so cards saved in that window were stored only at Tessellate and were never in the transfer. Corvid's "under 1% miss rate" applied only to the snapshot.
- **Chain of consequences:**
  1. The transfer finished in mid-to-late May with a reported 0.6% miss rate, within expectation.
  2. Six to eight more weeks of new stored cards accumulated at Tessellate: about 95% of new bookings until 2 June, then about 75% until cut-over. Peak summer booking season is when many first-time guests save a card.
  3. When Tessellate access ended on 30 June, a second transfer was no longer straightforward to arrange.
  4. When those guests returned to book in the autumn and the following year, the saved card on file had no matching Corvid token. Charges failed and guests were asked to re-enter their card.
  5. If `payments-gateway` also charges stored cards for balance payments or damage on existing bookings, which the proposal does not say, those charges failed silently for the same cohort.
- **Observable outcome:**
  - The "stored card not found" error rate on Corvid was well above the 1% expectation, concentrated among cards saved between the snapshot date and 30 June.
  - Repeat-guest checkout completion dropped, and support tickets from returning guests rose with the theme "my saved card disappeared."
- **Plausibility:** Likely
- **Severity:** Low if stored cards are used only for convenience at next booking. Medium if they are used to collect balances on existing bookings.
- **Mitigation:** Add a second, delta token transfer to Plan §1, scheduled after traffic reaches 100% Corvid and before 30 June, covering every card stored at Tessellate since the first snapshot. Put Tessellate's agreement to perform it in the Commercial position section. State in Plan §1 whether stored cards are charged for balances. If they are, track missing-token failures as a separate alert from re-entry friction.

---

## Recommendations

### Must address before proceeding

The decision requested, "approve the ramp schedule and the August clean-up," asks for approval of the two parts that fail most clearly. I recommend not approving either as written.

- **Narrative 1 (30 June Cliff):** Finish the ramp before 30 June with a buffer, or get a written Tessellate extension. Reword the Rollback section so it does not promise a path to a terminated processor.
- **Narrative 2 (Orphaned Refunds):** Get post-termination refund and dispute access from Tessellate in writing. Tie the Plan §4 clean-up date to the end of the Tessellate forward book plus the chargeback window, not to "a month on Corvid."
- **Narrative 3 (Reserve):** Legal review of the termination and reserve clauses, with the expected holdback in Finance's forecast. This can be resolved with a document review. It belongs here because the cost of not knowing may exceed several years of the projected saving.

### Worth mitigating

- **Narrative 4 (Gate That Couldn't See):** Redefine the Plan §2 gates with sample sizes and per-issuer measurement. Once Narrative 1 is fixed and rollback exists again, this decides whether the gates protect anything.
  - **Watch signal:** authorisation rate by issuer country, with an alert if Corvid falls more than 1 point below Tessellate on at least 2,000 transactions in a segment.
- **Narrative 5 (Token Delta):** Schedule the delta transfer before 30 June.
  - **Watch signal:** `stored card not found` rate on Corvid, with an alert above 1% of stored-card attempts.

### Acknowledged risks

- **Residual authorisation-rate tuning after cut-over:** Once the gates are fixed, a small remaining gap for some issuers is a normal cost of switching processors. It is reasonable to carry it against the $610,000 annual saving.
- **The original ~1% token miss rate in the snapshot:** Re-entering a card at next booking is an acceptable cost, as Risks already says, provided the delta in Narrative 5 is handled separately.
