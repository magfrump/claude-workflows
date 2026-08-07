# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (branch e3/csp-arm1)
**Scope:** `git diff d86d2dc..HEAD` (HEAD = f25d968) — app/layout.tsx, app/lib/security/csp.ts, app/lib/security/csp.test.ts, app/lib/utils/exportGraph.ts, proxy.ts, proxy.test.ts, plus commit f25d968's message claims
**Commit:** f25d968
**Checked:** 2026-08-06
**Total claims checked:** 18
**Summary:** 17 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Historical rule observed: all evidence read from ancestors of worktree HEAD and the worktree's installed `node_modules`; no main checkout or other worktrees consulted. Full-1 artifacts were used as advisory hints only. The falsification claim (Claim 13) was verified by reading assertions, not by mutating the worktree.

---

## Claim 1: "Next tags its own bootstrap `<script>` elements with the nonce it parses out of the *request* Content-Security-Policy header, which proxy.ts sets on the forwarded request headers — not out of the response header. We therefore don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-32`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The installed Next.js parses the nonce inside `parseRequestHeaders` — a function whose input is the incoming request's headers, not the response:

```js
// node_modules/next/dist/server/app-render/app-render.js:155,166-167
function parseRequestHeaders(headers, options) {
    ...
    const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
    const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

proxy.ts sets that header on the forwarded request:

```ts
// proxy.ts:25-26
const requestHeaders = new Headers(request.headers);
requestHeaders.set("Content-Security-Policy", csp);
```

The "we don't need to read x-nonce" half is consistent with usage: `x-nonce` is read nowhere in app code (paraphrased — no quote available because the claim covers absence of code; `rg -n "x-nonce"` over the repo excluding node_modules hits only `proxy.ts:27-31` and `proxy.test.ts`). That the parsed nonce is then applied to Next's own bootstrap scripts is paraphrased — no quote available because the nonce threading from `parseRequestHeaders` to script emission spans many files in `next/dist/server/app-render/`; the request-side parse quoted above is the load-bearing part of the claim.

**Evidence:** `node_modules/next/dist/server/app-render/app-render.js:155-167`, `proxy.ts:25-31`, `proxy.test.ts:60-73`

---

## Claim 2: "Opt this layout out of static rendering ... Per-request nonces and static rendering are mutually exclusive ... the app is a single 'use client' route with no generateStaticParams, revalidate, or ISR"

**Location:** `app/layout.tsx:27,34-41`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

`headers()` is a Dynamic API in the installed Next; its own error text confirms it forces dynamic rendering:

```js
// node_modules/next/dist/server/request/headers.js:78
throw ... new _staticgenerationbailout.StaticGenBailoutError(`Route ${workStore.route} with \`dynamic = "error"\` couldn't be rendered statically because it used \`headers()\`. ...`)
```

The single-route claim: the only page files are `app/page.tsx` and the layout, and the page is a client component:

```tsx
// app/page.tsx:1
"use client";
```

The absence claim holds (paraphrased — no quote available because the claim covers absence of code: `rg -n "generateStaticParams|revalidate"` over `app/` matches only this comment itself at `app/layout.tsx:39`).

**Evidence:** `node_modules/next/dist/server/request/headers.js:43-98`, `app/page.tsx:1`, `app/layout.tsx:27-42`

---

## Claim 3: "The comparison is against the permissive value, so unset, misspelled, and unexpected environments must all get the stricter policy."

**Location:** `app/lib/security/csp.test.ts:54-55`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High

The implementation gates only the permissive branch on an exact match:

```ts
// app/lib/security/csp.ts:45
const devEvalDirective = nodeEnv === "development" ? " 'unsafe-eval'" : "";
```

Any `nodeEnv` other than the exact string `"development"` (including `undefined`, `""`, `"Development"`, `"dev"`) falls through to the empty string, i.e. no `'unsafe-eval'`. The test sweeps exactly those values at `app/lib/security/csp.test.ts:56-58`.

**Evidence:** `app/lib/security/csp.ts:41-47`, `app/lib/security/csp.test.ts:53-59`

---

## Claim 4: "Regression guard: graph PNG/zip export must decode canvases in-DOM (`exportGraph.ts` uses `toBlob`) rather than `fetch()`-ing a data URL, which would be blocked here."

**Location:** `app/lib/security/csp.test.ts:67-70`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

`exportGraph.ts` does use `toBlob` and contains no `fetch`:

```ts
// app/lib/utils/exportGraph.ts:6,25
import { toBlob } from "html-to-image";
...
const blob = await toBlob(viewportElement, {
```

The policy the test asserts against does scope `connect-src` to `'self'`:

```ts
// app/lib/security/csp.ts:52
"connect-src 'self'",
```

That `fetch()` of `data:` URLs is governed by `connect-src` and `'self'` excludes the `data:` scheme is paraphrased — no quote available because it is CSP specification behavior, not repo code.

**Evidence:** `app/lib/utils/exportGraph.ts:6-32`, `app/lib/security/csp.ts:52`, `app/lib/security/csp.test.ts:66-72`

---

## Claim 5: "Extracted from `proxy.ts` so the policy ... can be imported and asserted on directly (see `csp.test.ts`). The proxy entry point stays a thin wiring layer."

**Location:** `app/lib/security/csp.ts:4-7`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High

`csp.test.ts` exists and imports the function directly (`import { buildCsp } from "./csp"` at `app/lib/security/csp.test.ts:2`). proxy.ts imports it rather than defining it:

```ts
// proxy.ts:3,16
import { buildCsp } from "@/app/lib/security/csp";
...
const csp = buildCsp(nonce);
```

That the extraction came from proxy.ts is confirmed by history: the pre-fix proxy.ts defined the policy inline (paraphrased — no quote available because the claim is about commit history; `git show e5d95a9:proxy.ts` contains the directive array that now lives in csp.ts). proxy.ts at HEAD is 53 lines containing only nonce generation, header wiring, and the matcher.

**Evidence:** `app/lib/security/csp.ts:1-58`, `proxy.ts:1-53`, `app/lib/security/csp.test.ts:2`

---

## Claim 6: "Why `style-src 'unsafe-inline'`: the dependents are React `style={{...}}` attributes ..., reactflow's per-node transform styles, KaTeX's inline-styled output, `next/font`'s injected declarations, and dev-time HMR style injection — not Tailwind, which compiles to an external stylesheet here."

**Location:** `app/lib/security/csp.ts:13-19`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

The named dependencies are all present: `"reactflow": "^11.11.4"` (`package.json:29`), KaTeX CSS imported at `app/layout.tsx:5` (`import "katex/dist/katex.min.css"`), and `next/font/google` at `app/layout.tsx:2`. Tailwind is wired through PostCSS as a build-time stylesheet:

```css
/* app/globals.css:1-2 */
@import "tailwindcss";
@plugin "@tailwindcss/typography";
```

with `"@tailwindcss/postcss": {}` in `postcss.config.mjs:3` — i.e. compiled CSS, not runtime inline injection. That reactflow, KaTeX, and React `style` props emit inline styles at runtime is paraphrased — no quote available because it is runtime rendering behavior of third-party libraries, not statically quotable from this repo; hence Medium confidence for the enumeration of *which* dependents require the carve-out, while the "not Tailwind" half is directly evidenced.

**Evidence:** `package.json:29`, `app/layout.tsx:2-5`, `app/globals.css:1-2`, `postcss.config.mjs:3`

---

## Claim 7: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `app/lib/security/csp.ts:20-24`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The conclusion is correct; the enumeration of services is not. Re-enumerating client network calls on this state: every `fetch` in client-reachable code targets a same-origin path — `/api/explanation/lean-error` (`app/components/features/lean-display/LeanCodeDisplay.tsx:88`), `/api/verification/lean` (`app/lib/formalization/api.ts:104`), `/api/refine/context` (`app/components/features/context-input/ContextInput.tsx:25`), `/api/analytics` (`app/hooks/useAnalytics.ts:11,30`), plus the generic helper `fetchApi(url, ...)` (`app/lib/formalization/api.ts:10`) whose call sites pass `/api/...` paths (paraphrased — no quote available because the invariant is inferred from multiple call sites in `app/hooks/`). The only third-party fetch is OpenRouter:

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

and `callLlm`/`streamLlm` are imported only from `app/api/**/route.ts` files and the server-only `app/lib/formalization/artifactRoute.ts` (which imports `NextRequest`/`NextResponse` at `app/lib/formalization/artifactRoute.ts:1`); the one client-side reference is a type-only import (`import type { LlmCallUsage } from "@/app/lib/llm/callLlm"` at `app/lib/formalization/api.ts:3`), which is erased at compile time. So no browser-to-third-party call exists, and `connect-src 'self'` is sufficient — the docstring's bottom line holds.

The imprecision: **there are no OpenAlex calls anywhere in the codebase** — `rg -i openalex` outside node_modules matches only this docstring itself, and `git grep -i openalex d86d2dc` returns nothing, so the reference did not exist even before this branch (paraphrased — no quote available because the claim covers absence of code: zero matching grep results). "Anthropic" likewise names no direct Anthropic API call; it appears only as an OpenRouter model-id prefix (`export const CLAUDE_OPUS = "anthropic/claude-opus-4.6"` at `app/lib/llm/models.ts:2`). The precise version would be: "the only third-party API call is OpenRouter (which routes to Anthropic models), made from server-side API route code." Note: the full-1 security review repeated the OpenAlex enumeration as "independently confirmed"; it is not confirmable on this state.

**Evidence:** `app/lib/llm/callLlm.ts:7,164`, `app/lib/llm/streamLlm.ts:249`, `app/lib/llm/models.ts:2`, `app/lib/formalization/api.ts:3-18`, `app/lib/formalization/artifactRoute.ts:1-4`, `app/hooks/useAnalytics.ts:11,30`

---

## Claim 8: "Why `'unsafe-eval'` in development only: Next's dev server loads modules and applies Fast Refresh through eval-based bundles ... Production builds do not depend on eval (pdfjs-dist probes for it with `new Function("")`, but that probe is caught and pdfjs falls back — it only logs a CSP violation), so the carve-out is gated on the environment and never ships in a production build."

**Location:** `app/lib/security/csp.ts:25-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium

The pdfjs probe claim is exactly right in the installed pdfjs-dist:

```js
// node_modules/pdfjs-dist/build/pdf.mjs:506-512
function isEvalSupported() {
  try {
    new Function("");
    return true;
  } catch {
    return false;
  }
}
```

and the consumer treats it as a feature flag rather than a hard requirement (`const isEvalSupported = src.isEvalSupported !== false;` at `node_modules/pdfjs-dist/build/pdf.mjs:14689`). The gate itself is the `nodeEnv === "development"` comparison quoted under Claim 3, and in a production deployment `NODE_ENV` is `"production"`, so the directive is absent. That Next's dev server specifically relies on eval-based module loading and Fast Refresh is paraphrased — no quote available because it is bundler runtime behavior spread across Next's dev-server internals; this is the reason for Medium rather than High confidence. Note the gate is evaluated per-request from the runtime `NODE_ENV` (default parameter at `app/lib/security/csp.ts:43`), not baked at build time — "never ships in a production build" is accurate in effect for any correctly configured production process.

**Evidence:** `node_modules/pdfjs-dist/build/pdf.mjs:506-519,14689`, `app/lib/security/csp.ts:41-47`

---

## Claim 9: "`nodeEnv` is a parameter rather than an ambient `process.env` read so the production branch can be observed from a test process without mutating global state. The comparison is against the *permissive* value, so any unset, misspelled, or unexpected environment yields the stricter policy."

**Location:** `app/lib/security/csp.ts:34-40`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High

The signature matches the described mechanism:

```ts
// app/lib/security/csp.ts:41-45
export function buildCsp(
  nonce: string,
  nodeEnv: string | undefined = process.env.NODE_ENV,
): string {
  const devEvalDirective = nodeEnv === "development" ? " 'unsafe-eval'" : "";
```

Tests pass `"production"` explicitly (`buildCsp(NONCE, "production")` at `app/lib/security/csp.test.ts:18` et al.) without touching `process.env`. The fail-closed half is the same invariant verified under Claim 3, and it is the same `=== "development"` comparison the commit message says was "unchanged, only relocated" — `git show e5d95a9:proxy.ts` contains the identical comparison (paraphrased — no quote available because the claim is about commit history rather than current-state code).

**Evidence:** `app/lib/security/csp.ts:41-47`, `app/lib/security/csp.test.ts:18,53-59`

---

## Claim 10: "html-to-image's `toBlob` goes canvas → `canvas.toBlob()`, staying entirely within the DOM. The `toPng` + `fetch(dataUrl)` route it replaces looked equivalent but is not: `fetch()` of a `data:` URL is governed by `connect-src`, which the app's CSP scopes to `'self'`, so that route throws a TypeError at runtime."

**Location:** `app/lib/utils/exportGraph.ts:16-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The installed html-to-image's `toBlob` is canvas → `canvasToBlob`, with no fetch on that path:

```js
// node_modules/html-to-image/es/index.js:52-56
export async function toBlob(node, options = {}) {
    const canvas = await toCanvas(node, options);
    const blob = await canvasToBlob(canvas);
    return blob;
}
```

```js
// node_modules/html-to-image/es/util.js:128-131
export function canvasToBlob(canvas, options = {}) {
    if (canvas.toBlob) {
        return new Promise((resolve) => {
            canvas.toBlob(resolve, options.type ? options.type : 'image/png', ...
```

(The no-`toBlob` fallback in `util.js:134-146` decodes via `window.atob`, also fetch-free.) One qualifier for the "entirely within the DOM" phrasing under its broadest reading: the shared `toCanvas` → `toSvg` step calls `embedWebFonts`/`embedImages` (`node_modules/html-to-image/es/index.js:9-10`), which can `fetch` same-origin subresources (stylesheets, images) via `fetchAsDataURL` (`node_modules/html-to-image/es/dataurl.js:10-11`). Those fetches existed identically in the replaced `toPng` route (which is `toCanvas` + `canvas.toDataURL()` per `index.js:44-47`) and are same-origin, hence permitted by `connect-src 'self'`. The delta the comment describes — eliminating the `connect-src`-blocked `fetch(dataUrl)` — is exactly what the code change does. That a CSP-blocked fetch rejects with a TypeError is paraphrased — no quote available because it is Fetch/CSP specification behavior, not repo code.

**Evidence:** `node_modules/html-to-image/es/index.js:44-56`, `node_modules/html-to-image/es/util.js:128-146`, `node_modules/html-to-image/es/dataurl.js:10-11`, `app/lib/utils/exportGraph.ts:24-32`, `app/lib/security/csp.ts:52`

---

## Claim 11: Null-failure handling — `renderGraphToBlob` throws when `toBlob` yields no blob, and both call sites go through the shared helper

**Location:** `app/lib/utils/exportGraph.ts:24-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`canvas.toBlob` can invoke its callback with `null`, which html-to-image resolves through unchanged (`canvas.toBlob(resolve, ...)` at `node_modules/html-to-image/es/util.js:131` — the resolve callback receives whatever the browser passes, including null). The helper handles it:

```ts
// app/lib/utils/exportGraph.ts:29-31
if (!blob) {
    throw new Error("Failed to render graph to an image");
}
```

Both exported functions route through it — `downloadGraphAsPng` (`const blob = await renderGraphToBlob(viewportElement);` at `app/lib/utils/exportGraph.ts:39`) and `graphToPngBlob` (`return renderGraphToBlob(viewportElement);` at `app/lib/utils/exportGraph.ts:47`). The downstream callers `app/lib/utils/exportAll.ts` and `app/components/panels/GraphPanel.tsx` contain no direct `toPng`/`toBlob`/`fetch` usage (paraphrased — no quote available because the claim covers absence of code: `rg -n "toPng|toBlob|fetch"` over those two files returns nothing).

**Evidence:** `app/lib/utils/exportGraph.ts:24-48`, `node_modules/html-to-image/es/util.js:128-133`

---

## Claim 12: "`NextResponse.next({ request: { headers } })` cannot expose the mutated request directly — it encodes the forwarded headers onto the response as `x-middleware-request-<name>`, which Next unpacks before rendering."

**Location:** `proxy.test.ts:8-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The installed Next does exactly this encoding:

```js
// node_modules/next/dist/server/web/spec-extension/response.js:36,39
headers.set('x-middleware-request-' + key, value);
...
headers.set('x-middleware-override-headers', keys.join(','));
```

That Next unpacks these before rendering is paraphrased — no quote available because the unpacking happens in the router/server request-adaptation layer across multiple files in `next/dist/server/`; the encoding side quoted above is what the test helper (`forwardedRequestHeader`, `proxy.test.ts:15-19`) directly depends on, and the observed test run (11/11 passing, see Claim 17) confirms the round-trip.

**Evidence:** `node_modules/next/dist/server/web/spec-extension/response.js:30-40`, `proxy.test.ts:8-19`

---

## Claim 13: "Deleting the `requestHeaders.set("Content-Security-Policy", csp)` line in proxy.ts must fail this test" — and commit f25d968's "Falsification verified: deleting the requestHeaders.set line in proxy.ts fails 2 of its 5 tests."

**Location:** `proxy.test.ts:30-31` (and commit f25d968 message)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium

Verified by reading the assertions (the worktree was not mutated, per the historical rule — hence Medium rather than High). With `proxy.ts:26` deleted, `requestHeaders` would still be mutated (the `x-nonce` set at `proxy.ts:31` remains), so `NextResponse.next` still emits `x-middleware-request-*` headers — but no `x-middleware-request-content-security-policy`. Consequences per test:

- Test 1 ("sets the CSP on the forwarded REQUEST headers") fails: `expect(requestCsp).toBeTruthy()` (`proxy.test.ts:37`) receives `null`.
- Test 2 ("sets the same policy on the response") fails: the response header is still set (`response.headers.set("Content-Security-Policy", csp)` at `proxy.ts:36`) while the forwarded value is `null`, so `toBe` (`proxy.test.ts:47-49`) mismatches.
- Tests 3, 4, 5 pass: test 3 reads only the response header (`proxy.test.ts:53-56`), test 4 compares `x-nonce` (still forwarded) against the response policy (still set, `proxy.test.ts:66-72`), test 5 checks only `x-nonce` clobbering (`proxy.test.ts:76-84`).

That is exactly 2 of 5, matching the commit's count.

**Evidence:** `proxy.test.ts:26-85`, `proxy.ts:25-36`

---

## Claim 14: "@vitest-environment node — NextRequest/NextResponse need the Node web-standard Request/Response globals, which the default jsdom environment does not provide."

**Location:** `proxy.test.ts:1-3`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High

The project default is indeed jsdom:

```ts
// vitest.config.ts:8
environment: 'jsdom',
```

Executing the two new test files in this sandbox confirmed the node-environment pragma is honored: both files ran and passed (11 tests) even while vitest reported `MISSING DEPENDENCY Cannot find dependency 'jsdom'` for the default environment (paraphrased — no quote available because this is observed tool output from `npx vitest run app/lib/security/csp.test.ts proxy.test.ts`, not source code). That jsdom's environment lacks the exact web-standard `Request`/`Response` globals `NextRequest` requires is paraphrased — no quote available because it is a property of the jsdom runtime, not statically quotable; the pragma's necessity is consistent with the observed pass under the node environment.

**Evidence:** `vitest.config.ts:6-11`, `proxy.test.ts:1-6`, `package.json:48`

---

## Claim 15: "Next 16's Proxy always runs on the Node.js runtime (it cannot be moved to Edge), so `crypto.randomUUID` and `Buffer` are both available as Node core APIs." (and commit R4: "Next 16 Proxy always runs on Node.js (get-page-static-info.js)")

**Location:** `proxy.ts:12-14`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The installed Next enforces this, in the exact file the commit cites — attempting to configure a runtime in a proxy file is an error whose message states the invariant:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

(In dev it force-resolves `resolvedRuntime = _constants.SERVER_RUNTIME.nodejs;` at `get-page-static-info.js:581`; in build it throws.) `crypto.randomUUID` and `Buffer` being Node core APIs is paraphrased — no quote available because it is Node.js platform surface, not repo code; both are standard since well before the Node version Next 16 supports.

**Evidence:** `node_modules/next/dist/build/analysis/get-page-static-info.js:573-588`, `proxy.ts:11-16`

---

## Claim 16: "Next reads the nonce out of the *request* Content-Security-Policy header (see `next/dist/server/app-render/app-render.js`) ... Setting the header only on the response is not enough ... because 'strict-dynamic' makes CSP3 browsers ignore 'self' — the app's own scripts are blocked and hydration never runs. So the same policy string goes on both the forwarded request and the response."

**Location:** `proxy.ts:18-24`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The file reference is exact — see the quote under Claim 1 (`app-render.js:166-167`, inside `parseRequestHeaders`). The code does set the same string both places:

```ts
// proxy.ts:26,36
requestHeaders.set("Content-Security-Policy", csp);
...
response.headers.set("Content-Security-Policy", csp);
```

and `proxy.test.ts:44-49` asserts response and forwarded-request values are identical. The `'strict-dynamic'` semantics — CSP3 browsers ignoring `'self'`/host allowlist entries when `'strict-dynamic'` is present, so un-nonced own-origin scripts are blocked — is paraphrased — no quote available because it is CSP Level 3 specification behavior, not repo code.

**Evidence:** `node_modules/next/dist/server/app-render/app-render.js:166-167`, `proxy.ts:17-37`, `proxy.test.ts:26-49`

---

## Claim 17: "x-nonce is the conventional seam for server components that render their own `<Script>` tags. Nothing reads it today (Next handles its own bootstrap scripts via the header above); `.set` rather than `.append` so a client-supplied value is clobbered rather than joined into a comma-list."

**Location:** `proxy.ts:27-30`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High

"Nothing reads it today": no app code reads `x-nonce` (paraphrased — no quote available because the claim covers absence of code; `rg -n "x-nonce"` outside node_modules matches only `proxy.ts:27-31`, `proxy.test.ts`, and the layout comment that says it is *not* read). The clobbering behavior is `Headers.prototype.set` semantics, asserted directly by the test:

```ts
// proxy.test.ts:77-83
headers: { "x-nonce": "attacker-supplied" },
...
expect(forwardedRequestHeader(response, "x-nonce")).not.toContain(
  "attacker-supplied",
);
```

This is the rationale comment the commit says was "restored as a comment rather than deleted" (Y1 deferred) — present as described.

**Evidence:** `proxy.ts:27-31`, `proxy.test.ts:76-84`, `app/layout.tsx:31-32`

---

## Claim 18: Commit f25d968 — "26 test files / 232 tests pass (was 24 / 221)" and matcher comment "Apply CSP to page navigations only. Skip API routes ..., Next's static assets ..., and prefetches"

**Location:** commit f25d968 (message) and `proxy.ts:40-52`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High

Static counts match exactly: `rg --files -g '*.test.*'` (excluding node_modules) finds 26 files, and counting `it(`/`test(` block openers across them totals 232, with no `it.each`/`test.each` multipliers present (paraphrased — no quote available because the claim is aggregate counts across 26 files, not a snippet). The 11 new tests (6 in csp.test.ts + 5 in proxy.test.ts) were additionally executed in this sandbox and all pass; the full 232-test run was not reproduced here (jsdom dependency resolution fails in this sandbox for the other 24 files), so the "pass" status of the pre-existing 221 rests on the commit's own report plus their being untouched by this diff. The matcher comment matches its config:

```ts
// proxy.ts:45-49
source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
missing: [
    { type: "header", key: "next-router-prefetch" },
    { type: "header", key: "purpose", value: "prefetch" },
],
```

The negative-lookahead excludes exactly the listed paths, and `next-router-prefetch` is Next's real prefetch header (`const NEXT_ROUTER_PREFETCH_HEADER = 'next-router-prefetch';` at `node_modules/next/dist/client/components/app-router-headers.js:106`).

**Evidence:** `proxy.ts:40-52`, `node_modules/next/dist/client/components/app-router-headers.js:106`, `app/lib/security/csp.test.ts:16-72`, `proxy.test.ts:25-85`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 7** (`app/lib/security/csp.ts:20-24`): `connect-src 'self'` sufficiency is correct, but the enumeration is wrong — no OpenAlex integration exists anywhere in the codebase (or its history at d86d2dc), and "Anthropic" is reached only as an OpenRouter model-id prefix. Tighten to: "the only third-party API call is OpenRouter, made server-side from API route code."

### Unverifiable
- None (Claim 18's full-suite pass status is partially reproduced: the 11 new tests pass here; the remaining 221 could not be executed in this sandbox due to jsdom resolution, but the file/test counts are exact).

## Hallucination pattern log

No Incorrect verdicts; nothing qualifies for `docs/reviews/hallucination-patterns.md` (Claim 7's OpenAlex mention is an inaccurate enumeration inside an otherwise-correct rationale, not a fabricated symbol/API, and its verdict is Mostly accurate). No worktree writes were made in any case, per this run's constraints.

## Goal-Alignment Note
- Answered: All six brief items. (1) Request-header CSP wiring verified against Next's `parseRequestHeaders` (Claims 1, 16). (2) exportGraph toBlob path verified in installed html-to-image source, both call sites through the shared helper, null handling present (Claims 10, 11). (3) csp.ts nodeEnv parameter, `=== "development"` fail-closed, and docstring accuracy checked with a fresh client-network-call enumeration (Claims 3, 6, 7, 8, 9). (4) Falsification claim verified by assertion reading: exactly tests 1 and 2 of 5 fail if the set line is deleted (Claim 13). (5) Commit counts 26/232 verified statically and exactly; per-blocker claims R1-R4 all check out (Claims 1, 5, 9, 10, 13, 15, 18). (6) Comment sweep: layout comment now correct (request-header mechanism), x-nonce rationale restored and accurate, matcher comment matches config, runtime comment matches Next's enforcement.
- Out of scope: Runtime browser verification of the CSP (prod build + devtools) — the commit itself flags this as unavailable in the sandbox; R2/G1 remain runtime-unverified as the commit honestly states. Code-quality judgments on any of the above.
- Escalate: Loop-termination signal for the orchestrator: zero Incorrect and zero Stale findings; the sole residual is the Claim 7 OpenAlex/Anthropic enumeration (Mostly accurate, comment-only, amber-scope at most). Note that full-1's security review asserted the OpenAlex claim was "independently confirmed" — that confirmation does not hold on this state and should not be carried forward.
