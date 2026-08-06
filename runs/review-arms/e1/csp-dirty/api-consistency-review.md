# API Consistency Review — csp-dirty (d86d2dc..d90d6bb)

**Scope:** `git diff d86d2dc..d90d6bb` — `proxy.ts` (new, 64 lines) and `app/layout.tsx` (+8/-1). Commits in range: 9b4e453 (feat: strict CSP with per-request nonces), b25e939 (comment fix), d90d6bb (comment cleanup). New consumer-facing surface reviewed: the `proxy` function export, the `config` matcher export, the module-internal `buildCsp` helper, the `x-nonce` request-header contract, and the CSP response-header contract that every existing browser-side consumer now binds to.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3), `/workspace/runs/review-arms/e1/code-fact-check-report.md` — treated as foundation, not re-verified.

Commit: d90d6bb

### Baseline Conventions

Established from five sibling interfaces in the repo as of d90d6bb:

1. **Framework-convention files use the framework's exact export shape.** `app/api/**/route.ts` (17 files) export `GET`/`POST`/`DELETE` by Next's contract; `app/layout.tsx` default-exports `RootLayout` and named-exports `metadata`; `next.config.ts` default-exports a `NextConfig`. The repo never invents an alternative shape for a file the framework owns.
2. **Handler parameter naming is `request`, typed `NextRequest`.** 14 of 17 route handlers use `export async function POST(request: NextRequest)`; `app/api/predict/route.ts:4` uses `request: Request`. No `req` abbreviation anywhere in `app/api/`.
3. **Pure helpers live in `app/lib/**` as exported functions with a co-located `.test.ts`.** `app/lib/utils/export.ts`, `app/lib/utils/workspacePersistence.ts` (+ `workspacePersistence.test.ts`), `app/lib/utils/textSelection.ts` (+ test), `app/lib/formalization/artifactRoute.ts`. 24 `.test.ts`/`.test.tsx` files total; CLAUDE.md:89 states "Write tests alongside implementation."
4. **Verb-prefixed camelCase function names with capitalized-not-uppercased acronyms.** `buildUserMessage` (`app/lib/formalization/artifactRoute.ts:10`), `buildPropositionIndex` / `buildLine` (`app/lib/utils/pdfPropositionParser.ts:354,189`), `callLlm` (`app/lib/llm/callLlm.ts:102`), `downloadGraphAsPng` / `graphToPngBlob` (`app/lib/utils/exportGraph.ts:15,32`), `getPdfjs` (`app/lib/utils/fileExtraction.ts:24`). Acronyms are `Llm`/`Png`/`Pdf`, never `LLM`/`PNG`.
5. **Documentation contracts are load-bearing.** CLAUDE.md:91 requires a `docs/decisions/NNN-title.md` record "when choosing a new library or significant architectural approach" (8 such records exist); CLAUDE.md:30-45 keeps a per-file inventory of `app/`; `docs/ARCHITECTURE.md` carries a "Key Technical Decisions" section with a why-paragraph per structural choice.
6. **No custom HTTP header contract exists anywhere in the repo before this diff.** Grep for `x-*` header names and `headers.set` across `app/`, `verifier/`, and `next.config.ts` returns zero producers and zero consumers. `next.config.ts` has no `headers()` block; `verifier/server.ts` sets none.
7. **Browser-side consumers assume an unrestricted fetch/DOM environment.** `app/lib/utils/exportGraph.ts:24,37` `fetch()` a `data:` URL produced by `html-to-image`; `app/lib/utils/export.ts:8` uses `URL.createObjectURL`. Nothing in the repo declares a transport allowlist that these calls were written against.

### Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `proxy` (exported fn) | Framework-convention export | `POST` / `GET` route handlers; `RootLayout` default export | `app/api/edit/inline/route.ts:10`, `app/layout.tsx:22` | Consistent — Next 16 owns this name; repo always adopts framework names verbatim |
| `config` (exported const) | Framework-convention export | `metadata` in `app/layout.tsx:17`; `nextConfig` default export in `next.config.ts:3` | `app/layout.tsx:17`, `next.config.ts:3` | Consistent — required by Next's proxy contract; note this is the repo's first `export const config` |
| `request` (param) | Parameter name | `request: NextRequest` in 14 route handlers | `app/api/refine/context/route.ts:29` | Consistent |
| `buildCsp` (module fn) | Pure helper | `buildUserMessage`, `buildPropositionIndex`, `callLlm` | `app/lib/formalization/artifactRoute.ts:10`, `app/lib/utils/pdfPropositionParser.ts:354` | Name consistent (verb prefix, `Csp` acronym casing matches `Png`/`Llm`); placement and unexported/untested status inconsistent — see Finding 6 |
| `x-nonce` (request header) | Wire contract | none | *No existing precedent in `app/`, `verifier/`, `next.config.ts`* (searched for `x-*` header literals and `headers.set`) | Undecidable against repo precedent; matches Next's own documented example name, but the contract has no reader — see Findings 2 and 3 |
| `RootLayout` → `async` | Signature change | all other components are sync | `app/layout.tsx:22` | Consistent with React 19 / Next 16 async-server-component contract; no consumer binds to the return type |

### Findings

#### 1. `connect-src 'self'` breaks the existing `exportGraph` consumer contract

**Severity:** Breaking
**Location:** `proxy.ts:25` (`"connect-src 'self'"`), consumers at `app/lib/utils/exportGraph.ts:24` and `app/lib/utils/exportGraph.ts:37`
**Move:** Consumer-contract tracing (move 3)
**Confidence:** High — the fact-check confirms both call sites and that no `connect-src` allowance covers them.
**Evidence:**
```
"img-src 'self' data: blob:",
...
"connect-src 'self'",
```
and, in the same diff's rationale comment: `` `connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party. ``
**Legibility-target:** Someone adding a directive to `buildCsp` who reasons about third-party origins only and never enumerates the app's own browser-side `fetch()` call sites.
The rationale comment enumerates the third-party-origin case and concludes `'self'` is sufficient, but the repo's browser code also fetches non-origin *schemes*: `downloadGraphAsPng` and `graphToPngBlob` both call `fetch(dataUrl)` on a `data:` URL returned by `html-to-image`. `connect-src 'self'` does not cover `data:`, so both graph-export paths — and the zip export that depends on `graphToPngBlob` via `app/lib/utils/exportAll.ts` — fail at runtime under the new policy. The diff already recognises that this app traffics in `data:` and `blob:` URLs: `img-src 'self' data: blob:` on the line immediately above grants exactly those schemes for a different directive. That makes this a silent breaking change to an existing internal consumer, not a deliberate tightening: no test, changelog entry, or comment records that graph export was considered.
**Recommendation:** Add `data:` (and `blob:`, matching `img-src`) to `connect-src`, or refactor `exportGraph.ts` to convert the data URL without a `fetch` round-trip. Whichever is chosen, state the decision in the `buildCsp` doc comment next to the existing `connect-src` paragraph so the next editor sees that browser-side schemes, not just origins, are in scope.

#### 2. The nonce is published on a contract Next does not read, so the `script-src` directive binds to nothing

**Severity:** Breaking
**Location:** `proxy.ts:40-48` (`requestHeaders.set("x-nonce", nonce)` + `response.headers.set("Content-Security-Policy", ...)`), `proxy.ts:21` (`script-src 'self' 'nonce-…' 'strict-dynamic'`), `app/layout.tsx:27-31`
**Move:** Consumer-contract tracing (move 3) / asymmetry (move 7)
**Confidence:** High — rests on the merged fact-check finding that the layout's mechanism claim is wrong because the nonce would have to be read from the request's CSP header, which this proxy never sets.
**Evidence:**
```
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```
**Legibility-target:** A reviewer who accepts the layout comment's claim that "Next.js automatically tags its own bootstrap `<script>` elements with the nonce" and therefore never asks *from which header* Next obtains it.
Two contracts are in play and the diff satisfies neither end-to-end. The producer side sets `x-nonce` on the forwarded request and the CSP on the *response*; the framework consumer binds to the CSP header on the *request*. Because the request-side CSP header is never set, nothing tags Next's bootstrap scripts, and `'strict-dynamic'` makes the omission maximally consequential: with `'strict-dynamic'` present, the `'self'` source expression in `script-src` is ignored by conforming browsers, so an untagged first-party bootstrap script is blocked rather than falling back to origin-based allowance. This is the same class of defect the repo avoids everywhere else by adopting framework export shapes verbatim (baseline 1): here the file name and export names follow Next's contract exactly while the header plumbing quietly diverges from it.
**Recommendation:** Set the CSP on the forwarded request headers as well as the response (`requestHeaders.set("Content-Security-Policy", csp)`), computing the policy string once and passing it to both, so the producer and the framework consumer read the same contract. Verify with a rendered page that Next's bootstrap `<script>` tags carry a `nonce` attribute before treating the directive as enforced.

#### 3. `x-nonce` is a new wire contract with zero consumers

**Severity:** Inconsistent
**Location:** `proxy.ts:41` (`requestHeaders.set("x-nonce", nonce)`)
**Move:** Consumer-contract tracing (move 3)
**Confidence:** High — fact-check confirms the header is forwarded and never read, and that `app/` contains no `<Script>` tags.
**Precedent:** *No existing precedent in `app/`, `verifier/`, `next.config.ts`* — the repo defines no custom HTTP header, producer or consumer, before this diff.
**Evidence:**
```
  // Forward the nonce to server components via a request header so layouts
  // can read it via `headers()` and pass it to <Script> tags they render.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
```
**Legibility-target:** A future contributor who adds a `<Script>` tag and needs to know whether a nonce is available and under what name.
The comment describes a consumer that does not exist: no file in `app/` calls `headers().get("x-nonce")`, and there are no `<Script>` elements to nonce. `app/layout.tsx` — the one place the comment names — explicitly declines to read it ("so we don't need to read x-nonce here ourselves"), which means the two comments added by this diff describe opposite intents for the same header. An unconsumed contract is not free: it is the first custom header in the codebase, so it silently sets the naming precedent (`x-` prefix, lowercase-kebab) for everything that follows, and there is no test pinning it. The repo's own pattern for a helper with no current caller is not to ship it — every exported helper in `app/lib/utils/` has at least one call site.
**Recommendation:** Either wire a real consumer (see Finding 2 — reading the nonce in `layout.tsx` and passing it to script tags is one coherent design), or drop the `x-nonce` forwarding and the `NextResponse.next({ request })` wrapper entirely and keep the response header alone. If it stays, add a one-line note naming the intended reader, and reconcile it with the contradicting comment in `layout.tsx`.

#### 4. `layout.tsx`'s comment documents a mechanism the code does not implement

**Severity:** Inconsistent
**Location:** `app/layout.tsx:27-31`
**Move:** Doc drift on the changed surface (move 3)
**Confidence:** High — foundation finding from the merged fact-check.
**Evidence:**
```
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
  await headers();
```
**Legibility-target:** The next person to touch `layout.tsx`, who will read this comment as a statement of the contract and conclude that no nonce plumbing is needed.
The second sentence asserts a framework behaviour ("from the response's CSP header") that is not how the nonce reaches Next, and this is the *only* documentation of the whole nonce mechanism at the consuming end. The comment is also the sole justification for the bare `await headers()` call — a statement with no value binding, which will read as dead code to anyone who does not accept the surrounding claim. Two of the three commits in this range (b25e939, d90d6bb) are edits to this comment and `proxy.ts`'s, so the comment is being actively maintained as the spec; leaving it wrong is more costly than leaving it absent. The repo's convention is that comments carry mechanism-level truth — e.g. `app/lib/utils/exportGraph.ts:1-4` explains *why* the module is split out, and `app/lib/utils/export.ts:3` names the exact browser API used.
**Recommendation:** Rewrite the comment to state what actually happens once Finding 2 is resolved, naming the specific header Next reads. Keep the first sentence (the dynamic-rendering rationale for `await headers()`), which is independently correct and is the only thing justifying that line.

#### 5. A project-wide cross-cutting contract ships with no decision record and no inventory update

**Severity:** Minor
**Location:** `proxy.ts` (whole file); missing entry in `docs/decisions/`; `CLAUDE.md:30-45` directory inventory; `docs/ARCHITECTURE.md` "Key Technical Decisions" (line 239)
**Move:** Doc drift (move 3) / versioning impact (move 6)
**Confidence:** High — verified by listing `docs/decisions/` (8 records, none about CSP) and grepping the doc set for `csp|nonce|proxy`, which matches only `proxy.ts` and unrelated text.
**Evidence:** CLAUDE.md:91 — "When choosing a new library or significant architectural approach, create a short decision record in `docs/decisions/NNN-title.md` explaining what was chosen and why". CLAUDE.md:31 still describes the changed file as: "`layout.tsx` — Sets up fonts (EB Garamond serif + Geist Mono) and metadata".
**Legibility-target:** A contributor whose feature is blocked by the CSP and who searches the docs to learn whether the restriction is deliberate and who to ask.
This diff adds a policy that constrains every future browser-side feature — a new script source, a CDN font, an analytics beacon, an iframe embed all now require a `buildCsp` edit — which is precisely the "significant architectural approach" the repo's own rule targets; the eight existing records cover strictly smaller decisions (a test framework, a state library, a cost model). Two inventories are now stale in the same direction: `CLAUDE.md`'s directory layout is scoped "under `app/`" and so has no place for a root-level `proxy.ts`, and its `layout.tsx` line omits the newly added rendering-mode contract that makes the layout dynamic on every request. `docs/ARCHITECTURE.md` documents structural choices with a why-paragraph each and gains none for the first security-policy surface in the project.
**Recommendation:** Add `docs/decisions/008-content-security-policy.md` recording the `'strict-dynamic'` + nonce choice, the `style-src 'unsafe-inline'` carve-out (which is currently justified only inside a source comment), and the matcher exclusions. Update the `layout.tsx` line in CLAUDE.md and add a root-file note for `proxy.ts`.

#### 6. `buildCsp` diverges from the repo's pure-helper placement and testing convention

**Severity:** Minor
**Location:** `proxy.ts:17-30`
**Move:** Name-pattern audit (move 2) / asymmetry (move 7)
**Confidence:** High — the naming precedent and the co-located-test pattern were both enumerated directly from the tree.
**Precedent:** `build<Noun>` pure-helper naming used in `app/lib/formalization/artifactRoute.ts:10` (`buildUserMessage`, exported) and `app/lib/utils/pdfPropositionParser.ts:354` (`buildPropositionIndex`)
**Evidence:**
```
function buildCsp(nonce: string): string {
  const directives = [
```
**Legibility-target:** Someone tightening or relaxing a directive who wants to assert the resulting policy string without booting Next.
The *name* is fully consistent with baseline 4 — verb prefix, and `Csp` follows the repo's capitalized-acronym style (`Png` in `downloadGraphAsPng`, `Llm` in `callLlm`), not `CSP`. The divergence is structural: `buildCsp` is a deterministic string function, the exact profile the repo places in `app/lib/**` and covers with a co-located `.test.ts` (`workspacePersistence.ts`/`.test.ts`, `textSelection.ts`/`.test.ts`, `pdfPropositionParser.ts`/`.test.ts`), yet it is unexported at the repo root with no test among the 24 in the suite. That is what let Finding 1 through: a two-line test asserting `connect-src` covers the schemes `exportGraph` uses would have caught it. `buildUserMessage` is the closest sibling — a pure request-to-string builder — and it is exported from a `lib/` module.
**Recommendation:** Move `buildCsp` to `app/lib/security/buildCsp.ts` (exported) with `buildCsp.test.ts` asserting the directive set, and have `proxy.ts` import it. Keeping the rationale comments with the function preserves them at the point of edit.

#### 7. Matcher coverage is asymmetric with its own stated rationale

**Severity:** Minor
**Location:** `proxy.ts:51-63`
**Move:** Asymmetry (move 7) / idempotency-and-safety (move 9)
**Confidence:** Medium — the matcher semantics are clear from the pattern, but the practical impact on prefetched RSC payloads depends on Next's client navigation behaviour, which I did not exercise.
**Evidence:**
```
    source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```
**Legibility-target:** A reviewer checking whether the exclusion list matches the comment's three stated reasons.
The comment gives three rationales — skip API routes, skip static assets, skip prefetches — but the pattern implements them unevenly. `favicon.ico` is excluded while its siblings in `public/` (`file.svg`, `globe.svg`, `next.svg`, `vercel.svg`, `window.svg`) are not, so those responses each burn a freshly generated UUID nonce on an asset with no scripts, contradicting the "no scripts to nonce" rationale the comment gives for the exclusions. In the other direction, the prefetch exclusion means a page whose HTML/RSC payload arrives via prefetch is served with no CSP header at all — the policy applies to cold navigations but not to the warm client-side transitions that dominate a single-page workspace like this one. The `/api` exclusion is defensible for `script-src`, but it also drops `frame-ancestors 'none'` and `object-src 'none'` from every `/api/*` response, so the two consumer surfaces of this app carry different baseline guarantees.
**Recommendation:** Either broaden the static exclusion to cover `public/` assets by extension (matching the stated rationale) or drop the `favicon.ico` special case as inconsistent; and record explicitly — in code or in the decision record from Finding 5 — that prefetched navigations are intentionally uncovered, since that is the behaviour most likely to be mistaken for enforcement.

#### 8. `proxy` returns synchronously while every other request-handling export in the repo is `async`

**Severity:** Informational
**Location:** `proxy.ts:32` (`export function proxy(request: NextRequest): NextResponse`)
**Move:** Name-pattern audit (move 2) / asymmetry (move 7)
**Confidence:** High.
**Precedent:** `export async function POST(request: NextRequest)` used in `app/api/**/route.ts` (16 of 17 handlers)
**Evidence:**
```
export function proxy(request: NextRequest): NextResponse {
```
**Legibility-target:** A contributor who adds an `await` inside `proxy` and must change the signature, and any caller-side type inference that assumed a promise.
Next accepts both a sync and an async proxy, so this is not a contract violation — it is a local inconsistency with the repo's uniform "request handlers are async, returning `NextResponse`" shape. It also makes the first thing that needs I/O (a config lookup, a KV read, a feature flag) a signature change rather than an added `await`. The same diff makes `RootLayout` async for exactly that kind of forward-looking reason. Note also that the parameter is correctly named `request` and typed `NextRequest`, matching baseline 2 including the avoidance of `req`.
**Recommendation:** No change required. If `proxy` ever needs asynchronous work, make it `async` at that point rather than pre-emptively; the return type annotation is explicit, which is the important part.

### What Looks Good

- **Framework export shape is exact.** `proxy` + `config` from a root-level `proxy.ts` is precisely Next 16's contract, and adopting the framework's names verbatim is what the repo does everywhere else (`route.ts` HTTP verbs, `metadata`, `RootLayout`) — no invented wrapper, no re-export indirection.
- **Parameter naming and typing match the dominant route-handler convention** (`request: NextRequest`), including avoiding the `req` abbreviation that appears nowhere in `app/api/`.
- **`buildCsp`'s name follows the repo's `build<Noun>` precedent and its acronym casing rule** (`Csp`, like `Png`/`Llm`/`Pdf`), so it reads as native to the codebase.
- **The `style-src 'unsafe-inline'` carve-out is documented as deliberate at the point of the exception**, with the reason (Tailwind v4 inline styles) and the cost of removing it — this is the right shape for a policy exception, and matches the repo's habit of explaining *why* in module headers (`app/lib/utils/exportGraph.ts:1-4`).
- **Directives are built from a single ordered array joined once**, so there is one place to edit and no chance of a malformed separator — a better structure than string concatenation for a contract that will be amended repeatedly.
- **`await headers()` is the minimal way to force dynamic rendering** and is confined to the root layout rather than sprinkled across pages.

### Summary Table

| # | Finding | Severity | Location |
|---|---|---|---|
| 1 | `connect-src 'self'` breaks `fetch(dataUrl)` graph-export consumer | Breaking | `proxy.ts:25`; `app/lib/utils/exportGraph.ts:24,37` |
| 2 | Nonce published on `x-nonce`, not the request CSP header Next reads; `'strict-dynamic'` makes this fail closed | Breaking | `proxy.ts:40-48`, `proxy.ts:21` |
| 3 | `x-nonce` is a new wire contract with zero consumers and contradictory comments | Inconsistent | `proxy.ts:41` |
| 4 | `layout.tsx` comment documents a mechanism the code does not implement | Inconsistent | `app/layout.tsx:27-31` |
| 5 | No decision record; CLAUDE.md / ARCHITECTURE.md inventories stale | Minor | `docs/decisions/`, `CLAUDE.md:31` |
| 6 | `buildCsp` unexported and untested, off the `app/lib/**` + co-located-test pattern | Minor | `proxy.ts:17-30` |
| 7 | Matcher exclusions inconsistent with their stated rationale (public assets, prefetches, `/api`) | Minor | `proxy.ts:51-63` |
| 8 | `proxy` sync while all repo request handlers are async | Informational | `proxy.ts:32` |

### Overall Assessment

The *shape* of the new surface is consistent with the codebase: the file name, export names, parameter naming, and helper naming all match either the framework contract or the nearest repo neighbours, and the one deliberate policy exception is documented where it is taken. The problems are all on the *contract* axis rather than the naming axis. Two contracts are broken: an existing internal consumer (`exportGraph`'s `fetch` of a `data:` URL) is silently cut off by `connect-src 'self'`, and the nonce the whole design rests on is handed to a header no consumer reads, so the `script-src` directive binds to nothing while `'strict-dynamic'` removes the origin-based fallback. Around those sit a dead `x-nonce` contract, a comment that documents the non-existent mechanism, and the absence of the decision record the repo's own rules require for a change of this reach. Findings 1 and 2 should be resolved before this is considered enforcing anything; 3, 4, and 6 largely dissolve once 2 is fixed properly, since a real consumer and a testable `buildCsp` are the natural shape of that fix.

## Goal-Alignment Note

- **Answered:** Whether the new `proxy`/`config`/`buildCsp`/`x-nonce` surface matches the repo's established naming, placement, parameter, and documentation conventions (name-pattern audit above); whether existing consumers' contracts survive the change (Findings 1, 2); whether the new header contract has readers (Finding 3); doc/test drift on the changed surface (Findings 4, 5, 6); coverage asymmetries in the matcher (Finding 7).
- **Out of scope:** Whether the CSP is *secure enough* as a policy — the strength of `'unsafe-inline'` for styles, threat modelling of the markdown-sanitisation path the comment alludes to, and any XSS analysis belong to the security critic. Runtime/performance cost of forcing dynamic rendering on the root layout belongs to the performance critic. Whether Next 16's proxy runs on the Edge runtime and whether `Buffer`/`crypto.randomUUID` are available there was taken as stated in the source comment and not verified.
- **Escalate:** Findings 1 and 2 are behaviour-breaking, not stylistic, and each has a concrete runtime consequence (graph export fails; first-party scripts blocked). They warrant a manual page-load and export check before merge, regardless of what the other critics report. Finding 5's missing decision record is the one item that persists after the code is fixed and should be assigned rather than absorbed into the fix.
