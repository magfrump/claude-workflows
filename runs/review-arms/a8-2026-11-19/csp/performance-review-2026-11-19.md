Commit: d90d6bb

# Performance Review — meta-formalism-copilot CSP proxy (d86d2dc..d90d6bb)

**Scope:** `git diff d86d2dc..d90d6bb` — `proxy.ts` (new), `app/layout.tsx`
**Date:** 2026-11-19
**Based on:** merged code-fact-check report `code-fact-check-report.md` (k=3) and replicate r3's execution logs in `fc-r3-logs/` (`build-noheaders.log`, `build3.log`, `root-headers.txt`, `noheaders-headers.txt`, `matcher.txt`)

## Data Flow and Hot Paths

The app has one page, `/` (`app/page.tsx`, a `"use client"` component), plus 17 API routes under `app/api/`. `next.config.ts` is empty, so nothing else in the config affects caching. Before the change, `next build` prerendered `/` and `/_not-found` as static (`○ /`, `○ /_not-found` in `fc-r3-logs/build-noheaders.log:16-17`), and `next start` served `/` from the full-route cache (`x-nextjs-cache: HIT`, `Cache-Control: s-maxage=31536000`, `Content-Length: 20072` in `noheaders-headers.txt`).

After the change, `await headers()` in the root layout makes every route dynamic (`ƒ /`, `ƒ /_not-found` in `build3.log:16-17`), and `/` is served with `Cache-Control: private, no-cache, no-store, max-age=0, must-revalidate` (`root-headers.txt`). The proxy runs once for every request that passes the matcher: page navigations, non-prefetch RSC navigations, 404 paths and `public/` files (`matcher.txt`). Its own work per request is one UUID, one base64 encode, one copy of the request headers and one string join. It does no I/O.

Path temperature: both changed units are **hot**. They run on every page view, and the proxy also runs on every matched asset request. How much load this means depends on traffic, which the repo does not document. Per fact-check claim 9, the proxy runs on the Node.js runtime, not Edge. The 9b4e453 commit body says the app is deployed to Vercel previews, and `docker-compose.yml` shows a self-hosted path.

## Findings

#### Root page loses its static prerender and CDN cache; every page view becomes a full server render

**Severity:** Medium
**Location:** `app/layout.tsx:22-31`
**Move:** Find the work that moved to the wrong place (3); Question the cache (8); Price the deployment environment (10)
**Classification:** Structural (a full-route cache is removed, but the cost per request is bounded and does not grow with data) / Hot path (every navigation to `/`)
**Confidence:** High
**Baseline:** pre-change `/` served with `Cache-Control: s-maxage=31536000` (31,536,000 s shared-cache lifetime) and `x-nextjs-cache: HIT`, measured by fact-check replicate r3 on `next start` (`fc-r3-logs/noheaders-headers.txt`). Post-change: `Cache-Control: private, no-cache, no-store, max-age=0, must-revalidate` (`fc-r3-logs/root-headers.txt`). No latency or cost numbers were measured.

Evidence (`app/layout.tsx:22` and `:31`):
```tsx
export default async function RootLayout({
```
```tsx
  await headers();
```
(excerpt ends :31; the enclosing `RootLayout` continues to :42 with the `<html>/<body>` return. Read; nothing after it is cached.)

Before the change, the 20 KB HTML for `/` was built once and served from the CDN (Vercel) or from Next's in-memory full-route cache (self-hosted) on every hit. Now every page load runs the proxy and a full server-side React render of the whole client tree of `app/page.tsx`. On Vercel, that means at least one function invocation per page view, plus the proxy's own invocation, where before there was a cache hit. Every response is also `no-store`, so browsers and shared caches can no longer reuse the HTML, and back/forward navigations and reloads all go to the origin. The cost is linear in page views rather than flat. It also adds cold-start time to the critical path of first paint, which the static build never had. This cost buys correctness: a nonce CSP cannot work on cached HTML, because the HTML would carry a stale nonce. So the real question is whether a nonce-based design is the right one, not whether to delete the `headers()` call. Note also that fact-check claim 2 found the layout comment wrong about why the call is needed: dynamic rendering does not make the proxy run (the matcher does). It makes the HTML carry the fresh nonce.

**Recommendation:** Decide this trade-off on purpose and state it in the commit and the code comment. For a single-page app with no inline scripts of its own, a hash- or SRI-based CSP (Next's `experimental.sri`, or a static `script-src 'self'` policy set in `next.config.ts` `headers()`) keeps `/` static and CDN-cacheable. If nonces stay, measure the TTFB of `/` on the Vercel preview before and after the change, so the regression has a number.

#### `/_not-found` becomes dynamic, so arbitrary-path scans now cost a proxy run plus an SSR each

**Severity:** Low
**Location:** `app/layout.tsx:31`, `proxy.ts:57`
**Move:** Count the hidden multiplications (1); Price the deployment environment (10)
**Classification:** Structural (cache removed) / Hot path for unauthenticated traffic (any URL that isn't `/api`, `_next/static`, `_next/image` or `favicon.ico`)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative (build output shows `○ /_not-found` before the change and `ƒ /_not-found` after, `build-noheaders.log:17` and `build3.log:17`. r3's `matcher.txt` records `/foo -> HTTP/1.1 404 Not Found` with a CSP header, so the proxy ran.)

Evidence (`proxy.ts:57`):
```ts
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```
(excerpt ends :57; the enclosing `config.matcher` continues to :63 with the prefetch `missing` conditions. Read; they don't exclude 404s.)

Before the change, the 404 page was prerendered, so a vulnerability scanner or crawler hitting thousands of nonexistent paths (`/wp-login.php`, `/.env`, and so on) got a cached response. Now each such request runs the proxy and a dynamic render of the not-found tree. On a serverless host, the per-request cost multiplies by the number of junk requests the internet sends. The cost per request is small, but the request count is set by outside traffic, not by real users.

**Recommendation:** Accept it if the host already rate-limits. Otherwise, the hash/SRI alternative above fixes this too. To keep nonces, give `not-found` its own static treatment or narrow the matcher to the app's real routes (`/`), since the app has only one page.

#### Proxy also runs on `public/` assets and path-prefix siblings of `api`

**Severity:** Informational
**Location:** `proxy.ts:57`
**Move:** Count the hidden multiplications (1)
**Classification:** Micro (one extra proxy pass per asset request) / Hot path in principle, but cold in practice: no source under `app/` references the five `public/*.svg` files (grep found none)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

Evidence (`proxy.ts:57`):
```ts
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```
(excerpt ends :57; the enclosing `config.matcher` continues to :63. Read.)

Fact-check claim 12 (Mostly accurate) found that `public/` files still pass the matcher. Each one costs a nonce and a header copy, and on Vercel a proxy invocation, for a response that has no scripts. Because the negative lookahead has no trailing `/`, it skips not only `/api/...` but any path starting with `api` (for example `/apiary`), which is a correctness oddity rather than a performance one. The impact today is near zero, because nothing serves those assets.

**Recommendation:** If static assets are added to `public/` later, add a file-extension exclusion to the lookahead (for example `.*\\..*`), the form Next's own CSP example uses. Change `api` to `api/` in the lookahead.

## Endorsements (evidence-gated)

- API routes, `_next/static` chunks, `favicon.ico` and both prefetch header variants skip the proxy, so no nonce work is spent on them. [fact-check: claim 12 — Mostly accurate; r3 `matcher.txt` executed: `/api/analytics`, `/_next/static/...`, `/favicon.ico`, `next-router-prefetch:1` and `purpose:prefetch` all returned without a CSP header]
- The proxy's per-request work (`proxy.ts:34-49`) is a constant amount of CPU (one `randomUUID`, one base64 encode of 36 bytes, one copy of the request headers, one join of a 9-element array) with no I/O, no awaits and no module-level state that could grow. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Root page loses static prerender and CDN cache; every view becomes a full SSR, `no-store` | Medium | `app/layout.tsx:22-31` | High |
| 2 | `/_not-found` becomes dynamic; arbitrary-path scans cost a proxy run plus an SSR each | Low | `app/layout.tsx:31`, `proxy.ts:57` | High |
| 3 | Proxy runs on `public/` assets and `api*` path siblings | Informational | `proxy.ts:57` | Medium |

## Overall Assessment

The proxy itself is cheap. The real performance cost of this change is the design choice it forces: per-request nonces require dynamic HTML. That turns the app's only page and its 404 page from cached, prerendered content (measured `s-maxage=31536000`, cache HIT) into an uncacheable server render on every view. The cost is fixable in place but structural in kind. Either accept the cost explicitly, measured as TTFB on the Vercel preview, or switch to a hash/SRI-based or static `'self'` CSP that keeps `/` static. The second option also removes the fact-check's correctness doubts about how the nonce reaches Next. Nobody has measured latency or cost yet. Profile one before/after page load on the actual deployment target before deciding.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the performance-reviewer skill.
- Answered: yes
- Out of scope: Correctness of the CSP itself (whether the nonce reaches Next on Vercel, `connect-src` breaking `fetch(dataUrl)` export, pdf.js `worker-src`). These are security/correctness issues already escalated by the fact-check (E1-E3), not performance issues.
- Escalate: Finding 1's trade-off (nonce CSP forces dynamic rendering, while a hash/SRI or static `'self'` CSP keeps `/` cacheable) should reach architecture-review/security-reviewer alongside fact-check E1, because the same alternative resolves both.
- Decisions I made: I used r3's measured `Cache-Control`/`x-nextjs-cache` headers as Finding 1's baseline, because they are a real execution measurement even though they are not a latency number. I calibrated Finding 1 at Medium rather than the Macro × Hot default of High, because the extra per-request cost is a bounded single-page SSR and does not grow with data.
