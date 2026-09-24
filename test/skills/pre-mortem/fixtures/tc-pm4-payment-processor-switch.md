# Proposal: Move card processing from Tessellate Pay to Corvid Payments

**Owner:** Payments team · **Status:** for approval by the Finance and Engineering leads

## Why

Luma Stays takes about 18,000 card payments a month for holiday rentals.
Corvid quoted a blended rate of 1.9% against Tessellate's 2.4%, which saves
roughly $610,000 a year at current volume, and Corvid supports the local payment
methods we need for the Portugal and Greece launches in the autumn.

## Commercial position

Our Tessellate agreement is on a fixed three-year term that ends on 30 June.
Legal served the non-renewal notice in March, as the agreement requires 90 days'
notice, so the agreement will end on that date rather than roll over for another
three years. Corvid's agreement is signed and its rate applies from our first
transaction.

## Technical plan

The checkout already talks to Tessellate through our internal `payments-gateway`
service, so the change is mostly behind that service.

1. **Integration** (April to mid-May). Add a Corvid adapter to
   `payments-gateway`. Stored cards are migrated with a network token transfer
   that Corvid runs on our behalf; it completes in about two weeks.
2. **Ramp.** Route by guest country and by a percentage flag in the gateway:
   - 2 June: 5% of new bookings on Corvid
   - 16 June: 25%
   - 7 July: 50%
   - 21 July: 100%
   Each step needs a week of authorisation rates within half a point of
   Tessellate and no rise in chargebacks.
3. **Refunds and adjustments.** A refund goes back through whichever processor
   took the original payment. Guests book up to eleven months ahead, and we
   refund about 6% of bookings, mostly in the four weeks before the stay.
4. **Clean-up** (August). Remove the Tessellate adapter once all traffic has been
   on Corvid for a month.

## Rollback

At any ramp step, setting the percentage flag back to 0 sends all new bookings
to Tessellate again within a minute. We will keep the Tessellate adapter in the
code through August for this purpose.

## Risks we have considered

- **Authorisation rates** could dip for some card issuers on a new processor.
  The ramp gates cover this.
- **Token transfer** could miss some stored cards. Guests would re-enter their
  card at next booking; Corvid expects a miss rate under 1%.
- **Reconciliation.** Finance will reconcile two settlement files during the
  ramp; the Finance lead has agreed to this.

## Decision requested

Approve the ramp schedule and the August clean-up.
