# Performance Review — csp-dirty (d86d2dc..d90d6bb)

**Scope:** `git diff d86d2dc..d90d6bb` — `proxy.ts` (new, 64 lines: `buildCsp` + `proxy` + `config.matcher`) and `app/layout.tsx` (RootLayout made `async`, `await headers()` added). Commits outside the range are context only.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3), treated as foundation and not re-verified.

Commit: d90d6bb

---

### Data Flow and Hot Paths

Request path introduced by this change, per non-excluded HTTP request:

1. **Proxy invocation** (`proxy.ts:34`) — Next.js 16 runs `proxy` on the **Node** runtime (the inline comment at `proxy.ts:35-36` says "Edge runtime"; the fact-check confirms this is wrong). It fires for every request matching `config.matcher` (`proxy.ts:55`): everything except `api/*`, `_next/static/*`, `_next/image/*`, `favicon.ico`, and requests carrying `next-router-prefetch` / `purpose: prefetch`.
2. **Nonce generation** (`proxy.ts:37`) — `crypto.randomUUID()` → `Buffer.from(...)` → base64.
3. **Request-header clone** (`proxy.ts:41-45`) — full `Headers` copy, `x-nonce` set, passed to `NextResponse.next({ request: { headers } })` so Next forwards overridden request headers downstream. Per the fact-check, **`x-nonce` is never read anywhere in the app.**
4. **CSP construction + header write** (`proxy.ts:47`, `proxy.ts:20-31`) — 9-element array allocated and `join("; ")`-ed into a ~270-byte string, written to the response.
5. **Render** — `app/layout.tsx:31` `await headers()` marks the root layout dynamic, which per the fact-check forces **dynamic rendering for the entire app**. The one page route in the repo (`app/page.tsx`, the only `page.tsx` in `app/`) is a `"use client"` SPA shell; it was statically prerendered at build before this change and is now server-rendered on every request.

**Size of N.** N is *requests*, not items: this repo has exactly one page route, no dynamic route segments, and no per-item server loops in the diff. The app is a single-page client workspace persisting state to `localStorage` (README), deployed via `docker-compose` + `next start` (long-lived Node server, so no per-request cold start). Realistic navigation volume is low — a handful of full page loads per user session, with all subsequent interaction happening client-side. **Every finding below is bounded by that N**, and the severities are the structural severities; absolute wall-clock impact on this deployment is small. Nothing in the diff touches databases, ORMs, per-item loops, or background workers, so items (5) database patterns and (7) contention points of the review checklist have no findings.

---

### Findings

#### F1 — `await headers()` in RootLayout trades the app's entire static prerender for per-request SSR

**Severity:** High
**Location:** `app/layout.tsx:31` (and the `async` signature at `app/layout.tsx:26`)
**Move:** (3) work moved to the wrong place — build time → per-request hot path
**Classification:** Macro / Hot (request handler: this is the root layout of the only route; it executes on every non-prefetch page navigation)
**Confidence:** High that the mechanism holds (fact-check verified); Medium on magnitude, which is unmeasured.
**Baseline:** no baseline available — flagged as speculative. Structural size for scale, not a measurement: 60 component files under `app/components/`, 6,341 LOC across those plus `app/page.tsx`, all reachable from the single route and all SSR-rendered on the server even though they are client components.
**Evidence:**
```
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
  await headers();
```
**Legibility-target:** the reviewer who reads "opt out of static rendering" as a one-line annotation rather than as "the Full Route Cache is now off for the whole app."

Before this commit, `/` was prerendered once at build and served from the Full Route Cache; the server did no React work per navigation. After it, the entire client-component tree is SSR-rendered on every request — the scaling factor is 1× at build → 1× **per page load**, i.e. work multiplied by navigation count instead of by deploy count. The comment's stated reason is also wrong (the fact-check confirms the proxy runs regardless of whether the layout is dynamic); the real reason is that a per-request nonce must not be baked into cached HTML, which is a correct requirement but a much more expensive one than the comment implies. This is High rather than Critical because the growth is bounded and linear in navigations, and this deployment's navigation volume is low — a public, traffic-bearing deployment would push it to Critical.

**Recommendation:** Keep the dynamic opt-out only if nonce-based CSP is a hard requirement, and record the tradeoff explicitly (the current comment misstates it). If it is not, the cheaper shapes are: (a) drop nonces and use hashes or `'strict-dynamic'` without a per-request value, restoring the static prerender; or (b) if some future route is static and script-free, scope the opt-out to the route(s) that need it rather than the root layout. Before either, measure: `next build` output (static vs `ƒ` dynamic marker for `/`) plus TTFB on `/` at d86d2dc vs d90d6bb gives the real number in minutes.

---

#### F2 — The dynamic opt-out is placed at the root layout, so it cascades to every route added later

**Severity:** Medium
**Location:** `app/layout.tsx:31`
**Move:** (3) work in the wrong place; (9) asymptotic behavior — the cost grows with future route count, not with current load
**Classification:** Macro / Cold (no such routes exist today; this is a cost that arrives with future work)
**Confidence:** Medium — depends on whether the project ever adds static routes.
**Baseline:** no baseline available — flagged as speculative. Current route count: 1 (`app/page.tsx`); 16 API route handlers, which the matcher already excludes and which are dynamic anyway.
**Evidence:**
```
export default async function RootLayout({
```
**Legibility-target:** the future contributor who adds a docs or landing route and cannot understand why it will not prerender.

The root layout wraps every route in the app, so any route added later — a marketing page, a docs page, a shared/read-only artifact view — inherits forced dynamic rendering whether or not it renders scripts that need a nonce. The scaling factor is per-route: each new static-capable route silently converts into a per-request render. Today the blast radius is one route, which is why this is Medium and not High.

**Recommendation:** Leave a comment at the opt-out naming the cascade explicitly, or move the nonce dependency into a segment layout under a route group so script-free routes can stay static. Revisit if a second route is added.

---

#### F3 — Per-request `Headers` clone and request-header override forward an `x-nonce` that nothing reads

**Severity:** Low-Medium
**Location:** `proxy.ts:41-45`
**Move:** (1) hidden multiplication — a cost paid on every matched request for a consumer that does not exist
**Classification:** Micro / Hot (proxy body, every non-excluded request)
**Confidence:** High — the fact-check confirms `x-nonce` is forwarded but never read, and the layout comment itself says the app does not read it.
**Baseline:** no baseline available — flagged as speculative. Order of magnitude: one `Headers` allocation plus a copy of every inbound request header (browser requests typically carry 10-20) per request.
**Evidence:**
```
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
```
**Legibility-target:** the reader who assumes the forwarded header is load-bearing and preserves it during a later refactor.

This is dead work, not slow work: the clone allocates and copies the full inbound header set, and passing `request.headers` to `NextResponse.next` makes Next serialize the overridden headers into its internal request-header channel for the downstream render — on every matched request, forever, for a value no server component consumes. The scaling factor is 1 clone + 1 header-serialization per request. It is only Low-Medium because the per-request cost is microseconds, but it is the highest-value item in this report by fix-cost: the fix is deletion.

**Recommendation:** Delete lines 41-45 and use a bare `NextResponse.next()`. If a future `<Script nonce>` needs the value, reintroduce the forwarding at that point, next to its consumer.

---

#### F4 — `buildCsp` rebuilds a 9-element array and re-joins a constant string on every request

**Severity:** Low
**Location:** `proxy.ts:19-32`, called from `proxy.ts:47`
**Move:** (3) work that belongs at module init sitting in the per-request path
**Classification:** Micro / Hot (called once per matched request)
**Confidence:** High on the mechanism; Low that it is worth fixing on its own.
**Baseline:** no baseline available — flagged as speculative. Eight of nine directives are compile-time constants; only `script-src` varies.
**Evidence:**
```
function buildCsp(nonce: string): string {
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```
**Legibility-target:** the reader who sees a function call and assumes something request-dependent is being computed across all nine directives.

Only the `script-src` directive depends on the nonce; the other eight are constants that could be joined once at module load into a static prefix and suffix, reducing per-request work to a two-part template concatenation. The scaling factor is one array allocation plus one 9-element join per request. Constants, not asymptotics — this will never show up in a profile at this app's request volume, and the current form is more readable than the optimized one, so this is recorded for completeness rather than as a change worth making.

**Recommendation:** No action recommended. If the proxy ever runs at meaningfully higher volume, hoist the constant directives into a module-level `const CSP_PREFIX` / `CSP_SUFFIX` pair.

---

#### F5 — Nonce encoding doubles the header bytes and defeats HTTP/2 header-table compression

**Severity:** Low
**Location:** `proxy.ts:37`
**Move:** (6) serialization tax
**Classification:** Micro / Hot (every matched response)
**Confidence:** Medium — the byte arithmetic is certain; the HPACK/QPACK consequence is a property of the protocol, not something measured here.
**Baseline:** no baseline available — flagged as speculative. Byte counts: `crypto.randomUUID()` produces a 36-character ASCII string carrying ~122 bits of entropy; base64 of those 36 bytes is 48 characters. The equivalent entropy from 16 random bytes is 24 base64 characters. Full CSP header ≈ 270 bytes.
**Evidence:**
```
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```
**Legibility-target:** the reader who takes the adjacent comment's runtime claim ("available in the Edge runtime that Next proxy runs in") at face value — the fact-check establishes this runs on Node.

Base64-encoding the *textual* UUID rather than its underlying bytes carries the hyphens and hex expansion through the encoding, so the nonce is 48 bytes where 24 would carry the same entropy. More consequentially, because the nonce changes on every response, the `Content-Security-Policy` header can never be served from the HPACK/QPACK dynamic table — roughly 270 bytes go on the wire uncompressed per response, and response headers are not gzipped. The scaling factor is ~270 bytes × responses; at this app's volume that is noise, which is why it is Low.

**Recommendation:** If touched for other reasons, switch to `Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString("base64")` — shorter, cheaper, same security property. Also fix the comment's runtime claim so future readers do not reason about Edge-runtime constraints that do not apply.

---

#### F6 — The matcher does not exclude `public/` assets, so the proxy runs on files that contain no scripts

**Severity:** Low-Medium
**Location:** `proxy.ts:55-63`
**Move:** (1) hidden multiplication — proxy cost × asset requests
**Classification:** Micro / Hot (asset requests are part of every cold page load)
**Confidence:** Medium — depends on how many static files are requested per load; today `public/` holds 5 SVGs and none are obviously referenced by the app shell.
**Baseline:** no baseline available — flagged as speculative. `public/` contains 5 files (`file.svg`, `globe.svg`, `next.svg`, `vercel.svg`, `window.svg`); the matcher's negative lookahead excludes only `api`, `_next/static`, `_next/image`, and `favicon.ico`.
**Evidence:**
```
    source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```
**Legibility-target:** the reader who reads the comment "Apply CSP to page navigations only" and believes the matcher achieves that — it does not; it matches any root-level static file, plus 404s, `robots.txt`, `sitemap.xml`, and anything else added to `public/` later.

Files served from `public/` sit at the site root and therefore match, so each such request generates a nonce, clones headers, builds a CSP string, and attaches it to a response that has no scripts to authorize. The scaling factor is one full proxy pass per static asset request rather than per navigation, and it grows with whatever is added to `public/` later. It stays Low-Medium because the current asset set is tiny and the deployment is a long-lived Node server (no per-invocation billing or cold start); on a serverless deployment each of these becomes a separate function invocation and the finding rises to Medium.

**Recommendation:** Extend the negative lookahead with a file-extension guard, e.g. `/((?!api|_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico|txt|xml)$).*)`, so the proxy fires on HTML navigations only — which is what the comment already claims.

---

#### F7 — The proxy runs on the Node runtime while the comment asserts Edge, so the cost model in the code is wrong

**Severity:** Informational
**Location:** `proxy.ts:35-36`
**Move:** (9) asymptotic behavior vs constants — the comment invites reasoning against the wrong constants
**Classification:** Micro / Hot (documentation of a hot path)
**Confidence:** High on the fact (fact-check verified); the *performance* consequence is deployment-dependent and nil on this one.
**Baseline:** no baseline available — flagged as speculative. Deployment is `docker-compose` + `next start` (a long-lived Node server), so there is no per-request cold-start component today.
**Evidence:**
```
  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
  // available in the Edge runtime that Next proxy runs in.
```
**Legibility-target:** anyone sizing the proxy's per-request cost, or deciding later to move this deployment to a serverless host.

The fact-check establishes that Next 16 runs the proxy on Node, not Edge. On the current long-running-server deployment this costs nothing — Node is already warm and in-process. It is recorded because the comment will mislead a later reader who is either (a) adding an API-heavy dependency to the proxy under the false belief that Edge constraints apply, or (b) estimating serverless invocation cost, where Node-runtime proxy invocations are materially heavier than Edge ones.

**Recommendation:** Correct the comment to say Node runtime. No code change.

---

### What Looks Good

- **Prefetch exclusion is work correctly removed from the hot path** (`proxy.ts:57-60`). Next's router prefetches a lot; excluding `next-router-prefetch` and `purpose: prefetch` means the proxy does not run — and, given F1, no dynamic render is triggered — for requests that may never paint. This is the single best perf decision in the diff and the comment explaining it is accurate.
- **`api`, `_next/static`, and `_next/image` exclusions** correctly keep the proxy off the paths with the highest request counts and no HTML to protect.
- **`buildCsp` is a pure function of the nonce** with no I/O, no allocation beyond the string, and no async work — the proxy body has zero awaits and cannot block the request pipeline.
- **Font loading is unaffected.** `next/font/google` (`app/layout.tsx:2`) resolves at build time; making the layout `async` does not move font fetching into the request path.
- **No database, ORM, N+1, cache, or per-item loop was introduced.** The diff adds no queries and no collection iteration, so the classic hot-path multiplication patterns are absent by construction.

---

### Summary Table

| # | Finding | Severity | Class / Temp | Location |
|---|---------|----------|--------------|----------|
| F1 | `await headers()` forces per-request SSR app-wide, losing the static prerender | High | Macro / Hot | `app/layout.tsx:31` |
| F2 | Dynamic opt-out at root layout cascades to all future routes | Medium | Macro / Cold | `app/layout.tsx:31` |
| F3 | Per-request `Headers` clone forwards an `x-nonce` nothing reads | Low-Medium | Micro / Hot | `proxy.ts:41-45` |
| F6 | Matcher does not exclude `public/` assets; proxy runs on script-free files | Low-Medium | Micro / Hot | `proxy.ts:55-63` |
| F4 | `buildCsp` rebuilds 8 constant directives per request | Low | Micro / Hot | `proxy.ts:19-32` |
| F5 | Nonce encoding doubles header bytes; defeats HPACK/QPACK caching | Low | Micro / Hot | `proxy.ts:37` |
| F7 | Comment asserts Edge runtime; proxy runs on Node | Informational | Micro / Hot | `proxy.ts:35-36` |

---

### Overall Assessment

The performance story of this change is one decision and a handful of constants. The decision — `await headers()` in the root layout (F1) — converts the app from "render once at build" to "render on every navigation," and it is not visible as a performance change anywhere in the diff: the comment that introduces it describes it as an opt-out to make the proxy run, which the fact-check shows is not even the real reason. That framing is the main risk here, more than the cycles: a reader auditing this file for cost will not find the cost. If per-request nonces are a firm requirement, the tradeoff is defensible and should simply be written down accurately; if they are not, hashes or a nonce-free `'strict-dynamic'` policy restores the prerender.

Everything else is constants (F3-F5, F7) plus one matcher gap (F6). Their combined per-request cost is microseconds, and this deployment — a single-route, `localStorage`-backed SPA behind a long-lived Node server — has a request volume where none of them will surface in a profile. F3 is nonetheless worth doing today because the fix is deleting five lines of provably dead work, and F6 because the matcher does not do what its own comment says. No measured baseline exists anywhere in this repo; every number in this report is either a structural count from the source or explicitly flagged as speculative. The cheapest way to replace all of it with real data is a `next build` output diff (static vs dynamic marker on `/`) plus TTFB on `/` at d86d2dc vs d90d6bb.

---

## Goal-Alignment Note

- **Answered:** Per-request cost introduced by the new proxy (nonce generation, header cloning, CSP construction, matcher breadth) and the app-wide rendering-model change caused by `await headers()` in the root layout; where work moved from build time into the request path; which of it is dead work; asymptotic vs constant-factor separation; serialization cost of a per-response CSP header. Positive findings recorded where work was correctly kept out of the hot path (prefetch and static-asset exclusions).
- **Out of scope:** Whether the CSP policy is *secure* (nonce entropy adequacy, `style-src 'unsafe-inline'`, `'strict-dynamic'` semantics) — security-reviewer's call, and F5's encoding note is a byte-count observation, not a security judgment. Whether the `x-nonce` contract should exist at all as an interface — api-consistency. Correctness of the code comments as claims — already established by the merged fact-check and consumed here as foundation, not re-verified. No fix loop was run: this is a measurement pass and no code was modified.
- **Escalate:** (1) F1 needs a product decision, not a perf fix — is per-request nonce CSP a hard requirement for this app? If yes, F1 is accepted cost and only the comment needs correcting; if no, reverting `await headers()` removes the entire macro finding. (2) No performance baseline of any kind exists in this repo, so every severity here is reasoned from code structure alone; if this deployment ever becomes multi-user or moves to a serverless host, F1 and F6 both escalate and should be re-reviewed with measurements in hand.
