# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm2 (branch e3/csp-arm2)
**Scope:** `git diff d86d2dc..HEAD` — app/layout.tsx, app/lib/utils/exportGraph.ts, app/lib/utils/exportGraph.test.ts, proxy.ts, proxy.test.ts, plus commit messages in range (2544a19 checked as fresh; 9b4e453's verification claim handled per loop-owner override)
**Checked:** 2026-08-06
**Commit:** 2544a19
**Total claims checked:** 16
**Summary:** 12 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log: `docs/reviews/hallucination-patterns.md` does not exist in the worktree — no prior patterns to compare against.

Loop-owner override honored: commit 9b4e453's "Verified prod build ... Next applies the nonce to every `<script>` tag it generates" claim is treated as accepted-immutable-history, not a fresh finding. This report verifies only that the waive documentation exists and is accurate (Claim 14).

---

## Claim 1: "Every route under this layout must render per request: a statically prerendered HTML document would bake in one nonce ... Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) and stamps it onto the bootstrap <script> tags it emits, so nothing here reads it directly."

**Location:** `app/layout.tsx:21-25`
**Type:** Behavioral / Architectural
**Confidence:** High
**Verdict:** Verified
**Legibility-target:** contributor deciding whether layout code may read or must forward the nonce

The nonce-source mechanism is confirmed in the installed Next 16.2.4:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

where `headers` here are the rendered request's headers and the extractor pulls the `'nonce-'` source from `script-src`:

```js
// node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:18,26
const directive = directives.find((dir)=>dir.startsWith('script-src')) || directives.find((dir)=>dir.startsWith('default-src'));
.find((source)=>source.startsWith("'nonce-") && source.length > 8 && source.endsWith("'"))
```

The extracted nonce is passed into Next's bootstrap-script emission (paraphrased — no quote available because the nonce threads through `getRequiredScripts(..., nonce, ...)` in `node_modules/next/dist/server/app-render/required-scripts.js` across several call sites and reads more clearly as a summary). "Nothing here reads it directly" is confirmed: the only occurrences of "nonce" in `app/layout.tsx` are in this comment itself, and the file's sole related export is

```ts
// app/layout.tsx:26
export const dynamic = "force-dynamic";
```

(paraphrased — no quote available for the absence claim: `rg -n "headers\(|nonce" app/layout.tsx` matches only the comment lines 22-23 and the export at 26). The prerender-would-bake-one-nonce premise is a standard consequence of static prerendering (one render, one document served to all visitors) and is consistent with the mechanism above (paraphrased — no quote available because the claim is about Next's caching model, not a single code snippet).

**Evidence:** `app/layout.tsx:18-26`, `node_modules/next/dist/server/app-render/app-render.js:166-167`, `node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:18-26`, `node_modules/next/dist/server/app-render/required-scripts.js`

---

## Claim 2: "1x1 transparent GIF — the shape toPng returns (base64 image data URL)."

**Location:** `app/lib/utils/exportGraph.test.ts:10`
**Type:** Behavioral / Reference
**Confidence:** High
**Verdict:** Verified
**Legibility-target:** test reader judging whether the fixture is representative

The comment claims only that the fixture shares the *shape* of `toPng`'s output (a base64 image data URL), not its format. `toPng` in the installed html-to-image returns a canvas data URL:

```js
// node_modules/html-to-image/lib/index.js:136
return [2 /*return*/, canvas.toDataURL()];
```

`canvas.toDataURL()` with no argument produces a `data:image/png;base64,...` string (paraphrased — no quote available because the behavior is the HTML canvas spec default, not repo code). The fixture is a base64 image data URL of the same shape:

```ts
// app/lib/utils/exportGraph.test.ts:11-12
const dataUrl =
  "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";
```

**Evidence:** `app/lib/utils/exportGraph.test.ts:10-18`, `node_modules/html-to-image/lib/index.js:136`, `node_modules/html-to-image/lib/index.d.ts:5`

---

## Claim 3: "`fetch(dataUrl)` is the shorter spelling but is a `connect-src` fetch, and the app's CSP sets `connect-src 'self'`, which refuses `data:`. Decoding here keeps that directive tight instead of widening it for an export helper."

**Location:** `app/lib/utils/exportGraph.ts:16-21`
**Type:** Behavioral / Configuration
**Confidence:** High
**Verdict:** Verified
**Legibility-target:** contributor tempted to revert to the shorter `fetch(dataUrl)` spelling

The configuration half is directly quoted from the policy:

```ts
// proxy.ts:29
"connect-src 'self'",
```

The spec half — that `fetch()` is governed by `connect-src` and that `'self'` does not match `data:` URLs — is per the CSP3 specification's fetch-directive mapping and `'self'` matching rules (paraphrased — no quote available because the claim is about the CSP specification, not repo code). Both former `fetch(dataUrl)` call sites were replaced with the decoder:

```ts
// app/lib/utils/exportGraph.ts:54
triggerDownload(dataUrlToBlob(dataUrl), filename);
```

```ts
// app/lib/utils/exportGraph.ts:65
return dataUrlToBlob(dataUrl);
```

and no `fetch(` of a data URL remains in the file (paraphrased — no quote available because the claim covers absence of code: `rg -n "fetch\(" app/lib/utils/exportGraph.ts` returns no hits).

**Evidence:** `app/lib/utils/exportGraph.ts:14-66`, `proxy.ts:29`

---

## Claim 4: "`NextResponse.next({ request: { headers } })` cannot expose the forwarded request headers directly — Next encodes them onto the response as `x-middleware-request-<lowercased-name>`, with the overridden names listed in `x-middleware-override-headers`, and unpacks them before render."

**Location:** `proxy.test.ts:5-12`
**Type:** Behavioral / Architectural
**Confidence:** High
**Verdict:** Verified
**Legibility-target:** maintainer of the test helper if Next changes this internal encoding

The encoding is exactly as described in the installed Next 16.2.4:

```js
// node_modules/next/dist/server/web/spec-extension/response.js:35-39
for (const [key, value] of init.request.headers){
    headers.set('x-middleware-request-' + key, value);
    keys.push(key);
}
headers.set('x-middleware-override-headers', keys.join(','));
```

(`key` is lowercased by the `Headers` iteration contract — paraphrased, no quote available because that normalization is the WHATWG Headers spec, not Next code.) The "unpacks them before render" step is performed server-side when the middleware/proxy response is applied to the real request (paraphrased — no quote available because the unpacking spans `node_modules/next/dist/server/web/adapter.js` and the router-server header-application path across multiple functions). The test helper mirrors the encoding faithfully:

```ts
// proxy.test.ts:17-22
const overridden = (response.headers.get("x-middleware-override-headers") ?? "")
  .split(",")
  .map((s) => s.trim().toLowerCase());
if (!overridden.includes(name.toLowerCase())) return null;
return response.headers.get(`x-middleware-request-${name.toLowerCase()}`);
```

**Evidence:** `proxy.test.ts:5-23`, `node_modules/next/dist/server/web/spec-extension/response.js:33-40`, `node_modules/next/dist/server/web/adapter.js`

---

## Claim 5: "Required by React style={} attributes, reactflow's inline transforms and KaTeX; removing it silently breaks graph layout and equation sizing." (rationale for keeping `style-src 'unsafe-inline'`)

**Location:** `proxy.test.ts:60-61`
**Type:** Behavioral / Architectural
**Confidence:** Medium
**Verdict:** Verified
**Legibility-target:** reviewer considering tightening style-src

All three named dependents exist in the app. `style={` attributes appear in at least ten component files, e.g. `app/components/panels/GraphPanel.tsx` and `app/components/layout/IconRail.tsx` (paraphrased — no quote available because the claim is about breadth of usage; `rg -l "style=\{" app/` lists 10+ files). reactflow is a direct dependency and is used by the graph features:

```json
// package.json:29
"reactflow": "^11.11.4",
```

with imports in `app/components/features/proof-graph/ProofGraph.tsx` and `app/components/features/causal-graph/CausalGraphView.tsx` (paraphrased — no quote available because only the presence of the import matters). KaTeX renders via rehype:

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:6
import rehypeKatex from "rehype-katex";
```

That reactflow positions nodes with inline `transform` styles and KaTeX emits inline size/height styles is library behavior (paraphrased — no quote available because it is runtime DOM output of third-party libraries, not repo source). Confidence is Medium only because "removing it silently breaks graph layout and equation sizing" is a runtime consequence not exercised by any test in the repo; the dependency claims themselves are solid.

**Evidence:** `proxy.test.ts:59-65`, `package.json:21,29-30`, `app/components/features/output-editing/LatexRenderer.tsx:6-10`, `app/components/features/proof-graph/ProofGraph.tsx`

---

## Claim 6: "CSP proxy (Next.js 16 renamed Middleware → Proxy) with per-request nonces."

**Location:** `proxy.ts:5`
**Type:** Reference / Behavioral
**Confidence:** High
**Verdict:** Verified
**Legibility-target:** contributor wondering why the file is not named middleware.ts

The rename is reflected in Next 16.2.4's own error strings:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

The `middleware-to-proxy` docs URL and "Proxy file" terminology confirm the rename. Per-request nonce generation is in the code itself:

```ts
// proxy.ts:40
const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

and freshness is asserted by the passing test `"issues a fresh nonce per request"` at `proxy.test.ts:108-112` (paraphrased — no quote available because the assertion is quoted in Claim 4's file and the test run in Claim 16 shows it passing).

**Evidence:** `proxy.ts:5,37-40`, `node_modules/next/dist/build/analysis/get-page-static-info.js:575-585`, `proxy.test.ts:108-112`

---

## Claim 7: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust."

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Confidence:** Medium
**Verdict:** Verified
**Legibility-target:** reviewer assessing the CSP design

The policy carries both sources:

```ts
// proxy.ts:25
`script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```

Under CSP3 `'strict-dynamic'`, only nonce/hash-matched scripts execute, host-source and `'self'` allowlists are ignored, and scripts loaded by trusted scripts through non-parser-inserted means inherit trust (paraphrased — no quote available because this is the CSP3 specification's `'strict-dynamic'` semantics, not repo code). That Next tags its emitted bootstrap scripts with this nonce is the mechanism verified in Claim 1. Confidence Medium because the end-to-end browser enforcement is spec behavior, not something exercised in this repo's tests.

**Evidence:** `proxy.ts:22-34`, `node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:18-26`

---

## Claim 8: "Why `style-src 'unsafe-inline'`: React `style={}` attributes, reactflow's inline transforms and KaTeX all emit inline styles at runtime; dev also injects styles. (Tailwind v4 itself compiles to a linked stylesheet via `@tailwindcss/postcss` and is already covered by `'self'`.)" (post-fix rationale, brief item 2)

**Location:** `proxy.ts:12-17`
**Type:** Behavioral / Architectural
**Confidence:** High
**Verdict:** Verified
**Legibility-target:** reviewer checking that the two style-src rationales in the repo now agree

This is the corrected rationale from 2544a19 (amber A3). It is now aligned with the test file's rationale — the two name the same dependents:

```ts
// proxy.test.ts:60-61
// Required by React style={} attributes, reactflow's inline transforms and
// KaTeX; removing it silently breaks graph layout and equation sizing.
```

The dependents themselves are verified in Claim 5. The Tailwind parenthetical checks out against the toolchain: the plugin is a declared dev dependency —

```json
// package.json:36
"@tailwindcss/postcss": "^4",
```

— and the project's own docs describe the setup as "Tailwind CSS v4 with `@tailwindcss/postcss`" with theme config in `globals.css` (`CLAUDE.md`, Design System section; paraphrased — no quote needed beyond the cited section because it corroborates rather than establishes). A PostCSS-compiled Tailwind build ships as a linked stylesheet served same-origin, which `style-src 'self'` (quoted at `proxy.ts:26` in Claim 3's evidence) covers (paraphrased — no quote available because the linked-stylesheet output is build-pipeline behavior, not a repo snippet). No contradictory "Tailwind emits inline styles" rationale remains anywhere: `rg -n "unsafe-inline" --iglob '!node_modules'` hits only `proxy.ts:12,26` and `proxy.test.ts:59,63` (paraphrased — no quote available because the claim covers absence of other hits).

**Evidence:** `proxy.ts:12-17,26`, `proxy.test.ts:59-65`, `package.json:36,49`, `CLAUDE.md` (Design System)

---

## Claim 9: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:19-20`
**Type:** Architectural
**Confidence:** High
**Verdict:** Mostly accurate
**Legibility-target:** reviewer auditing whether the browser ever needs a third-party connect-src entry

The load-bearing half is correct. Anthropic and OpenRouter calls live in server-side library code:

```ts
// app/lib/llm/callLlm.ts:1-2
import { randomUUID } from "crypto";
import Anthropic from "@anthropic-ai/sdk";
```

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

These modules are imported only from `app/api/*/route.ts` handlers (server), not from `"use client"` components (paraphrased — no quote available because the claim aggregates the import graph across ~15 API route files; `callLlm`/`streamLlm` importers are all under `app/api/`). No client-side fetch to an absolute third-party URL exists in `app/` (paraphrased — no quote available because the claim covers absence of code: `rg` for `fetch(` with an `https://` literal outside `app/api` and `app/lib/llm` returns no hits).

The imprecision: **OpenAlex appears nowhere in the repository except this comment itself** — `rg -ci "openalex"` outside node_modules matches only `proxy.ts` (paraphrased — no quote available because the claim covers absence of code; single hit is this comment line). The comment enumerates a third-party caller that does not exist, so a reader would search for OpenAlex integration in vain. Same finding as iteration-2's Claim 8; still present at HEAD and explicitly left open by 2544a19 ("Remaining amber and green findings are out of scope for this pass").

**Evidence:** `proxy.ts:19-20`, `app/lib/llm/callLlm.ts:1-7,164`, `app/lib/llm/streamLlm.ts:249`, `app/api/` (import graph)

---

## Claim 10: "Generate a fresh nonce per request. Next 16 proxy always runs on the Node.js runtime, where crypto.randomUUID and Buffer are both available." (post-fix, brief item 1)

**Location:** `proxy.ts:38-39`
**Type:** Behavioral / Reference
**Confidence:** High
**Verdict:** Verified
**Legibility-target:** contributor extending the proxy who must know which runtime APIs are in scope

The corrected runtime identification matches Next 16.2.4's own enforcement, verbatim:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576-581
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. ...`;
if (isDev) {
    ...
    resolvedRuntime = _constants.SERVER_RUNTIME.nodejs;
```

In production builds the same condition throws rather than coercing (`throw ... "E1031"` at `get-page-static-info.js:583-585` — paraphrased continuation of the same quoted block). On Node.js, `Buffer` is a global and `crypto.randomUUID` is available on the global `crypto` object (Node >= 18, matching the project's declared "Node.js (v18+)" prerequisite in `CLAUDE.md`; paraphrased — no quote available because the API availability is Node platform documentation, not repo code). Per-request freshness is asserted by the passing test at `proxy.test.ts:108-112` (see Claim 16's live run). The pre-fix "Edge runtime" wording is gone from the file — "Edge" no longer appears in `proxy.ts` (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `proxy.ts:37-40`, `node_modules/next/dist/build/analysis/get-page-static-info.js:575-585`, `CLAUDE.md` (Prerequisites)

---

## Claim 11: "Next.js reads the nonce off the *request* `Content-Security-Policy` header during render and stamps it onto the bootstrap <script> tags it emits. Setting it only on the response is not enough: under 'strict-dynamic' the 'self' source is ignored, so un-nonced bootstrap scripts are refused and the app never hydrates. Both headers must carry the same policy."

**Location:** `proxy.ts:44-48`
**Type:** Behavioral
**Confidence:** High
**Verdict:** Verified
**Legibility-target:** future maintainer tempted to drop the request-header copy of the policy

The request-header read is quoted in Claim 1 (`app-render.js:166-167` reads `headers['content-security-policy']` and extracts the `'nonce-'` source). The code sets both copies from the same string:

```ts
// proxy.ts:49-50,58
const requestHeaders = new Headers(request.headers);
requestHeaders.set("Content-Security-Policy", csp);
...
response.headers.set("Content-Security-Policy", csp);
```

and the equality is pinned by a passing test:

```ts
// proxy.test.ts:83-90
const forwarded = forwardedRequestHeader(
  response,
  "content-security-policy",
);
expect(forwarded).not.toBeNull();
expect(forwarded).toBe(response.headers.get("Content-Security-Policy"));
```

The "'self' is ignored under 'strict-dynamic'" consequence is CSP3 spec behavior (paraphrased — no quote available because it is specification semantics, not repo code); it follows that un-nonced scripts under this policy would be refused. The never-hydrates outcome is a browser-runtime consequence not exercised in-repo, but the mechanism chain supporting it is fully verified.

**Evidence:** `proxy.ts:44-58`, `proxy.test.ts:76-90`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 12: "Overwrite (not append) so a client-supplied x-nonce cannot be smuggled through to a server component."

**Location:** `proxy.ts:51-53`
**Type:** Behavioral / Invariant
**Confidence:** High
**Verdict:** Mostly accurate
**Legibility-target:** security reviewer tracing header-injection surface

The overwrite semantics are real and tested:

```ts
// proxy.ts:53
requestHeaders.set("x-nonce", nonce);
```

`Headers.set` replaces any existing value (WHATWG Headers spec — paraphrased, no quote available because it is platform behavior), and the attacker case is pinned:

```ts
// proxy.test.ts:96-105
const response = proxy(
  new NextRequest(
    new Request("https://example.test/graph", {
      headers: { "x-nonce": "attacker-controlled" },
    }),
  ),
);
expect(forwardedRequestHeader(response, "x-nonce")).not.toContain(
  "attacker-controlled",
);
```

The imprecision, unchanged from iteration 2's Claim 11: **no server component reads x-nonce** — outside `proxy.ts` and its test, `x-nonce` appears nowhere in `app/` (paraphrased — no quote available because the claim covers absence of code: `rg -n "x-nonce" app/` returns no hits). The protected consumer is hypothetical wiring; the defensive claim is correct for any future consumer but describes a data flow that does not currently terminate anywhere. Explicitly left open by 2544a19's scope note.

**Evidence:** `proxy.ts:51-53`, `proxy.test.ts:96-105`

---

## Claim 13: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)."

**Location:** `proxy.ts:63-65`
**Type:** Configuration
**Confidence:** High
**Verdict:** Verified
**Legibility-target:** reviewer checking matcher coverage

The matcher below the comment implements exactly the three exclusions:

```ts
// proxy.ts:66-73
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

The negative-lookahead excludes `/api`, `/_next/static`, `/_next/image`, and `/favicon.ico`; the `missing` entries exclude requests carrying either prefetch header, which is the documented Next pattern for skipping prefetches (paraphrased — no quote available because the header names' prefetch semantics come from Next's matcher documentation, not repo code). Note the comment says "static assets" while the regex also excludes `_next/image` and `favicon.ico` — a fair summary, both being non-HTML asset routes.

**Evidence:** `proxy.ts:62-75`

---

## Claim 14: Commit 2544a19 R2 waive — "commit 9b4e453's message claims 'Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates'. That cannot have been true as written: at 9b4e453 through d90d6bb the policy was set only on the response, and Next reads the nonce exclusively from the request header ... recorded as false in this message and in the iteration-2 rubric ... The underlying defect itself was fixed in 99e1229 (iteration 1, R1). Same class as A15 ..."

**Location:** commit 2544a19 (message body); referenced history: commit 9b4e453
**Type:** Reference / Behavioral
**Confidence:** High
**Verdict:** Verified
**Legibility-target:** loop owner confirming the waive documentation exists and is accurate (per override, this is not re-litigated as a fresh finding)

Per the loop-owner override, only the waive documentation's existence and accuracy are checked. All four components verify:

1. **Quote fidelity.** 9b4e453's message contains, verbatim: "Verified prod build emits the CSP header and Next applies the nonce / to every <script> tag it generates" (paraphrased line-join — the quote spans a hard wrap in the commit body of 9b4e453; text matches character-for-character apart from the wrap).
2. **Mechanism accuracy.** At 9b4e453 the policy was set only on the response — the historical file forwards only `x-nonce` on the request:

```ts
// git show 9b4e453:proxy.ts, lines 42-48
const requestHeaders = new Headers(request.headers);
requestHeaders.set("x-nonce", nonce);
...
response.headers.set("Content-Security-Policy", csp);
```

   Same shape at d90d6bb (`response.headers.set("Content-Security-Policy", buildCsp(nonce))` at its line 47 — quoted from `git show d90d6bb:proxy.ts`). Next reads the nonce from the request `content-security-policy` header only (Claim 1's quote of `app-render.js:166-167`); nothing in Next reads `x-nonce` for this purpose (paraphrased — no quote available because the claim covers absence of code in Next's render path).
3. **Rubric recording.** The iteration-2 rubric documents the escalation and disposition: "R2 | (was A10) Commit 9b4e453's verification claim ... cannot have been true as written ... **Unfixable — history.**" (`/workspace/runs/review-arms/e3-loops/csp-arm2/full-2/code-review-rubric.md:41`, quoted in part; full row includes the no-future-citation instruction). The A15 cross-reference also exists and matches: "Commits 9b4e453/d90d6bb state 'Layout reads `headers()` to opt out of static rendering' — true when written, superseded by R4's `force-dynamic`" (`code-review-rubric.md:63`).
4. **Fix attribution.** 99e1229's message describes R1 as adding the request-header copy, and the current code carries it (`proxy.ts:50`, quoted in Claim 11).

**Evidence:** commit messages 2544a19, 9b4e453, d90d6bb, 99e1229 (`git log d86d2dc..HEAD`); `git show 9b4e453:proxy.ts`; `/workspace/runs/review-arms/e3-loops/csp-arm2/full-2/code-review-rubric.md:30,41,63`; `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 15: Commit 2544a19 R1/A3 dispositions — "Comment-only fix at proxy.ts:35-36"; "Next's own build error says so verbatim and the build forces runtime: 'nodejs' for proxy files"; "the style-src 'unsafe-inline' rationale at proxy.ts:12-14 attributed the carve-out to Tailwind v4 ... Aligned it with the correct rationale already stated in proxy.test.ts:59-61 ... proxy.ts was the one `rg \"unsafe-inline\"` hits first"; "All three changes are comments"

**Location:** commit 2544a19 (message body)
**Type:** Reference / Behavioral
**Confidence:** High
**Verdict:** Mostly accurate
**Legibility-target:** history reader reconstructing what iteration 2 changed

Almost everything verifies:

- **"Comment-only fix at proxy.ts:35-36"** — accurate against the pre-fix file: the diff hunk `@@ -32,8 +35,8 @@` in `git show 2544a19` removes exactly old lines 35-36 (`- // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both` / `- // available in the Edge runtime that Next proxy runs in.`, quoted from the diff). Post-fix the comment sits at `proxy.ts:38-39`; the commit cites the location being fixed, which is the natural reading.
- **"Next's own build error says so verbatim"** — verbatim confirmed: "Proxy always runs on Node.js runtime" (`node_modules/next/dist/build/analysis/get-page-static-info.js:576`, quoted in Claim 10). The dev-mode path also forces `resolvedRuntime = _constants.SERVER_RUNTIME.nodejs` (`get-page-static-info.js:581`, quoted in Claim 10).
- **"rationale at proxy.ts:12-14"** — accurate: the diff hunk `@@ -9,9 +9,12 @@` removes the three Tailwind-rationale lines at old lines 12-14 (`- * Why 'style-src unsafe-inline': Tailwind v4 emits inline styles. ...`, quoted from `git show 2544a19`).
- **"already stated in proxy.test.ts:59-61"** — accurate: the rationale comment is at lines 60-61 under the `it(` on line 59 (quoted in Claim 5).
- **"All three changes are comments"** — accurate: `git show 2544a19 --stat` reports only `proxy.ts | 13 ++++++++-----` and both hunks touch only comment lines (quoted in the two hunk excerpts above; paraphrased for the whole-diff claim — no additional quote available because the assertion covers the absence of non-comment lines in the diff, which the two quoted hunks jointly exhaust).

The one imprecision: **"proxy.ts was the one `rg \"unsafe-inline\"` hits first."** In a fresh run at HEAD, `rg -n "unsafe-inline"` listed `proxy.test.ts` hits before `proxy.ts` (paraphrased — no quote available because the claim is about tool output ordering, not file content). ripgrep's cross-file output order is not guaranteed (parallel directory traversal), so the aside is not reliably true; the substantive point — that `proxy.ts` prominently carried the wrong rationale — stands regardless. This is an aside about grep ergonomics, not a code claim; it does not affect the disposition it decorates.

**Evidence:** `git show 2544a19` (diff hunks and stat), `node_modules/next/dist/build/analysis/get-page-static-info.js:575-585`, `proxy.test.ts:59-65`, `proxy.ts:12-17,38-39`

---

## Claim 16: Commit 2544a19 verification paragraph — "npx vitest run -> 26 files / 234 tests pass (unchanged); npx tsc --noEmit clean; npm run lint clean (2 pre-existing warnings in app/page.tsx, untouched)."

**Location:** commit 2544a19 (message body)
**Type:** Reference / Configuration
**Confidence:** High
**Verdict:** Verified
**Legibility-target:** loop owner confirming the self-reported verification reproduces

All three figures reproduce live at HEAD (= 2544a19, so re-running is an exact replication):

- `npx vitest run` → "Test Files  26 passed (26) / Tests  234 passed (234)" (quoted from the run output in this session; paraphrased formatting — the two lines are the vitest summary block). "Unchanged" is consistent with 99e1229's message reporting the same 26/234 ("234 tests pass (was 221)", quoted from `git log`).
- `npx tsc --noEmit` → exits clean, no diagnostics (paraphrased — no quote available because the claim covers absence of output; the command exited 0 with empty output in this session).
- `npm run lint` → "✖ 2 problems (0 errors, 2 warnings)", both `react-hooks/exhaustive-deps` warnings at `app/page.tsx:209:6` and `app/page.tsx:271:6` (quoted from the lint output in this session). `app/page.tsx` is not in the d86d2dc..HEAD diff, confirming "pre-existing ... untouched" (paraphrased — no quote available because the claim covers absence of the file from `git diff --stat d86d2dc..HEAD`).

**Evidence:** live runs in worktree (vitest, tsc, eslint); `git show 2544a19`; `git log d86d2dc..HEAD` (99e1229 body); `git diff --stat d86d2dc..HEAD`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 9** (`proxy.ts:19-20`): the `connect-src 'self'` sufficiency argument holds, but the comment names OpenAlex, which appears nowhere else in the repository — a phantom third-party enumeration entry. Known-open amber carried from iteration 2; explicitly out of scope for 2544a19.
- **Claim 12** (`proxy.ts:51-53`): x-nonce overwrite semantics are correct and tested, but no server component reads x-nonce anywhere — the protected consumer is hypothetical wiring. Known-open finding carried from iteration 2.
- **Claim 15** (commit 2544a19 body): the aside "proxy.ts was the one `rg \"unsafe-inline\"` hits first" is not reliably true (ripgrep cross-file ordering is nondeterministic; a fresh run listed proxy.test.ts first). Immutable commit-message trivia; no code impact.
- **Claim 5** (`proxy.test.ts:60-61`): dependents verified, but "removing it silently breaks graph layout and equation sizing" is a runtime consequence no test exercises — listed here only for the confidence qualifier, not as an error.

### Unverifiable
- None.

## Goal-Alignment Note
- Answered: All four brief items. (1) proxy.ts runtime comment post-fix → Claim 10, Verified High — "Proxy always runs on Node.js runtime" is verbatim in Next 16.2.4's build source. (2) style-src rationale post-fix → Claim 8, Verified — now agrees with proxy.test.ts:60-61 and with the actual dependents (React style={}, reactflow, KaTeX all present; Tailwind v4 via @tailwindcss/postcss confirmed as linked-stylesheet toolchain). (3) 2544a19 commit-body claims → Claims 14-16: waive documentation exists and is accurate (quote fidelity, mechanism, rubric rows R2/A15, fix attribution all check out); dispositions and line references accurate; test/tsc/lint figures reproduced live (26 files / 234 tests, tsc clean, exactly 2 warnings in app/page.tsx). (4) Full comment sweep of changed files → Claims 1-13: connect-src enumeration (Claim 9, OpenAlex phantom persists), x-nonce comment (Claim 12, no consumer persists), layout comment (Claim 1, Verified), test-file comments (Claims 2, 4, 5, Verified), matcher/strict-dynamic/nonce-delivery comments (Claims 6, 7, 11, 13, Verified).
- Out of scope: whether the two persisting Mostly-accurate comments (OpenAlex phantom, hypothetical x-nonce consumer) must be fixed before termination — both were explicitly dispositioned as open ambers by 2544a19 and neither is Incorrect or Stale; browser-level end-to-end confirmation of hydration under the enforced policy (unit-testable surface fully covered; residual gap unchanged from iteration 2); review-quality or severity-mapping judgments (rubric's job).
- Escalate: Nothing. Zero Incorrect and zero Stale claims at HEAD — both iteration-2 Incorrect findings (Edge-runtime comment, Tailwind rationale) are fixed and verified, and the sole remaining red-class item (9b4e453's verification claim) is covered by the loop-owner's accepted-immutable-history override with accurate waive documentation (Claim 14). On comment accuracy, this range supports loop termination.
