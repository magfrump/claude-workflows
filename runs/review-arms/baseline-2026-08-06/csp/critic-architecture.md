Commit: d90d6bb
# Architecture Review — CSP proxy + per-request nonce (branch diff d86d2dc..d90d6bb)

**Scope:** `git diff d86d2dc..d90d6bb` — `proxy.ts` (new), `app/layout.tsx`
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/csp/fact-check.md`

Scope check: the diff introduces a new cross-cutting concern (a Next.js proxy/middleware
layer building CSP response headers) and changes a framework lifecycle hook (root layout
rendering mode). Both fall under trigger category 4 (cross-cutting concerns / middleware /
framework lifecycle). In scope.

Trust-Boundary Cross-Reference: no `docs/reviews/security-review-*.md` exists in this
worktree, so the security-reviewer integration is a no-op. Module-boundary findings below
proceed with default behavior.

## Dependency Map

Two files participate in one cross-cutting pipeline:

- `proxy.ts` (root) — new composition point. Depends only on `next/server`
  (`NextResponse`, `NextRequest`). Runs per matched request (governed by `config.matcher`).
  Produces two outputs per request: (a) a `Content-Security-Policy` header on the *response*,
  and (b) an `x-nonce` header on the *forwarded request*.
- `app/layout.tsx` — root server component. Now depends on `next/headers` (`headers`) and
  is `async`. Calls `await headers()` purely for its side effect of forcing dynamic rendering.

Intended dependency flow: `proxy` (infrastructure/edge) → forwards nonce → `layout` (and any
server component below it) reads nonce → tags `<Script>` elements. Dependency direction is
framework-appropriate (periphery/infra toward the render tree via a header contract); no
domain-toward-infrastructure inversion. The architectural problem is not the *direction* of
the dependencies but that the pipeline's two ends are **not connected** — see Finding 1.

## Findings

#### Cross-cutting nonce pipeline is composed but not wired end-to-end

**Severity:** Structural
**Location:** `proxy.ts:37-47`, `app/layout.tsx:22-31`
**Move:** #4 (layer/cross-cutting composition), #3 (module boundary contract)
**Confidence:** High

The proxy establishes a security cross-cutting concern whose whole purpose is to deliver a
per-request nonce to the render tree, but the two halves of that pipeline never meet. The
proxy sets the CSP (which names the nonce) on the *response* and sets `x-nonce` on the
*forwarded request* — two different channels — while the documented Next.js auto-tagging
contract requires the CSP string itself on the *request* headers before `NextResponse.next`
(corroborated by fact-check Claim 2, verdict Incorrect). Meanwhile no server component reads
`x-nonce` (fact-check Claim 9: producer with zero consumers; the only layout explicitly
disclaims reading it at `app/layout.tsx:30`). The result is a cross-cutting concern that is
structurally inert: the response advertises `script-src ... 'nonce-X' 'strict-dynamic'`
(`proxy.ts:22`) but nothing in the render path ever emits a script carrying nonce X. This is a
composition-root defect, not a line-level bug — the proxy→render-tree contract that the entire
feature is built around is unfulfilled, so every added file exists to serve a pathway that does
not close. Left as is, the architecture invites a future maintainer to "extend" a nonce
mechanism that was never actually load-bearing.

**Recommendation:** Close the contract in one place: set the CSP on the forwarded
*request* headers (`requestHeaders.set("Content-Security-Policy", csp)`) so Next's auto-tagging
has a source, OR make the `x-nonce` contract real by having `layout.tsx` read it and thread it
into rendered `<Script>` tags. Pick one propagation channel and delete the other so the
pipeline has a single, exercised path. (The security critic owns whether the resulting CSP is
*safe*; this finding is that the concern is not *wired*.)

#### Layout's rendering mode is implicitly coupled to the proxy via a comment-only contract

**Severity:** Coupling
**Location:** `app/layout.tsx:27-31`
**Move:** #7 (coupling surface), #2 (responsibility boundary)
**Confidence:** High

`await headers()` is called for a side effect (forcing dynamic rendering) with no use of its
return value. The layout now carries a hidden responsibility — "stay dynamic so the CSP
mechanism works" — that is enforced only by a comment. Nothing links this line to `proxy.ts`
structurally: a future refactor that removes the seemingly-dead `await headers()`, or that
re-enables static optimization, would silently break the nonce feature with no compile-time or
test signal. This is control coupling expressed through a framework side effect rather than an
explicit interface, which is the kind of dependency that erodes quietly. (Per fact-check Claim
1, the stated causation is also loose: the proxy runs per request regardless of the layout's
rendering mode — so the comment misdescribes *why* the line is needed, compounding the
fragility.)

**Recommendation:** Make the coupling explicit and self-documenting — prefer the standard
`export const dynamic = "force-dynamic"` (or `export const runtime`/`revalidate` as
appropriate) route-segment config over a side-effecting `await headers()`, and have the
comment name the real dependency (per-request nonce embedding in HTML, not proxy execution).
If `headers()` is retained, actually consume `x-nonce` so the call has a real, checkable
purpose.

#### `x-nonce` request header is a dead public contract

**Severity:** Minor
**Location:** `proxy.ts:39-42`
**Move:** #3 (module boundary), #8 (extension points)
**Confidence:** High

`x-nonce` is a new header-based interface exported into the request pipeline with no consumer
anywhere in the codebase (fact-check Claim 9). As a standalone observation (distinct from the
Finding 1 pipeline defect), an unconsumed header is a boundary that future code may bind to
without realizing nothing produces meaning from it, or may duplicate. It widens the implicit
request contract for no current benefit.

**Recommendation:** Either consume it in the render tree (resolving Finding 1) or remove it
until a consumer exists; do not ship a producer-only header contract.

## What Looks Good

- **Clean single-responsibility split in `proxy.ts`.** `buildCsp(nonce)` is a pure function
  isolated from the request-handling `proxy()`; the directive list is declarative and easy to
  audit. Good separation of policy construction from request wiring.
- **Correct composition-root placement.** Putting CSP in a single root `proxy.ts` rather than
  scattering header logic across API routes / components is the right architectural home for a
  cross-cutting concern — one place to reason about the whole policy.
- **`matcher` scoping is well-considered** (`proxy.ts:55-62`): excluding API routes, static
  assets, and prefetches keeps the concern applied only where HTML is rendered, which is the
  correct boundary for this concern.
- **Dependency direction is sound** — no infrastructure/framework dependency was pushed into
  domain or business modules; the change is confined to the edge/layout layer.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Nonce pipeline composed but not wired end-to-end | Structural | `proxy.ts:37-47`, `app/layout.tsx:22-31` | High |
| 2 | Layout rendering mode implicitly coupled to proxy via comment-only contract | Coupling | `app/layout.tsx:27-31` | High |
| 3 | `x-nonce` request header is a dead public contract | Minor | `proxy.ts:39-42` | High |

## Overall Assessment

The change places a cross-cutting concern in the right structural home (a single root proxy)
with clean internal separation, and it does not distort dependency direction. But it does not
maintain structural integrity as delivered: the feature's central contract — proxy delivers a
per-request nonce to the render tree — is composed across two files that never connect, leaving
an inert pipeline whose response headers reference a nonce no rendered script carries. The
single most important structural concern is Finding 1: choose one propagation channel (CSP on
the forwarded request for Next auto-tagging, or an actually-consumed `x-nonce`) and wire it
end-to-end, then delete the unused half. All three findings are fixable in place within these
two files — no restructuring is required, only closing the contract that the current
composition leaves open.
