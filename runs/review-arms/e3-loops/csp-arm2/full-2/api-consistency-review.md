# API Consistency Review — strict CSP (iteration-1 fixes)

Worktree: `/workspace/runs/review-arms/e3-loops/wt-csp-arm2` (branch `e3/csp-arm2`)
Commit: 99e1229
Range reviewed: `d86d2dc..HEAD` (`9b4e453`, `b25e939`, `d90d6bb`, `99e1229`)
Diff surface: `app/layout.tsx`, `app/lib/utils/exportGraph.ts` (+ new `.test.ts`), new `proxy.ts` (+ new `proxy.test.ts`)

Foundation: the merged k=3 code-fact-check is taken as given and is not re-verified. Where a finding rests on it, that is stated explicitly.

---

## Baseline conventions

Sampled siblings (5), read in full, to establish what this repo has already committed to:

| Sibling | What it establishes |
|---|---|
| `app/lib/utils/export.ts` | The **core** export layer: zero-dependency, generic blob/download primitives (`triggerDownload`, `downloadTextFile`, `sanitizeFilename`). Module doc: *"Core export utilities for downloading workspace artifacts as files. Uses native Blob + createObjectURL for zero-dependency text downloads."* Generic helpers live here; feature modules import from it. |
| `app/lib/utils/exportGraph.ts` (pre-diff) | A **code-split leaf**. Module doc: *"Graph image export utilities. Separated for code-splitting since html-to-image is only needed when exporting the React Flow graph."* It imports `triggerDownload` from `export.ts`; nothing imports *into* it except `exportAll.ts` and a dynamic `import()` in `GraphPanel.tsx`. |
| `app/lib/utils/fileExtraction.ts` | Error convention for utils: `throw new Error(...)` with the **offending value interpolated** — `` throw new Error(`Unsupported file type: .${ext ?? "(unknown)"}`) `` (:85), and a remediation sentence when one exists (:81–83). |
| `app/lib/formalization/artifactRoute.ts` | `build*` prefix precedent for pure string-assembly functions: `export function buildUserMessage(req: ArtifactGenerationRequest): string` (:10). |
| `app/lib/types/decomposition.ts` | Converter-naming precedent: `toNodeVerificationStatus` (:29) / `fromNodeVerificationStatus` (:41) — `to<Target>` / `from<Source>`, not `<source>To<Target>`. |
| `app/api/**/route.ts` (17 handlers) | Request-handler convention: **17 of 17 are `async`**; responses are uniformly `NextResponse.json(...)`; **no route sets a custom header** (`rg 'headers\.set\('` over `app/` returns zero hits outside the diff). |
| `app/lib/utils/*.test.ts`, `app/lib/llm/*.test.ts` | Test convention: colocated beside the source file, `import { describe, it, expect } from "vitest"`, one `describe` per exported function named after the export. Every existing test file lives under `app/`. |
| `vitest.config.ts` | Single global project: `environment: 'jsdom'`, `globals: true`, no `include` (relies on vitest's default `**/*.{test,spec}.…` glob), no per-file environment overrides anywhere in the repo. |

Prior-iteration rubric `/workspace/runs/review-arms/e1/csp-dirty/code-review-rubric.md` was read as advisory. Its R1 (nonce never reaches the document) and R2 (`connect-src` breaks `fetch(dataUrl)`) are **resolved** at 99e1229 — verified against `proxy.ts:46–47` and `exportGraph.ts:53,66`. Its A4, A9, G4 and G5 are **not** resolved; they are re-derived from current code below rather than carried over.

---

## Name-Pattern Audit (required)

Every new public name in the range, against its closest existing neighbor.

| New public name | Location | Kind | Closest existing neighbor(s) | Verdict |
|---|---|---|---|---|
| `buildCsp(nonce: string): string` | `proxy.ts:19` | exported fn | `buildUserMessage(req): string` — `app/lib/formalization/artifactRoute.ts:10` | **Consistent.** `build<Noun>` returning an assembled string, pure, no I/O. Matches precedent exactly. |
| `dataUrlToBlob(dataUrl: string): Blob` | `app/lib/utils/exportGraph.ts:23` | exported fn | `toNodeVerificationStatus` / `fromNodeVerificationStatus` — `app/lib/types/decomposition.ts:29,41` | **Name consistent, placement inconsistent.** No `<source>To<Target>` precedent exists in `app/**`; the repo's converter precedent is `to<Target>`/`from<Source>`. The `xToY` spelling is web-platform-idiomatic and reads unambiguously, so the name itself is fine. The *module* it lives in is the problem — see #2. |
| `proxy(request: NextRequest): NextResponse` | `proxy.ts:34` | exported fn | `export async function POST(req: NextRequest)` ×17 — `app/api/**/route.ts` | **Framework-mandated name, but sync.** See #11. |
| `config` (with `matcher`) | `proxy.ts:59` | exported const | No precedent — the repo has no other framework config export outside `next.config.ts` / `vitest.config.ts` | **Framework-mandated.** No repo convention to violate. |
| `x-nonce` request header | `proxy.ts:50` | wire contract | **No existing precedent in `app/**`** — zero `headers.set(` calls outside this diff; no custom `x-*` header anywhere in the repo | **Inconsistent** — a first-of-its-kind wire contract with no production reader. See #1. |
| `dynamic = "force-dynamic"` | `app/layout.tsx:26` | route-segment config | **No existing precedent in the repo** — `rg 'export const (dynamic\|runtime\|revalidate\|maxDuration\|fetchCache)' app/` returns this line and nothing else | **Repo-first, applied at the broadest possible scope.** See #7. |

---

## Findings

#### 1. `x-nonce` is a new wire contract with zero production readers, now locked in by tests

**Severity:** Inconsistent
**Location:** `proxy.ts:48–50`; asserted at `proxy.test.ts:88–95, 97–108`
**Move:** Consumer contracts / dead surface
**Confidence:** High
**Precedent:** No existing precedent in `app/**` — `rg 'headers\.set\('` over `app/` returns zero hits outside this diff, and `rg 'x-nonce'` over the worktree returns only `proxy.ts:48,50` (the write) and `proxy.test.ts` (the assertions). No `<Script nonce=…>` and no `headers()` read exists anywhere.
**Evidence:**
```ts
  // Overwrite (not append) so a client-supplied x-nonce cannot be smuggled
  // through to a server component.
  requestHeaders.set("x-nonce", nonce);
```
and the layout comment at `app/layout.tsx:23–25`, which explicitly declines to consume it: *"Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) … so nothing here reads it directly."*
**Legibility-target:** the next contributor who greps `x-nonce`, finds a test asserting it and concludes something depends on it.
The merged fact-check already grades this as *"x-nonce protects a nonexistent consumer."* The API-consistency consequence is the part iteration 1 made worse, not better: at d90d6bb `x-nonce` was an unused write; at 99e1229 it is an unused write **with two dedicated tests**, one of which frames it as a security control ("overwrites a client-supplied x-nonce rather than appending it"). Tests are how this repo documents contracts — `app/lib/utils/workspacePersistence.test.ts` tests exactly the surface `workspacePersistence.ts` exports. Test-locking a header nothing reads inverts that: it publishes a contract the codebase does not honor and raises the cost of deleting it. It also gives the repo two carriers for one value (the `'nonce-…'` token inside the request CSP, which Next actually reads, and `x-nonce`, which nothing reads) with no stated source of truth.
**Recommendation:** Pick one. Either (a) delete `proxy.ts:48–50` and the two tests, since `requestHeaders.set("Content-Security-Policy", csp)` at :47 is the mechanism that works — and note that `x-nonce`'s removal does not let you drop the `NextResponse.next({ request })` wrapper, which the CSP forwarding still needs; or (b) land a real reader (a `<Script nonce={(await headers()).get("x-nonce")}>` or an inline-style nonce consumer) in the same change, and have the test assert against *that* consumer rather than against the header in isolation.

#### 2. `dataUrlToBlob` is a generic primitive published from the code-split, graph-only leaf module

**Severity:** Inconsistent
**Location:** `app/lib/utils/exportGraph.ts:16–44`
**Move:** Module placement / import-graph consistency
**Confidence:** High
**Precedent:** `triggerDownload(blob, filename)` used in `app/lib/utils/export.ts:8` — the repo's established home for generic, dependency-free blob plumbing; `exportGraph.ts:7` imports it from there rather than redefining it.
**Evidence:** the module's own docstring, unchanged by this diff, at `app/lib/utils/exportGraph.ts:1–4`:
```ts
/**
 * Graph image export utilities. Separated for code-splitting since
 * html-to-image is only needed when exporting the React Flow graph.
 */
```
and the new export at :23: `export function dataUrlToBlob(dataUrl: string): Blob`.
**Legibility-target:** a future contributor who needs data-URL→Blob decoding somewhere unrelated to graphs.
`export.ts` and `exportGraph.ts` are split along an explicit axis the repo wrote down: `export.ts` is "core … zero-dependency", `exportGraph.ts` is the `html-to-image` chunk. `dataUrlToBlob` sits on the `export.ts` side of that line by every stated criterion — it touches no DOM, no React Flow, no `html-to-image`, and its own tests (`exportGraph.test.ts`) exercise it on `text/plain` and `application/octet-stream` payloads that have nothing to do with graphs. Leaving it in the leaf means any second consumer either pulls `html-to-image` into its bundle (defeating the documented split, and `GraphPanel.tsx:101–102` dynamic-imports this module precisely to avoid that) or copies the function. The same misplacement makes the test file's identity ambiguous: `exportGraph.test.ts` currently contains *only* `describe("dataUrlToBlob")` and nothing about graph export, whereas every sibling test file is named for the module whose exports it covers.
**Recommendation:** Move `dataUrlToBlob` to `app/lib/utils/export.ts` beside `triggerDownload`, import it into `exportGraph.ts`, and move the five cases to a new `export.test.ts`. That also restores `exportGraph.test.ts` as the natural place for the consumer-contract tests missing in #10.

#### 3. Two authoritative docs give contradictory rationales for the same `style-src` carve-out

**Severity:** Inconsistent
**Location:** `proxy.ts:12–14` vs. `proxy.test.ts:59–63`
**Move:** Documented-contract consistency
**Confidence:** High (rests on merged fact-check, which grades `proxy.ts`'s Tailwind rationale **Incorrect** and `proxy.test.ts:60–61` correct; not re-verified here)
**Evidence:**
```ts
 * Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening
 * to nonces would require rebuilding how Tailwind ships styles in dev and
 * SSR. Documented as a deliberate carve-out, not an oversight.
```
against, in the same change:
```ts
    // Required by React style={} attributes, reactflow's inline transforms and
    // KaTeX; removing it silently breaks graph layout and equation sizing.
```
**Legibility-target:** whoever later tries to tighten `style-src` to nonces.
A CSP directive's carve-out is a contract with the app's whole rendering stack, and this change ships two mutually exclusive statements of what that contract protects, both written as authoritative and both introduced by the same PR. They imply opposite migration paths: the `proxy.ts` version says the blocker is Tailwind's build pipeline (fix by changing how Tailwind ships styles); the test version says the blocker is runtime `style={}` from React, reactflow and KaTeX (no Tailwind change would help). A reader who trusts `proxy.ts` — the file the directive lives in, and the one a `rg "unsafe-inline"` lands on first — will do work that cannot succeed. The test comment is the correct one and is the one guarded by an assertion, which makes the module docstring the odd document out.
**Recommendation:** Replace `proxy.ts:12–14` with the test's rationale (React `style={}`, reactflow inline transforms, KaTeX) and have it point at `proxy.test.ts`'s assertion as the guard, so there is one statement of the carve-out and one place that fails if it is removed.

#### 4. The same route returns a CSP on navigation and no CSP on prefetch

**Severity:** Inconsistent
**Location:** `proxy.ts:59–72`
**Move:** Response-contract symmetry across a single surface
**Confidence:** Medium-High
**Evidence:**
```ts
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```
with the comment at :60–62: *"Apply CSP to page navigations only. Skip … prefetches (which would otherwise burn a nonce on a request that may never paint)."*
**Legibility-target:** anyone reasoning about "does `/graph` ship a CSP?" — the honest answer is "sometimes".
The repo's existing response contract is uniform: all 17 route handlers answer with `NextResponse.json(...)` and none varies its headers by request provenance. This matcher makes the header set for `GET /graph` depend on a client-supplied hint (`purpose: prefetch` / `next-router-prefetch`), which is request metadata the client fully controls. Two consequences follow for consumers: a browser or crawler that sends `purpose: prefetch` receives the document with no `Content-Security-Policy` at all, and — because prefetch also skips the *request* header — a prefetched RSC payload is rendered without a nonce in scope. The scope exclusions have the same shape of imprecision the prior rubric flagged (A9) and the diff has not changed them: `source` is an unanchored prefix lookahead, so `/apidocs` or `/_next/imageproxy` fall outside CSP, while the five files in `public/` (`file.svg`, `globe.svg`, `next.svg`, `vercel.svg`, `window.svg`) fall *inside* it despite the comment claiming "page navigations only".
**Recommendation:** Decide explicitly whether the contract is "every HTML/RSC response carries CSP" or "navigations only", write that down, and make the matcher say it: anchor each alternative (`/api(?:/|$)`) and add an extension guard so `public/` assets fall out. If the prefetch skip stays, note in the comment that prefetch responses are deliberately unprotected — the "burn a nonce" rationale describes a cost, not a safety argument.

#### 5. New error message drops the offending value that sibling utils include

**Severity:** Minor
**Location:** `app/lib/utils/exportGraph.ts:25–27`
**Move:** Error-shape consistency
**Confidence:** High
**Evidence:**
```ts
  if (!dataUrl.startsWith("data:") || commaIndex === -1) {
    throw new Error("Not a data: URL");
  }
```
against the neighbor convention at `app/lib/utils/fileExtraction.ts:85`: `` throw new Error(`Unsupported file type: .${ext ?? "(unknown)"}`) ``.
**Legibility-target:** whoever reads `console.error("[graph export]", err)` in a bug report.
Both consumers swallow this error into a log line — `GraphPanel.tsx:105–106` (`console.error("[graph export]", err)`) and `exportAll.ts:69–70` (`console.warn("[export] Could not capture graph image:", err)`). With no context in the message, those log lines cannot distinguish "`toPng` returned something unexpected" from "the argument was a URL" — and since `toPng`'s output is the only real input, a failure here is exactly the case a maintainer needs detail on. The two failure modes are also merged: a non-`data:` prefix and a missing comma produce the same string. The message additionally omits the remediation sentence that `fileExtraction.ts:81–83` includes.
**Recommendation:** `` throw new Error(`Not a data: URL: ${dataUrl.slice(0, 32)}…`) ``, or split the two conditions so the message names which invariant failed. Keep the truncation — the argument can be megabytes.

#### 6. `dataUrlToBlob` presents as a general data-URL decoder but silently narrows what `fetch()` accepted

**Severity:** Minor
**Location:** `app/lib/utils/exportGraph.ts:23–44`
**Move:** Replacement-parity / scope-of-promise
**Confidence:** Medium-High
**Evidence:**
```ts
  const isBase64 = header.endsWith(";base64");
  const mediaType =
    (isBase64 ? header.slice(0, -";base64".length) : header).split(";")[0] ||
    "application/octet-stream";
```
**Legibility-target:** a second caller who reads the name and the tests and assumes general data-URL support.
The function replaces `fetch(dataUrl)` + `res.blob()` (removed at `exportGraph.ts:53,66`), and its name, signature and test suite all advertise a general decoder — the tests deliberately exercise `text/plain`, percent-encoding, `application/octet-stream` and parameter-dropping, none of which `toPng` ever produces. Against that advertised scope it diverges from the `fetch()` it replaces in two ways. `;base64` is matched case-sensitively, but RFC 2397's token and every browser's `fetch` treat it case-insensitively, so `data:image/png;Base64,…` is decoded as percent-encoded text and returns garbage bytes with no error. And an omitted media type falls back to `application/octet-stream`, where RFC 2397 and `fetch` both default to `text/plain;charset=US-ASCII`. Neither divergence can bite the current two call sites — `toPng` emits lowercase `data:image/png;base64,` — so this is scoped as Minor, but the public name and the test suite are what a third caller will trust, and they promise more than the implementation delivers. The non-base64 branch has the matching issue: `decodeURIComponent(payload)` into `new Blob([string])` re-encodes as UTF-8 regardless of any `;charset=` the caller declared, which the "drops parameters from the media type" test at `exportGraph.test.ts:31–35` pins as intended behavior without noting the consequence.
**Recommendation:** Either narrow the promise or widen the implementation. Narrowing is cheaper: rename to something scoped (`pngDataUrlToBlob`) or document in the JSDoc that the supported input is exactly what `html-to-image` emits, and drop the `text/plain` cases from the test suite so they stop advertising generality. If it stays general, lowercase `header` before the `;base64` test and use the RFC default.

#### 7. `export const dynamic = "force-dynamic"` is a repo-first rendering contract applied at the widest possible scope

**Severity:** Minor
**Location:** `app/layout.tsx:21–26`
**Move:** Scope of a new global contract
**Confidence:** High
**Precedent:** **No existing precedent in the repo** — `rg 'export const (dynamic|runtime|revalidate|maxDuration|fetchCache)' app/` returns exactly this one line. No route segment in `app/` had previously opted out of Next's default rendering mode.
**Evidence:**
```tsx
// Every route under this layout must render per request: a statically
// prerendered HTML document would bake in one nonce and reuse it for every
// visitor, which defeats the nonce. …
export const dynamic = "force-dynamic";
```
**Legibility-target:** the contributor who later adds a static marketing or docs page under `app/` and cannot work out why it is never prerendered.
The comment is now accurate — it correctly states the mechanism and correctly says the layout reads nothing, which fixes the prior iteration's A1. The remaining consistency issue is scope, not correctness: this is the first route-segment config the repo has, and it is placed on the **root** layout, so it silently governs every current and future page. Nothing at the page level records that the constraint exists or that it comes from CSP; a page author sees only `layout.tsx`. The repo's own `CLAUDE.md:34` inventory still describes `layout.tsx` as *"Sets up fonts (EB Garamond serif + Geist Mono) and metadata"*, with no mention of a rendering-mode contract and no entry at all for a root-level `proxy.ts`, so the one place a contributor is told what each file does is now stale on exactly this point.
**Recommendation:** Keep the placement (it is the correct scope for a per-request nonce), but close the documentation loop: add the rendering-mode contract to `CLAUDE.md:34`, add a `proxy.ts` line to the structure list, and record the CSP approach in `docs/decisions/` — the directory holds 8 records and none covers CSP, while `CLAUDE.md:91` asks for a record on a significant architectural approach.

#### 8. The runtime comment names Edge; the code runs on Node and declares no runtime

**Severity:** Minor
**Location:** `proxy.ts:35–37`
**Move:** Documented-contract accuracy
**Confidence:** High (rests on merged fact-check, which grades the "Edge runtime" comment **Incorrect**; not re-verified here)
**Evidence:**
```ts
  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
  // available in the Edge runtime that Next proxy runs in.
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```
**Legibility-target:** anyone deciding whether a given API is safe to call in this file.
The comment is the file's only statement about its execution environment, and it is wrong. It is also the justification for the two APIs on the very next line, so it reads as a checked claim rather than an aside — a later contributor extending `proxy` will use it to rule an API in or out and will be reasoning from the wrong runtime. The file declares no `export const runtime`, and no file in the repo does, so there is nothing else to correct the record.
**Recommendation:** Fix the comment to name the Node runtime. If the intent really is Edge portability, make it a contract rather than a comment — add `export const runtime = "edge"` and replace `Buffer.from(...).toString("base64")` with a Web-API equivalent, since `Buffer` is the Node-only call in that line.

#### 9. `connect-src` rationale names a third party the codebase does not call

**Severity:** Minor
**Location:** `proxy.ts:16–17`
**Move:** Documented-contract accuracy
**Confidence:** High (rests on merged fact-check: the connect-src claim holds but names a nonexistent OpenAlex integration; not re-verified here)
**Evidence:**
```ts
 * `connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter
 * calls are server-to-server (Next API routes), not browser-to-third-party.
```
**Legibility-target:** whoever audits which external origins the browser is allowed to reach.
The conclusion is right, but the inventory backing it is not, and this comment is the only written record of which integrations were considered when `connect-src` was tightened. An inventory that lists a non-existent dependency is one a future auditor cannot use to check completeness — the natural next question, "is this list still current?", has no reliable answer once one entry is known to be invented.
**Recommendation:** Drop `OpenAlex`, or replace the enumeration with the invariant that actually holds ("all third-party API calls originate from Next route handlers, never the browser"), which stays true as integrations change.

#### 10. The consumer contract the fix was supposed to preserve is the one thing the new tests do not cover

**Severity:** Minor
**Location:** `app/lib/utils/exportGraph.test.ts:1–40`; consumers at `app/components/panels/GraphPanel.tsx:98–110`, `app/lib/utils/exportAll.ts:62–71`
**Move:** Consumer-contract verification
**Confidence:** High
**Evidence:** the whole new test file is a single `describe("dataUrlToBlob", …)`; there is no `describe` for `downloadGraphAsPng` or `graphToPngBlob`, and no test imports either.
**Legibility-target:** a reviewer asking "what stops the next refactor of this file from breaking export?"
The fact-check confirms the signatures are preserved and that both consumers already `catch`. That is true today and untested tomorrow. `graphToPngBlob(viewport): Promise<Blob>` is the contract `exportAll.ts:64` binds to, and `downloadGraphAsPng` is what `GraphPanel.tsx:104` binds to; the change swapped their internals from an async `fetch` to a synchronous decoder that can now `throw`. The repo's convention is that the exported surface is what gets tested — `costs.test.ts` imports five exports and gives each its own `describe`; `workspacePersistence.test.ts` imports six. Here the module gained a third export and the two pre-existing ones remain uncovered, so the "signatures preserved / consumers still catch" property that justified the fix has no guard. The failure mode is quiet: if `dataUrlToBlob` ever threw synchronously *outside* an async function, `exportAll.ts`'s best-effort `try` would still swallow it and the zip would ship without `proof-graph.png`.
**Recommendation:** Add a `describe("graphToPngBlob")` with `toPng` mocked (`vi.mock("html-to-image")` — `workspacePersistence.test.ts:1` already establishes `vi` usage) asserting it resolves to a `Blob` with `type === "image/png"`, and one case asserting a bad `toPng` return rejects rather than resolving to an empty blob. If #2 is taken, these land in `exportGraph.test.ts` after `dataUrlToBlob`'s cases move to `export.test.ts`.

#### 11. `proxy` is synchronous while all 17 request handlers in the repo are async

**Severity:** Informational
**Location:** `proxy.ts:34`
**Move:** Signature consistency across request handlers
**Confidence:** High
**Precedent:** `export async function POST(req: NextRequest)` / `GET` — 17 of 17 handlers under `app/api/**/route.ts` are `async` (`rg 'export (async )?function (GET|POST|…)' app/api/` → 17 matches, all `async`); zero are sync.
**Evidence:** `export function proxy(request: NextRequest): NextResponse {`
**Legibility-target:** the contributor who adds the first `await` inside `proxy`.
Next accepts both forms and nothing is broken. The note is that this is the repo's only sync request handler, and the moment `proxy` needs to `await` anything — a nonce from an async source, a feature-flag read, an audit log — the return type changes from `NextResponse` to `Promise<NextResponse>`, and `proxy.test.ts`'s `const run = () => proxy(...)` plus all five `run().headers` assertions change with it. The async form costs nothing today and matches the 17 neighbors.
**Recommendation:** Optional. If taken, make it `export async function proxy(…): Promise<NextResponse>` and `await run()` in the tests, in the same change that would otherwise force it.

#### 12. `proxy.test.ts` binds to Next's internal `x-middleware-request-*` encoding

**Severity:** Informational
**Location:** `proxy.test.ts:8–29`
**Move:** Dependency on an undocumented internal contract
**Confidence:** High
**Evidence:**
```ts
  if (!overridden.includes(name.toLowerCase())) return null;
  return response.headers.get(`x-middleware-request-${name.toLowerCase()}`);
```
**Legibility-target:** whoever upgrades Next and sees this file go red.
This is the right call and the file says why (`proxy.test.ts:4–11`): there is no public way to observe forwarded request headers, and the forwarding is the belief worth falsifying. Recording it as a finding only because it is the one place in the repo that depends on a Next internal — no other test touches framework internals — and `package.json:23` pins `"next": "16.2.4"` without a range guard on this behavior. The failure mode is at least loud: `forwardedRequestHeader` returns `null` when the override list changes, and the tests at :85–86 and :91 assert non-null.
**Recommendation:** Keep it. Add one line to the existing docblock naming the Next version the encoding was observed on (`16.2.4`), so a post-upgrade failure reads as "internal changed" rather than "our proxy broke".

#### 13. The `dataUrlToBlob` fixture is a GIF standing in for the PNG the helper actually receives

**Severity:** Informational
**Location:** `app/lib/utils/exportGraph.test.ts:8–19`
**Move:** Fixture fidelity to the production contract
**Confidence:** High (fact-check foundation: the fixture matches `toPng`'s *shape*, not its media type)
**Evidence:**
```ts
    // 1x1 transparent GIF — the shape toPng returns (base64 image data URL).
    const dataUrl =
      "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";
```
**Legibility-target:** a reader checking whether the PNG path is covered.
The comment is honest about the substitution and the byte-level assertions (GIF89a header, `0x3b` trailer) are genuinely stronger than a PNG fixture would need to be. The gap is that no test in the range ever passes an `image/png` data URL through the function, so the media type the two production call sites depend on — `zip.file("proof-graph.png", pngBlob)` at `exportAll.ts:66`, and the `.png` filename default at `exportGraph.ts:48` — is asserted only by analogy.
**Recommendation:** Nothing required if #10 is taken, since a mocked-`toPng` test covers the PNG media type directly. Otherwise swap in a 1×1 PNG fixture and keep the byte assertions.

#### 14. `proxy.test.ts` is the first test outside `app/` and the first to exercise a non-DOM module under the global jsdom environment

**Severity:** Informational
**Location:** `proxy.test.ts` (repo root); `vitest.config.ts:5–11`
**Move:** Test-suite convention
**Confidence:** Medium-High
**Evidence:** `vitest.config.ts` declares `environment: 'jsdom'`, `globals: true`, `setupFiles: ['./vitest.setup.ts']` and **no** `include`; all 25 pre-existing test files live under `app/`.
**Legibility-target:** whoever adds the next root-level or server-side test.
The location is correct and not a violation — Next requires `proxy.ts` at the project root, and colocation is the repo's rule, so root is where its test belongs. Two second-order notes. First, discovery relies on vitest's default `**/*.{test,spec}.…` glob rather than an explicit `include`; that works, but the config no longer describes a suite that lives only under `app/`. Second, this is the first test of a server-side module, and it runs under jsdom with `vitest.setup.ts` loading `@testing-library/jest-dom/vitest` — machinery it does not use. `Buffer` and `crypto.randomUUID` resolve because vitest's jsdom environment still runs on Node, so nothing fails today; the risk is that a jsdom-only global could mask an Edge/Node-runtime incompatibility in `proxy.ts` that production would hit.
**Recommendation:** Add `// @vitest-environment node` at the top of `proxy.test.ts`, which documents the intent and removes the jsdom shim from a server-module test. If more server-side tests follow, promote it to a `projects` entry in `vitest.config.ts` with an explicit `include` per environment.

---

## What Looks Good

- **The two blockers from iteration 1 are genuinely closed at the contract level, not papered over.** `requestHeaders.set("Content-Security-Policy", csp)` (`proxy.ts:47`) is the mechanism Next actually reads, and it is asserted end-to-end at `proxy.test.ts:78–86` — including the strongest available check, that the forwarded request policy is byte-identical to the response policy. Likewise both `fetch(dataUrl)` sites are gone (`exportGraph.ts:53,66`) with `Promise<Blob>` and the `filename = "proof-graph.png"` default untouched, so `exportAll.ts:64` and `GraphPanel.tsx:104` bind to exactly what they bound to before.
- **`buildCsp` is the right extraction and the right name.** Splitting the pure policy string out of the request handler matches `buildUserMessage` (`artifactRoute.ts:10`) precisely, and it is what makes `proxy.test.ts:34–66` able to assert the *directive set* (`expect([...directives.keys()].sort()).toEqual([...])`) rather than a substring. That assertion is a real contract: adding or dropping a directive fails loudly instead of silently widening the policy.
- **The module's public surface is exactly Next 16's proxy contract** — two exports (`proxy`, `config`), both framework-required, no invented wrapper or re-export indirection, and `next/server` is the only import.
- **Idempotency is handled on the correct side of the split.** `buildCsp` is pure and deterministic (three tests call it with the same `"NONCE"` and get stable output); `proxy` is deliberately non-idempotent and that non-idempotency is itself asserted at `proxy.test.ts:110–114` — the fresh-nonce-per-request property is the one that matters and the one that is guarded.
- **The `x-middleware-request-*` helper is documented at the level a reader needs.** `proxy.test.ts:4–11` explains why the internal is being read and what belief the file exists to falsify, which is the right amount of context for a test that depends on framework internals.

---

## Summary Table

| # | Finding | Severity | Location |
|---|---|---|---|
| 1 | `x-nonce` wire contract has zero production readers, now test-locked | Inconsistent | `proxy.ts:48–50`; `proxy.test.ts:88–108` |
| 2 | `dataUrlToBlob` published from the code-split graph leaf, not `export.ts` | Inconsistent | `app/lib/utils/exportGraph.ts:16–44` |
| 3 | `proxy.ts` and `proxy.test.ts` give contradictory `style-src` rationales | Inconsistent | `proxy.ts:12–14` vs `proxy.test.ts:59–63` |
| 4 | Same route: CSP on navigation, none on prefetch; unanchored matcher scope | Inconsistent | `proxy.ts:59–72` |
| 5 | `"Not a data: URL"` omits the offending value sibling utils include | Minor | `app/lib/utils/exportGraph.ts:25–27` |
| 6 | General-decoder promise narrows `fetch()` on `;base64` casing and default media type | Minor | `app/lib/utils/exportGraph.ts:23–44` |
| 7 | `dynamic = "force-dynamic"` is repo-first, root-scoped, and undocumented in `CLAUDE.md` | Minor | `app/layout.tsx:21–26` |
| 8 | "Edge runtime" comment wrong (Node); no `export const runtime` | Minor | `proxy.ts:35–37` |
| 9 | `connect-src` rationale names a nonexistent OpenAlex integration | Minor | `proxy.ts:16–17` |
| 10 | `downloadGraphAsPng` / `graphToPngBlob` contracts remain untested | Minor | `app/lib/utils/exportGraph.test.ts` |
| 11 | `proxy` is sync; 17 of 17 repo handlers are async | Informational | `proxy.ts:34` |
| 12 | Test binds to Next-internal `x-middleware-request-*` encoding | Informational | `proxy.test.ts:8–29` |
| 13 | GIF fixture stands in for the PNG media type production depends on | Informational | `app/lib/utils/exportGraph.test.ts:8–19` |
| 14 | First test outside `app/`; server module under global jsdom env | Informational | `proxy.test.ts`; `vitest.config.ts` |

**Breaking: 0 · Inconsistent: 4 · Minor: 6 · Informational: 4**

---

## Overall Assessment

Iteration 1 fixed the two contract breaks and did not introduce a new one — no finding in this range is Breaking. `exportGraph.ts`'s exported signatures and defaults are byte-for-byte what its two consumers already bound to, `buildCsp` is a clean, correctly named extraction whose directive-set assertion is a stronger contract than the code had before, and the request-header CSP forwarding is now verified end-to-end rather than assumed.

What remains is a consistency deficit concentrated in two places. The first is `x-nonce` (#1): the fix round added tests to a header nothing reads, which converts an unused write into a published contract and makes it harder to delete — the one place where iteration 1 moved the surface in the wrong direction. The second is documentation acting as contract. Three findings (#3, #8, #9) are cases where the only written statement of a contract — the `style-src` carve-out, the execution runtime, the third-party inventory behind `connect-src` — is wrong or self-contradictory, and #3 is the sharpest because the contradiction is *internal to this change*: the file and its own test disagree about what the carve-out protects, and the file is the one a reader hits first.

`dataUrlToBlob` (#2, #6) is a smaller but compounding issue: a generic primitive published from a module the repo explicitly documented as a code-split leaf, with a name and a test suite that advertise general data-URL support the implementation only partly delivers. Moving it to `export.ts` resolves the placement, the test-file identity problem, and clears space for the consumer-contract tests missing in #10.

Ordered by what I would fix before merge: #1 (delete or land a reader), #3 (one rationale, not two), #2 (move the helper), #4 (decide and state the CSP scope contract). The Minor documentation items (#8, #9) are one-line edits worth taking in the same pass. Nothing here blocks on correctness.

## Goal-Alignment Note

- **Answered:** Baseline conventions established from 7 sibling sources read in full (`export.ts`, `exportGraph.ts` pre-diff, `fileExtraction.ts`, `artifactRoute.ts`, `decomposition.ts`, the 17 `app/api/**/route.ts` handlers, the 25 existing test files + `vitest.config.ts`). Name-Pattern Audit covers all five required new public names (`buildCsp`, `dataUrlToBlob`, `proxy`/`config`, the `x-nonce` contract, the `dynamic` export), each with an explicit `Precedent:` or `No existing precedent in <scope>` line. Consumer contracts checked: `exportGraph` signatures and defaults preserved (#10 notes they are unguarded), PNG-bytes contract traced to `exportAll.ts:66` and `GraphPanel.tsx:104`, test-file conventions audited (#13, #14). Error consistency (#5), asymmetries (#4, #11), nullability (#5 — `dataUrlToBlob` throws where the module's `getGraphViewportElement` returns `null`; both are defensible and consumers catch, so it is folded into #5 rather than raised separately), and idempotency (`buildCsp` pure, `proxy` deliberately not, both asserted — see What Looks Good) all covered.
- **Out of scope:** Whether the CSP is *secure* (nonce entropy from `crypto.randomUUID`, `'strict-dynamic'` semantics, the `'unsafe-inline'` risk itself) — security-reviewer's call; I only assess whether the carve-out is documented consistently. Whether the per-request `Headers` clone or `force-dynamic` costs measurable latency or throughput — performance-reviewer. Module-boundary and dependency-direction judgment on `proxy.ts` at the repo root — architecture-review; #2's placement finding is scoped to the documented `export.ts`/`exportGraph.ts` split, not to layering in general. All claims the merged k=3 fact-check already graded (Tailwind rationale, "Edge runtime", OpenAlex, GIF fixture, both `fetch` sites replaced, signatures preserved, consumers catch) are taken as foundation and not re-verified.
- **Escalate:** #1 (`x-nonce`) needs an orchestrator decision, not an author fix — it is the third review round to raise it (prior rubric A4 at d90d6bb), the resolution is binary (delete the header, or land a real consumer), and iteration 1 chose a third path — test it in place — that closes neither branch. #3 needs a tiebreak recorded somewhere durable: the fact-check has already graded which rationale is correct, and if that grading is not carried into the fix, iteration 3 will re-litigate it. #7's documentation gap (`CLAUDE.md:34` inventory stale, no `proxy.ts` entry, no `docs/decisions/` record for an app-wide security control, where `CLAUDE.md:91` asks for one) overlaps prior-rubric G4 and is a repo-hygiene item the orchestrator should route once rather than have each critic re-raise.
