# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree /workspace/runs/review-arms/e3-loops/wt-csp-arm2, branch e3/csp-arm2)
**Scope:** `git diff d86d2dc..HEAD` — commits 9b4e453, b25e939, d90d6bb (feature: strict CSP with per-request nonces) plus fix commit 99e1229 (iteration-1 blocker fixes R1–R4). Files: proxy.ts, proxy.test.ts, app/layout.tsx, app/lib/utils/exportGraph.ts, app/lib/utils/exportGraph.test.ts, plus commit-message claims.
**Checked:** 2026-08-06, against the worktree at HEAD with installed node_modules (next 16.2.4); test suite, tsc, and lint executed live by each replicate. This report is a mechanical merge of three independent replicate reports (most-severe verdict wins per cluster).
**Commit:** 99e1229
**Replication:** k=3
**Total claims checked:** 20 (merged clusters; replicates individually checked 16 / 23 / 18 claims)
**Summary:** All three replicates agree the iteration-1 fix commit's claims hold: the CSP is now set on the forwarded request headers where Next 16 actually reads the nonce (confirmed in Next's app-render source), both `fetch(dataUrl)` call sites are replaced by a correct in-process decoder, the new request-forwarding test genuinely fails against the pre-fix wiring, and every stated verification figure (26 files / 234 tests, tsc clean, lint 2 pre-existing warnings in app/page.tsx) reproduces exactly. Merged findings requiring attention: 3 Incorrect — the "Tailwind v4 emits inline styles" style-src rationale in proxy.ts (the accurate rationale is in proxy.test.ts; the two now contradict), the "Edge runtime" claim in proxy.ts (Next 16 proxy always runs on Node.js), and the feature commit 9b4e453's "Next applies the nonce to every `<script>` tag" verification claim (refuted by the R1 mechanism); 1 Stale (feature commit's "layout reads headers()" superseded by force-dynamic); 5 Mostly accurate (phantom OpenAlex in the connect-src enumeration, x-nonce protecting a nonexistent consumer, GIF fixture media-type looseness, untested style-src breakage consequence, "KaTeX trust:false" being a library default rather than a project setting); 1 Unverifiable (d90d6bb's historical 221/221 test run).

## Claim 1: layout.tsx — force-dynamic rationale and nonce-from-request-CSP mechanism

**Location:** app/layout.tsx:21-26
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Future maintainers deciding whether the rendering-mode switch can be removed or scoped down.
**Replicate verdicts:** r1: Verified · r2: Verified (as its Claims 1+2) · r3: Verified (as its Claims 1+2)

The comment claims every route must render per request (a prerendered document would bake in one nonce), and that "Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) and stamps it onto the bootstrap `<script>` tags it emits, so nothing here reads it directly." All parts check out. `export const dynamic = "force-dynamic"` (app/layout.tsx:26) is Next's documented route-segment config forcing per-request rendering for all routes under the root layout. The nonce source is confirmed in Next 16.2.4's own render path: `const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];` followed by `const nonce = ... getScriptNonceFromHeader(csp)` (node_modules/next/dist/server/app-render/app-render.js:166-167), where the `headers` are the incoming request headers; proxy.ts sets that request header (`requestHeaders.set("Content-Security-Policy", csp);`). "Nothing here reads it directly" is accurate — the file has no `headers()` call, no `next/headers` import, and no x-nonce read (rg for "x-nonce" under app/ is empty; only proxy.ts and proxy.test.ts touch it); the fix commit's diff shows the old `import { headers } from "next/headers";` and `await headers();` removed with no dangling references.

**Evidence:** app/layout.tsx:1-27 (imports are only Metadata type, fonts, CSS); node_modules/next/dist/server/app-render/app-render.js:166-167, 1143; node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:12-24; proxy.ts:46-47; 99e1229 diff of app/layout.tsx; rg "x-nonce" app/ (empty).

## Claim 2: exportGraph.ts — code-splitting rationale

**Location:** app/lib/utils/exportGraph.ts:1-4
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Maintainers tempted to import this module statically from eagerly-loaded code.
**Replicate verdicts:** r1: Verified · r2: not checked · r3: not checked

"Separated for code-splitting since html-to-image is only needed when exporting the React Flow graph." Both entry paths into this module are dynamic: `await import("@/app/lib/utils/exportGraph")` (app/components/panels/GraphPanel.tsx:102), and while `app/lib/utils/exportAll.ts:10` imports it statically, exportAll is itself loaded dynamically (`await import("@/app/lib/utils/exportAll")`, app/page.tsx:576). So html-to-image stays out of the initial bundle, as claimed.

**Evidence:** app/lib/utils/exportGraph.ts:6; app/components/panels/GraphPanel.tsx:102; app/lib/utils/exportAll.ts:10; app/page.tsx:576.

## Claim 3: exportGraph.ts — dataUrlToBlob docstring, decoder correctness, and call-site replacement

**Location:** app/lib/utils/exportGraph.ts:16-44, 54, 65
**Type:** Behavioral / configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewers checking the R2 fix; anyone tempted to revert to `fetch(dataUrl)`.
**Replicate verdicts:** r1: Verified · r2: Verified (as its Claims 3+4) · r3: Verified

The docstring claims `fetch(dataUrl)` is a `connect-src` fetch and the app's `connect-src 'self'` refuses `data:` — correct CSP-spec behavior (`fetch()` is governed by connect-src; `'self'` matches the document origin only, never the `data:` scheme), and the policy does set `connect-src 'self'` (proxy.ts). The decoder is correct: the base64 branch (`header.endsWith(";base64")`) decodes via `atob` + `charCodeAt` into a `Uint8Array`, preserving arbitrary bytes; the non-base64 branch applies `decodeURIComponent` per RFC 2397; the media type strips `;base64` and parameters via `.split(";")[0]` with an `application/octet-stream` fallback; non-`data:` inputs throw. All five behaviors are pinned by tests (exportGraph.test.ts:9-39, including a non-UTF-8 byte round-trip `//79` → `[0xff, 0xfe, 0xfd]`). Both call sites now use it: `triggerDownload(dataUrlToBlob(dataUrl), filename);` and `return dataUrlToBlob(dataUrl);`. A repo grep confirms no `fetch(` of a data: URL remains anywhere under app/ — every remaining client-side fetch targets a relative `/api/...` path. One unclaimed edge noted by r2: the non-base64 branch UTF-8-encodes the decoded string via `new Blob([string])`, which would mangle percent-encoded *binary* payloads — but no comment or test claims byte fidelity for that branch, and both real call sites pass base64 PNG data URLs.

**Evidence:** app/lib/utils/exportGraph.ts:19-44, 54, 65; proxy.ts:26-27; app/lib/utils/exportGraph.test.ts:9-39; rg "fetch\(" app/ (all hits /api-relative, server-side OPENROUTER_API_URL, or this docstring's own mention).

## Claim 4: exportGraph.test.ts — test names/comments match assertions; GIF fixture comment

**Location:** app/lib/utils/exportGraph.test.ts:9-39
**Type:** Reference / behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Reviewers auditing whether the R2 test coverage is what it says it is.
**Replicate verdicts:** r1: Verified · r2: Verified · r3: Mostly accurate — most severe wins

All five tests assert what their names claim (byte preservation, percent-decoding, media-type parameter dropping, non-data: rejection), and all pass in the live run. The fixture comment "1x1 transparent GIF — the shape toPng returns (base64 image data URL)" is internally correct — the fixture is a genuine GIF (asserted bytes `[0x47, 0x49, 0x46, 0x38, 0x39, 0x61]` = "GIF89a" plus trailer `0x3b`) and `toPng` does return a base64 image data URL. Docked to Mostly accurate (r3): `toPng` returns a `data:image/png;base64,...` URL, not a GIF — the parenthetical scopes the claim to the *shape*, which the fixture matches, but the fixture's media type differs from the production one. Minor looseness only.

**Evidence:** app/lib/utils/exportGraph.test.ts:10-19; app/lib/utils/exportGraph.ts:47-53 (`toPng(...)` produces the dataUrl passed to the decoder); vitest run output "Tests 234 passed (234)".

## Claim 5: proxy.ts — "Next.js 16 renamed Middleware → Proxy"

**Location:** proxy.ts:5
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Developers looking for a middleware.ts and not finding one.
**Replicate verdicts:** r1: Verified · r2: Verified · r3: Verified

package.json pins `"next": "16.2.4"`. The installed Next has first-class proxy-file support — `const PROXY_FILENAME = 'proxy';` (node_modules/next/dist/lib/constants.js:289) — and its error/deprecation text references the rename directly: "Learn more: https://nextjs.org/docs/messages/middleware-to-proxy" (node_modules/next/dist/build/analysis/get-page-static-info.js:576; also the middleware-filename warnOnce in next/dist/build/index.js).

**Evidence:** package.json (`"next": "16.2.4"`); node_modules/next/dist/lib/constants.js:289-290; node_modules/next/dist/build/analysis/get-page-static-info.js:576.

## Claim 6: proxy.ts — nonce + 'strict-dynamic' semantics

**Location:** proxy.ts:7-10
**Type:** Behavioral (spec)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Security reviewers evaluating the XSS posture.
**Replicate verdicts:** r1: Verified (Medium) · r2: Verified (Medium) · r3: Verified (High)

"Only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust. This keeps a hypothetical injected `<script>` tag from executing." Accurate CSP3 `'strict-dynamic'` semantics (paraphrased — spec behavior, not repo code): with `script-src 'self' 'nonce-X' 'strict-dynamic'` (proxy.ts:22-23), nonced scripts execute, scripts they programmatically create inherit trust, parser-inserted injected scripts without the nonce are refused, and host/`'self'` sources are ignored. Unlike the pre-fix state, the premise "scripts that Next.js has tagged with the nonce" now obtains — see Claims 1 and 10.

**Evidence:** proxy.ts:7-10, 20-31 (buildCsp directive list); mechanism wiring per Claims 1 and 10.

## Claim 7: proxy.ts — "Tailwind v4 emits inline styles" rationale for style-src 'unsafe-inline'

**Location:** proxy.ts:12-15
**Type:** Behavioral / configuration
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** Anyone deciding whether the `'unsafe-inline'` carve-out can be tightened, and what would break.
**Replicate verdicts:** r1: Incorrect (Medium) · r2: Incorrect (Medium) · r3: Incorrect (Medium)

"Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR." The carve-out itself is genuinely needed, but the stated mechanism is wrong: Tailwind v4 runs through `@tailwindcss/postcss` (package.json devDependency) and compiles `app/globals.css` (imported at app/layout.tsx:3) into a stylesheet Next serves as a linked `.css` file — allowed by `style-src 'self'`, no `'unsafe-inline'` required for Tailwind's own output. The actual consumers are the set named by the test file's own comment: "Required by React style={} attributes, reactflow's inline transforms and KaTeX" (proxy.test.ts:60-61) — inline `style` attributes fall under `style-src` (via style-src-attr fallback) and cannot be nonced at all; r3 confirmed `style={}` usage is widespread in the app's own components (GraphPanel.tsx, NodeDetailPanel.tsx, ArtifactPanelShell.tsx, SemiformalPanel.tsx, OutputPanel.tsx, and others) — plus dev-mode `<style>` injection (Next/HMR behavior, not Tailwind). The repo now carries two contradictory rationales for the same directive; the test file's is the accurate one. Carried from the feature commit (9b4e453); the fix commit did not claim to correct it ("Amber and green findings are out of scope for this pass and remain open," commit 99e1229).

**Evidence:** proxy.ts:12-15, 23; package.json (`"@tailwindcss/postcss"`); app/layout.tsx:3; proxy.test.ts:59-65; rg `style=\{` over app/ (multiple components); commit 99e1229 message scope statement.

## Claim 8: proxy.ts — "connect-src 'self' is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server"

**Location:** proxy.ts:16-17
**Type:** Configuration / invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Reviewers checking whether the CSP will break any client-side network call.
**Replicate verdicts:** r1: Mostly accurate · r2: Mostly accurate · r3: Mostly accurate

The substantive claim is now true on this state. All three replicates independently re-enumerated client-side network initiations under app/: every browser-side `fetch` targets a relative same-origin path — `/api/analytics` (app/hooks/useAnalytics.ts:11,30), `/api/verification/lean` (app/lib/formalization/api.ts:104, plus relative-URL wrappers at :10,:38), `/api/refine/context` (ContextInput.tsx:25), `/api/explanation/lean-error` (LeanCodeDisplay.tsx:88). No `EventSource`/`WebSocket`/`XMLHttpRequest`/`sendBeacon` usage exists under app/ (rg, zero hits). External calls are server-side only: `fetch(OPENROUTER_API_URL, ...)` in app/lib/llm/callLlm.ts:164 and streamLlm.ts:249, imported exclusively by API routes and artifactRoute.ts (itself imported by API routes); the Lean verifier call is inside app/api/verification/lean/route.ts:21; `@anthropic-ai/sdk` is imported only in callLlm.ts. The former violator — `fetch(dataUrl)` — is gone (Claim 3). r3 additionally confirmed fonts are self-hosted via `next/font/google` and pdf.js workers are same-origin module URLs. The inaccuracy keeping this below Verified: **OpenAlex appears nowhere in the repository outside this comment** (repo-wide case-insensitive rg: sole hit is proxy.ts:16). The enumeration names a third-party integration that does not exist.

**Evidence:** proxy.ts:16-17, 26-27; rg "fetch(" app/ full listing; app/lib/llm/callLlm.ts:7,164; app/lib/llm/streamLlm.ts:249; app/lib/formalization/artifactRoute.ts:2-4; app/api/verification/lean/route.ts:21; rg -i "openalex" repo-wide (empty outside proxy.ts:16).

## Claim 9: proxy.ts — "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in"

**Location:** proxy.ts:35-36
**Type:** Configuration / runtime
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Maintainers reasoning about what APIs the proxy may use.
**Replicate verdicts:** r1: Incorrect (High) · r2: Incorrect (High) · r3: Stale (High) — most severe wins

Next 16 proxy does not run in the Edge runtime. The installed Next 16.2.4 is explicit — and treats Edge as not even configurable for proxy files: "Route segment config is not allowed in Proxy file at ... **Proxy always runs on Node.js runtime.** Learn more: https://nextjs.org/docs/messages/middleware-to-proxy" (node_modules/next/dist/build/analysis/get-page-static-info.js:576), and the build forces it: `if (staticInfo.runtime === 'nodejs' || (0, _utils1.isProxyFile)(page)) { ... runtime: 'nodejs',` (node_modules/next/dist/build/index.js:1515-1519). The practical conclusion the comment supports is unaffected — `crypto.randomUUID` and `Buffer` are both available in Node.js — so the code works; only the runtime identification is wrong, reflecting the pre-Next-16 middleware-on-Edge world, and would misdirect anyone debugging runtime-availability issues. Carried unchanged from the feature commit (present verbatim in `git show d90d6bb:proxy.ts`); the fix commit did not claim to correct it.

**Evidence:** proxy.ts:34-37; node_modules/next/dist/build/analysis/get-page-static-info.js:576; node_modules/next/dist/build/index.js:1515-1519; commit 99e1229 message scope statement.

## Claim 10: proxy.ts — request-header CSP forwarding comment (the R1 mechanism)

**Location:** proxy.ts:41-45
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** The whole point of the fix — reviewers must be able to trust this wiring description.
**Replicate verdicts:** r1: Verified · r2: Verified · r3: Verified

"Next.js reads the nonce off the *request* `Content-Security-Policy` header during render and stamps it onto the bootstrap `<script>` tags it emits. Setting it only on the response is not enough: under 'strict-dynamic' the 'self' source is ignored, so un-nonced bootstrap scripts are refused and the app never hydrates. Both headers must carry the same policy." Three sub-claims, all verified. (1) Request-side read: node_modules/next/dist/server/app-render/app-render.js:166-167 (quoted at Claim 1); the code delivers it via `requestHeaders.set("Content-Security-Policy", csp);` then `NextResponse.next({ request: { headers: requestHeaders } })`. r3 additionally traced the full delivery path: the encoding as `x-middleware-request-*` headers (next/dist/server/web/spec-extension/response.js:36-39) and the server-side unpack before render (next/dist/server/lib/router-utils/resolve-routes.js:396-411). (2) `'strict-dynamic'` ignoring `'self'`: CSP3 spec behavior (paraphrased), so response-only CSP with un-nonced bootstrap scripts would block hydration. (3) Same policy on both: the identical `csp` string is set on request and response, and the test pins equality (`expect(forwarded).toBe(response.headers.get("Content-Security-Policy"))`).

**Evidence:** proxy.ts:39-56; node_modules/next/dist/server/app-render/app-render.js:160-167; node_modules/next/dist/server/web/spec-extension/response.js:25-40; node_modules/next/dist/server/lib/router-utils/resolve-routes.js:396-411; proxy.test.ts:78-89.

## Claim 11: proxy.ts — x-nonce overwrite comment

**Location:** proxy.ts:48-50
**Type:** Behavioral / security
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Security reviewers assessing header-smuggling exposure.
**Replicate verdicts:** r1: Mostly accurate · r2: Verified · r3: Verified — most severe wins

"Overwrite (not append) so a client-supplied x-nonce cannot be smuggled through to a server component." The mechanism is correct: `Headers.set` replaces any existing value (WHATWG Headers semantics), and the behavior is pinned by a test that sends `"x-nonce": "attacker-controlled"` and asserts the forwarded value does not contain it (proxy.test.ts:97-108). The caveat docking this to Mostly accurate (r1): **no server component reads x-nonce** — a repo grep for "x-nonce" under app/ returns zero hits; the only writers/readers are proxy.ts and proxy.test.ts. The protected consumer is hypothetical, so the comment describes a defensive invariant for currently dead wiring (the nonce actually reaches Next via the CSP request header per Claim 10, not via x-nonce). Not wrong as a precaution — r2 and r3 noted the same fact without docking — but a reader would reasonably infer a consumer exists.

**Evidence:** proxy.ts:48-50; proxy.test.ts:97-108; rg "x-nonce" app/ (zero hits).

## Claim 12: proxy.ts — matcher comment

**Location:** proxy.ts:59-62
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Anyone changing the matcher and needing to know what's deliberately excluded.
**Replicate verdicts:** r1: Verified (Medium) · r2: Verified (High) · r3: Verified (High)

"Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)." The config matches: the source regex negative-lookaheads `api|_next/static|_next/image|favicon.ico` (proxy.ts:63-65), and the `missing` conditions exclude requests carrying `next-router-prefetch` or `purpose: prefetch` headers (proxy.ts:64-69) — the standard Next matcher pattern for skipping prefetches. r1 notes the matcher is consumed by the framework at build/route time and not exercised by the unit tests, so the claim rests on Next's documented matcher semantics rather than an executed check.

**Evidence:** proxy.ts:59-72.

## Claim 13: proxy.test.ts — x-middleware-request-* observation-mechanism docstring

**Location:** proxy.test.ts:5-12
**Type:** Reference / behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Future maintainers when a Next upgrade breaks these tests.
**Replicate verdicts:** r1: Verified (High) · r2: Verified (Medium) · r3: Verified (High)

"`NextResponse.next({ request: { headers } })` cannot expose the forwarded request headers directly — Next encodes them onto the response as `x-middleware-request-<lowercased-name>`, with the overridden names listed in `x-middleware-override-headers`, and unpacks them before render." Confirmed against the installed Next 16.2.4: `headers.set('x-middleware-request-' + key, value);` and `headers.set('x-middleware-override-headers', keys.join(','));` (node_modules/next/dist/server/web/spec-extension/response.js:34-39, `handleMiddlewareField`); the unpack side confirmed by r3 at node_modules/next/dist/server/lib/router-utils/resolve-routes.js:396-411. Lowercasing holds because `Headers` iteration yields normalized lowercase names. The helper `forwardedRequestHeader` (proxy.test.ts:13-22) reads exactly this encoding, including the override-list membership check. The "only way to assert from a unit test" framing is a judgment about the test-observability boundary rather than a checkable code fact, but no alternative observable exists on the `NextResponse` surface, and the commit message honestly flags the coupling ("would need updating if Next changes that encoding," 99e1229 Notes).

**Evidence:** proxy.test.ts:5-22; node_modules/next/dist/server/web/spec-extension/response.js:25-40; node_modules/next/dist/server/lib/router-utils/resolve-routes.js:396-411; commit 99e1229 Notes section.

## Claim 14: proxy.test.ts — test names match assertions; the request-forwarding test falsifies the R1 wiring

**Location:** proxy.test.ts:32-114 (8 tests); commit 99e1229 R3 ("That last assertion fails against the pre-R1 wiring, so the nonce-delivery belief is now falsifiable")
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewers deciding whether the R3 tests actually protect the R1 fix.
**Replicate verdicts:** r1: Verified · r2: Verified (as its Claims 15+16) · r3: Verified

All 8 tests assert what their names claim: exact 9-directive set (matching buildCsp one-for-one), nonce + `'strict-dynamic'` on script-src, style-src carve-out, CSP on the response, CSP forwarded on the request, x-nonce/policy-nonce consistency, overwrite-not-append via an attacker-controlled inbound header, and per-request freshness via two runs producing different policies (sound because each call generates a new `crypto.randomUUID()` nonce). The falsifiability claim checked statically against the pre-fix wiring: at d90d6bb, proxy.ts forwarded only x-nonce — `requestHeaders.set("x-nonce", nonce);` with the CSP set solely on the response (`git show d90d6bb:proxy.ts`) — so `content-security-policy` would never appear in `x-middleware-override-headers`, `forwardedRequestHeader(response, "content-security-policy")` would return null (proxy.test.ts:20), and `expect(forwarded).not.toBeNull()` fails. The test genuinely discriminates the broken wiring from the fixed one. r3's scope note: from a unit test it cannot falsify a hypothetical change in *Next's* render-side read; that residual is acknowledged in the commit's Notes.

**Evidence:** proxy.test.ts:13-22, 32-114; git show d90d6bb:proxy.ts lines 41-47; proxy.ts:21-37, 46-55; node_modules/next/dist/server/web/spec-extension/response.js:25-40.

## Claim 15: proxy.test.ts — style-src carve-out test comment

**Location:** proxy.test.ts:59-61
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** Whoever eventually tries to remove `'unsafe-inline'`.
**Replicate verdicts:** r1: Verified (Medium) · r2: Mostly accurate (Medium) · r3: not separately verdicted (endorsed within its Claims 7/14) — most severe wins

"Required by React style={} attributes, reactflow's inline transforms and KaTeX; removing it silently breaks graph layout and equation sizing." The named consumers exist: `reactflow: ^11.11.4`, `katex: ^0.16.45`, `rehype-katex: ^7.0.1` (package.json); reactflow positions its viewport/nodes via inline `style` transforms and KaTeX emits inline style attributes for sizing — both fall under `style-src` (no `style-src-attr` is declared, so `style-src` governs attributes too) and inline style attributes cannot be nonce-whitelisted. This is the accurate version of the rationale that proxy.ts:12-14 gets wrong (Claim 7). Docked to Mostly accurate (r2): the specific breakage claim ("silently breaks graph layout and equation sizing") is asserted, not demonstrated by any test, and the CSP-attr mechanics rest on paraphrased spec behavior.

**Evidence:** proxy.test.ts:59-65; package.json dependency entries; proxy.ts:23.

## Claim 16: Commit 99e1229 message — R1–R4 dispositions and verification figures

**Location:** commit 99e1229 (message body)
**Type:** Behavioral / configuration / reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** The review loop itself — whether the fix commit's self-report can be trusted.
**Replicate verdicts:** r1: Verified · r2: Verified (as its Claims 18+19+20) · r3: Verified (as its Claims 15+16)

Checked line by line by all three replicates. **R1** "proxy.ts now sets the same policy string on both the forwarded request headers and the response": true — same `csp` local on request and response; mechanism verified in Claim 10. **R2** "replaced both fetch call sites": true — the pre-fix file had exactly two (`const res = await fetch(dataUrl);` at d90d6bb:app/lib/utils/exportGraph.ts:24 and :37), both now `dataUrlToBlob` (Claim 3), with `connect-src 'self'` kept tight rather than widened with `data:`. **R3** "buildCsp is now exported": true — `export function buildCsp` (proxy.ts:19), previously unexported at d90d6bb; the enumerated coverage maps one-to-one onto the 8 tests; falsifiability verified in Claim 14. **R4**: the diff shows `await headers()` and its incorrect comment replaced by `export const dynamic = "force-dynamic"` with a corrected comment that survives R1's correction (Claim 1). **"234 tests pass (was 221)"**: reproduced live by all three replicates — `Test Files 26 passed (26) / Tests 234 passed (234)`; "was 221" is arithmetic-consistent (13 new tests: 8 + 5; 234 − 13 = 221, agreeing with d90d6bb's message), not re-executed at the parent commit. **Verification block**: `npx tsc --noEmit` clean — reproduced; `npm run lint` — reproduced exactly: "✖ 2 problems (0 errors, 2 warnings)", both `react-hooks/exhaustive-deps` in app/page.tsx:209 and :271, a file untouched by the fix commit, so "pre-existing" is accurate. The Notes coupling disclosure matches Claim 13.

**Evidence:** commit 99e1229 message and stat; proxy.ts:19,46-47,55; git show d90d6bb:proxy.ts:19,41-47; git show d90d6bb:app/lib/utils/exportGraph.ts:24,37; proxy.test.ts:33-115; live runs (three independent executions) of `npx vitest run` (26/234), `npx tsc --noEmit` (clean), `npm run lint` (2 warnings, app/page.tsx:209,271).

## Claim 17: Commit 9b4e453 — "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates"

**Location:** commit 9b4e453 (feature commit message)
**Type:** Verification claim (historical)
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Anyone treating the feature commit as evidence the CSP worked pre-fix.
**Replicate verdicts:** r1: not checked · r2: Incorrect (High) · r3: Incorrect (Medium) — most severe wins

The second half of this claim cannot have been true as stated. At 9b4e453 (and through d90d6bb) the CSP was set only on the response, and Next reads the nonce exclusively from the *request* `content-security-policy` header (app-render.js:166-167), so `nonce` was `undefined` during render and Next's scripts were not nonced. The fix commit's own R1 paragraph states this outright: "R1 FIXED — nonce never reached the document. The policy was set only on the response; Next reads the nonce off the *request* Content-Security-Policy header during render." The first half (build emits the CSP response header) is plausible; the "nonce on every `<script>` tag" half is refuted by the wiring. Immutable history; no doc should cite that verification.

**Evidence:** commit 9b4e453 message; commit 99e1229 message (R1 paragraph); node_modules/next/dist/server/app-render/app-render.js:166-167; d90d6bb:proxy.ts (no request-side CSP set).

## Claim 18: Commit 9b4e453 — "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit 9b4e453 (feature commit message)
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Security reviewers assessing whether CSP is guardrail or fix.
**Replicate verdicts:** r1: not checked · r2: not checked · r3: Mostly accurate

`rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw" app` — zero hits; both negatives confirmed. "KaTeX trust:false" overstates slightly: the KaTeX integration sets no `trust` option at all (`import rehypeKatex from "rehype-katex"; ... const rehypePlugins = [rehypeKatex];`, app/components/features/output-editing/LatexRenderer.tsx:6-10) — `trust: false` is KaTeX's *default*, not something this codebase configures. The security posture claimed is real; the phrasing implies an explicit setting that does not exist, and a future KaTeX upgrade changing the default would silently void the claim.

**Evidence:** rg over app/ (empty for both patterns); app/components/features/output-editing/LatexRenderer.tsx:6-10.

## Claim 19: Commits 9b4e453 / d90d6bb — "Layout reads headers() to opt out of static rendering"

**Location:** commit 9b4e453 message (echoed by d90d6bb's message)
**Type:** Staleness signal (commit message vs current code)
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** Future archaeologists.
**Replicate verdicts:** r1: not checked · r2: Stale · r3: not checked

True when written, superseded by 99e1229's R4: the layout no longer calls `headers()`; static rendering is now opted out via `export const dynamic = "force-dynamic"` (app/layout.tsx:26). Expected staleness for a commit message — flagged only so history readers know the mechanism changed.

**Evidence:** commit 9b4e453 message; app/layout.tsx:26; no `headers()` in the file.

## Claim 20: Commit d90d6bb — "No behavior change; CSP directives preserved exactly. Lint clean; 221/221 tests pass."

**Location:** commit d90d6bb message
**Type:** Verification claim (historical)
**Verdict:** Unverifiable
**Confidence:** Low
**Legibility-target:** Future archaeologists.
**Replicate verdicts:** r1: not checked · r2: Unverifiable · r3: not separately verdicted (parenthetically endorsed the "no behavior change" half)

The "221/221 tests pass" count applies to the tree at d90d6bb, which no replicate executed (only HEAD was run). The number is arithmetically consistent with HEAD's verified 234 minus the 13 tests added by 99e1229 (8 + 5), and the diff d90d6bb..99e1229 shows the directive list unchanged (r3: that commit only inlined a local and edited comments), but the historical test run itself cannot be confirmed from this state.

**Evidence:** commit d90d6bb message; 234 − 13 = 221 (derived from the verified HEAD run and new-test counts); git show d90d6bb --stat.

## Claims Requiring Attention

**Incorrect:**
- **Claim 7** (proxy.ts:12-15, Incorrect/Medium, 3/3 replicates agree): "Tailwind v4 emits inline styles" is the wrong reason for `style-src 'unsafe-inline'` — Tailwind v4 output is a linked stylesheet under this setup; the real dependents are React `style={}` attributes, reactflow transforms, KaTeX, and dev-mode style injection. The accurate rationale already exists in the same PR at proxy.test.ts:60-61; the two contradict each other. Carried from the feature commits; outside the fix commit's declared scope. Align proxy.ts with the test file.
- **Claim 9** (proxy.ts:35-36, Incorrect/High, 2/3 Incorrect + 1 Stale): "the Edge runtime that Next proxy runs in" — Next 16 proxy always runs on the Node.js runtime (Next's own build error says so verbatim). The APIs named are available either way, so behavior is unaffected; only the runtime identification is wrong. One-line comment fix; also carried from the feature commits.
- **Claim 17** (commit 9b4e453 message, Incorrect/High, 2/2 replicates that checked): "Verified prod build ... Next applies the nonce to every `<script>` tag" cannot have been true given the R1 mechanism; contradicted by 99e1229's own R1 paragraph. Immutable history — no action possible beyond not citing that verification.

**Stale:**
- **Claim 19** (commits 9b4e453/d90d6bb messages): "Layout reads headers() to opt out of static rendering" — superseded by R4's `force-dynamic`. Expected commit-message staleness; awareness only.

**Mostly accurate (minor drift):**
- **Claim 8** (proxy.ts:16-17, 3/3 agree): the `connect-src 'self'` sufficiency claim now holds on this state, but the comment names OpenAlex, which appears nowhere in the repository. Drop it from the enumeration.
- **Claim 11** (proxy.ts:48-50): overwrite semantics correct and tested, but no server component reads x-nonce — the protected consumer is hypothetical dead wiring.
- **Claim 4** (exportGraph.test.ts:10): the GIF fixture matches the *shape* toPng returns (base64 image data URL) but not its media type (PNG). Minor looseness.
- **Claim 15** (proxy.test.ts:59-61): the "silently breaks graph layout and equation sizing" consequence is asserted, not tested; fine as a comment, noted for calibration.
- **Claim 18** (commit 9b4e453 message): "KaTeX trust:false" is the library default, not an explicit project setting; a future KaTeX upgrade changing the default would silently void the claim.

## Verdict stability

- **Clusters:** 20 total. 14 checked by all 3 replicates; 2 checked by 2 replicates (Claims 15, 17); 4 checked by 1 replicate (Claims 2, 18, 19, 20).
- **Merged verdict counts:** 10 Verified, 5 Mostly accurate, 3 Incorrect, 1 Stale, 1 Unverifiable.
- **Agreement rate:** 16/20 clusters (80%) had unanimous verdicts among the replicates that checked them.
- **Disagreements (4):**
  - **Claim 4** (exportGraph.test.ts fixture): r1 Verified, r2 Verified, r3 Mostly accurate → merged Mostly accurate. r3 docked for the GIF-vs-PNG media-type looseness r1/r2 treated as adequately scoped by the comment's parenthetical.
  - **Claim 9** (Edge runtime): r1 Incorrect (High), r2 Incorrect (High), r3 Stale (High) → merged Incorrect (High). Same finding, same evidence; r3 classified it as outdated-world drift rather than error. No factual disagreement.
  - **Claim 11** (x-nonce overwrite): r1 Mostly accurate, r2 Verified, r3 Verified → merged Mostly accurate. All three found the identical fact (no consumer of x-nonce exists); they differed only on whether that docks the verdict.
  - **Claim 15** (style-src test comment): r1 Verified, r2 Mostly accurate (r3 no separate verdict) → merged Mostly accurate. r2 docked for the untested breakage consequence.
- All four disagreements are severity-calibration differences on shared evidence, not conflicting findings; no replicate contradicted another on any underlying fact.

## Goal-Alignment Note
- Answered: All 7 brief items were checked by all three replicates against the current state: (1) request-header CSP wiring → Claims 1, 10 (Verified; mechanism confirmed in Next 16.2.4 source, including — r3 — the full x-middleware encode/unpack delivery path); (2) dataUrlToBlob decode + call sites + no residual data:-fetch → Claim 3 (Verified; unclaimed binary edge in the non-base64 branch noted); (3) proxy.test.ts names/comments vs assertions incl. falsifiability and the x-middleware mechanism → Claims 13, 14, 15 (Verified/Verified/Mostly accurate); (4) layout force-dynamic comment and clean headers() removal → Claim 1 (Verified); (5) connect-src re-enumeration on this state → Claim 8 (Mostly accurate — OpenAlex phantom only); (6) commit 99e1229 claims incl. three independent live reproductions of 26 files / 234 tests, tsc clean, lint 2 pre-existing warnings → Claim 16 (Verified; "was 221" arithmetic-consistent, not re-executed); (7) carried-over stale comments → Claims 7, 9 (Incorrect), 11 (Mostly accurate), plus r2/r3's history findings (Claims 17-20).
- Out of scope: whether the remaining Incorrect comments *should* have been fixed in this pass (the commit explicitly scoped them out); whether the CSP policy itself is the right security posture (critic territory); browser-level end-to-end confirmation that hydration succeeds under the enforced policy (unit + internals evidence only — the residual gap all three replicates flag, acknowledged in the commit's Notes); the untested binary percent-encoded data-URL edge (no claim covers it); rollout questions (Report-Only) explicitly declined by the commit.
- Escalate: Nothing at blocker level, unanimously across replicates. The iteration-1 blockers' fixes all verify against the code, and the fix commit's self-reported verification figures reproduce exactly in three independent runs. The remaining Incorrect items are documentation-accuracy debt: proxy.ts:12-15 and :35-36 are cheap comment-only fixes the next iteration could take, and the repo currently carries two contradictory rationales for the same CSP directive (proxy.ts vs proxy.test.ts) — critics may wish to fold these into an amber finding. Suggest the security critic confirm the style-src and connect-src reasoning independently rather than trusting proxy.ts's stated rationales.
