Commit: f2f149b

# Security Review — LLM-server hygiene (branch d86d2dc..f2f149b)

**Scope:** branch diff `d86d2dc..f2f149b` — `app/api/edit/artifact/route.ts`, `app/lib/llm/callLlm.ts`, `app/lib/llm/streamLlm.ts`, `app/lib/llm/callLlm.test.ts`
**Date:** 2026-08-06
**Based on:** fact-check report `/workspace/runs/review-arms/baseline-2026-08-06/hygiene/fact-check.md` (7 verified, 1 stale)

This is a hygiene PR whose net effect is a security *improvement*: provider error bodies and LLM response text are removed from server logs, and `details` is removed from the SSE error payload. The findings below concern residuals the PR did not close and one contract-drift item; none are blocking.

## Trust Boundary Map

```
B1: [client HTTP request body]        → [route.ts POST validation]    → [callLlm / streamLlm]      (user's own source material)
B2: [provider error response body]    → [callLlm / streamLlm catch]   → [thrown Error .details]    (OpenRouter/Anthropic-controlled text)
B3: [server error state]              → [HTTP response body / SSE]     → [client]                   (egress to caller)
B4: [server error state]              → [console.error]                → [server logs on disk]      (egress to disk)
```

The diff hardens B4 (logs) and the SSE half of B3 (streaming path no longer forwards `details`). The residual concern is the non-streaming half of B3: the JSON HTTP error path still forwards provider-origin data (B2) to the caller. Note that B1 content is the caller's *own* input, so echoing it back to the same caller is low-risk by construction; B2 content is provider-controlled and is the more sensitive egress.

## Findings

#### Non-streaming HTTP error path still forwards the full, untruncated OpenRouter provider body to the client
**Severity:** Low
**Location:** `app/api/edit/artifact/route.ts:89-93`
**Boundary:** B2 → B3
**Move:** #3 (error path), #1 (trust boundary — egress asymmetry)
**Confidence:** Medium

The streaming path was hardened this diff to stop forwarding `details` over SSE (`streamLlm.ts:162`), and `callLlm.ts:182-185` explicitly reasons that the OpenRouter body "can echo parts of the request and we don't want it on disk." But the non-streaming consumer still surfaces that same body to the client verbatim: `return NextResponse.json({ error: err.message, details: err.details }, ...)`. Unlike the invalid-JSON branch (`route.ts:83`, which caps at `.slice(0, 500)`), `err.details` here is the **untruncated** provider error body (`callLlm.ts:187` throws with the full `errorBody`). Impact is bounded — the provider body is upstream-controlled rather than another user's data, and the caller is the request originator — but it is an information-disclosure asymmetry: the PR's own stated policy ("decide what, if anything, to surface") was applied to logs and SSE but not to this HTTP branch, and provider error bodies can carry rate-limit internals, model routing, or account-scoped hints. Legibility-target: reviewer decides whether the non-streaming path should match the streaming path's no-forward stance or at least truncate.
**Recommendation:** Decide the egress contract once and apply it to both transports — either drop `details` from the HTTP 502 body to match SSE, or truncate it (e.g., `err.details.slice(0, 500)`) as the sibling invalid-JSON branch already does.

#### `err.message` is still logged and forwarded; SDK error messages may embed provider body text
**Severity:** Informational
**Location:** `app/lib/llm/streamLlm.ts:157-162`; consumer `app/api/edit/artifact/route.ts:95-99`
**Boundary:** B2 → B3/B4
**Move:** #3 (error path)
**Confidence:** Low

The hardening removes `details` but keeps `message` in both the log and the SSE `error` event. For `OpenRouterError` and `errorWithDetails`, `message` is a controlled string (`OpenRouter API error: <status>`), so this is safe. The residual is the generic `err instanceof Error` path: an `@anthropic-ai/sdk` thrown error's `.message` can include the provider's error payload, which the diff's own rationale treats as request-echoing. This is pre-existing and low-likelihood (Anthropic error messages are typically structured, not raw request echoes), so it is noted rather than flagged for action. Legibility-target: reviewer aware that "message-only" is not a guarantee of zero request-content egress if SDK errors are verbose.
**Recommendation:** No change required; if belt-and-suspenders is wanted, normalize SDK errors to a fixed message before forwarding.

#### SSE protocol JSDoc still documents the removed `details` field (contract drift)
**Severity:** Informational
**Location:** `app/lib/llm/streamLlm.ts:71`
**Boundary:** B3 (contract, not a live crossing)
**Move:** N/A — documentation/contract alignment
**Confidence:** High

Per the fact-check (Claim 5, verdict: Stale), the protocol block still reads `event: error — { error: "message", details: "..." }` while the sole emit site (`streamLlm.ts:162`) now sends `{ error }` only. No security exposure — the doc over-promises a field that is *not* sent, so it cannot cause a leak — but the PR's stated intent explicitly includes "align the SSE error contract and its JSDoc," and this line is the one place that intent was not carried out. Legibility-target: reviewer sees the PR's own goal is not fully met; a client author trusting the doc would parse for an absent field.
**Recommendation:** Update the JSDoc to `event: error — { error: "message" }`.

## What Looks Good

- **Log hygiene (B4) is correct.** `route.ts:81`, `callLlm.ts:186`, and `streamLlm.ts:160` now emit length/status/message only; the response text and provider bodies no longer reach disk. This is the core intent and it is implemented soundly.
- **SSE egress (B3) tightened.** `details` is gone from the streaming `error` event (`streamLlm.ts:162`); `errorWithDetails` retains the property in-process only, correctly documented as opt-in.
- **Per-call client construction is a security positive (B-independent).** Replacing the `_anthropicClient` singleton with `makeAnthropicClient` (`callLlm.ts:14-16`) means an `ANTHROPIC_API_KEY` rotation takes effect on the next request without a redeploy — this shortens the window a compromised/rotated key stays live (move #6, secrets lifecycle). The added test (`callLlm.test.ts`) locks the behavior against a singleton regression.
- **No secrets in the diff.** API keys are read from `process.env` at call time and passed by value; none are logged or hardcoded.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Non-streaming HTTP error forwards untruncated provider body | Low | B2→B3 | `route.ts:89-93` | Medium |
| 2 | `err.message` egress may embed SDK provider body | Informational | B2→B3/B4 | `streamLlm.ts:157-162` | Low |
| 3 | Stale SSE `details` in protocol JSDoc | Informational | B3 | `streamLlm.ts:71` | High |

## Overall Assessment

The change improves security posture: it removes user source material and provider error bodies from logs and removes `details` from the SSE error payload, and the per-call client construction shortens key-rotation latency. No High/Critical issues, no escalation. The one substantive residual is an egress asymmetry — the non-streaming HTTP 502 path (`route.ts:89-93`) still forwards the full untruncated OpenRouter body to the client while the streaming path no longer does. It is fixable in place (drop or truncate `details`) and is the single most useful thing to reconcile so the "decide what to surface" policy is applied uniformly across both transports. The stale JSDoc is the PR's own stated goal left half-done and should be corrected in the same pass.
