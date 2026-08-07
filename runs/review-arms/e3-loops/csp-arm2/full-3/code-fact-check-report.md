# Code Fact-Check Report (Merged, k=3)

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm2 (branch e3/csp-arm2)
**Scope:** `git diff d86d2dc..HEAD` (HEAD = 2544a19) — app/layout.tsx, app/lib/utils/exportGraph.ts, app/lib/utils/exportGraph.test.ts, proxy.ts, proxy.test.ts, plus commit-message claims in range. Loop-owner override honored in all replicates: 9b4e453's verification claim treated as accepted immutable history; only 2544a19's waive documentation verified.
**Checked:** 2026-08-06
**Commit:** 2544a19
**Replication:** k=3
**Merge rule:** mechanical collation; clusters = same file, ±5 lines, same assertion; most-severe verdict wins (Incorrect(high) > Incorrect(med) > Incorrect(low) > Stale > Mostly accurate > Unverifiable > Verified).
**Total clusters:** 17
**Summary:** 12 verified, 4 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log: `docs/reviews/hallucination-patterns.md` does not exist in the worktree (all replicates concur); no new fabrication patterns qualified for logging, and worktree writes are prohibited for this run.

---

## Cluster 1: layout.tsx — routes must render per request; Next takes the nonce from the request's CSP header and stamps it on bootstrap script tags; nothing here reads it directly

**Location:** `app/layout.tsx:21-26`
**Type:** Behavioral / Architectural
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (High) · r2: Verified (High) · r3: Verified (High)

Unanimous. All three replicates quote Next 16.2.4's renderer reading the nonce from the incoming request's CSP header (`node_modules/next/dist/server/app-render/app-render.js:166-167` via `getScriptNonceFromHeader`), confirm proxy.ts sets that request header (`requestHeaders.set("Content-Security-Policy", csp)`), and confirm the absence claim — no `headers()` call, no `next/headers` import, no nonce read in the layout; the diff adds only `export const dynamic = "force-dynamic";`.

**Evidence (union):** `app/layout.tsx:1-27`, `proxy.ts:44-50`, `node_modules/next/dist/server/app-render/app-render.js:166-167`, `node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:18-26`, `node_modules/next/dist/server/app-render/required-scripts.js`

---

## Cluster 2: exportGraph.ts — `fetch(dataUrl)` would be a `connect-src` fetch; CSP sets `connect-src 'self'`, which refuses `data:`; decoding keeps the directive tight

**Location:** `app/lib/utils/exportGraph.ts:16-21`
**Type:** Behavioral / Configuration
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (High) · r2: Verified (High) · r3: Verified (High)

Unanimous. `"connect-src 'self'",` quoted at proxy.ts:29 in all replicates; both former `fetch(dataUrl)` call sites replaced by `dataUrlToBlob` (exportGraph.ts:54 and :65/66); no `fetch(` of a data URL remains. The `connect-src`-governs-`fetch()` and `'self'`-rejects-`data:` halves are CSP3 spec semantics (paraphrased in all replicates).

**Evidence (union):** `app/lib/utils/exportGraph.ts:14-66`, `proxy.ts:29`

---

## Cluster 3: exportGraph.test.ts — "1x1 transparent GIF — the shape toPng returns (base64 image data URL)" (and test names match assertions)

**Location:** `app/lib/utils/exportGraph.test.ts:9-39` (fixture comment at :10)
**Type:** Reference / Behavioral
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (High) · r2: Verified (High) · r3: Verified (High)

Unanimous. `toPng` returns `canvas.toDataURL()` (quoted from installed html-to-image by r1 and r2), which yields a base64 image data URL — the claimed *shape*. The fixture is genuinely a 1x1 GIF (byte-level GIF89a header/trailer assertions pass, per the 234/234 run). r3 additionally verified each test name against its body and the implementation branches (`isBase64` detection, parameter dropping, non-`data:` rejection).

**Evidence (union):** `app/lib/utils/exportGraph.test.ts:9-39`, `app/lib/utils/exportGraph.ts:22-33`, `node_modules/html-to-image/lib/index.js:136`, `node_modules/html-to-image/es/index.js:46`, `package.json:19`

---

## Cluster 4: proxy.test.ts — helper docstring: Next encodes forwarded request headers as `x-middleware-request-<lowercased-name>`, names listed in `x-middleware-override-headers`, unpacked before render

**Location:** `proxy.test.ts:5-12`
**Type:** Behavioral / Architectural
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (High) · r2: Verified (High) · r3: Verified (Medium)

Unanimous verdict. All replicates quote the exact encoding loop in `node_modules/next/dist/server/web/spec-extension/response.js:35-39`; lowercasing comes from WHATWG `Headers` iteration. r2 additionally quoted the server-side unpack site (`resolve-routes.js:414`, `'x-middleware-request-' + key`); r1/r3 verified the unpack path by breadth (adapter/router-server modules), hence r3's Medium confidence on that sub-part.

**Evidence (union):** `proxy.test.ts:5-23`, `node_modules/next/dist/server/web/spec-extension/response.js:33-40`, `node_modules/next/dist/server/lib/router-utils/resolve-routes.js:414`, `node_modules/next/dist/server/web/adapter.js`

---

## Cluster 5: proxy.test.ts — style-src test comment: "Required by React style={} attributes, reactflow's inline transforms and KaTeX; removing it silently breaks graph layout and equation sizing"

**Location:** `proxy.test.ts:60-61`
**Type:** Behavioral / Configuration
**Merged verdict:** Mostly accurate (most-severe-wins over 2× Verified)
**Replicate verdicts:** r1: Verified (Medium) · r2: Verified (Medium) · r3: Mostly accurate (Medium)

Disagreement on verdict, agreement on substance. All three replicates verified the dependent-naming half: `style={` attributes appear across 8-10+ component files; `reactflow` (^11.11.4) and `katex` (^0.16.45) are direct dependencies with real usage (ProofGraph.tsx, CausalGraphView.tsx, rehype-katex in LatexRenderer.tsx). All three flagged the same residual: the consequence "removing it silently breaks graph layout and equation sizing" is asserted, not demonstrated — no test removes `'unsafe-inline'` and observes breakage. r1/r2 expressed this as a Medium-confidence qualifier on Verified; r3 docked to Mostly accurate. Most severe wins: Mostly accurate. Comment-precision/calibration only; no error of fact identified by any replicate.

**Evidence (union):** `proxy.test.ts:59-65`, `package.json:21,29-30`, `app/components/panels/GraphPanel.tsx`, `app/components/features/output-editing/LatexRenderer.tsx:6`, `app/components/features/proof-graph/ProofGraph.tsx`

---

## Cluster 6: proxy.ts:5 — "CSP proxy (Next.js 16 renamed Middleware → Proxy) with per-request nonces"

**Location:** `proxy.ts:5`
**Type:** Reference / Behavioral
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (High) · r2: not separately checked · r3: Verified (High)

Unanimous among the 2 replicates that checked it (r2 covered the rename evidence inside its runtime-comment claim rather than as a standalone claim). The rename is confirmed by Next 16.2.4's own build strings ("Proxy file", "Proxy always runs on Node.js runtime", `middleware-to-proxy` docs URL). Per-request nonce generation is in `proxy.ts:40` and pinned by the passing "issues a fresh nonce per request" test.

**Evidence (union):** `proxy.ts:5,37-40`, `package.json:23`, `node_modules/next/dist/build/analysis/get-page-static-info.js:575-585`, `proxy.test.ts:108-113`

---

## Cluster 7: proxy.ts:7-10 — nonces + 'strict-dynamic': only nonce-tagged scripts run; scripts they load inherit trust

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (Medium) · r2: Verified (Medium) · r3: Verified (Medium)

Unanimous, uniformly Medium confidence: the policy tokens are quoted from `proxy.ts:25`; the `'strict-dynamic'` semantics (host-source/`'self'` ignored, trust inheritance for programmatically created scripts) are CSP3 spec behavior enforced browser-side, not exercised by repo tests. Next's nonce tagging is established by Cluster 1's mechanism.

**Evidence (union):** `proxy.ts:7-10,22-34`, `node_modules/next/dist/server/app-render/get-script-nonce-from-header.js:18-26`

---

## Cluster 8: proxy.ts:12-17 — post-fix style-src rationale: React `style={}`, reactflow inline transforms, KaTeX emit inline styles; dev also injects styles; Tailwind v4 compiles to a linked stylesheet via `@tailwindcss/postcss`, covered by `'self'`

**Location:** `proxy.ts:12-17`
**Type:** Behavioral / Configuration
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (High) · r2: Verified (High) · r3: Verified (Medium)

Unanimous. This is 2544a19's A3 correction (brief item 2). All replicates confirm the in-tree contradiction flagged in iteration 2 is resolved — proxy.ts:12-13 now names the same three consumers as proxy.test.ts:60-61. The Tailwind parenthetical checks out: `"@tailwindcss/postcss": {}` in postcss.config.mjs, `"@tailwindcss/postcss": "^4"` in package.json, stylesheet entering via `import "./globals.css"` and shipped as a linked stylesheet under `style-src 'self'`. r1 additionally confirmed no contradictory "Tailwind emits inline styles" rationale remains anywhere (`rg "unsafe-inline"` hits only proxy.ts:12,26 and proxy.test.ts:59,63).

**Evidence (union):** `proxy.ts:12-17,26`, `proxy.test.ts:59-65`, `postcss.config.mjs:2-4`, `app/layout.tsx:3`, `package.json:36,49`, `CLAUDE.md` (Design System)

---

## Cluster 9: proxy.ts:19-20 — "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party"

**Location:** `proxy.ts:19-20`
**Type:** Architectural
**Merged verdict:** Mostly accurate
**Replicate verdicts:** r1: Mostly accurate (High) · r2: Mostly accurate (High) · r3: Mostly accurate (High)

Unanimous. The load-bearing sufficiency half holds in all replicates: Anthropic/OpenRouter calls live in server-side `app/lib/llm/` modules (no `"use client"` directives), imported only from `app/api/*/route.ts` handlers; no client-side fetch targets anything but relative `/api/...` paths. The unanimous imprecision: **OpenAlex appears nowhere in the repository except this comment** — `rg -i openalex` outside node_modules hits only proxy.ts:19, and `git log -S openalex` returns only 9b4e453, the commit that introduced the comment (r2). Phantom third-party enumeration entry; security conclusion unaffected. Known-open amber carried from iteration 2, explicitly out of scope for 2544a19 ("Remaining amber and green findings are out of scope for this pass"). Not a fabricated-symbol hallucination (names an external service, not a code symbol), so not log-qualifying (r2).

**Evidence (union):** `proxy.ts:19-20`, `app/lib/llm/callLlm.ts:1-7,164`, `app/lib/llm/streamLlm.ts:87-91,249`, `app/api/` (import graph), `app/lib/utils/exportGraph.ts:54,65`

---

## Cluster 10: proxy.ts:38-39 — post-fix runtime comment: "Generate a fresh nonce per request. Next 16 proxy always runs on the Node.js runtime, where crypto.randomUUID and Buffer are both available."

**Location:** `proxy.ts:38-40`
**Type:** Behavioral / Configuration / Reference
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (High) · r2: Verified (High) · r3: Verified (High)

Unanimous. This is 2544a19's R1 correction (brief item 1); the iteration-2 "Edge runtime" Incorrect finding is gone ("Edge" no longer appears in proxy.ts — r1). The replacement is verbatim-backed by Next 16.2.4's build source ("Proxy always runs on Node.js runtime.", `get-page-static-info.js:576`) and r2/r3 additionally quote the build unconditionally forcing `runtime: 'nodejs'` for proxy files (`build/index.js:1515-1519`). `Buffer` and `crypto.randomUUID` availability is Node platform behavior consistent with the project's Node 18+ prerequisite; per-request freshness pinned by the passing test.

**Evidence (union):** `proxy.ts:37-40`, `package.json:23`, `node_modules/next/dist/build/analysis/get-page-static-info.js:573-585`, `node_modules/next/dist/build/index.js:1515-1519`, `proxy.test.ts:108-113`, `CLAUDE.md` (Prerequisites)

---

## Cluster 11: proxy.ts:44-48 — Next reads the nonce off the *request* CSP header; response-only is not enough (under 'strict-dynamic' the 'self' source is ignored, app never hydrates); both headers must carry the same policy

**Location:** `proxy.ts:43-48`
**Type:** Behavioral
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (High) · r2: Verified (High) · r3: Verified (High)

Unanimous. Request-header read quoted from `app-render.js:166-167` in all replicates; both header copies set from the single `const csp = buildCsp(nonce)` (proxy.ts:49-50, :58-59); equality pinned by the passing test asserting `expect(forwarded).toBe(response.headers.get("Content-Security-Policy"))`. The `'strict-dynamic'`-ignores-`'self'` consequence is CSP3 spec behavior; the never-hydrates outcome is a browser-runtime consequence whose supporting mechanism chain is fully verified (r1).

**Evidence (union):** `proxy.ts:42-59`, `proxy.test.ts:76-90`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Cluster 12: proxy.ts:51-53 — "Overwrite (not append) so a client-supplied x-nonce cannot be smuggled through to a server component"

**Location:** `proxy.ts:51-54`
**Type:** Behavioral / Invariant
**Merged verdict:** Mostly accurate (most-severe-wins over 2× Verified)
**Replicate verdicts:** r1: Mostly accurate (High) · r2: Verified (High) · r3: Verified (High)

Disagreement on verdict, agreement on mechanism. All three replicates verified the overwrite semantics (`requestHeaders.set("x-nonce", nonce)` on a copy of the incoming headers; `Headers.set` replaces rather than appends) and the passing attacker-scenario test (`"x-nonce": "attacker-controlled"` asserted `not.toContain`). r1's imprecision, carried from iteration 2: **no server component reads x-nonce** — outside proxy.ts and its test, `x-nonce` appears nowhere in `app/` (r3's Cluster-1 evidence independently confirms the empty grep). The protected consumer is hypothetical wiring; the defensive claim is correct for any future consumer but describes a data flow that currently terminates nowhere. Known-open finding, explicitly left open by 2544a19's scope note. Most severe wins: Mostly accurate.

**Evidence (union):** `proxy.ts:49-54`, `proxy.test.ts:96-107`

---

## Cluster 13: proxy.ts:60-65 — matcher comment: CSP on page navigations only; skip API routes (no HTML), Next static assets (no scripts to nonce), and prefetches (would burn a nonce on a request that may never paint)

**Location:** `proxy.ts:60-65`
**Type:** Configuration
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (High) · r2: Verified (High) · r3: Verified (High)

Unanimous. The matcher's negative lookahead (`api|_next/static|_next/image|favicon.ico`) and the two `missing` prefetch-header clauses implement exactly the three stated exclusions; all replicates quote the config. r1 notes the comment's "static assets" fairly summarizes `_next/image` and `favicon.ico` as well.

**Evidence (union):** `proxy.ts:60-75`

---

## Cluster 14: commit 2544a19 — R2 waive documentation for 9b4e453's verification claim (loop-owner override: verify documentation existence and accuracy only)

**Location:** commit 2544a19 (message body); referenced history: 9b4e453, d90d6bb, 99e1229
**Type:** Reference / Behavioral
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (High) · r2: Verified (High) · r3: Verified (High)

Unanimous, and unanimously scoped per the loop-owner override: 9b4e453's claim is ACCEPTED as immutable history and is NOT re-issued as a fresh finding in any replicate; only the waive documentation was checked. All checkable points verify across all three replicates:

1. **Quote fidelity** — 2544a19's quotation of 9b4e453 ("Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates") matches the historical message character-for-character apart from a hard line wrap.
2. **Mechanism accuracy** — at 9b4e453 and d90d6bb the policy was set only on the response (`git show` of both historical blobs: request headers got only `x-nonce`); Next reads the nonce exclusively from the request CSP header (`app-render.js:166-167`), so `nonce` was `undefined` during render at those revisions.
3. **Rubric recording** — iteration-2 rubric row R2 ("**Unfixable — history.** Practical disposition is this rubric acknowledgment, not a code change." — `full-2/code-review-rubric.md:41`) and the A15 cross-reference (`:63`) both exist and match.
4. **Fix attribution** — 99e1229 introduced the request-side `requestHeaders.set("Content-Security-Policy", csp)` now at proxy.ts:50, asserted by proxy.test.ts:81-89.

r3 additionally notes 2544a19's own Notes paragraph transparently flags the waive as a disposition, not a fix — an accurate self-description.

**Evidence (union):** commit messages 2544a19, 9b4e453, d90d6bb, 99e1229; `git show 9b4e453:proxy.ts`; `git show d90d6bb:proxy.ts`; `node_modules/next/dist/server/app-render/app-render.js:166-167`; `/workspace/runs/review-arms/e3-loops/csp-arm2/full-2/code-review-rubric.md:30,41,63`

---

## Cluster 15: commit 2544a19 — R1/A3 disposition claims ("Comment-only fix at proxy.ts:35-36"; "Next's own build error says so verbatim"; "rationale at proxy.ts:12-14 … aligned with proxy.test.ts:59-61"; "All three changes are comments"; rg-ordering aside)

**Location:** commit 2544a19 (message body)
**Type:** Reference / Behavioral
**Merged verdict:** Mostly accurate (most-severe-wins over 2× Verified)
**Replicate verdicts:** r1: Mostly accurate (High) · r2: Verified (High) · r3: Verified (High) — r3 covered this cluster as two claims (R1 paragraph; A3 paragraph), both Verified

Disagreement on verdict, agreement on all substantive points. All replicates confirm: the diff hunks match the commit's descriptions exactly (old lines 35-36 for the Edge-runtime comment, old lines 12-14 for the Tailwind rationale — pre-fix numbering, with the post-fix text landing at :38-39 and :12-17); "Proxy always runs on Node.js runtime" is verbatim in Next's build source; "proxy.test.ts:59-61" correctly locates the test-file rationale; and the change is comment-only (`git show 2544a19 --stat`: `proxy.ts | 13 ++++++++-----`, all hunks in comments). r1's sole imprecision, not checked by r2/r3: the aside **"proxy.ts was the one `rg \"unsafe-inline\"` hits first"** is not reliably true — ripgrep's cross-file output order is nondeterministic (parallel traversal), and a fresh run listed proxy.test.ts first. Immutable commit-message trivia decorating a disposition that stands regardless; no code impact. Most severe wins: Mostly accurate.

**Evidence (union):** `git show 2544a19 -- proxy.ts` (hunks and stat), `proxy.ts:12-17,38-39`, `proxy.test.ts:59-65`, `node_modules/next/dist/build/analysis/get-page-static-info.js:575-585`, `node_modules/next/dist/build/index.js:1515-1519`, `postcss.config.mjs:3`, `package.json:36`

---

## Cluster 16: commit 2544a19 — verification block: "npx vitest run -> 26 files / 234 tests pass (unchanged); npx tsc --noEmit clean; npm run lint clean (2 pre-existing warnings in app/page.tsx, untouched)"

**Location:** commit 2544a19 (message body)
**Type:** Reference / Configuration
**Merged verdict:** Verified
**Replicate verdicts:** r1: Verified (High) · r2: Verified (High) · r3: Verified (High)

Unanimous, and independently re-executed live by each replicate at HEAD (= 2544a19, an exact replication): `npx vitest run` → `Test Files 26 passed (26)` / `Tests 234 passed (234)` in all three runs; `npx tsc --noEmit` exited 0 with empty output in all three; `npm run lint` → `✖ 2 problems (0 errors, 2 warnings)`, both `react-hooks/exhaustive-deps` at app/page.tsx:209:6 and :271:6, and app/page.tsx is absent from the d86d2dc..HEAD diff. "(unchanged)" consistent with 99e1229's 234 count; "no test outcome could move" sound given the comment-only diff (Cluster 15).

**Evidence (union):** live vitest/tsc/eslint runs of 2026-08-06 (three independent executions); `git show 2544a19`; `git log d86d2dc..HEAD`; `git diff --stat d86d2dc..HEAD`; `app/page.tsx:209,271`

---

## Cluster 17: commits 9b4e453 / d90d6bb — "Layout reads headers() to opt out of static rendering"

**Location:** commit 9b4e453 message (echoed by d90d6bb)
**Type:** Staleness
**Merged verdict:** Stale
**Replicate verdicts:** r1: not separately checked · r2: not separately checked (noted in scope as rubric A14/A15 territory) · r3: Stale (High)

Checked as a standalone claim only by r3; r1 and r2 both reference the same fact inside their Cluster-14 waive verification (A15 cross-reference), consistent with r3's verdict. True when written; superseded by 99e1229's `export const dynamic = "force-dynamic"` — the layout now contains no `headers()` call or `next/headers` import. Immutable commit-message history, already recorded as rubric A15 and cited by 2544a19's R2 paragraph. Awareness only; no action possible or required.

**Evidence (union):** commit 9b4e453 message, commit d90d6bb message, `app/layout.tsx:1-4,26`, `/workspace/runs/review-arms/e3-loops/csp-arm2/full-2/code-review-rubric.md:63`

---

## Claims Requiring Attention

### Incorrect
- None. (Unanimous across k=3: both iteration-2 Incorrect comment findings — Edge-runtime comment, Tailwind style-src rationale — are fixed and verified; the sole remaining red-class item, 9b4e453's verification claim, is covered by the loop-owner's accepted-immutable-history override with accurate waive documentation, Cluster 14.)

### Stale
- **Cluster 17** (commits 9b4e453/d90d6bb messages): "Layout reads headers() to opt out of static rendering" — superseded by 99e1229's `force-dynamic`. Immutable history, already recorded as rubric A15; awareness only. (r3 only; consistent with r1/r2's A15 cross-checks.)

### Mostly Accurate
- **Cluster 9** (`proxy.ts:19-20`): unanimous 3/3 — the `connect-src 'self'` sufficiency argument holds, but the comment names OpenAlex, which appears nowhere else in the repository (and nowhere in the branch's ancestry — `git log -S openalex` returns only the comment-introducing commit). Phantom third-party enumeration entry; security conclusion unaffected. Known-open amber, explicitly out of scope for 2544a19. One-word comment fix if a future pass touches the file.
- **Cluster 12** (`proxy.ts:51-53`): most-severe-wins (r1 MA vs. r2/r3 Verified) — x-nonce overwrite semantics are correct and tested, but no server component reads x-nonce anywhere; the protected consumer is hypothetical wiring. Known-open finding carried from iteration 2, explicitly left open by 2544a19's scope note.
- **Cluster 15** (commit 2544a19 body): most-severe-wins (r1 MA vs. r2/r3 Verified) — the aside "proxy.ts was the one `rg \"unsafe-inline\"` hits first" is not reliably true (ripgrep cross-file ordering is nondeterministic). Immutable commit-message trivia; all substantive disposition claims verified by all replicates; no code impact.
- **Cluster 5** (`proxy.test.ts:60-61`): most-severe-wins (r3 MA vs. r1/r2 Verified-with-Medium-confidence) — dependents verified unanimously, but "removing it silently breaks graph layout and equation sizing" is a runtime consequence asserted, not demonstrated by any test. Calibration note only.

### Unverifiable
- None.

## Verdict stability

- **Clusters:** 17. **Fully covered (k=3):** 15; Cluster 6 covered by r1/r3 only, Cluster 17 by r3 only (both consistent with the non-covering replicates' embedded evidence).
- **Unanimous verdicts:** 14/17 (82%) — including unanimous Mostly accurate on Cluster 9 (the OpenAlex phantom, the most stable non-Verified finding) and unanimous Verified on all mechanism-critical clusters (1, 10, 11, 14, 16).
- **Split verdicts (3):** Clusters 5, 12, 15 — each split 1 Mostly accurate vs. 2 Verified (or Verified-with-qualifier). In all three splits the replicates agree on the underlying facts and differ only on whether a residual imprecision docks the verdict or is expressed as a confidence qualifier. Most-severe-wins promotes each to Mostly accurate; none is behavioral, none blocks.
- **Verdict-class stability on the red/stale axis:** perfect — 0 Incorrect and 0 Unverifiable in every replicate; the single Stale is immutable-history, found by the replicate with the widest claim sweep and corroborated by the others' A15 references.
- **Live re-execution stability:** the 2544a19 verification figures (26 files / 234 tests, tsc clean, exactly 2 lint warnings at app/page.tsx:209:6 and :271:6) reproduced identically in three independent runs.

## Goal-Alignment Note

- **Answered (all four brief items, unanimous across k=3):** (1) Post-fix runtime comment at proxy.ts:38-39 → Verified, High, 3/3 — "Proxy always runs on Node.js runtime" is verbatim in Next 16.2.4's build source, and the build forces `runtime: 'nodejs'` for proxy files. (2) Post-fix style-src rationale at proxy.ts:12-17 → Verified 3/3 — now agrees with proxy.test.ts:60-61 and with the actual dependents (React `style={}`, reactflow, KaTeX; Tailwind v4 correctly described as a linked stylesheet via `@tailwindcss/postcss`); the iteration-2 in-tree contradiction is resolved. (3) 2544a19's commit-body claims → Clusters 14-16: R1/A3 dispositions and line references accurate; R2 waive documentation exists and is accurate on every checkable point (quote fidelity, mechanism/falsity analysis, rubric R2 and A15 rows, 99e1229 fix attribution); verification figures reproduced live by all three replicates. (4) Full comment sweep of the changed files → Clusters 1-13: connect-src enumeration (OpenAlex phantom persists, unanimous), x-nonce comment (hypothetical consumer, r1), layout/matcher/strict-dynamic/nonce-delivery/test-file comments all Verified.
- **Loop-owner override (9b4e453 waive):** honored identically in all three replicates — the historical verification claim is treated as accepted-immutable-history, not re-issued as a fresh finding; each replicate independently verified only that 2544a19's waive documentation exists and is accurate, and each found that it does (Cluster 14, Verified 3/3). Whether the waive is an acceptable loop-termination disposition remains the loop owner's decision; this report confirms only that the documentation is accurate.
- **Out of scope (union):** whether the persisting Mostly-accurate comment impurities must be fixed before termination (all were explicitly dispositioned as open ambers by 2544a19 and none is Incorrect or Stale in the working tree); browser-level end-to-end confirmation of hydration under the enforced policy (unit-testable surface fully covered; residual gap unchanged from iteration 2); whether the CSP policy is the right policy, and review-quality/severity-mapping judgments (critic and rubric territory); amber/green findings outside the changed-file comment set (e.g., rubric A14).
- **Escalate: Nothing — unanimous, 3/3.** Every replicate independently concluded with zero Incorrect and zero Stale claims in the working tree at HEAD: both iteration-2 Incorrect findings are fixed and verified, the sole red-class item is covered by the loop-owner override with accurate waive documentation, and the surviving non-Verified verdicts are non-blocking comment impurities (plus one immutable-history Stale already recorded as rubric A15). On comment accuracy, this range supports loop termination.
