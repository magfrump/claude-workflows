# API Consistency Review

Commit: 99e1229
Range: `d86d2dc..HEAD` (`git diff d86d2dc..HEAD`)
Worktree: /workspace/runs/review-arms/e3-loops/wt-validate-arm2 (detached at 99e1229)
Reviewer skill: api-consistency-reviewer
Legibility-target: intermediate reviewer familiar with Next.js and TypeScript, not with this repo's export conventions.

## Scope

Consumer-binding surfaces touched by the diff:

- **Exported library functions** — `dataUrlToBlob` (new, `app/lib/utils/exportGraph.ts`); `buildCsp` (new, `proxy.ts`); `proxy` (new, `proxy.ts`).
- **Config schema** — `export const config` in `proxy.ts` (Next.js proxy matcher).
- **Internal HTTP header contract** — `x-nonce` request header set in `proxy.ts`.
- **Preserved signatures** — `downloadGraphAsPng`, `graphToPngBlob` (bodies rewritten, signatures unchanged).

No HTTP/REST endpoints, gRPC, GraphQL, SDK methods, CLI commands, or event payloads are in this diff.

## Breaking-change determination

**Zero Breaking findings.** Explicit checks performed:

- `downloadGraphAsPng(viewportElement, filename = "proof-graph.png")` and `graphToPngBlob(...)` retain identical signatures and return types across the `fetch(dataUrl)` → `dataUrlToBlob(dataUrl)` swap. Return of `graphToPngBlob` remains `Promise<Blob>`; `dataUrlToBlob` returns a `Blob` synchronously and the `return dataUrlToBlob(dataUrl)` inside an `async` function keeps the `Promise<Blob>` contract. No consumer sees a changed shape.
  - Evidence (exportGraph.ts): `-  const res = await fetch(dataUrl);` / `-  return res.blob();` → `+  return dataUrlToBlob(dataUrl);`
- All three new exports (`dataUrlToBlob`, `buildCsp`, `proxy`) and `config` are additions — no existing public name is renamed, removed, or repurposed.
- `proxy.ts` is a new file; the prior `middleware.ts` is gone from the tree (`ls middleware.*` → no matches), consistent with the Next.js 16 Middleware→Proxy rename documented in the file header. This is a framework-driven filename change, not a consumer-facing break — the framework binds the file by name/location, not application code.

## Findings

### F1 — `x-nonce` forwarded request header has zero readers (Inconsistent / amber)

`proxy.ts` establishes a request-header contract:

```
requestHeaders.set("x-nonce", nonce);
```

but no server component, route handler, or layout reads it. Grep across `app/` for `get("x-nonce"` / `x-nonce` returns only the two comment lines in `app/layout.tsx` (which explicitly say "nothing here reads it directly") and the proxy write itself. The nonce reaches Next.js through the forwarded `Content-Security-Policy` request header, which Next parses to stamp its bootstrap `<script>` tags; the separate `x-nonce` header is a parallel channel that is written and never consumed.

- **Severity: Inconsistent (amber), not Breaking.** A written-but-unread header breaks no consumer — there is no reader to break. It is a half-established contract: either intended as a public affordance for future server components to read the active nonce, or dead output. Consistency cost is that the next author cannot tell which, and the test suite (`proxy.test.ts` "forwards x-nonce matching the nonce in the policy", "overwrites a client-supplied x-nonce") locks in behavior that nothing depends on, giving the contract false permanence.
- **Evidence verbatim (proxy.ts):**
  `  // Overwrite (not append) so a client-supplied x-nonce cannot be smuggled`
  `  // through to a server component.`
  `  requestHeaders.set("x-nonce", nonce);`
- **Evidence verbatim (layout.tsx):** `// Content-Security-Policy header (set in proxy.ts) and stamps it onto the` / `// bootstrap <script> tags it emits, so nothing here reads it directly.`
- **Name-Pattern note:** `x-nonce` is a conventional lowercase `x-`-prefixed custom header — idiomatic, no naming issue. The finding is contract-completeness, not naming.
- **Suggested resolution (non-blocking):** add a one-line comment at the `set("x-nonce", ...)` site stating it is a deliberate forward-compat affordance with no current reader, OR drop it and the two dependent tests. The overwrite-not-append security reasoning is sound and worth keeping in whichever form survives. This is a known amber for the tier-policy validation; it does not gate.

### F2 — new exported-function naming is consistent with utils conventions (Consistent / green)

Name-Pattern Audit of every new public name against nearest existing neighbors:

- **`dataUrlToBlob`** (exportGraph.ts). Convention in `app/lib/utils/` is descriptive camelCase, verb- or transform-led: `triggerDownload`, `sanitizeFilename`, `downloadSemiformalAsMarkdown`, `mergeStreamingPreview`, `stripCodeFences`, `topologicalSort`. `dataUrlToBlob` follows the platform-idiomatic `sourceToTarget` transform shape (cf. DOM `canvas.toBlob`, `URL.createObjectURL`) and reads as a pure converter, matching its pure-function implementation.
  - **Precedent:** camelCase descriptive util naming is pervasive across `app/lib/utils/` (20+ exports); `X-to-Blob` transform naming is idiomatic to the web platform the file already uses (`new Blob`, `atob`, `Uint8Array`). Precedent present → no tier penalty.
- **`buildCsp`** (proxy.ts). verb+Noun camelCase; `Csp` acronym cased as a word. Neighbors: `parseLatexPropositions`, `gatherDependencyContext`, `migrateV1Workspace` (note `V1` — the codebase already Pascal-cases short tokens inside camelCase names, so `Csp` over `CSP` is in-house style, not a deviation).
  - **Precedent:** present (verbNoun camelCase; mixed-case acronym token precedent via `migrateV1Workspace`). No tier penalty.
- **`proxy`** and **`config`** (proxy.ts). Framework-mandated export names — Next.js binds the proxy entry by these exact identifiers.
  - **Precedent:** framework contract, not a codebase-authored name. No penalty; renaming would break the framework binding.

All new names carry precedent; none incur the −1 no-precedent tier reduction.

### F3 — `buildCsp` / `proxy` split is a clean testability seam (Consistent / green)

`buildCsp(nonce)` is factored out of `proxy` purely so the directive set can be asserted without constructing a `NextRequest`. This matches the repo's existing habit of exporting small pure helpers alongside their orchestrators (e.g., `sanitizeFilename` beside the `download*` family in `export.ts`, `dataUrlToBlob` beside `downloadGraphAsPng` in this same diff). The export is honest — `buildCsp` has no side effects and its consumers are `proxy` and the test file. No asymmetry: input is a single `nonce: string`, output a single policy string.

- **Evidence verbatim (proxy.test.ts):** `import { buildCsp, proxy } from "./proxy";`

### Error consistency

`dataUrlToBlob` throws `new Error("Not a data: URL")` on malformed input, matching the plain-`Error`-with-message convention used elsewhere in utils (no custom error classes exist in this codebase). Consistent. Note it is a throwing pure function while its former inline form (`fetch` + `res.blob()`) would have rejected a Promise — but since both preserved callers (`downloadGraphAsPng`, `graphToPngBlob`) are `async`, a synchronous throw surfaces to callers identically as a rejected Promise. No error-surface asymmetry.

### Nullability

- `getGraphViewportElement(): HTMLElement | null` unchanged.
- `dataUrlToBlob` returns non-null `Blob` or throws — no nullable return, no ambiguous empty-vs-null case.
- `forwardedRequestHeader` (test helper) returns `string | null`, appropriately modeling absent headers; test-only, not a public surface.

No nullability inconsistencies.

## What Looks Good

- Signature preservation across the `fetch`→`dataUrlToBlob` swap is exact; the refactor is invisible to every caller. This is the clean way to swap an implementation under a stable contract.
- Every new public name carries in-house or framework precedent; the Name-Pattern Audit found no coinage that fights existing conventions.
- `buildCsp` is a well-chosen pure seam — it makes the CSP directive set unit-assertable (`proxy.test.ts` "emits exactly the intended directive set") without a request object, and the export is side-effect-free and honest.
- The `x-nonce` overwrite-not-append choice is the security-correct default and is documented at the call site.
- Deliberate CSP carve-outs (`style-src 'unsafe-inline'`, `connect-src 'self'`) are documented with rationale in the file header, so a future reader will not "tighten" them and break Tailwind/reactflow/KaTeX.

## Summary Table

| ID | Finding | Surface | Severity | Precedent |
|----|---------|---------|----------|-----------|
| F1 | `x-nonce` request header written with zero readers | HTTP header contract | Inconsistent (amber) | Header naming has precedent; contract completeness is the issue |
| F2 | New export names (`dataUrlToBlob`, `buildCsp`, `proxy`, `config`) | Exported functions / config | Consistent (green) | Present (codebase + framework) |
| F3 | `buildCsp`/`proxy` testability split | Exported functions | Consistent (green) | Present |
| — | `downloadGraphAsPng` / `graphToPngBlob` signatures preserved | Exported functions | Consistent (green) | N/A (unchanged) |
| — | Error + nullability surfaces | Exported functions | Consistent (green) | Present |

## Overall Assessment

**0 Breaking. 1 Inconsistent (amber). 0 naming penalties.**

The diff introduces three new exports and one config object, all consumer-safe: no rename, no removal, no signature change, no return-shape change. The preserved `exportGraph` signatures make the `dataUrlToBlob` swap fully backward-compatible. The single amber (F1) is the pre-identified `x-nonce` zero-reader contract — a completeness/legibility concern, not a break, and explicitly non-gating for the tier-policy validation. Under the api-consistency lens, this change is clean.

## Goal-Alignment Note

Task goal: validate decision 031 tier policy T by confirming **0 red** at arm 2 pass 2 (99e1229) from the API-consistency critic. This review finds **0 Breaking (0 red)** on the API-consistency surface. The one amber (F1, `x-nonce` zero readers) is the known, expected Inconsistent flag called out in the task brief — it maps to amber, not red, and therefore does not contradict the 0-red target. Result supports tier policy T at arm 2 pass 2 from this critic's stage. Draw is fresh: this review used only `git diff d86d2dc..HEAD` at 99e1229 and its ancestors; no prior artifacts or sibling worktrees were consulted.
