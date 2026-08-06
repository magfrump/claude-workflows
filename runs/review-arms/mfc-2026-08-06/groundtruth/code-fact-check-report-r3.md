# Code Fact-Check Report

**Repository:** /workspace/external/meta-formalism-copilot
**Scope:** HEAD~3..HEAD (4d5f743, 2e23824, c0e0a35, merge 7f30210)
**Checked:** 2026-08-06
**Total claims checked:** 15
**Summary:** 12 verified, 2 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable
**Commit:** 7f30210

Note on method: `node_modules` is not installed in this checkout, so no tests or lint were executed; all verdicts rest on reading implementations and git history. Where execution would have raised confidence, that is reflected in the Confidence field.

## Claim 1: "Safe to spread: allWorks holds at most PER_QUERY_RESULTS per query — worst case MAX_OVERRIDE_QUERIES (5) queries on the override path (25), fewer on the LLM path (≤3 queries → 15). Well under the arg-count limit."
**Location:** `app/api/evidence-search/route.ts:178-180`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
Every numeric component checks out against the code that exercises it:
- `PER_QUERY_RESULTS` exists: `const PER_QUERY_RESULTS = 5;` (`app/api/evidence-search/route.ts:20`), and is the only cap on per-query results — `url.searchParams.set("per_page", String(PER_QUERY_RESULTS));` (`route.ts:114`), with `allWorks` populated solely from fulfilled `searchOpenAlex` results (`route.ts:167-173`).
- `MAX_OVERRIDE_QUERIES` exists with the claimed value: `export const MAX_OVERRIDE_QUERIES = 5;` (`app/api/evidence-search/querySanitize.ts:9`). The override path is hard-capped: `if (cleaned.length >= MAX_OVERRIDE_QUERIES) break;` (`querySanitize.ts:20`), and the route uses the sanitized list directly (`route.ts:160-164`), so override worst case is 5 × 5 = 25.
- The LLM path is genuinely capped at ≤3 queries: `generateSearchQueries` returns `parsed.queries.slice(0, 3)` (`route.ts:94`), and every fallback branch returns a single-element array (`route.ts:87,92,96`), so LLM worst case is 3 × 5 = 15.
- The spread in question is `Math.max(...allWorks.map((w) => w.relevance_score ?? 0), 1)` (`route.ts:181`) — at most 26 arguments, trivially under any engine's argument-count limit.
Minor implicit dependency (not a defect in the claim): the per-query bound relies on OpenAlex honoring `per_page=5`; the code does not defensively truncate `data.results` (`route.ts:126`).
**Evidence:** `app/api/evidence-search/route.ts:20,94,114,126,160-173,181`, `app/api/evidence-search/querySanitize.ts:9,20`

## Claim 2: "Regression: partial-JSON streaming can yield a tension object before its `between` tuple has arrived. Indexing `between[0]` on undefined threw a runtime TypeError that crashed the whole panel."
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:41-43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The streaming mechanism is real: the panel receives `streamingPreview` documented as "Partial map data from streaming (partial-JSON parsed)" (`BalancedPerspectivesPanel.tsx:12-13`), and `app/hooks/useArtifactGeneration.ts:9` imports `parse as parsePartialJson` from `partial-json`, applying it to accumulated stream chunks (`useArtifactGeneration.ts:75`). A partial parse can legitimately yield a tension object whose `between` array has not started parsing. The pre-fix code (parent `c0e0a35^`, visible in the diff) rendered `<span>{t.between[0]}</span>` unconditionally; indexing `[0]` on `undefined` throws `TypeError: Cannot read properties of undefined (reading '0')`, and a render-phase throw with no error boundary takes down the panel subtree. `mergeStreamingPreview` passes the data through unmodified (`app/lib/utils/mergeStreamingPreview.ts:13-15`), so nothing upstream fills in `between`.
**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:12-13,110-120`, `app/hooks/useArtifactGeneration.ts:9,68-86`, `app/lib/utils/mergeStreamingPreview.ts:13-15`

## Claim 3: "`between` absent mid-stream — the static type marks it required, so cast."
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:46`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The type does mark `between` required: the tensions element type is declared as `between: [string, string];` with no optional modifier (`app/lib/types/artifacts.ts:99-100`), so constructing a tension without it requires the `as unknown as Tension` cast the test uses.
**Evidence:** `app/lib/types/artifacts.ts:99-100`, `app/components/panels/BalancedPerspectivesPanel.test.tsx:47`

## Claim 4: "Persists to localStorage with debounced writes (see the debounced storage adapter below) to avoid excessive serialization on rapid updates."
**Location:** `app/lib/stores/evidenceStore.ts:8-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The adapter referenced "below" exists and does what is claimed. `createDebouncedStorage()` (`evidenceStore.ts:20-41`) implements a 300 ms trailing debounce on `setItem`: `if (pending) clearTimeout(pending); pending = setTimeout(() => { ... localStorage.setItem(name, value); ... }, 300);` (`evidenceStore.ts:25-33`). The store wires it into zustand's persist middleware via `createJSONStorage(() => debouncedStorage)` (`evidenceStore.ts:355-357`), so every persisted write goes through the debounce. The claim is scoped to writes; reads (`getItem`) and `removeItem` are immediate, which does not contradict it.
**Evidence:** `app/lib/stores/evidenceStore.ts:20-41,48,355-357`

## Claim 5: "Pin the production CSP explicitly so these assertions don't depend on the ambient NODE_ENV the test runner happens to set."
**Location:** `proxy.test.ts:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
`buildCsp`'s only NODE_ENV sensitivity is the default value of its second parameter: `allowUnsafeEval: boolean = process.env.NODE_ENV !== "production"` (`proxy.ts:28`). Passing `false` explicitly (`proxy.test.ts:12`) bypasses the default entirely, and `false` is exactly what production resolves to, so `csp` is the production string regardless of the runner's env. The one test that wants dev behavior likewise pins it explicitly with `buildCsp(NONCE, true)` (`proxy.test.ts:37`). No assertion in the file reads an unpinned `buildCsp(NONCE)`.
**Evidence:** `proxy.ts:26-29`, `proxy.test.ts:12,37`

## Claim 6: "'unsafe-eval' must remain scoped to script-src — never leaks elsewhere." (as the rationale for the accompanying assertion)
**Location:** `proxy.test.ts:44-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The comment claims the assertions establish scoping, and together they do. `expect(devCsp.match(/'unsafe-eval'/g)).toHaveLength(1)` (`proxy.test.ts:45`) proves exactly one occurrence exists in the whole dev CSP, and the preceding exact-equality assertion `expect(devScriptSrc).toBe("script-src 'self' 'nonce-...' 'strict-dynamic' 'unsafe-eval'")` (`proxy.test.ts:41-43`) proves that one occurrence is inside `script-src`. One-total + one-in-script-src jointly entail zero occurrences in any other directive. The count assertion alone would not establish this; the pair does.
**Evidence:** `proxy.test.ts:36-46`

## Claim 7: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."
**Location:** `proxy.ts:18-19`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
Enumerated every client-side network call site (fetch/XHR/WebSocket/EventSource/sendBeacon) outside `app/api/`:
- All browser `fetch` targets are relative same-origin `/api/...` paths: `app/hooks/useAnalytics.ts:11,30`, `useEvidenceSearch.ts:39`, `useEvidenceScoring.ts:47`, `useEvidenceOverlap.ts:54`, `useEvidenceIntegration.ts:80`, `useDecomposition.ts:144`, `useArtifactGeneration.ts:58`, `useArtifactEditing.ts:39,48`, `app/lib/formalization/api.ts:121,142,158,167,180`, `formalizeNode.ts:136`, panels/features (`OutputPanel.tsx:50,66`, `SemiformalPanel.tsx:45,61`, `EditableSection.tsx:78,85`, `CustomTypeDesigner.tsx:53,90`, `LeanCodeDisplay.tsx:88`, `ContextInput.tsx:25`). No XHR/WebSocket/EventSource/sendBeacon uses exist in client code.
- The third-party calls named in the claim are indeed server-side: `OPENROUTER_API_URL` is fetched only from `app/lib/llm/callLlm.ts:203` and `streamLlm.ts:250`, which are imported exclusively by `app/api/**` routes plus `app/lib/llm/costs.ts` (the sole non-`app/api` importers of `callLlm`, `app/lib/formalization/api.ts:3` and `artifactRoute.ts`, are a type-only import and a server-side route helper). OpenAlex is fetched from `app/api/evidence-search/route.ts:117`.
- Export/download utilities avoid the `data:` fetch trap deliberately: `app/lib/utils/exportGraph.ts:6` — "Use toBlob (not toPng + fetch) so we don't need `data:` in CSP connect-src" — and `export.ts:8` uses `URL.createObjectURL` + anchor download, which needs no connect-src grant. The only absolute external URL in client code is an `href` (DOI link, `EvidencePaperCard.tsx:25`), governed by navigation, not connect-src.
Narrow caveat (does not defeat the claim): the DD-009 corpus git pipeline performs browser-context HTTP to arbitrary git remotes (`app/lib/corpus/gitCore.ts:203,218` via `isomorphic-git/http/web`), but it is dev-only behind a hard production guard (`app/lib/corpus/flag.ts:21` returns `false` when `NODE_ENV === "production"`) and runs in a dedicated Web Worker (`gitWorker.ts`), whose fetches are governed by the worker script's own CSP, not this document policy. If S4/S5 ever ships that path to production, this docstring will need revisiting.
**Evidence:** `proxy.ts:39`, `app/lib/llm/callLlm.ts:203`, `app/lib/llm/streamLlm.ts:250`, `app/lib/formalization/api.ts:3,121`, `app/lib/utils/exportGraph.ts:6`, `app/lib/utils/export.ts:8`, `app/lib/corpus/gitCore.ts:203,218`, `app/lib/corpus/flag.ts:21`, client fetch sites listed above

## Claim 8: "`'unsafe-eval'` is added only when NODE_ENV !== 'production'."
**Location:** `proxy.ts:21-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The mechanism is a defaulted parameter: `allowUnsafeEval: boolean = process.env.NODE_ENV !== "production"` (`proxy.ts:28`), with the token appended only when truthy: `${allowUnsafeEval ? " 'unsafe-eval'" : ""}` (`proxy.ts:30-32`). Call-site audit: the only runtime caller is `proxy()` itself, which uses the default — `const csp = buildCsp(nonce);` (`proxy.ts:53`) — so served CSP behavior matches the claim exactly. The remaining callers are the tests, which pass the flag explicitly (`proxy.test.ts:12,37`); they construct strings but never serve headers, so they don't contradict the claim. Narrow reading worth noting: because the knob is an overridable parameter rather than an internal check, any future caller passing `true` in production would silently violate this docstring; today no such caller exists (repo-wide grep for `buildCsp(` finds only `proxy.ts:53` and the two test call sites).
**Evidence:** `proxy.ts:26-32,53`, `proxy.test.ts:12,37`

## Claim 9: "Production output is genuinely eval-free."
**Location:** `proxy.ts:23-24`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
This is a claim about Next.js production build artifacts, not about code in the repo. No production build exists in the checkout (no `.next/` directory) and `node_modules` is not installed, so the bundle could not be built and grepped for `eval` — paraphrased — no quote available because the claim's subject (production bundle contents) does not exist in the repository. Indirect support: the production CSP omits `'unsafe-eval'` and CSP #143 has been live since commit `9581518`, so any eval in production output would surface as EvalErrors in every production deployment — the same failure mode the commit describes observing in dev. That makes the claim plausible but not verified here.
**Evidence:** `proxy.ts:30-32` (production script-src omits 'unsafe-eval'); absence of `.next/` and `node_modules/` in `/workspace/external/meta-formalism-copilot`

## Claim 10: "evidenceStore: drop the unverifiable 'same pattern as workspaceStore' parity claim; describe the debounced-write behavior directly." (commit message)
**Location:** commit `4d5f743` (message), re `app/lib/stores/evidenceStore.ts`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
The docstring edit did what it says — the top-of-file comment now describes the debounce directly (`evidenceStore.ts:8-9`). But the identical parity claim survives 8 lines below the docstring, in the section banner the new comment points readers at: "Debounced localStorage adapter (same pattern as workspaceStore)" (`evidenceStore.ts:17`). So the parity claim was moved out of the docstring, not dropped from the file. Additionally, "unverifiable" undersells it: `workspaceStore.ts` does document "custom debounced storage adapter rate-limits writes" (`workspaceStore.ts:5`) and selects a debounced-localStorage storage seam (`workspaceStore.ts:530`), so the parity claim appears to be broadly true rather than uncheckable — though "unverifiable" is the author's characterization and borders on opinion.
**Evidence:** `app/lib/stores/evidenceStore.ts:8-9,17`, `app/lib/stores/workspaceStore.ts:5,530`

## Claim 11: "comment-only; lint clean, no behavior change." (commit message)
**Location:** commit `4d5f743` (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
`git show 4d5f743` touches only `app/api/evidence-search/route.ts` (3 comment lines replacing 2) and `app/lib/stores/evidenceStore.ts` (2 docstring lines) — every changed line is inside a comment, so "comment-only" and "no behavior change" are verified from the diff. The "lint clean" sub-claim could not be re-executed (`node_modules` absent), but a comment-only diff cannot introduce new lint findings relative to the parent, so it inherits the parent's lint status; not weighted against the verdict.
**Evidence:** diff of `4d5f743` (`app/api/evidence-search/route.ts:175-180`, `app/lib/stores/evidenceStore.ts:5-9`)

## Claim 12: "Guard the endpoints row on `t.between` (matching the optional chaining already used for every other streamed field)." (commit message)
**Location:** commit `c0e0a35` (message), re `app/components/panels/BalancedPerspectivesPanel.tsx:113`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
The substantive point — every other streamed access that could throw is already protected, and this guard brings `between` in line — is true. But the parenthetical is loose on two counts. (1) The new guard is a truthiness conditional render, `{t.between && (...)}` (`BalancedPerspectivesPanel.tsx:113`), not optional chaining; it actually matches the existing object-guard pattern (`displayMap.topic && ...` at line 46, `displayMap.synthesis && ...` at line 129), while optional chaining proper is what the array fields use (`displayMap.tensions?.map` line 110, `perspectives?.map` line 69, `supportingArguments?.map` line 82, `howAddressed?.map` line 136). (2) Not "every other streamed field" is guarded at all: leaf scalars such as `p.label` (line 74), `p.coreClaim` (line 76), `t.description` (line 120), and `displayMap.synthesis.equilibrium` (line 133) render unguarded — safe only because React renders `undefined` as nothing, not because they're chained. The claim is true under the reading "every other throw-capable access is protected"; it is not literally true as written.
**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:46,56,66-69,74,76,82,93,107-120,129-136`

## Claim 13: "Adds a regression test that reproduces the exact TypeError without the guard." (commit message)
**Location:** commit `c0e0a35` (message), re `app/components/panels/BalancedPerspectivesPanel.test.tsx:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
Traced the test's render path against the pre-fix code: the test supplies `balancedPerspectives` whose `tensions` contains `{ description: "Half-streamed tension" }` with no `between` (`test.tsx:46-48`); `mergeStreamingPreview` passes it through as `displayData` with `hasDisplayData` true via `!!d.topic` ("Test topic") (`mergeStreamingPreview.ts:13-14`, `test.tsx:20`); the mocked `ArtifactPanelShell` renders children when `hasData` (`test.tsx:10-13`); `tensions.length > 0` opens the tensions block (`BalancedPerspectivesPanel.tsx:107`); and the pre-fix code then evaluated `t.between[0]` unconditionally — indexing `undefined`, which throws precisely the TypeError the commit body quotes ("Cannot read properties of undefined"). With the guard, the row is skipped and the `not.toThrow()` + description assertions pass. Confidence is Medium rather than High only because the suite could not be executed (no `node_modules`) — the claim was verified by code-path reading, including confirming `CollapsibleSection`/`EditableSection` are real or mocked and introduce no error boundary that would swallow the throw (`EditableSection` is mocked, `test.tsx:7-9`).
**Evidence:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:7-13,20,46-55`, `app/components/panels/BalancedPerspectivesPanel.tsx:107-120` (and its pre-fix form in the `c0e0a35` diff), `app/lib/utils/mergeStreamingPreview.ts:13-14`

## Claim 14: "the strict CSP from #143" (commit message)
**Location:** commit `2e23824` (message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The reference resolves: commit `9581518` on this branch's history is titled "feat: strict Content-Security-Policy with per-request nonces (#143)", i.e., the squash-merge of PR #143, which introduced the `buildCsp` policy this commit relaxes for dev. (GitHub itself was not queried; the `(#143)` squash-merge suffix in the local history is the evidence.)
**Evidence:** `git log` — `9581518 feat: strict Content-Security-Policy with per-request nonces (#143)`

## Claim 15: "buildCsp gained an explicit allowUnsafeEval param (defaulted from NODE_ENV) so the test pins both prod (no eval) and dev (eval present) modes." (commit message)
**Location:** commit `2e23824` (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
All three parts hold: the param exists and is defaulted from NODE_ENV (`proxy.ts:27-28`); the test pins prod with `buildCsp(NONCE, false)` and asserts `expect(csp).not.toMatch(/'unsafe-eval'/)` (`proxy.test.ts:12,31`); and it pins dev with `buildCsp(NONCE, true)` and asserts `'unsafe-eval'` is present in script-src (`proxy.test.ts:37,41-43`).
**Evidence:** `proxy.ts:26-32`, `proxy.test.ts:12,30-46`

## Claims Requiring Attention

### Incorrect
- none

### Stale
- none

### Mostly Accurate
- **Claim 10** (`commit 4d5f743` / `app/lib/stores/evidenceStore.ts:17`): the "same pattern as workspaceStore" parity claim was dropped from the docstring but survives verbatim in the section banner the new docstring points at.
- **Claim 12** (`commit c0e0a35` / `BalancedPerspectivesPanel.tsx:113`): the new guard is a truthiness conditional (matching the existing object-guard pattern), not optional chaining, and several streamed leaf fields are not guarded at all — the parenthetical overstates uniformity.

### Unverifiable
- **Claim 9** (`proxy.ts:23-24`): "Production output is genuinely eval-free" is a claim about the Next.js production bundle, which does not exist in this checkout (no build, no node_modules); plausible via CSP-enforcement reasoning but not verified.

## Goal-Alignment Note
- Answered: yes
- Out of scope: executing the test suite and lint (no `node_modules` in the checkout — verdicts for Claims 11 and 13 rest on diff/code-path reading, reflected in their confidence); live GitHub lookup for PR #143 (local squash-merge commit used instead); production-bundle inspection for Claim 9.
- Escalate: (1) If DD-009 S4/S5 ever ships the corpus git pipeline to production, the `connect-src 'self'` docstring in `proxy.ts:18-19` becomes wrong — browser-context git-remote HTTP from the worker (see Claim 7 caveat). (2) `buildCsp`'s `allowUnsafeEval` is an overridable public parameter; the "dev-only" property is enforced only by the single runtime call site, so a future caller could silently ship 'unsafe-eval' to production (Claim 8 narrow reading).
