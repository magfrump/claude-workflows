# Code Fact-Check Report
Commit: d90d6bb

**Repository:** `/workspace/external/cc-review-eval/mfc-csp`
**Scope:** `git diff main...review` — `app/layout.tsx`, `proxy.ts` — plus commit messages in `git log main..review` (9b4e453, b25e939, d90d6bb)
**Checked:** 2026-08-15
**Total claims checked:** 17
**Summary:** 5 verified, 5 mostly accurate, 0 stale, 6 incorrect, 1 unverifiable

---

## Claim 1: "Opt this layout out of static rendering so proxy.ts runs on every request and can attach a fresh per-request CSP nonce."

**Location:** `app/layout.tsx:27-28`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** High

The comment asserts a causal chain: `await headers()` → layout is dynamic → the proxy runs per request. The second link does not hold. Next.js runs the proxy for every request matching `config.matcher`, independent of whether the matched route renders statically or dynamically; the matcher is the only gate:

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

Nothing in `proxy.ts` or `next.config.ts` conditions proxy execution on the render mode — `next.config.ts` declares no options at all:

```ts
// next.config.ts:3-5
const nextConfig: NextConfig = {
  /* config options here */
};
```

The half of the claim that does hold is that calling a dynamic API opts the route out of static rendering (`await headers()` at `app/layout.tsx:31`). What that actually buys is that the *rendered HTML* is regenerated per request, so the `nonce` embedded in the markup matches the `nonce` in the response header instead of being frozen into a prerendered document — not that it causes the proxy to run.

**Evidence:** `app/layout.tsx:27-31`, `proxy.ts:51-63`, `next.config.ts:1-7`

---

## Claim 2: "Next.js automatically tags its own bootstrap `<script>` elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

Next.js does auto-nonce its bootstrap scripts, but it reads the CSP from the **request** headers, not the response headers. In the installed Next 16.2.4, the nonce is extracted inside `parseRequestHeaders`:

```js
// node_modules/next/dist/server/app-render/app-render.js:155
function parseRequestHeaders(headers, options) {
```

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
    const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
    const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

`getScriptNonceFromHeader` then parses `script-src` (falling back to `default-src`) for a `'nonce-…'` source:

```js
// node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:18
    const directive = directives.find((dir)=>dir.startsWith('script-src')) || directives.find((dir)=>dir.startsWith('default-src'));
```

`proxy.ts` sets the CSP only on the response object, and puts only `x-nonce` (not the CSP) onto the forwarded request headers:

```ts
// proxy.ts:41-47
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

So `headers['content-security-policy']` is undefined during render, `nonce` resolves to `undefined`, and Next's bootstrap scripts are emitted without a `nonce` attribute. The stated reason for not reading `x-nonce` in the layout therefore does not hold as written.

**Evidence:** `app/layout.tsx:27-31`, `proxy.ts:41-47`, `node_modules/next/dist/server/app-render/app-render.js:155-167`, `node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:12-30`

---

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy)"

**Location:** `proxy.ts:5`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High

The project pins Next 16.2.4:

```json
// package.json:19
    "next": "16.2.4",
```

and that version treats `middleware` as the superseded name for `proxy`:

```js
// node_modules/next/dist/build/index.js:651
                _log.warnOnce(`The "${_constants.MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${_constants.PROXY_FILENAME}" instead. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`);
```

The root-level `proxy.ts` filename is a recognized proxy file location:

```js
// node_modules/next/dist/build/utils.js:1130-1132
function isProxyFile(file) {
    return file === `/${_constants.PROXY_FILENAME}` || file === `/src/${_constants.PROXY_FILENAME}`;
}
```

**Evidence:** `package.json:19`, `node_modules/next/dist/build/index.js:645-651`, `node_modules/next/dist/build/utils.js:1130-1132`

---

## Claim 4: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust."

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The CSP-semantics half is right, and the emitted directive does pair a nonce with `strict-dynamic`:

```ts
// proxy.ts:22
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```

The premise that "Next.js has explicitly tagged" its scripts with *this* nonce does not hold in this wiring — see Claim 2: Next reads the nonce from the request's CSP header, and `proxy.ts:41-47` never places the CSP there. Precisely stated, the directive is what the comment describes, but under the current wiring the set of nonce-tagged scripts is empty rather than "Next's bootstrap scripts."

**Evidence:** `proxy.ts:7-10`, `proxy.ts:22`, `proxy.ts:41-47`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** `proxy.ts:12-14`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** High

Tailwind v4 is wired here as a PostCSS plugin that compiles into the imported stylesheet — not as an inline-style emitter:

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

`app/globals.css` is imported as a stylesheet by the layout, so Tailwind's output reaches the page as a linked CSS file, which `style-src 'self'` already covers:

```tsx
// app/layout.tsx:4
import "./globals.css";
```

The installed version confirms v4 (`node_modules/tailwindcss/package.json:3`: `"version": "4.2.4"`). What does require `'unsafe-inline'` in this app is inline `style={...}` attributes rendered by components — present in 20+ component files, e.g.:

```tsx
// app/components/features/proof-graph/ProofGraphNode.tsx — 4 occurrences of `style={`
```

(paraphrased — no quote available because the assertion is about the aggregate count of `style={` occurrences across 20+ files rather than any single snippet; the grep `rg -c "style=\{" app --glob '*.tsx'` reports matches in `ProofGraphNode.tsx` (4), `EditableOutput.tsx` (3), `GraphPanel.tsx` (2), and ~17 others.)

The mechanism the comment names is therefore misattributed; the carve-out is real but is driven by React inline style attributes (and third-party runtime style injection from `reactflow`/`katex`), not by Tailwind.

**Evidence:** `proxy.ts:12-14`, `proxy.ts:23`, `postcss.config.mjs:1-5`, `app/globals.css:1-2`, `app/layout.tsx:4`, `node_modules/tailwindcss/package.json:3`

---

## Claim 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:16-17`
**Type:** Architectural / Behavioral
**Verdict:** Incorrect
**Confidence:** High

The server-to-server half checks out: the OpenRouter and Anthropic calls live in `app/lib/llm/`, whose only importers are API route handlers:

```ts
// app/lib/llm/callLlm.ts:164
    const response = await fetch(OPENROUTER_API_URL, {
```

Importers of `callLlm`/`streamLlm` outside `app/lib/llm/` are all under `app/api/` plus `app/lib/formalization/` (paraphrased — no quote available because the assertion covers the absence of client-component importers across the whole tree; `rg -l "callLlm|streamLlm" app` returns only `app/api/**/route.ts` files and `app/lib/{llm,formalization}` modules, none of which carry a `"use client"` directive).

But the sufficiency conclusion is contradicted by a browser-side fetch to a non-`'self'` URL. `downloadGraphAsPng` and `graphToPngBlob` run in the browser (they read from `document`) and fetch a `data:` URL produced by `html-to-image`:

```ts
// app/lib/utils/exportGraph.ts:20-25
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
```

```ts
// app/lib/utils/exportGraph.ts:10-12
export function getGraphViewportElement(): HTMLElement | null {
  return document.querySelector<HTMLElement>(".react-flow__viewport");
}
```

`connect-src 'self'` does not permit `data:` in fetch position (the emitted directive is exactly `"connect-src 'self'"`, `proxy.ts:26`), so this is a browser-side request the stated rationale does not account for. Note the sibling directives *do* carve out these schemes for other fetch contexts — `"img-src 'self' data: blob:"` (`proxy.ts:24`) — which makes the `connect-src` omission the specific gap.

Separately, "OpenAlex" has no referent in this codebase: it appears nowhere outside this comment and commit 9b4e453 (paraphrased — no quote available because the claim covers the absence of code; case-insensitive `rg -i openalex` over the repo excluding `node_modules` and lockfiles returns exactly one hit, `proxy.ts:16`).

**Evidence:** `proxy.ts:16-17`, `proxy.ts:24`, `proxy.ts:26`, `app/lib/utils/exportGraph.ts:10-12`, `app/lib/utils/exportGraph.ts:20-37`, `app/lib/llm/callLlm.ts:7`, `app/lib/llm/callLlm.ts:164`, `app/lib/llm/streamLlm.ts:249`

---

## Claim 7: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in."

**Location:** `proxy.ts:35-36`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High

The proxy does not run in the Edge runtime under Next 16.2.4. Next's own build-time check states the rule and rejects any attempt to declare otherwise:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:573-576
    if ((0, _utils.isProxyFile)(page) && resolvedRuntime) {
        ...
        const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

`proxy.ts` declares no runtime of its own — there is no `export const runtime` in the file (paraphrased — no quote available because the claim covers the absence of code; the full 64-line file is reproduced across the other claims in this report and contains only the `buildCsp`, `proxy`, and `config` exports).

The API-availability half of the claim is unaffected: both `crypto.randomUUID` and `Buffer` exist in the Node.js runtime this actually runs in, so `proxy.ts:37` works. Only the named runtime is wrong. This wording was introduced in `d90d6bb`, which widened an already-incorrect Edge-runtime attribution from the prior revision.

**Evidence:** `proxy.ts:34-37`, `node_modules/next/dist/build/analysis/get-page-static-info.js:573-576`, `node_modules/next/dist/build/utils.js:1130-1132`

---

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to `<Script>` tags they render."

**Location:** `proxy.ts:39-40`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High

The forwarding mechanism itself is real:

```ts
// proxy.ts:41-46
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
```

But no consumer exists on either half of the stated purpose. `x-nonce` is never read anywhere in the repository, and no `<Script>` component is rendered anywhere (paraphrased — no quote available because both assertions cover the absence of code: `rg -n "x-nonce" .` excluding `node_modules` returns only `proxy.ts:42` and the comment text at `app/layout.tsx:30` and `proxy.ts:39`; `rg -n "next/script|<Script" app` returns zero matches).

The only `next/headers` consumer in the tree does not read the header:

```tsx
// app/layout.tsx:3
import { headers } from "next/headers";
```

```tsx
// app/layout.tsx:31
  await headers();
```

The return value is discarded. Commit `d90d6bb`'s own message acknowledges this ("the nonce is only written, never read by the layout") while leaving this comment's forward-looking rationale in place.

**Evidence:** `proxy.ts:39-46`, `app/layout.tsx:3`, `app/layout.tsx:31`

---

## Claim 9: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)."

**Location:** `proxy.ts:52-54`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High

Each named exclusion is present in the pattern, and the prefetch header keys are the ones Next actually sends:

```ts
// proxy.ts:56-61
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```

```js
// node_modules/next/dist/client/components/app-router-headers.js:106
const NEXT_ROUTER_PREFETCH_HEADER = 'next-router-prefetch';
```

Two imprecisions in "page navigations only":

1. `_next/static` and `_next/image` are excluded, but static files served from `public/` are not — the negative lookahead does not cover them, so requests for `/file.svg`, `/globe.svg`, `/next.svg`, `/vercel.svg`, and `/window.svg` still match and receive a CSP header (paraphrased — no quote available because the assertion is about directory contents rather than a snippet: `ls public` lists exactly those five `.svg` files, none of which appear in the lookahead at `proxy.ts:57`).
2. The lookahead is prefix-based, not segment-bounded: `(?!api|…)` excludes any path whose first segment merely *begins with* `api` (e.g. `/apidocs`), not only `/api/...`. The precise version would say the matcher skips paths beginning with those strings.

**Evidence:** `proxy.ts:51-63`, `node_modules/next/dist/client/components/app-router-headers.js:106`, `public/`

---

## Claim 10 (commit 9b4e453): "File is named proxy.ts because Next.js 16 renamed Middleware to Proxy (middleware.ts builds with a deprecation warning)."

**Location:** `git log main..review` — commit 9b4e453
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High

Next 16.2.4 emits exactly the described warning rather than an error when only `middleware.ts` is present:

```js
// node_modules/next/dist/build/index.js:651
                _log.warnOnce(`The "${_constants.MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${_constants.PROXY_FILENAME}" instead. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`);
```

(Having both files present is a hard error instead — `node_modules/next/dist/build/index.js:645` — but that case does not apply here.)

**Evidence:** `node_modules/next/dist/build/index.js:645-651`, `package.json:19`

---

## Claim 11 (commit 9b4e453): "The matcher skips /api routes, _next/static, and prefetches so we don't burn nonces on requests that don't render HTML."

**Location:** `git log main..review` — commit 9b4e453
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The three named exclusions are present in `proxy.ts:56-61` (quoted under Claim 9). The precise version would add that `_next/image` and `favicon.ico` are also excluded while `public/` assets are not, and that the `api` exclusion is prefix-based — see Claim 9 for the evidence on both points.

**Evidence:** `proxy.ts:51-63`, `public/`

---

## Claim 12 (commit 9b4e453): "Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached."

**Location:** `git log main..review` — commit 9b4e453
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The layout does call the dynamic API, which opts the route out of static rendering:

```tsx
// app/layout.tsx:22-31
export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  // Opt this layout out of static rendering so proxy.ts runs on every request
  ...
  await headers();
```

"Reads headers()" overstates what the code does — the call's return value is discarded at `app/layout.tsx:31`, so the layout invokes the API without reading anything from it. The stated reason (a per-request nonce cannot be baked into cached HTML) is the correct rationale, and is notably *more* accurate than the in-file comment version fact-checked as Claim 1, which instead attributes the opt-out to making the proxy run.

**Evidence:** `app/layout.tsx:22-31`

---

## Claim 13 (commit 9b4e453): "style-src keeps 'unsafe-inline' as a deliberate carve-out for Tailwind v4."

**Location:** `git log main..review` — commit 9b4e453
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High

The directive is present as described:

```ts
// proxy.ts:23
    "style-src 'self' 'unsafe-inline'",
```

The attribution to Tailwind v4 is the same misattribution fact-checked in Claim 5: Tailwind v4 is configured as a PostCSS plugin compiling into `app/globals.css` (`postcss.config.mjs:1-5`, `app/globals.css:1-2`), which `'self'` already covers. The carve-out is driven by React inline `style={...}` attributes across the component tree.

**Evidence:** `proxy.ts:23`, `postcss.config.mjs:1-5`, `app/globals.css:1-2`

---

## Claim 14 (commit 9b4e453): "connect-src is just 'self' because all external API calls (Anthropic, OpenAlex, OpenRouter) go server-to-server, never browser-to-third-party."

**Location:** `git log main..review` — commit 9b4e453
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High

Same finding as Claim 6. The LLM provider calls are server-side (`app/lib/llm/callLlm.ts:164`, `app/lib/llm/streamLlm.ts:249`, reached only from `app/api/**/route.ts`), but the browser-side `fetch(dataUrl)` on a `data:` URL at `app/lib/utils/exportGraph.ts:24` and `:37` is a browser fetch that `connect-src 'self'` does not permit, and "OpenAlex" names no code in this repository. Evidence quoted under Claim 6.

**Evidence:** `app/lib/utils/exportGraph.ts:20-37`, `proxy.ts:26`, `app/lib/llm/callLlm.ts:164`

---

## Claim 15 (commit 9b4e453): "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)."

**Location:** `git log main..review` — commit 9b4e453
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The first two conjuncts hold: neither `dangerouslySetInnerHTML` nor `rehype-raw` appears anywhere in `app/` or in the dependency list (paraphrased — no quote available because both assertions cover the absence of code: `rg -n "dangerouslySetInnerHTML" app` and `rg -n "rehype-raw|rehypeRaw" app package.json` each return zero matches).

The third is true in effect but imprecise as written — `trust: false` is never passed; `rehypeKatex` is registered with no options at all:

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:10
const rehypePlugins = [rehypeKatex];
```

KaTeX's `trust` setting has no configured default in its option spec and is coerced with `Boolean`, so an unset value evaluates to `false`:

```js
// node_modules/katex/dist/katex.mjs:349-350
    var trust = typeof this.trust === "function" ? this.trust(context) : this.trust;
    return Boolean(trust);
```

The precise version would say KaTeX is left at its default (untrusted) rather than explicitly configured `trust: false`.

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:6-10`, `node_modules/katex/dist/katex.mjs:207-211`, `node_modules/katex/dist/katex.mjs:349-350`, `package.json:12-38`

---

## Claim 16 (commit 9b4e453): "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates."

**Location:** `git log main..review` — commit 9b4e453
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

The first half holds — `proxy.ts:47` sets the header on the response unconditionally for matched requests:

```ts
// proxy.ts:47
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

The second half is contradicted by the same code path as Claim 2: Next reads the nonce from `headers['content-security-policy']` in `parseRequestHeaders` (`node_modules/next/dist/server/app-render/app-render.js:166-167`), and `proxy.ts:41-46` forwards only `x-nonce` on the request while placing the CSP solely on the response. With no CSP on the request, `nonce` is `undefined` at render and Next's generated `<script>` tags carry no nonce attribute.

**Evidence:** `proxy.ts:41-47`, `node_modules/next/dist/server/app-render/app-render.js:155-167`, `node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:12-30`

---

## Claim 17 (commit d90d6bb): "proxy.ts: add explicit return type, inline single-use csp local. … No behavior change; CSP directives preserved exactly. Lint clean; 221/221 tests pass."

**Location:** `git log main..review` — commit d90d6bb
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** Medium

The diff from `9b4e453` to `d90d6bb` matches the description exactly — a `: NextResponse` return annotation added and the `csp` local inlined:

```diff
// git diff 9b4e453 d90d6bb -- proxy.ts
-export function proxy(request: NextRequest) {
+export function proxy(request: NextRequest): NextResponse {
...
-  const csp = buildCsp(nonce);
...
-  response.headers.set("Content-Security-Policy", csp);
+  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

The `buildCsp` directive array is untouched by that diff, so "CSP directives preserved exactly" holds (`proxy.ts:20-30` is outside the changed hunks). The `221` figure matches the repository's test-case count (paraphrased — no quote available because the assertion is an aggregate over all `*.test.ts*` files rather than a snippet: `rg -c "\bit\(|\btest\(" --glob '*.test.ts*' app` summed across files yields 221). Confidence is Medium rather than High because the pass/lint status itself was not re-executed — see Claim 17a below.

The companion `layout.tsx` clause ("the nonce is only written, never read by the layout") is accurate and consistent with Claim 8: `x-nonce` is set at `proxy.ts:42` and read nowhere.

**Evidence:** `proxy.ts:19-32`, `proxy.ts:34-48`, git range `9b4e453..d90d6bb`

---

## Claim 17a (commit d90d6bb): "Lint clean; 221/221 tests pass."

**Location:** `git log main..review` — commit d90d6bb
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** High

The declared count of 221 is corroborated statically (see Claim 17), but green status for `npm run lint` and `npm run test` cannot be established without executing them:

```json
// package.json:8-10
    "lint": "eslint",
    "test": "vitest run",
```

Verifying would require running both commands at `d90d6bb`, which is out of scope for static analysis.

**Evidence:** `package.json:8-10`

---

## Claim 18 (commit b25e939): "correct layout comment to reference proxy.ts (renamed from middleware.ts)"

**Location:** `git log main..review` — commit b25e939
**Type:** Reference / Staleness
**Verdict:** Mostly accurate
**Confidence:** High

The comment edit itself is exactly as described:

```diff
// git show b25e939 -- app/layout.tsx
-  // Read the per-request CSP nonce that middleware.ts forwards via x-nonce.
+  // Read the per-request CSP nonce that proxy.ts forwards via x-nonce.
```

The parenthetical "(renamed from middleware.ts)" reads as a file rename in this repository, but no `middleware.ts` has ever existed here (paraphrased — no quote available because the claim covers the absence of a file across history: `git log --all --oneline -- middleware.ts src/middleware.ts` returns no commits). The rename is the Next.js framework convention change (Claim 10), not a rename of a file in this tree — the CSP proxy was introduced directly as `proxy.ts` in `9b4e453`, one commit earlier.

**Evidence:** git commits `b25e939`, `9b4e453`; `proxy.ts` (added in `9b4e453`)

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`app/layout.tsx:27-28`): `await headers()` does not cause `proxy.ts` to run — the proxy runs on every matcher-matched request regardless of render mode; the opt-out exists so the nonce in the HTML matches the nonce in the header.
- **Claim 2** (`app/layout.tsx:28-30`): Next reads the nonce from the **request's** CSP header (`parseRequestHeaders`), not the response's; `proxy.ts` sets the CSP only on the response, so Next's bootstrap scripts get no nonce.
- **Claim 5** (`proxy.ts:12-14`): Tailwind v4 is a PostCSS plugin compiling into `app/globals.css`, not an inline-style emitter; `'unsafe-inline'` is needed for React `style={...}` attributes (20+ components) and third-party runtime style injection.
- **Claim 6** (`proxy.ts:16-17`): `connect-src 'self'` is not sufficient — `app/lib/utils/exportGraph.ts:24,37` does a browser-side `fetch()` on a `data:` URL; also "OpenAlex" appears nowhere else in the repository.
- **Claim 7** (`proxy.ts:35-36`): Next 16 proxy always runs on the **Node.js** runtime, not Edge ("Proxy always runs on Node.js runtime", `get-page-static-info.js:576`). The APIs named are available, but the runtime is wrong.
- **Claim 8** (`proxy.ts:39-40`): nothing reads `x-nonce` and no `<Script>` component exists anywhere in the repo; the stated purpose has no consumer.
- **Claim 13** (commit 9b4e453): same Tailwind misattribution as Claim 5.
- **Claim 14** (commit 9b4e453): same `connect-src` gap as Claim 6.
- **Claim 16** (commit 9b4e453): the CSP header is emitted, but Next does not nonce the generated `<script>` tags under this wiring.

### Stale
- None.

### Mostly Accurate
- **Claim 4** (`proxy.ts:7-10`): CSP semantics described correctly, but the premise that Next tags its scripts with this nonce does not hold — tighten to describe the directive, not the outcome.
- **Claim 9** (`proxy.ts:52-54`): `public/` assets (five `.svg` files) still match and receive the CSP; the `api` exclusion is prefix-based, not segment-bounded.
- **Claim 11** (commit 9b4e453): same two omissions as Claim 9.
- **Claim 12** (commit 9b4e453): "reads headers()" overstates — the return value is discarded; the stated caching rationale is correct.
- **Claim 15** (commit 9b4e453): `trust: false` is never passed to `rehypeKatex`; KaTeX is left at its untrusted default.
- **Claim 18** (commit b25e939): no `middleware.ts` ever existed in this repo — the rename is Next.js's framework convention, not a file rename here.

### Unverifiable
- **Claim 17a** (commit d90d6bb): "Lint clean; 221/221 tests pass" — the 221 count is corroborated statically, but pass/lint status requires running `npm run lint` and `npm run test` at `d90d6bb`.
