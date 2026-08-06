# Code Fact-Check Report

**Repository:** /workspace/external/meta-formalism-copilot
**Scope:** HEAD~3..HEAD (4d5f743, 2e23824, c0e0a35, merge 7f30210)
**Checked:** 2026-08-06
**Total claims checked:** 17
**Summary:** 11 verified, 3 mostly accurate, 0 stale, 0 incorrect, 3 unverifiable
**Commit:** 7f30210

Note on execution: `node_modules` is not installed in this checkout, so the Vitest suite was not executed; test-behavior claims are verified by reading the components under test end-to-end (including mocks and the pre-fix code at `HEAD~3`).

## Claim 1: "Safe to spread: allWorks holds at most PER_QUERY_RESULTS per query — worst case MAX_OVERRIDE_QUERIES (5) queries on the override path (25), fewer on the LLM path (≤3 queries → 15). Well under the arg-count limit."
**Location:** `app/api/evidence-search/route.ts:178-180`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
Every component of the bound checks out:
- `PER_QUERY_RESULTS` exists and is 5: `const PER_QUERY_RESULTS = 5;` (`route.ts:20`). It is passed to OpenAlex as the page size — `url.searchParams.set("per_page", String(PER_QUERY_RESULTS));` (`route.ts:114`) — so each query contributes at most 5 works to `allWorks` (populated only from fulfilled `searchOpenAlex` results, `route.ts:167-173`; error/timeout paths return `[]`, `route.ts:120-135`).
- `MAX_OVERRIDE_QUERIES` exists and is 5: `export const MAX_OVERRIDE_QUERIES = 5;` (`app/api/evidence-search/querySanitize.ts:9`), enforced by `if (cleaned.length >= MAX_OVERRIDE_QUERIES) break;` (`querySanitize.ts:20`). The override path uses `sanitizeQueries(body.queries)` (`route.ts:160-164`), so worst case 5 × 5 = 25.
- LLM path is genuinely ≤3 queries: `generateSearchQueries` returns `parsed.queries.slice(0, 3)` (`route.ts:94`) and every fallback branch returns a single-element array `[elementContent.slice(0, 100)]` (`route.ts:87,92,96`). So ≤3 × 5 = 15.
- The spread this guards, `Math.max(...allWorks.map((w) => w.relevance_score ?? 0), 1)` (`route.ts:181`), therefore receives ≤26 arguments — orders of magnitude under engine argument-count limits (~65k+). The per-iteration `allWorks.push(...result.value)` spread (`route.ts:171`) is likewise ≤5 args.
**Evidence:** `app/api/evidence-search/route.ts:20,94,114,160-173,181`, `app/api/evidence-search/querySanitize.ts:9,20`

## Claim 2: "Regression: partial-JSON streaming can yield a tension object before its `between` tuple has arrived. Indexing `between[0]` on undefined threw a runtime TypeError that crashed the whole panel."
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
The pre-fix code indexed the tuple unguarded: `git show HEAD~3:app/components/panels/BalancedPerspectivesPanel.tsx` shows `<span>{t.between[0]}</span>` / `<span>{t.between[1]}</span>` with no `t.between` check (old lines 114, 116). Streamed partials reach the render path: `mergeStreamingPreview` returns `finalData ?? streamingPreview ?? null` (`app/lib/utils/mergeStreamingPreview.ts:13`) and the panel's `streamingPreview` prop is documented as "Partial map data from streaming (partial-JSON parsed)" (`BalancedPerspectivesPanel.tsx:12`). A tension object whose `between` has not parsed yet makes `t.between[0]` throw `TypeError: Cannot read properties of undefined`, and an uncaught render error unmounts the component tree ("crashed the whole panel"). The type marks `between` required (`between: [string, string]`, `app/lib/types/artifacts.ts:100`), consistent with the test's cast comment at `test.tsx:49`.
**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `git show HEAD~3:app/components/panels/BalancedPerspectivesPanel.tsx` (old lines 112-117), `app/lib/utils/mergeStreamingPreview.ts:13`, `app/components/panels/BalancedPerspectivesPanel.tsx:12`, `app/lib/types/artifacts.ts:99-102`

## Claim 3: "`between` absent mid-stream — the static type marks it required, so cast."
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The static type does mark it required: `tensions: Array<{ between: [string, string]; description: string; }>` (`app/lib/types/artifacts.ts:99-102`) — no `?` and non-optional tuple, so constructing a tension without `between` requires the `as unknown as Tension` cast the test uses.
**Evidence:** `app/lib/types/artifacts.ts:99-102`, `app/components/panels/BalancedPerspectivesPanel.test.tsx:50`

## Claim 4: "Persists to localStorage with debounced writes (see the debounced storage adapter below) to avoid excessive serialization on rapid updates."
**Location:** `app/lib/stores/evidenceStore.ts:8-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The adapter the comment points at exists directly below and does what is claimed: `createDebouncedStorage` (`evidenceStore.ts:20-41`) coalesces `setItem` calls — `if (pending) clearTimeout(pending); pending = setTimeout(() => { ... localStorage.setItem(name, value); ... }, 300);` (`evidenceStore.ts:25-33`) — and is wired into the persist middleware via `storage: typeof window !== "undefined" ? createJSONStorage(() => debouncedStorage) : undefined` (`evidenceStore.ts:355-357`). The claim is specifically about writes; reads (`getItem`) and `removeItem` are immediate, which the comment does not contradict.
**Evidence:** `app/lib/stores/evidenceStore.ts:20-41,48,355-357`

## Claim 5: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."
**Location:** `proxy.ts:18-19`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
The stated rationale is correct for the default app. A sweep of client-side network calls (`rg "fetch\(|XMLHttpRequest|new WebSocket|EventSource|sendBeacon" app`, excluding `app/api/` and tests) finds only same-origin `/api/...` fetches: `app/hooks/useAnalytics.ts:11,30`, `app/lib/formalization/api.ts:11,39,121`, `app/components/features/context-input/ContextInput.tsx:25`, `app/components/features/lean-display/LeanCodeDisplay.tsx:88`. The third-party calls live server-side only: OpenRouter/Anthropic in `app/lib/llm/callLlm.ts:203` / `streamLlm.ts:250`, imported (beyond type-only imports) exclusively by API routes via `app/lib/formalization/artifactRoute.ts`; OpenAlex in `app/api/evidence-search/route.ts:117`. Export/download utilities do not need `data:`/`blob:` in connect-src: `export.ts` uses `URL.createObjectURL` + anchor click, not fetch (`app/lib/utils/export.ts:7-14`), and `exportGraph.ts:6` explicitly notes "Use toBlob (not toPng + fetch) so we don't need `data:` in CSP connect-src." The pdf.js worker is bundled same-origin (`fileExtraction.ts:26-29`).
The narrow reading that keeps this only *mostly* accurate: the DD-009 corpus git pipeline performs browser-context third-party traffic — `gitWorker.ts:33` imports `isomorphic-git/http/web` and `gitCore.ts:203/213` push/pull to a user-configured `remoteUrl` from a dedicated Web Worker. This is default-off and dev-only (`app/lib/corpus/flag.ts`), and a dedicated worker's fetches are governed by the worker script's own CSP (the proxy matcher excludes `_next/static`, `proxy.ts:74-82`), so the document's `connect-src 'self'` neither blocks it nor needs to change — but the docstring's "not browser-to-third-party" enumeration is no longer the whole story and will silently drift further when corpus S4/S5 ships.
**Evidence:** `app/lib/llm/callLlm.ts:203`, `app/lib/llm/streamLlm.ts:250`, `app/lib/formalization/api.ts:3` ("import type { LlmCallUsage }" — type-only), `app/lib/utils/export.ts:7-14`, `app/lib/utils/exportGraph.ts:6`, `app/lib/corpus/gitWorker.ts:33`, `app/lib/corpus/gitCore.ts:198-213`, `proxy.ts:74-82`

## Claim 6: "Production output is genuinely eval-free, so `'unsafe-eval'` is added only when NODE_ENV !== \"production\"."
**Location:** `proxy.ts:23-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
Two sub-claims. (a) The conditional mechanism is exactly as stated — see Claim 7. (b) "Production output is genuinely eval-free": no first-party `eval(` or `new Function` exists anywhere under `app/` (grep returns nothing outside tests — paraphrased, no quote available because the assertion is about absence of matches), and Next.js production builds do not emit eval-based module wrappers or eval source maps (those are dev-server behaviors, which is the comment's own premise). Confidence is Medium rather than High because the production bundle itself was not built and scanned in this pass, so a transitively bundled dependency using eval cannot be fully excluded.
**Evidence:** `proxy.ts:26-32`, grep of `app/` for `eval(|new Function` (no non-test matches; paraphrased — no quote available because the claim covers absence)

## Claim 7: "`'unsafe-eval'` is added only when NODE_ENV !== \"production\"" (default-parameter mechanism)
**Location:** `proxy.ts:21-32`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
`buildCsp(nonce: string, allowUnsafeEval: boolean = process.env.NODE_ENV !== "production")` (`proxy.ts:26-28`) appends `'unsafe-eval'` to `script-src` only when `allowUnsafeEval` is truthy: `` const scriptSrc = `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${allowUnsafeEval ? " 'unsafe-eval'" : ""}` `` (`proxy.ts:30-32`). Call-site audit (`rg -n "buildCsp"`): the only production call site is `const csp = buildCsp(nonce);` (`proxy.ts:53`), which takes the NODE_ENV-derived default; the only other callers are the tests, which pass the flag explicitly (`proxy.test.ts:12,37`). No caller can accidentally enable eval in production without setting NODE_ENV wrong, in which case the comment's condition still holds as written.
**Evidence:** `proxy.ts:26-32,53`, `proxy.test.ts:12,37`

## Claim 8: "Pin the production CSP explicitly so these assertions don't depend on the ambient NODE_ENV the test runner happens to set."
**Location:** `proxy.test.ts:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
`const csp = buildCsp(NONCE, false);` (`proxy.test.ts:12`) passes the second argument explicitly, so the `process.env.NODE_ENV !== "production"` default (`proxy.ts:28`) is never evaluated for this fixture. Every assertion in the describe block that uses `csp`/`directives` (`proxy.test.ts:15-34,48-61`) is therefore NODE_ENV-independent, and the dev-mode test likewise pins `buildCsp(NONCE, true)` (`proxy.test.ts:37`).
**Evidence:** `proxy.test.ts:12,37`, `proxy.ts:26-28`

## Claim 9: "'unsafe-eval' must remain scoped to script-src — never leaks elsewhere."
**Location:** `proxy.test.ts:44`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The count assertion on the next line — `expect(devCsp.match(/'unsafe-eval'/g)).toHaveLength(1);` (`proxy.test.ts:45`) — would not establish scoping by itself (one occurrence could sit in any directive). But combined with the immediately preceding exact-match assertion `expect(devScriptSrc).toBe(`script-src 'self' 'nonce-${NONCE}' 'strict-dynamic' 'unsafe-eval'`)` (`proxy.test.ts:41-43`), which proves one occurrence is inside `script-src`, a total count of exactly 1 proves no occurrence exists anywhere else. The pair of assertions does establish the comment's invariant.
**Evidence:** `proxy.test.ts:38-45`

## Claim 10: "evidenceStore: drop the unverifiable 'same pattern as workspaceStore' parity claim; describe the debounced-write behavior directly."
**Location:** commit `4d5f743` (message body)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
The commit did rewrite the file-header docstring as described (`evidenceStore.ts:8-9` no longer mentions workspaceStore). However, the very parity claim it set out to drop still exists 8 lines below, in the section-banner comment the new docstring points readers at: `// Debounced localStorage adapter (same pattern as workspaceStore)` (`evidenceStore.ts:17`). That surviving claim is the drifted one: workspaceStore no longer hosts its own debounced adapter — it was moved to the corpus storage seam (`app/lib/stores/workspaceStore.ts:530`: "Storage seam is selected here (DD-009 S1): debounced localStorage by ..." and `app/lib/corpus/storeAdapter.ts`). So the commit's description of its own change is accurate for the docstring but the cleanup is incomplete against its stated intent.
**Evidence:** `app/lib/stores/evidenceStore.ts:8-9,17`, `app/lib/stores/workspaceStore.ts:5,530`

## Claim 11: "Resolves review items A1/A2 (fact-check Mostly-Accurate comment nits)."
**Location:** commit `4d5f743` (message body)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
No fact-check report containing A1/A2 items about these two comments exists in the repository at 7f30210. The committed `docs/reviews/code-review-rubric.md:19-20` does define items A1/A2, but those are corpus-architecture items (manifest naming, `state/<name>.json` namespace), already marked "✅ Fixed" before this range — not the evidence-comment nits. Commit `c0e0a35`'s own note explains why: "Review docs in docs/reviews/ left uncommitted" — the referenced review artifacts were never committed and the working tree is now clean, so the referent cannot be checked. The two edits themselves are consistent with the description ("Mostly-Accurate comment nits"), but the A1/A2 mapping is unrecoverable from the repo.
**Evidence:** `docs/reviews/code-review-rubric.md:19-20`, commit message `c0e0a35` ("Review docs in docs/reviews/ left uncommitted"), `git status` (clean tree — paraphrased, no quote available because the evidence is command output showing no entries)

## Claim 12: "comment-only; lint clean, no behavior change."
**Location:** commit `4d5f743` (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
The commit's diff touches exactly two hunks, both entirely within comment blocks: the `Safe to spread` comment (`app/api/evidence-search/route.ts:178-180`) and the docstring (`app/lib/stores/evidenceStore.ts:8-9`). No executable line changes, so "no behavior change" follows. "Lint clean" was not re-run in this pass (no `node_modules` installed) but comment-only edits cannot introduce the rule classes this config checks.
**Evidence:** `git show 4d5f743` (both hunks comment-only; quoted in full in the range diff), `app/api/evidence-search/route.ts:178-180`, `app/lib/stores/evidenceStore.ts:8-9`

## Claim 13: "the strict CSP from #143"
**Location:** commit `2e23824` (message body)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
The strict CSP itself is real and predates this range (`proxy.ts` with nonce + `'strict-dynamic'`, plus a full review trail under `docs/reviews/csp-headers/`), so the substance of the sentence is fine. But the issue/PR number `#143` cannot be checked from this environment (no GitHub access), and nothing in the repo (`rg "#143" docs README.md` — no matches) ties the CSP work to that number.
**Evidence:** `proxy.ts:4-25`, `docs/reviews/csp-headers/` (directory exists), grep for `#143` (no matches — paraphrased, no quote available because the claim covers absence)

## Claim 14: "the test pins both prod (no eval) and dev (eval present) modes."
**Location:** commit `2e23824` (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
Prod pinned: `buildCsp(NONCE, false)` with `expect(csp).not.toMatch(/'unsafe-eval'/)` (`proxy.test.ts:12,31`). Dev pinned: `buildCsp(NONCE, true)` with the exact `script-src ... 'unsafe-eval'` string assertion (`proxy.test.ts:37,41-43`). Both modes are exercised with the flag explicit, matching the commit's description of the `allowUnsafeEval` param's purpose.
**Evidence:** `proxy.test.ts:12,30-34,36-46`

## Claim 15: "Guard the endpoints row on `t.between` (matching the optional chaining already used for every other streamed field)."
**Location:** commit `c0e0a35` (message body)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
The spirit is right — every other streamed field in the panel is defensively guarded — but the letter is off in two ways. First, the added guard is not optional chaining; it is a truthiness conditional render: `{t.between && (<div ...>)}` (`BalancedPerspectivesPanel.tsx:113`). Second, the pre-existing guards are a mix of the two styles, not uniformly optional chaining: `?.` on arrays (`displayMap.tensions?.map` line 110, `displayMap.perspectives?.map` line 69, `p.supportingArguments?.map` line 82) and `&&` conditional renders on objects/strings (`{displayMap.topic && ...}` line 46, `{displayMap.summary && ...}` line 56, `{displayMap.synthesis && ...}` line 129 guarding the `displayMap.synthesis.equilibrium` access at line 133). The new guard matches the second, `&&` family — which is the correct choice here since `t.between?.[0]` would render an empty endpoints row — so behavior is fine; only the "optional chaining" characterization is imprecise.
**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:46,56,66-69,78-82,107-119,129-133`

## Claim 16: "Adds a regression test that reproduces the exact TypeError without the guard."
**Location:** commit `c0e0a35` (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
The test renders a tension with `between` absent (`BalancedPerspectivesPanel.test.tsx:49-51`) and asserts render does not throw plus that the description still renders (`test.tsx:51-55`). Tracing it against the un-guarded code confirms it would reproduce the crash: the tensions section renders whenever `(displayMap.tensions?.length ?? 0) > 0` (`BalancedPerspectivesPanel.tsx:107`); `CollapsibleSection` always renders its children even when collapsed — "Always render children to preserve internal state" with `display: none` (`app/components/ui/CollapsibleSection.tsx:50-51`) — and the test's mocks (EditableSection, ArtifactPanelShell with `hasData` pass-through, `test.tsx:7-13`) keep the real tension markup in the tree. So without the guard, `t.between[0]` on `undefined` throws the TypeError during render and `render()` would throw. Confidence Medium only because the suite could not be executed in this checkout (`node_modules` absent), so the pass/fail behavior is established by reading, not by running.
**Evidence:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:7-13,47-55`, `app/components/panels/BalancedPerspectivesPanel.tsx:107-119`, `app/components/ui/CollapsibleSection.tsx:50-51`, `git show HEAD~3:app/components/panels/BalancedPerspectivesPanel.tsx` (old lines 113-117)

## Claim 17: "landed directly on integration/6.1 per user direction (panel is not on main and no in-flight feature branch owns it)."
**Location:** commit `c0e0a35` (message body)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
The checkable core holds: `git cat-file -e main:app/components/panels/BalancedPerspectivesPanel.tsx` fails — the panel file does not exist on `main` (paraphrased — no quote available because the evidence is a command exit status). "No in-flight feature branch owns it" is consistent with `git branch -a` / `git log --all` showing no unmerged branch touching the panel, though intent-level ownership ("per user direction") is not checkable from the repo. Confidence Medium for that residual.
**Evidence:** `git cat-file -e main:app/components/panels/BalancedPerspectivesPanel.tsx` (non-zero exit), `git log --all --oneline`

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- (none)

### Mostly Accurate
- **Claim 5** (`proxy.ts:18-19`): connect-src rationale is true for the shipped defaults, but the flagged DD-009 corpus git worker (`isomorphic-git/http/web` push/pull to a user remote) is browser-context third-party traffic the docstring's enumeration omits.
- **Claim 10** (commit `4d5f743` / `evidenceStore.ts:17`): the commit dropped the workspaceStore-parity claim from the docstring but the identical (and now-drifted) claim survives in the section banner 8 lines below.
- **Claim 15** (commit `c0e0a35`): the added guard is a `&&` conditional render, not optional chaining, and the panel's other streamed fields use a mix of both styles — the characterization is imprecise though the behavior is correct.

### Unverifiable
- **Claim 11** (commit `4d5f743`): review items A1/A2 referenced by the commit exist nowhere in the repo (the only committed A1/A2 are unrelated corpus items); the evidence-review artifacts were left uncommitted and are gone.
- **Claim 13** (commit `2e23824`): issue/PR reference `#143` cannot be confirmed without GitHub access; no in-repo cross-reference exists.
- (Claim 6's production-bundle residual is noted in-place; verdict remains Verified at Medium confidence.)

## Goal-Alignment Note
- Answered: yes
- Out of scope: running the Vitest suite and building the production bundle (no `node_modules` in the checkout; installing dependencies into the target repo was avoided per the do-not-write rule) — test/bundle claims verified by end-to-end reading instead; GitHub issue/PR lookups (no network access to the remote).
- Escalate: the surviving drifted comment at `app/lib/stores/evidenceStore.ts:17` ("same pattern as workspaceStore") — the exact nit commit 4d5f743 intended to remove; and the `proxy.ts` connect-src docstring will need an update when the corpus git pipeline (browser-side push/pull) ships beyond the dev flag.
