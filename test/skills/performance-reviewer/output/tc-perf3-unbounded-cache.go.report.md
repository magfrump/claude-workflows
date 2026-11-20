⚠️ **No code fact-check report provided.** Performance claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

# Performance Review: subject.go

**Scope:** `subject.go` (package `geo`, `Handler.ServeHTTP` geocode endpoint)
**Date:** 2026-11-19

## Data Flow and Hot Paths

`Handler.ServeHTTP` serves `GET /geocode?address=...`. It reads `address` from the query string and checks an in-process `map[string]Location` under a read lock. On a miss it calls `Geocoder.Lookup`, which is probably a remote, possibly paid, geocoding API (its implementation isn't in scope). It then stores the result under a write lock and writes JSON back.

**Path temperature: hot.** The doc comment (lines 29–30) says this backs "the public storefront's address autocomplete, called on each debounced keystroke." So the endpoint is public, unauthenticated as far as this file shows, and gets called several times per address a user types. That claim comes from the comment and hasn't been fact-checked. The debouncing happens on the client, so the server can't rely on it.

**Data sizes:** the key space is every string anyone sends. Autocomplete makes each prefix of a typed address its own key ("1", "12", "123", "123 M", …). There is no upper bound in the code.

## Findings

#### 1. Cache keyed by attacker-controlled input grows without limit

**Severity:** Critical
**Location:** `subject.go:22`, `subject.go:26`, `subject.go:49-51`
**Move:** Trace the memory lifecycle / Question the cache
**Classification:** Macro (unbounded collection growth) / Hot path (public per-keystroke request handler)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

Every address that looks up successfully is stored in `h.results` for the life of the process. There is no size cap, no TTL and no eviction. The key comes straight from the query string, and `net/http` accepts URLs up to about 1 MB of headers by default, so each entry can be large. Normal autocomplete traffic grows the map with every prefix of every typed address. An attacker can grow it as fast as the upstream geocoder returns successes, eventually exhausting process memory, so this enables DoS. The map also never shrinks, which puts steady pressure on the Go GC: live heap grows, and so does mark work.

**Recommendation:** Replace the map with a bounded LRU/TTL cache (for example `hashicorp/golang-lru/v2/expirable`) with an explicit entry cap. Reject or truncate `address` values over a sensible length (around 256 bytes) before using them as a lookup or cache key.

#### 2. Upstream `Lookup` has no cancellation or deadline

**Severity:** High
**Location:** `subject.go:15-17`, `subject.go:44`
**Move:** Find the contention point / Price the deployment environment
**Classification:** Macro (in-flight work multiplies with upstream latency) / Hot path
**Confidence:** Medium (the `Lookup` implementation isn't in scope, so it may set its own timeout)
**Baseline:** no baseline available — flagged as speculative

`Geocoder.Lookup(address string)` takes no `context.Context`, so `r.Context()` can't be passed down. In autocomplete, the client drops the previous request when the user types the next character. The server still finishes every abandoned `Lookup`, pays for it (if the geocoder bills per call), and caches the result. If the upstream slows down, goroutines and outbound connections pile up in proportion to request rate × upstream latency, with nothing to cap them. That's the most likely way this endpoint breaks under load.

**Recommendation:** Change the interface to `Lookup(ctx context.Context, address string)`, pass `r.Context()` wrapped in a short `context.WithTimeout`, and cap concurrent upstream calls (a semaphore or a sized HTTP transport).

#### 3. Concurrent misses on the same key each call upstream (cache stampede)

**Severity:** Medium
**Location:** `subject.go:38-52`
**Move:** Count the hidden multiplications
**Classification:** Macro (upstream calls scale with concurrent requests per key) / Hot path
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

There's a gap between `RUnlock` (line 40) and `Lock` (line 49). Every request that misses on the same key during that window calls `Lookup` separately. Short popular prefixes ("1", "12", common street names) get hit by many users at once, especially right after a deploy or restart when the cache is empty. N concurrent misses become N upstream calls where one would do.

**Recommendation:** Wrap the miss path in `golang.org/x/sync/singleflight` (`group.Do(address, …)`) so concurrent misses for the same key share one upstream call.

#### 4. Raw keys and per-keystroke prefixes keep the hit rate low

**Severity:** Medium
**Location:** `subject.go:32`, `subject.go:39`
**Move:** Question the cache
**Classification:** Micro (wasted upstream call per miss) / Hot path
**Confidence:** Medium (verify the real traffic distribution)
**Baseline:** no baseline available — flagged as speculative

The cache key is the raw query string. "123 Main St", "123 main st" and "123 Main St " are three separate entries and three upstream calls. Autocomplete also means most keys are intermediate prefixes that one user requests once and nobody asks for again. So the cache mostly fills memory (finding 1) without saving many upstream calls. Without the client-side debounce the comment mentions, the miss count could be one per keystroke per user.

**Recommendation:** Normalize keys (trim, collapse whitespace, case-fold) before lookup and storage. Consider skipping upstream lookups and caching below a minimum prefix length. Measure the hit rate with a counter before and after.

#### 5. Failures aren't cached, so bad addresses hit upstream every time

**Severity:** Low
**Location:** `subject.go:45-48`
**Move:** Question the cache
**Classification:** Micro (one upstream call per failing request) / Hot path
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

When `Lookup` fails, nothing is stored, so every repeat of an unresolvable address calls upstream again. Partial autocomplete input will often fail to resolve, and an attacker can cheaply force uncached upstream calls by sending junk strings. It's minor next to finding 2, but it adds to upstream load and cost. If you add negative caching, distinguish "not found" from transient upstream errors so outages aren't cached.

**Recommendation:** Cache "not found" results with a short TTL, and don't cache transient upstream errors (5xx, timeouts).

#### 6. The cache is per process

**Severity:** Informational
**Location:** `subject.go:22`, `subject.go:26`
**Move:** Price the deployment environment
**Classification:** Micro / Hot path
**Confidence:** Low (the deployment topology isn't visible from this file)
**Baseline:** no baseline available — flagged as speculative

`results` lives in each `Handler` instance. With N replicas, each one warms its own cache, which cuts the hit rate by roughly N, and every restart or deploy resets it. On autoscaled or serverless platforms, the cache may be cold for most requests.

**Recommendation:** If upstream cost matters, measure per-replica hit rates. Consider a shared cache (Redis/memcached) once findings 1 and 4 are fixed.

## Endorsements

- No lock is held while `Lookup` runs. The read lock is released at line 40 before the call at line 44, and the write lock is taken only after it returns (lines 49–51). Slow upstream calls therefore don't serialize other requests on `h.mu`. [read: subject.go:38-51]
- The JSON response streams directly to `w` through `json.NewEncoder(w)`, without an intermediate `[]byte` buffer. [read: subject.go:54-55]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Cache keyed by attacker-controlled input grows without limit | Critical | `subject.go:22,49-51` | High |
| 2 | Upstream `Lookup` has no cancellation or deadline | High | `subject.go:15-17,44` | Medium |
| 3 | Concurrent misses each call upstream (stampede) | Medium | `subject.go:38-52` | High |
| 4 | Raw keys and prefixes keep the hit rate low | Medium | `subject.go:32,39` | Medium |
| 5 | Failures aren't cached | Low | `subject.go:45-48` | High |
| 6 | Per-process cache | Informational | `subject.go:22,26` | Low |

## Overall Assessment

The handler is small, and its locking is correct: no lock is held during the upstream call. But its cache is unbounded and fed by untrusted public input on a per-keystroke endpoint. That is the most urgent problem, because it allows memory-exhaustion DoS (finding 1). Close behind is the lack of context or timeout on `Lookup` (finding 2), which lets abandoned autocomplete requests and a slow upstream pile up unbounded goroutines and paid upstream calls. Each issue can be fixed in place with a bounded TTL/LRU cache, input length limits, context propagation, singleflight and key normalization. None of them needs a structural redesign.

All findings are speculative because no measurements were provided. Before and after the fixes, measure the cache hit rate, heap size over time, upstream call rate and cost, and p99 latency when the upstream is slow.
