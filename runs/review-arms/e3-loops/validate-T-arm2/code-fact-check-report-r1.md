# Code Fact-Check Report

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-validate-arm2` (detached, ancestors of HEAD only)
**Commit:** 99e1229 (`fix: address full-review blockers R1-R4 (e3 arm2 iter1)`)
**Skill:** code-fact-check — fresh independent draw (T-isolating; k unchanged)
**Files reviewed:** `proxy.ts`, `proxy.test.ts`, `app/layout.tsx`, `app/lib/utils/exportGraph.ts`, `app/lib/utils/exportGraph.test.ts`
**Date:** 2026-08-06

---

## Claim 1: proxy.ts forwards the CSP on the *request* header so Next reads the nonce there

**Source (`proxy.ts:36-46`):**
> "Next.js reads the nonce off the *request* `Content-Security-Policy` header during render and stamps it onto the bootstrap <script> tags it emits. Setting it only on the response is not enough..."

Code sets `requestHeaders.set("Content-Security-Policy", csp)` on a `new Headers(request.headers)`, passes it via `NextResponse.next({ request: { headers: requestHeaders } })`, and *also* sets the same `csp` on `response.headers`. Both headers carry the same policy string (single `buildCsp(nonce)` value). The mechanism the comment describes (Next reading the nonce off the request CSP header) is the documented Next.js nonce-with-CSP flow; the code delivers the nonce exactly where Next reads it.

**Verdict:** Verified · **Confidence:** High (quoted evidence; code matches comment). The runtime dependency on Next's request-CSP nonce extraction is a framework behavior not executed here, but the wiring is correct for it.

## Claim 2: exportGraph uses `dataUrlToBlob` (no `data:` fetch); decode correct; both call sites replaced

**Source (`exportGraph.ts:16-21`):**
> "`fetch(dataUrl)` ... is a `connect-src` fetch, and the app's CSP sets `connect-src 'self'`, which refuses `data:`. Decoding here keeps that directive tight..."

- Decoder is correct: splits on first comma, validates `data:` prefix, detects `;base64`, strips media-type params via `.split(";")[0]`, base64-decodes via `atob`→`Uint8Array`, percent-decodes non-base64 via `decodeURIComponent`. Tests confirm base64 (GIF89a), non-UTF-8 bytes (`0xff 0xfe 0xfd`), percent-encoding, param-dropping, and non-`data:` rejection.
- Both former `fetch(dataUrl)` sites replaced: `downloadGraphAsPng` now calls `triggerDownload(dataUrlToBlob(dataUrl), ...)`; `graphToPngBlob` returns `dataUrlToBlob(dataUrl)`.
- No `await fetch(dataUrl)` / `fetch(res)` remains anywhere. The only `fetch(dataUrl)` string left in the file is inside the docstring (`exportGraph.ts:19`), not live code.

**Verdict:** Verified · **Confidence:** High (quoted evidence).

## Claim 3: proxy.test.ts assertions match; the CSP-forwarding test genuinely falsifies broken wiring

**Source (commit body):** "proxy.test.ts covers the directive set, nonce presence on script-src, the style-src carve-out, per-request freshness, x-nonce overwrite-not-append, and ... that the CSP is forwarded on the request. That last assertion fails against the pre-R1 wiring..."

- `forwardedRequestHeader` reads `x-middleware-override-headers` + `x-middleware-request-<name>` — Next's real encoding of forwarded request headers on a `NextResponse.next({request})`. This is the only unit-test observable for request-header forwarding.
- The "forwards the same CSP on the request" test asserts `forwarded` is non-null and equals the response CSP. Against pre-R1 wiring (which set CSP only on the response — see Claim 7 / commit 9b4e453), `content-security-policy` would be absent from the forwarded request headers, so `forwardedRequestHeader` returns null and the test fails. **It genuinely falsifies the broken wiring.**
- Assertion names/coverage all present: directive set (8 keys + values), nonce+`'strict-dynamic'` on script-src, style-src `'unsafe-inline'`, per-request freshness, x-nonce overwrite (asserts forwarded x-nonce does not contain the attacker value; code uses `.set()` = overwrite).

**Verdict:** Verified · **Confidence:** High.

## Claim 4: layout `export const dynamic = "force-dynamic"` with an accurate comment

**Source (commit body R4 + `app/layout.tsx:21-27`):** "Replaced with `export const dynamic = \"force-dynamic\"` ... plus a comment that survives R1's correction."

Current `app/layout.tsx` contains `export const dynamic = "force-dynamic";` and the comment: "Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) ... so nothing here reads it directly." No `headers()` call remains in the layout (grep: none) — consistent with the comment's claim that the layout reads nothing. The force-dynamic mechanism (opt out of static prerender so per-request nonces are not baked in) is the correct Next.js directive for the stated goal. Note: the cumulative `d86d2dc..HEAD` diff shows layout gaining these 7 lines only (the "discarded `await headers()`" the commit describes replacing existed in the *intermediate* arm state d90d6bb, not at base d86d2dc) — the commit's narrative is relative to the prior arm, not the diff base; the *end state* is as described.

**Verdict:** Verified · **Confidence:** High (quoted evidence).

## Claim 5: `connect-src 'self'` docstring — external calls are server-to-server

**Source (`proxy.ts:14-15`):**
> "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

Re-enumeration of client (browser) network calls: every browser-side `fetch`/`fetchApi`/`fetchStreamingApi` targets a same-origin `/api/*` route (ContextInput, LeanCodeDisplay, useAnalytics, formalization/api.ts, panels, hooks). The third-party origins — `OPENROUTER_API_URL` (`callLlm.ts`, `streamLlm.ts`) and `LEAN_VERIFIER_URL` (`api/verification/lean/route.ts`) — are reached only from server API routes (those modules import Node `crypto`/`@anthropic-ai/sdk` and are imported exclusively by `app/api/**/route.ts` and server-side formalization helpers). So `connect-src 'self'` does not break any browser call. **However, "OpenAlex" does not appear anywhere in the codebase** (grep: 0 hits) — the enumeration names a service that isn't there.

**Verdict:** Mostly accurate · **Confidence:** High. The substantive claim (all external calls server-to-server → `connect-src 'self'` safe) holds and the **code is correct**; the **comment only** is imprecise (stale/aspirational service list). Comment-only, not code-wrong.

## Claim 6: Remaining feature-commit comment/doc claims

- **Runtime name — "crypto.randomUUID and Buffer are both available in the Edge runtime" (`proxy.ts:32-33`):** Both are available in Next's Edge runtime; `Buffer` availability in Edge is Next-provided. Verdict: Mostly accurate · Medium (framework-runtime claim not executed here). Comment-only; code uses both and functions in the Node test runtime regardless.
- **style-src `'unsafe-inline'` rationale:** `proxy.ts` cites Tailwind v4; `proxy.test.ts:61-62` cites "React style={} attributes, reactflow's inline transforms and KaTeX." Both are plausible justifications for the same carve-out; they differ in *which* consumers they name but agree on the directive. Verdict: Verified (the carve-out exists and is exercised by the test) · High. Comment-only divergence in stated rationale, not a code defect.
- **x-nonce overwrite-not-append (`proxy.ts:41-42`):** "Overwrite (not append) so a client-supplied x-nonce cannot be smuggled through." `Headers.set()` overwrites; test confirms attacker value is dropped. Verdict: Verified · High.
- **connect-src vendor enumeration:** see Claim 5 (OpenAlex absent).

## Claim 7: Commit-message claims

- **99e1229 "234 tests pass (was 221)" (+13):** New tests added = 8 (`proxy.test.ts`) + 5 (`exportGraph.test.ts`) = 13, matching the stated delta exactly. Absolute counts and the `tsc`/`lint`-clean claims cannot be executed here — `node_modules` is not installed in this worktree. Verdict: Mostly accurate · Medium (the +13 delta is corroborated by static test-case count; absolute 234/221 and tsc/lint results are Unverifiable by execution but internally consistent).
- **99e1229 R1/R2/R3/R4 dispositions:** each corroborated by Claims 1-4 above. Verdict: Verified · High.
- **9b4e453 (already-merged feature commit) verification claim — "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates":** At 9b4e453 the proxy set `x-nonce` on the request headers but set `Content-Security-Policy` **only on the response** (`git show 9b4e453:proxy.ts:42-48`), never on the forwarded request header. Since Next reads the nonce off the *request* CSP header (the exact defect R1 later fixed), Next would **not** apply the per-request nonce to its bootstrap scripts. The commit's verification claim was therefore **false at the time it was written**. Per the task's LOOP-OWNER OVERRIDE, this is **immutable-history** (routes to the override log), **not** a fresh finding.

---

## Claims Requiring Attention

| # | Claim | Verdict | Code-wrong or comment-only |
|---|-------|---------|----------------------------|
| 5 | `connect-src` docstring enumerates "OpenAlex", which does not exist in the codebase | Mostly accurate | **Comment-only** — code (`connect-src 'self'`) is correct |
| 7 | 9b4e453 "Next applies the nonce to every `<script>` tag" — false at that commit (CSP set only on response) | Incorrect (immutable-history / override log, not fresh) | Was **code-wrong at 9b4e453**; already fixed by R1 in 99e1229. Not a fresh finding. |
| 7 | 99e1229 absolute "234/234 pass, tsc/lint clean" | Unverifiable (by execution) | N/A — no `node_modules`; +13 delta is corroborated |

No fresh Incorrect finding exists in the current worktree state (99e1229). The only Incorrect claim is the historical 9b4e453 verification statement, which the override rule classifies as immutable-history.

## Goal-Alignment Note
- **Answered:** All rich-brief items (1-7) checked against code at 99e1229. proxy.ts delivers the nonce on the request header where Next reads it (Claim 1); exportGraph's decoder is correct with both call sites converted and no residual `data:` fetch (Claim 2); the CSP-forwarding test genuinely falsifies broken wiring (Claim 3); layout `force-dynamic` + comment are accurate (Claim 4); `connect-src 'self'` is safe for all browser calls (Claim 5). This is a fresh, independent draw. Net: **zero fresh red/Incorrect findings** in the reviewed state — consistent with decision 031's tier policy T expectation that arm 2's full-review pass 2 reaches 0-red and the loop terminates at 2 full passes.
- **Out of scope:** Whether the loop *should* terminate under T (that is the loop-owner's policy determination, informed by this 0-fresh-red result, not a fact-check verdict); amber/green findings deferred by the commit; other worktrees / e1 / prior csp-arm2 artifacts (per historical rule).
- **Escalate:** One immutable-history item — 9b4e453's false verification claim ("Next applies the nonce to every `<script>` tag") — routes to the override log, not the fresh-finding count. Absolute test/tsc/lint verification (234/234, clean) is Unverifiable here because `node_modules` is absent; the +13 test-count delta is statically corroborated.
