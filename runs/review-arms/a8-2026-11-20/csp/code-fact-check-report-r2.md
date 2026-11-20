Commit: d90d6bb

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (reviewed worktree `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-csp`, detached HEAD d90d6bb)
**Scope:** d86d2dc..d90d6bb (3 commits; `proxy.ts` new, `app/layout.tsx` modified) plus the three commit messages
**Checked:** 2026-11-19
**Total claims checked:** 24
**Summary:** 14 verified, 2 mostly accurate, 0 stale, 6 incorrect, 2 unverifiable

Notes on method. Framework evidence comes from the Next.js 16.2.4 install at `/workspace/external/cc-review-eval/mfc-csp/node_modules/next` (same version as `package.json` `"next": "16.2.4"`; that checkout's HEAD is also d90d6bb). The reviewed worktree has no `node_modules`. `docs/reviews/hallucination-patterns.md` does not exist in the reviewed repo, so no prior patterns were compared. Paths prefixed `next/dist/` below are relative to that install's `node_modules/next/dist/`.

---

## Claim 1: "Opt this layout out of static rendering"

**Location:** `app/layout.tsx:27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `await headers()` in the root layout makes every route under it dynamically rendered under the current `next.config.ts`; does not establish behavior if `cacheComponents`/PPR is enabled later, and does not cover the "so proxy.ts runs" clause (Claim 2).

```tsx
// app/layout.tsx:22-31 (excerpt ends :31; enclosing RootLayout continues to :42 — read)
export default async function RootLayout({
  ...
  await headers();
```

`headers()` is a request-time dynamic API. `next.config.ts` sets nothing (`const nextConfig: NextConfig = { /* config options here */ };`, `next.config.ts:3-5`), so no `cacheComponents`/PPR mode changes that. No `export const dynamic` exists anywhere in `app/` (paraphrased — no quote available because claim covers absence of code: `rg "^export const (dynamic|revalidate)" app` returned no hits).

**Evidence:** `app/layout.tsx:22-42`, `next.config.ts:1-7`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "so proxy.ts runs on every request and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:27-28`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether static vs dynamic rendering decides if the proxy runs; does not establish Vercel's edge routing behavior beyond Next's own router.

The proxy runs for every request its matcher selects, whether or not the page is statically rendered. In Next's router the middleware/proxy step comes before any filesystem or page lookup:

```js
// next/dist/server/lib/router-utils/resolve-routes.js:57-72 (excerpt ends :72; calculateRoutes continues — read)
// check middleware (using matchers)
{ match: ()=>({}), name: 'middleware' },
...opts.minimalMode ? [] : fsChecker.rewrites.beforeFiles,
...
{ match: ()=>({}), name: 'check_fs' },
```

The real reason dynamic rendering is needed is different: a prerendered HTML document carries scripts stamped at build time, with no nonce or a stale one, so the fresh nonce in the per-request header would match no script. Dynamic rendering is what lets Next stamp each response's nonce into the HTML. The 9b4e453 body states this correctly ("required because per-request nonces can't be cached", Claim 18). A reader following this comment could drop `await headers()` thinking the proxy no longer needs it, or could think a static page has no CSP header. Both are wrong: the header is still sent, and the page's scripts are blocked.

**Evidence:** `next/dist/server/lib/router-utils/resolve-routes.js:48-75`, `next/dist/server/lib/router-utils/resolve-routes.js:319-347`
**Legibility-target:** for-author

---

## Claim 3: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header"

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the self-hosted Node server path (`next start`) in Next 16.2.4; does not establish the Vercel deployment path, where routing is handled by Vercel's own adapter, and does not establish by execution that every emitted script carries the nonce (Claim 17).

Next reads the nonce from the **request** headers it renders with, not from the response:

```js
// next/dist/server/app-render/app-render.js:155-167 (excerpt ends :167; enclosing parseRequestHeaders() continues to :191 — read)
function parseRequestHeaders(headers, options) {
    ...
    const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
    const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

called as `parseRequestHeaders(req.headers, …)` (`app-render.js:1557`). The proxy sets CSP only on the response (`proxy.ts:47`), not in `requestHeaders`. It still works on the Node server because the router copies every non-internal proxy response header onto `req.headers` as well:

```js
// next/dist/server/lib/router-utils/resolve-routes.js:427-445 (excerpt ends :445; enclosing handler continues — read)
for (const [key, value] of Object.entries({
    ...(0, _utils.filterReqHeaders)(middlewareHeaders, _utils.ipcForbiddenHeaders)
})){
    ...
    if (value) {
        resHeaders[key] = value;
        req.headers[key] = value;
    }
}
```

`content-security-policy` is not in `ipcForbiddenHeaders` (`next/dist/server/lib/server-ipc/utils.js:31-41`). The nonce is then passed to `getRequiredScripts(..., nonce, ...)` (`app-render.js:1969`). So the outcome holds on `next start`, but the precise version is: Next parses the CSP header from the request headers, which on the Node server include the proxy's response headers. This depends on an internal copy step; Next's documented pattern also sets the CSP on the forwarded request headers. Whether Vercel's adapter does the same copy could not be checked here.

**Evidence:** `next/dist/server/app-render/app-render.js:155-191`, `next/dist/server/app-render/app-render.js:1557-1561`, `next/dist/server/lib/router-utils/resolve-routes.js:394-445`, `next/dist/server/lib/server-ipc/utils.js:31-58`, `proxy.ts:41-48`
**Legibility-target:** for-author

---

## Claim 4: "so we don't need to read x-nonce here ourselves"

**Location:** `app/layout.tsx:30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the current tree: no app-authored `<script>`/`next/script` that would need a nonce; does not establish that future `<Script>` additions will work without reading it.

There are no `next/script` imports and no `<script>`/`<Script>` elements in `app/` (paraphrased — no quote available because claim covers absence of code: `rg -n "next/script|<script|<Script" app` hit only the comment at `app/layout.tsx:29`).

**Evidence:** `app/layout.tsx:27-31`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: "CSP proxy (Next.js 16 renamed Middleware → Proxy)"

**Location:** `proxy.ts:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file convention and named export in Next 16.2.4; does not cover runtime semantics (Claim 12).

```js
// next/dist/build/index.js:651
_log.warnOnce(`The "${_constants.MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${_constants.PROXY_FILENAME}" instead. ...`);
```

`next/dist/build/analysis/get-page-static-info.js:263` accepts a named `proxy` export, which matches `export function proxy` at `proxy.ts:34`.

**Evidence:** `next/dist/build/index.js:614-651`, `next/dist/build/analysis/get-page-static-info.js:237-299`, `proxy.ts:34`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust. This keeps a hypothetical injected `<script>` tag from executing"

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the semantics of the emitted `script-src` directive in CSP3 browsers; does not establish that the nonce actually reaches every script (Claims 3, 17), and in CSP3 `'self'` is ignored when `'strict-dynamic'` is present, so it only acts as a fallback for older browsers.

```ts
// proxy.ts:22
`script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```

The claim matches standard nonce + `'strict-dynamic'` semantics: parser-inserted scripts without the nonce are blocked, and scripts loaded by trusted scripts are allowed (paraphrased — no quote available because this is CSP-spec semantics, not repo code). The nonce is base64 of a UUID string (`proxy.ts:37`), so it passes Next's escape check (`get-script-nonce-from-header.js` rejects HTML-escape characters).

**Evidence:** `proxy.ts:19-32`, `proxy.ts:37`, `next/dist/server/app-render/get-script-nonce-from-header.js:11-45`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles"

**Location:** `proxy.ts:12-14`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the stated reason, Tailwind v4 output in this project's PostCSS setup; does not establish that `'unsafe-inline'` could be removed (it cannot, for other reasons named below), and does not cover dev-server style injection, which comes from Next/Turbopack, not Tailwind.

Tailwind v4 runs as a PostCSS plugin here and compiles into an external stylesheet:

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

An existing build of this repo (`/workspace/external/cc-review-eval/mfc-csp/.next/static/chunks/0qqafo8jts909.css`) contains the compiled Tailwind utilities as a static `.css` chunk (paraphrased — no quote available because it is minified generated CSS; `rg -c "font-serif|tailwindcss v4"` matched in that file). That build is older (dated Aug 17) and not of this commit.

`'unsafe-inline'` is still needed, but for different reasons: app code has 31 React `style={{…}}` attributes, e.g. `app/components/features/output-editing/LatexRenderer.tsx:32` `style={{ lineHeight: 1.9, fontFamily: "inherit" }}` and `app/components/panels/SemiformalPanel.tsx:77` `style={{ width: \`${Math.round(editWaitEstimate.progress * 100)}%\` }}`. KaTeX HTML output and React Flow transforms also use inline style attributes (paraphrased — no quote available because these are third-party render outputs, not repo source). A maintainer who acts on "it's only Tailwind" would look in the wrong place when trying to tighten `style-src`.

**Evidence:** `postcss.config.mjs:1-7`, `app/globals.css:1-2`, `app/components/features/output-editing/LatexRenderer.tsx:29-40`, `app/components/panels/SemiformalPanel.tsx:77`, `app/components/layout/IconRail.tsx:28`, `app/components/panels/GraphPanel.tsx:215`
**Legibility-target:** for-author

---

## Claim 8a: "Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party"

**Location:** `proxy.ts:16-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the OpenRouter fetch sites (`callLlm`, `streamLlm`) and that only API routes import them; does not establish that no other browser-side fetch exists (Claim 8b refutes that).

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

The only fetches to it are `app/lib/llm/callLlm.ts:164` and `app/lib/llm/streamLlm.ts:249`. These are reached through `app/lib/formalization/artifactRoute.ts:2-4`, which only `app/api/formalization/*/route.ts` import. The single client-side import of `callLlm` is `import type { LlmCallUsage }` (`app/lib/formalization/api.ts:3`), which is erased at compile time. Browser-side fetches outside `app/api` all target same-origin `/api/...` (`ContextInput.tsx:25`, `LeanCodeDisplay.tsx:88`, `formalization/api.ts:104`, `useAnalytics.ts:11`). No OpenAlex or Anthropic URL appears in client code (paraphrased — no quote available because claim covers absence of code: `rg -i "anthropic|openalex"` outside `app/api` hit only `app/lib/llm/*` and type/cost files, none of which fetch).

**Evidence:** `app/lib/llm/callLlm.ts:7`, `app/lib/llm/callLlm.ts:164`, `app/lib/llm/streamLlm.ts:249`, `app/lib/formalization/artifactRoute.ts:1-4`, `app/lib/formalization/api.ts:3`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8b: "`connect-src 'self'` is sufficient"

**Location:** `proxy.ts:16`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers browser-side `fetch()` calls in `app/`; does not establish by execution in a browser, and does not cover connections made by pdf.js workers.

The browser fetches a `data:` URL, and `connect-src 'self'` does not allow the `data:` scheme:

```ts
// app/lib/utils/exportGraph.ts:16-27 (full function)
export async function downloadGraphAsPng(
  viewportElement: HTMLElement,
  filename = "proof-graph.png",
) {
  const dataUrl = await toPng(viewportElement, { pixelRatio: 2, backgroundColor: EXPORT_BG });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
  triggerDownload(blob, filename);
}
```

`graphToPngBlob` does the same at `app/lib/utils/exportGraph.ts:37`. The PNG-export button's handler calls this (`app/components/panels/GraphPanel.tsx:98-110`), and so does the zip export (`app/lib/utils/exportAll.ts:10`). Under this policy, `fetch(dataUrl)` is a CSP violation and rejects. The GraphPanel handler only logs it with `console.error("[graph export]", err)`, so graph PNG export, and any zip export that includes the graph, fail silently. `html-to-image`'s own `fetch(url)` for fonts and images (`node_modules/html-to-image/lib/embed-webfonts.js:54`, `lib/dataurl.js:56`) is same-origin here and is allowed.

**Evidence:** `app/lib/utils/exportGraph.ts:16-39`, `app/components/panels/GraphPanel.tsx:98-110`, `app/lib/utils/exportAll.ts:10`, `proxy.ts:26`
**Legibility-target:** for-author

---

## Claim 9a: "available in the Edge runtime that Next proxy runs in"

**Location:** `proxy.ts:35-36`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which runtime Next 16.2.4 uses for `proxy.ts`; does not cover `middleware.ts`, which can still choose Edge.

In Next 16, Proxy always runs on the Node.js runtime:

```js
// next/dist/build/analysis/get-page-static-info.js:573-576
if ((0, _utils.isProxyFile)(page) && resolvedRuntime) {
    ...
    const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. ...`;
```

```js
// next/dist/build/index.js:1515-1519
if (staticInfo.runtime === 'nodejs' || (0, _utils1.isProxyFile)(page)) {
    hasNodeMiddleware = true;
    functionsConfigManifest.functions['/_middleware'] = {
        runtime: 'nodejs',
```

The 9b4e453 version of this comment made the same Edge claim. A reader could wrongly avoid Node APIs in the proxy, or wrongly rely on Edge-only behavior.

**Evidence:** `next/dist/build/analysis/get-page-static-info.js:570-580`, `next/dist/build/index.js:1512-1525`
**Legibility-target:** for-author

---

## Claim 9b: "crypto.randomUUID and Buffer are both available"

**Location:** `proxy.ts:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Node.js runtime that Proxy actually uses (Node 22.23.2 in this sandbox); does not cover an Edge runtime, which the proxy does not use.

```ts
// proxy.ts:37
const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

`Buffer` and the global `crypto.randomUUID` are both built into Node ≥19 (paraphrased — no quote available because these are runtime built-ins; `node --version` reports v22.23.2).

**Evidence:** `proxy.ts:34-37`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-42`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the forwarding mechanism and whether anything reads it; does not establish anything about future consumers.

The forwarding mechanism works: `NextResponse.next({ request: { headers: requestHeaders } })` (`proxy.ts:44-46`) sets override headers, and the router applies them to `req.headers` (`resolve-routes.js:396-421`). But nothing reads `x-nonce`. The only `x-nonce` hits in the repo are this write and the layout comment saying it is not read (paraphrased — no quote available because claim covers absence of code: `rg -n "x-nonce"` returned `proxy.ts:42` and `app/layout.tsx:30` only), and no `<Script>` tags exist (Claim 4). The comment describes a consumer that does not exist. Precise version: "exposed for any future `<Script>`; currently unread."

**Evidence:** `proxy.ts:39-48`, `app/layout.tsx:27-31`, `next/dist/server/lib/router-utils/resolve-routes.js:396-421`
**Legibility-target:** for-author

---

## Claim 11: "Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches"

**Location:** `proxy.ts:52-61`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `/api*`, `/_next/static*` and requests with `next-router-prefetch` or `purpose: prefetch` headers are excluded; does not establish that only these are excluded. The lookahead also excludes `/_next/image` and `/favicon.ico`, and since `api` is unanchored it excludes any path starting with `/api` (for example a future `/apiary` page would get no CSP). RSC navigation requests (`rsc` header, no prefetch header) still run the proxy.

```ts
// proxy.ts:57-61
source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
missing: [
  { type: "header", key: "next-router-prefetch" },
  { type: "header", key: "purpose", value: "prefetch" },
],
```

**Evidence:** `proxy.ts:51-64`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "File is named proxy.ts because Next.js 16 renamed Middleware to Proxy (middleware.ts builds with a deprecation warning)."

**Location:** commit 9b4e453 body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rename and the warning text in Next 16.2.4; does not cover differences in runtime between the two conventions (Claim 9a).

```js
// next/dist/build/index.js:651
_log.warnOnce(`The "${_constants.MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${_constants.PROXY_FILENAME}" instead. ...`);
```

**Evidence:** `next/dist/build/index.js:651`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false"

**Location:** commit 9b4e453 body
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `app/` source at d90d6bb; KaTeX `trust` is false by KaTeX's default, not set explicitly (`rehypePlugins = [rehypeKatex]` with no options). Does not cover third-party libraries' internal use of innerHTML.

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:6-10
import rehypeKatex from "rehype-katex";
...
const rehypePlugins = [rehypeKatex];
```

`rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw|innerHTML" app` returned no hits (paraphrased — no quote available because claim covers absence of code).

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:1-40`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "The matcher skips /api routes, _next/static, and prefetches so we don't burn nonces on requests that don't render HTML."

**Location:** commit 9b4e453 body
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 11, including the same residue (unanchored `api` prefix; `_next/image` and `favicon.ico` also excluded).

See the `proxy.ts:57-61` quote in Claim 11.

**Evidence:** `proxy.ts:51-64`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached."

**Location:** commit 9b4e453 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reason and the mechanism; does not establish anything about cacheComponents/PPR configurations.

See Claim 1 (`app/layout.tsx:31` `await headers();`) and Claim 2 for why per-request nonces require per-request HTML.

**Evidence:** `app/layout.tsx:22-42`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "style-src keeps 'unsafe-inline' as a deliberate carve-out for Tailwind v4 ... tightening would require reworking how Tailwind ships styles in dev/SSR" / "connect-src is just 'self' because all external API calls ... go server-to-server, never browser-to-third-party."

**Location:** commit 9b4e453 body
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same findings as Claims 7 and 8b, repeated in the commit body; the server-to-server part on its own is Verified (Claim 8a).

The commit body repeats both refuted rationales. Tailwind compiles to an external stylesheet, and the inline-style needs come from React `style={}` attributes and third-party renderers (Claim 7). `connect-src 'self'` blocks the client-side `fetch(dataUrl)` at `app/lib/utils/exportGraph.ts:24` and `:37` (Claim 8b). Most-severe part wins: the Tailwind mechanism and the connect-src sufficiency conclusion are both Incorrect.

**Evidence:** `postcss.config.mjs:1-7`, `app/lib/utils/exportGraph.ts:16-39`
**Legibility-target:** for-author

---

## Claim 17: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** commit 9b4e453 body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Static reading supports that the nonce is passed into Next's script generation on the Node server path; does not establish, by execution, that every emitted script tag carries it, nor that this holds on Vercel.

Execution is required and was blocked. `next build` needs network access for `next/font/google` (`app/layout.tsx:2`), and the sandbox has none. The existing `.next` in the sibling checkout has no `BUILD_ID` and predates this change, so it cannot be served. Static support: the nonce flows from `parseRequestHeaders` (Claim 3) into `getRequiredScripts(..., nonce, ...)` (`next/dist/server/app-render/app-render.js:1969`) and into `App({ ..., nonce, ... })` (`app-render.js:1143`).

**Evidence:** `next/dist/server/app-render/app-render.js:1143`, `next/dist/server/app-render/app-render.js:1969`, `app/layout.tsx:2`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18a: "headers() is called to opt out of static rendering so the proxy can attach per-request CSP"

**Location:** commit d90d6bb body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Same mechanism as Claim 2; does not cover Vercel routing.

The proxy attaches the CSP header whatever the page's rendering mode, because the proxy step runs before filesystem/page lookup (`resolve-routes.js:57-72`, quoted in Claim 2). Dynamic rendering is needed so the HTML's scripts carry the same per-request nonce, not so the header can be attached.

**Evidence:** `next/dist/server/lib/router-utils/resolve-routes.js:48-75`
**Legibility-target:** for-author

---

## Claim 18b: "the nonce is only written, never read by the layout"

**Location:** commit d90d6bb body
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the layout and the whole `app/` tree (no `x-nonce` reader anywhere); does not cover the proxy comment that implies a reader (Claim 10).

`app/layout.tsx:31` discards the result: `await headers();`. `x-nonce` has no reader (Claim 10).

**Evidence:** `app/layout.tsx:27-31`, `proxy.ts:42`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "No behavior change; CSP directives preserved exactly."

**Location:** commit d90d6bb body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the proxy.ts diff 9b4e453..d90d6bb (return-type annotation, inlining `csp`, comment text) and the layout comment change; does not establish that the pre-existing behavior was correct.

`git diff 9b4e453 d90d6bb -- proxy.ts` changes only the signature annotation (`export function proxy(request: NextRequest): NextResponse {`), the comment, and replaces `const csp = buildCsp(nonce);` … `set("Content-Security-Policy", csp)` with `set("Content-Security-Policy", buildCsp(nonce))`. `buildCsp` (`proxy.ts:19-32`) is untouched. `app/layout.tsx` changed only in comments.

**Evidence:** `proxy.ts:19-48`, `app/layout.tsx:27-31`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: "Lint clean; 221/221 tests pass."

**Location:** commit d90d6bb body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers eslint on the two changed files and the full vitest suite at d90d6bb; does not establish that any test exercises the proxy or CSP (no test touches `proxy.ts`).

- Tests: `timeout 300 npx vitest run`, cwd `/workspace/external/cc-review-eval/mfc-csp` (HEAD d90d6bb), run 2026-11-20T01:20:33Z. Output: `Test Files  24 passed (24)` / `Tests  221 passed (221)`. Process exit was 1, caused by an environment artifact: vitest's dependency probe failed on an empty `/workspace/external/package.json` (`ERR_INVALID_PACKAGE_CONFIG`, "MISSING DEPENDENCY jsdom") before the suite ran green. This is not a test failure.
- Lint: `timeout 240 npx eslint proxy.ts app/layout.tsx`, same cwd, 2026-11-20T01:21:49Z, exit 0, no output.

**Evidence:** `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/csp-r2-vitest.log`, `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/csp-r2-eslint.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: "Manual end-to-end browser verification on the Vercel preview is still recommended"

**Location:** commit 9b4e453 body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Records that no browser or Vercel verification is evidenced in the change; does not establish deployed behavior.

The commit itself says browser verification has not been done. It needs a Vercel preview and a browser, neither available here (paraphrased — no quote available because the subject is a deployment outside the repo). This matters because Claim 3's nonce path depends on a Node-router copy step that Vercel's adapter may not repeat.

**Evidence:** `proxy.ts:44-48`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`app/layout.tsx:27-28`): the proxy runs on every matched request whatever the rendering mode; dynamic rendering is needed so HTML scripts carry the per-request nonce.
- **Claim 7** (`proxy.ts:12-14`): Tailwind v4 compiles to an external stylesheet; `'unsafe-inline'` is needed for React `style={}` attributes (31 sites), KaTeX and React Flow.
- **Claim 8b** (`proxy.ts:16`): `connect-src 'self'` blocks `fetch(dataUrl)` in `app/lib/utils/exportGraph.ts:24,37`, which breaks graph PNG and zip export (the error is only console-logged).
- **Claim 9a** (`proxy.ts:35-36`): Next 16 Proxy always runs on Node.js, not Edge.
- **Claim 16** (9b4e453 body): repeats the Tailwind and connect-src rationales from Claims 7 and 8b.
- **Claim 18a** (d90d6bb body): same wrong mechanism as Claim 2.

### Stale
- none

### Mostly Accurate
- **Claim 3** (`app/layout.tsx:28-30`): Next parses the nonce from *request* headers. It works on `next start` only because the router copies proxy response headers onto `req.headers`. Precise wording, or setting CSP on `requestHeaders` too, would remove the dependence on that copy step.
- **Claim 10** (`proxy.ts:39-40`): `x-nonce` is forwarded, but nothing reads it and no `<Script>` exists.

### Unverifiable
- **Claim 17** (9b4e453 body): needs a `next build` + `next start`, blocked by `next/font/google` network fetch.
- **Claim 21** (9b4e453 body): needs a Vercel preview and a browser.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: security/perf judgments on the policy itself (e.g. missing `worker-src`, dev-mode `'unsafe-eval'` needs) beyond what the claims assert; the hallucination-pattern log was not updated because none of the Incorrect claims are fabricated symbols/APIs, and the brief forbids writing other files.
- Escalate: (1) Graph PNG export and zip export break under `connect-src 'self'` because of `fetch(dataUrl)` in `app/lib/utils/exportGraph.ts:24,37`. This is a functional regression and should be routed to the security/functional critics. (2) The nonce reaches Next only through an internal router step that copies the proxy's response headers onto `req.headers` (`resolve-routes.js:442-443`). On Vercel this is unverified, and if that step is absent every script is blocked. Ask the author to also set `Content-Security-Policy` on `requestHeaders`, or to verify on the preview. (3) The matcher's unanchored `api` lookahead exempts any future page whose path starts with `/api` from CSP.
- Decisions I made: framework evidence came from the sibling install `/workspace/external/cc-review-eval/mfc-csp` (same HEAD d90d6bb, Next 16.2.4) because the reviewed worktree has no node_modules; tests and lint were executed there, not in the read-only worktree; the vitest exit code 1 was judged an environment artifact because the suite summary shows 221/221 passed.
