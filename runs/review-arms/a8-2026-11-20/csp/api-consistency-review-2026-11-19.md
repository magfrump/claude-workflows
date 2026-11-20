Commit: d90d6bb

# API Consistency Review — CSP proxy (d86d2dc..d90d6bb)

**Scope:** `git diff d86d2dc..d90d6bb` (3 commits; `proxy.ts` new, `app/layout.tsx` modified), meta-formalism-copilot
**Date:** 2026-11-19
**Based on:** `code-fact-check-report.md` (merged k=3, most-severe-wins) in this directory

## Baseline Conventions

Surveyed in the worktree at d90d6bb:

- **Request-handling exports.** 17 App Router handlers under `app/api/**/route.ts` export `async function <VERB>(request: NextRequest)` with **no explicit return type** and return `NextResponse.json(...)` (for example `app/api/analytics/route.ts:4`, `app/api/edit/whole/route.ts:18`, `app/api/formalization/lean/route.ts:75`). Library and hook exports under `app/lib/**` and `app/hooks/**` do declare explicit return types (`app/lib/utils/export.ts:35`, `app/lib/utils/workspacePersistence.ts:79`, `app/hooks/useFormalizationPipeline.ts:49`).
- **Route namespace.** Everything under `app/api/` is a JSON API path at `/api/<domain>/<action>`. Pages are `app/page.tsx` plus the root layout. No page path starts with `api` today.
- **Published HTTP headers.** Before this change the repo set no custom request or response headers anywhere: no `x-*` header, no `headers()` block in `next.config.ts` (the config is empty, `next.config.ts:3-5`), and no earlier `middleware.ts`. This diff is the first of its kind for header policy, the framework-convention file (`proxy.ts`) and the `config.matcher` export.
- **Route-segment config exports.** None in `app/` (searched `export const (config|runtime|dynamic|maxDuration|revalidate)` under `app/`).
- **Browser-side network consumers.** `app/lib/utils/exportGraph.ts` calls `fetch()` on a `data:` URL from the browser (lines 24 and 37), reached from `app/components/panels/GraphPanel.tsx:102-104` and `app/lib/utils/exportAll.ts:64`.

No `node_modules` is present in the worktree, so Next 16's own file-convention docs could not be read locally. Framework-contract statements below rely on the Stage-1 fact-check, which did read Next's dist code in at least one replicate.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `proxy` (export) | exported function (framework entry point) | `GET`, `POST`, `DELETE` route-handler exports | `app/api/**/route.ts` | Consistent: the name is fixed by Next 16's file convention, not chosen by the author. The explicit `: NextResponse` return type differs from the handler siblings (Finding 6). |
| `config` (export, with `matcher`) | config schema | _(no route-segment config exports exist)_ | none — searched `app/**` for `export const (config\|runtime\|dynamic\|maxDuration\|revalidate)` and `next.config.ts` | New category. The shape is framework-defined. |
| `x-nonce` | published request header | _(no custom headers anywhere)_ | none — searched `app/**`, `proxy.ts` and `next.config.ts` for `"x-` and `.headers.set` | New category. The name follows Next's CSP guide (route: code-fact-check, unread locally). It has no reader (Finding 3). |
| `Content-Security-Policy` | published response header | _(no response-header policy anywhere)_ | none — same search, plus `next.config.ts` `headers()` | New category. It establishes the convention that security headers live in `proxy.ts` rather than in `next.config.ts` `headers()` (Finding 7). |
| `buildCsp` | module-private function | n/a | n/a | Not public (not exported), so it is outside the audit. Noted only because it appears in the diff. |
| `RootLayout` (now `async`) | default export | `Home` in `app/page.tsx` | `app/page.tsx` | The name is unchanged. Making the default export `async` is compatible with how Next consumes it. |

## Findings

#### 1. The connect-src contract breaks two existing in-app consumers (graph PNG export and export-all)

**Severity:** Breaking
**Location:** `proxy.ts:26`; consumers at `app/lib/utils/exportGraph.ts:24,37`
**Move:** 3 (trace the consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`proxy.ts:26`):
```
    "connect-src 'self'",
```
Evidence (`app/lib/utils/exportGraph.ts:20-26`, excerpt ends :26; enclosing `downloadGraphAsPng()` continues to :27 — read):
```
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
  triggerDownload(blob, filename);
```
Evidence (`app/lib/utils/exportGraph.ts:37-38`, the last two lines of `graphToPngBlob()`, read from :30 to :39):
```
  const res = await fetch(dataUrl);
  return res.blob();
```

The policy the proxy now publishes covers browser `fetch()` calls. `connect-src 'self'` does not list `data:`, so the `fetch(dataUrl)` in both exported helpers is refused. These helpers are existing public functions with live callers: `GraphPanel.tsx:102-104` (the PNG download button) and `exportAll.ts:64` (the zip export). Both features worked before this change and fail after it. The comment at `proxy.ts:16-17` says connect-src only has to cover the app's own API calls, so the contract was defined without checking browser-side `fetch` calls in `app/lib`. The Stage-1 fact-check found this 3/3 (Claim 10).

**Recommendation:** Either add `data:` to `connect-src`, or change the two helpers to turn the data URL into a Blob without `fetch` (for example with `html-to-image`'s `toBlob`). Add a test that pins the directive list so the next tightening is checked against browser-side consumers.

#### 2. The nonce is published on the side the renderer does not read

**Severity:** Breaking
**Location:** `proxy.ts:41-48`, `app/layout.tsx:28-30`
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** Medium (Stage-1 split: r1 and r3 say every bootstrap script is blocked; r2 says `next start` copies the proxy's response headers onto the request, so it works there; Vercel is unconfirmed)
**Legibility-target:** for-author

Evidence (`proxy.ts:41-48`, read from the function's signature at :34 to its last line, :49):
```
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
  return response;
```
Evidence (`app/layout.tsx:28-30`):
```
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
```

The proxy has two consumers: the browser, which enforces the response CSP, and Next's renderer, which tags its own `<script>` elements. They need the same nonce. The proxy gives the renderer `x-nonce`, which Next does not read, and gives the CSP only to the response. According to the fact-check (Claim 3, `app-render.js:166-167`), the renderer looks for the nonce in the **request** `Content-Security-Policy` header. Whether the two sides match therefore depends on the host router copying response headers onto the request (`resolve-routes.js:442-443` on `next start`) and is not guaranteed by the proxy itself. Where the copy does not happen, `'strict-dynamic'` plus an untagged bootstrap blocks every script, and every page breaks. The layout comment documents the response-header reading as intended behavior, which hides the dependency.

**Recommendation:** Also set `Content-Security-Policy` on `requestHeaders`, as Next's CSP guide does, so the renderer gets the nonce directly and the result does not depend on the host. Then fix the comment at `app/layout.tsx:28-30`. Exploitability and deployment are routed to security-reviewer and architecture-review (E1).

#### 3. `x-nonce` is a published request header with no reader, and the two comments describing it contradict each other

**Severity:** Minor
**Location:** `proxy.ts:39-42`, `app/layout.tsx:30`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`proxy.ts:39-42`):
```
  // Forward the nonce to server components via a request header so layouts
  // can read it via `headers()` and pass it to <Script> tags they render.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
```

The comment at `proxy.ts:39-40` documents a consumer (layouts reading `x-nonce` and passing it to `<Script>`) that does not exist. There is no `<Script>` in `app/` (Claim 13), and `app/layout.tsx:30` says the layout deliberately does not read `x-nonce`. A future reader gets two opposite descriptions of the same header. That matters because `x-nonce` is the hook anyone adding `<Script>` or an inline script will reach for.

**Recommendation:** Keep `x-nonce` and make the comment say it is reserved for future `<Script>` or inline-script use, with no reader today. Or drop it until a reader exists. Either way, make the two comments agree.

#### 4. The matcher's `api` exclusion is a prefix, not the `/api/` namespace

**Severity:** Minor
**Location:** `proxy.ts:57`
**Move:** 2 (naming against the grain: the route-path namespace)
**Confidence:** High
**Legibility-target:** for-author

Precedent: the API namespace is the directory `/api/<domain>/<action>`, used in `app/api/**/route.ts`

Evidence (`proxy.ts:57`):
```
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

The repo's API surface is the `/api/` path segment. The lookahead excludes any path whose first characters are `api`, so a future page such as `/apiary`, `/api-docs` or `/apis` gets no CSP and no error. The comment at `proxy.ts:52` says "Skip API routes", which describes the segment, not the prefix. The same applies to `favicon.ico`: its `.` is an unescaped regex wildcard, which is harmless but imprecise.

**Recommendation:** Anchor the segment: `(?!api/|api$|_next/static|_next/image|favicon\.ico)`. Also routed to security-reviewer as E5.

#### 5. Published docs inside the change describe a runtime and a styling contract that differ from the code

**Severity:** Minor
**Location:** `proxy.ts:12-14`, `proxy.ts:35-36`
**Move:** 3 (documentation drift; built on fact-check Claims 7 and 11)
**Confidence:** High (3/3 in Stage 1)
**Legibility-target:** for-author

Evidence (`proxy.ts:35-36`):
```
  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
  // available in the Edge runtime that Next proxy runs in.
```
Evidence (`proxy.ts:12-14`):
```
 * Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening
 * to nonces would require rebuilding how Tailwind ships styles in dev and
 * SSR. Documented as a deliberate carve-out, not an oversight.
```

`proxy.ts` is the first framework-contract file in the repo, so its header comment is the documentation the next contributor will rely on. The Next 16 proxy runs on Node.js, not Edge, and the `'unsafe-inline'` carve-out is needed for React `style={}` props, KaTeX and React Flow, not for Tailwind v4, which ships an external stylesheet. A contributor following the stated reason could remove the carve-out and break those components. A contributor trusting the Edge note could avoid Node APIs for no reason.

**Recommendation:** Correct both comments. Name the real reasons for `'unsafe-inline'` (inline `style` attributes from React, KaTeX and React Flow).

#### 6. Explicit return type on `proxy` differs from the request-handler siblings

**Severity:** Informational
**Location:** `proxy.ts:34`
**Move:** 2
**Confidence:** High
**Legibility-target:** for-author

Precedent: request entry points omit the return type, `export async function POST(request: NextRequest)`, used in `app/api/**/route.ts` (17 files)

Evidence (`proxy.ts:34`):
```
export function proxy(request: NextRequest): NextResponse {
```

The closest siblings, the route handlers that take a `NextRequest` and return a `NextResponse`, never annotate the return type. Library code under `app/lib/**` does, so either style has precedent in the repo, and this is not a defect. It is listed so the choice made in d90d6bb is deliberate. Under the naming-severity table it would be Minor; it is downgraded here because the repo has both conventions.

**Recommendation:** None required. If handlers should start using explicit return types, record that as a convention rather than leaving one file as the outlier.

#### 7. First response-header policy: this sets where security headers live

**Severity:** Informational
**Location:** `proxy.ts:47`, `next.config.ts:3-5`
**Move:** 1 / 2 (new category)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

No existing precedent in `app/**`, `proxy.ts`, `next.config.ts` (searched for `.headers.set`, `"x-`, `Content-Security`, `headers()`)

Evidence (`proxy.ts:47`):
```
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

This is the repo's first published response header. Putting it in `proxy.ts` is required for a per-request nonce. But it also sets the convention that future static security headers (`X-Content-Type-Options`, `Referrer-Policy`, HSTS) go here too, where they would be skipped for `/api/*` and prefetches because of the matcher, rather than in `next.config.ts` `headers()`, which covers every path. `frame-ancestors 'none'` likewise does not reach API responses. The skill's precedent rule downgrades this to Informational (it is already at the floor).

**Recommendation:** Add one line to `proxy.ts` saying that per-request headers belong here and static headers go in `next.config.ts` `headers()`, so the matcher's exclusions do not silently narrow future headers.

## What Looks Good

- The `proxy` and `config` export names and shapes match the Next 16 file convention described in the 9b4e453 commit body (route: code-fact-check; Claim 16 is Unverifiable without a build).
- `RootLayout` keeps its name and props type. Making it `async` is compatible with its only consumer, the Next renderer (route: code-fact-check).
- `buildCsp` is module-private, so the directive list adds no exported surface.
- The d90d6bb refactor kept the directive list byte-for-byte identical (`git diff 9b4e453 d90d6bb -- proxy.ts` touches only the runtime comment and inlines the `csp` local; no directive line changed). Route: code-fact-check.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `connect-src 'self'` breaks graph PNG export and export-all (`fetch(data:)`) | Breaking | `proxy.ts:26`, `app/lib/utils/exportGraph.ts:24,37` | High |
| 2 | Nonce reaches the renderer only through the host's header copy; CSP is never set on the request | Breaking | `proxy.ts:41-48`, `app/layout.tsx:28-30` | Medium |
| 3 | `x-nonce` has no reader; the proxy and layout comments contradict each other | Minor | `proxy.ts:39-42`, `app/layout.tsx:30` | High |
| 4 | Matcher excludes the `api` prefix, not the `/api/` segment | Minor | `proxy.ts:57` | High |
| 5 | Header-comment contract wrong (Edge runtime, Tailwind reason) | Minor | `proxy.ts:12-14,35-36` | High |
| 6 | Explicit return type differs from route-handler siblings | Informational | `proxy.ts:34` | High |
| 7 | First response-header policy sets the convention for where security headers live | Informational | `proxy.ts:47`, `next.config.ts:3-5` | High |

## Overall Assessment

The new surface is small and mostly fixed by the framework, so its names cause no real problem. The trouble is in the contracts it publishes. The CSP breaks two existing exported helpers that have live UI callers (Finding 1, certain). The nonce handoff between proxy and renderer depends on host behavior the code does not control, which may break every page (Finding 2, deployment-dependent). Both can be fixed in place with a few lines in `proxy.ts`. The documentation in the change describes consumers, runtimes and reasons that do not match the code (Findings 3 and 5). As the repo's first framework-convention and header-policy file, it should be corrected before it becomes the template. No tests pin the directive list or the matcher (E6), which is how Finding 1 got through.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the api-consistency-reviewer skill.
- Answered: yes
- Out of scope: Whether the CSP stops XSS (security-reviewer), and the pdf.js worker-src and dev 'unsafe-eval' questions (E3, E4; these are security and runtime, not surface consistency). Next's framework docs could not be read: no `node_modules` in the worktree.
- Escalate: (a) Finding 2 / E1: confirm on Vercel whether proxy response headers reach the renderer's request; owner-facing deployment check. (b) Finding 1 / E2: Breaking regression with High confidence; it should block shipping. (c) E6: a test pinning the directive list and matcher would have caught Finding 1.
- Decisions I made: Rated Finding 2 Breaking at Medium confidence despite r2's dissent, because the change's own correctness depends on undocumented host behavior. Treated Finding 4 as naming-shaped (route namespace) and cited the `app/api/**` precedent, so it was not downgraded.
