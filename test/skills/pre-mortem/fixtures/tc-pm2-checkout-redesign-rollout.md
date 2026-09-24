# Launch plan: One-page checkout for Brindle & Co.

**Owner:** Checkout squad · **Status:** ready for go/no-go review

## What we are shipping

The current checkout is four pages: basket, address, delivery, payment. The new
one-page checkout collapses them into a single page with inline address lookup,
delivery-slot selection and a saved-card wallet. In a two-week A/B test at 5%
of traffic in September, conversion rose from 3.1% to 3.6% and average time to
purchase fell by 48 seconds. The new page calls three services the old one did
not: the address-lookup service, the delivery-slot service (synchronously, on
page load) and the wallet service.

## Rollout schedule

| Date | Share of traffic on new checkout |
|---|---|
| Tue 11 Nov | 10% |
| Tue 18 Nov | 50% |
| Tue 25 Nov | 100%, old checkout code path removed in the same release |

Each step proceeds if conversion and error rate at the previous step are no
worse than control. Removing the old code path in the 25 November release keeps
us from maintaining two checkouts through December.

## Readiness

- **Load testing.** The new checkout and its three downstream services were load
  tested in October at 1.5x our normal weekday peak. p99 page load stayed under
  900 ms. The delivery-slot service was the slowest component, at 410 ms p99.
- **Feature flag.** Traffic share is controlled by the `checkout_v2_share` flag.
  Once the old code path is removed, the flag no longer has anything to fall
  back to and will be deleted.
- **Monitoring.** A checkout dashboard shows conversion, payment errors, and
  per-service latency. Alerts page the Checkout squad on-call.
- **Support.** Customer Service has a one-page guide to the new flow.

## Calendar context

The engineering-wide change freeze runs from Wed 26 November to Tue 2 December.
During the freeze, production deploys need sign-off from the VP of Engineering
and are limited to Sev-1 fixes.

Our retail calendar is the same as last year's. Traffic over the Black Friday
to Cyber Monday weekend (28 November to 1 December) ran at roughly four times
a normal weekday peak last year, and December overall ran at about twice
November.

## Success criteria

- Conversion at or above 3.5% across December.
- Payment error rate no higher than the old checkout's 0.4%.
- No increase in checkout-related support contacts per thousand orders.

## Decision requested

Go/no-go on the 11 November start.
