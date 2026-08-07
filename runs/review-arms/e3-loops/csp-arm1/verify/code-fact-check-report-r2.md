# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (branch e3/csp-arm1)
**Commit:** 1eb081e
**Scope:** `git diff d86d2dc..HEAD` — app/layout.tsx, app/lib/security/csp.ts, app/lib/security/csp.test.ts, app/lib/utils/exportGraph.ts, app/lib/utils/exportGraph.test.ts, proxy.ts, proxy.test.ts
**Checked:** 2026-08-06
**Total claims checked:** 18
**Summary:** 17 verified, 0 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Round-2 pass after the amber-disposition commit 1eb081e. Verifies the 8 amber-disposition claims from the brief and sweeps the edited files for newly-introduced stale comments (comments describing the deleted `x-nonce` write, the deleted `missing:` prefetch clause, or the replaced `toPng` path). All three new/changed test files pass (`npx vitest run`: 15/15) and `npx tsc --noEmit` exits 0. `docs/reviews/hallucination-patterns.md` does not exist in the worktree; no fabrications were found, so it was not created.

---

## Claim 1: "Next tags its own bootstrap `<script>` elements with the nonce it parses out of the *request* Content-Security-Policy header, which proxy.ts sets on the forwarded request headers — not out of the response header. We therefore don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:26-32`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High

Next's app renderer reads the nonce from the incoming *request* headers, not the response:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

proxy.ts does set that header on the forwarded request:

```ts
// proxy.ts:31-32
const requestHeaders = new Headers(request.headers);
requestHeaders.set("Content-Security-Policy", csp);
```

The "don't need to read x-nonce" part holds: `rg -in "x-nonce"` over the repo (excluding node_modules) matches only this comment, the explanatory comment in `proxy.ts:33`, and the negative test `proxy.test.ts:79-82` (paraphrased — no quote available because the claim covers absence of code; the grep has no reader hits).

**Evidence:** `node_modules/next/dist/server/app-render/app-render.js:166-167`, `proxy.ts:31-32`, `proxy.test.ts:79-83`

---

## Claim 2: "a statically prerendered document is built once, so its `<script>` tags would carry a stale nonce ... The cost is one SSR shell render per navigation ... small here because the app is a single \"use client\" route with no generateStaticParams, revalidate, or ISR. (Unmeasured: ...)"

**Location:** `app/layout.tsx:33-45`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The route-count assertion is checkable and true: `rg --files app -g 'page.tsx'` returns only `app/page.tsx`, and that file opens with:

```tsx
// app/page.tsx:1
"use client";
```

`generateStaticParams`, `revalidate`, and ISR config are absent — the only grep hits for those tokens in `app/` are this comment itself, `app/layout.tsx:41-42` (paraphrased — no quote available because the claim covers absence of code; grep returns no other matches). The `await headers()` call at `app/layout.tsx:46` is a Next dynamic API that opts the tree out of static prerendering (paraphrased — no quote available because the behavior is implemented across Next's framework internals, not app code). The comment explicitly labels the size of the cost as unmeasured, which is honest rather than a checkable numeric claim.

**Evidence:** `app/layout.tsx:23-46`, `app/page.tsx:1`

---

## Claim 3: "The comparison is against the permissive value, so unset, misspelled, and unexpected environments must all get the stricter policy." (fail-closed test comment)

**Location:** `app/lib/security/csp.test.ts:52-53`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High

The implementation compares against `"development"` (the permissive value) and defaults to the empty (strict) directive:

```ts
// app/lib/security/csp.ts:47
const devEvalDirective = nodeEnv === "development" ? " 'unsafe-eval'" : "";
```

The test exercises `undefined`, `""`, `"Development"`, `"dev"`, `"test"`, `"prod"` and all get the strict policy; the suite passes (15/15 in the vitest run for this pass).

**Evidence:** `app/lib/security/csp.ts:46-47`, `app/lib/security/csp.test.ts:51-58`

---

## Claim 4: "Regression guard: graph PNG/zip export must decode canvases in-DOM (`exportGraph.ts` uses `toBlob`) rather than `fetch()`-ing a data URL"

**Location:** `app/lib/security/csp.test.ts:66-69`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High

`exportGraph.ts` imports and uses only `toBlob`:

```ts
// app/lib/utils/exportGraph.ts:6
import { toBlob } from "html-to-image";
```

and no `toPng` or `fetch(dataUrl)` remains anywhere in `app/lib/utils/exportGraph.ts` (paraphrased — no quote available because the claim covers absence of code; grep for `toPng|fetch(` in that file hits only comments).

**Evidence:** `app/lib/security/csp.test.ts:66-72`, `app/lib/utils/exportGraph.ts:6,29-38`

---

## Claim 5: "Extracted from `proxy.ts` so the policy ... can be imported and asserted on directly (see `csp.test.ts`). The proxy entry point stays a thin wiring layer."

**Location:** `app/lib/security/csp.ts:4-7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

`proxy.ts` imports the policy rather than defining it:

```ts
// proxy.ts:3
import { buildCsp } from "@/app/lib/security/csp";
```

`csp.test.ts` exists and imports `buildCsp` directly (`app/lib/security/csp.test.ts:2`). `proxy.ts` contains no directive strings — only nonce generation, header wiring, and the matcher config (paraphrased — no quote available because the claim is about what the 64-line file does *not* contain).

**Evidence:** `proxy.ts:3,11-42`, `app/lib/security/csp.test.ts:2`

---

## Claim 6: "Why `style-src 'unsafe-inline'`: the dependents are React `style={{...}}` attributes ..., reactflow's per-node transform styles, KaTeX's inline-styled output, `next/font`'s injected declarations ... — not Tailwind, which compiles to an external stylesheet here."

**Location:** `app/lib/security/csp.ts:13-19`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

The named dependencies are all present:

```json
// package.json:21,29 (excerpt)
"katex": "^0.16.45",
"reactflow": "^11.11.4",
```

`next/font` is used in `app/layout.tsx:2` (`import { EB_Garamond, Geist_Mono } from "next/font/google"`). Tailwind v4 is wired through `app/globals.css:1` (`@import "tailwindcss";`), which the build compiles into the app's external stylesheet rather than inline `<style>` attributes (paraphrased — no quote available because the compile-to-stylesheet behavior lives in the Tailwind/PostCSS toolchain, not app code). Confidence is Medium only because the full set of inline-style producers is a runtime property; every named dependent was confirmed present.

**Evidence:** `package.json:16,21,29,36,49`, `app/globals.css:1-2`, `app/layout.tsx:2,7-14`

---

## Claim 7: "`connect-src 'self'` is sufficient because no browser-side code calls a third-party origin: every outbound call is made server-side from `app/api/**`."

**Location:** `app/lib/security/csp.ts:21-24`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High

Re-enumerated on this tree state. Every client-side network call found (`fetch(`/`XMLHttpRequest`/`WebSocket`/`EventSource`/`sendBeacon` grep over `app/`, excluding `app/api/` and tests) targets a relative same-origin path: `app/hooks/useAnalytics.ts:11,30` (`/api/analytics`), `app/hooks/useDecomposition.ts:129-130` (`/api/decomposition/extract`), `app/hooks/useArtifactEditing.ts:39,48`, `app/lib/formalization/api.ts:104,121,137,146,159`, `app/components/panels/SemiformalPanel.tsx:43,59`, `app/components/panels/OutputPanel.tsx:50,66`, `app/components/features/lean-display/LeanCodeDisplay.tsx:88`, `app/components/features/context-input/ContextInput.tsx:25`, `app/components/features/output-editing/EditableSection.tsx:77,84` (paraphrased — no quote available because the invariant is inferred from many call sites; every one was read and is a literal `"/api/..."` string or `ARTIFACT_ROUTE[type]`, whose values in `app/lib/types/artifacts.ts` are all `"/api/formalization/..."` literals).

The one third-party URL in client-importable code is:

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

but the modules that call it (`callLlm.ts:164`, `streamLlm.ts:249`) are imported as values only by `app/api/**/route.ts` files and by `app/lib/formalization/artifactRoute.ts`, which itself is imported only by `app/api/formalization/*/route.ts` — all server-side. `app/lib/formalization/api.ts:3` imports only a *type* from `callLlm` (`import type { LlmCallUsage }`), which erases at compile time.

**Evidence:** `app/lib/llm/callLlm.ts:7,164`, `app/lib/llm/streamLlm.ts:249`, `app/lib/formalization/api.ts:3,10,38`, `app/lib/types/artifacts.ts` (ARTIFACT_ROUTE map), `app/hooks/useAnalytics.ts:11,30`

---

## Claim 8: "Note that it also governs `fetch()` of `data:` URLs — see `exportGraph.ts`, which decodes canvases with `toBlob` rather than re-fetching a data URL."

**Location:** `app/lib/security/csp.ts:24-25`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The reference is live: `exportGraph.ts` uses `toBlob` (see Claim 4 evidence). That `connect-src` governs `fetch()` of `data:` URLs, and that `'self'` does not match the `data:` scheme, is CSP3 spec behavior (paraphrased — no quote available because the claim is about browser/spec behavior, not repo code).

**Evidence:** `app/lib/security/csp.ts:24-25`, `app/lib/utils/exportGraph.ts:6,29-38`

---

## Claim 9: "Production builds do not depend on eval (pdfjs-dist probes for it with `new Function(\"\")`, but that probe is caught and pdfjs falls back — it only logs a CSP violation)"

**Location:** `app/lib/security/csp.ts:28-33`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium

The probe exists exactly as described and is wrapped in try/catch:

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

`FeatureTest.isEvalSupported` caches the result (`pdf.mjs:518-520`), so under a no-`unsafe-eval` CSP the probe throws, is caught, and pdfjs takes the non-eval path. The "only logs a CSP violation" tail refers to the browser's console report for the blocked eval attempt, which is emitted even when the exception is caught (paraphrased — no quote available because that is browser behavior, not repo code). Confidence Medium because the downstream non-eval fallback paths inside pdfjs were not individually traced.

**Evidence:** `node_modules/pdfjs-dist/build/pdf.mjs:506-520`, `package.json:25`

---

## Claim 10: "`nodeEnv` is a required parameter rather than an ambient `process.env` read ... It is deliberately not defaulted: a default would make the shipping branch the one branch no test exercises."

**Location:** `app/lib/security/csp.ts:38-45`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The signature has no default and no `process.env` read:

```ts
// app/lib/security/csp.ts:46
export function buildCsp(nonce: string, nodeEnv: string | undefined): string {
```

Every call site passes the argument explicitly — the sole production call site is:

```ts
// proxy.ts:19
const csp = buildCsp(nonce, process.env.NODE_ENV);
```

and all other callers are in `csp.test.ts` with literal values (paraphrased — no quote available because the "no call site relies on a default" part is an exhaustive-grep result: `rg -n buildCsp` returns only `csp.ts`, `csp.test.ts`, and `proxy.ts:3,19`). `process.env` does not appear in `csp.ts` at all. `npx tsc --noEmit` exits 0, confirming no call site was left passing one argument.

**Evidence:** `app/lib/security/csp.ts:46-47`, `proxy.ts:19`, `app/lib/security/csp.test.ts:18-71`

---

## Claim 11: "`csp.test.ts` fires if someone widens `connect-src` to allow `data:`; these tests fire if someone narrows the export path back to `toPng` + `fetch(dataUrl)` ..."

**Location:** `app/lib/utils/exportGraph.test.ts:4-12`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High

Both guards exist. The CSP side:

```ts
// app/lib/security/csp.test.ts:71
expect(parse(buildCsp(NONCE, "production"))["connect-src"]).toBe("'self'");
```

The export side:

```ts
// app/lib/utils/exportGraph.test.ts:41-45
expect(toBlob).toHaveBeenCalledWith(element, expect.anything());
expect(toPng).not.toHaveBeenCalled();
// `fetch()` of a data: URL is governed by `connect-src 'self'` and throws.
expect(globalThis.fetch).not.toHaveBeenCalled();
```

Both files ran and passed in this verification pass.

**Evidence:** `app/lib/security/csp.test.ts:66-72`, `app/lib/utils/exportGraph.test.ts:39-46`

---

## Claim 12: "html-to-image's `toBlob` goes canvas → `canvas.toBlob()` where available, so the final decode stays in-DOM. (The shared `toCanvas` pipeline may still `fetch()` same-origin webfonts and images to inline them ...) The legacy `toDataURL` fallback inside the library reconstructs the base64 round-trip this replaced, so the fast path is a runtime choice, not a guarantee of the import."

**Location:** `app/lib/utils/exportGraph.ts:16-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

All three sub-claims match the installed library (html-to-image 1.11.x). `toBlob` routes through `canvasToBlob`:

```js
// node_modules/html-to-image/lib/index.js:163-166
case 0: return [4 /*yield*/, toCanvas(node, options)];
...
return [4 /*yield*/, (0, util_1.canvasToBlob)(canvas)];
```

`canvasToBlob` prefers the in-DOM API and only falls back to a base64 round-trip:

```js
// node_modules/html-to-image/lib/util.js:181-188 (excerpt)
if (canvas.toBlob) {
    return new Promise(function (resolve) {
        canvas.toBlob(resolve, ...);
    });
}
return new Promise(function (resolve) {
    var binaryString = window.atob(canvas.toDataURL(...).split(',')[1]);
```

Note the fallback decodes via `window.atob`, not `fetch()`, so even the slow path does not hit `connect-src` — consistent with the comment, which frames the fallback as a performance round-trip rather than a CSP hazard. The webfont/image inlining claim is real: `node_modules/html-to-image/lib/embed-webfonts.js:54` and `lib/dataurl.js:56` call `fetch(url)` during `toCanvas` (paraphrased quote locations — the calls are single-line `fetch` statements inside the library's async generator scaffolding).

**Evidence:** `node_modules/html-to-image/lib/index.js:157-174`, `node_modules/html-to-image/lib/util.js:179-200`, `node_modules/html-to-image/lib/embed-webfonts.js:44-56`, `node_modules/html-to-image/lib/dataurl.js:51-56`

---

## Claim 13: "`NextResponse.next({ request: { headers } })` cannot expose the mutated request directly — it encodes the forwarded headers onto the response as `x-middleware-request-<name>`, which Next unpacks before rendering."

**Location:** `proxy.test.ts:8-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Confirmed empirically: the test suite reads headers through exactly this encoding and passes —

```ts
// proxy.test.ts:19
return response.headers.get(`x-middleware-request-${name}`);
```

with `proxy.test.ts` green (6/6) against the installed next@16.2.4 (`package.json:23`). The unpack-before-render half is Next-internal plumbing (paraphrased — no quote available because it spans Next's middleware response handling across multiple dist files); the passing `x-middleware-override-headers` assertion at `proxy.test.ts:38-40` corroborates the mechanism.

**Evidence:** `proxy.test.ts:15-20,26-41`, `package.json:23`

---

## Claim 14: "Load-bearing: Next parses the script nonce out of the request Content-Security-Policy header. ... Deleting the `requestHeaders.set(\"Content-Security-Policy\", csp)` line in proxy.ts must fail this test."

**Location:** `proxy.test.ts:26-30`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The nonce-parsing claim is confirmed by Next's source (quoted in Claim 1). The counterfactual holds: the test asserts on `x-middleware-request-content-security-policy` (`proxy.test.ts:32-37`), which only exists because of the `requestHeaders.set` call at `proxy.ts:32` — removing that call leaves the forwarded header unset and `expect(requestCsp).toBeTruthy()` fails (paraphrased — no quote available because the claim is a counterfactual about deleted code; the causal chain is the two quoted lines).

**Evidence:** `proxy.test.ts:31-41`, `proxy.ts:31-32`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 15: "The seam had no readers, and a header asserted in CI reads as live plumbing. Reinstate both together, never the header alone." (x-nonce negative test)

**Location:** `proxy.test.ts:80-81` (and the matching comment `proxy.ts:33-36`)
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High

The "no readers" premise is true on this tree: case-insensitive grep for `x-nonce` outside node_modules hits only the two explanatory comments and the negative test itself (paraphrased — no quote available because the claim covers absence of code; zero reader hits). The deletion is complete — no `requestHeaders.set("x-nonce", ...)` remains in `proxy.ts`, and the replacement negative test passes:

```ts
// proxy.test.ts:82
expect(forwardedRequestHeader(run(), "x-nonce")).toBeNull();
```

Neither comment describes the deleted write as still existing; both are phrased as "no x-nonce header," so no stale residue was introduced.

**Evidence:** `proxy.test.ts:79-83`, `proxy.ts:33-36`, `app/layout.tsx:31-32`

---

## Claim 16: "CSP coverage must not be a function of a client-supplied request header: no matcher entry may carry a `missing:`/`has:` header condition." (and proxy.ts's "Deliberately no `missing:` prefetch exclusion" comment)

**Location:** `proxy.test.ts:86-88`; `proxy.ts:49-54`
**Type:** Invariant / Configuration
**Verdict:** Verified
**Confidence:** High

The config matches: the single matcher entry carries only `source`:

```ts
// proxy.ts:57-61
matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
    },
],
```

No `missing:` or `has:` key exists anywhere in `proxy.ts` (paraphrased — no quote available because the claim covers absence of code; grep confirms), and the invariant test iterating `config.matcher` passes. The surrounding comment "Skip API routes ... and Next's static assets" matches the actual negative-lookahead exclusions (`api`, `_next/static`, `_next/image`, `favicon.ico`) with no leftover mention of a prefetch exclusion — the comment now describes the exclusions that exist.

**Evidence:** `proxy.ts:44-63`, `proxy.test.ts:85-94`

---

## Claim 17: "Typed against Next's own `ProxyConfig` (matching `next.config.ts`'s `NextConfig` annotation) so a typo in a matcher key — `missng:` for `missing:`, `sources:` for `source:` — fails the type check" — and "(Next.js 16 renamed Middleware → Proxy)" / "Next 16's Proxy always runs on the Node.js runtime (it cannot be moved to Edge)"

**Location:** `proxy.ts:2,6,44-47,12-15`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High

`ProxyConfig` is a real next@16.2.4 export, and the rename claim is stated by Next itself:

```ts
// node_modules/next/dist/server/web/types.d.ts:10-13
* @deprecated Use `ProxyConfig` instead. Middleware has been renamed to Proxy.
...
export type { MiddlewareConfigInput as ProxyConfig } from '../../build/segment-config/middleware/middleware-config';
```

(also re-exported at `node_modules/next/server.d.ts:14`). The matcher entry type is an object literal union with keys `locale`/`has`/`missing`/`source` (`node_modules/next/dist/build/segment-config/middleware/middleware-config.d.ts:6-11`), so a misspelled key in the object literal is an excess-property type error; `npx tsc --noEmit` exits 0 on the current file. The Node-runtime claim is verbatim in Next's build analysis:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

which also confirms the follow-on claim at `proxy.ts:12-15` that `crypto.randomUUID` and `Buffer` (Node core) are safe to use there.

**Evidence:** `node_modules/next/dist/server/web/types.d.ts:10-13`, `node_modules/next/server.d.ts:14`, `node_modules/next/dist/build/segment-config/middleware/middleware-config.d.ts:1-21`, `node_modules/next/dist/build/analysis/get-page-static-info.js:576`, `proxy.ts:2,44-47`

---

## Claim 18: "Skipping on `purpose: prefetch` / `next-router-prefetch` saved ~0.75 µs of nonce generation and let any caller that sets those headers receive a rendered document with no CSP ..."

**Location:** `proxy.ts:52-55`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium

The security half of the sentence is verifiable and true: a matcher `missing:` clause on those headers would exclude matching requests from the proxy entirely, so responses would carry no CSP (paraphrased — no quote available because the claim describes the behavior of a deleted config clause; the matcher semantics are Next framework behavior). The "~0.75 µs of nonce generation" figure is a microbenchmark of `Buffer.from(crypto.randomUUID()).toString("base64")` (`proxy.ts:15`) that cannot be confirmed by static analysis — no benchmark exists in the repo. The tilde and the comment's own framing (cost that was "saved" by the deleted clause, cited to argue the saving was negligible) make it a rhetorical order-of-magnitude estimate rather than a load-bearing spec; verifying it would need a runtime microbenchmark.

**Evidence:** `proxy.ts:12-15,49-55`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None. Specifically swept for residue of the three deletions (x-nonce write, `missing:` prefetch clause, `toPng`+`fetch(dataUrl)` path): every remaining mention of them is phrased as deliberate absence or historical contrast, not as live code.

### Mostly Accurate
- None.

### Unverifiable
- **Claim 18** (`proxy.ts:52-55`): the "~0.75 µs" nonce-generation cost is a microbenchmark estimate; verifying it would require a runtime benchmark. The security half of the same sentence is verified.

## Goal-Alignment Note
- Answered: All 7 brief items. (1) `buildCsp` nodeEnv is required with no default; the only production call site passes `process.env.NODE_ENV` explicitly; fail-closed dev-eval preserved and tested (Claims 3, 10). (2) x-nonce deletion safe — zero readers on this tree; the load-bearing request-CSP-header property is tested and the counterfactual holds (Claims 1, 14, 15). (3) Matcher `missing:` gone; comment matches the four actual exclusions (Claim 16). (4) connect-src invariant re-enumerated on this state — all client network calls are relative `/api` paths; the sole third-party URL (OpenRouter) is reachable only from server-side modules (Claim 7). (5) Layout cost comment honest and route-count claim true; toBlob comment matches html-to-image source including the atob (non-fetch) fallback (Claims 2, 12). (6) `ProxyConfig` typing is a real next@16.2.4 export and tsc is clean (Claim 17). (7) Newly-introduced Incorrect/Stale sweep: none found — 0 Incorrect, 0 Stale across all 18 claims; tests 15/15 green.
- Out of scope: Runtime browser behavior (actual CSP enforcement, pdfjs fallback paths in a live browser, TTFB cost of the dynamic opt-out); the ~0.75 µs microbenchmark figure.
- Escalate: Nothing. No red-blocking findings for the 0R+0A standard from this fact-check.
