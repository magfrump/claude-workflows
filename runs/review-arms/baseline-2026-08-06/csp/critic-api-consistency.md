Commit: d90d6bb
# API Consistency Review — CSP proxy + layout static-rendering opt-out

**Scope:** `git diff d86d2dc..d90d6bb` (worktree wt-csp @ d90d6bb) — `proxy.ts` (new), `app/layout.tsx`
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/csp/fact-check.md`

## Baseline Conventions

This diff introduces the codebase's **first** proxy/middleware and the first custom HTTP-header contract, so most "conventions" are being established here rather than matched. What baseline exists:

- **Framework entrypoint names:** Next 16 mandates `proxy` (function) and `config` (with `matcher`) as the exported names for a root `proxy.ts`. Matches the renamed-middleware convention (fact-check Claim 3, verified). Consistent by construction.
- **Header-object naming:** the only prior art for setting HTTP headers is `SSE_HEADERS` in `app/lib/llm/streamLlm.ts:12-16`, which uses Title-Case-Dash keys: `Content-Type`, `Cache-Control`, `Connection`.
- **Response construction:** all API routes use `NextResponse.json(...)` (e.g. `app/api/edit/whole/route.ts:33`); `proxy.ts` correctly uses `NextResponse.next(...)` instead, which is the right primitive for a pass-through proxy (not a JSON responder). No inconsistency.
- **No existing custom request headers** anywhere in `app/` (grep for `headers.set` / `x-` outside `proxy.ts` returns nothing), so `x-nonce` is the first inbound-header contract.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|----------|----------|------------------|----------------|---------|
| `proxy` | function (framework export) | _(no prior middleware/proxy)_ | none — searched repo root for `proxy.ts`/`middleware.ts` | Framework-mandated name; consistent with Next 16 convention |
| `config` | export (framework) | route-level `SSE_HEADERS`-style consts; no prior `config` export | none — first proxy config | Framework-mandated; consistent |
| `buildCsp` | function (module-private) | `mockWholeResponse`, `transformSseStream` (verb-noun camelCase) | `app/lib/llm/*.ts` | Consistent — verb-noun camelCase; not exported |
| `Content-Security-Policy` (response header) | HTTP header | `Content-Type`, `Cache-Control` | `app/lib/llm/streamLlm.ts:12-16` | Consistent — Title-Case-Dash matches `SSE_HEADERS` |
| `x-nonce` (request header) | HTTP header | `Content-Type`, `Cache-Control`, `Connection` | `app/lib/llm/streamLlm.ts:12-16` | Inconsistent — lowercase vs the Title-Case-Dash precedent |

## Findings

#### `x-nonce` request-header contract is defined but has no consumer, and its documented purpose contradicts itself across files

**Severity:** Inconsistent
**Location:** `proxy.ts:39-42`, `app/layout.tsx:28-30`
**Move:** #3 (consumer contract), #7 (asymmetry)
**Confidence:** High

`proxy.ts` establishes a request-header contract — `x-nonce` forwarded to server components — and documents it as "so layouts can read it via `headers()` and pass it to `<Script>` tags they render" (`proxy.ts:39-40`). No code consumes it: fact-check Claim 9 confirms a repo-wide search for `x-nonce` returns only its definition, and there are no `<Script>`/`next/script` usages. Worse, the sole layout explicitly disclaims the contract — `app/layout.tsx:30`: "we don't need to read x-nonce here ourselves." So the producer-side comment and the consumer-side comment describe opposite intents for the same header. A future developer binding to `x-nonce` gets contradictory guidance about whether it is a live contract, and the header is currently dead weight.

**Recommendation:** Either wire an actual consumer (a server component reading `headers().get("x-nonce")` and passing it to rendered `<Script nonce=...>` tags) and align both comments, or drop the `x-nonce` forwarding until a consumer exists. Don't ship a documented-but-unbound interface.

#### Custom request header `x-nonce` uses lowercase, diverging from the Title-Case-Dash header precedent

**Severity:** Minor
**Location:** `proxy.ts:42`
**Move:** #2 (naming)
**Confidence:** Medium

Precedent: `Content-Type` / `Cache-Control` / `Connection` (Title-Case-Dash) used in `app/lib/llm/streamLlm.ts:12-16`

The only prior header-naming precedent uses Title-Case-Dash keys, and this diff's own response header follows it (`Content-Security-Policy`, `proxy.ts:47`). The new inbound header breaks that with lowercase `x-nonce`. HTTP header names are case-insensitive, so there is no functional impact, but the inconsistency is visible to anyone reading both files and to any future `headers().get(...)` caller who must guess the casing. Note also RFC 6648 deprecates the `X-` prefix for new headers; `nonce` or `next-nonce` would avoid it, though `x-nonce` is the widely-used community convention for exactly this Next.js pattern (a mitigating precedent outside this repo).

**Recommendation:** Use `X-Nonce` to match the `SSE_HEADERS` Title-Case-Dash style, or consciously adopt lowercase and note it as the convention for future custom headers.

#### CSP set only on the response, not on request headers — the nonce-propagation contract is not actually wired (cross-reference)

**Severity:** Informational (API-consistency lane; functional severity belongs to security/correctness)
**Location:** `proxy.ts:44-47`, `app/layout.tsx:28-30`
**Move:** #3 (consumer contract)
**Confidence:** Medium

Flagged here only for contract-completeness; fact-check Claim 2 (Incorrect) is the authority. Next's nonce auto-tagging reads the nonce from the **request** `Content-Security-Policy` header passed into `NextResponse.next({ request: { headers } })`, but this code sets CSP only on the **response** and puts a separate `x-nonce` on the request. The layout's comment (`app/layout.tsx:28-30`) asserts Next "automatically tags its own bootstrap `<script>` elements with the nonce from the response's CSP header" — a contract Next does not honor. Combined with `'strict-dynamic'` (`proxy.ts:22`), untagged bootstrap scripts would be blocked, not trusted. This is a behavior/correctness defect more than a naming/interface-consistency one; I defer the severity call to the security and fact-check outputs and record it only so the header contract is understood end-to-end.

**Recommendation:** If the intended contract is Next's built-in auto-tagging, set `requestHeaders.set("Content-Security-Policy", buildCsp(nonce))` before `NextResponse.next(...)` and fix the layout comment. See fact-check Claim 2.

## What Looks Good

- `proxy`/`config`/`matcher` shape matches the Next 16 convention exactly (fact-check Claim 3).
- Response header `Content-Security-Policy` uses Title-Case-Dash, consistent with `SSE_HEADERS`.
- `NextResponse.next(...)` is the correct primitive for a pass-through proxy — not shoehorned into the routes' `NextResponse.json(...)` pattern.
- `buildCsp` is verb-noun camelCase and correctly kept module-private (not exported), consistent with helper naming elsewhere.
- The `matcher` exclusions (API routes, static assets, prefetches) are precise and well-documented (fact-check Claim 10, verified) — no over-broad interception of the existing `/api/*` surface.
- `app/layout.tsx` change (`await headers()`) preserves the existing `RootLayout` signature/props; making it `async` is backward-compatible for a Server Component and breaks no consumer.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `x-nonce` contract defined but unconsumed + self-contradicting docs | Inconsistent | `proxy.ts:39-42`, `app/layout.tsx:28-30` | High |
| 2 | `x-nonce` lowercase diverges from Title-Case-Dash header precedent | Minor | `proxy.ts:42` | Medium |
| 3 | CSP on response not request — nonce propagation unwired (x-ref fact-check C2) | Informational | `proxy.ts:44-47` | Medium |

## Overall Assessment

The framework-facing surface (`proxy`, `config`, `matcher`, `NextResponse.next`, the `Content-Security-Policy` response header) is consistent with both Next 16 conventions and the codebase's thin existing header precedent — nothing here will break the existing `/api/*` consumers. The one genuine consistency problem is the `x-nonce` request header: it is a newly-introduced consumer contract that no code binds to, and its purpose is documented in mutually contradictory ways across `proxy.ts` and `app/layout.tsx`. That, plus the underlying unwired nonce propagation (fact-check Claim 2), means the propagation interface is described but not delivered. All findings are fixable in place; the author should either complete the nonce-consumer wiring (and reconcile the two comments) or remove the dead `x-nonce` forwarding, and align the custom header's casing with the `SSE_HEADERS` precedent. No breaking changes to existing consumers.
