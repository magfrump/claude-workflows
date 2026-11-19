Commit: d90d6bb

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree `wt-csp`, detached HEAD d90d6bb)
**Scope:** d86d2dc..d90d6bb — `app/layout.tsx`, `proxy.ts`, and the bodies of commits 9b4e453, b25e939, d90d6bb
**Checked:** 2026-11-19
**Total claims checked:** 14
**Summary:** 5 verified, 0 mostly accurate, 0 stale, 7 incorrect, 2 unverifiable

Notes on method: `node_modules` is not installed in the worktree and the npm cache holds no `next@16` tarball, so claims about Next.js framework internals rest on knowledge of the Next.js source and docs for the pinned version (`"next": "16.2.4"`, `package.json`), not on reading the installed framework. Confidence for those claims is capped at Medium. `docs/reviews/hallucination-patterns.md` does not exist in this repo, so no prior patterns were compared. No files other than this report were written, so every verdict is static.

---

## Claim 1a: "headers() is called to opt out of static rendering" (layout.tsx comment, first clause; 9b4e453 body: "Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached")

**Location:** `app/layout.tsx:27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `await headers()` in the root layout makes every route under it dynamic, and that a nonce must be produced per request. Does not establish that the dynamic render actually gets a nonce applied to its scripts (see Claim 2).

```tsx
// app/layout.tsx:22-32 (excerpt ends :32; enclosing RootLayout continues to :42 — read)
export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  // Opt this layout out of static rendering so proxy.ts runs on every request
  ...
  await headers();
```

`headers()` is a Dynamic API. Calling it in the root layout makes every page dynamic (paraphrased — no quote available because this is Next.js framework behaviour and the framework is not installed in the sandbox). The return value is discarded. The rest of the unit (`:34-42`) renders `<html><body>` and never uses it.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `app/layout.tsx:22-42`, `package.json` (`"next": "16.2.4"`)

---

## Claim 1b: "...so proxy.ts runs on every request and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:27-28`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the causal link the comment draws between the layout's rendering mode and whether the proxy runs. Does not establish whether a dynamic render is needed for nonce stamping (it is; Claim 1a holds).

Proxy (formerly middleware) runs for every request its `matcher` selects, whether the route is rendered statically or dynamically (paraphrased — no quote available because this is framework request-pipeline behaviour, and the framework is not installed). The proxy's reach is set only by its own config:

```ts
// proxy.ts:54-63
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

Making the layout dynamic is needed so the HTML is rendered per request and can carry a per-request nonce. It does not decide whether the proxy runs. The conclusion (the layout must be dynamic) is right, but the stated mechanism is wrong.

**Legibility-target:** for-author
**Evidence:** `app/layout.tsx:27-32`, `proxy.ts:51-64`

---

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the source Next.js reads its script nonce from, and whether this proxy supplies it there. Does not establish runtime behaviour in a browser, which was not run.

When the App Router renders, it takes the nonce from the **incoming request's** `Content-Security-Policy` header (`req.headers['content-security-policy']`, parsed by `getScriptNonceFromHeader` in app-render). It does not read the response header. The official Next.js CSP example therefore sets the CSP on the forwarded request headers as well as on the response (paraphrased — no quote available because the Next.js source is not installed in the sandbox; this comes from the framework source and docs for v15/16). This proxy puts the CSP on the response only. The forwarded request headers carry only `x-nonce`, which Next does not parse:

```ts
// proxy.ts:34-48 (complete proxy())
export function proxy(request: NextRequest): NextResponse {
  ...
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
  ...
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
  return response;
}
```

As a result, Next's bootstrap and inline flight `<script>` tags get no `nonce` attribute. The response policy is `script-src 'self' 'nonce-…' 'strict-dynamic'` (`proxy.ts:22`). Under CSP Level 3, when `'strict-dynamic'` is present the browser ignores `'self'`, so every Next script, whether external chunk or inline, would be blocked and the client would not hydrate. A reader who trusts this comment would not add the request-side CSP header that the nonce depends on.

**Legibility-target:** for-author
**Evidence:** `app/layout.tsx:27-32`, `proxy.ts:19-31`, `proxy.ts:34-48`

---

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy)" (also 9b4e453: "middleware.ts builds with a deprecation warning"; b25e939 subject "renamed from middleware.ts")

**Location:** `proxy.ts:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the file-convention rename and the exported `proxy` function name for Next 16. Does not establish the exact wording of the deprecation warning, because no build was run.

Next.js 16 renamed the `middleware.ts` convention to `proxy.ts` with an exported `proxy` function, and deprecated `middleware.ts` (paraphrased — no quote available because this is a framework release fact; the framework is not installed). The repo pins `"next": "16.2.4"` (`package.json`), and the file exports `export function proxy(request: NextRequest): NextResponse` (`proxy.ts:34`).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `proxy.ts:5`, `proxy.ts:34`, `package.json`

---

## Claim 4: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR." (also 9b4e453 body)

**Location:** `proxy.ts:12-14`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether Tailwind v4 in this build setup is the source of inline styles. Does not establish that `'unsafe-inline'` is unnecessary; it is needed for other reasons, named below.

Tailwind v4 runs here as a PostCSS plugin. It compiles `globals.css` into a stylesheet that Next serves from `_next/static`, which `'self'` already allows:

```js
// postcss.config.mjs:1-7
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

The inline styles that need `'unsafe-inline'` come from elsewhere. The app has 30 React `style={{…}}` props, which render as `style=""` attributes in the SSR HTML. Two examples are `app/components/features/proof-graph/ProofGraphNode.tsx:45` `style={{ borderColor: statusColor, borderWidth: 2, minWidth: 160 }}` and `app/components/panels/SemiformalPanel.tsx:77`. KaTeX and reactflow also write inline styles (paraphrased — no quote available because those libraries are not installed in the sandbox). The conclusion (keep `'unsafe-inline'`) holds, but the stated cause is wrong, so per the compound-claim rule the verdict is Incorrect.

**Legibility-target:** for-author
**Evidence:** `proxy.ts:12-14`, `proxy.ts:23`, `postcss.config.mjs:1-7`, `app/globals.css:1-2`, `app/components/features/proof-graph/ProofGraphNode.tsx:45`, `app/components/panels/SemiformalPanel.tsx:77`

---

## Claim 5a: "Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:16-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the OpenRouter call sites and the client fetches to `/api/*` found by grep. Does not establish that `'self'` covers every browser-side fetch (see Claim 5b).

The only third-party URL is used inside `app/lib/llm/`: `app/lib/llm/callLlm.ts:7` `export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";`, fetched at `callLlm.ts:164` and `streamLlm.ts:249`. These modules are imported by `app/api/**/route.ts` and server libs. The one client-side importer, `app/lib/formalization/api.ts:3`, imports a type only: `import type { LlmCallUsage } from "@/app/lib/llm/callLlm";`. Client fetches go to same-origin paths, for example `app/components/features/context-input/ContextInput.tsx:25` `fetch("/api/refine/context", {` and `app/hooks/useAnalytics.ts:11` `fetch("/api/analytics")`. No OpenAlex or Anthropic URL appears in `app/` (paraphrased — no quote available because the claim covers absence of code, from a grep for `https?://` and `fetch(` over `app/`).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `app/lib/llm/callLlm.ts:7`, `app/lib/llm/callLlm.ts:164`, `app/lib/llm/streamLlm.ts:249`, `app/lib/formalization/api.ts:3`, `app/components/features/context-input/ContextInput.tsx:25`, `app/hooks/useAnalytics.ts:11`

---

## Claim 5b: "`connect-src 'self'` is sufficient" (also 9b4e453: "connect-src is just 'self' because all external API calls ... go server-to-server")

**Location:** `proxy.ts:16`, `proxy.ts:26`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the graph-export path's browser `fetch()` of a `data:` URL. Does not establish whether html-to-image makes other blocked fetches inside `toPng`, because the library is not installed.

The browser fetches a `data:` URL, and `connect-src` governs that fetch. `'self'` does not match the `data:` scheme:

```ts
// app/lib/utils/exportGraph.ts:16-27 (complete downloadGraphAsPng)
export async function downloadGraphAsPng(
  viewportElement: HTMLElement,
  filename = "proof-graph.png",
) {
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
  triggerDownload(blob, filename);
}
```

`graphToPngBlob` (`:30-39`) does the same thing (`const res = await fetch(dataUrl);` at `:37`). Both run client-side. `GraphPanel.tsx:102-104` dynamically imports `downloadGraphAsPng` and calls it, and `exportAll.ts:64` calls `graphToPngBlob`. Under `connect-src 'self'` (`proxy.ts:26`) these fetches are refused, so the PNG graph export and the PNG inside the zip export would break. The server-to-server premise is true (Claim 5a), but the conclusion that `'self'` is enough is false.

**Legibility-target:** for-author
**Evidence:** `proxy.ts:26`, `app/lib/utils/exportGraph.ts:16-39`, `app/components/panels/GraphPanel.tsx:102-104`, `app/lib/utils/exportAll.ts:64`

---

## Claim 6a: "Generate a fresh nonce per request. crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in." — the runtime part ("the Edge runtime that Next proxy runs in")

**Location:** `proxy.ts:35-36`
**Type:** Configuration / Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which runtime Next 16 proxy runs in. Does not establish anything about deployment-platform specifics on Vercel.

In Next.js 16, `proxy.ts` runs on the Node.js runtime, and the Edge runtime is not supported for proxy (only the deprecated `middleware.ts` can still target Edge) (paraphrased — no quote available because this is a framework fact and the framework is not installed). `proxy.ts` sets no `runtime` in its `config` (`proxy.ts:51-64` contains only `matcher`). This comment was written in 9b4e453 and extended in d90d6bb to add Buffer.

**Legibility-target:** for-author
**Evidence:** `proxy.ts:35-37`, `proxy.ts:51-64`, `package.json`

---

## Claim 6b: "crypto.randomUUID and Buffer are both available" / "fresh nonce per request"

**Location:** `proxy.ts:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both globals exist in the Node.js runtime where proxy actually runs, and that a new value is generated on each call. Does not establish the nonce's entropy encoding beyond base64 of a UUID string.

`const nonce = Buffer.from(crypto.randomUUID()).toString("base64");` (`proxy.ts:37`) runs inside `proxy()` on every invocation. `crypto.randomUUID` and `Buffer` are both globals in Node.js 19+ (paraphrased — no quote available because this is runtime-environment behaviour).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `proxy.ts:34-48`

---

## Claim 7: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-41`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reader of `x-nonce` and every `<Script>` in the repo at d90d6bb. Does not establish whether a future consumer is planned.

Nothing reads `x-nonce`. A `git grep` for `nonce` / `x-nonce` at d90d6bb finds only `proxy.ts` and the layout comment, which says the opposite: `// CSP header, so we don't need to read x-nonce here ourselves.` (`app/layout.tsx:30`). The layout discards the `headers()` result (`await headers();`, `app/layout.tsx:32`), and no `<Script>` component is rendered anywhere (paraphrased — no quote available because the claim covers absence of code, from a grep). The header is set but never consumed, and the two comments in this change contradict each other.

**Legibility-target:** for-author
**Evidence:** `proxy.ts:39-41`, `app/layout.tsx:27-32`

---

## Claim 8: "Apply CSP to page navigations only. Skip API routes (they don't render HTML), Next's static assets (no scripts to nonce), and prefetches" (also 9b4e453: "The matcher skips /api routes, _next/static, and prefetches")

**Location:** `proxy.ts:52-54`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that `/api/*`, `/_next/static/*`, `/_next/image*`, `/favicon.ico` and requests carrying `next-router-prefetch` or `purpose: prefetch` are excluded. Does not establish that "page navigations only" is exact: the negative lookahead also excludes any path that merely starts with `api` (for example `/apiary`), and other `public/` files (`file.svg`, `next.svg`, …) and non-prefetch RSC requests still pass through the proxy. The regex was not executed.

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
  ],
```

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `proxy.ts:51-64`, `public/` listing

---

## Claim 9: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates." (9b4e453 body)

**Location:** commit 9b4e453 (body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the nonce-stamping half, against the proxy code as committed. The header-emission half is consistent with `proxy.ts:46`. Does not establish what a build in the author's environment printed; no build was run (no `node_modules`).

The header half matches the code: `response.headers.set("Content-Security-Policy", buildCsp(nonce));` (`proxy.ts:46`). The nonce half conflicts with how Next sources the nonce. Next reads it from the request's CSP header, and this proxy never sets that header (see Claim 2; paraphrased — no quote available because the Next.js source is not installed). With the code as committed, Next's generated scripts would not carry the nonce. The "verified" statement is either wrong or describes a state other than the one committed.

**Legibility-target:** for-author
**Evidence:** `proxy.ts:34-48`

---

## Claim 10: "No behavior change; CSP directives preserved exactly." (d90d6bb body)

**Location:** commit d90d6bb (body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the full `git diff 9b4e453 d90d6bb` across both files. Does not establish that the pre-existing behaviour was correct.

`git diff 9b4e453 d90d6bb` changes three things. It adds a `: NextResponse` return annotation. It inlines `const csp = buildCsp(nonce);` into `response.headers.set("Content-Security-Policy", buildCsp(nonce));`. It rewords comments. `buildCsp` (`proxy.ts:19-31`) and the matcher are unchanged.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `proxy.ts:19-31`, `proxy.ts:34-48`, `app/layout.tsx:27-30`

---

## Claim 11: "Lint clean; 221/221 tests pass." (d90d6bb body)

**Location:** commit d90d6bb (body)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the fact that the claim is an executable guarantee. Does not establish lint or test status.

Execution is required and was blocked: there is no `node_modules` in the worktree, and installing packages or using the network is not allowed in this pass. No test in the repo exercises `proxy.ts` or the CSP (paraphrased — no quote available because the claim covers absence of code: the only `nonce` hits outside the two changed files are none). So even a pass would not touch the CSP behaviour.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `vitest.config.ts`, `package.json`

---

## Claim 12: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)" (9b4e453 body)

**Location:** commit 9b4e453 (body)
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Not checked in depth in this replicate. It is outside the changed files' comments and was not on the priority list. Does not establish any of its three sub-claims.

This claim concerns the rest of the app, not the two files in the diff, and this replicate did not trace it (paraphrased — no quote available because no search was done for this claim). Verifying it needs a grep for `dangerouslySetInnerHTML` and `rehype-raw`, plus a read of the KaTeX options in `app/components/features/output-editing/LatexRenderer.tsx`.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `package.json` (`react-markdown`, `rehype-katex`), `app/components/features/output-editing/LatexRenderer.tsx`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`app/layout.tsx:27-28`): The proxy runs for every matched request whatever the rendering mode. The dynamic render is needed so the HTML can carry a per-request nonce, not so the proxy runs.
- **Claim 2** (`app/layout.tsx:28-30`): Next takes the nonce from the request's CSP header, and this proxy sets CSP only on the response, so Next's scripts go unnonced and `'strict-dynamic'` blocks them. Set CSP on `requestHeaders` too, or fix the comment.
- **Claim 4** (`proxy.ts:12-14`): Tailwind v4 (via `@tailwindcss/postcss`) ships an external stylesheet. The inline styles come from React `style` props (30 sites), KaTeX and reactflow.
- **Claim 5b** (`proxy.ts:16,26`): `exportGraph.ts:24,37` calls `fetch(dataUrl)` in the browser, and `connect-src 'self'` blocks `data:`, which breaks PNG and zip graph export.
- **Claim 6a** (`proxy.ts:35-36`): Next 16 proxy runs on Node.js, not Edge.
- **Claim 7** (`proxy.ts:39-41`): Nothing reads `x-nonce` and there are no `<Script>` tags. The comment contradicts `app/layout.tsx:30`.
- **Claim 9** (9b4e453 body): "Next applies the nonce to every <script>" cannot hold for the committed proxy, which never puts CSP on the request.

### Stale
- none

### Mostly Accurate
- none

### Unverifiable
- **Claim 11** (d90d6bb body): Needs `npm ci`, then `npm run lint` and `npx vitest run`. Blocked by the missing `node_modules` and the no-network rule.
- **Claim 12** (9b4e453 body): Needs a grep for `dangerouslySetInnerHTML` and `rehype-raw`, plus a read of the KaTeX options. Not done in this replicate.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: Claim 12 (app-wide XSS-surface claim) was only recorded, not traced. Running build, lint or tests was blocked by the missing `node_modules` and the no-install rule.
- Escalate: (1) Likely functional breakage: with CSP set on the response only, Next will not stamp the nonce, and `'strict-dynamic'` would block all Next scripts, so the app would not hydrate. A browser or `next build && next start` check against the committed proxy should confirm this before shipping. (2) `connect-src 'self'` breaks the graph PNG and zip export, which call `fetch(data:…)`. (3) The framework-internal verdicts (Claims 2, 3, 6a, 9) rest on Next.js source knowledge, not on an installed copy. A replicate or reviewer with `node_modules` should grep `getScriptNonceFromHeader` / `content-security-policy` in `next/dist/server/app-render`.
- Decisions I made: Following the "write no other file" rule, I recorded no executed verdicts, because executed provenance needs a captured-output file. I treated framework facts as static evidence at Medium confidence instead of marking them Unverifiable.
