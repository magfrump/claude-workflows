Commit: d90d6bb

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (review worktree `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-csp`, detached HEAD d90d6bb)
**Scope:** d86d2dc..d90d6bb — `proxy.ts` (new), `app/layout.tsx` (modified), and the three commit messages (9b4e453, b25e939, d90d6bb)
**Checked:** 2026-11-19
**Total claims checked:** 15
**Summary:** 5 verified, 2 mostly accurate, 0 stale, 6 incorrect, 2 unverifiable

Framework reference: the review worktree has no `node_modules`. Next.js behavior was read from an installed copy of the same pinned version (`next` 16.2.4, matching `package.json` `"next": "16.2.4"`) at `/workspace/external/cc-review-eval/mfc-csp/node_modules/next` (a checkout of this same branch, HEAD d90d6bb). Paths below prefixed `NEXT/` are relative to that directory. No hallucination-pattern log exists in the reviewed repo (`docs/reviews/` absent), and no Incorrect verdict here is a fabricated symbol, so no log entry applies.

Execution blocker (applies to every executable claim below): a production build could not be run. The worktree has no installed dependencies and the sandbox has no network; `next/font/google` in `app/layout.tsx` needs the network at build time. The prior build attempt in the reference checkout failed: `/workspace/external/cc-review-eval/mfc-csp/.next/trace-build` records `"name":"next-build",... "failed":true`, and there is no `BUILD_ID`. All verdicts are therefore static.

---

## Claim 1: "Next.js 16 renamed Middleware → Proxy"

**Location:** `proxy.ts:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rename and the deprecation of the `middleware` file name in Next 16 (also stated in commit 9b4e453's body, including "middleware.ts builds with a deprecation warning"); does not establish the exact build-time warning text, which was not executed.

The Next 16.2.4 docs say so directly: `NEXT/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md:11` — "The `middleware` file convention is deprecated and has been renamed to `proxy`", and the version table at `:770` — "`v16.0.0` | Middleware is deprecated and renamed to Proxy". The export is named `proxy` as the convention requires: `export function proxy(request: NextRequest): NextResponse {` (`proxy.ts:34`).

**Evidence:** `proxy.ts:5`, `proxy.ts:34`, `NEXT/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md:11`, `:770`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust"

**Location:** `proxy.ts:7-8`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether Next.js tags any script with the nonce under this proxy, as Next 16.2.4's render path reads it; does not establish browser behavior by execution (build blocked; see header).

The policy half (with `'nonce-…' 'strict-dynamic'`, only nonce-bearing scripts and scripts they load run) matches CSP semantics. The premise that Next.js tags its scripts with the nonce does not hold for this proxy, and that premise is what makes the app work under the policy. Next reads the nonce from the **request** headers:

```js
// NEXT/dist/server/app-render/app-render.js:166-167 (inside parseRequestHeaders(headers, options), called at :1557 as parseRequestHeaders(req.headers, {...}))
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```
(excerpt ends :167; enclosing parseRequestHeaders continues past :175 — read through :175, and the remainder builds request IDs and does not touch the nonce)

The proxy puts the CSP only on the **response** and forwards only `x-nonce` on the request:

```ts
// proxy.ts:41-48
const requestHeaders = new Headers(request.headers);
requestHeaders.set("x-nonce", nonce);

const response = NextResponse.next({
  request: { headers: requestHeaders },
});
response.headers.set("Content-Security-Policy", buildCsp(nonce));
return response;
```

`NextResponse.next` forwards only the keys present in `init.request.headers` (`NEXT/dist/server/web/spec-extension/response.js:35-39`: `for (const [key, value] of init.request.headers){ headers.set('x-middleware-request-' + key, value); ...}`). A header set on `response.headers` afterwards is never copied into the request. So at render time `csp` is undefined, `nonce` is undefined, and Next emits its scripts without a nonce. Under `'strict-dynamic'`, `'self'` is ignored, so Next's own bootstrap scripts would be blocked in a browser. The Next 16 CSP guide's reference proxy sets the CSP on both: `requestHeaders.set('Content-Security-Policy', contentSecurityPolicyHeaderValue)` and `response.headers.set(...)` (`NEXT/dist/docs/01-app/02-guides/content-security-policy.md:67-85`). The guide also says Next applies nonces "based on the CSP header present in the request" (`:181`).

**Evidence:** `proxy.ts:41-48`, `NEXT/dist/server/app-render/app-render.js:155-175`, `:1557`, `NEXT/dist/server/app-render/get-script-nonce-from-header.js:12-47`, `NEXT/dist/server/web/spec-extension/response.js:25-40`, `NEXT/dist/docs/01-app/02-guides/content-security-policy.md:67-85`, `:181-191`
**Legibility-target:** for-author

---

## Claim 3: "Tailwind v4 emits inline styles" (as the reason `style-src` needs `'unsafe-inline'`)

**Location:** `proxy.ts:12-14`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers how Tailwind is wired in this repo and which code produces inline styles; does not establish whether removing `'unsafe-inline'` would break the app (the carve-out may still be needed, for other reasons).

Tailwind v4 is wired as a PostCSS plugin over a stylesheet import: `"@tailwindcss/postcss": {},` (`postcss.config.mjs:3`) and `@import "tailwindcss";` (`app/globals.css:1`), imported by `import "./globals.css";` (`app/layout.tsx:4`). That compiles to a bundled CSS file served from `_next/static`, which `'self'` covers. It does not produce inline styles. The inline styles that do need `'unsafe-inline'` come from React `style={{…}}` attributes in app code, for example `style={{ backgroundColor: status.color }}` (`app/components/panels/NodeDetailPanel.tsx:48`), 30 such sites across `app/**/*.tsx` (paraphrased — no quote available because the count comes from `rg -n "style=\{\{" app -g '*.tsx' | wc -l` → 30). They also come from the libraries reactflow and rehype-katex (KaTeX output), and from Next's dev-mode style injection. The conclusion (keep `'unsafe-inline'`) is plausibly right, but the stated mechanism is wrong. A reader who replaced Tailwind expecting to drop the carve-out would be misled.

**Evidence:** `postcss.config.mjs:1-7`, `app/globals.css:1-2`, `app/layout.tsx:4`, `app/components/panels/NodeDetailPanel.tsx:48`, `app/components/panels/GraphPanel.tsx:215`
**Legibility-target:** for-author

---

## Claim 4a: "Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party"

**Location:** `proxy.ts:16-17` (also commit 9b4e453 body)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all `fetch(` call sites under `app/` outside `app/api/` and the import graph of the OpenRouter client; does not establish third-party SDK internals that might open their own connections.

`OPENROUTER_API_URL` is `"https://openrouter.ai/api/v1/chat/completions"` (`app/lib/llm/callLlm.ts:7`). `callLlm`/`streamLlm` are imported only by `app/api/**/route.ts`, `app/lib/formalization/artifactRoute.ts` and server libs (paraphrased — no quote available because this is an import-graph result from `rg -ln "callLlm|streamLlm" app`). The one client-side file in that list uses a type-only import: `import type { LlmCallUsage } from "@/app/lib/llm/callLlm";` (`app/lib/formalization/api.ts:3`). Every client-side `fetch(` to the network targets a relative `/api/...` path, for example `fetch("/api/refine/context", {` (`app/components/features/context-input/ContextInput.tsx:25`) and `fetch("/api/verification/lean", {` (`app/lib/formalization/api.ts:104`).

**Evidence:** `app/lib/llm/callLlm.ts:7`, `app/lib/formalization/api.ts:3`, `:104`, `app/components/features/context-input/ContextInput.tsx:25`, `app/hooks/useAnalytics.ts:11`
**Legibility-target:** for-orchestrator-synthesis

## Claim 4b: "`connect-src 'self'` is sufficient"

**Location:** `proxy.ts:16` (also commit 9b4e453 body: "connect-src is just 'self' because all external API calls ... go server-to-server")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers browser `fetch` call sites in app code; does not establish the internal fetches of html-to-image or pdfjs-dist beyond what is noted here.

The browser code fetches a `data:` URL, and `connect-src 'self'` does not allow that, because `'self'` never matches the `data:` scheme:

```ts
// app/lib/utils/exportGraph.ts:20-26 (downloadGraphAsPng, :16-27, read in full)
const dataUrl = await toPng(viewportElement, {
  pixelRatio: 2,
  backgroundColor: EXPORT_BG,
});
const res = await fetch(dataUrl);
const blob = await res.blob();
triggerDownload(blob, filename);
```

`graphToPngBlob` does the same at `:33-38` (`const res = await fetch(dataUrl);`). Both run in the browser: `GraphPanel.tsx` (a `"use client"` file) loads one with `await import("@/app/lib/utils/exportGraph")` (`app/components/panels/GraphPanel.tsx:102`), and `exportAll.ts` imports `graphToPngBlob` (`app/lib/utils/exportAll.ts:10`). Under this policy, the PNG graph export and the graph image in the zip export would fail with a CSP connect-src violation. "Sufficient" holds for the third-party API calls (4a) but not for the policy as a whole.

**Evidence:** `proxy.ts:26`, `app/lib/utils/exportGraph.ts:16-39`, `app/components/panels/GraphPanel.tsx:102`, `app/lib/utils/exportAll.ts:10`
**Legibility-target:** for-author

---

## Claim 5a: "crypto.randomUUID and Buffer are both available"

**Location:** `proxy.ts:35-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers availability in the runtime the proxy actually uses (Node.js); does not establish Edge-runtime availability, which is moot here.

Proxy runs on Node.js (Claim 5b), where both the global `crypto.randomUUID` and `Buffer` exist. The expression `Buffer.from(crypto.randomUUID()).toString("base64")` (`proxy.ts:37`) is the same one used in the Next 16 CSP guide (`NEXT/dist/docs/01-app/02-guides/content-security-policy.md:48`).

**Evidence:** `proxy.ts:37`, `NEXT/dist/docs/01-app/02-guides/content-security-policy.md:48`
**Legibility-target:** for-orchestrator-synthesis

## Claim 5b: "the Edge runtime that Next proxy runs in"

**Location:** `proxy.ts:36`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the runtime Next 16.2.4 uses for `proxy.ts`; does not establish runtime behavior on a specific Vercel deployment.

`NEXT/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md:219`: "Proxy defaults to using the Node.js runtime. The `runtime` config option is not available in Proxy files." No runtime override exists: `rg -n "runtime" proxy.ts next.config.ts` matches only this comment (paraphrased — no quote available because the claim is about absence of config). Edge was Middleware's default (`proxy.md:743`), not Proxy's. A reader acting on this comment would wrongly apply Edge constraints, or would assume Edge-only globals are the safe set.

**Evidence:** `proxy.ts:36`, `next.config.ts:1-7`, `NEXT/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md:217-219`, `:743`
**Legibility-target:** for-author

---

## Claim 6: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-40`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the forwarding mechanism and every reader of `x-nonce` in the repo; does not establish that forwarding `x-nonce` makes Next itself apply a nonce (it does not; see Claim 2).

The mechanism works: `requestHeaders.set("x-nonce", nonce);` (`proxy.ts:42`) is forwarded through `NextResponse.next({ request: { headers: requestHeaders } })` (`proxy.ts:44-46`). But nothing reads it. `rg -n "x-nonce|nonce" app` hits only the layout comment, which says the layout does *not* read it: "so we don't need to read x-nonce here ourselves" (`app/layout.tsx:30`). There are no `<Script>` / `next/script` uses in `app/` (paraphrased — no quote available because the claim covers absence: zero grep hits). The precise version: `x-nonce` is forwarded for possible future use and currently has no consumer. A reader may also take it as the channel Next uses to get the nonce. It is not: Next reads only the request `Content-Security-Policy` header (Claim 2).

**Evidence:** `proxy.ts:39-46`, `app/layout.tsx:27-31`
**Legibility-target:** for-author

---

## Claim 7: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches"

**Location:** `proxy.ts:52-62` (also commit 9b4e453 body: "The matcher skips /api routes, _next/static, and prefetches")
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the matcher's exclusions; does not establish matcher evaluation by execution.

The exclusions are as stated: `source: "/((?!api|_next/static|_next/image|favicon.ico).*)"` with `missing: [{ type: "header", key: "next-router-prefetch" }, { type: "header", key: "purpose", value: "prefetch" }]` (`proxy.ts:57-61`). This matches the Next 16 guide's recommended matcher verbatim (`NEXT/dist/docs/01-app/02-guides/content-security-policy.md:148-151`). "Page navigations only" is too broad a description. The negative lookahead has no trailing `/`, so it skips any path that starts with `api`, not only `/api/`. It also does not skip `public/` assets other than `favicon.ico` (`public/` holds `file.svg globe.svg next.svg vercel.svg window.svg`; paraphrased — no quote available because this is a directory listing). Those assets, and non-prefetch RSC navigation requests, also run the proxy and get a CSP and a fresh nonce.

**Evidence:** `proxy.ts:51-64`, `NEXT/dist/docs/01-app/02-guides/content-security-policy.md:133-175`
**Legibility-target:** for-author

---

## Claim 8: "`await headers()`" opts this layout out of static rendering

**Location:** `app/layout.tsx:27,31` (also commit 9b4e453 body: "Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the opt-out effect of calling a request-time API in the root layout (no `cacheComponents` or PPR is configured; `next.config.ts` is empty); does not establish by execution that the build reports the route as dynamic (build blocked).

`await headers();` (`app/layout.tsx:31`) is a request-time API call in the root layout, and `next.config.ts` has `/* config options here */` only, so the default dynamic-rendering rules apply. The Next guide requires dynamic rendering for nonces: "you **must use dynamic rendering** to add nonces" (`NEXT/dist/docs/01-app/02-guides/content-security-policy.md:38`). Its own example uses `await connection()` (`:201-206`), but reading `headers()` has the same opt-out effect (paraphrased — no quote available because this is Next's documented dynamic-API rule, not repo code). The rationale "nonces can't be cached" is right.

**Evidence:** `app/layout.tsx:22-42`, `next.config.ts:1-7`, `NEXT/dist/docs/01-app/02-guides/content-security-policy.md:38`, `:195-206`
**Legibility-target:** for-orchestrator-synthesis

## Claim 9: "so proxy.ts runs on every request and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:27-28` (also commit d90d6bb body: "headers() is called to opt out of static rendering so the proxy can attach per-request CSP")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the causal link between the layout's dynamic rendering and whether the proxy runs; does not establish caching behavior of an external CDN.

Whether the proxy runs does not depend on how the layout renders. Proxy sits ahead of filesystem and app routes in the request chain: "Proxy will be invoked for **every route in your project**" and runs at step 3, before "Filesystem routes (`public/`, `_next/static/`, `pages/`, `app/`, etc.)" (`NEXT/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md:202-209`). It would run, and attach a fresh CSP header, even for a statically prerendered page. Dynamic rendering is needed for a different reason: so the HTML is rendered per request and the nonce can be put on its script tags (`content-security-policy.md:181`: "Static pages are generated at build time, when no request or response headers exist—so no nonce can be injected"). With a static page, the header would carry a fresh nonce that the cached HTML lacks. The stated mechanism ("so proxy runs") is wrong, so a reader who later swaps `headers()` for caching would misjudge what breaks.

**Evidence:** `app/layout.tsx:27-31`, `NEXT/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md:202-212`, `NEXT/dist/docs/01-app/02-guides/content-security-policy.md:181`
**Legibility-target:** for-author

## Claim 10: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which header Next 16.2.4 parses for the nonce; does not establish browser behavior by execution (build blocked).

Next takes the nonce from the **request's** CSP header, not the response's: `const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];` inside `parseRequestHeaders`, called as `parseRequestHeaders(req.headers, {` (`NEXT/dist/server/app-render/app-render.js:166`, `:1557`). See Claim 2 for the full trace. Because `proxy.ts` sets the CSP only on the response (`proxy.ts:47`), Next finds no nonce and tags nothing. The "so we don't need to read x-nonce" conclusion is correct only in that reading `x-nonce` would not help either. The fix lives in the proxy (set CSP on the request headers too), not in the layout.

**Evidence:** `app/layout.tsx:28-30`, `proxy.ts:47`, `NEXT/dist/server/app-render/app-render.js:155-175`, `:1557`, `NEXT/dist/docs/01-app/02-guides/content-security-policy.md:181-191`
**Legibility-target:** for-author

---

## Claim 11: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit 9b4e453 body
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named properties in app source; does not establish broader XSS safety (other sinks such as `href` values or `innerHTML` in libraries).

`rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw|trust" app` gives no non-test hits (paraphrased — no quote available because the claim covers absence). The only rehype plugin is `const rehypePlugins = [rehypeKatex];` (`app/components/features/output-editing/LatexRenderer.tsx:10`). No `trust` option is passed, so KaTeX's default `trust: false` applies.

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:6-10`
**Legibility-target:** for-orchestrator-synthesis

## Claim 12: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** commit 9b4e453 body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the nonce-application half against Next 16.2.4's source; the "emits the CSP header" half is not contradicted (the proxy sets it on the response, `proxy.ts:47`) but was not executed.

The nonce half is contradicted by the framework code traced in Claim 2: with no `Content-Security-Policy` on the request, `nonce` is `undefined` (`NEXT/dist/server/app-render/app-render.js:166-167`), so Next applies no nonce to any script. Whatever the author observed, it cannot have been nonce-tagged scripts produced by this proxy on Next 16.2.4. A verification is reported here that the code does not support. Execution to confirm in a browser was blocked (see header).

**Evidence:** `proxy.ts:41-48`, `NEXT/dist/server/app-render/app-render.js:166-167`
**Legibility-target:** for-author

## Claim 13: "No behavior change; CSP directives preserved exactly."

**Location:** commit d90d6bb body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the b25e939..d90d6bb diff; does not establish that the behavior being preserved was correct (see Claims 2, 4b).

The `proxy.ts` diff only removes `const csp = buildCsp(nonce);`, replaces `response.headers.set("Content-Security-Policy", csp);` with `response.headers.set("Content-Security-Policy", buildCsp(nonce));`, adds the `: NextResponse` return type, and edits a comment. `buildCsp` (`proxy.ts:19-32`) is untouched. The `app/layout.tsx` diff changes only comment lines (paraphrased — no quote available because this summarizes `git diff b25e939..d90d6bb`).

**Evidence:** `proxy.ts:19-48`, `app/layout.tsx:27-30`
**Legibility-target:** for-orchestrator-synthesis

## Claim 14: "Lint clean; 221/221 tests pass."

**Location:** commit d90d6bb body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond noting the blocker; does not establish lint or test status, nor that any test exercises `proxy.ts` (no test file for it exists in the diff).

This is an executable guarantee, so execution is required. Blocker: the review worktree has no `node_modules` and must not be modified, and the sandbox has no network to install. The test count could not be checked.

**Evidence:** `package.json:6-12`
**Legibility-target:** for-orchestrator-synthesis

## Claim 15: "Manual end-to-end browser verification on the Vercel preview is still recommended"

**Location:** commit 9b4e453 body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Records that browser verification was not performed in this review; does not establish anything about the Vercel preview.

The claim implies that browser verification had not been done. Claims 2, 4b and 10 predict that it would fail: bootstrap scripts blocked, and data-URL fetches blocked on export. That needs a browser and a deployment, which are not available here.

**Evidence:** `proxy.ts:19-48`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`proxy.ts:7-8`): Next never tags scripts with the nonce here, because it reads the nonce from the request CSP header and the proxy sets CSP only on the response. The proxy also needs `requestHeaders.set("Content-Security-Policy", …)`.
- **Claim 3** (`proxy.ts:12-14`): Tailwind v4 compiles to a bundled stylesheet. The inline styles come from React `style` props, reactflow and KaTeX.
- **Claim 4b** (`proxy.ts:16`, commit 9b4e453): `connect-src 'self'` blocks `fetch(dataUrl)` in `app/lib/utils/exportGraph.ts:24,37`, which breaks graph PNG export.
- **Claim 5b** (`proxy.ts:36`): Next 16 Proxy runs on Node.js, not Edge.
- **Claim 9** (`app/layout.tsx:27-28`, commit d90d6bb): the proxy runs regardless of static or dynamic rendering. Dynamic rendering is needed so the HTML can carry the nonce.
- **Claim 10** (`app/layout.tsx:28-30`): Next reads the nonce from the request's CSP header, not the response's.
- **Claim 12** (commit 9b4e453): "Next applies the nonce to every <script> tag" is contradicted by Next 16.2.4's render path under this proxy.

### Stale
- none

### Mostly Accurate
- **Claim 6** (`proxy.ts:39-40`): `x-nonce` is forwarded but has no reader (no layout reads it, no `<Script>` exists).
- **Claim 7** (`proxy.ts:52-54`): "page navigations only" is too broad. `public/*.svg` and RSC requests also get a CSP, and any `/api*` prefix is skipped.

### Unverifiable
- **Claim 14** (commit d90d6bb): lint and test results need installed deps.
- **Claim 15** (commit 9b4e453): browser verification needs a browser and a deployment.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: running a production build or browser test (no deps in the worktree, no network for next/font/google); code-quality and security judgments outside the claims.
- Escalate: (1) Blocking: the proxy sets CSP only on the response, so under Next 16.2.4 no script gets a nonce and `'strict-dynamic'` should block all of Next's bootstrap JS. The app likely fails to hydrate in production (Claims 2/10/12; send to the security and correctness critics). (2) `connect-src 'self'` breaks `fetch(dataUrl)` in graph PNG and zip export (Claim 4b). (3) `script-src` has no dev-only `'unsafe-eval'`, which the Next guide says React dev needs (`content-security-policy.md:42`). This is not a claim in the diff; route it to a critic. (4) No tests cover `proxy.ts`.
- Decisions I made: I used Next 16.2.4 framework code and docs from `/workspace/external/cc-review-eval/mfc-csp/node_modules/next` (same pinned version, same branch HEAD), because the review worktree has no `node_modules`.
