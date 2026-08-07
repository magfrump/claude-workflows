# Performance Review — Decision 031 Tier Policy T Validation (arm 2, pass 2)

Commit: 99e1229
Scope: `git diff d86d2dc..HEAD` (5 files, +266/-5)
Reviewer: performance-reviewer skill (standalone; no upstream code-fact-check report provided)
Baseline rule: every finding carries a measured number+units+source OR the literal speculative phrase.

## Context / files in scope

- `app/layout.tsx` — adds `export const dynamic = "force-dynamic"` to the root layout.
- `proxy.ts` (new) — per-request CSP proxy: builds a nonce'd policy, forwards it on request + response.
- `proxy.test.ts` (new) — unit tests; not shipped, excluded from runtime analysis.
- `app/lib/utils/exportGraph.ts` — adds `dataUrlToBlob()` and swaps two `fetch(dataUrl)` + `.blob()` calls for it.
- `app/lib/utils/exportGraph.test.ts` (new) — unit tests; excluded from runtime analysis.

Call-site classification (established by reading the callers, not inferred):
- `dataUrlToBlob` ← `downloadGraphAsPng` ← `GraphPanel.handleExportGraph`, a `useCallback` fired on an export button click that sets an `exporting` spinner. Also ← `graphToPngBlob` ← `exportAllAsZip`. Both are **user-initiated, one-shot, cold paths.**
- `proxy()` runs once **per page navigation** (matcher excludes `api`, `_next/static`, `_next/image`, `favicon.ico`, and prefetches). Per-navigation, not per-render-tick — warm but not a tight loop.
- `force-dynamic` forces per-request SSR for every route under the root layout.

---

## Findings

### F1 — `force-dynamic` forces per-request SSR on every route (ACCEPTED feature cost, not a fresh defect)

- **Location:** `app/layout.tsx` (`export const dynamic = "force-dynamic"`)
- **Classification:** Accepted feature cost (High-magnitude, pre-existing acceptance). Explicitly out of scope as a fresh red per the historical rule — the per-request-render cost is the intended mechanism that makes per-request CSP nonces work; a statically prerendered document would bake in one nonce and reuse it, defeating the nonce.
- **Move:** Trace the work multiplier — static prerender (once at build) → dynamic render (once per request). Every visit now re-runs the server render instead of serving a cached HTML document.
- **Baseline:** Speculative: no measurement was taken; the per-request SSR overhead versus the prior static/ISR path was not benchmarked in this diff.
- **Evidence (verbatim):**
  > `+// Every route under this layout must render per request: a statically`
  > `+// prerendered HTML document would bake in one nonce and reuse it for every`
  > `+// visitor, which defeats the nonce.`
  > `+export const dynamic = "force-dynamic";`
- **Legibility-target:** N/A — accepted. Recorded for completeness only. This is the design's known cost, not a regression introduced by this pass.

### F2 — `dataUrlToBlob` decodes base64 on the main thread with a per-byte `charCodeAt` loop (cold path)

- **Location:** `app/lib/utils/exportGraph.ts:23-40`
- **Classification:** Low (informational). Cold, user-initiated, one-shot path; not a hot path (fails the hot-path gate).
- **Move:** Hot-path gate + work-per-invocation. The decode is O(n) over the PNG byte length on the main thread. At `pixelRatio: 2` a full-viewport graph PNG can be on the order of a few MB, so the `for` loop runs a few million iterations synchronously per export. But it runs once per export click, behind an `exporting` spinner (`setExporting(true)` wraps the call), and the prior implementation (`fetch(dataUrl)` → `.blob()`) also had to materialize the same bytes — so this is a decode-location change, not new work in a loop.
- **Baseline:** Speculative: the synchronous `atob` + `charCodeAt` loop was not benchmarked against the replaced `fetch(dataUrl).blob()` path; no main-thread-blocking duration was measured for a representative export payload.
- **Evidence (verbatim):**
  > `+  const binary = atob(payload);`
  > `+  const bytes = new Uint8Array(binary.length);`
  > `+  for (let i = 0; i < binary.length; i++) {`
  > `+    bytes[i] = binary.charCodeAt(i);`
  > `+  }`
  > `+  return new Blob([bytes], { type: mediaType });`
- **Legibility-target:** If a future measurement shows the export click blocks the main thread past ~50ms for typical graphs, the byte loop is the lever (it is the only O(n) step). No action warranted now — the change is justified by the CSP `connect-src 'self'` constraint documented in the helper (`fetch(dataUrl)` is a `connect-src` fetch the policy refuses), and the cold-path, spinner-guarded context makes the synchronous decode acceptable.

### F3 — `proxy()` per-navigation work: `randomUUID` + `Buffer` base64 + array-join (warm path, negligible)

- **Location:** `proxy.ts:29-46` (`buildCsp` + nonce generation)
- **Classification:** Green (no action). Runs once per page navigation; constant-size work.
- **Move:** Per-invocation cost on the warmest changed path. Each navigation does one `crypto.randomUUID()`, one `Buffer.from(...).toString("base64")`, one 9-element array `.join("; ")`, and two `Headers` constructions. All are constant-size (the policy string is fixed-length; the nonce is a fixed 36-char UUID). No allocation grows with request count, payload, or collection size — there is no loop over user data.
- **Baseline:** Speculative: the per-navigation proxy overhead was not measured; however the work is O(1) constant-size with no data-dependent iteration, so it does not scale with load.
- **Evidence (verbatim):**
  > `+  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");`
  > `+  const csp = buildCsp(nonce);`
  > `+  const requestHeaders = new Headers(request.headers);`
- **Legibility-target:** None. Constant-size per-navigation work is not a scaling concern; the matcher already excludes static assets and prefetches so the proxy is not invoked on asset fan-out.

---

## What Looks Good

- **Prefetch exclusion in the matcher.** `proxy.ts` config skips `next-router-prefetch` / `purpose: prefetch` requests, avoiding burning a nonce (and the per-request render it implies) on navigations that may never paint. This is a deliberate load-reducing choice, called out in a comment.
- **Static-asset exclusion.** The matcher excludes `_next/static`, `_next/image`, and `favicon.ico`, so the proxy does not run on the asset fan-out of a page load — only on the document navigation. This keeps the per-navigation cost from multiplying across dozens of sub-requests.
- **Lazy import of the export helper.** `GraphPanel` dynamically `import()`s `exportGraph` only inside the click handler ("avoid loading html-to-image until needed"), keeping the heavy `html-to-image` dependency off the initial bundle/hydration path.
- **`dataUrlToBlob` constant-size fast path.** The non-base64 branch is a single `decodeURIComponent` with no loop; only the base64 branch iterates, and it pre-sizes the `Uint8Array` (`new Uint8Array(binary.length)`) rather than growing it — no reallocation churn.

---

## Summary Table

| ID | Finding | Path | Classification | Baseline |
|----|---------|------|----------------|----------|
| F1 | `force-dynamic` per-request SSR | Every route (render) | Accepted feature cost (High, pre-accepted; not a fresh red) | Speculative |
| F2 | Synchronous base64 byte-loop decode | Export click (cold, one-shot) | Low / informational | Speculative |
| F3 | Per-navigation nonce+CSP build | Proxy (warm, O(1)) | Green | Speculative |

---

## Overall Assessment

**No Critical performance defects.** The single High-magnitude item (F1, `force-dynamic` per-request SSR) is the explicitly accepted feature cost of per-request CSP nonces and is excluded from fresh-defect classification by the historical rule — it is not a fresh Critical and not a new red. The remaining changed paths are either cold and one-shot (F2, export decode) or warm but constant-size (F3, per-navigation proxy). Nothing in this diff introduces a hot-path regression, an N+1 pattern, an unbounded allocation, or work that scales with load or collection size.

Under Tier Policy T, this diff produces **0 red** from the performance lens at arm 2 pass 2 (99e1229): F1 is accepted (amber-equivalent, out of scope), F2 is Low/informational, F3 is Green. The confirmation the validation seeks holds for this critic.

## Goal-Alignment Note

The task is to confirm 0 red at arm 2 pass 2 (99e1229) for Decision 031 tier policy T, from the performance critic stage. This review draws only from ancestors of 99e1229 (fresh draw; no prior artifacts or other worktrees consulted) and treats the `force-dynamic` per-request-render cost as the known accepted feature cost rather than a fresh red, per the historical rule. On that basis the performance lens yields **0 Critical and 0 fresh red**, consistent with the outcome the validation is confirming. The one caveat worth surfacing: every finding here rests on the literal speculative baseline — no runtime numbers were measured in this pass — so the "0 red" conclusion is a *structural* judgment (no hot-path regression, no scaling defect, accepted item correctly excluded), not a measured one. If tier policy T requires measured baselines to close a finding, F1/F2/F3 would each need a micro-benchmark; as design-level performance judgments they are sound as written.
