# Architecture Review — e3 CSP arm1 (verification pass, critic stage)

Commit: 1eb081e
Range reviewed: `git diff d86d2dc..HEAD` (HEAD = 1eb081e, branch e3/csp-arm1)
Worktree: /workspace/runs/review-arms/e3-loops/wt-csp-arm1
Merge standard: 0 Red + 0 Amber (here: 0 Structural, 0 Coupling)
Scope discipline: ancestors of worktree HEAD only; no other worktrees or arm artifacts consulted.
Cross-reference: no `security-review.md` present in the output dir at completion — cross-reference of boundary labels is a **no-op** this pass.

---

## Consequences first

This change ships a strict, per-request-nonce CSP as a Next.js 16 Proxy, with the
policy string extracted into a pure, unit-tested module. The dependency graph is
shallow and correctly directed: `proxy.ts` (wiring) → `csp.ts` (pure policy);
`app/layout.tsx` opts into dynamic rendering so the proxy runs per request; the
graph-export utility is constrained to a CSP-compatible render path and guarded
from both directions. Commit 1eb081e is an amber-disposition pass over a
frozen surface — it deletes a dead seam, tightens one signature, adds tests, and
corrects comments. It introduces **no new module, no new public type, and no new
cross-module edge**. The net architectural effect is a *reduction* in coupling
(one dead seam removed) plus new test coverage that pins two invariants that were
previously unenforced.

**No Structural findings exist in this range.** Stated plainly and without
qualification: there are zero dependency-direction inversions, zero module-boundary
breaches, zero layering violations, and zero ISP/LSP violations.

---

## What Looks Good

- **Dependency direction is correct and one-way.** `proxy.ts` imports `buildCsp`
  from `@/app/lib/security/csp`; `csp.ts` imports nothing from the app. The pure
  policy unit sits below the wiring layer that consumes it. Extraction was done
  for the right reason (testability of the one cheap-to-test unit of a
  cross-cutting control), and the entry point stays a thin adapter.
  Evidence (`proxy.ts:1-3`):
  ```
  import { NextResponse } from "next/server";
  import type { NextRequest, ProxyConfig } from "next/server";
  import { buildCsp } from "@/app/lib/security/csp";
  ```

- **Dead seam removed — coupling reduced, not added (CARRIED item, now closed).**
  The prior full-2 advisory flagged the `x-nonce` request header as a
  published-but-unread seam. 1eb081e deletes the write. Repo-wide grep confirms
  **zero live consumers**: the only remaining occurrences are two explanatory
  comments and a regression test asserting the header's *absence*.
  Evidence (grep `x-nonce`, source only): `app/layout.tsx:32` (comment
  "…don't need to read x-nonce here ourselves"), `proxy.ts:33` (comment "No
  `x-nonce` header"). No reader anywhere. Nothing else depended on it — deletion
  breaks no edge. The replacement clobber test was moved onto the load-bearing
  header (request `Content-Security-Policy`), preserving the security assertion
  that the deleted x-nonce test carried.
  Evidence (`proxy.test.ts:79-83`):
  ```
  it("publishes no x-nonce header", () => {
    // The seam had no readers, and a header asserted in CI reads as live
    // plumbing. Reinstate both together, never the header alone.
    expect(forwardedRequestHeader(run(), "x-nonce")).toBeNull();
  });
  ```

- **`buildCsp` env dependency is now a required parameter, and the shipping
  branch is the tested branch (CARRIED item, now confirmed).** The
  `= process.env.NODE_ENV` default was removed; `nodeEnv: string | undefined` is
  now required and injected at the single production call site. This makes the
  function pure (no ambient global read) and — critically — means the production
  (non-`development`) branch is exactly what the tests exercise, rather than a
  branch that only the ambient default reaches.
  Evidence (`csp.ts:46`): `export function buildCsp(nonce: string, nodeEnv: string | undefined): string {`
  Evidence (`proxy.ts:19`): `const csp = buildCsp(nonce, process.env.NODE_ENV);` — the only caller (grep-confirmed).
  The fail-closed comparison (`nodeEnv === "development"`, comparing against the
  permissive value) is now directly covered by `csp.test.ts`'s "fails closed for
  any environment that is not exactly 'development'" case over
  `[undefined, "", "Development", "dev", "test", "prod"]`.

- **CSP↔export invariant is now guarded from both directions (CARRIED item, now
  confirmed).** `csp.test.ts` fires if `connect-src` is widened to allow `data:`;
  the new `exportGraph.test.ts` fires if the export path is narrowed back to
  `toPng` + `fetch(dataUrl)`. The author correctly identifies the narrowing
  direction as the likelier regression (reads as a cleanup in a rendering util by
  someone with no reason to open `csp.ts`). This is a well-placed bidirectional
  guard over a genuine cross-module invariant.
  Evidence (`exportGraph.test.ts:34-40`): asserts `toBlob` called, `toPng` not
  called, `globalThis.fetch` not called.

- **Internal DRY refactor without surface change.** `renderGraphToBlob` is a new
  *private* helper (`exportGraph.ts:29`) collapsing the duplicated render logic
  from `downloadGraphAsPng` and `graphToPngBlob`. Both public signatures are
  unchanged; the two external consumers (`GraphPanel.tsx:104`,
  `exportAll.ts:64`) bind to the same API as before. This is an implementation-
  local improvement — it does not touch a module boundary.

- **Matcher hardening removes a client-controllable coverage gap.** Dropping the
  `missing:` prefetch exclusion (Y1) means CSP coverage is now purely
  server-determined; no client-supplied request header can opt a response out of
  the policy. The `ProxyConfig` type annotation (Y2) turns matcher-key typos into
  compile errors. Both are structural-hygiene improvements, and the "excludes
  routes only on server-determined criteria" test pins the invariant.
  Evidence (`proxy.test.ts:85-93`): iterates `config.matcher`, asserts no entry
  carries `missing`/`has`.

- **Comment corrections increase legibility without changing behavior.** The
  `csp.ts` docstring (Y7) replaces a phantom third-party enumeration with the
  actual invariant; `exportGraph.ts` (Y8) tightens the `toBlob` accounting to
  note the `where available` fast-path and the library's legacy `toDataURL`
  fallback; `layout.tsx` (Y6) replaces "The cost here is nil" with honest,
  explicitly-unmeasured accounting. These are documentation-accuracy fixes on an
  unchanged code surface.

---

## Findings

No Structural or Coupling findings. Two Informational observations follow — neither
blocks merge, and both are already acknowledged in-tree by the author.

### I1 — Layout dynamic opt-out is an implicit coupling to proxy execution (Informational, CARRIED / pre-existing, not introduced by 1eb081e)

- **Severity:** Informational
- **Status:** CARRIED (originates in the CSP feature commit 9b4e453, not in 1eb081e; 1eb081e only edits the surrounding comment)
- **Boundary:** `app/layout.tsx` ↔ `proxy.ts` runtime ordering
- **Consequence:** The `await headers();` call in `RootLayout` is a load-bearing
  side-effect-free statement whose only purpose is to force dynamic rendering so
  the proxy runs per request and Next can parse the nonce from the request CSP
  header. This is an *implicit* temporal/behavioral coupling: layout and proxy
  are wired through Next's render pipeline, not through an import edge, so a future
  edit that removes the seemingly-inert `await headers()` would silently break
  nonce delivery with no compile-time signal.
- **Evidence verbatim** (`app/layout.tsx`):
  ```
  // This dynamic opt-out is deliberate and load-bearing, not an oversight: a
  // statically prerendered document is built once, so its <script> tags would
  // carry a stale nonce (or none) and be blocked by the CSP on every request
  // after the first.
  ...
  await headers();
  ```
- **Why not higher:** This is intrinsic to per-request-nonce CSP under the Next
  app router — nonces and static rendering are mutually exclusive by
  construction, as the comment correctly states. The coupling is unavoidable
  given the chosen (correct) approach, and it is now documented at length with the
  cost accounting and a "revisit if we drop nonces for hashes" exit. There is no
  cleaner boundary available; flagging only so the implicit edge is on record.
- **Legibility-target:** already met — the load-bearing nature is explained
  inline. No action required.

### I2 — Export fast-path is a runtime choice, not an import-level guarantee (Informational, NEW note, no defect)

- **Severity:** Informational
- **Status:** NEW (the nuance was added by 1eb081e's Y8 comment retighten)
- **Boundary:** `exportGraph.ts` → `html-to-image` library internals ↔ `csp.ts` `connect-src`
- **Consequence:** The CSP-safety of the export path depends on `toBlob` taking
  its `canvas.toBlob()` fast path. The library retains a legacy `toDataURL`
  fallback and the shared `toCanvas` pipeline may still `fetch()` *same-origin*
  webfonts/images. Same-origin fetches are permitted under `connect-src 'self'`,
  so this is not a violation — but it means the invariant "export never trips CSP"
  rests on library behavior the import cannot statically guarantee.
- **Evidence verbatim** (`exportGraph.ts`):
  ```
  * html-to-image's `toBlob` goes canvas → `canvas.toBlob()` where available, so
  * the final decode stays in-DOM. (The shared `toCanvas` pipeline may still
  * `fetch()` same-origin webfonts and images to inline them — permitted under
  * `connect-src 'self'`, and unchanged from the old path.) The legacy
  * `toDataURL` fallback inside the library reconstructs the base64 round-trip
  * this replaced, so the fast path is a runtime choice, not a guarantee of the
  * import.
  ```
- **Why not higher:** The comment itself is the correction — it *downgrades* a
  prior overclaim ("staying entirely within the DOM") to an accurate one. The
  test (`exportGraph.test.ts`) pins the code-level invariant (we call `toBlob`,
  not `toPng`+`fetch`), which is the part under this repo's control. The library's
  internal fallback is a same-origin operation and CSP-compatible regardless.
  This is an accuracy improvement, not a new risk.
- **Legibility-target:** met — the comment now states the boundary precisely.

---

## Summary Table

| ID | Severity | Boundary | Status | Blocks merge? |
|----|----------|----------|--------|---------------|
| — | Structural | — | none found | — |
| — | Coupling | — | none found | — |
| I1 | Informational | layout ↔ proxy render ordering | CARRIED (pre-existing; comment-only touch in 1eb081e) | No |
| I2 | Informational | exportGraph → library ↔ connect-src | NEW note (accuracy correction, no defect) | No |

**Structural count: 0. Coupling count: 0.** Merge standard (0 Red + 0 Amber) is met from the architecture lens.

---

## Overall Assessment

**Confirmed: 0 Structural.** The range `d86d2dc..HEAD` maintains and slightly
improves architectural health. Dependency direction is correct (wiring → pure
policy, one way). Responsibility boundaries are clean: `csp.ts` owns the policy,
`proxy.ts` owns request wiring, `exportGraph.ts` owns a CSP-compatible render
path, `layout.tsx` owns the dynamic opt-out. No module-boundary breach, no
layering inversion, no ISP or LSP violation, no new public surface.

Commit 1eb081e specifically introduces **no new coupling**. On the contrary, it
*removes* one edge (the dead `x-nonce` seam, grep-confirmed zero readers),
*narrows* one dependency to make it explicit and testable (`buildCsp`'s env is
now an injected required param, so the shipping branch equals the tested branch),
and *adds* a bidirectional guard around the one genuine cross-module invariant
(CSP `connect-src` ↔ export render path). The matcher change closes a
client-controllable coverage gap and the `ProxyConfig` annotation adds
compile-time protection. The only NEW item is an Informational documentation
nuance (I2) that corrects an earlier overclaim — it records a boundary more
precisely rather than introducing one.

All three prior full-2 advisory Coupling items are resolved and confirmed:
- x-nonce dead seam — **DELETED**, zero readers remain (confirmed).
- buildCsp env dependency — now a **required param**, shipping branch tested (confirmed).
- CSP↔export invariant — **now guarded both directions** via new `exportGraph.test.ts` (confirmed).

## Goal-Alignment Note

The stated goal was a verification pass confirming 0 Structural and surfacing any
NEW coupling from commit 1eb081e. Result: **0 Structural confirmed; 0 new
Coupling.** The one NEW item is Informational (I2, a documentation-accuracy
correction with no defect). The three carried Coupling concerns are all closed
and independently confirmed by grep and by reading the shipping code, not merely
by trusting the commit message. From the architecture lens this branch satisfies
the 0R+0A merge standard.
