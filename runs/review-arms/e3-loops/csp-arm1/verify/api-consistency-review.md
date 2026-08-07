# API Consistency Review — e3-loops / csp-arm1 (Arm 1 verification pass)

- **Commit:** 1eb081e
- **Branch:** e3/csp-arm1
- **Scope:** `git diff d86d2dc..HEAD` (worktree `wt-csp-arm1`; ancestors of HEAD only)
- **Reviewer skill:** api-consistency-reviewer
- **Merge standard:** 0R + 0A (0 Breaking, 0 Inconsistent required to merge)
- **Legibility-target:** the author on re-read six months out, and the next agent that touches the CSP proxy or the graph-export path without prior context.

## Verdict up front

**0 Breaking.** No consumer-facing contract in the tree is broken by any change in this range. The two changes flagged by the brief as contract-affecting — `buildCsp`'s signature change to a required `nodeEnv`, and the wholesale deletion of the `x-nonce` request-header contract — are both clean: the sole `buildCsp` caller is updated in the same commit, and `x-nonce` had no readers anywhere in the tree.

**0 new Inconsistent.** No new naming, error-format, or asymmetry inconsistency at the Inconsistent tier. One Low/nit on a private helper name (below), which is out of the public-surface audit and downgraded accordingly.

**Both prior advisory findings verified CLOSED** (prefetch matcher; untyped config).

---

## Prior-finding verification (carried, advisory → confirmed closed)

### CARRIED-1 — prefetch `missing:` matcher exclusion — **CLOSED**

Prior full-2 api finding: matcher used a `missing:` prefetch-exclusion clause, making CSP coverage a function of a client-supplied request header (Inconsistent). Now removed.

**Evidence** (`proxy.ts`, verbatim):
```ts
export const config: ProxyConfig = {
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
    },
  ],
};
```
The matcher entry carries only a server-determined `source` regex — no `missing:` / `has:` header condition. A regression guard now asserts the invariant from the test side (`proxy.test.ts`, "excludes routes only on server-determined criteria"):
```ts
for (const entry of config.matcher ?? []) {
  expect(typeof entry).not.toBe("string");
  const matcher = entry as { missing?: unknown; has?: unknown };
  expect(matcher.missing).toBeUndefined();
  expect(matcher.has).toBeUndefined();
}
```
Closed, and now double-guarded (code + test).

### CARRIED-2 — untyped `config` export — **CLOSED**

Prior full-2 api finding: the `config` export was untyped, so a matcher-key typo (`missng:` for `missing:`) would silently change coverage instead of failing the build (Inconsistent). Now typed.

**Evidence** (`proxy.ts`, verbatim):
```ts
import type { NextRequest, ProxyConfig } from "next/server";
...
export const config: ProxyConfig = {
```
`ProxyConfig` is a genuine export of `next/server` (confirmed at `node_modules/next/server.d.ts:14`), so the annotation is real, not a phantom type. **Precedent:** matches the sibling framework-config annotation `const nextConfig: NextConfig = {...}` in `next.config.ts:3` — the same "annotate the framework config object with the framework's own type" pattern the proxy.ts comment cites. Closed.

---

## Findings (this range)

### Change 1 — `buildCsp(nonce, nodeEnv)`: `nodeEnv` now required — **Not Breaking**

`buildCsp` is a new exported library function within this diff scope (`app/lib/security/csp.ts` is created in the range). Its signature is:

**Evidence** (`app/lib/security/csp.ts`, verbatim):
```ts
export function buildCsp(nonce: string, nodeEnv: string | undefined): string {
```

- **Consumer impact — sole caller updated?** Yes. The only non-test caller in the tree is `proxy.ts`, which passes both arguments:
  ```ts
  const csp = buildCsp(nonce, process.env.NODE_ENV);
  ```
  (`rg "buildCsp("` returns exactly one production call site plus the test file; no other module imports it.) A required second parameter would be Breaking only if a caller passed one argument — none does.
- **Design assessment (positive):** the parameter is deliberately *not* defaulted, and typed `string | undefined` rather than a narrowed enum, so the shipping (production) branch is the one branch tests can exercise without mutating global `process.env`. The fail-closed semantics (anything ≠ `"development"` → stricter policy) are pinned by `csp.test.ts` across `undefined`, `""`, `"Development"`, `"dev"`, `"test"`, `"prod"`. This is a correctness-preserving, testability-improving contract, not a hazard.

**Name-pattern:** `buildCsp` — verb-prefix `build*`. **Precedent:** yes — `buildUserMessage` (exported, `app/lib/formalization/artifactRoute.ts:10`), `buildLine` / `buildPropositionIndex` (`app/lib/utils/pdfPropositionParser.ts`). Verb-prefix exported helpers are the dominant convention in `app/lib/` (`extractTextFrom*`, `exportAllAsZip`, `gatherDependencyContext`, `parseLatexPropositions`, …). No tier penalty. Good name.

### Change 2 — `x-nonce` request-header contract deleted (with its two tests) — **Not Breaking**

The previous plumbing published an `x-nonce` header on the forwarded request as a conventional seam for server components. It is now removed entirely.

- **Orphaned-consumer check:** `rg "x-nonce|xNonce|X-Nonce"` over the whole tree returns only (a) the `proxy.ts` comment documenting the deliberate omission, (b) the `app/layout.tsx` comment stating the layout does not read it, and (c) the `proxy.test.ts` guard asserting the header is absent. **No component, hook, or server module reads `x-nonce`.** Deleting a published-but-unread contract breaks no consumer.
- **Why this is the right direction, not a regression:** Next parses the nonce out of the *request* `Content-Security-Policy` header (still set by `proxy.ts`), so hydration does not depend on `x-nonce`. The deletion is guarded symmetrically: a test asserts the header stays absent, and both `proxy.ts` and `layout.tsx` carry a "reinstate the header and its reader together" note — which is exactly the contract-hygiene rule that prevents a published-but-unread header from re-accreting.

**Evidence** (`proxy.test.ts`, verbatim):
```ts
it("publishes no x-nonce header", () => {
  // The seam had no readers, and a header asserted in CI reads as live
  // plumbing. Reinstate both together, never the header alone.
  expect(forwardedRequestHeader(run(), "x-nonce")).toBeNull();
});
```

This is a contract *removal* done correctly: no asymmetry left behind (no reader stranded, no writer stranded), and the removal is pinned so it cannot silently regress.

### Change 3 — `config` typed as `ProxyConfig` — see CARRIED-2 (closed). Not Breaking, refinement only.

### Change 4 — matcher `missing:` clause removed — see CARRIED-1 (closed).

Behaviorally this *widens* CSP coverage (prefetch/`purpose: prefetch` requests now receive a nonce'd policy) — strictly safer, and not a consumer-contract break. Not Breaking.

### Change 5 — `exportGraph.ts` internal refactor (`toPng`+`fetch` → `toBlob`) — **Not Breaking, no public-surface change**

The public exports are unchanged in name and signature:

**Evidence** (`app/lib/utils/exportGraph.ts`, verbatim):
```ts
export async function downloadGraphAsPng(
  viewportElement: HTMLElement,
  filename = "proof-graph.png",
)
...
export async function graphToPngBlob(
  viewportElement: HTMLElement,
): Promise<Blob>
```
Both keep their prior parameter lists and return types; only the private rendering path changed (extracted into `renderGraphToBlob`). No caller-visible contract moved.

- **Error consistency:** the new failure mode throws a plain `Error("Failed to render graph to an image")`, matching the codebase's plain-`Error`-with-message convention (e.g., the export/parse utilities). The message substring is pinned by `exportGraph.test.ts` (`/Failed to render graph/`). Consistent; no bespoke error shape introduced.

### LOW / nit (NEW) — private helper name `renderGraphToBlob` vs public sibling `graphToPngBlob`

Within `exportGraph.ts` the new private helper is `renderGraphToBlob` while the public sibling that returns the same thing is `graphToPngBlob` — two different naming shapes (`render<Noun>To<Type>` vs `<noun>To<Type>`) for "graph → blob". This is a **private** symbol, so it is outside the public-name audit and does not count against the 0-Inconsistent bar; flagged only as a legibility nit.

- **Precedent line:** No clear precedent either way — the file's public convention is `<noun>To<Type>` (`graphToPngBlob`), so `graphToBlob` would have read more consistently than `renderGraphToBlob`. **No-precedent → would be −1 tier if it were a public name**; as a private helper it stays Low/nit.
- Non-blocking. No action required for merge.

---

## REQUIRED Name-Pattern Audit (new public names)

| New public name | Kind | Closest neighbor(s) | Precedent | Assessment |
|---|---|---|---|---|
| `buildCsp` | exported fn | `buildUserMessage`, `buildLine`, `buildPropositionIndex` | **Precedent** (verb-prefix `build*`, dominant `app/lib/` convention) | Consistent. No penalty. |
| `nodeEnv` (param) | param | `process.env.NODE_ENV` | **Precedent** (camelCase of the env var) | Consistent. |
| `proxy` | exported fn | Next 16 Proxy convention (framework-mandated) | Framework precedent | Required name; conformant. Test imports `{ proxy }` named. |
| `config` | exported const | `nextConfig` in `next.config.ts`; Next matcher-config convention | Framework precedent | Required name; now `ProxyConfig`-typed. |
| `app/lib/security/` (new module dir) | module path | `app/lib/analytics/`, `app/lib/formalization/`, `app/lib/stores/`, `app/lib/utils/` | **Precedent** (domain-named `app/lib/<domain>/` subdirs) | Consistent placement. |
| `renderGraphToBlob` | private fn | `graphToPngBlob` (public sibling) | **No-precedent** for the `render*` shape here | Private → out of public audit; Low/nit only (see above). |

No new HTTP endpoints, gRPC/GraphQL surfaces, SDK methods, CLI flags, event payloads, or config *fields* introduced in this range. The only consumer-facing config surface touched is the framework `matcher` (server-determined, hardened — CARRIED-1).

---

## What Looks Good

- **Contract removal done right.** The `x-nonce` deletion is the textbook case: writer and (absent) reader removed together, the absence pinned by a test, and a "reinstate both together" note left at both the writer site and the would-be reader site (`layout.tsx`). This is the opposite of the usual asymmetry hazard.
- **Purity-for-testability contract.** `buildCsp(nonce, nodeEnv)` lifting `NODE_ENV` to a required, undefaulted, deliberately-wide (`string | undefined`) parameter means the production branch is the tested branch, and fail-closed behavior is asserted across six environment values.
- **Both prior advisory findings closed and now guarded from the test side**, so they cannot silently regress: the matcher invariant and the `config` typing are both pinned.
- **Cross-file invariant guarded from both ends.** `csp.test.ts` fires if `connect-src` is widened to `data:`; `exportGraph.test.ts` fires if the export path narrows back to `toPng`+`fetch(dataUrl)`. The CSP↔export coupling is documented at both sites and enforced bidirectionally.
- **Public export signatures of `exportGraph.ts` preserved** through the internal refactor — no caller churn.

## Summary Table

| ID | Finding | Tier | NEW / CARRIED | Status |
|---|---|---|---|---|
| Change 1 | `buildCsp` requires `nodeEnv`; sole caller updated | Not Breaking | NEW | Clean |
| Change 2 | `x-nonce` request-header contract deleted; no readers | Not Breaking | NEW | Clean |
| Change 3 | `config` typed `ProxyConfig` | Not Breaking (refinement) | NEW | Clean |
| Change 4 | matcher `missing:` removed (widens coverage) | Not Breaking | NEW | Clean |
| Change 5 | `exportGraph` internal refactor; public exports unchanged | Not Breaking | NEW | Clean |
| LOW-1 | `renderGraphToBlob` vs `graphToPngBlob` name shape | Low / nit (private) | NEW | Advisory |
| CARRIED-1 | prefetch `missing:` matcher exclusion | (was Inconsistent) | CARRIED | **CLOSED** |
| CARRIED-2 | untyped `config` export | (was Inconsistent) | CARRIED | **CLOSED** |

**Breaking: 0. New Inconsistent: 0. New Low/nit: 1 (private, non-blocking). Prior findings: 2/2 closed.**

## Overall Assessment

The range meets the 0R + 0A merge standard on the API-consistency axis. Nothing Breaking exists: the two brief-flagged contract changes (`buildCsp` required-`nodeEnv`, `x-nonce` deletion) are both consumer-safe — the one `buildCsp` caller is updated in-commit, and `x-nonce` had zero readers. No new Inconsistent-tier finding; new public names all carry precedent (or are framework-mandated). Both prior advisory inconsistencies are verified closed and now regression-guarded. The single new nit is a private helper name and does not bear on merge.

## Goal-Alignment Note

The goal — Arm 1 verification pass, 0R + 0A standard, "confirm 0 Breaking and surface any NEW inconsistency from 1eb081e" — is met on the API-consistency dimension: **0 Breaking confirmed**, and no NEW Inconsistent-tier finding surfaced (one private-name Low/nit only). The prior full-2 api findings the brief asked to re-verify (prefetch matcher; untyped config) are both confirmed closed. This review covers the consumer-contract axis only; security/performance/architecture axes are out of scope for this critic and are handled by their respective passes.
