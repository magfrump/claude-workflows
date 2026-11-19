Commit: d90d6bb

# Architecture Review — meta-formalism-copilot CSP proxy (d86d2dc..d90d6bb)

**Scope:** d86d2dc..d90d6bb (3 commits): `proxy.ts` (new), `app/layout.tsx`
**Date:** 2026-11-19
**Based on:** merged code-fact-check report `/workspace/.claude/wt-2026-11-19-a8-token-measurement/runs/review-arms/a8-2026-11-19/csp/code-fact-check-report.md` (k=3)

Scope check: in scope under **cross-cutting concerns** (a new request-pipeline stage that runs before every page render) and **module structure** (a new top-level module `proxy.ts` that the framework discovers by file name). Public APIs: the module exports `proxy` and `config`, consumed only by Next.js by convention. Data models: no, apart from the `x-nonce` request header, treated below as an implicit contract.

Trust-boundary cross-reference: no-op. No `docs/reviews/security-review-*.md` exists in the reviewed tree, so this review contains no trust-boundary labels. The security-reviewer output for this pass, if any, sits at the orchestrator's path and is not read here.

## Dependency Map

- `proxy.ts` (repo root, framework-discovered) depends only on `next/server` (`NextResponse`, `NextRequest`). No application module imports it. The framework calls it before routing on every request that passes the `config.matcher`.
- `app/layout.tsx` gains a dependency on `next/headers` (`headers()`). It does not import `proxy.ts`, and the two have no compile-time edge between them. They are coupled at runtime in two ways: (a) the layout has to render dynamically for each HTML response to carry a new nonce, and (b) the nonce has to get from the proxy into Next's renderer, which tags its bootstrap `<script>` elements with it.
- The policy in `buildCsp` (`proxy.ts:19-32`) constrains client feature modules it has no edge to: `app/lib/utils/exportGraph.ts` (`fetch(dataUrl)`), `app/lib/utils/fileExtraction.ts` and `pdfPropositionParser.ts` (the pdf.js worker), and every component that renders inline `style={{}}` props (19 files under `app/`), KaTeX or React Flow. The dependency points the right way (a root cross-cutting module that knows nothing about features). But it is invisible: a feature that breaks the policy fails only at runtime in the browser.

## Findings

#### 1. Nonce delivery depends on an undocumented router internal (the CSP is set on the response, never on the forwarded request) — addresses E1

**Severity:** Coupling
**Location:** `proxy.ts:41-47`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High on the mechanism, Medium on deployment impact (Vercel unconfirmed)
**Legibility-target:** for-author

**Evidence:**
```ts
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```
(excerpt ends :47; enclosing `proxy()` continues to :49 with `return response;` and `}` — read)

The proxy-to-renderer contract that Next.js documents is "put the CSP header on the forwarded request headers; the renderer extracts the nonce from there". The proxy doesn't do that. It forwards only `x-nonce`, which Next ignores, and sets the CSP only on the response. The fact-check (claim 3, E1) found that scripts get the nonce on self-hosted `next start` only because the router copies proxy response headers onto `req.headers` (`next/dist/server/lib/router-utils/resolve-routes.js:443-446`). That is content coupling: the app's whole script-execution path depends on a private implementation detail of the router, in a module that no public API or test pins. If that copy differs on another adapter (Vercel's edge routing, a standalone/output-export build, a future Next minor), the page loses its nonce and `'strict-dynamic'` blocks every script. The app does not degrade gracefully here: the whole UI is one `"use client"` page (`app/page.tsx:1`), so a blocked bootstrap leaves the app completely dead. The layout comment (`app/layout.tsx:28-30`, "from the response's CSP header") writes this internal down as if it were the intended contract, so the next maintainer will keep relying on it.

**Recommendation:** Set the CSP on `requestHeaders` too, before `NextResponse.next(...)`, as well as on the response. That uses Next's documented hand-off, and the router-copy path stops mattering. Fix the layout comment so it describes that contract, and confirm on the Vercel preview before shipping.

#### 2. The CSP policy is an unlinked cross-cutting constraint on client features, and its stated rationale names the wrong dependents — addresses E2, E3

**Severity:** Coupling
**Location:** `proxy.ts:12-17,19-31`; affected dependents `app/lib/utils/exportGraph.ts:24,37`, `app/lib/utils/fileExtraction.ts:26-29`, `app/lib/utils/pdfPropositionParser.ts:443-446`
**Move:** 2 (responsibility boundaries), 7 (coupling surface)
**Confidence:** High (E2: 3/3 fact-check replicates); Medium (E3: worker-src fallback inferred, not executed)
**Legibility-target:** for-author

**Evidence** (`proxy.ts:22-26`):
```ts
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
    "connect-src 'self'",
```
(excerpt ends :26; enclosing `buildCsp()` continues to :32 with `frame-ancestors`, `base-uri`, `object-src` and the `join` — read)

Dependent (`app/lib/utils/exportGraph.ts:24`):
```ts
  const res = await fetch(dataUrl);
```

Dependent (`app/lib/utils/fileExtraction.ts:26-29`):
```ts
  pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
    "pdfjs-dist/build/pdf.worker.min.mjs",
    import.meta.url,
  ).toString();
```

A CSP is effectively a capability manifest for the whole client: every feature module now has an implicit dependency on it. The doc comment does list the policy's dependents, but it lists the wrong ones. It says `'unsafe-inline'` exists for Tailwind, while the fact-check (claim 6) found the real dependents are React `style` props, KaTeX and React Flow. It says `connect-src 'self'` holds because all external traffic goes server-to-server, but the browser-side `fetch(dataUrl)` in `exportGraph.ts` already breaks it (claim 8: graph PNG export and Export All fail with only a `console.error`). It names no `worker-src` dependent, even though pdf.js spawns a worker that, under `'strict-dynamic'`, may not be allowed (claim 5 caveat). Nothing connects the two sides: no test, no note in `CLAUDE.md`'s architecture section or `docs/ARCHITECTURE.md`, no decision record. So a future feature change (a new worker, a `blob:` fetch, a third-party embed) breaks at runtime with no build-time or test-time signal, and whoever loosens the policy has a wrong rationale to work from. Whether to allow `data:` in connect-src or set `worker-src` is a security call. The structural problem is that the constraint is hidden and documented incorrectly.

**Recommendation:** Rewrite the comment so it lists the real dependents of each carve-out, and either change the dependents (for example, have `exportGraph.ts` use html-to-image's `toBlob` and skip the `data:` fetch) or extend the directives on purpose (the security reviewer decides which). Add a short "CSP constraints on client code" entry to the project's architecture doc or a `docs/decisions/` record, so feature authors can see what the policy forbids.

#### 3. `x-nonce` is a published contract with no consumer, and the two files describe it differently

**Severity:** Minor
**Location:** `proxy.ts:39-42`; `app/layout.tsx:27-31`
**Move:** 3 (module boundary), 5 (interface minimality)
**Confidence:** High
**Legibility-target:** for-author

**Evidence** (`proxy.ts:39-42`):
```ts
  // Forward the nonce to server components via a request header so layouts
  // can read it via `headers()` and pass it to <Script> tags they render.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
```
(excerpt ends :42; enclosing `proxy()` continues to :49 — read)

`app/layout.tsx:28-31`:
```tsx
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
  await headers();
```
(excerpt ends :31; enclosing `RootLayout` continues to :42 with the `<html>/<body>` return — read)

The proxy offers a request-header interface (`x-nonce`) and documents a consumer that doesn't exist. No `<Script>` is in the tree and nothing reads the header (fact-check claim 11). The layout comment says the opposite: the header is not needed. So two modules give conflicting accounts of one contract. The next person to add a third-party `<Script>` can't tell which channel is authoritative. This also makes Finding 1 harder to see: the one header the proxy explicitly forwards is the wrong one.

**Recommendation:** Pick one channel. Either keep `x-nonce` and say it is the supported hook for future `<Script>`/inline-script consumers (with an example read in the comment), or drop it and forward only the CSP request header from Finding 1. Make both comments say the same thing.

#### 4. Dynamic rendering is switched on by a side-effect call whose result is thrown away, and the comment gets the causality backwards

**Severity:** Minor
**Location:** `app/layout.tsx:27-31`
**Move:** 2 (responsibility boundaries), 8 (explicit extension point vs. implicit trigger)
**Confidence:** High (claim 2 Incorrect, 3/3)
**Legibility-target:** for-author

**Evidence:**
```tsx
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  await headers();
```
(lines 27-28 and 31 shown; lines 29-30 quoted in Finding 3; enclosing `RootLayout` continues to :42 — read)

The root layout is the composition root for the whole app, and it now holds a rendering-mode decision that exists only for the proxy. That decision is expressed as a call to a request API whose return value is discarded. It is an implicit trigger: someone tidying "unused" code can delete it, the build still passes, and every HTML response then ships a stale, cached nonce. The comment also has the dependency backwards: the matcher, not dynamic rendering, decides whether the proxy runs. Dynamic rendering only makes the HTML carry the current request's nonce (fact-check claim 2). The coupling is real (a nonce-based CSP needs per-request HTML), but it should be stated, not left as a side effect.

**Recommendation:** Use an explicit declaration (`await connection()` from `next/server`, or `export const dynamic = "force-dynamic"`). Say in the comment that the layout must render per request because the proxy's nonce changes per request, and name `proxy.ts` as the reason.

#### 5. The matcher hard-codes the route topology as a negative regex

**Severity:** Minor
**Location:** `proxy.ts:57`
**Move:** 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```ts
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```
(excerpt ends :57; enclosing `config.matcher` entry continues to :62 with the `missing` prefetch conditions — read)

The proxy's scope comes from an exclusion list of path prefixes, not from what the response is (HTML or not). `(?!api` with no trailing `/` also excludes any future page whose path starts with `api` (`/apiary`). `public/` files (`/file.svg` and the rest) and non-prefetch RSC navigations still run the proxy (fact-check claim 12). Every new non-HTML route family means editing this regex, and a wrong edit fails silently either way: a page without CSP, or an asset with a pointless nonce. The scale is small today, so this is Minor.

**Recommendation:** Anchor the exclusions (`api/`, `_next/static/`, `_next/image/`, `favicon\.ico$`), and consider excluding common static extensions. A one-line comment saying "new non-HTML route prefixes must be added here" makes the extension point visible.

#### 6. No test pins the proxy contract

**Severity:** Informational
**Location:** `proxy.ts:34-49`
**Move:** 7 (coupling surface)
**Confidence:** High (fact-check claim 16: 221 tests pass, none touches `proxy.ts`)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```ts
export function proxy(request: NextRequest): NextResponse {
```
(excerpt ends :34; enclosing `proxy()` continues to :49 — read)

"221/221 tests pass" in d90d6bb is true but says nothing about this change. The directive list, the nonce format and the headers set on the forwarded request are the module's whole behavior, and no unit test pins them. A unit test on `proxy()` (does the request get the CSP header, does the nonce in the CSP match the forwarded one) would have caught Finding 1 with no browser. A test-strategy pass belongs to another critic. Noted here because the missing test is what keeps Findings 1 and 2 hidden.

## What Looks Good

- The proxy sits at the root as a single-purpose module with one framework dependency (`next/server`) and no imports from application code. The direction is right: the cross-cutting policy knows nothing about features.
- `buildCsp` is a pure function of the nonce, separate from request handling, so the policy can be unit-tested and reviewed on its own.
- API routes are kept out of the pipeline, so the server-side LLM calls (`app/lib/llm/callLlm.ts`, `streamLlm.ts`) are untouched.
- The deliberate carve-out is documented in the code rather than left implicit. The rationale is wrong (Finding 2), but this is the right place for it.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Nonce reaches the renderer only through an undocumented router header copy; CSP never set on forwarded request (E1) | Coupling | `proxy.ts:41-47` | High / Medium (Vercel) |
| 2 | CSP is a hidden constraint on client features; rationale names the wrong dependents; export and pdf.js break (E2, E3) | Coupling | `proxy.ts:12-17,19-31` | High / Medium |
| 3 | `x-nonce` published with no consumer; the two files contradict each other | Minor | `proxy.ts:39-42`, `app/layout.tsx:27-31` | High |
| 4 | Dynamic rendering via a discarded `headers()` call; causality misstated | Minor | `app/layout.tsx:27-31` | High |
| 5 | Matcher hard-codes route topology; `(?!api` unanchored | Minor | `proxy.ts:57` | Medium |
| 6 | No test pins the proxy contract | Informational | `proxy.ts:34-49` | High |

## Overall Assessment

The basic structure is sound: a single, dependency-light root module that adds one pipeline stage, with a pure policy builder. Everything is fixable in place, and no restructuring is needed. The biggest structural concern is Finding 1. The one contract that matters, how the nonce reaches Next's renderer, travels through a private router behavior instead of the documented request-header hand-off. The header the proxy does forward (`x-nonce`) has no reader, and the layout comment records the internal as if it were the design. Because the app is a single client page under `'strict-dynamic'`, if that internal behaves differently on the deployment target, the whole UI fails to load, not just part of it. Setting the CSP on the forwarded request headers removes the dependency with a few lines of change. Second is Finding 2: the policy already conflicts with two client features (graph export, and probably the pdf.js worker), and nothing links the policy to the code it constrains.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the architecture-review skill.
- Answered: yes
- Out of scope: Choosing the directive values (whether to allow `data:` in connect-src, adding `worker-src`, keeping `'unsafe-inline'`) is a security-reviewer call. Per-request rendering cost of the forced-dynamic root layout belongs to the performance critic. OpenAlex naming (E4) is addressed to the orchestrator.
- Escalate: (1) security-reviewer: Finding 1's fix (CSP on forwarded request headers) and Finding 2's directive changes, since both alter the script/connect/worker policy. (2) orchestrator: Vercel-preview verification of nonce delivery is still unconfirmed (E1). Treat it as a ship blocker until someone has observed it working, not inferred it.
- Decisions I made: Rated Finding 1 Coupling rather than Structural. It is content coupling to a framework internal, not a dependency-inversion or layer violation, even though the runtime failure would be total. Read E2/E3 as structural (a hidden constraint) and left the exploitability and directive decisions to security.
