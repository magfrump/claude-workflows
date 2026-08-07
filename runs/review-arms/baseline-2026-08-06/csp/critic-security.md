Commit: d90d6bb
# Security Review — CSP proxy + per-request nonce (branch diff d86d2dc..d90d6bb)

**Scope:** `proxy.ts` (new), `app/layout.tsx` (static-rendering opt-out). Cross-file context read: `app/lib/utils/exportGraph.ts`, `app/lib/utils/exportAll.ts`, `app/components/panels/GraphPanel.tsx`, `app/lib/llm/callLlm.ts`, `app/lib/llm/streamLlm.ts`, `app/lib/utils/pdfPropositionParser.ts`, client fetch sites under `app/`.
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/csp/fact-check.md` (Claims 2, 6, 9 are load-bearing here).

No escalation (HALT) patterns matched: this PR *adds* a security header and introduces no injection, auth bypass, plaintext secret, or disabled-TLS path. The findings below are about the added control being **ineffective and likely to be weakened**, not about a newly exploitable hole.

## Trust Boundary Map

```
B1: [attacker HTML via markdown/DOM] → [script-src nonce + 'strict-dynamic'] → [script executes in browser]   (new)
B2: [proxy per-request nonce]        → [x-nonce on REQUEST hdr / CSP on RESPONSE hdr] → [Next bootstrap <script> tagging]  (new)
B3: [client export: toPng data: URL] → [fetch() governed by connect-src 'self'] → [Blob download]
```

B1 is the protection this PR intends to add (block injected scripts). B2 is the nonce-delivery mechanism that B1 depends on — and it is mis-wired. B3 is an existing same-origin-assumption path that the new `connect-src 'self'` now constrains. Every finding below crosses one of these.

## Findings

#### CSP nonce is never delivered to Next.js; 'strict-dynamic' blocks the app's own scripts, so the control is non-functional and its natural fix is a security regression
**Severity:** Medium
**Location:** `proxy.ts:22`, `proxy.ts:41-47`; `app/layout.tsx:27-31`
**Boundary:** B2 (feeds B1)
**Move:** #1 trace trust boundaries / #3 check the error path (what happens when the control "fails open" for the developer)
**Confidence:** High (mechanism); Medium (exact browser-blank vs. partial-render outcome)

Next.js auto-tags its bootstrap/hydration `<script>` elements only when the nonce is present on the **request** `Content-Security-Policy` header passed into `NextResponse.next({ request: { headers } })` (fact-check Claim 2). This proxy sets the CSP on the **response** only and forwards a separate `x-nonce` on the request — it never places a CSP string on the request headers:

```ts
// proxy.ts:41-47
const requestHeaders = new Headers(request.headers);
requestHeaders.set("x-nonce", nonce);
const response = NextResponse.next({ request: { headers: requestHeaders } });
response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

Because `script-src` carries `'strict-dynamic'` (`proxy.ts:22`), supporting browsers **ignore `'self'`** and admit only nonce/hash-tagged scripts plus what they load. Next's own `/_next/*` scripts will therefore be untagged and blocked — the SPA does not hydrate. The security consequence is not the outage itself but the remediation gradient: the fastest way to "make the site work again" is to drop `'strict-dynamic'` and add `'unsafe-inline'`/`'self'` to `script-src`, which nullifies the XSS protection the comment (`proxy.ts:7-10`) claims. The PR ships a control that is both inert as written and biased toward being loosened rather than fixed. The correct wiring is `requestHeaders.set("Content-Security-Policy", buildCsp(nonce))` before `NextResponse.next`, so Next tags its scripts from the request-side CSP.

**Recommendation:** Set the CSP on the **request** headers (not just the response) so Next's nonce auto-tagging engages; keep `'strict-dynamic'`. Verify in a browser that `/_next/*` scripts carry the nonce and load before merging — do not resolve a broken CSP by adding `'unsafe-inline'` to `script-src`.

#### connect-src 'self' is insufficient: browser code fetches a `data:` URL during graph/PNG export, which CSP blocks
**Severity:** Medium
**Location:** `app/lib/utils/exportGraph.ts:24`, `:37`; reached from `app/components/panels/GraphPanel.tsx:102-104` and `app/lib/utils/exportAll.ts:64-65`; policy at `proxy.ts:26`
**Boundary:** B3
**Move:** #2 implicit assumption (the "all browser fetches are same-origin" premise)
**Confidence:** Medium (per CSP spec `fetch()` to `data:` is governed by `connect-src`; blocked unless `data:` is listed — some engines have historically varied)

The comment asserts `connect-src 'self'` is sufficient "because ... calls are server-to-server" (`proxy.ts:16-17`). That premise is incomplete: client-side export code issues `await fetch(dataUrl)` where `dataUrl` is a `data:image/png;base64,...` produced by `toPng`, to reconvert it to a Blob:

```ts
// exportGraph.ts:20-25
const dataUrl = await toPng(viewportElement, { pixelRatio: 2, backgroundColor: EXPORT_BG });
const res = await fetch(dataUrl);
const blob = await res.blob();
```

`data:` is not `'self'`, so `connect-src 'self'` blocks this fetch — breaking "Download graph as PNG" and "Export All" (zip). Note `img-src` was correctly widened to `data: blob:` (`proxy.ts:24`) but `connect-src` was not, so the graph *renders* yet *export* fails. As with the finding above, the risk is that a developer un-blocks export by adding `data:`/`blob:` to `connect-src`, widening the exfiltration surface CSP is meant to constrain.

**Recommendation:** Fix the code, not the policy: replace `fetch(dataUrl)` with a direct base64→Blob decode (or `canvas.toBlob()` / `html-to-image`'s `toBlob`) so no network fetch of a `data:` URL is needed, keeping `connect-src 'self'` intact. If a policy change is unavoidable, scope it to `connect-src 'self' data:` and document why.

#### `x-nonce` request header is dead plumbing — forwarded but never consumed
**Severity:** Low
**Location:** `proxy.ts:42`; disclaimed at `app/layout.tsx:30`
**Boundary:** B2
**Move:** #1 (boundary that carries a security token to no consumer)
**Confidence:** High

`x-nonce` is set on the forwarded request (`proxy.ts:42`) but no layout or component reads it, and there are no `next/script`/`<Script>` usages in the app (fact-check Claim 9; confirmed — only match for `x-nonce` in `app/` is the disclaiming comment at `layout.tsx:30`). This is not itself exploitable, but it is a false signal: it reads as "nonce propagation is wired up" when nothing propagates. Combined with the top finding, a future maintainer may "consume" `x-nonce` in a `<Script nonce>` and still be broken, because the real gap is the missing request-side CSP header, not a missing reader.

**Recommendation:** Either delete the `x-nonce` forwarding (Next's auto-tagging needs the request CSP header, not `x-nonce`), or, if kept for app-authored inline scripts, pair it with the request-side CSP fix and add an actual consumer. Update the `layout.tsx:28-30` comment, which currently misstates that Next tags from the response header.

#### `style-src 'unsafe-inline'` retains an inline-style injection surface (documented carve-out)
**Severity:** Informational
**Location:** `proxy.ts:23`
**Boundary:** B1
**Move:** #1
**Confidence:** High

`'unsafe-inline'` for styles is a deliberate, documented Tailwind v4 concession (`proxy.ts:12-14`) and is a common, accepted tradeoff. Flagged only for completeness: it leaves CSS-injection vectors (e.g., style-based data exfiltration via attribute selectors) unmitigated. No action required for this PR; revisit if styles ever carry untrusted content.

## What Looks Good

- `object-src 'none'`, `base-uri 'self'`, `frame-ancestors 'none'`, `default-src 'self'` are all correct, high-value directives.
- `connect-src 'self'` correctly reflects that all LLM egress (Anthropic/OpenRouter) is server-side: `callLlm.ts`/`streamLlm.ts` fetch `OPENROUTER_API_URL` only from API routes gated on server-only env vars; browser fetches target `/api/*` (verified). The only gap is the `data:` export path (finding above), not third-party hosts.
- `img-src 'self' data: blob:` correctly anticipates the generated-image/data-URL rendering path.
- pdf.js worker is loaded from a bundled same-origin asset via `new URL("pdfjs-dist/build/pdf.worker.min.mjs", import.meta.url)` (`pdfPropositionParser.ts:443-444`); `worker-src` is unspecified and falls back through `child-src` to `default-src 'self'`, which permits the same-origin worker. Not a finding, but worth an explicit `worker-src 'self'` for legibility if worker loading regresses.
- Per-request nonce generation itself is sound (`crypto.randomUUID`, fresh each call) — the defect is delivery, not generation.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Nonce never on request CSP header → strict-dynamic blocks Next's scripts; control inert, fix path weakens it | Medium | B2 | `proxy.ts:41-47`, `:22` | High |
| 2 | connect-src 'self' blocks client `fetch(data: URL)` in graph export | Medium | B3 | `exportGraph.ts:24,37` | Medium |
| 3 | `x-nonce` forwarded but never consumed (dead plumbing / false signal) | Low | B2 | `proxy.ts:42` | High |
| 4 | `style-src 'unsafe-inline'` inline-style surface (documented carve-out) | Informational | B1 | `proxy.ts:23` | High |

## Overall Assessment

The direction is right and the directive set is mostly well-chosen, but the two Medium findings mean the change does not deliver the protection it advertises: the nonce is generated but never routed to where Next.js reads it, so `'strict-dynamic'` will block the app's own scripts, and `connect-src 'self'` breaks in-browser graph export. Neither is an exploitable vulnerability — this PR is net-neutral-to-positive on attack surface — but both create pressure to "fix" by loosening the policy (`'unsafe-inline'` on scripts, `data:` on connect-src), which would convert a well-intentioned hardening into a false sense of security. The single most important thing to address: set the CSP on the **request** headers so Next's nonce auto-tagging works and the app actually runs under the intended `'strict-dynamic'` policy; verify in a browser before merge. Both fixes are in-place; no architectural rework needed.
