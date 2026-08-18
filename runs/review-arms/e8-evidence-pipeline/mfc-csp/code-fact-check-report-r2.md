# Code Fact-Check Report

**Commit:** d90d6bb
**Repository:** /workspace/external/cc-review-eval/mfc-csp
**Scope:** Files changed in `git diff d86d2dc...HEAD` (`app/layout.tsx`, `proxy.ts`) plus the three commit messages on that range (9b4e453, b25e939, d90d6bb)
**Checked:** 2026-08-18
**Total claims checked:** 18
**Summary:** 12 verified, 2 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Execution environment notes (apply to all `executed` claims): all commands ran in
`/workspace/external/cc-review-eval/mfc-csp` on 2026-08-18 (UTC timestamps per log). The sandbox
has no network access, so `next build` was run with
`NEXT_FONT_GOOGLE_MOCKED_RESPONSES=/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-font-mock.js`
to stub the two Google Fonts CSS fetches (a stock `npm run build` fails on the font download,
first-attempt failure preserved in prose here; the committed log `r2-build.log` is the successful
mocked-fonts run). This affects only `next/font` asset fetching, not CSP/proxy behavior. Servers:
production `next start` on port 4231, dev `next dev` on port 4232; both killed after probing.
Evidence directory: `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/` (all
files prefixed `r2-`).

---

## Claim 1a: "Opt this layout out of static rendering" (via `await headers()`)

**Location:** `app/layout.tsx:27-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the root route is dynamically rendered in the production build; does not establish that `await headers()` is the sole cause (no counterfactual build without it was run, to keep the shared clone unmodified).

The layout awaits the dynamic `headers()` API:

```tsx
// app/layout.tsx:27-31
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. ...
  await headers();
```

The production build reports every route, including `/`, as dynamic:

```
// evidence/r2-build.log
┌ ƒ /
├ ƒ /_not-found
...
ƒ  (Dynamic)  server-rendered on demand
```

- Command: `NEXT_FONT_GOOGLE_MOCKED_RESPONSES=.../r2-font-mock.js npm run build`
- cwd: `/workspace/external/cc-review-eval/mfc-csp` · exit code: 0 · timestamp: 2026-08-18T06:24:01Z

**Evidence:** `app/layout.tsx:27-31`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-build.log`

---

## Claim 1b: "...so proxy.ts runs on every request and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:27-28`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that a fresh nonce is attached per request in the running production server; does not establish the counterfactual (what would happen if the layout were statically rendered), which was not executed.

The imprecision: the proxy runs on every matched request regardless of whether the page is
statically or dynamically rendered — Next middleware/proxy executes before the route is served
(paraphrased — no quote available because middleware-before-route ordering is spread across Next's
server pipeline in `node_modules/next/dist/server` rather than a quotable line). What dynamic
rendering actually buys is that the *rendered HTML* embeds the current request's nonce so it
matches the CSP header; a cached static page could not do that. The conclusion — dynamic rendering
is required for fresh per-request nonces to work end-to-end — is right, and the executed evidence
confirms fresh nonces per request: two successive requests carried different nonces in the CSP
header:

```
// evidence/r2-curl-probes.log (root vs /some-random-page)
content-security-policy: ... 'nonce-MWY1MjlhZDYtYWQyMy00ZjJjLWFlMzktZTEyZjdkZWIyNTgx' ...
content-security-policy: ... 'nonce-YjlkYTRiMmItMDIzOC00M2RhLWFlODYtYTM1NmE5NGZmYjVm' ...
```

- Command: `curl -s -m 15 -D - -o /dev/null http://localhost:4231/` (and `/some-random-page`)
- cwd: `/workspace` (server cwd `/workspace/external/cc-review-eval/mfc-csp`) · exit code: 0 · timestamp: 2026-08-18T06:24:35Z–06:27:09Z

**Evidence:** `app/layout.tsx:27-28`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-curl-probes.log`

---

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the production server's rendered HTML for the root page (script tags nonce-tagged, nonce matches the same response's CSP header, layout reads no x-nonce); does not establish browser-side execution of those scripts (no browser in the sandbox).

Executed end-to-end: the production server's HTML tags every generated `<script>` (and stylesheet
`<link>`) with a nonce, and that nonce is byte-identical to the nonce in the same response's CSP
header:

```
// evidence/r2-root-headers.txt
content-security-policy: default-src 'self'; script-src 'self' 'nonce-NzhmNmUwMjEtNWM5Zi00Nzk1LWIzMTgtNzhmODZkOGZkM2M1' 'strict-dynamic'; ...
```

```
// evidence/r2-html-nonce-check.log (script tags extracted from r2-root-page.html)
<script src="/_next/static/chunks/0_0neb_tu2q4s.js" async="" nonce="NzhmNmUwMjEtNWM5Zi00Nzk1LWIzMTgtNzhmODZkOGZkM2M1">
...
```

`rg -o 'nonce="[^"]*"' r2-root-page.html | sort -u` yields exactly one distinct value, equal to
the header nonce (captured in `r2-html-nonce-check.log`). The dev server shows the same behavior
(39 nonce attributes, one distinct value matching the dev response header — `r2-dev-check.log`).
And nothing in `app/` reads `x-nonce` — a repo-wide grep finds the header name only where
`proxy.ts` sets it and where this comment mentions it (paraphrased — no quote available because
the claim covers absence of code: `rg -rn "x-nonce" app proxy.ts` returns only `proxy.ts` set-site
and the `app/layout.tsx` comment).

Internal-mechanism note: Next's renderer parses the nonce out of a `content-security-policy`
header it sees on the request side after the proxy runs:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

The observed behavior nonetheless matches the comment exactly: the proxy sets CSP only on the
response, and Next tagged the scripts with that response's nonce.

- Command: `curl -s -m 20 -D r2-root-headers.txt http://localhost:4231/ -o r2-root-page.html`
- cwd: `/workspace` (server on port 4231) · exit code: 0 · timestamp: 2026-08-18T06:27:56Z

**Evidence:** `app/layout.tsx:28-30`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-root-headers.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-root-page.html`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-html-nonce-check.log`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-dev-check.log`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy)"

**Location:** `proxy.ts:5`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that Next 16.2.4 (the installed version) recognizes the `proxy.ts` file convention and runs it; does not establish the full deprecation timeline of `middleware.ts` (see Claim 11).

The installed Next (16.2.4 per `node_modules/next/package.json`, checked via
`node -e "console.log(require('next/package.json').version)"`) defines the convention:

```js
// node_modules/next/dist/lib/constants.js:287-290
const MIDDLEWARE_FILENAME = 'middleware';
const MIDDLEWARE_LOCATION_REGEXP = `(?:src/)?${MIDDLEWARE_FILENAME}`;
const PROXY_FILENAME = 'proxy';
const PROXY_LOCATION_REGEXP = `(?:src/)?${PROXY_FILENAME}`;
```

The production build detected and compiled the file, labeling it:

```
// evidence/r2-build.log
ƒ Proxy (Middleware)
```

and at runtime it set the CSP header on matched requests (`r2-curl-probes.log`).

- Command: `NEXT_FONT_GOOGLE_MOCKED_RESPONSES=.../r2-font-mock.js npm run build`
- cwd: `/workspace/external/cc-review-eval/mfc-csp` · exit code: 0 · timestamp: 2026-08-18T06:24:01Z

**Evidence:** `proxy.ts:5`, `node_modules/next/dist/lib/constants.js:287-290`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-build.log`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-curl-probes.log`

---

## Claim 4: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust. This keeps a hypothetical injected `<script>` tag from executing"

**Location:** `proxy.ts:7-10`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the served policy string implements nonce + 'strict-dynamic' with no 'unsafe-inline' in script-src, and that all Next-generated scripts carry the matching nonce; does not establish actual browser enforcement (no browser in the sandbox — enforcement rests on standard CSP3 semantics).

The served header contains exactly the directives that produce this behavior under CSP3:

```
// evidence/r2-root-headers.txt
content-security-policy: default-src 'self'; script-src 'self' 'nonce-NzhmNmUwMjEt...' 'strict-dynamic'; ...
```

Under 'strict-dynamic', an injected `<script>` without the nonce is blocked, and nonce-carrying
scripts may load further scripts that inherit trust (paraphrased — no quote available because
this part is CSP specification semantics enforced by the browser, not repo code). The precondition
the comment relies on — that Next's own scripts are all nonce-tagged — was confirmed executed: every
`<script>` in the prod HTML carries the header's nonce (Claim 2, `r2-html-nonce-check.log`).

- Command: `curl -s -m 20 -D r2-root-headers.txt http://localhost:4231/ -o r2-root-page.html`
- cwd: `/workspace` · exit code: 0 · timestamp: 2026-08-18T06:27:56Z

**Evidence:** `proxy.ts:7-10`, `proxy.ts:20-31`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-root-headers.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-html-nonce-check.log`

---

## Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** `proxy.ts:12-14`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the server-rendered HTML of the root page in both dev and production; does not establish client-side style injection after hydration or during dev HMR (curl cannot observe browser-side DOM mutations), which is why confidence is Medium rather than High.

The stated mechanism is refuted by execution: in both the production and dev server-rendered HTML,
Tailwind's CSS arrives as external stylesheets, not inline styles. Prod:

```
// evidence/r2-style-check.log
--- prod stylesheet links:
<link rel="stylesheet" href="/_next/static/chunks/0qqafo8jts909.css" nonce="NzhmNmUwMjEt..." data-precedence="next"/>
...
--- prod style element count:
0
```

Dev likewise has zero `<style>` elements and two `<link rel="stylesheet">` tags
(`r2-dev-check.log`, "style element count: 0"). The inline styles that do exist — and that do
require `'unsafe-inline'` in `style-src` — are 4 `style="..."` attributes emitted by the app's own
components, not by Tailwind:

```
// evidence/r2-style-check.log (dev HTML, identical count in prod)
style="font-family:var(--font-serif, &#x27;EB Garamond&#x27;, serif)"
style="width:var(--rail-width);background:var(--rail-bg)"
```

These originate from `style={{...}}` props in app components — e.g. `app/components/layout/IconRail.tsx`,
`app/components/panels/ArtifactPanelShell.tsx` (paraphrased — no quote available because the
attribution spans several component files found via `rg -ln "style=\{\{" app`). So the carve-out
is still needed, but for the app's own inline style attributes; a reader acting on the comment
(e.g., attempting to tighten style-src by reworking Tailwind's shipping) would be misled about
where the inline styles come from.

- Commands: `curl -s -D r2-dev-headers.txt http://localhost:4232/ -o r2-dev-page.html` (exit 0, 2026-08-18T06:32:25Z); style extraction into `r2-style-check.log` (2026-08-18T06:32:41Z)
- cwd: `/workspace` (dev server cwd `/workspace/external/cc-review-eval/mfc-csp`)

**Evidence:** `proxy.ts:12-14`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-style-check.log`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-dev-check.log`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-dev-page.html`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-root-page.html`

---

## Claim 6a: "`connect-src 'self'` is sufficient because Anthropic / ... / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:16-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers static import/call-site analysis of the current codebase (browser code fetches only relative `/api/...` URLs; Anthropic/OpenRouter clients are imported only by API routes); does not establish runtime-constructed URLs or future additions.

The only absolute third-party URL in browser-reachable code paths is the OpenRouter constant, and
it lives in the server-side LLM module:

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

```ts
// app/lib/llm/callLlm.ts:2,14
import Anthropic from "@anthropic-ai/sdk";
    _anthropicClient = new Anthropic({ apiKey });
```

`callLlm`/`streamLlm`/`OPENROUTER_API_URL` are imported exclusively from `app/api/**/route.ts`
files — a grep over `app/components` and `app/hooks` finds zero importers (paraphrased — no quote
available because the claim covers absence of code: `rg -ln "callLlm|streamLlm|OPENROUTER_API_URL"
app/components app/hooks` returns nothing, while the same grep over `app/api` returns seven route
files). Client-side fetches all target relative API paths, e.g.:

```ts
// app/lib/types/artifacts.ts:192-193
export const ARTIFACT_ROUTE: Partial<Record<ArtifactType, string>> = {
  "causal-graph": "/api/formalization/causal-graph",
```

```ts
// app/lib/formalization/api.ts:104
  const res = await fetch("/api/verification/lean", {
```

A repo-wide grep for `https?://` in `app/components`, `app/hooks`, `app/lib` (excluding tests)
finds only the OpenRouter constant above and two SVG `xmlns` attributes (paraphrased — no quote
available because the claim covers absence of matching grep results).

**Evidence:** `proxy.ts:16-17`, `app/lib/llm/callLlm.ts:2-14`, `app/lib/types/artifacts.ts:192-198`, `app/lib/formalization/api.ts:104`, `app/hooks/useDecomposition.ts:129-130`

---

## Claim 6b: "...OpenAlex... calls are server-to-server (Next API routes)"

**Location:** `proxy.ts:16`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of any OpenAlex integration in the repository and its git history; does not establish whether OpenAlex integration is planned elsewhere.

No OpenAlex call, client, URL, or symbol exists anywhere in the repository — case-insensitive
grep over all tracked files matches only this comment line itself, and `git log --all -S openalex -i`
shows the term entered the repo in commit 9b4e453 (the commit that created `proxy.ts`) and never
existed as code (paraphrased — no quote available because the claim covers absence of code: the
only grep hit is `proxy.ts:16`, the line under check). There are no OpenAlex calls to be
"server-to-server"; the comment attributes a property to a nonexistent integration. This does not
weaken the CSP conclusion (vacuously, no browser-to-OpenAlex traffic exists), but the reference is
fabricated relative to this codebase.

**Evidence:** `proxy.ts:16`, `app/lib/llm/callLlm.ts:7` (the real third-party endpoints for contrast)

---

## Claim 7a: "...the Edge runtime that Next proxy runs in"

**Location:** `proxy.ts:35-36`
**Type:** Architectural / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the runtime Next 16.2.4 assigns to this repo's proxy in a production build (no runtime override is configured in `proxy.ts`); does not establish behavior on other hosting platforms or Next versions.

The production build's own manifest records the proxy's runtime as Node.js, not Edge:

```json
// .next/server/functions-config-manifest.json (generated by the executed build, quoted from build output)
"functions": {
    "/_middleware": {
      "runtime": "nodejs",
```

`proxy.ts` exports no `runtime` config of its own — its `config` export contains only `matcher`
(`proxy.ts:52-64`). A reader acting on the comment (e.g., avoiding Node-only APIs, or debugging
Edge-specific limits) would be misled: this proxy runs in the Node.js runtime.

- Command: `NEXT_FONT_GOOGLE_MOCKED_RESPONSES=.../r2-font-mock.js npm run build` (manifest read post-build)
- cwd: `/workspace/external/cc-review-eval/mfc-csp` · exit code: 0 · timestamp: 2026-08-18T06:24:01Z

**Evidence:** `proxy.ts:35-36`, `proxy.ts:52-64`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-build.log`, `.next/server/functions-config-manifest.json` (build artifact)

---

## Claim 7b: "crypto.randomUUID and Buffer are both available in the ... runtime that Next proxy runs in"

**Location:** `proxy.ts:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both APIs function in the runtime this proxy actually executes in (Node.js, per Claim 7a); does not establish availability in an Edge deployment of the same code.

The nonce line exercises both APIs on every request:

```ts
// proxy.ts:37
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

Every probed response carried a well-formed base64 nonce — e.g.
`'nonce-MWY1MjlhZDYtYWQyMy00ZjJjLWFlMzktZTEyZjdkZWIyNTgx'` (`r2-curl-probes.log`), which decodes
to a UUID string (paraphrased — no quote available because the decode is an observation about the
captured value, not repo code: base64 of `1f529ad6-ad23-4f2c-ae39-e12f7deb2581`). Had either API
been missing, the proxy would have thrown and no CSP header would appear.

- Command: `curl -s -m 15 -D - -o /dev/null http://localhost:4231/`
- cwd: `/workspace` · exit code: 0 · timestamp: 2026-08-18T06:24:35Z

**Evidence:** `proxy.ts:37`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-curl-probes.log`

---

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the code uses Next's documented request-header-override mechanism to forward `x-nonce`; does not establish an end-to-end observation of a layout reading `x-nonce` (no code in the repo reads it — see Claim 2 — so there is nothing to execute without modifying the clone).

The code sets the header and passes it through the documented override channel:

```ts
// proxy.ts:42-48
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
```

Next's own types document that this field overrides the incoming request:

```ts
// node_modules/next/dist/server/web/spec-extension/response.d.ts:37-41
interface MiddlewareResponseInit extends globalThis.ResponseInit {
    /**
     * These fields will override the request from clients.
     */
    request?: ModifiedRequest;
}
```

and the implementation encodes the override for the server to apply:

```js
// node_modules/next/dist/server/web/spec-extension/response.js:36,39
            headers.set('x-middleware-request-' + key, value);
        headers.set('x-middleware-override-headers', keys.join(','));
```

Confidence is Medium because the "layouts can read it" half was verified only as a capability from
Next's documented mechanism, not observed end-to-end (this repo's layout deliberately does not
read `x-nonce`).

**Evidence:** `proxy.ts:39-48`, `node_modules/next/dist/server/web/spec-extension/response.d.ts:37-41`, `node_modules/next/dist/server/web/spec-extension/response.js:30-40`

---

## Claim 9: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches..."

**Location:** `proxy.ts:52-63`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers CSP-header presence/absence for the probed route classes (page, 404 page, /api route, /favicon.ico, /_next/static path, and both prefetch-header variants) on the production server; does not establish every conceivable path (e.g. `/_next/image` was excluded by the same matcher source but not probed).

The matcher:

```ts
// proxy.ts:55-61
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```

Probes against the production server (`r2-curl-probes.log`, all `curl -s -D - -o /dev/null`,
exit 0 unless noted, 2026-08-18T06:24:35Z–06:27:18Z):

- `GET /` → 200 **with** `content-security-policy` header
- `GET /some-random-page` → 404 **with** CSP header (page navigations, including not-found, covered)
- `GET /api/analytics` → 200 **without** CSP header
- `GET /favicon.ico` → 200 **without** CSP header
- `GET /_next/static/chunks/xyz.js` → 404 **without** CSP header
- `GET /` with `purpose: prefetch` → 200 **without** CSP header
- `GET /` with `next-router-prefetch: 1` + `RSC: 1` → 200 **without** CSP header (the same
  request without the `RSC` header hung until curl's timeout, exit 28 — a server quirk unrelated
  to the matcher; the RSC variant demonstrates the skip)

The header presence/absence lines are captured verbatim in the log (paraphrased — no quote
available because the negative cases are the absence of a header line in the captured responses;
see `r2-curl-probes.log` sections `api-analytics`, `favicon`, `static-asset`, `prefetch-purpose`).

**Evidence:** `proxy.ts:52-63`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-curl-probes.log`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-build.log` (matcher compiled into `functions-config-manifest.json` with the same source and `missing` conditions)

---

## Claim 10: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit 9b4e453 (commit message)
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers greps for the three named mechanisms in `app/` and KaTeX's effective trust setting; does not establish the absence of other XSS vectors (that is a security-review question, out of scope).

`dangerouslySetInnerHTML` and `rehype-raw`/`rehypeRaw`: zero matches anywhere under `app/` or in
`package.json` dependencies (paraphrased — no quote available because the claim covers absence of
code: `rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw" app` and the package.json grep return
nothing). KaTeX is used via `rehype-katex` with no options object:

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:6,10
import rehypeKatex from "rehype-katex";
const rehypePlugins = [rehypeKatex];
```

With `trust` unset, KaTeX's settings coerce it to false:

```js
// node_modules/katex/dist/katex.mjs:349-350
    var trust = typeof this.trust === "function" ? this.trust(context) : this.trust;
    return Boolean(trust);
```

`Boolean(undefined)` is `false`, so the effective setting is `trust: false` — the claim holds as
the default rather than an explicit option, which does not change the guarantee.

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:6-10`, `node_modules/katex/dist/katex.mjs:349-350`

---

## Claim 11: "middleware.ts builds with a deprecation warning"

**Location:** commit 9b4e453 (commit message)
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the presence of the deprecation-warning code path in the installed Next 16.2.4; does not establish the warning actually firing, because executing it was blocked.

This is an executable guarantee ("builds with a warning"), so under the mandatory-execution rule
the verdict is capped at Unverifiable from static reading: executing it would require creating a
`middleware.ts` in the clone, and this review must leave the shared clone unmodified (another
replicate runs servers from the same working tree) — that is the specific blocker. Static evidence
strongly supports the claim: the installed Next's build path contains exactly this warning:

```js
// node_modules/next/dist/build/index.js:651
_log.warnOnce(`The "${_constants.MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${_constants.PROXY_FILENAME}" instead. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`);
```

with `MIDDLEWARE_FILENAME = 'middleware'` and `PROXY_FILENAME = 'proxy'`
(`node_modules/next/dist/lib/constants.js:287-289`).

**Evidence:** `node_modules/next/dist/build/index.js:645-651`, `node_modules/next/dist/lib/constants.js:287-290`

---

## Claim 12: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** commit 9b4e453 (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the production build/serve of the root page in this sandbox (header emitted, every generated script tag nonce-tagged with the matching value); does not establish browser-side enforcement or behavior on other routes' client-side navigations.

Reproduced independently: the prod server emits the CSP header (`r2-root-headers.txt`, quoted at
Claim 2), and every `<script>` tag in the generated HTML carries the matching nonce — the extracted
script-tag list shows a nonce attribute on each of the 15+ script tags and
`rg -o 'nonce="[^"]*"' | sort -u` yields exactly one value, equal to the header's
(`r2-html-nonce-check.log`; quoted at Claim 2).

- Commands: build (exit 0, 2026-08-18T06:24:01Z, `r2-build.log`); `curl -s -m 20 -D r2-root-headers.txt http://localhost:4231/ -o r2-root-page.html` (exit 0, 2026-08-18T06:27:56Z)
- cwd: `/workspace/external/cc-review-eval/mfc-csp` (build), `/workspace` (curl)

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-build.log`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-root-headers.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-html-nonce-check.log`

---

## Claim 13: "No behavior change; CSP directives preserved exactly." (cleanup commit)

**Location:** commit d90d6bb (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the b25e939→d90d6bb diff of `proxy.ts` and `app/layout.tsx`; does not establish equivalence beyond those two files (no other files changed in that commit per its diffstat).

The full diff of the cleanup commit touches only comments, an explicit return type, and inlining
of a single-use local — the directive-building code and every directive string are untouched:

```diff
// git diff b25e939 d90d6bb (proxy.ts hunk)
-export function proxy(request: NextRequest) {
+export function proxy(request: NextRequest): NextResponse {
...
   const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
-  const csp = buildCsp(nonce);
...
-  response.headers.set("Content-Security-Policy", csp);
+  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

The `app/layout.tsx` hunk of the same diff changes only comment text (paraphrased — no quote
available because the hunk is a four-line comment rewrite already reproduced in full under
Claims 1-2's discussion of the current text).

**Evidence:** commit range `b25e939..d90d6bb` (`git diff`), `proxy.ts:34-49`

---

## Claim 14: "Lint clean"

**Location:** commit d90d6bb (commit message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `npm run lint` on the checked-out HEAD in this sandbox; does not establish which warnings existed at commit time versus environment differences.

`npm run lint` exits 0 with zero errors, but it is not literally clean — two pre-existing warnings
fire in a file untouched by this diff:

```
// evidence/r2-lint.log
/workspace/external/cc-review-eval/mfc-csp/app/page.tsx
  209:6  warning  React Hook useCallback has missing dependencies: ...  react-hooks/exhaustive-deps
  271:6  warning  React Hook useCallback has missing dependencies: ...  react-hooks/exhaustive-deps
✖ 2 problems (0 errors, 2 warnings)
```

The precise version: "lint passes (exit 0, 0 errors) with 2 pre-existing warnings in
`app/page.tsx`."

- Command: `npm run lint`
- cwd: `/workspace/external/cc-review-eval/mfc-csp` · exit code: 0 · timestamp: 2026-08-18T06:34:56Z

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-lint.log`

---

## Claim 15: "221/221 tests pass"

**Location:** commit d90d6bb (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the vitest run summary on the checked-out HEAD in this sandbox; does not establish a clean process exit here (the non-zero exit code traced to sandbox path pollution outside the repo, not to any test).

The suite reports exactly the claimed count:

```
// evidence/r2-test.log
 Test Files  24 passed (24)
      Tests  221 passed (221)
```

`npm test` nonetheless exited 1 in this sandbox because vitest's post-run jsdom presence check
tripped over an invalid `package.json` outside the repository:

```
// evidence/r2-test.log
Error: Invalid package config /workspace/external/package.json while importing /workspace/external/cc-review-eval/mfc-csp. Unexpected end of JSON input
...
 MISSING DEPENDENCY  Cannot find dependency 'jsdom'
```

`jsdom` is in fact installed (`node_modules/jsdom/package.json` exists — paraphrased, no quote
available because the evidence is the file's existence, checked with `ls`). All 221 tests ran and
passed; the exit code reflects the environment, not the tests — hence Medium confidence rather
than High.

- Command: `npm test`
- cwd: `/workspace/external/cc-review-eval/mfc-csp` · exit code: 1 (environment artifact, see above) · timestamp: 2026-08-18T06:34:34Z

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/r2-test.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`proxy.ts:12-14`): Tailwind v4 does not emit inline styles here — it ships external stylesheets in both dev and prod; the `'unsafe-inline'` carve-out is actually needed for the app's own `style={{...}}` attributes (4 in the root page). Reword the comment to attribute the carve-out correctly.
- **Claim 6b** (`proxy.ts:16`): No OpenAlex integration exists anywhere in the repo or its history; drop OpenAlex from the list or add the integration the comment presumes.
- **Claim 7a** (`proxy.ts:35-36`): The proxy runs in the Node.js runtime (`functions-config-manifest.json`: `"runtime": "nodejs"`), not the Edge runtime; the comment's conclusion (both APIs available) survives, but the runtime name should be corrected.

### Mostly Accurate
- **Claim 1b** (`app/layout.tsx:27-28`): Proxy runs on every matched request regardless of rendering mode; dynamic rendering is needed so the HTML embeds the fresh nonce, not so the proxy runs. Tighten the comment's causal wording.
- **Claim 14** (commit d90d6bb): "Lint clean" = exit 0 with 0 errors, but 2 pre-existing warnings in `app/page.tsx`.

### Unverifiable
- **Claim 11** (commit 9b4e453): "middleware.ts builds with a deprecation warning" — execution would require adding a `middleware.ts` to the shared clone, which this review must leave unmodified; the exact warning string exists in the installed Next 16.2.4 build path (`node_modules/next/dist/build/index.js:651`).
