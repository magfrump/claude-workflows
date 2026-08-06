# Code Fact-Check Report

**Repository:** /workspace/external/meta-formalism-copilot
**Scope:** HEAD~3..HEAD (4d5f743, 2e23824, c0e0a35, merge 7f30210)
**Checked:** 2026-08-06
**Total claims checked:** 20
**Summary:** 12 verified, 4 mostly accurate, 0 stale, 0 incorrect, 4 unverifiable
**Commit:** 7f30210
**Replication:** k=3

Merged most-severe-wins from code-fact-check-report-r{1,2,3}.md (r1: 17 claims, r2: 20, r3: 15). No replicate executed tests or builds (`node_modules` absent in checkout); execution-dependent claims verified by end-to-end reading, reflected in Confidence.

## Claim 1: "Safe to spread: allWorks holds at most PER_QUERY_RESULTS per query — worst case MAX_OVERRIDE_QUERIES (5) queries on the override path (25), fewer on the LLM path (≤3 queries → 15). Well under the arg-count limit."
**Location:** `app/api/evidence-search/route.ts:178-180`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
All numeric components verified by all three replicates: `const PER_QUERY_RESULTS = 5;` (`route.ts:20`) enforced via `url.searchParams.set("per_page", String(PER_QUERY_RESULTS))` (`route.ts:114`); `export const MAX_OVERRIDE_QUERIES = 5;` (`querySanitize.ts:9`) enforced by `if (cleaned.length >= MAX_OVERRIDE_QUERIES) break;` (`querySanitize.ts:20`); LLM path capped by `parsed.queries.slice(0, 3)` (`route.ts:94`) with single-element fallbacks (`route.ts:87,92,96`). The guarded spread `Math.max(...allWorks.map(...), 1)` (`route.ts:181`) receives ≤26 args. r3 notes the per-query bound trusts OpenAlex to honor `per_page` — `data.results` is not defensively truncated (`route.ts:126`).
**Evidence:** `app/api/evidence-search/route.ts:20,94,114,126,160-173,181`, `app/api/evidence-search/querySanitize.ts:9,20`

## Claim 2: "Regression: partial-JSON streaming can yield a tension object before its `between` tuple has arrived. Indexing `between[0]` on undefined threw a runtime TypeError that crashed the whole panel."
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:41-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
Pre-fix code indexed unguarded (`<span>{t.between[0]}</span>`, old lines 113-117 per `git show HEAD~3:...`); the streaming premise is real (`streamingPreview` documented "Partial map data from streaming (partial-JSON parsed)" `BalancedPerspectivesPanel.tsx:12-13`; `partial-json` applied to accumulated chunks, `useArtifactGeneration.ts:9,75`; wired at `page.tsx:994`); no error boundary between the tensions map and panel root, so the render throw unmounts the subtree.
**Evidence:** `git show HEAD~3:app/components/panels/BalancedPerspectivesPanel.tsx` (old 112-117), `app/components/panels/BalancedPerspectivesPanel.tsx:12-13,110-121`, `app/hooks/useArtifactGeneration.ts:9,68-86`, `app/page.tsx:994`

## Claim 3: "`between` absent mid-stream — the static type marks it required, so cast."
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:48-49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
`between: [string, string];` with no optional modifier (`app/lib/types/artifacts.ts:99-102`) — the `as unknown as Tension` cast is required, as stated.
**Evidence:** `app/lib/types/artifacts.ts:99-102`

## Claim 4: "The description still renders even though the endpoints aren't ready."
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
Only the endpoints row is inside the `t.between && (...)` guard (`BalancedPerspectivesPanel.tsx:113-119`); `{t.description}` sits outside (line 120). Observable despite `defaultOpen={false}` because `CollapsibleSection` always renders children with `display: none` (`CollapsibleSection.tsx:50-51`).
**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-120`, `app/components/ui/CollapsibleSection.tsx:50-51`

## Claim 5: "Persists to localStorage with debounced writes (see the debounced storage adapter below) to avoid excessive serialization on rapid updates."
**Location:** `app/lib/stores/evidenceStore.ts:8-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
`createDebouncedStorage()` (`evidenceStore.ts:20-41`) implements a 300 ms trailing debounce on `setItem` (`clearTimeout(pending); pending = setTimeout(() => { localStorage.setItem(name, value); ... }, 300)`, lines 25-33), wired via `createJSONStorage(() => debouncedStorage)` (`evidenceStore.ts:355-357`).
**Evidence:** `app/lib/stores/evidenceStore.ts:20-41,48,355-357`

## Claim 6: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."
**Location:** `proxy.ts:18-19`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
All three replicates independently enumerated client-side network initiations and agree on the core: every browser fetch is a relative `/api/...` path; the only absolute third-party URL (`OPENROUTER_API_URL`, `callLlm.ts:7,203`; `streamLlm.ts:250`) is imported only by server code (the client `api.ts:3` import is type-only); OpenAlex is fetched server-side (`route.ts:117`); no WebSocket/EventSource/XHR/sendBeacon anywhere; exports use `URL.createObjectURL` + anchor, and `exportGraph.ts:6` deliberately avoids the `toPng + fetch` path ("so we don't need `data:` in CSP connect-src"); pdf.js worker is bundled same-origin (`fileExtraction.ts:26-29`). Winning caveat (r1): the DD-009 corpus git pipeline performs browser-context third-party HTTP — `gitWorker.ts:33` imports `isomorphic-git/http/web`; `gitCore.ts:203,213-218` push/pull to a user-configured `remoteUrl` from a dedicated Web Worker. It is dev-only behind a hard production guard (`app/lib/corpus/flag.ts:21` returns `false` when `NODE_ENV === "production"`) and worker fetches are governed by the worker script's own CSP, so the served policy needs no change today — but the docstring's "not browser-to-third-party" enumeration is no longer the whole story and silently drifts further when corpus S4/S5 ships.
**Evidence:** `app/lib/llm/callLlm.ts:7,203`, `app/lib/llm/streamLlm.ts:250`, `app/lib/formalization/api.ts:3`, `app/lib/utils/export.ts:7-14`, `app/lib/utils/exportGraph.ts:6`, `app/lib/utils/fileExtraction.ts:26-29`, `app/lib/corpus/gitWorker.ts:33`, `app/lib/corpus/gitCore.ts:198-218`, `app/lib/corpus/flag.ts:21`, `proxy.ts:74-82`

## Claim 7: "Production output is genuinely eval-free"
**Location:** `proxy.ts:23-24`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Unverifiable · r3=Unverifiable
First-party code is eval-free by grep — zero `eval(`/`new Function` outside the docstring's own mention (paraphrased — no quote available because the claim covers absence of matches). But the claim's subject is the production bundle, which does not exist in the checkout (no `.next/`, no `node_modules`), and r2 notes `pdfjs-dist` (`package.json:27`) upstream can use `new Function` at runtime behind a feature test. Plausible (a violating bundle would throw EvalErrors in every production deploy under the live CSP), but not established by repo evidence.
**Evidence:** grep of `app/`, `proxy.ts` for `eval(|new Function` (single hit: `proxy.ts:22`, the docstring itself); `package.json:27`; absence of `.next/` and `node_modules/`

## Claim 8: "`'unsafe-eval'` is added only when NODE_ENV !== \"production\"" (default-parameter mechanism)
**Location:** `proxy.ts:21-32`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
`allowUnsafeEval: boolean = process.env.NODE_ENV !== "production"` (`proxy.ts:28`); token appended only when truthy (`proxy.ts:30-32`). Call-site audit (all three replicates): only runtime caller is `const csp = buildCsp(nonce);` (`proxy.ts:53`); tests pass the flag explicitly (`proxy.test.ts:12,37`). Narrow reading (r3): the knob is an overridable public parameter — "dev-only" is enforced solely by the single runtime call site; a future caller passing `true` would silently violate the docstring.
**Evidence:** `proxy.ts:26-32,53`, `proxy.test.ts:12,37`

## Claim 9: "Next.js's dev server (HMR + eval source maps) injects `eval()`-based code that a strict CSP blocks, flooding the browser console with EvalErrors."
**Location:** `proxy.ts:21-23`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=— · single-replicate detection
External framework behavior, not checkable from this checkout (no `node_modules`, no runnable dev server). Matches widely documented Next.js dev-build behavior; nothing in the repo contradicts it. Paraphrased — no quote available because the claim concerns framework runtime behavior not present in the repository.
**Evidence:** paraphrased — no quote available (external framework behavior)

## Claim 10: "Pin the production CSP explicitly so these assertions don't depend on the ambient NODE_ENV the test runner happens to set."
**Location:** `proxy.test.ts:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
`buildCsp(NONCE, false)` (`proxy.test.ts:12`) bypasses the default initializer (`proxy.ts:28`) — the only place `buildCsp` reads NODE_ENV; the dev test pins `buildCsp(NONCE, true)` (`proxy.test.ts:37`). No assertion reads an unpinned call.
**Evidence:** `proxy.test.ts:12,37`, `proxy.ts:26-32`

## Claim 11: "'unsafe-eval' must remain scoped to script-src — never leaks elsewhere."
**Location:** `proxy.test.ts:44-45`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
Established by the assertion *pair*, as all three replicates independently reasoned: exact-match `expect(devScriptSrc).toBe(\`script-src ... 'unsafe-eval'\`)` (`proxy.test.ts:41-43`) proves one occurrence is inside script-src; `expect(devCsp.match(/'unsafe-eval'/g)).toHaveLength(1)` (`proxy.test.ts:45`) proves no other occurrence exists.
**Evidence:** `proxy.test.ts:36-46`

## Claim 12: "evidenceStore: drop the unverifiable 'same pattern as workspaceStore' parity claim; describe the debounced-write behavior directly."
**Location:** commit `4d5f743` (message), re `app/lib/stores/evidenceStore.ts`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
Unanimous: the docstring edit happened as described, but the identical parity claim survives 8 lines below in the section banner the new docstring points readers at — `// Debounced localStorage adapter (same pattern as workspaceStore)` (`evidenceStore.ts:17`). The drift removal is half-done. r1 adds that the surviving claim is the *drifted* one: workspaceStore no longer hosts its own adapter — it was moved to the corpus storage seam (`workspaceStore.ts:530`, `app/lib/corpus/storeAdapter.ts:33-46` "moved verbatim from workspaceStore.ts"); r2/r3 note the parity is currently still checkable-and-true via the seam, so "unverifiable" also oversells.
**Evidence:** `app/lib/stores/evidenceStore.ts:8-9,17`, `app/lib/stores/workspaceStore.ts:5,530`, `app/lib/corpus/storeAdapter.ts:33-46`

## Claim 13: "Resolves review items A1/A2 (fact-check Mostly-Accurate comment nits)."
**Location:** commit `4d5f743` (message)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=—
No review artifact in the repo contains matching A1/A2 items; the committed `docs/reviews/code-review-rubric.md:19-20` defines A1/A2 as unrelated corpus-architecture items (already ✅ Fixed pre-range), so a reader following the reference lands on the wrong items. The intended source was left uncommitted (per c0e0a35's own note: "Review docs in docs/reviews/ left uncommitted") and is gone.
**Evidence:** `docs/reviews/code-review-rubric.md:19-20`; paraphrased — no quote available because the referenced review document does not exist in the repository

## Claim 14: "comment-only; lint clean, no behavior change."
**Location:** commit `4d5f743` (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
Both hunks are entirely comment text (`route.ts:175-180`, `evidenceStore.ts:5-9`). "Lint clean" not re-executed (no `node_modules`); comment-only edits inherit the parent's lint status.
**Evidence:** `git show 4d5f743`, `app/api/evidence-search/route.ts:178-180`, `app/lib/stores/evidenceStore.ts:8-9`

## Claim 15: "the strict CSP from #143"
**Location:** commit `2e23824` (message)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Verified · r3=Verified
Most-severe-wins carries r1's verdict (GitHub not reachable; no in-repo `#143` cross-reference found by r1's grep of docs). Note: r2 and r3 independently *resolved* the reference in git history — commit `9581518` is titled "feat: strict Content-Security-Policy with per-request nonces (#143)", the squash-merge suffix tying the CSP to PR #143 — which strongly suggests the reference is good; see Verdict stability below. The strict CSP itself is real and predates the range either way.
**Evidence:** r1: grep `#143` in docs (no matches; paraphrased — claim covers absence); r2/r3: `git log` — `9581518 feat: strict Content-Security-Policy with per-request nonces (#143)`

## Claim 16: "fix(csp): allow 'unsafe-eval' in development only" (commit title shorthand)
**Location:** commit `2e23824` (title), `proxy.ts:21`, `proxy.test.ts:36`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
"Development only" is true only under a narrow reading: the condition is `NODE_ENV !== "production"` (`proxy.ts:28`), which also enables `'unsafe-eval'` when NODE_ENV is unset, `"test"`, `"staging"`, or any custom value — a fail-open default. In standard Next.js deployment (`next build`/`next start` force `NODE_ENV=production`) the readings coincide; a nonstandard runtime that fails to set NODE_ENV serves the weakened CSP. (r1 and r3 verified the *literal* NODE_ENV formulation as written — Claim 8 — and r3 flagged the same fail-open reading in its escalation; the title/docstring shorthand is what this claim covers.)
**Evidence:** `proxy.ts:21,28`, `proxy.test.ts:36`, commit message of `2e23824`

## Claim 17: "buildCsp gained an explicit allowUnsafeEval param (defaulted from NODE_ENV) so the test pins both prod (no eval) and dev (eval present) modes."
**Location:** commit `2e23824` (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
Param exists with NODE_ENV default (`proxy.ts:27-28`); prod pinned via `buildCsp(NONCE, false)` + `not.toMatch(/'unsafe-eval'/)` (`proxy.test.ts:12,31`); dev pinned via `buildCsp(NONCE, true)` + exact script-src assertion (`proxy.test.ts:37,41-43`).
**Evidence:** `proxy.ts:26-32`, `proxy.test.ts:12,30-46`

## Claim 18: "Guard the endpoints row on `t.between` (matching the optional chaining already used for every other streamed field)."
**Location:** commit `c0e0a35` (message), re `BalancedPerspectivesPanel.tsx:113`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
Unanimous, on two counts: (1) the added guard is a truthiness conditional render `{t.between && (...)}` (`BalancedPerspectivesPanel.tsx:113`), not optional chaining — it matches the existing *object/section* guard family (`displayMap.topic &&` line 46, `displayMap.summary &&` line 56, `displayMap.synthesis &&` line 129), while optional chaining is what the array fields use (`tensions?.map` line 110, `perspectives?.map` line 69, `supportingArguments?.map` line 82); (2) "every other streamed field" overstates — leaf scalars (`t.description` line 120, `p.label` line 74, `p.coreClaim` line 76, `synthesis.equilibrium` line 133) render unguarded, safe only because React renders `undefined` as nothing. True under the reading "every other throw-capable access is protected"; not literally true. Behavior of the fix itself is correct (`t.between?.[0]` would have rendered an empty endpoints row).
**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:46,56,66-69,74,76,82,107-120,129-136`

## Claim 19: "Adds a regression test that reproduces the exact TypeError without the guard."
**Location:** commit `c0e0a35` (message), re `BalancedPerspectivesPanel.test.tsx:50-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
All three traced the test's render path end-to-end against the pre-fix code: the missing-`between` tension reaches the real tension markup (mocks pass through, `test.tsx:7-13`; `hasContent` truthy via topic, `mergeStreamingPreview.ts:13-14`; `CollapsibleSection` always renders children, `CollapsibleSection.tsx:50-51`), so without the guard `t.between[0]` throws during `render()`, failing `not.toThrow()`. Confidence Medium uniformly: the suite was not executed (no `node_modules`), and r2 notes the test pins the *scenario*, not the TypeError message.
**Evidence:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:7-14,46-56`, `app/components/panels/BalancedPerspectivesPanel.tsx:107-120`, `app/lib/utils/mergeStreamingPreview.ts:13-14`, `app/components/ui/CollapsibleSection.tsx:50-51`

## Claim 20: "landed directly on integration/6.1 per user direction (panel is not on main and no in-flight feature branch owns it)."
**Location:** commit `c0e0a35` (message, Notes)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
The panel file has never existed on `main`/`origin/main` (`git log origin/main -- <panel>` empty; `git cat-file -e main:<panel>` non-zero — paraphrased, evidence is command exit status/absence). No branch in `git branch -a` owns the panel. "Per user direction" is intent, not repo-checkable — hence Medium.
**Evidence:** `git log origin/main -- app/components/panels/BalancedPerspectivesPanel.tsx` (empty), `git branch -a`

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- (none)

### Mostly Accurate
- **Claim 6** (`proxy.ts:18-19`): connect-src rationale true for shipped defaults, but the DD-009 corpus git worker (`isomorphic-git/http/web` push/pull to a user remote, dev-flag-gated) is browser-context third-party traffic the docstring's enumeration omits; drifts further when S4/S5 ships.
- **Claim 12** (commit `4d5f743` / `evidenceStore.ts:17`): the parity claim the commit set out to drop survives verbatim in the section banner 8 lines below the rewritten docstring.
- **Claim 16** (commit `2e23824` title / `proxy.ts:28`): "development only" is really "any NODE_ENV other than exactly `production`" — unset/staging/custom values also get `'unsafe-eval'` (fail-open default).
- **Claim 18** (commit `c0e0a35` / `BalancedPerspectivesPanel.tsx:113`): guard is a `&&` conditional render (not optional chaining) and several streamed leaf fields are unguarded — characterization imprecise, behavior correct.

### Unverifiable
- **Claim 7** (`proxy.ts:23-24`): "production output genuinely eval-free" — first-party code eval-free by grep; production bundle and `pdfjs-dist` (known optional `new Function` use upstream) not inspectable in this checkout.
- **Claim 9** (`proxy.ts:21-23`): Next.js dev eval-injection is external framework behavior, not checkable from the repo.
- **Claim 13** (commit `4d5f743`): review items A1/A2 resolve to nothing in the repo (committed rubric's A1/A2 are unrelated corpus items); source artifacts were left uncommitted.
- **Claim 15** (commit `2e23824`): `#143` — r1 could not resolve; r2/r3 found the `(#143)` squash-merge suffix on commit `9581518`, which effectively resolves it (see Verdict stability).

## Verdict stability

20 clusters total; all reporting replicates agreed on 17; 3 disagreed. Agreement rate: **17/20 = 85%** (below the ≥90% falsifier threshold — k=3 stands; sample also < 20-claim cumulative bar for the k=2 downgrade).

Disagreeing clusters:
- **Claim 6** (connect-src): r1=Mostly accurate · r2=Verified · r3=Verified. All three found the same facts, including the git worker; they differ on whether the dev-flag-gated worker traffic demotes the docstring. Most-severe carried (Mostly accurate).
- **Claim 7** (eval-free production): r1=Verified · r2=Unverifiable · r3=Unverifiable. r1 accepted grep + framework reasoning; r2/r3 held that a claim about the production bundle can't be verified without the bundle. Most-severe carried (Unverifiable).
- **Claim 15** (#143): r1=Unverifiable · r2=Verified · r3=Verified. Pure evidence-reach disagreement: r2/r3 found the squash-merge suffix in `git log`; r1's grep missed it. Most-severe carried per rule, with the resolving evidence recorded in-claim — a case where the severity rule is conservative against positive evidence found by 2/3 replicates.

## Goal-Alignment Note
- Answered: yes (merged from three replicates; no replicate answered less than "yes")
- Out of scope: test-suite/lint execution and production-bundle inspection (no `node_modules` in checkout — affects Confidence on Claims 7, 14, 19, never verdicts alone); live GitHub lookups.
- Escalate: (1) surviving drifted comment at `evidenceStore.ts:17` — the exact nit 4d5f743 intended to remove (route to author); (2) fail-open `NODE_ENV !== "production"` reading of the unsafe-eval default (route to security critic); (3) `allowUnsafeEval` is an overridable public parameter — "dev-only" enforced only by the single runtime call site (route to security + api-consistency critics); (4) connect-src docstring breaks if DD-009 S4/S5 ships the browser git pipeline to production (route to author as future-drift note).
