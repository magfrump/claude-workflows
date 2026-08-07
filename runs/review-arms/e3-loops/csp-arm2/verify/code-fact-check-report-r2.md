# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm2 (branch `e3/csp-arm2`)
**Commit:** ab4dbdb
**Scope:** `git diff d86d2dc..HEAD` — app/layout.test.ts, app/layout.tsx, app/lib/utils/dataUrl.ts, app/lib/utils/dataUrl.test.ts, app/lib/utils/exportGraph.ts, proxy.ts, proxy.test.ts; plus the ab4dbdb commit-message verification block and (advisory) csp-arm2/amber-dispositions.md
**Checked:** 2026-08-06
**Total claims checked:** 18
**Summary:** 15 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Loop-owner overrides honored: 9b4e453's historical claim and the A15/A17 immutable-history items are treated as accepted-immutable and are not re-raised as findings. ACKs A7, A8, A9, A11, A15, A17 were verified for factual accuracy only. No `docs/reviews/hallucination-patterns.md` exists in the worktree; no Incorrect verdicts, so none is owed.

Independent verification performed (read-only; worktree left clean per `git status --porcelain`): full test suite run — 27 files / 240 tests, all passing; `tsc --noEmit` exit 0; `npm run lint` exactly 2 pre-existing warnings; matcher behavior re-derived against Next's own `next/dist/compiled/path-to-regexp`.

---

## Claim 1: "`next/font/google` is a build-time loader that the Next compiler rewrites; it throws when called from a plain module graph, so it is stubbed here."

**Location:** `app/layout.test.ts:3-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The real (non-compiler) entry point throws unconditionally at load time:

```js
// node_modules/next/dist/compiled/@next/font/google/index.js:7-15
let message = '@next/font/google failed to run or is incorrectly configured.'
...
throw new Error(message)
```

The `node_modules/next/font/google/index.js` shim is 0 bytes (paraphrased — no quote available because the claim is about an empty file, there is nothing to quote), so outside the Next compiler the loader either throws or exports no callable loader; either way `app/layout.tsx` is unimportable without the `vi.mock`. The mocked import demonstrably works: the suite runs `app/layout.test.ts` green (27 files / 240 tests observed in this verification pass).

**Evidence:** `node_modules/next/dist/compiled/@next/font/google/index.js:1-15`, `app/layout.test.ts:9-12`

---

## Claim 2: "Nothing else in the suite fails if `export const dynamic` is deleted — this test is that failure."

**Location:** `app/layout.test.ts:16-23`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The assertion genuinely falsifies the export:

```ts
// app/layout.test.ts:22-23
const layout = await import("./layout");
expect(layout.dynamic).toBe("force-dynamic");
```

If `export const dynamic` is deleted, `layout.dynamic` is `undefined` and the `toBe("force-dynamic")` assertion fails — this is not a tautology. The "nothing else fails" half: a repo-wide grep for test files importing `app/layout` returns exactly one hit, `app/layout.test.ts` itself (paraphrased — no quote available because the claim covers absence of code: no other matching grep results for `./layout` / `app/layout` imports under `--glob '*.test.*'`). No other test can observe the export. The amber doc's stronger claim of an executed mutation check (delete → red → restore) was not re-executed here (worktree writes prohibited), but the static argument is decisive.

**Evidence:** `app/layout.test.ts:22-23`, grep of `app/**/*.test.*` for layout imports

---

## Claim 3: "Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) and stamps it onto the bootstrap `<script>` tags it emits, so nothing here reads it directly."

**Location:** `app/layout.tsx:21-25`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

Confirmed directly in the installed Next 16.2.4 source:

```js
// node_modules/next/dist/server/app-render/app-render.js:166-167
const csp = headers['content-security-policy'] || headers['content-security-policy-report-only'];
const nonce = typeof csp === 'string' ? (0, _getscriptnoncefromheader.getScriptNonceFromHeader)(csp) : undefined;
```

`headers` here is the incoming request's headers, and the extracted `nonce` is threaded into the render (`app-render.js:186` passes `nonce` into render options; `app-render.js:1143` receives it in the `App` component alongside `preinitScripts`) — the bootstrap-script stamping itself is (paraphrased — no quote available because the nonce propagation to emitted script tags spans several render helpers and is more legible as a summary). `proxy.ts:59-60` sets exactly that request header: `requestHeaders.set("Content-Security-Policy", csp)`. Nothing in `app/layout.tsx` reads the nonce (the file contains no `headers()` call in the final tree).

**Evidence:** `node_modules/next/dist/server/app-render/app-render.js:166-167,186,1143`, `proxy.ts:58-60`, `app/layout.tsx:33`

---

## Claim 4: "Equivalent today (PPR is not enabled) ... deliberately broader than the `await headers()` it replaced ... Covered by layout.test.ts."

**Location:** `app/layout.tsx:24-32`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High

PPR is not enabled — the Next config is empty:

```ts
// next.config.ts:3-5
const nextConfig: NextConfig = {
  /* config options here */
};
```

The replaced mechanism existed as claimed: the pre-`99e1229` layout contained a bare `await headers();` under a comment (`git show 9b4e453:app/layout.tsx`, line 31: `await headers();`). `app/layout.test.ts` exists and asserts the export (Claim 2). The segment-vs-subtree semantic distinction between `await headers()` and `force-dynamic` is standard Next behavior (paraphrased — no quote available because it is framework-semantics documentation, not a snippet in this repo) and nothing in the repo contradicts it.

**Evidence:** `next.config.ts:1-7`, `git show 9b4e453:app/layout.tsx` (line 31), `app/layout.test.ts:22-23`

---

## Claim 5: "Lives in its own module so a second consumer can use it without importing `exportGraph.ts`, which pulls `html-to-image` into whatever chunk imports it — the code split `GraphPanel.tsx` dynamic-imports precisely to avoid."

**Location:** `app/lib/utils/dataUrl.ts:1-7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

`exportGraph.ts` does statically import the library: `import { toPng } from "html-to-image";` (`app/lib/utils/exportGraph.ts:6`), while `dataUrl.ts` has zero imports (paraphrased — no quote available because the claim covers absence of code: the file contains no import statements). The referenced dynamic import exists:

```tsx
// app/components/panels/GraphPanel.tsx:102
const { getGraphViewportElement, downloadGraphAsPng } = await import("@/app/lib/utils/exportGraph");
```

**Evidence:** `app/lib/utils/exportGraph.ts:6`, `app/lib/utils/dataUrl.ts:1-38`, `app/components/panels/GraphPanel.tsx:102`

---

## Claim 6: "`fetch(dataUrl)` is the shorter spelling but is a `connect-src` fetch, which the app's CSP refuses. Decoding here keeps that directive tight ... see the connect-src note in `proxy.ts`."

**Location:** `app/lib/utils/dataUrl.ts:12-16`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The referenced policy exists: `"connect-src 'self'"` (`proxy.ts:36`), and the referenced note exists in `proxy.ts`'s docblock (`proxy.ts:24-27`). A `fetch()` of a `data:` URL is governed by `connect-src`, and `'self'` does not include the `data:` scheme, so such a fetch is refused (paraphrased — no quote available because this is CSP3 spec behavior, not repo code). The disposition claim that the A5 move was behavior-identical also checks out: the `dataUrlToBlob` function body in `app/lib/utils/dataUrl.ts` is character-identical to the body previously in `git show 2544a19:app/lib/utils/exportGraph.ts` (diff of the extracted function bodies is empty; only the docstring changed), and the test was a genuine rename — `git log --follow` reports `R096 app/lib/utils/exportGraph.test.ts → app/lib/utils/dataUrl.test.ts` with only the import line changed. Both call sites resolve (`app/lib/utils/exportGraph.ts:8` imports it; suite green; `tsc --noEmit` exit 0).

**Evidence:** `proxy.ts:24-27,36`, `app/lib/utils/dataUrl.ts:18-38`, `git show 2544a19:app/lib/utils/exportGraph.ts`, `app/lib/utils/exportGraph.ts:8,25,36`

---

## Claim 7: "CSP proxy (Next.js 16 renamed Middleware → Proxy) with per-request nonces."

**Location:** `proxy.ts:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

Next's own build code carries the rename and deprecation:

```js
// node_modules/next/dist/build/index.js:651
_log.warnOnce(`The "${_constants.MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${_constants.PROXY_FILENAME}" instead. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`);
```

with `PROXY_FILENAME = 'proxy'` (`node_modules/next/dist/lib/constants.js:289`). Per-request nonce generation is at `proxy.ts:47` and freshness is asserted by the passing test `"issues a fresh nonce per request"` (`proxy.test.ts:109`).

**Evidence:** `node_modules/next/dist/build/index.js:645-651`, `node_modules/next/dist/lib/constants.js:289`, `proxy.ts:47`, `proxy.test.ts:109-113`

---

## Claim 8: "Why `style-src 'unsafe-inline'`: React `style={}` attributes, reactflow's inline transforms and KaTeX all emit inline styles at runtime ... (Tailwind v4 itself compiles to a linked stylesheet via `@tailwindcss/postcss` and is already covered by `'self'`.)"

**Location:** `proxy.ts:12-18`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** Medium

The named dependencies are all real and present: `"reactflow": "^11.11.4"`, `"katex": "^0.16.45"` (`package.json:29,21`) and `"@tailwindcss/postcss": "^4"`, `"tailwindcss": "^4"` (`package.json:36,49`). That these libraries emit inline styles at runtime, and that Tailwind v4 output is a linked stylesheet, is (paraphrased — no quote available because it describes third-party runtime behavior, not repo code) consistent with how each ships and uncontradicted by anything in the repo. Medium confidence because the runtime-emission behavior is not statically checkable here.

**Evidence:** `package.json:16-49`, `proxy.ts:32`

---

## Claim 9: "This block is the single authoritative rationale for the CSP directives. Other files that touch a directive (`proxy.test.ts`, `app/lib/utils/dataUrl.ts`) point here rather than restating it, so the fact has one owner..."

**Location:** `proxy.ts:19-23`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

A repo-wide grep for `unsafe-inline` (excluding node_modules) hits only `proxy.ts` (rationale + directive) and `proxy.test.ts` (assertion + pointer). The test copy is indeed reduced to a pointer:

```ts
// proxy.test.ts:74
// Rationale: see the style-src note in proxy.ts (authoritative copy).
```

and `dataUrl.ts` defers likewise: "see the connect-src note in `proxy.ts` for the policy rationale itself" (`app/lib/utils/dataUrl.ts:14-15`). No third restatement remains (paraphrased — no quote available because the claim covers absence of code: no other grep hits for the rationale text).

**Evidence:** `proxy.ts:12-27`, `proxy.test.ts:73-77`, `app/lib/utils/dataUrl.ts:12-16`

---

## Claim 10: "`connect-src 'self'` is sufficient because every third-party call (Anthropic, OpenRouter) originates from a Next route handler on the server; the browser only ever talks to same-origin `/api/...` paths."

**Location:** `proxy.ts:24-27`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High

Re-enumerated all network calls under `app/` (excluding tests). Every browser-side `fetch` target is same-origin: `fetch("/api/analytics")` (`app/hooks/useAnalytics.ts:11,30`), `fetch("/api/verification/lean", ...)` (`app/lib/formalization/api.ts:104`), `fetch("/api/explanation/lean-error", ...)` (`LeanCodeDisplay.tsx:88`), `fetch("/api/refine/context", ...)` (`ContextInput.tsx:25`), and the parameterized `fetchApi`/`fetchStreamingApi` helpers whose only supplied URLs are the literal `"/api/decomposition/extract"` (`app/hooks/useDecomposition.ts:130`) and `ARTIFACT_ROUTE` values, all of the form:

```ts
// app/lib/types/artifacts.ts:192-198
export const ARTIFACT_ROUTE: Partial<Record<ArtifactType, string>> = {
  "causal-graph": "/api/formalization/causal-graph",
  ...
};
```

The external-URL callers are server-only: `fetch(OPENROUTER_API_URL, ...)` lives in `app/lib/llm/callLlm.ts:164` / `streamLlm.ts:249`, whose non-test importers are exclusively `app/api/**/route.ts` files and the route-handler helper `app/lib/formalization/artifactRoute.ts` (itself imported only by `app/api/formalization/*/route.ts`); the Anthropic SDK import sits in the same server module (`app/lib/llm/callLlm.ts:2`). `app/lib/formalization/api.ts:3` imports only a *type* from `callLlm`, which is erased at compile time (paraphrased — no quote available because type-erasure is TypeScript compilation behavior, not a snippet). One precision note, not a defect: the parenthetical vendor list omits the Lean verifier — `fetch(\`${LEAN_VERIFIER_URL}/verify\`, ...)` with default `http://localhost:3100` (`app/api/verification/lean/route.ts:3-4,21`) — but that call also originates from a route handler, so the invariant as stated holds.

**Evidence:** `app/hooks/useAnalytics.ts:11,30`, `app/lib/formalization/api.ts:3,10,38,104`, `app/hooks/useDecomposition.ts:129-133`, `app/hooks/useArtifactGeneration.ts:42,61`, `app/lib/types/artifacts.ts:192-198`, `app/lib/llm/callLlm.ts:2,7,164`, `app/lib/llm/streamLlm.ts:249`, `app/lib/formalization/artifactRoute.ts:2-4`, `app/api/verification/lean/route.ts:3-21`

---

## Claim 11: "form-action ... Does not fall back to default-src. The app posts to no cross-origin form target, so 'self' is free and closes the dangling-markup / injected-`<form>` path, which needs no script and so is untouched by script-src 'strict-dynamic'."

**Location:** `proxy.ts:38-42`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High

The directive is present: `"form-action 'self'"` (`proxy.ts:43`), and the test suite's exact-key assertion was updated to the 10-directive set including it —

```ts
// proxy.test.ts:47-58
expect([...directives.keys()].sort()).toEqual([
  "base-uri", "connect-src", "default-src", "font-src", "form-action",
  "frame-ancestors", "img-src", "object-src", "script-src", "style-src",
]);
```

(reformatted for width) plus the value assertion `expect(directives.get("form-action")).toBe("'self'")` (`proxy.test.ts:64`). That `form-action` does not inherit from `default-src` is CSP3 spec behavior (paraphrased — no quote available because it is spec, not repo code). "The app posts to no cross-origin form target": no `<form action=...>` targeting a cross-origin URL exists under `app/` (paraphrased — no quote available because the claim covers absence of code: grep for form actions yields no cross-origin target).

**Evidence:** `proxy.ts:38-43`, `proxy.test.ts:46-64`

---

## Claim 12: "Next 16 proxy always runs on the Node.js runtime, where crypto.randomUUID and Buffer are both available."

**Location:** `proxy.ts:45-46`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

Next 16.2.4's build unconditionally assigns the Node runtime to a `proxy` file:

```js
// node_modules/next/dist/build/index.js:1515-1519
if (staticInfo.runtime === 'nodejs' || (0, _utils1.isProxyFile)(page)) {
    ...
    functionsConfigManifest.functions['/_middleware'] = {
        runtime: 'nodejs',
```

— the `isProxyFile(page)` disjunct forces `runtime: 'nodejs'` for `proxy.*` regardless of any runtime export. `crypto.randomUUID` and `Buffer` are both available on Node ≥ 19 globals (paraphrased — no quote available because it is Node platform behavior; the environment here runs Node v20.20.2 and the expression executed successfully in the test run).

**Evidence:** `node_modules/next/dist/build/index.js:1515-1521`, `proxy.ts:47`

---

## Claim 13: "Next.js reads the nonce off the *request* `Content-Security-Policy` header during render ... Setting it only on the response is not enough: under 'strict-dynamic' the 'self' source is ignored, so un-nonced bootstrap scripts are refused and the app never hydrates. Both headers must carry the same policy."

**Location:** `proxy.ts:53-57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium

The request-header read is confirmed (same evidence as Claim 3: `app-render.js:166-167` reads `headers['content-security-policy']`). That `'strict-dynamic'` causes host-source expressions like `'self'` to be ignored in `script-src` is CSP3 spec behavior (paraphrased — no quote available because it is spec, not repo code); the "never hydrates" consequence follows from it but is a runtime outcome not demonstrable statically — hence Medium. The both-headers-same-policy invariant is enforced by a passing test:

```ts
// proxy.test.ts:96-97
expect(forwarded).toBe(response.headers.get("Content-Security-Policy"));
```

**Evidence:** `node_modules/next/dist/server/app-render/app-render.js:166-167`, `proxy.ts:58-70`, `proxy.test.ts:89-98`

---

## Claim 14: "Deliberately no `x-nonce` header: Next reads the nonce out of the Content-Security-Policy request header above, and nothing in `app/` has ever read `x-nonce`."

**Location:** `proxy.ts:62-66`
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High

No `x-nonce` write remains in `proxy.ts` (paraphrased — no quote available because the claim covers absence of code: grep for `x-nonce` in `proxy.ts` hits only these comment lines), and the test asserts non-forwarding: `expect(forwardedRequestHeader(run(), "x-nonce")).toBeNull()` (`proxy.test.ts:106`). The historical "ever" was checked with `git log -S"x-nonce" -- app/`: the only hits are comments. At 9b4e453 the layout contained

```tsx
// git show 9b4e453:app/layout.tsx, lines 27,31
// Read the per-request CSP nonce that middleware.ts forwards via x-nonce.
await headers();
```

— a bare `headers()` call that never accessed the `x-nonce` value (the comment itself was corrected in 99e1229 to "we don't need to read x-nonce here ourselves" before removal). So no code in `app/` ever read the header; CSP forwarding via `NextResponse.next({ request: { headers: requestHeaders } })` (`proxy.ts:68-70`) is intact and test-covered (Claim 13).

**Evidence:** `proxy.ts:58-71`, `proxy.test.ts:101-107`, `git show 9b4e453:app/layout.tsx`, `git log -S"x-nonce" -- app/`

---

## Claim 15: "Everything except API routes ..., Next's build output and image optimizer ..., and /favicon.ico. Anything else — page navigations, prefetched documents, files under public/, 404s — gets the policy. ... Each exclusion is anchored so it cannot swallow a sibling route: `api` only matches /api and /api/..., never a future /apidocs; `favicon.ico` only matches the whole path."

**Location:** `proxy.ts:74-91`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

Behavior was re-derived independently against Next's own matcher compiler (`pathToRegexp` from `next/dist/compiled/path-to-regexp` at the installed next@16.2.4), not just the test file's RegExp approximation, using the committed source:

```ts
// proxy.ts:88-90
matcher: [
  { source: "/((?!api(?:/|$)|_next/static|_next/image|favicon\\.ico$).*)" },
]
```

Results: `/`, `/graph`, `/logo.svg`, `/does-not-exist`, `/apidocs`, `/api-status`, `/favicon.ico.map` all match (get the CSP); `/api`, `/api/formalization/lean`, `/_next/static/chunk.js`, `/_next/image`, `/favicon.ico` are excluded — exactly as the comment and the four matcher tests claim, and no `missing:`/`has:` clause exists on the entry (asserted by `proxy.test.ts:127-133` and confirmed in the source). The one imprecision: "Each exclusion is anchored" is overbroad. `api` and `favicon.ico` are anchored (`api(?:/|$)`, `favicon\.ico$`), but `_next/static` and `_next/image` are unanchored prefixes — the same compilation excludes `/_next/staticfoo`. No practical sibling can exist there because `/_next/*` is a Next-reserved namespace (paraphrased — no quote available because it is framework routing behavior, not repo code), so the "cannot swallow a sibling route" consequence still holds, but the literal "each ... is anchored" does not. The precise version: "the user-route exclusions (`api`, `favicon.ico`) are anchored; the `_next/*` exclusions are prefixes in a Next-reserved namespace."

**Evidence:** `proxy.ts:74-91`, `proxy.test.ts:116-177`, `node -e` run of `next/dist/compiled/path-to-regexp` over 13 paths

---

## Claim 16: "Next encodes them onto the response as `x-middleware-request-<lowercased-name>`, with the overridden names listed in `x-middleware-override-headers` ... PINNED TO A NEXT INTERNAL: verified against next@16.2.4."

**Location:** `proxy.test.ts:5-24`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The version pin is exact: `"next": "16.2.4"` (`package.json:23`) and `"version": "16.2.4"` (`node_modules/next/package.json:3`). The transport encoding claim is confirmed empirically: the canary test (`proxy.test.ts:115`, asserting `x-middleware-override-headers` is present) and the forwarding test (`proxy.test.ts:89-98`, reading `x-middleware-request-content-security-policy` via the helper at `proxy.test.ts:25-34`) both pass in this verification run — if the encoding were wrong, the helper would return `null` and the assertions would fail (paraphrased — no quote available because the proof is a passing test execution, not a static snippet).

**Evidence:** `package.json:23`, `node_modules/next/package.json:3`, `proxy.test.ts:25-34,89-98,115-119`, observed test run (240/240 green)

---

## Claim 17: "Approximates Next's compilation of the `source` pattern. The only dynamic part is the single capture group, so a plain RegExp agrees with path-to-regexp on every path asserted here (checked against next/dist/compiled/path-to-regexp at next@16.2.4)."

**Location:** `proxy.test.ts:120-124`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

Independently re-checked: the plain `new RegExp(\`^${entry.source}$\`)` used at `proxy.test.ts:125-126` and the real `pathToRegexp(source, [], { delimiter: '/', sensitive: false, strict: true })` from `next/dist/compiled/path-to-regexp` produce identical accept/reject results for all 12 paths asserted in the file (verified by direct execution against the installed compiled module; results listed under Claim 15) (paraphrased — no quote available because the evidence is an executed comparison, not a snippet).

**Evidence:** `proxy.test.ts:120-177`, `node/dist/compiled/path-to-regexp` execution

---

## Claim 18: Commit ab4dbdb verification block — "npm test 27 files / 240 tests passed (from 26/234); tsc --noEmit exit 0, empty; npm run lint exactly the 2 pre-existing react-hooks/exhaustive-deps warnings at app/page.tsx:209:6 and :271:6, a file this change does not touch."

**Location:** `git show ab4dbdb` (commit message); mirrored in `csp-arm2/amber-dispositions.md:31-36`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

Reproduced in this pass: `npx vitest run` → "Test Files  27 passed (27) / Tests  240 passed (240)"; `npx tsc --noEmit` → exit 0, empty output; `npm run lint` → exactly `209:6 warning ... react-hooks/exhaustive-deps` and `271:6 warning ... react-hooks/exhaustive-deps` in `app/page.tsx`, "2 problems (0 errors, 2 warnings)" (paraphrased quotes from command output — no source-file quote available because these are executed-command results). `app/page.tsx` is indeed untouched (not in `git diff d86d2dc..HEAD --stat`). The baseline "(from 26/234)" could not be re-executed without checking out `2544a19` (worktree writes prohibited) but is arithmetically consistent with the diff: +1 test file (`app/layout.test.ts`), and `git diff 2544a19..ab4dbdb -- proxy.test.ts` shows 7 added `it(` blocks, 2 removed (`x-nonce`) and 1 moved, i.e. net +6 tests = 240. Graded Mostly accurate only because the baseline half rests on reconstruction rather than execution; every re-executable claim reproduced exactly.

**Evidence:** `git show ab4dbdb`, executed `vitest`/`tsc`/lint runs, `git diff 2544a19..ab4dbdb -- proxy.test.ts`

---

### Advisory sweep: checkable assertions in `csp-arm2/amber-dispositions.md` (ACK accuracy, not re-raised)

- **A8, "Response splitting is unreachable (`Headers.set` rejects CR/LF)"** — Verified: `new Headers().set('a', 'x\r\ny')` throws `TypeError` in this runtime (executed check; paraphrased — no quote available because the evidence is an executed expression).
- **A11, "Named drop-in ...: `Uint8Array.fromBase64`"** — Mostly accurate (counted as one of the 3 in the Summary): a real, shipped browser API (Baseline 2025 / TC39 stage 4 — paraphrased, no quote available because it is platform documentation), and `dataUrlToBlob` runs in the browser where it applies; note it is `undefined` in the project's Node v20.20.2, so any test of the drop-in would need the stated loop fallback. Not a fabrication; no hallucination-log entry warranted.
- **A12, "repo-wide `rg -ni openalex` had exactly one hit: this comment"** — Verified as now-zero: `rg -ni openalex` over the worktree (excluding node_modules) returns no hits (paraphrased — no quote available because the claim covers absence of code).
- **A7 half-fix** — Verified present: pin + triage rule in `proxy.test.ts:5-24`, canary at `proxy.test.ts:115-119`.
- **A9, A15, A17** — accepted-immutable per loop-owner override; A9's "unobtainable in sandbox" build-failure claim is consistent with the sandboxed environment and was not re-attempted.

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 15** (`proxy.ts:85-87`): "Each exclusion is anchored" is overbroad — `_next/static` / `_next/image` are unanchored prefixes (e.g. `/_next/staticfoo` is excluded); harmless because `/_next/*` is Next-reserved, but the comment could name the two anchored exclusions specifically (it already does in its examples).
- **Claim 18** (commit ab4dbdb message): the "(from 26/234)" baseline is reconstruction-consistent but was not re-executed; all currently executable verification claims reproduced exactly.
- **Advisory A11** (`csp-arm2/amber-dispositions.md:21`): `Uint8Array.fromBase64` is real in browsers but absent from the project's Node v20.20.2 — worth one clause if the drop-in is ever taken.

### Unverifiable
- None.

## Goal-Alignment Note
- Answered: All 7 brief items. (1) Matcher `api(?:/|$)` anchoring correct, `/apidocs` and `/api-status` covered, no `missing:`/`has:` client-header condition — independently re-derived against Next's own path-to-regexp (Claims 15, 17). (2) `form-action 'self'` present, directive-count test updated 9→10 with value assertion (Claim 11). (3) `x-nonce` deletion safe — zero readers ever under `app/`, CSP request-header forwarding intact and test-pinned (Claims 13, 14). (4) `dataUrlToBlob` move byte-identical (empty function-body diff vs 2544a19), test git-mv'd (R096), both call sites resolve, suite + tsc green (Claim 6). (5) `app/layout.test.ts` genuinely falsifies the `force-dynamic` export — sole importer of layout, non-tautological assertion (Claim 2). (6) connect-src invariant re-enumerated and holds — every browser call is same-origin `/api/...`; style-src rationale has a single owner in `proxy.ts` (Claims 9, 10). (7) Newly-introduced issue sweep: zero Incorrect, zero Stale; the only findings are three precision notes (comment overbreadth, an unexecuted baseline figure, a Node-vs-browser API qualifier in the advisory doc), none red-worthy. All six ACKs verified for accuracy; none re-raised.
- Out of scope: A9's owed TTFB measurement (unobtainable in sandbox, per accepted ACK); baseline test-count re-execution at 2544a19 (would require a checkout — no worktree writes); runtime hydration behavior under a wrong CSP (Claim 13's "never hydrates" consequence).
- Escalate: Nothing. 0 Incorrect / 0 Stale supports the 0-red bar; the three Mostly-accurate items are precision notes, not defects.
