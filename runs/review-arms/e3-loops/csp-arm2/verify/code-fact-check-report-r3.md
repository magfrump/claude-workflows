# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm2 (branch `e3/csp-arm2`)
**Commit:** ab4dbdb
**Scope:** `git diff d86d2dc..HEAD` (6 commits; files: `app/layout.test.ts`, `app/layout.tsx`, `app/lib/utils/dataUrl.test.ts`, `app/lib/utils/dataUrl.ts`, `app/lib/utils/exportGraph.ts`, `proxy.test.ts`, `proxy.ts`) plus the `ab4dbdb` commit-message disposition claims. Round 3 (post-amber-disposition verification pass).
**Checked:** 2026-08-06
**Total claims checked:** 20
**Summary:** 14 verified, 2 mostly accurate, 0 stale, 0 incorrect, 4 unverifiable

Historical-rule note: verification used only ancestors of worktree HEAD (`ab4dbdb~1`, `9b4e453`, `99e1229`) plus this arm's own `csp-arm2/amber-dispositions.md` (advisory). Per the loop-owner override, `9b4e453`'s historical verification claim and the A15/A17 immutable-history items are treated as accepted-immutable and are not re-raised as findings. No `docs/reviews/hallucination-patterns.md` exists in the worktree; none of the verdicts below is a fabrication, so no log entry is owed.

---

## Claim 1: "`next/font/google` is a build-time loader that the Next compiler rewrites; it throws when called from a plain module graph, so it is stubbed here."

**Location:** `app/layout.test.ts:3-8`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium

Whether the unmocked loader throws under vitest's plain module graph cannot be confirmed from static reading (paraphrased — no quote available because the claim is about runtime behavior of a Next-internal loader, not repo code). The claim is consistent with the amber-dispositions record and with the fact that the mock is load-bearing: the test file imports `app/layout.tsx`, which imports the loader. Confirming would require running the test with the `vi.mock` removed, a worktree mutation this pass does not perform. The stub's stated non-purpose ("nothing below asserts anything about fonts") is accurate — the only assertion in the file is `expect(layout.dynamic).toBe("force-dynamic")` (`app/layout.test.ts:23`).

**Evidence:** `app/layout.test.ts:1-25`, `app/layout.tsx:1-16`

---

## Claim 2: "Nothing else in the suite fails if `export const dynamic` is deleted — this test is that failure."

**Location:** `app/layout.test.ts:16-23`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High

The test genuinely falsifies the export's presence:

```ts
// app/layout.test.ts:22-23
const layout = await import("./layout");
expect(layout.dynamic).toBe("force-dynamic");
```

If `export const dynamic = "force-dynamic"` is deleted from `app/layout.tsx`, `layout.dynamic` is `undefined` and the `toBe` assertion fails — the test is not a tautology (paraphrased — no quote available because the claim covers the counterfactual absence of code). The "nothing else fails" half: a repo-wide `rg -n "force-dynamic" app` returns exactly two hits, `app/layout.tsx` (the export) and `app/layout.test.ts:23` (this assertion) — no other test or module binds to it (paraphrased — no quote available because the claim covers absence of other matching grep results). The `ab4dbdb` commit message additionally records "Mutation-checked: deleting the export turns the test red", which this pass did not re-run (no worktree writes) but which is consistent with the static analysis.

**Evidence:** `app/layout.test.ts:14-24`, `app/layout.tsx:33`, `ab4dbdb` commit message (A6)

---

## Claim 3: "Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) and stamps it onto the bootstrap `<script>` tags it emits, so nothing here reads it directly."

**Location:** `app/layout.tsx:21-25` (same mechanism claimed at `proxy.ts:53-58`)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium

The half of this claim inside the repo is verified: the proxy sets the header on the forwarded request —

```ts
// proxy.ts:59-60
const requestHeaders = new Headers(request.headers);
requestHeaders.set("Content-Security-Policy", csp);
```

— and `proxy.test.ts:88-96` asserts the forwarded request header equals the response header. Nothing in `app/layout.tsx` reads any header:

```tsx
// app/layout.tsx:35-38
export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
```

The other half — that Next's renderer consumes the request CSP header and stamps the nonce onto its bootstrap scripts — is framework-internal behavior not exercisable by the unit suite (paraphrased — no quote available because the behavior lives in `next`'s server renderer, outside the repo). It matches Next's documented nonce mechanism, but only an integration/E2E render would confirm it. This is the same residual uncertainty all three prior fact-check rounds carried; nothing in the amber pass changed it.

**Evidence:** `app/layout.tsx:21-33`, `proxy.ts:53-61`, `proxy.test.ts:88-96`

---

## Claim 4: "This is deliberately broader than the `await headers()` it replaced ... Equivalent today (PPR is not enabled) ... Covered by layout.test.ts."

**Location:** `app/layout.tsx:27-33`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High

"PPR is not enabled": the Next config declares nothing —

```ts
// next.config.ts:3-5
const nextConfig: NextConfig = {
  /* config options here */
};
```

— so no `ppr`/`experimental.ppr` flag exists (paraphrased — no quote available because the claim covers absence of a config key). "It replaced `await headers()`": ancestor `99e1229` shows the removal, `-  await headers();` in `app/layout.tsx` (quoted from `git show 99e1229 -- app/`). "Covered by layout.test.ts": the file exists and its single assertion pins this export (Claim 2); the full suite passes 27 files / 240 tests including it. The forward-looking sentence ("the line to revisit if the project ever turns PPR on") is intent, not checked.

**Evidence:** `next.config.ts:1-8`, `git show 99e1229`, `app/layout.test.ts:23`

---

## Claim 5: "Lives in its own module so a second consumer can use it without importing `exportGraph.ts`, which pulls `html-to-image` into whatever chunk imports it — the code split `GraphPanel.tsx` dynamic-imports precisely to avoid."

**Location:** `app/lib/utils/dataUrl.ts:1-7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

`exportGraph.ts` does import the library at module top level:

```ts
// app/lib/utils/exportGraph.ts:6
import { toPng } from "html-to-image";
```

and `GraphPanel.tsx` does dynamic-import the module:

```tsx
// app/components/panels/GraphPanel.tsx:102
const { getGraphViewportElement, downloadGraphAsPng } = await import("@/app/lib/utils/exportGraph");
```

`dataUrl.ts` itself has zero imports (paraphrased — no quote available because the claim covers absence of import statements in the 38-line file), so importing it pulls in nothing.

**Evidence:** `app/lib/utils/dataUrl.ts:1-38`, `app/lib/utils/exportGraph.ts:6`, `app/components/panels/GraphPanel.tsx:102`

---

## Claim 6: "`fetch(dataUrl)` is the shorter spelling but is a `connect-src` fetch, which the app's CSP refuses. ... see the connect-src note in `proxy.ts` for the policy rationale itself."

**Location:** `app/lib/utils/dataUrl.ts:12-16`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The directive exists as claimed:

```ts
// proxy.ts:35
"connect-src 'self'",
```

Under CSP, `fetch()` of a `data:` URL is governed by `connect-src`, and `'self'` does not match the `data:` scheme, so such a fetch is refused (paraphrased — no quote available because this is CSP/Fetch spec behavior, not repo code). The cross-reference is live: `proxy.ts:24-26` contains the connect-src rationale this docstring points to. This pointer form is new in `ab4dbdb`; the pre-move copy restated the directive ("the app's CSP sets `connect-src 'self'`, which refuses `data:`", `git show ab4dbdb~1:app/lib/utils/exportGraph.ts`), consistent with the A16 single-owner claim (Claim 13).

**Evidence:** `app/lib/utils/dataUrl.ts:8-16`, `proxy.ts:24-26,35`

---

## Claim 7: A5 disposition — "moved `dataUrlToBlob` to app/lib/utils/dataUrl.ts ... git mv'd its test to dataUrl.test.ts. Behaviour byte-identical."

**Location:** `ab4dbdb` commit message (A5); `app/lib/utils/dataUrl.ts:17-38`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High

Extracting the `dataUrlToBlob` function body from `ab4dbdb~1:app/lib/utils/exportGraph.ts` and diffing it against `app/lib/utils/dataUrl.ts` yields no differences — `diff` reports identical (paraphrased — no quote available because the evidence is an empty diff between two 22-line extracts). Only the docstring above the function changed (Claim 6). The test rename is recorded by git as a true rename:

```
ab4dbdb  R096  app/lib/utils/exportGraph.test.ts  app/lib/utils/dataUrl.test.ts
```

(quoted from `git log --follow --name-status -- app/lib/utils/dataUrl.test.ts`), with the 4% delta being the import path. Both remaining call sites resolve: `exportGraph.ts:8` imports `{ dataUrlToBlob } from "./dataUrl"` and uses it at `exportGraph.ts:25` and `:36`; `tsc --noEmit` exits 0 and all 5 `dataUrl.test.ts` cases pass.

**Evidence:** `git show ab4dbdb~1:app/lib/utils/exportGraph.ts`, `app/lib/utils/dataUrl.ts:17-38`, `app/lib/utils/exportGraph.ts:8,25,36`, `app/lib/utils/dataUrl.test.ts:2`

---

## Claim 8: "Next encodes them onto the response as `x-middleware-request-<lowercased-name>`, with the overridden names listed in `x-middleware-override-headers` ... PINNED TO A NEXT INTERNAL: verified against next@16.2.4."

**Location:** `proxy.test.ts:5-23`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The version pin is exact:

```json
// package.json:23
"next": "16.2.4",
```

and `node_modules/next/package.json` confirms the installed version is `16.2.4`. The encoding claim is validated by execution: the suite's forwarding assertion (`proxy.test.ts:88-96`) and the canary (`proxy.test.ts:113-117`, asserting `x-middleware-override-headers` is truthy) both pass against the installed Next, which is only possible if the described transport exists (paraphrased — no quote available because the evidence is the observed pass of tests exercising `next/server` internals). The acknowledged fragility ("may be renamed by any Next upgrade") is the accepted A7 ACK, not re-raised.

**Evidence:** `proxy.test.ts:5-40,88-96,113-117`, `package.json:23`, `node_modules/next/package.json:3`

---

## Claim 9: "Nothing under app/ reads x-nonce; Next takes the nonce from the request CSP header asserted above."

**Location:** `proxy.test.ts:101-106` (twin claim at `proxy.ts:62-66`: "nothing in `app/` has ever read `x-nonce`")
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High

Repo-wide `rg -n "x-nonce"` outside `node_modules` hits only `proxy.ts` comments and `proxy.test.ts` (paraphrased — no quote available because the claim covers absence of matches under `app/`). The stronger historical form in `proxy.ts` ("has *ever* read") also holds: `git log -S "x-nonce" -- app/` finds two commits, and in both the string appears only in comments — e.g.

```
// 9b4e453, app/layout.tsx (added line)
+  // Read the per-request CSP nonce that middleware.ts forwards via x-nonce.
+  await headers();
```

— a comment mentioning the header next to an `await headers()` call that never accessed `x-nonce` specifically; `99e1229` deleted that comment. No code under `app/` ever called `headers().get("x-nonce")` or equivalent (paraphrased — no quote available because the claim covers absence of code across history). The deletion is safe on the test's own terms: the guarded test `expect(forwardedRequestHeader(run(), "x-nonce")).toBeNull()` (`proxy.test.ts:106`) passes, and CSP forwarding is untouched — `NextResponse.next({ request: { headers: requestHeaders } })` remains at `proxy.ts:68-70` with the forwarding assertion still green.

**Evidence:** `proxy.test.ts:101-106`, `proxy.ts:59-70`, `git show 9b4e453 -- app/`, `git show 99e1229 -- app/`

---

## Claim 10: "The matcher used to skip requests carrying client-controlled prefetch headers, shipping a document whose bootstrap scripts had no nonce."

**Location:** `proxy.test.ts:119-121`
**Type:** Staleness / Reference (historical)
**Verdict:** Verified
**Confidence:** High

The prior state is in the direct ancestor:

```ts
// ab4dbdb~1:proxy.ts (matcher entry)
missing: [
  { type: "header", key: "next-router-prefetch" },
  { type: "header", key: "purpose", value: "prefetch" },
],
```

Both keys are request headers a client can set, so the skip was client-controlled as stated. The current matcher has no such clause — `config.matcher[0]` is only `{ source: "/((?!api(?:/|$)|_next/static|_next/image|favicon\\.ico$).*)" }` (`proxy.ts:85-89`) — and `proxy.test.ts:128-131` asserts the entry has neither `missing` nor `has`. The new behavior is directly tested: a request with `purpose: prefetch` and `next-router-prefetch: 1` headers still receives the CSP (`proxy.test.ts:119-134`, passing).

**Evidence:** `git show ab4dbdb~1:proxy.ts`, `proxy.ts:85-89`, `proxy.test.ts:119-134`

---

## Claim 11: "The only dynamic part is the single capture group, so a plain RegExp agrees with path-to-regexp on every path asserted here (checked against next/dist/compiled/path-to-regexp at next@16.2.4)."

**Location:** `proxy.test.ts:140-143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Re-checked empirically this round. Compiling the exact `source` string through Next's own vendored compiler:

```js
const {pathToRegexp} = require('next/dist/compiled/path-to-regexp');
const re = pathToRegexp('/((?!api(?:/|$)|_next/static|_next/image|favicon\\.ico$).*)');
```

and testing all 12 paths asserted in `proxy.test.ts` (`/`, `/graph`, `/logo.svg`, `/does-not-exist`, `/apidocs`, `/api-status`, `/favicon.ico.map` → match; `/api`, `/api/formalization/lean`, `/_next/static/chunk.js`, `/_next/image`, `/favicon.ico` → no match) produced results identical to the test file's plain-RegExp expectations on every path (paraphrased — no quote available because the evidence is a 12-line runtime output table, reproduced in the one-line summary: 7/7 covered, 5/5 excluded). This confirms brief item 1: `/apidocs` and `/api-status` are covered, `/api` and `/api/...` are excluded, and no client-header condition exists on the matcher.

**Evidence:** `proxy.test.ts:136-178`, `proxy.ts:85-89`, `node_modules/next/dist/compiled/path-to-regexp` (runtime check)

---

## Claim 12: "React `style={}` attributes, reactflow's inline transforms and KaTeX all emit inline styles at runtime; dev also injects styles. (Tailwind v4 itself compiles to a linked stylesheet via `@tailwindcss/postcss` and is already covered by `'self'`.)"

**Location:** `proxy.ts:12-17`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium

All named dependencies are real and present:

```json
// package.json:21,29,36
"katex": "^0.16.45",
"reactflow": "^11.11.4",
"@tailwindcss/postcss": "^4",
```

That reactflow positions nodes via inline `transform` styles and KaTeX emits inline style attributes is standard, documented behavior of those libraries, and React `style={}` props always render as inline `style` attributes (paraphrased — no quote available because the behavior lives in third-party library rendering code, not the repo). Confidence is Medium rather than High only because the runtime style emission was not observed in a browser this round. The carve-out itself is a documented design decision (not fact-checked as such); the checkable parts hold.

**Evidence:** `proxy.ts:12-17`, `package.json:16,21,29,36,49`

---

## Claim 13: "This block is the single authoritative rationale for the CSP directives. Other files that touch a directive (`proxy.test.ts`, `app/lib/utils/dataUrl.ts`) point here rather than restating it, so the fact has one owner."

**Location:** `proxy.ts:19-23`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

Repo-wide `rg -n "unsafe-inline|style-src"` outside `node_modules` hits only `proxy.ts` and `proxy.test.ts` (paraphrased — no quote available because the claim covers absence of other matches). The test copy is a pointer, not a restatement:

```ts
// proxy.test.ts:74
// Rationale: see the style-src note in proxy.ts (authoritative copy).
```

and `dataUrl.ts:15-16` likewise defers ("see the connect-src note in `proxy.ts` for the policy rationale itself") rather than restating the directive, as its pre-move copy did (Claim 6). The two named files are exactly the set of other files touching a directive.

**Evidence:** `proxy.ts:19-23`, `proxy.test.ts:73-77`, `app/lib/utils/dataUrl.ts:12-16`

---

## Claim 14: "`connect-src 'self'` is sufficient because every third-party call (Anthropic, OpenRouter) originates from a Next route handler on the server; the browser only ever talks to same-origin `/api/...` paths."

**Location:** `proxy.ts:24-26`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High

Re-enumerated this round (brief item 6). Every network primitive in non-test `app/` code was grepped (`fetch(`, `EventSource`, `WebSocket`, `XMLHttpRequest`, `axios`, `sendBeacon`, `new Image(`, `importScripts`); the complete hit list is: `app/hooks/useAnalytics.ts:11,30` (`fetch("/api/analytics")`), `app/lib/formalization/api.ts:10,38` (parameterized `fetch(url, ...)`), `:104` (`fetch("/api/verification/lean")`), `app/components/features/lean-display/LeanCodeDisplay.tsx:88` (`/api/explanation/lean-error`), `app/components/features/context-input/ContextInput.tsx:25` (`/api/refine/context`), plus three server-side calls (paraphrased — no quote available because the invariant spans eleven call sites across nine files). The parameterized `fetch(url)` helpers resolve only to same-origin literals: `app/hooks/useDecomposition.ts:130` passes `"/api/decomposition/extract"`, and `app/hooks/useArtifactGeneration.ts:42` passes `ARTIFACT_ROUTE[type]`, a table whose every value is an `/api/formalization/...` path:

```ts
// app/lib/types/artifacts.ts:193-197
"causal-graph": "/api/formalization/causal-graph",
"statistical-model": "/api/formalization/statistical-model",
...
counterexamples: "/api/formalization/counterexamples",
```

The third-party calls are server-only: `fetch(OPENROUTER_API_URL, ...)` lives in `app/lib/llm/callLlm.ts:164` and `streamLlm.ts:249`, whose non-type importers are exclusively `app/api/**/route.ts` handlers and the server-side `app/lib/formalization/artifactRoute.ts` (which itself imports `NextRequest`/`NextResponse`, `artifactRoute.ts:1`); the Anthropic client (`getAnthropicClient`, `streamLlm.ts:8`) sits in the same server-only module; `LEAN_VERIFIER_URL` is fetched only inside `app/api/verification/lean/route.ts:21` (paraphrased — no quote available because the caller-graph evidence spans multiple import chains). The former phantom "OpenAlex" is gone: `rg -in openalex` over the worktree returns zero hits, and the sole historical hit was the pre-amber comment itself (`git show ab4dbdb~1:proxy.ts`: "Anthropic / OpenAlex / OpenRouter calls are server-to-server") — confirming the A12 fix claim.

**Evidence:** `proxy.ts:24-26`, `app/lib/llm/callLlm.ts:7,164`, `app/lib/llm/streamLlm.ts:6-8,249`, `app/lib/formalization/artifactRoute.ts:1-8`, `app/lib/types/artifacts.ts:193-197`, `app/hooks/useDecomposition.ts:130`, `app/api/verification/lean/route.ts:21`, `git show ab4dbdb~1:proxy.ts`

---

## Claim 15: "Does not fall back to default-src. The app posts to no cross-origin form target, so 'self' is free and closes the dangling-markup / injected-`<form>` path, which needs no script and so is untouched by script-src 'strict-dynamic'."

**Location:** `proxy.ts:37-41` (directive at `proxy.ts:42`)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High

The directive is present:

```ts
// proxy.ts:42
"form-action 'self'",
```

`form-action` not falling back to `default-src` is CSP3 spec behavior, and `form-action` restrictions operating without script execution is likewise spec-correct (paraphrased — no quote available because these are CSP specification facts, not repo code). "Posts to no cross-origin form target" holds in the strongest form: `rg -n "<form|action=" app` (non-test) returns zero hits — the app renders no `<form>` elements at all (paraphrased — no quote available because the claim covers absence of matching code). The paired test updated as the disposition claims (brief item 2): the exact-key assertion in `proxy.test.ts:46-57` lists 10 sorted keys including `"form-action"`, versus 9 keys with no `form-action` in `ab4dbdb~1:proxy.test.ts:37-45`, and `proxy.test.ts:59` asserts the value: `expect(directives.get("form-action")).toBe("'self'")`.

**Evidence:** `proxy.ts:37-42`, `proxy.test.ts:44-60`, `git show ab4dbdb~1:proxy.test.ts`

---

## Claim 16: "Next 16 proxy always runs on the Node.js runtime, where crypto.randomUUID and Buffer are both available."

**Location:** `proxy.ts:48-49`
**Type:** Behavioral / Configuration
**Verdict:** Unverifiable
**Confidence:** Medium

Framework-runtime claim carried unchanged from `ab4dbdb~1` (same wording in the ancestor, `git show ab4dbdb~1:proxy.ts`). The installed Next is 16.2.4 (`package.json:23`), and in Next 16 the root `proxy.ts` file convention defaults to the Node.js runtime, where both APIs exist — consistent with the claim (paraphrased — no quote available because runtime selection happens inside Next's build/serve machinery, outside static repo analysis). Whether "always" admits no edge-runtime opt-out in this Next version cannot be settled from the repo; no runtime override is configured here (`next.config.ts` is empty, and `proxy.ts` exports no `runtime` config). Prior rounds carried the same residual; not new.

**Evidence:** `proxy.ts:47-50`, `package.json:23`, `next.config.ts:1-8`

---

## Claim 17: "Setting it only on the response is not enough: under 'strict-dynamic' the 'self' source is ignored, so un-nonced bootstrap scripts are refused and the app never hydrates. Both headers must carry the same policy."

**Location:** `proxy.ts:53-58`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium

The CSP-spec half is correct: when `'strict-dynamic'` is present, browsers ignore `'self'`/host sources in `script-src`, so scripts without the nonce are refused (paraphrased — no quote available because this is CSP3 specification behavior). The Next-behavior half — that the *request* header is how the nonce reaches the renderer and that response-only would break hydration — is the same framework-internal mechanism as Claim 3 and is not exercisable by the unit suite; the suite verifies only that both headers do carry the same policy: `expect(forwarded).toBe(response.headers.get("Content-Security-Policy"))` (`proxy.test.ts:95`), which passes. CSP forwarding is intact post-x-nonce-deletion (brief item 3).

**Evidence:** `proxy.ts:53-61`, `proxy.test.ts:88-96`

---

## Claim 18: "Everything except API routes ..., Next's build output and image optimizer ..., and /favicon.ico. Anything else — page navigations, prefetched documents, files under public/, 404s — gets the policy. ... Each exclusion is anchored so it cannot swallow a sibling route: `api` only matches /api and /api/..., never a future /apidocs; `favicon.ico` only matches the whole path."

**Location:** `proxy.ts:74-83` (matcher at `proxy.ts:85-89`)
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The coverage description and both named anchor examples are exactly right, confirmed against Next's own vendored `path-to-regexp` at 16.2.4 (Claim 11): `/api` and `/api/formalization/lean` excluded, `/apidocs` and `/api-status` covered, `/favicon.ico` excluded, `/favicon.ico.map` covered, `/`, `/graph`, `/logo.svg` (public/), and `/does-not-exist` (404) covered. The one imprecision is the universal quantifier "Each exclusion is anchored": the `_next/static` and `_next/image` alternates are unanchored prefixes. Runtime check against the same compiled regex: `/_next/staticfoo` and `/_next/image-proxy` both fail to match — i.e., hypothetical siblings of the `_next` exclusions *would* be swallowed (paraphrased — no quote available because the evidence is runtime regex output). Practical impact is nil — `/_next/` is a Next-reserved namespace with no user-defined siblings — and the sentence's own examples cite only `api` and `favicon.ico`, which are anchored:

```ts
// proxy.ts:87
source: "/((?!api(?:/|$)|_next/static|_next/image|favicon\\.ico$).*)",
```

The precise form would be "the exclusions that could collide with app routes (`api`, `favicon.ico`) are anchored."

**Evidence:** `proxy.ts:74-89`, `proxy.test.ts:136-178`, runtime check via `node_modules/next/dist/compiled/path-to-regexp`

---

## Claim 19: `ab4dbdb` commit-message verification block — "npm test 27 files / 240 tests passed (from 26/234); tsc --noEmit exit 0, empty; npm run lint exactly the 2 pre-existing react-hooks/exhaustive-deps warnings at app/page.tsx:209:6 and :271:6, a file this change does not touch."

**Location:** `ab4dbdb` commit message (verification paragraph)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High

All three re-run this round in the worktree at `ab4dbdb`: `npm test` → `Test Files 27 passed (27) / Tests 240 passed (240)`; `npx tsc --noEmit` → exit 0, empty output; `npm run lint` → exactly `2 problems (0 errors, 2 warnings)`, both `react-hooks/exhaustive-deps` at `app/page.tsx:209:6` and `app/page.tsx:271:6` (paraphrased — no quote available because the evidence is command output, reproduced in the counts just given). `app/page.tsx` is absent from `git diff --stat d86d2dc..HEAD`, confirming "a file this change does not touch". The arithmetic of the baseline delta also checks: 234 + 8 added − 2 removed = 240; 26 + 1 = 27.

**Evidence:** `ab4dbdb` commit message; `npm test`, `npx tsc --noEmit`, `npm run lint` run 2026-08-06 in `/workspace/runs/review-arms/e3-loops/wt-csp-arm2`

---

## Claim 20: A9 ACK — "`next build` fails on next/font/google reaching fonts.googleapis.com, re-failed on three passes. Owed outside the sandbox."

**Location:** `ab4dbdb` commit message (A9)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium

Not re-run this round (a `next build` attempt would reproduce a known-failing network fetch and writes `.next/` into the worktree). The mechanism is plausible and consistent with the repo: `app/layout.tsx:1` imports from `next/font/google` (`import { EB_Garamond, Geist_Mono } from "next/font/google";`, `app/layout.tsx:2`), which fetches font CSS from Google at build time in a default configuration, and the sandbox blocks external network (paraphrased — no quote available because the claim is about sandboxed build-time network behavior, not repo code). This is an accepted ACK (A9) with the owed measurement explicitly deferred outside the sandbox; recorded here for completeness, not contested.

**Evidence:** `ab4dbdb` commit message (A9); `app/layout.tsx:1-2`

---

## Claims Requiring Attention

### Incorrect

- None.

### Stale

- None.

### Mostly Accurate

- **Claim 18** (`proxy.ts:80-83`): "Each exclusion is anchored" is overbroad — `_next/static` and `_next/image` are unanchored prefixes (a hypothetical `/_next/staticfoo` would be exempt). The two examples the comment actually names (`api`, `favicon.ico`) are anchored and behave exactly as claimed; `/_next/` is Next-reserved, so no real sibling route exists to swallow. Cosmetic precision fix at most; not policy-weakening.

### Unverifiable

- **Claim 1** (`app/layout.test.ts:3-8`): whether unmocked `next/font/google` throws under vitest needs a mutation run; the mock's stated purpose and non-assertions are accurate.
- **Claim 3 / Claim 17** (`app/layout.tsx:21-25`, `proxy.ts:53-58`): Next's renderer consuming the request CSP header and stamping the nonce is framework-internal; would need an integration render. The in-repo halves (forwarding, header equality, spec behavior of `'strict-dynamic'`) are verified. Same residual as all prior rounds.
- **Claim 16** (`proxy.ts:48-49`): "always runs on the Node.js runtime" is a Next 16 runtime-selection claim outside static analysis; consistent with Next 16 defaults and unmodified config.
- **Claim 20** (`ab4dbdb` A9): sandbox `next build` failure not re-attempted; accepted ACK, measurement owed outside the sandbox as recorded.

## Goal-Alignment Note

- Answered: All 7 brief items. (1) Matcher anchoring verified against Next's own compiled `path-to-regexp` at 16.2.4 — `/apidocs` and `/api-status` covered, `/api(/...)` excluded, no `missing:`/`has` client-header condition remains (Claims 10, 11, 18). (2) `form-action 'self'` present, no-fallback comment spec-correct, key-set test widened 9→10 with a value assertion (Claim 15). (3) x-nonce deletion safe — zero readers ever under `app/` (historical `-S` search included), CSP forwarding untouched and still asserted (Claim 9). (4) `dataUrlToBlob` move byte-identical (empty diff on the function body), test git-mv'd (R096), both call sites resolve, tsc clean (Claim 7). (5) `app/layout.test.ts` genuinely falsifies the `force-dynamic` export — deletion yields `undefined` against a `toBe("force-dynamic")` assertion, and nothing else in the suite binds to the export (Claim 2). (6) connect-src invariant re-enumerated across every network primitive in `app/` — all browser calls same-origin `/api/...`, all third-party calls server-side; OpenAlex phantom confirmed gone (Claim 14); style-src rationale has a single authoritative owner in `proxy.ts` with pointer-only copies elsewhere (Claim 13). (7) New-issue sweep over the `ab4dbdb` edits found zero Incorrect and zero Stale claims; the one nuance is the overbroad "each exclusion is anchored" quantifier (Claim 18, Mostly accurate, cosmetic).
- Out of scope: A15/A17 immutable commit-message claims and `9b4e453`'s historical verification claim (loop-owner accepted-immutable overrides — verified the dispositions describe them accurately, not re-raised); A8/A9/A11 ACK merits (design judgments, not factual claims — their supporting factual assertions were spot-checked and hold, e.g. `Headers.set` CR/LF rejection is platform behavior, no jank reports exist in-repo); build-time performance measurement owed under A9 (explicitly deferred outside the sandbox).
- Escalate: Nothing. 0 Incorrect / 0 Stale on the decisive question. If the loop owner wants literal zero-imprecision comments before merge, the Claim 18 one-word tightening ("each exclusion that could collide with an app route is anchored") is the only candidate edit; it does not affect behavior and no test contradicts it.
