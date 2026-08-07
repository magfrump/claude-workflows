# UI Visual Review — MECHANICAL mode

Commit: 1eb081e
Range: d86d2dc..HEAD (branch e3/csp-arm1)
Worktree: /workspace/runs/review-arms/e3-loops/wt-csp-arm1
Mode: Mechanical (items 1–5 and 8; three viewport bands; guidelines-doc check; CSP rendering consequences)
Scope discipline: Ancestors of worktree HEAD only. No other worktrees or arm artifacts consulted.

## Diff inventory (UI-relevant surface)

`git diff --stat d86d2dc..HEAD` touches 7 files; only two are UI-relevant and only one renders markup:

- `app/layout.tsx` — root layout. **No JSX/CSS markup changed.** The only edits: added `import { headers } from "next/headers"`, changed `export default function` → `export default async function`, added a load-bearing comment block, and added `await headers()`. The returned JSX (`<html lang="en">` / `<body className={...}>` / `{children}`) is byte-for-byte unchanged.
- `app/lib/utils/exportGraph.ts` — non-rendering utility. Internal refactor `toPng` + `fetch(dataUrl)` → `toBlob` via new `renderGraphToBlob` helper. No markup, no JSX, no CSS. Render parameters preserved exactly (`pixelRatio: 2`, `backgroundColor: EXPORT_BG = "#F9F5F1"`).

The remaining five files are tests (`csp.test.ts`, `exportGraph.test.ts`, `proxy.test.ts`) and non-UI source (`csp.ts`, `proxy.ts`). Out of visual scope.

## What Looks Good

- The `app/layout.tsx` change is a pure server-rendering-mode edit (static → dynamic opt-out via `await headers()`) with no effect on the rendered DOM tree, class names, fonts, or layout structure. Visual output is identical.
- The comment block on the dynamic opt-out is unusually explicit about the CSP-nonce/static-rendering mutual exclusion and its cost, which correctly documents *why* the visual/render path is what it is.
- `exportGraph.ts` preserves the exact export raster parameters (`pixelRatio: 2`, ivory-cream background), so the produced PNG is visually identical to the prior path — no regression in export fidelity, resolution, or background fill.

## Item-by-item (mechanical items 1–5, 8)

1. **Overflow / clipping** — No markup or CSS changed. No new containers, no sizing changes. Nothing can newly clip or overflow. No finding.
2. **Cross-resolution sizing** — No layout, flex/grid, width, or breakpoint code touched. No finding.
3. **Affordance / interactive feedback** — No new buttons, links, or controls in the diff. The pre-existing graph-export silent-failure affordance is discussed under Goal-Alignment. No finding *in this diff*.
4. **Text legibility / contrast** — No text, color token, or font change. `<body>` className (fonts, antialiasing) unchanged. No finding.
5. **Focus order / keyboard** — No focusable element added, removed, or reordered. See Keyboard Navigation. No finding.
8. **3D / canvas viewport rendering** — The React Flow graph viewport is captured for export via `html-to-image`. The capture switched from `toPng` (base64 → `fetch(data:)` → blob) to `toBlob` (canvas → `canvas.toBlob()`). This is a rendering-*correctness* improvement under CSP, not a visual change: the old `fetch(dataUrl)` path throws a `TypeError` under `connect-src 'self'` (a `data:` URL is not `'self'`), so the new path actually completes the export where the old one would silently fail at runtime. No new viewport rendering issue; if anything the export path is more likely to succeed. No finding.

## CSP rendering consequences

- `app/layout.tsx` now opts out of static rendering so `proxy.ts` runs per request and Next tags its bootstrap `<script>` tags with the per-request CSP nonce. Consequence for rendering: bootstrap scripts carry a fresh nonce and are **not** CSP-blocked; a statically prerendered shell would have shipped a stale/absent nonce and been blocked after the first request, which would present as a broken (script-less) page. This change removes that failure mode. Net rendering effect: positive, no new visible defect.
- `exportGraph.ts` `toBlob` path keeps the decode in-DOM (`canvas.toBlob()`), and the shared canvas pipeline's same-origin webfont/image `fetch()` is permitted under `connect-src 'self'`. No CSP-induced rendering breakage introduced.

## Keyboard Navigation

No new focusable elements in this diff.

## Guidelines-doc check

No UI/design guidelines document is referenced or altered by this diff, and no markup was changed, so there is nothing to check a rendered change against. WCAG 2.2 / NNGroup checks are non-applicable to this diff because no rendered element changed. (The carried silent-failure affordance below implicates NNGroup "visibility of system status" but is out of this diff's scope.)

## Viewport Verification Checklist

| Band | Width | Result |
|------|-------|--------|
| Mobile | ~375px | Unaffected — no markup/CSS in diff. No new clipping/overflow. |
| Tablet | ~768px | Unaffected — no breakpoint or layout code touched. |
| Desktop | ~1440px | Unaffected — `<body>` structure and classes unchanged. |

Legibility-target: N/A — no text, font, size, or color token changed in this diff; body typography (`ebGaramond`/`geistMono`, `antialiased`) is unchanged, so the existing legibility target is preserved by construction.

## Summary Table

| ID | Severity | Item | Status | File |
|----|----------|------|--------|------|
| — | (none Critical) | — | — | — |
| C1 | Major | Graph PNG export fails silently — `catch` only `console.error`s; `if (viewport)` no-ops with no user feedback | CARRIED (advisory; unchanged by 1eb081e) | app/components/panels/GraphPanel.tsx (NOT in diff range) |

No Critical findings. No new Major/Minor findings introduced by commit 1eb081e or anywhere in d86d2dc..HEAD.

## Overall Assessment

Commit 1eb081e (and the full d86d2dc..HEAD range) introduces **zero Critical** UI issues and **zero new** UI issues of any severity. The only rendering-surface file, `app/layout.tsx`, changed its server-rendering mode but not its markup; the export utility refactor preserves visual output exactly and improves CSP-time export reliability. Merge standard 0R+0A is satisfiable from the UI-visual dimension: no Critical, no new findings to add.

## Goal-Alignment Note

The verification target was to confirm 0 Critical and to assess whether the recurring full-2 Major — the silent PNG-export-failure affordance — changed at all in 1eb081e.

Finding: the user-visible silent-failure affordance is **unchanged**. The affordance lives in `app/components/panels/GraphPanel.tsx` (`handleExportGraph`: `catch (err) { console.error("[graph export]", err); }` plus `if (viewport) await downloadGraphAsPng(viewport)` which no-ops silently when the viewport element is absent). That file is **not in the diff range** (confirmed via `git diff --name-only d86d2dc..HEAD` — no match for GraphPanel/exportAll/DownloadButton). 1eb081e added `exportGraph` *invariant tests* (`app/lib/utils/exportGraph.test.ts`) and refactored the export raster path to `toBlob`, but did not add any user-facing error surface (toast, banner, or status) and did not touch the caller. Therefore the recurring Major remains exactly as advised previously: still present, still advisory, still out of scope for this diff. Its severity classification is unchanged and it is not a merge blocker under the 0R+0A standard for this arm, since it is neither Critical nor newly introduced.
