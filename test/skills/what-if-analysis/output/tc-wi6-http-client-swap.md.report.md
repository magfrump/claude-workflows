# What-If Analysis: Swap `quote-service` outbound HTTP client behind `quote_http_pooled`

**Proposal:** Replace `pyrequest-classic` with `pyrequest-pooled` in `quote_service/providers/http.py`, selected per request by the `quote_http_pooled` flag, rolled out 5% → 50% → 100%
**Date:** 2026-11-20
**Upstream critiques:** none

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output. This skill is most powerful when focused on the gaps that critics miss.

**Prior Art Check:** No repository is available, so `docs/decisions/` and `docs/working/` could not be searched. No `[PRIOR CONSIDERATION]` findings are possible. Keywords that would have been searched: `pyrequest`, `connection pool`, `keep-alive`, `load balancer`, `TLS handshake`, `quote_http_pooled`, `retry`, `rate provider`, `preload`/`fork`.

**Overall calibration:** This is a well-scoped proposal. The rollback claim is mostly true, and the rehearsal is better than most teams do. The real risks are not in the rollout mechanics. They are in three places: (a) what "same request/response API" leaves out, mainly exceptions, hooks, and pool behaviour; (b) whether the dashboards can see a 5% cohort at all; and (c) what long-lived connections do to load distribution and correctness on the provider side. Most findings below are moderate. Two are cheap checks that should happen before step 2.

---

## Assumptions Examined

1. **Assumption:** "Same request/response API" means the same *behaviour* at the call site. That includes the exception classes raised on timeout, connection reset, and DNS failure, which the existing retry logic catches.
   - **Source:** Explicit claim ("same request/response API"). That retries are unaffected is implicit in "No change to … retries".
   - **If wrong:** Redesign of the error-mapping layer. Retries could stop firing, or fire on the wrong errors, with no code diff in the retry module.
   - **Tag:** `[NOVEL]`

2. **Assumption:** The flag selects between two **long-lived, process-wide** client instances. The alternative is building a client per call.
   - **Source:** Implicit. "picks the client at call time" and "the module … builds the client" are ambiguous on this.
   - **If wrong:** Full retreat for the benefit, possibly worse. A per-request pooled client has no pool to reuse, so the handshake share stays near 8% or rises. Un-closed pools can also leak sockets and file descriptors.
   - **Tag:** `[NOVEL]`

3. **Assumption:** The rollout dashboards (latency, error rate, TLS handshakes) can tell the pooled arm apart from the classic arm.
   - **Source:** Implicit in Rollout step 3.
   - **If wrong:** Redesign of the rollout gating. At 5%, a doubled error rate in the pooled arm moves the aggregate by about 5% relative. The handshake improvement moves the aggregate from 8% to about 7.6%. Neither is visible against normal noise, so the 5% stage proves nothing either way.
   - **Tag:** `[NOVEL]`

4. **Assumption:** The TLS-handshake metric does not depend on the client library that emits it.
   - **Source:** Implicit.
   - **If wrong:** Tweak, but a dangerous one. If the count comes from `pyrequest-classic` hooks or instrumentation, the pooled arm emits zero. The dashboard then shows a "success" that is really missing data.
   - **Tag:** `[NOVEL]`

5. **Assumption:** Reusing connections across the internal load balancer is harmless to the providers. The provider teams checked connection *count* only.
   - **Source:** Explicit (Risks: connection count); load distribution is implicit.
   - **If wrong:** Redesign, such as a max-connection-lifetime setting or an LB change. See Consequence Chains.
   - **Tag:** `[NOVEL]`

6. **Assumption:** Billing's and Routing's year in production transfers to quote-service. That means the same library version, same configuration, same process model (threads/async/fork), and a similar request shape.
   - **Source:** Explicit ("run in production for over a year").
   - **If wrong:** Tweak to redesign, depending on which variable differs.
   - **Tag:** `[NOVEL]`

7. **Assumption:** Any bug in the new client shows up as latency or errors, so the dashboards and rollback cover it.
   - **Source:** Implicit. The only stated risk mitigation for library bugs is "staged rollout and rehearsed flag-off."
   - **If wrong:** Redesign. A silent correctness bug in a *pricing* service produces wrong quotes, not errors.
   - **Tag:** `[NOVEL]`

8. **Assumption:** Three days per stage covers the traffic patterns that matter.
   - **Source:** Explicit (Rollout step 2).
   - **If wrong:** Tweak. Extend or time the stages.
   - **Tag:** `[NOVEL]`

---

## Consequence Chains

**Outcome A: connections are reused across the LB keep-alive boundary**
```
→ First-order: ~8% → <1% of calls pay a fresh TLS handshake
  → Second-order: quote-service's connections to each provider become long-lived and pinned to
    whichever backend instance the internal LB picked at connect time (true if the LB balances
    per-connection, i.e. L4 or HTTP keep-alive without per-request rebalancing)
    → Third-order: when a provider scales out, new instances get almost no quote-service traffic
      until pooled connections recycle; the hot instances stay hot. Autoscaling looks broken to
      the provider team, and nothing in their dashboards points to quote-service.
    → Third-order: during a provider deploy, a draining instance holds quote-service connections
      until it closes them; if it closes abruptly, every in-flight request on those connections
      fails at once. The error spike is correlated across pods, not spread out like today.
  → Second-order: today's 8% churn was silently doing the rebalancing. Removing it is a behaviour
    change that "nothing downstream can tell which client made a call" does not cover. The
    providers can't tell from headers, but they can tell from connection lifetimes and load skew.
```

**Outcome B: idle connections now survive long enough to go stale**
```
→ First-order: pool holds connections between requests
  → Second-order: in low-traffic windows (nights, weekends), connections sit idle past the LB's or
    provider's idle timeout. The first request on a stale socket gets a reset or
    "remote end closed connection."
    → Third-order (client retries internally): if the pooled client transparently retries on a
      stale connection, and a provider call is a POST with side effects (rate lock, quote hold,
      metering), providers see duplicate requests. This is a new retry layer under "no change
      to retries."
    → Third-order (client does not retry): a small error spike that only appears off-peak. Daytime
      dashboard watching misses it, and it bites the first customer of the morning.
```

**Outcome C: p95 quote latency drops ~20 ms**
```
→ First-order: faster quotes
  → Second-order: within a quarter, someone tightens the quote SLO, an upstream timeout, or a
    caller's budget to match the new p95
    → Third-order: rollback is no longer free. Flipping the flag off now breaches an SLO or trips
      an upstream timeout that didn't exist when the rollback was rehearsed. (See Reversibility Map.)
```

---

## Coupling Analysis

| Coupling | Visible / invisible | Notes |
|---|---|---|
| Retry/timeout logic ↔ client exception types | **Invisible** (behavioural contract) | Retry code very likely catches `pyrequest_classic.*` exception classes or inspects their attributes. If the new client raises different types, retries silently change. The proposal says retries don't change, but retries depend on the client's errors. |
| Timeout semantics ↔ pool acquisition | **Invisible** | Pooled clients usually add a new wait: "acquire a connection from the pool." Under burst load with a small per-host pool cap, requests queue *before* the configured timeout starts, or a separate pool timeout fires with a new exception type. Same timeout values, different behaviour. |
| Observability hooks (handshake count, tracing spans, trace-header injection, request logging) ↔ client | **Invisible** unless wired generically | If any of these attach through `pyrequest-classic` event hooks or adapters, the pooled arm loses them. The proposal's own success metric may be one of them. |
| Process model (pre-fork / `--preload`, gevent, threads) ↔ module-level pool | **Invisible** | A pool created at import time in a pre-forking server is shared by every worker. Interleaved responses on shared sockets are a classic outcome. Classic's per-host pooling may have hidden this because its connections rarely lived long. Billing/Routing's clean record says nothing about it if their server model differs. |
| Provider LB balancing ↔ connection lifetime | **Invisible** (cross-team) | See Chain A. The provider teams approved connection *count*, not connection *lifetime* or skew. |
| Provider connection limits ↔ *all* callers | Partly visible | "10x our peak" counts our connections. Are Billing/Routing also pooled callers of the same providers? Limits are shared. Pod count × pool max × 3 providers during an autoscale event is the number to check, not average peak. |
| Two pools resident during mixed stages | Visible on reflection | At 5%/50%, every pod holds a classic pool *and* a pooled pool. The connection count is briefly higher than either alone. Fine given 10x headroom, but worth stating. |
| Test suite ↔ mocks of `pyrequest-classic` | **Invisible** | If unit/integration tests patch classic, the pooled path may have near-zero test coverage while CI stays green. |

---

## Confidence Inversions

**"It has the same request/response API; the change is in connection handling only."**
Scenario: on read timeout, classic raises `ReadTimeout(ConnectionError)` and pooled raises `PoolTimeout` or `ReadTimeout(TimeoutError)`. The retry wrapper's `except ConnectionError` no longer matches. In the pooled arm, a transient provider timeout now fails the quote instead of retrying. The error rate rises only in the pooled arm, and at 5% it is invisible in aggregate (Assumption 3). The bug is found at 50% or 100%, as "quote failures up, unclear why." Rollback fixes it, so severity is moderate. But it is exactly the bug class that the staged rollout is supposed to catch and won't at 5%.

**"Nothing downstream of `quote-service` can tell which client made a call."**
True at the HTTP message level, false at the connection level (Chain A). Scenario: a provider team spends a week debugging uneven backend CPU after the 100% flip and never connects it to this change. That is their incident, so they find out first.

**"Rollback does not get harder over time."**
Mostly true mechanically. Inverted scenario: three things make it harder.
1. A rollback at 100% means every pod opens fresh classic connections to three providers within the same ~10 s window. That is a synchronized handshake burst the 1% rehearsal never exercised.
2. SLOs or timeouts get tuned to the new latency (Chain C).
3. If the reason for rolling back is a correctness bug, the wrong quotes already issued are not rolled back by the flag.

**"Billing and Routing have run it in production for over a year."**
Scenario: they run an async server with a version pinned 18 months ago. Quote-service runs pre-fork gunicorn with a newer version that changed default pool size or stale-connection retry behaviour. Their year of production says nothing about the configuration that actually ships here.

**Silent correctness (Assumption 7).**
Scenario: a response body is not fully consumed. For example, the parser reads a size-limited prefix, or an error path returns early without draining. Under classic this was harmless, because those connections were rarely reused. Under pooled, the leftover bytes stay on the socket and the next request reads them. Most mature pooled clients guard against this, but in a pricing service the failure mode is "customer receives another lane's rate," not a 500. No dashboard in the rollout plan would show it. Probability is low and severity is high, because quotes may be honoured or contractual.

---

## Adversarial Scenarios

1. **Peak freight volume lands inside a stage (realistic: month-end/quarter-end, or a carrier disruption).**
   Load is several times the normal day during the 50% or 100% stage. The per-host pool cap becomes the bottleneck, and requests queue for connections. p95 *rises* in the pooled arm under peak even though it fell at normal load. With 3-day stages that don't span a peak, the team ships to 100% believing the latency win holds everywhere. Worst realistic case: a degraded month-end quote window, recoverable by flag-off, but during the worst possible week to also be absorbing the rollback handshake burst.

2. **A provider deploys or scales during the 100% stage.**
   Pinned connections go to draining instances, and errors arrive in correlated bursts across all quote-service pods (Chain A). Hot backends on the provider side push provider latency up, which cancels the 20 ms gain. Worst realistic case: a provider-side incident that is hard to attribute because it presents as provider instability.

3. **The 5% stage returns a clean result that means nothing.**
   No per-arm metrics exist, or the handshake metric is library-specific. The team advances to 50% on a non-signal. This is the most likely "hostile" scenario: about 20–40% likely in my estimate, since per-flag-arm metric tagging is often missing in practice. It turns the staged rollout into a two-stage rollout (50%, 100%) without anyone deciding that.

---

## Reversibility Map

| Timepoint | What reversal requires | Difficulty |
|---|---|---|
| **1 week** (5% or 50% stage) | Flag off; classic pool is still warm because it carries most traffic. Exactly the rehearsed case. | Trivial |
| **1 month** (100% for weeks) | Flag off. The classic pool is cold on every pod, so a synchronized handshake burst hits three provider LBs within ~10 s. This was never rehearsed above 1%. Also: does anything still exercise the classic path (tests, a staging canary)? If not, it has rotted silently, e.g. a dependency bump broke it. | Easy, with one unrehearsed cliff (the burst) |
| **6 months** (past "at least one quarter") | If the cleanup change has landed, reversal is a re-implementation plus re-rollout. Even if it hasn't, SLOs or upstream timeouts may now assume the new p95, and provider teams may have resized capacity around fewer, longer connections. | Moderate. Organisational rather than technical. |
| **Any time, if the reason is a correctness bug** | The flag stops new wrong quotes. Quotes already issued, stored, and possibly accepted are not reversed. | **Irreversible for the affected quotes** |

**Cliff edges:**
- **The cleanup PR.** Expected and acknowledged by the proposal, which is fine.
- **Full-traffic rollback burst.** Unrehearsed, though probably survivable given 10x headroom.
- **Issued quotes under a silent correctness bug.** The one genuinely irreversible path.

The proposal's claim of a flat gradient is right for *data and code*. It is incomplete for *commitments made through the system*.

---

## Cost of Success

The world after success: quote-service runs on `pyrequest-pooled` at 100%, the handshake share is under 1%, and p95 is about 20 ms better. Compared with today, it is worse in these ways:

- **Complexity cost:** Connection-level state now persists. Future intermittent failures (stale sockets, pinned backends, pool exhaustion) are stateful and time-dependent, which makes them harder to reproduce than today's mostly stateless behaviour. For a quarter or more there are two code paths, two dependency trees, and in principle a doubled test matrix.
- **Maintenance cost:** `pyrequest-classic` stays installed and must keep receiving security bumps for a path that serves 0% of traffic. Pool sizing per host becomes a tuning knob someone must own as traffic grows.
- **Optionality cost:** Small. A future move to an async client or a service mesh would replace this anyway. Long-lived connections slightly reduce the provider teams' freedom to rely on per-connection balancing.
- **Opportunity cost:** Low, because the change is small. Note that 20 ms on p95 is a modest win. If any "must address" item below grows into real work, the effort-to-benefit ratio changes, and it is worth re-asking whether the cost is still justified.

None of these is large. This is a cheap change if it works.

---

## Findings Summary

- `[UNEXAMINED ASSUMPTION]` `[HIDDEN COUPLING]` Retry and timeout handling likely depend on `pyrequest-classic` exception classes; "same API" may not include the same exceptions. `[NOVEL]`
- `[UNEXAMINED ASSUMPTION]` The flag may select a per-request client instance rather than a long-lived one, which would defeat pooling and risk socket leaks. `[NOVEL]`
- `[UNEXAMINED ASSUMPTION]` Rollout metrics may not be split by flag arm; at 5% neither the win nor a regression is visible in aggregate. `[NOVEL]`
- `[HIDDEN COUPLING]` The TLS-handshake count, tracing, and request logging may be emitted via classic-specific hooks; the pooled arm could under-report. `[NOVEL]`
- `[HIDDEN COUPLING]` A module-level pool combined with a pre-forking server can share sockets across workers. Billing/Routing's record doesn't cover it if their process model differs. `[NOVEL]`
- `[HIDDEN COUPLING]` Pool-acquisition wait is a new latency and timeout mode under burst, not covered by "timeouts unchanged." `[NOVEL]`
- `[SECOND-ORDER EFFECT]` Long-lived connections pin to provider backends, which skews load and blunts provider autoscaling. Today's 8% churn was doing the rebalancing. `[NOVEL]`
- `[SECOND-ORDER EFFECT]` Stale idle connections cause off-peak errors, or internal client retries that duplicate non-idempotent provider calls. `[NOVEL]`
- `[SECOND-ORDER EFFECT]` Correlated error bursts across pods during provider deploys. `[NOVEL]`
- `[UNEXAMINED ASSUMPTION]` Silent correctness failures (response desync) would produce mispriced quotes that no rollout dashboard detects. `[NOVEL]`
- `[UNEXAMINED ASSUMPTION]` Three-day stages may not include peak freight load, where pool caps matter most. `[NOVEL]`
- `[UNEXAMINED ASSUMPTION]` Provider headroom of "10x our peak" may not account for autoscaled pod count × pool max, or for other teams' pooled connections to the same providers. `[NOVEL]`
- `[REVERSIBILITY CLIFF]` Rollback from 100% causes a synchronized fresh-handshake burst from every pod; rehearsed only at 1%. `[NOVEL]`
- `[REVERSIBILITY CLIFF]` SLOs or timeouts tightened to the new p95 make rollback an SLO breach. `[NOVEL]`
- `[REVERSIBILITY CLIFF]` Quotes issued under a correctness bug are not reversed by the flag. `[NOVEL]`
- `[SUCCESS COST]` Stateful connection failures are harder to debug; a dead dependency path needs security upkeep for a quarter; pool sizing becomes an owned knob. `[NOVEL]`

---

## Recommendations

**Must address before proceeding (before step 2, the 5% stage):**
1. **Tag provider-call latency, error rate, and handshake count by flag arm**, and gate each stage on pooled-vs-classic comparison, not the aggregate. Confirm the handshake metric is emitted independently of the client library, for example from the LB or socket level, or verify that both clients emit it. Without this, the 5% stage is not a test. *Cost: hours.*
2. **Audit the exception path.** List every exception the retry and timeout code catches, and confirm `pyrequest-pooled` raises compatible types for connect timeout, read timeout, connection reset, pool timeout, and DNS failure. Add a test that runs the retry wrapper against both clients with injected faults. *Cost: an hour or two.*
3. **Confirm the pool is long-lived and fork-safe.** It should be a single client instance per process, created after fork (or lazily on first use), not per request and not at import under `--preload`. *Cost: a code read.*

**Worth mitigating:**
- **Max connection lifetime and idle eviction.** Set the pooled client's idle timeout below the LB/provider idle timeout, and set a max lifetime of minutes so connections recycle and rebalance across provider backends. Tell the provider teams the change is to connection *lifetime*, not just count. Watch signal: per-backend request skew on provider dashboards.
- **Stale-connection retries.** Check whether the pooled client retries automatically on stale connections, and whether provider calls are idempotent. If they are not, disable automatic retry for non-idempotent methods.
- **Correctness spot-check.** If providers echo a request ID or the request parameters, assert the echo matches in the pooled arm and alert on mismatch. If they don't, sample-compare pooled-arm quotes against a classic re-request during the 5% stage. Low probability, but in a pricing service it is the only failure the flag can't undo.
- **Stage timing.** Make sure the 50% or 100% stage spans at least one peak window, and that stages include a full night or weekend to catch idle-staleness errors. Check that the per-host pool cap sits above per-pod peak concurrency per provider.
- **Rollback burst.** Either rehearse a flag-off at 50% under real traffic, or confirm with the providers that a simultaneous reconnect from all pods is within LB handshake capacity.
- **Keep the classic path alive.** Keep it exercised in CI and in a staging canary during the quarter so the rollback target doesn't rot. Note in the SLO change log that the latency win depends on this flag until cleanup lands.

**Acknowledged risks:**
- Two pools resident during mixed stages briefly raise connection count. Acceptable given the confirmed 10x headroom.
- Carrying `pyrequest-classic` for a quarter costs a little maintenance. Acceptable, and it is the price of a real rollback path.
- Losing the rollback path when the cleanup change lands. Acceptable, since the proposal already gives cleanup its own review.
