# UI Visual Review — csp-clean (d86d2dc..4f018ab)

**Scope:** `git diff d86d2dc..4f018ab` — `app/layout.tsx`, `app/lib/utils/exportGraph.ts` (visual export path), and the rendering consequences of the new CSP in `proxy.ts` for content the app actually renders.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3) — nonce delivery via request header, `connect-src` no longer blocking export, `style-src` rationale sites verified, `img-src` grants `data: blob:`. Treated as foundation; not re-verified.
`Commit: 4f018ab`

## Environment

- **Files reviewed:** `app/layout.tsx`, `app/lib/utils/exportGraph.ts`, `proxy.ts` (CSP directives only), plus read-only context: `app/lib/utils/export.ts`, `app/lib/utils/exportAll.ts`, `app/components/panels/GraphPanel.tsx`, `app/lib/utils/fileExtraction.ts`, `app/globals.css`
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet / small laptop), 1366x768 (common laptop), 1920px+ (desktop)
- **Target browsers / platforms:** modern evergreen browsers + mobile Safari (Next 16.2.4 / React 19.2.5)
- **Review mode:** Mechanical (checklist items 1–5 and 8 only)
- **Project-local UI guidelines:** none found. `docs/` contains `ARCHITECTURE.md`, `USER_GUIDE.md`, `MAINTAINING_USER_GUIDE.md`, `decisions/`, `plans/`, `proposals/`, `spikes/`, `thoughts/` — no `UI_LAYOUT_GUIDELINES.md` or equivalent. Defaults from this skill applied.

### Findings

#### PNG export can fail with no user-visible signal — the new `null` blob path is swallowed

**Severity:** Major
**Location:** `app/lib/utils/exportGraph.ts:17-24` (new throw), consumed at `app/components/panels/GraphPanel.tsx:98-110` and `app/lib/utils/exportAll.ts:60-69`
**Issue type:** Affordance
**Viewport:** all
**Move:** Step 2 item 8 (interactive element state matrix — feedback/error state on the diff-touched export action) — reached via the export control the changed function backs
**Confidence:** High (code path), Medium (frequency of the `null` return in practice)

The rewrite adds an explicit failure branch that did not exist before: `toBlob` is typed to return `Blob | null`, and `renderGraphPng` converts that `null` into a thrown `Error`. Both call sites terminate that error without surfacing anything to the user — `GraphPanel` catches it into `console.error` and resets `exporting` to `false`, so the button flips from "Exporting..." back to "Export .png" and no file appears; `exportAll` downgrades it to `console.warn` and ships a zip that is silently missing `proof-graph.png`. The user's only evidence of failure is the absence of a download, which is indistinguishable from a slow browser save dialog. This violates WCAG 4.1.3 (status messages must be programmatically determinable) and the affordance principle that loading and completion states must be communicated. The swallowing handlers pre-date this diff, but the diff is what introduced a new, silent-by-construction way to reach them.

**Recommendation:** Surface the failure where the action was initiated rather than in the console. Add an error state alongside the existing `exporting` state in `GraphPanel` and render it in the header next to the button (`role="status"` or `role="alert"`), and have `exportAll` record a skipped-artifact note into the zip manifest so the omission is discoverable.

```tsx
// GraphPanel.tsx — before
} catch (err) {
  console.error("[graph export]", err);
} finally {
  setExporting(false);
}

// after
} catch (err) {
  console.error("[graph export]", err);
  setExportError("Could not export the graph image. Try again.");
} finally {
  setExporting(false);
}
// …and render {exportError && <span role="alert" className="text-xs text-red-700">{exportError}</span>}
```

#### `await headers()` in the root layout opts every route into dynamic rendering, removing the prerendered first paint

**Severity:** Minor
**Location:** `app/layout.tsx:22-31`
**Issue type:** Responsive
**Viewport:** all; most perceptible at 320–480px on constrained mobile networks
**Move:** Step 2 item 5 (perceived above-the-fold readiness at small viewports) — spacing/fold behavior at first paint
**Confidence:** High (the mechanism), Medium (magnitude of user-visible delay)

`await headers()` is placed in the **root** layout, so the opt-out from static prerendering propagates to every page in the tree, not just the routes that need the nonce. Nothing can be served as a prebuilt HTML shell any more; every navigation and reload waits on a server render before the first byte of markup. On a fast desktop connection at 1920px this is invisible, but at 320–480px on a slow link it converts an instant static shell into a blank viewport for the duration of the round trip — the classic "did the tap register?" failure. This is a deliberate and, given the nonce requirement, largely unavoidable cost; it is flagged so it is a known cost rather than a surprise.

**Recommendation:** Keep it, but make the tradeoff explicit — extend the existing comment to note that this disables static generation app-wide, and if any route later needs to stay static, move the `headers()` read into a narrower layout or a small client boundary rather than the root. No code change proposed.

#### `img-src data:` is load-bearing for PNG export even though the export now returns a Blob; `blob:` is currently unexercised by rendered content

**Severity:** Informational
**Location:** `proxy.ts:31` (`img-src 'self' data: blob:`), consumed by `app/lib/utils/exportGraph.ts:17-24`
**Issue type:** Other (CSP → rendered-content interaction)
**Viewport:** all
**Move:** Step 2 item 1 (does the rendered/exported image reach the user intact, or is it silently clipped/blocked)
**Confidence:** High

The comment on the import reads as if switching to `toBlob` removed the diff's dependence on `data:` URLs. It removed the dependence in **`connect-src`** only. `html-to-image` still serializes the cloned subtree into a `data:image/svg+xml` document and loads it through an `Image` before rasterizing to canvas, so `img-src data:` remains a hard requirement of the export path — tightening it later would break PNG export in exactly the silent way Finding 1 describes. Separately, a scan of `app/` found no `<img>`, `next/image`, `new Image()`, or CSS `url()` in rendered code, and downloads go out through an `<a download href="blob:…">` (a navigation, not governed by fetch directives), so the `blob:` token is not currently exercised by anything the app renders.

**Evidence:** `// Use toBlob (not toPng + fetch) so we don't need \`data:\` in CSP connect-src.` (`app/lib/utils/exportGraph.ts:6`)

**Recommendation:** Amend the comment to name which directive changed and which one is still load-bearing, e.g. `// toBlob avoids the toPng→fetch hop, so connect-src no longer needs data:. img-src data: is still required — html-to-image rasterizes via a data:image/svg+xml Image.` Leave the directive itself as-is.

#### `worker-src` is unset and falls back to a `'strict-dynamic'` `script-src`, which may block the PDF text-extraction worker

**Severity:** Minor
**Location:** `proxy.ts:20-34` (directive list, no `worker-src`), affected consumer `app/lib/utils/fileExtraction.ts:25-30` and `app/lib/utils/pdfPropositionParser.ts:442-447`
**Issue type:** Other (CSP → rendered-content interaction)
**Viewport:** all
**Move:** Step 2 item 1 (content the user expects to appear never arrives)
**Confidence:** Medium

The directive list has no `worker-src` and no `child-src`, so worker requests fall back to `script-src 'self' 'nonce-…' 'strict-dynamic'`. `'strict-dynamic'` causes host-source expressions such as `'self'` to be **ignored** in the directive it appears in, and a worker request carries no nonce, so whether the same-origin `pdf.worker.min.mjs` is permitted depends on engine-specific handling of the strict-dynamic/worker interaction rather than on anything the policy states. If it is blocked, the user-visible symptom is a PDF upload that spins and never populates the input panel — a failure with no rendered explanation, since the block surfaces only in the console. This is adjacent to security review; it is included here because the consequence is a rendering/feedback failure in the upload flow.

**Recommendation:** Set `worker-src` explicitly so it does not inherit the strict-dynamic fallback: add `"worker-src 'self' blob:"` to the directives array (`blob:` covers bundler configurations that materialize the worker from an object URL). Verify at runtime with a PDF upload.

### What Looks Good

- **`style-src 'unsafe-inline'` is correctly retained for the graph.** React Flow positions every node with an inline `transform` on the node element. Dropping `'unsafe-inline'` would not produce a styling nit — it would collapse the entire proof graph into a single overlapping stack at the container origin at every viewport. The carve-out comment in `proxy.ts` names the right reason.
- **`font-src 'self' data:` covers everything the app actually loads.** `next/font/google` self-hosts EB Garamond and Geist Mono into `/_next/static/media`, and `katex/dist/katex.min.css` resolves its `url(fonts/…)` references through the Next CSS pipeline to the same origin. Math and body type render under the policy with no external font hop.
- **The `null` return from `toBlob` is handled rather than propagated as an unhelpful downstream error.** `renderGraphPng` fails fast with a named message; the gap is in surfacing it (Finding 1), not in the utility itself.
- **`graphToPngBlob` correctly dropped `async` while keeping the `Promise<Blob>` return type.** Call sites in `exportAll.ts` are unaffected, and the export path lost a redundant `fetch` round trip through the data URL.
- **The proxy matcher excludes `_next/static`, `_next/image`, and prefetches.** Static assets and speculative navigations do not burn a nonce, and no rendered subresource depends on those responses carrying a CSP header.
- **No layout or spacing regressions.** The diff adds no markup, no Tailwind classes, no fixed dimensions, and no scroll containers; checklist items 2 (controls in scroll containers), 3 (`shrink-0` vs `flex-1 min-h-0`), 4 (absolute-positioning anchor), and 5 (vertical spacing at 1366x768) have nothing to act on.

### Keyboard Navigation

No new focusable elements in this diff.

### Viewport Verification Checklist

- [x] 360px mobile: content reachable, no horizontal overflow, touch targets adequate — no markup, dimensions, or class strings changed; the only viewport-sensitive consequence is the delayed first paint in Finding 2.
- [x] 1366x768 (common laptop): all action buttons visible without scrolling — no padding, gap, or row-height changes in the diff; the export control's header row is untouched.
- [x] 1920x1080 (standard desktop): layout fills space without excessive whitespace — unchanged.

### Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | PNG export failure is swallowed into the console; no user-visible signal | Major | Affordance | `app/lib/utils/exportGraph.ts:17-24`, `app/components/panels/GraphPanel.tsx:98-110` | High |
| 2 | `await headers()` in the root layout disables static prerender app-wide | Minor | Responsive | `app/layout.tsx:22-31` | High |
| 3 | `worker-src` unset, falls back to `'strict-dynamic'` `script-src`; PDF worker may be blocked | Minor | Other | `proxy.ts:20-34` | Medium |
| 4 | `img-src data:` still load-bearing for export; `blob:` unexercised by rendered content | Informational | Other | `proxy.ts:31`, `app/lib/utils/exportGraph.ts:6` | High |

### Overall Assessment

The visual/layout posture of this change is sound: the diff adds no markup, no sizing, and no positioning, so the mechanical layout checks (items 2–5) have nothing to catch, and the one CSP directive that could have caused a dramatic visual regression — `style-src` without `'unsafe-inline'`, which would have collapsed the React Flow graph — was correctly left permissive with a documented rationale. Everything found here is fixable in place; none of it indicates a structural problem. The single most important thing to address is Finding 1: the rewrite introduced a new failure branch on the export path and both call sites route it to the console, so a user whose graph fails to render gets a button that returns to its idle label and nothing else — the failure is invisible at every viewport. Findings 3 and 4 are cheap hardening of the same theme (a blocked resource under this CSP surfaces to the user as silence), and Finding 2 is a real but likely acceptable cost of nonce-based CSP that should be recorded rather than fixed.

## Goal-Alignment Note
- Answered: Whether the diff introduces layout, sizing, positioning, spacing, or interactive-state regressions (it does not), and whether the new CSP directives break rendering of content the app actually paints — KaTeX fonts, `next/font` self-hosted faces, React Flow inline node transforms, and the `html-to-image` export pipeline (they do not, and `img-src data:` is load-bearing for the last of these). Also whether the reworked export path gives the user feedback when it fails (it does not — Finding 1).
- Out of scope: Runtime verification in a browser (no dev server started; nonce injection, worker loading, and the export path are reasoned from code only, per the fact-check foundation that nonce delivery was never runtime-verified). Pre-existing layout of `GraphPanel`'s header row and the `DownloadButton` component, neither of which the diff touches. The vacuous wildcard/`http:` guards in `proxy.test.ts` — test quality, not rendering. Checklist items 6 and 7 (affordance audit, cross-browser/responsive sweep), excluded by mechanical mode.
- Escalate: Finding 3 (`worker-src` falling back to a `'strict-dynamic'` `script-src`) sits on the boundary between UI and security review — it is reported here because its symptom is a silent rendering failure in the PDF upload flow, but the directive decision belongs to the security reviewer. The security reviewer should also confirm whether `'strict-dynamic'` was intended to govern worker loading at all. Additionally, the whole-app dynamic-rendering switch in Finding 2 has a performance dimension (per-request server render on every route) that the performance reviewer is better placed to size.
