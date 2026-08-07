# UI Visual Review — e3/csp-arm2 (Arm 2 verification pass)

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-csp-arm2`
**Commit:** ab4dbdb
**Date:** 2026-08-06
**Review mode:** Mechanical (items 1–5, 8; three viewport bands; guidelines-doc check; CSP rendering consequences)

## Environment

- **Files reviewed (diff-scoped):**
  - `app/layout.tsx` — added a `export const dynamic = "force-dynamic"` config export + docblock (no JSX/markup change)
  - `app/layout.test.ts` — new test (non-UI)
  - `app/lib/utils/dataUrl.ts` — new zero-dependency `data:` URL codec (`dataUrlToBlob`), pure logic
  - `app/lib/utils/dataUrl.test.ts` — new test (non-UI)
  - `app/lib/utils/exportGraph.ts` — `fetch(dataUrl).blob()` → `dataUrlToBlob(dataUrl)` (behavior-preserving swap)
  - `proxy.ts` / `proxy.test.ts` — new CSP proxy + tests (headers only, no rendered markup)
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet/laptop), 1920px+ (desktop)
- **Target browsers / platforms:** modern evergreen + mobile Safari
- **Project UI guidelines doc:** none found (`docs/` has ARCHITECTURE.md, USER_GUIDE.md, etc.; no `*GUIDELINES*` file) — fell back to skill defaults.

## Diff character

No JSX, TSX markup, CSS, SCSS, or Tailwind class string was added, removed, or modified in this range. The changes are:

1. A Next.js **config export** (`export const dynamic`) added above `RootLayout` — the component's returned `<html>/<body>/{children}` JSX (app/layout.tsx:41–46) is untouched.
2. A **file move / extraction**: the `data:`-URL → Blob decode logic moved into `app/lib/utils/dataUrl.ts` and is now called from `exportGraph.ts` instead of `fetch()`. The decode result (a `Blob` handed to `triggerDownload`) is byte-identical to the prior `fetch(dataUrl).blob()` path.
3. Server-side **CSP header** wiring (`proxy.ts`): `form-action 'self'` directive added, matcher exclusions anchored, `x-nonce` request header removed, per-request nonce retained. Headers only — nothing rendered.

## Findings

No Critical findings. No new Major or Minor UI findings. No new focusable elements, no markup, no styling.

### CSP rendering-consequence assessment (no finding)

**Move:** CSP rendering consequences (task-directed check)
**Confidence:** High

The nonce + `'strict-dynamic'` policy is preserved and both the request and response `Content-Security-Policy` headers carry the same policy (proxy.ts:65–75), so Next's bootstrap scripts still receive a nonce and the app still hydrates — no blank-page / un-styled render regression. `style-src 'unsafe-inline'` is retained (proxy.ts:34), so React inline `style={}`, reactflow transforms, and KaTeX render unchanged. `img-src 'self' data: blob:` is retained (proxy.ts:35), which is what lets the PNG-export data-URL/blob path render and download. The new `form-action 'self'` directive constrains form submission targets only; the app posts no cross-origin forms, so no visible form/affordance is affected. `force-dynamic` changes render *timing* (per-request vs. static), not rendered output. Nothing in the CSP change narrows a directive the UI depends on.

### dataUrl.ts move — affordance/rendering impact (no finding)

**Move:** Step 2 item 6 affordance (carried-issue re-assessment, task-directed)
**Confidence:** High

The extraction is behavior-preserving. `downloadGraphAsPng` (exportGraph.ts:17–24) and `graphToPngBlob` (exportGraph.ts:27–37) produce the same `Blob` as before; the sole caller of the download path, `GraphPanel.tsx:98–108`, is unchanged. The one nuance: the prior `fetch(dataUrl)` rejected asynchronously on failure, while `dataUrlToBlob` throws synchronously — but both are inside the same `try { … } catch (err) { console.error("[graph export]", err) }` (GraphPanel.tsx:105–106), so the surfaced behavior is identical. `toPng` always returns a well-formed base64 data URL, so `dataUrlToBlob`'s throw-on-malformed path is not reachable from this caller in practice. No new failure mode, no new user-visible affordance.

## Carried (not new) — recurring Major, unchanged and out of target

**Silent PNG-export affordance / console-only error handling** — `GraphPanel.tsx:98–108`. On export failure the handler only calls `console.error` and resets the `exporting` flag; no user-visible error state, and a 0-byte / empty result is accepted silently. This is the recurring Major from prior full-3 UI reviews (dispositioned amber/green there). **ab4dbdb did not target it, and GraphPanel.tsx is not in this diff — it persists unchanged.** Not re-raised as a new finding per the report-deduplication rule; recorded here as CARRIED for continuity. The button itself is well-formed (label toggles `"Export .png"` ↔ `"Exporting..."`, `disabled={exporting}` — GraphPanel.tsx:121–123), so the affordance gap is confined to error/empty-result surfacing, not the control.

## What Looks Good

- **No markup churn under a header/policy change.** The CSP hardening and the codec extraction were done without touching any rendered element — the lowest-risk possible shape for a UI-adjacent change.
- **Export button state coverage is intact and correct** (GraphPanel.tsx:121–123): visible label, in-flight label swap, and `disabled` during export. The label-swap pattern (rather than hiding the control) matches the skill's affordance guidance.
- **CSP keeps the directives the UI renders through** (`style-src 'unsafe-inline'`, `img-src … data: blob:`), so no rendering/affordance regression is introduced by the tightening.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| In-flight control state, no disappearing control | NNGroup (persistent controls), skill item 6 | Export button swaps label + disables rather than vanishing during export (GraphPanel.tsx:121–123) — unchanged, still correct |
| Behavior-preserving refactor keeps affordances stable | skill item 8 (diff-scoped state coverage) | data-URL decode moved without altering the Blob handed to `triggerDownload` |

## Keyboard Navigation

No new focusable elements in this diff.

## Viewport Verification Checklist

- [x] 360px mobile: no markup/CSS changed; existing layout unaffected; no horizontal-overflow risk introduced.
- [x] 1366x768 (common laptop): no markup/CSS changed; action buttons unaffected.
- [x] 1920x1080 (standard desktop): no markup/CSS changed; whitespace/layout unaffected.

(All three pass by construction: the diff introduces no rendered-markup or style changes at any viewport. `force-dynamic` alters render timing, not layout.)

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence | New/Carried |
|---|---------|----------|------------|----------|------------|-------------|
| 1 | Silent PNG-export failure / 0-byte accepted (console-only error) | Major | Affordance | `app/components/panels/GraphPanel.tsx:98–108` | High | CARRIED (unchanged; not in diff; not targeted by ab4dbdb) |

No Critical findings. No NEW findings.

## Overall Assessment

Clean from a UI standpoint. ab4dbdb is a comment/small-code + file-move + CSP-header change with **zero rendered-markup or styling modifications**, so there is no new layout, overflow, sizing, positioning, occlusion, focus, or state-coverage issue to surface. The dataUrl.ts extraction is behavior-preserving — the PNG export produces the same Blob and reaches the same unchanged caller, so no affordance behavior changed. The CSP tightening preserves every directive the UI renders through (`style-src 'unsafe-inline'`, `img-src data: blob:`), so no rendering regression. The one standing Major — silent PNG-export error/0-byte handling in GraphPanel.tsx — persists **unchanged** and outside this diff's scope; it was previously dispositioned and is recorded here as CARRIED, not re-raised. **0 Critical. Nothing new to address in this arm.**

## Goal-Alignment Note

This pass supports the Arm 2 verification / critic stage of the E3-loops experiment under the 0R+0A merge standard. The mechanical UI review confirms **0 Critical** UI issues in `d86d2dc..HEAD` (HEAD = ab4dbdb) and surfaces **no NEW UI issue** attributable to ab4dbdb. The prior recurring Majors (silent PNG-export affordances: 0-byte accepted, console-only errors) were verified to **persist unchanged** — they live in `GraphPanel.tsx`, which ab4dbdb does not touch — and the dataUrl.ts extraction was verified **not** to alter any rendering or affordance behavior. Scope was held to ancestors of the worktree HEAD only; no other worktrees or arm artifacts were consulted. Net: the UI dimension clears the 0-Critical bar and contributes no new blocker to the merge decision.
