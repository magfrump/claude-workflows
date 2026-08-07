Commit: f2f149b

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree: /workspace/runs/review-arms/baseline-2026-08-06/wt-hygiene)
**Scope:** branch diff `d86d2dc..f2f149b` (full-branch changeset; LLM-server-hygiene work)
**Checked:** 2026-08-06
**Total claims checked:** 8
**Summary:** 7 verified, 0 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

---

## Claim 1: "Log only length, not content — `responseText` is a function of the user's source material and shouldn't end up in server logs. The response payload still echoes a slice back to the caller..."

**Location:** `app/api/edit/artifact/route.ts:77-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The log line emits only the length, not the content:

```ts
// app/api/edit/artifact/route.ts:81
console.error(`[edit/artifact] LLM returned invalid JSON: ${responseText.length} chars`);
```

The response payload still echoes a slice back to the caller, matching the second half of the comment:

```ts
// app/api/edit/artifact/route.ts:82-85
return NextResponse.json(
  { error: "LLM response was not valid JSON", details: responseText.slice(0, 500) },
  { status: 502 },
);
```

Both halves of the claim hold: the log carries only `responseText.length`, while the HTTP response body still carries `responseText.slice(0, 500)`.

**Evidence:** `app/api/edit/artifact/route.ts:77-85`

---

## Claim 2: "Construct a fresh Anthropic client per call... per-call construction means an env-var rotation (e.g. swapping ANTHROPIC_API_KEY in the Vercel dashboard) takes effect on the next request without needing a redeploy or process restart."

**Location:** `app/lib/llm/callLlm.ts:10-13`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The factory constructs a new client each invocation with no module-scope caching (the previous `_anthropicClient` singleton was removed in this diff):

```ts
// app/lib/llm/callLlm.ts:14-16
export function makeAnthropicClient(apiKey: string): Anthropic {
  return new Anthropic({ apiKey });
}
```

The env-var-rotation claim holds because `callLlm` reads `process.env.ANTHROPIC_API_KEY` at call time and passes it straight into the factory, so a rotated env var is picked up on the next request:

```ts
// app/lib/llm/callLlm.ts:111
const anthropicKey = process.env.ANTHROPIC_API_KEY;
// app/lib/llm/callLlm.ts:133
const client = makeAnthropicClient(anthropicKey);
```

The streaming path does the same (`process.env.ANTHROPIC_API_KEY` read in `streamLlm`, passed to `streamAnthropic` → `makeAnthropicClient(opts.apiKey)` at `streamLlm.ts:207`). No lingering references to the old `getAnthropicClient` remain anywhere in the repo (grep returned zero hits).

**Evidence:** `app/lib/llm/callLlm.ts:10-16`, `app/lib/llm/callLlm.ts:111-133`, `app/lib/llm/streamLlm.ts:207`

---

## Claim 3: "Log only status + endpoint here; the body can echo parts of the request... The body still rides on OpenRouterError so route handlers can decide what (if anything) to surface to the caller."

**Location:** `app/lib/llm/callLlm.ts:182-185`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The log emits only status; endpoint is present via the message prefix; the error body is not logged:

```ts
// app/lib/llm/callLlm.ts:186-187
console.error(`[${endpoint}] OpenRouter error: status=${response.status}`);
throw new OpenRouterError(response.status, errorBody);
```

The body "rides on" the error via `OpenRouterError.details`:

```ts
// app/lib/llm/callLlm.ts:18-26
export class OpenRouterError extends Error {
  status: number;
  details: string;
  constructor(status: number, details: string) { ... this.details = details; }
}
```

And a route handler does read that field to decide what to surface, confirming the "route handlers can decide what to surface" part against a real consumer:

```ts
// app/api/edit/artifact/route.ts:89-93
if (err instanceof OpenRouterError) {
  return NextResponse.json(
    { error: err.message, details: err.details },
    { status: 502 },
  );
}
```

**Evidence:** `app/lib/llm/callLlm.ts:180-187`, `app/lib/llm/callLlm.ts:18-26`, `app/api/edit/artifact/route.ts:89-93`

---

## Claim 4: "The streaming catch block intentionally does not log or forward `details` over SSE... but the property remains attached to the thrown Error for any in-process consumer that opts in to reading it."

**Location:** `app/lib/llm/streamLlm.ts:25-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The catch block logs only `message` and the SSE `error` event carries only `error`, with no `details` logged or forwarded:

```ts
// app/lib/llm/streamLlm.ts:157-162
const message = err instanceof Error ? err.message : "Unknown error";
console.error(`[${endpoint}] Stream error: ${message}`);
try {
  controller.enqueue(sseEvent("error", { error: message }));
```

The `details` property does remain attached to the thrown Error (the factory still sets it, and `streamOpenRouter` still throws via it):

```ts
// app/lib/llm/streamLlm.ts:30-34
function errorWithDetails(message: string, details: string): Error {
  const err = new Error(message);
  (err as Error & { details: string }).details = details;
  return err;
}
// app/lib/llm/streamLlm.ts:265
throw errorWithDetails(`OpenRouter API error: ${response.status}`, errorBody);
```

Note: the "any in-process consumer that opts in to reading it" clause is aspirational — no current consumer reads the property (`getErrorDetails` was removed in this diff; grep for `getErrorDetails` returns zero hits). The claim asserts only that the property *remains attached* and is capability-conditional ("for any consumer that opts in"), which is accurate; it does not assert a live reader exists.

**Evidence:** `app/lib/llm/streamLlm.ts:25-34`, `app/lib/llm/streamLlm.ts:157-165`, `app/lib/llm/streamLlm.ts:265`

---

## Claim 5: "SSE protocol: ... event: error — { error: "message", details: "..." }"

**Location:** `app/lib/llm/streamLlm.ts:65-74` (specifically the `event: error` line, `streamLlm.ts:71`)
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High

The `streamLlm` JSDoc still documents the SSE `error` event as carrying a `details` field:

```ts
// app/lib/llm/streamLlm.ts:71
*   event: error   — { error: "message", details: "..." }
```

But the only `error`-event emit site in the module no longer includes `details` (it was removed in this same diff):

```ts
// app/lib/llm/streamLlm.ts:162
controller.enqueue(sseEvent("error", { error: message }));
```

This is the exact protocol-doc-vs-emit-site drift the brief flagged. The block was accurate before this diff removed `details` from the payload; the sibling `errorWithDetails` JSDoc (Claim 4) *was* updated to reflect the removal, but this protocol block was not, leaving it stale. I confirmed the emit side is the sole error emitter: grep for `sseEvent("error"` returns only `streamLlm.ts:162`, and downstream consumers pass error events through unchanged without reading `details` (`app/lib/llm/transformSseStream.ts:55` — "Pass through token and error events unchanged"). A client author reading this protocol block would expect a `details` field that is never sent. The precise version should read `event: error — { error: "message" }`.

**Evidence:** `app/lib/llm/streamLlm.ts:65-74`, `app/lib/llm/streamLlm.ts:162`, `app/lib/llm/transformSseStream.ts:55`

---

## Claim 6: "Provider error bodies can echo parts of the request, so don't write them to logs or send them to the client over SSE."

**Location:** `app/lib/llm/streamLlm.ts:158-159`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The immediately following code neither logs nor forwards the provider body — it logs only `message` and sends only `error: message` over SSE:

```ts
// app/lib/llm/streamLlm.ts:160-162
console.error(`[${endpoint}] Stream error: ${message}`);
try {
  controller.enqueue(sseEvent("error", { error: message }));
```

The provider body (`errorBody`) is captured only into the thrown Error's `details` (Claim 4) and is never passed to `console.error` or `sseEvent` here.

**Evidence:** `app/lib/llm/streamLlm.ts:158-165`

---

## Claim 7: "Track every Anthropic({ apiKey }) construction so we can assert the client is built fresh per call (no module-scope singleton)."

**Location:** `app/lib/llm/callLlm.test.ts:2-3`
**Type:** Behavioral (test-intent)
**Verdict:** Verified
**Confidence:** High

The mock records every constructor call, and the test asserts on the recorded sequence:

```ts
// app/lib/llm/callLlm.test.ts:12-20
vi.mock("@anthropic-ai/sdk", () => {
  return {
    default: class MockAnthropic {
      messages = { create: messagesCreate };
      constructor(opts: { apiKey: string }) {
        constructorCalls.push({ apiKey: opts.apiKey });
      }
    },
  };
});
```

This matches production behavior verified in Claim 2 (`makeAnthropicClient` constructs a fresh client per call with no singleton).

**Evidence:** `app/lib/llm/callLlm.test.ts:1-20`, `app/lib/llm/callLlm.test.ts:37-54`

---

## Claim 8: "Each call must have constructed its own client with the env-var-current key. If a singleton sneaks back, the second call would reuse key-A."

**Location:** `app/lib/llm/callLlm.test.ts:52-53`
**Type:** Behavioral (test-intent)
**Verdict:** Verified
**Confidence:** High

The test rotates the env var between two calls and asserts each construction used the then-current key:

```ts
// app/lib/llm/callLlm.test.ts:41-54
process.env.ANTHROPIC_API_KEY = "key-A";
await callLlm({ endpoint: "t1", ... });
process.env.ANTHROPIC_API_KEY = "key-B";
await callLlm({ endpoint: "t2", ... });
expect(constructorCalls).toEqual([{ apiKey: "key-A" }, { apiKey: "key-B" }]);
```

The assertion correctly encodes the failure mode described: with a reinstated singleton, the second construction would not occur and the array would be `[{ apiKey: "key-A" }]`, failing the `toEqual`. The claim's mechanism is accurate against the production code (`callLlm` reads `process.env.ANTHROPIC_API_KEY` per call — `callLlm.ts:111`).

**Evidence:** `app/lib/llm/callLlm.test.ts:37-54`, `app/lib/llm/callLlm.ts:111-133`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 5** (`app/lib/llm/streamLlm.ts:71`): SSE protocol JSDoc still documents `event: error — { error, details }`, but the emit site (`streamLlm.ts:162`) now sends `{ error }` only; `details` was removed from the SSE payload in this diff. Update the doc to `event: error — { error: "message" }`.

### Mostly Accurate
(none)

### Unverifiable
(none)
