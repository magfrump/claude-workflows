# Code Fact-Check Report
Commit: d90d6bb

**Repository:** /workspace/external/cc-review-eval/mfc-csp
**Scope:** branch diff `main...review` (`app/layout.tsx`, `proxy.ts`) plus commit messages `main..review`
**Checked:** 2026-08-15
**Total claims checked:** 14
**Summary:** 3 verified, 5 mostly accurate, 0 stale, 5 incorrect, 1 unverifiable

---

## Claim 1: "Opt this layout out of static rendering so proxy.ts runs on every request and can attach a fresh per-request CSP nonce."

**Location:** `app/layout.tsx:27-28`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

`headers()` is a dynamic API in Next 16 and does opt the route out of static rendering — Next's own bailout error confirms it:

```js
// node_modules/next/dist/esm/server/request/headers.js:76
throw Object.defineProperty(new StaticGenBailoutError(`Route ${workStore.route} with \`dynamic = "error"\` couldn't be rendered statically because it used \`headers()\`. ...`
```

The causal phrasing is imprecise: the proxy runs on every matched request regardless of whether the page is static or dynamic — what the `headers()` call actually buys is that the page HTML is rendered per-request instead of being prerendered at build time with a baked-in (or absent) nonce that would mismatch the fresh CSP header (paraphrased — no quote available because the claim covers the interaction of the build-time prerender pipeline with the proxy's per-request header, which spans Next's rendering machinery rather than one snippet). The precise version: "so the page is rendered per-request, keeping the HTML in sync with the fresh nonce the proxy attaches."

**Evidence:** `app/layout.tsx:27-31`, `node_modules/next/dist/esm/server/request/headers.js:4-107`

---

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

Next.js reads the nonce from the incoming **request** headers, not from the response's CSP header. The app renderer parses request headers:

```js
// node_modules/next/dist/esm/server/app-render/app-render.js:111-112
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? getScriptNonceFromHeader(csp) : undefined;
```

and that `headers` argument is the request's headers:

```js
// node_modules/next/dist/esm/server/app-render/app-render.js:1502
const parsedRequestHeaders = parseRequestHeaders(req.headers, {
```

The proxy sets the CSP header only on the **response** and sets only `x-nonce` on the forwarded request:

```ts
// proxy.ts:42-47
requestHeaders.set("x-nonce", nonce);

const response = NextResponse.next({
  request: { headers: requestHeaders },
});
response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

Because no `Content-Security-Policy` header is placed on the forwarded request, `nonce` resolves to `undefined` in the renderer and Next does not tag its bootstrap scripts with the nonce at all. For the described behavior, the proxy would need to set the CSP header on the request headers as well (the pattern in Next's CSP guidance). As written, under `script-src 'self' 'nonce-…' 'strict-dynamic'` (`proxy.ts:22`), un-nonced bootstrap scripts would be blocked by a conforming browser (paraphrased — no quote available because this is CSP-specification behavior of `'strict-dynamic'`, not repository code).

**Evidence:** `app/layout.tsx:27-31`, `proxy.ts:41-48`, `node_modules/next/dist/esm/server/app-render/app-render.js:100-112,1502`

---

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy)"

**Location:** `proxy.ts:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The installed Next (`16.2.4` per `node -e "require('next/package.json').version"` — paraphrased — no quote available because the value was read via a node one-liner, not a source snippet) treats `middleware` as the deprecated name of `proxy`:

```js
// node_modules/next/dist/esm/build/index.js:583
Log.warnOnce(`The "${MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${PROXY_FILENAME}" instead. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`);
```

**Evidence:** `proxy.ts:5`, `node_modules/next/dist/esm/build/index.js:575-584`, `package.json:26`

---

## Claim 4: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust."

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

As a description of `'strict-dynamic'` semantics this is correct: nonce-bearing scripts execute and scripts they programmatically load inherit trust (paraphrased — no quote available because this is CSP-specification behavior, not repository code). But the premise "scripts that Next.js has explicitly tagged with the nonce" is empty in this codebase — as shown in Claim 2, Next never receives the nonce (it reads it from the request's `content-security-policy` header, which the proxy does not set), so no script gets tagged. The mechanism is described accurately; its precondition is not met by this code.

**Evidence:** `proxy.ts:7-10,22,41-48`, `node_modules/next/dist/esm/server/app-render/app-render.js:111-112`

---

## Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** `proxy.ts:12-14`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium

In this project Tailwind v4 ships as a compiled stylesheet, not inline styles. It is wired through PostCSS into an imported CSS file:

```css
/* app/globals.css:1-2 */
@import "tailwindcss";
@plugin "@tailwindcss/typography";
```

which `app/layout.tsx` pulls in as a normal stylesheet:

```tsx
// app/layout.tsx:4
import "./globals.css";
```

A stylesheet delivered this way is covered by `style-src 'self'`, not `'unsafe-inline'`. The app does have real inline-style pressure, but it comes from React `style={}` attributes scattered across components — e.g.:

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:32
style={{ lineHeight: 1.9, fontFamily: "inherit" }}
```

with 20+ further `style={` occurrences across `app/components/` (paraphrased — no quote available because the evidence is a grep count across many files, not one snippet). Next's dev-mode style injection may also require `'unsafe-inline'`, but that is Next behavior, not "Tailwind v4 emits inline styles" (paraphrased — no quote available because dev-server injection behavior is runtime behavior of the Next toolchain, not statically quotable app code). The carve-out itself may well be needed; the stated mechanism is wrong.

**Confidence rationale:** Medium — the prod delivery path is clear from the config, but dev-mode injection behavior resists static analysis.

**Evidence:** `app/globals.css:1-2`, `app/layout.tsx:4`, `postcss.config.mjs`, `package.json:33,49`, `app/components/features/output-editing/LatexRenderer.tsx:20-32`

---

## Claim 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:16-17`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium

The server-to-server half checks out: the OpenRouter/Anthropic call sites live in `app/lib/llm/callLlm.ts` and `app/lib/llm/streamLlm.ts`, which import Node's `crypto` module and are imported only by `app/api/**/route.ts` files:

```ts
// app/lib/llm/streamLlm.ts:1
import { randomUUID } from "crypto";
```

and all browser-side fetches target same-origin `/api/...` paths, e.g.:

```ts
// app/hooks/useAnalytics.ts:11
fetch("/api/analytics")
```

(remaining client fetch sites are same-origin as well — paraphrased — no quote available because the evidence is a grep across `app/hooks`, `app/components`, and `app/lib/formalization` showing every literal URL starts with `/api/`).

But "sufficient" is contradicted by the client-side graph export, which fetches a `data:` URL from the browser:

```ts
// app/lib/utils/exportGraph.ts:20-25
const dataUrl = await toPng(viewportElement, {
  pixelRatio: 2,
  backgroundColor: EXPORT_BG,
});
const res = await fetch(dataUrl);
const blob = await res.blob();
```

This runs in a client component (`app/components/panels/GraphPanel.tsx:1` is `"use client"` and imports `downloadGraphAsPng`). Under CSP, `fetch()` of a `data:` URL is governed by `connect-src`, and `'self'` does not include `data:` — the PNG export would be blocked (paraphrased — no quote available because this is CSP-specification behavior, not repository code). Separately, "OpenAlex" appears nowhere in the repository outside this comment itself — a grep for `openalex` (case-insensitive, excluding node_modules) matches only `proxy.ts:16` (paraphrased — no quote available because the claim covers absence of code / no matching grep results).

**Evidence:** `proxy.ts:16-17,26`, `app/lib/llm/callLlm.ts:7`, `app/lib/llm/streamLlm.ts:1-9`, `app/lib/utils/exportGraph.ts:16-39`, `app/components/panels/GraphPanel.tsx:1`, `app/hooks/useAnalytics.ts:11`

---

## Claim 7: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in."

**Location:** `proxy.ts:35-36`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High

In Next 16, proxy does not run in the Edge runtime — it always runs on Node.js, and a runtime override is not even permitted:

```js
// node_modules/next/dist/esm/build/analysis/get-page-static-info.js:503
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

`proxy.ts` declares no runtime config of its own — its only export besides `proxy` is the `config` matcher object (`proxy.ts:51-64`), and `next.config.ts` is empty of options:

```ts
// next.config.ts:3-5
const nextConfig: NextConfig = {
  /* config options here */
};
```

The functional conclusion survives the misattribution: `crypto.randomUUID` and `Buffer` are both available in the Node.js runtime the proxy actually runs in (paraphrased — no quote available because global availability in Node ≥ 20 is a platform fact, not repository code), so `proxy.ts:37` works — but the comment names the wrong runtime, which would mislead a reader reasoning about what APIs the proxy may use.

**Evidence:** `proxy.ts:35-37,51-64`, `node_modules/next/dist/esm/build/analysis/get-page-static-info.js:495-513`, `next.config.ts:1-8`

---

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-40`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The forwarding mechanism itself works as described — the header is set on a clone of the request headers and passed to `NextResponse.next`:

```ts
// proxy.ts:41-46
const requestHeaders = new Headers(request.headers);
requestHeaders.set("x-nonce", nonce);

const response = NextResponse.next({
  request: { headers: requestHeaders },
});
```

so a layout *could* read it via `headers()`. But nothing does: a repo-wide grep for `x-nonce` finds only the write at `proxy.ts:42` and the layout comment that says it is deliberately not read (paraphrased — no quote available because the claim covers absence of code — no consuming grep hits). The layout confirms this explicitly:

```tsx
// app/layout.tsx:30
// CSP header, so we don't need to read x-nonce here ourselves.
```

The comment describes an available-but-unused capability; and note that this forwarding is not the channel Next itself uses for automatic nonce tagging (see Claim 2 — Next wants the CSP header on the request).

**Evidence:** `proxy.ts:39-46`, `app/layout.tsx:27-31`

---

## Claim 9: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)."

**Location:** `proxy.ts:52-54`
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The matcher does skip the named categories. The source pattern excludes API routes and Next's static asset paths:

```ts
// proxy.ts:57
source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

and the `missing` conditions (`proxy.ts:58-61`) skip prefetches: Next runs the route only when every `missing` entry is absent —

```js
// node_modules/next/dist/esm/shared/lib/router/utils/prepare-destination.js (matchHas)
const allMatch = has.every((item)=>hasMatch(item)) && !missing.some((item)=>hasMatch(item));
```

— so a request carrying either `next-router-prefetch` or `purpose: prefetch` bypasses the proxy. "Page navigations only" overstates slightly: the pattern still matches non-page requests such as the files in `public/` (`file.svg`, `globe.svg`, `next.svg`, `vercel.svg`, `window.svg` — paraphrased — no quote available because the claim is about directory contents, not a code snippet), which would receive the CSP header harmlessly. The precise version: "skips API routes, `_next/static`, `_next/image`, `favicon.ico`, and prefetches; everything else, including public assets, is matched."

**Evidence:** `proxy.ts:55-63`, `node_modules/next/dist/esm/shared/lib/router/utils/prepare-destination.js:27-90`, `public/`

---

## Claim 10: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit `9b4e453` (message body)
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

Greps for `dangerouslySetInnerHTML` and `rehype-raw`/`rehypeRaw` across `app/` (excluding tests) return zero hits (paraphrased — no quote available because the claim covers absence of code — no matching grep results). The KaTeX part is directionally right but imprecisely stated: no `trust: false` is ever passed — the sole KaTeX usage configures no options at all:

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:10
const rehypePlugins = [rehypeKatex];
```

KaTeX's default is untrusted — its settings schema declares `trust` with no default value, and the check coerces the unset value to `false`:

```js
// node_modules/katex/dist/katex.mjs:349-350
var trust = typeof this.trust === "function" ? this.trust(context) : this.trust;
return Boolean(trust);
```

So the *behavior* matches "trust:false", but as the library default rather than an explicit project setting — a later `rehypeKatex` options change would not trip over any explicit hardening.

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:1-42`, `node_modules/katex/dist/katex.mjs:207-211,263-276,349-350`

---

## Claim 11: "File is named proxy.ts because Next.js 16 renamed Middleware to Proxy (middleware.ts builds with a deprecation warning)."

**Location:** commit `9b4e453` (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The installed Next 16.2.4 emits exactly such a warning for `middleware.ts`:

```js
// node_modules/next/dist/esm/build/index.js:583
Log.warnOnce(`The "${MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${PROXY_FILENAME}" instead. ...`);
```

and errors when both files exist (`node_modules/next/dist/esm/build/index.js:575-582`, which throws "Both middleware file ... and proxy file ... are detected" — paraphrased — no quote available because the message string is assembled from template variables across several lines and quotes poorly in fragment form).

**Evidence:** `node_modules/next/dist/esm/build/index.js:570-584`, `package.json:26`

---

## Claim 12: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** commit `9b4e453` (message body)
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** Medium

The first half is consistent with the code — the proxy sets the header on every matched response:

```ts
// proxy.ts:47
response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

The second half is contradicted by Next's renderer: the nonce Next applies to script tags is extracted from the **request** `content-security-policy` header (`node_modules/next/dist/esm/server/app-render/app-render.js:111-112`, quoted in Claim 2), which this proxy never sets — it forwards only `x-nonce` (`proxy.ts:42`). With no request CSP header, the renderer's nonce is `undefined` and no script tag receives one. I could not re-run the claimed prod-build verification (paraphrased — no quote available because build execution is a runtime step outside static analysis), but the static code path makes the claimed observation ("nonce on every <script> tag") unreachable as written; confidence is Medium only because the claim asserts an empirical observation I cannot reproduce here.

**Evidence:** `proxy.ts:41-48`, `node_modules/next/dist/esm/server/app-render/app-render.js:100-112,1502`

---

## Claim 13: "No behavior change; CSP directives preserved exactly" / "the nonce is only written, never read by the layout"

**Location:** commit `d90d6bb` (message body)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High

The `b25e939..d90d6bb` diff touches only comments, adds an explicit `: NextResponse` return type, and inlines the single-use `csp` local:

```diff
-  response.headers.set("Content-Security-Policy", csp);
+  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

(from `git diff b25e939..d90d6bb`, `proxy.ts` hunk). The `buildCsp` directive list is untouched by the commit, so directives are preserved exactly (paraphrased — no quote available because the evidence is the absence of any `buildCsp` hunk in the diff). And "only written, never read": `x-nonce` is set at `proxy.ts:42` and no other code in the repository reads it (paraphrased — no quote available because the claim covers absence of code — no matching grep results outside the write site and a comment).

**Evidence:** `git diff b25e939..d90d6bb`, `proxy.ts:19-32,42`, `app/layout.tsx:27-31`

---

## Claim 14: "Lint clean; 221/221 tests pass."

**Location:** commit `d90d6bb` (message body)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low

Confirming this requires executing `eslint` and `vitest run` (paraphrased — no quote available because the claim is about tool-run outcomes, not code content), which I did not do in this read-only pass — test execution writes cache state and the exact pass count (221) cannot be established statically. Verification would need `npm run lint && npm test` at `d90d6bb`.

**Evidence:** `package.json:8-12`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`app/layout.tsx:28-30`): Next reads the nonce from the *request's* CSP header, which the proxy never sets — bootstrap scripts get no nonce; fix by also setting `Content-Security-Policy` on the forwarded request headers.
- **Claim 5** (`proxy.ts:12-14`): Tailwind v4 ships a compiled stylesheet here; the `'unsafe-inline'` pressure comes from React `style={}` attributes (and dev-mode style injection), not Tailwind.
- **Claim 6** (`proxy.ts:16-17`): `connect-src 'self'` is not sufficient — the client-side graph export fetches a `data:` URL, which `'self'` blocks; also, no OpenAlex integration exists in the repo.
- **Claim 7** (`proxy.ts:35-36`): Next 16 proxy always runs on the Node.js runtime, not Edge (the APIs are still available, but the runtime attribution is wrong).
- **Claim 12** (commit `9b4e453`): "Next applies the nonce to every <script> tag" is unreachable as coded — the nonce never reaches the renderer.

### Stale
- (none)

### Mostly Accurate
- **Claim 1** (`app/layout.tsx:27-28`): the proxy runs regardless; `headers()` buys per-request page rendering so the HTML stays in sync with the fresh nonce.
- **Claim 4** (`proxy.ts:7-10`): correct `'strict-dynamic'` semantics, but no script actually gets nonce-tagged in this codebase (see Claim 2).
- **Claim 8** (`proxy.ts:39-40`): the forwarding works, but nothing consumes `x-nonce`; note the capability is unused.
- **Claim 9** (`proxy.ts:52-54`): "page navigations only" overstates — public assets (e.g., `/window.svg`) still match.
- **Claim 10** (commit `9b4e453`): "KaTeX trust:false" is the library default, not an explicit project setting.

### Unverifiable
- **Claim 14** (commit `d90d6bb`): needs `npm run lint && npm test` at `d90d6bb` to confirm "Lint clean; 221/221 tests pass".
