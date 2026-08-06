# API Consistency Review — strict CSP proxy

Commit: e5d95a9
Range: `d86d2dc..HEAD` (4 commits: 9b4e453, b25e939, d90d6bb, e5d95a9)
Worktree: `/workspace/runs/review-arms/e3-loops/wt-csp-arm1` (branch `e3/csp-arm1`)
Surface under review: new root module `proxy.ts` (71 lines, new file) + `app/layout.tsx` (+18/−1)

Foundation: the merged code-fact-check (k=3) is taken as given and not re-verified. Its Incorrect findings — nonce-delivery wiring, the connect-src/exportGraph collision, the Tailwind style-src rationale, the historical-verification claim, and the stale Edge-runtime comment — are treated as established fact here and re-examined only through the interface-contract lens (who binds to what, and what silently breaks).

---

## Baseline conventions

Sampled siblings, chosen for adjacency to the new surface (a root-level config module, two server-side modules that generate ids, the framework's own config file, and the client consumer the new policy governs):

| Sibling | Path | Convention it establishes |
|---|---|---|
| `next.config.ts` | `next.config.ts` | Root-level framework config is a **typed** const (`const nextConfig: NextConfig = {...}`) with a `default` export. The type annotation is the guard against typo'd config keys. |
| `artifactRoute.ts` | `app/lib/formalization/artifactRoute.ts:10` | Pure derivation helpers are named `build<Noun>` (`buildUserMessage`). Same pattern at `app/lib/utils/pdfPropositionParser.ts:189,354`. |
| `callLlm.ts` / `streamLlm.ts` | `app/lib/llm/callLlm.ts:1`, `app/lib/llm/streamLlm.ts:1` | **Server-side** modules obtain randomness via `import { randomUUID } from "crypto"`. Client-side modules (`app/lib/stores/workspaceStore.ts:34`, `app/hooks/useWorkspaceSessions.ts:96`) use the *global* `crypto.randomUUID()`. The split is consistent across the repo: import form on the server, global form in the browser. |
| `app/api/verification/lean/route.ts` | same | The only place in the repo that sets an HTTP header explicitly: `headers: { "Content-Type": "application/json" }`. Errors are JSON `{ error: string }` with a status; unreachable dependencies **fail open** to a degraded-but-working response (`{ valid: true, mock: true }`), never a 500. |
| `exportGraph.ts` / `exportAll.ts` | `app/lib/utils/exportGraph.ts:24,37`; `app/lib/utils/exportAll.ts:60-69` | Client-side image export is implemented as `toPng(...) → fetch(dataUrl) → blob()`. Failures are best-effort: `exportAll` catches and `console.warn`s, keeping the zip; `GraphPanel.tsx:98-110` catches and `console.error`s. |

Two facts about the baseline matter for everything below:

1. **No custom `x-*` header exists anywhere in the repo.** `rg 'headers\.(set|get)'` across the tree returns exactly one non-diff hit — the `Content-Type` above. The diff introduces the codebase's first request-header contract and its first response-header contract simultaneously.
2. **No response-header policy has ever governed client code before.** Every existing client module was written against an implicit "the browser will let me do anything" contract. A global CSP is a retroactive narrowing of that contract on ~120 existing files, and nothing in the diff audits them.

---

## Name-Pattern Audit

Every new public (or framework-visible) name in the diff, against its nearest existing neighbors.

| New name | Kind | Nearest neighbors in repo | Verdict |
|---|---|---|---|
| `proxy.ts` (filename) | Root module | `next.config.ts`, `postcss.config.mjs`, `vitest.config.ts`, `eslint.config.mjs` — all root-level, all framework-mandated names | **Consistent.** Framework-mandated by Next 16; matches the repo's flat root-config layout. |
| `proxy` (exported fn) | Framework entry point | no sibling entry points; nearest is `export default nextConfig` in `next.config.ts` | **Consistent.** Name is dictated by the framework, not chosen. |
| `config` (exported const) | Framework config object | `const nextConfig: NextConfig` (`next.config.ts:3`) | **Divergent on typing, not on naming.** See Finding 6 — the name is mandated, but the sibling annotates its config type and this one does not. |
| `buildCsp` | Module-private fn | `buildUserMessage` (`app/lib/formalization/artifactRoute.ts:10`), `buildPropositionIndex` (`app/lib/utils/pdfPropositionParser.ts:354`), `buildLine` (`:189`) | **Consistent.** `build<Noun>` for a pure string/structure derivation is the established pattern. |
| `Csp` (acronym casing) | Identifier casing | `callLlm`, `streamLlm`, `transformSseStream`, `parsePdfPropositions`, `downloadGraphAsPng`, `parseJson` | **Consistent.** Dominant convention is PascalCase-not-SCREAMING for acronyms (6 of 7 hits); `extractTextFromPDF` (`app/lib/utils/fileExtraction.ts:34`) is the lone outlier. `buildCsp` sides with the majority. |
| `devOnly` | Local const | `REQUEST_TIMEOUT_MS` (`app/api/verification/lean/route.ts:5`), `EXPORT_BG` (`app/lib/utils/exportGraph.ts:14`) | **Minor drift.** Siblings name locals after *what the value is*; `devOnly` names *when it applies*. `devEvalDirective` would match. Not worth a finding on its own; noted for completeness. |
| `x-nonce` (request header) | New wire contract | none — no `x-*` header exists in the repo; only `Content-Type` is ever set | **Divergent — no precedent, and no consumer.** See Findings 2 and 3. |
| `Content-Security-Policy` (response header) | New wire contract | none — first response header set by app code | **No existing precedent in the repo.** Governed by the CSP spec rather than local convention, so naming is not at issue; the *coverage* contract is (Findings 1, 4). |
| `RootLayout` (now `async`) | Component signature | no sibling layouts; `app/page.tsx:40` and all components are sync | **Signature change, framework-permitted.** See Finding 8 for the contract it encodes implicitly. |

---

## Findings

#### 1. `connect-src 'self'` silently breaks both existing graph-export consumers

**Severity:** Breaking
**Location:** `proxy.ts:33` (`"connect-src 'self'"`); consumers at `app/lib/utils/exportGraph.ts:24` and `:37`
**Move:** Consumer contract — trace every existing caller bound to the surface the new policy narrows
**Confidence:** High
**Evidence:**

```
// proxy.ts
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
    "connect-src 'self'",
```

```ts
// app/lib/utils/exportGraph.ts:20-26
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
```

**Legibility-target:** A reviewer who opens `proxy.ts` and `app/lib/utils/exportGraph.ts` side by side should be able to see the collision without running the app.

`toPng` returns a `data:image/png;base64,…` URL, and `fetch()` against it is a *fetch-directive* request governed by `connect-src`, not by `img-src`. The diff carefully allows `data:` for `img-src` and `font-src` — the author was thinking about `data:` URLs — but the one directive that governs the repo's only `data:`-URL *fetch* omits it. The fact-check has already confirmed the collision; the API-consistency point is that the new global policy is a **breaking change to an internal contract that has two existing callers and zero tests**, and nothing in the diff acknowledges either.

Both callers reach it through dynamic imports, so neither the type-checker nor the bundler can surface the dependency:

- `app/components/panels/GraphPanel.tsx:102` → `downloadGraphAsPng` — the "Export Graph" button.
- `app/lib/utils/exportAll.ts:10,64` → `graphToPngBlob` — the graph PNG inside "Export All", reached from `app/page.tsx:576`.

The `img-src`/`connect-src` split is also the clearest internal asymmetry in the policy: the same `data:` scheme is trusted enough to *render* but not enough to *read back*, with no comment explaining the distinction. That asymmetry is exactly what a reader would need in order to notice the bug.

**Recommendation:** Add `data:` to `connect-src` (`"connect-src 'self' data:"`) with a one-line comment naming `exportGraph.ts` as the reason, so the coupling is discoverable from the policy side. Better still, remove the coupling: `toPng` has a `toBlob` sibling in `html-to-image`, which eliminates the `fetch(dataUrl)` round-trip entirely and makes both consumers CSP-agnostic. Either way, add a test that asserts the built policy string admits whatever scheme the export path actually uses — right now `buildCsp` is module-private and untestable (Finding 11).

---

#### 2. The nonce is published on two headers, and Next binds to neither

**Severity:** Breaking
**Location:** `proxy.ts:48-54`; claim at `app/layout.tsx:28-31`
**Move:** Producer/consumer contract — identify who is supposed to read each field
**Confidence:** High (mechanism established by the merged fact-check)
**Evidence:**

```ts
// proxy.ts:48-54
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

```
// app/layout.tsx:28-31
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
```

**Legibility-target:** A reader should be able to answer "who consumes the nonce?" from the diff alone. Today the diff names two candidate consumers and delivers to neither.

Treating the fact-check as foundation — the request-side CSP header is never set and `x-nonce` has no reader — the interface shape of the defect is a **two-sided contract with both sides unwired**. The producer emits `x-nonce` on the *request* headers (documented for server components to read) while the layout comment explicitly declines to read it; and the enforcement policy goes on the *response*, which is not the surface the renderer inspects. The result is a script-src whose nonce matches nothing.

The consistency consequence is severe rather than cosmetic because of directive interaction inside the same line: `script-src 'self' 'nonce-…' 'strict-dynamic'`. In any CSP3 browser, the presence of `'strict-dynamic'` causes `'self'` (and all host-source expressions) to be **ignored**. So the fallback that would otherwise have kept same-origin bundles running is deliberately disabled by the same directive, and an unmatched nonce means *no* script executes. The policy is not "strict but working" — for a production build it is "everything blocked", and every page in the app is the consumer.

**Recommendation:** Pick one delivery surface and wire it end to end. The lower-risk shape, given `app/layout.tsx` is the only document shell, is to set the CSP on the forwarded **request** headers as well as the response, so the renderer can extract the nonce — and then delete `x-nonce`, which becomes redundant (Finding 3). Whichever surface is chosen, the layout comment must name the mechanism that is actually in force; right now it asserts the behavior that the code does not implement, which is what let the gap survive three commits.

---

#### 3. `x-nonce` is a wire contract with a producer, no consumer, and no naming precedent

**Severity:** Inconsistent
**Location:** `proxy.ts:48-49`; contradicted at `app/layout.tsx:28-31`
**Move:** Name-pattern audit + dead-contract check
**Confidence:** High
**Precedent:** No existing precedent in the repo — `rg 'headers\.(set|get)'` over `app/`, `proxy.ts`, and `verifier/` returns exactly one non-diff hit, `"Content-Type": "application/json"` at `app/api/verification/lean/route.ts:23`. No `x-*` header is defined or read anywhere.
**Evidence:**

```ts
// proxy.ts:46-49
  // Forward the nonce to server components via a request header so layouts
  // can read it via `headers()` and pass it to <Script> tags they render.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
```

**Legibility-target:** A future contributor adding a `<Script>` tag needs to know whether `x-nonce` is load-bearing. Today the doc comment says yes and the layout says no.

Two problems compound. First, the header's docstring and its only would-be consumer disagree in the same diff — `proxy.ts:46-47` says layouts read it, `app/layout.tsx:30-31` says they don't need to. A contract that documents itself into existence and is then explicitly declined is worse than no contract: the next person to add a client `<Script>` will find `x-nonce` in the proxy, assume it works, and ship a blocked script.

Second, the name arrives with no local convention to lean on and picks the one prefix the standards have moved away from — `X-` prefixing for application headers was deprecated by RFC 6648 in 2012. Because this is the repo's *first* custom header, whatever it does becomes the precedent for every header added after it. That makes the choice worth more scrutiny than a one-off would get, and it is the strongest argument for deleting the header rather than renaming it.

**Recommendation:** Delete `x-nonce` and the `NextResponse.next({ request })` rewrite along with it once Finding 2 is resolved via the CSP request header — the nonce then travels on a standard header with a defined reader. If a custom header is genuinely needed later, establish the convention deliberately (unprefixed, lowercase, app-scoped: `mfc-nonce`) and document it, rather than letting an unconsumed header set the precedent by accident.

---

#### 4. A client-supplied request header can suppress the policy entirely

**Severity:** Inconsistent
**Location:** `proxy.ts:58-71` (`config.matcher[0].missing`)
**Move:** Coverage asymmetry — where does the contract *not* apply, and who controls that?
**Confidence:** High (mechanism), Medium (practical exposure)
**Evidence:**

```ts
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
  ],
```

**Legibility-target:** Someone reasoning about "is this page covered by the CSP?" should get a yes/no from the path alone. Here the answer also depends on request headers the caller controls.

The stated rationale — "would otherwise burn a nonce on a request that may never paint" — describes a cost that does not exist: `buildCsp` is a pure string concatenation over a `randomUUID`, with no allocation of a limited resource and nothing to burn. What the exclusion buys is nothing; what it costs is that **policy coverage becomes a function of request headers rather than of route**. Any client can send `purpose: prefetch` on a top-level navigation and receive a document with no `Content-Security-Policy` header at all.

This is an inconsistency in the contract's shape, not only a security nit: every other exclusion in the matcher is *path*-scoped and therefore statically knowable (`api`, `_next/static`, `_next/image`, `favicon.ico`), matching how the rest of the repo scopes behavior — see `app/api/*/route.ts`, where the route path fully determines the handler. The `missing:` clause is the one rule whose outcome the caller decides, and it sits directly beside four rules that the server decides.

**Recommendation:** Drop the `missing:` clause and apply the policy to every matched path. If prefetch exclusion is later shown to be needed for a measured reason, re-add it with the measurement in the comment; the current comment justifies it with a cost that `buildCsp` does not incur.

---

#### 5. Server-side randomness uses the client-side idiom, and pairs it with a Node-only global

**Severity:** Inconsistent
**Location:** `proxy.ts:42-44`
**Move:** Name-pattern audit — same capability, established split by execution context
**Confidence:** High (convention divergence), Medium (runtime consequence — see note)
**Precedent:** `import { randomUUID } from "crypto"` used in `app/lib/llm/callLlm.ts:1` and `app/lib/llm/streamLlm.ts:1` (both server-side); global `crypto.randomUUID()` used in `app/lib/stores/workspaceStore.ts:34`, `app/hooks/useWorkspaceSessions.ts:96,143`, `app/hooks/useFormalizationSessions.ts:71`, `app/components/panels/CausalGraphPanel.tsx:120` (all client-side).
**Evidence:**

```ts
  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
  // available in the Edge runtime that Next proxy runs in.
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

**Legibility-target:** A reader should be able to tell which runtime a module targets from its import style, as they can for every other server module in the repo.

The repo has a clean, unbroken split: server modules import `randomUUID` from `"crypto"`; browser modules use the global. `proxy.ts` is a server module that uses the browser form — the first exception in the codebase — and then combines it with `Buffer`, which is a **Node global with no Edge-runtime equivalent**. The comment asserts both are available in Edge; per the merged fact-check that Edge-runtime claim is stale/incorrect, so the code is currently relying on Node semantics while documenting Edge semantics. Whichever runtime is actually in force, the file states one and depends on the other, which is precisely the condition that makes a future runtime change silently fatal — `Buffer.from` on Edge is a `ReferenceError` on *every* request.

There is also a smaller contract oddity: `Buffer.from(uuid).toString("base64")` base64-encodes a string that is already 36 CSP-safe ASCII characters. No other id in the repo is re-encoded (`workspaceStore.ts:34` and the four hook sites use `randomUUID()` raw). The encoding adds a Node dependency and buys nothing the raw UUID lacks.

**Recommendation:** Match the server convention — `import { randomUUID } from "crypto"` at the top of `proxy.ts` — and drop the `Buffer` round-trip in favor of using the UUID directly as the nonce. That removes the only Node-global dependency in the file and makes the module runtime-portable regardless of how the Edge-vs-Node question in the comment is finally resolved. Fix the comment in the same change so it names the runtime that is actually configured.

---

#### 6. `export const config` is untyped, unlike the sibling root config

**Severity:** Minor
**Location:** `proxy.ts:57-71`
**Move:** Name-pattern audit — compare the new config export to the existing one
**Confidence:** High
**Precedent:** `const nextConfig: NextConfig = { … }` at `next.config.ts:3`, with `import type { NextConfig } from "next"` at `:1`.
**Evidence:**

```ts
// next.config.ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
};
```

```ts
// proxy.ts
export const config = {
  matcher: [ … ],
};
```

**Legibility-target:** A contributor editing the matcher should get a compile error for a misspelled key, as they would in `next.config.ts`.

The repo's one existing root-config module annotates its type explicitly even though the object is *empty* — the annotation is there purely as a guard, which is a deliberate convention worth matching. The new config object is considerably more intricate (a nested matcher with `source`, `missing`, `type`, `key`, `value`) and is the one that would actually benefit: a typo in `missing` or `source` currently degrades silently to "matcher does not apply", producing a page with no CSP and no error anywhere.

`proxy.ts` already imports types from `next/server` (`import type { NextRequest }`) and annotates the function's return as `NextResponse`, so the file's own style is otherwise type-forward. The config export is the one place it lapses.

**Recommendation:** Annotate with Next's exported proxy/middleware config type (imported as a `type`, matching `next.config.ts:1` and `proxy.ts:2`). If Next 16 does not export a public type for the proxy config, declare a local `satisfies`-checked shape rather than leaving the object untyped.

---

#### 7. Consumers of the newly-narrowed contract fail three different ways, none visible to the user

**Severity:** Minor
**Location:** `app/components/panels/GraphPanel.tsx:98-110`, `app/lib/utils/exportAll.ts:60-69`, `app/api/verification/lean/route.ts:38-41`
**Move:** Error consistency across callers of the same broken surface
**Confidence:** High
**Evidence:**

```ts
// GraphPanel.tsx:98-110 — logs at error level, resets spinner, shows nothing
    } catch (err) {
      console.error("[graph export]", err);
    } finally {
      setExporting(false);
    }
```

```ts
// exportAll.ts:67-69 — logs at warn level, zip still ships without the image
  } catch (err) {
    console.warn("[export] Could not capture graph image:", err);
  }
```

**Legibility-target:** A user who clicks "Export Graph" after this change should be able to tell that something failed.

Finding 1 establishes that both graph-export paths break. This finding is about what the codebase does *with* that breakage, and the answer is inconsistent across three levels for the same class of failure: `console.error` with no UI (GraphPanel), `console.warn` with silent partial output (exportAll), and — the repo's own best precedent — a *deliberate, documented* degraded response in `app/api/verification/lean/route.ts:38-41`, which returns `{ valid: true, mock: true }` so the caller can tell it received a fallback.

The API-consistency issue is that the CSP change converts two "should basically never happen" catch blocks into the **normal** path, and neither of them was designed to be the normal path. The user-visible result of shipping this diff as-is: the Export Graph button spins and completes with no file and no message, and Export All produces a zip that is quietly missing `proof-graph.png` — the same failure signalled at two different severities and surfaced to the user at neither.

**Recommendation:** Out of scope to redesign export error handling in this diff, and it should not be redesigned here. But since this change is what promotes those paths to live, the diff should either (a) fix Finding 1 so they stay cold, or (b) if the CSP restriction is intended to stand, raise the two handlers to a user-visible failure and align them on the `mock: true`-style explicit-degradation signal the API layer already uses.

---

#### 8. The dynamic-rendering contract is encoded as a side-effect call rather than the declarative export

**Severity:** Minor
**Location:** `app/layout.tsx:24-41`
**Move:** Idempotency / intent-expression — is the contract stated, or merely implied by a side effect?
**Confidence:** High
**Precedent:** The repo consistently expresses build/runtime configuration declaratively — `next.config.ts`, `vitest.config.ts`, `postcss.config.mjs`, `eslint.config.mjs`, `package.json` scripts. No other module opts into behavior by calling a function and discarding its result.
**Evidence:**

```tsx
  // This dynamic opt-out is deliberate and load-bearing, not an oversight: a
  // statically prerendered document is built once, so its <script> tags would
  // carry a stale nonce (or none) and be blocked by the CSP on every request
  // after the first.
  await headers();
```

**Legibility-target:** The "do not delete this line" contract should survive a contributor who does not read the comment.

The reasoning in the comment is sound and the expanded version added in e5d95a9 is genuinely good documentation. The issue is purely where the contract lives: `await headers()` with a discarded result is an expression whose entire purpose is invisible at the call site. It is the kind of line that a lint rule (`no-void`, unused-expression rules), a code-simplifier pass, or a contributor tidying an `async` component will remove — and removing it produces no error, no test failure, and no type change, just a silently stale nonce on every request after the first. The comment is load-bearing in the literal sense: delete it and the line looks like dead code.

Next provides `export const dynamic = "force-dynamic"` for exactly this, which is self-describing, greppable, and cannot be mistaken for an accidental call. It also matches how everything else in this repo is configured — declaratively, at the top of the module.

**Recommendation:** Replace `await headers()` with `export const dynamic = "force-dynamic"` and keep the existing comment attached to it verbatim; the rationale is worth preserving, it just needs a self-explanatory anchor. Reverting `RootLayout` to a synchronous function then falls out for free.

---

#### 9. `blob:` is trusted for images but not by the directive that governs workers

**Severity:** Minor
**Location:** `proxy.ts:28-36`; affected consumer `app/lib/utils/fileExtraction.ts:24-31` (also `app/lib/utils/pdfPropositionParser.ts:442-447`)
**Move:** Asymmetry — same scheme, different trust, no stated reason
**Confidence:** Medium
**Evidence:**

```
    "default-src 'self'",
    …
    "img-src 'self' data: blob:",
```

```ts
// app/lib/utils/fileExtraction.ts:25-31
  const pdfjsLib = await import("pdfjs-dist");
  pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
    "pdfjs-dist/build/pdf.worker.min.mjs",
    import.meta.url,
  ).toString();
```

**Legibility-target:** A reader should be able to enumerate which schemes the app relies on and see each one accounted for in the policy.

The policy enumerates eight directives but omits `worker-src`, which therefore falls back to `default-src 'self'` — a fallback that excludes `blob:` even though the directive right above it explicitly admits `blob:` for images. The repo has two PDF paths that install a worker (`fileExtraction.ts`, `pdfPropositionParser.ts`); both resolve `workerSrc` to a bundled same-origin asset, which `'self'` permits, so the common path is fine. The residual risk is that `pdfjs-dist` has historically fallen back to instantiating its worker from a `blob:` URL when the direct load fails, and under this policy that fallback would be blocked rather than degrading — with the failure surfacing as a broken PDF upload rather than as a CSP message anyone connects back to `proxy.ts`.

Flagging at Medium confidence because whether the fallback path is reachable depends on `pdfjs-dist` version behavior I did not verify. The consistency point stands regardless of that: the policy grants `blob:` in one directive and silently withholds it in a fallback, with no comment marking the choice as intentional — the same shape of omission as Finding 1, and the reason both were easy to miss.

**Recommendation:** Enumerate `worker-src 'self' blob:` explicitly, and add a short comment listing which repo paths each non-obvious scheme exists for (`data:` for `exportGraph`, `blob:` for pdfjs and `URL.createObjectURL` in `app/lib/utils/export.ts:8`). The policy's directive list is the natural place for that index, and having it would have made Finding 1 self-evident.

---

#### 10. The policy ships enforce-only, with no reporting contract and no staged rollout

**Severity:** Informational
**Location:** `proxy.ts:27-36` (directive list)
**Move:** Rollout/observability contract for a change that narrows an existing surface
**Confidence:** High
**Evidence:** The `directives` array contains no `report-uri`, no `report-to`, and the header key at `proxy.ts:54` is `Content-Security-Policy`, not `Content-Security-Policy-Report-Only`.
**Legibility-target:** Whoever operates this app should be able to find out what the policy is blocking without a user filing a bug.

Findings 1 and 2 both describe violations that produce **no server-side signal at all** — they surface only as a browser console message on the user's machine. A policy that retroactively constrains ~120 pre-existing client files, none of which were written with it in mind, is precisely the case where a report sink or a Report-Only shakedown period pays for itself: either mechanism would have surfaced the `fetch(dataUrl)` block and the unmatched-nonce block on the first page load rather than in review.

**Recommendation:** Ship as `Content-Security-Policy-Report-Only` first, or add a `report-to` endpoint (an `app/api/csp-report/route.ts` would sit naturally alongside the existing routes and match their `NextResponse.json` shape), and flip to enforcing once the report stream is clean. This is an operational suggestion rather than a defect in the interface, hence Informational.

---

#### 11. `buildCsp` has no test seam, and its `nonce` parameter has no defined empty contract

**Severity:** Informational
**Location:** `proxy.ts:24-38`
**Move:** Nullability / testability of the new contract
**Confidence:** High
**Evidence:**

```ts
function buildCsp(nonce: string): string {
```

**Legibility-target:** The policy string is the single most consequential value in this diff; it should be assertable in a test.

`buildCsp` is well-shaped in isolation — pure, deterministic given `NODE_ENV`, single-purpose, and correctly named per the audit above. But it is module-private in a file whose only other export is a framework entry point, so there is no way to assert anything about the policy string from `vitest`. Every finding in this review that concerns the policy's *content* (1, 9, and the `'strict-dynamic'` interaction in 2) is the kind of thing a three-line unit test would have pinned.

On nullability: the signature accepts any `string`, including `""`, which would emit the directive `'nonce-'` — syntactically valid CSP that matches nothing, i.e. a total script block presented as a working policy. The current caller can't produce an empty nonce, so this is latent rather than live; it becomes real if the `Buffer`/`crypto` line in Finding 5 is refactored.

**Recommendation:** Export `buildCsp` (it is a pure function; exporting it costs nothing and matches how `app/lib/utils/*` exposes helpers for `*.test.ts` siblings) and add a `proxy.test.ts` asserting: the nonce appears in `script-src`, `'unsafe-eval'` is absent when `NODE_ENV !== "development"`, and each scheme the app depends on is admitted by the directive that governs it.

---

## What Looks Good

- **`buildCsp` naming and shape.** Matches `buildUserMessage` / `buildPropositionIndex` exactly — `build<Noun>`, pure, returns the derived value rather than mutating. Acronym casing sides with the repo majority (`callLlm`, `transformSseStream`, `parsePdfPropositions`).
- **The directive array as a data structure.** `directives.join("; ")` over an array of strings is far more reviewable and diff-friendly than a template literal, and each directive lands on its own line in a diff. This is the right shape for a value that will be edited under review pressure.
- **Explicit return typing on the entry point.** `function proxy(request: NextRequest): NextResponse` annotates both sides, and `import type { NextRequest }` correctly uses a type-only import — consistent with `next.config.ts:1`. Only the `config` export missed this (Finding 6).
- **Path exclusions in the matcher are stated positively and explained.** The `api` / `_next/static` / `_next/image` / `favicon.ico` exclusions each have a reason in the comment, and each is statically determined by the route. That is the right model; only the header-conditional `missing:` clause departs from it (Finding 4).
- **The dev-only `'unsafe-eval'` carve-out is correctly gated and correctly documented.** `NODE_ENV`-gated, confined to a single `devOnly` term appended to one directive, and the comment states both why it is needed and why it cannot reach production. The fact-check verified the mechanism; from an interface standpoint the carve-out is the narrowest possible one and does not leak into any other directive.
- **The expanded layout comment added in e5d95a9.** It states the tradeoff, quantifies the cost ("the app is a single `use client` route with no `generateStaticParams`, revalidate, or ISR"), and names the condition under which to revisit (hashes instead of nonces). That is the standard other comments in this repo should be held to; Finding 8 is only about giving it a more durable anchor than a discarded expression.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | `connect-src 'self'` breaks `fetch(dataUrl)` in both graph-export consumers | Breaking | `proxy.ts:33` → `exportGraph.ts:24,37` | High |
| 2 | Nonce published on two headers; Next binds to neither, and `'strict-dynamic'` disables the `'self'` fallback | Breaking | `proxy.ts:48-54`; `app/layout.tsx:28-31` | High |
| 3 | `x-nonce` is a producer-only header with no precedent and a self-contradicting docstring | Inconsistent | `proxy.ts:48-49` | High |
| 4 | `missing:` prefetch clause lets a caller suppress the CSP via request headers | Inconsistent | `proxy.ts:64-68` | High / Medium |
| 5 | Server module uses the client `crypto` idiom plus Node-only `Buffer`, against a stale Edge comment | Inconsistent | `proxy.ts:42-44` | High / Medium |
| 6 | `export const config` untyped, unlike `const nextConfig: NextConfig` | Minor | `proxy.ts:57-71` | High |
| 7 | Three inconsistent, user-invisible failure modes for the same newly-live breakage | Minor | `GraphPanel.tsx:98-110`; `exportAll.ts:60-69` | High |
| 8 | Dynamic-rendering contract encoded as a discarded `await headers()` side effect | Minor | `app/layout.tsx:40` | High |
| 9 | `blob:` allowed for `img-src` but withheld by the `worker-src`→`default-src` fallback | Minor | `proxy.ts:28-36` | Medium |
| 10 | Enforce-only rollout with no `report-to`/Report-Only stage | Informational | `proxy.ts:27-36,54` | High |
| 11 | `buildCsp` unexported/untestable; `nonce: ""` yields a silently-matchless directive | Informational | `proxy.ts:24-38` | High |

---

## Overall Assessment

As a piece of interface design the proxy is better than most first-cut CSP implementations: the directive list is a reviewable data structure, the dev-only carve-out is minimally scoped and honestly documented, `buildCsp` lands on the repo's established `build<Noun>` pattern, and the layout comment added in e5d95a9 explains its tradeoff at a standard the rest of the codebase does not reach. The naming audit turns up essentially nothing to correct in the identifiers the author actually chose — the one place naming goes wrong is `x-nonce`, and that is a header the diff should not be introducing at all.

The problems are all in the *contracts*, and they share a single root: this diff introduces the codebase's first response-header policy — a retroactive narrowing of an implicit contract that ~120 existing client files were written against — without auditing any of those files. Two Breaking consequences follow. The nonce is delivered on surfaces nothing reads, and because `'strict-dynamic'` deliberately voids the `'self'` fallback in the same directive, a production build ships a policy that blocks every script on every page. And `connect-src 'self'` blocks `fetch(dataUrl)` in `exportGraph.ts`, killing both export paths — a collision made harder to spot by the policy's own asymmetry, where `data:` is granted to `img-src` two lines above and withheld from the one directive that governs the repo's only `data:` fetch. Both consumers are reached through dynamic imports, so nothing in the type system or the bundler could have flagged them.

Neither Breaking finding is expensive to fix — one directive term and one header placement — but neither should merge as-is, and the deeper fix is structural: `buildCsp` needs to be exported and tested (Finding 11) so that the policy's content is assertable, and the directive list needs comments naming which repo path each non-obvious scheme exists for (Finding 9), so the next person to tighten a directive can see what they are about to break. Findings 3, 4, 5, 6, and 8 are all cheap and worth taking in the same pass; 7 and 10 are follow-ups that this change makes newly urgent rather than defects it introduces.

## Goal-Alignment Note

- **Answered:** Baseline conventions drawn from five siblings (`next.config.ts`, `artifactRoute.ts`, `callLlm.ts`/`streamLlm.ts`, `app/api/verification/lean/route.ts`, `exportGraph.ts`/`exportAll.ts`); the required Name-Pattern Audit covering all nine new framework-visible or wire-level names (`proxy.ts`, `proxy`, `config`, `buildCsp`, acronym casing, `devOnly`, `x-nonce`, `Content-Security-Policy`, `RootLayout`'s async signature), each with an explicit precedent or an explicit no-precedent statement; the consumer-contract question the brief named (`connect-src` vs. the pre-existing `fetch(dataUrl)` consumers at `exportGraph.ts:24,37`, reached from `GraphPanel.tsx:102` and `exportAll.ts:64`); the `x-nonce` header contract and its missing reader; error consistency across the three handlers that the change promotes to the live path; policy asymmetries (`data:` in `img-src` vs. `connect-src`; `blob:` in `img-src` vs. the `worker-src` fallback; path-scoped vs. header-scoped matcher exclusions); nullability of `buildCsp`'s `nonce` parameter; and idempotency (`buildCsp` is pure and deterministic given `NODE_ENV`; the per-request nonce is intentionally non-deterministic; `await headers()` is a discarded-result side effect).
- **Out of scope:** Re-verification of the merged fact-check's findings — nonce-delivery wiring, the connect-src/exportGraph collision, the Tailwind `style-src` rationale, the historical-verification claim, and the stale Edge-runtime comment are used as foundation and examined only for their interface consequences. Also excluded: exploitability analysis of the CSP itself (security-reviewer's lane — Finding 4 is scoped to contract shape, not attack narrative), performance of `buildCsp` per request, whether strict CSP is the right feature at all, and any redesign of the export error-handling paths beyond noting in Finding 7 that this diff promotes them to live.
- **Escalate:** (1) Findings 1 and 2 are both Breaking and both ship a dead app or a dead feature — they gate merge, and Finding 2 in particular means no page renders in production, which no test in the repo would currently catch. (2) The `worker-src`/`blob:` risk in Finding 9 rests on `pdfjs-dist` fallback behavior I did not verify against the installed version (`^5.6.205`); someone should confirm whether the blob-worker path is reachable before relying on `'self'` alone. (3) Finding 4's practical exposure — whether a `purpose: prefetch` header on a top-level document navigation actually yields an uncovered HTML response in Next 16 — is asserted from the matcher semantics, not tested; worth confirming empirically before deciding between dropping the clause and keeping it.
