# Code Fact-Check Report

Commit: d90d6bb

**Repository:** `/workspace/external/cc-review-eval/mfc-csp`
**Scope:** `git diff main...review` — `app/layout.tsx`, `proxy.ts`, plus commit messages in `git log main..review` (`9b4e453`, `b25e939`, `d90d6bb`)
**Checked:** 2026-08-15
**Total claims checked:** 20
**Summary:** 8 verified, 5 mostly accurate, 0 stale, 7 incorrect, 0 unverifiable

---

## Claim 1: "Opt this layout out of static rendering so proxy.ts runs on every request and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:27-28`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** High

The claim asserts a causal chain: `await headers()` → layout is dynamic → the proxy runs per request. The second link does not exist. Whether `proxy.ts` runs is decided purely by matching the request pathname against the compiled matcher, before any rendering decision:

```js
// node_modules/next/dist/server/next-server.js:385-393
if (!(middleware.match(normalizedPathname, req, parsedUrl.query) || middleware.match(maybeDecodedPathname, req, parsedUrl.query))) {
    return handleFinished();
}
let result;
let bubblingResult = false;
try {
    await this.ensureMiddleware(req.url);
    result = await this.runMiddleware({
```

Nothing in that gate consults the route's static/dynamic status, so a statically prerendered page served from cache still runs the proxy (paraphrased — no quote available because the claim covers the absence of a condition; there is no static-rendering check anywhere in the `middleware.match(...)` guard to quote).

The first half of the sentence is correct: calling `headers()` during prerender interrupts static generation.

```js
// node_modules/next/dist/server/request/headers.js:102-107
case 'prerender-legacy':
    // Legacy Prerender
    // We are in a legacy static generation mode while prerendering
    // We track dynamic access here so we don't need to wrap the headers in
    // individual property access tracking.
    return (0, _dynamicrendering.throwToInterruptStaticGeneration)(callingExpression, workStore, workUnitStore);
```

The accurate statement of what the code does: `await headers()` opts the route out of static rendering so the *response* is generated per request (which is what a per-request CSP header on a cached HTML document would otherwise conflict with) — it does not cause or gate the proxy's execution.

**Evidence:** `app/layout.tsx:27-31`, `node_modules/next/dist/server/next-server.js:385-393`, `node_modules/next/dist/server/request/headers.js:100-125`

---

## Claim 2: "Next.js automatically tags its own bootstrap `<script>` elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves"

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

Next.js reads the nonce from the **request** headers, not the response headers:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

The `headers` argument to that function is `req.headers`:

```js
// node_modules/next/dist/server/app-render/app-render.js:1557-1561
const parsedRequestHeaders = parseRequestHeaders(req.headers, {
    isRoutePPREnabled: renderOpts.experimental.isRoutePPREnabled === true,
    previewProps: ...
});
const { isPrefetchRequest, previouslyRevalidatedTags, nonce } = parsedRequestHeaders;
```

`proxy.ts` sets the CSP only on the response, and sets only `x-nonce` (not `content-security-policy`) on the forwarded request headers:

```ts
// proxy.ts:41-47
const requestHeaders = new Headers(request.headers);
requestHeaders.set("x-nonce", nonce);

const response = NextResponse.next({
  request: { headers: requestHeaders },
});
response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

So `parseRequestHeaders` finds no `content-security-policy` request header, `nonce` resolves to `undefined`, and Next tags nothing (paraphrased — no quote available because the outcome is the absence of a value flowing through `app-render.js`, not a snippet). The corollary "so we don't need to read x-nonce here ourselves" therefore does not follow from the stated mechanism.

**Evidence:** `app/layout.tsx:28-30`, `proxy.ts:41-47`, `node_modules/next/dist/server/app-render/app-render.js:155-190`, `node_modules/next/dist/server/app-render/app-render.js:1554-1561`, `node_modules/next/dist/server/app-render/get-script-nonce-from-header.js`

---

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy)"

**Location:** `proxy.ts:5`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High

Next 16.2.4 is installed (`"next": "16.2.4"` in `package.json:22`) and defines both filename conventions, with `proxy` as the current one:

```js
// node_modules/next/dist/lib/constants.js:287-290
const MIDDLEWARE_FILENAME = 'middleware';
const MIDDLEWARE_LOCATION_REGEXP = `(?:src/)?${MIDDLEWARE_FILENAME}`;
const PROXY_FILENAME = 'proxy';
const PROXY_LOCATION_REGEXP = `(?:src/)?${PROXY_FILENAME}`;
```

The named export `proxy` used at `proxy.ts:34` is the handler name Next looks for in a proxy file:

```js
// node_modules/next/dist/build/templates/middleware.js:77
const handlerUserland = (isProxy ? mod.proxy : mod.middleware) || mod.default;
```

**Evidence:** `proxy.ts:5`, `proxy.ts:34`, `package.json:22`, `node_modules/next/dist/lib/constants.js:287-290`, `node_modules/next/dist/build/templates/middleware.js:77`

---

## Claim 4: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust"

**Location:** `proxy.ts:7-8`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

The general CSP semantics of `'nonce-…' 'strict-dynamic'` are as described, but the premise — that Next.js tags its scripts with *this* nonce — does not hold for this code. As established in Claim 2, Next derives the nonce from the request's `content-security-policy` header, and `proxy.ts` never sets that header on the request:

```ts
// proxy.ts:41-47
const requestHeaders = new Headers(request.headers);
requestHeaders.set("x-nonce", nonce);

const response = NextResponse.next({
  request: { headers: requestHeaders },
});
response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

What the code actually produces: a CSP whose `script-src` carries a nonce that no emitted `<script>` element bears (paraphrased — no quote available because the claim concerns the absence of a nonce attribute in generated HTML output, which is produced at runtime and has no source line to quote).

**Evidence:** `proxy.ts:7-10`, `proxy.ts:22`, `proxy.ts:41-47`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** `proxy.ts:12-14`
**Type:** Architectural / Configuration
**Verdict:** Incorrect
**Confidence:** High

Tailwind v4 in this project is compiled by the PostCSS plugin into an external stylesheet, not inline styles. The pipeline is a build-time PostCSS transform:

```js
// postcss.config.mjs:1-5
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

```css
/* app/globals.css:1-2 */
@import "tailwindcss";
@plugin "@tailwindcss/typography";
```

The build output confirms the result is a static `.css` file containing both the project's custom properties and Tailwind's generated utilities:

```
$ grep -l "ivory-cream" .next/static/chunks/*.css
.next/static/chunks/14ilop8f~_b--.css

$ grep -o "\.antialiased{[^}]*}" .next/static/chunks/14ilop8f~_b--.css
.antialiased{-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}
```

An external stylesheet is covered by the `style-src 'self'` already present at `proxy.ts:23` and needs no `'unsafe-inline'`.

The inline styles that *do* exist in this app come from React `style={{…}}` attributes across the component tree, e.g.:

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:20-23
<p
  className={`text-[#6B6560] ${className ?? ""}`}
  style={{ lineHeight: 1.9 }}
>
```

Such attributes appear in at least 19 component files (paraphrased — no quote available because the count is an aggregate over many call sites; it comes from `rg -c "style=\{\{" app --glob '*.tsx'`). The mechanism attributed to Tailwind is therefore misattributed; the accurate statement is that React inline `style` attributes (and third-party runtime style injection such as React Flow's) are what `'unsafe-inline'` covers.

**Evidence:** `proxy.ts:12-14`, `proxy.ts:23`, `postcss.config.mjs:1-5`, `app/globals.css:1-2`, `.next/static/chunks/14ilop8f~_b--.css`, `app/components/features/output-editing/LatexRenderer.tsx:20-23`

---

## Claim 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:16-17`
**Type:** Architectural / Configuration
**Verdict:** Incorrect
**Confidence:** High

The premise about the named third parties is correct, but the "sufficient" conclusion is not, because a client-side module fetches a `data:` URL — a scheme `connect-src 'self'` does not permit:

```ts
// app/lib/utils/exportGraph.ts:20-26
const dataUrl = await toPng(viewportElement, {
  pixelRatio: 2,
  backgroundColor: EXPORT_BG,
});
const res = await fetch(dataUrl);
const blob = await res.blob();
triggerDownload(blob, filename);
```

The same pattern repeats in the sibling export helper:

```ts
// app/lib/utils/exportGraph.ts:33-38
const dataUrl = await toPng(viewportElement, {
  pixelRatio: 2,
  backgroundColor: EXPORT_BG,
});
const res = await fetch(dataUrl);
return res.blob();
```

This is browser-side code — it queries the DOM directly:

```ts
// app/lib/utils/exportGraph.ts:10-12
export function getGraphViewportElement(): HTMLElement | null {
  return document.querySelector<HTMLElement>(".react-flow__viewport");
}
```

Note that `img-src` and `font-src` in the same directive list do allow `data:`, but `connect-src` does not:

```ts
// proxy.ts:24-26
"img-src 'self' data: blob:",
"font-src 'self' data:",
"connect-src 'self'",
```

Two supporting sub-findings. First, the Anthropic and OpenRouter parts hold: `app/lib/llm/callLlm.ts` imports Node's `crypto` and is imported only by files under `app/api/**` and `app/lib/formalization/`, so it never reaches the browser bundle:

```ts
// app/lib/llm/callLlm.ts:1-7
import { randomUUID } from "crypto";
import Anthropic from "@anthropic-ai/sdk";
...
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

Second, "OpenAlex" names a service this repository does not call at all — a repo-wide case-insensitive search for `openalex` (excluding `node_modules`, `.next`, and lockfiles) returns exactly one hit, the comment itself at `proxy.ts:16` (paraphrased — no quote available because the claim covers the absence of matching grep results).

**Evidence:** `proxy.ts:16-17`, `proxy.ts:24-26`, `app/lib/utils/exportGraph.ts:10-12`, `app/lib/utils/exportGraph.ts:16-39`, `app/lib/llm/callLlm.ts:1-7`

---

## Claim 7: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in."

**Location:** `proxy.ts:35-36`
**Type:** Architectural / Invariant
**Verdict:** Incorrect
**Confidence:** High

In Next.js 16 a proxy file does not run in the Edge runtime. The framework states this explicitly and rejects any attempt to configure a runtime for a proxy file:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:573-582
if ((0, _utils.isProxyFile)(page) && resolvedRuntime) {
    const relativePath = (0, _path.relative)(process.cwd(), pageFilePath);
    const resolvedPath = relativePath.startsWith('.') ? relativePath : `./${relativePath}`;
    const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
    if (isDev) {
        // errorOnce as proxy/middleware runs per request including multiple
        // internal _next/ routes and spams logs.
        _log.errorOnce(message);
        resolvedRuntime = _constants.SERVER_RUNTIME.nodejs;
    } else {
```

`isProxyFile` matches this repository's root-level `proxy.ts`:

```js
// node_modules/next/dist/build/utils.js:1130-1132
function isProxyFile(file) {
    return file === `/${_constants.PROXY_FILENAME}` || file === `/src/${_constants.PROXY_FILENAME}`;
}
```

The consequence is that both named globals *are* available, but for the opposite reason from the one stated: they are available because this is the Node.js runtime. `Buffer` is a Node global with no counterpart in the Edge runtime, so had the comment's premise been true, the very next line would fail:

```ts
// proxy.ts:37
const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

The accurate statement is: `crypto.randomUUID` and `Buffer` are both available because Next.js 16 always runs proxy files on the Node.js runtime.

**Evidence:** `proxy.ts:35-37`, `node_modules/next/dist/build/analysis/get-page-static-info.js:572-589`, `node_modules/next/dist/build/utils.js:1130-1132`

---

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to `<Script>` tags they render."

**Location:** `proxy.ts:39-40`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The forwarding mechanism itself is real and correctly written — `NextResponse.next({ request: { headers } })` is what makes a header visible to downstream server components:

```ts
// proxy.ts:41-46
const requestHeaders = new Headers(request.headers);
requestHeaders.set("x-nonce", nonce);

const response = NextResponse.next({
  request: { headers: requestHeaders },
});
```

The stated purpose does not correspond to anything in the codebase, however. A repo-wide search for `x-nonce` (excluding `node_modules` and `.next`) returns only two hits — the write in `proxy.ts:42` and a mention inside the layout's own comment at `app/layout.tsx:30` — so no layout or component reads the header (paraphrased — no quote available because the claim covers the absence of matching grep results). There are likewise no `<Script>` elements anywhere in `app/` to receive it (paraphrased — no quote available for the same reason).

The precise version: the nonce is written to the request headers and is readable via `headers()`, but no consumer exists, and — per Claim 2 — this header is not the channel Next.js itself uses for nonce propagation.

**Evidence:** `proxy.ts:39-46`, `app/layout.tsx:27-31`

---

## Claim 9: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches."

**Location:** `proxy.ts:52-54`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium

The three exclusions the comment enumerates are all really present in the matcher:

```ts
// proxy.ts:55-62
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

The negative lookahead excludes `api`, `_next/static`, `_next/image`, and `favicon.ico`, and the `missing` clause excludes requests carrying either prefetch header. Next 16 passes non-`source` matcher fields through to the compiled matcher:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:335
let { source, ...rest } = matcher;
```

The summarizing phrase "page navigations only" overstates the exclusion in two ways. First, files served from `public/` are not under `_next/static`, so they match the pattern and receive the CSP header — the directory holds five SVGs (paraphrased — no quote available because the claim is about directory contents, not a code snippet; `ls public/` lists `file.svg`, `globe.svg`, `next.svg`, `vercel.svg`, `window.svg`). Second, Next wraps every matcher source so that `_next/data` requests are also admitted:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:340
source = `/:nextData(_next/data/[^/]{1,})?${source}${isRoot ? ... : '{(\\.json)}?'}`;
```

Non-prefetch RSC navigation requests also match, since nothing in the pattern or the `missing` clause filters on the RSC header (paraphrased — no quote available because the claim covers the absence of a condition in the matcher object quoted above).

**Evidence:** `proxy.ts:51-64`, `node_modules/next/dist/build/analysis/get-page-static-info.js:330-358`, `public/`

---

## Claim 10: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit `9b4e453` (message body)
**Type:** Architectural / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The first two sub-claims check out: searches for `dangerouslySetInnerHTML` across `app/` (excluding tests) and for `rehype-raw`/`rehypeRaw` across `app/` and `package.json` both return zero hits (paraphrased — no quote available because both claims cover the absence of matching grep results; `rehype-raw` is likewise absent from the dependency list in `package.json:11-31`).

The third sub-claim is imprecise. `trust: false` is nowhere configured — `rehype-katex` is registered with no options at all, so `trust` takes KaTeX's default:

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:6-10
import rehypeKatex from "rehype-katex";
import "katex/dist/katex.min.css";

const remarkPlugins = [remarkGfm, remarkMath];
const rehypePlugins = [rehypeKatex];
```

The precise version: KaTeX runs with `trust` at its default (falsy) value because no options object is passed, not because the project sets `trust: false`.

**Evidence:** commit `9b4e453`, `app/components/features/output-editing/LatexRenderer.tsx:1-10`, `package.json:11-31`

---

## Claim 11: "File is named proxy.ts because Next.js 16 renamed Middleware to Proxy (middleware.ts builds with a deprecation warning)."

**Location:** commit `9b4e453` (message body)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High

The deprecation warning the message describes is emitted at build time:

```js
// node_modules/next/dist/build/index.js:651
_log.warnOnce(`The "${_constants.MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${_constants.PROXY_FILENAME}" instead. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`);
```

`MIDDLEWARE_FILENAME` is `'middleware'` and `PROXY_FILENAME` is `'proxy'` (`node_modules/next/dist/lib/constants.js:287-289`, quoted under Claim 3), and the installed version is 16.2.4 (`package.json:22`).

**Evidence:** commit `9b4e453`, `node_modules/next/dist/build/index.js:645-651`, `node_modules/next/dist/lib/constants.js:287-290`, `package.json:22`

---

## Claim 12: "The matcher skips /api routes, _next/static, and prefetches so we don't burn nonces on requests that don't render HTML."

**Location:** commit `9b4e453` (message body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High

Unlike the in-file comment (Claim 9), this phrasing asserts only the exclusions, all three of which are present:

```ts
// proxy.ts:57-61
source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
missing: [
  { type: "header", key: "next-router-prefetch" },
  { type: "header", key: "purpose", value: "prefetch" },
],
```

**Evidence:** commit `9b4e453`, `proxy.ts:55-62`

---

## Claim 13: "Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached."

**Location:** commit `9b4e453` (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The layout does call `headers()`:

```tsx
// app/layout.tsx:31
await headers();
```

and that call interrupts static generation during prerender:

```js
// node_modules/next/dist/server/request/headers.js:106-107
// individual property access tracking.
return (0, _dynamicrendering.throwToInterruptStaticGeneration)(callingExpression, workStore, workUnitStore);
```

Unlike the in-file comment at `app/layout.tsx:27-28` (Claim 1), this commit-message phrasing does not assert that the opt-out is what makes the proxy run, so it does not carry that error.

**Evidence:** commit `9b4e453`, `app/layout.tsx:22-31`, `node_modules/next/dist/server/request/headers.js:100-125`

---

## Claim 14: "connect-src is just 'self' because all external API calls (Anthropic, OpenAlex, OpenRouter) go server-to-server, never browser-to-third-party."

**Location:** commit `9b4e453` (message body)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High

Restricted to the named third parties, the claim holds: the Anthropic SDK and the OpenRouter endpoint live in a module that also imports Node's `crypto`, and it is reached only from API routes and server-side formalization helpers:

```ts
// app/lib/llm/callLlm.ts:1-7
import { randomUUID } from "crypto";
import Anthropic from "@anthropic-ai/sdk";
...
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

Browser-side `fetch` calls target same-origin API routes, e.g.:

```ts
// app/hooks/useAnalytics.ts:11
fetch("/api/analytics")
```

Two qualifiers. "OpenAlex" names a service this repository never calls — the only occurrence of that string outside `node_modules`/`.next`/lockfiles is the comment in `proxy.ts` itself (paraphrased — no quote available because the claim covers the absence of matching grep results). And the "connect-src is just 'self'" conclusion is undercut by the client-side `data:`-URL fetch documented under Claim 6 (`app/lib/utils/exportGraph.ts:24`, `:37`), which is a browser-side connection the directive does not permit even though it is not a third-party host.

**Evidence:** commit `9b4e453`, `app/lib/llm/callLlm.ts:1-7`, `app/hooks/useAnalytics.ts:11`, `app/lib/utils/exportGraph.ts:20-38`, `proxy.ts:16-17`

---

## Claim 15: "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates."

**Location:** commit `9b4e453` (message body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

The first half is supported by the code — the response header is set unconditionally on every matched request:

```ts
// proxy.ts:47
response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

The second half contradicts how Next.js sources the nonce. Per Claim 2, the value is extracted from the *request's* `content-security-policy` header (`node_modules/next/dist/server/app-render/app-render.js:166-167`, quoted there), and `proxy.ts` sets that header only on the response while forwarding just `x-nonce` on the request (`proxy.ts:41-47`, quoted under Claim 2). With no CSP request header present, `nonce` is `undefined` and no `<script>` receives a nonce attribute (paraphrased — no quote available because the outcome is the absence of a value flowing through `app-render.js`).

The build artifacts in the working tree cannot corroborate the claim either: the checked-in `.next` build predates this branch and contains no proxy entry.

```json
// .next/server/middleware-manifest.json:1-6
{
  "version": 3,
  "middleware": {},
  "sortedMiddleware": [],
  "functions": {}
}
```

**Evidence:** commit `9b4e453`, `proxy.ts:41-47`, `node_modules/next/dist/server/app-render/app-render.js:155-190`, `.next/server/middleware-manifest.json`

---

## Claim 16: "proxy.ts: add explicit return type, inline single-use csp local."

**Location:** commit `d90d6bb` (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Both edits are exactly what the commit's own diff does:

```diff
// git show d90d6bb -- proxy.ts
-export function proxy(request: NextRequest) {
+export function proxy(request: NextRequest): NextResponse {
...
-  const csp = buildCsp(nonce);
...
-  response.headers.set("Content-Security-Policy", csp);
+  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

The resulting file carries the annotation at `proxy.ts:34` and the inlined call at `proxy.ts:47`.

**Evidence:** commit `d90d6bb`, `proxy.ts:34`, `proxy.ts:47`

---

## Claim 17: "No behavior change; CSP directives preserved exactly."

**Location:** commit `d90d6bb` (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The commit's diff for `proxy.ts` touches only lines 34-47 and does not enter the `directives` array; `git show d90d6bb -- proxy.ts` shows no hunk overlapping `buildCsp`'s body (paraphrased — no quote available because the claim covers the absence of a diff hunk in that line range). The nine directives at `proxy.ts:21-29` are byte-identical to those introduced in `9b4e453`.

**Evidence:** commit `d90d6bb`, `proxy.ts:19-32`

---

## Claim 18: "Lint clean; 221/221 tests pass."

**Location:** commit `d90d6bb` (message body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The test count is exact. Running the project's test command reproduces it:

```
$ npx vitest run
 Test Files  24 passed (24)
      Tests  221 passed (221)
```

"Lint clean" is imprecise: `npx eslint` exits 0 with zero errors but two warnings, both pre-existing in a file this branch does not touch:

```
/workspace/external/cc-review-eval/mfc-csp/app/page.tsx
  209:6  warning  React Hook useCallback has missing dependencies: ...  react-hooks/exhaustive-deps
  271:6  warning  React Hook useCallback has missing dependencies: ...  react-hooks/exhaustive-deps

✖ 2 problems (0 errors, 2 warnings)
```

The precise version would be "lint passes with 0 errors (2 pre-existing warnings in `app/page.tsx`)".

**Evidence:** commit `d90d6bb`, `package.json:8-9`, `app/page.tsx:209`, `app/page.tsx:271`

---

## Claim 19: "layout.tsx: correct comment — headers() is called to opt out of static rendering so the proxy can attach per-request CSP, not to read x-nonce (the nonce is only written, never read by the layout)."

**Location:** commit `d90d6bb` (message body)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The parenthetical is accurate: the layout contains no read of `x-nonce`, and the only two occurrences of that string in the repository (excluding `node_modules`/`.next`) are the write in `proxy.ts:42` and the mention inside the layout's replacement comment (paraphrased — no quote available because the claim covers the absence of matching grep results). The comment replacement itself matches the description:

```diff
// git show d90d6bb -- app/layout.tsx
-  // Read the per-request CSP nonce that proxy.ts forwards via x-nonce.
+  // Opt this layout out of static rendering so proxy.ts runs on every request
```

Note that the *replacement comment* introduces the two errors reported in Claims 1 and 2; this commit-message claim describes the edit accurately regardless.

**Evidence:** commit `d90d6bb`, `app/layout.tsx:27-31`, `proxy.ts:42`

---

## Claim 20: "correct layout comment to reference proxy.ts (renamed from middleware.ts)"

**Location:** commit `b25e939` (message subject)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The commit is a one-line, one-file change doing exactly that:

```diff
// git show b25e939 -- app/layout.tsx
-  // Read the per-request CSP nonce that middleware.ts forwards via x-nonce.
+  // Read the per-request CSP nonce that proxy.ts forwards via x-nonce.
```

`git show b25e939 --stat` reports `app/layout.tsx | 2 +-`, i.e. one insertion and one deletion in a single file (paraphrased — no quote available because the figure comes from git's diffstat output rather than a source line). The rename premise is confirmed under Claims 3 and 11.

**Evidence:** commit `b25e939`, `app/layout.tsx:27-30`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`app/layout.tsx:27-28`): `await headers()` opts the route out of static rendering, but does not cause `proxy.ts` to run — the proxy runs on any matcher-matching request regardless of the route's static/dynamic status.
- **Claim 2** (`app/layout.tsx:28-30`): Next.js reads the nonce from the **request's** `content-security-policy` header, not the response's; `proxy.ts` sets the CSP only on the response, so no nonce reaches Next's renderer.
- **Claim 4** (`proxy.ts:7-8`): Next.js tags no scripts with this nonce, because the nonce is never delivered on the request CSP header the renderer reads.
- **Claim 5** (`proxy.ts:12-14`): Tailwind v4 compiles to an external `.css` chunk here (`.next/static/chunks/14ilop8f~_b--.css`), covered by `style-src 'self'`; the actual inline styles come from React `style={{…}}` attributes across ~19 components.
- **Claim 6** (`proxy.ts:16-17`): `connect-src 'self'` is not sufficient — `app/lib/utils/exportGraph.ts:24` and `:37` run `fetch(dataUrl)` on a `data:` URL in browser code, which `'self'` does not permit. Separately, OpenAlex is never called anywhere in the repo.
- **Claim 7** (`proxy.ts:35-36`): Next.js 16 always runs proxy files on the **Node.js** runtime, not Edge; `Buffer` works because of that, and would be unavailable had the stated premise held.
- **Claim 15** (commit `9b4e453`): Next does not apply the nonce to generated `<script>` tags with this wiring; the checked-in `.next` build also contains no proxy entry, so it cannot corroborate the "verified prod build" statement.

### Stale
- None.

### Mostly Accurate
- **Claim 8** (`proxy.ts:39-40`): The `NextResponse.next({ request: { headers } })` forwarding works, but nothing reads `x-nonce` and no `<Script>` elements exist in `app/` — tighten to describe capability, not an existing consumer.
- **Claim 9** (`proxy.ts:52-54`): The three named exclusions are real, but "page navigations only" overstates it — `public/` assets, `_next/data` requests, and non-prefetch RSC requests all still match.
- **Claim 10** (commit `9b4e453`): `trust: false` is KaTeX's default, not a configured setting — `rehype-katex` is registered with no options at `app/components/features/output-editing/LatexRenderer.tsx:10`.
- **Claim 14** (commit `9b4e453`): The Anthropic/OpenRouter server-side premise holds, but OpenAlex is never called, and the `data:`-URL fetch in `exportGraph.ts` is a browser-side connection `'self'` blocks.
- **Claim 18** (commit `d90d6bb`): 221/221 tests confirmed; "lint clean" should read "0 errors, 2 pre-existing warnings in `app/page.tsx`".

### Unverifiable
- None.
