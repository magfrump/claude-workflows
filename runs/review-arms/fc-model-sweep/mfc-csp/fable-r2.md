# Code Fact-Check Report
Commit: d90d6bb

**Repository:** /workspace/external/cc-review-eval/mfc-csp
**Scope:** `git diff main...review` — `app/layout.tsx`, `proxy.ts`, plus commit messages `main..review`
**Checked:** 2026-08-15
**Total claims checked:** 14
**Summary:** 3 verified, 6 mostly accurate, 0 stale, 5 incorrect, 0 unverifiable

---

## Claim 1: "Opt this layout out of static rendering so proxy.ts runs on every request and can attach a fresh per-request CSP nonce."

**Location:** `app/layout.tsx:27-28`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The mechanism used is real: the layout awaits `headers()` with no other use of the result:

```tsx
// app/layout.tsx:27-31
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
  await headers();
```

Calling `headers()` in a server component does opt the route into dynamic rendering (paraphrased — no quote available because this is documented Next.js framework behavior, not app code; `headers` is imported from `next/headers` at `app/layout.tsx:3`).

The stated *reason* is imprecise: the proxy runs on every matched request regardless of whether the page is statically or dynamically rendered — the matcher in `proxy.ts:55-63` gates on request path and headers, not on rendering mode (paraphrased — no quote available because the claim covers absence of any rendering-mode condition in the matcher config). What dynamic rendering actually buys is that the *HTML render* happens per request, so a per-request nonce is not baked into cached static HTML. The proxy attaching the response header never depended on this opt-out. The precise version would be: "opt out of static rendering so the page HTML is re-rendered per request and can carry the fresh nonce."

**Evidence:** `app/layout.tsx:3`, `app/layout.tsx:27-31`, `proxy.ts:50-63`

---

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

Next.js extracts the nonce from the **request** headers, not the response's CSP header. In this project's installed Next.js (16.2.4), the app renderer's `parseRequestHeaders` does:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

The `headers` object there is the incoming request's headers — the same function parses request-only headers like the prefetch header on the adjacent lines (paraphrased — no quote available because the request-header provenance is established by the surrounding function `parseRequestHeaders` at `node_modules/next/dist/server/app-render/app-render.js:155-167`, which reads `Next-Router-Prefetch` and RSC request headers from the same object).

The proxy, however, sets the CSP header only on the **response**, and forwards only `x-nonce` on the request:

```ts
// proxy.ts:41-48
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

No `Content-Security-Policy` header is ever set on `requestHeaders` (paraphrased — no quote available because the claim covers absence of code: `grep -n "Content-Security-Policy" proxy.ts` matches only the response-header line 47). So the renderer's `csp` lookup finds nothing, `nonce` is `undefined`, and Next.js does not tag its bootstrap scripts with the nonce. Both the stated mechanism ("from the response's CSP header") and the stated consequence ("so we don't need to read x-nonce here ourselves" — i.e., the scripts get tagged anyway) are contradicted by the code as wired.

**Evidence:** `node_modules/next/dist/server/app-render/app-render.js:155-167`, `node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:23-41`, `proxy.ts:41-48`

---

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy)" / commit 9b4e453: "middleware.ts builds with a deprecation warning"

**Location:** `proxy.ts:5` (also commit `9b4e453` message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The installed Next.js 16.2.4 build emits exactly this deprecation for the old filename:

```js
// node_modules/next/dist/build/index.js:651
_log.warnOnce(`The "${_constants.MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${_constants.PROXY_FILENAME}" instead. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`);
```

**Evidence:** `node_modules/next/dist/build/index.js:645-651`, `package.json:26` (`"next": "16.2.4"`)

---

## Claim 4: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust."

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The description of CSP `nonce` + `'strict-dynamic'` semantics is correct in the abstract, and the policy string does contain both:

```ts
// proxy.ts:22
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```

But the premise that Next.js tags its scripts with this nonce does not hold in this codebase: as established in Claim 2, Next.js reads the nonce from the request's `Content-Security-Policy` header, which this proxy never sets, so no scripts get tagged (paraphrased — no quote available because the finding is the cross-file conclusion of Claim 2, with quotes given there). Under the policy as written, that would mean Next's own bootstrap scripts fail the nonce check too — the claim describes the intended design, not the behavior of the code as wired.

**Evidence:** `proxy.ts:20-30`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles."

**Location:** `proxy.ts:12-14`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** Medium

Tailwind v4 in this project is wired as a PostCSS-compiled stylesheet, not an inline-style emitter:

```css
/* app/globals.css:1-2 */
@import "tailwindcss";
@plugin "@tailwindcss/typography";
```

with `@tailwindcss/postcss` as the build plugin (`package.json:36`, devDependency `"@tailwindcss/postcss": "^4"`). Its output ships as compiled CSS through Next's asset pipeline — an external stylesheet covered by `style-src 'self'`, not inline styles (paraphrased — no quote available because the claim concerns build-pipeline output, not a quotable source line; the wiring is `postcss.config.mjs` plus the `@import` above).

What actually depends on `'unsafe-inline'` in this app is elsewhere: the app's own components use React inline `style={{...}}` attributes in 30 places across files such as `app/components/panels/GraphPanel.tsx` and `app/components/features/proof-graph/ProofGraphNode.tsx` (paraphrased — no quote available because the evidence is a grep count spanning ~20 files: `grep -rn "style={{" app --include="*.tsx"` → 30 non-test hits), and Next injects `<style>` elements for CSS in development. The carve-out may still be needed, but the attributed mechanism ("Tailwind v4 emits inline styles") does not match how this project's Tailwind ships styles.

**Evidence:** `app/globals.css:1-2`, `package.json:36-50`, `postcss.config.mjs`

---

## Claim 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:16-17`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High

The server-to-server half checks out for the APIs that exist. The Anthropic SDK and the OpenRouter fetch live in `app/lib/llm/callLlm.ts` / `app/lib/llm/streamLlm.ts`, which import Node-only modules:

```ts
// app/lib/llm/callLlm.ts:1
import { randomUUID } from "crypto";
```

and are imported only by `app/api/**/route.ts` handlers and server route helpers such as `app/lib/formalization/artifactRoute.ts` (paraphrased — no quote available because the evidence is a repo-wide import grep across nine files, all under `app/api/` or server-only libs). Browser-side fetches in components/hooks all target relative `/api/...` paths, e.g.:

```ts
// app/hooks/useAnalytics.ts:11
    fetch("/api/analytics")
```

Two problems make the claim as a whole incorrect:

1. **"OpenAlex" does not exist in this codebase.** A case-insensitive grep for `openalex` across all source files matches only this comment itself (paraphrased — no quote available because the claim covers absence of code: zero grep hits outside `proxy.ts:16`).
2. **"Sufficient" is contradicted by browser-side `data:` fetches.** The graph-export path, called from the client component `app/components/panels/GraphPanel.tsx` (`"use client"` at `GraphPanel.tsx:1`), fetches a `data:` URL:

```ts
// app/lib/utils/exportGraph.ts:20-26
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
```

`connect-src 'self'` does not allow the `data:` scheme, so this `fetch(dataUrl)` (and the same pattern at `app/lib/utils/exportGraph.ts:37`, used by `app/lib/utils/exportAll.ts:64`) would be blocked under this policy. The directive is not sufficient for the browser-side requests the app actually makes.

**Evidence:** `app/lib/llm/callLlm.ts:1,7`, `app/lib/llm/streamLlm.ts:249`, `app/lib/utils/exportGraph.ts:20-38`, `app/lib/utils/exportAll.ts:64`, `app/components/panels/GraphPanel.tsx:1`, `app/hooks/useAnalytics.ts:11`

---

## Claim 7: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in."

**Location:** `proxy.ts:35-36`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High

In Next.js 16 the proxy does not run in the Edge runtime — it always runs on Node.js. The installed framework says so verbatim when rejecting runtime config in a proxy file:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

`proxy.ts` declares no runtime override of its own (paraphrased — no quote available because the claim covers absence of code: no `runtime` export or config key anywhere in the 64-line file). The APIs themselves — `crypto.randomUUID` and `Buffer` — are available in the Node.js runtime, so the line of code works; but the runtime attribution a reader would act on ("this file is Edge, avoid Node APIs") is wrong.

**Evidence:** `node_modules/next/dist/build/analysis/get-page-static-info.js:572-576`, `proxy.ts:34-37`

---

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-40`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The mechanism is real: the header is set on the forwarded request headers, which server components can read via `headers()`:

```ts
// proxy.ts:41-45
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
```

But nothing consumes it: a repo-wide grep for `x-nonce` matches only `proxy.ts:42` and the layout comment at `app/layout.tsx:30`, which explicitly declines to read it (paraphrased — no quote available because the claim covers absence of code — no `headers().get("x-nonce")` or `<Script nonce=...>` exists anywhere in `app/`). The comment describes an available capability, not anything the codebase does; and per Claim 2, forwarding `x-nonce` alone does not deliver the nonce to the place Next.js itself reads it from (the request's `Content-Security-Policy` header).

**Evidence:** `proxy.ts:39-48`, `app/layout.tsx:27-31`

---

## Claim 9: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)."

**Location:** `proxy.ts:52-54`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The matcher does exclude what the comment names:

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

The negative lookahead skips `/api`, `/_next/static`, `/_next/image`, and `/favicon.ico`; the `missing` conditions skip requests carrying the prefetch headers. The prefetch header key matches what this Next version actually sends:

```js
// node_modules/next/dist/client/components/app-router-headers.js:106
const NEXT_ROUTER_PREFETCH_HEADER = 'next-router-prefetch';
```

The "page navigations only" framing is slightly too strong: any non-excluded path also matches — e.g., files served from `public/` other than `favicon.ico`, and any route handler mounted outside `/api` — so those requests get CSP headers too (paraphrased — no quote available because this follows from the regex quoted above matching all paths not in its exclusion list). Harmless, but "only" overstates the precision of the filter.

**Evidence:** `proxy.ts:50-64`, `node_modules/next/dist/client/components/app-router-headers.js:106`

---

## Claim 10: Commit 9b4e453: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit `9b4e453` (message body)
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The first two parts are confirmed absences: greps for `dangerouslySetInnerHTML`, `rehype-raw`, and `rehypeRaw` across `app/` return zero hits (paraphrased — no quote available because the claim covers absence of code — no matching grep results).

The KaTeX part is true by default rather than by configuration. The app passes no options to rehype-katex:

```ts
// app/components/features/output-editing/LatexRenderer.tsx:10
const rehypePlugins = [rehypeKatex];
```

and the installed KaTeX defaults `trust` to `false` — the option schema for `trust` has no `default` key and type `["boolean", "function"]`, and `getDefaultValue` returns `false` for boolean-typed options:

```js
// node_modules/katex/dist/katex.mjs:242-244
  switch (defaultType) {
    case 'boolean':
      return false;
```

So the effective behavior matches, but "KaTeX trust:false" reads as an explicit setting; nothing in the app sets it (paraphrased — no quote available because the claim covers absence of code: no `trust` option appears anywhere in `app/`).

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:6-10`, `node_modules/katex/dist/katex.mjs:207-211,233-244`

---

## Claim 11: Commit 9b4e453: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** commit `9b4e453` (message body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium

The first half is consistent with the code: the proxy sets the header on every matched response:

```ts
// proxy.ts:47
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

The second half is contradicted by the framework source: Next 16.2.4 obtains the nonce for its script tags exclusively from the incoming request's `content-security-policy` header (`node_modules/next/dist/server/app-render/app-render.js:166-167`, quoted in Claim 2), and this proxy never sets that request header (paraphrased — no quote available because the claim covers absence of code — `Content-Security-Policy` appears in `proxy.ts` only on the response at line 47). With no nonce visible to the renderer, Next does not apply the nonce to the `<script>` tags it generates. Confidence is Medium rather than High only because the commit asserts an observed runtime result I did not reproduce; the static evidence that the described mechanism cannot occur as wired is strong. The same commit's remaining implementation notes (matcher skips, `headers()` opt-out, connect-src rationale, Tailwind carve-out) restate the in-file comments assessed in Claims 1, 5, 6, and 9.

**Evidence:** `proxy.ts:41-48`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 12: Commit b25e939: "fix: correct layout comment to reference proxy.ts (renamed from middleware.ts)"

**Location:** commit `b25e939`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The commit's diff changes exactly one comment line in `app/layout.tsx`:

```diff
// git show b25e939 (app/layout.tsx:27)
-  // Read the per-request CSP nonce that middleware.ts forwards via x-nonce.
+  // Read the per-request CSP nonce that proxy.ts forwards via x-nonce.
```

and `proxy.ts` is the file that exists on the branch (paraphrased — no quote available because the claim is about file existence: `proxy.ts` present at repo root, no `middleware.ts`).

**Evidence:** commit `b25e939`, `proxy.ts:1`

---

## Claim 13: Commit d90d6bb: "No behavior change; CSP directives preserved exactly."

**Location:** commit `d90d6bb`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The commit's diff touches only: a comment rewrite in `app/layout.tsx`, an added return type annotation, a comment edit, and inlining of a single-use local in `proxy.ts`:

```diff
// git show d90d6bb (proxy.ts)
-export function proxy(request: NextRequest) {
+export function proxy(request: NextRequest): NextResponse {
...
-  const csp = buildCsp(nonce);
...
-  response.headers.set("Content-Security-Policy", csp);
+  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

No directive string in `buildCsp` is touched by the diff (paraphrased — no quote available because the claim covers absence of changes: `git show d90d6bb` contains no hunk inside the `directives` array). Note the commit also asserts the layout comment now says `headers()` is "not to read x-nonce" — that correction is accurate as far as it goes, though the comment's replacement rationale has its own problems (Claims 1-2).

**Evidence:** commit `d90d6bb`, `proxy.ts:19-31`

---

## Claim 14: Commit d90d6bb: "Lint clean; 221/221 tests pass."

**Location:** commit `d90d6bb`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High

I re-ran both at branch HEAD. `npx vitest run` reports exactly the claimed count (paraphrased — no quote available because the evidence is command output, not source: "Test Files 24 passed (24), Tests 221 passed (221)"). `npx eslint` exits 0 with no errors but emits 2 pre-existing `react-hooks/exhaustive-deps` warnings in `app/hooks/useWorkspacePersistence.ts` (paraphrased — no quote available because the evidence is command output: "✖ 2 problems (0 errors, 2 warnings)"). "Lint clean" is accurate for errors/exit status but overlooks the warnings.

**Evidence:** commit `d90d6bb`, `package.json:8-12` (test/lint scripts)

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`app/layout.tsx:28-30`): Next.js reads the nonce from the *request's* `Content-Security-Policy` header, which the proxy never sets — Next does not tag its bootstrap scripts as claimed; the comment should describe forwarding the CSP on the request headers.
- **Claim 5** (`proxy.ts:12-14`): Tailwind v4 ships compiled external CSS here, not inline styles; `'unsafe-inline'` is actually load-bearing for the app's 30 React `style={{}}` attributes and dev-mode style injection.
- **Claim 6** (`proxy.ts:16-17`): "OpenAlex" appears nowhere in the codebase, and `connect-src 'self'` is not sufficient — client-side `fetch(dataUrl)` in `app/lib/utils/exportGraph.ts:24,37` fetches `data:` URLs the policy blocks.
- **Claim 7** (`proxy.ts:35-36`): Next 16 proxy always runs on the Node.js runtime, not Edge (framework source states this verbatim); the APIs are available, but in Node.
- **Claim 11** (commit `9b4e453`): "Next applies the nonce to every <script> tag" cannot occur as wired — the renderer sees no CSP request header and thus no nonce.

### Stale
- (none)

### Mostly Accurate
- **Claim 1** (`app/layout.tsx:27-28`): dynamic rendering is needed so the *HTML render* is per-request; the proxy runs on every matched request regardless.
- **Claim 4** (`proxy.ts:7-10`): CSP semantics described correctly, but the "Next.js has explicitly tagged" premise fails in this wiring (see Claim 2).
- **Claim 8** (`proxy.ts:39-40`): the forwarding mechanism works, but nothing in the repo consumes `x-nonce`.
- **Claim 9** (`proxy.ts:52-54`): exclusions verified; "page navigations only" overstates — other `public/` files and non-`/api` handlers also match.
- **Claim 10** (commit `9b4e453`): `dangerouslySetInnerHTML`/`rehype-raw` absences confirmed; KaTeX `trust:false` holds by library default, not by any explicit setting.
- **Claim 14** (commit `d90d6bb`): 221/221 tests reproduce; lint exits 0 but with 2 warnings.

### Unverifiable
- (none)
