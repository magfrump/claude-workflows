# Performance Review — mfc-hygiene (LLM-server hygiene)

**Commit:** f2f149b
**Scope:** `git diff d86d2dc...HEAD` — `app/api/edit/artifact/route.ts`, `app/lib/llm/callLlm.ts`, `app/lib/llm/streamLlm.ts`, `app/lib/llm/callLlm.test.ts`
**Date:** 2026-08-18
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-hygiene/code-fact-check-report.md` (k=2, execution-verified)

## Data Flow and Hot Paths

The diff does three hygiene things on the shared LLM server path: (1) replaces the module-scope Anthropic singleton (`getAnthropicClient`) with per-call construction (`makeAnthropicClient`) so an `ANTHROPIC_API_KEY` rotation takes effect on the next request; (2) redacts response/error bodies from server logs (edit/artifact invalid-JSON, OpenRouter non-OK, streaming catch); (3) drops the `details` field from the SSE `error` payload. `callLlm` and `streamLlm` are **hot** — they are the per-request LLM handlers behind every `app/api/*` formalization/edit/refine route. Around them sits a filesystem cache (`app/lib/llm/cache.ts`, `data/cache/<sha256>.json`) that `callLlm.recordAndCache` populates with raw LLM text *before* any route validates it. The diff does not touch the cache module, but the task scopes the cache lifecycle in, and the client-construction change lives one function away from it.

The one measured number available is the fact-check's executed client-construction micro-benchmark: **10,000 constructions in 19.86 ms ≈ 1.99 µs each** (execution-verified, Claim 3). Every other path here has no baseline, so those findings are flagged speculative.

## Findings

#### Poisoned cache entry is never evicted on the edit/artifact whole-edit path — sibling route evicts, this one doesn't

**Severity:** Medium
**Location:** `app/api/edit/artifact/route.ts:66-87` (caching happens upstream at `app/lib/llm/callLlm.ts:91-95`)
**Move:** Question the cache (invalidation) / Find the work that moved to the wrong place
**Classification:** Macro (permanent cache poisoning, no invalidation) / Hot path (per-request edit handler)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

`callLlm.recordAndCache` writes the raw provider text to the filesystem cache whenever `text` is non-empty (`callLlm.ts:91-95`), keyed on `(model, systemPrompt, userContent, maxTokens)` — this happens *before* the route inspects the text. The whole-edit branch then does `JSON.parse`, and on failure returns 502 **without evicting the cache entry it just wrote**. The sibling generic handler solves exactly this: `app/lib/formalization/artifactRoute.ts:103-105` calls `removeCachedResult(...)` in its parse-failure branch. The edit/artifact route omits that call. Because the filesystem cache has no TTL and no eviction (see next finding), every subsequent identical `(content, instruction)` request is a cache hit (`callLlm.ts:124-128`) that returns the same invalid JSON and 502s again — permanently, with no way for the user to re-roll the LLM short of altering their input (which changes the hash). The dollar cost is one wasted *paid* provider call whose result is unusable and pinned forever; the retries are free (`costUsd: 0` on cache hit) but the feature stays broken for that input. This is the "repeated failures" regime whenever the cache write actually persists (see the deployment finding for the inverse regime where writes fail and retries re-bill instead).

**Recommendation:** Mirror `artifactRoute.ts:103-105` — call `removeCachedResult` in the whole-edit `JSON.parse` failure branch. Better still, hoist validation into `callLlm`/`recordAndCache` so unvalidated text is never cached in the first place, closing the gap for all routes rather than per-caller.

#### Filesystem cache has no eviction, TTL, or size bound — unbounded disk growth

**Severity:** Medium
**Location:** `app/lib/llm/cache.ts:26-68`
**Move:** Trace the memory/storage lifecycle (cache without eviction policy)
**Classification:** Macro (unbounded storage growth) / write path is hot (populated per cache-miss request)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

`setCachedResult` writes one `<sha256>.json` file per distinct `(model, systemPrompt, userContent, maxTokens)` tuple and never prunes. There is no LRU, no max entry count, no TTL, and no total-size cap; `removeCachedResult` (`cache.ts:70-83`) is the only reap path and fires only on a caller's explicit parse-failure eviction. `userContent` embeds full user source material plus instruction, so the key space is effectively unbounded and grows monotonically with traffic. On a persistent disk this grows without limit; combined with the finding above, poisoned entries accumulate permanently. `maxTokens: 8192` responses can be large, so per-entry footprint is non-trivial.

**Recommendation:** Add a bound — LRU with a max entry count or a total-bytes cap, plus a TTL — or move to a store with native eviction. At minimum, document the operational assumption that `data/cache` requires external pruning.

#### `data/cache` under `process.cwd()` collapses hit rate (or fails writes) on ephemeral/serverless filesystems

**Severity:** Medium
**Location:** `app/lib/llm/cache.ts:6` (`CACHE_DIR = join(process.cwd(), "data", "cache")`); write silently swallowed at `callLlm.ts:93` / `streamLlm.ts:61`
**Move:** Price the deployment environment
**Classification:** Macro (per-instance / ephemeral filesystem defeats the cache) / Hot path (every cache-miss request)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

The diff's own comment names Vercel as the deployment target ("swapping ANTHROPIC_API_KEY in the Vercel dashboard", `callLlm.ts:10-13`). On Vercel serverless the app-root filesystem is read-only except `/tmp`, and `/tmp` is per-instance and reset on cold start. Two regimes follow, both bad: (a) if writes to `process.cwd()/data/cache` throw EROFS, the error is swallowed by `catch { /* cache write failure is non-fatal */ }` (`callLlm.ts:93`) — the cache silently never populates, hit rate is ~0%, and **every request pays full provider cost**, including every retry of a failing edit (this is the "repeated failures billed" case); (b) if it instead lands in per-instance `/tmp`, entries are unshared across the serverless fan-out and evaporate on cold start, so realized hit rate is a fraction of the local single-process rate the design assumes. Either way the cache's cost-avoidance value is largely illusory in the named target environment. This is a deployment-context concern, not diff-introduced — but the client-construction comment ties the code to that environment explicitly.

**Recommendation:** Confirm where `data/cache` resolves on the deployed platform. If serverless, move to a shared store (Vercel KV / Redis / object storage) so the cache is actually hit across instances, and surface cache-write failures (at least a counter) instead of silently swallowing them, so a 0% hit rate is observable rather than a silent cost leak.

#### Per-call client construction: constructor cost is negligible, but connection-pool reuse is unverified

**Severity:** Low
**Location:** `app/lib/llm/callLlm.ts:14-16`, `:133`; `app/lib/llm/streamLlm.ts:207`
**Move:** Find the work that moved to the wrong place (init → per-call)
**Classification:** Micro (per-call object construction) / Hot path (per-request LLM handler)
**Confidence:** Medium
**Baseline:** 10,000 constructions in 19.86 ms ≈ 1.99 µs each (execution-verified, fact-check Claim 3, `./evidence/r1-client-construction-benchmark.txt`)

Moving `new Anthropic({ apiKey })` from a module-scope singleton to per-call construction adds ~1.99 µs per request. Against an LLM round-trip of hundreds of milliseconds to seconds, that is ~5-6 orders of magnitude below the dominant cost — the constructor time itself is a non-issue and is correctly traded for env-var key rotation. The one caveat the benchmark does *not* cover: it times object instantiation only, not whether each fresh client establishes a new HTTP/TLS connection instead of reusing a pooled keep-alive connection. If the SDK bound a per-instance HTTP agent, per-call construction would forgo connection reuse and add a TLS handshake per request — far more expensive than 1.99 µs. See the submitted claim below; I did not open the SDK internals to settle it.

**Recommendation:** No action on constructor cost. Optionally confirm (via the SDK docs or a connection-count trace) that HTTP connection pooling is at the process/global-dispatcher level and not per-client, so per-call construction doesn't silently disable keep-alive under load.

## Endorsements (evidence-gated)

- Per-call Anthropic client construction is cheap in absolute terms — ~1.99 µs/construction (10,000 in 19.86 ms), negligible against LLM network latency, so the singleton→per-call move for key-rotation correctness carries no meaningful per-request CPU cost. `[fact-check: claim 3 — verified (executed)]`
- `callLlm` short-circuits on a cache hit before any provider call (`callLlm.ts:124-128`), so a populated cache does avoid the provider round-trip on repeat identical requests — the cache does deliver its cost saving *where the entry is valid and the filesystem persists*. `[read: app/lib/llm/callLlm.ts:124-128]`
- The log-redaction changes (length/status/message only) marginally reduce log write volume on error paths; no adverse performance effect. `[read: app/api/edit/artifact/route.ts:77-81, app/lib/llm/callLlm.ts:182-187, app/lib/llm/streamLlm.ts:156-162]`

## Submitted claims

- `[unverified — submitted as claim]` Per-call construction of `new Anthropic({ apiKey })` does not open a fresh TCP/TLS connection per call — the `@anthropic-ai/sdk` HTTP client reuses connections at the process-global dispatcher level rather than binding a keep-alive pool per client instance. (If false, per-call construction adds a TLS handshake per request under load, a Medium hot-path cost the 1.99 µs constructor benchmark does not measure.)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Poisoned cache entry never evicted on edit/artifact parse failure (sibling evicts) | Medium | `app/api/edit/artifact/route.ts:66-87` | High |
| 2 | Filesystem cache has no eviction/TTL/size bound — unbounded growth | Medium | `app/lib/llm/cache.ts:26-68` | High |
| 3 | `data/cache` under cwd collapses hit rate / fails writes on serverless FS | Medium | `app/lib/llm/cache.ts:6` | Medium |
| 4 | Per-call client construction — constructor cost negligible; pool reuse unverified | Low | `app/lib/llm/callLlm.ts:14-16` | Medium |

## Overall Assessment

The diff's headline change — per-call client construction — is performance-neutral: the fact-check's executed 1.99 µs/construction benchmark settles it against a multi-hundred-ms LLM call, and the move buys real key-rotation correctness. The redaction and SSE-payload edits carry no performance cost. The load-bearing performance risk lives in the cache lifecycle the task scoped in, not in the redaction hygiene: `callLlm` caches unvalidated LLM text before the route checks it, and the edit/artifact whole-edit path — unlike its sibling `artifactRoute.ts`, which evicts — never removes a poisoned entry, so on a persistent disk a single bad LLM roll pins a permanent 502 for that input. The same cache has no eviction, TTL, or size bound at all, and its `process.cwd()/data/cache` location means the whole mechanism either silently never populates (read-only serverless FS → every request re-billed at full provider cost) or fragments per-instance on the named Vercel target. The single most important fix is cheap and local: mirror `removeCachedResult` into the edit/artifact parse-failure branch (or validate before caching in `callLlm`), which closes the poisoning gap; the eviction bound and the deployment-store question are the follow-ups. All four findings are speculative on impact — confirming them needs a cache-hit-rate measurement on the deployed platform and a connection-count trace for the submitted claim.
