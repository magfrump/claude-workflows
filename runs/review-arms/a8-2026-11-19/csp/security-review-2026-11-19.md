Commit: d90d6bb

# Security Review: strict CSP proxy (d86d2dc..d90d6bb)

**Scope:** `proxy.ts` (new), `app/layout.tsx`; context read: `app/lib/utils/exportGraph.ts`, `app/components/panels/GraphPanel.tsx:98-110`, `app/lib/utils/fileExtraction.ts:24-31`, `app/lib/utils/pdfPropositionParser.ts:441-447`, `app/components/features/output-editing/LatexRenderer.tsx`, every browser `fetch(` in `app/`, `app/api/**` response shapes
**Date:** 2026-11-19
**Based on:** merged code-fact-check report (k=3) `code-fact-check-report.md`, including r3's executed `next start` logs in `fc-r3-logs/` (`matcher.txt`, `root-headers.txt`)

No HALT escalation: none of the five escalation patterns matches. The reviewed repo has no constraints doc, so every attacker the diff exposes is in scope.

## Trust Boundary Map

```
B1 (new): [browser request: path S2 + headers S1] → [proxy matcher, proxy.ts:51-63]          → [document served with / without CSP]
B2 (new): [nonce S3, proxy.ts:37]                 → [response CSP header → router header copy → Next renderer] → [nonce attribute on <script> in HTML]
B3:       [LLM output S4, via /api JSON]          → [ReactMarkdown without rehype-raw; CSP as second layer]    → [DOM of the page]
B4 (new): [browser fetch call sites S5/S6]        → [connect-src 'self', proxy.ts:26]                          → [network / data: URLs]
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | Request headers `purpose`, `next-router-prefetch` | request-time | UNTRUSTED for the "apply CSP?" decision: any client sets them; browsers set `Purpose: prefetch` on some prefetches |
| S2 | Request path | request-time | UNTRUSTED for matcher routing |
| S3 | `crypto.randomUUID()` nonce | runtime-generated per request (CSPRNG) | trusted as a secret toward script-src, provided it is unpredictable and never reused |
| S4 | LLM output rendered by `LatexRenderer` | request-time, derived from user input | UNTRUSTED toward HTML/script sinks |
| S5 | `html-to-image` `data:` URL | client-generated | trusted content; it is a `data:` URL, which connect-src governs |
| S6 | Relative `/api/...` URLs in client code | code-constant | trusted (all sinks) |

What enters from outside is the request path and headers (B1), which decide whether the document gets a CSP at all, and LLM text (B3), which the CSP is meant to back up. The diff assumes that every request that renders a document the user will see passes the matcher, and that Next always gets the nonce (B2). The first assumption fails on a header any client controls (Finding 1). The second holds on self-hosted `next start` only through an undocumented router behaviour. When it fails, the app stops working rather than losing protection (Finding 2).

## Findings

#### 1. Any request carrying `Purpose: prefetch` gets the full HTML document with no CSP

**Severity:** Medium
**Location:** `proxy.ts:52-62`
**Boundary:** B1
**Move:** 11 (enumerate bypasses for every guardrail)
**Confidence:** High that the opt-out exists (r3 ran it: `fc-r3-logs/matcher.txt` records `purpose:prefetch -> HTTP/1.1 200 OK` with no `content-security-policy`, while `/` and `/foo` carry one). Low to Medium that an attacker can make a victim's browser use such a response for a real navigation.
**Legibility-target:** for-author

Evidence (`proxy.ts:55-62`):
```ts
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
```

Whether the proxy runs, and so whether the CSP exists, depends on request headers the client controls (S1). The `/` route still renders its HTML, so a request with `Purpose: prefetch` gets the same document with no policy. Browsers send this header on `<link rel=prefetch>` document prefetches. If that response is later used for the navigation (the prefetch cache, or a navigational prefetch the attacker triggers from their own page), the whole session runs with no CSP. That is exactly when the guardrail is supposed to matter: after an injection regression in B3. The reason given for the exemption ("burn a nonce on a request that may never paint") is not a security or performance cost, because a nonce is one `randomUUID` call. `next-router-prefetch: 1` is exempted the same way (r3 also got a CSP-less 200). Browsers never send that header on a top-level navigation, so only the `purpose` arm is reachable through a browser. Reachability depends on browser prefetch-cache behaviour for `Cache-Control: no-store` responses (`root-headers.txt`), which this review did not test.

**Recommendation:** Remove the `missing` exemptions so every matched request gets a CSP. If the per-request cost matters, still set a CSP on prefetch responses (with a fresh nonce) and skip only the extra work. A document response should never ship without the header.

#### 2. Next gets the nonce only through an undocumented response-to-request header copy; the documented pattern forwards the CSP itself

**Severity:** Low
**Location:** `proxy.ts:41-47`, `app/layout.tsx:26-30`
**Boundary:** B2
**Move:** 1 (trace the trust boundaries), with fact-check Claims 3, 11, 13 and escalation E1
**Confidence:** Medium
**Legibility-target:** for-author

Evidence (`proxy.ts:41-47`):
```ts
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

Next's renderer takes the script nonce from the request's `Content-Security-Policy` header. Next ignores `x-nonce`, and nothing in the app reads it (fact-check Claim 11). The proxy puts the CSP only on the response. On `next start` it still works because the router copies proxy response headers onto `req.headers` (`resolve-routes.js:443-446`, r3 executed: 15/15 scripts nonced). That is an internal side effect, not a contract, and it is unconfirmed on Vercel, which the commit body names as the deployment target. If the copy doesn't happen, the fault is availability, not exposure. Scripts render without a nonce, `'strict-dynamic'` blocks them all, and the app does not hydrate. So this does not weaken security. It goes wrong the safe way, and it is a real ship risk. The layout comment (`app/layout.tsx:28-30`) tells maintainers the wrong mechanism, so a future fix aimed at the comment's mechanism would not help.

**Recommendation:** Also set `requestHeaders.set("Content-Security-Policy", csp)`, which is the pattern Next documents, and drop or justify `x-nonce`. Rewrite the layout comment to say that Next reads the nonce from the request CSP header and that `headers()` keeps the HTML dynamic so each render gets that request's nonce.

#### 3. No `form-action`: under the rehype-raw regression the CSP is meant to catch, injected forms can still send data anywhere

**Severity:** Low
**Location:** `proxy.ts:20-30`
**Boundary:** B3
**Move:** 11
**Confidence:** High (`form-action` has no `default-src` fallback, per the CSP spec)
**Legibility-target:** for-author

Evidence (`proxy.ts:20-30`):
```ts
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
    "connect-src 'self'",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
  ];
```

The stated threat model (9b4e453 body) is LLM markdown rendered raw. In that state, `<script>`, inline handlers, `javascript:` URLs, `<base>`, `<object>` and external `<img>`/font beacons are blocked. A `<form action="https://attacker">` styled as a re-authentication or "paste your API key" prompt is not blocked. Neither is `<meta http-equiv="refresh">` navigation, which CSP doesn't cover anyway.

**Recommendation:** Add `form-action 'self'`. It costs nothing, since the app posts only to its own `/api` routes via `fetch`.

#### 4. No violation reporting, so the guardrail cannot "catch the regression" it exists for

**Severity:** Informational
**Location:** `proxy.ts:20-31`
**Boundary:** B3
**Move:** 3 (check the error path)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`proxy.ts:31`):
```ts
  return directives.join("; ");
```

There is no `report-to`/`report-uri`. A blocked injection, and every functional breakage this policy causes (Finding 5, and Finding 2 on Vercel), shows up only in the end user's devtools console. The commit's purpose ("CSP catches the regression...") needs a signal someone actually sees.

**Recommendation:** Add a `report-to` endpoint, even a minimal same-origin `/api/csp-report` that logs. Or ship first as `Content-Security-Policy-Report-Only` on the preview to collect violations before enforcing.

#### 5. `connect-src 'self'` breaks graph PNG export and Export All silently (E2); avoid "fixing" it by widening connect-src

**Severity:** Informational (mainly functional; the security interest is in how it gets fixed)
**Location:** `proxy.ts:26`, `app/lib/utils/exportGraph.ts:24`, `app/lib/utils/exportGraph.ts:37`
**Boundary:** B4
**Move:** 12 (sweep every call site)
**Confidence:** High (fact-check Claim 8, 3/3; `fetch` of a `data:` URL is governed by connect-src)
**Legibility-target:** for-author

Evidence (`app/lib/utils/exportGraph.ts:20-26`; excerpt ends :26, enclosing `downloadGraphAsPng` continues to :27 (read), and `graphToPngBlob` :30-39 has the same shape at :37):
```ts
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
  triggerDownload(blob, filename);
```

The rejected fetch is caught at `GraphPanel.tsx:105-106` (`console.error("[graph export]", err);`), so users see nothing happen. Adding `data:` to connect-src is low risk. The rushed fix to avoid is `connect-src *` or `https:`, which would reopen browser-side exfiltration (B4) for the injection scenario.

**Recommendation:** Use `html-to-image`'s `toBlob` (or decode the data URL without `fetch`) so connect-src stays `'self'`.

#### 6. pdf.js worker: no `worker-src`; the fallback is the strict script-src (E3)

**Severity:** Informational
**Location:** `proxy.ts:22`, `app/lib/utils/fileExtraction.ts:26-29`, `app/lib/utils/pdfPropositionParser.ts:443-446`
**Boundary:** B2
**Move:** 11
**Confidence:** Low (not executed; worker handling under `'strict-dynamic'` varies by browser)
**Legibility-target:** for-author

Evidence (`app/lib/utils/fileExtraction.ts:26-29`):
```ts
  pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
    "pdfjs-dist/build/pdf.worker.min.mjs",
    import.meta.url,
  ).toString();
```

Workers fall back to `script-src`, where `'strict-dynamic'` makes `'self'` ignored, so the same-origin worker URL may be refused. pdf.js can fall back to a main-thread "fake worker" through dynamic import. That keeps protection but may break or slow PDF upload. Either way, this weakens nothing.

**Recommendation:** Test PDF upload in a browser under the policy. If it's blocked, add an explicit `worker-src 'self' blob:` rather than relaxing `script-src`.

#### 7. `style-src 'unsafe-inline'` is justified with the wrong reason; it permits CSS injection in the regression scenario

**Severity:** Informational
**Location:** `proxy.ts:12-14`, `proxy.ts:23`
**Boundary:** B3
**Move:** 2 (implicit sanitization assumption)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence (`proxy.ts:12-14`):
```ts
 * Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening
 * to nonces would require rebuilding how Tailwind ships styles in dev and
 * SSR. Documented as a deliberate carve-out, not an oversight.
```

Tailwind v4 ships an external stylesheet (fact-check Claim 6). What actually needs inline styles is SSR `style=` attributes from React `style={{}}` props (for example `LatexRenderer.tsx:22,32`), KaTeX and React Flow. With raw HTML enabled, injected `<style>` could restyle or overlay the UI for phishing. External CSS beacons are constrained by `img-src`/`font-src`. A future maintainer who reads "Tailwind needs it" may keep or widen the carve-out for the wrong reason.

**Recommendation:** Correct the comment. If tightening is ever wanted, split it into `style-src-elem 'self' 'nonce-…'` plus `style-src-attr 'unsafe-inline'`.

#### 8. Matcher exclusion `(?!api` is a prefix test: any future page under `/api*` would ship without CSP

**Severity:** Informational
**Location:** `proxy.ts:57`
**Boundary:** B1
**Move:** 11
**Confidence:** High for the regex behaviour (fact-check Claim 12, 3/3). Not reachable today: `app/page.tsx` is the only page, and every `app/api/**` route returns JSON or SSE.
**Legibility-target:** for-author

Evidence (`proxy.ts:57`):
```ts
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

**Recommendation:** Anchor it as `(?!api/|api$|_next/static/|_next/image|favicon\.ico$)`.

#### 9. Comments misstate the runtime and the nonce plumbing

**Severity:** Informational
**Location:** `proxy.ts:35-36`, `proxy.ts:39-40`
**Boundary:** B2
**Move:** 2
**Confidence:** High (fact-check Claims 9, 11)
**Legibility-target:** for-author

Evidence (`proxy.ts:35-36`, `proxy.ts:39-40`):
```ts
  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
  // available in the Edge runtime that Next proxy runs in.
```
```ts
  // Forward the nonce to server components via a request header so layouts
  // can read it via `headers()` and pass it to <Script> tags they render.
```

The Next 16 proxy runs on Node.js. No layout reads `x-nonce` and no `<Script>` exists. These comments describe the security mechanism wrongly, which is the same kind of drift that breaks Finding 2's fix. The behaviour itself is unaffected.

**Recommendation:** Correct them alongside Finding 2.

#### 10. `next dev` likely needs `'unsafe-eval'`; risk of the policy being loosened for convenience

**Severity:** Informational
**Location:** `proxy.ts:22`
**Boundary:** B2
**Move:** 3
**Confidence:** Low (dev mode not executed in this review or by r3)
**Legibility-target:** for-author

Evidence (`proxy.ts:22`):
```ts
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```

React and Next dev tooling uses `eval`. If dev breaks, the easiest local fix is to add `'unsafe-eval'` unconditionally, which would then ship to production.

**Recommendation:** Add `'unsafe-eval'` only when `process.env.NODE_ENV === "development"`, and say so in the comment.

### Untested bypass candidates

- **Script gadgets under `'strict-dynamic'`:** any nonced bundle (react-markdown, reactflow, html-to-image, pdfjs, katex) that creates `<script>` elements from DOM- or data-derived URLs passes that trust on. No sweep of the bundled libraries for such gadgets was done.
- **Vercel / CDN static caching with a reused nonce:** a cached HTML response would reuse one nonce across users. Locally the response is `Cache-Control: private, no-cache, no-store` (`root-headers.txt`), but Vercel's edge was not exercised.
- **Browser reuse of a `Purpose: prefetch` response for navigation (Finding 1's reachability):** not exercised in a browser.
- **`next-router-prefetch: 1` response body type:** r3 recorded a CSP-less 200 but not whether the body is the HTML document or an RSC payload. Browsers do not send this header on navigations either way.
- **pdf.js worker under the policy (Finding 6):** not exercised.

Tested and cleared (traced statically): `Sec-Purpose: prefetch` (speculation rules) is not in the `missing` list, so those requests get CSP. `public/*.svg` passes the matcher and gets CSP. Unknown paths (`/foo`) get CSP (r3, executed). Inline event handlers and `javascript:` URLs are not permitted by the script-src at `proxy.ts:22`. `<base>` is constrained by `base-uri 'self'` (`proxy.ts:28`).

## Endorsement Claims

The CSP guardrail as a whole is **not** endorsed: it has untested bypass candidates (above). The claims below are atomic properties next to it.

- **Claim:** The nonce comes from `crypto.randomUUID()` (a CSPRNG with 122 random bits), is generated inside the per-request `proxy` function, and is base64-encoded into a character set valid for a `nonce-source`.
  **Location:** `proxy.ts:34-37`
  **Evidence:** read-static (plus r3's executed logs in `matcher.txt`, showing a distinct nonce on each of the `/`, `/foo` and RSC requests)
  **Verified:** read `proxy.ts:34-49` in full; read the three nonce values in `fc-r3-logs/matcher.txt`
  **Not verified:** that no cache layer (Vercel edge) serves one rendered nonce to several requests
  **route: code-fact-check**

- **Claim:** The emitted script-src contains neither `'unsafe-inline'` nor `'unsafe-eval'`, and the policy sets `object-src 'none'`, `base-uri 'self'` and `frame-ancestors 'none'`.
  **Location:** `proxy.ts:20-30`
  **Evidence:** read-static (the header string matches r3's `root-headers.txt`)
  **Verified:** read the directive array and compared it against the header r3 captured from `next start`
  **Not verified:** the header as served by the Vercel preview
  **route: code-fact-check**

- **Claim:** The only HTML sink for LLM output found in `app/` is `ReactMarkdown` in `LatexRenderer.tsx:34-39`, configured with `rehypeKatex` only (no `rehype-raw`). A grep for `dangerouslySetInnerHTML`/`innerHTML`/`eval(`/`new Function` in `app/` found no matches.
  **Location:** `app/components/features/output-editing/LatexRenderer.tsx:9-10`, `app/components/features/output-editing/LatexRenderer.tsx:34-39`
  **Evidence:** read-static
  **Verified:** read the whole `LatexRenderer.tsx` and the grep output
  **Not verified:** markdown or HTML rendering inside third-party components (reactflow node labels, KaTeX output under `trust` defaults)
  **route: code-fact-check**

## Primitive sweep

Primitive: browser-side URL fetch (governed by connect-src, B4)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `app/lib/utils/exportGraph.ts:24` | S5 `data:` URL | connect-src `'self'` blocks it | Finding 5 |
| `app/lib/utils/exportGraph.ts:37` | S5 `data:` URL | connect-src `'self'` blocks it | Finding 5 |
| `app/lib/formalization/api.ts:10` | S6 `/api/...` url parameter (callers pass route constants) | same-origin | cleared: `'self'` |
| `app/lib/formalization/api.ts:38` | S6 | same-origin | cleared: `'self'` |
| `app/lib/formalization/api.ts:104` | S6 `/api/verification/lean` | same-origin | cleared |
| `app/hooks/useAnalytics.ts:11`, `:30` | S6 `/api/analytics` | same-origin | cleared |
| `app/components/features/context-input/ContextInput.tsx:25` | S6 | same-origin | cleared |
| `app/components/features/lean-display/LeanCodeDisplay.tsx:88` | S6 | same-origin | cleared |
| `app/lib/llm/callLlm.ts:164`, `app/lib/llm/streamLlm.ts:249` | OpenRouter constant | server-only (imports Node `crypto`; called from `app/api/**` routes) | cleared: not browser-side, CSP does not apply |
| `app/api/verification/lean/route.ts:21` | `LEAN_VERIFIER_URL` (deploy-time env) | server-side | cleared: CSP does not apply |

Primitive: HTML interpolation (B3)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `app/components/features/output-editing/LatexRenderer.tsx:34-39` | S4 LLM output | react-markdown default escaping, no rehype-raw; CSP as second layer | cleared for today; the CSP gaps under the regression scenario are Findings 1, 3, 7 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `Purpose: prefetch` request gets HTML with no CSP | Medium | B1 | `proxy.ts:52-62` | High (exists) / Low-Med (browser reachability) |
| 2 | Nonce reaches Next only via an undocumented header copy; fails closed | Low | B2 | `proxy.ts:41-47` | Medium |
| 3 | No `form-action` | Low | B3 | `proxy.ts:20-30` | High |
| 4 | No violation reporting | Informational | B3 | `proxy.ts:20-31` | High |
| 5 | connect-src breaks PNG/zip export; do not widen it | Informational | B4 | `exportGraph.ts:24,37` | High |
| 6 | pdf.js worker with no `worker-src` | Informational | B2 | `fileExtraction.ts:26-29` | Low |
| 7 | `style-src 'unsafe-inline'` misjustified | Informational | B3 | `proxy.ts:12-14,23` | Medium |
| 8 | `(?!api` prefix exclusion | Informational | B1 | `proxy.ts:57` | High |
| 9 | Runtime and x-nonce comments wrong | Informational | B2 | `proxy.ts:35-36,39-40` | High |
| 10 | Dev mode may need `'unsafe-eval'` | Informational | B2 | `proxy.ts:22` | Low |

## Overall Assessment

The change makes nothing less safe. Every failure found except Finding 1 goes wrong the safe way, by breaking functionality (export, possibly PDF upload, hydration on Vercel) rather than opening a hole. The policy text is reasonably strict. The issues can be fixed in place and do not point to an architectural problem. The most important one is Finding 1: whether a document gets a CSP must not depend on a request header the client controls. Remove the `missing` exemptions. Close behind it, on availability rather than security: forward the CSP on the request headers (Finding 2) and verify on the actual Vercel preview, because the self-hosted pass depends on an undocumented router copy. No findings beyond these within the code paths read; endorsement claims pending execution verification.

## Escalation responses

- **E1** (`proxy.ts:41-48`): addressed as Finding 2. It goes wrong the safe way (the app breaks, protection does not drop), so Low on security. Ship-blocking only if Vercel does not mirror headers, which still needs a run on the preview.
- **E2** (`exportGraph.ts:24,37`): addressed as Finding 5. Functional break; the security concern is the shape of the fix.
- **E3** (`fileExtraction.ts:26-29`, `pdfPropositionParser.ts:443-446`): addressed as Finding 6. No weakening; possible functional break, needs a browser test.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the security-reviewer skill.
- Answered: yes
- Out of scope: browser and Vercel execution (no network; the prefetch-cache reachability for Finding 1, the Vercel header mirroring for Finding 2 and the pdf.js worker for Finding 6 are not exercised); no supply-chain review (no manifest change in the diff)
- Escalate: (1) run the Vercel preview to confirm nonce delivery and that `Purpose: prefetch` responses lack CSP there; (2) a browser test of graph export, Export All and PDF upload under the policy; (3) E4 (the OpenAlex mention with no code) remains with the orchestrator, not security-relevant
- Decisions I made: rated E1 Low rather than Medium, because it goes wrong the safe way and the floor rule covers mechanisms that violate a security property, not availability; withheld endorsement of the CSP guardrail as a whole under move 11, endorsing only atomic properties next to it
