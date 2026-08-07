# UI Visual Review — validate-T arm2 (d86d2dc..HEAD)

**Scope:** `git diff d86d2dc..HEAD` in worktree `wt-validate-arm2` (detached HEAD)
**Commit:** 99e1229
**Date:** 2026-08-06
**Review mode:** Mechanical (items 1–5, 8; three viewport bands; guidelines-doc check; CSP rendering consequences)

Advisory stage — this critic cannot produce a Critical/red for tier policy T; run for completeness.

## Environment

- **Files reviewed (diff-scoped):** `app/layout.tsx`, `app/lib/utils/exportGraph.ts`, `app/lib/utils/exportGraph.test.ts`, `proxy.ts`, `proxy.test.ts`
- **Rendered-UI files touched by the diff:** `app/layout.tsx` (root layout — segment config only), `app/lib/utils/exportGraph.ts` (export helper — no rendered element)
- **Context read (not in diff):** `app/components/panels/GraphPanel.tsx` (caller of `downloadGraphAsPng`)
- **Target viewports:** 360px mobile · 1366×768 laptop · 1920×1080 desktop
- **Target browsers / platforms:** modern evergreen browsers + mobile Safari
- **Project-local UI guidelines:** none found (`docs/UI_LAYOUT_GUIDELINES.md` absent; only `docs/decisions/002-multi-artifact-ui-layout.md`, a decision record, not a checklist)

## Findings

No Critical, Major, or Minor layout findings. The diff renders no visual element and touches no CSS, JSX markup, or focusable control. One pre-existing advisory (carried, not introduced by this diff) is recorded below for completeness.

#### Silent PNG-export failure affordance (carried advisory)

**Severity:** Informational
**Location:** `app/components/panels/GraphPanel.tsx:98-110` (caller — NOT in this diff)
**Issue type:** Affordance
**Viewport:** all
**Move:** Step 2 item 6 (affordance — full-audit item, noted only because it is a known carried advisory; not a mechanical-mode finding)
**Confidence:** High

`handleExportGraph` wraps the export in `try/catch` whose `catch` branch only calls `console.error("[graph export]", err)`; the `finally` resets the button label from "Exporting..." back to "Export .png". On any failure the user sees the button settle back to its idle label with no toast, banner, or error text — the failure is silent. This is unchanged by the diff.

**Evidence (verbatim):**
```tsx
    } catch (err) {
      console.error("[graph export]", err);
    } finally {
      setExporting(false);
    }
```

**Relationship to this diff:** The diff replaces `fetch(dataUrl)` with `dataUrlToBlob(dataUrl)` inside `downloadGraphAsPng`. `dataUrlToBlob` throws synchronously on a malformed data URL (`throw new Error("Not a data: URL")`); previously `fetch(dataUrl)` would reject asynchronously. Both are caught by the same `catch`, so the user-visible behavior (silent failure, button returns to idle) is identical before and after. The diff neither introduces nor worsens the affordance — it is carried, and correctly classified Informational/advisory.

**Recommendation:** Out of scope for this change. If addressed later, surface a non-color error affordance in `GraphPanel` (e.g., an inline "Export failed — try again" message with `role="status"`, WCAG 4.1.3) rather than relying on the console.

## What Looks Good

- **`layout.tsx` change is config-only.** `export const dynamic = "force-dynamic"` is a Next.js route-segment option, not markup — it renders nothing and cannot affect layout, sizing, overflow, or focus at any viewport. The accompanying comment correctly explains the nonce-per-request rationale.
- **CSP rendering consequences are sound.** The nonce is delivered via the request CSP header (set in `proxy.ts`) and stamped onto Next.js bootstrap `<script>` tags; `force-dynamic` guarantees a fresh nonce per request rather than one baked into a prerendered document. This is the fix that makes hydration work — interactive controls (the Export button, Formalize queue controls) become operable. No stuck/non-hydrated graph.
- **`dataUrlToBlob` keeps `connect-src 'self'` tight.** Decoding the data URL in-process avoids a `connect-src` fetch of a `data:` URL that the CSP would block. The export (toBlob → triggerDownload) path therefore completes without a CSP violation — the graph PNG download works. The "why" is documented in a comment for reviewers unfamiliar with the CSP interaction.
- **No new markup, no new CSS, no new focusable elements** — nothing to break responsively.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Loading/progress state communicated | WCAG 4.1.3 | Export button toggles "Exporting..." / "Export .png" and `disabled` during the async export (pre-existing, preserved by the diff) |
| Non-text contrast / affordance intact | WCAG 1.4.11 | `DownloadButton` styling untouched; no regression to control discoverability |

## Keyboard Navigation

> No new focusable elements in this diff.

## Viewport Verification Checklist

- [x] 360px mobile: content reachable, no horizontal overflow, touch targets adequate — no markup/CSS changed; nothing added that could overflow
- [x] 1366×768 (common laptop): all action buttons visible without scrolling — export controls unchanged; layout config change has no visual effect
- [x] 1920×1080 (standard desktop): layout fills space without excessive whitespace — no rendered element added or resized

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Silent PNG-export failure (carried, caller only, not in diff) | Informational | Affordance | `app/components/panels/GraphPanel.tsx:98-110` | High |

## Overall Assessment

The visual/layout posture of this change is clean. The diff is non-visual: a Next.js route-segment config flag (`force-dynamic`) and an in-process data-URL→Blob decode helper, plus their tests and the CSP proxy. It adds no markup, no CSS, and no focusable elements, so there is nothing to break across the 360px / 1366×768 / 1920×1080 bands, and no keyboard-navigation surface to review. The CSP-related rendering consequences are net-positive: the nonce-per-request path (via `force-dynamic` + proxy header) is what restores hydration so the UI's interactive controls actually work, and the `dataUrlToBlob` path lets the PNG export complete without tripping `connect-src 'self'`. The only recorded item is the pre-existing silent export-failure affordance in the (out-of-diff) `GraphPanel` caller — Informational, carried, and neither introduced nor worsened here. **There is no Critical finding.** Nothing in this stage requires action for tier policy T.

## Goal-Alignment Note

Task goal is to confirm 0 red at arm 2 pass 2 (99e1229) for decision-031 tier policy T. This UI visual critic is advisory and structurally cannot emit a red/Critical for policy T; run here for completeness. Consistent with the historical rule, only ancestors of 99e1229 were examined (diff base d86d2dc..HEAD in this worktree); no other worktrees or prior review artifacts were consulted (fresh draw). Result: **0 Critical**, 1 Informational (carried advisory). This stage contributes 0 red — consistent with the expected 0-red outcome for arm 2 pass 2.
