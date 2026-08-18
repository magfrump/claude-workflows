# Code Fact-Check Report

**Commit:** d90d6bb
**Repository:** /workspace/external/cc-review-eval/mfc-csp
**Scope:** `git diff d86d2dc...HEAD` — `app/layout.tsx`, `proxy.ts` (CSP proxy with per-request nonces)
**Checked:** 2026-08-17
**Total claims checked:** 14
**Summary:** 9 verified, 0 mostly accurate, 0 stale, 3 incorrect, 2 unverifiable

Execution environment notes: verdict-bearing executions ran against `next dev` (Next.js 16.2.4, Turbopack) on `PORT=4101` in the clone. A production `npm run build` was attempted twice and fails in this sandbox with `Failed to fetch `EB Garamond` from Google Fonts` (no network to fonts.googleapis.com) — captured in `evidence/r1-build.log` and `evidence/r1-build-retry.log` (exit 1 both times). All raw outputs are under `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/` with prefix `r1-`. Hallucination-pattern-log steps were skipped per the run's blinding instructions. One temporary probe page (`app/r1probe/page.tsx`, used for Claim 8) was created and deleted; the clone was left with a clean `git status`.

---

## Claim 1a: "Opt this layout out of static rendering" (via `await headers()`)

**Location:** `app/layout.tsx:27`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether `await headers()` forces this root layout into dynamic rendering in a production build; does not establish dev-mode behavior (dev always renders dynamically, so dev execution cannot discriminate).

This is an executable guarantee — the build output's static/dynamic route marking would settle it — so the mandatory-execution rule caps the verdict at Unverifiable: `npm run build` was executed twice (cwd `/workspace/external/cc-review-eval/mfc-csp`, exit 1 both times, 2026-08-17 23:22 and 23:31 local; `evidence/r1-build.log`, `evidence/r1-build-retry.log`) and fails on the sandbox's lack of network access to Google Fonts, before any route-rendering analysis is produced. Static reading strongly supports the claim: Next's `headers()` implementation interrupts static generation when called during prerender:

```js
// node_modules/next/dist/server/request/headers.js:105-107
// We track dynamic access here so we don't need to wrap the headers in
...
return (0, _dynamicrendering.throwToInterruptStaticGeneration)(callingExpression, workStore, workUnitStore);
```

The layout does call it:

```tsx
// app/layout.tsx:31
await headers();
```

The specific blocker is that production `next build`/`next start` cannot run in this sandbox (Google Fonts fetch failure); with a build, the route table's static/dynamic marker for `/` would verify or refute this directly.

**Evidence:** `app/layout.tsx:27-31`, `node_modules/next/dist/server/request/headers.js:98-109`, `evidence/r1-build.log`, `evidence/r1-build-retry.log`

---

## Claim 1b: "...so proxy.ts runs on every request"

**Location:** `app/layout.tsx:27`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the claimed causal mechanism (static-rendering opt-out is what makes proxy.ts run per request); does not dispute that opting out of static rendering is useful for keeping the HTML's baked-in nonce fresh.

The stated mechanism is refuted by the proxy's own configuration: whether `proxy.ts` runs is governed solely by the URL/header matcher, which has no coupling to a route's rendering mode:

```ts
// proxy.ts:55-63
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

Next runs proxy/middleware for every matched incoming request before route resolution, including requests served from statically prerendered output, so the proxy would run per request even if the layout were statically rendered (paraphrased — no quote available because this is framework request-pipeline behavior spanning Next's server internals, and the production static-serving path could not be executed in this sandbox due to the build blocker in Claim 1a). What the `await headers()` opt-out actually changes is whether the HTML is re-rendered per request so its embedded nonce matches the fresh CSP header — not whether the proxy executes. Confidence is Medium rather than High because the static-route case could not be demonstrated by execution.

**Evidence:** `proxy.ts:51-63`, `app/layout.tsx:27-31`, `evidence/r1-dev-server.log`

---

## Claim 1c: "...and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each matched request receives a distinct nonce in the response CSP header (dev server); does not establish production-mode behavior (build blocked, see Claim 1a).

Executed: two consecutive `curl -s -o /dev/null -D - http://localhost:4101/` requests (cwd `/workspace/external/cc-review-eval/mfc-csp`, exit 0, 2026-08-17 ~23:23 local) returned distinct nonces in the `content-security-policy` response header:

```
// evidence/r1-nonce-freshness.txt
nonce-N2MwMzJhZjctMjQzZS00YjhmLThkMDYtNDQwMGUzMjY5NzRh
nonce-OTUxMWVjMDUtNjQwYy00NDhiLWIzNzQtMmRlNGMxNzYwOTE0
```

A third distinct nonce appears in the initial page capture (`evidence/r1-curl-root-headers.txt`).

**Evidence:** `evidence/r1-nonce-freshness.txt`, `evidence/r1-curl-root-headers.txt`, `proxy.ts:37`

---

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-server rendering of `/` (all script tags nonced, nonce sourced from the proxy-set CSP header); does not establish production-build behavior (build blocked, see Claim 1a).

Executed: `curl -s -D evidence/r1-curl-root-headers.txt -o evidence/r1-curl-root-body.html http://localhost:4101/` (cwd `/workspace/external/cc-review-eval/mfc-csp`, exit 0, response `Date: Tue, 18 Aug 2026 06:22:56 GMT`). The audit over the captured body (`evidence/r1-script-nonce-audit.txt`, 2026-08-18T06:32:40Z, exit 0) shows 36 `<script>` tags, 0 without a `nonce=` attribute, and a single distinct nonce value equal to the one in the response CSP header:

```
// evidence/r1-script-nonce-audit.txt
$ grep -oP "<script[^>]*>" r1-curl-root-body.html | wc -l
36
$ ... | grep -vc "nonce=" (tags WITHOUT nonce)
0
$ CSP nonce from r1-curl-root-headers.txt:
nonce-ZmMxYjM0ZTYtMWE2Mi00MWI3LWE0MTItNmZiNjFiZGYwODAx
```

The proxy sets the CSP only on the response (and `x-nonce` on the request), so the nonce Next used can only have come from the response CSP header. Mechanism corroborated in Next's renderer, which extracts the nonce from the CSP header in its header bag:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

The Claim 8 probe additionally showed that Next propagates the proxy's response CSP header into the request headers the render sees (`evidence/r1-xnonce-probe.txt` shows `requestCsp` equal to the full proxy CSP).

**Evidence:** `evidence/r1-script-nonce-audit.txt`, `evidence/r1-curl-root-headers.txt`, `evidence/r1-curl-root-body.html`, `evidence/r1-xnonce-probe.txt`, `node_modules/next/dist/server/app-render/app-render.js:166-167`, `proxy.ts:44-48`

---

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy)"

**Location:** `proxy.ts:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that Next 16 recognizes a root `proxy.ts` file as the middleware successor and executed it; does not cover the full deprecation status of `middleware.ts` in v16.

The installed Next version is 16.2.4 (`"next": "16.2.4"`, `package.json`), and its constants define the convention:

```js
// node_modules/next/dist/lib/constants.js:289
const PROXY_FILENAME = 'proxy';
```

Next's own error text confirms the rename and links the migration doc: `"Route segment config is not allowed in Proxy file at ... Learn more: https://nextjs.org/docs/messages/middleware-to-proxy"` (`node_modules/next/dist/build/analysis/get-page-static-info.js:576`). Executed: the dev server ran this file per request — the request log itemizes its time, e.g. `GET / 200 in 5.3s (next.js: 4.8s, proxy.ts: 138ms, application-code: 384ms)` (`evidence/r1-dev-server.log`; `npm run dev`, cwd clone, server exit not applicable — killed at end of run, 2026-08-17 23:21-23:33 local).

**Evidence:** `package.json`, `node_modules/next/dist/lib/constants.js:289`, `node_modules/next/dist/build/analysis/get-page-static-info.js:576`, `evidence/r1-dev-server.log`

---

## Claim 4: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust. This keeps a hypothetical injected `<script>` tag from executing"

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the served policy contains exactly the directives whose standard semantics match this description; does not cover in-browser enforcement (no browser in sandbox) and does not cover the parser-inserted qualifier of `'strict-dynamic'` trust propagation.

Executed: the served response header contains the claimed directive set (`curl` capture, exit 0, 2026-08-18T06:22:56Z):

```
// evidence/r1-curl-root-headers.txt
content-security-policy: default-src 'self'; script-src 'self' 'nonce-ZmMx...' 'strict-dynamic'; ...
```

built from:

```ts
// proxy.ts:22
`script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```

Under CSP3, this combination allows only nonce-carrying scripts, propagates trust from them to scripts they load via non-parser-inserted APIs, and blocks parser-inserted markup such as an injected `<script>` tag lacking the nonce — matching the comment (paraphrased — no quote available because these are CSP Level 3 specification semantics enforced by the browser, not code in this repository). Confidence is Medium because actual browser enforcement could not be executed in this sandbox; the header contents and Next's nonce tagging (Claim 2) are what was verified directly.

**Evidence:** `proxy.ts:20-31`, `evidence/r1-curl-root-headers.txt`, `evidence/r1-script-nonce-audit.txt`

---

## Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** `proxy.ts:12-14`
**Type:** Behavioral / Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the SSR HTML actually served in dev (no inline Tailwind styles observed there); does not establish client-runtime style injection behavior, which is where the claim would have to be true.

Tailwind v4 is present: `"tailwindcss": "^4"` (`package.json`, devDependencies). However, the executed SSR capture contradicts the claim for the server-rendered document: the audit (`evidence/r1-script-nonce-audit.txt`, 2026-08-18T06:32:40Z, exit 0) found

```
$ style tags in body:
0
```

and all CSS arrives as external nonced `<link rel="stylesheet">` chunks (font CSS and reactflow CSS; quoted in the same audit file). The document contains 4 `style="..."` attributes (paraphrased — no quote available because they are scattered component-level attributes in a 33KB single-line HTML capture, `evidence/r1-curl-root-body.html`), which are attributable to component libraries rather than demonstrably to Tailwind. Whether Tailwind/Turbopack injects inline `<style>` elements at client runtime in dev — the only place the claim could still hold — requires a browser, which this sandbox lacks; that is the specific blocker. The directive itself is present as configured (`"style-src 'self' 'unsafe-inline'"`, `proxy.ts:23`).

**Evidence:** `package.json`, `proxy.ts:23`, `evidence/r1-script-nonce-audit.txt`, `evidence/r1-curl-root-body.html`

---

## Claim 6a: "`connect-src 'self'` is sufficient because Anthropic / ... OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:16-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Anthropic and OpenRouter call sites and the absence of client-side third-party fetches in `app/`; does not establish behavior of runtime-constructed URLs or future code.

The Anthropic SDK and the OpenRouter endpoint live in server-side modules:

```ts
// app/lib/llm/callLlm.ts:2,7
import Anthropic from "@anthropic-ai/sdk";
...
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

Every module matching `OPENROUTER_API_URL|openrouter.ai|anthropic.com` lacks a `"use client"` directive, and every non-test importer of `callLlm`/`streamLlm` is under `app/api/**` or `app/lib/**`, all also without `"use client"` (paraphrased — no quote available because the evidence is a grep classification across ~15 files, all reporting `server:`). No client component fetches an absolute third-party URL: a grep for `fetch("http...` across `app/` returns only the server-side `callLlm.ts` constant above (paraphrased — no quote available because the claim covers absence of code; the grep had no other results).

**Evidence:** `app/lib/llm/callLlm.ts:1-10`, `app/lib/llm/streamLlm.ts`, `app/api/` (route importers)

---

## Claim 6b: "...OpenAlex calls..." (that OpenAlex calls exist in this codebase)

**Location:** `proxy.ts:16`
**Type:** Reference / Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of any OpenAlex integration anywhere in the repository and its full git history; does not dispute the sufficiency of `connect-src 'self'` (which holds regardless).

No OpenAlex reference exists anywhere in the codebase outside this comment: a case-insensitive repo-wide search (excluding `node_modules`/`.next`) returns zero matches, and `git log --all -S "openalex" -i` shows the string only ever entered the repository in commit 9b4e453 — the commit that added `proxy.ts` itself (paraphrased — no quote available because the claim covers absence of code; the searches returned no results outside the comment under check). The comment names a third-party integration the project does not have. The surrounding conclusion is unaffected — with no OpenAlex calls at all, `connect-src 'self'` remains sufficient — but the reference itself is false.

**Evidence:** `proxy.ts:16-17`, repository-wide grep (no matches), `git log --all -S "openalex"`

---

## Claim 7a: "Generate a fresh nonce per request."

**Location:** `proxy.ts:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers matched requests against the dev server; does not cover excluded routes (which get no nonce at all — see Claim 9).

Same execution as Claim 1c: consecutive requests produced distinct nonces (`evidence/r1-nonce-freshness.txt`, curl exit 0, 2026-08-17 ~23:23 local), consistent with the per-invocation generation in the code:

```ts
// proxy.ts:37
const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

**Evidence:** `evidence/r1-nonce-freshness.txt`, `evidence/r1-curl-root-headers.txt`, `proxy.ts:37`

---

## Claim 7b: "crypto.randomUUID and Buffer are both available in the ... runtime that Next proxy runs in."

**Location:** `proxy.ts:35-36`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers availability of both APIs in the runtime that actually executed the proxy in this run (dev server); the runtime's *name* is Claim 7c.

Executed: every matched request produced a well-formed base64-of-UUID nonce in the CSP header (48-character base64 values in `evidence/r1-curl-root-headers.txt` and `evidence/r1-nonce-freshness.txt`; curl exit 0), which requires both `crypto.randomUUID` and `Buffer` in

```ts
// proxy.ts:37
const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

to have executed without error on each request; the dev-server log shows no runtime errors from `proxy.ts` (`evidence/r1-dev-server.log`).

**Evidence:** `proxy.ts:37`, `evidence/r1-curl-root-headers.txt`, `evidence/r1-nonce-freshness.txt`, `evidence/r1-dev-server.log`

---

## Claim 7c: "...the Edge runtime that Next proxy runs in."

**Location:** `proxy.ts:36`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which runtime Next 16 executes `proxy.ts` in; does not affect Claim 7b (both APIs are native to Node.js, so the code works regardless).

Next 16 runs the proxy on the Node.js runtime, not the Edge runtime. Next's own build analysis states this unconditionally:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

A reader acting on the comment (e.g., assuming Edge-runtime API constraints apply, or that Node-only APIs are unavailable here) would be misled; in fact the opposite holds — full Node.js APIs are available, and `Buffer` is available natively rather than via an Edge polyfill.

**Evidence:** `node_modules/next/dist/build/analysis/get-page-static-info.js:576`, `node_modules/next/dist/lib/constants.js:289-290`

---

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `x-nonce` set on the forwarded request headers is readable via `headers()` in a server component (dev server); does not establish that any current layout consumes it (none does — `app/layout.tsx:30` says it is not needed), nor `<Script>`-tag propagation, which no code exercises.

Executed via a temporary probe page (`app/r1probe/page.tsx`, created for this check and deleted afterward) that rendered `JSON.stringify({ xNonce: h.get("x-nonce"), requestCsp: h.get("content-security-policy") })` from `await headers()`. Command: `curl -s -m 120 http://localhost:4101/r1probe` (cwd clone, exit 0, HTTP 200, 2026-08-17 ~23:28 local). The captured body shows the header round-trip, with `xNonce` equal to the nonce in that response's CSP header:

```
// evidence/r1-xnonce-probe.txt
xNonce&quot;:&quot;MWUxMTYyNzctMzEwYS00ZWNmLWE1MTQtZDIwOTU4ZDljOGU4&quot;,&quot;requestCsp&quot;:&quot;default-src &#x27;self&#x27;; script-src &#x27;self&#x27; &#x27;nonce-MWUxMTYyNzctMzEwYS00ZWNmLWE1MTQ...
```

matching the setter:

```ts
// proxy.ts:41-42
const requestHeaders = new Headers(request.headers);
requestHeaders.set("x-nonce", nonce);
```

(The probe incidentally shows Next also propagates the proxy's *response* CSP header into the request-header bag — the mechanism behind Claim 2.)

**Evidence:** `evidence/r1-xnonce-probe.txt`, `evidence/r1-xnonce-probe-headers.txt`, `proxy.ts:41-48`

---

## Claim 9: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches..."

**Location:** `proxy.ts:52-54`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers matcher inclusion/exclusion as observed against the dev server for `/`, `/api/analytics`, `/favicon.ico`, a `/_next/static` asset, `/_next/image`, and prefetch-headered requests; does not verify the parenthetical rationales ("they don't render HTML", "would burn a nonce") or exhaustively cover all route shapes.

Executed probe series (`curl`, cwd clone, exit 0 per probe, 2026-08-17 23:23–23:31 local; raw capture `evidence/r1-matcher-probes.txt`):

```
== GET / (page)
HTTP/1.1 200 OK
content-security-policy: default-src 'self'; script-src 'self' 'nonce-...' 'strict-dynamic'; ...
== GET /api/analytics
HTTP/1.1 200 OK
== GET /favicon.ico
HTTP/1.1 200 OK
== GET /_next/static css chunk
HTTP/1.1 200 OK
== GET / with purpose: prefetch header
HTTP/1.1 200 OK
== GET / with next-router-prefetch: 1 header + RSC
HTTP/1.1 200 OK
== GET /_next/image
HTTP/1.1 200 OK
Content-Security-Policy: script-src 'none'; frame-src 'none'; sandbox;
```

Only the page navigation received the proxy's CSP; API, favicon, `_next/static`, and both prefetch-headered requests received none, and `/_next/image` received only Next's image optimizer's own built-in restrictive CSP, not the proxy's (its value contains no nonce and none of the proxy's directives). The dev-server log corroborates: matched requests itemize `proxy.ts` time while `GET /api/analytics` shows no `proxy.ts` component (`evidence/r1-dev-server.log`). This matches the matcher config quoted under Claim 1b (`proxy.ts:55-63`).

**Evidence:** `evidence/r1-matcher-probes.txt`, `evidence/r1-dev-server.log`, `proxy.ts:51-63`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`app/layout.tsx:27`): Proxy execution is controlled by the matcher, not by the layout's rendering mode — the opt-out keeps the rendered HTML's nonce fresh; it does not make proxy.ts run.
- **Claim 6b** (`proxy.ts:16`): No OpenAlex integration exists anywhere in the repo or its history — drop OpenAlex from the comment.
- **Claim 7c** (`proxy.ts:36`): Next 16 proxy always runs on the Node.js runtime, not the Edge runtime (per Next's own source and the middleware-to-proxy migration doc).

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- **Claim 1a** (`app/layout.tsx:27`): Needs a production `next build` (blocked: sandbox has no network to fonts.googleapis.com) to confirm the route is marked dynamic; Next source strongly supports it.
- **Claim 5** (`proxy.ts:12-14`): Needs a browser session to observe whether Tailwind/Turbopack injects inline `<style>` elements at client runtime; the server-rendered HTML contains zero inline styles and ships all CSS as external nonced links.
