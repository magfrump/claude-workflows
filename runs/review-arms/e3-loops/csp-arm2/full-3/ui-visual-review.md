# UI Visual Review — e3 arm2, full loop iteration 3 (FINAL pass)

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-csp-arm2` (branch `e3/csp-arm2`)
**Commit:** 2544a19
**Date:** 2026-08-06
**Based on:** iteration-2 UI visual review (`../full-2/ui-visual-review.md`) — findings carried forward and re-verified against HEAD, not copied on faith.

## Environment

- **Files reviewed (diff):** `app/layout.tsx`, `app/lib/utils/exportGraph.ts`, `app/lib/utils/exportGraph.test.ts`, `proxy.ts`, `proxy.test.ts`
- **Files read for rendering consequence (not in diff, read to evaluate what the diff's CSP does to actually-rendered content):** `app/components/panels/GraphPanel.tsx`, `app/lib/utils/export.ts`, `app/lib/utils/exportAll.ts`, `app/components/features/output-editing/LatexRenderer.tsx`, `app/components/ui/icons/*`
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet / small laptop), 1920px+ (large desktop)
- **Target browsers / platforms:** modern evergreen browsers + mobile Safari
- **Review mode:** Mechanical (checklist items 1–5 and 8; item 11 evaluated and found N/A — no spatial/stacked layout touched; item 9 N/A — the React Flow graph is 2D DOM, no 3D pipeline in diff)
- **Project UI guidelines:** none found. `docs/` contains `ARCHITECTURE.md`, `USER_GUIDE.md`, `MAINTAINING_USER_GUIDE.md`, `decisions/`, `plans/`, `proposals/`, `spikes/`, `thoughts/` — no `UI_LAYOUT_GUIDELINES.md` or equivalent. Skill defaults therefore apply in full, with no project-local suppressions available.

## What changed since iteration 2

`2544a19` is comment-only: three prose hunks in `proxy.ts` (the `style-src 'unsafe-inline'` rationale at :12–17, the runtime attribution at :35–36). `git show 2544a19` confirms no executable line moved — the diff is `8 insertions(+), 5 deletions(-)`, all inside `/* */` and `//` blocks. **No finding below could have been created, closed, or changed in severity by this commit.** Every finding is a re-verification against HEAD source, and every one is unchanged.

**Nothing Critical exists in this diff.** No content is inaccessible or invisible at any reviewed viewport, no user is locked out of the primary task, and there is no accessibility violation of Critical class. The two Criticals from the iteration-1 rubric (hydration failure under `'strict-dynamic'`; graph stuck because `fetch(data:)` was refused by `connect-src 'self'`) remain structurally resolved at HEAD: `proxy.ts:47-49` sets the same policy on the forwarded request headers, and `exportGraph.ts:54,65` route both export paths through the in-process decoder.

## Findings

All findings are **carried forward** from iteration 2 and re-verified. None is new; none is closed.

#### PNG export can complete "successfully" with a 0-byte file — the decoder's validity gate checks the prefix, not the payload

**Severity:** Major
**Location:** `app/lib/utils/exportGraph.ts:23-45` (guard at :24-27), consumed at `:54` and `:65`
**Issue type:** Affordance (silent failure)
**Viewport:** all
**Move:** Step 2 item 8 (state matrix — the "error" state of a diff-touched control path is unhandled); CSP rendering consequence for actually-rendered content
**Confidence:** High
**Status:** Open — unchanged by 2544a19. Known-open amber in the rubric.

`dataUrlToBlob` rejects only inputs that fail `startsWith("data:")` or lack a comma. A degenerate `"data:,"` — which `toPng` emits when the source element has zero measurable area — passes both checks: `header` is `""`, `payload` is `""`, `mediaType` falls through the `||` to `"application/octet-stream"`, and the function returns a zero-byte Blob. `triggerDownload` then hands that to the browser, which writes `proof-graph.png` at 0 bytes and reports success. The user's only signal that the export failed is opening the file later. The prior `fetch(dataUrl)` spelling had the same hole, so this is not a regression — but the diff replaced the implicit path with an explicit validation function, which is precisely where the check belongs and where its absence is now a choice rather than an accident.

**Evidence:** `exportGraph.ts:24-27`, verbatim:

```ts
  const commaIndex = dataUrl.indexOf(",");
  if (!dataUrl.startsWith("data:") || commaIndex === -1) {
    throw new Error("Not a data: URL");
  }
```

and `:31-33`, verbatim:

```ts
  const mediaType =
    (isBase64 ? header.slice(0, -";base64".length) : header).split(";")[0] ||
    "application/octet-stream";
```

**Legibility-target:** Not a legibility finding — the failure produces no rendered pixels at any viewport. The affordance target is the negative one: the user must not be shown a success-shaped outcome (button returns to "Export .png", file appears in the download tray) for a produced artifact of zero bytes. WCAG 4.1.3 (Status Messages) is the relevant standard: the outcome of the operation must be programmatically determinable, and here a failure is indistinguishable from a success in both the visual and the accessibility tree.

**Recommendation:** Reject an empty payload in the decoder, so the failure reaches the `catch` rather than the filesystem.

```ts
// before
  if (!dataUrl.startsWith("data:") || commaIndex === -1) {
    throw new Error("Not a data: URL");
  }

// after
  if (!dataUrl.startsWith("data:") || commaIndex === -1) {
    throw new Error("Not a data: URL");
  }
  if (commaIndex === dataUrl.length - 1) {
    // toPng returns "data:," when the target element has zero measurable area;
    // writing that to disk produces a 0-byte PNG the user only discovers later.
    throw new Error("Empty data: URL payload — nothing was rendered");
  }
```

Tradeoff: none material. The one behavior change is that a legitimately empty export now throws instead of downloading — which is the intent. Pair with the finding below, or the throw is still swallowed.

---

#### Every failure mode of the new decoder terminates in `console.error` — the user sees the button blink and nothing else

**Severity:** Major
**Location:** `app/components/panels/GraphPanel.tsx:98-110` (handler), `app/lib/utils/exportAll.ts:60-69`; throw sites introduced by the diff at `app/lib/utils/exportGraph.ts:26` and `:36`
**Issue type:** Affordance (silent failure) / State coverage — error state
**Viewport:** all
**Move:** Step 2 item 8 (error state of a diff-affected control path)
**Confidence:** High
**Status:** Open — unchanged by 2544a19. Known-open amber in the rubric.

The diff adds two new synchronous throw sites inside the export path: the `Not a data: URL` guard, and `decodeURIComponent(payload)` at `:36`, which throws `URIError` on a malformed percent-escape. Both propagate into `handleExportGraph`'s `catch`, whose entire body is a `console.error`. The `finally` clears `exporting`, so the button label returns from "Exporting..." to "Export .png" — the exact same visual transition as a successful export. There is no toast, no inline error region, no `aria-live` announcement, and no state that survives past the handler. A sighted mouse user, a keyboard user, and a screen-reader user all receive the identical (null) signal on failure and on success. The handler is pre-existing code untouched by the diff, but the diff is what routes new failure classes into it, so the gap is in scope for this review.

**Evidence:** `GraphPanel.tsx:98-110`, verbatim:

```tsx
  const handleExportGraph = useCallback(async () => {
    setExporting(true);
    try {
      // Dynamic import to avoid loading html-to-image until needed
      const { getGraphViewportElement, downloadGraphAsPng } = await import("@/app/lib/utils/exportGraph");
      const viewport = getGraphViewportElement();
      if (viewport) await downloadGraphAsPng(viewport);
    } catch (err) {
      console.error("[graph export]", err);
    } finally {
      setExporting(false);
    }
  }, []);
```

**Legibility-target:** An error surface must be perceivable without opening devtools. Concretely: rendered text, not a console string; contrast ≥ 4.5:1 against `--ivory-cream` `#F9F5F1` for body-size text (WCAG 1.4.3) — the existing `emerald-700` / `#9A9590` palette in this header does *not* supply a failure color, so one must be chosen and checked, not inherited; conveyed by more than color (icon or text prefix, WCAG 1.4.1); and announced via `role="status"` or `aria-live="polite"` so it reaches assistive tech (WCAG 4.1.3). Placement adjacent to the "Export .png" control in the `flex items-center gap-2` row at `GraphPanel.tsx:118`, so the message is spatially bound to the control that produced it.

**Recommendation:** Add an error state to the panel and render it beside the button.

```tsx
// before
    } catch (err) {
      console.error("[graph export]", err);
    } finally {

// after
    } catch (err) {
      console.error("[graph export]", err);
      setExportError("Could not export the graph image.");
    } finally {
```

with a sibling of the `DownloadButton` at `:119-125`:

```tsx
{exportError && (
  <span role="status" className="text-xs text-red-700">
    {exportError}
  </span>
)}
```

Tradeoff: the header row at `:114` is already a four-control `justify-between` bar with no wrap (see the Informational finding below); adding an inline message pushes that row closer to its clipping threshold on narrow viewports. If that is a concern, render the message below the header bar rather than inside it.

---

#### "Export .png" is enabled during the window where the graph viewport does not yet exist, and clicking it is a silent no-op

**Severity:** Minor
**Location:** `app/components/panels/GraphPanel.tsx:14-17` (dynamic import with `ssr: false` + loading fallback), `:103-104`, `:119-125`
**Issue type:** Affordance / State coverage — disabled state
**Viewport:** all
**Move:** Step 2 item 8 (disabled state)
**Confidence:** High
**Status:** Open — pre-existing, not introduced by this diff; unchanged by 2544a19.

`hasNodes` gates the button's presence, but the React Flow canvas is a `next/dynamic` import with `ssr: false`, so `.react-flow__viewport` is absent from the DOM until that chunk resolves and mounts. In that window the button is rendered and enabled, `getGraphViewportElement()` returns `null`, and `if (viewport)` at `:104` skips the export entirely — no throw, no log, no state change beyond the `exporting` flag flipping true and back. The button is `disabled={exporting}` only; it has no notion of viewport readiness.

**Evidence:** `GraphPanel.tsx:103-104`, verbatim:

```tsx
      const viewport = getGraphViewportElement();
      if (viewport) await downloadGraphAsPng(viewport);
```

and `:119-125`, verbatim:

```tsx
          {hasNodes && (
            <DownloadButton
              label={exporting ? "Exporting..." : "Export .png"}
              onClick={handleExportGraph}
              disabled={exporting}
            />
          )}
```

**Legibility-target:** If the fix is to disable the button until the viewport mounts, the disabled state must be visibly disabled and not merely faded — the sibling controls use `disabled:opacity-50` (`:137`), which at `emerald-700` on `#F5F1ED` remains legible but must stay distinguishable from enabled at a glance (skill affordance principle 5), and `disabled` must be the real attribute rather than `aria-disabled` alone so the control also drops out of the tab order rather than being focusable-but-dead.

**Recommendation:** Either gate on readiness, or convert the silent skip into the same user-visible error as the finding above. The narrower fix is the `else` branch:

```tsx
// before
      if (viewport) await downloadGraphAsPng(viewport);

// after
      if (!viewport) throw new Error("Graph is still loading — try again in a moment.");
      await downloadGraphAsPng(viewport);
```

Tradeoff: this converts a no-op into an error message, which is only an improvement once the error surface from the previous finding exists. Ordering matters — land the error surface first.

---

#### `img-src 'self' data: blob:` silently breaks remote images in rendered markdown

**Severity:** Minor
**Location:** `proxy.ts:22`; consumed by `app/components/features/output-editing/LatexRenderer.tsx:34-38`
**Issue type:** Responsive / rendering consequence of CSP on actually-rendered content
**Viewport:** all
**Move:** CSP rendering-consequence sweep
**Confidence:** Medium — depends on whether user or model-authored markdown in this app ever carries remote image URLs, which is content-dependent and not statically decidable.
**Status:** Open — introduced by this diff (the directive is new); unchanged by 2544a19.

`LatexRenderer` renders untrusted-ish markdown through `ReactMarkdown` with `remarkGfm`, so standard `![alt](https://…)` image syntax is live. `img-src 'self' data: blob:` omits `https:`, so any remote-hosted image in that markdown is refused by the browser and collapses to the user agent's broken-image glyph with a console violation. This is a genuine consequence of the diff on rendered output, not a hypothetical: the directive is new in this change and no prior policy constrained image loading. It is Minor rather than Major because the failure is at least *visible* (unlike the export failures above) and because remote images may simply never occur in this app's content.

**Evidence:** `proxy.ts:22`, verbatim:

```ts
    "img-src 'self' data: blob:",
```

`data:` and `blob:` are both load-bearing and correct — `blob:` covers `triggerDownload`'s `URL.createObjectURL` object URLs (`export.ts:8-10`), and `data:` covers `html-to-image`'s internal `img.src = <svg data URL>` step, without which `toPng` itself would fail. The omission is `https:` only.

**Legibility-target:** If remote images are in scope for this app's content, the broken-image glyph is not an acceptable terminal state — a refused image should degrade to its `alt` text at body contrast (≥ 4.5:1 on `--ivory-cream` `#F9F5F1`), not to a 16px placeholder icon carrying no information. If remote images are *out* of scope, the correct fix is upstream: strip or linkify image nodes in the markdown pipeline so the user never sees a broken glyph at all.

**Recommendation:** Decide the policy explicitly rather than leaving it implicit in a directive list. Either widen the directive:

```ts
// before
    "img-src 'self' data: blob:",

// after
    "img-src 'self' data: blob: https:",
```

…or keep it tight and add a `components.img` override in `LatexRenderer` that renders a remote image's `alt` as text. Widening to bare `https:` is the weaker option security-wise (any host may be pinged); prefer the renderer-side fix if remote images are not a supported feature.

---

#### `force-dynamic` on the root layout removes the static shell, and there is no `loading.tsx` to cover the gap

**Severity:** Informational
**Location:** `app/layout.tsx:21-26`
**Issue type:** Responsive / perceived-performance
**Viewport:** all; most noticeable on mobile bands where connections are slower
**Move:** Step 2 item 5 (what the user sees before content arrives) — perceived-latency consequence, not a layout defect
**Confidence:** High
**Status:** Open — the directive is introduced by this diff; the absence of `loading.tsx` is pre-existing. Unchanged by 2544a19.

`export const dynamic = "force-dynamic"` is correct and necessary — a prerendered document would bake one nonce and serve it to every visitor, defeating the mechanism, and the comment above it says exactly that. The UI-side consequence is that no route under this layout ships a prerendered HTML shell any more, so first paint waits on the server render. `rg --files app -g 'loading.tsx' -g 'error.tsx' -g 'global-error.tsx'` returns nothing, so there is no route-level suspense fallback to paint in the interim. The user sees blank until the server responds. This is Informational because it changes timing, not layout — no element moves, overflows, or clips.

**Evidence:** `app/layout.tsx:21-26`, verbatim:

```tsx
// Every route under this layout must render per request: a statically
// prerendered HTML document would bake in one nonce and reuse it for every
// visitor, which defeats the nonce. Next.js takes the nonce from the request's
// Content-Security-Policy header (set in proxy.ts) and stamps it onto the
// bootstrap <script> tags it emits, so nothing here reads it directly.
export const dynamic = "force-dynamic";
```

**Legibility-target:** A skeleton or shell, if added, must not itself be a contrast failure — the existing graph fallback uses `text-[#9A9590]` on `--ivory-cream` `#F9F5F1` (`GraphPanel.tsx:16`), which computes to roughly 2.3:1 and fails WCAG 1.4.3's 4.5:1 for normal-size text. Any new loading text should not copy that value; darken toward `--ink-black` or raise the text size into the large-text threshold (3:1).

**Recommendation:** Add an `app/loading.tsx` rendering the two-panel frame as a skeleton, so the blank window is filled with layout rather than nothing. No change to the `force-dynamic` directive itself — it is right as written.

---

#### `worker-src` is unspecified and inherits `default-src 'self'`, which will refuse `blob:` workers

**Severity:** Informational
**Location:** `proxy.ts:19-29`
**Issue type:** Other (latent CSP rendering consequence)
**Viewport:** all
**Move:** CSP rendering-consequence sweep
**Confidence:** High on the mechanism, Low on impact — `rg "new Worker"` across `app/` returns no hits, so nothing in the codebase trips this today.
**Status:** Open, latent — introduced by this diff; unchanged by 2544a19.

The directive list omits `worker-src`, which falls back through `child-src` to `default-src 'self'`. Bundlers routinely instantiate workers from `blob:` URLs, and several plausible future additions here (a Lean type-checking worker, an off-main-thread layout pass for large graphs) would do so. Such a worker would be refused with no UI-visible symptom other than the feature not working. Flagged as a tripwire for the next person to add one, not as a defect in current behavior.

**Evidence:** `proxy.ts:19-29` directive array, verbatim:

```ts
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
    "connect-src 'self'",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
  ];
```

**Legibility-target:** N/A — no rendered surface. Recorded as a forward-looking note.

**Recommendation:** No change now. If a worker is ever added, add `"worker-src 'self' blob:"` to the array in the same commit. `proxy.test.ts:23-34` asserts the exact directive key set, so that test will fail loudly and force the decision — which is the right design and worth keeping.

---

#### GraphPanel header button row cannot wrap; four controls overflow below ~1024px

**Severity:** Informational
**Location:** `app/components/panels/GraphPanel.tsx:113-118`
**Issue type:** Overflow
**Viewport:** below roughly 1024px, worst at 320–480px
**Move:** Step 2 item 1 (silent clipping) + item 2
**Confidence:** Medium — the exact breakpoint depends on rendered label widths, which vary with `sourceCount` in the "Decompose N Sources" label at `:94-96`.
**Justification for reporting a pre-existing issue:** the diff adds a Major finding whose recommended fix places a new inline error message into this same header row. The row's inability to wrap is the constraint that fix must respect, so it is reported here as context rather than as a defect attributable to this change.
**Status:** Open — pre-existing, untouched by this diff and by 2544a19.

The outer container is `overflow-hidden` and the header is a `justify-between` flex row with no `flex-wrap`. With the "Decomposition" heading plus up to four controls ("Export .png", "Decompose N Sources", and the pause/resume/cancel queue trio at `:145-160`), the row's intrinsic width exceeds the container on narrow viewports and the trailing controls are clipped — not scrolled, clipped, with no indication anything is missing. At 1366×768 and 1920×1080 the row fits comfortably.

**Evidence:** `GraphPanel.tsx:113-118`, verbatim:

```tsx
    <div className="flex h-full flex-col overflow-hidden bg-[var(--ivory-cream)]">
      <div className="flex items-center justify-between border-b border-[#DDD9D5] bg-[#F5F1ED] px-6 py-3">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-[var(--ink-black)]">
          Decomposition
        </h2>
        <div className="flex items-center gap-2">
```

**Legibility-target:** All controls in this row must remain fully reachable at 320px without horizontal page scroll, and each must keep a ≥24×24px hit target (WCAG 2.5.8 Level AA). The current `px-4 py-1.5 text-xs` pills are approximately 27px tall, which clears AA but not the 44×44px AAA target (WCAG 2.5.5) — acceptable, but do not shrink them further to buy horizontal room.

**Recommendation:** Let the control cluster wrap rather than clip.

```tsx
// before
      <div className="flex items-center justify-between border-b border-[#DDD9D5] bg-[#F5F1ED] px-6 py-3">
...
        <div className="flex items-center gap-2">

// after
      <div className="flex flex-wrap items-center justify-between gap-y-2 border-b border-[#DDD9D5] bg-[#F5F1ED] px-6 py-3">
...
        <div className="flex flex-wrap items-center gap-2">
```

Tradeoff: on narrow viewports the header grows to two rows, consuming vertical space in a panel that is already `h-full` constrained. That is the correct trade — a taller header beats an unreachable Cancel button.

## What Looks Good

- **The CSP does not break any content this app actually renders.** Verified by sweep rather than assumption: `rg "https?://" app --glob '*.tsx'` returns only two hits, both the SVG `xmlns` namespace literal in `PaperClipIcon.tsx:4` and `SendIcon.tsx:4` — which is an XML namespace identifier, never fetched, and therefore unaffected by any directive. No `next/image` `remotePatterns`, no `<video>`/`<audio>`/`<iframe>`/`<embed>`/`<object>` (so the `media-src`/`frame-src` fallbacks to `default-src 'self'` are inert), no `<form>` (so the unspecified `form-action`, which does *not* inherit from `default-src`, has nothing to govern), and no `dangerouslySetInnerHTML` or inline `<script>` in any component. Fonts are self-hosted: `next/font/google` (`layout.tsx:2,6-14`) inlines at build under `/_next/static/media`, and KaTeX ships its `.woff2` files through the bundled `katex/dist/katex.min.css` import at `layout.tsx:4` — both same-origin, both covered by `font-src 'self'`.
- **The `style-src 'unsafe-inline'` carve-out is the correct call for this UI, and 2544a19's comment now states the true reason.** React `style={}` attributes, React Flow's inline `transform` on `.react-flow__viewport` (the pan/zoom mechanism, and the element `getGraphViewportElement()` targets), and KaTeX's inline sizing on rendered equations all emit runtime inline styles. Removing the carve-out would flatten graph pan/zoom and break equation sizing — a Critical-class visual regression. The previous comment blamed Tailwind v4, which was wrong (`@tailwindcss/postcss` compiles to a linked stylesheet already covered by `'self'`); the corrected text at `proxy.ts:12-17` now matches the rationale independently asserted in `proxy.test.ts:57-63`, so the repo no longer carries two contradictory explanations for one directive. Both the security choice and its documentation are now sound.
- **`img-src ... data: blob:` keeps the export pipeline working end to end.** These two sources are not incidental: `html-to-image`'s `toPng` renders through an `Image` whose `src` is an SVG `data:` URL, and `triggerDownload` (`export.ts:8-10`) hands the browser a `blob:` object URL. Dropping either would break PNG export at a different point than the one iteration 1 fixed.
- **`dataUrlToBlob` decodes base64 byte-exactly rather than via a text round-trip.** The `charCodeAt` loop at `exportGraph.ts:39-42` avoids the classic corruption of running binary through a UTF-8 string, and `exportGraph.test.ts:20-22` pins that with a non-UTF-8 byte sequence (`[0xff, 0xfe, 0xfd]`). A corrupted PNG is a visual defect that no static review would catch — the test is what makes it not happen.
- **`app/layout.tsx:21-26` documents a global rendering-mode switch in the module's public surface.** `export const dynamic = "force-dynamic"` is greppable and self-describing, unlike the discarded `await headers()` call it replaced, and the comment correctly states that nothing in the layout reads the nonce directly.
- **No layout, spacing, sizing, or positioning declaration appears anywhere in the diff.** Checklist items 2 through 5 have no surface to fail on — a genuinely clean result rather than an unexamined one.

## Keyboard Navigation

**No new focusable elements in this diff.**

The diff touches two non-rendering modules (`proxy.ts`, `proxy.test.ts`), one pure utility plus its test (`exportGraph.ts`, `exportGraph.test.ts`), and one module-level export in `app/layout.tsx`. `layout.tsx`'s rendered JSX (`<html>` / `<body>`) is unchanged — the only edit is the added `dynamic` export and its comment. No button, link, input, `tabindex`, keyboard handler, modal, overlay, dropdown, or focus-managing region is added or modified. The remaining four items are therefore skipped per the skill's rule.

## Viewport Verification Checklist

- [x] **360px mobile** — no change from this diff. Nothing in the diff renders. The pre-existing GraphPanel header clipping (Informational finding above) is worst at this band and is unaffected by the change.
- [x] **1366×768 (common laptop)** — no change from this diff. All action buttons remain visible without scrolling; the header row fits at this width.
- [x] **1920×1080 (standard desktop)** — no change from this diff. Layout unaffected.

Reasoned about statically per skill rule 3; no browser was run. The conclusion is uniform across all three bands because the diff contains zero layout declarations — the CSP's effect on rendered content is viewport-independent (a refused resource is refused at every width), and `force-dynamic` affects timing rather than geometry.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence | New in 2544a19? |
|---|---------|----------|------------|----------|------------|-----------------|
| 1 | 0-byte PNG accepted as a valid export; decoder guard checks prefix, not payload | Major | Affordance | `app/lib/utils/exportGraph.ts:23-45` | High | No — carried, unchanged |
| 2 | All new throw sites terminate in `console.error`; no user-visible failure state | Major | Affordance / State coverage | `app/components/panels/GraphPanel.tsx:98-110` | High | No — carried, unchanged |
| 3 | Export button enabled before `.react-flow__viewport` mounts; click is a silent no-op | Minor | Affordance / State coverage | `app/components/panels/GraphPanel.tsx:103-104, 119-125` | High | No — pre-existing |
| 4 | `img-src` omits `https:`; remote markdown images collapse to broken-image glyph | Minor | Rendering consequence | `proxy.ts:22`, `LatexRenderer.tsx:34-38` | Medium | No — carried, unchanged |
| 5 | `force-dynamic` removes static shell; no `loading.tsx` fallback | Informational | Responsive / perceived-perf | `app/layout.tsx:21-26` | High | No — carried, unchanged |
| 6 | `worker-src` unset, inherits `'self'`; would refuse `blob:` workers | Informational | Other (latent) | `proxy.ts:19-29` | High mechanism / Low impact | No — carried, unchanged |
| 7 | GraphPanel header row cannot wrap; controls clip below ~1024px | Informational | Overflow | `app/components/panels/GraphPanel.tsx:113-118` | Medium | No — pre-existing |

**Critical findings: none.**

## Overall Assessment

The visual and layout posture of this change is sound, and this final pass confirms rather than revises that judgment. `2544a19` is comment-only — three prose hunks in `proxy.ts` — so no finding could have moved, and none did; the value of this pass is the independent re-verification against HEAD source plus a widened sweep for rendering consequences the earlier passes might have missed. That sweep found nothing new: no external image or font hosts, no media elements, no forms, no workers, no inline scripts, and no `dangerouslySetInnerHTML` anywhere in the component tree, which means the strict CSP this branch introduces does not break a single thing the app actually renders. The `style-src 'unsafe-inline'` carve-out remains load-bearing for React Flow pan/zoom and KaTeX sizing, and 2544a19's correction to its rationale is a real improvement — the repo previously carried two contradictory explanations for one directive, and now carries one true one. The two Criticals from earlier iterations (hydration failure, stuck graph) remain structurally resolved at HEAD, and **nothing Critical exists in this diff**.

What remains is a coherent single theme rather than a scatter of unrelated defects: the export path can fail in several ways and tells the user about none of them. Findings 1, 2, and 3 are three doors into the same room — a zero-byte file written as if it were a success, a thrown error that reaches only the console, and a click that does nothing because the canvas has not mounted — and all three converge on the same missing thing. Every one is fixable in place; none indicates a structural problem with the CSP work, which is the actual subject of this branch. The single most important thing to address is finding 2: give `handleExportGraph`'s `catch` a user-visible, `aria-live`-announced error surface. That one change is what makes finding 1's payload guard and finding 3's readiness check worth landing at all — without it, a stricter decoder just converts one silent failure into a different silent failure. Land the error surface first, then the guards.

## Goal-Alignment Note

- **Answered:** Whether `d86d2dc..2544a19` introduces visual, layout, or affordance regressions, and what the new strict CSP does to content the app actually renders. It does not introduce layout regressions — the diff contains no layout, sizing, spacing, or positioning declarations at any of the three reviewed viewport bands — and the CSP breaks no rendered content, verified by sweeping for external hosts, media elements, forms, workers, and inline scripts rather than assuming. All seven iteration-2 findings were re-verified against HEAD source and all seven remain open and unchanged, which is the expected result for a comment-only commit. **No Critical findings.**
- **Out of scope:** Full-audit checklist items 6 (broad affordance review) and 7 (responsive / cross-browser), per mechanical mode — noting that the diff-scoped state-coverage checks under item 8 did run and produced findings 1–3. Runtime browser verification was not performed; all conclusions are static reasoning over source, per skill rule 3. Item 9 (3D viewport) is N/A — the React Flow graph is 2D DOM with no 3D rendering pipeline. Item 11 (overlap / z-order) is N/A — the diff touches no spatial or stacked layout. Non-UI concerns raised by the commit message — R2's `accepted-immutable-history` waiver on 9b4e453's false verification claim, and the scoping question about whether amber A3 should have been taken in a blocker-only pass — are correctness and process matters for the fact-check and rubric stages, not visual review, and are not adjudicated here.
- **Escalate:** Nothing blocking from a UI perspective; there is no Critical finding and no visual reason to hold this branch. Two decisions belong to the loop owner rather than to this review. First, findings 1 and 2 are known-open ambers that have now survived three iterations unchanged; if the arm's exit criteria permit shipping with open Majors, they ship as-is, but the pairing should be recorded deliberately — a stricter decoder without a user-visible error surface is not an improvement, so if only one of the two lands, it should be finding 2. Second, finding 4 needs a product answer this review cannot supply: whether remote images in rendered markdown are a supported feature. If yes, `img-src` needs `https:`; if no, `LatexRenderer` should drop image nodes so users never meet a broken-image glyph. Leaving it undecided means the answer is set implicitly by a directive list.
