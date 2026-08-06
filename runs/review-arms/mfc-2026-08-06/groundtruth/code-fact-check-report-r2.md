# Code Fact-Check Report

**Repository:** /workspace/external/meta-formalism-copilot
**Scope:** HEAD~3..HEAD (commits 4d5f743, 2e23824, c0e0a35; merge 7f30210)
**Checked:** 2026-08-06
**Total claims checked:** 20
**Summary:** 14 verified, 3 mostly accurate, 0 stale, 0 incorrect, 3 unverifiable
**Commit:** 7f30210

---

## Claim 1: "Safe to spread: allWorks holds at most PER_QUERY_RESULTS per query — worst case MAX_OVERRIDE_QUERIES (5) queries on the override path (25), fewer on the LLM path (≤3 queries → 15). Well under the arg-count limit."
**Location:** `app/api/evidence-search/route.ts:178-180`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
Every number checks out against the code that exercises the spread:
- `PER_QUERY_RESULTS = 5` exists (`app/api/evidence-search/route.ts:20`) and is actually enforced at the fetch site: `url.searchParams.set("per_page", String(PER_QUERY_RESULTS))` (`route.ts:114`), so each `searchOpenAlex` call returns at most 5 works (trusting OpenAlex to honor `per_page`).
- `MAX_OVERRIDE_QUERIES` exists with value 5 — `export const MAX_OVERRIDE_QUERIES = 5;` (`app/api/evidence-search/querySanitize.ts:9`) — and the override path is genuinely capped there: `sanitizeQueries` breaks out of its loop with `if (cleaned.length >= MAX_OVERRIDE_QUERIES) break;` (`querySanitize.ts:20`). Worst case 5 × 5 = 25.
- The LLM path is genuinely ≤3 queries: `generateSearchQueries` returns `parsed.queries.slice(0, 3)` (`route.ts:94`), and all three fallback branches return a single-element array `[elementContent.slice(0, 100)]` (`route.ts:87,92,96`). So ≤3 × 5 = 15.
- `allWorks` is populated only from fulfilled `Promise.allSettled` results (`route.ts:168-173`) and spread at `Math.max(...allWorks.map(...), 1)` (`route.ts:181`). 25 arguments is orders of magnitude below JS engine argument-count limits (~65k+).
Minor note (not an inaccuracy): `MAX_OVERRIDE_QUERIES` is defined in `querySanitize.ts` and is not imported into `route.ts`, so a reader of this file alone must follow `sanitizeQueries` to confirm the bound — the cross-file reference is nonetheless accurate.
**Evidence:** `app/api/evidence-search/route.ts:20`, `route.ts:94`, `route.ts:114`, `route.ts:168-173`, `route.ts:181`, `app/api/evidence-search/querySanitize.ts:9,20`

---

## Claim 2: "Regression: partial-JSON streaming can yield a tension object before its `between` tuple has arrived. Indexing `between[0]` on undefined threw a runtime TypeError that crashed the whole panel."
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The pre-fix code (removed side of the c0e0a35 diff) indexed unguarded: `<span>{t.between[0]}</span>` with no check on `t.between`, so a tension object lacking `between` throws `TypeError: Cannot read properties of undefined (reading '0')` during render. The streaming premise is real: the panel accepts `streamingPreview` documented as "Partial map data from streaming (partial-JSON parsed)" (`BalancedPerspectivesPanel.tsx:12-13`), the `partial-json` package is a dependency (`package.json:26`), and `page.tsx:994` wires `streamingJsonPreview["balanced-perspectives"]` into the panel — partial-JSON parsing can surface `{description: ...}` before the `between` array closes. "Crashed the whole panel" is accurate: the throw happens inside the panel's render function with no error boundary between the tensions map and the panel root, so React unmounts the whole subtree.
**Evidence:** `git diff HEAD~3..HEAD -- app/components/panels/BalancedPerspectivesPanel.tsx` (removed `<span>{t.between[0]}</span>` block), `app/components/panels/BalancedPerspectivesPanel.tsx:12-13,110-121`, `app/page.tsx:994`, `package.json:26`

---

## Claim 3: "`between` absent mid-stream — the static type marks it required, so cast."
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The tension type declares the tuple as required (no `?`, no `undefined` in the union): `between: [string, string];` (`app/lib/types/artifacts.ts:100`). Constructing a tension without it therefore does require the `as unknown as Tension` cast used in the test.
**Evidence:** `app/lib/types/artifacts.ts:100`, `app/components/panels/BalancedPerspectivesPanel.test.tsx:49`

---

## Claim 4: "The description still renders even though the endpoints aren't ready."
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
In the fixed component, only the endpoints row is inside the `t.between && (...)` guard (`BalancedPerspectivesPanel.tsx:113-119`); the description `<p className="mt-1 text-xs text-red-800">{t.description}</p>` sits outside it (`line 120`) and renders unconditionally. The test can observe it despite `CollapsibleSection defaultOpen={false}` because `CollapsibleSection` always renders children and merely hides them with `display: none` — "Always render children to preserve internal state" / `<div style={open ? undefined : HIDDEN_STYLE}>{children}</div>` (`app/components/ui/CollapsibleSection.tsx:50-51`) — and Testing Library's `getByText` matches display-hidden elements.
**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-120`, `app/components/ui/CollapsibleSection.tsx:13,50-51`

---

## Claim 5: "Guard the endpoints row on `t.between` (matching the optional chaining already used for every other streamed field)"
**Location:** commit `c0e0a35` (message), re: `app/components/panels/BalancedPerspectivesPanel.tsx:113`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
The spirit is right, the letter overstates on two counts. (1) The added guard is a truthiness conditional-render (`{t.between && (...)}`), not optional chaining — consistent with the component's *object/section* guards (`displayMap.topic &&`, `displayMap.summary &&`, `displayMap.synthesis &&`) rather than with its optional chaining, which is used on arrays (`displayMap.tensions?.map`, `perspectives?.map`, `supportingArguments?.map`, `howAddressed?.map`). (2) Not "every other streamed field" is guarded: `t.description` (line 120), `p.label`, `p.coreClaim` (lines 74, 76), and `synthesis.equilibrium` (line 133) render unguarded — safe only because rendering `undefined` as text can't throw, unlike indexing into it. The narrow reading that "every other field whose absence could throw is already guarded" is true; the literal reading is not.
**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:46,56,66-69,74,76,107-113,120,129,133`

---

## Claim 6: "Adds a regression test that reproduces the exact TypeError without the guard."
**Location:** commit `c0e0a35` (message), re: `app/components/panels/BalancedPerspectivesPanel.test.tsx:52-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
By code reading, the test does exercise the crashing path: the missing-`between` tension flows through `makeData` (topic `"Test topic"` makes `hasContent` truthy via `!!d.topic`, `mergeStreamingPreview.ts:13-14`), `ArtifactPanelShell` is mocked to render children when `hasData`, `EditableSection` is mocked pass-through, and `CollapsibleSection` (not mocked) always renders children (`CollapsibleSection.tsx:50-51`) — so without the guard, `t.between[0]` executes and throws the TypeError during `render()`, failing the `expect(...).not.toThrow()` assertion. Confidence is Medium rather than High for two reasons: (a) I could not execute the suite — `node_modules` is not installed in this checkout, so `vitest` cannot run; (b) the test asserts only that render does not throw — it never asserts the TypeError's message, so "the exact TypeError" is reproduced by the *scenario*, not pinned by an assertion.
**Evidence:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:7-14,52-56`, `app/lib/utils/mergeStreamingPreview.ts:13-14`, `app/components/ui/CollapsibleSection.tsx:50-51`; paraphrased — no quote available for test execution because the repo has no installed `node_modules` (vitest run fails with module-not-found).

---

## Claim 7: "landed directly on integration/6.1 per user direction (panel is not on main and no in-flight feature branch owns it)."
**Location:** commit `c0e0a35` (message, Notes)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
`git log origin/main -- app/components/panels/BalancedPerspectivesPanel.tsx` returns no commits — the panel file has never existed on `origin/main`. The branch listing (`git branch -a`) contains no branch whose name references balanced-perspectives or this panel; the commit is the tip work of `integration/6.1`, the checked-out branch. "No in-flight feature branch owns it" is verified only against branch names and origin refs — a local-only branch elsewhere can't be ruled out, hence Medium.
**Evidence:** `git log origin/main -- app/components/panels/BalancedPerspectivesPanel.tsx` (empty), `git branch -a` output (no matching branch); paraphrased — no quote available because the evidence is the absence of matching git refs/log entries.

---

## Claim 8: "Persists to localStorage with debounced writes (see the debounced storage adapter below) to avoid excessive serialization on rapid updates."
**Location:** `app/lib/stores/evidenceStore.ts:8-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The adapter referenced "below" exists and does what's claimed: `createDebouncedStorage()` (`evidenceStore.ts:20-41`) implements `setItem` as `clearTimeout(pending); pending = setTimeout(() => { localStorage.setItem(name, value); ... }, 300)` — a genuine trailing-edge 300 ms debounce writing to `localStorage`. It is wired into the store via `storage: typeof window !== "undefined" ? createJSONStorage(() => debouncedStorage) : undefined` (`evidenceStore.ts:355-357`), so persisted writes really flow through the debounce. Reads (`getItem`) are synchronous/undebounced, which the comment doesn't claim otherwise.
**Evidence:** `app/lib/stores/evidenceStore.ts:20-41`, `evidenceStore.ts:48`, `evidenceStore.ts:355-357`

---

## Claim 9: "evidenceStore: drop the unverifiable 'same pattern as workspaceStore' parity claim; describe the debounced-write behavior directly."
**Location:** commit `4d5f743` (message), re: `app/lib/stores/evidenceStore.ts:8-9`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
The parity claim was dropped from the module docstring (lines 8-9 now describe the debounce directly), but an identical parity claim survives eight lines below, in the section header the new docstring points readers at: `// Debounced localStorage adapter (same pattern as workspaceStore)` (`evidenceStore.ts:17`). So the drift the commit set out to remove is only half-removed. Separately, calling the claim "unverifiable" is itself an overstatement today: `workspaceStore` uses a debounced localStorage adapter "moved verbatim from workspaceStore.ts" with the same 300 ms debounce (`app/lib/corpus/storeAdapter.ts:33-46`, wired via `workspaceStore.ts:530`), so the parity is currently checkable and true — though it is a cross-file coupling that could silently drift, which is a fair reason to remove it.
**Evidence:** `app/lib/stores/evidenceStore.ts:8-9,17`, `app/lib/corpus/storeAdapter.ts:33-46`, `app/lib/stores/workspaceStore.ts:5,530`

---

## Claim 10: "Resolves review items A1/A2 (fact-check Mostly-Accurate comment nits)."
**Location:** commit `4d5f743` (message)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
No review artifact in this repository contains A1/A2 items matching these two comment fixes. The committed `docs/reviews/code-review-rubric.md:19-20` does define items labeled A1/A2, but they are unrelated corpus-branch findings (`WorkspaceManifest.customTypeIds` naming; `state/<name>.json` namespace) — a reader following the reference lands on the wrong items. The intended source review appears to be the uncommitted session artifacts that sibling commit c0e0a35's notes mention ("Review docs in docs/reviews/ left uncommitted"), which are not present in this working tree. The *substance* is consistent — both changed comments are exactly "Mostly-Accurate comment nit" material — but the A1/A2 identifiers cannot be resolved against anything in the repo.
**Evidence:** `docs/reviews/code-review-rubric.md:19-20`; paraphrased — no quote available because the referenced review document does not exist in the repository (search of `docs/` for matching A1/A2 items found only unrelated corpus-branch items).

---

## Claim 11: "comment-only; lint clean, no behavior change."
**Location:** commit `4d5f743` (message, Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
The diff for 4d5f743 touches exactly two files and every changed line is inside a comment block (`route.ts` lines 178-180 comment text; `evidenceStore.ts` lines 8-9 docstring text) — "comment-only" and "no behavior change" are verified directly from the diff. "Lint clean" could not be re-executed (no `node_modules` in this checkout), but comment-text edits cannot introduce ESLint findings under this repo's config in any plausible way; confidence Medium only because the lint run itself wasn't reproduced.
**Evidence:** `git show 4d5f743` (5 insertions / 4 deletions, all comment lines), `app/api/evidence-search/route.ts:178-180`, `app/lib/stores/evidenceStore.ts:8-9`

---

## Claim 12: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."
**Location:** `proxy.ts:18-19`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
I enumerated every client-side network initiation across the app rather than trusting the file:
- All `fetch` calls in client components/hooks target relative same-origin paths: `/api/analytics`, `/api/explanation/lean-error`, `/api/refine/context`, `/api/verification/lean`, `/api/formalization/*`, `/api/edit/*`, `/api/evidence-*`, `/api/decomposition/extract`, `/api/custom-type/design` (e.g. `app/lib/formalization/api.ts:121,142,158,167,180`, `app/hooks/useAnalytics.ts:11,30`, and the full grep of `"/api/` across `app/hooks` + `app/components`).
- The only absolute third-party URL fetched in code is `OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions"` (`app/lib/llm/callLlm.ts:7`), and `callLlm`/`streamLlm` are imported only by API routes and the server-side `app/lib/formalization/artifactRoute.ts`; the client-side `app/lib/formalization/api.ts` imports only the *type* (`import type { LlmCallUsage }`, `api.ts:3`). OpenAlex is fetched in `app/api/evidence-search/route.ts:117` (server). No Anthropic endpoint is fetched client-side.
- No `WebSocket`, `EventSource`, `XMLHttpRequest`, or `navigator.sendBeacon` usage exists anywhere under `app/` (grep returned nothing).
- Export/download utilities do not fetch `data:`/`blob:` URLs: text export uses `Blob` + `URL.createObjectURL` on an anchor (`app/lib/utils/export.ts:3,8` — anchor navigation, not connect-src), and graph export deliberately avoids the fetch path: "Use toBlob (not toPng + fetch) so we don't need `data:` in CSP connect-src." (`app/lib/utils/exportGraph.ts:6`).
- The pdf.js worker is bundled same-origin via `new URL("pdfjs-dist/build/pdf.worker.min.mjs", import.meta.url)` (`app/lib/utils/fileExtraction.ts:26-29`, `pdfPropositionParser.ts:443-446`), not loaded from a CDN. DOI links on paper cards (`EvidencePaperCard.tsx:25`) are `<a href>` navigations, not connections.
**Evidence:** `app/lib/llm/callLlm.ts:7`, `app/lib/formalization/api.ts:3,121-180`, `app/lib/formalization/artifactRoute.ts:2-4`, `app/lib/utils/export.ts:3-8`, `app/lib/utils/exportGraph.ts:6-7`, `app/lib/utils/fileExtraction.ts:25-29`, grep of `app/` for `fetch(`/`WebSocket`/`EventSource`/`XMLHttpRequest`/`sendBeacon`

---

## Claim 13: "Next.js's dev server (HMR + eval source maps) injects `eval()`-based code that a strict CSP blocks, flooding the browser console with EvalErrors."
**Location:** `proxy.ts:21-23`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
This is a claim about Next.js framework internals, not repo code, and cannot be confirmed from this checkout (no `node_modules`, no runnable dev server). It matches widely documented Next.js behavior — webpack/turbopack dev builds default to `eval`-family source maps, and the dev-only `'unsafe-eval'` carve-out is the standard published remedy — and nothing in the repo contradicts it, but no repo-local evidence can establish it. Paraphrased — no quote available because the claim concerns external framework runtime behavior not present in the repository.
**Evidence:** paraphrased — no quote available (external framework behavior; `node_modules` not installed).

---

## Claim 14: "Production output is genuinely eval-free"
**Location:** `proxy.ts:23-24`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
What I could verify supports it: a grep of all first-party code (`app/`, `proxy.ts`, config) finds zero uses of `eval(` or `new Function` (the only hit is this docstring's own mention of `eval()`), and Next.js production builds are documented to avoid eval-based source maps. What I could not verify: the actual production bundle (no `node_modules` installed, so `npm run build` is unavailable) and third-party client dependencies — notably `pdfjs-dist` (`package.json:27`), which upstream is known to optionally use `new Function` for PostScript/font compilation at runtime behind an eval-support feature test with a non-eval fallback; the installed copy could not be inspected. So the claim is plausible and unlikely to be false in a user-visible way (pdf.js degrades gracefully under a no-eval CSP), but "genuinely eval-free" as a statement about production runtime behavior is not established by repo evidence.
**Evidence:** grep of `app/`, `proxy.ts`, `next.config*` for `eval(`/`new Function` (single hit: `proxy.ts:22`, the docstring itself); `package.json:27`; paraphrased — no quote available for the bundle claim because no production build or installed dependencies exist in this checkout.

---

## Claim 15: "`'unsafe-eval'` is added only when NODE_ENV !== \"production\"."
**Location:** `proxy.ts:24` (docstring), mechanism at `proxy.ts:26-32`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The mechanism is a default parameter: `allowUnsafeEval: boolean = process.env.NODE_ENV !== "production"` (`proxy.ts:28`), and `'unsafe-eval'` is appended to `script-src` only when that flag is truthy (`proxy.ts:30-32`). Call-site audit: the only production call site is `proxy.ts:53` — `const csp = buildCsp(nonce);` — which omits the argument and therefore uses the NODE_ENV-derived default; the only other callers are the tests, which pass explicit `false`/`true` (`proxy.test.ts:12,37`). So in the deployed proxy, the directive's presence is governed exactly by `NODE_ENV !== "production"`. (Note the flag is *added-when-not-production*, i.e. fail-open for unset/nonstandard NODE_ENV — see Claim 16 — but that is precisely what this sentence, read literally, says.)
**Evidence:** `proxy.ts:26-32`, `proxy.ts:53`, `proxy.test.ts:12,37`, grep for `buildCsp` (no other call sites outside docs)

---

## Claim 16: "fix(csp): allow 'unsafe-eval' in development only" / "buildCsp now adds 'unsafe-eval' to script-src only when NODE_ENV !== \"production\""
**Location:** commit `2e23824` (title + message)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
The message body's NODE_ENV formulation is exact (see Claim 15). The title's "in development only" is true only under a narrow reading: the condition is `NODE_ENV !== "production"`, which also enables `'unsafe-eval'` when NODE_ENV is unset, `"test"`, `"staging"`, or any custom value — not only `"development"`. In standard Next.js deployment (`next build`/`next start` and Vercel force `NODE_ENV=production`) the two readings coincide, but a nonstandard runtime that fails to set NODE_ENV gets the weakened CSP in production. The docstring and test name carry the same "development only" shorthand (`proxy.ts:21`, `proxy.test.ts:36`).
**Evidence:** `proxy.ts:28`, `proxy.ts:21`, `proxy.test.ts:36`, commit message of `2e23824`

---

## Claim 17: "Pin the production CSP explicitly so these assertions don't depend on the ambient NODE_ENV the test runner happens to set."
**Location:** `proxy.test.ts:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
`buildCsp(NONCE, false)` (`proxy.test.ts:12`) passes the second argument explicitly, so the default initializer `process.env.NODE_ENV !== "production"` (`proxy.ts:28`) — the only place `buildCsp` reads NODE_ENV — is never evaluated for this value. Default parameters in JS apply only when the argument is `undefined`; `false` is not. The dev-mode test likewise pins `buildCsp(NONCE, true)` (`proxy.test.ts:37`). Every assertion in the file operates on these two pinned outputs, so the suite's results are independent of ambient NODE_ENV, exactly as claimed.
**Evidence:** `proxy.test.ts:12,37`, `proxy.ts:26-32`

---

## Claim 18: "'unsafe-eval' must remain scoped to script-src — never leaks elsewhere." (comment describing what the adjacent assertion establishes)
**Location:** `proxy.test.ts:44-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The scoping property is established by the *pair* of assertions in this test, not the count check alone: line 41-43 asserts the full `script-src` directive equals a string containing `'unsafe-eval'` (`expect(devScriptSrc).toBe(\`script-src 'self' 'nonce-${NONCE}' 'strict-dynamic' 'unsafe-eval'\`)`), proving one occurrence lies inside `script-src`; line 45 asserts `devCsp.match(/'unsafe-eval'/g)` has length exactly 1, proving there are no other occurrences anywhere in the CSP string. One occurrence total + that occurrence inside script-src ⇒ it appears nowhere else. The comment accurately describes what the assertion (in context) establishes.
**Evidence:** `proxy.test.ts:37-45`

---

## Claim 19: "the strict CSP from #143"
**Location:** commit `2e23824` (message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The referenced PR exists in history: commit `9581518` is titled "feat: strict Content-Security-Policy with per-request nonces (#143)", and it introduced the strict CSP that `2e23824` relaxes for dev (the `buildCsp` in `proxy.ts` predating this range had no `'unsafe-eval'` anywhere, per the removed side of the `2e23824` diff).
**Evidence:** `git log --all --oneline` (`9581518 feat: strict Content-Security-Policy with per-request nonces (#143)`), `git show 2e23824 -- proxy.ts`

---

## Claim 20: "buildCsp gained an explicit allowUnsafeEval param (defaulted from NODE_ENV) so the test pins both prod (no eval) and dev (eval present) modes."
**Location:** commit `2e23824` (message, Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
All three parts hold: the param exists with the NODE_ENV default (`proxy.ts:27-28`); the test pins prod mode with `buildCsp(NONCE, false)` and asserts `expect(csp).not.toMatch(/'unsafe-eval'/)` (`proxy.test.ts:12,31`); and it pins dev mode with `buildCsp(NONCE, true)` and asserts `'unsafe-eval'` is present in `script-src` (`proxy.test.ts:37-43`).
**Evidence:** `proxy.ts:26-32`, `proxy.test.ts:12,30-46`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`commit c0e0a35` / `BalancedPerspectivesPanel.tsx:113`): the new guard is a truthiness conditional-render, not optional chaining, and "every other streamed field" overstates — `t.description`, `p.label`, `p.coreClaim`, `synthesis.equilibrium` render unguarded (safely).
- **Claim 9** (`commit 4d5f743` / `evidenceStore.ts:17`): the "same pattern as workspaceStore" parity claim was dropped from the docstring but survives verbatim in the adapter section header at line 17 — the drift removal is half-done.
- **Claim 16** (`commit 2e23824` title / `proxy.ts:28`): "development only" is really "any NODE_ENV other than exactly `production`" — unset/staging/custom values also get `'unsafe-eval'` (fail-open default).

### Unverifiable
- **Claim 10** (`commit 4d5f743`): review items "A1/A2" resolve to nothing in the repo; the committed rubric's A1/A2 are unrelated corpus-branch items, inviting misreading.
- **Claim 13** (`proxy.ts:21-23`): Next.js dev-server eval-injection behavior is external framework behavior, not checkable from this checkout.
- **Claim 14** (`proxy.ts:23-24`): "production output is genuinely eval-free" — first-party code is eval-free by grep, but no production build or installed deps (notably `pdfjs-dist`, which can use `new Function` at runtime) were available to inspect.

## Goal-Alignment Note
- Answered: yes
- Out of scope: code-quality/design judgments (e.g. whether the fail-open NODE_ENV default is a good idea — noted only as a narrow-reading flag on Claim 16, per the fact-check-not-review boundary); execution of the test suite and production build (blocked by missing `node_modules` in the checkout — affected confidence on Claims 6, 11, 13, 14 but no verdicts hinge on it alone).
- Escalate: (1) the leftover parity comment at `evidenceStore.ts:17` (Claim 9) and the "every other streamed field" overstatement (Claim 5) are cheap author fixes; (2) the security-relevant fail-open reading of the `allowUnsafeEval` default (Claim 16) should be routed to the security critic rather than adjudicated here; (3) if the harness can `npm install`, re-running the two changed test files would upgrade Claims 6 and 11 to High confidence.
