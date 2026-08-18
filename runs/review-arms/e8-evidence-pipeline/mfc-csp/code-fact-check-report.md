# Code Fact-Check Report

**Commit:** d90d6bb
**Replication:** k=2 (E8 two-replicate protocol; merge rules adapted from the k=3 spec)
**Repository:** /workspace/external/cc-review-eval/mfc-csp
**Scope:** `git diff d86d2dc...HEAD` — `app/layout.tsx`, `proxy.ts` (CSP proxy with per-request nonces) — plus the three commit messages on that range (9b4e453, b25e939, d90d6bb; commit-message claims checked by r2 only)
**Checked:** 2026-08-18 (merged from replicate reports r1 checked 2026-08-17 and r2 checked 2026-08-18)
**Total claims checked:** 20
**Summary:** 14 verified, 1 mostly accurate, 0 stale, 4 incorrect, 1 unverifiable

Merged per the Stage-1 most-severe-wins protocol from `skills/code-review/SKILL.md`, adapted
to two replicates: clusters matched on (file, line-range ±5, claim substance); most severe
verdict wins; `**Replicate verdicts:**` lines carry `r1=… · r2=…` with `—` for a replicate
that did not surface the claim and a `single-replicate detection` marker where only one did.
This merge is mechanical collation of the replicates' verdicts and evidence — no new
verification was performed.

Execution environment notes (carried from the replicates; apply to `executed` claims):

- **r1** ran verdict-bearing executions against `next dev` (Next.js 16.2.4, Turbopack) on
  `PORT=4101`. A production `npm run build` failed twice in r1's environment on the Google
  Fonts fetch (no network; `evidence/r1-build.log`, `evidence/r1-build-retry.log`, exit 1
  both times). One temporary probe page (`app/r1probe/page.tsx`) was created for Claim 8's
  header round-trip and deleted; clean `git status` afterward.
- **r2** ran the production build successfully by stubbing the Google Fonts fetches with
  `NEXT_FONT_GOOGLE_MOCKED_RESPONSES=…/evidence/r2-font-mock.js` (`evidence/r2-build.log`,
  exit 0, 2026-08-18T06:24:01Z — affects only `next/font` asset fetching, not CSP/proxy
  behavior), then probed production `next start` on port 4231 and dev `next dev` on port
  4232.
- All raw outputs are under `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/evidence/`
  with `r1-` / `r2-` prefixes. Hallucination-pattern-log steps were skipped per the run's
  blinding instructions.

---

## Claim 1a: "Opt this layout out of static rendering" (via `await headers()`)

**Location:** `app/layout.tsx:27-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the root route is dynamically rendered in the production build (r2's mocked-fonts build); does not establish that `await headers()` is the sole cause (no counterfactual build without it was run).
**Replicate verdicts:** r1=Unverifiable · r2=Verified

The layout awaits the dynamic `headers()` API:

```tsx
// app/layout.tsx:27-31
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. ...
  await headers();
```

r2's production build reports every route, including `/`, as dynamic:

```
// evidence/r2-build.log
┌ ƒ /
├ ƒ /_not-found
...
ƒ  (Dynamic)  server-rendered on demand
```

- Command: `NEXT_FONT_GOOGLE_MOCKED_RESPONSES=.../r2-font-mock.js npm run build`
- cwd: `/workspace/external/cc-review-eval/mfc-csp` · exit code: 0 · timestamp: 2026-08-18T06:24:01Z

r1's static corroboration: Next's `headers()` implementation interrupts static generation
when called during prerender:

```js
// node_modules/next/dist/server/request/headers.js:105-107
return (0, _dynamicrendering.throwToInterruptStaticGeneration)(callingExpression, workStore, workUnitStore);
```

Divergence note (see Verdict stability): r1's Unverifiable was the mandatory-execution cap —
its build failed on the sandbox's Google Fonts fetch, and r1 explicitly named the production
build's static/dynamic route marker as the evidence that "would verify or refute this
directly." r2 executed exactly that probe (mocked fonts, exit 0) and it verified the claim.
An execution-blocked Unverifiable is an epistemic cap, not a more-severe finding; with the
named blocker resolved by the other replicate's successful execution, the executed Verified
carries the cluster.

**Evidence:** `app/layout.tsx:27-31`, `evidence/r2-build.log`, `node_modules/next/dist/server/request/headers.js:98-109`, `evidence/r1-build.log`, `evidence/r1-build-retry.log`

---

## Claim 1b: "...so proxy.ts runs on every request"

**Location:** `app/layout.tsx:27-28`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the claimed causal mechanism (static-rendering opt-out is what makes proxy.ts run per request); does not dispute that opting out of static rendering is needed for the HTML's baked-in nonce to stay fresh (that atom is Claim 1c).
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate (verdicted as part of the compound "runs on every request and can attach a fresh per-request CSP nonce"; per decision 033 the compound clusters with each atom and the sub-claim's Incorrect wins the cluster)

The stated mechanism is refuted by the proxy's own configuration: whether `proxy.ts` runs is
governed solely by the URL/header matcher, which has no coupling to a route's rendering mode:

```ts
// proxy.ts:55-63
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

Next runs proxy/middleware for every matched incoming request before route resolution,
including requests served from statically prerendered output, so the proxy would run per
request even if the layout were statically rendered (paraphrased — no quote available because
this is framework request-pipeline behavior spanning Next's server internals rather than a
quotable line; r2 independently recorded the same paraphrase). What the `await headers()`
opt-out actually changes is whether the HTML is re-rendered per request so its embedded nonce
matches the fresh CSP header — not whether the proxy executes. Both replicates converged on
this mechanism reading; they diverged only on verdict severity (r1 split the atom out as
Incorrect; r2 kept the compound at Mostly accurate because the conclusion end-to-end is
right). Confidence is Medium because the static-route counterfactual was not demonstrated by
execution in either replicate.

**Evidence:** `proxy.ts:51-63`, `app/layout.tsx:27-31`, `evidence/r1-dev-server.log`

---

## Claim 1c: "...and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each matched request receives a distinct nonce in the response CSP header, observed on both the dev server (r1) and the production server (r2); does not cover excluded routes.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound verdict — r2's evidence for this atom confirms fresh per-request nonces; the compound's imprecise half is Claim 1b)

r1 executed: two consecutive `curl -s -o /dev/null -D - http://localhost:4101/` requests
(cwd `/workspace/external/cc-review-eval/mfc-csp`, exit 0, 2026-08-17 ~23:23 local) returned
distinct nonces in the `content-security-policy` response header:

```
// evidence/r1-nonce-freshness.txt
nonce-N2MwMzJhZjctMjQzZS00YjhmLThkMDYtNDQwMGUzMjY5NzRh
nonce-OTUxMWVjMDUtNjQwYy00NDhiLWIzNzQtMmRlNGMxNzYwOTE0
```

r2 reproduced the same on the production server (curl, exit 0, 2026-08-18T06:24:35Z–06:27:09Z):

```
// evidence/r2-curl-probes.log (root vs /some-random-page)
content-security-policy: ... 'nonce-MWY1MjlhZDYtYWQyMy00ZjJjLWFlMzktZTEyZjdkZWIyNTgx' ...
content-security-policy: ... 'nonce-YjlkYTRiMmItMDIzOC00M2RhLWFlODYtYTM1NmE5NGZmYjVm' ...
```

**Evidence:** `evidence/r1-nonce-freshness.txt`, `evidence/r1-curl-root-headers.txt`, `evidence/r2-curl-probes.log`, `proxy.ts:37`

---

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rendered HTML of `/` on both the dev server (r1) and the production server (r2) — all script tags nonced with the value from the same response's CSP header, and no app code reads `x-nonce`; does not establish browser-side execution of those scripts (no browser in the sandbox).
**Replicate verdicts:** r1=Verified · r2=Verified

r2, production server: every generated `<script>` (and stylesheet `<link>`) carries a nonce
byte-identical to the same response's CSP header:

```
// evidence/r2-root-headers.txt
content-security-policy: default-src 'self'; script-src 'self' 'nonce-NzhmNmUwMjEtNWM5Zi00Nzk1LWIzMTgtNzhmODZkOGZkM2M1' 'strict-dynamic'; ...
```

```
// evidence/r2-html-nonce-check.log (script tags extracted from r2-root-page.html)
<script src="/_next/static/chunks/0_0neb_tu2q4s.js" async="" nonce="NzhmNmUwMjEtNWM5Zi00Nzk1LWIzMTgtNzhmODZkOGZkM2M1">
```

- Command: `curl -s -m 20 -D r2-root-headers.txt http://localhost:4231/ -o r2-root-page.html`
- cwd: `/workspace` (server on port 4231) · exit code: 0 · timestamp: 2026-08-18T06:27:56Z

r1, dev server: the audit over the captured body (`evidence/r1-script-nonce-audit.txt`,
2026-08-18T06:32:40Z, exit 0) shows 36 `<script>` tags, 0 without a `nonce=` attribute, and a
single distinct nonce equal to the response CSP header's:

```
// evidence/r1-script-nonce-audit.txt
$ grep -oP "<script[^>]*>" r1-curl-root-body.html | wc -l
36
$ ... | grep -vc "nonce=" (tags WITHOUT nonce)
0
```

Nothing in `app/` reads `x-nonce` — a repo-wide grep finds the header name only where
`proxy.ts` sets it and where this comment mentions it (paraphrased — no quote available
because the claim covers absence of code: r2's `rg -rn "x-nonce" app proxy.ts` returns only
the `proxy.ts` set-site and the `app/layout.tsx` comment). Mechanism corroborated in Next's
renderer, which extracts the nonce from the CSP header:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

**Evidence:** `evidence/r2-root-headers.txt`, `evidence/r2-root-page.html`, `evidence/r2-html-nonce-check.log`, `evidence/r2-dev-check.log`, `evidence/r1-script-nonce-audit.txt`, `evidence/r1-curl-root-headers.txt`, `evidence/r1-curl-root-body.html`, `evidence/r1-xnonce-probe.txt`, `node_modules/next/dist/server/app-render/app-render.js:166-167`, `proxy.ts:44-48`

---

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy)"

**Location:** `proxy.ts:5`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the installed Next 16.2.4 recognizes the root `proxy.ts` convention, compiled it, and executed it per matched request; does not cover the full deprecation timeline of `middleware.ts` (see Claim 16).
**Replicate verdicts:** r1=Verified · r2=Verified

The installed Next version is 16.2.4 (`"next": "16.2.4"`, `package.json`), and its constants
define the convention:

```js
// node_modules/next/dist/lib/constants.js:287-290
const MIDDLEWARE_FILENAME = 'middleware';
const PROXY_FILENAME = 'proxy';
```

r2's production build detected and compiled the file, labeling it:

```
// evidence/r2-build.log
ƒ Proxy (Middleware)
```

r1's dev server ran the file per request — the request log itemizes its time, e.g.
`GET / 200 in 5.3s (next.js: 4.8s, proxy.ts: 138ms, application-code: 384ms)`
(`evidence/r1-dev-server.log`). Next's own error text confirms the rename and links the
migration doc: `"Route segment config is not allowed in Proxy file at ... Learn more:
https://nextjs.org/docs/messages/middleware-to-proxy"`
(`node_modules/next/dist/build/analysis/get-page-static-info.js:576`).

**Evidence:** `package.json`, `node_modules/next/dist/lib/constants.js:287-290`, `node_modules/next/dist/build/analysis/get-page-static-info.js:576`, `evidence/r1-dev-server.log`, `evidence/r2-build.log`, `evidence/r2-curl-probes.log`

---

## Claim 4: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust. This keeps a hypothetical injected `<script>` tag from executing"

**Location:** `proxy.ts:7-10`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the served policy contains exactly the directives whose standard CSP3 semantics match this description and that all Next-generated scripts carry the matching nonce; does not cover actual in-browser enforcement (no browser in either replicate's sandbox).
**Replicate verdicts:** r1=Verified · r2=Verified

The served response header contains the claimed directive set (r1 dev capture, exit 0,
2026-08-18T06:22:56Z; r2 prod capture, exit 0, 2026-08-18T06:27:56Z):

```
// evidence/r1-curl-root-headers.txt
content-security-policy: default-src 'self'; script-src 'self' 'nonce-ZmMx...' 'strict-dynamic'; ...
```

built from:

```ts
// proxy.ts:22
`script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```

Under CSP3, this combination allows only nonce-carrying scripts, propagates trust from them
to scripts they load via non-parser-inserted APIs, and blocks parser-inserted markup such as
an injected `<script>` tag lacking the nonce (paraphrased — no quote available because these
are CSP Level 3 specification semantics enforced by the browser, not code in this repository;
both replicates recorded this paraphrase independently). The precondition — that Next's own
scripts are all nonce-tagged — was confirmed by execution in both replicates (Claim 2).
Confidence is Medium in both replicates because browser enforcement itself could not be
executed.

**Evidence:** `proxy.ts:7-10`, `proxy.ts:20-31`, `evidence/r1-curl-root-headers.txt`, `evidence/r1-script-nonce-audit.txt`, `evidence/r2-root-headers.txt`, `evidence/r2-html-nonce-check.log`

---

## Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** `proxy.ts:12-14`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the server-rendered HTML of the root page in both dev and production (r2) and the dev SSR capture (r1); does not establish client-side style injection after hydration or during dev HMR (curl cannot observe browser-side DOM mutations), which is why confidence is Medium rather than High.
**Replicate verdicts:** r1=Unverifiable · r2=Incorrect

Most-severe-wins: r2's executed refutation carries the cluster; r1's Unverifiable was scoped
to the browser-runtime remainder (client-side injection) that r2's Scope also excludes, and
r1's own dev-SSR observation (zero inline `<style>` elements, all CSS as external nonced
links) is consistent with r2's refutation.

r2's evidence: in both the production and dev server-rendered HTML, Tailwind's CSS arrives as
external stylesheets, not inline styles. Prod:

```
// evidence/r2-style-check.log
--- prod stylesheet links:
<link rel="stylesheet" href="/_next/static/chunks/0qqafo8jts909.css" nonce="NzhmNmUwMjEt..." data-precedence="next"/>
...
--- prod style element count:
0
```

Dev likewise has zero `<style>` elements and two `<link rel="stylesheet">` tags
(`evidence/r2-dev-check.log`, "style element count: 0"; matching r1's audit,
`evidence/r1-script-nonce-audit.txt`, "style tags in body: 0"). The inline styles that do
exist — and that do require `'unsafe-inline'` in `style-src` — are 4 `style="..."` attributes
emitted by the app's own components, not by Tailwind:

```
// evidence/r2-style-check.log (dev HTML, identical count in prod)
style="font-family:var(--font-serif, &#x27;EB Garamond&#x27;, serif)"
style="width:var(--rail-width);background:var(--rail-bg)"
```

These originate from `style={{...}}` props in app components — e.g.
`app/components/layout/IconRail.tsx`, `app/components/panels/ArtifactPanelShell.tsx`
(paraphrased — no quote available because the attribution spans several component files found
via `rg -ln "style=\{\{" app`). So the carve-out is still needed, but for the app's own
inline style attributes; a reader acting on the comment (e.g., attempting to tighten
style-src by reworking Tailwind's shipping) would be misled about where the inline styles
come from.

- Commands (r2): `curl -s -D r2-dev-headers.txt http://localhost:4232/ -o r2-dev-page.html` (exit 0, 2026-08-18T06:32:25Z); style extraction into `r2-style-check.log` (2026-08-18T06:32:41Z)
- cwd: `/workspace` (dev server cwd `/workspace/external/cc-review-eval/mfc-csp`)

**Evidence:** `proxy.ts:12-14`, `proxy.ts:23`, `evidence/r2-style-check.log`, `evidence/r2-dev-check.log`, `evidence/r2-dev-page.html`, `evidence/r2-root-page.html`, `evidence/r1-script-nonce-audit.txt`, `evidence/r1-curl-root-body.html`, `package.json`

---

## Claim 6a: "`connect-src 'self'` is sufficient because Anthropic / ... / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:16-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers static import/call-site analysis of the current codebase (Anthropic/OpenRouter clients imported only by server-side modules and API routes; browser code fetches only relative `/api/...` URLs); does not establish runtime-constructed URLs or future additions.
**Replicate verdicts:** r1=Verified · r2=Verified

The only absolute third-party URL in browser-reachable code paths is the OpenRouter constant,
and it lives in the server-side LLM module alongside the Anthropic SDK import:

```ts
// app/lib/llm/callLlm.ts:2,7
import Anthropic from "@anthropic-ai/sdk";
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

`callLlm`/`streamLlm`/`OPENROUTER_API_URL` are imported exclusively from `app/api/**/route.ts`
files — a grep over `app/components` and `app/hooks` finds zero importers, while the same
grep over `app/api` returns seven route files (paraphrased — no quote available because the
claim covers absence of code; r1's independent grep classification across ~15 modules found
every match server-side with no `"use client"` directive). Client-side fetches all target
relative API paths, e.g.:

```ts
// app/lib/formalization/api.ts:104
  const res = await fetch("/api/verification/lean", {
```

A repo-wide grep for `https?://` in `app/components`, `app/hooks`, `app/lib` (excluding
tests) finds only the OpenRouter constant above and two SVG `xmlns` attributes (paraphrased —
no quote available because the claim covers absence of matching grep results).

**Evidence:** `proxy.ts:16-17`, `app/lib/llm/callLlm.ts:1-14`, `app/lib/llm/streamLlm.ts`, `app/lib/types/artifacts.ts:192-198`, `app/lib/formalization/api.ts:104`, `app/hooks/useDecomposition.ts:129-130`, `app/api/` (route importers)

---

## Claim 6b: "...OpenAlex calls..." (that OpenAlex calls exist in this codebase)

**Location:** `proxy.ts:16`
**Type:** Reference / Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of any OpenAlex integration anywhere in the repository and its full git history; does not dispute the sufficiency of `connect-src 'self'` (which holds vacuously regardless).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect

No OpenAlex call, client, URL, or symbol exists anywhere in the repository — a
case-insensitive repo-wide search (excluding `node_modules`/`.next`) matches only this
comment line itself, and `git log --all -S "openalex" -i` shows the string only ever entered
the repository in commit 9b4e453, the commit that added `proxy.ts` (paraphrased — no quote
available because the claim covers absence of code: both replicates' searches returned no
results outside the comment under check). The comment names a third-party integration the
project does not have. The surrounding conclusion is unaffected — with no OpenAlex calls at
all, `connect-src 'self'` remains sufficient — but the reference itself is fabricated
relative to this codebase.

**Evidence:** `proxy.ts:16-17`, repository-wide grep (no matches), `git log --all -S "openalex"`, `app/lib/llm/callLlm.ts:7` (the real third-party endpoints for contrast)

---

## Claim 7a: "Generate a fresh nonce per request."

**Location:** `proxy.ts:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers matched requests against the dev server; does not cover excluded routes (which get no nonce at all — see Claim 9).
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection

r1 executed: consecutive requests produced distinct nonces (`evidence/r1-nonce-freshness.txt`,
curl exit 0, 2026-08-17 ~23:23 local), consistent with the per-invocation generation in the
code:

```ts
// proxy.ts:37
const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

(r2 did not harvest this comment as a separate claim, but its production-server probes at
Claim 1c independently observed distinct per-request nonces.)

**Evidence:** `evidence/r1-nonce-freshness.txt`, `evidence/r1-curl-root-headers.txt`, `proxy.ts:37`

---

## Claim 7b: "crypto.randomUUID and Buffer are both available in the ... runtime that Next proxy runs in."

**Location:** `proxy.ts:35-37`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers availability of both APIs in the runtime that actually executed the proxy in these runs (dev server in r1, production server in r2 — Node.js per Claim 7c); does not establish availability in an Edge deployment of the same code.
**Replicate verdicts:** r1=Verified · r2=Verified

The nonce line exercises both APIs on every request:

```ts
// proxy.ts:37
const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

Every probed response in both replicates carried a well-formed base64-of-UUID nonce — e.g.
`'nonce-MWY1MjlhZDYtYWQyMy00ZjJjLWFlMzktZTEyZjdkZWIyNTgx'` (`evidence/r2-curl-probes.log`),
which decodes to a UUID string (paraphrased — no quote available because the decode is an
observation about the captured value, not repo code: base64 of
`1f529ad6-ad23-4f2c-ae39-e12f7deb2581`). Had either API been missing, the proxy would have
thrown and no CSP header would appear; r1's dev-server log shows no runtime errors from
`proxy.ts` (`evidence/r1-dev-server.log`).

**Evidence:** `proxy.ts:37`, `evidence/r1-curl-root-headers.txt`, `evidence/r1-nonce-freshness.txt`, `evidence/r1-dev-server.log`, `evidence/r2-curl-probes.log`

---

## Claim 7c: "...the Edge runtime that Next proxy runs in."

**Location:** `proxy.ts:35-36`
**Type:** Behavioral / Reference / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which runtime Next 16.2.4 assigns to this repo's proxy (no runtime override is configured in `proxy.ts`); does not affect Claim 7b (both APIs are native to Node.js, so the code works regardless) and does not establish behavior on other hosting platforms or Next versions.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect (r2 numbered this cluster Claim 7a in its report)

Next 16 runs the proxy on the Node.js runtime, not the Edge runtime. r2's executed build
manifest records it directly:

```json
// .next/server/functions-config-manifest.json (generated by r2's executed build)
"functions": {
    "/_middleware": {
      "runtime": "nodejs",
```

r1's static evidence — Next's own build analysis states this unconditionally:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:576
const message = `Route segment config is not allowed in Proxy file at "${resolvedPath}". Proxy always runs on Node.js runtime. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`;
```

`proxy.ts` exports no `runtime` config of its own — its `config` export contains only
`matcher` (`proxy.ts:52-64`). A reader acting on the comment (e.g., assuming Edge-runtime API
constraints apply, avoiding Node-only APIs, or debugging Edge-specific limits) would be
misled; in fact the opposite holds — full Node.js APIs are available, and `Buffer` is native
rather than an Edge polyfill.

- Command (r2): `NEXT_FONT_GOOGLE_MOCKED_RESPONSES=.../r2-font-mock.js npm run build` (manifest read post-build)
- cwd: `/workspace/external/cc-review-eval/mfc-csp` · exit code: 0 · timestamp: 2026-08-18T06:24:01Z

**Evidence:** `node_modules/next/dist/build/analysis/get-page-static-info.js:576`, `node_modules/next/dist/lib/constants.js:287-290`, `evidence/r2-build.log`, `.next/server/functions-config-manifest.json` (build artifact), `proxy.ts:52-64`

---

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `x-nonce` set on the forwarded request headers is readable via `headers()` in a server component (r1's dev-server probe) and that the code uses Next's documented request-header-override mechanism (r2, static); does not establish that any current layout consumes it (none does — `app/layout.tsx:30` says it is not needed), nor `<Script>`-tag propagation, which no code exercises.
**Replicate verdicts:** r1=Verified (executed, High) · r2=Verified (static, Medium)

r1 executed via a temporary probe page (`app/r1probe/page.tsx`, created for this check and
deleted afterward) that rendered
`JSON.stringify({ xNonce: h.get("x-nonce"), requestCsp: h.get("content-security-policy") })`
from `await headers()`. Command: `curl -s -m 120 http://localhost:4101/r1probe` (cwd clone,
exit 0, HTTP 200, 2026-08-17 ~23:28 local). The captured body shows the header round-trip,
with `xNonce` equal to the nonce in that response's CSP header:

```
// evidence/r1-xnonce-probe.txt
xNonce&quot;:&quot;MWUxMTYyNzctMzEwYS00ZWNmLWE1MTQtZDIwOTU4ZDljOGU4&quot;,&quot;requestCsp&quot;:&quot;default-src &#x27;self&#x27;; script-src &#x27;self&#x27; &#x27;nonce-MWUxMTYyNzctMzEwYS00ZWNmLWE1MTQ...
```

matching the setter:

```ts
// proxy.ts:41-42
const requestHeaders = new Headers(request.headers);
requestHeaders.set("x-nonce", nonce);
```

r2's static corroboration — Next's own types document the override channel:

```ts
// node_modules/next/dist/server/web/spec-extension/response.d.ts:37-41
interface MiddlewareResponseInit extends globalThis.ResponseInit {
    /**
     * These fields will override the request from clients.
     */
    request?: ModifiedRequest;
}
```

The merged verdict carries r1's executed evidence and High confidence: r1's probe supplies
the end-to-end observation r2 marked as its reason for Medium confidence.

**Evidence:** `evidence/r1-xnonce-probe.txt`, `evidence/r1-xnonce-probe-headers.txt`, `proxy.ts:39-48`, `node_modules/next/dist/server/web/spec-extension/response.d.ts:37-41`, `node_modules/next/dist/server/web/spec-extension/response.js:30-40`

---

## Claim 9: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches..."

**Location:** `proxy.ts:52-63`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers matcher inclusion/exclusion for the probed route classes on both the dev server (r1: `/`, `/api/analytics`, `/favicon.ico`, `/_next/static`, `/_next/image`, prefetch variants) and the production server (r2: page, 404 page, `/api` route, favicon, `/_next/static`, prefetch variants); does not verify the parenthetical rationales ("they don't render HTML", "would burn a nonce") or exhaustively cover all route shapes.
**Replicate verdicts:** r1=Verified · r2=Verified

The matcher:

```ts
// proxy.ts:55-61
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```

r1's dev-server probe series (`curl`, exit 0 per probe, 2026-08-17 23:23–23:31 local;
`evidence/r1-matcher-probes.txt`):

```
== GET / (page)
HTTP/1.1 200 OK
content-security-policy: default-src 'self'; script-src 'self' 'nonce-...' 'strict-dynamic'; ...
== GET /api/analytics
HTTP/1.1 200 OK
== GET /_next/image
HTTP/1.1 200 OK
Content-Security-Policy: script-src 'none'; frame-src 'none'; sandbox;
```

Only the page navigation received the proxy's CSP; API, favicon, `_next/static`, and both
prefetch-headered requests received none, and `/_next/image` received only Next's image
optimizer's own built-in restrictive CSP. r2 reproduced the same pattern against the
production server (2026-08-18T06:24:35Z–06:27:18Z, `evidence/r2-curl-probes.log`), adding
`GET /some-random-page` → 404 **with** CSP header (not-found pages are page navigations) and
noting one server quirk: `next-router-prefetch: 1` without an `RSC` header hung until curl's
timeout (exit 28) — unrelated to the matcher; the RSC variant demonstrates the skip
(paraphrased — no quote available because the negative cases are the absence of a header line
in the captured responses; see `r2-curl-probes.log` sections `api-analytics`, `favicon`,
`static-asset`, `prefetch-purpose`). The dev-server log corroborates: matched requests
itemize `proxy.ts` time while `GET /api/analytics` shows no `proxy.ts` component
(`evidence/r1-dev-server.log`).

**Evidence:** `evidence/r1-matcher-probes.txt`, `evidence/r1-dev-server.log`, `evidence/r2-curl-probes.log`, `evidence/r2-build.log` (matcher compiled into `functions-config-manifest.json` with the same source and `missing` conditions), `proxy.ts:51-63`

---

## Claim 10: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit 9b4e453 (commit message)
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers greps for the three named mechanisms in `app/` and KaTeX's effective trust setting; does not establish the absence of other XSS vectors (that is a security-review question, out of scope).
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection

`dangerouslySetInnerHTML` and `rehype-raw`/`rehypeRaw`: zero matches anywhere under `app/` or
in `package.json` dependencies (paraphrased — no quote available because the claim covers
absence of code: `rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw" app` and the
package.json grep return nothing). KaTeX is used via `rehype-katex` with no options object:

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

`Boolean(undefined)` is `false`, so the effective setting is `trust: false` — the claim holds
as the default rather than an explicit option, which does not change the guarantee.

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:6-10`, `node_modules/katex/dist/katex.mjs:349-350`

---

## Claim 11: "middleware.ts builds with a deprecation warning"

**Location:** commit 9b4e453 (commit message)
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the presence of the deprecation-warning code path in the installed Next 16.2.4; does not establish the warning actually firing, because executing it was blocked.
**Replicate verdicts:** r1=— · r2=Unverifiable · single-replicate detection

This is an executable guarantee ("builds with a warning"), so under the mandatory-execution
rule the verdict is capped at Unverifiable from static reading: executing it would require
creating a `middleware.ts` in the clone, and this review must leave the shared clone
unmodified (another replicate runs servers from the same working tree) — that is the specific
blocker. Static evidence strongly supports the claim: the installed Next's build path
contains exactly this warning:

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
**Scope:** Covers the production build/serve of the root page in r2's sandbox (header emitted, every generated script tag nonce-tagged with the matching value); does not establish browser-side enforcement or behavior on other routes' client-side navigations.
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection

Reproduced independently by r2: the prod server emits the CSP header
(`evidence/r2-root-headers.txt`, quoted at Claim 2), and every `<script>` tag in the
generated HTML carries the matching nonce — the extracted script-tag list shows a nonce
attribute on each of the 15+ script tags and `rg -o 'nonce="[^"]*"' | sort -u` yields exactly
one value, equal to the header's (`evidence/r2-html-nonce-check.log`; quoted at Claim 2).

- Commands: build (exit 0, 2026-08-18T06:24:01Z, `r2-build.log`); `curl -s -m 20 -D r2-root-headers.txt http://localhost:4231/ -o r2-root-page.html` (exit 0, 2026-08-18T06:27:56Z)
- cwd: `/workspace/external/cc-review-eval/mfc-csp` (build), `/workspace` (curl)

**Evidence:** `evidence/r2-build.log`, `evidence/r2-root-headers.txt`, `evidence/r2-html-nonce-check.log`

---

## Claim 13: "No behavior change; CSP directives preserved exactly." (cleanup commit)

**Location:** commit d90d6bb (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the b25e939→d90d6bb diff of `proxy.ts` and `app/layout.tsx`; does not establish equivalence beyond those two files (no other files changed in that commit per its diffstat).
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection

The full diff of the cleanup commit touches only comments, an explicit return type, and
inlining of a single-use local — the directive-building code and every directive string are
untouched:

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
Claims 1a-2's discussion of the current text).

**Evidence:** commit range `b25e939..d90d6bb` (`git diff`), `proxy.ts:34-49`

---

## Claim 14: "Lint clean"

**Location:** commit d90d6bb (commit message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `npm run lint` on the checked-out HEAD in r2's sandbox; does not establish which warnings existed at commit time versus environment differences.
**Replicate verdicts:** r1=— · r2=Mostly accurate · single-replicate detection

`npm run lint` exits 0 with zero errors, but it is not literally clean — two pre-existing
warnings fire in a file untouched by this diff:

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

**Evidence:** `evidence/r2-lint.log`

---

## Claim 15: "221/221 tests pass"

**Location:** commit d90d6bb (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the vitest run summary on the checked-out HEAD in r2's sandbox; does not establish a clean process exit here (the non-zero exit code traced to sandbox path pollution outside the repo, not to any test).
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection

The suite reports exactly the claimed count:

```
// evidence/r2-test.log
 Test Files  24 passed (24)
      Tests  221 passed (221)
```

`npm test` nonetheless exited 1 in r2's sandbox because vitest's post-run jsdom presence
check tripped over an invalid `package.json` outside the repository:

```
// evidence/r2-test.log
Error: Invalid package config /workspace/external/package.json while importing /workspace/external/cc-review-eval/mfc-csp. Unexpected end of JSON input
...
 MISSING DEPENDENCY  Cannot find dependency 'jsdom'
```

`jsdom` is in fact installed (`node_modules/jsdom/package.json` exists — paraphrased, no
quote available because the evidence is the file's existence, checked with `ls`). All 221
tests ran and passed; the exit code reflects the environment, not the tests — hence Medium
confidence rather than High.

- Command: `npm test`
- cwd: `/workspace/external/cc-review-eval/mfc-csp` · exit code: 1 (environment artifact, see above) · timestamp: 2026-08-18T06:34:34Z

**Evidence:** `evidence/r2-test.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`app/layout.tsx:27`): Proxy execution is controlled by the matcher, not by the layout's rendering mode — the opt-out keeps the rendered HTML's nonce fresh; it does not make proxy.ts run. Tighten the comment's causal wording. (r1=Incorrect, r2=Mostly accurate as compound; most-severe-wins.)
- **Claim 5** (`proxy.ts:12-14`): Tailwind v4 does not emit inline styles here — it ships external stylesheets in both dev and prod; the `'unsafe-inline'` carve-out is actually needed for the app's own `style={{...}}` attributes (4 in the root page). Reword the comment to attribute the carve-out correctly. (r1=Unverifiable, r2=Incorrect via executed dev+prod probes; most-severe-wins.)
- **Claim 6b** (`proxy.ts:16`): No OpenAlex integration exists anywhere in the repo or its history — drop OpenAlex from the comment or add the integration it presumes. (Both replicates: Incorrect, High.)
- **Claim 7c** (`proxy.ts:35-36`): Next 16 proxy always runs on the Node.js runtime, not the Edge runtime — per Next's own source, the middleware-to-proxy migration doc, and r2's executed build manifest (`"runtime": "nodejs"`). (Both replicates: Incorrect, High.)

### Stale
- None.

### Mostly Accurate
- **Claim 14** (commit d90d6bb): "Lint clean" = exit 0 with 0 errors, but 2 pre-existing warnings in `app/page.tsx`. (Single-replicate: r2.)

### Unverifiable
- **Claim 11** (commit 9b4e453): "middleware.ts builds with a deprecation warning" — execution would require adding a `middleware.ts` to the shared clone, which the review must leave unmodified; the exact warning string exists in the installed Next 16.2.4 build path (`node_modules/next/dist/build/index.js:651`). (Single-replicate: r2.)

---

## Verdict stability

- **Total clusters:** 20
- **Clusters where all reporting replicates agreed:** 16 (9 of the 13 clusters both replicates surfaced, plus 7 single-replicate detections, which agree trivially)
- **Clusters where verdicts disagreed:** 4
  - **Claim 1a** (static-rendering opt-out): r1=Unverifiable · r2=Verified → merged **Verified**. Deliberate deviation from mechanical most-severe ordering (Unverifiable > Verified), recorded here: r1's Unverifiable was the mandatory-execution cap with "production build blocked (Google Fonts fetch)" as its named blocker, and r1 stated the build's static/dynamic route marker would settle the claim; r2 executed exactly that probe (mocked-fonts build, exit 0) and it verified. An execution-blocked Unverifiable is a missing-evidence state, not a more-severe finding — letting it override the supplied execution would discard the evidence the cap existed to demand.
  - **Claim 1b** (proxy runs on every request): r1=Incorrect (atomized) · r2=Mostly accurate (compound) → merged **Incorrect** per most-severe-wins and the decision-033 compound/atomic rule (the compound clusters with each atom; the sub-claim's Incorrect beats the compound's Mostly accurate). Both replicates agreed on the underlying mechanism reading.
  - **Claim 1c** (fresh per-request nonce): r1=Verified (atomized) · r2=Mostly accurate (same compound as 1b) → merged **Verified** for this atom; r2's evidence for this half (distinct nonces per request, executed) matches r1's, and the compound's imprecision is fully carried by Claim 1b.
  - **Claim 5** (Tailwind inline styles): r1=Unverifiable · r2=Incorrect → merged **Incorrect** per most-severe-wins, carrying r2's executed dev+prod refutation. r1's dev-SSR observation (zero inline `<style>` elements) is consistent with r2's; r1 only declined to verdict for lack of a browser to rule out client-runtime injection, which r2's Scope also excludes (hence merged Confidence: Medium).
- **Agreement rate:** 16/20 = 80% overall; 9/13 ≈ 69% among clusters surfaced by both replicates.
- Confidence-only divergence (not a verdict disagreement): Claim 8 — r1 Verified/High (executed probe) vs r2 Verified/Medium (static); merged carries the executed High.
