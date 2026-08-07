# Performance Review — e3/csp-arm1 (strict CSP with per-request nonces), full-loop iteration 2

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-csp-arm1` — `proxy.ts`, `proxy.test.ts`, `app/lib/security/csp.ts`, `app/lib/security/csp.test.ts`, `app/layout.tsx`, `app/lib/utils/exportGraph.ts`
**Date:** 2026-08-06
**Commit:** f25d968
**Based on:** `code-fact-check-report.md` (merged k=3, same commit, same directory) — behavioral claims verified there are taken as foundation and not re-verified.

**Headline (hot-path gate):** **No Critical and no High findings.** Every hot-path item in this diff is Micro-class with a measured per-navigation cost in the low tens of microseconds; the one Macro-class item (`await headers()`) is a deliberate, already-waived architectural tradeoff whose *magnitude* — not existence — is the only thing this review adds.

---

## Data Flow and Hot Paths

Three distinct paths changed, with very different temperatures:

1. **`proxy.ts` — hot.** Runs once per matched request. The matcher admits every path except `api`, `_next/static`, `_next/image`, `favicon.ico`, and prefetch-tagged requests. Per invocation it: generates a nonce, builds a ~276-byte CSP string, clones the entire inbound `Headers` object, sets two headers on the clone, hands the clone to `NextResponse.next({ request })` (which re-encodes *every* forwarded header as `x-middleware-request-<name>` plus a joined key list — `node_modules/next/dist/server/web/spec-extension/response.js:34-39`), then sets the CSP a second time on the response. This is the "second header write per navigation" the brief flags.

2. **`app/layout.tsx` — hot, structural.** `await headers()` at line 42 opts the root layout out of static rendering, which propagates to the entire route tree. Every document request is now a server render; no prerendered HTML, no full route cache, no shared-cache storage of the document.

3. **`app/lib/utils/exportGraph.ts` — cold.** Both entry points are reached only through dynamic `import()` on a user click: `downloadGraphAsPng` from `GraphPanel.tsx:102-104`, `graphToPngBlob` from `exportAll.ts:62-65` (one call per "Export All"). Frequency is single-digit invocations per session at most. Data size, by contrast, is large: `pixelRatio: 2` over the React Flow viewport.

**Measurement note.** No production or staging measurements exist for this app — no perf docs, dashboards, or load tests in the repo. Where I could isolate a code path into a runnable micro-benchmark I did so and cite it below; everything else carries the speculative disclaimer. Micro-benchmarks were run in this worktree on **Node v20.20.2** and measure the Node-side cost only — they are not browser measurements and not end-to-end request latency.

---

## Findings

### F1 — `await headers()` makes the app's only route per-request-rendered and its document uncacheable by any shared cache

**Severity:** Medium
**Location:** `app/layout.tsx:27-42`
**Move:** Work moved to the wrong place (move 3); asymptotic/structural (move 9)
**Classification:** Macro (build-time work relocated to per-request) / Hot path (every document navigation)
**Confidence:** High (mechanism), Low (magnitude)
**Baseline:** no baseline available — flagged as speculative

`await headers()` bails the root layout out of static generation (fact-check Cluster 1, verified against Next's own `StaticGenBailoutError` text). Because it sits in the *root* layout, the opt-out is not scoped to one page — it removes the possibility of a prerendered document for the whole tree, and, being dynamic, the document is also excluded from Next's full route cache and from any CDN/shared-cache storage in front of it. The work that used to happen once at build time now happens once per navigation.

I am **not** contesting the tradeoff: per-request nonces and prerendered documents are mutually exclusive by construction, the brief waives this as load-bearing, and the alternative (hash-based CSP) is correctly named in the comment as the only escape. What I am flagging is that the comment asserts **"The cost here is nil ... there is nothing static to lose,"** and that is the one part of the rationale that does not hold. The route being a single `"use client"` page means there is little *component* work to re-do, but the shell HTML and the RSC payload for it would still have been built once and served from cache; now they are produced per request, and the document loses shared-cacheability entirely. "Nil" overstates it. The honest framing is "small and accepted," not "nil."

**Recommendation:** Keep the opt-out. Correct the comment from "The cost here is nil" to something falsifiable and accurate — e.g. "The cost is one SSR shell render per navigation instead of a cached prerender, and the document is no longer shared-cacheable; accepted because nonces require it." If you want the claim to be measurable rather than argued, capture one number before merging: `npm run build` output for the route (static vs dynamic marker) plus a single TTFB sample against a production build, so a future reader can check the "small" against something.
**Legibility-target:** the phrase "The cost here is nil" at `app/layout.tsx:38` — an unmeasured absolute claim about performance sitting in a comment. Replace with a bounded, checkable statement.

---

### F2 — Forwarding request headers re-encodes the entire inbound header set on every navigation (~12 µs/request measured)

**Severity:** Low
**Location:** `proxy.ts:25-36`
**Move:** Hidden multiplication (move 1); serialization tax (move 6)
**Classification:** Micro (per-operation clone + re-encode overhead) / Hot path (every matched request)
**Confidence:** High
**Baseline:** ~2.80 µs per `new Headers(request.headers)` + two `.set` calls, and ~8.88 µs for Next's `x-middleware-request-*` re-encode — micro-benchmark run 2026-08-06 in this worktree on Node v20.20.2, 100,000 iterations over a synthetic 13-header browser navigation request (512-byte cookie). Total ~11.7 µs/request. Not a browser or production measurement.

`NextResponse.next({ request: { headers } })` does not forward the two headers that changed — it iterates the whole cloned `Headers` object and writes each entry back onto the response as `x-middleware-request-<name>`, then joins every key name into `x-middleware-override-headers` (`response.js:34-39`, fact-check Cluster 16). So the marginal cost of the new request-header write is not one `.set`; it is a full clone plus a full re-serialization of the inbound header set, ~1.7 KB of internal header bytes for the synthetic request above, growing linearly with cookie size.

This is worth stating precisely because full-1's equivalent finding read the clone as *dead* work done only to carry an unread `x-nonce`. That reading no longer holds: `requestHeaders.set("Content-Security-Policy", csp)` is load-bearing — Next parses the nonce out of the request header (fact-check Cluster 3), and deleting the line fails 2 of `proxy.test.ts`'s 5 tests (Cluster 17). The clone is now the price of a working CSP, not waste. At ~12 µs against an SSR render measured in milliseconds, it is noise.

**Recommendation:** No change. Do not "optimize" this by dropping the request-header write — that breaks hydration. Recorded so a future reader does not re-litigate it as dead work.

---

### F3 — `x-nonce` is forwarded on every request and read by nothing

**Severity:** Informational
**Location:** `proxy.ts:27-31`
**Move:** Hidden multiplication (move 1)
**Classification:** Micro (one extra header set + ~48 forwarded bytes) / Hot path (every matched request)
**Confidence:** High
**Baseline:** ~0.3 µs marginal per request and ~70 bytes of forwarded internal header (48-byte nonce + name), derived from the same 2026-08-06 Node v20.20.2 micro-benchmark as F2 (the two-`.set` variant vs. the clone alone). Not a browser or production measurement.

Nothing in the repo reads `x-nonce` (fact-check Cluster 19: repo-wide grep finds no reader outside the writer, the tests, and the layout comment declining to read it). Its cost was structurally significant when it was the *only* reason to clone the header set; now that the CSP request header requires the clone regardless, `x-nonce`'s marginal cost is one `.set` and ~70 bytes. That is not a performance concern at any plausible traffic level.

**Recommendation:** Keep it or drop it on API-design grounds, not performance grounds. If kept, the existing comment already explains why; no perf action.
**Legibility-target:** none — the comment at `proxy.ts:27-31` is accurate and sufficient.

---

### F4 — `buildCsp` reconstructs nine constant directives and re-reads `process.env.NODE_ENV` per request

**Severity:** Informational
**Location:** `app/lib/security/csp.ts:41-58`; called from `proxy.ts:16`
**Move:** Work in the wrong place (move 3)
**Classification:** Micro (array literal + join, constant size) / Hot path (every matched request)
**Confidence:** High
**Baseline:** ~0.18 µs per 9-element `join("; ")` producing a 276-byte string; nonce generation `Buffer.from(crypto.randomUUID()).toString("base64")` ~0.57 µs — micro-benchmark run 2026-08-06 in this worktree on Node v20.20.2, 200,000 iterations each. Not a browser or production measurement.

Eight of the nine directives are compile-time constants; only `script-src` varies (by nonce, and by an environment value that cannot change within a process lifetime). A precomputed prefix/suffix pair would make the per-request work a single template concatenation. Measured, the whole build is ~0.18 µs and the CSP header is 276 bytes — roughly 1.5% of the ~12 µs the header forwarding in F2 costs, and invisible next to a render. The current form is also the more testable one (`nodeEnv` as a parameter is what makes the fail-closed sweep test possible without mutating global state — fact-check Cluster 10), which is worth more than 0.18 µs.

One measured counterpoint worth recording so it is not "fixed" later: switching the nonce to the frequently-recommended `randomBytes(16).toString("base64")` is **5× slower** here (2.86 µs vs 0.57 µs on the same benchmark), even though it produces a shorter 24-char nonce instead of 48. If the 24 extra header bytes ever matter, that is the tradeoff; today neither does.

**Recommendation:** No change. Do not hoist the directive array to module scope for performance — the parameterized form is load-bearing for the tests and the saving is sub-microsecond.

---

### F5 — Matcher admits `public/` assets and non-`static` `_next` paths, each paying the full nonce + clone + forward cost

**Severity:** Informational
**Location:** `proxy.ts:40-52`
**Move:** Hidden multiplication (move 1)
**Classification:** Micro (per-request overhead on requests that never render a document) / Hot path (asset and RSC request volume exceeds navigation volume)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative (no request-mix data for this app; the per-request cost is the ~12 µs measured in F2, but the multiplier — how many non-document requests hit the matcher — is unknown)

The negative lookahead excludes `api`, `_next/static`, `_next/image`, and `favicon.ico` (fact-check Cluster 20). It does not exclude files served from `public/` (`file.svg`, `globe.svg`, `next.svg`, `vercel.svg`, `window.svg`), nor `_next` paths other than `static`/`image` — notably dev-server HMR traffic. Each such request generates a nonce, clones and re-encodes the header set, and attaches a 276-byte CSP to a response that contains no scripts to nonce. The prefetch `missing` conditions correctly spare prefetches, which is the larger win and is already handled.

Today this is genuinely negligible: five unused default SVGs. It is worth recording only because the cost scales with whatever gets added to `public/` later, and nothing in the matcher will flag that.

**Recommendation:** Optional — extend the lookahead to cover static file extensions (e.g. `.*\\.(?:svg|png|jpg|webp|ico|txt|xml)$`) if `public/` ever grows beyond the Next scaffold defaults. Not worth a change now.
**Legibility-target:** the comment at `proxy.ts:41-43` says "Apply CSP to page navigations only," which is slightly stronger than what the matcher does — `public/` assets and `_next/data`/HMR paths also match. Softening it to "page navigations and anything else not explicitly excluded below" would keep a future reader from trusting the narrower claim.

---

### F6 — `pixelRatio: 2` allocates a 4× backing store; unchanged behavior, but now the only sizing knob in the export path

**Severity:** Informational
**Location:** `app/lib/utils/exportGraph.ts:24-33`
**Move:** Memory lifecycle (move 4); what's the size of N (move 2)
**Classification:** Macro (allocation scales with viewport area) / Cold path (user-initiated export, single-digit invocations per session)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative (no measurement of actual graph viewport dimensions or exported PNG size in this repo; "verify data size" against a real export)

`pixelRatio: 2` quadruples the canvas backing store relative to the CSS-pixel viewport. For a 1600×1000 CSS-px viewport that is a 3200×2000 canvas ≈ 25.6 MB of RGBA held live while `canvas.toBlob` encodes, on top of the SVG/foreignObject intermediate `toCanvas` builds. This value is unchanged from the pre-diff code — it moved into the new `renderGraphToBlob` helper — so it is not a regression, and on a cold, user-initiated path a transient 25 MB is acceptable. It lands here as Informational under the Micro/Macro × path matrix (Macro × Cold → Medium by default, adjusted down because the allocation is transient, the invocation is explicitly user-triggered, and the behavior predates the diff).

The consolidation into one helper is itself the useful change: `pixelRatio` now has exactly one definition site instead of two, so if export ever OOMs on a large graph there is one number to turn.

**Recommendation:** None now. If large-graph exports are ever reported as failing or janky, measure the viewport dimensions first — `pixelRatio` is the knob, and it is now in one place.

---

### F7 — `canvasToBlob`'s legacy fallback is a byte-at-a-time decode loop over the whole PNG

**Severity:** Informational
**Location:** `app/lib/utils/exportGraph.ts:25` → `node_modules/html-to-image/lib/util.js:186-198`
**Move:** Asymptotic behavior / graceful degradation (move 9); serialization tax (move 6)
**Classification:** Macro (O(n) per-byte JS loop over multi-MB payload) / Cold path (export only), and unreachable on any browser this app supports
**Confidence:** High (the code path exists and is what it looks like), Low (that it is ever taken)
**Baseline:** no baseline available — flagged as speculative (the branch requires a browser without `canvas.toBlob`; none were available to measure)

`toBlob` takes `canvas.toBlob` when present. When absent it falls back to `toDataURL` → `atob` → a `for` loop writing `charCodeAt(i)` into a `Uint8Array` one byte at a time — i.e. it reconstructs the exact base64 round-trip this commit set out to remove, in the slowest possible form, over a multi-megabyte payload. `canvas.toBlob` has been universally supported for years, so this is a latent cliff rather than a live cost, and it is inside a dependency, not the diff.

Recording it because it slightly qualifies the diff's own comment: the fast path is chosen at runtime, not guaranteed by the import.

**Recommendation:** No action. Do not add a manual fallback — the dependency's is adequate and the branch is dead in practice.
**Legibility-target:** the comment at `app/lib/utils/exportGraph.ts:17-18` states `toBlob` "goes canvas → `canvas.toBlob()`, staying entirely within the DOM." The fact-check (Cluster 13) already docks "entirely within the DOM" as over-broad because the shared `toCanvas` pipeline can `fetch()` webfonts/images. The same sentence also reads as unconditional about `canvas.toBlob()` when it is a runtime feature check. A single tighter sentence fixes both: "goes canvas → `canvas.toBlob()` where available, so the final decode stays in-DOM."

---

## What Looks Good

**The `toPng` + `fetch(dataUrl)` → `toBlob` swap removes real work, not just a CSP violation.** This is the standout item in the diff and its performance benefit is larger than the commit message claims. The old path was `toCanvas` → `canvas.toDataURL()` (base64-encode the entire PNG into a JS string) → `fetch(dataUrl)` (parse the URL, base64-decode it back) → `.blob()`. The new path is `toCanvas` → `canvas.toBlob()` (binary out of the canvas directly). Measured on a 3 MB payload, Node v20.20.2, this worktree, 2026-08-06: base64 encode **2.0 ms**, base64 decode **1.7 ms**, `fetch(data:…)` + `arrayBuffer()` **161.6 ms**, plus a transient 4.2 M-character intermediate string (~4 MB as a one-byte string, 8 MB if promoted). The new path pays none of it. The 161.6 ms figure is Node's undici and is **not** a browser number — browsers handle `data:` URLs on a different path and would likely be much faster — but the encode/decode and the multi-megabyte transient string are inherent to `toDataURL` in any runtime. The change is strictly less work on every axis, and the CSP fix comes free with it.

**The shared `renderGraphToBlob` helper** removes a duplicated options literal and gives `pixelRatio` a single definition site (F6), while adding a null check that throws instead of downloading a zero-byte file (fact-check Cluster 14). Deduplication that also collapses a tuning knob to one place is the right kind.

**Code-splitting is intact.** Both consumption paths remain behind dynamic `import()` (`GraphPanel.tsx:102`, `page.tsx:576`; `exportAll.ts`'s static import is itself only dynamically loaded — fact-check Cluster 12). `html-to-image` still stays out of the initial bundle, so the export changes cost nothing to users who never export.

**The matcher's prefetch exclusion is the right optimization to have made.** Router prefetches are the highest-volume class of requests that would otherwise pay nonce generation for a document that may never paint. Excluding them (rather than the `public/` long tail in F5) targets the volume that actually exists.

**`nodeEnv` as a parameter rather than an ambient read** costs ~0 per request and buys a test that sweeps six environment values for fail-closed behavior. Testability bought at no measurable runtime price.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `await headers()` → per-request render, document uncacheable; comment claims cost is "nil" | Medium | `app/layout.tsx:27-42` | High (mechanism) / Low (magnitude) |
| F2 | Request-header forwarding re-encodes whole header set per navigation (~12 µs measured) | Low | `proxy.ts:25-36` | High |
| F3 | `x-nonce` forwarded, read by nothing (~0.3 µs, ~70 B marginal) | Informational | `proxy.ts:27-31` | High |
| F4 | `buildCsp` rebuilds 9 constant directives + reads `NODE_ENV` per request (~0.18 µs) | Informational | `app/lib/security/csp.ts:41-58` | High |
| F5 | Matcher admits `public/` assets and non-`static` `_next` paths | Informational | `proxy.ts:40-52` | Medium |
| F6 | `pixelRatio: 2` → 4× canvas backing store (unchanged; now single-sited) | Informational | `app/lib/utils/exportGraph.ts:24-33` | Medium |
| F7 | `canvasToBlob` legacy fallback = per-byte decode loop (dead in practice) | Informational | `exportGraph.ts:25` → `util.js:186-198` | High / Low |

---

## Overall Assessment

The performance posture of this change is good, and it improved between iterations. **Nothing Critical or High exists in this diff.** The hot path added by `proxy.ts` costs a measured ~12 µs per matched request, dominated not by the diff's own code but by Next's `x-middleware-request-*` re-encoding of the forwarded header set — a cost that is now unavoidable, because the request-header CSP write is what makes the nonce reach the renderer at all. That is the one substantive correction this iteration makes to the previous review's framing: the header clone reads as dead work only if you believe the request header is decorative, and it is not.

The single Macro-class item is `await headers()`, and it is a correctly-reasoned, correctly-waived architectural tradeoff — nonces and prerendering are mutually exclusive, and the comment already names hash-based CSP as the only exit. My one objection is to a sentence, not a design: "The cost here is nil" is an unmeasured absolute in a comment, and it is wrong in kind — the document loses prerendering and shared-cacheability, which is small for a single client route but is not nothing. Fixing that sentence is the highest-value action in this report, and it costs one line.

The export change is the clear win. Swapping `toPng` + `fetch(dataUrl)` for `toBlob` deletes a base64 encode, a base64 decode, a fetch, and a multi-megabyte transient string from a path that handles multi-megabyte images — the CSP compliance was the motivation, but the performance improvement stands on its own and is understated by the commit's framing.

Nothing here needs a fix before merging. **What would need measurement:** F1's magnitude is the only finding where the answer could plausibly change a decision, and it needs exactly two numbers — the build output's static/dynamic marker for the route, and one TTFB sample against a production build. Everything else is either measured (F2, F3, F4) or below the threshold where measuring would change anything (F5–F7).

---

## Goal-Alignment Note

- **Answered:** All four items in the brief. (1) The request-header CSP write — the second header write per navigation — is characterized with a measured cost (F2, ~12 µs/request including Next's full-header-set re-encode) and explicitly re-framed against the earlier "dead work" reading, since the write is now load-bearing for nonce delivery. (2) `exportGraph`'s `toBlob` switch is assessed against **both** comparison points requested: vs. the original `toPng` + `fetch` path (measured: 2.0 ms encode + 161.6 ms Node `fetch(data:)` + 1.7 ms decode + ~4 MB transient string, all removed) and vs. a manual decode path (F7 — html-to-image's own `atob` + per-byte-loop fallback, which is that path, and which `toBlob` skips whenever `canvas.toBlob` exists; net: the new code has **no** base64 decode step at all, on either comparison). (3) Per-request `buildCsp` invocation from `proxy.ts` is measured and found negligible, with a counter-recommendation against the obvious "optimization" (F4). (4) `await headers()` is reported at Medium as a waived-but-real structural cost, with the waiver honored and the objection scoped to the comment's "cost is nil" claim (F1). Severity/hot-path calibration is stated per finding via **Classification:**; the hot-path gate is applied and reported up front — no Critical, no High.
- **Out of scope:** No production, staging, or browser measurements exist for this app, so F1, F5, and F6 carry the speculative disclaimer; the Node micro-benchmarks (F2, F3, F4, and the What-Looks-Good export numbers) measure Node-side CPU only and are labeled as such — they are not end-to-end request latency and not browser behavior. Security correctness of the CSP directives, API/interface design of `buildCsp`'s signature, and test coverage adequacy belong to the sibling critics. Runtime CSP verification against a production build was unavailable in the sandbox, per the commit's own note.
- **Escalate:** Nothing at Critical or High. One item merits a decision rather than a code change: the `app/layout.tsx:38` claim **"The cost here is nil"** is an unmeasured absolute performance assertion in a comment, and it is the only place in this diff where the documented rationale overstates the analysis. Recommend correcting the wording (one line) or, if the team prefers to keep the claim, backing it with the two numbers named in F1. Separately, carried forward from the fact-check: the full-1 security review's "independently confirmed" OpenAlex `connect-src` claim does **not** hold on this state and must not be reused in any full-2 synthesis — this review makes no use of it.
