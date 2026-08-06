# Performance Review — strict-CSP feature, iteration-1 fixes

**Commit:** 99e1229
**Range:** `d86d2dc..HEAD` (99e1229) in `/workspace/runs/review-arms/e3-loops/wt-csp-arm2`, branch `e3/csp-arm2`
**Diff size:** 5 files, +266/−5 (`app/layout.tsx`, `app/lib/utils/exportGraph.ts` + new test, new `proxy.ts` + new `proxy.test.ts`)
**Reviewer stance:** performance critic only. The merged fact-check (k=3) is treated as foundation and not re-verified.

## Measurement environment

Two of the findings below carry real measured numbers rather than the speculative flag. Both were produced in this worktree:

- **Decode microbenchmark** — `node v20.20.2`, script written to `$TMPDIR/b.mjs`, replicating `dataUrlToBlob`'s base64 branch verbatim (`atob` + `charCodeAt` loop + `new Blob`) over synthetic payloads. One warm-up iteration, then a single timed run per size.
- **Proxy per-request microbenchmark** — `node v20.20.2`, `$TMPDIR/p.mjs`, replicating `proxy()`'s per-request work (`Buffer.from(crypto.randomUUID()).toString("base64")`, `buildCsp` array construction + `join`, `new Headers(request.headers)` clone over a 6-header realistic request, two `.set()` calls), N = 200,000 iterations.

**What could not be measured.** `npx next build` fails in this sandbox — `next/font/google` cannot reach `fonts.googleapis.com`, so both `EB_Garamond` and `Geist_Mono` error out and the build aborts before emitting the route table. That means the `○`-static-vs-`ƒ`-dynamic route markers and any TTFB comparison between `d86d2dc` and HEAD are unavailable. Every finding that would need those numbers is flagged speculative below rather than given a fabricated magnitude.

---

## Findings

#### F1 — `force-dynamic` in the root layout re-renders the entire component tree on every page request

**Severity:** High
**Location:** `app/layout.tsx:26` (`export const dynamic = "force-dynamic";`)
**Move:** Work moved to the wrong place (build time → request time); size of N
**Classification:** Macro / Hot
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
$ cat next.config.ts
const nextConfig: NextConfig = {
  /* config options here */
};
```

**Legibility-target:** A maintainer should be able to see, from the route table alone, that every page under `app/` is `ƒ (Dynamic)` and that no HTML is reusable between visitors. The export makes this legible in the module's public surface — which is a real improvement over the `await headers()` it replaced — but the cost it declares is still unmeasured anywhere in the repo.

`app/layout.tsx` is the root layout, so this export cascades to every route segment beneath it. Today that is one page route (`app/page.tsx`), but `app/page.tsx` is `"use client"` and pulls in the whole workspace: 63 `.tsx` files and 12,726 non-test LOC under `app/`. Scaling factor is **1× per request instead of 1× per deploy** — the server-side render of that tree, plus font-CSS resolution and the RSC payload serialization, moves from a single build-time execution to once per navigation, and the Full Route Cache (and any CDN HTML caching in front of it) is disabled for the whole app. The multiplier is therefore total page views, not a constant.

Two things keep this at High rather than Critical. First, the work per request is bounded by the fixed component tree — nothing here is unbounded in user data. Second, and importantly for the review's framing: **relative to `d90d6bb` this fix is rendering-mode-neutral.** The `await headers()` it replaced already forced per-request rendering; the iteration-1 change makes an existing cost explicit rather than introducing a new one. It is graded against `d86d2dc` because that is the review range, and against `d86d2dc` the app genuinely moves from prerendered to per-request.

**Recommendation:** No code change from a performance standpoint — this is the accepted cost of per-request nonces and it is now correctly declared. Do add the measurement the repo lacks: capture `next build`'s route markers and a p50 TTFB for `/` at `d86d2dc` and at HEAD, in an environment with network access, and record the delta in the CSP decision record. If the TTFB delta turns out to be large, F2 is the recovery path.

---

#### F2 — `force-dynamic` is strictly broader than the `await headers()` it replaced, and forecloses partial prerendering app-wide

**Severity:** Medium
**Location:** `app/layout.tsx:26`; compare `git show d90d6bb:app/layout.tsx` (`await headers();` inside an `async` `RootLayout`)
**Move:** Work moved to the wrong place — an opt-out that was per-segment and dynamic-API-scoped became a route-segment config flag
**Classification:** Macro / Cold (the affected surface is a build/render-mode capability, not per-request executed work)
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

**Legibility-target:** A reader comparing the two spellings should be able to tell that they are not interchangeable. Nothing in the diff or the commit message says so — R4's disposition presents `force-dynamic` as a purely legibility-motivated swap ("states the contract in the module's public surface"), which is true of the naming and false of the render-mode semantics.

`await headers()` is a dynamic API: it marks the segment that calls it as dynamic and, under partial prerendering, produces a dynamic hole while the surrounding shell still prerenders. `export const dynamic = "force-dynamic"` is a route-segment config that opts the whole subtree out of static generation and PPR unconditionally, and additionally applies no-store fetch semantics to the subtree. On Next 16.2.4 with an empty `next.config.ts` — PPR not enabled — the two are behaviourally equivalent *today*, which is why this is Medium and not High. The cost is optionality: if the app later enables PPR to recover F1's static shell while keeping a per-request nonce hole, the root-layout `force-dynamic` silently defeats it, and the failure mode is "we turned on PPR and nothing got faster," which is hard to attribute back to this line.

Scaling factor: none today; the loss is the entire prerenderable fraction of the shell under any future PPR adoption.

**Recommendation:** Keep `force-dynamic` — it is the right call for correctness-of-intent right now. Add one sentence to the existing comment recording that this is deliberately broader than a dynamic-API opt-out and is the line to revisit if PPR is ever enabled. That is enough to make the coupling discoverable.

---

#### F3 — base64 decode moved from the browser's native fetch path onto the main thread as a per-byte JS loop

**Severity:** Medium
**Location:** `app/lib/utils/exportGraph.ts:35-40` (the `atob` + `charCodeAt` loop in `dataUrlToBlob`), consumed at `:54` and `:65`
**Move:** Work moved to the wrong place (off-thread native decode → synchronous main-thread interpreted loop)
**Classification:** Macro / Cold — Macro because the *blocking* duration is now proportional to image size rather than off the critical thread entirely; Cold because both call sites are user-initiated exports
**Confidence:** High
**Baseline:** measured — 3.5 ms (1 MiB), 13.6 ms (4 MiB), 61.6 ms (16 MiB) for the full `dataUrlToBlob` base64 branch; `node v20.20.2`, `$TMPDIR/b.mjs` microbenchmark replicating the function verbatim, one warm-up + one timed run per size
**Evidence:**

```
app/lib/utils/exportGraph.ts:35-40
  const binary = atob(payload);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return new Blob([bytes], { type: mediaType });
```

Replaced (from the diff):

```
-  const res = await fetch(dataUrl);
-  const blob = await res.blob();
-  triggerDownload(blob, filename);
+  triggerDownload(dataUrlToBlob(dataUrl), filename);
```

Benchmark output:

```
0.5 MiB png -> b64 chars 699052   | full decode 3.7 ms  | atob alone 0.6 ms  | loop 3.1 ms
1 MiB   png -> b64 chars 1398104  | full decode 3.5 ms  | atob alone 1.2 ms  | loop 2.3 ms
4 MiB   png -> b64 chars 5592408  | full decode 13.6 ms | atob alone 3.9 ms  | loop 9.7 ms
16 MiB  png -> b64 chars 22369624 | full decode 61.6 ms | atob alone 16.5 ms | loop 45.1 ms
```

**Legibility-target:** A reader should be able to see that the decode is O(bytes) *on the main thread* and that the `await` disappearing from the call sites is not free — the old `await fetch(dataUrl)` yielded to the event loop and did the decode in browser-native code; `dataUrlToBlob` is a synchronous call inside an `async` function and holds the thread for its whole duration.

Scaling factor is linear at roughly **3.8 ms per MiB of decoded PNG**, of which ~70% is the `charCodeAt` loop rather than `atob` (45.1 ms of the 61.6 ms at 16 MiB). Both call sites render at `pixelRatio: 2`, so the PNG is 4× the pixel count of the on-screen graph — a large decomposition graph on a high-DPI viewport lands in the multi-MiB range, i.e. a 10–60 ms synchronous main-thread stall. That is a single dropped frame budget several times over, during an interaction where `GraphPanel` has already set `exporting` state and the UI is expected to stay responsive. It is genuinely cold — one click, no loop, no repetition — which is why this is Medium and not High.

Note the constraint is real: `connect-src 'self'` refuses `data:`, so `fetch(dataUrl)` is not available and the in-process decode is the correct answer over widening the directive. The finding is about *where* the decode runs, not whether it should exist.

**Recommendation:** If export jank is ever reported, the drop-in fix is `Uint8Array.fromBase64(payload)` (Stage 3, shipping in current Chrome/Safari/Node 22+) with the current loop as fallback — it moves the per-byte work back into native code. A lower-effort intermediate is chunking the loop, but that only helps if it also yields. Until someone reports jank this is a documented cost, not a defect: measure a real export with the Performance panel before spending effort.

---

#### F4 — `dataUrlToBlob` holds roughly twice the peak transient memory of the fetch path it replaced

**Severity:** Informational
**Location:** `app/lib/utils/exportGraph.ts:35-40`
**Move:** Memory lifecycle — an extra full-size decoded copy is live simultaneously with the source
**Classification:** Micro / Cold
**Confidence:** Medium (allocation counts are read off the code; V8 string representation for the `atob` result is inferred, not measured)
**Baseline:** measured, partial — the microbenchmark confirms `blob.size` equals the input byte count exactly at every size (524288 / 1048576 / 4194304 / 16777216), so no hidden re-encoding; peak-RSS was not instrumented
**Evidence:**

```
app/lib/utils/exportGraph.ts:35-40   (binary string, then bytes array, then Blob — three live copies)
  const binary = atob(payload);
  const bytes = new Uint8Array(binary.length);
  ...
  return new Blob([bytes], { type: mediaType });
```

**Legibility-target:** A reader should be able to count the simultaneously-live copies of the image. There are four: the caller's `dataUrl` string (~1.33N, still referenced by the caller's local), `binary` (~N), `bytes` (N), and the `Blob`'s own copy (N) — peak ≈ 4.33N. The old path held the `dataUrl` string plus the fetch-produced Blob, ≈ 2.33N.

Scaling factor is a constant **~1.9× peak transient allocation**, linear in image size. For a 4 MiB PNG that is ~17 MiB transient instead of ~9 MiB. In `exportAll.ts:64-65` the Blob is then handed to JSZip, which reads it again during `generateAsync`, so the export-all path stacks another copy on top — but that is pre-existing behaviour and unchanged by this diff. At realistic graph-screenshot sizes none of this is close to a browser tab's memory ceiling, which is why this stays Informational.

**Recommendation:** No action. If F3's recommendation is ever taken, `Uint8Array.fromBase64` drops the `binary` copy for free and this resolves as a side effect.

---

#### F5 — per-request proxy work is real but three orders of magnitude below the render it precedes

**Severity:** Low
**Location:** `proxy.ts:19-32` (`buildCsp` rebuilds a 9-element array and re-joins 8 constant directives per call), `proxy.ts:36` (nonce), `proxy.ts:48` (`new Headers(request.headers)` clone)
**Move:** Hidden multiplication — a constant-cost block executed once per navigation
**Classification:** Micro / Hot
**Confidence:** High
**Baseline:** measured — **3.3 µs per request** for the combined nonce + `buildCsp` + `Headers` clone + two `set()` calls; `node v20.20.2`, `$TMPDIR/p.mjs`, N = 200,000 iterations against a 6-header request
**Evidence:**

```
proxy.ts:36
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
proxy.ts:48
  const requestHeaders = new Headers(request.headers);
```

```
per-request proxy work: 3.3 us  (N=200000)
```

**Legibility-target:** A reader should be able to conclude that the proxy is not the thing to optimize. It is the only per-request code the diff adds on the hot path, so it deserves a number — and the number settles it.

Scaling factor: 3.3 µs × navigations. Against F1's per-request full-tree SSR, which is conservatively in the single-to-tens-of-milliseconds range, this is a **~0.03% or smaller share** of the request. Eight of the nine directives are compile-time constants that could be hoisted to a module-level prefix string, and the `Headers` clone could in principle be avoided — neither is worth doing.

**Recommendation:** No action. Hoisting the constant directives is a legitimate small cleanup if someone is already editing `buildCsp`, but it must not be sold as a performance fix; the measured ceiling on the win is under 3 µs per request.

---

#### F6 — the nonce is a 48-character base64 of a UUID *string*, inflating the CSP header ~10% for no entropy gain

**Severity:** Low
**Location:** `proxy.ts:36`
**Move:** Serialization — per-response bytes on the wire
**Classification:** Micro / Hot
**Confidence:** High
**Baseline:** measured — CSP is **276 bytes** with the current nonce vs **252 bytes** with `crypto.getRandomValues(new Uint8Array(16))`; nonce length 48 chars vs 24 chars; `node v20.20.2`, `$TMPDIR/p.mjs`
**Evidence:**

```
proxy.ts:36
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

```
nonce len 48 "YzRhZTVhYjEtYmRiNi00YzY5LWJjYTAtOWE2MzlkMTU5MmE2"
csp bytes 276
alt nonce len 24 csp bytes 252
```

`crypto.randomUUID()` returns the 36-character *hyphenated text* form of 122 bits of entropy; base64-ing that text yields 48 characters carrying the same 122 bits. Encoding 16 raw random bytes instead gives 128 bits in 24 characters.

**Legibility-target:** A reader should be able to see that the nonce's length is an artifact of double-encoding a string, not a security parameter — the current spelling reads as if 48 characters were chosen deliberately.

Scaling factor: **24 bytes per response × navigations**, uncompressible in both cases. Because the nonce is fresh per request the whole `Content-Security-Policy` header is a literal on every response — HPACK/QPACK cannot index it, so all 276 bytes are paid each time. The internal `x-middleware-request-content-security-policy` forwarding encoding is consumed by the Next server and does not reach the wire, so the response header is the only per-navigation cost. 24 bytes is noise on an HTML response; this is Low on the strength of it being on the hot path at all, not on magnitude.

**Recommendation:** Optional one-line change to `crypto.getRandomValues(new Uint8Array(16))` — shorter header, more entropy, and it drops the `Buffer` dependency (relevant if the proxy is ever moved to the Edge runtime). Not worth a dedicated commit.

---

#### F7 — the matcher runs the proxy on `public/` assets and error pages, which its own comment says it does not

**Severity:** Low
**Location:** `proxy.ts:53-71` (`config.matcher`), comment at `:54-57` ("Apply CSP to page navigations only")
**Move:** Size of N — the request population the proxy actually sees is larger than the comment's population
**Classification:** Micro / Hot
**Confidence:** High
**Baseline:** measured — 3.3 µs per extra request from F5's benchmark, times the excess population
**Evidence:**

```
proxy.ts:58
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

```
$ ls public/
file.svg  globe.svg  next.svg  vercel.svg  window.svg
```

The negative lookahead excludes `api`, `_next/static`, `_next/image`, and `favicon.ico`. It does not exclude `public/` assets (5 SVGs served from the app root), `robots.txt`, `sitemap.xml`, or 404 paths — each of those matches, allocates a nonce, builds a CSP, and clones the request headers for a response that has no scripts to nonce. Separately, the lookahead terms are unanchored prefixes, so a hypothetical `/apidocs` or `/_next/imageproxy` route would be excluded from CSP entirely — that is a security-shaped consequence and is left to the security critic; the performance-relevant half is only the wasted per-request work.

**Legibility-target:** A reader should be able to check the comment against the pattern and get the same answer. Right now the comment claims three exclusions and a fourth property ("page navigations only") that the pattern does not deliver.

Scaling factor: 3.3 µs × (asset + error-page requests). With 5 SVGs in `public/` and no evidence any of them are referenced by the app, the real excess is close to zero in practice.

**Recommendation:** No performance action. If the pattern is tightened for the security reason, adding a file-extension guard to the lookahead fixes both readings at once. The prefetch `missing:` guards are correct and should be kept.

---

#### F8 — the percent-encoded branch decodes to a JS string and then re-encodes to UTF-8

**Severity:** Informational
**Location:** `app/lib/utils/exportGraph.ts:32-34`
**Move:** Memory lifecycle / serialization — an unnecessary round-trip through a UTF-16 string
**Classification:** Micro / Cold
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**

```
app/lib/utils/exportGraph.ts:32-34
  if (!isBase64) {
    return new Blob([decodeURIComponent(payload)], { type: mediaType });
  }
```

`decodeURIComponent` produces a JS string, which `new Blob([string])` then UTF-8-encodes back into bytes. For non-ASCII content that is a decode-then-re-encode round trip through a UTF-16 intermediate.

**Legibility-target:** A reader should be able to see that this branch is not on any production path. `toPng` always returns a `;base64` data URL — the branch exists only for the `data:text/plain,hello%20world` case, which is exercised by `exportGraph.test.ts:26-30` and by no application code.

Scaling factor: linear in payload size, on a path with zero production callers. It is correct, tested, and free.

**Recommendation:** No action.

---

## What Looks Good

- **The `fetch(dataUrl)` → `dataUrlToBlob` swap is the right trade, and the comment says why.** The alternative fix — adding `data:` to `connect-src` — would have been cheaper at runtime and worse everywhere else. The docstring at `exportGraph.ts:16-22` states the constraint explicitly, so a future reader who sees the "slow" per-byte loop will not delete it in favour of the shorter spelling. That is exactly the failure mode a perf-motivated cleanup would otherwise cause here.
- **The decode is exactly O(N) with no hidden multiplication.** The benchmark confirms `blob.size` equals the input byte count at every size tested — no double-buffering, no re-encoding, no accidental quadratic string concatenation, which is the classic way this function gets written wrong.
- **Both `dataUrlToBlob` call sites are behind dynamic imports.** `GraphPanel.tsx:102` and `page.tsx:576` `await import()` the export modules, so `html-to-image` and `jszip` stay out of the initial bundle. F3's cost is paid only by users who click export, and the bytes are too.
- **`buildCsp` is a pure function of the nonce and is now exported and tested.** This is what makes F5 measurable at all — a private closure over request state would not have been benchmarkable without standing up a server.
- **The proxy does no I/O, no `await`, and no allocation proportional to request size.** `crypto.randomUUID()` is non-blocking; there is no KV lookup, no config read, no per-request policy assembly from user data. For code that runs on every navigation, that is the correct shape.
- **The prefetch `missing:` guards are a genuine optimization**, not just correctness — they keep `next-router-prefetch` and `purpose: prefetch` requests from burning proxy work on navigations that may never paint.
- **`force-dynamic` is more legible than `await headers()`** even though F2 notes it is semantically broader. A route-segment config export cannot be removed by a cleanup pass that mistakes it for a dead statement, which is precisely what the discarded `await headers();` invited.

---

## Summary Table

| ID | Finding | Severity | Class | Temp | Baseline |
|----|---------|----------|-------|------|----------|
| F1 | `force-dynamic` renders the whole tree per request | High | Macro | Hot | speculative (build blocked) |
| F2 | `force-dynamic` broader than `await headers()`; forecloses PPR | Medium | Macro | Cold | speculative |
| F3 | base64 decode moved to a main-thread per-byte loop | Medium | Macro | Cold | measured: 3.8 ms/MiB |
| F5 | per-request proxy work | Low | Micro | Hot | measured: 3.3 µs/req |
| F6 | 48-char nonce inflates CSP header | Low | Micro | Hot | measured: 276 vs 252 bytes |
| F7 | matcher covers `public/` assets and 404s | Low | Micro | Hot | measured: 3.3 µs × excess |
| F4 | ~1.9× peak transient memory vs fetch path | Informational | Micro | Cold | measured (partial) |
| F8 | percent-encoded branch round-trips through a string | Informational | Micro | Cold | speculative |

---

## Overall Assessment

**No blocking performance defect.** The iteration-1 fixes are performance-neutral-to-positive against the state they were fixing, and the one High finding is an accepted cost of the feature rather than a regression the fixes introduced.

Both moved-work changes assessed as requested:

- **`await headers()` → `force-dynamic`** is rendering-mode-neutral against `d90d6bb`. It changes nothing about how much work runs per request; it changes only how visible that fact is, which is an improvement. Against the review base `d86d2dc` the app does move from prerendered to per-request (F1), but that transition belongs to the CSP feature, not to this iteration. The one substantive delta the fix does introduce is scope (F2): `force-dynamic` is a strictly stronger opt-out than the dynamic API it replaced, and it closes the PPR recovery door for the whole app. That is worth one sentence of comment, not a code change.
- **`fetch(dataUrl)` → in-process decode** genuinely relocates work — from browser-native, off-the-JS-thread decoding to a synchronous interpreted per-byte loop on the main thread, at a measured ~3.8 ms/MiB with ~70% of that in the `charCodeAt` loop rather than `atob` (F3), and at roughly 1.9× peak transient memory (F4). Both call sites are cold, user-initiated, once-per-click exports behind dynamic imports, so this lands at Medium. The trade is correct on the merits — widening `connect-src` to `data:` to save 10–60 ms on a click would be a bad exchange — and the code documents why.

The hot-path picture is reassuring. The only new per-request code is the proxy, and it measures at 3.3 µs — three orders of magnitude under the render it precedes, which makes the nonce-length and matcher-scope findings (F6, F7) real but unrankable against F1. Everything expensive in this diff is either once-per-deploy-turned-once-per-request by design (F1) or once-per-user-click (F3, F4).

The one thing genuinely missing is a number for F1. The repo has no benchmark, no Lighthouse config, and no recorded TTFB, and this sandbox cannot build. Whoever owns the CSP decision should capture route markers and TTFB at `d86d2dc` versus HEAD in a networked environment — not to gate this change, but so the cost of per-request nonces is written down once instead of re-litigated by every future reviewer who notices `force-dynamic` in the root layout.

---

## Goal-Alignment Note

- **Answered:** Both moved-work changes named in the brief, assessed as moves (F1/F2 for `await headers()` → `force-dynamic`; F3/F4 for the fetch round-trip → in-process decode). `dataUrlToBlob`'s memory lifecycle and its full decoded copy (F4). The per-navigation serialization of the CSP onto two headers (F6, with the finding that only the response header reaches the wire). Contention, caching, and asymptotics: no contention primitives, no caches, and no super-linear behaviour introduced anywhere in the range — the decode is exactly linear and the proxy is O(1) in request size. Prior-rubric performance items re-checked against current code: G8 (`buildCsp` rebuilds its array per request) and G2 (48-char nonce) both still hold and are now carried with measured numbers as F5 and F6; A8 (`await headers()` cost) is superseded by F1/F2; A9's performance half (matcher scope) is carried as F7. F6 in the prior rubric is unchanged by this diff.
- **Out of scope:** `exportAll.ts` is untouched by this range, so its double-compression of an already-DEFLATE'd PNG through JSZip and its extra Blob copy during `generateAsync` are noted but not graded. The unanchored negative-lookahead terms in the matcher (`/apidocs`, `/_next/imageproxy` shipping without CSP) are a security consequence, not a performance one — flagged for the security critic. `buildCsp`'s `header.endsWith(";base64")` detection and the missing `catch` at the export call sites are correctness/UX, not perf. Bundle-size analysis of `html-to-image` and `jszip` was not attempted; both are behind dynamic imports and neither version changed.
- **Escalate:** F1's magnitude is unmeasurable in this environment because `next build` cannot fetch Google Fonts. If the orchestrator needs a number for the static-to-dynamic transition before this feature ships, that measurement must be taken outside the sandbox — it is the single largest performance unknown in the range and no amount of code reading will produce it. Secondarily, F2 is a claim about Next 16 PPR semantics that I could not exercise (PPR is not enabled and the build does not run); if the project has any PPR ambition, verify that claim against Next 16.2.4's docs before acting on the recommendation.
