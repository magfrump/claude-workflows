# Code Review Rubric

**Commit:** f2f149b

**Scope:** `git diff d86d2dc...f2f149b` — `app/api/edit/artifact/route.ts`, `app/lib/llm/callLlm.ts`, `app/lib/llm/callLlm.test.ts`, `app/lib/llm/streamLlm.ts` (LLM-server hygiene: per-call client construction for key rotation, log redaction, SSE error payloads) | **Reviewed:** 2026-08-18 | **Status: 🔴 DOES NOT PASS** — 2 red item(s) unresolved

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | Log-redaction guardrail is only half-applied: the diff sets a pipeline-wide policy ("response text is a function of the user's source material and shouldn't end up in server logs", `route.ts:77-81`, length-only) but the sibling handler `handleArtifactRoute` running the same `callLlm` pipeline still `console.error`s a 500-char content preview of the same user-derived LLM response on any invalid-JSON failure — user source material reaches persistent logs. **Convergence: Security (Medium, executed) + API-consistency (Inconsistent) + Fact-check Claim 1c (Mostly accurate, executed).** Escalated 🟡→🔴 (2 core critics + executed corroboration: fact-check spy captured `NOTJSON_MARKER_` payload). Mechanism-severity floor applies. | Security + API-consistency | Medium / Inconsistent (escalated) | `app/lib/formalization/artifactRoute.ts:106-107` (policy at `app/api/edit/artifact/route.ts:77-81`) | for-author | No prior overrides consulted (blinded e8 synthesis — override log outside instance scope) | 🔴 Unresolved |
| R2 | Malformed non-empty LLM response permanently poisons the on-disk cache on the edit/artifact whole-edit path: `callLlm.recordAndCache` writes raw provider text to a permanent, un-evicted sha256-keyed cache before validation (`callLlm.ts:91-95`); the whole-edit branch then 502s on `JSON.parse` failure **without evicting** — it never even receives `cacheKey` (destructures only `{text,usage}`). Sibling `artifactRoute.ts:103-105` does the missing `removeCachedResult`. Every subsequent identical request is a cache hit re-serving the malformed text — durable self-DoS per cache key. **Convergence: Security (Medium, executed) + Performance (Medium).** Escalated 🟡→🔴 (2 core critics + executed corroboration: `sec-cache-poison-scratch.txt` — 2nd identical call hits cache, re-serves malformed text, makes no 2nd provider call). Named defect mechanism (mechanism floor). | Security + Performance | Medium (escalated) | `app/api/edit/artifact/route.ts:45-87` (cache write at `app/lib/llm/callLlm.ts:91-95`) | for-author | No prior overrides consulted (blinded e8 synthesis) | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they stand. Each must carry a resolution or author note.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | SSE `error` event schema drift: protocol JSDoc documents `event: error — { error, details }` but commit 7c799cc removed `details` from the only emit site (`streamLlm.ts:162` now sends `{ error }`; executed: `Object.keys(data) === ["error"]`). Producer/consumer contract mismatch — an external SSE client reading `data.details` always gets `undefined`; the file's own neighboring `errorWithDetails` JSDoc already documents the deliberate non-forwarding, so the protocol block is internally contradicted. No in-repo breakage (`formalization/api.ts:92` reads only `.error`). **Convergence: Fact-check Claim 10b (Stale) + API-consistency Finding 1 (Inconsistent).** Not escalated: pure doc/contract drift (decision 031 caps doc-only at 🟡), no behavioral defect. | API-consistency + Fact-check | Stale / Inconsistent | Fact-check (Claim 10b) + API-consistency | for-author | — | 🟡 Open | — |
| A2 | `responseFormat` comment is Incorrect: says "Only used with the OpenRouter provider (Anthropic direct API does not support this)", but the Anthropic branch itself consumes it via `output_config.format` (`callLlm.ts:139-146`) and the Anthropic Messages API does support structured outputs. Code is correct; the comment misinforms a reader (who might assume `responseFormat` is a no-op when `ANTHROPIC_API_KEY` is set). Comment/doc-only Incorrect → 🟡 per Unified Severity Mapping (decision 031). | Fact-check | Incorrect (high, comment-only) | Fact-check (Claim 4) | for-author | — | 🟡 Open | — |
| A3 | Filesystem cache has no eviction, TTL, or size bound — one `<sha256>.json` per distinct `(model, systemPrompt, userContent, maxTokens)` tuple, never pruned (`removeCachedResult` is the only reap path). `userContent` embeds full user source, so the key space grows monotonically with traffic; combined with R2, poisoned entries accumulate permanently. `maxTokens: 8192` responses can be large. | Performance | Medium | Performance (Finding 2) | for-author | — | 🟡 Open | — |
| A4 | `CACHE_DIR = join(process.cwd(), "data", "cache")` collapses hit rate or fails writes on the named Vercel serverless target: either EROFS writes are swallowed by `catch { /* non-fatal */ }` (hit rate ~0%, every request re-billed at full provider cost, including retries of failing edits) or entries land in per-instance `/tmp` (unshared across fan-out, evaporate on cold start). Cost-avoidance value largely illusory in the environment the diff's own comment names. | Performance | Medium | Performance (Finding 3) | for-author | — | 🟡 Open | — |
| A5 | "Record analytics and write to cache (same as callLlm's recordAndCache)" is imprecise: same side effects, but the streaming version caches `{ text, usage }` while `callLlm`'s caches `{ text, usage, cacheKey }` and returns it (stream returns void). Precise form: "same analytics + cache side effects, minus the `cacheKey` field and return value." | Fact-check | Mostly accurate | Fact-check (Claim 9) | for-author | — | 🟡 Open | — |
| A6 | "Cache hits emit a single `done` event" omits a qualifier: when `SIMULATE_STREAM_FROM_CACHE=true`, a cache hit replays the cached text as many `token` events before the `done` (`streamLlm.ts:102-109`, `:184-190`). | Fact-check | Mostly accurate | Fact-check (Claim 11b) | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Unredacted `err.message` on unexpected-error and stream-catch paths: the diff drops the body/`details` from OpenRouter and stream error sinks, but the unexpected-error handlers still log `err.message` verbatim, and the stream catch both logs and forwards it over SSE. Safe for the known OpenRouter path (fixed string `OpenRouter API error: ${status}`); residual mechanism is any other thrown error whose `.message` embeds request/response content (provider-SDK error, parse `SyntaxError`). Untested/Low — kept visible per mechanism floor. | Security (Finding 3) | Low | for-author | — | 🟢 Open |
| C2 | Per-call client construction: constructor cost is negligible (~1.99 µs/construction, 10,000 in 19.86 ms, execution-verified) against a multi-hundred-ms LLM round-trip, correctly traded for key-rotation correctness. The critic's "connection-pool reuse unverified" caveat is now **resolved** by Stage-2.5 submitted claim 2 (Verified, executed — see CG2): pooling is process-global, not per-instance, so no per-call TLS handshake is added. | Performance (Finding 4) | Low | for-author | — | 🟢 Open |
| C3 | Exported factory renamed `getAnthropicClient` → `makeAnthropicClient` (signature-compatible `(apiKey: string): Anthropic`; both in-repo importers updated, `rg getAnthropicClient app` → 0 hits). Rename is the right call — `make*` signals fresh construction vs. the memoizing `get*` accessors. Flagged only so the public-symbol rename is a recorded, deliberate choice. | API-consistency (Finding 3) | Informational | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides consulted — this is a blinded e8 synthesis run (`docs/reviews/override-log.md` is outside the instance scope the synthesis was permitted to read). The heading is retained so the omission is auditable; a non-blinded production run must perform the Step 3.5 scan.

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics. Every row carries `Evidence` and has passed the Confirmed-Good cross-check (provenance rule 5; scoped to its backing verdict's Scope line; no contradicting observation in the merged or per-replicate fact-check reports).

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Removing the module-scope Anthropic singleton means a rotated `ANTHROPIC_API_KEY` is used on the *next* call — the old key is not retained in a cached client across calls (both consumers: `callLlm` and `streamAnthropic`). **Scoped:** does NOT cover how quickly the Vercel platform propagates a dashboard env change to a running instance (outside the codebase). | ✅ Confirmed | `app/lib/llm/callLlm.test.ts:53` — `expect(constructorCalls).toEqual([{ apiKey: "key-A" }, { apiKey: "key-B" }])` (executed, exit 0); `app/lib/llm/callLlm.ts:111` per-call env read; `streamLlm.ts:84,207`; `getAnthropicClient`/`_anthropicClient` grep-empty. Backing: **FC submitted claim 1 (executed)**, carried by FC Claims 2 & 3 (executed). | security-reviewer endorsement → verified Stage 2.5 | for-orchestrator-synthesis |
| Per-call `new Anthropic({ apiKey })` does not open a fresh TCP/TLS connection per call — the `@anthropic-ai/sdk` HTTP client reuses connections at the process-global dispatcher level, not a per-instance keep-alive pool. **Scoped:** covers the app's actual path (no custom `fetch`/`fetchOptions.dispatcher`) on the Node 20 global-fetch runtime; does NOT establish reuse *rates* against live `api.anthropic.com` under concurrent load, nor a caller injecting a custom `fetch`/dispatcher (the app does neither). | ✅ Confirmed | `node_modules/@anthropic-ai/sdk/client.js:72,74` — `this.fetch = options.fetch ?? Shims.getDefaultFetch()`; executed probe: `c1.fetch === c2.fetch : true`, 6 requests via two distinct-key clients → **2** sockets (not 6), `c1.fetchOptions: null`. Backing: **FC submitted claim 2 (executed)**. | performance-reviewer endorsement → verified Stage 2.5 | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved — every 🔴/🟡/🟢 row cites a `path:line` with source-report evidence, and the two load-bearing convergent reds (R1, R2) plus both ✅ rows carry executed fact-check/critic evidence.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

To pass review: both 🔴 items (R1 log-redaction leak, R2 cache poisoning) must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
