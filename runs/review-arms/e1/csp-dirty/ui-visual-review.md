# UI Visual Review — csp-dirty (d86d2dc..d90d6bb)

**Scope:** `git diff d86d2dc..d90d6bb` — `app/layout.tsx` (root layout, made async) and new `proxy.ts` (per-request-nonce CSP). Rendering consequences of the CSP directives on content the app actually renders.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3), treated as foundation and not re-verified.

Commit: d90d6bb

## Environment

- **Files reviewed:** `app/layout.tsx`, `proxy.ts`; rendering-consequence tracing into `app/components/panels/GraphPanel.tsx`, `app/lib/utils/exportGraph.ts`, `app/lib/utils/export.ts`, `app/hooks/useWorkspacePersistence.ts`, `app/globals.css`, `app/page.tsx` (read only to establish what the CSP governs).
- **Project-local UI guidelines:** none found. `docs/` contains `ARCHITECTURE.md`, `USER_GUIDE.md`, `MAINTAINING_USER_GUIDE.md`, `decisions/`, `plans/` — no `UI_LAYOUT_GUIDELINES.md` or equivalent. Skill defaults apply.
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet/small laptop), 1366x768 (common laptop), 1920px+ (desktop).
- **Target browsers / platforms:** modern evergreen browsers + mobile Safari (all enforce CSP identically for the directives used here).
- **Review mode:** Mechanical (checklist items 1–5 and 8).

### Findings

#### Entire UI renders as a dead static shell — no hover, focus, active, or disabled state ever fires

**Severity:** Critical
**Location:** `app/layout.tsx:22-31` (async layout + `await headers()`), `proxy.ts:20` (`script-src 'self' 'nonce-…' 'strict-dynamic'`)
**Issue type:** State coverage
**Viewport:** All (320px through 1920px+)
**Move:** Step 2 item 8 — interactive element state matrix
**Confidence:** High

Per the fact-check foundation, the nonce is attached to the *response* header while Next reads the nonce off the *request* header, so Next's bootstrap `<script>` tags are emitted without a matching nonce and `'strict-dynamic'` blocks them. The server-rendered HTML still paints — `app/page.tsx` is a `"use client"` component that prerenders — so the user sees a complete, correctly laid-out interface at every viewport. But no React hydration means no event listeners: `:hover` and `:focus-visible` CSS still work, while every JS-driven state (active/pressed toggles, `disabled` flipping during a request, `aria-expanded` on the panel rail, error banners, streaming updates) is frozen at its initial server-rendered value. This is the worst failure shape for state coverage because the affordances all *look* live — the WCAG 4.1.3 status-message and NNGroup feedback expectations are satisfied visually while nothing behind them responds.

**Recommendation:** Read the nonce back from the request header in the layout and pass it through, or set the CSP header on the *request* headers Next reads (`requestHeaders.set("Content-Security-Policy", csp)`) in addition to the response. Until the nonce round-trip is fixed, the CSP should not ship — no other finding in this report matters while the page cannot hydrate.

#### Graph panel is stuck on its "Loading graph..." placeholder forever

**Severity:** Critical
**Location:** `app/components/panels/GraphPanel.tsx:14-17` (rendering consequence of `proxy.ts:20`)
**Issue type:** Other (rendering / permanent loading state)
**Viewport:** All
**Move:** Step 2 item 8 — state coverage, downstream visible artifact
**Confidence:** High

`ProofGraph` is loaded via `dynamic(..., { ssr: false, loading: () => <div …>Loading graph...</div> })`. An `ssr: false` dynamic import resolves only on the client, after hydration. With hydration blocked, the loading fallback is the terminal state: users see a grey "Loading graph..." line centered in the panel indefinitely, with no error, no timeout, and no retry affordance. This is the most visible single symptom of the CSP misconfiguration and the one most likely to be misread as a backend hang rather than a CSP problem. The same applies at every viewport — the fallback is `flex flex-1 items-center justify-center`, so it centers cleanly and looks like a legitimate in-progress state at 360px and at 1920px alike.

**Recommendation:** Fixed by resolving the nonce round-trip (finding 1). Independently, consider giving `ssr: false` dynamic imports a timeout-backed error state so a permanently-unresolved chunk surfaces as an error rather than an eternal spinner.

**Evidence:**

```tsx
{ ssr: false, loading: () => <div className="flex flex-1 items-center justify-center text-sm text-[#9A9590]">Loading graph...</div> },
```

#### PNG graph export produces no file and no visible feedback

**Severity:** Major
**Location:** `app/lib/utils/exportGraph.ts:24` and `:37` (blocked by `proxy.ts:26`, `connect-src 'self'`)
**Issue type:** Other (blocked resource / missing error state)
**Viewport:** All
**Move:** Step 2 item 8 — error state for a diff-governed interaction
**Confidence:** High

`downloadGraphAsPng` and `graphToPngBlob` both do `await fetch(dataUrl)` on the `data:` URL returned by `toPng`. `connect-src 'self'` does not permit the `data:` scheme, so the fetch rejects. Neither function has a `catch`, so the rejection propagates as an unhandled promise rejection with no toast, banner, or inline error — the user clicks the export control and observes nothing at all. Per WCAG 4.1.3, the outcome of a user-initiated action must be programmatically determinable; a silently swallowed failure fails that at every viewport.

**Recommendation:** Replace the `fetch(dataUrl)` → `blob()` round-trip with a direct data-URL-to-Blob conversion (no network layer, so no `connect-src` involvement), or add `data:` to `connect-src`. Either way, wrap the export call in a `try/catch` that surfaces a visible error state.

**Evidence:**

```ts
  const res = await fetch(dataUrl);
  const blob = await res.blob();
```

#### Saved workspace layout never restores — panels always paint their default arrangement

**Severity:** Major
**Location:** `app/hooks/useWorkspacePersistence.ts:19` (`useEffect` restore, rendering consequence of `proxy.ts:20`)
**Issue type:** Other (layout state)
**Viewport:** All
**Move:** Step 2 item 8 — downstream state consequence
**Confidence:** Medium

Workspace persistence restores panel arrangement from `localStorage` inside a `useEffect`. Effects never run without hydration, so a returning user's saved split orientation and panel selection are silently discarded and the app renders the default layout on every load. Visually this reads as "the app forgot my layout" rather than as a script error, which makes it a slow-burn support cost distinct from findings 1 and 2. Confidence is Medium only because it depends on whether the persisted layout differs from the default for a given user.

**Recommendation:** Resolved by finding 1. No independent change needed.

#### Root layout opted out of static rendering — every navigation now waits on a server render

**Severity:** Informational
**Location:** `app/layout.tsx:26-30`
**Issue type:** Responsive / perceived performance
**Viewport:** All, most noticeable on 320–480px mobile connections
**Move:** Step 2 item 5 — adjacent (layout cost rather than spacing)
**Confidence:** High

`await headers()` marks the root layout dynamic, which cascades to every route beneath it. The previously static HTML shell — which browsers could paint from cache almost immediately — is now generated per request, so first contentful paint is gated on a server round-trip. There is no layout or overflow consequence; the cost is entirely in time-to-first-paint, and it is a deliberate and necessary tradeoff for per-request nonces rather than a defect.

**Recommendation:** No change. Flagged so the FCP regression is attributed to this commit rather than mistaken for a backend slowdown later.

**Evidence:**

```tsx
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce.
  await headers();
```

#### `style-src 'unsafe-inline'` rationale comment names the wrong consumer, risking a future visual break

**Severity:** Informational
**Location:** `proxy.ts:11-13`
**Issue type:** Other (documentation with rendering consequence)
**Viewport:** All
**Move:** Step 2 item 8 — state coverage depends on inline styles
**Confidence:** High

The comment attributes the `'unsafe-inline'` carve-out to Tailwind v4. Per the fact-check foundation, Tailwind ships a static stylesheet (`@import "tailwindcss"` in `app/globals.css`, served same-origin) and does not need it; the actual load-bearing consumers are React `style={}` attributes, reactflow's inline transforms, and KaTeX's inline math sizing. This matters visually because a future hardening pass that trusts the comment would drop `'unsafe-inline'` after confirming Tailwind is fine, and the visible result would be an un-transformable graph viewport (reactflow positions nodes via inline `transform`), collapsed KaTeX math, and any component using a computed `style={}` losing its sizing.

**Recommendation:** Correct the comment to name React inline styles, reactflow, and KaTeX as the dependents, so the constraint is not accidentally removed.

**Evidence:**

```ts
 * Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening
 * to nonces would require rebuilding how Tailwind ships styles in dev and
 * SSR. Documented as a deliberate carve-out, not an oversight.
```

### What Looks Good

- **`img-src 'self' data: blob:` is correctly scoped.** `html-to-image` renders through an `<img>` whose `src` is a `data:image/svg+xml` URL, and `app/lib/utils/export.ts:8` uses `URL.createObjectURL` (a `blob:` URL) for downloads. Both schemes are permitted, so image rendering and the non-PNG download paths are unaffected.
- **`font-src 'self'` is sufficient and nothing external is referenced.** `next/font/google` self-hosts EB Garamond and Geist Mono at build time under `/_next/static/media`, and `katex/dist/katex.min.css`'s relative `url()` font references are rewritten by Next's CSS pipeline to the same same-origin path. A grep of `app/` for external URLs returned only a documentation link in a code comment — there is no CDN font, image, or stylesheet anywhere in the rendered surface, so `default-src 'self'` does not strand any asset.
- **`style-src 'self' 'unsafe-inline'` keeps all inline-style-dependent rendering intact.** No `style-src-attr` is declared, so `'unsafe-inline'` covers style *attributes* as well as `<style>` elements — reactflow node transforms, KaTeX inline sizing, and React `style={}` all continue to render. (The rationale comment is wrong; the directive itself is right.)
- **No `worker-src` gap.** A grep for `new Worker` across `app/` found none, so the `default-src 'self'` fallback for workers strands nothing.
- **`frame-ancestors 'none'` has no rendering cost.** The app is not embedded anywhere in-repo; this blocks framing without affecting any visible surface.
- **The layout markup itself is unchanged.** No class strings, no flex sizing, no positioning, and no spacing were touched — checklist items 1–5 have no diff-scoped surface to flag.

### Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Outcome of a user action must be perceivable | WCAG 4.1.3 (Status Messages) | Flagged the silent PNG-export failure and the terminal "Loading graph..." placeholder as missing status feedback rather than cosmetic issues |
| Interactive elements must give feedback that the action registered | NNGroup (weak signifiers increase user effort) | Flagged the hydration failure as a state-matrix defect: controls look live but no JS-driven state transitions |
| Do not hide content or affordances | Skill rule 2 | Recommendations restore feedback (error surfacing, timeout-backed error state) rather than suppressing the failing paths |

### Keyboard Navigation

No new focusable elements in this diff.

### Viewport Verification Checklist

- [x] **360px mobile:** No layout change from the diff. Content is reachable and there is no horizontal overflow. The CSP consequences (dead controls, permanent graph placeholder) apply identically; the "Loading graph..." fallback centers correctly and does not overflow.
- [x] **1366x768 (common laptop):** No spacing or sizing changed; action buttons occupy the same positions as at d86d2dc and remain above the fold. They are visible but non-responsive per finding 1.
- [x] **1920x1080 (standard desktop):** No whitespace or fill change. All findings are viewport-independent — the CSP applies uniformly, so no width-specific regression exists.

### Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | UI renders as a dead static shell; no JS-driven state ever fires | Critical | State coverage | `app/layout.tsx:22-31`, `proxy.ts:20` | High |
| 2 | Graph panel permanently stuck on "Loading graph..." | Critical | Rendering | `app/components/panels/GraphPanel.tsx:14-17` | High |
| 3 | PNG export silently produces nothing (no error state) | Major | Blocked resource | `app/lib/utils/exportGraph.ts:24,37` | High |
| 4 | Saved workspace layout never restores | Major | Layout state | `app/hooks/useWorkspacePersistence.ts:19` | Medium |
| 5 | Root layout opted out of static rendering — slower FCP | Informational | Perceived perf | `app/layout.tsx:26-30` | High |
| 6 | `style-src 'unsafe-inline'` comment names wrong consumer | Informational | Documentation | `proxy.ts:11-13` | High |

### Overall Assessment

The diff makes no layout, sizing, spacing, or positioning changes, so checklist items 1–5 are clean by construction — but the CSP it introduces is a rendering-control surface, and it currently produces the most deceptive visual failure mode available: a page that paints perfectly at every viewport and then does nothing. Findings 1, 2, and 4 are one root cause (the nonce is written to the response header while Next reads the request header, so `'strict-dynamic'` blocks Next's own bootstrap) and all three resolve together; finding 3 is an independent `connect-src` interaction with `fetch()` on a `data:` URL. None of this is a structural layout problem — the fixes are localized to `proxy.ts`'s header wiring and one line in `exportGraph.ts`. The single most important thing to address is the nonce round-trip: while it is broken, the application is a screenshot of itself, and every other finding is masked.

## Goal-Alignment Note

- **Answered:** Whether the diff introduces layout/overflow/sizing/positioning/spacing defects (it does not — items 1–5 have no diff-scoped surface), and what the CSP directives do to the rendering and interaction state of content the app actually renders: hydration blocked (all interactive state frozen, `ssr: false` panels stuck on placeholders, effect-driven layout restore lost), `connect-src` blocking the PNG export's `data:` fetch with no error surface, and confirmation that `img-src`/`font-src`/`style-src` correctly cover every asset the app renders (self-hosted next/font, KaTeX fonts, reactflow inline transforms, `blob:` downloads, `data:` SVG export).
- **Out of scope:** Security posture of the CSP itself (directive strength, XSS coverage, the `data:`/`blob:` scheme allowances as attack surface) — that belongs to `security-reviewer`. The correctness of the nonce plumbing as a *mechanism* is taken from the fact-check foundation and not re-derived. Pre-existing UI in non-diff files is untouched except where the CSP directly changes its rendering behavior. Keyboard navigation, affordance review (item 6), and responsive/cross-browser checks (item 7) are not applicable or not run in mechanical mode.
- **Escalate:** Findings 1 and 2 are release-blocking from a pure user-visible standpoint, independent of the security review's conclusions — the app is non-functional while shipped in this state. Finding 6 is a latent trap worth escalating to whoever owns the CSP-hardening roadmap: the comment will mislead a future tightening pass into breaking reactflow and KaTeX rendering.
