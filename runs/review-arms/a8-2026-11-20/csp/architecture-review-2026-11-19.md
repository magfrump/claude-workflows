Commit: d90d6bb

# Architecture Review — CSP proxy (d86d2dc..d90d6bb)

**Scope:** d86d2dc..d90d6bb, 2 files: `proxy.ts` (new), `app/layout.tsx` (modified), in meta-formalism-copilot
**Date:** 2026-11-19
**Based on:** merged code-fact-check report, `runs/review-arms/a8-2026-11-20/csp/code-fact-check-report.md` (k=3)

**Scope check:** in scope. Cross-cutting concerns: yes, because the change adds a new request-pipeline stage (Next 16 proxy) that runs ahead of every page render. Module structure: yes, a new root-level module. Public APIs: framework entry points only (`proxy`, `config`). Data models: no, apart from one new request header (`x-nonce`).

**Trust-boundary cross-reference:** no-op. No `docs/reviews/security-review-*.md` exists in the reviewed worktree, so no Trust Boundary Map was available.

## Dependency Map

- `proxy.ts` imports only `next/server` (`NextResponse`, `NextRequest`). Nothing in the app imports it. The framework finds it by file convention, so its coupling to the app is through runtime contracts, not imports:
  - **Downstream (request side):** it writes the `x-nonce` request header. No module reads it (fact-check Claim 13; `rg x-nonce app` finds only the layout comment).
  - **Downstream (renderer):** Next's App Router renderer has to find the nonce so it can tag its bootstrap `<script>` elements. Next reads the nonce from the **request** `Content-Security-Policy` header (fact-check Claim 3, `app-render.js:166-167`). The proxy sets CSP only on the **response**.
  - **Downstream (every client module):** the CSP string is a policy over every browser-side behaviour in `app/`: `fetch` targets (`app/lib/utils/exportGraph.ts:24,37`), worker loading (`app/lib/utils/fileExtraction.ts:26`, `app/lib/utils/pdfPropositionParser.ts:443`), inline styles (React `style={}`, KaTeX, React Flow).
  - **Route layout:** the matcher's denylist (`api`, `_next/static`, `_next/image`, `favicon.ico`) mirrors the shape of `app/` and `public/`.
- `app/layout.tsx` gains an import of `next/headers` and an `await headers()` call whose result is thrown away. It exists only to serve `proxy.ts` (making rendering dynamic so each response carries a fresh nonce). So a presentation-layer module now carries a dependency that belongs to the pipeline stage.
- Direction: the new stage depends on the framework (stable). The app depends on the new stage only implicitly, through the CSP's effects. There is no cycle.

## Findings

#### F1. The nonce reaches Next's renderer through a framework-internal side channel, not the contract the proxy sets up

**Severity:** Coupling
**Location:** `proxy.ts:41-48`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** Medium (the mechanism is static-verified across three replicates; how Vercel behaves is unconfirmed)
**Legibility-target:** for-author

**Evidence:**
```ts
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
  return response;
```
(The excerpt is the body of `proxy()` from :41; the function opens at :34 with nonce generation at :37, all read, and closes at :49.)

The proxy and the renderer have two possible channels between them. The one the proxy builds explicitly, the forwarded request headers, carries only `x-nonce`, which nothing reads. The one Next actually reads, a request-side `Content-Security-Policy` header (fact-check Claim 3), is never set. On `next start` it works only because the self-hosted router copies proxy *response* headers onto `req.headers` (`next/dist/server/lib/router-utils/resolve-routes.js:442-443`, per replicate r2). That is content coupling to an internal of one hosting adapter. On a host whose adapter does not do that copy (Vercel has not been checked), Next gets no nonce and `'strict-dynamic'` blocks every bootstrap script. The app would still pass lint and the 221 tests and then fail as a blank page. The design hides this: a reader of `proxy.ts` sees a request-header channel and assumes that is how the nonce travels.

**Recommendation:** Make the request side the explicit contract. Also set `Content-Security-Policy` on `requestHeaders` before `NextResponse.next` (Next's own CSP guide does this), and keep the response header for the browser. Then delete `x-nonce` (see F4) or keep it on purpose with a consumer. This answers escalation E1 on the structure side. Whether the failure can actually be exploited or breaks the site is for security-reviewer.

#### F2. One root-level policy string silently constrains unrelated client modules, and nothing links them or tests the link

**Severity:** Coupling
**Location:** `proxy.ts:19-32` (with comment rationale at `proxy.ts:12-17`)
**Move:** 7 (coupling surface), 2 (responsibility)
**Confidence:** High for the coupling. For the concrete breakages, see the fact-check (connect-src: High, 3/3). The pdf.js worker breakage is unverified (E3).
**Legibility-target:** for-author

**Evidence:**
```ts
function buildCsp(nonce: string): string {
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
    "connect-src 'self'",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
  ];
  return directives.join("; ");
}
```

Each directive is an assumption about modules elsewhere in `app/`. The rationale comment states those assumptions wrongly. It says "Tailwind v4 emits inline styles", but the real dependents are React `style={}`, KaTeX and React Flow (Claim 7). It says "connect-src 'self' is sufficient", but `app/lib/utils/exportGraph.ts:24,37` calls `fetch(dataUrl)` (Claim 10). The coupling runs one way and nothing records it. Someone adding a `fetch` to a new origin, a Web Worker, or a library that injects styles has no signal in their own module that a policy in a root file will block them. With no test on the policy (E6), that becomes a runtime-only failure. In this diff the first known casualty already ships: graph PNG export and export-all fail with only a `console.error`. The structural cost goes beyond those bugs. Every future client feature now implicitly depends on `proxy.ts`.

**Recommendation:** Move the policy into a small exported module (for example `app/lib/security/csp.ts`, exporting the `buildCsp` function and the directive table) with a unit test that pins each directive to the code that needs it. Fix the comment so it names the real dependents (React inline styles, KaTeX, React Flow, `data:` fetches in export). Add `data:` to connect-src, or change `exportGraph.ts` so it no longer round-trips through `fetch`. Both remedies change the policy, so they need the security-reviewer's agreement.

#### F3. The root layout carries an invisible side-effect dependency on the proxy, with a wrong stated reason

**Severity:** Minor
**Location:** `app/layout.tsx:27-31`
**Move:** 4 (layer placement), 2 (responsibility)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```tsx
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
  await headers();
```
(The excerpt ends at :31. The enclosing `RootLayout` continues to :42, rendering `<html>`/`<body>` and `{children}` with no further use of headers. All of it was read.)

The root layout (fonts, metadata, document shell) now holds a call whose only job is to change the rendering mode for the proxy's sake. The call returns a value nobody uses, so a later "unused call" cleanup could delete it, and the fallout would be a stale nonce baked into static HTML, not a build error. The comment states the mechanism wrongly: the proxy runs whether or not the page is static, and the nonce comes from the request header, not the response one (Claims 2, 3, 20; d90d6bb replaced 9b4e453's correct reason with this one). It also makes the whole route tree dynamic from the root as a side effect. That fits a per-request nonce, but it is an app-wide rendering decision buried in a font/shell module.

**Recommendation:** Use the declarative form Next provides, `export const dynamic = "force-dynamic"` in `app/layout.tsx` (or `await connection()` from `next/server`). Correct the comment to say: "dynamic so each HTML response embeds the per-request nonce Next reads from the request CSP header set in proxy.ts".

#### F4. The `x-nonce` request header is public pipeline surface with no consumer, and its comment advertises a contract that does not exist

**Severity:** Minor
**Location:** `proxy.ts:39-42`
**Move:** 3 (minimal public surface)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```ts
  // Forward the nonce to server components via a request header so layouts
  // can read it via `headers()` and pass it to <Script> tags they render.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
```
(The excerpt ends at :42. The enclosing `proxy()` continues to :49, where `requestHeaders` flows into `NextResponse.next({ request: { headers } })` at :44-46 and nowhere else. All of it was read.)

The header and its comment set up an extension point (layouts reading `x-nonce` for `<Script>`) that nothing uses. No `next/script` and no `headers().get("x-nonce")` exist anywhere in `app/` (Claim 13). Together with the layout comment saying it deliberately does *not* read `x-nonce`, the two files describe two contradictory designs for the same data flow. The next contributor cannot tell which one is load-bearing. That ambiguity is what produced F1.

**Recommendation:** Pick one contract. Either delete `x-nonce` and its comment, or keep it and record in `proxy.ts` the single supported way for a component to get the nonce (for a future `<Script nonce>`).

#### F5. The matcher is a denylist coupled to the route directory layout, so every new non-HTML route class means editing a regex

**Severity:** Minor
**Location:** `proxy.ts:55-63`
**Move:** 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```ts
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

The proxy's scope is defined by naming what to leave out, and the names track the current directory layout. Today the files in `public/` (`file.svg`, `globe.svg`, …) and non-prefetch RSC requests still run the proxy (Claim 14). Because `(?!api` has no trailing slash, any future page whose path starts with "api" (`/apiary`, `/api-docs`) silently loses CSP (E5). Each new static directory or route-handler tree outside `/api` needs a regex edit that nothing prompts. This is pragmatic at today's size, but the pipeline stage is now coupled to route naming.

**Recommendation:** Anchor the exclusion (`api/`, `api$`). Write the exclusions as a named list with a comment explaining the rule (skip anything that does not render HTML). Add a matcher unit test covering `/api/x`, `/apiary`, `/_next/static/x`, `/globe.svg` and `/`. The exploitability of the unanchored lookahead belongs to security-reviewer (E5).

#### F6. Project architecture docs do not record the new pipeline stage

**Severity:** Informational
**Location:** `CLAUDE.md` (Architecture → Directory Layout)
**Move:** 1 (dependency map)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
- `layout.tsx` — Sets up fonts (EB Garamond serif + Geist Mono) and metadata
```

The repo's architecture doc lists every module under `app/` but has no entry for `proxy.ts`, a root-level stage that now governs every page response and constrains every client module (F2). It also still describes `layout.tsx` as fonts and metadata only (F3). Contributors (and agents following CLAUDE.md) will not know the CSP exists until they hit a blocked request.

**Recommendation:** Add a `proxy.ts` line under Architecture: "per-request CSP; changing browser-side fetch/worker/style behaviour may need a directive change". Update the `layout.tsx` line too.

#### F7. Coverage note: no seam for testing the pipeline stage (E6)

**Severity:** Informational
**Location:** `proxy.ts:19`
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```ts
function buildCsp(nonce: string): string {
```

`buildCsp` is module-private and `proxy` needs a `NextRequest`, so the policy and matcher have no unit-testable seam. Extracting the policy as F2 recommends creates the seam. test-strategy owns which tests to write.

## What Looks Good

- A single responsibility, isolated in one root module that imports only `next/server`. Nothing in the app imports the proxy, so it can be removed or replaced without touching feature code.
- The policy is built by a pure function separate from the request handler, so extracting it for tests is a small step.
- Using the Next 16 `proxy.ts` convention rather than the deprecated `middleware.ts` follows the framework's intended extension point.
- Skipping `/api` and prefetches keeps the stage scoped to HTML responses, which is the right boundary in principle (F5 is about how the boundary is written, not where it sits).
- The `'unsafe-inline'` style carve-out is recorded in the code as a deliberate decision. The reason given is wrong, but the practice is right.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Nonce reaches the renderer via a router-internal header copy, not the request-side contract | Coupling | `proxy.ts:41-48` | Medium |
| 2 | Root CSP silently constrains unrelated client modules; wrong rationale, no test | Coupling | `proxy.ts:19-32` | High |
| 3 | Layout carries an invisible side-effect dependency on the proxy; wrong reason | Minor | `app/layout.tsx:27-31` | High |
| 4 | `x-nonce` is unused pipeline surface with a contradictory advertised contract | Minor | `proxy.ts:39-42` | High |
| 5 | Matcher denylist coupled to route layout; unanchored `api` | Minor | `proxy.ts:55-63` | Medium |
| 6 | CLAUDE.md does not record the new pipeline stage | Informational | `CLAUDE.md` | High |
| 7 | No test seam for policy/matcher (coverage note) | Informational | `proxy.ts:19` | High |

## Overall Assessment

The placement is sound: one isolated root module, framework-sanctioned, depending only on `next/server`. Its contracts are not. Two of them are implicit and wrong. The renderer gets its nonce through a self-hosted router's header copy rather than the request header the proxy should set (F1). The policy encodes assumptions about client modules that are already false for graph export (F2). The layout and the proxy also describe two contradictory designs for how the nonce flows (F3, F4). All of this can be fixed in place: set CSP on the forwarded request headers, extract and test the policy, use a declarative dynamic opt-out, and drop or document `x-nonce`. No restructuring is needed. The most important structural concern is F1. A cross-cutting stage that works only because of one hosting adapter's internals can fail as a blank page on another host, with every local gate green.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the architecture-review skill.
- Answered: yes
- Out of scope: whether the CSP gaps can be exploited and the exact directive fixes (connect-src `data:`, worker-src for pdf.js, dev `'unsafe-eval'`, unanchored lookahead) are security-reviewer's domain. Which tests to write is test-strategy's. No `next build` or browser run was possible (no node_modules, no network).
- Escalate: E1, structural half answered as F1. The deployment-target check (does Vercel copy proxy response headers onto the request?) still needs a host or preview run; the cheaper remedy is to set request-side CSP regardless. Any policy change from F2 or F5 needs security-reviewer sign-off.
- Decisions I made: I treated the trust-boundary cross-reference as a no-op because no security-review file existed in the worktree. I rated F1 Coupling, not Structural, because the fix is local (a few lines in `proxy.ts`) even though the impact if left unfixed is high.
