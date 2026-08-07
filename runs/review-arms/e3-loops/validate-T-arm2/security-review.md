# Security Review — validate-T arm2 (99e1229, CSP + iter-1 fixes)

Commit: 99e1229
**User goal:** Validate decision 031 tier policy T — confirm arm 2's full-review pass 2 of 99e1229 has 0 red so the loop terminates at 2 full passes.
**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-validate-arm2` (detached at 99e1229) — 5 files: `proxy.ts`, `proxy.test.ts`, `app/layout.tsx`, `app/lib/utils/exportGraph.ts`, `app/lib/utils/exportGraph.test.ts`.
**Date:** 2026-08-06
**Based on:** Merged fact-check (0 code-red; comment-only nits) supplied in task preamble.

This state is the fix for four prior full-review blockers (R1 nonce delivery, R2 connect-src export break, R3 untested policy, R4 discarded `await headers()`). This review verifies those are closed and hunts for anything genuinely NEW. The known-open-by-design ambers (missing `form-action`, prefetch matcher skip, matcher prefix anchoring, enforce-only rollout, `/api` no `nosniff`, `style-src 'unsafe-inline'` carve-out) are pre-existing design tradeoffs and are NOT re-raised as red.

## Trust Boundary Map

```
B1: [browser HTTP request] → [proxy(): fresh nonce + buildCsp() sets req+resp CSP] → [Next render / server components]  (new)
B2: [client x-nonce header] → [proxy(): requestHeaders.set overwrite]              → [server components]                (new)
B3: [in-process toPng() data: URL] → [dataUrlToBlob(): atob / decodeURIComponent]  → [Blob → triggerDownload]           (new)
```

B1 is the primary boundary: every non-excluded page navigation gets a per-request CSP with a nonce on both the forwarded request header (so Next can stamp bootstrap `<script>` tags) and the response header (so the browser enforces). B2 is the attacker-supplied-`x-nonce` case — the proxy overwrites rather than appends, so a client cannot smuggle its own nonce into a server component. B3 is entirely client-side and consumes only app-generated `data:` URLs; no network-crossing input reaches it.

## Blocker closure verification

- **R1 (nonce delivery)** — CLOSED. `proxy.ts:39` sets `Content-Security-Policy` on `requestHeaders` (the forwarded request) and `proxy.ts:47` sets the identical policy on the response. `proxy.test.ts` asserts both, and that the forwarded CSP contains `'nonce-<x-nonce>'` — the wiring falsifier. Evidence (`proxy.ts`): `requestHeaders.set("Content-Security-Policy", csp);` … `response.headers.set("Content-Security-Policy", csp);`.
- **R2 (connect-src export break)** — CLOSED. `exportGraph.ts` no longer calls `fetch(dataUrl)`; both `downloadGraphAsPng` and `graphToPngBlob` now use `dataUrlToBlob(dataUrl)`. `connect-src 'self'` stays tight. No remaining `fetch(` in the file.
- **R3 (untested policy)** — CLOSED. `buildCsp` is exported and `proxy.test.ts` has 8 tests including the directive-set assertion and the request-forwarding falsifier; `exportGraph.test.ts` adds 5 tests for `dataUrlToBlob`.
- **R4 (discarded `await headers()`)** — CLOSED. `app/layout.tsx` uses `export const dynamic = "force-dynamic"` and reads no nonce directly; there is no `headers()` call whose result is discarded. Next 16.2.4 uses `proxy.ts` (the renamed Middleware); no stale `middleware.ts` exists.

## Findings

No Critical, High, or Medium findings. Two Informational (defense-in-depth only).

#### Non-base64 `data:` branch can throw on malformed percent-encoding

**Severity:** Informational
**Location:** `app/lib/utils/exportGraph.ts:32` (`decodeURIComponent(payload)`)
**Boundary:** B3
**Move:** #3 (error path)
**Confidence:** High

`decodeURIComponent` throws `URIError` on a malformed `%` sequence, which would propagate out of `dataUrlToBlob`. In practice the only inputs are `toPng()` outputs, which are always `;base64` and never reach this branch, so this is not exploitable — the sole external-ish caller path is app-internal. Noting only because the function is now exported and could be reused with less-controlled input later.

**Recommendation:** No action required for this diff. If `dataUrlToBlob` is later exposed to untrusted `data:` strings, wrap the decode in a try/catch that rethrows a typed error.

#### Nonce derived via base64-of-UUID rather than raw random bytes

**Severity:** Informational
**Location:** `proxy.ts:35`
**Boundary:** B1
**Move:** #9 (cryptographic choices)
**Confidence:** High

`Buffer.from(crypto.randomUUID()).toString("base64")` yields a CSP nonce backed by a v4 UUID's 122 bits of CSPRNG entropy — comfortably above the practical unpredictability bar for a per-request nonce, and `crypto.randomUUID()` is a cryptographic source (not `Math.random()`). The base64-of-the-UUID-string spelling is slightly unusual (it encodes the 36-char textual UUID, not the 16 raw bytes) but does not reduce entropy or produce CSP-invalid characters. Not a weakness.

**Recommendation:** Optional cosmetic simplification: `crypto.randomBytes(16).toString("base64")` (or `randomUUID()` used directly) expresses the same intent more conventionally. No security change.

## What Looks Good

- **Nonce delivered on both request and response headers** with identical policy — the exact fix R1 required, and the `'strict-dynamic'` + `'nonce-'` pairing means un-nonced injected scripts cannot execute even if markdown sanitization is bypassed.
- **`x-nonce` is overwritten, not appended** (`proxy.ts:44`), closing the client-supplied-nonce smuggling vector; `proxy.test.ts` has an explicit falsifier ("overwrites a client-supplied x-nonce").
- **`connect-src 'self'` preserved** by decoding `data:` URLs in-process instead of widening the directive for an export helper — the tradeoff is documented inline.
- **Fresh nonce per request** from a CSPRNG, asserted by the "issues a fresh nonce per request" test.
- **Tight baseline directives**: `default-src 'self'`, `frame-ancestors 'none'` (clickjacking), `object-src 'none'`, `base-uri 'self'` (base-tag injection) — all asserted by the directive-set test.
- **Carve-outs are documented as deliberate** (`style-src 'unsafe-inline'` for Tailwind/KaTeX/reactflow), not silent, so reviewers can see the residual risk.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Non-base64 branch throws on malformed percent-encoding | Informational | B3 | `exportGraph.ts:32` | High |
| 2 | Nonce as base64-of-UUID vs raw random bytes | Informational | B1 | `proxy.ts:35` | High |

## Overall Assessment

Strong security posture. All four prior blockers (R1–R4) are genuinely closed, each with a corresponding test that would fail if the fix regressed — the CSP nonce now reaches the document on the forwarded request header, the export path no longer trips `connect-src`, the policy is unit-tested including a wiring falsifier, and the layout renders per-request without a discarded `headers()` call. No new Critical/High/Medium issue is introduced by the fixes. The only findings are two Informational defense-in-depth notes on code that consumes app-internal input. The known-open ambers remain open by design and are out of scope for red. Nothing here blocks; the single most useful (optional) follow-up is documenting the enforce-only rollout status, which is already an accepted amber.

## Goal-Alignment Note

The goal is to confirm 0 red for full-review pass 2 so the tier-policy-T loop terminates at 2 full passes. This review finds **0 Critical, 0 High, 0 Medium** — i.e., 0 red. The four blockers that produced red in the prior pass are verified closed with regression tests. Only Informational findings remain, which do not count as red under any reasonable red/amber/green mapping. This pass therefore supports loop termination at 2 full passes.
