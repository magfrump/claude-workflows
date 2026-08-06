# UI Visual Review — strict CSP with per-request nonces (e3 arm1, full loop iteration 1)

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-csp-arm1` (branch `e3/csp-arm1`)
**Commit:** e5d95a9
**Date:** 2026-08-06
**Based on:** upstream code-fact-check verdict for this arm (nonce delivery; `connect-src` vs. `exportGraph`)
**Files in diff:** `app/layout.tsx` (modified), `proxy.ts` (added)

## Environment

- **Files reviewed:** `app/layout.tsx`, `proxy.ts`; rendering surfaces the CSP governs — `app/page.tsx`, `app/globals.css`, `app/lib/utils/exportGraph.ts`, `app/lib/utils/export.ts`, `app/lib/utils/fileExtraction.ts`, `app/lib/utils/pdfPropositionParser.ts`, `app/components/features/proof-graph/ProofGraph.tsx`, `app/components/features/causal-graph/CausalGraphView.tsx`, `app/components/features/output-editing/LatexRenderer.tsx`
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet / small laptop), 1366x768 (common laptop), 1920px+ (desktop)
- **Target browsers / platforms:** modern evergreen browsers + mobile Safari
- **Review mode:** Mechanical (checklist items 1–5 and 8), extended with CSP rendering-consequence analysis
- **Project UI guidelines:** none found. `docs/` contains `ARCHITECTURE.md`, `USER_GUIDE.md`, `MAINTAINING_USER_GUIDE.md`, `decisions/`, `plans/`, `proposals/`, `spikes/`, `thoughts/` — no `UI_LAYOUT_GUIDELINES.md` or equivalent. Checklist defaults apply throughout.

**Note on scope.** This diff changes no layout markup, no CSS, and no Tailwind class strings. `app/layout.tsx`'s only rendered-output change is `export default function` → `export default async function` plus an `await headers()` call; the `<html>`/`<body>` tree and the `body` className string are byte-identical. Mechanical checklist items 1–5 therefore have no direct surface in this diff (see *What Looks Good*). The reviewable visual risk in this change is entirely **second-order**: a response header that decides whether the app's scripts, styles, fonts, images, workers, and export path are allowed to load at all. That is what the findings below cover.

---

## Findings

#### Nonce never reaches Next's bootstrap scripts; `'strict-dynamic'` then blocks the entire client bundle, rendering a dead un-hydrated shell

**Severity:** Critical
**Location:** `proxy.ts:29` (script-src), `proxy.ts:44-53` (nonce generation and header plumbing), `app/layout.tsx:27-31` (the comment asserting the mechanism)
**Issue type:** Other (CSP-induced render failure) — manifests as total loss of interactivity at every viewport
**Viewport:** all (320px through 1920px+)
**Move:** CSP rendering-consequence analysis for scripts under `'strict-dynamic'`, using the fact-check's nonce-delivery verdict as foundation
**Confidence:** High that the CSP is unsafe as written; the fact-check owns the underlying delivery verdict, and I reason below under *both* of its readings

**Evidence (verbatim):**

`proxy.ts:29`
```
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${devOnly}`,
```

`proxy.ts:44-53`
```
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
  return response;
}
```

`app/layout.tsx:27-31`
```
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
```

**Legibility-target:** the app's primary two-panel interface must be operable at 320px and above; under this finding it is inert at every width, so the target is missed unconditionally rather than at a particular breakpoint.

The comment at `app/layout.tsx:29-31` states that Next tags its bootstrap `<script>` elements "with the nonce from the response's CSP header." Next reads the nonce from a **request** header named `Content-Security-Policy`, not from the response header — the proxy sets a custom `x-nonce` request header (`proxy.ts:45`) and puts the real CSP only on the response (`proxy.ts:51`). Neither of those is where Next looks, and nothing in `app/layout.tsx` reads `x-nonce` back out and threads it onto anything; `await headers()` is called and its result discarded. This is the fact-check's verdict, and I take it as foundation rather than re-deriving it.

The rendering consequence is worse than "scripts lack a nonce," because `'strict-dynamic'` changes what the rest of the directive means. Under CSP Level 3, when `'strict-dynamic'` is present in `script-src`, host-source and scheme-source expressions — and `'self'` — are **ignored** for script loading. So the `'self'` at `proxy.ts:29` does not provide a fallback. Next's initial HTML emits `<script src="/_next/static/chunks/...">` tags; with no nonce on them and `'self'` neutralized, every one is blocked. React never hydrates. Because `app/page.tsx` is a client component that Next still server-renders, the user does not get a blank white page — they get the SSR'd markup of `<main className="flex h-screen flex-col">` and its panels, which *looks* like the application but responds to nothing. Buttons do not fire, panels do not switch, the React Flow graph never lays out (dagre positioning and `fitView` at `ProofGraph.tsx:50-51` are client-side), and file upload does nothing. This is the worst class of failure for a visual review: the affordances are all present and all lying.

Under the fact-check's *alternate* reading — the undocumented router-mirroring path that saved the nonce for one self-hosted replicate — Next does tag its bootstrap scripts, `'strict-dynamic'` propagates trust to the chunks they load, and the app renders and hydrates normally. Findings 2 and 3 below then become the live defects. The problem for a reviewer is that these two readings are visually indistinguishable at the source level and differ only by deployment target, so the change ships a first-paint outcome that depends on an undocumented behavior. Treat the failing reading as the default until a `Content-Security-Policy` **request** header is set explicitly.

**Recommendation:** Set the CSP on the request headers as well as the response, which is the documented Next.js contract and makes the behavior independent of the router-mirroring path.

```diff
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
+ // Next reads the nonce out of the *request* CSP header to tag its bootstrap
+ // <script> tags. Setting it only on the response is not sufficient.
+ requestHeaders.set("Content-Security-Policy", csp);
```

with `const csp = buildCsp(nonce);` hoisted above so request and response carry the identical string. Then correct the `app/layout.tsx:29-31` comment, which currently documents the mechanism that does not work. Verify by loading the app and confirming the bootstrap `<script>` tags in view-source carry `nonce="..."` and the console is free of CSP script violations — a check that costs one page load and would have caught this.

---

#### `connect-src 'self'` blocks `fetch(dataUrl)`, breaking PNG export and the zip export that embeds it

**Severity:** Critical
**Location:** `proxy.ts:33`; blocked call sites `app/lib/utils/exportGraph.ts:24` and `app/lib/utils/exportGraph.ts:37`
**Issue type:** Other (CSP-induced feature failure) — user-visible as a dead export control
**Viewport:** all
**Move:** CSP rendering-consequence analysis of the export path under `connect-src`
**Confidence:** High

**Evidence (verbatim):**

`proxy.ts:33`
```
    "connect-src 'self'",
```

`app/lib/utils/exportGraph.ts:20-27`
```
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
  triggerDownload(blob, filename);
```

`app/lib/utils/exportGraph.ts:31-38`
```
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  return res.blob();
```

**Legibility-target:** the export control must give a truthful completion or failure state at 1366x768, the viewport where the graph panel and its toolbar are both visible without scrolling. Currently it gives neither.

`toPng` returns a `data:image/png;base64,...` string. Both functions then round-trip it through `fetch()` purely to obtain a `Blob`. `fetch()` is governed by `connect-src`, and `connect-src 'self'` does not include the `data:` scheme — schemes must be listed explicitly. Both fetches are blocked and reject with a `TypeError`. The header comment at `proxy.ts:16-17` justifies `'self'` on the grounds that "Anthropic / OpenAlex / OpenRouter calls are server-to-server," which is accurate as far as it goes but enumerates only the third-party API surface; it does not account for this same-page `data:` fetch, so the carve-out reasoning has a hole rather than an error.

Note the asymmetry that makes this easy to miss in review: `img-src 'self' data: blob:` (`proxy.ts:31`) *does* permit `data:`, so `toPng`'s own internals — which serialize the cloned DOM into an SVG `foreignObject`, assign it to an `Image`, and paint to a canvas — succeed. The PNG is generated correctly and only the retrieval step fails. From the user's side the graph visibly re-renders for export and then nothing downloads.

The visual failure mode depends on the caller's error handling and is bad in either direction: an unhandled rejection leaves the export button in its normal state with no file and no message, which reads as "the click didn't land" and invites repeat clicks; a caught rejection surfaces a generic error for what is a configuration problem, not a user problem. The zip path is collateral — `graphToPngBlob` is the embedding step, so "export everything" fails as a whole rather than degrading to a zip without the image.

**Recommendation:** Drop the `fetch` round-trip entirely rather than widening the CSP. Converting a data URL to a Blob needs no network layer, and this keeps `connect-src 'self'` intact — the stricter and better outcome.

```diff
- const res = await fetch(dataUrl);
- const blob = await res.blob();
- triggerDownload(blob, filename);
+ triggerDownload(dataUrlToBlob(dataUrl), filename);
```

with a small shared helper decoding the base64 payload via `atob` into a `Uint8Array` and wrapping it in `new Blob([bytes], { type: "image/png" })`, applied at both `exportGraph.ts:24` and `exportGraph.ts:37`. If the round-trip is kept for expediency, `connect-src 'self' data:` is the minimum change, but that widens the directive for the whole app to work around two lines. Either way, add a failure toast on the export path so a blocked export cannot present as a no-op.

---

#### No `worker-src`; the `'strict-dynamic'` fallback may block the pdf.js worker, silently failing PDF upload

**Severity:** Major
**Location:** `proxy.ts:27-36` (directive list — no `worker-src` or `child-src` entry); affected call sites `app/lib/utils/fileExtraction.ts:25-30` and `app/lib/utils/pdfPropositionParser.ts:442-449`
**Issue type:** Other (CSP-induced feature failure) — user-visible as a stalled upload affordance
**Viewport:** all
**Move:** CSP rendering-consequence analysis of content the app renders — the PDF ingestion path that feeds the input panel
**Confidence:** Medium — the spec's fallback behavior for workers under `'strict-dynamic'` has genuine cross-browser divergence; the recommended fix is correct regardless of which way a given engine resolves it

**Evidence (verbatim):**

`proxy.ts:27-36`
```
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${devOnly}`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
    "connect-src 'self'",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
  ];
```

`app/lib/utils/fileExtraction.ts:24-30`
```
async function getPdfjs() {
  const pdfjsLib = await import("pdfjs-dist");
  pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
    "pdfjs-dist/build/pdf.worker.min.mjs",
    import.meta.url,
  ).toString();
  return pdfjsLib;
}
```

**Legibility-target:** the file-upload control must reach a terminal state (parsed, or an explicit error) at 320px, where upload is the primary entry point into the app and there is no room for an ambiguous spinner.

Worker script loads resolve through the fallback chain `worker-src` → `child-src` → `script-src` → `default-src`. This CSP defines none of the first two, so pdf.js's worker is adjudicated by `script-src` — the one directive carrying `'strict-dynamic'`. A `new Worker(url)` request cannot carry a nonce, and `'strict-dynamic'` neutralizes the `'self'` that would otherwise permit the same-origin `/_next/static/media/pdf.worker.min.mjs` URL. Whether the worker survives depends on whether the engine extends `'strict-dynamic'`'s trust-propagation to a worker request initiated by already-trusted script; engines have not agreed on this, which is precisely why hardening guides recommend stating `worker-src` explicitly whenever `'strict-dynamic'` is in play rather than relying on the fallback.

If blocked, `getDocument(...).promise` never settles or rejects opaquely. Both `extractTextFromPDF` and the structured extractor at `pdfPropositionParser.ts:442` sit behind the file-upload affordance, so the user picks a PDF and the input panel stays empty. At 320–480px this is the most damaging place for an indeterminate state, since the upload control typically occupies the fold and there is no adjacent content to signal that anything is still in progress. This finding is contingent on Finding 1 being fixed — if scripts are blocked outright, upload never runs at all.

**Recommendation:** State the directive explicitly rather than depending on fallback resolution. `blob:` is included because bundlers commonly materialize worker entry points as blob URLs, and omitting it trades one silent failure for another.

```diff
    "connect-src 'self'",
+   "worker-src 'self' blob:",
    "frame-ancestors 'none'",
```

Verify by uploading a PDF with the production CSP active and confirming text lands in the input panel with no `Refused to create a worker` console entry.

---

#### `app/layout.tsx` comment documents a nonce mechanism that does not hold, and the expansion added by e5d95a9 increases its authority

**Severity:** Minor
**Location:** `app/layout.tsx:27-39`
**Issue type:** Other (documentation accuracy with downstream visual consequence)
**Viewport:** N/A — affects maintenance, not layout
**Move:** CSP rendering-consequence analysis; the comment is the artifact that would stop a future reviewer from re-checking Finding 1
**Confidence:** High that the comment states the mechanism inaccurately; the fact-check owns the verdict itself and this finding defers to it rather than duplicating it

**Evidence (verbatim):**

`app/layout.tsx:27-39`
```
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
  //
  // This dynamic opt-out is deliberate and load-bearing, not an oversight: a
  // statically prerendered document is built once, so its <script> tags would
  // carry a stale nonce (or none) and be blocked by the CSP on every request
  // after the first. Per-request nonces and static rendering are mutually
  // exclusive by construction. The cost here is nil — the app is a single
  // "use client" route with no generateStaticParams, revalidate, or ISR — so
  // there is nothing static to lose. Revisit only if we drop nonces in favour
  // of hashes, which would let prerendered output keep a stable CSP.
```

**Legibility-target:** N/A.

The second paragraph, added by e5d95a9 to waive a lite-review blocker, is well-reasoned and its conclusion is right — per-request nonces and static prerendering genuinely are incompatible, and this app has no static route to lose. But it is built on top of the first paragraph's premise that the nonce is already arriving where Next needs it. Expanding the justification without re-testing that premise makes the block read as settled: a future maintainer encountering a blank-feeling app is now less likely to suspect the nonce path, because thirteen lines of comment assert it works. The `await headers()` call is doing real work (forcing dynamic rendering) while its stated purpose (nonce delivery) is not achieved, and nothing in the file consumes `x-nonce` — the discarded return value is the visible tell.

**Recommendation:** After applying Finding 1's fix, rewrite the first paragraph to name the actual mechanism — that the proxy sets the CSP on the *request* headers and Next reads the nonce from there — and keep the second paragraph as-is; its static-rendering reasoning stands on its own and should survive.

---

#### Style, font, and image directives are correctly scoped for what this app renders

**Severity:** Informational
**Location:** `proxy.ts:30-32`
**Issue type:** Other (CSP rendering-consequence, no defect)
**Viewport:** all
**Move:** CSP rendering-consequence analysis for styles, fonts, and images
**Confidence:** High

**Evidence (verbatim):**

`proxy.ts:30-32`
```
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
```

**Legibility-target:** typography and graph node styling must hold at 320px through 1920px+; these directives do not threaten that.

Recording this as a positive finding because the analysis is non-obvious and a future tightening pass will need it. `style-src 'unsafe-inline'` is load-bearing well beyond the Tailwind v4 justification given at `proxy.ts:12-14`: it also covers the `<style>` block `next/font/google` injects for the `EB_Garamond` and `Geist_Mono` `--font-*` variables consumed by the `body` className, React Flow's per-node inline `transform` styles (without which every graph node stacks at the origin), and the inline `style={{...}}` attributes across roughly nineteen components including `ProofGraphNode.tsx`, `LatexRenderer.tsx`, and `EditableOutput.tsx`. Any future move to nonce-based styles must account for all four, not just Tailwind.

Fonts resolve cleanly: `next/font/google` self-hosts at build time and `katex/dist/katex.min.css` (imported at `app/layout.tsx:5` and `LatexRenderer.tsx:7`) is bundled with its font files rewritten to `/_next/static/media/`, so every font request is same-origin and satisfied by `'self'`. No external font host is contacted, which is what makes the absence of a Google Fonts origin correct here rather than an omission — worth stating explicitly, since KaTeX rendering silently degrading to fallback glyphs would be a subtle math-legibility regression.

`img-src 'self' data: blob:` correctly anticipates `html-to-image`'s data-URL `Image` step and `URL.createObjectURL` usage. The `blob:` download in `export.ts:8-11` — anchor with `download`, blob object URL — is unaffected, as no shipped directive governs `download`-attributed anchor navigation.

**Recommendation:** No change. When `style-src` is eventually tightened, treat the four inline-style sources above as the migration checklist.

---

## What Looks Good

- **No layout regression surface.** The `<html>`/`<body>` tree and the `body` className string (`${ebGaramond.variable} ${geistMono.variable} font-serif antialiased`) are unchanged. Mechanical items 1–5 have nothing to flag: the diff adds no container, no overflow rule, no `shrink-0`/`flex-1` decision, no absolutely-positioned element, and no padding or gap. The app shell at `app/page.tsx:780` (`<main className="flex h-screen flex-col">`) is untouched.
- **`img-src` and `font-src` are correctly scoped** to the app's real asset graph — see the Informational finding above.
- **`frame-ancestors 'none'`, `base-uri 'self'`, `object-src 'none'`** are the right defaults and carry no rendering cost for this app, which frames nothing and embeds no plugin content.
- **The dev-only `'unsafe-eval'` carve-out (`proxy.ts:24-26`)** is correctly gated on `NODE_ENV === "development"` and is genuinely necessary — without it Fast Refresh breaks and the dev console floods, which would have made every subsequent visual iteration on this branch harder. Correctly scoped so it cannot ship.
- **The proxy matcher (`proxy.ts:60-70`)** excludes `_next/static` and `_next/image`, so static assets and optimized images are not gratuitously subjected to per-request header work.
- **The static-rendering waiver reasoning** in `app/layout.tsx:32-39` is sound on its own terms and names a concrete revisit condition (switching nonces → hashes). Only its dependency on the first paragraph's premise is at issue.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Do not let a control present a false completion state | NNGroup — visible system status; WCAG 4.1.3 status messages | Findings 2 and 3 require the export and upload paths to surface an explicit failure rather than no-op when the CSP blocks them |
| Interactive affordances must be operable, not merely present | WCAG 2.1.1; NNGroup on weak signifiers | Finding 1 — an un-hydrated shell renders every control as a non-functional lookalike |
| State `worker-src` explicitly when `'strict-dynamic'` is present | CSP Level 3 fallback chain (`worker-src` → `child-src` → `script-src`) | Finding 3 recommendation |
| Prefer narrowing code over widening policy | Principle of least privilege | Finding 2 recommends removing the `fetch` round-trip rather than adding `data:` to `connect-src` |

## Keyboard Navigation

> No new focusable elements in this diff.

`app/layout.tsx` renders only `<html>`, `<body>`, and `{children}`; `proxy.ts` renders nothing. No focusable element, modal, overlay, dropdown, or focus-managing region is added or modified, and no page-level landmark is introduced or restructured. Focus order, Escape-key behavior, skip-link presence, and focus-trap risk are therefore all out of scope for this diff.

One consequence worth recording without counting it as a keyboard finding: under Finding 1, hydration never runs, so any keyboard handler registered by React — including Escape handlers on `ArtifactTypeModal.tsx` — never attaches. That is a downstream effect of the script block, not an independent keyboard defect, and it resolves entirely when Finding 1 is fixed.

## Interactive Element State Matrix (checklist item 8)

No interactive elements are added or modified by this diff. `app/layout.tsx` contributes no `<button>`, `<a href>`, `<input>`, `<textarea>`, `<select>`, `role="button"`-style element, or event handler; `proxy.ts` is server-side request handling with no rendered output. The matrix is empty by scope, not by omission — per the skill's diff-scoped rule, pre-existing controls elsewhere in the app are not in scope.

## Viewport Verification Checklist

- [ ] **360px mobile:** content reachable, no horizontal overflow, touch targets adequate — *unchanged by this diff at the CSS level. Blocked from verification by Finding 1: an un-hydrated shell cannot be assessed for touch-target behavior. Finding 3 additionally puts the primary upload entry point at risk at this width.*
- [ ] **1366x768 (common laptop):** all action buttons visible without scrolling — *unchanged by this diff. Finding 2 applies here: the graph export control is visible and reachable but non-functional.*
- [ ] **1920x1080 (standard desktop):** layout fills space without excessive whitespace — *unchanged by this diff.*

All three remain unchecked because the diff's risk is not resolvable by static layout reasoning — it requires loading the app with the production CSP active and reading the console. That one manual check, at any single viewport, would confirm or clear Findings 1, 2, and 3 together.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Nonce never reaches Next's bootstrap scripts; `'strict-dynamic'` blocks the client bundle → dead un-hydrated shell | Critical | CSP / render failure | `proxy.ts:29`, `proxy.ts:44-53`, `app/layout.tsx:27-31` | High |
| 2 | `connect-src 'self'` blocks `fetch(dataUrl)` → PNG and zip export fail | Critical | CSP / feature failure | `proxy.ts:33`; `app/lib/utils/exportGraph.ts:24,37` | High |
| 3 | No `worker-src`; `'strict-dynamic'` fallback may block pdf.js worker → PDF upload stalls | Major | CSP / feature failure | `proxy.ts:27-36`; `fileExtraction.ts:25-30`, `pdfPropositionParser.ts:442-449` | Medium |
| 4 | Layout comment documents a nonce mechanism that does not hold; e5d95a9 expansion raises its authority | Minor | Documentation accuracy | `app/layout.tsx:27-39` | High |
| 5 | Style / font / image directives correctly scoped for rendered content | Informational | CSP (no defect) | `proxy.ts:30-32` | High |

## Overall Assessment

The visual posture of this change is that it introduces no layout defect and every risk it carries is second-order: a response header deciding what the browser is allowed to load. That makes it deceptively low-risk to eyeball — the diff touches two files, changes no markup, and reads clean — while in fact gating whether the application renders as an application at all. Findings 1–3 are all fixable in place and none indicates a structural problem: the CSP's shape is right, and the `'strict-dynamic'` posture, the dev-only `'unsafe-eval'` gate, and the static-rendering waiver are all defensible calls. What is missing is the nonce's actual delivery path plus two directives that the app's real asset graph requires. The single most important thing to address is Finding 1 — not only because it is the most severe, but because it masks the other two: with the client bundle blocked, the export and upload paths never execute, so fixing Findings 2 and 3 first would produce no observable improvement and could easily read as "the fix didn't work." Fix the nonce delivery, confirm hydration in the console, then re-verify export and PDF upload. The broader process point is that all three findings are visible in a single page load with devtools open, and none was caught before this stage — a one-load smoke check against the production CSP is the cheapest possible guard for this class of change and belongs in the loop before a branch like this reaches review.

## Goal-Alignment Note

- **Answered:** Whether the diff introduces layout, sizing, positioning, spacing, or state-coverage defects (it does not — no markup or CSS changed), and what the CSP does to the content this app actually renders: scripts under `'strict-dynamic'` given the fact-check's nonce-delivery verdict, reasoned under both of its readings (Finding 1); the export path under `connect-src` (Finding 2); the pdf.js worker under the `worker-src` fallback (Finding 3); and styles, fonts, and images under their directives (Finding 5). Keyboard navigation and the item-8 state matrix are addressed and explicitly empty by scope.
- **Out of scope:** The nonce-delivery verdict itself — taken as foundation from the upstream fact-check and not re-derived (Finding 4 defers to it). Security posture of the CSP as a defense (whether `'strict-dynamic'` is the right hardening choice, whether `style-src 'unsafe-inline'` is an acceptable residual risk) belongs to the security critic; this review addresses those directives only where they determine what renders. Full-audit checklist items 6 and 7 (affordance review, responsive/cross-browser) were not run per mechanical mode. Pre-existing interactive elements outside the diff were not audited. No runtime verification was performed — no dev server was started, so all findings are static-analysis reasoning.
- **Escalate:** Finding 1 blocks the branch and should gate anything downstream, since it makes Findings 2 and 3 unobservable and would make their fixes appear ineffective. The deployment-dependence in Finding 1 needs a human call: the fact-check reports one replicate where an undocumented router-mirroring path saved the nonce self-hosted, which means this branch's behavior may differ between the developer's machine and the deployment target — the explicit request-header fix removes that dependence and should be preferred over confirming which environments happen to work. Finding 3's Medium confidence reflects real cross-browser divergence in how `'strict-dynamic'` resolves worker requests; the recommended explicit `worker-src` is correct either way, so this needs no adjudication, only application.
