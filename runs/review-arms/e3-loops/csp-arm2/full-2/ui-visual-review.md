# UI Visual Review — MECHANICAL mode

**Commit:** 99e1229
**Range:** `d86d2dc..HEAD` (worktree `/workspace/runs/review-arms/e3-loops/wt-csp-arm2`, branch `e3/csp-arm2`)
**Files in range:** `app/layout.tsx`, `app/lib/utils/exportGraph.ts` (+ test), `proxy.ts` (+ test)
**Project UI guidelines doc:** none found. `docs/decisions/002-multi-artifact-ui-layout.md` is a layout decision record, not a style guide; no design-token or component-guideline doc exists in this repo. Findings below are graded against WCAG 2.2 and NNGroup feedback/visibility guidance rather than a house standard.

**Scope note (load-bearing for how to read this report):** the diff contains **zero JSX, CSS, Tailwind class, or component-markup changes**. Mechanical items 1–5 and 8 are therefore evaluated against (a) the rendered surfaces whose *behavior* this diff changes — the two export affordances downstream of `exportGraph.ts` — and (b) the CSP's consequences for content the app actually renders. Pure layout geometry is unchanged by this commit; where I note a layout issue I say explicitly whether this diff introduced it.

---

## Findings

#### PNG export can complete "successfully" with a 0-byte file, and the new decoder is what makes that path silent

**Severity:** Major
**Location:** `app/lib/utils/exportGraph.ts:23-45` (`dataUrlToBlob`), consumed at `:54` (`downloadGraphAsPng`) and `:65` (`graphToPngBlob`)
**Issue type:** Silent failure / missing feedback affordance (NNGroup Heuristic 1, visibility of system status)
**Viewport:** All (not viewport-dependent; more likely on large viewports where the graph is bigger)
**Move:** Trace the failure branch of the new code to the pixel the user sees
**Confidence:** Medium — the decode logic is read directly from the diff and is certain; the specific `data:,` producer (oversized canvas) is browser behavior I could not exercise in this environment.

**Evidence:**

```ts
export function dataUrlToBlob(dataUrl: string): Blob {
  const commaIndex = dataUrl.indexOf(",");
  if (!dataUrl.startsWith("data:") || commaIndex === -1) {
    throw new Error("Not a data: URL");
  }
  const header = dataUrl.slice("data:".length, commaIndex);
  const payload = dataUrl.slice(commaIndex + 1);
```

**Legibility-target:** the user must be able to tell a completed export from a failed one without opening DevTools.

`html-to-image`'s `toPng` ultimately calls `canvas.toDataURL()`. When the canvas exceeds the browser's maximum area — reachable here because `toPng` is called with `pixelRatio: 2` on `.react-flow__viewport`, whose size is a function of node count and zoom and is unbounded — Chrome returns the literal string `"data:,"` rather than throwing. Walk that through the new decoder: `startsWith("data:")` is true, `commaIndex` is 5, so the guard does not fire; `header` is `""`, `payload` is `""`, `isBase64` is false, and `mediaType` falls through the `|| "application/octet-stream"` default. The function returns a valid, empty `Blob`. `triggerDownload` then hands the browser a 0-byte object URL with `download="proof-graph.png"`, and the user gets a file in their downloads folder named like a PNG that no image viewer will open. The `exporting` state flips back to `false`, the button re-reads "Export .png", and nothing anywhere says the export failed.

This behavior is not *newly* introduced — `fetch("data:,")` also resolved to an empty blob — but this commit is the fix-up for the prior iteration's silent-PNG-export Critical, and the guard it added (`startsWith("data:") && commaIndex !== -1`) is precisely the kind of validation that would have caught this and didn't. A decoder that treats an empty payload as a legitimate zero-byte image is the remaining half of the same bug class.

**Recommendation:** reject empty payloads in the decoder (`if (!payload) throw new Error("Empty data: URL payload")`), and give `downloadGraphAsPng` a caller-visible failure signal — see the next finding for where that signal has to surface.

---

#### Every failure mode of the new decoder terminates in `console.error` — the user sees the button blink and nothing else

**Severity:** Major
**Location:** `app/components/panels/GraphPanel.tsx:98-109` (`handleExportGraph`); throw sites at `app/lib/utils/exportGraph.ts:26` and `:38`
**Issue type:** Missing error affordance on a primary action
**Viewport:** All
**Move:** State-matrix walk of the interactive element downstream of the diff (mechanical item 8)
**Confidence:** High — read directly from both files; the fact-check foundation independently confirms consumers catch with `console.error`/`warn` only.

**Evidence:**

```tsx
    } catch (err) {
      console.error("[graph export]", err);
    } finally {
      setExporting(false);
    }
```

**Legibility-target:** a failed primary action must produce a visible, non-console message; a user with DevTools closed (i.e. every user) must not be left guessing.

The diff adds two new synchronous throw sites inside a click handler: the explicit `throw new Error("Not a data: URL")` at `:26`, and `atob(payload)` at `:38`, which raises `InvalidCharacterError` on a malformed base64 payload. Both propagate out of `downloadGraphAsPng`, reject the promise, and land in the `catch` above. The entire user-visible consequence is: the "Export .png" label reads "Exporting…" for a few hundred milliseconds, the button is `disabled:opacity-40` for that window, and then it returns to its resting state. No file arrives. No toast, no inline message, no `aria-live` announcement, no error state on the button. A screen-reader user gets even less — the label swap is not in a live region, so nothing at all is announced.

The same shape holds on the zip path: `exportAllAsZip` wraps the graph capture in `try { … } catch { console.warn(…) }` (`app/lib/utils/exportAll.ts:60-69`) and then proceeds to `triggerDownload` the zip anyway. The user receives `metaformalism-export.zip`, opens it, and finds no `proof-graph.png` — a partial export presented as a complete one. The `// Graph screenshot (best-effort)` comment documents the intent, but "best-effort" is a contract with the programmer, not with the person who clicked Export All.

I am not asking this diff to build a toast system. The minimum is that the failure be *visible*: an error label on the button plus an `aria-live="polite"` region, and, for the zip, a `README.txt` or manifest entry noting the omitted image.

**Recommendation:** add `const [exportError, setExportError] = useState<string | null>(null)`, set it in the `catch`, and render it adjacent to the button inside an `aria-live="polite"` container; clear it on the next successful export. For `exportAll`, record the skipped artifact in the zip so the omission is discoverable offline.

---

#### "Export .png" is enabled during the window where the graph viewport does not yet exist, and clicking it is a silent no-op

**Severity:** Minor
**Location:** `app/components/panels/GraphPanel.tsx:14-17` (`dynamic(..., { ssr: false })`), `:119-125` (button gated on `hasNodes`), `:103-104` (`if (viewport)`)
**Issue type:** Control enabled in a state where it cannot act; no feedback
**Viewport:** All
**Move:** State matrix (mechanical item 8) — enumerate states the control can be in, not just the happy one
**Confidence:** High — the gating condition and the null-guard are both read directly.

**Evidence:**

```tsx
const ProofGraph = dynamic(
  () => import("@/app/components/features/proof-graph/ProofGraph"),
  { ssr: false, loading: () => <div className="flex flex-1 items-center justify-center text-sm text-[#9A9590]">Loading graph...</div> },
);
```

```tsx
      const viewport = getGraphViewportElement();
      if (viewport) await downloadGraphAsPng(viewport);
```

**Legibility-target:** a control that cannot perform its action should not present as actionable.

`ProofGraph` is client-only and code-split, so `.react-flow__viewport` does not exist in the DOM until that chunk resolves and React Flow mounts. The Export button, however, renders as soon as `hasNodes` is true — which happens the moment proposition data arrives, before the chunk loads. In that window the button is fully enabled and looks identical to its working state; clicking it runs the handler, `getGraphViewportElement()` returns `null`, the `if (viewport)` guard swallows the call entirely, and `exporting` toggles true-then-false with no download and — unlike the throw path above — not even a `console.error`. This is the quietest failure in the export surface.

The window is normally short, but it widens exactly when it matters: slow connections, cold caches, and large decompositions. This is pre-existing (`if (viewport)` predates `d86d2dc`) and this diff does not worsen it; I raise it because it is the third distinct silent-failure branch in a path this commit was specifically sent to de-silence, and fixing the two above without this one leaves the surface still capable of no-oping.

**Recommendation:** gate the button on graph readiness rather than on `hasNodes` alone (a `ready` flag set by `ProofGraph`'s mount, or `disabled={!graphMounted}`), and turn the `if (viewport)` guard into an `else` branch that sets the same `exportError` state proposed above.

---

#### `img-src 'self' data: blob:` silently breaks remote images in rendered markdown

**Severity:** Minor
**Location:** `proxy.ts:22` (`"img-src 'self' data: blob:"`); rendering surface `app/components/features/output-editing/LatexRenderer.tsx:33-38`
**Issue type:** CSP rendering consequence — content degradation with no explanation
**Viewport:** All
**Move:** Trace each CSP directive to the concrete DOM the app produces
**Confidence:** Medium — the directive and the renderer are certain; how often model or source markdown carries a remote image URL in this domain is a judgment call.

**Evidence:**

```ts
    "img-src 'self' data: blob:",
```

**Legibility-target:** content that cannot render should degrade to something the reader can interpret, not a broken-image glyph with no cause.

`LatexRenderer` runs `ReactMarkdown` with `remarkGfm`, so `![caption](https://example.org/fig.png)` in semiformal proof output or in pasted source material becomes a real `<img>` with a cross-origin `src`. Under this policy the browser refuses the load: Chrome paints its broken-image icon plus the alt text, Firefox renders the alt text alone, and the only explanation lives in the console. In a tool whose subject matter is mathematical proofs the likelihood is genuinely low — LaTeX figures arrive as `\includegraphics`, not markdown image tags, and remote images in LLM prose are rare — which is why this is Minor rather than Major. It is a deliberate and defensible security posture; the gap is that the posture has no user-facing story.

Worth stating positively: `rehypeRaw` is *not* in the plugin list, so raw HTML in markdown is dropped by react-markdown before CSP ever sees it. The proxy's own comment ("even if something slipped past markdown sanitization") is describing a real second layer, not a hypothetical one.

**Recommendation:** if remote images are ever expected, pass a `urlTransform` to `ReactMarkdown` that rewrites disallowed schemes/hosts into a visible "external image blocked" placeholder with the URL as text, so the reader can follow the link manually. Otherwise document the restriction in `docs/USER_GUIDE.md` and leave the directive tight.

---

#### `force-dynamic` on the root layout removes the static shell, and there is no `loading.tsx` to cover the gap

**Severity:** Informational
**Location:** `app/layout.tsx:26` (`export const dynamic = "force-dynamic"`); absence of `app/loading.tsx`, `app/error.tsx`, `app/global-error.tsx`
**Issue type:** Perceived-performance / first-paint affordance
**Viewport:** All; most noticeable on mobile (320–480px) where connections are slowest
**Move:** Ask what the user sees during the interval the change lengthens
**Confidence:** High on the mechanism (verified: no `loading.tsx`, `error.tsx`, `not-found.tsx`, or `global-error.tsx` exists anywhere under `app/`); the magnitude of the TTFB change is unmeasured.

**Evidence:**

```tsx
export const dynamic = "force-dynamic";
```

**Legibility-target:** the interval between navigation and first meaningful paint should be occupied by something other than a blank viewport.

The directive is correct and necessary — a prerendered document would bake one nonce and reuse it for every visitor, which the comment states accurately. The side effect is that every route under this layout now renders per request instead of being served from the static shell. `app/page.tsx` is `"use client"`, so the server-rendered HTML was already a thin shell, which bounds the cost; but the shell is no longer cacheable, and the repo has no `loading.tsx` to fill the wait. On a cold serverless start the browser shows an empty white viewport for the whole server-render round trip. On a fast desktop connection this is imperceptible. At 320–480px on mobile data it is the difference between "loading" and "broken".

Related and worth recording as residual risk rather than a defect: with no `error.tsx` or `global-error.tsx`, the app has no rendering-level failure affordance at all. If the nonce delivery ever regresses — the exact defect this iteration fixed — the failure mode is a blank or inert page with no message, which is what made the prior iteration's hydration-death finding Critical rather than Major. The fix removes the cause; it does not add a net.

**Recommendation:** add a minimal `app/loading.tsx` (skeleton matching the two-panel shell) and an `app/global-error.tsx` with a reload affordance. Neither belongs in this commit; file as follow-up.

---

#### `worker-src` is unspecified and inherits `default-src 'self'`, which will refuse `blob:` workers

**Severity:** Informational
**Location:** `proxy.ts:19-29` (`buildCsp` directive list)
**Issue type:** Latent CSP rendering constraint
**Viewport:** N/A
**Move:** Enumerate the fallback chain for directives the policy omits
**Confidence:** High — directive list read verbatim; absence of workers verified by grep across `app/`.

**Evidence:**

```ts
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
```

**Legibility-target:** none today — recording the constraint so a future change does not rediscover it as a blank panel.

There are no `new Worker(...)` call sites in the app today (verified), so nothing is broken. But `worker-src` falls back to `default-src 'self'`, and the common pattern for bundled workers — and the one `jszip`, `katex`, and Monaco-style editors reach for — is `new Worker(URL.createObjectURL(blob))`, which `'self'` refuses. The failure surfaces as a panel that renders its container and never its content, with only a console violation to explain it. Note that `img-src` already carries `blob:` while `worker-src` does not, so the asymmetry is easy to miss when reading the list.

**Recommendation:** no change now. If a worker is ever introduced, add `worker-src 'self' blob:` in the same commit, and add a `proxy.test.ts` case asserting it.

---

#### GraphPanel header button row cannot wrap; four controls overflow below ~1024px

**Severity:** Informational
**Location:** `app/components/panels/GraphPanel.tsx:114` (header row) and `:118` (button group)
**Issue type:** Unbounded content / horizontal overflow (mechanical item 1)
**Viewport:** 768–1024px and 320–480px
**Move:** Mechanical items 1 and 3 applied to the surface hosting the diff-affected control
**Confidence:** High on the class strings (read verbatim); Medium on the exact breakpoint, which depends on the split ratio in `PanelShell` and on `sourceCount` (the Decompose label grows with it).

**Evidence:**

```tsx
      <div className="flex items-center justify-between border-b border-[#DDD9D5] bg-[#F5F1ED] px-6 py-3">
```

```tsx
        <div className="flex items-center gap-2">
```

**Legibility-target:** every control in a panel header must remain fully visible and hittable at the narrowest supported panel width.

**This diff did not introduce this and I am not asking it to fix it** — I record it because it is the container the export affordance lives in, and any recommendation above that adds an inline error message lands in this row. Neither div carries `flex-wrap`, `min-w-0`, or an overflow rule. In the widest state — `hasNodes && hasContent && hasStructuredSources && extractionStatus === "done"` — the row holds "Export .png", "Formalize All", "Re-extract with LLM", and "Decompose N Sources" plus the "Decomposition" heading. At 1920px+ with the graph panel given roughly half the width this is comfortable. In a 768–1024px two-panel split, or at 320–480px, the flex children compress past their padding and then overflow the `px-6` box; because the parent is inside `overflow-hidden` (`:113`), the overflow is *clipped*, not scrolled — the rightmost control is silently cut off with no scroll affordance to reach it. At 1366×768 (mechanical item 5) the horizontal dimension is fine; vertical spacing in this header is a fixed `py-3` and does not compound.

**Recommendation:** add `flex-wrap gap-y-2` to the button group and `min-w-0` to the header's flex children. Follow-up ticket, not this commit.

---

## What Looks Good

- **The `connect-src`-vs-`data:` reasoning is correct and the docblock explains *why*, not *what*.** `dataUrlToBlob`'s comment names the exact directive that made `fetch(dataUrl)` fail and states the tradeoff it is avoiding (decode in-process rather than widen `connect-src` for one export helper). A future reader tempted to "simplify" this back to `fetch` has the reason sitting right there. Both call sites (`:54`, `:65`) were converted — no half-migration.
- **The MIME extraction is right, which matters for the file the user actually opens.** `data:image/png;base64,…` yields header `image/png;base64` → strip `;base64` → `split(";")[0]` → `image/png`. The `Blob` carries the correct type into `triggerDownload`, so the downloaded `proof-graph.png` is a real PNG to the OS, not an octet-stream the user has to rename. The `|| "application/octet-stream"` fallback matches the data-URL spec's own default behavior.
- **`'strict-dynamic'` is the right choice specifically because of how this app loads its graph.** `ProofGraph` is `dynamic(..., { ssr: false })`, so React Flow arrives via a runtime-injected `<script>`. Under a nonce-only policy those injected chunks would be refused and the graph panel would sit on "Loading graph..." forever — the prior iteration's stuck-panel Critical. `'strict-dynamic'` propagates trust from the nonced bootstrap to script-inserted chunks, which is exactly the mechanism this codebase needs. The choice reads as deliberate, and the comment says so.
- **`style-src 'unsafe-inline'` is documented as a carve-out with a named cause, not left to be discovered.** The rendered surfaces that depend on it are real and load-bearing: Tailwind v4's emitted styles, React Flow's per-frame inline `transform` on `.react-flow__viewport`, KaTeX's inline sizing, and `LatexRenderer`'s own `style={{ lineHeight: 1.9 }}`. Tightening this to nonces would break pan/zoom rendering outright. The comment says "deliberate carve-out, not an oversight," which is the correct disclosure.
- **`font-src 'self' data:` matches what the app actually loads.** `next/font/google` self-hosts EB Garamond and Geist Mono under `/_next/static/media`, and `katex.min.css` resolves its fonts same-origin. No Google Fonts CDN reference exists in `globals.css` (verified — the only `@import` is `tailwindcss`). Typography renders unchanged, and `html-to-image`'s font-inlining step reads those same-origin faces through `connect-src 'self'`, so the exported PNG keeps the app's type rather than falling back to a system serif.
- **`img-src` includes both `data:` and `blob:`, which is what the export pipeline needs.** `html-to-image` rasterizes through an intermediate `<img src="data:image/svg+xml,…">`, and `triggerDownload` hands the anchor a `blob:` object URL. A tighter `img-src 'self'` would have broken the export at the rasterization step — a subtle failure that would have looked like a `dataUrlToBlob` bug.
- **The proxy matcher excludes prefetches for a stated reason.** Skipping requests carrying `next-router-prefetch` / `purpose: prefetch` avoids minting a nonce for a render that may never paint. The `missing:` array is the correct mechanism for this and is spelled out in the comment.
- **`x-nonce` is `set`, not `append`.** `requestHeaders.set("x-nonce", nonce)` overwrites any client-supplied value rather than appending to it, and the comment names the smuggling scenario it prevents. Small detail, easy to get wrong, got right.

## Keyboard Navigation

No new focusable elements in this diff.

The diff adds no JSX and therefore no focusable elements, tab stops, focus styles, or ARIA. Three keyboard/AT observations follow from the *behavior* changes and are folded into the findings above rather than repeated as separate items: (1) the "Exporting…" label swap on `DownloadButton` is not inside a live region, so no state change is announced during an export; (2) `DownloadButton` uses `disabled:pointer-events-none` (`app/components/ui/DownloadButton.tsx:17`), so a keyboard user who activates it loses focus to `document.body` for the duration of the export and does not regain it when the button re-enables; (3) the export failure paths produce no announceable output at all. All three are pre-existing; (1) and (3) would be closed by the `aria-live` region recommended in the second finding.

## Viewport Verification Checklist

Static reasoning only — no browser was available in this environment. Items marked **runtime** need confirmation against a real render before the CSP change ships.

| # | Check | 320–480px | 768–1024px | 1366×768 | 1920px+ |
|---|---|---|---|---|---|
| 1 | Unbounded content / silent clipping | Pass (no change in diff) | **Informational** — GraphPanel header row clips inside `overflow-hidden`, pre-existing | Pass | Pass |
| 2 | Controls trapped in scroll containers | Pass — no scroll containers added | Pass | Pass | Pass |
| 3 | `shrink-0` vs `flex-1 min-h-0` | N/A — no flex declarations in diff | N/A | N/A | N/A |
| 4 | Absolute positioning anchors | N/A — no positioned elements in diff | N/A | N/A | N/A |
| 5 | Vertical spacing | N/A | N/A | Pass — header is fixed `py-3`, no compounding | N/A |
| 8 | State matrix, diff-affected controls | See table below | — | — | — |

**Runtime checks this review could not perform:**
- Load the app with the proxy active and confirm hydration completes (no `Refused to execute inline script` in console) — the mechanism is verified by reading, the outcome is not.
- Confirm the `ProofGraph` chunk loads under `'strict-dynamic'` and the panel leaves its "Loading graph..." state.
- Confirm Next 16 applies the nonce to its `<link rel="preload" as="script">` tags as well as to `<script>`; if it does not, preloads are refused and page load is slower (not broken) — cosmetic-to-performance only.
- Export a deliberately oversized graph (many nodes, zoomed out, `pixelRatio: 2`) and check whether the downloaded PNG is 0 bytes — the reproduction for the first finding.

**State matrix — controls whose behavior this diff changes** (neither control is itself modified by the diff):

| Control | State | Visual | Correct? |
|---|---|---|---|
| `DownloadButton` "Export .png" (`GraphPanel.tsx:119`) | Idle | Label "Export .png", enabled | Yes |
| | Exporting | Label "Exporting…", `disabled:opacity-40`, pointer-events off | Yes, but no live-region announcement |
| | Success | Returns to Idle; file downloads | Yes |
| | Throw (`Not a data: URL`, `atob` failure) | Returns to Idle; **no file, no message** | **No** — Major finding 2 |
| | Empty payload (`data:,`) | Returns to Idle; **0-byte file "downloads"** | **No** — Major finding 1 |
| | Viewport not yet mounted | Returns to Idle; **no file, not even a console error** | **No** — Minor finding 3 |
| | Hidden | Not rendered when `!hasNodes` | Yes |
| IconRail "Export All" (`IconRail.tsx:105`) | Idle / Disabled | `disabled:opacity-40` when `!hasExportableContent` | Yes |
| | Graph capture throws | Zip downloads **without** `proof-graph.png`, no notice | **No** — Major finding 2 |
| | No in-flight state at all | `handleExportAll` (`page.tsx:574`) sets no pending flag; zip generation is unindicated | Pre-existing gap, not raised as a finding |

## Summary Table

| # | Severity | Finding | Location | Introduced by this diff? |
|---|---|---|---|---|
| 1 | Major | 0-byte PNG accepted as a valid export; decoder treats empty payload as success | `exportGraph.ts:23-45` | Guard added by diff; gap not closed |
| 2 | Major | All new throw sites terminate in `console.error`/`warn`; no user-visible failure | `GraphPanel.tsx:98-109`, `exportAll.ts:60-69` | New throw sites added by diff |
| 3 | Minor | Export button enabled before `.react-flow__viewport` mounts; silent no-op | `GraphPanel.tsx:14-17, 103-104, 119` | No — pre-existing |
| 4 | Minor | `img-src` blocks remote images in rendered markdown; broken-image glyph only | `proxy.ts:22`, `LatexRenderer.tsx:33-38` | Yes |
| 5 | Informational | `force-dynamic` removes static shell; no `loading.tsx` or `global-error.tsx` | `app/layout.tsx:26` | Yes (directive); absence pre-existing |
| 6 | Informational | `worker-src` unset, inherits `'self'`; will refuse `blob:` workers | `proxy.ts:19-29` | Yes (latent) |
| 7 | Informational | GraphPanel header row cannot wrap; clips below ~1024px | `GraphPanel.tsx:114, 118` | No — pre-existing |

## Overall Assessment

The two Criticals this iteration was sent to fix look structurally resolved from the code. Hydration death is addressed at the right layer — the nonce goes on the *request* headers so Next stamps it onto its own bootstrap scripts, `force-dynamic` stops a prerender from baking a single nonce for all visitors, and `'strict-dynamic'` is what lets the `ssr: false` `ProofGraph` chunk load at all. The stuck-graph-panel symptom shared that root cause and should clear with it. The reasoning is documented in comments that say why rather than what, which is the thing that makes this kind of fix survive contact with a future maintainer. Runtime confirmation is still owed on all of it; I read code, I did not load a page.

The PNG export fix is where I'd push back. `dataUrlToBlob` correctly removes the `connect-src` block, gets the MIME type right, and is applied at both call sites — the mechanical part is done. But the finding it descends from was *silent* export failure, and the export path is still silent on three distinct branches: an empty payload downloads a 0-byte file that looks like success, a decoder throw produces a button blink and nothing else, and an unmounted viewport no-ops without even reaching the console. The commit removed one cause of failure without adding the affordance that would make the remaining causes legible. Closing that is small — a non-empty check in the decoder, an error state on the button, and an `aria-live` region — and it is what turns "the export works now" into "the user can tell whether the export worked."

The CSP itself is well-matched to what this app renders. Every directive I traced to a real DOM consequence checks out: `unsafe-inline` styles for React Flow's transforms and KaTeX, `data:`/`blob:` images for the `html-to-image` rasterization and the download anchor, self-hosted fonts for both the page and the exported PNG. The `img-src` restriction on remote markdown images is a real but low-likelihood degradation in this problem domain, and the missing `worker-src` is a note-to-future-self rather than a defect.

Nothing here is a merge blocker on layout grounds — there is no layout in this diff. The two Majors are affordance gaps in the path this commit was specifically dispatched to repair, and I'd want them closed in the same iteration rather than deferred, precisely because deferring them leaves the original finding half-fixed in a way that reads as fixed.

## Goal-Alignment Note

- **Answered:** Whether the iteration-1 fixes hold up in the surfaces the user actually sees — nonce delivery and `'strict-dynamic'` reconciled against the app's `ssr: false` dynamic import and inline-style dependencies (they do, by code reading); the error and affordance path of the new `dataUrlToBlob` decode, which was the specific question asked (three silent branches remain, two of them Major); CSP consequences for rendered content (markdown images, fonts, KaTeX, React Flow transforms, the export rasterization pipeline); mechanical items 1–5 and 8 across 320–480 / 768–1024 / 1366×768 / 1920px+, with the honest result that the diff contains no layout code and items 3–4 are not applicable.
- **Out of scope:** Fix wiring against Next 16 internals and the confirmation that both export call sites use `dataUrlToBlob` — taken as given from the merged fact-check, not re-verified. Security properties of the CSP (`form-action` absence, `frame-ancestors`, nonce entropy from `crypto.randomUUID`) belong to `security-reviewer`. The `proxy.test.ts` and `exportGraph.test.ts` additions were not reviewed as tests. Pre-existing layout issues are recorded as Informational and explicitly flagged as not introduced here.
- **Escalate:** Two Majors, both affordance gaps in the export path this iteration was dispatched to fix — a 0-byte PNG that presents as a successful download, and failure branches that surface only in the console. Recommend closing both in this iteration rather than carrying them, since the parent finding was "silent PNG export failure" and it remains silent. Also flag for the orchestrator that every conclusion about hydration and chunk loading here is derived from code reading; the runtime checklist above has not been executed, and the prior iteration's Criticals were exactly the kind that only appear on a real page load.
