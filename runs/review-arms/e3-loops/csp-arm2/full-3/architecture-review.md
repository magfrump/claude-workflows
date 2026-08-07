# Architecture Review — CSP proxy + nonce delivery (iteration 3, FINAL)

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-csp-arm2` (branch `e3/csp-arm2`)
**Commit:** 2544a19
**Files in scope:** `proxy.ts` (new), `proxy.test.ts` (new), `app/layout.tsx`, `app/lib/utils/exportGraph.ts`, `app/lib/utils/exportGraph.test.ts` (new)
**Trigger:** new top-level module (`proxy.ts`) + cross-cutting concern (CSP / rendering-mode pipeline)
**Prior pass:** `../full-2/code-review-rubric.md` (advisory) — 0 Structural; Coupling C1–C4 carried open.

## Headline

**No Structural findings. Nothing in this iteration's commit changes the structure of the system.**

`2544a19` edits three comment blocks in `proxy.ts` and nothing else — verified: `git show --stat 2544a19` → `proxy.ts | 13 ++++++++-----`, and every changed line in the hunks is inside `/** */` or a `//` comment. No symbol, signature, module boundary, import edge, or dependency direction moved. Every structural finding from iteration 2 therefore carries forward at its original severity, and I re-verified each against the tree at HEAD rather than assuming it (enumerations reproduced below, per finding).

The one architecture-relevant thing the commit *does* is not a fix — it is evidence. Iteration 2's C4 noted a second copy of a CSP fact living in a leaf module with no owner and called it "the same rot pattern" as earlier findings. `2544a19` is that prediction coming true and being answered the way that preserves it: the `style-src` rationale had drifted between `proxy.ts` and `proxy.test.ts`, and the repair hand-synced the two copies rather than giving the fact one home. That is recorded below as **C5** — the only new finding in this pass.

Honest summary for a final pass: after three iterations the change is structurally sound and structurally *unfinished*. C1 — the half of the security control that no test covers — is unchanged from iteration 2, and it is the only item in this review whose failure mode is silent.

---

#### C1. The layout half of the nonce control is still the untested half — and no test file in the repo even imports it

**Severity:** Coupling
**Location:** `app/layout.tsx:21–26`; `proxy.ts:44–53`; `proxy.test.ts` (whole file)
**Move:** Coupling-surface audit / substitutability
**Confidence:** High (coverage gap now proven by enumeration, not by a test run)
**Status:** Carried unchanged from iteration 2. Untouched by `2544a19`.

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

Executed at HEAD:
- `rg -n "force-dynamic|export const dynamic" --glob '!node_modules' --glob '!.next' -g '*.ts*' .` → **one hit**: `./app/layout.tsx:26`.
- `rg -n "layout" --glob '*.test.ts*' .` (node_modules excluded) → the only hit is `proxy.test.ts:61`, the word "layout" inside a prose comment about graph rendering. **No test file in the repository imports `app/layout.tsx`.**

**Legibility-target:** for-author

Iteration 2 proved this by running the suite with the line deleted and getting 13/13 green. The enumeration above is the stronger form of the same claim and costs nothing to re-check: there is no test that *could* fail, because no test loads the module. The control is one behaviour split across two files with no import edge between them, and the falsifier iteration 1 demanded was scoped to the module the finding named (`proxy.ts`) rather than the invariant the finding described (a fresh nonce reaches each rendered document).

The consequence is unchanged and is the reason this item leads the list: delete line 26 in a plausible cleanup — "why is a layout forcing dynamic rendering? this looks like a leftover" — and the suite stays green, `tsc` stays clean, lint stays clean, and every visitor gets served the same baked-in nonce. `'strict-dynamic'` then means the frozen nonce is the *only* thing that grants script trust, so the failure is not a broken app that someone notices; it is a working app with a defeated control.

I graded this Coupling rather than Structural in iteration 2 and I hold that grade. The mechanism is a declared framework contract (`export const dynamic`), which is greppable, type-visible, appears in `next build` output, and is immune to the specific deletion failure that made iteration 1's R4 red. What is missing is coverage, not structure.

**Recommendation:** Unchanged and still cheap: a test that imports `app/layout.tsx` and asserts `dynamic === "force-dynamic"`, commented with `proxy.ts` as the reason. Trivially satisfiable, but it converts a silent security regression into a red test. Cross-reference the two comments so each end names the other.

---

#### C2. The falsifier's load-bearing assertion is still pinned to a Next-private header protocol, with no version signpost

**Severity:** Coupling
**Location:** `proxy.test.ts:5–22`
**Move:** Dependency direction — test-suite dependency on framework internals
**Confidence:** High
**Status:** Carried unchanged from iteration 2. Untouched by `2544a19`.

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

`x-middleware-request-*` and `x-middleware-override-headers` are an internal transport between the proxy stage and the render stage — not part of `next/server`'s typed surface, not in the public API contract. `package.json` pins `"next": "16.2.4"` exactly, which contains the blast radius today.

The bound on the consequence is the same one I established in iteration 2 and it is the acceptable direction: if Next changes the encoding, the helper returns `null`, the guarded assertions (`expect(forwarded).not.toBeNull()` at :83, `expect(nonce).toBeTruthy()` at :91) fail loudly, and the one unguarded assertion (`not.toContain` at :105) throws rather than passing vacuously, because vitest's chai adapter rejects a `null` receiver for that combination. So the coupling costs **false reds on a Next upgrade**, not silent loss of the falsifier. That is why this is Coupling and not Structural.

What is still missing is the triage rule. A maintainer facing a red `proxy.test.ts` after a `next` bump must reconstruct from scratch whether the proxy broke or the test's assumption broke — and the wrong call (weakening the assertion to get green) silently disarms the R1 falsifier, which is the most valuable test in this diff.

Note the interaction with `2544a19`: this iteration's commit demonstrates that the author is willing to spend a commit on comment accuracy in `proxy.ts`. The same treatment was not extended to `proxy.test.ts`'s docblock, which is where the undocumented version dependency lives.

**Recommendation:** Keep the approach — there is no public alternative. Add `next@16.2.4` to the docblock plus the triage rule in one sentence ("if this helper returns `null` after a Next upgrade, the encoding moved — fix the helper, do not weaken the assertion"). Optionally add a canary asserting `x-middleware-override-headers` exists at all, which distinguishes "Next changed" from "proxy broke" without any judgement call.

---

#### C3. The CSP policy is still a public export of the framework entry file

**Severity:** Coupling
**Location:** `proxy.ts:22`
**Move:** Module boundary audit / dependency direction
**Confidence:** High (single-consumer enumeration re-executed at HEAD)
**Status:** Carried unchanged from iteration 2. Untouched by `2544a19`.

**Evidence:**

```
export function buildCsp(nonce: string): string {
```
(`proxy.ts:22`)

Executed at HEAD: `rg -n "buildCsp" .` (node_modules excluded) → `proxy.ts:22` (definition), `proxy.ts:42` (sole production call), and `proxy.test.ts:3,35,54,62`. No hit under `app/`. `ls app/lib` → `analytics formalization llm stores types utils` — no `security/`. `cat next.config.ts` → still the empty scaffold (`const nextConfig: NextConfig = {};`), so no competing header owner exists yet.

**Legibility-target:** for-author

The export itself remains the right call and I would not ask for it back: a cross-cutting security policy that nothing outside its module can observe is exactly what produced iteration 1's R1, and `buildCsp`'s shape (pure, one string in, one string out, no framework types in the signature) is a clean seam.

The cost is *where* it is exported from. `proxy.ts` is a repo-root file that exists because Next.js looks for that filename. Anything that ever needs the policy — a `report-uri` endpoint, a Report-Only rollout, a `next.config.ts` static-header path for the routes the matcher excludes, a fixture that renders a page under the real CSP — must import from the framework's entry module, inverting the usual direction (entry files depend on lib; lib does not depend on entry files). It also makes `proxy.ts` non-relocatable: Next 16 already renamed this file once (`middleware.ts` → `proxy.ts`, per `b25e939`), and a second rename would now break importers rather than only the framework hook.

Two notes specific to this final pass. First, three iterations have gone by with no second consumer, which is real evidence that the cost is not being paid yet — the finding is about the cost curve, not a present defect. Second, `security-review` in the prior pass identified `next.config.ts` as the natural home for a second header layer and showed that a second layer turns the matcher's exclusions into a live mismatch; if that layer is ever added, this finding is the one that decides whether the policy has one owner or two.

**Recommendation:** Move the policy to `app/lib/security/csp.ts` and have `proxy.ts` import it, leaving `proxy.ts` as thin framework glue: generate nonce → build → set both headers. `proxy.test.ts` splits naturally into a policy test beside the policy and a wiring test beside the proxy.

---

#### C4. A generic `data:` codec still lives inside a module that exists to be code-split away

**Severity:** Coupling
**Location:** `app/lib/utils/exportGraph.ts:1–7, 16–44`; `app/lib/utils/exportGraph.test.ts:2`
**Move:** Responsibility boundaries / interface segregation
**Confidence:** High
**Status:** Carried unchanged from iteration 2. Untouched by `2544a19`.

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
(`app/lib/utils/exportGraph.ts:23`) — nothing in the body is graph-specific: it handles base64, percent-encoding, media-type parameters, and a non-`data:` rejection path.

```
import { dataUrlToBlob } from "./exportGraph";
```
(`app/lib/utils/exportGraph.test.ts:2`)

Executed at HEAD: `rg -n "dataUrlToBlob"` → definition + two in-module call sites (`:54`, `:65`) + six hits in `exportGraph.test.ts`. No external consumer. The documented split is live: `app/components/panels/GraphPanel.tsx:102` does `await import("@/app/lib/utils/exportGraph")` precisely to keep `html-to-image` out of the main chunk.

**Legibility-target:** for-author

The R2 fix behind this — decoding in-process instead of widening `connect-src` — remains well-judged; placement is the issue. Any second caller of the codec (a PDF page thumbnail, a pasted-image handler, an avatar preview) drags `html-to-image` into that caller's chunk and defeats the split the module's own first three lines declare. The test file already demonstrates the pull: `exportGraph.test.ts` tests only `dataUrlToBlob` and imports through the heavy module. Sibling precedent points the other way — `app/lib/utils/export.ts` ("Core export utilities… zero-dependency") already owns `triggerDownload` and `downloadTextFile`, and `app/lib/utils/` is otherwise a flat set of single-purpose leaf modules.

The second boundary note in this finding is the one that `2544a19` has now made concrete; see **C5**.

**Recommendation:** Move `dataUrlToBlob` to `app/lib/utils/dataUrl.ts` (or into `export.ts` beside `triggerDownload`) with its test cases following it; re-export nothing.

---

#### C5. **(new)** The rationale drift predicted by C4 happened, and the repair hand-synced a second copy instead of giving the fact an owner

**Severity:** Coupling
**Location:** `proxy.ts:12–17` vs `proxy.test.ts:59–61`; third instance at `app/lib/utils/exportGraph.ts:18–21`
**Move:** Responsibility boundaries — ownership of a cross-module fact
**Confidence:** High (both copies read at HEAD; the drift-and-repair is in `git show 2544a19`)
**Status:** New this iteration. This is the only architecture-relevant consequence of `2544a19`.

**Evidence:**

Copy 1, after `2544a19`:

```
 * Why `style-src 'unsafe-inline'`: React `style={}` attributes, reactflow's
 * inline transforms and KaTeX all emit inline styles at runtime; dev also
 * injects styles. (Tailwind v4 itself compiles to a linked stylesheet via
 * `@tailwindcss/postcss` and is already covered by `'self'`.) Tightening to
 * nonces would mean reworking how each of those ships styles. Documented as a
 * deliberate carve-out, not an oversight.
```
(`proxy.ts:12–17`)

Copy 2, unchanged since the feature commit:

```
  it("keeps the style-src 'unsafe-inline' carve-out", () => {
    // Required by React style={} attributes, reactflow's inline transforms and
    // KaTeX; removing it silently breaks graph layout and equation sizing.
```
(`proxy.test.ts:59–61`)

Copy 3, a different directive, same pattern:

```
 * `fetch(dataUrl)` is the shorter spelling but is a `connect-src` fetch, and
 * the app's CSP sets `connect-src 'self'`, which refuses `data:`. Decoding here
 * keeps that directive tight instead of widening it for an export helper.
```
(`app/lib/utils/exportGraph.ts:18–21`)

And the repair itself (`git show 2544a19`, the `proxy.ts` hunk):

```
- * Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening
- * to nonces would require rebuilding how Tailwind ships styles in dev and
- * SSR. Documented as a deliberate carve-out, not an oversight.
+ * Why `style-src 'unsafe-inline'`: React `style={}` attributes, reactflow's
+ * inline transforms and KaTeX all emit inline styles at runtime; dev also
```

**Legibility-target:** for-author

Iteration 2's C4 closed with a boundary note: a CSP fact was being re-stated in a leaf utility, "a second copy of a fact owned elsewhere, i.e. the same rot pattern" that had already produced wrong comments elsewhere in this change. That was a prediction. `2544a19` is the prediction resolving — the two copies of the `style-src` rationale had diverged far enough to contradict each other on *which dependency* forces the carve-out, and the divergence took a k=3 fact-check plus a full review cycle to detect.

What the repair did is the part worth recording architecturally. It re-typed the correct rationale into the second location, so the system now has two agreeing copies of a fact with no import edge, no shared constant, and no mechanism that fails when they diverge again. The next edit to either one re-opens the same defect, and the detection mechanism that caught it the first time was a review pass, not the build. A third copy of an adjacent CSP fact already sits in `exportGraph.ts`, in a module that has no other relationship to the policy.

I am grading this Coupling rather than Minor deliberately. Two files must now be edited together, the requirement is expressed nowhere but in prose, and nothing enforces it — that is coupling without a seam, and it happens to be coupling over the documentation that is the only description this mechanism has. It is not Structural: nothing executable depends on the agreement, and a wrong comment cannot break the app. It costs a reader's trust, not correctness.

There is a real design tension here worth naming rather than glossing: the test comment at `proxy.test.ts:60–61` is *good practice* — a test that asserts a security carve-out should say why the carve-out exists, right where the assertion is. The problem is not that the test explains itself; it is that neither copy is marked as derivative of the other. One line of attribution would resolve it without deleting either.

**Recommendation:** Pick an owner and mark the others as references. Cheapest: make `proxy.ts:12–17` authoritative, shorten `proxy.test.ts:60–61` to `// rationale: see proxy.ts style-src note`, and trim `exportGraph.ts:18–21` to the invariant that survives a policy change ("decode in-process — do not `fetch()` a `data:` URL; it is a `connect-src` fetch"). The durable version of this is **I2** — a decision record that owns all four CSP facts, so no comment needs to be the source of truth.

---

#### M1. `x-nonce` still has tests and still has no consumer

**Severity:** Minor
**Location:** `proxy.ts:51–53`; `proxy.test.ts:88–108`
**Move:** Interface segregation
**Confidence:** High (enumeration re-executed at HEAD)
**Status:** Carried unchanged from iteration 2.

**Evidence:** `rg -n "x-nonce|xNonce"` (node_modules, `.next` excluded) → `proxy.ts:51` (comment), `proxy.ts:53` (write), and five hits in `proxy.test.ts`. **No reader anywhere under `app/`.**

```
  // Overwrite (not append) so a client-supplied x-nonce cannot be smuggled
  // through to a server component.
  requestHeaders.set("x-nonce", nonce);
```
(`proxy.ts:51–53`)

**Legibility-target:** for-author

Iteration 1's A4 said this resolves either way once R1 lands — land a consumer or delete the header. Three iterations later it has neither, and it has accumulated two tests. The tests are individually reasonable (the smuggling test encodes a real security property) but they assert the shape of a contract that no code consumes, and they turn a two-line deletion into a change with test fallout. A reader now sees a tested wire contract and reasonably infers a consumer exists.

This is distinct from the request-side `Content-Security-Policy` header, which R1 established as genuinely load-bearing and which `proxy.test.ts:80–87` covers correctly. Only the `x-nonce` half is unconsumed.

**Recommendation:** Decide, in one line. If a `<Script nonce={...}>` consumer is planned, add `// consumer: <path>` now. If not, delete `proxy.ts:51–53` and its two tests — the `NextResponse.next({ request })` wrapper stays either way, because the CSP request header needs it.

---

#### M2. Server-runtime module still tested under jsdom — but `2544a19` narrows what this risks

**Severity:** Minor (risk narrowed this iteration; grade held)
**Location:** `proxy.test.ts:1–3`; `vitest.config.ts:8`
**Move:** Substitutability — test environment vs deployment runtime
**Confidence:** High
**Status:** Carried from iteration 2, **recharacterized**.

**Evidence:**

```
    environment: 'jsdom',
```
(`vitest.config.ts:8`, applied globally) — `rg -n "vitest-environment" --glob '*.test.*'` → **no hits**, so `proxy.test.ts` inherits jsdom.

```
  // Generate a fresh nonce per request. Next 16 proxy always runs on the
  // Node.js runtime, where crypto.randomUUID and Buffer are both available.
```
(`proxy.ts:38–39`, as amended by `2544a19`)

**Legibility-target:** for-author

I am revising this finding down in substance, and I want to be explicit that the revision is in the change's favour. Iteration 2 argued this was "a fidelity gap in exactly the belief the comment asserts," because the comment claimed an Edge runtime while the test ran on Node-backed jsdom — so the test could not distinguish "available in the deployed runtime" from "available in the test harness," and the deployed runtime as described was the one where `Buffer` is genuinely doubtful.

`2544a19` corrects that comment: Next 16 proxy always runs on Node.js. Deployment runtime and test runtime are therefore both Node, and the globals the module depends on (`crypto.randomUUID`, `Buffer`) really are present in production for the reason now stated. The fidelity gap that iteration 2 described is largely gone — this is a case where a comment-only fix genuinely reduced architectural risk, because the comment was the artifact carrying the wrong belief.

What remains is smaller and is why I hold the grade rather than dropping the finding: `proxy.ts` is still the only server-runtime module in a suite whose global environment is a browser emulator, and the correctness of that arrangement is now an inference a reader has to make (jsdom runs on Node, therefore Node globals leak through) rather than something the file states. Every other test file in the repo tests DOM-facing code, so the global default is right for them; `proxy.test.ts` is the one file for which it is incidental.

**Recommendation:** Unchanged and still one line: `// @vitest-environment node` at the top of `proxy.test.ts`. It is now easier to justify than it was in iteration 2, because the file's own comment names the runtime it should be matching.

---

#### M3. The relocated export failure boundary still has no owner

**Severity:** Minor
**Location:** `app/lib/utils/exportGraph.ts:25–27, 54, 65`
**Move:** Responsibility boundaries — error ownership
**Confidence:** High (re-verified at HEAD)
**Status:** Carried unchanged from iteration 2.

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
(`app/lib/utils/exportGraph.ts:54`)

Executed at HEAD: `rg -n "try|catch" app/lib/utils/exportGraph.ts` → **no hits**. Neither call site (`:54`, `:65`) catches.

**Legibility-target:** for-author

Before the R2 fix, an export failure surfaced as a rejected `fetch` inside an `async` function. After it, it surfaces as a synchronous `throw` from the decoder (or from `atob` on malformed base64) propagating out of the same `async` functions as the same uncaught rejection. User-visible behaviour is identical — click, nothing happens, no message — and the module still nominates no owner. Worth restating in the final pass so the R2 fix is not read as having addressed it: the throw site moved, the ownership question did not.

**Recommendation:** Out of this diff's scope to build an error UI, but pick the owner and write it in the docblock. If the call sites will own it: `// throws on malformed input — callers must catch`, so the next person adding a call site sees the obligation.

---

#### I1. `force-dynamic` keeps the rendering-mode decision at the widest possible scope

**Severity:** Informational
**Location:** `app/layout.tsx:26`
**Move:** Extension points
**Confidence:** High
**Status:** Carried unchanged from iteration 2.

**Evidence:** `export const dynamic = "force-dynamic";` (`app/layout.tsx:26`) — the app's only route-segment config (`rg -n "export const dynamic|export const runtime" app/` → one hit).

**Legibility-target:** for-orchestrator-synthesis

Every page route, present and future, renders per request because a security control needs it. Any future route wanting static rendering must override at its own segment and silently loses nonce freshness in doing so. Route handlers under `app/api/` are unaffected (segment config in a layout does not apply to them), so the blast radius is pages only.

This is the correct trade if per-request nonces are a hard requirement — flagged only so the cost is attributed to this decision rather than rediscovered later as an unexplained TTFB regression. The extension point that does not exist: there is no way to declare "this route is static and therefore exempt from nonce-based CSP" without editing two files that do not reference each other.

**Recommendation:** No action in this diff. Record the trade in the decision record (I2).

---

#### I2. The control spans four files, three of them documented only by comments, with no decision record

**Severity:** Informational
**Location:** `docs/decisions/`; `CLAUDE.md`
**Move:** Module boundary audit — discoverability
**Confidence:** High (re-verified at HEAD)
**Status:** Carried from iteration 2, **strengthened** by C5.

**Evidence:** `ls docs/decisions` → eight records (`001-formal-artifact-types`, `001-vitest-test-framework`, `002-multi-artifact-ui-layout`, `003-artifact-generation-api`, `004-generalized-decomposition`, `005-streaming-api-responses`, `005-zustand-state-management`, `007-cost-estimation-model`) — none about CSP, headers, or rendering mode. `rg -ni "csp|proxy\.ts|content-security" CLAUDE.md` → one unrelated hit at `CLAUDE.md:37` (the panels list). No `docs/ARCHITECTURE.md` in the tree.

**Legibility-target:** for-orchestrator-synthesis

This was already the recommendation in iteration 2; C5 upgrades it from good hygiene to the actual fix for a defect that has now occurred once. The mechanism spans `proxy.ts` + `proxy.test.ts` + a rendering-mode contract in `app/layout.tsx` + a utility whose existence is justified by the policy — four files that must move together, documented in four comments that reference each other only in prose, one of which has already drifted into contradiction and had to be repaired by a review pass. A decision record is the artifact that lets the next reader learn the whole mechanism without reverse-engineering it from comments of unproven reliability, and it is the natural owner for the facts C5 says currently have none.

**Recommendation:** One record — `docs/decisions/NNN-content-security-policy.md` — covering: nonce delivery via the request header and why response-only fails under `'strict-dynamic'`; the `force-dynamic` consequence and its cost (I1); the `style-src 'unsafe-inline'` carve-out and its actual dependents (C5); and the `connect-src 'self'` constraint that shapes `dataUrlToBlob` (C4). Add `proxy.ts` to `CLAUDE.md`'s file inventory.

---

## What Looks Good

- **The commit does exactly what it says and nothing more.** `git show --stat 2544a19` → one file, 8 insertions / 5 deletions, every changed line inside a comment. For a cross-cutting security control on a final pass, a comment-only commit that cannot move a test outcome is the right shape of change, and the message says so explicitly rather than leaving a reviewer to verify it.
- **A comment-only fix that genuinely reduced architectural risk.** The Edge-runtime correction at `proxy.ts:38–39` is not cosmetic: the comment was the stated justification for the two runtime APIs on the next line, so a contributor extending the proxy would have ruled APIs in or out from the wrong runtime. Correcting it also retires most of M2's substance (see that finding). Comment fixes rarely earn this note; this one does.
- **The R1 falsifier remains real.** `proxy.test.ts:80–87` asserts the forwarded request header *equals* the response header — precisely the belief whose falseness caused R1 — and the prior pass confirmed it fails when the wiring line is disabled. Three iterations on, it is still the most valuable artifact in the diff.
- **`buildCsp`'s seam is minimal and pure.** One string in, one string out; no injected clock, crypto, or config; no framework types in the signature. The directive-set test (`proxy.test.ts:34–48`) asserts the *exact* key set rather than the presence of a few directives, so a silently dropped directive fails.
- **Dependency direction on the app side is clean and has stayed clean.** `proxy.ts` imports only `next/server`; nothing under `app/` imports `proxy.ts` (re-verified at HEAD). Exporting `buildCsp` introduced no cycle, and three iterations of edits have not created one.
- **Test placement follows the repo convention throughout.** All 26 other test files sit beside their subject; `proxy.test.ts` at the root does the same for a root-level module and picks up the default vitest include with no config change.
- **`dataUrlToBlob`'s test suite targets the right failures.** Binary safety (`0xff 0xfe 0xfd` round-trip), media-type parameter stripping, the percent-encoded branch, and the rejection path — the four things a hand-rolled codec gets wrong.

## Summary Table

| # | Finding | Severity | Location | Status | Legibility-target |
|---|---------|----------|----------|--------|-------------------|
| — | *(none)* | **Structural** | — | **No Structural findings in this range** | — |
| C1 | Layout half of the nonce control is untested; no test file in the repo imports `app/layout.tsx` | Coupling | `app/layout.tsx:21–26`; `proxy.test.ts` | Carried, unchanged | for-author |
| C2 | Falsifier pinned to Next-private `x-middleware-request-*` protocol; no version signpost or triage rule | Coupling | `proxy.test.ts:5–22` | Carried, unchanged | for-author |
| C3 | CSP policy exported from the framework entry file rather than a security module; inverts import direction | Coupling | `proxy.ts:22` | Carried, unchanged | for-author |
| C4 | Generic `data:` codec inside a module that exists to be code-split away | Coupling | `app/lib/utils/exportGraph.ts:1–7, 16–44` | Carried, unchanged | for-author |
| C5 | **New.** Predicted rationale drift occurred; repair hand-synced a second copy instead of giving the fact an owner | Coupling | `proxy.ts:12–17` vs `proxy.test.ts:59–61`; `exportGraph.ts:18–21` | New this iteration | for-author |
| M1 | `x-nonce` has two tests and still zero consumers | Minor | `proxy.ts:51–53`; `proxy.test.ts:88–108` | Carried, unchanged | for-author |
| M2 | Server-runtime module tested under global jsdom; risk narrowed by the runtime-comment correction | Minor | `proxy.test.ts:1–3`; `vitest.config.ts:8` | Carried, recharacterized | for-author |
| M3 | Export failure boundary relocated but still unowned; no `try`/`catch` at either call site | Minor | `app/lib/utils/exportGraph.ts:25–27, 54, 65` | Carried, unchanged | for-author |
| I1 | Rendering-mode decision remains at the root layout; cascades to every future page route | Informational | `app/layout.tsx:26` | Carried, unchanged | for-orchestrator-synthesis |
| I2 | Control spans four files with no decision record and no inventory entry | Informational | `docs/decisions/`; `CLAUDE.md` | Carried, strengthened by C5 | for-orchestrator-synthesis |

## Overall Assessment

**There is nothing Structural in `d86d2dc..2544a19`.** I state that as a positive finding, not an absence of effort: I re-ran the dependency-direction, module-boundary, and layer checks against HEAD rather than inheriting iteration 2's verdict, and the results hold — `proxy.ts` imports only `next/server`, nothing under `app/` imports `proxy.ts`, no cycle exists, no layer is breached, and the one inversion I can name (C3, a framework entry file owning a policy) has no consumer paying for it yet.

**On this iteration's commit specifically:** `2544a19` is comment-only, so by construction it could not change the structure, and it did not. It did two useful things and one thing worth flagging. Useful: it corrected the runtime claim that was the stated justification for two API choices, which retires most of M2's substance — a rare case of a comment fix reducing real architectural risk. Also useful: it aligned the contradictory `style-src` rationales so the repo no longer states two incompatible things about one directive. Worth flagging: *how* it aligned them. It re-typed the correct text into one of two unlinked copies, which resolves today's contradiction and preserves the mechanism that produced it. That is C5, the only new finding here.

**The through-line across all three iterations is unchanged and is worth naming plainly at the close:** the fixes have been scoped to the modules the reviews named rather than the invariants the reviews described. C1 is the clearest case — the falsifier covers `proxy.ts` because that is where iteration 1's finding pointed, while the half of the control living in `app/layout.tsx` has now gone three iterations with no test that even loads it. C3 is the same pattern at module scope (the rubric offered "export it *or* move it"; export was smaller). C4 is it at placement scope. C5 is it at the documentation scope. Each individual choice was locally reasonable and cheap; the aggregate is a control whose structure is sound and whose edges are unpinned.

**Priority for any follow-up, unchanged from iteration 2 because nothing addressed it:** **C1** first and alone if only one thing is done — it is the single item in this review whose failure is silent under a fully green suite, and its fix is one small test file. Then **C3 + C4 together** (both are moves, both cheapest now, and doing them together gives `app/lib/security/` and `app/lib/utils/dataUrl.ts` an obvious shape). Then **I2**, which now subsumes **C5**: a decision record is the durable owner for the four CSP facts that currently live in comments, one of which has already drifted once. **M1** is a thirty-second decision. **M2** and **M3** are one-line comments each.

**Verdict for the final pass:** no Structural defect, five Coupling items (four carried, one new), three Minor, two Informational. None of them blocks the change. C1 is the one I would not ship a follow-up sprint without.

### Cross-reference to `security-review.md` (this pass)

`security-review.md` landed in this directory before this review was finalized, so its Trust Boundary Map (TB1–TB6) applies. Mapping my findings onto its labels — this is a cross-reference, not a re-grading; every severity below is mine and every boundary label is theirs:

| # | Boundary | Relationship |
|---|----------|--------------|
| C1 | **TB2** | The map names `export const dynamic = "force-dynamic"` (`app/layout.tsx:26`) as *the control at TB2* — "keeps one nonce bound to one response." C1 is precisely that named control having no test that loads it. Security calls TB2 "now sound"; that is a correct reading of the *mechanism*. C1 is about the mechanism's **retention**, not its correctness — the boundary is sound and one deletion in a cleanup pass silently unsounds it. The two assessments are compatible and should be read together, not as a disagreement. |
| C3 | **TB3** | TB3 is where `buildCsp` (`proxy.ts:22–35`) "actually becomes a control," and the map notes that whatever it omits is unenforced for the document's lifetime. C3 says the owner of that policy is a framework entry file, so any second writer at TB3 (a `next.config.ts` `headers()` entry, a Report-Only rollout) must import from it. C3 is the structural precondition for TB3 having exactly one owner. |
| C5 | **TB3 / TB4** | The `style-src` rationale C5 tracks documents a TB3 policy decision; the docblock at `proxy.ts:9–10` that the map cites as naming **TB4** is in the same comment block. Both are the comment-owned facts C5 says have no single home. Security's own Informational #10 covers the revised `style-src` rationale from the policy-correctness side; C5 covers the same text from the ownership side. |
| C4 | **TB5** | Same code, different lens. The map treats TB5 as a data-flow boundary (media-type segment → Blob `type` → object-URL Content-Type). C4 is about where that boundary's implementation *lives* — inside a module that exists to be code-split away. Neither finding depends on the other. |
| M1 | **TB1 → TB2** | The map lists the `x-nonce` overwrite at `proxy.ts:53` as a control at TB1 and as a value crossing TB2. M1 does not dispute that the overwrite is correct; it observes that the header has no reader at the far side of TB2, so the control guards a contract nothing consumes. If M1 is resolved by deletion, TB1's control list and TB2's crossing list both shrink by one — worth flagging to synthesis so the two reviews stay consistent. |
| I1 | **TB2** | The blast radius I1 describes (every page route renders per request) is the cost of the TB2 control being declared at the root layout. TB6 (`app/api/*` outside the matcher) is the complementary exemption; segment config in a layout does not reach route handlers, which is why I1's scope is pages only. |

One note where the two reviews genuinely diverge in emphasis rather than substance: security's map says TB1 "decides whether the request reaches TB3 at all" using client-set headers, and grades that Medium. I did not raise the matcher as an architecture finding (it is scoped out below), but it is the same ownership question as C3 seen from the boundary side — the matcher and the policy are two halves of one control living in one framework entry file. If C3's move to `app/lib/security/` is taken, the matcher is the piece that must deliberately *stay* in `proxy.ts`, and saying so explicitly at that time would keep security's TB1/TB3 split legible.

## Goal-Alignment Note

- **Answered:** All eight requested architecture moves, re-run against HEAD rather than inherited. Dependency direction (C3; plus the re-verified clean `app/` → `proxy.ts` non-edge and absence of cycles). Responsibility boundaries (C4, C5, M3). Module boundary audit (C3, I2). Layer violations (C3 is the only inversion found; no `app/` layer breach). Interface segregation (M1, C4). Substitutability (M2, revised in the change's favour after the runtime-comment correction). Coupling-surface audit (C1, C5). Extension points (I1). The brief's direct question — whether anything Structural exists — is answered explicitly in the Headline, the Summary Table's first row, and the Overall Assessment: **no**. The brief's note that `2544a19` changed comments only was verified independently (`git show --stat` plus hunk inspection) rather than accepted. All four prior-rubric Coupling items C1–C4 were re-verified individually at HEAD with executed enumerations rather than carried on assertion; each is marked Carried/unchanged with its evidence re-quoted. `security-review.md` for this pass was present at finalization, so every finding is cross-referenced to its Trust Boundary Map (TB1–TB6) in the section above, including the one place the two reviews reach different-sounding verdicts on TB2 and why they are compatible.
- **Out of scope:** Whether the policy is *correct* as security — the matcher's prefetch exemption and unanchored prefixes, client-supplied `content-security-policy` request-header stripping, missing `form-action`/`worker-src`, cache and `Vary` interactions — all security-reviewer's domain, and all carried in the prior pass as A1 and security #1/#6; I touch the matcher only where it bears on ownership (C3). Comment-accuracy grading (the OpenAlex mention at `proxy.ts:19`, the remaining commit-message staleness waived as R2) — fact-check's domain; I use the *fact* of the repaired drift as structural evidence in C5 without re-grading any claim. TTFB and bundle-size magnitudes for I1 and C4 — performance-reviewer's domain; I flag the structural cascade, not the number. `dataUrlToBlob`'s decoding correctness on edge inputs, its naming and signature conventions — api-consistency's domain. The absent export-error UI — ui-visual's domain; M3 covers only the unassigned ownership.
- **Escalate:** **C1**, unchanged and now for the third consecutive iteration, on the same grounds: its consequence — a security control silently disabled by a plausible cleanup under a fully green suite — matches the consequence class that made iteration 1's R3 and R4 red, even though I grade the finding itself Coupling because the mechanism is declarative rather than incidental. I am not escalating it by convergence or by repetition; the native severity remains Coupling and that is the one that should govern. What I am asking the orchestrator to weigh on a *final* pass is that this item has survived two full fix cycles untouched while cheaper items were taken, and its fix is a single small test file. Also flag for synthesis: **C5 is the first finding in this arm that is caused by a previous fix's method rather than by the original change**, which is the loop-quality signal this experiment is looking for — the repair was correct in content and structurally inert, so a rubric that scores only whether findings were addressed would score it clean.
