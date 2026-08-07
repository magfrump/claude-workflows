# API Consistency Review — e3/csp-arm2, full pass 3 (FINAL)

**Commit:** 2544a19
**Range:** `d86d2dc..HEAD` (5 commits: 9b4e453, b25e939, d90d6bb, 99e1229, 2544a19)
**Worktree:** `/workspace/runs/review-arms/e3-loops/wt-csp-arm2` (branch `e3/csp-arm2`)
**Reviewed:** 2026-08-06
**Foundation:** merged code-fact-check (k=3), `full-3/code-fact-check-report.md` — 0 Incorrect. Documented behavior taken as given; not re-verified.
**Prior pass:** `full-2/code-review-rubric.md` (advisory). Prior api findings #1–#14 are re-dispositioned below.

**Headline: nothing Breaking.** No consumer-facing contract in this range is removed, renamed, or narrowed in a way that breaks an existing caller. `dataUrlToBlob` is additive; `downloadGraphAsPng` and `graphToPngBlob` keep their signatures and return types (`Promise<void>` / `Promise<Blob>`) across the `fetch` → `dataUrlToBlob` swap. The one contract that *widens* app-wide — `export const dynamic = "force-dynamic"` on the root layout — is a rendering-mode change with no call-site impact and no conflicting sibling declaration (repo-wide, `export const (dynamic|revalidate|runtime|fetchCache|maxDuration)` has exactly one hit: `app/layout.tsx:26`).

**What 2544a19 changed:** comments only (`git diff 99e1229..2544a19` touches `proxy.ts` lines 12-14 and 35-36 exclusively). The code surface reviewed here is 99e1229's. Two prior api findings close as a direct result (#3, #8 below); no finding is newly created by 2544a19.

**Verification run:** `npx vitest run proxy.test.ts app/lib/utils/exportGraph.test.ts` → 2 files, **13 tests passed**.

---

## Name-Pattern Audit (REQUIRED)

Every new public name in the range, compared against its closest existing neighbors.

| New name | Kind | Closest existing neighbors (precedent) | Verdict |
|---|---|---|---|
| `proxy(request: NextRequest)` | exported function, `proxy.ts` | **No existing precedent in this repo** — first framework entry file of its kind. Name is **mandated by Next 16** (renamed Middleware → Proxy); not a free choice. | ✅ Framework-fixed. Not a naming decision. |
| `config` (route matcher object) | exported const, `proxy.ts:62` | **No existing precedent in this repo** — `next.config.ts:3-5` declares an empty `NextConfig` and no `headers()`. Name is **mandated by Next**. | ✅ Framework-fixed. See #4 for the *value*. |
| `dynamic = "force-dynamic"` | exported const, `app/layout.tsx:26` | **No existing precedent in this repo** — repo-wide grep for route-segment config exports returns only this line. Name and value vocabulary are **mandated by Next**. | ✅ Framework-fixed. See #7 for the doc gap. |
| `buildCsp(nonce: string): string` | exported function, `proxy.ts:19` | **Precedent:** `buildUserMessage(req: ArtifactGenerationRequest): string` (`app/lib/formalization/artifactRoute.ts:10`) — the repo's only other `build*` export. Same shape: `build<Noun>(input) => string`. | ✅ Verb matches. ⚠️ Acronym casing — see #10. |
| `dataUrlToBlob(dataUrl: string): Blob` | exported function, `app/lib/utils/exportGraph.ts:23` | **Precedent:** `graphToPngBlob` in the *same file* (`exportGraph.ts:58`) — `<source>To<Target>` is the established transform-naming form; also `transformSseStream` (`app/lib/llm/`). Sibling utils use verb-first (`stripCodeFences`, `sanitizeText`, `extractTextFromPDF`). | ✅ Name is right. ⚠️ **Module placement** is not — see #2. |
| `x-nonce` | request header written by `proxy.ts:50` | **No existing precedent in `app/` for any custom `x-*` header** — repo-wide `rg '"x-[a-z-]+"' app/` returns zero hits. The repo's only header contract is `SSE_HEADERS` (`streamLlm.ts:12-16`), which uses standard names only (`Content-Type`, `Cache-Control`, `Connection`). | ⚠️ Wire name follows the wider Next-ecosystem convention, but the repo has no `x-*` precedent and **no reader** — see #1. |
| `Content-Security-Policy` (request + response) | header, `proxy.ts:47, :55` | Standard IANA header; the request-side use is Next's documented read path. | ✅ Correct on both sides; symmetry asserted by `proxy.test.ts:78-93`. |
| `forwardedRequestHeader`, `parseDirectives`, `bytesOf` | module-local test helpers | Module-local; not exported. Consistent with test files repo-wide. | ✅ No public surface. |

**Import-form audit:** `proxy.test.ts:3` imports `./proxy` (sibling relative) and `exportGraph.test.ts:2` imports `./exportGraph` — matching `exportAll.ts:9-10`'s relative-for-siblings / `@/`-for-cross-tree split (CONTRIBUTING.md:103-109). `import { describe, it, expect } from "vitest"` matches 13/13 test files that import from vitest explicitly despite `globals: true`. ✅ No deviation.

---

## Findings

### #1 — `x-nonce` is a published, now test-locked request-header contract with zero readers

**Severity:** Inconsistent
**Location:** `proxy.ts:48-50`; `proxy.test.ts:95-115`
**Precedent:** No existing precedent in `app/` for a custom `x-*` header — `rg '"x-[a-z-]+"' app/` returns zero hits. The repo's only header-contract export is `SSE_HEADERS` (`app/lib/llm/streamLlm.ts:12-16`), which is response-side and uses standard names only.
**Evidence** (verbatim, `proxy.ts:48-50`):
```
  // Overwrite (not append) so a client-supplied x-nonce cannot be smuggled
  // through to a server component.
  requestHeaders.set("x-nonce", nonce);
```
`rg "x-nonce" app/` → **0 hits**. `rg "next/headers|headers\(\)" app/ --glob '!*.test.*'` → **0 hits**. No server component, route handler, or `<Script nonce>` reads it. The nonce that actually reaches the document travels on the request `Content-Security-Policy` header (`proxy.ts:47`), not here — the layout comment says so explicitly: *"so nothing here reads it directly"* (`app/layout.tsx:22-23`).
**Impact:** A published request contract with no consumer. Iteration 2 added two dedicated tests (`"forwards x-nonce matching the nonce in the policy"`, `"overwrites a client-supplied x-nonce rather than appending it"`), which converts an unused write into a *test-locked* contract: a future reader now reasonably infers a consumer exists, and deleting the write costs two test deletions rather than one line. The overwrite guarantee also does not hold on `/api` — the matcher skips it (`proxy.ts:65`), so the 16 handlers under `app/api/` would read a caller-supplied `x-nonce`.
**Recommendation:** Binary, unchanged from pass 2 — either delete `proxy.ts:48-50` plus the two tests, **or** land a real consumer (`<Script nonce={(await headers()).get("x-nonce")}>`). This is the third consecutive pass raising it; it is an owner decision, not an author fix.
**Legibility-target:** for-orchestrator-synthesis
**Disposition:** Open (prior api #1, unchanged).

---

### #2 — `dataUrlToBlob` is published from the module that exists to be code-split away

**Severity:** Inconsistent
**Location:** `app/lib/utils/exportGraph.ts:16-44`; `app/lib/utils/exportGraph.test.ts:2`
**Precedent:** `app/lib/utils/export.ts:1-4` is the repo's declared home for generic, dependency-free download primitives, and already owns `triggerDownload(blob, filename)` and `sanitizeFilename(name)`. Its docblock states the boundary in the repo's own words:
```
/**
 * Core export utilities for downloading workspace artifacts as files.
 * Uses native Blob + createObjectURL for zero-dependency text downloads.
 */
```
**Evidence** (verbatim, `exportGraph.ts:1-6`):
```
/**
 * Graph image export utilities. Separated for code-splitting since
 * html-to-image is only needed when exporting the React Flow graph.
 */

import { toPng } from "html-to-image";
```
`dataUrlToBlob` touches neither the graph nor `html-to-image`; it is a pure `string → Blob` codec. The split is real and actively defended at the call site — `app/components/panels/GraphPanel.tsx:102` dynamic-imports the module precisely to keep `html-to-image` out of the main chunk:
```
      const { getGraphViewportElement, downloadGraphAsPng } = await import("@/app/lib/utils/exportGraph");
```
The new test file already demonstrates the pull it creates: `exportGraph.test.ts` contains a single `describe("dataUrlToBlob")` yet imports through the heavy module.
**Impact:** Any second consumer of `dataUrlToBlob` either drags `html-to-image` into its chunk — defeating the documented split — or copies the function. The repo has an explicitly-named module for exactly this kind of helper and it was not used.
**Recommendation:** Move to `export.ts` (matching the `triggerDownload` precedent) or a new `app/lib/utils/dataUrl.ts` with its own test file. This also frees `exportGraph.test.ts` to cover the two exports that remain untested (#6 below).
**Legibility-target:** for-author
**Disposition:** Open (prior api #2 / rubric A5, unchanged — code untouched by 2544a19).

---

### #3 — Contradictory `style-src` rationales — **CLOSED by 2544a19**

**Severity:** Informational (resolved)
**Location:** `proxy.ts:11-16` vs `proxy.test.ts:57-63`
**Evidence** (verbatim, `proxy.ts:11-16` at 2544a19):
```
 * Why `style-src 'unsafe-inline'`: React `style={}` attributes, reactflow's
 * inline transforms and KaTeX all emit inline styles at runtime; dev also
 * injects styles. (Tailwind v4 itself compiles to a linked stylesheet via
 * `@tailwindcss/postcss` and is already covered by `'self'`.) Tightening to
 * nonces would mean reworking how each of those ships styles. Documented as a
 * deliberate carve-out, not an oversight.
```
`proxy.test.ts:57-59`:
```
    // Required by React style={} attributes, reactflow's inline transforms and
    // KaTeX; removing it silently breaks graph layout and equation sizing.
```
**Impact (resolved):** At 99e1229 the repo carried two mutually exclusive authoritative statements of the same directive's rationale, implying opposite migration paths, with the incorrect one (`proxy.ts`, Tailwind-attributed) being the first `rg "unsafe-inline"` hit. 2544a19 rewrites `proxy.ts` to name the same three dependents as the test and explicitly retires the Tailwind attribution. The two statements now agree; the merged fact-check independently grades this range 0 Incorrect.
**Legibility-target:** for-orchestrator-synthesis
**Disposition:** **Closed** (prior api #3 / rubric A3).

---

### #4 — The matcher's response-coverage contract does not match its own comment

**Severity:** Inconsistent
**Location:** `proxy.ts:59-72`
**Precedent:** No existing precedent in this repo for a path-matching contract — `next.config.ts:3-5` declares no `headers()`, `redirects()`, or `rewrites()`. Assessed against the comment's own stated contract rather than a sibling.
**Evidence** (verbatim, `proxy.ts:59-72`):
```
export const config = {
  // Apply CSP to page navigations only. Skip API routes (they don't render
  // HTML), Next's static assets (no scripts to nonce), and prefetches (which
  // would otherwise burn a nonce on a request that may never paint).
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
  ],
};
```
Three ways the delivered contract diverges from `"page navigations only"`:
1. **Unanchored prefixes.** `api`, `_next/static`, `_next/image` are prefix alternatives with no `(?:/|$)` boundary, so a future `/apidocs` or `/api-status` route silently ships with no CSP header at all.
2. **Static assets are matched, not skipped.** `public/` holds 5 SVGs (`file.svg`, `globe.svg`, `next.svg`, `vercel.svg`, `window.svg`); none is under `_next/static`, so all five — plus 404s — do match and receive the header, contra the comment.
3. **Client-controlled opt-out.** The `missing:` block conditions the security header on request headers the requester supplies. Post-99e1229 this is a *widened* asymmetry: a prefetched document now lacks the **request**-side CSP too, so its bootstrap scripts get no nonce and the two document shapes diverge. Only the non-prefetch shape is tested (`proxy.test.ts:66-67` constructs a plain `Request`).
**Impact:** Consumers (browsers, and any future route author) cannot predict which responses carry the policy from reading the comment. The stated rationale for the `missing:` block is a `crypto.randomUUID()` cost argument — a poor exchange for a security control.
**Recommendation:** Delete the `missing:` block; anchor each alternative (`api(?:/|$)`); add a test asserting CSP is present on a `purpose: prefetch` request.
**Legibility-target:** for-author
**Disposition:** Open (prior api #4 / rubric A1, unchanged).

---

### #5 — `"Not a data: URL"` drops the offending value that sibling utils include

**Severity:** Minor
**Location:** `app/lib/utils/exportGraph.ts:24-27`
**Precedent:** `app/lib/utils/fileExtraction.ts:85` — the closest sibling error in the same directory — interpolates the rejected value:
```
      throw new Error(`Unsupported file type: .${ext ?? "(unknown)"}`);
```
`app/lib/formalization/api.ts:16, :46` similarly forward a server-supplied message (`data.error ?? "Request failed"`) rather than a bare literal.
**Evidence** (verbatim, `exportGraph.ts:24-27`):
```
  const commaIndex = dataUrl.indexOf(",");
  if (!dataUrl.startsWith("data:") || commaIndex === -1) {
    throw new Error("Not a data: URL");
  }
```
**Impact:** Two distinct failure modes (wrong scheme; well-formed `data:` prefix but no comma) collapse into one indistinguishable string, and neither carries the input. Both consumers swallow it into a log line — `exportAll.ts:67-68` does `console.warn("[export] Could not capture graph image:", err)` — where the distinction is exactly what a debugger would need.
**Recommendation:** Interpolate a truncated prefix of the input and split the two conditions, matching `fileExtraction.ts:85`.
**Legibility-target:** for-author
**Disposition:** Open (prior api #5 / rubric G7).

---

### #6 — `downloadGraphAsPng` / `graphToPngBlob` — the two contracts the change was meant to preserve — remain the module's only untested exports

**Severity:** Minor
**Location:** `app/lib/utils/exportGraph.test.ts` (whole file); `exportGraph.ts:46-66`
**Precedent:** `app/lib/utils/fileExtraction.test.ts` covers the public entry point `extractTextFromFile` alongside the `sanitizeText` helper, not the helper alone; `app/lib/llm/streamLlm.test.ts` mocks `fetch` to exercise the public streaming export. The repo's convention is to test the consumer-facing export.
**Evidence** (verbatim, the entire test surface added for this module — `exportGraph.test.ts:6`):
```
describe("dataUrlToBlob", () => {
```
No other `describe` exists in the file. Yet the diff changed both public exports' internals:
```
-  const res = await fetch(dataUrl);
-  const blob = await res.blob();
-  triggerDownload(blob, filename);
+  triggerDownload(dataUrlToBlob(dataUrl), filename);
```
**Impact:** The swap replaced an `await`ed rejection with a *synchronous* throw inside an `async` function. It still surfaces as a rejected promise, so `exportAll.ts:61-69`'s best-effort `try` still catches it — but nothing asserts that, and no test passes an `image/png` data URL through either public path. The media type both call sites depend on (`zip.file("proof-graph.png", …)` at `exportAll.ts:65`; the `filename = "proof-graph.png"` default at `exportGraph.ts:48`) is asserted only by analogy with the GIF fixture (#13).
**Recommendation:** One test per public export with `toPng` mocked to return a 1×1 PNG data URL. Closes #13 for free.
**Legibility-target:** for-author
**Disposition:** Open (prior api / rubric G6).

---

### #7 — Four documentation surfaces that the repo's own rules require updating are unchanged

**Severity:** Minor
**Location:** `CLAUDE.md:34`, `CLAUDE.md:91`, `CLAUDE.md:95-103`, `CONTRIBUTING.md:95-101`, `docs/decisions/`
**Precedent:** `docs/decisions/` holds 8 records (`001-formal-artifact-types`, `001-vitest-test-framework`, `002-multi-artifact-ui-layout`, `003-artifact-generation-api`, `004-generalized-decomposition`, `005-streaming-api-responses`, `005-zustand-state-management`, `007-cost-estimation-model`) — including one for the *test framework*, which is a lower-stakes cross-cutting choice than an app-wide security header.
**Evidence** (verbatim, `CLAUDE.md:91`):
```
- When choosing a new library or significant architectural approach, create a short decision record in `docs/decisions/NNN-title.md` explaining what was chosen and why
```
`CLAUDE.md:34` still describes the changed file by its pre-change responsibilities only:
```
- `layout.tsx` — Sets up fonts (EB Garamond serif + Geist Mono) and metadata
```
`CONTRIBUTING.md:95-101`'s Project Structure lists `app/components/…`, `app/lib/`, `app/api/` and has no entry for a repo-root framework file. `rg -l 'middleware|Content-Security|CSP|proxy\.ts'` across `README.md CLAUDE.md CONTRIBUTING.md docs/` matches only two unrelated Zustand documents.
**Impact:** The CSP control now spans four files (`proxy.ts`, `proxy.test.ts`, `app/layout.tsx`, `exportGraph.ts`) and is documented exclusively by inline comments. `layout.tsx` has acquired a *rendering-mode* contract binding every current and future route under the root layout, and the file's one-line inventory entry does not mention it — a contributor reading `CLAUDE.md` would not learn that adding `export const revalidate = 60` to a page breaks the nonce.
**Recommendation:** `docs/decisions/008-csp-nonce-proxy.md`; extend the `layout.tsx` inventory line with the `force-dynamic` contract and its reason; add a root-file line for `proxy.ts`.
**Legibility-target:** for-author
**Disposition:** Open (prior api #7 / #11, rubric G11).

---

### #8 — "Edge runtime" runtime claim — **CLOSED by 2544a19**

**Severity:** Informational (resolved)
**Location:** `proxy.ts:35-36`
**Evidence** (verbatim, `git diff 99e1229..2544a19`):
```
-  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
-  // available in the Edge runtime that Next proxy runs in.
+  // Generate a fresh nonce per request. Next 16 proxy always runs on the
+  // Node.js runtime, where crypto.randomUUID and Buffer are both available.
```
**Impact (resolved):** The module's only statement about its execution environment was wrong, and it is the stated justification for the two platform APIs on the following line — a contributor extending `proxy` would have ruled APIs in or out from the wrong runtime. Now correct and consistent with `package.json`'s `"next": "16.2.4"`.
**Legibility-target:** for-orchestrator-synthesis
**Disposition:** **Closed** (prior api #8 / rubric R1).

---

### #9 — `connect-src` rationale enumerates an integration that does not exist

**Severity:** Minor
**Location:** `proxy.ts:16-17`
**Precedent:** No existing precedent in this repo for a documented integration inventory — this comment is the only written record of which outbound calls were weighed. Assessed for internal accuracy.
**Evidence** (verbatim, `proxy.ts:16-17`):
```
 * `connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter
 * calls are server-to-server (Next API routes), not browser-to-third-party.
```
Repo-wide, the sole `OpenAlex` hit is this comment. The conclusion holds independently — I re-enumerated every browser-reachable `fetch`: `useAnalytics.ts:11,:30` (`/api/analytics`), `formalization/api.ts:10,:38,:104` (relative + `/api/verification/lean`), `LeanCodeDisplay.tsx:88`, `ContextInput.tsx:25` — all same-origin. `OPENROUTER_API_URL` appears only in `callLlm.ts:164` / `streamLlm.ts:249`, imported exclusively by files under `app/api/` (16 route handlers).
**Impact:** An inventory with one known-phantom entry cannot answer "is this list still current?" — the question the comment exists to answer when someone proposes adding a browser-side integration.
**Recommendation:** Drop `OpenAlex`, or replace the enumeration with the invariant that actually survives: *"all third-party calls originate from Next route handlers, never the browser."*
**Legibility-target:** for-author
**Disposition:** Open (prior api #9 / rubric A12; carried as an MA in the merged fact-check).

---

### #10 — `buildCsp` acronym casing, and the policy is exported from the framework entry file

**Severity:** Minor
**Location:** `proxy.ts:19`
**Precedent (verb form):** `buildUserMessage` (`app/lib/formalization/artifactRoute.ts:10`) — matched exactly. **Precedent (acronym casing):** the repo is already split — `extractTextFromPDF` (`fileExtraction.ts:34`) capitalizes, while `parsePdfPropositions` (`pdfPropositionParser.ts:494`), `isPdfTexCompiled` (`:429`) and `graphToPngBlob` / `downloadGraphAsPng` (`exportGraph.ts`) do not.
**Evidence** (verbatim, `proxy.ts:19`):
```
export function buildCsp(nonce: string): string {
```
**Impact:** Casing is defensible — `Csp` matches the more populous camel-cased-acronym group and the same-diff `dataUrlToBlob`/`Png` neighbors — so this is *not* a naming defect. The consistency issue is the **module** the export lives in: the policy for the whole app is now a public export of a repo-root file that exists only because Next looks for that filename, and Next has already renamed this file once (Middleware → Proxy, per `proxy.ts:4`). Any future consumer — a `report-uri` endpoint, a Report-Only rollout, a `next.config.ts` static-header path, a test fixture — must import from the framework entry module. Separately, exporting turned an internal invariant into an unenforced parameter contract: `buildCsp` accepts any string and splices it into a security policy (`"x' 'unsafe-inline"` weakens it; `;` appends directives). Not reachable today — the sole caller is `proxy.ts:39` with `Buffer.from(crypto.randomUUID()).toString("base64")`.
**Recommendation:** Move to `app/lib/security/csp.ts`; either validate the nonce at the boundary or invert to `buildCsp(): { nonce, csp }`.
**Legibility-target:** for-author
**Disposition:** Open (prior rubric A8).

---

### #11 — `dataUrlToBlob` diverges from the `fetch(dataUrl)` behavior it replaces

**Severity:** Minor
**Location:** `app/lib/utils/exportGraph.ts:23-44`
**Precedent:** The replaced call — `const res = await fetch(dataUrl); const blob = await res.blob();` — *is* the precedent, and it implemented RFC 2397 fully. A drop-in substitute inherits that expectation, which the docstring reinforces by framing itself as a spelling change.
**Evidence** (verbatim, `exportGraph.ts:29-33`):
```
  const isBase64 = header.endsWith(";base64");
  const mediaType =
    (isBase64 ? header.slice(0, -";base64".length) : header).split(";")[0] ||
    "application/octet-stream";
```
Four divergences from the `fetch` path: `;BASE64` (case variant) falls into the percent-decode branch and silently corrupts; whitespace before `;base64` is not tolerated; the non-base64 branch re-encodes as UTF-8 regardless of `;charset=`; an omitted media type defaults to `application/octet-stream` where RFC 2397 and `fetch` use `text/plain;charset=US-ASCII`.
**Impact:** Unreachable today — both callers pass lowercase `toPng` output. But the exported name, the `(string) => Blob` signature, and a five-case test suite that deliberately exercises percent-encoding, parameter stripping, and non-UTF-8 bytes all advertise a general decoder. The tests widen the apparent contract beyond what the implementation honors.
**Recommendation:** Either narrow the contract in the docstring ("handles `toPng` output; not a general RFC 2397 decoder") or case-fold the `;base64` check and trim the header.
**Legibility-target:** for-author
**Disposition:** Open (prior api #6 / rubric G2).

---

### #12 — `proxy` is the repo's only synchronous request handler

**Severity:** Informational
**Location:** `proxy.ts:34`
**Precedent:** 17 of 17 other request handlers are `async` — `rg 'export (async )?function (GET|POST|DELETE|PUT)' app/api -g route.ts` returns 17 declarations, all `async`.
**Evidence** (verbatim, `proxy.ts:34`):
```
export function proxy(request: NextRequest): NextResponse {
```
**Impact:** Correct and deliberate — nothing in the body awaits, and a sync return is marginally cheaper per request. Flagged only because it is a shape a contributor will notice; the return type is `NextResponse`, not `NextResponse | Promise<NextResponse>`, so adding any `await` later is a signature change at the one place Next calls it.
**Recommendation:** None. Recorded for awareness.
**Legibility-target:** for-orchestrator-synthesis
**Disposition:** Open (prior api #11 / rubric G11).

---

### #13 — The R1 falsifier is pinned to Next's private header transport with no version signpost

**Severity:** Informational
**Location:** `proxy.test.ts:5-22`
**Precedent:** No existing precedent in this repo for depending on a framework's private encoding — the closest analogue, `streamLlm.test.ts`, mocks the public `fetch` boundary.
**Evidence** (verbatim, `proxy.test.ts:5-11`):
```
/**
 * `NextResponse.next({ request: { headers } })` cannot expose the forwarded
 * request headers directly — Next encodes them onto the response as
 * `x-middleware-request-<lowercased-name>`, with the overridden names listed in
 * `x-middleware-override-headers`, and unpacks them before render. Reading that
 * encoding is the only way to assert from a unit test that the nonce actually
 * reaches the document, which is the belief this file exists to falsify.
 */
```
**Impact:** The failure direction is safe — if Next changes the encoding, `forwardedRequestHeader` returns `null` and the guarded assertions fail loudly rather than passing vacuously. The gap is triage: a maintainer facing a red suite after a Next bump must reconstruct whether the proxy broke or the test's assumption did, and the wrong call (weakening the assertion) silently disarms the falsifier. The docblock names no version, and `package.json` pins `"next": "16.2.4"`.
**Recommendation:** Add `next@16.2.4` plus a one-line triage rule to the docblock; optionally a canary asserting `x-middleware-override-headers` exists at all.
**Legibility-target:** for-author
**Disposition:** Open (prior api #12 / rubric A7).

---

### #14 — A GIF fixture stands in for the PNG media type both call sites depend on

**Severity:** Informational
**Location:** `app/lib/utils/exportGraph.test.ts:8-19`
**Precedent:** `fileExtraction.test.ts` exercises the actual file types the extractor ships for. The convention is fixture-matches-production-input.
**Evidence** (verbatim, `exportGraph.test.ts:9-12`):
```
    // 1x1 transparent GIF — the shape toPng returns (base64 image data URL).
    const dataUrl =
      "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";
    const blob = dataUrlToBlob(dataUrl);
    expect(blob.type).toBe("image/gif");
```
**Impact:** The comment is honest about the substitution and the byte assertions (`GIF89a` header, `0x3b` trailer) are stronger than a PNG fixture needs. But no test in the range passes an `image/png` data URL, so `blob.type === "image/png"` — which `exportAll.ts:65` relies on when writing `proof-graph.png` — is asserted only by analogy.
**Recommendation:** Swap in a 1×1 PNG fixture, keeping the byte assertions. Moot if #6 lands.
**Legibility-target:** for-author
**Disposition:** Open (prior api #13 / rubric A13).

---

### #15 — `proxy.test.ts` runs a server-side module under the repo-global jsdom environment

**Severity:** Informational
**Location:** `proxy.test.ts:1-3`; `vitest.config.ts:8`
**Precedent:** `vitest.config.ts:8` sets `environment: 'jsdom'` globally, and every one of the 25 pre-existing test files targets browser or pure-logic code, so no precedent for a per-file `// @vitest-environment node` pragma exists in this repo.
**Evidence** (verbatim, `vitest.config.ts:6-10`):
```
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./vitest.setup.ts'],
  },
```
`proxy.test.ts` carries no environment pragma.
**Impact:** `Buffer` and `crypto.randomUUID` resolve because vitest's jsdom still runs on Node — so the suite cannot distinguish "available in the deployed runtime" from "available in the harness." That is precisely the belief `proxy.ts:35-36`'s (now-corrected) comment asserts. Confirmed green either way: the 13 tests pass under the current config.
**Recommendation:** Add `// @vitest-environment node` to `proxy.test.ts` so the test environment matches the deployment runtime the comment names.
**Legibility-target:** for-author
**Disposition:** Open (prior api #14 / rubric G10).

---

## What Looks Good

- **No breaking change anywhere in the range.** `downloadGraphAsPng(viewportElement, filename?)` and `graphToPngBlob(viewportElement): Promise<Blob>` keep identical signatures and return types across the `fetch` → `dataUrlToBlob` swap; `GraphPanel.tsx:102-104` and `exportAll.ts:64-65` need no edit. Verified by reading both call sites, not inferred.
- **The `Content-Security-Policy` request/response symmetry is asserted, not assumed.** `proxy.test.ts:78-93` pins request policy === response policy — the exact contract Next depends on — and the merged fact-check confirms it genuinely fails against the prior wiring. This is the strongest thing in the diff.
- **`dataUrlToBlob` matches the module's own transform-naming form.** `<source>To<Target>` mirrors `graphToPngBlob` one screen below it. Name right, module wrong (#2).
- **The `x-nonce` overwrite is `set`, not `append`** (`proxy.ts:50`) — the right primitive for a header a client can supply, with a test that pins the choice (`proxy.test.ts:95-106`). Correct even though the contract has no reader (#1).
- **The layout comment now states the negative contract explicitly** — *"so nothing here reads it directly"* (`app/layout.tsx:22-23`) — which is exactly the kind of statement that stops a future reader from hunting for a nonce consumer that doesn't exist.
- **`buildCsp` pins the full directive set by name.** `proxy.test.ts:34-45` asserts the sorted 9-key list, so silently dropping or adding a directive fails the suite. Very few CSP implementations are tested this precisely.
- **2544a19 fixes exactly two comments and nothing else.** A comment-only commit that closes two prior findings without touching a line of code is the correct shape for a final legibility pass, and it leaves the fact-check foundation from 99e1229 intact.
- **Test conventions followed without exception.** Explicit `vitest` imports (13/13 precedent), sibling-relative imports (CONTRIBUTING.md:103-109), colocated test files. The one novelty — a test file at repo root — is forced by `proxy.ts`'s framework-mandated location and is picked up by the default vitest `include`; confirmed by running it.

---

## Summary Table

| # | Finding | Severity | Location | Precedent | Status |
|---|---|---|---|---|---|
| 1 | `x-nonce` published + test-locked with zero readers | **Inconsistent** | `proxy.ts:48-50`; `proxy.test.ts:95-115` | None in repo (`SSE_HEADERS` is the only header contract) | Open (3rd pass) |
| 2 | `dataUrlToBlob` published from the code-split module | **Inconsistent** | `exportGraph.ts:16-44` | `export.ts:1-4` owns generic primitives | Open |
| 4 | Matcher coverage contradicts its own comment (3 ways) | **Inconsistent** | `proxy.ts:59-72` | None in repo; vs own comment | Open |
| 5 | `"Not a data: URL"` omits the value siblings include | Minor | `exportGraph.ts:24-27` | `fileExtraction.ts:85` | Open |
| 6 | Both public exports of `exportGraph` untested | Minor | `exportGraph.test.ts` | `fileExtraction.test.ts`, `streamLlm.test.ts` | Open |
| 7 | Decision record + 4 doc surfaces unchanged | Minor | `CLAUDE.md:34,91`; `CONTRIBUTING.md:95`; `docs/decisions/` | 8 existing records incl. one for the test framework | Open |
| 9 | `connect-src` rationale names phantom OpenAlex | Minor | `proxy.ts:16-17` | None; internal accuracy | Open |
| 10 | Policy exported from framework entry file; unvalidated nonce param | Minor | `proxy.ts:19` | `buildUserMessage` (verb ✅); casing split (✅) | Open |
| 11 | `dataUrlToBlob` diverges from the `fetch` path it replaces | Minor | `exportGraph.ts:23-44` | The replaced `fetch(dataUrl)` | Open |
| 12 | Only synchronous request handler in the repo | Informational | `proxy.ts:34` | 17/17 `app/api` handlers are `async` | Open |
| 13 | Falsifier pinned to private Next transport, no version | Informational | `proxy.test.ts:5-22` | None; `streamLlm.test.ts` mocks public boundary | Open |
| 14 | GIF fixture for a PNG media-type contract | Informational | `exportGraph.test.ts:8-19` | `fileExtraction.test.ts` | Open |
| 15 | Server module tested under global jsdom env | Informational | `proxy.test.ts:1-3`; `vitest.config.ts:8` | Global config; no pragma precedent | Open |
| 3 | Contradictory `style-src` rationales | Informational | `proxy.ts:11-16` | — | **Closed by 2544a19** |
| 8 | "Edge runtime" claim | Informational | `proxy.ts:35-36` | — | **Closed by 2544a19** |

**Counts:** Breaking **0** · Inconsistent **3** · Minor **6** · Informational **4** open, **2** closed this pass.

---

## Overall Assessment

**Nothing Breaking exists in `d86d2dc..2544a19`.** I checked this directly rather than by inference: every export whose implementation changed (`downloadGraphAsPng`, `graphToPngBlob`) retains its exact signature and return type; every new export is additive; the only app-wide contract change (`force-dynamic`) has no call sites and no conflicting sibling declaration. Both consumers of the changed module were read and need no edit. The 13 new tests pass.

Honest state of the change: **the security control itself is now correct and well-pinned; what remains open is uniformly about legibility and surface placement, not correctness.** Two rounds of fixes closed the substantive interface defects — the nonce reaches the document and the symmetry is asserted; `connect-src` was held tight rather than widened for an export helper; the policy is testable and its directive set is pinned by name. 2544a19 closes the last two documentation contradictions, and the merged fact-check now reports 0 Incorrect claims. The comment surface, which was the weakest part of this change through iteration 2, is the part that improved most.

The three remaining Inconsistent findings share a single root cause and it is worth naming plainly: **this change places things where they were cheapest to place, not where the repo says they go.** `dataUrlToBlob` went into the module the repo documents as the thing to code-split away, when `export.ts` exists and its docblock describes exactly this helper. The policy went into the framework entry file rather than a security module. `x-nonce` was written where it was convenient and then test-locked without ever acquiring a reader. Each is individually small; together they mean that a contributor who learns this codebase's conventions from `CLAUDE.md` and `CONTRIBUTING.md` will not find the CSP control where those documents imply it lives — and #7 records that neither document was updated to say otherwise. That is the finding I would act on first, because it is the one that compounds: every subsequent CSP change inherits the wrong import direction.

`#1` (`x-nonce`) is now on its third consecutive pass without resolution, and each iteration has raised the cost of the delete branch rather than picking one. It is not an author-judgment question anymore; someone has to choose. `#4` (matcher) is the only open finding with a live consequence — a future `/api…`-prefixed route ships with no CSP, silently, and no test would catch it.

Recommended sequencing if further iterations are authorized: `#4` (live consequence, ~5 lines + 1 test) → `#1` (owner decision, both branches are small) → `#2` + `#10` (one move each, resolves the import-direction root cause) → `#7` (decision record, which is also where `#9`'s corrected integration inventory belongs). `#6` closes `#14` for free. Everything else is comment-level.

---

## Goal-Alignment Note

- **Answered:** Whether anything in `d86d2dc..2544a19` breaks a consumer contract (**no**); how every new public name compares to its nearest repo precedent (Name-Pattern Audit, 8 names, each with a `Precedent:` or `No existing precedent in …` line); which consumer contracts the change publishes and whether they have readers (`x-nonce`: none; request-side CSP: Next, asserted by test); where request/response and doc/code asymmetries remain; error-message consistency against sibling utils; nullability and signature stability across the `fetch` → `dataUrlToBlob` swap; and the disposition of all 14 prior-pass api findings (2 closed, 12 open, 0 regressed).
- **Out of scope:** Whether the CSP directive set is *sufficient* as a security control (missing `form-action`, no `report-to`, enforce-only rollout, cache/`Vary` pairing) — security-reviewer's domain, and the prior rubric already carries these as A2/G3/G4. The runtime cost of `force-dynamic` and of the synchronous base64 loop — performance-reviewer's domain (prior F1/F3); I confirmed only that neither changes a signature. Module-boundary and dependency-direction reasoning behind #2 and #10 — architecture's domain (prior C3/C4); I reached the same two places from the repo's documented module contracts instead. Whether the KaTeX/reactflow inline-style dependents are individually real — merged fact-check graded this range 0 Incorrect and I took that as foundation without re-verifying.
- **Escalate:** **#1 (`x-nonce`)** — third consecutive pass, and iteration 2 chose a third path (add tests) over the stated binary, which raised the cost of the delete branch without closing it. Not resolvable by author judgment; the loop owner must pick delete-the-write or land-a-consumer. **#7 (docs/decision record)** — `CLAUDE.md:91` mandates a decision record for a significant architectural approach, and an app-wide CSP with an app-wide rendering-mode change is squarely that; four passes of review findings now exist with no durable artifact to carry them, so if this arm terminates here the reasoning lives only in review outputs. Both are for-orchestrator-synthesis, not for-author.
