Commit: f2f149b

# Test Strategy: LLM-server hygiene (branch d86d2dc..f2f149b)

**Scope:** `app/lib/llm/callLlm.ts`, `app/lib/llm/streamLlm.ts`, `app/api/edit/artifact/route.ts`, `app/lib/llm/callLlm.test.ts` (new)
**Reviewed:** 2026-08-06
**Tier:** Advisory (all findings green / "Consider")

## Test Conventions

Vitest (`vitest.config.ts`, `vitest.setup.ts`), tests co-located as `*.test.ts` next to source under `app/lib/llm/`. Pattern: `vi.mock` module boundaries (`./cache`, `./costs`, analytics persist, `@anthropic-ai/sdk`), `beforeEach` clears env vars, SSE assertions collect events by reading the `ReadableStream` and splitting on `\n\n` (see `streamLlm.test.ts` `collectEvents`). AAA style. This diff already follows the conventions in the new `callLlm.test.ts`.

## Untested Paths Touched by the Change

- **G1** — `app/lib/llm/streamLlm.ts:161-162` — SSE `error` event emits `{ error: message }` with **no `details`** when the stream body throws — not covered. `streamLlm.test.ts` exercises only the mock-done and cache-done paths; nothing drives the `catch` block, so the PR's central contract (details no longer leave the process over SSE) has zero regression guard.
- **G2** — `app/lib/llm/streamLlm.ts:160` — the stream `catch` logs only `message`, not the provider `errorBody` — not covered; no assertion that `console.error` output excludes the provider body.
- **G3** — `app/lib/llm/callLlm.ts:181-187` — OpenRouter `!response.ok` branch: logs `status=` only (not `errorBody`) and throws `OpenRouterError(status, errorBody)` — not covered. `callLlm.test.ts` drives only the Anthropic success path; the OpenRouter error branch (both the log-hygiene change and the `details`-rides-on-error contract) is unexercised.
- **G4** — `app/api/edit/artifact/route.ts:77-85` — invalid-JSON `catch`: logs `${responseText.length} chars` only, returns 502 with `details: responseText.slice(0,500)` — not covered; no `route.ts` test file exists for this handler.
- **G5** — `app/lib/llm/streamLlm.ts:207` — `streamAnthropic` uses `makeAnthropicClient` (fresh-per-call) — not covered on the streaming path; `callLlm.test.ts` pins the invariant only for the non-streaming `callLlm` path.
- **G6** — `app/lib/llm/streamLlm.ts:71` — SSE protocol JSDoc still documents `event: error — { error, details }` while the emit site sends `{ error }` only (fact-check Claim 5, stale). A shape assertion on the error event would have caught this drift and would keep doc and emit in lockstep.

## Recommended Tests

#### streamLlm error event omits `details` and log omits provider body
**Closes gaps:** G1, G2
**Type:** unit
**Priority:** medium (highest-value here — it is the exact regression this PR exists to prevent)
**File:** `app/lib/llm/streamLlm.test.ts`
**What it verifies:** when the provider path throws, the SSE `error` event carries `error` only (no `details` key) and the provider body never reaches `console.error`.
**Key cases:**
- Set `OPENROUTER_API_KEY` + `openRouterModel`, mock `fetch` to resolve `{ ok:false, status:429, text: async () => "SECRET_BODY echoing request" }`; collect events → exactly one `error` event, `data.error` set, `"details" in data === false`.
- Spy `console.error`; assert no call argument contains `"SECRET_BODY"` (only `message` / status).
**Setup needed:** `vi.spyOn(console,"error")`; `globalThis.fetch` mock (restored in `afterEach`), as in the existing `fetchStreamingApi` test.

#### callLlm OpenRouter error branch: log hygiene + details on OpenRouterError
**Closes gaps:** G3
**Type:** unit
**Priority:** medium
**File:** `app/lib/llm/callLlm.test.ts`
**What it verifies:** on a non-ok OpenRouter response, `callLlm` throws `OpenRouterError` with `status` and `details === errorBody`, logs `status=` without the body.
**Key cases:**
- `OPENROUTER_API_KEY` set (no Anthropic key), `fetch` → `{ ok:false, status:502, text: async () => "PROVIDER_BODY" }`; expect throw `instanceof OpenRouterError`, `err.details === "PROVIDER_BODY"`, `err.status === 502`.
- `console.error` spy: asserted call contains `status=502`, does not contain `"PROVIDER_BODY"`.
**Setup needed:** `globalThis.fetch` mock; reuse existing `./cache` / `./costs` / analytics mocks already in the file.

#### edit/artifact route: invalid-JSON path logs length, echoes slice to caller
**Closes gaps:** G4
**Type:** integration
**Priority:** low
**File:** `app/api/edit/artifact/route.test.ts` (new)
**What it verifies:** when the LLM returns non-JSON, the 502 body includes `details` (first 500 chars) for the caller while the server log records only a char count.
**Key cases:**
- Mock `callLlm` to resolve invalid JSON text; POST → 502, `body.details` is the slice; `console.error` argument matches `/\d+ chars/` and does not contain the response content.
**Setup needed:** mock `@/app/lib/llm/callLlm`; construct a `NextRequest`. Note the setup cost (Next route harness) — deferred, hence low priority.

## What NOT to Test

- `makeAnthropicClient` on the streaming path (G5) as a *separate* test — the fresh-per-call invariant is already pinned for the shared factory by `callLlm.test.ts`; duplicating it on `streamAnthropic` adds maintenance cost for the same guarantee. If G1's test is written, have it use the Anthropic path (not OpenRouter) once so the streaming factory is at least smoke-exercised, rather than a dedicated test.
- The rename `getAnthropicClient → makeAnthropicClient` itself — pure mechanical rename, covered by the type checker and existing imports.

## Coverage Gaps Beyond Current Scope

**1.** No test file exists for `app/api/edit/artifact/route.ts` (or, likely, sibling API routes) — the whole route layer's error-response contract is untested. G4 is one instance; the broader gap is worth a follow-up route-testing pass.

## Summary

The highest-value missing test is the streamLlm error-path assertion (G1/G2): this PR's entire purpose is to stop `details`/provider bodies from leaving the process via SSE and logs, yet no test drives the `catch` block, so a future edit re-adding `details` to `sseEvent("error", ...)` would pass CI silently. The OpenRouter error branch in `callLlm` (G3) has the same shape and is cheap to add alongside the existing mocks. The stale SSE-protocol JSDoc (G6, fact-check Claim 5) is the concrete symptom of having no shape test pinning the error-event contract — writing G1 with an explicit `"details" in data === false` assertion both closes the gap and would flag the doc drift. Residual risk after the plan: the route layer (G4) stays thin on coverage, but its blast radius is a visible 502 rather than a silent leak. Open question surfaced by the enumeration: is the caller-facing `details` slice in `route.ts` (still echoed to the requester) an intentional carve-out from the no-leak rule? The comment says yes (requester originated the input); a test documenting that asymmetry would make the intent legible.
