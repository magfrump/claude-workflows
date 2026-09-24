# Change proposal: Swap the outbound HTTP client in `quote-service` behind a flag

**Team:** Pricing, Corvel Freight · **Size:** Small · **Status:** Ready to start

## What and why

`quote-service` calls three internal rate providers over HTTP to build a
shipping quote. It uses the `pyrequest-classic` client, which pools
connections per host but cannot reuse a connection across our internal load
balancer's keep-alive boundary. Under load we see about 8% of calls pay a fresh
TLS handshake (roughly 30 ms each).

We want to switch to `pyrequest-pooled`, which the Billing and Routing teams
have run in production for over a year. It has the same request/response API;
the change is in connection handling only.

## Scope

- One module changes: `quote_service/providers/http.py`, which builds the
  client. Every provider call goes through it.
- A new boolean flag, `quote_http_pooled`, picks the client at call time. Both
  clients stay installed and both code paths stay in the module.
- No change to request payloads, response parsing, timeouts, retries, the
  database, stored data, cached data, or the public quote API.
- Nothing downstream of `quote-service` can tell which client made a call:
  the rate providers see the same headers and body either way.

## Rollout

1. Deploy with the flag off. No behaviour change.
2. Turn the flag on for 5% of requests for three days, then 50% for three days,
   then 100%.
3. Watch provider-call latency, error rate, and the TLS handshake count
   dashboard at each step.

## Rollback

Turning `quote_http_pooled` off returns every subsequent request to
`pyrequest-classic` within the flag service's 10-second propagation time. Because
the flag is read per request and the client holds no state beyond its
connection pool, there is nothing to drain or migrate.

We rehearsed this last week in staging and then in production at 1% of
traffic: flag on, flag off, flag on again, under synthetic load. Each flip took
effect within 10 seconds with no failed quotes and no error-rate change.

Rollback does not get harder over time. The flag and the old client stay in the
code for at least one quarter after 100%, and removing them will be its own
change with its own review. No data is written in a new format and no other
team is asked to change anything.

## Expected result

- The fresh-handshake share of provider calls falls from about 8% to under 1%.
- p95 quote latency drops by roughly 20 ms.

## Risks we considered

- **A bug in `pyrequest-pooled` under our traffic pattern.** Mitigated by the
  staged rollout and the rehearsed flag-off.
- **Connection count on the rate providers.** Pooled connections are
  long-lived; the provider teams confirmed their connection limits are 10x our
  peak.
