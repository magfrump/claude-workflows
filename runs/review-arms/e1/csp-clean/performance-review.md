# Performance Review — csp-clean (d86d2dc..4f018ab)

**Scope:** `git diff d86d2dc..4f018ab` — strict-CSP proxy (`proxy.ts`, `proxy.test.ts`), root-layout dynamic-rendering opt-in (`app/layout.tsx`), and the graph-export encode path (`app/lib/utils/exportGraph.ts`). 4 files, +142/-18.
**Date:** 2026-08-06
**Based on:** merged code fact-check (`code-fact-check-report.md`, k=3) — its verified behavior is taken as foundation and not re-verified.
**Commit:** 4f018ab

---

### Data Flow and Hot Paths

Two distinct paths are touched, with opposite temperatures.

**Path A — page navigation (hot).** Every non-excluded request enters `proxy(request)` (`proxy.ts:38`). Per request it: generates 16 random bytes and base64-encodes them; builds a 10-element directive array and joins it; clones the entire incoming header set (`new Headers(request.headers)`); writes two headers onto the clone; constructs a `NextResponse.next()` with the rewritten request headers; writes the CSP a third time onto the response. The request then reaches `RootLayout`, which now `await headers()` — per the fact-check (Claim 1), this opts the whole app into dynamic rendering. The app has exactly one page (`app/page.tsx`, `"use client"`), so *every* HTML request in the product traverses this path. Frequency is bounded by human navigation, not by data size — there is no loop over a collection anywhere in the proxy.

**Path B — graph export (cold).** `downloadGraphAsPng` (GraphPanel export button, `GraphPanel.tsx:102-104`, behind a dynamic `import()`) and `graphToPngBlob` (Export-All zip, `exportAll.ts:62-65`) both funnel into the new `renderGraphPng` helper. Invoked once per explicit user click; N per session is single digits. The dominant cost is the DOM→canvas rasterization inside `html-to-image` at `pixelRatio: 2`, which this diff did not change.

**Measurement caveat applying to every finding below:** `node_modules` is not installed in this worktree and the repo contains no benchmark, Lighthouse config, or latency assertion (grep for `bench|lighthouse|p95|TTFB` returns only unrelated LLM wait-time-estimate code). Nothing in this review could be executed or timed.

---

### Findings

#### 1. `await headers()` in the root layout removes the entire app from static rendering

**Severity:** High
**Location:** `app/layout.tsx:29` (`await headers();`), affecting `app/page.tsx`
**Move:** (3) work moved to the wrong place — build time → request time
**Classification:** Macro / Hot (the root layout wraps the only page in the app; the proxy matcher confirms it runs on every non-excluded navigation)
**Confidence:** Medium-High on the mechanism (fact-check Claim 1 verifies the dynamic-rendering opt-in from source and rates the Next-internal nonce extraction Medium); Low on magnitude, which is unmeasured.
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> `// Opt this layout into dynamic rendering so Next.js injects the per-request`
> `// nonce (set by proxy.ts) into its own bootstrap <script> tags during render.`
> `await headers();` — `app/layout.tsx`

**Legibility-target:** a reader who sees a one-line `await` in a layout and does not connect it to the loss of the full route cache for every route in the app.

`app/page.tsx` is a client component, which before this change meant Next could prerender its HTML shell once at build and serve that shell from the static/full-route cache. `await headers()` makes the layout dynamic, and dynamic rendering is inherited downward, so the shell is now re-rendered on the server on every cold navigation. The scaling factor is per-request, not per-item: cost grows linearly with navigation count (1× server render per request instead of 0×), and it removes the option of serving HTML from a CDN edge entirely — a class of deployment optimization, not just a constant. It is genuinely load-bearing for the feature (the nonce cannot be baked into static HTML), which is why this is High and not Critical: the work is bounded and intentional, and the RSC payload for a client-component shell is small.

**Recommendation:** Keep it — but bound the blast radius rather than leave it app-wide. Two options worth measuring once `node_modules` is available: (a) push the dynamic opt-in down to a nested layout/segment if any future route does not need a nonce, so static routes stay static; (b) record a before/after TTFB number for `/` (dev-build `next build` output already labels routes ○ static vs ƒ dynamic — capture that diff) so the cost of this trade is documented rather than assumed. At minimum, note in the layout comment that this disables static generation app-wide, since that consequence is invisible at the call site.

---

#### 2. Proxy matcher does not exclude `/public` assets — latent per-asset multiplication

**Severity:** Low
**Location:** `proxy.ts:60-70` (`config.matcher.source`)
**Move:** (1) hidden multiplication — proxy invocations per page load scale with static-asset count
**Classification:** Macro / Hot (the matcher governs the request path) — but see the count discount below
**Confidence:** High that the gap exists; High that its present-day cost is zero.
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> `source: "/((?!api|_next/static|_next/image|favicon.ico).*)",` — `proxy.ts:64`

**Legibility-target:** a future contributor who adds `public/logo.png` and has no signal that they just added a proxy invocation to every page load.

The negative lookahead excludes Next's own asset routes but not `/public`. Files served from `public/` (currently `file.svg`, `globe.svg`, `next.svg`, `vercel.svg`, `window.svg`) would each match and run the full nonce-generation + header-clone + CSP-build sequence on a response that renders no HTML and can never use the nonce. The multiplication is `assets_referenced_per_page × navigations`. Today the factor is 1× because a repo-wide grep for `src="/…"` / `href="/…"` in `app/**/*.tsx` finds zero references to any of those five files — they are unused Next scaffolding. Severity is therefore held at Low despite the Macro×Hot cell (High) in the matrix: the multiplier is currently zero and the finding is a scaling trap, not a live cost.

**Recommendation:** Extend the lookahead with a static-extension alternation (e.g. `|.*\\.(?:svg|png|jpg|webp|ico|woff2?)$`) or delete the unused `public/*.svg` scaffolding so the gap cannot be silently activated. Cheap, one-line, and prevents the trap from arming itself the first time someone adds a logo.

---

#### 3. Full request-header clone on every navigation

**Severity:** Low
**Location:** `proxy.ts:47` (`const requestHeaders = new Headers(request.headers);`)
**Move:** (6) serialization tax
**Classification:** Micro / Hot (runs on every non-excluded navigation)
**Confidence:** High that the copy happens; Low that it matters.
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> `const requestHeaders = new Headers(request.headers);`
> `requestHeaders.set("x-nonce", nonce);`
> `requestHeaders.set("Content-Security-Policy", csp);` — `proxy.ts:47-50`

**Legibility-target:** a reader who assumes `new Headers(x)` is a cheap reference wrap rather than a full key/value copy.

`new Headers(init)` iterates and copies every incoming header (typically 15-30 entries on a browser navigation: cookies, accept, UA, sec-fetch-*, etc.), then the two `set` calls append to the copy, then `NextResponse.next({ request: { headers } })` re-serializes the whole set for the downstream render. Scaling factor is per-request and constant-bounded by header count, so it is a constant-factor cost, not a complexity change — and there is no supported way to mutate the incoming headers in place in the Next proxy API, so the clone is essentially forced by the framework.

**Recommendation:** Leave as is; it is idiomatic and the alternative does not exist in the API. Recorded so that it is not mistaken for a free operation if this proxy later grows more per-request work.

---

#### 4. `x-nonce` is written on every request and read by nothing

**Severity:** Low
**Location:** `proxy.ts:49`
**Move:** (3) work in the wrong place — specifically, work with no consumer at all
**Classification:** Micro / Hot (every non-excluded navigation)
**Confidence:** High — the fact-check (Claim 11) confirms `rg -n "x-nonce"` matches exactly one line repo-wide, the write itself, and that no `<Script>` anywhere receives a nonce prop.
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> `requestHeaders.set("x-nonce", nonce);` — `proxy.ts:49`

**Legibility-target:** a reader who assumes the header is the delivery mechanism (as the comment above it implies) and preserves it during a future refactor because it looks load-bearing.

This is dead per-request work: one map insertion plus ~30 bytes carried through the forwarded-header serialization on every navigation, consumed by nobody. The operative nonce channel is the *next* line, the request-side `Content-Security-Policy` header. The cost is negligible in isolation; the reason to raise it is that its comment misattributes the delivery path, so the cost is permanent — nobody will ever remove it because everybody will think it is required.

**Recommendation:** Either delete the line and its comment, or keep it and change the comment to say it is an unused convenience side-channel for future server components. Do not leave a dead per-request write described as the mechanism.

---

#### 5. `buildCsp` rebuilds and re-joins a 10-element constant array per request

**Severity:** Informational
**Location:** `proxy.ts:20-35`
**Move:** (8) caches — a memoizable constant computed per request
**Classification:** Micro / Hot
**Confidence:** High on the behavior; High that the cost is negligible.
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> `const directives = [` … `];`
> `return directives.join("; ");` — `proxy.ts:21-35`

**Legibility-target:** a reader deciding whether CSP construction is a candidate for hoisting.

Nine of the ten directives are compile-time constants; only `script-src` varies, and only in its nonce substring. The per-request work is one array allocation, one template interpolation, and one join over ~10 short strings — on the order of hundreds of nanoseconds against a request that includes a full React server render (finding 1). Splitting into a constant prefix/suffix pair would be a real but immeasurable saving, and would cost the current directive list its single-glance readability, which `proxy.test.ts` explicitly pins on ordering.

**Recommendation:** Do nothing. Noted as deliberately-not-optimized so a later reader does not "fix" it and break the order-pinning test for no gain.

---

#### 6. CSP string is serialized three times per request (two headers plus the response)

**Severity:** Informational
**Location:** `proxy.ts:50` and `proxy.ts:55`
**Move:** (6) serialization tax
**Classification:** Micro / Hot
**Confidence:** High — the fact-check (Claim 12) verifies both writes exist and that each has a distinct consumer.
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> `requestHeaders.set("Content-Security-Policy", csp);`
> …
> `response.headers.set("Content-Security-Policy", csp);` — `proxy.ts:50, 55`

**Legibility-target:** a reader who sees the same string set twice and assumes one is redundant.

The policy string is ~240 bytes. It is carried on the internal forwarded request (parsed by the renderer to extract the nonce) and again on the outbound response (enforced by the browser), so roughly 240 extra bytes cross the internal request boundary per navigation and 240 bytes go over the wire. Both copies are load-bearing per the fact-check, so this is a documented tax rather than waste; scaling is per-request and constant.

**Recommendation:** No change. Keep the existing comment explaining why both writes are necessary — it is the thing preventing someone from deleting the request-side copy and silently breaking nonce injection.

---

#### 7. `pixelRatio: 2` rasterization holds a 4×-area canvas plus the PNG blob in memory

**Severity:** Low
**Location:** `app/lib/utils/exportGraph.ts:17-22` (`renderGraphPng`)
**Move:** (4) memory lifecycle; (2) size of N
**Classification:** Macro / Cold (user-initiated export button; `GraphPanel.tsx:102` loads the module via dynamic `import()` only on click)
**Confidence:** Medium — the memory arithmetic is arithmetic, but the actual viewport dimensions at export time are unmeasured.
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> `const blob = await toBlob(viewportElement, {`
> `  pixelRatio: 2,`
> `  backgroundColor: EXPORT_BG,`
> `});` — `app/lib/utils/exportGraph.ts:18-21`

**Legibility-target:** a reader who reads `pixelRatio: 2` as a quality knob without seeing that it is a 4× memory knob.

Doubling the pixel ratio quadruples pixel count, so the intermediate canvas is `4 × width × height × 4` bytes of RGBA — for a 1600×900 React Flow viewport that is roughly 3200×1800×4 ≈ 23 MB live while the PNG encodes, and the encoded blob lives on top of it until `triggerDownload` revokes the object URL 100 ms after the click (`export.ts:15-18`). The scaling factor is viewport area, which grows with monitor size — a large desktop viewport pushes the peak toward 50 MB. The matrix cell (Macro×Cold) prescribes Medium; severity is discounted one step to Low because this diff neither introduced nor worsened the ratio — `pixelRatio: 2` is carried over verbatim from the `toPng` call it replaces.

**Recommendation:** No action required for this change. If graph-export OOMs are ever reported on low-memory devices, the lever is a viewport-size-conditional pixel ratio (drop to 1 above some area threshold), not a change to the encode path.

---

#### 8. Export-All builds the whole zip, including the graph PNG, in memory

**Severity:** Informational
**Location:** `app/lib/utils/exportAll.ts:60-68`
**Move:** (4) memory lifecycle
**Classification:** Macro / Cold (one explicit "Export All" click; `jszip` is itself code-split per the file's own header comment)
**Confidence:** Medium — call-site behavior is clear from source; total artifact sizes are unmeasured.
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> `const pngBlob = await graphToPngBlob(viewport);`
> `zip.file("proof-graph.png", pngBlob);` — `app/lib/utils/exportAll.ts:64-65`

**Legibility-target:** a reader estimating the peak memory of an export on a large decomposition.

The PNG blob from finding 7 is handed to JSZip and retained alongside every JSON artifact and every per-node folder (`nodes.forEach`, line 76 onward) until the archive is generated, so peak memory is the sum of all artifacts rather than a streaming maximum. Scaling is linear in node count and artifact size. This is pre-existing structure that the diff only touches indirectly — the change actually *reduces* the peak here, since the old `toPng` path materialized a base64 data URL of the same image before the blob existed.

**Recommendation:** No change now. If large decompositions become common, JSZip's streaming `generateInternalStream` API avoids holding the finished archive in memory a second time.

---

#### 9. Positive: `toBlob` removes a base64 round-trip from the export path

**Severity:** Informational (positive finding)
**Location:** `app/lib/utils/exportGraph.ts:17-36`
**Move:** (3) work moved to the *right* place — one canvas encode replaces encode → base64 → fetch → re-decode
**Classification:** Macro / Cold
**Confidence:** High — the fact-check (Claim 2) verifies the removal of the only `fetch(dataUrl)` call directly from the diff, and confirms no `fetch` of a `data:`/`blob:` URL remains anywhere.
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> `// Use toBlob (not toPng + fetch) so we don't need `data:` in CSP connect-src.` — `app/lib/utils/exportGraph.ts:6`

**Legibility-target:** a reader who reads this as a purely security-motivated change and misses that it is also strictly less work.

The removed path produced a PNG, base64-encoded it into a data URL (≈33% size inflation, and the whole string is a single JS string on the heap), passed that string through `fetch()`, and had the browser decode it back into a blob. The new path stops at `canvas.toBlob`. For the ~23 MB-class canvas of finding 7 the saved intermediate is on the order of several MB of string allocation plus a synchronous decode, per export. Deduplicating the two call sites into one `renderGraphPng` helper also means the pixel-ratio decision now lives in exactly one place. This is the strongest change in the diff on both axes.

**Recommendation:** None — keep. Worth citing as the pattern if another export path is added.

---

### What Looks Good

- **`toBlob` refactor (finding 9).** A security constraint and a performance improvement resolved by the same change, with the two call sites collapsed into one helper so the expensive knob (`pixelRatio`) has a single home.
- **Matcher excludes prefetches.** `missing: [{ key: "next-router-prefetch" }, { key: "purpose", value: "prefetch" }]` (`proxy.ts:65-69`) keeps the proxy off speculative requests. This is exactly the "don't do the work until it's needed" move, and the comment states the reason ("would otherwise burn a nonce on a request that may never paint").
- **API routes and `_next/static`/`_next/image` excluded.** The proxy is scoped to requests that can actually render nonce-tagged HTML, so the hottest asset paths never pay for it.
- **Export modules are code-split.** `html-to-image` and `jszip` load via dynamic `import()` on click (`GraphPanel.tsx:102`, `exportAll.ts` header comment) rather than in the initial bundle — the right call for a cold path.
- **Nonce cost is genuinely minimal.** 16 bytes from `crypto.getRandomValues` plus one base64 encode is the floor for what this feature needs; no hashing, no async, no allocation loop.

---

### Summary Table

| # | Finding | Severity | Class | Path | Location |
|---|---------|----------|-------|------|----------|
| 1 | `await headers()` disables static rendering app-wide | High | Macro | Hot | `app/layout.tsx:29` |
| 2 | Matcher does not exclude `/public` assets (latent multiplication, N=0 today) | Low | Macro | Hot | `proxy.ts:64` |
| 3 | Full request-header clone per navigation | Low | Micro | Hot | `proxy.ts:47` |
| 4 | `x-nonce` written every request, read by nothing | Low | Micro | Hot | `proxy.ts:49` |
| 7 | `pixelRatio: 2` → 4× canvas memory held with the blob | Low | Macro | Cold | `exportGraph.ts:18-21` |
| 5 | `buildCsp` rebuilds a near-constant array per request | Informational | Micro | Hot | `proxy.ts:21-35` |
| 6 | CSP string serialized on both request and response | Informational | Micro | Hot | `proxy.ts:50, 55` |
| 8 | Export-All holds the full zip in memory | Informational | Macro | Cold | `exportAll.ts:60-68` |
| 9 | Positive: `toBlob` removes base64 round-trip | Informational | Macro | Cold | `exportGraph.ts:17-36` |

No Critical findings. No unbounded work, no N+1, no loop over a collection, and no new synchronous I/O anywhere in the diff.

---

### Overall Assessment

The performance profile of this change is one real trade and a pile of negligible constants. The trade is finding 1: the strict-CSP feature buys per-request nonces at the cost of static rendering for the entire app, and because the product currently has exactly one page, "app-wide" and "the whole product" are the same set. That cost is intrinsic to nonce-based CSP — you cannot bake a per-request nonce into build-time HTML — so the recommendation is to document and bound it, not to reverse it. What is worth fixing is that the consequence is invisible at the call site: a single `await headers()` with a comment about nonces, and nothing that says "this turns off static generation for every route."

Everything else in the proxy is constant-factor work on a path already dominated by a React server render: a header clone, three short string writes, and 16 random bytes. The two genuinely actionable small items are the dead `x-nonce` write (finding 4) and the `/public` matcher gap (finding 2), both one-liners, both valuable more for what they prevent a future reader from believing than for the cycles they save. The export-path change is a clear improvement in both memory and step count, and the pre-existing `pixelRatio: 2` cost it inherits is the one thing in the cold path large enough to matter if it ever surfaces.

The dominant limitation of this review is that nothing could be measured: `node_modules` is absent and the repo carries no benchmark, Lighthouse config, or latency assertion, so every magnitude claim above is derived from code structure and arithmetic rather than observation. The single highest-value follow-up is not a code change — it is capturing the `next build` route table before and after finding 1 (the ○/ƒ static-vs-dynamic markers) so the trade has a number attached to it.

---

## Goal-Alignment Note

- **Answered:** All nine performance moves applied to the four changed files. Hot/cold temperature assigned per finding with the evidence for the classification (matcher scope for the proxy; dynamic `import()` + click-gating for the export path). Both fact-check foundations that carry performance weight were consumed rather than re-derived: `await headers()` → app-wide dynamic rendering (finding 1) and the `toPng`+`fetch` → `toBlob` moved-work change (finding 9), which is assessed as a net reduction in work, not merely a security fix. The dead `x-nonce` write and the dual header serialization are both reported as per-request costs. All severities reported down to Informational, as briefed for this measurement run.
- **Out of scope:** Security assessment of the CSP directives themselves (`security-reviewer`); the `proxy.test.ts` regex defect the fact-check rated Incorrect (test correctness, not performance); LLM streaming and API-route latency, untouched by this range; the pre-existing `pixelRatio: 2` choice as a product/quality decision. No fix loop was run — this is a pass-1 measurement report and no code was modified.
- **Escalate:** (a) **No baselines exist.** Every magnitude in this report is structural inference; `node_modules` is not installed and the repo has no benchmark or perf assertion. Finding 1's severity in particular rests on an unmeasured TTFB delta — capture the `next build` static-vs-dynamic route table and a TTFB before/after to confirm or downgrade it. (b) **Finding 2 is severity-discounted on a fact that can change.** The `/public` matcher gap is scored Low only because zero public assets are currently referenced; the first `<img src="/logo.png">` moves it toward the Macro×Hot cell (High) with no code change to the proxy. (c) The fact-check rates the Next-internal nonce-extraction step Medium confidence (it could not read `node_modules`); if that mechanism turns out to be wrong, finding 1's cost is being paid for nothing, which would change the recommendation from "bound it" to "remove it."
