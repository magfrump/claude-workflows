# Performance Review — strict-CSP feature, iteration-3 (final pass)

**Commit:** 2544a19
**Range:** `d86d2dc..HEAD` (2544a19) in `/workspace/runs/review-arms/e3-loops/wt-csp-arm2`, branch `e3/csp-arm2`
**Diff size:** 5 files, +266/−5 (`app/layout.tsx`, `app/lib/utils/exportGraph.ts` + new test, new `proxy.ts` + new `proxy.test.ts`)
**Date:** 2026-08-06
**Based on:** prior performance review at `full-2/performance-review.md` (Commit 99e1229) and the iteration-2 rubric at `full-2/code-review-rubric.md` (advisory). Measurements below were re-taken first-hand against this commit; prior numbers are cited only where noted.

> ⚠️ **No code fact-check report provided for this pass.** Comment and docstring claims in the range
> have not been independently re-verified here. The iteration-2 merged fact-check (k=3) covered them
> at 99e1229; the only delta since is comment text, which this review reads but does not fact-check.

## Delta since the last performance pass

`git diff 99e1229..HEAD` touches `proxy.ts` only, and every changed line is a comment. Filtering the
delta to non-comment lines yields the empty set:

```
$ git diff 99e1229..HEAD -- . | grep -E '^[+-]' | grep -vE '^[+-]{3}' | grep -vE '^[+-]\s*(\*|//)'
(no output)
```

**No executable statement in the range changed since the prior pass.** Every performance finding
below is therefore carried forward at the same mechanism, with line anchors re-resolved against
2544a19 (the comment edits shifted `proxy.ts` by +4 lines below the docblock) and with the two
microbenchmarks re-run rather than inherited.

## Data flow and hot paths

Two distinct paths are affected, and they have opposite temperatures.

**Hot — every page navigation.** `proxy.ts` runs on every request matching its `config.matcher`.
Per request it mints a nonce (`crypto.randomUUID()` → base64), rebuilds a 9-directive policy string,
clones the inbound request headers, sets two of them, and sets one response header. No I/O, no
`await`, no allocation proportional to request body. It precedes a full per-request SSR of the app
(`export const dynamic = "force-dynamic"` in the root layout), which is the dominant cost in the
range by three orders of magnitude.

**Cold — user-initiated export clicks.** `dataUrlToBlob` in `app/lib/utils/exportGraph.ts` decodes a
`toPng` data URL to a Blob on the main thread. Two call sites: `downloadGraphAsPng` (`:54`, reached
from `GraphPanel.tsx:102-104` behind a dynamic import) and `graphToPngBlob` (`:65`, reached from
`exportAll.ts:64`). One invocation per click; no loop, no repetition, no scaling with user count.

Data sizes: the decode is linear in PNG byte count, and both call sites render at `pixelRatio: 2`,
so the image is 4× the on-screen pixel count — a large proof graph on a high-DPI viewport lands in
the multi-MiB range. The proxy's work is O(1) in request size (the header clone is bounded by the
inbound header count, ~6–15 in practice).

## Measurement environment

Both microbenchmarks were re-run in this worktree at 2544a19, `node v20.20.2`:

- **Proxy per-request microbenchmark** — `$TMPDIR/p3.mjs`, replicating `proxy()`'s per-request work
  verbatim (nonce, `buildCsp` array + `join`, `new Headers(request.headers)` clone over a 6-header
  realistic navigation request, two `.set()` calls). 20,000 warm-up iterations, then N = 200,000
  timed.
- **Decode microbenchmark** — `$TMPDIR/b3.mjs`, replicating `dataUrlToBlob` verbatim over synthetic
  base64 payloads at 0.5 / 1 / 4 / 16 MiB. One warm-up, one timed run per size.

**What still could not be measured.** `npx next build` remains blocked in this sandbox — re-attempted
at 2544a19 and it fails identically: `next/font: error: Failed to fetch 'EB Garamond' from Google
Fonts` and the same for `Geist Mono`, both traced to `app/layout.tsx`, aborting before the route
table is emitted. So the `○`-static-vs-`ƒ`-dynamic route markers and any TTFB delta between
`d86d2dc` and HEAD are still unavailable, and F1's magnitude is still flagged speculative rather
than given an invented number.

---

## Findings

#### F1 — `force-dynamic` in the root layout re-renders the entire component tree on every page request

**Severity:** High
**Location:** `app/layout.tsx:26` (`export const dynamic = "force-dynamic";`)
**Move:** Work moved to the wrong place (build time → request time); size of N
**Classification:** Macro (rendering-mode change; cost grows with the component tree) / Hot path (executes on every page navigation)
**Confidence:** High that the rendering mode is per-request; Low on magnitude
**Baseline:** no baseline available — flagged as speculative
**Evidence:**

```
app/layout.tsx:26
export const dynamic = "force-dynamic";
```

```
$ rg -n "export const (dynamic|revalidate|runtime|fetchCache)" app/
app/layout.tsx:26:export const dynamic = "force-dynamic";
```

```
$ timeout 240 npx next build
Error: Turbopack build failed with 2 errors:
next/font: error: Failed to fetch `EB Garamond` from Google Fonts.
next/font: error: Failed to fetch `Geist Mono` from Google Fonts.
  Import trace: ... app/layout.tsx
```

**Legibility-target:** A maintainer should be able to see from the route table alone that every page
under `app/` is `ƒ (Dynamic)` and that no HTML is reusable between visitors. The declared export
makes that legible in the module's public surface — a real improvement over the discarded
`await headers()` it replaced — and 2544a19's comment block above it now states the mechanism
correctly. What is still not written down anywhere in the repo is the *cost* that declaration
commits to.

This is the root layout, so the export cascades to every route segment beneath it. Today that is one
page route, but `app/page.tsx` is `"use client"` and pulls in the whole workspace: 63 `.tsx` files
under `app/`. The scaling factor is **1× per request instead of 1× per deploy** — the SSR of that
tree, font-CSS resolution, and RSC payload serialization all move from a single build-time execution
to once per navigation, and the Full Route Cache (plus any CDN HTML caching in front of it) is
disabled app-wide. The multiplier is total page views, not a constant.

Two things hold this at High rather than Critical: the per-request work is bounded by a fixed
component tree (nothing scales with user data, so there is no unbounded-consumption or DoS path),
and relative to `d90d6bb` the change is rendering-mode-**neutral** — the `await headers()` it
replaced already forced per-request rendering. It grades High only against the review base
`d86d2dc`, where the app genuinely moves from prerendered to per-request.

**Recommendation:** No code change. This is the accepted cost of per-request nonces and is now
correctly declared; the iteration-2 rubric recorded it as amber A9 on exactly those grounds, and this
pass does not dispute that disposition — the High here is the critic's native severity for a
Macro × Hot rendering-mode change, not a demand to block. What is owed is the number: capture
`next build` route markers and a p50 TTFB for `/` at `d86d2dc` versus HEAD in a networked
environment and record the delta in the CSP decision record, so this stops being re-litigated by
every future reviewer who notices `force-dynamic` in a root layout.

---

#### F2 — `force-dynamic` is strictly broader than the `await headers()` it replaced, and forecloses partial prerendering app-wide

**Severity:** Medium
**Location:** `app/layout.tsx:21-26`; compare `git show d90d6bb:app/layout.tsx` (`await headers();` inside an `async` `RootLayout`)
**Move:** Work moved to the wrong place — a per-segment, dynamic-API-scoped opt-out became a route-segment config flag
**Classification:** Macro (render-mode capability, not per-call overhead) / Cold path (build/render-mode configuration, not executed work)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Evidence:**

```
$ git show d90d6bb:app/layout.tsx
export default async function RootLayout({
  ...
  await headers();
```

```
$ rg -n '"next"' package.json
23:    "next": "16.2.4",
```

```
app/layout.tsx:21-26  (the comment block, as of 2544a19 — unchanged by this commit)
// Every route under this layout must render per request: a statically
// prerendered HTML document would bake in one nonce ...
export const dynamic = "force-dynamic";
```

**Legibility-target:** A reader comparing the two spellings should be able to tell they are not
interchangeable. The comment explains *why per-request rendering is required* — which is correct and
was the point of R4 — but it still says nothing about `force-dynamic` being a strictly stronger
opt-out than the dynamic API it replaced. Iteration 3 edited comments in `proxy.ts` and left this one
untouched, so the gap the prior pass flagged is unchanged.

`await headers()` is a dynamic API: it marks its own segment dynamic and, under PPR, yields a
dynamic hole while the surrounding shell still prerenders. `export const dynamic = "force-dynamic"`
opts the whole subtree out of static generation and PPR unconditionally and applies no-store fetch
semantics beneath it. On Next 16.2.4 with an empty `next.config.ts` (PPR not enabled) the two are
behaviourally equivalent today, which is why this is Medium. The cost is optionality: if PPR is later
enabled to recover F1's static shell while keeping a per-request nonce hole, this line silently
defeats it, and the failure mode — "we turned on PPR and nothing got faster" — is hard to attribute
back here. Scaling factor: none today; the loss is the entire prerenderable fraction of the shell
under any future PPR adoption.

**Recommendation:** Keep `force-dynamic`. Add one sentence to the existing comment at
`app/layout.tsx:21-25` recording that it is deliberately broader than a dynamic-API opt-out and is
the line to revisit under PPR. This is a one-line comment edit of exactly the kind 2544a19 already
made in the sibling file, so it is cheap to land in the same class of change.

---

#### F3 — base64 decode runs as a synchronous main-thread per-byte loop instead of the browser's native fetch decode

**Severity:** Medium
**Location:** `app/lib/utils/exportGraph.ts:38-43` (the `atob` + `charCodeAt` loop), consumed at `:54` and `:65`
**Move:** Work moved to the wrong place (off-thread native decode → synchronous interpreted loop on the main thread)
**Classification:** Macro (blocking duration is proportional to image size rather than off the critical thread) / Cold path (both call sites are one-per-click, user-initiated exports)
**Confidence:** High
**Baseline:** measured — **5.7 ms (0.5 MiB), 8.1 ms (1 MiB), 21.0 ms (4 MiB), 82.8 ms (16 MiB)** for the full `dataUrlToBlob` base64 branch; `node v20.20.2`, `$TMPDIR/b3.mjs` re-run against 2544a19, one warm-up + one timed run per size. (The prior pass measured 3.5 / 13.6 / 61.6 ms for 1 / 4 / 16 MiB on the same machine; the code is byte-identical, so the ~1.3× spread is run-to-run variance, not a regression. Both runs agree on the shape: linear, single-digit ms per MiB.)
**Evidence:**

```
app/lib/utils/exportGraph.ts:38-43
  const binary = atob(payload);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return new Blob([bytes], { type: mediaType });
```

Replaced (from the range diff):

```
-  const res = await fetch(dataUrl);
-  const blob = await res.blob();
-  triggerDownload(blob, filename);
+  triggerDownload(dataUrlToBlob(dataUrl), filename);
```

Benchmark output at 2544a19:

```
0.5 MiB | b64 chars 699052   | decode 5.7 ms  | blob.size 524288   | type image/png
1 MiB   | b64 chars 1398104  | decode 8.1 ms  | blob.size 1048576  | type image/png
4 MiB   | b64 chars 5592408  | decode 21.0 ms | blob.size 4194304  | type image/png
16 MiB  | b64 chars 22369624 | decode 82.8 ms | blob.size 16777216 | type image/png
```

**Legibility-target:** A reader should be able to see that the decode is O(bytes) *on the main
thread*, and that the `await` disappearing from the call sites is not free — the old
`await fetch(dataUrl)` yielded to the event loop and decoded in browser-native code, whereas
`dataUrlToBlob` is a synchronous call inside an `async` function and holds the thread for its whole
duration. The docstring at `:16-22` explains why the decode exists in-process but says nothing about
it being synchronous, so this remains the one property a reader has to derive.

Scaling factor is linear at roughly **5 ms per MiB of decoded PNG** on this run. Both call sites
render at `pixelRatio: 2`, so a large decomposition graph on a high-DPI viewport lands in the
multi-MiB range — a ~10–80 ms synchronous main-thread stall during an interaction where `GraphPanel`
has already set `exporting` state and the UI is expected to stay responsive. It is genuinely cold
(one click, no loop), which is what holds it at Medium.

The constraint is real and correctly resolved: `connect-src 'self'` refuses `data:`, so
`fetch(dataUrl)` is unavailable, and widening the directive to save tens of milliseconds on a click
would be a bad trade. The finding is about *where* the decode runs, not whether it should exist.

**Recommendation:** No action until export jank is actually reported. If it is, the drop-in is
`Uint8Array.fromBase64(payload)` with the current loop as fallback, which moves the per-byte work
back into native code and resolves F4 for free. Measure a real export with the Performance panel
before spending effort — the benchmark here is Node, not a browser main thread under React load.

---

#### F4 — `dataUrlToBlob` holds roughly twice the peak transient memory of the fetch path it replaced

**Severity:** Informational
**Location:** `app/lib/utils/exportGraph.ts:38-43`
**Move:** Memory lifecycle — an extra full-size decoded copy is live simultaneously with the source
**Classification:** Micro (constant-factor allocation overhead per call) / Cold path (once per export click)
**Confidence:** Medium (allocation counts are read off the code; V8's string representation for the `atob` result is inferred, not measured)
**Baseline:** measured, partial — `blob.size` equals the input byte count exactly at every size tested (524288 / 1048576 / 4194304 / 16777216 in the F3 run at 2544a19), confirming no hidden re-encoding or double-buffering; peak RSS was not instrumented
**Evidence:**

```
app/lib/utils/exportGraph.ts:38-43   (binary string, then bytes array, then Blob)
  const binary = atob(payload);
  const bytes = new Uint8Array(binary.length);
  ...
  return new Blob([bytes], { type: mediaType });
```

**Legibility-target:** A reader should be able to count the simultaneously-live copies of the image.
There are four: the caller's `dataUrl` string (~1.33N, still referenced by the caller's local),
`binary` (~N), `bytes` (N), and the Blob's own copy (N) — peak ≈ 4.33N. The old path held the
`dataUrl` string plus the fetch-produced Blob, ≈ 2.33N.

Scaling factor is a constant **~1.9× peak transient allocation**, linear in image size: ~17 MiB
transient instead of ~9 MiB for a 4 MiB PNG. In `exportAll.ts:64` the Blob is then handed to JSZip,
which reads it again during `generateAsync`, stacking another copy — pre-existing behaviour,
unchanged by this range. At realistic graph-screenshot sizes none of this approaches a tab's memory
ceiling, which is why it stays Informational.

**Recommendation:** No action. Resolves as a side effect if F3's recommendation is ever taken.

---

#### F5 — per-request proxy work is real but three orders of magnitude below the render it precedes

**Severity:** Low
**Location:** `proxy.ts:20-34` (`buildCsp` rebuilds a 9-element array and re-joins 8 constant directives per call), `proxy.ts:40` (nonce), `proxy.ts:49` (`new Headers(request.headers)` clone)
**Move:** Hidden multiplication — a constant-cost block executed once per navigation
**Classification:** Micro (fixed per-call overhead, no data-dependent growth) / Hot path (every page navigation)
**Confidence:** High
**Baseline:** measured — **2.67 µs per request** for the combined nonce + `buildCsp` + `Headers` clone + two `set()` calls; `node v20.20.2`, `$TMPDIR/p3.mjs` re-run against 2544a19, 20,000 warm-up + N = 200,000 timed iterations against a 6-header navigation request. (Prior pass: 3.3 µs on the same machine for the same code — same order, run-to-run variance.)
**Evidence:**

```
proxy.ts:40
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
proxy.ts:49
  const requestHeaders = new Headers(request.headers);
```

```
per-request proxy work: 2.67 us (N=200000)
```

**Legibility-target:** A reader should be able to conclude that the proxy is not the thing to
optimize. It is the only per-request code the range adds on the hot path, so it deserves a number —
and the number settles it. 2544a19's comment rewrite at `:38-39` improves this: the runtime the cost
is paid in (Node.js, not Edge) is now stated correctly, so a reader benchmarking this path knows
which runtime's cost model applies.

Scaling factor: 2.67 µs × navigations. Against F1's per-request full-tree SSR — conservatively in the
single-to-tens-of-milliseconds range — this is a **~0.03% or smaller share** of the request. Eight of
the nine directives are compile-time constants that could be hoisted to a module-level prefix string,
and the `Headers` clone could in principle be avoided; neither is worth doing.

**Recommendation:** No action. Hoisting the constant directives is a legitimate small cleanup if
someone is already editing `buildCsp`, but it must not be sold as a performance fix — the measured
ceiling on the win is under 3 µs per request.

---

#### F6 — the nonce is a 48-character base64 of a UUID *string*, inflating the CSP header ~10% for no entropy gain

**Severity:** Low
**Location:** `proxy.ts:40`
**Move:** Serialization tax — per-response bytes on the wire
**Classification:** Micro (24 constant bytes per response) / Hot path (every navigation response)
**Confidence:** High
**Baseline:** measured — CSP is **276 bytes** with the current nonce vs **252 bytes** with `crypto.getRandomValues(new Uint8Array(16))`; nonce length 48 chars vs 24 chars; `node v20.20.2`, `$TMPDIR/p3.mjs` re-run against 2544a19 (identical to the prior pass's numbers)
**Evidence:**

```
proxy.ts:40
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

```
nonce len 48; csp bytes 276
alt nonce len 24; csp bytes 252
```

`crypto.randomUUID()` returns the 36-character *hyphenated text* form of 122 bits of entropy;
base64-ing that text yields 48 characters carrying the same 122 bits. Encoding 16 raw random bytes
instead gives 128 bits in 24 characters.

**Legibility-target:** A reader should be able to see that the nonce's length is an artifact of
double-encoding a string, not a chosen security parameter — the current spelling reads as if 48
characters were deliberate. Note that 2544a19's comment rewrite makes the alternative slightly more
attractive on its own terms: now that the Node.js runtime is correctly named, `Buffer` is no longer
justified by a (wrong) Edge-runtime claim, and `crypto.getRandomValues` would be runtime-agnostic.

Scaling factor: **24 bytes per response × navigations**, uncompressible either way. Because the nonce
is fresh per request the whole `Content-Security-Policy` header is a literal on every response —
HPACK/QPACK cannot index it, so all 276 bytes are paid each time. The internal
`x-middleware-request-content-security-policy` forwarding encoding is consumed by the Next server and
never reaches the wire, so the response header is the only per-navigation cost. 24 bytes is noise on
an HTML response; this is Low on the strength of being on the hot path at all, not on magnitude.

**Recommendation:** Optional one-line change to `crypto.getRandomValues(new Uint8Array(16))` —
shorter header, more entropy, and it drops the `Buffer` dependency. Not worth a dedicated commit.

---

#### F7 — the matcher runs the proxy on `public/` assets and error pages, which its own comment says it does not

**Severity:** Low
**Location:** `proxy.ts:62-75` (`config.matcher`), comment at `:63-65` ("Apply CSP to page navigations only")
**Move:** Size of N — the request population the proxy actually sees is larger than the comment's population
**Classification:** Micro (2.67 µs of wasted work per excess request) / Hot path (request routing)
**Confidence:** High
**Baseline:** measured — 2.67 µs per excess request (F5's re-run benchmark at 2544a19), times the excess population
**Evidence:**

```
proxy.ts:68
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

```
$ ls public/
file.svg  globe.svg  next.svg  vercel.svg  window.svg
```

The negative lookahead excludes `api`, `_next/static`, `_next/image`, and `favicon.ico`. It does not
exclude `public/` assets (5 SVGs served from the app root), `robots.txt`, `sitemap.xml`, or 404
paths — each of those matches, allocates a nonce, builds a CSP, and clones the request headers for a
response that has no scripts to nonce. Separately, the lookahead terms are unanchored prefixes, so a
hypothetical `/apidocs` or `/_next/imageproxy` route would be excluded from CSP entirely — a
security-shaped consequence, left to the security critic; the performance-relevant half is only the
wasted per-request work.

**Legibility-target:** A reader should be able to check the comment against the pattern and get the
same answer. The comment still claims three exclusions plus a property ("page navigations only") the
pattern does not deliver. Iteration 3's comment pass corrected two other comments in this file and
did not touch this one, so the discrepancy is now the last surviving comment/behaviour gap in
`proxy.ts` on the performance side.

Scaling factor: 2.67 µs × (asset + error-page requests). With 5 SVGs in `public/` and no evidence any
is referenced by the app, the real excess is close to zero in practice.

**Recommendation:** No performance action. If the pattern is tightened for the security reason,
adding a file-extension guard to the lookahead fixes both readings at once. The prefetch `missing:`
guards are correct and should be kept.

---

#### F8 — the percent-encoded branch decodes to a JS string and then re-encodes to UTF-8

**Severity:** Informational
**Location:** `app/lib/utils/exportGraph.ts:35-37`
**Move:** Memory lifecycle / serialization — an unnecessary round-trip through a UTF-16 string
**Classification:** Micro (constant round-trip per call) / Cold path (zero production callers)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**

```
app/lib/utils/exportGraph.ts:35-37
  if (!isBase64) {
    return new Blob([decodeURIComponent(payload)], { type: mediaType });
  }
```

`decodeURIComponent` produces a JS string, which `new Blob([string])` then UTF-8-encodes back into
bytes. For non-ASCII content that is a decode-then-re-encode round trip through a UTF-16
intermediate.

**Legibility-target:** A reader should be able to see that this branch is not on any production path.
`toPng` always returns a `;base64` data URL — the branch exists only for the
`data:text/plain,hello%20world` case, exercised by `exportGraph.test.ts:26-30` and by no application
code.

Scaling factor: linear in payload size, on a path with zero production callers. Correct, tested, and
free.

**Recommendation:** No action.

---

## What Looks Good

- **Nothing performance-relevant regressed in iteration 3.** The commit is comment-only; verified
  mechanically by filtering the `99e1229..HEAD` diff to non-comment lines and getting the empty set.
  A review iteration that changes only prose is the cheapest possible thing to re-review, and the
  commit message says so explicitly ("All three changes are comments, so no test outcome could
  move"). That claim holds against the diff.
- **The R1 comment fix removes a stale premise that could have misdirected a future optimization.**
  `proxy.ts:38-39` now names the Node.js runtime rather than Edge. F5 and F6 both concern the nonce
  construction, and the correct runtime is what tells a future editor which APIs (`Buffer`,
  `crypto.getRandomValues`) are actually on the table. Fixing the comment made the F6 recommendation
  cleaner rather than muddier.
- **The `fetch(dataUrl)` → `dataUrlToBlob` swap is the right trade, and the docstring says why.** The
  alternative — adding `data:` to `connect-src` — would have been cheaper at runtime and worse
  everywhere else. `exportGraph.ts:16-22` states the constraint, so a perf-motivated cleanup pass
  will not silently delete the "slow" loop in favour of the shorter spelling.
- **The decode is exactly O(N) with no hidden multiplication.** Re-confirmed at 2544a19: `blob.size`
  equals the input byte count at every size tested — no double-buffering, no re-encoding, no
  accidental quadratic string concatenation, which is the classic way this function gets written
  wrong.
- **Both `dataUrlToBlob` call sites are behind dynamic imports.** `GraphPanel.tsx:102` `await
  import()`s the export module, so `html-to-image` stays out of the initial bundle. F3's cost — and
  its bytes — are paid only by users who click export.
- **The proxy does no I/O, no `await`, and no allocation proportional to request size.** No KV
  lookup, no config read, no per-request policy assembly from user data. For code on every
  navigation, that is the correct shape, and it is why the measured cost is microseconds.
- **`buildCsp` is a pure function of the nonce and is exported and tested.** That is what makes F5
  and F6 measurable at all — a private closure over request state could not be benchmarked without
  standing up a server.
- **The prefetch `missing:` guards are a genuine optimization**, keeping `next-router-prefetch` and
  `purpose: prefetch` requests from burning proxy work on navigations that may never paint.
- **`force-dynamic` is more legible than `await headers()`.** A route-segment config export cannot be
  deleted by a cleanup pass that mistakes it for a dead statement — precisely what the discarded
  `await headers();` invited.

---

## Summary Table

| # | Finding | Severity | Location | Class × Temp | Confidence | Baseline |
|---|---------|----------|----------|--------------|------------|----------|
| F1 | `force-dynamic` renders the whole tree per request | High | `app/layout.tsx:26` | Macro × Hot | High (mode) / Low (magnitude) | speculative (build blocked) |
| F2 | `force-dynamic` broader than `await headers()`; forecloses PPR | Medium | `app/layout.tsx:21-26` | Macro × Cold | Medium | speculative |
| F3 | base64 decode is a synchronous main-thread per-byte loop | Medium | `exportGraph.ts:38-43` | Macro × Cold | High | measured: ~5 ms/MiB |
| F5 | per-request proxy work | Low | `proxy.ts:20-34,40,49` | Micro × Hot | High | measured: 2.67 µs/req |
| F6 | 48-char nonce inflates CSP header | Low | `proxy.ts:40` | Micro × Hot | High | measured: 276 vs 252 bytes |
| F7 | matcher covers `public/` assets and 404s | Low | `proxy.ts:62-75` | Micro × Hot | High | measured: 2.67 µs × excess |
| F4 | ~1.9× peak transient memory vs fetch path | Informational | `exportGraph.ts:38-43` | Micro × Cold | Medium | measured (partial) |
| F8 | percent-encoded branch round-trips through a string | Informational | `exportGraph.ts:35-37` | Micro × Cold | High | speculative |

---

## Overall Assessment

**No Critical findings. One High finding exists — F1 — and it is not a defect.** It is the accepted
cost of the feature (per-request nonces require per-request rendering), it is rendering-mode-neutral
against the immediately preceding commit, and it grades High only because the review range starts at
`d86d2dc`, where the app was still prerendered. It carries a Macro × Hot classification, which is
what anchors it at High under this skill's matrix; the iteration-2 rubric's decision to record it as
amber A9 is a synthesis-level disposition this pass does not contest. From a performance standpoint
there is nothing here to block on.

**Iteration 3 is performance-inert.** The commit changes comments only — verified mechanically, not
asserted — so every finding is carried forward unchanged in mechanism. What did change is the quality
of the reasoning a future optimizer will work from: `proxy.ts` no longer claims an Edge runtime it
does not run in, which is directly load-bearing for F6's recommendation, and it no longer carries a
Tailwind rationale that contradicted its own test file. Both are net positives for a performance
reader even though neither moves a nanosecond.

The hot-path picture is settled. The only new per-request code in the whole range is the proxy, and
it re-measures at **2.67 µs** — three orders of magnitude under the render it precedes, which is what
makes F5, F6, and F7 real but unrankable against F1. Everything expensive in this range is either
once-per-deploy-turned-once-per-request by design (F1) or once-per-user-click behind a dynamic import
(F3, F4). No N+1 pattern, no unbounded collection, no cache without eviction, no contention primitive,
and no super-linear behaviour was introduced anywhere in `d86d2dc..HEAD`.

The single genuine gap is unchanged and unfixable here: **F1 has no number.** The repo has no
benchmark, no Lighthouse config, and no recorded TTFB, and `next build` still cannot run in this
sandbox (re-attempted at 2544a19; `next/font/google` cannot reach `fonts.googleapis.com`). Whoever
owns the CSP decision should capture route markers and p50 TTFB at `d86d2dc` versus HEAD in a
networked environment — not to gate this change, but so the cost is written down once.

---

## Goal-Alignment Note

- **Answered:** Whether anything performance-relevant changed in iteration 3 (no — comment-only,
  verified by filtering the diff to non-comment lines). All eight prior findings re-assessed against
  2544a19 with line anchors re-resolved for the +4-line shift in `proxy.ts`. Both prior measurements
  independently re-taken rather than inherited: proxy per-request work now 2.67 µs (prior 3.3 µs) and
  decode now ~5 ms/MiB (prior 3.8 ms/MiB) — same code, so the spread is run-to-run variance and both
  runs agree on shape and order of magnitude. `next build` re-attempted to try to close F1's
  measurement gap. Explicit Critical/High determination: no Critical; one High (F1), accepted feature
  cost, not a blocker.
- **Out of scope:** `exportAll.ts` is untouched by this range, so its double-compression of an
  already-DEFLATE'd PNG through JSZip and its extra Blob copy during `generateAsync` are noted but
  not graded. The unanchored negative-lookahead terms in the matcher (`/apidocs`,
  `/_next/imageproxy` shipping without CSP) are a security consequence, not a performance one.
  `header.endsWith(";base64")` case-sensitivity, the missing `catch` at the export call sites, and
  the `"Not a data: URL"` message content are correctness/UX. Bundle-size analysis of `html-to-image`
  and `jszip` was not attempted; both are behind dynamic imports and neither version changed. The
  truth of the rewritten comments is a fact-check concern, not graded here.
- **Escalate:** F1's magnitude remains unmeasurable in this environment — `next build` fails on
  Google Fonts fetch, confirmed again at 2544a19 — so the static-to-dynamic transition ships with no
  number attached. This is the third consecutive pass reporting it; no amount of further code reading
  will produce the measurement, and if the orchestrator wants a number before this feature ships it
  must be taken outside the sandbox. Secondarily, F2's claim about Next 16.2.4 PPR semantics could
  not be exercised (PPR not enabled, build does not run); verify against the docs before acting on
  it if the project has PPR ambition.
