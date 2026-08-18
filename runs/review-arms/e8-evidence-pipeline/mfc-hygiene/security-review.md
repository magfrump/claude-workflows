# Security Review — mfc-hygiene (LLM-server hygiene: per-call client, log redaction, SSE errors)

**Commit:** f2f149b
**Scope:** `git diff d86d2dc...HEAD` — `app/api/edit/artifact/route.ts`, `app/lib/llm/callLlm.ts`, `app/lib/llm/streamLlm.ts`, `app/lib/llm/callLlm.test.ts` (context read: `app/lib/formalization/artifactRoute.ts`, `app/lib/llm/cache.ts`)
**Date:** 2026-08-17
**Based on:** code-fact-check report at `runs/review-arms/e8-evidence-pipeline/mfc-hygiene/code-fact-check-report.md` (16 claims; 11 verified, 3 mostly-accurate, 1 stale, 1 incorrect). Its verdicts are treated as binding foundation and not re-verified.

No escalation patterns matched (no plaintext secrets, no missing auth, no injection, no disabled TLS, no hardcoded keys). No HALT block.

## Trust Boundary Map

```
B1: [user HTTP body: content/instruction/sourceText] → [route handler, buildUserMessage] → [callLlm/streamLlm userContent]
B2: [provider response text (user-source-derived)]    → [callLlm recordAndCache → on-disk cache; route JSON.parse] → [HTTP JSON / SSE done]   (trust: response treated as data, cached before validation)
B3: [internal error state + response/error bodies]    → [console.error/console.log redaction] → [server log sink]   (moved: redaction added on 3 log sites)
B4: [stream error (provider body attached as details)] → [SSE error-event filter] → [HTTP SSE client]   (moved: details dropped from wire)
B5: [ANTHROPIC_API_KEY env var]                        → [makeAnthropicClient per call] → [Anthropic SDK]   (moved: singleton → per-call read)
```

The diff moves three sinks toward less disclosure (B3 log redaction, B4 SSE-detail removal) and changes a secret-lifetime property (B5, singleton removed so a rotated key is read per call). What enters from outside is the user's own source material (B1); the security-relevant question is where that material — and provider bodies derived from it (B2) — subsequently travels: to logs (B3), to the SSE client (B4), to the HTTP response body, and to the persistent cache (B2). The diff's stated policy is "user-source-derived response text shouldn't reach server logs," but that policy is only partially realized across the pipeline (Finding 2), and an orthogonal availability defect on the cached-response path (Finding 1) is reachable but untouched by the diff.

## Findings

#### Malformed LLM response permanently poisons the on-disk cache on the edit/artifact whole-edit path

**Severity:** Medium
**Location:** `app/api/edit/artifact/route.ts:45-87`, `app/lib/llm/callLlm.ts:91-95`, `app/lib/llm/cache.ts:61-68`
**Boundary:** B2
**Move:** #3 (error path) + #8 (persistence at scale)
**Confidence:** High

`callLlm`'s `recordAndCache` writes the raw provider response to the on-disk cache whenever `text` is non-empty (`callLlm.ts:92-93`) — with **no JSON validation before the write**. The cache is a permanent sha256-keyed file with no TTL and no eviction (`cache.ts`). When the whole-edit branch then fails to parse that text as JSON (`route.ts:68-86`), it returns 502 but **does not evict the entry** — and it never even receives the `cacheKey` needed to do so (it destructures only `{ text, usage }` at `route.ts:46`). Its sibling generic handler does exactly the missing step: `artifactRoute.ts:103-105` calls `removeCachedResult(...)` on parse failure. Consequence: once the LLM returns a non-empty non-JSON response for a given `(model, systemPrompt, userContent, maxTokens)` tuple, every subsequent identical request is a cache hit that re-serves the same malformed text and re-fails — a persistent 502 for that input until the cache file is manually deleted. Executed (`evidence/sec-cache-poison-scratch.txt`): first call caches `"THIS_IS_NOT_JSON {broken"`; second identical call hits cache (`cache hit` logged), re-serves the malformed text, and makes **no** second provider call (`messagesCreate` called once). Blast radius is per-cache-key (the key embeds the caller's full input, so no cross-tenant poisoning), i.e. a durable self-DoS of the affected input rather than a multi-user outage — which is why this is Medium, not High.

**Recommendation:** On JSON-parse failure in the whole-edit branch, evict the cache entry as the sibling does — thread `cacheKey` out of `callLlm` (already returned) and call `removeCachedResult(...)`. Better, do not cache responses that the caller will validate as structured JSON until validation passes (move the cache write behind the parse gate in the shared pipeline).

#### Log-redaction guardrail is only half-applied — sibling route still logs a 500-char response preview

**Severity:** Medium
**Location:** `app/lib/formalization/artifactRoute.ts:106-107` (policy set at `app/api/edit/artifact/route.ts:77-81`)
**Boundary:** B3
**Move:** #11 (enumerate guardrail bypasses)
**Confidence:** High

The diff's redaction comment states response text "is a function of the user's source material and shouldn't end up in server logs," and enforces that at `route.ts:81` (length-only). But the sibling handler serving the same `callLlm` pipeline and the same invalid-JSON failure still writes `console.error(..., preview)` where `preview = responseText.slice(0, 500)` — 500 characters of the same class of user-source-derived content into the server log. This is the primary **tested** bypass of the log-redaction guardrail: fact-check Claim 1c executed it (spy captured the `NOTJSON_MARKER_` payload). The user's source material (potentially confidential documents being formalized) thus reaches persistent server logs on any malformed-JSON response through the generic artifact routes, defeating the diff's stated pipeline-wide intent. Per the mechanism-severity floor (a named mechanism disclosing user content to a reachable log sink), this is Medium, not Informational.

**Recommendation:** Apply the same length-only redaction at `artifactRoute.ts:106-107`. Audit for a single shared logging helper so the redaction policy cannot drift per-route.

#### Unredacted `err.message` on error paths can carry provider-SDK content into logs and SSE

**Severity:** Low
**Location:** `app/api/edit/artifact/route.ts:96`, `app/lib/formalization/artifactRoute.ts:121`, `app/lib/llm/streamLlm.ts:157-162`
**Boundary:** B3, B4
**Move:** #11 + #3
**Confidence:** Low

The redaction added in this diff drops the *body*/`details` from the OpenRouter and stream error sinks, but the unexpected-error handlers still log `err.message` verbatim, and the stream catch both logs and forwards `err.message` over SSE. For the known OpenRouter path `err.message` is the fixed string `OpenRouter API error: ${status}` (safe — fact-check Claim 7/12). The residual exposure is any *other* thrown error whose `.message` embeds request/response content — e.g. a provider SDK error, or a `JSON.parse` `SyntaxError` in a path that logs the error object. Whether the Anthropic SDK's `Error.message` ever contains request/response body content was not established (SDK internals are outside the diff), so this is listed as an untested bypass below and rated Low.

**Recommendation:** Route all error logging through the same helper that strips to a message allowlist / fixed strings, and never forward a raw `err.message` over SSE without confirming it cannot echo provider payloads.

### Untested bypass candidates (move #11 — log/SSE redaction guardrail)

The diff's guardrail is "user-source-derived response and provider-error content must not reach server logs or the SSE wire." Candidate inputs that would still route such content past it:

1. **Sibling `artifactRoute.ts:106-107` preview log** — *Tested* (fact-check Claim 1c, executed; spy captured the marker). Promoted to Finding 2.
2. **Provider-SDK internal logging** — the Anthropic/OpenRouter SDKs, if configured with debug logging (e.g. an `ANTHROPIC_LOG`-style env flag), emit request/response bodies from inside the SDK. The app-level redaction cannot cover SDK-internal sinks. *Untested* — depends on an env flag and SDK behavior outside the diff.
3. **Unexpected-error / SSE `err.message` forwarding** — `route.ts:96`, `artifactRoute.ts:121`, `streamLlm.ts:160,162` emit `err.message` unredacted. A provider SDK error or parse error whose `.message` embeds request/response content would reach the log (and, on the stream path, the client). *Untested* — the fact-check scope note on Claim 12 explicitly did not establish that `err.message` can never contain request content for arbitrary SDK errors. See Finding 3.
4. **HTTP 502 `details` echo** — `route.ts:83` and `artifactRoute.ts:109` return `responseText.slice(0,500)`; all seven `OpenRouterError` catch sites return `err.details` (the provider body) to the caller (fact-check Claim 7, executed). Not a *log* sink and by-design ("the caller originated it"), but it is the widest surface where response/provider content still travels; the "caller originated it" trust assumption (B2) does not hold if any intermediary or shared client sits between origin and the 502 body. *Tested* shape (fact-check Claims 1b/7); disclosure-to-third-party is *untested* and deployment-dependent.

Because bypass candidates 2 and 3 are untested, the log/SSE redaction guardrail does **not** appear in Endorsement Claims (move #11 rule).

## Endorsement Claims

- **Claim:** Removing the module-scope Anthropic singleton means a rotated `ANTHROPIC_API_KEY` is used on the *next* call — the old key is not retained in a cached client across calls.
  **Location:** `app/lib/llm/callLlm.ts:10-16,111,133`; `app/lib/llm/streamLlm.ts:84,207`; `app/lib/llm/callLlm.test.ts:41-54`
  **Evidence:** executed (carried from code-fact-check Claims 2 & 3, executed replicates)
  **Verified:** `makeAnthropicClient` constructs unconditionally; the env key is re-read per call (`callLlm.ts:111`, `streamLlm.ts:84`); the shipped test rotates the env key across two calls and asserts constructions `[{apiKey:"key-A"},{apiKey:"key-B"}]` (passed, exit 0); `getAnthropicClient`/`_anthropicClient` fully removed (grep-empty per fact-check).
  **Not verified:** how quickly the Vercel platform propagates a dashboard env-var change to a running instance (outside the codebase) — the code property is per-call re-read, not platform propagation latency.
  **route: code-fact-check**

(No endorsement is made of the log-redaction or SSE-redaction guardrails — they carry untested bypass candidates per move #11. The per-call-construction property above is a secret-lifetime behavior, not a guardrail/filter, so it is endorseable.)

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Malformed response permanently poisons on-disk cache (no eviction on edit/artifact whole-edit) | Medium | B2 | `app/api/edit/artifact/route.ts:45-87` | High |
| 2 | Log redaction half-applied — sibling logs 500-char response preview | Medium | B3 | `app/lib/formalization/artifactRoute.ts:106-107` | High |
| 3 | Unredacted `err.message` on error/SSE paths may carry SDK content | Low | B3,B4 | `app/lib/llm/streamLlm.ts:157-162` | Low |

## Overall Assessment

The diff's three hygiene moves are directionally sound: per-call client construction genuinely improves key-rotation/revocation behavior (endorsed, execution-backed), and the two redaction edits reduce content-in-logs at the sites they touch. The security posture is weakened by two things the diff does not address. First, the redaction policy it states is pipeline-wide but its enforcement is route-local — the sibling `artifactRoute.ts` still logs a 500-char preview of the same user-derived content (Finding 2, Medium), so the stated guarantee is not met in production. Second, an orthogonal availability defect sits on the same path the diff edits: a malformed non-empty LLM response is written to a permanent, un-evicted cache and re-served forever for that input (Finding 1, Medium, executed), because `edit/artifact` lacks the `removeCachedResult` eviction its sibling has. Both are fixable in place without architectural change; the single most important action is to route all response/error logging through one redaction helper (closing Finding 2 and bypass candidate 3) and gate the cache write behind JSON validation (closing Finding 1). No findings rise to Critical/High; endorsement claims are execution-backed. Conclusion: no authentication/injection/secret-exposure issues in the code paths read; the two Medium findings should be resolved before relying on the diff's stated log-hygiene guarantee.
