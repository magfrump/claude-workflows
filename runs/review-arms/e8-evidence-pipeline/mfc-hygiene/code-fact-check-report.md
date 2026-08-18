# Code Fact-Check Report

**Repository:** /workspace/external/cc-review-eval/mfc-hygiene
**Commit:** f2f149b
**Replication:** k=2
**Scope:** `git diff d86d2dc...HEAD` — `app/api/edit/artifact/route.ts`, `app/lib/llm/callLlm.test.ts`, `app/lib/llm/callLlm.ts`, `app/lib/llm/streamLlm.ts` (plus sibling routes implicitly covered by redaction claims: `app/lib/formalization/artifactRoute.ts` and the `app/api/*` LLM routes)
**Checked:** 2026-08-18
**Total claims checked:** 16
**Summary:** 11 verified, 3 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

Merge of two fact-check replicates (r1, r2) on identical scope, most-severe-wins per the code-review Stage-1 merge protocol (adapted to k=2). Per-claim `**Replicate verdicts:**` lines record each replicate's verdict; `— · single-replicate detection` marks claims only one replicate surfaced. Evidence and reasoning are carried verbatim from the replicate that assigned the winning verdict.

Execution provenance (carried from both replicates; all commands ran in cwd `/workspace/external/cc-review-eval/mfc-hygiene` on 2026-08-18 UTC):

- **r1** — scratch redaction/route tests via `npx vitest run --silent=false --reporter=verbose app/lib/llm/__r1scratch.redaction.test.ts app/api/edit/artifact/__r1scratch.route.test.ts` · exit 0 · 2026-08-18T06:42:56Z; `npx vitest run app/lib/llm/callLlm.test.ts` · exit 0 · 2026-08-18T06:41:46Z; client-construction micro-benchmark · exit 0 · 2026-08-18T06:43:06Z. Outputs under `./evidence/` with prefix `r1-` (`r1-redaction-scratch-tests.txt`, `r1-calllm-client-lifetime-test.txt`, `r1-client-construction-benchmark.txt`, `r1-scratch-redaction-test-source.ts`, `r1-scratch-route-test-source.ts`). The first vitest capture contains a harmless startup warning (empty `package.json` at `/workspace/external/` outside the clone); the run itself reported `1 passed (1)` exit 0. Scratch tests were deleted after the run; `git status` in the clone is clean.
- **r2 — E1** — `npx vitest run --reporter=verbose app/lib/llm/callLlm.test.ts` · exit 0 · 2026-08-18T06:42:50Z · `./evidence/r2-vitest-callLlm-existing.txt`
- **r2 — E2** — `npx vitest run --reporter=verbose app/lib/llm/r2-factcheck-lib.scratch.test.ts app/lib/llm/r2-factcheck-routes.scratch.test.ts` · exit 0 · 2026-08-18T06:42:49Z · `./evidence/r2-vitest-scratch.txt` · sources archived at `./evidence/r2-scratch-lib-test-source.ts` and `./evidence/r2-scratch-routes-test-source.ts` (scratch tests deleted after the run)

---

## Claim 1a: "Log only length, not content — `responseText` is a function of the user's source material and shouldn't end up in server logs." (log-only-length half)

**Location:** `app/api/edit/artifact/route.ts:77-81`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified (as compound Claim 1) · r2=Verified
**Scope:** Covers the invalid-JSON `console.error` in this route's whole-edit branch; does not establish log hygiene of any other route (see Claim 1c) or of the route's outer catch block.

The log line interpolates only the length:

```ts
// app/api/edit/artifact/route.ts:81
console.error(`[edit/artifact] LLM returned invalid JSON: ${responseText.length} chars`);
```

Executed (r2 E2, route scratch test `edit/artifact invalid-JSON redaction`): with `callLlm` mocked to return a 615-char non-JSON string containing marker `NOTJSON_MARKER_`, the `console.error` spy captured `"615 chars"` and did **not** capture the marker; r1's parallel run captured `"[edit/artifact] LLM returned invalid JSON: 900 chars"` with `USER_SOURCE_MATERIAL` absent from the log (paraphrased — no quote available because both assertions are over a spy's captured call list in the archived scratch tests).

**Evidence:** `app/api/edit/artifact/route.ts:77-81`, `./evidence/r2-vitest-scratch.txt`, `./evidence/r2-scratch-routes-test-source.ts`, `./evidence/r1-redaction-scratch-tests.txt`, `./evidence/r1-scratch-route-test-source.ts`

---

## Claim 1b: "The response payload still echoes a slice back to the caller, since they originated the request and need it to debug their input."

**Location:** `app/api/edit/artifact/route.ts:79-85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified (as compound Claim 1) · r2=Verified
**Scope:** Covers the 502 response body of the invalid-JSON branch; does not establish what clients do with the echoed slice.

```ts
// app/api/edit/artifact/route.ts:82-85
return NextResponse.json(
  { error: "LLM response was not valid JSON", details: responseText.slice(0, 500) },
  { status: 502 },
);
```

Executed (r2 E2, same test as 1a): the route returned status 502 with `details === responseText.slice(0, 500)` (length 500) for the 615-char input; r1's run confirmed the same slice length (500) and status 502 (paraphrased — no quote available because the values are runtime assertions in the archived scratch tests).

**Evidence:** `app/api/edit/artifact/route.ts:82-85`, `./evidence/r2-vitest-scratch.txt`, `./evidence/r1-redaction-scratch-tests.txt`

---

## Claim 1c: "`responseText` ... shouldn't end up in server logs" (read as a redaction guarantee for LLM response text, pipeline-wide)

**Location:** `app/api/edit/artifact/route.ts:77-78`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=— · r2=Mostly accurate · single-replicate detection
**Scope:** Covers whether LLM response text (user-source-derived) reaches server logs across the routes sharing the `callLlm` pipeline; does not cover logs emitted by the Anthropic/OpenRouter SDKs themselves.

Under the narrow, route-local reading the claim is fully true (see Claim 1a). But the rationale states a general policy — response text is "a function of the user's source material and shouldn't end up in server logs" — and the sibling generic artifact handler, which serves the same `callLlm` pipeline and the same invalid-JSON failure, still logs a 500-char preview of the response content:

```ts
// app/lib/formalization/artifactRoute.ts:106-107
const preview = responseText.slice(0, 500);
console.error(`[${config.endpoint}] Failed to parse LLM response as JSON:`, preview);
```

Executed (r2 E2, route scratch test `artifactRoute invalid-JSON logging`): calling `handleArtifactRoute` with `callLlm` mocked to return the marker string, the `console.error` spy **did** capture `NOTJSON_MARKER_` — the same class of data this comment says shouldn't reach server logs (paraphrased — no quote available because the finding is a spy assertion in the archived scratch test). The comment's mechanism and its local conclusion are both right; a reader inferring the stated policy holds pipeline-wide would be misled, hence the qualifier belongs in the comment.

**Evidence:** `app/api/edit/artifact/route.ts:77-81`, `app/lib/formalization/artifactRoute.ts:106-107`, `./evidence/r2-vitest-scratch.txt`, `./evidence/r2-scratch-routes-test-source.ts`

---

## Claim 2: "Track every Anthropic({ apiKey }) construction so we can assert the client is built fresh per call (no module-scope singleton)." / "If a singleton sneaks back, the second call would reuse key-A."

**Location:** `app/lib/llm/callLlm.test.ts:3-4` (also `:51-53`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified · r2=Verified
**Scope:** Covers that the test does what its comments say and that it passes against current `callLlm` (per-call construction with the current `ANTHROPIC_API_KEY`); does not establish per-call construction in `streamLlm` (see Claim 3).

The test mocks the SDK constructor to push each `apiKey` and asserts two calls with rotated env keys produce two constructions:

```ts
// app/lib/llm/callLlm.test.ts:53
expect(constructorCalls).toEqual([{ apiKey: "key-A" }, { apiKey: "key-B" }]);
```

Executed (r2 E1 / r1 `callLlm.test.ts` run): `callLlm Anthropic client lifetime > constructs a fresh Anthropic client per call (no singleton)` — 1 test passed, exit 0, recorded constructions `[{ apiKey: "key-A" }, { apiKey: "key-B" }]`. Statically, no module-scope client variable remains: `rg -n "getAnthropicClient" app` returns no hits, and the singleton form (`let _anthropicClient` / `getAnthropicClient`) was removed by commit 7c799cc (paraphrased — no quote available because the claim covers absence of code — no matching grep results).

**Evidence:** `app/lib/llm/callLlm.test.ts:1-55`, `app/lib/llm/callLlm.ts:14-16`, `./evidence/r2-vitest-callLlm-existing.txt`, `./evidence/r1-calllm-client-lifetime-test.txt`

---

## Claim 3: "Construct a fresh Anthropic client per call. ... per-call construction means an env-var rotation (e.g. swapping ANTHROPIC_API_KEY in the Vercel dashboard) takes effect on the next request without needing a redeploy or process restart."

**Location:** `app/lib/llm/callLlm.ts:10-13`
**Type:** Performance / Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified · r2=Verified
**Scope:** Covers both consumers of `makeAnthropicClient` (`callLlm` and `streamAnthropic`) re-reading `process.env` and constructing a fresh client per invocation; does not establish how quickly the Vercel platform propagates dashboard env changes to running instances (outside the codebase).

The factory constructs unconditionally, and the key is read from the environment on every call:

```ts
// app/lib/llm/callLlm.ts:14-16
export function makeAnthropicClient(apiKey: string): Anthropic {
  return new Anthropic({ apiKey });
}
```

```ts
// app/lib/llm/callLlm.ts:111
const anthropicKey = process.env.ANTHROPIC_API_KEY;
```

`streamLlm` does the same (`app/lib/llm/streamLlm.ts:84` reads the env var; `:207` calls `makeAnthropicClient(opts.apiKey)`). Executed: r2 E1 proves `callLlm` picks up a rotated key on the next call; r2 E2's `streamAnthropic per-call client construction` test proves the streaming path constructs `[{ apiKey: "stream-key-A" }, { apiKey: "stream-key-B" }]` across two rotated calls (paraphrased — no quote available because the assertions live in the archived scratch test). r1 additionally benchmarked the "cheap to instantiate" rationale: 10,000 constructions in 19.86 ms (~1.99 µs each), exit 0.

**Evidence:** `app/lib/llm/callLlm.ts:14-16`, `app/lib/llm/callLlm.ts:111`, `app/lib/llm/streamLlm.ts:84`, `app/lib/llm/streamLlm.ts:207`, `./evidence/r2-vitest-callLlm-existing.txt`, `./evidence/r2-vitest-scratch.txt`, `./evidence/r1-client-construction-benchmark.txt`, `./evidence/r1-calllm-client-lifetime-test.txt`

---

## Claim 4: "When provided, enforces structured JSON output via OpenRouter's response_format. Only used with the OpenRouter provider (Anthropic direct API does not support this)."

**Location:** `app/lib/llm/callLlm.ts:56-57`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Incorrect · r2=— · single-replicate detection
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
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection
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
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection
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
**Replicate verdicts:** r1=Verified · r2=Verified
**Scope:** Covers `callLlm`'s OpenRouter non-OK branch (console output and the thrown error's payload); does not establish that route handlers make privacy-preserving choices with `details` — in fact every current `OpenRouterError` catch surfaces `err.details` to the HTTP caller (e.g. `route.ts:91`), which the comment's "can decide" wording permits but a reader should know.

```ts
// app/lib/llm/callLlm.ts:186-187
console.error(`[${endpoint}] OpenRouter error: status=${response.status}`);
throw new OpenRouterError(response.status, errorBody);
```

Executed (r2 E2 `callLlm OpenRouter error handling`; r1 scratch redaction run): with fetch mocked to a non-OK status whose body is a secret marker (`SECRET_PROVIDER_BODY` / `SECRET_PROVIDER_BODY_XYZ`), the thrown error was an `OpenRouterError` carrying the correct status and `details === <marker>`, while the `console.error` spy captured only `status=<code>` and not the body (paraphrased — no quote available because these are spy/throw assertions in the archived scratch tests). Statically, all seven catch sites (`app/api/edit/artifact/route.ts:89-93`, `app/api/edit/whole/route.ts:35-38`, `app/api/edit/inline/route.ts:27-30`, `app/api/refine/context/route.ts:52-55`, `app/api/formalization/lean/route.ts:143-146`, `app/api/explanation/lean-error/route.ts:36-39`, `app/lib/formalization/artifactRoute.ts:114-118`) return `details: err.details` to the caller in a 502 JSON body — consistent with "route handlers decide what to surface".

**Evidence:** `app/lib/llm/callLlm.ts:180-188`, `app/api/edit/artifact/route.ts:88-94`, `app/lib/formalization/artifactRoute.ts:114-118`, `./evidence/r2-vitest-scratch.txt`, `./evidence/r1-redaction-scratch-tests.txt`, `./evidence/r1-scratch-redaction-test-source.ts`

---

## Claim 8: "The streaming catch block intentionally does not log or forward `details` over SSE (provider error bodies can echo request content), but the property remains attached to the thrown Error for any in-process consumer that opts in to reading it."

**Location:** `app/lib/llm/streamLlm.ts:25-29`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified · r2=Verified
**Scope:** Covers the `streamLlm` catch block's console output and SSE `error` payload, and the `details` property attachment; does not establish that any in-process consumer currently exists (none does — `getErrorDetails` was removed and no code reads `.details` off these thrown errors), so the "opts in" clause is currently hypothetical.

The catch block logs and forwards only the message:

```ts
// app/lib/llm/streamLlm.ts:160-162
console.error(`[${endpoint}] Stream error: ${message}`);
try {
  controller.enqueue(sseEvent("error", { error: message }));
```

and the property is attached before throwing:

```ts
// app/lib/llm/streamLlm.ts:30-34
function errorWithDetails(message: string, details: string): Error {
  const err = new Error(message);
  (err as Error & { details: string }).details = details;
  return err;
}
```

Executed (r2 E2 `streamLlm catch block redaction`; r1 scratch stream run): a mocked OpenRouter 500 with body `SECRET_PROVIDER_BODY(_XYZ)` produced an SSE error event whose data equals `{ error: "OpenRouter API error: 500" }`, the raw stream did not contain the body, and the log spy did not capture the body (paraphrased — no quote available because these are stream/spy assertions in the archived scratch tests). Grep confirms no current reader of `.details` on the streaming path (`rg -n "getErrorDetails" app` returns no hits).

**Evidence:** `app/lib/llm/streamLlm.ts:25-34`, `app/lib/llm/streamLlm.ts:156-165`, `app/lib/llm/streamLlm.ts:263-266`, `./evidence/r2-vitest-scratch.txt`, `./evidence/r1-redaction-scratch-tests.txt`

---

## Claim 9: "Record analytics and write to cache (same as callLlm's recordAndCache)."

**Location:** `app/lib/llm/streamLlm.ts:45`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Verified · r2=Mostly accurate
**Scope:** Covers the equivalence of the two `recordAndCache` helpers' side effects (analytics append + conditional cache write, failures swallowed); does not establish cache-read compatibility between entries written by each.

Both helpers append the same analytics entry shape and cache when `text` is non-empty, but the cached payloads differ: the streaming version caches `{ text, usage }`:

```ts
// app/lib/llm/streamLlm.ts:61
try { await setCachedResult(cacheHash, { text, usage }); } catch { /* non-fatal */ }
```

while `callLlm`'s version caches a result that also carries `cacheKey` (and returns it, where the stream version returns void):

```ts
// app/lib/llm/callLlm.ts:91-93
const result: CallLlmResult = { text, usage, cacheKey };
if (text) {
  try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
```

The recording mechanism is the same; "same as" is imprecise about the extra `cacheKey` field in `callLlm`'s cached value. A precise version: "same analytics + cache side effects as callLlm's recordAndCache, minus the `cacheKey` field and return value." (r1 verdicted this Verified, judging the return-shape difference not misleading; r2 called it Mostly accurate for the omitted `cacheKey`. Most-severe-wins → Mostly accurate.)

**Evidence:** `app/lib/llm/streamLlm.ts:45-63`, `app/lib/llm/callLlm.ts:74-96`

---

## Claim 10a: "SSE protocol: event: token — { text: \"partial chunk\" } / event: done — { text: \"full accumulated text\", usage: LlmCallUsage }"

**Location:** `app/lib/llm/streamLlm.ts:68-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified · r2=Verified
**Scope:** Covers the token and done event payload shapes across the Anthropic, OpenRouter, cache, and mock branches; does not cover the error event (Claim 10b) or client-side parsing.

Token events carry `{ text }` and done events carry `{ text, usage }` on every emitting branch:

```ts
// app/lib/llm/streamLlm.ts:237
controller.enqueue(sseEvent("done", { text: accumulated, usage }));
```

The same shapes appear at the cache-hit (`streamLlm.ts:108`), simulated-stream (`:186`, `:190`), mock (`:153`), token (`:221`), and OpenRouter (`:299`, `:321`) emit sites (paraphrased — no quote available because the identical one-line pattern repeats across the emit sites). Executed corroboration (r2 E2, cache-hit test): the cache branch emitted exactly one `done` event.

**Evidence:** `app/lib/llm/streamLlm.ts:108,153,186,190,221,237,299,321`, `./evidence/r2-vitest-scratch.txt`

---

## Claim 10b: "event: error — { error: \"message\", details: \"...\" }"

**Location:** `app/lib/llm/streamLlm.ts:71`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Stale · r2=Stale
**Scope:** Covers the documented shape of the SSE `error` event versus the single emit site; does not establish whether any client currently depends on `details` (the in-repo consumer `app/lib/formalization/api.ts:92` reads only `.error`, so no in-repo breakage).

The protocol JSDoc still documents a `details` field, but commit 7c799cc removed it from the only emit site. The catch block now sends only `error`:

```ts
// app/lib/llm/streamLlm.ts:162
controller.enqueue(sseEvent("error", { error: message }));
```

Executed (both replicates): the emitted error event's data parsed to exactly `{ error: "OpenRouter API error: 500" }` and `Object.keys(data)` equaled `["error"]` — no `details` key on the wire (paraphrased — no quote available because the assertion is over parsed stream output in the archived scratch tests). The claim was accurate before this change (the removed `getErrorDetails` fed a `details` field into the same emit, per the diff); the neighboring `errorWithDetails` JSDoc was updated but this protocol block was not. The in-repo SSE consumer reads only the `error` field:

```ts
// app/lib/formalization/api.ts:92
errorMsg = JSON.parse(dataStr).error ?? errorMsg;
```

A client implementing per this protocol doc and reading `details` will always get `undefined`.

**Evidence:** `app/lib/llm/streamLlm.ts:65-75`, `app/lib/llm/streamLlm.ts:156-165`, `app/lib/formalization/api.ts:89-94`, `./evidence/r2-vitest-scratch.txt`, `./evidence/r1-redaction-scratch-tests.txt`

---

## Claim 11a: "Provider chain mirrors callLlm(): Anthropic → OpenRouter → mock."

**Location:** `app/lib/llm/streamLlm.ts:73`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified · r2=Verified (as compound Claim 7c)
**Scope:** Covers the branch order in `streamLlm`'s `start()` against `callLlm`'s; does not establish equivalence of the branches' internals (e.g. `responseFormat` exists only in `callLlm`).

`streamLlm` selects `if (anthropicKey)` → `else if (openRouterKey && openRouterModel)` → `else` mock:

```ts
// app/lib/llm/streamLlm.ts:114-134 (abridged)
if (anthropicKey) {
  await streamAnthropic(controller, { ... });
} else if (openRouterKey && openRouterModel) {
  await streamOpenRouter(controller, { ... });
} else {
  // Mock fallback
```

matching `callLlm`'s order (guards at `callLlm.ts:130`, `callLlm.ts:161`, mock fallback at `callLlm.ts:205-206`; quoted/cited at Claim 6) (paraphrased — no quote available because the mirrored chain spans two functions of ~70 lines each). r1 additionally noted both compute `effectiveModel` with the identical ternary. Executed corroboration (r2 E2): the mock-vs-provider selection is exercised by the scratch construction tests.

**Evidence:** `app/lib/llm/streamLlm.ts:84-155`, `app/lib/llm/callLlm.ts:110-223`, `./evidence/r2-vitest-scratch.txt`

---

## Claim 11b: "Cache hits emit a single `done` event."

**Location:** `app/lib/llm/streamLlm.ts:75`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (as compound Claim 7c)
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

`simulateStreamFromCache` enqueues a `token` event per ~20-char chunk (`streamLlm.ts:184-187`) before the final `done` (`streamLlm.ts:190`). The precise version: "Cache hits emit a single `done` event unless `SIMULATE_STREAM_FROM_CACHE=true`, which replays the cached text as token events first." (r1 flagged the missing qualifier as Mostly accurate; r2, verdicting the compound sentence, read the flag as an out-of-scope testing escape hatch documented three lines below and called the default-path reading Verified. Most-severe-wins → Mostly accurate.)

**Evidence:** `app/lib/llm/streamLlm.ts:97-112`, `app/lib/llm/streamLlm.ts:176-191`

---

## Claim 12: "Provider error bodies can echo parts of the request, so don't write them to logs or send them to the client over SSE."

**Location:** `app/lib/llm/streamLlm.ts:158-159`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection
**Scope:** Covers the catch block's own log and SSE output for errors reaching it (including OpenRouter error bodies attached via `errorWithDetails`); does not establish that `err.message` itself can never contain request content for arbitrary provider SDK errors.

The catch logs `message` only —

```ts
// app/lib/llm/streamLlm.ts:157-162
const message = err instanceof Error ? err.message : "Unknown error";
// ...
console.error(`[${endpoint}] Stream error: ${message}`);
try {
  controller.enqueue(sseEvent("error", { error: message }));
```

Executed (r2 E2): with a provider error body of `SECRET_PROVIDER_BODY`, neither the log spy nor the raw SSE stream contained the body (paraphrased — no quote available because these are spy/stream assertions in the archived scratch test). The client observes only the generic message (`"OpenRouter API error: 500"`); the server log observes the same message; the body itself is currently observed by no one on the streaming path (it stays on the swallowed Error's `details`).

**Evidence:** `app/lib/llm/streamLlm.ts:156-165`, `app/lib/llm/streamLlm.ts:263-265`, `./evidence/r2-vitest-scratch.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`app/lib/llm/callLlm.ts:56-57`): Comment says `responseFormat` is "only used with the OpenRouter provider (Anthropic direct API does not support this)", but the Anthropic branch consumes it via `output_config.format` at `callLlm.ts:139-146`, and the Anthropic Messages API does support structured outputs. Update or delete the parenthetical. (Single-replicate detection: r1 only; r2 did not surface this claim.)

### Stale
- **Claim 10b** (`app/lib/llm/streamLlm.ts:71`): Protocol JSDoc still documents the SSE error event as `{ error, details }`, but commit 7c799cc removed `details` from the only emit site (`streamLlm.ts:162` now sends `{ error }`; executed: wire payload keys are exactly `["error"]`). Update the protocol line to match. (Both replicates.)

### Mostly Accurate
- **Claim 1c** (`app/api/edit/artifact/route.ts:77-78`): "shouldn't end up in server logs" holds in this route but not pipeline-wide — `app/lib/formalization/artifactRoute.ts:106-107` still `console.error`s a 500-char preview of the same class of user-derived LLM response text (executed). Qualify the comment to route-local scope. (Single-replicate detection: r2 only.)
- **Claim 9** (`app/lib/llm/streamLlm.ts:45`): "same as callLlm's recordAndCache" — same side effects, but the cached payload differs (`callLlm`'s version also stores `cacheKey` and returns the result). (Divergent: r1=Verified, r2=Mostly accurate.)
- **Claim 11b** (`app/lib/llm/streamLlm.ts:75`): "Cache hits emit a single `done` event" needs a qualifier for `SIMULATE_STREAM_FROM_CACHE=true`, which emits token events first (`streamLlm.ts:102-109`). (Divergent: r1=Mostly accurate, r2=Verified via the compound provider-chain+cache claim.)

### Unverifiable
- None.

---

## Verdict stability

- **Total merged clusters:** 16
- **Dual-reported clusters (both replicates surfaced):** 11 — Claims 1a, 1b, 2, 3, 7, 8, 9, 10a, 10b, 11a, 11b
- **Single-replicate detections:** 5 — Claim 1c (r2), Claim 4 (r1), Claim 5 (r1), Claim 6 (r1), Claim 12 (r2)
- **Agreement among dual-reported clusters:** 9/11 (81.8%)
- **Disagreements (2):**
  - **Claim 9** (`streamLlm.ts:45`): r1=Verified, r2=Mostly accurate → merged **Mostly accurate** (most-severe-wins; r2 caught the omitted `cacheKey` field).
  - **Claim 11b** (`streamLlm.ts:75`): r1=Mostly accurate, r2=Verified → merged **Mostly accurate** (most-severe-wins; r1 caught the missing `SIMULATE_STREAM_FROM_CACHE` qualifier that r2's compound-claim reading treated as out of scope).
- **Compound/atomic mismatches resolved (decision 033):**
  - route.ts:77-85 — r1 verdicted one compound claim (Claim 1, Verified); r2 split it into 1a (log-only-length) + 1b (echo-slice), both Verified. Merged as the split 1a/1b, both Verified.
  - streamLlm.ts:73-75 — r2 verdicted one compound claim (Claim 7c: provider chain + cache-hit, Verified); r1 split it into 11a (provider chain, Verified) + 11b (cache hits, Mostly accurate). The compound clusters with each part; most-severe-wins across the cluster yields 11a=Verified, 11b=Mostly accurate.

Single sample per cluster (k=2, two replicates); five clusters rest on one replicate's observation. No hallucination-pattern (fabricated symbol/API) fabrications among the Incorrect verdicts — Claim 4 is a capability/branch-routing mismatch, not a fabricated symbol.
