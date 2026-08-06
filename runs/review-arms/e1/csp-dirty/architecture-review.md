# Architecture Review — csp-dirty (d86d2dc..d90d6bb)

**Scope:** `git diff d86d2dc..d90d6bb` in the pinned worktree /workspace/runs/review-arms/e1/wt-csp-dirty (detached at d90d6bb) — new top-level `proxy.ts` (64 lines) and `app/layout.tsx` made async. Structural integrity only: dependency direction, responsibility boundaries, module surface, coupling, extension points. Correctness of the CSP mechanism and its exploitability belong to code-fact-check and security respectively and are treated here only where they are symptoms of a structural cause.
**Date:** 2026-08-06
**Based on:** merged code fact-check (`/workspace/runs/review-arms/e1/csp-dirty/code-fact-check-report.md`, k=3) — its findings are the foundation and are not re-verified here.
**Commit:** d90d6bb

*Sibling security review:* `/workspace/runs/review-arms/e1/csp-dirty/security-review.md` was absent at the time of writing, so no boundary labels are cross-referenced. Findings C2 and S2 are the ones that would coincide with a trust boundary if that review lands.

### Dependency Map

**New module graph edges (import-level):**

```
proxy.ts ──────► next/server  (NextResponse, type NextRequest)   [stable, framework]
app/layout.tsx ─► next/headers (headers)                          [stable, framework]
                └► next, next/font/google, ./globals.css, katex   [pre-existing]
```

- `proxy.ts` imports **nothing from `app/`**. It sits at the repo root because Next 16 requires that location for the Proxy (ex-Middleware) entry point. Its only dependencies are framework types and one framework value — maximally stable, correctly directed. There is no cycle anywhere in the added graph.
- Nothing in `app/` imports `proxy.ts`. There is no import edge in either direction.

**Runtime (non-import) edges — the part the module graph cannot express:**

```
app/layout.tsx ──[side effect: await headers() forces dynamic render]──► proxy.ts executes per request
proxy.ts ──[HTTP header "x-nonce" on the forwarded request]──► (no consumer)
proxy.ts ──[Content-Security-Policy response header]──► every page-rendered module in app/
                                                        (exportGraph.ts, GraphPanel, LatexRenderer, reactflow, …)
```

The third edge is the architecturally significant one: a single 64-line root module imposes a runtime contract on every module reachable from a page render, with no compile-time, test-time, or lint-time representation of that contract anywhere. The first edge is the second-most significant: the root layout has acquired a behavioral dependency on an infrastructure module it never names in an import.

Layer placement is otherwise sound. `proxy.ts` is infrastructure/edge; `app/layout.tsx` is the document shell; `app/lib/*` is domain; `app/api/*` is transport. Nothing in this diff inverts that stack or reaches across it via imports.

### Findings

#### S1 — The root layout carries a global rendering-mode switch that exists only to make another module run, via a side effect with no local evidence

**Severity:** Structural
**Location:** `app/layout.tsx:26-32`
**Move:** Responsibility boundaries / hidden coupling
**Confidence:** High (structure); the mechanism's efficacy is Claim 1's business, and it is graded Mostly accurate there.

**Evidence:**
```tsx
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
  await headers();
```

**Legibility-target:** for-author

The root layout is the document shell — fonts, `<html>`/`<body>`, metadata. It now also decides the rendering mode of the entire application, and it does so through a call whose return value is discarded. Every static signal available to a future maintainer says this line is dead: no binding, no usage, an `await` on a value nobody wants, in a file whose other 30 lines are pure presentation. The only thing preventing its deletion is a four-line comment, and that comment's second half is graded Incorrect by the fact-check (Claim 2) — so a maintainer who checks the comment against reality finds it wrong and is *more* likely to remove the line, not less. This is a responsibility misplacement compounded by an undocumented mechanism dependency: `layout.tsx` depends on `proxy.ts`'s per-request execution, `proxy.ts` is never mentioned in any import, and the dependency is enforced by nothing.

**Recommendation:** Make the dependency legible rather than incidental. The cheapest version: consume the value (`const h = await headers()`) and derive something real from it, or replace the bare call with `export const dynamic = "force-dynamic"` — a named, greppable, framework-recognised declaration of the same intent that no one will mistake for dead code. Pair either with a comment that survives contact with Claim 2, and add `proxy.ts` to the sentence so a `rg proxy` from the layout finds the counterpart. Longer term, if per-request rendering is a requirement of the security control rather than of the UI, the declaration belongs next to the control (or in a documented decision record), not buried in the shell.

#### S2 — A cross-cutting security control ships with its policy private, its delivery contract unexpressed, and zero tests

**Severity:** Structural
**Location:** `proxy.ts:19-32` (`buildCsp`, not exported), `proxy.ts:34-49` (`proxy`); `vitest.config.ts` (no `proxy` test exists anywhere)
**Move:** Module boundary audit / interface segregation
**Confidence:** High

**Evidence:**
```ts
function buildCsp(nonce: string): string {
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```

**Legibility-target:** for-author

`buildCsp` is the one genuinely pure, trivially testable thing in the module — string in, string out, no framework contact — and it is module-private, so the policy that governs every page in the app can be asserted from nowhere. The module's entire public surface is the two symbols the framework demands (`proxy`, `config`); that is admirably minimal for a framework entry point, but it means the *policy* and the *transport* share one visibility scope, and the policy inherits the transport's untestability. The consequence is visible in this very range: the nonce-delivery wiring is mis-built (fact-check Claims 2 and 12, both Incorrect), the commit message asserts it was verified, and nothing in the repository could have contradicted that assertion. A control whose contract cannot be stated cannot be regression-protected — the next Next.js upgrade, the next directive added, the next matcher tweak all ship on the same evidence base this one did.

**Recommendation:** Export `buildCsp` (or move the directive list to a `csp.ts` sibling that `proxy.ts` imports) and add `proxy.test.ts` at the root — vitest's default include glob already picks up root-level `*.test.ts`, so no config change is needed. Assert the directive set, and assert the nonce actually appears where the design says it must. The second assertion is the one that matters: it is precisely the check that would have caught Claim 2, and writing it forces the delivery contract to be named.

#### C1 — The `x-nonce` forwarding seam is an extension point with zero consumers, and its contract is a bare string

**Severity:** Coupling
**Location:** `proxy.ts:39-45`
**Move:** Extension points (OCP) / coupling surface
**Confidence:** High (fact-check foundation: the seam has zero consumers)

**Evidence:**
```ts
  // Forward the nonce to server components via a request header so layouts
  // can read it via `headers()` and pass it to <Script> tags they render.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
```

**Legibility-target:** for-author

This is a deliberately designed extension point that nothing extends — no file in the repo reads `x-nonce`, and no `<Script>` tag exists in `app/` for it to serve. Speculative generality is cheap here (four lines), but it is not free: it costs the reader confidence, because the comment describes a working data path and the layout's comment three files away explicitly says the opposite ("so we don't need to read x-nonce here ourselves"). Two comments in a 72-line diff disagree about whether the seam is live. Worse, the contract when a consumer eventually arrives is a magic string in two places — content coupling by literal, the weakest form, with no shared constant and no type.

**Recommendation:** Either delete the forwarding (and the comment) until a consumer exists, or land the consumer in the same change. If it stays, export the header name as a constant from the module that owns it (`export const NONCE_HEADER = "x-nonce"`) so the eventual consumer binds to a symbol rather than to a string, and reconcile the two comments so they describe one story.

#### C2 — A global policy silently constrains distant modules, with violations detectable only in a browser

**Severity:** Coupling
**Location:** `proxy.ts:19-32` (directives) vs. `app/lib/utils/exportGraph.ts:24,37`; `app/components/features/output-editing/LatexRenderer.tsx`; reactflow-driven inline styles across ~20 files under `app/`
**Move:** Coupling surface (global/common coupling) / layer awareness
**Confidence:** High for the structure; the specific `connect-src` breakage is fact-check Claim 6 (Incorrect) and its exploitability/impact is security's call.

**Evidence:**
```ts
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
    "connect-src 'self'",
```

**Legibility-target:** for-orchestrator-synthesis

Every directive here is a constraint on modules that have no idea it exists. `exportGraph.ts:24` calls `fetch(dataUrl)` — legal TypeScript, passing tests, blocked by `connect-src 'self'`. The `'unsafe-inline'` carve-out in `style-src` is load-bearing for reactflow and KaTeX, but the comment attributes it to Tailwind (fact-check Claim 5, Incorrect), so the *reason* the carve-out cannot be removed is documented incorrectly — the next person to tighten it will remove it, break node positioning, and not know why. This is classic common coupling: one shared mutable policy, many uninformed dependents, failures that surface far from the change and only at runtime in a real browser. The policy is not wrong to be global — CSP has to be — but a global policy needs a compensating mechanism, and there is none.

**Recommendation:** Annotate each directive with the concrete dependent that constrains it (`connect-src 'self'` → "note: exportGraph.ts fetches data: URLs"; `style-src 'unsafe-inline'` → reactflow + KaTeX + React `style={}`, per the fact-check's enumeration, not Tailwind). That converts invisible coupling into a grep-able one. Then close the loop with the S2 test: a directive test that lists the known dependents makes the next tightening a red test instead of a browser bug report.

#### M1 — The matcher regex duplicates knowledge of the route layout as an untyped string

**Severity:** Minor
**Location:** `proxy.ts:50-63`
**Move:** Coupling surface (stamp coupling on directory naming)
**Confidence:** High

**Evidence:**
```ts
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```

**Legibility-target:** for-author

The exclusion list encodes the app's directory layout — `app/api/*` exists, and its exclusion is correct today across all 17 route handlers. But the knowledge lives in a regex the compiler cannot check: rename or nest the API root and this silently starts applying a page CSP to JSON responses, or stops applying it to pages. The blast radius is small and the failure is loud-ish, which is why this is Minor rather than Coupling, but it is a second place (after `next.config.ts`) where routing structure is asserted.

**Recommendation:** No change required now. If `app/api` ever moves, this line is on the checklist — a one-line comment naming that fact is enough.

#### M2 — `Buffer` ties an Edge-runtime module to a Node-compat global where a Web-standard equivalent exists

**Severity:** Minor
**Location:** `proxy.ts:35-37`
**Move:** Substitutability (runtime portability)
**Confidence:** Medium (fact-check Claim 7 grades the accompanying comment Stale)

**Evidence:**
```ts
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

**Legibility-target:** for-author

The proxy runs in whichever runtime Next assigns it, and the module reaches for a Node global to do base64 when `btoa` is the portable spelling. The comment asserting both are available in the Edge runtime is graded Stale by the fact-check. Structurally the point is narrow: an infrastructure module at the framework boundary should depend on the smallest, most stable substrate available, so that a runtime switch (Edge → Node, or a future Next default flip) is a non-event.

**Recommendation:** `btoa(crypto.randomUUID())` — same output, no Node dependency, and it drops a stale claim from the comment block.

#### I1 — Two potential homes for response headers now exist

**Severity:** Informational
**Location:** `proxy.ts:47`; `next.config.ts` (currently empty: `const nextConfig: NextConfig = {};`)
**Move:** Responsibility boundaries
**Confidence:** High

**Evidence:**
```ts
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```

**Legibility-target:** for-orchestrator-synthesis

Next supports static security headers via `next.config.ts`'s `headers()`. This change correctly chose the proxy — per-request nonces cannot be static — but the repo now has an empty `next.config.ts` that is the natural-looking home for the *next* header someone adds (HSTS, Referrer-Policy, X-Content-Type-Options). Split across two files, the set of response headers becomes something you have to know to look for in two places.

**Recommendation:** When the next header lands, put it in the proxy alongside CSP, or leave a pointer comment in `next.config.ts`. Not actionable in this range.

#### I2 — An app-wide security control's only design record is a comment block

**Severity:** Informational
**Location:** `proxy.ts:4-18`; no entry under `docs/decisions/`
**Move:** Extension points / traceability
**Confidence:** High

**Evidence:**
```ts
 * Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening
 * to nonces would require rebuilding how Tailwind ships styles in dev and
 * SSR. Documented as a deliberate carve-out, not an oversight.
```

**Legibility-target:** for-orchestrator-synthesis

The instinct to document the carve-out is right, and the header comment is the best thing in the diff. But a control that binds every page, forces a global rendering-mode change, and constrains a dozen unrelated modules is a decision-record-sized decision, and the record it got is a comment that the fact-check grades Incorrect in two of its three "why" paragraphs (Claims 2 and 5). Comments in the enforcing module are the right place for *what*; the *why*, the rejected alternatives, and the list of constrained dependents outlive the file.

**Recommendation:** Add `docs/decisions/NNN-strict-csp-nonces.md` capturing: why proxy over `next.config.ts` headers, why `'strict-dynamic'`, what actually forces `'unsafe-inline'` in `style-src` (per fact-check Claim 5, not Tailwind), and the dynamic-rendering cost the layout change imposes.

### What Looks Good

- **Dependency direction is clean and correctly inverted.** `proxy.ts` imports only `next/server`. It knows nothing about `app/`, `app/lib/`, or any domain type — the infrastructure module depends on the framework, and the application does not depend on the infrastructure module at the import level. No cycle is introduced.
- **`buildCsp` is already extracted as a pure function.** The seam that makes S2's fix a one-word change (`export`) is already cut. Someone was thinking about separation of policy from transport; they just stopped one keyword short.
- **The public surface is exactly the framework's contract.** Two exports, both required by Next (`proxy`, `config`), nothing else leaked. For a root-level entry point this is the right minimum.
- **The matcher is scoped deliberately and its reasoning is stated.** Excluding API routes, static assets, and prefetches is the correct scoping for a page-level CSP, and the fact-check graded that comment Verified (Claim 9). Cross-cutting concerns that document *what they do not cross* are rarer than they should be.
- **The layout change is one line.** Whatever S1 says about its legibility, the author resisted the temptation to thread nonce plumbing through the component tree — the blast radius in `app/` is a single `await`.
- **The commit sequence shows self-correction.** b25e939 exists purely to fix a stale `middleware.ts` reference after the rename, and d90d6bb is a behavior-preserving cleanup (fact-check Claims 13 and 14). The instinct to keep comments true to the code is present, even where the outcome missed.

### Summary Table

| ID | Finding | Severity | Location | Confidence |
|----|---------|----------|----------|------------|
| S1 | Root layout carries a global rendering-mode switch via a discarded side effect, coupled to `proxy.ts` with no import and no test | Structural | `app/layout.tsx:26-32` | High |
| S2 | Cross-cutting security control has private policy, unexpressed delivery contract, zero tests | Structural | `proxy.ts:19-49` | High |
| C1 | `x-nonce` forwarding seam has zero consumers; contract is a bare string, and two comments disagree about whether it is live | Coupling | `proxy.ts:39-45` | High |
| C2 | Global policy silently constrains distant modules (`exportGraph.ts`, reactflow, KaTeX); violations surface only in-browser | Coupling | `proxy.ts:19-32` | High |
| M1 | Matcher regex duplicates route-layout knowledge as an untyped string | Minor | `proxy.ts:50-63` | High |
| M2 | `Buffer` couples an Edge-runtime module to a Node global where `btoa` suffices | Minor | `proxy.ts:35-37` | Medium |
| I1 | Two potential homes for response headers (`proxy.ts` vs empty `next.config.ts`) | Informational | `proxy.ts:47`, `next.config.ts` | High |
| I2 | App-wide control's only design record is a comment block, two-thirds of which is graded Incorrect | Informational | `proxy.ts:4-18` | High |

### Overall Assessment

Structurally, the *placement* of this change is right and the *binding* of it is wrong. `proxy.ts` sits where a framework-level cross-cutting concern belongs, imports nothing it shouldn't, exports nothing it needn't, and introduces no cycle — as a module, it is well-behaved. The problem is entirely in the edges that don't appear in the module graph: a root layout that depends on the proxy through a discarded side effect (S1), a delivery contract that exists in comments and nowhere in code (S2), an extension point with no extenders (C1), and a policy that constrains a dozen modules that cannot see it (C2). Those four are one shape viewed from four sides — the coupling this feature genuinely requires is real and unavoidable, but none of it has been made legible to the compiler, the test suite, or the next reader.

That shape has already cost something concrete. The fact-check's two load-bearing Incorrect findings (Claims 2 and 12 — the nonce never reaches a script tag, and the commit asserts otherwise) are not independent mistakes; they are what S2 predicts. When a cross-cutting control's contract is stated in prose only, a wrong belief about the mechanism cannot be falsified by anything in the repository, so it ships. The fix that matters most is also the cheapest: export `buildCsp`, add a root-level `proxy.test.ts`, and assert that the nonce lands where the design says it lands. That single test converts the highest-value structural gap into a red-green signal and would have caught the mis-wiring before it merged. S1's fix (`export const dynamic = "force-dynamic"`, or consume the headers value) is a two-line change with an outsized legibility return, and C1 resolves by deleting four lines or landing a consumer. Nothing here calls for restructuring — the bones are fine, they just need to be visible.

## Goal-Alignment Note

- **Answered:** Dependency direction and layer placement for the new top-level `proxy.ts` (clean, framework-only, no cycles); the responsibility boundary between the document shell and the security control (misplaced rendering-mode switch, S1); the module's public surface and what is wrongly private (S2); the coupling surface of an app-wide policy over uninformed dependents (C2); the unused designed extension point (C1); substitutability and route-knowledge duplication at the framework boundary (M1, M2); traceability of the decision (I1, I2). All severities reported down to Informational per the measurement-run instruction; no fix loop was run.
- **Out of scope:** Whether the CSP actually blocks XSS, whether `connect-src 'self'` constitutes a vulnerability or merely a functional break, and the exploitability of any nonce weakness — security's, and deferred to `security-review.md` (absent at time of writing; the cross-reference of boundary labels for S2/C2 was a no-op). The *correctness* of the nonce-delivery mechanism is code-fact-check's (Claims 2, 12) and is taken as foundation, not re-derived; only its structural cause is treated here. Performance of the forced-dynamic rendering switch, API-surface consistency, and test coverage strategy beyond the one contract test named in S2 belong to their own critics.
- **Escalate:** S1 and S2 together mean a security-relevant control can be silently disabled by a plausible cleanup commit (`await headers()` reads as dead code) with no test to catch it — worth flagging to the orchestrator as a cross-critic item, since the structural gap and the security consequence are the same defect seen from two angles. Also worth surfacing: the `style-src 'unsafe-inline'` rationale is misattributed to Tailwind (fact-check Claim 5), which means the *correct* reason the carve-out cannot be removed is recorded nowhere — a future tightening will break reactflow node positioning and the trail will be cold.
