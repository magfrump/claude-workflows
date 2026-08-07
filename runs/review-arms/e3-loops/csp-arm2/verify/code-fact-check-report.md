# Code Fact-Check Report (merged)

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm2 (branch `e3/csp-arm2`)
**Commit:** ab4dbdb
**Replication:** k=3 (mechanical merge of `code-fact-check-report-r1.md`, `-r2.md`, `-r3.md`)
**Scope:** `git diff d86d2dc..HEAD` — `app/layout.test.ts`, `app/layout.tsx`, `app/lib/utils/dataUrl.ts`, `app/lib/utils/dataUrl.test.ts`, `app/lib/utils/exportGraph.ts`, `proxy.ts`, `proxy.test.ts`; plus the `ab4dbdb` commit-message verification block and (advisory) `csp-arm2/amber-dispositions.md` ACK claims
**Checked:** 2026-08-06
**Total clusters:** 23 (22 substantive + 1 accepted-immutable override)
**Summary:** 15 verified, 2 mostly accurate, 0 stale, 0 incorrect, 5 unverifiable; 1 accepted-immutable override (not counted as a finding)

**Merge method:** Claims across replicates were clustered by (same file, ±5 lines, same assertion). Each cluster's verdict is the most-severe replicate verdict under the ordering Incorrect(high) > Incorrect(med) > Incorrect(low) > Stale > Mostly accurate > Unverifiable > Verified. Each entry records the per-replicate verdicts. No new analysis was performed; this is collation only.

**Loop-owner overrides honored (not re-raised as fresh findings):** `9b4e453`'s superseded historical verification claim and the A15/A17 immutable-history items are accepted-immutable per loop-owner override (Cluster 23). ACKs A7/A8/A9/A11 were spot-checked for factual accuracy across replicates and are not re-raised.

---

## Cluster 1: "`next/font/google` is a build-time loader that the Next compiler rewrites; it throws when called from a plain module graph, so it is stubbed here."

**Location:** `app/layout.test.ts:3-8`
**Type:** Behavioral / Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (Medium) · r2 Verified (High) · r3 Unverifiable (Medium)

r2 found the unmocked loader throws unconditionally (`node_modules/next/dist/compiled/@next/font/google/index.js:7-15`) and the `node_modules/next/font/google/index.js` shim is 0 bytes; r1 confirmed the stub's exported names (`EB_Garamond`, `Geist_Mono`) match the layout's real imports and the suite runs green with the mock. r3 held the throw-on-plain-import behavior itself Unverifiable without a mutation run (removing `vi.mock`), which no replicate performed (no worktree writes). Most-severe verdict: Unverifiable. The stub's stated non-purpose (nothing asserts about fonts) is accurate across all three.

**Evidence:** `node_modules/next/dist/compiled/@next/font/google/index.js:1-15`, `app/layout.test.ts:9-12`, `app/layout.tsx:2`

---

## Cluster 2: "Nothing else in the suite fails if `export const dynamic` is deleted — this test is that failure."

**Location:** `app/layout.test.ts:16-24`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

The assertion `expect(layout.dynamic).toBe("force-dynamic")` (`app/layout.test.ts:22-23`) genuinely falsifies the export (`app/layout.tsx:34`) — deletion makes `layout.dynamic` `undefined`, statically decidable, not a tautology. Repo-wide grep confirms `app/layout.test.ts` is the sole test binding to the export. The commit's "Mutation-checked: deleting the export turns it red" (A6) was not re-executed (no worktree writes) but is consistent with the static argument.

**Evidence:** `app/layout.test.ts:22-23`, `app/layout.tsx:34`, grep of `app/**/*.test.*` for layout imports

---

## Cluster 3: "Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) and stamps it onto the bootstrap `<script>` tags it emits, so nothing here reads it directly."

**Location:** `app/layout.tsx:21-25`
**Type:** Behavioral / Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (Medium) · r2 Verified (High) · r3 Unverifiable (Medium)

The in-repo half is verified by all three: `proxy.ts` sets `requestHeaders.set("Content-Security-Policy", csp)` and `proxy.test.ts` round-trips the forwarded request header equal to the response header; nothing under `app/` reads a nonce. r2 additionally located Next's renderer reading the request CSP header (`node_modules/next/dist/server/app-render/app-render.js:166-167`). r3 held the "stamps onto emitted bootstrap scripts" half Unverifiable from the unit suite (framework-internal, needs an integration render). Most-severe verdict: Unverifiable for the end-to-end stamping consequence; the forwarding half is verified.

**Evidence:** `node_modules/next/dist/server/app-render/app-render.js:166-167`, `proxy.ts:56-60`, `proxy.test.ts:90-99`, `app/layout.tsx:18-25`

---

## Cluster 4: "This is deliberately broader than the `await headers()` it replaced ... Equivalent today (PPR is not enabled) ... Covered by layout.test.ts."

**Location:** `app/layout.tsx:27-33`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

PPR is not enabled — `next.config.ts:3-5` is empty, no `ppr`/`experimental.ppr` flag anywhere. The replaced mechanism existed: the pre-change layout carried a bare `await headers();` (`git show 9b4e453/99e1229/d90d6bb:app/layout.tsx`). `app/layout.test.ts` covers the export (Cluster 2). The segment-vs-subtree distinction is standard Next semantics, uncontradicted by the repo.

**Evidence:** `next.config.ts:1-7`, `git show 9b4e453:app/layout.tsx`, `app/layout.test.ts:22-23`

---

## Cluster 5: "Lives in its own module so a second consumer can use it without importing `exportGraph.ts`, which pulls `html-to-image` into whatever chunk imports it — the code split `GraphPanel.tsx` dynamic-imports precisely to avoid."

**Location:** `app/lib/utils/dataUrl.ts:1-7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

`exportGraph.ts:6` statically imports `toPng` from `html-to-image`; `dataUrl.ts` has zero imports; `GraphPanel.tsx:102` dynamic-imports `@/app/lib/utils/exportGraph`. All three replicates agree.

**Evidence:** `app/lib/utils/dataUrl.ts:1-38`, `app/lib/utils/exportGraph.ts:6`, `app/components/panels/GraphPanel.tsx:102`

---

## Cluster 6: "`fetch(dataUrl)` is the shorter spelling but is a `connect-src` fetch, which the app's CSP refuses ... see the connect-src note in `proxy.ts`."

**Location:** `app/lib/utils/dataUrl.ts:12-16`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

`proxy.ts` carries `"connect-src 'self'"`; per CSP3 a `fetch()` of a `data:` URL is governed by `connect-src` and `'self'` does not match the `data:` scheme, so it is refused. The cross-reference note is live in `proxy.ts`. All three agree.

**Evidence:** `app/lib/utils/dataUrl.ts:9-16`, `proxy.ts:24-27,33-36`

---

## Cluster 7 (disposition A5): "Moved `dataUrlToBlob` to `app/lib/utils/dataUrl.ts` ... git mv'd its test to dataUrl.test.ts. Behaviour byte-identical; all five existing cases still pass."

**Location:** `csp-arm2/amber-dispositions.md` / `ab4dbdb` commit message; `app/lib/utils/dataUrl.ts:17-38`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

Function body is character-identical to the pre-move copy (empty diff vs `2544a19`/`ab4dbdb~1:app/lib/utils/exportGraph.ts`); only the docstring changed. Test rename recorded as `R096 app/lib/utils/exportGraph.test.ts → app/lib/utils/dataUrl.test.ts`, sole content delta the import path. Both call sites resolve (`exportGraph.ts:8,25,36`); `tsc --noEmit` exit 0; all five cases pass.

**Evidence:** `git log --follow --name-status -- app/lib/utils/dataUrl.test.ts`, `git show 2544a19:app/lib/utils/exportGraph.ts`, `app/lib/utils/dataUrl.ts:17-38`, `app/lib/utils/exportGraph.ts:8,25,36`

---

## Cluster 8: "Next encodes them onto the response as `x-middleware-request-<lowercased-name>`, with the overridden names listed in `x-middleware-override-headers` ... PINNED TO A NEXT INTERNAL: verified against next@16.2.4."

**Location:** `proxy.test.ts:5-24`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

Version pin exact (`package.json:23` and `node_modules/next/package.json` both `16.2.4`). Encoding confirmed empirically: the forwarding helper recovers a value byte-equal to the response CSP and the canary test (`x-middleware-override-headers` truthy) is green — impossible if the described transport were wrong. Both header names are Next-private.

**Evidence:** `package.json:23`, `node_modules/next/package.json:3`, `proxy.test.ts:24-34,90-99,113-121`

---

## Cluster 9: "Nothing under app/ reads x-nonce; Next takes the nonce from the request CSP header asserted above." (twin: `proxy.ts` "has *ever* read")

**Location:** `proxy.test.ts:101-106` / `proxy.ts:62-66`
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

Repo-wide `rg -n "x-nonce"` outside `node_modules` hits only `proxy.ts` comments and `proxy.test.ts`. The stronger historical "ever" form holds: `git log -S "x-nonce" -- app/` finds the string only in comments (never `headers().get("x-nonce")`). Deletion safe: `expect(forwardedRequestHeader(run(), "x-nonce")).toBeNull()` passes; CSP request-forwarding via `NextResponse.next({ request: { headers } })` untouched.

**Evidence:** `proxy.ts:56-70`, `proxy.test.ts:101-107`, `git log -S "x-nonce" -- app/`, `git show 9b4e453:app/layout.tsx`

---

## Cluster 10: "Approximates Next's compilation of the `source` pattern ... a plain RegExp agrees with path-to-regexp on every path asserted here (checked against next/dist/compiled/path-to-regexp at next@16.2.4)."

**Location:** `proxy.test.ts:120-131`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

All three re-executed both engines against the 12 asserted paths and got identical results: `/`, `/graph`, `/logo.svg`, `/does-not-exist`, `/apidocs`, `/api-status`, `/favicon.ico.map` match; `/api`, `/api/formalization/lean`, `/_next/static/chunk.js`, `/_next/image`, `/favicon.ico` excluded. No `missing:`/`has` clause remains.

**Evidence:** `proxy.ts:85-92`, `proxy.test.ts:120-178`, runtime execution of both regex engines

---

## Cluster 11: "The matcher used to skip requests carrying client-controlled prefetch headers, shipping a document whose bootstrap scripts had no nonce."

**Location:** `proxy.test.ts:119-136` (historical)
**Type:** Staleness / Reference
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 not separately assessed · r3 Verified (High)

The prior matcher (ancestor `2544a19`/`ab4dbdb~1`) carried `missing: [{ next-router-prefetch }, { purpose: prefetch }]`; both are client-settable request headers. HEAD's matcher has no `missing`/`has` clause, and a prefetch request still receives the CSP (`proxy.test.ts:119-136`, passing).

**Evidence:** `git show ab4dbdb~1:proxy.ts`, `proxy.ts:85-92`, `proxy.test.ts:119-145`

---

## Cluster 12: "Why `style-src 'unsafe-inline'`: React `style={}` attributes, reactflow's inline transforms and KaTeX all emit inline styles at runtime ... (Tailwind v4 compiles to a linked stylesheet via `@tailwindcss/postcss`, covered by `'self'`.)"

**Location:** `proxy.ts:12-18`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** Medium
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (Medium) · r3 Verified (Medium)

Named dependencies all present (`package.json`: `katex ^0.16.45`, `reactflow ^11.11.4`, `@tailwindcss/postcss ^4`, `tailwindcss ^4`). Runtime inline-style emission is documented third-party behavior, uncontradicted by the repo but not statically checkable — hence merged confidence Medium (r2/r3).

**Evidence:** `proxy.ts:12-18`, `package.json:16-49`

---

## Cluster 13: "This block is the single authoritative rationale for the CSP directives. Other files that touch a directive point here rather than restating it."

**Location:** `proxy.ts:19-23`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

`rg -n "unsafe-inline"` (and `style-src`) outside `node_modules` hits only `proxy.ts` and `proxy.test.ts`. Test copy reduced to a pointer (`proxy.test.ts` "see the style-src note in proxy.ts (authoritative copy)"); `dataUrl.ts` defers to the connect-src note. No third restatement remains.

**Evidence:** `proxy.ts:12-27`, `proxy.test.ts:57-77`, `app/lib/utils/dataUrl.ts:12-16`

---

## Cluster 14: "`connect-src 'self'` is sufficient because every third-party call (Anthropic, OpenRouter) originates from a Next route handler on the server; the browser only ever talks to same-origin `/api/...` paths."

**Location:** `proxy.ts:24-26`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

All three re-enumerated every network primitive in non-test `app/`: every browser-side call targets same-origin `/api/...` (analytics, verification/lean, explanation/lean-error, refine/context, decomposition/extract, and `ARTIFACT_ROUTE` values — all `/api/formalization/...`). Vendor calls (`OPENROUTER_API_URL`, Anthropic SDK) live in `app/lib/llm/callLlm.ts` / `streamLlm.ts`, imported only by server-side route handlers; `LEAN_VERIFIER_URL` fetched only inside `app/api/verification/lean/route.ts`. No `XMLHttpRequest`/`EventSource`/`WebSocket`/`sendBeacon`/Worker usage. The OpenAlex phantom is gone (`rg -in openalex` zero hits; A12 fix confirmed).

**Evidence:** `proxy.ts:24-33`, `app/lib/types/artifacts.ts:192-198`, `app/lib/llm/callLlm.ts:164`, `app/lib/llm/streamLlm.ts:249`, `app/api/verification/lean/route.ts:21`, repo-wide greps

---

## Cluster 15: "CSP proxy (Next.js 16 renamed Middleware → Proxy)."

**Location:** `proxy.ts:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 not separately assessed

Next's own build code carries the rename + deprecation warning (`node_modules/next/dist/build/index.js:645-651`) with `PROXY_FILENAME = 'proxy'` (`node_modules/next/dist/lib/constants.js:289`).

**Evidence:** `node_modules/next/dist/lib/constants.js:289`, `node_modules/next/dist/build/index.js:645-651`, `proxy.ts:5`

---

## Cluster 16: "Next 16 proxy always runs on the Node.js runtime, where crypto.randomUUID and Buffer are both available."

**Location:** `proxy.ts:45-49`
**Type:** Behavioral / Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Unverifiable (Medium)

r1/r2 found the build unconditionally assigns Node runtime to a proxy file (`node_modules/next/dist/build/index.js:1515-1519`, `isProxyFile(page)` disjunct forces `runtime: 'nodejs'`) and both globals executed in the test run. r3 held the universal "always" (no edge-runtime opt-out in this Next version) not settleable from the repo. Most-severe verdict: Unverifiable; no runtime override is configured (`next.config.ts` empty, `proxy.ts` exports no `runtime`).

**Evidence:** `node_modules/next/dist/build/index.js:1515-1519`, `proxy.ts:47-49`, `next.config.ts:1-7`

---

## Cluster 17: "Setting it only on the response is not enough: under 'strict-dynamic' the 'self' source is ignored, so un-nonced bootstrap scripts are refused and the app never hydrates. Both headers must carry the same policy."

**Location:** `proxy.ts:52-58`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (Medium) · r2 Verified (Medium) · r3 Unverifiable (Medium)

The CSP3 spec half is correct across all three: `'strict-dynamic'` causes host/`'self'` sources in `script-src` to be ignored. The both-headers invariant is test-pinned (`expect(forwarded).toBe(response.headers.get("Content-Security-Policy"))`, passing). r3 rated the Next-renderer + "never hydrates" consequence Unverifiable (framework-internal, needs integration render) — the residual all rounds carried. Most-severe verdict: Unverifiable for the hydration consequence; the header-equality and spec halves are verified.

**Evidence:** `proxy.ts:31,52-60`, `proxy.test.ts:90-99`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Cluster 18: "form-action ... Does not fall back to default-src. The app posts to no cross-origin form target, so 'self' is free and closes the dangling-markup / injected-`<form>` path."

**Location:** `proxy.ts:38-42`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Verified (High) · r3 Verified (High)

Directive present (`"form-action 'self'"`); the exact-key assertion was widened 9→10 keys including `"form-action"` with a value assertion `expect(directives.get("form-action")).toBe("'self'")`, both passing. `form-action` has no `default-src` fallback (CSP3) and needs no script (untouched by `'strict-dynamic'`). No `<form>` element exists under `app/`.

**Evidence:** `proxy.ts:38-43`, `proxy.test.ts:44-64`, `git show ab4dbdb~1:proxy.test.ts`, repo-wide grep

---

## Cluster 19: "Each exclusion is anchored so it cannot swallow a sibling route: `api` only matches /api and /api/..., never a future /apidocs; `favicon.ico` only matches the whole path."

**Location:** `proxy.ts:74-91`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 Mostly accurate (High) · r3 Mostly accurate (High)

r2 and r3 both flagged the universal quantifier "Each exclusion is anchored" as overbroad: `api` (`api(?:/|$)`) and `favicon.ico` (`favicon\.ico$`) are anchored, but `_next/static` and `_next/image` are **unanchored prefixes** — the same compiled regex would also exclude `/_next/staticfoo`, `/_next/image-proxy`. Behavior impact is nil because `/_next/*` is a Next-reserved namespace with no user-defined siblings, so the "cannot swallow a sibling route" consequence still holds; the comment's own examples cite only the two anchored exclusions. r1 verified the matcher behaves as described without flagging the quantifier. Cosmetic precision note, not policy-weakening. Most-severe verdict: Mostly accurate. **This is the one candidate new amber for the merge.**

**Evidence:** `proxy.ts:85-90`, `proxy.test.ts:116-178`, runtime check via `node_modules/next/dist/compiled/path-to-regexp`

---

## Cluster 20: Commit `ab4dbdb` verification block — "npm test 27 files / 240 tests passed (from 26/234); tsc --noEmit exit 0, empty; npm run lint exactly the 2 pre-existing react-hooks/exhaustive-deps warnings at app/page.tsx:209:6 and :271:6."

**Location:** `git show ab4dbdb` (commit message); mirrored in `csp-arm2/amber-dispositions.md:31-36`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 not separately assessed · r2 Mostly accurate (High) · r3 Verified (High)

Both r2 and r3 re-ran the suite (27 files / 240 tests), `tsc --noEmit` (exit 0, empty), and lint (exactly 2 `react-hooks/exhaustive-deps` warnings at `app/page.tsx:209:6` and `:271:6`, a file the change does not touch). r2 graded Mostly accurate solely because the "(from 26/234)" baseline could not be re-executed without checking out `2544a19` (no worktree writes); it is arithmetically consistent (234 + 8 − 2 = 240; 26 + 1 = 27). r3 verified via the same arithmetic reconstruction. Most-severe verdict: Mostly accurate — provenance caveat on the baseline half only; every re-executable claim reproduced exactly.

**Evidence:** `git show ab4dbdb`, executed `vitest`/`tsc`/lint runs 2026-08-06, `git diff 2544a19..ab4dbdb -- proxy.test.ts`

---

## Cluster 21 (disposition A9): "`await headers()` already forced per-request rendering" — `force-dynamic` is rendering-mode-neutral against the immediately preceding commit.

**Location:** `csp-arm2/amber-dispositions.md` (advisory); code at `app/layout.tsx:34`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Verified (High) · r2 not separately assessed · r3 not separately assessed

r1 verified per the loop-owner instruction that ACK justifications be checked without re-raising: the predecessor `await headers();` is on the record (`git show d90d6bb:app/layout.tsx:31`); `headers()` is a dynamic API that opts a segment into per-request rendering, so the render cost predates `force-dynamic`. The owed-measurement framing is consistent with the `next/font/google` build-time fetch (see Cluster 22).

**Evidence:** `git show d90d6bb:app/layout.tsx`, `app/layout.tsx:2,34`, `csp-arm2/amber-dispositions.md`

---

## Cluster 22 (disposition A9): "`next build` fails on next/font/google reaching fonts.googleapis.com, re-failed on three passes. Owed outside the sandbox."

**Location:** `ab4dbdb` commit message (A9)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 not separately assessed · r2 not separately assessed · r3 Unverifiable (Medium)

r3 did not re-run (a `next build` would reproduce a known-failing network fetch and write `.next/` into the worktree). Mechanism plausible and consistent with the repo: `app/layout.tsx:2` imports from `next/font/google`, which fetches font CSS from Google at build time, and the sandbox blocks external network. Accepted ACK (A9); measurement explicitly deferred outside the sandbox.

**Evidence:** `ab4dbdb` commit message (A9), `app/layout.tsx:1-2`

---

## Cluster 23 (ACK justifications A15/A17 — accepted-immutable override): commit messages of `9b4e453`/`d90d6bb` say "Layout reads `headers()`" (superseded, immutable), and `2544a19` carries an unreliable ripgrep-output-order aside (immutable).

**Location:** `csp-arm2/amber-dispositions.md` (advisory); git history
**Type:** Reference / Staleness
**Verdict:** Accepted-immutable override (not counted as a finding)
**Confidence:** High
**Commit:** ab4dbdb
**Replication:** k=3
**Replicate verdicts:** r1 Mostly accurate (High) · r2 accepted-immutable (not re-raised) · r3 accepted-immutable (not re-raised)

Both historical claims exist where stated and are accurately characterized: `9b4e453`'s body "Layout reads headers() to opt out of static rendering" was true when written and is superseded on this tree (`rg -n "headers" app/layout.tsx` zero hits at HEAD); `2544a19`'s ripgrep-order aside describes genuinely nondeterministic parallel-traversal output. **Per the loop-owner override these are accepted-immutable and treated as a considered override, not a fresh finding.** Recorded here for traceability only; excluded from the verdict totals and from Claims Requiring Attention.

**Evidence:** `git show -s 9b4e453`, `git show -s 2544a19`, `app/layout.tsx` (HEAD), `csp-arm2/amber-dispositions.md`

---

## Claims Requiring Attention

### Incorrect

None.

### Stale

None.

### Mostly Accurate

- **Cluster 19** (`proxy.ts:74-91`): "Each exclusion is anchored" is overbroad — `_next/static` / `_next/image` are unanchored prefixes (e.g. `/_next/staticfoo` would also be excluded), while the two exclusions the comment actually names (`api`, `favicon.ico`) are anchored and behave exactly as claimed. Harmless because `/_next/*` is a Next-reserved namespace with no sibling routes; cosmetic precision fix at most, not policy-weakening. Flagged by r2 and r3; the candidate new amber for this merge.
- **Cluster 20** (commit `ab4dbdb` verification block): the "(from 26/234)" baseline test-count is reconstruction-consistent (arithmetic checks; +1 test file, net +6 tests) but was not re-executed (would require a checkout, no worktree writes). Every currently re-executable verification claim (240/240 tests, tsc exit 0, 2 pre-existing lint warnings) reproduced exactly. Provenance caveat only, not a defect.

### Unverifiable

- **Cluster 1** (`app/layout.test.ts:3-8`): whether unmocked `next/font/google` throws under vitest needs a mutation run (remove `vi.mock`); the mock's stated purpose and non-assertions are accurate, and the stub's exported names match the layout's imports.
- **Cluster 3** (`app/layout.tsx:21-25`): Next's renderer consuming the request CSP header and stamping the nonce onto emitted bootstrap scripts is framework-internal; needs an integration render. The in-repo half (request-header forwarding, round-trip test) is verified.
- **Cluster 16** (`proxy.ts:45-49`): "always runs on the Node.js runtime" is a Next 16 runtime-selection claim; r1/r2 found the build forces Node for proxy files, but the universal "no edge opt-out" was not settleable from the repo. Both globals executed in the test run; no runtime override is configured.
- **Cluster 17** (`proxy.ts:52-58`): the "app never hydrates" consequence is a runtime browser outcome not demonstrable statically. The `'strict-dynamic'` spec behavior and the both-headers-equal invariant are verified.
- **Cluster 22** (`ab4dbdb` A9): sandbox `next build` failure not re-attempted (would reproduce a known-failing fetch and dirty the worktree); accepted ACK, measurement owed outside the sandbox.

## Verdict stability

- **Full agreement (all reporting replicates concur):** Clusters 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 18, 21, 22 — 16 clusters (Verified ×14 fully-agreed + Cluster 21/22 single-reporter trivial).
- **Split verdicts (most-severe applied):** 6 clusters —
  - Cluster 1: Verified, Verified, **Unverifiable** → Unverifiable (r3 required a mutation run r1/r2 approximated statically)
  - Cluster 3: Verified, Verified, **Unverifiable** → Unverifiable (r3 held the framework-internal stamping half unverifiable from unit tests)
  - Cluster 16: Verified, Verified, **Unverifiable** → Unverifiable (r3 held the universal "always Node runtime" unsettleable from the repo)
  - Cluster 17: Verified, Verified, **Unverifiable** → Unverifiable (r3 held the "never hydrates" consequence unverifiable)
  - Cluster 19: Verified, **Mostly accurate**, **Mostly accurate** → Mostly accurate (r2+r3 caught the overbroad anchoring quantifier r1 did not flag)
  - Cluster 20: (r1 n/a), **Mostly accurate**, Verified → Mostly accurate (r2 downgraded on the un-re-executed baseline figure)
- **Agreement rate:** 17 / 23 clusters (≈74%) reached identical verdicts across all reporting replicates. The disagreements are systematic, not random: r3 was consistently the most conservative, routing four framework-internal / mutation-gated claims to Unverifiable where r1/r2 accepted the static approximation as Verified; the two Mostly-accurate splits are genuine precision catches (a comment overbreadth and an un-re-executed baseline number). No disagreement crossed into Incorrect or Stale — the 0-red bar is stable across all three replicates.

## Goal-Alignment Note (merged)

- **Answered — all 7 brief items, concordant across replicates.** (1) Matcher anchoring: all three re-executed Next's own `path-to-regexp` at 16.2.4 over the asserted paths — `/apidocs`, `/api-status`, `/favicon.ico.map` covered; `/api`, `/api/...`, `/favicon.ico`, `/_next/*` excluded; no `missing:`/`has` client-header clause remains (Clusters 10, 11, 19). (2) `form-action 'self'` present, exact-key test widened 9→10 with a value assertion (Cluster 18). (3) `x-nonce` deletion safe — zero readers ever under `app/` (historical `-S` search included), CSP request-forwarding intact and round-trip-tested (Clusters 3, 9, 17). (4) `dataUrl.ts` move byte-identical (empty function-body diff), `R096` git rename, both call sites resolve, no dangling import (Clusters 5, 7). (5) `app/layout.test.ts` genuinely falsifies the `force-dynamic` export and is its sole importer (Cluster 2). (6) connect-src invariant re-enumerated across every network primitive — all browser calls same-origin `/api/...`, all vendor calls server-side; OpenAlex phantom gone; style-src rationale has one authoritative owner with pointer-only copies (Clusters 12, 13, 14). (7) Newly-introduced-issue sweep: **0 Incorrect, 0 Stale** across all replicates; the only fresh nuance is the cosmetic "each exclusion is anchored" overbreadth (Cluster 19).
- **Out of scope / owed (concurrent across replicates):** runtime browser verification (nonce stamping, hydration failure mode, prod-build CSP emission — flagged Unverifiable/Medium at Clusters 3, 17); mutation re-execution and baseline test-count re-run at `2544a19` (no worktree writes — Clusters 1, 20); A9's owed TTFB measurement, unobtainable in-sandbox because `next build` needs `fonts.googleapis.com` (Cluster 22).
- **Escalate:** Nothing. The decisive 0-red bar (0 Incorrect / 0 Stale) is stable across k=3. If the loop owner wants literal zero-imprecision comments before merge, the Cluster 19 one-clause tightening ("the exclusions that could collide with an app route — `api`, `favicon.ico` — are anchored") is the only candidate edit; it changes no behavior and no test contradicts it. The A9/A15/A17 accepted-immutable overrides were verified accurate and are not re-raised (Clusters 21, 23).
