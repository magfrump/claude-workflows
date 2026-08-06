# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree /workspace/runs/review-arms/e3-loops/wt-csp-arm2, branch e3/csp-arm2)
**Scope:** `git diff d86d2dc..HEAD` (commits 9b4e453, b25e939, d90d6bb, 99e1229) — CSP proxy with per-request nonces plus iteration-1 fix commit; files: app/layout.tsx, app/lib/utils/exportGraph.ts, app/lib/utils/exportGraph.test.ts, proxy.ts, proxy.test.ts, and the four commit messages.
**Checked:** comments and docstrings in the diff, test names/comments, and commit-message claims; verified against Next.js 16.2.4 sources in node_modules, the app's client-side network call sites, and by running the test suite, tsc, and lint in the worktree.
**Total claims checked:** 23
**Summary:** The iteration-1 fix commit's claims all check out: the CSP is now set on the forwarded request headers (where Next actually reads the nonce — confirmed in Next's app-render source), both data-URL fetch sites were replaced with an in-process decoder, the 8 proxy tests + 5 exportGraph tests exist and the CSP-forwarding assertion demonstrably fails against the pre-fix wiring, and the stated verification results (234/234 tests, tsc clean, lint with exactly 2 pre-existing warnings) reproduce exactly. Three Incorrect findings remain, all carried from the feature commit and not claimed as fixed: the "Edge runtime" comment in proxy.ts (Next 16 Proxy always runs on the Node.js runtime), the "Tailwind v4 emits inline styles" style-src rationale (Tailwind emits a stylesheet; the real inline-style consumers are elsewhere), and the feature commit's "Verified prod build … Next applies the nonce to every `<script>` tag" (contradicted by the fix commit's own R1 finding). The connect-src docstring is now substantively true on this state but still names a nonexistent "OpenAlex" integration.

**Commit:** 99e1229

## Claim 1: layout.tsx — Next takes the nonce from the request's CSP header; nothing in the layout reads it

**Location:** app/layout.tsx:21-25
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** future maintainer of the layout

The comment says: "a statically prerendered HTML document would bake in one nonce and reuse it for every visitor … Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) and stamps it onto the bootstrap `<script>` tags it emits, so nothing here reads it directly." Next's renderer does exactly this — it reads the request headers, not the response. And the layout file contains no `headers()` call or nonce read; grepping the app for `x-nonce` finds only proxy.ts and proxy.test.ts.

**Evidence:**
- `const csp = headers['content-security-policy'] || headers['content-security-policy-report-only']; const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;` — node_modules/next/dist/server/app-render/app-render.js:166-167 (the `headers` here are the incoming request headers).
- proxy.ts:43 `requestHeaders.set("Content-Security-Policy", csp);` sets that request header.
- `rg -n "x-nonce" app/` returns no hits (only proxy.ts:50 and proxy.test.ts) — paraphrased grep result; no quote available because the result set is empty for app/.

## Claim 2: layout.tsx — `export const dynamic = "force-dynamic"` makes every route render per request

**Location:** app/layout.tsx:26 (and comment lines 21-23)
**Type:** Behavioral / configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** future maintainer

`dynamic = "force-dynamic"` is Next's documented route-segment config that forces dynamic (per-request) rendering for the segment and its children; on the root layout it covers every route — paraphrased from Next.js segment-config behavior; no single quotable line because the mechanism is spread across Next's static-analysis machinery (`PARSE_PATTERN` in node_modules/next/dist/build/analysis/get-page-static-info.js:95 includes `export const` + `dynamic` detection). The removal of the previous `await headers()` opt-out left no dangling artifacts: the file (read in full, app/layout.tsx:1-43) has no `next/headers` import, no `async` on `RootLayout`, and no leftover comment referencing `headers()`.

**Evidence:**
- `export const dynamic = "force-dynamic";` — app/layout.tsx:26.
- Full file read shows imports are only `next`, `next/font/google`, and two CSS files — app/layout.tsx:1-4.

## Claim 3: exportGraph.ts — `fetch(dataUrl)` is a connect-src fetch and the app's CSP `connect-src 'self'` refuses `data:`

**Location:** app/lib/utils/exportGraph.ts:16-20 (docstring of `dataUrlToBlob`)
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** future maintainer tempted to "simplify" back to fetch

The app's CSP does set `connect-src 'self'`, and per the CSP spec, `fetch()` is governed by connect-src and `'self'` matches only same-origin URLs, never the `data:` scheme — paraphrased spec behavior; no quote available because the CSP spec is not in the repo. The docstring's motivation (keep the directive tight rather than adding `data:` to connect-src) matches what the code does.

**Evidence:**
- `"connect-src 'self'",` — proxy.ts:27.
- `const binary = atob(payload);` in-process decode replacing the fetch — app/lib/utils/exportGraph.ts:36.

## Claim 4: both export call sites use `dataUrlToBlob`; no `fetch(` of a data: URL remains in app/

**Location:** app/lib/utils/exportGraph.ts:54, 65
**Type:** Architectural / staleness check
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer

`downloadGraphAsPng` and `graphToPngBlob` both call `dataUrlToBlob(dataUrl)` directly. A grep for `fetch(` across app/ (excluding tests) finds only same-origin `/api/...` calls in client code, two server-side calls to `OPENROUTER_API_URL` (app/lib/llm/callLlm.ts:164, app/lib/llm/streamLlm.ts:249), a server-side `LEAN_VERIFIER_URL` call (app/api/verification/lean/route.ts:21), and the docstring mention of `fetch(dataUrl)` — no code fetches a data: URL.

**Evidence:**
- `triggerDownload(dataUrlToBlob(dataUrl), filename);` — app/lib/utils/exportGraph.ts:54.
- `return dataUrlToBlob(dataUrl);` — app/lib/utils/exportGraph.ts:65.
- Grep result list — paraphrased; no quote available because it is a multi-file result set (11 hits, enumerated above).

## Claim 5: exportGraph.test.ts — test names and comments match assertions; decoder correctness

**Location:** app/lib/utils/exportGraph.test.ts:9-39
**Type:** Behavioral (test-to-name fidelity)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer

All 5 tests assert what their names claim. The base64 fixture comment ("1x1 transparent GIF — the shape toPng returns (base64 image data URL)") is accurate: `R0lGODlh…` decodes to bytes starting `47 49 46 38 39 61` ("GIF89a") and ending `0x3b` (GIF trailer), exactly what the test asserts; html-to-image's `toPng` does return a base64 image data URL (paraphrased — library behavior, consistent with exportGraph.ts's usage `const dataUrl = await toPng(...)` at app/lib/utils/exportGraph.ts:49-53). The implementation matches each tested behavior: base64 branch via `atob` + `charCodeAt` preserves raw bytes (test 2, `//79` → `[0xff, 0xfe, 0xfd]`); non-base64 branch uses `decodeURIComponent` (test 3); media-type parameters are dropped by `.split(";")[0]` (test 4); non-data: input throws (test 5, guarded by `dataUrl.startsWith("data:")` at exportGraph.ts:22-24). One unclaimed edge: the non-base64 branch UTF-8-encodes the decoded string via `new Blob([string])`, which would mangle percent-encoded *binary* payloads — but no comment or test claims byte fidelity for that branch, and both real call sites pass base64 PNG data URLs.

**Evidence:**
- `const isBase64 = header.endsWith(";base64");` — app/lib/utils/exportGraph.ts:27.
- `(isBase64 ? header.slice(0, -";base64".length) : header).split(";")[0] || "application/octet-stream";` — app/lib/utils/exportGraph.ts:29-30.
- `return new Blob([decodeURIComponent(payload)], { type: mediaType });` — app/lib/utils/exportGraph.ts:33.

## Claim 6: proxy.ts — "Next.js 16 renamed Middleware → Proxy"

**Location:** proxy.ts:5
**Type:** Reference / configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** onboarding reader

package.json pins `"next": "16.2.4"`, and the installed Next defines the proxy filename convention and a middleware deprecation message pointing at the rename.

**Evidence:**
- `const PROXY_FILENAME = 'proxy';` — node_modules/next/dist/lib/constants.js:289.
- `Please use "${_constants.PROXY_FILENAME}" instead. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy` — node_modules/next/dist/build/index.js (warnOnce for the deprecated middleware filename).
- `"next": "16.2.4",` — package.json:23.

## Claim 7: proxy.ts — nonces + 'strict-dynamic': only nonce-tagged scripts run; scripts they load inherit trust

**Location:** proxy.ts:7-10
**Type:** Behavioral (security mechanism)
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** security reviewer

Accurate description of CSP3 `'strict-dynamic'` semantics: nonce-matched scripts execute, scripts they programmatically create inherit trust, and static injected `<script>` tags without the nonce are refused — paraphrased; no quote available because this is CSP-spec behavior not represented in the repo. The policy string matches the description.

**Evidence:**
- `` `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`, `` — proxy.ts:23.

## Claim 8: proxy.ts — "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles"

**Location:** proxy.ts:12-14
**Type:** Behavioral (dependency rationale)
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** future maintainer considering tightening the CSP

Carried from the feature commit; the fix commit did not claim to correct it. The conclusion (the carve-out is needed) is right, but the attribution is wrong: Tailwind v4 compiles to a stylesheet (loaded here via `import "./globals.css"`, app/layout.tsx:3), not inline styles. The actual inline-style consumers in this app are React `style={}` attributes (used widely), reactflow's inline node transforms, KaTeX's inline sizing styles, and next/font's injected `<style>` element — the sibling test comment (proxy.test.ts:60-61) gives the correct rationale and never mentions Tailwind. Removing `'unsafe-inline'` would still break things, just not for the stated reason.

**Evidence:**
- `* Why \`style-src 'unsafe-inline'\`: Tailwind v4 emits inline styles.` — proxy.ts:12.
- `// Required by React style={} attributes, reactflow's inline transforms and // KaTeX; removing it silently breaks graph layout and equation sizing.` — proxy.test.ts:60-61 (the corrected rationale, added by the fix commit alongside the unchanged proxy.ts one).
- Tailwind-emits-stylesheet — paraphrased; no quote available because it is library behavior (globals.css `@theme inline` config per CLAUDE.md, shipped as a compiled stylesheet).

## Claim 9: proxy.ts — "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server"

**Location:** proxy.ts:16-17
**Type:** Architectural / invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** security reviewer

Re-enumerated all client-side network initiations on this state: every browser-initiated `fetch` targets a same-origin `/api/...` path (app/hooks/useAnalytics.ts:11,30; app/components/features/lean-display/LeanCodeDisplay.tsx:88; app/lib/formalization/api.ts:10,38,104 — its `url` parameters are `/api/...` routes passed by hooks; app/components/features/context-input/ContextInput.tsx:25). No `EventSource`, `WebSocket`, `XMLHttpRequest`, or `sendBeacon` usage exists in app/ (grep empty). The Anthropic SDK and OpenRouter fetches live in app/lib/llm/callLlm.ts and streamLlm.ts, whose non-test importers are exclusively API routes and app/lib/formalization/artifactRoute.ts (itself imported by API routes) — genuinely server-to-server. The R2 fix removed the one violation (the data:-URL fetch) that made this claim false on the previous state. Docked to Mostly accurate because "OpenAlex" appears nowhere in the codebase (`rg -in openalex app/` returns nothing) — the comment enumerates a nonexistent integration.

**Evidence:**
- `fetch("/api/analytics")` — app/hooks/useAnalytics.ts:11.
- `const response = await fetch(OPENROUTER_API_URL, {` — app/lib/llm/streamLlm.ts:249 (server-side module).
- `import { callLlm, OpenRouterError } from "@/app/lib/llm/callLlm";` — app/api/refine/context/route.ts:2 (representative importer; full importer list is API routes + artifactRoute.ts).
- OpenAlex grep empty — paraphrased; no quote available because the result set is empty.

## Claim 10: proxy.ts — "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in"

**Location:** proxy.ts:35-36
**Type:** Configuration / runtime
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** future maintainer

Carried unchanged from the feature commit (present verbatim in `git show d90d6bb:proxy.ts`); the fix commit did not claim to correct it. In Next 16 the Proxy file does not run in the Edge runtime — Next's own error message states the opposite. The code still works, because `crypto.randomUUID` and `Buffer` are both available in the Node.js runtime, but the comment names the wrong runtime and would misdirect anyone debugging runtime-availability issues.

**Evidence:**
- `const message = \`Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy\`;` — node_modules/next/dist/build/analysis/get-page-static-info.js:576.
- `// available in the Edge runtime that Next proxy runs in.` — proxy.ts:36.

## Claim 11: proxy.ts — Next reads the nonce off the request CSP header; response-only is not enough because 'strict-dynamic' ignores 'self'; both headers must carry the same policy

**Location:** proxy.ts:40-44
**Type:** Behavioral (the R1 fix's core mechanism claim)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** security reviewer / future maintainer

All three sub-claims hold. (1) Next's app renderer extracts the nonce from the incoming request's `content-security-policy` header (see Claim 1 evidence — app-render.js:166-167); the code sets it there (proxy.ts:43) via `NextResponse.next({ request: { headers: requestHeaders } })` (proxy.ts:52-54). (2) Under CSP3 `'strict-dynamic'`, host-source and `'self'` expressions in script-src are ignored, so un-nonced bootstrap scripts would be blocked — paraphrased; no quote available because this is CSP-spec behavior. (3) The response carries the identical policy string (`response.headers.set("Content-Security-Policy", csp)`, proxy.ts:55), and proxy.test.ts:81-89 asserts request/response policy equality.

**Evidence:**
- `requestHeaders.set("Content-Security-Policy", csp);` — proxy.ts:43.
- `response.headers.set("Content-Security-Policy", csp);` — proxy.ts:55.
- `expect(forwarded).toBe(response.headers.get("Content-Security-Policy"));` — proxy.test.ts:88.

## Claim 12: proxy.ts — "Overwrite (not append) so a client-supplied x-nonce cannot be smuggled through"

**Location:** proxy.ts:48-49
**Type:** Behavioral (security)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** security reviewer

`Headers.set` replaces any existing value (unlike `append`), so a client-sent `x-nonce` is discarded. proxy.test.ts:97-107 exercises exactly this with a request carrying `x-nonce: attacker-controlled` and asserts the forwarded value does not contain it.

**Evidence:**
- `requestHeaders.set("x-nonce", nonce);` — proxy.ts:50.
- `headers: { "x-nonce": "attacker-controlled" },` … `expect(forwardedRequestHeader(response, "x-nonce")).not.toContain("attacker-controlled");` — proxy.test.ts:101,105-106.

## Claim 13: proxy.ts — matcher comment: page navigations only; skip API routes, static assets, prefetches

**Location:** proxy.ts:58-60
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** future maintainer

The matcher's negative lookahead excludes `api`, `_next/static`, `_next/image`, and `favicon.ico`, and the `missing` conditions skip requests carrying `next-router-prefetch` or `purpose: prefetch` headers — matching all three stated exclusions.

**Evidence:**
- `source: "/((?!api|_next/static|_next/image|favicon.ico).*)",` — proxy.ts:63.
- `missing: [ { type: "header", key: "next-router-prefetch" }, { type: "header", key: "purpose", value: "prefetch" }, ],` — proxy.ts:64-67.

## Claim 14: proxy.test.ts — helper docstring: Next encodes forwarded request headers as `x-middleware-request-<lowercased-name>` + `x-middleware-override-headers`, and this is the only unit-test observable

**Location:** proxy.test.ts:5-12
**Type:** Behavioral (framework internals)
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** future test maintainer (the commit's own Notes flag this as the part to update if Next changes)

Next's `NextResponse` constructor does exactly this encoding; keys come from `Headers` iteration, which normalizes to lowercase, matching "lowercased-name". The "unpacks them before render" part and "only way to assert from a unit test" are consistent with Next's server applying these override headers before invoking the renderer (the override-header constant appears throughout node_modules/next/dist/server) — Medium rather than High because I verified the encoder directly but the unpack path and the "only observable" exhaustiveness claim only by breadth of grep, not line-by-line.

**Evidence:**
- `for (const [key, value] of init.request.headers){ headers.set('x-middleware-request-' + key, value); keys.push(key); } headers.set('x-middleware-override-headers', keys.join(','));` — node_modules/next/dist/server/web/spec-extension/response.js:34-39 (`handleMiddlewareField`).
- Unpack-before-render — paraphrased; no single quote available because the consumption is spread across multiple server modules matching `x-middleware-override-headers`.

## Claim 15: proxy.test.ts — buildCsp tests assert what their names claim

**Location:** proxy.test.ts:32-64
**Type:** Behavioral (test-to-name fidelity)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer

"emits exactly the intended directive set" asserts the sorted key list equals the 9 directives buildCsp emits (base-uri, connect-src, default-src, font-src, frame-ancestors, img-src, object-src, script-src, style-src — matches proxy.ts:21-29 one-for-one) plus exact values for four of them. "carries the nonce and 'strict-dynamic' on script-src" and "keeps the style-src 'unsafe-inline' carve-out" assert exactly those substrings on the right directives.

**Evidence:**
- `expect([...directives.keys()].sort()).toEqual([ "base-uri", "connect-src", "default-src", …` — proxy.test.ts:34-44.
- `expect(scriptSrc).toContain("'nonce-NONCE'"); expect(scriptSrc).toContain("'strict-dynamic'");` — proxy.test.ts:53-54.

## Claim 16: proxy.test.ts — the CSP-forwarded-on-request test falsifies the nonce-delivery wiring ("fails against the pre-R1 wiring")

**Location:** proxy.test.ts:81-89; commit 99e1229 message ("That last assertion fails against the pre-R1 wiring, so the nonce-delivery belief is now falsifiable")
**Type:** Behavioral / invariant (falsifiability)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer of the review-fix loop

Checked against the actual pre-fix state: `git show d90d6bb:proxy.ts` sets only `x-nonce` on the forwarded request headers and the CSP only on the response. Under that wiring, `content-security-policy` never appears in `x-middleware-override-headers` (the test request sends no such header), so `forwardedRequestHeader(...)` returns null and `expect(forwarded).not.toBeNull()` fails. The companion tests also hold: "forwards x-nonce matching the nonce in the policy" cross-checks the forwarded nonce against the `'nonce-…'` token in the response CSP (proxy.test.ts:88-96), and "issues a fresh nonce per request" compares two independent invocations' CSP strings (proxy.test.ts:109-113), which differ because each call generates `Buffer.from(crypto.randomUUID()).toString("base64")` (proxy.ts:37).

**Evidence:**
- Pre-fix wiring: `requestHeaders.set("x-nonce", nonce); … response.headers.set("Content-Security-Policy", buildCsp(nonce));` — d90d6bb:proxy.ts (no request-side CSP set).
- `if (!overridden.includes(name.toLowerCase())) return null;` — proxy.test.ts:20.
- `expect(forwarded).not.toBeNull();` — proxy.test.ts:87.

## Claim 17: proxy.test.ts — style-src carve-out comment: "Required by React style={} attributes, reactflow's inline transforms and KaTeX"

**Location:** proxy.test.ts:60-61
**Type:** Behavioral (dependency rationale)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** future maintainer considering tightening style-src

Directionally correct and much better than the proxy.ts rationale (Claim 8): inline `style` attributes are governed by style-src (absent a style-src-attr directive) and require `'unsafe-inline'`; reactflow positions nodes with inline transform styles and KaTeX emits inline sizing styles, and both are in the dependency tree (package.json:21 `"katex": "^0.16.45"`, :29 `"reactflow": "^11.11.4"`). "Mostly accurate" rather than Verified because the specific breakage claim ("silently breaks graph layout and equation sizing") is asserted, not demonstrated by any test, and the CSP-attr mechanics are paraphrased spec behavior — no quote available because the spec is not in the repo.

**Evidence:**
- `"reactflow": "^11.11.4",` — package.json:29.
- `// Required by React style={} attributes, reactflow's inline transforms and` — proxy.test.ts:60.

## Claim 18: commit 99e1229 — R1/R2/R3 fix descriptions, including "234 tests pass (was 221)"

**Location:** commit 99e1229 message, R1-R3 paragraphs
**Type:** Behavioral / configuration (commit-message claims)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer / future archaeologist

R1: request+response both carry the same policy — verified at proxy.ts:43,55 and Claim 11. R2: both fetch call sites replaced — verified at Claim 4. R3: buildCsp is exported (`export function buildCsp` — proxy.ts:19) and proxy.test.ts covers exactly the six enumerated things (directive set, nonce on script-src, style-src carve-out, per-request freshness, x-nonce overwrite-not-append, CSP forwarded on request) in its 8 tests; exportGraph.test.ts covers the decoder in 5 tests. The static count reproduces exactly: `npx vitest run` in the worktree → "Test Files 26 passed (26), Tests 234 passed (234)". The arithmetic is consistent: 234 − 221 = 13 = 8 proxy tests + 5 exportGraph tests.

**Evidence:**
- `Test Files  26 passed (26) / Tests  234 passed (234)` — vitest output, run 2026-08-06 in the worktree.
- `export function buildCsp(nonce: string): string {` — proxy.ts:19.

## Claim 19: commit 99e1229 — R4: replaced the discarded `await headers()` + wrong comment with `export const dynamic = "force-dynamic"`

**Location:** commit 99e1229 message, R4 paragraph
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer

The current layout has no `headers()` call and declares the rendering mode in its public surface (Claim 2); the new comment (app/layout.tsx:21-25) describes the corrected R1 mechanism (nonce read from the request CSP header), which matches Next's implementation (Claim 1) — so it does "survive R1's correction" as claimed.

**Evidence:**
- `export const dynamic = "force-dynamic";` — app/layout.tsx:26.
- No `next/headers` import — app/layout.tsx:1-4 (imports are next, next/font/google, two CSS files).

## Claim 20: commit 99e1229 — verification block: "npx vitest run -> 26 files / 234 tests pass; npx tsc --noEmit clean; npm run lint clean (2 pre-existing warnings in app/page.tsx, untouched)"

**Location:** commit 99e1229 message, Verification paragraph
**Type:** Configuration / verification claim
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** reviewer

All three reproduce exactly in the worktree at HEAD: vitest 26 files / 234 tests pass; `npx tsc --noEmit` exits 0 with no output; `npm run lint` reports exactly `✖ 2 problems (0 errors, 2 warnings)`, both `react-hooks/exhaustive-deps` warnings in app/page.tsx (lines 209 and 271), a file untouched by this diff.

**Evidence:**
- `✖ 2 problems (0 errors, 2 warnings)` — npm run lint output, run 2026-08-06; both at app/page.tsx:209:6 and 271:6.
- tsc exit code 0, empty output — paraphrased; no quote available because clean output is empty.

## Claim 21: commit 9b4e453 — "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates"

**Location:** commit 9b4e453 message
**Type:** Behavioral (verification claim, feature commit)
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** future archaeologist reading the history

The second half of this claim cannot have been true as stated. At 9b4e453 (and through d90d6bb) the CSP was set only on the response, and Next reads the nonce exclusively from the *request* `content-security-policy` header (app-render.js:166-167 — Claim 1), so `nonce` was `undefined` during render and Next's scripts were not nonced. The fix commit's own R1 paragraph states this outright. The first half (build emits the CSP response header) is plausible; the "nonce on every `<script>` tag" half is refuted by the wiring. This is a historical claim the fix commit did not (and cannot) amend, but it stands contradicted in the branch history.

**Evidence:**
- `R1 FIXED — nonce never reached the document. The policy was set only on the response; Next reads the nonce off the *request* Content-Security-Policy header during render.` — commit 99e1229 message.
- Pre-fix wiring lacking any request-side CSP set — d90d6bb:proxy.ts (see Claim 16 evidence).

## Claim 22: commit 9b4e453 — "Layout reads headers() to opt out of static rendering"

**Location:** commit 9b4e453 message (also echoed by d90d6bb's message: "headers() is called to opt out of static rendering")
**Type:** Staleness signal (commit message vs current code)
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** future archaeologist

True when written, superseded by 99e1229's R4: the layout no longer calls `headers()`; static rendering is now opted out via `export const dynamic = "force-dynamic"` (app/layout.tsx:26). Expected staleness for a commit message — flagged only so history readers know the mechanism changed.

**Evidence:**
- `- Layout reads headers() to opt out of static rendering` — commit 9b4e453 message.
- `export const dynamic = "force-dynamic";` — app/layout.tsx:26; no `headers()` in the file.

## Claim 23: commit d90d6bb — "No behavior change; CSP directives preserved exactly. Lint clean; 221/221 tests pass."

**Location:** commit d90d6bb message
**Type:** Verification claim (historical)
**Verdict:** Unverifiable
**Confidence:** Low
**Legibility-target:** future archaeologist

The "221/221 tests pass" count applies to the tree at d90d6bb, which I did not execute (only HEAD was run). The number is arithmetically consistent with HEAD's verified 234 minus the 13 tests added by 99e1229 (8 + 5), and the diff d90d6bb..99e1229 shows the directive list unchanged, but the historical test run itself cannot be confirmed from this state.

**Evidence:**
- `221/221 tests pass.` — commit d90d6bb message.
- 234 − 13 = 221 — paraphrased arithmetic from the verified HEAD test run and new-test counts; no quote available because it is a derived calculation.

## Claims Requiring Attention

1. **Claim 10 (Incorrect, High)** — proxy.ts:35-36: the comment says Next proxy runs in the Edge runtime; Next 16's own tooling states "Proxy always runs on Node.js runtime." Code behavior is unaffected (both APIs exist in Node), but the comment misdirects runtime debugging. One-line fix.
2. **Claim 8 (Incorrect, Medium)** — proxy.ts:12: "Tailwind v4 emits inline styles" misattributes why `style-src 'unsafe-inline'` is needed; the correct rationale already exists at proxy.test.ts:60-61 (React style attributes, reactflow transforms, KaTeX). Copy it over.
3. **Claim 21 (Incorrect, High)** — commit 9b4e453's "Next applies the nonce to every `<script>` tag" is refuted by the pre-fix wiring and by 99e1229's R1 paragraph. Immutable history; no action possible beyond awareness.
4. **Claim 9 (Mostly accurate, High)** — proxy.ts:16: "OpenAlex" names an integration that does not exist anywhere in the codebase. The substantive sufficiency claim now holds on this state.
5. **Claim 17 (Mostly accurate, Medium)** — the "silently breaks graph layout and equation sizing" consequence is asserted, not tested; fine as a comment, noted for calibration.

## Goal-Alignment Note
- Answered: All 7 items in the shared brief. (1) Request-header CSP wiring verified against Next's app-render source — the nonce now reaches where Next reads it; both header writes match their claimed purposes. (2) dataUrlToBlob decode logic verified (base64 byte-exact; percent-encoded branch correct for text, with an unclaimed binary edge noted); both call sites converted; no data:-URL fetch remains in app/. (3) All 8 proxy tests match their names; the x-middleware-request-* observation mechanism matches Next's encoder; the CSP-forwarding assertion demonstrably fails against d90d6bb's wiring. (4) force-dynamic mechanism and clean headers() removal confirmed. (5) connect-src 'self' re-enumerated on this state — now sufficient; OpenAlex phantom remains. (6) Commit 99e1229's fix list, test count (234, reproduced), and falsifiability claim all verified. (7) Remaining carried defects: Edge-runtime comment (Incorrect), Tailwind style-src rationale (Incorrect), feature-commit prod-build nonce claim (Incorrect, historical); the old x-nonce-forwarding comment from the feature state was already removed by the fix commit.
- Out of scope: whether the CSP policy itself is the *right* policy (security judgment — critic territory); the untested binary percent-encoded data-URL edge (no claim covers it); rollout questions (Report-Only) explicitly declined by the commit.
- Escalate: nothing blocking. The three Incorrect findings are comment/history accuracy issues, not behavior defects; suggest the security critic confirm the style-src and connect-src reasoning independently rather than trusting proxy.ts's stated rationales.
