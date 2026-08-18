# Code Fact-Check Report

**Commit:** f2f149b
**Repository:** /workspace/external/cc-review-eval/mfc-hygiene
**Scope:** `git diff d86d2dc...HEAD` — `app/api/edit/artifact/route.ts`, `app/lib/llm/callLlm.test.ts`, `app/lib/llm/callLlm.ts`, `app/lib/llm/streamLlm.ts`
**Checked:** 2026-08-18
**Total claims checked:** 13
**Summary:** 10 verified, 1 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

Execution provenance note: all executed verdicts ran in cwd `/workspace/external/cc-review-eval/mfc-hygiene`; raw outputs are under `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-hygiene/evidence/` (prefix `r1-`). The first vitest capture (`r1-calllm-client-lifetime-test.txt`) contains a harmless startup warning caused by an empty `package.json` at `/workspace/external/` outside the clone ("Invalid package config … Cannot find dependency 'jsdom'"); the run itself completed and reported `1 passed (1)` with exit 0, and subsequent runs did not reproduce the warning. Scratch tests were run inside the clone and deleted afterward; their sources are archived as `r1-scratch-redaction-test-source.ts` and `r1-scratch-route-test-source.ts` in the evidence directory, and `git status` in the clone is clean.

---

## Claim 1: "Log only length, not content — `responseText` is a function of the user's source material and shouldn't end up in server logs. The response payload still echoes a slice back to the caller, since they originated the request and need it to debug their input."

**Location:** `app/api/edit/artifact/route.ts:77-80`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the invalid-JSON branch of `POST /api/edit/artifact` (console output and the 502 response body); does not establish that other routes or the `OpenRouterError` catch at `route.ts:88-94` avoid echoing content, nor what upstream infrastructure logs about response bodies.

Both halves of the claim were confirmed by executing the route with a mocked `callLlm` returning a 900-char non-JSON string. The log carries only the length:

```ts
// app/api/edit/artifact/route.ts:81
console.error(`[edit/artifact] LLM returned invalid JSON: ${responseText.length} chars`);
```

and the response echoes a 500-char slice to the caller:

```ts
// app/api/edit/artifact/route.ts:82-85
return NextResponse.json(
  { error: "LLM response was not valid JSON", details: responseText.slice(0, 500) },
  { status: 502 },
);
```

Executed: `npx vitest run --silent=false --reporter=verbose app/lib/llm/__r1scratch.redaction.test.ts app/api/edit/artifact/__r1scratch.route.test.ts` in `/workspace/external/cc-review-eval/mfc-hygiene`, exit 0, 2026-08-18T06:42:56Z. The captured run shows `CAPTURED-LOG-ROUTE: "[edit/artifact] LLM returned invalid JSON: 900 chars"` (no source material in the log), status 502, `details.length === 500`, and the marker string `USER_SOURCE_MATERIAL` present in `details` but absent from the log (paraphrased — no quote available because the assertions and captured stdout span the archived scratch test and its output file; see Evidence).

**Evidence:** `app/api/edit/artifact/route.ts:77-85`, r1-redaction-scratch-tests.txt, r1-scratch-route-test-source.ts

---

## Claim 2: "Track every Anthropic({ apiKey }) construction so we can assert the client is built fresh per call (no module-scope singleton)" / "Each call must have constructed its own client with the env-var-current key. If a singleton sneaks back, the second call would reuse key-A."

**Location:** `app/lib/llm/callLlm.test.ts:3-4`, `app/lib/llm/callLlm.test.ts:51-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `callLlm`'s Anthropic branch constructing one client per call with the current `ANTHROPIC_API_KEY`; does not establish the same for `streamLlm`'s `streamAnthropic` path (verified separately by static reading in Claim 3) or for a real (unmocked) SDK.

Executed: `npx vitest run app/lib/llm/callLlm.test.ts` in `/workspace/external/cc-review-eval/mfc-hygiene`, exit 0, 2026-08-18T06:41:46Z — `1 passed (1)`. The test's mocked constructor recorded `[{ apiKey: "key-A" }, { apiKey: "key-B" }]` across two calls, exactly as the comment describes (paraphrased — no quote available because the assertion result is in the vitest pass summary in the captured output, not printed inline). The counterfactual half ("a singleton would reuse key-A") matches the removed implementation, which cached the first client and ignored later keys:

```ts
// removed by commit 7c799cc (git diff d86d2dc...HEAD, app/lib/llm/callLlm.ts)
let _anthropicClient: Anthropic | null = null;
export function getAnthropicClient(apiKey: string): Anthropic {
  if (!_anthropicClient) {
    _anthropicClient = new Anthropic({ apiKey });
  }
  return _anthropicClient;
}
```

**Evidence:** `app/lib/llm/callLlm.test.ts:1-55`, r1-calllm-client-lifetime-test.txt

---

## Claim 3: "Construct a fresh Anthropic client per call. The SDK is cheap to instantiate and per-call construction means an env-var rotation (e.g. swapping ANTHROPIC_API_KEY in the Vercel dashboard) takes effect on the next request without needing a redeploy or process restart."

**Location:** `app/lib/llm/callLlm.ts:10-13`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers instantiation cost of `new Anthropic({apiKey})` (SDK 0.90.0, no network activity at construction) and env-var reread semantics in `callLlm`/`streamLlm`; does not establish that a Vercel dashboard env-var change reaches a running serverless instance's `process.env` without a redeploy — that platform half is outside the codebase.

"Cheap to instantiate" — executed micro-benchmark: `node -e "...10000 constructions..."` in `/workspace/external/cc-review-eval/mfc-hygiene`, exit 0, 2026-08-18T06:43:06Z: 10,000 constructions in 19.86 ms, ~1.99 µs each (see captured output). "Takes effect on the next request" — both call sites read the key from `process.env` per invocation and pass it to a fresh client:

```ts
// app/lib/llm/callLlm.ts:111
const anthropicKey = process.env.ANTHROPIC_API_KEY;
```

```ts
// app/lib/llm/callLlm.ts:133
const client = makeAnthropicClient(anthropicKey);
```

```ts
// app/lib/llm/streamLlm.ts:207
const client = makeAnthropicClient(opts.apiKey);
```

and the shipped test (Claim 2's run, exit 0) demonstrates the second call picks up a rotated key. The Vercel-specific clause is a deployment-platform assertion the code cannot establish; the in-code mechanism it depends on (fresh `process.env` read per call) is confirmed, so the claim is verified with that scope limit noted.

**Evidence:** `app/lib/llm/callLlm.ts:111-133`, `app/lib/llm/streamLlm.ts:84,207`, r1-client-construction-benchmark.txt, r1-calllm-client-lifetime-test.txt

---

## Claim 4: "When provided, enforces structured JSON output via OpenRouter's response_format. Only used with the OpenRouter provider (Anthropic direct API does not support this)."

**Location:** `app/lib/llm/callLlm.ts:56-57`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which provider branches of `callLlm` consume `responseFormat` and whether the Anthropic API exposes structured outputs; does not establish whether the Anthropic-branch `output_config` mapping produces a valid request against the live API (not executed — no API key in the sandbox).

The code contradicts both parts. The Anthropic branch itself consumes `responseFormat`, mapping it into `output_config`:

```ts
// app/lib/llm/callLlm.ts:139-146
...(responseFormat && {
  output_config: {
    format: {
      type: "json_schema" as const,
      schema: responseFormat.json_schema.schema,
    },
  },
}),
```

so "only used with the OpenRouter provider" is false in this codebase. The parenthetical "Anthropic direct API does not support this" is also wrong as a capability statement: the Anthropic Messages API supports structured outputs via `output_config: {format: {...}}` (paraphrased — no quote available because the source is the Anthropic API reference documentation, not a repo file). Both parts earn the same verdict, so the compound claim is not split. A reader acting on this comment (e.g. assuming `responseFormat` is a no-op when `ANTHROPIC_API_KEY` is set) would be misled.

**Evidence:** `app/lib/llm/callLlm.ts:56-58`, `app/lib/llm/callLlm.ts:139-146`

---

## Claim 5: "Record analytics and write to cache. Failures are silently ignored so they never break the LLM call that produced the result."

**Location:** `app/lib/llm/callLlm.ts:74-75`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers synchronous throws and rejected promises from `appendAnalyticsEntry` and `setCachedResult` inside `recordAndCache`; does not establish that failures are observed by anyone (they are swallowed without logging), nor cover the separate mock-branch analytics write at `callLlm.ts:215-222`.

Both operations are individually wrapped, and the failure is observed by no one (the catch bodies are empty comments):

```ts
// app/lib/llm/callLlm.ts:83-94
  try {
    appendAnalyticsEntry({
      id: randomUUID(),
      endpoint,
      ...usage,
      timestamp: new Date().toISOString(),
    });
  } catch { /* persistence failure must not break LLM calls */ }
  const result: CallLlmResult = { text, usage, cacheKey };
  if (text) {
    try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
  }
```

The `await` inside the `try` means a rejected `setCachedResult` promise is also caught, matching the claim.

**Evidence:** `app/lib/llm/callLlm.ts:76-96`

---

## Claim 6: "Centralized LLM call with Anthropic -> OpenRouter -> mock fallback. Returns the raw text response and usage/cost metadata. On mock fallback, returns text: '' — the caller provides its own mock text."

**Location:** `app/lib/llm/callLlm.ts:98-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `callLlm`'s provider selection order and the mock branch's return value; does not establish that every caller actually substitutes its own mock text.

Provider order is Anthropic (`if (anthropicKey)`, `callLlm.ts:130`) then OpenRouter (`if (openRouterKey && openRouterModel)`, `callLlm.ts:161`) then the mock fallthrough (paraphrased — no quote available because the ordering spans the three sequential branch guards at `callLlm.ts:130`, `callLlm.ts:161`, and `callLlm.ts:205-223` and reads more clearly as a summary). The mock branch returns empty text:

```ts
// app/lib/llm/callLlm.ts:223
return { text: "", usage };
```

and at least one caller supplies its own mock text on that signal (`route.ts:54-58` returns `mockWholeResponse(...)` / `mockInlineResponse(...)` when `usage.provider === "mock"`).

**Evidence:** `app/lib/llm/callLlm.ts:130,161,205-223`, `app/api/edit/artifact/route.ts:54-58`

---

## Claim 7: "Log only status + endpoint here; the body can echo parts of the request and we don't want it on disk in plaintext. The body still rides on OpenRouterError so route handlers can decide what (if anything) to surface to the caller."

**Location:** `app/lib/llm/callLlm.ts:182-185`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `callLlm`'s OpenRouter non-OK branch (console output and the thrown error's payload); does not establish what route handlers choose to surface — in fact every current `OpenRouterError` catch surfaces `err.details` to the HTTP caller (e.g. `route.ts:91`), which the comment's "can decide" wording permits but a reader should know.

Executed via a scratch vitest with `fetch` stubbed to return `ok: false, status: 418, body "SECRET_PROVIDER_BODY_XYZ"`: same command/cwd/exit/timestamp as Claim 1 (exit 0, 2026-08-18T06:42:56Z). The captured run shows `CAPTURED-LOG-CALLLM: "[r1test] OpenRouter error: status=418"` — the log names only endpoint and status, and the marker body string is absent from all console.error output — while the thrown error satisfied `caught.details === SECRET` and `caught.status === 418` (paraphrased — no quote available because the assertions live in the archived scratch test and pass silently; see Evidence). Statically, the observer chain is:

```ts
// app/lib/llm/callLlm.ts:186-187
console.error(`[${endpoint}] OpenRouter error: status=${response.status}`);
throw new OpenRouterError(response.status, errorBody);
```

and route handlers do read it, e.g.:

```ts
// app/api/edit/artifact/route.ts:89-93
if (err instanceof OpenRouterError) {
  return NextResponse.json(
    { error: err.message, details: err.details },
    { status: 502 },
  );
```

**Evidence:** `app/lib/llm/callLlm.ts:180-188`, `app/api/edit/artifact/route.ts:88-94`, r1-redaction-scratch-tests.txt, r1-scratch-redaction-test-source.ts

---

## Claim 8: "The streaming catch block intentionally does not log or forward `details` over SSE (provider error bodies can echo request content), but the property remains attached to the thrown Error for any in-process consumer that opts in to reading it."

**Location:** `app/lib/llm/streamLlm.ts:25-29`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `streamLlm` catch block's console output and SSE `error` payload, and the `details` property attachment; does not establish that any in-process consumer exists today — none does (the only reader, `getErrorDetails`, was deleted in this diff, and no other code reads `.details` off these thrown errors), so the "opts in" clause is currently hypothetical.

Executed (same scratch run as Claims 1/7, exit 0, 2026-08-18T06:42:56Z): with `fetch` stubbed to fail with body `SECRET_PROVIDER_BODY_XYZ`, the captured stream output shows `CAPTURED-SSE-RAW: "event: error\ndata: {\"error\":\"OpenRouter API error: 500\"}\n\n"` — no `details` key, no body content — and `CAPTURED-LOG-STREAM: "[r1stream] Stream error: OpenRouter API error: 500"` with the marker absent from logs. The catch block emits:

```ts
// app/lib/llm/streamLlm.ts:160-162
console.error(`[${endpoint}] Stream error: ${message}`);
try {
  controller.enqueue(sseEvent("error", { error: message }));
```

and the attachment half holds statically:

```ts
// app/lib/llm/streamLlm.ts:30-34
function errorWithDetails(message: string, details: string): Error {
  const err = new Error(message);
  (err as Error & { details: string }).details = details;
  return err;
}
```

with the thrown site at `streamLlm.ts:265` (`throw errorWithDetails(\`OpenRouter API error: ${response.status}\`, errorBody)`).

**Evidence:** `app/lib/llm/streamLlm.ts:25-34`, `app/lib/llm/streamLlm.ts:156-165`, `app/lib/llm/streamLlm.ts:263-266`, r1-redaction-scratch-tests.txt

---

## Claim 9: "Record analytics and write to cache (same as callLlm's recordAndCache)."

**Location:** `app/lib/llm/streamLlm.ts:45`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers behavioral equivalence of the two `recordAndCache` helpers (analytics append + conditional cache write, failures swallowed); does not establish byte-for-byte identity — the callLlm variant additionally takes a `cacheKey` and returns a `CallLlmResult` while the stream variant returns void and caches `{ text, usage }` without the key.

The stream helper performs the same two operations with the same swallow-on-failure semantics:

```ts
// app/lib/llm/streamLlm.ts:52-62
  try {
    appendAnalyticsEntry({
      id: randomUUID(),
      endpoint,
      ...usage,
      timestamp: new Date().toISOString(),
    });
  } catch { /* persistence failure must not break LLM calls */ }
  if (text) {
    try { await setCachedResult(cacheHash, { text, usage }); } catch { /* non-fatal */ }
  }
```

compared with `callLlm.ts:83-94` (quoted at Claim 5). The parenthetical "same as" is accurate for the behavior it points at; the return-shape difference does not mislead a reader of this JSDoc.

**Evidence:** `app/lib/llm/streamLlm.ts:46-63`, `app/lib/llm/callLlm.ts:76-96`

---

## Claim 10a: "SSE protocol: event: token — { text: \"partial chunk\" } / event: done — { text: \"full accumulated text\", usage: LlmCallUsage }"

**Location:** `app/lib/llm/streamLlm.ts:68-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the payload shapes at every `token`/`done` emit site in `streamLlm.ts`; does not establish client-side parsing behavior or wire-level framing beyond `sseEvent`.

All `token` emits send `{ text }` (`streamLlm.ts:186`, `streamLlm.ts:221`, `streamLlm.ts:299`) and all `done` emits send `{ text, usage }` (`streamLlm.ts:108`, `streamLlm.ts:153`, `streamLlm.ts:190`, `streamLlm.ts:237`, `streamLlm.ts:321`) (paraphrased — no quote available because the claim covers eight one-line emit sites across the file; representative example below).

```ts
// app/lib/llm/streamLlm.ts:237
controller.enqueue(sseEvent("done", { text: accumulated, usage }));
```

**Evidence:** `app/lib/llm/streamLlm.ts:108,153,186,190,221,237,299,321`

---

## Claim 10b: "event: error — { error: \"message\", details: \"...\" }"

**Location:** `app/lib/llm/streamLlm.ts:71`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the documented shape of the SSE `error` event versus the single emit site; does not establish whether any client currently depends on `details` (the in-repo consumer `app/lib/formalization/api.ts:92` reads only `.error`, so no in-repo breakage).

The protocol JSDoc still documents a `details` field, but the only `error` emit site stopped sending it in commit 7c799cc, when the diff replaced `sseEvent("error", { error: message, details })` with the current form:

```ts
// app/lib/llm/streamLlm.ts:162
controller.enqueue(sseEvent("error", { error: message }));
```

Executed confirmation (same scratch run as Claim 8, exit 0, 2026-08-18T06:42:56Z): the captured wire output is `event: error\ndata: {"error":"OpenRouter API error: 500"}\n\n` and the test asserted `Object.keys(payload)` does not contain `details`. The claim was accurate before this change (the removed `getErrorDetails` fed a `details` field into the same emit, per the diff) — the doc at line 71 was not updated when the emit site was. The in-repo SSE consumer reads only the `error` field:

```ts
// app/lib/formalization/api.ts:92
errorMsg = JSON.parse(dataStr).error ?? errorMsg;
```

**Evidence:** `app/lib/llm/streamLlm.ts:65-75`, `app/lib/llm/streamLlm.ts:156-165`, `app/lib/formalization/api.ts:89-94`, r1-redaction-scratch-tests.txt

---

## Claim 11a: "Provider chain mirrors callLlm(): Anthropic → OpenRouter → mock."

**Location:** `app/lib/llm/streamLlm.ts:73`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch order in `streamLlm`'s `start()` against `callLlm`'s; does not establish equivalence of the branches' internals (e.g. `responseFormat` exists only in `callLlm`).

`streamLlm` selects `if (anthropicKey)` → `else if (openRouterKey && openRouterModel)` → `else` mock:

```ts
// app/lib/llm/streamLlm.ts:114,124,134-136
if (anthropicKey) {
  ...
} else if (openRouterKey && openRouterModel) {
  ...
} else {
  // Mock fallback
  console.warn(`[${endpoint}] No API key configured — returning mock stream.`);
```

matching `callLlm`'s order (guards at `callLlm.ts:130`, `callLlm.ts:161`, mock fallthrough at `callLlm.ts:205-223`; quoted/cited at Claim 6). Both also compute `effectiveModel` with the identical ternary (`streamLlm.ts:86-90` vs `callLlm.ts:113-117`) (paraphrased — no quote available because the comparison spans two files' parallel five-line expressions).

**Evidence:** `app/lib/llm/streamLlm.ts:84-155`, `app/lib/llm/callLlm.ts:110-223`

---

## Claim 11b: "Cache hits emit a single `done` event."

**Location:** `app/lib/llm/streamLlm.ts:75`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cache-hit branch of `streamLlm`; does not establish behavior of cache misses or of the client's rendering.

True in the default configuration, but the claim omits a qualifier: when `SIMULATE_STREAM_FROM_CACHE=true`, a cache hit emits many `token` events before the `done`:

```ts
// app/lib/llm/streamLlm.ts:102-109
if (process.env.SIMULATE_STREAM_FROM_CACHE === "true") {
  // Simulate token-by-token streaming from cache for testing
  // partial-JSON rendering without making expensive API calls.
  console.log(`[${endpoint}] simulating stream from cache (${cached.text.length} chars)`);
  await simulateStreamFromCache(controller, cached.text, cached.usage);
} else {
  controller.enqueue(sseEvent("done", { text: cached.text, usage: cached.usage }));
}
```

`simulateStreamFromCache` enqueues a `token` event per ~20-char chunk (`streamLlm.ts:184-187`) before the final `done` (`streamLlm.ts:190`). The precise version: "Cache hits emit a single `done` event unless `SIMULATE_STREAM_FROM_CACHE=true`, which replays the cached text as token events first."

**Evidence:** `app/lib/llm/streamLlm.ts:97-112`, `app/lib/llm/streamLlm.ts:176-191`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`app/lib/llm/callLlm.ts:56-57`): Comment says `responseFormat` is "only used with the OpenRouter provider (Anthropic direct API does not support this)", but the Anthropic branch consumes it via `output_config.format` at `callLlm.ts:139-146`, and the Anthropic Messages API does support structured outputs. Update or delete the parenthetical.

### Stale
- **Claim 10b** (`app/lib/llm/streamLlm.ts:71`): Protocol JSDoc still documents the SSE error event as `{ error, details }`, but commit 7c799cc removed `details` from the only emit site (`streamLlm.ts:162` now sends `{ error }`). Update the protocol line to match.

### Mostly Accurate
- **Claim 11b** (`app/lib/llm/streamLlm.ts:75`): "Cache hits emit a single `done` event" needs a qualifier for `SIMULATE_STREAM_FROM_CACHE=true`, which emits token events first (`streamLlm.ts:102-109`).

### Unverifiable
- None.
