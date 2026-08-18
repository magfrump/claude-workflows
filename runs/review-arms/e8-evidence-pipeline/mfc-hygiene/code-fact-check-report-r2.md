# Code Fact-Check Report

**Repository:** /workspace/external/cc-review-eval/mfc-hygiene
**Commit:** f2f149b
**Scope:** `git diff d86d2dc...HEAD` — `app/api/edit/artifact/route.ts`, `app/lib/llm/callLlm.test.ts`, `app/lib/llm/callLlm.ts`, `app/lib/llm/streamLlm.ts` (plus sibling routes implicitly covered by redaction claims: `app/lib/formalization/artifactRoute.ts` and the `app/api/*` LLM routes)
**Checked:** 2026-08-18
**Total claims checked:** 12
**Summary:** 9 verified, 2 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Execution provenance shared by executed claims below: all commands ran in cwd `/workspace/external/cc-review-eval/mfc-hygiene` on 2026-08-18 (UTC).

- **E1** — `npx vitest run --reporter=verbose app/lib/llm/callLlm.test.ts` · exit 0 · 2026-08-18T06:42:50Z · output: `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-hygiene/evidence/r2-vitest-callLlm-existing.txt`
- **E2** — `npx vitest run --reporter=verbose app/lib/llm/r2-factcheck-lib.scratch.test.ts app/lib/llm/r2-factcheck-routes.scratch.test.ts` · exit 0 · 2026-08-18T06:42:49Z · output: `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-hygiene/evidence/r2-vitest-scratch.txt` · test sources archived at `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-hygiene/evidence/r2-scratch-lib-test-source.ts` and `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-hygiene/evidence/r2-scratch-routes-test-source.ts` (scratch tests were deleted from the clone after the run)

---

## Claim 1a: "Log only length, not content — `responseText` is a function of the user's source material and shouldn't end up in server logs." (the log-only-length part)

**Location:** `app/api/edit/artifact/route.ts:77-81`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the invalid-JSON `console.error` in this route's whole-edit branch; does not establish log hygiene of any other route (see Claim 1c) or of the route's outer catch block.

The log line interpolates only the length:

```ts
// app/api/edit/artifact/route.ts:81
console.error(`[edit/artifact] LLM returned invalid JSON: ${responseText.length} chars`);
```

Executed (E2, route scratch test `edit/artifact invalid-JSON redaction`): with `callLlm` mocked to return a 615-char non-JSON string containing marker `NOTJSON_MARKER_`, the `console.error` spy captured `"615 chars"` and did **not** capture the marker (paraphrased — no quote available because the assertion is over a spy's captured call list in the archived scratch test, not a source snippet).

**Evidence:** `app/api/edit/artifact/route.ts:77-81`, E2 (`/workspace/runs/review-arms/e8-evidence-pipeline/mfc-hygiene/evidence/r2-vitest-scratch.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-hygiene/evidence/r2-scratch-routes-test-source.ts`)

---

## Claim 1b: "The response payload still echoes a slice back to the caller, since they originated the request and need it to debug their input."

**Location:** `app/api/edit/artifact/route.ts:79-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 502 response body of the invalid-JSON branch; does not establish what clients do with the echoed slice.

```ts
// app/api/edit/artifact/route.ts:82-85
return NextResponse.json(
  { error: "LLM response was not valid JSON", details: responseText.slice(0, 500) },
  { status: 502 },
);
```

Executed (E2, same test as 1a): the route returned status 502 with `details === responseText.slice(0, 500)` (length 500) for the 615-char input (paraphrased — no quote available because the values are runtime assertions in the archived scratch test).

**Evidence:** `app/api/edit/artifact/route.ts:82-85`, E2

---

## Claim 1c: "`responseText` ... shouldn't end up in server logs" (read as a redaction guarantee for LLM response text)

**Location:** `app/api/edit/artifact/route.ts:77-78`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether LLM response text (user-source-derived) reaches server logs across the routes sharing the `callLlm` pipeline; does not cover logs emitted by the Anthropic/OpenRouter SDKs themselves.

Under the narrow, route-local reading the claim is fully true (see Claim 1a). But the rationale states a general policy — response text is "a function of the user's source material and shouldn't end up in server logs" — and the sibling generic artifact handler, which serves the same `callLlm` pipeline and the same invalid-JSON failure, still logs a 500-char preview of the response content:

```ts
// app/lib/formalization/artifactRoute.ts:106-107
const preview = responseText.slice(0, 500);
console.error(`[${config.endpoint}] Failed to parse LLM response as JSON:`, preview);
```

Executed (E2, route scratch test `artifactRoute invalid-JSON logging`): calling `handleArtifactRoute` with `callLlm` mocked to return the marker string, the `console.error` spy **did** capture `NOTJSON_MARKER_` — the same class of data this comment says shouldn't reach server logs (paraphrased — no quote available because the finding is a spy assertion in the archived scratch test). The comment's mechanism and its local conclusion are both right; a reader inferring the stated policy holds pipeline-wide would be misled, hence the qualifier belongs in the comment.

**Evidence:** `app/api/edit/artifact/route.ts:77-81`, `app/lib/formalization/artifactRoute.ts:106-107`, E2

---

## Claim 2: "Track every Anthropic({ apiKey }) construction so we can assert the client is built fresh per call (no module-scope singleton)." / "If a singleton sneaks back, the second call would reuse key-A."

**Location:** `app/lib/llm/callLlm.test.ts:3-4` (also `:51-53`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test does what its comments say and that it passes against current `callLlm`; does not establish per-call construction in `streamLlm` (see Claim 3).

The test mocks the SDK constructor to push each `apiKey` and asserts two calls with rotated env keys produce two constructions:

```ts
// app/lib/llm/callLlm.test.ts:53
expect(constructorCalls).toEqual([{ apiKey: "key-A" }, { apiKey: "key-B" }]);
```

Executed (E1): `callLlm Anthropic client lifetime > constructs a fresh Anthropic client per call (no singleton)` — 1 test passed, exit 0. Statically, no module-scope client variable remains: `rg -n "getAnthropicClient" app` returns no hits (paraphrased — no quote available because the claim covers absence of code — no matching grep results).

**Evidence:** `app/lib/llm/callLlm.test.ts:1-55`, `app/lib/llm/callLlm.ts:14-16`, E1

---

## Claim 3: "Construct a fresh Anthropic client per call. ... per-call construction means an env-var rotation (e.g. swapping ANTHROPIC_API_KEY in the Vercel dashboard) takes effect on the next request without needing a redeploy or process restart."

**Location:** `app/lib/llm/callLlm.ts:10-13`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both consumers of `makeAnthropicClient` (`callLlm` and `streamAnthropic`) re-reading `process.env` and constructing a fresh client per invocation; does not establish how quickly the Vercel platform itself propagates dashboard env changes to running instances, and the "SDK is cheap to instantiate" rationale was not benchmarked.

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

`streamLlm` does the same (`app/lib/llm/streamLlm.ts:84` reads the env var; `:207` calls `makeAnthropicClient(opts.apiKey)`). Executed: E1 proves `callLlm` picks up a rotated key on the next call; E2's `streamAnthropic per-call client construction` test proves the streaming path constructs `[{ apiKey: "stream-key-A" }, { apiKey: "stream-key-B" }]` across two rotated calls (paraphrased — no quote available because the assertions live in the archived scratch test).

**Evidence:** `app/lib/llm/callLlm.ts:14-16`, `app/lib/llm/callLlm.ts:111`, `app/lib/llm/streamLlm.ts:84`, `app/lib/llm/streamLlm.ts:207`, E1, E2

---

## Claim 4: "Log only status + endpoint here; the body can echo parts of the request and we don't want it on disk in plaintext. The body still rides on OpenRouterError so route handlers can decide what (if anything) to surface to the caller."

**Location:** `app/lib/llm/callLlm.ts:182-185`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the non-ok branch of `callLlm`'s OpenRouter fetch (log content and error propagation); does not establish that route handlers make privacy-preserving choices with `details` — in fact every current handler forwards it to the caller.

```ts
// app/lib/llm/callLlm.ts:186-187
console.error(`[${endpoint}] OpenRouter error: status=${response.status}`);
throw new OpenRouterError(response.status, errorBody);
```

Executed (E2, `callLlm OpenRouter error handling` test): with fetch mocked to a 429 whose body is `SECRET_PROVIDER_BODY`, the thrown error was an `OpenRouterError` with `status === 429` and `details === "SECRET_PROVIDER_BODY"`, and the `console.error` spy captured `status=429` but not the body (paraphrased — no quote available because these are spy/throw assertions in the archived scratch test). Who observes the failure: all seven catch sites (`app/api/edit/artifact/route.ts:89-93`, `app/api/edit/whole/route.ts:35-38`, `app/api/edit/inline/route.ts:27-30`, `app/api/refine/context/route.ts:52-55`, `app/api/formalization/lean/route.ts:143-146`, `app/api/explanation/lean-error/route.ts:36-39`, `app/lib/formalization/artifactRoute.ts:114-118`) return `details: err.details` to the caller in a 502 JSON body — consistent with "route handlers decide what to surface" (paraphrased — no quote available because the behavior spans seven near-identical catch blocks located by grep).

**Evidence:** `app/lib/llm/callLlm.ts:180-188`, `app/api/edit/artifact/route.ts:89-93`, `app/lib/formalization/artifactRoute.ts:114-118`, E2

---

## Claim 5: "The streaming catch block intentionally does not log or forward `details` over SSE (provider error bodies can echo request content), but the property remains attached to the thrown Error for any in-process consumer that opts in to reading it."

**Location:** `app/lib/llm/streamLlm.ts:25-29`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the streaming catch block's log/SSE output and the `details` property attachment; does not establish that any in-process consumer currently exists (none does — `getErrorDetails` was removed and no code reads `.details` off these errors).

The catch block logs and forwards only the message:

```ts
// app/lib/llm/streamLlm.ts:160-162
console.error(`[${endpoint}] Stream error: ${message}`);
try {
  controller.enqueue(sseEvent("error", { error: message }));
```

and the property is attached before throwing:

```ts
// app/lib/llm/streamLlm.ts:31-32
const err = new Error(message);
(err as Error & { details: string }).details = details;
```

Executed (E2, `streamLlm catch block redaction` test): a mocked OpenRouter 500 with body `SECRET_PROVIDER_BODY` produced an SSE error event whose data equals `{ error: "OpenRouter API error: 500" }`, the raw stream did not contain the body, and the log spy did not capture the body (paraphrased — no quote available because these are stream/spy assertions in the archived scratch test). The claim's hedge is accurate as written — it promises availability to a consumer that "opts in", not that one exists; grep confirms no current reader of `.details` on the streaming path (paraphrased — no quote available because the claim covers absence of code — `rg -n "getErrorDetails" app` returns no hits).

**Evidence:** `app/lib/llm/streamLlm.ts:25-34`, `app/lib/llm/streamLlm.ts:156-165`, E2

---

## Claim 6: "Record analytics and write to cache (same as callLlm's recordAndCache)."

**Location:** `app/lib/llm/streamLlm.ts:45`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the equivalence of the two `recordAndCache` helpers' side effects; does not establish cache-read compatibility between entries written by each.

Both helpers append the same analytics entry shape and cache when `text` is non-empty, but the cached payloads differ: the streaming version caches `{ text, usage }`:

```ts
// app/lib/llm/streamLlm.ts:61
try { await setCachedResult(cacheHash, { text, usage }); } catch { /* non-fatal */ }
```

while `callLlm`'s version caches a result that also carries `cacheKey`:

```ts
// app/lib/llm/callLlm.ts:91-93
const result: CallLlmResult = { text, usage, cacheKey };
if (text) {
  try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
```

The recording mechanism is the same; "same as" is imprecise about the extra `cacheKey` field in `callLlm`'s cached value (and `callLlm`'s version returns the result while the stream version returns void). A precise version: "same analytics + cache side effects as callLlm's recordAndCache, minus the `cacheKey` field and return value."

**Evidence:** `app/lib/llm/streamLlm.ts:45-63`, `app/lib/llm/callLlm.ts:74-96`

---

## Claim 7a: "SSE protocol: event: token — { text: \"partial chunk\" } / event: done — { text: \"full accumulated text\", usage: LlmCallUsage }"

**Location:** `app/lib/llm/streamLlm.ts:68-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the token and done event payload shapes across the Anthropic, OpenRouter, cache, and mock branches; does not cover the error event (Claim 7b).

Token events carry `{ text }` and done events carry `{ text, usage }` on every emitting branch:

```ts
// app/lib/llm/streamLlm.ts:221
controller.enqueue(sseEvent("token", { text }));
```

```ts
// app/lib/llm/streamLlm.ts:237
controller.enqueue(sseEvent("done", { text: accumulated, usage }));
```

The same shapes appear at the cache-hit (`app/lib/llm/streamLlm.ts:108`), simulated-stream (`:186`, `:190`), mock (`:153`), and OpenRouter (`:299`, `:321`) emit sites (paraphrased — no quote available because the identical one-line pattern repeats across six call sites). Executed corroboration (E2, cache-hit test): the cache branch emitted exactly one `done` event.

**Evidence:** `app/lib/llm/streamLlm.ts:108`, `app/lib/llm/streamLlm.ts:153`, `app/lib/llm/streamLlm.ts:186-190`, `app/lib/llm/streamLlm.ts:221`, `app/lib/llm/streamLlm.ts:237`, `app/lib/llm/streamLlm.ts:299`, `app/lib/llm/streamLlm.ts:321`, E2

---

## Claim 7b: "SSE protocol: event: error — { error: \"message\", details: \"...\" }"

**Location:** `app/lib/llm/streamLlm.ts:71`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the wire shape of the `error` SSE event emitted by `streamLlm`; does not cover error responses of non-streaming routes.

The protocol JSDoc still documents a `details` field, but commit 7c799cc removed it from the emitted payload. The catch block now sends only `error`:

```ts
// app/lib/llm/streamLlm.ts:162
controller.enqueue(sseEvent("error", { error: message }));
```

Executed (E2, `SSE error event carries only { error }` test): the emitted error event's data parsed to exactly `{ error: "OpenRouter API error: 500" }` and `Object.keys(data)` equaled `["error"]` — no `details` key on the wire (paraphrased — no quote available because the assertion is over parsed stream output in the archived scratch test). At the base commit the code did enqueue `{ error: message, details }` (the diff shows the removed `getErrorDetails` call and the old enqueue line), so the JSDoc was accurate when written and the code has since diverged — the neighboring `errorWithDetails` JSDoc (Claim 5) was updated in f2f149b but this protocol block was not. A client implementing per this protocol doc and reading `details` will always get `undefined`.

**Evidence:** `app/lib/llm/streamLlm.ts:65-75`, `app/lib/llm/streamLlm.ts:156-165`, E2

---

## Claim 7c: "Provider chain mirrors callLlm(): Anthropic → OpenRouter → mock. Cache hits emit a single `done` event."

**Location:** `app/lib/llm/streamLlm.ts:73-74`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers provider selection order and the default cache-hit behavior; the cache-hit sentence is exactly true only when `SIMULATE_STREAM_FROM_CACHE` is not `"true"` — with that flag set, a cache hit emits many token events before `done`.

Selection order matches `callLlm` (key-presence checks in the same order):

```ts
// app/lib/llm/streamLlm.ts:114-134 (abridged)
if (anthropicKey) {
  await streamAnthropic(controller, { ... });
} else if (openRouterKey && openRouterModel) {
  await streamOpenRouter(controller, { ... });
} else {
  // Mock fallback
```

`callLlm` gates identically — `if (anthropicKey)` at `app/lib/llm/callLlm.ts:130`, `if (openRouterKey && openRouterModel)` at `:161`, mock fallback at `:205-206` (paraphrased — no quote available because the mirrored chain spans two functions of ~70 lines each and the gate expressions are quoted by line reference). Cache hit: executed (E2, cache-hit test) — exactly one event, type `done`. The `SIMULATE_STREAM_FROM_CACHE === "true"` branch (`app/lib/llm/streamLlm.ts:102-106`) is an explicit testing escape hatch and is documented three lines below the claim, so the sentence is read as describing the default path.

**Evidence:** `app/lib/llm/streamLlm.ts:96-155`, `app/lib/llm/callLlm.ts:130`, `app/lib/llm/callLlm.ts:161`, `app/lib/llm/callLlm.ts:205-206`, E2

---

## Claim 8: "Provider error bodies can echo parts of the request, so don't write them to logs or send them to the client over SSE."

**Location:** `app/lib/llm/streamLlm.ts:158-159`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the catch block's own log and SSE output for errors reaching it (including OpenRouter error bodies attached via `errorWithDetails`); does not establish that `err.message` itself can never contain request content for arbitrary provider SDK errors.

Same evidence as Claims 5 and 7b: the catch logs `message` only —

```ts
// app/lib/llm/streamLlm.ts:157-162
const message = err instanceof Error ? err.message : "Unknown error";
// ...
console.error(`[${endpoint}] Stream error: ${message}`);
try {
  controller.enqueue(sseEvent("error", { error: message }));
```

Executed (E2): with a provider error body of `SECRET_PROVIDER_BODY`, neither the log spy nor the raw SSE stream contained the body (paraphrased — no quote available because these are spy/stream assertions in the archived scratch test). Who observes the failure: the client observes only the generic message (`"OpenRouter API error: 500"`); the server log observes the same message; the body itself is currently observed by no one on the streaming path (it stays on the swallowed Error's `details`).

**Evidence:** `app/lib/llm/streamLlm.ts:156-165`, `app/lib/llm/streamLlm.ts:263-265`, E2

---

## Claims Requiring Attention

### Stale
- **Claim 7b** (`app/lib/llm/streamLlm.ts:71`): The SSE protocol JSDoc still documents `event: error — { error, details }`, but since 7c799cc the code emits `{ error }` only (executed: wire payload keys are exactly `["error"]`). The protocol block was not updated when the neighboring `errorWithDetails` JSDoc was.

### Mostly Accurate
- **Claim 1c** (`app/api/edit/artifact/route.ts:77-78`): "shouldn't end up in server logs" holds in this route but not pipeline-wide — `app/lib/formalization/artifactRoute.ts:106-107` still `console.error`s a 500-char preview of the same class of user-derived LLM response text (executed).
- **Claim 6** (`app/lib/llm/streamLlm.ts:45`): "same as callLlm's recordAndCache" — same side effects, but the cached payload differs (`callLlm`'s version also stores `cacheKey` and returns the result).
