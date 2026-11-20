# What-If Analysis: Swap the outbound HTTP client in `quote-service` behind a flag

**Proposal:** Replace `pyrequest-classic` with `pyrequest-pooled` in `quote_service/providers/http.py`, selected per request by the `quote_http_pooled` flag (Pricing team, Corvel Freight)
**Date:** 2026-11-20
**Upstream critiques:** none

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output — this skill is most powerful when focused on the gaps that critics miss.

**Prior Art Check:** No repository was available, so `docs/decisions/` and `docs/working/` could not be searched. No `[PRIOR CONSIDERATION]` findings are possible. The proposal's own "Risks we considered" section is treated as the baseline of examined territory.

**Overall read:** This is a well-scoped, well-rehearsed change, and its rollback story holds up. The real risks are not about undoing the change. They are about whether the rollout signals can detect the failure modes that long-lived connections introduce. Those modes are slow, rare, and triggered by events (provider deploys, DNS changes, LB idle expiry, traffic peaks) that a 1% synthetic rehearsal and a three-day step will not reliably hit.

---

## Assumptions Examined

- **Assumption:** `pyrequest-pooled` has "the same request/response API", so retries, timeouts and error handling behave identically.
  - **Source:** explicit ("What and why"; "No change to … timeouts, retries")
  - **If wrong:** redesign. If the clients raise different exception classes for connection resets, or apply timeouts differently (per-attempt vs per-request, connect timeout skipped on a reused connection), the unchanged retry logic silently changes behaviour. Calls that used to retry may fail, and calls that used to fail fast may retry.
  - **Tag:** `[NOVEL]`

- **Assumption:** Reusing connections across the internal LB's keep-alive boundary is safe. That is, the pooled client will not send requests on a connection the LB has already closed.
  - **Source:** implicit (the whole benefit comes from crossing the boundary `pyrequest-classic` refuses to cross)
  - **If wrong:** redesign. Stale-connection reuse yields `ECONNRESET` or empty-response errors on the first request after an idle period. If provider calls are POSTs, the client may correctly refuse to auto-retry them, which surfaces errors as failed quotes.
  - **Tag:** `[NOVEL]`

- **Assumption:** A year of production use by Billing and Routing transfers to `quote-service`.
  - **Source:** explicit ("What and why")
  - **If wrong:** tweak to redesign. It transfers only if traffic shape (bursty vs steady), LB path, idle timeouts, concurrency model (threads, async, pre-fork workers) and provider endpoints are similar. The proposal does not say they are.
  - **Tag:** `[NOVEL]`

- **Assumption:** The TLS handshake count dashboard measures the same thing under both clients.
  - **Source:** implicit (Rollout step 3 relies on it as the success signal)
  - **If wrong:** redesign of the rollout. If the metric comes from a hook or instrumentation in `pyrequest-classic` and the new client doesn't emit it, the pooled share reads as zero handshakes. That looks like success and is actually blindness.
  - **Tag:** `[NOVEL]`

- **Assumption:** Provider connection limits at "10x our peak" give ample headroom for long-lived pooled connections.
  - **Source:** explicit ("Risks we considered")
  - **If wrong:** tweak. Pool size caps fix it. The danger is that "peak" was measured as concurrent active connections under the classic client. Pooled connection count scales with *worker processes × pool size × provider hosts*, held idle, and both pools coexist during the 5% and 50% stages.
  - **Tag:** `[NOVEL]`

- **Assumption:** The client "holds no state beyond its connection pool".
  - **Source:** explicit ("Rollback")
  - **If wrong:** tweak. The pool itself carries state that matters: resolved IPs (DNS), which LB backend each connection is pinned to, TLS session and certificate. That doesn't affect rollback. It affects correctness during normal operation (see couplings).
  - **Tag:** `[NOVEL]`

- **Assumption:** The client in `http.py` is constructed in a way that is safe for the service's process and concurrency model.
  - **Source:** implicit
  - **If wrong:** redesign. If the client is built at import time and the server pre-forks workers (e.g., gunicorn with `preload_app`), forked workers can share pooled TLS sockets and corrupt each other's streams. Per-host pooling in the classic client may have hidden this. A long-lived cross-boundary pool makes it more likely to bite.
  - **Tag:** `[NOVEL]`

- **Assumption:** Three-day stages at 5% and 50% are long enough to exercise the risky conditions.
  - **Source:** explicit ("Rollout")
  - **If wrong:** tweak. Lengthen the stages, or deliberately trigger provider deploys or LB events while at 50%.
  - **Tag:** `[NOVEL]`

## Consequence Chains

**Outcome 1: Fresh-handshake share falls from ~8% to <1%.**
```
→ First-order: far fewer TLS handshakes; connections live much longer
  → Second-order: connections stay pinned to whichever LB backend / provider instance they first reached
    → Third-order: when a rate provider scales out, new instances receive little traffic until old
      connections churn; hot instances stay hot, so provider-side latency or errors rise during load
      spikes, which is exactly when autoscaling was supposed to help
    → Third-order: when a provider deploys or drains an instance, the in-flight requests on its
      pooled connections see resets in a burst rather than a trickle
  → Second-order: connections outlive DNS records and certificates
    → Third-order: a provider failover or IP migration via DNS is invisible to quote-service until
      connections break; certificate rotation or revocation takes effect only on reconnect
```

**Outcome 2: p95 quote latency drops ~20 ms.**
```
→ First-order: quotes are faster
  → Second-order: the handshake share stops being a meaningful tail signal; dashboards and alerts
    tuned to the old latency profile lose sensitivity
  → Second-order: if quote callers fan out or retry on latency, slightly faster quotes slightly
    raise throughput to providers (minor; not a real concern at 20 ms)
```
Calibration: the 20 ms figure is plausible. With three provider calls per quote, roughly 22% of quotes include at least one handshake, so handshakes do sit in the p95 band. If the calls are parallel and handshakes are not the slowest leg, the gain will be smaller. This affects whether the project is worth it, not safety.

**Outcome 3: Two clients coexist, chosen per request.**
```
→ First-order: each worker holds two live pools (classic and pooled) during 5% and 50% stages
  → Second-order: at 5%, the pooled pool is sparsely used, so its connections idle longest, which
    maximises stale-connection reuse against the LB idle timeout
    → Third-order: the 5% stage may show *more* errors per pooled request than 100% would, or, if
      the client validates idle connections, show *less* benefit than 100%. The 5% signal is noisy
      in both directions and may cause a spurious rollback or false confidence
  → Second-order: provider-side connection count is the sum of both pools, peaking at the 50% stage
```

## Coupling Analysis

| Coupling | Visible / invisible | Notes |
|---|---|---|
| Pool idle timeout vs internal LB idle/keep-alive timeout | **Invisible** (timing) | The client's idle timeout must be shorter than the LB's, or stale reuse occurs. This is the most important coupling, and it is exactly the boundary the proposal is crossing. |
| Retry logic ↔ exception classes / idempotency of provider calls | **Invisible** (behavioural contract) | "Same API" covers the happy path. Retry code typically matches on exception types and status codes that may differ between libraries. |
| TLS handshake dashboard ↔ client instrumentation | **Invisible** (convention) | The success metric may be client-specific. |
| Provider load balancing / autoscaling ↔ connection churn | **Invisible** (behavioural) | Provider teams implicitly rely on quote-service's current reconnect rate to spread load. They confirmed connection *limits*, not load distribution. |
| DNS-based failover / cert rotation ↔ connection lifetime | **Invisible** (temporal) | Infra changes that assume clients reconnect regularly. |
| Client construction ↔ worker fork model | **Invisible** (process model) | Is the client created before or after fork? |
| Flag service ↔ every provider call | **Visible** (config), partly invisible | A per-request read puts the flag SDK on the hot path. The default value when the flag service is unreachable decides which client runs during a flag outage. Confirm it defaults to classic. |
| Shared dependencies between the two libraries | **Visible** (dependency manifest) | Both installed for a quarter or more. Pins on shared transitive deps (TLS, certifi, urllib-style core) can conflict on upgrade. |

## Confidence Inversions

- **"Nothing downstream can tell which client made a call."** True for headers and body. False for connection behaviour, which is the whole point of the change. Providers see far fewer, much longer-lived connections. Scenario: a provider's LB uses least-connections balancing. Quote-service now holds a handful of persistent connections, which land unevenly and starve new instances during a scale-out. The provider team sees "quote-service" as a hot spot they cannot explain, because nobody told them its connection pattern changed.

- **"The client holds no state beyond its connection pool… nothing to drain."** True for rollback, and rollback is genuinely clean. But the pool *is* state, carrying stale DNS, LB pinning, and certificates. Scenario: a rate provider migrates hosts behind a DNS change during the 100% stage. Classic-client traffic would have followed within minutes. Pooled traffic keeps hitting the old IPs until they are torn down, then fails in a burst.

- **"We rehearsed this… no failed quotes."** The rehearsal proved *flipping* is safe. It did not prove *running* is safe. Synthetic load at 1% is steady, so connections never idle past the LB timeout, no provider deploys, and no DNS changes. Scenario: the failure mode is "first request after 60+ s of idle on a given connection fails". It appears at night and on low-traffic provider endpoints, and never under synthetic load.

- **"Billing and Routing have run it for over a year."** Scenario: both teams call services that bypass the internal LB, or use idempotent GETs where auto-retry hides stale-connection errors. Their year of clean running then says nothing about POSTs through the LB.

## Adversarial Scenarios

1. **Rollout lands on peak freight season.** The proposal is "Ready to start" on 2026-11-20 (Friday). Starting Monday 11-23 puts 50% on 11-26 (Thanksgiving) and 100% around Black Friday/Cyber Monday, during peak-season shipping volume. Realistic worst case (~10–20%): a load-dependent pool bug or provider hot-spotting surfaces at the 50% step during a traffic peak. The flag-off still works, but the incident happens when on-call is thin and the business cost of failed quotes is highest. Mitigation is calendar-level: pause at 5% through the holiday, or wait for any change freeze to lift.

2. **Provider deploy or scale event during 50–100%.** Realistic worst case: a rate provider does a rolling deploy. Pooled connections to draining instances reset together, retry behaviour differs from the classic client, and a burst of failed quotes lasts tens of seconds. Error rate spikes briefly, which may not trip a rollback threshold but does fail real customer quotes. It recurs on every provider deploy.

3. **Load at 2–3x projection (peak season, autoscaled quote-service).** Realistic worst case: quote-service autoscales out, and each new worker opens its own pools across three providers for both clients. Idle-held connections approach provider limits faster than "10x peak" suggests, because that figure was likely measured in active connections under the classic client.

## Reversibility Map

| Timepoint | What reversal requires |
|---|---|
| 1 week | Flip the flag off. Effective in ≤10 s, rehearsed in production. |
| 1 month | Same. The old client is still installed and its code path still exercised by the flag. |
| 6 months | Same, *provided* the flag and old client are still in place. The proposal says they stay at least a quarter, and their removal is its own reviewed change, which by definition is not a cliff of this change. |

**The gradient is flat.** No data is written in a new format, no other team is asked to change, and the old path stays live. Things that are *not* cliffs and are noted only for completeness: the one-off handshake spike when flipping back (a rollback cost that returns to today's load), and any quotes that failed while the flag was on (a consequence, not a reversal obstacle).

One watch item, not tagged as a cliff because the proposal does not cause it: if provider teams later rightsize TLS termination capacity because quote-service's handshake load dropped, flipping back would quietly need their capacity back. Telling them the old pattern may return before the flag is removed keeps the gradient flat.

## Cost of Success

Picture the world after full success: handshakes under 1%, p95 down ~20 ms, the flag at 100%, both clients in the module for a quarter or more. What's worse than today:

- **Complexity:** two client libraries and two code paths in the module every provider call goes through. Anyone debugging a provider error must first ask which client handled it. Logs and errors need to record that, or incidents get slower to diagnose.
- **Maintenance:** two libraries to patch for CVEs and keep compatible with shared transitive dependencies, for at least a quarter.
- **Optionality:** "temporary" flags at 100% have a way of becoming permanent. Removal is promised as its own change; without a date or owner it may never happen. The old path then rots untested while still nominally being the rollback.
- **Observability:** the handshake dashboard stops being informative, and connection-level problems (staleness, pinning) need new signals that do not exist today.
- **Opportunity:** small. This is a small change; the opportunity cost is real but modest.

None of these is severe. Together they are the price of a ~20 ms win, and they are worth naming so the cleanup actually gets scheduled.

## Findings Summary

- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The rollout's success signal (TLS handshake dashboard) may be instrumented only in `pyrequest-classic`, which would make pooled traffic read as zero handshakes.
- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The pool idle timeout vs the internal LB idle timeout is unverified. Stale-connection reuse is the defining risk of crossing the keep-alive boundary.
- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` "Same API" may not mean the same exception classes and timeout semantics, so unchanged retry logic could behave differently, especially for non-idempotent provider calls.
- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Billing/Routing experience may not transfer (different LB path, methods, traffic shape, concurrency model).
- `[HIDDEN COUPLING]` `[NOVEL]` Client construction vs the worker fork model risks shared pooled sockets across processes.
- `[HIDDEN COUPLING]` `[NOVEL]` Provider load balancing and autoscaling depend on today's connection churn. Long-lived connections pin to instances.
- `[HIDDEN COUPLING]` `[NOVEL]` DNS failover and certificate rotation assume clients reconnect regularly.
- `[HIDDEN COUPLING]` `[NOVEL]` A per-request flag read puts the flag service on the hot path. Its outage default decides which client runs.
- `[SECOND-ORDER EFFECT]` `[NOVEL]` At 5%, pooled connections idle longest, so the first stage's signal is noisy and may mislead in either direction.
- `[SECOND-ORDER EFFECT]` `[NOVEL]` Both pools coexist during staged rollout; provider connection count peaks at the 50% stage and scales with autoscaling.
- `[SECOND-ORDER EFFECT]` `[NOVEL]` Provider deploys produce burst resets rather than trickles.
- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Rollout timing likely overlaps Thanksgiving and peak freight season.
- `[SUCCESS COST]` `[NOVEL]` Two clients and two paths for a quarter or more; the flag removal has no date or owner; the handshake dashboard loses meaning; diagnosis needs a "which client" field.
- No `[REVERSIBILITY CLIFF]`: the gradient is flat.

## Recommendations

**Must address before proceeding** (all cheap; none challenges the plan's shape):
1. **Verify the success and failure signals work for both clients.** Confirm the handshake metric, latency, and error rate are emitted equivalently by `pyrequest-pooled`, and tag every provider-call metric and log line with which client served it. Without this, the staged rollout cannot see what it is staging.
2. **Pin the pooled client's idle timeout below the internal LB's idle timeout**, and confirm how it handles a reset on a reused connection for the provider calls' HTTP methods. If those calls are POSTs, test the stale-connection path explicitly: idle a connection past the LB timeout, then send.
3. **Confirm the client is constructed per worker, after fork**, not at import in a pre-forking server.
4. **Check the calendar.** Don't advance beyond 5% across Thanksgiving and Black Friday/Cyber Monday, or respect any existing peak-season change freeze.

**Worth mitigating:**
- Set a maximum connection lifetime (e.g., minutes, not hours) if `pyrequest-pooled` supports it. This bounds DNS staleness, LB pinning, and cert-rotation lag at a negligible cost to the handshake gain. Ask Billing/Routing what they use.
- Cap pool size per host. Add a dashboard of open connections per provider, summing both pools, and check it against provider limits at the 50% stage.
- Hold the 50% stage across at least one provider deploy, or coordinate one deliberately, and watch for burst resets. Extend stages to cover a weekly peak rather than a fixed three days.
- Confirm the flag's default when the flag service is unreachable is `off` (classic).
- Tell provider teams the connection *pattern* is changing (fewer, longer-lived), not just the count. Ask them to check least-connections balancing and autoscaling behaviour.

**Acknowledged risks:**
- Carrying two client libraries for a quarter is an acceptable price for a rehearsed, instant rollback. Give the removal change an owner and a target date now so the flag does not become permanent.
- The 20 ms p95 estimate may come in lower if provider calls are parallel. This affects the value of the change, not its safety, and the rollout measures it directly.
