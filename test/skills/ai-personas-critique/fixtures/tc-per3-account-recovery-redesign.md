# Faster Account Recovery for Tallyfin Wallet

**Team:** Identity and Access, Tallyfin
**Stage:** Design proposal, requesting sign-off from Product and Risk

## The problem

Tallyfin Wallet lets customers hold a balance, pay friends, and pay at merchants that accept Tallyfin codes. About 1.9 million customers are active in a given month, and the median balance is $140, though roughly 6 percent of accounts hold more than $2,000.

Account recovery is our single largest source of support contacts. When a customer forgets their password or changes phones, today's flow asks them to:

1. Enter a one-time code sent by SMS to the phone number on file;
2. Click a link sent to the email address on file;
3. Upload a photo of a government ID and take a selfie, which a vendor matches within about ten minutes.

Customers who complete all three steps get back in. Many do not. Last quarter 38 percent of recovery attempts were abandoned, most often at the email step (customers no longer have access to the address they signed up with) or at the ID step (they do not have their ID with them, or the selfie match fails in poor lighting). Abandoned recoveries turn into support calls, which average 14 minutes, and into one-star app store reviews that mention being "locked out of my own money."

## Proposal

We will replace the three-step flow with a single step for most customers, and give support agents a clear path for the rest.

**Self-service recovery.** A customer who taps "Can't sign in" receives a six-digit code by SMS at the phone number on file. Entering the code lets them set a new password and signs them in on the new device. The email and ID steps are removed.

**Assisted recovery.** A customer who no longer has the phone number on file can call support. The agent verifies identity by asking for the customer's full name, date of birth, and the last four digits of the debit card linked to the account. If all three match, the agent updates the phone number on file to the number the customer provides, and the customer then completes self-service recovery with a code sent to the new number.

**Session continuity.** After recovery, existing payees, saved cards and the customer's balance remain available immediately, so customers can get on with paying for things. We considered a holding period on outgoing transfers but rejected it because the most common reason for recovery is a customer standing at a checkout who needs to pay now.

## Expected results

In the internal test with 4,000 customers, the single-step flow had a completion rate of 93 percent against 62 percent for the current flow, and median time to recover fell from eleven minutes to under one. We expect recovery-related support contacts to fall by about two thirds, which frees roughly nine agent positions for other queues.

The ID-verification vendor charges $1.10 per check. At our volume of about 55,000 recoveries per month, removing the step saves roughly $60,000 a month, or $726,000 a year, before counting the support savings.

## Why this is safe enough

SMS codes are already our primary second factor for sign-in, so recovery by SMS does not introduce a new mechanism. Codes expire after five minutes and are rate-limited to five attempts. The knowledge questions used in assisted recovery are the same ones our card issuer uses on its own support line. Agents will be trained on the script and cannot skip any of the three checks.

## Rollout plan

- **Weeks 1–2:** Ship to 10 percent of customers; monitor completion and contact rate.
- **Weeks 3–4:** Ship to 50 percent.
- **Week 5:** Full rollout; retire the ID-verification integration.

## Asks

Sign-off from Product on the new flow, from Risk on the removal of the email and ID steps, and from Support Operations on the assisted-recovery script.
