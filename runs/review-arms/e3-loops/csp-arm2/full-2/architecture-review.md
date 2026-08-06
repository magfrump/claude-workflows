# Architecture Review — CSP proxy + nonce delivery (iteration 2)

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-csp-arm2` (branch `e3/csp-arm2`)
**Commit:** 99e1229
**Files in scope:** `proxy.ts` (new), `proxy.test.ts` (new), `app/layout.tsx`, `app/lib/utils/exportGraph.ts`, `app/lib/utils/exportGraph.test.ts` (new)
**Trigger:** new top-level module (`proxy.ts`) + cross-cutting concern (CSP / rendering-mode pipeline)
**Foundation:** merged fact-check (k=3) for this range — fix claims verified; not re-verified here.

## Headline

Both structural reds from iteration 1 got real fixes, not paper ones. **R3** (cross-cutting control with a private policy and zero tests) is closed: `buildCsp` is exported and `proxy.test.ts` asserts the directive set *and* that the nonce lands on the forwarded request headers — a falsifier that genuinely fails when the wiring line is removed. **R4** (rendering-mode control as a discarded `await headers()` side effect) is closed in kind: the control is now a named, greppable, framework-declared segment export.

I found **no new Structural defect**. What the fixes introduced is a set of coupling costs, all of which are the *cheap* form of their respective problem: the falsifier is pinned to a Next-private header protocol, the CSP policy is now a public export of a framework entry file, a generic codec landed inside a deliberately code-split module, and the layout half of the nonce control is still the only half no test covers.

---

#### C1. The layout half of the nonce control is still the untested half — deleting it leaves 13/13 green

**Severity:** Coupling
**Location:** `app/layout.tsx:21–26`; `proxy.ts:43–52`; `proxy.test.ts` (whole file)
**Move:** Coupling-surface audit / substitutability
**Confidence:** High (mechanism and coverage gap both enumerated in-tree)

**Evidence:**

```
// Every route under this layout must render per request: a statically
// prerendered HTML document would bake in one nonce and reuse it for every
// visitor, which defeats the nonce. Next.js takes the nonce from the request's
// Content-Security-Policy header (set in proxy.ts) and stamps it onto the
// bootstrap <script> tags it emits, so nothing here reads it directly.
export const dynamic = "force-dynamic";
```
(`app/layout.tsx:21–26`)

Executed: `rg -n "buildCsp" .` → `proxy.ts:19`, `proxy.ts:39`, `proxy.test.ts:3,33,35,54,62` — no hit in `app/`. `rg -n "export const dynamic" app/` → `app/layout.tsx:26` only. `npx vitest run proxy.test.ts app/lib/utils/exportGraph.test.ts` → `Test Files 2 passed (2) · Tests 13 passed (13)`.

**Legibility-target:** for-author

R4 asked for two things and got one. The mechanism is fixed: `export const dynamic = "force-dynamic"` is a declarative framework contract — a named export, type-visible, greppable, and immune to the specific failure R4 named (a cleanup pass deleting a bare expression statement whose value is discarded). That is a genuine improvement and I would not re-raise R4 on its own terms.

The coupling is not fixed. The nonce control is still one behaviour split across two files with no import edge between them, and iteration 1's fix work put a test on exactly one side. `proxy.test.ts` proves the proxy emits and forwards a fresh nonce; nothing proves the document is rendered per request. Delete line 26 of `layout.tsx` and every test in the repo still passes, while a prerendered document freezes one nonce for all visitors — the precise failure the comment above it describes. The asymmetry is worth naming because it is the *residue of a fix*: the falsifier that iteration 1 demanded was scoped to the module the review named, not to the invariant the review described.

Is `force-dynamic` better or worse than `await headers()` as a coupling mechanism? Better on every axis I can score. Both are implicit — neither file imports the other, and in both cases the causal link lives only in a comment. But `await headers()` coupled through a *runtime side effect* (touching a dynamic API to trip Next's static-analysis bail-out), which is invisible to a reader who does not know Next's dynamic-API rules and looks like dead code. `force-dynamic` couples through a *declared route-segment config*, which is the framework's own vocabulary for this decision, appears in `next build` output as a `ƒ` marker, and reads as intentional. The remaining implicitness is that the *reason* — nonce freshness, owned by `proxy.ts` — is comment-only.

**Recommendation:** Add one assertion that fails when the render mode changes. Cheapest honest option: a test that imports `app/layout.tsx` and asserts `dynamic === "force-dynamic"`, with a comment naming `proxy.ts` as the reason — trivially satisfiable but it converts a silent security regression into a red test. Better if the build is available to CI: assert the route is dynamic in `next build` output. Either way, cross-reference the two comments so each end names the other.

---

#### C2. The falsifier's load-bearing assertion is pinned to a Next-private header protocol

**Severity:** Coupling
**Location:** `proxy.test.ts:5–22`
**Move:** Dependency direction — test-suite dependency on framework internals
**Confidence:** High

**Evidence:**

```
/**
 * `NextResponse.next({ request: { headers } })` cannot expose the forwarded
 * request headers directly — Next encodes them onto the response as
 * `x-middleware-request-<lowercased-name>`, with the overridden names listed in
 * `x-middleware-override-headers`, and unpacks them before render. Reading that
 * encoding is the only way to assert from a unit test that the nonce actually
 * reaches the document, which is the belief this file exists to falsify.
 */
function forwardedRequestHeader(
```
(`proxy.test.ts:5–13`)

**Legibility-target:** for-author

`x-middleware-request-*` and `x-middleware-override-headers` are an internal transport between the middleware/proxy stage and the render stage. They are not part of `next/server`'s typed surface, they are not in the public API contract, and `package.json` pins `"next": "16.2.4"` with a caret-free exact version only by luck of formatting (`"next": "16.2.4"` — exact, which helps here).

The consequence is bounded, and I want to be precise about the bound rather than gesture at "fragile test". If Next changes the encoding, `forwardedRequestHeader` returns `null`, and the two tests that matter guard for it (`expect(forwarded).not.toBeNull()` at :83, `expect(nonce).toBeTruthy()` at :91) — they fail loudly. I checked the one unguarded case, the security-relevant `not.toContain("attacker-controlled")` at :105, for vacuous-pass behaviour: vitest's chai adapter throws on a `null` receiver ("the given combination of arguments (null and string) is invalid for this assertion"), so it also fails loudly rather than passing on a missing header. So the coupling costs *false reds on a Next upgrade*, not *silent loss of the falsifier*. That is the acceptable failure direction, and it is the reason I grade this Coupling and not Structural.

What is missing is the signpost. A future maintainer facing a red `proxy.test.ts` after a `next` bump has to reconstruct from scratch whether the *proxy* broke or the *test's assumption about Next* broke — and the wrong conclusion (weakening the assertion to make it green) silently disarms the R1 falsifier.

**Recommendation:** Keep the approach — there is no public alternative, and the docblock already explains why. Add the version dependency explicitly: name `next@16.x` in the docblock and state the triage rule ("if this helper returns null after a Next upgrade, the encoding moved — fix the helper, do not weaken the assertion"). Optionally add one assertion that the override header exists at all, as a canary that distinguishes "Next changed" from "proxy broke".

---

#### C3. The CSP policy is now a public export of the framework entry file

**Severity:** Coupling
**Location:** `proxy.ts:19`
**Move:** Module boundary audit / dependency direction
**Confidence:** High (single-consumer enumeration executed)

**Evidence:**

```
export function buildCsp(nonce: string): string {
```
(`proxy.ts:19`) — consumers: `proxy.ts:39` and `proxy.test.ts` only (`rg -n "buildCsp" .`, node_modules excluded).

**Legibility-target:** for-author

Answering the question the review brief poses directly: **`buildCsp` is a test-only seam today, and the export is the right call anyway.** A cross-cutting security policy whose content nothing outside the module can observe is exactly what produced R1 — the export is what makes the directive-set test possible, and the function's shape (pure, one parameter, string out) is a clean seam with no leaked internals. I would not ask for it to be un-exported.

The structural cost is *where* it is exported from. Iteration 1's rubric offered two fixes for R3 — "export `buildCsp` **or** move to `app/lib/security/`" — and the author took the first, so the policy's owner is `proxy.ts`: a repo-root file that exists because Next.js looks for that filename. Anything else that ever needs the policy — a `report-uri` endpoint, a Report-Only rollout, a static-header path in the currently-empty `next.config.ts`, a test-fixture that renders a page under the real CSP — must import from the framework's entry module. That inverts the usual direction (entry files depend on lib; lib does not depend on entry files) and it makes `proxy.ts` non-relocatable: Next 16 already renamed this file once (`middleware.ts` → `proxy.ts`, per commit b25e939's comment fix), and a second rename would now break importers rather than just the framework hook.

There is no consumer today, so nothing is broken. The cost is paid at the moment a second consumer appears, and the fix is cheaper before that than after.

**Recommendation:** Move the policy to `app/lib/security/csp.ts` (exporting `buildCsp`) and have `proxy.ts` import it, leaving `proxy.ts` as thin framework glue: generate nonce → build → set both headers. `proxy.test.ts` splits naturally into a policy test next to the policy and a wiring test next to the proxy. This also gives G7 ("no obvious owner for the next response header") an answer.

---

#### C4. A generic `data:` codec landed inside a module that exists to be code-split away

**Severity:** Coupling
**Location:** `app/lib/utils/exportGraph.ts:1–7, 16–44`; `app/lib/utils/exportGraph.test.ts:2`
**Move:** Responsibility boundaries / interface segregation
**Confidence:** High

**Evidence:**

```
/**
 * Graph image export utilities. Separated for code-splitting since
 * html-to-image is only needed when exporting the React Flow graph.
 */

import { toPng } from "html-to-image";
import { triggerDownload } from "./export";
```
(`app/lib/utils/exportGraph.ts:1–7`)

```
export function dataUrlToBlob(dataUrl: string): Blob {
```
(`app/lib/utils/exportGraph.ts:23`) — nothing in it is graph-specific; it handles base64, percent-encoding, media-type parameters, and a non-`data:` rejection path.

```
import { dataUrlToBlob } from "./exportGraph";
```
(`app/lib/utils/exportGraph.test.ts:2`)

**Legibility-target:** for-author

The R2 fix itself is well-judged: decoding in-process instead of widening `connect-src` keeps the policy tight and moves the export path off the network entirely. The placement is the issue. `exportGraph.ts` declares in its first three lines that it exists so `html-to-image` stays out of the main bundle; `dataUrlToBlob` is a general-purpose codec with no dependency on `html-to-image`, `reactflow`, or the graph. Any second caller — a PDF page thumbnail, a pasted-image handler, an avatar preview — that imports it drags `html-to-image` into that caller's chunk and quietly defeats the stated split. The test file already demonstrates the pull: `exportGraph.test.ts` tests only `dataUrlToBlob` yet imports through the heavy module.

Sibling precedent exists and points the other way: `app/lib/utils/export.ts` already owns dependency-free Blob/download plumbing (`triggerDownload`, `downloadTextFile`), and `app/lib/utils/` is otherwise a flat set of single-purpose leaf modules (`stripCodeFences.ts`, `throttle.ts`, `topologicalSort.ts`). A codec fits that shape exactly.

Second boundary note in the same place: the CSP constraint is now *documented* in a leaf utility ("the app's CSP sets `connect-src 'self'`", :19–21) with no symbol, import, or test tying it to `proxy.ts`. The behavioural coupling is benign — `dataUrlToBlob` is correct regardless of what the policy says — but the comment is a second copy of a fact owned elsewhere, i.e. the same rot pattern that produced iteration 1's A1 and A2 (and, per the merged fact-check, still produces the live Tailwind-rationale defect in `proxy.ts:12–14`).

**Recommendation:** Move `dataUrlToBlob` to `app/lib/utils/dataUrl.ts` (or into `export.ts` beside `triggerDownload`) with `exportGraph.test.ts`'s cases following it; re-export nothing. Trim the comment to the invariant that survives a policy change ("decode in-process — do not `fetch()` a `data:` URL; it is a `connect-src` fetch") and let `proxy.ts` remain the single place that states what `connect-src` is.

---

#### M1. `x-nonce` gained tests but still has no consumer — the dead contract is now harder to delete

**Severity:** Minor
**Location:** `proxy.ts:47–50`; `proxy.test.ts:88–108`
**Move:** Interface segregation
**Confidence:** High (enumeration executed)

**Evidence:** `rg -n "x-nonce|xNonce" .` (node_modules excluded) → `proxy.ts:48` (comment), `proxy.ts:50` (write), and five hits in `proxy.test.ts`. No reader anywhere in `app/`.

```
  // Overwrite (not append) so a client-supplied x-nonce cannot be smuggled
  // through to a server component.
  requestHeaders.set("x-nonce", nonce);
```
(`proxy.ts:48–50`)

**Legibility-target:** for-author

Iteration 1's A4 said this resolves either way once R1 lands — land a consumer, or delete the header. Iteration 2 did a third thing: it wrote two tests against it. The tests are individually reasonable (the smuggling test encodes a real security property), but structurally they convert a two-line deletion into a decision with test fallout, and they assert the *shape* of a contract that no code consumes. A reader now sees a tested wire contract and reasonably infers a consumer exists.

Note this is not the same as the request-`Content-Security-Policy` header, which R1 established as genuinely load-bearing and which `proxy.test.ts:80–87` covers correctly. `x-nonce` is the separate, still-unconsumed half.

**Recommendation:** Decide. If a `<Script nonce={...}>` consumer is planned, add a `// consumer: <path>` note now. If not, delete `proxy.ts:47–50`'s `x-nonce` line and its two tests — the `NextResponse.next({ request })` wrapper stays regardless, since the CSP request header needs it.

---

#### M2. The falsifier for a server-runtime module runs under the browser test environment

**Severity:** Minor
**Location:** `proxy.test.ts:1–3`; `vitest.config.ts:8`
**Move:** Substitutability — test environment vs deployment runtime
**Confidence:** Medium-High (config read; per-file override absent, confirmed by `rg`)

**Evidence:**

```
    environment: 'jsdom',
```
(`vitest.config.ts:8`, applied globally) — `rg -n "vitest-environment" -g '*.test.*' .` → no hits, so `proxy.test.ts` inherits jsdom.

**Legibility-target:** for-author

`proxy.ts` ships to a server runtime and depends on runtime-availability facts — `crypto.randomUUID` and `Buffer` (`proxy.ts:35–37`, whose Edge-runtime claim the merged fact-check already carries as a live comment defect). Under jsdom those globals resolve through Node's test process regardless, so the test cannot distinguish "available in the deployed runtime" from "available in the test harness." That is a fidelity gap in exactly the belief the comment asserts. It is Minor, not Coupling, because the test's *primary* job — header wiring — is runtime-independent and does hold.

Every other test file in the repo tests DOM-facing code (components, hooks, browser utils), so the global jsdom default is right for them; `proxy.test.ts` is the first file for which it is wrong.

**Recommendation:** Add `// @vitest-environment node` at the top of `proxy.test.ts`. One line, and it makes the runtime assumption explicit at the site that depends on it.

---

#### M3. The R2 fix relocated a failure boundary without establishing one

**Severity:** Minor
**Location:** `app/lib/utils/exportGraph.ts:25–27, 54, 65`
**Move:** Responsibility boundaries — error ownership
**Confidence:** High

**Evidence:**

```
  if (!dataUrl.startsWith("data:") || commaIndex === -1) {
    throw new Error("Not a data: URL");
  }
```
(`app/lib/utils/exportGraph.ts:25–27`)

```
  triggerDownload(dataUrlToBlob(dataUrl), filename);
```
(`app/lib/utils/exportGraph.ts:54`) — no `try`/`catch` at either call site (:54, :65), unchanged from iteration 1.

**Legibility-target:** for-author

Before the fix, an export failure surfaced as a rejected `fetch` inside an `async` function (uncaught rejection). After the fix, it surfaces as a synchronous `throw` from a decoder, or from `atob` on malformed base64, propagating out of the same `async` functions as the same uncaught rejection. The user-visible behaviour — click, nothing happens, no message — is identical, and the module still nominates no owner for the failure. Iteration 1 carried this as advisory G12; the R2 fix moved the throw site without closing it, which is worth stating explicitly so the fix is not read as having addressed it.

Architecturally the question is which layer owns export failure: the utility (return `null`/`Result`), or the calling component (catch and render an error state). Neither is chosen.

**Recommendation:** Out of this diff's scope to build an error UI, but pick the owner and write it in the docblock. If the call sites will own it, say `// throws on malformed input — callers must catch`, so the next person adding a call site sees the obligation.

---

#### I1. `force-dynamic` at the root layout keeps the rendering-mode decision at the widest possible scope

**Severity:** Informational
**Location:** `app/layout.tsx:26`
**Move:** Extension points
**Confidence:** High

**Evidence:** `export const dynamic = "force-dynamic";` (`app/layout.tsx:26`) — the app's only route-segment config (`rg -n "export const dynamic|export const runtime" app/` → one hit).

**Legibility-target:** for-orchestrator-synthesis

Unchanged in kind from iteration 1's A8: every page route, present and future, renders per request because a security control needs it, and any future route that wants static rendering must override at its own segment while silently losing nonce freshness. Route handlers under `app/api/` are unaffected (segment config in a layout does not apply to them), so the blast radius is pages only.

This is the correct trade if per-request nonces are a hard requirement — I flag it only so the cost is attributed to this decision rather than rediscovered later as an unexplained TTFB regression. The extension point that does not exist: there is no way to say "this route is static and therefore exempt from nonce-based CSP" without editing two files that do not reference each other.

**Recommendation:** No action in this diff. Record the trade in a decision record (see I2).

---

#### I2. The control's surface tripled; no decision record or inventory entry exists

**Severity:** Informational
**Location:** `docs/decisions/`; `CLAUDE.md`
**Move:** Module boundary audit — discoverability
**Confidence:** High

**Evidence:** `ls docs/decisions` → eight records, none about CSP, headers, or rendering mode. `rg -n -i "csp|proxy\.ts|middleware" CLAUDE.md` → one unrelated hit (`CLAUDE.md:37`, the panels list); no `docs/ARCHITECTURE.md` in the tree.

**Legibility-target:** for-orchestrator-synthesis

Iteration 1 carried this as G4 against a 72-line surface. The surface is now `proxy.ts` + `proxy.test.ts` + a rendering-mode contract in the root layout + an exported utility whose existence is justified by the policy — four files that must move together, documented in four comments that reference each other informally and, per the merged fact-check, still contain at least two wrong rationales. A decision record is the artifact that would let a future reader learn the whole mechanism without reverse-engineering it from comments of mixed reliability.

**Recommendation:** One record — `docs/decisions/NNN-content-security-policy.md` — covering: nonce delivery via request headers (and why response-only fails under `strict-dynamic`), the `force-dynamic` consequence and its cost, the `style-src 'unsafe-inline'` carve-out and its *actual* dependents, and the `connect-src 'self'` constraint that shapes `dataUrlToBlob`. Add `proxy.ts` to `CLAUDE.md`'s file inventory.

---

## What Looks Good

- **The R3 falsifier is real, not decorative.** `proxy.test.ts:80–87` asserts the forwarded request header *equals* the response header, which is precisely the belief whose falseness caused R1. The merged fact-check confirms it fails when the wiring line is disabled. Most "add a test" fixes to a review finding assert the thing that was already true; this one asserts the thing that was wrong.
- **The R4 mechanism swap is a genuine legibility upgrade.** Discarded-side-effect coupling (`await headers();`) → declared segment config. The specific failure R4 named — a cleanup pass deleting an expression whose value is unused — is now impossible.
- **`buildCsp`'s seam is minimal and pure.** One string parameter in, one string out, no injected clock/crypto/config, no framework types in the signature. The directive-set test (`proxy.test.ts:34–48`) asserts the *exact* key set rather than the presence of a few directives, so a silently dropped directive fails.
- **Dependency direction on the app side stays clean.** `proxy.ts` imports only `next/server`; nothing under `app/` imports `proxy.ts` (`rg` over `app/` → 0 hits). No cycle was introduced by exporting `buildCsp`.
- **Test placement follows the repo convention.** All 26 other test files sit beside their subject; `proxy.test.ts` at the root does the same for a root-level module, and picks up the default vitest include with no config change.
- **`dataUrlToBlob`'s own test suite is well-targeted.** Binary-safety (`0xff 0xfe 0xfd` round-trip), media-type parameter stripping, the percent-encoded branch, and the rejection path — the four things a hand-rolled codec gets wrong. The negative test at `proxy.test.ts:97–108` also fails loudly rather than vacuously on a missing header, which I verified against vitest's chai adapter rather than assuming.

## Summary Table

| # | Finding | Severity | Location | Legibility-target |
|---|---------|----------|----------|-------------------|
| C1 | Layout half of the nonce control is untested; deleting `export const dynamic` leaves all tests green | Coupling | `app/layout.tsx:21–26`; `proxy.test.ts` | for-author |
| C2 | Falsifier pinned to Next-private `x-middleware-request-*` protocol; no version signpost or triage rule | Coupling | `proxy.test.ts:5–22` | for-author |
| C3 | CSP policy exported from the framework entry file rather than a security module; inverts import direction for any future consumer | Coupling | `proxy.ts:19` | for-author |
| C4 | Generic `data:` codec placed inside a module that exists to be code-split away; CSP fact re-stated in a leaf utility | Coupling | `app/lib/utils/exportGraph.ts:1–7, 16–44` | for-author |
| M1 | `x-nonce` gained two tests but still has zero consumers; dead contract now costs more to delete | Minor | `proxy.ts:47–50`; `proxy.test.ts:88–108` | for-author |
| M2 | Server-runtime module tested under the global jsdom environment; no `@vitest-environment node` | Minor | `proxy.test.ts:1–3`; `vitest.config.ts:8` | for-author |
| M3 | R2 relocated the export failure boundary without establishing one; still no owner, still silent | Minor | `app/lib/utils/exportGraph.ts:25–27, 54, 65` | for-author |
| I1 | Rendering-mode decision remains at the root layout; cascades to every future page route | Informational | `app/layout.tsx:26` | for-orchestrator-synthesis |
| I2 | Control now spans four files with no decision record and no inventory entry | Informational | `docs/decisions/`; `CLAUDE.md` | for-orchestrator-synthesis |

## Overall Assessment

**No Structural findings. Prior structural reds R3 and R4 are closed on their stated terms.**

I went looking for the failure mode this iteration is designed to catch — a fix that satisfies a review's letter while re-introducing the defect elsewhere — and did not find it. R3's fix produced a falsifier that genuinely falsifies; R4's fix replaced an incidental side effect with a declared framework contract. Neither is cosmetic.

What remains is a coherent cluster with one shape: **the fixes were scoped to the modules the review named, not to the invariants the review described.** C1 is the clearest instance — the falsifier covers `proxy.ts` because that is where the finding pointed, while the half of the control living in `layout.tsx` stayed uncovered even though the same finding explained why it matters. C3 is the same pattern at the module level: the rubric offered "export it *or* move it," and export is the smaller edit, leaving the policy owned by a framework entry file. C4 is the pattern at the placement level: the decode logic went where the caller already was rather than where a general-purpose codec belongs.

None of these blocks the change. In priority order for a follow-up: **C1** (a security control whose loss is silent under a green suite is the only item with a real downside), then **C3 + C4 together** (both are moves, both are cheap now and progressively less cheap later, and doing them together gives `app/lib/security/` and `app/lib/utils/dataUrl.ts` an obvious shape), then **M1** as a decision the author can make in thirty seconds, then **I2** to make the whole mechanism legible without relying on comments the fact-check has already found unreliable in two places.

The severity distribution is itself the finding: iteration 1 produced two Structural items; iteration 2 produces none. The loop worked.

*(No `security-review.md` present in `/workspace/runs/review-arms/e3-loops/csp-arm2/full-2/` at the time of writing — no boundary-label cross-reference applied.)*

## Goal-Alignment Note

- **Answered:** All eight requested architecture moves. Dependency direction (C3, plus the confirmed-clean `app/` → `proxy.ts` non-edge). Responsibility boundaries (C4, M3). Module boundary audit (C3, I2). Layer violations (C3 — the framework-entry-as-library-owner inversion is the only one found; no `app/` layer breach). Interface segregation (M1, C4). Substitutability (M2). Coupling surface (C1 — explicit better/worse verdict on `export const dynamic` vs `await headers()`: better on legibility, greppability, and deletion-resistance; unchanged on implicitness and test coverage). Extension points (I1). Verified both claimed fixes structurally (R3 closed, R4 closed in kind) and searched specifically for defects the fixes introduced — C2, C4, M1, and M2 are all new with this iteration.
- **Out of scope:** Whether the policy is *correct* as security (missing `form-action`, prefetch exemption, cache/`Vary` barriers, `worker-src`) — security-reviewer's domain. Comment-accuracy defects (Tailwind `style-src` rationale, Edge-runtime claim, OpenAlex phantom) — carried by the merged fact-check as foundation; referenced in I2 only as a reason the decision record matters, not re-verified. Bundle-size and TTFB magnitudes for I1 — performance-reviewer's domain; I flag the structural cascade, not the number. `dataUrlToBlob`'s decoding correctness on edge inputs and its naming/signature conventions — api-consistency's domain. The absent export-error UI — ui-visual's domain (M3 covers only the unassigned ownership).
- **Escalate:** **C1** to the orchestrator, on the grounds that its consequence (a security control silently disabled by a plausible cleanup, with a fully green test suite) matches the consequence class that made R3 and R4 red in iteration 1, even though I grade the finding itself Coupling because the mechanism is now declarative rather than incidental. If the orchestrator's escalation rule keys on consequence rather than on the native severity, this is the one item that should cross into red. Also flag for synthesis that **I2** is now a cross-domain concern rather than a documentation nicety: with the merged fact-check finding multiple wrong rationales in the very comments that are the mechanism's only documentation, the absence of a decision record is what makes the next reader's information source unreliable.
