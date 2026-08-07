# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (branch `e3/csp-arm1`)
**Commit:** 1eb081e
**Scope:** `git diff d86d2dc..HEAD` — `app/layout.tsx`, `app/lib/security/csp.ts`, `app/lib/security/csp.test.ts`, `app/lib/utils/exportGraph.ts`, `app/lib/utils/exportGraph.test.ts`, `proxy.ts`, `proxy.test.ts`
**Checked:** 2026-08-06
**Total claims checked:** 20
**Summary:** 18 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Verification pass r3, after amber-disposition commit 1eb081e (8 amber fixes). All three new test
files pass: `Test Files 3 passed (3) / Tests 15 passed (15)` (vitest run in the worktree).
`npx tsc --noEmit` exits 0. `docs/reviews/hallucination-patterns.md` does not exist in the
worktree; no fabrications were found, so it was not created.

---

## Claim 1: "Next tags its own bootstrap `<script>` elements with the nonce it parses out of the *request* Content-Security-Policy header, which proxy.ts sets on the forwarded request headers — not out of the response header. We therefore don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:24-30`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High

Next's app renderer parses the nonce from the **request** headers, exactly as claimed:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167 (inside parseRequestHeaders)
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

proxy.ts sets that header on the forwarded request:

```ts
// proxy.ts:30-31
const requestHeaders = new Headers(request.headers);
requestHeaders.set("Content-Security-Policy", csp);
```

"We don't need to read x-nonce": a repo-wide grep for `x-nonce` finds only the layout comment, a
proxy.ts comment, and the `proxy.test.ts` assertion that the header is absent — no reader exists
(paraphrased — no quote available because the claim covers absence of code; grep for `x-nonce`
returns zero non-comment, non-test hits).

**Evidence:** `app/layout.tsx:24-30`, `proxy.ts:30-31`, `node_modules/next/dist/server/app-render/app-render.js:155-167`

---

## Claim 2: "Opt this layout out of static rendering … Per-request nonces and static rendering are mutually exclusive by construction. The cost is one SSR shell render per navigation … small here because the app is a single 'use client' route with no generateStaticParams, revalidate, or ISR. (Unmeasured: …)"

**Location:** `app/layout.tsx:23-44`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

`await headers()` is a Next dynamic API that bails out of static generation; Next's own error
string for the conflicting configuration confirms the mechanism:

```js
// node_modules/next/dist/server/request/headers.js:78
throw ... new _staticgenerationbailout.StaticGenBailoutError(`Route ${workStore.route} with \`dynamic = "error"\` couldn't be rendered statically because it used \`headers()\`. ...`)
```

"Single 'use client' route": `rg --files app -g 'page.tsx'` returns only `app/page.tsx`, and it
begins:

```tsx
// app/page.tsx:1
"use client";
```

"No generateStaticParams, revalidate, or ISR": a grep for `generateStaticParams|revalidate|dynamic =`
across `app/` hits only this comment itself (paraphrased — no quote available because the claim
covers absence of code; grep returns zero non-comment matches). The cost description honestly
flags its own unmeasured numbers ("Unmeasured: …"), so no quantitative claim is asserted.

**Evidence:** `app/layout.tsx:23-44`, `app/page.tsx:1`, `node_modules/next/dist/server/request/headers.js:77-115`

---

## Claim 3: "Regression guard: graph PNG/zip export must decode canvases in-DOM (`exportGraph.ts` uses `toBlob`) rather than `fetch()`-ing a data URL, which would be blocked here."

**Location:** `app/lib/security/csp.test.ts:67-70`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

`exportGraph.ts` does use `toBlob` and contains no `fetch`:

```ts
// app/lib/utils/exportGraph.ts:6
import { toBlob } from "html-to-image";
```

```ts
// app/lib/utils/exportGraph.ts:31-34
const blob = await toBlob(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
```

That `fetch()` of a `data:` URL would be blocked by `connect-src 'self'` is standard CSP3/Fetch
behavior — `data:` is not `'self'` (paraphrased — no quote available because this is
specification behavior, not repo code).

**Evidence:** `app/lib/security/csp.test.ts:66-72`, `app/lib/utils/exportGraph.ts:6,31-38`

---

## Claim 4: "Extracted from `proxy.ts` so the policy … can be imported and asserted on directly (see `csp.test.ts`). The proxy entry point stays a thin wiring layer."

**Location:** `app/lib/security/csp.ts:4-7`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High

`csp.test.ts` exists and imports the function directly:

```ts
// app/lib/security/csp.test.ts:2
import { buildCsp } from "./csp";
```

proxy.ts imports it rather than building the policy inline:

```ts
// proxy.ts:3
import { buildCsp } from "@/app/lib/security/csp";
```

proxy.ts contains no policy-string construction of its own — only nonce generation, header
wiring, and the matcher config (paraphrased — no quote available because the claim covers absence
of code in a 64-line file).

**Evidence:** `app/lib/security/csp.ts:4-7`, `app/lib/security/csp.test.ts:2`, `proxy.ts:1-64`

---

## Claim 5: "Why `style-src 'unsafe-inline'`: the dependents are React `style={{...}}` attributes …, reactflow's per-node transform styles, KaTeX's inline-styled output, `next/font`'s injected declarations, and dev-time HMR style injection — not Tailwind, which compiles to an external stylesheet here."

**Location:** `app/lib/security/csp.ts:13-19`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

All named dependents are present in the project:

```json
// package.json:21,29-30 (dependencies)
"katex": "^0.16.45",
"reactflow": "^11.11.4",
"rehype-katex": "^7.0.1",
```

```tsx
// app/layout.tsx:2
import { EB_Garamond, Geist_Mono } from "next/font/google";
```

Tailwind v4 is present as a PostCSS build-time plugin (`"@tailwindcss/postcss": "^4"` and
`"tailwindcss": "^4"` at `package.json:36,49`), which emits compiled CSS into the app stylesheet
rather than inline `style` attributes (paraphrased — no quote available because the compilation
model is library behavior, not repo code). Confidence Medium because the completeness of the
dependent list (e.g., that removing the carve-out would break exactly these consumers) is a
runtime property not fully checkable statically; the named packages and imports all exist.

**Evidence:** `app/lib/security/csp.ts:13-19`, `package.json:16-49`, `app/layout.tsx:2`

---

## Claim 6: "`connect-src 'self'` is sufficient because no browser-side code calls a third-party origin: every outbound call is made server-side from `app/api/**`."

**Location:** `app/lib/security/csp.ts:21-24`
**Type:** Architectural / Invariant
**Verdict:** Mostly accurate
**Confidence:** High

The load-bearing half is true on this tree state. Re-enumerating client network calls: every
`fetch(` in client-reachable code targets a relative `/api/...` path, e.g.:

```ts
// app/components/features/context-input/ContextInput.tsx:25
const response = await fetch("/api/refine/context", {
```

```ts
// app/lib/formalization/api.ts:104
const res = await fetch("/api/verification/lean", {
```

Dynamic URLs resolve to relative API paths too — `ARTIFACT_ROUTE` values are all `/api/formalization/*`:

```ts
// app/lib/types/artifacts.ts:192-198
export const ARTIFACT_ROUTE: Partial<Record<ArtifactType, string>> = {
  "causal-graph": "/api/formalization/causal-graph",
  ...
```

No `EventSource`, `WebSocket`, `XMLHttpRequest`, `sendBeacon`, or `axios` usage exists in `app/`
(paraphrased — no quote available because the claim covers absence of code; grep returns zero
hits). The only third-party origin in the codebase is OpenRouter:

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

and `callLlm`/`streamLlm` are imported exclusively by route handlers under `app/api/**` and by
`app/lib/formalization/artifactRoute.ts`, which is itself imported only by five `app/api/formalization/*/route.ts`
files (paraphrased — no quote available because the invariant is inferred from the full importer
list across 11 call sites). The imprecision: the outbound `fetch` statements physically live in
`app/lib/llm/*.ts` and `app/lib/formalization/artifactRoute.ts`, not in `app/api/**` — they
*execute* inside `app/api/**` handlers. "Made server-side from `app/api/**`" is correct about
execution context but loose about code location. The security conclusion (nothing browser-side
needs a wider `connect-src`) holds.

**Evidence:** `app/lib/security/csp.ts:21-24`, `app/lib/llm/callLlm.ts:7,164`, `app/lib/llm/streamLlm.ts:249`, `app/lib/formalization/api.ts:10,38,104-159`, `app/lib/types/artifacts.ts:192-198`, `app/hooks/useArtifactGeneration.ts:42-61`, `app/hooks/useDecomposition.ts:129-130`

---

## Claim 7: "Note that it also governs `fetch()` of `data:` URLs — see `exportGraph.ts`, which decodes canvases with `toBlob` rather than re-fetching a data URL."

**Location:** `app/lib/security/csp.ts:25-26`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The reference is accurate — `exportGraph.ts` imports and uses `toBlob` and contains no `fetch`:

```ts
// app/lib/utils/exportGraph.ts:6
import { toBlob } from "html-to-image";
```

That `connect-src` governs `fetch()` of `data:` URLs is CSP3/Fetch specification behavior
(paraphrased — no quote available because it is spec behavior, not repo code; the claim is
consistent with the `TypeError`-at-runtime description in `exportGraph.ts:23-26`).

**Evidence:** `app/lib/security/csp.ts:25-26`, `app/lib/utils/exportGraph.ts:6,28-38`

---

## Claim 8: "Production builds do not depend on eval (pdfjs-dist probes for it with `new Function(\"\")`, but that probe is caught and pdfjs falls back — it only logs a CSP violation), so the carve-out is gated on the environment and never ships in a production build."

**Location:** `app/lib/security/csp.ts:28-33`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium

The pdfjs probe exists exactly as described and is wrapped in try/catch, returning `false` (the
fallback path) when eval is blocked:

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

Consumers check the flag rather than assuming eval: `const isEvalSupported = src.isEvalSupported !== false;`
(`node_modules/pdfjs-dist/build/pdf.mjs:14689`). The gating itself is verified in code:

```ts
// app/lib/security/csp.ts:47
const devEvalDirective = nodeEnv === "development" ? " 'unsafe-eval'" : "";
```

with `nodeEnv` supplied from `process.env.NODE_ENV` at the single production call site
(`proxy.ts:19`). Confidence Medium only for the "only logs a CSP violation" clause: that the
browser emits a console violation report for the caught probe is runtime browser behavior not
checkable statically; the caught-probe-plus-fallback mechanism is confirmed in pdfjs source.

**Evidence:** `app/lib/security/csp.ts:28-33,47`, `node_modules/pdfjs-dist/build/pdf.mjs:506-519,14689`, `proxy.ts:19`

---

## Claim 9: "`nodeEnv` is a required parameter rather than an ambient `process.env` read … It is deliberately not defaulted: a default would make the shipping branch the one branch no test exercises. The comparison is against the *permissive* value, so any unset, misspelled, or unexpected environment yields the stricter policy — hence the wide `string | undefined` type."

**Location:** `app/lib/security/csp.ts:38-44`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High

The signature has no default and the wide type:

```ts
// app/lib/security/csp.ts:46-47
export function buildCsp(nonce: string, nodeEnv: string | undefined): string {
  const devEvalDirective = nodeEnv === "development" ? " 'unsafe-eval'" : "";
```

The comparison is against `"development"` (the permissive value), so `undefined`, `""`,
`"Development"`, `"prod"`, etc. all take the strict branch — asserted directly by the fail-closed
test:

```ts
// app/lib/security/csp.test.ts:56-58
for (const env of [undefined, "", "Development", "dev", "test", "prod"]) {
  expect(buildCsp(NONCE, env)).not.toContain("'unsafe-eval'");
}
```

No call site relies on a default: the only non-test caller passes the environment explicitly —
`const csp = buildCsp(nonce, process.env.NODE_ENV);` (`proxy.ts:19`); a repo-wide grep finds no
other `buildCsp(` call sites outside `csp.test.ts` (paraphrased — no quote available because the
claim covers absence of other callers; grep returns only proxy.ts and the test file). All 15
tests pass and `tsc --noEmit` exits 0, confirming the required-parameter change broke no caller.

**Evidence:** `app/lib/security/csp.ts:38-47`, `app/lib/security/csp.test.ts:54-59`, `proxy.ts:17-19`

---

## Claim 10: "`csp.test.ts` fires if someone widens `connect-src` to allow `data:`; these tests fire if someone narrows the export path back to `toPng` + `fetch(dataUrl)` …"

**Location:** `app/lib/utils/exportGraph.test.ts:4-11`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High

Both halves of the two-sided invariant exist. The CSP side:

```ts
// app/lib/security/csp.test.ts:71
expect(parse(buildCsp(NONCE, "production"))["connect-src"]).toBe("'self'");
```

The export-path side:

```ts
// app/lib/utils/exportGraph.test.ts:41-43
expect(toBlob).toHaveBeenCalledWith(element, expect.anything());
expect(toPng).not.toHaveBeenCalled();
// `fetch()` of a data: URL is governed by `connect-src 'self'` and throws.
expect(globalThis.fetch).not.toHaveBeenCalled();
```

Reintroducing `toPng` + `fetch(dataUrl)` in either export function would fail
`toPng).not.toHaveBeenCalled()` / `fetch).not.toHaveBeenCalled()`; widening `connect-src` to
`'self' data:` would fail the exact-match `toBe("'self'")`. Both suites pass on this tree.

**Evidence:** `app/lib/utils/exportGraph.test.ts:4-11,38-53`, `app/lib/security/csp.test.ts:66-72`

---

## Claim 11: "html-to-image's `toBlob` goes canvas → `canvas.toBlob()` where available, so the final decode stays in-DOM. (The shared `toCanvas` pipeline may still `fetch()` same-origin webfonts and images to inline them …) The legacy `toDataURL` fallback inside the library reconstructs the base64 round-trip this replaced, so the fast path is a runtime choice, not a guarantee of the import. The `toPng` + `fetch(dataUrl)` route it replaces … `fetch()` of a `data:` URL is governed by `connect-src` … so that route throws a TypeError at runtime."

**Location:** `app/lib/utils/exportGraph.ts:16-27`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The library's canvas-to-blob helper does exactly what the comment says — `canvas.toBlob` when
available, else a base64 `toDataURL` round-trip:

```js
// node_modules/html-to-image/es/util.js:129-131
if (canvas.toBlob) {
    ...
        canvas.toBlob(resolve, options.type ? options.type : 'image/png', options.quality ? options.quality : 1);
```

with the fallback branch reconstructing bytes via `window.atob(t.toDataURL(...).split(",")[1])`
(minified form at `node_modules/html-to-image/dist/html-to-image.js`, function `f`; same logic as
`es/util.js`). The shared pipeline's resource embedder does use `fetch`:

```js
// node_modules/html-to-image/dist/html-to-image.js (function C, embed-resources)
case 0: return [4, fetch(t, r)];
```

and `toPng` returns `toDataURL()` output — `return [2, e.sent().toDataURL()]` (dist bundle,
`t.toPng`) — so the replaced route did fetch a `data:` URL. The blocked-by-`connect-src` TypeError
is CSP3/Fetch spec behavior (paraphrased — no quote available because it is spec behavior, not
repo code).

**Evidence:** `app/lib/utils/exportGraph.ts:16-27`, `node_modules/html-to-image/es/util.js:125-140`, `node_modules/html-to-image/dist/html-to-image.js:1`

---

## Claim 12: "`NextResponse.next({ request: { headers } })` cannot expose the mutated request directly — it encodes the forwarded headers onto the response as `x-middleware-request-<name>`, which Next unpacks before rendering. Reading them back is how a test observes what the renderer will receive."

**Location:** `proxy.test.ts:8-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Confirmed empirically: the test suite reads exactly those headers and passes —

```ts
// proxy.test.ts:18-20
return response.headers.get(`x-middleware-request-${name}`);
```

and the assertions on `x-middleware-request-content-security-policy` and
`x-middleware-override-headers` (`proxy.test.ts:31-42`) all pass in the vitest run (`Tests 15
passed (15)`). The encoding is performed inside `NextResponse.next` in Next's own
`spec-extension/response` implementation (paraphrased — no quote available because the mechanism
spans Next's minified response/adapter modules; the passing assertions are direct behavioral
evidence on this Next version, 16.2.4 per `package.json:23`).

**Evidence:** `proxy.test.ts:8-20,30-42`, `package.json:23`

---

## Claim 13: "Load-bearing: Next parses the script nonce out of the request Content-Security-Policy header. Without this the nonce never reaches the renderer, and 'strict-dynamic' then blocks Next's own bootstrap scripts. Deleting the `requestHeaders.set(\"Content-Security-Policy\", csp)` line in proxy.ts must fail this test."

**Location:** `proxy.test.ts:26-30`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The nonce-from-request-header parse is quoted under Claim 1
(`node_modules/next/dist/server/app-render/app-render.js:166-167`). The referenced line exists:

```ts
// proxy.ts:31
requestHeaders.set("Content-Security-Policy", csp);
```

Deleting it would leave no forwarded CSP request header, so
`forwardedRequestHeader(response, "content-security-policy")` would be `null` and
`expect(requestCsp).toBeTruthy()` (`proxy.test.ts:37`) would fail — the coupling is direct. The
'strict-dynamic'-ignores-'self' consequence is CSP3 spec behavior (paraphrased — no quote
available because it is spec behavior, not repo code).

**Evidence:** `proxy.test.ts:26-42`, `proxy.ts:30-31`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 14: "The seam had no readers, and a header asserted in CI reads as live plumbing. Reinstate both together, never the header alone." (x-nonce absence test)

**Location:** `proxy.test.ts:79-83`
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High

"No readers" is confirmed: a repo-wide grep for `x-nonce` (case-insensitive, excluding
node_modules) matches only `proxy.ts:33` (comment), `proxy.test.ts:79,82` (this test), and
`app/layout.tsx:32` (comment) — no code reads the header (paraphrased — no quote available
because the claim covers absence of code; grep output is exhaustive). The test itself asserts
the deletion held:

```ts
// proxy.test.ts:82
expect(forwardedRequestHeader(run(), "x-nonce")).toBeNull();
```

and passes. No leftover comment in the diff describes the deleted `x-nonce` write as still
existing — layout.tsx and proxy.ts both describe it in the negative ("we don't need to read
x-nonce", "No `x-nonce` header").

**Evidence:** `proxy.test.ts:79-83`, `proxy.ts:33-36`, `app/layout.tsx:28-32`

---

## Claim 15: "CSP coverage must not be a function of a client-supplied request header: no matcher entry may carry a `missing:`/`has:` header condition." (matcher invariant test)

**Location:** `proxy.test.ts:85-94`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High

The config on this tree has a single object entry with only `source`:

```ts
// proxy.ts:59-63
matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
    },
  ],
```

No `missing:` or `has:` key exists anywhere in proxy.ts (paraphrased — no quote available because
the claim covers absence of code; grep for `missing:`/`has:` in proxy.ts hits only comments). The
test iterates `config.matcher` and asserts `matcher.missing`/`matcher.has` are `undefined`
(`proxy.test.ts:88-93`) and passes.

**Evidence:** `proxy.test.ts:85-94`, `proxy.ts:59-63`

---

## Claim 16: "CSP proxy (Next.js 16 renamed Middleware → Proxy) …"

**Location:** `proxy.ts:6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

Next's own type declarations document the rename:

```ts
// node_modules/next/dist/server/web/types.d.ts:10-13
 * @deprecated Use `ProxyConfig` instead. Middleware has been renamed to Proxy.
 */
export type { MiddlewareConfigInput as MiddlewareConfig } from '../../build/segment-config/middleware/middleware-config';
export type { MiddlewareConfigInput as ProxyConfig } from '../../build/segment-config/middleware/middleware-config';
```

Installed Next version is 16.2.4 (`"next": "16.2.4"`, `package.json:23`).

**Evidence:** `proxy.ts:6`, `node_modules/next/dist/server/web/types.d.ts:9-13`, `package.json:23`

---

## Claim 17: "Next 16's Proxy always runs on the Node.js runtime (it cannot be moved to Edge), so `crypto.randomUUID` and `Buffer` are both available as Node core APIs."

**Location:** `proxy.ts:12-15`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

Next's build-time validation states this verbatim:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

i.e., Next 16 rejects a runtime segment config in a proxy file rather than honoring an Edge
override. `crypto.randomUUID` and `Buffer` are Node core globals (paraphrased — no quote
available because these are platform APIs, not repo code); the proxy tests, which run under
`@vitest-environment node` and execute `Buffer.from(crypto.randomUUID())` (`proxy.ts:15`), pass.

**Evidence:** `proxy.ts:12-15`, `node_modules/next/dist/build/analysis/get-page-static-info.js:576`, `proxy.test.ts:1-3`

---

## Claim 18: "Setting the header only on the response is not enough: the renderer never sees it, no script gets a nonce, and — because 'strict-dynamic' makes CSP3 browsers ignore 'self' — the app's own scripts are blocked and hydration never runs. So the same policy string goes on both the forwarded request and the response. `.set` rather than `.append`, so a client-supplied Content-Security-Policy request header is clobbered rather than joined into a comma-list …"

**Location:** `proxy.ts:21-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Renderer-reads-request-header: quoted under Claim 1 (`app-render.js:166-167` reads request
headers in `parseRequestHeaders`). Same policy on both sides:

```ts
// proxy.ts:31, 38-41
requestHeaders.set("Content-Security-Policy", csp);
...
const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
response.headers.set("Content-Security-Policy", csp);
```

asserted by the passing test `expect(response.headers.get("Content-Security-Policy")).toBe(forwardedRequestHeader(response, "content-security-policy"))`
(`proxy.test.ts:47-50`). The `.set`-clobbers behavior is proven by the passing attacker-nonce test
(`proxy.test.ts:64-75`), which supplies `"content-security-policy": "script-src 'nonce-attacker'"`
and asserts the forwarded header does `not.toContain("attacker")`. The 'strict-dynamic'-ignores-
'self' clause is CSP3 spec behavior (paraphrased — no quote available because it is spec behavior,
not repo code).

**Evidence:** `proxy.ts:21-41`, `proxy.test.ts:45-75`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 19: "Typed against Next's own `ProxyConfig` (matching `next.config.ts`'s `NextConfig` annotation) so a typo in a matcher key — `missng:` for `missing:`, `sources:` for `source:` — fails the type check instead of silently changing which responses carry a CSP."

**Location:** `proxy.ts:43-46`
**Type:** Invariant / Reference
**Verdict:** Verified
**Confidence:** High

`ProxyConfig` is a real export of `next/server` (`node_modules/next/server.d.ts:10-15` re-exports
`ProxyConfig` from `next/dist/server/web/types`), aliasing `MiddlewareConfigInput`:

```ts
// node_modules/next/dist/build/segment-config/middleware/middleware-config.d.ts:6-11
matcher?: string | Array<{
    locale?: false;
    has?: RouteHas[];
    missing?: RouteHas[];
    source: string;
} | string>;
```

`source` is required and the entry type is closed, so an object-literal typo (`missng:`,
`sources:`) trips TypeScript's excess/missing property checks (paraphrased — no quote available
because this is TypeScript type-system behavior over the quoted type, not additional repo code).
The parallel with `next.config.ts` is accurate:

```ts
// next.config.ts:1-3
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
```

`npx tsc --noEmit` passes on the current, correctly-spelled config.

**Evidence:** `proxy.ts:43-47`, `node_modules/next/server.d.ts:10-15`, `node_modules/next/dist/server/web/types.d.ts:13`, `node_modules/next/dist/build/segment-config/middleware/middleware-config.d.ts:2-11`, `next.config.ts:1-3`

---

## Claim 20: "Apply CSP to page navigations only. Skip API routes (they don't render HTML) and Next's static assets (no scripts to nonce). Deliberately no `missing:` prefetch exclusion: … Skipping on `purpose: prefetch` / `next-router-prefetch` saved ~0.75 µs of nonce generation and let any caller that sets those headers receive a rendered document with no CSP, no nonce, and no frame-ancestors."

**Location:** `proxy.ts:48-63`
**Type:** Configuration / Performance
**Verdict:** Mostly accurate
**Confidence:** High

The matcher matches the description:

```ts
// proxy.ts:61
source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

— excludes `api` (API routes), `_next/static`, `_next/image`, and `favicon.ico` (static assets;
`app/favicon.ico` exists in the tree). No `missing:` clause exists (see Claim 15). The
consequence claim is mechanically right: a matcher `missing:` entry keyed on
`purpose`/`next-router-prefetch` headers would skip the proxy entirely for requests carrying
those client-suppliable headers, so no header set by `proxy` — CSP, nonce, `frame-ancestors` —
would be attached (paraphrased — no quote available because the claim describes the deleted
clause's counterfactual behavior, i.e., absence of code). The one imprecision is the number: a
micro-benchmark of the exact nonce expression on this machine
(`Buffer.from(crypto.randomUUID()).toString("base64")`, 200k iterations, Node in the worktree)
measured **~0.52 µs/op**, not ~0.75 µs. The `~` hedge and the order of magnitude are right; the
specific figure is ~40% high for this environment (and is machine-dependent). The rhetorical
point — the saving is negligible — is unaffected.

**Evidence:** `proxy.ts:48-63`, `proxy.test.ts:85-94`, micro-benchmark run 2026-08-06 (Node, worktree)

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 6** (`app/lib/security/csp.ts:21-24`): "every outbound call is made server-side from `app/api/**`" — true of execution context, but the fetch statements live in `app/lib/llm/*.ts` and `app/lib/formalization/artifactRoute.ts` (imported only by `app/api/**` handlers). Tighten to "from server-side code invoked only by `app/api/**` handlers" if precision matters; the security conclusion holds as-is.
- **Claim 20** (`proxy.ts:54`): "~0.75 µs of nonce generation" — measured ~0.52 µs/op in this environment; the `~` hedge covers it, but the figure is machine-dependent and reads ~40% high here. The argument does not depend on the exact value.

### Unverifiable
- None.

## Goal-Alignment Note
- Answered: All 7 brief items. (1) `buildCsp` nodeEnv is required with no default (`csp.ts:46`); sole non-test caller passes `process.env.NODE_ENV` explicitly (`proxy.ts:19`); fail-closed dev-eval preserved and tested against unset/misspelled envs (Claim 9). (2) x-nonce deletion safe — zero readers repo-wide; the load-bearing CSP-request-header property is directly tested, including the `.set`-clobber attacker-nonce case (Claims 13, 14, 18). (3) Matcher `missing:` clause gone; comment now matches the actual exclusions, and the no-`missing:`/`has:` invariant is test-enforced (Claims 15, 20). (4) connect-src invariant re-enumerated on this tree state: all client network calls are relative `/api/*` fetches; the only third-party origin (OpenRouter) is reached solely from server-side code; no OpenAlex or other phantom client calls exist (Claim 6). (5) Layout cost comment is honest (flags its own unmeasured numbers) and mechanically accurate; toBlob comment matches html-to-image's actual `canvas.toBlob`-with-`toDataURL`-fallback implementation including the retightened "runtime choice, not a guarantee of the import" qualifier (Claims 2, 11). (6) `ProxyConfig` typing is real and correct — exported by `next/server`, matcher entry requires `source`, `tsc --noEmit` passes (Claim 19). (7) Newly-introduced Incorrect/Stale sweep: none found — no comment in the diff describes deleted code as live; the two residual imprecisions are minor and hedged (Claims 6, 20). All 15 new tests pass.
- Out of scope: Browser-runtime CSP enforcement behavior (strict-dynamic script blocking, data:-fetch TypeError, pdfjs console violation) — spec-level claims consistent with the cited code but not statically checkable; code quality/design judgments (critic stages' remit).
- Escalate: Nothing. Zero Incorrect and zero Stale verdicts; under the 0R+0A merge standard, nothing in this fact-check pass blocks. The two Mostly-accurate items are optional wording tightenings, not defects.
