# Architecture Review — csp-clean (d86d2dc..4f018ab)

**Scope:** `git diff d86d2dc..4f018ab` — `proxy.ts` (new), `proxy.test.ts` (new), `app/layout.tsx`, `app/lib/utils/exportGraph.ts`
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3) at `/workspace/runs/review-arms/e1/csp-clean/code-fact-check-report.md` — its findings are taken as foundation and not re-verified
**Commit:** 4f018ab

Structural integrity only. Implementation quality (whether `style-src 'unsafe-inline'` is acceptable posture, whether the regex guards are correct) belongs to the security and test critics; this report asks whether the change leaves the module graph healthier or more entangled. A parallel `security-review.md` was not present at write time, so no boundary-label cross-references are made.

---

### Dependency Map

New and changed edges introduced by the range:

```
                    ┌─────────────────────────────────────────┐
   (framework edge) │ proxy.ts                                │
                    │   next/server → NextResponse            │
                    │   buildCsp(nonce) ── CSP policy string  │
                    │   proxy(request)  ── transport          │
                    │   config.matcher  ── scope              │
                    └────────┬───────────────────┬────────────┘
                             │                   │
              import buildCsp│                   │ (no import edge —
                             ▼                   │  runtime header only)
                    ┌─────────────────┐          ▼
                    │ proxy.test.ts   │   ┌───────────────────────┐
                    │ (jsdom env)     │   │ app/layout.tsx        │
                    └─────────────────┘   │  await headers()      │
                                          │  (result discarded)   │
                                          └───────────────────────┘

                    ┌─────────────────────────────────────────┐
                    │ app/lib/utils/exportGraph.ts            │
                    │   html-to-image → toBlob (was toPng)    │
                    │   renderGraphPng() ← new private helper │
                    │   downloadGraphAsPng / graphToPngBlob   │
                    └────────┬───────────────────┬────────────┘
                             │                   │
              GraphPanel.tsx │                   │ exportAll.ts
              (dynamic import)                   │ (static import)
```

Import-graph direction is clean. `proxy.ts` depends only on the framework (`next/server`) and on nothing inside `app/`; no application module imports `proxy.ts` at build time. `exportGraph.ts` keeps its existing two callers and its existing public signatures. **No new cycles are introduced, and no inward-pointing edge (framework edge → application internals) is created.**

The problems are all in the edges the import graph *doesn't* show. Three of the four changed files participate in one cross-cutting invariant — "every page response carries this exact CSP, and nothing in the app may do anything the CSP forbids" — and that invariant is represented nowhere as a declared contract. It lives in a string array inside a transport module, and it reaches its dependents through a runtime header (`layout.tsx`) and through a source comment (`exportGraph.ts`).

---

### Findings

#### A1. The CSP policy has no home outside the transport edge, so consumers couple to it by comment

**Severity:** Structural
**Location:** `proxy.ts:21-36`; `app/lib/utils/exportGraph.ts:6`
**Move:** Responsibility boundaries / dependency direction
**Confidence:** High
**Evidence:**

> ```
> export function buildCsp(nonce: string): string {
>   const directives = [
>     "default-src 'self'",
> ```
> — `proxy.ts:21-23`

> `// Use toBlob (not toPng + fetch) so we don't need `data:` in CSP connect-src.`
> — `app/lib/utils/exportGraph.ts:6`

**Legibility-target:** A contributor who adds a browser-side `fetch` to a third-party host, an inline `<script>`, or a CDN font six months from now.

`proxy.ts` currently holds two responsibilities that change for different reasons: *what the policy is* (a security decision, reviewed by security people, stable across deployments) and *how the policy is transported* (a Next.js integration detail that changes when the framework renames Middleware→Proxy, as it just did). Because the policy lives inside the transport module, no application module can depend on it — so `exportGraph.ts`, which genuinely is a policy consumer, expresses that dependency as a comment. The comment is the entire link: nothing type-checks it, no test connects the two files, and if `connect-src` later gains `data:` the comment becomes a lie with no signal. The same mechanism will repeat for every future consumer, and each will pay the cost independently, which is what makes this compounding rather than local.

**Recommendation:** Extract the policy to `app/lib/security/csp.ts` exporting `buildCsp` plus the directive constants; `proxy.ts` imports it and keeps only nonce generation, header setting, and `config.matcher`. That gives the policy a module consumers can import (e.g. `exportGraph` asserting in a test that `connect-src` lacks `data:`, rather than a comment), restores the project convention that logic lives under `app/lib/`, and separately resolves A3.

---

#### A2. `layout.tsx` depends on proxy behavior through a discarded side effect, and picks up a security responsibility it doesn't advertise

**Severity:** Structural
**Location:** `app/layout.tsx:26-32`
**Move:** Module boundary audit / interface segregation (SRP)
**Confidence:** High
**Evidence:**

> ```
>   // Opt this layout into dynamic rendering so Next.js injects the per-request
>   // nonce (set by proxy.ts) into its own bootstrap <script> tags during render.
>   // The proxy already runs per request via its matcher; the dynamic-rendering
>   // switch is what lets the rendered HTML pick up the nonce.
>   await headers();
> ```
> — `app/layout.tsx:26-32`

**Legibility-target:** A contributor doing a lint-driven or "dead code" cleanup pass on the layout, and the reviewer who approves it.

The nonce mechanism now requires two files to agree, with no artifact expressing the agreement: `proxy.ts` must set the request-side CSP header, and `layout.tsx` must force dynamic rendering. The second half is expressed as a statement whose return value is thrown away — syntactically indistinguishable from dead code, and exactly the shape an automated cleanup or a linter's no-unused-expressions rule targets. Deleting it does not fail a test, does not fail a type check, and does not fail the build; it silently reverts pages to static rendering and drops the nonce from the emitted HTML, at which point `'strict-dynamic'` blocks the app's own bootstrap scripts or the policy degrades to nothing enforceable. The comment is good and correct (the fact-check confirms the causal story matches the wiring at this commit), but a comment is the weakest possible binding for a two-file invariant. Secondarily, the layout's documented responsibility is "sets up fonts and metadata" (`CLAUDE.md:34`); it is now also the render-mode gate for a security control, and that widening is undocumented.

**Recommendation:** Make the coupling visible rather than incidental. Minimum: `export const dynamic = "force-dynamic";` (a declarative, named, greppable statement of the same intent) instead of a bare discarded `await`, with the existing comment retained. Better: have `layout.tsx` actually read the nonce from the extracted policy module's helper and pass it where it is needed, so the value is used rather than the call being ceremonial (see A5). Either way, record the layout's new responsibility in `CLAUDE.md`.

---

#### A3. `buildCsp` is exported for one consumer — a test that must drag the framework edge module into a jsdom environment

**Severity:** Coupling
**Location:** `proxy.ts:21`; `proxy.test.ts:2`; `vitest.config.ts` (`environment: 'jsdom'`)
**Move:** Interface segregation
**Confidence:** Medium — the pure-function part is certain; whether importing `next/server` under jsdom is merely wasteful or actually fragile cannot be settled offline (`node_modules` is absent in this worktree)
**Evidence:**

> `import { buildCsp } from "./proxy";`
> — `proxy.test.ts:2`

> `import { NextResponse } from "next/server";`
> — `proxy.ts:1`

**Legibility-target:** Whoever next has to debug a test-environment failure in this file, or extend the policy tests.

The module's public surface now serves two audiences with nothing in common: Next.js consumes `proxy` and `config` by filename convention, and the test suite consumes `buildCsp`. Widening a framework-entry module's exports purely for testability is the standard smell that a pure unit is trapped inside an impure module. The concrete cost lands on the test: to exercise a function that is nothing but string concatenation, it loads a module whose top-level import is the Next server runtime, inside a browser-simulating environment (`jsdom`) that has no business hosting it. That is a layering inversion in the test graph — the cheapest, most deterministic unit in the change has been given the heaviest, least deterministic import chain.

**Recommendation:** Same extraction as A1. Once `buildCsp` lives in `app/lib/security/csp.ts`, `proxy.test.ts` becomes `app/lib/security/csp.test.ts` importing a dependency-free module, `proxy.ts` drops back to the two exports the framework actually requires, and the test stops depending on `next/server` resolving under jsdom.

---

#### A4. `buildCsp` has no seam for environment or rollout variation, and the order-pinning test converts every variation into a two-file edit

**Severity:** Coupling
**Location:** `proxy.ts:21-36`; `proxy.test.ts:38-47`
**Move:** Extension points (pragmatic OCP)
**Confidence:** Medium — the shape of the constraint is certain from the code; the specific claim that dev-mode HMR needs `'unsafe-eval'` under Next 16 could not be executed offline
**Evidence:**

> ```
> export const buildCsp = (nonce: string): string => { … }   // signature: (nonce) => string
> ```
> — paraphrased from `proxy.ts:21`; the directive array is a hardcoded literal with no parameter other than `nonce`

> ```
>   it("emits the directive list in stable order", () => {
>     expect(directives.map(d => d.split(" ")[0])).toEqual([
> ```
> — `proxy.test.ts:38-40`

**Legibility-target:** The person who has to make this policy differ between dev and prod, or roll it out report-only first.

`buildCsp` is closed to the two variations a CSP most predictably needs. The first is environment: development builds commonly require `'unsafe-eval'` and a websocket `connect-src` for HMR, so if dev breaks under this policy the fix is to edit the shared literal — the one place where a dev-only relaxation could leak into production. The second is rollout: `Content-Security-Policy-Report-Only` with a `report-uri`/`report-to` directive is the normal way to introduce a strict policy without breaking users, and neither the function nor `proxy()` has anywhere to express it. The `toEqual` order pin makes both changes a synchronized two-file edit. That pin is deliberate and the intent is right — the comment says updating the test is the explicit acknowledgement — but `toEqual` on the full ordered list means any *addition* trips it, not just a weakening, so the guard's cost falls on safe changes as much as on unsafe ones.

**Recommendation:** Give the function one parameter for variation — `buildCsp({ nonce, mode })` or a directive-overrides map — and keep the exact-string pins for the high-risk directives while relaxing the order assertion to `toEqual(expect.arrayContaining(...))` plus a separate strict pin on the security-critical subset. This preserves the "weakening fails loudly" property while letting an additive change (a `report-to`, a dev-only source) pass without editing the guard.

---

#### A5. The `x-nonce` forwarding seam has zero consumers, and its comment names it as the delivery mechanism

**Severity:** Minor
**Location:** `proxy.ts:44-49`
**Move:** Extension points / coupling surface
**Confidence:** High (fact-check Claim 11: repo-wide grep matches `x-nonce` only at the write site; no `<Script>` receives a nonce anywhere)
**Evidence:**

> ```
>   // Forward the nonce to server components via a request header so layouts
>   // can read it via `headers()` and pass it to <Script> tags they render.
>   const requestHeaders = new Headers(request.headers);
>   requestHeaders.set("x-nonce", nonce);
> ```
> — `proxy.ts:44-49`

**Legibility-target:** The next contributor who adds a `<Script>` tag and needs a nonce for it.

This is an extension point built ahead of demand, and it survived the fix pass that corrected the surrounding comments. Architecturally the cost is not the header itself (one line, cheap) but the misdirection: the comment presents `x-nonce` as *the* path by which the nonce reaches rendered scripts, while the mechanism actually in play is the request-side `Content-Security-Policy` header set on the very next line. A reader tracing the design follows the documented wire, finds nothing consuming it, and has to reconstruct the real path themselves — precisely the reader A2 also burdens. It also creates a false impression of a supported contract: `x-nonce` looks like a stable interface future code may bind to, but nothing tests it, so it can be renamed or dropped without any failure.

**Recommendation:** Either close the loop — have `layout.tsx` read `x-nonce` and use it, which would simultaneously make A2's `await headers()` a real read rather than a discarded side effect — or delete the line and rewrite the comment to name the request-side CSP header as the delivery mechanism. Keeping an undocumented-as-unused seam is the one option that costs without paying.

---

#### A6. The policy invariant is structurally enforced for only part of the policy

**Severity:** Minor
**Location:** `proxy.test.ts:14-31`
**Move:** Extension points / responsibility boundaries
**Confidence:** High (taken as foundation from fact-check Claim 4, verdict Incorrect, found independently by all three replicates; not re-verified here)
**Evidence:**

> ```
>   it("does not allow eval, wildcards, or http: schemes anywhere", () => {
>     expect(csp).not.toMatch(/'unsafe-eval'/);
>     expect(csp).not.toMatch(/\*\s/); // wildcard source not followed by directive end
>     expect(csp).not.toMatch(/\bhttp:\b/);
>   });
> ```
> — `proxy.test.ts:27-31`

**Legibility-target:** A reviewer deciding how much to trust the test suite when approving a change to `buildCsp`.

Noting this for the architecture record rather than re-litigating it: this test file is the *only* structural enforcement of the cross-cutting invariant A1 describes, so the gap between its stated and actual contract determines how much load the rest of the design can put on it. Six of the ten directives are pinned by exact string; `style-src`, `img-src`, and `font-src` are pinned by nothing, and the two catch-all guards intended to cover them are vacuous per the fact-check. The architectural consequence is that the "policy is guarded, so it is safe to depend on" premise — which A1's recommendation and A4's order-pin both lean on — currently holds for six directives and not for three.

**Recommendation:** Close per the fact-check's suggested fix (`not.toMatch(/\bhttp:/)` and `/(^|\s)\*(;|\s|$)/`), or better, add exact-string pins for `style-src`/`img-src`/`font-src` so all ten directives are guarded uniformly and the catch-all regexes become belt-and-braces rather than the sole cover. Detailed handling belongs to the test-strategy and security critics.

---

#### A7. CSP is scoped to page navigations, so the "global policy" is global only over one edge

**Severity:** Informational
**Location:** `proxy.ts:59-72`
**Move:** Module boundary audit
**Confidence:** High
**Evidence:**

> ```
>   // Apply CSP to page navigations only. Skip API routes (they don't render
>   // HTML), Next's static assets (no scripts to nonce), and prefetches (which
>   // would otherwise burn a nonce on a request that may never paint).
>   matcher: [
>     {
>       source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
> ```
> — `proxy.ts:59-65`

**Legibility-target:** Anyone reasoning about which responses are covered by the policy.

The exclusions are well-reasoned and the comment states the reasoning, which is more than most matchers do. Recording it as a boundary fact rather than a defect: the invariant this change establishes is "every *page navigation* response carries the CSP," not "every response." Anything under `/api` that ever returns a browser-rendered surface — an HTML error page, a redirect target, a future SSR'd route colocated under `api` — sits outside the boundary with no signal that it has left it. That is an acceptable trade at this size; it is worth knowing that the boundary is path-shaped and enforced by a regex, so the boundary moves whenever routes move.

**Recommendation:** No change. If an API route ever returns HTML, revisit the matcher rather than adding a second policy site.

---

#### A8. `proxy.ts` is a new top-level runtime module absent from the documented directory layout

**Severity:** Informational
**Location:** `proxy.ts` (repo root); `CLAUDE.md:31-53`
**Move:** Module boundary audit
**Confidence:** High
**Evidence:**

> `### Directory Layout (under \`app/\`)`
> — `CLAUDE.md:31`

**Legibility-target:** A newcomer orienting from `CLAUDE.md`.

The placement itself is framework-mandated — Next.js resolves the proxy/middleware entry point by filename at the project root, so there is no alternative location and no finding against it. What is worth recording is that until this change all request-handling logic lived under `app/`, and the documented architecture is written entirely in terms of "under `app/`". There is now a second runtime module outside that boundary (alongside `next.config.ts`), and the docs do not mention it. Note that A1's extraction would restore most of the invariant: only the thin transport shim would remain at root, with the policy back under `app/lib/`.

**Recommendation:** Add `proxy.ts` to the `CLAUDE.md` architecture section as a root-level entry point with a one-line note on why it cannot live under `app/`.

---

### What Looks Good

- **Dependency direction is correct at the edge.** `proxy.ts` imports only `next/server` and nothing from `app/`. The framework edge does not reach inward, and no application module imports the proxy — the one architectural mistake that would have been genuinely expensive here was avoided.
- **No cycles, and no change to the `exportGraph` public contract.** `downloadGraphAsPng` and `graphToPngBlob` keep their signatures (`graphToPngBlob` drops `async` but still returns `Promise<Blob>`, so both call sites — `GraphPanel.tsx:104` and `exportAll.ts:64` — are unaffected). Substitutability preserved.
- **`renderGraphPng` is a well-judged extraction.** Two call sites had drifted into duplicated `toPng` + `fetch` + `blob()` chains; the new private helper collapses them to one, so the next policy-driven change to rendering has exactly one place to land. This is the change in the range that most improves future modifiability.
- **The directive-pinning test is the right *kind* of control.** Whatever its coverage gaps (A6), the design intent — make weakening a cross-cutting security control fail loudly, and make updating the test the explicit acknowledgement — is the correct structural response to "this policy is enforced nowhere else." The comment stating that intent is exemplary.
- **Rationale is recorded at the decision site.** The `style-src 'unsafe-inline'` carve-out, the `form-action` CSP3 non-fallback, the matcher exclusions, and the `toBlob` switch each carry a comment explaining *why*, not *what*. This is the main reason the module's boundaries were legible enough to review offline.

---

### Summary Table

| ID | Finding | Severity | Move | Location | Confidence |
|----|---------|----------|------|----------|------------|
| A1 | CSP policy has no home outside the transport edge; consumers couple by comment | Structural | Responsibility boundaries | `proxy.ts:21-36`, `exportGraph.ts:6` | High |
| A2 | `layout.tsx` depends on proxy behavior via a discarded side effect; undocumented responsibility | Structural | Module boundary / SRP | `app/layout.tsx:26-32` | High |
| A3 | `buildCsp` exported only for a test that must load `next/server` under jsdom | Coupling | Interface segregation | `proxy.ts:21`, `proxy.test.ts:2` | Medium |
| A4 | No seam for environment or report-only variation; order pin makes changes two-file | Coupling | Extension points | `proxy.ts:21-36`, `proxy.test.ts:38-47` | Medium |
| A5 | `x-nonce` seam has zero consumers; comment names the wrong delivery wire | Minor | Extension points | `proxy.ts:44-49` | High |
| A6 | Policy invariant structurally enforced for 6 of 10 directives | Minor | Extension points | `proxy.test.ts:14-31` | High |
| A7 | CSP scoped to page navigations; boundary is path-regex-shaped | Informational | Module boundary | `proxy.ts:59-72` | High |
| A8 | New root-level runtime module absent from documented layout | Informational | Module boundary | `proxy.ts`, `CLAUDE.md:31` | High |

---

### Overall Assessment

The change introduces a cross-cutting concern competently at the transport layer and gets the hard part right: the framework edge stays outside the application, no cycles appear, and the one consumer that had to adapt (`exportGraph`) came out of it with less duplication than it started with. The review-fix pass that produced 4f018ab visibly improved the structure — exporting `buildCsp`, adding directive pins, and correcting the layout comment all moved in the right direction.

What remains is a single structural theme with several faces. The CSP is a global invariant with no global representation: it exists as a literal inside a transport module, and every dependency on it is expressed through a channel the compiler cannot see — a comment in `exportGraph.ts` (A1), a discarded `await` in `layout.tsx` (A2), a test-only export (A3), an unused header (A5). Each is individually cheap; together they mean the policy's blast radius is knowable only by reading four files and trusting their comments. The single highest-leverage move is A1's extraction of `app/lib/security/csp.ts`, which directly resolves A3, enables the A4 seam, restores the "logic lives under `app/`" convention noted in A8, and gives A1's consumers something importable to assert against.

None of this is blocking for a measurement run, and none of it is the kind of debt that gets more expensive quietly — it gets more expensive the moment a *second* consumer needs to know the policy, which A1 predicts will happen and will be paid for the same way the first time. Fix A1/A2 before that second consumer arrives.

---

## Goal-Alignment Note

- **Answered:** All eight structural-integrity moves for the range — dependency direction (map, A1), responsibility boundaries (A1, A2), module boundary audit (A2, A7, A8), layer violations (A3's test-env inversion; none found in the import graph), interface segregation (A2, A3), substitutability (`exportGraph` signatures preserved — no defect), coupling surface / cycles (map: none introduced), extension points (A4, A5, A6). Also assessed the four items the brief flagged: the `buildCsp` export-and-test shape (A3, A4, A6), the dead `x-nonce` seam (A5), the `layout.tsx`↔proxy coupling (A2), and the policy→consumer coupling shape in `exportGraph` (A1).
- **Out of scope:** Whether `style-src 'unsafe-inline'` is acceptable posture and whether the vacuous regexes are exploitable (security critic); whether `'strict-dynamic'` breaks the pdf.js worker load, flagged by the fact-check as a functional risk (security/functional critic); correctness of the regex fixes (test-strategy); runtime verification of nonce injection — no `node_modules` in this worktree, nothing was executed; anything outside `d86d2dc..4f018ab`.
- **Escalate:** (1) A2 is the one finding where a plausible, well-intentioned future edit — deleting a statement that looks like dead code — silently disables a security control with no test, type, lint, or build failure; it deserves a guard regardless of whether the rest of this report is actioned. (2) A6 inherits the fact-check's Incorrect verdict unmodified: because `proxy.test.ts` is the *only* structural enforcement of the policy, its partial coverage limits how much any other structural recommendation here can lean on it. (3) Per fact-check escalation (2), runtime verification of the nonce path has not been performed at 4f018ab; this review's dependency map for the `layout.tsx`↔proxy edge takes the fact-check's reading of the mechanism as given and could not confirm it by execution.
