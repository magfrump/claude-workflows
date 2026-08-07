# Code Review Rubric

**Scope:** d86d2dc..1eb081e (e3/csp-arm1 verification pass) | **Reviewed:** 2026-08-06 | **Commit:** 1eb081e | **Status:** MEETS 0R+0A (0 🔴 · the sole open 🟡 is the pre-existing, acked force-dynamic waive)

**Pipeline:** code-fact-check (merged k=3, 0 Incorrect / 0 Stale) → security · performance · api-consistency · architecture · ui-visual critics → this synthesis. Merge standard: **0R + 0A**, where an amber closes by fix OR by explicit author ack/waive with justification.

**Severity mapping (unchanged):** Sec Crit/High→🔴, Med→🟡, Low/Info→🟢. Perf Crit→🔴, High/Med→🟡, Low/Info→🟢. API Breaking→🔴, Inconsistent→🟡, Minor/Info→🟢. Arch Structural→🔴, Coupling→🟡, Minor/Info→🟢. FC Incorrect(high)→🔴, else→🟡/🟢. ui advisory→🟢.

---

## ↔️ Iteration Delta (vs. full-2 @ f25d968 → disposition @ 1eb081e)

The full-2 rubric carried **0 red · 9 amber**. The disposition commit `1eb081e` resolved them **8 FIXED · 1 ACKED**. This verification pass independently confirms each disposition held (grep + code read + green suite, not by trusting the commit message).

| Full-2 amber | Disposition | Confirmed this pass by | Critic corroboration |
|---|---|---|---|
| 🟡-1 client-suppliable `missing:` prefetch matcher clause | **FIXED** (deleted whole block; coverage now server-determined) | `config.matcher` carries only `source` regex; `proxy.test.ts` asserts no entry has `missing`/`has` | sec (B1 closed), api (CARRIED-1 CLOSED), arch, perf F2 |
| 🟡-2 untyped `config` export | **FIXED** (`export const config: ProxyConfig`) | `ProxyConfig` is a real `next/server` export; matcher-key typo now fails `tsc` | api (CARRIED-2 CLOSED), arch, FC Claim 21 |
| 🟡-3 export-path invariant unguarded (narrowing direction) | **FIXED** (new `exportGraph.test.ts`: `toBlob` called, `toPng`/`fetch` not, `!blob` throws) | 3 tests present and green | api, arch, sec (B3), FC Claims 8/11 |
| 🟡-4 `buildCsp` env defaulted / untested prod branch | **FIXED** (removed default; `nodeEnv: string \| undefined` required, injected at sole call site) | fail-closed test over `undefined/""/"Development"/"dev"/"test"/"prod"`; `tsc` clean | sec (B4), api, arch, FC Claim 10 |
| 🟡-5 published-but-unread `x-nonce` seam | **FIXED** (write + its tests deleted; clobber test retargeted to load-bearing request CSP header) | grep `x-nonce` → only 2 comments + absence-test (`toBeNull`) | sec, perf F3 RESOLVED, api Change 2, arch, FC Claims 1/14/15/18 |
| 🟡-6 "cost here is nil" overclaim on dynamic opt-out | **FIXED** (comment → honest, explicitly-unmeasured accounting) | verbatim comment now names the two unmeasured numbers; WAIVED decision left intact | perf F1, arch, ui, FC Claims 2/3 |
| 🟡-7 phantom third-party enumeration in `csp.ts` | **FIXED** (replaced with the actual "no browser-side third-party call" invariant) | FC Claim 6 (Mostly accurate — code-location residual only, security conclusion holds) | sec, FC Claim 6 |
| 🟡-8 over-broad "entirely within the DOM" export comment | **FIXED** (retightened: `canvas.toBlob()` where available + same-origin webfont fetch caveat + legacy `toDataURL` fallback) | FC Claim 12 Verified; arch I2 notes it downgrades an overclaim | arch I2, FC Claim 12 |
| 🟡-9 f25d968 commit-message / jsdom scope artifact | **ACKED** (immutable ancestor history; env artifact, not repo state) | FC merge re-confirms suite green; jsdom `MISSING DEPENDENCY` reproduced as env artifact only | FC merge note |

**Do-not-re-raise (per disposition notes):** 🟡-9 commit-message framing; the removed `buildCsp` default (any new caller must pass env); the `x-nonce` reinstate-with-a-consumer rule.

### NEW this pass (findings surfaced by the verification critics, not in full-2)

- **Security:** `form-action` directive absent (Low) → 🟢; `data:` in img-src/font-src (Info) → 🟢.
- **Performance:** F2 — prefetch requests now run the proxy (matcher `missing:` removed), ~0.75 µs/prefetch, deliberate security tradeoff (Low) → 🟢.
- **API:** `renderGraphToBlob` private-helper name vs public sibling `graphToPngBlob` (Low, private, out of public audit) → 🟢.
- **Architecture:** I2 — export fast-path is a runtime choice, not an import-level guarantee (Informational, documentation-accuracy note) → 🟢.

---

## 🔴 Must Fix

_None._ No Critical/High security, no Critical performance, no Breaking API, no Structural architecture, no Incorrect(high) fact-check finding exists in this range.

## 🟡 Must Address

| # | Finding | Source | Location | Disposition |
|---|---|---|---|---|
| A1 | Force-dynamic SSR render per navigation (`await headers()` opts layout out of static rendering; document no longer shared-/CDN-cacheable) | perf F1 (Medium/Amber, CARRIED) | `app/layout.tsx` (`await headers()` in `RootLayout`) | **ACKED / WAIVED** (pre-existing). Author note @ 1eb081e (🟡-6): the WAIVED decision is untouched; only the justifying comment was corrected to honest, explicitly-unmeasured accounting ("one SSR shell render per navigation … accepted because nonces require it, small here because the app is a single `use client` route … Unmeasured: build static/dynamic marker + one TTFB sample"). Per-request nonces and static rendering are mutually exclusive by construction (FC Claim 2, arch I1) — the cost is the goal's price, not overhead to trim. Behavior unchanged from full-2. |

No other Medium/Amber item exists: the perf F2 prefetch cost (Low), the security form-action gap (Low), and the api name nit (Low) all map to 🟢 under the severity mapping and are not amber.

## 🟢 Consider

| # | Finding | Source | Location | Note |
|---|---|---|---|---|
| G1 | `form-action` directive absent — does not inherit from `default-src`, so an injected non-script `<form action=…>` is unrestricted (defense-in-depth) | sec (Low, NEW) | `csp.ts:48-58` | App has no `<form>` and no client third-party call; `form-action 'self'` is safe to add and breaks nothing. One-line directive + test-key extension. |
| G2 | Prefetch navigations now run nonce gen + `buildCsp` (matcher `missing:` removed) | perf F2 (Low, NEW) | `proxy.ts` `config.matcher` | Deliberate: closes a client-header-keyed coverage gap. ~0.75 µs/prefetch, O(1), no I/O. Negligible under load; the cost is the security property. |
| G3 | `data:` permitted in `img-src`/`font-src` | sec (Info, NEW) | `csp.ts:53-54` | Common low-risk carve-out, plausibly needed by KaTeX/next-font/graph export. No change; confirm emitters before any future tighten. |
| G4 | `style-src 'unsafe-inline'` retained | sec (Info, acked carve-out) | `csp.ts:52` | Documented dependents (React `style={{}}`, reactflow, KaTeX, next/font, dev HMR). Accepted, documented residual — not a regression. |
| G5 | Private helper `renderGraphToBlob` vs public sibling `graphToPngBlob` (name-shape mismatch) | api (Low/nit, NEW) | `exportGraph.ts` | Private symbol, outside public-surface audit; non-blocking. `graphToBlob` would have read more consistently. |
| G6 | Layout↔proxy implicit temporal coupling via `await headers()` (no import edge; compile-time-invisible if removed) | arch I1 (Info, CARRIED) | `app/layout.tsx` ↔ `proxy.ts` | Intrinsic to per-request-nonce CSP; documented inline at length. No cleaner boundary; on record only. |
| G7 | Export CSP-safety rests on `toBlob` taking its `canvas.toBlob()` fast path (library retains legacy `toDataURL`; `toCanvas` may `fetch()` same-origin fonts/images, permitted under `connect-src 'self'`) | arch I2 (Info, NEW note) | `exportGraph.ts` → html-to-image ↔ `csp.ts` | Comment is itself the correction (downgrades a prior overclaim). Code-level invariant pinned by test. Accuracy improvement, no defect. |
| G8 | FC comment-precision residuals (Mostly accurate, no edit required) | FC Claims 3/6/17 | `layout.tsx:34-42`, `csp.ts:21-24`, `proxy.ts:49-63` | Claim 3 CDN-cacheability is runtime-only-confirmable (comment self-hedges "Unmeasured"); Claim 6 loose on code-location (fetches live in `app/lib/**`, execute in `app/api/**`) — security conclusion holds; Claim 17 "~0.75 µs" measured ~0.52 µs on-machine (order-of-magnitude, tilde-hedged). Advisory tightenings, not blockers. |

## ↩️ Considered Overrides

No prior overrides matched this diff.

## ✅ Confirmed Good

Grounded in the merged fact-check (k=3, 0 Incorrect / 0 Stale) cross-checked against per-replicate FC verdicts, at **Commit: 1eb081e**:

- **Client-supplied CSP request header is clobbered, not merged** — `requestHeaders.set(...)` (not `.append`); attacker-nonce test proves `nonce-attacker` does not survive to the renderer. Same policy string on request + response; equality asserted. (FC Claims 14/18, sec B1)
- **CSP coverage is purely server-determined** — matcher carries only a `source` regex; no `missing:`/`has:` header condition; invariant test-pinned. (FC Claim 16, api CARRIED-1, arch)
- **Fail-closed env comparison** — `buildCsp(nonce, nodeEnv)` required/undefaulted, compares against the permissive `"development"` value; anything else yields the stricter policy; pinned across six env values; `tsc` clean. (FC Claim 10, sec B4, api, arch)
- **Export path cannot regress to `fetch(data:)`** — `exportGraph.ts` uses `toBlob`; bidirectional guard (`csp.test.ts` fires on `connect-src`→`data:` widening; `exportGraph.test.ts` fires on narrowing back to `toPng`+`fetch`). Public export signatures preserved through the refactor. (FC Claims 8/11/12, sec B3, api Change 5, arch)
- **`x-nonce` seam fully removed** — zero readers repo-wide; write + tests deleted; absence pinned by test; nonce reaches the document via the request CSP header Next parses. Per-request work strictly reduced. (FC Claims 1/15, perf F3, api Change 2, arch)
- **Dependency direction correct and one-way** — `proxy.ts` (wiring) → `csp.ts` (pure policy, imports nothing from app). No new module, public type, or cross-module edge; net coupling *reduced*. (arch)
- **Nonce generation** — `crypto.randomUUID()` (CSPRNG, 122 bits) base64, fresh per request, uniqueness test-confirmed; Node-runtime guarantee for `crypto`/`Buffer` documented and validated. (FC Claims 19/20, sec, perf)
- **`ProxyConfig` typing** — real `next/server` export; matcher typo → compile error; matches `NextConfig` sibling precedent. (FC Claim 21, api CARRIED-2)
- **UI render output identical** — `layout.tsx` changed server-rendering mode only (no markup/CSS/font/class change); `exportGraph.ts` preserves raster params (`pixelRatio: 2`, `#F9F5F1` bg). Export now more likely to succeed under CSP. (ui)
- **Suite green** — 15/15 vitest across the new/changed test files in all three replicates; `tsc --noEmit` exit 0 (r2/r3). jsdom `MISSING DEPENDENCY` reproduced as an env artifact only (acked 🟡-9). (FC merge)

## ⚠️ Unverified Findings

None. Every critic finding is grounded in cited code/tests; the FC merge returned 0 Unverifiable (r2's lone Unverifiable on Claim 17 resolved to Mostly accurate under most-severe-wins). The only inherently un-static-checkable claims (browser CSP enforcement of strict-dynamic, the `data:`-fetch TypeError, the pdfjs console violation, the µs microbenchmark constant) are explicitly scoped out as spec-level/runtime-only and are consistent with cited code.

## ⏭️ Skipped Core Critics

None. All six critics ran this pass: code-fact-check (merged k=3), security, performance, api-consistency, architecture, ui-visual.

---

## 0R+0A Merge Verdict

**MEETS.**

- **0 🔴** — no Critical/High security, no Critical performance, no Breaking API, no Structural architecture, no Incorrect(high) fact-check finding.
- **1 🟡**, fully dispositioned: **A1 (force-dynamic SSR-render waive)** is a pre-existing, author-acked/**WAIVED** amber (justification recorded at 1eb081e, 🟡-6) — it is the goal's necessary price for per-request nonces, not a fresh finding. Its underlying behavior is unchanged; only its comment was made honest.
- Every full-2 amber is closed (8 fixed + 1 acked), each independently confirmed by this pass.
- All NEW findings this pass (form-action, prefetch cost, `data:` sources, private-helper name, arch I2 note) map to 🟢 under the severity mapping and do not gate merge.

**Undispositioned 🟡:** none.
