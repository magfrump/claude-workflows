# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (branch `e3/csp-arm1`)
**Scope:** `git diff d86d2dc..HEAD` (HEAD = f25d968; commits 9b4e453, b25e939, d90d6bb, e5d95a9, f25d968) — files: `app/layout.tsx`, `app/lib/security/csp.ts`, `app/lib/security/csp.test.ts`, `app/lib/utils/exportGraph.ts`, `proxy.ts`, `proxy.test.ts`, plus commit-message claims of f25d968
**Commit:** f25d968
**Checked:** 2026-08-06
**Total claims checked:** 18
**Summary:** 14 verified, 2 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Historical rule respected: all evidence is from the worktree at f25d968 (ancestors only). This arm's full-1 reports were consulted as advisory hints only. No `docs/reviews/hallucination-patterns.md` exists in this tree.

---

## Claim 1: "Next tags its own bootstrap `<script>` elements with the nonce it parses out of the *request* Content-Security-Policy header, which proxy.ts sets on the forwarded request headers — not out of the response header."

**Location:** `app/layout.tsx:28-32`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** R1 (nonce wiring)

Next's app renderer extracts the nonce from the incoming request headers, not the response:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

These lines are inside `parseRequestHeaders(headers, options)` (`node_modules/next/dist/server/app-render/app-render.js:155`), whose input is the request header map (paraphrased — no quote available because the caller chain that feeds `req.headers` into `parseRequestHeaders` spans several render entry points in app-render.js). The extractor scans `script-src` then `default-src` for a `'nonce-…'` token:

```js
// node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:18
const directive = directives.find((dir)=>dir.startsWith('script-src')) || directives.find((dir)=>dir.startsWith('default-src'));
```

And proxy.ts now sets the policy on the forwarded request headers:

```ts
// proxy.ts:25-26
const requestHeaders = new Headers(request.headers);
requestHeaders.set("Content-Security-Policy", csp);
```

This corrects the full-1 headline finding (response-only delivery). The layout comment now matches the mechanism.

**Evidence:** `app/layout.tsx:27-42`, `proxy.ts:25-36`, `node_modules/next/dist/server/app-render/app-render.js:155-167`, `node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:12-28`

---

## Claim 2: "The app is a single 'use client' route with no generateStaticParams, revalidate, or ISR — so there is nothing static to lose."

**Location:** `app/layout.tsx:37-40`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** R1 (dynamic opt-out cost)

The only page in the app directory is `app/page.tsx` (paraphrased — no quote available because the claim is about file structure: `rg --files -g 'page.tsx' app` returns exactly one file), and it is a client component:

```tsx
// app/page.tsx:1
"use client";
```

Greps for `generateStaticParams` and `revalidate` across `app/` hit nothing except this comment's own text in `app/layout.tsx` (paraphrased — no quote available because the claim covers absence of code; no matching grep results outside the comment itself).

**Evidence:** `app/page.tsx:1`, `app/layout.tsx:37-40`

---

## Claim 3: "Regression guard: graph PNG/zip export must decode canvases in-DOM (`exportGraph.ts` uses `toBlob`) rather than `fetch()`-ing a data URL, which would be blocked here."

**Location:** `app/lib/security/csp.test.ts:68-70`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** R2 (export vs connect-src)

The referenced file does use `toBlob`:

```ts
// app/lib/utils/exportGraph.ts:25-28
const blob = await toBlob(viewportElement, {
  pixelRatio: 2,
  backgroundColor: EXPORT_BG,
});
```

No `fetch(` of a data URL remains anywhere in `app/lib/utils/` (paraphrased — no quote available because the claim covers absence of code; the only `fetch(` matches in exportGraph.ts are inside the warning comment itself). The guarded assertion matches the built policy: `"connect-src 'self'"` at `app/lib/security/csp.ts:52`.

**Evidence:** `app/lib/security/csp.test.ts:67-72`, `app/lib/utils/exportGraph.ts:24-33`, `app/lib/security/csp.ts:52`

---

## Claim 4: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust."

**Location:** `app/lib/security/csp.ts:8-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** General (policy rationale)

The built directive matches the described semantics:

```ts
// app/lib/security/csp.ts:48
`script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${devEvalDirective}`,
```

That CSP3 `'strict-dynamic'` grants transitive trust to scripts loaded by nonce-carrying scripts, and causes `'self'` to be ignored, is CSP specification behavior (paraphrased — no quote available because the claim is about the CSP3 specification, not repo code).

**Evidence:** `app/lib/security/csp.ts:45-48`

---

## Claim 5: "Why `style-src 'unsafe-inline'`: the dependents are React `style={{...}}` attributes …, reactflow's per-node transform styles, KaTeX's inline-styled output, `next/font`'s injected declarations, and dev-time HMR style injection — not Tailwind, which compiles to an external stylesheet here."

**Location:** `app/lib/security/csp.ts:13-18`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** General (style-src rationale)

The named dependents exist in this tree: `"reactflow": "^11.11.4"` and `"katex": "^0.16.45"` in `package.json`, and `next/font` is used in the layout:

```tsx
// app/layout.tsx:2
import { EB_Garamond, Geist_Mono } from "next/font/google";
```

Tailwind is imported via a stylesheet (`import "./globals.css"` at `app/layout.tsx:4`), consistent with "compiles to an external stylesheet". That every listed dependent actually injects inline styles at runtime is not statically checkable from this repo (paraphrased — no quote available because the inline-style behavior lives inside reactflow/KaTeX/next-font runtime output), hence Medium confidence; the misattribution-to-Tailwind error flagged in full-1 is gone.

**Evidence:** `app/lib/security/csp.ts:13-18`, `package.json` (reactflow, katex entries), `app/layout.tsx:2-5`

---

## Claim 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `app/lib/security/csp.ts:20-23`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** R2 / loop-termination sweep (connect-src enumeration)

The Anthropic and OpenRouter halves are correct. The only third-party network calls in `app/` are:

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

and the Anthropic SDK client (`import Anthropic from "@anthropic-ai/sdk"` at `app/lib/llm/callLlm.ts:2`). Every importer of `callLlm`/`streamLlm` is a server-side file — `app/api/*/route.ts` files and `app/lib/formalization/artifactRoute.ts`; `app/lib/formalization/api.ts` imports only a type (paraphrased — no quote available because the invariant is inferred from the full grep of import sites across nine files). Client-side code reaches the network only through relative-URL fetches of the app's own API routes:

```ts
// app/lib/formalization/api.ts:10-15
const res = await fetch(url, {
  method: "POST",
  ...
```

Re-enumeration on this state found no other client network APIs — no `XMLHttpRequest`, `EventSource`, `WebSocket`, or `sendBeacon` outside tests (paraphrased — no quote available because the claim covers absence of code; grep returned no matches). So `connect-src 'self'` is in fact sufficient.

The imprecision: **OpenAlex does not exist in this tree.** The only occurrence of the string in the entire non-node_modules tree is this docstring line itself (paraphrased — no quote available because the claim covers absence of code: `grep -rni openalex` excluding node_modules hits only `app/lib/security/csp.ts:20`). OpenAlex evidence-search code exists on `integration/6.1`, which is not an ancestor of this HEAD (`git merge-base --is-ancestor c5554f4 HEAD` → not-ancestor). On this branch state the docstring references an integration that isn't there — a docstring-reference-that-doesn't-grep. Harmless to the directive's correctness (it claims calls are server-side, and there are no such calls at all), but the enumeration is inaccurate for this tree.

**Evidence:** `app/lib/security/csp.ts:20-23`, `app/lib/llm/callLlm.ts:2-16`, `app/lib/llm/streamLlm.ts:1-10`, `app/lib/formalization/api.ts:10-17`

---

## Claim 7: "Note that it also governs `fetch()` of `data:` URLs — see `exportGraph.ts`, which decodes canvases with `toBlob` rather than re-fetching a data URL."

**Location:** `app/lib/security/csp.ts:22-23`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** R2

The cross-reference resolves: `exportGraph.ts` imports and calls `toBlob`:

```ts
// app/lib/utils/exportGraph.ts:6
import { toBlob } from "html-to-image";
```

That `fetch()` of a `data:` URL is governed by `connect-src` is Fetch/CSP specification behavior (paraphrased — no quote available because the claim is about the Fetch/CSP specs, not repo code).

**Evidence:** `app/lib/security/csp.ts:22-23`, `app/lib/utils/exportGraph.ts:6,24-33`

---

## Claim 8: "Production builds do not depend on eval (pdfjs-dist probes for it with `new Function("")`, but that probe is caught and pdfjs falls back — it only logs a CSP violation)."

**Location:** `app/lib/security/csp.ts:27-30`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** General (unsafe-eval rationale)

The probe exists exactly as described, inside a try/catch:

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

It feeds a cached `FeatureTest.isEvalSupported` getter (`node_modules/pdfjs-dist/build/pdf.mjs:518-520`), which gates eval use elsewhere in the library (paraphrased — no quote available because the fallback consumers are spread across the 500k-line pdf.mjs bundle). Medium confidence because "only logs a CSP violation" describes browser-console behavior under a blocking CSP, which cannot be confirmed statically.

**Evidence:** `app/lib/security/csp.ts:25-30`, `node_modules/pdfjs-dist/build/pdf.mjs:506-520`

---

## Claim 9: "Why `'unsafe-eval'` in development only: Next's dev server loads modules and applies Fast Refresh through eval-based bundles, so without this the dev console floods with EvalErrors and HMR breaks."

**Location:** `app/lib/security/csp.ts:25-27`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** General (unsafe-eval rationale)

The gating itself is real and tested:

```ts
// app/lib/security/csp.ts:45
const devEvalDirective = nodeEnv === "development" ? " 'unsafe-eval'" : "";
```

But whether Next's dev server actually eval-loads bundles and whether HMR breaks without the carve-out is runtime dev-server behavior that static analysis of this repo cannot confirm (paraphrased — no quote available because verifying it requires running the dev server under a strict CSP and observing console errors). The claim is consistent with Next's widely documented dev behavior; it is not contradicted by anything in the tree.

**Evidence:** `app/lib/security/csp.ts:25-30,45`

---

## Claim 10: "`nodeEnv` is a parameter rather than an ambient `process.env` read so the production branch can be observed from a test process without mutating global state. The comparison is against the *permissive* value, so any unset, misspelled, or unexpected environment yields the stricter policy."

**Location:** `app/lib/security/csp.ts:36-39`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** R3 / Y6 (testability + fail-closed)

The signature and comparison match:

```ts
// app/lib/security/csp.ts:41-45
export function buildCsp(
  nonce: string,
  nodeEnv: string | undefined = process.env.NODE_ENV,
): string {
  const devEvalDirective = nodeEnv === "development" ? " 'unsafe-eval'" : "";
```

The comparison is `=== "development"` — equality against the permissive value, so every other value falls to the strict branch. The fail-closed sweep exercises exactly the claimed inputs:

```ts
// app/lib/security/csp.test.ts:56-58
for (const env of [undefined, "", "Development", "dev", "test", "prod"]) {
  expect(buildCsp(NONCE, env)).not.toContain("'unsafe-eval'");
}
```

The commit's claim that the `=== "development"` comparison is "unchanged, only relocated" also holds: the pre-fix `proxy.ts` at e5d95a9 contains the same comparison (paraphrased — no quote available because the historical file was inspected via `git show e5d95a9:proxy.ts`, which shows the identical ternary inside the old inline `buildCsp`).

**Evidence:** `app/lib/security/csp.ts:33-45`, `app/lib/security/csp.test.ts:53-59`

---

## Claim 11: "Graph image export utilities. Separated for code-splitting since html-to-image is only needed when exporting the React Flow graph."

**Location:** `app/lib/utils/exportGraph.ts:1-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** General (comment sweep)

Both consumers load the module dynamically at export time:

```tsx
// app/components/panels/GraphPanel.tsx:102
const { getGraphViewportElement, downloadGraphAsPng } = await import("@/app/lib/utils/exportGraph");
```

The zip path (`app/lib/utils/exportAll.ts:10` imports exportGraph statically) is itself dynamically imported:

```tsx
// app/page.tsx:576
const { exportAllAsZip } = await import("@/app/lib/utils/exportAll");
```

So html-to-image stays out of the initial bundle on both paths.

**Evidence:** `app/lib/utils/exportGraph.ts:1-6`, `app/components/panels/GraphPanel.tsx:102-104`, `app/lib/utils/exportAll.ts:10,64`, `app/page.tsx:576-577`

---

## Claim 12: "html-to-image's `toBlob` goes canvas → `canvas.toBlob()`, staying entirely within the DOM. The `toPng` + `fetch(dataUrl)` route it replaces looked equivalent but is not: `fetch()` of a `data:` URL is governed by `connect-src`, which the app's CSP scopes to `'self'`, so that route throws a TypeError at runtime."

**Location:** `app/lib/utils/exportGraph.ts:17-22`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** R2 (toBlob substitution)

The core mechanism is exactly as claimed. In the installed package (html-to-image 1.11.13):

```js
// node_modules/html-to-image/lib/index.js:157-173 (toBlob)
case 0: return [4 /*yield*/, toCanvas(node, options)];
case 1:
    canvas = _a.sent();
    return [4 /*yield*/, (0, util_1.canvasToBlob)(canvas)];
```

and `canvasToBlob` is pure canvas API — `canvas.toBlob()` with an in-process `window.atob` fallback, no fetch:

```js
// node_modules/html-to-image/lib/util.js:179-185
function canvasToBlob(canvas, options) {
    ...
    if (canvas.toBlob) {
        return new Promise(function (resolve) {
            canvas.toBlob(resolve, ...
```

The replaced route is also correctly characterized: `toPng` returns `canvas.toDataURL()` (`node_modules/html-to-image/lib/index.js:127-139`), and the app's `connect-src` is `'self'` (`app/lib/security/csp.ts:52`), which blocks `fetch()` of `data:` URLs per the CSP/Fetch specs (paraphrased — no quote available because that governing rule is specification behavior, not repo code).

The one over-broad phrase is "staying entirely within the DOM": the shared `toCanvas` stage can issue `fetch()` calls when embedding external resources — `node_modules/html-to-image/lib/embed-webfonts.js:54` contains `return [4 /*yield*/, fetch(url)];` and `lib/dataurl.js:56` likewise. Those fetches target the resource's own URL (here, same-origin `next/font` assets, allowed by `connect-src 'self'`) and were equally present in the old `toPng` path, so the comparison the comment draws is sound — but the decode step, not the whole `toBlob` call, is what stays entirely in-DOM.

**Evidence:** `app/lib/utils/exportGraph.ts:16-33`, `node_modules/html-to-image/lib/index.js:127-174`, `node_modules/html-to-image/lib/util.js:179-200`, `node_modules/html-to-image/lib/embed-webfonts.js:54`, `app/lib/security/csp.ts:52`

---

## Claim 13: "`NextResponse.next({ request: { headers } })` cannot expose the mutated request directly — it encodes the forwarded headers onto the response as `x-middleware-request-<name>`, which Next unpacks before rendering."

**Location:** `proxy.test.ts:8-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** R3 (test observability mechanism)

The installed Next encodes exactly this way:

```js
// node_modules/next/dist/server/web/spec-extension/response.js:36
headers.set('x-middleware-request-' + key, value);
```

```js
// node_modules/next/dist/server/web/spec-extension/response.js:39
headers.set('x-middleware-override-headers', keys.join(','));
```

The second line also backs the test's `x-middleware-override-headers` assertion at `proxy.test.ts:40-42`. That Next's server unpacks these before rendering is inferred from the encoding's purpose (paraphrased — no quote available because the unpacking side lives in Next's router server code across multiple files and was not traced line-by-line).

**Evidence:** `proxy.test.ts:8-19,40-42`, `node_modules/next/dist/server/web/spec-extension/response.js:30-40`

---

## Claim 14: "Deleting the `requestHeaders.set("Content-Security-Policy", csp)` line in proxy.ts must fail this test." (and commit: "Falsification verified: deleting the requestHeaders.set line in proxy.ts fails 2 of its 5 tests.")

**Location:** `proxy.test.ts:30-31` (and commit f25d968, R3 section)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** R3 (falsification)

Verified by assertion analysis, without mutating the worktree. If `proxy.ts:26` were deleted, `NextResponse.next` would receive request headers without a CSP entry, so `x-middleware-request-content-security-policy` would be absent (per the encoding at `node_modules/next/dist/server/web/spec-extension/response.js:36`, quoted in Claim 13). Then:

- Test 1 fails: `expect(requestCsp).toBeTruthy();` (`proxy.test.ts:38`) — `requestCsp` would be `null`.
- Test 2 fails: the response header is still set independently at `proxy.ts:36` (`response.headers.set("Content-Security-Policy", csp)`), so

```ts
// proxy.test.ts:48-50
expect(response.headers.get("Content-Security-Policy")).toBe(
  forwardedRequestHeader(response, "content-security-policy"),
);
```

compares the policy string to `null` and fails.

- Tests 3, 4, 5 still pass: test 3 reads only the response header (`proxy.test.ts:54-57`); tests 4 and 5 read the forwarded `x-nonce`, which is set by the untouched `proxy.ts:31`, and the response CSP (paraphrased — no quote available because the pass/fail outcome is inferred by tracing each assertion against the hypothetically mutated code, not from an executed run).

That is exactly 2 of 5, matching the commit's count.

**Evidence:** `proxy.test.ts:26-86`, `proxy.ts:25-36`, `node_modules/next/dist/server/web/spec-extension/response.js:36`

---

## Claim 15: "Next 16's Proxy always runs on the Node.js runtime (it cannot be moved to Edge), so `crypto.randomUUID` and `Buffer` are both available as Node core APIs." (also file header: "CSP proxy (Next.js 16 renamed Middleware → Proxy)")

**Location:** `proxy.ts:6,12-14`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** R4 (runtime comment)

The installed Next (`"next": "16.2.4"` in `package.json`) states this in its own error text:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

The `middleware-to-proxy` URL in the same string corroborates the rename claim. `crypto.randomUUID` and `Buffer` being Node core is standard-library fact (paraphrased — no quote available because the claim is about the Node.js standard library, not repo code). This resolves full-1's Edge-runtime Incorrect finding; no stale "Edge" text remains in the file (paraphrased — no quote available because the claim covers absence of code; grep for "Edge" in proxy.ts matches only the rename note on line 6's history — current file has no Edge-runtime assertion).

**Evidence:** `proxy.ts:5-15`, `node_modules/next/dist/build/analysis/get-page-static-info.js:572-576`, `package.json` (next entry)

---

## Claim 16: "x-nonce is the conventional seam for server components that render their own `<Script>` tags. Nothing reads it today (Next handles its own bootstrap scripts via the header above); `.set` rather than `.append` so a client-supplied value is clobbered rather than joined into a comma-list."

**Location:** `proxy.ts:27-30`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Y1 (x-nonce rationale restored)

"Nothing reads it today" holds: a repo-wide grep for `x-nonce` finds only `proxy.ts` (the writer), this comment, the layout comment explaining why it is *not* read (`app/layout.tsx:32`), and `proxy.test.ts` assertions (paraphrased — no quote available because the claim covers absence of code; no application code reads the header). The clobber semantics are exercised by a test:

```ts
// proxy.test.ts:77-84
const request = new NextRequest("http://localhost:3000/", {
  headers: { "x-nonce": "attacker-supplied" },
});
const response = proxy(request);

expect(forwardedRequestHeader(response, "x-nonce")).not.toContain(
  "attacker-supplied",
);
```

That `Headers.set` replaces while `append` joins is web-standard `Headers` behavior (paraphrased — no quote available because it is platform API semantics, not repo code).

**Evidence:** `proxy.ts:27-31`, `proxy.test.ts:66-85`, `app/layout.tsx:31-32`

---

## Claim 17: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)."

**Location:** `proxy.ts:41-43`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** General (matcher comment sweep)

The comment matches the config it annotates:

```ts
// proxy.ts:44-51
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

The negative-lookahead excludes `api`, `_next/static`, `_next/image`, and `favicon.ico`; the `missing` conditions exclude requests carrying either prefetch header — the three skip categories the comment names, in order.

**Evidence:** `proxy.ts:40-53`

---

## Claim 18: Commit f25d968 verification block — "26 test files / 232 tests pass (was 24 / 221)"; "Two new test files, 11 tests"; "tsc --noEmit clean; npm run lint clean (2 pre-existing exhaustive-deps warnings in app/page.tsx)"; "`npm run build` fails in this sandbox on next/font/google's network fetch"

**Location:** commit f25d968 (message body)
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** R3 / verification counts

Re-executed on the worktree at f25d968. `npx vitest run` reports:

```
 Test Files  26 passed (26)
      Tests  232 passed (232)
```

(quoted from the run's summary output). `rg --files -g '*.test.*'` counts exactly 26 test files including the two new ones (`app/lib/security/csp.test.ts`, `proxy.test.ts`), which contain 6 and 5 `it(...)` blocks respectively — 11 tests, so the "was 24 / 221" arithmetic is internally consistent (26−2, 232−11) (paraphrased — no quote available because the prior-state counts are derived arithmetically rather than by checking out e5d95a9, which the historical rule discourages only for non-ancestors — the derivation was preferred as sufficient). `npx tsc --noEmit` exited 0. `npm run lint` reports:

```
✖ 2 problems (0 errors, 2 warnings)
```

both `react-hooks/exhaustive-deps` warnings in `app/page.tsx` (lines 209:6 and 271:6), matching "2 pre-existing exhaustive-deps warnings in app/page.tsx". The `@vitest-environment node` pragma claim is confirmed at `proxy.test.ts:1`:

```ts
// proxy.test.ts:1
// @vitest-environment node
```

The one sub-claim not re-executed is the `npm run build` failure on `next/font/google`'s network fetch — plausible (the layout imports `next/font/google` at `app/layout.tsx:2` and this sandbox blocks outbound network), but the build was not run for this check, so that fragment alone is unverified; it is an environment observation, not a code claim. It does not affect the verdict on the counts, which were all reproduced.

**Evidence:** vitest/tsc/lint runs on the worktree at f25d968; `proxy.test.ts:1`, `app/lib/security/csp.test.ts:16-73`, `app/page.tsx:209,271`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 6** (`app/lib/security/csp.ts:20`): "OpenAlex" names an integration that does not exist anywhere in this tree (it lives on the non-ancestor `integration/6.1` branch). Drop it from the enumeration, or reword to cover only the calls this branch actually makes (Anthropic, OpenRouter). The connect-src conclusion itself is correct.
- **Claim 12** (`app/lib/utils/exportGraph.ts:17-18`): "staying entirely within the DOM" is true of the canvas→blob decode step but not of the whole `toBlob` call — `toCanvas` can `fetch()` same-origin resources (webfont embedding). Tighten to "decodes the canvas entirely in-DOM" if precision matters; the CSP argument is unaffected.

### Unverifiable
- **Claim 9** (`app/lib/security/csp.ts:25-27`): Next dev-server eval/HMR behavior under a strict CSP requires a running dev server to confirm; consistent with documented Next behavior, contradicted by nothing.
- **Claim 18, one fragment** (commit f25d968): the `npm run build` next/font network-fetch failure was not re-executed; all reproducible counts (26/232, tsc, lint) were re-run and match.

## Goal-Alignment Note
- Answered: All six brief items. (1) Request-header CSP wiring verified against Next's own `parseRequestHeaders`/`getScriptNonceFromHeader` source. (2) toBlob path verified in the installed html-to-image 1.11.13 source; both call sites route through `renderGraphToBlob`; null failure throws instead of downloading an empty file. (3) `nodeEnv` parameter, `=== "development"` fail-closed comparison, and docstring accuracy checked, with client network calls re-enumerated on this state (all same-origin; connect-src 'self' sufficient). (4) Falsification claim confirmed by assertion tracing: exactly tests 1 and 2 of proxy.test.ts fail if `proxy.ts:26` is deleted — 2 of 5, as the commit states. (5) 26 files / 232 tests reproduced by running the suite; 11 new tests (6+5); tsc and lint claims reproduced. (6) Comment sweep of all changed files: layout comment now correct, x-nonce rationale accurate, matcher comment accurate, runtime comment corrected — zero Incorrect and zero Stale findings, which supports loop termination; the two Mostly-accurate items (OpenAlex mention, "entirely within the DOM" phrasing) are wording tightenings, not behavior mismatches.
- Out of scope: Runtime browser verification of the CSP (prod build + devtools check) — the commit itself flags this as unavailable in the sandbox; dev-server HMR behavior under CSP (Claim 9).
- Escalate: Nothing blocking. If the loop-termination bar is "no Incorrect/Stale," this pass meets it; the OpenAlex docstring mention (Claim 6) is the only residual worth a one-word edit in a future amber pass, and note it will become *accurate* if/when the `integration/6.1` evidence-search work merges into this line.
