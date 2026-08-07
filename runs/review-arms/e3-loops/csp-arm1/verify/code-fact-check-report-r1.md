# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (branch `e3/csp-arm1`)
**Commit:** 1eb081e
**Scope:** `git diff d86d2dc..HEAD` — app/layout.tsx, app/lib/security/csp.ts, app/lib/security/csp.test.ts, app/lib/utils/exportGraph.ts, app/lib/utils/exportGraph.test.ts, proxy.ts, proxy.test.ts
**Checked:** 2026-08-06
**Total claims checked:** 18
**Summary:** 16 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

No `docs/reviews/hallucination-patterns.md` exists in the worktree; no fabricated-symbol findings arose that would warrant creating one (and the historical rule forbids worktree writes from this pass).

All 15 tests in the three new/changed test files pass (`npx vitest run proxy.test.ts app/lib/security/csp.test.ts app/lib/utils/exportGraph.test.ts` → "Test Files 3 passed (3), Tests 15 passed (15)"). The known `MISSING DEPENDENCY Cannot find dependency 'jsdom'` line reproduced and remains an environment artifact, consistent with the acked 🟡-9 disposition — the suite completes green regardless.

---

## Claim 1: "Next tags its own bootstrap `<script>` elements with the nonce it parses out of the *request* Content-Security-Policy header, which proxy.ts sets on the forwarded request headers — not out of the response header. We therefore don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:26-32`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High

Next parses the nonce from the incoming request headers, not the response:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167 (inside parseRequestHeaders)
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

The enclosing function is `function parseRequestHeaders(headers, options)` (`node_modules/next/dist/server/app-render/app-render.js:155`), so the headers consulted are request headers. proxy.ts sets exactly that header on the forwarded request: `requestHeaders.set("Content-Security-Policy", csp)` (`proxy.ts:31`). The "we don't need to read x-nonce" part holds: grepping the repo for `x-nonce` finds only the proxy.ts comment, the layout.tsx comment, and the proxy.test.ts absence-assertion — no reader (paraphrased — no quote available because the claim covers absence of code; grep for `x-nonce` returns only comment/test hits at `proxy.ts:33`, `app/layout.tsx:32`, `proxy.test.ts:79,82`).

**Evidence:** `node_modules/next/dist/server/app-render/app-render.js:155-167`, `proxy.ts:30-31`, `proxy.test.ts:79-83`

---

## Claim 2: "the app is a single \"use client\" route with no generateStaticParams, revalidate, or ISR"

**Location:** `app/layout.tsx:39-42`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The only page route in the app directory is `app/page.tsx` (the other `app/` subdirectories are `api`, `components`, `hooks`, `lib` — none contain a `page.tsx`; paraphrased — no quote available because the claim is about directory layout, not a snippet). That page is a client component:

```tsx
// app/page.tsx:1
"use client";
```

`generateStaticParams` and `revalidate` appear nowhere in `app/**` except inside this very comment (`app/layout.tsx:41-42`) (paraphrased — no quote available because the claim covers absence of code; grep returns only the comment itself).

**Evidence:** `app/page.tsx:1`, `app/layout.tsx:41-42`

---

## Claim 3: "The cost is one SSR shell render per navigation instead of a cached prerender, and the document is no longer shared- or CDN-cacheable ... (Unmeasured: the two numbers that would size it are the build output's static/dynamic marker and one TTFB sample.)"

**Location:** `app/layout.tsx:34-42`
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** Medium

The mechanism is real: `await headers();` (`app/layout.tsx:43`) is a Next dynamic API call that opts the route out of static prerendering, which is what forfeits the cached prerender (paraphrased — no quote available because the static-vs-dynamic consequence is framework behavior spanning Next's render pipeline, not a single quotable line). The comment honestly self-labels the magnitude as unmeasured, which is the correct calibration — this pass did not build the app either, so the "one SSR shell render per navigation" cost remains a stated, not measured, figure. "Mostly accurate" rather than "Verified" only because the cacheability consequence depends on response headers Next emits at runtime, which static analysis cannot confirm; the comment's own "(Unmeasured: ...)" hedge already concedes exactly this.

**Evidence:** `app/layout.tsx:23-43`

---

## Claim 4: "Regression guard: graph PNG/zip export must decode canvases in-DOM (`exportGraph.ts` uses `toBlob`) rather than `fetch()`-ing a data URL, which would be blocked here."

**Location:** `app/lib/security/csp.test.ts:67-70`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

`exportGraph.ts` does use `toBlob` and contains no `fetch()` call:

```ts
// app/lib/utils/exportGraph.ts:6
import { toBlob } from "html-to-image";
```

```ts
// app/lib/utils/exportGraph.ts:30-33
const blob = await toBlob(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
```

The "would be blocked" premise matches the built policy — `"connect-src 'self'"` (`app/lib/security/csp.ts:53`) — and the CSP spec point that `'self'` does not match `data:` URLs is standard Fetch/CSP behavior (paraphrased — no quote available because the claim is about the CSP specification, not repo code).

**Evidence:** `app/lib/utils/exportGraph.ts:6,30-33`, `app/lib/security/csp.ts:53`, `app/lib/security/csp.test.ts:66-72`

---

## Claim 5: "Extracted from `proxy.ts` so the policy ... can be imported and asserted on directly (see `csp.test.ts`). The proxy entry point stays a thin wiring layer."

**Location:** `app/lib/security/csp.ts:4-7`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High

`proxy.ts` imports the policy builder rather than defining any directive itself:

```ts
// proxy.ts:3
import { buildCsp } from "@/app/lib/security/csp";
```

`csp.test.ts` exists and imports `buildCsp` directly (`app/lib/security/csp.test.ts:2`: `import { buildCsp } from "./csp";`). No policy directive strings appear in `proxy.ts` (paraphrased — no quote available because the claim covers absence of code; the only CSP-content lines in proxy.ts are the `buildCsp` call and header sets).

**Evidence:** `proxy.ts:3,19`, `app/lib/security/csp.test.ts:2`

---

## Claim 6: "Why `style-src 'unsafe-inline'`: the dependents are React `style={{...}}` attributes across the component tree, reactflow's per-node transform styles, KaTeX's inline-styled output, `next/font`'s injected declarations, and dev-time HMR style injection — not Tailwind, which compiles to an external stylesheet here."

**Location:** `app/lib/security/csp.ts:13-19`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

Each named dependent checks out. React inline styles: `style={{` appears in multiple components, e.g. `app/components/features/proof-graph/ProofGraphNode.tsx`, `app/components/features/causal-graph/CausalGraphNode.tsx` (paraphrased — no quote available because the claim spans many files; grep for `style={{` hits 5+ component files). KaTeX writes element styles: `node.style[key] = this.style[key];` (`node_modules/katex/dist/katex.js:1086`). The packages are all present: `"katex": "^0.16.45"`, `"reactflow": "^11.11.4"`, `"tailwindcss": "^4"` (`package.json:21,29,49`), and `next/font` is used in the layout: `import { EB_Garamond, Geist_Mono } from "next/font/google";` (`app/layout.tsx:2`). Tailwind v4 via `@tailwindcss/postcss` compiles into the imported external stylesheet (`app/layout.tsx:4`: `import "./globals.css";`). Confidence is Medium only because reactflow's per-node transform styling and dev-HMR injection are third-party runtime behaviors I confirmed by package presence and general library behavior rather than by tracing every style write (paraphrased — no quote available because the behavior lives in minified vendor bundles).

**Evidence:** `app/lib/security/csp.ts:13-19`, `node_modules/katex/dist/katex.js:1086`, `package.json:21,29,49`, `app/layout.tsx:2,4`

---

## Claim 7: "`connect-src 'self'` is sufficient because no browser-side code calls a third-party origin: every outbound call is made server-side from `app/api/**`."

**Location:** `app/lib/security/csp.ts:21-24`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High

This is the invariant that replaced the earlier phantom enumeration; I re-swept the current tree. The only third-party fetch targets in the codebase are the OpenRouter calls: `const response = await fetch(OPENROUTER_API_URL, {` (`app/lib/llm/callLlm.ts:164`, similarly `app/lib/llm/streamLlm.ts:249`). Those two modules are imported exclusively by `app/api/**/route.ts` files and by `app/lib/formalization/artifactRoute.ts`, which is itself imported only by six `app/api/formalization/*/route.ts` files (paraphrased — no quote available because the invariant is inferred from multiple call sites; grep for `callLlm|streamLlm` importers returns only `app/api/**` routes, `artifactRoute.ts`, and test files, and grep for `artifactRoute` importers returns only `app/api/formalization/*/route.ts`).

Every browser-side fetch goes through `fetchApi`/`fetchStreamingApi` (`app/lib/formalization/api.ts:10,38`) or hard-coded route strings, and every URL passed is a relative `/api/...` path — e.g. `fetchApi<{ text: string }>("/api/edit/artifact", {` (`app/hooks/useArtifactEditing.ts:39`), `"/api/decomposition/extract"` (`app/hooks/useDecomposition.ts:130`), and the route table:

```ts
// app/lib/types/artifacts.ts:192-198
export const ARTIFACT_ROUTE: Partial<Record<ArtifactType, string>> = {
  "causal-graph": "/api/formalization/causal-graph",
  "statistical-model": "/api/formalization/statistical-model",
  "property-tests": "/api/formalization/property-tests",
  "dialectical-map": "/api/formalization/dialectical-map",
  counterexamples: "/api/formalization/counterexamples",
};
```

One same-origin nuance does not violate the claim: html-to-image's `toCanvas` pipeline can `fetch()` same-origin webfonts (see Claim 12), which is a browser-side outbound call — but to `'self'`, not a third-party origin, and the adjacent `exportGraph.ts` comment discloses it.

**Evidence:** `app/lib/llm/callLlm.ts:164`, `app/lib/llm/streamLlm.ts:249`, `app/lib/formalization/api.ts:10,38,104,121,137,146,159`, `app/lib/types/artifacts.ts:192-198`, `app/hooks/useArtifactEditing.ts:39,48`, `app/hooks/useDecomposition.ts:130`, `app/components/panels/OutputPanel.tsx:50,66`, `app/components/panels/SemiformalPanel.tsx:43,59`, `app/components/features/output-editing/EditableSection.tsx:77,84`

---

## Claim 8: "pdfjs-dist probes for it with `new Function(\"\")`, but that probe is caught and pdfjs falls back — it only logs a CSP violation"

**Location:** `app/lib/security/csp.ts:29-31`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The probe exists exactly as described, wrapped in try/catch:

```js
// node_modules/pdfjs-dist/build/pdf.mjs:506-513
function isEvalSupported() {
  try {
    new Function("");
    return true;
  } catch {
    return false;
  }
}
```

and consumers branch on it: `const isEvalSupported = src.isEvalSupported !== false;` (`node_modules/pdfjs-dist/build/pdf.mjs:14689`). The "only logs a CSP violation" clause is browser behavior for a caught CSP-blocked eval (the violation report fires even when the exception is caught) — standard CSP semantics (paraphrased — no quote available because the claim is about browser CSP reporting behavior, not repo code). pdfjs-dist is a real dependency: `"pdfjs-dist": "^5.6.205"` (`package.json:25`).

**Evidence:** `node_modules/pdfjs-dist/build/pdf.mjs:506-519,14689`, `package.json:25`

---

## Claim 9: "`nodeEnv` is a required parameter rather than an ambient `process.env` read ... It is deliberately not defaulted ... The comparison is against the *permissive* value, so any unset, misspelled, or unexpected environment yields the stricter policy"

**Location:** `app/lib/security/csp.ts:36-45`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High

The signature has no default and the function body reads no ambient state:

```ts
// app/lib/security/csp.ts:46-47
export function buildCsp(nonce: string, nodeEnv: string | undefined): string {
  const devEvalDirective = nodeEnv === "development" ? " 'unsafe-eval'" : "";
```

The comparison is against `"development"` (the permissive value), so `undefined`, `""`, `"Development"`, `"prod"` etc. all fall to the strict branch — asserted by the fail-closed test looping over exactly those values (`app/lib/security/csp.test.ts:53-59`). The one production call site passes the environment explicitly:

```ts
// proxy.ts:19
const csp = buildCsp(nonce, process.env.NODE_ENV);
```

No other call site exists that could rely on a default: `buildCsp` is referenced only in `proxy.ts`, `csp.ts`, and `csp.test.ts`, and every `csp.test.ts` call passes an explicit second argument (paraphrased — no quote available because the claim covers absence of code; grep for `buildCsp(` shows two-argument calls everywhere). `NODE_ENV` is read nowhere else in the repo's own code — grep hits only `proxy.ts:19` (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `app/lib/security/csp.ts:36-47`, `proxy.ts:16-19`, `app/lib/security/csp.test.ts:16,42-59`

---

## Claim 10: "`csp.test.ts` fires if someone widens `connect-src` to allow `data:`; these tests fire if someone narrows the export path back to `toPng` + `fetch(dataUrl)`"

**Location:** `app/lib/utils/exportGraph.test.ts:5-12`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

Both halves of the bidirectional guard exist. The CSP side: `expect(parse(buildCsp(NONCE, "production"))["connect-src"]).toBe("'self'");` (`app/lib/security/csp.test.ts:71`) — any widening changes the string and fails. The export side:

```ts
// app/lib/utils/exportGraph.test.ts:38-42
expect(toBlob).toHaveBeenCalledWith(element, expect.anything());
expect(toPng).not.toHaveBeenCalled();
// `fetch()` of a data: URL is governed by `connect-src 'self'` and throws.
expect(globalThis.fetch).not.toHaveBeenCalled();
```

Reintroducing `toPng` + `fetch(dataUrl)` trips the second and third assertions. All three exportGraph tests pass in the current run (paraphrased — no quote available because the evidence is a test-run result: 15/15 passing).

**Evidence:** `app/lib/security/csp.test.ts:66-72`, `app/lib/utils/exportGraph.test.ts:36-64`

---

## Claim 11: "html-to-image's `toBlob` goes canvas → `canvas.toBlob()` where available, so the final decode stays in-DOM. (The shared `toCanvas` pipeline may still `fetch()` same-origin webfonts and images to inline them ...) The legacy `toDataURL` fallback inside the library reconstructs the base64 round-trip this replaced, so the fast path is a runtime choice, not a guarantee of the import."

**Location:** `app/lib/utils/exportGraph.ts:16-27`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

All three sub-claims match the vendored library. `toBlob` → `toCanvas` → `canvasToBlob`: `case 0: return [4 /*yield*/, toCanvas(node, options)]; ... [4 /*yield*/, (0, util_1.canvasToBlob)(canvas)]` (`node_modules/html-to-image/lib/index.js:157-174`). `canvasToBlob` prefers the in-DOM path and falls back to a base64 round-trip:

```js
// node_modules/html-to-image/lib/util.js:181-189
if (canvas.toBlob) {
    return new Promise(function (resolve) {
        canvas.toBlob(resolve, options.type ? options.type : 'image/png', options.quality ? options.quality : 1);
    });
}
return new Promise(function (resolve) {
    var binaryString = window.atob(canvas
        .toDataURL(options.type ? options.type : undefined, options.quality ? options.quality : undefined)
        .split(',')[1]);
```

(Note the fallback decodes via `atob`, not `fetch()`, so even the slow path is not `connect-src`-governed — the comment's phrase "base64 round-trip" is precisely right and does not overclaim a fetch.) The webfont caveat: `return [4 /*yield*/, fetch(url)];` inside `fetchCSS` (`node_modules/html-to-image/lib/embed-webfonts.js:54`), invoked from the shared embed pipeline.

**Evidence:** `node_modules/html-to-image/lib/index.js:157-174`, `node_modules/html-to-image/lib/util.js:179-199`, `node_modules/html-to-image/lib/embed-webfonts.js:44-54,151,178`

---

## Claim 12: "The `toPng` + `fetch(dataUrl)` route it replaces looked equivalent but is not: `fetch()` of a `data:` URL is governed by `connect-src`, which the app's CSP scopes to `'self'`, so that route throws a TypeError at runtime."

**Location:** `app/lib/utils/exportGraph.ts:23-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium

The policy half is directly quotable: `"connect-src 'self'"` (`app/lib/security/csp.ts:53`). That `fetch()` of a `data:` URL is subject to `connect-src` and that `'self'` does not match the `data:` scheme — hence a blocked fetch rejecting with a TypeError — is CSP/Fetch spec behavior (paraphrased — no quote available because the claim is about browser specification behavior, not repo code; verifying the exact thrown type would require a browser runtime, hence Medium rather than High).

**Evidence:** `app/lib/security/csp.ts:53`, `app/lib/utils/exportGraph.ts:23-27`

---

## Claim 13: "`NextResponse.next({ request: { headers } })` cannot expose the mutated request directly — it encodes the forwarded headers onto the response as `x-middleware-request-<name>`, which Next unpacks before rendering."

**Location:** `proxy.test.ts:8-13`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

Next's response builder does exactly this encoding:

```js
// node_modules/next/dist/server/web/spec-extension/response.js:36-39
headers.set('x-middleware-request-' + key, value);
// ...
headers.set('x-middleware-override-headers', keys.join(','));
```

The test helper reads them back with the same prefix (`proxy.test.ts:18`: `return response.headers.get(\`x-middleware-request-${name}\`);`), and the first proxy test also asserts the companion `x-middleware-override-headers` entry (`proxy.test.ts:40-42`), which passes.

**Evidence:** `node_modules/next/dist/server/web/spec-extension/response.js:36-39`, `proxy.test.ts:14-19,31-43`

---

## Claim 14: "Deleting the `requestHeaders.set(\"Content-Security-Policy\", csp)` line in proxy.ts must fail this test."

**Location:** `proxy.test.ts:27-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The referenced line exists verbatim: `requestHeaders.set("Content-Security-Policy", csp);` (`proxy.ts:31`). Without it, no forwarded-request CSP header is encoded, so `forwardedRequestHeader(response, "content-security-policy")` returns `null` and the assertion `expect(requestCsp).toBeTruthy();` (`proxy.test.ts:37`) fails; the nonce-pattern and override-headers assertions (`proxy.test.ts:38-42`) would fail as well (paraphrased — no quote available because the claim is a counterfactual about deleted code, inferred from the header-encoding mechanism quoted in Claim 13).

**Evidence:** `proxy.ts:30-31`, `proxy.test.ts:31-43`

---

## Claim 15: "No `x-nonce` header: the conventional seam for server components rendering their own `<Script>` tags had no readers, and a published-but-unread header reads as live plumbing. Reinstate it here (with a test) at the same time as the first component that actually consumes it." (and the matching test comment "The seam had no readers")

**Location:** `proxy.ts:33-36`, `proxy.test.ts:80-81`
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High

The write is gone — `proxy.ts` contains no `requestHeaders.set("x-nonce", ...)` — and no reader ever existed: a repo-wide grep for `x-nonce` (case-insensitive, plus `xNonce`/`x_nonce` variants) matches only the two comments and the absence-test (`proxy.ts:33`, `app/layout.tsx:32`, `proxy.test.ts:79,82`) (paraphrased — no quote available because the claim covers absence of code; grep returns no non-comment, non-test hits). The absence-test pins the deleted state:

```ts
// proxy.test.ts:82
expect(forwardedRequestHeader(run(), "x-nonce")).toBeNull();
```

and passes. The load-bearing property that replaced the old clobber test is asserted at `proxy.test.ts:66-77` — a client-supplied `content-security-policy` request header containing `'nonce-attacker'` is not present in the forwarded header (`expect(...).not.toContain("attacker");`, `proxy.test.ts:74-76`), matching `.set` semantics at `proxy.ts:31`.

**Evidence:** `proxy.ts:30-36`, `proxy.test.ts:66-83`, `app/layout.tsx:32`

---

## Claim 16: "CSP proxy (Next.js 16 renamed Middleware → Proxy)" and "Next 16's Proxy always runs on the Node.js runtime (it cannot be moved to Edge), so `crypto.randomUUID` and `Buffer` are both available as Node core APIs."

**Location:** `proxy.ts:6,13-15`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High

The installed Next is `"version": "16.2.4"` (`node_modules/next/package.json:3`). The rename is stated in Next's own types:

```ts
// node_modules/next/dist/server/web/types.d.ts:10-13
* @deprecated Use `ProxyConfig` instead. Middleware has been renamed to Proxy.
...
export type { MiddlewareConfigInput as ProxyConfig } from '../../build/segment-config/middleware/middleware-config';
```

The Node-runtime-only claim is enforced by Next's build with an error message that mirrors the comment almost verbatim:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

`crypto.randomUUID` and `Buffer` being Node core APIs on that runtime is standard Node behavior (paraphrased — no quote available because the claim is about the Node platform, not repo code).

**Evidence:** `node_modules/next/package.json:3`, `node_modules/next/dist/server/web/types.d.ts:10-13`, `node_modules/next/dist/build/analysis/get-page-static-info.js:576`, `proxy.ts:14`

---

## Claim 17: "Typed against Next's own `ProxyConfig` (matching `next.config.ts`'s `NextConfig` annotation) so a typo in a matcher key — `missng:` for `missing:`, `sources:` for `source:` — fails the type check instead of silently changing which responses carry a CSP."

**Location:** `proxy.ts:44-47`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High

The type is imported from Next's public server entry: `import type { NextRequest, ProxyConfig } from "next/server";` (`proxy.ts:2`), and Next re-exports it there (`node_modules/next/server.d.ts:14`: `ProxyConfig,`). The underlying shape has exactly the `source`/`has`/`missing` keys the comment names:

```ts
// node_modules/next/dist/build/segment-config/middleware/middleware-config.d.ts:2-11
export type MiddlewareConfigInput = {
    matcher?: string | Array<{
        locale?: false;
        has?: RouteHas[];
        missing?: RouteHas[];
        source: string;
    } | string>;
```

An excess/misspelled key in the object literal (`missng:`, `sources:`) violates this type under TypeScript's excess-property checking on a typed const (paraphrased — no quote available because the claim is about TypeScript compiler behavior on the quoted type, not a repo snippet). The sibling precedent is real: `const nextConfig: NextConfig = {` (`next.config.ts:3`).

**Evidence:** `proxy.ts:2,48`, `node_modules/next/server.d.ts:14`, `node_modules/next/dist/build/segment-config/middleware/middleware-config.d.ts:1-21`, `next.config.ts:1-3`

---

## Claim 18: "Apply CSP to page navigations only. Skip API routes (they don't render HTML) and Next's static assets (no scripts to nonce). Deliberately no `missing:` prefetch exclusion: every exclusion here must be server-determined ... Skipping on `purpose: prefetch` / `next-router-prefetch` saved ~0.75 µs of nonce generation and let any caller that sets those headers receive a rendered document with no CSP, no nonce, and no frame-ancestors."

**Location:** `proxy.ts:49-63`
**Type:** Configuration / Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** High

The matcher matches the described exclusions exactly and carries no header conditions:

```ts
// proxy.ts:58-62
matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
    },
  ],
```

The `missing:` block is fully gone — no `missing:` or `has:` key exists anywhere in `proxy.ts` outside comments, and the new test loops the config asserting `expect(matcher.missing).toBeUndefined(); expect(matcher.has).toBeUndefined();` (`proxy.test.ts:90-91`), which passes (paraphrased for the absence half — no quote available because the claim covers absence of code). So the comment now matches behavior: the proxy currently excludes exactly four server-determined path prefixes — `api`, `_next/static`, `_next/image`, `favicon.ico` — and nothing else.

Two small imprecisions keep this at Mostly accurate rather than Verified. First, "page navigations only" is slightly broader in practice: the negative-lookahead pattern matches *every* path outside those four prefixes, including RSC/prefetch fetches to the page route and any hypothetical non-page public asset (e.g. a future `/robots.txt`), not only document navigations. The exclusion list is accurate; the positive characterization is a rounding-up. Second, the "~0.75 µs" figure: a fresh microbenchmark of the nonce line (`Buffer.from(crypto.randomUUID()).toString("base64")`, 10^6 iterations on this machine) measured ~0.52 µs/op (paraphrased — no quote available because the evidence is a measurement run, not a source file). Same order of magnitude and the comment uses "~", so the rhetorical point (the saving was negligible) fully survives, but the constant is machine-dependent and ~30% high here.

**Evidence:** `proxy.ts:49-63`, `proxy.test.ts:85-94`

---

## Claims Requiring Attention

### Incorrect

None.

### Stale

None.

### Mostly Accurate

- **Claim 3** (`app/layout.tsx:34-42`): The dynamic-rendering cost accounting is mechanism-correct and self-labeled unmeasured; the cacheability consequence rests on runtime response headers not confirmable statically. No edit needed — the comment already hedges precisely where the uncertainty is.
- **Claim 18** (`proxy.ts:49-63`): "page navigations only" rounds up — the matcher applies to every request outside the four excluded prefixes (including RSC/prefetch fetches), not strictly document navigations; and "~0.75 µs" measured ~0.52 µs on this machine (same order, tilde-hedged). Optional tighten: "Apply CSP to everything except API routes and Next's static assets."

### Unverifiable

None.

## Goal-Alignment Note

- Answered: All seven brief items. (1) `buildCsp` has no default, sole production call site passes `process.env.NODE_ENV`, fail-closed comparison preserved and test-pinned (Claim 9). (2) `x-nonce` had zero readers ever; the write and its tests are gone; the replacement clobber test asserts the genuinely load-bearing `.set`-not-`.append` property on the forwarded CSP header (Claim 15). (3) The `missing:` block is gone; the comment now correctly states the four server-determined exclusions; new test enforces no header-keyed matcher conditions (Claim 18). (4) The connect-src invariant re-verified against current state: only third-party fetches are OpenRouter, reachable solely from `app/api/**`; all client fetches are relative `/api/...` (Claim 7). (5) Layout honest-cost rewrite and exportGraph toBlob/webfont-caveat comments both check out against the vendored library (Claims 3, 11, 12). (6) `ProxyConfig` correctly imported from `next/server`, resolving to `MiddlewareConfigInput` with the exact keys named (Claim 17). (7) Sweep for newly introduced Incorrect/Stale: none found — 0 Incorrect, 0 Stale across 18 claims; the two Mostly-accurate items are minor phrasing/constant imprecision, not disposition regressions. All 15 tests pass.
- Out of scope: 🟢-row items deliberately left untouched by the disposition commit (per the amber-dispositions notes); f25d968's commit-message framing (ACKED 🟡-9 — not re-raised; the jsdom MISSING DEPENDENCY artifact reproduced and remains environmental); anything on main, csp-arm2, or e1 artifacts (historical rule observed — only worktree-HEAD ancestors and this arm's advisory artifacts were read).
- Escalate: Nothing. Under the 0R+0A comment-accuracy standard this pass finds no red: no Incorrect, no Stale, no Unverifiable. The two Mostly-accurate notes (Claim 18's "page navigations only" phrasing and the machine-dependent µs constant; Claim 3's inherently-runtime cacheability clause) are advisory tightens, not blockers.
