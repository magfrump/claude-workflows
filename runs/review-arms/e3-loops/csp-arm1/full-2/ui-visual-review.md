# UI Visual Review — CSP arm 1, full-loop iteration 2

**Scope:** `git diff d86d2dc..HEAD` on branch `e3/csp-arm1` (worktree `wt-csp-arm1`)
**Commit:** f25d968
**Date:** 2026-08-06
**Review mode:** Mechanical (checklist items 1–5 and 8; three viewport bands; guidelines-doc check; CSP rendering consequences)
**Based on:** full-1 `ui-visual-review.md` findings treated as advisory only (both prior Criticals re-verified below).

## Environment

- **Files reviewed (diff):** `app/layout.tsx`, `app/lib/security/csp.ts`, `app/lib/security/csp.test.ts`, `app/lib/utils/exportGraph.ts`, `proxy.ts`, `proxy.test.ts`
- **Files read for consequence analysis (not in diff):** `app/components/panels/GraphPanel.tsx`, `app/components/ui/DownloadButton.tsx`, `app/lib/utils/export.ts`, `app/lib/utils/exportAll.ts`, `app/lib/utils/fileExtraction.ts`, `app/globals.css`
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet / small laptop), 1920px+ (large desktop)
- **Target browsers / platforms:** modern evergreen browsers + mobile Safari (CSP3 `'strict-dynamic'` assumed supported)
- **Project-local UI guidelines doc:** **none found.** `docs/` contains `ARCHITECTURE.md`, `USER_GUIDE.md`, `MAINTAINING_USER_GUIDE.md`, `decisions/`, `plans/`, `proposals/`, `spikes/`, `thoughts/` — no `UI_LAYOUT_GUIDELINES.md` or equivalent. Generic checklist defaults therefore apply, and no project-local suppressions are in force. No inline `ui-review:` suppression comments appear in the diff.

## Prior-iteration Criticals — re-verification by code reading

Both full-1 Criticals hinged on defects that this diff's ancestors fixed. Verified against the code, not the prior report's conclusions:

- **Hydration death (CSP blocks Next's own bootstrap scripts) — RESOLVED.** `proxy.ts:27` sets the policy on the *forwarded request* headers (`requestHeaders.set("Content-Security-Policy", csp)`), which is where Next's app-render parses the script nonce from; the same string is also set on the response at `proxy.ts:39`. `app/layout.tsx:42` (`await headers()`) opts the root layout out of static rendering so the proxy runs per request and the emitted `<script>` nonce always matches the response policy. `proxy.test.ts:24-45` is a regression guard on exactly that line. Rendering consequence: the document hydrates, so all client-rendered UI (panels, React Flow graph, KaTeX) paints as before this branch.
- **Blocked PNG export (`fetch()` of a `data:` URL vs. `connect-src 'self'`) — RESOLVED.** `exportGraph.ts` now goes `toBlob` → `canvas.toBlob()`, entirely in-DOM, with no `fetch`. `csp.test.ts:66-72` guards against widening `connect-src` as the wrong fix. I checked the remaining html-to-image network surface for the rendered graph: `rg` finds no `<img>`, no `background-image`, and no `url(...)` in `app/components/**/*.tsx` or `app/globals.css`, so html-to-image has no external resource to inline — the only URL it materialises is the `data:` SVG it loads into an `Image`, which `img-src 'self' data: blob:` permits.

## Findings

#### Graph PNG export failure is invisible to the user — the new `throw` is swallowed and the button just returns to idle

**Severity:** Major
**Location:** `app/lib/utils/exportGraph.ts:16-27` (new failure path) with consumer `app/components/panels/GraphPanel.tsx:98-110`
**Issue type:** Affordance (status/feedback)
**Viewport:** all
**Move:** Task-directed check of the new failure affordance introduced by the `toBlob` rewrite (adjacent to Step 2 item 6's "loading and progress states are communicated"; reported because the diff creates the error, not because it renders new markup)
**Confidence:** High

The rewrite introduces an explicit null-blob branch that throws a human-readable message, but nothing in the UI ever shows it. `handleExportGraph` wraps the call in `try/catch`, logs to `console.error`, and unwinds `setExporting(false)` in `finally` — so on failure the button flips "Exporting..." → "Export .png" and no file arrives. The user's only signal that the export failed is the *absence* of a download, which is indistinguishable from a slow browser download or a mis-clicked button. `toBlob` returns null for real, reachable reasons (canvas allocation failure on a very large graph at `pixelRatio: 2`, out-of-memory on mobile Safari), so this is not a theoretical branch. It violates the "visibility of system status" principle and WCAG 4.1.3 (status messages must be programmatically determinable — here the status is not even visually determinable). This is a *new* affordance question rather than a regression: before the fix the export was blocked outright, so the same silence covered a 100%-failure path; now it covers a rare-failure path, which is exactly when a silent failure is most confusing.

**Evidence** (verbatim, `app/lib/utils/exportGraph.ts:21-26`):

```ts
  if (!blob) {
    throw new Error("Failed to render graph to an image");
  }
  return blob;
}
```

**Evidence** (verbatim, `app/components/panels/GraphPanel.tsx:104-109`):

```tsx
      if (viewport) await downloadGraphAsPng(viewport);
    } catch (err) {
      console.error("[graph export]", err);
    } finally {
      setExporting(false);
    }
```

**Legibility-target:** any error surface added must render at ≥12px (the panel header's `text-xs` = 12px baseline) with ≥4.5:1 contrast against `--ivory-cream` `#F9F5F1`; the existing header muted grey `#6B6560` on that background clears 4.5:1, plain red-500 on ivory does not — use a darker red (e.g. `#B42318`) if colour is used, and never colour alone (WCAG 1.4.1).

**Recommendation:** Surface the caught error in the panel header next to the button, and keep the message the thrown `Error` already provides. Minimal change, no layout restructuring:

```tsx
// before
    } catch (err) {
      console.error("[graph export]", err);
    } finally {

// after
    } catch (err) {
      console.error("[graph export]", err);
      setExportError(err instanceof Error ? err.message : "Export failed");
    } finally {
```

…rendered as a `shrink-0` sibling of the button inside the existing `flex items-center gap-2` row, with `role="status"` so assistive tech is notified:

```tsx
{exportError && (
  <span role="status" className="shrink-0 text-xs text-[#B42318]">
    {exportError}
  </span>
)}
```

**Tradeoff:** the header row at 320–480px is already dense (title + up to three controls); an inline message will wrap or push controls. If the header is tight, render the message *below* the header bar as a full-width strip instead of inline — see the Minor finding on header crowding.

---

#### `getGraphViewportElement()` returning null is an even quieter no-op than the throw path

**Severity:** Minor
**Location:** `app/components/panels/GraphPanel.tsx:103-104` (consumer of `app/lib/utils/exportGraph.ts:10-11`)
**Issue type:** Affordance (status/feedback)
**Viewport:** all
**Move:** Same failure-affordance sweep as the finding above
**Confidence:** High

`if (viewport) await downloadGraphAsPng(viewport)` means a missing React Flow viewport produces *no* error, no log, and no download — strictly less feedback than the thrown path. Pre-existing rather than introduced by this diff, but it is the sibling branch of the failure affordance under review, and whatever error surface the finding above adds should cover it too so the two failure modes do not diverge.

**Evidence** (verbatim, `app/components/panels/GraphPanel.tsx:103-104`):

```tsx
      const viewport = getGraphViewportElement();
      if (viewport) await downloadGraphAsPng(viewport);
```

**Legibility-target:** same as above — ≥12px, ≥4.5:1 against `#F9F5F1`, not colour-alone.

**Recommendation:** Convert the guard into an else-branch that sets the same error state (`"Graph is not ready to export"`), so both failure modes reach one surface.

---

#### Zip export silently omits `proof-graph.png` on the same new failure path

**Severity:** Minor
**Location:** `app/lib/utils/exportAll.ts:60-69`
**Issue type:** Affordance (status/feedback)
**Viewport:** all
**Move:** Downstream consumer trace of the new `throw` in `exportGraph.ts`
**Confidence:** High

The second consumer of the rewritten module catches the new `Error` as "best-effort" and `console.warn`s it. The user receives a zip that is missing the graph image with nothing in the UI or in the archive to say so. The comment marks this as deliberate, so the severity is Minor, but the failure is now reachable through a code path the diff created rather than only through pre-existing CSP breakage.

**Evidence** (verbatim, `app/lib/utils/exportAll.ts:67-69`):

```ts
  } catch (err) {
    console.warn("[export] Could not capture graph image:", err);
  }
```

**Legibility-target:** N/A — recommended remedy is an in-archive text file, not rendered UI.

**Recommendation:** In the catch, write the reason into the archive so the omission is self-documenting without new UI: `zip.file("proof-graph.png.MISSING.txt", String(err));`.

---

#### Panel header row has no wrap or min-width floor; the new "Exporting..." label swap shares a crowded row at 320–480px

**Severity:** Minor
**Location:** `app/components/panels/GraphPanel.tsx:114-125`
**Issue type:** Sizing / responsive
**Viewport:** 320–480px
**Move:** Step 2 item 3 (`shrink-0` vs `flex-1 min-h-0`) applied to the header the diff's failure surface would land in
**Confidence:** Medium

The header is `flex items-center justify-between … px-6 py-3` with a `flex items-center gap-2` control cluster that can hold "Export .png", "Formalize All", and queue controls simultaneously. There is no `flex-wrap`, and neither the `<h2>` nor the control cluster carries `shrink-0` or `min-w-0`, so at 320–480px flex shrinking squeezes both — the `px-6` (48px total) horizontal padding makes it worse. The existing `Export .png` → `Exporting...` swap is width-neutral enough not to cause visible reflow on its own, so this is not a regression; it is the constraint that governs where the Major finding's error surface can go. Not touched by this diff.

**Evidence** (verbatim, `app/components/panels/GraphPanel.tsx:114`):

```tsx
      <div className="flex items-center justify-between border-b border-[#DDD9D5] bg-[#F5F1ED] px-6 py-3">
```

**Legibility-target:** header controls are `text-xs` (12px) with `px-2.5 py-1` → roughly 20–22px tall, **below** the WCAG 2.5.8 Level AA 24×24 CSS-px target minimum. Pre-existing and out of this diff's scope, but it means the header cannot absorb more controls at mobile widths without a target-size regression.

**Recommendation:** If the error surface from the Major finding is added, place it in a `shrink-0` strip below the header bar rather than inline in this row, and add `min-w-0` to the `<h2>` so the title truncates instead of crushing the controls.

---

#### CSP rendering consequences for actually-rendered content: no directive blocks anything the app paints

**Severity:** Informational
**Location:** `app/lib/security/csp.ts:44-55`
**Issue type:** Other (CSP → rendering)
**Viewport:** all
**Move:** Task-directed CSP rendering-consequence check
**Confidence:** High (Medium on the pdfjs worker, which I verified by import path rather than by running it)

Directive-by-directive against what actually renders: `style-src 'self' 'unsafe-inline'` admits React `style={{…}}` attributes, React Flow's per-node `transform` styles (without which every node would stack at the origin), KaTeX's inline-styled math output, and `next/font`'s injected declarations — the carve-out is load-bearing for layout, not merely convenient. `font-src 'self' data:` covers `next/font`'s self-hosted files and KaTeX's bundled faces, both served from `/_next/static` (`'self'`); no external font host is referenced. `img-src 'self' data: blob:` covers html-to-image's `data:` SVG round-trip, and the app renders no `<img>` or CSS `url()` at all. `default-src 'self'` is the fallback for `worker-src`, and the pdfjs worker resolves through `new URL("pdfjs-dist/build/pdf.worker.min.mjs", import.meta.url)` (`app/lib/utils/fileExtraction.ts:26-29`, mirrored at `app/lib/utils/pdfPropositionParser.ts:443`), which the bundler emits same-origin — so PDF text extraction, and therefore everything downstream of it in the UI, is not blocked. Downloads via `triggerDownload`'s `<a href="blob:" download>` are anchor navigation, governed by no directive in this policy.

**Evidence** (verbatim, `app/lib/security/csp.ts:46-49`):

```ts
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${devEvalDirective}`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
```

**Legibility-target:** N/A — no rendered text is affected; the check confirms the absence of blocked styles that would have destroyed legibility (an unstyled React Flow canvas, unstyled KaTeX).

**Recommendation:** No change. If a future diff adds an `<img>` from a third-party host or a remote font, `img-src` / `font-src` must be widened deliberately — do not widen `connect-src`, which `csp.test.ts:66-72` guards.

---

#### Root layout is now always dynamically rendered; no visual or loading-state consequence found

**Severity:** Informational
**Location:** `app/layout.tsx:22-42`
**Issue type:** Other (render mode → perceived loading)
**Viewport:** all
**Move:** Consequence check on the one diff hunk that touches a rendering component
**Confidence:** High

`export default async function RootLayout` + `await headers()` forces per-request rendering. The visual question is whether this introduces a blank or fallback frame the user would see: it does not. The layout body renders only `<html>`/`<body>` with font-variable classes and `{children}`; there is no `loading.tsx`, no `<Suspense>` boundary, and no streaming fallback in the layout, and the route below it is a client component that already paints its own initial state. The `await` resolves from already-available request headers rather than I/O, so no perceptible delay is added before first paint. No layout shift: the `<body>` class string is byte-identical to the pre-diff version.

**Evidence** (verbatim, `app/layout.tsx:42-48`):

```tsx
  await headers();

  return (
    <html lang="en">
      <body
        className={`${ebGaramond.variable} ${geistMono.variable} font-serif antialiased`}
```

**Legibility-target:** unchanged — `next/font` variables and `font-serif antialiased` are preserved exactly, so body copy renders at the same family, size, and weight as before the diff.

**Recommendation:** No change.

## What Looks Good

- **The `toBlob` fix is the right shape, and its comment prevents regression by explanation, not just prohibition.** `exportGraph.ts:16-23` names the mechanism (`fetch()` of a `data:` URL is governed by `connect-src`) rather than just saying "don't do this", and `csp.test.ts:66-72` encodes the same reasoning as a test. A future contributor hitting a CSP violation on export is steered away from the tempting wrong fix.
- **Extracting `buildCsp` into a pure function keeps the directive set reviewable.** The whole policy is nine lines in one place, which is why the rendering-consequence check above could be exhaustive rather than sampled.
- **The dynamic-rendering opt-out is documented as load-bearing.** `app/layout.tsx:26-41` explains *why* static rendering and per-request nonces are mutually exclusive and states the cost is nil for this single client route. That is exactly the comment that stops someone from "optimising" the `await headers()` away and silently breaking hydration on every request after the first.
- **`style-src 'unsafe-inline'` is justified with its actual dependents named.** `csp.ts:13-18` enumerates React inline styles, React Flow transforms, KaTeX, and `next/font` — so the carve-out reads as a deliberate layout constraint rather than laziness, and anyone proposing to remove it knows the full cost up front.
- **No layout geometry changed at all.** The diff adds no markup, no classes, no dimensions; the only rendering-component hunk is a comment plus an `await`. That is why all three viewport bands come back clean.

## Keyboard Navigation

No new focusable elements in this diff.

## Interactive Element State Matrix (item 8)

Strictly diff-scoped: the diff adds or modifies **no** interactive elements. `app/layout.tsx` is the only rendering component touched, and its change is a comment plus `await headers()` — no `<button>`, `<a>`, `<input>`, handler, or `role` is added or modified. `DownloadButton` and `GraphPanel`'s controls were read for consequence analysis only and are unchanged by this diff, so the matrix is **N/A**. (For context, `DownloadButton.tsx:17` does carry default / hover / focus-ring / disabled styling; the state gap noted above is `:active`, and it is out of scope here.)

## Viewport Verification Checklist

- [x] **320–480px mobile:** content reachable, no horizontal overflow, no new touch targets. Diff adds no markup or classes, so nothing here changes. Pre-existing constraint recorded above: the `GraphPanel` header controls are ~20–22px tall (below the WCAG 2.5.8 AA 24px minimum) and the header row does not wrap — relevant only as a constraint on where the recommended error surface can be placed.
- [x] **768–1024px tablet / small laptop:** unchanged. At 1366×768 the graph panel header and its action buttons remain above the fold exactly as before; no vertical spacing was added by the diff.
- [x] **1920px+ desktop:** unchanged. No fixed dimensions, max-widths, or grid definitions introduced; layout fills space identically to the pre-diff build.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Graph PNG export failure invisible — new `throw` swallowed by `console.error` | Major | Affordance | `app/lib/utils/exportGraph.ts:21-23` → `GraphPanel.tsx:105-106` | High |
| 2 | Null-viewport export path is a silent no-op | Minor | Affordance | `GraphPanel.tsx:103-104` | High |
| 3 | Zip export silently omits `proof-graph.png` on the new throw path | Minor | Affordance | `app/lib/utils/exportAll.ts:67-69` | High |
| 4 | Panel header lacks wrap/`min-w-0`; constrains where an error surface can go at 320–480px | Minor | Sizing / responsive | `GraphPanel.tsx:114-125` | Medium |
| 5 | CSP directives block nothing the app actually renders (verified per directive) | Informational | Other | `app/lib/security/csp.ts:44-55` | High |
| 6 | Root layout now always dynamic; no visual or loading-state consequence | Informational | Other | `app/layout.tsx:22-42` | High |

**Nothing Critical exists in this diff.** Both full-1 Criticals (hydration death; blocked PNG export) are resolved — verified by reading `proxy.ts:27,39`, `app/layout.tsx:42`, and `exportGraph.ts:16-27`, not by taking the prior report's word. No finding in this iteration makes content inaccessible or invisible at any reviewed viewport, and none blocks the primary task.

## Overall Assessment

The visual and layout posture of this change is clean: the diff adds no markup, no classes, and no dimensions, so all three viewport bands come back unchanged, and a directive-by-directive walk of the new CSP confirms nothing the app actually paints is blocked — the `'unsafe-inline'` style carve-out is genuinely load-bearing for React Flow's transforms and KaTeX, and the pdfjs worker resolves same-origin under the `default-src` fallback. Both prior Criticals are genuinely fixed rather than papered over, and the fixes carry comments and tests that explain the mechanism, which is why the tempting wrong fix (widening `connect-src` to allow `data:`) is now guarded. The one thing worth addressing is Finding 1: the `toBlob` rewrite introduces an explicit, human-readable failure message that no user will ever see, because the only consumer logs it to the console and resets the button to its idle label — so a failed export is indistinguishable from a slow download. It is fixable in place with a `role="status"` span in the existing header row (or a strip below it, given the header's mobile crowding) and does not indicate a structural problem.

## Goal-Alignment Note

- **Answered:** Do the nonce-delivery and `connect-src` fixes actually restore rendering? Yes — hydration is restored via the request-header CSP plus the dynamic-rendering opt-out, and PNG export is restored via the in-DOM `toBlob` path, both verified by reading the code rather than inheriting full-1's conclusions. What does the user see when the new `toBlob` null branch fires? Nothing at all — the Major finding, with a concrete in-place fix and its mobile-layout tradeoff. Do any CSP directives block rendered content? No — checked per directive against the app's actual styles, fonts, images, workers, and downloads. Three viewport bands: all clean, no geometry changed. Guidelines-doc check: no project-local UI guidelines exist, so generic defaults applied and no suppressions are in force.
- **Out of scope:** Security adequacy of the policy itself (`'strict-dynamic'` semantics, `'unsafe-eval'` gating, nonce entropy) — that is the security critic's call, and I assessed these directives only for what they do to rendered output. Test quality in `csp.test.ts` / `proxy.test.ts` beyond citing them as regression guards. `DownloadButton`'s missing `:active` state and the header's sub-24px touch targets are pre-existing and untouched by this diff; recorded as constraints on the recommended fix, not raised as findings against this branch. No runtime/browser verification was performed — this is a static read, so the pdfjs-worker conclusion (Medium confidence) rests on the import path rather than an observed load.
- **Escalate:** Nothing blocking. One judgement call for the author: Finding 1's fix touches `GraphPanel`, a file outside this diff. If the arm's convention is to keep the diff scoped to the CSP change, defer it to a follow-up rather than widening this branch — the failure it covers is rare, and the export path itself is now correct.
