Commit: d90d6bb

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (reviewed worktree `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-token-measurement/wt-csp`, detached at d90d6bb)
**Scope:** branch diff d86d2dc..d90d6bb (`app/layout.tsx`, `proxy.ts`) plus the commit bodies of 9b4e453 and d90d6bb; consumers and Next.js 16.2.4 framework code read to verify claims
**Checked:** 2026-11-19
**Total claims checked:** 19 (16 numbered claims; 1, 6 and 7 split into a/b)
**Summary:** 11 verified, 2 mostly accurate, 0 stale, 4 incorrect, 2 unverifiable

Replicate r3 of 3. Execution environment: a scratch copy of d90d6bb (`git archive d90d6bb`) at `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/csp-fc-r3`, with `node_modules` copied from the pre-installed `/workspace/external/cc-review-eval/mfc-csp/node_modules` (next 16.2.4). The sandbox has no egress, so `next/font/google` cannot fetch fonts; for the build/run probes **only**, the two `next/font/google` calls in the scratch `app/layout.tsx` were replaced by `{ variable: "a" }` / `{ variable: "b" }` stubs. Nothing about CSP, `headers()` or the proxy was changed except in the one probe labelled "no-headers variant". All captured output is under `.../csp-fc-r3/logs/`. Servers were started under `timeout` and killed by PID; none remain running. No browser is available in the sandbox, so browser-side enforcement is reasoned from the CSP spec, not observed.

---

## Claim 1a: "Opt this layout out of static rendering" (via `await headers()`)

**Location:** `app/layout.tsx:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `await headers()` in the root layout turns `/` from prerendered-static to dynamic in a `next build` of 16.2.4; does not establish behaviour on Vercel's build pipeline or for routes added later with their own segment config.

With the layout as committed, the build reports `┌ ƒ /` ("ƒ (Dynamic) server-rendered on demand"). With only line 31 (`await headers();`) removed, the same build reports `┌ ○ /` ("○ (Static) prerendered as static content"), and the served response carries `x-nextjs-cache: HIT`, `x-nextjs-prerender: 1`, `Cache-Control: s-maxage=31536000`.

```tsx
// app/layout.tsx:31
  await headers();
```

Commands: `NEXT_TELEMETRY_DISABLED=1 timeout 500 ./node_modules/.bin/next build` in `.../csp-fc-r3`, 2026-11-19T17:07:26Z, exit 0 (`logs/build3.log`); same with line 31 removed, 2026-11-19T17:08:18Z, exit 0 (`logs/build-noheaders.log`, response headers in `logs/noheaders-headers.txt`).

**Evidence:** `app/layout.tsx:22-43`, `csp-fc-r3/logs/build3.log`, `csp-fc-r3/logs/build-noheaders.log`, `csp-fc-r3/logs/noheaders-headers.txt`

---

## Claim 1b: "…so proxy.ts runs on every request and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:26-27`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated causal link (dynamic rendering → proxy runs) on `next start`; does not establish Vercel/CDN behaviour, where a cached static page could also bypass the proxy.

The proxy runs on every matched request whether or not the layout is dynamic. In the no-headers variant, where `/` was prerendered static and served from cache (`x-nextjs-cache: HIT`), the response still carried a fresh header `content-security-policy: … 'nonce-NmQ1YmRiNDAt…' 'strict-dynamic' …`, so the proxy had run. What dynamic rendering actually buys is that **the HTML body** is rendered per request with the nonce in it. In the static variant the body had `scripts=18 nonced=0`: the header names a fresh nonce and no script tag carries it, so under `'strict-dynamic'` every script is blocked. The conclusion (the `headers()` call is required) holds. The stated mechanism ("so proxy.ts runs") is wrong, and a reader acting on it would look in the wrong place: the proxy, not the render cache.

**Evidence:** `app/layout.tsx:26-31`, `csp-fc-r3/logs/noheaders-headers.txt`, `csp-fc-r3/logs/noheaders-body.html`, `csp-fc-r3/logs/build-noheaders.log`

---

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High (self-hosted `next start`); see Scope for Vercel
**Verification mode:** executed
**Scope:** Covers the self-hosted Node router (`next start`) in 16.2.4, where the nonce reaches the renderer because the router copies proxy response headers onto the request; does not establish Vercel's runtime, where response headers might not be mirrored into request headers. There the proxy (which sets CSP only on the response, `proxy.ts:47`) could leave Next without a nonce.

The renderer reads the nonce from the **request** headers:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
    const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
    const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```
(excerpt from `parseRequestHeaders(headers, options)`, which starts at :155 and continues past :185; the values flow into its return object; read to :185)

The value gets there because the router copies every proxy response header onto `req.headers`:

```js
// node_modules/next/dist/server/lib/router-utils/resolve-routes.js:443-446
                            if (value) {
                                resHeaders[key] = value;
                                req.headers[key] = value;
                            }
```
(excerpt ends inside the middleware-response handling block, which runs :394-~500; read :390-448)

Observed on `next start`: 15 of 15 `<script>` tags in `/` carry `nonce="NmY5MzIy…"`, the value in that response's CSP header. The three stylesheet `<link>`s carry it as well. Nothing in `app/` reads `x-nonce` (grep shows only the comments at `app/layout.tsx:30` and `proxy.ts:40` and the setter at `proxy.ts:42`). Command: `timeout 60 next start -p 3917`, then `curl -D logs/root-headers.txt -o logs/root-body.html http://127.0.0.1:3917/`, 2026-11-19T17:07:45Z, curl exit 0.

**Evidence:** `node_modules/next/dist/server/app-render/app-render.js:155-185`, `node_modules/next/dist/server/lib/router-utils/resolve-routes.js:394-446`, `proxy.ts:39-48`, `csp-fc-r3/logs/root-headers.txt`, `csp-fc-r3/logs/root-body.html`

---

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy)"

**Location:** `proxy.ts:5`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file-convention rename and the deprecation warning for `middleware.ts` in next 16.2.4; does not establish other renamed APIs.

```js
// node_modules/next/dist/build/index.js:651
_log.warnOnce(`The "${_constants.MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${_constants.PROXY_FILENAME}" instead. …`);
```
The build output also lists `ƒ Proxy (Middleware)` (`csp-fc-r3/logs/build3.log`). This also verifies the 9b4e453 body line "middleware.ts builds with a deprecation warning". `package.json` pins `"next": "16.2.4"`.

**Evidence:** `node_modules/next/dist/build/index.js:651`, `package.json`, `csp-fc-r3/logs/build3.log`

---

## Claim 4: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust. This keeps a hypothetical injected `<script>` tag from executing"

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium (CSP enforcement reasoned from the spec; no browser in sandbox)
**Verification mode:** executed
**Scope:** Covers that the emitted policy is nonce + `'strict-dynamic'` and that every server-emitted script carries the nonce; does not establish that client features loading script-like resources outside `<script>` elements still work. `'strict-dynamic'` makes `'self'` ignored and `script-src` is the fallback for `worker-src`, so the pdf.js workers loaded via `GlobalWorkerOptions.workerSrc = new URL(…, import.meta.url)` (`app/lib/utils/fileExtraction.ts:26-29`, `app/lib/utils/pdfPropositionParser.ts:443-446`) may be blocked. Not browser-tested.

```
// csp-fc-r3/logs/root-headers.txt
content-security-policy: default-src 'self'; script-src 'self' 'nonce-NmY5…' 'strict-dynamic'; …
```
15/15 scripts nonced (see Claim 2).

**Evidence:** `proxy.ts:19-32`, `csp-fc-r3/logs/root-headers.txt`, `csp-fc-r3/logs/root-body.html`, `app/lib/utils/fileExtraction.ts:24-31`

---

## Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** `proxy.ts:12-14` (repeated in the 9b4e453 body: "style-src keeps 'unsafe-inline' as a deliberate carve-out for Tailwind v4")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the production HTML contains and where Tailwind's output lands; does not establish dev-mode style injection by Next/Turbopack HMR, which was not run.

Tailwind v4 (via `@tailwindcss/postcss`, `postcss.config.mjs:3`; `@import "tailwindcss";`, `app/globals.css:1`) compiles to external stylesheets. The prod HTML has no `<style>` tags, only `<link rel="stylesheet" href="/_next/static/chunks/064espkpqfg2~.css" nonce="…">` ×3, and that file begins `@layer properties{…--tw-translate-x:0…`. `'self'` already covers these, and they are nonced anyway. What does need `'unsafe-inline'` is React `style={{…}}` attributes written by the app itself, for example:

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:32
      style={{ lineHeight: 1.9, fontFamily: "inherit" }}
```
There are dozens more such attributes (`app/components/panels/GraphPanel.tsx:215`, `app/components/features/proof-graph/ProofGraphNode.tsx:45`, …), plus KaTeX's inline `style=` output rendered via `rehypeKatex` (`LatexRenderer.tsx:10`). Two `style="…"` attributes appear in the server-rendered `/` (`logs/root-body.html`). The carve-out is needed, but the stated reason (Tailwind) is wrong, and so is the stated cost of tightening ("rebuilding how Tailwind ships styles").

**Evidence:** `proxy.ts:12-14,23`, `postcss.config.mjs:3`, `app/globals.css:1-2`, `app/components/features/output-editing/LatexRenderer.tsx:17-42`, `csp-fc-r3/logs/root-body.html`

---

## Claim 6a: "Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:16-17` (repeated in the 9b4e453 body)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the third-party LLM call sites in `app/`; does not establish that no client code ever contacts a third party for other reasons.

The OpenRouter and Anthropic calls are in server-only modules (`app/lib/llm/callLlm.ts:1` `import { randomUUID } from "crypto";`, `:7` `OPENROUTER_API_URL = "https://openrouter.ai/…"`, used at `:164` and `app/lib/llm/streamLlm.ts:249`). Their importers are `app/api/**/route.ts` files. No `"use client"` file imports anthropic or openrouter (grep returned none). **OpenAlex is not referenced anywhere in the codebase** except this comment (paraphrased — no quote available because the claim is about the absence of code: `grep -rni openalex` hits only `proxy.ts`). Tighten: drop OpenAlex.

**Evidence:** `app/lib/llm/callLlm.ts:1-7,164`, `app/lib/llm/streamLlm.ts:1,249`, `proxy.ts:16-17`

---

## Claim 6b: "`connect-src 'self'` is sufficient"

**Location:** `proxy.ts:16` (9b4e453 body: "connect-src is just 'self' because all external API calls … go server-to-server")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High (CSP source-matching for `data:` is unambiguous: `'self'` never matches a `data:` URL; not browser-tested)
**Verification mode:** static
**Scope:** Covers browser `fetch()` calls in client code under this policy; does not establish html-to-image's internal resource fetches beyond the call sites named here, or the pdf.js worker (see Claim 4 Scope).

Browser-side graph export fetches a `data:` URL, which `connect-src 'self'` blocks:

```ts
// app/lib/utils/exportGraph.ts:20-26 (enclosing downloadGraphAsPng, :16-27, read in full)
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
  triggerDownload(blob, filename);
```
`graphToPngBlob` does the same (`exportGraph.ts:33-38`). The callers are the graph panel's export button (`app/components/panels/GraphPanel.tsx:102-104`, whose `catch` only `console.error`s, so the user sees nothing) and Export All (`app/lib/utils/exportAll.ts:64`). html-to-image also calls `fetch(url)` internally (`node_modules/html-to-image/es/dataurl.js:11`, `embed-webfonts.js:10`). The premise (no third-party calls) is true, but "sufficient" is false: a `data:` source (or a non-fetch decode of the data URL) is needed.

**Evidence:** `app/lib/utils/exportGraph.ts:16-39`, `app/components/panels/GraphPanel.tsx:98-110`, `app/lib/utils/exportAll.ts:64`, `proxy.ts:26`

---

## Claim 7a: "the Edge runtime that Next proxy runs in"

**Location:** `proxy.ts:35-36`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the runtime next 16.2.4 assigns to `proxy.ts`; does not establish Vercel's hosting placement.

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. …`;
```
(excerpt from the proxy-runtime check :573-589; read in full)

The build's `.next/server/functions-config-manifest.json` records `"/_middleware": { "runtime": "nodejs", … }`, and `middleware-manifest.json` (the edge manifest) is empty (`"middleware": {}`). Captured in the scratch build at `csp-fc-r3/.next/server/functions-config-manifest.json` (build `logs/build3.log`, exit 0).

**Evidence:** `node_modules/next/dist/build/analysis/get-page-static-info.js:573-589`, `csp-fc-r3/.next/server/functions-config-manifest.json`, `csp-fc-r3/.next/server/middleware-manifest.json`

---

## Claim 7b: "crypto.randomUUID and Buffer are both available"

**Location:** `proxy.ts:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers availability in the Node.js runtime the proxy actually runs in; does not establish availability in the Edge runtime the comment names (moot, see 7a).

The proxy executed without error and produced base64 nonces, e.g. `'nonce-NmY5MzIyNmMtMDZmNi00MzU2LTkzMTMtYWY3YTI1ZTBmODRm'`, a fresh value on each of the requests in `logs/matcher.txt`.

```ts
// proxy.ts:37
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

**Evidence:** `proxy.ts:34-49`, `csp-fc-r3/logs/root-headers.txt`, `csp-fc-r3/logs/matcher.txt`

---

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-40`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `x-nonce` is set as a request override and is readable; does not establish any consumer, because none exists.

```ts
// proxy.ts:41-46
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
```
(excerpt ends :46; enclosing `proxy()` continues to :49, read)

The mechanism works: `x-middleware-request-*` overrides are applied to `req.headers` (`resolve-routes.js:396-421`). But nothing reads `x-nonce`, and there is no `next/script` or `<Script>` anywhere in `app/` (paraphrased — no quote available because the claim covers absence of code: grep for `x-nonce|next/script|<Script` hits only `proxy.ts:40,42` and the comment `app/layout.tsx:30`). The layout comment says it deliberately does not read it. Tighten: say the header is unused and kept for future `<Script>` use, or drop it.

**Evidence:** `proxy.ts:39-46`, `app/layout.tsx:28-31`, `node_modules/next/dist/server/lib/router-utils/resolve-routes.js:396-421`

---

## Claim 9: "Apply CSP to page navigations only. Skip API routes …, Next's static assets …, and prefetches"

**Location:** `proxy.ts:52-54` (and the 9b4e453 body "matcher skips /api routes, _next/static, and prefetches")
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `/`, `/api/analytics`, a `/_next/static` chunk, `/favicon.ico`, an unknown page, and prefetch requests carrying `next-router-prefetch: 1` or `purpose: prefetch`; does not establish behaviour for paths that merely begin with `api` (the negative lookahead `(?!api` also excludes e.g. `/apiary`) or for other prefetch signals Next may send.

`logs/matcher.txt` (2026-11-19T17:07:54Z, `next start -p 3917`): `/` and `/foo` (404) carry CSP. `/api/analytics`, the static chunk, `/favicon.ico`, and requests with `next-router-prefetch: 1` or `purpose: prefetch` carry no CSP. A non-prefetch RSC request (`rsc: 1`) does carry CSP.

```ts
// proxy.ts:58
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

**Evidence:** `proxy.ts:51-64`, `csp-fc-r3/logs/matcher.txt`, `csp-fc-r3/.next/server/functions-config-manifest.json`

---

## Claim 10: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit 9b4e453 body
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers grep-level absence of `dangerouslySetInnerHTML`, `innerHTML` and `rehype-raw` in `app/`, and KaTeX running with its default `trust`; does not establish the absence of other DOM sinks in third-party libraries.

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:10
const rehypePlugins = [rehypeKatex];
```
No options are passed, so KaTeX's default `trust: false` applies. There are no `dangerouslySetInnerHTML`, `innerHTML` or rehype-raw hits in non-test `app/` files (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:1-42`, `node_modules/katex/dist/katex.mjs:207`

---

## Claim 11: "Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached."

**Location:** commit 9b4e453 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the static-vs-dynamic effect and the consequence for nonces on `next start`; does not establish Vercel behaviour.

See Claims 1a and 1b: without `headers()`, `/` is prerendered and the served HTML carries 0/18 nonced scripts against a fresh header nonce. This body line states the correct mechanism; the layout comment (Claim 1b) does not.

**Evidence:** `app/layout.tsx:31`, `csp-fc-r3/logs/build-noheaders.log`, `csp-fc-r3/logs/noheaders-body.html`

---

## Claim 12: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** commit 9b4e453 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `/` on a self-hosted prod build (fonts stubbed); does not establish other routes, client-side-navigation payloads, or the Vercel preview, which the commit itself defers.

15 of 15 `<script>` tags nonced; CSP header present (`logs/root-headers.txt`, `logs/root-body.html`; command in Claim 2).

**Evidence:** `csp-fc-r3/logs/root-headers.txt`, `csp-fc-r3/logs/root-body.html`

---

## Claim 13: "No behavior change; CSP directives preserved exactly."

**Location:** commit d90d6bb body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the d90d6bb diff to `proxy.ts` (return-type annotation, inlining `csp`) and `app/layout.tsx` (comment only); does not establish that the pre-existing behaviour was correct.

`git diff 9b4e453..d90d6bb` changes only the `proxy()` return type, the deletion of `const csp = buildCsp(nonce);`, `response.headers.set("Content-Security-Policy", buildCsp(nonce));`, and comment lines. `buildCsp` (`proxy.ts:19-32`) is untouched.

**Evidence:** `proxy.ts:19-49`, `app/layout.tsx:26-31`

---

## Claim 14: "Lint clean; 221/221 tests pass."

**Location:** commit d90d6bb body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `vitest run` and `eslint app/layout.tsx proxy.ts` at d90d6bb; does not establish full-repo `eslint`, and no test exercises `proxy.ts`.

`timeout 300 ./node_modules/.bin/vitest run` in `.../csp-fc-r3`, 2026-11-19T17:09:01Z, exit 0: "Tests 221 passed (221)" (`logs/vitest.log`; run with the font stub in `layout.tsx`, which no test imports). `timeout 200 ./node_modules/.bin/eslint app/layout.tsx proxy.ts` on the restored, unmodified `layout.tsx`, exit 0 (`logs/eslint.log`).

**Evidence:** `csp-fc-r3/logs/vitest.log`, `csp-fc-r3/logs/eslint.log`

---

## Claim 15: "headers() is called to opt out of static rendering so the proxy can attach per-request CSP, not to read x-nonce (the nonce is only written, never read by the layout)."

**Location:** commit d90d6bb body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The second half (x-nonce never read) is true, per Claim 8. The first half restates the mechanism refuted in Claim 1b; that defect is verdicted there and not double-counted here. Unverifiable is recorded only for the residual reading "so the proxy's header nonce matches the HTML", which is true but not what the text says.

"Only written, never read" is confirmed (paraphrased — no quote available because the claim covers absence of code; grep as in Claim 8). "So the proxy can attach per-request CSP" carries the same wrong mechanism as Claim 1b: the proxy attaches it regardless.

**Evidence:** `app/layout.tsx:26-31`, `proxy.ts:42`

---

## Claim 16: "Manual end-to-end browser verification on the Vercel preview is still recommended — CSP issues sometimes only appear once Next's full bootstrap is exercised."

**Location:** commit 9b4e453 body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** The recommendation is advice, not a code claim; recorded because the sandbox found concrete browser-only breakages (Claims 6b, 4 Scope) that confirm the caution.

Verifying needs a real browser against a deployed or local build, which the sandbox lacks (no Chromium or Playwright), plus Vercel access.

**Evidence:** `app/lib/utils/exportGraph.ts:24`, `app/lib/utils/fileExtraction.ts:26-29`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`app/layout.tsx:26-27`): the proxy runs on every request regardless. `headers()` is needed so the **HTML** is rendered per request with the nonce. Probe: a static `/` still got a fresh CSP header, with 0/18 scripts nonced.
- **Claim 5** (`proxy.ts:12-14`): Tailwind v4 ships external `.css` files (nonced `<link>`s, no `<style>` tags in prod). `'unsafe-inline'` is needed for React `style={{}}` attributes and KaTeX inline styles.
- **Claim 6b** (`proxy.ts:16`): `connect-src 'self'` blocks `fetch(dataUrl)` in `app/lib/utils/exportGraph.ts:24,37`, so PNG graph export and Export All's graph image break, with only a `console.error`.
- **Claim 7a** (`proxy.ts:35-36`): in Next 16 the proxy always runs on the Node.js runtime (`get-page-static-info.js:576`; manifest `"runtime": "nodejs"`), not Edge.

### Stale
- none

### Mostly Accurate
- **Claim 6a** (`proxy.ts:16-17`): OpenAlex is not referenced anywhere in the codebase; the Anthropic and OpenRouter calls are server-side.
- **Claim 8** (`proxy.ts:39-40`): `x-nonce` is readable, but nothing reads it and there is no `<Script>` in the app. Say it is unused or remove it.

### Unverifiable
- **Claim 15** (d90d6bb body): restates Claim 1b's mechanism. Its "never read" half is true.
- **Claim 16** (9b4e453 body): needs a real browser and the Vercel preview.

Hallucination-pattern log: no Incorrect verdict is a fabricated symbol, API or option (all four are wrong mechanisms or behaviours), so no entry qualifies. Per the brief ("Do not write any other file"), `docs/reviews/hallucination-patterns.md` was neither created nor updated. The reviewed repo has no such file.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: code-quality and fix design (whether to add `data:` to connect-src, `worker-src`, or CSP on request headers) is left to the sibling critics; browser-side enforcement was not observed because no browser is available.
- Escalate: (1) Graph PNG export and Export All are likely broken by `connect-src 'self'` (`exportGraph.ts:24,37`). This is a functional regression, not just a comment error, and needs a browser check or a fix. (2) The pdf.js worker (`fileExtraction.ts:26-29`, `pdfPropositionParser.ts:443-446`) may be blocked because `script-src` with `'strict-dynamic'` is the `worker-src` fallback and ignores `'self'`. PDF upload needs a browser test. (3) On Vercel, confirm Next still finds the nonce: the proxy sets CSP only on the response, and the nonce reaches the renderer on `next start` only because the router copies response headers onto the request (`resolve-routes.js:443-446`). Setting `Content-Security-Policy` on `requestHeaders` as well would remove the dependence.
- Decisions I made: stubbed `next/font/google` in the scratch copy only (no egress), to get a prod build; copied `node_modules` from `/workspace/external/cc-review-eval/mfc-csp` (same commit d90d6bb, next 16.2.4) rather than installing; folded the 9b4e453 body's repeats of the proxy.ts docblock claims into Claims 3, 5, 6 and 9 rather than verdicting them twice.
