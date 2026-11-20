Commit: d90d6bb

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-csp`, detached at d90d6bb)
**Scope:** d86d2dc..d90d6bb (3 commits; `proxy.ts` new, `app/layout.tsx` modified), plus the three commit messages
**Checked:** 2026-11-19
**Total claims checked:** 22
**Summary:** 10 verified, 3 mostly accurate, 0 stale, 6 incorrect, 3 unverifiable

Sandbox note: the worktree has no `node_modules` (no Next.js source to read, no build, lint or test possible) and the sandbox has no network; the npm cache holds no Next tarball. Every claim about Next.js framework internals is therefore checked against Next.js 16 documented behavior from reviewer knowledge, tagged as such, and capped at Medium confidence. `docs/reviews/hallucination-patterns.md` does not exist in the reviewed repo; it was not created, because the worktree is read-only for this pass.

---

## Claim 1a: "Opt this layout out of static rendering" (via `await headers()`)

**Location:** `app/layout.tsx:27,31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that calling the dynamic API `headers()` in the root layout makes the route render dynamically; it does not establish the build output (no `next build` was possible) or that dynamic rendering alone makes Next put the nonce on its scripts (see Claim 2).

```tsx
// app/layout.tsx:22-31
export default async function RootLayout({
  ...
  await headers();
```
(excerpt ends :31; enclosing RootLayout() continues to :42 — read; the rest renders `<html>/<body>{children}` and never uses the result.)

`headers()` from `next/headers` is a request-time dynamic API, and calling it in a server component opts the route out of static prerendering (paraphrased — no quote available because Next.js source is not present in the sandbox; this is documented Next.js App Router behavior). The returned value is discarded (`app/layout.tsx:31`), which is fine for that purpose.

**Evidence:** `app/layout.tsx:3`, `app/layout.tsx:22-42`

---

## Claim 1b: "so proxy.ts runs on every request and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:27-28`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the causal link stated (dynamic rendering → proxy runs); it does not dispute that dynamic rendering is needed for nonces for a different reason.

Proxy (formerly middleware) runs before routing on every request that its `config.matcher` selects, whether the page is static or dynamic (paraphrased — no quote available because Next.js source is not present in the sandbox; documented behavior). Whether the proxy runs is set only by the matcher:

```ts
// proxy.ts:55-62
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [ ... ],
    },
  ],
```

The real reason dynamic rendering is needed is that the HTML has to be rendered per request, so that the per-request nonce can be written into the `<script nonce>` attributes. A statically prerendered page would still get a fresh CSP header from the proxy, but its cached HTML would carry no matching nonce. The stated mechanism is wrong. A reader who removes `await headers()` because "the matcher already runs the proxy" would be acting on the right fact, but this comment teaches the wrong model.

**Evidence:** `app/layout.tsx:27-31`, `proxy.ts:51-64`

---

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers where Next reads the nonce from and whether this proxy supplies it there; it does not establish the runtime outcome (which needs a prod build plus `curl`, blocked here; see Claim 14).

At render time Next.js takes the nonce from the **request's** `Content-Security-Policy` header (App Router render reads the incoming request headers, and the Next.js CSP guide's proxy example sets the CSP on the forwarded request headers for exactly this reason) (paraphrased — no quote available because Next.js source is not present in the sandbox; documented behavior). This proxy sets the CSP only on the **response** and forwards only `x-nonce` on the request:

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
(excerpt ends :48; enclosing proxy() closes at :49 — read.)

So the stated mechanism ("from the response's CSP header") is wrong. If Next reads only the request header, as documented, it finds no nonce, and its bootstrap/inline flight scripts go out untagged. Under `script-src 'self' 'nonce-…' 'strict-dynamic'` (`proxy.ts:22`), CSP3 browsers ignore `'self'` when `'strict-dynamic'` is present, so those scripts would be blocked and the app would fail to hydrate. This contradicts the 9b4e453 claim that the build was checked (Claim 14), so it needs execution to settle. It is the highest-stakes item in this report.

**Evidence:** `app/layout.tsx:28-31`, `proxy.ts:22`, `proxy.ts:41-48`

---

## Claim 3: "we don't need to read x-nonce here ourselves"

**Location:** `app/layout.tsx:30`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no app code renders its own `<script>` / `next/script` that would need the nonce passed by hand; it does not establish that Next's own scripts get the nonce (Claim 2).

`rg -n "next/script|<script" app` matches only the comment itself at `app/layout.tsx:29` (paraphrased — no quote available because the claim covers absence of code, no matching grep results). No app-authored script needs `x-nonce`.

**Evidence:** `app/layout.tsx:29`

---

## Claim 4: "CSP proxy (Next.js 16 renamed Middleware → Proxy)" / commit 9b4e453 "File is named proxy.ts because Next.js 16 renamed Middleware to Proxy"

**Location:** `proxy.ts:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the rename and that the project is on Next 16; it does not establish the deprecation-warning half of the commit sentence (Claim 12).

`package.json` pins `"next": "16.2.4"`. In Next.js 16, `middleware.ts` / `export function middleware` became `proxy.ts` / `export function proxy` (paraphrased — no quote available because Next.js source/docs are not in the sandbox; Next.js 16 release notes). The file exports the new name: `export function proxy(request: NextRequest): NextResponse {` (`proxy.ts:34`).

**Evidence:** `package.json` (dependencies.next), `proxy.ts:34`

---

## Claim 5: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust"

**Location:** `proxy.ts:7-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the CSP3 semantics of `'nonce-…' 'strict-dynamic'` as written at `proxy.ts:22`; it does not establish that Next actually tags its scripts under this proxy (Claim 2) or behavior in pre-CSP3 browsers, where `'self'` is the fallback.

```ts
// proxy.ts:22
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```
Under CSP Level 3, `'strict-dynamic'` makes the browser ignore host/`'self'` sources, allow nonce-matched scripts, and pass trust to scripts those scripts insert without the parser (paraphrased — no quote available because this is CSP specification behavior, not repo code).

**Evidence:** `proxy.ts:19-32`

---

## Claim 6: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles."

**Location:** `proxy.ts:12-14`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the stated cause; it does not dispute that `'unsafe-inline'` is needed today (it is, for other reasons).

Tailwind v4 runs here as a PostCSS plugin that compiles `globals.css` into a stylesheet:

```js
// postcss.config.mjs:1-5
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```
```css
/* app/globals.css:1-2 */
@import "tailwindcss";
@plugin "@tailwindcss/typography";
```

Production ships that as a linked CSS file, not inline styles (paraphrased — no quote available because build output cannot be produced without node_modules). The inline styles that actually need `'unsafe-inline'` are React `style={…}` attributes: 31 occurrences across `app/**/*.tsx`, for example `style={{ backgroundColor: status.color }}` (`app/components/panels/NodeDetailPanel.tsx:48`) and `style={{ lineHeight: 1.9, fontFamily: "inherit" }}` (`app/components/features/output-editing/LatexRenderer.tsx:31`). KaTeX output via `rehype-katex` and reactflow's positioning also use them (paraphrased — no quote available because they are library behaviors, not repo code). Style attributes cannot be covered by nonces at all, so the comment's "tightening to nonces would require rebuilding how Tailwind ships styles" is the wrong blocker. The real blocker is style attributes from app code and libraries, plus Next's dev-mode style injection.

**Evidence:** `postcss.config.mjs:1-5`, `app/globals.css:1-2`, `app/components/panels/NodeDetailPanel.tsx:48`, `app/components/features/output-editing/LatexRenderer.tsx:31`

---

## Claim 7a: "Anthropic / ... / OpenRouter calls are server-to-server (Next API routes)"

**Location:** `proxy.ts:16-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Anthropic SDK and OpenRouter `fetch` sites; it does not establish that no other browser-side connection exists (Claim 7c).

The only third-party calls are in `app/lib/llm/callLlm.ts` (`fetch(OPENROUTER_API_URL, …)` at :164, `import Anthropic from "@anthropic-ai/sdk"` at :2) and `app/lib/llm/streamLlm.ts:249`. Both import Node's `crypto` (`import { randomUUID } from "crypto";`, line 1 of each), and both are imported only from `app/api/**/route.ts` files and from `app/lib/formalization/artifactRoute.ts` (paraphrased — no quote available because the importer set spans 9 files, listed by `rg -n "streamLlm|callLlm" app`). `app/lib/formalization/api.ts:3` imports only a type.

**Evidence:** `app/lib/llm/callLlm.ts:2,164`, `app/lib/llm/streamLlm.ts:1,249`, `app/api/edit/inline/route.ts:2`, `app/lib/formalization/artifactRoute.ts:2-4`

---

## Claim 7b: "... OpenAlex ... calls are server-to-server"

**Location:** `proxy.ts:16`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of OpenAlex code at d90d6bb; it does not establish the transport of the OpenAlex integration on unmerged branches.

There is no OpenAlex code in the reviewed tree: `rg -i openalex` matches only `proxy.ts:16` (paraphrased — no quote available because the claim covers absence of code). OpenAlex work exists only on branches that are not ancestors of d90d6bb (`git merge-base --is-ancestor f82b6f8 d90d6bb` fails; f82b6f8 is on `origin/feat/evidence-integration`). The comment describes an integration that has not landed. Precise version: name only Anthropic/OpenRouter, or say OpenAlex is pending evidence-integration.

**Evidence:** `proxy.ts:16`

---

## Claim 7c: "`connect-src 'self'` is sufficient" (also commit 9b4e453: "connect-src is just 'self' because all external API calls ... go server-to-server")

**Location:** `proxy.ts:16`, `proxy.ts:26`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers browser-side `fetch` sites in `app/`; it does not cover connections opened inside third-party libraries beyond the `fetch(dataUrl)` sites named.

The browser code calls `fetch()` on a `data:` URL. `connect-src` governs `fetch()`, and `'self'` does not match the `data:` scheme:

```ts
// app/lib/utils/exportGraph.ts:20-26
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
  triggerDownload(blob, filename);
```
(the same pattern is at `app/lib/utils/exportGraph.ts:33-38` in `graphToPngBlob`.) These are reached from the graph PNG download (`app/components/panels/GraphPanel.tsx:102-104`) and from export-all (`app/lib/utils/exportAll.ts:64`). Under `"connect-src 'self'"` (`proxy.ts:26`), both fetches are refused, so PNG export and the export-all zip break. The server-to-server premise holds for third-party APIs (Claim 7a), but "sufficient" is false for this policy.

**Evidence:** `proxy.ts:26`, `app/lib/utils/exportGraph.ts:20-38`, `app/components/panels/GraphPanel.tsx:102-104`, `app/lib/utils/exportAll.ts:64`

---

## Claim 8a: "the Edge runtime that Next proxy runs in"

**Location:** `proxy.ts:35-36`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which runtime Next 16 proxy uses; it does not establish deploy-target specifics on Vercel.

In Next.js 16, `proxy.ts` runs on the Node.js runtime, which cannot be configured, and the Edge runtime is not supported for proxy (middleware.ts is kept for Edge users) (paraphrased — no quote available because Next.js source/docs are not in the sandbox; Next.js 16 upgrade guide). No `runtime` export appears in `proxy.ts` (`proxy.ts:51-64` exports only `config` with `matcher`). The comment names the wrong runtime. The conclusion about API availability still holds (Claim 8b).

**Evidence:** `proxy.ts:35-37`, `proxy.ts:51-64`

---

## Claim 8b: "crypto.randomUUID and Buffer are both available"

**Location:** `proxy.ts:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers availability of both globals in the Node.js runtime that proxy actually uses; it does not establish nonce entropy properties (base64 of the UUID's 36-char text form, not of raw bytes).

```ts
// proxy.ts:37
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```
`globalThis.crypto.randomUUID` and `Buffer` are both globals in Node ≥19 / the Node runtime Next 16 uses (paraphrased — no quote available because this is runtime platform behavior, not repo code).

**Evidence:** `proxy.ts:37`

---

## Claim 9: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-42`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `x-nonce` is forwarded and readable; it does not establish any consumer (there is none).

```ts
// proxy.ts:41-42
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
```
The header is forwarded and could be read. Nothing reads it: `rg -n "x-nonce"` matches only `proxy.ts:42` and the layout comment `app/layout.tsx:30`, which says the layout does not read it, and the repo renders no `<Script>` (Claim 3) (paraphrased — no quote available because the claim covers absence of code). Precise version: "forwarded for future `<Script>` use; currently unread."

**Evidence:** `proxy.ts:39-42`, `app/layout.tsx:30`

---

## Claim 10: "Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches"

**Location:** `proxy.ts:52-54`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the matcher's regex and `missing` conditions; it does not establish how Next 16 tags prefetch requests in practice (header names taken from the Next docs pattern).

```ts
// proxy.ts:57-61
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```
The three named exclusions are present. The comment leaves out that `_next/image` and `favicon.ico` are also skipped. The lookahead `(?!api…)` has no trailing slash, so it also skips any top-level path that merely starts with "api" (for example `/apiary`). No such page exists today: the only page is `app/page.tsx`, and every route handler is under `app/api/` (paraphrased — no quote available because this is about directory layout).

**Evidence:** `proxy.ts:51-64`

---

## Claim 11: commit 9b4e453 "no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false"

**Location:** `app/components/features/output-editing/LatexRenderer.tsx:6-10`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `app/`; it does not establish that libraries never inject HTML, and `trust:false` is KaTeX's default rather than an explicit setting.

`rg "dangerouslySetInnerHTML|rehype-raw|rehypeRaw" app` matches nothing (paraphrased — no quote available because the claim covers absence of code). The KaTeX plugin is passed with no options, so `trust` keeps its default of `false`:
```tsx
// app/components/features/output-editing/LatexRenderer.tsx:10
const rehypePlugins = [rehypeKatex];
```

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:6-10`

---

## Claim 12: commit 9b4e453 "middleware.ts builds with a deprecation warning"

**Location:** commit 9b4e453 message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Not established; execution required.

This is an executable claim about build output. It needs `next build` with a `middleware.ts`. Blocker: no `node_modules` in the worktree and no network to install them.

**Evidence:** `package.json` (next 16.2.4)

---

## Claim 13: commit 9b4e453 "Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached"

**Location:** commit 9b4e453 message; `app/layout.tsx:31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the rationale (cached HTML cannot carry a per-request nonce); it does not establish that Next then applies the nonce (Claim 2).

`await headers();` (`app/layout.tsx:31`) forces dynamic rendering. This rationale is the correct one, and it is what Claims 1b and 15b later misstate.

**Evidence:** `app/layout.tsx:31`

---

## Claim 14: commit 9b4e453 "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** commit 9b4e453 message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Not established; execution required. Static evidence leans against the nonce half.

This is an executable guarantee: `next build && next start`, then `curl` a page and compare the response CSP nonce with the `nonce=` attributes on the `<script>` tags. Blocker: no `node_modules`, no network. The header half is plausible from `proxy.ts:47`. The nonce half conflicts with Claim 2: the proxy never puts the CSP on the forwarded request headers (`proxy.ts:41-46`), which is where Next documents reading it.

**Evidence:** `proxy.ts:41-48`

---

## Claim 15a: commit d90d6bb "No behavior change; CSP directives preserved exactly."

**Location:** commit d90d6bb message; `proxy.ts:34-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the d90d6bb diff (`git diff 9b4e453 d90d6bb`); it does not mean the preserved behavior is correct.

The proxy hunk only adds `: NextResponse`, inlines `const csp = buildCsp(nonce);` into `response.headers.set("Content-Security-Policy", buildCsp(nonce));` (`proxy.ts:47`), and edits comments. `buildCsp` (`proxy.ts:19-32`) is untouched. The layout change is comment-only.

**Evidence:** `proxy.ts:19-32`, `proxy.ts:34-48`, `app/layout.tsx:27-30`

---

## Claim 15b: commit d90d6bb "headers() is called to opt out of static rendering so the proxy can attach per-request CSP"

**Location:** commit d90d6bb message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same as Claim 1b.

This is the same wrong mechanism as Claim 1b. The proxy attaches the CSP on every matched request regardless (`proxy.ts:47`, `proxy.ts:55-62`). Dynamic rendering is needed so the HTML carries the per-request nonce. That was the correct rationale in 9b4e453 (Claim 13), and this "correction" replaced it with a wrong one.

**Evidence:** `proxy.ts:47`, `proxy.ts:55-62`

---

## Claim 15c: commit d90d6bb "the nonce is only written, never read by the layout"

**Location:** commit d90d6bb message; `app/layout.tsx:31`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the layout and all of `app/`; no reader exists anywhere.

`await headers();` discards its result (`app/layout.tsx:31`). `x-nonce` is referenced only at `proxy.ts:42` and in comments (Claim 9).

**Evidence:** `app/layout.tsx:31`, `proxy.ts:42`

---

## Claim 16: commit d90d6bb "Lint clean; 221/221 tests pass."

**Location:** commit d90d6bb message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Not established; execution required.

This needs `npm run lint` and `npm test` (vitest). Blocker: no `node_modules`, no network to install. Note that no test in the diff exercises `proxy.ts` (paraphrased — no quote available because the diff adds no test files), so a pass would not cover the CSP behavior anyway.

**Evidence:** `package.json` (scripts.lint, scripts.test)

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`app/layout.tsx:27-28`): the proxy runs on every matched request whether or not the page is static. The layout must be dynamic so the HTML carries the nonce, not so the proxy runs.
- **Claim 2** (`app/layout.tsx:28-30`): Next reads the nonce from the request's CSP header, and the proxy sets the CSP only on the response (`proxy.ts:47`), so Next's scripts are likely left without a nonce and blocked under `'strict-dynamic'`.
- **Claim 6** (`proxy.ts:12`): Tailwind v4 (PostCSS) ships a stylesheet. The inline-style needs are React `style={}` attributes (31 sites), KaTeX and reactflow.
- **Claim 7c** (`proxy.ts:16,26`): `fetch(dataUrl)` in `app/lib/utils/exportGraph.ts:24,37` is blocked by `connect-src 'self'`, which breaks graph PNG export and export-all.
- **Claim 8a** (`proxy.ts:35-36`): Next 16 proxy runs on the Node.js runtime, not Edge.
- **Claim 15b** (commit d90d6bb): repeats the wrong mechanism from 1b and overwrote 9b4e453's correct rationale.

### Stale
- none

### Mostly Accurate
- **Claim 7b** (`proxy.ts:16`): OpenAlex code does not exist at d90d6bb. It is only on the unmerged `feat/evidence-integration` branch.
- **Claim 9** (`proxy.ts:39-40`): `x-nonce` is forwarded but nothing reads it, and there are no `<Script>` tags.
- **Claim 10** (`proxy.ts:52-54`): the comment omits the `_next/image` and `favicon.ico` skips, and the `api` lookahead also skips any top-level path starting with "api".

### Unverifiable
- **Claim 12** (commit 9b4e453): middleware.ts deprecation warning. Needs `next build`, which was blocked (no node_modules or network).
- **Claim 14** (commit 9b4e453): "Next applies the nonce to every script tag". Needs a prod build plus `curl`, which was blocked. Static evidence (Claim 2) contradicts it.
- **Claim 16** (commit d90d6bb): lint and 221/221 tests. Needs `npm run lint` and `npm test`, which were blocked.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: code-quality and security judgments beyond claim accuracy; the hallucination-pattern log update was skipped because the reviewed worktree is read-only and no Incorrect verdict is a fabricated symbol.
- Escalate: (1) Run a prod build and `curl` a page to check whether `<script nonce=…>` matches the response CSP (Claims 2/14). If it does not match, the app does not hydrate under this CSP, which blocks shipping, and the fix is to also set `Content-Security-Policy` on `requestHeaders`. (2) Graph PNG export and export-all break under `connect-src 'self'` (Claim 7c), so the policy needs `data:` (or `blob:`) in connect-src, or the code must stop fetching data URLs. (3) It is unchecked whether the pdfjs worker (`app/lib/utils/fileExtraction.ts:26`, `app/lib/utils/pdfPropositionParser.ts:443`) loads under `script-src` with `'strict-dynamic'` and no `worker-src`; this needs a browser check.
- Decisions I made: Next.js framework claims were verdicted from documented Next 16 behavior at Medium confidence, because there was no node_modules or network. OpenAlex was rated Mostly accurate rather than Incorrect, because the integration exists on an unmerged branch.
