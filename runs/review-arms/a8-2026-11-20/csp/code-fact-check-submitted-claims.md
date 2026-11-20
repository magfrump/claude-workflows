Commit: d90d6bb

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (reviewed worktree `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-csp`, detached HEAD d90d6bb)
**Scope:** Stage 2.5 submitted claims only (S1-S7) about the change d86d2dc..d90d6bb (`proxy.ts`, `app/layout.tsx`). No harvested claims; numbering continues from Claim 24 of the merged report.
**Checked:** 2026-11-19
**Total claims checked:** 8 (7 submitted; S3 split into 27a/27b)
**Summary:** 6 verified, 1 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination pattern log: `docs/reviews/hallucination-patterns.md` does not exist in the reviewed repo; no prior patterns to compare against.

Execution environment for executed claims: a scratch copy of the d90d6bb tree made with `git archive d90d6bb` at `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25/app-copy`, with `node_modules` symlinked to `/workspace/external/cc-review-eval/mfc-csp/node_modules` (Next 16.2.4, Node v22.23.2). `proxy.ts` in that copy was confirmed byte-identical to `git show d90d6bb:proxy.ts`. No network access: Google Fonts failed to download, so `next build` was not attempted, and `next dev` pages return 500 because webpack cannot resolve `bluebird`/`mammoth` through the symlink. That failure is environmental and happens after the proxy has run. All probe processes were stopped by PID, and the port was confirmed closed before this report was written.

---

## Submitted Claims

## Claim 25: "The nonce comes from a CSPRNG (`crypto.randomUUID`, 122 random bits) and is regenerated on every proxy invocation; its base64 alphabet contains none of the characters Next rejects (`getScriptNonceFromHeader`, `ESCAPE_REGEX`)."

**Submitted by:** security-reviewer
**Location:** `proxy.ts:37`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security-reviewer and the owner, who need to know whether the nonce is safe from guessing and from Next's rejection path
**Scope:** Covers nonce generation inside the `proxy()` body (fresh on each call, 122-bit v4 UUID source, 48-char base64 output) and acceptance of that output by Next 16.2.4's `getScriptNonceFromHeader`/`ESCAPE_REGEX`. It does not establish four things: that no CDN, edge or browser cache stores the dynamic HTML and replays one nonce (the critic's own residue); that the proxy runs on requests its matcher excludes (prefetches, see Claim 28), which get no nonce at all; which runtime the proxy actually runs in (the `proxy.ts:35-36` "Edge runtime" comment is not verdicted here); and that the forwarded `x-nonce` request header is consumed anywhere (the layout does not read it).

The nonce is computed on every call, inside the function body:

```ts
// proxy.ts:34-37
export function proxy(request: NextRequest): NextResponse {
  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
  // available in the Edge runtime that Next proxy runs in.
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```
(excerpt ends :37; enclosing proxy() continues to :49, read: the nonce flows to `requestHeaders.set("x-nonce", nonce)` at :42 and `buildCsp(nonce)` at :47, its only uses)

It base64-encodes the 36-character UUID *text*, not 16 raw bytes. That yields 48 characters with no padding, and the entropy is the UUID's 122 random bits; the encoding adds none. Next extracts the nonce and rejects it only when `ESCAPE_REGEX` matches:

```js
// node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:34-35
    if (_htmlescape.ESCAPE_REGEX.test(nonce)) {
        throw Object.defineProperty(new Error('Nonce value from Content-Security-Policy contained HTML escape characters. ...
```
(excerpt ends :35; enclosing getScriptNonceFromHeader() continues to :42, read: it returns the nonce)

```js
// node_modules/next/dist/server/htmlescape.js:32
const ESCAPE_REGEX = /[&><  ]/g;
```

The base64 alphabet (`A-Za-z0-9+/=`) contains none of `& > < U+2028 U+2029`. Executed check: the probe called the real `proxy()` (transpiled verbatim with `typescript.transpileModule`) 20,000 times and fed each CSP header to Next's own `getScriptNonceFromHeader`. Results: 20,000 unique nonces, 0 throws, 0 parse misses, 0 `ESCAPE_REGEX` hits, and the forwarded `x-middleware-request-x-nonce` equal to the parsed nonce every time. The observed alphabet was `012345ABCDEFGIJLMNOQRSTUVWYZcdghijklmtwxyz`. The dev-server probe for Claim 28 also returned a distinct nonce on each proxied request. On "CSPRNG": `crypto.randomUUID` is specified (WebCrypto, Node) to draw from a cryptographically secure generator (paraphrased — no quote available because this is a platform-spec property, not repo code).

**Evidence:** `proxy.ts:34-49`, `proxy.ts:19-32`, `node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:12-42`, `node_modules/next/dist/server/htmlescape.js:32`. Executed: `timeout 120 node --experimental-strip-types /tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25/probe/s1.mts`, cwd `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25/app-copy`, exit 0, 2026-11-20T01:38:00Z. Output: `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/csp/stage25-logs/s1-nonce-probe.log`

---

## Claim 26: "The OpenRouter and Anthropic calls that `proxy.ts:16-17` names run in server modules (`app/lib/llm/callLlm.ts`, `streamLlm.ts`), imported only by API routes and server code, not client components; every client-side `fetch(` outside `app/api` targets `/api/*` or a `data:` URL."

**Submitted by:** security-reviewer
**Location:** `app/lib/llm/callLlm.ts:1-3,112-113`, `app/lib/llm/streamLlm.ts:1-3,87-88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the OpenRouter and Anthropic call sites and every value importer of `callLlm.ts`/`streamLlm.ts` in `app/` source, plus every `fetch(` call outside `app/api` in source. It does not establish what the built client bundle contains (the critic's residue); OpenAlex, which `proxy.ts:16` also names and for which no call site exists anywhere in `app/` (zero grep hits), so that part of the comment is not covered here; or non-`fetch` browser network paths beyond a grep for `EventSource`/`XMLHttpRequest`/`WebSocket`/`sendBeacon`, which found none.

The provider calls are server-side:

```ts
// app/lib/llm/callLlm.ts:1-2
import { randomUUID } from "crypto";
import Anthropic from "@anthropic-ai/sdk";
```
```ts
// app/lib/llm/callLlm.ts:112-113
  const anthropicKey = process.env.ANTHROPIC_API_KEY;
  const openRouterKey = process.env.OPENROUTER_API_KEY;
```
(excerpt ends :113; enclosing callLlm() continues to the end of the function, read: the OpenRouter `fetch(OPENROUTER_API_URL, …)` is at `:164`)

```ts
// app/lib/llm/streamLlm.ts:87-88
  const anthropicKey = process.env.ANTHROPIC_API_KEY;
  const openRouterKey = process.env.OPENROUTER_API_KEY;
```
(excerpt ends :88; enclosing streamLlm() continues, read; the OpenRouter `fetch(OPENROUTER_API_URL, …)` is at `streamLlm.ts:249`)

The value importers are all API routes or server helpers: `app/api/{refine/context,edit/inline,edit/whole,edit/artifact,explanation/lean-error,formalization/lean,decomposition/extract}/route.ts`, `app/lib/formalization/artifactRoute.ts` (imported only by `app/api/formalization/*/route.ts`), `streamLlm.ts`, and `app/lib/llm/transformSseStream.ts` (imported only by two API routes). The one client-reachable importer, `app/lib/formalization/api.ts:3`, is type-only (`import type { LlmCallUsage } from "@/app/lib/llm/callLlm";`), and TypeScript erases it. Client `fetch(` sites outside `app/api` are: `"/api/refine/context"` (`ContextInput.tsx:25`), `"/api/explanation/lean-error"` (`LeanCodeDisplay.tsx:88`), `"/api/analytics"` (`useAnalytics.ts:11,30`), `"/api/verification/lean"` (`api.ts:104`), `fetch(dataUrl)` from `toPng` (`exportGraph.ts:24,37`), and `fetch(url, …)` in `api.ts:10,38`. Every `url` caller passes a `/api/...` literal or an `ARTIFACT_ROUTE` value, and all of those are `/api/formalization/*` (`app/lib/types/artifacts.ts:193-197`; `api.ts:121,137,146,159`). The pdf.js worker is loaded from a bundled `new URL(…)` (`pdfPropositionParser.ts:443`, `fileExtraction.ts:26`), not from a third-party origin.

**Evidence:** `app/lib/llm/callLlm.ts:1-5,112-113,164`, `app/lib/llm/streamLlm.ts:1-10,87-88,249`, `app/lib/formalization/api.ts:3,6-18,33-41,104,112-162`, `app/lib/types/artifacts.ts:193-197`, `app/lib/utils/exportGraph.ts:15-40`, `app/hooks/useArtifactGeneration.ts:42-61`, `app/lib/formalization/formalizeNode.ts:114-118`

---

## Claim 27a: "The proxy does … no loops, I/O, network calls or state kept between requests."

**Submitted by:** performance-reviewer
**Location:** `proxy.ts:34-49`
**Type:** Performance / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the user-written body of `proxy()` and `buildCsp()`: no loops, no awaits/I/O/network, no module-level mutable state. It does not establish that the framework calls the proxy makes are loop-free (they are not; see 27b).

```ts
// proxy.ts:41-48
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
  return response;
```
(excerpt ends :48; enclosing proxy() continues to :49, its closing brace, read)

`buildCsp` (`proxy.ts:19-32`) builds a fixed 9-element array and calls `join`. The only module-level binding is the static `config` (`proxy.ts:51-64`).

**Evidence:** `proxy.ts:19-32`, `proxy.ts:34-49`, `proxy.ts:51-64`

---

## Claim 27b: "The proxy does a constant amount of work per request … its per-request cost is dominated by `crypto.randomUUID()` and a Headers clone."

**Submitted by:** performance-reviewer
**Location:** `proxy.ts:34-49`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what drives the cost of one `proxy()` invocation in Node at Next 16.2.4. It does not establish Edge-runtime timings, the cost of Next's server-side unpacking of the `x-middleware-request-*` headers after the proxy returns, or whether the absolute cost (tens of microseconds) matters. It almost certainly does not.

The stated mechanism is refuted on two counts. First, the work is linear in the number of request headers, not constant. Both `new Headers(request.headers)` and `NextResponse.next({ request: { headers } })` iterate every header, and the second copies each one into the response:

```js
// node_modules/next/dist/server/web/spec-extension/response.js:34-39
        const keys = [];
        for (const [key, value] of init.request.headers){
            headers.set('x-middleware-request-' + key, value);
            keys.push(key);
        }
        headers.set('x-middleware-override-headers', keys.join(','));
```
(excerpt ends :39; enclosing handleMiddlewareField() continues to :41, read; called from `NextResponse.next` at :125-133, read)

Second, the dominant cost is `NextResponse.next`'s per-header serialization, not `randomUUID` or the clone. Measured with 21 request headers: nonce generation 505 ns/op, Headers clone plus set 2,161 ns/op, `NextResponse.next({request:{headers}})` 15,251 ns/op, CSP `headers.set` 792 ns/op. A reader acting on "dominated by randomUUID" would optimise the wrong step. Request-header count is bounded in practice, so "effectively constant" would be defensible; the "dominated by" attribution is not.

**Evidence:** `proxy.ts:37-47`, `node_modules/next/dist/server/web/spec-extension/response.js:24-41,125-133`. Executed: `timeout 120 node /tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25/probe/s3.cjs`, cwd `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25/app-copy`, exit 0, 2026-11-20T01:43:11Z. Output: `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/csp/stage25-logs/s3-cost-bench.log`

---

## Claim 28: "The `missing` conditions on `next-router-prefetch` and `purpose: prefetch` stop the proxy from running on router prefetches."

**Submitted by:** performance-reviewer
**Location:** `proxy.ts:55-63`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Next 16.2.4 `next dev --webpack` behaviour for `/` with the `next-router-prefetch` header (values `1` and `2`) and with `purpose: prefetch`. It also covers that a plain navigation, an RSC client navigation (`rsc: 1`) and a non-matching `purpose: other` still run the proxy. It does not establish four things: production `next build`/`next start` behaviour (not run: no network for Google Fonts); browser speculative prefetches that send `Sec-Purpose: prefetch` rather than `Purpose`, which do still run the proxy; that skipping prefetches is harmless; or behaviour on paths other than `/`. On the third point: a browser HTML prefetch that sends `Purpose: prefetch` gets a response with no CSP header, and if the browser later uses that cached document for navigation, the page renders with no CSP. This was not tested here.

Next evaluates `missing` as "none of these may match":

```js
// node_modules/next/dist/shared/lib/router/utils/prepare-destination.js:118
    const allMatch = has.every((item)=>hasMatch(item)) && !missing.some((item)=>hasMatch(item));
```
(excerpt ends :118; enclosing matchHas() continues to :123, read: it returns `params` or `false`, and `getMiddlewareRouteMatcher` in `middleware-route-matcher.js:19-24` skips the matcher on `false`)

A `value` is matched as an anchored regex: ``new RegExp(`^${hasItem.value}$`)`` (`prepare-destination.js:101`). The Next 16 client router sets the header on its prefetches: `[_approuterheaders.NEXT_ROUTER_PREFETCH_HEADER]: '1'` (`node_modules/next/dist/client/components/segment-cache/cache.js:993`), with `'2'` at `:1398`.

Executed against a live dev server running the d90d6bb tree. A, D and E got a `content-security-policy` header, and the server log annotated those requests with `(proxy.ts: …ms)`. B, C and F got no CSP header and no proxy annotation:

- A: plain request
- B: `next-router-prefetch: 1` with `rsc: 1`
- C: `purpose: prefetch`
- D: `rsc: 1` only
- E: `purpose: other`
- F: `next-router-prefetch: 2`

All responses were 500 because of the environmental `bluebird`/`mammoth` symlink resolution failure, which happens after the proxy has run and is unrelated to the claim. Curl exit codes were not captured (a scripting slip, noted in the log); every probe received an HTTP status line.

**Evidence:** `proxy.ts:51-64`, `node_modules/next/dist/shared/lib/router/utils/prepare-destination.js:57-123`, `node_modules/next/dist/shared/lib/router/utils/middleware-route-matcher.js:12-29`, `node_modules/next/dist/client/components/segment-cache/cache.js:993,1398-1403`. Executed: `NEXT_TELEMETRY_DISABLED=1 timeout 300 ./node_modules/.bin/next dev --webpack -p 3917` in `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25/app-copy`, plus six `curl -s -o /dev/null -D - -m 90 [-H …] http://127.0.0.1:3917/` probes, cwd `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25`, 2026-11-20T01:42:11Z. The server was stopped by PID (killed by the probe, exit not applicable). Output: `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/csp/stage25-logs/s4-prefetch-curl.log` and `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/csp/stage25-logs/s4-next-dev-server.log` (proxy annotations on its `GET /` lines)

---

## Claim 29: "The `proxy` and `config` export names and shapes match the Next 16 file convention (middleware renamed to proxy)."

**Submitted by:** api-consistency-reviewer
**Location:** `proxy.ts:1-64`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file name (`proxy` at the project root), the handler export name, and the `config.matcher` object shape (`source` plus `missing` of `{type, key, value?}`) against Next 16.2.4's template and zod schema, plus the observed fact that `next dev` loads and runs the file. It does not establish the runtime the proxy executes in (the `proxy.ts:35-36` Edge-runtime comment is not verdicted here) or production-build validation (not run).

```js
// node_modules/next/dist/build/templates/middleware.js:75-77
const page = 'VAR_DEFINITION_PAGE';
const isProxy = page === '/proxy' || page === '/src/proxy';
const handlerUserland = (isProxy ? mod.proxy : mod.middleware) || mod.default;
```
(excerpt ends :77; enclosing module continues, read: `:87-88` throws `must export a function named \`proxy\`` if the handler is not a function)

`PROXY_FILENAME = 'proxy'` (`node_modules/next/dist/lib/constants.js:289`). The matcher schema accepts `{ locale?, has?, missing?, source }` with `.strict()` (`node_modules/next/dist/build/segment-config/middleware/middleware-config.js:73-80`), which matches `proxy.ts:56-62`. Executed: the dev server for Claim 28 compiled `proxy.ts`, ran it (log lines `GET / … (proxy.ts: 119ms)`), and applied its `missing` matcher.

**Evidence:** `proxy.ts:34`, `proxy.ts:51-64`, `node_modules/next/dist/build/templates/middleware.js:75-89`, `node_modules/next/dist/lib/constants.js:289`, `node_modules/next/dist/build/segment-config/middleware/middleware-config.js:73-80`. Executed: same run as Claim 28. Output: `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/csp/stage25-logs/s4-next-dev-server.log`

---

## Claim 30: "`RootLayout` keeps its name and props type; making it `async` is compatible with its only consumer, the Next renderer."

**Submitted by:** api-consistency-reviewer
**Location:** `app/layout.tsx:22-26`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the name, the props type, the absence of other importers, and that the file is a server component (so async is permitted). It does not establish that the page renders successfully end to end: the dev render in this sandbox failed for an unrelated module-resolution reason. Nor does it cover the side effect of `await headers()`, which makes every route under this layout dynamic. That is intended, not an API change, and was not verdicted.

Before, at d86d2dc: `export default function RootLayout({` (`app/layout.tsx:20` at d86d2dc). After:

```tsx
// app/layout.tsx:22-26
export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
```
(excerpt ends :26; enclosing RootLayout() continues to :42, read: `await headers()` at :31, then the unchanged JSX)

`rg "RootLayout|…layout\""` outside `app/layout.tsx` returns no hits, and the file has no `"use client"` directive (paraphrased — no quote available because the claim covers absence of code: no matching grep results). Async server components are the documented App Router form for layouts that `await` request APIs such as `headers()` (paraphrased — no quote available because this is framework documentation, not repo code).

**Evidence:** `app/layout.tsx:1-42`, `git show d86d2dc:app/layout.tsx` lines 20-24

---

## Claim 31: "The d90d6bb refactor kept the directive list byte-for-byte identical (`git diff 9b4e453 d90d6bb -- proxy.ts` touches only the runtime comment and inlines the `csp` local)."

**Submitted by:** api-consistency-reviewer
**Location:** `proxy.ts:19-48`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte identity of the `directives` array and the `join("; ")` across 9b4e453 and d90d6bb, and the full list of hunks in that diff. It does not establish anything about b25e939 (the middle commit, which touches only `app/layout.tsx`) or about the emitted header at runtime, which Claims 25 and 28 observed.

The directive block is identical: the sha256 of the `const directives = [ … ];` block is `3d40b9c5…32ac46` at both commits, `diff` exits 0, and the single diff hunk (`@@ -31,11 +31,10 @@`) has `return directives.join("; ");` only as context. The parenthetical "touches only" is short by one change: the diff also adds an explicit return type,

```diff
-export function proxy(request: NextRequest) {
+export function proxy(request: NextRequest): NextResponse {
```

which the d90d6bb commit message itself lists ("add explicit return type"). A precise version: "touches only the return-type annotation and the runtime comment, and inlines the `csp` local".

**Evidence:** `proxy.ts:19-32`, `proxy.ts:34-48`. Executed: `git diff 9b4e453 d90d6bb -- proxy.ts` (exit 0) and a `diff` of the directive blocks (exit 0) plus sha256, cwd `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-csp`, 2026-11-20 (timestamp in log). Output: `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/csp/stage25-logs/s7-directive-diff.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 27b** (`proxy.ts:34-49`): proxy cost is linear in request-header count and is dominated by `NextResponse.next`'s `x-middleware-request-*` copy (~15 µs vs ~0.5 µs for the nonce), not by `randomUUID` plus the clone. The performance-reviewer's "What Looks Good" line should drop the "dominated by" attribution.

### Mostly Accurate
- **Claim 31** (`proxy.ts:34`): the directives are byte-identical, but the 9b4e453→d90d6bb diff also adds the `: NextResponse` return type, so "touches only" should name it.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: d90d6bb` as its first line and a `## Submitted Claims` section verdicting each listed claim.
- Answered: yes
- Out of scope: new claims harvested from the diff (Stage 1 owns those), including the `proxy.ts:35-36` "Edge runtime" comment, the `proxy.ts:39-40` "layouts can read it via headers() and pass it to <Script>" comment (`x-nonce` is forwarded but nothing reads it), and the `proxy.ts:16` OpenAlex mention, which matches no call site in `app/`. Production `next build` was not run because there is no network for Google Fonts.
- Escalate: (1) Claim 28 residue for security-reviewer: excluding `purpose: prefetch` means a browser HTML prefetch that sends `Purpose: prefetch` gets a response with no CSP. If the browser later navigates using that cached document, the page renders without a CSP. Untested here; worth a decision on whether the `purpose` entry should stay. (2) Claim 27b: correct the performance-reviewer endorsement before it reaches the rubric.
