Commit: d90d6bb
# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree wt-csp @ d90d6bb)
**Scope:** branch diff d86d2dc..d90d6bb (CSP proxy + layout static-rendering opt-out)
**Checked:** 2026-08-06
**Total claims checked:** 10
**Summary:** 6 verified, 2 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Note: `docs/reviews/hallucination-patterns.md` does not exist in this worktree; proceeded normally. No fabricated-symbol patterns were confirmed (the one Incorrect verdict is a framework-behavior mismatch, not a nonexistent symbol), so no log entry is warranted.

---

## Claim 1: "Opt this layout out of static rendering so proxy.ts runs on every request and can attach a fresh per-request CSP nonce."

**Location:** `app/layout.tsx:27-31`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The mechanism named — calling a dynamic API to force dynamic rendering — is real. `await headers()` is a dynamic Next.js API, so awaiting it opts the layout out of static rendering:

```tsx
// app/layout.tsx:31
await headers();
```

The causal framing is imprecise, though: proxy/middleware runs on every matched request independently of whether the layout renders statically (matching is governed by `config.matcher` in `proxy.ts:55-62`, not by the layout's rendering mode). What the static-rendering opt-out actually affects is whether the *rendered HTML* is regenerated per request (so a per-request nonce could be embedded), not whether the proxy executes. Directionally correct intent, loose causation.

**Evidence:** `app/layout.tsx:31`, `proxy.ts:55-62`

---

## Claim 2: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium

Next.js's documented nonce auto-tagging reads the nonce from the **request** headers' `Content-Security-Policy` value (the CSP string passed into `NextResponse.next({ request: { headers } })`), not from the response header. In this diff the proxy sets the CSP only on the **response**, and sets a separate `x-nonce` on the request headers — it never places the CSP string on the request headers:

```ts
// proxy.ts:41-47
const requestHeaders = new Headers(request.headers);
requestHeaders.set("x-nonce", nonce);

const response = NextResponse.next({
  request: { headers: requestHeaders },
});
response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

Because the request-side `Content-Security-Policy` header is absent, Next.js has no nonce source to auto-tag its bootstrap `<script>` elements from (paraphrased — no quote available because this is documented Next.js framework behavior, not a symbol in this repo; the standard pattern requires `requestHeaders.set("Content-Security-Policy", csp)` before `NextResponse.next`). The comment both misnames the source (response vs request CSP header) and asserts an automatic behavior that the surrounding code does not actually enable. With `'strict-dynamic'` in `script-src` (`proxy.ts:22`), an untagged Next bootstrap script would be blocked rather than trusted — the opposite of what the comment claims. A reader acting on this comment would wrongly conclude nonce propagation is wired up.

**Evidence:** `app/layout.tsx:28-30`, `proxy.ts:22`, `proxy.ts:41-47`

---

## Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy)."

**Location:** `proxy.ts:5`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** Medium

The repo is on Next 16, and the file follows the proxy (formerly middleware) convention — a root `proxy.ts` exporting a `proxy(request)` function plus a `config` with `matcher`:

```ts
// proxy.ts:34
export function proxy(request: NextRequest): NextResponse {
```
```json
// package.json:23
"next": "16.2.4",
```

The export name (`proxy`, not `middleware`) and file location match the renamed convention. The external framework-versioning fact itself (that v16 performed the rename) is corroborated by the in-repo version and file shape but not independently verifiable from the codebase alone — hence Medium.

**Evidence:** `proxy.ts:34`, `proxy.ts:51-63`, `package.json:23`

---

## Claim 4: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust."

**Location:** `proxy.ts:7-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

This accurately describes standard CSP `'strict-dynamic'` semantics, and matches the directive built here:

```ts
// proxy.ts:22
`script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```

Under `'strict-dynamic'`, only nonce-/hash-tagged scripts execute and scripts they programmatically load inherit trust (the `'self'` and host-source expressions are ignored by supporting browsers). The described behavior is correct CSP semantics (paraphrased — no quote available because 'strict-dynamic' semantics are a CSP spec property, not code in this repo).

**Evidence:** `proxy.ts:22`

---

## Claim 5: "Why style-src 'unsafe-inline': Tailwind v4 emits inline styles."

**Location:** `proxy.ts:12-13`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High

Tailwind v4 is a project dependency, and the `style-src` directive does carry `'unsafe-inline'`:

```ts
// proxy.ts:23
"style-src 'self' 'unsafe-inline'",
```
```json
// package.json:49
"tailwindcss": "^4",
```

The checkable configuration (the directive value) and the stated dependency (Tailwind v4) both hold.

**Evidence:** `proxy.ts:23`, `package.json:49`

---

## Claim 6: "connect-src 'self' is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:16-17`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The core claim holds: all browser-originated fetches target same-origin `/api/...` routes, and the external LLM calls run server-side. Client fetches are same-origin:

```ts
// app/hooks/useAnalytics.ts:11
fetch("/api/analytics")
```
```ts
// app/components/features/context-input/ContextInput.tsx:25
const response = await fetch("/api/refine/context", {
```

The external hosts are only reached from server code gated on a server-only env var:

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```
```ts
// app/lib/llm/callLlm.ts:112
const anthropicKey = process.env.ANTHROPIC_API_KEY;
```

`callLlm.ts` is imported by API routes (e.g. `app/api/edit/whole/route.ts`), confirming the server-to-server path; `connect-src 'self'` (`proxy.ts:26`) is therefore sufficient. The imprecision: **OpenAlex** appears nowhere in the codebase except this comment — a `-i` search for `openalex` returns only `proxy.ts:16` itself (paraphrased — no quote available because the claim is about absence: no OpenAlex client/server integration exists). Naming a non-integrated service as a justifying example is a minor reference inaccuracy; the sufficiency conclusion is still correct.

**Evidence:** `proxy.ts:16-17`, `proxy.ts:26`, `app/lib/llm/callLlm.ts:7`, `app/lib/llm/callLlm.ts:112`, `app/hooks/useAnalytics.ts:11`, `app/components/features/context-input/ContextInput.tsx:25`

---

## Claim 7: "Generate a fresh nonce per request."

**Location:** `proxy.ts:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The nonce is computed inside `proxy()`, which runs per matched request, from a freshly generated UUID each invocation:

```ts
// proxy.ts:37
const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

A new `crypto.randomUUID()` is produced on every call and base64-encoded, so each request gets a distinct nonce. Fresh-per-request is accurate.

**Evidence:** `proxy.ts:34`, `proxy.ts:37`

---

## Claim 8: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in."

**Location:** `proxy.ts:35-36`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low

Whether the proxy executes in the Edge runtime and whether `Buffer`/`crypto.randomUUID` are present there are properties of the Next.js runtime environment, not of this repository. No `runtime` export or config pins the runtime in `proxy.ts` or `layout.tsx` (paraphrased — no quote available because the claim asserts a runtime environment capability that cannot be confirmed by static analysis of the codebase; it would require running the proxy or consulting Next 16 runtime docs). The code does call both symbols (`proxy.ts:37`), so it depends on the claim being true, but the claim itself is not statically checkable here.

**Evidence:** `proxy.ts:37`

---

## Claim 9: "Forward the nonce to server components via a request header so layouts can read it via headers() and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-40`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium

The forwarding half is real — `x-nonce` is set on the forwarded request headers, so a server component could read it:

```ts
// proxy.ts:42
requestHeaders.set("x-nonce", nonce);
```

But the described consumption does not occur anywhere. A repo-wide search for `x-nonce` returns only its definition in `proxy.ts:42`; no layout or component reads it, and there are no `<Script>` / `next/script` usages in the codebase (paraphrased — no quote available because the claim is about absence of consumers: grep for `x-nonce`, `<Script`, and `next/script` yields no reader). The only layout explicitly disclaims reading it (`app/layout.tsx:30`: "we don't need to read x-nonce here ourselves"). So the header is forwarded and *could* be read, but the "so layouts can read it and pass it to `<Script>` tags they render" describes a wiring that no code exercises — the `x-nonce` header is currently dead.

**Evidence:** `proxy.ts:42`, `app/layout.tsx:30`

---

## Claim 10: "Apply CSP to page navigations only. Skip API routes ..., Next's static assets ..., and prefetches ...."

**Location:** `proxy.ts:52-54`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High

The matcher matches the described exclusions:

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

The negative-lookahead `source` excludes paths beginning with `api`, `_next/static`, `_next/image`, and `favicon.ico` (API routes + static assets), and the `missing` clause excludes requests carrying prefetch markers (`next-router-prefetch` header, or `purpose: prefetch`). All three stated exclusions are present. Minor unstated nuance: only `_next/static` and `_next/image` are excluded, not all `_next/*` (e.g. `_next/data`), but that is narrower than — and consistent with — the "static assets" wording.

**Evidence:** `proxy.ts:55-62`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`app/layout.tsx:28-30`): Next.js auto-tags scripts from the **request** CSP header, not the response header, and this code never sets the CSP on request headers (only `x-nonce`), so the claimed automatic nonce-tagging is not actually enabled.

### Stale
- (none)

### Mostly Accurate
- **Claim 1** (`app/layout.tsx:27-31`): `await headers()` does opt out of static rendering, but the proxy runs per-request regardless of layout rendering mode — loose causation.
- **Claim 6** (`proxy.ts:16-17`): connect-src 'self' sufficiency is correct, but OpenAlex is named as a justifying example while having zero integration anywhere in the codebase.
- **Claim 9** (`proxy.ts:39-40`): `x-nonce` is forwarded but never consumed — no layout/component reads it and there are no `<Script>` usages; the described consumption path is dead.

### Unverifiable
- **Claim 8** (`proxy.ts:35-36`): Edge-runtime availability of `Buffer`/`crypto.randomUUID` is a framework-runtime property not checkable from the codebase; would need runtime execution or Next 16 runtime docs.
