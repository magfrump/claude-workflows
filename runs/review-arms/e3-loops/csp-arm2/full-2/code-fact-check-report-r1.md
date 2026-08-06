# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree /workspace/runs/review-arms/e3-loops/wt-csp-arm2, branch e3/csp-arm2)
**Scope:** `git diff d86d2dc..HEAD` — commits 9b4e453, b25e939, d90d6bb (feature: strict CSP with per-request nonces) plus fix commit 99e1229 (iteration-1 blocker fixes R1–R4). Files: proxy.ts, proxy.test.ts, app/layout.tsx, app/lib/utils/exportGraph.ts, app/lib/utils/exportGraph.test.ts.
**Checked:** 2026-08-06, against the worktree at HEAD with installed node_modules (next 16.2.4); test suite, tsc, and lint executed live. Prior-iteration report (/workspace/runs/review-arms/e1/csp-dirty/code-fact-check-report-r3.md) used as advisory hints only; every verdict re-derived from the current code.
**Total claims checked:** 16
**Summary:** 12 Verified, 2 Mostly accurate, 2 Incorrect, 0 Stale, 0 Unverifiable. The fix commit's four blocker claims (R1–R4) all check out against the code: the CSP is now set on the forwarded request headers where Next 16 actually reads the nonce (`app-render.js` reads `headers['content-security-policy']` from the request), both `fetch(dataUrl)` call sites are replaced by a correct in-process decoder, the new request-forwarding test genuinely fails against the pre-fix wiring, and the layout's `force-dynamic` comment now describes the real mechanism. Its verification claims (26 files / 234 tests, tsc clean, lint 2 pre-existing warnings) all reproduce exactly. Two comments carried over from the feature commits remain wrong — and the fix commit did not claim to fix them: the Edge-runtime claim in proxy.ts (Next 16 proxy always runs on Node.js) and the Tailwind-emits-inline-styles rationale for `style-src 'unsafe-inline'` (the accurate rationale is the one in proxy.test.ts). The `connect-src` docstring is now substantively correct on this state but still names OpenAlex, which appears nowhere in the app.

**Commit:** 99e1229

## Claim 1: layout.tsx — force-dynamic rationale and nonce mechanism

**Location:** app/layout.tsx:21-26
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Future maintainers deciding whether the rendering-mode switch can be removed or scoped down.

The comment claims: "Every route under this layout must render per request: a statically prerendered HTML document would bake in one nonce and reuse it for every visitor... Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) and stamps it onto the bootstrap `<script>` tags it emits, so nothing here reads it directly" (app/layout.tsx:21-25). All parts check out. `export const dynamic = "force-dynamic"` (app/layout.tsx:26) is Next's documented route-segment config forcing per-request rendering for all routes under the root layout. The nonce-source claim is confirmed in Next 16.2.4's own render path: `const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];` followed by `const nonce = ... getScriptNonceFromHeader(csp)` (node_modules/next/dist/server/app-render/app-render.js:166-167), where `getScriptNonceFromHeader` extracts the nonce from the `script-src` directive (node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:12-24). proxy.ts sets that request header: `requestHeaders.set("Content-Security-Policy", csp);` (proxy.ts:47). "Nothing here reads it directly" is accurate — no `headers()` or `x-nonce` read remains in the file, and the fix commit's diff shows the `import { headers } from "next/headers";` line and the `await headers();` call both removed with no dangling references (git show 99e1229 -- app/layout.tsx: `-import { headers } from "next/headers";` and `-  await headers();`). `npx tsc --noEmit` passes on this state (run live).

**Evidence:** app/layout.tsx:21-26; node_modules/next/dist/server/app-render/app-render.js:166-167; node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:12-24; proxy.ts:47; 99e1229 diff of app/layout.tsx.

## Claim 2: exportGraph.ts — code-splitting rationale

**Location:** app/lib/utils/exportGraph.ts:1-4
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Maintainers tempted to import this module statically from eagerly-loaded code.

"Separated for code-splitting since html-to-image is only needed when exporting the React Flow graph" (app/lib/utils/exportGraph.ts:2-3). Both entry paths into this module are dynamic: `const { getGraphViewportElement, downloadGraphAsPng } = await import("@/app/lib/utils/exportGraph");` (app/components/panels/GraphPanel.tsx:102), and while `app/lib/utils/exportAll.ts:10` imports it statically, exportAll is itself loaded dynamically: `const { exportAllAsZip } = await import("@/app/lib/utils/exportAll");` (app/page.tsx:576). So html-to-image stays out of the initial bundle, as claimed.

**Evidence:** app/lib/utils/exportGraph.ts:6 (`import { toPng } from "html-to-image"`); app/components/panels/GraphPanel.tsx:102; app/lib/utils/exportAll.ts:10; app/page.tsx:576.

## Claim 3: exportGraph.ts — dataUrlToBlob docstring and decode correctness

**Location:** app/lib/utils/exportGraph.ts:16-44
**Type:** Behavioral / configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewers checking the R2 fix; anyone tempted to revert to `fetch(dataUrl)`.

The docstring claims "`fetch(dataUrl)` is the shorter spelling but is a `connect-src` fetch, and the app's CSP sets `connect-src 'self'`, which refuses `data:`" (app/lib/utils/exportGraph.ts:19-21). Paraphrased — no quote available because this is a CSP-spec fact: `fetch()` is governed by `connect-src`, and `'self'` matches the document origin only, never the `data:` scheme, so the pre-fix call would be blocked under this policy. The policy does set `connect-src 'self'` (proxy.ts:26). The decoder itself is correct: the base64 branch (`header.endsWith(";base64")`, app/lib/utils/exportGraph.ts:30) decodes via `atob` + `charCodeAt` into a `Uint8Array` (lines 38-43), which preserves arbitrary bytes; the non-base64 branch applies `decodeURIComponent` (line 36), matching RFC 2397 percent-encoding; the media type strips the `;base64` suffix and any parameters via `.split(";")[0]` with an `application/octet-stream` fallback (lines 31-33); non-`data:` inputs throw (lines 24-27). All five behaviors are pinned by tests (app/lib/utils/exportGraph.test.ts:9-39, including a non-UTF-8 byte round-trip at lines 20-23). Both call sites now use it: `triggerDownload(dataUrlToBlob(dataUrl), filename);` (line 54) and `return dataUrlToBlob(dataUrl);` (line 65). A repo grep confirms no `fetch(` of a data: URL remains anywhere under app/ — every remaining client-side `fetch` targets a relative `/api/...` path, and the only "fetch(dataUrl)" string left is this docstring's own mention (rg "fetch\(" app/).

**Evidence:** app/lib/utils/exportGraph.ts:19-21, 23-44, 54, 65; proxy.ts:26; app/lib/utils/exportGraph.test.ts:9-39; rg "fetch\(" app/ output (all hits are /api-relative, OPENROUTER_API_URL in server-side lib/llm, or this comment).

## Claim 4: exportGraph.test.ts — test comments match assertions

**Location:** app/lib/utils/exportGraph.test.ts:9-39
**Type:** Reference / behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewers auditing whether the R2 test coverage is what it says it is.

Each test name and comment matches its assertion. "1x1 transparent GIF — the shape toPng returns (base64 image data URL)" (app/lib/utils/exportGraph.test.ts:10) — the fixture is a genuine GIF (asserted bytes `[0x47, 0x49, 0x46, 0x38, 0x39, 0x61]` = "GIF89a", line 16, and trailer `0x3b`, line 17), and `toPng` from html-to-image does return a base64 image data URL (it wraps `canvas.toDataURL`), so the fixture is shape-representative even though it's a GIF rather than a PNG. The remaining four tests assert exactly what their names say (byte preservation, percent-decoding, media-type parameter dropping, non-data: rejection). All pass in the live run.

**Evidence:** app/lib/utils/exportGraph.test.ts:9-39; vitest run output "Tests 234 passed (234)".

## Claim 5: proxy.ts — "Next.js 16 renamed Middleware → Proxy"

**Location:** proxy.ts:5
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Developers looking for a middleware.ts and not finding one.

package.json pins `"next": "16.2.4"`. The installed Next build has first-class proxy-file support — `PROXY_FILENAME` / `PROXY_LOCATION_REGEXP` constants (node_modules/next/dist/lib/constants.js:180-184) — and its error text references the rename directly: "Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy" (node_modules/next/dist/build/analysis/get-page-static-info.js:576).

**Evidence:** package.json (`"next": "16.2.4"`); node_modules/next/dist/lib/constants.js:180-184; node_modules/next/dist/build/analysis/get-page-static-info.js:576.

## Claim 6: proxy.ts — nonce + 'strict-dynamic' semantics

**Location:** proxy.ts:7-10
**Type:** Behavioral (spec)
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** Security reviewers evaluating the XSS posture.

"Only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust. This keeps a hypothetical injected `<script>` tag from executing" (proxy.ts:7-10). Paraphrased — no quote available because this is CSP3 spec behavior, not repo code: with `script-src 'self' 'nonce-X' 'strict-dynamic'` (proxy.ts:22), nonced scripts execute, scripts they programmatically create inherit trust, and parser-inserted injected scripts without the nonce are refused. Unlike in the pre-fix state (where the prior iteration found the nonce never reached the document), the premise "scripts that Next.js has tagged with the nonce" now obtains — see Claims 1 and 10. Confidence Medium only because the trust-propagation semantics rest on the spec rather than anything executable here.

**Evidence:** proxy.ts:7-10, 22; mechanism wiring per Claim 1 evidence.

## Claim 7: proxy.ts — "Tailwind v4 emits inline styles" rationale for style-src 'unsafe-inline'

**Location:** proxy.ts:12-14
**Type:** Behavioral / configuration
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** Anyone deciding whether the `'unsafe-inline'` carve-out can be tightened, and what would break.

"Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR" (proxy.ts:12-14). The carve-out itself is genuinely needed, but the stated mechanism is wrong: Tailwind v4 runs through `@tailwindcss/postcss` (package.json devDependency) and compiles `app/globals.css` into a stylesheet that a production Next build serves as a linked `.css` file — allowed by `style-src 'self'`, no `'unsafe-inline'` required for Tailwind's own output. What actually requires `'unsafe-inline'` is the set named by the test file's own comment: "Required by React style={} attributes, reactflow's inline transforms and KaTeX" (proxy.test.ts:60-61) — inline `style` attributes fall under `style-src` (via style-src-attr fallback) and cannot be nonced at all — plus dev-mode `<style>` injection, which is Next/HMR behavior, not Tailwind "emitting inline styles." This comment predates the fix commit (introduced in 9b4e453) and the fix commit did not claim to correct it ("Amber and green findings are out of scope for this pass and remain open," commit 99e1229). The repo now contains two contradictory rationales for the same directive; the test file's is the accurate one.

**Evidence:** proxy.ts:12-14, 23; package.json (`"@tailwindcss/postcss"`); proxy.test.ts:59-65; commit 99e1229 message ("Amber and green findings are out of scope").

## Claim 8: proxy.ts — "connect-src 'self' is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server"

**Location:** proxy.ts:16-17
**Type:** Configuration / invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Reviewers checking whether the CSP will break any client-side network call.

The substantive claim is now true on this state. Re-enumerating client-side network initiations under app/: every browser-side `fetch` targets a relative same-origin path — `/api/analytics` (app/hooks/useAnalytics.ts:11,30), `/api/verification/lean` (app/lib/formalization/api.ts:104), `/api/refine/context` (app/components/features/context-input/ContextInput.tsx:25), `/api/explanation/lean-error` (app/components/features/lean-display/LeanCodeDisplay.tsx:88), plus the relative-URL wrappers in app/lib/formalization/api.ts:10,38. The OpenRouter calls (`OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions"`, app/lib/llm/callLlm.ts:7, used at callLlm.ts:164 and streamLlm.ts:249) are reached only via API routes (app/api/*/route.ts import `l` / `artifactRoute`, which import callLlm/streamLlm — app/lib/formalization/artifactRoute.ts:2-4) — server-to-server, as claimed. The external `LEAN_VERIFIER_URL` fetch is likewise inside an API route (app/api/verification/lean/route.ts:21). No `EventSource`/`WebSocket`/`XMLHttpRequest`/`sendBeacon` usage exists under app/ (rg, zero hits). The former violators — the `fetch(dataUrl)` calls — are gone (Claim 3). The one inaccuracy keeping this below Verified: **OpenAlex appears nowhere in the repository outside this comment** (repo-wide case-insensitive rg for "openalex", excluding node_modules: sole hit is proxy.ts:16). The enumeration names a third-party integration that does not exist.

**Evidence:** proxy.ts:16-17, 26; rg "fetch(" app/ full listing; app/lib/llm/callLlm.ts:7,164; app/lib/llm/streamLlm.ts:249; app/lib/formalization/artifactRoute.ts:2-4; app/api/verification/lean/route.ts:21; rg -i "openalex" repo-wide.

## Claim 9: proxy.ts — "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in"

**Location:** proxy.ts:35-36
**Type:** Configuration / runtime
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** Maintainers reasoning about what APIs the proxy may use.

Next 16 proxy does not run in the Edge runtime. The installed Next 16.2.4 is explicit — and treats Edge as not even configurable for proxy files: "Route segment config is not allowed in Proxy file at ... **Proxy always runs on Node.js runtime.** Learn more: https://nextjs.org/docs/messages/middleware-to-proxy" (node_modules/next/dist/build/analysis/get-page-static-info.js:576). The practical conclusion the comment supports is unaffected — `crypto.randomUUID` and `Buffer` are both available in Node.js — so the code works; only the runtime identification is wrong. This comment was introduced in the feature commits and the fix commit did not claim to correct it (its scope was R1–R4; "Amber and green findings ... remain open"). The prior iteration flagged the same misattribution; it remains on this state.

**Evidence:** proxy.ts:35-37; node_modules/next/dist/build/analysis/get-page-static-info.js:576; commit 99e1229 message scope statement.

## Claim 10: proxy.ts — request-header CSP forwarding comment (the R1 mechanism)

**Location:** proxy.ts:41-45
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** The whole point of the fix — reviewers must be able to trust this wiring description.

"Next.js reads the nonce off the *request* `Content-Security-Policy` header during render and stamps it onto the bootstrap `<script>` tags it emits. Setting it only on the response is not enough: under 'strict-dynamic' the 'self' source is ignored, so un-nonced bootstrap scripts are refused and the app never hydrates. Both headers must carry the same policy" (proxy.ts:41-45). Three sub-claims, all verified. (1) Request-side read: Next's app renderer takes the CSP from the incoming request headers — `const csp = headers['content-security-policy'] || ...; const nonce = ... getScriptNonceFromHeader(csp)` (node_modules/next/dist/server/app-render/app-render.js:166-167, in the same block that reads other request headers like the RSC and prefetch headers at lines 160-165). The code delivers it: `requestHeaders.set("Content-Security-Policy", csp);` then `NextResponse.next({ request: { headers: requestHeaders } })` (proxy.ts:46-54). (2) 'strict-dynamic' ignoring 'self': paraphrased — no quote available because this is CSP3 spec behavior (in the presence of `'strict-dynamic'`, host-source and `'self'` expressions in script-src are ignored by conforming browsers), so response-only CSP with un-nonced bootstrap scripts would indeed block hydration. (3) Same policy on both: the identical `csp` string is set on request (proxy.ts:47) and response (proxy.ts:55), and the test pins equality (proxy.test.ts:85).

**Evidence:** proxy.ts:39-56; node_modules/next/dist/server/app-render/app-render.js:160-167; node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:12-24; proxy.test.ts:78-86.

## Claim 11: proxy.ts — x-nonce overwrite comment

**Location:** proxy.ts:48-50
**Type:** Behavioral / security
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** Security reviewers assessing header-smuggling exposure.

"Overwrite (not append) so a client-supplied x-nonce cannot be smuggled through to a server component" (proxy.ts:48-49). The mechanism is correct: `Headers.set` replaces any existing value (standard Headers semantics), and the behavior is pinned by a test that sends `"x-nonce": "attacker-controlled"` and asserts the forwarded value does not contain it (proxy.test.ts:97-108). The caveat: **no server component reads x-nonce** — a repo grep for "x-nonce" under app/ returns zero hits; the only writers/readers are proxy.ts and proxy.test.ts. The protected consumer is hypothetical, so the comment describes a defensive invariant for a header that is currently dead wiring (the nonce actually reaches Next via the CSP request header per Claim 10, not via x-nonce). Not wrong as a precaution, but a reader would reasonably infer a consumer exists.

**Evidence:** proxy.ts:48-50; proxy.test.ts:97-108; rg "x-nonce" app/ (zero hits).

## Claim 12: proxy.ts — matcher comment

**Location:** proxy.ts:60-62
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** Anyone changing the matcher and needing to know what's deliberately excluded.

"Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches (which would otherwise burn a nonce on a request that may never paint)" (proxy.ts:60-62). The config matches: the source regex negative-lookaheads `api|_next/static|_next/image|favicon.ico` (proxy.ts:65), and the `missing` conditions exclude requests carrying `next-router-prefetch` or `purpose: prefetch` headers (proxy.ts:66-69) — the standard Next matcher pattern for skipping prefetches. Confidence Medium because the matcher is consumed by the framework at build/route time and is not exercised by the unit tests, so the claim rests on Next's documented matcher semantics rather than an executed check.

**Evidence:** proxy.ts:59-72.

## Claim 13: proxy.test.ts — x-middleware-request-* observation-mechanism docstring

**Location:** proxy.test.ts:5-12
**Type:** Reference / behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Future maintainers when a Next upgrade breaks these tests.

"`NextResponse.next({ request: { headers } })` cannot expose the forwarded request headers directly — Next encodes them onto the response as `x-middleware-request-<lowercased-name>`, with the overridden names listed in `x-middleware-override-headers`, and unpacks them before render" (proxy.test.ts:6-10). Confirmed verbatim against the installed Next 16.2.4: `headers.set('x-middleware-request-' + key, value);` (node_modules/next/dist/server/web/spec-extension/response.js:36) and `headers.set('x-middleware-override-headers', keys.join(','));` (response.js:39); the unpacking side lives in the server's middleware adapter path (node_modules/next/dist/server/web/adapter.js, which handles the same header names). The helper `forwardedRequestHeader` (proxy.test.ts:13-22) reads exactly this encoding, including the override-list membership check. The docstring's stronger framing — "the only way to assert from a unit test that the nonce actually reaches the document" — is a judgment about the test-observability boundary rather than a checkable code fact, but it is consistent with the encoding being Next-internal, and the commit message honestly flags the coupling ("would need updating if Next changes that encoding," commit 99e1229).

**Evidence:** proxy.test.ts:5-22; node_modules/next/dist/server/web/spec-extension/response.js:36,39; commit 99e1229 Notes section.

## Claim 14: proxy.test.ts — the request-forwarding test falsifies the R1 wiring

**Location:** proxy.test.ts:78-86 (and commit 99e1229 R3: "That last assertion fails against the pre-R1 wiring, so the nonce-delivery belief is now falsifiable")
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** Reviewers deciding whether the R3 test actually protects the R1 fix.

The test "forwards the same CSP on the request so Next can nonce its scripts" asserts `expect(forwarded).not.toBeNull()` and equality with the response header (proxy.test.ts:84-85), where `forwarded` requires `content-security-policy` to appear in `x-middleware-override-headers` (proxy.test.ts:17-21). Checked statically against the pre-fix wiring: at d90d6bb, proxy.ts forwarded only x-nonce — `requestHeaders.set("x-nonce", nonce);` with the CSP set solely via `response.headers.set("Content-Security-Policy", buildCsp(nonce));` (git show d90d6bb:proxy.ts, lines 41-47) — so the override list would contain only `x-nonce`, `forwardedRequestHeader(response, "content-security-policy")` would return null (proxy.test.ts:20), and the assertion at line 84 fails. The test genuinely discriminates the broken wiring from the fixed one. The companion tests also match their names: x-nonce/policy-nonce consistency (proxy.test.ts:88-95), overwrite-not-append via an attacker-controlled inbound header (97-108), and per-request freshness via two runs producing different policies (110-114, sound because each call generates a new `crypto.randomUUID()` nonce, proxy.ts:37).

**Evidence:** proxy.test.ts:13-22, 78-114; git show d90d6bb:proxy.ts lines 41-47; proxy.ts:37,46-55.

## Claim 15: proxy.test.ts — style-src carve-out test comment

**Location:** proxy.test.ts:59-61
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** Whoever eventually tries to remove `'unsafe-inline'`.

"Required by React style={} attributes, reactflow's inline transforms and KaTeX; removing it silently breaks graph layout and equation sizing" (proxy.test.ts:60-61). The named consumers exist: `reactflow: ^11.11.4`, `katex: ^0.16.45`, `rehype-katex: ^7.0.1` (package.json), and reactflow positions its viewport/nodes via inline `style` transforms while KaTeX emits inline style attributes for sizing — both fall under `style-src` (no `style-src-attr` is declared, so `style-src` governs attributes too, proxy.ts:23), and inline style attributes cannot be nonce-whitelisted. Paraphrased — no quote available because the reactflow/KaTeX inline-style behavior is library behavior verified from the dependency list plus CSP fallback rules, not from repo code. This is the accurate version of the rationale that proxy.ts:12-14 gets wrong (Claim 7).

**Evidence:** proxy.test.ts:59-65; package.json dependency entries; proxy.ts:23.

## Claim 16: Commit 99e1229 message — R1–R4 dispositions and verification figures

**Location:** commit 99e1229 (message body)
**Type:** Behavioral / configuration / reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** The review loop itself — whether the fix commit's self-report can be trusted.

Checked line by line. **R1** "proxy.ts now sets the same policy string on both the forwarded request headers and the response": true — same `csp` local set at proxy.ts:47 (request) and proxy.ts:55 (response); mechanism verified in Claim 10. **R2** "replaced both fetch call sites": true — the pre-fix file had exactly two (`const res = await fetch(dataUrl);` at d90d6bb:app/lib/utils/exportGraph.ts:24 and :37), both now `dataUrlToBlob` (Claim 3). **R3** "buildCsp is now exported": true — d90d6bb had `function buildCsp` (unexported, d90d6bb:proxy.ts:19), now `export function buildCsp` (proxy.ts:19); the enumerated coverage (directive set, nonce on script-src, style-src carve-out, per-request freshness, x-nonce overwrite, request forwarding) maps one-to-one onto the 8 tests in proxy.test.ts:33-115; falsifiability verified in Claim 14. **"234 tests pass (was 221)"**: reproduced live — `Test Files 26 passed (26) / Tests 234 passed (234)` (npx vitest run in the worktree). The "was 221" is arithmetic-consistent: the fix commit adds exactly 13 tests (8 in proxy.test.ts + 5 in exportGraph.test.ts) and 234 − 13 = 221; not re-executed at the parent commit (would require mutating the worktree), hence consistent rather than independently rerun. **R4**: verified in Claim 1 — the diff shows `await headers()` and its incorrect comment replaced by `export const dynamic = "force-dynamic"` with the corrected comment. **Verification block**: `npx tsc --noEmit` clean — reproduced; `npm run lint` — reproduced exactly: "✖ 2 problems (0 errors, 2 warnings)", both `react-hooks/exhaustive-deps` warnings in app/page.tsx:209 and :271, and app/page.tsx is untouched by the fix commit (its stat lists only layout.tsx, exportGraph.{ts,test.ts}, proxy.{ts,test.ts}), so "pre-existing" is accurate. The Notes coupling disclosure matches Claim 13.

**Evidence:** commit 99e1229 message and stat; proxy.ts:19,47,55; git show d90d6bb:proxy.ts:19,41-47; git show d90d6bb:app/lib/utils/exportGraph.ts:24,37; proxy.test.ts:33-115; live runs of `npx vitest run` (26/234), `npx tsc --noEmit` (clean), `npm run lint` (2 warnings in app/page.tsx:209,271).

## Claims Requiring Attention

**Incorrect:**
- **Claim 7** (proxy.ts:12-14): "Tailwind v4 emits inline styles" is the wrong reason for `style-src 'unsafe-inline'` — Tailwind v4 output is a linked stylesheet under this setup; the real dependents are React `style={}` attributes, reactflow transforms, KaTeX, and dev-mode style injection. The accurate rationale already exists in the same PR at proxy.test.ts:60-61; the two contradict each other. Carried from the feature commits; outside the fix commit's declared scope.
- **Claim 9** (proxy.ts:35-36): "the Edge runtime that Next proxy runs in" — Next 16 proxy always runs on the Node.js runtime (Next's own build error says so verbatim). The APIs named are available either way, so behavior is unaffected; only the runtime identification is wrong. Also carried from the feature commits.

**Mostly accurate (minor drift):**
- **Claim 8** (proxy.ts:16-17): the `connect-src 'self'` sufficiency claim now holds on this state, but the comment names OpenAlex, which appears nowhere in the repository.
- **Claim 11** (proxy.ts:48-50): overwrite semantics correct and tested, but no server component reads x-nonce — the protected consumer is hypothetical dead wiring.

## Goal-Alignment Note
- Answered: All 7 brief items were checked against the current state: (1) request-header CSP wiring → Claims 10, 1 (Verified, mechanism confirmed in Next 16.2.4 source); (2) dataUrlToBlob decode + call sites + no residual data:-fetch → Claim 3 (Verified); (3) proxy.test.ts names/comments vs assertions incl. the falsifiability and x-middleware mechanism → Claims 13, 14, 15 (Verified); (4) layout force-dynamic comment and clean headers() removal → Claim 1 (Verified); (5) connect-src re-enumeration on this state → Claim 8 (Mostly accurate — OpenAlex phantom only); (6) commit 99e1229 claims incl. live reproduction of 26 files / 234 tests, tsc, lint → Claim 16 (Verified; "was 221" arithmetic-consistent, not re-executed); (7) carried-over stale comments → Claims 7, 9 (both still Incorrect), 11 (Mostly accurate).
- Out of scope: whether the remaining Incorrect comments *should* have been fixed in this pass (the commit explicitly scoped them out); browser-level end-to-end confirmation that hydration succeeds under the enforced policy (unit-testable surface is covered; a live build/browser check is the residual gap); review-quality judgments (this is a fact-check, not a review).
- Escalate: Nothing at blocker level. The iteration-1 blockers' fixes all verify against the code, and the fix commit's self-reported verification figures reproduce exactly. The two remaining Incorrect items are documentation-accuracy debt (proxy.ts:12-14 and :35-36) that critics may wish to fold into an amber finding, since the repo now carries two contradictory rationales for the same CSP directive.
