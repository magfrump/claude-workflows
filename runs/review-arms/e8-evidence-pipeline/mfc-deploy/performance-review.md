# Performance Review — mfc-deploy Vercel-deploy documentation

**Commit:** 4329d6e
**Scope:** `git diff d86d2dc...HEAD` (CLAUDE.md Deployment section, README.md Deploy-to-Vercel + Lean Verification edits), with the documented persistence/caching/analytics claims traced into `app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`, `app/lib/llm/callLlm.ts`, `app/lib/llm/streamLlm.ts`, `app/api/verification/lean/route.ts`, `app/lib/formalization/leanRetryLoop.ts`
**Date:** 2026-08-18
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/code-fact-check-report.md` (merged k=2, 25 claims; execution verdicts consumed as ground truth)

## Data Flow and Hot Paths

The diff itself changes only documentation, but the documentation defines a new deployment target — Vercel serverless — and platform semantics are performance inputs (cognitive move 10). The paths the docs describe are hot: every LLM request (all `app/api/formalization/*`, `edit/*`, `refine/*`, `decomposition/*` routes) flows through `callLlm`/`streamLlm`, which (a) consults a filesystem cache at `<cwd>/data/cache` before calling a billed provider, and (b) appends an analytics line to `<cwd>/data/analytics.jsonl` (both locations execution-verified by fact-check Claims 6/18a). The Lean pipeline (`leanRetryLoop`) runs up to 3 generate+verify cycles per user action, each verify a proxied fetch with a 35 s timeout (`app/api/verification/lean/route.ts:5`). The repo carries one real measurement usable as a baseline: median output tokens per endpoint "derived from analytics data (246 calls, 2026-04-16)" in `app/lib/llm/costs.ts` (see `ENDPOINT_ESTIMATES` and docs/decisions/007), priced at the repo's own table ($3/M input, $15/M output for `claude-sonnet-4-6`).

The fact-check report's refutation that binds this review: **Claim 4a (Incorrect, executed ×2)** — CLAUDE.md's "unset `LEAN_VERIFIER_URL` → mock" is wrong; unset substitutes `http://localhost:3100` and performs a real request, mocking only when the fetch throws. I do not re-derive "unset selects the mock" anywhere below.

## Findings

#### LLM cache hit rate collapses to zero on the documented Vercel target — every repeated prompt is re-billed, silently

**Severity:** High
**Location:** `app/lib/llm/cache.ts:6`, `app/lib/llm/callLlm.ts:92-96,120-129`, `CLAUDE.md:77` (diff)
**Move:** Price the deployment environment (10) + Question the cache (8)
**Classification:** Macro (cache effectively deleted in the deploy target) / Hot path (every LLM request)
**Confidence:** High on mechanism; Medium on platform semantics (fact-check Claim 7 is Unverifiable on Vercel's filesystem policy)
**Baseline:** median 1,450 output tokens per `formalization/lean` call (and 1,150–2,100 for sibling endpoints), from analytics data of 246 calls, 2026-04-16, recorded in `app/lib/llm/costs.ts` `ENDPOINT_ESTIMATES` / docs/decisions/007

The cache writes to `join(process.cwd(), "data", "cache")` — execution-verified as `<cwd>/data` (fact-check Claim 6) — not `/tmp`. Under the diff's own platform claim ("Vercel Functions can only write to `/tmp`"; Claim 7, Unverifiable but stated by this very document), every `setCachedResult` on Vercel fails and the failure is swallowed (`callLlm.ts:94`, `streamLlm.ts:64`), so every LLM call is a guaranteed cache miss with no log signal. Even if writes did land, the docs' warm-container framing means per-instance ephemeral caches: serverless fan-out plus cold starts yields near-zero cross-instance hit rate regardless. Consequence in dollars at the repo's own pricing: each repeated identical prompt that would have been a $0 cache hit in dev is re-billed — output side alone ≈ 1,450 × $15/1M ≈ $0.022 per repeated lean-generation call, plus input tokens (source material can be large — file uploads feed `userContent`), plus full provider latency instead of a local file read. The diff says "Persistence on Vercel is best-effort" but never states this billing/latency consequence, and the cache is precisely the feature the CLAUDE.md warning ("don't add features that assume durable filesystem state") already describes — the guidance is written as if for future features while the existing cache already violates it.

**Recommendation:** Document the consequence explicitly in both files: "on Vercel the LLM cache is inoperative — every call is billed at full provider cost; expect N× the dev cost for repeated prompts." Longer term, either point `CACHE_DIR`/`DATA_DIR` at `/tmp` when deployed (recovers warm-container reuse only) or note that real caching on Vercel requires an external store (KV/Redis).

#### Analytics log: unbounded append, full-file read+parse per GET, no rotation or pagination

**Severity:** Medium
**Location:** `app/lib/analytics/persist.ts:14-32`, `app/api/analytics/route.ts:4-7`, `README.md:120` (diff)
**Move:** Trace the memory lifecycle (4) + What's the size of N? (2)
**Classification:** Macro (unbounded growth, unbounded response) / Warm path (append per LLM call; read per analytics-panel view)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative (the 246-call/2026-04 dataset shows real accumulation but no file-size or read-latency measurement exists)

`appendAnalyticsEntry` appends one JSON line per LLM call forever — `clearAnalyticsEntries` is the only truncation, and it is user-initiated. `readAnalyticsEntries` reads the entire file, splits, and `JSON.parse`s every line on every `GET /api/analytics`, then serializes the whole array back out — cost of a panel view grows linearly with lifetime LLM-call count, and the append is `appendFileSync`, a synchronous disk write on the event loop of every LLM request. The diff's own scoping ("treat the analytics panel as dev-only", Claim 18b) is exactly where this bites: dev is the one environment where the file persists and grows for months. At dev scale (thousands of entries) this is tolerable; it has no bound and no pagination, so it degrades linearly with use.

**Recommendation:** Cap or rotate the file (e.g., keep last N entries) and/or add a `?limit=` to the GET. Swap `appendFileSync` for the async `fs/promises` API to keep the hot path non-blocking. A doc-only fix would at least name the unbounded-growth caveat next to "dev-only".

#### Lean verify budget (35 s × 3 retries) vs Vercel function duration is undocumented

**Severity:** Medium
**Location:** `app/api/verification/lean/route.ts:5`, `app/lib/formalization/leanRetryLoop.ts:3,41-78`, `README.md:115,119` (diff)
**Move:** Price the deployment environment (10) + Count the hidden multiplications (1)
**Classification:** Macro (per-request time budget multiplies with retries) / Hot path (per user formalization action)
**Confidence:** Medium (Vercel's duration limits are platform facts not verifiable here — same class as fact-check Claims 3b/7)
**Baseline:** no baseline available — flagged as speculative

The diff's recommended remote-verifier setup (`LEAN_VERIFIER_URL` → Railway/Render/Fly) routes each verification through a Vercel Function that proxies the request with a 35 s abort timeout. `leanRetryLoop` drives up to `MAX_LEAN_ATTEMPTS = 3` generate+verify cycles per user action — the verify calls are client-side sequenced, so no single function invocation spans the whole loop, but one slow `lake` build legitimately takes tens of seconds and a single proxied verify can run up to the full 35 s inside one Vercel Function invocation. If the deployed plan's max function duration is below 35 s, the platform kills the invocation before the route's own timeout fires; the client-side `verifyLean` then sees a failed/error response rather than the in-route mock. The new "Limitations on Vercel" section documents the no-verifier case but not this slow-verifier case, which is the configuration the section actively recommends. Note the timeout-path behavior itself is covered by the executed fact-check verdict (Claim 4b scope: abort/timeout falls into the same catch → mock), so the in-route 35 s ceiling degrades gracefully; the undocumented risk is specifically the platform ceiling being lower than 35 s.

**Recommendation:** Add one line to the README table: verify that the Vercel plan's function duration limit exceeds the verifier's worst-case build time (or lower `REQUEST_TIMEOUT_MS` to fit the plan), and state what the user sees when a verify times out. Flag as "verify platform limit" — requires a deployed instance to confirm.

#### Failed cache-dir creation retried on every call once the filesystem is read-only

**Severity:** Low
**Location:** `app/lib/llm/cache.ts:26-31,61-68`
**Move:** Find the work that moved to the wrong place (3)
**Classification:** Micro (two swallowed syscall failures per call) / Hot path (every uncached LLM call)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

`ensureCacheDir` sets `dirEnsured = true` only after `mkdir` succeeds; on a filesystem where it never succeeds (the diff's Vercel scenario), every `setCachedResult` re-attempts `mkdir` + `writeFile` and throws two exceptions that are constructed and swallowed per LLM call. Each `getCachedResult` also pays a guaranteed-miss `readFile` + exception. Constant per-call overhead, microseconds-to-milliseconds against a multi-second LLM call — raised for completeness because it is invisible (no logging on the swallowed failures), not because it is expensive.

**Recommendation:** None required for performance. If touched anyway, log the first persistence failure once per instance so operators learn the cache is dead (this also serves the High finding above).

#### Refuted "unset → mock" doc claim has a dev-side cost consequence

**Severity:** Informational
**Location:** `CLAUDE.md:76` (diff); binding verdict: fact-check Claim 4a (Incorrect, executed in both replicates)
**Move:** Using the fact-check report + Price the deployment environment (10)
**Classification:** Micro (doc-induced expectation error) / Cold path (dev/test expectation, not production code)
**Confidence:** High (mechanism is the executed fact-check verdict, not my derivation)
**Baseline:** no baseline available — flagged as speculative

Per the executed refutation, with `LEAN_VERIFIER_URL` unset the route sends real traffic to `localhost:3100`. A developer trusting CLAUDE.md's "unset → mock" will expect verification to be free/instant with the variable unset — but in the documented dev setup (verifier running on the default port) every pipeline verify triggers a real `lake` build, and a failing theorem drives `leanRetryLoop` through 3 LLM generations plus 3 builds where the developer expected zero-cost mocks. The fix is the doc correction the fact-check already prescribes (adopt README:88's accurate phrasing); noting here only the latency/cost expectation gap it creates.

**Recommendation:** Apply the fact-check's correction to CLAUDE.md:76; no code change.

## Endorsements (evidence-gated)

- Unreachable-verifier degradation is instant-mock rather than blocking: with the verifier down or the URL unreachable, the route returns `{ valid: true, mock: true }` immediately instead of stalling the pipeline — executed in both replicates. [fact-check: claim 4b — Verified (executed)]
- The rest of the app stays functional (LLM routes, generation, editing) with no verifier reachable, so the verifier is not a hard latency dependency of the main workflow. [fact-check: claim 13 — Verified (executed)]
- The cache is consulted before any billed provider call, and the key hashes `(model, systemPrompt, userContent, maxTokens)`, preventing cross-model or cross-prompt collisions from serving wrong (and cost-misattributed) results. [read: app/lib/llm/cache.ts:15-24,33-59 + app/lib/llm/callLlm.ts:120-129]
- Cache hits rewrite usage to `provider: "cache", costUsd: 0, latencyMs: 0`, so the analytics ledger distinguishes billed calls from free hits instead of double-counting spend. [read: app/lib/llm/cache.ts:42-54]
- The Anthropic SDK client is constructed at most once per warm server instance and reused across `callLlm`/`streamLlm` invocations in that instance, avoiding per-request client/TLS setup. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Cache hit rate → 0 on Vercel; repeated prompts re-billed silently | High | `app/lib/llm/cache.ts:6` | High (mech) / Medium (platform) |
| 2 | Analytics log unbounded; full read+parse per GET; sync append on hot path | Medium | `app/lib/analytics/persist.ts:14-32` | High |
| 3 | 35 s verify timeout vs Vercel function-duration limit undocumented | Medium | `app/api/verification/lean/route.ts:5` | Medium |
| 4 | mkdir/write retried and swallowed per call on read-only fs | Low | `app/lib/llm/cache.ts:26-31` | High |
| 5 | Refuted "unset → mock" doc creates dev cost/latency expectation gap | Informational | `CLAUDE.md:76` | High |

## Overall Assessment

As documentation, this diff is unusually honest — it names the mock silent-pass, the ephemeral filesystem, and the analytics non-persistence, and the fact-check confirms most of its mechanism claims. Its performance gap is one of omission, not error: the docs describe *where* persistence breaks on Vercel but not *what that costs*. The single most important item is Finding 1 — the LLM cache, the app's only cost-control mechanism, is silently inoperative in the exact deployment the diff instructs end users to click into, and its failure mode (swallowed exceptions, no log line) means a self-hosting user will never see why their Anthropic bill lacks the cache discount dev usage enjoys. Findings 2 and 4 are fixable in place; Finding 3 needs one deployed measurement (function duration vs verifier build time) to resolve. No profiling is required for Findings 1, 2, 4 — they are structural; Finding 3 is the one that needs a live Vercel data point.
