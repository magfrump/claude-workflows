# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm2 (branch `e3/csp-arm2`)
**Commit:** ab4dbdb
**Scope:** `git diff d86d2dc..HEAD` — `app/layout.test.ts`, `app/layout.tsx`, `app/lib/utils/dataUrl.ts`, `app/lib/utils/dataUrl.test.ts`, `app/lib/utils/exportGraph.ts`, `proxy.ts`, `proxy.test.ts`; amber-disposition claims from `csp-arm2/amber-dispositions.md` (advisory) checked where they assert code facts
**Checked:** 2026-08-06
**Total claims checked:** 18
**Summary:** 17 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

No hallucination pattern log exists in the worktree (`docs/reviews/hallucination-patterns.md` absent); no fabrications found, so none is created.

Note on the historical rule: only ancestors of `ab4dbdb` and this arm's own `csp-arm2/` artifacts were consulted. The loop-owner overrides for `9b4e453`'s message claim and A15/A17 are honored: their justifications were checked for accuracy (Claims 17–18) but are not raised as findings.

---

## Claim 1: "`next/font/google` is a build-time loader that the Next compiler rewrites; it throws when called from a plain module graph, so it is stubbed here."

**Location:** `app/layout.test.ts:3-8`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium

The stub's exported names match the layout's real imports exactly:

```ts
// app/layout.tsx:2
import { EB_Garamond, Geist_Mono } from "next/font/google";
```

```ts
// app/layout.test.ts:10-12
vi.mock("next/font/google", () => {
  const loader = () => ({ variable: "--font-stub", className: "font-stub" });
  return { EB_Garamond: loader, Geist_Mono: loader };
```

That `next/font/google` throws outside the Next compiler is consistent with the suite outcome (paraphrased — no quote available because the claim covers absence of a failure: the full suite passes with the mock in place, 27 files / 240 tests, and the loader's throw-on-plain-import behavior lives in Next's compiled internals, not in this repo). Confidence Medium only because the throw behavior itself was not exercised without the mock (mutating the worktree to try is out of bounds for this pass).

**Evidence:** `app/layout.test.ts:9-12`, `app/layout.tsx:2`, test run output (27 files / 240 tests passed)

---

## Claim 2: "Nothing else in the suite fails if `export const dynamic` is deleted — this test is that failure."

**Location:** `app/layout.test.ts:16-24`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High

The test asserts the exported value directly:

```ts
// app/layout.test.ts:22-23
const layout = await import("./layout");
expect(layout.dynamic).toBe("force-dynamic");
```

and the export it pins exists:

```ts
// app/layout.tsx:34
export const dynamic = "force-dynamic";
```

Deleting the export makes `layout.dynamic` evaluate to `undefined`, which cannot satisfy `toBe("force-dynamic")` — this is statically decidable, no runtime mutation needed. The "nothing else fails" half: a repo-wide grep for other tests reading `layout.dynamic` or importing `app/layout` returns only this file (paraphrased — no quote available because the claim covers absence of code: `rg -l 'from "\./layout"|app/layout' --glob '*.test.*'` matches `app/layout.test.ts` alone). The disposition table's mutation-check claim (A6, `amber-dispositions.md:16,35`) is consistent with this static analysis, though the mutation run itself was not re-executed (no worktree writes permitted).

**Evidence:** `app/layout.test.ts:22-23`, `app/layout.tsx:34`

---

## Claim 3: "Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) and stamps it onto the bootstrap `<script>` tags it emits, so nothing here reads it directly."

**Location:** `app/layout.tsx:21-25`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

The proxy does set the request-side header the comment names:

```ts
// proxy.ts:56-57
const requestHeaders = new Headers(request.headers);
requestHeaders.set("Content-Security-Policy", csp);
```

and nothing in the layout (or anywhere under `app/`) reads a nonce header — `rg -n "x-nonce|nonce" app/` returns only the layout comment itself and `layout.test.ts` prose (paraphrased — no quote available because the claim covers absence of code). The forwarding is asserted end-to-end by a passing test:

```ts
// proxy.test.ts:92-98
const forwarded = forwardedRequestHeader(
  response,
  "content-security-policy",
);
expect(forwarded).not.toBeNull();
expect(forwarded).toBe(response.headers.get("Content-Security-Policy"));
```

Whether Next's renderer actually stamps that nonce onto bootstrap scripts is Next-internal behavior not exercisable from this unit suite; confidence Medium for that half.

**Evidence:** `proxy.ts:52-57`, `proxy.test.ts:90-99`, `app/layout.tsx:18-25`

---

## Claim 4: "This is deliberately broader than the `await headers()` it replaced … Equivalent today (PPR is not enabled)"

**Location:** `app/layout.tsx:27-33`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

The predecessor mechanism existed exactly as described — at `d90d6bb` the layout contained:

```ts
// git show d90d6bb:app/layout.tsx (lines 3, 31)
import { headers } from "next/headers";
...
  await headers();
```

and PPR is not enabled — the Next config is empty:

```ts
// next.config.ts:3-5
const nextConfig: NextConfig = {
  /* config options here */
};
```

No `experimental.ppr` (or any other) flag is set anywhere (paraphrased — no quote available because the claim covers absence of configuration: `rg -n "ppr" next.config.ts package.json` yields no hits).

**Evidence:** `git show d90d6bb:app/layout.tsx`, `next.config.ts:1-7`

---

## Claim 5: "Lives in its own module so a second consumer can use it without importing `exportGraph.ts`, which pulls `html-to-image` into whatever chunk imports it — the code split `GraphPanel.tsx` dynamic-imports precisely to avoid."

**Location:** `app/lib/utils/dataUrl.ts:4-7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

`exportGraph.ts` does import the heavy dependency:

```ts
// app/lib/utils/exportGraph.ts:6
import { toPng } from "html-to-image";
```

`dataUrl.ts` imports nothing (its only statements are the two docblocks and the function — paraphrased for the absence half: no `import` line exists in `app/lib/utils/dataUrl.ts`), and the code split the comment references is real:

```ts
// app/components/panels/GraphPanel.tsx:102
const { getGraphViewportElement, downloadGraphAsPng } = await import("@/app/lib/utils/exportGraph");
```

**Evidence:** `app/lib/utils/dataUrl.ts:1-38`, `app/lib/utils/exportGraph.ts:6`, `app/components/panels/GraphPanel.tsx:102`

---

## Claim 6: "`fetch(dataUrl)` is the shorter spelling but is a `connect-src` fetch, which the app's CSP refuses."

**Location:** `app/lib/utils/dataUrl.ts:12-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The policy contains:

```ts
// proxy.ts:33
"connect-src 'self'",
```

Per the CSP3 spec, `fetch()` is governed by `connect-src`, and `'self'` matches only same-origin URLs — a `data:` URL is not same-origin, so `fetch(dataUrl)` would be blocked under this policy (paraphrased — no quote available because the claim is about standardized browser behavior, not repo code). The pre-move copy of this docstring said the same thing with the directive value restated; the reworded version defers to `proxy.ts` and remains accurate.

**Evidence:** `app/lib/utils/dataUrl.ts:9-16`, `proxy.ts:33`

---

## Claim 7 (disposition A5): "Moved to a new `app/lib/utils/dataUrl.ts` … Behaviour byte-identical; all five existing cases still pass" and the test file was renamed via `git mv` with "contents unchanged but the import."

**Location:** `csp-arm2/amber-dispositions.md:15` (advisory artifact), `app/lib/utils/dataUrl.ts:17-38`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

Comparing the pre-move implementation at `2544a19` with HEAD, the function body is character-identical; only the docstring wording changed (paraphrased — no quote available because the evidence is a diff showing *no* body changes: `git show 2544a19:app/lib/utils/exportGraph.ts` lines 23-45 vs `app/lib/utils/dataUrl.ts:17-38` differ in zero code lines). The rename is a 96%-similarity git rename whose only content change is the import line:

```
// git diff 2544a19:app/lib/utils/exportGraph.test.ts ab4dbdb:app/lib/utils/dataUrl.test.ts
-import { dataUrlToBlob } from "./exportGraph";
+import { dataUrlToBlob } from "./dataUrl";
```

Git records it as `R096 app/lib/utils/exportGraph.test.ts → app/lib/utils/dataUrl.test.ts` in `ab4dbdb`. Both call sites resolve — `exportGraph.ts` re-imports:

```ts
// app/lib/utils/exportGraph.ts:8
import { dataUrlToBlob } from "./dataUrl";
```

and no other file imports the old location (paraphrased — no quote available because the claim covers absence of code: `rg -l dataUrlToBlob` outside `node_modules` hits exactly `dataUrl.ts`, `dataUrl.test.ts`, `exportGraph.ts`). All five test cases pass in the suite run.

**Evidence:** `git log --follow --name-status -- app/lib/utils/dataUrl.test.ts`, `app/lib/utils/exportGraph.ts:8,25,36`, test run output

---

## Claim 8: "`NextResponse.next({ request: { headers } })` … Next encodes them onto the response as `x-middleware-request-<lowercased-name>`, with the overridden names listed in `x-middleware-override-headers` … PINNED TO A NEXT INTERNAL: verified against next@16.2.4."

**Location:** `proxy.test.ts:5-23`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High

The version pin is exact:

```json
// package.json:23
"next": "16.2.4",
```

(installed `node_modules/next/package.json` reports `16.2.4` as well). The encoding claim is confirmed empirically: the helper that reads exactly that encoding —

```ts
// proxy.test.ts:28-34
const overridden = (response.headers.get("x-middleware-override-headers") ?? "")
  .split(",")
  .map((s) => s.trim().toLowerCase());
if (!overridden.includes(name.toLowerCase())) return null;
return response.headers.get(`x-middleware-request-${name.toLowerCase()}`);
```

— recovers a value byte-equal to the response CSP in the passing forwarding test, and the canary test (`proxy.test.ts:117-121`, asserting `x-middleware-override-headers` is truthy) is green in the suite run. Both header names are indeed Next-private (paraphrased — no quote available because the claim is about API surface status: neither name appears in Next's exported types; they live in compiled internals).

**Evidence:** `package.json:23`, `proxy.test.ts:24-34,90-99,117-121`, test run output

---

## Claim 9: "Nothing under app/ reads x-nonce; Next takes the nonce from the request CSP header asserted above."

**Location:** `proxy.test.ts:101-106` (same claim at `proxy.ts:62-66`)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

`rg -n "x-nonce"` across the worktree hits only `proxy.ts` comments and `proxy.test.ts` — zero hits under `app/` (paraphrased — no quote available because the claim covers absence of code). The deletion is safe: no production reader existed, and the load-bearing CSP request-header forwarding is untouched —

```ts
// proxy.ts:56-60
const requestHeaders = new Headers(request.headers);
requestHeaders.set("Content-Security-Policy", csp);
...
const response = NextResponse.next({
  request: { headers: requestHeaders },
```

with the test at `proxy.test.ts:106` (`expect(forwardedRequestHeader(run(), "x-nonce")).toBeNull()`) passing.

**Evidence:** `proxy.ts:56-69`, `proxy.test.ts:101-107`, repo-wide grep

---

## Claim 10: "Approximates Next's compilation of the `source` pattern … a plain RegExp agrees with path-to-regexp on every path asserted here (checked against next/dist/compiled/path-to-regexp at next@16.2.4)."

**Location:** `proxy.test.ts:126-131`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

Re-executed both engines against all 12 asserted paths. Plain `new RegExp("^" + source + "$")` and `require("next/dist/compiled/path-to-regexp").pathToRegexp(source)` produce identical results on every one: `/`, `/graph`, `/logo.svg`, `/does-not-exist`, `/apidocs`, `/api-status`, `/favicon.ico.map` all match; `/api`, `/api/formalization/lean`, `/_next/static/chunk.js`, `/_next/image`, `/favicon.ico` all fail to match (paraphrased — no quote available because the evidence is a re-run of the comparison, output tabulated above, not a code snippet). This confirms brief item 1: the anchored exclusions behave exactly as the comment at `proxy.ts:79-88` describes, and no `missing:`/`has` clause remains:

```ts
// proxy.ts:88-92
matcher: [
  {
    source: "/((?!api(?:/|$)|_next/static|_next/image|favicon\\.ico$).*)",
  },
],
```

**Evidence:** `proxy.ts:79-92`, `proxy.test.ts:123-178`, node re-execution of both regex engines

---

## Claim 11: "The matcher used to skip requests carrying client-controlled prefetch headers, shipping a document whose bootstrap scripts had no nonce."

**Location:** `proxy.test.ts:124-136` (history claim; also `proxy.ts:83-85`)
**Type:** Staleness / Reference
**Verdict:** Verified
**Confidence:** High

The prior state (ancestor `2544a19`) carried exactly such a clause:

```ts
// git show 2544a19:proxy.ts (matcher entry)
missing: [
  { type: "header", key: "next-router-prefetch" },
  { type: "header", key: "purpose", value: "prefetch" },
],
```

Both are request headers a client can set (paraphrased — no quote available because header controllability is protocol behavior, not repo code). HEAD's matcher has no `missing`/`has` property — asserted by the passing test `proxy.test.ts:139-145` — and the prefetch-still-gets-CSP behavior is asserted at `proxy.test.ts:124-136`, green in the suite run.

**Evidence:** `git show 2544a19:proxy.ts`, `proxy.ts:88-92`, `proxy.test.ts:124-145`

---

## Claim 12: "Why `style-src 'unsafe-inline'`: React `style={}` attributes, reactflow's inline transforms and KaTeX all emit inline styles at runtime … (Tailwind v4 itself compiles to a linked stylesheet via `@tailwindcss/postcss` and is already covered by `'self'`.)" and "This block is the single authoritative rationale … Other files that touch a directive (`proxy.test.ts`, `app/lib/utils/dataUrl.ts`) point here rather than restating it."

**Location:** `proxy.ts:12-25`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High

The named dependencies are all present:

```json
// package.json:21,29,36,49
"katex": "^0.16.45",
"reactflow": "^11.11.4",
"@tailwindcss/postcss": "^4",
"tailwindcss": "^4",
```

The single-owner claim holds on this tree: the test copy is reduced to a pointer —

```ts
// proxy.test.ts:59
// Rationale: see the style-src note in proxy.ts (authoritative copy).
```

— and the third former copy in the export helper now defers rather than restates:

```ts
// app/lib/utils/dataUrl.ts:14-15
* the app's CSP refuses. Decoding here keeps that directive tight instead of
* widening it for an export helper; see the connect-src note in `proxy.ts` for
```

No other file restates a style-src or connect-src rationale (paraphrased — no quote available because the claim covers absence of code: `rg -n "unsafe-inline"` outside `node_modules` hits only `proxy.ts` and the `proxy.test.ts` assertion/pointer). That reactflow/KaTeX emit inline styles at runtime is consistent with how those libraries work but was not runtime-verified here; it is the acknowledged carve-out rationale, not a new claim introduced by this commit.

**Evidence:** `proxy.ts:12-25`, `proxy.test.ts:57-62`, `app/lib/utils/dataUrl.ts:9-16`, `package.json:16-49`

---

## Claim 13: "`connect-src 'self'` is sufficient because every third-party call (Anthropic, OpenRouter) originates from a Next route handler on the server; the browser only ever talks to same-origin `/api/...` paths."

**Location:** `proxy.ts:24-26`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High

Re-enumerated every network call site on this tree. Browser-side callers all target relative `/api/...` paths:

```ts
// app/components/features/context-input/ContextInput.tsx:25
const response = await fetch("/api/refine/context", {
```

plus `app/components/features/lean-display/LeanCodeDisplay.tsx:88` (`/api/explanation/lean-error`), `app/hooks/useAnalytics.ts:11,30` (`/api/analytics`), `app/lib/formalization/api.ts:104` (`/api/verification/lean`), `app/hooks/useDecomposition.ts:130` (`/api/decomposition/extract`), and `app/hooks/useArtifactGeneration.ts:61` via `ARTIFACT_ROUTE`, whose every value is an `/api/formalization/...` path (`app/lib/types/artifacts.ts:192-197`). The generic helpers `fetchApi`/`fetchStreamingApi` (`app/lib/formalization/api.ts:10,38`) are only ever called with those same-origin URLs (paraphrased — no quote available because the invariant is inferred from the complete enumerated call-site list; every caller was listed above). The two vendor calls live in `app/lib/llm/callLlm.ts:164` and `app/lib/llm/streamLlm.ts:249` (`fetch(OPENROUTER_API_URL, ...)`, plus the Anthropic SDK client at `streamLlm.ts:205-230`), and every importer of those modules is a route handler under `app/api/` or another server-side `lib/llm`/`lib/formalization` module — `app/lib/formalization/api.ts` imports only `type LlmCallUsage`, which is erased at compile time (`app/lib/formalization/api.ts:3`). No `XMLHttpRequest`, `EventSource`, `WebSocket`, `sendBeacon`, or Worker usage exists in `app/` (paraphrased — no quote available because the claim covers absence of code: greps return zero hits). One additional server-side external call exists — `app/api/verification/lean/route.ts:21` fetches `LEAN_VERIFIER_URL` (default `http://localhost:3100`) — but it runs in a route handler, so the invariant's operative statement holds; whether a localhost sidecar counts as "third-party" is definitional, and it does not weaken the connect-src conclusion.

**Evidence:** `proxy.ts:24-26,33`, `app/lib/types/artifacts.ts:190-197`, `app/lib/formalization/api.ts:3,10,38,104`, `app/lib/llm/callLlm.ts:164`, `app/lib/llm/streamLlm.ts:249`, `app/api/verification/lean/route.ts:3-21`, repo-wide greps

---

## Claim 14: "CSP proxy (Next.js 16 renamed Middleware → Proxy)" and "Next 16 proxy always runs on the Node.js runtime, where crypto.randomUUID and Buffer are both available."

**Location:** `proxy.ts:5`, `proxy.ts:47-48`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High

Both halves check out against the installed Next 16.2.4:

```js
// node_modules/next/dist/lib/constants.js:289
const PROXY_FILENAME = 'proxy';
```

and the build unconditionally assigns the Node.js runtime to a proxy file — the condition short-circuits on `isProxyFile` regardless of any declared runtime:

```js
// node_modules/next/dist/build/index.js:1515-1519
if (staticInfo.runtime === 'nodejs' || (0, _utils1.isProxyFile)(page)) {
    var _staticInfo_middleware;
    hasNodeMiddleware = true;
    functionsConfigManifest.functions['/_middleware'] = {
        runtime: 'nodejs',
```

`crypto.randomUUID` and `Buffer` are both available on the Node.js runtime (paraphrased — no quote available because these are Node platform globals, not repo code; the passing proxy tests execute both at `proxy.ts:49` under vitest's Node environment).

**Evidence:** `node_modules/next/dist/lib/constants.js:289-290`, `node_modules/next/dist/build/index.js:1515-1519`, `proxy.ts:47-49`, test run output

---

## Claim 15: "Setting it only on the response is not enough: under 'strict-dynamic' the 'self' source is ignored, so un-nonced bootstrap scripts are refused and the app never hydrates."

**Location:** `proxy.ts:52-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium

The spec half is accurate: per CSP3, when `'strict-dynamic'` is present in `script-src`, host-source and `'self'` expressions are ignored by supporting browsers, so a script granted trust only by `'self'` would be refused (paraphrased — no quote available because the claim is about standardized browser behavior, not repo code). The repo half — that Next needs the *request*-side header to stamp nonces — is the same forwarding contract verified in Claim 3 via the passing round-trip test (`proxy.test.ts:90-99`). The end-state "app never hydrates" is a browser-integration outcome not verifiable from unit tests; Medium confidence for that consequence, High for the directive semantics.

**Evidence:** `proxy.ts:31,52-60`, `proxy.test.ts:90-99`

---

## Claim 16: "form-action … Does not fall back to default-src. The app posts to no cross-origin form target, so 'self' is free and closes the dangling-markup / injected-`<form>` path, which needs no script and so is untouched by script-src 'strict-dynamic'."

**Location:** `proxy.ts:38-42`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

The directive is present —

```ts
// proxy.ts:42
"form-action 'self'",
```

— and the directive-count test was updated to match: the exact-key-set assertion lists ten keys including `"form-action"` (`proxy.test.ts:46-57`), with a value assertion `expect(directives.get("form-action")).toBe("'self'")` at `proxy.test.ts:62-63`; both pass. `form-action` is one of the CSP directives with no `default-src` fallback, and form submission requires no script execution, so `'strict-dynamic'` in `script-src` indeed does not constrain it (paraphrased — no quote available because these are CSP3 spec facts, not repo code). "The app posts to no cross-origin form target" is confirmed by absence: no `<form` element exists anywhere under `app/` (paraphrased — no quote available because the claim covers absence of code: `rg -n "<form" app` returns zero hits).

**Evidence:** `proxy.ts:38-42`, `proxy.test.ts:44-64`, repo-wide grep

---

## Claim 17 (ACK justification, A9): "`await headers()` already forced per-request rendering" — i.e., `force-dynamic` is rendering-mode-neutral against the immediately preceding commit.

**Location:** `csp-arm2/amber-dispositions.md:19` (advisory artifact); code at `app/layout.tsx:34`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

Checked per the loop-owner instruction that ACK justifications be verified without re-raising. The predecessor mechanism is on the record:

```ts
// git show d90d6bb:app/layout.tsx:31
  await headers();
```

`headers()` is a dynamic API whose use opts a segment into per-request rendering in the App Router (paraphrased — no quote available because the behavior is Next framework semantics, not repo code), so the claim that the render cost predates `force-dynamic` is accurate. The owed-measurement framing (numbers unobtainable in-sandbox because `next build` needs `fonts.googleapis.com`) is consistent with `app/layout.tsx:2`'s `next/font/google` import, which fetches fonts at build time.

**Evidence:** `git show d90d6bb:app/layout.tsx`, `app/layout.tsx:2,34`, `csp-arm2/amber-dispositions.md:19`

---

## Claim 18 (ACK justifications, A15/A17): commit messages of `9b4e453`/`d90d6bb` say "Layout reads `headers()`" (superseded, immutable), and `2544a19` carries an unreliable ripgrep-output-order aside (immutable).

**Location:** `csp-arm2/amber-dispositions.md:23,25` (advisory artifact); git history
**Type:** Reference / Staleness
**Verdict:** Mostly accurate
**Confidence:** High

Both claims exist where stated and are accurately characterized. `9b4e453`'s body contains:

```
// git show -s 9b4e453 (body line 12)
- Layout reads headers() to opt out of static rendering — required
```

which was true when written (Claim 17) and is superseded on this tree — `rg -n "headers" app/layout.tsx` has zero hits at HEAD (paraphrased — no quote available because the claim covers absence of code). `2544a19`'s body contains the ripgrep-order aside (`git show -s 2544a19`, line beginning "one `rg \"unsafe-inline\"` hits first"), and cross-file ripgrep output order is indeed nondeterministic under parallel traversal (paraphrased — no quote available because this is tool behavior, not repo code). These are accepted-immutable per the loop-owner override and are **not** raised as findings; verdict "Mostly accurate" records only that the historical messages describe a mechanism no longer present, exactly as the ACK itself says. The disposition's verification block also re-checks: its claimed suite size (27 files / 240 tests) matches this pass's independent run exactly.

**Evidence:** `git show -s 9b4e453`, `git show -s 2544a19`, `app/layout.tsx` (HEAD), `csp-arm2/amber-dispositions.md:23-25,32`, test run output

---

## Claims Requiring Attention

### Incorrect

None.

### Stale

None.

### Mostly Accurate

- **Claim 18** (`git history: 9b4e453 / 2544a19`): historical commit messages describe the superseded `headers()` mechanism and an unreliable rg-order aside — accepted-immutable per loop-owner override (A15/A17); characterizations in the disposition are accurate; nothing to fix in-tree.

### Unverifiable

None.

## Goal-Alignment Note

- Answered: All 7 brief items. (1) Matcher anchoring verified by re-executing both plain RegExp and Next's own `path-to-regexp` at 16.2.4 — all 12 asserted paths behave as claimed; `/apidocs`, `/api-status`, `/favicon.ico.map` covered; `/api`, `/api/...`, `/favicon.ico` excluded; no `missing:`/`has` clause remains (Claims 10, 11). (2) `form-action 'self'` present, ten-key exact-set test updated and passing (Claim 16). (3) `x-nonce` deletion safe — zero readers under `app/`, CSP request-forwarding untouched and round-trip-tested (Claims 3, 9). (4) `dataUrl.ts` move byte-identical, `R096` git rename, both call sites resolve, no dangling import (Claims 5, 7). (5) `app/layout.test.ts` genuinely falsifies — asserts `layout.dynamic === "force-dynamic"` against a real export; deletion is statically guaranteed to turn it red (Claim 2). (6) connect-src invariant re-enumerated and holds — every browser call is same-origin `/api/...`; Anthropic/OpenRouter calls are server-side only; style-src has a single authoritative owner in `proxy.ts` with the test copy reduced to a pointer (Claims 12, 13). (7) Sweep for newly-introduced Incorrect/Stale: none found — 0 Incorrect, 0 Stale across all 18 claims; full suite passes 27 files / 240 tests, matching the disposition's verification block.
- Out of scope: runtime browser verification (nonce stamping on bootstrap scripts, hydration failure mode, prod-build CSP header emission — all flagged Medium where they matter); mutation re-execution (no worktree writes); A9's owed TTFB measurement (owed outside the sandbox per the ACK); the 22 green rubric rows.
- Escalate: nothing. No red-class finding. The A7/A8/A9/A11/A15/A17 ACK justifications were each spot-checked and are accurate as written (Claims 8, 17, 18 cover the checkable ones; A8's "Headers.set rejects CR/LF" and A11's microbenchmark are consistent with platform behavior and were not contradicted by anything on this tree).
