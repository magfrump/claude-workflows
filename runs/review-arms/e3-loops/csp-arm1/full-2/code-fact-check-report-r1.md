# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (meta-formalism-copilot, branch e3/csp-arm1)
**Scope:** `git diff d86d2dc..HEAD` (HEAD = f25d968; commits 9b4e453, b25e939, d90d6bb, e5d95a9, f25d968) — files: app/layout.tsx, app/lib/security/csp.ts, app/lib/security/csp.test.ts, app/lib/utils/exportGraph.ts, proxy.ts, proxy.test.ts; plus commit-message claims of f25d968
**Checked:** 2026-08-06
**Commit:** f25d968
**Total claims checked:** 18
**Summary:** 15 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

No `docs/reviews/hallucination-patterns.md` exists in the worktree; no fabrication-class findings arose that would warrant creating one (and this pass writes nothing into the worktree).

---

## Claim 1: "Opt this layout out of static rendering so proxy.ts runs on every request and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:23-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** Future maintainer of the CSP nonce path

The mechanism is present and matches the comment:

```tsx
// app/layout.tsx:41
  await headers();
```

`headers()` from `next/headers` is Next's documented dynamic-rendering opt-out API; calling it in the root layout marks every route dynamic (paraphrased — no quote available because the claim is about Next.js framework semantics documented outside the repo, not a single quotable line in project source). Confidence is Medium only because the "runs on every request" consequence is a framework runtime behavior that static analysis cannot fully confirm; the code does exactly what the comment describes.

**Evidence:** `app/layout.tsx:22-41`

---

## Claim 2: "Next tags its own bootstrap `<script>` elements with the nonce it parses out of the *request* Content-Security-Policy header, which proxy.ts sets on the forwarded request headers — not out of the response header"

**Location:** `app/layout.tsx:24-28`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer checking the R1 blocker fix (nonce delivery)

This is the corrected version of the comment the full-1 review found Incorrect (it previously claimed the *response* header was read). The installed Next 16.2.4 parses the nonce from request headers:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
    const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
    const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

These lines sit inside `parseRequestHeaders(headers, options)` (`app-render.js:155`), whose argument is the incoming request's header map (paraphrased — no quote available because the request-origin of the argument is established by the function's callers across `app-render.js`, not a single line). And proxy.ts now does set that header on the forwarded request:

```ts
// proxy.ts:25-26
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("Content-Security-Policy", csp);
```

**Evidence:** `app/layout.tsx:22-32`, `proxy.ts:25-26`, `node_modules/next/dist/server/app-render/app-render.js:155-167`

---

## Claim 3: "the app is a single 'use client' route with no generateStaticParams, revalidate, or ISR — so there is nothing static to lose"

**Location:** `app/layout.tsx:37-40`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer weighing the waived dynamic-rendering blocker

The only page route in the repo is `app/page.tsx` (paraphrased — no quote available because the claim covers file-tree structure; `rg --files app -g 'page.tsx' -g 'page.ts'` returns exactly `app/page.tsx`), and it opens with:

```tsx
// app/page.tsx:1
"use client";
```

A repo-wide grep for `generateStaticParams|revalidate|force-static|dynamic =` in non-test app code matches only this comment itself in `app/layout.tsx:39` (paraphrased — no quote available because the claim asserts absence of code; the grep has no other hits).

**Evidence:** `app/page.tsx:1`, `app/layout.tsx:37-40`

---

## Claim 4: "Extracted from `proxy.ts` so the policy ... can be imported and asserted on directly (see `csp.test.ts`). The proxy entry point stays a thin wiring layer."

**Location:** `app/lib/security/csp.ts:4-6`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer checking the R3 blocker fix (testability)

`csp.test.ts` exists beside it with six tests importing `buildCsp` directly:

```ts
// app/lib/security/csp.test.ts:2
import { buildCsp } from "./csp";
```

and proxy.ts consumes it as wiring:

```ts
// proxy.ts:3
import { buildCsp } from "@/app/lib/security/csp";
```

Git history confirms `buildCsp` lived inside proxy.ts at e5d95a9 (`git show e5d95a9` shows `function buildCsp(nonce: string): string` defined in proxy.ts) (paraphrased — no quote available because the evidence is a historical diff hunk already excerpted above in the range log, not current source).

**Evidence:** `app/lib/security/csp.ts:1-58`, `app/lib/security/csp.test.ts:2`, `proxy.ts:3`, commit e5d95a9

---

## Claim 5: "Why `style-src 'unsafe-inline'`: the dependents are React `style={{...}}` attributes ..., reactflow's per-node transform styles, KaTeX's inline-styled output, `next/font`'s injected declarations, and dev-time HMR style injection — not Tailwind, which compiles to an external stylesheet here."

**Location:** `app/lib/security/csp.ts:13-18`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** Security reviewer evaluating the inline-style carve-out

Each named dependent exists in this codebase: inline `style={{` attributes appear in non-test components (e.g. `app/components/layout/IconRail.tsx`, `app/components/features/context-input/ContextInput.tsx`) (paraphrased — no quote available because the claim spans many call sites; grep for `style={{` lists multiple component files); reactflow is a real dependency:

```json
// package.json:29
    "reactflow": "^11.11.4",
```

KaTeX CSS is imported in the root layout:

```tsx
// app/layout.tsx:5
import "katex/dist/katex.min.css";
```

as are `next/font` fonts (`app/layout.tsx:2`: `import { EB_Garamond, Geist_Mono } from "next/font/google";`), and Tailwind v4 runs through PostCSS (`postcss.config.mjs:3`: `"@tailwindcss/postcss": {}`), i.e. compiled stylesheet rather than runtime inline injection. Confidence Medium because "dev-time HMR style injection" and whether next/font's declarations are truly inline `<style>` (vs. attribute) are framework runtime behaviors not checkable statically; the checkable parts all hold.

**Evidence:** `package.json:29`, `app/layout.tsx:2-5`, `postcss.config.mjs:3`, `app/components/layout/IconRail.tsx`, `app/components/features/context-input/ContextInput.tsx`

---

## Claim 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `app/lib/security/csp.ts:20-21`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Loop-termination decision (comment sweep)

The load-bearing half holds on this state. The only absolute-URL fetches in app code target OpenRouter:

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

`callLlm`/`streamLlm` are imported at runtime only by `app/api/**` route handlers and `app/lib/formalization/artifactRoute.ts` (itself route-side); the one client-side importer takes a type only (paraphrased — no quote available because the claim is an invariant inferred from the full importer list; the sole non-API importer is `app/lib/formalization/api.ts:3`, which reads `import type { LlmCallUsage } from "@/app/lib/llm/callLlm";` — a type-only import erased at compile time). Browser-side network calls are relative-URL fetches to the app's own API routes:

```ts
// app/lib/formalization/api.ts:10-14
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
```

The inaccuracy: **OpenAlex appears nowhere in the repo except this comment.** A case-insensitive repo-wide grep for `openalex` (excluding node_modules/.git) matches only `app/lib/security/csp.ts:20` itself (paraphrased — no quote available because the claim asserts absence of code; the grep has exactly one hit, the comment). The comment asserts properties of OpenAlex calls that do not exist. The precise version would drop OpenAlex or say "no browser code calls any third-party origin; Anthropic/OpenRouter traffic goes through Next API routes." This wording predates the range (it originated in 9b4e453's proxy.ts header) and survived the extraction verbatim.

**Evidence:** `app/lib/security/csp.ts:20-21`, `app/lib/llm/callLlm.ts:7,164`, `app/lib/llm/streamLlm.ts:249`, `app/lib/formalization/api.ts:3,10-14`

---

## Claim 7: "Note that it also governs `fetch()` of `data:` URLs — see `exportGraph.ts`, which decodes canvases with `toBlob` rather than re-fetching a data URL."

**Location:** `app/lib/security/csp.ts:22-23`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** Future maintainer tempted to widen connect-src

The cross-reference is accurate:

```ts
// app/lib/utils/exportGraph.ts:6
import { toBlob } from "html-to-image";
```

and no `fetch(` of a data URL remains in `exportGraph.ts` (paraphrased — no quote available because the claim asserts absence of code; the only `fetch` mentions in the file are inside the comment itself, lines 18-19). That CSP `connect-src` governs `fetch()` of `data:` URLs is a web-platform spec behavior (Fetch/CSP: `'self'` does not include the `data:` scheme, so such fetches are blocked) that cannot be confirmed from this repo's code — hence Medium, not High (paraphrased — no quote available because the claim is about browser spec behavior, not project source).

**Evidence:** `app/lib/security/csp.ts:22-23`, `app/lib/utils/exportGraph.ts:6,16-33`

---

## Claim 8: "Why `'unsafe-eval'` in development only ... Production builds do not depend on eval (pdfjs-dist probes for it with `new Function(\"\")`, but that probe is caught and pdfjs falls back — it only logs a CSP violation), so the carve-out is gated on the environment and never ships in a production build."

**Location:** `app/lib/security/csp.ts:25-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** Security reviewer evaluating the dev-only eval carve-out

The gating is exactly as described:

```ts
// app/lib/security/csp.ts:45
  const devEvalDirective = nodeEnv === "development" ? " 'unsafe-eval'" : "";
```

The pdfjs probe claim checks out in the installed package — the probe is wrapped in try/catch and degrades to `false`:

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

"Production builds do not depend on eval" (regarding Next's own output) is a framework claim not verifiable statically here, especially since `npm run build` fails in this sandbox on font fetches per the commit message — hence Medium (paraphrased — no quote available because the claim covers Next's production bundle behavior, outside this repo's source).

**Evidence:** `app/lib/security/csp.ts:25-30,45`, `node_modules/pdfjs-dist/build/pdf.mjs:506-513`

---

## Claim 9: "`nodeEnv` is a parameter rather than an ambient `process.env` read so the production branch can be observed from a test process without mutating global state. The comparison is against the *permissive* value, so any unset, misspelled, or unexpected environment yields the stricter policy."

**Location:** `app/lib/security/csp.ts:36-39`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer checking the R3/Y6 fold-in

```ts
// app/lib/security/csp.ts:41-45
export function buildCsp(
  nonce: string,
  nodeEnv: string | undefined = process.env.NODE_ENV,
): string {
  const devEvalDirective = nodeEnv === "development" ? " 'unsafe-eval'" : "";
```

The comparison is `=== "development"` (the permissive value), so every other value — including `undefined`, `""`, `"Development"`, `"prod"` — takes the empty-string branch and omits `'unsafe-eval'`. The fail-closed sweep test exercises exactly this:

```ts
// app/lib/security/csp.test.ts:56-58
    for (const env of [undefined, "", "Development", "dev", "test", "prod"]) {
      expect(buildCsp(NONCE, env)).not.toContain("'unsafe-eval'");
    }
```

The commit's claim that the comparison is "unchanged, only relocated" also holds: e5d95a9's in-proxy version read `process.env.NODE_ENV === "development"` (paraphrased — no quote available because the evidence is a historical diff hunk of e5d95a9, shown in that commit's diff of proxy.ts).

**Evidence:** `app/lib/security/csp.ts:41-45`, `app/lib/security/csp.test.ts:53-59`

---

## Claim 10: "Regression guard: graph PNG/zip export must decode canvases in-DOM (`exportGraph.ts` uses `toBlob`) rather than `fetch()`-ing a data URL, which would be blocked here."

**Location:** `app/lib/security/csp.test.ts:68-70`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Future maintainer of the export path

The cross-reference is live: `exportGraph.ts` imports and uses `toBlob`:

```ts
// app/lib/utils/exportGraph.ts:25-28
  const blob = await toBlob(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
```

and the guarded assertion matches the built policy (`app/lib/security/csp.ts:52`: `"connect-src 'self'",`).

**Evidence:** `app/lib/security/csp.test.ts:67-72`, `app/lib/utils/exportGraph.ts:24-33`, `app/lib/security/csp.ts:52`

---

## Claim 11: "Separated for code-splitting since html-to-image is only needed when exporting the React Flow graph."

**Location:** `app/lib/utils/exportGraph.ts:2-3`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Future maintainer of module layout

Both consumption paths reach this module only through dynamic `import()`:

```tsx
// app/components/panels/GraphPanel.tsx:102
      const { getGraphViewportElement, downloadGraphAsPng } = await import("@/app/lib/utils/exportGraph");
```

```ts
// app/page.tsx:576
    const { exportAllAsZip } = await import("@/app/lib/utils/exportAll");
```

`exportAll.ts` imports `exportGraph` statically (`app/lib/utils/exportAll.ts:10`: `import { getGraphViewportElement, graphToPngBlob } from "./exportGraph";`), but `exportAll` itself is only loaded dynamically, so html-to-image stays out of the main bundle either way.

**Evidence:** `app/components/panels/GraphPanel.tsx:102`, `app/page.tsx:576`, `app/lib/utils/exportAll.ts:10`

---

## Claim 12: "html-to-image's `toBlob` goes canvas → `canvas.toBlob()`, staying entirely within the DOM. The `toPng` + `fetch(dataUrl)` route it replaces looked equivalent but is not: `fetch()` of a `data:` URL is governed by `connect-src` ... so that route throws a TypeError at runtime. Do not reintroduce it"

**Location:** `app/lib/utils/exportGraph.ts:17-22`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Reviewer checking the R2 blocker fix (export vs connect-src)

The core structural claim is confirmed in the installed package — `toBlob` is `toCanvas` followed by `canvasToBlob`, with no fetch in the function body:

```js
// node_modules/html-to-image/lib/index.js:157-174 (excerpt)
function toBlob(node, options) {
    ...
                case 0: return [4 /*yield*/, toCanvas(node, options)];
                case 1:
                    canvas = _a.sent();
                    return [4 /*yield*/, (0, util_1.canvasToBlob)(canvas)];
```

The qualifier that keeps this at Mostly accurate: "staying entirely within the DOM" overstates slightly. The shared `toCanvas` pipeline can itself issue `fetch()` calls when embedding external resources:

```js
// node_modules/html-to-image/lib/dataurl.js:56
                case 0: return [4 /*yield*/, fetch(url, init)];
```

and `node_modules/html-to-image/lib/embed-webfonts.js:54` (`return [4 /*yield*/, fetch(url)];`). Those fetches existed identically on the old `toPng` path (which also runs `toCanvas` — `lib/index.js:127-131` shows `toPng` = `toCanvas` + `canvas.toDataURL()`), so the *delta* claim — the switch removes exactly the `fetch(dataUrl)` step — is precisely right; only the "entirely within the DOM" phrasing is broader than the library warrants. That a `data:`-URL fetch is blocked by `connect-src 'self'` is spec behavior not verifiable from this repo (paraphrased — no quote available because the claim is about browser CSP semantics, not project source).

**Evidence:** `app/lib/utils/exportGraph.ts:16-23`, `node_modules/html-to-image/lib/index.js:127-174`, `node_modules/html-to-image/lib/dataurl.js:56`, `node_modules/html-to-image/lib/embed-webfonts.js:54`

---

## Claim 13: Commit f25d968 — "The two call sites now share one renderGraphToBlob helper ... and its null return (toBlob's failure mode) is handled rather than silently producing an empty download."

**Location:** commit f25d968 (R2 paragraph); `app/lib/utils/exportGraph.ts:24-48`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer checking the R2 blocker fix

Both exported functions route through the helper:

```ts
// app/lib/utils/exportGraph.ts:39
  const blob = await renderGraphToBlob(viewportElement);
```

```ts
// app/lib/utils/exportGraph.ts:47
  return renderGraphToBlob(viewportElement);
```

and these are the only two call sites of graph rendering in non-test code (paraphrased — no quote available because the claim is an invariant inferred from a repo-wide grep for `renderGraphToBlob|downloadGraphAsPng|graphToPngBlob`, whose only non-test hits are `exportGraph.ts` itself, `exportAll.ts:64`, and `GraphPanel.tsx:104`). The null branch throws instead of downloading an empty blob:

```ts
// app/lib/utils/exportGraph.ts:29-31
  if (!blob) {
    throw new Error("Failed to render graph to an image");
  }
```

`toBlob`'s null failure mode is real: html-to-image's `canvasToBlob` resolves with `canvas.toBlob`'s callback value, which may be null (paraphrased — no quote available because the null path threads through `node_modules/html-to-image/lib/util.js`'s promise wrapper and the DOM `canvas.toBlob` contract, spanning library and platform).

**Evidence:** `app/lib/utils/exportGraph.ts:24-48`, `app/lib/utils/exportAll.ts:64`, `app/components/panels/GraphPanel.tsx:102-104`

---

## Claim 14: "`NextResponse.next({ request: { headers } })` cannot expose the mutated request directly — it encodes the forwarded headers onto the response as `x-middleware-request-<name>`, which Next unpacks before rendering."

**Location:** `proxy.test.ts:9-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reader of the test harness (why the indirection is trustworthy)

The installed Next confirms the encoding:

```js
// node_modules/next/dist/server/web/spec-extension/response.js:36-39
            headers.set('x-middleware-request-' + key, value);
        ...
        headers.set('x-middleware-override-headers', keys.join(','));
```

That Next "unpacks before rendering" is the server-side consumer of this encoding (paraphrased — no quote available because the unpacking happens in Next's server request-handling pipeline across multiple files, not a single quotable site).

**Evidence:** `proxy.test.ts:8-19`, `node_modules/next/dist/server/web/spec-extension/response.js:36-39`

---

## Claim 15: "Deleting the `requestHeaders.set(\"Content-Security-Policy\", csp)` line in proxy.ts must fail this test." / commit f25d968: "Falsification verified: deleting the requestHeaders.set line in proxy.ts fails 2 of its 5 tests."

**Location:** `proxy.test.ts:30-31`; commit f25d968 (R3 paragraph)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** Loop-termination decision (is the R1 fix actually pinned by tests?)

Verified by reading the assertions against the encoding mechanism (per instruction, without mutating the worktree). With the CSP `requestHeaders.set` deleted, only `x-nonce` would be forwarded, so `forwardedRequestHeader(response, "content-security-policy")` returns null. Test 1 fails at its first assertion:

```ts
// proxy.test.ts:38
    expect(requestCsp).toBeTruthy();
```

(and would also fail at `proxy.test.ts:40-42`, since `x-middleware-override-headers` would list only `x-nonce`). Test 2 fails because the response header is still set (`proxy.ts:36`: `response.headers.set("Content-Security-Policy", csp);`) while the forwarded copy is gone:

```ts
// proxy.test.ts:48-50
    expect(response.headers.get("Content-Security-Policy")).toBe(
      forwardedRequestHeader(response, "content-security-policy"),
    );
```

Tests 3-5 read only the response CSP and `x-nonce`, both unaffected by the deletion (paraphrased — no quote available because the claim covers which assertions do *not* reference the forwarded CSP header, an absence spanning `proxy.test.ts:53-85`). Exactly 2 of 5 fail — matching the commit. Medium rather than High because the falsification was confirmed by static reasoning, not by running the mutated suite.

**Evidence:** `proxy.test.ts:26-85`, `proxy.ts:25-36`

---

## Claim 16: "Next 16's Proxy always runs on the Node.js runtime (it cannot be moved to Edge), so `crypto.randomUUID` and `Buffer` are both available as Node core APIs." (and file header: "Next.js 16 renamed Middleware → Proxy")

**Location:** `proxy.ts:6,12-14`; commit f25d968 (R4 paragraph)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer checking the R4 blocker fix (runtime comment)

The installed Next 16.2.4 states both facts in the cited file:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
        const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

and the rename is echoed at `get-page-static-info.js:299` (`'proxy (previously called middleware)'` inside the error template). `crypto.randomUUID` and `Buffer` being Node core is standard platform surface (paraphrased — no quote available because the claim is about the Node.js runtime API, not project source). This replaces the pre-range comment that documented the Edge runtime.

**Evidence:** `proxy.ts:6,12-15`, `node_modules/next/dist/build/analysis/get-page-static-info.js:299,576`

---

## Claim 17: "x-nonce is the conventional seam for server components that render their own `<Script>` tags. Nothing reads it today ...; `.set` rather than `.append` so a client-supplied value is clobbered rather than joined into a comma-list."

**Location:** `proxy.ts:27-31`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewer of the deferred Y1 amber (x-nonce has no consumer)

"Nothing reads it today" holds: outside tests, `x-nonce` appears only where it is set (`proxy.ts:31`) and in the layout comment that explicitly declines to read it (`app/layout.tsx:31-32`: "We therefore don't need / to read x-nonce here ourselves.") (paraphrased — no quote available for the absence half because it asserts no reader exists; grep for `x-nonce` in non-test code returns only those two files). The clobbering behavior is `Headers.set` semantics, and the test pins it:

```ts
// proxy.test.ts:82-84
    expect(forwardedRequestHeader(response, "x-nonce")).not.toContain(
      "attacker-supplied",
    );
```

This is the rationale comment the commit says was "restored ... rather than deleted"; it is present and accurate.

**Evidence:** `proxy.ts:27-31`, `app/layout.tsx:26-32`, `proxy.test.ts:76-85`

---

## Claim 18: Commit f25d968 — "Verification: 26 test files / 232 tests pass (was 24 / 221)" and "Two new test files, 11 tests" / proxy.test.ts:1-3 — "Runs under the node vitest environment since NextRequest needs the web-standard globals" (default env is jsdom)

**Location:** commit f25d968 (verification paragraph); `proxy.test.ts:1-3`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Loop-termination decision (does the stated verification hold?)

Re-run in the worktree at HEAD:

```
Test Files  26 passed (26)
     Tests  232 passed (232)
```

(quoted from `npx vitest run` output in this pass). The new-test arithmetic is internally consistent: the two new files contribute 6 (`csp.test.ts`) + 5 (`proxy.test.ts`) = 11 `it()` blocks, and 24+2=26, 221+11=232. The environment claim is confirmed on both sides — the override:

```ts
// proxy.test.ts:1
// @vitest-environment node
```

against the jsdom default:

```ts
// vitest.config.mts (test block)
    environment: 'jsdom',
```

Why Mostly accurate rather than Verified: the vitest run emitted a `MISSING DEPENDENCY  Cannot find dependency 'jsdom'` resolution error before completing with all 26 files passing, so "232 tests pass" is true but the suite's environment resolution is noisier than the clean "npm test ... passing" the commit implies; the "was 24 / 221" baseline was checked arithmetically, not by re-running at e5d95a9 (which the historical rule discourages only for non-ancestors — it is an ancestor, but re-running old states was unnecessary given the commit-internal consistency) (paraphrased — no quote available because the claim concerns test-runner output, not source).

**Evidence:** commit f25d968 message, `proxy.test.ts:1-3`, vitest.config.mts, `app/lib/security/csp.test.ts:16-73`, `proxy.test.ts:25-86`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 6** (`app/lib/security/csp.ts:20-21`): The connect-src rationale names OpenAlex, but no OpenAlex call exists anywhere in the repo — the enumeration asserts properties of calls that don't exist. Drop "OpenAlex" (or rephrase as "no browser code calls third-party origins"). Carried verbatim from 9b4e453 through the extraction; this is the only surviving comment inaccuracy found in the sweep.
- **Claim 12** (`app/lib/utils/exportGraph.ts:17-18`): "staying entirely within the DOM" is slightly over-broad — html-to-image's shared `toCanvas` pipeline can fetch external resources (webfonts/images); the removed `fetch(dataUrl)` step is the exact and correctly-stated delta. Optional one-word tighten ("the final decode stays in-DOM").
- **Claim 18** (commit f25d968): "26 files / 232 tests pass" reproduces exactly, but the suite emits a jsdom dependency-resolution error before passing; the commit's "clean" framing omits that noise. No action needed beyond awareness.

### Unverifiable
- None.

---

## Goal-Alignment Note
- Answered: All six brief items. (1) Request-header CSP wiring verified against Next 16.2.4's `parseRequestHeaders` (Claim 2). (2) toBlob path verified in installed html-to-image source; both call sites through the shared helper; null handling present (Claims 11-13). (3) csp.ts nodeEnv mechanism and `=== "development"` fail-closed verified; docstring re-checked with connect-src re-enumerated on this state (Claims 5-9). (4) Falsification claim verified by reading assertions — exactly 2 of 5 proxy tests fail if the line is deleted (Claim 15). (5) 26/232 reproduced by running the suite; per-blocker claims R1-R4 each check out (Claims 2, 12-13, 4/9, 16). (6) Comment sweep: layout comment now correct, x-nonce rationale restored and accurate, matcher comment matches the config source+missing rules, runtime comment correct; the one surviving inaccuracy is the OpenAlex mention (Claim 6, Mostly accurate — cosmetic, not load-bearing).
- Out of scope: Runtime confirmation of R2/G1 (browser CSP enforcement of `data:` fetches, actual export behavior) — spec-level, flagged Medium where relied on; `npm run build` unavailable in sandbox per commit, not re-attempted.
- Escalate: Nothing at Incorrect/Stale severity. For loop termination: no comment in the changed files contradicts the code; the OpenAlex mention is the only residual and is below blocker grade.
