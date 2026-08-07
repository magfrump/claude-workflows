# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm2 (branch e3/csp-arm2)
**Scope:** `git diff d86d2dc..HEAD` (HEAD = 2544a19) — app/layout.tsx, app/lib/utils/exportGraph.test.ts, app/lib/utils/exportGraph.ts, proxy.test.ts, proxy.ts; plus commit 2544a19's message claims. Iteration-3 (final) pass; prior artifacts at csp-arm2/full-2/ treated as advisory only. Historical evidence restricted to ancestors of worktree HEAD.
**Checked:** 2026-08-06
**Commit:** 2544a19
**Total claims checked:** 15
**Summary:** 14 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Note on the loop-owner override: commit 9b4e453's message claim ("Next applies the nonce to every `<script>` tag") is ACCEPTED as immutable history per the loop owner. Per instruction, this pass verifies only that the waive documentation in 2544a19 exists and is accurate (Claim 14). It is not re-issued as a finding.

No `docs/reviews/hallucination-patterns.md` exists in the worktree; no new fabrication patterns were found this pass (and worktree writes are prohibited for this run), so no log update was made.

---

## Claim 1: "Every route under this layout must render per request: a statically prerendered HTML document would bake in one nonce and reuse it for every visitor... Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) and stamps it onto the bootstrap <script> tags it emits, so nothing here reads it directly."

**Location:** `app/layout.tsx:21-25`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

Next 16.2.4's renderer reads the nonce from the request's CSP header, exactly as the comment says — in `parseRequestHeaders` (a function over incoming request headers):

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

The proxy sets that request header:

```ts
// proxy.ts:49-50
const requestHeaders = new Headers(request.headers);
requestHeaders.set("Content-Security-Policy", csp);
```

The extracted nonce is applied to the framework's emitted bootstrap scripts (paraphrased — no quote available because the nonce threads through many render-path files, e.g. `node_modules/next/dist/server/app-render/required-scripts.js` and `get-layer-assets.js`, rather than one quotable site). "Nothing here reads it directly" holds: the layout's diff adds only `export const dynamic = "force-dynamic";` (app/layout.tsx:27) and contains no `headers()` call; `rg -n 'headers\(' app/layout.tsx` returns nothing (paraphrased — no quote available because the claim covers absence of code). That `force-dynamic` opts the segment out of static prerendering is Next's documented route-segment-config semantics (paraphrased — no quote available because the behavior lives in Next's render pipeline, not a single quotable line).

**Evidence:** `app/layout.tsx:21-27`, `proxy.ts:44-50`, `node_modules/next/dist/server/app-render/app-render.js:166-167`, `node_modules/next/dist/server/app-render/get-script-nonce-from-header.js`

---

## Claim 2: "1x1 transparent GIF — the shape toPng returns (base64 image data URL)."

**Location:** `app/lib/utils/exportGraph.test.ts:10`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High

`toPng` from `html-to-image` (package.json:19, `"html-to-image": "^1.11.13"`) returns a canvas data URL:

```js
// node_modules/html-to-image/es/index.js:46
return canvas.toDataURL();
```

`canvas.toDataURL()` yields a base64 `data:image/png;base64,...` string, so "base64 image data URL" is the correct shape (paraphrased — no quote available because `toDataURL` is a browser built-in, not repo code). The fixture itself is genuinely a 1x1 GIF: the test suite passes with the byte-level assertions `expect(bytes.slice(0, 6)).toEqual([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]); // GIF89a` (app/lib/utils/exportGraph.test.ts:16) — confirmed by the run in Claim 15 (234/234 pass).

**Evidence:** `app/lib/utils/exportGraph.test.ts:10-18`, `node_modules/html-to-image/es/index.js:46`, `package.json:19`

---

## Claim 3: "`fetch(dataUrl)` is the shorter spelling but is a `connect-src` fetch, and the app's CSP sets `connect-src 'self'`, which refuses `data:`. Decoding here keeps that directive tight instead of widening it for an export helper."

**Location:** `app/lib/utils/exportGraph.ts:16-21`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

The CSP does set the directive as claimed:

```ts
// proxy.ts:29
"connect-src 'self'",
```

That a `fetch()` call is governed by `connect-src`, and that `'self'` (same-origin) does not match the `data:` scheme, are CSP-spec semantics (paraphrased — no quote available because the behavior is defined by the CSP Level 3 spec and enforced by the browser, not by repo code). Both former `fetch(dataUrl)` call sites are gone: the diff shows `- const res = await fetch(dataUrl);` replaced by `triggerDownload(dataUrlToBlob(dataUrl), filename);` (app/lib/utils/exportGraph.ts:54) and `return dataUrlToBlob(dataUrl);` (app/lib/utils/exportGraph.ts:66); `rg -n 'fetch\(dataUrl' app/` returns nothing (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `app/lib/utils/exportGraph.ts:16-21,54,66`, `proxy.ts:29`

---

## Claim 4: "`NextResponse.next({ request: { headers } })` cannot expose the forwarded request headers directly — Next encodes them onto the response as `x-middleware-request-<lowercased-name>`, with the overridden names listed in `x-middleware-override-headers`, and unpacks them before render."

**Location:** `proxy.test.ts:5-12`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

Next 16.2.4 does exactly this encoding when `NextResponse.next` receives overridden request headers:

```js
// node_modules/next/dist/server/web/spec-extension/response.js:35-39
for (const [key, value] of init.request.headers){
    headers.set('x-middleware-request-' + key, value);
    keys.push(key);
}
headers.set('x-middleware-override-headers', keys.join(','));
```

The lowercasing in `<lowercased-name>` comes from the `Headers` iterator normalizing keys to lowercase, not from explicit code here (paraphrased — no quote available because it is Fetch-spec `Headers` behavior, not repo or Next code). The server-side unpack before render exists:

```js
// node_modules/next/dist/server/lib/router-utils/resolve-routes.js:414
const valueKey = 'x-middleware-request-' + key;
```

**Evidence:** `proxy.test.ts:5-22`, `node_modules/next/dist/server/web/spec-extension/response.js:35-39`, `node_modules/next/dist/server/lib/router-utils/resolve-routes.js:414`

---

## Claim 5: "[style-src 'unsafe-inline'] Required by React style={} attributes, reactflow's inline transforms and KaTeX; removing it silently breaks graph layout and equation sizing."

**Location:** `proxy.test.ts:60-61`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** Medium

All three named consumers exist in this app. Inline `style={}` attributes are widespread in project components — `rg -c 'style=\{' app --glob '*.tsx'` hits GraphPanel.tsx (2), NodeDetailPanel.tsx (2), ArtifactPanelShell.tsx (1), SemiformalPanel.tsx (1), OutputPanel.tsx (1), BookSpineDivider.tsx (1), CollapsibleSection.tsx (1), FormalizationControls.tsx (1) (paraphrased — no quote available because the evidence is grep counts across eight files). The libraries are direct dependencies: `"reactflow": "^11.11.4"` (package.json:29) and `"katex": "^0.16.45"` (package.json:21). That reactflow positions nodes via inline `transform` styles and KaTeX emits inline sizing styles is library-internal behavior (paraphrased — no quote available because it lives in the libraries' render output, not repo code) — hence Medium rather than High confidence on the "silently breaks" consequence, which is the standard failure mode when `'unsafe-inline'` is removed while inline styles are in use.

**Evidence:** `proxy.test.ts:59-65`, `package.json:21,29`, `app/components/panels/GraphPanel.tsx`, `app/components/panels/NodeDetailPanel.tsx`

---

## Claim 6: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust."

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium

The policy carries both tokens:

```ts
// proxy.ts:25
`script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```

Under CSP3 `'strict-dynamic'`, host-source and `'self'` entries are ignored, nonced scripts execute, and scripts they programmatically create inherit trust (paraphrased — no quote available because this is CSP Level 3 spec semantics enforced by the browser). Next's tagging of its scripts with the nonce is established in Claim 1. Medium confidence only because the enforcement is browser-side, outside static analysis of this repo.

**Evidence:** `proxy.ts:7-10,25`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 7: "Why `style-src 'unsafe-inline'`: React `style={}` attributes, reactflow's inline transforms and KaTeX all emit inline styles at runtime; dev also injects styles. (Tailwind v4 itself compiles to a linked stylesheet via `@tailwindcss/postcss` and is already covered by `'self'`.)"

**Location:** `proxy.ts:12-17`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

This is the post-fix rationale (brief item 2). It now agrees with the test file's rationale — proxy.ts:12-13 names "React `style={}` attributes, reactflow's inline transforms and KaTeX", the same three consumers as `proxy.test.ts:60-61` ("Required by React style={} attributes, reactflow's inline transforms and KaTeX") — the in-tree contradiction flagged in iteration 2 is resolved. The named consumers are real (see Claim 5 evidence). The Tailwind parenthetical is correct for this repo: Tailwind v4 is wired as a PostCSS plugin,

```js
// postcss.config.mjs:2-4
plugins: {
  "@tailwindcss/postcss": {},
},
```

and enters the page as an imported stylesheet, `import "./globals.css";` (app/layout.tsx:3), which Next ships as a linked stylesheet covered by `style-src 'self'` (paraphrased — no quote available because the shipping mechanism is Next's CSS pipeline, not project code). "dev also injects styles" refers to dev-mode style injection by the toolchain (paraphrased — no quote available because it is dev-server runtime behavior, not static repo code).

**Evidence:** `proxy.ts:12-17`, `proxy.test.ts:59-65`, `postcss.config.mjs:2-4`, `app/layout.tsx:3`, `package.json:36`

---

## Claim 8: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:19-20`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The load-bearing part of the claim holds. The only third-party endpoint in app code is server-side:

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

The Anthropic/OpenRouter provider chain lives in `app/lib/llm/` (e.g. `const anthropicKey = process.env.ANTHROPIC_API_KEY;`, app/lib/llm/streamLlm.ts:87 — reading server env vars), no file in `app/lib/llm/` carries a `"use client"` directive, and no `fetch(` call in `app/components/`, `app/page.tsx`, or `app/hooks/` targets anything other than relative `/api/...` paths (paraphrased — no quote available because the evidence is the absence of grep matches for non-`/api/` fetch targets in client code).

The imprecision: **OpenAlex calls do not exist in this branch's ancestry at all.** `rg -i openalex --glob '!node_modules'` hits only `proxy.ts` itself, and `git log -S openalex -i HEAD` returns only 9b4e453, the commit that introduced this comment (paraphrased — no quote available because the claim covers absence of code). So the comment enumerates a third-party integration the codebase does not have; the security conclusion is unaffected (a nonexistent call is trivially not browser-to-third-party). This is the same carried-over amber identified in prior iterations and is explicitly left open by 2544a19 ("Remaining amber and green findings are out of scope for this pass and remain open"). Not a fabricated-symbol hallucination — it names an external service, not a code symbol — so it does not qualify for the hallucination-patterns log.

**Evidence:** `proxy.ts:19-20`, `app/lib/llm/callLlm.ts:7`, `app/lib/llm/streamLlm.ts:87-91`, `app/api/` (directory listing)

---

## Claim 9: "Generate a fresh nonce per request. Next 16 proxy always runs on the Node.js runtime, where crypto.randomUUID and Buffer are both available."

**Location:** `proxy.ts:38-39`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

This is the post-fix runtime comment (brief item 1); the iteration-2 "Edge runtime" error is corrected and the replacement is accurate for the installed `"next": "16.2.4"` (package.json:23). Next's own build code says so verbatim:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

and the build forces the runtime for proxy files:

```js
// node_modules/next/dist/build/index.js:1515-1519
if (staticInfo.runtime === 'nodejs' || (0, _utils1.isProxyFile)(page)) {
    var _staticInfo_middleware;
    hasNodeMiddleware = true;
    functionsConfigManifest.functions['/_middleware'] = {
        runtime: 'nodejs',
```

`Buffer` is a Node global and `crypto.randomUUID` is available on Node's global webcrypto in all Node versions Next 16 supports (paraphrased — no quote available because these are Node.js built-ins, not repo code). "Fresh nonce per request" matches the implementation — the nonce is derived from `crypto.randomUUID()` on every invocation (`const nonce = Buffer.from(crypto.randomUUID()).toString("base64");`, proxy.ts:40) — and is asserted by the passing test "issues a fresh nonce per request" (proxy.test.ts:109-113).

**Evidence:** `proxy.ts:38-40`, `package.json:23`, `node_modules/next/dist/build/analysis/get-page-static-info.js:573-576`, `node_modules/next/dist/build/index.js:1515-1519`, `proxy.test.ts:109-113`

---

## Claim 10: "Next.js reads the nonce off the *request* `Content-Security-Policy` header during render and stamps it onto the bootstrap <script> tags it emits. Setting it only on the response is not enough: under 'strict-dynamic' the 'self' source is ignored, so un-nonced bootstrap scripts are refused and the app never hydrates. Both headers must carry the same policy."

**Location:** `proxy.ts:44-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The request-header read is quoted in Claim 1 (`node_modules/next/dist/server/app-render/app-render.js:166-167` — `parseRequestHeaders` consumes `headers['content-security-policy']`). The code sets both headers to the same string: `requestHeaders.set("Content-Security-Policy", csp);` (proxy.ts:50) and `response.headers.set("Content-Security-Policy", csp);` (proxy.ts:59), both from the single `const csp = buildCsp(nonce);` (proxy.ts:42). The passing test "forwards the same CSP on the request so Next can nonce its scripts" asserts `expect(forwarded).toBe(response.headers.get("Content-Security-Policy"));` (proxy.test.ts:88). That `'strict-dynamic'` causes `'self'` to be ignored so un-nonced scripts are refused is CSP3 spec behavior (paraphrased — no quote available because enforcement is browser-side, defined by the CSP Level 3 spec).

**Evidence:** `proxy.ts:42-59`, `proxy.test.ts:80-89`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 11: "Overwrite (not append) so a client-supplied x-nonce cannot be smuggled through to a server component."

**Location:** `proxy.ts:52-53`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High

The implementation uses `requestHeaders.set("x-nonce", nonce);` (proxy.ts:54) on a copy of the incoming headers (`const requestHeaders = new Headers(request.headers);`, proxy.ts:49). `Headers.set` replaces any existing value rather than appending (paraphrased — no quote available because `Headers` is a Fetch-spec built-in, not repo code). The passing test exercises exactly the smuggling scenario — a request sent with `headers: { "x-nonce": "attacker-controlled" }` (proxy.test.ts:100) asserts the forwarded value `not.toContain("attacker-controlled")` (proxy.test.ts:104-106).

**Evidence:** `proxy.ts:49-54`, `proxy.test.ts:97-107`

---

## Claim 12: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)."

**Location:** `proxy.ts:63-65`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High

The matcher below the comment implements each exclusion:

```ts
// proxy.ts:68-73
source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
missing: [
  { type: "header", key: "next-router-prefetch" },
  { type: "header", key: "purpose", value: "prefetch" },
],
```

The negative lookahead skips `api`, `_next/static`, `_next/image`, and `favicon.ico`; the `missing` clauses skip requests carrying either prefetch header, matching the comment's three skip categories (paraphrased — no quote available for the matcher *semantics* because matcher evaluation is Next framework behavior; the config itself is quoted above).

**Evidence:** `proxy.ts:61-75`

---

## Claim 13: Commit 2544a19 body — R1 disposition ("The comment justified crypto.randomUUID and Buffer by 'the Edge runtime that Next proxy runs in', but Next 16 proxy always runs on Node.js... Comment-only fix at proxy.ts:35-36") and A3 disposition ("the style-src 'unsafe-inline' rationale at proxy.ts:12-14 attributed the carve-out to Tailwind v4 emitting inline styles... Aligned it with the correct rationale already stated in proxy.test.ts:59-61")

**Location:** commit 2544a19 (message body)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High

Every checkable element holds. The pre-fix comment said what the commit quotes:

```diff
# git show 2544a19 -- proxy.ts (hunk @@ -32,8 +35,8 @@)
-  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
-  // available in the Edge runtime that Next proxy runs in.
+  // Generate a fresh nonce per request. Next 16 proxy always runs on the
+  // Node.js runtime, where crypto.randomUUID and Buffer are both available.
```

"proxy.ts:35-36" matches the pre-image location exactly (the hunk header `@@ -32,8 +35,8 @@` places the removed lines at old-file lines 35-36; in the post-fix file the comment sits at 38-39 — the citation is accurate for the file being fixed). The Node.js runtime and forced-`nodejs` build claims are verified with quotes in Claim 9. For A3: the old rationale read `- * Why 'style-src unsafe-inline': Tailwind v4 emits inline styles.` (same `git show 2544a19` diff, old proxy.ts:12-14), the Tailwind-compiles-to-a-linked-stylesheet correction is verified in Claim 7, and "proxy.test.ts:59-61" is the correct location of the test-file rationale — `it("keeps the style-src 'unsafe-inline' carve-out", ...)` at proxy.test.ts:59 with the comment at 60-61. The change is comment-only as claimed: the 2544a19 diff touches only `proxy.ts`, 8 insertions / 5 deletions, all in comments (paraphrased — no quote available because the assertion covers the whole diff, quoted in relevant part above).

**Evidence:** commit 2544a19 diff (`git show 2544a19 -- proxy.ts`), `proxy.ts:12-17,38-39`, `proxy.test.ts:59-61`, `node_modules/next/dist/build/analysis/get-page-static-info.js:576`

---

## Claim 14: Commit 2544a19 body — R2 waive documentation ("at 9b4e453 through d90d6bb the policy was set only on the response, and Next reads the nonce exclusively from the request header, so nonce was undefined during render... the claim is recorded as false in this message and in the iteration-2 rubric... Same class as A15")

**Location:** commit 2544a19 (message body)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High

Per the loop-owner override, 9b4e453's own claim is accepted immutable history; this claim checks only that the waive documentation exists and is accurate. It does, and it is.

(1) The historical mechanism description is correct. At 9b4e453 the CSP was set only on the response — the request headers got only `x-nonce`:

```ts
// git show 9b4e453:proxy.ts (proxy body)
requestHeaders.set("x-nonce", nonce);
...
response.headers.set("Content-Security-Policy", csp);
```

and `git show d90d6bb:proxy.ts` shows the same wiring (`requestHeaders.set("x-nonce", nonce);` at line 42, `response.headers.set("Content-Security-Policy", buildCsp(nonce));` at line 47) — no request-side CSP header in either revision (paraphrased in part — no quote available for the *absence* of a request-side CSP set). Next reads the nonce exclusively from the request CSP header (quoted in Claim 1: `app-render.js:166-167` falls back only to `content-security-policy-report-only`, never to response headers), so `nonce` would be `undefined` during render at those revisions.

(2) The waive is recorded where the commit says. In this message: the full R2 paragraph quoted in the claim header. In the iteration-2 rubric: row "R2 | (was A10) Commit 9b4e453's verification claim ... **Unfixable — history.** Practical disposition is this rubric acknowledgment, not a code change." (/workspace/runs/review-arms/e3-loops/csp-arm2/full-2/code-review-rubric.md:41). (3) A15 exists and is the class the commit says: "A15 | (was implicit in A10) Commits 9b4e453/d90d6bb state 'Layout reads `headers()` to opt out of static rendering' — true when written, superseded by R4's `force-dynamic`" (code-review-rubric.md:63). (4) "The underlying defect itself was fixed in 99e1229" — 99e1229's diff introduced the request-side `requestHeaders.set("Content-Security-Policy", csp);` now at proxy.ts:50 (paraphrased — no quote available because the fix is the cumulative diff verified across Claims 1 and 10).

**Evidence:** commit 2544a19 message; `git show 9b4e453:proxy.ts`; `git show d90d6bb:proxy.ts:42,47`; `node_modules/next/dist/server/app-render/app-render.js:166-167`; `/workspace/runs/review-arms/e3-loops/csp-arm2/full-2/code-review-rubric.md:30,41,63`

---

## Claim 15: Commit 2544a19 body — "Verification: npx vitest run -> 26 files / 234 tests pass (unchanged); npx tsc --noEmit clean; npm run lint clean (2 pre-existing warnings in app/page.tsx, untouched). All three changes are comments, so no test outcome could move."

**Location:** commit 2544a19 (message body)
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High

All three commands re-executed at HEAD (2544a19) in the worktree:

```
Test Files  26 passed (26)
     Tests  234 passed (234)
```

(`npx vitest run`, this pass). `npx tsc --noEmit` exited 0 with no output, and `npm run lint` reported exactly `✖ 2 problems (0 errors, 2 warnings)`, both `react-hooks/exhaustive-deps` warnings in `app/page.tsx` (lines 209:6 and 271:6) — a file untouched by the d86d2dc..HEAD diff (paraphrased — no quote available because the evidence is command output from this pass, reproduced in relevant part above). "All three changes are comments" is confirmed by the 2544a19 diff (Claim 13): the only hunks are comment lines in proxy.ts.

**Evidence:** commit 2544a19 message; `npx vitest run`, `npx tsc --noEmit`, `npm run lint` executed 2026-08-06 in the worktree; `app/page.tsx:209,271`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 8** (`proxy.ts:19-20`): connect-src rationale names "OpenAlex" but no OpenAlex call exists anywhere in this branch's ancestry (the word appears only in this comment). The security conclusion is unaffected. Carried-over amber, explicitly left open by 2544a19's scope statement; dropping the word "OpenAlex" (or the whole enumeration) would make the comment exact.

### Unverifiable
- None.

## Goal-Alignment Note
- Answered: All four brief items. (1) The post-fix runtime comment at proxy.ts:38-39 is now correct — Next 16 proxy always runs on Node.js, verified verbatim against Next 16.2.4's build error and forced `runtime: 'nodejs'` (Claim 9). (2) The post-fix style-src rationale at proxy.ts:12-17 now agrees with proxy.test.ts:60-61 and with the actual dependents (React `style={}` usage, reactflow, KaTeX; Tailwind v4 correctly described as a linked stylesheet) (Claims 5, 7). (3) All of 2544a19's commit-body claims verified: dispositions R1/A3 (Claim 13), R2 waive documentation exists and is accurate including the rubric R2/A15 rows (Claim 14), and all verification numbers re-executed and confirmed (Claim 15). (4) Full comment sweep of the changed files: connect-src enumeration (Claim 8), x-nonce comment (Claim 11), layout comment (Claim 1), matcher comment (Claim 12), test-file comments (Claims 2, 4, 5), strict-dynamic and dual-header comments (Claims 6, 10). Zero Incorrect and zero Stale verdicts remain in the changed files.
- Out of scope: 9b4e453's historical verification claim (loop-owner override — waive documentation verified instead, Claim 14); amber/green findings outside the changed-file comment set (e.g., the KaTeX `trust` default phrasing, rubric A14, which lives in a commit message and file not in this diff's comment scope).
- Escalate: Nothing. The only surviving non-Verified verdict is Claim 8 (Mostly accurate, carried-over amber on the phantom OpenAlex mention) — comment-precision only, no behavioral or security consequence; it does not meet the bar for a blocker and, per 2544a19, remains deliberately open.
