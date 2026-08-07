# Architecture Review — e3/csp-arm1 (strict CSP + per-request nonces)

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-csp-arm1` (branch `e3/csp-arm1`) — `proxy.ts` (new, 53), `proxy.test.ts` (new, 86), `app/lib/security/csp.ts` (new, 58), `app/lib/security/csp.test.ts` (new, 73), `app/layout.tsx` (+20), `app/lib/utils/exportGraph.ts` (+24/−13)
**Commit:** f25d968
**Date:** 2026-08-06
**Based on:** `code-fact-check-report.md` (merged, k=3) in this directory — treated as foundation; behavioral claims not re-verified.
**Trust-boundary cross-reference:** `security-review.md` in this directory defines B1 (browser-supplied request headers → proxy → renderer), B2 (proxy-minted nonce → `buildCsp` policy → browser CSP engine), B3 (`NODE_ENV` → `buildCsp(nodeEnv)` → `'unsafe-eval'` present or absent), B4 (graph DOM subtree → `toBlob` → downloaded file; the boundary this diff *removes* by no longer crossing `connect-src`). Findings below carry the corresponding label. Three findings have direct correlates in that review, arrived at independently from different lenses — C3/`x-nonce` (its Informational, `proxy.ts:27-31`, B1), M1/OpenAlex enumeration (its Informational, `csp.ts:20-24`, B2), and M2/header ownership (its Informational "CSP is the only security header set", B1+B2). The convergence is worth noting: where a security lens sees an unlabelled input and an architecture lens sees an unowned boundary, they are describing one defect.
**Prior iteration:** `../full-1/architecture-review.md` treated as advisory. Its two Structural findings (A1 nonce-delivery contract, A2 module-private untestable policy) are assessed for closure below.

## Headline

**Nothing Structural remains in this diff.** Both of full-1's Structural findings are genuinely closed — not papered over — and the extraction that closed A2 is placed and directed correctly. The residue is four coupling/minor items and four informational notes.

## Dependency Map

The diff now adds two modules and one new import edge, where full-1 had one module and zero import edges.

- **`app/lib/security/csp.ts` (new).** Pure, dependency-free: no imports at all, one exported function `buildCsp(nonce, nodeEnv?) → string`. Colocated `csp.test.ts`. This is a leaf in every sense — nothing it depends on can break it.
- **`proxy.ts` (repo root, new).** Framework entry point; Next 16 discovers it by filename. Depends on `next/server` and, newly, on `@/app/lib/security/csp`. Exports `proxy` and `config`. Colocated `proxy.test.ts` — which is now possible precisely because `proxy()` is a plain exported function over `NextRequest`.
- **Edge direction: `proxy.ts` → `app/lib/security/csp.ts`.** Entry point depends on logic; logic depends on nothing. That is the correct direction, and it matches the repo's existing shape — `app/api/**/route.ts` handlers delegate to `app/lib/llm/*` rather than inlining. The root-level file is now an adapter (38 lines, zero policy), which is the precedent full-1's A8 asked for.
- **`app/layout.tsx`.** Unchanged in structure: still depends on `proxy.ts`'s *runtime behavior* (not its module) via `await headers()`, with no compile-time representation. Waived per brief; see I3.
- **`app/lib/utils/exportGraph.ts`.** No new import edge, but a new *invariant* edge: its implementation choice (`toBlob` rather than `toPng` + `fetch(dataUrl)`) is forced by `connect-src 'self'` in `csp.ts`. Two modules in different subtrees, coupled by a runtime policy, joined only by prose. See C1.
- **Layering.** `app/lib/security/` slots into the established `app/lib/<domain>/` convention (7 sibling domains, colocated `*.test.ts`). No inversion anywhere: nothing stable was made to depend on anything volatile, and no application module was made to depend on the proxy.

## Full-1 Structural findings — closure assessment

**A1 (nonce delivery contract exists only in prose, split across three unlinked write sites): closed.** The policy is now computed once into a local (`const csp = buildCsp(nonce)`) and written to both channels from adjacent lines in one function, and — the part that matters architecturally — the contract is now *falsifiable*. `proxy.test.ts`'s first test asserts the CSP lands on the forwarded request headers with a nonce in `script-src`, and the merged fact-check (Cluster 17) confirms by assertion tracing that deleting `requestHeaders.set("Content-Security-Policy", csp)` fails exactly two of the five tests. The comment in `layout.tsx` that previously contradicted the mechanism now agrees with it. The contract moved from "a belief recorded in three places" to "one call site plus a test that fails when it breaks." That is a real close, not a documentation patch.

**A2 (the one testable unit of a cross-cutting security control is module-private in an untestable file): closed, and the placement is sound.** `buildCsp` is exported from `app/lib/security/csp.ts` with six tests covering directive inventory, nonce interpolation, the dev/prod branch, fail-closed behavior on six unexpected environment strings, the dev-vs-prod delta, and a `connect-src` regression guard. `proxy.ts` retains no policy. Two specific things make this better than a mechanical file-move:

1. The `nodeEnv` parameter (full-1's A3) was added in the same change, so the production branch is observable from a test process without mutating globals — the test *"allows `'unsafe-eval'` in development only"* asserts both directions, which was impossible before.
2. The fail-closed property full-1 praised in prose is now pinned by a test that enumerates `undefined`, `""`, `"Development"`, `"dev"`, `"test"`, `"prod"`. That converts a good decision into a maintained one.

Placement is the right call: `app/lib/<domain>/` with a colocated test is this repo's only convention for logic, `@/*` resolves from the repo root so the import works from a root-level file, and `csp.ts` has no imports, so nothing about `app/**` gets dragged into the proxy's module graph. The one honest caveat is that nothing inside `app/**` imports it — see I1, which is a note rather than an objection.

The residual C2 below is the *unclosed remainder* of A3, not of A2: making the environment a parameter made the policy testable, which was A2's whole point, but it did not remove the ambient read from the production path.

## Findings

#### The CSP↔export-path invariant is guarded in one direction only, and the guarded module has no tests at all

**Severity:** Coupling
**Location:** `app/lib/utils/exportGraph.ts:16-33`, `app/lib/security/csp.test.ts:66-72`, `app/lib/security/csp.ts:20-24`
**Boundary:** B4 (the `connect-src` crossing this diff removes — reintroducing `fetch(dataUrl)` restores it)
**Move:** #7 (coupling surface), #3 (module boundary audit)
**Confidence:** High

**Move:** Put the guard on the side that can actually regress — the export path — rather than only on the policy that constrains it.
**Legibility-target:** A developer optimizing graph export six months from now, who reaches for `toPng` because it reads more naturally than `toBlob` and has no local reason not to.

A security policy in `app/lib/security/` now dictates an implementation detail in `app/lib/utils/`, two subtrees with no import between them. The change itself is correct and the comments are unusually good — but look at where the guard sits. `csp.test.ts` asserts `connect-src` stays `'self'` and explains, in a comment, that `exportGraph.ts` must therefore not `fetch()` a data URL. That test fires if someone *widens the policy*. Nothing fires if someone *narrows the export path back* — and `exportGraph.ts` has no test file in a repo with 26 of them, so the regression's entire detection surface is a browser, in production, on the PNG/zip export path, as a `TypeError`. The asymmetry is exactly backwards relative to likelihood: widening `connect-src` is a deliberate act by someone reading a security module, while swapping `toBlob` back to `toPng` is a plausible cleanup by someone reading a rendering utility who has no reason to open `csp.ts`. The merged fact-check's Cluster 13 sharpens this: `html-to-image`'s shared `toCanvas` pipeline *can* still `fetch()` for webfont/image embedding, so "stays within the DOM" holds for the removed decode step specifically — meaning the invariant is narrower and more delicate than the comment's phrasing suggests, and correspondingly easier to violate by accident.

**Evidence:** `app/lib/utils/exportGraph.ts:17-22` — `` * html-to-image's `toBlob` goes canvas → `canvas.toBlob()`, staying entirely `` / `` * within the DOM. The `toPng` + `fetch(dataUrl)` route it replaces looked `` / `` * equivalent but is not: `fetch()` of a `data:` URL is governed by `` / `` * `connect-src`, which the app's CSP scopes to `'self'`, so that route throws `` / `` * a TypeError at runtime. Do not reintroduce it ``; `app/lib/security/csp.test.ts:67-70` — `// Regression guard: graph PNG/zip export must decode canvases in-DOM` / ``// (`exportGraph.ts` uses `toBlob`) rather than `fetch()`-ing a data URL,``; repo-wide `rg --files -g '*exportGraph*'` returns one file — `app/lib/utils/exportGraph.ts` — and no test.

**Recommendation:** Add `app/lib/utils/exportGraph.test.ts` with one test that mocks `html-to-image` and asserts `renderGraphToBlob`'s path calls `toBlob` and that no `fetch` occurs (`vi.spyOn(globalThis, "fetch")` → `not.toHaveBeenCalled()`), citing the CSP reason in the test name. That is the cheapest artifact that fails on the regression the comment is trying to prevent, and it makes the invariant bidirectional. Optionally tighten the `exportGraph.ts` comment per fact-check Cluster 13 ("the final decode stays in-DOM").

---

#### `buildCsp`'s environment dependency was made testable but not removed; the production call site still reads ambient state and no test covers it

**Severity:** Coupling
**Location:** `app/lib/security/csp.ts:44-47`, `proxy.ts:16`
**Boundary:** B3 (`NODE_ENV` → shipped policy — the untested default is exactly this boundary's production path)
**Move:** #5 (interface segregation), #1 (dependency direction)
**Confidence:** High

**Move:** Make the environment an explicit argument at the one call site that matters, so the signature and the production path agree.
**Legibility-target:** Whoever asks "can `'unsafe-eval'` ship to production?" and wants to answer it by reading `proxy.ts` rather than by reasoning about default-parameter evaluation.

The default parameter is a well-chosen shape for the *test* problem — it is precisely what made the prod branch observable and closed A2's testability gap. But it splits the module into two behaviors with unequal coverage. Every one of the six `csp.test.ts` cases passes `nodeEnv` explicitly; the sole production caller, `buildCsp(nonce)`, does not. So the branch that actually ships is the only branch no test exercises, and the function's signature advertises purity that its default silently withdraws. The consequence is not a bug today — the fail-closed comparison means an unexpected `NODE_ENV` yields the stricter policy, and the ambient read is one hop from the entry point. It is that the seam is *optional*, and optional seams decay: a second caller (a future static-header path, a build script, a Storybook harness) will get whatever `NODE_ENV` the surrounding process happens to carry, and will do so without any signal at the call site that it made a choice. Full-1's A3 recommended reading the environment once inside `proxy()`; the extraction adopted the parameter half of that and left the read where it was.

**Evidence:** `app/lib/security/csp.ts:44-47` — `export function buildCsp(` / `  nonce: string,` / `  nodeEnv: string | undefined = process.env.NODE_ENV,` / `): string {`; `proxy.ts:16` — `  const csp = buildCsp(nonce);`; `app/lib/security/csp.test.ts` — all six cases call `buildCsp(NONCE, <explicit env>)`; no test invokes the one-argument form.

**Recommendation:** Either (a) drop the default and pass `process.env.NODE_ENV` explicitly from `proxy.ts:16` — one character of churn at the call site, and the ambient read becomes visible in the adapter layer where framework/environment coupling belongs; or (b) keep the default and add one test asserting `buildCsp(NONCE)` (one-argument form) contains no `'unsafe-eval'` under the test runner's environment, so the shipping branch has at least one guard. (a) is preferred — it also removes the argument about which branch is "the real one."

---

#### The `x-nonce` seam still has zero consumers, and now has a test that cements it

**Severity:** Coupling
**Location:** `proxy.ts:27-31`, `proxy.test.ts:64-85`
**Boundary:** B1 — direct correlate of `security-review.md`'s Informational "`x-nonce` is a live header with no consumer" (same location, B1)
**Move:** #3 (module boundary audit), #5 (interface segregation)
**Confidence:** High

**Move:** Decide the seam's fate now — wire it or delete it — while deleting it is still a two-line change rather than a two-line-plus-two-test change.
**Legibility-target:** A developer adding a `<Script>` tag who greps `x-nonce`, finds a write site *and two passing tests*, and concludes the plumbing is live.

Full-1 flagged this as an interface with no implementor; f25d968 improved the honesty (the comment now says "Nothing reads it today") but moved the structure the other way. Two of `proxy.test.ts`'s five tests now pin `x-nonce` behavior — that it matches the policy's nonce, and that a client-supplied value is clobbered rather than appended. Tests are how a codebase records which behaviors are contracts. So the module now publishes a header nobody reads, documents a consumer that does not exist, and asserts two properties of it in CI. That is more convincing misinformation than the comment alone was: prose can be doubted, a green test suite is usually taken as evidence that something is load-bearing. The clobber-vs-append property is genuinely correct and worth having *if the header is kept* — the objection is not to the test but to testing a seam whose consumer set is empty, because the combination raises the cost of the eventual deletion and lowers the odds anyone attempts it. Note this is now purely a legibility cost, not a correctness one: the real channel (CSP on the request headers) is wired and separately tested, so `x-nonce`'s absence would break nothing.

**Evidence:** `proxy.ts:27-31` — `// x-nonce is the conventional seam for server components that render their` / `// own <Script> tags. Nothing reads it today (Next handles its own bootstrap` / `// scripts via the header above); `.set` rather than `.append` so a` / `// client-supplied value is clobbered rather than joined into a comma-list.` / `requestHeaders.set("x-nonce", nonce);`; repo-wide `rg -n "x-nonce"` → 7 hits: 1 write site, 1 comment in `proxy.ts`, 4 in `proxy.test.ts`, 1 declining comment in `app/layout.tsx:32`. Zero reads outside tests; no `next/script` usage in `app/`.

**Recommendation:** Delete `requestHeaders.set("x-nonce", nonce)` and its two tests. Next extracts the nonce from the request CSP itself, so nothing regresses. If the team prefers to keep the seam against a planned `<Script>` consumer, retitle the tests to say so explicitly (e.g. *"x-nonce is published for future `<Script>` consumers and is not read today"*) so the suite documents the seam's status rather than implying it is in use.

---

#### The leaf security module carries an enumeration of the app's third-party integrations, and it has already drifted

**Severity:** Minor
**Location:** `app/lib/security/csp.ts:20-24`
**Boundary:** B2 — direct correlate of `security-review.md`'s Informational "`csp.ts` justifies `connect-src 'self'` partly on an integration that does not exist" (same location, B2)
**Move:** #2 (responsibility boundaries), #4 (layer violations)
**Confidence:** High

**Move:** State the rationale as an invariant the architecture guarantees, not as a list of the integrations that happen to exist today.
**Legibility-target:** Whoever adds the next third-party API and needs to know whether `connect-src` must change.

`csp.ts` is a dependency-free leaf, but its docstring is not: it reasons about reactflow, KaTeX, `next/font`, HMR, pdfjs-dist, `exportGraph.ts`, and a named list of upstream APIs. That inversion is inherent to CSP — a single policy necessarily encodes facts about every module above it, and the alternative (per-module CSP contributions assembled at build time) would be absurd over-engineering at this size. The cost is that the enumeration is a *maintenance liability with no maintainer*, and the fact-check demonstrates it has already gone stale in transit: the docstring names OpenAlex, which exists nowhere on this line (fact-check Cluster 6 — it lives on the non-ancestor `integration/6.1` branch), and "Anthropic" is reached only as an OpenRouter model-id prefix. The enumeration was carried verbatim from 9b4e453 through the extraction, which is exactly how this class of comment rots: a refactor moves it and nobody re-derives it. The structural point is that the *reason* `connect-src 'self'` is safe is not "these three vendors are server-side" — it is "no browser code in this app calls a third-party origin, because all outbound calls go through `app/api/**`." That formulation is stable under adding vendors; the list is not.

**Evidence:** `app/lib/security/csp.ts:20-22` — `` * `connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter `` / ` * calls are server-to-server (Next API routes), not browser-to-third-party.`; fact-check Cluster 6 (3/3 replicates, Mostly Accurate): no OpenAlex integration exists in this tree or at `d86d2dc`.

**Recommendation:** Replace the vendor list with the invariant: *"`connect-src 'self'` is sufficient because no browser-side code calls a third-party origin — every outbound API call is made server-side from `app/api/**`. Adding a client-side third-party fetch would require widening this directive; route it through an API handler instead."* This states the architectural rule the directive depends on, survives new vendors, and tells the next contributor what to do rather than what was once true.

---

#### Response security headers still have two plausible homes and no stated owner

**Severity:** Minor
**Location:** `proxy.ts:36`, `next.config.ts:3-5`
**Boundary:** B1, B2 — correlates with `security-review.md`'s Informational "CSP is the only security header set, and `/api/*` responses get none"; that review names the missing headers, this one names the missing owner
**Move:** #2 (responsibility boundaries)
**Confidence:** Medium

**Move:** Name `proxy.ts` as the single owner of response security headers before a second one is added elsewhere.
**Legibility-target:** Whoever adds `Strict-Transport-Security`, `Referrer-Policy`, or `Permissions-Policy` next.

Carried forward from full-1 (A6) unaddressed, and the extraction slightly raised the stakes: `proxy.ts` is now explicitly self-described as "wiring only," which reads as an argument *against* putting more headers there, while `next.config.ts` remains an empty placeholder whose `headers()` hook is the conventional Next home for static security headers. Nothing records the split, so the next header will be placed by coin flip — and once headers live in two files with different execution models (build-time config vs. per-request function), "what is our actual response policy?" stops being answerable from one file, and a `frame-ancestors`/`X-Frame-Options` style overlap becomes easy to introduce silently. The current state is fine; the unstated boundary is what will cost.

**Evidence:** `proxy.ts:36` — `  response.headers.set("Content-Security-Policy", csp);`; `proxy.ts:8-9` — ` * This file is wiring only; the policy itself lives in` / `` * `app/lib/security/csp.ts`, where it is unit-tested. ``; `next.config.ts:3-5` — `const nextConfig: NextConfig = {` / `  /* config options here */` / `};`.

**Recommendation:** One sentence in the `proxy.ts` docstring: *"All response security headers belong here rather than `next.config.ts`'s `headers()` hook, so the policy is readable in one place; the CSP must be per-request, and splitting the rest across two execution models would fragment it."* The value is in the sentence existing, not in which way it decides.

---

#### `app/lib/security/` is imported only from outside `app/**`

**Severity:** Informational
**Location:** `app/lib/security/csp.ts`, `proxy.ts:3`
**Move:** #4 (layer violations), #3 (module boundary audit)
**Confidence:** High

**Move:** None now — recorded so the placement question is answered deliberately if a second root-level runtime module arrives.
**Legibility-target:** The author of `instrumentation.ts` or the next root-level framework file.

The new module's home follows the repo's convention perfectly (`app/lib/<domain>/` + colocated test, matching seven siblings) but not its usage: `rg -n "lib/security"` returns exactly one importer, and it lives above `app/**`, not inside it. This is not a layer violation — the dependency points from the framework-entry layer down into logic, which is correct, and `csp.ts` imports nothing, so no `app/**` code is dragged into the proxy's module graph. It is worth a note only because the convention and the usage disagree, and the tiebreak went to convention, which is the right call at n=1: inventing a root-level `lib/` for a single 58-line file would fragment where logic lives for no benefit, and `@/*` resolves from the repo root so the import path is unremarkable either way. The signal to watch is a second root-level runtime module needing shared logic — at that point a root `lib/` housing "code used by framework-entry files" may become the truer home, and the decision should be made once rather than per-file.

**Evidence:** `proxy.ts:3` — `import { buildCsp } from "@/app/lib/security/csp";`; repo-wide `rg -n "lib/security"` → 2 hits, both in `proxy.ts` (the import and a docstring reference); `app/lib/` siblings: `analytics/`, `formalization/`, `llm/`, `stores/`, `types/`, `utils/`, `security/`.

**Recommendation:** No action. Revisit only when a second non-`app/**` runtime module needs shared logic.

---

#### `graphToPngBlob` is now an exact public alias of the private helper

**Severity:** Informational
**Location:** `app/lib/utils/exportGraph.ts:24-47`
**Move:** #5 (interface segregation)
**Confidence:** High

**Move:** None — recorded because the private/public split in this file is now vestigial and may confuse a later reader.
**Legibility-target:** Someone deciding which of the module's three rendering functions to call.

The `renderGraphToBlob` extraction is the right change — it removes a genuine duplication and gives the CSP-sensitive rendering exactly one site, which is what makes C1's recommended test possible. The residue is that `graphToPngBlob` is now `return renderGraphToBlob(viewportElement)` and nothing else, so the module has a private function and a public function with identical bodies and signatures, distinguished only by export. That is harmless (the module's two exported entry points differ meaningfully — one triggers a download, one returns a blob for zip assembly) but a reader may reasonably wonder what the private/public boundary is protecting. At this size the answer is "nothing yet," and merging them would only trade one small oddity for another.

**Evidence:** `app/lib/utils/exportGraph.ts:44-47` — `export async function graphToPngBlob(` / `  viewportElement: HTMLElement,` / `): Promise<Blob> {` / `  return renderGraphToBlob(viewportElement);`; callers: `app/lib/utils/exportAll.ts:64` (`graphToPngBlob`), `app/components/panels/GraphPanel.tsx:104` (`downloadGraphAsPng`).

**Recommendation:** No action. If a third rendering variant appears, export `renderGraphToBlob` directly and delete the alias.

---

#### `await headers()` remains a discarded side effect standing in for a render-mode switch — waived

**Severity:** Informational (waived)
**Location:** `app/layout.tsx:22-42`
**Move:** #7 (coupling surface), #8 (extension points)
**Confidence:** High

**Move:** None — the brief records this as waived with the comment corrected. Recorded for completeness and for the next reviewer of this file.
**Legibility-target:** A future lint pass, `code-simplifier` sweep, or "why is this layout async?" cleanup.

Full-1's A4 recommended `export const dynamic = "force-dynamic"` in place of the discarded `await headers()`; the waiver stands and the comment's factual defect (it previously claimed Next reads the nonce from the *response* header) is now corrected and confirmed accurate by the merged fact-check (Clusters 1-3). Two properties are worth recording rather than re-arguing. First, the residual risk is unchanged and unguarded: removing `await headers()` yields a statically prerendered layout with a stale-or-absent nonce and no failing test — the coupling to `proxy.ts`'s runtime behavior still has no compile-time or test-time representation, and `proxy.test.ts` cannot cover it because it tests the proxy in isolation. Second, the comment now does the job well: it states the mechanism, why the dynamic opt-out is load-bearing rather than accidental, why the cost is nil *for this app specifically*, and what would invalidate the reasoning (switching nonces to hashes). That last clause is the part that is otherwise unrecoverable, and it should survive if the waiver is ever revisited.

**Evidence:** `app/layout.tsx:42` — `  await headers();` (return value unused); `app/layout.tsx:34-35` — `// This dynamic opt-out is deliberate and load-bearing, not an oversight: a` / `// statically prerendered document is built once, so its <script> tags would`; no `export const dynamic` in `app/layout.tsx`.

**Recommendation:** No action while waived. If the waiver is lifted, move the second paragraph of the comment onto the new `dynamic` export rather than deleting it.

---

#### The `matcher` config remains the module's only extension point

**Severity:** Informational
**Location:** `proxy.ts:40-53`
**Move:** #8 (extension points)
**Confidence:** High

**Move:** None at this size — carried forward from full-1 unchanged so the growth signal stays recorded.
**Legibility-target:** A reviewer of the next change to this file.

Unchanged by f25d968. Exempting a new class of route still means adding an alternative to a negative-lookahead group inside a string — modification rather than extension — and `(?!api|_next/static|_next/image|favicon.ico)` is at the edge of scannable. With four exclusions this remains the right call; a matcher registry would be over-engineering. The signal to watch is a fifth and sixth exclusion arriving with unrelated features.

**Evidence:** `proxy.ts:46` — `      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",`

**Recommendation:** No action. If a third contributor adds an exclusion, split `matcher` into multiple `source` objects with a comment each.

## What Looks Good

- **The A2 extraction is the real thing, not a file move.** `buildCsp` went from module-private in an untestable root file to exported from `app/lib/security/csp.ts` with six tests — and critically, the `nodeEnv` parameter landed in the same change, so the production branch is actually observable. An extraction that had moved the function while leaving the ambient `process.env` read would have satisfied the letter of the finding and closed none of its value. This one closed the value.
- **The fail-closed property is now pinned rather than praised.** Full-1 complimented `=== "development"` in prose. `csp.test.ts` now enumerates `undefined`, `""`, `"Development"`, `"dev"`, `"test"`, `"prod"` and asserts none of them get `'unsafe-eval'`. That is the difference between a good decision and a maintained one, and it is the single highest-value test in the diff.
- **The nonce delivery contract became falsifiable.** `proxy.test.ts` documents *in the test body* which line's deletion it catches, and the fact-check independently traced that deleting `requestHeaders.set(...)` fails exactly two of five tests. Tests that name the mutation they defend against are rare and disproportionately useful to the next maintainer.
- **`proxy.ts` is now a genuine adapter.** 38 lines, zero policy, one import of logic. This sets the precedent full-1's A8 asked for — root-level framework file = glue, `app/lib/**` = logic — matching how `app/api/**/route.ts` already delegates to `app/lib/llm/*`. The next root-level module (`instrumentation.ts`, a rate limiter) now has a good example to copy rather than a bad one.
- **`renderGraphToBlob` gives the CSP-sensitive path exactly one site.** Beyond removing duplication, it means the invariant in C1 has a single place to be guarded, and the null-blob failure now throws instead of silently downloading an empty file. Consolidating before adding the guard is the right order.
- **The comments explain mechanism, not just intent.** `proxy.ts:18-24` cites the specific Next internal (`app-render.js`) and explains why response-only would fail (`'strict-dynamic'` makes CSP3 browsers ignore `'self'`). `exportGraph.ts:17-22` explains why the replaced route "looked equivalent but is not." This is the kind of documentation that survives a framework major, because it records the causal chain rather than the conclusion.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| C1 | CSP↔export-path invariant guarded in one direction only; `exportGraph.ts` has no tests | Coupling | B4 | `app/lib/utils/exportGraph.ts:16-33`, `app/lib/security/csp.test.ts:66-72` | High |
| C2 | `buildCsp` env dependency made testable but not removed; production call site uses the untested ambient default | Coupling | B3 | `app/lib/security/csp.ts:44-47`, `proxy.ts:16` | High |
| C3 | `x-nonce` seam still has zero consumers, and two tests now cement it | Coupling | B1 | `proxy.ts:27-31`, `proxy.test.ts:64-85` | High |
| M1 | Leaf security module carries a third-party integration enumeration that has already drifted (OpenAlex) | Minor | B2 | `app/lib/security/csp.ts:20-24` | High |
| M2 | Response security headers have two plausible homes, no stated owner (carried from full-1 A6) | Minor | B1, B2 | `proxy.ts:36`, `next.config.ts:3-5` | Medium |
| I1 | `app/lib/security/` imported only from outside `app/**` — placement follows convention, not usage | Informational | — | `proxy.ts:3` | High |
| I2 | `graphToPngBlob` is now an exact public alias of the private helper | Informational | — | `app/lib/utils/exportGraph.ts:44-47` | High |
| I3 | `await headers()` discarded side effect — waived, comment corrected, coupling still untested | Informational (waived) | B2 | `app/layout.tsx:22-42` | High |
| I4 | `matcher` regex is the only extension point — carried forward, no action | Informational | B1 | `proxy.ts:40-53` | High |

**Structural: none.**

## Overall Assessment

**Structurally sound; ship-ready from an architecture standpoint.** This iteration closed both of full-1's Structural findings on their merits rather than cosmetically, and it did so in the direction that improves the system rather than merely satisfying the review: the policy moved into the tested layer, the entry point became a real adapter, the delivery contract acquired a test that names the line it defends, and the environment dependency became a parameter in the same stroke. Dependency direction is correct at every new edge, the one new import points from framework-entry down to a dependency-free leaf, and the new module's placement matches seven existing siblings.

The residue is one class of problem, not five: **invariants that live in prose next to code that cannot enforce them.** C1 (export path must not `fetch` a data URL), C2 (the shipping branch of `buildCsp`), and C3 (a seam with no consumer) are each an instance, and each has a cheap mechanical fix — one test, one explicit argument, one deletion. None of them blocks. C1 is the one I would fix first: it is the only finding whose failure mode is a user-visible broken feature discovered in production, and it costs about fifteen lines.

The comment quality across this diff is well above what these files started with, and the deliberate parts are marked as deliberate. The remaining risk is the standard fate of good comments: M1 already shows one drifting during a refactor that moved it verbatim. Where a comment states an invariant that a test could hold, prefer the test — that is the through-line of every finding above.

## Goal-Alignment Note

- **Answered:** All briefed lenses. **Dependency direction** (Dependency Map — the new `proxy.ts` → `app/lib/security/csp.ts` edge points entry-point→logic, correct; no inversions). **Responsibility boundaries** (M1, M2). **Module boundary** including the explicit closure assessment the brief requested — A1 and A2 both genuinely closed, with the `app/lib/security/` placement and dependency direction assessed as sound (I1 records the one honest caveat). **Layers** (I1 — convention vs. usage; not a violation). **ISP** (C2 optional-seam signature, I2 vestigial alias). **Substitutability** (no subtypes, interfaces, or polymorphism anywhere in the diff — move #6 does not apply; `buildCsp`'s optional parameter is the nearest thing and is covered under C2). **Coupling** including both items the brief named: the layout's `await headers()` coupling (I3, waived, comment confirmed corrected) and the `proxy` → `lib/security` dependency (Dependency Map + I1 — sound). **Extension points** (I4, C1's guard placement). Findings lead with consequences and use the Structural / Coupling / Minor / Informational scale. **Explicit answer to the brief's question: nothing Structural exists in this diff.** **Trust-boundary cross-reference** performed rather than no-op'd: `security-review.md` landed in this directory during the review, so every finding carries a B1-B4 label and the three direct correlates (C3, M1, M2) are named at both the header and the finding.
- **Out of scope:** Runtime/browser verification of the CSP (no prod build or devtools available; the commit itself flags this). Security adequacy of the directive *values* — whether `style-src 'unsafe-inline'` is acceptable risk, whether `'strict-dynamic'` is correctly reasoned — belongs to a security review, not an architecture one; this review assesses only where the policy lives and how it is wired. Implementation correctness of the Next 16 header mechanics (taken from the merged fact-check, Clusters 3, 16, 17). Test quality per se beyond what the module boundary implies (`test-strategy`'s remit); C1's recommended test is named because the missing guard is a coupling artifact, not a coverage metric.
- **Escalate:** Nothing at Structural severity — if the loop-termination bar is "no Structural architecture findings," this pass meets it. Two items warrant a decision rather than deferral if the loop continues: **C1** (cheapest fix with a user-visible failure mode) and **C3** (deleting the `x-nonce` seam gets strictly more expensive now that two tests pin it — the window for a two-line deletion is closing). **M1 overlaps the fact-check's sole residual** (Cluster 6, the OpenAlex enumeration, Mostly Accurate, found by 3/3 replicates); the architectural recommendation there — replace the vendor list with the invariant that makes it true — subsumes the fact-check's suggested textual tighten, so the two should be resolved as one edit rather than twice. Also carried forward from the fact-check and applicable here: **the full-1 security review's assertion that the OpenAlex `connect-src` claim was "independently confirmed" does not hold on this state and must not be relied on downstream.**
