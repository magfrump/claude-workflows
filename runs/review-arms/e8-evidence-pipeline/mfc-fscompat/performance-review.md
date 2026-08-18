# Performance Review — mfc-fscompat (`d86d2dc...HEAD`, dataDir() → /tmp under Vercel)

**Commit:** b64c1ca
**Scope:** `app/lib/utils/dataDir.ts` (new), `app/lib/llm/cache.ts`, `app/lib/analytics/persist.ts`; call sites in `app/lib/llm/callLlm.ts` and `app/lib/llm/streamLlm.ts` read for frequency context.
**Date:** 2026-08-17
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/code-fact-check-report.md` (k=2 merged, HEAD b64c1ca)

## Data Flow and Hot Paths

The diff extracts an inline `process.env.VERCEL ? "/tmp" : join(cwd, "data")` ternary into a shared `dataDir()` helper and routes both the LLM response cache (`cache.ts`, `CACHE_DIR = dataDir("cache")`) and the analytics append log (`persist.ts`, `DATA_DIR = dataDir()`) through it. The fact-check verified (executed) that resolved paths are byte-identical to the parent commit in both env states (claim 17) and that with `VERCEL=1` writes land in `/tmp` (claim 1a).

Both consumers sit on the LLM request path. `getCachedResult` is called once per `callLlm`/`streamLlm` invocation *before* any provider call (`callLlm.ts:125`, `streamLlm.ts:101`); `setCachedResult` writes on every miss; `appendAnalyticsEntry` writes one JSONL line per completed call (`callLlm.ts:85,213`, `streamLlm.ts:56,149`). These are request handlers behind the formalization API routes — **hot** in the per-request sense, though absolute frequency is bounded by user actions and multi-second LLM latency. The existence of the cache at all is evidence that *repeated identical prompts are expected* (the fact-check confirms cache files are `{text,usage}` JSON keyed by a sha256 of `{model,systemPrompt,userContent,maxTokens}` — claim 5). That expectation is exactly what the deployment target breaks.

The review below prices the change against Vercel's documented storage semantics per cognitive move 10. No measured baselines (traffic rate, token volume, per-call cost, hit rate) were surfaced in the repo or by the fact-check, so every finding is flagged speculative.

## Findings

#### LLM cache hit-rate collapses across Vercel Function instances — repeated prompts get re-billed

**Severity:** High
**Location:** `app/lib/llm/cache.ts:7` (`CACHE_DIR = dataDir("cache")`), `app/lib/utils/dataDir.ts:13`
**Move:** Question the cache (8) + Price the deployment environment (10)
**Classification:** Macro (cache keyed to a per-instance ephemeral filesystem) / Hot path (LLM request handler)
**Confidence:** High (mechanism) / Low (magnitude — no traffic baseline)
**Baseline:** no baseline available — flagged as speculative

`/tmp` on Vercel is **per-Function-instance** and lives only as long as the warm container. The cache is a bare filesystem read/write keyed by sha256 with no shared backing store, so each concurrently-running instance builds and reads its *own* `/tmp/cache`. A prompt cached on instance A is a miss on instance B, and every cold start begins with an empty cache. The consequence is a re-billed provider completion on each miss that a single durable disk would have served for free. Under horizontal fan-out to M warm instances with roughly uniform routing, the chance a repeat lands on the instance holding the file is ~1/M, so of K identical calls that would all hit on a shared disk, on the order of (1 − 1/M)·K re-bill — plus every cold start resets that instance's cache to empty. The dollar impact scales with traffic, prompt-token size, and instance count, none of which are measurable from the sandbox; the *direction* (hit rate falls, provider spend rises versus the pre-Vercel single-disk baseline) is structural, not speculative. The fact-check could only establish that writes/round-trips succeed *within one warm container* (claim 14a executed); the cross-instance and cold-start persistence properties are Unverifiable platform behavior (claims 1b, 8a, 8b, 14b) — so the cost cannot be closed out by execution, only reasoned from Vercel's documented model.

**Recommendation:** For the cache to pay off on Vercel it must live in a store shared across instances and surviving cold starts — Vercel KV / Upstash Redis, Blob storage, or a managed cache keyed by the same sha256. Treat the `/tmp` cache as a best-effort per-instance warm cache only, and make that explicit; do not assume the documented hit-rate benefit of the pre-Vercel `data/cache` disk carries over. If a persistent store is out of scope, capture a hit-rate/provider-spend baseline from a deployed instance before relying on the cache economically.

#### Analytics log diverges per instance and is lost on cold start — reads return one instance's partial slice

**Severity:** Medium
**Location:** `app/lib/analytics/persist.ts:8-9,17-20,22-35`, `app/lib/utils/dataDir.ts:13`
**Move:** Price the deployment environment (10) + Trace the memory/state lifecycle (4)
**Classification:** Macro (durability/consistency tied to per-instance ephemeral fs) / Hot path (per-LLM-call append)
**Confidence:** High (mechanism) / Low (magnitude)
**Baseline:** no baseline available — flagged as speculative

`appendAnalyticsEntry` writes one line to `/tmp/analytics.jsonl` on the instance that served the call; `readAnalyticsEntries` (backing the Analytics panel / `GET` route) reads only the local instance's file. On Vercel this means (a) writes fan out across instances so no single file is complete, (b) a read served by a different instance than the writes returns a partial or empty history, and (c) every cold start silently drops that instance's accumulated log — the code comment (`persist.ts:6-7`) acknowledges the cold-start loss. The write itself is cheap (`appendFileSync`, one `existsSync` per call); the cost is not latency but that the analytics feature is quietly under-counting and non-deterministic in production. The fact-check confirms the routing (claim 1a executed) but the durability half is Unverifiable platform behavior (claim 1b).

**Recommendation:** Route analytics to an append-capable shared store (same KV/Blob/DB decision as the cache) if the panel is expected to reflect real usage in production; otherwise document it as dev/self-hosted-only and gate or label the Vercel behavior so a partial read is not mistaken for ground truth.

#### Redundant sha256 recomputation per LLM call (`computeHash` runs twice) — pre-existing, adjacent to diff

**Severity:** Low
**Location:** `app/lib/llm/cache.ts:40` (inside `getCachedResult`) vs. caller `app/lib/llm/callLlm.ts:121,125`; same shape in `streamLlm.ts:95,101`
**Move:** Find the work that moved to the wrong place (3) / Hidden multiplication (1)
**Classification:** Micro (one extra hash of `userContent` per call) / Hot path (LLM request handler), but LLM-latency-gated
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

The caller computes `cacheHash = computeHash(...)` at `callLlm.ts:121` (comment: "Compute hash once, reuse for cache get and set"), but `getCachedResult` takes the raw params and recomputes the identical sha256 internally at `cache.ts:40`. Only the *set* path honors the "reuse" (`setCachedResult` takes the hash directly, `cache.ts:62-68`); the *get* path re-hashes. So `sha256(JSON.stringify({model,systemPrompt,userContent,maxTokens}))` runs twice per call — and `userContent` can be a whole source document in this app, making the hash non-trivial though still negligible beside a multi-second provider call. **This is pre-existing** — the diff changed only `CACHE_DIR`, not `computeHash`/`getCachedResult` — so it is out of scope for merging this change but worth logging.

**Recommendation:** If touched later, add a `getCachedResultByHash(hash)` overload (mirroring `setCachedResult`) so the caller's already-computed `cacheHash` is reused, and align the `cache.ts:120`-style "compute once" comment with reality. Not worth a standalone change at current call frequency.

## Endorsements (evidence-gated)

- `dataDir()` is a pure, dependency-free extraction: resolved values for `DATA_DIR`/`CACHE_DIR` are identical to the parent commit in both env states, so the refactor adds no runtime cost of its own. [fact-check: claim 17 — Verified]
- Cache files store exactly `{ text, usage }` keyed by a sha256 hex filename, with no per-entry metadata bloat — minimal serialization footprint per cached entry. [fact-check: claim 5 — Verified]
- A corrupt or missing cache file is treated as an ordinary miss (returns null, no crash), so the cache layer adds no exception-handling overhead on the failure path. [fact-check: claim 6 — Verified]
- The refactor introduces zero new dependencies (diff stat touches only the three files; new module imports only `path`), so no dependency-load or bundle-size cost. [fact-check: claim 13 — Verified]
- `getCachedResult` recomputes `computeHash` internally (`cache.ts:40`) despite the caller having already computed `cacheHash` (`callLlm.ts:121`), so the sha256 over `userContent` executes twice on the get path. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Cache hit-rate collapses across per-instance `/tmp`; repeated prompts re-billed | High | `cache.ts:7` | High mech / Low mag |
| 2 | Analytics log diverges per instance, lost on cold start; reads return partial slice | Medium | `persist.ts:8-35` | High mech / Low mag |
| 3 | Redundant sha256 recomputation per call (`computeHash` twice) — pre-existing | Low | `cache.ts:40` | High |

## Overall Assessment

This diff is a clean, behavior-preserving extraction locally (claim 17, executed), but its *purpose* is to route persistence to `/tmp` on Vercel, and that is where the performance story is. On the target platform `/tmp` is per-instance and ephemeral, which turns a durable-disk cache into a per-instance warm cache with a collapsing hit rate (finding 1, the core cost — the LLM cache exists precisely to avoid re-billing identical prompts, and horizontal fan-out plus cold starts defeat it) and turns a durable analytics log into a diverging, cold-start-lossy per-instance file (finding 2). Neither is a bug in the extracted code — the refactor faithfully preserves the prior inline behavior — but both are structural costs the change *commits the app to* by declaring `/tmp` the production write target. The right fix for both is the same: a store shared across instances and surviving cold starts (Vercel KV / Upstash / Blob), with `/tmp` demoted to an explicit best-effort tier. The most important item is finding 1 because it re-bills real provider spend. Confirming magnitude requires a deployed-instance baseline (hit rate, provider spend, analytics completeness) that the sandbox cannot produce — the fact-check correctly marks every Vercel-lifecycle claim Unverifiable (1b, 8a, 8b, 11, 14b), so the cost is derived from Vercel's documented semantics, not measured. Not a clean bill of health: ship only with the shared-store follow-up tracked, or with the `/tmp` limitation documented and the features scoped to dev/self-hosted.
