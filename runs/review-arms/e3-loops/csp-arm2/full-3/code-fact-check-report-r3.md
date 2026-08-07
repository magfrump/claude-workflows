# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree /workspace/runs/review-arms/e3-loops/wt-csp-arm2, branch e3/csp-arm2)
**Scope:** `git diff d86d2dc..HEAD` (commits 9b4e453, b25e939, d90d6bb, 99e1229, 2544a19) — CSP proxy feature + iteration-1 fix + iteration-2 comment-only fix; files: app/layout.tsx, app/lib/utils/exportGraph.ts, app/lib/utils/exportGraph.test.ts, proxy.ts, proxy.test.ts, plus commit-message claims. Historical rule observed: only ancestors of HEAD read; prior-iteration artifacts treated as advisory hints only, re-verified independently here.
**Checked:** 2026-08-06
**Total claims checked:** 18
**Summary:** 15 verified, 2 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

**Commit:** 2544a19

Iteration-3 focus: the two comment corrections made by 2544a19 (Node-runtime justification, style-src rationale), the waive documentation for the immutable-history blocker R2, 2544a19's commit-body claims, and a completeness sweep of every remaining checkable comment in the changed files. Both prior Incorrect comment findings are now fixed and verify cleanly. Zero Incorrect verdicts remain on the working tree. The one prior Incorrect that survives (9b4e453's "nonce on every `<script>` tag" verification claim) is covered by the loop-owner override: it is accepted as immutable history, and this pass verified only that the waive documentation in 2544a19 exists and is accurate — it does (Claim 15). Remaining non-Verified verdicts are two Mostly-accurate comment impurities (the phantom "OpenAlex" mention; an asserted-not-demonstrated breakage consequence in a test comment) and one expected Stale in immutable commit messages, already recorded as rubric A15.

Hallucination-pattern log: `docs/reviews/hallucination-patterns.md` does not exist in the worktree (`ls docs/reviews/` returns nothing — paraphrased; no quote available because the result set is empty). No new fabrication patterns qualify for logging from this pass (zero Incorrect verdicts), and the no-worktree-writes rule applies regardless.

---

## Claim 1: layout.tsx — routes must render per request; Next takes the nonce from the request's CSP header and stamps it on bootstrap script tags; nothing here reads it directly

**Location:** `app/layout.tsx:21-26`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** future maintainer of the layout

The comment sits directly above the mechanism it describes:

```ts
// app/layout.tsx:23-26
// visitor, which defeats the nonce. Next.js takes the nonce from the request's
// Content-Security-Policy header (set in proxy.ts) and stamps it onto the
// bootstrap <script> tags it emits, so nothing here reads it directly.
export const dynamic = "force-dynamic";
```

Next's app renderer does read the nonce from the incoming request headers, not the response:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

and proxy.ts sets that request header: `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:46. The "nothing here reads it directly" half holds: the full file (app/layout.tsx:1-43) imports only `next`, `next/font/google`, and two CSS files (`import "./globals.css"; import "katex/dist/katex.min.css";` — app/layout.tsx:3-4); there is no `next/headers` import and no `x-nonce` read anywhere under `app/` (paraphrased — no quote available because the grep result set for `x-nonce` in app/ is empty; the only hits repo-wide are proxy.ts and proxy.test.ts). `dynamic = "force-dynamic"` on the root layout forcing per-request rendering for all child routes is Next's documented segment-config behavior (paraphrased — no quote available because the mechanism is spread across Next's static-analysis machinery rather than one quotable line).

**Evidence:** `app/layout.tsx:21-26`, `app/layout.tsx:1-4`, `node_modules/next/dist/server/app-render/app-render.js:166-167`, `proxy.ts:46`

---

## Claim 2: exportGraph.ts — "`fetch(dataUrl)` … is a `connect-src` fetch, and the app's CSP sets `connect-src 'self'`, which refuses `data:`"

**Location:** `app/lib/utils/exportGraph.ts:16-20`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** future maintainer tempted to simplify back to fetch

The policy does set the directive: `"connect-src 'self'",` — proxy.ts:29. That `fetch()` is governed by connect-src and that `'self'` never matches the `data:` scheme is CSP-spec behavior (paraphrased — no quote available because the CSP spec is not in the repo). Both call sites use the in-process decoder instead: `triggerDownload(dataUrlToBlob(dataUrl), filename);` — app/lib/utils/exportGraph.ts:54, and `return dataUrlToBlob(dataUrl);` — app/lib/utils/exportGraph.ts:65.

**Evidence:** `proxy.ts:29`, `app/lib/utils/exportGraph.ts:16-20`, `app/lib/utils/exportGraph.ts:54`, `app/lib/utils/exportGraph.ts:65`

---

## Claim 3: exportGraph.test.ts — fixture comment and test names match assertions

**Location:** `app/lib/utils/exportGraph.test.ts:9-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer

Unchanged since iteration 1; re-checked against the implementation. The fixture comment "1x1 transparent GIF — the shape toPng returns (base64 image data URL)" matches its assertions:

```ts
// app/lib/utils/exportGraph.test.ts:17-18
expect(bytes.slice(0, 6)).toEqual([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]); // GIF89a
expect(bytes.at(-1)).toBe(0x3b); // GIF trailer
```

Each of the five test names describes what its body asserts, and the implementation branches match: base64 detection via `const isBase64 = header.endsWith(";base64");` (app/lib/utils/exportGraph.ts:27), parameter-dropping via `.split(";")[0]` (app/lib/utils/exportGraph.ts:29-30), non-data: rejection guarded by `if (!dataUrl.startsWith("data:") || commaIndex === -1) { throw new Error("Not a data: URL"); }` (app/lib/utils/exportGraph.ts:22-24). That html-to-image's `toPng` returns a base64 image data URL is library behavior consistent with the call sites (paraphrased — no quote available because the behavior lives in the dependency, not the repo).

**Evidence:** `app/lib/utils/exportGraph.test.ts:9-39`, `app/lib/utils/exportGraph.ts:22-33`

---

## Claim 4: proxy.ts — "Next.js 16 renamed Middleware → Proxy"

**Location:** `proxy.ts:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** onboarding reader

The installed Next (`"next": "16.2.4",` — package.json:23) recognizes the proxy filename and treats middleware as the deprecated name; its build tooling refers to "Proxy file" and links `middleware-to-proxy` migration docs:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

**Evidence:** `package.json:23`, `node_modules/next/dist/build/analysis/get-page-static-info.js:576`

---

## Claim 5: proxy.ts — nonces + 'strict-dynamic': only nonce-tagged scripts run; scripts they load inherit trust; injected `<script>` refused

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** security reviewer

The policy matches the description: `` `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`, `` — proxy.ts:25. The described semantics — nonce-matched scripts execute, scripts they programmatically create inherit trust, and a statically injected un-nonced `<script>` is refused — are CSP3 `'strict-dynamic'` behavior (paraphrased — no quote available because this is spec behavior not represented in the repo). Medium confidence because the semantics claim rests on spec knowledge, not repo code.

**Evidence:** `proxy.ts:7-10`, `proxy.ts:25`

---

## Claim 6: proxy.ts — post-fix style-src rationale: React `style={}`, reactflow inline transforms, KaTeX emit inline styles; dev also injects styles; Tailwind v4 compiles to a linked stylesheet via `@tailwindcss/postcss`, covered by `'self'`

**Location:** `proxy.ts:12-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** future maintainer considering tightening style-src

This is 2544a19's A3 correction (brief item 2). The new text:

```ts
// proxy.ts:12-15
* Why `style-src 'unsafe-inline'`: React `style={}` attributes, reactflow's
* inline transforms and KaTeX all emit inline styles at runtime; dev also
* injects styles. (Tailwind v4 itself compiles to a linked stylesheet via
* `@tailwindcss/postcss` and is already covered by `'self'`.) Tightening to
```

It is now aligned with the test file's rationale — `// Required by React style={} attributes, reactflow's inline transforms and` / `// KaTeX; removing it silently breaks graph layout and equation sizing.` — proxy.test.ts:60-61 — so the two contradictory rationales the repo previously carried now agree. The named dependents are real: `"katex": "^0.16.45",` — package.json:21; `"reactflow": "^11.11.4",` — package.json:29; React `style={}` attributes are used in multiple app components (paraphrased — no quote available because it is a multi-file grep result set, e.g. app/components/features/causal-graph/CausalGraphNode.tsx among others). The Tailwind parenthetical checks out: `"@tailwindcss/postcss": {},` — postcss.config.mjs:3, with the compiled stylesheet entering via `import "./globals.css";` — app/layout.tsx:3, a linked stylesheet permitted by `style-src 'self'`. Medium rather than High confidence because "dev also injects styles" and the runtime inline-style behavior of reactflow/KaTeX are library/dev-mode behaviors verified from the dependency tree and general knowledge, not traced line-by-line (paraphrased — no quote available because the behavior lives in dependencies and Next's dev mode, not repo code).

**Evidence:** `proxy.ts:12-17`, `proxy.test.ts:60-61`, `package.json:21`, `package.json:29`, `postcss.config.mjs:3`, `app/layout.tsx:3`

---

## Claim 7: proxy.ts — "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party"

**Location:** `proxy.ts:19-20`
**Type:** Architectural / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** security reviewer

The substantive sufficiency claim holds on this state, as re-established in iteration 2 and spot-re-checked here: since the R2 fix removed the `fetch(dataUrl)` call sites (Claim 2), no browser-initiated network call targets anything but same-origin `/api/...` paths, and the OpenRouter/Anthropic fetches live in server-side modules imported only by API routes (paraphrased — no quote available because the conclusion aggregates a multi-file enumeration of every client-side network call site, performed in the iteration-2 pass and re-confirmed by the absence of new network-call changes in this comment-only commit: `git show 2544a19 --stat` touches only proxy.ts). Docked to Mostly accurate, unchanged from prior iterations, because "OpenAlex" names an integration that does not exist: `rg -in openalex` over the repo (excluding node_modules) hits only this comment line itself — `` * `connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter `` — proxy.ts:19 (the empty-elsewhere grep is paraphrased — no quote available because the result set outside this line is empty). 2544a19 edited the adjacent style-src paragraph but did not claim to fix this; it remains an open amber-class comment impurity, not a behavioral defect.

**Evidence:** `proxy.ts:19-20`, `app/lib/utils/exportGraph.ts:54`, `app/lib/utils/exportGraph.ts:65`

---

## Claim 8: proxy.ts — post-fix runtime comment: "Next 16 proxy always runs on the Node.js runtime, where crypto.randomUUID and Buffer are both available"

**Location:** `proxy.ts:38-39`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** future maintainer extending the proxy

This is 2544a19's R1 correction (brief item 1) — the prior "Edge runtime" comment (Incorrect/High in iterations 1-2) is gone. The new text:

```ts
// proxy.ts:38-40
// Generate a fresh nonce per request. Next 16 proxy always runs on the
// Node.js runtime, where crypto.randomUUID and Buffer are both available.
const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

Next 16's own tooling states the runtime claim verbatim:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
... Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

and the build unconditionally assigns the Node runtime to proxy files:

```js
// node_modules/next/dist/build/index.js:1515-1519
if (staticInfo.runtime === 'nodejs' || (0, _utils1.isProxyFile)(page)) {
    var _staticInfo_middleware;
    hasNodeMiddleware = true;
    functionsConfigManifest.functions['/_middleware'] = {
        runtime: 'nodejs',
```

`crypto.randomUUID` and `Buffer` both being available on the Node.js runtime is Node platform behavior (paraphrased — no quote available because it is runtime-API availability, not repo code); the passing test suite exercising this exact line (proxy.test.ts's `run()` invocations) confirms both APIs resolve at test time.

**Evidence:** `proxy.ts:38-40`, `node_modules/next/dist/build/analysis/get-page-static-info.js:576`, `node_modules/next/dist/build/index.js:1515-1519`

---

## Claim 9: proxy.ts — Next reads the nonce off the *request* CSP header; response-only is not enough because 'strict-dynamic' ignores 'self'; both headers must carry the same policy

**Location:** `proxy.ts:43-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** security reviewer / future maintainer

All three sub-claims hold, re-verified on this pass. (1) Next extracts the nonce from incoming request headers (app-render.js:166-167, quoted at Claim 1), and the code sets it there: `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:46, forwarded via `NextResponse.next({ request: { headers: requestHeaders } })` — proxy.ts:55-57. (2) Under CSP3 `'strict-dynamic'`, host-source and `'self'` expressions in script-src are ignored, so un-nonced bootstrap scripts would be refused (paraphrased — no quote available because this is CSP-spec behavior). (3) The response carries the identical policy — `response.headers.set("Content-Security-Policy", csp);` — proxy.ts:58 — and the test asserts equality: `expect(forwarded).toBe(response.headers.get("Content-Security-Policy"));` — proxy.test.ts:88.

**Evidence:** `proxy.ts:43-47`, `proxy.ts:55-58`, `node_modules/next/dist/server/app-render/app-render.js:166-167`, `proxy.test.ts:81-89`

---

## Claim 10: proxy.ts — "Overwrite (not append) so a client-supplied x-nonce cannot be smuggled through to a server component"

**Location:** `proxy.ts:51-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** security reviewer

`requestHeaders.set("x-nonce", nonce);` — proxy.ts:53 — and `Headers.set` replaces any existing value, unlike `append` (paraphrased — no quote available because it is WHATWG Fetch platform behavior, not repo code). The test exercises exactly this path with `headers: { "x-nonce": "attacker-controlled" },` — proxy.test.ts:101 — and asserts `expect(forwardedRequestHeader(response, "x-nonce")).not.toContain("attacker-controlled");` — proxy.test.ts:105-106.

**Evidence:** `proxy.ts:51-53`, `proxy.test.ts:97-107`

---

## Claim 11: proxy.ts — matcher comment: page navigations only; skip API routes (no HTML), static assets (no scripts to nonce), and prefetches

**Location:** `proxy.ts:60-62`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** future maintainer

The config matches all three stated exclusions: `source: "/((?!api|_next/static|_next/image|favicon.ico).*)",` — proxy.ts:65 — excludes API routes and Next static assets, and the `missing` conditions skip prefetch requests:

```ts
// proxy.ts:66-69
missing: [
  { type: "header", key: "next-router-prefetch" },
  { type: "header", key: "purpose", value: "prefetch" },
],
```

**Evidence:** `proxy.ts:60-69`

---

## Claim 12: proxy.test.ts — helper docstring: Next encodes forwarded request headers as `x-middleware-request-<lowercased-name>` with names listed in `x-middleware-override-headers`, unpacked before render; reading that encoding is the only unit-test observable

**Location:** `proxy.test.ts:5-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** future test maintainer

Next's response constructor performs exactly this encoding:

```js
// node_modules/next/dist/server/web/spec-extension/response.js:36-39
headers.set('x-middleware-request-' + key, value);
...
headers.set('x-middleware-override-headers', keys.join(','));
```

Keys come from `Headers` iteration, which normalizes names to lowercase, matching "lowercased-name" (paraphrased — no quote available because the lowercasing is WHATWG Headers platform behavior). The "unpacks them before render" and "only way to assert from a unit test" parts are consistent with Next's server applying override headers before invoking the renderer, verified by grep breadth across node_modules/next/dist/server rather than line-by-line (paraphrased — no quote available because the consumption is spread across multiple server modules) — hence Medium.

**Evidence:** `proxy.test.ts:5-12`, `node_modules/next/dist/server/web/spec-extension/response.js:34-39`

---

## Claim 13: proxy.test.ts — style-src test comment: "Required by React style={} attributes, reactflow's inline transforms and KaTeX; removing it silently breaks graph layout and equation sizing"

**Location:** `proxy.test.ts:60-61`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** future maintainer considering tightening style-src

The dependent-naming half is accurate and now agrees with the corrected proxy.ts rationale (Claim 6): both libraries are in the dependency tree (`"katex": "^0.16.45",` — package.json:21; `"reactflow": "^11.11.4",` — package.json:29) and inline `style` attributes are governed by style-src absent a style-src-attr directive (paraphrased — no quote available because this is CSP-spec behavior). Docked to Mostly accurate, unchanged from iteration 2, because the specific consequence — "silently breaks graph layout and equation sizing" — is asserted, not demonstrated by any test in the repo (paraphrased — no quote available because the claim covers absence of code: no test removes `'unsafe-inline'` and observes breakage). Fine as a comment; noted for calibration only.

**Evidence:** `proxy.test.ts:59-64`, `package.json:21`, `package.json:29`

---

## Claim 14: commit 2544a19 — R1 paragraph: comment-only fix at proxy.ts:35-36; API-availability point kept and re-attributed to the correct runtime

**Location:** commit 2544a19 message, R1 paragraph
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer / future archaeologist

The commit's description of the old comment is quoted accurately — the pre-fix file said `// available in the Edge runtime that Next proxy runs in.` (paraphrased quote of `git show d90d6bb:proxy.ts` line 36 — no in-worktree quote available because the text exists only in a historical blob). The fix is comment-only, exactly two lines, replacing that justification:

```diff
# git show 2544a19 -- proxy.ts (hunk @@ -32,8 +35,8 @@)
-  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
-  // available in the Edge runtime that Next proxy runs in.
+  // Generate a fresh nonce per request. Next 16 proxy always runs on the
+  // Node.js runtime, where crypto.randomUUID and Buffer are both available.
```

"proxy.ts:35-36" is the pre-fix file's line numbering (the removed lines sit at old lines 35-36 in the hunk above); at HEAD the replacement lands at proxy.ts:38-39 because the enlarged style-src paragraph above it shifted lines by 3. The claim is accurate against the state it describes. "Next's own build error says so verbatim and the build forces runtime: 'nodejs' for proxy files" both check out against Next sources (quoted at Claim 8: get-page-static-info.js:576 and build/index.js:1515-1519). The API-availability point is indeed kept on the new line 39.

**Evidence:** commit 2544a19 message, `git show 2544a19 -- proxy.ts`, `proxy.ts:38-39`, `node_modules/next/dist/build/analysis/get-page-static-info.js:576`, `node_modules/next/dist/build/index.js:1515-1519`

---

## Claim 15: commit 2544a19 — R2 WAIVED paragraph: waive documentation for 9b4e453's verification claim (loop-owner override — verify documentation existence and accuracy only)

**Location:** commit 2544a19 message, R2 paragraph
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** loop owner / future archaeologist

Per the loop-owner override, 9b4e453's historical claim is ACCEPTED as immutable history; this pass verifies only that the waive documentation exists and is accurate. It does, on all five checkable points:

1. **The quote is faithful.** 2544a19 attributes to 9b4e453: "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates". The actual message reads: `Verified prod build emits the CSP header and Next applies the nonce / to every <script> tag it generates.` — commit 9b4e453 message (line-wrap differs; wording identical).
2. **The falsity analysis is accurate.** At 9b4e453 the proxy set the CSP only on the response — the historical file's only header writes are `requestHeaders.set("x-nonce", nonce);` and `response.headers.set("Content-Security-Policy", csp);` (`git show 9b4e453:proxy.ts` lines 43 and 48; paraphrased-adjacent quote from a historical blob), same for d90d6bb (`response.headers.set("Content-Security-Policy", buildCsp(nonce));`, `git show d90d6bb:proxy.ts` line 47) — and Next reads the nonce exclusively from the request header (app-render.js:166-167, quoted at Claim 1), so `nonce` was `undefined` during render on those states.
3. **"Recorded … in the iteration-2 rubric" is true.** The rubric's red table carries the R2 row with disposition "**Unfixable — history.** Practical disposition is this rubric acknowledgment, not a code change." — /workspace/runs/review-arms/e3-loops/csp-arm2/full-2/code-review-rubric.md:41 (consulted as the referenced artifact of a Reference claim, not as verdict input).
4. **"The underlying defect itself was fixed in 99e1229" is true** — that commit added `requestHeaders.set("Content-Security-Policy", csp);` (now proxy.ts:46, Claim 9), and proxy.test.ts:81-89 asserts the forwarding.
5. **"Same class as A15" is true** — rubric row A15 records the related "Layout reads headers()" commit-message staleness for the same two commits (code-review-rubric.md:63; see Claim 18).

Consistent with the override, the underlying 9b4e453 claim is NOT reported as a fresh Incorrect finding in this pass; it is a documented, considered waive. The commit's own Notes paragraph transparently flags that the waive is a disposition, not a fix — an accurate self-description.

**Evidence:** commit 2544a19 message (R2 and Notes paragraphs), commit 9b4e453 message, `git show 9b4e453:proxy.ts`, `git show d90d6bb:proxy.ts`, `node_modules/next/dist/server/app-render/app-render.js:166-167`, `/workspace/runs/review-arms/e3-loops/csp-arm2/full-2/code-review-rubric.md:41,63`

---

## Claim 16: commit 2544a19 — A3 paragraph: old rationale attributed the carve-out to Tailwind v4 emitting inline styles (wrong); aligned with the correct rationale already stated in proxy.test.ts:59-61 so the two now agree

**Location:** commit 2544a19 message, A3 paragraph
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer

The removed text matches the commit's characterization:

```diff
# git show 2544a19 -- proxy.ts (hunk @@ -9,9 +9,12 @@)
- * Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening
- * to nonces would require rebuilding how Tailwind ships styles in dev and
- * SSR. Documented as a deliberate carve-out, not an oversight.
```

The Tailwind-compiles-to-a-linked-stylesheet correction is supported by `"@tailwindcss/postcss": {},` — postcss.config.mjs:3 (and `"@tailwindcss/postcss": "^4",` — package.json:36). The new proxy.ts text does now agree with the test comment (both quoted at Claims 6 and 13). The reference "proxy.test.ts:59-61" is accurate to within its own span: line 59 is the enclosing `it("keeps the style-src 'unsafe-inline' carve-out", ...)` and the rationale comment occupies lines 60-61 — the cited range covers the right block. The scoping self-description ("comment-only, zero behavior risk, in a file already being edited for R1") matches the diff: 2544a19 touches only proxy.ts, 8 insertions / 5 deletions, all inside comments (`git show 2544a19 --stat`: `proxy.ts | 13 ++++++++-----` — paraphrased stat line; quote is the stat output itself).

**Evidence:** commit 2544a19 message (A3 paragraph), `git show 2544a19 -- proxy.ts`, `postcss.config.mjs:3`, `package.json:36`, `proxy.test.ts:59-61`

---

## Claim 17: commit 2544a19 — verification block: "npx vitest run -> 26 files / 234 tests pass (unchanged); npx tsc --noEmit clean; npm run lint clean (2 pre-existing warnings in app/page.tsx, untouched). All three changes are comments, so no test outcome could move."

**Location:** commit 2544a19 message, Verification paragraph
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer

All three reproduce exactly in the worktree at HEAD, executed on this pass (2026-08-06): `npx vitest run` → `Test Files  26 passed (26)` / `Tests  234 passed (234)` (vitest output); `npx tsc --noEmit` exits 0 with empty output (paraphrased — no quote available because clean output is empty; exit code echoed as `tsc-exit:0`); `npm run lint` → `✖ 2 problems (0 errors, 2 warnings)`, both `react-hooks/exhaustive-deps` at app/page.tsx:209:6 and app/page.tsx:271:6 (lint output), and app/page.tsx is not in the d86d2dc..HEAD diff (paraphrased — no quote available because the claim covers absence: the diff stat lists only the five scoped files). "All three changes are comments" is confirmed by the 2544a19 diff (Claims 14, 16): every hunk edits comment lines only, so the no-test-movement inference is sound. "(unchanged)" is consistent with iteration 2's verified 234 count.

**Evidence:** commit 2544a19 message (Verification paragraph), vitest/tsc/lint runs of 2026-08-06 in the worktree, `git show 2544a19 -- proxy.ts`

---

## Claim 18: commits 9b4e453 / d90d6bb — "Layout reads headers() to opt out of static rendering"

**Location:** commit 9b4e453 message (echoed by d90d6bb's message)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** future archaeologist

Historical and immutable; carried unchanged from iteration 2 and already documented as rubric A15 (referenced by 2544a19's R2 paragraph — Claim 15 point 5). The feature commit says `- Layout reads headers() to opt out of static rendering — required / because per-request nonces can't be cached.` — commit 9b4e453 message. True when written; superseded by 99e1229's R4: the layout now opts out via `export const dynamic = "force-dynamic";` — app/layout.tsx:26 — and contains no `headers()` call or `next/headers` import (app/layout.tsx:1-4, quoted context at Claim 1). Expected commit-message staleness, flagged for awareness only; no action is possible or required.

**Evidence:** commit 9b4e453 message, commit d90d6bb message, `app/layout.tsx:26`, `app/layout.tsx:1-4`

---

## Claims Requiring Attention

### Incorrect

(none — both prior Incorrect comment findings are fixed and verified in this pass; the prior Incorrect historical commit claim is waived under the loop-owner override with accurate waive documentation, Claim 15)

### Stale
- **Claim 18** (commits 9b4e453/d90d6bb messages): "Layout reads headers()" — superseded by `force-dynamic`; immutable history, already recorded as rubric A15; awareness only.

### Mostly Accurate
- **Claim 7** (`proxy.ts:19`): "OpenAlex" names an integration that exists nowhere in the codebase; the substantive `connect-src 'self'` sufficiency claim holds. One-word comment fix if a future pass touches the file.
- **Claim 13** (`proxy.test.ts:60-61`): the "silently breaks graph layout and equation sizing" consequence is asserted, not demonstrated by any test; dependent-naming half is accurate and now consistent with proxy.ts.

### Unverifiable

(none)

## Goal-Alignment Note
- Answered: All four brief items. (1) The post-fix runtime comment at proxy.ts:38-39 is now correct — Next 16 Proxy always runs on Node.js, confirmed against Next's own build-error string (get-page-static-info.js:576) and the build's forced `runtime: 'nodejs'` for proxy files (build/index.js:1515-1519); Verified/High. (2) The post-fix style-src rationale is now aligned with proxy.test.ts's rationale and with the actual dependents (katex and reactflow in package.json, React style={} usage in app components, Tailwind v4 as a linked stylesheet via @tailwindcss/postcss); Verified/Medium. (3) 2544a19's commit-body claims all check out: the R1 and A3 change descriptions match the diff hunks exactly, the quoted historical text is faithful, the line references resolve (pre-fix numbering for proxy.ts:35-36, noted), and the static verification block (26 files / 234 tests, tsc clean, lint's 2 pre-existing page.tsx warnings) reproduces exactly on re-execution. The R2 waive documentation exists and is accurate on all five checkable points (quote fidelity, falsity analysis, rubric recording, 99e1229 fix reference, A15 cross-reference); per the loop-owner override it is treated as a considered disposition, not a fresh finding. (4) Full comment sweep of all five changed files: connect-src enumeration still Mostly accurate (OpenAlex phantom persists — the only surviving comment impurity in the working tree); x-nonce overwrite comment, layout comment, matcher comment, and all test-file comments Verified; no Incorrect or Stale claim remains in any working-tree file.
- Out of scope: whether the CSP policy is the right policy (critic territory); whether the waive itself is an acceptable loop-termination disposition (loop-owner decision — this report only confirms the documentation is accurate); the open amber/green findings 2544a19 explicitly left out of scope.
- Escalate: nothing. Zero Incorrect verdicts on the working tree; the two Mostly-accurate items are non-blocking comment impurities and the one Stale is immutable, documented history.
