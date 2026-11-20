# Pre-Mortem: Brindle & Co. one-page checkout launch

**Proposal:** Launch plan: One-page checkout for Brindle & Co. (Checkout squad, go/no-go on the 11 Nov start)
**Date:** 2026-11-19
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** These failure narratives come straight from the proposal. For sharper narratives, run `what-if-analysis` first and pass in its output. This skill works best when it starts from assumptions and coupling points that have already been mapped.

> **Prior art check skipped.** No repository is available, so `docs/decisions/` and `docs/working/` were not searched. None of the narratives below is tagged `[PRIOR CONSIDERATION]`.

> **Note on dates.** The plan's weekday labels (Tue 11 Nov, Tue 18 Nov, Tue 25 Nov, Black Friday 28 Nov) match the 2025 calendar. In 2026, 11 Nov falls on a Wednesday and Black Friday is 27 Nov. Today is 19 Nov, so a "Tue 11 Nov" start is already in the past for 2026. Confirm which year the schedule targets before the go/no-go. The narratives below use the plan's dates as written. Every failure mode still applies if the dates shift by a day.

---

## Failure Narratives

### 1. The Black Friday Slot Stall

- **Root cause:** The delivery-slot service is called **synchronously on page load** and was load tested only to **1.5x normal weekday peak** (Readiness › Load testing). Black Friday traffic arrives at about **4x**, roughly 2.7x beyond the tested envelope, on the slowest component in the path. That component was already at 410 ms p99 at 1.5x.
- **Chain of consequences:**
  1. At 07:00 GMT on Fri 28 Nov, traffic crosses about 2.5x weekday peak. Slot computation slows because December slot inventory is sparse and each request scans more candidate slots. p99 climbs from 410 ms to 2.8 s.
  2. Checkout page requests hold connections while they wait on the slot call. The page tier's connection pool saturates, and page loads that never touch slots also start queuing.
  3. Retries from the page tier and from customers hammering refresh push the slot service into timeouts. The page has no degraded "choose your slot later" state, because the slot call blocks render.
  4. Under the old four-page flow, a slot outage would have hit only the delivery step. Now it blocks the **entire** checkout, including basket review and payment for people who had already picked a slot.
  5. The flag that could have shed load back to the old flow was deleted on 25 Nov (see narrative 2).
- **Observable outcome:** The checkout dashboard shows per-service latency for delivery-slot pinned at the timeout ceiling. Page-load p99 is above 6 s. Conversion falls from about 3.6% to 1.2% between 07:00 and 11:30. Checkout on-call gets about 140 pages in the first hour. Social media posts complain that "checkout won't load". Lost revenue is concentrated in the highest-value four hours of the year.
- **Plausibility:** Plausible (upper end. This traffic level was never tested, and the call that fails it sits on the critical path.)
- **Severity:** High (recoverable, but the cost lands in the peak trading window. It becomes near-catastrophic when combined with narrative 2.)
- **Mitigation:** Change Readiness › Load testing to require a soak test at **≥4.5x weekday peak**, with December-density slot inventory, before the 18 Nov step. Gate the 50% step on delivery-slot p99 < 600 ms at that load. In the page code, move the delivery-slot call off the synchronous render path: render the page with the slot section in a loading state, fetch slots asynchronously with a 1 s timeout, and fall back to "we'll confirm your slot by email".

### 2. Nothing to Roll Back To

- **Root cause:** The 25 Nov release bundles three irreversible moves into the last deploy day before the freeze (Rollout schedule; Readiness › Feature flag): 100% traffic, removal of the old code path, and deletion of `checkout_v2_share`. From 26 Nov to 2 Dec, every fix is a forward fix that needs VP sign-off and a Sev-1 classification.
- **Chain of consequences:**
  1. The 100% step gets about 18 hours of observation on an ordinary Tuesday before the freeze starts. The "no worse than control" gate cannot be evaluated at 100%, because control no longer exists.
  2. On Sat 29 Nov the wallet service starts returning intermittent 502s on saved-card tokenization under BFCM load. The payment error rate reaches 1.1%, against the 0.4% old-checkout baseline.
  3. Checkout still works for customers who enter a new card, so the incident commander hesitates to call it Sev-1. Forty minutes go to severity triage on the bridge call.
  4. The VP of Engineering is reached on a holiday-weekend Saturday 55 minutes after the page. A forward fix (skip the wallet when it is unhealthy) has to be written, reviewed, and deployed under pressure. In the old world this would have been a flag flip.
  5. The fix ships at 14:10, about 3.5 hours after onset. A second, smaller issue on Sun 30 Nov is judged "not Sev-1" and waits until 3 Dec.
- **Observable outcome:** Payment errors sit above 1% for roughly 3.5 hours on Black Friday Saturday. The incident timeline shows about 95 minutes spent on severity classification and approval rather than remediation. The December success criterion "payment error rate ≤ 0.4%" is missed on the busiest weekend. The post-incident review finds that a rollback would have taken under 5 minutes.
- **Plausibility:** Likely (the chance that *some* defect or capacity issue needs rollback during an untested 4x weekend is well over 50%)
- **Severity:** High
- **Mitigation:** Split the 25 Nov release in Rollout schedule into two: (a) 25 Nov moves `checkout_v2_share` to 100% with the old code path **retained and the flag kept live**; (b) old-path removal and flag deletion are scheduled as a January release, after the 2 Dec freeze ends. Add to Readiness › Feature flag: "Setting `checkout_v2_share` to 0 is a pre-approved freeze action that does not require VP sign-off". Agree this with the VP before 25 Nov.

### 3. The Address Lookup Quota Wall

- **Root cause:** The address-lookup service was load tested at 1.5x, but its capacity limit comes from its upstream postcode/address data provider, not from Brindle's own infrastructure. A per-second or per-month request quota holds at normal volume and breaks at 4x. The plan does not say whether the inline lookup has a manual-entry fallback. This narrative assumes it has none.
- **Chain of consequences:**
  1. Inline lookup fires a request on every keystroke burst (debounce at 150 ms). At 4x traffic, Brindle's request rate to the provider crosses the contracted 200 req/s ceiling around 09:00 on Black Friday.
  2. The provider returns HTTP 429. The address-lookup service passes the error through as an empty result list.
  3. Customers see "No addresses found for this postcode". Because no "enter address manually" link appears on an empty result, new customers without a saved address cannot proceed.
  4. Returning customers with saved addresses are unaffected, so aggregate conversion falls only moderately, which slows detection. Payment errors stay flat, so the payment alert never fires.
  5. On the second day of 429s, the provider's monthly credit allowance runs out, and lookup fails completely until the account owner, who is on leave, approves a top-up.
- **Observable outcome:** Address-lookup per-service latency looks *healthy*: fast responses, because they are fast empty responses. First-time-customer conversion falls from about 2.9% to about 1.4% while returning-customer conversion holds. Customer Service logs about 600 contacts tagged "can't find my address" over the weekend, which pushes support contacts per thousand orders above the success-criteria baseline.
- **Plausibility:** Plausible
- **Severity:** Medium
- **Revisit trigger:** Add an alert on the checkout dashboard for `address_lookup.upstream_429_count > 50 per 5 min` **or** `address_lookup.empty_result_rate > 15% sustained for 10 min`. The second condition is needed because an empty-result spike is the failure signature, and latency hides it. (Also confirm the provider's per-second and monthly limits against 4x Black Friday volume before 18 Nov, and ensure a manual-entry fallback renders on empty results. See Recommendations.)

### 4. The Gate That Couldn't Fail

- **Root cause:** The rollout gate is "no worse than control" with no stated margin or sample size, evaluated weekly (Rollout schedule). The December success criterion is an absolute 3.5% conversion with no control group (Success criteria). Once the 25 Nov release removes the old path, the team loses any way to attribute December conversion to the checkout rather than to seasonality.
- **Chain of consequences:**
  1. The 10% and 50% steps each run for one November week. Week-to-week noise at 10% traffic is wider than the September lift, so the gate passes on "not significantly worse", which is a weak test.
  2. The September result (3.1% → 3.6%) came from a two-week, 5% test in a low-season month. Part of it was novelty: returning customers were trying the new flow out of curiosity.
  3. December traffic skews toward gift buyers and first-time visitors, who historically convert differently from September regulars.
  4. December conversion lands at 3.4%. With no holdout, the team cannot say whether the new checkout underperformed, December's traffic mix diluted it, or the BFCM incidents (narratives 1 and 2) dragged it down.
  5. The January retrospective turns into an unresolvable argument. The roadmap item "extend one-page pattern to mobile app" is frozen pending an answer nobody can produce.
- **Observable outcome:** The December dashboard shows conversion at 3.4% against a 3.5% target. The success criteria are marked "missed" with no causal attribution. The squad cannot answer "was the launch a success?" in the January business review, and leadership confidence in A/B-test-driven launches drops.
- **Plausibility:** Likely
- **Severity:** Medium
- **Mitigation:** In Rollout schedule, keep a **2–5% holdout on the old checkout through 31 December**. This requires the change in narrative 2's mitigation to retain the old code path. Rewrite Success criteria to be relative: "conversion ≥ holdout + 0.3 pp across December, with a pre-registered sample size". Define the per-step gate as a non-inferiority test with an explicit margin (for example, "lower 95% bound of conversion difference > −0.2 pp").

### 5. The Abandoned-Basket Dead Links

- **Root cause:** The 25 Nov release removes the old four-page flow's routes, such as `/checkout/address` and `/checkout/delivery`. Existing links into those routes stay live: abandoned-basket recovery emails, in-flight sessions, and customers' bookmarks. The plan does not mention redirects.
- **Chain of consequences:**
  1. Before 25 Nov, about 50% of customers are in the old flow. Abandoned-basket emails generated in the previous week deep-link to the step where each customer left off.
  2. The release deploys at 14:00 Tuesday. Customers mid-flow in the old checkout click "Continue to delivery" and get a 404 or a generic error page.
  3. Over Black Friday, the abandoned-basket campaign sends its scheduled "Your basket is waiting — 15% off this weekend" reminder. The email was templated against old-flow URLs and lands thousands of high-intent customers on a dead page.
  4. Some customers give up. Others contact support, and the Customer Service one-page guide covers the new flow but not "the link in your email is broken".
- **Observable outcome:** Web logs show a spike in 404s on `/checkout/address` and `/checkout/delivery` from 25 Nov, peaking around 4,000/hour after the Black Friday email send. Abandoned-basket email recovery conversion falls from its usual rate to near zero. Support contacts tagged "broken checkout link" reach about 300 over the weekend.
- **Plausibility:** Plausible
- **Severity:** Low (cosmetic and easily fixed with redirects, but the fix lands during the freeze, and the cost concentrates on the most valuable email send of the year)
- **Mitigation:** Add a step to the 25 Nov release (Rollout schedule) that 301-redirects every old checkout route (`/checkout/address`, `/checkout/delivery`, `/checkout/payment`) to the one-page checkout with the basket preserved. Before 25 Nov, update the abandoned-basket email templates to link only to the basket URL, and add a pre-release check that each old route returns a redirect, not a 404.

---

## Recommendations

### Must address before proceeding

- **Narrative 2: Nothing to Roll Back To (Likely / High).** This is the single highest-leverage change in the plan. Keep the old code path and `checkout_v2_share` alive through the freeze, and pre-authorize "set flag to 0" as a freeze action that needs no VP sign-off. This change makes every other narrative cheaper. As written, removing the old path *the day before* a freeze that spans a 4x weekend turns minor incidents into multi-hour ones.
- **Narrative 1: The Black Friday Slot Stall (Plausible / High).** The plan's own numbers show the gap: tested at 1.5x, expecting 4x, with the slowest service on a synchronous path. Before the 18 Nov 50% step, either load test at ≥4.5x with December slot density or make the slot call non-blocking with a timeout and fallback. Doing both is better.

Given these two, the honest answer to "go on 11 Nov?" is **go on the 10% and 50% steps, no-go on the 25 Nov release as written.** The early steps are low-risk and produce useful data. The danger is concentrated in the 25 Nov bundle.

### Worth mitigating

- **Narrative 4: The Gate That Couldn't Fail (Likely / Medium).** This is cheap once narrative 2 is fixed. Keep a 2–5% holdout through December and restate the success criteria relative to it. Without a holdout, December's result cannot be interpreted.
- **Narrative 3: The Address Lookup Quota Wall (Plausible / Medium).** Before 18 Nov, confirm the upstream provider's per-second and monthly limits against 4x Black Friday volume, and make sure an empty or failed lookup always offers manual address entry. Add the empty-result-rate alert from the narrative's revisit trigger.
- **Narrative 5: The Abandoned-Basket Dead Links (Plausible / Low).** Add redirects and audit the email templates. This is an hour of work that prevents a self-inflicted wound on the year's biggest email send.

### Acknowledged risks

- None of the five narratives belongs in this group as written. The remaining risk the team can reasonably accept is **novelty-effect decay**: the September lift of +0.5 pp may shrink in December even if nothing breaks. That is an honest outcome, not a failure, and the holdout from narrative 4 is what lets the team tell the two apart.
