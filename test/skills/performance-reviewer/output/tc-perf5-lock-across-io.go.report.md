> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

# Performance Review: subject.go

**Scope:** `subject.go` (package `quotes`, the whole file, 59 lines)
**Date:** 2026-11-19

## Data Flow and Hot Paths

`HandleQuote` serves `GET /quote?symbol=XYZ` for a trading dashboard. On every request it:

1. Takes a service-wide `sync.Mutex`.
2. Makes a blocking HTTP GET to the upstream quote API (5 s client timeout).
3. Decodes the JSON into a `Quote`.
4. Updates two per-symbol maps, `requests` and `lastSeen`.
5. Encodes the result to the client.
6. Releases the lock (deferred).

**Path temperature: hot.** This is a per-request handler, and trading dashboards usually poll often, possibly for many symbols per user. The file has no request-rate or traffic numbers, and the repo has nothing besides `subject.go`, so no measured baselines exist. Every finding below is speculative and based on the code's structure.

## Findings

#### 1. Global mutex held across the upstream HTTP call serializes every request

**Severity:** Critical
**Location:** `subject.go:37-57`
**Move:** Find the contention point
**Classification:** Macro (lock held across I/O, throughput capped at 1 in-flight request) / Hot path (per-request handler)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

`s.mu.Lock()` with `defer s.mu.Unlock()` holds one process-wide lock across `s.client.Get`, reading the response body, and writing the response to the client. Only one quote request can be in flight per process, for any symbol. Throughput is capped at about `1 / upstream_latency`: at 50 ms upstream latency that is roughly 20 req/s per instance, whatever the CPU or core count. Every other request waits in line, so latency grows linearly with queue depth. One slow or hung upstream call blocks all users for up to the 5 s timeout. Under sustained upstream slowness the cap drops to 0.2 req/s, which makes this DoS-enabling: anyone who can trigger slow upstream lookups, for example by requesting a symbol the upstream handles slowly, stalls the whole dashboard.

**Recommendation:** Lock only around the two map updates on lines 53-54, after the upstream call and decode have finished. Do the I/O outside the lock and never write to `w` while holding it. If the counters are hot, consider `sync.Map` or sharded/atomic counters. Before merging, load-test with concurrent clients against a mocked upstream with fixed latency so you have a throughput number to compare against.

#### 2. `requests` and `lastSeen` grow without bound, keyed by client-supplied input

**Severity:** High
**Location:** `subject.go:20-21, 35, 53-54`
**Move:** Trace the memory lifecycle / What's the size of N?
**Classification:** Macro (unbounded collection growth) / Hot path (written on every successful request)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

Both maps are keyed by the raw `symbol` query parameter, and nothing ever removes an entry. Entries are only added after the decode succeeds, but the handler never checks `resp.StatusCode`. An upstream 404 or 4xx with a JSON error body such as `{"error":"unknown symbol"}` still decodes into `Quote` without error, so made-up symbols likely get recorded as well (verify upstream error-response format). N is therefore the number of distinct strings clients have ever sent, not the number of real tickers (around 10⁴). Each entry costs the key string plus map overhead in two maps, so memory grows linearly with distinct inputs until the process is restarted. Today the global lock in finding 1 limits the insertion rate. Fixing finding 1 removes that limit.

**Recommendation:** Reject non-2xx upstream responses before decoding, and validate `symbol` against an allowed pattern or known-ticker set before touching the maps. If you need per-symbol stats for arbitrary keys, use a bounded structure (LRU or a cap with eviction) or export them as metrics instead of holding them in maps.

#### 3. Upstream call ignores the client's request context

**Severity:** Medium
**Location:** `subject.go:40`
**Move:** Find the contention point
**Classification:** Macro (wasted serialized work that scales with abandoned requests) / Hot path
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

`s.client.Get` does not use `r.Context()`. If a dashboard client disconnects or times out, the upstream call keeps running for up to 5 s. Combined with finding 1, abandoned requests keep holding the global lock and delay live requests. Even after finding 1 is fixed, abandoned requests still use upstream connections and upstream quota.

**Recommendation:** Build the request with `http.NewRequestWithContext(r.Context(), http.MethodGet, url, nil)` and call `s.client.Do`.

#### 4. Upstream response body is neither size-limited nor drained

**Severity:** Low
**Location:** `subject.go:45-48`
**Move:** Trace the memory lifecycle / Serialization tax
**Classification:** Micro (per-call allocation and connection-reuse cost) / Hot path
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

`json.NewDecoder(resp.Body).Decode` stops reading after the first JSON value, and `Close` runs without draining whatever is left. If the body has trailing bytes, such as a newline or larger error pages, Go's transport may not be able to reuse the keep-alive connection, which adds a TCP/TLS handshake to the next call. There is also no size cap. A misbehaving upstream that returns a very large `symbol` string gets fully allocated, and while the lock is held that cost is serialized for everyone.

**Recommendation:** Wrap the body in `io.LimitReader` with a small cap (for example 64 KiB), and drain it before closing: `io.Copy(io.Discard, resp.Body)`.

#### 5. No response caching or request coalescing, so every poll goes upstream

**Severity:** Informational
**Location:** `subject.go:40`
**Move:** Count the hidden multiplications / Question the cache
**Classification:** Micro (one upstream round-trip per request) / Hot path
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

Upstream call volume equals dashboard request volume: users × symbols × poll frequency. Many users watching the same popular tickers produce identical upstream calls within the same second. Whether to cache depends on how fresh quotes need to be and on upstream pricing or rate limits, which the code doesn't show.

**Recommendation:** Once finding 1 is fixed, consider `golang.org/x/sync/singleflight` keyed by symbol to merge concurrent identical lookups. If the product can tolerate it, add a short TTL cache (hundreds of ms), bounded in size. Measure upstream calls per second first to see whether this is worth doing.

#### 6. Default transport idle-connection limit will churn connections once concurrency is restored

**Severity:** Informational
**Location:** `subject.go:26`
**Move:** Find the contention point
**Classification:** Micro (connection setup cost per request) / Hot path
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

`&http.Client{Timeout: ...}` uses `http.DefaultTransport`, whose `MaxIdleConnsPerHost` is 2. Today the global lock allows only one in-flight request, so this has no effect. After finding 1 is fixed, concurrent requests to the single upstream host will open new connections and then close all but two of them. Each new connection costs a TCP/TLS handshake.

**Recommendation:** When fixing finding 1, set up a dedicated `http.Transport` with `MaxIdleConnsPerHost` sized to the concurrency you expect upstream.

*Out of scope, handed to `security-reviewer`: `symbol` is concatenated into the upstream URL path without escaping (line 40), which allows path manipulation against the upstream.*

## Endorsements

- The `http.Client` is created once in `NewService` and reused by the handler, not rebuilt per request, so the transport's connection pool can persist across calls. [read: subject.go:24-31,40]
- The upstream client has a finite 5 s timeout, so a single upstream call cannot block forever. Finding 1 still multiplies the effect of that timeout across all callers. [read: subject.go:26]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Global mutex held across upstream HTTP I/O | Critical | `subject.go:37-57` | High |
| 2 | Unbounded per-symbol maps keyed by client input | High | `subject.go:20-21,53-54` | Medium |
| 3 | Upstream call ignores request context | Medium | `subject.go:40` | High |
| 4 | Upstream body not size-limited or drained | Low | `subject.go:45-48` | Medium |
| 5 | No caching/coalescing of identical upstream lookups | Informational | `subject.go:40` | Medium |
| 6 | Default `MaxIdleConnsPerHost=2` will churn after fix | Informational | `subject.go:26` | Medium |

## Overall Assessment

The biggest problem is finding 1. Holding one mutex across a network round-trip turns a concurrent HTTP server into a single-threaded queue. Throughput is limited by upstream latency, and one slow upstream call stalls every dashboard user. Fix it first, and it can be fixed in place: shrink the critical section to the two map writes. That fix removes a limit that currently hides other problems. Unbounded map growth (finding 2) and connection churn (finding 6) get worse once requests run concurrently, so fix findings 2 and 3 in the same change. No measurements exist in the repo, so all impact estimates come from reading the code. A simple concurrent load test against a fixed-latency mock upstream would confirm the throughput cap from finding 1 and give a baseline for checking the fix.
