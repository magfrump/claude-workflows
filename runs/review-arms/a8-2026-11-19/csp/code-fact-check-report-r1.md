Commit: d90d6bb

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree `wt-csp`, detached HEAD d90d6bb)
**Scope:** branch diff d86d2dc..d90d6bb (`app/layout.tsx`, `proxy.ts`) plus the three commit messages; consumer code under `app/` read for the client-side and consumer claims
**Checked:** 2026-11-19
**Total claims checked:** 17
**Summary:** 6 verified, 4 mostly accurate, 0 stale, 5 incorrect, 2 unverifiable

Sandbox note: the worktree has no `node_modules`, the npm cache holds no `next` tarball, and there is no network. Nothing could be built, linted or run. Claims about Next.js 16 framework internals rest on the documented Next.js contract (the official CSP guide and the Next 16 proxy docs), not on installed source. Confidence on those claims is capped at Medium for that reason.

No `docs/reviews/hallucination-patterns.md` was consulted: the brief allows writing only this file, and the reviewed repo's pattern log was not part of the scope.

---

## Claim 1a: "Opt this layout out of static rendering"

**Location:** `app/layout.tsx:27-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that calling the dynamic API `headers()` in the root layout makes every route under it dynamically rendered; does not establish behavior under `cacheComponents`/PPR (not enabled: `next.config.ts` is empty) and was not confirmed by a build.

```tsx
// app/layout.tsx:31
  await headers();
```

`next.config.ts` sets no options (`const nextConfig: NextConfig = { /* config options here */ };`, `next.config.ts:3-5`), so the default rule applies: calling a dynamic API such as `headers()` opts the route out of static prerendering (paraphrased — no quote available because this is Next.js framework behavior and the framework source is not installed in the sandbox).

**Evidence:** `app/layout.tsx:22-43`, `next.config.ts:1-7`

---

## Claim 1b: "so proxy.ts runs on every request" (static-rendering opt-out is what makes the proxy run)

**Location:** `app/layout.tsx:27-28`; commit 9b4e453 body ("Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached") is the accurate version of the same rationale
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the stated causal link between dynamic rendering and proxy execution; does not establish whether the per-request HTML actually carries the nonce (see Claim 2).

The proxy runs for every request its `matcher` selects, whether the page is statically or dynamically rendered. Proxy/middleware executes before the route cache is consulted (paraphrased — no quote available because this is framework request-pipeline behavior and the framework source is not installed). Its selection is set only by the matcher:

```ts
// proxy.ts:55-62
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
```

Dynamic rendering is needed so the HTML is rendered per request and can carry that request's nonce, instead of being served prerendered with no nonce or a stale one. Commit 9b4e453 said exactly this. The rewritten comment in d90d6bb replaced it with a mechanism that is wrong: the proxy would run on every request either way.

**Evidence:** `app/layout.tsx:27-31`, `proxy.ts:51-64`

---

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers where Next.js gets the nonce it applies to its scripts and whether this proxy supplies it there; does not establish runtime browser behavior, because no build or browser run was possible.

During rendering, Next.js reads the nonce from the **request's** `Content-Security-Policy` header, the one forwarded to the renderer. It does not read the response header. The official Next.js CSP guide's proxy example therefore sets the CSP on `requestHeaders` as well as on the response (paraphrased — no quote available because the Next.js source and docs are not present in the sandbox). This proxy puts the CSP only on the response and forwards only `x-nonce` on the request:

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

Next.js never reads `x-nonce`. That header name is the guide's convention for app code. Nothing in the repo reads it either (paraphrased — no quote available because the claim covers absence of code: `rg -n "x-nonce|nonce"` outside `node_modules` hits only `proxy.ts` and these layout comments). The renderer would therefore find no nonce and emit its bootstrap and inline flight scripts (`self.__next_f.push`) without one. Under `script-src 'self' 'nonce-…' 'strict-dynamic'` (`proxy.ts:22`), CSP3 browsers ignore `'self'` when `'strict-dynamic'` is present, so those scripts would be blocked and the app would not hydrate. A reader who trusts this comment would not think to forward the CSP on the request. This contradicts the 9b4e453 claim "Next applies the nonce to every <script> tag" (Claim 10). It is the highest-stakes item in this report and needs a real build plus a browser load to confirm.

**Evidence:** `app/layout.tsx:27-31`, `proxy.ts:22`, `proxy.ts:34-49`

---

## Claim 3: "Next.js 16 renamed Middleware → Proxy" / "middleware.ts builds with a deprecation warning"

**Location:** `proxy.ts:5`; commit 9b4e453 body
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the rename in Next.js 16 and that the project is on Next 16; does not establish the exact deprecation-warning text, which needs a build.

```json
// package.json:21
    "next": "16.2.4",
```

Next.js 16 renamed the `middleware` file convention to `proxy` (`proxy.ts`, exported function `proxy`) and deprecated `middleware.ts` (paraphrased — no quote available because this is release-level framework documentation, not repo code). The export name matches: `export function proxy(request: NextRequest): NextResponse {` (`proxy.ts:34`). No `middleware.ts` existed at the base (`git show d86d2dc:middleware.ts` → "does not exist"). The `middleware.ts` mention in commit b25e939's subject refers to an intermediate name inside this PR.

**Evidence:** `package.json:21`, `proxy.ts:5`, `proxy.ts:34`

---

## Claim 4: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust"

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the CSP semantics of the `script-src` directive as written (nonce plus `'strict-dynamic'`); does not establish that Next.js actually tags its scripts under this proxy (Claim 2 says it does not) or how workers such as the pdfjs worker are treated.

```ts
// proxy.ts:22
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```

With `'strict-dynamic'`, only nonce-bearing scripts and the scripts they load in a non-parser-inserted way are trusted. `'self'` is ignored by CSP3 browsers (paraphrased — no quote available because these are CSP Level 3 specification semantics). The sentence describes the policy correctly. Its premise that Next.js tags the scripts is the defect in Claim 2.

**Evidence:** `proxy.ts:7-10`, `proxy.ts:19-32`

---

## Claim 5: "Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** `proxy.ts:12-14`; commit 9b4e453 body ("deliberate carve-out for Tailwind v4")
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the stated reason `style-src` needs `'unsafe-inline'`; does not dispute that `'unsafe-inline'` is needed in practice.

Tailwind v4 is wired through PostCSS into the global stylesheet:

```js
// postcss.config.mjs:1-5
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

```css
/* app/globals.css:1 */
@import "tailwindcss";
```

That compiles to a CSS file which Next.js serves as a `<link rel="stylesheet">` in production. Tailwind itself does not emit inline styles or style attributes. Dev-mode `<style>` injection comes from Next/webpack HMR, not from Tailwind (paraphrased — no quote available because this is build-pipeline behavior and no build could run). What does require `'unsafe-inline'` is app and library code that writes inline `style` attributes: 31 `style={{` sites in `app/` (for example `style={{ lineHeight: 1.9, fontFamily: "inherit" }}`, `app/components/features/output-editing/LatexRenderer.tsx:32`), KaTeX's inline-styled output from `rehype-katex` (`LatexRenderer.tsx:6,10`), and React Flow's transform styles. The carve-out is needed, but the mechanism given for it is wrong, and tightening would be blocked by those style attributes, not by Tailwind.

**Evidence:** `proxy.ts:12-14`, `proxy.ts:23`, `postcss.config.mjs:1-7`, `app/globals.css:1-2`, `app/components/features/output-editing/LatexRenderer.tsx:1-40`

---

## Claim 6a: "Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party"

**Location:** `proxy.ts:16-17`; commit 9b4e453 body
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Anthropic and OpenRouter call sites and their importers; does not establish anything about OpenAlex, which has no code in the repo.

The only third-party fetches are in `app/lib/llm/`:

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

These are reached from API routes and from `app/lib/formalization/artifactRoute.ts`. The one client-side importer, `app/lib/formalization/api.ts`, imports only a type (`import type { LlmCallUsage } from "@/app/lib/llm/callLlm";`, `app/lib/formalization/api.ts:3`), and its fetches go to relative `/api/...` URLs. "OpenAlex" appears nowhere except this comment (paraphrased — no quote available because the claim covers absence of code: `rg -i openalex` outside `node_modules` hits only `proxy.ts`). Tighten the comment to name only the providers the code calls.

**Evidence:** `app/lib/llm/callLlm.ts:7`, `app/lib/llm/callLlm.ts:162-175`, `app/lib/llm/streamLlm.ts:249`, `app/lib/formalization/api.ts:1-12`

---

## Claim 6b: "`connect-src 'self'` is sufficient"

**Location:** `proxy.ts:16`, `proxy.ts:26`; commit 9b4e453 body ("connect-src is just 'self' because all external API calls … go server-to-server")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers browser `fetch` calls in client code reachable under this policy; does not establish html-to-image's internal resource fetches or pdfjs's internal requests, which were not traced into library source.

The client-side graph export fetches a `data:` URL, and `connect-src 'self'` does not allow the `data:` scheme:

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

The same pattern is at `exportGraph.ts:33-38` (`graphToPngBlob`, used by `app/lib/utils/exportAll.ts:64`). The function is reached from the "Export .png" button (`app/components/panels/GraphPanel.tsx:98-110`), which catches the error and only logs `console.error("[graph export]", err)`. Under this CSP, PNG export and the PNG inside the zip export would fail with only a console error. The premise "all external calls are server-to-server" is true for the LLM providers (6a), but it does not support the conclusion "`'self'` is sufficient".

**Evidence:** `proxy.ts:26`, `app/lib/utils/exportGraph.ts:16-39`, `app/lib/utils/exportAll.ts:64`, `app/components/panels/GraphPanel.tsx:98-110`

---

## Claim 7a: "the Edge runtime that Next proxy runs in"

**Location:** `proxy.ts:35-36`
**Type:** Configuration / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which runtime Next.js 16 proxy uses; does not establish deployment-platform specifics (Vercel), which need a deploy.

In Next.js 16 the proxy runs on the Node.js runtime, and the `runtime` option is not available in proxy files. The Edge runtime remains only for the deprecated `middleware.ts` (paraphrased — no quote available because this is Next 16 framework documentation and the source is not installed). `proxy.ts` declares no runtime: `export const config = {` at `proxy.ts:51-64` contains only `matcher`.

**Evidence:** `proxy.ts:34-37`, `proxy.ts:51-64`, `package.json:21`

---

## Claim 7b: "crypto.randomUUID and Buffer are both available"

**Location:** `proxy.ts:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that both globals exist in the runtime the proxy actually uses (Node.js); does not establish the Edge-runtime availability the comment cites, which is moot (7a).

```ts
// proxy.ts:37
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

`Buffer` and global `crypto.randomUUID` are built into the Node.js runtime. The project targets current Node (`"@types/node": "^24"`, `package.json:36`). The conclusion holds even though the runtime named in the comment is wrong.

**Evidence:** `proxy.ts:37`, `package.json:36`

---

## Claim 8: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-42`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the header is forwarded on the request and could be read; does not establish any consumer, because none exists.

The forwarding is real: `requestHeaders.set("x-nonce", nonce);` followed by `NextResponse.next({ request: { headers: requestHeaders } })` (`proxy.ts:42-46`). Nothing reads it, and nothing renders `<Script>`. There are no `next/script` imports and no `x-nonce` reads anywhere (paraphrased — no quote available because the claim covers absence of code: `rg -n "next/script|<Script"` and `rg -n "x-nonce"` outside `node_modules` find only `proxy.ts` and layout comments). The layout comment in the same change says outright that it does not read the header (`app/layout.tsx:30`). The comment should say that no consumer exists today.

**Evidence:** `proxy.ts:39-46`, `app/layout.tsx:27-31`

---

## Claim 9: "Skip API routes …, Next's static assets (no scripts to nonce), and prefetches"; commit: "so we don't burn nonces on requests that don't render HTML"

**Location:** `proxy.ts:52-62`; commit 9b4e453 body
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which paths and headers the matcher excludes; does not establish runtime matcher semantics beyond the documented path-to-regexp and `missing` behavior.

```ts
// proxy.ts:57-61
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```

`/api…`, `/_next/static`, `/_next/image`, `/favicon.ico` and the two prefetch header forms are excluded as described. Two gaps remain. Files in `public/` (`file.svg`, `globe.svg`, `next.svg`, `vercel.svg`, `window.svg`) still match. Non-prefetch client navigations (RSC payload fetches, no HTML) also still match, so the commit's "requests that don't render HTML" is not fully covered. The negative lookahead is also prefix-based: it skips any path that starts with `api`, `/apiary` for example (paraphrased — no quote available because this is regex semantics of the quoted line).

**Evidence:** `proxy.ts:51-64`, `public/` listing

---

## Claim 10: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates."

**Location:** commit 9b4e453 body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing executed (execution required); does not establish either half. Static evidence contradicts the nonce half.

Execution is required and was blocked: there is no `node_modules` in the worktree, no cached `next` tarball, and no network, so `next build && next start` could not run. Statically, the CSP-header half is consistent with `proxy.ts:47`. The nonce half conflicts with Claim 2: the renderer reads the nonce from the request CSP header, which this proxy never sets (`proxy.ts:41-46`). To verify, build, start, `curl` a page, and check whether the `<script>` tags carry `nonce="…"` matching the response header. Then load the page in a browser and check for CSP violations and hydration.

**Evidence:** `proxy.ts:41-48`, `app/layout.tsx:27-31`

---

## Claim 11: "no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false"

**Location:** commit 9b4e453 body
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `app/` source outside tests; does not establish dependency internals.

`rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw|trust" app` finds nothing outside tests (paraphrased — no quote available because the claim covers absence of code). KaTeX runs through `rehype-katex` with no options (`const rehypePlugins = [rehypeKatex];`, `app/components/features/output-editing/LatexRenderer.tsx:10`), so `trust` is `false` only because that is KaTeX's default. Nothing sets it explicitly.

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:1-40`

---

## Claim 12: "No behavior change; CSP directives preserved exactly."

**Location:** commit d90d6bb body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the d90d6bb delta relative to its parent, which is all of b25e939..d90d6bb after 9b4e453; does not establish that the behavior being preserved is correct (Claims 2, 6b).

`git diff 9b4e453..d90d6bb` shows `proxy.ts` changes only these: the `: NextResponse` return annotation, the comment, and inlining `const csp = buildCsp(nonce);` into `response.headers.set("Content-Security-Policy", buildCsp(nonce));` (`proxy.ts:47`). `buildCsp` (`proxy.ts:19-32`) is untouched. The `layout.tsx` change is comment-only.

**Evidence:** `proxy.ts:19-32`, `proxy.ts:34-49`, `app/layout.tsx:27-30`

---

## Claim 13: "Lint clean; 221/221 tests pass."

**Location:** commit d90d6bb body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing executed; does not establish lint or test status.

Execution is required and was blocked: no `node_modules` in the worktree and no network to install it. `npm run lint` / `npm test` (`package.json:9-10`) could not run. The diff adds no tests, so the passing suite does not exercise the proxy or the CSP behavior either way.

**Evidence:** `package.json:5-12`

---

## Claim 14: "the nonce is only written, never read by the layout"

**Location:** commit d90d6bb body
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `app/layout.tsx` and the rest of `app/`; does not establish that Next.js itself obtains the nonce (Claim 2).

The layout calls `await headers();` and discards the result (`app/layout.tsx:31`). No code reads `x-nonce` (paraphrased — no quote available because the claim covers absence of code: the `rg` search in Claim 8).

**Evidence:** `app/layout.tsx:22-43`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`app/layout.tsx:27-28`): Dynamic rendering does not make the proxy run. The matcher does that. Dynamic rendering is needed so the HTML is rendered per request with a fresh nonce. **Legibility-target:** for-author
- **Claim 2** (`app/layout.tsx:28-30`): Next reads the nonce from the **request** CSP header. The proxy sets CSP only on the response and forwards only `x-nonce`, which Next ignores. Next's scripts likely ship without a nonce and get blocked under `'strict-dynamic'`. **Legibility-target:** for-author
- **Claim 5** (`proxy.ts:12-14`): Tailwind v4 compiles to a stylesheet. `'unsafe-inline'` is needed for the inline `style` attributes from React, KaTeX and React Flow (31 `style={{` sites), not for Tailwind. **Legibility-target:** for-author
- **Claim 6b** (`proxy.ts:16,26`): `connect-src 'self'` blocks `fetch(dataUrl)` in `app/lib/utils/exportGraph.ts:24,37`, which breaks PNG and zip export. **Legibility-target:** for-author
- **Claim 7a** (`proxy.ts:35-36`): The Next 16 proxy runs on the Node.js runtime, not Edge. **Legibility-target:** for-author

### Stale
- none

### Mostly Accurate
- **Claim 6a** (`proxy.ts:16-17`): The Anthropic and OpenRouter calls are server-side, but OpenAlex has no code in the repo. **Legibility-target:** for-author
- **Claim 8** (`proxy.ts:39-40`): `x-nonce` is forwarded, but nothing reads it and there are no `<Script>` tags. **Legibility-target:** for-author
- **Claim 9** (`proxy.ts:52-54`): `public/*.svg` files and non-prefetch RSC navigations still pass through the proxy. **Legibility-target:** for-author
- **Claim 11** (commit 9b4e453): KaTeX `trust` is false by default, not explicitly configured. **Legibility-target:** for-author

### Unverifiable
- **Claim 10** (commit 9b4e453): "Next applies the nonce to every <script>". Needs a build plus browser run, and static evidence contradicts it. **Legibility-target:** for-orchestrator-synthesis
- **Claim 13** (commit d90d6bb): "Lint clean; 221/221 tests pass". Needs `node_modules`. **Legibility-target:** for-orchestrator-synthesis

### Verified
- Claims 1a, 3, 4, 7b, 12, 14. **Legibility-target:** for-orchestrator-synthesis

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: Code-quality and security judgments beyond claim accuracy. Library-internal fetches of html-to-image and pdfjs, and whether `'strict-dynamic'` (via the `script-src` fallback for `worker-src`) admits the pdfjs worker URL; this was not traced. Updating the hallucination-pattern log, since the brief allows writing only this file.
- Escalate: (1) Claim 2 / Claim 10. The proxy never sets CSP on the forwarded request headers, so Next likely emits no script nonce, and `'strict-dynamic'` would then block all Next scripts. This could break the app outright. It needs a real build plus browser check, or a fix that adds `requestHeaders.set("Content-Security-Policy", csp)`. (2) Claim 6b. `connect-src` must allow `data:`, or the export must drop `fetch(dataUrl)`, or PNG and zip export break silently. (3) Possible hallucination-log entry for whoever owns the log: "OpenAlex named as an external API with no code in repo".
- Decisions I made: Framework-behavior claims (Claims 1b, 2, 7a) were verdicted Incorrect at Medium confidence from the documented Next.js 16 contract, because the framework source is not installed. Claim 10, the executable build claim, was capped at Unverifiable per the mandatory-execution rule, even though the static evidence points against it.
