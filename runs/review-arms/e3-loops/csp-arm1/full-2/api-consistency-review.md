# API Consistency Review

**Repository:** /workspace/runs/review-arms/e3-loops/wt-csp-arm1 (meta-formalism-copilot)
**Branch:** e3/csp-arm1
**Commit:** f25d968
**Scope:** `git diff d86d2dc..HEAD` — `app/layout.tsx`, `app/lib/security/csp.ts` (new), `app/lib/security/csp.test.ts` (new), `app/lib/utils/exportGraph.ts`, `proxy.ts` (new), `proxy.test.ts` (new)
**Reviewed:** 2026-08-06
**Foundation:** merged code-fact-check (k=3) at `full-2/code-fact-check-report.md` — 0 Incorrect, 0 Stale, 3 Mostly accurate. Documented behavior is taken as established; this review does not re-verify it.
**Prior iteration:** `full-1/api-consistency-review.md` treated as advisory only; every precedent below was re-derived against this tree.

## Headline

**No Breaking findings.** Full-1's two Breaking findings are both resolved on this state:

- F1 (`connect-src 'self'` breaks `fetch(dataUrl)` in both graph-export consumers) — fixed by the `toPng`→`toBlob` migration; no `fetch(` remains on the export path (`app/lib/utils/exportGraph.ts:24-33`).
- F2 (nonce published on headers Next does not bind to) — fixed by setting the policy on the *forwarded request* headers (`proxy.ts:25-26`), which the merged fact-check verified against Next 16.2.4's `parseRequestHeaders`.

No exported signature in the diff is narrowed or removed. `downloadGraphAsPng(viewportElement, filename?)` and `graphToPngBlob(viewportElement): Promise<Blob>` keep their shapes; `RootLayout` becomes `async`, which Next permits for the layout it owns. The one *behavioral* contract change on an exported function (the two export helpers can now reject where they previously resolved) is absorbed by both in-repo consumers, which already wrap the calls in `try`/`catch` — so it is Minor, not Breaking. See Finding 5.

---

## Baseline conventions

Re-derived from this tree before any finding was written.

| Sibling | Path | Convention it establishes |
|---|---|---|
| `buildUserMessage`, `buildPropositionIndex`, `buildLine` | `app/lib/formalization/artifactRoute.ts:10`; `app/lib/utils/pdfPropositionParser.ts:354,189` | Pure derivation helpers are named `build<Noun>`. |
| `callLlm`, `streamLlm`, `sseEvent`, `fetchApi`, `downloadGraphAsPng` | `app/lib/llm/callLlm.ts:102`, `streamLlm.ts:21`, `app/lib/formalization/api.ts:6`, `app/lib/utils/exportGraph.ts:35` | Acronyms are cased as ordinary words (`Llm`, `Sse`, `Api`, `Png`), not SCREAMING. Sole outlier: `extractTextFromPDF` (`app/lib/utils/fileExtraction.ts:34`). |
| `analytics/`, `formalization/`, `llm/`, `stores/`, `types/`, `utils/` | `app/lib/*` | Domain sub-directories are lowercase single words. |
| `import { randomUUID } from "crypto"`, `import { createHash } from "crypto"` | `app/lib/llm/callLlm.ts:1`, `streamLlm.ts:1`, `cache.ts:1` | **Server-side** modules import Node crypto by name. |
| `crypto.randomUUID()` | `app/lib/stores/workspaceStore.ts:34`, `app/hooks/useWorkspaceSessions.ts:96,143`, `useFormalizationSessions.ts:71`, `app/components/panels/CausalGraphPanel.tsx:120` | **Client-side** modules use the global form. The server/client split is unbroken across all 9 call sites. |
| `const nextConfig: NextConfig = {...}` | `next.config.ts:3` | Root-level framework config objects carry their framework type annotation. |
| `headers: { "Content-Type": "application/json" }` | `app/api/verification/lean/route.ts` | The only HTTP header app code sets prior to this diff. No `x-*` header exists anywhere in the tree. |
| `throw new Error(\`Unsupported file type: .${ext ?? "(unknown)"}\`)` | `app/lib/utils/fileExtraction.ts:85`; also `:81`, `app/lib/llm/streamLlm.ts:271`, `app/lib/formalization/api.ts:16,50,99` | Thrown errors name the offending input or the specific failed step. |
| `getGraphViewportElement(): HTMLElement \| null` | `app/lib/utils/exportGraph.ts:10` | Absence in this module is signalled by a nullable return, and guarded by the caller (`exportAll.ts:63`, `GraphPanel.tsx:104`). |
| `console.warn("[export] ...")` / `console.error("[graph export]", err)` | `app/lib/utils/exportAll.ts:68`; `app/components/panels/GraphPanel.tsx:106` | Export failures are best-effort and swallowed at the consumer with a bracket-tagged log. |
| Colocated `*.test.ts` beside the module | 23 of 25 pre-existing test files | Tests sit next to the unit. Only `app/lib/stores/__tests__/` diverges. |
| `import ... from "@/app/lib/types/decomposition"` + `from "./export"` | `app/lib/utils/exportAll.ts:7-10` | `@/`-alias for cross-directory imports, relative for same-directory. |

---

## Name-Pattern Audit

Every new public (and module-private, where it shapes the module's vocabulary) name in the diff, against its nearest existing neighbor.

| New name | Kind | Nearest neighbors in this tree | Verdict |
|---|---|---|---|
| `buildCsp` | Exported fn (`app/lib/security/csp.ts:41`) | `buildUserMessage` (`artifactRoute.ts:10`), `buildPropositionIndex` (`pdfPropositionParser.ts:354`), `buildLine` (`:189`) | **Consistent.** `Precedent: build<Noun> for a pure derivation, 3 of 3 existing hits.` |
| `Csp` (acronym casing) | Identifier casing | `callLlm`, `streamLlm`, `sseEvent`, `fetchApi`, `downloadGraphAsPng` | **Consistent.** `Precedent: acronyms cased as words, 5+ hits; lone outlier extractTextFromPDF (fileExtraction.ts:34).` |
| `app/lib/security/` | Directory | `analytics/`, `formalization/`, `llm/`, `stores/`, `types/`, `utils/` | **Consistent.** `Precedent: lowercase single-word domain dirs under app/lib, 6 of 6.` |
| `csp.ts` (filename) | Module | `cache.ts`, `costs.ts`, `models.ts`, `export.ts` | **Consistent.** `Precedent: lowercase noun matching the exported concept.` |
| `csp.test.ts` (placement) | Test file | 23 colocated `*.test.ts`; `app/lib/stores/__tests__/` is the outlier | **Consistent.** `Precedent: colocation is the dominant convention (23/25).` |
| `nodeEnv` (param) | Parameter | `process.env.NODE_ENV` reads elsewhere are module-scope consts (`app/api/verification/lean/route.ts:4`) | **Consistent enough.** Naming matches the env var it mirrors. See Finding 8 for the docstring tension, not the name. |
| `devEvalDirective` | Local const (`csp.ts:45`) | `EXPORT_BG` (`exportGraph.ts:14`), `REQUEST_TIMEOUT_MS` (`lean/route.ts:5`) | **Consistent.** `Precedent: locals named after what the value is.` Improves on the pre-fix `devOnly`, which named *when* rather than *what*. |
| `renderGraphToBlob` | Module-private fn (`exportGraph.ts:24`) | `graphToPngBlob` (`:44`), `downloadGraphAsPng` (`:35`), `getGraphViewportElement` (`:10`), `triggerDownload` (`export.ts:8`) | **Minor drift.** `Precedent: this module uses <subject>To<Format>Blob and download<Subject>As<Format>; render* appears nowhere in app/lib/utils.` See Finding 4. |
| `proxy` (exported fn) | Framework entry point (`proxy.ts:11`) | none; nearest is `export default nextConfig` (`next.config.ts:3`) | **Consistent.** `No existing precedent in this repo — the name is mandated by Next 16, not chosen.` |
| `proxy.ts` (root filename) | Root module | `next.config.ts`, `vitest.config.ts`, `postcss.config.mjs`, `eslint.config.mjs` | **Consistent.** `Precedent: flat root layout for framework-mandated files.` |
| `proxy.test.ts` (root placement) | Test file | every other test lives under `app/` | **Consistent.** `Precedent: colocation; the module it tests is root-mandated, so the test follows it.` Picked up by vitest's default `include` (`vitest.config.ts` sets no `include`). |
| `config` (exported const) | Framework config object (`proxy.ts:40`) | `const nextConfig: NextConfig` (`next.config.ts:3`) | **Divergent on typing, not naming.** `Precedent: next.config.ts annotates its config type; ProxyConfig is exported for exactly this (node_modules/next/dist/server/web/types.d.ts:13, re-exported at next/server.d.ts:14).` See Finding 3. |
| `x-nonce` | New request-header contract (`proxy.ts:31`) | none — the only header app code sets is `Content-Type` (`app/api/verification/lean/route.ts`) | **Divergent.** `No existing precedent in this repo for any x-* header.` See Finding 2. |
| `Content-Security-Policy` | New request + response header (`proxy.ts:26,36`) | none | `No existing precedent in this repo — the name is fixed by the CSP spec.` Naming is not at issue; *coverage* is (Finding 1). |
| `RootLayout` (now `async`) | Component signature (`app/layout.tsx:22`) | `app/page.tsx` and all components are sync | **Framework-permitted signature change.** See Finding 10. |
| `parse` (test helper) | Test-local fn (`csp.test.ts:5`) | `collectEvents` (`streamLlm.test.ts:26`) | **Minor drift, test-local.** Siblings name the subject (`collectEvents`); bare `parse` does not. Not worth a finding — zero blast radius. |
| `forwardedRequestHeader`, `run` (test helpers) | Test-local fns (`proxy.test.ts:14,22`) | `collectEvents` (`streamLlm.test.ts:26`) | **`forwardedRequestHeader` consistent; `run` drifts** — bare `run` says nothing about its subject in a file that will grow. Test-local, no finding. |

---

## Findings

### Finding 1 — `config.matcher`'s `missing:` clause makes CSP coverage caller-controllable

- **Severity:** Inconsistent
- **Location:** `proxy.ts:40-53`
- **Confidence:** High (mechanism) / Medium (whether it matters today)
- **Precedent:** `No existing precedent in this repo — proxy.ts is the first middleware/proxy config in the tree.` The contract it breaks is its own stated one, not a sibling's.

**Evidence:**

```ts
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

The first three exclusions are properties of the *path* — the server decides them. The `missing:` clause is a property of the *request headers* — the caller decides it. So the header contract this diff introduces is not "every HTML document response carries a CSP"; it is "every HTML document response carries a CSP unless the requester asked for it not to." A plain `curl -H 'purpose: prefetch' http://host/` receives the full HTML document with no `Content-Security-Policy` header and no nonce, because the proxy never ran. The stated rationale ("would otherwise burn a nonce on a request that may never paint") describes a cost that is real but tiny: minting a nonce is one `randomUUID` plus one base64 encode, and a prefetched document that *does* later paint is exactly the case where you want the header present.

Every other coverage rule in this matcher is server-determined and therefore an invariant. This one is an invariant only for well-behaved clients, which is not what an invariant is. It is also the kind of exception that silently generalizes: the next contributor who adds a header-based exclusion will reasonably read this line as license.

**Suggested fix:** drop the `missing:` block and let prefetches take the header. If prefetch cost is genuinely a concern, exclude prefetches by path (`_next/data`) rather than by client-supplied header, and assert the residual coverage in `proxy.test.ts` with a request carrying `purpose: prefetch`.

**Legibility-target:** an operator reading `proxy.ts` to answer "which of our responses are covered by the CSP?" — the current file answers "all HTML navigations," and that answer is wrong for any caller that says otherwise.

---

### Finding 2 — `x-nonce` is a producer-only wire contract with no consumer and no `x-*` precedent

- **Severity:** Minor *(would be Inconsistent; −1 tier applied for absence of precedent)*
- **Location:** `proxy.ts:27-31`
- **Confidence:** High
- **Precedent:** `No existing precedent in this repo for custom x-* headers — the only header set by application code before this diff is Content-Type (app/api/verification/lean/route.ts).` The merged fact-check (Cluster 19) independently confirms no reader exists anywhere in the tree.

**Evidence:**

```ts
  // x-nonce is the conventional seam for server components that render their
  // own <Script> tags. Nothing reads it today (Next handles its own bootstrap
  // scripts via the header above); `.set` rather than `.append` so a
  // client-supplied value is clobbered rather than joined into a comma-list.
  requestHeaders.set("x-nonce", nonce);
```

and, from the layout that would be its natural consumer:

```tsx
  // Content-Security-Policy header, which proxy.ts sets on the forwarded
  // request headers — not out of the response header. We therefore don't need
  // to read x-nonce here ourselves.
```

The comment is now honest — this is a real improvement over an earlier state that implied a consumer. But an honest description of an unconsumed contract is still an unconsumed contract. Its cost is not runtime: it is that `x-nonce` now appears in the forwarded request headers of every page request, will show up in any header logging or tracing added later, and reads to a future contributor as a supported input. It also establishes the repo's first `x-*` header shape without a consumer to constrain it — so whoever *does* eventually read it inherits a format (base64 of a UUID string) chosen with no reader in mind.

Note also the internal tension: the same value is authoritative on `Content-Security-Policy` and advisory on `x-nonce`, with nothing keeping the two in sync beyond adjacency in one function. `proxy.test.ts:69-75` asserts they match, which is the right guard — but the guard exists because the duplication does.

**Suggested fix:** either delete the line until a `<Script nonce>` consumer lands (the CSP header alone is what Next binds to), or keep it and add a one-line `docs/` note declaring it a supported internal contract. Deleting is cheaper; `proxy.test.ts:62-75,77-85` would shrink by two tests that currently only test the seam against itself.

**Legibility-target:** a contributor adding a server component with an inline `<Script>`, who needs to know whether `x-nonce` is a supported input or an artifact.

---

### Finding 3 — `export const config` is untyped, against the sibling root-config precedent, so matcher typos fail silently

- **Severity:** Inconsistent
- **Location:** `proxy.ts:40`
- **Confidence:** High
- **Precedent:** `Precedent: next.config.ts:3 annotates its config object (const nextConfig: NextConfig = {...}); Next 16 exports ProxyConfig (and the deprecated alias MiddlewareConfig) from next/server for this exact purpose — node_modules/next/dist/server/web/types.d.ts:12-13, re-exported at node_modules/next/server.d.ts:12,14.`

**Evidence:**

```ts
export const config = {
  ...
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
```

versus the only sibling of this kind in the repo:

```ts
const nextConfig: NextConfig = {
  /* config options here */
};
```

The whole point of the sibling's annotation is that framework config objects are consumed by string key at build time, so a typo is not a type error — it is a silently ignored key. Here the object being typo-proofed gates a security header. `missng:` instead of `missing:`, or `sources:` instead of `source:`, produces a config that type-checks, lints clean, passes all five tests in `proxy.test.ts` (which call `proxy()` directly and never exercise the matcher), and changes which responses are protected. The repo already decided this class of object gets an annotation; this one is the instance where it matters most and is the one that lacks it.

**Suggested fix:**

```ts
import type { NextRequest, ProxyConfig } from "next/server";

export const config: ProxyConfig = { ... };
```

`ProxyConfig` is the Next 16 name; `MiddlewareConfig` is the deprecated alias, so prefer the former to match the file's own "Middleware → Proxy" framing at line 6.

**Legibility-target:** the type checker, and the reviewer of the *next* matcher edit — who currently has no automated signal that the edit landed in a real key.

---

### Finding 4 — the private `renderGraphToBlob` is an exact duplicate of its own public wrapper, and introduces a verb the module doesn't use

- **Severity:** Minor
- **Location:** `app/lib/utils/exportGraph.ts:24-33,44-48`
- **Confidence:** High
- **Precedent:** `Precedent: this module's vocabulary is get<Subject>Element (:10), download<Subject>As<Format> (:35), <subject>To<Format>Blob (:44); app/lib/utils/export.ts adds triggerDownload, downloadTextFile, sanitizeFilename. render* appears in no module under app/lib/utils.`

**Evidence:**

```ts
async function renderGraphToBlob(viewportElement: HTMLElement): Promise<Blob> {
```

```ts
/** Generate a PNG blob of the graph (for embedding in zip) */
export async function graphToPngBlob(
  viewportElement: HTMLElement,
): Promise<Blob> {
  return renderGraphToBlob(viewportElement);
}
```

`graphToPngBlob` and `renderGraphToBlob` have identical parameter lists, identical return types, and — after the refactor — identical behavior. The public one adds a name and nothing else. The module now carries two names for one operation, one of them (`render…`) a verb that exists nowhere else in `app/lib/utils`, and the drop of the `Png` token from the private name quietly makes the private helper look more format-agnostic than it is (Finding 6).

The extraction itself was correct and worth doing — before it, the render options (`pixelRatio: 2`, `backgroundColor: EXPORT_BG`) were duplicated across both exports and could drift. The fix is to keep the deduplication and lose the extra name.

**Suggested fix:** make `graphToPngBlob` the shared implementation and have `downloadGraphAsPng` call it:

```ts
/** Generate a PNG blob of the graph (for download or for embedding in a zip) */
export async function graphToPngBlob(
  viewportElement: HTMLElement,
): Promise<Blob> {
  const blob = await toBlob(viewportElement, { pixelRatio: 2, backgroundColor: EXPORT_BG, type: "image/png" });
  if (!blob) throw new Error(`Failed to render ${viewportElement.className || "graph"} to a PNG`);
  return blob;
}

export async function downloadGraphAsPng(viewportElement: HTMLElement, filename = "proof-graph.png") {
  triggerDownload(await graphToPngBlob(viewportElement), filename);
}
```

The existing JSDoc block at `:16-23` moves onto `graphToPngBlob` unchanged. Public surface shrinks by zero exports and the module loses one private name.

**Legibility-target:** a contributor adding a third export path (e.g. JPEG, or a clipboard copy) who must first work out which of the two identical functions is the one to extend.

---

### Finding 5 — new rejection path on two exported functions is undocumented, and the module now uses two failure idioms

- **Severity:** Minor
- **Location:** `app/lib/utils/exportGraph.ts:10,29-31,35-41,43-48`
- **Confidence:** High
- **Precedent:** `Precedent: throwing is established (fileExtraction.ts:81,85; streamLlm.ts:271; formalization/api.ts:16,50,99) and every one of those messages names the offending input or the specific step — e.g. "Unsupported file type: .${ext ?? "(unknown)"}" (fileExtraction.ts:85). Nullable-return for absence is also established, in this very module (exportGraph.ts:10).`

**Evidence:**

```ts
export function getGraphViewportElement(): HTMLElement | null {
```

```ts
  if (!blob) {
    throw new Error("Failed to render graph to an image");
  }
```

Three separate consistency points, all small, all in one module:

1. **Undocumented contract change.** Both exported functions can now reject where previously they resolved (`toPng` returning an empty data URL produced a 0-byte blob, not a rejection). Neither `downloadGraphAsPng` nor `graphToPngBlob` documents this — `graphToPngBlob`'s JSDoc still reads only `/** Generate a PNG blob of the graph (for embedding in zip) */`, and `downloadGraphAsPng` has no JSDoc at all. Both in-repo consumers already catch (`exportAll.ts:60-69` warns and keeps the zip; `GraphPanel.tsx:98-110` logs and clears the spinner), which is why this is Minor rather than Breaking — but the *documented* contract is the one a future consumer will code against.

2. **Two idioms for failure in one module.** Absence of the viewport is a `null` return the caller must guard; failure to render is a throw the caller must catch. Neither is wrong, but a consumer of this module has to handle both, and nothing in the module's shape signals that.

3. **Message shape drifts from precedent.** `"Failed to render graph to an image"` identifies neither the element nor the reason, where every sibling throw names something concrete. In the field this surfaces as a bare `[graph export] Error: Failed to render graph to an image` with no way to distinguish a tainted canvas from an over-large canvas from a detached node.

**Suggested fix:** add `@throws` to whichever function survives Finding 4's consolidation, and give the message a discriminator — the canvas dimensions and the element selector are both in hand at the throw site.

**Legibility-target:** the on-call reader of a `[graph export]` console line, and the next consumer of `graphToPngBlob` deciding whether a `try`/`catch` is required.

---

### Finding 6 — the PNG guarantee is now implicit in an undocumented library default

- **Severity:** Minor
- **Location:** `app/lib/utils/exportGraph.ts:24-33`
- **Confidence:** High
- **Precedent:** `Precedent: the format is asserted in three places in the surrounding code — the exported names downloadGraphAsPng / graphToPngBlob (:35,:44), the default filename "proof-graph.png" (:37), and the zip entry name zip.file("proof-graph.png", pngBlob) (exportAll.ts:65).`

**Evidence:**

```ts
  const blob = await toBlob(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
```

Under `toPng`, PNG was in the function name being called. Under `toBlob`, it is not, and the call passes no `type`. The output is still PNG — but only because `html-to-image` hardcodes it: `toBlob` calls `canvasToBlob(canvas)` with **no options at all** (`node_modules/html-to-image/lib/index.js:166`), and `canvasToBlob` then defaults to `'image/png'` (`node_modules/html-to-image/lib/util.js:183`). So the guarantee behind two exported names, one default filename, and one zip entry name rests on a library implementation detail that the library's own public `Options` type suggests is configurable and is in fact ignored on this path.

Nothing asserts the result. `csp.test.ts` covers the policy and `proxy.test.ts` covers the headers, but no test in the diff checks `blob.type`, so a `html-to-image` minor bump that starts honoring `options.type` — or changes the default — ships a `.png` file containing a JPEG with a green suite.

**Suggested fix:** pass `type: "image/png"` explicitly in the options object (harmless today, correct if the library starts forwarding options), and add one assertion at whichever level can see the blob. This is also the natural place to record *why* the format token disappeared from the call.

**Legibility-target:** the reviewer of the next `html-to-image` version bump, who currently has no local signal that the format contract depends on that package's internals.

---

### Finding 7 — server-only module uses the client `crypto` idiom

- **Severity:** Minor
- **Location:** `proxy.ts:12-15`
- **Confidence:** High
- **Precedent:** `Precedent: server-side modules import Node crypto by name — import { randomUUID } from "crypto" (app/lib/llm/callLlm.ts:1, app/lib/llm/streamLlm.ts:1) and import { createHash } from "crypto" (app/lib/llm/cache.ts:1). The bare global crypto.randomUUID() form appears only in client code: app/lib/stores/workspaceStore.ts:34, app/hooks/useWorkspaceSessions.ts:96,143, app/hooks/useFormalizationSessions.ts:71, app/components/panels/CausalGraphPanel.tsx:120. The split is unbroken across all 9 pre-existing call sites.`

**Evidence:**

```ts
  // Generate a fresh nonce per request. Next 16's Proxy always runs on the
  // Node.js runtime (it cannot be moved to Edge), so `crypto.randomUUID` and
  // `Buffer` are both available as Node core APIs.
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

The comment is now accurate (the merged fact-check, Cluster 18, verified the Node-runtime claim against Next's own error text), so this is purely a convention point — but a load-bearing one: a single line mixes the *client* idiom for randomness with a *Node-only* global (`Buffer`). The mixed idiom is what makes the runtime assumption invisible. Written as `import { randomUUID } from "crypto"`, the file states its runtime in its import list, where the linter and the reader both see it, instead of in a comment three lines above the call.

**Suggested fix:** `import { randomUUID } from "crypto";` at the top and `Buffer.from(randomUUID()).toString("base64")` at the call site. The comment then shrinks to the one fact it still needs to carry (why Node, not Edge).

**Legibility-target:** a contributor who later tries to move this file to the Edge runtime — the import list would stop them; a comment will not.

---

### Finding 8 — `buildCsp`'s docstring describes a contract its own default parameter undoes at the production call site

- **Severity:** Informational
- **Location:** `app/lib/security/csp.ts:34-44`; `proxy.ts:16`
- **Confidence:** High
- **Precedent:** `Precedent: env-dependent config elsewhere is a module-scope const with an inline fallback — const ... = process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100" (app/api/verification/lean/route.ts:4). A per-call default-parameter read has no sibling, but is strictly better than the module-scope form for a value read once per request.`

**Evidence:**

```
 * `nodeEnv` is a parameter rather than an ambient `process.env` read so the
 * production branch can be observed from a test process without mutating
 * global state.
```

```ts
export function buildCsp(
  nonce: string,
  nodeEnv: string | undefined = process.env.NODE_ENV,
): string {
```

against the sole production call site:

```ts
  const csp = buildCsp(nonce);
```

The mechanism is right and the testability goal is fully achieved (`csp.test.ts:43-59` exercises both branches plus a six-value fail-closed sweep without touching `process.env`). The docstring's framing is just slightly off: it is not "a parameter rather than an ambient read" — it is a parameter *whose default is* the ambient read, and in production the ambient read is what runs. A reader who takes the sentence literally will look for a caller that passes the environment in and not find one.

Also worth noting for the record: `nodeEnv: string | undefined` is deliberately wide, and the fail-closed test at `csp.test.ts:53-59` depends on that width to pass `"Development"`, `"dev"`, `"prod"`. Narrowing it to a union would break that test and remove the property it guards, so the wide type is correct here — flagging it only so a future "tighten the types" pass doesn't undo it.

**Suggested fix:** one-clause rewrite — "`nodeEnv` defaults to `process.env.NODE_ENV` but is injectable, so the production branch can be observed from a test process without mutating global state."

**Legibility-target:** a reader auditing where this security control gets its environment from.

---

### Finding 9 — matcher exclusions match by prefix, not by path segment

- **Severity:** Informational
- **Location:** `proxy.ts:46`
- **Confidence:** High
- **Precedent:** `No existing precedent in this repo — first matcher.` Route inventory re-derived for this review: `app/page.tsx` plus 16 routes, all under `app/api/**`.

**Evidence:**

```ts
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

The negative lookahead is unanchored at its right edge, so it excludes any path *beginning with* those strings, not those path segments. A future top-level route named `/apidocs`, `/api-status`, or `/apiary` would silently fall outside the proxy and ship without a CSP. Latent today — the only non-`/api` route is `/` — and this is the idiomatic Next matcher shape, which is exactly why it is worth a line of defense: the failure is silent, and the person who adds `/apidocs` will have no reason to look at `proxy.ts`.

**Suggested fix:** anchor the segment — `"/((?!api/|_next/static/|_next/image/|favicon\\.ico$).*)"` — or leave it and add the trap to the matcher comment so the next route author sees it.

**Legibility-target:** whoever adds the repo's second top-level route.

---

### Finding 10 — the dynamic-rendering contract is carried by a discarded `await headers()`, and `frame-ancestors 'none'` ships enforce-only

- **Severity:** Informational
- **Location:** `app/layout.tsx:22,41`; `app/lib/security/csp.ts:53`
- **Confidence:** High
- **Precedent:** `Precedent: no sibling layout exists; app/page.tsx:40 and every component in the tree are sync. No prior response-header contract exists for consumers to have depended on.`

**Evidence:**

```tsx
export default async function RootLayout({
```

```tsx
  await headers();
```

```ts
    "frame-ancestors 'none'",
```

Two contract observations, neither actionable today:

1. `await headers()` is a load-bearing call whose *value* is discarded — the effect is the dynamic-rendering opt-out. The 18-line comment above it (`app/layout.tsx:25-40`) is genuinely good and explains exactly this. But no type, lint rule, or test protects the line: a future "remove unused await" cleanup deletes it, the layout goes back to static, and the symptom is a stale nonce blocking scripts in production only. If there is a cheap guard available — `export const dynamic = "force-dynamic"` alongside it, which states the same intent declaratively — it would be worth having both.

2. `frame-ancestors 'none'` is a new response-level contract forbidding embedding of the app anywhere. Nothing in the tree embeds it (repo-wide grep for `iframe`/`embed` finds hits only in `csp.ts:53` and `csp.test.ts:27,32`), so there is no consumer to break — but the whole policy ships enforce-only, with no `Content-Security-Policy-Report-Only` stage and no `report-to`/`report-uri` directive. For a first CSP on an app with third-party rendering libraries (reactflow, KaTeX, pdfjs), a report-only stage is the conventional way to discover the violations you did not predict before they become blank panels. That is a rollout choice rather than an API defect, and the arm-1 lite-first path may well have made it deliberately.

**Legibility-target:** for (1), the author of a future lint-driven cleanup; for (2), whoever is on the other end of the first "the graph panel is blank in prod" report.

---

## What Looks Good

- **The `build<Noun>` extraction is the right shape and lands on the right precedent.** `buildCsp` (`csp.ts:41`) matches `buildUserMessage` / `buildPropositionIndex` / `buildLine` exactly, and pulling the pure policy string out of the wiring is what makes it testable at all — `csp.test.ts` asserts the full directive list, the nonce interpolation, the dev/prod delta, and the fail-closed comparison, none of which was reachable when the policy was inline in `proxy.ts`.
- **Acronym casing sides with the majority.** `Csp` follows `Llm`/`Sse`/`Api`/`Png` (5+ sites) rather than the lone `extractTextFromPDF` outlier.
- **`app/lib/security/` is a well-formed new sibling.** Lowercase single-word domain directory, matching all six existing ones, with the module named for the concept it exports. A security directory is a category the tree was missing and will plausibly grow.
- **Import-path idiom matches the established split.** Alias for cross-directory (`proxy.ts:3`, `@/app/lib/security/csp`), relative for same-directory (`csp.test.ts:2`, `./csp`) — the same split `exportAll.ts:7-10` uses.
- **Test placement follows colocation in both new files,** including `proxy.test.ts` at the root, where the module it tests is required to live. Vitest picks it up under the default `include` since `vitest.config.ts` sets none, and the `@vitest-environment node` pragma is the right narrow fix for the jsdom default rather than a config-wide change.
- **`.set` over `.append` on `x-nonce` is the correct choice and is pinned by a test** (`proxy.test.ts:77-85`, asserting an attacker-supplied value is clobbered rather than comma-joined). Whatever happens to Finding 2, this detail was right.
- **The fail-closed environment comparison is tested as a property, not an example.** `csp.test.ts:53-59` sweeps `[undefined, "", "Development", "dev", "test", "prod"]` rather than asserting one negative case, and `:61-66` pins the dev/prod delta to exactly `'unsafe-eval'` — so a future directive added to only one branch fails the suite.
- **Both export call sites now route through one render implementation.** Even with Finding 4's naming point, the deduplication is the substantive win: `pixelRatio` and `backgroundColor` can no longer drift between the download path and the zip path.
- **The `connect-src` regression guard is a genuinely well-designed test.** `csp.test.ts:67-72` asserts the *directive* and explains in-comment that the correct response to a future export failure is to fix the export path, not widen the directive. That is the rare test that encodes the reasoning rather than just the value.
- **No `worker-src` gap.** pdfjs's worker is loaded via `new URL("pdfjs-dist/build/pdf.worker.min.mjs", import.meta.url)` (`app/lib/utils/pdfPropositionParser.ts:443`, `app/lib/utils/fileExtraction.ts:26`), which bundles to a same-origin `_next/static` asset — covered by `default-src 'self'` through the `worker-src` → `child-src` → `default-src` fallback chain. The absent directive is correct, not an oversight.
- **`devEvalDirective` fixed the naming drift full-1 flagged** (`devOnly` named *when* the value applies; the new name says *what it is*, matching `EXPORT_BG` / `REQUEST_TIMEOUT_MS`).
- **The comments carry their reasoning, and the merged fact-check found them accurate.** `csp.ts:13-19` (why `style-src 'unsafe-inline'` is a carve-out with named dependents rather than laziness), `proxy.ts:18-24` (why the request header is load-bearing), `exportGraph.ts:16-23` (why not to reintroduce `fetch(dataUrl)`) — k=3 verification returned 0 Incorrect and 0 Stale across all of them.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | `config.matcher`'s `missing:` clause lets a caller opt out of the CSP via request headers | Inconsistent | `proxy.ts:40-53` | High / Medium |
| 3 | `export const config` untyped, unlike `const nextConfig: NextConfig`; `ProxyConfig` is exported for this | Inconsistent | `proxy.ts:40` | High |
| 2 | `x-nonce` is a producer-only header with no consumer and no `x-*` precedent | Minor | `proxy.ts:27-31` | High |
| 4 | Private `renderGraphToBlob` exactly duplicates public `graphToPngBlob`; `render*` verb unprecedented | Minor | `exportGraph.ts:24-33,44-48` | High |
| 5 | New rejection path undocumented; nullable-return and throw idioms mixed; message names nothing | Minor | `exportGraph.ts:10,29-31,43-48` | High |
| 6 | PNG guarantee now rests on an undocumented `html-to-image` default; nothing asserts `blob.type` | Minor | `exportGraph.ts:24-28` | High |
| 7 | Server-only module uses the client `crypto` global idiom alongside Node-only `Buffer` | Minor | `proxy.ts:12-15` | High |
| 8 | `buildCsp` docstring says "parameter rather than ambient read"; production passes one arg | Informational | `csp.ts:34-44`; `proxy.ts:16` | High |
| 9 | Matcher exclusions match by prefix, not path segment (`/apidocs` would lose the CSP) | Informational | `proxy.ts:46` | High |
| 10 | Dynamic-rendering contract carried by a discarded `await headers()`; enforce-only CSP rollout | Informational | `app/layout.tsx:22,41`; `csp.ts:53` | High |

**Breaking: none.**

---

## Overall Assessment

This is a consistent diff on the axes that decide whether an interface ages well, and the two Breaking findings from the previous full iteration are genuinely closed rather than papered over — the `toPng`→`toBlob` migration removes the `fetch(data:)` path outright, and the nonce now travels on the header Next actually reads. Every new *name* in the diff lands on an existing precedent or is framework-mandated; the new `app/lib/security/` directory is a well-formed sibling; and the extraction of `buildCsp` converted a security control from untestable to property-tested, which is the change that most improves this surface's future.

What remains is concentrated in two places. The first is `proxy.ts`'s **configuration surface** — the untyped `config` object (Finding 3) and the caller-controllable `missing:` clause (Finding 1). These are the two findings I would act on before merge, and they are related: both mean the *actual* coverage of the CSP is harder to determine than reading the file suggests, one because a typo can't be caught and one because the answer depends on the requester. Neither is expensive to fix — one import and one deletion.

The second is `exportGraph.ts`'s **post-refactor shape** (Findings 4, 5, 6). Individually these are small; together they say the same thing, which is that the migration preserved behavior but let the module's self-description drift: two names for one function, a format promise that moved from the call into a library default, and a new rejection path that no JSDoc mentions. The consolidation sketched in Finding 4 closes all three at once and shrinks the module.

The remaining Informational items are notes for future readers rather than defects. Two deserve a second look during rollout planning specifically: the enforce-only launch with no Report-Only stage (Finding 10), which for a first CSP over reactflow/KaTeX/pdfjs is where undiscovered violations become blank panels; and the unprotected `await headers()`, which is the kind of line a cleanup pass deletes without understanding.

Documentation accuracy is not re-litigated here — the merged k=3 fact-check found 0 Incorrect and 0 Stale, and its two comment-level Mostly-accurate items (the phantom OpenAlex reference in `csp.ts:20`, and "entirely within the DOM" at `exportGraph.ts:17`) are its to carry, not this review's.

---

## Goal-Alignment Note

- **Answered:** All briefed items. **Name-Pattern Audit** over every new public name — 17 rows covering `buildCsp` and the new `app/lib/security/` module/directory/test placement, `renderGraphToBlob`, and the `proxy`/`config`/matcher surface — each carrying `Precedent:` or `No existing precedent in ...`. **Consumer contracts** — `downloadGraphAsPng` and `graphToPngBlob` signatures re-checked against both call sites (`GraphPanel.tsx:102-104`, `exportAll.ts:10,64`) and confirmed unchanged in shape, with the behavioral rejection-path change traced to both consumers' existing `catch` blocks (Finding 5); the `app/lib/security/` directory precedent derived from all six existing `app/lib/*` siblings. **Error consistency** — Finding 5 (message shape against 6 sibling throw sites), Finding 1 (coverage contract). **Asymmetries** — Finding 4 (duplicate name pair), Finding 2 (write-only header), Finding 5 (null-return vs. throw within one module). **Nullability** — `toBlob`'s `Promise<Blob | null>` narrowing at `exportGraph.ts:29-31`, and `nodeEnv: string | undefined` at `csp.ts:43` (deliberately wide; flagged in Finding 8 so a future tightening pass doesn't break the fail-closed test). **Breaking status stated explicitly** in the Headline and the Summary Table: none.
- **Out of scope:** Exploitability of the `missing:` prefetch bypass and of nonce entropy (`Buffer.from(crypto.randomUUID())`) — security-reviewer's call; Finding 1 is framed as a coverage-contract inconsistency only. Whether `style-src 'unsafe-inline'` is acceptable — a policy judgement, not an interface one. Runtime browser verification of the CSP (unavailable in this sandbox, and flagged as such by the commit itself). Comment-accuracy items already recorded in the merged fact-check: the phantom OpenAlex reference (Cluster 6, `csp.ts:20`) and "staying entirely within the DOM" (Cluster 13, `exportGraph.ts:17`) — both real, both owned upstream, not re-raised as API findings. Test-internal naming drift (`parse`, `run`) noted in the audit table but deliberately not raised as findings.
- **Escalate:** Nothing at Breaking severity. If the loop-termination bar for this arm is "no Breaking findings," this pass meets it. The two Inconsistent findings (1 and 3) are the pre-merge set, and both are one-line fixes. One cross-review note for synthesis: full-1's Findings 1, 2 and 11 are resolved on this state and must not be carried forward; full-1's Findings 3, 4, 6, 7, 8, 9 and 10 survive here as this review's Findings 2, 1, 3, 5, 10, (worker-src — **withdrawn**, see What Looks Good) and 10 respectively. Full-1's Finding 9 (`blob:` withheld from workers by the `default-src` fallback) is **withdrawn on independent re-derivation**: pdfjs loads its worker from a bundled same-origin `_next/static` URL, not a `blob:` URL, so `default-src 'self'` covers it.
